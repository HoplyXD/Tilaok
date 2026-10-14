class_name ItemHazardDirector
extends Node

## One deterministic per-physics-step resolver for every moving/timed item. It runs after the
## actors (higher physics priority): behaviors advance in stable item-ID order, report intents,
## and the director resolves them by (recorded time, item ID, seat) so callback order never
## decides an outcome. One terminal outcome per player; setup effects are never credited.

signal attribution_recorded(record: AttributionRecord)

var items: ItemManager
var arena: ArenaDefinition
var tuning: GameplayTuning
var budget: TransientBudget
var records: Array[AttributionRecord] = []
var play_time := 0.0
## Round-relative clock includes the item's activation-grace interval.
var simulation_time := 0.0
var active_round_id := ""
var steps := 0
var suppressed_shots := 0
## Diagnostics only: wall-clock cost of `step` (microseconds).
var step_usec_total := 0
var step_usec_worst := 0
var step_samples := 0
## Optional host hook `(record: AttributionRecord) -> bool`. When it accepts a lethal record the
## host owns the terminal commit (the P06 ledger); otherwise the director eliminates directly.
var elimination_sink := Callable()
## Some mode ledgers own every lethal decision, including deliberate rejection of stale events.
var elimination_sink_exclusive := false
var _immune_until: Dictionary = {}
var _spring_cooldown: Dictionary = {}
var _base_occluders: Array[Rect2] = []
var _jump_press_frame: Dictionary = {}
var _known_routers: Array[LocalInputRouter] = []


func _init() -> void:
	name = "ItemHazardDirector"
	process_physics_priority = 200


func configure(manager: ItemManager) -> void:
	items = manager
	arena = manager.arena
	tuning = manager.tuning
	budget = manager.budget
	_base_occluders.clear()
	for spec in arena.surface_specs:
		_base_occluders.append(spec.rect)


func _exit_tree() -> void:
	for router in _known_routers:
		if is_instance_valid(router) and router.action_pressed.is_connected(_on_action_pressed):
			router.action_pressed.disconnect(_on_action_pressed)
	_known_routers.clear()


func reset_for_play() -> void:
	_jump_press_frame.clear()
	play_time = 0.0
	simulation_time = 0.0
	steps = 0
	records.clear()
	suppressed_shots = 0
	_immune_until.clear()
	_spring_cooldown.clear()


func _physics_process(delta: float) -> void:
	if items == null or not items.in_play:
		return
	simulation_time += delta
	if not items.is_active():
		return
	step(delta)


func is_immune(seat: int) -> bool:
	return float(_immune_until.get(seat, -1.0)) > play_time


func mark_immune(seat: int, from_time: float) -> void:
	_immune_until[seat] = from_time + tuning.item_bubble_recapture_immunity_s


func spring_cooldown_remaining(seat: int) -> float:
	return float(_spring_cooldown.get(seat, 0.0))


func budget_release(kind: TransientBudget.Kind, handle: int) -> void:
	if handle >= 0:
		budget.release(kind, handle)


func budget_release_captive(player_id: String) -> void:
	budget.release_captive(player_id)


func release_occluders(item_id: String) -> Array[Rect2]:
	return _build_context(0.0).occluders_excluding(item_id)


func record_setup(behavior: ItemBehavior, seat: int, time: float, detail: String) -> void:
	_emit(behavior.make_record(AttributionRecord.Kind.SETUP, seat, time, detail))


func release_all_captives() -> void:
	for behavior in _behaviors():
		behavior.teardown(self)


func on_item_removed(instance_id: String) -> void:
	var piece := items.piece_for(instance_id) as HazardPiece
	if piece != null and piece.behavior != null:
		piece.behavior.teardown(self)
	budget.release_emitter(instance_id)


## One fixed-delta resolution step; `_physics_process` calls this.
func step(delta: float) -> void:
	var started := Time.get_ticks_usec()
	_step(delta)
	var spent := Time.get_ticks_usec() - started
	step_usec_total += spent
	step_usec_worst = maxi(step_usec_worst, spent)
	step_samples += 1


func _step(delta: float) -> void:
	var ctx := _build_context(delta)
	ctx.time_start = play_time
	play_time += delta
	ctx.time_end = play_time
	steps += 1
	for seat in _spring_cooldown.keys():
		_spring_cooldown[seat] = maxf(0.0, float(_spring_cooldown[seat]) - delta)
	var behaviors := _behaviors()
	for behavior in behaviors:
		behavior.step(ctx)
		behavior.apply_touch_effects(ctx)
	_allocate_slots(ctx, behaviors)
	var lethal_seats := _resolve_lethal(ctx, behaviors)
	_resolve_stuns(ctx, behaviors, lethal_seats)
	for behavior in behaviors:
		behavior.post_resolve(ctx)
	_resolve_launches(ctx, behaviors)


func _behaviors() -> Array[ItemBehavior]:
	var result: Array[ItemBehavior] = []
	if items == null:
		return result
	var ids: Array = items.pieces.keys()
	ids.sort()
	for instance_id in ids:
		var piece := items.piece_for(str(instance_id)) as HazardPiece
		if piece != null and piece.behavior != null:
			result.append(piece.behavior)
	return result


func _build_context(delta: float) -> ItemStepContext:
	var ctx := ItemStepContext.new()
	ctx.tuning = tuning
	ctx.arena = arena
	ctx.budget = budget
	ctx.director = self
	ctx.dt = delta
	ctx.base_occluders = _base_occluders.duplicate()
	var seats: Array = []
	var actor_map: Dictionary = {}
	if items.actors_source.is_valid():
		actor_map = items.actors_source.call()
	seats = actor_map.keys()
	seats.sort()
	for seat in seats:
		var actor := actor_map[seat] as ChickenController
		if actor != null and is_instance_valid(actor):
			ctx.actors.append(actor)
			_track_router(actor)
	var ids: Array = items.pieces.keys()
	ids.sort()
	for instance_id in ids:
		var piece := items.piece_for(str(instance_id))
		if piece != null:
			ctx.piece_occluders.append(
				{"item_id": str(instance_id), "rects": piece.occlusion_rects()}
			)
	return ctx


func _allocate_slots(ctx: ItemStepContext, behaviors: Array[ItemBehavior]) -> void:
	for kind in [TransientBudget.Kind.PROJECTILE, TransientBudget.Kind.BUBBLE]:
		var requests: Array[Dictionary] = []
		for request in ctx.slot_requests:
			if request.kind == kind:
				requests.append({"emitter_id": request.emitter_id})
		if requests.is_empty():
			continue
		for grant in budget.allocate(kind, requests):
			var behavior := _find(behaviors, str(grant.emitter_id))
			if behavior is LauncherBehavior:
				(behavior as LauncherBehavior).grant_slot(int(grant.handle))
			elif behavior is BubbleBehavior:
				(behavior as BubbleBehavior).grant_slot(int(grant.handle))


func _resolve_lethal(ctx: ItemStepContext, behaviors: Array[ItemBehavior]) -> Dictionary:
	var reports := ctx.lethal_reports.duplicate()
	reports.sort_custom(
		func(left: Dictionary, right: Dictionary) -> bool:
			if not is_equal_approx(float(left.time), float(right.time)):
				return float(left.time) < float(right.time)
			if str(left.item_id) != str(right.item_id):
				return str(left.item_id) < str(right.item_id)
			return int(left.seat) < int(right.seat)
	)
	var handled: Dictionary = {}
	for report in reports:
		var seat := int(report.seat)
		if handled.has(seat):
			continue
		var actor := _actor_for(ctx, seat)
		if actor == null or not ctx.is_hazard_target(actor):
			continue
		var source := _find(behaviors, str(report.item_id))
		if source == null:
			continue
		var record := source.make_record(
			AttributionRecord.Kind.ELIMINATION, seat, float(report.time), str(report.detail)
		)
		# Normalize the behavior clock to the room's round-active-simulation clock. The
		# behavior clock omits item activation grace; simulation_time includes that interval.
		record.physics_time += simulation_time - play_time
		record.physics_tick = Engine.get_physics_frames()
		record.time_comparable = true
		record.round_id = active_round_id
		record.event_id = (
			"%s:item:%s:%d:%d"
			% [active_round_id, record.source_item_id, record.physics_tick, record.player_seat]
		)
		if elimination_sink.is_valid():
			if bool(elimination_sink.call(record)):
				handled[seat] = true
				_emit(record)
			elif elimination_sink_exclusive:
				handled[seat] = true
		elif actor.eliminate("hazard:%s" % report.item_id):
			handled[seat] = true
			_emit(record)
	return handled


## Stun touches in stable (seat, item ID) order; never on a player eliminated this step. A stun
## is a setup effect: it is recorded but never credited.
func _resolve_stuns(
	ctx: ItemStepContext, behaviors: Array[ItemBehavior], lethal_seats: Dictionary
) -> void:
	var requests := ctx.stun_requests.duplicate()
	requests.sort_custom(
		func(left: Dictionary, right: Dictionary) -> bool:
			if int(left.seat) != int(right.seat):
				return int(left.seat) < int(right.seat)
			return str(left.item_id) < str(right.item_id)
	)
	var handled: Dictionary = {}
	for request in requests:
		var seat := int(request.seat)
		if handled.has(seat) or lethal_seats.has(seat):
			continue
		var actor := _actor_for(ctx, seat)
		if actor == null or not ctx.is_hazard_target(actor):
			continue
		if actor.apply_stun(float(request.seconds), request.knockback as Vector2):
			handled[seat] = true
			var source := _find(behaviors, str(request.item_id))
			if source != null:
				record_setup(source, seat, ctx.time_start, "stun")


func _resolve_launches(ctx: ItemStepContext, behaviors: Array[ItemBehavior]) -> void:
	var requests := ctx.launch_requests.duplicate()
	requests.sort_custom(
		func(left: Dictionary, right: Dictionary) -> bool:
			if int(left.seat) != int(right.seat):
				return int(left.seat) < int(right.seat)
			return str(left.item_id) < str(right.item_id)
	)
	var handled: Dictionary = {}
	for request in requests:
		var seat := int(request.seat)
		if handled.has(seat) or spring_cooldown_remaining(seat) > 0.0:
			continue
		var actor := _actor_for(ctx, seat)
		if actor == null or not ctx.is_hazard_target(actor):
			continue
		if actor.lifecycle.status != PlayerLifecycleState.Status.ACTIVE:
			continue
		handled[seat] = true
		var boosted := _jump_timed(actor)
		var magnitude := (
			tuning.item_spring_boost_wu_s if boosted else tuning.item_spring_launch_wu_s
		)
		actor.launch(
			(request.normal as Vector2) * magnitude,
			tuning.item_spring_horizontal_cap_wu_s,
			tuning.item_spring_upward_cap_wu_s
		)
		_spring_cooldown[seat] = tuning.item_spring_cooldown_s
		var source := _find(behaviors, str(request.item_id))
		if source is SpringBehavior:
			(source as SpringBehavior).on_launched()
			_emit(
				source.make_record(
					AttributionRecord.Kind.SETUP,
					seat,
					ctx.time_end,
					"spring boost" if boosted else "spring launch"
				)
			)


## A jump pressed within the boost window before this contact boosts the launch. The press is
## timestamped from the input edge because the controller consumes its own jump buffer on landing.
func _jump_timed(actor: ChickenController) -> bool:
	if not _jump_press_frame.has(actor.seat_index):
		return false
	var frames := Engine.get_physics_frames() - int(_jump_press_frame[actor.seat_index])
	var window_frames := int(
		round(tuning.item_spring_boost_window_s * float(Engine.physics_ticks_per_second))
	)
	return frames >= 0 and frames <= window_frames


func _on_action_pressed(seat_index: int, action_name: String) -> void:
	if action_name == "jump":
		_jump_press_frame[seat_index] = Engine.get_physics_frames()


func _track_router(actor: ChickenController) -> void:
	var router := actor.input_router
	if router == null or _known_routers.has(router):
		return
	_known_routers.append(router)
	router.action_pressed.connect(_on_action_pressed)


func _emit(record: AttributionRecord) -> void:
	records.append(record)
	attribution_recorded.emit(record)


func _actor_for(ctx: ItemStepContext, seat: int) -> ChickenController:
	for actor in ctx.actors:
		if actor.seat_index == seat:
			return actor
	return null


func _find(behaviors: Array[ItemBehavior], item_id: String) -> ItemBehavior:
	for behavior in behaviors:
		if behavior.item_id == item_id:
			return behavior
	return null

class_name BubbleBehavior
extends ItemBehavior

## Bula-Bulaklak: one bubble at a time rises on a fixed upward path. It captures at most one live
## chicken for about two seconds (no control, never eliminates by itself), then releases it at the
## nearest safe spot, or at the last safe point with zero velocity when none exists.

enum State { WAIT, REQUEST, RISING }

var state := State.WAIT
var timer := 0.0
var path := Rect2()
var path_top_y := 0.0
var bubble_handle := -1
var bubble_center := Vector2.ZERO
var captive: ChickenController = null
var capture_left := 0.0
var last_safe := Vector2.ZERO
var capture_count := 0
var release_count := 0
var last_release_safe := true


func configure(
	record: PlacedItem, resolved_regions: Array[Dictionary], source_tuning: GameplayTuning
) -> void:
	super.configure(record, resolved_regions, source_tuning)
	var rects := world_rects(ItemRegionSpec.Kind.EFFECT)
	path = rects[0] if not rects.is_empty() else Rect2()
	path_top_y = path.position.y
	reset_to_start()


func reset_to_start() -> void:
	super.reset_to_start()
	state = State.WAIT
	timer = tuning.item_bubble_cadence_s
	bubble_handle = -1
	captive = null
	capture_left = 0.0
	capture_count = 0
	release_count = 0


func preview_at(seconds: float) -> void:
	elapsed = seconds
	var radius := tuning.item_bubble_radius_wu
	var run := maxf(1.0, path.size.y - radius * 2.0)
	var rise_time := run / tuning.item_bubble_rise_wu_s
	var u := fposmod(seconds, rise_time + 0.6)
	state = State.RISING
	bubble_handle = 0
	bubble_center = Vector2(
		path.get_center().x, path.end.y - radius - minf(u, rise_time) * tuning.item_bubble_rise_wu_s
	)


func has_bubble() -> bool:
	return bubble_handle >= 0


func grant_slot(handle: int) -> void:
	bubble_handle = handle
	state = State.RISING
	bubble_center = Vector2(path.get_center().x, path.end.y - tuning.item_bubble_radius_wu)
	pending_sounds.append("sfx_emit")


func step(ctx: ItemStepContext) -> void:
	advance(ctx.dt)
	var radius := tuning.item_bubble_radius_wu
	match state:
		State.WAIT:
			timer -= ctx.dt
			if timer <= 0.0:
				state = State.REQUEST
		State.REQUEST:
			ctx.request_slot(item_id, TransientBudget.Kind.BUBBLE)
		State.RISING:
			_rise(ctx, radius)


func post_resolve(ctx: ItemStepContext) -> void:
	if state != State.RISING or captive != null:
		return
	var radius := tuning.item_bubble_radius_wu
	var bubble_rect := Rect2(bubble_center - Vector2.ONE * radius, Vector2.ONE * radius * 2.0)
	for actor in ctx.actors:
		if not _can_capture(ctx, actor):
			continue
		if not bubble_rect.intersects(ctx.body_of(actor), false):
			continue
		var player_id := "seat_%d" % actor.seat_index
		if not ctx.budget.register_captive(bubble_handle, player_id):
			continue
		captive = actor
		capture_left = tuning.item_bubble_capture_s
		last_safe = actor.global_position
		actor.set_captured(true, item_id)
		actor.clear_external_motion()
		capture_count += 1
		pending_sounds.append("sfx_capture")
		ctx.director.record_setup(self, actor.seat_index, ctx.time_end, "bubble capture")
		return


func teardown(director: ItemHazardDirector) -> void:
	if captive != null:
		_release(director, director.release_occluders(item_id), director.play_time)
	if bubble_handle >= 0:
		director.budget_release(TransientBudget.Kind.BUBBLE, bubble_handle)
	bubble_handle = -1
	state = State.WAIT
	timer = tuning.item_bubble_cadence_s


func _can_capture(ctx: ItemStepContext, actor: ChickenController) -> bool:
	if not ctx.is_hazard_target(actor):
		return false
	if actor.lifecycle.status != PlayerLifecycleState.Status.ACTIVE:
		return false
	return not ctx.director.is_immune(actor.seat_index)


func _rise(ctx: ItemStepContext, radius: float) -> void:
	if captive != null and (not is_instance_valid(captive) or captive.lifecycle.is_terminal()):
		_drop_dead_captive(ctx)
	if captive == null and not ctx.budget.is_active(TransientBudget.Kind.BUBBLE, bubble_handle):
		_pop(ctx)
		return
	var occluders := ctx.occluders_excluding(item_id)
	var clip := LaneQuery.clip(
		bubble_center, Vector2.UP, bubble_center.y - path_top_y, radius * 2.0, occluders
	)
	var rise := tuning.item_bubble_rise_wu_s * ctx.dt
	var room := maxf(0.0, float(clip.length) - radius)
	if rise >= room:
		bubble_center.y -= room
		if captive == null:
			_pop(ctx)
			return
	else:
		bubble_center.y -= rise
	bubble_center.y = maxf(bubble_center.y, path_top_y + radius)
	if captive == null:
		return
	var center := bubble_center
	captive.carry_captive_to(center)
	var size := Vector2(tuning.body_width_wu, tuning.body_height_wu)
	if SafeReleaseResolver.is_free(center, size, ctx.arena.arena_bounds, occluders):
		last_safe = center
	capture_left -= ctx.dt
	if capture_left <= 0.0:
		_release(ctx.director, occluders, ctx.time_end)
		_pop(ctx)


func _pop(ctx: ItemStepContext) -> void:
	ctx.budget.release(TransientBudget.Kind.BUBBLE, bubble_handle)
	bubble_handle = -1
	state = State.WAIT
	timer = tuning.item_bubble_cadence_s
	pending_sounds.append("sfx_pop")


func _drop_dead_captive(ctx: ItemStepContext) -> void:
	if captive != null:
		ctx.budget.release_captive("seat_%d" % captive.seat_index)
	captive = null
	capture_left = 0.0


func _release(director: ItemHazardDirector, occluders: Array[Rect2], time: float) -> void:
	if captive == null:
		return
	var actor := captive
	captive = null
	capture_left = 0.0
	director.budget_release_captive("seat_%d" % actor.seat_index)
	if not is_instance_valid(actor) or actor.lifecycle.is_terminal():
		return
	var size := Vector2(tuning.body_width_wu, tuning.body_height_wu)
	var found := SafeReleaseResolver.find(
		actor.global_position, size, director.arena.arena_bounds, occluders
	)
	last_release_safe = bool(found.found)
	actor.carry_captive_to(found.center if last_release_safe else last_safe)
	actor.set_captured(false)
	actor.clear_external_motion()
	if last_release_safe:
		actor.launch(
			Vector2(0.0, -tuning.item_bubble_release_wu_s),
			tuning.item_spring_horizontal_cap_wu_s,
			tuning.item_spring_upward_cap_wu_s
		)
	release_count += 1
	director.mark_immune(actor.seat_index, time)
	pending_sounds.append("sfx_pop")


func readout() -> Dictionary:
	return {
		"elapsed": elapsed,
		"state": ["wait", "request", "rising"][state] + (" • captive" if captive != null else ""),
		"has_bubble": has_bubble(),
		"bubble_pos": bubble_center - origin,
		"captive_seat": captive.seat_index if captive != null else -1,
		"capture_left": capture_left,
		"path": Rect2(path.position - origin, path.size),
	}

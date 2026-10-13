class_name LauncherBehavior
extends ItemBehavior

## Tsinelas Launcher: cooldown, then a transient slot is requested (telegraph only after a slot is
## granted), a telegraph, then one slipper down its bounded lane. Solids stop it; players hit by
## it are eliminated, with the earlier of blocker and player deciding the outcome.

enum State { COOLDOWN, WAITING_SLOT, TELEGRAPH }

var state := State.COOLDOWN
var timer := 0.0
var handle := -1
var lane := Rect2()
var lane_dir := Vector2.RIGHT
var lane_origin := Vector2.ZERO
var lane_length := 0.0
var projectiles: Array[Dictionary] = []
var suppressed_shots := 0
var shots_fired := 0
var clipped_length := 0.0


func configure(
	record: PlacedItem, resolved_regions: Array[Dictionary], source_tuning: GameplayTuning
) -> void:
	super.configure(record, resolved_regions, source_tuning)
	var rects := world_rects(ItemRegionSpec.Kind.LANE)
	lane = rects[0] if not rects.is_empty() else Rect2()
	var footprint := Rect2(origin, footprint_size)
	if lane.position.x >= footprint.end.x - 0.01:
		lane_dir = Vector2.RIGHT
		lane_origin = Vector2(lane.position.x, lane.get_center().y)
		lane_length = lane.size.x
	elif lane.end.x <= footprint.position.x + 0.01:
		lane_dir = Vector2.LEFT
		lane_origin = Vector2(lane.end.x, lane.get_center().y)
		lane_length = lane.size.x
	elif lane.position.y >= footprint.end.y - 0.01:
		lane_dir = Vector2.DOWN
		lane_origin = Vector2(lane.get_center().x, lane.position.y)
		lane_length = lane.size.y
	else:
		lane_dir = Vector2.UP
		lane_origin = Vector2(lane.get_center().x, lane.end.y)
		lane_length = lane.size.y
	clipped_length = lane_length
	reset_to_start()


func reset_to_start() -> void:
	super.reset_to_start()
	state = State.COOLDOWN
	timer = tuning.item_launcher_initial_delay_s
	handle = -1
	projectiles.clear()
	suppressed_shots = 0
	shots_fired = 0


func preview_at(seconds: float) -> void:
	elapsed = seconds
	var telegraph := tuning.item_launcher_telegraph_s
	var flight := lane_length / tuning.item_launcher_projectile_speed_wu_s
	var cycle := telegraph + flight + 0.4
	var u := fposmod(seconds, cycle)
	projectiles.clear()
	if u < telegraph:
		state = State.TELEGRAPH
		timer = telegraph - u
	else:
		state = State.COOLDOWN
		var travelled := (u - telegraph) * tuning.item_launcher_projectile_speed_wu_s
		if travelled < lane_length:
			var size := tuning.item_launcher_projectile_size_wu
			(
				projectiles
				. append(
					{
						"center": lane_origin + lane_dir * (size * 0.5 + travelled),
						"handle": -1,
						"travelled": travelled,
					}
				)
			)
	clipped_length = lane_length


## Called by the director when the rotating allocation granted this emitter a slot.
func grant_slot(granted_handle: int) -> void:
	handle = granted_handle
	state = State.TELEGRAPH
	timer = tuning.item_launcher_telegraph_s
	pending_sounds.append("sfx_charge")


func step(ctx: ItemStepContext) -> void:
	advance(ctx.dt)
	var occluders := ctx.occluders_excluding(item_id)
	clipped_length = _clipped_lane(occluders)
	_advance_projectiles(ctx, occluders)
	match state:
		State.COOLDOWN:
			timer -= ctx.dt
			if timer <= 0.0:
				state = State.WAITING_SLOT
		State.WAITING_SLOT:
			ctx.request_slot(item_id, TransientBudget.Kind.PROJECTILE)
		State.TELEGRAPH:
			timer -= ctx.dt
			if timer <= 0.0:
				_fire(ctx, occluders)


func teardown(director: ItemHazardDirector) -> void:
	for projectile in projectiles:
		director.budget_release(TransientBudget.Kind.PROJECTILE, int(projectile.handle))
	if handle >= 0:
		director.budget_release(TransientBudget.Kind.PROJECTILE, handle)
	projectiles.clear()
	handle = -1


func _clipped_lane(occluders: Array[Rect2]) -> float:
	var thickness := tuning.item_launcher_projectile_size_wu
	return float(LaneQuery.clip(lane_origin, lane_dir, lane_length, thickness, occluders).length)


func _spawn_rect() -> Rect2:
	var size := Vector2.ONE * tuning.item_launcher_projectile_size_wu
	var center := lane_origin + lane_dir * size.x * 0.5
	return Rect2(center - size * 0.5, size)


func _fire(ctx: ItemStepContext, occluders: Array[Rect2]) -> void:
	state = State.COOLDOWN
	timer = tuning.item_launcher_cooldown_s
	var spawn := _spawn_rect()
	var rejected := not ctx.arena.arena_bounds.encloses(spawn)
	rejected = rejected or spawn.intersects(ctx.arena.protected_spawn, false)
	rejected = rejected or spawn.intersects(ctx.arena.protected_goal, false)
	for rect in occluders:
		rejected = rejected or spawn.intersects(rect, false)
	for actor in ctx.actors:
		if ctx.is_hazard_target(actor) and spawn.intersects(ctx.body_of(actor), false):
			rejected = true
	if rejected:
		suppressed_shots += 1
		ctx.director.budget_release(TransientBudget.Kind.PROJECTILE, handle)
		handle = -1
		return
	shots_fired += 1
	pending_sounds.append("sfx_fire")
	projectiles.append({"center": spawn.get_center(), "handle": handle, "travelled": 0.0})
	handle = -1


func _advance_projectiles(ctx: ItemStepContext, occluders: Array[Rect2]) -> void:
	var size := Vector2.ONE * tuning.item_launcher_projectile_size_wu
	var kept: Array[Dictionary] = []
	for projectile in projectiles:
		var old_center: Vector2 = projectile.center
		var step_len := tuning.item_launcher_projectile_speed_wu_s * ctx.dt
		var remaining := lane_length - float(projectile.travelled)
		var moved := minf(step_len, maxf(0.0, remaining))
		var new_center := old_center + lane_dir * moved
		var from_rect := Rect2(old_center - size * 0.5, size)
		var to_rect := Rect2(new_center - size * 0.5, size)
		var block_t := -1.0
		for rect in occluders:
			var t := SweptContact.first_overlap(from_rect, to_rect, rect)
			if t >= 0.0 and (block_t < 0.0 or t < block_t):
				block_t = t
		var hit_t := -1.0
		var hit_seat := -1
		for actor in ctx.actors:
			if not ctx.is_hazard_target(actor):
				continue
			var t_actor := SweptContact.first_overlap(from_rect, to_rect, ctx.body_of(actor))
			if t_actor >= 0.0 and (hit_t < 0.0 or t_actor < hit_t):
				hit_t = t_actor
				hit_seat = actor.seat_index
		var done := false
		if hit_t >= 0.0 and (block_t < 0.0 or hit_t <= block_t):
			ctx.report_lethal(
				hit_seat, ctx.time_start + hit_t * ctx.dt, item_id, "slipper projectile"
			)
			done = true
		elif block_t >= 0.0:
			done = true
		projectile.center = new_center
		projectile.travelled = float(projectile.travelled) + moved
		if float(projectile.travelled) >= lane_length - 0.001:
			done = true
		if not ctx.budget.is_active(TransientBudget.Kind.PROJECTILE, int(projectile.handle)):
			done = true
		if done:
			ctx.budget.release(TransientBudget.Kind.PROJECTILE, int(projectile.handle))
		else:
			kept.append(projectile)
	projectiles = kept


func readout() -> Dictionary:
	var local_projectiles: Array[Vector2] = []
	for projectile in projectiles:
		local_projectiles.append((projectile.center as Vector2) - origin)
	var charge := 0.0
	if state == State.TELEGRAPH:
		charge = 1.0 - clampf(timer / tuning.item_launcher_telegraph_s, 0.0, 1.0)
	return {
		"elapsed": elapsed,
		"state": ["cooldown", "waiting_slot", "telegraph"][state],
		"charge_t": charge,
		"projectiles": local_projectiles,
		"lane_origin": lane_origin - origin,
		"lane_dir": lane_dir,
		"lane_length": lane_length,
		"clipped_length": clipped_length,
		"suppressed": suppressed_shots,
	}

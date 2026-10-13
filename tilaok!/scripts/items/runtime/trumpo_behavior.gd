class_name TrumpoBehavior
extends ItemBehavior

## Trumpo sa Riles. The top is a closed-form function of elapsed time along a bounded rail, so
## resets, pauses and 10-cycle repeats are exact. Contact is a swept test per step.

var sweep := Rect2()
var horizontal := true
var travel := 0.0
var start_center := Vector2.ZERO
var direction := Vector2.RIGHT
var previous_rect := Rect2()
var current_rect := Rect2()
var paused_at_end := false
var forward := true


func configure(
	record: PlacedItem, resolved_regions: Array[Dictionary], source_tuning: GameplayTuning
) -> void:
	super.configure(record, resolved_regions, source_tuning)
	var rects := world_rects(ItemRegionSpec.Kind.SWEEP)
	sweep = rects[0] if not rects.is_empty() else Rect2()
	horizontal = sweep.size.x >= sweep.size.y
	var hit := tuning.item_trumpo_hit_wu
	var rail_dir := ItemGeometry.rotate_vector(Vector2.RIGHT, turns)
	if horizontal:
		travel = maxf(0.0, sweep.size.x - hit)
		var y := sweep.get_center().y
		var left := Vector2(sweep.position.x + hit * 0.5, y)
		var right := Vector2(sweep.end.x - hit * 0.5, y)
		start_center = left if rail_dir.x >= 0.0 else right
		direction = Vector2.RIGHT if rail_dir.x >= 0.0 else Vector2.LEFT
	else:
		travel = maxf(0.0, sweep.size.y - hit)
		var x := sweep.get_center().x
		var top := Vector2(x, sweep.position.y + hit * 0.5)
		var bottom := Vector2(x, sweep.end.y - hit * 0.5)
		start_center = top if rail_dir.y >= 0.0 else bottom
		direction = Vector2.DOWN if rail_dir.y >= 0.0 else Vector2.UP
	reset_to_start()


func reset_to_start() -> void:
	super.reset_to_start()
	_place(0.0)
	previous_rect = current_rect


func top_center() -> Vector2:
	return current_rect.get_center()


func step(ctx: ItemStepContext) -> void:
	previous_rect = current_rect
	var was_paused := paused_at_end
	advance(ctx.dt)
	_place(elapsed)
	if paused_at_end and not was_paused:
		pending_sounds.append("sfx_pause")
	for actor in ctx.actors:
		if not ctx.is_hazard_target(actor):
			continue
		var fraction := SweptContact.first_overlap(previous_rect, current_rect, ctx.body_of(actor))
		if fraction >= 0.0:
			ctx.report_lethal(
				actor.seat_index, ctx.time_start + fraction * ctx.dt, item_id, "trumpo contact"
			)


func preview_at(seconds: float) -> void:
	elapsed = seconds
	_place(seconds)
	previous_rect = current_rect


func _place(at_time: float) -> void:
	var sample := PathMover.sample(
		at_time, travel, tuning.item_trumpo_speed_wu_s, tuning.item_trumpo_pause_s
	)
	paused_at_end = bool(sample.paused)
	forward = bool(sample.forward)
	var center := start_center + direction * float(sample.offset)
	var size := Vector2.ONE * tuning.item_trumpo_hit_wu
	current_rect = Rect2(center - size * 0.5, size)


func readout() -> Dictionary:
	return {
		"elapsed": elapsed,
		"top_pos": top_center() - origin,
		"paused": paused_at_end,
		"forward": forward,
		"spin": elapsed * 9.0,
		"state": "paused" if paused_at_end else "moving",
		"direction": direction,
	}

class_name ParolBehavior
extends ItemBehavior

## Parol Pulse. Two posts project a beam on a 3 s cycle: inactive, then charge (inside the
## inactive tail), then active. Solids between the posts really occlude it.

var beam := Rect2()
var horizontal := true
var phase := PhaseCycle.Phase.INACTIVE
var charge_t := 0.0
var segments: Array[Rect2] = []
var _last_phase := PhaseCycle.Phase.INACTIVE


func configure(
	record: PlacedItem, resolved_regions: Array[Dictionary], source_tuning: GameplayTuning
) -> void:
	super.configure(record, resolved_regions, source_tuning)
	var rects := world_rects(ItemRegionSpec.Kind.EFFECT)
	beam = rects[0] if not rects.is_empty() else Rect2()
	horizontal = beam.size.x >= beam.size.y
	reset_to_start()


func reset_to_start() -> void:
	super.reset_to_start()
	phase = PhaseCycle.Phase.INACTIVE
	_last_phase = PhaseCycle.Phase.INACTIVE
	charge_t = 0.0
	segments.clear()


## Beam rects from each post toward the other, each clipped at its first blocker.
func beam_segments(occluders: Array[Rect2]) -> Array[Rect2]:
	var result: Array[Rect2] = []
	if beam.size == Vector2.ZERO:
		return result
	var width := tuning.item_parol_beam_width_wu
	if horizontal:
		var y := beam.get_center().y
		var from_a := LaneQuery.clip(
			Vector2(beam.position.x, y), Vector2.RIGHT, beam.size.x, width, occluders
		)
		var from_b := LaneQuery.clip(
			Vector2(beam.end.x, y), Vector2.LEFT, beam.size.x, width, occluders
		)
		result.append(Rect2(beam.position.x, y - width * 0.5, from_a.length, width))
		result.append(Rect2(beam.end.x - from_b.length, y - width * 0.5, from_b.length, width))
	else:
		var x := beam.get_center().x
		var down_a := LaneQuery.clip(
			Vector2(x, beam.position.y), Vector2.DOWN, beam.size.y, width, occluders
		)
		var up_b := LaneQuery.clip(
			Vector2(x, beam.end.y), Vector2.UP, beam.size.y, width, occluders
		)
		result.append(Rect2(x - width * 0.5, beam.position.y, width, down_a.length))
		result.append(Rect2(x - width * 0.5, beam.end.y - up_b.length, width, up_b.length))
	return result


func preview_at(seconds: float) -> void:
	elapsed = seconds
	var cycle := tuning.item_parol_cycle_s
	phase = PhaseCycle.phase_at(
		seconds, cycle, tuning.item_parol_active_s, tuning.item_parol_charge_s
	)
	charge_t = PhaseCycle.charge_progress(
		seconds, cycle, tuning.item_parol_active_s, tuning.item_parol_charge_s
	)
	segments = beam_segments([])


func step(ctx: ItemStepContext) -> void:
	advance(ctx.dt)
	var cycle := tuning.item_parol_cycle_s
	var active := tuning.item_parol_active_s
	var charge := tuning.item_parol_charge_s
	phase = PhaseCycle.phase_at(elapsed, cycle, active, charge)
	charge_t = PhaseCycle.charge_progress(elapsed, cycle, active, charge)
	if phase != _last_phase:
		if phase == PhaseCycle.Phase.CHARGE:
			pending_sounds.append("sfx_charge")
		elif phase == PhaseCycle.Phase.ACTIVE:
			pending_sounds.append("sfx_on")
		_last_phase = phase
	segments = beam_segments(ctx.occluders_excluding(item_id))
	if phase != PhaseCycle.Phase.ACTIVE:
		return
	for actor in ctx.actors:
		if not ctx.is_hazard_target(actor):
			continue
		var body := ctx.body_of(actor)
		for segment in segments:
			if segment.size.x > 0.0 and segment.size.y > 0.0 and segment.intersects(body, false):
				ctx.report_lethal(actor.seat_index, ctx.time_start, item_id, "parol beam")
				break


func readout() -> Dictionary:
	var local: Array[Rect2] = []
	for segment in segments:
		local.append(Rect2(segment.position - origin, segment.size))
	return {
		"elapsed": elapsed,
		"phase": PhaseCycle.phase_name(phase),
		"charge_t": charge_t,
		"segments": local,
		"state": PhaseCycle.phase_name(phase),
	}

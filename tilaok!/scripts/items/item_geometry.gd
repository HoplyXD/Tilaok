class_name ItemGeometry
extends RefCounted

## Pure rotation/region math. One quarter turn is a clockwise 90 degree turn in a y-down plane.


static func normalized_turns(turns: int) -> int:
	return posmod(turns, 4)


static func rotated_size(size: Vector2, turns: int) -> Vector2:
	return size if normalized_turns(turns) % 2 == 0 else Vector2(size.y, size.x)


static func rotate_rect(rect: Rect2, box: Vector2, turns: int) -> Rect2:
	var result := rect
	var current_box := box
	for _step in range(normalized_turns(turns)):
		result = Rect2(
			Vector2(current_box.y - (result.position.y + result.size.y), result.position.x),
			Vector2(result.size.y, result.size.x)
		)
		current_box = Vector2(current_box.y, current_box.x)
	return result


static func rotate_vector(vector: Vector2, turns: int) -> Vector2:
	var result := vector
	for _step in range(normalized_turns(turns)):
		result = Vector2(-result.y, result.x)
	return result


## Regions marked `reach_stage_edge` (a projectile path drawn past the stage) are cut where they
## would leave the build region or enter the protected spawn / goal zone, measured outward from
## the placed footprint. Other regions are returned unchanged. Rects stay footprint-relative.
static func clip_to_stage(
	regions: Array[Dictionary], footprint: Rect2, arena: ArenaDefinition
) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for region in regions:
		if not bool(region.get("reach_stage_edge", false)) or arena == null:
			result.append(region)
			continue
		var copy := region.duplicate()
		var lane: Rect2 = region.rect
		lane.position += footprint.position
		var clipped := _clip_lane(lane, footprint, arena)
		clipped.position -= footprint.position
		copy.rect = clipped
		result.append(copy)
	return result


static func _clip_lane(lane: Rect2, footprint: Rect2, arena: ArenaDefinition) -> Rect2:
	var room := arena.build_region
	var blockers: Array[Rect2] = [arena.protected_spawn, arena.protected_goal]
	if lane.position.x >= footprint.end.x - 0.01 or lane.end.x <= footprint.position.x + 0.01:
		var rightward := lane.position.x >= footprint.end.x - 0.01
		var low := maxf(lane.position.x, room.position.x)
		var high := minf(lane.end.x, room.end.x)
		for zone in blockers:
			if zone.end.y <= lane.position.y or zone.position.y >= lane.end.y:
				continue
			if rightward and zone.position.x >= lane.position.x - 0.01:
				high = minf(high, zone.position.x)
			elif not rightward and zone.end.x <= lane.end.x + 0.01:
				low = maxf(low, zone.end.x)
		return Rect2(low, lane.position.y, maxf(0.0, high - low), lane.size.y)
	var downward := lane.position.y >= footprint.end.y - 0.01
	var top := maxf(lane.position.y, room.position.y)
	var bottom := minf(lane.end.y, room.end.y)
	for zone in blockers:
		if zone.end.x <= lane.position.x or zone.position.x >= lane.end.x:
			continue
		if downward and zone.position.y >= lane.position.y - 0.01:
			bottom = minf(bottom, zone.position.y)
		elif not downward and zone.end.y <= lane.end.y + 0.01:
			top = maxf(top, zone.end.y)
	return Rect2(lane.position.x, top, lane.size.x, maxf(0.0, bottom - top))


static func resolve_regions(
	variant: ItemVariantDefinition, turns: int, tuning: GameplayTuning
) -> Array[Dictionary]:
	var cell := tuning.grid_cell_wu
	var box := Vector2(variant.footprint_cells) * cell
	var resolved: Array[Dictionary] = []
	for region in variant.regions:
		var rect := Rect2(region.rect_cells.position * cell, region.rect_cells.size * cell)
		var normal := Vector2.ZERO
		if region.kind == ItemRegionSpec.Kind.ONE_WAY_TOP:
			if region.thickness_tuning_key != &"":
				rect.size.y = float(tuning.get(region.thickness_tuning_key))
			elif region.thickness_wu > 0.0:
				rect.size.y = region.thickness_wu
			normal = rotate_vector(Vector2.UP, turns)
		(
			resolved
			. append(
				{
					"kind": region.kind,
					"rect": rotate_rect(rect, box, turns),
					"normal": normal,
					"effect": region.effect,
					"blockable": region.blockable,
					"reach_stage_edge": region.reach_stage_edge,
				}
			)
		)
	return resolved

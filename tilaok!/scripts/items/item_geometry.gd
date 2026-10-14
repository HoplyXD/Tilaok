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
				}
			)
		)
	return resolved

class_name BaryaPlacementRules
extends RefCounted


static func cell_rect(cell: Vector2i, tuning: GameplayTuning) -> Rect2:
	var size := Vector2.ONE * tuning.grid_cell_wu
	return Rect2(Vector2(cell) * tuning.grid_cell_wu, size)


static func validate_cell(
	arena: ArenaDefinition,
	tuning: GameplayTuning,
	cell: Vector2i,
	existing_pieces: Array,
	actor_rects: Array[Rect2]
) -> Dictionary:
	if arena == null or tuning == null:
		return {"allowed": false, "code": "missing_stage", "reason": "Stage is unavailable."}
	var rect := cell_rect(cell, tuning)
	var stage_result := arena.validate_region(rect, ArenaDefinition.REGION_FOOTPRINT, actor_rects)
	if not bool(stage_result.allowed):
		return {
			"allowed": false,
			"code": "stage_rejected",
			"reason": str(stage_result.reason),
			"footprint": rect,
		}
	for item_variant in existing_pieces:
		var item := item_variant as PlacedItem
		if item == null:
			continue
		for occupied_rect in item.occupancy():
			if rect.intersects(occupied_rect, false):
				return {
					"allowed": false,
					"code": "item_overlap",
					"reason": "Overlaps another piece. Move it into a free cell.",
					"footprint": rect,
				}
	return {
		"allowed": true,
		"code": "valid",
		"reason": "Valid Barya placement.",
		"footprint": rect,
		"cell": cell,
	}


## Deterministic recovery searches every stage cell. Distance is measured from the actual death
## position; equal distances choose row-major (y, x) order.
static func nearest_valid_cell(
	position: Vector2,
	arena: ArenaDefinition,
	tuning: GameplayTuning,
	existing_pieces: Array,
	actor_rects: Array[Rect2]
) -> Dictionary:
	if arena == null or tuning == null:
		return {"allowed": false, "cell": Vector2i.ZERO}
	var columns := ceili(arena.arena_bounds.size.x / tuning.grid_cell_wu)
	var rows := ceili(arena.arena_bounds.size.y / tuning.grid_cell_wu)
	var found := false
	var best_cell := Vector2i.ZERO
	var best_distance := INF
	for y in range(rows):
		for x in range(columns):
			var cell := Vector2i(x, y)
			var verdict := validate_cell(arena, tuning, cell, existing_pieces, actor_rects)
			if not bool(verdict.allowed):
				continue
			var distance := cell_rect(cell, tuning).get_center().distance_squared_to(position)
			if (
				not found
				or distance < best_distance
				or (
					distance == best_distance
					and (cell.y < best_cell.y or (cell.y == best_cell.y and cell.x < best_cell.x))
				)
			):
				found = true
				best_cell = cell
				best_distance = distance
	return {"allowed": found, "cell": best_cell, "distance_squared": best_distance}

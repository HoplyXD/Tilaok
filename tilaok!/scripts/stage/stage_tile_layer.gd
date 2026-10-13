class_name StageTileLayer
extends TileMapLayer

## Visual 64x64 tile layer for the stage. ArenaDefinition stays the layout authority:
## paint_arena() fills one tile per grid cell of every surface rect. Collision stays on the
## per-surface StaticBody2D nodes so each surface keeps its own SupportSurfaceMetadata.

const SOURCE_ID := 0
const TILE_GROUND := Vector2i(0, 0)
const TILE_BOUNDARY := Vector2i(1, 0)
const TILE_PLATFORM := Vector2i(2, 0)


func paint_arena(arena: ArenaDefinition) -> int:
	clear()
	var cell := arena.tuning.grid_cell_wu
	if tile_set != null and not is_equal_approx(float(tile_set.tile_size.x), cell):
		# Tiles are authored at 64 px; other grids scale the layer so cells still match.
		scale = Vector2.ONE * cell / float(tile_set.tile_size.x)
	var painted := 0
	for spec in arena.surface_specs:
		var rect: Rect2 = spec.rect
		var tile := tile_for_surface(str(spec.id), bool(spec.immutable))
		var first := Vector2i((rect.position / cell).floor())
		var last := Vector2i((rect.end / cell).ceil())
		for x in range(first.x, last.x):
			for y in range(first.y, last.y):
				set_cell(Vector2i(x, y), SOURCE_ID, tile)
				painted += 1
	return painted


static func tile_for_surface(surface_id: String, immutable: bool) -> Vector2i:
	if not immutable:
		return TILE_PLATFORM
	if surface_id.ends_with("_wall") or surface_id.ends_with("ceiling"):
		return TILE_BOUNDARY
	if surface_id.begins_with("arena.base_"):
		return TILE_PLATFORM
	return TILE_GROUND

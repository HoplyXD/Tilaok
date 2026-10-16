@tool
class_name StageMap
extends Node2D

## Root of a map scene in scenes/maps/ (requested by Jorge, 2026-10-16). MapCatalog scans that
## folder, so a new map scene saved there appears in the Lobby map selection with no code edit.
##
## A map scene has two TileMapLayer children, both on the 64 px stage grid (cell (x, y) is stage
## tile (x, y); the stage is ARENA_SIZE tiles):
## - "DevMarkers": editing-only marker tiles, hidden in the game:
##   - Spawn (atlas 0,0): the protected spawn area; chickens appear standing on its bottom edge,
##     at its horizontal centre.
##   - Build Area (atlas 1,0): where players may build (the rectangle around every Build tile).
##   - Flag (atlas 2,0): the flag trigger; nobody may build within one tile of it.
## - "Blocks": the stage itself, painted with the block sprite sheet. Every painted cell inside
##   the stage is solid base geometry; touching cells merge into rectangles (one collision surface
##   each). Cells outside the stage (a frame around it) are drawn only: the game already closes
##   the stage with invisible walls and a ceiling there. Tiles whose TileSet custom data
##   "no_wall_slide" is on make surfaces chickens cannot wall-slide or wall-kick on.
## Markers outside the stage are ignored. The "Precise" settings below are optional and only
## needed for off-grid details (the tutorial's half-tile flag ledge).

const MARKERS_LAYER := "DevMarkers"
const BLOCKS_LAYER := "Blocks"
const MARKER_SPAWN := Vector2i(0, 0)
const MARKER_BUILD := Vector2i(1, 0)
const MARKER_FLAG := Vector2i(2, 0)
const NO_WALL_SLIDE := "no_wall_slide"
## Stage size in tiles (GameplayTuning.arena_width_tiles x arena_height_tiles).
const ARENA_SIZE := Vector2i(32, 16)

## Name shown in the Lobby map selection.
@export var map_name := "":
	set(value):
		map_name = value
		update_configuration_warnings()
## Lower sorts first in the selection (ties sort by name).
@export var map_order := 100
## Off hides a work-in-progress map from the selection.
@export var in_selection := true
@export_multiline var description := ""

@export_group("Precise (optional)")
## Where chickens stand at spawn, in tiles (feet). (-1, -1) = the Spawn area's bottom centre.
@export var spawn_feet_override_tiles := Vector2(-1.0, -1.0)
## Exact flag trigger in tiles (fractions allowed). Empty = the rectangle of the Flag tiles.
@export var flag_override_tiles := Rect2()
## Exact no-build zone around the flag. Empty = the flag grown by one tile.
@export var protected_goal_override_tiles := Rect2()
## Tutorial coach "BUILD HERE" zone in tiles. Empty = none.
@export var build_here_zone_tiles := Rect2()
## Extra solid base surfaces that are not whole tiles (drawn as plain grey boxes).
@export var extra_surfaces: Array[ArenaSurfaceLayout] = []


func _ready() -> void:
	if not Engine.is_editor_hint():
		prepare_for_play()


## In the game: drop the dev markers and keep the Blocks layer as the stage picture only
## (collision comes from the generated surfaces, not from tiles).
func prepare_for_play() -> void:
	var markers := markers_layer()
	if markers != null:
		markers.visible = false
		markers.queue_free()
	var blocks := blocks_layer()
	if blocks != null:
		blocks.collision_enabled = false


func markers_layer() -> TileMapLayer:
	return get_node_or_null(MARKERS_LAYER) as TileMapLayer


func blocks_layer() -> TileMapLayer:
	return get_node_or_null(BLOCKS_LAYER) as TileMapLayer


## Marker cells of one kind inside the stage.
func marker_cells(marker: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var layer := markers_layer()
	if layer == null:
		return cells
	var arena := Rect2i(Vector2i.ZERO, ARENA_SIZE)
	for cell in layer.get_used_cells():
		if layer.get_cell_atlas_coords(cell) == marker and arena.has_point(cell):
			cells.append(cell)
	cells.sort()
	return cells


## Solid block cells (inside the stage).
func block_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var layer := blocks_layer()
	if layer == null:
		return cells
	var arena := Rect2i(Vector2i.ZERO, ARENA_SIZE)
	for cell in layer.get_used_cells():
		if arena.has_point(cell):
			cells.append(cell)
	cells.sort()
	return cells


func is_no_wall_slide(cell: Vector2i) -> bool:
	var layer := blocks_layer()
	if layer == null or layer.tile_set == null:
		return false
	if not layer.tile_set.has_custom_data_layer_by_name(NO_WALL_SLIDE):
		return false
	var data := layer.get_cell_tile_data(cell)
	return data != null and bool(data.get_custom_data(NO_WALL_SLIDE))


## Problems that keep this map out of the selection (also shown as editor warnings).
func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if map_name.strip_edges().is_empty():
		errors.append("Give the map a Map Name.")
	if markers_layer() == null:
		errors.append("Add a TileMapLayer named %s." % MARKERS_LAYER)
	if blocks_layer() == null:
		errors.append("Add a TileMapLayer named %s." % BLOCKS_LAYER)
	var blocks := block_cells()
	if blocks.is_empty():
		errors.append(
			(
				"Paint at least one block inside the %dx%d stage (the floor)."
				% [ARENA_SIZE.x, ARENA_SIZE.y]
			)
		)
	var labels := {MARKER_SPAWN: "Spawn", MARKER_BUILD: "Build Area", MARKER_FLAG: "Flag"}
	for marker in labels:
		if marker_cells(marker).is_empty():
			errors.append("Paint at least one %s marker tile inside the stage." % labels[marker])
	if not errors.is_empty():
		return errors
	var feet := _spawn_feet()
	var below := Vector2i(floori(feet.x - 0.001), roundi(feet.y))
	var below_right := Vector2i(floori(feet.x + 0.001), roundi(feet.y))
	var on_extra := false
	for surface in extra_surfaces:
		on_extra = on_extra or surface.rect_tiles.has_point(feet + Vector2(0.0, 0.01))
	if not blocks.has(below) and not blocks.has(below_right) and not on_extra:
		errors.append("Chickens must spawn standing on a block (the Spawn area's bottom edge).")
	var flag := _flag_rect()
	for cell in blocks:
		if flag.intersects(Rect2(cell, Vector2.ONE)):
			errors.append("The flag overlaps block %s; leave the flag in open air." % cell)
			break
	return errors


## The ArenaLayout this map plays as. `layout_id` is the map id (its file name).
func to_layout(layout_id: String) -> ArenaLayout:
	var layout := ArenaLayout.new()
	layout.layout_id = layout_id
	layout.surfaces = _surfaces()
	for surface in extra_surfaces:
		var copy := surface.duplicate() as ArenaSurfaceLayout
		copy.custom_visual = true
		if copy.surface_id.is_empty():
			copy.surface_id = "arena.extra_%02d" % layout.surfaces.size()
		layout.surfaces.append(copy)
	var spawn := _bounds(marker_cells(MARKER_SPAWN))
	layout.protected_spawn_tiles = Rect2(spawn)
	layout.spawn_feet_tiles = _spawn_feet()
	layout.build_region_tiles = Rect2(_bounds(marker_cells(MARKER_BUILD)))
	var flag := _flag_rect()
	_name_goal_surface(layout.surfaces, flag)
	layout.goal_trigger_tiles = flag
	layout.protected_goal_tiles = (
		protected_goal_override_tiles
		if protected_goal_override_tiles.has_area()
		else flag.grow(1.0).intersection(Rect2(Vector2.ZERO, Vector2(ARENA_SIZE)))
	)
	layout.build_here_zone_tiles = build_here_zone_tiles
	layout.floor_top_tile = float(spawn.end.y)
	for surface in layout.surfaces:
		if surface.surface_id == "arena.floor":
			layout.floor_top_tile = surface.rect_tiles.position.y
	return layout


## The block rectangle the flag stands on (first one straight below the flag's centre) is named
## "arena.goal", as on the built-in stage.
static func _name_goal_surface(surfaces: Array[ArenaSurfaceLayout], flag: Rect2) -> void:
	var column := flag.get_center().x
	var best: ArenaSurfaceLayout = null
	for surface in surfaces:
		var rect := surface.rect_tiles
		if surface.surface_id == "arena.floor" or surface.custom_visual:
			continue
		if rect.position.x <= column and column < rect.end.x and rect.position.y >= flag.end.y:
			if best == null or rect.position.y < best.rect_tiles.position.y:
				best = surface
	if best != null:
		best.surface_id = "arena.goal"


func _spawn_feet() -> Vector2:
	if spawn_feet_override_tiles.x >= 0.0 and spawn_feet_override_tiles.y >= 0.0:
		return spawn_feet_override_tiles
	var spawn := _bounds(marker_cells(MARKER_SPAWN))
	return Vector2(spawn.position.x + spawn.size.x * 0.5, spawn.end.y)


func _flag_rect() -> Rect2:
	if flag_override_tiles.has_area():
		return flag_override_tiles
	return Rect2(_bounds(marker_cells(MARKER_FLAG)))


## Painted cells merged into rectangles: maximal horizontal runs per row (cells with the same
## wall-slide setting), stacked with the run directly above when both span the same columns.
## Deterministic, and it reproduces the default stage's six surfaces exactly. The widest lowest
## rectangle is the floor; "no_wall_slide" tiles give wall-ineligible surfaces.
func _surfaces() -> Array[ArenaSurfaceLayout]:
	var filled := {}
	for cell in block_cells():
		filled[cell] = is_no_wall_slide(cell)
	var rects: Array[Rect2i] = []
	var rect_no_wall: Array[bool] = []
	var open_by_span := {}
	var rows: Array = []
	for cell in filled:
		if not rows.has(cell.y):
			rows.append(cell.y)
	rows.sort()
	for y in rows:
		var xs: Array = []
		for cell in filled:
			if cell.y == y:
				xs.append(cell.x)
		xs.sort()
		var next_open := {}
		var index := 0
		while index < xs.size():
			var start: int = xs[index]
			var no_wall: bool = filled[Vector2i(start, y)]
			var end := start
			while (
				index + 1 < xs.size()
				and xs[index + 1] == end + 1
				and filled[Vector2i(xs[index + 1], y)] == no_wall
			):
				index += 1
				end = xs[index]
			index += 1
			var span := Vector3i(start, end, 1 if no_wall else 0)
			var rect_index := -1
			if open_by_span.has(span) and rects[open_by_span[span]].end.y == y:
				rect_index = open_by_span[span]
				rects[rect_index].size.y += 1
			else:
				rects.append(Rect2i(start, y, end - start + 1, 1))
				rect_no_wall.append(no_wall)
				rect_index = rects.size() - 1
			next_open[span] = rect_index
		open_by_span = next_open
	var floor_index := -1
	for i in rects.size():
		var rect := rects[i]
		if (
			floor_index < 0
			or rect.end.y > rects[floor_index].end.y
			or (rect.end.y == rects[floor_index].end.y and rect.size.x > rects[floor_index].size.x)
		):
			floor_index = i
	var result: Array[ArenaSurfaceLayout] = []
	var block_number := 0
	for i in rects.size():
		var surface := ArenaSurfaceLayout.new()
		surface.rect_tiles = Rect2(rects[i])
		if i == floor_index:
			surface.surface_id = "arena.floor"
			surface.wall_eligible = false
		else:
			block_number += 1
			surface.surface_id = "arena.block_%02d" % block_number
			surface.wall_eligible = not rect_no_wall[i]
		result.append(surface)
	return result


static func _bounds(cells: Array[Vector2i]) -> Rect2i:
	if cells.is_empty():
		return Rect2i()
	var rect := Rect2i(cells[0], Vector2i.ONE)
	for cell in cells:
		rect = rect.expand(cell).expand(cell + Vector2i.ONE)
	return rect


func _get_configuration_warnings() -> PackedStringArray:
	return validate()

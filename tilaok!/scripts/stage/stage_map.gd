@tool
class_name StageMap
extends Node2D

## Root of a map scene in scenes/maps/ (user request, 2026-10-16). MapCatalog scans that
## folder, so a new map scene saved there appears in the Lobby map selection with no code edit.
##
## A map scene has two TileMapLayer children, both on the 64 px stage grid (cell (x, y) is stage
## tile (x, y); the stage is ARENA_SIZE tiles):
## - "DevMarkers": editing-only marker tiles, hidden in the game:
##   - Spawn (atlas 0,0): the protected spawn area; chickens appear standing on its bottom edge,
##     at its horizontal centre.
##   - Build Area (atlas 1,0): where players may build (the rectangle around every Build tile).
##   - Flag (atlas 2,0): the flag trigger; nobody may build within one tile of it.
## - "Blocks": the stage itself, painted with assets/tiles/map_tiles_tileset.tres. What a cell
##   does comes from its terrain in terrain set 0, not from the atlas coordinates, so repainting
##   the art never changes gameplay:
##     Grass (terrain 0) - solid base geometry, chickens may wall-slide and wall-kick on it.
##     Stone (terrain 1) - solid base geometry that is NOT climbable (no wall slide or kick).
##     Water (terrain 2) - not solid; chickens float in it (ArenaLayout.water_regions_tiles).
##   Touching solid cells merge into rectangles (one collision surface each). Cells outside the
##   stage (a frame around it) are drawn only: the game already closes the stage with invisible
##   walls and a ceiling there.
##   The art is authored at 256 px while the stage grid is 64 px, so the Blocks layer is scaled
##   0.25 in each map scene; one painted cell is still one stage tile.
## Markers outside the stage are ignored. The "Precise" settings below are optional and only
## needed for off-grid details (the tutorial's half-tile flag ledge).

const MARKERS_LAYER := "DevMarkers"
const BLOCKS_LAYER := "Blocks"
const MARKER_SPAWN := Vector2i(0, 0)
const MARKER_BUILD := Vector2i(1, 0)
const MARKER_FLAG := Vector2i(2, 0)
## Black marker: the kill boundary. Invisible in play; a chicken entering one is eliminated.
const MARKER_BORDER := Vector2i(3, 0)
## Optional child naming the camera's limit: a CollisionShape2D holding a RectangleShape2D drawn
## over the area the camera may show.
const CAMERA_BORDER_NODE := "Camera Border"
## Terrain set and terrain indices of map_tiles_tileset.tres. Godot stores terrains 0-based, so
## these are the 1st/2nd/3rd terrains listed in the TileSet editor.
const TERRAIN_SET := 0
const TERRAIN_GRASS := 0
const TERRAIN_STONE := 1
const TERRAIN_WATER := 2
## Solid and unclimbable exactly like Stone. It is a separate terrain only so a map can give it its
## own occlusion and light settings (it is meant to cast no shadow) without changing Stone.
const TERRAIN_BORDER_BLOCK := 3
## Checked by validate() so a reordered or renamed TileSet shows up as an editor warning instead
## of silently changing what every map does.
const TERRAIN_NAMES := ["Grass", "Stone", "Water", "Border Block"]
## Pre-terrain TileSet custom data, still honoured for any map not yet repainted.
const NO_WALL_SLIDE := "no_wall_slide"
## Default stage size in tiles (GameplayTuning.arena_width_tiles x arena_height_tiles). Only the
## fallback for a map that paints nothing beyond it: since 2026-10-22 a map is as large as what it
## paints, so markers and terrain are read wherever they are and `stage_size_tiles()` reports the
## real extent. Maps used to be clipped to this, which silently discarded a larger map's markers.
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


## Marker cells of one kind, wherever they are painted. A map is as large as what it paints, so
## nothing is clipped to ARENA_SIZE: clipping used to discard a larger map's Spawn and Flag and
## leave it failing validation with no visible cause.
func marker_cells(marker: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var layer := markers_layer()
	if layer == null:
		return cells
	for cell in layer.get_used_cells():
		if layer.get_cell_atlas_coords(cell) == marker:
			cells.append(cell)
	cells.sort()
	return cells


## Border marker cells: the stage's kill boundary.
func border_cells() -> Array[Vector2i]:
	return marker_cells(MARKER_BORDER)


## The optional camera border: the box the view may never leave. Authored either way round:
##   - a child named CAMERA_BORDER_NODE (a CollisionShape2D with a RectangleShape2D) drawn over the
##     area the camera may show, which is the easy one to size by eye in the editor; or
##   - a Camera2D child with its own limit_left/top/right/bottom set.
## Empty when the map authors neither, and the stage extent is used instead.
func camera_bounds_world() -> Rect2:
	var shape_bounds := _camera_border_shape_bounds()
	if shape_bounds.has_area():
		return shape_bounds
	return _camera_limit_bounds()


## The drawn Camera Border rectangle, in this map's space.
func _camera_border_shape_bounds() -> Rect2:
	var node := get_node_or_null(CAMERA_BORDER_NODE) as CollisionShape2D
	if node == null:
		for child in get_children():
			if child is CollisionShape2D and str(child.name).to_lower().begins_with("camera"):
				node = child as CollisionShape2D
				break
	if node == null:
		return Rect2()
	var rectangle := node.shape as RectangleShape2D
	if rectangle == null or rectangle.size.x <= 0.0 or rectangle.size.y <= 0.0:
		return Rect2()
	# A RectangleShape2D is centred on its node, and the scale is part of how it was sized by eye.
	var size := rectangle.size * node.scale.abs()
	return Rect2(node.position - size * 0.5, size)


## A Camera2D child's own limits, ignoring Godot's +/-10000000 "not authored" defaults.
func _camera_limit_bounds() -> Rect2:
	var camera: Camera2D = null
	for child in get_children():
		if child is Camera2D:
			camera = child as Camera2D
			break
	if camera == null:
		return Rect2()
	var left := float(camera.limit_left)
	var top := float(camera.limit_top)
	var right := float(camera.limit_right)
	var bottom := float(camera.limit_bottom)
	if right - left >= 1000000.0 or bottom - top >= 1000000.0:
		return Rect2()
	if right <= left or bottom <= top:
		return Rect2()
	return Rect2(Vector2(left, top), Vector2(right - left, bottom - top))


## The terrain of a painted cell, or -1 when the cell is empty or carries no terrain. A tile whose
## terrain has not been assigned yet counts as -1 and is treated as solid, so a half-set-up TileSet
## still produces a playable stage instead of a map with no floor.
func terrain_at(cell: Vector2i) -> int:
	var layer := blocks_layer()
	if layer == null:
		return -1
	var data := layer.get_cell_tile_data(cell)
	if data == null or data.terrain_set != TERRAIN_SET:
		return -1
	return data.terrain


## Solid block cells (inside the stage): everything painted except water.
func block_cells() -> Array[Vector2i]:
	return _cells_where(func(cell: Vector2i) -> bool: return terrain_at(cell) != TERRAIN_WATER)


## Water cells (inside the stage). Not solid; chickens float in them.
func water_cells() -> Array[Vector2i]:
	return _cells_where(func(cell: Vector2i) -> bool: return terrain_at(cell) == TERRAIN_WATER)


## Stone and Border Block are the not-climbable terrains. Falls back to the pre-terrain custom data
## for maps that still use the old block sprite sheet.
func is_no_wall_slide(cell: Vector2i) -> bool:
	var terrain := terrain_at(cell)
	if terrain >= 0:
		return terrain == TERRAIN_STONE or terrain == TERRAIN_BORDER_BLOCK
	var layer := blocks_layer()
	if layer == null or layer.tile_set == null:
		return false
	if not layer.tile_set.has_custom_data_layer_by_name(NO_WALL_SLIDE):
		return false
	var data := layer.get_cell_tile_data(cell)
	return data != null and bool(data.get_custom_data(NO_WALL_SLIDE))


func _cells_where(predicate: Callable) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var layer := blocks_layer()
	if layer == null:
		return cells
	for cell in layer.get_used_cells():
		if predicate.call(cell):
			cells.append(cell)
	cells.sort()
	return cells


## The stage's real extent in tiles: everything the map paints, at least ARENA_SIZE. Drives the
## arena bounds so the camera and clamps follow a larger map instead of the old fixed 32x16.
func stage_size_tiles() -> Vector2i:
	var extent := ARENA_SIZE
	var layers: Array[TileMapLayer] = [markers_layer(), blocks_layer()]
	for layer in layers:
		if layer == null:
			continue
		for cell in layer.get_used_cells():
			extent = Vector2i(maxi(extent.x, cell.x + 1), maxi(extent.y, cell.y + 1))
	return extent


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
		errors.append("Paint at least one block on the Blocks layer (the floor).")
	errors.append_array(_terrain_errors())
	var labels := {MARKER_SPAWN: "Spawn", MARKER_BUILD: "Build Area", MARKER_FLAG: "Flag"}
	for marker in labels:
		if marker_cells(marker).is_empty():
			errors.append("Paint at least one %s marker tile on the DevMarkers layer." % labels[marker])
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


## Warns when the Blocks TileSet does not carry the three terrains this script reads by index, so
## a reordered or renamed terrain set is caught in the editor instead of silently changing which
## cells are climbable or watery. A TileSet with no terrain set at all is not an error: those maps
## fall back to the pre-terrain custom data.
func _terrain_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	var layer := blocks_layer()
	if layer == null or layer.tile_set == null:
		return errors
	var tiles := layer.tile_set
	if tiles.get_terrain_sets_count() <= TERRAIN_SET:
		return errors
	for index in TERRAIN_NAMES.size():
		if tiles.get_terrains_count(TERRAIN_SET) <= index:
			errors.append(
				(
					"The Blocks TileSet needs %d terrains in set %d (%s)."
					% [TERRAIN_NAMES.size(), TERRAIN_SET, ", ".join(TERRAIN_NAMES)]
				)
			)
			break
		var actual := tiles.get_terrain_name(TERRAIN_SET, index)
		if actual != TERRAIN_NAMES[index]:
			errors.append(
				(
					'Terrain %d of the Blocks TileSet should be "%s" but is "%s".'
					% [index, TERRAIN_NAMES[index], actual]
				)
			)
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
	# Clip to the map's own extent, not the fixed ARENA_SIZE: a flag beyond 32x16 used to intersect
	# to nothing and leave the goal unprotected.
	var stage := Rect2(Vector2.ZERO, Vector2(stage_size_tiles()))
	layout.protected_goal_tiles = (
		protected_goal_override_tiles
		if protected_goal_override_tiles.has_area()
		else flag.grow(1.0).intersection(stage)
	)
	layout.build_here_zone_tiles = build_here_zone_tiles
	layout.water_regions_tiles = _water_regions()
	layout.border_regions_tiles = _border_regions()
	layout.stage_size_tiles = stage_size_tiles()
	layout.camera_bounds = camera_bounds_world()
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


## Solid cells merged into rectangles by _merge_runs(), grouped so a Grass run and a Stone run
## never share a surface. The widest lowest rectangle is the floor; Stone gives wall-ineligible
## surfaces.
func _surfaces() -> Array[ArenaSurfaceLayout]:
	var groups := {}
	for cell in block_cells():
		groups[cell] = 1 if is_no_wall_slide(cell) else 0
	var merged := _merge_runs(groups)
	var rects: Array[Rect2i] = merged[0]
	var rect_groups: Array[int] = merged[1]
	var rect_no_wall: Array[bool] = []
	for group in rect_groups:
		rect_no_wall.append(group == 1)
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


## Water cells merged into rectangles, in tiles (the same deterministic merge the solid surfaces
## use, so a water pool is one region instead of one per cell).
func _water_regions() -> Array[Rect2]:
	return _regions_of(water_cells())


## Border marker cells merged into kill rectangles, the same way water pools are merged.
func _border_regions() -> Array[Rect2]:
	return _regions_of(border_cells())


static func _regions_of(cells: Array[Vector2i]) -> Array[Rect2]:
	var groups := {}
	for cell in cells:
		groups[cell] = 0
	var merged := _merge_runs(groups)
	var rects: Array[Rect2i] = merged[0]
	var result: Array[Rect2] = []
	for rect in rects:
		result.append(Rect2(rect))
	return result


## Cells merged into rectangles: maximal horizontal runs per row (cells sharing the same `groups`
## value), stacked with the run directly above when both span the same columns. Deterministic, and
## it reproduces the default stage's six surfaces exactly.
## Returns [Array[Rect2i] rects, Array[int] group of each rect].
static func _merge_runs(groups: Dictionary) -> Array:
	var rects: Array[Rect2i] = []
	var rect_groups: Array[int] = []
	var open_by_span := {}
	var rows: Array = []
	for cell in groups:
		if not rows.has(cell.y):
			rows.append(cell.y)
	rows.sort()
	for y in rows:
		var xs: Array = []
		for cell in groups:
			if cell.y == y:
				xs.append(cell.x)
		xs.sort()
		var next_open := {}
		var index := 0
		while index < xs.size():
			var start: int = xs[index]
			var group: int = groups[Vector2i(start, y)]
			var end := start
			while (
				index + 1 < xs.size()
				and xs[index + 1] == end + 1
				and groups[Vector2i(xs[index + 1], y)] == group
			):
				index += 1
				end = xs[index]
			index += 1
			var span := Vector3i(start, end, group)
			var rect_index := -1
			if open_by_span.has(span) and rects[open_by_span[span]].end.y == y:
				rect_index = open_by_span[span]
				rects[rect_index].size.y += 1
			else:
				rects.append(Rect2i(start, y, end - start + 1, 1))
				rect_groups.append(group)
				rect_index = rects.size() - 1
			next_open[span] = rect_index
		open_by_span = next_open
	return [rects, rect_groups]


static func _bounds(cells: Array[Vector2i]) -> Rect2i:
	if cells.is_empty():
		return Rect2i()
	var rect := Rect2i(cells[0], Vector2i.ONE)
	for cell in cells:
		rect = rect.expand(cell).expand(cell + Vector2i.ONE)
	return rect


func _get_configuration_warnings() -> PackedStringArray:
	return validate()

class_name ArenaLayout
extends Resource

## Data-driven stage layout consumed by ArenaDefinition. The default layout reproduces the literal
## ArenaDefinition geometry exactly (the signature test enforces it); the tutorial layout is a
## second resource. A layout is chosen once per match, so every mode plays on the same stage.
##
## All rectangles are tiles: Rect2(left, top, width, height). Containment walls and the ceiling are
## always generated from the tuned arena size and are not part of a layout.

@export var layout_id := "default"
@export var surfaces: Array[ArenaSurfaceLayout] = []
@export var spawn_feet_tiles := Vector2(3.0, 15.0)
@export var build_region_tiles := Rect2(5.0, 3.0, 23.0, 12.0)
@export var protected_spawn_tiles := Rect2(0.0, 11.0, 5.0, 4.0)
@export var protected_goal_tiles := Rect2(28.0, 9.0, 4.0, 6.0)
@export var goal_trigger_tiles := Rect2(30.0, 10.0, 1.0, 2.0)
## Where a coach marker should point a builder. Empty means "no guidance zone".
@export var build_here_zone_tiles := Rect2()
## Tile row of the floor top, used to describe how high the flag sits.
@export var floor_top_tile := 15.0
## A map scene (scenes/maps/, StageMap root) whose Blocks layer is the stage picture. Set by
## MapCatalog; null keeps the debug stage tiles. Collision always comes from `surfaces`.
@export var map_scene: PackedScene


static func make_default() -> ArenaLayout:
	var layout := ArenaLayout.new()
	layout.layout_id = "default"
	layout.surfaces = [
		_surface("arena.floor", Rect2(0.0, 15.0, 32.0, 1.0), false),
		_surface("arena.base_a", Rect2(6.0, 13.0, 4.0, 2.0), true),
		_surface("arena.base_b", Rect2(12.0, 11.0, 4.0, 1.0), true),
		_surface("arena.base_c", Rect2(18.0, 13.0, 4.0, 2.0), true),
		_surface("arena.base_d", Rect2(24.0, 11.0, 4.0, 1.0), true),
		_surface("arena.goal", Rect2(28.0, 12.0, 4.0, 3.0), true),
	]
	return layout


## Tiles from the floor top to the top of the goal trigger's resting surface.
func flag_height_tiles() -> float:
	return floor_top_tile - (goal_trigger_tiles.position.y + goal_trigger_tiles.size.y)


static func _surface(surface_id: String, rect: Rect2, wall: bool) -> ArenaSurfaceLayout:
	var surface := ArenaSurfaceLayout.new()
	surface.surface_id = surface_id
	surface.rect_tiles = rect
	surface.wall_eligible = wall
	return surface

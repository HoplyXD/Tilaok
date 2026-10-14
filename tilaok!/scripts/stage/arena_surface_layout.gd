class_name ArenaSurfaceLayout
extends Resource

## One immutable base surface of an ArenaLayout. Rectangles are in tiles (fractions allowed), so
## designers edit the stage in the Inspector without touching world units.

@export var surface_id := ""
## Position and size in tiles: Rect2(left, top, width, height).
@export var rect_tiles := Rect2()
## Whether wall slide / wall kick may use this surface's sides (REQ-MOVE-004).
@export var wall_eligible := false
## True when the rectangle is not tile aligned: the stage tile layer skips it and the room draws a
## graybox polygon instead, so the picture matches the collision exactly.
@export var custom_visual := false

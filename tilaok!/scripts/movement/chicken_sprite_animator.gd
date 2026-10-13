class_name ChickenSpriteAnimator
extends AnimatedSprite2D

## Picks the chicken animation from its ChickenController parent every frame. Frames live in the
## SpriteFrames of scenes/characters/chicken.tscn (PLACEHOLDER sheet:
## assets/character/Chicken Placeholder Sprite Sheet.png, 4 cols x 2 rows of 512x512 cells).
## Artists can replace or add frames per animation in the editor without touching this script.

## Sheet cell size in texture pixels; one cell maps onto two grid tiles (a chicken's 1x2 clearance).
const CELL_PX := 512.0
## Below this horizontal speed (wu/s) the chicken counts as standing still.
const MOVE_THRESHOLD_WU_S := 20.0

## Per-animation offset in texture pixels so the feet of every frame sit on the collision bottom.
## Row-1 feet touch the cell bottom; row-2 (air) poses end higher in their cells.
@export var animation_offsets := {
	&"idle": Vector2(0, -16),
	&"run_right": Vector2(0, -16),
	&"run_left": Vector2(0, -16),
	&"wall_slide_right": Vector2(0, -16),
	&"wall_slide_left": Vector2(0, -16),
	&"sneak": Vector2(0, -16),
	&"jump": Vector2(0, 130),
	&"jump_right": Vector2(0, 108),
	&"jump_left": Vector2(0, 108),
	&"glide": Vector2(0, 130),
	&"glide_right": Vector2(0, 108),
	&"glide_left": Vector2(0, 108),
}
## Multiplier on the seat colour so the mid-grey placeholder reads as that colour.
@export var tint_strength := 2.1

var chicken: ChickenController


func _ready() -> void:
	chicken = get_parent() as ChickenController
	if chicken != null and chicken.tuning != null:
		# Two tiles tall: 0.25 on the 64 wu grid (512 px cell -> 128 wu).
		scale = Vector2.ONE * (chicken.tuning.grid_cell_wu * 2.0 / CELL_PX)
	play(&"idle")


func _process(_delta: float) -> void:
	if chicken == null:
		return
	var next := animation_for_state()
	if animation != next:
		play(next)
	offset = animation_offsets.get(next, Vector2.ZERO)
	var base := Color.WHITE if chicken.lifecycle.is_terminal() else chicken.marker_color
	modulate = Color(base.r * tint_strength, base.g * tint_strength, base.b * tint_strength, base.a)


## The animation name for the chicken's current movement state.
func animation_for_state() -> StringName:
	if chicken.sneaking:
		return &"sneak"
	if chicken.wall_sliding and chicken.wall_side != 0:
		return &"wall_slide_right" if chicken.wall_side > 0 else &"wall_slide_left"
	var vx := chicken.velocity.x
	var side := ""
	if vx > MOVE_THRESHOLD_WU_S:
		side = "_right"
	elif vx < -MOVE_THRESHOLD_WU_S:
		side = "_left"
	if not chicken.is_on_floor():
		return StringName(("glide" if chicken.gliding else "jump") + side)
	if side.is_empty():
		return &"idle"
	return StringName("run" + side)

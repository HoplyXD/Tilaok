# gdlint: disable=max-returns
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
	&"stun": Vector2(0, -16),
	&"dead": Vector2(0, 109),
}
## Multiplier on the seat colour so the mid-grey placeholder reads as that colour.
@export var tint_strength := 2.1
## Stunned chickens brighten and dim smoothly at this rate (Hz). Never a hard on/off flash, and
## never above the 3 flashes per second photosensitivity limit; Screen shake Off holds it steady.
@export var stun_pulse_hz := 2.0
## Peak brightness multiplier of the stun pulse (1.0 = the chicken's own colour).
@export var stun_peak_brightness := 2.4
## A steady brightening while stunned so the state never depends on motion.
@export var stun_base_brightness := 1.5

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
	if next == &"stun":
		var level := stun_brightness(
			Time.get_ticks_msec() / 1000.0,
			PresentationApplier.shake_mode,
			stun_pulse_hz,
			stun_base_brightness,
			stun_peak_brightness
		)
		modulate = Color(level, level, level, base.a)


## Brightness multiplier of a stunned chicken at `time_seconds`: a steady brightening plus, unless
## Screen shake is Off, a smooth sine pulse (halved at Reduced). Pure, so it can be sampled.
static func stun_brightness(
	time_seconds: float, shake_level: int, pulse_hz: float, base: float, peak: float
) -> float:
	if shake_level == PresentationApplier.SHAKE_OFF or pulse_hz <= 0.0:
		return base
	var depth := (peak - base) * (1.0 if shake_level == PresentationApplier.SHAKE_FULL else 0.5)
	var wave := 0.5 + 0.5 * sin(TAU * pulse_hz * time_seconds)
	return base + depth * wave


## The animation name for the chicken's current movement state.
func animation_for_state() -> StringName:
	if chicken.lifecycle.status == PlayerLifecycleState.Status.ELIMINATED:
		return &"dead"
	if chicken.is_stunned():
		return &"stun"
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

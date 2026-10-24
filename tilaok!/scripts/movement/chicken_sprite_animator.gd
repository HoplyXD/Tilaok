# gdlint: disable=max-returns
class_name ChickenSpriteAnimator
extends AnimatedSprite2D

## Picks the chicken animation from its ChickenController parent every frame. Frames live in the
## SpriteFrames of scenes/characters/chicken.tscn (assets/character/Chicken 1 Sprite Sheet.png,
## 2048x2048 cells). Artists can replace or add frames per animation in the editor without
## touching this script; node scale and per-animation offsets are authored there too.

## Below this horizontal speed (wu/s) the chicken counts as standing still.
const MOVE_THRESHOLD_WU_S := 20.0

## Per-animation offset in texture pixels (so it scales with the node) that puts the feet of
## every frame on the collision bottom. Unlisted animations sit at the node origin; fill this in
## from the editor for any pose whose art does not already end on the cell's feet line.
@export var animation_offsets := {}
const DEFAULT_TINT_STRENGTH := 2.1

## Multiplier on the seat colour so the mid-grey placeholder reads as that colour.
@export var tint_strength := DEFAULT_TINT_STRENGTH
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
	play(&"idle")


func _process(_delta: float) -> void:
	if chicken == null:
		return
	var next := animation_for_state()
	# A pose the sheet has no frames for yet holds the current one instead of erroring out.
	if sprite_frames == null or not sprite_frames.has_animation(next):
		next = animation
	elif animation != next:
		play(next)
	offset = animation_offsets.get(next, Vector2.ZERO)
	var base := Color.WHITE if chicken.lifecycle.is_terminal() else chicken.marker_color
	modulate = seat_tint(base, tint_strength)
	if next == &"stun":
		var level := stun_brightness(
			Time.get_ticks_msec() / 1000.0,
			PresentationApplier.shake_mode,
			stun_pulse_hz,
			stun_base_brightness,
			stun_peak_brightness
		)
		modulate = Color(level, level, level, base.a)


## The modulate that makes the grey chicken art read as `color` (brightened, alpha kept). The
## results chart uses it too, so its chickens match the ones in the game.
static func seat_tint(color: Color, strength: float = DEFAULT_TINT_STRENGTH) -> Color:
	return Color(color.r * strength, color.g * strength, color.b * strength, color.a)


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
		# jump / jump_left / jump_right, each with a _gliding variant.
		return StringName("jump" + side + ("_gliding" if chicken.gliding else ""))
	if side.is_empty():
		return &"idle"
	return StringName("run" + side)

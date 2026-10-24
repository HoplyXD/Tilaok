# gdlint: disable=max-returns
class_name ChickenSpriteAnimator
extends AnimatedSprite2D

## Picks the chicken animation from its ChickenController parent every frame. Frames live in the
## SpriteFrames of scenes/characters/chicken.tscn (assets/character/Chicken 1 Sprite Sheet.png,
## 2048x2048 cells). Artists can replace or add frames per animation in the editor without
## touching this script; node scale and per-animation offsets are authored there too.
##
## `play()` is called once per pose change, never per frame, so each animation's own loop /
## no-loop flag in the SpriteFrames decides whether it repeats. Three poses are transitions that
## must be seen in full before the next one starts, and they are gated on `animation_finished`:
##   `sneak` -> `sneak_hold`, `sneak_stand` -> idle/run, `jump*_landing` -> idle/run.
## Because that gate needs the pose to end on its own, each is authored non-looping; a pose that
## loops (or is missing from the sheet) is never waited for, so a mis-set flag cannot deadlock.
##
## Left/right comes from `ChickenController.facing_input` -- the movement key the controller
## accepted -- not from velocity, so a chicken sliding on ice or taking knockback reads as idle.

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

var _was_on_floor := true
var _was_sneaking := false
var _was_stunned := false
## Set from touching down until `_landing_pose` has played out; its name is latched at touchdown
## so turning mid-landing cannot restart the animation.
var _landing := false
var _landing_pose := &""
## True once the one-shot `sneak` intro has played, so `sneak_hold` takes over.
var _sneak_held := false
## Set from releasing down until `sneak_stand` has played out.
var _standing_up := false
## Replays the resolved pose even when its name has not changed, for the moments that should
## restart it: a fresh stun, a fresh takeoff, entering sneak, touching down.
var _replay := false


func _ready() -> void:
	chicken = get_parent() as ChickenController
	animation_finished.connect(_on_animation_finished)
	if chicken != null:
		_was_on_floor = chicken.is_on_floor()
	play(&"idle")


func _process(_delta: float) -> void:
	if chicken == null:
		return
	_track_transitions()
	var next := pose_for_state()
	# A pose the sheet has no frames for yet holds the current one instead of erroring out.
	if sprite_frames == null or not sprite_frames.has_animation(next):
		next = animation
	elif next != animation or _replay:
		play(next)
	_replay = false
	offset = animation_offsets.get(animation, Vector2.ZERO)
	_apply_tint()


## Watches the ground, sneak and stun edges that the one-shot transition poses hang off.
func _track_transitions() -> void:
	var grounded := chicken.is_on_floor()
	if grounded != _was_on_floor:
		_replay = true
		if grounded:
			# "always play after hitting the ground"
			_landing_pose = StringName("jump" + _side() + "_landing")
			_landing = _ends_on_its_own(_landing_pose)
		else:
			_landing = false
	_was_on_floor = grounded
	var sneaking := chicken.sneaking
	if sneaking != _was_sneaking:
		_replay = true
		if sneaking:
			# The intro plays first; `sneak_hold` follows only once it has finished.
			_sneak_held = not _ends_on_its_own(&"sneak")
			_standing_up = false
		else:
			_standing_up = _ends_on_its_own(&"sneak_stand")
			_sneak_held = false
	_was_sneaking = sneaking
	var stunned := chicken.is_stunned()
	if stunned and not _was_stunned:
		_replay = true
	_was_stunned = stunned


func _on_animation_finished() -> void:
	if animation == _landing_pose:
		_landing = false
	elif animation == &"sneak":
		_sneak_held = true
	elif animation == &"sneak_stand":
		_standing_up = false


## True when `pose` is in the sheet and authored non-looping, so it reaches `animation_finished`
## on its own. A missing or looping pose is never waited for, so it cannot stall a transition.
func _ends_on_its_own(pose: StringName) -> bool:
	if sprite_frames == null or not sprite_frames.has_animation(pose):
		return false
	return not sprite_frames.get_animation_loop(pose)


## "_left" / "_right" / "" from the movement key the controller accepted this step.
func _side() -> String:
	if chicken.facing_input > 0:
		return "_right"
	if chicken.facing_input < 0:
		return "_left"
	return ""


func _apply_tint() -> void:
	var base := Color.WHITE if chicken.lifecycle.is_terminal() else chicken.marker_color
	modulate = seat_tint(base, tint_strength)
	if animation == &"stun":
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


## The pose the chicken's current state calls for, highest priority first. `dead` is not one of
## the authored movement poses but stays top of the list, for the death sprite (GDD §6).
func pose_for_state() -> StringName:
	if chicken.lifecycle.status == PlayerLifecycleState.Status.ELIMINATED:
		return &"dead"
	if chicken.is_stunned():
		return &"stun"
	if chicken.sneaking:
		return &"sneak_hold" if _sneak_held else &"sneak"
	if chicken.wall_sliding and chicken.wall_side != 0:
		# The wall the chicken is held against, which is the side it is pressing toward.
		return &"wall_slide_right" if chicken.wall_side > 0 else &"wall_slide_left"
	var side := _side()
	if not chicken.is_on_floor():
		# Airborne, in the order one jump passes through them. Rising reads as the jump itself;
		# `_falling` covers walking off a ledge too, where there was no jump to follow.
		if chicken.gliding:
			return StringName("jump" + side + "_gliding")
		if chicken.velocity.y > 0.0:
			return StringName("jump" + side + "_falling")
		return StringName("jump" + side)
	# Grounded. The landing and stand-up one-shots play out before idle or run resume; both are
	# cut short by a new jump, since the airborne branch above is reached first.
	if _landing:
		return _landing_pose
	if _standing_up:
		return &"sneak_stand"
	if side.is_empty():
		return &"idle"
	return StringName("run" + side)

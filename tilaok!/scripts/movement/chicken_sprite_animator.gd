# gdlint: disable=max-returns
class_name ChickenSpriteAnimator
extends AnimatedSprite2D

## Picks the chicken animation from its ChickenController every frame. scenes/characters/
## chicken.tscn groups one of these sprites per chicken colour under its Animations node, each
## with its own SpriteFrames (assets/character/Chicken Sprites/<colour>/, 2048x2048 frames), and
## shows only the one whose `skin_color` is nearest the chicken's `marker_color`. The art is
## already coloured, so nothing is tinted. Artists can replace or add frames per animation in the
## editor without touching this script; node scale and per-animation offsets are authored there.
##
## `play()` is called once per pose change, never per frame, so each animation's own loop /
## no-loop flag in the SpriteFrames decides whether it repeats. Three poses are transitions that
## must be seen in full before the next one starts, and they are gated on `animation_finished`:
##   `sneak` -> `sneak_hold`, `sneak_stand` -> idle/run, `jump*_landing` -> idle/run.
## Because that gate needs the pose to end on its own, each is authored non-looping; a pose that
## loops (or is missing from the sheet) is never waited for, so a mis-set flag cannot deadlock.
##
## Left/right of running and of the rising `jump` comes from `ChickenController.facing_input` --
## the movement key the controller accepted -- so a chicken sliding on ice reads as idle. Falling,
## gliding and landing instead follow where the chicken is actually moving (`velocity.x`), so a
## chicken knocked or drifting left falls, glides and lands facing left whatever key is held.

const CHICKEN_SCENE := "res://scenes/characters/chicken.tscn"
## The sprite sheets' crouch art sits below the controller origin; raise only the captive artwork
## so its visual center aligns with the bubble center. This is a local-world-unit offset.
const CAPTURED_CROUCH_CENTER_OFFSET := Vector2(0.0, -20.0)
## skin_color -> SpriteFrames of every colour sprite in the chicken scene, read on first use.
static var _skin_frames := {}

## Lobby slot previews should hold a standing idle pose independent of gameplay state.
@export var force_idle_preview := false

## Per-animation offset in texture pixels (so it scales with the node) that puts the feet of
## every frame on the collision bottom. Unlisted animations sit at the node origin; fill this in
## from the editor for any pose whose art does not already end on the cell's feet line.
@export var animation_offsets := {}
## The seat colour this sprite's art is drawn in (PlayerSeatRegistry.COLORS). Of the sprites
## under one chicken, only the one nearest the chicken's marker_color is shown.
@export var skin_color := Color("#f2c14e")
## Below this horizontal speed (wu/s) a falling, gliding or landing chicken counts as moving
## straight down and plays the sideless pose.
@export var drift_deadzone_wu_s := 40.0
## Seconds a chicken that walked or slid off a ledge (no jump) keeps its run/idle pose before
## `jump*_falling` takes over, so small drops do not flick to the falling pose. After a real jump
## the falling pose instead follows as soon as the jump animation has played out.
@export var falling_delay_s := 1.0
## Stunned chickens brighten and dim smoothly at this rate (Hz). Never a hard on/off flash, and
## never above the 3 flashes per second photosensitivity limit; Screen shake Off holds it steady.
@export var stun_pulse_hz := 2.0
## Peak brightness multiplier of the stun pulse (1.0 = the chicken's own colour).
@export var stun_peak_brightness := 2.4
## A steady brightening while stunned so the state never depends on motion.
@export var stun_base_brightness := 1.5

var chicken: ChickenController
var _authored_position := Vector2.ZERO

var _was_on_floor := true
var _was_sneaking := false
var _was_stunned := false
## Where the chicken was moving on its last airborne frame, for the landing pose.
var _air_side := ""
## Seconds since the chicken last left the ground; 0 while grounded.
var _air_time := 0.0
## True when this airborne spell began with (or turned into) a rise: a jump, a coyote jump or a
## launch. False for walking off a ledge.
var _jumped := false
## Set once the jump pose has played out, so `jump*_falling` follows it at once.
var _jump_done := false
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
	chicken = _owning_chicken()
	_authored_position = position
	animation_finished.connect(_on_animation_finished)
	if chicken != null:
		_was_on_floor = chicken.is_on_floor()
	play(&"idle")


func _process(delta: float) -> void:
	if chicken == null:
		return
	visible = _wears_this_skin()
	_track_transitions(delta)
	var captured := chicken.lifecycle.status == PlayerLifecycleState.Status.CAPTURED
	if captured:
		# Bula capture is an immediate held crouch; do not play the ordinary sneak intro.
		_sneak_held = true
		_standing_up = false
	position = _authored_position + (CAPTURED_CROUCH_CENTER_OFFSET if captured else Vector2.ZERO)
	var next := &"idle" if force_idle_preview else pose_for_state()
	# A pose the sheet has no frames for yet holds the current one instead of erroring out.
	if sprite_frames == null or not sprite_frames.has_animation(next):
		next = animation
	elif next != animation or _replay:
		play(next)
	_replay = false
	offset = animation_offsets.get(animation, Vector2.ZERO)
	_apply_stun_pulse()


## The ChickenController this sprite belongs to: its parent, or further up when the sprite sits
## under the Animations node that groups one sprite per colour.
func _owning_chicken() -> ChickenController:
	var node := get_parent()
	while node != null and not node is ChickenController:
		node = node.get_parent()
	return node as ChickenController


## True when this sprite is the sibling whose skin_color is nearest the chicken's marker_color
## (the first one on a tie), so exactly one colour of each chicken is drawn.
func _wears_this_skin() -> bool:
	var worn: ChickenSpriteAnimator = null
	for node in get_parent().get_children():
		var skin := node as ChickenSpriteAnimator
		if skin == null:
			continue
		if (
			worn == null
			or (
				skin_distance(skin.skin_color, chicken.marker_color)
				< skin_distance(worn.skin_color, chicken.marker_color)
			)
		):
			worn = skin
	return worn == self


## Watches the ground, sneak and stun edges that the one-shot transition poses hang off.
func _track_transitions(delta: float) -> void:
	var grounded := chicken.is_on_floor()
	if grounded != _was_on_floor:
		if grounded:
			_replay = true
			# "always play after hitting the ground", facing the way it was moving when it did.
			_landing_pose = StringName("jump" + _air_side + "_landing")
			_landing = _ends_on_its_own(_landing_pose)
		else:
			_landing = false
			_jumped = false
	_air_time = 0.0 if grounded else _air_time + delta
	if not grounded and not _jumped and chicken.velocity.y < 0.0:
		# Rising from the ground or a coyote jump: the jump pose starts over.
		_jumped = true
		_jump_done = not _ends_on_its_own(StringName("jump" + _side()))
		_replay = true
	if not grounded and chicken.gliding:
		# A glide ends the jump pose; letting go of it falls straight away.
		_jumped = true
		_jump_done = true
	if not grounded:
		_air_side = _motion_side()
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
	elif animation in [&"jump", &"jump_left", &"jump_right"]:
		_jump_done = true
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


## "_left" / "_right" / "" from where the chicken is actually moving, "" inside the deadzone.
func _motion_side() -> String:
	if chicken.velocity.x > drift_deadzone_wu_s:
		return "_right"
	if chicken.velocity.x < -drift_deadzone_wu_s:
		return "_left"
	return ""


func _apply_stun_pulse() -> void:
	if animation != &"stun":
		modulate = Color.WHITE
		return
	var level := stun_brightness(
		Time.get_ticks_msec() / 1000.0,
		PresentationApplier.shake_mode,
		stun_pulse_hz,
		stun_base_brightness,
		stun_peak_brightness
	)
	modulate = Color(level, level, level, 1.0)


## How far apart two colours are, for matching a seat colour to the nearest chicken skin.
static func skin_distance(left: Color, right: Color) -> float:
	return Vector3(left.r - right.r, left.g - right.g, left.b - right.b).length_squared()


## The SpriteFrames of the chicken-scene sprite drawn in the colour nearest `color`. The results
## chart uses it, so its chickens are the same coloured art as the ones in the game.
static func frames_for_color(color: Color) -> SpriteFrames:
	if _skin_frames.is_empty():
		var scene := load(CHICKEN_SCENE) as PackedScene
		var root := scene.instantiate() if scene != null else null
		if root != null:
			for node in root.find_children("*", "AnimatedSprite2D", true, false):
				var skin := node as ChickenSpriteAnimator
				if skin != null and skin.sprite_frames != null:
					_skin_frames[skin.skin_color] = skin.sprite_frames
			root.free()
	var best: SpriteFrames = null
	var best_distance := INF
	for skin_color in _skin_frames:
		var distance := skin_distance(skin_color, color)
		if distance < best_distance:
			best = _skin_frames[skin_color]
			best_distance = distance
	return best


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
	if not chicken.is_on_floor():
		# Airborne. Rising reads as the jump itself and follows the key; falling and gliding follow
		# where the chicken is moving. After a jump, `_falling` follows the moment the jump pose has
		# played out. Walking off a ledge keeps the run/idle pose for `falling_delay_s` first.
		if chicken.gliding:
			return StringName("jump" + _motion_side() + "_gliding")
		if _jumped:
			if _jump_done:
				return StringName("jump" + _motion_side() + "_falling")
			return StringName("jump" + _side())
		if _air_time >= falling_delay_s:
			return StringName("jump" + _motion_side() + "_falling")
		return _locomotion_pose()
	# Grounded. The landing and stand-up one-shots play out before idle or run resume; both are
	# cut short by a new jump, since the airborne branch above is reached first.
	if _landing:
		return _landing_pose
	if _standing_up:
		return &"sneak_stand"
	return _locomotion_pose()


## `idle`, or `run_left` / `run_right` from the accepted movement key.
func _locomotion_pose() -> StringName:
	var side := _side()
	if side.is_empty():
		return &"idle"
	return StringName("run" + side)

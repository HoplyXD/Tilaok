class_name ChickenController
extends CharacterBody2D

signal intentional_input_changed(is_intentional: bool)
signal terminal_state_changed(status: PlayerLifecycleState.Status, reason: String)
signal escaped_bounds
signal wall_kicked(side: int)
signal sneak_changed(is_sneaking: bool)
signal stunned(seconds: float)

const WATER_DRAG := 0.86
const IDENTITY_MARKER_TEXTURES := {
	"CIRCLE": preload("res://assets/ui/common/identity_circle.svg"),
	"TRIANGLE": preload("res://assets/ui/common/identity_triangle.svg"),
	"SQUARE": preload("res://assets/ui/common/identity_square.svg"),
	"DIAMOND": preload("res://assets/ui/common/identity_diamond.svg"),
}
## Hitbox children of scenes/characters/chicken.tscn. Exactly one is ever enabled: the state
## below picks it, and ChickenSpriteAnimator picks its animation from that same state, so the
## pose on screen and the body in the physics world never disagree. The first unnamed rectangle
## shape is the standing body, so a chicken built in code with a single shape still works.
const JUMP_SHAPE_NODE := "JumpHitbox"
const SNEAK_SHAPE_NODE := "SneakHitbox"

@export var seat_index := 0
@export var tuning: GameplayTuning
@export var input_router: LocalInputRouter
@export var identity_number := 1
@export var identity_shape := "CIRCLE"
@export var marker_color := Color("#f2c14e")
@export var bounds := Rect2(Vector2.ZERO, Vector2(2048.0, 1024.0))
## False when the scene supplies a sprite (scenes/characters/chicken.tscn); the code-drawn DEBUG
## body is then skipped, but the number/shape identity marker above the head is still drawn.
@export var draw_debug_body := true
## False hides the number/shape marker above the head (the lobby preview chickens, whose card
## already names the player with its shape).
@export var draw_identity_marker := true

var simulation_authority := SimulationAuthority.offline()
var support_tracker: SupportTracker
var support_actor_id := ""
var lifecycle := PlayerLifecycleState.new()
var locomotion_velocity := Vector2.ZERO
var external_velocity := Vector2.ZERO
var coyote_remaining := 0.0
var jump_buffer_remaining := 0.0
var jump_was_held := false
var intentional_input := false
## Sign of the movement key the controller accepted this step: -1 left, +1 right, 0 neither.
## ChickenSpriteAnimator picks its left/right pose from this, so the pose follows the key the
## player is holding rather than the velocity -- ice slides and knockback do not read as running.
## Zero whenever the controller ignores movement (build mode, no seat, outside Play).
var facing_input := 0
## Build mode suppresses direct player movement while leaving gravity, collisions and external
## forces active. The live-build room owns this per-seat lock.
var build_input_locked := false
var containment_outcome_reported := false
## Wall slide/jump state (REQ-MOVE-004). Side: -1 wall on the left, +1 on the right, 0 none.
var wall_side := 0
var wall_lock_side := 0
var wall_sliding := false
var wall_kick_count := 0
var show_wall_debug := false
## Sneak (hold down while grounded): body shrinks to sneak_height_wu at the feet; no walking or
## jumping. Glide (hold jump while falling): descent capped at glide_fall_cap_wu_s.
var sneaking := false
## Stun (block STUN hitboxes): controls frozen while > 0; a short immunity follows each stun.
var stun_remaining := 0.0
var stun_immunity_remaining := 0.0
var gliding := false
## True while standing on a slippery block (Yelo ice, 2026-10-16); refreshed every step.
var on_ice := false
## Water volumes in world units (ArenaDefinition.water_regions). Empty on a stage without water.
var water_regions: Array[Rect2] = []
## Kill volumes in world units (ArenaDefinition.border_regions). A chicken whose centre enters one
## is eliminated. Empty on a stage that paints no Border, which then has no boundary at all.
var border_regions: Array[Rect2] = []
## True while the body's centre is inside a water volume; the chicken floats instead of falling.
var in_water := false
## True while a jump pressed in water is still rising, so buoyancy and drag leave the arc alone.
var water_jumping := false
## Per-physics-step velocity retained while floating. Below 1.0 it damps the rise/fall overshoot so
## a chicken settles at the waterline; it is a feel constant, not a tuned magnitude.
var _water_surface_y := 0.0
var _ascent_gravity := 1875.0
var _fall_gravity := 2531.25
var _jump_impulse := -600.0
var _vertical_half_step := 0.0
var _wall_probe := WallContactProbe.new()
var _wall_grace_remaining := 0.0
var _wall_grace_side := 0
var _wall_collider_id := 0
var _wall_debug_signature := 0
var _body_shape: CollisionShape2D
var _jump_shape: CollisionShape2D
var _sneak_shape: CollisionShape2D
var _standing_size := Vector2.ZERO
var _standing_offset := Vector2.ZERO
## True while the compact airborne body is the enabled hitbox. Not the same as `not is_on_floor()`:
## a chicken that lands with no headroom keeps the small body until it fits again.
var _airborne_body := false
var _contact_sensor: ChickenContactSensor


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_to_group("chickens")
	if tuning == null:
		tuning = GameplayTuning.new()
	_apply_tuning()
	if input_router != null:
		input_router.action_pressed.connect(_on_action_pressed)
		input_router.phase_changed.connect(_on_phase_changed)
	var contact_sensor := ChickenContactSensor.new()
	contact_sensor.name = "ContactSensor"
	contact_sensor.contact_size = Vector2(
		tuning.contact_sensor_width_wu, tuning.contact_sensor_height_wu
	)
	contact_sensor.collision_layer = 0
	contact_sensor.collision_mask = 2
	add_child(contact_sensor)
	_contact_sensor = contact_sensor
	_capture_body_shape()


func _exit_tree() -> void:
	_clear_support()
	if input_router != null and input_router.action_pressed.is_connected(_on_action_pressed):
		input_router.action_pressed.disconnect(_on_action_pressed)
	if input_router != null and input_router.phase_changed.is_connected(_on_phase_changed):
		input_router.phase_changed.disconnect(_on_phase_changed)


func _physics_process(delta: float) -> void:
	if (
		input_router == null
		or get_tree().paused
		or simulation_authority == null
		or not simulation_authority.can_commit()
	):
		return
	var in_play := input_router.phase == LocalInputRouter.Phase.PLAY
	if not in_play:
		_clear_support()
	# In build mode the movement keys drive the block cursor, so the chicken holds still.
	var building := in_play and (input_router.is_build_mode(seat_index) or build_input_locked)
	var controls_active := in_play and not building
	var axis := input_router.movement_axis(seat_index) if controls_active else 0.0
	# Captured before stun and sneak zero `axis` below: those poses have no left/right variant,
	# and the animator should still know which way a recovering chicken is asking to go.
	facing_input = 0 if is_zero_approx(axis) else (1 if axis > 0.0 else -1)
	var jump_down := controls_active and input_router.is_action_held(seat_index, "jump")
	var next_intent := (
		controls_active
		and (input_router.has_direction_intent(seat_index) or absf(axis) > 0.0 or jump_down)
	)
	if intentional_input != next_intent:
		intentional_input = next_intent
		intentional_input_changed.emit(intentional_input)
	if controls_active and input_router.consume_pressed(seat_index, "jump"):
		jump_buffer_remaining = tuning.jump_buffer_seconds
	elif building:
		jump_buffer_remaining = 0.0
	else:
		jump_buffer_remaining = maxf(0.0, jump_buffer_remaining - delta)
	if not in_play:
		jump_buffer_remaining = 0.0
		_vertical_half_step = 0.0
		reset_wall_state()
		reset_sneak()
		clear_stun()
		return

	if _advance_locked_state(delta):
		return
	stun_immunity_remaining = maxf(0.0, stun_immunity_remaining - delta)
	var stunned_now := stun_remaining > 0.0
	if building:
		# Entering build mode stops player-driven horizontal motion immediately. Gravity and
		# external motion from hazards remain part of the live simulation.
		locomotion_velocity.x = 0.0
		jump_was_held = false
	if stunned_now:
		# Stunned: no walking, jumping, gliding or sneaking until the timer runs out.
		stun_remaining = maxf(0.0, stun_remaining - delta)
		axis = 0.0
		jump_down = false
		jump_buffer_remaining = 0.0
	_update_sneak(input_router.is_action_held(seat_index, "down") and not stunned_now)
	if sneaking:
		# Sneaking chickens hold still: no walking and no jump (buffered presses are dropped).
		axis = 0.0
		locomotion_velocity.x = 0.0
		jump_buffer_remaining = 0.0
	_update_water()
	_update_wall_contact(delta)
	_update_horizontal(axis, delta)
	if in_water:
		_update_float(delta)
	else:
		_update_vertical(delta, jump_down)
	var combined := locomotion_velocity + external_velocity
	combined.y -= _vertical_half_step
	velocity = combined
	move_and_slide()
	if support_tracker != null and not support_actor_id.is_empty():
		support_tracker.record_actor_step(support_actor_id, self, Engine.get_physics_frames())
	locomotion_velocity = Vector2(
		velocity.x - external_velocity.x, velocity.y - external_velocity.y + _vertical_half_step
	)
	if is_on_floor() and locomotion_velocity.y > 0.0:
		locomotion_velocity.y = 0.0
	elif is_on_ceiling() and locomotion_velocity.y < 0.0:
		locomotion_velocity.y = 0.0
	_update_external_motion(delta)
	if is_on_floor() and external_velocity.length_squared() <= 0.01:
		coyote_remaining = tuning.coyote_seconds
	elif external_velocity.length_squared() > 0.01:
		coyote_remaining = 0.0
	_notify_block_contacts(axis)
	_update_body_shape_for_air()
	_refresh_wall_debug()
	_check_border()
	_check_bounds()


## An eliminated chicken has no control but keeps falling (user request, 2026-10-15) until
## it lands on a solid, instead of hanging in the air. It drifts no further sideways, never
## supports anyone, never touches blocks or hazards again and never reports leaving the stage:
## once it falls out of bounds it simply stops.
func _fall_while_eliminated(delta: float) -> void:
	external_velocity = Vector2.ZERO
	_vertical_half_step = 0.0
	if not bounds.has_point(global_position):
		velocity = Vector2.ZERO
		locomotion_velocity = Vector2.ZERO
		return
	var fall_speed := minf(velocity.y + _fall_gravity * delta, tuning.fall_speed_cap_wu_s)
	velocity = Vector2(0.0, maxf(fall_speed, 0.0) if is_on_floor() else fall_speed)
	move_and_slide()
	if is_on_floor() and velocity.y > 0.0:
		velocity.y = 0.0
	locomotion_velocity = velocity


## Eliminated, opening freeze, captured and mid-climb chickens skip normal movement this step.
func _advance_locked_state(delta: float) -> bool:
	if lifecycle.is_terminal():
		_clear_support()
		reset_wall_state()
		if lifecycle.status == PlayerLifecycleState.Status.ELIMINATED:
			_fall_while_eliminated(delta)
		else:
			locomotion_velocity = Vector2.ZERO
		return true
	if lifecycle.status == PlayerLifecycleState.Status.OPENING_FREEZE:
		_clear_support()
		reset_wall_state()
		locomotion_velocity = Vector2.ZERO
		external_velocity = Vector2.ZERO
		jump_buffer_remaining = 0.0
		coyote_remaining = 0.0
		return true
	if lifecycle.status == PlayerLifecycleState.Status.CAPTURED:
		_clear_support()
		reset_wall_state()
		locomotion_velocity = Vector2.ZERO
		jump_buffer_remaining = 0.0
		coyote_remaining = 0.0
		return true
	return false


func set_snapshot(snapshot: ConfigurationSnapshot) -> void:
	if not _can_mutate() or snapshot == null or snapshot.gameplay == null:
		return
	tuning = snapshot.gameplay
	_apply_tuning()
	reset_wall_state()


## Negative caps use the tuning launch caps.
func launch(force: Vector2, max_horizontal: float = -1.0, max_upward: float = -1.0) -> void:
	if (
		not _can_mutate()
		or lifecycle.is_terminal()
		or (
			lifecycle.status
			in [PlayerLifecycleState.Status.CAPTURED, PlayerLifecycleState.Status.OPENING_FREEZE]
		)
	):
		return
	if max_horizontal < 0.0:
		max_horizontal = tuning.launch_max_horizontal_wu_s
	if max_upward < 0.0:
		max_upward = tuning.launch_max_upward_wu_s
	_clear_support()
	reset_wall_state()
	reset_sneak()
	external_velocity += force
	external_velocity.x = clampf(external_velocity.x, -max_horizontal, max_horizontal)
	external_velocity.y = maxf(external_velocity.y, -max_upward)
	locomotion_velocity.y = 0.0
	coyote_remaining = 0.0
	jump_buffer_remaining = 0.0


func set_captured(captured: bool, source_id: String = "") -> void:
	if not _can_mutate() or lifecycle.is_terminal():
		return
	if captured:
		if lifecycle.status == PlayerLifecycleState.Status.OPENING_FREEZE:
			return
		lifecycle.status = PlayerLifecycleState.Status.CAPTURED
		_clear_support()
		reset_wall_state()
		reset_sneak()
		lifecycle.capture_source_id = source_id
		locomotion_velocity = Vector2.ZERO
		coyote_remaining = 0.0
		jump_buffer_remaining = 0.0
	else:
		if lifecycle.status != PlayerLifecycleState.Status.CAPTURED:
			return
		lifecycle.status = PlayerLifecycleState.Status.ACTIVE
		lifecycle.capture_source_id = ""


## Moves a captured chicken with its bubble. Only a CAPTURED chicken may be carried, so a bubble
## can never teleport an active, secured or eliminated player.
func carry_captive_to(world_position: Vector2) -> bool:
	if not _can_mutate() or lifecycle.status != PlayerLifecycleState.Status.CAPTURED:
		return false
	global_position = world_position
	velocity = Vector2.ZERO
	return true


## Clears forced motion and buffered input so a lower-priority state cannot resume after a
## capture or release. Does not alter lifecycle status.
func clear_external_motion() -> void:
	if not _can_mutate():
		return
	external_velocity = Vector2.ZERO
	locomotion_velocity = Vector2.ZERO
	velocity = Vector2.ZERO
	coyote_remaining = 0.0
	jump_buffer_remaining = 0.0


func set_opening_freeze(frozen: bool) -> void:
	if not _can_mutate() or lifecycle.is_terminal():
		return
	if frozen:
		lifecycle.status = PlayerLifecycleState.Status.OPENING_FREEZE
		_clear_support()
		reset_wall_state()
		reset_sneak()
		locomotion_velocity = Vector2.ZERO
		external_velocity = Vector2.ZERO
		coyote_remaining = 0.0
		jump_buffer_remaining = 0.0
	else:
		if lifecycle.status == PlayerLifecycleState.Status.OPENING_FREEZE:
			lifecycle.status = PlayerLifecycleState.Status.ACTIVE


func contact_overlaps() -> Array[Node2D]:
	if _contact_sensor == null or not is_instance_valid(_contact_sensor):
		return []
	return _contact_sensor.overlaps()


func secure(reason: String = "secured") -> bool:
	if not _can_mutate():
		return false
	return _set_terminal(PlayerLifecycleState.Status.SECURED, reason)


func eliminate(reason: String = "eliminated") -> bool:
	if not _can_mutate():
		return false
	return _set_terminal(PlayerLifecycleState.Status.ELIMINATED, reason)


## Restores this seat for a new round without recreating its node or identity markers.
func reset_for_round(spawn_position: Vector2) -> void:
	if not _can_mutate():
		return
	_clear_support()
	global_position = spawn_position
	velocity = Vector2.ZERO
	locomotion_velocity = Vector2.ZERO
	external_velocity = Vector2.ZERO
	coyote_remaining = 0.0
	jump_buffer_remaining = 0.0
	jump_was_held = false
	_vertical_half_step = 0.0
	intentional_input = false
	containment_outcome_reported = false
	lifecycle.status = PlayerLifecycleState.Status.ACTIVE
	lifecycle.capture_source_id = ""
	lifecycle.terminal_reason = ""
	reset_wall_state()
	clear_stun()


## Stun touch: freeze controls for `seconds` and knock back (through launch, so all launch caps
## and precedence apply). Refused while terminal, captured, frozen or stun-immune.
func apply_stun(seconds: float, knockback: Vector2 = Vector2.ZERO) -> bool:
	if (
		not _can_mutate()
		or seconds <= 0.0
		or stun_immunity_remaining > 0.0
		or lifecycle.is_terminal()
	):
		return false
	if (
		lifecycle.status
		in [PlayerLifecycleState.Status.CAPTURED, PlayerLifecycleState.Status.OPENING_FREEZE]
	):
		return false
	if knockback != Vector2.ZERO:
		launch(knockback)
	stun_remaining = seconds
	stun_immunity_remaining = seconds + tuning.stun_immunity_s
	stunned.emit(seconds)
	return true


func is_stunned() -> bool:
	return stun_remaining > 0.0


func clear_stun() -> void:
	if not _can_mutate():
		return
	stun_remaining = 0.0
	stun_immunity_remaining = 0.0


func _set_terminal(status: PlayerLifecycleState.Status, reason: String) -> bool:
	if not _can_mutate():
		return false
	if not lifecycle.set_status(status, reason):
		return false
	_clear_support()
	reset_wall_state()
	reset_sneak()
	clear_stun()
	locomotion_velocity = Vector2.ZERO
	external_velocity = Vector2.ZERO
	jump_buffer_remaining = 0.0
	coyote_remaining = 0.0
	terminal_state_changed.emit(status, reason)
	return true


## Clears every wall contact/lock/grace field. Called from each reset, lifecycle and launch path.
func reset_wall_state() -> void:
	wall_side = 0
	wall_lock_side = 0
	wall_sliding = false
	_wall_grace_remaining = 0.0
	_wall_grace_side = 0
	_wall_collider_id = 0
	_wall_probe.clear()
	_refresh_wall_debug()


func _update_wall_contact(delta: float) -> void:
	if (
		not tuning.wall_movement_enabled
		or is_on_floor()
		or external_velocity.length_squared() > 0.01
	):
		if wall_side != 0 or wall_lock_side != 0 or _wall_grace_remaining > 0.0 or wall_sliding:
			reset_wall_state()
		return
	if (
		wall_lock_side != 0
		and not _wall_probe.has_eligible_wall(
			self, tuning, wall_lock_side, tuning.wall_jump_recontact_separation_wu
		)
	):
		wall_lock_side = 0
	var previous_side := wall_side
	var preferred := previous_side if previous_side != 0 else _wall_grace_side
	if _wall_probe.sample(self, tuning, preferred) != 0:
		wall_side = _wall_probe.side
		_wall_collider_id = _wall_probe.collider_id
		_wall_grace_side = wall_side
		_wall_grace_remaining = 0.0
		return
	wall_side = 0
	if previous_side != 0 and tuning.wall_jump_contact_grace_s > 0.0:
		_wall_grace_remaining = tuning.wall_jump_contact_grace_s
		_wall_grace_side = previous_side
	elif _wall_grace_remaining > 0.0:
		_wall_grace_remaining = maxf(0.0, _wall_grace_remaining - delta)
	if _wall_grace_remaining <= 0.0 or not WallContactProbe.collider_is_live(_wall_collider_id):
		_wall_grace_remaining = 0.0
		_wall_grace_side = 0
		_wall_collider_id = 0


func _try_wall_kick() -> void:
	if not tuning.wall_movement_enabled:
		return
	var kick_side := wall_side
	if kick_side == 0 and _wall_grace_remaining > 0.0:
		kick_side = _wall_grace_side
	if kick_side == 0 or kick_side == wall_lock_side:
		return
	locomotion_velocity.x = -float(kick_side) * tuning.wall_jump_horizontal_wu_s
	locomotion_velocity.y = tuning.wall_jump_vertical_wu_s
	jump_buffer_remaining = 0.0
	wall_lock_side = kick_side
	wall_side = 0
	wall_sliding = false
	_wall_grace_remaining = 0.0
	_wall_grace_side = 0
	wall_kick_count += 1
	wall_kicked.emit(kick_side)


func _refresh_wall_debug() -> void:
	if not show_wall_debug:
		return
	var signature := wall_side * 9 + wall_lock_side * 3 + (1 if wall_sliding else 0)
	if signature != _wall_debug_signature:
		_wall_debug_signature = signature
		queue_redraw()


## Leaves sneak when there is headroom; a chicken under a low ceiling stays small.
func reset_sneak() -> void:
	if sneaking and _can_stand():
		_set_sneak_shape(false)


func _update_sneak(down_held: bool) -> void:
	if not sneaking:
		if (
			tuning.sneak_enabled
			and down_held
			and is_on_floor()
			and external_velocity.length_squared() <= 0.01
		):
			_set_sneak_shape(true)
	elif (not down_held or not tuning.sneak_enabled) and _can_stand():
		_set_sneak_shape(false)


func _capture_body_shape() -> void:
	if _body_shape != null:
		return
	for child in get_children():
		if not (child is CollisionShape2D):
			continue
		var collision := child as CollisionShape2D
		if not (collision.shape is RectangleShape2D):
			continue
		var node_name := str(collision.name)
		if node_name == JUMP_SHAPE_NODE:
			_jump_shape = collision
		elif node_name == SNEAK_SHAPE_NODE:
			_sneak_shape = collision
		elif _body_shape == null:
			_body_shape = collision
	if _body_shape == null:
		return
	# Own the shapes so resizing one never affects another chicken sharing the resource.
	for owned in _hitboxes():
		owned.shape = owned.shape.duplicate()
	_standing_size = (_body_shape.shape as RectangleShape2D).size
	_standing_offset = _body_shape.position
	_apply_body_tuning()
	_sync_body_shape()


## The tuning body size is authoritative; the scene's authored hitboxes are resized to match so
## the physics body never disagrees with `hit_rect()`, which hazards, block kill/stun hitboxes and
## placement clearance all read. JumpHitbox has no `hit_rect()` counterpart (it is physics-only),
## so its authored size is left alone and only its feet are pinned to the standing feet line.
func _apply_body_tuning() -> void:
	if _body_shape == null or tuning == null:
		return
	_standing_size = Vector2(tuning.body_width_wu, tuning.body_height_wu)
	(_body_shape.shape as RectangleShape2D).size = _standing_size
	_body_shape.position = _standing_offset
	var feet := _standing_offset.y + _standing_size.y * 0.5
	if _sneak_shape != null:
		var sneak_size := Vector2(_standing_size.x, _sneak_height())
		(_sneak_shape.shape as RectangleShape2D).size = sneak_size
		_sneak_shape.position = Vector2(_standing_offset.x, feet - sneak_size.y * 0.5)
	if _jump_shape != null:
		var jump_size := (_jump_shape.shape as RectangleShape2D).size
		_jump_shape.position = Vector2(_jump_shape.position.x, feet - jump_size.y * 0.5)


## Every hitbox this chicken owns, standing body first.
func _hitboxes() -> Array[CollisionShape2D]:
	var result: Array[CollisionShape2D] = []
	for collision in [_body_shape, _jump_shape, _sneak_shape]:
		if collision != null:
			result.append(collision)
	return result


## The hitbox the current state calls for. Sneak wins over airborne: a sneaking chicken is on
## the floor by definition, and leaving sneak already needs the `_can_stand()` headroom check.
func _active_shape() -> CollisionShape2D:
	if sneaking and _sneak_shape != null:
		return _sneak_shape
	if _airborne_body and _jump_shape != null:
		return _jump_shape
	return _body_shape


## Enables exactly `_active_shape()` and disables the rest. A chicken authored with only the
## standing body (code-built actors, older scenes) falls back to resizing that one shape.
func _sync_body_shape() -> void:
	if _body_shape == null:
		return
	if _jump_shape == null and _sneak_shape == null:
		var height := _sneak_height() if sneaking else _standing_size.y
		# Keep the feet in place: the origin stays fixed and the shape shifts down.
		(_body_shape.shape as RectangleShape2D).size = Vector2(_standing_size.x, height)
		_body_shape.position = _standing_offset + Vector2(0.0, (_standing_size.y - height) * 0.5)
		return
	var active := _active_shape()
	for collision in _hitboxes():
		collision.disabled = collision != active


## Swaps to the compact airborne body on leaving the floor and back on landing. Growing again
## needs headroom, so a chicken that lands in a one-tile gap keeps the small body until it fits.
func _update_body_shape_for_air() -> void:
	if _jump_shape == null or sneaking:
		return
	var airborne := not is_on_floor()
	if airborne == _airborne_body or (not airborne and not _can_stand()):
		return
	_airborne_body = airborne
	_sync_body_shape()


## World-space hitbox used by hazards, block kill/stun hitboxes and placement clearance. While
## sneaking it is the one-tile sneak body at the feet (2026-10-16); standing, the full body.
func hit_rect() -> Rect2:
	var standing := Vector2(tuning.body_width_wu, tuning.body_height_wu)
	var rect := Rect2(global_position - standing * 0.5, standing)
	if not sneaking:
		return rect
	var height := minf(tuning.sneak_height_wu, standing.y)
	return Rect2(Vector2(rect.position.x, rect.end.y - height), Vector2(standing.x, height))


func _sneak_height() -> float:
	return minf(tuning.sneak_height_wu, _standing_size.y)


func _can_stand() -> bool:
	_capture_body_shape()
	if _body_shape == null or not is_inside_tree():
		return true
	# Sweeping the enabled (compact) body up by the height it is missing covers exactly the space
	# the standing body would need above it.
	var active := _active_shape()
	var rise := _standing_size.y - (active.shape as RectangleShape2D).size.y
	if rise <= 0.0:
		return true
	return not test_move(global_transform, Vector2(0.0, -rise))


func _set_sneak_shape(enabled: bool) -> void:
	_capture_body_shape()
	if _body_shape == null or sneaking == enabled:
		return
	sneaking = enabled
	var height := _sneak_height() if enabled else _standing_size.y
	_sync_body_shape()
	if _contact_sensor != null:
		var full_height := tuning.contact_sensor_height_wu
		var sensor_height := full_height * height / _standing_size.y
		_contact_sensor.set_contact_size(Vector2(tuning.contact_sensor_width_wu, sensor_height))
		_contact_sensor.position = Vector2(0.0, (full_height - sensor_height) * 0.5)
	sneak_changed.emit(sneaking)
	queue_redraw()


## Tells stage blocks about real contact: floor and wall-slide touches (collapsing blocks) and
## grounded side pushes (wood boxes). Blocks opt in by implementing the methods.
func _notify_block_contacts(axis: float) -> void:
	for index in range(get_slide_collision_count()):
		var collision := get_slide_collision(index)
		var collider := collision.get_collider() as Node
		if collider == null or not is_instance_valid(collider):
			continue
		var normal := collision.get_normal()
		if normal.y < -0.7 and collider.has_method("notify_chicken_contact"):
			collider.call("notify_chicken_contact", self)
		elif (
			absf(normal.x) > 0.7
			and is_on_floor()
			and absf(axis) > 0.01
			and signf(axis) == -signf(normal.x)
			and collider.has_method("push_from_chicken")
		):
			collider.call("push_from_chicken", self, int(signf(axis)))
	if wall_side != 0 and WallContactProbe.collider_is_live(_wall_collider_id):
		var wall := instance_from_id(_wall_collider_id) as Node
		if wall.has_method("notify_chicken_contact"):
			wall.call("notify_chicken_contact", self)


func _clear_support() -> void:
	if support_tracker != null and not support_actor_id.is_empty():
		support_tracker.invalidate_actor(support_actor_id)


func _apply_tuning() -> void:
	if tuning == null or tuning.jump_apex_seconds <= 0.0:
		return
	_ascent_gravity = 2.0 * tuning.jump_height_wu / pow(tuning.jump_apex_seconds, 2.0)
	_fall_gravity = _ascent_gravity * tuning.fall_gravity_multiplier
	_jump_impulse = -_ascent_gravity * tuning.jump_apex_seconds
	_apply_body_tuning()


func _update_horizontal(axis: float, delta: float) -> void:
	on_ice = _on_slippery_floor()
	var target := axis * tuning.run_speed_wu_s * (tuning.ice_speed_scale if on_ice else 1.0)
	var grip := tuning.ice_accel_scale if on_ice else 1.0
	if absf(axis) < 0.01:
		if is_on_floor():
			var brake := tuning.brake_wu_s2 * (tuning.ice_brake_scale if on_ice else 1.0)
			locomotion_velocity.x = move_toward(locomotion_velocity.x, 0.0, brake * delta)
		elif tuning.air_neutral_drag_wu_s2 > 0.0:
			locomotion_velocity.x = move_toward(
				locomotion_velocity.x, 0.0, tuning.air_neutral_drag_wu_s2 * delta
			)
		return
	var acceleration := tuning.ground_accel_wu_s2 if is_on_floor() else tuning.air_accel_wu_s2
	if (
		is_on_floor()
		and signf(locomotion_velocity.x) != signf(target)
		and absf(locomotion_velocity.x) > 0.0
	):
		acceleration = tuning.reverse_wu_s2
	if is_on_floor():
		acceleration *= grip
	locomotion_velocity.x = move_toward(locomotion_velocity.x, target, acceleration * delta)


## Whether the floor under the chicken (from the last slide) is a slippery block.
func _on_slippery_floor() -> bool:
	if not is_on_floor():
		return false
	for index in get_slide_collision_count():
		var collision := get_slide_collision(index)
		if collision.get_normal().y > -0.7:
			continue
		var collider := collision.get_collider()
		if collider != null and collider.has_method("is_slippery"):
			if bool(collider.call("is_slippery")):
				return true
	return false


func _update_vertical(delta: float, jump_down: bool) -> void:
	_vertical_half_step = 0.0
	wall_sliding = false
	gliding = false
	if external_velocity.length_squared() > 0.01:
		coyote_remaining = 0.0
		jump_buffer_remaining = 0.0
		jump_was_held = jump_down
		return
	if is_on_floor():
		coyote_remaining = tuning.coyote_seconds
	else:
		coyote_remaining = maxf(0.0, coyote_remaining - delta)
	if jump_buffer_remaining > 0.0 and (is_on_floor() or coyote_remaining > 0.0):
		locomotion_velocity.y = _jump_impulse
		jump_buffer_remaining = 0.0
		coyote_remaining = 0.0
	elif jump_buffer_remaining > 0.0:
		# Ground/coyote jump always wins above; this only runs when neither applies.
		_try_wall_kick()
	if locomotion_velocity.y < 0.0:
		var gravity := _ascent_gravity
		if not jump_down and external_velocity.y >= 0.0:
			gravity *= tuning.jump_release_gravity_multiplier
		_vertical_half_step = gravity * delta * 0.5
		locomotion_velocity.y += gravity * delta
	elif external_velocity.y >= 0.0:
		_vertical_half_step = _fall_gravity * delta * 0.5
		locomotion_velocity.y = minf(
			locomotion_velocity.y + _fall_gravity * delta, tuning.fall_speed_cap_wu_s
		)
		if (
			wall_side != 0
			and tuning.wall_movement_enabled
			and locomotion_velocity.y > tuning.wall_slide_fall_cap_wu_s
		):
			# Cap descent only; ascent and external forced motion are never touched.
			locomotion_velocity.y = tuning.wall_slide_fall_cap_wu_s
			_vertical_half_step = 0.0
			wall_sliding = true
		elif (
			tuning.glide_enabled
			and jump_down
			and not sneaking
			and wall_side == 0
			and not is_on_floor()
			and locomotion_velocity.y > tuning.glide_fall_cap_wu_s
		):
			# Glide caps descent only; wall slide wins on a wall and steering is unchanged.
			locomotion_velocity.y = tuning.glide_fall_cap_wu_s
			_vertical_half_step = 0.0
			gliding = true
	jump_was_held = jump_down


## Water is not solid, so there is no collision to read: a chicken is in water when its centre is
## inside one of the stage's water volumes. Remembers that volume's waterline for _update_float().
func _update_water() -> void:
	if not tuning.water_enabled or water_regions.is_empty():
		in_water = false
		return
	var was_in_water := in_water
	in_water = false
	for region in water_regions:
		if region.has_point(global_position):
			in_water = true
			_water_surface_y = region.position.y
			break
	if in_water and not was_in_water:
		# Entering water kills the fall so a long drop does not punch through the pool.
		locomotion_velocity.y = minf(locomotion_velocity.y, tuning.water_sink_cap_wu_s)
		water_jumping = false
	if not in_water:
		water_jumping = false


## Floating: below the waterline buoyancy lifts the chicken, above it gravity pulls it back, and
## drag bleeds the overshoot so it settles bobbing at the surface instead of being flung out.
## A jump press is an upward stroke. Wall slide, wall kick, coyote time and glide do not apply in
## water; the chicken is swimming, not standing on anything.
func _update_float(delta: float) -> void:
	_vertical_half_step = 0.0
	wall_sliding = false
	gliding = false
	coyote_remaining = 0.0
	if external_velocity.length_squared() > 0.01:
		jump_buffer_remaining = 0.0
		return
	if jump_buffer_remaining > 0.0:
		# Water is jumpable: a press uses the full jump impulse so a chicken can leave the pool.
		# The swim stroke alone never clears the waterline, because the stroke clamp below is a
		# fraction of the jump impulse.
		locomotion_velocity.y = _jump_impulse
		water_jumping = true
		jump_buffer_remaining = 0.0
	elif water_jumping:
		# Carry the jump arc through the water under plain gravity. Buoyancy, drag and the stroke
		# clamp would otherwise cancel the impulse within a frame or two and trap the chicken.
		locomotion_velocity.y += _fall_gravity * delta
		if locomotion_velocity.y >= 0.0:
			water_jumping = false
	else:
		var submerged := global_position.y > _water_surface_y
		if submerged:
			locomotion_velocity.y -= tuning.water_buoyancy_wu_s2 * delta
		else:
			locomotion_velocity.y += _fall_gravity * delta
		locomotion_velocity.y *= WATER_DRAG
		locomotion_velocity.y = clampf(
			locomotion_velocity.y, -tuning.water_stroke_wu_s, tuning.water_sink_cap_wu_s
		)
	locomotion_velocity.x = clampf(
		locomotion_velocity.x, -tuning.water_move_wu_s, tuning.water_move_wu_s
	)


func _update_external_motion(delta: float) -> void:
	if external_velocity.length_squared() <= 0.01:
		external_velocity = Vector2.ZERO
		return
	if is_on_ceiling() and external_velocity.y < 0.0:
		external_velocity.y = 0.0
	elif is_on_floor() and external_velocity.y > 0.0:
		external_velocity.y = 0.0
	elif external_velocity.y < 0.0:
		external_velocity.y += _ascent_gravity * delta
	else:
		external_velocity.y = minf(
			external_velocity.y + _fall_gravity * delta, tuning.fall_speed_cap_wu_s
		)
	external_velocity.x = move_toward(external_velocity.x, 0.0, tuning.ground_accel_wu_s2 * delta)


func _draw() -> void:
	# The DEBUG chicken is authored for the 48 wu body; scale it to the real body and squash it
	# toward the feet while sneaking.
	var draw_scale := (tuning.body_height_wu if tuning != null else 48.0) / 48.0
	var squash := 1.0
	var drop := 0.0
	if sneaking and _standing_size.y > 0.0:
		squash = _sneak_height() / _standing_size.y
		drop = (_standing_size.y - _sneak_height()) * 0.5
	var widen := 1.0 + (1.0 - squash) * 0.3
	draw_set_transform(Vector2(0.0, drop), 0.0, Vector2(draw_scale * widen, draw_scale * squash))
	if draw_debug_body:
		_draw_debug_body()
		if draw_identity_marker:
			_draw_identity_marker(Vector2(0.0, -27.0))
	elif draw_identity_marker:
		# Sprite body: unsquashed marker just above the head, lowered with the sneaking body.
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * draw_scale)
		_draw_identity_marker(Vector2(0.0, -30.0 + drop / draw_scale))
	if show_wall_debug:
		_draw_wall_debug()
	draw_set_transform(Vector2.ZERO)


func _draw_debug_body() -> void:
	var body := Color.WHITE if lifecycle.is_terminal() else marker_color
	draw_colored_polygon(
		PackedVector2Array(
			[
				Vector2(-12.0, 2.0),
				Vector2(-9.0, -9.0),
				Vector2(3.0, -12.0),
				Vector2(12.0, -5.0),
				Vector2(11.0, 7.0),
				Vector2(0.0, 12.0),
				Vector2(-10.0, 8.0),
			]
		),
		body
	)
	draw_circle(Vector2(5.0, -7.0), 2.0, Color("#1d2930"))
	draw_colored_polygon(
		PackedVector2Array(
			[
				Vector2(-5.0, -11.0),
				Vector2(-1.0, -19.0),
				Vector2(2.0, -11.0),
			]
		),
		Color("#e76f51")
	)


func _draw_identity_marker(marker: Vector2) -> void:
	var texture := (
		IDENTITY_MARKER_TEXTURES.get(identity_shape, IDENTITY_MARKER_TEXTURES["CIRCLE"]) as Texture2D
	)
	draw_texture_rect(
		texture, Rect2(marker - Vector2(11.0, 11.0), Vector2(22.0, 22.0)), false, marker_color
	)
	var font := ThemeDB.fallback_font
	if font != null:
		draw_string(
			font,
			marker + Vector2(-11.0, 5.0),
			str(identity_number),
			HORIZONTAL_ALIGNMENT_CENTER,
			22.0,
			14,
			Color("#15242b")
		)


func _draw_wall_debug() -> void:
	# DEBUG cue only (code-drawn, not final art): bar on the touched side, label for state.
	if wall_side == 0 and wall_lock_side == 0:
		return
	var shown := wall_side if wall_side != 0 else wall_lock_side
	var bar_color := Color("#ffb703") if wall_side != 0 else Color("#8d99ae")
	var x := float(shown) * 15.0
	draw_rect(Rect2(Vector2(x - 2.0, -24.0), Vector2(4.0, 48.0)), bar_color)
	var font := ThemeDB.fallback_font
	if font != null:
		var label := "DEBUG WALL SLIDE" if wall_sliding else "DEBUG WALL LOCK"
		draw_string(
			font, Vector2(-40.0, 40.0), label, HORIZONTAL_ALIGNMENT_LEFT, 120.0, 9, bar_color
		)


## The Border marker kills instead of blocking: touching one eliminates the chicken. It replaced
## the containment walls, so this is what stops a chicken running off the stage forever.
func _check_border() -> void:
	if border_regions.is_empty() or lifecycle.is_terminal():
		return
	for region in border_regions:
		if region.has_point(global_position):
			eliminate("border")
			return


func _check_bounds() -> void:
	if bounds.has_point(global_position):
		return
	if containment_outcome_reported:
		return
	containment_outcome_reported = true
	escaped_bounds.emit()


func _on_action_pressed(action_seat: int, action_name: String) -> void:
	if (
		input_router.phase == LocalInputRouter.Phase.PLAY
		and action_seat == seat_index
		and action_name == "jump"
		and not lifecycle.is_terminal()
	):
		jump_buffer_remaining = tuning.jump_buffer_seconds


func _on_phase_changed(
	_previous_phase: LocalInputRouter.Phase, next_phase: LocalInputRouter.Phase
) -> void:
	if next_phase != LocalInputRouter.Phase.PLAY:
		jump_buffer_remaining = 0.0
		jump_was_held = false
		reset_wall_state()
		clear_stun()


func _can_mutate() -> bool:
	return simulation_authority != null and simulation_authority.can_commit()

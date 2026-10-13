class_name ChickenController
extends CharacterBody2D

signal intentional_input_changed(is_intentional: bool)
signal terminal_state_changed(status: PlayerLifecycleState.Status, reason: String)
signal escaped_bounds
signal wall_kicked(side: int)
signal sneak_changed(is_sneaking: bool)

@export var seat_index := 0
@export var tuning: GameplayTuning
@export var input_router: LocalInputRouter
@export var identity_number := 1
@export var identity_shape := "CIRCLE"
@export var marker_color := Color("#f2c14e")
@export var bounds := Rect2(Vector2.ZERO, Vector2(2048.0, 1024.0))

var support_tracker: SupportTracker
var support_actor_id := ""
var lifecycle := PlayerLifecycleState.new()
var locomotion_velocity := Vector2.ZERO
var external_velocity := Vector2.ZERO
var coyote_remaining := 0.0
var jump_buffer_remaining := 0.0
var jump_was_held := false
var intentional_input := false
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
var gliding := false
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
var _standing_size := Vector2.ZERO
var _standing_offset := Vector2.ZERO
var _contact_sensor: ChickenContactSensor


func _ready() -> void:
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
	if input_router == null or get_tree().paused:
		return
	var in_play := input_router.phase == LocalInputRouter.Phase.PLAY
	if not in_play:
		_clear_support()
	var axis := input_router.movement_axis(seat_index) if in_play else 0.0
	var jump_down := in_play and input_router.is_action_held(seat_index, "jump")
	var next_intent := (
		in_play and (input_router.has_direction_intent(seat_index) or absf(axis) > 0.0 or jump_down)
	)
	if intentional_input != next_intent:
		intentional_input = next_intent
		intentional_input_changed.emit(intentional_input)
	if in_play and input_router.consume_pressed(seat_index, "jump"):
		jump_buffer_remaining = tuning.jump_buffer_seconds
	else:
		jump_buffer_remaining = maxf(0.0, jump_buffer_remaining - delta)
	if not in_play:
		jump_buffer_remaining = 0.0
		_vertical_half_step = 0.0
		reset_wall_state()
		reset_sneak()
		return

	if lifecycle.is_terminal():
		_clear_support()
		reset_wall_state()
		locomotion_velocity = Vector2.ZERO
		return
	if lifecycle.status == PlayerLifecycleState.Status.OPENING_FREEZE:
		_clear_support()
		reset_wall_state()
		locomotion_velocity = Vector2.ZERO
		external_velocity = Vector2.ZERO
		jump_buffer_remaining = 0.0
		coyote_remaining = 0.0
		return
	if lifecycle.status == PlayerLifecycleState.Status.CAPTURED:
		_clear_support()
		reset_wall_state()
		locomotion_velocity = Vector2.ZERO
		jump_buffer_remaining = 0.0
		coyote_remaining = 0.0
		return
	_update_sneak(input_router.is_action_held(seat_index, "down"))
	if sneaking:
		# Sneaking chickens hold still: no walking and no jump (buffered presses are dropped).
		axis = 0.0
		locomotion_velocity.x = 0.0
		jump_buffer_remaining = 0.0
	_update_wall_contact(delta)
	_update_horizontal(axis, delta)
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
	_refresh_wall_debug()
	_check_bounds()


func set_snapshot(snapshot: ConfigurationSnapshot) -> void:
	if snapshot == null or snapshot.gameplay == null:
		return
	tuning = snapshot.gameplay
	_apply_tuning()
	reset_wall_state()


## Negative caps use the tuning launch caps.
func launch(force: Vector2, max_horizontal: float = -1.0, max_upward: float = -1.0) -> void:
	if (
		lifecycle.is_terminal()
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
	if lifecycle.is_terminal():
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
	if lifecycle.status != PlayerLifecycleState.Status.CAPTURED:
		return false
	global_position = world_position
	velocity = Vector2.ZERO
	return true


## Clears forced motion and buffered input so a lower-priority state cannot resume after a
## capture or release. Does not alter lifecycle status.
func clear_external_motion() -> void:
	external_velocity = Vector2.ZERO
	locomotion_velocity = Vector2.ZERO
	velocity = Vector2.ZERO
	coyote_remaining = 0.0
	jump_buffer_remaining = 0.0


func set_opening_freeze(frozen: bool) -> void:
	if lifecycle.is_terminal():
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


func secure(reason: String = "secured") -> bool:
	return _set_terminal(PlayerLifecycleState.Status.SECURED, reason)


func eliminate(reason: String = "eliminated") -> bool:
	return _set_terminal(PlayerLifecycleState.Status.ELIMINATED, reason)


## Restores this seat for a new round without recreating its node or identity markers.
func reset_for_round(spawn_position: Vector2) -> void:
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


func _set_terminal(status: PlayerLifecycleState.Status, reason: String) -> bool:
	if not lifecycle.set_status(status, reason):
		return false
	_clear_support()
	reset_wall_state()
	reset_sneak()
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
		if child is CollisionShape2D and (child as CollisionShape2D).shape is RectangleShape2D:
			_body_shape = child
			# Own the shape so resizing never affects another chicken sharing the resource.
			_body_shape.shape = _body_shape.shape.duplicate()
			_standing_size = (_body_shape.shape as RectangleShape2D).size
			_standing_offset = _body_shape.position
			return


func _sneak_height() -> float:
	return minf(tuning.sneak_height_wu, _standing_size.y)


func _can_stand() -> bool:
	_capture_body_shape()
	if _body_shape == null or not is_inside_tree():
		return true
	var rise := _standing_size.y - (_body_shape.shape as RectangleShape2D).size.y
	if rise <= 0.0:
		return true
	return not test_move(global_transform, Vector2(0.0, -rise))


func _set_sneak_shape(enabled: bool) -> void:
	_capture_body_shape()
	if _body_shape == null or sneaking == enabled:
		return
	sneaking = enabled
	var rectangle := _body_shape.shape as RectangleShape2D
	var height := _sneak_height() if enabled else _standing_size.y
	# Keep the feet in place: the origin stays fixed and the shape shifts down.
	rectangle.size = Vector2(_standing_size.x, height)
	_body_shape.position = _standing_offset + Vector2(0.0, (_standing_size.y - height) * 0.5)
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


func _update_horizontal(axis: float, delta: float) -> void:
	var target := axis * tuning.run_speed_wu_s
	if absf(axis) < 0.01:
		if is_on_floor():
			locomotion_velocity.x = move_toward(
				locomotion_velocity.x, 0.0, tuning.brake_wu_s2 * delta
			)
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
	locomotion_velocity.x = move_toward(locomotion_velocity.x, target, acceleration * delta)


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
	var marker := Vector2(0.0, -27.0)
	match identity_shape:
		"TRIANGLE":
			draw_colored_polygon(
				PackedVector2Array(
					[marker + Vector2(0, -7), marker + Vector2(-7, 6), marker + Vector2(7, 6)]
				),
				Color.WHITE
			)
		"SQUARE":
			draw_rect(Rect2(marker - Vector2(5, 5), Vector2(10, 10)), Color.WHITE)
		"DIAMOND":
			draw_colored_polygon(
				PackedVector2Array(
					[
						marker + Vector2(0, -7),
						marker + Vector2(7, 0),
						marker + Vector2(0, 7),
						marker + Vector2(-7, 0)
					]
				),
				Color.WHITE
			)
		_:
			draw_circle(marker, 6.0, Color.WHITE)
	var font := ThemeDB.fallback_font
	if font != null:
		draw_string(
			font,
			marker + Vector2(-4, 4),
			str(identity_number),
			HORIZONTAL_ALIGNMENT_LEFT,
			10.0,
			9,
			Color.BLACK
		)
	if show_wall_debug:
		_draw_wall_debug()
	draw_set_transform(Vector2.ZERO)


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

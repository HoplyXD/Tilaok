class_name ChickenController
extends CharacterBody2D

signal intentional_input_changed(is_intentional: bool)
signal terminal_state_changed(status: PlayerLifecycleState.Status, reason: String)
signal escaped_bounds

@export var seat_index := 0
@export var tuning: GameplayTuning
@export var input_router: LocalInputRouter
@export var identity_number := 1
@export var identity_shape := "CIRCLE"
@export var marker_color := Color("#f2c14e")
@export var bounds := Rect2(Vector2.ZERO, Vector2(1024.0, 512.0))

var lifecycle := PlayerLifecycleState.new()
var locomotion_velocity := Vector2.ZERO
var external_velocity := Vector2.ZERO
var coyote_remaining := 0.0
var jump_buffer_remaining := 0.0
var jump_was_held := false
var intentional_input := false
var containment_outcome_reported := false
var _ascent_gravity := 1875.0
var _fall_gravity := 2531.25
var _jump_impulse := -600.0
var _vertical_half_step := 0.0


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


func _exit_tree() -> void:
	if input_router != null and input_router.action_pressed.is_connected(_on_action_pressed):
		input_router.action_pressed.disconnect(_on_action_pressed)
	if input_router != null and input_router.phase_changed.is_connected(_on_phase_changed):
		input_router.phase_changed.disconnect(_on_phase_changed)


func _physics_process(delta: float) -> void:
	if input_router == null or get_tree().paused:
		return
	var in_play := input_router.phase == LocalInputRouter.Phase.PLAY
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
		return

	if lifecycle.is_terminal():
		locomotion_velocity = Vector2.ZERO
		return
	if lifecycle.status == PlayerLifecycleState.Status.OPENING_FREEZE:
		locomotion_velocity = Vector2.ZERO
		external_velocity = Vector2.ZERO
		jump_buffer_remaining = 0.0
		coyote_remaining = 0.0
		return
	if lifecycle.status == PlayerLifecycleState.Status.CAPTURED:
		locomotion_velocity = Vector2.ZERO
		jump_buffer_remaining = 0.0
		coyote_remaining = 0.0
		return
	_update_horizontal(axis, delta)
	_update_vertical(delta, jump_down)
	var combined := locomotion_velocity + external_velocity
	combined.y -= _vertical_half_step
	velocity = combined
	move_and_slide()
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
	_check_bounds()


func set_snapshot(snapshot: ConfigurationSnapshot) -> void:
	if snapshot == null or snapshot.gameplay == null:
		return
	tuning = snapshot.gameplay
	_apply_tuning()


func launch(force: Vector2, max_horizontal: float = 480.0, max_upward: float = 900.0) -> void:
	if (
		lifecycle.is_terminal()
		or (
			lifecycle.status
			in [PlayerLifecycleState.Status.CAPTURED, PlayerLifecycleState.Status.OPENING_FREEZE]
		)
	):
		return
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
		lifecycle.capture_source_id = source_id
		locomotion_velocity = Vector2.ZERO
		coyote_remaining = 0.0
		jump_buffer_remaining = 0.0
	else:
		if lifecycle.status != PlayerLifecycleState.Status.CAPTURED:
			return
		lifecycle.status = PlayerLifecycleState.Status.ACTIVE
		lifecycle.capture_source_id = ""


func set_opening_freeze(frozen: bool) -> void:
	if lifecycle.is_terminal():
		return
	if frozen:
		lifecycle.status = PlayerLifecycleState.Status.OPENING_FREEZE
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


func _set_terminal(status: PlayerLifecycleState.Status, reason: String) -> bool:
	if not lifecycle.set_status(status, reason):
		return false
	locomotion_velocity = Vector2.ZERO
	external_velocity = Vector2.ZERO
	jump_buffer_remaining = 0.0
	coyote_remaining = 0.0
	terminal_state_changed.emit(status, reason)
	return true


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

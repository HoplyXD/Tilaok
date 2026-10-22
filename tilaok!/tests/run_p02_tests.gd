extends SceneTree

const ROOM := preload("res://scenes/fixtures/p02_movement_room.tscn")

var failures := 0
var checks := 0
var navigation_event_count := 0
var room: P02MovementRoom


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_seat_identity_and_reclaim()
	_test_gamepad_edges_and_axes()
	_test_recovery_contract()
	room = ROOM.instantiate() as P02MovementRoom
	root.add_child(room)
	room.input_router.navigation_step.connect(_record_navigation_step)
	for _frame in range(4):
		await physics_frame
	_test_keyboard_join_edges()
	_test_keyboard_routing()
	_test_navigation_repeat()
	await _test_pause_freeze_and_cancel()
	await _test_physics_and_contact()
	await _test_coyote_and_jump_buffer()
	await _test_no_held_jump_repeat()
	await _test_launch_and_containment()
	await _test_terminal_precedence()
	_test_water_float()
	await _test_cleanup_cycles()
	print("P02_TESTS checks=%d failures=%d" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _check(condition: bool, label: String) -> void:
	checks += 1
	if condition:
		print("PASS ", label)
	else:
		failures += 1
		push_error("FAIL " + label)


func _record_navigation_step(_seat_index: int, _direction: String) -> void:
	navigation_event_count += 1


## A chicken in a Water-terrain volume floats: entering caps the fall, buoyancy carries it up to
## the waterline and it settles there instead of being thrown out, and jump is an upward stroke.
## Stepped directly rather than through the room, because no shipped map has water painted yet.
func _test_water_float() -> void:
	var actor: ChickenController = room.actors[0]
	var tuning := actor.tuning
	var restore_position := actor.global_position
	var restore_regions := actor.water_regions
	var waterline := 640.0
	actor.water_regions = [Rect2(0.0, waterline, 256.0, 256.0)]

	actor.global_position = Vector2(128.0, waterline - 200.0)
	actor._update_water()
	_check(not actor.in_water, "a chicken above the pool is not in water")

	# Falling in fast is capped at the sink cap instead of punching through the pool.
	actor.global_position = Vector2(128.0, waterline + 220.0)
	actor.locomotion_velocity = Vector2(0.0, 600.0)
	actor._update_water()
	_check(
		actor.in_water and is_equal_approx(actor.locomotion_velocity.y, tuning.water_sink_cap_wu_s),
		"entering water caps the fall at the sink cap"
	)

	# Run until it stops moving rather than for a fixed time: the room's tuning may be distance
	# scaled, which changes how long the rise from the pool floor takes.
	var delta := 1.0 / 60.0
	var settled_steps := 0
	for _step in 1800:
		actor._update_water()
		if actor.in_water:
			actor._update_float(delta)
		else:
			actor.locomotion_velocity.y += actor._fall_gravity * delta
		actor.global_position.y += actor.locomotion_velocity.y * delta
		if absf(actor.locomotion_velocity.y) <= tuning.water_sink_cap_wu_s * 0.25:
			settled_steps += 1
			if settled_steps >= 30:
				break
		else:
			settled_steps = 0
	_check(
		absf(actor.global_position.y - waterline) <= tuning.grid_cell_wu * 0.25,
		"a floating chicken rises and settles at the waterline (%.1f wu off)" % absf(
			actor.global_position.y - waterline
		)
	)

	actor.global_position = Vector2(128.0, waterline + 160.0)
	actor.locomotion_velocity = Vector2(0.0, 5000.0)
	actor._update_water()
	actor._update_float(delta)
	_check(
		is_equal_approx(actor.locomotion_velocity.y, tuning.water_sink_cap_wu_s),
		"descent in water never exceeds the sink cap"
	)

	actor.locomotion_velocity = Vector2.ZERO
	actor.jump_buffer_remaining = tuning.jump_buffer_seconds
	actor._update_water()
	actor._update_float(delta)
	_check(
		is_equal_approx(actor.locomotion_velocity.y, -tuning.water_stroke_wu_s),
		"a jump press in water is an upward stroke"
	)

	actor.water_regions = restore_regions
	actor.global_position = restore_position
	actor.locomotion_velocity = Vector2.ZERO
	actor.jump_buffer_remaining = 0.0
	actor.in_water = false


func _test_seat_identity_and_reclaim() -> void:
	var registry := PlayerSeatRegistry.new()
	var first := registry.join_gamepad(3)
	var second := registry.join_gamepad(4)
	_check(first == 0 and second == 1, "two gamepads receive isolated first seats")
	_check(registry.join_gamepad(3) == -1, "assigned device cannot join twice")
	_check(
		registry.get_seat(0).shape == "CIRCLE" and registry.get_seat(1).shape == "TRIANGLE",
		"number and shape identity order is permanent"
	)
	registry.set_ready(0, true)
	registry.disconnect_gamepad(3)
	_check(registry.reclaim_gamepad(0, 9), "unassigned changed device reclaims missing seat")
	_check(
		registry.get_seat(0).identity == 1 and not registry.get_seat(0).ready,
		"reclaim keeps identity and clears ready state"
	)
	_check(not registry.reclaim_gamepad(1, 9), "one device cannot steal another assigned seat")


func _test_recovery_contract() -> void:
	var contract := ContainmentRecoveryContract.new()
	contract.begin_round([4, 7, 0, 0], 12, ContainmentRecoveryContract.Mode.LAGSANAY)
	_check(
		contract.report_escape() == ContainmentRecoveryContract.Outcome.PROTOTYPE_DEFECT,
		"Lagsanay breach is a prototype defect"
	)
	contract.report_escape()
	var recovery := contract.recover()
	_check(
		contract.outcome_count == 1 and recovery.award_count == 0,
		"breach is idempotent and grants no awards"
	)
	_check(
		recovery.scores == [4, 7, 0, 0] and recovery.construction_revision == 12,
		"recovery preserves pre-round score and construction snapshot"
	)
	contract.begin_round([1, 0, 0, 0], 2, ContainmentRecoveryContract.Mode.RACE)
	_check(
		contract.report_escape() == ContainmentRecoveryContract.Outcome.FAILED_RACE,
		"race escape produces one failed outcome"
	)
	_check(contract.recover().is_empty(), "race failure has no automatic recovery/respawn")


func _test_gamepad_edges_and_axes() -> void:
	var router := LocalInputRouter.new()
	router.tuning = GameplayTuning.new()
	router.phase = LocalInputRouter.Phase.LOBBY
	var join := _joy_button(10, JOY_BUTTON_A, true)
	router._handle_joy_button(join)
	router._handle_joy_button(join)
	_check(
		router.registry.joined_seats().size() == 1 and not router.registry.get_seat(0).ready,
		"South join press cannot ready the same gamepad seat"
	)
	router._handle_joy_button(_joy_button(10, JOY_BUTTON_A, false))
	router._handle_joy_button(_joy_button(10, JOY_BUTTON_A, true))
	_check(router.registry.get_seat(0).ready, "gamepad ready needs a separate fresh South press")
	router._handle_joy_button(_joy_button(10, JOY_BUTTON_A, false))
	router.registry.join_gamepad(11)
	router.set_phase(LocalInputRouter.Phase.PLAY)
	router._handle_joy_button(_joy_button(10, JOY_BUTTON_A, true))
	_check(
		router.consume_pressed(0, "jump") and not router.consume_pressed(1, "jump"),
		"gamepad jump edge stays in the assigned seat"
	)
	router._handle_joy_button(_joy_button(10, JOY_BUTTON_A, false))
	router._handle_joy_button(_joy_button(11, JOY_BUTTON_A, true))
	_check(
		router.consume_pressed(1, "jump") and not router.consume_pressed(0, "jump"),
		"second gamepad controls only its own seat"
	)
	router._handle_joy_button(_joy_button(11, JOY_BUTTON_A, false))
	for phase_case in [
		[LocalInputRouter.Phase.PUGAD, "claim"],
		[LocalInputRouter.Phase.PLACE, "confirm"],
		[LocalInputRouter.Phase.MENU, "confirm"],
		[LocalInputRouter.Phase.PAUSE, "confirm"],
		[LocalInputRouter.Phase.RESULTS, "confirm"],
	]:
		router.set_phase(phase_case[0])
		router._handle_joy_button(_joy_button(10, JOY_BUTTON_A, true))
		_check(
			router.consume_pressed(0, phase_case[1]),
			"gamepad South maps to %s in diagnostic phase %d" % [phase_case[1], phase_case[0]]
		)
		router._handle_joy_button(_joy_button(10, JOY_BUTTON_A, false))
		if phase_case[0] == LocalInputRouter.Phase.PAUSE:
			router.set_phase(LocalInputRouter.Phase.PLAY)
	router._handle_joy_axis(_joy_axis(10, JOY_AXIS_LEFT_X, 0.24))
	_check(router.movement_axis(0) == 0.0, "left stick remains neutral below 0.25 activation")
	router._handle_joy_axis(_joy_axis(10, JOY_AXIS_LEFT_X, 0.25))
	router._handle_joy_axis(_joy_axis(10, JOY_AXIS_LEFT_X, 0.21))
	_check(router.movement_axis(0) >= 0.25, "stick remains active until below 0.20 neutral")
	router._handle_joy_button(_joy_button(10, JOY_BUTTON_DPAD_LEFT, true))
	_check(router.movement_axis(0) == -1.0, "active D-pad direction takes precedence over stick")
	router._handle_joy_button(_joy_button(10, JOY_BUTTON_DPAD_RIGHT, true))
	_check(
		router.movement_axis(0) == 0.0 and router.has_direction_intent(0),
		"opposing D-pad directions cancel while remaining observable"
	)
	router._handle_joy_button(_joy_button(10, JOY_BUTTON_DPAD_LEFT, false))
	router._handle_joy_button(_joy_button(10, JOY_BUTTON_DPAD_RIGHT, false))
	router.free()


func _event(key: Key, pressed: bool, echo: bool = false, location: int = 0) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.keycode = key
	event.pressed = pressed
	event.echo = echo
	event.location = location
	return event


func _joy_button(device: int, button: int, pressed: bool) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.device = device
	event.button_index = button
	event.pressed = pressed
	return event


func _joy_axis(device: int, axis: int, value: float) -> InputEventJoypadMotion:
	var event := InputEventJoypadMotion.new()
	event.device = device
	event.axis = axis
	event.axis_value = value
	return event


func _test_keyboard_join_edges() -> void:
	var router := room.input_router
	router.set_shared_keyboard_enabled(true)
	router.set_phase(LocalInputRouter.Phase.LOBBY)
	router._handle_key(_event(KEY_D, true))
	_check(
		router.registry.joined_seats().is_empty(), "shared keyboard movement key cannot join a seat"
	)
	router._handle_key(_event(KEY_D, false))
	router._handle_key(_event(KEY_E, true))
	_check(
		router.registry.joined_seats().size() == 1 and not router.registry.get_seat(0).ready,
		"fresh K1 join press does not also ready the seat"
	)
	router._handle_key(_event(KEY_E, false))
	router._handle_key(_event(KEY_E, true))
	_check(router.registry.get_seat(0).ready, "ready requires a separate fresh press after joining")
	router._handle_key(_event(KEY_E, false))
	router.registry.set_ready(0, false)
	router._handle_key(_event(KEY_ENTER, true))
	_check(
		router.registry.joined_seats().size() == 2 and not router.registry.get_seat(1).ready,
		"fresh K2 Enter joins the second keyboard seat without readying it"
	)
	router._handle_key(_event(KEY_ENTER, false))
	router.set_phase(LocalInputRouter.Phase.PLAY)


func _test_keyboard_routing() -> void:
	var router := room.input_router
	router.set_phase(LocalInputRouter.Phase.PLAY)
	router._handle_key(_event(KEY_E, true))
	_check(not router.consume_pressed(0, "ready"), "K1 lobby-ready binding is ignored in Play")
	router._handle_key(_event(KEY_E, false))
	router._handle_key(_event(KEY_R, true))
	_check(
		room._pause_label.text.contains("rotate unavailable"),
		"unsupported rotation produces a disabled cue"
	)
	router._handle_key(_event(KEY_R, false))
	router._handle_key(_event(KEY_CTRL, true, false, KEY_LOCATION_LEFT))
	_check(not router.consume_pressed(1, "jump"), "left Control does not alias the K2 jump key")
	router._handle_key(_event(KEY_CTRL, false, false, KEY_LOCATION_LEFT))
	router._handle_key(_event(KEY_CTRL, true, false, KEY_LOCATION_RIGHT))
	_check(router.consume_pressed(1, "jump"), "right Control maps to K2 jump")
	router._handle_key(_event(KEY_CTRL, false, false, KEY_LOCATION_RIGHT))
	router._handle_key(_event(KEY_D, true))
	_check(
		router.movement_axis(0) == 1.0 and router.movement_axis(1) == 0.0,
		"K1 movement is isolated from K2"
	)
	router._handle_key(_event(KEY_RIGHT, true))
	_check(router.movement_axis(1) == 1.0, "K2 movement is routed to its own seat")
	router._handle_key(_event(KEY_A, true))
	_check(
		router.movement_axis(0) == 0.0 and router.has_direction_intent(0),
		"opposing keys cancel movement but preserve intent"
	)
	router._handle_key(_event(KEY_E, true, true))
	_check(not router.consume_pressed(0, "ready"), "OS key echo cannot create a ready edge")
	router._handle_key(_event(KEY_A, false))
	router._handle_key(_event(KEY_D, false))
	router._handle_key(_event(KEY_RIGHT, false))
	router._handle_key(_event(KEY_SPACE, true))
	_check(router.consume_pressed(0, "jump"), "K1 jump maps in Play")
	router.set_phase(LocalInputRouter.Phase.PUGAD)
	_check(not router.consume_pressed(0, "claim"), "transition consumes existing one-shot edge")
	router._handle_key(_event(KEY_SPACE, false))
	_check(
		not router._held.has("kbd:K1:%d" % KEY_SPACE),
		"release of a held key clears it after that key becomes unbound"
	)
	router._handle_key(_event(KEY_E, true))
	_check(router.consume_pressed(0, "claim"), "K1 confirm maps to claim in Pugad")
	router.set_phase(LocalInputRouter.Phase.PLACE)
	_check(
		not router.consume_pressed(0, "confirm"),
		"held claim cannot confirm after transition into Place"
	)
	router._handle_key(_event(KEY_E, false))
	router._handle_key(_event(KEY_E, true))
	_check(router.consume_pressed(0, "confirm"), "fresh K1 press confirms in Place")
	router._handle_key(_event(KEY_E, false))
	router.set_phase(LocalInputRouter.Phase.PLAY)
	_check(
		room.pause_coordinator.menu_owner == -1,
		"K1 layout does not acquire pause ownership outside pause"
	)


func _test_navigation_repeat() -> void:
	var router := room.input_router
	router.set_phase(LocalInputRouter.Phase.PLACE)
	var diagonal_start := navigation_event_count
	router._handle_key(_event(KEY_D, true))
	router._handle_key(_event(KEY_W, true))
	_check(
		navigation_event_count == diagonal_start + 1,
		"diagonal navigation does not emit two immediate moves"
	)
	router._handle_key(_event(KEY_D, false))
	router._handle_key(_event(KEY_W, false))
	router._handle_key(_event(KEY_D, true))
	var first_repeat := router.repeat_navigation(0, "right", 0.10)
	var second_repeat := router.repeat_navigation(0, "right", 0.15)
	var fast_repeat := router.repeat_navigation(0, "right", 0.125)
	_check(
		not first_repeat and second_repeat and fast_repeat,
		"placement repeat uses 0.25s delay then 8 moves/s"
	)
	router._handle_key(_event(KEY_D, false))
	router.set_phase(LocalInputRouter.Phase.MENU)
	router._handle_key(_event(KEY_D, true))
	router._handle_key(_event(KEY_E, true))
	_check(router.consume_pressed(0, "confirm"), "K1 South/confirm maps in Menu")
	router._handle_key(_event(KEY_E, false))
	var menu_early := router.repeat_navigation(0, "right", 0.249)
	var menu_repeat := router.repeat_navigation(0, "right", 0.002)
	_check(not menu_early and menu_repeat, "menu repeat uses 0.25s delay")
	router._handle_key(_event(KEY_D, false))


func _test_pause_freeze_and_cancel() -> void:
	var coordinator := room.pause_coordinator
	var router := room.input_router
	coordinator.set_paused("automated probe", -1)
	_check(
		paused and coordinator.state == PauseRecoveryCoordinator.State.PAUSED,
		"pause freezes SceneTree simulation"
	)
	var before_callbacks := room._probe_callbacks
	var before_ticks := room._simulation_ticks
	coordinator._on_action_pressed(0, "confirm")
	coordinator._on_action_pressed(1, "confirm")
	coordinator._on_action_pressed(0, "confirm")
	_check(
		(
			coordinator.menu_owner == 0
			and coordinator.state == PauseRecoveryCoordinator.State.COUNTDOWN
		),
		"first fresh confirm acquires menu ownership; all seats ready starts countdown"
	)
	for _frame in range(20):
		await physics_frame
	_check(
		room._probe_callbacks == before_callbacks and room._simulation_ticks == before_ticks,
		"Timer callback and physics probe do not advance during resume countdown"
	)
	router.device_status_changed.emit(99, true)
	_check(
		(
			coordinator.state == PauseRecoveryCoordinator.State.PAUSED
			and coordinator.countdown_remaining == 0.0
		),
		"device status change cancels resume countdown"
	)
	coordinator._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	_check(
		not router.registry.get_seat(0).ready and not router.registry.get_seat(1).ready,
		"focus changes clear pause readiness"
	)
	for seat in router.registry.joined_seats():
		router.registry.set_ready(int(seat.seat), true)
	_check(coordinator.request_resume(), "all connected seats can begin the resume countdown")
	for _frame in range(185):
		await physics_frame
	_check(
		coordinator.state == PauseRecoveryCoordinator.State.RUNNING and not paused,
		"three-second countdown resumes the saved phase"
	)
	var missing_seat := router.registry.join_gamepad(99)
	_check(missing_seat == 2, "synthetic gamepad can occupy a remaining local seat")
	router._on_joy_connection_changed(99, false)
	_check(
		(
			coordinator.state == PauseRecoveryCoordinator.State.PAUSED
			and not router.registry.get_seat(missing_seat).connected
		),
		"bound gamepad disconnect pauses the whole simulation and retains its seat"
	)
	paused = false
	router.resume_system()
	coordinator.state = PauseRecoveryCoordinator.State.RUNNING
	coordinator.pause_reason = ""
	router.set_phase(LocalInputRouter.Phase.PLAY)


func _test_physics_and_contact() -> void:
	var router := room.input_router
	var actor: ChickenController = room.actors[0]
	var other: ChickenController = room.actors[1]
	room._reset_trial()
	room.set_diagnostic_phase(LocalInputRouter.Phase.PUGAD)
	var phase_gate_x := actor.global_position.x
	router._handle_key(_event(KEY_D, true))
	for _frame in range(12):
		await physics_frame
	router._handle_key(_event(KEY_D, false))
	_check(actor.global_position.x == phase_gate_x, "controller cannot move during the Pugad phase")
	room.set_diagnostic_phase(LocalInputRouter.Phase.PLAY)
	var start_x := actor.global_position.x
	router.set_phase(LocalInputRouter.Phase.PLAY)
	router._handle_key(_event(KEY_D, true))
	for _frame in range(30):
		await physics_frame
	var running_speed := absf(actor.velocity.x)
	var release_x := actor.global_position.x
	router._handle_key(_event(KEY_D, false))
	var displacement := actor.global_position.x - start_x
	for _frame in range(30):
		await physics_frame
	var stopped_speed := absf(actor.velocity.x)
	var braking_distance := actor.global_position.x - release_x
	_check(
		displacement > 40.0 and running_speed > 0.0,
		"runtime run controller moves in intended direction"
	)
	_check(
		stopped_speed < running_speed and braking_distance <= 14.5,
		"runtime ground braking reduces speed within the measured stopping distance"
	)
	router._handle_key(_event(KEY_D, true))
	for _frame in range(12):
		await physics_frame
	var reversal_start_speed := actor.velocity.x
	router._handle_key(_event(KEY_D, false))
	router._handle_key(_event(KEY_A, true))
	var reversal_frames := 0
	for frame in range(12):
		await physics_frame
		reversal_frames = frame + 1
		if actor.velocity.x < 0.0:
			break
	var reversal_speed := actor.velocity.x
	router._handle_key(_event(KEY_A, false))
	_check(
		reversal_start_speed >= 270.0 and reversal_speed < 0.0 and reversal_frames <= 7,
		"runtime ground reversal crosses zero within seven physics steps"
	)
	room._reset_trial()
	actor.global_position = Vector2(500, 548)
	other.global_position = Vector2(500, 548)
	for _frame in range(4):
		await physics_frame
	var sensor := actor.get_node("ContactSensor") as ChickenContactSensor
	_check(sensor.overlaps().has(other), "independent contact sensor detects overlapping chickens")
	_check(
		actor.global_position.distance_to(other.global_position) < 1.0,
		"chicken bodies overlap without pushing"
	)
	room._reset_trial()
	actor.global_position = Vector2(756, 338)
	for _frame in range(10):
		await physics_frame
	router._handle_key(_event(KEY_D, true))
	router._handle_key(_event(KEY_SPACE, true))
	for _frame in range(24):
		await physics_frame
	router._handle_key(_event(KEY_SPACE, false))
	var gap_landing := false
	for _frame in range(24):
		await physics_frame
		if actor.is_on_floor() and actor.global_position.y < 320.0:
			gap_landing = actor.global_position.x >= 820.0 and actor.global_position.x <= 940.0
			if gap_landing:
				break
	router._handle_key(_event(KEY_D, false))
	var gap_x := actor.global_position.x
	var gap_y := actor.global_position.y
	print("P02_METRIC gap64_rise64 landed=%s x=%.2f y=%.2f" % [gap_landing, gap_x, gap_y])
	_check(
		gap_landing and gap_y < 320.0,
		"full jump traverses the dedicated 64 gap and 64 rise fixture"
	)
	room._reset_trial()
	actor.global_position = Vector2(568, 376)
	for _frame in range(5):
		await physics_frame
	router._handle_key(_event(KEY_SPACE, true))
	var hit_ceiling := false
	for _frame in range(10):
		await physics_frame
		hit_ceiling = hit_ceiling or actor.is_on_ceiling()
	router._handle_key(_event(KEY_SPACE, false))
	_check(hit_ceiling, "collision stops a normal jump against the ceiling fixture")
	room._reset_trial()
	actor.global_position = Vector2(220, 548)
	for _frame in range(20):
		await physics_frame
	var short_start_y := actor.global_position.y
	router._handle_key(_event(KEY_SPACE, true))
	await physics_frame
	router._handle_key(_event(KEY_SPACE, false))
	var short_peak := actor.global_position.y
	for _frame in range(90):
		await physics_frame
		short_peak = minf(short_peak, actor.global_position.y)
	var short_height := short_start_y - short_peak
	room._reset_trial()
	actor.global_position = Vector2(220, 548)
	for _frame in range(20):
		await physics_frame
	router._handle_key(_event(KEY_SPACE, true))
	var full_start_y := actor.global_position.y
	var full_peak := full_start_y
	var full_peak_frame := 0
	for _frame in range(24):
		await physics_frame
		if actor.global_position.y < full_peak:
			full_peak = actor.global_position.y
			full_peak_frame = _frame + 1
	router._handle_key(_event(KEY_SPACE, false))
	for _frame in range(60):
		await physics_frame
	var metric_template := (
		"jump_short_wu=%.2f jump_full_wu=%.2f apex_frames=%d displacement_30ticks=%.2f "
		+ "run_speed=%.2f stopped_speed=%.2f braking_distance=%.2f reversal_frames=%d"
	)
	var metric_text := (
		metric_template
		% [
			short_height,
			full_start_y - full_peak,
			full_peak_frame,
			displacement,
			running_speed,
			stopped_speed,
			braking_distance,
			reversal_frames
		]
	)
	print("P02_METRIC " + metric_text)
	_check(
		short_height > 0.0 and (full_start_y - full_peak) > short_height,
		"short and full jump trajectories differ"
	)


func _test_terminal_precedence() -> void:
	var actor: ChickenController = room.actors[1]
	var router := room.input_router
	actor.set_opening_freeze(true)
	actor.set_captured(true, "lower-priority capture")
	actor.launch(Vector2(200, -300))
	_check(
		(
			actor.lifecycle.status == PlayerLifecycleState.Status.OPENING_FREEZE
			and actor.external_velocity == Vector2.ZERO
		),
		"opening freeze outranks capture and launch"
	)
	actor.set_opening_freeze(false)
	actor.set_captured(true, "fixture capture")
	router._handle_key(_event(KEY_LEFT, true))
	await physics_frame
	_check(actor.intentional_input, "intent remains observable while captured")
	actor.launch(Vector2(200, -300))
	_check(actor.external_velocity == Vector2.ZERO, "capture blocks forced movement")
	router._handle_key(_event(KEY_LEFT, false))
	actor.set_captured(false)
	_check(
		actor.eliminate("fixture") and not actor.secure("late capture"),
		"terminal outcome is idempotent"
	)
	actor.launch(Vector2(200, -300))
	_check(
		actor.lifecycle.is_terminal() and actor.external_velocity == Vector2.ZERO,
		"terminal player ignores forced movement"
	)


func _test_no_held_jump_repeat() -> void:
	var actor: ChickenController = room.actors[0]
	var router := room.input_router
	room._reset_trial()
	actor.global_position = Vector2(220, 548)
	for _frame in range(20):
		await physics_frame
	router._handle_key(_event(KEY_SPACE, true))
	for _frame in range(110):
		await physics_frame
	var landed_once := actor.is_on_floor() and absf(actor.global_position.y - 556.0) <= 1.0
	_check(landed_once, "held jump does not auto-repeat after landing")
	router._handle_key(_event(KEY_SPACE, false))


func _test_coyote_and_jump_buffer() -> void:
	var actor: ChickenController = room.actors[0]
	var router := room.input_router
	router.set_phase(LocalInputRouter.Phase.PLAY)
	room._reset_trial()
	actor.global_position = Vector2(350, 440)
	for _frame in range(4):
		await physics_frame
	var landed_on_test_ledge := actor.is_on_floor()
	router._handle_key(_event(KEY_D, true))
	for _frame in range(24):
		await physics_frame
		if not actor.is_on_floor():
			break
	router._handle_key(_event(KEY_D, false))
	var within_coyote_window := not actor.is_on_floor() and actor.coyote_remaining > 0.0
	router._handle_key(_event(KEY_SPACE, true))
	await physics_frame
	var coyote_jump := actor.locomotion_velocity.y < 0.0
	router._handle_key(_event(KEY_SPACE, false))
	_check(
		landed_on_test_ledge and within_coyote_window and coyote_jump,
		"fresh jump within the 0.10s ledge coyote window launches"
	)

	room._reset_trial()
	actor.global_position = Vector2(220, 547)
	actor.locomotion_velocity.y = 200.0
	router._handle_key(_event(KEY_SPACE, true))
	await physics_frame
	router._handle_key(_event(KEY_SPACE, false))
	for _frame in range(4):
		await physics_frame
	_check(
		actor.locomotion_velocity.y < 0.0,
		"one fresh jump press buffered just before landing is consumed once"
	)


func _test_cleanup_cycles() -> void:
	var root_nodes_before := root.get_child_count()
	room.queue_free()
	await process_frame
	for _cycle in range(5):
		var transient := ROOM.instantiate() as P02MovementRoom
		root.add_child(transient)
		await process_frame
		transient.queue_free()
		await process_frame
	_check(
		root.get_child_count() == root_nodes_before - 1,
		"five fixture reload cycles release their scene nodes and signal owners"
	)


func _test_launch_and_containment() -> void:
	var actor: ChickenController = room.actors[0]
	room._reset_trial()
	actor.global_position = Vector2(220, 556)
	for _frame in range(20):
		await physics_frame
	actor.coyote_remaining = 0.1
	actor.launch(Vector2(480, -900))
	_check(actor.coyote_remaining == 0.0, "launch clears coyote permission")
	var contained := true
	for _frame in range(60):
		await physics_frame
		contained = contained and room.actors[0].bounds.has_point(actor.global_position)
	_check(contained, "maximum configured diagonal launch stays inside visible containment")
	var released_height := await _measure_launch_height(true)
	var held_height := await _measure_launch_height(false)
	print(
		(
			"P02_METRIC forced_launch_released_wu=%.2f forced_launch_held_wu=%.2f"
			% [released_height, held_height]
		)
	)
	_check(
		absf(released_height - held_height) <= 1.0,
		"ordinary jump release does not shorten an external launch"
	)
	room._on_diagnostic_mode_selected(1)
	room.recovery_contract.begin_round([4, 7, 0, 0], 12, ContainmentRecoveryContract.Mode.LAGSANAY)
	room._reset_trial()
	room.inject_containment_breach(0)
	await physics_frame
	_check(
		(
			room.pause_coordinator.state == PauseRecoveryCoordinator.State.PAUSED
			and not actor.lifecycle.is_terminal()
		),
		"Lagsanay containment breach pauses as a defect without eliminating the taya"
	)
	room._recover_from_defect()
	_check(
		(
			room.pause_coordinator.state == PauseRecoveryCoordinator.State.RUNNING
			and actor.global_position == P02MovementRoom.SEAT_POSITIONS[0]
			and room.recovery_contract.pre_round_scores == [4, 7, 0, 0]
			and room.recovery_contract.construction_revision == 12
		),
		"prototype recovery restores fixture position without changing score/construction snapshot"
	)
	room._on_diagnostic_mode_selected(2)
	room.recovery_contract.begin_round([2, 3, 0, 0], 18, ContainmentRecoveryContract.Mode.KANGAROO)
	room._reset_trial()
	room.inject_containment_breach(0)
	await physics_frame
	_check(
		(
			room.pause_coordinator.state == PauseRecoveryCoordinator.State.PAUSED
			and not actor.lifecycle.is_terminal()
		),
		"Kangaroo-only containment breach also pauses as a prototype defect"
	)
	room._recover_from_defect()
	room._on_diagnostic_mode_selected(0)
	room.inject_containment_breach(0)
	await physics_frame
	_check(
		(
			actor.lifecycle.status == PlayerLifecycleState.Status.ELIMINATED
			and room.recovery_contract.outcome_count == 1
		),
		"race-only containment escape produces one failed terminal outcome"
	)
	room.recovery_contract.report_escape()
	room._recover_from_defect()
	_check(
		room.recovery_contract.outcome_count == 1 and actor.global_position.x > 1152.0,
		"race failure neither repeats its outcome nor automatically respawns"
	)
	room._reset_trial()
	_check(
		(
			actor.lifecycle.status == PlayerLifecycleState.Status.ACTIVE
			and actor.global_position == room.SEAT_POSITIONS[0]
		),
		"explicit diagnostic trial reset restores terminal actor at its seat"
	)


func _measure_launch_height(release_early: bool) -> float:
	var actor: ChickenController = room.actors[0]
	var router := room.input_router
	room._reset_trial()
	actor.global_position = Vector2(220, 556)
	for _frame in range(20):
		await physics_frame
	var start_y := actor.global_position.y
	actor.launch(Vector2(0, -600))
	if not release_early:
		router._handle_key(_event(KEY_SPACE, true))
	var peak_y := start_y
	for index in range(24):
		await physics_frame
		peak_y = minf(peak_y, actor.global_position.y)
		if release_early and index == 0:
			router._handle_key(_event(KEY_SPACE, true))
			router._handle_key(_event(KEY_SPACE, false))
	if not release_early:
		router._handle_key(_event(KEY_SPACE, false))
	return start_y - peak_y

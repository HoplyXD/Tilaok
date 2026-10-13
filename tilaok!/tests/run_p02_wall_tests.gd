extends SceneTree
## REQ-MOVE-004 wall slide / wall jump checks (P02-T15–T21). Real Godot physics; K1, K2 and
## gamepad input are SYNTHETIC events, never physical-device evidence.
## Run: godot --headless --path "tilaok!" --script res://tests/run_p02_wall_tests.gd

const P02_ROOM := preload("res://scenes/fixtures/p02_movement_room.tscn")
const P03_ROOM := preload("res://scenes/fixtures/p03_stage_room.tscn")
const BODY_WIDTH := 24.0

var failures := 0
var checks := 0
var room: P02MovementRoom
var router: LocalInputRouter
var origin := P02MovementRoom.WALL_FIXTURE_ORIGIN


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_configuration()
	room = P02_ROOM.instantiate() as P02MovementRoom
	root.add_child(room)
	await _frames(4)
	_join_seats()
	room.build_wall_fixtures()
	room.set_wall_movement_enabled(false)
	await _frames(2)
	await _test_disabled_is_inert()
	room.set_wall_movement_enabled(true)
	await _test_slide_and_symmetry()
	await _test_excluded_surfaces()
	await _test_kick_per_device()
	await _test_hold_echo_and_buffer()
	await _test_lock_and_recontact()
	await _test_grace_and_removal()
	await _test_ground_precedence()
	await _test_lifecycle_transitions()
	await _test_shaft_climb_measurement()
	await _test_maximum_force_containment()
	room.queue_free()
	await process_frame
	await _test_p03_integration()
	await _test_reload_cycles()
	print("P02_WALL_TESTS checks=%d failures=%d" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _check(condition: bool, label: String) -> void:
	checks += 1
	if condition:
		print("PASS ", label)
	else:
		failures += 1
		push_error("FAIL " + label)


func _frames(count: int) -> void:
	for _frame in range(count):
		await physics_frame


func _key(key: Key, pressed: bool, echo: bool = false, location: int = 0) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.keycode = key
	event.pressed = pressed
	event.echo = echo
	event.location = location
	router._handle_key(event)


func _pad(device: int, button: int, pressed: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.device = device
	event.button_index = button
	event.pressed = pressed
	router._handle_joy_button(event)


func _join_seats() -> void:
	router = room.input_router
	router.set_shared_keyboard_enabled(true)
	router.set_phase(LocalInputRouter.Phase.LOBBY)
	_key(KEY_F, true)
	_key(KEY_F, false)
	_key(KEY_ENTER, true)
	_key(KEY_ENTER, false)
	_pad(10, JOY_BUTTON_A, true)
	_pad(10, JOY_BUTTON_A, false)
	router.set_phase(LocalInputRouter.Phase.PLAY)


func _actor(seat: int) -> ChickenController:
	return room.actors[seat] as ChickenController


func _place(actor: ChickenController, position: Vector2) -> void:
	actor.reset_wall_state()
	actor.global_position = position
	actor.velocity = Vector2.ZERO
	actor.locomotion_velocity = Vector2.ZERO
	actor.external_velocity = Vector2.ZERO
	actor.coyote_remaining = 0.0
	actor.jump_buffer_remaining = 0.0
	actor.lifecycle.status = PlayerLifecycleState.Status.ACTIVE
	actor.lifecycle.terminal_reason = ""


func _slab_stand() -> Vector2:
	return Vector2(
		WallFixtureBuilder.slab_right_stand_x(origin, BODY_WIDTH), origin.y + 24.0
	)


func _left_of_shaft_stand() -> Vector2:
	var x := origin.x + WallFixtureBuilder.SHAFT_LEFT_X - BODY_WIDTH * 0.5 - 0.1
	return Vector2(x, origin.y + 24.0)


func _test_configuration() -> void:
	var tuning := GameplayTuning.new()
	_check(tuning.validate().is_empty(), "default tuning with wall keys validates")
	_check(not tuning.wall_movement_enabled, "wall movement ships disabled by default")
	_check(
		tuning.wall_slide_fall_cap_wu_s == 120.0
		and tuning.wall_jump_horizontal_wu_s == 240.0
		and tuning.wall_jump_vertical_wu_s == -520.0
		and tuning.wall_jump_contact_grace_s == 0.08
		and tuning.wall_jump_recontact_separation_wu == 8.0,
		"wall keys start at the documented unmeasured candidates"
	)
	var bad := GameplayTuning.new()
	bad.wall_slide_fall_cap_wu_s = -1.0
	_check(not bad.validate().is_empty(), "non-positive slide cap is rejected")
	bad = GameplayTuning.new()
	bad.wall_jump_vertical_wu_s = 100.0
	_check(not bad.validate().is_empty(), "downward wall jump impulse is rejected")
	bad = GameplayTuning.new()
	bad.wall_jump_horizontal_wu_s = NAN
	_check(not bad.validate().is_empty(), "non-finite wall impulse is rejected")
	bad = GameplayTuning.new()
	bad.wall_jump_recontact_separation_wu = 0.5
	_check(not bad.validate().is_empty(), "separation below the probe distance is rejected")
	var source := GameplayTuning.new()
	source.wall_movement_enabled = true
	var snapshot := ConfigurationSnapshot.create(source, PresentationSettings.new(), "movement_room", 12345, 1)
	source.wall_movement_enabled = false
	_check(snapshot.gameplay.wall_movement_enabled, "run snapshot isolates wall movement keys")
	var arena := ArenaDefinition.new(GameplayTuning.new())
	var eligible_ids := ["arena.base_a", "arena.base_b", "arena.base_c", "arena.base_d", "arena.goal"]
	var classification_ok := true
	for spec in arena.surface_specs:
		var metadata := spec.metadata as SupportSurfaceMetadata
		var expected_eligible: bool = eligible_ids.has(spec.id)
		var is_eligible := (
			metadata.wall_movement_eligibility == SupportSurfaceMetadata.Eligibility.ELIGIBLE
		)
		classification_ok = classification_ok and expected_eligible == is_eligible
		classification_ok = classification_ok and (
			metadata.wave_support_eligibility == SupportSurfaceMetadata.Eligibility.INELIGIBLE
		)
	_check(
		classification_ok,
		"base platform sides are wall-eligible; floor, containment and ceiling are not; wave flag unchanged"
	)


func _test_disabled_is_inert() -> void:
	var actor := _actor(0)
	_place(actor, _slab_stand())
	await _frames(14)
	_check(
		actor.wall_side == 0 and not actor.wall_sliding and actor.locomotion_velocity.y > 300.0,
		"disabled wall movement applies no slide cap and records no contact"
	)
	_place(actor, _slab_stand())
	await _frames(6)
	_key(KEY_SPACE, true)
	await _frames(3)
	_key(KEY_SPACE, false)
	_check(actor.wall_kick_count == 0, "disabled wall movement never kicks")


func _test_slide_and_symmetry() -> void:
	var actor := _actor(0)
	var cap := actor.tuning.wall_slide_fall_cap_wu_s
	_place(actor, _slab_stand())
	await _frames(14)
	var left_wall_speed := actor.locomotion_velocity.y
	_check(
		actor.wall_side == -1 and actor.wall_sliding and absf(left_wall_speed - cap) <= 0.5,
		"airborne contact with a wall on the left slides at the configured cap"
	)
	_check(actor.coyote_remaining == 0.0 and not actor.is_on_floor(), "wall contact grants no coyote or floor")
	_place(actor, _left_of_shaft_stand())
	await _frames(14)
	var right_wall_speed := actor.locomotion_velocity.y
	_check(
		actor.wall_side == 1 and actor.wall_sliding and absf(right_wall_speed - cap) <= 0.5,
		"airborne contact with a wall on the right slides identically"
	)
	print(
		(
			"P02_WALL_METRIC slide cap=%.2f left_wall_speed=%.2f right_wall_speed=%.2f"
			% [cap, left_wall_speed, right_wall_speed]
		)
	)
	_place(actor, _slab_stand())
	actor.locomotion_velocity.y = -400.0
	await _frames(1)
	_check(
		not actor.wall_sliding and actor.locomotion_velocity.y < -300.0,
		"ascending beside an eligible wall is not speed-capped"
	)
	_check(
		actor.support_tracker == null,
		"wall contact needs no support tracker and publishes no support in the P02 room"
	)


func _test_excluded_surfaces() -> void:
	var actor := _actor(0)
	var excluded_stand := Vector2(
		origin.x + WallFixtureBuilder.EXCLUDED_X + WallFixtureBuilder.FIXTURE_WIDTH_WU + 12.1,
		origin.y + 24.0
	)
	_place(actor, excluded_stand)
	await _frames(14)
	_check(
		actor.wall_side == 0 and actor.locomotion_velocity.y > 300.0,
		"explicitly ineligible solid never slides"
	)
	_key(KEY_SPACE, true)
	await _frames(3)
	_key(KEY_SPACE, false)
	_check(actor.wall_kick_count == 0, "explicitly ineligible solid never kicks")
	var one_way_stand := Vector2(
		origin.x + WallFixtureBuilder.ONE_WAY_X + WallFixtureBuilder.FIXTURE_WIDTH_WU + 12.1,
		origin.y + 24.0
	)
	_place(actor, one_way_stand)
	await _frames(14)
	_check(
		actor.wall_side == 0 and actor.locomotion_velocity.y > 300.0,
		"one-way solid side never slides even when flagged eligible"
	)
	_place(actor, Vector2(144.0 + 12.1, 300.0))
	await _frames(12)
	_check(
		actor.wall_side == 0 and actor.locomotion_velocity.y > 300.0,
		"solid without wall metadata (arena containment style) fails closed"
	)
	var trigger := Area2D.new()
	trigger.name = "WallTrigger"
	trigger.position = Vector2(700.0, 300.0)
	room.world_layer().add_child(trigger)
	trigger.set_meta(
		SupportSurfaceMetadata.META_KEY, _eligible_metadata("wall_fixture.trigger")
	)
	var trigger_shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(16.0, 128.0)
	trigger_shape.shape = rectangle
	trigger.add_child(trigger_shape)
	_place(actor, Vector2(700.0 + 8.0 + 12.1, 260.0))
	await _frames(10)
	_check(actor.wall_side == 0, "an Area2D trigger is never a wall")
	trigger.queue_free()
	var other := _actor(1)
	_place(other, Vector2(760.0, 260.0))
	_place(actor, Vector2(770.0, 260.0))
	await _frames(10)
	_check(
		actor.wall_side == 0 and actor.locomotion_velocity.y > 300.0,
		"another chicken is never a wall"
	)
	_place(other, Vector2(270.0, 548.0))


func _eligible_metadata(surface_id: String) -> SupportSurfaceMetadata:
	var metadata := SupportSurfaceMetadata.new()
	metadata.surface_id = surface_id
	metadata.wave_support_eligibility = SupportSurfaceMetadata.Eligibility.INELIGIBLE
	metadata.wall_movement_eligibility = SupportSurfaceMetadata.Eligibility.ELIGIBLE
	return metadata


func _kick_trial(
	actor: ChickenController, press: Callable, release: Callable, label: String
) -> void:
	_place(actor, _slab_stand())
	await _frames(8)
	var before := actor.wall_kick_count
	press.call()
	# The first await resumes before the kick tick runs; the second is one tick after the kick.
	await _frames(2)
	var vx := actor.locomotion_velocity.x
	var vy := actor.locomotion_velocity.y
	await _frames(1)
	var kicks := actor.wall_kick_count - before
	release.call()
	await _frames(1)
	print("P02_WALL_METRIC kick device=%s kicks=%d vx=%.2f vy=%.2f" % [label, kicks, vx, vy])
	_check(kicks == 1, "%s: one fresh press produces exactly one kick" % label)
	_check(
		vx > 238.0 and vx <= 240.5 and vy >= -500.0 and vy <= -475.0,
		"%s: kick travels away from the wall with the configured impulse" % label
	)


func _test_kick_per_device() -> void:
	await _kick_trial(
		_actor(0),
		func() -> void: _key(KEY_SPACE, true),
		func() -> void: _key(KEY_SPACE, false),
		"synthetic K1"
	)
	await _kick_trial(
		_actor(1),
		func() -> void: _key(KEY_CTRL, true, false, KEY_LOCATION_RIGHT),
		func() -> void: _key(KEY_CTRL, false, false, KEY_LOCATION_RIGHT),
		"synthetic K2"
	)
	await _kick_trial(
		_actor(2),
		func() -> void: _pad(10, JOY_BUTTON_A, true),
		func() -> void: _pad(10, JOY_BUTTON_A, false),
		"synthetic gamepad"
	)
	var actor := _actor(0)
	_place(actor, _left_of_shaft_stand())
	await _frames(8)
	_key(KEY_SPACE, true)
	await _frames(3)
	_key(KEY_SPACE, false)
	_check(
		actor.wall_kick_count >= 1 and actor.locomotion_velocity.x < -230.0,
		"wall on the right kicks left with the mirrored impulse"
	)
	_place(actor, _slab_stand())
	await _frames(8)
	_key(KEY_SPACE, true)
	await _frames(2)
	_key(KEY_A, true)
	await _frames(3)
	var steered_vx := actor.locomotion_velocity.x
	_key(KEY_A, false)
	_key(KEY_SPACE, false)
	print("P02_WALL_METRIC steering vx_after_3_ticks_holding_toward_wall=%.2f" % steered_vx)
	_check(
		steered_vx < 200.0 and actor.intentional_input,
		"air steering applies immediately after a kick"
	)


func _test_hold_echo_and_buffer() -> void:
	var actor := _actor(0)
	_place(actor, _slab_stand())
	await _frames(8)
	_key(KEY_SPACE, true, true)
	await _frames(5)
	_check(actor.wall_kick_count == 0, "OS key echo alone never kicks")
	_key(KEY_SPACE, false)
	_place(actor, _slab_stand())
	await _frames(8)
	var before := actor.wall_kick_count
	_key(KEY_SPACE, true)
	for _repeat in range(6):
		await _frames(10)
		_key(KEY_SPACE, true, true)
	_key(KEY_SPACE, false)
	_check(
		actor.wall_kick_count - before == 1,
		"holding jump with OS repeats for one second yields exactly one kick"
	)
	_place(actor, _slab_stand() + Vector2(6.0, 0.0))
	actor.locomotion_velocity.x = -120.0
	before = actor.wall_kick_count
	_key(KEY_SPACE, true)
	await _frames(12)
	_key(KEY_SPACE, false)
	_check(
		actor.wall_kick_count - before == 1,
		"a press just before contact is buffered and consumed exactly once"
	)


func _test_lock_and_recontact() -> void:
	var actor := _actor(0)
	_place(actor, _slab_stand())
	await _frames(8)
	_key(KEY_SPACE, true)
	await _frames(2)
	_key(KEY_SPACE, false)
	_check(actor.wall_kick_count == 1 and actor.wall_lock_side == -1, "first contact kicks and locks")
	var face_x := origin.x + WallFixtureBuilder.FIXTURE_WIDTH_WU
	var stand := _slab_stand()
	actor.global_position = Vector2(stand.x, actor.global_position.y)
	actor.locomotion_velocity.x = 0.0
	_key(KEY_SPACE, true)
	await _frames(3)
	_key(KEY_SPACE, false)
	_check(actor.wall_kick_count == 1, "second press at the same contact does not kick")
	await _frames(10)
	actor.global_position = Vector2(stand.x + 20.0, actor.global_position.y)
	actor.locomotion_velocity.x = 0.0
	await _frames(2)
	_check(actor.wall_lock_side == 0, "separation beyond the threshold reopens the contact lock")
	actor.global_position = Vector2(stand.x, actor.global_position.y)
	await _frames(2)
	_key(KEY_SPACE, true)
	await _frames(3)
	_key(KEY_SPACE, false)
	_check(actor.wall_kick_count == 2, "fresh recontact after separation allows exactly one more kick")
	# Measure where the lock clears when drifting away at kick speed.
	_place(actor, stand)
	await _frames(8)
	_key(KEY_SPACE, true)
	var clear_gap := -1.0
	for _frame in range(20):
		await physics_frame
		if clear_gap < 0.0 and actor.wall_kick_count > 0 and actor.wall_lock_side == 0:
			clear_gap = actor.global_position.x - BODY_WIDTH * 0.5 - face_x
	_key(KEY_SPACE, false)
	print("P02_WALL_METRIC recontact lock_cleared_at_gap_wu=%.2f" % clear_gap)
	_check(clear_gap >= actor.tuning.wall_jump_recontact_separation_wu, "lock clears only once the gap reaches the threshold")


func _test_grace_and_removal() -> void:
	var actor := _actor(0)
	_place(actor, _slab_stand())
	await _frames(8)
	actor.global_position.x += 3.0
	actor.locomotion_velocity.x = 0.0
	await _frames(1)
	var before := actor.wall_kick_count
	_key(KEY_SPACE, true)
	await _frames(3)
	_key(KEY_SPACE, false)
	_check(actor.wall_kick_count - before == 1, "a press inside the post-separation grace kicks once")
	_place(actor, _slab_stand())
	await _frames(8)
	actor.global_position.x += 3.0
	actor.locomotion_velocity.x = 0.0
	await _frames(10)
	before = actor.wall_kick_count
	_key(KEY_SPACE, true)
	await _frames(3)
	_key(KEY_SPACE, false)
	_check(actor.wall_kick_count == before, "a press after the grace expires does not kick")
	var moving := room.wall_fixtures["moving"] as StaticBody2D
	var moving_stand := Vector2(
		origin.x + WallFixtureBuilder.MOVING_X + WallFixtureBuilder.FIXTURE_WIDTH_WU + 12.1,
		origin.y + 24.0
	)
	_place(actor, moving_stand)
	await _frames(8)
	_check(actor.wall_side == -1, "a moving wall qualifies while contact is valid")
	moving.position.x += 60.0
	await _frames(12)
	before = actor.wall_kick_count
	_key(KEY_SPACE, true)
	await _frames(3)
	_key(KEY_SPACE, false)
	_check(
		actor.wall_side == 0 and actor.wall_kick_count == before,
		"a moving wall that left contact clears slide and cannot be kicked"
	)
	var shaft_left := room.wall_fixtures["shaft_left"] as StaticBody2D
	_place(actor, _left_of_shaft_stand())
	await _frames(8)
	_check(actor.wall_side == 1, "removable wall qualifies before removal")
	before = actor.wall_kick_count
	shaft_left.queue_free()
	_key(KEY_SPACE, true)
	await _frames(3)
	_key(KEY_SPACE, false)
	_check(
		actor.wall_side == 0 and actor.wall_kick_count == before,
		"same-step wall removal clears contact and refuses the kick"
	)
	room.build_wall_fixtures()
	await _frames(2)


func _test_ground_precedence() -> void:
	var actor := _actor(0)
	var wall := WallFixtureBuilder.add_solid(
		room.world_layer(), "wall_fixture.floor_wall", Rect2(Vector2(700.0, 452.0), Vector2(16.0, 128.0)), true
	)
	_place(actor, Vector2(728.1, 556.0))
	await _frames(20)
	_check(actor.is_on_floor() and actor.wall_side == 0, "grounded beside a wall records no wall contact")
	_key(KEY_SPACE, true)
	await _frames(2)
	_key(KEY_SPACE, false)
	_check(
		actor.wall_kick_count == 0 and actor.locomotion_velocity.y < -300.0,
		"ground jump beside an eligible wall stays a normal ground jump"
	)
	wall.queue_free()
	await _frames(2)


func _test_lifecycle_transitions() -> void:
	var actor := _actor(0)
	# External launch pre-empts and clears wall state.
	_place(actor, _slab_stand())
	await _frames(8)
	var kicks := actor.wall_kick_count
	actor.launch(Vector2(0.0, -300.0))
	_check(actor.wall_side == 0 and actor.wall_lock_side == 0, "launch clears wall eligibility immediately")
	_key(KEY_SPACE, true)
	await _frames(3)
	_key(KEY_SPACE, false)
	_check(actor.wall_kick_count == kicks, "a launch is not overwritten by a wall kick")
	# Capture, opening freeze and terminal states cannot wall-act; intent stays observable.
	for state_name in ["captured", "opening_freeze", "secured", "eliminated"]:
		_place(actor, _slab_stand())
		await _frames(8)
		kicks = actor.wall_kick_count
		room.set_player_state(0, state_name)
		_key(KEY_SPACE, true)
		await _frames(3)
		var intent_visible := actor.intentional_input
		_key(KEY_SPACE, false)
		_check(
			actor.wall_kick_count == kicks and actor.wall_side == 0,
			"%s state cannot slide or kick" % state_name
		)
		if state_name in ["captured", "opening_freeze"]:
			_check(intent_visible, "%s state keeps jump intent observable" % state_name)
		room.set_player_state(0, "active")
		actor.set_captured(false)
		actor.set_opening_freeze(false)
		actor.lifecycle.status = PlayerLifecycleState.Status.ACTIVE
		actor.lifecycle.terminal_reason = ""
	# Pause/resume cannot replay a stale press.
	_place(actor, _slab_stand())
	await _frames(8)
	kicks = actor.wall_kick_count
	room.pause_coordinator.set_paused("wall pause probe", -1)
	_key(KEY_SPACE, true)
	await _frames(5)
	_key(KEY_SPACE, false)
	paused = false
	room.pause_coordinator.state = PauseRecoveryCoordinator.State.RUNNING
	router.resume_system()
	router.set_phase(LocalInputRouter.Phase.PLAY)
	await _frames(5)
	_check(actor.wall_kick_count == kicks, "pause/resume does not replay a stale wall press")
	# Phase change clears the buffer and wall state.
	_place(actor, _slab_stand())
	await _frames(8)
	kicks = actor.wall_kick_count
	_key(KEY_SPACE, true)
	router.set_phase(LocalInputRouter.Phase.PUGAD)
	router.set_phase(LocalInputRouter.Phase.PLAY)
	_key(KEY_SPACE, false)
	await _frames(4)
	_check(
		actor.wall_kick_count == kicks and actor.jump_buffer_remaining == 0.0,
		"phase change clears the buffered wall press"
	)
	# Reset clears all wall state.
	_place(actor, _slab_stand())
	await _frames(8)
	room._reset_trial()
	_check(
		actor.wall_side == 0 and actor.wall_lock_side == 0 and not actor.wall_sliding,
		"diagnostic reset clears wall contact, lock and slide"
	)


func _test_shaft_climb_measurement() -> void:
	var actor := _actor(0)
	var center_x := WallFixtureBuilder.shaft_center_x(origin)
	_place(actor, Vector2(center_x - 20.0, origin.y + 100.0))
	await _frames(2)
	var kick_heights: Array[float] = []
	var highest := actor.global_position.y
	var steer_key := KEY_D
	for _frame in range(240):
		await physics_frame
		highest = minf(highest, actor.global_position.y)
		if actor.wall_side != 0 and actor.wall_lock_side == 0 and actor.jump_buffer_remaining == 0.0:
			steer_key = KEY_A if actor.wall_side > 0 else KEY_D
			_key(KEY_A, false)
			_key(KEY_D, false)
			_key(KEY_SPACE, true)
			_key(KEY_SPACE, false)
			_key(steer_key, true)
		if actor.wall_kick_count > kick_heights.size():
			kick_heights.append(actor.global_position.y)
	_key(KEY_A, false)
	_key(KEY_D, false)
	var gains := PackedStringArray()
	for index in range(1, kick_heights.size()):
		gains.append("%.1f" % (kick_heights[index - 1] - kick_heights[index]))
	print(
		(
			"P02_WALL_METRIC shaft kicks=%d max_height_y=%.2f gain_per_cycle=%s"
			% [kick_heights.size(), highest, ",".join(gains)]
		)
	)
	_check(kick_heights.size() >= 1, "two-wall shaft permits wall kicks (measured, not rejected)")


func _test_maximum_force_containment() -> void:
	var actor := _actor(0)
	var vectors: Array[Vector2] = [
		Vector2(480.0, -900.0), Vector2(-480.0, -900.0), Vector2(0.0, -900.0), Vector2(480.0, 0.0)
	]
	for vector in vectors:
		_place(actor, _slab_stand() if vector.x >= 0.0 else _left_of_shaft_stand())
		await _frames(8)
		_key(KEY_SPACE, true)
		await _frames(3)
		_key(KEY_SPACE, false)
		actor.launch(vector)
		var contained := true
		var min_point := actor.global_position
		var max_point := actor.global_position
		for _frame in range(120):
			await physics_frame
			contained = contained and actor.bounds.has_point(actor.global_position)
			min_point = Vector2(
				minf(min_point.x, actor.global_position.x), minf(min_point.y, actor.global_position.y)
			)
			max_point = Vector2(
				maxf(max_point.x, actor.global_position.x), maxf(max_point.y, actor.global_position.y)
			)
		print(
			(
				"P02_WALL_METRIC containment launch=%s min=%s max=%s contained=%s"
				% [vector, min_point, max_point, contained]
			)
		)
		_check(contained, "kick plus launch %s stays inside visible bounds" % vector)
		_check(actor.external_velocity.length() <= 1100.0, "wall kick never enlarges external launch caps")


func _test_p03_integration() -> void:
	var stage := P03_ROOM.instantiate() as P03StageRoom
	root.add_child(stage)
	await _frames(3)
	_check(not stage.tuning.wall_movement_enabled, "P03 stage starts with wall movement disabled")
	var seat := stage.join_keyboard("K1")
	stage.start_play()
	var actor := stage.actors[seat] as ChickenController
	stage.set_wall_movement_enabled(true)
	var base_a_right_face := 320.0
	_p03_place(actor, Vector2(base_a_right_face + 12.1, 395.0))
	await _frames(12)
	_check(
		actor.wall_side == -1 and actor.wall_sliding,
		"P03 base platform side slides when wall movement is enabled"
	)
	_check(
		stage.support_tracker.contacts_by_actor.get(actor.support_actor_id, []).is_empty(),
		"wall slide records no support contact"
	)
	_check(
		stage.current_support_result(actor.support_actor_id, 384.0).reason == "no support",
		"wall contact never qualifies as support or Rising-wave eligibility"
	)
	_p03_place(actor, Vector2(12.1, 300.0))
	await _frames(12)
	_check(
		actor.wall_side == 0 and actor.locomotion_velocity.y > 300.0,
		"P03 left containment wall never qualifies"
	)
	_p03_place(actor, Vector2(base_a_right_face + 12.1, 395.0))
	await _frames(8)
	var visible := true
	_press_p03(true)
	await _frames(3)
	_press_p03(false)
	actor.launch(Vector2(480.0, -900.0))
	var contained := true
	for _frame in range(60):
		await physics_frame
		await process_frame
		contained = contained and actor.bounds.has_point(actor.global_position)
		if not stage.camera_rig.targets.is_empty():
			visible = visible and stage.camera_rig.screen_bounds_visible(
				stage.camera_rig.targets[0].world_rect
			)
	_check(contained, "P03 kick plus maximum launch stays inside the arena bounds")
	_check(visible, "camera keeps the actor visible through kick plus maximum launch")
	stage.queue_free()
	await process_frame


func _p03_place(actor: ChickenController, position: Vector2) -> void:
	_place(actor, position)


func _press_p03(pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = KEY_SPACE
	event.keycode = KEY_SPACE
	event.pressed = pressed
	for node in root.get_children():
		if node is P03StageRoom:
			(node as P03StageRoom).input_router._handle_key(event)


func _test_reload_cycles() -> void:
	var before := root.get_child_count()
	for _cycle in range(5):
		var transient := P02_ROOM.instantiate() as P02MovementRoom
		root.add_child(transient)
		await process_frame
		transient.build_wall_fixtures()
		transient.set_wall_movement_enabled(true)
		await process_frame
		transient.queue_free()
		await process_frame
	_check(root.get_child_count() == before, "five wall fixture reload cycles leave no retained nodes")

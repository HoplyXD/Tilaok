extends SceneTree

## NLB-P01 input ownership and simulation authority boundary regressions.
## Run with Godot 4.7.2:
## --headless --fixed-fps 60 --path tilaok! --script res://tests/run_nlb_p01_tests.gd

var checks := 0
var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_authority_roles()
	_test_local_action_mapping()
	_test_remote_assignment_and_actions()
	_test_input_neutralization_and_capacity()
	_test_authority_denials()
	_test_detached_presentation_state()
	_test_reset_teardown_cycles()
	print("NLB_P01_TESTS checks=%d failures=%d" % [checks, failures])
	await process_frame
	quit(1 if failures > 0 else 0)


func _check(condition: bool, label: String) -> void:
	checks += 1
	if condition:
		print("PASS ", label)
	else:
		failures += 1
		push_error("FAIL " + label)


func _test_authority_roles() -> void:
	var offline := SimulationAuthority.offline()
	var host := SimulationAuthority.host()
	var client := SimulationAuthority.client_presentation()
	_check(offline.can_commit(), "offline role commits by default")
	_check(host.can_commit(), "host role can commit")
	_check(not client.can_commit(), "client presentation has no commit authority")
	_check(client.is_client_presentation(), "client role remains explicit")
	var invalid := SimulationAuthority.new()
	_check(not invalid.configure(99) and not invalid.can_commit(), "invalid role fails closed")


func _test_local_action_mapping() -> void:
	var router := LocalInputRouter.new()
	router.set_shared_keyboard_enabled(true)
	router.set_phase(LocalInputRouter.Phase.PLAY)
	var layouts := ["K1", "K2", "K3", "K4"]
	var left_keys := [KEY_A, KEY_LEFT, KEY_J, KEY_KP_4]
	var right_keys := [KEY_D, KEY_RIGHT, KEY_L, KEY_KP_6]
	var down_keys := [KEY_S, KEY_DOWN, KEY_K, KEY_KP_2]
	var jump_keys := [KEY_SPACE, KEY_CTRL, KEY_I, KEY_KP_8]
	for index in layouts.size():
		var layout: String = layouts[index]
		var seat := router.registry.join_keyboard(layout)
		var jump_location := KEY_LOCATION_RIGHT if layout == "K2" else KEY_LOCATION_UNSPECIFIED
		_send_key(router, int(left_keys[index]), true)
		_check(
			is_equal_approx(router.movement_axis(seat), -1.0),
			"%s left reaches shared movement" % layout
		)
		_send_key(router, int(right_keys[index]), true)
		_check(
			is_zero_approx(router.movement_axis(seat)) and router.has_direction_intent(seat),
			"%s opposing directions retain intentional input" % layout
		)
		_send_key(router, int(left_keys[index]), false)
		_send_key(router, int(right_keys[index]), false)
		_send_key(router, int(down_keys[index]), true)
		_check(router.is_action_held(seat, "down"), "%s down enters shared sneak action" % layout)
		_send_key(router, int(down_keys[index]), false)
		_send_key(router, int(jump_keys[index]), true, jump_location)
		_check(
			(
				router.is_action_held(seat, "jump")
				and router.consume_pressed(seat, "jump")
				and not router.consume_pressed(seat, "jump")
			),
			"%s jump press/hold is shared and consumed exactly once" % layout
		)
		_send_key(router, int(jump_keys[index]), false, jump_location)
	_check(router.registry.joined_seats().size() == 4, "host spectator occupies no player seat")
	var gamepad_router := LocalInputRouter.new()
	gamepad_router.set_phase(LocalInputRouter.Phase.PLAY)
	var gamepad_seat := gamepad_router.registry.join_gamepad(0)
	var pause_seats: Array[int] = []
	gamepad_router.pause_requested.connect(func(seat: int) -> void: pause_seats.append(seat))
	_send_joy_button(gamepad_router, JOY_BUTTON_DPAD_LEFT, true)
	var left_ok := is_equal_approx(gamepad_router.movement_axis(gamepad_seat), -1.0)
	_send_joy_button(gamepad_router, JOY_BUTTON_DPAD_LEFT, false)
	_send_joy_button(gamepad_router, JOY_BUTTON_A, true)
	var jump_ok := gamepad_router.consume_pressed(gamepad_seat, "jump")
	_send_joy_button(gamepad_router, JOY_BUTTON_A, false)
	_send_joy_button(gamepad_router, JOY_BUTTON_X, true)
	var contextual_ok := gamepad_router.consume_pressed(gamepad_seat, "cheer")
	_send_joy_button(gamepad_router, JOY_BUTTON_X, false)
	_send_joy_button(gamepad_router, JOY_BUTTON_START, true)
	_check(
		left_ok and jump_ok and contextual_ok,
		"gamepad d-pad, jump and contextual alias share seat actions"
	)
	_check(pause_seats == [gamepad_seat], "gamepad Start submits the shared pause request")
	router.free()
	gamepad_router.free()


func _send_key(router: LocalInputRouter, key: int, pressed: bool, location: int = 0) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.pressed = pressed
	event.location = location
	router._handle_key(event)


func _send_joy_button(router: LocalInputRouter, button: int, pressed: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.device = 0
	event.button_index = button
	event.pressed = pressed
	router._handle_joy_button(event)


func _test_remote_assignment_and_actions() -> void:
	var router := LocalInputRouter.new()
	var adapter := RemoteSeatInputAdapter.new()
	var host := SimulationAuthority.host()
	_check(adapter.configure(router, host), "host adapter binds to shared router")
	var first := adapter.assign_source("peer-alpha")
	_check(first == 0, "host assigns first remote source to first available seat")
	_check(adapter.assign_source("peer-alpha") == -1, "duplicate source ownership is rejected")
	_check(
		(
			adapter.submit_action("peer-alpha", "right", true)
			and is_equal_approx(router.movement_axis(first), 1.0)
		),
		"remote right action enters the same movement query"
	)
	_check(
		(
			adapter.submit_action("peer-alpha", "left", true)
			and is_zero_approx(router.movement_axis(first))
			and router.has_direction_intent(first)
		),
		"opposing remote directions have zero axis but retain intent"
	)
	_check(
		router.intentional_input_sources(first).size() == 2,
		"opposing input sources remain individually observable"
	)
	_check(
		(
			adapter.submit_action("peer-alpha", "jump", true)
			and router.consume_pressed(first, "jump")
			and not router.consume_pressed(first, "jump")
		),
		"remote jump press is consumed exactly once"
	)
	_check(
		(
			adapter.submit_action("peer-alpha", "jump", false)
			and adapter.submit_action("peer-alpha", "jump", false)
		),
		"duplicate release is harmless"
	)
	_check(
		(
			adapter.submit_movement_axis("peer-alpha", -0.65)
			and is_equal_approx(router.movement_axis(first), -0.65)
		),
		"remote normalized axis reaches shared movement state"
	)
	_check(
		(
			not adapter.submit_movement_axis("peer-alpha", 1.01)
			and not adapter.submit_movement_axis("unknown-peer", 0.5)
			and not adapter.submit_action("peer-alpha", "join", true)
		),
		"out-of-range, unknown and join-injection input is rejected"
	)
	_check(
		not adapter.submit_action("peer-alpha", "pause", true) == false,
		"remote pause is an ordinary host-bound action request"
	)
	adapter.revoke_source("peer-alpha")
	_check(
		(
			router.registry.seat_for_remote_source("peer-alpha") == -1
			and is_zero_approx(router.movement_axis(first))
			and not router.has_direction_intent(first)
		),
		"revocation clears ownership and held/axis input"
	)
	_check(
		not adapter.submit_action("peer-alpha", "right", true),
		"revoked source cannot submit actions"
	)
	router.free()


func _test_input_neutralization_and_capacity() -> void:
	var router := LocalInputRouter.new()
	var adapter := RemoteSeatInputAdapter.new()
	adapter.configure(router, SimulationAuthority.host())
	var seat := adapter.assign_source("phase-peer")
	router.set_phase(LocalInputRouter.Phase.PLAY)
	adapter.submit_action("phase-peer", "jump", true)
	router.set_phase(LocalInputRouter.Phase.PLACE)
	_check(
		not router.consume_pressed(seat, "jump") and router.is_action_held(seat, "jump"),
		"phase change clears edge but blocks held one-shot action"
	)
	adapter.submit_action("phase-peer", "jump", false)
	adapter.submit_action("phase-peer", "jump", true)
	_check(router.consume_pressed(seat, "jump"), "release then fresh press is accepted")
	var ids := ["peer-b", "peer-c", "peer-d"]
	for source_id in ids:
		_check(
			adapter.assign_source(source_id) >= 0, "host assigns another remote seat: " + source_id
		)
	_check(adapter.assign_source("peer-fifth") == -1, "fifth seat is rejected")
	_check(
		adapter.assign_source("invalid:source") == -1,
		"source identities reject invalid characters and cannot exceed seat cap"
	)
	_check(
		adapter.assign_source("peer/path") == -1 and adapter.assign_source("peer.name") == -1,
		"remote source identities reject slash and dot separators"
	)
	_check(adapter.revoke_source("phase-peer"), "source revoke succeeds")
	_check(router.registry.seat_for_remote_source("phase-peer") == -1, "revoke removes source map")
	var client_router := LocalInputRouter.new()
	var client_adapter := RemoteSeatInputAdapter.new()
	client_adapter.configure(client_router, SimulationAuthority.client_presentation())
	_check(
		client_adapter.assign_source("cannot-own") == -1, "client cannot assign remote ownership"
	)
	_check(
		not client_router.apply_remote_action("cannot-own", "right", true),
		"client cannot inject gameplay input"
	)
	_check(
		client_router.registry.join_keyboard("K1") == -1, "client cannot claim a local player seat"
	)
	var host_registry := PlayerSeatRegistry.new()
	host_registry.authority = SimulationAuthority.host()
	var retained_seat := host_registry.join_keyboard("K1")
	host_registry.authority = SimulationAuthority.client_presentation()
	_check(not host_registry.set_ready(retained_seat, true), "client cannot commit a ready state")
	host_registry.clear_to_lobby()
	_check(
		(
			bool(host_registry.get_seat(retained_seat).joined)
			and not bool(host_registry.get_seat(retained_seat).ready)
		),
		"client cannot clear host-owned seat assignments"
	)
	router.free()
	client_router.free()


func _test_authority_denials() -> void:
	var client := SimulationAuthority.client_presentation()
	var phase := MatchPhaseController.new()
	phase.authority = client
	phase.enter(MatchPhaseController.Phase.PLAY, 10.0)
	var phase_advanced := phase.advance(1.0)
	_check(
		(
			phase.phase == MatchPhaseController.Phase.LOBBY
			and is_zero_approx(phase.remaining_seconds)
			and not phase_advanced
		),
		"client cannot change phase or advance its timer"
	)
	var lifecycle := MatchLifecycleCoordinator.new()
	lifecycle.authority = client
	_check(
		not lifecycle.begin(4) and lifecycle.match_id == -1 and lifecycle.completed_round == 0,
		"client cannot begin authoritative match lifecycle"
	)
	var race := RaceRoundController.new()
	race.authority = client
	_check(
		not race.begin("client", [0, 1], {0: 0, 1: 0}) and not race.active,
		"client cannot begin race"
	)
	var schedule := EventSchedule.new()
	schedule.authority = client
	var rng := RandomNumberGenerator.new()
	rng.seed = 31415
	var rng_before := rng.state
	var schedule_error := schedule.begin(
		rng, [EventSchedule.Challenge.KARERA, EventSchedule.Challenge.LAGSANAY], 4
	)
	_check(
		not schedule_error.is_empty() and rng.state == rng_before and schedule.locked.is_empty(),
		"client schedule denial does not draw RNG or lock rounds"
	)
	var item_manager := ItemManager.new()
	item_manager.authority = client
	var denied_place := item_manager.place("unknown", Vector2i.ZERO, 0, 0)
	var denied_remove := item_manager.remove("missing", "client")
	var denied_play := item_manager.begin_play()
	_check(
		(
			not bool(denied_place.get("allowed", false))
			and not bool(denied_remove.get("allowed", false))
			and item_manager.pieces.is_empty()
			and not item_manager.in_play
			and denied_play.is_empty()
		),
		"client item placement, removal and activation are side-effect free"
	)
	var budget := TransientBudget.new()
	budget.configure(GameplayTuning.new())
	var granted := budget.allocate(
		TransientBudget.Kind.PROJECTILE, [{"emitter_id": "fixture", "player_id": ""}]
	)
	budget.authority = client
	var budget_count_before := budget.total_count()
	var denied_allocation := budget.allocate(
		TransientBudget.Kind.PROJECTILE, [{"emitter_id": "client", "player_id": ""}]
	)
	var denied_release := budget.release(TransientBudget.Kind.PROJECTILE, int(granted[0].handle))
	budget.advance(1000.0)
	budget.clear_all()
	_check(
		(
			budget_count_before == 1
			and denied_allocation.is_empty()
			and denied_release.is_empty()
			and budget.total_count() == budget_count_before
		),
		"client cannot allocate, advance, release or clear authoritative transient budget"
	)
	var arena := ArenaDefinition.new()
	arena.authority = client
	_check(
		(
			not arena.register_player_construction("client-piece")
			and not arena.unregister_player_construction("arena.floor")
		),
		"client cannot edit construction ownership in stage"
	)
	var support := SupportTracker.new()
	support.authority = client
	support.finalized_step = 41
	support.surfaces["fixture"] = SupportSurfaceMetadata.new()
	support.finalize_physics_step(42)
	support.clear()
	_check(
		support.finalized_step == 41 and support.surfaces.has("fixture"),
		"client cannot advance or clear support state"
	)
	var chicken := ChickenController.new()
	chicken.simulation_authority = client
	chicken.launch(Vector2(300.0, -300.0))
	var eliminated := chicken.eliminate("client")
	chicken.reset_for_round(Vector2(500.0, 100.0))
	_check(
		(
			not eliminated
			and chicken.lifecycle.status == PlayerLifecycleState.Status.ACTIVE
			and chicken.external_velocity == Vector2.ZERO
			and chicken.position == Vector2.ZERO
		),
		"client cannot change actor velocity, lifecycle or transform"
	)
	var barya := BaryaRoundObjective.new()
	barya.authority = client
	var barya_before := barya.state
	_check(
		(
			not barya.begin_offer(1, 1, "egg")
			and barya.commit_terminal(0, "finished", 1).is_empty()
			and barya.state == barya_before
		),
		"client cannot mutate Barya ownership or receipts"
	)
	var event := LagsanayRoundController.new()
	event.authority = client
	var event_rng := RandomNumberGenerator.new()
	event_rng.seed = 88
	var event_rng_before := event_rng.state
	var event_started := event.begin("event", [0, 1], {}, event_rng, 1.0, 2.0, 3.0, 4.0, 5.0)
	_check(
		not event_started and event_rng.state == event_rng_before and not event.active,
		"client cannot draw event taya or start event"
	)
	item_manager.free()
	chicken.free()


func _test_detached_presentation_state() -> void:
	var source := {"players": [{"seat": 1, "display": {"identity": "triangle"}}], "scores": {1: 8}}
	var copy := SimulationAuthority.offline().detached_snapshot(source) as Dictionary
	(copy.players[0].display as Dictionary).identity = "spoofed"
	copy.scores[1] = -999
	_check(
		str(source.players[0].display.identity) == "triangle" and int(source.scores[1]) == 8,
		"nested presentation dictionaries are detached from authoritative state"
	)


func _test_reset_teardown_cycles() -> void:
	var router := LocalInputRouter.new()
	var adapter := RemoteSeatInputAdapter.new()
	adapter.configure(router, SimulationAuthority.host())
	for cycle in range(10):
		var source_id := "cycle-%d" % cycle
		var seat := adapter.assign_source(source_id)
		if seat >= 0:
			adapter.submit_action(source_id, "right", true)
			adapter.submit_movement_axis(source_id, 0.75)
			adapter.revoke_source(source_id)
		router.clear_input_state()
		router.registry.clear_to_lobby()
	_check(
		(
			router.registry.joined_seats().is_empty()
			and router.intentional_input_sources(0).is_empty()
			and router.movement_axis(0) == 0.0
		),
		"ten reset/teardown cycles leave no stale source, seat or held movement"
	)
	router.free()

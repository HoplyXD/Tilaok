extends SceneTree

## P13-T11 spectator cheer: eliminated and secured seats cheer during Play with the Rotate control
## (R / Right Shift / West); live seats, other phases, pauses and the results ignore it; a 1 s
## per-seat cooldown holds; the HUD mark stays inside the existing score row; and a cheer-spam run
## leaves scores, clocks, positions, commands and every random stream exactly as a no-cheer run.
## Synthetic seats and input only; the physical-keyboard check stays with P02-T04 / P13-T12.

const ROOM_SCENE := preload("res://scenes/match/p12_scheduled_match_room.tscn")
const KARERA := EventSchedule.Challenge.KARERA
const LAGSANAY := EventSchedule.Challenge.LAGSANAY
const KANGAROO := EventSchedule.Challenge.KANGAROO
const NONE := EventSchedule.Challenge.NONE
const PADS := [7101, 7102]
const HUD_RESERVATION := 64.0
const SPAM_FRAMES := 300

var checks := 0
var failures := 0
var room: P12ScheduledMatchRoom
var emitted := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_unit()
	_test_router_binding()
	await _test_room_rules()
	await _test_no_simulation_effect()
	print("P13_CHEER_TESTS checks=%d failures=%d" % [checks, failures])
	quit(1 if failures > 0 else 0)


# --- unit ---------------------------------------------------------------------------------------


func _test_unit() -> void:
	var cheer := SpectatorCheer.new()
	var count := [0]
	cheer.cheered.connect(func(_seat: int) -> void: count[0] += 1)
	_check(not cheer.request(0, false), "an ineligible seat cannot cheer")
	_check(not cheer.is_cooling(0), "an ignored request does not start the cooldown")
	_check(cheer.request(0, true), "an eligible seat cheers")
	_check(cheer.is_cooling(0) and is_equal_approx(cheer.remaining(0), 1.0), "1 s cooldown starts")
	_check(not cheer.request(0, true), "a repeat inside the cooldown is ignored")
	_check(cheer.request(1, true), "another seat has its own cooldown")
	cheer.advance(0.99)
	_check(not cheer.request(0, true), "0.99 s later it is still cooling")
	cheer.advance(0.011)
	_check(cheer.request(0, true), "after 1 s it cheers again")
	_check(count[0] == 3, "three cheers were reported (%d)" % count[0])
	cheer.reset()
	_check(not cheer.is_cooling(0), "reset clears the cooldowns")
	var stream := SpectatorCheer.make_stream()
	_check(
		stream.get_length() > 0.2 and stream.get_length() < 1.0,
		"the placeholder cue is a short sound (%.2f s)" % stream.get_length()
	)


func _test_router_binding() -> void:
	var router := LocalInputRouter.new()
	root.add_child(router)
	router.set_shared_keyboard_enabled(true)
	router.registry.join_keyboard("K1")
	router.registry.join_keyboard("K2")
	router.registry.join_gamepad(PADS[0])
	var seen: Array[String] = []
	router.action_pressed.connect(
		func(seat: int, name: String) -> void: seen.append("%d:%s" % [seat, name])
	)
	router.set_phase(LocalInputRouter.Phase.PLAY)
	_tap_key(router, KEY_R, false)
	_tap_key(router, KEY_SHIFT, true)
	var event := InputEventJoypadButton.new()
	event.device = PADS[0]
	event.button_index = JOY_BUTTON_X
	event.pressed = true
	router._handle_joy_button(event)
	event.pressed = false
	router._handle_joy_button(event)
	_check(
		seen == ["0:cheer", "1:cheer", "2:cheer"],
		"R, Right Shift and West cheer during Play (%s)" % [seen]
	)
	seen.clear()
	for phase in [
		LocalInputRouter.Phase.PUGAD, LocalInputRouter.Phase.MENU, LocalInputRouter.Phase.RESULTS
	]:
		router.set_phase(phase)
		_tap_key(router, KEY_R, false)
	_check("0:cheer" not in seen, "outside Play the same key never reports a cheer (%s)" % [seen])
	router.queue_free()


func _tap_key(router: LocalInputRouter, key: Key, right: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.pressed = true
	if right:
		event.location = KEY_LOCATION_RIGHT
	router._handle_key(event)
	event.pressed = false
	router._handle_key(event)


# --- the room ------------------------------------------------------------------------------------


func _test_room_rules() -> void:
	var seats := await _open(4, {1: [KARERA, NONE]})
	await _to_play(seats)
	var presenter := room.presenter
	var hud := presenter.play_hud
	presenter._cheer.cheered.connect(func(_seat: int) -> void: emitted += 1)
	# Seat 0 is eliminated by a trap, seat 1 reaches the flag; seats 2 and 3 are still running.
	await physics_frame
	_trap(seats[0])
	await _frames(3)
	await physics_frame
	room.race_candidate_queue.queue_goal(
		room.actors[seats[1]] as ChickenController, Engine.get_physics_frames()
	)
	await _frames(4)
	_check(_status(seats[0]) == PlayerLifecycleState.Status.ELIMINATED, "seat 1 is out")
	_check(_status(seats[1]) == PlayerLifecycleState.Status.SECURED, "seat 2 has finished")
	# Live seats are ignored.
	_press(seats[2])
	_press(seats[3])
	await _frames(2)
	_check(emitted == 0 and presenter.cheering_seats().is_empty(), "live chickens cannot cheer")
	_check(hud.score_rows[seats[2]].state_text() == "RUN", "a live seat keeps its RUN state")
	# An eliminated seat cheers: mark in its own row only.
	_press(seats[0])
	await _frames(2)
	_check(emitted == 1, "an eliminated chicken cheers (%d)" % emitted)
	_check(
		hud.score_rows[seats[0]].state_text() == "CHEER!", "its own score row shows CHEER! as text"
	)
	_check(hud.score_rows[seats[1]].state_text() == "SECURED", "other rows are unchanged")
	_check(
		(
			is_equal_approx(presenter.cheer_cooldown_remaining(seats[0]), 1.0)
			or presenter.cheer_cooldown_remaining(seats[0]) > 0.9
		),
		"the 1 s cooldown is running"
	)
	_press(seats[0])
	_press(seats[0])
	await _frames(2)
	_check(emitted == 1, "repeat presses inside the cooldown are ignored")
	# A secured seat cheers too.
	_press(seats[1])
	await _frames(2)
	_check(emitted == 2, "a secured chicken cheers")
	_check_hud_fits(hud, "two cheering rows")
	# After the cooldown it cheers again and the mark has cleared.
	await _frames(66)
	_check(hud.score_rows[seats[0]].state_text() == "OUT", "the mark clears after 1 s (OUT)")
	_press(seats[0])
	await _frames(2)
	_check(emitted == 3, "after the cooldown it cheers again")
	# While paused nothing happens.
	await _frames(66)
	room.pause_coordinator.set_paused("test pause", -1)
	await _frames(2)
	_press(seats[0])
	_check(emitted == 3, "a paused game ignores the cheer")
	room.pause_coordinator.set_paused("", -1)
	await _close()

	# Pugad and Place: the key is claim / rotate territory, never a cheer.
	seats = await _open(2, {1: [KARERA, NONE]})
	var other := room.presenter
	other._cheer.cheered.connect(func(_seat: int) -> void: emitted += 1)
	emitted = 0
	_check(
		room.phase_controller.phase == MatchPhaseController.Phase.PUGAD, "the match is in the Pugad"
	)
	_press(seats[0])
	await _frames(2)
	_check(emitted == 0, "the Pugad does not cheer")
	room._finish_pugad_timeout()
	await _frames(2)
	_press(seats[0])
	await _frames(2)
	_check(emitted == 0, "the Place does not cheer")
	await _close()


func _check_hud_fits(hud: UiPlayHud, label: String) -> void:
	var bar_rect := hud.hud_bar.get_global_rect()
	_check(bar_rect.size.y <= HUD_RESERVATION + 1.5, "%s: the HUD bar stays within 64 px" % label)
	var viewport_width := float(ProjectSettings.get_setting("display/window/size/viewport_width"))
	_check(
		bar_rect.position.x >= -1.5 and bar_rect.end.x <= viewport_width + 1.5,
		"%s: the HUD bar stays within the screen width" % label
	)


# --- no simulation effect ---------------------------------------------------------


func _test_no_simulation_effect() -> void:
	var control_a := await _scenario(false)
	var control_b := await _scenario(false)
	_check(
		JSON.stringify(control_a) == JSON.stringify(control_b),
		"control: two identical no-cheer runs agree (the comparison is meaningful)"
	)
	var spam := await _scenario(true)
	var presses := int(spam.presses)
	spam.erase("presses")
	control_a.erase("presses")
	_check(
		JSON.stringify(control_a) == JSON.stringify(spam),
		"%d cheer presses change no score, clock, position, command or random stream" % presses
	)
	for key in control_a:
		if JSON.stringify(control_a[key]) != JSON.stringify(spam.get(key)):
			push_error("P13_CHEER differs in %s: %s vs %s" % [key, control_a[key], spam.get(key)])
	_check(presses > 100, "the spam run really pressed (%d)" % presses)


## One scripted Kangaroo + Bomb-Taya round: seat 1 is trapped, then the run just plays. With
## `spam` every seat (live ones too) mashes the cheer control every few frames.
func _scenario(spam: bool) -> Dictionary:
	var seats := await _open(4, {1: [KANGAROO, LAGSANAY]})
	await _to_play(seats)
	room.bomb_taya.head_start_remaining = 0.0
	var presses := 0
	for frame in SPAM_FRAMES:
		await physics_frame
		if frame == 20:
			_trap(seats[0])
		if spam and frame % 3 == 0:
			for seat in seats:
				_press(seat)
				presses += 1
	await process_frame
	var positions: Array = []
	for seat in seats:
		var actor := room.actors[seat] as ChickenController
		positions.append(
			[snappedf(actor.global_position.x, 0.001), snappedf(actor.global_position.y, 0.001)]
		)
	var streams := room.match_streams
	var result := {
		"presses": presses,
		"scores": room.cumulative_score_units.duplicate(),
		"phase": room.phase_controller.phase,
		"sim_time": snappedf(room.items.director.simulation_time, 0.0001),
		"positions": positions,
		"commands": room.kangaroo_round.controller.command_history.size(),
		"markers": room.kangaroo_round.controller.marker_counts.duplicate(),
		"live": room.kangaroo_round.controller.live_seats.duplicate(),
		"taya": room.bomb_taya.taya_seat,
		"countdown": snappedf(room.bomb_taya.countdown_remaining, 0.0001),
		"rng":
		[
			streams.egg.state,
			streams.event.state,
			streams.kangaroo.state,
			streams.tie.state,
			streams.taya.state,
			streams.cosmetic.state,
		],
	}
	await _close()
	return result


# --- harness ------------------------------------------------------------------------


func _press(seat: int) -> void:
	var router := room.input_router
	match seat:
		0:
			_tap_key(router, KEY_R, false)
		1:
			_tap_key(router, KEY_SHIFT, true)
		_:
			var event := InputEventJoypadButton.new()
			event.device = PADS[seat - 2]
			event.button_index = JOY_BUTTON_X
			event.pressed = true
			router._handle_joy_button(event)
			event.pressed = false
			router._handle_joy_button(event)


func _open(seat_count: int, forced: Dictionary) -> Array[int]:
	room = ROOM_SCENE.instantiate() as P12ScheduledMatchRoom
	root.add_child(room)
	await process_frame
	await physics_frame
	var seats: Array[int] = [room.join_keyboard("K1"), room.join_keyboard("K2")]
	for device_id in PADS.slice(0, seat_count - 2):
		var seat_index := room.input_router.registry.join_gamepad(device_id)
		seats.append(seat_index)
		room.input_router.seat_joined.emit(seat_index)
	for seat_index in seats:
		room.input_router.registry.set_ready(seat_index, true)
	_check(room.start_match(), "%d-seat scheduled match starts" % seat_count)
	for round_number in forced:
		var pair: Array = forced[round_number]
		room.schedule.locked[int(round_number)] = {
			"round": int(round_number),
			"main": int(pair[0]),
			"twist": int(pair[1]),
			"guaranteed": false,
			"sudden_death": false,
			"twist_options": 0,
		}
	room.tuning.match_target_score_units = 100000
	room.tuning.match_results_advance_seconds = 600.0
	room.tuning.match_race_hard_cap_seconds = 600.0
	room.tuning.match_race_after_first_finish_seconds = 600.0
	return seats


func _to_play(seats: Array[int]) -> void:
	room._finish_pugad_timeout()
	var edits: Array[Dictionary] = []
	room._resolve_place_edits(edits)
	var index := 0
	for seat in seats:
		var actor := room.actors[seat] as ChickenController
		actor.global_position = room.arena.controller_origin_from_feet(
			room.arena.spawn_feet + Vector2(220.0 * index, 0.0)
		)
		actor.velocity = Vector2.ZERO
		index += 1
	await _frames(4)


func _trap(seat: int) -> void:
	var record := AttributionRecord.new()
	record.kind = AttributionRecord.Kind.ELIMINATION
	record.player_seat = seat
	record.source_item_id = "trap.p13cheer.%d" % seat
	record.owner_seat = -1
	record.physics_time = room.items.director.simulation_time + 0.004
	record.physics_tick = Engine.get_physics_frames()
	record.time_comparable = true
	record.round_id = room.items.director.active_round_id
	record.event_id = (
		"%s:item:%s:%d:%d" % [record.round_id, record.source_item_id, record.physics_tick, seat]
	)
	room._on_item_elimination(record)


func _status(seat: int) -> PlayerLifecycleState.Status:
	return (room.actors[seat] as ChickenController).lifecycle.status


func _close() -> void:
	Engine.time_scale = 1.0
	if room != null and is_instance_valid(room):
		room.queue_free()
	room = null
	paused = false
	await process_frame
	await process_frame


func _frames(count: int) -> void:
	for _frame in count:
		await physics_frame
	await process_frame


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("P13_CHEER FAIL: " + message)
	print("%s %s" % ["PASS" if condition else "FAIL", message])

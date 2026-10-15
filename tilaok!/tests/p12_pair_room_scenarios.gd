# gdlint: disable=max-file-lines
extends RefCounted

## P12-T05..T10 stack scenarios on the scheduled match room (`P12ScheduledMatchRoom`): real
## physics, real actors, the persistent stage, deterministic scripted goals and traps at 2, 3 and
## 4 seats (K1/K2 keyboard seats plus synthetic gamepad IDs; no physical device). Each round's
## locked schedule entry is forced to the pair under test (test-only; the real schedule rolls it).

const ROOM_SCENE := preload("res://scenes/match/p12_scheduled_match_room.tscn")
const KARERA := EventSchedule.Challenge.KARERA
const LAGSANAY := EventSchedule.Challenge.LAGSANAY
const KANGAROO := EventSchedule.Challenge.KANGAROO
const NONE := EventSchedule.Challenge.NONE
const SPIKES := "block.spikes.main"

var check: Callable
var tree: SceneTree
var room: P12ScheduledMatchRoom
var _serial := 0


func _init(check_callback: Callable, scene_tree: SceneTree) -> void:
	check = check_callback
	tree = scene_tree


func run_all() -> void:
	for seat_count: int in [2, 3, 4]:
		await _karera_bomb_taya(seat_count)
	for seat_count: int in [2, 3, 4]:
		await _karera_kangaroo(seat_count)
	for seat_count: int in [2, 3, 4]:
		await _kangaroo_bomb_taya(seat_count)
	await _pause_freezes_every_clock()
	await _sudden_death_after_a_stack()
	await _ten_restarts_are_stable()


# --- harness ----------------------------------------------------------------------------------


func _open(seat_count: int, forced: Dictionary) -> Array[int]:
	room = ROOM_SCENE.instantiate() as P12ScheduledMatchRoom
	tree.root.add_child(room)
	await tree.process_frame
	await tree.physics_frame
	var seats: Array[int] = [room.join_keyboard("K1"), room.join_keyboard("K2")]
	for device_id in [7101, 7102].slice(0, seat_count - 2):
		var seat_index := room.input_router.registry.join_gamepad(device_id)
		seats.append(seat_index)
		room.input_router.seat_joined.emit(seat_index)
	for seat_index in seats:
		room.input_router.registry.set_ready(seat_index, true)
	check.call(room.start_match(), "%d-seat scheduled match starts" % seat_count)
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
	room.tuning.kangaroo_telegraph_seconds = 0.05
	room.tuning.kangaroo_response_seconds = 1.0
	room.tuning.kangaroo_reset_seconds = 0.05
	return seats


func _to_play() -> void:
	room._finish_pugad_timeout()
	var edits: Array[Dictionary] = []
	room._resolve_place_edits(edits)
	check.call(
		room.phase_controller.phase == MatchPhaseController.Phase.PLAY,
		(
			"round %d enters Play as %s"
			% [room.items.round_number + 1, EventSchedule.describe(room.current_entry())]
		)
	)


func _close() -> void:
	Engine.time_scale = 1.0
	if room != null and is_instance_valid(room):
		room.queue_free()
	room = null
	await tree.process_frame
	await tree.process_frame


func _steps(count: int) -> void:
	for _index in count:
		await tree.physics_frame


func _seats() -> Array[int]:
	var result: Array[int] = []
	for seat in room.input_router.registry.joined_seats():
		result.append(int(seat.seat))
	return result


func _status(seat: int) -> PlayerLifecycleState.Status:
	return (room.actors[seat] as ChickenController).lifecycle.status


func _secured(seat: int) -> bool:
	return _status(seat) == PlayerLifecycleState.Status.SECURED


func _eliminated(seat: int) -> bool:
	return _status(seat) == PlayerLifecycleState.Status.ELIMINATED


## Spreads the runners so nobody tags or hugs by accident.
func _spread() -> void:
	var index := 0
	for seat in _seats():
		var actor := room.actors[seat] as ChickenController
		var feet := room.arena.spawn_feet + Vector2(220.0 * index, 0.0)
		actor.global_position = room.arena.controller_origin_from_feet(feet)
		actor.velocity = Vector2.ZERO
		index += 1


func _skip_bomb_head_start() -> void:
	room.bomb_taya.head_start_remaining = 0.0
	var opening := room.actors.get(room.bomb_taya.opening_taya_seat) as ChickenController
	if opening != null:
		opening.set_opening_freeze(false)


## Queues a goal touch for the CURRENT physics step (call right after a physics_frame await).
func _goal(seat: int) -> bool:
	return room.race_candidate_queue.queue_goal(
		room.actors[seat] as ChickenController, Engine.get_physics_frames()
	)


func _trap(seat: int, owner: int, offset := 0.004, comparable := true) -> bool:
	_serial += 1
	var record := AttributionRecord.new()
	record.kind = AttributionRecord.Kind.ELIMINATION
	record.player_seat = seat
	record.source_item_id = "trap.p12.%d" % _serial
	record.owner_seat = owner
	record.physics_time = room.items.director.simulation_time + offset
	record.physics_tick = Engine.get_physics_frames()
	record.time_comparable = comparable
	record.round_id = room.items.director.active_round_id
	record.event_id = (
		"%s:item:%s:%d:%d" % [record.round_id, record.source_item_id, record.physics_tick, seat]
	)
	return room._on_item_elimination(record)


func _ledger(seat: int) -> Dictionary:
	if room.race_round_controller == null:
		return {}
	return room.race_round_controller.ledger.outcomes_by_seat.get(seat, {})


func _award_keys(model: MatchResultsViewModel) -> Array[String]:
	var keys: Array[String] = []
	for row in model.award_rows:
		keys.append(str(row.key))
	return keys


func _race_only(seats: Array[int], start: Dictionary) -> Dictionary:
	return RaceScoreCalculator.calculate(seats, room.race_round_controller.ledger.outcomes(), start)


func _totals_match(expected: Dictionary, seats: Array[int]) -> bool:
	var ok := bool(expected.valid)
	for seat in seats:
		ok = ok and int(room.cumulative_score_units[seat]) == int(expected.totals_units[seat])
	return ok


# --- Karera + Bomb-Taya: the approved same-step rows on the real room -----------------------


func _karera_bomb_taya(seat_count: int) -> void:
	var tag := "K+L %d seats" % seat_count
	var seats := await _open(seat_count, {1: [KARERA, LAGSANAY]})
	_to_play()
	_spread()
	_skip_bomb_head_start()
	await _steps(2)
	check.call(
		(
			room.bomb_taya.active
			and room.goal_area.monitoring
			and room.play_twist_text() == "TWIST: BOMB-TAYA"
		),
		"%s: Karera Main with the flag live and a Bomb-Taya Twist" % tag
	)
	# U3: a finishing taya hands the bomb over inside the step that commits the finish.
	var first := room.bomb_taya.taya_seat
	room.bomb_taya.countdown_remaining = 6.0
	await tree.physics_frame
	_goal(first)
	await _steps(2)
	check.call(
		_secured(first) and room.bomb_taya.taya_seat != first and room.bomb_taya.taya_seat >= 0,
		"%s: U3 the finishing taya is secured and the bomb moved on" % tag
	)
	check.call(
		room.bomb_taya.countdown_remaining > 5.5 and room.bomb_taya.countdown_remaining < 6.0,
		(
			"%s: U3 the remaining countdown is kept (%.2f s)"
			% [tag, room.bomb_taya.countdown_remaining]
		)
	)
	await _close()

	# C4 / U1: trap strictly earlier than the timeout keeps its Patibong; a later/tied one does not.
	seats = await _open(seat_count, {1: [KARERA, LAGSANAY]})
	_to_play()
	_spread()
	_skip_bomb_head_start()
	await _steps(2)
	var taya := room.bomb_taya.taya_seat
	var owner := (taya + 1) % seat_count
	room.bomb_taya.countdown_remaining = 0.5 / 60.0
	check.call(_trap(taya, owner, 0.001), "%s: the Twist takes the trap record" % tag)
	await _steps(2)
	check.call(
		(
			str(_ledger(taya).get("cause", "")) == "direct_hazard"
			and int(_ledger(taya).get("direct_owner_seat", -1)) == owner
		),
		"%s: C4 a strictly earlier trap beats the timeout and keeps its credit" % tag
	)
	await _close()
	seats = await _open(seat_count, {1: [KARERA, LAGSANAY]})
	_to_play()
	_spread()
	_skip_bomb_head_start()
	await _steps(2)
	taya = room.bomb_taya.taya_seat
	owner = (taya + 1) % seat_count
	room.bomb_taya.countdown_remaining = 0.5 / 60.0
	_trap(taya, owner, 0.012)
	await _steps(2)
	check.call(
		_eliminated(taya) and int(_ledger(taya).get("direct_owner_seat", 0)) == -1,
		"%s: C4 a trap at or after the expiry is the timeout (no Patibong)" % tag
	)
	check.call(
		room.bomb_taya.taya_seat != taya,
		"%s: a new taya is chosen after the timeout (U4 timer for the live count)" % tag
	)
	await _close()

	# U1 on the room: goal and timeout on one step eliminate.
	seats = await _open(seat_count, {1: [KARERA, LAGSANAY]})
	_to_play()
	_spread()
	_skip_bomb_head_start()
	await _steps(2)
	taya = room.bomb_taya.taya_seat
	await tree.physics_frame
	room.bomb_taya.countdown_remaining = 0.5 / 60.0
	_goal(taya)
	await _steps(2)
	check.call(
		_eliminated(taya) and not _secured(taya),
		"%s: U1 goal and timeout on one step: the taya is eliminated, not secured" % tag
	)
	await _close()


# --- Karera + Kangaroo (T07/T08) -----------------------------------------------------------


func _karera_kangaroo(seat_count: int) -> void:
	var tag := "K+Kg %d seats" % seat_count
	var seats := await _open(seat_count, {1: [KARERA, KANGAROO]})
	_to_play()
	var controller := room.kangaroo_round.controller
	check.call(
		controller.active and controller.twist_role and room.goal_area.monitoring,
		"%s: Karera owns the end; Kangaroo runs as a Twist with the flag live" % tag
	)
	check.call(room.play_twist_text() == "TWIST: KANGAROO", "%s: the HUD names the Twist" % tag)
	var early := seats[0]
	var start := room.round_start_score_units.duplicate()
	await tree.physics_frame
	_goal(early)
	await _steps(2)
	check.call(_secured(early), "%s: a finisher is secured" % tag)
	check.call(
		not controller.live_seats.has(early),
		"%s: a secured finisher leaves command eligibility" % tag
	)
	Engine.time_scale = 6.0
	await _steps(900)
	Engine.time_scale = 1.0
	var completed := 0
	for command in controller.command_history:
		if bool(command.evaluated):
			completed += 1
	check.call(
		completed >= 3 or room.phase_controller.phase == MatchPhaseController.Phase.RESULTS,
		"%s: commands complete under the race deadlines (%d completed)" % [tag, completed]
	)
	check.call(
		int(controller.marker_counts.get(early, 0)) == 0,
		"%s: a secured finisher never gains a failure marker" % tag
	)
	var failed := -1
	for seat in seats:
		if seat != early and _eliminated(seat):
			failed = seat
	if failed >= 0:
		await tree.physics_frame
		check.call(
			not _goal(failed) and _eliminated(failed),
			"%s: a failed runner cannot finish later" % tag
		)
		check.call(
			str(_ledger(failed).get("cause", "")) == "command_failure",
			"%s: the third failure is a command_failure elimination" % tag
		)
	if (
		room.race_round_controller != null
		and room.phase_controller.phase == MatchPhaseController.Phase.RESULTS
	):
		var expected := _race_only(seats, start)
		check.call(
			_totals_match(expected, seats), "%s: scores equal the race calculator alone" % tag
		)
		var keys := _award_keys(room.last_results_model)
		check.call("patibong" not in keys, "%s: command failure never awards Patibong" % tag)
	await _close()

	# U6: goal and third failure on one step.
	seats = await _open(seat_count, {1: [KARERA, KANGAROO]})
	_to_play()
	var runner := seats[seat_count - 1]
	room.kangaroo_round.controller.marker_counts[runner] = 2
	await tree.physics_frame
	var now := room.items.director.simulation_time
	(
		room
		. kangaroo_round
		. controller
		. command_history
		. append(
			{
				"instance": null,
				"command_id": 900,
				"command": KangarooRoundController.Command.FREEZE,
				"command_name": "FREEZE",
				"is_storm": false,
				"band": -1,
				"wave_y": -1.0,
				"telegraph_start_at": now - 1.0,
				"response_start_at": now - 0.5,
				"response_end_at": now + 0.004,
				"reset_seconds": 0.0,
				"status": "RESPONSE",
				"response_started": true,
				"evaluated": false,
				"evaluated_at": -1.0,
				"grace_at": -1.0,
				"grace_checked": false,
				"initial_held_sources": {},
				"freeze_violations": {runner: true},
				"pass_by_seat": {},
				"failure_seats": [],
			}
		)
	)
	_goal(runner)
	await _steps(2)
	check.call(
		_eliminated(runner) and not _secured(runner),
		"%s: U6 goal and third failure on one step: eliminated, not secured" % tag
	)
	check.call(
		(
			str(_ledger(runner).get("cause", "")) == "command_failure"
			and int(_ledger(runner).get("direct_owner_seat", 0)) == -1
		),
		"%s: U6 the ledger cause is command_failure with no credit" % tag
	)
	await _close()

	# nobody finishes: the deadline owns the end, no points, visible reason.
	seats = await _open(seat_count, {1: [KARERA, KANGAROO]})
	room.tuning.match_race_hard_cap_seconds = 0.5
	room.tuning.match_race_after_first_finish_seconds = 0.5
	_to_play()
	Engine.time_scale = 6.0
	await _steps(120)
	Engine.time_scale = 1.0
	check.call(
		room.phase_controller.phase == MatchPhaseController.Phase.RESULTS,
		"%s: the race deadline ends a stacked round" % tag
	)
	var model := room.last_results_model
	if model != null:
		check.call(
			model.award_rows.is_empty() and not model.suppression_reason.is_empty(),
			"%s: nobody finished: no points and a visible reason" % tag
		)
	await _close()


# --- Kangaroo + Bomb-Taya (T09/T10) ----------------------------------------------------------


func _kangaroo_bomb_taya(seat_count: int) -> void:
	var tag := "Kg+L %d seats" % seat_count
	var seats := await _open(seat_count, {1: [KANGAROO, LAGSANAY]})
	_to_play()
	var controller := room.kangaroo_round.controller
	check.call(
		controller.active and not controller.twist_role and room.bomb_taya.active,
		"%s: Kangaroo is the Main; Bomb-Taya is the Twist" % tag
	)
	check.call(not room.goal_area.monitoring, "%s: the flag is hidden in elimination Mains" % tag)
	_spread()
	_skip_bomb_head_start()
	room.bomb_taya.countdown_remaining = 5.0
	await tree.physics_frame
	controller._create_command(
		KangarooRoundController.Command.FREEZE, -1, room.items.director.simulation_time, false, 1.0
	)
	await _steps(5)
	var before := room.bomb_taya.countdown_remaining
	await _steps(30)
	check.call(
		room.bomb_taya.countdown_remaining < before,
		(
			"%s: the taya countdown keeps running through a Freeze (%.3f -> %.3f)"
			% [tag, before, room.bomb_taya.countdown_remaining]
		)
	)
	room.bomb_taya.countdown_remaining = 0.01
	var doomed := room.bomb_taya.taya_seat
	await _steps(3)
	check.call(
		_eliminated(doomed),
		"%s: a low countdown during Freeze still eliminates the taya (R4 stays inactive)" % tag
	)
	await _close()

	# multiple terminal causes in one step: one outcome per player.
	seats = await _open(seat_count, {1: [KANGAROO, LAGSANAY]})
	_to_play()
	_spread()
	_skip_bomb_head_start()
	await _steps(2)
	var timed_out := room.bomb_taya.taya_seat
	var trapped := (timed_out + 1) % seat_count
	await tree.physics_frame
	room.bomb_taya.countdown_remaining = 0.5 / 60.0
	_trap(trapped, timed_out)
	await _steps(2)
	var outcomes := room.kangaroo_round.controller.outcomes()
	var causes := {}
	var single := true
	for row in outcomes:
		single = single and not causes.has(int(row.seat_index))
		causes[int(row.seat_index)] = str(row.cause)
	check.call(single, "%s: one outcome per player" % tag)
	check.call(
		str(causes.get(timed_out, "")) == "timeout",
		"%s: the taya timeout is a Kangaroo-arbitrated elimination (%s)" % [tag, str(causes)]
	)
	check.call(
		str(causes.get(trapped, "")) == "direct_hazard",
		"%s: a trap in the same step eliminates on its own seat" % tag
	)
	await _close()

	# Storm with two survivors (needs a third seat to eliminate first).
	seats = await _open(seat_count, {1: [KANGAROO, LAGSANAY]})
	room.tuning.kangaroo_storm_after_commands = 2
	_to_play()
	_spread()
	_skip_bomb_head_start()
	for index in range(seat_count - 2):
		await tree.physics_frame
		_trap(seats[index], -1)
		await _steps(2)
	check.call(
		room.kangaroo_round.controller.live_seats.size() == 2,
		(
			"%s: down to two survivors (%d live)"
			% [tag, room.kangaroo_round.controller.live_seats.size()]
		)
	)
	Engine.time_scale = 6.0
	var storm_seen := false
	for _frame in 900:
		await tree.physics_frame
		storm_seen = storm_seen or room.kangaroo_round.controller.storm_active
		if room.phase_controller.phase != MatchPhaseController.Phase.PLAY:
			break
	Engine.time_scale = 1.0
	check.call(
		storm_seen or room.phase_controller.phase == MatchPhaseController.Phase.RESULTS,
		"%s: two survivors run Storm cadence until a winner" % tag
	)
	await _close()

	# everyone eliminated together: Last Cluck, one placement table.
	seats = await _open(seat_count, {1: [KANGAROO, LAGSANAY]})
	_to_play()
	_spread()
	_skip_bomb_head_start()
	await tree.physics_frame
	for seat in seats:
		_trap(seat, -1)
	await _steps(3)
	var cluck := room.last_results_model
	check.call(
		room.phase_controller.phase == MatchPhaseController.Phase.RESULTS and cluck != null,
		"%s: everyone eliminated together resolves the round" % tag
	)
	if cluck != null:
		check.call(
			not cluck.last_cluck_explanation.is_empty(),
			"%s: Last Cluck is announced and explained" % tag
		)
		var keys := _award_keys(cluck)
		check.call(
			"tapos" not in keys and "una" not in keys and "bayani" not in keys,
			"%s: Kangaroo Main uses the placement family only (%s)" % [tag, str(keys)]
		)
	await _close()


# --- lifecycle ---------------------------------------------------------------------------


func _pause_freezes_every_clock() -> void:
	var seats := await _open(4, {1: [KARERA, LAGSANAY]})
	_to_play()
	_spread()
	_skip_bomb_head_start()
	room.bomb_taya.countdown_remaining = 20.0
	await _steps(5)
	room.pause_coordinator.set_paused("test pause", -1)
	await _steps(2)
	check.call(room.get_tree().paused, "K+L: pausing freezes the tree")
	var frozen := room.bomb_taya.countdown_remaining
	var race_clock := room.race_round_controller.elapsed_seconds
	await _steps(30)
	check.call(
		(
			room.bomb_taya.countdown_remaining == frozen
			and room.race_round_controller.elapsed_seconds == race_clock
		),
		"K+L: the taya countdown and the race clock stay frozen together"
	)
	room.get_tree().paused = false
	await _close()
	seats = await _open(3, {1: [KANGAROO, LAGSANAY]})
	_to_play()
	_spread()
	_skip_bomb_head_start()
	await _steps(5)
	room.pause_coordinator.set_paused("test pause", -1)
	await _steps(2)
	var kangaroo_time := room.kangaroo_round.controller.active_time()
	var taya_clock := room.bomb_taya.countdown_remaining
	await _steps(30)
	check.call(
		(
			room.kangaroo_round.controller.active_time() == kangaroo_time
			and room.bomb_taya.countdown_remaining == taya_clock
		),
		"Kg+L: pause freezes the command clock and the taya countdown together"
	)
	room.get_tree().paused = false
	await _close()


func _sudden_death_after_a_stack() -> void:
	var seats := await _open(2, {1: [KARERA, LAGSANAY], 2: [KARERA, KANGAROO]})
	room.tuning.match_round_limit = 2
	# round 1 ends level (nobody finishes), round 2 is the Kangaroo stack and ends level too
	room.tuning.match_race_hard_cap_seconds = 0.3
	room.tuning.match_race_after_first_finish_seconds = 0.3
	_to_play()
	Engine.time_scale = 6.0
	await _steps(120)
	Engine.time_scale = 1.0
	room._start_next_round()
	await _steps(3)
	_to_play()
	Engine.time_scale = 6.0
	for _frame in 400:
		await tree.physics_frame
		if room._sudden_death_active or room.final_results_visible:
			break
	Engine.time_scale = 1.0
	check.call(
		room._sudden_death_active, "a level score after a stacked last round starts sudden death"
	)
	if room._sudden_death_active:
		check.call(
			room.play_twist_text().is_empty() and room.event_main == NONE,
			"sudden death is a standalone Lagsanay: no Twist tag, no Main left over"
		)
		check.call(
			not _bomb_or_kangaroo_hazard_target(),
			"no stack controller keeps taking hazards in sudden death"
		)
	if room._sudden_death_active:
		await tree.physics_frame
		_trap(seats[0], -1)
		await _steps(4)
		check.call(
			room.final_results_visible,
			"a trap eliminates in sudden death (its clock matches the hazard clock) and decides it"
		)
	check.call(seats.size() == 2, "two seats played")
	await _close()


func _bomb_or_kangaroo_hazard_target() -> bool:
	return room._bomb_taya_running() or room._kangaroo_twist_running()


func _ten_restarts_are_stable() -> void:
	await _open(2, {1: [KARERA, LAGSANAY]})
	room.tuning.match_target_score_units = 1
	var nodes: Array[int] = []
	var objects: Array[int] = []
	for restart in 10:
		if restart > 0:
			room.reset_room()
			for seat in _seats():
				room.input_router.registry.set_ready(seat, true)
			room.start_match()
			room.schedule.locked[1] = {
				"round": 1,
				"main": KARERA,
				"twist": LAGSANAY,
				"guaranteed": false,
				"sudden_death": false,
				"twist_options": 0,
			}
			room.tuning.match_target_score_units = 1
			room.tuning.match_results_advance_seconds = 600.0
		_to_play()
		_skip_bomb_head_start()
		await tree.physics_frame
		for seat in _seats():
			_goal(seat)
		await _steps(4)
		await tree.process_frame
		nodes.append(int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
		objects.append(int(Performance.get_monitor(Performance.OBJECT_COUNT)))
	print("P12_PAIR_RESTARTS nodes=%s objects=%s" % [str(nodes), str(objects)])
	check.call(
		nodes.back() <= nodes[1] + 2 and objects.back() <= objects[1] + 20,
		(
			"ten full-match restarts keep node (%d -> %d) and object (%d -> %d) counts stable"
			% [nodes[1], nodes.back(), objects[1], objects.back()]
		)
	)
	await _close()

extends RefCounted

## P12 decision-table scenarios at controller level: pure, deterministic and permutation-checked.
## Every row names its table id (C = covered by a source, U = owner-approved proposal).

var check: Callable
var host: Node
var _event_serial := 0


func run_all() -> void:
	_c1_goal_vs_hazard_ledger()
	_c2_competing_hazards_ledger()
	_c3_deadline_boundary_ledger()
	_c4_c5_bomb_batch()
	_c7_command_failure_vs_hazard()
	_u1_bomb_goal_vs_timeout()
	_u2_bomb_goal_vs_pass()
	_u3_bomb_finishing_taya_transfer()
	_u4_bomb_timer_after_timeout_with_finishers()
	_u5_deadline_vs_twist_terminal()
	_u6_goal_vs_third_failure()
	_u7_commands_with_one_runner()
	_u8_no_storm_as_twist()
	_u9_multi_cause_rank()
	_u10_bomb_failure_before_pass()
	_u11_bomb_pass_independent_of_hug()
	_u12_mixed_producers_one_batch()
	_bomb_permutations()


func _init(check_callback: Callable, host_node: Node) -> void:
	check = check_callback
	host = host_node


func _actors(seats: Array[int]) -> Dictionary:
	var result: Dictionary = {}
	for seat in seats:
		var actor := ChickenController.new()
		actor.seat_index = seat
		actor.support_actor_id = "seat_%d" % seat
		host.add_child(actor)
		result[seat] = actor
	return result


func _free_actors(actors: Dictionary) -> void:
	for actor in actors.values():
		if is_instance_valid(actor):
			(actor as Node).queue_free()


func _stream(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func _tuning() -> GameplayTuning:
	var tuning := GameplayTuning.new()
	tuning.kangaroo_telegraph_seconds = 0.05
	tuning.kangaroo_response_seconds = 1.0
	tuning.kangaroo_reset_seconds = 0.05
	return tuning


func _hazard(
	seat: int, tick: int, time: float, source_id := "trap.1", owner := 1, comparable := true
) -> AttributionRecord:
	var record := AttributionRecord.new()
	record.kind = AttributionRecord.Kind.ELIMINATION
	record.player_seat = seat
	record.source_item_id = source_id
	record.owner_seat = owner
	record.physics_time = time
	record.physics_tick = tick
	record.time_comparable = comparable
	record.round_id = "p12:lag"
	_event_serial += 1
	record.event_id = "p12:lag:item:%s:%d:%d:%d" % [source_id, tick, seat, _event_serial]
	return record


func _contact(seat: int, distance := 100.0) -> Dictionary:
	return {"seat_index": seat, "distance_squared": distance}


func _typed_contacts(rows: Array) -> Array[Dictionary]:
	var typed: Array[Dictionary] = []
	for row in rows:
		typed.append(row as Dictionary)
	return typed


func _seat_ints(rows: Array) -> Array[int]:
	var typed: Array[int] = []
	for row in rows:
		typed.append(int(row))
	return typed


func _cause_for(outcomes: Array, seat: int) -> String:
	for outcome in outcomes:
		if int(outcome.seat_index) == seat:
			return str(outcome.get("cause", ""))
	return ""


func _c1_goal_vs_hazard_ledger() -> void:
	var ledger := RaceOutcomeLedger.new()
	var seats: Array[int] = [0, 1]
	ledger.begin("c1", seats, {})
	var batch: Array[Dictionary] = [
		{
			"event_id": "c1:goal",
			"round_id": "c1",
			"seat_index": 0,
			"kind": "goal",
			"physics_tick": 5
		},
		{
			"event_id": "c1:elim",
			"round_id": "c1",
			"seat_index": 0,
			"kind": "elimination",
			"physics_tick": 5,
			"source_item_id": "trap.9",
			"direct_owner_seat": 1,
		},
	]
	var resolved := ledger.resolve_step(5, batch)
	check.call(
		resolved.size() == 1 and str(resolved[0].outcome) == "eliminated",
		"C1 same-step goal and direct hazard: elimination wins (one outcome)"
	)


func _c2_competing_hazards_ledger() -> void:
	var ledger := RaceOutcomeLedger.new()
	var seats: Array[int] = [0, 1, 2]
	ledger.begin("c2", seats, {})
	var batch: Array[Dictionary] = [
		{
			"event_id": "c2:b",
			"round_id": "c2",
			"seat_index": 0,
			"kind": "elimination",
			"physics_tick": 3,
			"source_item_id": "trap.b",
			"direct_owner_seat": 2,
		},
		{
			"event_id": "c2:a",
			"round_id": "c2",
			"seat_index": 0,
			"kind": "elimination",
			"physics_tick": 3,
			"source_item_id": "trap.a",
			"direct_owner_seat": 1,
		},
	]
	var resolved := ledger.resolve_step(3, batch)
	check.call(
		resolved.size() == 1 and int(resolved[0].direct_owner_seat) == 1,
		"C2 competing hazards on one seat: stable item id decides the single credited kill"
	)


func _c3_deadline_boundary_ledger() -> void:
	var race := RaceRoundController.new()
	race.configure(60.0, 15.0)
	var seats: Array[int] = [0, 1]
	race.begin("c3", seats, {})
	var goal: Array[Dictionary] = [
		{"event_id": "c3:g", "round_id": "c3", "seat_index": 0, "kind": "goal", "physics_tick": 1}
	]
	var step := race.advance_step(60.0, 1, goal)
	var finished := false
	for outcome in step.new_outcomes:
		finished = finished or (int(outcome.seat_index) == 0 and str(outcome.outcome) == "finished")
	check.call(
		finished and str(step.end_reason) == "hard_cap",
		"C3 a finish on the 60 s boundary step counts before the hard-cap failure"
	)


func _c7_command_failure_vs_hazard() -> void:
	check.call(
		KangarooRoundController.hazard_precedes_command(true, 1.0, 1.2),
		"C7 a strictly earlier comparable hazard precedes a command evaluation"
	)
	check.call(
		not KangarooRoundController.hazard_precedes_command(true, 1.2, 1.2),
		"C7 an exact tie resolves as command failure"
	)
	check.call(
		not KangarooRoundController.hazard_precedes_command(false, 0.5, 1.2),
		"C7 an incomparable time resolves as command failure"
	)


func _u5_deadline_vs_twist_terminal() -> void:
	var race := RaceRoundController.new()
	race.configure(0.05, 0.05)
	var seats: Array[int] = [0, 1, 2]
	race.begin("u5", seats, {})
	var forwarded: Array[Dictionary] = [
		{
			"event_id": "u5:timeout",
			"round_id": "u5",
			"seat_index": 1,
			"kind": "elimination",
			"physics_tick": 4,
			"source_item_id": "",
			"direct_owner_seat": -1,
			"cause": "timeout",
		}
	]
	var step := race.advance_step(0.05, 4, forwarded)
	var causes := {}
	for outcome in step.new_outcomes:
		causes[int(outcome.seat_index)] = str(outcome.cause)
	check.call(
		str(causes.get(1, "")) == "timeout" and str(causes.get(0, "")) == "hard_cap",
		"U5 a Twist terminal due on the deadline step commits first and keeps its cause"
	)
	check.call(
		not (RaceScoreCalculator.calculate(seats, race.ledger.outcomes(), {}).get("award_rows", []).any(
			func(row: Dictionary) -> bool: return str(row.key) == "patibong"
		)),
		"U5 a deadline-step Twist elimination earns no Patibong"
	)


func _kangaroo_twist(seat_count: int, twist: bool, seed_value := 5) -> KangarooRoundController:
	var controller := KangarooRoundController.new()
	var seats: Array[int] = []
	for index in seat_count:
		seats.append(index)
	var started := controller.begin("p12:kg", seats, {}, _stream(seed_value), _tuning(), 0.0, {})
	check.call(started, "Kangaroo scaffold begins (%d seats, twist=%s)" % [seat_count, twist])
	controller.twist_role = twist
	return controller


func _freeze_command(command_id: int, end_at: float, violators: Dictionary) -> Dictionary:
	return {
		"command_id": command_id,
		"command": KangarooRoundController.Command.FREEZE,
		"command_name": "FREEZE",
		"is_storm": false,
		"band": -1,
		"wave_y": -1.0,
		"telegraph_start_at": 0.0,
		"response_start_at": 0.0,
		"response_end_at": end_at,
		"reset_seconds": 0.0,
		"status": "RESPONSE",
		"response_started": true,
		"evaluated": false,
		"evaluated_at": -1.0,
		"grace_at": -1.0,
		"grace_checked": false,
		"initial_held_sources": {},
		"freeze_violations": violators,
		"pass_by_seat": {},
		"failure_seats": [],
	}


func _u6_goal_vs_third_failure() -> void:
	var seats: Array[int] = [0, 1, 2]
	var actors := _actors(seats)
	var controller := _kangaroo_twist(3, true)
	controller.marker_counts[1] = 2
	controller.marker_counts[2] = 1
	controller.command_history.append(_freeze_command(99, 0.01, {1: true, 2: true}))
	var step := controller.advance_to(0.02, 7, actors, null, [] as Array[Dictionary])
	var causes := {}
	for outcome in step.new_outcomes:
		causes[int(outcome.seat_index)] = str(outcome.cause)
	check.call(
		str(causes.get(1, "")) == "command_failure" and not causes.has(2),
		"U6 the third failure eliminates (command_failure); a second marker does not"
	)
	var ledger := RaceOutcomeLedger.new()
	ledger.begin("u6", seats, {})
	var batch: Array[Dictionary] = [
		{
			"event_id": "u6:goal",
			"round_id": "u6",
			"seat_index": 1,
			"kind": "goal",
			"physics_tick": 7
		},
		{
			"event_id": "u6:fail",
			"round_id": "u6",
			"seat_index": 1,
			"kind": "elimination",
			"physics_tick": 7,
			"source_item_id": "",
			"direct_owner_seat": -1,
			"cause": "command_failure",
		},
	]
	var resolved := ledger.resolve_step(7, batch)
	check.call(
		(
			resolved.size() == 1
			and str(resolved[0].outcome) == "eliminated"
			and str(resolved[0].cause) == "command_failure"
			and int(resolved[0].direct_owner_seat) == -1
		),
		"U6 same-step goal and third failure: eliminated with the failure cause and no credit"
	)
	_free_actors(actors)


func _u7_commands_with_one_runner() -> void:
	var controller := _kangaroo_twist(3, true, 9)
	controller.secure_seat(0)
	controller.secure_seat(1)
	check.call(
		(
			controller.live_seats.size() == 1
			and controller.live_seats[0] == 2
			and controller.secured_seats.size() == 2
		),
		"U7 finishers leave the live roster without an elimination record"
	)
	var step := controller.advance_to(2.0, 3, {}, null, [] as Array[Dictionary])
	check.call(
		controller.active and not controller.ended and not bool(step.get("ended", false)),
		"U7 the Twist never ends the round when one unfinished runner remains"
	)
	var saw_hug := false
	var saw_command := false
	for command in controller.command_history:
		saw_command = true
		if int(command.command) == KangarooRoundController.Command.HUG:
			saw_hug = true
	check.call(saw_command, "U7 commands continue for the last unfinished runner")
	check.call(not saw_hug, "U7 Hug is never selected with fewer than two unfinished runners")
	var standalone := _kangaroo_twist(2, false, 9)
	standalone.live_seats = [0] as Array[int]
	standalone.advance_to(1.0, 3, {}, null, [] as Array[Dictionary])
	check.call(standalone.ended, "U7 control: a standalone Kangaroo still ends at one survivor")


func _u8_no_storm_as_twist() -> void:
	var controller := _kangaroo_twist(3, true, 13)
	controller.no_elimination_commands = 20
	controller._step_provisional_count = 20
	var step := controller.advance_to(3.0, 5, {}, null, [] as Array[Dictionary])
	check.call(
		not controller.storm_active and step.get("advanced", false),
		"U8 Storm is never active when Kangaroo is a Twist"
	)


func _u9_multi_cause_rank() -> void:
	var seats: Array[int] = [0, 1, 2]
	var actors := _actors(seats)
	var controller := _kangaroo_twist(3, false, 15)
	controller.marker_counts[1] = 2
	var command := {
		"command_id": 1,
		"command": KangarooRoundController.Command.FREEZE,
		"command_name": "FREEZE",
		"is_storm": false,
		"band": -1,
		"wave_y": -1.0,
		"telegraph_start_at": 0.0,
		"response_start_at": 0.0,
		"response_end_at": 0.5,
		"reset_seconds": 0.0,
		"status": "RESPONSE",
		"response_started": true,
		"evaluated": false,
		"evaluated_at": -1.0,
		"grace_at": -1.0,
		"grace_checked": false,
		"initial_held_sources": {},
		"freeze_violations": {1: true},
		"pass_by_seat": {},
		"failure_seats": [],
	}
	controller.command_history.append(command)
	controller.round_id = "p12:kg"
	check.call(
		controller.submit_external_elimination(1, 0.5, "p12:kg:timeout:1:1", "timeout"),
		"U9 the Bomb-Taya timeout is accepted as an external elimination"
	)
	var trap := _hazard(1, 1, 0.5, "trap.u9", 2)
	trap.round_id = "p12:kg"
	controller.submit_hazard(trap)
	var step := controller.advance_to(0.6, 1, actors, null, [] as Array[Dictionary])
	var cause := _cause_for(step.new_outcomes, 1)
	(
		check
		. call(
			cause == "command_failure",
			(
				"U9 command failure, timeout and trap on one recorded time: command failure ranks first (%s)"
				% cause
			)
		)
	)
	var second := _kangaroo_twist(3, false, 15)
	second.round_id = "p12:kg"
	second.submit_external_elimination(2, 0.4, "p12:kg:timeout:2:2", "timeout")
	var later_trap := _hazard(2, 1, 0.4, "trap.u9b", 1)
	later_trap.round_id = "p12:kg"
	second.submit_hazard(later_trap)
	var step_two := second.advance_to(0.6, 1, {}, null, [] as Array[Dictionary])
	check.call(
		_cause_for(step_two.new_outcomes, 2) == "timeout",
		"U9 timeout and trap on one recorded time: the timeout ranks before the trap (no Patibong)"
	)
	var third := _kangaroo_twist(3, false, 15)
	third.round_id = "p12:kg"
	third.submit_external_elimination(0, 0.5, "p12:kg:timeout:0:3", "timeout")
	var earlier_trap := _hazard(0, 1, 0.3, "trap.u9c", 1)
	earlier_trap.round_id = "p12:kg"
	third.submit_hazard(earlier_trap)
	var step_three := third.advance_to(0.6, 1, {}, null, [] as Array[Dictionary])
	check.call(
		_cause_for(step_three.new_outcomes, 0) == "direct_hazard",
		"U9 a strictly earlier trap beats the timeout and keeps its Patibong credit"
	)
	var incomparable := _kangaroo_twist(3, false, 15)
	incomparable.round_id = "p12:kg"
	incomparable.submit_external_elimination(1, 0.5, "p12:kg:timeout:1:4", "timeout")
	var unclear := _hazard(1, 1, 0.1, "trap.u9d", 2, false)
	unclear.round_id = "p12:kg"
	incomparable.submit_hazard(unclear)
	var step_four := incomparable.advance_to(0.6, 1, {}, null, [] as Array[Dictionary])
	check.call(
		_cause_for(step_four.new_outcomes, 1) == "timeout",
		"U9 an incomparable-time trap ranks last: the timeout wins"
	)
	_free_actors(actors)


func _u12_mixed_producers_one_batch() -> void:
	var seats: Array[int] = [0, 1, 2]
	var records: Array[Dictionary] = [
		{"seat_index": 0, "physics_tick": 9, "physics_time": 1.0, "time_comparable": true},
		{"seat_index": 1, "physics_tick": 9, "physics_time": 1.0, "time_comparable": true},
		{"seat_index": 2, "physics_tick": 9, "physics_time": 1.0, "time_comparable": true},
	]
	var survivors: Array[int] = []
	var placement := PlacementScoreResolver.resolve(seats, records, survivors)
	check.call(
		bool(placement.valid) and int(placement.last_cluck_seat) == 0,
		"U12 mixed same-step producers all feed the unchanged resolver: Last Cluck, lowest slot"
	)


func _ledger_signature(shuffled: bool, variant := 0) -> String:
	var ledger := RaceOutcomeLedger.new()
	var seats: Array[int] = [0, 1, 2, 3]
	ledger.begin("perm", seats, {})
	var rows: Array[Dictionary] = [
		{
			"event_id": "perm:g0",
			"round_id": "perm",
			"seat_index": 0,
			"kind": "goal",
			"physics_tick": 4
		},
		{
			"event_id": "perm:g1",
			"round_id": "perm",
			"seat_index": 1,
			"kind": "goal",
			"physics_tick": 4
		},
		{
			"event_id": "perm:e1",
			"round_id": "perm",
			"seat_index": 1,
			"kind": "elimination",
			"physics_tick": 4,
			"source_item_id": "trap.z",
			"direct_owner_seat": 2,
		},
		{
			"event_id": "perm:e2",
			"round_id": "perm",
			"seat_index": 2,
			"kind": "elimination",
			"physics_tick": 4,
			"source_item_id": "",
			"direct_owner_seat": -1,
			"cause": "timeout",
		},
	]
	if shuffled:
		if variant % 2 == 1:
			rows.reverse()
		if variant >= 2:
			var head: Dictionary = rows.pop_front()
			rows.append(head)
	var parts: Array[String] = []
	for outcome in ledger.resolve_step(4, rows):
		parts.append(
			"%d:%s:%s" % [int(outcome.seat_index), str(outcome.outcome), str(outcome.cause)]
		)
	parts.sort()
	return "|".join(parts)


# --- Bomb-Taya Twist rows (K+L and Kg+L) -------------------------------------------------------


func _bomb(seat_count: int, seed_value := 7) -> BombTayaTwist:
	var seats: Array[int] = []
	for index in seat_count:
		seats.append(index)
	var twist := BombTayaTwist.new()
	var started := twist.begin("p12:bomb", seats, _stream(seed_value), 0.001, 1.0, 7.0, 10.0, 15.0)
	check.call(started, "Bomb-Taya scaffold begins (%d seats)" % seat_count)
	twist.advance_step(0.01, 1, seats, [] as Array[int], [] as Array[Dictionary])
	return twist


func _seats_of(seat_count: int) -> Array[int]:
	var seats: Array[int] = []
	for index in seat_count:
		seats.append(index)
	return seats


func _c4_c5_bomb_batch() -> void:
	var twist := _bomb(3)
	var taya := twist.taya_seat
	var other := (taya + 1) % 3
	twist.countdown_remaining = 0.005
	var result := twist.advance_step(
		0.01, 2, _seats_of(3), [] as Array[int], _typed_contacts([_contact(other)])
	)
	check.call(
		int(result.timeout_seat) == taya and not bool(result.tagged),
		"C5 a contact on the expiry step loses to the timeout (no tag transfer)"
	)
	check.call(
		twist.taya_seat != taya and twist.taya_seat >= 0,
		"C6 the timed-out taya is replaced by a live runner in the same batch"
	)


func _u1_bomb_goal_vs_timeout() -> void:
	for seat_count: int in [2, 3, 4]:
		var twist := _bomb(seat_count)
		var taya := twist.taya_seat
		twist.countdown_remaining = 0.005
		var finishing: Array[int] = [taya]
		var result := twist.advance_step(
			0.01, 2, _seats_of(seat_count), [] as Array[int], [] as Array[Dictionary], finishing
		)
		check.call(
			int(result.timeout_seat) == taya,
			(
				"U1 (%d seats) goal and timeout on one step: the taya is eliminated by the timeout"
				% seat_count
			)
		)


func _u2_bomb_goal_vs_pass() -> void:
	for seat_count: int in [3, 4]:
		var twist := _bomb(seat_count)
		var taya := twist.taya_seat
		var target := (taya + 1) % seat_count
		var bystander := (taya + 2) % seat_count
		twist.countdown_remaining = 5.0
		var finishing: Array[int] = [target]
		var result := twist.advance_step(
			0.01,
			2,
			_seats_of(seat_count),
			[] as Array[int],
			_typed_contacts([_contact(target, 10.0), _contact(bystander, 50.0)]),
			finishing
		)
		check.call(
			twist.taya_seat == bystander and bool(result.tagged),
			"U2 (%d seats) a runner finishing this step is never the pass target" % seat_count
		)
	var two := _bomb(2)
	var other := (two.taya_seat + 1) % 2
	two.countdown_remaining = 5.0
	var secured_target: Array[int] = [other]
	var kept := two.advance_step(
		0.01, 2, _seats_of(2), [] as Array[int], _typed_contacts([_contact(other)]), secured_target
	)
	check.call(
		two.taya_seat == (other + 1) % 2 and not bool(kept.tagged),
		"U2 (2 seats) with the only target finishing, the taya keeps the bomb"
	)


func _u3_bomb_finishing_taya_transfer() -> void:
	for seat_count: int in [2, 3, 4]:
		var twist := _bomb(seat_count, 11)
		var taya := twist.taya_seat
		twist.countdown_remaining = 6.0
		var finishing: Array[int] = [taya]
		var result := twist.advance_step(
			0.01, 2, _seats_of(seat_count), [] as Array[int], [] as Array[Dictionary], finishing
		)
		var handed: Dictionary = twist.transfers.back()
		check.call(
			bool(result.taya_changed) and twist.taya_seat != taya and twist.taya_seat >= 0,
			"U3 (%d seats) a finishing taya hands the bomb over in the same step" % seat_count
		)
		check.call(
			(
				str(handed.reason) == "taya_finished"
				and absf(twist.countdown_remaining - (6.0 - 0.01)) < 0.0001
			),
			"U3 (%d seats) the remaining countdown is preserved (no new timer)" % seat_count
		)
	var touching := _bomb(3, 12)
	var touching_taya := touching.taya_seat
	var touched := (touching_taya + 1) % 3
	touching.countdown_remaining = 6.0
	var leaving: Array[int] = [touching_taya]
	var handed_over := touching.advance_step(
		0.01, 2, _seats_of(3), [] as Array[int], _typed_contacts([_contact(touched)]), leaving
	)
	check.call(
		bool(handed_over.taya_changed) and not bool(handed_over.tagged),
		"U3 the finishing taya's own contact is not replayed as a pass by the new taya"
	)
	var one_left := _bomb(2)
	var first: Array[int] = [one_left.taya_seat]
	one_left.advance_step(0.01, 2, _seats_of(2), [] as Array[int], [] as Array[Dictionary], first)
	check.call(
		one_left.active and one_left.taya_seat >= 0,
		"U3 exactly one unfinished runner left: that runner is the taya and the Twist goes on"
	)
	var last: Array[int] = [one_left.taya_seat]
	var live: Array[int] = [one_left.taya_seat]
	one_left.advance_step(0.01, 3, live, first, [] as Array[Dictionary], last)
	check.call(
		not one_left.active, "U3 nobody left to carry it: the Twist idles; Karera ends the round"
	)
	var again_a := _bomb(4, 21)
	var again_b := _bomb(4, 21)
	var fin_a: Array[int] = [again_a.taya_seat]
	var fin_b: Array[int] = [again_b.taya_seat]
	again_a.advance_step(0.01, 2, _seats_of(4), [] as Array[int], [] as Array[Dictionary], fin_a)
	again_b.advance_step(0.01, 2, _seats_of(4), [] as Array[int], [] as Array[Dictionary], fin_b)
	check.call(
		again_a.taya_seat == again_b.taya_seat, "U3 the transfer draw is deterministic per seed"
	)


func _u4_bomb_timer_after_timeout_with_finishers() -> void:
	var twist := _bomb(4, 31)
	var finisher := (twist.taya_seat + 1) % 4
	var finishing: Array[int] = [finisher]
	twist.advance_step(0.01, 2, _seats_of(4), [] as Array[int], [] as Array[Dictionary], finishing)
	var live: Array[int] = []
	for seat in _seats_of(4):
		if seat != finisher:
			live.append(seat)
	twist.countdown_remaining = 0.005
	var gone: Array[int] = [finisher]
	var result := twist.advance_step(0.01, 3, live, gone, [] as Array[Dictionary])
	check.call(
		int(result.timeout_seat) >= 0 and absf(twist.countdown_remaining - 7.0) < 0.0001,
		"U4 one finisher + a timeout leaves two runners: the fresh timer is the two-alive 7 s"
	)
	var plain := _bomb(4, 33)
	plain.countdown_remaining = 0.005
	plain.advance_step(0.01, 2, _seats_of(4), [] as Array[int], [] as Array[Dictionary])
	check.call(
		absf(plain.countdown_remaining - 10.0) < 0.0001,
		"U4 with no finisher four alive, one times out -> three left -> 10 s"
	)


func _u10_bomb_failure_before_pass() -> void:
	var twist := _bomb(4, 51)
	var taya := twist.taya_seat
	var target := (taya + 1) % 4
	var bystander := (taya + 2) % 4
	twist.countdown_remaining = 5.0
	var live: Array[int] = []
	for seat in _seats_of(4):
		if seat != target:
			live.append(seat)
	var result := twist.advance_step(
		0.01,
		2,
		live,
		[] as Array[int],
		_typed_contacts([_contact(target, 1.0), _contact(bystander, 90.0)])
	)
	check.call(
		twist.taya_seat == bystander and bool(result.tagged),
		"U10 a pass target already eliminated this step is removed before pass selection"
	)
	var second := _bomb(4, 52)
	var old_taya := second.taya_seat
	second.countdown_remaining = 5.0
	var alive: Array[int] = []
	for seat in _seats_of(4):
		if seat != old_taya:
			alive.append(seat)
	# The room reads contacts for the live taya only, so an eliminated taya has none this step.
	var replaced := second.advance_step(0.01, 2, alive, [] as Array[int], [] as Array[Dictionary])
	check.call(
		second.taya_seat != old_taya and bool(replaced.taya_changed) and not bool(replaced.tagged),
		"U10 a taya eliminated by a command failure is replaced, never passed to"
	)
	check.call(
		absf(second.countdown_remaining - (10.0 - 0.01)) < 0.0001,
		"U10 the replacement gets the fresh timer for the new live count (3 -> 10 s)"
	)


func _u11_bomb_pass_independent_of_hug() -> void:
	var twist := _bomb(3, 61)
	var taya := twist.taya_seat
	var receiver := (taya + 1) % 3
	twist.countdown_remaining = 5.0
	var result := twist.advance_step(
		0.01, 2, _seats_of(3), [] as Array[int], _typed_contacts([_contact(receiver)])
	)
	check.call(
		bool(result.tagged) and twist.taya_seat == receiver,
		"U11 a tag pass is independent of any Kangaroo Hug response"
	)


func _bomb_permutations() -> void:
	var reference := _bomb_signature(false)
	for variant in 6:
		check.call(
			_bomb_signature(true, variant) == reference,
			(
				"permutation %d of live/contact/finishing order yields the identical Twist outcome"
				% variant
			)
		)
	var ledger_reference := _ledger_signature(false)
	for variant in 4:
		check.call(
			_ledger_signature(true, variant) == ledger_reference,
			"ledger candidate order permutation %d yields identical outcomes" % variant
		)


func _bomb_signature(shuffled: bool, variant := 0) -> String:
	var twist := _bomb(4, 71)
	twist.countdown_remaining = 5.0
	var taya := twist.taya_seat
	var others: Array[int] = []
	for seat in _seats_of(4):
		if seat != taya:
			others.append(seat)
	var live: Array = _seats_of(4)
	var contacts: Array = [_contact(others[2], 40.0), _contact(others[0], 20.0)]
	var finishing: Array = [others[2], others[1]]
	if shuffled:
		if variant % 2 == 1:
			live.reverse()
		if variant % 3 >= 1:
			contacts.reverse()
		if variant >= 3:
			finishing.reverse()
	var result := twist.advance_step(
		0.01,
		2,
		_seat_ints(live),
		[] as Array[int],
		_typed_contacts(contacts),
		_seat_ints(finishing)
	)
	return (
		"taya=%d|tagged=%s|timeout=%d|changed=%s|cd=%.3f"
		% [
			twist.taya_seat,
			str(result.tagged),
			int(result.timeout_seat),
			str(result.taya_changed),
			twist.countdown_remaining
		]
	)

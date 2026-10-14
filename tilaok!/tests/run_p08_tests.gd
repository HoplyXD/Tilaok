extends SceneTree

const TUNING := preload("res://scripts/config/gameplay_tuning.gd")
const STREAMS := preload("res://scripts/diagnostics/seeded_streams.gd")
const CONTROLLER := preload("res://scripts/match/lagsanay_round_controller.gd")
const PLACEMENT := preload("res://scripts/match/placement_score_resolver.gd")
const SCORES := preload("res://scripts/match/lagsanay_score_calculator.gd")
const ATTRIBUTION := preload("res://scripts/items/runtime/attribution_record.gd")

var checks := 0
var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_tuning_and_seed_stream()
	_test_head_start_passing_and_immunity()
	_test_timeout_hazard_and_batch_order()
	_test_placement_and_last_cluck()
	_test_awards_and_commit()
	print("P08_TEST_SUMMARY checks=%d failures=%d" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _test_tuning_and_seed_stream() -> void:
	var tuning := TUNING.new()
	_check(tuning.validate().is_empty(), "P08 provisional timing defaults validate")
	_check(
		tuning.lagsanay_opening_head_start_seconds == 3.0,
		"opening head start defaults to 3 seconds"
	)
	_check(tuning.lagsanay_taya_seconds_2p == 7.0, "2-player timer defaults to 7 seconds")
	_check(tuning.lagsanay_taya_seconds_3p == 10.0, "3-player timer defaults to 10 seconds")
	_check(tuning.lagsanay_taya_seconds_4p == 15.0, "4-player timer defaults to 15 seconds")
	var streams_a := STREAMS.new()
	var streams_b := STREAMS.new()
	streams_a.seed_all(481)
	streams_b.seed_all(481)
	var controller_a := _begin([0, 1, 2, 3], "seed-a", streams_a.taya)
	var controller_b := _begin([0, 1, 2, 3], "seed-b", streams_b.taya)
	_check(
		controller_a.taya_seat == controller_b.taya_seat,
		"taya gameplay stream reproduces its seeded opening selection"
	)
	_check(
		streams_a.taya.randi() == streams_b.taya.randi(),
		"taya stream is independent and reproducible"
	)
	_check(
		streams_a.cosmetic.randi() == streams_b.cosmetic.randi(), "cosmetic stream remains separate"
	)


func _test_head_start_passing_and_immunity() -> void:
	var controller := _begin([0, 1, 2, 3], "pass", _rng(12), 0.5)
	var opening := controller.taya_seat
	var opening_step := controller.advance_step(
		0.25, 1, [{"seat_index": _other(opening, [0, 1, 2, 3]), "distance_squared": 1.0}], {}
	)
	_check(not opening_step.tagged, "opening taya cannot pass during head start")
	_check(
		is_equal_approx(controller.countdown_remaining, 15.0),
		"bomb countdown does not run during head start"
	)
	var end_opening := controller.advance_step(
		0.25, 2, [{"seat_index": _other(opening, [0, 1, 2, 3]), "distance_squared": 1.0}], {}
	)
	_check(
		bool(end_opening.head_start_ended), "head start ends once at its active-simulation boundary"
	)
	_check(not bool(end_opening.tagged), "no transfer is inferred on the opening transition step")
	var candidates: Array[Dictionary] = []
	for seat in [0, 1, 2, 3]:
		if seat != opening:
			candidates.append({"seat_index": seat, "distance_squared": 9.0})
	var pass_result := controller.advance_step(0.1, 3, candidates, {})
	var expected_receiver := _lowest_other(opening, [0, 1, 2, 3])
	_check(bool(pass_result.tagged), "eligible overlap transfers exactly once")
	_check(
		controller.taya_seat == expected_receiver,
		"equal-distance contacts use the lowest stable seat slot"
	)
	_check(is_equal_approx(controller.countdown_remaining, 14.9), "passing preserves the countdown")
	var old_taya := opening
	var others: Array[Dictionary] = [{"seat_index": old_taya, "distance_squared": 1.0}]
	var immunity := controller.advance_step(0.2, 4, others, {})
	_check(
		not bool(immunity.tagged), "previous taya cannot receive the bomb during pass-back immunity"
	)
	var stationary := controller.advance_step(1.0, 5, others, {})
	_check(bool(stationary.tagged), "ongoing stationary overlap can pass after immunity expires")
	_check(
		controller.taya_seat == old_taya,
		"expired immunity permits the previous taya to receive it again"
	)
	_check(
		is_equal_approx(controller.countdown_remaining, 13.7),
		"second pass also preserves remaining time"
	)

	var nearest := _begin([0, 1, 2], "nearest", _rng(7), 0.1)
	var taya := nearest.taya_seat
	nearest.advance_step(0.1, 10, [], {})
	var distance_rows: Array[Dictionary] = []
	for seat in [0, 1, 2]:
		if seat != taya:
			var nearest_seat := _lowest_other(taya, [0, 1, 2])
			distance_rows.append(
				{"seat_index": seat, "distance_squared": 1.0 if seat == nearest_seat else 30.0}
			)
	var nearest_result := nearest.advance_step(0.1, 11, distance_rows, {})
	var expected_nearest := _lowest_other(taya, [0, 1, 2])
	_check(
		bool(nearest_result.tagged),
		"multiple simultaneous contact candidates are considered as a frozen set"
	)
	_check(nearest.taya_seat == expected_nearest, "nearest candidate beats farther contacts")


func _test_timeout_hazard_and_batch_order() -> void:
	var timeout := _begin([0, 1, 2], "timeout", _rng(2), 0.1, 0.2, 0.2, 0.2)
	var taya := timeout.taya_seat
	timeout.advance_step(0.1, 20, [], {})
	var contact: Array[Dictionary] = [
		{"seat_index": _other(taya, [0, 1, 2]), "distance_squared": 0.0}
	]
	var expires := timeout.advance_step(0.2, 21, contact, {})
	_check(
		not bool(expires.tagged), "expiry wins a same-step contact with no recorded contact time"
	)
	_check(
		str(timeout.outcomes_by_seat[taya].cause) == "timeout",
		"taya timer expiry is an elimination event"
	)
	_check(timeout.taya_seat != taya, "a timed-out taya is reassigned only after the batch")
	_check(
		is_equal_approx(timeout.countdown_remaining, 0.2),
		"new taya receives the configured 2-player timer after one elimination"
	)
	var standard_timers := _begin([0, 1, 2], "standard-timers", _rng(27), 0.1)
	standard_timers.advance_step(0.1, 24, [], {})
	standard_timers.countdown_remaining = 0.01
	standard_timers.advance_step(0.02, 25, [], {})
	_check(
		(
			is_equal_approx(standard_timers.countdown_seconds, 7.0)
			and is_equal_approx(standard_timers.countdown_remaining, 7.0)
		),
		"taya reassignment from three to two survivors receives the standard seven-second timer"
	)
	var competing := _begin([0, 1, 2], "competing-source", _rng(28), 0.1, 8.0, 8.0, 8.0)
	competing.advance_step(0.1, 25, [], {})
	var source_z := _hazard("competing-source", 2, 0, 26, 0.15, "z_source")
	var source_a := _hazard("competing-source", 2, 1, 26, 0.15, "a_source")
	_check(competing.submit_hazard(source_z), "first same-time competing hazard record is accepted")
	_check(
		competing.submit_hazard(source_a), "second same-time competing hazard record is accepted"
	)
	competing.advance_step(0.1, 26, [], {})
	_check(
		str(competing.outcomes_by_seat[2].source_item_id) == "a_source",
		"same-time competing sources use stable item-ID attribution order"
	)
	_check(
		int(competing.outcomes_by_seat[2].direct_owner_seat) == 1,
		"selected competing source preserves its recorded owner"
	)

	var earlier := _begin([0, 1], "hazard-before-timeout", _rng(4), 0.1, 0.2, 0.2, 0.2)
	var target := earlier.taya_seat
	earlier.advance_step(0.1, 30, [], {})
	var hazard := _hazard("hazard-before-timeout", target, 1 - target, 31, 0.25, "trumpo")
	_check(
		earlier.submit_hazard(hazard), "current-round direct hazard is accepted by the mode ledger"
	)
	var early_result := earlier.advance_step(0.2, 31, [], {})
	_check(
		str(earlier.outcomes_by_seat[target].cause) == "direct_hazard",
		"a directly attributed hazard strictly before timeout wins"
	)
	_check(not early_result.new_outcomes.is_empty(), "terminal batch emits its accepted event once")

	var exact := _begin([0, 1], "hazard-tie-timeout", _rng(5), 0.1, 0.2, 0.2, 0.2)
	var exact_target := exact.taya_seat
	exact.advance_step(0.1, 40, [], {})
	var tied_hazard := _hazard(
		"hazard-tie-timeout", exact_target, 1 - exact_target, 41, 0.3, "launcher"
	)
	exact.submit_hazard(tied_hazard)
	exact.advance_step(0.2, 41, [], {})
	_check(
		str(exact.outcomes_by_seat[exact_target].cause) == "timeout",
		"timeout wins exact hazard-time ties"
	)
	_check(
		int(exact.outcomes_by_seat[exact_target].direct_owner_seat) == -1,
		"timeout is never a Patibong kill"
	)

	var batch := _begin([0, 1, 2, 3], "batch", _rng(21), 0.1, 8.0, 8.0, 8.0)
	batch.advance_step(0.1, 50, [], {})
	var taya_seat := batch.taya_seat
	for seat in [0, 1, 2, 3]:
		if seat != taya_seat:
			batch.submit_hazard(_hazard("batch", seat, taya_seat, 51, 0.15, "rail_%d" % seat))
	var batch_result := batch.advance_step(
		0.1, 51, [{"seat_index": _other(taya_seat, [0, 1, 2, 3]), "distance_squared": 0.0}], {}
	)
	_check(
		batch.outcomes_by_seat.size() == 3, "several eliminations in one step commit as one batch"
	)
	_check(
		batch.taya_seat == taya_seat,
		"surviving current taya keeps its identity after non-taya deaths"
	)
	_check(
		is_equal_approx(batch.countdown_remaining, 7.9),
		"non-taya death does not reset or extend the surviving taya timer"
	)
	_check(not bool(batch_result.tagged), "same-step eliminated tag candidates are ignored")
	_check(
		not batch.submit_hazard(_hazard("stale-round", 0, 1, 51, 0.16, "stale")),
		"stale-round hazard callback is rejected"
	)


func _test_placement_and_last_cluck() -> void:
	_check(
		PLACEMENT.table_for_players(2) == PackedInt32Array([8, 0]),
		"2-player placement table is 1.0 / 0"
	)
	_check(
		PLACEMENT.table_for_players(3) == PackedInt32Array([8, 4, 0]),
		"3-player placement table is 1.0 / 0.5 / 0"
	)
	_check(
		PLACEMENT.table_for_players(4) == PackedInt32Array([8, 4, 2, 0]),
		"4-player placement table is 1.0 / 0.5 / 0.25 / 0"
	)
	for count in [2, 3, 4]:
		var records: Array[Dictionary] = []
		for seat in count:
			records.append(
				{
					"seat_index": seat,
					"physics_tick": 100,
					"physics_time": 10.0 + float(seat) * 0.01,
					"time_comparable": true
				}
			)
		var resolution := PLACEMENT.resolve(_seat_range(count), records)
		var expected_winner: int = int(count) - 1
		_check(bool(resolution.valid), "%d-player all-eliminated Last Cluck resolves" % count)
		_check(
			int(resolution.last_cluck_seat) == expected_winner,
			"%d-player latest recorded time selects one Last Cluck winner" % count
		)
		_check(
			int(resolution.score_units[expected_winner]) == 8,
			"Last Cluck winner receives exact first-place value"
		)
		_check(
			int(resolution.score_units.values().reduce(func(a, b): return int(a) + int(b), 0)) >= 8,
			"Last Cluck never averages first place away"
		)
	var exact_tie := (
		PLACEMENT
		. resolve(
			[0, 1, 2],
			[
				{"seat_index": 0, "physics_tick": 9, "physics_time": 4.0, "time_comparable": true},
				{"seat_index": 1, "physics_tick": 9, "physics_time": 4.0, "time_comparable": true},
				{"seat_index": 2, "physics_tick": 9, "physics_time": 4.0, "time_comparable": true},
			]
		)
	)
	_check(
		int(exact_tie.last_cluck_seat) == 0,
		"exact Last Cluck time tie uses lowest stable player slot"
	)
	_check(
		int(exact_tie.score_units[1]) == 2 and int(exact_tie.score_units[2]) == 2,
		"exact lower-place tie averages places two and three in eighth units"
	)
	var tick_only := (
		PLACEMENT
		. resolve(
			[0, 1, 2],
			[
				{"seat_index": 2, "physics_tick": 11},
				{"seat_index": 1, "physics_tick": 11},
				{"seat_index": 0, "physics_tick": 11},
			]
		)
	)
	_check(
		int(tick_only.last_cluck_seat) == 0,
		"legacy tick-only callers stay indistinguishable and use slot order"
	)
	var earlier_groups := (
		PLACEMENT
		. resolve(
			[0, 1, 2, 3],
			[
				{"seat_index": 3, "physics_tick": 1},
				{"seat_index": 0, "physics_tick": 2, "physics_time": 2.1, "time_comparable": true},
				{"seat_index": 1, "physics_tick": 2, "physics_time": 2.2, "time_comparable": true},
				{"seat_index": 2, "physics_tick": 2, "physics_time": 2.2, "time_comparable": true},
			]
		)
	)
	_check(
		int(earlier_groups.last_cluck_seat) == 1,
		"a smaller final same-tick group chooses its latest record"
	)
	_check(
		int(earlier_groups.score_units[2]) == 4 and int(earlier_groups.score_units[0]) == 2,
		"same-tick lower placements retain the recorded-time and tie groups"
	)
	_check(int(earlier_groups.score_units[3]) == 0, "earlier elimination group retains last place")
	var forward_order := _last_cluck_callback_order([0, 1, 2])
	var reverse_order := _last_cluck_callback_order([2, 1, 0])
	_check(
		bool(forward_order.duplicate_rejected) and bool(reverse_order.duplicate_rejected),
		"duplicate hazard callbacks are rejected in both callback-order fixtures"
	)
	_check(
		(
			bool(forward_order.ended)
			and bool(reverse_order.ended)
			and forward_order.new_outcome_count == 3
			and reverse_order.new_outcome_count == 3
		),
		"permuted final-batch callbacks commit exactly one terminal row per player"
	)
	_check(
		(
			int(forward_order.result.get("last_cluck_seat", -1)) == 2
			and int(reverse_order.result.get("last_cluck_seat", -1)) == 2
			and (
				forward_order.result.get("placement_units", {})
				== reverse_order.result.get("placement_units", {})
			)
		),
		"Last Cluck winner and placements do not depend on callback arrival order"
	)


func _test_awards_and_commit() -> void:
	var outcomes: Array[Dictionary] = [
		{"seat_index": 0, "cause": "direct_hazard", "direct_owner_seat": 1},
		{"seat_index": 1, "cause": "direct_hazard", "direct_owner_seat": 1},
		{"seat_index": 2, "cause": "timeout", "direct_owner_seat": -1},
	]
	var records: Array[Dictionary] = []
	for seat in range(3):
		records.append(
			{
				"seat_index": seat,
				"physics_tick": seat + 1,
				"physics_time": float(seat),
				"time_comparable": true
			}
		)
	var result := SCORES.calculate([0, 1, 2], records, [], outcomes, {0: 40, 1: 64, 2: 16})
	_check(bool(result.valid), "placement and Lagsanay awards produce one valid result")
	_check(
		int(result.winner_seat) == 2, "latest survivor-order record chooses the Last Cluck winner"
	)
	_check(
		int(result.delta_units[1]) >= 2,
		"direct owner can receive Patibong even when also eliminated"
	)
	_check(
		int(result.delta_units[1]) == 6, "self-kill rejection and non-winning attribution are exact"
	)
	_check(
		int(result.delta_units[2]) == 14,
		"winner receives eight placement units plus six Bawi units at the three-point boundary"
	)
	var below_boundary := SCORES.calculate(
		[0, 1], [{"seat_index": 0, "physics_tick": 1}], [1], [], {0: 48, 1: 25}
	)
	_check(
		int(below_boundary.delta_units[1]) == 8,
		"winner keeps first-place units but Bawi does not round up from a 2.875-point deficit"
	)
	var self_kill_outcomes: Array[Dictionary] = [
		{"seat_index": 0, "cause": "direct_hazard", "direct_owner_seat": 0},
		{"seat_index": 1, "cause": "timeout", "direct_owner_seat": -1}
	]
	var self_result := SCORES.calculate(
		[0, 1],
		[{"seat_index": 0, "physics_tick": 1}, {"seat_index": 1, "physics_tick": 2}],
		[],
		self_kill_outcomes,
		{}
	)
	_check(int(self_result.delta_units[0]) == 0, "self-kill earns no Patibong")
	var controller := _begin([0, 1], "score-once", _rng(1), 0.1, 0.2, 0.2, 0.2)
	controller.advance_step(0.1, 80, [], {})
	controller.advance_step(0.2, 81, [], {})
	if not controller.ended:
		var rest: int = 1 - controller.taya_seat
		controller.submit_hazard(
			_hazard("score-once", rest, controller.taya_seat, 82, 0.31, "trap")
		)
		controller.advance_step(0.1, 82, [], {})
	var committed := controller.score_result()
	_check(
		controller.commit_score_once(committed), "complete Lagsanay award set commits exactly once"
	)
	_check(
		not controller.commit_score_once(committed),
		"duplicate result callback cannot apply the score again"
	)


func _begin(
	seats: Array[int],
	round: String,
	rng: RandomNumberGenerator,
	head_start: float = 0.1,
	timeout_2p: float = 7.0,
	timeout_3p: float = 10.0,
	timeout_4p: float = 15.0
) -> LagsanayRoundController:
	var controller := CONTROLLER.new() as LagsanayRoundController
	_check(
		controller.begin(
			round, seats, {}, rng, head_start, 1.0, timeout_2p, timeout_3p, timeout_4p
		),
		"%d-player Lagsanay round begins" % seats.size()
	)
	return controller


func _last_cluck_callback_order(order: Array[int]) -> Dictionary:
	var controller := _begin([0, 1, 2], "callback-order", _rng(29), 0.1)
	controller.advance_step(0.1, 80, [], {})
	var duplicate_rejected := false
	for index in range(order.size()):
		var seat := order[index]
		var record := _hazard(
			"callback-order", seat, -1, 81, 0.11 + float(seat) * 0.01, "fixture_%d" % seat
		)
		controller.submit_hazard(record)
		if index == 0:
			duplicate_rejected = not controller.submit_hazard(record)
	var step := controller.advance_step(0.1, 81, [], {})
	var result := controller.score_result()
	return {
		"ended": controller.ended,
		"new_outcome_count": step.new_outcomes.size(),
		"duplicate_rejected": duplicate_rejected,
		"result": result,
	}


func _rng(seed_value: int) -> RandomNumberGenerator:
	var result := RandomNumberGenerator.new()
	result.seed = seed_value
	return result


func _hazard(
	round: String, victim: int, owner: int, tick: int, time: float, source: String
) -> AttributionRecord:
	var result := ATTRIBUTION.new() as AttributionRecord
	result.kind = AttributionRecord.Kind.ELIMINATION
	result.player_seat = victim
	result.owner_seat = owner
	result.source_item_id = source
	result.physics_tick = tick
	result.physics_time = time
	result.time_comparable = true
	result.round_id = round
	result.event_id = "%s:%s:%d:%d" % [round, source, tick, victim]
	result.self_kill = victim == owner
	return result


func _seat_range(count: int) -> Array[int]:
	var seats: Array[int] = []
	for seat in count:
		seats.append(seat)
	return seats


func _other(seat: int, seats: Array[int]) -> int:
	for candidate in seats:
		if candidate != seat:
			return candidate
	return -1


func _lowest_other(seat: int, seats: Array[int]) -> int:
	for candidate in seats:
		if candidate != seat:
			return candidate
	return -1


func _check(condition: bool, label: String) -> void:
	checks += 1
	if condition:
		print("PASS ", label)
	else:
		failures += 1
		push_error("FAIL " + label)

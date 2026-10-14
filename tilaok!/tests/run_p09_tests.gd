extends SceneTree

const TUNING := preload("res://scripts/config/gameplay_tuning.gd")
const COORDINATOR := preload("res://scripts/match/match_lifecycle_coordinator.gd")
const LAGSANAY := preload("res://scripts/match/lagsanay_round_controller.gd")

var checks := 0
var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_tuning()
	_test_termination_matrix()
	_test_round_order_and_callbacks()
	_test_sudden_death_contestant_subsets()
	print("P09_TEST_SUMMARY checks=%d failures=%d" % [checks, failures.size()])
	for failure in failures:
		push_error(failure)
	quit(1 if not failures.is_empty() else 0)


func _test_tuning() -> void:
	var tuning := TUNING.new()
	_check(tuning.match_target_score_units == 80, "P09 target defaults to 80 eighth-points")
	_check(tuning.match_round_limit == 12, "P09 round limit defaults to 12")
	_check(tuning.validate().is_empty(), "P09 tuning defaults validate")
	tuning.match_target_score_units = 0
	_check(not tuning.validate().is_empty(), "zero score target is rejected")
	tuning.match_target_score_units = 80
	tuning.match_round_limit = 0
	_check(not tuning.validate().is_empty(), "zero round limit is rejected")


func _test_termination_matrix() -> void:
	var coordinator := _new_match()
	_check(
		(
			_kind(coordinator.finish_round(1, {0: 8, 1: 4}, 80, 12))
			== MatchLifecycleCoordinator.Decision.CONTINUE
		),
		"below-target round 1 continues"
	)
	_check(
		(
			_kind(coordinator.finish_round(2, {0: 79, 1: 78}, 80, 12))
			== MatchLifecycleCoordinator.Decision.CONTINUE
		),
		"round below threshold continues with an unequal leader"
	)
	_check(
		(
			(
				_kind(coordinator.finish_round(3, {0: 80, 1: 72}, 80, 12))
				== MatchLifecycleCoordinator.Decision.WINNER
			)
			and coordinator.winner_seat == 0
		),
		"exact target ends with the unique leader"
	)

	coordinator = _new_match()
	var above := coordinator.finish_round(1, {0: 88, 1: 80, 2: 72}, 80, 12)
	_check(
		_kind(above) == MatchLifecycleCoordinator.Decision.WINNER and int(above.winner_seat) == 0,
		"simultaneous above-target totals rank by exact stored integer"
	)

	coordinator = _new_match()
	var exact_tie := coordinator.finish_round(1, {0: 80, 1: 80}, 80, 12)
	_check(
		(
			_kind(exact_tie) == MatchLifecycleCoordinator.Decision.SUDDEN_DEATH
			and exact_tie.tied_seats == [0, 1]
		),
		"equal leaders at exact target enter sudden death"
	)

	coordinator = _new_match()
	var lower_tie := coordinator.finish_round(1, {0: 81, 1: 60, 2: 60}, 80, 12)
	_check(
		(
			_kind(lower_tie) == MatchLifecycleCoordinator.Decision.WINNER
			and int(lower_tie.winner_seat) == 0
		),
		"a tie below the leader does not trigger sudden death"
	)

	coordinator = _new_match()
	for round_number in range(1, 11):
		var result := coordinator.finish_round(round_number, {0: round_number, 1: 0}, 80, 12)
		_check(
			_kind(result) == MatchLifecycleCoordinator.Decision.CONTINUE,
			"round %d below the target continues" % round_number
		)
	_check(
		(
			_kind(coordinator.finish_round(11, {0: 11, 1: 0}, 80, 12))
			== MatchLifecycleCoordinator.Decision.CONTINUE
		),
		"round 11 remains nonterminal below target"
	)
	var round_twelve := coordinator.finish_round(12, {0: 0, 1: 0, 2: 0, 3: 0}, 80, 12)
	_check(
		(
			_kind(round_twelve) == MatchLifecycleCoordinator.Decision.SUDDEN_DEATH
			and round_twelve.tied_seats == [0, 1, 2, 3]
		),
		"round 12 with all four tied enters sudden death and admits no round 13"
	)

	coordinator = _new_match()
	_advance_to_round(coordinator, 12)
	var threshold_and_limit := coordinator.finish_round(12, {0: 80, 1: 80, 2: 5}, 80, 12)
	_check(
		(
			_kind(threshold_and_limit) == MatchLifecycleCoordinator.Decision.SUDDEN_DEATH
			and str(threshold_and_limit.reason) == "score_target"
		),
		"threshold plus round limit preserves tied top leaders and target reason"
	)

	coordinator = _new_match()
	_advance_to_round(coordinator, 12)
	var subset := coordinator.finish_round(12, {0: 30, 1: 80, 2: 10, 3: 80}, 80, 12)
	_check(
		(
			_kind(subset) == MatchLifecycleCoordinator.Decision.SUDDEN_DEATH
			and subset.tied_seats == [1, 3]
		),
		"noncontiguous tied leader slots enter; spectators stay outside the subset"
	)


func _test_round_order_and_callbacks() -> void:
	var coordinator := _new_match()
	var reordered := coordinator.finish_round(2, {0: 4, 1: 3}, 80, 12)
	_check(
		(
			_kind(reordered) == MatchLifecycleCoordinator.Decision.INVALID
			and coordinator.completed_round == 0
		),
		"round 2 callback cannot skip the active round 1 decision"
	)
	var first := coordinator.finish_round(1, {0: 80, 1: 80}, 80, 12)
	_check(
		_kind(first) == MatchLifecycleCoordinator.Decision.SUDDEN_DEATH,
		"first terminal decision records one sudden-death attempt"
	)
	_check(
		(
			_kind(coordinator.finish_round(1, {0: 80, 1: 80}, 80, 12))
			== MatchLifecycleCoordinator.Decision.INVALID
		),
		"duplicate round callback is rejected"
	)
	_check(
		not coordinator.resolve_sudden_death(99, 1, 1, 0),
		"callback from a different match is rejected"
	)
	_check(
		not coordinator.resolve_sudden_death(coordinator.match_id, 2, 1, 0),
		"callback from a different round is rejected"
	)
	_check(
		not coordinator.resolve_sudden_death(coordinator.match_id, 1, 2, 0),
		"callback from a different attempt is rejected"
	)
	_check(
		coordinator.resolve_sudden_death(coordinator.match_id, 1, 1, 1),
		"current tied contestant callback resolves one winner"
	)
	_check(
		not coordinator.resolve_sudden_death(coordinator.match_id, 1, 1, 0),
		"duplicate terminal callback cannot replace the winner"
	)
	_check(coordinator.winner_seat == 1, "one stable winner is retained")
	_check(coordinator.retry_sudden_death() == -1, "resolved sudden death cannot retry")


func _test_sudden_death_contestant_subsets() -> void:
	for count in [2, 3, 4]:
		var seats: Array[int] = []
		if count == 2:
			seats = [1, 3]
		elif count == 3:
			seats = [0, 2, 3]
		else:
			for index in range(count):
				seats.append(index)
		var controller := LAGSANAY.new()
		var rng := RandomNumberGenerator.new()
		rng.seed = 401 + count
		_check(
			controller.begin(
				"p09-live-%d" % count,
				seats,
				{0: 0, 1: 0, 2: 0, 3: 0},
				rng,
				0.001,
				0.0,
				0.01,
				0.01,
				0.01
			),
			"%d-seat subset initializes with original stable slots" % count
		)
		_check(controller.seat_indices == seats, "%d-seat tiebreak preserves seat identity" % count)
		var opening_taya := controller.taya_seat
		controller.advance_step(0.002, 1, [], {})
		var spectator := -1
		for candidate in PlayerSeatRegistry.MAX_SEATS:
			if not seats.has(candidate):
				spectator = candidate
				break
		var before_taya := controller.taya_seat
		if spectator >= 0:
			var spectator_contact := controller.advance_step(
				0.001, 2, [{"seat_index": spectator, "distance_squared": 0.0}], {}
			)
			_check(
				not bool(spectator_contact.tagged) and controller.taya_seat == before_taya,
				"spectator seat %d cannot become taya in a %d-seat subset" % [spectator, count]
			)
		else:
			controller.advance_step(0.001, 2, [], {})
		var tick := 3
		while not controller.ended and tick < 10:
			controller.advance_step(0.02, tick, [], {})
			tick += 1
		var winner := controller.sudden_death_winner()
		_check(
			controller.ended and bool(winner.get("valid", false)),
			"real controller timeout physics reaches one %d-player survivor" % count
		)
		_check(
			seats.has(int(winner.get("winner_seat", -1))),
			"%d-player authoritative winner stays inside tied roster" % count
		)
		_check(
			controller.outcomes().size() == count - 1,
			"%d-player survivor ending eliminates exactly the other contestants" % count
		)
		_check(
			opening_taya in seats, "%d-player opening taya remains an original contestant" % count
		)


func _new_match() -> MatchLifecycleCoordinator:
	var coordinator := COORDINATOR.new()
	coordinator.begin(7)
	return coordinator


func _advance_to_round(coordinator: MatchLifecycleCoordinator, next_round: int) -> void:
	for round_number in range(1, next_round):
		var result := coordinator.finish_round(round_number, {0: 0, 1: 0}, 80, 12)
		_check(
			_kind(result) == MatchLifecycleCoordinator.Decision.CONTINUE,
			"fixture round %d advances to %d" % [round_number, next_round]
		)


func _kind(decision: Dictionary) -> int:
	return int(decision.get("kind", MatchLifecycleCoordinator.Decision.INVALID))


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)

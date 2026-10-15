extends SceneTree

const MATCH_SCENE := preload("res://scenes/match/match_room.tscn")
const FIXTURE := preload("res://tests/p06_fixtures.gd")
const QUEUE_SCRIPT := preload("res://scripts/match/race_candidate_queue.gd")

var checks := 0
var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_tuning_and_formatting()
	_test_deadlines_and_ordering()
	_test_candidate_queue()
	_test_ledger_permutations_and_attribution()
	_test_race_scoring_matrix()
	_test_placement_tables_and_last_cluck()
	await _test_real_goal_and_next_round()
	print("P06_TEST_SUMMARY checks=%d failures=%d" % [checks, failures])
	await process_frame
	await process_frame
	quit(1 if failures > 0 else 0)


func _test_tuning_and_formatting() -> void:
	var tuning := GameplayTuning.new()
	_check(tuning.validate().is_empty(), "P06 deadline defaults validate")
	_check(
		tuning.match_race_hard_cap_seconds == 60.0, "race hard cap defaults to 60 active seconds"
	)
	_check(
		tuning.match_race_after_first_finish_seconds == 15.0,
		"finish grace defaults to 15 active seconds"
	)
	tuning.match_race_hard_cap_seconds = 0.0
	_check(not tuning.validate().is_empty(), "zero race hard cap is rejected by tuning validation")
	_check(ScoreFormat.format_units(0) == "0", "zero eighth-units format exactly")
	_check(ScoreFormat.format_units(1) == "0.125", "one eighth-unit formats without rounding")
	_check(ScoreFormat.format_units(3) == "0.375", "three eighth-units format exactly")
	_check(ScoreFormat.format_units(11) == "1.375", "whole and fractional score format exactly")
	_check(ScoreFormat.format_units(-1) == "-0.125", "negative values format symmetrically")
	_check(
		ScoreFormat.format_units(80) == "10", "the 10-point threshold formats exactly from 80 units"
	)


func _test_deadlines_and_ordering() -> void:
	var controller := RaceRoundController.new()
	controller.configure(2.0, 1.0)
	controller.begin("hard-cap", [0, 1, 2], {})
	var result := controller.advance_step(2.0, 20, [])
	_check(result.ended and result.end_reason == "hard_cap", "no-finish round ends at the hard cap")
	_check(controller.ledger.outcomes().size() == 3, "hard cap fails every remaining runner once")
	_check(
		controller.ledger.outcomes()[0].cause == "hard_cap",
		"hard-cap failure is explained in the ledger"
	)

	controller.configure(9.0, 1.0)
	controller.begin("boundary-finish", [0, 1], {})
	result = controller.advance_step(0.5, 1, [FIXTURE.goal("boundary-finish", 0, 1)])
	_check(
		not result.ended and controller.first_finish_deadline == 1.5,
		"first finish starts one fixed 1-second window"
	)
	result = controller.advance_step(1.0, 2, [FIXTURE.goal("boundary-finish", 1, 2)])
	_check(
		result.end_reason == "all_terminal",
		"finish collected on deadline boundary counts before failure"
	)
	_check(
		controller.ledger.outcomes_by_seat[1].outcome == "finished",
		"boundary finisher stays secured"
	)

	controller.configure(9.0, 1.0)
	controller.begin("fixed-window", [0, 1, 2], {})
	controller.advance_step(0.25, 1, [FIXTURE.goal("fixed-window", 0, 1)])
	controller.advance_step(0.5, 2, [FIXTURE.goal("fixed-window", 1, 2)])
	_check(
		controller.first_finish_deadline == 1.25,
		"later finishes do not extend the post-finish deadline"
	)
	result = controller.advance_step(0.5, 3, [])
	_check(
		result.end_reason == "post_finish_deadline",
		"unfinished runners fail at the fixed post-finish deadline"
	)
	_check(
		controller.ledger.outcomes_by_seat[2].cause == "post_finish_deadline",
		"post-finish failure is recorded once"
	)

	controller.configure(1.0, 1.0)
	controller.begin("coincident", [0, 1, 2], {})
	controller.advance_step(1.0, 1, [FIXTURE.goal("coincident", 0, 1)])
	result = controller.advance_step(1.0, 2, [])
	_check(result.end_reason == "hard_cap", "hard cap wins when both deadlines coincide")

	controller.configure(9.0, 9.0)
	controller.begin("goal-death-tie", [0, 1], {})
	var same_step: Array[Dictionary] = [
		FIXTURE.goal("goal-death-tie", 0, 7),
		FIXTURE.elimination("goal-death-tie", 0, 7),
		FIXTURE.goal("goal-death-tie", 1, 7),
	]
	result = controller.advance_step(0.01, 7, same_step)
	_check(
		controller.ledger.outcomes_by_seat[0].outcome == "eliminated",
		"same-step goal and elimination resolves as elimination"
	)
	_check(
		controller.ledger.outcomes_by_seat[1].outcome == "finished",
		"a same-step valid finish is recorded"
	)
	_check(
		result.end_reason == "all_terminal",
		"all terminal actors end the race before deadline failure"
	)


func _test_candidate_queue() -> void:
	var queue := QUEUE_SCRIPT.new()
	queue.begin("queue-round")
	var actor := ChickenController.new()
	actor.seat_index = 1
	actor.lifecycle.status = PlayerLifecycleState.Status.CAPTURED
	_check(not queue.queue_goal(actor, 4), "captured chicken cannot finish while inside the goal")
	actor.lifecycle.status = PlayerLifecycleState.Status.ACTIVE
	_check(
		queue.queue_goal(actor, 5), "released active chicken can finish while overlapping the goal"
	)
	_check(queue.queue_goal(actor, 5), "repeated goal overlap is an idempotent queue request")
	var goals := queue.drain()
	_check(
		goals.size() == 1 and goals[0].kind == "goal",
		"goal overlap polling deduplicates one seat-step event"
	)
	_check(queue.queue_elimination(0, 6, "trap-1", 1), "hazard fixture queues a direct elimination")
	var hazards := queue.drain()
	_check(
		hazards.size() == 1 and hazards[0].source_item_id == "trap-1",
		"candidate queue preserves stable source identity and direct owner"
	)
	queue.reset()
	_check(not queue.queue_goal(actor, 7), "next-round queue reset rejects stale callbacks")
	actor.free()


func _test_ledger_permutations_and_attribution() -> void:
	var first := RaceOutcomeLedger.new()
	var second := RaceOutcomeLedger.new()
	_check(
		not RaceOutcomeLedger.new().begin("duplicate-seats", [0, 0], {0: 0}),
		"ledger rejects duplicate seat identities"
	)
	first.begin("permutation", [0, 1, 2], {0: 8, 1: 2, 2: 0})
	second.begin("permutation", [0, 1, 2], {0: 8, 1: 2, 2: 0})
	var candidates: Array[Dictionary] = [
		FIXTURE.elimination("permutation", 1, 4, "trap-z", 0, "z-hit"),
		FIXTURE.elimination("permutation", 1, 4, "trap-a", 2, "a-hit"),
		FIXTURE.goal("permutation", 1, 4),
	]
	first.resolve_step(4, candidates)
	candidates.reverse()
	second.resolve_step(4, candidates)
	var first_result: Dictionary = first.outcomes_by_seat[1]
	var second_result: Dictionary = second.outcomes_by_seat[1]
	_check(
		first_result == second_result,
		"candidate callback permutations produce the same terminal record"
	)
	_check(first_result.outcome == "eliminated", "same-step elimination beats a goal")
	_check(
		first_result.source_item_id == "trap-a",
		"same-step direct hazards use stable item ID ordering"
	)
	_check(
		first_result.direct_owner_seat == 2, "direct owner comes from the stable selected hazard"
	)
	_check(
		first.resolve_step(4, candidates).is_empty(),
		"a resolved physics-step batch cannot resolve twice"
	)
	_check(
		first.resolve_step(5, [FIXTURE.goal("permutation", 1, 5)]).is_empty(),
		"later callbacks cannot replace a terminal outcome"
	)
	_check(
		first.resolve_step(6, [FIXTURE.goal("stale-round", 0, 6)]).is_empty(),
		"stale round identities are discarded"
	)

	var ambiguous := RaceOutcomeLedger.new()
	ambiguous.begin("ambiguous", [0, 1, 2], {})
	var ambiguous_candidates: Array[Dictionary] = [
		FIXTURE.elimination("ambiguous", 1, 8, "trap-a", 0),
		FIXTURE.elimination("ambiguous", 1, 8),
	]
	ambiguous.resolve_step(8, ambiguous_candidates)
	_check(
		ambiguous.outcomes_by_seat[1].direct_owner_seat == -1,
		"a tied non-hazard elimination removes ambiguous Patibong credit"
	)

	var self_hit := RaceOutcomeLedger.new()
	self_hit.begin("self", [0, 1], {})
	var self_candidates: Array[Dictionary] = [FIXTURE.elimination("self", 0, 9, "trap-self", 0)]
	self_hit.resolve_step(9, self_candidates)
	_check(
		self_hit.outcomes_by_seat[0].direct_owner_seat == -1,
		"self-elimination has no direct owner credit"
	)
	var score_fixture := {"valid": true, "delta_units": {0: 0, 1: 0}, "totals_units": {0: 0, 1: 0}}
	_check(self_hit.commit_score_once("self", score_fixture), "first score commit succeeds")
	_check(
		not self_hit.commit_score_once("self", score_fixture), "duplicate score commit is rejected"
	)
	_check(
		not self_hit.commit_score_once("old-round", score_fixture), "stale score commit is rejected"
	)


func _test_race_scoring_matrix() -> void:
	_check(
		not RaceScoreCalculator.calculate([0, 0], [], {}).valid,
		"race scorer rejects duplicate seat identities"
	)
	var result := RaceScoreCalculator.calculate(
		[0, 1],
		[FIXTURE.terminal(0, "finished", 10), FIXTURE.terminal(1, "finished", 10)],
		{0: 0, 1: 0},
		[1]
	)
	_check(
		result.valid and result.delta_units[0] == 0 and result.delta_units[1] == 0,
		"2-player all-finish round awards zero to both players, including the coin carrier"
	)
	_check(result.award_rows.is_empty(), "2-player all-finish round has no award rows")
	_check(
		result.first_finish_seats == [0, 1], "exact earliest-finish ties are retained as a group"
	)

	result = RaceScoreCalculator.calculate(
		[0, 1, 2],
		[
			FIXTURE.terminal(0, "finished", 1),
			FIXTURE.terminal(1, "finished", 2),
			FIXTURE.terminal(2, "finished", 3)
		],
		{0: 0, 1: 0, 2: 0},
		[2]
	)
	_check(
		result.delta_units[0] == 0 and result.delta_units[2] == 0,
		"3-player all-finish round suppresses Barya too"
	)
	_check(result.award_rows.is_empty(), "all-finish result has no coin award row")
	result = (
		RaceScoreCalculator
		. calculate(
			[0, 1, 2, 3],
			[
				FIXTURE.terminal(0, "finished", 1),
				FIXTURE.terminal(1, "finished", 2),
				FIXTURE.terminal(2, "finished", 3),
				FIXTURE.terminal(3, "finished", 4),
			],
			{0: 8, 1: 16, 2: 24, 3: 32},
			[3]
		)
	)
	_check(
		(
			result.delta_units[0] == 0
			and result.delta_units[1] == 0
			and result.delta_units[2] == 0
			and result.delta_units[3] == 0
			and result.totals_units == {0: 8, 1: 16, 2: 24, 3: 32}
			and result.award_rows.is_empty()
		),
		"4-player all-finish round leaves every previous total unchanged"
	)
	result = (
		RaceScoreCalculator
		. calculate(
			[0, 1, 2],
			[
				FIXTURE.terminal(0, "finished", 1),
				FIXTURE.terminal(1, "finished", 2),
				FIXTURE.terminal(2, "eliminated", 3),
			],
			{0: 0, 1: 0, 2: 0},
			[1]
		)
	)
	_check(
		result.delta_units[0] == 10 and result.delta_units[1] == 12,
		"Barya still pays its finisher when some but not all players finish"
	)

	result = RaceScoreCalculator.calculate(
		[0, 1, 2],
		[
			FIXTURE.terminal(0, "eliminated", 1, 0),
			FIXTURE.terminal(1, "eliminated", 2, 0),
			FIXTURE.terminal(2, "eliminated", 3)
		],
		{0: 80, 1: 0, 2: 0},
		[0]
	)
	_check(
		result.delta_units[0] == 0 and result.award_rows.is_empty(),
		"no-finisher round gives no Patibong or Barya"
	)

	result = RaceScoreCalculator.calculate(
		[0, 1, 2],
		[
			FIXTURE.terminal(0, "finished", 3),
			FIXTURE.terminal(1, "eliminated", 4),
			FIXTURE.terminal(2, "eliminated", 5, 1)
		],
		{0: 80, 1: 56, 2: 57}
	)
	_check(result.delta_units[0] == 14, "sole finisher earns Tapos, Una and Bayani")
	_check(result.delta_units[1] == 2, "dead trap owner earns Patibong when someone finishes")
	_check(result.delta_units[2] == 0, "non-finisher earns no race objective points")
	_check(result.totals_units[0] == 94, "round commit adds exact delta to starting total")
	_check(
		ScoreFormat.format_units(int(result.totals_units[0])) == "11.75",
		"cumulative totals preserve exact eighth-unit increments"
	)

	result = RaceScoreCalculator.calculate(
		[0, 1, 2, 3],
		[
			FIXTURE.terminal(0, "finished", 1),
			FIXTURE.terminal(1, "finished", 1),
			FIXTURE.terminal(2, "eliminated", 2, 2),
			FIXTURE.terminal(3, "eliminated", 3, 2)
		],
		{0: 80, 1: 56, 2: 0, 3: 0}
	)
	_check(
		result.delta_units[0] == 10 and result.delta_units[1] == 16,
		"tied first finishers share Una and the underdog finisher also earns Bawi"
	)
	_check(
		result.delta_units[2] == 2 and result.delta_units[3] == 0,
		"direct Patibong counts opponents killed and excludes a self-kill"
	)
	var bawi_explained := false
	for award in result.award_rows:
		if award.key == "bawi" and int(award.seat_index) == 1:
			bawi_explained = true
	_check(bawi_explained, "award rows explain Bawi for the round-start underdog finisher")

	result = RaceScoreCalculator.calculate(
		[0, 1],
		[FIXTURE.terminal(0, "finished", 1), FIXTURE.terminal(1, "eliminated", 2, 0)],
		{0: 80, 1: 56}
	)
	_check(
		result.delta_units[0] == 16,
		"two-player sole finisher earns ordinary awards and a direct kill"
	)
	_check(result.delta_units[1] == 0, "a direct-killed victim receives no trap credit")
	var bawi := RaceScoreCalculator.calculate(
		[0, 1, 2],
		[
			FIXTURE.terminal(0, "eliminated", 1),
			FIXTURE.terminal(1, "finished", 2),
			FIXTURE.terminal(2, "eliminated", 3)
		],
		{0: 80, 1: 56, 2: 57}
	)
	_check(
		bawi.delta_units[1] == 20,
		"sole underdog finisher gets Bawi from the immutable round-start 3-point gap"
	)
	var threshold_case := RaceScoreCalculator.calculate(
		[0, 1],
		[FIXTURE.terminal(0, "finished", 1), FIXTURE.terminal(1, "eliminated", 2)],
		{0: 66, 1: 0}
	)
	_check(
		threshold_case.totals_units[0] == 80, "score delta lands exactly on the 10-point threshold"
	)
	_check(
		ScoreFormat.format_units(int(threshold_case.totals_units[0])) == "10",
		"threshold display agrees with stored units"
	)
	var bawi_boundary := RaceScoreCalculator.calculate(
		[0, 1, 2],
		[
			FIXTURE.terminal(0, "eliminated", 1),
			FIXTURE.terminal(1, "finished", 2),
			FIXTURE.terminal(2, "finished", 3)
		],
		{0: 80, 1: 56, 2: 57}
	)
	_check(bawi_boundary.delta_units[1] == 16, "24-unit round-start gap earns Bawi")
	_check(bawi_boundary.delta_units[2] == 8, "23-unit round-start gap does not earn Bawi")
	_check(
		result.delta_units[0] == 16,
		"self-kill fixture does not remove the unrelated finisher awards"
	)


func _test_placement_tables_and_last_cluck() -> void:
	_check(
		PlacementScoreResolver.table_for_players(2) == PackedInt32Array([8, 0]),
		"2-seat placement table is exact"
	)
	_check(
		PlacementScoreResolver.table_for_players(3) == PackedInt32Array([8, 4, 0]),
		"3-seat placement table is exact"
	)
	_check(
		PlacementScoreResolver.table_for_players(4) == PackedInt32Array([8, 4, 2, 0]),
		"4-seat placement table is exact"
	)
	var survival_order: Array[Dictionary] = [
		{"seat_index": 0, "physics_tick": 1},
		{"seat_index": 1, "physics_tick": 2},
		{"seat_index": 2, "physics_tick": 3},
	]
	var four_player_result := PlacementScoreResolver.resolve([0, 1, 2, 3], survival_order, [3])
	_check(
		(
			four_player_result.valid
			and four_player_result.score_units[0] == 0
			and four_player_result.score_units[1] == 2
			and four_player_result.score_units[2] == 4
			and four_player_result.score_units[3] == 8
		),
		"four-player elimination order awards fourth to first death and first to survivor"
	)
	var owned_trap: Array[Dictionary] = [
		{"cause": "direct_hazard", "seat_index": 1, "direct_owner_seat": 0}
	]
	var lagsanay_result := LagsanayScoreCalculator.calculate(
		[0, 1, 2, 3], survival_order, [3], owned_trap, {}
	)
	var kangaroo_result := KangarooScoreCalculator.calculate(
		[0, 1, 2, 3], survival_order, [3], owned_trap, {}
	)
	_check(
		(
			lagsanay_result.valid
			and kangaroo_result.valid
			and lagsanay_result.placement_units[0] == 0
			and kangaroo_result.placement_units[0] == 0
			and lagsanay_result.delta_units[0] == 2
			and kangaroo_result.delta_units[0] == 2
		),
		"fourth place earns zero placement in both modes while direct Patibong still counts"
	)
	_check(
		PlacementScoreResolver.tied_group_units(4, 3, 2) == 1,
		"4-player places 3–4 average to 1/8 point"
	)
	_check(
		PlacementScoreResolver.tied_group_units(4, 2, 2) == 3,
		"4-player places 2–3 average to 3/8 point"
	)
	_check(
		PlacementScoreResolver.tied_group_units(4, 2, 3) == 2,
		"4-player places 2–4 average to 1/4 point"
	)
	_check(
		PlacementScoreResolver.tied_group_units(3, 2, 2) == 2,
		"3-player places 2–3 average to 1/4 point"
	)
	_check(
		PlacementScoreResolver.tied_group_units(4, 1, 2) == 6,
		"exact tie helper retains the mathematical 1–2 average for non-Last-Cluck cases"
	)

	var last_cluck := PlacementScoreResolver.resolve(
		[0, 1, 2, 3],
		[
			{"seat_index": 0, "physics_tick": 4},
			{"seat_index": 1, "physics_tick": 3},
			{"seat_index": 2, "physics_tick": 3},
			{"seat_index": 3, "physics_tick": 2}
		],
		[]
	)
	_check(
		last_cluck.valid and last_cluck.last_cluck_seat == 0, "latest elimination wins Last Cluck"
	)
	_check(
		last_cluck.score_units[0] == 8,
		"Last Cluck winner receives first-place points without averaging"
	)
	_check(
		last_cluck.score_units[1] == 3 and last_cluck.score_units[2] == 3,
		"exact tied lower eliminations receive their current-table average"
	)
	_check(last_cluck.score_units[3] == 0, "earliest elimination receives last place")
	var tied_latest := PlacementScoreResolver.resolve(
		[0, 1, 2, 3],
		[
			{"seat_index": 0, "physics_tick": 4},
			{"seat_index": 1, "physics_tick": 6},
			{"seat_index": 2, "physics_tick": 6},
			{"seat_index": 3, "physics_tick": 2}
		],
		[]
	)
	_check(
		tied_latest.last_cluck_seat == 1 and tied_latest.score_units[1] == 8,
		"exact latest-elimination tie selects lowest seat slot"
	)
	_check(
		tied_latest.score_units[2] == 4,
		"other latest-tick player receives the next lower placement"
	)
	var survivor := PlacementScoreResolver.resolve(
		[0, 1, 2], [{"seat_index": 0, "physics_tick": 1}, {"seat_index": 1, "physics_tick": 2}], [2]
	)
	_check(survivor.score_units[2] == 8, "sole survivor receives first-place points")
	_check(
		survivor.score_units[1] == 4 and survivor.score_units[0] == 0,
		"losers are ranked by recorded elimination order"
	)
	_check(
		ScoreFormat.format_units(last_cluck.score_units[1]) == "0.375",
		"placement results use the shared exact score formatter"
	)


func _test_real_goal_and_next_round() -> void:
	var room := MATCH_SCENE.instantiate() as P05MatchRoom
	root.add_child(room)
	for _frame in range(3):
		await physics_frame
	room.join_keyboard("K1")
	room.join_keyboard("K2")
	room.input_router.registry.set_ready(0, true)
	room.input_router.registry.set_ready(1, true)
	_check(room.start_match(), "real-goal integration fixture starts a two-seat match")
	room.assignments = {0: str(room.egg_pool[0].egg_id), 1: str(room.egg_pool[1].egg_id)}
	room._enter_place()
	var build_piece := room.items.place("build.hollow_blocks.cell_1x1", Vector2i(8, 8), 0, 0)
	_check(build_piece.allowed, "live-flow fixture retains one real construction piece")
	room._enter_play()
	_check(
		room.goal_area != null and room.goal_area.monitoring,
		"P03 builds the arena-defined goal as a live physics trigger"
	)
	var goal_position := room.goal_area.global_position
	var captured_actor := room.actors[0] as ChickenController
	captured_actor.set_captured(true, "bubble_fixture")
	captured_actor.global_position = goal_position
	(room.actors[1] as ChickenController).global_position = goal_position
	for _frame in range(2):
		await physics_frame
	_check(
		room.phase_controller.phase == MatchPhaseController.Phase.PLAY,
		"captured overlap does not finish before release"
	)
	_check(
		captured_actor.lifecycle.status == PlayerLifecycleState.Status.CAPTURED,
		"captured chicken remains captive inside the goal trigger"
	)
	captured_actor.set_captured(false)
	for _frame in range(4):
		await physics_frame
	_check(
		room.phase_controller.phase == MatchPhaseController.Phase.RESULTS,
		"actual goal overlap finishes the released chicken and the active finisher"
	)
	_check(room.items.round_number == 1, "live race cleanup increments the round exactly once")
	_check(
		room.last_results_model.award_rows.is_empty(), "live all-finish result has no award rows"
	)
	_check(
		room.last_results_model.suppression_reason.contains("Everyone reached the goal"),
		"live result explains the two-player all-finish zero"
	)
	_check(
		room.cumulative_score_units[0] + room.cumulative_score_units[1] == 0,
		"live all-finish outcome commits zero cumulative delta"
	)
	_check(
		(
			(room.actors[0] as ChickenController).lifecycle.status
			== PlayerLifecycleState.Status.SECURED
		),
		"finisher is secured after goal resolution"
	)
	var signature := room.items.construction_signature()
	room._on_match_action_pressed(0, "confirm")
	room._on_match_action_pressed(1, "confirm")
	_check(
		room.phase_controller.phase == MatchPhaseController.Phase.PUGAD,
		"all-ready live results advance through the existing P05 gate"
	)
	_check(
		not signature.is_empty() and room.items.construction_signature() == signature,
		"construction persists after the scored round"
	)
	_check(
		(
			(room.actors[0] as ChickenController).lifecycle.status
			== PlayerLifecycleState.Status.ACTIVE
		),
		"next-round start resets finisher lifecycle"
	)
	_check(
		room.cumulative_score_units[0] + room.cumulative_score_units[1] == 0,
		"next-round actor reset preserves cumulative scores"
	)
	room.queue_free()
	await process_frame


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("P06 FAIL: " + message)

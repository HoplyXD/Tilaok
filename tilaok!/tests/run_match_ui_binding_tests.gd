extends SceneTree

## Live Round result binding: every number, award, reason and row on UiRoundResultScreen equals the
## MatchResultsViewModel built from the P06 calculator, for 2, 3 and 4 players (including eighth-
## point totals, suppressed rounds, the 2-player waiver and the worst-case ten award rows).

const RESULT_SCENE := preload("res://scenes/ui/screens/round_result_screen.tscn")
const PAD_IDS := [710, 711]

var checks := 0
var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_result_bindings()
	print("MATCH_UI_BINDING_TESTS checks=%d failures=%d" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _test_result_bindings() -> void:
	var cases := [
		{
			"name": "2 players, tied Una, waiver",
			"seats": 2,
			"start": {0: 0, 1: 0},
			"outcomes":
			[P06Fixtures.terminal(0, "finished", 10), P06Fixtures.terminal(1, "finished", 10)],
			"reason": "all_terminal",
		},
		{
			"name": "3 players, sole finisher with a Patibong kill and eighth-point totals",
			"seats": 3,
			"start": {0: 3, 1: 11, 2: 1},
			"outcomes":
			[
				P06Fixtures.terminal(0, "finished", 30),
				P06Fixtures.terminal(1, "eliminated", 20, 0),
				P06Fixtures.terminal(2, "eliminated", 25),
			],
			"reason": "post_finish_deadline",
		},
		{
			"name": "4 players all finished (suppressed)",
			"seats": 4,
			"start": {0: 0, 1: 0, 2: 0, 3: 0},
			"outcomes":
			[
				P06Fixtures.terminal(0, "finished", 11),
				P06Fixtures.terminal(1, "finished", 12),
				P06Fixtures.terminal(2, "finished", 13),
				P06Fixtures.terminal(3, "finished", 14),
			],
			"reason": "all_terminal",
		},
		{
			"name": "4 players nobody finished (suppressed)",
			"seats": 4,
			"start": {0: 8, 1: 8, 2: 8, 3: 8},
			"outcomes":
			[
				P06Fixtures.terminal(0, "eliminated", 60),
				P06Fixtures.terminal(1, "eliminated", 60),
				P06Fixtures.terminal(2, "eliminated", 60),
				P06Fixtures.terminal(3, "eliminated", 60),
			],
			"reason": "hard_cap",
		},
		{
			"name": "4 players, worst-case award rows (3 Tapos, 3 Una, 3 Bawi, 1 Patibong)",
			"seats": 4,
			"start": {0: 0, 1: 0, 2: 0, 3: 40},
			"outcomes":
			[
				P06Fixtures.terminal(0, "finished", 5),
				P06Fixtures.terminal(1, "finished", 5),
				P06Fixtures.terminal(2, "finished", 5),
				P06Fixtures.terminal(3, "eliminated", 9, 0),
			],
			"reason": "post_finish_deadline",
		},
	]
	for case in cases:
		var seat_count := int(case.seats)
		var seats := _registry_seats(seat_count)
		var seat_indices: Array[int] = []
		var joined: Array[Dictionary] = []
		for index in seat_count:
			seat_indices.append(index)
			joined.append(seats[index])
		var outcomes: Array[Dictionary] = []
		for outcome in case.outcomes:
			outcomes.append(outcome)
		var score := RaceScoreCalculator.calculate(seat_indices, outcomes, case.start)
		var model := MatchResultsViewModel.race(
			3, joined, outcomes, score, str(case.reason), 60.0, 15.0
		)
		var screen := RESULT_SCENE.instantiate() as UiRoundResultScreen
		root.add_child(screen)
		await process_frame
		var ready := {0: true}
		screen.bind_live(model, seats, ready, 6.0, 8.0, "k1", load(UiContext.PROMPT_MAP_PATH))
		var label := str(case.name)
		_check(
			(screen.get_node("%RoundLabel") as Label).text == "Round 3 result",
			"%s: round heading" % label
		)
		_check(
			screen.get_node("%NoScoreReason").text_value() == model.suppression_reason,
			"%s: scoring reason equals the P06 text" % label
		)
		_check(screen.get_node("%NoScoreReason").visible, "%s: scoring reason is visible" % label)
		_check(
			(screen.get_node("%EndReasonLabel") as Label).text == model.diagnostic_label,
			"%s: end reason equals the view model" % label
		)
		_check(
			(screen.get_node("%DeadlineLabel") as Label).text == model.deadline_explanation,
			"%s: deadline explanation equals the view model" % label
		)
		for index in screen.outcome_rows.size():
			var row := screen.outcome_rows[index]
			if index >= model.per_seat_outcomes.size():
				_check(not row.visible, "%s: unused outcome row %d is hidden" % [label, index + 1])
				continue
			var outcome: Dictionary = model.per_seat_outcomes[index]
			_check(
				row.score_text() == str(outcome.total_text),
				"%s: seat %d total shows %s" % [label, index + 1, outcome.total_text]
			)
			_check(
				(
					row.state_text().contains(str(outcome.score_delta_text))
					and row.state_text().contains(str(outcome.outcome))
				),
				"%s: seat %d shows delta and outcome text" % [label, index + 1]
			)
			_check(
				(
					row.badge.number_text() == str(outcome.identity)
					and row.badge.visible_shape() == str(outcome.shape)
				),
				"%s: seat %d row keeps number and shape" % [label, index + 1]
			)
			var seat_ready: bool = row.state_text().contains("READY")
			_check(seat_ready == (index == 0), "%s: ready mark follows results_ready" % label)
		var explain := model.award_rows.size() <= UiRoundResultScreen.EXPLAINED_AWARD_ROWS
		for index in screen.award_lines.size():
			var line := screen.award_lines[index]
			if index >= model.award_rows.size():
				_check(not line.visible, "%s: unused award row %d is hidden" % [label, index + 1])
				continue
			var award: Dictionary = model.award_rows[index]
			var text := line.text_value()
			_check(
				text.contains(str(award.title)) and text.contains(str(award.score_text)),
				"%s: award %d shows %s %s" % [label, index + 1, award.title, award.score_text]
			)
			_check(
				text.contains(str(award.explanation)) == explain,
				"%s: award %d explanation follows the row-count rule" % [label, index + 1]
			)
			_check(
				line.badge.number_text() == str(award.identity),
				"%s: award %d carries the seat number" % [label, index + 1]
			)
		screen.queue_free()
		await process_frame
	# ScoreFormat is the only formatter: eighth-point units render exactly.
	_check(ScoreFormat.format_units(3) == "0.375", "3 units render as 0.375")
	_check(ScoreFormat.format_units(11) == "1.375", "11 units render as 1.375")
	_check(ScoreFormat.format_units(40) == "5", "40 units render as a whole 5")


func _registry_seats(count: int) -> Array[Dictionary]:
	var registry := PlayerSeatRegistry.new()
	for index in count:
		if index == 0:
			registry.join_keyboard("K1")
		elif index == 1:
			registry.join_keyboard("K2")
		else:
			registry.join_gamepad(PAD_IDS[index - 2])
	var seats: Array[Dictionary] = []
	for index in PlayerSeatRegistry.MAX_SEATS:
		seats.append(registry.get_seat(index))
	return seats


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("MATCH_UI_BINDING FAIL: " + message)

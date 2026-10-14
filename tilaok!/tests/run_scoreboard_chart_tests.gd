extends SceneTree

## Focused math, provenance, reveal, resize, layout and cleanup checks for the chart.

const CHART_SCENE := preload("res://scenes/ui/components/scoreboard_chart.tscn")

var checks := 0
var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_history_exactness_and_eviction()
	await _test_chart_motion_layout_and_teardown()
	print("SCOREBOARD_CHART_TESTS checks=%d failures=%d" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _test_history_exactness_and_eviction() -> void:
	var history := ScorePresentationHistory.new()
	var first_result := {
		"valid": true,
		"award_rows":
		[
			{"seat_index": 0, "key": "tapos", "title": "Tapos", "units": 8},
			{"seat_index": 0, "key": "patibong", "title": "Patibong", "units": 2},
			{"seat_index": 0, "key": "patibong", "title": "Patibong", "units": 2},
			{"seat_index": 3, "key": "placement", "title": "Placement", "units": 0},
		]
	}
	_check(history.record_committed(2, 1, first_result), "first authoritative commit is recorded")
	_check(not history.record_committed(2, 1, first_result), "duplicate commit is ignored")
	_check(
		not history.record_committed(2, 2, {"valid": false, "award_rows": first_result.award_rows}),
		"invalid or uncommitted result is ignored"
	)
	var totals := {
		0: {"units": 20, "identity": 1, "shape": "CIRCLE"},
		3: {"units": 3, "identity": 4, "shape": "DIAMOND"},
	}
	var snapshot := history.snapshot(totals, 1)
	var rows: Array[Dictionary] = snapshot.seats
	_check(rows.size() == 2, "noncontiguous seats keep their own chart columns")
	_check(rows[0].seat_index == 0 and rows[1].seat_index == 3, "columns use stable seat order")
	_check(
		history.total_units_in_segments(rows[0]) == 20, "award and neutral segments sum to total"
	)
	_check(history.total_units_in_segments(rows[1]) == 3, "preloaded total is shown as neutral")
	_check(
		rows[0].segments[2].row_id == "0:patibong:0", "repeated award rows have stable identities"
	)
	_check(
		rows[0].segments[3].row_id == "0:patibong:1", "repeated award identity ordinal increments"
	)
	_check(rows[0].segments[0].units == 8, "unattributed amount stays a neutral prior total")
	_check(rows[0].segments[1].units == 8, "eighth-point award units remain exact")
	_check(rows[1].segments.size() == 1, "zero placement is not inflated into a visible segment")
	_check(rows[0].segments[1].reveal, "current committed rows are tagged for reveal")
	_check(not rows[0].segments[0].reveal, "previous total does not replay")
	var detached := snapshot.duplicate(true)
	detached.seats[0].segments[2].units = 999
	_check(history.snapshot(totals, 1).seats[0].segments[2].units == 2, "snapshot is deep-copied")
	_check(not history.record_committed(2, 1, first_result), "same round remains deduplicated")

	for round_number in range(2, ScorePresentationHistory.MAX_RETAINED_ROUNDS + 2):
		_check(
			history.record_committed(
				2,
				round_number,
				{"award_rows": [{"seat_index": 0, "key": "una", "title": "Una", "units": 1}]}
			),
			"committed round %d is retained" % round_number
		)
	_check(
		history.retained_round_count() == ScorePresentationHistory.MAX_RETAINED_ROUNDS,
		"history is bounded to twelve rounds"
	)
	var after_eviction := history.snapshot(
		{0: {"units": 20 + ScorePresentationHistory.MAX_RETAINED_ROUNDS}}
	)
	var evicted_row: Dictionary = after_eviction.seats[0]
	_check(
		history.total_units_in_segments(evicted_row) == int(evicted_row.units),
		"eviction keeps exact total"
	)
	_check(
		str(evicted_row.segments[0].key) == "previous_total",
		"evicted scores collapse into the neutral previous-total segment"
	)
	_check(
		not history.record_committed(2, 1, first_result),
		"recent dedupe tombstones survive visual eviction"
	)
	history.reset()
	_check(
		history.retained_round_count() == 0 and history.retained_award_count() == 0,
		"replay reset clears provenance"
	)
	_check(
		history.record_committed(3, 1, first_result),
		"new match id can start a fresh round-one history"
	)


func _test_chart_motion_layout_and_teardown() -> void:
	var chart := CHART_SCENE.instantiate() as ScoreboardChart
	root.add_child(chart)
	chart.size = Vector2(880.0, 420.0)
	var rows: Array[Dictionary] = [
		{
			"seat_index": 1,
			"identity": 2,
			"shape": "TRIANGLE",
			"units": 80,
			"delta_units": 8,
			"status": "FINISHED",
			"segments":
			[
				{"key": "previous_total", "units": 72},
				{"key": "tapos", "units": 8, "reveal": true},
			],
		},
		{
			"seat_index": 3,
			"identity": 4,
			"shape": "DIAMOND",
			"units": 80,
			"delta_units": 8,
			"status": "WINNER",
			"segments":
			[
				{"key": "previous_total", "units": 72},
				{"key": "tapos", "units": 8, "reveal": true},
			],
		},
	]
	var seats: Array[Dictionary] = [
		{"seat": 1, "identity": 2, "shape": "TRIANGLE", "color": Color.BLUE, "joined": true},
		{"seat": 3, "identity": 4, "shape": "DIAMOND", "color": Color.GREEN, "joined": true},
	]
	chart.bind_rows(rows, 80, "match:1:round:12", seats, PresentationSettings.RESULT_REVEAL_NORMAL)
	await process_frame
	var columns := chart.chart_columns()
	_check(columns.size() == 2, "two joined noncontiguous seats create two columns")
	_check(
		chart.target_units() == 80 and chart.axis_max_units() == 88,
		"axis keeps exact target and one-point headroom"
	)
	_check(columns[0].badge.number_text() == "2", "first column preserves number identity")
	_check(columns[1].badge.visible_shape() == "DIAMOND", "second column preserves shape identity")
	_check(columns[0].visible_total_units() == 72, "normal reveal starts from prior score")
	_check(
		is_equal_approx(columns[0].feet_anchor_y(), columns[0].bar_top_y()),
		(
			"chicken feet stay anchored to bar top (%.3f vs %.3f)"
			% [columns[0].feet_anchor_y(), columns[0].bar_top_y()]
		)
	)
	await create_timer(0.10).timeout
	var elapsed_before_resize := chart.reveal_elapsed_seconds()
	chart.size = Vector2(1100.0, 470.0)
	chart.bind_rows(rows, 80, "match:1:round:12", seats, PresentationSettings.RESULT_REVEAL_NORMAL)
	await process_frame
	_check(
		chart.reveal_elapsed_seconds() >= elapsed_before_resize,
		"resize and repeated bind do not restart reveal"
	)
	_check(
		is_equal_approx(columns[0].feet_anchor_y(), columns[0].bar_top_y()),
		(
			"resize preserves chicken foot anchor (%.3f vs %.3f)"
			% [columns[0].feet_anchor_y(), columns[0].bar_top_y()]
		)
	)
	chart.settle()
	_check(not chart.is_revealing(), "early advance settles chart immediately")
	_check(
		columns[0].visible_total_units() == 80, "settled eighth-point result reaches exact total"
	)
	_check(columns[1].bar_top_y() == columns[0].bar_top_y(), "equal scores share exact bar height")

	chart.bind_rows(rows, 80, "above-target", seats, PresentationSettings.RESULT_REVEAL_OFF)
	await process_frame
	_check(chart.axis_max_units() == 88, "score at target retains exact one-point headroom")
	var high_rows := rows.duplicate(true)
	high_rows[0].units = 104
	high_rows[0].segments = [{"key": "previous_total", "units": 104}]
	chart.bind_rows(
		high_rows, 80, "above-target-score", seats, PresentationSettings.RESULT_REVEAL_OFF
	)
	await process_frame
	_check(chart.axis_max_units() == 112, "above-target score expands the shared scale")
	_check(chart.target_units() == 80, "scale expansion does not move target line value")
	_check(columns[0].visible_total_units() == 104, "Off mode displays settled score immediately")
	var reduced_rows := rows.duplicate(true)
	chart.bind_rows(reduced_rows, 80, "reduced", seats, PresentationSettings.RESULT_REVEAL_REDUCED)
	await process_frame
	_check(not chart.is_revealing(), "Reduced mode skips spatial stack animation")
	_check(columns[0].visible_total_units() == 80, "Reduced mode sets final stack immediately")
	chart.settle()
	var old_instance := chart
	chart.queue_free()
	await process_frame
	_check(not is_instance_valid(old_instance), "teardown releases chart and UI-only chicken nodes")


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("SCOREBOARD_CHART FAIL: " + message)

class_name UiRoundResultScreen
extends UiScreen

signal continue_requested(seat_index: int)

## Above this many award rows only title + points are shown so the breakdown remains readable.
const EXPLAINED_AWARD_ROWS := 6

var award_lines: Array[UiAwardLine] = []

@onready var _round_label: Label = %RoundLabel
@onready var _end_reason_label: Label = %EndReasonLabel
@onready var _deadline_label: Label = %DeadlineLabel
@onready var _last_cluck_callout: Label = %LastCluckCallout
@onready var _twist_line: Label = %TwistLine
@onready var _next_round_label: Label = %NextRoundLabel
@onready var _no_score_reason: UiToastLine = %NoScoreReason
@onready var _ready_hint: UiPromptGlyph = %ReadyHint
@onready var _advance: UiCountdownRing = %AdvanceCountdown
@onready var _tutorial_strip: Control = %TutorialStrip
@onready var _chart: ScoreboardChart = %ScoreChart
@onready var _tag: Label = $Safe/Content/Tag


func state_names() -> PackedStringArray:
	return PackedStringArray(["Normal", "Nobody finished", "Everybody finished", "2-player waived"])


## Keeps a free strip at the right edge while the tutorial Results box is shown, so the box
## never covers chart content or an award line. Zero width removes the strip.
func reserve_side_strip(width: float) -> void:
	_tutorial_strip.visible = width > 0.0
	_tutorial_strip.custom_minimum_size = Vector2(maxf(width, 0.0), 0.0)


func router_phase() -> int:
	return LocalInputRouter.Phase.RESULTS


func bind_result(sample: UiSampleMatch, seats: Array[Dictionary], reason: String) -> void:
	_round_label.text = "Round %d result" % sample.round_number
	_end_reason_label.visible = false
	_deadline_label.visible = false
	var chart_rows: Array[Dictionary] = []
	for index in seats.size():
		var seat: Dictionary = seats[index]
		if not bool(seat.get("joined", false)):
			continue
		var total_units := (
			roundi(float(sample.scores[index]) * 8.0) if index < sample.scores.size() else 0
		)
		var delta_units := (
			roundi(float(sample.outcome_points[index]) * 8.0)
			if index < sample.outcome_points.size()
			else 0
		)
		var outcome_text := sample.outcomes[index] if index < sample.outcomes.size() else ""
		chart_rows.append(_sample_chart_row(seat, total_units, delta_units, outcome_text))
	_chart.bind_rows(chart_rows, 80, "sample:%d" % sample.round_number, seats)
	for index in award_lines.size():
		if index < sample.awards.size():
			var seat_index := sample.award_seats[index] if index < sample.award_seats.size() else 0
			var seat: Dictionary = _seat_for(seats, seat_index)
			award_lines[index].bind(seat, sample.awards[index])
		else:
			award_lines[index].visible = false
	_no_score_reason.show_text(reason)


## Live: shows exactly what P05/P06 computed for the round (see MatchResultsViewModel).
## seats are the four registry seat dictionaries; ready_by_seat maps seat -> bool.
func bind_live(
	model: MatchResultsViewModel,
	seats: Array[Dictionary],
	ready_by_seat: Dictionary,
	remaining: float,
	total: float,
	device_kind: String,
	map: UiPromptMap,
	motion_mode: int = PresentationSettings.RESULT_REVEAL_NORMAL,
	twist_text: String = "",
	next_round_text: String = ""
) -> void:
	_tag.visible = false
	_last_cluck_callout.visible = not model.last_cluck_explanation.is_empty()
	_twist_line.text = twist_text
	_twist_line.visible = not twist_text.is_empty()
	_next_round_label.text = next_round_text
	_next_round_label.visible = not next_round_text.is_empty()
	_round_label.text = "Round %d result" % model.round_number
	_end_reason_label.text = model.diagnostic_label
	_end_reason_label.visible = not model.diagnostic_label.is_empty()
	_deadline_label.text = model.deadline_explanation
	_deadline_label.visible = not model.deadline_explanation.is_empty()
	var chart_rows: Array = model.score_presentation.get("seats", []).duplicate(true)
	if chart_rows.is_empty():
		chart_rows = _fallback_chart_rows(model)
	for chart_row in chart_rows:
		var seat_index := int(chart_row.get("seat_index", -1))
		var outcome := _outcome_for(model.per_seat_outcomes, seat_index)
		var detail := str(outcome.get("outcome", ""))
		if bool(ready_by_seat.get(seat_index, false)):
			detail = "READY · " + detail
		chart_row["status"] = detail
	_chart.bind_rows(
		chart_rows,
		model.target_score_units,
		(
			model.score_presentation_id
			if not model.score_presentation_id.is_empty()
			else "round:%d" % model.round_number
		),
		seats,
		motion_mode
	)
	var explain := model.award_rows.size() <= EXPLAINED_AWARD_ROWS
	for index in award_lines.size():
		var line := award_lines[index]
		if index >= model.award_rows.size():
			line.visible = false
			continue
		var award: Dictionary = model.award_rows[index]
		var award_seat_index := int(award.get("seat_index", -1))
		var award_seat := _seat_for(seats, award_seat_index)
		var text := "%s %s" % [str(award.get("title", "")), str(award.get("score_text", ""))]
		if explain:
			text += " — %s" % str(award.get("explanation", ""))
		line.bind(award_seat, text, str(award.get("key", "")))
	_no_score_reason.show_text(model.suppression_reason)
	_ready_hint.bind("results_ready", device_kind, map)
	_advance.set_time(remaining, total)


func _on_screen_ready() -> void:
	award_lines = [
		%Award1, %Award2, %Award3, %Award4, %Award5, %Award6, %Award7, %Award8, %Award9, %Award10
	]


func _show_state(index: int, ctx: UiContext) -> void:
	var reason := ctx.sample.no_score_reason
	if index == 1:
		reason = "Nobody reached the flag, so no points were awarded this round."
	elif index == 2:
		reason = "Everybody reached the flag, so no points were awarded this round."
	elif index == 3:
		reason = "Both finished: points are waived in 2-player."
	bind_result(ctx.sample, ctx.seats, reason)
	_ready_hint.bind("results_ready", ctx.device_kind, ctx.prompt_map)
	_advance.set_time(ctx.sample.advance_seconds, ctx.sample.advance_seconds)


func _accept(seat_index: int) -> bool:
	_chart.settle()
	continue_requested.emit(seat_index)
	return true


func last_cluck_visible() -> bool:
	return _last_cluck_callout.visible


func twist_line_text() -> String:
	return _twist_line.text if _twist_line.visible else ""


func next_round_text() -> String:
	return _next_round_label.text if _next_round_label.visible else ""


func chart() -> ScoreboardChart:
	return _chart


func _fallback_chart_rows(model: MatchResultsViewModel) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for outcome in model.per_seat_outcomes:
		var seat_index := int(outcome.get("seat_index", -1))
		var total_units := int(outcome.get("total_units", 0))
		var awards: Array[Dictionary] = []
		var known_units := 0
		for award in model.award_rows:
			if int(award.get("seat_index", -1)) != seat_index or int(award.get("units", 0)) <= 0:
				continue
			known_units += int(award.units)
			(
				awards
				. append(
					{
						"key": str(award.get("key", "previous_total")),
						"row_id": str(award.get("key", "award")),
						"title": str(award.get("title", "Award")),
						"units": int(award.units),
						"reveal": true,
					}
				)
			)
		var segments: Array[Dictionary] = []
		if total_units > known_units:
			segments.append({"key": "previous_total", "units": total_units - known_units})
		segments.append_array(awards)
		(
			rows
			. append(
				{
					"seat_index": seat_index,
					"identity": int(outcome.get("identity", seat_index + 1)),
					"shape": str(outcome.get("shape", "")),
					"units": total_units,
					"delta_units": int(outcome.get("score_delta_units", 0)),
					"delta_text": str(outcome.get("score_delta_text", "")),
					"segments": segments,
				}
			)
		)
	return rows


func _outcome_for(outcomes: Array[Dictionary], seat_index: int) -> Dictionary:
	for outcome in outcomes:
		if int(outcome.get("seat_index", -1)) == seat_index:
			return outcome
	return {}


func _seat_for(seats: Array[Dictionary], seat_index: int) -> Dictionary:
	for seat in seats:
		if int(seat.get("seat", -1)) == seat_index:
			return seat
	return {}


func _sample_chart_row(
	seat: Dictionary, total_units: int, delta_units: int, outcome_text: String
) -> Dictionary:
	var segments: Array[Dictionary] = []
	if total_units > maxi(delta_units, 0):
		segments.append({"key": "previous_total", "units": total_units - maxi(delta_units, 0)})
	if delta_units > 0:
		segments.append({"key": "tapos", "title": "Tapos", "units": delta_units, "reveal": true})
	return {
		"seat_index": int(seat.get("seat", -1)),
		"identity": int(seat.get("identity", 0)),
		"shape": str(seat.get("shape", "")),
		"units": total_units,
		"delta_units": delta_units,
		"status": outcome_text,
		"segments": segments,
	}

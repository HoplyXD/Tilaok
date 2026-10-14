class_name UiRoundResultScreen
extends UiScreen

signal continue_requested(seat_index: int)

## Above this many award rows only title + points are shown so the column always fits.
const EXPLAINED_AWARD_ROWS := 6

var outcome_rows: Array[UiScoreRow] = []
var award_lines: Array[UiAwardLine] = []

@onready var _round_label: Label = %RoundLabel
@onready var _end_reason_label: Label = %EndReasonLabel
@onready var _deadline_label: Label = %DeadlineLabel
@onready var _no_score_reason: UiToastLine = %NoScoreReason
@onready var _ready_hint: UiPromptGlyph = %ReadyHint
@onready var _advance: UiCountdownRing = %AdvanceCountdown


func state_names() -> PackedStringArray:
	return PackedStringArray(["Normal", "Nobody finished", "Everybody finished", "2-player waived"])


func router_phase() -> int:
	return LocalInputRouter.Phase.RESULTS


func bind_result(sample: UiSampleMatch, seats: Array[Dictionary], reason: String) -> void:
	_round_label.text = "Round %d result" % sample.round_number
	_end_reason_label.visible = false
	_deadline_label.visible = false
	for index in outcome_rows.size():
		var seat: Dictionary = seats[index] if index < seats.size() else {}
		var text := sample.outcomes[index] if index < sample.outcomes.size() else ""
		var points := sample.outcome_points[index] if index < sample.outcome_points.size() else 0.0
		outcome_rows[index].bind(seat, points, text)
	for index in award_lines.size():
		if index < sample.awards.size():
			var seat_index := sample.award_seats[index] if index < sample.award_seats.size() else 0
			var seat: Dictionary = seats[seat_index] if seat_index < seats.size() else {}
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
	map: UiPromptMap
) -> void:
	_round_label.text = "Round %d result" % model.round_number
	_end_reason_label.text = model.diagnostic_label
	_end_reason_label.visible = not model.diagnostic_label.is_empty()
	_deadline_label.text = model.deadline_explanation
	_deadline_label.visible = not model.deadline_explanation.is_empty()
	for index in outcome_rows.size():
		var row := outcome_rows[index]
		if index >= model.per_seat_outcomes.size():
			row.visible = false
			continue
		var outcome: Dictionary = model.per_seat_outcomes[index]
		var seat_index := int(outcome.get("seat_index", -1))
		var seat: Dictionary = (
			seats[seat_index] if seat_index >= 0 and seat_index < seats.size() else {}
		)
		var detail := (
			"%s · %s" % [str(outcome.get("score_delta_text", "")), str(outcome.get("outcome", ""))]
		)
		if bool(ready_by_seat.get(seat_index, false)):
			detail += " · READY"
		row.bind_texts(seat, str(outcome.get("total_text", "")), detail)
	var explain := model.award_rows.size() <= EXPLAINED_AWARD_ROWS
	for index in award_lines.size():
		var line := award_lines[index]
		if index >= model.award_rows.size():
			line.visible = false
			continue
		var award: Dictionary = model.award_rows[index]
		var award_seat_index := int(award.get("seat_index", -1))
		var award_seat: Dictionary = (
			seats[award_seat_index]
			if award_seat_index >= 0 and award_seat_index < seats.size()
			else {}
		)
		var text := "%s %s" % [str(award.get("title", "")), str(award.get("score_text", ""))]
		if explain:
			text += " — %s" % str(award.get("explanation", ""))
		line.bind(award_seat, text)
	_no_score_reason.show_text(model.suppression_reason)
	_ready_hint.bind("results_ready", device_kind, map)
	_advance.set_time(remaining, total)


func _on_screen_ready() -> void:
	outcome_rows = [%Outcome1, %Outcome2, %Outcome3, %Outcome4]
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
	continue_requested.emit(seat_index)
	return true

class_name UiRoundResultScreen
extends UiScreen

signal continue_requested(seat_index: int)

var outcome_rows: Array[UiScoreRow] = []
var award_lines: Array[UiAwardLine] = []

@onready var _round_label: Label = %RoundLabel
@onready var _no_score_reason: UiToastLine = %NoScoreReason
@onready var _ready_hint: UiPromptGlyph = %ReadyHint
@onready var _advance: UiCountdownRing = %AdvanceCountdown


func state_names() -> PackedStringArray:
	return PackedStringArray(["Normal", "Nobody finished", "Everybody finished", "2-player waived"])


func router_phase() -> int:
	return LocalInputRouter.Phase.RESULTS


func bind_result(sample: UiSampleMatch, seats: Array[Dictionary], reason: String) -> void:
	_round_label.text = "Round %d result" % sample.round_number
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


func _on_screen_ready() -> void:
	outcome_rows = [%Outcome1, %Outcome2, %Outcome3, %Outcome4]
	award_lines = [%Award1, %Award2, %Award3, %Award4, %Award5, %Award6]


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

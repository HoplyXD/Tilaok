class_name UiScoreRow
extends PanelContainer

## One player's row: badge (number + shape), score and a text state tag.

const SCORE_STEP := 0.125

@onready var badge: UiPlayerBadge = %Badge
@onready var _score_label: Label = %ScoreLabel
@onready var _state_label: Label = %StateLabel


func bind(seat: Dictionary, score: float, state: String) -> void:
	visible = not seat.is_empty() and bool(seat.get("joined", false))
	badge.bind_seat(seat)
	_score_label.visible = true
	_score_label.text = "%s" % snappedf(score, SCORE_STEP)
	_state_label.text = state


func bind_roster(seat: Dictionary, text: String) -> void:
	visible = not seat.is_empty() and bool(seat.get("joined", false))
	badge.bind_seat(seat)
	_score_label.visible = false
	_state_label.text = text


func score_text() -> String:
	return _score_label.text


func state_text() -> String:
	return _state_label.text

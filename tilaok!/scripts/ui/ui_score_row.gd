class_name UiScoreRow
extends PanelContainer

## One player's row: badge (number + shape), score and a text state tag.

const SCORE_STEP := 0.125

## True paints the badge shape in this row's own panel colour (the Pause pill's outlined symbol).
@export var shape_matches_panel := false

@onready var badge: UiPlayerBadge = %Badge
@onready var _score_label: Label = %ScoreLabel
@onready var _state_label: Label = %StateLabel


func bind(seat: Dictionary, score: float, state: String) -> void:
	visible = not seat.is_empty() and bool(seat.get("joined", false))
	badge.bind_seat(seat)
	_score_label.visible = true
	_score_label.text = "%s" % snappedf(score, SCORE_STEP)
	_state_label.text = state


## Live binding: exact eighth-point units formatted by ScoreFormat (no float rounding).
func bind_units(seat: Dictionary, units: int, state: String) -> void:
	bind_texts(seat, ScoreFormat.format_units(units), state)


## Live binding for values that are already formatted text (round result rows).
func bind_texts(seat: Dictionary, score_text: String, state_text: String) -> void:
	visible = not seat.is_empty() and bool(seat.get("joined", false))
	badge.bind_seat(seat)
	_score_label.visible = true
	_score_label.text = score_text
	_state_label.text = state_text


func bind_roster(seat: Dictionary, text: String) -> void:
	visible = not seat.is_empty() and bool(seat.get("joined", false))
	if shape_matches_panel:
		var box := get_theme_stylebox("panel") as StyleBoxFlat
		if box != null:
			badge.plain_tint = box.bg_color
	badge.bind_seat(seat)
	_score_label.visible = false
	_state_label.text = text


func score_text() -> String:
	return _score_label.text


func state_text() -> String:
	return _state_label.text

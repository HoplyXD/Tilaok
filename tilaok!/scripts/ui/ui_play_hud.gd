class_name UiPlayHud
extends UiScreen

## Display-only HUD in the 64 px top reservation. Never takes input.

const CHALLENGE_NAME := "Karera"

var score_rows: Array[UiScoreRow] = []

@onready var hud_bar: Control = %HudBar
@onready var _notice_toast: UiToastLine = %NoticeToast
@onready var _round_label: Label = %RoundLabel
@onready var _challenge_label: Label = %ChallengeLabel
@onready var _twist_tag: Label = %TwistTag
@onready var _timer_label: Label = %TimerLabel
@onready var _next_event_label: Label = %NextEventLabel
@onready var _control_hints_bar: PanelContainer = %ControlHintsBar
@onready var _control_hints_grid: GridContainer = %ControlHintsRow
@onready var _notice_row: MarginContainer = %NoticeRow
@onready var _control_hint_labels: Array[Label] = [
	%ControlHint1, %ControlHint2, %ControlHint3, %ControlHint4
]
## "NEXT R6 KANGAROO": the locked next-round selection. (NextEventLabel keeps its historical
## name but carries the live tag: taya countdown, finish window or the current command.)
@onready var _up_next_label: Label = %UpNextLabel


func up_next_text() -> String:
	return _up_next_label.text if _up_next_label.visible else ""


func state_names() -> PackedStringArray:
	return PackedStringArray(["Normal", "Twist", "Taya", "Eliminated", "No timer"])


func router_phase() -> int:
	return LocalInputRouter.Phase.PLAY


func bind_round(
	round_number: int, challenge: String, twist: String, timer_text: String, next_event: String
) -> void:
	_round_label.text = "Round %d" % round_number
	_challenge_label.text = challenge
	_twist_tag.text = twist
	_twist_tag.visible = not twist.is_empty()
	_timer_label.text = timer_text
	_timer_label.visible = not timer_text.is_empty()
	_next_event_label.text = next_event
	_next_event_label.visible = not next_event.is_empty()


## Live: exact eighth-point units (ScoreFormat), per-seat state text and an optional notice.
## score_units / states map seat index -> int / String.
func bind_live(
	round_number: int,
	timer_text: String,
	window_text: String,
	seats: Array[Dictionary],
	score_units: Dictionary,
	states: Dictionary,
	notice: String,
	challenge_text: String = CHALLENGE_NAME,
	twist_text: String = "",
	up_next_text: String = ""
) -> void:
	bind_round(round_number, challenge_text, twist_text, timer_text, window_text)
	_up_next_label.text = up_next_text
	_up_next_label.visible = not up_next_text.is_empty()
	for index in score_rows.size():
		var seat: Dictionary = seats[index] if index < seats.size() else {}
		score_rows[index].bind_units(
			seat, int(score_units.get(index, 0)), str(states.get(index, ""))
		)
	_notice_toast.show_text(notice)


func bind_control_hints(control_hints: PackedStringArray) -> void:
	_bind_control_hints(control_hints)


func _bind_control_hints(hints: PackedStringArray) -> void:
	var any_hint := false
	var visible_count := 0
	for index in _control_hint_labels.size():
		var label := _control_hint_labels[index]
		label.text = hints[index] if index < hints.size() else ""
		label.visible = not label.text.is_empty()
		any_hint = any_hint or label.visible
		if label.visible:
			visible_count += 1
	_control_hints_bar.visible = any_hint
	_control_hints_grid.columns = 2
	var hint_rows := ceili(float(visible_count) / 2.0) if any_hint else 0
	var hint_height := hint_rows * 48
	_control_hints_bar.offset_bottom = 64.0 + hint_height
	_notice_row.offset_top = 70.0 + hint_height
	_notice_row.offset_bottom = _notice_row.offset_top + 79.0


func bind_scores(
	seats: Array[Dictionary], scores: PackedFloat32Array, states: PackedStringArray
) -> void:
	for index in score_rows.size():
		var seat: Dictionary = seats[index] if index < seats.size() else {}
		var score := scores[index] if index < scores.size() else 0.0
		var state := states[index] if index < states.size() else ""
		score_rows[index].bind(seat, score, state)


func _on_screen_ready() -> void:
	score_rows = [%ScoreRow1, %ScoreRow2, %ScoreRow3, %ScoreRow4]


func _show_state(index: int, ctx: UiContext) -> void:
	var sample := ctx.sample
	var states := sample.states.duplicate()
	var twist := sample.twist if index == 1 else ""
	var timer := "" if index == 4 else sample.timer_text
	if index == 2 and states.size() > 0:
		states[0] = "TAYA"
	if index == 3 and states.size() > 1:
		states[1] = "ELIMINATED"
	bind_round(sample.round_number, sample.main_challenge, twist, timer, sample.next_event)
	bind_scores(ctx.seats, sample.scores, states)

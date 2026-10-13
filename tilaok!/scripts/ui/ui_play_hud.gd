class_name UiPlayHud
extends UiScreen

## Display-only HUD in the 64 px top reservation. Never takes input.

var score_rows: Array[UiScoreRow] = []

@onready var hud_bar: Control = %HudBar
@onready var _round_label: Label = %RoundLabel
@onready var _challenge_label: Label = %ChallengeLabel
@onready var _twist_tag: Label = %TwistTag
@onready var _timer_label: Label = %TimerLabel
@onready var _next_event_label: Label = %NextEventLabel


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

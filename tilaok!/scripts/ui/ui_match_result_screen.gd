class_name UiMatchResultScreen
extends UiScreen

signal replay_requested
signal lobby_requested
signal quit_requested
signal menu_selection_changed(index: int)

@onready var _winner_badge: UiPlayerBadge = %WinnerBadge
@onready var _winner_label: Label = %WinnerLabel
@onready var _outcome_label: Label = %OutcomeLabel
@onready var _last_cluck: UiPhaseBanner = %LastCluckCallout
@onready var _tag: Label = $Safe/Content/Tag
@onready var _menu: UiMenuList = %MenuList
@onready var _replay_button: Button = %ReplayButton
@onready var _lobby_button: Button = %LobbyButton
@onready var _quit_button: Button = %QuitButton
@onready var _chart: ScoreboardChart = %FinalChart


func state_names() -> PackedStringArray:
	return PackedStringArray(["Winner", "Last Cluck", "Tie"])


func router_phase() -> int:
	return LocalInputRouter.Phase.RESULTS


func bind_match(sample: UiSampleMatch, seats: Array[Dictionary], cluck: bool, tie: bool) -> void:
	_tag.visible = true
	var winner: Dictionary = seats[sample.winner_seat] if sample.winner_seat < seats.size() else {}
	_winner_badge.bind_seat(winner)
	_winner_label.text = "TIE - shared win" if tie else "WINNER"
	var rows: Array[Dictionary] = []
	for index in seats.size():
		var seat: Dictionary = seats[index]
		if not bool(seat.get("joined", false)):
			continue
		var units := (
			roundi(float(sample.scores[index]) * 8.0) if index < sample.scores.size() else 0
		)
		(
			rows
			. append(
				{
					"seat_index": int(seat.get("seat", index)),
					"identity": int(seat.get("identity", index + 1)),
					"shape": str(seat.get("shape", "")),
					"units": units,
					"delta_units": 0,
					"status": "WINNER" if index == sample.winner_seat else "FINAL SCORE",
					"segments": [{"key": "previous_total", "units": units}] if units > 0 else [],
				}
			)
		)
	_chart.bind_rows(rows, 80, "sample-final:%d" % sample.winner_seat, seats)
	_last_cluck.visible = cluck
	_last_cluck.set_phase("LAST CLUCK!", "Won on the final round")
	_outcome_label.text = "SAMPLE gallery data"


## Live P09 binding. SAMPLE gallery resources are never read on this path.
func bind_final_match(
	model: MatchResultsViewModel, motion_mode: int = PresentationSettings.RESULT_REVEAL_NORMAL
) -> void:
	_tag.visible = false
	var seats: Array[Dictionary] = model.final_seats
	var winner_seat := model.winner_seat
	var winner: Dictionary = {}
	for seat in seats:
		if int(seat.get("seat", -1)) == winner_seat:
			winner = seat
			break
	_winner_badge.bind_seat(winner)
	_winner_label.text = (
		"WINNER — P%d %s"
		% [int(winner.get("identity", winner_seat + 1)), str(winner.get("shape", ""))]
	)
	_outcome_label.text = model.final_outcome_text
	var chart_rows: Array = model.score_presentation.get("seats", []).duplicate(true)
	if chart_rows.is_empty():
		chart_rows = _fallback_final_rows(model)
	for row in chart_rows:
		row["status"] = "WINNER" if int(row.get("seat_index", -1)) == winner_seat else "FINAL SCORE"
		row["delta_units"] = 0
		row["delta_text"] = ""
	_chart.bind_rows(
		chart_rows,
		model.target_score_units,
		(
			model.score_presentation_id
			if not model.score_presentation_id.is_empty()
			else "final:%d" % winner_seat
		),
		seats,
		motion_mode
	)
	_last_cluck.visible = not model.last_cluck_explanation.is_empty()
	if _last_cluck.visible:
		_last_cluck.set_phase("LAST CLUCK!", model.last_cluck_explanation)
	_menu.refresh_items()


func move_action(direction: String) -> bool:
	return _menu.move(direction)


func activate_action() -> bool:
	return _menu.activate()


func selected_action() -> int:
	return _menu.selected


func _on_screen_ready() -> void:
	_replay_button.pressed.connect(func() -> void: replay_requested.emit())
	_lobby_button.pressed.connect(func() -> void: lobby_requested.emit())
	_quit_button.pressed.connect(func() -> void: quit_requested.emit())
	_menu.selection_changed.connect(func(index: int) -> void: menu_selection_changed.emit(index))
	_menu.refresh_items()


func _show_state(index: int, ctx: UiContext) -> void:
	bind_match(ctx.sample, ctx.seats, index == 1, index == 2)


func _navigate(_seat_index: int, direction: String) -> bool:
	return _menu.move(direction)


func _accept(_seat_index: int) -> bool:
	return _menu.activate()


func chart() -> ScoreboardChart:
	return _chart


func _fallback_final_rows(model: MatchResultsViewModel) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for outcome in model.per_seat_outcomes:
		var seat_index := int(outcome.get("seat_index", -1))
		var units := int(outcome.get("total_units", 0))
		(
			rows
			. append(
				{
					"seat_index": seat_index,
					"identity": int(outcome.get("identity", seat_index + 1)),
					"shape": str(outcome.get("shape", "")),
					"units": units,
					"delta_units": 0,
					"status": str(outcome.get("outcome", "FINAL SCORE")),
					"segments": [{"key": "previous_total", "units": units}] if units > 0 else [],
				}
			)
		)
	return rows

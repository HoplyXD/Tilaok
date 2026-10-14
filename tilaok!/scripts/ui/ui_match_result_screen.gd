class_name UiMatchResultScreen
extends UiScreen

signal replay_requested
signal lobby_requested
signal quit_requested
signal menu_selection_changed(index: int)

var final_rows: Array[UiScoreRow] = []

@onready var _winner_badge: UiPlayerBadge = %WinnerBadge
@onready var _winner_label: Label = %WinnerLabel
@onready var _outcome_label: Label = %OutcomeLabel
@onready var _last_cluck: UiPhaseBanner = %LastCluckCallout
@onready var _tag: Label = $Safe/Content/Tag
@onready var _menu: UiMenuList = %MenuList
@onready var _replay_button: Button = %ReplayButton
@onready var _lobby_button: Button = %LobbyButton
@onready var _quit_button: Button = %QuitButton


func state_names() -> PackedStringArray:
	return PackedStringArray(["Winner", "Last Cluck", "Tie"])


func router_phase() -> int:
	return LocalInputRouter.Phase.RESULTS


func bind_match(sample: UiSampleMatch, seats: Array[Dictionary], cluck: bool, tie: bool) -> void:
	_tag.visible = true
	var winner: Dictionary = seats[sample.winner_seat] if sample.winner_seat < seats.size() else {}
	_winner_badge.bind_seat(winner)
	_winner_label.text = "TIE - shared win" if tie else "WINNER"
	for index in final_rows.size():
		var seat: Dictionary = seats[index] if index < seats.size() else {}
		var score := sample.scores[index] if index < sample.scores.size() else 0.0
		final_rows[index].bind(seat, score, "WINNER" if index == sample.winner_seat else "")
	_last_cluck.visible = cluck
	_last_cluck.set_phase("LAST CLUCK!", "Won on the final round")
	_outcome_label.text = "SAMPLE gallery data"


## Live P09 binding. SAMPLE gallery resources are never read on this path.
func bind_final_match(model: MatchResultsViewModel) -> void:
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
	for index in final_rows.size():
		var seat: Dictionary = seats[index] if index < seats.size() else {}
		if seat.is_empty() or not bool(seat.get("joined", false)):
			final_rows[index].visible = false
			continue
		var seat_index := int(seat.seat)
		var units := int(model.totals.get(seat_index, {}).get("units", 0))
		final_rows[index].bind(
			seat, float(units) / 8.0, "WINNER" if seat_index == winner_seat else "FINAL SCORE"
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
	final_rows = [%Final1, %Final2, %Final3, %Final4]
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

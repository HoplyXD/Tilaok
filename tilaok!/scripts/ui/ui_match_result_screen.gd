class_name UiMatchResultScreen
extends UiScreen

signal replay_requested
signal lobby_requested

var final_rows: Array[UiScoreRow] = []

@onready var _winner_badge: UiPlayerBadge = %WinnerBadge
@onready var _winner_label: Label = %WinnerLabel
@onready var _last_cluck: UiPhaseBanner = %LastCluckCallout
@onready var _menu: UiMenuList = %MenuList
@onready var _replay_button: Button = %ReplayButton
@onready var _lobby_button: Button = %LobbyButton


func state_names() -> PackedStringArray:
	return PackedStringArray(["Winner", "Last Cluck", "Tie"])


func router_phase() -> int:
	return LocalInputRouter.Phase.RESULTS


func bind_match(sample: UiSampleMatch, seats: Array[Dictionary], cluck: bool, tie: bool) -> void:
	var winner: Dictionary = seats[sample.winner_seat] if sample.winner_seat < seats.size() else {}
	_winner_badge.bind_seat(winner)
	_winner_label.text = "TIE - shared win" if tie else "WINNER"
	for index in final_rows.size():
		var seat: Dictionary = seats[index] if index < seats.size() else {}
		var score := sample.scores[index] if index < sample.scores.size() else 0.0
		final_rows[index].bind(seat, score, "WINNER" if index == sample.winner_seat else "")
	_last_cluck.visible = cluck
	_last_cluck.set_phase("LAST CLUCK!", "Won on the final round")


func _on_screen_ready() -> void:
	final_rows = [%Final1, %Final2, %Final3, %Final4]
	_replay_button.pressed.connect(func() -> void: replay_requested.emit())
	_lobby_button.pressed.connect(func() -> void: lobby_requested.emit())
	_menu.refresh_items()


func _show_state(index: int, ctx: UiContext) -> void:
	bind_match(ctx.sample, ctx.seats, index == 1, index == 2)


func _navigate(_seat_index: int, direction: String) -> bool:
	return _menu.move(direction)


func _accept(_seat_index: int) -> bool:
	return _menu.activate()

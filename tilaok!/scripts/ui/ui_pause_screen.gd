class_name UiPauseScreen
extends UiScreen

signal resume_requested
signal settings_requested
signal library_requested
signal leave_confirmed
signal skip_tutorial_requested

## Coordinator reason strings in plain words; unknown reasons are shown unchanged.
const REASON_TEXT := {
	"participant requested pause": "A player paused the game",
	"shared system pause": "The game is paused",
	"assigned device disconnected": "A controller was disconnected",
	"application focus lost": "The game window lost focus",
	"application focus changed": "The window changed - everybody ready up again",
	"device status changed": "A controller changed - everybody ready up again",
}

var rosters: Array[UiScoreRow] = []
var _missing_seats: Array[int] = []
var _last_countdown_whole := -1
var _accept_guard_frame := -1
var _coordinator: PauseRecoveryCoordinator
var _registry: PlayerSeatRegistry
var _map: UiPromptMap
var _device := "k1"

@onready var _owner_badge: UiPlayerBadge = %OwnerBadge
@onready var _owner_label: Label = %OwnerLabel
@onready var _reason_label: Label = %ReasonLabel
@onready var _countdown_label: Label = %CountdownLabel
@onready var _menu: UiMenuList = %MenuList
@onready var _reclaim_panel: Control = %ReclaimPanel
@onready var _reclaim_label: Label = %ReclaimLabel
@onready var _leave_confirm: UiConfirmDialog = %LeaveConfirm
@onready var _resume_button: Button = %ResumeButton
@onready var _settings_button: Button = %SettingsButton
@onready var _library_button: Button = %LibraryButton
@onready var _leave_button: Button = %LeaveButton
@onready var _skip_tutorial_button: Button = %SkipTutorialButton


func state_names() -> PackedStringArray:
	return PackedStringArray(
		["Paused", "Ready-up", "Resume countdown", "Device lost", "Leave confirm"]
	)


func router_phase() -> int:
	return LocalInputRouter.Phase.PAUSE


## Generic binder used by the gallery and by the live coordinator.
func bind_state(
	reason: String, owner: int, countdown: float, seats: Array[Dictionary], status: Dictionary
) -> void:
	owner_seat = owner
	_reason_label.text = reason
	var owner_data: Dictionary = {}
	for seat in seats:
		if int(seat.seat) == owner:
			owner_data = seat
	_owner_badge.bind_seat(owner_data)
	_owner_badge.visible = not owner_data.is_empty()
	_owner_label.text = (
		"Paused by" if not owner_data.is_empty() else "Shared pause - any player can take the menu"
	)
	var missing: Array[int] = []
	for index in rosters.size():
		var seat: Dictionary = seats[index] if index < seats.size() else {}
		var text := "READY" if bool(seat.get("ready", false)) else "WAITING"
		if not seat.is_empty() and not bool(seat.get("connected", true)):
			text = "DEVICE LOST"
			missing.append(int(seat.seat))
		rosters[index].bind_roster(seat, text)
	_missing_seats = missing
	_countdown_label.visible = countdown > 0.0
	_countdown_label.text = "Resuming in %d" % int(ceilf(countdown))
	_reclaim_panel.visible = not missing.is_empty()
	if not missing.is_empty():
		var target := int(status.get("reclaim_seat", missing[0]))
		_reclaim_label.text = (
			"Seat %d lost its controller. Press %s on the new controller to take the seat back."
			% [target + 1, _map.glyph("confirm", "gamepad") if _map != null else "South"]
		)
		if missing.size() > 1:
			_reclaim_label.text += " Left / Right picks another missing seat."
	_menu.refresh_items()
	if bool(status.get("leave_confirm", false)):
		# Keep the dialog's selection when a refresh arrives while it is already open.
		if not _leave_confirm.is_open():
			_leave_confirm.open("Leave the match and return to the lobby?")
	else:
		_leave_confirm.close()


static func reason_text(reason: String) -> String:
	return str(REASON_TEXT.get(reason.to_lower(), reason))


## The presenter calls this when a ready edge or device change happens while paused.
func refresh_live() -> void:
	_refresh_live()


func bind_prompts(map: UiPromptMap, device_kind: String) -> void:
	_map = map
	_device = device_kind


## Live binding to the existing pause/reconnect logic (display only).
func bind_coordinator(
	coordinator: PauseRecoveryCoordinator, registry: PlayerSeatRegistry, map: UiPromptMap
) -> void:
	_unbind_coordinator()
	_coordinator = coordinator
	_registry = registry
	_map = map
	coordinator.pause_state_changed.connect(_on_coordinator_changed)
	coordinator.countdown_changed.connect(_on_coordinator_countdown)
	coordinator.menu_selection_changed.connect(_on_coordinator_selection)
	_refresh_live()


func _on_screen_ready() -> void:
	rosters = [%Roster1, %Roster2, %Roster3, %Roster4]
	_resume_button.pressed.connect(func() -> void: resume_requested.emit())
	_settings_button.pressed.connect(func() -> void: settings_requested.emit())
	_library_button.pressed.connect(func() -> void: library_requested.emit())
	_leave_button.pressed.connect(_on_leave_pressed)
	_skip_tutorial_button.pressed.connect(func() -> void: skip_tutorial_requested.emit())
	_leave_confirm.confirmed.connect(func() -> void: leave_confirmed.emit())
	_leave_confirm.cancelled.connect(func() -> void: _menu.set_active(true))
	_menu.refresh_items()


func _exit_tree() -> void:
	_unbind_coordinator()


func _show_state(index: int, ctx: UiContext) -> void:
	bind_prompts(ctx.prompt_map, ctx.device_kind)
	var seats := ctx.seats.duplicate(true)
	var reasons := [
		"Participant requested pause",
		"Everyone must be ready to resume",
		"Everyone is ready",
		"Assigned device disconnected",
		"Participant requested pause",
	]
	for seat in seats:
		seat.ready = false
	if index >= 1:
		for seat in seats:
			if bool(seat.joined):
				seat.ready = true
	if index == 1 and not seats.is_empty():
		seats[0].ready = false
	if index == 3 and ctx.player_count >= 2:
		seats[1].connected = false
		seats[1].ready = false
	var countdown := 3.0 if index == 2 else 0.0
	bind_state(
		reasons[clampi(index, 0, reasons.size() - 1)],
		ctx.owner_seat,
		countdown,
		seats,
		{"leave_confirm": index == 4}
	)


## Only the pause owner drives this menu. A shared pause (no owner yet) accepts nobody; the
## coordinator hands the menu to the first fresh confirm.
func accepts_seat(seat_index: int) -> bool:
	return owner_seat >= 0 and seat_index == owner_seat


func _navigate(_seat_index: int, direction: String) -> bool:
	if _leave_confirm.is_open():
		return _leave_confirm.navigate(direction)
	if direction in ["left", "right"] and _missing_seats.size() > 1 and _coordinator != null:
		var index := _missing_seats.find(_coordinator.selected_reclaim_seat)
		index = posmod(index + (-1 if direction == "left" else 1), _missing_seats.size())
		_coordinator.choose_reclaim_seat(_missing_seats[index])
		_refresh_live()
		return true
	return _menu.move(direction)


func _accept(_seat_index: int) -> bool:
	# The confirm that handed a shared pause to its owner must not also activate an entry.
	if Engine.get_process_frames() == _accept_guard_frame:
		return false
	if _leave_confirm.is_open():
		return _leave_confirm.accept()
	return _menu.activate()


func _back(_seat_index: int) -> bool:
	if _leave_confirm.is_open():
		_leave_confirm.cancel()
		return true
	_menu.select(0)
	return true


## The entry is appended after Leave and hidden unless a guided tutorial is active.
func set_skip_tutorial_available(available: bool) -> void:
	if _skip_tutorial_button.visible == available:
		return
	_skip_tutorial_button.visible = available
	_menu.refresh_items()


func _on_leave_pressed() -> void:
	_menu.set_active(false)
	_leave_confirm.open("Leave the match and return to the lobby?")


func _refresh_live() -> void:
	if _coordinator == null or _registry == null:
		return
	var seats: Array[Dictionary] = []
	for index in PlayerSeatRegistry.MAX_SEATS:
		seats.append(_registry.get_seat(index))
	var status := {"leave_confirm": _leave_confirm.is_open()}
	var missing: Array[int] = []
	for seat in seats:
		if bool(seat.get("joined", false)) and not bool(seat.get("connected", true)):
			missing.append(int(seat.seat))
	if not missing.is_empty():
		var chosen := _coordinator.selected_reclaim_seat
		if not missing.has(chosen):
			chosen = missing[0]
			_coordinator.choose_reclaim_seat(chosen)
		status["reclaim_seat"] = chosen
	var countdown := _coordinator.countdown_remaining
	bind_state(
		reason_text(_coordinator.pause_reason), _coordinator.menu_owner, countdown, seats, status
	)


func _unbind_coordinator() -> void:
	if _coordinator == null or not is_instance_valid(_coordinator):
		_coordinator = null
		return
	if _coordinator.pause_state_changed.is_connected(_on_coordinator_changed):
		_coordinator.pause_state_changed.disconnect(_on_coordinator_changed)
	if _coordinator.countdown_changed.is_connected(_on_coordinator_countdown):
		_coordinator.countdown_changed.disconnect(_on_coordinator_countdown)
	if _coordinator.menu_selection_changed.is_connected(_on_coordinator_selection):
		_coordinator.menu_selection_changed.disconnect(_on_coordinator_selection)
	_coordinator = null


func _on_coordinator_changed(_paused: bool, _reason: String) -> void:
	_refresh_live()


func _on_coordinator_countdown(seconds: float) -> void:
	var whole := ceili(seconds)
	if whole == _last_countdown_whole:
		return
	_last_countdown_whole = whole
	_refresh_live()


func _on_coordinator_selection(_index: int, new_owner: int) -> void:
	if owner_seat < 0 and new_owner >= 0:
		_accept_guard_frame = Engine.get_process_frames()
	_refresh_live()

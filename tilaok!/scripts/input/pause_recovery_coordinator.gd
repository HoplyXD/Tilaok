# gdlint: disable=max-returns
class_name PauseRecoveryCoordinator
extends Node

signal pause_state_changed(paused: bool, reason: String)
signal countdown_changed(seconds_remaining: float)
signal reclaim_prompted(device_id: int, missing_seats: Array[int])
signal menu_selection_changed(index: int, owner_seat: int)
signal reclaim_menu_requested
signal recovery_complete

enum State { RUNNING, PAUSED, COUNTDOWN }

@export var input_router: LocalInputRouter
@export var resume_countdown_seconds := 3.0
## When true the pause menu is drawn by a scene (UiPauseScreen): the owner's confirm no longer
## readies the owner implicitly. Default false keeps the P02 behaviour exactly.
@export var external_menu := false
var authority := SimulationAuthority.offline()
var state := State.RUNNING
var pause_reason := ""
var menu_owner := -1
var selected_reclaim_seat := -1
var countdown_remaining := 0.0
var menu_selection := 0
var _pending_reclaim_device := -1
var _phase_before_pause := LocalInputRouter.Phase.PLAY


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if input_router != null:
		input_router.pause_requested.connect(_on_pause_requested)
		input_router.seat_disconnected.connect(_on_seat_disconnected)
		input_router.device_status_changed.connect(_on_device_status_changed)
		input_router.action_pressed.connect(_on_action_pressed)
		input_router.navigation_step.connect(_on_navigation_step)


func _exit_tree() -> void:
	if input_router == null:
		return
	if input_router.pause_requested.is_connected(_on_pause_requested):
		input_router.pause_requested.disconnect(_on_pause_requested)
	if input_router.seat_disconnected.is_connected(_on_seat_disconnected):
		input_router.seat_disconnected.disconnect(_on_seat_disconnected)
	if input_router.device_status_changed.is_connected(_on_device_status_changed):
		input_router.device_status_changed.disconnect(_on_device_status_changed)
	if input_router.action_pressed.is_connected(_on_action_pressed):
		input_router.action_pressed.disconnect(_on_action_pressed)
	if input_router.navigation_step.is_connected(_on_navigation_step):
		input_router.navigation_step.disconnect(_on_navigation_step)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if state == State.COUNTDOWN:
			_cancel_countdown("application focus lost")
		elif state == State.PAUSED:
			_clear_readiness()
		else:
			set_paused("application focus lost", -1)
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		if state == State.COUNTDOWN:
			_cancel_countdown("application focus changed")
		elif state == State.PAUSED:
			_clear_readiness()


func _process(delta: float) -> void:
	if state != State.COUNTDOWN or not _can_global_pause():
		return
	countdown_remaining = maxf(0.0, countdown_remaining - delta)
	countdown_changed.emit(countdown_remaining)
	if countdown_remaining <= 0.0:
		state = State.RUNNING
		pause_reason = ""
		menu_owner = -1
		get_tree().paused = false
		input_router.resume_system()
		input_router.set_phase(_phase_before_pause)
		pause_state_changed.emit(false, "resumed")
		recovery_complete.emit()


func set_paused(reason: String, owner_seat: int) -> void:
	if state != State.RUNNING or not _can_global_pause():
		return
	_phase_before_pause = (
		input_router.phase if input_router != null else LocalInputRouter.Phase.PLAY
	)
	state = State.PAUSED
	pause_reason = reason
	menu_owner = owner_seat
	menu_selection = 0
	countdown_remaining = 0.0
	_clear_readiness()
	if input_router != null:
		input_router.pause_system()
		input_router.set_phase(LocalInputRouter.Phase.PAUSE)
	pause_state_changed.emit(true, reason)


func request_resume() -> bool:
	if state != State.PAUSED or input_router == null or not _can_global_pause():
		return false
	if not _resume_ready():
		return false
	state = State.COUNTDOWN
	countdown_remaining = resume_countdown_seconds
	countdown_changed.emit(countdown_remaining)
	return true


## Fresh ready for one seat from an external pause menu (the owner's Resume entry).
func mark_ready(seat_index: int) -> bool:
	if state != State.PAUSED or input_router == null:
		return false
	if not input_router.registry.set_ready(seat_index, true):
		return false
	if _resume_ready():
		request_resume()
	return true


func choose_reclaim_seat(seat_index: int) -> bool:
	if state != State.PAUSED or input_router == null:
		return false
	var seat := input_router.registry.get_seat(seat_index)
	if seat.is_empty() or not seat.joined or seat.connected:
		return false
	selected_reclaim_seat = seat_index
	return true


func reclaim_device(device_id: int) -> bool:
	if state != State.PAUSED or input_router == null or selected_reclaim_seat < 0:
		return false
	if not input_router.registry.reclaim_gamepad(selected_reclaim_seat, device_id):
		return false
	selected_reclaim_seat = -1
	_pending_reclaim_device = -1
	_clear_readiness()
	return true


func confirm_reclaim() -> bool:
	if _pending_reclaim_device < 0:
		return false
	return reclaim_device(_pending_reclaim_device)


func cancel_for_status_change(reason: String) -> void:
	if state == State.COUNTDOWN:
		_cancel_countdown(reason)
	elif state == State.PAUSED:
		_clear_readiness()


func _on_pause_requested(seat_index: int) -> void:
	if not _can_global_pause():
		return
	if state == State.RUNNING:
		set_paused("participant requested pause", seat_index)
	elif state == State.PAUSED and menu_owner < 0:
		menu_owner = seat_index


func _on_seat_disconnected(_seat_index: int) -> void:
	if state == State.COUNTDOWN:
		_cancel_countdown("assigned device disconnected")
	else:
		set_paused("assigned device disconnected", -1)


func _on_device_status_changed(_device_id: int, _connected: bool) -> void:
	if state == State.COUNTDOWN:
		_cancel_countdown("device status changed")
	elif state == State.PAUSED:
		_clear_readiness()


func _on_action_pressed(seat_index: int, action_name: String) -> void:
	if action_name.begins_with("select_reclaim_device:"):
		var device_id := int(action_name.get_slice(":", 1))
		if device_id == _pending_reclaim_device and selected_reclaim_seat >= 0:
			confirm_reclaim()
			return
		_pending_reclaim_device = device_id
		if selected_reclaim_seat >= 0:
			confirm_reclaim()
			return
		var missing := _missing_seats()
		reclaim_prompted.emit(_pending_reclaim_device, missing)
		return
	if action_name == "system_pause" and state == State.RUNNING:
		set_paused("shared system pause", -1)
		return
	if state != State.PAUSED:
		return
	if menu_owner < 0 and action_name == "confirm":
		menu_owner = seat_index
		menu_selection = 0
		menu_selection_changed.emit(menu_selection, menu_owner)
		return
	if seat_index != menu_owner and menu_owner >= 0:
		if action_name in ["ready", "confirm"]:
			input_router.registry.set_ready(seat_index, true)
			if _resume_ready():
				request_resume()
		return
	if external_menu and seat_index == menu_owner:
		# An external pause menu owns the owner's confirm; its Resume entry calls mark_ready().
		return
	if action_name == "confirm" or action_name == "ready":
		if seat_index == menu_owner and menu_selection == 1:
			reclaim_menu_requested.emit()
			return
		input_router.registry.set_ready(seat_index, true)
		if _resume_ready():
			request_resume()


func _on_navigation_step(seat_index: int, direction: String) -> void:
	if state != State.PAUSED or menu_owner < 0 or seat_index != menu_owner:
		return
	if direction not in ["up", "down"]:
		return
	menu_selection = 1 - menu_selection
	menu_selection_changed.emit(menu_selection, menu_owner)


func _resume_ready() -> bool:
	return input_router.registry.all_joined_ready_and_connected()


func _missing_seats() -> Array[int]:
	var result: Array[int] = []
	if input_router == null:
		return result
	for seat in input_router.registry.joined_seats():
		if not seat.connected:
			result.append(int(seat.seat))
	return result


func _clear_readiness() -> void:
	if input_router == null:
		return
	for seat in input_router.registry.joined_seats():
		input_router.registry.set_ready(int(seat.seat), false)


func _cancel_countdown(reason: String) -> void:
	state = State.PAUSED
	countdown_remaining = 0.0
	pause_reason = reason
	_clear_readiness()
	if input_router != null:
		input_router.resume_system()
		input_router.pause_system()
		input_router.set_phase(LocalInputRouter.Phase.PAUSE)
	countdown_changed.emit(0.0)
	pause_state_changed.emit(true, reason)


func _can_global_pause() -> bool:
	return authority != null and authority.can_commit()

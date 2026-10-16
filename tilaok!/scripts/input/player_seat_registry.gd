class_name PlayerSeatRegistry
extends RefCounted

const MAX_SEATS := 4
## Shared-keyboard layouts (see LocalInputRouter._keyboard_layout_for_key).
const KEYBOARD_LAYOUTS := ["K1", "K2", "K3", "K4"]
const SHAPES := ["CIRCLE", "TRIANGLE", "SQUARE", "DIAMOND"]
const COLORS := [Color("#f2c14e"), Color("#63a7ff"), Color("#f07c6c"), Color("#89c77b")]

var _seats: Array[Dictionary] = []


func _init() -> void:
	for index in MAX_SEATS:
		(
			_seats
			. append(
				{
					"seat": index,
					"identity": index + 1,
					"shape": SHAPES[index],
					"color": COLORS[index],
					"joined": false,
					"connected": false,
					"device_kind": "",
					"device_id": -1,
					"keyboard_layout": "",
					"ready": false,
				}
			)
		)


func join_gamepad(device_id: int) -> int:
	if seat_for_gamepad(device_id) >= 0:
		return -1
	var index := _first_empty_seat()
	if index < 0:
		return -1
	var seat: Dictionary = _seats[index]
	seat.joined = true
	seat.connected = true
	seat.device_kind = "gamepad"
	seat.device_id = device_id
	return index


func join_keyboard(layout: String) -> int:
	if layout not in KEYBOARD_LAYOUTS or seat_for_keyboard(layout) >= 0:
		return -1
	var index := _first_empty_seat()
	if index < 0:
		return -1
	var seat: Dictionary = _seats[index]
	seat.joined = true
	seat.connected = true
	seat.device_kind = "keyboard"
	seat.keyboard_layout = layout
	return index


func seat_for_gamepad(device_id: int) -> int:
	for seat in _seats:
		if (
			seat.joined
			and seat.connected
			and seat.device_kind == "gamepad"
			and seat.device_id == device_id
		):
			return int(seat.seat)
	return -1


func seat_for_keyboard(layout: String) -> int:
	for seat in _seats:
		if seat.joined and seat.device_kind == "keyboard" and seat.keyboard_layout == layout:
			return int(seat.seat)
	return -1


func disconnect_gamepad(device_id: int) -> int:
	var index := seat_for_gamepad(device_id)
	if index >= 0:
		_seats[index].connected = false
		_seats[index].ready = false
	return index


func reclaim_gamepad(seat_index: int, device_id: int) -> bool:
	if seat_index < 0 or seat_index >= _seats.size():
		return false
	if seat_for_gamepad(device_id) >= 0:
		return false
	var seat: Dictionary = _seats[seat_index]
	if not seat.joined or seat.connected or seat.device_kind != "gamepad":
		return false
	seat.device_id = device_id
	seat.connected = true
	seat.ready = false
	return true


func set_ready(seat_index: int, value: bool) -> bool:
	if seat_index < 0 or seat_index >= _seats.size():
		return false
	if not _seats[seat_index].joined or not _seats[seat_index].connected:
		return false
	_seats[seat_index].ready = value
	return true


func get_seat(seat_index: int) -> Dictionary:
	if seat_index < 0 or seat_index >= _seats.size():
		return {}
	return _seats[seat_index].duplicate(true)


func joined_seats() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for seat in _seats:
		if seat.joined:
			result.append(seat.duplicate(true))
	return result


func all_joined_ready_and_connected() -> bool:
	var count := 0
	for seat in _seats:
		if seat.joined:
			count += 1
			if not seat.connected or not seat.ready:
				return false
	return count >= 2


func clear_to_lobby() -> void:
	for index in MAX_SEATS:
		_seats[index].joined = false
		_seats[index].connected = false
		_seats[index].device_kind = ""
		_seats[index].device_id = -1
		_seats[index].keyboard_layout = ""
		_seats[index].ready = false


func _first_empty_seat() -> int:
	for seat in _seats:
		if not seat.joined:
			return int(seat.seat)
	return -1

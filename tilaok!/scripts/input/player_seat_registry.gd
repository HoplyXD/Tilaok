class_name PlayerSeatRegistry
extends RefCounted

const MAX_SEATS := 4
const MAX_REMOTE_SOURCE_ID_LENGTH := 64
## Shared-keyboard layouts (see LocalInputRouter._keyboard_layout_for_key).
const KEYBOARD_LAYOUTS := ["K1", "K2", "K3", "K4"]
const SHAPES := ["CIRCLE", "TRIANGLE", "SQUARE", "DIAMOND"]
const COLORS := [Color("#f2c14e"), Color("#63a7ff"), Color("#f07c6c"), Color("#89c77b")]

var authority := SimulationAuthority.offline()
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
					"remote_source_id": "",
					"ready": false,
				}
			)
		)


func join_gamepad(device_id: int) -> int:
	if not _can_mutate():
		return -1
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
	if not _can_mutate():
		return -1
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


## Host-only caller chooses the seat. Remote input never supplies a seat index.
func assign_remote_source(
	source_id: String, preferred_seat: int, authority: SimulationAuthority
) -> int:
	if (
		authority == null
		or not authority.can_commit()
		or authority.role != SimulationAuthority.Role.HOST_AUTHORITY
		or not _valid_remote_source_id(source_id)
		or seat_for_remote_source(source_id) >= 0
	):
		return -1
	var index := preferred_seat if preferred_seat >= 0 else _first_empty_seat()
	if index < 0 or index >= _seats.size():
		return -1
	var seat: Dictionary = _seats[index]
	if seat.joined:
		return -1
	seat.joined = true
	seat.connected = true
	seat.device_kind = "remote"
	seat.remote_source_id = source_id
	return index


func seat_for_remote_source(source_id: String) -> int:
	for seat in _seats:
		if (
			seat.joined
			and seat.connected
			and seat.device_kind == "remote"
			and seat.remote_source_id == source_id
		):
			return int(seat.seat)
	return -1


func revoke_remote_source(source_id: String, authority: SimulationAuthority) -> bool:
	if (
		authority == null
		or not authority.can_commit()
		or authority.role != SimulationAuthority.Role.HOST_AUTHORITY
	):
		return false
	var index := seat_for_remote_source(source_id)
	if index < 0:
		return false
	var seat: Dictionary = _seats[index]
	seat.connected = false
	seat.ready = false
	seat.remote_source_id = ""
	return true


## Lobby transport loss releases the remote seat completely. During a network match the host
## reserves it instead (`revoke_remote_source`, then `reclaim_remote_source`; NLB-P08).
func release_remote_source(source_id: String, authority: SimulationAuthority) -> bool:
	if (
		authority == null
		or not authority.can_commit()
		or authority.role != SimulationAuthority.Role.HOST_AUTHORITY
	):
		return false
	var index := seat_for_remote_source(source_id)
	if index < 0:
		return false
	var seat: Dictionary = _seats[index]
	seat.joined = false
	seat.connected = false
	seat.ready = false
	seat.device_kind = ""
	seat.device_id = -1
	seat.keyboard_layout = ""
	seat.remote_source_id = ""
	return true


## NLB-P09 replay: frees a reserved or lost remote seat by index once the roster is rebuilt for the
## next match. Only a disconnected remote seat qualifies; a connected or local seat is never touched.
func release_unconnected_remote_seat(seat_index: int, authority: SimulationAuthority) -> bool:
	if (
		authority == null
		or not authority.can_commit()
		or authority.role != SimulationAuthority.Role.HOST_AUTHORITY
		or seat_index < 0
		or seat_index >= _seats.size()
	):
		return false
	var seat: Dictionary = _seats[seat_index]
	if not seat.joined or seat.connected or seat.device_kind != "remote":
		return false
	seat.joined = false
	seat.ready = false
	seat.device_kind = ""
	seat.device_id = -1
	seat.keyboard_layout = ""
	seat.remote_source_id = ""
	return true


## Host-only. Rebinds a reserved remote seat (joined, disconnected, device "remote") to a new
## source after the reclaim proof, snapshot ack and neutral sample. The seat is never chosen by the
## remote peer and a seat that is not reserved cannot be taken by this path.
func reclaim_remote_source(
	source_id: String, seat_index: int, authority: SimulationAuthority
) -> bool:
	if (
		authority == null
		or not authority.can_commit()
		or authority.role != SimulationAuthority.Role.HOST_AUTHORITY
		or not _valid_remote_source_id(source_id)
		or seat_for_remote_source(source_id) >= 0
		or seat_index < 0
		or seat_index >= _seats.size()
	):
		return false
	var seat: Dictionary = _seats[seat_index]
	if not seat.joined or seat.connected or seat.device_kind != "remote":
		return false
	seat.connected = true
	seat.ready = false
	seat.remote_source_id = source_id
	return true


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
	if not _can_mutate():
		return -1
	var index := seat_for_gamepad(device_id)
	if index >= 0:
		_seats[index].connected = false
		_seats[index].ready = false
	return index


func reclaim_gamepad(seat_index: int, device_id: int) -> bool:
	if not _can_mutate():
		return false
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
	if not _can_mutate():
		return false
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
	if not _can_mutate():
		return
	for index in MAX_SEATS:
		_seats[index].joined = false
		_seats[index].connected = false
		_seats[index].device_kind = ""
		_seats[index].device_id = -1
		_seats[index].keyboard_layout = ""
		_seats[index].remote_source_id = ""
		_seats[index].ready = false


func _first_empty_seat() -> int:
	for seat in _seats:
		if not seat.joined:
			return int(seat.seat)
	return -1


func _can_mutate() -> bool:
	return authority != null and authority.can_commit()


func _valid_remote_source_id(source_id: String) -> bool:
	if source_id.is_empty() or source_id.length() > MAX_REMOTE_SOURCE_ID_LENGTH:
		return false
	for index in source_id.length():
		var code := source_id.unicode_at(index)
		if not (
			code == 45
			or (code >= 48 and code <= 57)
			or (code >= 65 and code <= 90)
			or (code >= 95 and code <= 122)
		):
			return false
	return true

class_name UiLobbyScreen
extends UiScreen

signal ready_toggled(seat_index: int)
signal leave_requested(seat_index: int)

const MIN_PLAYERS := 2

var slots: Array[UiLobbySlot] = []
var seats: Array[Dictionary] = []

@onready var _need_players_label: Label = %NeedPlayersLabel
@onready var _start_hint: UiPromptGlyph = %StartHint
@onready var _back_hint: UiPromptGlyph = %BackHint


func state_names() -> PackedStringArray:
	return PackedStringArray(
		["Nobody joined", "One joined", "Two joined, one ready", "Four players", "Device lost"]
	)


func router_phase() -> int:
	return LocalInputRouter.Phase.LOBBY


## seats: four dictionaries shaped like PlayerSeatRegistry seats (joined/connected/ready/...).
func bind_seats(seat_data: Array[Dictionary], map: UiPromptMap, device_kind: String) -> void:
	seats = seat_data
	var joined := 0
	for index in slots.size():
		var seat: Dictionary = seat_data[index] if index < seat_data.size() else {}
		slots[index].bind(seat, map)
		if not seat.is_empty() and bool(seat.get("joined", false)):
			joined += 1
	_need_players_label.visible = joined < MIN_PLAYERS
	_start_hint.bind("ready", device_kind, map)
	_back_hint.bind("back", device_kind, map)


func joined_count() -> int:
	var count := 0
	for slot in slots:
		if slot.badge.seat_number > 0:
			count += 1
	return count


func _on_screen_ready() -> void:
	slots = [%Slot1, %Slot2, %Slot3, %Slot4]


func _show_state(index: int, ctx: UiContext) -> void:
	var counts := [0, 1, 2, 4, 3]
	var sample := UiContext.sample_seats(counts[clampi(index, 0, counts.size() - 1)])
	for seat in sample:
		seat.ready = false
	if index == 2:
		sample[0].ready = true
	if index == 3:
		sample[0].ready = true
		sample[2].ready = true
	if index == 4:
		sample[2].connected = false
	bind_seats(sample, ctx.prompt_map, ctx.device_kind)


func _accept(seat_index: int) -> bool:
	ready_toggled.emit(seat_index)
	return true


func _back(seat_index: int) -> bool:
	leave_requested.emit(seat_index)
	back_requested.emit()
	return true

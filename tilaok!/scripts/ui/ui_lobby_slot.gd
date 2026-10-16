class_name UiLobbySlot
extends PanelContainer

## One of four lobby join slots. Empty slots tell the player which key joins on each device.

const FRAME_NORMAL := &"SlotPanel"
const FRAME_READY := &"SlotPanelReady"

@onready var badge: UiPlayerBadge = %Badge
@onready var _state_label: Label = %StateLabel
@onready var _device_label: Label = %DeviceLabel


func bind(seat: Dictionary, map: UiPromptMap) -> void:
	badge.bind_seat(seat)
	var joined := not seat.is_empty() and bool(seat.get("joined", false))
	var is_ready := joined and bool(seat.get("ready", false))
	theme_type_variation = FRAME_READY if is_ready else FRAME_NORMAL
	if not joined:
		_state_label.text = "OPEN SLOT"
		_device_label.text = _join_hint(map)
		return
	if not bool(seat.get("connected", true)):
		_state_label.text = "DEVICE LOST"
	else:
		_state_label.text = "READY" if is_ready else "NOT READY"
	_device_label.text = _device_name(seat)


func state_text() -> String:
	return _state_label.text


func device_text() -> String:
	return _device_label.text


func _device_name(seat: Dictionary) -> String:
	if str(seat.get("device_kind", "")) == "gamepad":
		return "Gamepad %d" % (int(seat.get("device_id", 0)) + 1)
	var kind := str(seat.get("keyboard_layout", "")).to_lower()
	return str(UiLibraryText.DEVICE_LABELS.get(kind, "Keyboard %s" % kind.to_upper()))


func _join_hint(map: UiPromptMap) -> String:
	if map == null:
		return "Press ready to join"
	var keys := PackedStringArray()
	for kind in ["k1", "k3", "k2", "k4"]:
		keys.append(map.glyph("ready", kind))
	return "Press %s or %s to join" % [", ".join(keys), map.glyph("ready", "gamepad")]

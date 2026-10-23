class_name UiLobbySlot
extends PanelContainer

## One of four lobby join slots. Empty slots tell the player which key joins on each device.

const FRAME_NORMAL := &"SlotPanel"
const FRAME_READY := &"SlotPanelReady"
const OPEN_BADGE_ALPHA := 0.45
const EMPTY_CHICKEN_TINT := Color("#898989")
const EMPTY_CHICKEN_ALPHA := 0.38

@onready var badge: UiPlayerBadge = %Badge
@onready var _state_label: Label = %StateLabel
@onready var _device_label: Label = %DeviceLabel
@onready var _preview_chicken: ChickenController = %PreviewChicken


func bind(seat: Dictionary, map: UiPromptMap) -> void:
	badge.bind_seat(seat)
	var joined := not seat.is_empty() and bool(seat.get("joined", false))
	var is_ready := joined and bool(seat.get("ready", false))
	var seat_index := clampi(get_index(), 0, PlayerSeatRegistry.MAX_SEATS - 1)
	_preview_chicken.identity_number = int(seat.get("identity", seat_index + 1))
	_preview_chicken.identity_shape = str(seat.get("shape", PlayerSeatRegistry.SHAPES[seat_index]))
	_preview_chicken.marker_color = (
		seat.get("color", PlayerSeatRegistry.COLORS[seat_index]) if joined else EMPTY_CHICKEN_TINT
	)
	_preview_chicken.modulate.a = 1.0 if joined else EMPTY_CHICKEN_ALPHA
	_preview_chicken.queue_redraw()
	theme_type_variation = FRAME_READY if is_ready else FRAME_NORMAL
	# An open slot previews its fixed number + shape, faded, above the "Open slot" text.
	badge.modulate.a = 1.0 if joined else OPEN_BADGE_ALPHA
	if not joined:
		badge.bind_preview(seat)
		_state_label.text = "Open slot"
		_device_label.text = _join_hint(map)
		return
	if not bool(seat.get("connected", true)):
		_state_label.text = "Device lost"
	else:
		_state_label.text = "Ready" if is_ready else "Not Ready"
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

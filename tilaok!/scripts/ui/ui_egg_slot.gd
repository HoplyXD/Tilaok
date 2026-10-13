class_name UiEggSlot
extends PanelContainer

## Frame around one egg. The animated item inside is the existing code-drawn ItemEggPreview
## (gameplay art); frame, owner badge and selected look are scene/Theme.

signal claimed(variant_key: String)

const FRAME_NORMAL := &"EggFrame"
const FRAME_SELECTED := &"EggFrameSelected"

var variant_key := ""
var preview: ItemEggPreview

@onready var _host: Control = %PreviewHost
@onready var _owner_badge: UiPlayerBadge = %OwnerBadge


func configure(
	definitions: ItemDefinitions, key: String, tuning: GameplayTuning, turns: int = 0
) -> bool:
	_clear_preview()
	var egg := ItemEggPreview.new()
	if not egg.configure(definitions, key, turns, tuning):
		egg.free()
		return false
	variant_key = key
	preview = egg
	_host.add_child(egg)
	egg.claimed.connect(_on_preview_claimed)
	_owner_badge.visible = false
	return true


func set_selected(value: bool) -> void:
	theme_type_variation = FRAME_SELECTED if value else FRAME_NORMAL
	if preview != null:
		preview.selected = value


## Shows who claimed this egg; an empty dictionary clears it.
func set_claim_owner(seat: Dictionary) -> void:
	_owner_badge.visible = not seat.is_empty()
	if not seat.is_empty():
		_owner_badge.bind_seat(seat)


func claim_owner_number() -> int:
	return _owner_badge.seat_number if _owner_badge.visible else 0


func _clear_preview() -> void:
	if preview != null and is_instance_valid(preview):
		preview.queue_free()
	preview = null


func _on_preview_claimed(key: String) -> void:
	claimed.emit(key)

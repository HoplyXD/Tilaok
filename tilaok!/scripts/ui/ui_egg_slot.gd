class_name UiEggSlot
extends Control

## One egg card in the Pugad nest (Figma "Obstacle Pick"): the team's egg art, the live item preview
## inside it (the code-drawn ItemEggPreview without its placeholder shell) and the pick pill naming
## who picked the egg ("✓ Picked") or who is choosing it ("Choosing…"). The card shows no item name
## or description (GDD: those belong in the Library). Look and layout live in the scene and Theme.

signal claimed(variant_key: String)

const PICKED_TEXT := "✓ Picked"
const CHOOSING_TEXT := "Choosing…"

var variant_key := ""
var preview: ItemEggPreview
var selected := false

@onready var _host: Control = %PreviewHost
@onready var _pill: PanelContainer = %Pill
@onready var _status: Label = %StatusLabel
@onready var _owner_badge: UiPlayerBadge = %OwnerBadge
@onready var _selectors: Array[UiPlayerBadge] = [%Selector1, %Selector2, %Selector3, %Selector4]


func configure(
	definitions: ItemDefinitions, key: String, tuning: GameplayTuning, turns: int = 0
) -> bool:
	_clear_preview()
	var egg := ItemEggPreview.new()
	egg.draw_shell = false
	if not egg.configure(definitions, key, turns, tuning):
		egg.free()
		return false
	variant_key = key
	preview = egg
	_host.add_child(egg)
	egg.claimed.connect(_on_preview_claimed)
	_owner_badge.visible = false
	for badge in _selectors:
		badge.visible = false
	_refresh_pill({})
	return true


func set_selected(value: bool) -> void:
	selected = value
	if preview != null:
		preview.selected = value


## Shows who claimed this egg; an empty dictionary clears it.
func set_claim_owner(seat: Dictionary) -> void:
	_owner_badge.visible = not seat.is_empty()
	if not seat.is_empty():
		_paint_badge(_owner_badge, seat, seat)
	_refresh_pill(seat)


## Live: the seats currently pointing at this egg (number + shape badges, colour supplementary).
func set_selectors(seats: Array[Dictionary]) -> void:
	var lead: Dictionary = seats[0] if not seats.is_empty() else {}
	for index in _selectors.size():
		var badge := _selectors[index]
		badge.visible = index < seats.size() and not _owner_badge.visible
		if badge.visible:
			_paint_badge(badge, seats[index], lead)
	if not _owner_badge.visible:
		_refresh_pill(lead)


## The pill's place on this card, copied from the nest layout marker (hand-placed in the frame).
func set_pill_rect(pill_position: Vector2, pill_size: Vector2, pill_rotation: float) -> void:
	_pill.position = pill_position
	_pill.size = pill_size
	_pill.rotation = pill_rotation


func selector_numbers() -> PackedInt32Array:
	var numbers := PackedInt32Array()
	for badge in _selectors:
		if badge.visible:
			numbers.append(badge.seat_number)
	return numbers


func claim_owner_number() -> int:
	return _owner_badge.seat_number if _owner_badge.visible else 0


func pill_text() -> String:
	return _status.text if _pill.visible else ""


## The pill takes the lead seat's colour (owner, else the first chooser) and reads Picked / Choosing.
func _refresh_pill(lead: Dictionary) -> void:
	_pill.visible = not lead.is_empty()
	if not _pill.visible:
		return
	_pill.theme_type_variation = StringName("EggPill%d" % (int(lead.get("seat", 0)) + 1))
	_status.text = PICKED_TEXT if _owner_badge.visible else CHOOSING_TEXT


## Shapes sit in the pill colour with their cream outline (frame detail); number + shape identify.
func _paint_badge(badge: UiPlayerBadge, seat: Dictionary, lead: Dictionary) -> void:
	var variation := StringName("EggPill%d" % (int(lead.get("seat", 0)) + 1))
	var box := _pill.get_theme_stylebox("panel", variation) as StyleBoxFlat
	if box != null:
		badge.plain_tint = box.bg_color
	badge.bind_seat(seat)


func _clear_preview() -> void:
	if preview != null and is_instance_valid(preview):
		preview.queue_free()
	preview = null


func _on_preview_claimed(key: String) -> void:
	claimed.emit(key)

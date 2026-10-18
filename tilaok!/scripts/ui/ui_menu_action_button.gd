@tool
class_name UiMenuActionButton
extends Button

## The menu button from the Figma "Menu actions" frame (103:562).
## Normal: cream plank, brown text. Selected (the router's highlighted entry): brown plank,
## 72 px tall instead of 54, cream text, the action icon and the pointer on its left.
##
## Every look lives in the Theme (`MenuAction*` types); this script only picks each node's type.
## - The button's own stylebox is the 1.5 px edge colour and `Face` (inset 1.5 px) is the fill,
##   because a stylebox border can only be whole pixels.
## - The button keeps its `text` (the Theme margins plus that text give the 54 / 72 px heights),
##   but the Theme draws it transparent. `ActionLabel` shows it with the icon, the two centred
##   together as in Figma; a Button's own icon would sit at its left edge instead.
## It runs in the editor so the Inspector's Text and Selected show up in the 2D view.

const BUTTON := &"MenuAction"
const BUTTON_SELECTED := &"MenuActionSelected"
const FACE := &"MenuActionFace"
const FACE_SELECTED := &"MenuActionFaceSelected"
const FACE_PRESSED := &"MenuActionFacePressed"
const INSET := &"MenuActionInset"
const INSET_SELECTED := &"MenuActionInsetSelected"
const FASTENING := &"MenuActionFastening"
const FASTENING_SELECTED := &"MenuActionFasteningSelected"
const SHADOW := &"MenuActionShadow"
const SHADOW_SELECTED := &"MenuActionShadowSelected"
const TEXT := &"MenuActionText"
const TEXT_SELECTED := &"MenuActionTextSelected"
const TEXT_DISABLED := &"MenuActionTextDisabled"

## The highlighted entry. UiMenuList sets it; tick it in the Inspector to preview the look.
@export var selected := false:
	set = set_selected
## Drawn before the text while selected (Figma: the play icon on Play). Leave empty for none.
@export var action_icon: Texture2D:
	set(value):
		action_icon = value
		queue_redraw()

@onready var _shadow: Control = $Shadow
@onready var _face: Control = $Face
@onready var _inset: Control = $Inset
@onready var _fastenings: Array[Control] = [$FasteningLeft, $FasteningRight]
@onready var _icon: TextureRect = $ActionLabel/Icon
@onready var _label: Label = $ActionLabel/Label
@onready var _pointer: Control = $Pointer


func set_selected(value: bool) -> void:
	selected = value
	if theme_type_variation != _button_type():
		theme_type_variation = _button_type()
	queue_redraw()


func _ready() -> void:
	set_selected(selected)


func _draw() -> void:
	# Text, hover, press and disable changes all redraw the button, so this keeps the children in step.
	if not is_node_ready():
		return
	var mode := get_draw_mode()
	var disabled_now := mode == DRAW_DISABLED
	var pressed_now := mode == DRAW_PRESSED or mode == DRAW_HOVER_PRESSED
	var on := selected and not disabled_now
	_set_type(_face, (FACE_PRESSED if pressed_now else FACE_SELECTED) if on else FACE)
	_set_type(_inset, INSET_SELECTED if on else INSET)
	_set_type(_shadow, SHADOW_SELECTED if on else SHADOW)
	for node in _fastenings:
		_set_type(node, FASTENING_SELECTED if on else FASTENING)
	_set_type(_label, TEXT_DISABLED if disabled_now else (TEXT_SELECTED if on else TEXT))
	if _label.text != text:
		_label.text = text
	if _icon.texture != action_icon:
		_icon.texture = action_icon
	_set_visible(_icon, on and action_icon != null)
	_set_visible(_pointer, on)


func _button_type() -> StringName:
	return BUTTON_SELECTED if selected else BUTTON


func _set_type(node: Control, type_name: StringName) -> void:
	if node.theme_type_variation != type_name:
		node.theme_type_variation = type_name


func _set_visible(node: Control, value: bool) -> void:
	if node.visible != value:
		node.visible = value

@tool
class_name UiLibraryTabButton
extends Button

## The Library's plank button (Figma "Menu control", Library frame 133:1205).
## Normal: brown plank with dark rivets. Selected (the router's highlighted entry): dark teal plank,
## teal edge and cream rivets. Current (the open category, when the cursor is elsewhere): a shaded,
## darker brown plank. The text is cream in all three.
##
## Every look lives in the Theme (`LibraryTab*` types); this script only picks each node's type.
## - The button's own stylebox is the 1.5 px edge colour and `Face` (inset 1.5 px) is the fill,
##   because a stylebox border can only be whole pixels.
## - The Theme draws the button's own text transparent; `Content` shows it, with the optional icon
##   centred beside it as in Figma (a Button's own icon would sit at its left edge).
## It runs in the editor so the Inspector's Text, Selected, Current and Icon show up in the 2D view.

const BUTTON := &"LibraryTab"
const BUTTON_SELECTED := &"LibraryTabSelected"
const FACE := &"LibraryTabFace"
const FACE_CURRENT := &"LibraryTabFaceCurrent"
const FACE_SELECTED := &"LibraryTabFaceSelected"
const RIVET := &"LibraryTabRivet"
const RIVET_SELECTED := &"LibraryTabRivetSelected"

## The highlighted entry. UiMenuList sets it; tick it in the Inspector to preview the look.
@export var selected := false:
	set = set_selected
## The open page of its list (the Library's chosen category), shown shaded. The selected look wins
## while the cursor is on it.
@export var current := false:
	set(value):
		current = value
		queue_redraw()
## Drawn before the text (Figma: the chevron on Back). Leave empty for a text-only plank.
@export var action_icon: Texture2D:
	set(value):
		action_icon = value
		queue_redraw()

@onready var _face: Control = $Face
@onready var _rivets: Array[Control] = [$RivetLeft, $RivetRight]
@onready var _icon: TextureRect = $Content/Icon
@onready var _label: Label = $Content/Label


func set_selected(value: bool) -> void:
	selected = value
	var type_name := BUTTON_SELECTED if selected else BUTTON
	if theme_type_variation != type_name:
		theme_type_variation = type_name
	queue_redraw()


func label_text() -> String:
	return _label.text if is_node_ready() else text


func _ready() -> void:
	set_selected(selected)


func _draw() -> void:
	# Text and selection changes redraw the button, so this keeps the children in step.
	if not is_node_ready():
		return
	_set_type(_face, FACE_SELECTED if selected else (FACE_CURRENT if current else FACE))
	for rivet in _rivets:
		_set_type(rivet, RIVET_SELECTED if selected else RIVET)
	if _label.text != text:
		_label.text = text
	if _icon.texture != action_icon:
		_icon.texture = action_icon
	var has_icon := action_icon != null
	if _icon.visible != has_icon:
		_icon.visible = has_icon
	# Text alone fills the plank and trims long names; with an icon the pair is centred together,
	# so the label keeps its full width (a trimmed label is only as wide as its ellipsis).
	var label_flags := Control.SIZE_SHRINK_CENTER if has_icon else Control.SIZE_EXPAND_FILL
	if _label.size_flags_horizontal != label_flags:
		_label.size_flags_horizontal = label_flags
		_label.clip_text = not has_icon
		_label.text_overrun_behavior = (
			TextServer.OVERRUN_NO_TRIMMING if has_icon else TextServer.OVERRUN_TRIM_ELLIPSIS
		)


func _set_type(node: Control, type_name: StringName) -> void:
	if node.theme_type_variation != type_name:
		node.theme_type_variation = type_name

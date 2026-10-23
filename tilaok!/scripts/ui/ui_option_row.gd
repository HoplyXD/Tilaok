@tool
class_name UiOptionRow
extends Panel

## A Settings row (Figma "Settings" frame, 892 x 54): a name, then either named choices between two
## arrow boxes or a 0..1 level (10 % steps) on a slider with its percentage. The selected row (the
## router's highlighted entry) has the brown edge, the darker fill and the pointer before its name.
##
## Every look lives in the Theme (`Settings*` types) and the scene; this script picks the edge type,
## shows the matching face and pointer, and moves the slider's fill and knob by their anchors.
## It runs in the editor so the Inspector's Row Title, Choices and Selected show up in the 2D view.

signal choice_changed(index: int)
signal level_changed(level: float)

const LEVEL_STEP := 0.1
const EDGE := &"SettingsRowEdge"
const EDGE_SELECTED := &"SettingsRowEdgeSelected"

@export var row_title := "":
	set(value):
		row_title = value
		_refresh()
@export var choices := PackedStringArray():
	set(value):
		choices = value
		_refresh()
## The highlighted row. UiMenuList sets it; tick it in the Inspector to preview the look.
@export var selected := false:
	set = set_selected

var index := 0
var level := 1.0

@onready var _face: Control = $Face
@onready var _face_selected: Control = $FaceSelected
@onready var _pointer: Control = %PointerBox
@onready var _name_label: Label = %NameLabel
@onready var _choice: Control = %Choice
@onready var _value_label: Label = %ValueLabel
@onready var _slider: Control = %Slider
@onready var _fill: Control = %Fill
@onready var _knob: Control = %Knob
@onready var _percent_label: Label = %PercentLabel


func _ready() -> void:
	set_selected(selected)
	_refresh()


func set_selected(value: bool) -> void:
	selected = value
	var type_name := EDGE_SELECTED if selected else EDGE
	if theme_type_variation != type_name:
		theme_type_variation = type_name
	if not is_node_ready():
		return
	_face.visible = not selected
	_face_selected.visible = selected
	_pointer.visible = selected


func set_choice(new_index: int) -> void:
	index = clampi(new_index, 0, maxi(0, choices.size() - 1))
	_refresh()


func set_level(new_level: float) -> void:
	level = clampf(snappedf(new_level, LEVEL_STEP), 0.0, 1.0)
	_refresh()


func adjust(delta: int) -> void:
	if not choices.is_empty():
		var before := index
		set_choice(index + delta)
		if index != before:
			choice_changed.emit(index)
	else:
		var before_level := level
		set_level(level + delta * LEVEL_STEP)
		if not is_equal_approx(level, before_level):
			level_changed.emit(level)


## The shown value: the choice name, or the level as a percentage.
func value_text() -> String:
	if not is_node_ready():
		return ""
	return _value_label.text if not choices.is_empty() else _percent_label.text


func _refresh() -> void:
	if not is_node_ready():
		return
	_name_label.text = row_title
	var is_choice := not choices.is_empty()
	_choice.visible = is_choice
	_slider.visible = not is_choice
	_percent_label.visible = not is_choice
	if is_choice:
		_value_label.text = choices[clampi(index, 0, choices.size() - 1)]
	else:
		_fill.anchor_right = level
		_knob.anchor_left = level
		_knob.anchor_right = level
		_percent_label.text = "%d%%" % int(round(level * 100.0))

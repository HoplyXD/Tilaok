class_name UiOptionRow
extends PanelContainer

## A settings row: either a list of named choices or a 0..1 level in 10% steps.

signal choice_changed(index: int)
signal level_changed(level: float)

const LEVEL_STEP := 0.1

@export var row_title := ""
@export var choices := PackedStringArray()

var index := 0
var level := 1.0

@onready var _name_label: Label = %NameLabel
@onready var _value_label: Label = %ValueLabel
@onready var _bar: ProgressBar = %Bar


func _ready() -> void:
	if not row_title.is_empty():
		_name_label.text = row_title
	_refresh()


func set_selected(value: bool) -> void:
	theme_type_variation = &"RowPanelSelected" if value else &"RowPanel"


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


func value_text() -> String:
	return _value_label.text


func _refresh() -> void:
	if not is_node_ready():
		return
	var is_choice := not choices.is_empty()
	_bar.visible = not is_choice
	if is_choice:
		_value_label.text = "< %s >" % choices[index]
	else:
		_bar.value = level * 100.0
		_value_label.text = "%d%%" % int(round(level * 100.0))

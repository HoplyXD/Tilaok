@tool
class_name UiLibraryStepCard
extends Panel

## One "Round step" card on a Library page (Figma 133:1286): an illustration, the step's name with
## a short note on the right, and the explanation under them. `art` shows the illustration child
## named Art_<Art> (Art_Pugad, Art_Place, Art_Play) and hides the others; an unknown name shows
## none. It runs in the editor so the Inspector's text and art show up in the 2D view.

@export var heading := "PUGAD":
	set(value):
		heading = value
		_refresh()
@export var note := "about 8 s":
	set(value):
		note = value
		_refresh()
@export_multiline var body := "":
	set(value):
		body = value
		_refresh()
@export var art := "pugad":
	set(value):
		art = value
		_refresh()

@onready var _illustration: Control = $Illustration
@onready var _name_label: Label = $Explanation/Heading/StepName
@onready var _note_label: Label = $Explanation/Heading/StepNote
@onready var _body_label: Label = $Explanation/BodyMargin/StepBody


func bind(heading_value: String, note_value: String, body_value: String, art_name: String) -> void:
	heading = heading_value
	note = note_value
	body = body_value
	art = art_name


func _ready() -> void:
	_refresh()


func _refresh() -> void:
	if not is_node_ready():
		return
	_name_label.text = heading
	_note_label.text = note
	_body_label.text = body
	var wanted := "Art_" + art.capitalize()
	for child in _illustration.get_children():
		var control := child as Control
		if control != null:
			control.visible = control.name == wanted

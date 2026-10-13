class_name UiToastLine
extends PanelContainer

@onready var _text_label: Label = %TextLabel


func show_text(text: String) -> void:
	_text_label.text = text
	visible = not text.is_empty()


func clear() -> void:
	show_text("")


func text_value() -> String:
	return _text_label.text

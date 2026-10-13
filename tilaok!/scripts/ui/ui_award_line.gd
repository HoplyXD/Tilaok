class_name UiAwardLine
extends HBoxContainer

@onready var badge: UiPlayerBadge = %Badge
@onready var _text_label: Label = %TextLabel


func bind(seat: Dictionary, text: String) -> void:
	visible = not seat.is_empty()
	badge.bind_seat(seat)
	_text_label.text = text


func text_value() -> String:
	return _text_label.text

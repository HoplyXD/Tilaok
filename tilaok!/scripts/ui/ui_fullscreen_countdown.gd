class_name UiFullscreenCountdown
extends Control

@onready var _number: Label = %Number
@onready var _caption: Label = %Caption


func show_countdown(seconds: float, caption: String) -> void:
	visible = true
	_number.text = str(maxi(1, ceili(seconds)))
	_caption.text = caption


func hide_countdown() -> void:
	visible = false

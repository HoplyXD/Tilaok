extends Control

signal return_requested

@export var fixture_title := "Diagnostic Fixture"
@export var fixture_note := "Placeholder only. Gameplay mechanics are not implemented."


func _ready() -> void:
	$Panel/Margin/Content/Title.text = fixture_title
	$Panel/Margin/Content/Notice.text = fixture_note
	$Panel/Margin/Content/ReturnButton.pressed.connect(func() -> void: return_requested.emit())

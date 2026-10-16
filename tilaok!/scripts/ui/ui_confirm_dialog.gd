class_name UiConfirmDialog
extends PanelContainer

signal confirmed
signal cancelled

@onready var _message_label: Label = %MessageLabel
@onready var _menu: UiMenuList = %Menu
@onready var _yes_button: Button = %YesButton
@onready var _no_button: Button = %NoButton


func _ready() -> void:
	_yes_button.pressed.connect(_on_yes)
	_no_button.pressed.connect(_on_no)
	visible = false


func open(message: String) -> void:
	_message_label.text = message
	visible = true
	_menu.refresh_items()
	_menu.select(1)


func close() -> void:
	visible = false


func is_open() -> bool:
	return visible


## Yes / No are stacked, so up / down move; left / right keep working as before.
func navigate(direction: String) -> bool:
	if not _menu.horizontal:
		direction = str({"left": "up", "right": "down"}.get(direction, direction))
	return _menu.move(direction)


func accept() -> bool:
	return _menu.activate()


func cancel() -> void:
	_on_no()


func message_text() -> String:
	return _message_label.text


func _on_yes() -> void:
	close()
	confirmed.emit()


func _on_no() -> void:
	close()
	cancelled.emit()

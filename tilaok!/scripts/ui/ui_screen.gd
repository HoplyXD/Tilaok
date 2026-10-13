class_name UiScreen
extends Control

## Base for every scene-authored screen. Scripts bind data to nodes and react to the input bridge;
## layout and style live in the scene and the project Theme. Only the owning seat drives a screen.

signal back_requested

## Theme used only when this scene runs on its own (F6) with no themed parent.
@export var standalone_theme: Theme

## Seat allowed to drive this screen; -1 means any seat.
var owner_seat := -1
var context: UiContext


func _ready() -> void:
	_apply_standalone_theme()
	_on_screen_ready()


func accepts_seat(seat_index: int) -> bool:
	return owner_seat < 0 or seat_index == owner_seat


func navigate(seat_index: int, direction: String) -> bool:
	if not accepts_seat(seat_index):
		return false
	return _navigate(seat_index, direction)


func accept(seat_index: int) -> bool:
	if not accepts_seat(seat_index):
		return false
	return _accept(seat_index)


func back(seat_index: int) -> bool:
	if not accepts_seat(seat_index):
		return false
	return _back(seat_index)


## Gallery contract: names of the states this screen can show with sample data.
func state_names() -> PackedStringArray:
	return PackedStringArray(["Default"])


func show_state(index: int, ctx: UiContext) -> void:
	context = ctx
	_show_state(index, ctx)


## The LocalInputRouter.Phase value this screen expects while it is shown.
func router_phase() -> int:
	return LocalInputRouter.Phase.MENU


func _on_screen_ready() -> void:
	pass


func _show_state(_index: int, _ctx: UiContext) -> void:
	pass


func _navigate(_seat_index: int, _direction: String) -> bool:
	return false


func _accept(_seat_index: int) -> bool:
	return false


func _back(_seat_index: int) -> bool:
	back_requested.emit()
	return true


func _apply_standalone_theme() -> void:
	if standalone_theme == null or theme != null:
		return
	var node := get_parent()
	while node != null:
		var control := node as Control
		if control != null and control.theme != null:
			return
		node = node.get_parent()
	theme = standalone_theme

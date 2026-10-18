class_name UiMenuList
extends Control

## Router-driven selection over the direct Control children of a container (buttons, option rows).
## Godot focus is never used: the router owns navigation, so K2 Enter cannot double-activate.
## The selected look is a Theme type variation, so designers restyle it in the Theme.

signal item_activated(index: int)
signal selection_changed(index: int)

const VARIATION_NORMAL := &"TilaokMenuButton"
const VARIATION_SELECTED := &"MenuButtonSelected"
const ROW_NORMAL := &"RowPanel"
const ROW_SELECTED := &"RowPanelSelected"

## True for left/right menus (for example Yes/No); false for up/down lists.
@export var horizontal := false

var selected := 0
var items: Array[Control] = []
var active := true


func _ready() -> void:
	refresh_items()


func refresh_items() -> void:
	items.clear()
	for child in get_children():
		var control := child as Control
		if control == null:
			continue
		if control is BaseButton or control.has_method("set_selected"):
			items.append(control)
			control.focus_mode = Control.FOCUS_NONE
			var handler := _on_item_pressed.bind(items.size() - 1)
			if control is BaseButton and not (control as BaseButton).pressed.is_connected(handler):
				(control as BaseButton).pressed.connect(handler)
	selected = clampi(selected, 0, maxi(0, items.size() - 1))
	if not _is_selectable(selected):
		var first := _next_selectable(selected, 1)
		if first >= 0:
			selected = first
	_apply()


func set_active(value: bool) -> void:
	active = value
	_apply()


func select(index: int) -> void:
	if index < 0 or index >= items.size() or not _is_selectable(index):
		return
	if index != selected:
		selected = index
		selection_changed.emit(selected)
	_apply()


func move(direction: String) -> bool:
	var backward := "left" if horizontal else "up"
	var forward := "right" if horizontal else "down"
	if items.is_empty() or direction not in [backward, forward]:
		return false
	var step := -1 if direction == backward else 1
	var next_index := _next_selectable(selected, step)
	if next_index < 0 or next_index == selected:
		return false
	selected = next_index
	selection_changed.emit(selected)
	_apply()
	return true


func activate() -> bool:
	if selected < 0 or selected >= items.size() or not _is_selectable(selected):
		return false
	var item := items[selected]
	if item is BaseButton:
		var button := item as BaseButton
		if button.toggle_mode:
			button.button_pressed = not button.button_pressed
		else:
			button.pressed.emit()
	elif item.has_method("activate"):
		item.call("activate")
	item_activated.emit(selected)
	return true


func adjust(delta: int) -> bool:
	if selected < 0 or selected >= items.size():
		return false
	var item := items[selected]
	if item.has_method("adjust"):
		item.call("adjust", delta)
		return true
	return false


func selected_item() -> Control:
	if selected < 0 or selected >= items.size():
		return null
	return items[selected]


func selectable_count() -> int:
	var count := 0
	for index in items.size():
		if _is_selectable(index):
			count += 1
	return count


func _is_selectable(index: int) -> bool:
	if index < 0 or index >= items.size():
		return false
	var item := items[index]
	if not item.visible:
		return false
	if item is BaseButton and (item as BaseButton).disabled:
		return false
	return true


func _next_selectable(from_index: int, step: int) -> int:
	if items.is_empty():
		return -1
	var index := from_index
	for _attempt in items.size():
		index = posmod(index + step, items.size())
		if _is_selectable(index):
			return index
	return -1


func _apply() -> void:
	for index in items.size():
		var item := items[index]
		var is_selected := active and index == selected
		# Items with their own selected look (option rows, menu action buttons) set it themselves.
		if item.has_method("set_selected"):
			item.call("set_selected", is_selected)
		elif item is BaseButton:
			item.theme_type_variation = VARIATION_SELECTED if is_selected else VARIATION_NORMAL


func _on_item_pressed(index: int) -> void:
	if index != selected and _is_selectable(index):
		selected = index
		selection_changed.emit(selected)
		_apply()

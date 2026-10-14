class_name UiLibraryScreen
extends UiScreen

signal category_chosen(category: String)
signal entry_chosen(index: int)
## The How to Play page offers "Replay tutorial"; the owner (GameFlow / match presenter) clears the
## session set. Off by default so the gallery states are unchanged.
signal replay_tutorial_requested

const ZONE_CATEGORIES := 0
const ZONE_ENTRIES := 1
const ITEMS_CATEGORY := "Items"
const HOW_TO_PLAY_CATEGORY := "How to Play"
const REPLAY_LABEL := "Replay tutorial"
const REPLAY_DONE_LABEL := "Tutorial reset"
const REPLAY_DONE_TEXT := "The guided first round will play again at the start of your next match."

var zone := ZONE_CATEGORIES
var category := ""
var release_filter := false
var replay_tutorial_enabled := false
var entries: Array[ItemLibraryEntry] = []
var _definitions: ItemDefinitions
var _tuning: GameplayTuning
var _text: UiLibraryText
var _preview: ItemEggPreview
var _long_name := ""

@onready var _category_list: UiMenuList = %CategoryList
@onready var _entry_list: UiMenuList = %EntryList
@onready var _entry_title: Label = %EntryTitle
@onready var _entry_body: Label = %EntryBody
@onready var _animation_host: Control = %AnimationHost
@onready var _filter_button: Button = %ReleaseFilterButton


func state_names() -> PackedStringArray:
	return PackedStringArray(
		[
			"How to Play",
			"Karera",
			"Lagsanay",
			"Kangaroo",
			"Items (live)",
			"Items, release filter",
			"Accessibility",
			"Long Filipino name"
		]
	)


func bind_library(
	definitions: ItemDefinitions, tuning: GameplayTuning, text: UiLibraryText, long_name: String
) -> void:
	_definitions = definitions
	_tuning = tuning
	_text = text
	_long_name = long_name
	_category_list.refresh_items()
	_entry_list.refresh_items()


## Live binding: the real enabled item definitions; opens on the first category, filter off.
func bind_live(definitions: ItemDefinitions, tuning: GameplayTuning, text: UiLibraryText) -> void:
	bind_library(definitions, tuning, text, "")
	set_release_filter(false)
	var names := category_names()
	choose_category(names[0] if not names.is_empty() else "")
	_set_zone(ZONE_CATEGORIES)


func choose_category(name: String) -> void:
	category = name
	entries.clear()
	var buttons := _entry_list.items
	for button in buttons:
		button.visible = false
	if name == ITEMS_CATEGORY and _definitions != null:
		entries = ItemLibraryEntry.build_list(_definitions, release_filter)
		for index in mini(entries.size(), buttons.size()):
			(buttons[index] as Button).text = entries[index].display_name
			buttons[index].visible = true
	if name == HOW_TO_PLAY_CATEGORY and replay_tutorial_enabled and not buttons.is_empty():
		(buttons[0] as Button).text = REPLAY_LABEL
		buttons[0].visible = true
	_entry_list.refresh_items()
	_entry_list.select(0)
	_show_entry(0)
	category_chosen.emit(name)


func set_release_filter(value: bool) -> void:
	release_filter = value
	_filter_button.button_pressed = value
	_filter_button.text = "Release filter: ON" if value else "Release filter: OFF"
	if category == ITEMS_CATEGORY:
		choose_category(ITEMS_CATEGORY)


func category_names() -> PackedStringArray:
	var result := PackedStringArray()
	for item in _category_list.items:
		if item is Button and item != _filter_button:
			result.append((item as Button).text)
	return result


func _on_screen_ready() -> void:
	_filter_button.toggle_mode = true
	_category_list.item_activated.connect(_on_category_activated)
	_entry_list.selection_changed.connect(_show_entry)
	_entry_list.item_activated.connect(_on_entry_activated)
	_category_list.refresh_items()
	_entry_list.refresh_items()


func _exit_tree() -> void:
	_free_preview()


func _show_state(index: int, ctx: UiContext) -> void:
	bind_library(ctx.definitions, ctx.tuning, ctx.library_text, ctx.sample.long_name)
	zone = ZONE_CATEGORIES
	set_release_filter(index == 5)
	var names := [
		"How to Play", "Karera", "Lagsanay", "Kangaroo", "Items", "Items", "Accessibility", "Items"
	]
	choose_category(names[clampi(index, 0, names.size() - 1)])
	if index == 7 and not entries.is_empty():
		entries[0].display_name = _long_name
		(_entry_list.items[0] as Button).text = _long_name
		_show_entry(0)
	_set_zone(ZONE_ENTRIES if index == 4 and not entries.is_empty() else ZONE_CATEGORIES)


func _navigate(_seat_index: int, direction: String) -> bool:
	if direction == "right" and zone == ZONE_CATEGORIES and _entry_list.selectable_count() > 0:
		_set_zone(ZONE_ENTRIES)
		return true
	if direction == "left" and zone == ZONE_ENTRIES:
		_set_zone(ZONE_CATEGORIES)
		return true
	return _active_list().move(direction)


func _accept(_seat_index: int) -> bool:
	return _active_list().activate()


func _back(_seat_index: int) -> bool:
	if zone == ZONE_ENTRIES:
		_set_zone(ZONE_CATEGORIES)
		return true
	back_requested.emit()
	return true


func _active_list() -> UiMenuList:
	return _entry_list if zone == ZONE_ENTRIES else _category_list


func _set_zone(value: int) -> void:
	zone = value
	_category_list.set_active(zone == ZONE_CATEGORIES)
	_entry_list.set_active(zone == ZONE_ENTRIES)


func _on_category_activated(index: int) -> void:
	var item := _category_list.items[index]
	if item == _filter_button:
		set_release_filter(_filter_button.button_pressed)
		return
	choose_category((item as Button).text)


func _on_entry_activated(index: int) -> void:
	if category == HOW_TO_PLAY_CATEGORY and replay_tutorial_enabled:
		replay_tutorial_requested.emit()
		(_entry_list.items[0] as Button).text = REPLAY_DONE_LABEL
		_entry_body.text = REPLAY_DONE_TEXT
		return
	entry_chosen.emit(index)


func _show_entry(index: int) -> void:
	_free_preview()
	if category == ITEMS_CATEGORY:
		if index < 0 or index >= entries.size():
			_entry_title.text = "No items enabled"
			_entry_body.text = ""
			return
		var entry := entries[index]
		_entry_title.text = entry.display_name
		_entry_body.text = entry.text_block()
		var egg := ItemEggPreview.new()
		if egg.configure(_definitions, entry.animation_variant_key, 0, _tuning):
			_animation_host.add_child(egg)
			_preview = egg
		else:
			egg.free()
		return
	if _text != null:
		_entry_title.text = _text.title_for(category)
		_entry_body.text = _text.body_for(category)


func _free_preview() -> void:
	if _preview != null and is_instance_valid(_preview):
		_preview.queue_free()
	_preview = null

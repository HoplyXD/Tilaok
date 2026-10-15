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
const REPLAY_BODY := "Plays the guided first round again at the start of your next match."
## `--library-dev` marks a development / reference build: the release filter button and the
## reference (not playable) entries appear. Player builds never show either.
const DEV_FLAG := "--library-dev"
const REFERENCE_TAG := "REFERENCE ONLY - not playable in this build"
const KIND_PAGE := "page"
const KIND_ITEM := "item"
const KIND_REPLAY := "replay"
## An entry with several enabled sizes loops its animation through each one in turn.
const VARIANT_CYCLE_SECONDS := 2.0

var zone := ZONE_CATEGORIES
var category := ""
var release_filter := false
var replay_tutorial_enabled := false
var dev_mode := false
## Items entries shown by the current category (playable content only, plus reference rows in
## dev mode after them).
var entries: Array[ItemLibraryEntry] = []
## Every row of the current category in display order: {title, body, kind, entry?, reference?}.
var rows: Array[Dictionary] = []
## Index of the first row shown in the scrolling entry window.
var window_offset := 0
var _definitions: ItemDefinitions
var _reference_definitions: ItemDefinitions
var _tuning: GameplayTuning
var _text: UiLibraryText
var _context: Dictionary = {}
var _preview: ItemEggPreview
var _long_name := ""
var _cycle_index := 0
var _cycle_time := 0.0

@onready var _category_list: UiMenuList = %CategoryList
@onready var _entry_list: UiMenuList = %EntryList
@onready var _entry_title: Label = %EntryTitle
@onready var _entry_body: Label = %EntryBody
@onready var _animation_host: Control = %AnimationHost
@onready var _filter_button: Button = %ReleaseFilterButton


static func dev_mode_requested() -> bool:
	return OS.get_cmdline_user_args().has(DEV_FLAG)


## The lab catalog the dev-only reference rows are read from (never dealt in a match).
static func reference_definitions_for(tuning: GameplayTuning) -> ItemDefinitions:
	return ItemDefinitions.load_for_profile(tuning, ItemEnabledProfiles.ITEMS_LAB)


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
## `context` is UiLibraryText.build_context(); `reference_definitions` (dev mode only) lists
## content that exists but is not enabled in this build.
func bind_live(
	definitions: ItemDefinitions,
	tuning: GameplayTuning,
	text: UiLibraryText,
	context: Dictionary = {},
	reference_definitions: ItemDefinitions = null
) -> void:
	_context = context
	_reference_definitions = reference_definitions if dev_mode else null
	bind_library(definitions, tuning, text, "")
	set_release_filter(false)
	var names := category_names()
	choose_category(names[0] if not names.is_empty() else "")
	_set_zone(ZONE_CATEGORIES)


func choose_category(name: String) -> void:
	category = name
	window_offset = 0
	rows = _rows_for(name)
	_entry_list.refresh_items()
	_render_window()
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


## Titles of the rows in the current category (for tests and captures).
func row_titles() -> PackedStringArray:
	var result := PackedStringArray()
	for row in rows:
		result.append(str(row.title))
	return result


func visible_slot_count() -> int:
	var count := 0
	for item in _entry_list.items:
		if item.visible:
			count += 1
	return count


func current_row() -> Dictionary:
	var index := window_offset + _entry_list.selected
	return rows[index] if index >= 0 and index < rows.size() else {}


func _on_screen_ready() -> void:
	dev_mode = dev_mode_requested()
	_filter_button.visible = dev_mode
	_filter_button.toggle_mode = true
	_category_list.item_activated.connect(_on_category_activated)
	_entry_list.selection_changed.connect(_show_entry)
	_entry_list.item_activated.connect(_on_entry_activated)
	_category_list.refresh_items()
	_entry_list.refresh_items()


func _exit_tree() -> void:
	_free_preview()


func _process(delta: float) -> void:
	var entry := current_row().get("entry") as ItemLibraryEntry
	if _preview == null or entry == null or entry.enabled_variant_keys.size() < 2:
		return
	_cycle_time += delta
	if _cycle_time >= VARIANT_CYCLE_SECONDS:
		_cycle_time = 0.0
		_cycle_index = (_cycle_index + 1) % entry.enabled_variant_keys.size()
		_apply_variant(entry)


## Shows `entry`'s enabled variant `_cycle_index` in the egg and names its size in the title.
func _apply_variant(entry: ItemLibraryEntry) -> void:
	var key := entry.enabled_variant_keys[_cycle_index]
	if _preview != null and _preview.configure(_definitions, key, 0, _tuning):
		if _cycle_index < entry.enabled_variant_sizes.size():
			_entry_title.text = (
				"%s - %s"
				% [str(current_row().get("title", "")), entry.enabled_variant_sizes[_cycle_index]]
			)


func _show_state(index: int, ctx: UiContext) -> void:
	bind_library(ctx.definitions, ctx.tuning, ctx.library_text, ctx.sample.long_name)
	_context = UiLibraryText.build_context(ctx.tuning, ctx.prompt_map)
	zone = ZONE_CATEGORIES
	set_release_filter(index == 5)
	var names := [
		"How to Play", "Karera", "Lagsanay", "Kangaroo", "Items", "Items", "Accessibility", "Items"
	]
	choose_category(names[clampi(index, 0, names.size() - 1)])
	if index == 7 and not rows.is_empty():
		rows[0].title = _long_name
		_render_window()
		_show_entry(0)
	_set_zone(ZONE_ENTRIES if index == 4 and not rows.is_empty() else ZONE_CATEGORIES)


func _navigate(_seat_index: int, direction: String) -> bool:
	if direction == "right" and zone == ZONE_CATEGORIES and _entry_list.selectable_count() > 0:
		_set_zone(ZONE_ENTRIES)
		return true
	if direction == "left" and zone == ZONE_ENTRIES:
		_set_zone(ZONE_CATEGORIES)
		return true
	if zone == ZONE_ENTRIES and direction in ["up", "down"]:
		return _move_entries(direction)
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


## Moves through every row of the category even when there are more rows than entry buttons: the
## window scrolls one row at a time and wraps at both ends.
func _move_entries(direction: String) -> bool:
	var slots := visible_slot_count()
	if slots <= 0 or rows.is_empty():
		return false
	var current := window_offset + _entry_list.selected
	var target := current + (1 if direction == "down" else -1)
	if target < 0:
		target = rows.size() - 1
	elif target >= rows.size():
		target = 0
	if target == current:
		return false
	_move_entries_to(target)
	return true


## Selects row `target`, scrolling the window so it is visible.
func _move_entries_to(target: int) -> void:
	var slots := visible_slot_count()
	if target < window_offset:
		window_offset = target
	elif target >= window_offset + slots:
		window_offset = target - slots + 1
	window_offset = clampi(window_offset, 0, maxi(0, rows.size() - slots))
	_render_window()
	_entry_list.select(target - window_offset)
	_show_entry(target - window_offset)


func _on_category_activated(index: int) -> void:
	var item := _category_list.items[index]
	if item == _filter_button:
		set_release_filter(_filter_button.button_pressed)
		return
	choose_category((item as Button).text)


func _on_entry_activated(index: int) -> void:
	var row_index := window_offset + index
	if row_index < 0 or row_index >= rows.size():
		return
	if str(rows[row_index].kind) == KIND_REPLAY:
		replay_tutorial_requested.emit()
		(_entry_list.items[index] as Button).text = REPLAY_DONE_LABEL
		_entry_body.text = REPLAY_DONE_TEXT
		return
	entry_chosen.emit(row_index)


func _rows_for(name: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	entries.clear()
	if name == ITEMS_CATEGORY and _definitions != null:
		entries = ItemLibraryEntry.build_list(_definitions, release_filter)
		for entry in entries:
			(
				result
				. append(
					{
						"title": entry.display_name,
						"body": entry.text_block(),
						"kind": KIND_ITEM,
						"entry": entry,
					}
				)
			)
		if _reference_definitions != null:
			result.append_array(_reference_rows())
		return result
	if _text != null:
		for page in _text.pages_for(name, _context):
			result.append({"title": page.title, "body": page.body, "kind": KIND_PAGE})
		if result.is_empty():
			var legacy := _text.body_for(name)
			if not legacy.is_empty():
				result.append({"title": _text.title_for(name), "body": legacy, "kind": KIND_PAGE})
	if name == HOW_TO_PLAY_CATEGORY and replay_tutorial_enabled:
		result.append({"title": REPLAY_LABEL, "body": REPLAY_BODY, "kind": KIND_REPLAY})
	return result


## Families that exist in the lab catalog but are not in this build's enabled set. Dev only.
func _reference_rows() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var enabled_ids: Dictionary = {}
	for family in _definitions.families:
		enabled_ids[family.family_id] = true
	for family in _reference_definitions.families:
		if enabled_ids.has(family.family_id):
			continue
		var entry := ItemLibraryEntry.from_family(family, _reference_definitions)
		(
			result
			. append(
				{
					"title": "%s [REFERENCE]" % entry.display_name,
					"body": "%s\n\n%s" % [REFERENCE_TAG, entry.text_block()],
					"kind": KIND_ITEM,
					"reference": true,
				}
			)
		)
	return result


func _render_window() -> void:
	var buttons := _entry_list.items
	for slot in buttons.size():
		var row_index := window_offset + slot
		var button := buttons[slot] as Button
		button.visible = row_index < rows.size()
		if button.visible:
			button.text = str(rows[row_index].title)
	_entry_list.refresh_items()


func _show_entry(slot: int) -> void:
	_free_preview()
	var row_index := window_offset + slot
	if row_index < 0 or row_index >= rows.size():
		_animation_host.get_parent().visible = false
		_entry_title.text = "No items enabled" if category == ITEMS_CATEGORY else category
		_entry_body.text = ""
		return
	var row := rows[row_index]
	_entry_title.text = str(row.title)
	_entry_body.text = str(row.body)
	var entry := row.get("entry") as ItemLibraryEntry
	_cycle_index = 0
	_cycle_time = 0.0
	# Only item entries have an animation; the frame stays out of the way on text pages.
	_animation_host.get_parent().visible = entry != null
	if entry == null:
		return
	var egg := ItemEggPreview.new()
	if egg.configure(_definitions, entry.animation_variant_key, 0, _tuning):
		_animation_host.add_child(egg)
		_preview = egg
	else:
		egg.free()


func _free_preview() -> void:
	if _preview != null and is_instance_valid(_preview):
		_preview.queue_free()
	_preview = null

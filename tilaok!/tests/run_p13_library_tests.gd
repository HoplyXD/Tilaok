extends SceneTree

## P13-T05/T06 Library: every category has real (PLACEHOLDER-tagged) pages built from live tuning,
## every enabled family has an entry that is reachable (more rows than buttons scroll), disabled
## content and stack pages are absent unless their content is enabled, reference rows appear only
## with the dev flag, controllers can operate category / entry / back, and the Pugad stays
## name-free. Synthetic input only.

const FLOW_SCENE := preload("res://scenes/flow/game_flow.tscn")
const LIBRARY_SCENE := preload("res://scenes/ui/screens/library_screen.tscn")
const ROOM_SCENE := preload("res://scenes/match/p12_scheduled_match_room.tscn")
const TEXT_PATH := "res://data/ui/library_text.tres"
const PAD := 730
const CATEGORIES := ["How to Play", "Karera", "Lagsanay", "Kangaroo", "Items", "Accessibility"]
const FORBIDDEN := ["SAMPLE", "res://", "uid://", "seed", " wu", "DEBUG", "shape_id"]

var checks := 0
var failures := 0
var flow: GameFlow


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var text := load(TEXT_PATH) as UiLibraryText
	_check(text != null and not text.pages.is_empty(), "library_text.tres loads with pages")
	var tuning := GameplayTuning.new()
	ItemEnabledProfiles.apply(tuning, "karera_slice")
	var map := load(UiContext.PROMPT_MAP_PATH) as UiPromptMap
	var context := UiLibraryText.build_context(tuning, map, 2)
	_test_pages(text, tuning, context)
	_test_gating(text, tuning, map)
	await _test_items_and_scrolling(text, tuning, context)
	await _test_dev_reference_rows(text, tuning, context)
	await _test_controller_navigation()
	await _test_replay_entry(text, tuning, context)
	await _test_pugad_is_name_free()
	print("P13_LIBRARY_TESTS checks=%d failures=%d" % [checks, failures])
	quit(1 if failures > 0 else 0)


# --- copy ----------------------------------------------------------------------------------------


func _test_pages(text: UiLibraryText, tuning: GameplayTuning, context: Dictionary) -> void:
	for category in CATEGORIES:
		if category == "Items":
			continue
		var pages := text.pages_for(category, context)
		_check(not pages.is_empty(), "%s has pages" % category)
		for page in pages:
			var body := str(page.body)
			_check(
				body.contains(UiLibraryText.PLACEHOLDER_NOTE),
				"%s / %s carries the PLACEHOLDER tag" % [category, page.title]
			)
			for token in FORBIDDEN:
				_check(
					not body.contains(token) and not str(page.title).contains(token),
					"%s / %s has no '%s'" % [category, page.title, token]
				)
			_check(not body.contains("{"), "%s / %s has no unfilled token" % [category, page.title])
	var scoring := _body(text, context, "Karera", "Scoring")
	_check(
		scoring.contains("Tapos +1") and scoring.contains("Una +0.25"),
		"Karera scoring quotes the calculator values"
	)
	_check(
		scoring.contains("no second- or third-place bonus"),
		"Karera Library explains that Una is its only finish-order bonus"
	)
	var lagsanay_scoring := _body(text, context, "Lagsanay", "Placement points")
	_check(
		(
			lagsanay_scoring.contains("first eliminated is 4th 0")
			and lagsanay_scoring.contains("fourth-place chicken still keeps direct Patibong")
		),
		"Lagsanay Library explains fourth-place placement and independent trap points"
	)
	_check(scoring.contains("Bayani +0.5") and scoring.contains("Bawi +0.75"), "Bayani and Bawi")
	_check(not scoring.to_lower().contains("barya"), "Barya is not described (not enabled)")
	var winning := _body(text, context, "How to Play", "Winning")
	_check(
		winning.contains("First to 10 points") and winning.contains("round 12"), "target and limit"
	)
	tuning.match_target_score_units = 96
	tuning.match_round_limit = 9
	var changed := UiLibraryText.build_context(tuning, null, 0)
	var winning_changed := _body(text, changed, "How to Play", "Winning")
	_check(
		winning_changed.contains("First to 12 points") and winning_changed.contains("round 9"),
		"numbers follow live tuning, not literals"
	)
	tuning.match_target_score_units = 80
	tuning.match_round_limit = 12
	var taya := _body(text, context, "Lagsanay", "Taya, pass and timer")
	_check(taya.contains("15 s with 4") and taya.contains("7 s with 2"), "taya countdowns")
	_check(
		_body(text, context, "Lagsanay", "Placement points").contains("2nd 0.5"),
		"placement values come from the resolver"
	)
	var controls := _body(text, context, "How to Play", "Controls")
	_check(
		(
			controls.contains("Keyboard 1")
			and controls.contains("Gamepad")
			and controls.contains("West")
		),
		"controls list all three device kinds"
	)
	var shake := _body(text, context, "Accessibility", "Screen shake")
	_check(shake.contains("Current setting: Off"), "the shake page reflects the setting")


func _test_gating(text: UiLibraryText, tuning: GameplayTuning, map: UiPromptMap) -> void:
	var none: Array[Dictionary] = []
	var bare := UiLibraryText.build_context(tuning, map, 2, none)
	_check(
		_title_present(text, bare, "Karera", "Karera + Bomb-Taya") == false,
		"a stack page is absent while its row is disabled"
	)
	_check(
		_title_present(text, bare, "Lagsanay", "As a Twist: Bomb-Taya") == false,
		"the Bomb-Taya Twist page is absent while no row uses it"
	)
	var full := UiLibraryText.build_context(tuning, map, 2)
	for title in ["Karera + Bomb-Taya", "Karera + Kangaroo"]:
		_check(_title_present(text, full, "Karera", title), "%s is listed when enabled" % title)
	_check(_title_present(text, full, "Kangaroo", "As a Twist"), "Kangaroo Twist page when enabled")
	var no_kangaroo := UiLibraryText.build_context(
		tuning, map, 2, EventSchedule.enabled_pairs(), ["KARERA", "LAGSANAY"]
	)
	_check(
		text.pages_for("Kangaroo", no_kangaroo).is_empty(),
		"Kangaroo pages are absent when the mode is not available"
	)


# --- items, scrolling, filtering ---------------------------------------------------------------


func _test_items_and_scrolling(
	text: UiLibraryText, tuning: GameplayTuning, context: Dictionary
) -> void:
	var definitions := ItemDefinitions.load_for_profile(tuning, "karera_slice")
	var screen := LIBRARY_SCENE.instantiate() as UiLibraryScreen
	root.add_child(screen)
	await process_frame
	screen.bind_live(definitions, tuning, text, context)
	screen.choose_category("Items")
	var enabled_families: Array[String] = []
	for family in definitions.families:
		var any_enabled := false
		for variant in family.variants:
			any_enabled = any_enabled or definitions.is_variant_enabled(family.variant_key(variant))
		if any_enabled:
			enabled_families.append(family.family_id)
	_check(enabled_families.size() >= 8, "the build enables %d families" % enabled_families.size())
	_check(
		screen.entries.size() == enabled_families.size(),
		(
			"every enabled family has exactly one entry (%d/%d)"
			% [screen.entries.size(), enabled_families.size()]
		)
	)
	var seen: Dictionary = {}
	for entry in screen.entries:
		seen[entry.family_id] = true
		_check(
			not entry.tell.is_empty() and not entry.counterplay.is_empty(),
			"%s has a tell and counterplay" % entry.family_id
		)
		_check(
			entry.text_block().contains("Gamepad") and not entry.sizes.is_empty(),
			"%s lists controls for every device and its sizes" % entry.family_id
		)
		_check(not entry.modes_allowed.is_empty(), "%s lists its permitted modes" % entry.family_id)
		_check(
			not entry.animation_variant_key.is_empty(),
			"%s has a looping animation variant" % entry.family_id
		)
	for family_id in enabled_families:
		_check(seen.has(family_id), "%s is listed" % family_id)
	# Every enabled size is animated: the egg loops through each enabled variant of an entry.
	screen._set_zone(UiLibraryScreen.ZONE_ENTRIES)
	var multi := false
	for index in screen.rows.size():
		var entry := screen.rows[index].get("entry") as ItemLibraryEntry
		if entry == null or entry.enabled_variant_keys.size() < 2:
			continue
		multi = true
		screen.window_offset = 0
		screen._render_window()
		screen._move_entries_to(index)
		var shown := PackedStringArray()
		for _cycle in entry.enabled_variant_keys.size():
			shown.append(screen._preview.variant_key)
			screen._process(UiLibraryScreen.VARIANT_CYCLE_SECONDS + 0.01)
		_check(
			_unique_count(shown) == entry.enabled_variant_keys.size(),
			"%s animates each enabled size %s" % [entry.family_id, shown]
		)
	_check(multi, "at least one family has several enabled sizes")
	# Disabled content (lab-only families) is absent from the player Library.
	var lab := UiLibraryScreen.reference_definitions_for(tuning)
	var leaked := PackedStringArray()
	for family in lab.families:
		if enabled_families.has(family.family_id):
			continue
		for entry in screen.entries:
			if entry.family_id == family.family_id:
				leaked.append(family.family_id)
	_check(leaked.is_empty(), "no disabled family leaks into the Library %s" % [leaked])
	_check(
		not screen.dev_mode and not screen._filter_button.visible,
		"the release filter button and reference mode stay hidden without --library-dev"
	)
	# More rows than buttons: scrolling reaches every row.
	var slots := screen.visible_slot_count()
	_check(slots > 0, "entry buttons are shown (%d)" % slots)
	screen._set_zone(UiLibraryScreen.ZONE_ENTRIES)
	var reached := PackedStringArray()
	reached.append(str(screen.current_row().title))
	for _step in screen.rows.size() - 1:
		screen.navigate(0, "down")
		reached.append(str(screen.current_row().title))
	_check(
		reached.size() == screen.rows.size() and _unique_count(reached) == screen.rows.size(),
		"navigating down reaches every row once (%d rows, %d slots)" % [screen.rows.size(), slots]
	)
	screen.navigate(0, "down")
	_check(screen.window_offset == 0, "down from the last row wraps to the first")
	screen.navigate(0, "up")
	_check(
		str(screen.current_row().title) == str(screen.rows[screen.rows.size() - 1].title),
		"up from the first row wraps to the last"
	)
	screen.queue_free()
	await process_frame


func _test_dev_reference_rows(
	text: UiLibraryText, tuning: GameplayTuning, context: Dictionary
) -> void:
	var definitions := ItemDefinitions.load_for_profile(tuning, "karera_slice")
	var lab := UiLibraryScreen.reference_definitions_for(tuning)
	var player := LIBRARY_SCENE.instantiate() as UiLibraryScreen
	root.add_child(player)
	await process_frame
	player.bind_live(definitions, tuning, text, context, lab)
	player.choose_category("Items")
	var player_rows := player.rows.size()
	var player_reference := 0
	for row in player.rows:
		player_reference += 1 if bool(row.get("reference", false)) else 0
	_check(player_reference == 0, "a player build shows no reference rows even if given them")
	player.queue_free()
	var dev := LIBRARY_SCENE.instantiate() as UiLibraryScreen
	root.add_child(dev)
	await process_frame
	dev.dev_mode = true
	dev.bind_live(definitions, tuning, text, context, lab)
	dev.choose_category("Items")
	var dev_reference := 0
	for row in dev.rows:
		if bool(row.get("reference", false)):
			dev_reference += 1
			_check(
				(
					str(row.title).contains("[REFERENCE]")
					and str(row.body).contains(UiLibraryScreen.REFERENCE_TAG)
				),
				"a reference row is clearly marked not playable"
			)
	_check(dev_reference > 0, "dev mode lists reference content (%d rows)" % dev_reference)
	_check(
		dev.rows.size() == player_rows + dev_reference,
		"reference rows come after, and never replace, the playable rows"
	)
	dev.queue_free()
	await process_frame


# --- controller navigation through the real flow -------------------------------------


func _test_controller_navigation() -> void:
	flow = FLOW_SCENE.instantiate() as GameFlow
	flow.harness_mode = true
	root.add_child(flow)
	await _frames(3)
	_pad(JOY_BUTTON_A)
	await _frames(2)
	_pad(JOY_BUTTON_DPAD_DOWN)
	_pad(JOY_BUTTON_A)
	await _frames(2)
	_check(flow.state == GameFlow.State.LIBRARY, "a gamepad opens the Library from the Title")
	var library := flow._screen as UiLibraryScreen
	var visited := PackedStringArray()
	for _step in CATEGORIES.size():
		visited.append(library.category)
		_pad(JOY_BUTTON_DPAD_DOWN)
		_pad(JOY_BUTTON_A)
		await process_frame
	_check(
		visited.size() == CATEGORIES.size() and _unique_count(visited) >= CATEGORIES.size() - 1,
		"the D-pad and South step through every category %s" % [visited]
	)
	_pad(JOY_BUTTON_DPAD_RIGHT)
	_check(library.zone == UiLibraryScreen.ZONE_ENTRIES, "Right enters the entry list")
	_pad(JOY_BUTTON_B)
	_check(library.zone == UiLibraryScreen.ZONE_CATEGORIES, "East returns to the categories")
	_pad(JOY_BUTTON_B)
	await _frames(2)
	_check(flow.state == GameFlow.State.TITLE, "East from the categories leaves the Library")
	flow.queue_free()
	flow = null
	await _frames(3)


func _test_replay_entry(text: UiLibraryText, tuning: GameplayTuning, context: Dictionary) -> void:
	var definitions := ItemDefinitions.load_for_profile(tuning, "karera_slice")
	var screen := LIBRARY_SCENE.instantiate() as UiLibraryScreen
	root.add_child(screen)
	await process_frame
	screen.replay_tutorial_enabled = true
	var requested := [0]
	screen.replay_tutorial_requested.connect(func() -> void: requested[0] += 1)
	screen.bind_live(definitions, tuning, text, context)
	var titles := screen.row_titles()
	_check(
		titles.size() > 1 and titles[titles.size() - 1] == UiLibraryScreen.REPLAY_LABEL,
		"How to Play ends with the Replay tutorial entry"
	)
	screen._set_zone(UiLibraryScreen.ZONE_ENTRIES)
	for _step in screen.rows.size() - 1:
		screen.navigate(0, "down")
	screen.accept(0)
	_check(requested[0] == 1, "activating Replay tutorial requests it once")
	screen.queue_free()
	await process_frame


# --- the Pugad stays visual only ---------------------------------------------------------------


func _test_pugad_is_name_free() -> void:
	var room := ROOM_SCENE.instantiate() as P12ScheduledMatchRoom
	root.add_child(room)
	await _frames(2)
	for layout in ["K1", "K2"]:
		room.join_keyboard(layout)
	for seat in room.input_router.registry.joined_seats():
		room.input_router.registry.set_ready(int(seat.seat), true)
	room.start_match()
	await _frames(4)
	_check(
		(
			room.phase_controller.phase == MatchPhaseController.Phase.PUGAD
			and room.presenter.pugad_overlay.visible
		),
		"the Pugad is on screen"
	)
	var names := PackedStringArray()
	for family in room.definitions.families:
		names.append(family.working_name.to_lower())
		names.append(family.family_id.to_lower())
	var found := PackedStringArray()
	var labels := 0
	for node in _all_nodes(room.presenter.pugad_overlay):
		var label := node as Label
		if label == null or not label.is_visible_in_tree():
			continue
		labels += 1
		for name in names:
			if not name.is_empty() and label.text.to_lower().contains(name):
				found.append("%s='%s'" % [label.name, label.text])
	_check(found.is_empty(), "no visible Pugad text names an item %s" % [found])
	_check(labels > 0, "the Pugad shows its own text (%d labels)" % labels)
	room.queue_free()
	await process_frame


# --- helpers ------------------------------------------------------------------------


func _body(text: UiLibraryText, context: Dictionary, category: String, title: String) -> String:
	for page in text.pages_for(category, context):
		if str(page.title) == title:
			return str(page.body)
	return ""


func _title_present(
	text: UiLibraryText, context: Dictionary, category: String, title: String
) -> bool:
	for page in text.pages_for(category, context):
		if str(page.title) == title:
			return true
	return false


func _unique_count(values: PackedStringArray) -> int:
	var seen: Dictionary = {}
	for value in values:
		seen[value] = true
	return seen.size()


func _pad(button: JoyButton) -> void:
	var event := InputEventJoypadButton.new()
	event.device = PAD
	event.button_index = button
	event.pressed = true
	flow.router._handle_joy_button(event)
	event.pressed = false
	flow.router._handle_joy_button(event)


func _frames(count: int) -> void:
	for _frame in count:
		await process_frame


func _all_nodes(node: Node) -> Array[Node]:
	var result: Array[Node] = [node]
	for child in node.get_children():
		result.append_array(_all_nodes(child))
	return result


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("P13_LIBRARY FAIL: " + message)
	print("%s %s" % ["PASS" if condition else "FAIL", message])

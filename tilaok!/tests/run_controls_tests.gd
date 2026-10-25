extends SceneTree

## Requested by the user, 2026-10-16:
## - four shared-keyboard layouts, seated in join order (no layout is tied to a player number):
##   remapped 2026-10-25 as move / build / confirm / rotate / back: K1 WASD / Q / E or F / R / G,
##   K2 IJKL / U / O / P / H, K3 arrows / Right Shift / Enter / Backspace / backslash,
##   K4 numpad 8 4 2 6 / 5 / Enter / 0 / .;
## - the Lobby map row is mouse-clickable;
## - the Place ghost previews the block itself, rotated, with a facing arrow and its name;
## - the Library has a clickable Back button.
## Run: godot --headless --fixed-fps 60 --path tilaok! --script res://tests/run_controls_tests.gd

const FLOW_SCENE := preload("res://scenes/flow/game_flow.tscn")
const MATCH_SCENE := preload("res://scenes/match/match_room.tscn")
const LIBRARY_SCENE := preload("res://scenes/ui/screens/library_screen.tscn")
const SPIKES := "block.spikes.main"
const KAING := "build.hollow_blocks.cell_1x1"
## layout -> [confirm, rotate, left, right, up, down]
const LAYOUT_KEYS := {
	"K1": [KEY_E, KEY_R, KEY_A, KEY_D, KEY_W, KEY_S],
	"K2": [KEY_O, KEY_P, KEY_J, KEY_L, KEY_I, KEY_K],
	"K3": [KEY_ENTER, KEY_BACKSPACE, KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN],
	"K4": [KEY_KP_ENTER, KEY_KP_0, KEY_KP_4, KEY_KP_6, KEY_KP_8, KEY_KP_2],
}
## layout -> [build mode, back]
const LAYOUT_BUILD_BACK := {
	"K1": [KEY_Q, KEY_G],
	"K2": [KEY_U, KEY_H],
	"K3": [KEY_SHIFT, KEY_BACKSLASH],
	"K4": [KEY_KP_5, KEY_KP_PERIOD],
}

var failures := 0
var checks := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	# Headless windows start tiny; real clicks need the buttons on screen.
	root.size = Vector2i(1920, 1080)
	_test_layout_actions()
	_test_join_order()
	_test_prompts()
	await _test_ghost_preview()
	await _test_map_buttons_and_library_back()
	print("CONTROLS_TESTS checks=%d failures=%d" % [checks, failures])
	await process_frame
	quit(1 if failures > 0 else 0)


func _check(condition: bool, label: String) -> void:
	checks += 1
	if condition:
		print("PASS ", label)
	else:
		failures += 1
		push_error("FAIL " + label)


func _key(
	key: Key, pressed: bool, location: KeyLocation = KEY_LOCATION_UNSPECIFIED
) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.pressed = pressed
	event.location = location
	return event


func _location(key: int) -> KeyLocation:
	return KEY_LOCATION_RIGHT if key in [KEY_SHIFT, KEY_CTRL] else KEY_LOCATION_UNSPECIFIED


func _test_layout_actions() -> void:
	var router := LocalInputRouter.new()
	var wrong := PackedStringArray()
	for layout in LAYOUT_KEYS:
		var keys: Array = LAYOUT_KEYS[layout]
		for key in keys:
			if router._keyboard_layout_for_key(key, _location(key)) != layout:
				wrong.append("%s key %s" % [layout, OS.get_keycode_string(key)])
		var expect_place := ["confirm", "rotate", "left", "right", "up", "down"]
		router.phase = LocalInputRouter.Phase.PLACE
		for index in keys.size():
			var action := router._key_action(layout, keys[index])
			if action != expect_place[index]:
				wrong.append("%s %s -> %s" % [layout, OS.get_keycode_string(keys[index]), action])
		router.phase = LocalInputRouter.Phase.PLAY
		if router._key_action(layout, keys[4]) != "jump":
			wrong.append("%s up key does not jump in Play" % layout)
		router.phase = LocalInputRouter.Phase.LOBBY
		if router._key_action(layout, keys[0]) != "ready":
			wrong.append("%s confirm key does not ready in the Lobby" % layout)
		var build_back: Array = LAYOUT_BUILD_BACK[layout]
		if router._keyboard_layout_for_key(build_back[0], _location(build_back[0])) != layout:
			wrong.append("%s build key belongs to another layout" % layout)
		if router._key_action(layout, build_back[1]) != "back":
			wrong.append("%s back key does not go back in the Lobby" % layout)
		router.phase = LocalInputRouter.Phase.PLAY
		if router._key_action(layout, build_back[0]) != "build_toggle":
			wrong.append("%s build key does not toggle build mode in Play" % layout)
	_check(
		wrong.is_empty(),
		"every layout maps confirm / rotate / move / jump / ready / build / back to its keys: %s" % [wrong]
	)
	router.phase = LocalInputRouter.Phase.PLACE
	_check(
		(
			router._keyboard_layout_for_key(KEY_F, KEY_LOCATION_UNSPECIFIED) == "K1"
			and router._key_action("K1", KEY_F) == "confirm"
		),
		"WASD confirms with E or F"
	)
	router.free()


func _test_join_order() -> void:
	var router := LocalInputRouter.new()
	router.set_shared_keyboard_enabled(true)
	router.phase = LocalInputRouter.Phase.LOBBY
	var order := ["K4", "K3", "K1", "K2"]
	for layout in order:
		var confirm: int = LAYOUT_KEYS[layout][0]
		router._handle_key(_key(confirm, true, _location(confirm)))
		router._handle_key(_key(confirm, false, _location(confirm)))
	var seats := []
	for layout in order:
		seats.append(router.registry.seat_for_keyboard(layout))
	_check(
		seats == [0, 1, 2, 3],
		"seats follow join order, not the layout: numpad joined first is P1 (%s)" % [seats]
	)
	router.free()


func _test_prompts() -> void:
	var map := load(UiContext.PROMPT_MAP_PATH) as UiPromptMap
	var missing := PackedStringArray()
	for action in map.actions():
		for device in UiContext.DEVICE_KINDS:
			if map.glyph(action, device) == "?":
				missing.append("%s|%s" % [action, device])
	_check(missing.is_empty(), "every action has a prompt for all five devices: %s" % [missing])
	_check(
		(
			map.glyph("confirm", "k1") == "E / F"
			and map.glyph("confirm", "k2") == "O"
			and map.glyph("rotate", "k2") == "P"
			and map.glyph("back", "k2") == "H"
			and map.glyph("confirm", "k3") == "Enter"
			and map.glyph("rotate", "k3") == "Backspace"
			and map.glyph("confirm", "k4") == "Num Enter"
			and map.glyph("rotate", "k4") == "Num 0"
			and map.glyph("build_toggle", "k4") == "Num 5"
		),
		"prompts show E / O / Enter / Num Enter to confirm"
	)
	var seat := {"device_kind": "keyboard", "keyboard_layout": "K4"}
	_check(UiContext.device_for_seat(seat) == "k4", "a numpad seat reads numpad prompts")


func _test_ghost_preview() -> void:
	var room := MATCH_SCENE.instantiate() as P05MatchRoom
	root.add_child(room)
	await process_frame
	room.join_keyboard("K1")
	room.join_keyboard("K3")
	room.input_router.registry.set_ready(0, true)
	room.input_router.registry.set_ready(1, true)
	room.start_match()
	room.assignments = {0: str(room.egg_pool[0].egg_id), 1: str(room.egg_pool[1].egg_id)}
	room._enter_place()
	var cursor: Dictionary = room.placement_controller.cursors[0]
	cursor.variant_key = SPIKES
	cursor.cell = Vector2i(14, 8)
	cursor.quarter_turns = 0
	room.placement_controller.cursors[0] = cursor
	room._refresh_all_match_ghosts()
	var ghost := room._ghosts[0] as ItemGhost
	var preview := ghost.get_node_or_null("BlockPreview") as Node2D
	_check(
		(
			preview != null
			and preview.position == ghost.footprint_rect.get_center()
			and is_zero_approx(preview.rotation)
			and ghost.item_label == "Spikes"
			and ghost.rotation_turns == 0
		),
		"the Place ghost shows the Spikes block itself, upright, with its name"
	)
	room.placement_controller.rotate(0)
	room._refresh_match_ghost(0)
	preview = ghost.get_node_or_null("BlockPreview") as Node2D
	_check(
		(
			preview != null
			and is_equal_approx(preview.rotation, PI * 0.5)
			and ghost.rotation_turns == 1
		),
		"rotating turns the preview a quarter turn and the facing arrow reads 90°"
	)
	cursor = room.placement_controller.cursors[0]
	cursor.variant_key = KAING
	room.placement_controller.cursors[0] = cursor
	room._refresh_match_ghost(0)
	await process_frame
	var previews := ghost.get_children().filter(
		func(node: Node) -> bool: return node.name.begins_with("BlockPreview")
	)
	_check(
		previews.size() == 1 and ghost.item_label.begins_with("Kaing"),
		"switching blocks replaces the preview (one preview, now Kaing)"
	)
	room.queue_free()
	await process_frame


func _click(control: Control) -> void:
	var center := control.get_global_rect().get_center()
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = center
		event.global_position = center
		root.push_input(event, true)
		await process_frame


func _test_map_buttons_and_library_back() -> void:
	var flow := FLOW_SCENE.instantiate() as GameFlow
	root.add_child(flow)
	for _frame in range(3):
		await process_frame
	flow.router.registry.join_keyboard("K1")
	flow.tutorial_session.skip()
	flow._enter_match()
	for _frame in range(4):
		await process_frame
	var lobby := flow.room.presenter.lobby_screen
	var next_button := lobby.get_node("%NextMapButton") as Button
	var before := flow.selected_map_id
	_check(next_button.visible, "the Lobby map row has clickable arrows")
	await _click(next_button)
	for _frame in range(4):
		await process_frame
	_check(
		flow.selected_map_id == MapCatalog.cycle(before, 1),
		"clicking ▶ with the mouse picks the next map (%s -> %s)" % [before, flow.selected_map_id]
	)
	var prev_button := flow.room.presenter.lobby_screen.get_node("%PrevMapButton") as Button
	await _click(prev_button)
	for _frame in range(4):
		await process_frame
	_check(flow.selected_map_id == before, "clicking ◀ goes back")
	flow.queue_free()
	await process_frame
	var library := LIBRARY_SCENE.instantiate() as UiLibraryScreen
	root.add_child(library)
	await process_frame
	var backs := [0]
	library.back_requested.connect(func() -> void: backs[0] += 1)
	var back_button := library.get_node("%BackButton") as Button
	await _click(back_button)
	_check(
		back_button.visible and backs[0] == 1,
		"the Library has a Back button that leaves with one click"
	)
	library.queue_free()
	await process_frame

extends SceneTree

## Scene-based UI shell contract and behaviour tests (synthetic input only).

const GALLERY_SCENE := "res://scenes/ui/ui_gallery.tscn"
const THEME_PATH := "res://assets/ui/theme/tilaok_theme.tres"
const SCREEN_DIR := "res://scenes/ui/screens/"
const COMPONENT_DIR := "res://scenes/ui/components/"
const SCRIPT_DIR := "res://scripts/ui/"
const CANVAS := Rect2(0.0, 0.0, 1280.0, 720.0)
const FORBIDDEN_TOKENS := [
	"Label.new(",
	"Button.new(",
	"PanelContainer.new(",
	"VBoxContainer.new(",
	"HBoxContainer.new(",
	"MarginContainer.new(",
	"ColorRect.new(",
	"TextureRect.new(",
	"Control.new(",
	"add_theme_",
]

## Documented "do not rename" nodes per screen scene: name -> expected class.
const CONTRACT := {
	"title_screen":
	{
		"TitleLabel": "Label",
		"MenuList": "UiMenuList",
		"StartButton": "Button",
		"LibraryButton": "Button",
		"SettingsButton": "Button",
		"QuitButton": "Button",
		"BuildLabel": "Label",
		"PressToJoinPrompt": "UiPromptGlyph",
		"QuitConfirm": "UiConfirmDialog",
	},
	"lobby_screen":
	{
		"Slot1": "UiLobbySlot",
		"Slot2": "UiLobbySlot",
		"Slot3": "UiLobbySlot",
		"Slot4": "UiLobbySlot",
		"NeedPlayersLabel": "Label",
		"StartHint": "UiPromptGlyph",
		"BackHint": "UiPromptGlyph",
	},
	"tutorial_prompt":
	{
		"StepLabel": "Label",
		"BodyLabel": "Label",
		"PromptGlyph": "UiPromptGlyph",
		"SkipHint": "UiPromptGlyph",
	},
	"pugad_overlay":
	{
		"PhaseBanner": "UiPhaseBanner",
		"Countdown": "UiCountdownRing",
		"AnnounceBanner": "UiPhaseBanner",
		"LostClaimToast": "UiToastLine",
		"EggRow": "Control",
		"Egg1": "UiEggSlot",
		"Egg6": "UiEggSlot",
	},
	"place_overlay":
	{
		"PhaseBanner": "UiPhaseBanner",
		"Countdown": "UiCountdownRing",
		"ReasonToast": "UiToastLine",
		"GhostLegend": "VBoxContainer",
		"GhostStatus": "Label",
		"Pointer1": "UiPlayerBadge",
		"Pointer4": "UiPlayerBadge",
		"SeatStatus1": "UiScoreRow",
		"SeatStatus4": "UiScoreRow",
	},
	"play_hud":
	{
		"HudBar": "PanelContainer",
		"RoundLabel": "Label",
		"TwistTag": "Label",
		"ScoreRow1": "UiScoreRow",
		"ScoreRow4": "UiScoreRow",
		"TimerLabel": "Label",
		"NextEventLabel": "Label",
		"NoticeToast": "UiToastLine",
	},
	"round_result_screen":
	{
		"RoundLabel": "Label",
		"ScoreChart": "ScoreboardChart",
		"Award1": "UiAwardLine",
		"Award10": "UiAwardLine",
		"EndReasonLabel": "Label",
		"DeadlineLabel": "Label",
		"NoScoreReason": "UiToastLine",
		"ReadyHint": "UiPromptGlyph",
		"AdvanceCountdown": "UiCountdownRing",
	},
	"match_result_screen":
	{
		"WinnerBadge": "UiPlayerBadge",
		"WinnerLabel": "Label",
		"FinalChart": "ScoreboardChart",
		"LastCluckCallout": "UiPhaseBanner",
		"MenuList": "UiMenuList",
		"ReplayButton": "Button",
		"LobbyButton": "Button",
	},
	"pause_screen":
	{
		"OwnerBadge": "UiPlayerBadge",
		"OwnerLabel": "Label",
		"ReasonLabel": "Label",
		"Roster1": "UiScoreRow",
		"CountdownLabel": "Label",
		"MenuList": "UiMenuList",
		"ResumeButton": "Button",
		"ReclaimPanel": "PanelContainer",
		"ReclaimLabel": "Label",
		"LeaveConfirm": "UiConfirmDialog",
	},
	"settings_screen":
	{
		"MenuList": "UiMenuList",
		"ShakeRow": "UiOptionRow",
		"MasterRow": "UiOptionRow",
		"MusicRow": "UiOptionRow",
		"EffectsRow": "UiOptionRow",
		"CrowdRow": "UiOptionRow",
		"BackButton": "Button",
	},
	"library_screen":
	{
		"CategoryList": "UiMenuList",
		"EntryList": "UiMenuList",
		"EntryTitle": "Label",
		"EntrySummary": "Label",
		"EntryBody": "Label",
		"Steps": "VBoxContainer",
		"AnimationFrame": "PanelContainer",
		"AnimationHost": "Control",
		"ReleaseFilterButton": "Button",
		"BackButton": "UiLibraryTabButton",
		"ChooseKey": "Label",
		"ReadKey": "Label",
		"BackKey": "Label",
	},
	"events_overlay":
	{
		"TayaMarker": "PanelContainer",
		"KangarooPrompt": "PanelContainer",
	},
}

var failures := 0
var checks := 0
var gallery: UiGallery


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_resources_load()
	_test_script_source_rules()
	await _test_contract()
	await _test_gallery_screens()
	await _test_input_behaviour()
	await _test_art_slot_and_theme_swap()
	await _test_lifecycle_cycles()
	print("UI_TESTS checks=%d failures=%d" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _test_resources_load() -> void:
	var theme := load(THEME_PATH) as Theme
	_check(theme != null, "project Theme loads")
	if theme != null:
		for type_name in [
			"TilaokMenuButton",
			"MenuButtonSelected",
			"RowPanelSelected",
			"GhostValid",
			"GhostInvalid",
			"GhostProtected",
			"GhostRotationOff",
			"GhostConfirmed",
			"SafeAreaMargin",
			"HudBar",
			"HudLabel",
			"Backdrop",
			"RowPanelCompact",
		]:
			_check(Array(theme.get_type_list()).has(type_name), "Theme defines %s" % type_name)
		_check(
			theme.get_constant("min_midround_font_px", "TilaokPolicy") >= 16,
			"Theme policy: mid-round minimum font size is at least 16 px"
		)
	for path in [
		"res://data/ui/prompt_map.tres",
		"res://data/ui/sample_match_4p.tres",
		"res://data/ui/sample_match_2p.tres",
		"res://data/ui/library_text.tres",
	]:
		_check(load(path) != null, "resource loads: %s" % path)
	for dir_path in [SCREEN_DIR, COMPONENT_DIR]:
		for file_name in DirAccess.get_files_at(dir_path):
			if file_name.ends_with(".tscn"):
				var scene := load(dir_path + file_name) as PackedScene
				_check(scene != null, "scene loads: %s" % file_name)
				if scene != null:
					var node := scene.instantiate()
					_check(node != null, "scene instantiates: %s" % file_name)
					if node != null:
						node.free()


func _test_script_source_rules() -> void:
	for file_name in DirAccess.get_files_at(SCRIPT_DIR):
		if not file_name.ends_with(".gd"):
			continue
		var text := FileAccess.get_file_as_string(SCRIPT_DIR + file_name)
		var clean := true
		for token in FORBIDDEN_TOKENS:
			if text.contains(token):
				clean = false
				push_error("%s contains %s" % [file_name, token])
		_check(clean, "%s builds no layout and sets no theme overrides" % file_name)


func _test_contract() -> void:
	for scene_name in CONTRACT:
		var scene := load(SCREEN_DIR + scene_name + ".tscn") as PackedScene
		var screen := scene.instantiate() as Control
		root.add_child(screen)
		await process_frame
		var table: Dictionary = CONTRACT[scene_name]
		for node_name in table:
			var node := screen.get_node_or_null("%" + str(node_name))
			var ok := node != null and node.is_class(str(table[node_name]))
			if node != null and not ok:
				var script_name := _script_class(node)
				ok = script_name == str(table[node_name])
			_check(ok, "%s: %%%s is %s" % [scene_name, node_name, table[node_name]])
		_check_buttons_unfocusable(screen, scene_name)
		root.remove_child(screen)
		screen.free()


func _test_gallery_screens() -> void:
	gallery = (load(GALLERY_SCENE) as PackedScene).instantiate() as UiGallery
	root.add_child(gallery)
	await process_frame
	await process_frame
	gallery.set_chrome_visible(false)
	_check(
		gallery.screen_scenes.size() == UiGallery.SCREEN_IDS.size(),
		"gallery lists one scene per screen id"
	)
	_check(
		gallery.get_node("%ScreenList").get_child_count() == UiGallery.SCREEN_IDS.size(),
		"gallery has one button per screen id"
	)
	for players in [1, 4]:
		gallery.set_players(players)
		for index in UiGallery.SCREEN_IDS.size():
			gallery.show_screen(index)
			var states := gallery.current.state_names().size()
			for state in states:
				gallery.set_state(state)
				await process_frame
				await process_frame
				var label := "%s/%d players/state %d" % [gallery.screen_id(index), players, state]
				_check_inside_canvas(gallery.current, label)
				_check_midround_text(gallery.current, label)
	gallery.set_players(4)
	gallery.show_screen(gallery.index_of("play_hud"))
	await process_frame
	await process_frame
	var hud := gallery.current as UiPlayHud
	_check(
		is_equal_approx(hud.hud_bar.size.y, gallery.context.tuning.camera_hud_reservation_px),
		"Play HUD bar is exactly the HUD reservation tall (%s px)" % hud.hud_bar.size.y
	)
	_check(
		is_equal_approx(hud.hud_bar.global_position.y, 0.0),
		"Play HUD bar sits at the top of the canvas"
	)
	for row in hud.score_rows:
		_check(
			row.badge.visible_shape() == row.badge.shape_name and row.badge.number_text() != "-",
			"HUD score row shows number and shape for seat %s" % row.badge.number_text()
		)
	gallery.show_screen(gallery.index_of("lobby"))
	await process_frame
	var lobby := gallery.current as UiLobbyScreen
	gallery.set_state(3)
	await process_frame
	for slot in lobby.slots:
		_check(
			slot.badge.visible_shape() != "" and slot.badge.number_text() != "-",
			"lobby slot shows number and shape for seat %s" % slot.badge.number_text()
		)


func _test_input_behaviour() -> void:
	gallery.set_players(2)
	var title_index := gallery.index_of("title")
	gallery.show_screen(title_index)
	await process_frame
	var title := gallery.current as UiTitleScreen
	var started := [0]
	title.start_requested.connect(func() -> void: started[0] += 1)
	var menu: UiMenuList = title.get_node("%MenuList")
	_check(menu.selected == 0, "title menu starts on the first item")
	await _tap(KEY_S)
	_check(menu.selected == 1, "K1 down moves the title selection")
	await _tap(KEY_W)
	_check(menu.selected == 0, "K1 up moves the title selection back")
	gallery.context.owner_seat = 0
	gallery._apply_to_screen()
	title = gallery.current as UiTitleScreen
	started[0] = 0
	await _tap(KEY_DOWN)
	_check(
		(title.get_node("%MenuList") as UiMenuList).selected == 0,
		"K2 cannot drive a menu owned by seat 1"
	)
	await _tap(KEY_E)
	_check(started[0] == 1, "K1 confirm activates Start exactly once (got %d)" % started[0])
	_check(gallery.current is UiLobbyScreen, "Start opens the lobby")
	await _send_key(KEY_E, true)
	gallery.show_screen(gallery.index_of("title"))
	await process_frame
	_check(
		not gallery.router.consume_pressed(0, "ready"),
		"a held press is consumed by the screen transition"
	)
	await _send_key(KEY_E, false)
	gallery.show_screen(gallery.index_of("settings"))
	await process_frame
	var settings := gallery.current as UiSettingsScreen
	var shake: UiOptionRow = settings.get_node("%ShakeRow")
	shake.set_choice(0)
	var before := shake.index
	await _tap(KEY_D)
	_check(shake.index == before + 1, "K1 right changes the shake choice")
	var changed := [-1]
	settings.shake_changed.connect(func(mode: int) -> void: changed[0] = mode)
	await _tap(KEY_D)
	_check(changed[0] == 2 or shake.index == 2, "shake choice reaches Off through the screen")
	var pad_event := InputEventJoypadButton.new()
	pad_event.device = UiGallery.FIRST_GAMEPAD_ID + 2
	pad_event.button_index = JOY_BUTTON_DPAD_DOWN
	gallery.set_players(4)
	gallery.context.owner_seat = 2
	gallery._apply_to_screen()
	settings = gallery.current as UiSettingsScreen
	var settings_menu: UiMenuList = settings.get_node("%MenuList")
	var start_index := settings_menu.selected
	pad_event.pressed = true
	Input.parse_input_event(pad_event)
	await process_frame
	pad_event.pressed = false
	Input.parse_input_event(pad_event)
	await process_frame
	_check(
		settings_menu.selected != start_index,
		"synthetic gamepad d-pad (seat 3) drives a menu it owns"
	)
	gallery.context.owner_seat = 0
	gallery._apply_to_screen()


func _test_art_slot_and_theme_swap() -> void:
	gallery.set_players(4)
	gallery.show_screen(gallery.index_of("lobby"))
	await process_frame
	var lobby := gallery.current as UiLobbyScreen
	var image := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	image.fill(Color.MAGENTA)
	var texture := ImageTexture.create_from_image(image)
	var circle: TextureRect = lobby.slots[0].badge.get_node("%Art_Circle")
	circle.texture = texture
	lobby.bind_seats(UiContext.sample_seats(4), gallery.context.prompt_map, "k1")
	_check(
		circle.visible and not (lobby.slots[0].badge.get_node("%ShapeCircle") as Polygon2D).visible,
		"assigning a texture to Art_Circle replaces the placeholder polygon with no code change"
	)
	var alt := (load(THEME_PATH) as Theme).duplicate() as Theme
	alt.default_font_size = 18
	alt.set_font_size("font_size", "Label", 18)
	gallery.alt_theme = alt
	gallery.swap_theme()
	await process_frame
	await process_frame
	_check(gallery.theme == alt, "gallery hot-swaps to a second Theme")
	_check_inside_canvas(gallery.current, "lobby with the swapped theme")
	gallery.swap_theme()
	_check(gallery.theme == gallery.base_theme, "gallery swaps back to the project Theme")


func _test_lifecycle_cycles() -> void:
	gallery.show_screen(gallery.index_of("title"))
	await process_frame
	await process_frame
	var nodes_before := Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	var orphans_before := Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	for _cycle in 10:
		for index in UiGallery.SCREEN_IDS.size():
			gallery.show_screen(index)
			await process_frame
		gallery.show_screen(gallery.index_of("title"))
		await process_frame
		await process_frame
	var nodes_after := Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	var orphans_after := Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	_check(
		nodes_after == nodes_before,
		"10 open/close cycles keep node count stable (%d -> %d)" % [nodes_before, nodes_after]
	)
	_check(
		orphans_after <= orphans_before,
		"10 open/close cycles leave no new orphans (%d -> %d)" % [orphans_before, orphans_after]
	)
	gallery.queue_free()
	await process_frame


func _check_buttons_unfocusable(node: Node, label: String) -> void:
	for child in node.get_children():
		if child is BaseButton:
			_check(
				(child as BaseButton).focus_mode == Control.FOCUS_NONE,
				(
					"%s: button %s has no Godot focus (no Enter double-activation)"
					% [label, child.name]
				)
			)
		_check_buttons_unfocusable(child, label)


func _check_inside_canvas(screen: Node, label: String) -> void:
	var outside: Array[String] = []
	for control in _visible_controls(screen):
		var rect := control.get_global_rect()
		if rect.size.x <= 0.0 or rect.size.y <= 0.0:
			continue
		if (
			rect.position.x < CANVAS.position.x - 0.5
			or rect.position.y < CANVAS.position.y - 0.5
			or rect.end.x > CANVAS.end.x + 0.5
			or rect.end.y > CANVAS.end.y + 0.5
		):
			outside.append("%s %s" % [control.name, rect])
	_check(outside.is_empty(), "%s: controls inside 1280x720 %s" % [label, outside.slice(0, 3)])


func _check_midround_text(screen: Node, label: String) -> void:
	var minimum := int(
		(load(THEME_PATH) as Theme).get_constant("min_label_font_px", "TilaokPolicy")
	)
	var small: Array[String] = []
	for control in _visible_controls(screen):
		if control is Label and control.get_theme_font_size("font_size") < minimum:
			small.append(str(control.name))
	_check(small.is_empty(), "%s: text at least %d px %s" % [label, minimum, small.slice(0, 3)])


func _visible_controls(node: Node) -> Array[Control]:
	var result: Array[Control] = []
	for child in node.get_children():
		var control := child as Control
		if control != null and control.is_visible_in_tree():
			result.append(control)
		result.append_array(_visible_controls(child))
	return result


func _script_class(node: Node) -> String:
	var script := node.get_script() as Script
	return str(script.get_global_name()) if script != null else ""


func _tap(key: Key) -> void:
	await _send_key(key, true)
	await _send_key(key, false)
	await process_frame


func _send_key(key: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.pressed = pressed
	Input.parse_input_event(event)
	await process_frame


func _check(condition: bool, label: String) -> void:
	checks += 1
	if condition:
		print("PASS ", label)
	else:
		failures += 1
		push_error("FAIL " + label)

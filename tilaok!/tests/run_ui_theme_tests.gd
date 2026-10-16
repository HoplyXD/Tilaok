extends SceneTree

## Reference-restyle contract: Theme tokens, bundled fonts and their licences, the new reusable
## components (plank button, vine, seat pill, score chip, both confirm skins) and the identity
## rules they must keep (number + shape beside colour). Synthetic input only.

const THEME_PATH := "res://assets/ui/theme/tilaok_theme.tres"
const COMPONENT_DIR := "res://scenes/ui/components/"
const FONT_FILES := {
	"res://assets/fonts/handlee/Handlee-Regular.ttf": "res://assets/fonts/handlee/OFL.txt",
	"res://assets/fonts/mansalva/Mansalva-Regular.ttf": "res://assets/fonts/mansalva/OFL.txt",
	"res://assets/fonts/margarine/Margarine-Regular.ttf": "res://assets/fonts/margarine/OFL.txt",
	"res://assets/fonts/mountains_of_christmas/MountainsofChristmas-Bold.ttf":
	"res://assets/fonts/mountains_of_christmas/LICENSE.txt",
	"res://assets/fonts/road_rage/RoadRage-Regular.ttf": "res://assets/fonts/road_rage/OFL.txt",
}
const NEW_TYPES := [
	"BackdropWarm",
	"PanelPaper",
	"PanelRivet",
	"PaperBacking",
	"Rivet",
	"ScoreChip",
	"PillSeat1",
	"PillSeat2",
	"PillSeat3",
	"PillSeat4",
	"PillWarning",
	"KeyCap",
	"KeyCapLabel",
	"PromptAction",
	"ChalkboardPanel",
	"ScreenTitle",
	"PaperTitle",
	"ResultTitle",
	"SlotState",
	"SlotDevice",
	"BadgeNumberDark",
	"ChipLabel",
	"ChipState",
	"GuideTitle",
	"GuideBody",
]
const LEGEND_TYPES := {
	"tapos": "LegendTapos",
	"una": "LegendUna",
	"bayani": "LegendBayani",
	"patibong": "LegendPatibong",
	"bawi": "LegendBawi",
	"barya": "LegendBarya",
	"placement": "LegendPlacement",
}
## Variations read during a round (HUD, Place) must meet the mid-round minimum.
const MIDROUND_TYPES := ["HudLabel", "HudTitle", "HudSub", "ChipLabel", "ChipState", "TwistTag"]

var failures := 0
var checks := 0
var theme: Theme


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	theme = load(THEME_PATH) as Theme
	_check(theme != null, "project Theme loads")
	_test_theme_tokens()
	_test_fonts()
	await _test_plank_button()
	await _test_badge_variants()
	await _test_confirm_dialogs()
	await _test_lobby_open_slot()
	await _test_component_sheet()
	print("UI_THEME_TESTS checks=%d failures=%d" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _test_theme_tokens() -> void:
	var types := Array(theme.get_type_list())
	for type_name in NEW_TYPES:
		_check(types.has(type_name), "Theme defines %s" % type_name)
	for key in LEGEND_TYPES:
		var legend := theme.get_color("font_color", str(LEGEND_TYPES[key]))
		var chart := theme.get_color(key, "ScoreAward")
		_check(
			legend.is_equal_approx(chart),
			"%s letter colour equals the ScoreAward/%s chart colour" % [LEGEND_TYPES[key], key]
		)
	var minimum := theme.get_constant("min_midround_font_px", "TilaokPolicy")
	for type_name in MIDROUND_TYPES:
		_check(
			theme.get_font_size("font_size", type_name) >= minimum,
			"%s is at least the %d px mid-round minimum" % [type_name, minimum]
		)
	var label_minimum := theme.get_constant("min_label_font_px", "TilaokPolicy")
	var small: Array[String] = []
	for type_name in types:
		if theme.has_font_size("font_size", type_name):
			if theme.get_font_size("font_size", type_name) < label_minimum:
				small.append(str(type_name))
	_check(small.is_empty(), "no Theme text type is below %d px %s" % [label_minimum, small])
	for state in ["normal", "hover", "pressed", "disabled"]:
		_check(
			theme.has_stylebox(state, "TilaokMenuButton"),
			"plank button has a %s look" % state
		)
	_check(
		theme.get_stylebox("normal", "MenuButtonSelected")
		== theme.get_stylebox("hover", "TilaokMenuButton"),
		"router-selected menu entry uses the Hovered plank look"
	)


func _test_fonts() -> void:
	var default_font := theme.default_font
	_check(
		default_font != null and default_font.resource_path.ends_with("Handlee-Regular.ttf"),
		"Theme default font is Handlee (replaces Lemonade)"
	)
	for font_path in FONT_FILES:
		var font := load(font_path) as FontFile
		_check(font != null, "font loads: %s" % font_path.get_file())
		_check(
			FileAccess.file_exists(str(FONT_FILES[font_path])),
			"licence text ships beside %s" % font_path.get_file()
		)


func _test_plank_button() -> void:
	var plank := (load(COMPONENT_DIR + "plank_button.tscn") as PackedScene).instantiate() as Button
	root.add_child(plank)
	await process_frame
	_check(plank.focus_mode == Control.FOCUS_NONE, "plank button never takes Godot focus")
	_check(
		plank.get_node("RivetLeft") is Panel and plank.get_node("RivetRight") is Panel,
		"plank button has its two rivets as scene nodes"
	)
	_check(
		(plank.get_node("RivetLeft") as Control).mouse_filter == Control.MOUSE_FILTER_IGNORE,
		"rivets never swallow a click"
	)
	plank.queue_free()
	await process_frame


func _test_badge_variants() -> void:
	var seats := UiContext.sample_seats(4)
	var chip := (load(COMPONENT_DIR + "score_chip.tscn") as PackedScene).instantiate() as UiScoreRow
	var pill := (load(COMPONENT_DIR + "seat_pill.tscn") as PackedScene).instantiate() as UiScoreRow
	root.add_child(chip)
	root.add_child(pill)
	await process_frame
	chip.bind_units(seats[2], 18, "RUN")
	pill.bind_roster(seats[2], "READY")
	var chip_shape := chip.badge.get_node("%ShapeSquare") as Polygon2D
	var pill_shape := pill.badge.get_node("%ShapeSquare") as Polygon2D
	_check(
		chip.badge.visible_shape() == "SQUARE" and chip.badge.number_text() == "3",
		"score chip keeps number and shape"
	)
	_check(
		(chip.badge.get_node("%PrefixLabel") as Label).text == "P"
		and (chip.badge.get_node("%PrefixLabel") as Label).visible,
		"score chip reads P3"
	)
	_check(
		chip_shape.color.is_equal_approx((seats[2].color as Color).darkened(0.45)),
		"score chip darkens the seat colour for a cream surface"
	)
	_check(
		pill.badge.visible_shape() == "SQUARE" and pill.badge.number_text() == "3",
		"seat pill keeps number and shape"
	)
	_check(
		not pill_shape.color.is_equal_approx(seats[2].color as Color),
		"seat pill paints the shape plain so it shows on the seat-coloured pill"
	)
	_check(
		(pill.badge.get_node("%PrefixLabel") as Label).text == "Player ",
		"seat pill reads Player 3"
	)
	chip.queue_free()
	pill.queue_free()
	await process_frame


func _test_confirm_dialogs() -> void:
	for scene_name in ["confirm_dialog", "confirm_dialog_paper"]:
		var dialog := (
			(load(COMPONENT_DIR + scene_name + ".tscn") as PackedScene).instantiate()
			as UiConfirmDialog
		)
		root.add_child(dialog)
		await process_frame
		var confirmed := [0]
		dialog.confirmed.connect(func() -> void: confirmed[0] += 1)
		dialog.open("Leave?")
		var menu := dialog.get_node("%Menu") as UiMenuList
		_check(menu.selected == 1, "%s opens on No" % scene_name)
		_check(dialog.navigate("up") and menu.selected == 0, "%s: up moves to Yes" % scene_name)
		_check(dialog.navigate("right") and menu.selected == 1, "%s: right moves" % scene_name)
		_check(dialog.navigate("left") and menu.selected == 0, "%s: left still moves" % scene_name)
		dialog.accept()
		_check(confirmed[0] == 1 and not dialog.is_open(), "%s: Yes confirms once" % scene_name)
		var heading := dialog.get_node("Content/Heading") as Label
		var rivets := dialog.get_node("Rivets") as Control
		var backing := dialog.get_node("Decor/Backing") as Control
		if scene_name == "confirm_dialog":
			_check(
				rivets.visible and not heading.visible and not backing.visible,
				"in-game Leave match uses the rivet panel"
			)
		else:
			_check(
				not rivets.visible and heading.visible and backing.visible,
				"Quit uses the torn-paper panel with its heading"
			)
		dialog.queue_free()
		await process_frame


func _test_lobby_open_slot() -> void:
	var screen := (
		(load("res://scenes/ui/screens/lobby_screen.tscn") as PackedScene).instantiate()
		as UiLobbyScreen
	)
	root.add_child(screen)
	await process_frame
	var ctx := UiContext.make(2, "k1")
	screen.bind_seats(UiContext.sample_seats(2), ctx.prompt_map, "k1")
	var open_slot := screen.slots[3]
	_check(screen.joined_count() == 2, "open-slot previews do not count as joined seats")
	_check(
		open_slot.badge.number_text() == "4" and open_slot.badge.visible_shape() == "DIAMOND",
		"open slot previews its fixed number and shape"
	)
	_check(open_slot.badge.modulate.a < 1.0, "the preview is faded")
	_check(open_slot.state_text() == "Open slot", "open slot says so in text")
	_check(screen.slots[0].badge.modulate.a == 1.0, "a joined seat's badge is not faded")
	screen.queue_free()
	await process_frame


func _test_component_sheet() -> void:
	_check(UiGallery.SCREEN_IDS.has("components"), "UI Gallery lists the component sheet")
	var sheet := (
		(load("res://scenes/ui/screens/component_sheet.tscn") as PackedScene).instantiate()
		as UiComponentSheet
	)
	root.add_child(sheet)
	await process_frame
	sheet.show_state(0, UiContext.make(4, "k1"))
	await process_frame
	for index in sheet.pills.size():
		_check(
			sheet.pills[index].badge.number_text() == str(index + 1),
			"component sheet pill %d shows its number" % (index + 1)
		)
	sheet.queue_free()
	await process_frame


func _check(condition: bool, label: String) -> void:
	checks += 1
	if condition:
		print("PASS ", label)
	else:
		failures += 1
		push_error("FAIL " + label)

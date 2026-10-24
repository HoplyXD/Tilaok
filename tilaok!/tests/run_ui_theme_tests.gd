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
	"RivetDisabled",
	"PlankPressedFrame",
	"PlankPressedShadeTop",
	"PlankPressedShadeLeft",
	"PlankPressedShadeRight",
	"PlankClip",
	"PlankStroke",
	"PlankStrokePressed",
	"PlankStrokeDisabled",
	"PlankStrokeMask",
]
## Exact values from the Figma "Button Variants" frame (16:434):
## state -> [fill, outline gradient Theme type, gradient stop colours at 0 / 0.639 / 0.884].
## Owner decision 2026-10-17: the Normal and Hovered fills are swapped (Normal orange, Hovered
## and router-selected brown).
const PLANK_FIGMA := {
	"normal": ["#eb9c62", "PlankStroke", ["#000000", "#665b44", "#d8c190"]],
	"hover": ["#b77748", "PlankStroke", ["#000000", "#665b44", "#d8c190"]],
	"pressed": ["#885a39", "PlankStrokePressed", ["#000000", "#665b44", "#e5cd98"]],
	"disabled": ["#bc9d86", "PlankStrokeDisabled", ["#484848", "#918b80", "#d4c39e"]],
}
const PLANK_STOP_OFFSETS := [0.0, 0.639, 0.884]
## Exact values from the Figma "Menu actions" frame (103:562): Theme type -> [style or colour
## name, expected colour]. Normal is "Menu action" (103:571), Selected is "Play action" (103:563).
const MENU_ACTION_FIGMA := {
	"MenuAction": ["normal", "#b99669"],
	"MenuActionSelected": ["normal", "#86502f"],
	"MenuActionFace": ["panel", "#ead5af"],
	"MenuActionFaceSelected": ["panel", "#b77748"],
	"MenuActionInset": ["panel", "#f8e9cb"],
	"MenuActionInsetSelected": ["panel", "#e6b484"],
	"MenuActionFastening": ["panel", "#ae8659"],
	"MenuActionFasteningSelected": ["panel", "#86502f"],
	"MenuActionShadow": ["panel", "#af895d66"],
	"MenuActionShadowSelected": ["panel", "#754526"],
}
## Figma gradientTransform row 1: t = -0.216 u - 0.683 v + 1.165 over the button's u, v.
const PLANK_GRADIENT_T := Vector3(-0.216, -0.683, 1.165)
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
	await _test_menu_action_button()
	await _test_badge_variants()
	await _test_confirm_dialogs()
	await _test_lobby_open_slot()
	await _test_component_sheet()
	await _test_pause_frame()
	await _test_round_result_frame()
	await _test_place_frame()
	await _test_pugad_frame()
	await _test_tutorial_card()
	await _test_final_result_frame()
	await _test_title_card()
	await _test_library_frame()
	await _test_settings_frame()
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
		_check(theme.has_stylebox(state, "TilaokMenuButton"), "plank button has a %s look" % state)
	_check(
		(
			theme.get_stylebox("normal", "MenuButtonSelected")
			== theme.get_stylebox("hover", "TilaokMenuButton")
		),
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
	for state in PLANK_FIGMA:
		var spec: Array = PLANK_FIGMA[state]
		var box := theme.get_stylebox(state, "TilaokMenuButton") as StyleBoxFlat
		var fill := Color.html(str(spec[0]))
		_check(
			(
				box != null
				and _near(box.bg_color, fill)
				and box.shadow_size == 0
				and box.shadow_offset == Vector2.ZERO
			),
			"plank %s fill is the Figma #%s with no drop shadow" % [state, fill.to_html(false)]
		)
		_check(
			_gradient_matches(str(spec[1]), spec[2]),
			"plank %s outline gradient matches Figma stops %s and direction" % [state, spec[2]]
		)
	var stroke := plank.get_node("Stroke") as Control
	var stroke_gradient := plank.get_node("Stroke/Gradient") as Control
	var pressed_look := plank.get_node("PressedLook") as Control
	_check(
		(
			stroke.clip_children == CanvasItem.CLIP_CHILDREN_ONLY
			and pressed_look.clip_children == CanvasItem.CLIP_CHILDREN_ONLY
		),
		"outline gradient and pressed shadow are clipped to the rounded plank shape"
	)
	var rivet := plank.get_node("RivetLeft") as Control
	_check(
		(
			not pressed_look.visible
			and rivet.theme_type_variation == &"Rivet"
			and stroke_gradient.theme_type_variation == &"PlankStroke"
		),
		"Normal plank: normal outline gradient, no pressed shadow, dark rivets"
	)
	plank.toggle_mode = true
	plank.button_pressed = true
	await process_frame
	await process_frame
	_check(
		pressed_look.visible and stroke_gradient.theme_type_variation == &"PlankStrokePressed",
		"Pressed plank shows its inner frame, group shadow and pressed outline gradient"
	)
	plank.button_pressed = false
	plank.disabled = true
	await process_frame
	await process_frame
	_check(
		(
			not pressed_look.visible
			and stroke_gradient.theme_type_variation == &"PlankStrokeDisabled"
			and rivet.theme_type_variation == &"RivetDisabled"
			and (plank.get_node("RivetRight") as Control).theme_type_variation == &"RivetDisabled"
		),
		"Disabled plank uses the grey outline gradient and fades both rivets"
	)
	_check(
		_near(theme.get_stylebox("panel", "RivetDisabled").bg_color, Color.html("#775f57")),
		"disabled rivet colour is the Figma #775f57"
	)
	plank.disabled = false
	await process_frame
	await process_frame
	_check(rivet.theme_type_variation == &"Rivet", "re-enabled plank restores the dark rivets")
	plank.queue_free()
	await process_frame


## True when the Theme type's gradient has the Figma stops and runs in the Figma direction.
func _gradient_matches(type_name: String, colors: Array) -> bool:
	var box := theme.get_stylebox("panel", type_name) as StyleBoxTexture
	if box == null or not (box.texture is GradientTexture2D):
		return false
	var texture := box.texture as GradientTexture2D
	var gradient := texture.gradient
	if gradient.get_point_count() != PLANK_STOP_OFFSETS.size():
		return false
	for i in PLANK_STOP_OFFSETS.size():
		if absf(gradient.get_offset(i) - PLANK_STOP_OFFSETS[i]) > 0.001:
			return false
		if not _near(gradient.get_color(i), Color.html(str(colors[i]))):
			return false
	# Godot's linear fill: t = (p - from) . (to - from) / |to - from|^2. Compare with Figma's t.
	var span := texture.fill_to - texture.fill_from
	var corners: Array[Vector2] = [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 1)]
	for corner in corners:
		var godot_t: float = (corner - texture.fill_from).dot(span) / span.length_squared()
		var figma_t: float = (
			PLANK_GRADIENT_T.x * corner.x + PLANK_GRADIENT_T.y * corner.y + PLANK_GRADIENT_T.z
		)
		if absf(godot_t - figma_t) > 0.002:
			return false
	return true


func _near(a: Color, b: Color) -> bool:
	return absf(a.r - b.r) < 0.004 and absf(a.g - b.g) < 0.004 and absf(a.b - b.b) < 0.004


## Menu action button from Figma frame 103:562 "Menu actions": exact colours, the 54 / 72 px
## heights, the pointer and icon only while selected, and the Title menu moving the brown look.
func _test_menu_action_button() -> void:
	for type_name in MENU_ACTION_FIGMA:
		var spec: Array = MENU_ACTION_FIGMA[type_name]
		var box := theme.get_stylebox(str(spec[0]), str(type_name)) as StyleBoxFlat
		var want := Color.html(str(spec[1]))
		# The inset edge is an outline only; everything else is a fill.
		var got := Color.BLACK
		if box != null:
			got = box.bg_color if box.draw_center else box.border_color
		_check(
			box != null and _near(got, want) and absf(got.a - want.a) < 0.004,
			"%s is the Figma %s" % [type_name, spec[1]]
		)
	var shadow := theme.get_stylebox("panel", "MenuActionShadow") as StyleBoxFlat
	var shadow_selected := theme.get_stylebox("panel", "MenuActionShadowSelected") as StyleBoxFlat
	_check(
		(
			shadow.get_expand_margin(SIDE_BOTTOM) == 3.0
			and shadow_selected.get_expand_margin(SIDE_BOTTOM) == 4.0
		),
		"menu action drop shadows reach 3 px (normal) and 4 px (selected) below, as Figma 0 3 0 / 0 4 0"
	)
	_check(
		(
			_near(theme.get_color("font_color", "MenuActionText"), Color.html("#684127"))
			and theme.get_font_size("font_size", "MenuActionText") == 22
			and _near(
				theme.get_color("font_color", "MenuActionTextSelected"), Color.html("#fff8e8")
			)
			and theme.get_font_size("font_size", "MenuActionTextSelected") == 31
			and theme.get_constant("separation", "MenuActionRow") == 13
		),
		"menu action text: Margarine 22 #684127, selected 31 #fff8e8, 13 px after the icon"
	)
	var holder := VBoxContainer.new()
	root.add_child(holder)
	holder.theme = theme
	var button := (
		(load(COMPONENT_DIR + "menu_action_button.tscn") as PackedScene).instantiate()
		as UiMenuActionButton
	)
	button.text = "Play"
	button.action_icon = load("res://assets/ui/common/ui.common.icon_play.svg") as Texture2D
	holder.add_child(button)
	await process_frame
	await process_frame
	var pointer := button.get_node("Pointer") as Control
	var icon := button.get_node("ActionLabel/Icon") as Control
	var label := button.get_node("ActionLabel/Label") as Label
	_check(
		(
			button.size.is_equal_approx(Vector2(388, 54))
			and not pointer.visible
			and not icon.visible
			and label.text == "Play"
			and label.theme_type_variation == &"MenuActionText"
			and button.get_node("Face").theme_type_variation == &"MenuActionFace"
		),
		"normal menu action is 388 x 54, cream, text only, no pointer (%s)" % button.size
	)
	button.set_selected(true)
	await process_frame
	await process_frame
	_check(
		(
			button.size.is_equal_approx(Vector2(388, 72))
			and pointer.visible
			and icon.visible
			and label.theme_type_variation == &"MenuActionTextSelected"
			and button.get_node("Face").theme_type_variation == &"MenuActionFaceSelected"
			and button.get_node("Inset").theme_type_variation == &"MenuActionInsetSelected"
			and (
				button.get_node("FasteningLeft").theme_type_variation
				== &"MenuActionFasteningSelected"
			)
		),
		"selected menu action is 388 x 72, brown, icon and pointer shown (%s)" % button.size
	)
	_check(
		(
			pointer.get_rect().is_equal_approx(Rect2(-29, 25, 15, 22))
			and button.get_node("FasteningLeft").get_rect().is_equal_approx(Rect2(18, 33.5, 5, 5))
			and button.get_node("Inset").get_rect().is_equal_approx(Rect2(5, 5, 378, 60))
		),
		"pointer, fastening and inset edge sit where the frame puts them"
	)
	button.text = "Settings"
	await process_frame
	_check(label.text == "Settings", "the visible label follows the button text")
	holder.queue_free()
	await process_frame

	var title := (
		(load("res://scenes/ui/screens/title_screen.tscn") as PackedScene).instantiate()
		as UiTitleScreen
	)
	root.add_child(title)
	await process_frame
	title.show_state(0, UiContext.make(1, "k1"))
	await process_frame
	await process_frame
	var menu := title.get_node("%MenuList") as UiMenuList
	var buttons: Array[UiMenuActionButton] = []
	for item in menu.items:
		if item is UiMenuActionButton:
			buttons.append(item)
	_check(
		buttons.size() == 4 and buttons[0].text == "Play" and buttons[0].action_icon != null,
		"Title menu is four menu action buttons, Play first with the play icon"
	)
	if buttons.size() == 4:
		_check(
			(
				buttons[0].selected
				and buttons[0].size.y == 72.0
				and buttons[1].size.y == 54.0
				and is_equal_approx(buttons[1].position.y - buttons[0].position.y, 88.0)
			),
			"Title opens on Play selected (72 px), the rest 54 px, 16 px apart"
		)
		menu.move("down")
		await process_frame
		await process_frame
		_check(
			(
				not buttons[0].selected
				and buttons[1].selected
				and buttons[0].size.y == 54.0
				and buttons[1].size.y == 72.0
				and buttons[1].get_node("Pointer").visible
				and not buttons[0].get_node("Pointer").visible
			),
			"moving down hands the brown, tall look and the pointer to Library"
		)
		menu.set_active(false)
		await process_frame
		_check(
			buttons.all(func(b: UiMenuActionButton) -> bool: return not b.selected),
			"an inactive Title menu (quit dialog open) shows no selected button"
		)
	title.queue_free()
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
		(
			(chip.badge.get_node("%PrefixLabel") as Label).text == "P"
			and (chip.badge.get_node("%PrefixLabel") as Label).visible
		),
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
		(pill.badge.get_node("%PrefixLabel") as Label).text == "Player ", "seat pill reads Player 3"
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
	var joined_seats := UiContext.sample_seats(2)
	for index in screen.slots.size():
		var chicken := screen.slots[index].get_node("%PreviewChicken") as ChickenController
		var seat: Dictionary = joined_seats[index]
		if bool(seat.get("joined", false)):
			_check(
				(
					chicken != null
					and chicken.marker_color == seat.color
					and chicken.identity_shape == seat.shape
					and is_equal_approx(chicken.modulate.a, 1.0)
				),
				"joined Lobby player %d sees their own chicken color and shape" % (index + 1)
			)
		else:
			_check(
				(
					chicken != null
					and chicken.modulate.a < 0.5
					and chicken.marker_color == PlayerSeatRegistry.COLORS[index]
				),
				"empty Lobby slot %d shows its own colour's chicken, faded" % (index + 1)
			)
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


## Pause screen built from Figma frames 5:44 / 5:81: exact frame values, game seat colours, and
## the live states (shared / owner, quiet reason, countdown, reclaim pill) still working.
func _test_pause_frame() -> void:
	var pause := (
		(load("res://scenes/ui/screens/pause_screen.tscn") as PackedScene).instantiate()
		as UiPauseScreen
	)
	root.add_child(pause)
	await process_frame
	pause.bind_prompts(UiContext.make(4, "gamepad").prompt_map, "gamepad")
	var seats := UiContext.sample_seats(4)
	pause.bind_state(UiPauseScreen.reason_text("shared system pause"), -1, 0.0, seats, {})
	await process_frame
	await process_frame
	var panel := pause.get_node("Center/Panel") as Control
	_check(
		panel.size.is_equal_approx(Vector2(385, 506)),
		"Pause paper is the Figma 214 x 281 at 1.8x (%s)" % panel.size
	)
	var paper_art := pause.get_node("Center/Panel/Decor/PaperArt/Art_Panel") as NinePatchRect
	var paper_image := paper_art.texture.get_image()
	_check(
		paper_image.get_pixel(0, 0).a < 0.05 and paper_image.get_pixel(300, 400).a > 0.99,
		"paper art is the Figma render with a transparent surround and an opaque sheet"
	)
	var backing := pause.get_node("Center/Panel/Decor/Backing") as Control
	_check(
		(
			absf(rad_to_deg(backing.rotation) + 2.344) < 0.01
			and _near(theme.get_stylebox("panel", "PauseBacking").bg_color, Color.html("#9e6941"))
		),
		"backing is the Figma #9e6941 sheet turned 2.344 degrees"
	)
	var title := pause.get_node("Center/Panel/Content/TitleRow/PausedLabel") as Label
	_check(
		(
			title.text == "Paused"
			and title.get_theme_font_size("font_size") == 43
			and _near(title.get_theme_color("font_color"), Color.html("#784623"))
		),
		"title is Mountains of Christmas 24 -> 43 px #784623"
	)
	var owner_label := pause.get_node("%OwnerLabel") as Label
	var heading := pause.get_node("%RosterHeading") as Label
	_check(
		(
			owner_label.text == "shared pause · any player can take the menu"
			and heading.text == "any one player can resume"
			and heading.visible
			and _near(owner_label.get_theme_color("font_color"), Color.BLACK)
			and owner_label.get_theme_font_size("font_size") == 18
		),
		"shared pause shows the frame's two Mansalva lines in black"
	)
	_check(
		not (pause.get_node("%ReasonRow") as Control).visible, "a plain pause adds no reason line"
	)
	for index in 4:
		var pill := pause.rosters[index]
		var pill_color := (pill.get_theme_stylebox("panel") as StyleBoxFlat).bg_color
		var shape := (
			pill.badge.get_node("ShapeHolder/Shape" + str(seats[index].shape).capitalize())
			as Polygon2D
		)
		_check(
			(
				pill.visible
				and pill_color.is_equal_approx(
					(
						(theme.get_stylebox("panel", "PillSeat%d" % (index + 1)) as StyleBoxFlat)
						. bg_color
					)
				)
				and shape.color.is_equal_approx(pill_color)
				and (shape.get_node("Outline") as Line2D).visible
			),
			(
				"pill %d keeps the game colour; its shape is pill-coloured with a cream outline"
				% (index + 1)
			)
		)
	_check(
		pause.rosters[0].get_node("Glass/GlassPatch") is NinePatchRect,
		"pills carry the Figma glass overlay"
	)
	var texts := []
	for name in ["ResumeButton", "SettingsButton", "LibraryButton", "LeaveButton"]:
		var button := pause.get_node("%" + name) as Button
		texts.append(button.text)
		_check(
			(
				button.get_theme_font_size("font_size") == 14
				and button.get_node_or_null("Icon") is TextureRect
				and (button.get_node("DropShadow") as Control).show_behind_parent
			),
			"%s: 14 px label, Figma icon and group drop shadow" % name
		)
	_check(
		texts == ["Resume", "Settings", "Library", "Leave Match"], "button labels follow the frame"
	)
	# Owner, informative reason and countdown.
	for seat in seats:
		seat.ready = true
	pause.bind_state(UiPauseScreen.reason_text("application focus lost"), 1, 2.2, seats, {})
	await process_frame
	_check(
		owner_label.text == "paused by" and (pause.get_node("%OwnerBadge") as Control).visible,
		"owner pause reads 'paused by' with the owner badge"
	)
	_check(
		(
			(pause.get_node("%ReasonRow") as Control).visible
			and (pause.get_node("%ReasonLabel") as Label).text == "The game window lost focus"
		),
		"an informative reason gets its own line"
	)
	_check(
		(
			(pause.get_node("%CountdownLabel") as Label).visible
			and (pause.get_node("%CountdownLabel") as Label).text == "resuming in 3"
			and not heading.visible
		),
		"the countdown takes the 'everyone must be ready' line"
	)
	# Reclaim: seat 3 lost, then a second missing seat.
	seats[2].connected = false
	pause.bind_state(
		UiPauseScreen.reason_text("assigned device disconnected"),
		-1,
		0.0,
		seats,
		{"reclaim_seat": 2}
	)
	await process_frame
	var reclaim := pause.get_node("%ReclaimPanel") as PanelContainer
	var reclaim_label := pause.get_node("%ReclaimLabel") as Label
	_check(
		(
			reclaim.visible
			and not pause.rosters[2].visible
			and reclaim.get_index() == pause.rosters[2].get_index() - 1
			and reclaim.theme_type_variation == &"PillSeat3"
			and not (pause.get_node("%ReasonRow") as Control).visible
		),
		"the lost seat's pill becomes the tall reclaim pill in its place and colour"
	)
	_check(
		(
			reclaim_label.text.begins_with(
				"Player 3 has lost its controller. Press South on the new"
			)
			and not reclaim_label.text.contains("Left/Right")
		),
		"reclaim pill uses the frame's wording (%s)" % reclaim_label.text
	)
	seats[1].connected = false
	pause.bind_state(
		UiPauseScreen.reason_text("assigned device disconnected"),
		-1,
		0.0,
		seats,
		{"reclaim_seat": 1}
	)
	await process_frame
	_check(
		(
			reclaim_label.text.begins_with("Player 2 has lost")
			and reclaim_label.text.ends_with("Left/Right picks another missing seat.")
			and pause.rosters[2].visible
			and pause.rosters[2].state_text() == "DEVICE LOST"
			and reclaim.theme_type_variation == &"PillSeat2"
		),
		"with two missing seats the pill follows the chosen seat and mentions Left/Right"
	)
	pause.queue_free()
	await process_frame


## Round result details read from Figma frame 36:221 (exact paints and effects).
func _test_round_result_frame() -> void:
	_check(
		(
			_near(theme.get_color("font_outline_color", "ResultTitle"), Color.html("#624a39"))
			and theme.get_constant("outline_size", "ResultTitle") == 6
		),
		"result title has the Figma 1 px #624a39 outline (measured 3.96 vs 3.87 px at 1080p)"
	)
	var board := theme.get_stylebox("panel", "ChalkboardPanel") as StyleBoxFlat
	_check(
		(
			_near(board.bg_color, Color.html("#022c02"))
			and _near(board.border_color, Color.WHITE)
			and board.corner_radius_top_left == 0
		),
		"chalkboard is #022c02 with a square white frame"
	)
	var fill := theme.get_stylebox("fill", "CountdownBar") as StyleBoxTexture
	var fill_image := fill.texture.get_image()
	var w := fill_image.get_width()
	var h := fill_image.get_height()
	_check(
		(
			fill.texture.resource_path.ends_with("ui.round_result.countdown_fill.svg")
			and fill.texture_margin_right == 33.0
			and fill_image.get_pixel(w - 4, 0).a > 0.9
			and fill_image.get_pixel(w - 4, h - 1).a < 0.05
		),
		"countdown fill is the Figma trapezoid (slanted right end kept by a 33 px margin)"
	)
	var screen := (
		(load("res://scenes/ui/screens/round_result_screen.tscn") as PackedScene).instantiate()
		as UiScreen
	)
	root.add_child(screen)
	screen.show_state(0, UiContext.make(4, "k1"))
	await process_frame
	await process_frame
	var chalk := screen.get_node("Safe/Content/Columns/Chalkboard") as Control
	var grain := screen.get_node("Safe/Content/Columns/Chalkboard/Grain/GrainPatch") as Control
	var grain_rect := Rect2(grain.global_position, grain.size * grain.scale)
	_check(
		(
			grain.theme_type_variation == &"ChalkGrain"
			and grain_rect.position.distance_to(chalk.global_position) < 0.5
			and grain_rect.size.distance_to(chalk.size) < 0.5
		),
		"the Figma grain covers the whole chalkboard, frame included"
	)
	_check(screen.get_node_or_null("Safe/Content/Tag") == null, "no PLACEHOLDER tag on the result")
	var column := screen.find_child("Column1", true, false)
	if column == null:
		for node in screen.find_children("*", "UiPlayerBadge", true, false):
			if node.get_parent() is Control and node.name == "IdentityBadge":
				column = node.get_parent()
				break
	var outlined := false
	if column != null:
		var badge := column.get_node("IdentityBadge") as UiPlayerBadge
		for shape in ["ShapeCircle", "ShapeTriangle", "ShapeSquare", "ShapeDiamond"]:
			var polygon := badge.get_node("ShapeHolder/" + shape) as Polygon2D
			if polygon.visible:
				outlined = (polygon.get_node("Outline") as Line2D).visible
	_check(outlined, "chart player symbols carry the Figma cream outline")
	screen.queue_free()
	await process_frame


## Place details read from Figma frame 18:8 (HUD rail, chips, Guide card, status tabs, timer).
func _test_place_frame() -> void:
	var hud_box := theme.get_stylebox("panel", "HudBar") as StyleBoxFlat
	_check(
		(
			_near(hud_box.bg_color, Color.html("#2d2920"))
			and _near(hud_box.border_color, Color.html("#607477"))
			and hud_box.border_width_bottom == 2
		),
		"HUD rail is the Figma #2d2920 with a #607477 bottom line"
	)
	var chip_box := theme.get_stylebox("panel", "ScoreChip") as StyleBoxFlat
	_check(
		(
			_near(chip_box.bg_color, Color.html("#f6e8ce"))
			and _near(chip_box.border_color, Color.html("#9d5c00"))
			and _near(theme.get_color("font_color", "ChipState"), Color.html("#784623"))
			and theme.get_font("font", "ChipState").resource_path.ends_with("Mansalva-Regular.ttf")
			and _near(theme.get_color("font_color", "ChipName"), Color.html("#483934"))
			and theme.get_font_size("font_size", "ChipLabel") == 18
		),
		"score chips use the frame's cream, outline, Mansalva state and Margarine name / score"
	)
	var place := (
		(load("res://scenes/ui/screens/place_overlay.tscn") as PackedScene).instantiate()
		as UiPlaceOverlay
	)
	var hud := (
		(load("res://scenes/ui/screens/play_hud.tscn") as PackedScene).instantiate() as Control
	)
	root.add_child(hud)
	root.add_child(place)
	var ctx := UiContext.make(4, "k1")
	place.show_state(0, ctx)
	await process_frame
	await process_frame
	var guide := place.get_node("%PhaseBanner") as UiPhaseBanner
	_check(
		(
			guide.theme_type_variation == &"GuideCard"
			and guide.title_text() == "Guide"
			and guide.get_node("Rivets").get_child_count() == 4
		),
		"Place guide is the riveted Guide card"
	)
	var tabs := {
		"LegendValid": ["#3f675a", "#7ad18d", "Valid place to place an obstacle"],
		"LegendInvalid": ["#5e0d0e", "#b40a0c", "Blocked: cant place an obstacle"],
		"LegendProtected": ["#8a8c5a", "#d3e018", "Protected zone: no building"],
		"LegendRotationOff": ["#4c5653", "#9db9a3", "Cannot Rotate this way"],
	}
	for tab_name in tabs:
		var tab := place.get_node("%GhostLegend").get_node("%" + tab_name) as PanelContainer
		var spec: Array = tabs[tab_name]
		var strip := tab.get_node("Col/Strip") as Panel
		_check(
			(
				_near(
					(tab.get_theme_stylebox("panel") as StyleBoxFlat).bg_color, Color.html(spec[0])
				)
				and _near(
					(strip.get_theme_stylebox("panel") as StyleBoxFlat).bg_color,
					Color.html(spec[1])
				)
				and (tab.get_node("Col/Text") as Label).text == spec[2]
			),
			"%s tab matches the frame (%s / %s)" % [tab_name, spec[0], spec[1]]
		)
	var timer := place.get_node("%Countdown") as UiCountdownRing
	timer.set_time(8.0, 15.0)
	_check(
		(
			timer.seconds_text() == "8 secs"
			and (timer.get_node("%Bar") as ProgressBar).theme_type_variation == &"PlaceTimerBar"
		),
		"Place timer reads '8 secs' on the slanted blue bar"
	)
	_check(
		(
			place.get_node_or_null("Bottom/Col/Tag") == null
			and not (place.get_node("%GhostStatus") as Control).visible
			and not (place.get_node("Bottom/Col/StatusRow") as Control).visible
		),
		"no placeholder tag; the old locked count and status rows stay hidden"
	)
	_check(
		is_equal_approx((hud.get_node("%HudBar") as Control).size.y, 64.0),
		"HUD rail stays inside the 64 px stage reservation"
	)
	place.queue_free()
	hud.queue_free()
	await process_frame


## Pugad pick screen from Figma frame 2:5 "Obstacle Pick" (owner decisions: no item name or
## description on eggs, per the GDD; players + 2 eggs with two extra card spots).
func _test_pugad_frame() -> void:
	_check(
		(
			_near(theme.get_color("font_color", "PugadTitle"), Color.html("#784623"))
			and theme.get_font_size("font_size", "PugadTitle") == 45
			and _near(
				(theme.get_stylebox("panel", "ScoreChipPaper") as StyleBoxFlat).border_color,
				Color.html("#d6ba87")
			)
		),
		"Pick title is Mountains of Christmas 45 #784623; Pugad chips use the paper outline"
	)
	var pugad := (
		(load("res://scenes/ui/screens/pugad_overlay.tscn") as PackedScene).instantiate()
		as UiPugadOverlay
	)
	root.add_child(pugad)
	var ctx := UiContext.make(2, "k1")
	pugad.show_state(0, ctx)
	await process_frame
	await process_frame
	_check(pugad.visible_egg_count() == 4, "2 players get players + 2 = 4 egg cards")
	var spot := pugad.get_node("%Spots").get_node("Spots4/Spot1") as Control
	var egg1 := pugad.egg_slots[0]
	_check(
		(
			egg1.position.is_equal_approx(Vector2(329.4, 250.4))
			and is_equal_approx(egg1.rotation, spot.rotation)
		),
		"egg 1 sits on the frame's first card spot (329.4, 250.4, -11.84 degrees)"
	)
	var labels := egg1.find_children("*", "Label", true, false)
	var texts := PackedStringArray()
	for label in labels:
		if not (label.get_parent() is HBoxContainer and label.get_parent().name == "Name"):
			texts.append((label as Label).text)
	_check(
		texts == PackedStringArray(["✓ Picked"]),
		"egg cards carry no item name or description, only the pick status (%s)" % texts
	)
	var chooser: Array[Dictionary] = [ctx.seats[1]]
	pugad.egg_slots[1].set_selectors(chooser)
	_check(
		egg1.pill_text() == "✓ Picked" and pugad.egg_slots[1].pill_text() == "Choosing…",
		"the pick pill reads ✓ Picked for the owner and Choosing… for a chooser"
	)
	var many_keys := PackedStringArray()
	for _index in 6:
		many_keys.append(egg1.variant_key)
	var nest_rect := (pugad.get_node("Nest") as Control).get_global_rect()
	for count in [5, 6]:
		var shown_keys := PackedStringArray()
		for index in count:
			shown_keys.append(many_keys[index])
		pugad.bind_eggs(ctx.definitions, shown_keys, ctx.tuning)
		var contained := true
		for index in count:
			if not nest_rect.encloses(pugad.egg_slots[index].get_global_rect()):
				contained = false
		_check(contained, "%d egg cards stay inside the nest artwork" % count)
	var dim := pugad.get_node("Dim") as ColorRect
	_check(
		(
			dim.color.is_equal_approx(Color(0.09804, 0.09412, 0.09412, 0.41))
			and (pugad.get_node("Nest") as TextureRect).texture != null
		),
		"the frame's 41 % #191818 dim and the nest art are in place"
	)
	_check(
		(
			(pugad.get_node("%HudRound") as Label).text == "Round 1"
			and pugad.hud_chips[0].state_text() == "Picked"
			and pugad.count_text() == "2 / 2 picked"
			and (pugad.get_node("%PickHint") as Label).text == "South / Enter  Pick"
		),
		"Pugad HUD, chip state, picked count and hint follow the frame"
	)
	pugad.queue_free()
	await process_frame


## Tutorial coach card from Figma frame 91:2 "Tutorial", shown at 1.125x (owner decision: keep
## the coach box footprint so the body stays 18 px, not the x1.8 of the full-screen frames).
func _test_tutorial_card() -> void:
	var card_box := theme.get_stylebox("panel", "TutorialCard") as StyleBoxFlat
	_check(
		(
			_near(card_box.bg_color, Color.html("#f6e7cd"))
			and _near(card_box.border_color, Color.html("#d6ba87"))
			and card_box.border_width_left == 1
			and card_box.corner_radius_top_left == 3
			and _near(card_box.shadow_color, Color(0, 0, 0, 0.25))
		),
		"Tutorial card is the frame's #f6e7cd paper, 1 px #d6ba87 outline, radius 3, 25 % shadow"
	)
	var text_types := {
		"TutorialCardTitle": ["#784623", 36, "MountainsofChristmas-Bold.ttf"],
		"TutorialCardCaption": ["#94796f", 14, "Margarine-Regular.ttf"],
		"TutorialCardBody": ["#483934", 18, "Margarine-Regular.ttf"],
	}
	for type_name in text_types:
		var spec: Array = text_types[type_name]
		_check(
			(
				_near(theme.get_color("font_color", type_name), Color.html(spec[0]))
				and theme.get_font_size("font_size", type_name) == spec[1]
				and theme.get_font("font", type_name).resource_path.ends_with(spec[2])
			),
			"%s is %s %d px %s" % [type_name, spec[2], spec[1], spec[0]]
		)
	var prompt := (
		(load("res://scenes/ui/screens/tutorial_prompt.tscn") as PackedScene).instantiate()
		as UiTutorialPrompt
	)
	root.add_child(prompt)
	var view := {
		"visible": true,
		"step_id": "results",
		"title": "Step 5 of 5 - Results",
		"body": "Everyone reached the flag.",
		"skip_caption": "Pause > Skip tutorial",
		"tag": "PLACEHOLDER copy",
	}
	prompt.bind_live(view)
	await process_frame
	await process_frame
	var step := prompt.get_node("%StepLabel") as Label
	var skip := prompt.get_node("%SkipText") as Label
	_check(
		(
			step.text == "Step 5 of 5 - Results"
			and step.theme_type_variation == &"TutorialCardCaption"
			and (prompt.get_node("%BodyLabel") as Label).theme_type_variation == &"TutorialCardBody"
			and skip.text == "Pause > Skip tutorial"
			and skip.horizontal_alignment == HORIZONTAL_ALIGNMENT_RIGHT
		),
		"coach card reads the step line, the body and a right-aligned skip caption"
	)
	_check(
		(
			not (prompt.get_node("%PromptGlyph") as Control).visible
			and not (prompt.get_node("%SkipHint") as Control).visible
			and not (prompt.get_node("%Tag") as Control).visible
		),
		"no chip glyphs or placeholder tag on the card, as in the frame"
	)
	var box := (prompt.get_node("Anchor/Box") as Control).get_global_rect()
	_check(
		(
			is_equal_approx(box.position.x, 947.0)
			and box.end.x <= 1210.0 + 0.01
			and is_equal_approx(prompt.results_strip_width, 303.0)
		),
		"Results card sits at x 947 and ends by 1210 inside the reserved strip (%s)" % box
	)
	view.step_id = "pugad"
	prompt.bind_live(view)
	await process_frame
	box = (prompt.get_node("Anchor/Box") as Control).get_global_rect()
	_check(
		box.position.is_equal_approx(Vector2(24.0, 167.0)),
		"match card sits in the left column at (24, 167) (%s)" % box
	)
	# Welcome (Lobby): top-left corner, above the seat slots (y 196) and left of the map arrows
	# (x 452), with the longest four-player text (three keyboards and a gamepad).
	view.step_id = "welcome"
	view.title = "Step 1 of 5 - Welcome"
	view.body = (
		"You are 1 CIRCLE, 2 TRIANGLE, 3 SQUARE, 4 DIAMOND. Look for your number and shape"
		+ " above your chicken. Run: A / D / Left / Right / J / L / D-pad / Left stick."
		+ " Jump: Space / Right Ctrl / I / South."
	)
	prompt.bind_live(view)
	await process_frame
	await process_frame
	box = (prompt.get_node("Anchor/Box") as Control).get_global_rect()
	_check(
		(
			box.position.is_equal_approx(Vector2(24.0, 24.0))
			and is_equal_approx(box.size.x, 400.0)
			and box.end.y < 196.0
			and box.end.x < 452.0
		),
		"Welcome card sits top-left, above the Lobby slots and left of the map arrows (%s)" % box
	)
	prompt.queue_free()
	var hud := (load("res://scenes/match/match_hud.tscn") as PackedScene).instantiate()
	var anchor := hud.get_node("TutorialPrompt/Anchor") as Control
	_check(
		anchor.offset_left == 24.0 and anchor.offset_right <= 287.0,
		"the match HUD's coach box stays in the left column (x 24 to %.0f)" % anchor.offset_right
	)
	hud.free()
	await process_frame


## Final results from Figma frame 100:77 "Winner Results" (711 x 400, built at 1.8x).
func _test_final_result_frame() -> void:
	_check(
		(
			UiMatchResultScreen.winner_text({"identity": 2, "shape": "TRIANGLE"}, 1)
			== "Winner - P2  Triangle"
		),
		"winner line reads like the frame: Winner - P2  Triangle"
	)
	var holder := Control.new()
	holder.size = Vector2(1280, 720)
	root.add_child(holder)
	var screen := (
		(load("res://scenes/ui/screens/match_result_screen.tscn") as PackedScene).instantiate()
		as UiMatchResultScreen
	)
	holder.add_child(screen)
	var ctx := UiContext.make(4, "k1")
	screen.show_state(0, ctx)
	for i in 4:
		await process_frame
	var title := screen.get_node("%TitleLabel") as Label
	_check(
		(
			title.text == "Final Results"
			and title.theme_type_variation == &"ResultTitle"
			and title.get_theme_font_size("font_size") == 115
			and _near(title.get_theme_color("font_outline_color"), Color.html("#624a39"))
		),
		"title is the frame's Final Results, Mountains of Christmas 115 px with the brown outline"
	)
	var vine := screen.get_node("Safe/Content/TitleArea/Art_Vine") as TextureRect
	_check(
		(
			vine.texture != null
			and vine.texture.resource_path.ends_with("ui.match_result.vine.svg")
			and absf(vine.texture.get_width() - 902.5) < 1.0
			and vine.get_global_rect().position.is_equal_approx(Vector2(608.4, 64.8))
		),
		"the frame's vine sits at (608.4, 64.8) at 1.8x"
	)
	var board := screen.get_node("Safe/Content/Columns/Chalkboard") as Control
	var board_rect := board.get_global_rect()
	_check(
		(
			board.theme_type_variation == &"ChalkboardPanel"
			and board_rect.position.is_equal_approx(Vector2(40, 162))
			and absf(board_rect.size.x - 1031.0) < 1.0
			and absf(board_rect.end.y - 648.0) < 1.5
		),
		"chalkboard fills the frame's 40-1071 x 162-648 (%s)" % board_rect
	)
	var winner := screen.get_node("%WinnerLabel") as Label
	_check(
		(
			winner.text.begins_with("Winner - P1  ")
			and winner.theme_type_variation == &"ChalkLabel"
			and not (screen.get_node("%WinnerBadge") as Control).visible
		),
		"winner line is chalk text on the board header (%s)" % winner.text
	)
	var awards := screen.get_node("Safe/Content/Columns/Awards") as Control
	var outcome := screen.get_node("%OutcomeLabel") as Label
	var legend := screen.get_node("%ScoreAwardLegend") as GridContainer
	_check(
		(
			outcome.get_parent() == awards
			and outcome.theme_type_variation == &"ResultText"
			and is_equal_approx(awards.get_global_rect().position.x, 1091.0)
			and legend.columns == 1
		),
		"outcome sits under Awards at x 1091 and the Score Legend is one column"
	)
	var planks := {
		"%ReplayButton": ["Replay", 111.6],
		"%LobbyButton": ["Return to Lobby", 494.5],
		"%QuitButton": ["Quit", 864.0],
	}
	for path in planks:
		var button := screen.get_node(path) as Button
		var spec: Array = planks[path]
		var rect := button.get_global_rect()
		_check(
			(
				button is UiPlankButton
				and button.text == spec[0]
				and rect.size.is_equal_approx(Vector2(333, 31))
				and absf(rect.position.x - float(spec[1])) < 1.0
				and absf(rect.position.y - 664.2) < 1.0
				and button.get_node_or_null("DropShadow") != null
			),
			"%s plank is 333 x 31 at the frame's x %.1f, y 664 (%s)" % [spec[0], spec[1], rect]
		)
	_check(screen.get_node_or_null("Safe/Content/Tag") == null, "no placeholder tag on the screen")
	screen.show_state(1, ctx)
	for i in 3:
		await process_frame
	var cluck := screen.get_node("%LastCluckCallout") as Control
	_check(
		(
			cluck.visible
			and not (cluck.get_node("%PhaseLabel") as Control).visible
			and (cluck.get_node("%DetailLabel") as Label).text.begins_with("Last Cluck!")
			and (
				absf(
					(
						(screen.get_node("%ReplayButton") as Control).get_global_rect().position.y
						- 664.2
					)
				)
				< 1.0
			)
		),
		"Last Cluck line shows under the winner without moving the plank row"
	)
	holder.queue_free()
	await process_frame


## Figma "Parchment main menu" (103:553), from its design context and the team's 2x PNG export
## (2026-10-20) at 1 Figma px = 1 canvas px. The frame's title has two 92 px lines; "Tilaok!" is one,
## so the card is 652 px tall (744 in the frame) and everything under the title sits 92 px higher.
func _test_title_card() -> void:
	var holder := Control.new()
	holder.size = Vector2(1280, 720)
	root.add_child(holder)
	var title := (
		(load("res://scenes/ui/screens/title_screen.tscn") as PackedScene).instantiate()
		as UiTitleScreen
	)
	holder.add_child(title)
	title.show_state(0, UiContext.make(2, "k1"))
	for i in 3:
		await process_frame
	var card := title.get_node("Card") as Control
	var card_rect := card.get_global_rect()
	_check(
		card_rect.is_equal_approx(Rect2(368, 34, 544, 652)),
		"title card is 544 x 652, centred on the canvas (%s)" % card_rect
	)
	var paper := card.get_node("Paper") as Control
	var paper_box := paper.get_theme_stylebox("panel") as StyleBoxFlat
	_check(
		(
			paper.theme_type_variation == &"TitleCardPaper"
			and paper_box != null
			and _near(paper_box.bg_color, Color.html("#f6e7cd"))
			and _near(paper_box.border_color, Color.html("#d6ba87"))
			and paper_box.border_width_top == 1
			and paper_box.border_width_left == 1
		),
		"paper is #f6e7cd with the frame's 1 px #d6ba87 outline"
	)
	var backing := card.get_node("Backing") as Control
	var backing_box := backing.get_theme_stylebox("panel") as StyleBoxFlat
	var backing_xf := backing.get_global_transform()
	var backing_tl := backing_xf * Vector2.ZERO
	var backing_br := backing_xf * backing.size
	_check(
		(
			backing_box != null
			and _near(backing_box.bg_color, Color.html("#b77748"))
			and is_equal_approx(backing.rotation_degrees, -1.5)
			and backing.size.is_equal_approx(Vector2(544, 636))
		),
		"backing page is #b77748, the card's width, 16 px shorter and turned 1.5 degrees"
	)
	_check(
		(
			backing_tl.x < card_rect.position.x - 6.0
			and backing_tl.y > card_rect.position.y
			and backing_br.x > card_rect.end.x + 6.0
			and backing_br.y < card_rect.end.y
		),
		(
			"backing peeks out top-left and bottom-right like the frame (%s, %s)"
			% [backing_tl, backing_br]
		)
	)
	var backing_centre := backing_xf * (backing.size / 2.0)
	_check(
		backing_centre.is_equal_approx(card_rect.get_center() + Vector2(0.435, -5.245)),
		"backing centre sits 0.435 px right of and 5.245 px above the card's (%s)" % backing_centre
	)
	# Drop shadows: [node, theme type, alpha, fade px, inset px, screen offset].
	var shadow_specs := [
		[backing.get_node("Shadow"), &"TitleCardBackingShadow", 0.19, 34, 17.0, Vector2(3, 10)],
		[paper.get_node("Shadow"), &"TitleCardPaperShadow", 0.17, 28, 14.0, Vector2(0, 10)],
	]
	for spec in shadow_specs:
		var shadow := spec[0] as Control
		var owner_box := shadow.get_parent() as Control
		var box := shadow.get_theme_stylebox("panel") as StyleBoxFlat
		var xf := shadow.get_global_transform()
		var shift: Vector2 = (
			xf * (shadow.size / 2.0) - owner_box.get_global_transform() * (owner_box.size / 2.0)
		)
		var inset: float = spec[4]
		_check(
			(
				shadow.theme_type_variation == spec[1]
				and shadow.show_behind_parent
				and box != null
				and not box.draw_center
				and _near(Color(box.shadow_color, 1.0), Color.html("#59391f"))
				and is_equal_approx(box.shadow_color.a, spec[2])
				and box.shadow_size == spec[3]
				and shadow.size.is_equal_approx(owner_box.size - Vector2(inset, inset) * 2.0)
				and shift.distance_to(spec[5]) < 0.01
			),
			(
				"%s shadow: #59391f at %.2f, %d px fade centred on the edge, shifted %s (%s)"
				% [owner_box.name, spec[2], spec[3], spec[5], shift]
			)
		)
	_check(
		(
			(paper.get_theme_stylebox("panel") as StyleBoxFlat).shadow_size == 0
			and backing_box.shadow_size == 0
		),
		"paper and backing draw no shadow of their own (the Shadow children do)"
	)
	var patch := card.get_node("Grain/GrainPatch") as Control
	_check(
		(
			patch.theme_type_variation == &"TitleCardGrain"
			and patch.get_global_rect().is_equal_approx(card_rect)
			and (card.get_node("Grain") as Control).clip_contents
		),
		"paper grain covers exactly the card at 1.5x density"
	)
	var dash_box := theme.get_stylebox("panel", "TitleCardDashH") as StyleBoxTexture
	var dash_tex := dash_box.texture as GradientTexture2D if dash_box != null else null
	var dash_grad := dash_tex.gradient if dash_tex != null else null
	_check(
		(
			dash_grad != null
			and dash_tex.width == 8
			and dash_tex.height == 1
			and dash_grad.interpolation_mode == Gradient.GRADIENT_INTERPOLATE_CONSTANT
			and is_equal_approx(dash_grad.get_offset(1), 0.375)
			and _near(dash_grad.get_color(0), Color.html("#d0b38d"))
			and dash_grad.get_color(1).a == 0.0
			and dash_box.axis_stretch_horizontal == StyleBoxTexture.AXIS_STRETCH_MODE_TILE
		),
		"dashes are #d0b38d, 3 px on and 5 px off, tiled"
	)
	var dashes := {
		"DashTop": Rect2(14.5, 13, 514, 1),
		"DashBottom": Rect2(14.5, 638, 514, 1),
		"DashLeft": Rect2(13, 14, 1, 623),
		"DashRight": Rect2(530, 14, 1, 623),
		"DotLeft": Rect2(24, 25, 5, 5),
		"DotRight": Rect2(515, 25, 5, 5),
	}
	for node_name in dashes:
		var rect := (card.get_node(node_name) as Control).get_rect()
		_check(
			rect.is_equal_approx(dashes[node_name]),
			"%s sits 13 px inside the card edge as in the frame (%s)" % [node_name, rect]
		)
	var dot_box := theme.get_stylebox("panel", "TitleCardDot") as StyleBoxFlat
	_check(
		dot_box != null and _near(dot_box.bg_color, Color.html("#d6ba87")),
		"corner dots are the outline colour #d6ba87"
	)
	var label_specs := {
		"%TitleLabel": ["TitleCardTitle", "MountainsofChristmas", 100, "#684127", 56.0],
		"Card/Subtitle": ["TitleCardSubtitle", "Margarine", 17, "#94734f", 188.85],
		"%BuildLabel": ["TitleCardFooter", "Margarine", 14, "#94734f", 592.1],
	}
	for path in label_specs:
		var label := title.get_node(path) as Label
		var spec: Array = label_specs[path]
		var font := label.get_theme_font("font")
		_check(
			(
				label.theme_type_variation == StringName(spec[0])
				and font != null
				and font.resource_path.contains(str(spec[1]))
				and label.get_theme_font_size("font_size") == int(spec[2])
				and _near(label.get_theme_color("font_color"), Color.html(str(spec[3])))
				and label.get_theme_color("font_shadow_color").a == 0.0
				and is_equal_approx(label.get_rect().position.y, float(spec[4]))
				and label.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER
			),
			(
				"%s is %s %d %s, %.1f px below the card top"
				% [path, spec[1], spec[2], spec[3], spec[4]]
			)
		)
	_check(
		(title.get_node("%TitleLabel") as Label).text == "Tilaok!",
		"the card keeps the game title (the frame's 'Bramble & Post' is sample text)"
	)
	var build_rect := (title.get_node("%BuildLabel") as Control).get_rect()
	_check(
		build_rect.position.x >= 14.0 and build_rect.end.x <= 530.0,
		"the build label stays inside the dashed frame (%s)" % build_rect
	)
	var menu := title.get_node("%MenuList") as Control
	_check(
		menu.get_global_rect().position.is_equal_approx(Vector2(446, 316)),
		"menu starts 282 px below the card top, centred (%s)" % menu.get_global_rect()
	)
	# Figma vectors at the frame's boxes: the emblem's 52 x 35 box at (246, 30) draws its SVG
	# inset to (257, 31.73) 29 x 33.27; the ornament is 332 x 27 at (106, 320), 228 here.
	var slots := {
		"Card/Art_Emblem": ["ui.title.emblem", Rect2(257, 31.73, 29, 33.27)],
		"Card/Art_Ornament": ["ui.title.ornament", Rect2(106, 228, 332, 27)],
	}
	for path in slots:
		var slot := title.get_node(path) as TextureRect
		var spec: Array = slots[path]
		var tex := slot.texture
		var box_rect: Rect2 = spec[1]
		_check(
			(
				str(slot.get_meta("asset_id", "")) == spec[0]
				and tex != null
				and tex.resource_path == "res://assets/ui/title/%s.svg" % spec[0]
				and slot.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				and slot.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
				and slot.get_rect().is_equal_approx(box_rect)
				and absf(float(tex.get_width()) / tex.get_height() - box_rect.size.aspect()) < 0.01
			),
			(
				"%s shows %s.svg undistorted at the frame's box %s"
				% [path.get_file(), spec[0], box_rect]
			)
		)
	_check(
		card.find_child("Ornaments", false, false) == null,
		"the three empty ornament placeholders are gone"
	)
	var start := title.get_node("%StartButton") as UiMenuActionButton
	var pointer := start.get_node("Pointer") as TextureRect
	var pointer_shadow := pointer.get_node("Shadow") as TextureRect
	_check(
		(
			pointer.is_visible_in_tree()
			and pointer_shadow.show_behind_parent
			and pointer_shadow.texture == pointer.texture
			and pointer_shadow.get_rect().is_equal_approx(Rect2(0, 4, 15, 22))
			and _near(Color.html("#86502f") * pointer_shadow.self_modulate, Color.html("#754526"))
		),
		"the selected button's 0 4 0 #754526 shadow falls on its pointer too, as in the frame"
	)
	_check(
		title.find_child("LanLobbyButton", true, false) == null,
		"retired LAN lobby action is absent from the Title"
	)
	_check(title.find_child("Tag", true, false) == null, "no PLACEHOLDER tag on the title")
	title.show_state(1, UiContext.make(2, "k1"))
	for i in 2:
		await process_frame
	var join := title.get_node("%PressToJoinPrompt") as Control
	var join_label := join.get_node("%ActionLabel") as Label
	_check(
		(
			not join.visible
			and menu.visible
			and join_label.theme_type_variation == &"TitleCardPromptAction"
		),
		"nobody joined: the menu shows and the join prompt stays hidden"
	)
	holder.queue_free()
	await process_frame


## Library built from Figma frame 133:1205 (1600 x 900; 1 Figma px = 0.8 canvas px): the frame's
## layout, colours, plank looks and step cards, bound to live pages and K2 prompts.
func _test_library_frame() -> void:
	var holder := Control.new()
	holder.size = Vector2(1280, 720)
	root.add_child(holder)
	var library := (
		(load("res://scenes/ui/screens/library_screen.tscn") as PackedScene).instantiate()
		as UiLibraryScreen
	)
	holder.add_child(library)
	library.replay_tutorial_enabled = true
	library.show_state(0, UiContext.make(2, "k2"))
	library._set_zone(UiLibraryScreen.ZONE_ENTRIES)
	for i in 3:
		await process_frame
	# Node, Figma rect. Whole-px separations make planks and cards 0.2 px off at most.
	var rects := [
		["%BackButton", Rect2(64, 56, 166, 56)],
		["Frame/Detail", Rect2(648, 178, 888, 620)],
		["Frame/Art_LeafDivider", Rect2(675, 119, 250, 16)],
		["Frame/Navigation/FieldGuide", Rect2(64, 626, 552, 172)],
		["Frame/Footer", Rect2(64, 822, 1472, 38)],
	]
	for spec in rects:
		var node := library.get_node(str(spec[0])) as Control
		var want := _figma_rect(spec[1])
		_check(
			_rect_near(node.get_global_rect(), want, 0.25),
			"library %s sits at the frame's %s (%s)" % [spec[0], want, node.get_global_rect()]
		)
	var categories := library.get_node("%CategoryList") as Control
	var entries := library.get_node("%EntryList") as Control
	for column in [[categories, 64.0], [entries, 350.0]]:
		var list := column[0] as Control
		for index in 6:
			var plank := list.get_child(index) as Control
			var want := _figma_rect(Rect2(column[1], 178.0 + 72.0 * index, 266, 56))
			_check(
				_rect_near(plank.get_global_rect(), want, 0.25),
				"library plank %s %d at %s (%s)" % [list.name, index, want, plank.get_global_rect()]
			)
	var open := categories.get_child(0) as UiLibraryTabButton
	var normal := categories.get_child(1) as UiLibraryTabButton
	var chosen := entries.get_child(0) as UiLibraryTabButton
	_check(
		(
			open.text == "How to play"
			and library.category == "How to Play"
			and chosen.text == "The round loop"
			and chosen.selected
			and not open.selected
			and open.current
		),
		"library opens on How to play (shaded) / The round loop (highlighted)"
	)
	var plank_specs := [
		[normal, "#b77748", "#784623", "#563b2b"],
		[open, "#885a39", "#784623", "#563b2b"],
		[chosen, "#253c3d", "#3c5654", "#ebd6af"],
	]
	for spec in plank_specs:
		var plank := spec[0] as UiLibraryTabButton
		var face := (plank.get_node("Face") as Control).get_theme_stylebox("panel") as StyleBoxFlat
		var edge := plank.get_theme_stylebox("normal") as StyleBoxFlat
		var rivet := (
			(plank.get_node("RivetLeft") as Control).get_theme_stylebox("panel") as StyleBoxFlat
		)
		var shadow := (
			(plank.get_node("Shadow") as Control).get_theme_stylebox("panel") as StyleBoxFlat
		)
		var text := plank.get_node("Content/Label") as Label
		_check(
			(
				_near(face.bg_color, Color.html(spec[1]))
				and _near(edge.bg_color, Color.html(spec[2]))
				and _near(rivet.bg_color, Color.html(spec[3]))
				and _near(shadow.bg_color, Color.html("#784623"))
				and is_equal_approx(shadow.expand_margin_bottom, 4.0)
				and _near(text.get_theme_color("font_color"), Color.html("#fff5df"))
				and text.get_theme_font_size("font_size") == 21
				and text.text == plank.text
			),
			"library plank %s: %s face, %s edge, %s rivets, solid 4 px shadow" % spec.slice(0)
		)
	var back := library.get_node("%BackButton") as UiLibraryTabButton
	_check(
		(
			(back.get_node("Content/Icon") as TextureRect).visible
			and (back.get_node("Content/Label") as Label).text == "Back"
		),
		"library Back plank shows the chevron and its label"
	)
	var detail := library.get_node("Frame/Detail") as Control
	var face_box := (detail.get_node("Face") as Control).get_theme_stylebox("panel") as StyleBoxFlat
	var edge_box := detail.get_theme_stylebox("panel") as StyleBoxFlat
	var binding := (
		(detail.get_node("Binding") as Control).get_theme_stylebox("panel") as StyleBoxFlat
	)
	var shadow_node := detail.get_node("Shadow") as Control
	var shadow_box := shadow_node.get_theme_stylebox("panel") as StyleBoxFlat
	var shadow_shift := (
		shadow_node.get_global_rect().get_center() - detail.get_global_rect().get_center()
	)
	_check(
		(
			_near(face_box.bg_color, Color.html("#f6e7cd"))
			and _near(edge_box.bg_color, Color.html("#c4a074"))
			and _near(binding.bg_color, Color.html("#b77748"))
			and is_equal_approx(binding.bg_color.a, 0.7)
			and _near(Color(shadow_box.shadow_color, 1.0), Color.html("#50371f"))
			and is_equal_approx(shadow_box.shadow_color.a, 0.161)
			and shadow_box.shadow_size == 25
			and shadow_node.show_behind_parent
			and shadow_shift.distance_to(Vector2(0, 6.4)) < 0.01
		),
		"library page: #f6e7cd, #c4a074 edge, 70 % binding, 0 8 16 shadow (%s)" % shadow_shift
	)
	var grain := detail.get_node("Grain") as Control
	_check(
		grain.get_index() > detail.get_node("Content").get_index(),
		"library page grain covers the page content, like Figma's frame noise"
	)
	var gradient := (
		(library.get_node("Frame/Parchment/Gradient") as Control).get_theme_stylebox("panel")
		as StyleBoxTexture
	)
	var gradient_tex := gradient.texture as GradientTexture2D
	_check(
		(
			gradient_tex.fill == GradientTexture2D.FILL_RADIAL
			and _near(gradient_tex.gradient.get_color(0), Color.html("#edd3a7"))
			and _near(gradient_tex.gradient.get_color(1), Color.html("#ddbb88"))
			and _near(
				(library.get_node("Frame") as Control).get_theme_stylebox("panel").bg_color,
				Color.html("#253c3d")
			)
		),
		"library parchment: radial #edd3a7 -> #ddbb88 on the #253c3d frame"
	)
	var label_specs := [
		["Frame/TitleLabel", &"LibraryTitle", "Library", "#784623", 66],
		["%EntryTitle", &"LibraryChapterTitle", "The round loop", "#784623", 42],
		["%EntrySummary", &"LibraryChapterSummary", "Every round has three steps.", "#563b2b", 21],
	]
	for spec in label_specs:
		var label := library.get_node(str(spec[0])) as Label
		_check(
			(
				label.theme_type_variation == spec[1]
				and label.text == spec[2]
				and _near(label.get_theme_color("font_color"), Color.html(spec[3]))
				and label.get_theme_font_size("font_size") == spec[4]
			),
			"library %s reads '%s' in %s at %d px" % [spec[0], spec[2], spec[3], spec[4]]
		)
	var steps := library.get_node("%Steps") as Control
	var arts := PackedStringArray()
	for index in steps.get_child_count():
		var card := steps.get_child(index) as UiLibraryStepCard
		arts.append(card.art)
		var want := _figma_rect(Rect2(678, 312 + 138 * index, 828, 124))
		var card_face := (
			(card.get_node("Face") as Control).get_theme_stylebox("panel") as StyleBoxFlat
		)
		_check(
			(
				card.visible
				and _rect_near(card.get_global_rect(), want, 0.5)
				and _near(card_face.bg_color, Color.html("#fff3da"))
				and _near(card.get_theme_stylebox("panel").bg_color, Color.html("#c4a074"))
			),
			"library step card %d at %s, #fff3da with a #c4a074 edge" % [index + 1, want]
		)
	_check(arts == PackedStringArray(["pugad", "place", "play"]), "step art %s" % [arts])
	var keys := PackedStringArray()
	for key in ["%ChooseKey", "%ReadKey", "%BackKey"]:
		keys.append((library.get_node(key) as Label).text)
	_check(
		keys == PackedStringArray(["Arrow keys", "Enter", "Backspace"]),
		"library footer keys come from the prompt map for K2 %s" % [keys]
	)
	holder.queue_free()
	await process_frame


## Settings built from Figma frame 133:1336 (1600 x 900, measured from the team's 2x PNG export):
## the frame's layout and colours, choice and slider rows, and the selected row's look.
func _test_settings_frame() -> void:
	var holder := Control.new()
	holder.size = Vector2(1280, 720)
	root.add_child(holder)
	var settings := (
		(load("res://scenes/ui/screens/settings_screen.tscn") as PackedScene).instantiate()
		as UiSettingsScreen
	)
	holder.add_child(settings)
	settings.show_state(1, UiContext.make(2, "k1"))
	for i in 3:
		await process_frame
	var row_names := [
		"ShakeRow", "ResultRevealRow", "MuteRow", "MasterRow", "MusicRow", "EffectsRow", "CrowdRow"
	]
	for index in row_names.size():
		var row := settings.get_node("%" + str(row_names[index])) as UiOptionRow
		var want := _figma_rect(Rect2(354, 192 + 64 * index, 892, 54))
		_check(
			_rect_near(row.get_global_rect(), want, 0.01),
			"settings %s at %s (%s)" % [row_names[index], want, row.get_global_rect()]
		)
	var back := settings.get_node("%BackButton") as UiLibraryTabButton
	var panel := settings.get_node("Frame/Panel") as Control
	_check(
		(
			_rect_near(back.get_global_rect(), _figma_rect(Rect2(354, 648, 892, 48)), 0.01)
			and _rect_near(panel.get_global_rect(), _figma_rect(Rect2(330, 168, 940, 552)), 0.01)
			and back.text == "Back"
			and back.action_icon != null
		),
		"settings page 940 x 552 at (330, 168), Back plank 892 x 48 at (354, 648)"
	)
	var shake := settings.get_node("%ShakeRow") as UiOptionRow
	var reveal := settings.get_node("%ResultRevealRow") as UiOptionRow
	var shake_face := (shake.get_node("FaceSelected") as Control)
	var reveal_face := (reveal.get_node("Face") as Control)
	_check(
		(
			shake.selected
			and shake.theme_type_variation == &"SettingsRowEdgeSelected"
			and _near(shake.get_theme_stylebox("panel").bg_color, Color.html("#b77748"))
			and shake_face.visible
			and _near(shake_face.get_theme_stylebox("panel").bg_color, Color.html("#ebd6af"))
			and is_equal_approx(shake_face.offset_left, 2.5)
			and (shake.get_node("%PointerBox") as Control).visible
			and not reveal.selected
			and _near(reveal.get_theme_stylebox("panel").bg_color, Color.html("#c4a074"))
			and _near(reveal_face.get_theme_stylebox("panel").bg_color, Color.html("#fff3da"))
			and is_equal_approx(reveal_face.offset_left, 1.0)
			and not (reveal.get_node("%PointerBox") as Control).visible
		),
		"settings selected row: 2.5 px #b77748 edge on #ebd6af, pointer; others 1 px #c4a074"
	)
	var name_label := shake.get_node("%NameLabel") as Label
	var value_label := shake.get_node("%ValueLabel") as Label
	_check(
		(
			name_label.text == "Screen shake"
			and _near(name_label.get_theme_color("font_color"), Color.html("#563b2b"))
			and name_label.get_theme_font_size("font_size") == 21
			and shake.value_text() == "Off"
			and _near(value_label.get_theme_color("font_color"), Color.html("#253c3d"))
			and value_label.get_theme_font_size("font_size") == 20
			and (shake.get_node("%Choice") as Control).visible
			and not (shake.get_node("%Slider") as Control).visible
		),
		"settings choice row: Margarine 21 #563b2b name, Margarine 20 #253c3d value"
	)
	var music := settings.get_node("%MusicRow") as UiOptionRow
	var knob := music.get_node("%Knob") as Control
	var track := music.get_node("%Slider") as Control
	var knob_x := knob.get_global_rect().get_center().x
	var expected_x := (868.0 + 257.0 * 0.4) * 0.8
	_check(
		(
			music.value_text() == "40%"
			and track.visible
			and _rect_near(track.get_global_rect(), _figma_rect(Rect2(868, 470, 257, 10)), 0.01)
			and absf(knob_x - expected_x) < 0.01
			and is_equal_approx((music.get_node("%Fill") as Control).anchor_right, 0.4)
		),
		"settings slider: 257 x 10 track at x 868, knob and fill at 40 %% (knob x %.2f)" % knob_x
	)
	var footer := [
		["%ControlsHelp", "#563b2b"],
		["Frame/AccessibilityNote", "#253c3d"],
		["Frame/Tag", "#91662f"],
		["%BuildAboutLabel", "#8a6a4d"],
	]
	for spec in footer:
		var label := settings.get_node(str(spec[0])) as Label
		_check(
			(
				_near(label.get_theme_color("font_color"), Color.html(spec[1]))
				and not label.text.is_empty()
			),
			"settings footer %s in %s" % [spec[0], spec[1]]
		)
	holder.queue_free()
	await process_frame


func _figma_rect(rect: Rect2) -> Rect2:
	return Rect2(rect.position * 0.8, rect.size * 0.8)


func _rect_near(a: Rect2, b: Rect2, tolerance: float) -> bool:
	return (
		a.position.distance_to(b.position) <= tolerance and a.end.distance_to(b.end) <= tolerance
	)


func _check(condition: bool, label: String) -> void:
	checks += 1
	if condition:
		print("PASS ", label)
	else:
		failures += 1
		push_error("FAIL " + label)

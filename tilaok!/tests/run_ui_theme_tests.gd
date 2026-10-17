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
const PLANK_FIGMA := {
	"normal": ["#b77748", "PlankStroke", ["#000000", "#665b44", "#d8c190"]],
	"hover": ["#eb9c62", "PlankStroke", ["#000000", "#665b44", "#d8c190"]],
	"pressed": ["#885a39", "PlankStrokePressed", ["#000000", "#665b44", "#e5cd98"]],
	"disabled": ["#bc9d86", "PlankStrokeDisabled", ["#484848", "#918b80", "#d4c39e"]],
}
const PLANK_STOP_OFFSETS := [0.0, 0.639, 0.884]
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
	await _test_badge_variants()
	await _test_confirm_dialogs()
	await _test_lobby_open_slot()
	await _test_component_sheet()
	await _test_pause_frame()
	await _test_round_result_frame()
	await _test_place_frame()
	await _test_pugad_frame()
	await _test_tutorial_card()
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
	for state in PLANK_FIGMA:
		var spec: Array = PLANK_FIGMA[state]
		var box := theme.get_stylebox(state, "TilaokMenuButton") as StyleBoxFlat
		var fill := Color.html(str(spec[0]))
		_check(
			box != null
			and _near(box.bg_color, fill)
			and box.shadow_size == 0
			and box.shadow_offset == Vector2.ZERO,
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
		stroke.clip_children == CanvasItem.CLIP_CHILDREN_ONLY
		and pressed_look.clip_children == CanvasItem.CLIP_CHILDREN_ONLY,
		"outline gradient and pressed shadow are clipped to the rounded plank shape"
	)
	var rivet := plank.get_node("RivetLeft") as Control
	_check(
		not pressed_look.visible
		and rivet.theme_type_variation == &"Rivet"
		and stroke_gradient.theme_type_variation == &"PlankStroke",
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
		not pressed_look.visible
		and stroke_gradient.theme_type_variation == &"PlankStrokeDisabled"
		and rivet.theme_type_variation == &"RivetDisabled"
		and (plank.get_node("RivetRight") as Control).theme_type_variation == &"RivetDisabled",
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


## Pause screen built from Figma frames 5:44 / 5:81: exact frame values, game seat colours, and
## the live states (shared / owner, quiet reason, countdown, reclaim pill) still working.
func _test_pause_frame() -> void:
	var pause := (
		(load("res://scenes/ui/screens/pause_screen.tscn") as PackedScene).instantiate() as UiPauseScreen
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
		absf(rad_to_deg(backing.rotation) + 2.344) < 0.01
		and _near(theme.get_stylebox("panel", "PauseBacking").bg_color, Color.html("#9e6941")),
		"backing is the Figma #9e6941 sheet turned 2.344 degrees"
	)
	var title := pause.get_node("Center/Panel/Content/TitleRow/PausedLabel") as Label
	_check(
		title.text == "Paused"
		and title.get_theme_font_size("font_size") == 43
		and _near(title.get_theme_color("font_color"), Color.html("#784623")),
		"title is Mountains of Christmas 24 -> 43 px #784623"
	)
	var owner_label := pause.get_node("%OwnerLabel") as Label
	var heading := pause.get_node("%RosterHeading") as Label
	_check(
		owner_label.text == "shared pause · any player can take the menu"
		and heading.text == "everyone must be ready to resume"
		and heading.visible
		and _near(owner_label.get_theme_color("font_color"), Color.BLACK)
		and owner_label.get_theme_font_size("font_size") == 18,
		"shared pause shows the frame's two Mansalva lines in black"
	)
	_check(not (pause.get_node("%ReasonRow") as Control).visible, "a plain pause adds no reason line")
	for index in 4:
		var pill := pause.rosters[index]
		var pill_color := (pill.get_theme_stylebox("panel") as StyleBoxFlat).bg_color
		var shape := pill.badge.get_node("ShapeHolder/Shape" + str(seats[index].shape).capitalize()) as Polygon2D
		_check(
			pill.visible
			and pill_color.is_equal_approx(
				(theme.get_stylebox("panel", "PillSeat%d" % (index + 1)) as StyleBoxFlat).bg_color
			)
			and shape.color.is_equal_approx(pill_color)
			and (shape.get_node("Outline") as Line2D).visible,
			"pill %d keeps the game colour; its shape is pill-coloured with a cream outline" % (index + 1)
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
			button.get_theme_font_size("font_size") == 14
			and button.get_node_or_null("Icon") is TextureRect
			and (button.get_node("DropShadow") as Control).show_behind_parent,
			"%s: 14 px label, Figma icon and group drop shadow" % name
		)
	_check(texts == ["Resume", "Settings", "Library", "Leave Match"], "button labels follow the frame")
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
		(pause.get_node("%ReasonRow") as Control).visible
		and (pause.get_node("%ReasonLabel") as Label).text == "The game window lost focus",
		"an informative reason gets its own line"
	)
	_check(
		(pause.get_node("%CountdownLabel") as Label).visible
		and (pause.get_node("%CountdownLabel") as Label).text == "resuming in 3"
		and not heading.visible,
		"the countdown takes the 'everyone must be ready' line"
	)
	# Reclaim: seat 3 lost, then a second missing seat.
	seats[2].connected = false
	pause.bind_state(
		UiPauseScreen.reason_text("assigned device disconnected"), -1, 0.0, seats, {"reclaim_seat": 2}
	)
	await process_frame
	var reclaim := pause.get_node("%ReclaimPanel") as PanelContainer
	var reclaim_label := pause.get_node("%ReclaimLabel") as Label
	_check(
		reclaim.visible
		and not pause.rosters[2].visible
		and reclaim.get_index() == pause.rosters[2].get_index() - 1
		and reclaim.theme_type_variation == &"PillSeat3"
		and not (pause.get_node("%ReasonRow") as Control).visible,
		"the lost seat's pill becomes the tall reclaim pill in its place and colour"
	)
	_check(
		reclaim_label.text.begins_with("Player 3 has lost its controller. Press South on the new")
		and not reclaim_label.text.contains("Left/Right"),
		"reclaim pill uses the frame's wording (%s)" % reclaim_label.text
	)
	seats[1].connected = false
	pause.bind_state(
		UiPauseScreen.reason_text("assigned device disconnected"), -1, 0.0, seats, {"reclaim_seat": 1}
	)
	await process_frame
	_check(
		reclaim_label.text.begins_with("Player 2 has lost")
		and reclaim_label.text.ends_with("Left/Right picks another missing seat.")
		and pause.rosters[2].visible
		and pause.rosters[2].state_text() == "DEVICE LOST"
		and reclaim.theme_type_variation == &"PillSeat2",
		"with two missing seats the pill follows the chosen seat and mentions Left/Right"
	)
	pause.queue_free()
	await process_frame


## Round result details read from Figma frame 36:221 (exact paints and effects).
func _test_round_result_frame() -> void:
	_check(
		_near(theme.get_color("font_outline_color", "ResultTitle"), Color.html("#624a39"))
		and theme.get_constant("outline_size", "ResultTitle") == 6,
		"result title has the Figma 1 px #624a39 outline (measured 3.96 vs 3.87 px at 1080p)"
	)
	var board := theme.get_stylebox("panel", "ChalkboardPanel") as StyleBoxFlat
	_check(
		_near(board.bg_color, Color.html("#022c02"))
		and _near(board.border_color, Color.WHITE)
		and board.corner_radius_top_left == 0,
		"chalkboard is #022c02 with a square white frame"
	)
	var fill := theme.get_stylebox("fill", "CountdownBar") as StyleBoxTexture
	var fill_image := fill.texture.get_image()
	var w := fill_image.get_width()
	var h := fill_image.get_height()
	_check(
		fill.texture.resource_path.ends_with("ui.round_result.countdown_fill.svg")
		and fill.texture_margin_right == 33.0
		and fill_image.get_pixel(w - 4, 0).a > 0.9
		and fill_image.get_pixel(w - 4, h - 1).a < 0.05,
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
		grain.theme_type_variation == &"ChalkGrain"
		and grain_rect.position.distance_to(chalk.global_position) < 0.5
		and grain_rect.size.distance_to(chalk.size) < 0.5,
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
		_near(hud_box.bg_color, Color.html("#2d2920"))
		and _near(hud_box.border_color, Color.html("#607477"))
		and hud_box.border_width_bottom == 2,
		"HUD rail is the Figma #2d2920 with a #607477 bottom line"
	)
	var chip_box := theme.get_stylebox("panel", "ScoreChip") as StyleBoxFlat
	_check(
		_near(chip_box.bg_color, Color.html("#f6e8ce"))
		and _near(chip_box.border_color, Color.html("#9d5c00"))
		and _near(theme.get_color("font_color", "ChipState"), Color.html("#784623"))
		and theme.get_font("font", "ChipState").resource_path.ends_with("Mansalva-Regular.ttf")
		and _near(theme.get_color("font_color", "ChipName"), Color.html("#483934"))
		and theme.get_font_size("font_size", "ChipLabel") == 18,
		"score chips use the frame's cream, outline, Mansalva state and Margarine name / score"
	)
	var place := (
		(load("res://scenes/ui/screens/place_overlay.tscn") as PackedScene).instantiate()
		as UiPlaceOverlay
	)
	var hud := (load("res://scenes/ui/screens/play_hud.tscn") as PackedScene).instantiate() as Control
	root.add_child(hud)
	root.add_child(place)
	var ctx := UiContext.make(4, "k1")
	place.show_state(0, ctx)
	await process_frame
	await process_frame
	var guide := place.get_node("%PhaseBanner") as UiPhaseBanner
	_check(
		guide.theme_type_variation == &"GuideCard"
		and guide.title_text() == "Guide"
		and guide.get_node("Rivets").get_child_count() == 4,
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
			_near((tab.get_theme_stylebox("panel") as StyleBoxFlat).bg_color, Color.html(spec[0]))
			and _near(
				(strip.get_theme_stylebox("panel") as StyleBoxFlat).bg_color, Color.html(spec[1])
			)
			and (tab.get_node("Col/Text") as Label).text == spec[2],
			"%s tab matches the frame (%s / %s)" % [tab_name, spec[0], spec[1]]
		)
	var timer := place.get_node("%Countdown") as UiCountdownRing
	timer.set_time(8.0, 15.0)
	_check(
		timer.seconds_text() == "8 secs"
		and (timer.get_node("%Bar") as ProgressBar).theme_type_variation == &"PlaceTimerBar",
		"Place timer reads '8 secs' on the slanted blue bar"
	)
	_check(
		place.get_node_or_null("Bottom/Col/Tag") == null
		and not (place.get_node("%GhostStatus") as Control).visible
		and not (place.get_node("Bottom/Col/StatusRow") as Control).visible,
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
		_near(theme.get_color("font_color", "PugadTitle"), Color.html("#784623"))
		and theme.get_font_size("font_size", "PugadTitle") == 45
		and _near(
			(theme.get_stylebox("panel", "ScoreChipPaper") as StyleBoxFlat).border_color,
			Color.html("#d6ba87")
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
		egg1.position.is_equal_approx(Vector2(329.4, 250.4))
		and is_equal_approx(egg1.rotation, spot.rotation),
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
	var dim := pugad.get_node("Dim") as ColorRect
	_check(
		dim.color.is_equal_approx(Color(0.09804, 0.09412, 0.09412, 0.41))
		and (pugad.get_node("Nest") as TextureRect).texture != null,
		"the frame's 41 % #191818 dim and the nest art are in place"
	)
	_check(
		(pugad.get_node("%HudRound") as Label).text == "Round 1"
		and pugad.hud_chips[0].state_text() == "Picked"
		and pugad.count_text() == "2 / 2 picked"
		and (pugad.get_node("%PickHint") as Label).text == "South / Enter  Pick",
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
			(prompt.get_node("Anchor/Box/Content/Header/Title") as Label).text == "Guide:"
			and step.text == "Step 5 of 5 - Results"
			and step.theme_type_variation == &"TutorialCardCaption"
			and (prompt.get_node("%BodyLabel") as Label).theme_type_variation
			== &"TutorialCardBody"
			and skip.text == "Pause > Skip tutorial"
			and skip.horizontal_alignment == HORIZONTAL_ALIGNMENT_RIGHT
		),
		"coach card reads Guide:, the step line, the body and a right-aligned skip caption"
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
			is_equal_approx(box.size.x, 263.0)
			and is_equal_approx(box.position.x, 947.0)
			and box.end.x <= 1210.0 + 0.01
			and is_equal_approx(prompt.results_strip_width, 303.0)
		),
		"Results card is 263 px wide at x 947 and ends at 1210 inside the reserved strip (%s)" % box
	)
	view.step_id = "pugad"
	prompt.bind_live(view)
	await process_frame
	box = (prompt.get_node("Anchor/Box") as Control).get_global_rect()
	_check(
		box.position.is_equal_approx(Vector2(24.0, 167.0)),
		"match card sits in the left column at (24, 167) (%s)" % box
	)
	prompt.queue_free()
	var hud := (load("res://scenes/match/match_hud.tscn") as PackedScene).instantiate()
	var anchor := hud.get_node("TutorialPrompt/Anchor") as Control
	_check(
		is_equal_approx(anchor.offset_right - anchor.offset_left, 263.0),
		"the match HUD's coach box is the card's 263 px width"
	)
	hud.free()
	await process_frame


func _check(condition: bool, label: String) -> void:
	checks += 1
	if condition:
		print("PASS ", label)
	else:
		failures += 1
		push_error("FAIL " + label)

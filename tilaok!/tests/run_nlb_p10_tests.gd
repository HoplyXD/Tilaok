# gdlint: disable=max-line-length,max-file-lines
extends SceneTree

## Focused NLB-P10 checks: the pure phone layout per aspect ratio and dpi (safe area, size floor,
## no overlap), touch-index ownership with synthetic InputEventScreenTouch/Drag (move while aiming,
## rotating and confirming; no double fire; third finger, palm, release outside, disabled button,
## focus loss), the K4 aim detection fix, the gamepad live_cancel, the context action table checked
## against the router, glyph coverage for every action and device (including touch), the phone HUD
## identity rules and the network help cards (steps, skip, replay).
## Synthetic events are never physical or human evidence; the T03 sessions stay open.
## Transport-free. Authored only; nothing here has run.
## Run: Godot --headless --fixed-fps 60 --path tilaok! --script res://tests/run_nlb_p10_tests.gd

const VIEWPORTS := {
	"16:9": Vector2(1280, 720),
	"19.5:9": Vector2(1560, 720),
	"20:9": Vector2(1600, 720),
	"4:3": Vector2(960, 720),
}
const GLYPH_DEVICES := ["k1", "k2", "k3", "k4", "gamepad", "touch"]
const GLYPH_ACTIONS := [
	"ready", "back", "navigate", "run", "jump", "claim", "rotate", "confirm", "results_ready",
	"pause", "cheer", "help", "build_toggle", "aim", "live_rotate", "live_confirm", "live_cancel",
]

var checks := 0
var failures := 0
var _pressed: Array = []
var _released: Array = []
var _moves: Array = []
var _aims: Array = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_layout_per_aspect()
	_test_dp_math()
	_test_touch_ownership()
	_test_touch_edge_cases()
	_test_router_regressions()
	_test_context_table()
	_test_glyph_coverage()
	_test_hud_identity()
	_test_help_cards()
	await _test_presentation_integration()
	_test_source_audit()
	print("NLB_P10_TESTS checks=%d failures=%d" % [checks, failures])
	await process_frame
	quit(1 if failures > 0 else 0)


# --- layout ----------------------------------------------------------------------------------


func _test_layout_per_aspect() -> void:
	for label in VIEWPORTS:
		var viewport: Vector2 = VIEWPORTS[label]
		for live in [false, true]:
			var layout := TouchLayout.compute(viewport, Rect2(), 160.0, viewport, live)
			_check_layout(layout, viewport, "%s live=%s" % [label, live])
		# A notch inset on both short edges keeps controls inside the reported safe rect.
		var safe := Rect2(Vector2(70, 0), Vector2(viewport.x - 140, viewport.y))
		var notched := TouchLayout.compute(viewport, safe, 160.0, viewport, true)
		_check_layout(notched, viewport, "%s notch" % label)
		for rect in (notched.buttons as Dictionary).values():
			_check(safe.encloses(rect), "%s notch: every button stays inside the safe rect" % label)
	# A realistic phone: 2400x1080 at 420 dpi stretched to the 1280x720 viewport.
	var phone := TouchLayout.compute(Vector2(1280, 720), Rect2(), 420.0, Vector2(2400, 1080), true)
	_check_layout(phone, Vector2(1280, 720), "420 dpi phone")
	_check(float(phone.min_target_px) > 44.0, "a dense phone raises the floor above the 44 px minimum")
	# Very low dpi and a tiny viewport still respect the pixel floor.
	var tiny := TouchLayout.compute(Vector2(640, 360), Rect2(), 60.0, Vector2(640, 360), true)
	_check(float(tiny.button_px) >= TouchLayout.MIN_TARGET_PX, "tiny dpi still honours the pixel floor")
	_check(
		TouchLayout.control_ids(true).size() == TouchLayout.BASE_IDS.size() + TouchLayout.LIVE_IDS.size(),
		"live layouts add the four build controls"
	)
	_check((TouchLayout.compute(Vector2(1280, 720), Rect2(), 160.0, Vector2(1280, 720), false).aim_zone as Rect2).size == Vector2.ZERO, "no aim zone outside live build")


func _check_layout(layout: Dictionary, viewport: Vector2, label: String) -> void:
	var inner: Rect2 = layout.inner
	var buttons: Dictionary = layout.buttons
	var rects: Array = buttons.values()
	for control_id in buttons:
		var rect: Rect2 = buttons[control_id]
		_check(inner.grow(0.5).encloses(rect), "%s: %s inside the safe inner rect" % [label, control_id])
		_check(rect.size.x >= float(layout.min_target_px) - 0.01 and rect.size.y >= float(layout.min_target_px) - 0.01, "%s: %s meets the size floor" % [label, control_id])
		_check(rect.position.y >= viewport.y * 0.4, "%s: %s stays in the lower band, clear of the ghost area" % [label, control_id])
	var overlap := false
	for left in rects.size():
		for right in range(left + 1, rects.size()):
			if (rects[left] as Rect2).intersects(rects[right] as Rect2):
				overlap = true
	_check(not overlap, "%s: no two buttons overlap" % label)
	var move_zone: Rect2 = layout.move_zone
	var aim_zone: Rect2 = layout.aim_zone
	_check(inner.grow(0.5).encloses(move_zone), "%s: move zone inside the inner rect" % label)
	_check(move_zone.size.x <= inner.size.x * TouchLayout.MAX_ZONE_WIDTH_FRACTION + 0.01, "%s: move zone capped to 40 percent width" % label)
	var zone_hits := false
	for rect in rects:
		if (rect as Rect2).intersects(move_zone) or (aim_zone.has_area() and (rect as Rect2).intersects(aim_zone)):
			zone_hits = true
	_check(not zone_hits, "%s: buttons never sit inside a drag zone" % label)
	if aim_zone.has_area():
		_check(not move_zone.intersects(aim_zone), "%s: the move and aim zones are independent" % label)


func _test_dp_math() -> void:
	_check(is_equal_approx(TouchLayout.dp_px(160.0, Vector2(1280, 720), Vector2(1280, 720)), 1.0), "160 dpi unstretched is 1 px per dp")
	_check(is_equal_approx(TouchLayout.dp_px(320.0, Vector2(1280, 720), Vector2(2560, 1440)), 1.0), "stretch halves the density")
	_check(TouchLayout.dp_px(0.0, Vector2(1280, 720), Vector2.ZERO) > 0.0, "an unknown dpi and window fall back safely")
	_check(TouchLayout.MIN_TARGET_DP == 44.0, "the dp floor stays the proposed 44")


# --- ownership -------------------------------------------------------------------------------


func _make_layer() -> NetworkTouchLayer:
	var layer := NetworkTouchLayer.new()
	layer.live_route = true
	layer.set_environment(160.0, Rect2())
	layer.relayout_for(Vector2(1280, 720), Vector2(1280, 720))
	_pressed.clear()
	_released.clear()
	_moves.clear()
	_aims.clear()
	layer.control_pressed.connect(func(control_id: String) -> void: _pressed.append(control_id))
	layer.control_released.connect(func(control_id: String) -> void: _released.append(control_id))
	layer.move_changed.connect(func(direction: Vector2i) -> void: _moves.append(direction))
	layer.aim_changed.connect(func(direction: Vector2) -> void: _aims.append(direction))
	return layer


func _touch(index: int, position: Vector2, pressed: bool, canceled := false) -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = position
	event.pressed = pressed
	event.canceled = canceled
	return event


func _drag(index: int, position: Vector2) -> InputEventScreenDrag:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = position
	return event


func _center(layer: NetworkTouchLayer, control_id: String) -> Vector2:
	return (layer.layout.buttons[control_id] as Rect2).get_center()


func _test_touch_ownership() -> void:
	var layer := _make_layer()
	var move_center := (layer.layout.move_zone as Rect2).get_center()
	var aim_center := (layer.layout.aim_zone as Rect2).get_center()
	_check(layer.handle_event(_touch(0, move_center, true)), "a finger in the move zone is owned")
	_check(layer.owner_of(0) == NetworkTouchLayer.ZONE_MOVE, "index 0 owns the move zone")
	layer.handle_event(_drag(0, move_center + Vector2(120, 0)))
	_check(_moves.back() == Vector2i(1, 0), "dragging right moves right")
	# Second finger: aim while moving.
	layer.handle_event(_touch(1, aim_center, true))
	layer.handle_event(_drag(1, aim_center + Vector2(0, -120)))
	_check(layer.owner_of(1) == NetworkTouchLayer.ZONE_AIM, "index 1 owns the aim zone")
	_check(_aims.back() == Vector2(0, -1), "dragging up aims up")
	_check(_moves.back() == Vector2i(1, 0), "aiming never changes the movement direction")
	# Third finger rotates while moving and aiming.
	layer.handle_event(_touch(2, _center(layer, "rotate"), true))
	_check(_pressed == ["rotate"], "rotate fires once while moving and aiming")
	layer.handle_event(_touch(3, _center(layer, "place"), true))
	_check(_pressed == ["rotate", "place"], "place fires while moving, aiming and holding rotate")
	_check(layer.owner_count() == 4, "four fingers hold four independent owners")
	layer.handle_event(_touch(2, _center(layer, "rotate"), false))
	layer.handle_event(_touch(3, _center(layer, "place"), false))
	_check(_released == ["rotate", "place"], "each button releases exactly once")
	_check(layer.is_held(NetworkTouchLayer.ZONE_MOVE) and layer.is_held(NetworkTouchLayer.ZONE_AIM), "the zones stay held while buttons come and go")
	# Release outside the zone still releases the same finger.
	layer.handle_event(_drag(0, Vector2(5, 5)))
	layer.handle_event(_touch(0, Vector2(5, 5), false))
	_check(not layer.is_held(NetworkTouchLayer.ZONE_MOVE), "a release outside the zone releases its owner")
	_check(_moves.back() == Vector2i.ZERO, "releasing the move finger neutralises movement")
	_check(layer.is_held(NetworkTouchLayer.ZONE_AIM), "the aim finger is unaffected")
	layer.free()


func _test_touch_edge_cases() -> void:
	var layer := _make_layer()
	# No double fire: the same index pressed twice, then slid onto another button.
	layer.handle_event(_touch(0, _center(layer, "jump"), true))
	layer.handle_event(_touch(0, _center(layer, "jump"), true))
	_check(_pressed == ["jump"], "a repeated press edge fires once")
	layer.handle_event(_drag(0, _center(layer, "sneak")))
	_check(_pressed == ["jump"], "sliding onto a neighbour never fires it")
	layer.handle_event(_touch(0, _center(layer, "sneak"), false))
	_check(_released == ["jump"], "the release goes to the original owner only")
	# Palm / dead margin.
	_check(not layer.handle_event(_touch(1, Vector2(2, 2), true)), "a touch on nothing is ignored")
	_check(layer.owner_count() == 0, "an ignored touch owns nothing")
	# Third finger in an already-owned zone.
	var move_center := (layer.layout.move_zone as Rect2).get_center()
	layer.handle_event(_touch(2, move_center, true))
	var count := layer.owner_count()
	_check(layer.handle_event(_touch(3, move_center + Vector2(10, 10), true)), "a second finger in an owned zone is swallowed")
	_check(layer.owner_count() == count, "the swallowed finger owns nothing")
	layer.handle_event(_touch(2, move_center, false))
	# Disabled button owns the finger but never fires.
	layer.set_button_enabled("place", false)
	_pressed.clear()
	_released.clear()
	layer.handle_event(_touch(4, _center(layer, "place"), true))
	layer.handle_event(_touch(4, _center(layer, "place"), false))
	_check(_pressed.is_empty() and _released.is_empty(), "a disabled button neither presses nor releases")
	# Disabling a held button releases it.
	layer.handle_event(_touch(5, _center(layer, "cancel"), true))
	layer.set_button_enabled("cancel", false)
	_check(_released == ["cancel"], "disabling a held button releases it")
	_check(layer.owner_count() == 0, "no finger is left owning a disabled control")
	# Canceled touch releases.
	layer.handle_event(_touch(6, _center(layer, "cheer"), true))
	layer.handle_event(_touch(6, _center(layer, "cheer"), true, true))
	_check(_released.has("cheer") and layer.owner_count() == 0, "a canceled touch releases its owner")
	# Focus loss clears every held control and zone.
	_released.clear()
	layer.handle_event(_touch(7, _center(layer, "sneak"), true))
	layer.handle_event(_touch(8, move_center, true))
	layer.handle_event(_drag(8, move_center + Vector2(-100, 0)))
	layer.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	_check(layer.owner_count() == 0, "focus loss clears every owner")
	_check(_released == ["sneak"] and _moves.back() == Vector2i.ZERO, "focus loss releases held buttons and neutralises movement")
	# Orientation change.
	layer.handle_event(_touch(9, _center(layer, "jump"), true))
	layer._on_viewport_resized()
	_check(layer.owner_count() == 0, "a viewport change releases every finger")
	# Unowned drag and mouse gating.
	_check(not layer.handle_event(_drag(42, move_center)), "a drag from an unowned index is ignored")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = _center(layer, "jump")
	_check(not layer.handle_event(click), "mouse input is ignored unless the debug flag allows it")
	layer.accept_mouse = true
	_check(layer.handle_event(click) and layer.is_held("jump"), "the debug flag lets desktop tests click the layer")
	layer.free()
	# A hidden layer takes no input.
	var hidden := _make_layer()
	hidden.visible = false
	_check(not hidden.handle_event(_touch(0, _center(hidden, "jump"), true)), "a hidden layer takes no input")
	hidden.free()
	# Outside live build the build controls and aim zone do not exist.
	var offline := NetworkTouchLayer.new()
	offline.set_environment(160.0, Rect2())
	offline.relayout_for(Vector2(1280, 720), Vector2(1280, 720))
	_check(not offline.layout.buttons.has("place") and not offline.layout.buttons.has("build"), "build controls exist only on the live route")
	offline.free()


# --- router, table, glyphs ---------------------------------------------------------------------


func _test_router_regressions() -> void:
	var router := LocalInputRouter.new()
	router.set_shared_keyboard_enabled(true)
	for key in [KEY_KP_7, KEY_KP_1, KEY_KP_3, KEY_KP_9, KEY_KP_8, KEY_KP_4, KEY_KP_2, KEY_KP_6]:
		_check(router._keyboard_layout_for_key(key, KEY_LOCATION_UNSPECIFIED) == "K4", "numpad key %d is detected as K4" % key)
	var aim_keys := {KEY_KP_7: "aim_up", KEY_KP_1: "aim_left", KEY_KP_3: "aim_down", KEY_KP_9: "aim_right"}
	for key in aim_keys:
		_check(router._key_action("K4", key) == aim_keys[key], "K4 key %d reaches aim" % key)
	router.set_phase(LocalInputRouter.Phase.PLAY)
	_check(router._gamepad_phase_action(JOY_BUTTON_LEFT_SHOULDER) == "live_cancel", "the left bumper cancels a live placement in Play")
	_check(router._joy_action(JOY_BUTTON_LEFT_SHOULDER) == "live_cancel", "the left bumper is a known joypad button")
	_check(router._gamepad_phase_action(JOY_BUTTON_B) == "back", "B stays Back and never cancels")
	_check(router._gamepad_phase_action(JOY_BUTTON_A) == "jump", "A stays Jump in Play")
	_check(router._gamepad_phase_action(JOY_BUTTON_X) == "rotate", "X stays Rotate (the Play cheer alias)")
	router.set_phase(LocalInputRouter.Phase.LOBBY)
	_check(router._gamepad_phase_action(JOY_BUTTON_LEFT_SHOULDER) == "", "the left bumper does nothing outside Play")
	_check(LocalInputRouter.ROTATE_ALIAS_PLAY == "cheer" and LocalInputRouter.ROTATE_ALIAS_LOBBY == "help", "the rotate aliases are unchanged")
	router.free()


func _router_phase(context: String) -> int:
	match context:
		"lobby":
			return LocalInputRouter.Phase.LOBBY
		"pugad":
			return LocalInputRouter.Phase.PUGAD
		"go":
			return LocalInputRouter.Phase.GO
		"results":
			return LocalInputRouter.Phase.RESULTS
		"pause":
			return LocalInputRouter.Phase.PAUSE
	return LocalInputRouter.Phase.PLAY


## The table speaks in player-facing actions; the router returns its own ids for a few of them.
func _router_action(table_action: String) -> String:
	match table_action:
		"live_confirm":
			return "confirm"
		"help", "cheer":
			return "rotate"
	return table_action


func _test_context_table() -> void:
	var problems := InputContextTable.audit()
	_check(problems.is_empty(), "the action table is unambiguous (%s)" % str(problems))
	var router := LocalInputRouter.new()
	router.set_shared_keyboard_enabled(true)
	for context in InputContextTable.CONTEXTS:
		router.set_phase(_router_phase(context))
		router.live_build_confirm_enabled = context == "build"
		for device in ["k1", "k2", "k3", "k4"]:
			var layout := device.to_upper()
			for row in InputContextTable.bindings(device, context):
				if int(row.control) == KEY_ESCAPE:
					continue
				_check(router._keyboard_layout_for_key(int(row.control), KEY_LOCATION_UNSPECIFIED) == layout or int(row.control) in [KEY_SHIFT, KEY_CTRL], "%s/%s: key %d belongs to %s" % [device, context, int(row.control), layout])
				_check(router._key_action(layout, int(row.control)) == _router_action(str(row.action)), "%s/%s: key %d sends %s" % [device, context, int(row.control), row.action])
		for row in InputContextTable.bindings("gamepad", context):
			if typeof(row.control) != TYPE_INT:
				continue
			_check(router._gamepad_phase_action(int(row.control)) == _router_action(str(row.action)), "gamepad/%s: button %d sends %s" % [context, int(row.control), row.action])
	# Build controls never take over jump, cheer or rotate.
	for device in InputContextTable.DEVICES:
		for action in ["jump", "cheer"]:
			_check(_controls_for(device, "play", action) == _controls_for(device, "build", action), "%s keeps %s identical in play and build" % [device, action])
	_check(_controls_for("gamepad", "build", "live_cancel") == [str(JOY_BUTTON_LEFT_SHOULDER)], "gamepad live_cancel is the left bumper only")
	router.free()


func _controls_for(device: String, context: String, action: String) -> Array:
	var controls: Array = []
	for row in InputContextTable.bindings(device, context):
		if row.action == action:
			controls.append(str(row.control))
	controls.sort()
	return controls


func _test_glyph_coverage() -> void:
	var map := load("res://data/ui/prompt_map.tres") as UiPromptMap
	_check(map != null, "the prompt map loads")
	if map == null:
		return
	for action in GLYPH_ACTIONS:
		for device in GLYPH_DEVICES:
			_check(map.glyph(action, device) != "?", "glyph %s|%s exists" % [action, device])
		_check(map.action_names.has(action), "action name for %s exists" % action)
	_check(map.glyph("live_cancel", "gamepad") == "Left bumper", "the gamepad cancel glyph names the left bumper")
	_check(map.glyph("aim", "k4") == "Num 7 1 3 9", "the K4 aim glyph matches the fixed keys")
	_check(map.glyph("build_toggle", "touch") != map.glyph("live_rotate", "touch"), "touch build and rotate glyphs differ")


# --- HUD and help cards ----------------------------------------------------------------------


func _test_hud_identity() -> void:
	var seen := {}
	for seat in 4:
		var pair := "%s|%s" % [NetworkPhoneHud.shape_for_seat(seat), NetworkPhoneHud.color_for_seat(seat).to_html()]
		_check(not seen.has(NetworkPhoneHud.shape_for_seat(seat)), "seat %d has its own shape" % seat)
		seen[NetworkPhoneHud.shape_for_seat(seat)] = pair
	_check(NetworkPhoneHud.badge_text(1) == "You are P2", "the badge names the player number")
	_check(NetworkPhoneHud.badge_text(-1) == "Joining…", "an unassigned seat says so")
	for state in [NetworkLivePlacementClient.GhostState.TENTATIVE, NetworkLivePlacementClient.GhostState.PENDING, NetworkLivePlacementClient.GhostState.ACCEPTED_AWAIT_TERRAIN, NetworkLivePlacementClient.GhostState.REJECTED]:
		var chip := NetworkPhoneHud.placement_chip(state, "label")
		_check(chip.shape != "" and chip.text == "label", "placement state %d has a shape and text" % state)
	_check(NetworkPhoneHud.placement_chip(NetworkLivePlacementClient.GhostState.NONE, "x").text == "", "no ghost shows no chip")
	_check(NetworkPhoneHud.MIN_TEXT_PX >= 16, "the mid-round text floor stays at the proposed 16")
	_check(NetworkPhoneHud.objective_text(MatchPhaseController.Phase.PUGAD, 255) != "", "the Pugad has an objective line")


func _test_help_cards() -> void:
	var script := load("res://data/ui/tutorial_script.tres") as TutorialScript
	_check(script != null and script.has_all_steps(), "the offline tutorial steps are all still present")
	_check(script != null and script.has_all_network_steps(), "all eight phone steps exist as data")
	_check(TutorialScript.NETWORK_STEPS.size() == 8, "eight phone cards are listed")
	var map := load("res://data/ui/prompt_map.tres") as UiPromptMap
	for step_id in TutorialScript.NETWORK_STEPS:
		var step := script.step(step_id)
		_check(step != null and step.body != "" and step.title != "", "step %s has copy" % step_id)
		if step == null:
			continue
		var text := NetworkHelpCards.render_body(step, map, 1)
		_check(not text.contains("{") and not text.contains("?"), "step %s resolves every token" % step_id)
		_check(map.glyph(step.glyph_action, "touch") != "?", "step %s glyph action exists for touch" % step_id)
	var cards := NetworkHelpCards.new()
	_check(cards.session.is_active(), "a fresh session shows the cards")
	cards.open(0)
	_check(cards.index == 0 and cards.visible, "the cards open at the first step")
	cards.next_card()
	_check(cards.index == 1, "Next advances")
	cards.previous_card()
	_check(cards.index == 0 and cards.session.is_active(), "Back only steps back and is not Skip")
	cards.skip()
	_check(cards.session.skipped and not cards.session.is_active(), "Skip is session-only")
	cards.auto_open_once()
	_check(cards._auto_opened == false, "a skipped session never auto-opens")
	cards.replay()
	_check(cards.session.is_active() and cards.index == 0, "Replay restores the cards")
	cards.open(cards.card_count() - 1)
	cards.next_card()
	_check(cards.session.completed and not cards.visible, "the last card completes and closes")
	_check(not FileAccess.file_exists("user://tutorial_session.cfg"), "nothing is persisted for the session")
	cards.free()
	var fresh := NetworkHelpCards.new()
	fresh.auto_open_once()
	fresh.auto_open_once()
	_check(fresh._auto_opened, "the cards auto-open once per session")
	fresh.free()


func _test_presentation_integration() -> void:
	var presentation := NetworkMatchPresentation.new()
	presentation.touch_controls_forced = true
	root.add_child(presentation)
	await process_frame
	var layer := presentation.get_node_or_null("NetworkTouchLayer") as NetworkTouchLayer
	_check(layer != null, "the presentation builds the touch layer when forced")
	_check(presentation.get_node_or_null("NetworkPhoneHud") != null, "the presentation builds the phone HUD")
	_check(presentation.get_node_or_null("NetworkHelpCards") != null, "the presentation builds the help cards")
	if layer != null:
		layer.set_environment(160.0, Rect2())
		layer.relayout_for(Vector2(1280, 720), Vector2(1280, 720))
		var move_center := (layer.layout.move_zone as Rect2).get_center()
		layer.handle_event(_touch(0, move_center, true))
		layer.handle_event(_drag(0, move_center + Vector2(-150, 0)))
		_check(presentation._axis_x == -1000, "the move zone drives the horizontal axis")
		layer.handle_event(_touch(0, move_center, false))
		_check(presentation._axis_x == 0, "releasing the move finger zeroes the axis")
	presentation.queue_free()
	await process_frame
	var plain := NetworkMatchPresentation.new()
	root.add_child(plain)
	await process_frame
	_check(plain.get_node_or_null("NetworkTouchLayer") == null, "a desktop presentation never builds touch controls")
	plain.queue_free()
	await process_frame


func _test_source_audit() -> void:
	var presentation := FileAccess.get_file_as_string("res://scripts/network/network_match_presentation.gd")
	_check(not presentation.contains("_touch_button") and not presentation.contains("Button.new()"), "the presentation no longer builds plain gameplay Buttons")
	_check(presentation.contains("NetworkTouchLayer.new()"), "the presentation uses the touch layer")
	var layer := FileAccess.get_file_as_string("res://scripts/network/network_touch_layer.gd")
	_check(not layer.contains("Button.new()") and layer.contains("InputEventScreenTouch"), "the layer owns raw touch events, not Buttons")
	_check(layer.contains("InputEventScreenDrag"), "the layer handles drags by index")
	var router := FileAccess.get_file_as_string("res://scripts/input/local_input_router.gd")
	_check(router.contains("KEY_KP_7,"), "the K4 detector lists the numpad aim keys")


func _check(condition: bool, label: String) -> void:
	checks += 1
	if condition:
		print("PASS ", label)
	else:
		failures += 1
		push_error("FAIL " + label)

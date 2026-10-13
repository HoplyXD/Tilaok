extends SceneTree

const HARNESS_SCENE := preload("res://scenes/harness/foundation_harness.tscn")
const EVIDENCE_DIR := "../docs/evidence/p04"

var failures := 0
var checks := 0
var harness: FoundationHarness
var room: ItemLabRoom


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	harness = HARNESS_SCENE.instantiate() as FoundationHarness
	root.add_child(harness)
	await _wait_frames(12)
	await _click_button(harness.get_node("Layout/HarnessPanel/RoomRow/ItemRoomButton") as Button)
	room = harness.active_room as ItemLabRoom
	_check(room != null, "Item Lab opens through the visible foundation-harness button")
	if room == null:
		quit(1)
		return
	_check(not harness.get_node("Layout").visible, "opening the lab exposes the arena viewport")
	await _click_text_button(room, "Join K1")
	await _click_text_button(room, "Join K2")
	_check(room.actors.size() == 2, "visible join controls add two identity-labeled chickens")
	await _click_text_button(room, "Place")
	_check(
		room.input_router.phase == LocalInputRouter.Phase.PLACE and room.cursors.size() == 2,
		"Place button shows one ghost per seat"
	)
	var variant_before := room.selected_variant_key
	await _click_text_button(room, "Variant: %s" % variant_before.get_slice(".", 2))
	_check(
		room.selected_variant_key == "build.hollow_blocks.stack_2x3",
		"Variant button advances to the 2x3 stack (was %s)" % variant_before
	)
	await _tap(KEY_R)
	_check(room.cursors[0].turns == 1, "K1 rotate key turns the 2x3 ghost to 3x2")
	await _tap(KEY_D)
	await _tap(KEY_F)
	_check(
		room.items.persistent_count() == 1, "K1 confirm places a rotated 3x2 piece (lab placement)"
	)
	await _tap(KEY_SHIFT, KEY_LOCATION_RIGHT)
	await _tap(KEY_RIGHT)
	await _tap(KEY_ENTER)
	_check(room.items.persistent_count() == 2, "K2 rotate, move and confirm place a second piece")
	await _click_text_button(room, "Variant: %s" % room.selected_variant_key.get_slice(".", 2))
	_check(room.selected_variant_key == "build.bamboo_bridge.span_4x1", "Variant selects Tulay 4x1")
	await _tap(KEY_W)
	await _tap(KEY_W)
	await _tap(KEY_W)
	await _tap(KEY_R)
	_check(
		room.last_message.contains("Rotation unavailable"),
		"Tulay shows the disabled-rotation cue while vertical is gated"
	)
	await _tap(KEY_F)
	_check(room.items.persistent_count() == 3, "K1 confirm places the one-way Tulay")
	for _step in range(9):
		await _tap(KEY_LEFT)
	var invalid_ghost := room.cursors[1].ghost as ItemGhost
	_check(
		not invalid_ghost.valid and not invalid_ghost.reason.is_empty(),
		"K2 ghost turns invalid with an actionable reason: %s" % invalid_ghost.reason
	)
	await _tap(KEY_ENTER)
	_check(
		room.items.persistent_count() == 3 and room.last_message.begins_with("Rejected"),
		"an invalid confirm is rejected with a visible reason"
	)
	await _wait_frames(3)
	await RenderingServer.frame_post_draw
	var place_image := _save_screenshot("2026-10-13_item_lab_place_1080p.png")
	await _click_text_button(room, "Play")
	_check(
		(
			room.items.in_play
			and room.cursors.is_empty()
			and room.input_router.phase == LocalInputRouter.Phase.PLAY
		),
		"Play button starts the item lifecycle and frees ghosts"
	)
	await _ensure_running()
	var actor := room.actors[0] as ChickenController
	var start_x := actor.global_position.x
	await _send_key(KEY_D, true)
	await _wait_physics_frames(10)
	await _send_key(KEY_D, false)
	_check(
		actor.global_position.x > start_x, "synthetic K1 input moves the real controller in Play"
	)
	await _wait_physics_frames(70)
	await _ensure_running()
	await _wait_physics_frames(10)
	await RenderingServer.frame_post_draw
	_check(room.items.is_active(), "construction is active after the activation grace")
	var play_image := _save_screenshot("2026-10-13_item_lab_play_1080p.png")
	await _click_text_button(room, "Reset")
	_check(
		room.items.persistent_count() == 3 and room.items.in_play,
		"Reset keeps all three pieces and restarts Play"
	)
	await _click_text_button(room, "Clear all")
	_check(room.items.persistent_count() == 0, "Clear all removes construction (match reset)")
	await _click_text_button(room, "Return")
	await _wait_frames(2)
	_check(harness.active_room == null, "Return releases the Item Lab scene")
	_check(harness.get_node("Layout").visible, "return restores the foundation harness")
	print(
		(
			"P04_INTERACTIVE checks=%d failures=%d place=%s play=%s"
			% [checks, failures, place_image.get_size(), play_image.get_size()]
		)
	)
	harness.queue_free()
	await process_frame
	quit(1 if failures > 0 else 0)


func _ensure_running() -> void:
	# Losing OS window focus pauses the game by design; resume it the way a player would.
	for _attempt in range(3):
		if not paused:
			return
		await _click_text_button(room, "Resume")


func _save_screenshot(file_name: String) -> Image:
	var image := root.get_texture().get_image()
	var path := (
		(ProjectSettings.globalize_path("res://").path_join(EVIDENCE_DIR).path_join(file_name))
		. simplify_path()
	)
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var result := image.save_png(path)
	_check(result == OK, "1080p frame saved: %s" % file_name)
	return image


func _tap(key: Key, location: KeyLocation = KEY_LOCATION_UNSPECIFIED) -> void:
	await _ensure_running()
	await _send_key(key, true, location)
	await _send_key(key, false, location)
	await _wait_frames(1)


func _click_text_button(root_node: Node, text_value: String) -> void:
	var pending: Array[Node] = [root_node]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		if node is Button and (node as Button).text == text_value:
			await _click_button(node as Button)
			return
		for child in node.get_children():
			pending.append(child)
	push_error("Could not find visible button '%s'" % text_value)
	failures += 1


func _click_button(button: Button) -> void:
	await _wait_frames(2)
	var center := button.get_global_rect().get_center()
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = center
		event.global_position = center
		event.pressed = pressed
		root.push_input(event, true)
		await process_frame


func _send_key(key: Key, pressed: bool, location: KeyLocation = KEY_LOCATION_UNSPECIFIED) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.location = location
	event.pressed = pressed
	Input.parse_input_event(event)
	await process_frame


func _wait_frames(count: int) -> void:
	for _frame in range(count):
		await process_frame


func _wait_physics_frames(count: int) -> void:
	for _frame in range(count):
		await physics_frame


func _check(condition: bool, label: String) -> void:
	checks += 1
	if condition:
		print("PASS ", label)
	else:
		failures += 1
		push_error("FAIL " + label)

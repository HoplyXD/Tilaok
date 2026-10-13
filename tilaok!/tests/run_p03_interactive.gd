extends SceneTree

const HARNESS_SCENE := preload("res://scenes/harness/foundation_harness.tscn")

var failures := 0
var checks := 0
var harness: FoundationHarness
var room: P03StageRoom


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	harness = HARNESS_SCENE.instantiate() as FoundationHarness
	root.add_child(harness)
	await _wait_frames(3)
	await _click_button(
		harness.get_node("Layout/HarnessPanel/RoomRow/P03StageRoomButton") as Button
	)
	room = harness.active_room as P03StageRoom
	_check(room != null, "P03 arena opens through the visible foundation-harness button")
	if room == null:
		quit(1)
		return
	_check(not harness.get_node("Layout").visible, "opening P03 exposes the arena viewport")
	await _click_text_button(room, "Join K1")
	await _click_text_button(room, "Join K2")
	_check(room.actors.size() == 2, "visible join controls add two identity-labeled chickens")
	_check(
		room.camera_rig.targets.size() == 2,
		"Play camera follows the two live actors created through the UI"
	)
	await _click_text_button(room, "Play")
	_check(
		room.input_router.phase == LocalInputRouter.Phase.PLAY, "Play button enters Play context"
	)
	var actor := room.actors[0] as ChickenController
	var start_x := actor.global_position.x
	await _send_key(KEY_D, true)
	await _wait_physics_frames(8)
	await _send_key(KEY_D, false)
	_check(actor.global_position.x > start_x, "synthetic keyboard input moves the real controller")
	await _click_text_button(room, "Place previews")
	_check(
		(
			room.current_context == BoundedStageCamera.Context.PLACE
			and room.camera_rig.targets.size() == 2
		),
		"Place button frames both unconfirmed pointer previews"
	)
	var pointer_rect: Rect2 = room.pointers[1].rect
	await _click_text_button(room, "Confirm next")
	await _click_text_button(room, "Rotate next")
	_check(
		(
			room.camera_rig.targets.size() == 1
			and not bool(room.pointers[1].confirmed)
			and room.pointers[1].rect.size != pointer_rect.size
		),
		"confirm and rotate controls update the correct pointer extent"
	)
	await _click_text_button(room, "Pause")
	_check(paused, "visible pause control pauses the game tree")
	await _click_text_button(room, "Resume")
	_check(not paused, "visible pause control resumes the game tree")
	await _click_text_button(room, "Reset")
	_check(
		room.actors.size() == 2 and room.pointers.is_empty(),
		"visible reset control clears previews and restores both actors"
	)
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var evidence_path := (
		ProjectSettings
		. globalize_path("res://")
		. path_join("../docs/evidence/p03/2026-10-13_interactive_harness_1080p.png")
		. simplify_path()
	)
	DirAccess.make_dir_recursive_absolute(evidence_path.get_base_dir())
	var save_error := image.save_png(evidence_path)
	_check(save_error == OK, "interactive 1080p harness frame saves as rendered evidence")
	await _click_text_button(room, "Return")
	await _wait_frames(2)
	_check(harness.active_room == null, "visible Return control releases the P03 scene")
	_check(harness.get_node("Layout").visible, "return restores the foundation harness")
	print(
		(
			"P03_INTERACTIVE checks=%d failures=%d evidence=%s size=%s"
			% [checks, failures, evidence_path, image.get_size()]
		)
	)
	harness.queue_free()
	await process_frame
	quit(1 if failures > 0 else 0)


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
	var center := button.get_global_rect().get_center()
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = center
	event.global_position = center
	event.pressed = true
	root.push_input(event, true)
	await process_frame
	event = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = center
	event.global_position = center
	event.pressed = false
	root.push_input(event, true)
	await process_frame


func _send_key(key: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
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

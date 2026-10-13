extends SceneTree
## Rendered REQ-MOVE-004 captures (P02-T16/T21): 1920x1080, minimum zoom, P03 graybox + debug
## wall fixtures. Synthetic input only. Run with a real (non-headless) renderer:
## godot --path "tilaok!" --script res://tests/capture_p02_wall_evidence.gd

const ROOM_SCENE := preload("res://scenes/fixtures/p03_stage_room.tscn")
const BASE_A_RIGHT_FACE_X := 320.0
const BODY_HALF_WIDTH := 12.0

var output_dir := ""


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	output_dir = (
		ProjectSettings.globalize_path("res://").path_join("../docs/evidence/p02-wall").simplify_path()
	)
	var directory_result := DirAccess.make_dir_recursive_absolute(output_dir)
	if directory_result != OK and directory_result != ERR_ALREADY_EXISTS:
		push_error("Could not create evidence directory: %s" % error_string(directory_result))
		quit(1)
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	var room := ROOM_SCENE.instantiate() as P03StageRoom
	room.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(room)
	await _wait_for_frames(3)
	var seat := room.join_keyboard("K1")
	var actor := room.actors[seat] as ChickenController
	room.start_play()
	room.build_wall_fixtures()
	room.set_wall_movement_enabled(true)
	await _wait_for_frames(3)

	_place(actor, Vector2(BASE_A_RIGHT_FACE_X + BODY_HALF_WIDTH + 0.1, 395.0))
	await _wait_physics(10)
	await _capture(room, "01_slide_base_side_1080p.png", actor, "slide")

	_key(room, true)
	await _wait_physics(4)
	_key(room, false)
	await _capture(room, "02_kick_1080p.png", actor, "kick")

	var origin := P03StageRoom.WALL_FIXTURE_ORIGIN
	var excluded_x := (
		origin.x + WallFixtureBuilder.EXCLUDED_X + WallFixtureBuilder.FIXTURE_WIDTH_WU + 12.1
	)
	_place(actor, Vector2(excluded_x, origin.y + 24.0))
	await _wait_physics(12)
	await _capture(room, "03_excluded_surface_1080p.png", actor, "excluded")

	_place(actor, Vector2(BASE_A_RIGHT_FACE_X + BODY_HALF_WIDTH + 0.1, 395.0))
	await _wait_physics(8)
	_key(room, true)
	await _wait_physics(3)
	_key(room, false)
	actor.launch(Vector2(480.0, -900.0))
	var peak_y := actor.global_position.y
	var all_visible := true
	for _frame in range(40):
		await physics_frame
		await process_frame
		peak_y = minf(peak_y, actor.global_position.y)
		if not room.camera_rig.targets.is_empty():
			all_visible = all_visible and room.camera_rig.screen_bounds_visible(
				room.camera_rig.targets[0].world_rect
			)
	print("P02_WALL_CAPTURE max_kick_launch peak_y=%.2f camera_visible=%s" % [peak_y, all_visible])
	await _capture(room, "04_max_kick_launch_camera_1080p.png", actor, "max_kick_launch")
	quit(0)


func _place(actor: ChickenController, position: Vector2) -> void:
	actor.reset_wall_state()
	actor.global_position = position
	actor.velocity = Vector2.ZERO
	actor.locomotion_velocity = Vector2.ZERO
	actor.external_velocity = Vector2.ZERO


func _key(room: P03StageRoom, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = KEY_SPACE
	event.keycode = KEY_SPACE
	event.pressed = pressed
	room.input_router._handle_key(event)


func _wait_physics(frame_count: int) -> void:
	for _frame in range(frame_count):
		await physics_frame
	await process_frame


func _wait_for_frames(frame_count: int) -> void:
	for _frame in range(frame_count):
		await process_frame


func _capture(
	room: P03StageRoom, file_name: String, actor: ChickenController, label: String
) -> void:
	await RenderingServer.frame_post_draw
	var path := output_dir.path_join(file_name)
	var image := root.get_texture().get_image()
	var error := image.save_png(path)
	if error != OK:
		push_error("Could not save %s: %s" % [path, error_string(error)])
		return
	print(
		(
			"P02_WALL_SCREENSHOT label=%s path=%s size=%dx%d zoom=%.3f wall_side=%d sliding=%s "
			+ "lock=%d kicks=%d position=%s"
		)
		% [
			label,
			path,
			image.get_width(),
			image.get_height(),
			room.camera_rig.zoom.x,
			actor.wall_side,
			actor.wall_sliding,
			actor.wall_lock_side,
			actor.wall_kick_count,
			actor.global_position
		]
	)

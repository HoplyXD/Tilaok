extends SceneTree

const ROOM_SCENE := preload("res://scenes/fixtures/p03_stage_room.tscn")
const CLOSE_IMAGE := "2026-10-13_camera_jitter_fix_close_1080p.png"
const APART_IMAGE := "2026-10-13_camera_jitter_fix_apart_1080p.png"
const MAX_VERTICAL_PAIR_DELTA_WU := 0.05
const MAX_CAMERA_CENTER_ERROR_WU := 1.0

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	var room := ROOM_SCENE.instantiate() as P03StageRoom
	room.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(room)
	await _wait_frames(3)
	room.join_keyboard("K1")
	room.join_keyboard("K2")
	var first := room.actors[0] as ChickenController
	var second := room.actors[1] as ChickenController
	room.input_router.set_phase(LocalInputRouter.Phase.LOBBY)
	first.global_position = Vector2(400.0, 300.0)
	second.global_position = Vector2(478.0, 300.0)
	room._update_identity_badges()
	room._update_camera_targets()
	room.camera_rig._initialized = false
	await create_timer(1.5).timeout
	var close_bounds := room.camera_rig._combined_bounds()
	var close_y := room.camera_rig.position.y
	var close_expected_y := (
		room
		. camera_rig
		. _clamped_camera_position(close_bounds.get_center(), room.camera_rig.zoom.x)
		. y
	)
	var close_error := absf(close_y - close_expected_y)
	await _capture(CLOSE_IMAGE)
	second.global_position.x = 482.0
	room._update_identity_badges()
	room._update_camera_targets()
	await create_timer(0.5).timeout
	var apart_bounds := room.camera_rig._combined_bounds()
	var apart_y := room.camera_rig.position.y
	var apart_expected_y := (
		room
		. camera_rig
		. _clamped_camera_position(apart_bounds.get_center(), room.camera_rig.zoom.x)
		. y
	)
	var apart_error := absf(apart_y - apart_expected_y)
	var pair_delta := absf(apart_y - close_y)
	await _capture(APART_IMAGE)
	var result := (
		"PASS"
		if (
			pair_delta <= MAX_VERTICAL_PAIR_DELTA_WU
			and close_error <= MAX_CAMERA_CENTER_ERROR_WU
			and apart_error <= MAX_CAMERA_CENTER_ERROR_WU
		)
		else "FAIL"
	)
	var render_report := (
		(
			"CAMERA_JITTER_RENDER resolution=1920x1080 actors=2 separation=78->82 "
			+ "close_y=%.4f close_expected_y=%.4f close_error=%.4f "
			+ "apart_y=%.4f apart_expected_y=%.4f apart_error=%.4f "
			+ "pair_delta_y=%.4f zoom=%.5f result=%s"
		)
		% [
			close_y,
			close_expected_y,
			close_error,
			apart_y,
			apart_expected_y,
			apart_error,
			pair_delta,
			room.camera_rig.zoom.x,
			result,
		]
	)
	print(render_report)
	if result == "FAIL":
		failures += 1
		push_error("Rendered camera jitter or vertical drift exceeded its tolerance")
	room.queue_free()
	await process_frame
	quit(1 if failures > 0 else 0)


func _wait_frames(count: int) -> void:
	for _frame in range(count):
		await process_frame


func _capture(filename: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var output_dir := ProjectSettings.globalize_path("res://").path_join("../docs/evidence/p03")
	output_dir = output_dir.simplify_path()
	DirAccess.make_dir_recursive_absolute(output_dir)
	var output_path := output_dir.path_join(filename)
	var error := image.save_png(output_path)
	if error != OK:
		failures += 1
		push_error("Failed to save %s: %s" % [output_path, error_string(error)])
	else:
		print("CAMERA_SCREENSHOT path=%s size=%s" % [output_path, image.get_size()])

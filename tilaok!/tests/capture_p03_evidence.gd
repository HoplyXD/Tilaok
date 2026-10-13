extends SceneTree

const ROOM_SCENE := preload("res://scenes/fixtures/p03_stage_room.tscn")
const PERFORMANCE_SAMPLE_COUNT := 600
const MEMORY_OBSERVATION_HOLD_SECONDS := 5.0

var output_dir := ""


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	output_dir = ProjectSettings.globalize_path("res://").path_join("../docs/evidence/p03")
	output_dir = output_dir.simplify_path()
	var directory_result := DirAccess.make_dir_recursive_absolute(output_dir)
	if directory_result != OK and directory_result != ERR_ALREADY_EXISTS:
		push_error("Could not create P03 evidence directory: %s" % error_string(directory_result))
		quit(1)
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	var room := ROOM_SCENE.instantiate() as P03StageRoom
	room.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(room)
	await _wait_for_frames(3)
	_join_four_synthetic_seats(room)
	room.start_play()
	var actor_positions := [
		Vector2(96.0, 456.0), Vector2(256.0, 392.0), Vector2(448.0, 328.0), Vector2(832.0, 328.0)
	]
	for seat_index in range(actor_positions.size()):
		var actor := room.actors[seat_index] as ChickenController
		actor.global_position = actor_positions[seat_index]
		actor.velocity = Vector2.ZERO
		actor.locomotion_velocity = Vector2.ZERO
		actor.external_velocity = Vector2.ZERO
	room.input_router.set_phase(LocalInputRouter.Phase.LOBBY)
	var play_targets: Array[Rect2] = [
		Rect2(Vector2(0.0, 0.0), Vector2(24.0, 48.0)),
		Rect2(Vector2(1000.0, 464.0), Vector2(24.0, 48.0)),
		Rect2(Vector2(820.0, 96.0), Vector2(160.0, 64.0)),
		Rect2(Vector2(500.0, -16.0), Vector2(24.0, 48.0)),
	]
	room.set_camera_fixture_targets(play_targets, BoundedStageCamera.Context.PLAY)
	await _wait_for_frames(40)
	await RenderingServer.frame_post_draw
	var play_path := output_dir.path_join("2026-10-13_play_1080p.png")
	_capture_viewport(play_path, room)
	room.clear_camera_fixture_targets()
	room.enter_place_fixture()
	for pointer in room.pointers:
		(pointer.node as Node).queue_free()
		(pointer.label as Node).queue_free()
	room.pointers.clear()
	room._add_pointer(Rect2(Vector2(0.0, -16.0), Vector2(160.0, 64.0)), false)
	room._add_pointer(Rect2(Vector2(896.0, 416.0), Vector2(128.0, 96.0)), false)
	room._add_pointer(Rect2(Vector2(512.0, 176.0), Vector2(64.0, 160.0)), false)
	room._update_camera_targets()
	await _wait_for_frames(40)
	await RenderingServer.frame_post_draw
	var place_path := output_dir.path_join("2026-10-13_place_1080p.png")
	_capture_viewport(place_path, room)
	DisplayServer.window_set_size(Vector2i(1920, 800))
	await _wait_for_frames(20)
	await RenderingServer.frame_post_draw
	var wide_path := output_dir.path_join("2026-10-13_place_wide_window_1920x800.png")
	_capture_viewport(wide_path, room)
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	await _wait_for_frames(20)
	room.reset_room()
	for seat_index in range(actor_positions.size()):
		var actor := room.actors[seat_index] as ChickenController
		actor.global_position = actor_positions[seat_index]
		actor.velocity = Vector2.ZERO
		actor.locomotion_velocity = Vector2.ZERO
		actor.external_velocity = Vector2.ZERO
	room.start_play()
	for seat_index in range(actor_positions.size()):
		room.input_router._stick_x[seat_index] = 1.0 if seat_index % 2 == 0 else -1.0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var frame_intervals_ms := PackedFloat64Array()
	var started_usec := Time.get_ticks_usec()
	var previous_frame_usec := started_usec
	for frame_index in range(PERFORMANCE_SAMPLE_COUNT):
		if frame_index % 90 == 0:
			for seat_index in range(actor_positions.size()):
				var direction := 1.0 if ((frame_index / 90 + seat_index) % 2 == 0) else -1.0
				room.input_router._stick_x[seat_index] = direction
		await RenderingServer.frame_post_draw
		var frame_usec := Time.get_ticks_usec()
		frame_intervals_ms.append(float(frame_usec - previous_frame_usec) / 1000.0)
		previous_frame_usec = frame_usec
	var elapsed_seconds := float(Time.get_ticks_usec() - started_usec) / 1000000.0
	var memory_mib := float(Performance.get_monitor(Performance.MEMORY_STATIC)) / 1048576.0
	var metrics := _summarize(frame_intervals_ms)
	var status := (
		"PASSED"
		if metrics.p95 <= 16.67 and metrics.worst <= 16.67 and memory_mib <= 512.0
		else "FAILED"
	)
	var report := PackedStringArray(
		[
			"Status: %s" % status,
			"Build: %s" % P03StageRoom.BUILD_ID,
			"Engine: %s" % Engine.get_version_info().string,
			(
				"Machine: %s / %s / %d logical CPUs"
				% [OS.get_name(), OS.get_processor_name(), OS.get_processor_count()]
			),
			(
				"Renderer: %s; GPU: %s"
				% [
					RenderingServer.get_video_adapter_vendor(),
					RenderingServer.get_video_adapter_name()
				]
			),
			"Profile: movement_room / default GameplayTuning",
			"Seed: 12345",
			"Date: 2026-10-13 (local machine date)",
			"Actors: 4 real ChickenController instances; camera targets followed live actor extents",
			"Input: synthetic left/right axes; no physical devices attached or certified",
			(
				"Procedure: 600 uncapped completed render frames at 1920x1080 with v-sync off; arena "
				+ "collision, support contacts and live actor camera motion active"
			),
			(
				"Expected: median/p95/worst rendered frame interval at or below 16.67 ms; Godot static "
				+ "and Windows process memory below 512 MiB; no gameplay sockets"
			),
			(
				"Actual rendered interval: median %.3f ms; p95 %.3f ms; worst %.3f ms"
				% [metrics.median, metrics.p95, metrics.worst]
			),
			"Actual memory: static %.2f MiB; elapsed %.3f s" % [memory_mib, elapsed_seconds],
			(
				"Command: Godot 4.7.2 --path tilaok! --script "
				+ "res://tests/capture_p03_evidence.gd; shell records exit code"
			),
			"Evidence: docs/evidence/p03/2026-10-13_performance.txt",
			"Reviewer: Codex automated fixture run; no human review claimed",
		]
	)
	var report_file := FileAccess.open(
		output_dir.path_join("2026-10-13_performance.txt"), FileAccess.WRITE
	)
	if report_file == null:
		push_error("Could not write P03 performance report")
		quit(1)
		return
	report_file.store_string("\n".join(report) + "\n")
	report_file.close()
	print("P03_CAPTURE play=%s place=%s wide=%s" % [play_path, place_path, wide_path])
	var performance_format := (
		"P03_PERFORMANCE samples=%d elapsed=%.3fs render_median=%.3fms "
		+ "render_p95=%.3fms render_worst=%.3fms memory=%.2fMiB "
		+ "viewport=%s window=%s status=%s"
	)
	print(
		(
			performance_format
			% [
				PERFORMANCE_SAMPLE_COUNT,
				elapsed_seconds,
				metrics.median,
				metrics.p95,
				metrics.worst,
				memory_mib,
				root.get_visible_rect().size,
				DisplayServer.window_get_size(),
				status
			]
		)
	)
	print(
		(
			"P03_MEMORY_WINDOW pid=%d seconds=%.1f"
			% [OS.get_process_id(), MEMORY_OBSERVATION_HOLD_SECONDS]
		)
	)
	await create_timer(MEMORY_OBSERVATION_HOLD_SECONDS).timeout
	room.queue_free()
	await process_frame
	quit(0)


func _join_four_synthetic_seats(room: P03StageRoom) -> void:
	room.join_keyboard("K1")
	room.join_keyboard("K2")
	for device_id in range(2):
		var seat_index := room.input_router.registry.join_gamepad(device_id)
		if seat_index >= 0:
			room.input_router.seat_joined.emit(seat_index)


func _wait_for_frames(frame_count: int) -> void:
	for _frame in range(frame_count):
		await process_frame


func _capture_viewport(path: String, room: P03StageRoom) -> void:
	var image := root.get_texture().get_image()
	var error := image.save_png(path)
	if error != OK:
		push_error("Could not save rendered P03 screenshot: %s" % error_string(error))
	else:
		print(
			(
				"P03_SCREENSHOT path=%s size=%dx%d zoom=%.3f context=%s targets=%d viewport=%s window=%s"
				% [
					path,
					image.get_width(),
					image.get_height(),
					room.camera_rig.zoom.x,
					"PLAY" if room.current_context == BoundedStageCamera.Context.PLAY else "PLACE",
					room.camera_rig.targets.size(),
					root.get_visible_rect().size,
					DisplayServer.window_get_size()
				]
			)
		)


func _summarize(samples: PackedFloat64Array) -> Dictionary:
	var ordered := samples.duplicate()
	ordered.sort()
	var middle := ordered.size() / 2
	var median := (ordered[middle - 1] + ordered[middle]) * 0.5
	var percentile_index := clampi(
		int(ceil(float(ordered.size()) * 0.95)) - 1, 0, ordered.size() - 1
	)
	return {
		"median": median, "p95": ordered[percentile_index], "worst": ordered[ordered.size() - 1]
	}

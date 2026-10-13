extends SceneTree

const ROOM_SCENE := preload("res://scenes/fixtures/item_lab.tscn")
const EVIDENCE_DATE := "2026-10-13"
const PERFORMANCE_SAMPLE_COUNT := 600
const MEMORY_HOLD_SECONDS := 5.0
const KAING_1X1 := "build.hollow_blocks.cell_1x1"
const KAING_1X3 := "build.hollow_blocks.column_1x3"
const KAING_2X3 := "build.hollow_blocks.stack_2x3"
const TULAY_3X1 := "build.bamboo_bridge.span_3x1"
const TULAY_4X1 := "build.bamboo_bridge.span_4x1"
const TULAY_5X1 := "build.bamboo_bridge.span_5x1"

var output_dir := ""
var room: ItemLabRoom
var failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	output_dir = (
		ProjectSettings.globalize_path("res://").path_join("../docs/evidence/p04").simplify_path()
	)
	DirAccess.make_dir_recursive_absolute(output_dir)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	room = ROOM_SCENE.instantiate() as ItemLabRoom
	room.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(room)
	await _wait_frames(8)
	room.join_keyboard("K1")
	room.join_keyboard("K2")
	for device_id in range(2):
		var seat_index := room.input_router.registry.join_gamepad(device_id)
		if seat_index >= 0:
			room.input_router.seat_joined.emit(seat_index)
	await _wait_frames(4)
	await _capture_enabled_variants()
	await _capture_disabled_variants()
	await _capture_ghosts()
	await _capture_eggs_and_library()
	await _capture_crowd_and_performance()
	room.queue_free()
	await process_frame
	quit(1 if failed else 0)


func _place(variant_key: String, cell: Vector2i, turns: int = 0) -> void:
	var no_rects: Array[Rect2] = []
	var result := room.items.place(variant_key, cell, turns, 0, no_rects)
	if not bool(result.allowed):
		failed = true
		push_error("capture placement rejected: %s %s %s" % [variant_key, cell, result.reason])


func _capture_enabled_variants() -> void:
	room.items.reset_match()
	room.enter_place()
	_free_pointers()
	_place(KAING_1X1, Vector2i(8, 6))
	_place(KAING_2X3, Vector2i(11, 6))
	_place(KAING_2X3, Vector2i(15, 6), 1)
	_place(TULAY_4X1, Vector2i(20, 6))
	room.start_play()
	_pin_camera()
	await _wait_frames(30)
	await _save("%s_variants_enabled_1080p.png" % EVIDENCE_DATE, "enabled prototype variants")


func _capture_disabled_variants() -> void:
	# Capture-only tuning override: shows geometry of defined-but-disabled variants.
	var saved := room.tuning.item_enabled_variants
	var saved_vertical := room.tuning.item_tulay_vertical_enabled
	room.tuning.item_enabled_variants = PackedStringArray(
		[KAING_1X1, KAING_1X3, KAING_2X3, TULAY_3X1, TULAY_4X1, TULAY_5X1]
	)
	room.tuning.item_tulay_vertical_enabled = true
	room.items.reset_match()
	room.enter_place()
	_free_pointers()
	_place(KAING_1X3, Vector2i(8, 6))
	_place(KAING_1X3, Vector2i(11, 6), 1)
	_place(TULAY_3X1, Vector2i(15, 6))
	_place(TULAY_5X1, Vector2i(20, 6))
	_place(TULAY_4X1, Vector2i(26, 4), 1)
	room.start_play()
	_pin_camera()
	await _wait_frames(30)
	await _save(
		"%s_variants_disabled_geometry_1080p.png" % EVIDENCE_DATE,
		"defined-but-disabled geometry (capture-only tuning)"
	)
	room.tuning.item_enabled_variants = saved
	room.tuning.item_tulay_vertical_enabled = saved_vertical


func _capture_ghosts() -> void:
	room.items.reset_match()
	room.selected_variant_key = TULAY_4X1
	room.enter_place()
	room.cursors[0].cell = Vector2i(12, 6)
	room.cursors[1].cell = Vector2i(2, 12)
	room.cursors[2].cell = Vector2i(20, 6)
	room.cursors[3].cell = Vector2i(24, 9)
	room._refresh_all_ghosts()
	await _wait_frames(30)
	await _save("%s_ghost_valid_invalid_1080p.png" % EVIDENCE_DATE, "valid vs invalid Tulay ghosts")
	room.cycle_variant()
	room.selected_variant_key = KAING_2X3
	for seat_index in room.cursors:
		room.cursors[seat_index].turns = 0
	room.cursors[2].turns = 1
	room.cursors[3].cell = Vector2i(30, 9)
	room._refresh_all_ghosts()
	await _wait_frames(30)
	await _save(
		"%s_ghost_kaing_1080p.png" % EVIDENCE_DATE, "Kaing 2x3 ghosts incl. rotation and bounds"
	)


func _capture_eggs_and_library() -> void:
	room.items.reset_match()
	room.selected_variant_key = KAING_2X3
	room.enter_place()
	room.select_variant(TULAY_4X1)
	room.toggle_library()
	await _wait_frames(30)
	await _save(
		"%s_eggs_library_1080p.png" % EVIDENCE_DATE, "placeholder eggs, ghost and Library panel"
	)
	room.toggle_library()


func _capture_crowd_and_performance() -> void:
	room.items.reset_match()
	room.enter_place()
	_free_pointers()
	var placed := 0
	for row in range(3, 9):
		for unit in range(4):
			var origin_x := 5 + unit * 5
			_place(TULAY_4X1, Vector2i(origin_x, row))
			_place(KAING_1X1, Vector2i(origin_x + 4, row))
			placed += 2
	room.start_play()
	var positions := [
		Vector2(96.0, 456.0), Vector2(256.0, 392.0), Vector2(448.0, 328.0), Vector2(832.0, 328.0)
	]
	for seat_index in range(4):
		var actor := room.actors[seat_index] as ChickenController
		actor.global_position = positions[seat_index]
		actor.velocity = Vector2.ZERO
		actor.locomotion_velocity = Vector2.ZERO
		actor.external_velocity = Vector2.ZERO
	_pin_camera()
	await _wait_frames(40)
	await _save("%s_crowd_48_1080p.png" % EVIDENCE_DATE, "48 persistent pieces and four chickens")
	for seat_index in range(4):
		room.input_router._stick_x[seat_index] = 1.0 if seat_index % 2 == 0 else -1.0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	await _wait_frames(10)
	var intervals := PackedFloat64Array()
	var started_usec := Time.get_ticks_usec()
	var previous_usec := started_usec
	for frame_index in range(PERFORMANCE_SAMPLE_COUNT):
		if frame_index % 90 == 0:
			for seat_index in range(4):
				var direction := 1.0 if ((frame_index / 90 + seat_index) % 2 == 0) else -1.0
				room.input_router._stick_x[seat_index] = direction
		await RenderingServer.frame_post_draw
		var now_usec := Time.get_ticks_usec()
		intervals.append(float(now_usec - previous_usec) / 1000.0)
		previous_usec = now_usec
	var elapsed := float(Time.get_ticks_usec() - started_usec) / 1000000.0
	var spikes := PackedStringArray()
	for sample_index in range(intervals.size()):
		if intervals[sample_index] > 8.0:
			spikes.append("#%d=%.1fms" % [sample_index, intervals[sample_index]])
	var metrics := _summarize(intervals)
	var memory_mib := float(Performance.get_monitor(Performance.MEMORY_STATIC)) / 1048576.0
	var status := (
		"PASSED"
		if metrics.p95 <= 16.67 and metrics.worst <= 16.67 and memory_mib <= 512.0
		else "FAILED"
	)
	var report := PackedStringArray(
		[
			"Status: %s" % status,
			"Build: %s" % ItemLabRoom.LAB_BUILD_ID,
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
			"Profile: karera_slice / default GameplayTuning",
			"Seed: 12345",
			"Date: %s (local machine date)" % EVIDENCE_DATE,
			"Players: 4 real ChickenController instances (K1, K2, two synthetic gamepad seats)",
			"Input: synthetic stick axes; no physical devices attached or certified",
			"Workload: %d persistent pieces (24 Tulay 4x1 + 24 Kaing 1x1), cap %d" % [placed, 48],
			(
				(
					"Procedure: %d uncapped completed render frames at 1920x1080, v-sync off, "
					% PERFORMANCE_SAMPLE_COUNT
				)
				+ "collision, support contacts, item lifecycle and live camera active"
			),
			"Expected: median/p95/worst <= 16.67 ms; memory <= 512 MiB; no gameplay sockets",
			(
				"Actual rendered interval: median %.3f ms; p95 %.3f ms; worst %.3f ms"
				% [metrics.median, metrics.p95, metrics.worst]
			),
			"Actual memory: static %.2f MiB; elapsed %.3f s" % [memory_mib, elapsed],
			(
				"Frames above 8 ms (index=interval): %s"
				% ("none" if spikes.is_empty() else ", ".join(spikes))
			),
			(
				"Objects: %d total, %d nodes, %d orphan nodes"
				% [
					int(Performance.get_monitor(Performance.OBJECT_COUNT)),
					int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
					int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
				]
			),
			"Command: Godot 4.7.2 --path tilaok! --script res://tests/capture_p04_evidence.gd",
			"Reviewer: Codex automated fixture run; no human review claimed",
		]
	)
	var report_file := FileAccess.open(
		output_dir.path_join("%s_performance.txt" % EVIDENCE_DATE), FileAccess.WRITE
	)
	report_file.store_string("\n".join(report) + "\n")
	report_file.close()
	print(
		(
			"P04_PERFORMANCE samples=%d median=%.3fms p95=%.3fms worst=%.3fms memory=%.2fMiB status=%s"
			% [
				PERFORMANCE_SAMPLE_COUNT,
				metrics.median,
				metrics.p95,
				metrics.worst,
				memory_mib,
				status
			]
		)
	)
	print("P04_MEMORY_WINDOW pid=%d seconds=%.1f" % [OS.get_process_id(), MEMORY_HOLD_SECONDS])
	await create_timer(MEMORY_HOLD_SECONDS).timeout


func _free_pointers() -> void:
	for cursor in room.cursors.values():
		(cursor.ghost as Node).queue_free()
	room.cursors.clear()
	room.pointers.clear()


func _pin_camera() -> void:
	var targets: Array[Rect2] = [
		Rect2(Vector2(0.0, 0.0), Vector2(1024.0, 512.0)),
	]
	room.set_camera_fixture_targets(targets, BoundedStageCamera.Context.PLAY)


func _save(file_name: String, caption: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var path := output_dir.path_join(file_name)
	var error := image.save_png(path)
	if error != OK:
		failed = true
		push_error("could not save %s" % path)
	print(
		(
			"P04_SCREENSHOT file=%s size=%dx%d zoom=%.3f caption=%s"
			% [file_name, image.get_width(), image.get_height(), room.camera_rig.zoom.x, caption]
		)
	)


func _wait_frames(count: int) -> void:
	for _frame in range(count):
		await process_frame


func _summarize(samples: PackedFloat64Array) -> Dictionary:
	var ordered := samples.duplicate()
	ordered.sort()
	var middle := ordered.size() / 2
	var median := (ordered[middle - 1] + ordered[middle]) * 0.5
	var index := clampi(int(ceil(float(ordered.size()) * 0.95)) - 1, 0, ordered.size() - 1)
	return {"median": median, "p95": ordered[index], "worst": ordered[ordered.size() - 1]}

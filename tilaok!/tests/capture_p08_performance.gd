# gdlint: disable=max-file-lines
extends SceneTree

const ROOM_SCENE := preload("res://scenes/match/p08_lagsanay_room.tscn")
const OUTPUT_RELATIVE := "../docs/evidence/p08"
const SAMPLE_FRAMES := 300

var room: P08LagsanayMatchRoom
var output_dir := ""
var rows := PackedStringArray()
var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	output_dir = ProjectSettings.globalize_path("res://").path_join(OUTPUT_RELATIVE).simplify_path()
	DirAccess.make_dir_recursive_absolute(output_dir)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	rows = PackedStringArray(
		[
			"P08 rendered performance and restart run; synthetic seats and scripted scene transitions.",
			"Date: %s UTC" % Time.get_datetime_string_from_system(true),
			(
				"Build: source baseline 160a0b4 plus task-local P08; Godot %s"
				% Engine.get_version_info().string
			),
			(
				"Machine: %s / %s / %d logical CPUs"
				% [OS.get_name(), OS.get_processor_name(), OS.get_processor_count()]
			),
			(
				"Renderer: %s / %s"
				% [
					RenderingServer.get_video_adapter_vendor(),
					RenderingServer.get_video_adapter_name()
				]
			),
			"Profile/seed: lagsanay_lab / 12345; display 1920x1080; v-sync disabled.",
			(
				"Targets: median/p95/worst frame interval <=16.67 ms; "
				+ "Godot static memory <=512 MiB; no gameplay traffic."
			),
			"Review: Codex engineering run; no independent human review recorded.",
		]
	)
	for count in [2, 3, 4]:
		await _sample_player_count(int(count))
	await _exercise_containment_restarts()
	rows.append("P08_PERFORMANCE_SUMMARY failures=%d" % failures)
	var output := FileAccess.open(output_dir.path_join("p08_performance.txt"), FileAccess.WRITE)
	if output == null:
		push_error("Could not write P08 performance report")
		quit(1)
		return
	output.store_string("\n".join(rows) + "\n")
	output.close()
	for row in rows:
		print(row)
	quit(1 if failures > 0 else 0)


func _sample_player_count(count: int) -> void:
	await _create_room(count)
	if not room.start_match():
		_fail("%d-player standalone match did not start" % count)
		await _dispose_room()
		return
	room._enter_place()
	var rail := room.items.place("hazard.rail_trumpo.rail_4x1", Vector2i(14, 8), 0, 0)
	var launcher := room.items.place("hazard.slipper_launcher.lane_4x1", Vector2i(8, 8), 0, 0)
	if not bool(rail.get("allowed", false)) or not bool(launcher.get("allowed", false)):
		_fail(
			(
				"%d-player active-hazard fixture placement failed: %s / %s"
				% [count, str(rail), str(launcher)]
			)
		)
	room._enter_play()
	await _sample_rendered_frames(30)  # Warm up the renderer before measured intervals.
	if count == 2:
		await _capture("07_performance_2p_active_hazards_1920x1080.png")
	var metrics := await _sample_rendered_frames(SAMPLE_FRAMES)
	var static_mib := float(Performance.get_monitor(Performance.MEMORY_STATIC)) / 1048576.0
	var objects := int(Performance.get_monitor(Performance.OBJECT_COUNT))
	var nodes := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var orphans := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	var actors := room.actors.size()
	var persistent := room.items.persistent_count()
	var director_steps := room.items.director.steps
	var item_step_average := 0.0
	if room.items.director.step_samples > 0:
		item_step_average = (
			float(room.items.director.step_usec_total) / room.items.director.step_samples / 1000.0
		)
	var passed := (
		float(metrics.p95) <= 16.67
		and float(metrics.worst) <= 16.67
		and static_mib <= 512.0
		and orphans == 0
		and actors == count
		and persistent == 2
	)
	rows.append(
		(
			(
				"%dP lagsanay_lab seed=12345 synthetic input — frame median/p95/worst "
				+ "%.3f/%.3f/%.3f ms; static %.2f MiB; objects=%d nodes=%d orphans=%d "
				+ "actors=%d items=%d director_steps=%d item_step_avg=%.3f ms result=%s"
			)
			% [
				count,
				metrics.median,
				metrics.p95,
				metrics.worst,
				static_mib,
				objects,
				nodes,
				orphans,
				actors,
				persistent,
				director_steps,
				item_step_average,
				"PASSED" if passed else "FAILED"
			]
		)
	)
	if not passed:
		_fail("%d-player active-hazard performance sample missed a budget or count check" % count)
	await _dispose_room()


func _exercise_containment_restarts() -> void:
	await _create_room(2)
	room.tuning.lagsanay_opening_head_start_seconds = 0.1
	if not room.start_match():
		_fail("restart room did not start")
		await _dispose_room()
		return
	room._enter_place()
	var placement := room.items.place("build.hollow_blocks.cell_1x1", Vector2i(12, 8), 0, 0)
	if not bool(placement.get("allowed", false)):
		_fail("restart fixture could not place persistent construction")
	room._enter_play()
	var scores_before := room.cumulative_score_units.duplicate(true)
	var persistent_before := room.items.persistent_count()
	var successful_restarts := 0
	for attempt in range(1, 4):
		var breach_seat := -1
		for seat in room.lagsanay_controller.seat_indices:
			if int(seat) != room.lagsanay_controller.taya_seat:
				breach_seat = int(seat)
				break
		var actor := room.actors[breach_seat] as ChickenController
		actor.global_position = Vector2(actor.global_position.x, -500.0)
		actor.containment_outcome_reported = true
		actor.escaped_bounds.emit()
		await physics_frame
		if not room._defect_paused or not paused:
			_fail("containment breach %d did not pause as a prototype defect" % attempt)
			break
		if (
			room.items.persistent_count() != persistent_before
			or room.cumulative_score_units != scores_before
		):
			_fail("aborted attempt %d changed construction or cumulative score" % attempt)
			break
		room._restart_lagsanay_attempt()
		await physics_frame
		if room._defect_paused or paused or not room.lagsanay_controller.active:
			_fail("containment retry %d did not restore a fresh active round" % attempt)
			break
		successful_restarts += 1
	(
		rows
		. append(
			(
				(
					"containment restart attempts=3 passed=%d score_preserved=%s construction=%d actors=%d "
					+ "— synthetic escaped_bounds signal; no award on aborted attempts"
				)
				% [
					successful_restarts,
					str(room.cumulative_score_units == scores_before),
					room.items.persistent_count(),
					room.actors.size()
				]
			)
		)
	)
	if successful_restarts != 3:
		_fail("repeated containment restart/cleanup cycle incomplete")
	await _dispose_room()
	await _wait_frames(2)
	var remaining_orphans := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	rows.append(
		(
			"post-room cleanup orphan_nodes=%d result=%s"
			% [remaining_orphans, "PASSED" if remaining_orphans == 0 else "FAILED"]
		)
	)
	if remaining_orphans != 0:
		_fail("P08 room cleanup left orphan nodes")


func _create_room(count: int) -> void:
	await _dispose_room()
	room = ROOM_SCENE.instantiate() as P08LagsanayMatchRoom
	root.add_child(room)
	await _wait_frames(4)
	room.join_keyboard("K1")
	room.join_keyboard("K2")
	for device in range(800, 800 + maxi(0, count - 2)):
		var seat := room.input_router.registry.join_gamepad(device)
		if seat >= 0:
			room.input_router.seat_joined.emit(seat)
	for seat in room.input_router.registry.joined_seats():
		room.input_router.registry.set_ready(int(seat.seat), true)


func _sample_rendered_frames(frame_count: int) -> Dictionary:
	var intervals := PackedFloat64Array()
	var previous := Time.get_ticks_usec()
	for _frame in range(frame_count):
		await RenderingServer.frame_post_draw
		var current := Time.get_ticks_usec()
		intervals.append(float(current - previous) / 1000.0)
		previous = current
	intervals.sort()
	var index := clampi(int(ceil(intervals.size() * 0.95)) - 1, 0, intervals.size() - 1)
	return {
		"median": intervals[intervals.size() / 2], "p95": intervals[index], "worst": intervals[-1]
	}


func _capture(file_name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var path := output_dir.path_join(file_name)
	var result := image.save_png(path)
	if result != OK or image.get_size() != Vector2i(1920, 1080):
		_fail("capture %s failed (size=%s error=%d)" % [file_name, str(image.get_size()), result])
	else:
		rows.append(
			(
				"Capture: %s (%s), active Trumpo and Launcher, synthetic seat identities."
				% [file_name, str(image.get_size())]
			)
		)


func _dispose_room() -> void:
	if room != null and is_instance_valid(room):
		if paused:
			paused = false
		room.queue_free()
		await process_frame
	room = null


func _wait_frames(count: int) -> void:
	for _frame in range(count):
		await process_frame


func _fail(message: String) -> void:
	failures += 1
	rows.append("FAILED — " + message)
	push_error("P08 performance: " + message)

extends SceneTree

const P07_SCENE := preload("res://scenes/match/p07_first_playable_room.tscn")
const OUTPUT_RELATIVE := "../docs/evidence/p07"
const VARIANT_1X1 := "build.hollow_blocks.cell_1x1"
const SAMPLE_FRAMES := 300

var room: P07FirstPlayableMatchRoom
var output_dir := ""
var failures := 0
var frame_budget_misses := 0
var report_lines := PackedStringArray()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var evidence_override := OS.get_environment("TILAOK_P07_EVIDENCE_DIR")
	output_dir = (
		evidence_override.simplify_path()
		if not evidence_override.is_empty()
		else ProjectSettings.globalize_path("res://").path_join(OUTPUT_RELATIVE).simplify_path()
	)
	DirAccess.make_dir_recursive_absolute(output_dir)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	report_lines = PackedStringArray(
		[
			"P07 scripted render and performance capture; not human-play evidence.",
			(
				"Runtime: exported executable"
				if OS.has_feature("standalone")
				else "Runtime: project executable"
			),
			"Date: 2026-10-14 Asia/Manila",
			"Engine: %s" % Engine.get_version_info().string,
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
			(
				"Display: 1920x1080 windowed; v-sync disabled; %d frames per phase sample"
				% SAMPLE_FRAMES
			),
			(
				"Input: K1/K2 plus synthetic gamepad identities for seats 3/4; scripted phase "
				+ "transitions and goal callbacks."
			),
			(
				"Targets: frame p95/worst <=16.67 ms; Godot static memory <=512 MiB; "
				+ "local gameplay traffic 0 B/s by design."
			),
		]
	)
	await _capture_two_seat_loop()
	for seat_count in [2, 3, 4]:
		await _sample_seat_count(int(seat_count))
	var capture_status := "PASSED" if failures == 0 else "FAILED"
	var frame_status := "WITHIN BUDGET" if frame_budget_misses == 0 else "EXCEEDED"
	report_lines.insert(
		0, "Overall: capture %s; frame-time budget %s." % [capture_status, frame_status]
	)
	var output := FileAccess.open(output_dir.path_join("p07_performance.txt"), FileAccess.WRITE)
	if output == null:
		push_error("Could not write P07 performance evidence")
		quit(1)
		return
	output.store_string("\n".join(report_lines) + "\n")
	output.close()
	for line in report_lines:
		print(line)
	quit(1 if failures > 0 else 0)


func _capture_two_seat_loop() -> void:
	room = P07_SCENE.instantiate() as P07FirstPlayableMatchRoom
	root.add_child(room)
	await _wait_frames(30)
	room.join_keyboard("K1")
	room.join_keyboard("K2")
	await _capture("01_lobby_1920x1080.png")
	room.input_router.registry.set_ready(0, true)
	room._on_match_action_pressed(0, "ready")
	room.input_router.registry.set_ready(1, true)
	room._on_match_action_pressed(1, "ready")
	if room.phase_controller.phase != MatchPhaseController.Phase.PUGAD:
		_fail("Two-seat ready flow did not start Pugad")
		room.queue_free()
		await _wait_frames(4)
		return
	await _capture("02_pugad_1920x1080.png")
	room._queue_claim(0, str(room.egg_pool[0].egg_id))
	room._queue_claim(1, str(room.egg_pool[1].egg_id))
	await physics_frame
	room._flush_claims()
	if room.phase_controller.phase != MatchPhaseController.Phase.PLACE:
		_fail("Distinct Pugad claims did not enter Place")
		room.queue_free()
		await _wait_frames(4)
		return
	await _capture("03_place_1920x1080.png")
	var construction := room.items.place(VARIANT_1X1, Vector2i(8, 8), 0, 0)
	if not bool(construction.get("allowed", false)):
		_fail("P07 capture construction placement failed: %s" % str(construction))
	room._enter_play()
	await _wait_frames(30)
	await _capture("04_karera_1920x1080.png")
	var race_metrics := await _sample_frames(SAMPLE_FRAMES)
	for actor_variant in room.actors.values():
		var actor := actor_variant as ChickenController
		actor.global_position = room.goal_area.global_position
		room._on_goal_body_entered(actor)
	await _wait_physics_frames(8)
	if room.phase_controller.phase != MatchPhaseController.Phase.RESULTS:
		_fail("P07 actors positioned at goal did not resolve to results")
		room.queue_free()
		await _wait_frames(4)
		return
	var results_metrics := await _sample_frames(SAMPLE_FRAMES)
	await _capture("05_results_1920x1080.png")
	_append_metrics(2, room, race_metrics, results_metrics, "capture loop")
	room._start_next_round()
	if room.phase_controller.phase != MatchPhaseController.Phase.PUGAD:
		_fail("Results did not advance to next-round Pugad")
	else:
		await _capture("06_next_round_pugad_1920x1080.png")
		var audit: Dictionary = room.reset_audit_rows.back()
		if not bool(audit.get("construction_preserved", false)):
			_fail("P07 capture next-round transition lost construction")
	room.queue_free()
	await _wait_frames(4)


func _sample_seat_count(seat_count: int) -> void:
	var sample_room := P07_SCENE.instantiate() as P07FirstPlayableMatchRoom
	root.add_child(sample_room)
	await _wait_frames(30)
	sample_room.join_keyboard("K1")
	sample_room.join_keyboard("K2")
	for seat_index in range(2, seat_count):
		var seat := sample_room.input_router.registry.join_gamepad(810 + seat_index)
		if seat >= 0:
			sample_room.input_router.seat_joined.emit(seat)
	for joined in sample_room.input_router.registry.joined_seats():
		sample_room.input_router.registry.set_ready(int(joined.seat), true)
	if not sample_room.start_match():
		_fail("%d-seat P07 profile failed to start" % seat_count)
		sample_room.queue_free()
		await _wait_frames(4)
		return
	sample_room._finish_pugad_timeout()
	if sample_room.phase_controller.phase != MatchPhaseController.Phase.PLACE:
		_fail("%d-seat P07 timeout did not enter Place" % seat_count)
		sample_room.queue_free()
		await _wait_frames(4)
		return
	var construction := sample_room.items.place(VARIANT_1X1, Vector2i(8, 8), 0, 0)
	if not bool(construction.get("allowed", false)):
		_fail("%d-seat P07 performance construction failed" % seat_count)
	sample_room._enter_play()
	await _wait_frames(30)
	if seat_count == 4:
		await _capture_minimum_zoom(sample_room)
	var run_started := Time.get_ticks_msec()
	var race_metrics := await _sample_frames(SAMPLE_FRAMES)
	for actor_variant in sample_room.actors.values():
		var actor := actor_variant as ChickenController
		actor.global_position = sample_room.goal_area.global_position
		sample_room._on_goal_body_entered(actor)
	await _wait_physics_frames(8)
	if sample_room.phase_controller.phase != MatchPhaseController.Phase.RESULTS:
		_fail(
			(
				"%d-seat P07 goal callback did not resolve (queued=%d, outcomes=%d, paused=%s)"
				% [
					seat_count,
					sample_room.race_candidate_queue.candidates.size(),
					sample_room.race_round_controller.ledger.outcomes().size(),
					paused
				]
			)
		)
		sample_room.queue_free()
		await _wait_frames(4)
		return
	var results_metrics := await _sample_frames(SAMPLE_FRAMES)
	var elapsed_seconds := float(Time.get_ticks_msec() - run_started) / 1000.0
	_append_metrics(seat_count, sample_room, race_metrics, results_metrics, "performance")
	report_lines.append(
		(
			"%d-seat sample duration: %.3f s for %d race + %d results frames."
			% [seat_count, elapsed_seconds, SAMPLE_FRAMES, SAMPLE_FRAMES]
		)
	)
	sample_room.queue_free()
	await _wait_frames(4)


func _capture_minimum_zoom(sample_room: P07FirstPlayableMatchRoom) -> void:
	var spread := [
		Vector2(200.0, 900.0),
		Vector2(1800.0, 900.0),
		Vector2(1800.0, 180.0),
		Vector2(200.0, 180.0),
	]
	var seat_indices: Array = sample_room.actors.keys()
	seat_indices.sort()
	for index in range(seat_indices.size()):
		(sample_room.actors[seat_indices[index]] as ChickenController).global_position = spread[index]
	sample_room._update_identity_badges()
	sample_room._update_camera_targets()
	sample_room.camera_rig.set_process(false)
	sample_room.camera_rig.global_position = Vector2(1024.0, 448.0)
	sample_room.camera_rig.zoom = Vector2.ONE * sample_room.tuning.camera_zoom_min
	await _wait_frames(3)
	sample_room._update_identity_badges()
	sample_room._update_camera_targets()
	var visible_count := 0
	for target in sample_room.camera_rig.targets:
		if sample_room.camera_rig.screen_bounds_visible(target.world_rect):
			visible_count += 1
	if sample_room.camera_rig.targets.size() != 4 or visible_count != 4:
		_fail(
			(
				"Four-seat minimum-zoom camera shows %d of %d targets"
				% [visible_count, sample_room.camera_rig.targets.size()]
			)
		)
	(
		report_lines
		. append(
			(
				(
					"Minimum-zoom check: zoom %.2f (configured %.2f); "
					+ "visible targets %d/4; synthetic corner spread."
				)
				% [
					sample_room.camera_rig.zoom.x,
					sample_room.tuning.camera_zoom_min,
					visible_count,
				]
			)
		)
	)
	await _capture("07_four_seat_min_zoom_1920x1080.png")
	sample_room.camera_rig.set_process(true)


func _append_metrics(
	seat_count: int,
	sampled_room: P07FirstPlayableMatchRoom,
	race: Dictionary,
	results: Dictionary,
	label: String
) -> void:
	var static_mib := float(Performance.get_monitor(Performance.MEMORY_STATIC)) / 1048576.0
	var objects := int(Performance.get_monitor(Performance.OBJECT_COUNT))
	var nodes := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var orphans := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	var frame_passed := (
		float(race.p95) <= 16.67
		and float(race.worst) <= 16.67
		and float(results.p95) <= 16.67
		and float(results.worst) <= 16.67
	)
	if not frame_passed:
		frame_budget_misses += 1
	var runtime_passed := static_mib <= 512.0 and orphans == 0
	if not runtime_passed:
		_fail("%d-seat %s sample exceeded memory/orphan targets" % [seat_count, label])
	report_lines.append(
		(
			(
				"%s / %d seats / %s / seed %d — race median/p95/worst %.3f/%.3f/%.3f ms; "
				+ "results %.3f/%.3f/%.3f ms; static %.2f MiB; objects %d; nodes %d; "
				+ "orphans %d; actors %d; persistent items %d; targets %s."
			)
			% [
				label,
				seat_count,
				sampled_room.profile_id,
				sampled_room.match_seed,
				race.median,
				race.p95,
				race.worst,
				results.median,
				results.p95,
				results.worst,
				static_mib,
				objects,
				nodes,
				orphans,
				sampled_room.actors.size(),
				sampled_room.items.persistent_count(),
				(
					"frame within budget"
					if frame_passed
					else (
						"frame budget exceeded; memory/orphans %s"
						% ("within budget" if runtime_passed else "failed")
					)
				)
			]
		)
	)


func _sample_frames(frame_count: int) -> Dictionary:
	var intervals := PackedFloat64Array()
	var previous := Time.get_ticks_usec()
	for _frame_index in range(frame_count):
		await RenderingServer.frame_post_draw
		var current := Time.get_ticks_usec()
		intervals.append(float(current - previous) / 1000.0)
		previous = current
	intervals.sort()
	var total := 0.0
	for interval in intervals:
		total += interval
	var p95_index := clampi(int(ceil(intervals.size() * 0.95)) - 1, 0, intervals.size() - 1)
	return {
		"median": intervals[intervals.size() / 2],
		"p95": intervals[p95_index],
		"worst": intervals[intervals.size() - 1],
		"mean": total / maxf(1.0, intervals.size()),
	}


func _capture(file_name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var path := output_dir.path_join(file_name)
	var result := image.save_png(path)
	if result != OK or image.get_size() != Vector2i(1920, 1080):
		_fail(
			"Capture %s failed at size %s (save result %d)" % [file_name, image.get_size(), result]
		)
	else:
		report_lines.append(
			"Capture: %s (%s), scripted graybox UI." % [file_name, image.get_size()]
		)


func _wait_frames(count: int) -> void:
	for _frame_index in range(count):
		await process_frame


func _wait_physics_frames(count: int) -> void:
	for _frame_index in range(count):
		await physics_frame


func _fail(message: String) -> void:
	failures += 1
	push_error("P07 CAPTURE FAIL: " + message)

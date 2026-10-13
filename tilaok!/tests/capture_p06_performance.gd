extends SceneTree

const MATCH_SCENE := preload("res://scenes/match/match_room.tscn")
const OUTPUT_RELATIVE := "../docs/evidence/p06"
const VARIANT_1X1 := "build.hollow_blocks.cell_1x1"
const SAMPLE_FRAMES := 300
const REPEATED_ROUNDS := 10

var failures := 0
var output_dir := ""
var report_lines := PackedStringArray()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	output_dir = ProjectSettings.globalize_path("res://").path_join(OUTPUT_RELATIVE).simplify_path()
	DirAccess.make_dir_recursive_absolute(output_dir)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	report_lines = PackedStringArray(
		[
			"P06 2/3/4-seat Karera/results frame sample",
			"Date: 2026-10-14 Asia/Manila",
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
			"Display: 1920x1080, windowed; v-sync off; %d frames per phase sample" % SAMPLE_FRAMES,
			"Input: K1/K2 keyboard routing plus synthetic gamepad identities for seats 3/4.",
			(
				"Procedure: ten real Play/results transitions per seat count; sample active Play "
				+ "and live results once per count."
			),
			(
				"Targets: p95 and worst frame <16.67 ms; Godot static memory <512 MiB; local "
				+ "gameplay has no network path (0 B/s)."
			),
		]
	)
	for seat_count in [2, 3, 4]:
		await _sample_seat_count(int(seat_count))
	var status := "PASSED" if failures == 0 else "FAILED"
	report_lines.insert(0, "Status: " + status)
	var output := FileAccess.open(output_dir.path_join("p06_performance.txt"), FileAccess.WRITE)
	if output == null:
		push_error("Could not write P06 performance evidence")
		quit(1)
		return
	output.store_string("\n".join(report_lines) + "\n")
	output.close()
	for line in report_lines:
		print(line)
	quit(1 if failures > 0 else 0)


func _sample_seat_count(seat_count: int) -> void:
	var room := MATCH_SCENE.instantiate() as P05MatchRoom
	root.add_child(room)
	await _wait_frames(30)
	room.join_keyboard("K1")
	room.join_keyboard("K2")
	for seat_index in range(2, seat_count):
		var joined_seat := room.input_router.registry.join_gamepad(710 + seat_index)
		if joined_seat >= 0:
			room.input_router.seat_joined.emit(joined_seat)
	for seat in room.input_router.registry.joined_seats():
		room.input_router.registry.set_ready(int(seat.seat), true)
	if not room.start_match():
		_fail("%d-seat profile failed to start" % seat_count)
		room.queue_free()
		await _wait_frames(3)
		return
	var match_seed := room.match_seed
	for round_index in range(REPEATED_ROUNDS):
		if round_index > 0:
			room._start_next_round()
		room.assignments.clear()
		for seat in room.input_router.registry.joined_seats():
			var seat_index := int(seat.seat)
			room.assignments[seat_index] = str(room.egg_pool[seat_index].egg_id)
		room._enter_place()
		var construction := room.items.place(VARIANT_1X1, Vector2i(8 + round_index * 2, 8), 0, 0)
		if not bool(construction.get("allowed", false)):
			_fail(
				(
					"%d-seat round %d construction fixture failed: %s"
					% [seat_count, round_index + 1, str(construction)]
				)
			)
			break
		room._enter_play()
		if round_index == 0:
			for seat in room.input_router.registry.joined_seats():
				var actor := room.actors[int(seat.seat)] as ChickenController
				actor.global_position = Vector2(96.0 + int(seat.seat) * 100.0, 400.0)
			await _wait_frames(30)
			var race_metrics := await _sample_frames(SAMPLE_FRAMES)
			var goal := room.goal_area.global_position
			for actor_variant in room.actors.values():
				(actor_variant as ChickenController).global_position = goal
			await _wait_physics_frames(4)
			if room.phase_controller.phase != MatchPhaseController.Phase.RESULTS:
				_fail("%d-seat goal trigger did not resolve the sampled race" % seat_count)
			var results_metrics := await _sample_frames(SAMPLE_FRAMES)
			_append_metrics(seat_count, match_seed, race_metrics, results_metrics, room)
		else:
			var goal := room.goal_area.global_position
			for actor_variant in room.actors.values():
				(actor_variant as ChickenController).global_position = goal
			await _wait_physics_frames(4)
			if room.phase_controller.phase != MatchPhaseController.Phase.RESULTS:
				_fail(
					(
						"%d-seat repeated round %d failed to reach results"
						% [seat_count, round_index + 1]
					)
				)
	if room.items.round_number != REPEATED_ROUNDS:
		_fail(
			(
				"%d-seat fixture ended on round %d, expected %d"
				% [seat_count, room.items.round_number, REPEATED_ROUNDS]
			)
		)
	if room.items.persistent_count() != REPEATED_ROUNDS:
		_fail(
			(
				"%d-seat fixture retained %d pieces, expected %d"
				% [seat_count, room.items.persistent_count(), REPEATED_ROUNDS]
			)
		)
	report_lines.append(
		(
			"%d-seat run: %d completed rounds; %d persistent pieces; profile=%s; seed=%d."
			% [
				seat_count,
				REPEATED_ROUNDS,
				room.items.persistent_count(),
				room.profile_id,
				match_seed
			]
		)
	)
	room.queue_free()
	await _wait_frames(4)


func _append_metrics(
	seat_count: int, seed_value: int, race: Dictionary, results: Dictionary, room: P05MatchRoom
) -> void:
	var static_mib := float(Performance.get_monitor(Performance.MEMORY_STATIC)) / 1048576.0
	var objects := int(Performance.get_monitor(Performance.OBJECT_COUNT))
	var nodes := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var orphans := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	var passed := (
		float(race.p95) <= 16.67
		and float(race.worst) <= 16.67
		and float(results.p95) <= 16.67
		and float(results.worst) <= 16.67
		and static_mib <= 512.0
		and orphans == 0
	)
	if not passed:
		_fail("%d-seat frame, memory, or orphan target failed" % seat_count)
	report_lines.append(
		(
			(
				"%d seats / %s / seed %d — race median/p95/worst %.3f/%.3f/%.3f ms; "
				+ "results %.3f/%.3f/%.3f ms; static %.2f MiB; objects %d; nodes %d; "
				+ "orphans %d; targets %s."
			)
			% [
				seat_count,
				room.profile_id,
				seed_value,
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
				"PASSED" if passed else "FAILED"
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


func _wait_frames(count: int) -> void:
	for _frame_index in range(count):
		await process_frame


func _wait_physics_frames(count: int) -> void:
	for _frame_index in range(count):
		await physics_frame


func _fail(message: String) -> void:
	failures += 1
	push_error("P06 PERFORMANCE FAIL: " + message)

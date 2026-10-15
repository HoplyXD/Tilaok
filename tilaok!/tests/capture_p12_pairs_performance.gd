extends SceneTree

## P12 frame/memory sample of the stacked rounds at 1920x1080 (windowed, v-sync off), same
## procedure and targets as capture_p06_performance.gd / capture_match_ui_performance.gd.
## Heaviest case: four seats, Kangaroo + Lagsanay with Storm active, on a crowded round-12 stage.
## Run from an ISOLATED copy: it overwrites docs/evidence/p12/p12_pairs_performance.txt.

const SCENARIOS := preload("res://tests/p12_pair_room_scenarios.gd")
const OUTPUT_RELATIVE := "../docs/evidence/p12"
const SAMPLE_FRAMES := 300
const WARMUP_FRAMES := 120
const FRAME_TARGET_MS := 16.67
const MEMORY_TARGET_MIB := 512.0
const CROWD_VARIANTS: PackedStringArray = [
	"build.hollow_blocks.cell_1x1",
	"build.bamboo_bridge.span_4x1",
	"build.solid_block.slab_3x1",
	"build.wood_box.box_2x2",
]

var scn
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
			"P12 stacked-round frame/memory sample",
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
			(
				"Display: 1920x1080, windowed; v-sync off; %d warm-up then %d sampled frames per case."
				% [WARMUP_FRAMES, SAMPLE_FRAMES]
			),
			"Input: synthetic K1/K2 keyboard seats plus synthetic gamepad IDs 7101/7102.",
			(
				"Stage: crowded round-12 stage (items.round_number = 11, up to 40 persistent "
				+ "pieces); Storm forced early (storm_after_commands = 2)."
			),
			"Targets: p95 and worst frame < 16.67 ms; static memory < 512 MiB; no orphan nodes.",
		]
	)
	scn = SCENARIOS.new(_noop_check, self)
	await _sample("Kg+L (heaviest, Storm)", 4, {12: [scn.KANGAROO, scn.LAGSANAY]}, true)
	await _sample("Kg+L (Storm)", 2, {12: [scn.KANGAROO, scn.LAGSANAY]}, true)
	await _sample("K+L", 4, {12: [scn.KARERA, scn.LAGSANAY]}, false)
	await _sample("K+Kg", 4, {12: [scn.KARERA, scn.KANGAROO]}, false)
	report_lines.insert(0, "Status: " + ("PASSED" if failures == 0 else "FAILED"))
	var output := FileAccess.open(
		output_dir.path_join("p12_pairs_performance.txt"), FileAccess.WRITE
	)
	if output != null:
		output.store_string("\n".join(report_lines) + "\n")
		output.close()
	for line in report_lines:
		print(line)
	quit(1 if failures > 0 else 0)


func _noop_check(_condition: bool, _message: String) -> void:
	pass


func _sample(label: String, seat_count: int, overrides: Dictionary, storm: bool) -> void:
	await scn._open(seat_count, overrides)
	var room: P12ScheduledMatchRoom = scn.room
	room.tuning.match_pugad_seconds = 600.0
	if storm:
		room.tuning.kangaroo_storm_after_commands = 2
	room.items.round_number = 11
	var placed := _crowd(room)
	scn._to_play()
	scn._spread()
	scn._skip_bomb_head_start()
	await scn._steps(30)
	if storm:
		# Run simulation time forward (time scale) until Storm cadence is active, then sample.
		Engine.time_scale = 8.0
		for _step in 1200:
			await physics_frame
			if room.kangaroo_round.controller.storm_active:
				break
		Engine.time_scale = 1.0
	var storm_at_start: bool = room.kangaroo_round.controller.storm_active
	# Warm-up: the first rendered frames of a new scene include one-off shader/cache work.
	await _sample_frames(WARMUP_FRAMES)
	var metrics := await _sample_frames(SAMPLE_FRAMES)
	var static_mib := float(Performance.get_monitor(Performance.MEMORY_STATIC)) / 1048576.0
	var objects := int(Performance.get_monitor(Performance.OBJECT_COUNT))
	var nodes := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var orphans := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	var storm_seen: bool = storm_at_start or _storm_commands(room) > 0
	var passed := (
		float(metrics.p95) <= FRAME_TARGET_MS
		and float(metrics.worst) <= FRAME_TARGET_MS
		and static_mib <= MEMORY_TARGET_MIB
		and orphans == 0
	)
	if not passed:
		failures += 1
	report_lines.append(
		(
			(
				"%s — %d seats, %d pieces, plan %s, storm active at start=%s "
				+ "(storm commands %d): median/p95/worst %.3f/%.3f/%.3f ms; "
				+ "static %.2f MiB; objects %d; nodes %d; orphans %d; %s."
			)
			% [
				label,
				seat_count,
				placed,
				EventSchedule.describe(room.current_entry()),
				str(storm_seen),
				_storm_commands(room),
				metrics.median,
				metrics.p95,
				metrics.worst,
				static_mib,
				objects,
				nodes,
				orphans,
				"PASSED" if passed else "FAILED"
			]
		)
	)
	await scn._close()


func _storm_commands(room: P12ScheduledMatchRoom) -> int:
	var count := 0
	for command in room.kangaroo_round.controller.command_history:
		if bool(command.is_storm):
			count += 1
	return count


func _crowd(room: P12ScheduledMatchRoom) -> int:
	var placed := 0
	var index := 0
	for row in range(3, 17, 2):
		for column in range(1, 62, 2):
			var variant := CROWD_VARIANTS[index % CROWD_VARIANTS.size()]
			index += 1
			var result := room.items.place(variant, Vector2i(column, row), 0, 0)
			if bool(result.get("allowed", false)):
				placed += 1
			if placed >= 40:
				return placed
	return placed


func _sample_frames(frame_count: int) -> Dictionary:
	var intervals := PackedFloat64Array()
	var previous := Time.get_ticks_usec()
	for _frame_index in range(frame_count):
		await RenderingServer.frame_post_draw
		var current := Time.get_ticks_usec()
		intervals.append(float(current - previous) / 1000.0)
		previous = current
	intervals.sort()
	var p95_index := clampi(int(ceil(intervals.size() * 0.95)) - 1, 0, intervals.size() - 1)
	return {
		"median": intervals[floori(intervals.size() / 2.0)],
		"p95": intervals[p95_index],
		"worst": intervals[intervals.size() - 1],
	}

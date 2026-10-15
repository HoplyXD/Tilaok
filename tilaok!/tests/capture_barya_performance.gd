extends SceneTree

## Measures the live Barya objective on the scheduled P12 room with four seats and a crowded
## stage. Synthetic seats and real Godot physics/rendering; not target-PC or human-play evidence.

const ROOM_SCENE := preload("res://scenes/match/p12_scheduled_match_room.tscn")
const OUTPUT_RELATIVE := "../docs/evidence/barya/barya_performance.txt"
const KARERA := EventSchedule.Challenge.KARERA
const KANGAROO := EventSchedule.Challenge.KANGAROO
const WARMUP_FRAMES := 120
const SAMPLE_FRAMES := 300
const FRAME_TARGET_MS := 16.67
const MEMORY_TARGET_MIB := 512.0
const CROWD_VARIANTS: PackedStringArray = [
	"build.hollow_blocks.cell_1x1",
	"build.bamboo_bridge.span_4x1",
	"build.solid_block.slab_3x1",
	"build.wood_box.box_2x2",
]

var room: P12ScheduledMatchRoom
var report := PackedStringArray()
var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	room = ROOM_SCENE.instantiate() as P12ScheduledMatchRoom
	root.add_child(room)
	await process_frame
	await physics_frame
	var seats: Array[int] = [room.join_keyboard("K1"), room.join_keyboard("K2")]
	for device_id in [7101, 7102]:
		var seat := room.input_router.registry.join_gamepad(device_id)
		seats.append(seat)
		room.input_router.seat_joined.emit(seat)
	for seat in seats:
		room.input_router.registry.set_ready(seat, true)
	room.tuning.barya_enabled = true
	room.tuning.barya_offer_probability = 1.0
	room.tuning.match_pugad_seconds = 600.0
	room.tuning.match_target_score_units = 100000
	room.tuning.match_race_hard_cap_seconds = 600.0
	room.tuning.match_race_after_first_finish_seconds = 600.0
	_check(room.start_match(), "four-seat P12 match starts")
	room.schedule.locked[1] = {
		"round": 1,
		"main": KARERA,
		"twist": KANGAROO,
		"guaranteed": false,
		"sudden_death": false,
		"twist_options": 1,
	}
	var pieces := _crowd_stage()
	_check(pieces == 40, "crowded stage places 40 persistent pieces")
	var barya_slot := _barya_slot()
	_check(barya_slot >= 0, "probability-one Karera Pugad offers exactly one Barya")
	if barya_slot >= 0:
		room.selected_egg_by_seat[seats[0]] = barya_slot
		room._queue_claim(seats[0], str(room.egg_pool[barya_slot].egg_id))
		room._flush_claims()
		room._finish_pugad_timeout()
		var valid_cell := _find_valid_cell(seats[0])
		_check(valid_cell.x >= 0, "crowded stage has a valid temporary Barya cell")
		if valid_cell.x >= 0:
			var cursor: Dictionary = room.placement_controller.cursors[seats[0]]
			cursor.cell = valid_cell
			room.placement_controller.cursors[seats[0]] = cursor
			room._confirm_placement(seats[0])
			room._finish_place_timeout()
	var persistent_after_place := room.items.persistent_count()
	var barya_entered_item_manager := false
	for placed_item_variant in room.items.pieces.values():
		var placed_item := placed_item_variant as PlacedItem
		if placed_item != null and BaryaObjectiveDefinition.is_variant(placed_item.variant_key):
			barya_entered_item_manager = true
	var objective_live := (
		room.barya_objective.state == BaryaRoundObjective.State.AVAILABLE
		and room.barya_objective.coin != null
		and persistent_after_place <= room.tuning.item_persistent_cap
		and not barya_entered_item_manager
	)
	print(
		(
			"BARYA_PERF_SETUP state=%s coin=%s persistent=%d cap=%d in_item_manager=%s message=%s"
			% [
				BaryaRoundObjective.State.keys()[room.barya_objective.state],
				str(room.barya_objective.coin != null),
				persistent_after_place,
				room.tuning.item_persistent_cap,
				str(barya_entered_item_manager),
				room.last_message,
			]
		)
	)
	_check(objective_live, "live coin is outside persistent construction capacity")
	if not objective_live:
		await _write_report("SETUP FAILED", pieces, {})
		quit(1)
		return
	var coin := room.barya_objective.coin
	var carrier := room.actors[seats[0]] as ChickenController
	for seat in seats:
		var actor := room.actors[seat] as ChickenController
		actor.set_physics_process(false)
		actor.global_position = (
			coin.global_position + Vector2(0.0 if seat == seats[0] else 320.0 + seat * 70.0, 0.0)
		)
	await physics_frame
	await physics_frame
	room._resolve_round_objective_pickups(Engine.get_physics_frames())
	_check(
		(
			room.barya_objective.state == BaryaRoundObjective.State.CARRIED
			and room.barya_objective.carrier_seat == seats[0]
		),
		"live physics attaches Barya to a player before sampling"
	)
	for seat in seats:
		(room.actors[seat] as ChickenController).set_physics_process(true)
	await physics_frame
	var output_dir := (
		ProjectSettings.globalize_path("res://").path_join("../docs/evidence/barya").simplify_path()
	)
	DirAccess.make_dir_recursive_absolute(output_dir)
	report = PackedStringArray(
		[
			"Barya live-route frame and cleanup sample",
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
				"Display: 1280x720 windowed; v-sync off; %d warm-up then %d sampled frames."
				% [WARMUP_FRAMES, SAMPLE_FRAMES]
			),
			(
				"Route/profile: default P12 scheduled room; test-forced round-1 Karera + Kangaroo; "
				+ (
					"four synthetic seats; profile karera_slice; match seed %d."
					% room.base_match_seed
				)
			),
			(
				(
					"State: one live carried Barya, no more than one coin, %d persistent items after Place. "
					+ "Input is synthetic; overlap uses the live Godot PhysicsServer."
				)
				% persistent_after_place
			),
			(
				(
					"Targets: p95/worst frame <= %.2f ms; static memory <= %.0f MiB; "
					+ "zero orphan nodes after cleanup."
				)
				% [FRAME_TARGET_MS, MEMORY_TARGET_MIB]
			),
		]
	)
	await _sample_frames(WARMUP_FRAMES)
	var metrics := await _sample_frames(SAMPLE_FRAMES)
	var memory_mib := float(Performance.get_monitor(Performance.MEMORY_STATIC)) / 1048576.0
	var objects_before := int(Performance.get_monitor(Performance.OBJECT_COUNT))
	var nodes_before := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var cleanup_start := Time.get_ticks_usec()
	room.barya_objective.cleanup()
	var cleanup_us := Time.get_ticks_usec() - cleanup_start
	await process_frame
	await physics_frame
	var objects_after := int(Performance.get_monitor(Performance.OBJECT_COUNT))
	var nodes_after := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var orphans_after := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	var cleanup_passed := (
		room.barya_objective.state == BaryaRoundObjective.State.REMOVED
		and room.barya_objective.coin == null
		and room.items.persistent_count() == persistent_after_place
		and orphans_after == 0
	)
	var frame_passed := (
		float(metrics.p95) <= FRAME_TARGET_MS and float(metrics.worst) <= FRAME_TARGET_MS
	)
	var memory_passed := memory_mib <= MEMORY_TARGET_MIB
	_check(
		cleanup_passed, "cleanup removes coin without changing persistent pieces or orphaning nodes"
	)
	_check(frame_passed, "sampled frame intervals remain within 16.67 ms")
	_check(memory_passed, "static memory remains within 512 MiB")
	var status := "PASSED" if failures == 0 else "FAILED"
	report.append(
		(
			"Frame median/p95/worst: %.3f / %.3f / %.3f ms — %s."
			% [metrics.median, metrics.p95, metrics.worst, "PASSED" if frame_passed else "FAILED"]
		)
	)
	report.append(
		"Static memory: %.2f MiB — %s." % [memory_mib, "PASSED" if memory_passed else "FAILED"]
	)
	report.append(
		(
			"Objects/nodes before cleanup: %d / %d; after: %d / %d; orphans after: %d."
			% [objects_before, nodes_before, objects_after, nodes_after, orphans_after]
		)
	)
	report.append(
		(
			(
				"Objective cleanup call: %d µs; asynchronous queue_free drained after one "
				+ "process + physics frame; %s."
			)
			% [cleanup_us, "PASSED" if cleanup_passed else "FAILED"]
		)
	)
	await _write_report(status, pieces, metrics)
	room.queue_free()
	await process_frame
	quit(1 if failures > 0 else 0)


func _barya_slot() -> int:
	var result := -1
	for index in room.egg_pool.size():
		if BaryaObjectiveDefinition.is_variant(str(room.egg_pool[index].variant_key)):
			if result >= 0:
				return -1
			result = index
	return result


func _find_valid_cell(seat: int) -> Vector2i:
	for y in range(4, 17):
		for x in range(10, 54):
			var cursor: Dictionary = room.placement_controller.cursors[seat]
			cursor.cell = Vector2i(x, y)
			room.placement_controller.cursors[seat] = cursor
			if bool(room._placement_verdict(seat).get("allowed", false)):
				return Vector2i(x, y)
	return Vector2i(-1, -1)


func _crowd_stage() -> int:
	var count := 0
	var index := 0
	for row in range(3, 17, 2):
		for column in range(1, 62, 2):
			var result := room.items.place(
				CROWD_VARIANTS[index % CROWD_VARIANTS.size()], Vector2i(column, row), 0, 0
			)
			index += 1
			if bool(result.get("allowed", false)):
				count += 1
			if count >= 40:
				return count
	return count


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


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_warning("FAIL " + message)
		return
	print("PASS " + message)


func _write_report(status: String, _pieces: int, _metrics: Dictionary) -> void:
	report.insert(0, "Status: " + status)
	var output_path := (
		ProjectSettings.globalize_path("res://").path_join(OUTPUT_RELATIVE).simplify_path()
	)
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if file != null:
		file.store_string("\n".join(report) + "\n")
		file.close()
	for line in report:
		print(line)

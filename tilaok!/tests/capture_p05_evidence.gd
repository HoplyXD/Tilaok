extends SceneTree

const HARNESS_SCENE := preload("res://scenes/harness/foundation_harness.tscn")
const VARIANT_1X1 := "build.hollow_blocks.cell_1x1"
const VARIANT_2X3 := "build.hollow_blocks.stack_2x3"
const VARIANT_TULAY := "build.bamboo_bridge.span_4x1"
const VARIANT_KEYS := [VARIANT_1X1, VARIANT_2X3, VARIANT_TULAY]
const VARIANT_LABELS := ["Kaing 1x1", "Kaing 2x3", "Tulay 4x1"]
const PAD_DEVICE_IDS := [710, 711]
const SAMPLE_COUNT := 600
const OUTPUT_RELATIVE := "../docs/evidence/p05"
const REJECTION_CASES := [
	{"code": "unknown_variant", "key": "build.unknown.missing", "cell": Vector2i(8, 5), "turns": 0},
	{"code": "variant_disabled", "key": VARIANT_1X1, "cell": Vector2i(8, 5), "turns": 0},
	{"code": "rotation_unsupported", "key": VARIANT_TULAY, "cell": Vector2i(8, 5), "turns": 1},
	{"code": "out_of_bounds", "key": VARIANT_1X1, "cell": Vector2i(32, 5), "turns": 0},
	{"code": "protected_spawn", "key": VARIANT_1X1, "cell": Vector2i(4, 11), "turns": 0},
	{"code": "protected_goal", "key": VARIANT_1X1, "cell": Vector2i(28, 9), "turns": 0},
	{"code": "outside_build_region", "key": VARIANT_1X1, "cell": Vector2i(6, 2), "turns": 0},
	{"code": "immutable_base", "key": VARIANT_1X1, "cell": Vector2i(6, 14), "turns": 0},
	{"code": "player_clearance", "key": VARIANT_1X1, "cell": Vector2i(8, 5), "turns": 0},
	{"code": "item_overlap", "key": VARIANT_1X1, "cell": Vector2i(8, 5), "turns": 0},
	{"code": "persistent_cap", "key": VARIANT_1X1, "cell": Vector2i(8, 5), "turns": 0},
	{"code": "invalid_region", "key": VARIANT_2X3, "cell": Vector2i(8, 5), "turns": 0},
]

var output_dir := ""
var room: P05MatchRoom
var harness: FoundationHarness
var failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	output_dir = ProjectSettings.globalize_path("res://").path_join(OUTPUT_RELATIVE).simplify_path()
	DirAccess.make_dir_recursive_absolute(output_dir)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	harness = HARNESS_SCENE.instantiate() as FoundationHarness
	root.add_child(harness)
	await _wait_frames(30)
	_press_harness_room_button()
	await _wait_frames(4)
	room = harness.active_room as P05MatchRoom
	if room == null:
		push_error("P05 capture could not open match room")
		quit(1)
		return
	room.join_keyboard("K1")
	room.join_keyboard("K2")
	for device_id in PAD_DEVICE_IDS:
		var seat_index := room.input_router.registry.join_gamepad(device_id)
		if seat_index >= 0:
			room.input_router.seat_joined.emit(seat_index)
	for seat in room.input_router.registry.joined_seats():
		room.input_router.registry.set_ready(int(seat.seat), true)
	await _wait_frames(3)
	if not room.start_match():
		push_error("P05 capture could not start match fixture")
		failed = true
	else:
		await _enter_fixture_place()
		await _capture_rejection_reasons()
		await _capture_crowded_stage_and_performance()
		await _write_capture_matrix()
	room.queue_free()
	await _wait_frames(3)
	harness.queue_free()
	await _wait_frames(3)
	quit(1 if failed else 0)


func _enter_fixture_place() -> void:
	# Fixed fixture variants make the capture independent of procedural egg draws.
	for index in range(mini(room.egg_pool.size(), 4)):
		var egg: Dictionary = room.egg_pool[index]
		egg.variant_key = VARIANT_KEYS[index % VARIANT_KEYS.size()]
		room.egg_pool[index] = egg
		room.assignments[index] = str(egg.egg_id)
	room._enter_place()
	for actor_variant in room.actors.values():
		var actor := actor_variant as ChickenController
		actor.global_position = Vector2(640.0, 176.0)
		actor.velocity = Vector2.ZERO
		actor.locomotion_velocity = Vector2.ZERO
		actor.external_velocity = Vector2.ZERO
	room.set_camera_fixture_targets(
		[Rect2(Vector2.ZERO, Vector2(1024.0, 512.0))], BoundedStageCamera.Context.PLACE
	)
	await _wait_frames(8)


func _capture_rejection_reasons() -> void:
	var rows := PackedStringArray(
		["P05 visual rejection matrix (Godot %s)" % Engine.get_version_info().string, ""]
	)
	for case_index in range(REJECTION_CASES.size()):
		var case: Dictionary = REJECTION_CASES[case_index]
		var context := _make_case_context(str(case.code))
		var saved_tuning: GameplayTuning = room.tuning
		var saved_definitions: ItemDefinitions = room.definitions
		var saved_arena: ArenaDefinition = room.arena
		var saved_pieces: Dictionary = room.items.pieces.duplicate()
		var saved_positions: Dictionary = {}
		for seat_index in room.actors:
			saved_positions[seat_index] = (room.actors[seat_index] as Node2D).global_position
		room.tuning = context.tuning
		room.definitions = context.definitions
		room.arena = context.arena
		room.placement_controller.tuning = context.tuning
		room.placement_controller.definitions = context.definitions
		room.items.configure(
			context.tuning,
			context.arena,
			room.support_tracker,
			context.definitions,
			room.world_layer
		)
		room.items.pieces.clear()
		for item in context.existing:
			room.items.pieces[item.instance_id] = item
		room.input_router.tuning = context.tuning
		var cursor: Dictionary = room.placement_controller.cursors[0]
		cursor.variant_key = str(case.key)
		cursor.cell = case.cell
		cursor.quarter_turns = int(case.turns)
		room.placement_controller.cursors[0] = cursor
		if str(case.code) == "player_clearance":
			(room.actors[0] as Node2D).global_position = (
				Vector2(case.cell) * context.tuning.grid_cell_wu
				+ Vector2.ONE * context.tuning.grid_cell_wu * 0.5
			)
		var verdict := room.items.validate_placement(
			str(case.key), case.cell, int(case.turns), room._actor_rects()
		)
		var expected := str(case.code)
		var actual := str(verdict.get("code", "missing"))
		if expected != actual:
			failed = true
			push_error("P05 capture matrix mismatch: expected %s got %s" % [expected, actual])
		cursor = room.placement_controller.cursors[0]
		cursor.compact_label = false
		room.placement_controller.cursors[0] = cursor
		room._refresh_match_ghost(0)
		if actual == "unknown_variant":
			var base_variant := (
				room.definitions.find_variant(VARIANT_1X1).variant as ItemVariantDefinition
			)
			var footprint := ItemPlacementValidator.footprint_rect_for(
				base_variant, case.cell, 0, context.tuning
			)
			(room._ghosts[0] as ItemGhost).show_state(
				footprint,
				[],
				[],
				false,
				str(verdict.get("reason", "No reason returned.")),
				"P1 ● BLOCKED",
				"UNKNOWN VARIANT"
			)
		else:
			(room._ghosts[0] as ItemGhost).compact_label = false
		room._refresh_match_ui()
		await _wait_frames(2)
		var file_name := "%02d_rejection_%s_1920x1080.png" % [case_index + 1, str(case.code)]
		await _save(file_name)
		rows.append("| %s | %s | %s | %s |" % [expected, actual, str(case.cell), file_name])
		rows.append("  | Reason shown | %s |" % str(verdict.get("reason", "")))
		if expected != actual:
			rows.append("  | Result | FAILED |")
		else:
			rows.append("  | Result | PASSED |")
		rows.append("")
		print("P05_REJECTION_CAPTURE expected=%s actual=%s" % [expected, actual])
		room.tuning = saved_tuning
		room.definitions = saved_definitions
		room.arena = saved_arena
		room.placement_controller.tuning = saved_tuning
		room.placement_controller.definitions = saved_definitions
		room.items.pieces = saved_pieces
		room.items.configure(
			saved_tuning, saved_arena, room.support_tracker, saved_definitions, room.world_layer
		)
		room.input_router.tuning = saved_tuning
		for seat_index in saved_positions:
			(room.actors[int(seat_index)] as Node2D).global_position = saved_positions[seat_index]
		cursor = room.placement_controller.cursors[0]
		cursor.variant_key = str(room.egg_pool[0].variant_key)
		cursor.cell = Vector2i(8, 8)
		cursor.quarter_turns = 0
		room.placement_controller.cursors[0] = cursor
		room._refresh_match_ui()
	rows.insert(1, "| Expected code | Actual code | Cell | Capture |\n|---|---|---|---|")
	var matrix_file := FileAccess.open(
		output_dir.path_join("rejection_reason_matrix.md"), FileAccess.WRITE
	)
	matrix_file.store_string("\n".join(rows) + "\n")
	matrix_file.close()


func _make_case_context(code: String) -> Dictionary:
	var case_tuning := room.tuning.duplicate(true) as GameplayTuning
	var case_definitions := ItemDefinitions.load_all(case_tuning)
	var existing: Array[PlacedItem] = []
	var actors: Array[Rect2] = []
	match code:
		"variant_disabled":
			case_tuning.item_enabled_variants = PackedStringArray([VARIANT_2X3, VARIANT_TULAY])
			case_definitions = ItemDefinitions.load_all(case_tuning)
		"player_clearance":
			actors.append(
				Rect2(
					Vector2(8.0, 5.0) * case_tuning.grid_cell_wu,
					Vector2.ONE * case_tuning.grid_cell_wu
				)
			)
		"item_overlap", "persistent_cap":
			var item := _fixture_item(VARIANT_1X1, Vector2i(8, 5), case_tuning)
			existing.append(item)
			if code == "persistent_cap":
				case_tuning.item_persistent_cap = 1
		"invalid_region":
			var families: Array[ItemFamilyDefinition] = []
			for family in case_definitions.families:
				families.append(family.duplicate(true) as ItemFamilyDefinition)
			var stack_family := families[0]
			var stack_variant := stack_family.find_variant("stack_2x3")
			var bad_region := ItemRegionSpec.new()
			bad_region.kind = ItemRegionSpec.Kind.EFFECT
			bad_region.rect_cells = Rect2(Vector2.ZERO, Vector2.ZERO)
			bad_region.declared_bounded = true
			stack_variant.regions.append(bad_region)
			case_definitions = ItemDefinitions.from_families(families, case_tuning)
	return {
		"tuning": case_tuning,
		"definitions": case_definitions,
		"arena": ArenaDefinition.new(case_tuning),
		"existing": existing,
		"actors": actors,
	}


func _capture_crowded_stage_and_performance() -> void:
	room.items.reset_match()
	var total_commits := 0
	for round_index in range(12):
		room.items.enter_place()
		var row := 3 + int(round_index / 2)
		var offset := 0 if round_index % 2 == 0 else 2
		var edits: Array[Dictionary] = [
			{
				"seat_index": 0,
				"variant_key": VARIANT_TULAY,
				"origin_cell": Vector2i(5 + offset * 4, row),
				"quarter_turns": 0,
				"cleanup_targets": []
			},
			{
				"seat_index": 1,
				"variant_key": VARIANT_TULAY,
				"origin_cell": Vector2i(9 + offset * 4, row),
				"quarter_turns": 0,
				"cleanup_targets": []
			},
			{
				"seat_index": 2,
				"variant_key": VARIANT_1X1,
				"origin_cell": Vector2i(22 + offset, row),
				"quarter_turns": 0,
				"cleanup_targets": []
			},
			{
				"seat_index": 3,
				"variant_key": VARIANT_1X1,
				"origin_cell": Vector2i(23 + offset, row),
				"quarter_turns": 0,
				"cleanup_targets": []
			},
		]
		var resolution := AtomicEditResolver.resolve(
			room.definitions,
			room.arena,
			room.tuning,
			room.items.pieces.values(),
			edits,
			room.items.round_number,
			[]
		)
		var committed := room.items.commit_batch(resolution, [])
		if not bool(committed.get("allowed", false)) or committed.commits.size() != 4:
			failed = true
			push_error("P05 crowded-stage round %d failed: %s" % [round_index + 1, str(committed)])
			return
		total_commits += committed.commits.size()
		room.items.begin_play()
		room.items.end_round()
	if total_commits != 48 or room.items.persistent_count() != 48 or room.items.round_number != 12:
		failed = true
		push_error("P05 crowded fixture count mismatch")
		return
	room._enter_play()
	room.last_message = (
		"Post-round-12 fixture • 48 persistent pieces • "
		+ "construction retained across 12 rounds."
	)
	room._feedback_label.text = room.last_message
	for seat_index in range(4):
		var actor := room.actors[seat_index] as ChickenController
		actor.global_position = Vector2(96.0 + seat_index * 192.0, 392.0)
		actor.velocity = Vector2.ZERO
		actor.locomotion_velocity = Vector2.ZERO
		actor.external_velocity = Vector2.ZERO
	room.set_camera_fixture_targets(
		[Rect2(Vector2.ZERO, Vector2(1024.0, 512.0))], BoundedStageCamera.Context.PLAY
	)
	await _wait_frames(30)
	await _save("crowded_post_round12_48_pieces_1920x1080.png")
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	await _wait_frames(10)
	var intervals := PackedFloat64Array()
	var previous := Time.get_ticks_usec()
	for frame_index in range(SAMPLE_COUNT):
		await RenderingServer.frame_post_draw
		var now := Time.get_ticks_usec()
		intervals.append(float(now - previous) / 1000.0)
		previous = now
	var metrics := _summarize(intervals)
	var memory_mib := float(Performance.get_monitor(Performance.MEMORY_STATIC)) / 1048576.0
	var object_count := int(Performance.get_monitor(Performance.OBJECT_COUNT))
	var node_count := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var orphan_count := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	if metrics.p95 > 16.67 or metrics.worst > 16.67 or memory_mib > 512.0 or orphan_count != 0:
		failed = true
	var report := PackedStringArray(
		[
			"Status: %s" % ("PASSED" if not failed else "FAILED"),
			"P05 4-seat / 48-piece performance capture",
			"Date: 2026-10-14 local machine date",
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
			"Display: 1920x1080, windowed; v-sync off during 600 completed rendered-frame samples",
			"Seats: K1/K2 plus synthetic gamepad identities 3/4; no physical gamepads certified",
			"Fixture: 12 construction rounds; 24 Tulay 4x1 and 24 Kaing 1x1 (48 total)",
			(
				"Actual frame intervals: median %.3f ms; p95 %.3f ms; worst %.3f ms"
				% [metrics.median, metrics.p95, metrics.worst]
			),
			"Actual static memory: %.2f MiB" % memory_mib,
			(
				"Actual objects: %d; nodes: %d; orphan nodes: %d"
				% [object_count, node_count, orphan_count]
			),
			(
				"P04 baseline (2026-10-13): median 1.954 ms; p95 3.109 ms; worst 6.059 ms; "
				+ "static memory 70.97 MiB; 2089 objects; 232 nodes; 0 orphan nodes."
			),
			(
				"Cleanup: no cleanup targets in the 12-round stress fixture; the focused suite verified "
				+ "one-time cleanup, 10-round persistence, removal and reset."
			),
			(
				"Targets: p95 and worst < 16.67 ms; static memory < 512 MiB; "
				+ "gameplay traffic 0 B/s (local-only build)."
			),
			"Gameplay traffic: 0 B/s; P05 adds no sockets or network calls.",
			"Automated measurement from capture_p05_evidence.gd. No human review claimed.",
		]
	)
	var report_file := FileAccess.open(
		output_dir.path_join("p05_performance.txt"), FileAccess.WRITE
	)
	report_file.store_string("\n".join(report) + "\n")
	report_file.close()
	print(
		(
			(
				"P05_PERFORMANCE median=%.3fms p95=%.3fms worst=%.3fms "
				+ "memory=%.2fMiB objects=%d nodes=%d orphan_nodes=%d status=%s"
			)
			% [
				metrics.median,
				metrics.p95,
				metrics.worst,
				memory_mib,
				object_count,
				node_count,
				orphan_count,
				"PASSED" if not failed else "FAILED"
			]
		)
	)


func _fixture_item(variant_key: String, cell: Vector2i, tuning: GameplayTuning) -> PlacedItem:
	var item := PlacedItem.new()
	item.instance_id = "p05_capture_fixture"
	item.variant_key = variant_key
	item.origin_cell = cell
	item.footprint_rect = Rect2(
		Vector2(cell) * tuning.grid_cell_wu, Vector2.ONE * tuning.grid_cell_wu
	)
	return item


func _write_capture_matrix() -> void:
	var file := FileAccess.open(output_dir.path_join("capture_manifest.md"), FileAccess.WRITE)
	var lines := PackedStringArray(
		[
			"# P05 evidence capture manifest",
			"",
			"- Rejection reasons: `rejection_reason_matrix.md` and a 1920x1080 PNG per validator reason.",
			"- Crowded stage: `crowded_post_round12_48_pieces_1920x1080.png` after 12 batch-commit rounds.",
			(
				"- Performance: `p05_performance.txt` from 600 rendered frames in the same "
				+ "4-seat, 48-piece room."
			),
			"- Seats 3 and 4 use synthetic gamepads; no physical gamepad result is claimed.",
		]
	)
	file.store_string("\n".join(lines) + "\n")
	file.close()


func _press_harness_room_button() -> void:
	for child in harness.get_node("Layout/HarnessPanel/RoomRow").get_children():
		if child is Button and (child as Button).text == "P05 Match Loop":
			(child as Button).pressed.emit()
			return
	failed = true
	push_error("Could not find P05 harness entry")


func _save(file_name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var error := image.save_png(output_dir.path_join(file_name))
	if error != OK or image.get_size() != Vector2i(1920, 1080):
		failed = true
		push_error("P05 capture failed for %s (%s)" % [file_name, error])
	else:
		print("P05_CAPTURE file=%s size=1920x1080" % file_name)


func _wait_frames(count: int) -> void:
	for _frame in range(count):
		await process_frame


func _summarize(samples: PackedFloat64Array) -> Dictionary:
	var ordered := samples.duplicate()
	ordered.sort()
	var middle := ordered.size() / 2
	var median := (ordered[middle - 1] + ordered[middle]) * 0.5
	var p95_index := clampi(int(ceil(float(ordered.size()) * 0.95)) - 1, 0, ordered.size() - 1)
	return {"median": median, "p95": ordered[p95_index], "worst": ordered[ordered.size() - 1]}

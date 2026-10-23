# gdlint: disable=max-file-lines
extends SceneTree

const ROOM_SCENE := preload("res://scenes/match/p11_kangaroo_room.tscn")
const ATTRIBUTION_SCRIPT := preload("res://scripts/items/runtime/attribution_record.gd")
const KANGAROO_CONTROLLER := preload("res://scripts/match/kangaroo_round_controller.gd")
const OUTPUT_RELATIVE := "../docs/evidence/p11"
const BUILD_VARIANT := "build.hollow_blocks.cell_1x1"

var room: P11KangarooMatchRoom
var output_dir := ""
var checks := 0
var failures := 0
var report := PackedStringArray()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	output_dir = ProjectSettings.globalize_path("res://").path_join(OUTPUT_RELATIVE).simplify_path()
	DirAccess.make_dir_recursive_absolute(output_dir)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	report = PackedStringArray(
		[
			"P11 standalone integration run; all seats, inputs and hazard timestamps are synthetic.",
			"Engine: %s" % Engine.get_version_info().string,
			"Date: %s UTC" % Time.get_datetime_string_from_system(true),
			"Build: P11-independent-kangaroo-dev; current task working tree.",
			"OS: %s / %s" % [OS.get_name(), OS.get_processor_name()],
			"Input: synthetic K1/K2 and synthetic gamepad seat identities; no physical devices.",
			"Profile/seed: kangaroo_contract_lab / 12345 unless a row says otherwise.",
			"Reviewer: engineering integration run; no independent human review recorded.",
		]
	)
	for count in [2, 3, 4]:
		await _test_standalone_count(count)
	await _test_pause_reclaim_and_cleanup()
	await _test_containment_defect_recovery()
	if checks == 0:
		_check(false, "P11 integration runner executed no checks")
	report.append("P11_INTERACTIVE_SUMMARY checks=%d failures=%d" % [checks, failures])
	var log := FileAccess.open(output_dir.path_join("p11_interactive_run.txt"), FileAccess.WRITE)
	if log != null:
		log.store_string("\n".join(report) + "\n")
		log.close()
	print("P11_INTERACTIVE_SUMMARY checks=%d failures=%d" % [checks, failures])
	for line in report:
		print(line)
	await _dispose_room()
	quit(1 if failures > 0 else 0)


func _test_standalone_count(count: int) -> void:
	await _new_room(count)
	_check(room.start_match(), "%d synthetic seats start the standalone route" % count)
	_check(
		room.profile_id == "kangaroo_contract_lab", "room snapshots the Kangaroo contract profile"
	)
	_check(room.race_round_controller == null, "standalone Kangaroo creates no race controller")
	_check(
		room.kangaroo_controller != null, "standalone route owns an independent Kangaroo controller"
	)
	_check(room.tuning.validate().is_empty(), "Kangaroo tuning passes the shared validator")
	_check(room.items != null, "match lifecycle and persistent item manager are present")
	_check(
		room.input_router.registry.joined_seats().size() == count,
		"all %d synthetic seat identities join before Pugad" % count
	)
	room._enter_place()
	var placed := room.items.place(BUILD_VARIANT, Vector2i(20, 9), 0, 0)
	_check(
		bool(placed.get("allowed", false)), "Kangaroo profile permits player-built Rising support"
	)
	var construction_before := room.items.construction_signature()
	_check(
		not construction_before.is_empty(), "placed player construction has a persistent signature"
	)
	room._enter_play()
	await _wait_physics(4)
	await _wait_frames(2)
	_check(
		(
			room.phase_controller.phase == MatchPhaseController.Phase.PLAY
			and room.kangaroo_controller.active
		),
		"Pugad → Place → Play starts independent command evaluation at %d seats" % count
	)
	_check(
		(
			room.goal_area != null
			and not room.goal_area.monitoring
			and room.goal_area.collision_mask == 0
		),
		"Karera goal and race deadline stay inactive in the standalone profile"
	)
	_check(
		not room.has_method("_apply_lagsanay_outcomes"),
		"standalone Kangaroo does not inherit or invoke the Bomb-Taya mode controller"
	)
	_check(
		(
			room.tuning.item_enabled_variants.size() == ItemEnabledProfiles.KANGAROO_VARIANTS.size()
			and room.tuning.item_enabled_variants.has("hazard.rail_trumpo.rail_4x1")
			and room.tuning.item_enabled_variants.has("hazard.slipper_launcher.lane_4x1")
		),
		"profile enables reviewed Trumpo and Tsinelas Launcher variants"
	)
	_check(
		room.kangaroo_controller.command_history.size() >= 1,
		"seeded command scheduler launched a first command"
	)
	_check(
		(
			room._presenter != null
			and not room._presenter.has_method("get_collision_layer")
			and room._presenter.get_child_count() == 0
		),
		"debug presenter remains a visual-only non-colliding layer"
	)
	_check(
		room._command_stack != null and room._command_stack.get_child_count() > 0,
		"distinct command pose, timing and audio-placeholder labels render in the HUD"
	)
	if count == 2:
		var master_bus := AudioServer.get_bus_index("Master")
		var previous_mute := AudioServer.is_bus_mute(master_bus)
		AudioServer.set_bus_mute(master_bus, true)
		var first_panel: Dictionary = room._command_panels.values()[0]
		_check(
			(
				not str(first_panel.pose.text).contains("DEBUG")
				and not str(first_panel.steps.text).contains("DEBUG")
				and not str(first_panel.note.text).contains("DEBUG")
			),
			"muted audio retains clean command and timing instructions without debug labels"
		)
		for mode in [0, 1]:
			room._screen_shake_mode = mode
			room._trigger_shake()
			_check(room._shake_remaining > 0.0, "screen-shake mode %d keeps a visual cue" % mode)
		room._screen_shake_mode = 2
		room._trigger_shake()
		_check(room._shake_remaining == 0.0, "screen-shake Off suppresses camera motion")
		AudioServer.set_bus_mute(master_bus, previous_mute)
	if count == 2:
		await _capture("p11_2p_command_hud_1920x1080.png")
	await _sample_runtime_metrics(count)
	if count == 3:
		var commands := room.kangaroo_controller.active_commands()
		if not commands.is_empty():
			await _finish_with_seeded_direct_traps(int(commands[0].command_id), count)
		_check(
			(
				room.phase_controller.phase == MatchPhaseController.Phase.RESULTS
				and room.last_results_model != null
				and room.last_results_model.award_rows.size() > 0
			),
			"direct-trap survivor resolution commits placement awards into the shared results screen"
		)
		_check(
			room.items.construction_signature() == construction_before,
			"construction persists through the Kangaroo results cleanup"
		)
		room._start_next_round()
		_check(
			(
				room.phase_controller.phase == MatchPhaseController.Phase.PUGAD
				and room.items.construction_signature() == construction_before
			),
			"next Pugad retains the constructed stage and cumulative match lifecycle"
		)
		room._enter_place()
		room._enter_play()
		await _wait_physics(4)
		await _finish_with_simultaneous_command_failures()
		await _wait_frames(2)
		_check(
			(
				room.last_results_model != null
				and room.last_results_model.diagnostic_label.begins_with("Last Cluck!")
			),
			"simultaneous final failures render the Last Cluck winner explanation"
		)
		await _capture("p11_last_cluck_results_1920x1080.png")
	if count == 4:
		room._screen_shake_mode = 2
		room._trigger_shake()
		_check(room._shake_remaining == 0.0, "screen-shake Off suppresses the debug shake")
		room._screen_shake_mode = 1
		room._trigger_shake()
		_check(
			room._shake_remaining > 0.0, "Reduced screen shake preserves its distinct gentle cue"
		)
	_check(
		room.items.construction_signature() == construction_before,
		"active round leaves persistent construction unchanged"
	)
	await _dispose_room()
	_check(not is_instance_valid(room), "standalone room cleanup releases the scene instance")


func _finish_with_seeded_direct_traps(first_command_id: int, count: int) -> void:
	var active: Array[Dictionary] = room.kangaroo_controller.active_commands()
	var command: Dictionary = {}
	for row in active:
		if int(row.command_id) == first_command_id:
			command = row
			break
	if command.is_empty():
		_check(false, "terminal integration fixture found the announced first command")
		return
	var resolution_time := float(command.response_end_at)
	for seat in range(1, count):
		var record := ATTRIBUTION_SCRIPT.new() as AttributionRecord
		record.kind = AttributionRecord.Kind.ELIMINATION
		record.player_seat = seat
		record.owner_seat = 0
		record.source_item_id = "hazard.rail_trumpo"
		record.physics_tick = Engine.get_physics_frames() + 1
		record.physics_time = resolution_time - 0.02
		record.time_comparable = true
		record.round_id = room.kangaroo_controller.round_id
		record.event_id = "p11-integration:%d:%d" % [first_command_id, seat]
		_check(
			room.kangaroo_controller.submit_hazard(record),
			"synthetic direct trap is accepted for seat %d" % seat
		)
	var result := room.kangaroo_controller.advance_to(
		resolution_time, Engine.get_physics_frames() + 1, room.actors, room.support_tracker, []
	)
	room._apply_kangaroo_outcomes(result.new_outcomes)
	if bool(result.get("ended", false)):
		room._finish_kangaroo()
	_check(bool(result.get("ended", false)), "batched hazard outcomes leave one survivor")
	_check(
		(
			room.last_resolution.get("totals_units", {}).has(0)
			and int(room.last_resolution.totals_units[0]) > 0
		),
		"placement resolver awards the surviving player and eligible Patibong credit"
	)


func _finish_with_simultaneous_command_failures() -> void:
	var controller := room.kangaroo_controller
	if controller.command_history.is_empty():
		_check(false, "Last Cluck visual fixture has an announced command")
		return
	var command: Dictionary = controller.command_history[0]
	var response_start := float(command.response_start_at)
	var response_end := float(command.response_end_at)
	controller.advance_to(
		response_start, Engine.get_physics_frames() + 1, room.actors, room.support_tracker, []
	)
	for seat in controller.live_seats:
		controller.marker_counts[seat] = 2
		if int(command.command) == KANGAROO_CONTROLLER.Command.FREEZE:
			controller.record_intent_edge(
				seat, "synthetic:last-cluck:%d" % seat, true, response_start + 0.01
			)
	var hazards_submitted := true
	for seat in controller.live_seats:
		var record := ATTRIBUTION_SCRIPT.new() as AttributionRecord
		record.kind = AttributionRecord.Kind.ELIMINATION
		record.player_seat = seat
		record.owner_seat = -1
		record.source_item_id = "hazard.rail_trumpo"
		record.physics_tick = Engine.get_physics_frames() + 1
		record.physics_time = response_end
		record.time_comparable = true
		record.round_id = controller.round_id
		record.event_id = "p11-last-cluck:%d:%d" % [int(command.command_id), seat]
		hazards_submitted = controller.submit_hazard(record) and hazards_submitted
	var result := controller.advance_to(
		response_end, Engine.get_physics_frames() + 1, room.actors, room.support_tracker, []
	)
	room._apply_kangaroo_outcomes(result.new_outcomes)
	if bool(result.get("ended", false)):
		room._finish_kangaroo()
	_check(hazards_submitted, "Last Cluck tie fixture submits all comparable same-time traps")
	_check(
		bool(result.get("ended", false)) and bool(result.get("last_cluck", false)),
		"same-time terminal command failures resolve together through Last Cluck"
	)


func _test_pause_reclaim_and_cleanup() -> void:
	await _new_room(4)
	_check(room.start_match(), "pause/reclaim room starts")
	room._enter_place()
	room._enter_play()
	await _wait_physics(3)
	var clock_before := room.items.director.simulation_time
	room.input_router._on_joy_connection_changed(800, false)
	_check(
		room.pause_coordinator.state == PauseRecoveryCoordinator.State.PAUSED and paused,
		"assigned synthetic gamepad disconnect pauses the full scene"
	)
	_check(
		room.pause_coordinator.choose_reclaim_seat(2),
		"paused reclaim menu accepts the missing seat"
	)
	_check(room.pause_coordinator.reclaim_device(900), "new synthetic gamepad reclaims that seat")
	for seat in room.input_router.registry.joined_seats():
		room.input_router.registry.set_ready(int(seat.seat), true)
	_check(room.pause_coordinator.request_resume(), "all four seats can enter the resume countdown")
	room.pause_coordinator._process(room.pause_coordinator.countdown_remaining)
	_check(not paused, "reclaim resume countdown restores the full simulation")
	_check(
		is_equal_approx(room.items.director.simulation_time, clock_before),
		"pause and reclaim hold the Kangaroo active-simulation clock"
	)
	var old_room := room
	await _dispose_room()
	_check(not is_instance_valid(old_room), "pause/reclaim room tears down its command scheduler")
	_check(not paused, "room teardown leaves the project unpaused")


func _test_containment_defect_recovery() -> void:
	await _new_room(2)
	_check(room.start_match(), "containment-defect recovery room starts")
	room._enter_place()
	room._enter_play()
	var scores_before: Dictionary = room.cumulative_score_units.duplicate(true)
	room._on_actor_escaped(0)
	_check(
		(
			room._defect_paused
			and paused
			and room._defect_panel.visible
			and room._restart_attempt_button.visible
			and room._kangaroo_overlay.layer > room.presenter.layer
		),
		"containment defect exposes restart controls above the shared pause screen"
	)
	room._restart_attempt_button.pressed.emit()
	_check(
		(
			not room._defect_paused
			and not paused
			and room.kangaroo_controller.active
			and room.cumulative_score_units == scores_before
		),
		"defect restart restores Play from its score snapshot without creating an award"
	)
	var old_room := room
	await _dispose_room()
	_check(not is_instance_valid(old_room), "recovered defect room tears down cleanly")


func _sample_runtime_metrics(seat_count: int) -> void:
	var process_ms := PackedFloat64Array()
	var physics_ms := PackedFloat64Array()
	var static_bytes := PackedInt64Array()
	for _sample in range(120):
		await physics_frame
		process_ms.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
		physics_ms.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0)
		static_bytes.append(int(Performance.get_monitor(Performance.MEMORY_STATIC)))
	process_ms.sort()
	physics_ms.sort()
	static_bytes.sort()
	var last := process_ms.size() - 1
	var p95 := mini(last, floori(float(process_ms.size()) * 0.95))
	var physics_p95 := mini(last, floori(float(physics_ms.size()) * 0.95))
	var row := (
		(
			"P11_SYNTHETIC_DEBUG_METRICS seats=%d samples=%d process_ms[p50=%.3f,p95=%.3f,max=%.3f] "
			+ "physics_ms[p95=%.3f,max=%.3f] static_memory_mib[min=%.1f,max=%.1f]"
		)
		% [
			seat_count,
			process_ms.size(),
			process_ms[floori(float(process_ms.size()) * 0.50)],
			process_ms[p95],
			process_ms[last],
			physics_ms[physics_p95],
			physics_ms[last],
			float(static_bytes[0]) / 1048576.0,
			float(static_bytes[static_bytes.size() - 1]) / 1048576.0,
		]
	)
	report.append(row)
	print(row)


func _new_room(seat_count: int) -> void:
	await _dispose_room()
	room = ROOM_SCENE.instantiate() as P11KangarooMatchRoom
	room.set_match_seed(12345 + seat_count)
	root.add_child(room)
	await _wait_frames(4)
	room.join_keyboard("K1")
	room.join_keyboard("K2")
	for device_id in range(800, 800 + maxi(0, seat_count - 2)):
		var seat := room.input_router.registry.join_gamepad(device_id)
		if seat >= 0:
			room.input_router.seat_joined.emit(seat)
	for seat in room.input_router.registry.joined_seats():
		room.input_router.registry.set_ready(int(seat.seat), true)


func _wait_physics(frames: int) -> void:
	for _frame in range(frames):
		await physics_frame


func _wait_frames(frames: int) -> void:
	for _frame in range(frames):
		await process_frame


func _capture(file_name: String) -> void:
	await process_frame
	if DisplayServer.get_name() == "headless":
		_write(
			(
				"COULD-NOT-RUN rendered capture %s: headless renderer is not a rendered presentation check"
				% file_name
			)
		)
		return
	var texture := get_root().get_texture()
	if texture == null:
		_write("COULD-NOT-RUN rendered capture %s: root viewport texture unavailable" % file_name)
		return
	var image := texture.get_image()
	if image == null:
		_write("COULD-NOT-RUN rendered capture %s: root viewport image unavailable" % file_name)
		return
	var path := output_dir.path_join(file_name)
	var error := image.save_png(path)
	_check(
		error == OK,
		"rendered screenshot saved: %s (%dx%d)" % [file_name, image.get_width(), image.get_height()]
	)


func _write(row: String) -> void:
	report.append(row)


func _dispose_room() -> void:
	if room != null and is_instance_valid(room):
		if paused:
			paused = false
		room.queue_free()
		await process_frame
	room = null


func _check(condition: bool, label: String) -> void:
	checks += 1
	if condition:
		print("PASS ", label)
		report.append("PASSED — " + label)
	else:
		failures += 1
		push_error("FAIL " + label)
		report.append("FAILED — " + label)

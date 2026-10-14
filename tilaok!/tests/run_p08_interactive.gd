# gdlint: disable=max-file-lines
extends SceneTree

const ROOM_SCENE := preload("res://scenes/match/p08_lagsanay_room.tscn")
const OUTPUT_RELATIVE := "../docs/evidence/p08"
const TRUMPO := "hazard.rail_trumpo.rail_4x1"
const LAUNCHER := "hazard.slipper_launcher.lane_4x1"

var room: P08LagsanayMatchRoom
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
			"P08 interactive engineering run; all player input and positioning are synthetic.",
			"Engine: %s" % Engine.get_version_info().string,
			"Date: %s UTC" % Time.get_datetime_string_from_system(true),
			"Build: P08-independent-lagsanay-dev; source baseline 160a0b4 plus task-local P08 changes.",
			"OS: %s / %s" % [OS.get_name(), OS.get_processor_name()],
			"Input: synthetic K1/K2 and synthetic gamepad seat identities; no physical devices.",
			"Profile/seed: lagsanay_lab / 12345 unless a test row says otherwise.",
			"Reviewer: Codex engineering run; no independent human review recorded.",
		]
	)
	await _test_real_contact_matrix()
	await _test_trumpo_sink()
	await _test_launcher_sink()
	await _test_expiry_results()
	await _test_last_cluck_results()
	await _test_pause_and_cleanup()
	if checks == 0:
		_check(false, "interactive P08 runner executed no checks")
	report.append("P08_INTERACTIVE_SUMMARY checks=%d failures=%d" % [checks, failures])
	var log := FileAccess.open(output_dir.path_join("p08_interactive_run.txt"), FileAccess.WRITE)
	if log != null:
		log.store_string("\n".join(report) + "\n")
		log.close()
	print("P08_INTERACTIVE_SUMMARY checks=%d failures=%d" % [checks, failures])
	for line in report:
		print(line)
	await _dispose_room()
	quit(1 if failures > 0 else 0)


func _test_real_contact_matrix() -> void:
	for count in [2, 3, 4]:
		await _new_room(int(count), 3.0)
		_check(
			room.start_match(), "%d synthetic seats start the development Lagsanay profile" % count
		)
		_check(room.profile_id == "lagsanay_lab", "standalone room snapshots lagsanay_lab")
		_check(
			room.race_round_controller == null,
			"Lagsanay does not instantiate a Karera round controller"
		)
		_check(
			room.definitions.errors.is_empty(), "Lagsanay compatible content definitions validate"
		)
		room._enter_place()
		var opening_hazard := room.items.place(TRUMPO, Vector2i(14, 8), 0, 0)
		_check(
			bool(opening_hazard.get("allowed", false)),
			"mode-compatible Trumpo places before the opening immunity check"
		)
		room._enter_play()
		await _wait_physics(1)
		_write(
			(
				(
					"CONTACT_START_%dP phase=%d active=%s ended=%s taya=%d head=%.6f "
					+ "timer=%.6f seats=%s statuses=%s sim=%.6f"
				)
				% [
					count,
					room.phase_controller.phase,
					room.lagsanay_controller.active,
					room.lagsanay_controller.ended,
					room.lagsanay_controller.taya_seat,
					room.lagsanay_controller.head_start_remaining,
					room.lagsanay_controller.countdown_remaining,
					str(room.lagsanay_controller.seat_indices),
					_actor_statuses(),
					room.lagsanay_controller.simulation_clock
				]
			)
		)
		var spawn_actor := room.actors[0] as ChickenController
		_write(
			(
				"CONTACT_FLOOR_%dP mask=%d position=%s test_down=%s on_floor=%s floor_node=%s floor_pos=%s"
				% [
					count,
					spawn_actor.collision_mask,
					str(spawn_actor.global_position),
					spawn_actor.test_move(spawn_actor.global_transform, Vector2(0, 1)),
					spawn_actor.is_on_floor(),
					str(room.world_layer.get_node_or_null("arena.floor")),
					str(
						(
							(
								(room.world_layer.get_node_or_null("arena.floor") as StaticBody2D)
								. global_position
							)
							if room.world_layer.get_node_or_null("arena.floor") != null
							else Vector2.INF
						)
					)
				]
			)
		)
		_check(
			room.lagsanay_controller.active,
			"%d-seat Pugad → Place → Lagsanay enters the independent round" % count
		)
		_check(
			not room.goal_area.monitoring and room.goal_area.collision_mask == 0,
			"Karera goal trigger is disabled while protected clearance remains"
		)
		var opening_taya := room.lagsanay_controller.taya_seat
		var opening_actor := room.actors[opening_taya] as ChickenController
		_check(
			opening_actor.lifecycle.status == PlayerLifecycleState.Status.OPENING_FREEZE,
			"opening taya is visibly lifecycle-frozen and hazard-ineligible"
		)
		var hazard_context := ItemStepContext.new()
		_check(
			not hazard_context.is_hazard_target(opening_actor),
			"runtime hazards exclude the opening-frozen taya"
		)
		opening_actor.set_captured(true, "opening_immunity_fixture")
		_check(
			opening_actor.lifecycle.status == PlayerLifecycleState.Status.OPENING_FREEZE,
			"capture cannot change the opening-frozen taya lifecycle"
		)
		if count == 2:
			await _capture("01_opening_head_start_1920x1080.png")
		for seat in room.lagsanay_controller.seat_indices:
			if seat == opening_taya:
				continue
			var actor := room.actors[seat] as ChickenController
			actor.global_position = (
				(room.actors[opening_taya] as ChickenController).global_position
				+ Vector2(900.0 + float(seat) * 12.0, 0.0)
			)
		opening_actor.global_position = Vector2(14.0 * 64.0 + 128.0, 8.0 * 64.0 + 32.0)
		await _wait_physics(
			(
				int(
					ceil(
						(
							room.tuning.lagsanay_opening_head_start_seconds
							* Engine.physics_ticks_per_second
						)
					)
				)
				+ 2
			)
		)
		_write(
			(
				(
					"CONTACT_OPEN_END_%dP phase=%d active=%s ended=%s taya=%d head=%.6f "
					+ "timer=%.6f outcomes=%s statuses=%s"
				)
				% [
					count,
					room.phase_controller.phase,
					room.lagsanay_controller.active,
					room.lagsanay_controller.ended,
					room.lagsanay_controller.taya_seat,
					room.lagsanay_controller.head_start_remaining,
					room.lagsanay_controller.countdown_remaining,
					str(room.lagsanay_controller.outcomes_by_seat),
					_actor_statuses()
				]
			)
		)
		_check(
			room.lagsanay_controller.taya_seat == opening_taya,
			"opening has no pass to or from frozen taya"
		)
		_check(
			room.lagsanay_controller.head_start_remaining <= 0.0,
			"configured head start expires on active simulation time"
		)
		_check(
			not room.lagsanay_controller.outcomes_by_seat.has(opening_taya),
			"actual Trumpo sweeps cannot eliminate the opening taya"
		)
		opening_actor.global_position = Vector2(192.0, 900.0)
		await _wait_physics(1)
		for seat in room.lagsanay_controller.seat_indices:
			if seat == opening_taya:
				continue
			var candidate := room.actors[seat] as ChickenController
			var offset := -24.0 if seat < opening_taya else 24.0
			if count >= 3 and seat == 0:
				candidate.set_captured(true, "tagging_contract_fixture")
			candidate.global_position = opening_actor.global_position + Vector2(offset, 0.0)
		var countdown_before := room.lagsanay_controller.countdown_remaining
		await _wait_until_taya_changes(opening_taya, 10)
		var receiver := room.lagsanay_controller.taya_seat
		_check(
			receiver != opening_taya,
			"real physics sensor overlap passes the taya at %d players" % count
		)
		_check(
			(
				room.lagsanay_controller.countdown_remaining < countdown_before
				and (
					room.lagsanay_controller.countdown_remaining
					<= room.lagsanay_controller.countdown_seconds
				)
			),
			"real pass does not reset or extend the countdown"
		)
		if count == 2:
			await _wait_physics(1)
			await _wait_frames(2)
			var hud_notice := str(room.presenter.play_hud.get_node("%NoticeToast").text_value())
			var debug_text: String = room.presenter.debug_overlay.feedback_text()
			_check(
				(
					hud_notice.contains("Pass-back immunity")
					and debug_text.contains("Pass-back immunity")
					and debug_text.contains("other contacts stay live")
				),
				"HUD names pass-back immunity and the DEBUG overlay explains other live receivers"
			)
		if count >= 3:
			_check(
				room.lagsanay_controller.taya_seat == 0,
				"captured participants remain eligible for tag passing"
			)
		if count == 2:
			await _capture("02_passed_taya_1920x1080.png")
			var previous := opening_taya
			await _wait_physics(10)
			_check(
				room.lagsanay_controller.taya_seat != previous,
				"pass-back immunity leaves other eligible receiver contacts usable"
			)
		if count == 4:
			var sensor := opening_actor.get_node("ContactSensor") as ChickenContactSensor
			var freed_probe := Node2D.new()
			freed_probe.add_to_group("chickens")
			room.world_layer.add_child(freed_probe)
			sensor._track_enter(freed_probe)
			freed_probe.queue_free()
			await process_frame
			_check(
				sensor.overlaps().all(func(node: Node2D) -> bool: return is_instance_valid(node)),
				"freed participants are pruned from cached sensor overlaps"
			)
		await _write(
			(
				"CONTACT_%dP seed=%d opening=%d pass_to=%d timer_before=%.6f timer_after=%.6f"
				% [
					count,
					room.match_seed,
					opening_taya,
					receiver,
					countdown_before,
					room.lagsanay_controller.countdown_remaining
				]
			)
		)
		await _dispose_room()


func _test_trumpo_sink() -> void:
	await _new_room(3, 0.1)
	room.tuning.item_trumpo_speed_wu_s = 2400.0
	_check(room.start_match(), "Trumpo integration room starts")
	room._enter_place()
	var placed := room.items.place(TRUMPO, Vector2i(14, 8), 0, 0)
	_check(bool(placed.get("allowed", false)), "mode-compatible Trumpo rail places in Lagsanay")
	room._enter_play()
	var victim := _first_non_taya_excluding(0)
	var target := room.actors[victim] as ChickenController
	target.global_position = Vector2(14.0 * 64.0 + 128.0, 8.0 * 64.0 + 32.0)
	for _frame in range(180):
		target.global_position = Vector2(14.0 * 64.0 + 128.0, 8.0 * 64.0 + 32.0)
		await physics_frame
		if room.lagsanay_controller.outcomes_by_seat.has(victim):
			break
	var outcome: Dictionary = room.lagsanay_controller.outcomes_by_seat.get(victim, {})
	var records := room.items.director.records
	var direct_record: AttributionRecord
	for record in records:
		if record.kind == AttributionRecord.Kind.ELIMINATION and record.player_seat == victim:
			direct_record = record
	_check(
		str(outcome.get("cause", "")) == "direct_hazard",
		"actual Trumpo contact reaches the Lagsanay elimination sink"
	)
	_check(
		int(outcome.get("direct_owner_seat", -1)) == 0, "actual Trumpo contact credits its placer"
	)
	_check(
		direct_record != null and direct_record.time_comparable,
		"Trumpo attribution carries a comparable round-relative contact time"
	)
	_check(
		direct_record != null and direct_record.round_id == room.lagsanay_controller.round_id,
		"Trumpo record is stamped with the current mode round identity"
	)
	await _capture("03_trumpo_direct_contact_1920x1080.png")
	await _write(
		(
			"TRUMPO mode=lagsanay profile=lagsanay_lab seed=%d victim=%d owner=%d record=%s"
			% [
				room.match_seed,
				victim,
				int(outcome.get("direct_owner_seat", -1)),
				direct_record.summary() if direct_record != null else "missing"
			]
		)
	)
	await _dispose_room()


func _test_launcher_sink() -> void:
	await _new_room(3, 0.1)
	room.tuning.item_activation_grace_s = 0.0
	room.tuning.item_launcher_initial_delay_s = 0.05
	room.tuning.item_launcher_telegraph_s = 0.05
	room.tuning.item_launcher_projectile_speed_wu_s = 2400.0
	_check(room.start_match(), "projectile integration room starts")
	room._enter_place()
	var placed := room.items.place(LAUNCHER, Vector2i(8, 8), 0, 0)
	_check(
		bool(placed.get("allowed", false)), "mode-compatible Tsinelas Launcher places in Lagsanay"
	)
	room._enter_play()
	var victim := _first_non_taya_excluding(0)
	var target := room.actors[victim] as ChickenController
	target.global_position = Vector2(10.0 * 64.0 + 32.0, 8.0 * 64.0 + 32.0)
	for _frame in range(180):
		target.global_position = Vector2(10.0 * 64.0 + 32.0, 8.0 * 64.0 + 32.0)
		await physics_frame
		if room.lagsanay_controller.outcomes_by_seat.has(victim):
			break
	var outcome: Dictionary = room.lagsanay_controller.outcomes_by_seat.get(victim, {})
	_check(
		str(outcome.get("cause", "")) == "direct_hazard",
		"actual Tsinelas projectile contact reaches the Lagsanay elimination sink"
	)
	_check(
		int(outcome.get("direct_owner_seat", -1)) == 0,
		"projectile owner identity survives the mode-specific adapter"
	)
	var launcher_record_found := false
	for record in room.items.director.records:
		if (
			record.player_seat == victim
			and record.source_item_id == str(placed.get("instance_id", ""))
		):
			launcher_record_found = true
	_check(launcher_record_found, "projectile record retains its source item identity")
	await _capture("04_projectile_direct_contact_1920x1080.png")
	await _write(
		(
			"LAUNCHER mode=lagsanay profile=lagsanay_lab seed=%d victim=%d owner=%d source=%s"
			% [
				room.match_seed,
				victim,
				int(outcome.get("direct_owner_seat", -1)),
				str(outcome.get("source_item_id", ""))
			]
		)
	)
	await _dispose_room()


func _test_expiry_results() -> void:
	await _new_room(2, 0.1)
	_check(room.start_match(), "expiry-results room starts")
	room._enter_place()
	room._enter_play()
	await _wait_physics(10)
	room.lagsanay_controller.countdown_remaining = 0.03
	var taya := room.lagsanay_controller.taya_seat
	for _frame in range(10):
		await physics_frame
		if room.phase_controller.phase == MatchPhaseController.Phase.RESULTS:
			break
	_check(
		room.phase_controller.phase == MatchPhaseController.Phase.RESULTS,
		"taya expiry ends the 2-player round with one survivor"
	)
	_check(
		(
			room.last_results_model != null
			and room.last_results_model.diagnostic_label.contains("last chicken standing")
		),
		"ordinary results explain the last survivor"
	)
	_check(
		room.last_results_model != null and room.last_results_model.per_seat_outcomes.size() == 2,
		"ordinary result presents both participant outcomes"
	)
	_check(
		int(room.last_results_model.totals[1 - taya].delta_units) == 8,
		"ordinary winner receives exactly one first-place placement award"
	)
	await _capture("05_expiry_ordinary_winner_1920x1080.png")
	await _dispose_room()


func _test_last_cluck_results() -> void:
	await _new_room(3, 0.1)
	_check(room.start_match(), "Last Cluck presentation room starts")
	room._enter_place()
	room._enter_play()
	await _wait_physics(10)
	var controller := room.lagsanay_controller
	# SceneTree.physics_frame resumes before room physics callbacks in this integration runner.
	# The current counter is the record tick consumed by the next room step.
	var tick := Engine.get_physics_frames()
	var frame_delta := 1.0 / Engine.physics_ticks_per_second
	_write(
		(
			"LAST_CLUCK_FIXTURE tick=%d current=%d clock=%.6f delta=%.6f pending_before=%d"
			% [
				tick,
				Engine.get_physics_frames(),
				controller.simulation_clock,
				frame_delta,
				controller.pending_hazards.size()
			]
		)
	)
	for index in range(controller.seat_indices.size()):
		var seat: int = controller.seat_indices[index]
		var record := AttributionRecord.new()
		record.player_seat = seat
		record.source_item_id = "supplied_last_cluck_fixture"
		record.physics_tick = tick
		record.physics_time = (
			controller.simulation_clock + frame_delta * (0.05 + float(index) * 0.3)
		)
		record.time_comparable = true
		record.round_id = controller.round_id
		record.event_id = "%s:fixture:%d" % [controller.round_id, seat]
		_check(
			controller.submit_hazard(record), "supplied timestamped final-step record is accepted"
		)
	await physics_frame
	_write(
		(
			"LAST_CLUCK_AFTER tick=%d phase=%d active=%s ended=%s clock=%.6f pending=%d outcomes=%s"
			% [
				Engine.get_physics_frames(),
				room.phase_controller.phase,
				controller.active,
				controller.ended,
				controller.simulation_clock,
				controller.pending_hazards.size(),
				str(controller.outcomes_by_seat)
			]
		)
	)
	_check(
		room.phase_controller.phase == MatchPhaseController.Phase.RESULTS,
		"all-final-batch eliminations produce Last Cluck results"
	)
	_check(
		(
			room.last_results_model != null
			and room.last_results_model.last_cluck_explanation.contains(
				"latest recorded elimination time"
			)
		),
		"Last Cluck explanation names the actual tie rule"
	)
	var winner := int(room.last_resolution.get("last_cluck_seat", -1))
	_check(
		winner == controller.seat_indices.back(),
		"latest supplied final-step time wins this presentation fixture"
	)
	await process_frame
	await _capture("06_last_cluck_explained_results_1920x1080.png")
	await _write(
		(
			(
				"LAST_CLUCK presentation=PASSED supplied_timestamp_fixture=true winner=%d "
				+ "explanation=%s; authoritative precision remains limited to engine/integration records."
			)
			% [winner, room.last_results_model.last_cluck_explanation]
		)
	)
	await _dispose_room()


func _test_pause_and_cleanup() -> void:
	await _new_room(2, 3.0)
	_check(room.start_match(), "pause and cleanup room starts")
	room._enter_place()
	room._enter_play()
	await _wait_physics(3)
	var clock_before := room.lagsanay_controller.simulation_clock
	var head_start_before := room.lagsanay_controller.head_start_remaining
	room.pause_coordinator.resume_countdown_seconds = 3.0
	room._toggle_pause()
	for seat in room.lagsanay_controller.seat_indices:
		room.input_router.registry.set_ready(seat, true)
	_check(
		room.pause_coordinator.request_resume(), "resume countdown starts with participants ready"
	)
	await _wait_frames(2)
	_check(
		is_equal_approx(room.lagsanay_controller.simulation_clock, clock_before),
		"pause/resume countdown freezes the active-simulation clock"
	)
	_check(
		is_equal_approx(room.lagsanay_controller.head_start_remaining, head_start_before),
		"pause/resume countdown freezes the opening head-start clock"
	)
	_check(paused, "simulation remains paused throughout resume countdown")
	room.pause_coordinator._process(room.pause_coordinator.countdown_remaining)
	_check(not paused, "participant resume countdown completes and restores simulation")
	var sensor := (
		(room.actors[0] as ChickenController).get_node("ContactSensor") as ChickenContactSensor
	)
	_check(
		sensor.overlaps().all(func(node: Node2D) -> bool: return is_instance_valid(node)),
		"live sensor contains only valid overlap references"
	)
	var old_room := room
	await _dispose_room()
	_check(not is_instance_valid(old_room), "room teardown disconnects and releases P08 state")


func _new_room(seat_count: int, head_start_seconds: float) -> void:
	await _dispose_room()
	room = ROOM_SCENE.instantiate() as P08LagsanayMatchRoom
	room.debug_overlay_default = true
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
	room.tuning.lagsanay_opening_head_start_seconds = head_start_seconds


func _first_non_taya() -> int:
	for seat in room.lagsanay_controller.seat_indices:
		if seat != room.lagsanay_controller.opening_taya_seat:
			return seat
	return -1


func _first_non_taya_excluding(excluded_seat: int) -> int:
	for seat in room.lagsanay_controller.seat_indices:
		if seat != room.lagsanay_controller.opening_taya_seat and seat != excluded_seat:
			return seat
	return -1


func _wait_until_taya_changes(old_taya: int, frames: int) -> void:
	for _frame in range(frames):
		await physics_frame
		if room.lagsanay_controller.taya_seat != old_taya:
			return


func _wait_physics(frames: int) -> void:
	for _frame in range(frames):
		await physics_frame


func _wait_frames(frames: int) -> void:
	for _frame in range(frames):
		await process_frame


func _capture(file_name: String) -> void:
	await process_frame
	var texture := get_root().get_texture()
	if texture == null:
		_write(
			"COULD-NOT-RUN capture %s: headless renderer provides no viewport texture" % file_name
		)
		return
	var image := texture.get_image()
	if image == null:
		_write(
			(
				"COULD-NOT-RUN capture %s: headless renderer provides no readable viewport image"
				% file_name
			)
		)
		return
	var path := output_dir.path_join(file_name)
	var error := image.save_png(path)
	_check(
		error == OK,
		"capture written: %s (%dx%d)" % [file_name, image.get_width(), image.get_height()]
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


func _actor_statuses() -> String:
	var values: Dictionary = {}
	if room == null:
		return "{}"
	for seat in room.actors:
		var actor := room.actors[seat] as ChickenController
		values[int(seat)] = {
			"status": actor.lifecycle.status,
			"position": actor.global_position,
			"escaped": actor.containment_outcome_reported,
		}
	return str(values)

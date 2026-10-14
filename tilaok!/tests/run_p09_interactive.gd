# gdlint: disable=max-file-lines
extends SceneTree

const ROOM_SCENE := preload("res://scenes/match/p09_match_lifecycle_room.tscn")
const ATTRIBUTION := preload("res://scripts/items/runtime/attribution_record.gd")
const EXPECTED_VARIANTS: PackedStringArray = [
	"build.hollow_blocks.cell_1x1",
	"build.hollow_blocks.stack_2x3",
	"build.bamboo_bridge.span_4x1",
]
const OUTPUT_RELATIVE := "../docs/evidence/p09"

var room: P09MatchLifecycleRoom
var output_dir := ""
var checks := 0
var failures: Array[String] = []
var report := PackedStringArray()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	output_dir = ProjectSettings.globalize_path("res://").path_join(OUTPUT_RELATIVE).simplify_path()
	DirAccess.make_dir_recursive_absolute(output_dir)
	if not DisplayServer.get_name() == "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(Vector2i(1920, 1080))
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	report = PackedStringArray(
		[
			"P09 interactive engineering run; seat inputs and race outcome candidates are synthetic.",
			"Engine: %s" % Engine.get_version_info().string,
			"Date: %s UTC" % Time.get_datetime_string_from_system(true),
			"Build: P09-match-lifecycle-dev; route is development-only.",
			"OS/CPU: %s / %s" % [OS.get_name(), OS.get_processor_name()],
			"Devices: synthetic keyboard seats K1/K2 and synthetic gamepad IDs 7101/7102.",
			(
				"Fixtures: 0.002 s Karera cap, generated race ledger candidates, 0.001 s head start "
				+ "and 60 s taya timers."
			),
			"Reviewer: Codex engineering run; no independent human review recorded.",
		]
	)
	await _open_room()
	await _test_threshold_and_replay()
	await _test_all_finish_round_limit()
	await _test_noncontiguous_subset_and_lobby()
	await _dispose_room()
	report.append("P09_INTERACTIVE_SUMMARY checks=%d failures=%d" % [checks, failures.size()])
	var log := FileAccess.open(output_dir.path_join("p09_interactive_run.txt"), FileAccess.WRITE)
	if log != null:
		log.store_string("\n".join(report) + "\n")
		log.close()
	print("P09_INTERACTIVE_SUMMARY checks=%d failures=%d" % [checks, failures.size()])
	for line in report:
		print(line)
	quit(1 if not failures.is_empty() else 0)


func _open_room() -> void:
	room = ROOM_SCENE.instantiate() as P09MatchLifecycleRoom
	root.add_child(room)
	await process_frame
	await physics_frame
	_check(room != null and room.P09_BUILD_ID == "P09-match-lifecycle-dev", "P09 route opens")
	_check(room.profile_id == "karera_slice", "P09 keeps the P07 development profile")
	_check(
		room.tuning.item_enabled_variants == EXPECTED_VARIANTS,
		"P09 keeps exactly the three P07 variants"
	)
	_check(room.match_run_id == 0, "new P09 route has no prior match identity")
	var seats := _join_four_synthetic_seats()
	_check(seats == [0, 1, 2, 3], "four synthetic seats keep stable original slots")
	for seat_index in seats:
		room.input_router.registry.set_ready(seat_index, true)
	_check(room.start_match(), "four connected synthetic seats start a P09 match")
	_check(
		room.match_run_id == 1 and room.match_snapshot.run_id == 1,
		"first match snapshots identity 1"
	)
	_check(
		room.match_snapshot.seed_value == room.match_seed,
		"snapshot stores the deterministic first seed"
	)
	_check(
		room.match_seed == room._derive_match_seed(room.base_match_seed, 1),
		"first seed derives from base seed and identity"
	)
	room.tuning.match_race_hard_cap_seconds = 0.002
	room.tuning.match_race_after_first_finish_seconds = 0.002
	room.tuning.match_results_advance_seconds = 600.0
	await _enter_play()


func _join_four_synthetic_seats() -> Array[int]:
	var seats: Array[int] = [room.join_keyboard("K1"), room.join_keyboard("K2")]
	for device_id in [7101, 7102]:
		var seat_index := room.input_router.registry.join_gamepad(device_id)
		seats.append(seat_index)
		if seat_index >= 0:
			room.input_router.seat_joined.emit(seat_index)
	return seats


func _test_threshold_and_replay() -> void:
	var previous_seed := room.match_seed
	for active_round in range(1, 7):
		if active_round > 1:
			room._start_next_round()
			await process_frame
			await _enter_play()
		await _finish_race_round([0])
		if active_round < 6:
			_check(
				room.phase_controller.phase == MatchPhaseController.Phase.RESULTS,
				"synthetic award round %d continues before the score target" % active_round
			)
		else:
			_check(
				(
					room.final_results_visible
					and room.final_winner_seat == 0
					and int(room.final_scores_units[0]) == 84
				),
				"six authoritative score commits cross the 80-unit target and end the match"
			)
			_check(
				room.items.round_number == 6, "threshold ends after round 6 without an extra round"
			)
			_check(
				(
					room.last_results_model.match_complete
					and room.last_results_model.per_seat_outcomes.size() == 4
				),
				"the live final view model contains all original participant rows"
			)
			_check(
				not bool(room._result_screen.get_node("Safe/Content/Tag").visible),
				"live final results hide the SAMPLE gallery placeholder tag"
			)
			_check(
				(
					(
						room
						. last_results_model
						. per_seat_outcomes
						. filter(func(row: Dictionary) -> bool: return str(row.outcome) == "WINNER")
						. size()
					)
					== 1
				),
				"live results identify exactly one winner"
			)
			await _capture("01_score_target_final_results_1920x1080.png")
			await _test_final_readiness_invalidation_and_quit()
	_check(
		room.final_scores_units[1] == 0 and room.final_scores_units[2] == 0,
		"nonwinners retain exact zero totals"
	)
	var first_roster := room.input_router.registry.joined_seats()
	var original_devices := {
		2: int(first_roster[2].device_id),
		3: int(first_roster[3].device_id),
	}
	for seat_index in [0, 1, 2, 3]:
		room._on_match_action_pressed(seat_index, "confirm")
	if room.match_run_id == 1:
		_check(false, "all original participants freshly ready the selected Replay action")
	else:
		_check(room.match_run_id == 2, "unanimous Replay starts a fresh match identity")
		_check(room.match_seed != previous_seed, "Replay derives a new seed from the next identity")
		_check(room.match_snapshot.run_id == 2, "Replay creates a fresh configuration snapshot")
		_check(room.items.persistent_count() == 0, "Replay clears construction")
		_check(
			room.cumulative_score_units.values().all(func(units: int) -> bool: return units == 0),
			"Replay resets all match totals"
		)
		_check(
			room.phase_controller.phase == MatchPhaseController.Phase.PUGAD,
			"Replay enters Pugad in the same room"
		)
		var replay_roster := room.input_router.registry.joined_seats()
		_check(
			(
				int(replay_roster[2].device_id) == original_devices[2]
				and int(replay_roster[3].device_id) == original_devices[3]
			),
			"Replay retains original gamepad seat and device identities"
		)
		await _capture("02_replay_fresh_match_1920x1080.png")
	await physics_frame


func _test_all_finish_round_limit() -> void:
	room.tuning.match_target_score_units = 80
	room.tuning.match_round_limit = 12
	room.tuning.lagsanay_opening_head_start_seconds = 0.001
	room.tuning.lagsanay_taya_seconds_2p = 60.0
	room.tuning.lagsanay_taya_seconds_3p = 60.0
	room.tuning.lagsanay_taya_seconds_4p = 60.0
	room.tuning.match_race_hard_cap_seconds = 0.002
	room.tuning.match_race_after_first_finish_seconds = 0.002
	room._finish_pugad_timeout()
	var empty_edits: Array[Dictionary] = []
	room._resolve_place_edits(empty_edits)
	for active_round in range(1, 13):
		if active_round > 1:
			room._start_next_round()
			await process_frame
			await _enter_play()
		await _finish_race_round([0, 1, 2, 3])
		if active_round < 12:
			_check(
				room.phase_controller.phase == MatchPhaseController.Phase.RESULTS,
				"round-limit fixture continues after completed round %d" % active_round
			)
	_check(
		(
			room._sudden_death_active
			and room.lifecycle.tied_seats == [0, 1, 2, 3]
			and room.phase_controller.phase == MatchPhaseController.Phase.PLAY
		),
		"four-player all-finish matches reach round 12 with suppressed scores and enter sudden death"
	)
	_check(room.items.round_number == 12, "sudden death does not create round 13")
	_check(
		room.lagsanay_controller.seat_indices == [0, 1, 2, 3],
		"Lagsanay keeps all four tied original slots"
	)
	_check(
		room.cumulative_score_units.values().all(func(units: int) -> bool: return units == 0),
		"all-finish suppression leaves all four scores below target through round 12"
	)
	await _capture("03_all_finish_round_limit_sudden_death_1920x1080.png")
	var winner := await _finish_sudden_death_with_timeout()
	_check(
		room.final_results_visible and [0, 1, 2, 3].has(winner),
		"real Lagsanay controller resolves one of four tied contestants as the final winner"
	)
	_check(
		room.final_scores_units.values().all(func(units: int) -> bool: return units == 0),
		"sudden-death placement points never change match totals"
	)
	_check(
		(
			room.last_results_model.sudden_death
			and room.last_results_model.per_seat_outcomes.size() == 4
		),
		"final live view model records sudden death and every original participant"
	)
	_check(
		room.last_results_model.last_cluck_explanation.is_empty(),
		"survivor ending does not claim a Last Cluck result"
	)
	await _capture("04_final_sudden_death_results_1920x1080.png")
	await _replay_from_final_results()


func _test_noncontiguous_subset_and_lobby() -> void:
	room.tuning.match_target_score_units = 80
	room.tuning.match_round_limit = 1
	room.tuning.lagsanay_opening_head_start_seconds = 0.001
	room.tuning.lagsanay_taya_seconds_2p = 60.0
	room.tuning.lagsanay_taya_seconds_3p = 60.0
	room.tuning.lagsanay_taya_seconds_4p = 60.0
	room.tuning.match_race_hard_cap_seconds = 0.002
	room.tuning.match_race_after_first_finish_seconds = 0.002
	room.cumulative_score_units = {0: 0, 1: 40, 2: 0, 3: 40}
	(
		report
		. append(
			"Fixture note: preloaded cumulative scores 40/40 for P2/P4 isolate the round-limit subset route."
		)
	)
	room._finish_pugad_timeout()
	var placed := _place_test_construction()
	_check(
		bool(placed.get("allowed", false)),
		"preloaded tie fixture adds construction before Place ends"
	)
	var no_edits: Array[Dictionary] = []
	room._resolve_place_edits(no_edits)
	var stage_signature := room.items.construction_signature()
	var stage_count := room.items.persistent_count()
	await _finish_race_round([])
	_check(
		(
			room._sudden_death_active
			and room.lifecycle.tied_seats == [1, 3]
			and room.lagsanay_controller.seat_indices == [1, 3]
		),
		"four-player preloaded fixture routes only noncontiguous top seats P2/P4 into Lagsanay"
	)
	_check(
		(
			room.items.persistent_count() == stage_count
			and room.items.construction_signature() == stage_signature
		),
		"sudden death preserves the same persistent constructed stage"
	)
	_check(
		(
			room.actors[0].visible == false
			and room.actors[2].visible == false
			and room.actors[0].collision_layer == 0
			and room.actors[2].collision_layer == 0
		),
		"non-tied original participants cannot tag, become taya or enter hazard resolution"
	)
	var scores_at_tiebreak := room.cumulative_score_units.duplicate(true)
	var taya := room.lagsanay_controller.taya_seat
	for seat_index in [1, 3]:
		var contestant := room.actors[seat_index] as ChickenController
		contestant.global_position = room.arena.controller_origin_from_feet(room.arena.spawn_feet)
		if seat_index != taya:
			contestant.global_position += Vector2(600.0, 0.0)
	await physics_frame
	await _capture("05_noncontiguous_tied_players_sudden_death_1920x1080.png")
	await _test_midmatch_leave_cancel()
	await _test_pause_reclaim()
	await _test_real_tied_player_contact()
	var last_cluck := _finish_with_synthetic_last_cluck()
	var subset_winner := int(last_cluck.get("winner_seat", -1))
	_check(
		room.final_results_visible and [1, 3].has(subset_winner),
		"Last Cluck resolves one noncontiguous tied leader"
	)
	_check(
		room.final_scores_units == scores_at_tiebreak,
		"Lagsanay placement awards do not change match totals"
	)
	_check(
		room.final_last_cluck and not room.last_results_model.last_cluck_explanation.is_empty(),
		"Last Cluck explanation appears on the live match result screen"
	)
	await _capture("06_final_noncontiguous_sudden_death_results_1920x1080.png")
	await _test_quit_cancel()
	await _return_to_lobby()
	_check(
		room.phase_controller.phase == MatchPhaseController.Phase.LOBBY,
		"whole group returns to the internal lobby"
	)
	_check(
		room.input_router.registry.joined_seats().size() == 4,
		"whole-group leave preserves the scoring player count"
	)
	_check(room.items.persistent_count() == 0, "Lobby return clears construction and transients")
	_check(
		room.cumulative_score_units.is_empty(), "Lobby return discards the completed match score"
	)
	await _capture("07_return_to_lobby_1920x1080.png")


func _replay_from_final_results() -> void:
	for seat_index in [0, 1, 2, 3]:
		room._on_match_action_pressed(seat_index, "confirm")
	_check(
		(
			room.match_run_id == 3
			and room.phase_controller.phase == MatchPhaseController.Phase.PUGAD
			and room.items.persistent_count() == 0
		),
		"all players ready Replay after round-limit sudden death and reset the whole match"
	)
	await process_frame
	await physics_frame


func _place_test_construction() -> Dictionary:
	for cell in [Vector2i(22, 9), Vector2i(24, 10), Vector2i(18, 10), Vector2i(26, 9)]:
		var result := room.items.place("build.hollow_blocks.cell_1x1", cell, 0, 0)
		if bool(result.get("allowed", false)):
			return result
	return {"allowed": false, "reason": "no allowed test cell"}


func _enter_play() -> void:
	room._finish_pugad_timeout()
	var empty_edits: Array[Dictionary] = []
	room._resolve_place_edits(empty_edits)
	_check(
		room.phase_controller.phase == MatchPhaseController.Phase.PLAY,
		"Pugad and Place transition into Karera Play"
	)


func _finish_race_round(winning_seats: Array[int]) -> void:
	var controller := room.race_round_controller
	var candidates: Array[Dictionary] = []
	var tick := Engine.get_physics_frames()
	for seat_index in winning_seats:
		(
			candidates
			. append(
				{
					"round_id": controller.ledger.round_id,
					"seat_index": seat_index,
					"kind": "goal",
					"event_id": "%s:synthetic-goal:%d" % [controller.ledger.round_id, seat_index],
					"physics_tick": tick,
				}
			)
		)
	var step := controller.advance_step(0.01, tick, candidates)
	room._apply_race_outcomes(step.new_outcomes)
	room._finish_race(str(step.end_reason))
	await process_frame
	await physics_frame


func _test_final_readiness_invalidation_and_quit() -> void:
	_select_result_action(0, 2)
	for seat_index in [0, 1, 2, 3]:
		room._on_match_action_pressed(seat_index, "confirm")
	_check(
		room._modal_kind == "quit" and room._confirm_dialog.is_open(),
		"ordinary score-target results open Quit confirmation after unanimous ready"
	)
	room._confirm_dialog.cancel()
	_check(
		room.final_results_visible and not paused and room.result_action == -1,
		"cancelling ordinary Quit leaves the live result screen intact"
	)
	_select_result_action(0, 0)
	room._on_match_action_pressed(0, "confirm")
	_check(room.result_ready.has(0), "one fresh participant readies Replay")
	room._on_result_device_status_changed(7101, false)
	_check(
		(
			room.result_ready.is_empty()
			and room.result_action == -1
			and room.result_menu_owner == -1
			and not bool(room.input_router.registry.get_seat(0).ready)
		),
		"gamepad status change clears result readiness and its pending action"
	)
	_select_result_action(1, 0)
	room._on_match_action_pressed(1, "confirm")
	room._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	_check(
		room.result_ready.is_empty() and room.result_action == -1 and room.result_menu_owner == -1,
		"focus loss clears result readiness and menu ownership"
	)


func _select_result_action(owner: int, target_action: int) -> void:
	var steps := 0
	while (
		(room.result_menu_owner < 0 or room._result_screen.selected_action() != target_action)
		and steps < 4
	):
		room._on_match_navigation_step(owner, "left")
		steps += 1
	_check(
		room.result_menu_owner == owner and room._result_screen.selected_action() == target_action,
		"first fresh navigation selects result action %d for P%d" % [target_action, owner + 1]
	)


func _test_midmatch_leave_cancel() -> void:
	var before_phase := room.phase_controller.phase
	var before_signature := room.items.construction_signature()
	room.request_return()
	_check(
		room._confirm_dialog.is_open(),
		"mid-match whole-group leave uses the shared confirmation dialog"
	)
	room._confirm_dialog.cancel()
	_check(
		(
			room.phase_controller.phase == before_phase
			and not paused
			and room.items.construction_signature() == before_signature
		),
		"cancelling leave restores the sudden-death state and persistent stage"
	)


func _test_pause_reclaim() -> void:
	var old_device := int(room.input_router.registry.get_seat(3).device_id)
	var missing := room.input_router.registry.disconnect_gamepad(old_device)
	room.input_router.seat_disconnected.emit(missing)
	_check(
		(
			missing == 3
			and room.pause_coordinator.state == PauseRecoveryCoordinator.State.PAUSED
			and paused
		),
		"device loss pauses sudden death and preserves the missing seat"
	)
	_check(
		room.pause_coordinator.choose_reclaim_seat(missing),
		"missing original seat can be selected for reclaim"
	)
	_check(
		room.pause_coordinator.reclaim_device(old_device),
		"same gamepad device reclaims its original slot"
	)
	for seat in room.input_router.registry.joined_seats():
		room.input_router.registry.set_ready(int(seat.seat), true)
	room.pause_coordinator.resume_countdown_seconds = 0.01
	_check(
		room.pause_coordinator.request_resume(),
		"all connected original players can resume together"
	)
	await create_timer(0.04, true).timeout
	_check(
		(
			room.pause_coordinator.state == PauseRecoveryCoordinator.State.RUNNING
			and not paused
			and int(room.input_router.registry.get_seat(3).device_id) == old_device
		),
		"reclaim resumes the same match and retains device identity"
	)
	await physics_frame


func _test_real_tied_player_contact() -> void:
	var controller := room.lagsanay_controller
	var initial_taya := controller.taya_seat
	var receiver_seat := -1
	for seat_index in controller.seat_indices:
		if seat_index != initial_taya:
			receiver_seat = seat_index
			break
	if receiver_seat < 0:
		_check(false, "Lagsanay has a receiver seat for a taya tag")
		return
	for seat_index in [1, 3]:
		var actor := room.actors[seat_index] as ChickenController
		actor.global_position = room.arena.controller_origin_from_feet(room.arena.spawn_feet)
	await physics_frame
	await physics_frame
	_check(
		controller.head_start_remaining == 0.0,
		"tied-player head start expires on active simulation time"
	)
	var taya_actor := room.actors[controller.taya_seat] as ChickenController
	var receiver := room.actors[receiver_seat] as ChickenController
	taya_actor.global_position = room.arena.controller_origin_from_feet(room.arena.spawn_feet)
	receiver.global_position = taya_actor.global_position + Vector2(12.0, 0.0)
	await physics_frame
	var contacts := room._sudden_death_tag_contacts()
	var physically_tagged := controller.taya_seat != initial_taya
	if not contacts.is_empty() and not physically_tagged:
		var before_taya := controller.taya_seat
		var tag_result := controller.advance_step(
			0.001, Engine.get_physics_frames(), contacts, room.actors
		)
		physically_tagged = bool(tag_result.tagged) and controller.taya_seat != before_taya
	_check(
		not contacts.is_empty() or physically_tagged,
		"real physics contact sensor records a tied contestant"
	)
	_check(physically_tagged, "real contact transfers taya once")
	_check(
		(
			controller.seat_indices == [1, 3]
			and not controller.seat_indices.has(0)
			and not controller.seat_indices.has(2)
		),
		"spectators cannot enter tag or taya resolution"
	)
	await _capture("03b_tied_player_contact_1920x1080.png")


func _finish_sudden_death_with_timeout() -> int:
	var controller := room.lagsanay_controller
	var iterations := 0
	while not controller.ended and iterations < 10:
		controller.countdown_remaining = 0.001
		room._advance_sudden_death_physics(0.02)
		iterations += 1
		await physics_frame
	var outcome := controller.sudden_death_winner()
	return int(outcome.get("winner_seat", -1))


func _finish_with_synthetic_last_cluck() -> Dictionary:
	var controller := room.lagsanay_controller
	var tick := Engine.get_physics_frames()
	var event_time := controller.simulation_clock + 0.001
	for seat_index in controller.seat_indices:
		var record := ATTRIBUTION.new()
		record.kind = AttributionRecord.Kind.ELIMINATION
		record.player_seat = seat_index
		record.owner_seat = 3 if seat_index == 1 else 1
		record.source_item_id = "synthetic-last-cluck-trap-%d" % seat_index
		record.source_family_id = "synthetic-last-cluck-fixture"
		record.physics_time = event_time
		record.physics_tick = tick
		record.time_comparable = true
		record.round_id = controller.round_id
		record.event_id = "%s:synthetic-last-cluck:%d" % [controller.round_id, seat_index]
		_check(controller.submit_hazard(record), "synthetic Last Cluck hazard record is accepted")
	room._advance_sudden_death_physics(0.002)
	report.append(
		(
			"Fixture note: simultaneous Last Cluck hazard records are synthetic; the P07 allowlist "
			+ "contains no hazards."
		)
	)
	return controller.sudden_death_winner()


func _test_quit_cancel() -> void:
	room._on_match_navigation_step(0, "right")
	room._on_match_navigation_step(0, "right")
	_check(room.result_action == 2, "result menu can select Quit")
	for seat_index in [0, 1, 2, 3]:
		room._on_match_action_pressed(seat_index, "confirm")
	_check(
		room._modal_kind == "quit" and room._confirm_dialog.is_open(),
		"unanimously ready Quit opens the shared confirmation dialog"
	)
	room._confirm_dialog.cancel()
	_check(
		room.final_results_visible and not paused and room.result_action == -1,
		"cancelling Quit restores results and clears pending readiness"
	)


func _return_to_lobby() -> void:
	room._on_match_navigation_step(0, "left")
	_check(room.result_action == 1, "result menu can select Return to Lobby")
	for seat_index in [0, 1, 2, 3]:
		room._on_match_action_pressed(seat_index, "confirm")
		if room.phase_controller.phase == MatchPhaseController.Phase.LOBBY:
			break


func _capture(file_name: String) -> void:
	if DisplayServer.get_name() == "headless":
		report.append("CAPTURE_SKIPPED_HEADLESS %s" % file_name)
		return
	await process_frame
	await process_frame
	var viewport_image := get_root().get_texture().get_image()
	var result := viewport_image.save_png(output_dir.path_join(file_name))
	_check(result == OK, "saved rendered capture %s" % file_name)


func _dispose_room() -> void:
	if room != null and is_instance_valid(room):
		room.queue_free()
		await process_frame
		await process_frame


func _check(condition: bool, message: String) -> void:
	checks += 1
	var line := ("PASS: " if condition else "FAIL: ") + message
	report.append(line)
	if not condition:
		failures.append(message)

# gdlint: disable=max-file-lines
extends SceneTree

const ROOM_SCENE := preload("res://scenes/match/p09_match_lifecycle_room.tscn")
const OUTPUT_RELATIVE := "../docs/evidence/p09"

var room: P09MatchLifecycleRoom
var failures: Array[String] = []
var cycles: Array[Dictionary] = []
var frame_times_ms := PackedFloat32Array()
var warmed_frame_times_ms := PackedFloat32Array()
var warmed_baseline: Dictionary = {}
var warmed_capture_enabled := false


func _initialize() -> void:
	call_deferred("_run")


func _process(delta: float) -> bool:
	if delta > 0.0:
		frame_times_ms.append(delta * 1000.0)
		if warmed_capture_enabled:
			warmed_frame_times_ms.append(delta * 1000.0)
	return false


func _run() -> void:
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(Vector2i(1920, 1080))
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	room = ROOM_SCENE.instantiate() as P09MatchLifecycleRoom
	root.add_child(room)
	await process_frame
	await physics_frame
	_join_four_seats()
	for seat_index in [0, 1, 2, 3]:
		room.input_router.registry.set_ready(seat_index, true)
	room.tuning.match_results_advance_seconds = 600.0
	room.tuning.match_race_hard_cap_seconds = 0.003
	room.tuning.match_race_after_first_finish_seconds = 0.003
	room.tuning.lagsanay_opening_head_start_seconds = 0.001
	room.tuning.lagsanay_taya_seconds_2p = 0.02
	room.tuning.lagsanay_taya_seconds_3p = 0.02
	room.tuning.lagsanay_taya_seconds_4p = 0.02
	room.tuning.lagsanay_last_cluck_freeze_seconds = 0.001
	var initial := _snapshot("warmed-room")
	for cycle_index in range(10):
		var cycle_id := cycle_index + 1
		if room.phase_controller.phase == MatchPhaseController.Phase.LOBBY:
			for seat_index in [0, 1, 2, 3]:
				room.input_router.registry.set_ready(seat_index, true)
			_check(room.start_match(), "cycle %d starts a fresh match" % cycle_id)
		await process_frame
		var match_id := room.match_run_id
		var before := _snapshot("match-start")
		var placement := room.items.place("build.hollow_blocks.cell_1x1", Vector2i(22, 9), 0, 0)
		if not bool(placement.get("allowed", false)):
			placement = room.items.place("build.hollow_blocks.cell_1x1", Vector2i(24, 10), 0, 0)
		_check(
			bool(placement.get("allowed", false)),
			"cycle %d places persistent construction" % cycle_id
		)
		await _enter_play()
		var sudden_death := cycle_id % 2 == 0
		if sudden_death:
			for active_round in range(1, 13):
				if active_round > 1:
					room._start_next_round()
					await process_frame
					await _enter_play()
				await _finish_race([0, 1, 2, 3])
			_check(room._sudden_death_active, "cycle %d enters tied-player sudden death" % cycle_id)
			await _finish_sudden_death()
		else:
			for active_round in range(1, 7):
				if active_round > 1:
					room._start_next_round()
					await process_frame
					await _enter_play()
				await _finish_race([0])
		_check(
			room.final_results_visible, "cycle %d ends on the themed live result screen" % cycle_id
		)
		var final_state := _snapshot("match-result")
		var action_index := _result_action_for_cycle(cycle_id)
		if action_index == 1:
			room._on_match_navigation_step(0, "right")
			if room.result_action != 1:
				room._on_match_navigation_step(0, "right")
		for seat_index in [0, 1, 2, 3]:
			room._on_match_action_pressed(seat_index, "confirm")
		if room.phase_controller.phase == MatchPhaseController.Phase.LOBBY:
			for seat_index in [0, 1, 2, 3]:
				room.input_router.registry.set_ready(seat_index, true)
			_check(room.start_match(), "cycle %d restarts after its selected action" % cycle_id)
		await process_frame
		await process_frame
		var reset_state := _snapshot("after-restart")
		if cycle_id == 3:
			warmed_baseline = reset_state.duplicate(true)
			warmed_capture_enabled = true
		var restarted := room.phase_controller.phase == MatchPhaseController.Phase.PUGAD
		_check(restarted, "cycle %d returns to a fresh Pugad" % cycle_id)
		_check(room.match_run_id == match_id + 1, "cycle %d advances the match identity" % cycle_id)
		_check(
			room.items.persistent_count() == 0, "cycle %d clears construction on reset" % cycle_id
		)
		_check(
			room.cumulative_score_units.values().all(func(score: int) -> bool: return score == 0),
			"cycle %d resets every match score" % cycle_id
		)
		_check(
			(
				room.items.budget.total_count() == 0
				and room.items.budget.captive_count() == 0
				and room.pending_claims.is_empty()
			),
			"cycle %d clears transients, captures and pending claims" % cycle_id
		)
		_check(
			(
				room.lagsanay_controller.round_id.is_empty()
				and not room.lagsanay_controller.active
				and not room.lagsanay_controller.ended
				and room.lagsanay_controller.taya_seat == -1
				and room.lagsanay_controller.countdown_remaining == 0.0
				and room.lagsanay_controller.head_start_remaining == 0.0
				and room.lagsanay_controller.pass_back_immunity_until.is_empty()
			),
			"cycle %d clears Lagsanay taya timer and immunity" % cycle_id
		)
		_check(
			(
				room.result_ready.is_empty()
				and not room.final_results_visible
				and room.items.round_number == 0
			),
			"cycle %d clears result readiness and completed-round state" % cycle_id
		)
		_check(
			not room.lifecycle.callback_is_current(
				match_id, int(final_state.round), int(final_state.sudden_death_attempt)
			),
			"cycle %d rejects callbacks from the completed match" % cycle_id
		)
		if not warmed_baseline.is_empty():
			_check(
				absf(float(reset_state.objects) - float(warmed_baseline.objects)) <= 5.0,
				"cycle %d object count remains within five of the warmed baseline" % cycle_id
			)
			_check(
				(
					absf(
						(
							float(reset_state.static_memory_bytes)
							- float(warmed_baseline.static_memory_bytes)
						)
					)
					<= 1048576.0
				),
				(
					"cycle %d Godot static memory remains within 1 MiB of the warmed baseline"
					% cycle_id
				)
			)
		(
			cycles
			. append(
				{
					"cycle": cycle_id,
					"ending": "sudden_death" if sudden_death else "score_target",
					"menu_action": "lobby" if action_index == 1 else "replay",
					"match_identity": match_id,
					"before": before,
					"finish": final_state,
					"after": reset_state,
					"round_count": room.items.round_number,
					"completed_round_count": int(final_state.round),
					"sudden_death_attempt": int(final_state.sudden_death_attempt),
					"final_winner": int(final_state.final_winner),
					"fresh_callbacks":
					{
						"result_visible": room.final_results_visible,
						"result_ready": room.result_ready.size(),
						"controller_ended": room.lagsanay_controller.ended,
						"old_callback_current":
						room.lifecycle.callback_is_current(
							match_id, int(final_state.round), int(final_state.sudden_death_attempt)
						),
					},
				}
			)
		)
	var report := _build_report(initial)
	var output_dir := (
		ProjectSettings.globalize_path("res://").path_join(OUTPUT_RELATIVE).simplify_path()
	)
	DirAccess.make_dir_recursive_absolute(output_dir)
	var file := FileAccess.open(output_dir.path_join("p09_restart_audit.json"), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(report, "\t") + "\n")
		file.close()
	print("P09_RESTART_AUDIT cycles=%d failures=%d" % [cycles.size(), failures.size()])
	quit(1 if not failures.is_empty() else 0)


func _join_four_seats() -> void:
	room.join_keyboard("K1")
	room.join_keyboard("K2")
	for device_id in [7101, 7102]:
		var seat_index := room.input_router.registry.join_gamepad(device_id)
		if seat_index >= 0:
			room.input_router.seat_joined.emit(seat_index)


func _enter_play() -> void:
	room._finish_pugad_timeout()
	room._resolve_place_edits([])


func _finish_race(finishing_seats: Array[int]) -> void:
	var controller := room.race_round_controller
	var candidates: Array[Dictionary] = []
	var tick := Engine.get_physics_frames()
	for seat_index in finishing_seats:
		(
			candidates
			. append(
				{
					"round_id": controller.ledger.round_id,
					"seat_index": seat_index,
					"kind": "goal",
					"event_id": "%s:audit-goal:%d" % [controller.ledger.round_id, seat_index],
					"physics_tick": tick,
				}
			)
		)
	var result := controller.advance_step(0.01, tick, candidates)
	room._apply_race_outcomes(result.new_outcomes)
	room._finish_race(str(result.end_reason))
	await process_frame
	await physics_frame


func _finish_sudden_death() -> void:
	var iterations := 0
	while room._sudden_death_active and iterations < 12:
		room.lagsanay_controller.countdown_remaining = 0.001
		room._advance_sudden_death_physics(0.02)
		iterations += 1
		await physics_frame
	_check(not room._sudden_death_active, "sudden death resolves after one survivor remains")


func _result_action_for_cycle(cycle_id: int) -> int:
	match cycle_id:
		1, 4, 5, 8, 9:
			return 0
		2, 3, 6, 7:
			return 1
		10:
			return 0
	return 0


func _snapshot(label: String) -> Dictionary:
	var actor_states: Dictionary = {}
	for seat_index in room.actors:
		var actor := room.actors[seat_index] as ChickenController
		actor_states[seat_index] = int(actor.lifecycle.status) if actor != null else "missing"
	return {
		"label": label,
		"match_id": room.match_run_id,
		"phase": str(room.phase_controller.phase),
		"round": room.items.round_number,
		"scores": room.cumulative_score_units.duplicate(true),
		"item_count": room.items.persistent_count(),
		"construction_signature": room.items.construction_signature(),
		"transient_count": room.items.budget.total_count(),
		"captured_player_count": room.items.budget.captive_count(),
		"pending_claim_count": room.pending_claims.size(),
		"actors": actor_states,
		"result_visible": room.final_results_visible,
		"result_ready_count": room.result_ready.size(),
		"final_winner": room.final_winner_seat,
		"sudden_death_attempt": room.lifecycle.sudden_death_attempt,
		"lifecycle_match_id": room.lifecycle.match_id,
		"callback_pending": room.lifecycle.tied_seats.size() >= 2,
		"lagsanay":
		{
			"round_id": room.lagsanay_controller.round_id,
			"active": room.lagsanay_controller.active,
			"ended": room.lagsanay_controller.ended,
			"taya_seat": room.lagsanay_controller.taya_seat,
			"countdown_remaining": room.lagsanay_controller.countdown_remaining,
			"head_start_remaining": room.lagsanay_controller.head_start_remaining,
			"pass_back_immunity_count": room.lagsanay_controller.pass_back_immunity_until.size(),
		},
		"objects": Performance.get_monitor(Performance.OBJECT_COUNT),
		"static_memory_bytes": Performance.get_monitor(Performance.MEMORY_STATIC),
		"static_memory_peak_bytes": Performance.get_monitor(Performance.MEMORY_STATIC_MAX),
	}


func _build_report(initial: Dictionary) -> Dictionary:
	var sorted_times := frame_times_ms.duplicate()
	sorted_times.sort()
	return {
		"title": "P09 ten-cycle finish-to-restart audit",
		"date_utc": Time.get_datetime_string_from_system(true),
		"engine": Engine.get_version_info(),
		"os": OS.get_name(),
		"processor": OS.get_processor_name(),
		"renderer": RenderingServer.get_video_adapter_name(),
		"resolution": "1920x1080 windowed; vsync disabled",
		"fixtures":
		[
			"All four seats use synthetic keyboard/device identities.",
			"Race finish candidates are injected into the real race ledger.",
			"Sudden-death timeout is shortened and advanced through the real Lagsanay physics controller.",
			"Persistent construction is placed each match; scores/outcomes are live coordinator state.",
		],
		"memory_note":
		(
			"MEMORY_STATIC and OBJECT_COUNT are Godot runtime monitors, not process working "
			+ "set/private bytes."
		),
		"baseline": initial,
		"frame_time_ms": _frame_statistics(sorted_times),
		"warmed_baseline_after_cycle_3": warmed_baseline,
		"warmed_frame_time_ms": _frame_statistics(_sorted_copy(warmed_frame_times_ms)),
		"post_warm_deltas": _post_warm_deltas(),
		"completed_cycles": cycles.size(),
		"failures": failures.duplicate(),
		"cycles": cycles.duplicate(true),
	}


func _sorted_copy(values: PackedFloat32Array) -> PackedFloat32Array:
	var sorted := values.duplicate()
	sorted.sort()
	return sorted


func _post_warm_deltas() -> Array[Dictionary]:
	var deltas: Array[Dictionary] = []
	if warmed_baseline.is_empty():
		return deltas
	for cycle in cycles:
		if int(cycle.cycle) < 3:
			continue
		var after: Dictionary = cycle.after
		(
			deltas
			. append(
				{
					"cycle": int(cycle.cycle),
					"object_delta": int(after.objects) - int(warmed_baseline.objects),
					"static_memory_delta_bytes":
					int(after.static_memory_bytes) - int(warmed_baseline.static_memory_bytes),
				}
			)
		)
	return deltas


func _frame_statistics(sorted_times: PackedFloat32Array) -> Dictionary:
	if sorted_times.is_empty():
		return {"samples": 0}
	return {
		"samples": sorted_times.size(),
		"min": sorted_times[0],
		"median": sorted_times[sorted_times.size() / 2],
		"p95": sorted_times[mini(sorted_times.size() - 1, int(sorted_times.size() * 0.95))],
		"max": sorted_times[sorted_times.size() - 1],
	}


func _check(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)

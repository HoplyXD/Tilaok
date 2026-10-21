# gdlint: disable=max-line-length,max-file-lines
extends SceneTree

## NLB-P09-T02 ten-cycle replay / Return-to-Lobby audit (contract v1.6). Authored only; nothing in it
## has run. One host process, the real scheduled room and the real session manager, four seats (two
## local keyboards, two synthetic remote peers); the transport is a capture stub, so no socket is
## opened and no listener starts. Every cycle plays a real ending (score target on odd cycles, tied
## Sudden Death on even ones), compares the host ledger with a client model fed only the frames the
## host sent, takes the selected exit route (Replay re-keys in place; Return to Lobby stops the
## session) and then counts what is left. Synthetic peers are engineering evidence only.
## Run: Godot --headless --fixed-fps 60 --path tilaok! --script res://tests/audit_nlb_p09_cycles.gd

const ROOM_SCENE := preload("res://scenes/match/p12_scheduled_match_room.tscn")
const OUTPUT_RELATIVE := "../docs/evidence/nlb/p09"
const REMOTE_PEERS := [61, 62]
const GENERATION := 5
const CYCLES := 10

var room: P12ScheduledMatchRoom
var manager: AuditManager
var host_authority := SimulationAuthority.host()
var failures: Array[String] = []
var rows: Array[Dictionary] = []
var warmed_baseline: Dictionary = {}
var lobby_requested := false


class AuditManager:
	extends NetworkSessionManager

	var sent: Array[Dictionary] = []

	func _send(peer_id: int, family: int, payload: PackedByteArray) -> bool:
		sent.append({"peer": peer_id, "family": family, "payload": payload.duplicate(), "epoch": session_epoch})
		return true

	func _send_to_host(family: int, payload: PackedByteArray) -> bool:
		return _send(1, family, payload)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	room = ROOM_SCENE.instantiate() as P12ScheduledMatchRoom
	root.add_child(room)
	await process_frame
	await physics_frame
	room.tuning.match_results_advance_seconds = 600.0
	room.tuning.match_race_hard_cap_seconds = 0.003
	room.tuning.match_race_after_first_finish_seconds = 0.003
	room.tuning.lagsanay_opening_head_start_seconds = 0.001
	room.tuning.lagsanay_taya_seconds_2p = 0.02
	room.tuning.lagsanay_taya_seconds_3p = 0.02
	room.tuning.lagsanay_taya_seconds_4p = 0.02
	room.tuning.lagsanay_last_cluck_freeze_seconds = 0.001
	room.flow_requested.connect(_on_flow_requested)
	manager = AuditManager.new()
	root.add_child(manager)
	manager.local_authority = SimulationAuthority.offline()
	room.join_keyboard("K1")
	room.join_keyboard("K2")
	_open_session()
	var baseline := _snapshot("warmed-room")
	for cycle in range(1, CYCLES + 1):
		var lobby_exit := cycle % 3 == 0
		var sudden_death := cycle % 2 == 0
		_configure_ending(sudden_death)
		if room.phase_controller.phase == MatchPhaseController.Phase.LOBBY:
			_ready_everyone()
			_check(room.start_match(), "cycle %d starts a match" % cycle)
		await process_frame
		var match_before := manager.active_match_id
		var epoch_before := manager.session_epoch
		room.items.place("build.hollow_blocks.cell_1x1", Vector2i(22, 9), 0, 0)
		await _enter_play()
		if sudden_death:
			await _finish_race([] as Array[int])
			_check(room._sudden_death_active, "cycle %d enters tied Sudden Death" % cycle)
			await _finish_sudden_death()
		else:
			await _finish_race([0] as Array[int])
		_check(room.final_results_visible, "cycle %d reaches the final results" % cycle)
		var client := _client_from_host_frames()
		var agreed := _ledgers_agree(client)
		_check(agreed, "cycle %d: the client ledger and totals equal the host's" % cycle)
		var final_entry := client.client_results.final_entry()
		_check(int(final_entry.get("sudden_death", -1)) == (1 if sudden_death else 0), "cycle %d: the ledger records the ending kind" % cycle)
		var ledger_revision := room.result_ledger.revision()
		_phones_vote(NetworkResultsCodec.ResultAction.VOTE_LOBBY if lobby_exit else NetworkResultsCodec.ResultAction.VOTE_REPLAY)
		lobby_requested = false
		if lobby_exit:
			room._on_result_lobby_requested()
			_check(lobby_requested, "cycle %d: Return to Lobby is handed to the session owner" % cycle)
			manager.stop_session(NetworkLifecycleCodec.SessionEnd.LOBBY_RETURN)
			room.reset_room()
			var counts := manager.teardown_counts()
			_check(_all_zero(counts), "cycle %d: a stopped session retains nothing %s" % [cycle, str(_nonzero(counts))])
			_open_session()
		else:
			manager.sent.clear()
			room._on_result_replay_requested()
			await process_frame
			_check(manager.active_match_id == match_before + 1 and manager.session_epoch != epoch_before, "cycle %d: Replay mints a new match ID and epoch" % cycle)
			var rekeys := manager.sent.filter(func(entry: Dictionary) -> bool: return int(entry.family) == NetworkFrame.Family.REKEY)
			_check(rekeys.size() == REMOTE_PEERS.size() and rekeys.all(func(entry: Dictionary) -> bool: return int(entry.epoch) == epoch_before), "cycle %d: every peer is re-keyed under the old epoch" % cycle)
			_ack_peers()
			var restarted_counts := manager.teardown_counts()
			for key in ["pending_actions", "placement_cache", "placement_inflight", "known_stage_entities", "known_transients", "result_action_cache", "snapshot_receivers", "tombstone_repeats", "terrain_parts", "pause_epoch", "rekey_pending"]:
				_check(int(restarted_counts[key]) == 0, "cycle %d: Replay leaves %s empty" % [cycle, key])
			_check(int(restarted_counts["reservation_entries"]) == REMOTE_PEERS.size() and int(restarted_counts["retired_epochs"]) <= 2, "cycle %d: only the live identities and at most two retired epochs remain" % cycle)
		await process_frame
		await process_frame
		var after := _snapshot("after-exit")
		if cycle == 3:
			warmed_baseline = after.duplicate(true)
		_check(room.items.persistent_count() == 0 and room.items.budget.total_count() == 0 and room.pending_claims.is_empty(), "cycle %d clears construction, transients and claims" % cycle)
		_check(room.cumulative_score_units.values().all(func(units: int) -> bool: return units == 0), "cycle %d clears every score" % cycle)
		_check(room.result_ready.is_empty() and not room.final_results_visible and room.result_ledger.revision() == 0, "cycle %d clears readiness, results and the host ledger" % cycle)
		_check(room.lagsanay_controller.round_id.is_empty() and not room.lagsanay_controller.active, "cycle %d clears the Lagsanay controller" % cycle)
		if not warmed_baseline.is_empty():
			_check(absf(float(after.objects) - float(warmed_baseline.objects)) <= 5.0, "cycle %d object count stays within five of the warmed baseline" % cycle)
			_check(absf(float(after.static_memory_bytes) - float(warmed_baseline.static_memory_bytes)) <= 1048576.0, "cycle %d static memory stays within 1 MiB of the warmed baseline" % cycle)
		rows.append({
			"cycle": cycle,
			"ending": "sudden_death" if sudden_death else "score_target",
			"exit": "lobby" if lobby_exit else "replay",
			"ledger_revision_at_ending": ledger_revision,
			"agreed": agreed,
			"match_id_before": match_before,
			"epoch_changed": manager.session_epoch != epoch_before,
			"teardown_counts": manager.teardown_counts(),
			"after": after,
		})
		client.free()
	print("NLB_P09_CYCLE_LEDGER %s" % JSON.stringify(rows))
	_write_report(baseline)
	print("NLB_P09_CYCLE_AUDIT cycles=%d failures=%d input=synthetic seats=4 transport=capture" % [rows.size(), failures.size()])
	manager.queue_free()
	room.queue_free()
	await process_frame
	quit(1 if not failures.is_empty() else 0)


# --- session fixture -------------------------------------------------------------------------


## A host session without a socket: epoch, authority, two synthetic remote seats and their candidates.
func _open_session() -> void:
	manager.router = room.input_router
	manager.host_authority = host_authority
	room.input_router.set_authority(host_authority)
	manager.remote_adapter.configure(room.input_router, host_authority)
	manager.state = NetworkSessionManager.SessionState.LOBBY_OPEN
	manager.session_epoch = manager._new_epoch()
	manager._match_lineage += 1
	manager.active_match_id = manager._match_lineage
	manager.match_active = true
	manager.sync_ready = true
	manager.candidates.clear()
	manager.reservations.clear()
	for peer_id in REMOTE_PEERS:
		var seat := manager.remote_adapter.assign_source("peer_%d" % int(peer_id))
		manager.reservations.issue(seat)
		manager.candidates[int(peer_id)] = {
			"state": NetworkSessionManager.CandidateState.ACKNOWLEDGED,
			"seat": seat,
			"peer_generation": GENERATION,
			"deadline": 0,
			"claim_seat": -1,
			"match_sync_ready": true,
		}
	manager.bind_match_room(room)


func _ready_everyone() -> void:
	for seat in room.input_router.registry.joined_seats():
		room.input_router.registry.set_ready(int(seat.seat), true)


func _configure_ending(sudden_death: bool) -> void:
	# Round 1 is Karera. Score target: a sole finisher passes 1 point at once. Sudden Death: nobody
	# finishes, the round limit is 1 and the leaders are tied.
	room.tuning.match_target_score_units = 100000 if sudden_death else 8
	room.tuning.match_round_limit = 1


func _enter_play() -> void:
	room._finish_pugad_timeout()
	room._resolve_place_edits([])


func _finish_race(finishing_seats: Array[int]) -> void:
	var controller := room.race_round_controller
	var candidates: Array[Dictionary] = []
	var tick := Engine.get_physics_frames()
	for seat_index in finishing_seats:
		candidates.append({
			"round_id": controller.ledger.round_id,
			"seat_index": seat_index,
			"kind": "goal",
			"event_id": "%s:audit-goal:%d" % [controller.ledger.round_id, seat_index],
			"physics_tick": tick,
		})
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
	_check(not room._sudden_death_active, "Sudden Death resolves")


## A client manager that has seen only what the host actually sent to the first remote peer.
func _client_from_host_frames() -> NetworkSessionManager:
	var client := NetworkSessionManager.new()
	root.add_child(client)
	client.client_mode = true
	client.match_active = true
	client.sync_ready = true
	client.active_match_id = manager.active_match_id
	client.client_results.reset(manager.active_match_id)
	for entry in manager.sent:
		if int(entry.peer) == int(REMOTE_PEERS[0]) and int(entry.family) == NetworkFrame.Family.RESULT_EVENT:
			client._receive_result_event(entry.payload)
	return client


func _ledgers_agree(client: NetworkSessionManager) -> bool:
	var host_entries := room.result_ledger.entries()
	var client_entries := client.client_results.entries()
	if host_entries.size() != client_entries.size() or host_entries.is_empty():
		return false
	for index in host_entries.size():
		var host_entry: Dictionary = host_entries[index]
		var client_entry: Dictionary = client_entries[index]
		for key in ["kind", "round_id", "event_id", "revision"]:
			if int(host_entry[key]) != int(client_entry[key]):
				return false
		if host_entry.has("seats"):
			for seat_index in host_entry.seats.size():
				if int(host_entry.seats[seat_index].total) != int(client_entry.seats[seat_index].total):
					return false
	for seat in room.cumulative_score_units:
		if int(room.cumulative_score_units[seat]) != int(client.client_results.totals().get(int(seat), 0)):
			return false
	return true


func _phones_vote(action: int) -> void:
	var latest := room.result_ledger.latest_event_id()
	for peer_id in REMOTE_PEERS:
		var payload := NetworkResultsCodec.encode_action({
			"request_id": Time.get_ticks_usec() & 0xffffff,
			"match_id": manager.active_match_id,
			"round_id": room.result_ledger.latest_round_id(),
			"attempt_id": room.match_run_id & 0xffff,
			"event_id": latest,
			"action": action,
		})
		manager._handle_host_packet(int(peer_id), NetworkFrame.Family.RESULT_ACTION, payload)


func _ack_peers() -> void:
	for peer_id in REMOTE_PEERS:
		manager._handle_host_packet(int(peer_id), NetworkFrame.Family.REKEY_ACK, NetworkLifecycleCodec.encode_rekey_ack(manager.session_epoch, GENERATION))


func _on_flow_requested(kind: StringName) -> void:
	if kind == &"leave_match":
		lobby_requested = true


# --- measurements ----------------------------------------------------------------------------


func _snapshot(label: String) -> Dictionary:
	var actor_states: Dictionary = {}
	for seat_index in room.actors:
		var actor := room.actors[seat_index] as ChickenController
		actor_states[seat_index] = int(actor.lifecycle.status) if actor != null else "missing"
	return {
		"label": label,
		"match_run_id": room.match_run_id,
		"wire_match_id": manager.active_match_id,
		"phase": str(room.phase_controller.phase),
		"round": room.items.round_number,
		"scores": room.cumulative_score_units.duplicate(true),
		"item_count": room.items.persistent_count(),
		"construction_signature": room.items.construction_signature(),
		"transient_count": room.items.budget.total_count(),
		"pending_claim_count": room.pending_claims.size(),
		"actors": actor_states,
		"host_ledger_revision": room.result_ledger.revision(),
		"teardown_counts": manager.teardown_counts(),
		"objects": Performance.get_monitor(Performance.OBJECT_COUNT),
		"nodes": Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
		"static_memory_bytes": Performance.get_monitor(Performance.MEMORY_STATIC),
		"static_memory_peak_bytes": Performance.get_monitor(Performance.MEMORY_STATIC_MAX),
	}


func _all_zero(counts: Dictionary) -> bool:
	return _nonzero(counts).is_empty()


func _nonzero(counts: Dictionary) -> Array:
	var leftovers: Array = []
	for key in counts:
		if int(counts[key]) != 0:
			leftovers.append("%s=%s" % [key, str(counts[key])])
	return leftovers


func _write_report(baseline: Dictionary) -> void:
	var report := {
		"title": "NLB-P09 ten-cycle replay / lobby audit",
		"date_utc": Time.get_datetime_string_from_system(true),
		"engine": Engine.get_version_info(),
		"os": OS.get_name(),
		"fixtures": [
			"Two local keyboard seats and two synthetic remote peers; the transport is a capture stub.",
			"Race finish candidates are injected into the real ledger; Sudden Death runs the real Lagsanay controller.",
			"The client model is fed only the frames the host sent.",
		],
		"memory_note": "MEMORY_STATIC and OBJECT_COUNT are Godot runtime monitors, not process working set.",
		"baseline": baseline,
		"warmed_baseline_after_cycle_3": warmed_baseline,
		"completed_cycles": rows.size(),
		"failures": failures.duplicate(),
		"cycles": rows.duplicate(true),
	}
	var output_dir := ProjectSettings.globalize_path("res://").path_join(OUTPUT_RELATIVE).simplify_path()
	DirAccess.make_dir_recursive_absolute(output_dir)
	var file := FileAccess.open(output_dir.path_join("p09_cycle_audit.json"), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(report, "\t") + "\n")
		file.close()


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS %s" % label)
	else:
		failures.append(label)
		printerr("FAIL %s" % label)

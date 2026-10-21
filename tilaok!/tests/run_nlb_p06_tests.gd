# gdlint: disable=max-line-length,max-file-lines
extends SceneTree

## Focused NLB-P06 checks: contract v1.3 codecs and bounds, reason mapping, the host placement
## path (dedupe, reuse, capacity, ownership, tie order, ROUND_ENDED, disconnect cancel), versioned
## terrain commits with loss/reorder/duplicate replay, the client ghost state machine, P04-only
## peer rejection and unchanged default routes. Transport-free: frames are fed to the handlers.
## Run: Godot --headless --fixed-fps 60 --path tilaok! --script res://tests/run_nlb_p06_tests.gd

const LIVE_NETWORK_ROOM := preload("res://scenes/match/nlb_p06_network_live_build_room.tscn")
const CELL_1X1 := "build.hollow_blocks.cell_1x1"
const REMOTE_PEER := 41
const REMOTE_SOURCE := "peer_41"
const GENERATION := 7

var checks := 0
var failures := 0


class CaptureManager:
	extends NetworkSessionManager

	var sent: Array[Dictionary] = []

	func _send(peer_id: int, family: int, payload: PackedByteArray) -> bool:
		sent.append({"peer": peer_id, "family": family, "payload": payload.duplicate()})
		return true

	func _send_to_host(family: int, payload: PackedByteArray) -> bool:
		return _send(1, family, payload)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_wire_constants()
	_test_intent_and_result_codecs()
	_test_seat_state_and_terrain_codecs()
	_test_reason_mapping()
	_test_routes_and_local_confirm_flag()
	_test_p04_hello_rejected()
	_test_match_lifecycle_route_byte()
	_test_client_terrain_apply()
	_test_client_ghost_state_machine()
	await _test_host_placement_path()
	await _test_round_end_and_disconnect()
	print("NLB_P06_TESTS checks=%d failures=%d" % [checks, failures])
	await process_frame
	quit(1 if failures > 0 else 0)


func _test_wire_constants() -> void:
	_check(NetworkFrame.MAJOR == 1 and NetworkFrame.MINOR == 2, "envelope stays 1.2 so older binaries read the welcome")
	# NLB-P07 (contract v1.4) raised the schema to 4 and requires the live-transient bit as well.
	_check(NetworkFrame.SCHEMA == 4 and NetworkFrame.FEATURE_P06_MASK == 0x00ff and NetworkFrame.FEATURE_REQUIRED_MASK == 0x01ff, "schema 4 requires the live-placement and live-transient features")
	_check((NetworkFrame.FEATURE_P06_MASK & NetworkFrame.FEATURE_LIVE_PLACEMENT) != 0 and (NetworkFrame.FEATURE_P04_MASK & NetworkFrame.FEATURE_LIVE_PLACEMENT) == 0, "P04 mask lacks the live-placement bit")
	for family in [NetworkFrame.Family.PLACEMENT_INTENT, NetworkFrame.Family.PLACEMENT_RESULT, NetworkFrame.Family.LIVE_SEAT_STATE, NetworkFrame.Family.TERRAIN_COMMIT]:
		_check(family in NetworkFrame.FAMILIES, "family 0x%02X is allowlisted" % family)
		_check(NetworkFrame.family_allowed_on_channel(family, RawEnetTransport.CONTROL_CHANNEL), "family 0x%02X uses reliable channel 0" % family)
		_check(not NetworkFrame.family_allowed_on_channel(family, RawEnetTransport.STATE_CHANNEL), "family 0x%02X rejected on the state channel" % family)
	var frame := NetworkFrame.encode(NetworkFrame.Family.PLACEMENT_INTENT, 5, 1, PackedByteArray([1, 2]))
	_check(bool(NetworkFrame.decode(frame, 5).get("ok", false)), "new family frames decode at the envelope")
	_check(not bool(NetworkFrame.decode(NetworkFrame.encode(NetworkFrame.Family.PLACEMENT_INTENT, 5, 1, PackedByteArray()), 6).get("ok", true)), "stale epoch still rejected for new families")


func _test_intent_and_result_codecs() -> void:
	var intent := _intent_fields(9, Vector2i(12, -3), 1, 5)
	var encoded := NetworkPlacementCodec.encode_intent(intent)
	var decoded := NetworkPlacementCodec.decode_intent(encoded)
	_check(encoded.size() == NetworkPlacementCodec.INTENT_BYTES and bool(decoded.get("ok", false)), "placement intent is exactly 48 bytes and round-trips")
	_check(decoded.cell == Vector2i(12, -3) and int(decoded.rotation) == 1 and int(decoded.inventory_id) == 5, "intent keeps cell, rotation and host inventory ID")
	_check(not decoded.has("seat"), "intent carries no seat field")
	_check(not bool(NetworkPlacementCodec.decode_intent(encoded.slice(0, 47)).get("ok", true)), "short intent rejected")
	var long := encoded.duplicate()
	long.append(0)
	_check(not bool(NetworkPlacementCodec.decode_intent(long).get("ok", true)), "long intent rejected")
	var flagged := encoded.duplicate()
	flagged[47] = 1
	_check(int(NetworkPlacementCodec.decode_intent(flagged).get("reason", 0)) == NetworkFrame.Reason.MALFORMED, "non-zero flags are malformed")
	var bad_rotation := encoded.duplicate()
	bad_rotation[46] = 4
	_check(int(NetworkPlacementCodec.decode_intent(bad_rotation).get("reason", 0)) == NetworkFrame.Reason.MALFORMED, "rotation 4 is malformed")
	_check(NetworkPlacementCodec.encode_intent(_intent_fields(0, Vector2i.ZERO, 0, 5)).is_empty(), "request ID 0 cannot be encoded")
	var far := _intent_fields(9, Vector2i(NetworkPlacementCodec.MAX_CELL + 1, 0), 0, 5)
	_check(NetworkPlacementCodec.encode_intent(far).is_empty(), "out-of-range cell is not clamped by the sender")
	var far_bytes := encoded.duplicate()
	far_bytes.encode_s32(38, NetworkPlacementCodec.MAX_CELL + 1)
	var far_decoded := NetworkPlacementCodec.decode_intent(far_bytes)
	_check(int(far_decoded.get("reason", 0)) == NetworkFrame.Reason.FIELD_RANGE and int(far_decoded.get("request_id", 0)) == 9, "out-of-range cell decodes as FIELD_RANGE with its request ID")
	var accepted := {
		"request_id": 9, "status": NetworkPlacementCodec.Status.ACCEPTED, "reason": NetworkFrame.Reason.OK,
		"entity_id": 33, "cell": Vector2i(12, -3), "rotation": 1, "stage_version": 4,
		"activation_tick": 600, "detail": NetworkPlacementCodec.Detail.COMMITTED,
	}
	var result_bytes := NetworkPlacementCodec.encode_result(accepted)
	var result := NetworkPlacementCodec.decode_result(result_bytes)
	_check(result_bytes.size() == NetworkPlacementCodec.RESULT_BYTES and bool(result.get("ok", false)), "placement result is exactly 38 bytes and round-trips")
	_check(int(result.entity_id) == 33 and int(result.stage_version) == 4 and int(result.activation_tick) == 600, "acceptance names entity, stage version and activation tick")
	var no_entity := accepted.duplicate()
	no_entity.entity_id = 0
	_check(not bool(NetworkPlacementCodec.decode_result(NetworkPlacementCodec.encode_result(no_entity)).get("ok", true)), "construction acceptance without an entity is invalid")
	var objective := no_entity.duplicate()
	objective.detail = NetworkPlacementCodec.Detail.OBJECTIVE
	_check(bool(NetworkPlacementCodec.decode_result(NetworkPlacementCodec.encode_result(objective)).get("ok", false)), "Barya objective acceptance needs no stage entity")
	var rejected_ok := {"request_id": 9, "status": NetworkPlacementCodec.Status.REJECTED, "reason": NetworkFrame.Reason.OK, "detail": 1}
	_check(not bool(NetworkPlacementCodec.decode_result(NetworkPlacementCodec.encode_result(rejected_ok)).get("ok", true)), "a rejection always carries a non-OK reason")
	var rejected_entity := result_bytes.duplicate()
	rejected_entity[10] = NetworkPlacementCodec.Status.REJECTED
	_check(not bool(NetworkPlacementCodec.decode_result(rejected_entity).get("ok", true)), "a rejection cannot name an entity")


func _test_seat_state_and_terrain_codecs() -> void:
	var seat_state := {
		"match_id": 1, "round_id": 2, "attempt_id": 3, "inventory_id": 5, "variant_key": CELL_1X1,
		"item_status": NetworkPlacementCodec.ItemStatus.AVAILABLE, "build_mode": true, "rotation": 0,
		"cursor": Vector2i(4, 6),
	}
	var seat_bytes := NetworkPlacementCodec.encode_seat_state(seat_state)
	var seat_decoded := NetworkPlacementCodec.decode_seat_state(seat_bytes)
	_check(seat_bytes.size() == NetworkPlacementCodec.SEAT_STATE_BASE_BYTES + CELL_1X1.length() and bool(seat_decoded.get("ok", false)), "live seat state round-trips")
	_check(seat_decoded.variant_key == CELL_1X1 and bool(seat_decoded.build_mode) and seat_decoded.cursor == Vector2i(4, 6), "seat state echoes host build mode, item and cursor")
	var keyless := seat_state.duplicate()
	keyless.variant_key = ""
	_check(NetworkPlacementCodec.encode_seat_state(keyless).is_empty(), "an inventory ID requires its item key")
	var oversized := seat_state.duplicate()
	oversized.variant_key = "x".repeat(49)
	_check(NetworkPlacementCodec.encode_seat_state(oversized).is_empty(), "item key longer than 48 bytes rejected")
	var record := _stage_record(11, Vector2(128, 256), 0)
	var header := {"match_id": 1, "round_id": 2, "base_version": 3, "new_version": 4, "commit_tick": 99}
	var parts := NetworkPlacementCodec.encode_terrain_parts(
		header,
		[
			{"op": NetworkPlacementCodec.EditOp.ADD, "entity_id": 11, "record": record},
			{"op": NetworkPlacementCodec.EditOp.REMOVE, "entity_id": 12},
		]
	)
	var commit := NetworkPlacementCodec.decode_terrain_commit(parts[0]) if parts.size() == 1 else {}
	_check(parts.size() == 1 and bool(commit.get("ok", false)), "terrain commit round-trips")
	_check(int(commit.get("base_version", -1)) == 3 and int(commit.get("new_version", -1)) == 4 and commit.edits.size() == 2, "commit keeps base/new versions and both ops")
	_check(int(commit.edits[1].op) == NetworkPlacementCodec.EditOp.REMOVE and int(commit.edits[0].entity.entity_id) == 11, "add carries its record; remove carries only the ID")
	var gap_header := header.duplicate()
	gap_header.new_version = 6
	_check(NetworkPlacementCodec.encode_terrain_parts(gap_header, []).is_empty(), "non-contiguous versions cannot be encoded")
	var too_many: Array = []
	for index in NetworkPlacementCodec.MAX_TERRAIN_EDITS + 1:
		too_many.append({"op": NetworkPlacementCodec.EditOp.REMOVE, "entity_id": index + 1})
	_check(NetworkPlacementCodec.encode_terrain_parts(header, too_many).is_empty(), "more than 16 edits are refused, never truncated")
	var large: Array = []
	for index in NetworkPlacementCodec.MAX_TERRAIN_EDITS:
		large.append({"op": NetworkPlacementCodec.EditOp.ADD, "entity_id": index + 1, "record": _stage_record(index + 1, Vector2(index * 64, 0), 0, "x".repeat(48))})
	var large_parts := NetworkPlacementCodec.encode_terrain_parts(header, large)
	var within_frame := not large_parts.is_empty()
	for part in large_parts:
		within_frame = within_frame and part.size() <= NetworkFrame.MAX_PAYLOAD_BYTES
	_check(within_frame and large_parts.size() <= NetworkPlacementCodec.MAX_TERRAIN_PARTS, "16 maximum-size edits split into at most four frames under 878 bytes")
	var empty_parts := NetworkPlacementCodec.encode_terrain_parts(header, [])
	_check(empty_parts.size() == 1 and bool(NetworkPlacementCodec.decode_terrain_commit(empty_parts[0]).get("ok", false)), "a zero-edit version advance is valid")
	var duplicate_edit := NetworkPlacementCodec.encode_terrain_parts(header, [{"op": NetworkPlacementCodec.EditOp.REMOVE, "entity_id": 5}, {"op": NetworkPlacementCodec.EditOp.REMOVE, "entity_id": 5}])
	_check(not duplicate_edit.is_empty() and not bool(NetworkPlacementCodec.decode_terrain_commit(duplicate_edit[0]).get("ok", true)), "one entity cannot appear twice in a commit")
	var bad_lifecycle := _stage_record(11, Vector2.ZERO, 3)
	_check(not bool(NetworkMatchCodec.decode_stage_record(bad_lifecycle).get("ok", true)), "stage record lifecycle above 2 rejected")
	_check(bool(NetworkMatchCodec.decode_stage_record(_stage_record(11, Vector2.ZERO, 1)).get("ok", false)), "grace lifecycle tell decodes")


func _test_reason_mapping() -> void:
	var expected := {
		"wrong_phase": NetworkFrame.Reason.WRONG_PHASE, "actor_ineligible": NetworkFrame.Reason.WRONG_PHASE,
		"seat_unregistered": NetworkFrame.Reason.OWNERSHIP, "other_seat_item": NetworkFrame.Reason.OWNERSHIP,
		"stale_attempt": NetworkFrame.Reason.STALE_STATE, "stale_round": NetworkFrame.Reason.STALE_STATE,
		"future_stage": NetworkFrame.Reason.STALE_STATE, "rotation_unsupported": NetworkFrame.Reason.FIELD_RANGE,
		"out_of_bounds": NetworkFrame.Reason.FIELD_RANGE, "request_id_reused": NetworkFrame.Reason.REQUEST_ID_REUSE,
		"request_pending": NetworkFrame.Reason.REQUEST_CAPACITY, "boundary_full": NetworkFrame.Reason.REQUEST_CAPACITY,
		"request_limit": NetworkFrame.Reason.REQUEST_CAPACITY, "inventory_missing": NetworkFrame.Reason.INVENTORY,
		"inventory_used": NetworkFrame.Reason.INVENTORY, "inventory_mismatch": NetworkFrame.Reason.INVENTORY,
		"unknown_variant": NetworkFrame.Reason.INVENTORY, "variant_disabled": NetworkFrame.Reason.INVENTORY,
		"protected_spawn": NetworkFrame.Reason.PLACEMENT_BLOCKED, "protected_goal": NetworkFrame.Reason.PLACEMENT_BLOCKED,
		"outside_build_region": NetworkFrame.Reason.PLACEMENT_BLOCKED, "immutable_base": NetworkFrame.Reason.PLACEMENT_BLOCKED,
		"player_clearance": NetworkFrame.Reason.PLACEMENT_BLOCKED, "item_overlap": NetworkFrame.Reason.PLACEMENT_BLOCKED,
		"invalid_region": NetworkFrame.Reason.PLACEMENT_BLOCKED, "mover_sweep": NetworkFrame.Reason.PLACEMENT_BLOCKED,
		"live_effect_path": NetworkFrame.Reason.PLACEMENT_BLOCKED, "persistent_cap": NetworkFrame.Reason.CONTENT_LIMIT_EXCEEDED,
		"round_ended": NetworkFrame.Reason.ROUND_ENDED, "commit_failed": NetworkFrame.Reason.INTERNAL_RETRY,
		"invalid_request_id": NetworkFrame.Reason.MALFORMED,
	}
	var all_mapped := true
	for code in expected:
		all_mapped = all_mapped and NetworkPlacementCodec.reason_for_code(code) == int(expected[code])
	_check(all_mapped, "every P05 pipeline, room and validator code maps to its contract reason")
	_check(NetworkPlacementCodec.reason_for_code("not_a_code") == NetworkFrame.Reason.INTERNAL_RETRY and NetworkPlacementCodec.detail_for_code("not_a_code") == NetworkPlacementCodec.Detail.UNKNOWN, "unknown codes fail closed")
	var all_text := true
	for detail in NetworkPlacementCodec.Detail.values():
		all_text = all_text and not NetworkPlacementCodec.detail_text(int(detail)).is_empty() and int(detail) <= NetworkPlacementCodec.MAX_DETAIL
	_check(all_text, "every detail has client-local text and fits the bound")


func _test_routes_and_local_confirm_flag() -> void:
	_check(GameFlow.route_from_args(PackedStringArray()) == "", "no flag keeps the scheduled default")
	_check(GameFlow.route_from_args(PackedStringArray(["--match-route=network_live_build"])) == GameFlow.ROUTE_NETWORK_LIVE_BUILD, "network live route is an explicit opt-in")
	_check(GameFlow.route_from_args(PackedStringArray(["--match-route=offline_live_build"])) == GameFlow.ROUTE_OFFLINE_LIVE_BUILD, "offline live route unchanged")
	var manager := NetworkSessionManager.new()
	_check(manager.network_route == NetworkSessionManager.ROUTE_SCHEDULED, "session defaults to the scheduled network route")
	manager.free()
	var router := LocalInputRouter.new()
	_check(not router.live_build_confirm_enabled, "keyboard live confirm is off unless a live room enables it")
	router.phase = LocalInputRouter.Phase.PLAY
	_check(router._keyboard_south_action() == "", "default Play keeps south keys free")
	router.live_build_confirm_enabled = true
	_check(router._keyboard_south_action() == "confirm", "live rooms map south keys to confirm in Play")
	router.free()
	_check("build_toggle" in LocalInputRouter.REMOTE_ACTIONS and "live_cancel" in RemoteSeatInputAdapter.ACTIONS, "remote seats can reach build controls")
	_check(NetworkSessionManager.ACTION_NAMES.size() == 15 and NetworkSessionManager.ACTION_NAMES[12] == "build_toggle", "network action IDs 12-14 name the live controls")


func _test_p04_hello_rejected() -> void:
	for case in [[2, NetworkFrame.FEATURE_P04_MASK, false], [3, NetworkFrame.FEATURE_P06_MASK, false], [4, NetworkFrame.FEATURE_REQUIRED_MASK, true]]:
		var manager := CaptureManager.new()
		root.add_child(manager)
		var compatibility := CompatibilityManifest.build()
		manager._cached_compatibility = compatibility
		manager.manifest_digest = compatibility.digest
		manager._manifest_source_stamp = CompatibilityManifest.source_fingerprint()
		manager.candidates[3] = {"state": NetworkSessionManager.CandidateState.COMPATIBILITY, "deadline": 0, "seat": -1}
		var hello := PackedByteArray()
		hello.append_array(manager.manifest_digest)
		hello.append(NetworkFrame.MAJOR)
		hello.append(NetworkFrame.MINOR)
		hello.append_array(PackedByteArray([int(case[0]) & 0xff, 0]))
		hello.append_array(PackedByteArray([int(case[1]) & 0xff, (int(case[1]) >> 8) & 0xff]))
		manager._handle_host_packet(3, NetworkFrame.Family.COMPATIBILITY_HELLO, hello)
		var reply: Dictionary = manager.sent.back() if not manager.sent.is_empty() else {}
		var reason := int(reply.payload.decode_u16(0)) if not reply.is_empty() else -1
		if bool(case[2]):
			_check(reason == NetworkFrame.Reason.OK and int(manager.candidates[3].state) == NetworkSessionManager.CandidateState.CHALLENGE, "schema-4 P07 hello is admitted to the challenge")
		else:
			_check(reason == NetworkFrame.Reason.INCOMPATIBLE, "schema-%d hello is refused as INCOMPATIBLE, never half-admitted" % int(case[0]))
		manager.queue_free()


func _test_match_lifecycle_route_byte() -> void:
	var client := _client_manager()
	var p04_start := PackedByteArray([1, 1, 0, 0, 0, 0, 0, 0, 0])
	client.match_active = false
	client._handle_client_packet(1, NetworkFrame.Family.MATCH_LIFECYCLE, p04_start)
	_check(not client.match_active, "9-byte P04 match start is rejected")
	var p06_start := PackedByteArray([1, 1, 0, 0, 0, 0, 0, 0, 0, NetworkSessionManager.ROUTE_LIVE_BUILD])
	client._handle_client_packet(1, NetworkFrame.Family.MATCH_LIFECYCLE, p06_start)
	_check(not client.match_active, "10-byte P06 match start is rejected under contract v1.4")
	var bad_route := PackedByteArray([1, 1, 0, 0, 0, 0, 0, 0, 0, 2, 0])
	client._handle_client_packet(1, NetworkFrame.Family.MATCH_LIFECYCLE, bad_route)
	_check(not client.match_active, "unknown route byte is rejected")
	var live := PackedByteArray([1, 1, 0, 0, 0, 0, 0, 0, 0, NetworkSessionManager.ROUTE_LIVE_BUILD, 0])
	client._handle_client_packet(1, NetworkFrame.Family.MATCH_LIFECYCLE, live)
	_check(client.match_active and client.client_route == NetworkSessionManager.ROUTE_LIVE_BUILD, "live route byte enables the client live path")
	client.free()


func _test_client_terrain_apply() -> void:
	var client := _client_manager()
	var header := {"match_id": 1, "round_id": 1, "base_version": 0, "new_version": 1, "commit_tick": 10}
	var add_one := NetworkPlacementCodec.encode_terrain_parts(header, [{"op": NetworkPlacementCodec.EditOp.ADD, "entity_id": 11, "record": _stage_record(11, Vector2(64, 64), 1)}])
	client._receive_terrain_commit(add_one[0])
	_check(int(client.client_replica_state.stage_version) == 1 and client.client_replica_state.entities.has(11), "contiguous commit adds the entity and advances the version")
	_check(int(client.client_replica_state.entities[11].lifecycle) == NetworkPlacementCodec.Lifecycle.GRACE, "activation grace tell reaches the replica")
	client._receive_terrain_commit(add_one[0])
	_check(int(client.client_replica_state.stage_version) == 1 and client.client_replica_state.entities.size() == 1, "duplicate commit is idempotent")
	var header_v3 := header.duplicate()
	header_v3.base_version = 2
	header_v3.new_version = 3
	var later := NetworkPlacementCodec.encode_terrain_parts(header_v3, [{"op": NetworkPlacementCodec.EditOp.REMOVE, "entity_id": 11}])
	client._receive_terrain_commit(later[0])
	_check(client.terrain_gap and int(client.client_replica_state.stage_version) == 1 and client.client_replica_state.entities.has(11), "reordered/lost commit is a gap: nothing applied, building disabled")
	_check(not client.client_live_build_available(), "a terrain gap disables edit-dependent actions")
	client._set_terrain_gap(false)
	var header_v2 := header.duplicate()
	header_v2.base_version = 1
	header_v2.new_version = 2
	var remove := NetworkPlacementCodec.encode_terrain_parts(header_v2, [{"op": NetworkPlacementCodec.EditOp.REMOVE, "entity_id": 11}])
	client._receive_terrain_commit(remove[0])
	_check(int(client.client_replica_state.stage_version) == 2 and not client.client_replica_state.entities.has(11), "reliable remove op erases the entity")
	var big: Array = []
	for index in 12:
		big.append({"op": NetworkPlacementCodec.EditOp.ADD, "entity_id": 100 + index, "record": _stage_record(100 + index, Vector2(index * 64, 0), 0, "y".repeat(48))})
	var header_parts := header.duplicate()
	header_parts.base_version = 2
	header_parts.new_version = 3
	var parts := NetworkPlacementCodec.encode_terrain_parts(header_parts, big)
	_check(parts.size() >= 2, "a large commit spans several parts")
	if parts.size() >= 2:
		client._receive_terrain_commit(parts[parts.size() - 1])
		_check(int(client.client_replica_state.stage_version) == 2, "a partial commit is not applied")
		for index in parts.size() - 1:
			client._receive_terrain_commit(parts[index])
		_check(int(client.client_replica_state.stage_version) == 3 and client.client_replica_state.entities.size() == 12, "out-of-order parts apply once complete")
	var stale_state := client.client_replica_state.duplicate(true)
	client._receive_terrain_commit(remove[0])
	_check(client.client_replica_state.entities.size() == stale_state.entities.size(), "an older commit replayed later changes nothing")
	client.free()


func _test_client_ghost_state_machine() -> void:
	var client := _client_manager()
	client.client_live_seat_state = {
		"match_id": 1, "inventory_id": 5, "variant_key": CELL_1X1,
		"item_status": NetworkPlacementCodec.ItemStatus.AVAILABLE, "build_mode": false, "rotation": 0,
		"cursor": Vector2i(3, 4),
	}
	var ghost := NetworkLivePlacementClient.new()
	ghost.bind(client)
	_check(ghost.toggle_build() and ghost.state == NetworkLivePlacementClient.GhostState.TENTATIVE, "Build opens a tentative preview at the host cursor")
	_check(ghost.cell == Vector2i(3, 4) and ghost.ghost_label() == "PREVIEW", "preview is labelled tentative")
	_check(_last_action(client) == NetworkLivePlacementClient.ACTION_BUILD_TOGGLE, "opening tells the host to enter build mode")
	ghost.set_aim(Vector2.RIGHT)
	ghost.set_aim(Vector2.ZERO)
	_check(ghost.cell == Vector2i(4, 4), "an aim tap moves only the ghost one cell")
	_check(ghost.confirm() and ghost.state == NetworkLivePlacementClient.GhostState.PENDING, "Place sends one request and waits")
	var intents := _sent_family(client, NetworkFrame.Family.PLACEMENT_INTENT)
	ghost.confirm()
	var repeats := _sent_family(client, NetworkFrame.Family.PLACEMENT_INTENT)
	_check(intents.size() == 1 and repeats.size() == 2 and repeats[0] == repeats[1], "a repeat tap resends identical bytes with the same request ID")
	var first_id := ghost.request_id
	ghost.apply_result({"request_id": first_id + 50, "status": NetworkPlacementCodec.Status.ACCEPTED, "entity_id": 77, "detail": NetworkPlacementCodec.Detail.COMMITTED})
	_check(ghost.state == NetworkLivePlacementClient.GhostState.PENDING, "a result for another request is ignored")
	ghost.apply_result({"request_id": first_id, "status": NetworkPlacementCodec.Status.QUEUED, "detail": NetworkPlacementCodec.Detail.QUEUED})
	_check(ghost.state == NetworkLivePlacementClient.GhostState.PENDING and ghost.ghost_label() == "SENDING…", "queued acknowledgement keeps the ghost pending")
	ghost.apply_result({"request_id": first_id, "status": NetworkPlacementCodec.Status.ACCEPTED, "entity_id": 77, "cell": Vector2i(4, 4), "rotation": 0, "detail": NetworkPlacementCodec.Detail.COMMITTED})
	_check(ghost.state == NetworkLivePlacementClient.GhostState.ACCEPTED_AWAIT_TERRAIN and not ghost.ghost_label().to_lower().contains("placed"), "acceptance waits for host terrain and is never labelled committed")
	ghost.apply_result({"request_id": first_id, "status": NetworkPlacementCodec.Status.ACCEPTED, "entity_id": 77, "detail": NetworkPlacementCodec.Detail.COMMITTED})
	_check(ghost.state == NetworkLivePlacementClient.GhostState.ACCEPTED_AWAIT_TERRAIN, "a duplicate result after resolution cannot re-commit")
	var entities: Dictionary = client.client_replica_state.entities
	entities[77] = {"entity_id": 77, "variant_key": CELL_1X1, "position": Vector2(256, 256), "rotation": 0}
	client.client_replica_state.entities = entities
	ghost.apply_replica(client.client_replica_state)
	_check(ghost.state == NetworkLivePlacementClient.GhostState.NONE and not ghost.ghost_visible(), "the host's committed entity replaces the ghost")
	ghost.toggle_build()
	ghost.confirm()
	ghost.apply_result({"request_id": ghost.request_id, "status": NetworkPlacementCodec.Status.REJECTED, "reason": NetworkFrame.Reason.PLACEMENT_BLOCKED, "detail": NetworkPlacementCodec.Detail.ITEM_OVERLAP})
	_check(ghost.state == NetworkLivePlacementClient.GhostState.REJECTED and ghost.ghost_label().begins_with("✕") and ghost.notice == NetworkPlacementCodec.detail_text(NetworkPlacementCodec.Detail.ITEM_OVERLAP), "a rejected ghost shows a cross and its localized reason")
	ghost.reset()
	ghost.toggle_build()
	var before_cancel := _sent_family(client, NetworkFrame.Family.PLACEMENT_INTENT).size()
	ghost.cancel()
	_check(ghost.state == NetworkLivePlacementClient.GhostState.NONE and _last_action(client) == NetworkLivePlacementClient.ACTION_LIVE_CANCEL, "Cancel closes the preview through the idempotent cancel action")
	_check(_sent_family(client, NetworkFrame.Family.PLACEMENT_INTENT).size() == before_cancel, "closing build mode never confirms")
	ghost.toggle_build()
	client._set_terrain_gap(true)
	_check(not ghost.can_confirm() and not ghost.confirm(), "Place is disabled while the stage resyncs")
	ghost.unbind()
	client.free()


func _test_host_placement_path() -> void:
	var fixture: Dictionary = await _live_fixture(73)
	if fixture.is_empty():
		return
	var manager: CaptureManager = fixture.manager
	var room: NLBP06NetworkLiveBuildMatchRoom = fixture.room
	var remote_seat := int(fixture.remote_seat)
	var cells: Array[Vector2i] = _valid_cells(room, 2)
	if cells.size() < 2:
		_check(false, "two valid live cells exist for the network fixture")
		await _free_fixture(fixture)
		return
	var boundary_results: Array = []
	room.live_placement_boundary_resolved.connect(func(results: Array) -> void: boundary_results.append_array(results))
	manager._send_terrain_commit_if_changed()
	var round_value := room.items.round_number + 1
	var remote_payload := _remote_intent(room, remote_seat, 1, cells[1])
	manager._receipt_usec = 5000
	manager._accept_placement_intent(REMOTE_PEER, remote_payload, manager.candidates[REMOTE_PEER])
	var queued := _results(manager)
	_check(queued.size() == 1 and int(queued[0].status) == NetworkPlacementCodec.Status.QUEUED, "a valid intent is queued and acknowledged")
	var local_receipt := room.network_submit_placement(
		0, {"request_id": 900, "peer_generation": 0, "inventory_id": int(room._inventory_ids[0]), "expected_stage_version": room.items.stage_version, "cell": cells[0], "rotation": 0}, 5000
	)
	_check(str(local_receipt.get("status", "")) == "pending", "a second seat with the identical receipt time is queued at the same boundary")
	manager._accept_placement_intent(REMOTE_PEER, remote_payload, manager.candidates[REMOTE_PEER])
	var after_retry := _results(manager)
	_check(after_retry.size() == 2 and _result_bytes(manager)[0] == _result_bytes(manager)[1] and room.request_pipeline.pending.size() == 2, "an exact retry replays the cached response without a second submission")
	var reused := _remote_intent(room, remote_seat, 1, cells[0])
	manager._accept_placement_intent(REMOTE_PEER, reused, manager.candidates[REMOTE_PEER])
	_check(int(_results(manager).back().reason) == NetworkFrame.Reason.REQUEST_ID_REUSE, "a changed payload under a used request ID is REQUEST_ID_REUSE")
	for _frame in range(4):
		if not boundary_results.is_empty():
			break
		await physics_frame
	var sorted_seats := [0, remote_seat]
	sorted_seats.sort()
	var expected_first := int(sorted_seats[posmod(round_value, sorted_seats.size())])
	_check(boundary_results.size() == 2 and int(boundary_results[0].seat_index) == expected_first, "equal host receipt times resolve by round-rotated seat priority through the network path")
	_check(room.items.stage_version == 1 and room.items.pieces.size() == 2, "one boundary commits both edits and bumps the stage version once")
	var families := manager.sent.map(func(entry: Dictionary) -> int: return int(entry.family))
	var commit_index := families.find(NetworkFrame.Family.TERRAIN_COMMIT)
	var accepted_index := -1
	for index in manager.sent.size():
		if int(manager.sent[index].family) == NetworkFrame.Family.PLACEMENT_RESULT and int(NetworkPlacementCodec.decode_result(manager.sent[index].payload).status) == NetworkPlacementCodec.Status.ACCEPTED:
			accepted_index = index
	_check(commit_index >= 0 and accepted_index > commit_index, "the terrain commit precedes the acceptance on the reliable channel")
	var commit := NetworkPlacementCodec.decode_terrain_commit(manager.sent[commit_index].payload) if commit_index >= 0 else {}
	var accepted := NetworkPlacementCodec.decode_result(manager.sent[accepted_index].payload) if accepted_index >= 0 else {}
	var commit_ids: Array = []
	for edit in commit.get("edits", []):
		commit_ids.append(int(edit.entity_id))
	_check(int(commit.get("base_version", -1)) == 0 and int(commit.get("new_version", -1)) == 1 and commit_ids.size() == 2, "terrain diff sends only the two added entities with base 0 -> new 1")
	_check(commit_ids.has(int(accepted.get("entity_id", -1))) and int(accepted.get("stage_version", -1)) == 1, "acceptance names a committed entity and the new stage version")
	_check(not room.inventory_used.is_empty() and bool(room.inventory_used.get(remote_seat, false)), "the remote item is consumed exactly once")
	manager._accept_placement_intent(REMOTE_PEER, remote_payload, manager.candidates[REMOTE_PEER])
	var replay := NetworkPlacementCodec.decode_result(_result_bytes(manager).back())
	_check(int(replay.status) == NetworkPlacementCodec.Status.ACCEPTED and room.items.stage_version == 1 and room.items.pieces.size() == 2, "a lost-result retry returns the cached acceptance with no double commit")
	manager._placement_new_id_times.clear()
	manager._accept_placement_intent(REMOTE_PEER, _remote_intent(room, remote_seat, 2, cells[0]), manager.candidates[REMOTE_PEER])
	_check(int(_results(manager).back().reason) == NetworkFrame.Reason.INVENTORY, "a used item rejects a new request as INVENTORY")
	var foreign := _remote_intent(room, remote_seat, 3, cells[0], int(room._inventory_ids[0]))
	manager._accept_placement_intent(REMOTE_PEER, foreign, manager.candidates[REMOTE_PEER])
	_check(int(_results(manager).back().reason) == NetworkFrame.Reason.OWNERSHIP, "another seat's inventory ID is OWNERSHIP")
	manager._placement_new_id_times.clear()
	for request_id in [10, 11, 12]:
		manager._accept_placement_intent(REMOTE_PEER, _remote_intent(room, remote_seat, request_id, cells[0]), manager.candidates[REMOTE_PEER])
	_check(int(_results(manager).back().reason) == NetworkFrame.Reason.RATE_LIMIT, "more than two new request IDs per second are RATE_LIMIT")
	var cache: Dictionary = manager._placement_cache[REMOTE_PEER]
	var saved_cache := cache.duplicate(true)
	cache.clear()
	for index in NetworkSessionManager.PLACEMENT_CACHE_CAP:
		cache["%d:%d" % [GENERATION, 1000 + index]] = {"hash": "", "response": PackedByteArray(), "time": Time.get_ticks_msec(), "terminal": false}
	manager._placement_cache[REMOTE_PEER] = cache
	manager._placement_new_id_times.clear()
	manager._accept_placement_intent(REMOTE_PEER, _remote_intent(room, remote_seat, 20, cells[0]), manager.candidates[REMOTE_PEER])
	_check(int(_results(manager).back().reason) == NetworkFrame.Reason.REQUEST_CAPACITY and cache.size() == NetworkSessionManager.PLACEMENT_CACHE_CAP, "a cache full of in-flight requests answers REQUEST_CAPACITY and evicts nothing")
	manager._placement_cache[REMOTE_PEER] = saved_cache
	manager.network_route = NetworkSessionManager.ROUTE_SCHEDULED
	manager._placement_new_id_times.clear()
	manager._accept_placement_intent(REMOTE_PEER, _remote_intent(room, remote_seat, 21, cells[0]), manager.candidates[REMOTE_PEER])
	var scheduled := _results(manager).back()
	_check(int(scheduled.reason) == NetworkFrame.Reason.WRONG_PHASE and int(scheduled.detail) == NetworkPlacementCodec.Detail.WRONG_ROUTE, "placement intents are refused on the scheduled route")
	_check(not manager._action_phase_allowed(12), "build actions are refused on the scheduled route")
	manager.network_route = NetworkSessionManager.ROUTE_LIVE_BUILD
	_check(manager._action_phase_allowed(12) and manager._action_phase_allowed(14), "build actions are allowed in Play on the live route")
	room.phase_controller.phase = MatchPhaseController.Phase.GO
	_check(manager._input_phase_eligible() and not manager._action_phase_allowed(0) and not manager._action_phase_allowed(12), "GO keeps live input eligible but allows no action")
	manager._host_input_state[REMOTE_PEER] = {"generation": GENERATION, "last_valid_ms": Time.get_ticks_msec(), "last_sequence": -1, "timed_out": true, "await_neutral": false}
	var moving := NetworkMatchCodec.encode_input({
		"match_id": 1, "round_id": room.network_current_round_id(), "attempt_id": int(room.match_run_id) & 0xffff,
		"peer_generation": GENERATION, "sequence": 1, "client_tick": 1, "axes": [900, 0], "aim": [0, 1000],
		"held": NetworkMatchCodec.HELD_JUMP, "build_mode": true, "edge_watermark": 0,
	})
	manager._accept_continuous_input(REMOTE_PEER, moving, manager.candidates[REMOTE_PEER])
	var pending_sample: Dictionary = manager._pending_continuous.get(REMOTE_PEER, {})
	_check(not pending_sample.is_empty() and pending_sample.axes == [0, 0] and int(pending_sample.held) == 0 and not bool(pending_sample.build_mode), "GO input stays bound but is applied as neutral")
	manager.network_route = NetworkSessionManager.ROUTE_SCHEDULED
	_check(not manager._input_phase_eligible(), "the scheduled route keeps its P04 GO gating")
	manager.network_route = NetworkSessionManager.ROUTE_LIVE_BUILD
	room.phase_controller.phase = MatchPhaseController.Phase.PLAY
	var client := _client_manager()
	client.client_replica_state.stage_version = 0
	for entry in manager.sent:
		if int(entry.family) == NetworkFrame.Family.TERRAIN_COMMIT:
			client._receive_terrain_commit(entry.payload)
	var host_ids: Array = []
	for instance_id in room.items.pieces.keys():
		host_ids.append(room.network_entity_id_for(str(instance_id)))
	host_ids.sort()
	var client_ids: Array = client.client_replica_state.entities.keys()
	client_ids.sort()
	_check(host_ids == client_ids and int(client.client_replica_state.stage_version) == room.items.stage_version, "terrain diff audit: client entity IDs and stage version converge on the host")
	client.free()
	var pending_before := room.request_pipeline.pending.size()
	var spoofed := NetworkPlacementCodec.encode_intent(_intent_fields(30, cells[0], 0, int(room._inventory_ids[remote_seat]), room, GENERATION + 1))
	manager._accept_placement_intent(REMOTE_PEER, spoofed, manager.candidates[REMOTE_PEER])
	var last: Dictionary = manager.sent.back()
	_check(int(last.family) == NetworkFrame.Family.ADMISSION_DECISION and room.request_pipeline.pending.size() == pending_before, "a spoofed peer generation never reaches the pipeline")
	await _free_fixture(fixture)


func _test_round_end_and_disconnect() -> void:
	var fixture: Dictionary = await _live_fixture(91)
	if fixture.is_empty():
		return
	var manager: CaptureManager = fixture.manager
	var room: NLBP06NetworkLiveBuildMatchRoom = fixture.room
	var remote_seat := int(fixture.remote_seat)
	var cells: Array[Vector2i] = _valid_cells(room, 1)
	if cells.is_empty():
		_check(false, "a valid live cell exists for the round-end fixture")
		await _free_fixture(fixture)
		return
	manager._accept_placement_intent(REMOTE_PEER, _remote_intent(room, remote_seat, 1, cells[0]), manager.candidates[REMOTE_PEER])
	var sent_before := _results(manager).size()
	manager._clear_live_placement_peer(REMOTE_PEER)
	_check(room.request_pipeline.pending.is_empty() and not bool(room.inventory_used.get(remote_seat, false)), "a disconnect cancels the queued request and keeps the item")
	_check(_results(manager).size() == sent_before and manager._placement_inflight.is_empty(), "nothing is answered to a disconnected peer")
	var round_results: Array = []
	room.live_placement_boundary_resolved.connect(func(results: Array) -> void: round_results.append_array(results))
	manager._placement_new_id_times.clear()
	manager._accept_placement_intent(REMOTE_PEER, _remote_intent(room, remote_seat, 2, cells[0]), manager.candidates[REMOTE_PEER])
	room._close_live_attempt()
	room._close_live_attempt()
	var ended := _results(manager).filter(func(result: Dictionary) -> bool: return int(result.reason) == NetworkFrame.Reason.ROUND_ENDED)
	_check(ended.size() == 1 and round_results.size() == 1, "a round close answers each queued request with ROUND_ENDED exactly once")
	_check(not bool(room.inventory_used.get(remote_seat, false)) and room.items.stage_version == 0, "ROUND_ENDED commits nothing and retains the item")
	manager._accept_placement_intent(REMOTE_PEER, _remote_intent(room, remote_seat, 2, cells[0]), manager.candidates[REMOTE_PEER])
	_check(int(_results(manager).back().reason) == NetworkFrame.Reason.ROUND_ENDED, "a late retry receives the cached ROUND_ENDED")
	await _free_fixture(fixture)


# --- fixtures -------------------------------------------------------------------------------


func _live_fixture(seed_value: int) -> Dictionary:
	var host := SimulationAuthority.host()
	var router := LocalInputRouter.new()
	root.add_child(router)
	router.set_authority(host)
	var manager := CaptureManager.new()
	manager.configure(router)
	root.add_child(manager)
	manager.host_authority = host
	manager.remote_adapter.configure(router, host)
	router.registry.join_keyboard("K1")
	var remote_seat := manager.remote_adapter.assign_source(REMOTE_SOURCE)
	router.registry.set_ready(0, true)
	router.registry.set_ready(remote_seat, true)
	var room := LIVE_NETWORK_ROOM.instantiate() as NLBP06NetworkLiveBuildMatchRoom
	room.input_router = router
	room.simulation_authority = host
	room.go_countdown_seconds = 0.1
	# NLB-P07: the P06 slice cells are ENGINEERING; the fixture runs under the development override.
	room.unverified_content = true
	root.add_child(room)
	await process_frame
	room.set_match_seed(seed_value)
	room.tuning.match_target_score_units = 100000
	manager.network_route = NetworkSessionManager.ROUTE_LIVE_BUILD
	manager.match_active = true
	manager.active_match_id = 1
	manager.bind_match_room(room)
	manager.candidates[REMOTE_PEER] = {
		"state": NetworkSessionManager.CandidateState.READY, "deadline": 0, "seat": remote_seat,
		"peer_generation": GENERATION, "match_sync_ready": true,
	}
	var fixture := {"manager": manager, "room": room, "router": router, "remote_seat": remote_seat}
	if remote_seat < 0 or not room.start_match():
		_check(false, "network live fixture starts with one local and one remote seat")
		await _free_fixture(fixture)
		return {}
	for seat_index in [0, remote_seat]:
		var egg: Dictionary = room.egg_pool[seat_index]
		egg.variant_key = CELL_1X1
		room.egg_pool[seat_index] = egg
		room._queue_claim(seat_index, str(egg.egg_id))
	room._flush_claims()
	_check(room.phase_controller.phase == MatchPhaseController.Phase.GO and room._inventory_ids.size() == 2, "Pugad assignment enters GO and issues one host inventory ID per seat")
	room._process(0.2)
	if room.phase_controller.phase != MatchPhaseController.Phase.PLAY:
		_check(false, "GO releases the network live round into Play")
		await _free_fixture(fixture)
		return {}
	manager.sent.clear()
	return fixture


func _free_fixture(fixture: Dictionary) -> void:
	for key in ["room", "manager", "router"]:
		var node: Node = fixture.get(key)
		if node != null and is_instance_valid(node):
			node.queue_free()
	await process_frame


func _valid_cells(room: NLBP06NetworkLiveBuildMatchRoom, count: int) -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	var actor_rects := room._live_actor_swept_rects()
	for y in range(room.tuning.arena_height_tiles):
		for x in range(room.tuning.arena_width_tiles):
			var cell := Vector2i(x, y)
			var verdict := room.items.validate_placement(CELL_1X1, cell, 0, room.items.owner_seat_clearance(actor_rects))
			var spaced := true
			for other in found:
				spaced = spaced and absi(other.x - cell.x) > 1
			if bool(verdict.allowed) and spaced:
				found.append(cell)
				if found.size() >= count:
					return found
	return found


func _client_manager() -> CaptureManager:
	var client := CaptureManager.new()
	client.client_mode = true
	client.match_active = true
	client.sync_ready = true
	client.active_match_id = 1
	client.client_route = NetworkSessionManager.ROUTE_LIVE_BUILD
	client.client_assigned_seat = 1
	client.assigned_peer_generation = GENERATION
	client.client_replica_state = {
		"match_id": 1, "round_id": 1, "attempt_id": 1, "stage_version": 0, "seats": {}, "entities": {},
		"metadata": {"phase": MatchPhaseController.Phase.PLAY},
	}
	return client


func _intent_fields(request_id: int, cell: Vector2i, rotation: int, inventory_id: int, room: NLBP06NetworkLiveBuildMatchRoom = null, generation: int = GENERATION) -> Dictionary:
	return {
		"request_id": request_id,
		"match_id": 1,
		"round_id": room.network_current_round_id() if room != null else 1,
		"attempt_id": (int(room.match_run_id) & 0xffff) if room != null else 1,
		"peer_generation": generation,
		"expected_stage_version": room.items.stage_version if room != null else 0,
		"inventory_id": inventory_id,
		"cell": cell,
		"rotation": rotation,
	}


func _remote_intent(room: NLBP06NetworkLiveBuildMatchRoom, remote_seat: int, request_id: int, cell: Vector2i, inventory_id: int = -1) -> PackedByteArray:
	var item_id := inventory_id if inventory_id >= 0 else int(room._inventory_ids[remote_seat])
	return NetworkPlacementCodec.encode_intent(_intent_fields(request_id, cell, 0, item_id, room))


func _stage_record(entity_id: int, position: Vector2, lifecycle: int, key: String = CELL_1X1) -> PackedByteArray:
	return NetworkMatchCodec.encode_stage_record({
		"entity_id": entity_id, "variant_key": key, "position": position, "velocity": Vector2.ZERO,
		"rotation": 0, "lifecycle": lifecycle, "state_flags": 1, "timer_ms": 750, "revision": 1,
	})


func _results(manager: CaptureManager) -> Array:
	var decoded: Array = []
	for payload in _result_bytes(manager):
		decoded.append(NetworkPlacementCodec.decode_result(payload))
	return decoded


func _result_bytes(manager: CaptureManager) -> Array:
	return _sent_family(manager, NetworkFrame.Family.PLACEMENT_RESULT)


func _sent_family(manager: CaptureManager, family: int) -> Array:
	var payloads: Array = []
	for entry in manager.sent:
		if int(entry.family) == family:
			payloads.append(entry.payload)
	return payloads


func _last_action(manager: CaptureManager) -> int:
	var actions := _sent_family(manager, NetworkFrame.Family.ACTION_REQUEST)
	if actions.is_empty():
		return -1
	return int(NetworkMatchCodec.decode_action_request(actions.back()).get("action", -1))


func _check(condition: bool, label: String) -> void:
	checks += 1
	if condition:
		print("PASS ", label)
	else:
		failures += 1
		push_error("FAIL " + label)

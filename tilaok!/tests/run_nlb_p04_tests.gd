# gdlint: disable=max-line-length
extends SceneTree

var failures: Array[String] = []
var checks := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_wire_channels_and_inputs()
	_test_typed_state_records_and_snapshots()
	_test_host_logical_input_boundary()
	_test_teardown_cycles()
	if failures.is_empty():
		print("NLB_P04_TESTS PASSED checks=%d" % checks)
		quit(0)
	else:
		for failure in failures:
			push_error("NLB_P04_TEST_FAILED " + failure)
		print("NLB_P04_TESTS FAILED checks=%d failures=%d" % [checks, failures.size()])
		quit(1)


func _test_wire_channels_and_inputs() -> void:
	# NLB-P06 (v1.3) raised the schema to 3 and NLB-P07 (v1.4) to 4; the envelope stays 1.2 and P04 families keep their layout.
	_check(NetworkFrame.MAJOR == 1 and NetworkFrame.MINOR == 2 and NetworkFrame.SCHEMA == 5, "P04 wire version (schema 5 since NLB-P08)")
	_check(NetworkFrame.family_allowed_on_channel(NetworkFrame.Family.CONTINUOUS_INPUT, RawEnetTransport.INPUT_CHANNEL), "continuous input channel")
	_check(not NetworkFrame.family_allowed_on_channel(NetworkFrame.Family.CONTINUOUS_INPUT, RawEnetTransport.CONTROL_CHANNEL), "input wrong channel rejected")
	_check(NetworkFrame.family_allowed_on_channel(NetworkFrame.Family.STATE_UPDATE, RawEnetTransport.STATE_CHANNEL), "state channel")
	_check(not NetworkFrame.family_allowed_on_channel(NetworkFrame.Family.STATE_UPDATE, RawEnetTransport.INPUT_CHANNEL), "state wrong channel rejected")
	_check(RawEnetTransport.CHANNEL_COUNT == 3, "matching three-channel configuration")
	_check(ENetPacketPeer.FLAG_RELIABLE == 1, "reliable control flag value")
	var sample := _sample()
	var encoded := NetworkMatchCodec.encode_input(sample)
	var decoded := NetworkMatchCodec.decode_input(encoded)
	_check(encoded.size() == NetworkMatchCodec.INPUT_BYTES and bool(decoded.get("ok", false)), "continuous sample round trip")
	_check(decoded.axes == sample.axes and decoded.aim == sample.aim and int(decoded.held) == int(sample.held), "continuous fields retained")
	var invalid := sample.duplicate(true)
	invalid.axes = [1001, 0]
	_check(NetworkMatchCodec.encode_input(invalid).is_empty(), "out-of-range axis rejected without clamping")
	_check(not NetworkMatchCodec.decode_input(encoded.slice(0, encoded.size() - 1)).get("ok", false), "short input rejected")
	var action := {
		"request_id": 9, "match_id": 1, "round_id": 2, "attempt_id": 3,
		"peer_generation": 4, "edge_sequence": 5, "action": 0,
		"target_id": 0, "cell": Vector2i.ZERO, "rotation": 0,
		"pressed": true, "client_tick": 7,
	}
	var action_bytes := NetworkMatchCodec.encode_action_request(action)
	var action_decoded := NetworkMatchCodec.decode_action_request(action_bytes)
	_check(action_bytes.size() == NetworkMatchCodec.ACTION_REQUEST_BYTES and bool(action_decoded.get("ok", false)), "reliable action shape")
	_check(bool(action_decoded.pressed) and int(action_decoded.edge_sequence) == 5, "action edge and pressed state")
	var oversized := PackedByteArray()
	oversized.resize(NetworkFrame.MAX_FRAME_BYTES + 1)
	_check(not NetworkFrame.decode(oversized).get("ok", false), "oversized full frame rejected")


func _test_typed_state_records_and_snapshots() -> void:
	var metadata := {
		"match_id": 1, "round_id": 2, "attempt_id": 3, "tick": 60,
		"stage_version": 4, "snapshot_id": 5, "event_revision": 6,
		"host_time_ms": 7, "phase": MatchPhaseController.Phase.PLAY,
		"paused": false, "remaining_ms": 9000, "map_id": "default",
		"camera_position": Vector2(40.25, 80.5), "camera_zoom": 0.625, "event_main": 0,
		"event_twist": 255, "barya_state": BaryaRoundObjective.State.AVAILABLE,
		"carrier_seat": -1, "receipt_seat": -1, "rng_decision_id": 99,
	}
	var metadata_bytes := NetworkMatchCodec.encode_metadata(metadata)
	var metadata_decoded := NetworkMatchCodec.decode_metadata(metadata_bytes)
	_check(bool(metadata_decoded.get("ok", false)), "metadata schema round trip")
	_check(metadata_decoded.camera_position == metadata.camera_position and is_equal_approx(metadata_decoded.camera_zoom, metadata.camera_zoom) and int(metadata_decoded.rng_decision_id) == 99, "camera framing and event identity fixed point")
	var seat := NetworkMatchCodec.encode_seat_record({"seat": 0, "identity": 1, "shape_id": 0, "status": 0, "position": Vector2(10, 20), "velocity": Vector2.ZERO}, 125)
	var entity := NetworkMatchCodec.encode_stage_record({"entity_id": 22, "variant_key": "build.hollow_blocks.cell_1x1", "position": Vector2(100, 120), "velocity": Vector2(0, 4), "rotation": 1, "state_flags": 3, "timer_ms": 400, "revision": 4})
	var objective := NetworkMatchCodec.encode_objective_record({"kind": 1, "state": BaryaRoundObjective.State.AVAILABLE, "carrier_seat": -1, "receipt_seat": -1, "position": Vector2(240, 320), "round_id": 2, "attempt_id": 3})
	var event_context := NetworkMatchCodec.encode_event_context_record({"event_main": 0, "event_twist": 255, "next_main": 1, "next_twist": 255, "taya_seat": -1, "event_clock_ms": 5000, "event_revision": 6, "rng_decision_id": 99, "markers": {}})
	_check(NetworkMatchCodec.decode_seat_record(seat).get("ok", false), "seat record validates")
	_check(NetworkMatchCodec.decode_stage_record(entity).get("ok", false), "stage record validates")
	_check(NetworkMatchCodec.decode_objective_record(objective).get("ok", false), "objective record validates")
	_check(NetworkMatchCodec.decode_event_context_record(event_context).get("ok", false), "event context validates")
	var snapshot := NetworkMatchCodec.pack_snapshot([seat, entity, objective, event_context])
	var unpacked := NetworkMatchCodec.unpack_snapshot(snapshot)
	_check(bool(unpacked.get("ok", false)) and unpacked.records.size() == 4, "bounded typed snapshot round trip")
	_check(NetworkMatchCodec.crc32(snapshot) == NetworkMatchCodec.crc32(snapshot.duplicate()), "snapshot checksum stable")
	var damaged := snapshot.duplicate()
	damaged[6] = 0
	_check(not NetworkMatchCodec.unpack_snapshot(damaged).get("ok", false), "corrupt typed record rejected")
	var update := NetworkMatchCodec.encode_state_update(metadata, 61, 4, seat)
	var state_decoded := NetworkMatchCodec.decode_state_update(update)
	_check(bool(state_decoded.get("ok", false)) and int(state_decoded.tick) == 61, "full entity state update validates")
	_check(update.size() + NetworkFrame.HEADER_BYTES <= NetworkFrame.MAX_FRAME_BYTES, "state frame stays within 900-byte cap")


func _test_host_logical_input_boundary() -> void:
	var router := LocalInputRouter.new()
	root.add_child(router)
	var host := SimulationAuthority.host()
	_check(router.set_authority(host), "host authority accepts logical router")
	router.set_phase(LocalInputRouter.Phase.PLAY)
	var adapter := RemoteSeatInputAdapter.new()
	_check(adapter.configure(router, host), "remote adapter uses host authority")
	var seat := adapter.assign_source("peer_41")
	_check(seat == 0, "host assigns source to first empty seat")
	_check(adapter.submit_sample("peer_41", [1000, 0], [0, 0], NetworkMatchCodec.HELD_JUMP, false), "source-only sample accepted through production adapter")
	_check(is_equal_approx(router.movement_axis(seat), 1.0), "remote axis reaches its bound seat")
	_check(router.is_action_held(seat, "jump"), "jump held state reaches its bound seat")
	_check(not adapter.submit_sample("peer_999", [0, 0], [0, 0], 0, false), "unowned source rejected")
	_check(not adapter.submit_sample("peer_41", [1001, 0], [0, 0], 0, false), "adapter rejects out-of-range axes")
	router.clear_remote_source("peer_41")
	_check(not router.is_action_held(seat, "jump") and is_zero_approx(router.movement_axis(seat)), "neutralization releases axes and held actions")
	root.remove_child(router)
	router.free()


func _test_teardown_cycles() -> void:
	for cycle in 10:
		var router := LocalInputRouter.new()
		root.add_child(router)
		var manager := NetworkSessionManager.new()
		manager.configure(router)
		root.add_child(manager)
		manager.stop_session()
		root.remove_child(manager)
		manager.free()
		root.remove_child(router)
		router.free()
	_check(true, "ten manager/router teardown cycles")


func _sample() -> Dictionary:
	return {
		"match_id": 1, "round_id": 2, "attempt_id": 3,
		"peer_generation": 4, "sequence": 5, "client_tick": 6,
		"axes": [1000, -1000], "aim": [0, 250], "held": NetworkMatchCodec.HELD_JUMP,
		"build_mode": false, "edge_watermark": 7,
	}


func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)

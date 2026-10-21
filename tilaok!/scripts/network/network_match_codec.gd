class_name NetworkMatchCodec
extends RefCounted

## Bounded little-endian codecs for the P04 gameplay stream. These codecs never call get_var(),
## get_string_from_utf8() without a checked length, or deserialize Godot Objects/Resources.

const SNAPSHOT_CAP := 65536
const SNAPSHOT_CHUNK_BYTES := 858
const SNAPSHOT_CHUNK_HEADER_BYTES := 20
const MAX_SNAPSHOT_CHUNKS := 77
const MAX_SEATS := 4
const MAX_STAGE_ENTITIES := 48
const MAX_ID_BYTES := 48
const WORLD_SCALE := 256
const INPUT_BYTES := 41
const ACTION_REQUEST_BYTES := 53
const META_SCHEMA := 2
const RECORD_SEAT := 1
const RECORD_STAGE_ENTITY := 2
const RECORD_TOMBSTONE := 3
const RECORD_OBJECTIVE := 4
const RECORD_EVENT_CONTEXT := 5
## Contract v1.4 (NLB-P07): host-owned live transients and their bounded end notice.
const RECORD_TRANSIENT := 6
const RECORD_TRANSIENT_END := 7
const TRANSIENT_BYTES := 37
const TRANSIENT_END_BYTES := 4
const TRANSIENT_PROJECTILE := 1
const TRANSIENT_BUBBLE := 2
const TRANSIENT_BLAST := 3
const TRANSIENT_MOVER := 4
## Per-kind wire caps (contract v1 §1 offline tuning caps; movers inherit the persistent cap).
const TRANSIENT_CAPS := {
	TRANSIENT_PROJECTILE: 16,
	TRANSIENT_BUBBLE: 4,
	TRANSIENT_BLAST: 32,
	TRANSIENT_MOVER: 48,
}
const MAX_TRANSIENTS := 100
## Contract v1.6 (NLB-P09): one snapshot record per committed ledger entry (type byte + the
## RESULT_EVENT payload), at most NetworkResultsCodec.MAX_ENTRIES per match.
const RECORD_LEDGER := 8
const MAX_LEDGER_RECORDS := NetworkResultsCodec.MAX_ENTRIES
const MAX_SNAPSHOT_RECORDS := (
	MAX_SEATS + MAX_STAGE_ENTITIES + 8 + MAX_TRANSIENTS + MAX_LEDGER_RECORDS
)
const HELD_LEFT := 1 << 0
const HELD_RIGHT := 1 << 1
const HELD_UP := 1 << 2
const HELD_DOWN := 1 << 3
const HELD_JUMP := 1 << 4
const HELD_SNEAK := 1 << 5


static func encode_input(sample: Dictionary) -> PackedByteArray:
	var seatless := StreamPeerBuffer.new()
	seatless.big_endian = false
	var axes: Array = sample.get("axes", [0, 0])
	var aim: Array = sample.get("aim", [0, 0])
	if axes.size() != 2 or aim.size() != 2:
		return PackedByteArray()
	if (
		int(sample.get("match_id", 0)) <= 0
		or int(sample.get("round_id", -1)) < 0
		or int(sample.get("round_id", -1)) > 0xffffffff
		or int(sample.get("attempt_id", -1)) < 0
		or int(sample.get("attempt_id", -1)) > 0xffff
		or int(sample.get("peer_generation", 0)) <= 0
		or int(sample.get("peer_generation", 0)) > 0xffffffff
		or int(sample.get("sequence", -1)) < 0
		or int(sample.get("sequence", -1)) > 0xffffffff
		or int(sample.get("client_tick", -1)) < 0
		or int(sample.get("client_tick", -1)) > 0xffffffff
		or int(sample.get("held", -1)) < 0
		or (int(sample.get("held", -1)) & ~0x3f) != 0
		or int(sample.get("edge_watermark", -1)) < 0
		or int(sample.get("edge_watermark", -1)) > 0xffffffff
	):
		return PackedByteArray()
	for value in axes + aim:
		if int(value) < -1000 or int(value) > 1000:
			return PackedByteArray()
	seatless.put_u64(int(sample.get("match_id", 0)))
	seatless.put_u32(int(sample.get("round_id", 0)))
	seatless.put_u16(int(sample.get("attempt_id", 0)))
	seatless.put_u32(int(sample.get("peer_generation", 0)))
	seatless.put_u32(int(sample.get("sequence", 0)))
	seatless.put_u32(int(sample.get("client_tick", 0)))
	seatless.put_16(int(axes[0]))
	seatless.put_16(int(axes[1]))
	seatless.put_16(int(aim[0]))
	seatless.put_16(int(aim[1]))
	seatless.put_u16(int(sample.get("held", 0)))
	seatless.put_u8(1 if bool(sample.get("build_mode", false)) else 0)
	seatless.put_u32(int(sample.get("edge_watermark", 0)))
	return seatless.data_array if seatless.data_array.size() == INPUT_BYTES else PackedByteArray()


static func decode_input(payload: PackedByteArray) -> Dictionary:
	if payload.size() != INPUT_BYTES:
		return {"ok": false}
	var stream := _reader(payload)
	var sample := {
		"match_id": stream.get_u64(),
		"round_id": stream.get_u32(),
		"attempt_id": stream.get_u16(),
		"peer_generation": stream.get_u32(),
		"sequence": stream.get_u32(),
		"client_tick": stream.get_u32(),
		"axes": [stream.get_16(), stream.get_16()],
		"aim": [stream.get_16(), stream.get_16()],
		"held": stream.get_u16(),
		"build_mode": stream.get_u8(),
		"edge_watermark": stream.get_u32(),
	}
	for value in sample.axes + sample.aim:
		if int(value) < -1000 or int(value) > 1000:
			return {"ok": false}
	if int(sample.build_mode) > 1 or (int(sample.held) & ~0x3f) != 0:
		return {"ok": false}
	sample.ok = true
	return sample


static func encode_action_request(request: Dictionary) -> PackedByteArray:
	var action := int(request.get("action", -1))
	var request_id := int(request.get("request_id", 0))
	var target_id := int(request.get("target_id", 0))
	var cell: Vector2i = request.get("cell", Vector2i.ZERO)
	var rotation := int(request.get("rotation", 0))
	if (
		request_id <= 0
		or int(request.get("match_id", 0)) <= 0
		or action < 0 or action > 31
		or rotation < 0 or rotation > 3
		or int(request.get("round_id", -1)) < 0 or int(request.get("round_id", -1)) > 0xffffffff
		or int(request.get("attempt_id", -1)) < 0 or int(request.get("attempt_id", -1)) > 0xffff
		or int(request.get("peer_generation", 0)) <= 0 or int(request.get("peer_generation", 0)) > 0xffffffff
		or int(request.get("edge_sequence", 0)) <= 0 or int(request.get("edge_sequence", 0)) > 0xffffffff
		or int(request.get("client_tick", -1)) < 0 or int(request.get("client_tick", -1)) > 0xffffffff
	):
		return PackedByteArray()
	var stream := StreamPeerBuffer.new()
	stream.big_endian = false
	stream.put_u64(request_id)
	stream.put_u64(int(request.get("match_id", 0)))
	stream.put_u32(int(request.get("round_id", 0)))
	stream.put_u16(int(request.get("attempt_id", 0)))
	stream.put_u32(int(request.get("peer_generation", 0)))
	stream.put_u32(int(request.get("edge_sequence", 0)))
	stream.put_u8(action)
	stream.put_u64(target_id)
	stream.put_32(cell.x)
	stream.put_32(cell.y)
	stream.put_u8(rotation)
	stream.put_u8(1 if bool(request.get("pressed", true)) else 0)
	stream.put_u32(int(request.get("client_tick", 0)))
	return stream.data_array


static func decode_action_request(payload: PackedByteArray) -> Dictionary:
	if payload.size() != ACTION_REQUEST_BYTES:
		return {"ok": false}
	var stream := _reader(payload)
	var request := {
		"request_id": stream.get_u64(),
		"match_id": stream.get_u64(),
		"round_id": stream.get_u32(),
		"attempt_id": stream.get_u16(),
		"peer_generation": stream.get_u32(),
		"edge_sequence": stream.get_u32(),
		"action": stream.get_u8(),
		"target_id": stream.get_u64(),
		"cell": Vector2i(stream.get_32(), stream.get_32()),
		"rotation": stream.get_u8(),
		"pressed": stream.get_u8(),
		"client_tick": stream.get_u32(),
	}
	request.ok = (
		int(request.request_id) > 0
		and int(request.action) <= 31
		and int(request.rotation) <= 3
		and int(request.pressed) <= 1
		and int(request.edge_sequence) != 0
	)
	return request


static func encode_metadata(state: Dictionary) -> PackedByteArray:
	var map_id := str(state.get("map_id", "")).to_ascii_buffer()
	if (
		map_id.size() > 32
		or state.get("seats", []).size() > MAX_SEATS
		or int(state.get("phase", -1)) < 0 or int(state.get("phase", -1)) > 5
		or int(state.get("event_main", 255)) not in [255, 0, 1, 2]
		or int(state.get("event_twist", 255)) not in [255, 0, 1, 2]
		or int(state.get("barya_state", 0)) > 7
		or float(state.get("camera_zoom", 1.0)) < 0.25 or float(state.get("camera_zoom", 1.0)) > 2.0
		or int(state.get("carrier_seat", -1)) < -1 or int(state.get("carrier_seat", -1)) >= MAX_SEATS
		or int(state.get("receipt_seat", -1)) < -1 or int(state.get("receipt_seat", -1)) >= MAX_SEATS
	):
		return PackedByteArray()
	var stream := StreamPeerBuffer.new()
	stream.big_endian = false
	stream.put_u8(META_SCHEMA)
	stream.put_u64(int(state.get("match_id", 0)))
	stream.put_u32(int(state.get("round_id", 0)))
	stream.put_u16(int(state.get("attempt_id", 0)))
	stream.put_u32(int(state.get("tick", 0)))
	stream.put_u32(int(state.get("stage_version", 0)))
	stream.put_u32(int(state.get("snapshot_id", 0)))
	stream.put_u32(int(state.get("event_revision", 0)))
	stream.put_u32(int(state.get("host_time_ms", 0)))
	stream.put_u8(int(state.get("phase", 0)))
	stream.put_u8(1 if bool(state.get("paused", false)) else 0)
	stream.put_u32(int(state.get("remaining_ms", 0)))
	var camera: Vector2 = state.get("camera_position", Vector2.ZERO)
	stream.put_32(roundi(camera.x * WORLD_SCALE))
	stream.put_32(roundi(camera.y * WORLD_SCALE))
	stream.put_u16(roundi(float(state.get("camera_zoom", 1.0)) * 256.0))
	stream.put_u8(int(state.get("event_main", 255)) & 0xff)
	stream.put_u8(int(state.get("event_twist", 255)) & 0xff)
	stream.put_u8(int(state.get("barya_state", 0)) & 0xff)
	stream.put_8(int(state.get("carrier_seat", -1)))
	stream.put_8(int(state.get("receipt_seat", -1)))
	stream.put_u32(int(state.get("rng_decision_id", 0)))
	stream.put_u8(map_id.size())
	stream.put_data(map_id)
	return stream.data_array


static func decode_metadata(payload: PackedByteArray) -> Dictionary:
	if payload.size() < 61 or payload.size() > 93:
		return {"ok": false}
	var stream := _reader(payload)
	if stream.get_u8() != META_SCHEMA:
		return {"ok": false}
	var state := {
		"match_id": stream.get_u64(),
		"round_id": stream.get_u32(),
		"attempt_id": stream.get_u16(),
		"tick": stream.get_u32(),
		"stage_version": stream.get_u32(),
		"snapshot_id": stream.get_u32(),
		"event_revision": stream.get_u32(),
		"host_time_ms": stream.get_u32(),
		"phase": stream.get_u8(),
		"paused": stream.get_u8(),
		"remaining_ms": stream.get_u32(),
		"camera_position": Vector2(stream.get_32(), stream.get_32()) / WORLD_SCALE,
		"camera_zoom": float(stream.get_u16()) / 256.0,
		"event_main": stream.get_u8(),
		"event_twist": stream.get_u8(),
		"barya_state": stream.get_u8(),
		"carrier_seat": stream.get_8(),
		"receipt_seat": stream.get_8(),
		"rng_decision_id": stream.get_u32(),
	}
	var id_length := int(stream.get_u8())
	if id_length > 32 or payload.size() != 61 + id_length:
		return {"ok": false}
	var id_bytes := stream.get_data(id_length)
	if int(id_bytes[0]) != OK:
		return {"ok": false}
	state.map_id = id_bytes[1].get_string_from_ascii()
	state.ok = (
		int(state.paused) <= 1
		and int(state.phase) <= 5
		and float(state.camera_zoom) >= 0.25 and float(state.camera_zoom) <= 2.0
		and int(state.event_main) in [255, 0, 1, 2]
		and int(state.event_twist) in [255, 0, 1, 2]
		and int(state.barya_state) <= 7
		and int(state.carrier_seat) >= -1 and int(state.carrier_seat) < MAX_SEATS
		and int(state.receipt_seat) >= -1 and int(state.receipt_seat) < MAX_SEATS
	)
	return state


static func encode_seat_record(seat: Dictionary, score_units: int) -> PackedByteArray:
	var position: Vector2 = seat.get("position", Vector2.ZERO)
	var velocity: Vector2 = seat.get("velocity", Vector2.ZERO)
	var record := StreamPeerBuffer.new()
	record.big_endian = false
	record.put_u8(RECORD_SEAT)
	record.put_u8(int(seat.get("seat", 0)))
	record.put_u8(int(seat.get("identity", 0)))
	record.put_u8(int(seat.get("shape_id", 0)))
	record.put_u8(int(seat.get("status", 0)))
	record.put_u8(int(seat.get("flags", 0)))
	for value in [position.x, position.y, velocity.x, velocity.y]:
		record.put_32(roundi(float(value) * WORLD_SCALE))
	record.put_32(score_units)
	return record.data_array


static func decode_seat_record(payload: PackedByteArray) -> Dictionary:
	if payload.size() != 26:
		return {"ok": false}
	var stream := _reader(payload)
	if stream.get_u8() != RECORD_SEAT:
		return {"ok": false}
	var seat := {
		"seat": stream.get_u8(),
		"identity": stream.get_u8(),
		"shape_id": stream.get_u8(),
		"status": stream.get_u8(),
		"flags": stream.get_u8(),
		"position": Vector2(stream.get_32(), stream.get_32()) / WORLD_SCALE,
		"velocity": Vector2(stream.get_32(), stream.get_32()) / WORLD_SCALE,
		"score_units": stream.get_32(),
	}
	seat.ok = int(seat.seat) < MAX_SEATS and int(seat.shape_id) < 4 and int(seat.status) <= 5
	return seat


static func encode_stage_record(record: Dictionary) -> PackedByteArray:
	var key_bytes := str(record.get("variant_key", "")).to_ascii_buffer()
	var entity_id := int(record.get("entity_id", 0))
	var position: Vector2 = record.get("position", Vector2.ZERO)
	var velocity: Vector2 = record.get("velocity", Vector2.ZERO)
	if entity_id <= 0 or key_bytes.is_empty() or key_bytes.size() > MAX_ID_BYTES:
		return PackedByteArray()
	var stream := StreamPeerBuffer.new()
	stream.big_endian = false
	stream.put_u8(RECORD_STAGE_ENTITY)
	stream.put_u64(entity_id)
	stream.put_u8(key_bytes.size())
	stream.put_data(key_bytes)
	for value in [position.x, position.y, velocity.x, velocity.y]:
		stream.put_32(roundi(float(value) * WORLD_SCALE))
	stream.put_u8(int(record.get("rotation", 0)) & 3)
	stream.put_u8(int(record.get("lifecycle", 0)))
	stream.put_u8(int(record.get("state_flags", 0)) & 0xff)
	stream.put_u16(int(record.get("timer_ms", 0)) & 0xffff)
	stream.put_u32(int(record.get("revision", 0)))
	return stream.data_array


static func decode_stage_record(payload: PackedByteArray) -> Dictionary:
	if payload.size() < 36 or payload.size() > 83:
		return {"ok": false}
	var stream := _reader(payload)
	if stream.get_u8() != RECORD_STAGE_ENTITY:
		return {"ok": false}
	var entity_id := stream.get_u64()
	var key_length := int(stream.get_u8())
	if entity_id == 0 or key_length < 1 or key_length > MAX_ID_BYTES or payload.size() != 35 + key_length:
		return {"ok": false}
	var key := stream.get_data(key_length)
	if int(key[0]) != OK:
		return {"ok": false}
	var entity := {
		"entity_id": entity_id,
		"variant_key": key[1].get_string_from_ascii(),
		"position": Vector2(stream.get_32(), stream.get_32()) / WORLD_SCALE,
		"velocity": Vector2(stream.get_32(), stream.get_32()) / WORLD_SCALE,
		"rotation": stream.get_u8(),
		"lifecycle": stream.get_u8(),
		"state_flags": stream.get_u8(),
		"timer_ms": stream.get_u16(),
		"revision": stream.get_u32(),
	}
	# Lifecycle 0 = static/legacy, 1 = live grace (timer_ms remaining), 2 = active (contract v1.3).
	entity.ok = int(entity.rotation) < 4 and int(entity.state_flags) <= 15 and int(entity.lifecycle) <= 2
	return entity


static func encode_objective_record(state: Dictionary) -> PackedByteArray:
	var position: Vector2 = state.get("position", Vector2.ZERO)
	var stream := StreamPeerBuffer.new()
	stream.big_endian = false
	stream.put_u8(RECORD_OBJECTIVE)
	stream.put_u8(int(state.get("kind", 1)))
	stream.put_u8(int(state.get("state", 0)))
	stream.put_8(int(state.get("carrier_seat", -1)))
	stream.put_8(int(state.get("receipt_seat", -1)))
	stream.put_32(roundi(position.x * WORLD_SCALE))
	stream.put_32(roundi(position.y * WORLD_SCALE))
	stream.put_u32(int(state.get("round_id", 0)))
	stream.put_u16(int(state.get("attempt_id", 0)))
	return stream.data_array


static func decode_objective_record(payload: PackedByteArray) -> Dictionary:
	if payload.size() != 19 or int(payload[0]) != RECORD_OBJECTIVE:
		return {"ok": false}
	var stream := _reader(payload)
	stream.get_u8()
	var objective := {
		"kind": stream.get_u8(),
		"state": stream.get_u8(),
		"carrier_seat": stream.get_8(),
		"receipt_seat": stream.get_8(),
		"position": Vector2(stream.get_32(), stream.get_32()) / WORLD_SCALE,
		"round_id": stream.get_u32(),
		"attempt_id": stream.get_u16(),
	}
	objective.ok = int(objective.kind) == 1 and int(objective.state) <= 7
	return objective


static func encode_event_context_record(state: Dictionary) -> PackedByteArray:
	var stream := StreamPeerBuffer.new()
	stream.big_endian = false
	stream.put_u8(RECORD_EVENT_CONTEXT)
	for field in ["event_main", "event_twist", "next_main", "next_twist"]:
		stream.put_u8(int(state.get(field, 255)) & 0xff)
	stream.put_8(int(state.get("taya_seat", -1)))
	stream.put_u32(int(state.get("event_clock_ms", 0)))
	stream.put_u32(int(state.get("event_revision", 0)))
	stream.put_u32(int(state.get("rng_decision_id", 0)))
	for seat in MAX_SEATS:
		stream.put_u8(int(state.get("markers", {}).get(seat, 0)) & 0xff)
	return stream.data_array


static func decode_event_context_record(payload: PackedByteArray) -> Dictionary:
	if payload.size() != 22 or int(payload[0]) != RECORD_EVENT_CONTEXT:
		return {"ok": false}
	var stream := _reader(payload)
	stream.get_u8()
	var context := {
		"event_main": stream.get_u8(),
		"event_twist": stream.get_u8(),
		"next_main": stream.get_u8(),
		"next_twist": stream.get_u8(),
		"taya_seat": stream.get_8(),
		"event_clock_ms": stream.get_u32(),
		"event_revision": stream.get_u32(),
		"rng_decision_id": stream.get_u32(),
		"markers": {},
	}
	for seat in MAX_SEATS:
		context.markers[seat] = stream.get_u8()
	for field in ["event_main", "event_twist", "next_main", "next_twist"]:
		if int(context[field]) not in [255, 0, 1, 2]:
			return {"ok": false}
	context.ok = int(context.taya_seat) >= -1 and int(context.taya_seat) < MAX_SEATS
	return context


## One host-owned live transient (projectile, bubble, blast flash or mover position). Fields:
## transient_kind, transient_id (u16, nonzero, unique per kind), owner_entity (wire entity ID of
## the placed item, 0 when it no longer exists), position, velocity, extent (world units),
## phase (0..7), timer_ms, owner_seat and captive_seat (-1..3). Clients only draw it.
static func encode_transient_record(transient: Dictionary) -> PackedByteArray:
	var kind := int(transient.get("transient_kind", 0))
	var transient_id := int(transient.get("transient_id", 0))
	var extent: Vector2 = transient.get("extent", Vector2.ZERO)
	if (
		not TRANSIENT_CAPS.has(kind)
		or transient_id <= 0 or transient_id > 0xffff
		or int(transient.get("owner_entity", 0)) < 0
		or int(transient.get("phase", 0)) < 0 or int(transient.get("phase", 0)) > 7
		or int(transient.get("owner_seat", -1)) < -1
		or int(transient.get("owner_seat", -1)) >= MAX_SEATS
		or int(transient.get("captive_seat", -1)) < -1
		or int(transient.get("captive_seat", -1)) >= MAX_SEATS
		or extent.x < 0.0 or extent.y < 0.0 or extent.x > 65535.0 or extent.y > 65535.0
	):
		return PackedByteArray()
	var position: Vector2 = transient.get("position", Vector2.ZERO)
	var velocity: Vector2 = transient.get("velocity", Vector2.ZERO)
	var stream := StreamPeerBuffer.new()
	stream.big_endian = false
	stream.put_u8(RECORD_TRANSIENT)
	stream.put_u8(kind)
	stream.put_u16(transient_id)
	stream.put_u64(int(transient.get("owner_entity", 0)))
	for value in [position.x, position.y, velocity.x, velocity.y]:
		stream.put_32(roundi(float(value) * WORLD_SCALE))
	stream.put_u8(int(transient.get("phase", 0)))
	stream.put_u16(clampi(int(transient.get("timer_ms", 0)), 0, 0xffff))
	stream.put_8(int(transient.get("owner_seat", -1)))
	stream.put_8(int(transient.get("captive_seat", -1)))
	stream.put_u16(roundi(extent.x))
	stream.put_u16(roundi(extent.y))
	return stream.data_array if stream.data_array.size() == TRANSIENT_BYTES else PackedByteArray()


static func decode_transient_record(payload: PackedByteArray) -> Dictionary:
	if payload.size() != TRANSIENT_BYTES or int(payload[0]) != RECORD_TRANSIENT:
		return {"ok": false}
	var stream := _reader(payload)
	stream.get_u8()
	var transient := {
		"transient": true,
		"transient_kind": stream.get_u8(),
		"transient_id": stream.get_u16(),
		"owner_entity": stream.get_u64(),
		"position": Vector2(stream.get_32(), stream.get_32()) / WORLD_SCALE,
		"velocity": Vector2(stream.get_32(), stream.get_32()) / WORLD_SCALE,
		"phase": stream.get_u8(),
		"timer_ms": stream.get_u16(),
		"owner_seat": stream.get_8(),
		"captive_seat": stream.get_8(),
		"extent": Vector2(stream.get_u16(), stream.get_u16()),
	}
	transient.ok = (
		TRANSIENT_CAPS.has(int(transient.transient_kind))
		and int(transient.transient_id) > 0
		and int(transient.phase) <= 7
		and int(transient.owner_seat) >= -1 and int(transient.owner_seat) < MAX_SEATS
		and int(transient.captive_seat) >= -1 and int(transient.captive_seat) < MAX_SEATS
	)
	return transient


static func encode_transient_end(kind: int, transient_id: int) -> PackedByteArray:
	if not TRANSIENT_CAPS.has(kind) or transient_id <= 0 or transient_id > 0xffff:
		return PackedByteArray()
	var stream := StreamPeerBuffer.new()
	stream.big_endian = false
	stream.put_u8(RECORD_TRANSIENT_END)
	stream.put_u8(kind)
	stream.put_u16(transient_id)
	return stream.data_array


static func decode_transient_end(payload: PackedByteArray) -> Dictionary:
	if payload.size() != TRANSIENT_END_BYTES or int(payload[0]) != RECORD_TRANSIENT_END:
		return {"ok": false}
	var stream := _reader(payload)
	stream.get_u8()
	var ended := {
		"transient": true,
		"ended": true,
		"transient_kind": stream.get_u8(),
		"transient_id": stream.get_u16(),
	}
	ended.ok = TRANSIENT_CAPS.has(int(ended.transient_kind)) and int(ended.transient_id) > 0
	return ended


## OK, or CONTENT_LIMIT_EXCEEDED when any kind exceeds its wire cap. The host must then refuse or
## resync; it never truncates the list.
static func transient_cap_status(transients: Array) -> int:
	if transients.size() > MAX_TRANSIENTS:
		return NetworkFrame.Reason.CONTENT_LIMIT_EXCEEDED
	var counts := {}
	for transient_variant in transients:
		var kind := int((transient_variant as Dictionary).get("transient_kind", 0))
		counts[kind] = int(counts.get(kind, 0)) + 1
		if not TRANSIENT_CAPS.has(kind) or int(counts[kind]) > int(TRANSIENT_CAPS[kind]):
			return NetworkFrame.Reason.CONTENT_LIMIT_EXCEEDED
	return NetworkFrame.Reason.OK


## Typed record by its leading type byte, or {"ok": false}.
static func decode_record(raw: PackedByteArray) -> Dictionary:
	if raw.is_empty():
		return {"ok": false}
	match int(raw[0]):
		RECORD_SEAT:
			return decode_seat_record(raw)
		RECORD_STAGE_ENTITY:
			return decode_stage_record(raw)
		RECORD_TOMBSTONE:
			if raw.size() != 9:
				return {"ok": false}
			var tombstone_reader := _reader(raw)
			tombstone_reader.get_u8()
			return {"ok": true, "entity_id": tombstone_reader.get_u64(), "removed": true}
		RECORD_OBJECTIVE:
			return decode_objective_record(raw)
		RECORD_EVENT_CONTEXT:
			return decode_event_context_record(raw)
		RECORD_TRANSIENT:
			return decode_transient_record(raw)
		RECORD_TRANSIENT_END:
			return decode_transient_end(raw)
		RECORD_LEDGER:
			var entry := NetworkResultsCodec.decode_event(raw.slice(1))
			if not bool(entry.get("ok", false)):
				return {"ok": false}
			return {"ok": true, "ledger": true, "entry": entry}
	return {"ok": false}


## Type byte plus the event payload; empty when the entry is invalid.
static func encode_ledger_record(entry: Dictionary) -> PackedByteArray:
	var body := NetworkResultsCodec.encode_event(entry)
	if body.is_empty():
		return PackedByteArray()
	var record := PackedByteArray([RECORD_LEDGER])
	record.append_array(body)
	return record


## A superseding state frame carries host tick, stage version and one complete typed entity record.
static func encode_state_update(state: Dictionary, tick: int, stage_version: int, record: PackedByteArray) -> PackedByteArray:
	if tick < 0 or tick > 0xffffffff or stage_version < 0 or stage_version > 0xffffffff:
		return PackedByteArray()
	var metadata := encode_metadata(state)
	if metadata.is_empty() or metadata.size() > 255 or record.is_empty():
		return PackedByteArray()
	var stream := StreamPeerBuffer.new()
	stream.big_endian = false
	stream.put_u8(metadata.size())
	stream.put_data(metadata)
	stream.put_u32(tick)
	stream.put_u32(stage_version)
	stream.put_u16(record.size())
	stream.put_data(record)
	if stream.data_array.size() > NetworkFrame.MAX_FRAME_BYTES - NetworkFrame.HEADER_BYTES:
		return PackedByteArray()
	return stream.data_array


static func decode_state_update(payload: PackedByteArray) -> Dictionary:
	if payload.size() < 53 or payload.size() > NetworkFrame.MAX_FRAME_BYTES - NetworkFrame.HEADER_BYTES:
		return {"ok": false}
	var stream := _reader(payload)
	var metadata_length := int(stream.get_u8())
	if metadata_length < 61 or metadata_length > 93 or stream.get_position() + metadata_length + 10 > payload.size():
		return {"ok": false}
	var metadata_bytes := stream.get_data(metadata_length)
	if int(metadata_bytes[0]) != OK:
		return {"ok": false}
	var metadata := decode_metadata(metadata_bytes[1])
	if not bool(metadata.get("ok", false)):
		return {"ok": false}
	var tick := stream.get_u32()
	var stage_version := stream.get_u32()
	var record_length := int(stream.get_u16())
	if record_length == 0 or stream.get_position() + record_length != payload.size():
		return {"ok": false}
	var record_data := stream.get_data(record_length)
	if int(record_data[0]) != OK or record_data[1].is_empty():
		return {"ok": false}
	var record := decode_record(record_data[1])
	if not bool(record.get("ok", false)):
		return {"ok": false}
	return {"ok": true, "metadata": metadata, "tick": tick, "stage_version": stage_version, "record": record}


static func encode_tombstone(entity_id: int) -> PackedByteArray:
	if entity_id <= 0:
		return PackedByteArray()
	var stream := StreamPeerBuffer.new()
	stream.big_endian = false
	stream.put_u8(RECORD_TOMBSTONE)
	stream.put_u64(entity_id)
	return stream.data_array


## Snapshot records are length-prefixed inside the cap and validated as a whole before install.
static func unpack_snapshot(snapshot: PackedByteArray) -> Dictionary:
	if snapshot.size() < 4 or snapshot.size() > SNAPSHOT_CAP:
		return {"ok": false}
	var stream := _reader(snapshot)
	if stream.get_u16() != 1:
		return {"ok": false}
	var count := int(stream.get_u16())
	if count > MAX_SNAPSHOT_RECORDS:
		return {"ok": false}
	var records: Array[Dictionary] = []
	for _index in count:
		if stream.get_position() + 2 > snapshot.size():
			return {"ok": false}
		var length := int(stream.get_u16())
		if length == 0 or length > NetworkFrame.MAX_FRAME_BYTES - NetworkFrame.HEADER_BYTES - SNAPSHOT_CHUNK_HEADER_BYTES:
			return {"ok": false}
		if stream.get_position() + length > snapshot.size():
			return {"ok": false}
		var raw := stream.get_data(length)
		if int(raw[0]) != OK:
			return {"ok": false}
		var decoded := decode_record(raw[1])
		if not bool(decoded.get("ok", false)):
			return {"ok": false}
		records.append(decoded)
	if stream.get_position() != snapshot.size():
		return {"ok": false}
	var transients: Array = []
	for record in records:
		if bool(record.get("transient", false)) and not bool(record.get("ended", false)):
			transients.append(record)
	if transient_cap_status(transients) != NetworkFrame.Reason.OK:
		return {"ok": false, "reason": NetworkFrame.Reason.SNAPSHOT_LIMIT}
	return {"ok": true, "records": records}


static func pack_snapshot(records: Array[PackedByteArray]) -> PackedByteArray:
	if records.size() > MAX_SNAPSHOT_RECORDS:
		return PackedByteArray()
	var stream := StreamPeerBuffer.new()
	stream.big_endian = false
	stream.put_u16(1)
	stream.put_u16(records.size())
	for record in records:
		if record.is_empty() or record.size() > NetworkFrame.MAX_FRAME_BYTES - NetworkFrame.HEADER_BYTES - SNAPSHOT_CHUNK_HEADER_BYTES:
			return PackedByteArray()
		stream.put_u16(record.size())
		stream.put_data(record)
	if stream.data_array.size() > SNAPSHOT_CAP:
		return PackedByteArray()
	return stream.data_array


static func crc32(data: PackedByteArray) -> int:
	var crc: int = 0xffffffff
	for value in data:
		crc = crc ^ int(value)
		for _bit in 8:
			crc = (crc >> 1) ^ (0xedb88320 if (crc & 1) != 0 else 0)
	return (~crc) & 0xffffffff


static func _reader(data: PackedByteArray) -> StreamPeerBuffer:
	var stream := StreamPeerBuffer.new()
	stream.big_endian = false
	stream.data_array = data
	return stream

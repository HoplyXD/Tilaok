# gdlint: disable=max-returns,class-definitions-order
class_name NetworkPlacementCodec
extends RefCounted

## Contract v1.3 live-placement payloads. Every field is a bounded little-endian integer or a
## catalog key; no seat, world transform, Variant, Object or free text crosses the wire. Rejection
## text is chosen locally from the reason/detail enums.

const INTENT_BYTES := 48
const RESULT_BYTES := 38
const SEAT_STATE_BASE_BYTES := 34
const TERRAIN_HEADER_BYTES := 27
const TERRAIN_REMOVE_EDIT_BYTES := 9
const MAX_CELL := 1024
const MAX_KEY_BYTES := 48
const MAX_TERRAIN_EDITS := 16
const MAX_TERRAIN_PARTS := 4
const MAX_DETAIL := 63
const MAX_STAGE_RECORD_BYTES := 83

enum Status { QUEUED = 1, ACCEPTED = 2, REJECTED = 3 }
enum ItemStatus { NONE = 0, AVAILABLE = 1, PENDING = 2, USED = 3 }
enum EditOp { ADD = 1, UPDATE = 2, REMOVE = 3 }
enum Lifecycle { STATIC = 0, GRACE = 1, ACTIVE = 2 }
enum Detail {
	NONE = 0,
	QUEUED = 1,
	COMMITTED = 2,
	OBJECTIVE = 3,
	WRONG_PHASE = 4,
	SEAT_UNREGISTERED = 5,
	ACTOR_INELIGIBLE = 6,
	INVENTORY_MISSING = 7,
	INVENTORY_USED = 8,
	INVENTORY_MISMATCH = 9,
	LIVE_EFFECT_PATH = 10,
	FUTURE_STAGE = 11,
	STALE_ATTEMPT = 12,
	STALE_ROUND = 13,
	REQUEST_ID_REUSED = 14,
	REQUEST_PENDING = 15,
	BOUNDARY_FULL = 16,
	REQUEST_LIMIT = 17,
	INVALID_REQUEST_ID = 18,
	UNKNOWN_VARIANT = 19,
	VARIANT_DISABLED = 20,
	ROTATION_UNSUPPORTED = 21,
	PERSISTENT_CAP = 22,
	OUT_OF_BOUNDS = 23,
	PROTECTED_SPAWN = 24,
	PROTECTED_GOAL = 25,
	OUTSIDE_BUILD_REGION = 26,
	IMMUTABLE_BASE = 27,
	PLAYER_CLEARANCE = 28,
	ITEM_OVERLAP = 29,
	INVALID_REGION = 30,
	MOVER_SWEEP = 31,
	COMMIT_FAILED = 32,
	ROUND_ENDED = 33,
	OTHER_SEAT_ITEM = 34,
	SEAT_DISCONNECTED = 35,
	OBJECTIVE_REJECTED = 36,
	STAGE_UNAVAILABLE = 37,
	WRONG_ROUTE = 38,
	RATE_LIMIT = 39,
	CELL_RANGE = 40,
	UNKNOWN = 63,
}

## P05 pipeline, room and validator codes -> [wire reason, detail]. Codes missing from this table
## fail closed as INTERNAL_RETRY / UNKNOWN and are always rejections.
const CODE_TABLE := {
	"queued": [NetworkFrame.Reason.OK, Detail.QUEUED],
	"committed": [NetworkFrame.Reason.OK, Detail.COMMITTED],
	"objective": [NetworkFrame.Reason.OK, Detail.OBJECTIVE],
	"wrong_phase": [NetworkFrame.Reason.WRONG_PHASE, Detail.WRONG_PHASE],
	"actor_ineligible": [NetworkFrame.Reason.WRONG_PHASE, Detail.ACTOR_INELIGIBLE],
	"seat_unregistered": [NetworkFrame.Reason.OWNERSHIP, Detail.SEAT_UNREGISTERED],
	"other_seat_item": [NetworkFrame.Reason.OWNERSHIP, Detail.OTHER_SEAT_ITEM],
	"stale_attempt": [NetworkFrame.Reason.STALE_STATE, Detail.STALE_ATTEMPT],
	"stale_round": [NetworkFrame.Reason.STALE_STATE, Detail.STALE_ROUND],
	"future_stage": [NetworkFrame.Reason.STALE_STATE, Detail.FUTURE_STAGE],
	"rotation_unsupported": [NetworkFrame.Reason.FIELD_RANGE, Detail.ROTATION_UNSUPPORTED],
	"out_of_bounds": [NetworkFrame.Reason.FIELD_RANGE, Detail.OUT_OF_BOUNDS],
	"cell_range": [NetworkFrame.Reason.FIELD_RANGE, Detail.CELL_RANGE],
	"request_id_reused": [NetworkFrame.Reason.REQUEST_ID_REUSE, Detail.REQUEST_ID_REUSED],
	"request_pending": [NetworkFrame.Reason.REQUEST_CAPACITY, Detail.REQUEST_PENDING],
	"boundary_full": [NetworkFrame.Reason.REQUEST_CAPACITY, Detail.BOUNDARY_FULL],
	"request_limit": [NetworkFrame.Reason.REQUEST_CAPACITY, Detail.REQUEST_LIMIT],
	"request_capacity": [NetworkFrame.Reason.REQUEST_CAPACITY, Detail.REQUEST_PENDING],
	"rate_limit": [NetworkFrame.Reason.RATE_LIMIT, Detail.RATE_LIMIT],
	"inventory_missing": [NetworkFrame.Reason.INVENTORY, Detail.INVENTORY_MISSING],
	"inventory_used": [NetworkFrame.Reason.INVENTORY, Detail.INVENTORY_USED],
	"inventory_mismatch": [NetworkFrame.Reason.INVENTORY, Detail.INVENTORY_MISMATCH],
	"unknown_variant": [NetworkFrame.Reason.INVENTORY, Detail.UNKNOWN_VARIANT],
	"variant_disabled": [NetworkFrame.Reason.INVENTORY, Detail.VARIANT_DISABLED],
	"protected_spawn": [NetworkFrame.Reason.PLACEMENT_BLOCKED, Detail.PROTECTED_SPAWN],
	"protected_goal": [NetworkFrame.Reason.PLACEMENT_BLOCKED, Detail.PROTECTED_GOAL],
	"outside_build_region": [NetworkFrame.Reason.PLACEMENT_BLOCKED, Detail.OUTSIDE_BUILD_REGION],
	"immutable_base": [NetworkFrame.Reason.PLACEMENT_BLOCKED, Detail.IMMUTABLE_BASE],
	"player_clearance": [NetworkFrame.Reason.PLACEMENT_BLOCKED, Detail.PLAYER_CLEARANCE],
	"item_overlap": [NetworkFrame.Reason.PLACEMENT_BLOCKED, Detail.ITEM_OVERLAP],
	"invalid_region": [NetworkFrame.Reason.PLACEMENT_BLOCKED, Detail.INVALID_REGION],
	"mover_sweep": [NetworkFrame.Reason.PLACEMENT_BLOCKED, Detail.MOVER_SWEEP],
	"live_effect_path": [NetworkFrame.Reason.PLACEMENT_BLOCKED, Detail.LIVE_EFFECT_PATH],
	"objective_rejected": [NetworkFrame.Reason.PLACEMENT_BLOCKED, Detail.OBJECTIVE_REJECTED],
	"stage_rejected": [NetworkFrame.Reason.PLACEMENT_BLOCKED, Detail.STAGE_UNAVAILABLE],
	"missing_stage": [NetworkFrame.Reason.PLACEMENT_BLOCKED, Detail.STAGE_UNAVAILABLE],
	"persistent_cap": [NetworkFrame.Reason.CONTENT_LIMIT_EXCEEDED, Detail.PERSISTENT_CAP],
	"round_ended": [NetworkFrame.Reason.ROUND_ENDED, Detail.ROUND_ENDED],
	"seat_disconnected": [NetworkFrame.Reason.ROUND_ENDED, Detail.SEAT_DISCONNECTED],
	"wrong_route": [NetworkFrame.Reason.WRONG_PHASE, Detail.WRONG_ROUTE],
	"commit_failed": [NetworkFrame.Reason.INTERNAL_RETRY, Detail.COMMIT_FAILED],
	"invalid_request_id": [NetworkFrame.Reason.MALFORMED, Detail.INVALID_REQUEST_ID],
}

## Client-local text for each detail. The host never sends these strings.
const DETAIL_TEXT := {
	Detail.QUEUED: "Sending placement…",
	Detail.COMMITTED: "Placed. It activates after its safe grace period.",
	Detail.OBJECTIVE: "Barya placed.",
	Detail.WRONG_PHASE: "Building is closed right now.",
	Detail.SEAT_UNREGISTERED: "Your seat is no longer joined.",
	Detail.ACTOR_INELIGIBLE: "Only an active, unsecured chicken can build.",
	Detail.INVENTORY_MISSING: "You have no item to place.",
	Detail.INVENTORY_USED: "Your item was already used.",
	Detail.INVENTORY_MISMATCH: "That item does not belong to you.",
	Detail.LIVE_EFFECT_PATH: "Wait for active effects to clear, then try again.",
	Detail.FUTURE_STAGE: "The stage changed. Try again.",
	Detail.STALE_ATTEMPT: "That request belongs to an earlier round.",
	Detail.STALE_ROUND: "That request belongs to a different round.",
	Detail.REQUEST_ID_REUSED: "That request could not be matched. Try again.",
	Detail.REQUEST_PENDING: "Wait for your current placement to resolve.",
	Detail.BOUNDARY_FULL: "Too many placements at once. Try again.",
	Detail.REQUEST_LIMIT: "You have used all placement attempts this round.",
	Detail.INVALID_REQUEST_ID: "The placement request was invalid.",
	Detail.UNKNOWN_VARIANT: "That item is not available.",
	Detail.VARIANT_DISABLED: "That item is disabled in this match.",
	Detail.ROTATION_UNSUPPORTED: "That rotation is not allowed for this item.",
	Detail.PERSISTENT_CAP: "The stage has reached its piece limit.",
	Detail.OUT_OF_BOUNDS: "That spot is outside the stage.",
	Detail.PROTECTED_SPAWN: "Keep the start area clear.",
	Detail.PROTECTED_GOAL: "Keep the flag area clear.",
	Detail.OUTSIDE_BUILD_REGION: "That spot is outside the building area.",
	Detail.IMMUTABLE_BASE: "The base stage cannot be changed there.",
	Detail.PLAYER_CLEARANCE: "A chicken is too close to that spot.",
	Detail.ITEM_OVERLAP: "Something is already there.",
	Detail.INVALID_REGION: "That spot is not valid for this item.",
	Detail.MOVER_SWEEP: "A moving piece can cross that spot.",
	Detail.COMMIT_FAILED: "The host could not place that. Try again.",
	Detail.ROUND_ENDED: "The round ended before the placement resolved.",
	Detail.OTHER_SEAT_ITEM: "That item belongs to another player.",
	Detail.SEAT_DISCONNECTED: "The placement was cancelled when the seat disconnected.",
	Detail.OBJECTIVE_REJECTED: "Barya cannot be placed there.",
	Detail.STAGE_UNAVAILABLE: "The stage is not ready for that.",
	Detail.WRONG_ROUTE: "Live building is not enabled in this match.",
	Detail.RATE_LIMIT: "Placing too quickly. Wait a moment.",
	Detail.CELL_RANGE: "That spot is out of range.",
	Detail.UNKNOWN: "The placement was not accepted.",
}


static func reason_for_code(code: String) -> int:
	if not CODE_TABLE.has(code):
		return NetworkFrame.Reason.INTERNAL_RETRY
	return int(CODE_TABLE[code][0])


static func detail_for_code(code: String) -> int:
	if not CODE_TABLE.has(code):
		return Detail.UNKNOWN
	return int(CODE_TABLE[code][1])


static func detail_text(detail: int) -> String:
	return str(DETAIL_TEXT.get(detail, DETAIL_TEXT[Detail.UNKNOWN]))


static func encode_intent(intent: Dictionary) -> PackedByteArray:
	var cell: Vector2i = intent.get("cell", Vector2i.ZERO)
	if (
		int(intent.get("request_id", 0)) <= 0
		or int(intent.get("match_id", 0)) <= 0
		or int(intent.get("rotation", 0)) < 0
		or int(intent.get("rotation", 0)) > 3
		or absi(cell.x) > MAX_CELL
		or absi(cell.y) > MAX_CELL
	):
		return PackedByteArray()
	var stream := StreamPeerBuffer.new()
	stream.big_endian = false
	stream.put_u64(int(intent.request_id))
	stream.put_u64(int(intent.match_id))
	stream.put_u32(int(intent.get("round_id", 0)) & 0xffffffff)
	stream.put_u16(int(intent.get("attempt_id", 0)) & 0xffff)
	stream.put_u32(int(intent.get("peer_generation", 0)) & 0xffffffff)
	stream.put_u32(int(intent.get("expected_stage_version", 0)) & 0xffffffff)
	stream.put_u64(int(intent.get("inventory_id", 0)))
	stream.put_32(cell.x)
	stream.put_32(cell.y)
	stream.put_u8(int(intent.rotation))
	stream.put_u8(0)
	return stream.data_array


## Returns {"ok": false, "reason": Reason} for malformed (size/flags/id/rotation) or out-of-range
## (cell) payloads so the host can choose between rejecting the frame and answering the request.
static func decode_intent(payload: PackedByteArray) -> Dictionary:
	if payload.size() != INTENT_BYTES:
		return {"ok": false, "reason": NetworkFrame.Reason.MALFORMED}
	var stream := _reader(payload)
	var intent := {
		"request_id": stream.get_u64(),
		"match_id": stream.get_u64(),
		"round_id": stream.get_u32(),
		"attempt_id": stream.get_u16(),
		"peer_generation": stream.get_u32(),
		"expected_stage_version": stream.get_u32(),
		"inventory_id": stream.get_u64(),
		"cell": Vector2i(stream.get_32(), stream.get_32()),
		"rotation": stream.get_u8(),
		"flags": stream.get_u8(),
	}
	if (
		int(intent.request_id) <= 0
		or int(intent.match_id) <= 0
		or int(intent.rotation) > 3
		or int(intent.flags) != 0
	):
		return {"ok": false, "reason": NetworkFrame.Reason.MALFORMED}
	var cell: Vector2i = intent.cell
	if absi(cell.x) > MAX_CELL or absi(cell.y) > MAX_CELL:
		return {"ok": false, "reason": NetworkFrame.Reason.FIELD_RANGE, "request_id": intent.request_id}
	intent.ok = true
	return intent


static func encode_result(result: Dictionary) -> PackedByteArray:
	var status := int(result.get("status", 0))
	var cell: Vector2i = result.get("cell", Vector2i.ZERO)
	if (
		int(result.get("request_id", 0)) <= 0
		or status < Status.QUEUED
		or status > Status.REJECTED
		or int(result.get("detail", 0)) < 0
		or int(result.get("detail", 0)) > MAX_DETAIL
		or int(result.get("rotation", 0)) < 0
		or int(result.get("rotation", 0)) > 3
		or absi(cell.x) > MAX_CELL
		or absi(cell.y) > MAX_CELL
	):
		return PackedByteArray()
	var entity_id := int(result.get("entity_id", 0)) if status == Status.ACCEPTED else 0
	var stream := StreamPeerBuffer.new()
	stream.big_endian = false
	stream.put_u64(int(result.request_id))
	stream.put_u16(int(result.get("reason", NetworkFrame.Reason.OK)) & 0xffff)
	stream.put_u8(status)
	stream.put_u64(maxi(0, entity_id))
	stream.put_32(cell.x)
	stream.put_32(cell.y)
	stream.put_u8(int(result.get("rotation", 0)))
	stream.put_u32(int(result.get("stage_version", 0)) & 0xffffffff)
	stream.put_u32(int(result.get("activation_tick", 0)) & 0xffffffff)
	stream.put_u16(int(result.get("detail", 0)))
	return stream.data_array


static func decode_result(payload: PackedByteArray) -> Dictionary:
	if payload.size() != RESULT_BYTES:
		return {"ok": false}
	var stream := _reader(payload)
	var result := {
		"request_id": stream.get_u64(),
		"reason": stream.get_u16(),
		"status": stream.get_u8(),
		"entity_id": stream.get_u64(),
		"cell": Vector2i(stream.get_32(), stream.get_32()),
		"rotation": stream.get_u8(),
		"stage_version": stream.get_u32(),
		"activation_tick": stream.get_u32(),
		"detail": stream.get_u16(),
	}
	var status := int(result.status)
	var reason := int(result.reason)
	# Only acceptance names an entity (a Barya objective acceptance has none), and only a rejection
	# carries a non-OK reason.
	var names_entity := int(result.entity_id) > 0
	result.ok = (
		int(result.request_id) > 0
		and status >= Status.QUEUED
		and status <= Status.REJECTED
		and reason <= NetworkFrame.Reason.INTERNAL_RETRY
		and int(result.rotation) <= 3
		and int(result.detail) <= MAX_DETAIL
		and (not names_entity or status == Status.ACCEPTED)
		and (names_entity or status != Status.ACCEPTED or int(result.detail) == Detail.OBJECTIVE)
		and (status == Status.REJECTED) == (reason != NetworkFrame.Reason.OK)
	)
	return result


static func encode_seat_state(state: Dictionary) -> PackedByteArray:
	var key_bytes := str(state.get("variant_key", "")).to_ascii_buffer()
	var inventory_id := int(state.get("inventory_id", 0))
	var cursor: Vector2i = state.get("cursor", Vector2i.ZERO)
	var item_status := int(state.get("item_status", ItemStatus.NONE))
	if (
		key_bytes.size() > MAX_KEY_BYTES
		or (inventory_id > 0) == key_bytes.is_empty()
		or inventory_id < 0
		or item_status < ItemStatus.NONE
		or item_status > ItemStatus.USED
		or int(state.get("rotation", 0)) < 0
		or int(state.get("rotation", 0)) > 3
		or absi(cursor.x) > MAX_CELL
		or absi(cursor.y) > MAX_CELL
	):
		return PackedByteArray()
	var stream := StreamPeerBuffer.new()
	stream.big_endian = false
	stream.put_u64(int(state.get("match_id", 0)))
	stream.put_u32(int(state.get("round_id", 0)) & 0xffffffff)
	stream.put_u16(int(state.get("attempt_id", 0)) & 0xffff)
	stream.put_u64(inventory_id)
	stream.put_u8(key_bytes.size())
	stream.put_data(key_bytes)
	stream.put_u8(item_status)
	stream.put_u8(1 if bool(state.get("build_mode", false)) else 0)
	stream.put_u8(int(state.get("rotation", 0)))
	stream.put_32(cursor.x)
	stream.put_32(cursor.y)
	return stream.data_array


static func decode_seat_state(payload: PackedByteArray) -> Dictionary:
	if payload.size() < SEAT_STATE_BASE_BYTES or payload.size() > SEAT_STATE_BASE_BYTES + MAX_KEY_BYTES:
		return {"ok": false}
	var stream := _reader(payload)
	var state := {
		"match_id": stream.get_u64(),
		"round_id": stream.get_u32(),
		"attempt_id": stream.get_u16(),
		"inventory_id": stream.get_u64(),
	}
	var key_length := int(stream.get_u8())
	if payload.size() != SEAT_STATE_BASE_BYTES + key_length:
		return {"ok": false}
	state.variant_key = ""
	if key_length > 0:
		var key := stream.get_data(key_length)
		if int(key[0]) != OK:
			return {"ok": false}
		state.variant_key = (key[1] as PackedByteArray).get_string_from_ascii()
	state.item_status = stream.get_u8()
	var build_mode := int(stream.get_u8())
	state.build_mode = build_mode == 1
	state.rotation = stream.get_u8()
	state.cursor = Vector2i(stream.get_32(), stream.get_32())
	var cursor: Vector2i = state.cursor
	state.ok = (
		int(state.match_id) > 0
		and int(state.inventory_id) >= 0
		and (int(state.inventory_id) > 0) == (key_length > 0)
		and int(state.item_status) <= ItemStatus.USED
		and build_mode <= 1
		and int(state.rotation) <= 3
		and absi(cursor.x) <= MAX_CELL
		and absi(cursor.y) <= MAX_CELL
	)
	return state


## Splits one contiguous stage-version commit into at most MAX_TERRAIN_PARTS frames. `edits` holds
## {"op", "entity_id", "record"} where record is an encoded stage record for add/update. Zero edits
## is a valid version advance. Returns an empty array (never a truncated commit) when the edit
## count, part count or a record is invalid.
static func encode_terrain_parts(header: Dictionary, edits: Array) -> Array[PackedByteArray]:
	var empty: Array[PackedByteArray] = []
	var base_version := int(header.get("base_version", -1))
	var new_version := int(header.get("new_version", -1))
	if (
		edits.size() > MAX_TERRAIN_EDITS
		or int(header.get("match_id", 0)) <= 0
		or base_version < 0
		or new_version != base_version + 1
	):
		return empty
	var encoded_edits: Array[PackedByteArray] = []
	for edit_variant in edits:
		var edit: Dictionary = edit_variant
		var op := int(edit.get("op", 0))
		var entity_id := int(edit.get("entity_id", 0))
		if entity_id <= 0 or op < EditOp.ADD or op > EditOp.REMOVE:
			return empty
		var stream := StreamPeerBuffer.new()
		stream.big_endian = false
		stream.put_u8(op)
		stream.put_u64(entity_id)
		if op != EditOp.REMOVE:
			var record: PackedByteArray = edit.get("record", PackedByteArray())
			if record.size() < 36 or record.size() > MAX_STAGE_RECORD_BYTES:
				return empty
			stream.put_u16(record.size())
			stream.put_data(record)
		encoded_edits.append(stream.data_array)
	var groups: Array = [[]]
	var group_bytes := TERRAIN_HEADER_BYTES
	for encoded in encoded_edits:
		if group_bytes + encoded.size() > NetworkFrame.MAX_PAYLOAD_BYTES:
			groups.append([])
			group_bytes = TERRAIN_HEADER_BYTES
		(groups.back() as Array).append(encoded)
		group_bytes += encoded.size()
	if groups.size() > MAX_TERRAIN_PARTS:
		return empty
	var parts: Array[PackedByteArray] = []
	for index in groups.size():
		var group: Array = groups[index]
		var stream := StreamPeerBuffer.new()
		stream.big_endian = false
		stream.put_u64(int(header.get("match_id", 0)))
		stream.put_u32(int(header.get("round_id", 0)) & 0xffffffff)
		stream.put_u32(base_version & 0xffffffff)
		stream.put_u32(new_version & 0xffffffff)
		stream.put_u32(int(header.get("commit_tick", 0)) & 0xffffffff)
		stream.put_u8(index)
		stream.put_u8(groups.size())
		stream.put_u8(group.size())
		for encoded in group:
			stream.put_data(encoded)
		parts.append(stream.data_array)
	return parts


static func decode_terrain_commit(payload: PackedByteArray) -> Dictionary:
	if payload.size() < TERRAIN_HEADER_BYTES or payload.size() > NetworkFrame.MAX_PAYLOAD_BYTES:
		return {"ok": false}
	var stream := _reader(payload)
	var commit := {
		"match_id": stream.get_u64(),
		"round_id": stream.get_u32(),
		"base_version": stream.get_u32(),
		"new_version": stream.get_u32(),
		"commit_tick": stream.get_u32(),
		"part_index": stream.get_u8(),
		"part_count": stream.get_u8(),
		"edit_count": stream.get_u8(),
		"edits": [],
	}
	if (
		int(commit.match_id) <= 0
		or int(commit.new_version) != int(commit.base_version) + 1
		or int(commit.part_count) < 1
		or int(commit.part_count) > MAX_TERRAIN_PARTS
		or int(commit.part_index) >= int(commit.part_count)
		or int(commit.edit_count) > MAX_TERRAIN_EDITS
	):
		return {"ok": false}
	var edits: Array[Dictionary] = []
	var seen := {}
	for _index in int(commit.edit_count):
		if stream.get_position() + TERRAIN_REMOVE_EDIT_BYTES > payload.size():
			return {"ok": false}
		var op := int(stream.get_u8())
		var entity_id := stream.get_u64()
		if entity_id <= 0 or op < EditOp.ADD or op > EditOp.REMOVE or seen.has(entity_id):
			return {"ok": false}
		seen[entity_id] = true
		var edit := {"op": op, "entity_id": entity_id}
		if op != EditOp.REMOVE:
			if stream.get_position() + 2 > payload.size():
				return {"ok": false}
			var length := int(stream.get_u16())
			if length < 36 or length > MAX_STAGE_RECORD_BYTES or stream.get_position() + length > payload.size():
				return {"ok": false}
			var raw := stream.get_data(length)
			if int(raw[0]) != OK:
				return {"ok": false}
			var entity := NetworkMatchCodec.decode_stage_record(raw[1])
			if not bool(entity.get("ok", false)) or int(entity.entity_id) != entity_id:
				return {"ok": false}
			edit.entity = entity
		edits.append(edit)
	if stream.get_position() != payload.size():
		return {"ok": false}
	commit.edits = edits
	commit.ok = true
	return commit


static func _reader(payload: PackedByteArray) -> StreamPeerBuffer:
	var stream := StreamPeerBuffer.new()
	stream.big_endian = false
	stream.data_array = payload
	return stream

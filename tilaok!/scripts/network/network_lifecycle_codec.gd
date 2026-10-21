class_name NetworkLifecycleCodec
extends RefCounted

## Contract v1.5 (NLB-P08) byte layouts. Little-endian, exact sizes, every field range-checked.
## Nothing here ever logs or echoes a reclaim token.
const ID_BYTES := 16
const TOKEN_BYTES := 16
const NONCE_BYTES := 16
const PAUSE_STATE_BYTES := 26
const LIFECYCLE_HINT_BYTES := 9
const RECLAIM_BEGIN_BYTES := 36
const RECLAIM_RESULT_BYTES := 27
const SEAT_ASSIGNMENT_BYTES := 38

## Contract v1.6 (NLB-P09) additions: the in-place replay re-key and the host SESSION_CLOSE notice.
const REKEY_BYTES := 34
const REKEY_ACK_BYTES := 12
## Client to host stays the v1.2 two-byte reason; only the host notice grows.
const SESSION_CLOSE_CLIENT_BYTES := 2
const SESSION_CLOSE_HOST_BYTES := 11
const REKEY_FLAG_UNVERIFIED := 1

enum PauseState { RUNNING = 0, PAUSED = 1 }
## Why a session ended, as seen by the peer that has to show it. Never free text.
enum SessionEnd {
	NONE = 0,
	HOST_LOST = 1,
	HOST_CLOSED = 2,
	LOBBY_RETURN = 3,
	HOST_QUIT = 4,
	CLIENT_LEFT = 5,
	REPLAY_UNAVAILABLE = 6,
}
enum PauseReason { HOST_REQUEST = 0, FOCUS = 1, SYSTEM = 2 }
enum Hint { FOREGROUND = 0, BACKGROUND = 1, FOCUS_OUT = 2, FOCUS_IN = 3 }


static func encode_pause_state(record: Dictionary) -> PackedByteArray:
	var epoch := int(record.get("epoch", 0))
	var state := int(record.get("state", -1))
	var reason := int(record.get("reason", -1))
	if (
		epoch <= 0
		or epoch > 0xffffffff
		or state < PauseState.RUNNING
		or state > PauseState.PAUSED
		or reason < PauseReason.HOST_REQUEST
		or reason > PauseReason.SYSTEM
	):
		return PackedByteArray()
	var stream := _writer()
	stream.put_u64(int(record.get("match_id", 0)))
	stream.put_u32(int(record.get("round_id", 0)) & 0xffffffff)
	stream.put_u32(int(record.get("attempt_id", 0)) & 0xffffffff)
	stream.put_u32(epoch)
	stream.put_u32(int(record.get("host_tick", 0)) & 0xffffffff)
	stream.put_u8(state)
	stream.put_u8(reason)
	return stream.data_array


static func decode_pause_state(payload: PackedByteArray) -> Dictionary:
	if payload.size() != PAUSE_STATE_BYTES:
		return {"ok": false}
	var stream := _reader(payload)
	var record := {
		"match_id": stream.get_u64(),
		"round_id": stream.get_u32(),
		"attempt_id": stream.get_u32(),
		"epoch": stream.get_u32(),
		"host_tick": stream.get_u32(),
		"state": stream.get_u8(),
		"reason": stream.get_u8(),
	}
	if (
		int(record.epoch) == 0
		or int(record.state) > PauseState.PAUSED
		or int(record.reason) > PauseReason.SYSTEM
	):
		return {"ok": false}
	record["ok"] = true
	return record


static func encode_lifecycle_hint(peer_generation: int, client_seq: int, state: int) -> PackedByteArray:
	if peer_generation <= 0 or state < Hint.FOREGROUND or state > Hint.FOCUS_IN:
		return PackedByteArray()
	var stream := _writer()
	stream.put_u32(peer_generation)
	stream.put_u32(client_seq & 0xffffffff)
	stream.put_u8(state)
	return stream.data_array


static func decode_lifecycle_hint(payload: PackedByteArray) -> Dictionary:
	if payload.size() != LIFECYCLE_HINT_BYTES:
		return {"ok": false}
	var stream := _reader(payload)
	var record := {
		"peer_generation": stream.get_u32(),
		"client_seq": stream.get_u32(),
		"state": stream.get_u8(),
	}
	if int(record.peer_generation) == 0 or int(record.state) > Hint.FOCUS_IN:
		return {"ok": false}
	record["ok"] = true
	return record


static func encode_reclaim_begin(
	player_id: PackedByteArray, client_nonce: PackedByteArray, last_snapshot_id: int
) -> PackedByteArray:
	if player_id.size() != ID_BYTES or client_nonce.size() != NONCE_BYTES:
		return PackedByteArray()
	var payload := PackedByteArray()
	payload.append_array(player_id)
	payload.append_array(client_nonce)
	var tail := _writer()
	tail.put_u32(last_snapshot_id & 0xffffffff)
	payload.append_array(tail.data_array)
	return payload


static func decode_reclaim_begin(payload: PackedByteArray) -> Dictionary:
	if payload.size() != RECLAIM_BEGIN_BYTES:
		return {"ok": false}
	var tail := _reader(payload.slice(32, 36))
	return {
		"ok": true,
		"player_id": payload.slice(0, ID_BYTES),
		"client_nonce": payload.slice(ID_BYTES, ID_BYTES + NONCE_BYTES),
		"last_snapshot_id": tail.get_u32(),
	}


## `token` is the rotated reclaim token on OK and sixteen zero bytes on every refusal.
static func encode_reclaim_result(
	reason: int, seat: int, peer_generation: int, token: PackedByteArray, remaining_ms: int
) -> PackedByteArray:
	if reason < 0 or reason > 0xffff or seat < 0 or seat > 3 or token.size() != TOKEN_BYTES:
		return PackedByteArray()
	var stream := _writer()
	stream.put_u16(reason)
	stream.put_u8(seat)
	stream.put_u32(peer_generation & 0xffffffff)
	stream.put_data(token)
	stream.put_u32(clampi(remaining_ms, 0, 0xffffffff))
	return stream.data_array


static func decode_reclaim_result(payload: PackedByteArray) -> Dictionary:
	if payload.size() != RECLAIM_RESULT_BYTES:
		return {"ok": false}
	var stream := _reader(payload)
	var record := {"reason": stream.get_u16(), "seat": stream.get_u8()}
	record["peer_generation"] = stream.get_u32()
	var token_data := stream.get_data(TOKEN_BYTES)
	record["token"] = token_data[1] if int(token_data[0]) == OK else PackedByteArray()
	record["remaining_ms"] = stream.get_u32()
	if int(record.seat) > 3:
		return {"ok": false}
	record["ok"] = true
	return record


static func encode_seat_assignment(
	seat: int, peer_generation: int, player_id: PackedByteArray, token: PackedByteArray
) -> PackedByteArray:
	if seat < 0 or seat > 3 or player_id.size() != ID_BYTES or token.size() != TOKEN_BYTES:
		return PackedByteArray()
	var payload := PackedByteArray([seat, seat + 1])
	var generation := _writer()
	generation.put_u32(peer_generation & 0xffffffff)
	payload.append_array(generation.data_array)
	payload.append_array(player_id)
	payload.append_array(token)
	return payload


static func decode_seat_assignment(payload: PackedByteArray) -> Dictionary:
	if (
		payload.size() != SEAT_ASSIGNMENT_BYTES
		or int(payload[0]) > 3
		or int(payload[1]) != int(payload[0]) + 1
	):
		return {"ok": false}
	var generation := _reader(payload.slice(2, 6))
	return {
		"ok": true,
		"seat": int(payload[0]),
		"peer_generation": generation.get_u32(),
		"player_id": payload.slice(6, 6 + ID_BYTES),
		"token": payload.slice(6 + ID_BYTES, 6 + ID_BYTES + TOKEN_BYTES),
	}


## Sent under the OLD epoch envelope; carries the identity the peer must adopt before it acks.
static func encode_rekey(
	new_epoch: int, new_match_id: int, route: int, flags: int, token: PackedByteArray
) -> PackedByteArray:
	if (
		new_epoch <= 0
		or new_match_id <= 0
		or route < 0
		or route > 0xff
		or flags < 0
		or flags > REKEY_FLAG_UNVERIFIED
		or token.size() != TOKEN_BYTES
	):
		return PackedByteArray()
	var stream := _writer()
	stream.put_u64(new_epoch)
	stream.put_u64(new_match_id)
	stream.put_u8(route)
	stream.put_u8(flags)
	stream.put_data(token)
	return stream.data_array


static func decode_rekey(payload: PackedByteArray) -> Dictionary:
	if payload.size() != REKEY_BYTES:
		return {"ok": false}
	var stream := _reader(payload)
	var record := {
		"new_epoch": stream.get_u64(),
		"new_match_id": stream.get_u64(),
		"route": stream.get_u8(),
		"flags": stream.get_u8(),
	}
	var token_data := stream.get_data(TOKEN_BYTES)
	record["token"] = token_data[1] if int(token_data[0]) == OK else PackedByteArray()
	if (
		int(record.new_epoch) <= 0
		or int(record.new_match_id) <= 0
		or int(record.flags) > REKEY_FLAG_UNVERIFIED
		or (record.token as PackedByteArray).size() != TOKEN_BYTES
	):
		return {"ok": false}
	record["ok"] = true
	return record


## Sent under the NEW epoch envelope, which is itself the proof that the peer adopted it.
static func encode_rekey_ack(new_epoch: int, peer_generation: int) -> PackedByteArray:
	if new_epoch <= 0 or peer_generation <= 0 or peer_generation > 0xffffffff:
		return PackedByteArray()
	var stream := _writer()
	stream.put_u64(new_epoch)
	stream.put_u32(peer_generation)
	return stream.data_array


static func decode_rekey_ack(payload: PackedByteArray) -> Dictionary:
	if payload.size() != REKEY_ACK_BYTES:
		return {"ok": false}
	var stream := _reader(payload)
	var record := {"new_epoch": stream.get_u64(), "peer_generation": stream.get_u32()}
	if int(record.new_epoch) <= 0 or int(record.peer_generation) <= 0:
		return {"ok": false}
	record["ok"] = true
	return record


## Host to client: the v1.2 reason plus why the session ended, the last committed ledger revision
## and the host tick. Credentials never travel here.
static func encode_session_close_host(
	reason: int, end: int, ledger_revision: int, host_tick: int
) -> PackedByteArray:
	if (
		reason < 0
		or reason > 0xffff
		or end < SessionEnd.HOST_LOST
		or end > SessionEnd.REPLAY_UNAVAILABLE
	):
		return PackedByteArray()
	var stream := _writer()
	stream.put_u16(reason)
	stream.put_u8(end)
	stream.put_u32(clampi(ledger_revision, 0, 0xffffffff))
	stream.put_u32(host_tick & 0xffffffff)
	return stream.data_array


## An unknown or malformed notice still ends the session: it decodes as HOST_LOST, never as a
## reason to stay on a stale match view.
static func decode_session_close_host(payload: PackedByteArray) -> Dictionary:
	if payload.size() == SESSION_CLOSE_HOST_BYTES:
		var stream := _reader(payload)
		var reason := stream.get_u16()
		var end := stream.get_u8()
		if end >= SessionEnd.HOST_LOST and end <= SessionEnd.REPLAY_UNAVAILABLE:
			return {
				"ok": true,
				"reason": reason,
				"end": end,
				"ledger_revision": stream.get_u32(),
				"host_tick": stream.get_u32(),
			}
	return {
		"ok": false,
		"reason": NetworkFrame.Reason.SESSION_CLOSED,
		"end": SessionEnd.HOST_LOST,
		"ledger_revision": 0,
		"host_tick": 0,
	}


static func _writer() -> StreamPeerBuffer:
	var stream := StreamPeerBuffer.new()
	stream.big_endian = false
	return stream


static func _reader(bytes: PackedByteArray) -> StreamPeerBuffer:
	var stream := StreamPeerBuffer.new()
	stream.big_endian = false
	stream.data_array = bytes
	return stream

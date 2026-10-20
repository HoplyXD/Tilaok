# gdlint: disable=class-definitions-order
class_name NetworkFrame
extends RefCounted

## Exact TILK v1 envelope. Application payloads are raw ENet bytes; no Variant/RPC framing.
const MAGIC := "TILK"
const MAJOR := 1
const MINOR := 2
const SCHEMA := 2
const FEATURE_BASE_MASK := 0x000f
const FEATURE_LOGICAL_INPUT := 0x0010
const FEATURE_AUTHORITATIVE_VIEW := 0x0020
const FEATURE_SNAPSHOT_RECOVERY := 0x0040
const FEATURE_P04_MASK := 0x007f
const HEADER_BYTES := 22
const MAX_FRAME_BYTES := 900
const MAX_DISCOVERY_BYTES := 256
const DISCOVERY_FAMILIES := [1, 2]
const FAMILIES := [
	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14,	15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26
]

enum Family {
	DISCOVERY_QUERY = 0x01,
	BEACON = 0x02,
	COMPATIBILITY_HELLO = 0x03,
	COMPATIBILITY_RESULT = 0x04,
	JOIN_BEGIN = 0x05,
	CHALLENGE = 0x06,
	PROOF = 0x07,
	ADMISSION_DECISION = 0x08,
	SEAT_ASSIGNMENT = 0x09,
	ASSIGNMENT_ACK = 0x0A,
	LOBBY_STATE = 0x0B,
	READY_REQUEST = 0x0C,
	READY_RESULT = 0x0D,
	SESSION_CLOSE = 0x0E,
	MATCH_LIFECYCLE = 0x0F,
	CONTINUOUS_INPUT = 0x10,
	ACTION_REQUEST = 0x11,
	ACTION_RESULT = 0x12,
	STATE_UPDATE = 0x13,
	SNAPSHOT_REQUEST = 0x14,
	SNAPSHOT_CHUNK = 0x15,
	SNAPSHOT_END = 0x16,
	SNAPSHOT_ACK = 0x17,
	SYNC_READY = 0x18,
	AUTHORITATIVE_EVENT = 0x19,
	TERRAIN_COMMIT = 0x1A,
}


static func channel_for_family(family: int) -> int:
	match family:
		Family.CONTINUOUS_INPUT:
			return RawEnetTransport.INPUT_CHANNEL
		Family.STATE_UPDATE:
			return RawEnetTransport.STATE_CHANNEL
		_:
			return RawEnetTransport.CONTROL_CHANNEL


static func family_allowed_on_channel(family: int, channel: int) -> bool:
	return family in FAMILIES and channel_for_family(family) == channel

enum Reason {
	OK = 0,
	MALFORMED = 1,
	UNSUPPORTED_VERSION = 2,
	INCOMPATIBLE = 3,
	TOKEN_INVALID = 4,
	TOKEN_EXPIRED = 5,
	APPROVAL_REQUIRED = 6,
	LOBBY_CLOSED = 7,
	LOBBY_FULL = 8,
	WRONG_PHASE = 9,
	OWNERSHIP = 10,
	STALE_STATE = 11,
	FIELD_RANGE = 12,
	RATE_LIMIT = 13,
	REQUEST_ID_REUSE = 14,
	REQUEST_CAPACITY = 15,
	INVENTORY = 16,
	PLACEMENT_BLOCKED = 17,
	ROUND_ENDED = 18,
	CONTENT_LIMIT_EXCEEDED = 19,
	SNAPSHOT_LIMIT = 20,
	SNAPSHOT_INVALID = 21,
	RESYNC_FAILED = 22,
	HOST_ONLY = 23,
	SESSION_CLOSED = 24,
	INTERNAL_RETRY = 25,
}


static func encode(
	family: int, epoch: int, sequence: int, payload: PackedByteArray
) -> PackedByteArray:
	if family not in FAMILIES or payload.size() > MAX_FRAME_BYTES - HEADER_BYTES:
		return PackedByteArray()
	if sequence < 0 or sequence > 0xffffffff:
		return PackedByteArray()
	var stream := StreamPeerBuffer.new()
	stream.big_endian = false
	stream.put_data(MAGIC.to_ascii_buffer())
	stream.put_u8(MAJOR)
	stream.put_u8(MINOR)
	stream.put_u8(family)
	stream.put_u8(0)
	stream.put_u64(epoch)
	stream.put_u32(sequence)
	stream.put_u16(payload.size())
	stream.put_data(payload)
	return stream.data_array


static func decode(
	frame: PackedByteArray, expected_epoch: int = -1, discovery: bool = false
) -> Dictionary:
	var max_size := MAX_DISCOVERY_BYTES if discovery else MAX_FRAME_BYTES
	if frame.size() < HEADER_BYTES or frame.size() > max_size:
		return {"ok": false, "reason": Reason.MALFORMED}
	var stream := StreamPeerBuffer.new()
	stream.big_endian = false
	stream.data_array = frame
	if stream.get_data(4)[1] != MAGIC.to_ascii_buffer():
		return {"ok": false, "reason": Reason.MALFORMED}
	var major := stream.get_u8()
	var minor := stream.get_u8()
	var family := stream.get_u8()
	var flags := stream.get_u8()
	var epoch := stream.get_u64()
	var sequence := stream.get_u32()
	var length := stream.get_u16()
	if major != MAJOR:
		return {"ok": false, "reason": Reason.UNSUPPORTED_VERSION}
	if (
		minor > MINOR
		or flags != 0
		or family not in FAMILIES
		or length != frame.size() - HEADER_BYTES
	):
		return {"ok": false, "reason": Reason.MALFORMED}
	if discovery != (family in DISCOVERY_FAMILIES):
		return {"ok": false, "reason": Reason.MALFORMED}
	if discovery and epoch != 0:
		return {"ok": false, "reason": Reason.MALFORMED}
	if expected_epoch >= 0 and epoch != expected_epoch:
		return {"ok": false, "reason": Reason.STALE_STATE}
	return {
		"ok": true,
		"major": major,
		"minor": minor,
		"family": family,
		"epoch": epoch,
		"sequence": sequence,
		"payload": frame.slice(HEADER_BYTES)
	}

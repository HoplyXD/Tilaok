class_name NetworkResultsCodec
extends RefCounted

## Contract v1.6 (NLB-P09) byte layouts for the replicated result ledger, the result vote and the
## client's result action. Little-endian, exact sizes, every field range-checked. Scores are signed
## eighth-point integer units end to end; nothing here carries a float, a Color or a display string.
## The host never sends free text: causes and award keys are small enums.
const COMMON_BYTES := 23
const ACTION_BYTES := 27
const VOTE_BYTES := 23
const MAX_ENTRIES := 128
const MAX_AWARDS_PER_SEAT := 8
const MAX_SEATS := 4
const MAX_ROUND := 64
const NO_SEAT := -1
const MAX_EVENT_BYTES := COMMON_BYTES + 12 + 1 + MAX_SEATS * (14 + MAX_AWARDS_PER_SEAT * 3)

enum Kind { ROUND = 1, SD_ENTRY = 2, SD_RESULT = 3, FINAL = 4 }
enum ScoringFamily { RACE = 1, LAGSANAY = 2, KANGAROO = 3 }
enum Suppression { NONE = 0, NO_FINISHER = 1, ALL_FINISHED = 2 }
enum Decision { CONTINUE = 1, WINNER = 2, SUDDEN_DEATH = 3 }
enum Terminal { NONE = 0, SCORE_TARGET = 1, ROUND_LIMIT = 2 }
enum Outcome { NONE = 0, FINISHED = 1, ELIMINATED = 2 }
enum Cause {
	NONE = 0,
	GOAL = 1,
	DIRECT_HAZARD = 2,
	HAZARD = 3,
	ELIMINATION = 4,
	HARD_CAP = 5,
	POST_FINISH_DEADLINE = 6,
	TIMEOUT = 7,
	COMMAND_FAILURE = 8,
	DISCONNECT = 9,
	BOUNDS = 10,
}
enum AwardKey { TAPOS = 1, UNA = 2, BAYANI = 3, BAWI = 4, BARYA = 5, PATIBONG = 6, PLACEMENT = 7 }
## What a phone may ask of the host from the results screens.
enum ResultAction { CONTINUE = 1, VOTE_REPLAY = 2, VOTE_LOBBY = 3 }

const CAUSE_NAMES := {
	"": Cause.NONE,
	"goal": Cause.GOAL,
	"direct_hazard": Cause.DIRECT_HAZARD,
	"hazard": Cause.HAZARD,
	"elimination": Cause.ELIMINATION,
	"hard_cap": Cause.HARD_CAP,
	"post_finish_deadline": Cause.POST_FINISH_DEADLINE,
	"timeout": Cause.TIMEOUT,
	"command_failure": Cause.COMMAND_FAILURE,
	"disconnect": Cause.DISCONNECT,
	"bounds": Cause.BOUNDS,
}
const AWARD_NAMES := {
	"tapos": AwardKey.TAPOS,
	"una": AwardKey.UNA,
	"bayani": AwardKey.BAYANI,
	"bawi": AwardKey.BAWI,
	"barya": AwardKey.BARYA,
	"patibong": AwardKey.PATIBONG,
	"placement": AwardKey.PLACEMENT,
}


## Host cause string to wire enum. A string with no entry is an elimination (ambiguous source).
static func cause_code(name: String) -> int:
	return int(CAUSE_NAMES.get(name, Cause.ELIMINATION))


static func cause_name(code: int) -> String:
	for key in CAUSE_NAMES:
		if int(CAUSE_NAMES[key]) == code:
			return String(key)
	return ""


## -1 when the key has no wire code; the caller refuses to commit such a row.
static func award_code(key: String) -> int:
	return int(AWARD_NAMES.get(key, -1))


static func award_name(code: int) -> String:
	for key in AWARD_NAMES:
		if int(AWARD_NAMES[key]) == code:
			return String(key)
	return ""


static func mask_of(seats: Array) -> int:
	var mask := 0
	for seat in seats:
		var index := int(seat)
		if index >= 0 and index < MAX_SEATS:
			mask |= 1 << index
	return mask


static func seats_of(mask: int) -> Array[int]:
	var seats: Array[int] = []
	for index in MAX_SEATS:
		if (mask & (1 << index)) != 0:
			seats.append(index)
	return seats


## Structural validation shared by encode and decode. Cross-entry rules (revision, previous total)
## live in ClientResultsModel and ResultLedger.
static func entry_is_valid(entry: Dictionary) -> bool:
	var kind := int(entry.get("kind", 0))
	if kind < Kind.ROUND or kind > Kind.FINAL:
		return false
	if (
		int(entry.get("match_id", 0)) <= 0
		or int(entry.get("round_id", -1)) < 0
		or int(entry.get("round_id", -1)) > MAX_ROUND
		or int(entry.get("attempt_id", -1)) < 0
		or int(entry.get("attempt_id", -1)) > 0xffff
		or int(entry.get("event_id", 0)) <= 0
		or int(entry.get("event_id", 0)) > MAX_ENTRIES
		or int(entry.get("revision", 0)) <= 0
		or int(entry.get("revision", 0)) > MAX_ENTRIES
	):
		return false
	match kind:
		Kind.ROUND:
			return _round_is_valid(entry)
		Kind.SD_ENTRY:
			return (
				_seat_totals_are_valid(entry.get("seats", []))
				and _mask_is_valid(int(entry.get("tied_mask", 0)), true)
				and int(entry.get("sd_attempt", 0)) > 0
				and int(entry.get("sd_attempt", 0)) <= 0xff
				and _terminal_is_valid(int(entry.get("terminal_reason", -1)), true)
			)
		Kind.SD_RESULT:
			return (
				_seat_is_valid(int(entry.get("winner_seat", -2)), false)
				and int(entry.get("last_cluck", -1)) >= 0
				and int(entry.get("last_cluck", -1)) <= 1
				and int(entry.get("sd_attempt", 0)) > 0
				and int(entry.get("sd_attempt", 0)) <= 0xff
			)
		Kind.FINAL:
			return (
				_seat_totals_are_valid(entry.get("seats", []))
				and _seat_is_valid(int(entry.get("winner_seat", -2)), false)
				and int(entry.get("last_cluck", -1)) >= 0
				and int(entry.get("last_cluck", -1)) <= 1
				and int(entry.get("sudden_death", -1)) >= 0
				and int(entry.get("sudden_death", -1)) <= 1
				and _terminal_is_valid(int(entry.get("terminal_reason", -1)), true)
			)
	return false


static func encode_event(entry: Dictionary) -> PackedByteArray:
	if not entry_is_valid(entry):
		return PackedByteArray()
	var stream := _writer()
	var kind := int(entry.kind)
	stream.put_u8(kind)
	stream.put_u64(int(entry.match_id))
	stream.put_u32(int(entry.round_id))
	stream.put_u16(int(entry.attempt_id))
	stream.put_u32(int(entry.event_id))
	stream.put_u32(int(entry.revision))
	match kind:
		Kind.ROUND:
			_put_round_body(stream, entry)
		Kind.SD_ENTRY:
			stream.put_u8(int(entry.tied_mask))
			stream.put_u8(int(entry.sd_attempt))
			stream.put_u8(int(entry.terminal_reason))
			_put_seat_totals(stream, entry.seats)
		Kind.SD_RESULT:
			stream.put_8(int(entry.winner_seat))
			stream.put_u8(int(entry.last_cluck))
			stream.put_u8(int(entry.sd_attempt))
		Kind.FINAL:
			stream.put_8(int(entry.winner_seat))
			stream.put_u8(int(entry.last_cluck))
			stream.put_u8(int(entry.sudden_death))
			stream.put_u8(int(entry.terminal_reason))
			_put_seat_totals(stream, entry.seats)
	if stream.data_array.size() > MAX_EVENT_BYTES:
		return PackedByteArray()
	return stream.data_array


## Exact length, no trailing bytes, every enum known. `{"ok": false}` on any violation.
static func decode_event(payload: PackedByteArray) -> Dictionary:
	if payload.size() < COMMON_BYTES + 3 or payload.size() > MAX_EVENT_BYTES:
		return {"ok": false}
	var stream := _reader(payload)
	var entry := {
		"kind": stream.get_u8(),
		"match_id": stream.get_u64(),
		"round_id": stream.get_u32(),
		"attempt_id": stream.get_u16(),
		"event_id": stream.get_u32(),
		"revision": stream.get_u32(),
	}
	var ok := false
	match int(entry.kind):
		Kind.ROUND:
			ok = _get_round_body(stream, entry)
		Kind.SD_ENTRY:
			entry["tied_mask"] = stream.get_u8()
			entry["sd_attempt"] = stream.get_u8()
			entry["terminal_reason"] = stream.get_u8()
			var sd_seats = _get_seat_totals(stream, payload.size())
			ok = sd_seats != null
			if ok:
				entry["seats"] = sd_seats
		Kind.SD_RESULT:
			if payload.size() == COMMON_BYTES + 3:
				entry["winner_seat"] = stream.get_8()
				entry["last_cluck"] = stream.get_u8()
				entry["sd_attempt"] = stream.get_u8()
				ok = true
		Kind.FINAL:
			entry["winner_seat"] = stream.get_8()
			entry["last_cluck"] = stream.get_u8()
			entry["sudden_death"] = stream.get_u8()
			entry["terminal_reason"] = stream.get_u8()
			var final_seats = _get_seat_totals(stream, payload.size())
			ok = final_seats != null
			if ok:
				entry["seats"] = final_seats
	if not ok or stream.get_position() != payload.size() or not entry_is_valid(entry):
		return {"ok": false}
	entry["ok"] = true
	return entry


static func encode_action(record: Dictionary) -> PackedByteArray:
	var action := int(record.get("action", 0))
	if (
		int(record.get("request_id", 0)) <= 0
		or int(record.get("match_id", 0)) <= 0
		or int(record.get("round_id", -1)) < 0
		or int(record.get("round_id", -1)) > 0xffffffff
		or int(record.get("attempt_id", -1)) < 0
		or int(record.get("attempt_id", -1)) > 0xffff
		or int(record.get("event_id", 0)) <= 0
		or int(record.get("event_id", 0)) > 0xffffffff
		or action < ResultAction.CONTINUE
		or action > ResultAction.VOTE_LOBBY
	):
		return PackedByteArray()
	var stream := _writer()
	stream.put_u64(int(record.request_id))
	stream.put_u64(int(record.match_id))
	stream.put_u32(int(record.round_id))
	stream.put_u16(int(record.attempt_id))
	stream.put_u32(int(record.event_id))
	stream.put_u8(action)
	return stream.data_array


static func decode_action(payload: PackedByteArray) -> Dictionary:
	if payload.size() != ACTION_BYTES:
		return {"ok": false}
	var stream := _reader(payload)
	var record := {
		"request_id": stream.get_u64(),
		"match_id": stream.get_u64(),
		"round_id": stream.get_u32(),
		"attempt_id": stream.get_u16(),
		"event_id": stream.get_u32(),
		"action": stream.get_u8(),
	}
	if (
		int(record.request_id) <= 0
		or int(record.match_id) <= 0
		or int(record.event_id) <= 0
		or int(record.action) < ResultAction.CONTINUE
		or int(record.action) > ResultAction.VOTE_LOBBY
	):
		return {"ok": false}
	record["ok"] = true
	return record


## `action` is the currently selected result action (-1 none, else ResultAction value).
static func encode_vote(record: Dictionary) -> PackedByteArray:
	var action := int(record.get("action", -1))
	if (
		int(record.get("match_id", 0)) <= 0
		or int(record.get("round_id", -1)) < 0
		or int(record.get("round_id", -1)) > 0xffffffff
		or int(record.get("event_id", 0)) <= 0
		or int(record.get("event_id", 0)) > 0xffffffff
		or int(record.get("vote_seq", -1)) < 0
		or int(record.get("vote_seq", -1)) > 0xffffffff
		or action < -1
		or action > ResultAction.VOTE_LOBBY
		or action == 0
		or not _mask_is_valid(int(record.get("ready_mask", -1)), true)
		or not _mask_is_valid(int(record.get("required_mask", -1)), true)
		or (int(record.ready_mask) & ~int(record.required_mask)) != 0
	):
		return PackedByteArray()
	var stream := _writer()
	stream.put_u64(int(record.match_id))
	stream.put_u32(int(record.round_id))
	stream.put_u32(int(record.event_id))
	stream.put_u32(int(record.vote_seq))
	stream.put_8(action)
	stream.put_u8(int(record.ready_mask))
	stream.put_u8(int(record.required_mask))
	return stream.data_array


static func decode_vote(payload: PackedByteArray) -> Dictionary:
	if payload.size() != VOTE_BYTES:
		return {"ok": false}
	var stream := _reader(payload)
	var record := {
		"match_id": stream.get_u64(),
		"round_id": stream.get_u32(),
		"event_id": stream.get_u32(),
		"vote_seq": stream.get_u32(),
		"action": stream.get_8(),
		"ready_mask": stream.get_u8(),
		"required_mask": stream.get_u8(),
	}
	var action := int(record.action)
	if (
		int(record.match_id) <= 0
		or int(record.event_id) <= 0
		or action < -1
		or action > ResultAction.VOTE_LOBBY
		or action == 0
		or not _mask_is_valid(int(record.ready_mask), true)
		or not _mask_is_valid(int(record.required_mask), true)
		or (int(record.ready_mask) & ~int(record.required_mask)) != 0
	):
		return {"ok": false}
	record["ok"] = true
	return record


static func _round_is_valid(entry: Dictionary) -> bool:
	var family := int(entry.get("family", 0))
	var decision := int(entry.get("decision", 0))
	var seats = entry.get("seats", [])
	if (
		family < ScoringFamily.RACE
		or family > ScoringFamily.KANGAROO
		or int(entry.get("suppression", -1)) < Suppression.NONE
		or int(entry.get("suppression", -1)) > Suppression.ALL_FINISHED
		or int(entry.get("finisher_count", -1)) < 0
		or int(entry.get("finisher_count", -1)) > MAX_SEATS
		or not _mask_is_valid(int(entry.get("first_mask", -1)), true)
		or not _seat_is_valid(int(entry.get("last_cluck_seat", -2)), false)
		or not _seat_is_valid(int(entry.get("barya_seat", -2)), false)
		or decision < Decision.CONTINUE
		or decision > Decision.SUDDEN_DEATH
		or not _seat_is_valid(int(entry.get("winner_seat", -2)), false)
		or not _mask_is_valid(int(entry.get("tied_mask", -1)), true)
		or not _terminal_is_valid(int(entry.get("terminal_reason", -1)), true)
		or int(entry.get("round_id", 0)) <= 0
		or not (seats is Array)
		or (seats as Array).size() < 2
		or (seats as Array).size() > MAX_SEATS
	):
		return false
	if decision == Decision.WINNER and int(entry.winner_seat) < 0:
		return false
	if decision != Decision.WINNER and int(entry.winner_seat) >= 0:
		return false
	if decision == Decision.CONTINUE and int(entry.terminal_reason) != Terminal.NONE:
		return false
	if decision != Decision.CONTINUE and int(entry.terminal_reason) == Terminal.NONE:
		return false
	var seen := 0
	for seat_variant in seats:
		if not (seat_variant is Dictionary):
			return false
		var seat: Dictionary = seat_variant
		var index := int(seat.get("seat", -1))
		if index < 0 or index >= MAX_SEATS or (seen & (1 << index)) != 0:
			return false
		seen |= 1 << index
		if (
			int(seat.get("outcome", -1)) < Outcome.NONE
			or int(seat.get("outcome", -1)) > Outcome.ELIMINATED
			or int(seat.get("cause", -1)) < Cause.NONE
			or int(seat.get("cause", -1)) > Cause.BOUNDS
			or not _seat_is_valid(int(seat.get("owner", -2)), false)
			or int(seat.get("placement", -1)) < 0
			or int(seat.get("placement", -1)) > MAX_SEATS
			or int(seat.get("total", -1)) < 0
			or int(seat.get("total", -1)) > 0x7fffffff
			or abs(int(seat.get("delta", 0))) > 0x7fffffff
		):
			return false
		var awards = seat.get("awards", [])
		if not (awards is Array) or (awards as Array).size() > MAX_AWARDS_PER_SEAT:
			return false
		var sum := 0
		for award_variant in awards:
			if not (award_variant is Dictionary):
				return false
			var award: Dictionary = award_variant
			var key := int(award.get("key", 0))
			var units := int(award.get("units", 0x10000))
			if key < AwardKey.TAPOS or key > AwardKey.PLACEMENT or units < -0x8000 or units > 0x7fff:
				return false
			sum += units
		if sum != int(seat.get("delta", 0)):
			return false
	if (seen & int(entry.first_mask)) != int(entry.first_mask):
		return false
	if decision == Decision.WINNER and (seen & (1 << int(entry.winner_seat))) == 0:
		return false
	if int(entry.tied_mask) != 0 and (seen & int(entry.tied_mask)) != int(entry.tied_mask):
		return false
	if decision == Decision.SUDDEN_DEATH and _popcount(int(entry.tied_mask)) < 2:
		return false
	if decision != Decision.SUDDEN_DEATH and int(entry.tied_mask) != 0:
		return false
	return true


static func _put_round_body(stream: StreamPeerBuffer, entry: Dictionary) -> void:
	stream.put_u8(int(entry.family))
	stream.put_u8(int(entry.suppression))
	stream.put_u8(int(entry.finisher_count))
	stream.put_u8(int(entry.first_mask))
	stream.put_8(int(entry.last_cluck_seat))
	stream.put_8(int(entry.barya_seat))
	stream.put_u8(int(entry.decision))
	stream.put_8(int(entry.winner_seat))
	stream.put_u8(int(entry.tied_mask))
	stream.put_u8(int(entry.terminal_reason))
	var seats: Array = entry.seats
	stream.put_u8(seats.size())
	for seat_variant in seats:
		var seat: Dictionary = seat_variant
		stream.put_u8(int(seat.seat))
		stream.put_u8(int(seat.outcome))
		stream.put_u8(int(seat.cause))
		stream.put_8(int(seat.owner))
		stream.put_u8(int(seat.placement))
		stream.put_32(int(seat.delta))
		stream.put_32(int(seat.total))
		var awards: Array = seat.awards
		stream.put_u8(awards.size())
		for award_variant in awards:
			var award: Dictionary = award_variant
			stream.put_u8(int(award.key))
			stream.put_16(int(award.units))


static func _get_round_body(stream: StreamPeerBuffer, entry: Dictionary) -> bool:
	if stream.get_available_bytes() < 11:
		return false
	entry["family"] = stream.get_u8()
	entry["suppression"] = stream.get_u8()
	entry["finisher_count"] = stream.get_u8()
	entry["first_mask"] = stream.get_u8()
	entry["last_cluck_seat"] = stream.get_8()
	entry["barya_seat"] = stream.get_8()
	entry["decision"] = stream.get_u8()
	entry["winner_seat"] = stream.get_8()
	entry["tied_mask"] = stream.get_u8()
	entry["terminal_reason"] = stream.get_u8()
	var count := stream.get_u8()
	if count < 2 or count > MAX_SEATS:
		return false
	var seats: Array[Dictionary] = []
	for _index in count:
		if stream.get_available_bytes() < 14:
			return false
		var seat := {
			"seat": stream.get_u8(),
			"outcome": stream.get_u8(),
			"cause": stream.get_u8(),
			"owner": stream.get_8(),
			"placement": stream.get_u8(),
			"delta": stream.get_32(),
			"total": stream.get_32(),
		}
		var award_count := stream.get_u8()
		if award_count > MAX_AWARDS_PER_SEAT or stream.get_available_bytes() < award_count * 3:
			return false
		var awards: Array[Dictionary] = []
		for _award in award_count:
			awards.append({"key": stream.get_u8(), "units": stream.get_16()})
		seat["awards"] = awards
		seats.append(seat)
	entry["seats"] = seats
	return true


static func _put_seat_totals(stream: StreamPeerBuffer, seats: Array) -> void:
	stream.put_u8(seats.size())
	for seat_variant in seats:
		var seat: Dictionary = seat_variant
		stream.put_u8(int(seat.seat))
		stream.put_32(int(seat.total))


## Null on any violation (a typed Array cannot be returned as a sentinel).
static func _get_seat_totals(stream: StreamPeerBuffer, size: int):
	if stream.get_position() + 1 > size:
		return null
	var count := stream.get_u8()
	if count < 2 or count > MAX_SEATS or stream.get_position() + count * 5 > size:
		return null
	var seats: Array[Dictionary] = []
	for _index in count:
		seats.append({"seat": stream.get_u8(), "total": stream.get_32()})
	return seats


static func _seat_totals_are_valid(seats_variant) -> bool:
	if not (seats_variant is Array):
		return false
	var seats: Array = seats_variant
	if seats.size() < 2 or seats.size() > MAX_SEATS:
		return false
	var seen := 0
	for seat_variant in seats:
		if not (seat_variant is Dictionary):
			return false
		var seat: Dictionary = seat_variant
		var index := int(seat.get("seat", -1))
		if index < 0 or index >= MAX_SEATS or (seen & (1 << index)) != 0:
			return false
		seen |= 1 << index
		if int(seat.get("total", -1)) < 0 or int(seat.get("total", -1)) > 0x7fffffff:
			return false
	return true


static func _seat_is_valid(seat: int, required: bool) -> bool:
	if required:
		return seat >= 0 and seat < MAX_SEATS
	return seat >= NO_SEAT and seat < MAX_SEATS


static func _mask_is_valid(mask: int, allow_zero: bool) -> bool:
	if mask < 0 or mask > 0x0f:
		return false
	return allow_zero or mask != 0


static func _terminal_is_valid(code: int, allow_none: bool) -> bool:
	if code < Terminal.NONE or code > Terminal.ROUND_LIMIT:
		return false
	return allow_none or code != Terminal.NONE


static func _popcount(mask: int) -> int:
	var count := 0
	for index in MAX_SEATS:
		if (mask & (1 << index)) != 0:
			count += 1
	return count


static func _writer() -> StreamPeerBuffer:
	var stream := StreamPeerBuffer.new()
	stream.big_endian = false
	return stream


static func _reader(bytes: PackedByteArray) -> StreamPeerBuffer:
	var stream := StreamPeerBuffer.new()
	stream.big_endian = false
	stream.data_array = bytes
	return stream

class_name MatchResultTypes
extends RefCounted

## Local match result enums and structural validation for the offline score ledger.
## Scores are signed eighth-point integer units end to end; nothing here carries a float, a Color
## or a display string.
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
	BOUNDS = 9,
}
enum AwardKey { TAPOS = 1, UNA = 2, BAYANI = 3, BAWI = 4, BARYA = 5, PATIBONG = 6, PLACEMENT = 7 }
## Result-screen choices used by the local results flow.
enum ResultAction { CONTINUE = 1, VOTE_REPLAY = 2, VOTE_LOBBY = 3 }

const MAX_ENTRIES := 128
const MAX_AWARDS_PER_SEAT := 8
const MAX_SEATS := 4
const MAX_ROUND := 64
const NO_SEAT := -1

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
			if (
				key < AwardKey.TAPOS
				or key > AwardKey.PLACEMENT
				or units < -0x8000
				or units > 0x7fff
			):
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
	while mask != 0:
		count += mask & 1
		mask >>= 1
	return count

class_name ClientResultsModel
extends RefCounted

## NLB-P09 client mirror of the host's committed result ledger. It never decides anything: every
## entry came from the host, and this model only refuses what breaks the ledger's own invariants, so
## a corrupt, replayed or out-of-order result can never reach a screen. Dedupe key is
## (match_id, round_id, attempt_id, event_id) plus the ledger revision; the revision must advance by
## exactly one, a repeat is idempotent, an older one is ignored and a gap asks for a snapshot.
## Scores are integer eighth-point units; display text is derived from units by the caller.

enum Apply { APPLIED, DUPLICATE, STALE, GAP, INVALID }

var match_id := 0
var vote: Dictionary = {}
var _entries: Array[Dictionary] = []
var _vote_sequence := -1


func reset(new_match_id: int = 0) -> void:
	match_id = new_match_id
	_entries.clear()
	vote = {}
	_vote_sequence = -1


func revision() -> int:
	return _entries.size()


func entries() -> Array[Dictionary]:
	var copy: Array[Dictionary] = []
	for entry in _entries:
		copy.append(entry.duplicate(true))
	return copy


func latest() -> Dictionary:
	return _entries.back().duplicate(true) if not _entries.is_empty() else {}


func latest_event_id() -> int:
	return int(_entries.back().event_id) if not _entries.is_empty() else 0


## Cumulative units per seat as of the last committed round (sudden death never changes them).
func totals() -> Dictionary:
	var result := {}
	for index in range(_entries.size() - 1, -1, -1):
		var entry: Dictionary = _entries[index]
		if int(entry.kind) == NetworkResultsCodec.Kind.ROUND:
			for seat_variant in entry.seats:
				var seat: Dictionary = seat_variant
				result[int(seat.seat)] = int(seat.total)
			break
	return result


func latest_round_entry() -> Dictionary:
	for index in range(_entries.size() - 1, -1, -1):
		if int(_entries[index].kind) == NetworkResultsCodec.Kind.ROUND:
			return _entries[index].duplicate(true)
	return {}


## Sudden death has been entered and not yet resolved: the phone shows "Sudden Death", not a round.
func is_sudden_death() -> bool:
	var entered := false
	for entry in _entries:
		if int(entry.kind) == NetworkResultsCodec.Kind.SD_ENTRY:
			entered = true
		elif int(entry.kind) in [NetworkResultsCodec.Kind.SD_RESULT, NetworkResultsCodec.Kind.FINAL]:
			entered = false
	return entered


func is_final() -> bool:
	return not _entries.is_empty() and int(_entries.back().kind) == NetworkResultsCodec.Kind.FINAL


func final_entry() -> Dictionary:
	return _entries.back().duplicate(true) if is_final() else {}


## Applies one RESULT_EVENT body. `current_match_id` is the session's active match.
func apply(entry: Dictionary, current_match_id: int) -> int:
	if not NetworkResultsCodec.entry_is_valid(entry):
		return Apply.INVALID
	if int(entry.match_id) != current_match_id:
		return Apply.STALE
	if match_id != current_match_id:
		reset(current_match_id)
	var revision_value := int(entry.revision)
	var count := _entries.size()
	if revision_value <= count:
		return (
			Apply.DUPLICATE
			if _entries[revision_value - 1].hash() == entry.hash()
			else Apply.STALE
		)
	if revision_value > count + 1:
		return Apply.GAP
	if int(entry.event_id) != revision_value or not _fits_ledger(entry):
		return Apply.INVALID
	_entries.append(entry.duplicate(true))
	return Apply.APPLIED


## Rebuilds the ledger from a snapshot's records. False when any entry is out of order or invalid,
## in which case the model is left empty and the caller asks for another snapshot.
func install_snapshot(snapshot_entries: Array, current_match_id: int) -> bool:
	reset(current_match_id)
	var ordered: Array[Dictionary] = []
	for entry_variant in snapshot_entries:
		ordered.append(entry_variant as Dictionary)
	ordered.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.revision) < int(b.revision))
	for entry in ordered:
		if apply(entry, current_match_id) != Apply.APPLIED:
			reset(current_match_id)
			return false
	return true


## One RESULT_VOTE. Only the vote for the latest ledger entry counts, and only a newer sequence.
func apply_vote(record: Dictionary, current_match_id: int) -> bool:
	if (
		int(record.get("match_id", -1)) != current_match_id
		or int(record.get("event_id", 0)) != latest_event_id()
		or latest_event_id() == 0
	):
		return false
	var sequence := int(record.get("vote_seq", 0))
	if _vote_sequence >= 0 and not _is_newer(sequence, _vote_sequence):
		return false
	_vote_sequence = sequence
	vote = record.duplicate(true)
	return true


## The ledger's own rules, checked against what is already committed.
func _fits_ledger(entry: Dictionary) -> bool:
	var previous: Dictionary = _entries.back() if not _entries.is_empty() else {}
	var previous_kind := int(previous.get("kind", 0))
	var committed_totals := totals()
	match int(entry.kind):
		NetworkResultsCodec.Kind.ROUND:
			if not previous.is_empty() and previous_kind != NetworkResultsCodec.Kind.ROUND:
				return false
			if (
				previous_kind == NetworkResultsCodec.Kind.ROUND
				and int(previous.decision) != NetworkResultsCodec.Decision.CONTINUE
			):
				return false
			if previous_kind == NetworkResultsCodec.Kind.ROUND and int(entry.round_id) <= int(previous.round_id):
				return false
			var best := -1
			for seat_variant in entry.seats:
				var seat: Dictionary = seat_variant
				if int(seat.total) - int(seat.delta) != int(committed_totals.get(int(seat.seat), 0)):
					return false
				best = maxi(best, int(seat.total))
			var leaders := 0
			for seat_variant in entry.seats:
				var seat: Dictionary = seat_variant
				if int(seat.total) == best:
					leaders |= 1 << int(seat.seat)
			if int(entry.decision) == NetworkResultsCodec.Decision.WINNER:
				if leaders != (1 << int(entry.winner_seat)):
					return false
			elif int(entry.decision) == NetworkResultsCodec.Decision.SUDDEN_DEATH:
				if leaders != int(entry.tied_mask):
					return false
			return true
		NetworkResultsCodec.Kind.SD_ENTRY:
			if (
				previous_kind != NetworkResultsCodec.Kind.ROUND
				or int(previous.decision) != NetworkResultsCodec.Decision.SUDDEN_DEATH
				or int(entry.tied_mask) != int(previous.tied_mask)
				or int(entry.round_id) != int(previous.round_id)
			):
				return false
			return _seat_totals_equal(entry.seats, committed_totals)
		NetworkResultsCodec.Kind.SD_RESULT:
			return (
				previous_kind == NetworkResultsCodec.Kind.SD_ENTRY
				and (int(previous.tied_mask) & (1 << int(entry.winner_seat))) != 0
				and int(entry.sd_attempt) == int(previous.sd_attempt)
			)
		NetworkResultsCodec.Kind.FINAL:
			if not _seat_totals_equal(entry.seats, committed_totals):
				return false
			if previous_kind == NetworkResultsCodec.Kind.ROUND:
				return (
					int(previous.decision) == NetworkResultsCodec.Decision.WINNER
					and int(entry.winner_seat) == int(previous.winner_seat)
					and int(entry.sudden_death) == 0
				)
			return (
				previous_kind == NetworkResultsCodec.Kind.SD_RESULT
				and int(entry.winner_seat) == int(previous.winner_seat)
				and int(entry.sudden_death) == 1
			)
	return false


static func _seat_totals_equal(seats: Array, committed_totals: Dictionary) -> bool:
	if seats.size() != committed_totals.size():
		return false
	for seat_variant in seats:
		var seat: Dictionary = seat_variant
		if int(committed_totals.get(int(seat.seat), -1)) != int(seat.total):
			return false
	return true


static func _is_newer(current: int, previous: int) -> bool:
	var difference := (current - previous) & 0xffffffff
	return difference > 0 and difference < 0x80000000

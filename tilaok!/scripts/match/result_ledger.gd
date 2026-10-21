class_name ResultLedger
extends RefCounted

## NLB-P09: the host's committed, append-only result ledger for one match. One entry per committed
## round result, sudden-death entry, sudden-death result and the final result. Entries hold integer
## eighth-point units and small enums only (NetworkResultsCodec), so the same record feeds the
## reliable RESULT_EVENT, the snapshot ledger records and the host/client comparison tests.
## It never decides anything: the calculators, the lifecycle coordinator and the Lagsanay
## controller stay the sole sources of scores and decisions. Offline play records it too, harmlessly.

signal committed(entry: Dictionary)

var match_id := 0
var _entries: Array[Dictionary] = []
var _keys: Dictionary = {}


func reset(new_match_id: int) -> void:
	match_id = new_match_id
	_entries.clear()
	_keys.clear()


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


func latest_round_id() -> int:
	return int(_entries.back().round_id) if not _entries.is_empty() else 0


func has_kind(kind: int) -> bool:
	for entry in _entries:
		if int(entry.kind) == kind:
			return true
	return false


## Round entry from the committed calculator result. `decision` is the lifecycle decision.
func commit_round(
	round_id: int,
	attempt_id: int,
	family: int,
	score_result: Dictionary,
	outcome_rows: Array,
	decision: Dictionary
) -> Dictionary:
	var entry := build_round_entry(round_id, attempt_id, family, score_result, outcome_rows, decision)
	if entry.is_empty():
		return {}
	return _commit(entry)


func commit_sudden_death_entry(
	round_id: int, attempt_id: int, sd_attempt: int, tied_seats: Array, totals: Dictionary,
	terminal_reason: int
) -> Dictionary:
	return _commit(
		{
			"kind": NetworkResultsCodec.Kind.SD_ENTRY,
			"round_id": round_id,
			"attempt_id": attempt_id,
			"tied_mask": NetworkResultsCodec.mask_of(tied_seats),
			"sd_attempt": sd_attempt,
			"terminal_reason": terminal_reason,
			"seats": _seat_totals(totals),
		}
	)


func commit_sudden_death_result(
	round_id: int, attempt_id: int, sd_attempt: int, winner_seat: int, last_cluck: bool
) -> Dictionary:
	return _commit(
		{
			"kind": NetworkResultsCodec.Kind.SD_RESULT,
			"round_id": round_id,
			"attempt_id": attempt_id,
			"winner_seat": winner_seat,
			"last_cluck": 1 if last_cluck else 0,
			"sd_attempt": sd_attempt,
		}
	)


func commit_final(
	round_id: int,
	attempt_id: int,
	winner_seat: int,
	last_cluck: bool,
	sudden_death: bool,
	terminal_reason: int,
	totals: Dictionary
) -> Dictionary:
	return _commit(
		{
			"kind": NetworkResultsCodec.Kind.FINAL,
			"round_id": round_id,
			"attempt_id": attempt_id,
			"winner_seat": winner_seat,
			"last_cluck": 1 if last_cluck else 0,
			"sudden_death": 1 if sudden_death else 0,
			"terminal_reason": terminal_reason,
			"seats": _seat_totals(totals),
		}
	)


## Builds (without committing) the ROUND entry. Empty when a calculator row has no wire code.
static func build_round_entry(
	round_id: int,
	attempt_id: int,
	family: int,
	score_result: Dictionary,
	outcome_rows: Array,
	decision: Dictionary
) -> Dictionary:
	if not bool(score_result.get("valid", false)):
		return {}
	var totals_units: Dictionary = score_result.get("totals_units", {})
	var delta_units: Dictionary = score_result.get("delta_units", {})
	var seat_indices: Array[int] = []
	for seat_variant in totals_units:
		seat_indices.append(int(seat_variant))
	seat_indices.sort()
	var outcome_by_seat: Dictionary = {}
	for row_variant in outcome_rows:
		var row: Dictionary = row_variant
		outcome_by_seat[int(row.get("seat_index", -1))] = row
	var placement_units: Dictionary = score_result.get("placement_units", {})
	var event_winner := int(score_result.get("winner_seat", -1))
	var barya_seat := -1
	var seats: Array[Dictionary] = []
	var finishers := 0
	for seat_index in seat_indices:
		var awards: Array[Dictionary] = []
		for row_variant in score_result.get("award_rows", []):
			var award_row: Dictionary = row_variant
			if int(award_row.get("seat_index", -1)) != seat_index:
				continue
			var code := NetworkResultsCodec.award_code(str(award_row.get("key", "")))
			if code < 0:
				push_error("ResultLedger: award key '%s' has no wire code." % award_row.get("key", ""))
				return {}
			if code == NetworkResultsCodec.AwardKey.BARYA and int(award_row.get("units", 0)) > 0:
				barya_seat = seat_index
			awards.append({"key": code, "units": int(award_row.get("units", 0))})
		var record: Dictionary = outcome_by_seat.get(seat_index, {})
		var outcome := NetworkResultsCodec.Outcome.NONE
		if not record.is_empty():
			outcome = (
				NetworkResultsCodec.Outcome.FINISHED
				if str(record.get("outcome", "")) == "finished"
				else NetworkResultsCodec.Outcome.ELIMINATED
			)
		if family != NetworkResultsCodec.ScoringFamily.RACE and seat_index == event_winner:
			# The event's survivor or Last Cluck winner "finished" even if the controller kept a row.
			outcome = NetworkResultsCodec.Outcome.FINISHED
		if outcome == NetworkResultsCodec.Outcome.FINISHED:
			finishers += 1
		var owner := int(record.get("direct_owner_seat", -1))
		if owner < 0 or owner >= NetworkResultsCodec.MAX_SEATS:
			owner = -1
		var placement := 0
		if family != NetworkResultsCodec.ScoringFamily.RACE and not placement_units.is_empty():
			placement = 1
			for other in seat_indices:
				if int(placement_units.get(other, 0)) > int(placement_units.get(seat_index, 0)):
					placement += 1
		seats.append(
			{
				"seat": seat_index,
				"outcome": outcome,
				"cause": NetworkResultsCodec.cause_code(str(record.get("cause", ""))) if not record.is_empty() else NetworkResultsCodec.Cause.NONE,
				"owner": owner,
				"placement": placement,
				"delta": int(delta_units.get(seat_index, 0)),
				"total": int(totals_units.get(seat_index, 0)),
				"awards": awards,
			}
		)
	var suppression := NetworkResultsCodec.Suppression.NONE
	if family == NetworkResultsCodec.ScoringFamily.RACE:
		var finisher_count := int(score_result.get("finisher_count", finishers))
		finishers = finisher_count
		if finisher_count == 0:
			suppression = NetworkResultsCodec.Suppression.NO_FINISHER
		elif finisher_count == seat_indices.size():
			suppression = NetworkResultsCodec.Suppression.ALL_FINISHED
	var decision_kind := int(decision.get("kind", 0))
	var wire_decision := NetworkResultsCodec.Decision.CONTINUE
	var winner_seat := -1
	var tied_mask := 0
	if decision_kind == MatchLifecycleCoordinator.Decision.WINNER:
		wire_decision = NetworkResultsCodec.Decision.WINNER
		winner_seat = int(decision.get("winner_seat", -1))
	elif decision_kind == MatchLifecycleCoordinator.Decision.SUDDEN_DEATH:
		wire_decision = NetworkResultsCodec.Decision.SUDDEN_DEATH
		tied_mask = NetworkResultsCodec.mask_of(decision.get("tied_seats", []))
	var terminal := NetworkResultsCodec.Terminal.NONE
	if wire_decision != NetworkResultsCodec.Decision.CONTINUE:
		terminal = terminal_code(str(decision.get("reason", "")))
	return {
		"kind": NetworkResultsCodec.Kind.ROUND,
		"round_id": round_id,
		"attempt_id": attempt_id,
		"family": family,
		"suppression": suppression,
		"finisher_count": finishers,
		"first_mask": NetworkResultsCodec.mask_of(score_result.get("first_finish_seats", [])),
		"last_cluck_seat": (
			int(score_result.get("last_cluck_seat", -1))
			if bool(score_result.get("last_cluck", false))
			else -1
		),
		"barya_seat": barya_seat,
		"decision": wire_decision,
		"winner_seat": winner_seat,
		"tied_mask": tied_mask,
		"terminal_reason": terminal,
		"seats": seats,
	}


static func terminal_code(reason: String) -> int:
	match reason:
		"score_target":
			return NetworkResultsCodec.Terminal.SCORE_TARGET
		"round_limit":
			return NetworkResultsCodec.Terminal.ROUND_LIMIT
	return NetworkResultsCodec.Terminal.NONE


func _commit(entry: Dictionary) -> Dictionary:
	if match_id <= 0 or _entries.size() >= NetworkResultsCodec.MAX_ENTRIES:
		return {}
	entry["match_id"] = match_id
	entry["event_id"] = _entries.size() + 1
	entry["revision"] = _entries.size() + 1
	var key := "%d:%d:%d:%d" % [match_id, int(entry.round_id), int(entry.attempt_id), int(entry.event_id)]
	if _keys.has(key):
		return {}
	if not NetworkResultsCodec.entry_is_valid(entry):
		push_error("ResultLedger refused an entry that fails the wire invariants (kind %d)." % int(entry.kind))
		return {}
	_keys[key] = true
	_entries.append(entry.duplicate(true))
	committed.emit(entry.duplicate(true))
	return entry.duplicate(true)


static func _seat_totals(totals: Dictionary) -> Array[Dictionary]:
	var seats: Array[Dictionary] = []
	var indices: Array[int] = []
	for seat_variant in totals:
		var index := int(seat_variant)
		if index >= 0 and index < NetworkResultsCodec.MAX_SEATS:
			indices.append(index)
	indices.sort()
	for index in indices:
		seats.append({"seat": index, "total": int(totals.get(index, 0))})
	return seats

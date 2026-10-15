class_name RaceOutcomeLedger
extends RefCounted

enum CandidateKind { GOAL, ELIMINATION }

var round_id := ""
var seat_indices: Array[int] = []
var starting_totals: Dictionary = {}
var outcomes_by_seat: Dictionary = {}
var seen_event_ids: Dictionary = {}
var closed_physics_ticks: Dictionary = {}
var score_commit: Dictionary = {}
var score_committed := false


func begin(new_round_id: String, seats: Array[int], score_snapshot: Dictionary) -> bool:
	if new_round_id.is_empty() or seats.size() < 2 or seats.size() > 4:
		return false
	var unique_seats: Dictionary = {}
	for seat_index in seats:
		if unique_seats.has(seat_index):
			return false
		unique_seats[seat_index] = true
	round_id = new_round_id
	seat_indices = seats.duplicate()
	seat_indices.sort()
	starting_totals = score_snapshot.duplicate(true)
	outcomes_by_seat.clear()
	seen_event_ids.clear()
	closed_physics_ticks.clear()
	score_commit.clear()
	score_committed = false
	return true


## Resolves the complete candidate batch for one simulation step. Elimination wins over
## a goal on that step; tied direct hazards use stable source IDs. A tied non-hazard
## elimination makes direct ownership ambiguous and earns no Patibong.
func resolve_step(physics_tick: int, candidates: Array[Dictionary]) -> Array[Dictionary]:
	var resolved: Array[Dictionary] = []
	if round_id.is_empty() or closed_physics_ticks.has(physics_tick):
		return resolved
	closed_physics_ticks[physics_tick] = true
	var canonical_by_id: Dictionary = {}
	for candidate in candidates:
		if not _valid_candidate(candidate, physics_tick):
			continue
		var event_id := str(candidate.get("event_id", ""))
		if seen_event_ids.has(event_id):
			continue
		var normalized := candidate.duplicate(true)
		if (
			not canonical_by_id.has(event_id)
			or _candidate_key(normalized) < _candidate_key(canonical_by_id[event_id])
		):
			canonical_by_id[event_id] = normalized
	var by_seat: Dictionary = {}
	var event_ids: Array = canonical_by_id.keys()
	event_ids.sort()
	for event_id in event_ids:
		var candidate: Dictionary = canonical_by_id[event_id]
		seen_event_ids[event_id] = true
		var seat_index := int(candidate.seat_index)
		if outcomes_by_seat.has(seat_index):
			continue
		if not by_seat.has(seat_index):
			by_seat[seat_index] = []
		by_seat[seat_index].append(candidate)
	var seat_batch: Array = by_seat.keys()
	seat_batch.sort()
	for seat_index in seat_batch:
		var batch: Array = by_seat[seat_index]
		var eliminations: Array[Dictionary] = []
		var goals: Array[Dictionary] = []
		for candidate in batch:
			if str(candidate.kind) == "elimination":
				eliminations.append(candidate)
			else:
				goals.append(candidate)
		var outcome: Dictionary
		if not eliminations.is_empty():
			eliminations.sort_custom(_hazard_less)
			var selected: Dictionary = eliminations[0]
			var owner := -1
			var cause_is_ambiguous := false
			for candidate in eliminations:
				if str(candidate.get("source_item_id", "")).is_empty():
					cause_is_ambiguous = true
			if not cause_is_ambiguous:
				owner = int(selected.get("direct_owner_seat", -1))
			if owner == int(seat_index):
				owner = -1
			var stated_cause := str(selected.get("cause", ""))
			outcome = {
				"seat_index": int(seat_index),
				"outcome": "eliminated",
				"physics_tick": physics_tick,
				"event_id": str(selected.event_id),
				"source_item_id": str(selected.get("source_item_id", "")),
				"direct_owner_seat": owner,
				"cause":
				(
					"direct_hazard"
					if owner >= 0
					else (stated_cause if not stated_cause.is_empty() else "elimination")
				),
			}
		elif not goals.is_empty():
			goals.sort_custom(
				func(a: Dictionary, b: Dictionary) -> bool: return str(a.event_id) < str(b.event_id)
			)
			outcome = {
				"seat_index": int(seat_index),
				"outcome": "finished",
				"physics_tick": physics_tick,
				"event_id": str(goals[0].event_id),
				"source_item_id": "",
				"direct_owner_seat": -1,
				"cause": "goal",
			}
		else:
			continue
		outcomes_by_seat[int(seat_index)] = outcome
		resolved.append(outcome.duplicate(true))
	return resolved


func fail_remaining(physics_tick: int, reason: String) -> Array[Dictionary]:
	var resolved: Array[Dictionary] = []
	var ordered := seat_indices.duplicate()
	ordered.sort()
	for seat_index in ordered:
		if outcomes_by_seat.has(seat_index):
			continue
		var outcome := {
			"seat_index": seat_index,
			"outcome": "eliminated",
			"physics_tick": physics_tick,
			"event_id": "%s:deadline:%d:%d" % [round_id, physics_tick, seat_index],
			"source_item_id": "",
			"direct_owner_seat": -1,
			"cause": reason,
		}
		outcomes_by_seat[seat_index] = outcome
		resolved.append(outcome.duplicate(true))
	return resolved


func all_terminal() -> bool:
	return not seat_indices.is_empty() and outcomes_by_seat.size() == seat_indices.size()


func outcomes() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for seat_index in seat_indices:
		if outcomes_by_seat.has(seat_index):
			result.append((outcomes_by_seat[seat_index] as Dictionary).duplicate(true))
	return result


func commit_score_once(round_key: String, result: Dictionary) -> bool:
	if score_committed or round_key != round_id or not bool(result.get("valid", false)):
		return false
	score_commit = result.duplicate(true)
	score_committed = true
	return true


func _valid_candidate(candidate: Dictionary, physics_tick: int) -> bool:
	var event_id := str(candidate.get("event_id", ""))
	var seat_index := int(candidate.get("seat_index", -1))
	var kind := str(candidate.get("kind", ""))
	return (
		not event_id.is_empty()
		and str(candidate.get("round_id", "")) == round_id
		and int(candidate.get("physics_tick", -1)) == physics_tick
		and seat_indices.has(seat_index)
		and kind in ["goal", "elimination"]
		and not outcomes_by_seat.has(seat_index)
		and not seen_event_ids.has(event_id)
	)


func _candidate_key(candidate: Dictionary) -> String:
	return (
		"%08d:%s:%s:%08d:%s:%08d"
		% [
			int(candidate.get("seat_index", -1)),
			str(candidate.get("kind", "")),
			str(candidate.get("source_item_id", "")),
			int(candidate.get("direct_owner_seat", -1)),
			str(candidate.get("event_id", "")),
			int(candidate.get("physics_tick", -1)),
		]
	)


func _hazard_less(a: Dictionary, b: Dictionary) -> bool:
	var a_id := str(a.get("source_item_id", ""))
	var b_id := str(b.get("source_item_id", ""))
	if a_id.is_empty() != b_id.is_empty():
		return not a_id.is_empty()
	if a_id != b_id:
		return a_id < b_id
	return str(a.event_id) < str(b.event_id)

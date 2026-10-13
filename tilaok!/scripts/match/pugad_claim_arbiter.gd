class_name PugadClaimArbiter
extends RefCounted


## Claims have {seat_index, egg_id, tick}. Earlier ticks resolve first. Claims in one tick
## contesting the same egg are shuffled with the match tie stream before ownership is assigned.
static func resolve(
	eggs: Array[Dictionary],
	claims: Array[Dictionary],
	seat_indices: Array[int],
	tie_stream: RandomNumberGenerator,
	prior_assignments: Dictionary = {}
) -> Dictionary:
	var assignments := prior_assignments.duplicate(true)
	var egg_by_id: Dictionary = {}
	var available: Dictionary = {}
	for egg in eggs:
		var egg_id := str(egg.egg_id)
		egg_by_id[egg_id] = egg
		var already_claimed := false
		for owner in assignments.values():
			if str(owner) == egg_id:
				already_claimed = true
				break
		if not already_claimed:
			available[egg_id] = true
	var sorted_claims := claims.duplicate(true)
	sorted_claims.sort_custom(
		func(left: Dictionary, right: Dictionary) -> bool:
			if int(left.get("tick", 0)) != int(right.get("tick", 0)):
				return int(left.get("tick", 0)) < int(right.get("tick", 0))
			if str(left.get("egg_id", "")) != str(right.get("egg_id", "")):
				return str(left.get("egg_id", "")) < str(right.get("egg_id", ""))
			return int(left.get("seat_index", -1)) < int(right.get("seat_index", -1))
	)
	var losers: Array[int] = []
	var cursor := 0
	while cursor < sorted_claims.size():
		var tick := int(sorted_claims[cursor].get("tick", 0))
		var tick_claims: Array[Dictionary] = []
		while cursor < sorted_claims.size() and int(sorted_claims[cursor].get("tick", 0)) == tick:
			tick_claims.append(sorted_claims[cursor])
			cursor += 1
		var by_egg: Dictionary = {}
		for claim in tick_claims:
			var seat_index := int(claim.get("seat_index", -1))
			var egg_id := str(claim.get("egg_id", ""))
			if seat_index not in seat_indices or assignments.has(seat_index):
				if seat_index in seat_indices:
					losers.append(seat_index)
				continue
			if not available.has(egg_id):
				losers.append(seat_index)
				continue
			if not by_egg.has(egg_id):
				by_egg[egg_id] = []
			if seat_index not in by_egg[egg_id]:
				by_egg[egg_id].append(seat_index)
		var egg_ids: Array = by_egg.keys()
		egg_ids.sort()
		for egg_id_variant in egg_ids:
			var egg_id := str(egg_id_variant)
			var contenders: Array = by_egg[egg_id]
			contenders.sort()
			var winner_position := tie_stream.randi_range(0, contenders.size() - 1)
			var winner := int(contenders[winner_position])
			assignments[winner] = egg_id
			available.erase(egg_id)
			for contender in contenders:
				if int(contender) != winner:
					losers.append(int(contender))
	var remaining: Array[Dictionary] = []
	for egg in eggs:
		if available.has(str(egg.egg_id)):
			remaining.append(egg)
	losers.sort()
	return {
		"assignments": assignments,
		"losers": losers,
		"remaining_eggs": remaining,
		"egg_by_id": egg_by_id
	}


static func assign_remaining(
	eggs: Array[Dictionary],
	seat_indices: Array[int],
	prior_assignments: Dictionary,
	egg_stream: RandomNumberGenerator
) -> Dictionary:
	var assignments := prior_assignments.duplicate(true)
	var remaining_eggs := eggs.duplicate(true)
	var open_seats := seat_indices.duplicate()
	open_seats.sort()
	for seat_index in open_seats:
		if assignments.has(seat_index) or remaining_eggs.is_empty():
			continue
		var index := egg_stream.randi_range(0, remaining_eggs.size() - 1)
		var egg: Dictionary = remaining_eggs.pop_at(index)
		assignments[seat_index] = str(egg.egg_id)
	return {"assignments": assignments, "remaining_eggs": remaining_eggs}

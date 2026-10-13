class_name PlacementScoreResolver
extends RefCounted


## Current approved integer-eighth tables, for elimination modes that use placement scoring.
static func table_for_players(player_count: int) -> PackedInt32Array:
	match player_count:
		2:
			return PackedInt32Array([8, 0])
		3:
			return PackedInt32Array([8, 4, 0])
		4:
			return PackedInt32Array([8, 4, 2, 0])
	return PackedInt32Array()


static func tied_group_units(player_count: int, first_place: int, group_size: int) -> int:
	var table := table_for_players(player_count)
	if table.is_empty() or first_place < 1 or group_size <= 0:
		return -1
	if first_place + group_size - 1 > table.size():
		return -1
	var sum := 0
	for offset in range(group_size):
		sum += table[first_place + offset - 1]
	if sum % group_size != 0:
		return -1
	return int(sum / group_size)


## Inputs are seat indices plus one elimination record per eliminated seat:
## {"seat_index": int, "physics_tick": int}. All-ejected rounds apply Last Cluck
## before allocating the lower tied placements.
static func resolve(
	seat_indices: Array[int],
	elimination_records: Array[Dictionary],
	survivor_seats: Array[int] = []
) -> Dictionary:
	var table := table_for_players(seat_indices.size())
	if table.is_empty():
		return {"valid": false, "reason": "Placement scoring supports two to four seats."}
	var seat_set: Dictionary = {}
	for seat_index in seat_indices:
		if seat_set.has(seat_index):
			return {"valid": false, "reason": "Seat indices must be unique."}
		seat_set[seat_index] = true
	var eliminations_by_seat: Dictionary = {}
	for record in elimination_records:
		var seat_index := int(record.get("seat_index", -1))
		if not seat_set.has(seat_index) or eliminations_by_seat.has(seat_index):
			return {"valid": false, "reason": "Each eliminated seat needs one known record."}
		eliminations_by_seat[seat_index] = {
			"seat_index": seat_index, "physics_tick": int(record.get("physics_tick", -1))
		}
	var survivors: Array[int] = []
	for seat_index in survivor_seats:
		if (
			not seat_set.has(seat_index)
			or eliminations_by_seat.has(seat_index)
			or survivors.has(seat_index)
		):
			return {"valid": false, "reason": "Survivors must be known, unique and not eliminated."}
		survivors.append(seat_index)
	if survivors.size() + eliminations_by_seat.size() != seat_indices.size():
		return {"valid": false, "reason": "Every seat must be a survivor or eliminated."}
	var scores: Dictionary = {}
	var place := 1
	var last_cluck_seat := -1
	if survivors.is_empty():
		if elimination_records.is_empty():
			return {
				"valid": false, "reason": "An all-eliminated round needs elimination timestamps."
			}
		var latest_tick := -0x7fffffffffffffff
		for record in elimination_records:
			latest_tick = maxi(latest_tick, int(record.get("physics_tick", -1)))
		var latest_seats: Array[int] = []
		for seat_index in eliminations_by_seat:
			if int(eliminations_by_seat[seat_index].physics_tick) == latest_tick:
				latest_seats.append(int(seat_index))
		latest_seats.sort()
		last_cluck_seat = latest_seats[0]
		scores[last_cluck_seat] = table[0]
		place = 2
	else:
		survivors.sort()
		var survivor_units := tied_group_units(table.size(), 1, survivors.size())
		if survivor_units < 0:
			return {
				"valid": false, "reason": "The tied survivor placement has no exact table value."
			}
		for seat_index in survivors:
			scores[seat_index] = survivor_units
		place = survivors.size() + 1
	var loser_groups: Dictionary = {}
	for seat_index in eliminations_by_seat:
		if int(seat_index) == last_cluck_seat:
			continue
		var tick := int(eliminations_by_seat[seat_index].physics_tick)
		if not loser_groups.has(tick):
			loser_groups[tick] = []
		loser_groups[tick].append(int(seat_index))
	var ticks: Array = loser_groups.keys()
	ticks.sort()
	ticks.reverse()
	for tick in ticks:
		var group: Array = loser_groups[tick]
		group.sort()
		var group_units := tied_group_units(table.size(), place, group.size())
		if group_units < 0:
			return {"valid": false, "reason": "An elimination tie has no exact table value."}
		for seat_index in group:
			scores[int(seat_index)] = group_units
		place += group.size()
	return {
		"valid": true,
		"score_units": scores,
		"last_cluck": last_cluck_seat >= 0,
		"last_cluck_seat": last_cluck_seat,
	}

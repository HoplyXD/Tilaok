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
## {"seat_index": int, "physics_tick": int, "physics_time": float,
## "time_comparable": bool}. Tick-only callers remain indistinguishable within a tick.
## All-ejected rounds apply Last Cluck before allocating the lower tied placements.
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
			"seat_index": seat_index,
			"physics_tick": int(record.get("physics_tick", -1)),
			"physics_time": float(record.get("physics_time", 0.0)),
			"time_comparable": bool(record.get("time_comparable", false)),
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
		var latest_rows: Array[Dictionary] = []
		for seat_index in eliminations_by_seat:
			var row: Dictionary = eliminations_by_seat[seat_index]
			if int(row.physics_tick) == latest_tick:
				latest_rows.append(row)
		var latest_seats: Array[int] = []
		var latest_time := -INF
		var comparable_latest := _all_times_comparable(latest_rows)
		if comparable_latest:
			for row in latest_rows:
				latest_time = maxf(latest_time, float(row.physics_time))
		for row in latest_rows:
			if not comparable_latest or float(row.physics_time) == latest_time:
				latest_seats.append(int(row.seat_index))
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
		loser_groups[tick].append(eliminations_by_seat[seat_index])
	var ticks: Array = loser_groups.keys()
	ticks.sort()
	ticks.reverse()
	for tick in ticks:
		var tick_rows: Array[Dictionary] = []
		for row_variant in loser_groups[tick]:
			tick_rows.append(row_variant)
		if not _all_times_comparable(tick_rows):
			var tick_seats: Array[int] = []
			for row in tick_rows:
				tick_seats.append(int(row.seat_index))
			tick_seats.sort()
			var tied_units := tied_group_units(table.size(), place, tick_seats.size())
			if tied_units < 0:
				return {"valid": false, "reason": "An elimination tie has no exact table value."}
			for seat_index in tick_seats:
				scores[seat_index] = tied_units
			place += tick_seats.size()
			continue
		tick_rows.sort_custom(_later_recorded_first)
		var row_index := 0
		while row_index < tick_rows.size():
			var time := float(tick_rows[row_index].physics_time)
			var tied_seats: Array[int] = []
			while row_index < tick_rows.size() and float(tick_rows[row_index].physics_time) == time:
				tied_seats.append(int(tick_rows[row_index].seat_index))
				row_index += 1
			tied_seats.sort()
			var tied_units := tied_group_units(table.size(), place, tied_seats.size())
			if tied_units < 0:
				return {"valid": false, "reason": "An elimination tie has no exact table value."}
			for seat_index in tied_seats:
				scores[seat_index] = tied_units
			place += tied_seats.size()
	return {
		"valid": true,
		"score_units": scores,
		"last_cluck": last_cluck_seat >= 0,
		"last_cluck_seat": last_cluck_seat,
	}


static func _all_times_comparable(rows: Array[Dictionary]) -> bool:
	if rows.is_empty():
		return false
	for row in rows:
		if not bool(row.get("time_comparable", false)):
			return false
	return true


static func _later_recorded_first(left: Dictionary, right: Dictionary) -> bool:
	if float(left.physics_time) != float(right.physics_time):
		return float(left.physics_time) > float(right.physics_time)
	return int(left.seat_index) < int(right.seat_index)

class_name RaceScoreCalculator
extends RefCounted

const TAPOS_UNITS := 8
const UNA_UNITS := 2
const BAYANI_UNITS := 4
const PATIBONG_UNITS := 2
const BAWI_UNITS := 6
const BARYA_UNITS := 4
const BAWI_GAP_UNITS := 24


## Pure race scoring. Each outcome has seat_index, outcome ("finished" / "eliminated"),
## physics_tick and optional direct_owner_seat. Coin seats are test facts until Barya integration.
static func calculate(
	seat_indices: Array[int],
	outcomes: Array[Dictionary],
	starting_totals: Dictionary,
	coin_seats: Array[int] = []
) -> Dictionary:
	if seat_indices.size() < 2 or seat_indices.size() > 4:
		return {"valid": false, "reason": "Race scoring supports two to four seats."}
	var unique_seats: Dictionary = {}
	for seat_index in seat_indices:
		if unique_seats.has(seat_index):
			return {"valid": false, "reason": "Seat indices must be unique."}
		unique_seats[seat_index] = true
	var outcome_by_seat: Dictionary = {}
	var finishers: Array[int] = []
	var eliminations: Array[Dictionary] = []
	for outcome in outcomes:
		var seat_index := int(outcome.get("seat_index", -1))
		if not seat_indices.has(seat_index) or outcome_by_seat.has(seat_index):
			return {"valid": false, "reason": "Each joined seat needs one terminal outcome."}
		outcome_by_seat[seat_index] = outcome
		if str(outcome.get("outcome", "")) == "finished":
			finishers.append(seat_index)
		elif str(outcome.get("outcome", "")) == "eliminated":
			eliminations.append(outcome)
		else:
			return {"valid": false, "reason": "Unknown terminal outcome."}
	if outcome_by_seat.size() != seat_indices.size():
		return {"valid": false, "reason": "Score only a fully resolved round."}
	var delta_units: Dictionary = {}
	var totals_units: Dictionary = {}
	var leader_units := 0
	var has_leader := false
	for seat_index in seat_indices:
		var start_units := int(starting_totals.get(seat_index, 0))
		totals_units[seat_index] = start_units
		delta_units[seat_index] = 0
		if not has_leader or start_units > leader_units:
			leader_units = start_units
			has_leader = true
	var no_finisher := finishers.is_empty()
	var all_finishers := finishers.size() == seat_indices.size()
	var suppress := false
	var suppression_reason := ""
	if no_finisher:
		suppress = true
		suppression_reason = "No one reached the goal; no round points are awarded."
	elif all_finishers:
		suppress = true
		suppression_reason = "Everyone reached the goal; no round points are awarded."
	else:
		suppression_reason = "Some players finished; normal race awards apply."
	var award_rows: Array[Dictionary] = []
	if not no_finisher:
		var earliest_tick := 0x7fffffffffffffff
		for seat_index in finishers:
			var tick := int(outcome_by_seat[seat_index].get("physics_tick", 0))
			earliest_tick = mini(earliest_tick, tick)
		var first_finishers: Array[int] = []
		for seat_index in finishers:
			if int(outcome_by_seat[seat_index].get("physics_tick", 0)) == earliest_tick:
				first_finishers.append(seat_index)
		first_finishers.sort()
		for seat_index in finishers:
			if not suppress:
				_add_award(
					award_rows,
					delta_units,
					seat_index,
					"tapos",
					"Tapos",
					TAPOS_UNITS,
					"Reached the flag."
				)
				if first_finishers.has(seat_index) and not suppress:
					_add_award(
						award_rows,
						delta_units,
						seat_index,
						"una",
						"Una",
						UNA_UNITS,
						"Earliest finish; exact physics-step ties share Una."
					)
				if finishers.size() == 1 and not suppress:
					_add_award(
						award_rows,
						delta_units,
						seat_index,
						"bayani",
						"Bayani",
						BAYANI_UNITS,
						"Sole finisher."
					)
				if (
					has_leader
					and leader_units - int(starting_totals.get(seat_index, 0)) >= BAWI_GAP_UNITS
					and not suppress
				):
					_add_award(
						award_rows,
						delta_units,
						seat_index,
						"bawi",
						"Bawi",
						BAWI_UNITS,
						"Started at least 3 points behind the round-start leader and finished."
					)
			if coin_seats.has(seat_index) and not suppress:
				_add_award(
					award_rows,
					delta_units,
					seat_index,
					"barya",
					"Barya",
					BARYA_UNITS,
					"Carried a coin to the flag."
				)
	if not no_finisher and not suppress:
		for outcome in eliminations:
			var victim := int(outcome.get("seat_index", -1))
			var owner := int(outcome.get("direct_owner_seat", -1))
			if owner >= 0 and owner != victim and seat_indices.has(owner):
				_add_award(
					award_rows,
					delta_units,
					owner,
					"patibong",
					"Patibong",
					PATIBONG_UNITS,
					"Directly eliminated P%d." % (victim + 1)
				)
	for seat_index in seat_indices:
		totals_units[seat_index] = int(totals_units[seat_index]) + int(delta_units[seat_index])
	return {
		"valid": true,
		"delta_units": delta_units,
		"totals_units": totals_units,
		"award_rows": award_rows,
		"suppression_reason": suppression_reason,
		"finisher_count": finishers.size(),
		"first_finish_seats": _first_finish_seats(finishers, outcome_by_seat),
	}


static func _first_finish_seats(finishers: Array[int], outcome_by_seat: Dictionary) -> Array[int]:
	var result: Array[int] = []
	if finishers.is_empty():
		return result
	var earliest_tick := 0x7fffffffffffffff
	for seat_index in finishers:
		earliest_tick = mini(earliest_tick, int(outcome_by_seat[seat_index].get("physics_tick", 0)))
	for seat_index in finishers:
		if int(outcome_by_seat[seat_index].get("physics_tick", 0)) == earliest_tick:
			result.append(seat_index)
	result.sort()
	return result


static func _add_award(
	rows: Array[Dictionary],
	deltas: Dictionary,
	seat_index: int,
	key: String,
	title: String,
	units: int,
	explanation: String
) -> void:
	rows.append(
		{
			"seat_index": seat_index,
			"key": key,
			"title": title,
			"units": units,
			"explanation": explanation
		}
	)
	deltas[seat_index] = int(deltas[seat_index]) + units

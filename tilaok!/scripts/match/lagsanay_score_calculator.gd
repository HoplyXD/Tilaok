class_name LagsanayScoreCalculator
extends RefCounted

const PATIBONG_UNITS := 2
const BAWI_UNITS := 6
const BAWI_GAP_UNITS := 24


static func calculate(
	seat_indices: Array[int],
	elimination_records: Array[Dictionary],
	survivor_seats: Array[int],
	outcomes: Array[Dictionary],
	starting_totals: Dictionary
) -> Dictionary:
	var placements := PlacementScoreResolver.resolve(
		seat_indices, elimination_records, survivor_seats
	)
	if not bool(placements.get("valid", false)):
		return placements
	var delta_units: Dictionary = placements.score_units.duplicate(true)
	var award_rows: Array[Dictionary] = []
	for seat in seat_indices:
		(
			award_rows
			. append(
				{
					"seat_index": seat,
					"key": "placement",
					"title": "Placement",
					"units": int(delta_units[seat]),
					"explanation":
					"Lagsanay elimination placement; equal-time lower places share their table value.",
				}
			)
		)
	var kills_by_owner: Dictionary = {}
	for outcome in outcomes:
		if str(outcome.get("cause", "")) != "direct_hazard":
			continue
		var victim := int(outcome.get("seat_index", -1))
		var owner := int(outcome.get("direct_owner_seat", -1))
		if owner < 0 or owner == victim or not seat_indices.has(owner):
			continue
		kills_by_owner[owner] = int(kills_by_owner.get(owner, 0)) + 1
	for owner in kills_by_owner:
		var count := int(kills_by_owner[owner])
		var units := count * PATIBONG_UNITS
		delta_units[owner] = int(delta_units[owner]) + units
		(
			award_rows
			. append(
				{
					"seat_index": int(owner),
					"key": "patibong",
					"title": "Patibong",
					"units": units,
					"explanation":
					(
						"Directly eliminated %d opponent(s); self-kills and setup effects earn no credit."
						% count
					),
				}
			)
		)
	var winner := int(placements.get("last_cluck_seat", -1))
	if winner < 0 and survivor_seats.size() == 1:
		winner = int(survivor_seats[0])
	var leader := -0x7fffffff
	for seat in seat_indices:
		leader = maxi(leader, int(starting_totals.get(seat, 0)))
	if winner >= 0 and leader - int(starting_totals.get(winner, 0)) >= BAWI_GAP_UNITS:
		delta_units[winner] = int(delta_units[winner]) + BAWI_UNITS
		(
			award_rows
			. append(
				{
					"seat_index": winner,
					"key": "bawi",
					"title": "Bawi",
					"units": BAWI_UNITS,
					"explanation":
					"Winner started at least 3 points behind the round-start leader.",
				}
			)
		)
	var totals_units: Dictionary = {}
	for seat in seat_indices:
		totals_units[seat] = int(starting_totals.get(seat, 0)) + int(delta_units[seat])
	return {
		"valid": true,
		"delta_units": delta_units,
		"totals_units": totals_units,
		"placement_units": placements.score_units.duplicate(true),
		"award_rows": award_rows,
		"winner_seat": winner,
		"last_cluck": bool(placements.get("last_cluck", false)),
		"last_cluck_seat": int(placements.get("last_cluck_seat", -1)),
		"suppression_reason":
		"Placement, direct Patibong and eligible Bawi only; Karera awards are not active.",
	}

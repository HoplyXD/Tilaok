class_name P06Fixtures
extends RefCounted


## Test-only facts for race candidates, optional Barya and elimination-placement tables.
static func goal(
	round_id: String, seat_index: int, physics_tick: int, event_id: String = ""
) -> Dictionary:
	return {
		"event_id":
		(
			event_id
			if not event_id.is_empty()
			else "%s:goal:%d:%d" % [round_id, physics_tick, seat_index]
		),
		"round_id": round_id,
		"seat_index": seat_index,
		"kind": "goal",
		"physics_tick": physics_tick,
		"source_item_id": "",
		"direct_owner_seat": -1,
	}


static func elimination(
	round_id: String,
	seat_index: int,
	physics_tick: int,
	source_item_id: String = "",
	direct_owner_seat: int = -1,
	event_id: String = ""
) -> Dictionary:
	var source := source_item_id if not source_item_id.is_empty() else "none"
	return {
		"event_id":
		(
			event_id
			if not event_id.is_empty()
			else "%s:elimination:%d:%d:%s" % [round_id, physics_tick, seat_index, source]
		),
		"round_id": round_id,
		"seat_index": seat_index,
		"kind": "elimination",
		"physics_tick": physics_tick,
		"source_item_id": source_item_id,
		"direct_owner_seat": direct_owner_seat,
	}


static func terminal(
	seat_index: int, result: String, physics_tick: int, owner: int = -1
) -> Dictionary:
	return {
		"seat_index": seat_index,
		"outcome": result,
		"physics_tick": physics_tick,
		"direct_owner_seat": owner,
	}

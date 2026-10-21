class_name LagsanayRoundController
extends RefCounted

## Independent pass-through tag round. All decisions use a frozen physics-step batch and a
## round-relative active-simulation clock; this controller has no Karera ledger dependency.

const EVENT_TIME_EPSILON := 0.000001

var round_id := ""
var seat_indices: Array[int] = []
var starting_totals: Dictionary = {}
var outcomes_by_seat: Dictionary = {}
var seen_event_ids: Dictionary = {}
var pending_hazards: Array[AttributionRecord] = []
## NLB-P08: seats whose network grace expired, folded into the next step as the lowest-ranked cause.
var pending_disconnects: Array[Dictionary] = []
var rng: RandomNumberGenerator
var authority := SimulationAuthority.offline()
var taya_seat := -1
var opening_taya_seat := -1
var head_start_remaining := 0.0
var countdown_seconds := 0.0
var countdown_remaining := 0.0
var pass_back_seconds := 1.0
var simulation_clock := 0.0
var timeout_seconds_by_alive: Dictionary = {}
var pass_back_immunity_until: Dictionary = {}
var active := false
var ended := false
var end_reason := ""
var winner_seat := -1
var score_committed := false
var score_commit: Dictionary = {}


func begin(
	new_round_id: String,
	seats: Array[int],
	score_snapshot: Dictionary,
	gameplay_rng: RandomNumberGenerator,
	head_start_seconds: float,
	pass_back_immunity_seconds: float,
	timeout_2p: float,
	timeout_3p: float,
	timeout_4p: float
) -> bool:
	if not _can_mutate():
		return false
	if (
		new_round_id.is_empty()
		or seats.size() < 2
		or seats.size() > 4
		or gameplay_rng == null
		or head_start_seconds <= 0.0
		or pass_back_immunity_seconds < 0.0
		or timeout_2p <= 0.0
		or timeout_3p <= 0.0
		or timeout_4p <= 0.0
	):
		return false
	var unique: Dictionary = {}
	for seat in seats:
		if unique.has(seat):
			return false
		unique[seat] = true
	seat_indices = seats.duplicate()
	seat_indices.sort()
	round_id = new_round_id
	starting_totals = score_snapshot.duplicate(true)
	rng = gameplay_rng
	head_start_remaining = head_start_seconds
	pass_back_seconds = pass_back_immunity_seconds
	timeout_seconds_by_alive = {2: timeout_2p, 3: timeout_3p, 4: timeout_4p}
	var opening_index := rng.randi_range(0, seat_indices.size() - 1)
	taya_seat = seat_indices[opening_index]
	opening_taya_seat = taya_seat
	countdown_seconds = _timer_for_alive(seat_indices.size())
	countdown_remaining = countdown_seconds
	simulation_clock = 0.0
	outcomes_by_seat.clear()
	seen_event_ids.clear()
	pending_hazards.clear()
	pending_disconnects.clear()
	pass_back_immunity_until.clear()
	active = true
	ended = false
	end_reason = ""
	winner_seat = -1
	score_committed = false
	score_commit.clear()
	return true


func reset() -> void:
	if not _can_mutate():
		return
	active = false
	ended = false
	round_id = ""
	seat_indices.clear()
	starting_totals.clear()
	outcomes_by_seat.clear()
	seen_event_ids.clear()
	pending_hazards.clear()
	pending_disconnects.clear()
	pass_back_immunity_until.clear()
	taya_seat = -1
	opening_taya_seat = -1
	head_start_remaining = 0.0
	countdown_remaining = 0.0
	countdown_seconds = 0.0
	simulation_clock = 0.0
	winner_seat = -1
	score_committed = false
	score_commit.clear()
	end_reason = ""


func pass_back_remaining_seconds(seat: int) -> float:
	return maxf(0.0, float(pass_back_immunity_until.get(seat, simulation_clock)) - simulation_clock)


## Host only. One disconnect elimination per seat; it is processed with the next step's batch and
## never outranks a hazard or timeout recorded for the same seat on that step.
func submit_disconnect(seat: int, physics_tick: int) -> bool:
	if not _can_mutate() or not active or ended or not seat_indices.has(seat):
		return false
	if outcomes_by_seat.has(seat):
		return false
	for pending in pending_disconnects:
		if int(pending.seat) == seat:
			return true
	pending_disconnects.append({"seat": seat, "tick": physics_tick})
	return true


func submit_hazard(record: AttributionRecord) -> bool:
	if not _can_mutate():
		return false
	if (
		not active
		or ended
		or record == null
		or record.round_id != round_id
		or record.kind != AttributionRecord.Kind.ELIMINATION
		or not seat_indices.has(record.player_seat)
		or record.physics_tick < 0
		or record.event_id.is_empty()
		or seen_event_ids.has(record.event_id)
	):
		return false
	seen_event_ids[record.event_id] = true
	pending_hazards.append(record)
	return true


## `tag_contacts` is captured once before this call: [{seat_index, distance_squared}].
## Hazard and timeout records are batched first; contacts only transfer if the current taya
## survives, no winner is decided, and the countdown remains positive.
func advance_step(
	delta: float, physics_tick: int, tag_contacts: Array[Dictionary], _actors: Dictionary
) -> Dictionary:
	if not _can_mutate():
		return {"new_outcomes": [], "ended": false}
	var result := {
		"active": active,
		"ended": ended,
		"new_outcomes": [],
		"head_start_ended": false,
		"taya_changed": false,
		"tagged": false,
		"last_cluck": false,
		"winner_seat": winner_seat,
		"end_reason": end_reason,
	}
	if not active or ended or delta <= 0.0:
		return result
	var tick_start := simulation_clock
	var tick_end := tick_start + delta
	simulation_clock = tick_end
	var was_opening := head_start_remaining > 0.0
	var opening_step_seconds := minf(delta, head_start_remaining)
	head_start_remaining = maxf(0.0, head_start_remaining - delta)
	var head_start_ended := was_opening and head_start_remaining <= 0.0
	result.head_start_ended = head_start_ended
	var active_timer_step := maxf(0.0, delta - opening_step_seconds)
	var countdown_before := countdown_remaining
	var expiry_time := -1.0
	if active_timer_step > 0.0:
		countdown_remaining = maxf(0.0, countdown_remaining - active_timer_step)
		if countdown_before <= active_timer_step:
			expiry_time = tick_start + opening_step_seconds + countdown_before
	var hazard_by_seat: Dictionary = {}
	var hazards_this_step: Array[AttributionRecord] = []
	for record in pending_hazards:
		if record.physics_tick != physics_tick or record.round_id != round_id:
			continue
		if record.physics_time < tick_start - 0.000001 or record.physics_time > tick_end + 0.000001:
			continue
		hazards_this_step.append(record)
	pending_hazards.clear()
	hazards_this_step.sort_custom(_hazard_less)
	for record in hazards_this_step:
		if not hazard_by_seat.has(record.player_seat):
			hazard_by_seat[record.player_seat] = record
	var terminal_candidates: Array[Dictionary] = []
	for seat in hazard_by_seat:
		var record := hazard_by_seat[seat] as AttributionRecord
		terminal_candidates.append(_hazard_outcome(record, physics_tick))
	if expiry_time >= 0.0 and taya_seat >= 0 and not outcomes_by_seat.has(taya_seat):
		var chosen: Dictionary
		var hazard := hazard_by_seat.get(taya_seat) as AttributionRecord
		if (
			hazard != null
			and hazard.time_comparable
			and hazard.physics_time < expiry_time - EVENT_TIME_EPSILON
		):
			chosen = _hazard_outcome(hazard, physics_tick)
		else:
			chosen = _timeout_outcome(taya_seat, physics_tick, expiry_time)
		terminal_candidates.erase(_outcome_for_seat(terminal_candidates, taya_seat))
		terminal_candidates.append(chosen)
	for pending in pending_disconnects:
		var gone := int(pending.seat)
		if (
			outcomes_by_seat.has(gone)
			or not _outcome_for_seat(terminal_candidates, gone).is_empty()
		):
			continue
		terminal_candidates.append(_disconnect_outcome(gone, physics_tick, tick_end))
	pending_disconnects.clear()
	for outcome in terminal_candidates:
		var seat := int(outcome.seat_index)
		if outcomes_by_seat.has(seat) or not seat_indices.has(seat):
			continue
		outcomes_by_seat[seat] = outcome.duplicate(true)
		result.new_outcomes.append(outcome.duplicate(true))
	var old_taya := taya_seat
	var live := _live_seats()
	if live.is_empty():
		ended = true
		active = false
		end_reason = "last_cluck"
		result.last_cluck = true
	elif live.size() == 1:
		winner_seat = live[0]
		ended = true
		active = false
		end_reason = "last_survivor"
	elif not live.has(taya_seat):
		taya_seat = live[rng.randi_range(0, live.size() - 1)]
		countdown_seconds = _timer_for_alive(live.size())
		countdown_remaining = countdown_seconds
		result.taya_changed = true
	else:
		# An expiry tick has priority over contact because contact reports no sub-tick time.
		if (
			not was_opening
			and expiry_time < 0.0
			and countdown_remaining > 0.0
			and not tag_contacts.is_empty()
		):
			var receiver := _nearest_eligible(tag_contacts, live, tick_end)
			if receiver >= 0:
				pass_back_immunity_until[old_taya] = tick_end + pass_back_seconds
				taya_seat = receiver
				result.tagged = true
				result.taya_changed = true
	result.active = active
	result.ended = ended
	result.winner_seat = winner_seat
	result.end_reason = end_reason
	return result


func outcomes() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for seat in seat_indices:
		if outcomes_by_seat.has(seat):
			result.append((outcomes_by_seat[seat] as Dictionary).duplicate(true))
	return result


func elimination_records() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for outcome in outcomes():
		(
			result
			. append(
				{
					"seat_index": int(outcome.seat_index),
					"physics_tick": int(outcome.physics_tick),
					"physics_time": float(outcome.physics_time),
					"time_comparable": bool(outcome.time_comparable),
				}
			)
		)
	return result


func score_result() -> Dictionary:
	if not ended:
		return {"valid": false, "reason": "Lagsanay scoring requires an ended round."}
	return LagsanayScoreCalculator.calculate(
		seat_indices, elimination_records(), _live_seats(), outcomes(), starting_totals
	)


## Authoritative winner path for sudden death; ordinary placement awards are not applied.
func sudden_death_winner() -> Dictionary:
	if not ended:
		return {"valid": false, "winner_seat": -1, "last_cluck": false}
	if winner_seat >= 0 and seat_indices.has(winner_seat):
		return {"valid": true, "winner_seat": winner_seat, "last_cluck": false}
	if end_reason != "last_cluck":
		return {"valid": false, "winner_seat": -1, "last_cluck": false}
	var placement := score_result()
	var cluck_winner := int(placement.get("last_cluck_seat", -1))
	return {
		"valid": bool(placement.get("valid", false)) and seat_indices.has(cluck_winner),
		"winner_seat": cluck_winner,
		"last_cluck": true,
		"explanation":
		(
			"Every tied contestant was eliminated. The latest recorded elimination wins; "
			+ "an exact time tie goes to the lowest original seat."
		),
	}


func commit_score_once(result: Dictionary) -> bool:
	if not _can_mutate() or score_committed or not ended or not bool(result.get("valid", false)):
		return false
	score_commit = result.duplicate(true)
	score_committed = true
	return true


func _nearest_eligible(tag_contacts: Array[Dictionary], live: Array[int], at_time: float) -> int:
	var best_seat := -1
	var best_distance := INF
	for contact in tag_contacts:
		var seat := int(contact.get("seat_index", -1))
		if (
			seat == taya_seat
			or not live.has(seat)
			or seat == opening_taya_seat and head_start_remaining > 0.0
			or float(pass_back_immunity_until.get(seat, -1.0)) > at_time
		):
			continue
		var distance := float(contact.get("distance_squared", INF))
		if distance < best_distance or (distance == best_distance and seat < best_seat):
			best_distance = distance
			best_seat = seat
	return best_seat


func _live_seats() -> Array[int]:
	var result: Array[int] = []
	for seat in seat_indices:
		if not outcomes_by_seat.has(seat):
			result.append(seat)
	return result


func _timer_for_alive(alive_count: int) -> float:
	return float(timeout_seconds_by_alive.get(alive_count, 0.0))


func _hazard_outcome(record: AttributionRecord, tick: int) -> Dictionary:
	var owner := record.owner_seat if record.credit_eligible() else -1
	if owner == record.player_seat or not seat_indices.has(owner):
		owner = -1
	return {
		"seat_index": record.player_seat,
		"outcome": "eliminated",
		"physics_tick": tick,
		"physics_time": record.physics_time,
		"time_comparable": record.time_comparable,
		"event_id": record.event_id,
		"source_item_id": record.source_item_id,
		"direct_owner_seat": owner,
		"cause": "direct_hazard" if owner >= 0 else "hazard",
	}


func _timeout_outcome(seat: int, tick: int, event_time: float) -> Dictionary:
	return {
		"seat_index": seat,
		"outcome": "eliminated",
		"physics_tick": tick,
		"physics_time": event_time,
		"time_comparable": true,
		"event_id": "%s:timeout:%d:%d" % [round_id, tick, seat],
		"source_item_id": "",
		"direct_owner_seat": -1,
		"cause": "timeout",
	}


func _disconnect_outcome(seat: int, tick: int, event_time: float) -> Dictionary:
	return {
		"seat_index": seat,
		"outcome": "eliminated",
		"physics_tick": tick,
		"physics_time": event_time,
		"time_comparable": true,
		"event_id": "%s:disconnect:%d:%d" % [round_id, tick, seat],
		"source_item_id": "",
		"direct_owner_seat": -1,
		"cause": "disconnect",
	}


func _outcome_for_seat(rows: Array[Dictionary], seat: int) -> Dictionary:
	for row in rows:
		if int(row.get("seat_index", -1)) == seat:
			return row
	return {}


func _can_mutate() -> bool:
	return authority != null and authority.can_commit()


func _hazard_less(left: AttributionRecord, right: AttributionRecord) -> bool:
	if left.physics_time != right.physics_time:
		return left.physics_time < right.physics_time
	if left.source_item_id != right.source_item_id:
		return left.source_item_id < right.source_item_id
	return left.player_seat < right.player_seat

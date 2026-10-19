class_name BaryaRoundObjective
extends RefCounted

enum State { REMOVED, OFFERED, ASSIGNED, PLACED, AVAILABLE, CARRIED, SECURED, DISCARDED }

var match_id := -1
var authority := SimulationAuthority.offline()
var round_number := 0
var attempt_id := 0
var state := State.REMOVED
var offer_egg_id := ""
var assigned_seat := -1
## Original Place cell, retained for an aborted Play attempt.
var placement_cell := Vector2i.ZERO
## Current world cell, which may move when a committed elimination drops the coin.
var current_cell := Vector2i.ZERO
var carrier_seat := -1
var receipt_seat := -1
var pickup_blocked_tick := -1
var coin: BaryaCoin


func identity() -> String:
	return "%d:%d:%d" % [match_id, round_number, attempt_id]


func begin_offer(new_match_id: int, new_round_number: int, egg_id: String) -> bool:
	if not _can_mutate():
		return false
	remove_world_coin()
	match_id = new_match_id
	round_number = new_round_number
	attempt_id = 0
	offer_egg_id = egg_id
	assigned_seat = -1
	placement_cell = Vector2i.ZERO
	current_cell = Vector2i.ZERO
	carrier_seat = -1
	receipt_seat = -1
	pickup_blocked_tick = -1
	state = State.OFFERED if not egg_id.is_empty() else State.REMOVED
	return state == State.OFFERED


func assign(seat_index: int) -> bool:
	if not _can_mutate() or state != State.OFFERED or seat_index < 0:
		return false
	assigned_seat = seat_index
	state = State.ASSIGNED
	return true


func place(cell: Vector2i) -> bool:
	if not _can_mutate() or state != State.ASSIGNED:
		return false
	placement_cell = cell
	current_cell = cell
	state = State.PLACED
	return true


func activate(coin_node: BaryaCoin) -> bool:
	if (
		not _can_mutate()
		or state != State.PLACED
		or coin_node == null
		or not is_instance_valid(coin_node)
		or coin_node.identity != identity()
	):
		return false
	coin = coin_node
	state = State.AVAILABLE
	return true


## Returns the winning seat or -1. Candidate input is a physics-step snapshot; callback order is
## absent from this API. Exact-distance ties go to the lower stable seat index.
func resolve_pickup(candidates: Array[Dictionary], physics_tick: int) -> int:
	if not _can_mutate() or state != State.AVAILABLE or physics_tick <= pickup_blocked_tick:
		return -1
	var eligible: Array[Dictionary] = []
	for candidate in candidates:
		if not bool(candidate.get("eligible", false)):
			continue
		var seat := int(candidate.get("seat_index", -1))
		if seat < 0:
			continue
		eligible.append(candidate)
	eligible.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			var a_distance := float(a.get("distance_squared", INF))
			var b_distance := float(b.get("distance_squared", INF))
			if a_distance != b_distance:
				return a_distance < b_distance
			return int(a.seat_index) < int(b.seat_index)
	)
	if eligible.is_empty():
		return -1
	carrier_seat = int(eligible[0].seat_index)
	state = State.CARRIED
	return carrier_seat


func commit_terminal(seat_index: int, outcome: String, physics_tick: int) -> String:
	if not _can_mutate():
		return ""
	if state != State.CARRIED or carrier_seat != seat_index:
		return ""
	if outcome == "finished":
		receipt_seat = seat_index
		carrier_seat = -1
		state = State.SECURED
		return "secured"
	if outcome == "eliminated":
		carrier_seat = -1
		pickup_blocked_tick = physics_tick
		state = State.PLACED
		return "drop"
	return ""


func finish_drop(cell: Vector2i) -> void:
	if not _can_mutate() or state != State.PLACED:
		return
	current_cell = cell
	state = State.AVAILABLE


func discard() -> void:
	if not _can_mutate():
		return
	remove_world_coin()
	carrier_seat = -1
	receipt_seat = -1
	state = State.DISCARDED


## Retry keeps the same placed cell and offer; only attempt identity and temporary ownership are
## reset. Call activate() again after respawning at placement_cell.
func retry_attempt() -> bool:
	if not _can_mutate() or state not in [State.PLACED, State.AVAILABLE, State.CARRIED]:
		return false
	remove_world_coin()
	attempt_id += 1
	carrier_seat = -1
	receipt_seat = -1
	pickup_blocked_tick = -1
	current_cell = placement_cell
	state = State.PLACED
	return true


func scoring_seats() -> Array[int]:
	var seats: Array[int] = []
	if state == State.SECURED and receipt_seat >= 0:
		seats.append(receipt_seat)
	return seats


func remove_world_coin() -> void:
	if not _can_mutate():
		return
	if coin != null and is_instance_valid(coin):
		coin.queue_free()
	coin = null


func cleanup() -> void:
	if not _can_mutate():
		return
	remove_world_coin()
	carrier_seat = -1
	receipt_seat = -1
	assigned_seat = -1
	offer_egg_id = ""
	state = State.REMOVED


func _can_mutate() -> bool:
	return authority != null and authority.can_commit()

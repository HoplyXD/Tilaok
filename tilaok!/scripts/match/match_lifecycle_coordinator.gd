class_name MatchLifecycleCoordinator
extends RefCounted

## Match-level decisions are deliberately separate from ItemManager's completed-round counter.

enum Decision { INVALID, CONTINUE, WINNER, SUDDEN_DEATH }

var match_id := -1
var completed_round := 0
var tied_seats: Array[int] = []
var winner_seat := -1
var terminal_reason := ""
var sudden_death_attempt := 0
var sudden_death_resolved := false


func begin(new_match_id: int) -> bool:
	if new_match_id <= 0:
		return false
	match_id = new_match_id
	completed_round = 0
	tied_seats.clear()
	winner_seat = -1
	terminal_reason = ""
	sudden_death_attempt = 0
	sudden_death_resolved = false
	return true


## `active_round` is one-based. Score values are integer eighth-point units.
func finish_round(
	active_round: int, totals_units: Dictionary, target_units: int, round_limit: int
) -> Dictionary:
	if (
		match_id <= 0
		or terminal_reason != ""
		or active_round != completed_round + 1
		or target_units <= 0
		or round_limit <= 0
		or totals_units.size() < 2
	):
		return _decision(Decision.INVALID)
	var leaders: Array[int] = []
	var highest := -1
	for seat_variant in totals_units:
		var seat := int(seat_variant)
		var units := int(totals_units[seat_variant])
		if seat < 0 or units < 0 or float(units) != float(totals_units[seat_variant]):
			return _decision(Decision.INVALID)
		if units > highest:
			highest = units
			leaders = [seat]
		elif units == highest:
			leaders.append(seat)
	completed_round = active_round
	if highest < target_units and active_round < round_limit:
		return _decision(Decision.CONTINUE)
	terminal_reason = "score_target" if highest >= target_units else "round_limit"
	if leaders.size() == 1:
		winner_seat = leaders[0]
		return _decision(Decision.WINNER)
	leaders.sort()
	tied_seats = leaders
	sudden_death_attempt = 1
	return _decision(Decision.SUDDEN_DEATH)


func retry_sudden_death() -> int:
	if tied_seats.size() < 2 or sudden_death_resolved:
		return -1
	sudden_death_attempt += 1
	return sudden_death_attempt


func resolve_sudden_death(
	callback_match_id: int, callback_round: int, callback_attempt: int, callback_winner: int
) -> bool:
	if (
		callback_match_id != match_id
		or callback_round != completed_round
		or callback_attempt != sudden_death_attempt
		or tied_seats.size() < 2
		or not tied_seats.has(callback_winner)
		or sudden_death_resolved
	):
		return false
	winner_seat = callback_winner
	sudden_death_resolved = true
	return true


func callback_is_current(
	callback_match_id: int, callback_round: int, callback_attempt: int
) -> bool:
	return (
		callback_match_id == match_id
		and callback_round == completed_round
		and callback_attempt == sudden_death_attempt
		and tied_seats.size() >= 2
		and not sudden_death_resolved
	)


func _decision(kind: Decision) -> Dictionary:
	return {
		"kind": kind,
		"match_id": match_id,
		"completed_round": completed_round,
		"winner_seat": winner_seat,
		"tied_seats": tied_seats.duplicate(),
		"reason": terminal_reason,
		"attempt": sudden_death_attempt,
	}

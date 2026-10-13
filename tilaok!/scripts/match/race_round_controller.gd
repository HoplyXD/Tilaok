class_name RaceRoundController
extends RefCounted

var ledger := RaceOutcomeLedger.new()
var hard_cap_seconds := 60.0
var post_first_finish_seconds := 15.0
var elapsed_seconds := 0.0
var first_finish_deadline := -1.0
var active := false
var ended := false
var end_reason := ""


func configure(hard_cap: float, post_finish: float) -> bool:
	if (
		not is_finite(hard_cap)
		or not is_finite(post_finish)
		or hard_cap <= 0.0
		or post_finish <= 0.0
	):
		return false
	hard_cap_seconds = hard_cap
	post_first_finish_seconds = post_finish
	return true


func begin(round_id: String, seats: Array[int], starting_totals: Dictionary) -> bool:
	if not ledger.begin(round_id, seats, starting_totals):
		return false
	elapsed_seconds = 0.0
	first_finish_deadline = -1.0
	active = true
	ended = false
	end_reason = ""
	return true


## The step's candidates resolve before deadline checks so a finish on a boundary counts.
func advance_step(delta: float, physics_tick: int, candidates: Array[Dictionary]) -> Dictionary:
	if not active or ended:
		return {"active": active, "ended": ended, "new_outcomes": [], "end_reason": end_reason}
	elapsed_seconds += maxf(0.0, delta)
	var new_outcomes := ledger.resolve_step(physics_tick, candidates)
	if first_finish_deadline < 0.0:
		for outcome in new_outcomes:
			if str(outcome.get("outcome", "")) == "finished":
				first_finish_deadline = elapsed_seconds + post_first_finish_seconds
				break
	if ledger.all_terminal():
		_end("all_terminal")
	elif elapsed_seconds >= hard_cap_seconds:
		new_outcomes.append_array(ledger.fail_remaining(physics_tick, "hard_cap"))
		_end("hard_cap")
	elif first_finish_deadline >= 0.0 and elapsed_seconds >= first_finish_deadline:
		new_outcomes.append_array(ledger.fail_remaining(physics_tick, "post_finish_deadline"))
		_end("post_finish_deadline")
	return {
		"active": active,
		"ended": ended,
		"new_outcomes": new_outcomes,
		"end_reason": end_reason,
		"elapsed_seconds": elapsed_seconds,
		"first_finish_deadline": first_finish_deadline,
	}


func remaining_seconds() -> float:
	if not active or ended:
		return 0.0
	var remaining := hard_cap_seconds - elapsed_seconds
	if first_finish_deadline >= 0.0:
		remaining = minf(remaining, first_finish_deadline - elapsed_seconds)
	return maxf(0.0, remaining)


func _end(reason: String) -> void:
	active = false
	ended = true
	end_reason = reason

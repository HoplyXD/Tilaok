class_name MatchResultsViewModel
extends RefCounted

var round_number := 0
var diagnostic_label := ""
var per_seat_outcomes: Array[Dictionary] = []
var award_rows: Array[Dictionary] = []
var suppression_reason := ""
var totals: Dictionary = {}
var deadline_explanation := ""
var last_cluck_explanation := ""
var match_complete := false
var winner_seat := -1
var final_outcome_text := ""
var sudden_death := false
var final_seats: Array[Dictionary] = []


static func diagnostic(round_value: int, seats: Array[Dictionary]) -> MatchResultsViewModel:
	var model := MatchResultsViewModel.new()
	model.round_number = round_value
	model.diagnostic_label = "Round ended (diagnostic advance)."
	model.suppression_reason = "Awaiting P06 scoring integration; P05 awards no points."
	for seat in seats:
		(
			model
			. per_seat_outcomes
			. append(
				{
					"seat_index": int(seat.seat),
					"identity": int(seat.identity),
					"shape": str(seat.shape),
					"outcome": "Diagnostic Play ended; finish outcome is not evaluated.",
				}
			)
		)
	return model


static func race(
	round_value: int,
	seats: Array[Dictionary],
	outcomes: Array[Dictionary],
	score_result: Dictionary,
	end_reason: String,
	hard_cap_seconds: float,
	post_finish_seconds: float
) -> MatchResultsViewModel:
	var model := MatchResultsViewModel.new()
	model.round_number = round_value
	model.diagnostic_label = _end_reason_text(end_reason, hard_cap_seconds, post_finish_seconds)
	model.suppression_reason = str(score_result.get("suppression_reason", ""))
	model.deadline_explanation = (
		"Race limit %.0f s; after the first finish, remaining runners had %.0f s."
		% [hard_cap_seconds, post_finish_seconds]
	)
	var seat_by_index: Dictionary = {}
	for seat in seats:
		seat_by_index[int(seat.seat)] = seat
	var outcome_by_seat: Dictionary = {}
	for outcome in outcomes:
		outcome_by_seat[int(outcome.seat_index)] = outcome
	var delta_units: Dictionary = score_result.get("delta_units", {})
	var total_units: Dictionary = score_result.get("totals_units", {})
	for seat_index in seat_by_index:
		var seat: Dictionary = seat_by_index[seat_index]
		var outcome: Dictionary = outcome_by_seat.get(seat_index, {})
		var finished := str(outcome.get("outcome", "")) == "finished"
		var result_text := "Reached the flag; secured."
		if not finished:
			result_text = _elimination_text(
				str(outcome.get("cause", "eliminated")), hard_cap_seconds, post_finish_seconds
			)
		var delta := int(delta_units.get(seat_index, 0))
		var total := int(total_units.get(seat_index, 0))
		(
			model
			. per_seat_outcomes
			. append(
				{
					"seat_index": seat_index,
					"identity": int(seat.identity),
					"shape": str(seat.shape),
					"outcome": result_text,
					"score_delta_units": delta,
					"score_delta_text": _signed_score(delta),
					"total_units": total,
					"total_text": ScoreFormat.format_units(total),
				}
			)
		)
		model.totals[seat_index] = {
			"identity": int(seat.identity),
			"shape": str(seat.shape),
			"units": total,
			"text": ScoreFormat.format_units(total),
			"delta_units": delta,
			"delta_text": _signed_score(delta),
		}
	for award in score_result.get("award_rows", []):
		var row: Dictionary = award.duplicate(true)
		var seat: Dictionary = seat_by_index.get(int(row.get("seat_index", -1)), {})
		row["identity"] = int(seat.get("identity", 0))
		row["shape"] = str(seat.get("shape", ""))
		row["score_text"] = "+" + ScoreFormat.format_units(int(row.get("units", 0)))
		model.award_rows.append(row)
	return model


static func lag_sanay(
	round_value: int,
	seats: Array[Dictionary],
	outcomes: Array[Dictionary],
	score_result: Dictionary,
	opening_seconds: float,
	taya_seconds_2p: float,
	taya_seconds_3p: float,
	taya_seconds_4p: float,
	pass_back_seconds: float
) -> MatchResultsViewModel:
	var model := MatchResultsViewModel.new()
	model.round_number = round_value
	model.suppression_reason = str(score_result.get("suppression_reason", ""))
	model.deadline_explanation = (
		(
			"Opening head start %.1f s; taya timer %.0f s at 2, %.0f s at 3, %.0f s at 4 alive. "
			+ "Passing never resets the countdown; the previous taya cannot receive it for %.1f s."
		)
		% [
			opening_seconds,
			taya_seconds_2p,
			taya_seconds_3p,
			taya_seconds_4p,
			pass_back_seconds,
		]
	)
	var seat_by_index: Dictionary = {}
	for seat in seats:
		seat_by_index[int(seat.seat)] = seat
	var outcome_by_seat: Dictionary = {}
	for outcome in outcomes:
		outcome_by_seat[int(outcome.seat_index)] = outcome
	var winner := int(score_result.get("winner_seat", -1))
	var is_last_cluck := bool(score_result.get("last_cluck", false))
	if is_last_cluck:
		var winning_seat: Dictionary = seat_by_index.get(winner, {})
		model.diagnostic_label = (
			(
				"Last Cluck! P%d %s wins by the latest recorded elimination time. "
				+ "An exact time tie goes to the lowest stable player slot."
			)
			% [int(winning_seat.get("identity", winner + 1)), str(winning_seat.get("shape", ""))]
		)
		model.last_cluck_explanation = model.diagnostic_label
	else:
		var winner_seat: Dictionary = seat_by_index.get(winner, {})
		model.diagnostic_label = (
			"P%d %s is the last chicken standing."
			% [int(winner_seat.get("identity", winner + 1)), str(winner_seat.get("shape", ""))]
		)
	var delta_units: Dictionary = score_result.get("delta_units", {})
	var total_units: Dictionary = score_result.get("totals_units", {})
	for seat_index in seat_by_index:
		var seat: Dictionary = seat_by_index[seat_index]
		var outcome: Dictionary = outcome_by_seat.get(seat_index, {})
		var cause := str(outcome.get("cause", ""))
		var outcome_text := "Eliminated."
		if seat_index == winner:
			outcome_text = "Winner — %s." % ("Last Cluck" if is_last_cluck else "last survivor")
		elif cause == "timeout":
			outcome_text = "Taya timer expired."
		elif cause == "direct_hazard":
			outcome_text = "Directly eliminated by a trap."
		elif cause == "hazard":
			outcome_text = "Eliminated by a hazard; no direct Patibong credit."
		var delta := int(delta_units.get(seat_index, 0))
		var total := int(total_units.get(seat_index, 0))
		(
			model
			. per_seat_outcomes
			. append(
				{
					"seat_index": seat_index,
					"identity": int(seat.identity),
					"shape": str(seat.shape),
					"outcome": outcome_text,
					"score_delta_units": delta,
					"score_delta_text": _signed_score(delta),
					"total_units": total,
					"total_text": ScoreFormat.format_units(total),
				}
			)
		)
		model.totals[seat_index] = {
			"identity": int(seat.identity),
			"shape": str(seat.shape),
			"units": total,
			"text": ScoreFormat.format_units(total),
			"delta_units": delta,
			"delta_text": _signed_score(delta),
		}
	for award in score_result.get("award_rows", []):
		var row: Dictionary = award.duplicate(true)
		var seat: Dictionary = seat_by_index.get(int(row.get("seat_index", -1)), {})
		row["identity"] = int(seat.get("identity", 0))
		row["shape"] = str(seat.get("shape", ""))
		row["score_text"] = "+" + ScoreFormat.format_units(int(row.get("units", 0)))
		model.award_rows.append(row)
	return model


static func final_match(
	seats: Array[Dictionary],
	scores_units: Dictionary,
	winner: int,
	outcome_text: String,
	used_sudden_death: bool,
	last_cluck_text: String
) -> MatchResultsViewModel:
	var model := MatchResultsViewModel.new()
	model.match_complete = true
	model.winner_seat = winner
	model.final_outcome_text = outcome_text
	model.sudden_death = used_sudden_death
	model.last_cluck_explanation = last_cluck_text
	model.final_seats = seats.duplicate(true)
	model.diagnostic_label = outcome_text
	var winner_data: Dictionary = {}
	for seat in seats:
		var seat_index := int(seat.get("seat", -1))
		if seat_index < 0 or not bool(seat.get("joined", false)):
			continue
		var units := int(scores_units.get(seat_index, 0))
		var row := {
			"seat_index": seat_index,
			"identity": int(seat.get("identity", seat_index + 1)),
			"shape": str(seat.get("shape", "")),
			"total_units": units,
			"total_text": ScoreFormat.format_units(units),
			"outcome": "WINNER" if seat_index == winner else "FINAL SCORE",
		}
		model.per_seat_outcomes.append(row)
		model.totals[seat_index] = {
			"identity": row.identity,
			"shape": row.shape,
			"units": units,
			"text": row.total_text,
		}
		if seat_index == winner:
			winner_data = seat
	model.suppression_reason = "Final match scores are fixed; Lagsanay placement awards are not added."
	model.last_cluck_explanation = last_cluck_text
	if winner_data.is_empty():
		model.final_outcome_text = "Final winner is unavailable."
	return model


func as_dictionary() -> Dictionary:
	return {
		"round_number": round_number,
		"diagnostic_label": diagnostic_label,
		"per_seat_outcomes": per_seat_outcomes.duplicate(true),
		"award_rows": award_rows.duplicate(true),
		"suppression_reason": suppression_reason,
		"totals": totals.duplicate(true),
		"deadline_explanation": deadline_explanation,
		"last_cluck_explanation": last_cluck_explanation,
		"match_complete": match_complete,
		"winner_seat": winner_seat,
		"final_outcome_text": final_outcome_text,
		"sudden_death": sudden_death,
		"final_seats": final_seats.duplicate(true),
	}


static func _signed_score(units: int) -> String:
	return ("+" if units >= 0 else "") + ScoreFormat.format_units(units)


static func _end_reason_text(
	reason: String, hard_cap_seconds: float, post_finish_seconds: float
) -> String:
	match reason:
		"all_terminal":
			return "Every player finished or was eliminated."
		"hard_cap":
			return "The %.0f-second race limit ended the round." % hard_cap_seconds
		"post_finish_deadline":
			return "The %.0f-second finish window ended the round." % post_finish_seconds
	return "Karera round complete."


static func _elimination_text(
	cause: String, hard_cap_seconds: float, post_finish_seconds: float
) -> String:
	match cause:
		"hard_cap":
			return "Did not reach the flag before the %.0f-second race limit." % hard_cap_seconds
		"post_finish_deadline":
			return (
				"Did not reach the flag within %.0f seconds of the first finish."
				% post_finish_seconds
			)
		"reached_goal":
			return "Reached the flag; secured."
	return "Eliminated before reaching the flag."

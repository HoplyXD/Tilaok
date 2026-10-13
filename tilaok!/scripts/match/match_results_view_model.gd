class_name MatchResultsViewModel
extends RefCounted

var round_number := 0
var diagnostic_label := ""
var per_seat_outcomes: Array[Dictionary] = []
var award_rows: Array[Dictionary] = []
var suppression_reason := ""
var totals: Dictionary = {}


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


func as_dictionary() -> Dictionary:
	return {
		"round_number": round_number,
		"diagnostic_label": diagnostic_label,
		"per_seat_outcomes": per_seat_outcomes.duplicate(true),
		"award_rows": award_rows.duplicate(true),
		"suppression_reason": suppression_reason,
		"totals": totals.duplicate(true),
	}

class_name ContainmentRecoveryContract
extends RefCounted

enum Mode { RACE, LAGSANAY, KANGAROO }
enum Outcome { NONE, FAILED_RACE, PROTOTYPE_DEFECT }

var mode := Mode.RACE
var pre_round_scores: Array[int] = []
var construction_revision := 0
var outcome := Outcome.NONE
var outcome_count := 0
var recovery_count := 0


func begin_round(scores: Array[int], construction_token: int, selected_mode: Mode) -> void:
	pre_round_scores = scores.duplicate()
	construction_revision = construction_token
	mode = selected_mode
	outcome = Outcome.NONE
	outcome_count = 0
	recovery_count = 0


func report_escape() -> Outcome:
	if outcome != Outcome.NONE:
		return outcome
	outcome = Outcome.FAILED_RACE if mode == Mode.RACE else Outcome.PROTOTYPE_DEFECT
	outcome_count = 1
	return outcome


func recover() -> Dictionary:
	if outcome != Outcome.PROTOTYPE_DEFECT:
		return {}
	recovery_count += 1
	return {
		"scores": pre_round_scores.duplicate(),
		"construction_revision": construction_revision,
		"award_count": 0,
		"outcome_count": outcome_count,
	}

class_name LivePlacementRequest
extends RefCounted

## Immutable-by-convention snapshot of the fields an input owner may propose.

var request_id := ""
var match_id := -1
var round_id := -1
var attempt_id := ""
var observed_stage_version := -1
var variant_key := ""
var objective := ""
var cell := Vector2i.ZERO
var quarter_turns := 0


static func from_intent(intent: Dictionary):
	var request := LivePlacementRequest.new()
	request.request_id = str(intent.get("request_id", ""))
	request.match_id = int(intent.get("match_id", -1))
	request.round_id = int(intent.get("round_id", -1))
	request.attempt_id = str(intent.get("attempt_id", ""))
	request.observed_stage_version = int(intent.get("observed_stage_version", -1))
	request.variant_key = str(intent.get("variant_key", ""))
	request.objective = str(intent.get("objective", ""))
	request.cell = intent.get("cell", Vector2i.ZERO)
	request.quarter_turns = int(intent.get("quarter_turns", 0))
	return request


func to_dictionary() -> Dictionary:
	return {
		"request_id": request_id,
		"match_id": match_id,
		"round_id": round_id,
		"attempt_id": attempt_id,
		"observed_stage_version": observed_stage_version,
		"variant_key": variant_key,
		"objective": objective,
		"cell": cell,
		"quarter_turns": quarter_turns,
	}

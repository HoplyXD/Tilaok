class_name ItemStepContext
extends RefCounted

## Everything one director step gives a behavior. Behaviors only READ the stage and REPORT intents
## here; the director resolves all of them in one stable order (time, item ID, seat).

var tuning: GameplayTuning
var arena: ArenaDefinition
var budget: TransientBudget
var director: ItemHazardDirector
var actors: Array[ChickenController] = []
var dt := 0.0
var time_start := 0.0
var time_end := 0.0
var base_occluders: Array[Rect2] = []
var piece_occluders: Array[Dictionary] = []
var lethal_reports: Array[Dictionary] = []
var launch_requests: Array[Dictionary] = []
var slot_requests: Array[Dictionary] = []


func occluders_excluding(item_id: String) -> Array[Rect2]:
	var result: Array[Rect2] = base_occluders.duplicate()
	for entry in piece_occluders:
		if str(entry.item_id) != item_id:
			result.append_array(entry.rects)
	return result


func body_of(actor: ChickenController) -> Rect2:
	return SweptContact.body_rect(actor, tuning)


## Players a hazard may affect: alive and not in the opening freeze (which ignores hazards).
func is_hazard_target(actor: ChickenController) -> bool:
	if actor == null or not is_instance_valid(actor) or actor.lifecycle.is_terminal():
		return false
	return actor.lifecycle.status != PlayerLifecycleState.Status.OPENING_FREEZE


func report_lethal(seat: int, time: float, item_id: String, detail: String) -> void:
	lethal_reports.append({"seat": seat, "time": time, "item_id": item_id, "detail": detail})


func request_launch(seat: int, item_id: String, normal: Vector2) -> void:
	launch_requests.append({"seat": seat, "item_id": item_id, "normal": normal})


func request_slot(item_id: String, kind: TransientBudget.Kind) -> void:
	slot_requests.append({"emitter_id": item_id, "kind": kind})

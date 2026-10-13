class_name RaceCandidateQueue
extends RefCounted

## Collect candidates until the match room closes one complete physics-step batch.
var round_id := ""
var candidates: Array[Dictionary] = []
var event_ids: Dictionary = {}


func begin(new_round_id: String) -> void:
	round_id = new_round_id
	candidates.clear()
	event_ids.clear()


func reset() -> void:
	round_id = ""
	candidates.clear()
	event_ids.clear()


func collect_goal_overlaps(goal_area: Area2D, physics_tick: int) -> void:
	if goal_area == null or not is_instance_valid(goal_area) or round_id.is_empty():
		return
	for body in goal_area.get_overlapping_bodies():
		if body is ChickenController:
			queue_goal(body as ChickenController, physics_tick)


func queue_goal(actor: ChickenController, physics_tick: int) -> bool:
	if actor == null or not is_instance_valid(actor):
		return false
	if actor.lifecycle.status != PlayerLifecycleState.Status.ACTIVE or round_id.is_empty():
		return false
	return _queue(
		{
			"event_id": "%s:goal:%d:%d" % [round_id, physics_tick, actor.seat_index],
			"round_id": round_id,
			"seat_index": actor.seat_index,
			"kind": "goal",
			"physics_tick": physics_tick,
			"source_item_id": "",
			"direct_owner_seat": -1,
		}
	)


func queue_elimination(
	seat_index: int,
	physics_tick: int,
	source_item_id: String = "",
	direct_owner_seat: int = -1,
	event_id: String = ""
) -> bool:
	if round_id.is_empty():
		return false
	var stable_event_id := event_id
	if stable_event_id.is_empty():
		stable_event_id = (
			"%s:elimination:%d:%d:%s" % [round_id, physics_tick, seat_index, source_item_id]
		)
	return _queue(
		{
			"event_id": stable_event_id,
			"round_id": round_id,
			"seat_index": seat_index,
			"kind": "elimination",
			"physics_tick": physics_tick,
			"source_item_id": source_item_id,
			"direct_owner_seat": direct_owner_seat,
		}
	)


func drain() -> Array[Dictionary]:
	var result := candidates.duplicate(true)
	candidates.clear()
	event_ids.clear()
	return result


func _queue(candidate: Dictionary) -> bool:
	var event_id := str(candidate.event_id)
	if event_ids.has(event_id):
		return true
	event_ids[event_id] = true
	candidates.append(candidate)
	return true

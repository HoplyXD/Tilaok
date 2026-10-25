class_name TutorialSession
extends RefCounted

## Session-only tutorial memory, owned by GameFlow. Nothing here is saved: no file, no ConfigFile,
## no user:// write, and no tutorial bonus. A new app launch always starts a fresh session.

signal changed

var skipped := false
var completed := false
var seen_lagsanay := false
var seen_item_literacy := false
## Kangaroo just-in-time steps already shown this session (step id -> true).
var seen_kangaroo_steps: Dictionary = {}
## Session-only learning evidence, keyed by action name and then seat index.
var learned_actions: Dictionary = {}


## True while the guided first match should use the tutorial stage layout and coach box.
func is_active() -> bool:
	return not skipped and not completed


## The next match uses the tutorial layout only while the tutorial is still active.
func wants_tutorial_layout() -> bool:
	return is_active()


func skip() -> void:
	if skipped:
		return
	skipped = true
	changed.emit()


func mark_completed() -> void:
	if completed:
		return
	completed = true
	changed.emit()


func mark_lagsanay_seen() -> void:
	if seen_lagsanay:
		return
	seen_lagsanay = true
	changed.emit()


func mark_item_literacy_seen() -> void:
	if seen_item_literacy:
		return
	seen_item_literacy = true
	changed.emit()


func kangaroo_step_due(step_id: StringName) -> bool:
	return not skipped and not seen_kangaroo_steps.has(str(step_id))


func mark_kangaroo_step(step_id: StringName) -> void:
	if seen_kangaroo_steps.has(str(step_id)):
		return
	seen_kangaroo_steps[str(step_id)] = true
	changed.emit()


func mark_action_learned(action: StringName, seat_index: int) -> void:
	var key := str(action)
	if not learned_actions.has(key):
		learned_actions[key] = {}
	var seats: Dictionary = learned_actions[key]
	if seats.has(seat_index):
		return
	seats[seat_index] = true
	learned_actions[key] = seats
	changed.emit()


func has_learned_action(action: StringName, seat_index: int) -> bool:
	var seats: Dictionary = learned_actions.get(str(action), {})
	return bool(seats.get(seat_index, false))


func all_seats_learned(action: StringName, seat_indices: Array[int]) -> bool:
	if seat_indices.is_empty():
		return false
	for seat_index in seat_indices:
		if not has_learned_action(action, seat_index):
			return false
	return true


## "Replay tutorial" clears the whole session set (steps, skip and the just-in-time prompts).
func replay() -> void:
	skipped = false
	completed = false
	seen_lagsanay = false
	seen_item_literacy = false
	seen_kangaroo_steps.clear()
	learned_actions.clear()
	changed.emit()


func lagsanay_prompt_due() -> bool:
	return not skipped and not seen_lagsanay

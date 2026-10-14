class_name TutorialCoordinator
extends Node

## Read-only guided-round coordinator. It watches the match room's existing signals and state and
## publishes a display view for the coach box; it never writes room state, scores or timings and it
## never touches input. All wording lives in TutorialScript, all numbers come from the match's
## GameplayTuning snapshot or the stage layout.

signal step_changed(new_view: Dictionary)

const TUTORIAL_LAYOUT_ID := "tutorial"
const MARKER_SCENE := preload("res://scenes/tutorial/build_here_marker.tscn")
const GLYPH_SEPARATOR := " / "
const VARIANT_CLAIMED := &"claimed"
const VARIANT_LOST := &"lost"
const VARIANT_TIMEOUT := &"timeout"
const VARIANT_NOBODY := &"nobody"
const VARIANT_EVERYONE := &"everyone"
const VARIANT_WAIVER := &"waiver"

var room: P05MatchRoom
var session: TutorialSession
var tutorial_script: TutorialScript
var prompt_map: UiPromptMap
## The last published view; always safe to read (visible=false when there is nothing to show).
var view: Dictionary = {"visible": false, "step_id": &""}
var suppressed := false

var _marker: BuildHereMarker
var _timeout_assigned := false
var _assigned_snapshot := 0
var _nobody_finished_last_round := false
var _completion_pending := false
var _lagsanay_showing := false


func attach(
	p_room: P05MatchRoom, p_session: TutorialSession, p_script: TutorialScript, p_map: UiPromptMap
) -> void:
	detach()
	room = p_room
	session = p_session
	tutorial_script = p_script
	prompt_map = p_map
	room.phase_controller.phase_changed.connect(_on_phase_changed)
	room.presentation_changed.connect(_on_presentation_changed)
	room.actor_created.connect(_on_actor_created)
	for actor_variant in room.actors.values():
		_on_actor_created(actor_variant as ChickenController)
	session.changed.connect(_on_session_changed)
	rebuild()


func detach() -> void:
	if room != null and is_instance_valid(room):
		if room.phase_controller.phase_changed.is_connected(_on_phase_changed):
			room.phase_controller.phase_changed.disconnect(_on_phase_changed)
		if room.presentation_changed.is_connected(_on_presentation_changed):
			room.presentation_changed.disconnect(_on_presentation_changed)
		if room.actor_created.is_connected(_on_actor_created):
			room.actor_created.disconnect(_on_actor_created)
		for actor_variant in room.actors.values():
			var actor := actor_variant as ChickenController
			if (
				actor != null
				and is_instance_valid(actor)
				and actor.terminal_state_changed.is_connected(_on_actor_terminal)
			):
				actor.terminal_state_changed.disconnect(_on_actor_terminal)
	if session != null and session.changed.is_connected(_on_session_changed):
		session.changed.disconnect(_on_session_changed)
	_free_marker()
	room = null
	session = null


func _exit_tree() -> void:
	detach()


## The presenter hides the box and marker while a pause, overlay, confirmation or final result
## owns the screen.
func set_suppressed(value: bool) -> void:
	if suppressed == value:
		return
	suppressed = value
	rebuild()


func skip() -> void:
	if session != null:
		session.skip()


func is_tutorial_stage() -> bool:
	return room != null and room.arena != null and room.arena.layout_id == TUTORIAL_LAYOUT_ID


func rebuild() -> void:
	if room == null or not is_instance_valid(room) or session == null:
		return
	_update_lagsanay_flag()
	var next := _compute_view()
	_sync_marker(next)
	if next == view:
		return
	view = next
	step_changed.emit(view)


# --- events -----------------------------------------------------------------------------------


func _on_phase_changed(
	previous_phase: MatchPhaseController.Phase, next_phase: MatchPhaseController.Phase
) -> void:
	if next_phase == MatchPhaseController.Phase.PUGAD:
		_timeout_assigned = false
		_assigned_snapshot = 0
		if previous_phase == MatchPhaseController.Phase.RESULTS and _completion_pending:
			_completion_pending = false
			session.mark_completed()
	elif next_phase == MatchPhaseController.Phase.PLACE:
		# Seats that gained an egg after the last egg update were assigned by the Pugad timer.
		_timeout_assigned = room.assignments.size() > _assigned_snapshot
	elif next_phase == MatchPhaseController.Phase.RESULTS:
		_record_round_outcome()
	rebuild()


func _on_presentation_changed(reason: StringName) -> void:
	if reason == &"eggs" and room.phase_controller.phase == MatchPhaseController.Phase.PUGAD:
		_assigned_snapshot = room.assignments.size()
	rebuild()


func _on_actor_created(actor: ChickenController) -> void:
	if actor == null or not is_instance_valid(actor):
		return
	if not actor.terminal_state_changed.is_connected(_on_actor_terminal):
		actor.terminal_state_changed.connect(_on_actor_terminal)


func _on_actor_terminal(_status: PlayerLifecycleState.Status, _reason: String) -> void:
	rebuild()


func _on_session_changed() -> void:
	rebuild()


# --- state ------------------------------------------------------------------------------------


func finisher_count() -> int:
	var count := 0
	for actor_variant in room.actors.values():
		var actor := actor_variant as ChickenController
		if (
			actor != null
			and actor.lifecycle.status == PlayerLifecycleState.Status.SECURED
			and actor.lifecycle.terminal_reason == "reached_goal"
		):
			count += 1
	return count


func _record_round_outcome() -> void:
	if room.race_round_controller == null or not room.race_round_controller.ended:
		return
	var finishers := finisher_count()
	_nobody_finished_last_round = finishers == 0
	if finishers > 0 and is_tutorial_stage():
		_completion_pending = true


func _lagsanay_running() -> bool:
	if room.phase_controller.phase != MatchPhaseController.Phase.PLAY:
		return false
	var controller: Variant = room.get("lagsanay_controller")
	return controller != null and bool(controller.get("active"))


func _update_lagsanay_flag() -> void:
	var running := _lagsanay_running()
	if running and session.lagsanay_prompt_due():
		_lagsanay_showing = true
	elif not running and _lagsanay_showing:
		_lagsanay_showing = false
		session.mark_lagsanay_seen()


func _compute_view() -> Dictionary:
	var hidden := {"visible": false, "step_id": &""}
	if session.skipped or suppressed or room.shows_final_results():
		return hidden
	if _lagsanay_showing:
		return _view_for(TutorialScript.STEP_LAGSANAY, &"", 0)
	if not is_tutorial_stage() or session.completed:
		return hidden
	return _phase_view(hidden)


func _phase_view(hidden: Dictionary) -> Dictionary:
	var result := hidden
	match room.phase_controller.phase:
		MatchPhaseController.Phase.LOBBY:
			result = _view_for(TutorialScript.STEP_WELCOME, &"", 1)
		MatchPhaseController.Phase.PUGAD:
			result = _view_for(TutorialScript.STEP_PUGAD, _pugad_variant(), 2)
		MatchPhaseController.Phase.PLACE:
			var level := 2 if _nobody_finished_last_round else 1
			var place_variant := VARIANT_TIMEOUT if _timeout_assigned else &""
			result = _view_for(TutorialScript.STEP_PLACE, place_variant, 3, level)
		MatchPhaseController.Phase.PLAY:
			result = _view_for(TutorialScript.STEP_KARERA, &"", 4)
		MatchPhaseController.Phase.RESULTS:
			result = _view_for(TutorialScript.STEP_RESULTS, _results_variant(), 5)
	return result


func _pugad_variant() -> StringName:
	if not room.claim_feedback.is_empty():
		return VARIANT_LOST
	if not room.assignments.is_empty():
		return VARIANT_CLAIMED
	return &""


func _results_variant() -> StringName:
	var seats := room.input_router.registry.joined_seats().size()
	var finishers := finisher_count()
	if finishers == 0:
		return VARIANT_NOBODY
	if finishers >= seats and seats >= 3:
		return VARIANT_EVERYONE
	if finishers >= seats and seats == 2:
		return VARIANT_WAIVER
	return &""


func _view_for(step_id: StringName, variant: StringName, number: int, level: int = 1) -> Dictionary:
	var definition := tutorial_script.step(step_id)
	if definition == null:
		return {"visible": false, "step_id": &""}
	var body := definition.body_for(variant, level)
	var glyph := _glyphs(definition.glyph_action)
	var action_label := ""
	if prompt_map != null and not definition.glyph_action.is_empty():
		action_label = prompt_map.action_name(_map_action(definition.glyph_action))
	return {
		"visible": true,
		"step_id": step_id,
		"step_number": number,
		"title": definition.title,
		"body": _fill(body),
		"glyph": glyph,
		"action": action_label,
		"hint_level": level,
		"build_here": step_id == TutorialScript.STEP_PLACE,
		"skip_caption": tutorial_script.skip_caption,
		"tag": tutorial_script.placeholder_tag,
	}


# --- copy tokens ------------------------------------------------------------------------------


func _fill(text: String) -> String:
	var tuning := room.tuning
	var cell := tuning.grid_cell_wu
	var reason := ""
	if room.last_results_model != null:
		reason = room.last_results_model.suppression_reason
	var tokens := {
		"roster": _roster(),
		"move": _glyphs("run"),
		"jump": _glyphs("jump"),
		"claim": _glyphs("claim"),
		"rotate": _glyphs("rotate"),
		"confirm": _glyphs("confirm"),
		"pugad_s": _number(tuning.match_pugad_seconds),
		"place_s": _number(tuning.match_place_seconds),
		"cap_s": _number(tuning.match_race_hard_cap_seconds),
		"finish_s": _number(tuning.match_race_after_first_finish_seconds),
		"advance_s": _number(tuning.match_results_advance_seconds),
		"head_start_s": _number(tuning.lagsanay_opening_head_start_seconds),
		"ledge_tiles": _number(room.arena.flag_height_tiles()),
		"jump_tiles": _number(tuning.jump_height_wu / cell),
		"result_reason": reason,
	}
	var result := text
	for key in tokens:
		result = result.replace("{%s}" % key, str(tokens[key]))
	return result.strip_edges()


func _roster() -> String:
	var parts: Array[String] = []
	for seat in room.input_router.registry.joined_seats():
		parts.append("%d %s" % [int(seat.identity), str(seat.shape)])
	return ", ".join(parts)


## Glyphs for every device in play (K1 / K2 / gamepad), de-duplicated, in seat order.
func _glyphs(action: String) -> String:
	if prompt_map == null or action.is_empty():
		return ""
	var mapped := _map_action(action)
	var seen: Array[String] = []
	for seat in room.input_router.registry.joined_seats():
		var glyph := prompt_map.glyph(mapped, UiContext.device_for_seat(seat))
		if not seen.has(glyph):
			seen.append(glyph)
	if seen.is_empty():
		seen.append(prompt_map.glyph(mapped, "k1"))
	return GLYPH_SEPARATOR.join(seen)


func _map_action(action: String) -> String:
	return "run" if action == "move" else action


static func _number(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return str(int(roundf(value)))
	return "%.1f" % value


# --- BUILD HERE marker ------------------------------------------------------------------------


func _sync_marker(next_view: Dictionary) -> void:
	var wanted := bool(next_view.get("build_here", false)) and bool(next_view.get("visible", false))
	if not wanted:
		if _marker != null and is_instance_valid(_marker):
			_marker.visible = false
		return
	if room.world_layer == null or room.arena.build_here_zone.size == Vector2.ZERO:
		return
	if _marker == null or not is_instance_valid(_marker):
		_marker = MARKER_SCENE.instantiate() as BuildHereMarker
		room.world_layer.add_child(_marker)
	_marker.configure(room.arena.build_here_zone, int(next_view.get("hint_level", 1)) >= 2)
	_marker.visible = true


func _free_marker() -> void:
	if _marker != null and is_instance_valid(_marker):
		_marker.queue_free()
	_marker = null

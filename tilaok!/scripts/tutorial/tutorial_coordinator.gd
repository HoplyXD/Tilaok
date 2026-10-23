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
const VARIANT_TWIST := &"twist"
## The taya prompt (Lagsanay Main or Bomb-Taya Twist) sits over the stage's left edge and shares
## the box with the other just-in-time prompts, so it hands over after this long: the chickens
## are uncovered and the next due prompt (Kangaroo) takes its turn.
const TAYA_PROMPT_SECONDS := 12.0

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
var _lagsanay_as_twist := false
var _taya_prompt_expired := false
## The Kangaroo prompt shown during the current phase; marked seen when that phase ends.
var _kangaroo_step: StringName = &""


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
	if _kangaroo_step != &"":
		session.mark_kangaroo_step(_kangaroo_step)
		_kangaroo_step = &""
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


func _on_taya_prompt_timeout() -> void:
	_taya_prompt_expired = true
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
	if controller != null and bool(controller.get("active")):
		_lagsanay_as_twist = false
		return true
	# Bomb-Taya (Lagsanay as a Twist) teaches the same taya rules with Twist wording.
	var bomb: Variant = room.get("bomb_taya")
	if bomb != null and bool(bomb.get("active")):
		_lagsanay_as_twist = true
		return true
	return false


func _update_lagsanay_flag() -> void:
	var running := _lagsanay_running()
	if not running:
		_taya_prompt_expired = false
	elif _taya_prompt_expired:
		running = false
	if running and session.lagsanay_prompt_due():
		if not _lagsanay_showing and is_inside_tree():
			_taya_prompt_expired = false
			get_tree().create_timer(TAYA_PROMPT_SECONDS).timeout.connect(_on_taya_prompt_timeout)
		_lagsanay_showing = true
	elif not running and _lagsanay_showing:
		_lagsanay_showing = false
		session.mark_lagsanay_seen()


func _compute_view() -> Dictionary:
	var hidden := {"visible": false, "step_id": &""}
	if session.skipped or suppressed or room.shows_final_results():
		return hidden
	if _lagsanay_showing:
		var variant: StringName = VARIANT_TWIST if _lagsanay_as_twist else &""
		return _view_for(TutorialScript.STEP_LAGSANAY, variant, 0)
	var guided := is_tutorial_stage() and not session.completed
	var phase := room.phase_controller.phase
	var kangaroo_step := _kangaroo_jit_step()
	# The guided Pugad / Place / Results steps keep the box; the Kangaroo prompt takes Play.
	if kangaroo_step != &"" and (not guided or phase == MatchPhaseController.Phase.PLAY):
		_kangaroo_step = kangaroo_step
		return _view_for(kangaroo_step, &"", 0)
	if not guided:
		return hidden
	return _phase_view(hidden)


## The Kangaroo just-in-time step due in this phase, or &"". Poses in the Pugad and supports in
## the Place of a round that is, or precedes, a Kangaroo Main or Twist round (so players can build
## for it); the three misses once its commands are running.
func _kangaroo_jit_step() -> StringName:
	if session.skipped or room.shows_final_results():
		return &""
	var step := &""
	match room.phase_controller.phase:
		MatchPhaseController.Phase.PUGAD:
			if _kangaroo_near():
				step = TutorialScript.STEP_KANGAROO_POSES
		MatchPhaseController.Phase.PLACE:
			if _kangaroo_near():
				step = TutorialScript.STEP_KANGAROO_SUPPORTS
		MatchPhaseController.Phase.PLAY:
			if _kangaroo_running():
				step = TutorialScript.STEP_KANGAROO_MISSES
	if step != &"" and session.kangaroo_step_due(step):
		return step
	return &""


func _kangaroo_running() -> bool:
	var round_node: Variant = room.get("kangaroo_round")
	if round_node == null:
		return false
	var controller: Variant = round_node.get("controller")
	return controller != null and bool(controller.get("active"))


## The round being set up, or the next one (already announced), includes Kangaroo.
func _kangaroo_near() -> bool:
	if not room.has_method("current_entry") or room.get("schedule") == null:
		return false
	var entries: Array[Dictionary] = [room.call("current_entry")]
	var schedule: Variant = room.get("schedule")
	var upcoming: Variant = schedule.call("entry_for", room.items.round_number + 2)
	if upcoming is Dictionary:
		entries.append(upcoming)
	for entry in entries:
		if (
			int(entry.get("main", -1)) == EventSchedule.Challenge.KANGAROO
			or int(entry.get("twist", -1)) == EventSchedule.Challenge.KANGAROO
		):
			return true
	return false


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
		MatchPhaseController.Phase.GO:
			result = _view_for(TutorialScript.STEP_LIVE_BUILD, &"", 3)
		MatchPhaseController.Phase.PLAY:
			result = _view_for(TutorialScript.STEP_KARERA, &"", 4)
		MatchPhaseController.Phase.RESULTS:
			result = _view_for(TutorialScript.STEP_RESULTS, _results_variant(), 5)
	return result


## Claim feedback first: a new player must always see "claimed" / "lost" and the timer. The
## Barya note (which also repeats the claim key and timer) shows only before any claim.
func _pugad_variant() -> StringName:
	if not room.claim_feedback.is_empty():
		return VARIANT_LOST
	if not room.assignments.is_empty():
		return VARIANT_CLAIMED
	if room.tuning.barya_enabled:
		for egg in room.egg_pool:
			if BaryaObjectiveDefinition.is_variant(str(egg.get("variant_key", ""))):
				return &"barya"
	return &""


func _results_variant() -> StringName:
	var seats := room.input_router.registry.joined_seats().size()
	var finishers := finisher_count()
	if finishers == 0:
		return VARIANT_NOBODY
	if finishers >= seats:
		return VARIANT_EVERYONE
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
		"build": _glyphs("build_toggle"),
		"aim": _glyphs("aim"),
		"live_confirm": _glyphs("live_confirm"),
		"rotate_live": _glyphs("live_rotate"),
		"cancel": _glyphs("live_cancel"),
		"pugad_s": _number(tuning.match_pugad_seconds),
		"place_s": _number(tuning.match_place_seconds),
		"construction_s":
		_number(
			(
				(room as OfflineLiveBuildMatchRoom).construction_seconds
				if room is OfflineLiveBuildMatchRoom
				else 2.0
			)
		),
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

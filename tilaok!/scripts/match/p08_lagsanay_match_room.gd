class_name P08LagsanayMatchRoom
extends P05MatchRoom

const P08_BUILD_ID := "P08-independent-lagsanay-dev"
const P08_VARIANTS: PackedStringArray = [
	"build.hollow_blocks.cell_1x1",
	"build.hollow_blocks.stack_2x3",
	"build.bamboo_bridge.span_4x1",
	"hazard.rail_trumpo.rail_4x1",
	"hazard.slipper_launcher.lane_4x1",
]

var lagsanay_controller := LagsanayRoundController.new()
var _taya_marker: Label
var _defect_banner: Label
var _restart_attempt_button: Button
var _attempt_serial := 0
var _defect_paused := false
var _defect_reason := ""
var _freeze_generation := 0


func _init() -> void:
	profile_id = "lagsanay_lab"
	tuning.item_enabled_variants = P08_VARIANTS.duplicate()


func _ready() -> void:
	super._ready()
	process_physics_priority = 300
	if goal_area != null:
		goal_area.monitoring = false
		goal_area.collision_mask = 0
		goal_area.visible = false
	if not pause_coordinator.pause_state_changed.is_connected(_on_lagsanay_pause_state_changed):
		pause_coordinator.pause_state_changed.connect(_on_lagsanay_pause_state_changed)
	for child in world_layer.get_children():
		if child is Label and (child as Label).text == "KARERA GOAL":
			(child as Label).visible = false
		elif child is Line2D and (child as Line2D).name == "FlagTriggerOutline":
			(child as Line2D).visible = false
	var row := _top_bar.get_child(0) as HBoxContainer
	if row != null and row.get_child(0) is Label:
		(row.get_child(0) as Label).text = "TILAOK! • LAGSANAY LAB"
	_restart_attempt_button = _add_match_button(
		row, "Restart attempt", _restart_lagsanay_attempt, "restart_attempt"
	)
	_restart_attempt_button.visible = false
	_taya_marker = Label.new()
	_taya_marker.name = "P08TayaMarker"
	_taya_marker.add_theme_font_size_override("font_size", 18)
	_taya_marker.add_theme_color_override("font_color", Color("#fff176"))
	_taya_marker.add_theme_color_override("font_outline_color", Color("#17262d"))
	_taya_marker.add_theme_constant_override("outline_size", 5)
	_taya_marker.size = Vector2(220.0, 30.0)
	_taya_marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_taya_marker.visible = false
	world_layer.add_child(_taya_marker)
	_set_input_phase()
	_update_diagnostics()
	print("P08_LAGSANAY_READY build=%s profile=%s seed=%d" % [P08_BUILD_ID, profile_id, match_seed])


func _exit_tree() -> void:
	_freeze_generation += 1
	if (
		pause_coordinator != null
		and pause_coordinator.pause_state_changed.is_connected(_on_lagsanay_pause_state_changed)
	):
		pause_coordinator.pause_state_changed.disconnect(_on_lagsanay_pause_state_changed)
	if get_tree().paused:
		get_tree().paused = false
	lagsanay_controller.reset()
	super._exit_tree()


func _process(delta: float) -> void:
	super._process(delta)
	_update_taya_marker()
	_update_defect_presentation()


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if get_tree().paused or phase_controller.phase != MatchPhaseController.Phase.PLAY:
		return
	_advance_mode_play_physics(delta)


func _begin_pugad() -> void:
	lagsanay_controller.reset()
	_defect_paused = false
	_defect_reason = ""
	_attempt_serial = 0
	if _restart_attempt_button != null:
		_restart_attempt_button.visible = false
	super._begin_pugad()


func _toggle_pause() -> void:
	if pause_coordinator.state == PauseRecoveryCoordinator.State.RUNNING:
		pause_coordinator.set_paused("participant requested pause", -1)
		return
	if pause_coordinator.state == PauseRecoveryCoordinator.State.PAUSED:
		for seat in input_router.registry.joined_seats():
			input_router.registry.set_ready(int(seat.seat), true)
		pause_coordinator.request_resume()


func _on_lagsanay_pause_state_changed(paused_state: bool, _reason: String) -> void:
	if paused_state:
		get_tree().paused = true


func _update_diagnostics() -> void:
	super._update_diagnostics()
	if _phase_label == null:
		return
	if phase_controller.phase == MatchPhaseController.Phase.PLAY:
		_timer_label.text = _mode_play_timer_text()
		if _feedback_label != null:
			_feedback_label.text = _lagsanay_status_text()
	if _hints_label != null:
		_hints_label.text = _phase_hint()
	if _restart_attempt_button != null:
		_restart_attempt_button.visible = _defect_paused


func _phase_hint() -> String:
	if phase_controller.phase == MatchPhaseController.Phase.PLAY:
		return "Tag: pass the bomb • avoid traps • expiry eliminates the taya • pause freezes all clocks"
	if phase_controller.phase == MatchPhaseController.Phase.RESULTS:
		return "F / Enter / Pad A ready · construction and scores carry into the next round"
	return super._phase_hint()


func _enter_play() -> void:
	_free_match_ghosts()
	input_router.set_rotation_supported(false)
	# Place and Pugad never carry movement state into the next play attempt.
	_reset_actors_for_round()
	phase_controller.enter(MatchPhaseController.Phase.PLAY)
	_set_input_phase()
	current_context = BoundedStageCamera.Context.PLAY
	camera_rig.set_context(current_context)
	start_play()
	round_start_score_units = cumulative_score_units.duplicate(true)
	_attempt_serial = 0
	_begin_lagsanay_attempt(false)
	last_message = "Lagsanay: pass the taya before the countdown expires."
	_refresh_match_ui()


func _begin_lagsanay_attempt(is_retry: bool) -> void:
	var seats: Array[int] = []
	for seat in input_router.registry.joined_seats():
		seats.append(int(seat.seat))
	if is_retry:
		_reset_actors_for_round()
		start_play()
		_attempt_serial += 1
	var round_id := "%d:%d:p08:%d" % [match_run_id, items.round_number + 1, _attempt_serial]
	if not lagsanay_controller.begin(
		round_id,
		seats,
		round_start_score_units,
		match_streams.taya,
		tuning.lagsanay_opening_head_start_seconds,
		tuning.taya_pass_back_seconds,
		tuning.lagsanay_taya_seconds_2p,
		tuning.lagsanay_taya_seconds_3p,
		tuning.lagsanay_taya_seconds_4p
	):
		push_error("Could not initialize Lagsanay round %s" % round_id)
		return
	items.director.active_round_id = round_id
	items.director.elimination_sink_exclusive = true
	for seat in seats:
		var actor := actors.get(seat) as ChickenController
		if actor != null:
			actor.set_opening_freeze(seat == lagsanay_controller.opening_taya_seat)
	_update_taya_marker()


func _advance_mode_play_physics(delta: float) -> void:
	var contacts := _tag_contacts_snapshot()
	var step_result := lagsanay_controller.advance_step(
		delta, Engine.get_physics_frames(), contacts, actors
	)
	if bool(step_result.head_start_ended):
		var opening_actor := actors.get(lagsanay_controller.opening_taya_seat) as ChickenController
		if opening_actor != null:
			opening_actor.set_opening_freeze(false)
	_apply_lagsanay_outcomes(step_result.new_outcomes, bool(step_result.last_cluck))
	_update_taya_marker()
	_update_camera_targets()
	if bool(step_result.ended):
		_finish_lagsanay(bool(step_result.last_cluck))
	else:
		_update_diagnostics()


func _mode_play_timer_text() -> String:
	if not lagsanay_controller.active:
		return ""
	var identity_text := _seat_identity_text(lagsanay_controller.taya_seat)
	if lagsanay_controller.head_start_remaining > 0.0:
		return (
			"TAYA %s • HEAD START %.1f s"
			% [identity_text, lagsanay_controller.head_start_remaining]
		)
	return "TAYA %s • %.1f s" % [identity_text, lagsanay_controller.countdown_remaining]


func _on_item_elimination(record: AttributionRecord) -> bool:
	return (
		phase_controller.phase == MatchPhaseController.Phase.PLAY
		and lagsanay_controller.submit_hazard(record)
	)


func _on_actor_escaped(seat_index: int) -> void:
	if phase_controller.phase != MatchPhaseController.Phase.PLAY or _defect_paused:
		return
	_defect_paused = true
	_defect_reason = (
		"Containment breach by %s; no fall elimination is permitted in Lagsanay."
		% _seat_identity_text(seat_index)
	)
	lagsanay_controller.reset()
	var current_round_number := items.round_number
	items.end_round()
	items.round_number = current_round_number
	pause_coordinator.state = PauseRecoveryCoordinator.State.PAUSED
	pause_coordinator.pause_reason = "Lagsanay containment defect"
	input_router.pause_system()
	input_router.set_phase(LocalInputRouter.Phase.PAUSE)
	get_tree().paused = true
	last_message = _defect_reason
	_update_diagnostics()


func _tag_contacts_snapshot() -> Array[Dictionary]:
	var contacts: Array[Dictionary] = []
	if not lagsanay_controller.active or lagsanay_controller.head_start_remaining > 0.0:
		return contacts
	var taya := actors.get(lagsanay_controller.taya_seat) as ChickenController
	if taya == null or not is_instance_valid(taya):
		return contacts
	if (
		taya.lifecycle.status == PlayerLifecycleState.Status.OPENING_FREEZE
		or taya.lifecycle.is_terminal()
	):
		return contacts
	for node in taya.contact_overlaps():
		if not node is ChickenController:
			continue
		var other := node as ChickenController
		if (
			other.lifecycle.is_terminal()
			or other.lifecycle.status == PlayerLifecycleState.Status.OPENING_FREEZE
		):
			continue
		if not lagsanay_controller.seat_indices.has(other.seat_index):
			continue
		(
			contacts
			. append(
				{
					"seat_index": other.seat_index,
					"distance_squared":
					taya.global_position.distance_squared_to(other.global_position),
				}
			)
		)
	return contacts


func _apply_lagsanay_outcomes(outcomes: Array, last_cluck: bool) -> void:
	var last_cluck_winner := -1
	if last_cluck:
		var provisional := lagsanay_controller.score_result()
		last_cluck_winner = int(provisional.get("last_cluck_seat", -1))
	for outcome in outcomes:
		var seat := int(outcome.get("seat_index", -1))
		var actor := actors.get(seat) as ChickenController
		if actor == null or not is_instance_valid(actor):
			continue
		if last_cluck and seat == last_cluck_winner:
			actor.secure("last_cluck_winner")
		else:
			actor.eliminate(str(outcome.get("cause", "eliminated")))
	if not last_cluck and lagsanay_controller.ended and lagsanay_controller.winner_seat >= 0:
		var winner := actors.get(lagsanay_controller.winner_seat) as ChickenController
		if winner != null:
			winner.secure("lagsanay_winner")


func _finish_lagsanay(last_cluck: bool) -> void:
	if phase_controller.phase != MatchPhaseController.Phase.PLAY:
		return
	var outcome_rows := lagsanay_controller.outcomes()
	var score_result := lagsanay_controller.score_result()
	if not lagsanay_controller.commit_score_once(score_result):
		return
	last_resolution = score_result.duplicate(true)
	for seat in lagsanay_controller.seat_indices:
		cumulative_score_units[seat] = int(score_result.totals_units[seat])
	items.end_round()
	results_ready.clear()
	for seat in input_router.registry.joined_seats():
		var seat_index := int(seat.seat)
		input_router.registry.set_ready(seat_index, false)
		results_ready[seat_index] = false
	last_results_model = MatchResultsViewModel.lag_sanay(
		items.round_number,
		input_router.registry.joined_seats(),
		outcome_rows,
		score_result,
		tuning.lagsanay_opening_head_start_seconds,
		tuning.lagsanay_taya_seconds_2p,
		tuning.lagsanay_taya_seconds_3p,
		tuning.lagsanay_taya_seconds_4p,
		tuning.taya_pass_back_seconds
	)
	_results_panel.show_results(last_results_model)
	phase_controller.enter(MatchPhaseController.Phase.RESULTS, tuning.match_results_advance_seconds)
	_set_input_phase()
	current_context = BoundedStageCamera.Context.PLAY
	last_message = (
		"Lagsanay ended. Construction persists and the explained placement "
		+ "awards are committed."
	)
	_refresh_match_ui()
	if last_cluck:
		_freeze_generation += 1
		_freeze_then_resume(_freeze_generation)


func _freeze_then_resume(generation: int) -> void:
	get_tree().paused = true
	await get_tree().create_timer(tuning.lagsanay_last_cluck_freeze_seconds, true).timeout
	if generation == _freeze_generation and is_inside_tree():
		get_tree().paused = false
		_update_diagnostics()


func _restart_lagsanay_attempt() -> void:
	if not _defect_paused:
		return
	_defect_paused = false
	_defect_reason = ""
	get_tree().paused = false
	pause_coordinator.state = PauseRecoveryCoordinator.State.RUNNING
	pause_coordinator.pause_reason = ""
	input_router.resume_system()
	input_router.set_phase(LocalInputRouter.Phase.PLAY)
	_begin_lagsanay_attempt(true)
	last_message = (
		"Containment defect attempt restarted from its pre-Play score snapshot; "
		+ "construction is unchanged."
	)
	_refresh_match_ui()


func _update_taya_marker() -> void:
	if _taya_marker == null or not is_instance_valid(_taya_marker):
		return
	if not lagsanay_controller.active or phase_controller.phase != MatchPhaseController.Phase.PLAY:
		_taya_marker.visible = false
		return
	var actor := actors.get(lagsanay_controller.taya_seat) as ChickenController
	if actor == null or not is_instance_valid(actor):
		_taya_marker.visible = false
		return
	_taya_marker.text = "★ TAYA • %s" % _seat_identity_text(lagsanay_controller.taya_seat)
	_taya_marker.position = (
		actor.global_position + Vector2(-110.0, -actor.tuning.body_height_wu * 0.65)
	)
	_taya_marker.visible = true


func _update_defect_presentation() -> void:
	if _feedback_label != null and _defect_paused:
		_feedback_label.text = _defect_reason
	if _restart_attempt_button != null:
		_restart_attempt_button.visible = _defect_paused


func _lagsanay_status_text() -> String:
	if _defect_paused:
		return _defect_reason
	var message := (
		"Taya: %s. Passing does not reset the timer. "
		% _seat_identity_text(lagsanay_controller.taya_seat)
	)
	var immune_seats := ""
	for seat in lagsanay_controller.seat_indices:
		var remaining := lagsanay_controller.pass_back_remaining_seconds(int(seat))
		if remaining > 0.0:
			if not immune_seats.is_empty():
				immune_seats += ", "
			immune_seats += "%s %.1f s" % [_seat_identity_text(int(seat)), remaining]
	if not immune_seats.is_empty():
		message += "Pass-back immunity: %s; other contacts stay live. " % immune_seats
	message += "Contact is frozen per physics step; timeout wins an un-timed expiry-step contact."
	return message


func _seat_identity_text(seat_index: int) -> String:
	if input_router == null:
		return "P%d" % (seat_index + 1)
	var seat := input_router.registry.get_seat(seat_index)
	if seat.is_empty():
		return "P%d" % (seat_index + 1)
	return "P%d %s %s" % [int(seat.identity), MARKS.get(str(seat.shape), "◆"), str(seat.shape)]

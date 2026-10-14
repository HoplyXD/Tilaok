class_name P09MatchLifecycleRoom
extends P07FirstPlayableMatchRoom

const P09_BUILD_ID := "P09-match-lifecycle-dev"
const MATCH_RESULT_SCREEN := preload("res://scenes/ui/screens/match_result_screen.tscn")
const CONFIRM_DIALOG := preload("res://scenes/ui/components/confirm_dialog.tscn")

var lifecycle := MatchLifecycleCoordinator.new()
var base_match_seed := 12345
var original_seat_indices: Array[int] = []
var final_results_visible := false
var final_winner_seat := -1
var final_scores_units: Dictionary = {}
var final_outcome_text := ""
var final_last_cluck := false
var final_last_cluck_explanation := ""
var result_menu_owner := -1
var result_action := -1
var result_ready: Dictionary = {}
var lagsanay_controller := LagsanayRoundController.new()

var _result_screen: UiMatchResultScreen
var _taya_marker: Label
var _modal_overlay: Control
var _confirm_dialog: UiConfirmDialog
var _modal_kind := ""
var _modal_owner := -1
var _modal_previous_phase := LocalInputRouter.Phase.LOBBY
var _modal_previous_paused := false
var _sudden_death_active := false
var _sudden_death_match_id := -1
var _sudden_death_round := -1
var _sudden_death_attempt := -1
var _spectator_state: Dictionary = {}


func _init() -> void:
	super()
	match_run_id = 0


func set_match_seed(value: int) -> void:
	base_match_seed = value
	match_seed = value
	super.set_match_seed(value)


func _ready() -> void:
	super._ready()
	process_physics_priority = 300
	if not is_instance_valid(input_router) or not is_instance_valid(_match_canvas):
		return
	var row := _top_bar.get_child(0) as HBoxContainer
	if row != null and row.get_child_count() > 0:
		(row.get_child(0) as Label).text = "TILAOK! • P09 MATCH LIFECYCLE • DEVELOPMENT"
	if goal_area != null:
		goal_area.monitoring = true
		goal_area.collision_mask = 2
		goal_area.visible = true
	_result_screen = MATCH_RESULT_SCREEN.instantiate() as UiMatchResultScreen
	_result_screen.name = "P09LiveMatchResultScreen"
	_result_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_result_screen.visible = false
	_match_canvas.add_child(_result_screen)
	_result_screen.replay_requested.connect(_on_result_replay_requested)
	_result_screen.lobby_requested.connect(_on_result_lobby_requested)
	_result_screen.quit_requested.connect(_on_result_quit_requested)
	_result_screen.menu_selection_changed.connect(_on_result_menu_selection_changed)
	_create_confirmation_overlay()
	_taya_marker = Label.new()
	_taya_marker.name = "P09TayaMarker"
	_taya_marker.add_theme_font_size_override("font_size", 18)
	_taya_marker.add_theme_color_override("font_color", Color("#fff176"))
	_taya_marker.add_theme_color_override("font_outline_color", Color("#17262d"))
	_taya_marker.add_theme_constant_override("outline_size", 5)
	_taya_marker.size = Vector2(220.0, 30.0)
	_taya_marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_taya_marker.visible = false
	world_layer.add_child(_taya_marker)
	input_router.seat_disconnected.connect(_on_result_device_change)
	input_router.device_status_changed.connect(_on_result_device_status_changed)
	if not pause_coordinator.recovery_complete.is_connected(_on_recovery_complete):
		pause_coordinator.recovery_complete.connect(_on_recovery_complete)
	_set_input_phase()
	_update_diagnostics()
	print("P09_MATCH_LIFECYCLE_READY build=%s seed=%d" % [P09_BUILD_ID, base_match_seed])


func _exit_tree() -> void:
	lagsanay_controller.reset()
	if get_tree().paused:
		get_tree().paused = false
	super._exit_tree()


func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_FOCUS_IN]:
		_clear_result_readiness("application focus changed")


func _process(delta: float) -> void:
	super._process(delta)
	_update_taya_marker()
	if final_results_visible:
		_result_screen.visible = true
		_info_panel.visible = false
		_egg_row.visible = false
		_results_panel.visible = false


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if (
		get_tree().paused
		or not _sudden_death_active
		or phase_controller.phase != MatchPhaseController.Phase.PLAY
	):
		return
	_advance_sudden_death_physics(delta)


func start_match() -> bool:
	if phase_controller.phase != MatchPhaseController.Phase.LOBBY:
		return false
	if not LobbyViewModel.can_start(input_router.registry):
		return false
	var next_identity := match_run_id + 1
	match_seed = _derive_match_seed(base_match_seed, next_identity)
	items.director.elimination_sink_exclusive = false
	var started := super.start_match()
	if not started:
		return false
	lifecycle.begin(match_run_id)
	original_seat_indices.clear()
	for seat in input_router.registry.joined_seats():
		original_seat_indices.append(int(seat.seat))
	original_seat_indices.sort()
	final_results_visible = false
	final_winner_seat = -1
	final_scores_units.clear()
	final_outcome_text = ""
	final_last_cluck = false
	final_last_cluck_explanation = ""
	result_menu_owner = -1
	if is_instance_valid(_result_screen):
		_result_screen.owner_seat = -1
	result_action = -1
	result_ready.clear()
	_sudden_death_active = false
	return true


func _finish_race(reason: String) -> void:
	if (
		phase_controller.phase != MatchPhaseController.Phase.PLAY
		or _sudden_death_active
		or race_round_controller == null
		or not race_round_controller.ended
	):
		return
	var active_round := items.round_number + 1
	var outcome_rows := race_round_controller.ledger.outcomes()
	var seat_indices := original_seat_indices.duplicate()
	if seat_indices.size() < 2:
		for seat in input_router.registry.joined_seats():
			seat_indices.append(int(seat.seat))
	var score_result := RaceScoreCalculator.calculate(
		seat_indices, outcome_rows, round_start_score_units
	)
	if not race_round_controller.ledger.commit_score_once(
		race_round_controller.ledger.round_id, score_result
	):
		return
	for seat_index in seat_indices:
		cumulative_score_units[seat_index] = int(score_result.totals_units.get(seat_index, 0))
	items.end_round()
	var decision := lifecycle.finish_round(
		active_round,
		cumulative_score_units,
		tuning.match_target_score_units,
		tuning.match_round_limit
	)
	if int(decision.kind) == MatchLifecycleCoordinator.Decision.INVALID:
		push_error("P09 rejected round termination decision for round %d." % active_round)
		return
	results_ready.clear()
	for seat in input_router.registry.joined_seats():
		input_router.registry.set_ready(int(seat.seat), false)
	if int(decision.kind) == MatchLifecycleCoordinator.Decision.CONTINUE:
		last_results_model = MatchResultsViewModel.race(
			items.round_number,
			input_router.registry.joined_seats(),
			outcome_rows,
			score_result,
			reason,
			race_round_controller.hard_cap_seconds,
			race_round_controller.post_first_finish_seconds
		)
		_results_panel.show_results(last_results_model)
		phase_controller.enter(
			MatchPhaseController.Phase.RESULTS, tuning.match_results_advance_seconds
		)
		_set_input_phase()
		current_context = BoundedStageCamera.Context.PLAY
		last_message = "Karera round %d complete. Match continues." % active_round
		_refresh_match_ui()
		return
	if int(decision.kind) == MatchLifecycleCoordinator.Decision.WINNER:
		_show_final_results(int(decision.winner_seat), false, _terminal_text(str(decision.reason)))
		return
	_start_sudden_death(decision)


func _start_sudden_death(decision: Dictionary) -> void:
	_sudden_death_match_id = int(decision.match_id)
	_sudden_death_round = int(decision.completed_round)
	_sudden_death_attempt = int(decision.attempt)
	_sudden_death_active = true
	race_round_controller = null
	race_candidate_queue.reset()
	_reset_actors_for_round()
	start_play()
	phase_controller.enter(MatchPhaseController.Phase.PLAY)
	_set_input_phase()
	current_context = BoundedStageCamera.Context.PLAY
	camera_rig.set_context(current_context)
	var participants: Array[int] = decision.tied_seats.duplicate()
	_round_start_score_snapshot(participants)
	var sd_id := (
		"%d:%d:p09-sudden-death:%d"
		% [_sudden_death_match_id, _sudden_death_round, _sudden_death_attempt]
	)
	if not lagsanay_controller.begin(
		sd_id,
		participants,
		cumulative_score_units,
		match_streams.taya,
		tuning.lagsanay_opening_head_start_seconds,
		tuning.taya_pass_back_seconds,
		tuning.lagsanay_taya_seconds_2p,
		tuning.lagsanay_taya_seconds_3p,
		tuning.lagsanay_taya_seconds_4p
	):
		_sudden_death_active = false
		push_error("P09 could not initialize Lagsanay sudden death.")
		return
	items.director.active_round_id = sd_id
	items.director.elimination_sink_exclusive = true
	_apply_sudden_death_roster(participants)
	last_message = "Sudden death! The tied leaders enter Lagsanay on the persistent stage."
	_update_diagnostics()
	_refresh_match_ui()


func _round_start_score_snapshot(participants: Array[int]) -> void:
	round_start_score_units.clear()
	for seat_index in participants:
		round_start_score_units[seat_index] = int(cumulative_score_units.get(seat_index, 0))


func _apply_sudden_death_roster(participants: Array[int]) -> void:
	_spectator_state.clear()
	for seat_index in original_seat_indices:
		var actor := actors.get(seat_index) as ChickenController
		if actor == null or not is_instance_valid(actor):
			continue
		if participants.has(seat_index):
			actor.set_opening_freeze(seat_index == lagsanay_controller.opening_taya_seat)
			continue
		_spectator_state[seat_index] = {
			"collision_layer": actor.collision_layer,
			"collision_mask": actor.collision_mask,
			"visible": actor.visible,
			"physics_process": actor.is_physics_processing(),
		}
		actor.secure("sudden_death_spectator")
		actor.collision_layer = 0
		actor.collision_mask = 0
		actor.visible = false
		actor.set_physics_process(false)
	if goal_area != null:
		goal_area.monitoring = false
		goal_area.collision_mask = 0
		goal_area.visible = false
	for child in world_layer.get_children():
		if child is Label and (child as Label).text == "KARERA GOAL":
			(child as Label).visible = false
		elif child is Line2D and (child as Line2D).name == "FlagTriggerOutline":
			(child as Line2D).visible = false


func _advance_sudden_death_physics(delta: float) -> void:
	var contacts := _sudden_death_tag_contacts()
	var result := lagsanay_controller.advance_step(
		delta, Engine.get_physics_frames(), contacts, actors
	)
	if bool(result.head_start_ended):
		var opening_actor := actors.get(lagsanay_controller.opening_taya_seat) as ChickenController
		if opening_actor != null:
			opening_actor.set_opening_freeze(false)
	_apply_sudden_death_outcomes(result.new_outcomes, bool(result.last_cluck))
	_update_taya_marker()
	_update_camera_targets()
	if bool(result.ended):
		_finish_sudden_death(
			_sudden_death_match_id,
			_sudden_death_round,
			_sudden_death_attempt,
			bool(result.last_cluck)
		)
	else:
		_update_diagnostics()


func _sudden_death_tag_contacts() -> Array[Dictionary]:
	var contacts: Array[Dictionary] = []
	if not lagsanay_controller.active or lagsanay_controller.head_start_remaining > 0.0:
		return contacts
	var taya := actors.get(lagsanay_controller.taya_seat) as ChickenController
	if taya == null or not is_instance_valid(taya) or taya.lifecycle.is_terminal():
		return contacts
	for node in taya.contact_overlaps():
		if not node is ChickenController:
			continue
		var other := node as ChickenController
		if (
			other.lifecycle.is_terminal()
			or other.lifecycle.status == PlayerLifecycleState.Status.OPENING_FREEZE
			or not lifecycle.tied_seats.has(other.seat_index)
		):
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


func _apply_sudden_death_outcomes(outcomes: Array, last_cluck: bool) -> void:
	var final_record := lagsanay_controller.sudden_death_winner() if last_cluck else {}
	var cluck_winner := int(final_record.get("winner_seat", -1))
	for outcome in outcomes:
		var seat_index := int(outcome.get("seat_index", -1))
		var actor := actors.get(seat_index) as ChickenController
		if actor == null or not is_instance_valid(actor):
			continue
		if last_cluck and seat_index == cluck_winner:
			actor.secure("last_cluck_winner")
		else:
			actor.eliminate(str(outcome.get("cause", "eliminated")))
	if not last_cluck and lagsanay_controller.ended and lagsanay_controller.winner_seat >= 0:
		var winner := actors.get(lagsanay_controller.winner_seat) as ChickenController
		if winner != null:
			winner.secure("sudden_death_winner")


func _finish_sudden_death(
	callback_match_id: int, callback_round: int, callback_attempt: int, last_cluck: bool
) -> void:
	if not lifecycle.callback_is_current(callback_match_id, callback_round, callback_attempt):
		return
	if not _sudden_death_active or not lagsanay_controller.ended:
		return
	var result := lagsanay_controller.sudden_death_winner()
	var winner := int(result.get("winner_seat", -1))
	if not bool(result.get("valid", false)):
		push_error("P09 Lagsanay ended without a valid authoritative winner.")
		return
	if not lifecycle.resolve_sudden_death(
		callback_match_id, callback_round, callback_attempt, winner
	):
		return
	_sudden_death_active = false
	items.end_play_attempt()
	final_last_cluck = last_cluck
	final_last_cluck_explanation = str(result.get("explanation", ""))
	final_outcome_text = (
		"Tied leaders played Lagsanay sudden death. %s wins." % _seat_identity_text(winner)
	)
	if last_cluck:
		final_outcome_text = "Tied leaders played Lagsanay sudden death. Last Cluck decides the winner."
	_show_final_results(winner, last_cluck, final_outcome_text)


func _show_final_results(winner_seat: int, last_cluck: bool, outcome_text: String) -> void:
	final_results_visible = true
	final_winner_seat = winner_seat
	final_scores_units = cumulative_score_units.duplicate(true)
	final_outcome_text = outcome_text
	final_last_cluck = last_cluck
	result_menu_owner = -1
	result_action = -1
	result_ready.clear()
	for seat in input_router.registry.joined_seats():
		input_router.registry.set_ready(int(seat.seat), false)
	phase_controller.enter(MatchPhaseController.Phase.RESULTS)
	_set_input_phase()
	var seats: Array[Dictionary] = []
	for seat_index in PlayerSeatRegistry.MAX_SEATS:
		seats.append(input_router.registry.get_seat(seat_index))
	last_results_model = MatchResultsViewModel.final_match(
		seats,
		final_scores_units,
		winner_seat,
		outcome_text,
		lifecycle.sudden_death_attempt > 0,
		final_last_cluck_explanation
	)
	_result_screen.bind_final_match(last_results_model)
	_result_screen.visible = true
	_results_panel.visible = false
	last_message = outcome_text
	_update_diagnostics()


func _start_next_round() -> void:
	if final_results_visible:
		return
	super._start_next_round()


func _on_match_navigation_step(seat_index: int, direction: String) -> void:
	if _confirm_dialog != null and _confirm_dialog.is_open():
		if _claim_modal_owner(seat_index):
			_confirm_dialog.navigate(direction)
		return
	if final_results_visible:
		if result_menu_owner < 0:
			result_menu_owner = seat_index
			_result_screen.owner_seat = seat_index
		if seat_index != result_menu_owner:
			return
		_result_screen.move_action(direction)
		return
	super._on_match_navigation_step(seat_index, direction)


func _on_match_action_pressed(seat_index: int, action_name: String) -> void:
	if _confirm_dialog != null and _confirm_dialog.is_open():
		_handle_modal_action(seat_index, action_name)
		return
	if final_results_visible:
		_handle_final_results_action(seat_index, action_name)
		return
	if action_name == "back" and phase_controller.phase != MatchPhaseController.Phase.LOBBY:
		_open_confirmation("leave", seat_index)
		return
	if _sudden_death_active and seat_index >= 0 and action_name in ["claim", "confirm", "rotate"]:
		return
	super._on_match_action_pressed(seat_index, action_name)


func _handle_modal_action(seat_index: int, action_name: String) -> void:
	if action_name == "back" and (seat_index == _modal_owner or _modal_owner < 0):
		_cancel_confirmation()
	elif action_name == "confirm" or action_name == "ready":
		if _claim_modal_owner(seat_index):
			_confirm_dialog.accept()


func _handle_final_results_action(seat_index: int, action_name: String) -> void:
	if seat_index < 0:
		return
	if action_name == "back":
		_open_confirmation("leave", seat_index)
	elif action_name == "confirm" or action_name == "ready":
		if result_menu_owner < 0:
			result_menu_owner = seat_index
			_result_screen.owner_seat = seat_index
			_result_screen.activate_action()
		_set_result_ready(seat_index)
	else:
		super._on_match_action_pressed(seat_index, action_name)


func request_return() -> void:
	if phase_controller.phase == MatchPhaseController.Phase.LOBBY:
		super.request_return()
		return
	_open_confirmation("leave", -1)


func _on_result_menu_selection_changed(index: int) -> void:
	if result_action == index:
		return
	_clear_result_readiness("selected action changed", true)
	result_action = index


func _on_result_replay_requested() -> void:
	_select_result_action(0)


func _on_result_lobby_requested() -> void:
	_select_result_action(1)


func _on_result_quit_requested() -> void:
	_select_result_action(2)


func _select_result_action(index: int) -> void:
	if result_action != index:
		_clear_result_readiness("selected action changed", true)
		result_action = index
	if result_menu_owner >= 0:
		_set_result_ready(result_menu_owner)
	_try_commit_result_action()


func _set_result_ready(seat_index: int) -> void:
	if not original_seat_indices.has(seat_index):
		return
	var seat := input_router.registry.get_seat(seat_index)
	if (
		seat.is_empty()
		or not bool(seat.get("joined", false))
		or not bool(seat.get("connected", false))
	):
		return
	result_ready[seat_index] = true
	input_router.registry.set_ready(seat_index, true)
	_try_commit_result_action()


func _try_commit_result_action() -> void:
	if not final_results_visible or result_action < 0 or original_seat_indices.is_empty():
		return
	for seat_index in original_seat_indices:
		var seat := input_router.registry.get_seat(seat_index)
		if (
			seat.is_empty()
			or not bool(seat.get("joined", false))
			or not bool(seat.get("connected", false))
			or not bool(result_ready.get(seat_index, false))
		):
			return
	match result_action:
		0:
			_replay_match()
		1:
			_return_group_to_lobby()
		2:
			_open_confirmation("quit", result_menu_owner)


func _replay_match() -> void:
	var joined := input_router.registry.joined_seats()
	if joined.size() != original_seat_indices.size():
		_clear_result_readiness("seat roster changed")
		return
	reset_room()
	for seat_index in original_seat_indices:
		input_router.registry.set_ready(seat_index, true)
	if not start_match():
		push_error("P09 Replay could not start from the ready original seat roster.")


func _return_group_to_lobby() -> void:
	reset_room()
	for seat in input_router.registry.joined_seats():
		input_router.registry.set_ready(int(seat.seat), false)
	final_results_visible = false
	_result_screen.visible = false
	phase_controller.enter(MatchPhaseController.Phase.LOBBY)
	_set_input_phase()
	last_message = "The full group returned to the lobby. All original seats remain joined."
	_refresh_match_ui()


func _clear_result_readiness(reason: String, preserve_menu: bool = false) -> void:
	if not _modal_kind.is_empty() and _confirm_dialog != null and _confirm_dialog.is_open():
		_cancel_confirmation()
	if final_results_visible:
		result_ready.clear()
		if not preserve_menu:
			result_action = -1
		for seat_index in original_seat_indices:
			input_router.registry.set_ready(seat_index, false)
	if result_menu_owner >= 0 and not preserve_menu:
		result_menu_owner = -1
		if is_instance_valid(_result_screen):
			_result_screen.owner_seat = -1
	last_message = "Result action readiness cleared: %s." % reason


func _on_result_device_change(_seat_index: int) -> void:
	_clear_result_readiness("assigned device disconnected")


func _on_result_device_status_changed(_device_id: int, _connected: bool) -> void:
	_clear_result_readiness("device status changed")


func _on_recovery_complete() -> void:
	_clear_result_readiness("device recovery completed")
	if not _modal_kind.is_empty():
		_modal_previous_phase = LocalInputRouter.Phase.RESULTS
		_modal_previous_paused = false
		input_router.set_phase(LocalInputRouter.Phase.RESULTS)


func _create_confirmation_overlay() -> void:
	_modal_overlay = Control.new()
	_modal_overlay.name = "P09ConfirmationOverlay"
	_modal_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_modal_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	_modal_overlay.visible = false
	_match_canvas.add_child(_modal_overlay)
	var dimmer := ColorRect.new()
	dimmer.color = Color(0.02, 0.05, 0.07, 0.78)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	_modal_overlay.add_child(dimmer)
	_confirm_dialog = CONFIRM_DIALOG.instantiate() as UiConfirmDialog
	_confirm_dialog.name = "P09ConfirmDialog"
	_confirm_dialog.set_anchors_preset(Control.PRESET_CENTER)
	_confirm_dialog.position = Vector2(-210.0, -70.0)
	_confirm_dialog.process_mode = Node.PROCESS_MODE_ALWAYS
	_modal_overlay.add_child(_confirm_dialog)
	_confirm_dialog.confirmed.connect(_on_confirmation_confirmed)
	_confirm_dialog.cancelled.connect(_on_confirmation_cancelled)


func _open_confirmation(kind: String, owner: int) -> void:
	if not _modal_kind.is_empty():
		return
	_modal_kind = kind
	_modal_owner = owner
	_modal_previous_phase = input_router.phase
	_modal_previous_paused = get_tree().paused
	if final_results_visible:
		result_ready.clear()
		for seat_index in original_seat_indices:
			input_router.registry.set_ready(seat_index, false)
	_modal_overlay.visible = true
	_confirm_dialog.open(
		(
			"Quit Tilaok!?"
			if kind == "quit"
			else "Leave this match and return the whole group to the lobby?"
		)
	)
	input_router.set_phase(LocalInputRouter.Phase.RESULTS)
	get_tree().paused = true


func _claim_modal_owner(seat_index: int) -> bool:
	if seat_index < 0:
		return false
	if _modal_owner < 0:
		_modal_owner = seat_index
		return false
	return _modal_owner == seat_index


func _cancel_confirmation() -> void:
	if _confirm_dialog != null and _confirm_dialog.is_open():
		_confirm_dialog.cancel()


func _on_confirmation_cancelled() -> void:
	_finish_confirmation(false)


func _on_confirmation_confirmed() -> void:
	_finish_confirmation(true)


func _finish_confirmation(confirmed: bool) -> void:
	var kind := _modal_kind
	var previous_phase := _modal_previous_phase
	var was_paused := _modal_previous_paused
	_modal_kind = ""
	_modal_owner = -1
	_modal_overlay.visible = false
	input_router.set_phase(previous_phase)
	get_tree().paused = was_paused
	if not confirmed:
		if final_results_visible:
			result_action = -1
			_clear_result_readiness("confirmation cancelled")
		return
	if kind == "quit":
		get_tree().quit()
	elif kind == "leave":
		_return_group_to_lobby()


func _terminal_text(reason: String) -> String:
	if reason == "score_target":
		return (
			"First to %s points. The score target ended the match."
			% ScoreFormat.format_units(tuning.match_target_score_units)
		)
	return "Highest score after round %d ended the match." % tuning.match_round_limit


func _derive_match_seed(base_seed: int, identity: int) -> int:
	var mixed := int((base_seed * 1103515245 + identity * 12345 + 1013904223) & 0x7fffffff)
	return mixed if mixed != 0 else 1


func _update_taya_marker() -> void:
	if _taya_marker == null or not is_instance_valid(_taya_marker):
		return
	if not _sudden_death_active or not lagsanay_controller.active:
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


func _on_item_elimination(record: AttributionRecord) -> bool:
	if _sudden_death_active:
		return lagsanay_controller.submit_hazard(record)
	return super._on_item_elimination(record)


func _seat_identity_text(seat_index: int) -> String:
	var seat := input_router.registry.get_seat(seat_index)
	return (
		"P%d %s %s"
		% [
			int(seat.get("identity", seat_index + 1)),
			MARKS.get(str(seat.get("shape", "")), "◆"),
			str(seat.get("shape", "")),
		]
	)


func _update_diagnostics() -> void:
	super._update_diagnostics()
	if _result_screen != null and is_instance_valid(_result_screen):
		_result_screen.visible = final_results_visible
	if final_results_visible and _info_panel != null:
		_info_panel.visible = false
		_egg_row.visible = false
		_results_panel.visible = false
	if _taya_marker != null:
		_taya_marker.visible = _sudden_death_active and lagsanay_controller.active


func reset_room() -> void:
	var saved_spectators := _spectator_state.duplicate(true)
	_sudden_death_active = false
	lagsanay_controller.reset()
	final_results_visible = false
	final_winner_seat = -1
	final_scores_units.clear()
	result_menu_owner = -1
	result_action = -1
	result_ready.clear()
	_modal_kind = ""
	_modal_owner = -1
	if _modal_overlay != null and is_instance_valid(_modal_overlay):
		_modal_overlay.visible = false
	if _result_screen != null and is_instance_valid(_result_screen):
		_result_screen.visible = false
	super.reset_room()
	if items != null and items.director != null:
		items.director.elimination_sink_exclusive = false
		items.director.active_round_id = ""
	_spectator_state.clear()
	if goal_area != null:
		goal_area.monitoring = true
		goal_area.collision_mask = 2
		goal_area.visible = true
	for seat_index in actors:
		var actor := actors[seat_index] as ChickenController
		if actor == null or not is_instance_valid(actor):
			continue
		var saved: Dictionary = saved_spectators.get(int(seat_index), {})
		if not saved.is_empty():
			actor.collision_layer = int(saved.collision_layer)
			actor.collision_mask = int(saved.collision_mask)
			actor.visible = bool(saved.visible)
			actor.set_physics_process(bool(saved.physics_process))
	for child in world_layer.get_children():
		if child is Label and (child as Label).text == "KARERA GOAL":
			(child as Label).visible = true
		elif child is Line2D and (child as Line2D).name == "FlagTriggerOutline":
			(child as Line2D).visible = true
	if _taya_marker != null:
		_taya_marker.visible = false

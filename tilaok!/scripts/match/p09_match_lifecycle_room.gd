class_name P09MatchLifecycleRoom
extends P07FirstPlayableMatchRoom

const P09_BUILD_ID := "P09-match-lifecycle-dev"

## NLB-P09: a committed ledger entry (round result, sudden-death entry/result, final result).
signal result_committed(entry: Dictionary)

## The host's committed result ledger for this match (integer units and enums only).
var result_ledger := ResultLedger.new()
## NLB-P09: set by the network session on bind. Offline rooms never set any of the three, so the
## offline replay, lobby and results behavior is unchanged.
var network_mode := false
var network_host_commands := false
## Returns true when the session re-keyed and the room may reset and start the next match.
var network_replay_handler := Callable()
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
var _last_taya_seat := -1
var _spectator_state: Dictionary = {}
var _pending_round_record: Dictionary = {}


func _init() -> void:
	super()
	match_run_id = 0
	result_ledger.committed.connect(_on_result_ledger_committed)


func set_match_seed(value: int) -> void:
	base_match_seed = value
	match_seed = value
	super.set_match_seed(value)


func _ready() -> void:
	super._ready()
	lifecycle.authority = simulation_authority
	lagsanay_controller.authority = simulation_authority
	process_physics_priority = 300
	if not is_instance_valid(input_router) or presenter == null:
		return
	if goal_area != null:
		goal_area.monitoring = true
		goal_area.collision_mask = 2
		goal_area.visible = true
	# The match-result screen and the confirmation dialog are authored in match_hud.tscn and
	# shown by the presenter; the room only binds data and decides what the buttons do.
	_result_screen = presenter.match_result_screen
	_result_screen.visible = false
	_result_screen.replay_requested.connect(_on_result_replay_requested)
	_result_screen.lobby_requested.connect(_on_result_lobby_requested)
	_result_screen.quit_requested.connect(_on_result_quit_requested)
	_result_screen.menu_selection_changed.connect(_on_result_menu_selection_changed)
	_modal_overlay = presenter.confirm_overlay
	_confirm_dialog = presenter.confirm_dialog
	_modal_overlay.visible = false
	_confirm_dialog.confirmed.connect(_on_confirmation_confirmed)
	_confirm_dialog.cancelled.connect(_on_confirmation_cancelled)
	_taya_marker = _create_taya_marker("P09TayaMarker")
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
	if not _simulation_can_commit():
		return
	super._process(delta)
	_update_taya_marker()


func _physics_process(delta: float) -> void:
	if not _simulation_can_commit():
		return
	super._physics_process(delta)
	if (
		get_tree().paused
		or not _sudden_death_active
		or phase_controller.phase != MatchPhaseController.Phase.PLAY
	):
		return
	_advance_sudden_death_physics(delta)


func start_match() -> bool:
	if not _simulation_can_commit() or phase_controller.phase != MatchPhaseController.Phase.LOBBY:
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
	result_ledger.reset(match_run_id)
	_pending_round_record.clear()
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
	if not _simulation_can_commit():
		return
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
		seat_indices, outcome_rows, round_start_score_units, _race_score_coin_seats()
	)
	if not race_round_controller.ledger.commit_score_once(
		race_round_controller.ledger.round_id, score_result
	):
		return
	_stage_round_record(NetworkResultsCodec.ScoringFamily.RACE, score_result, outcome_rows)
	_record_score_presentation(active_round, score_result)
	_after_race_score_committed(score_result)
	for seat_index in seat_indices:
		cumulative_score_units[seat_index] = int(score_result.totals_units.get(seat_index, 0))
	items.end_round()
	var model := MatchResultsViewModel.race(
		items.round_number,
		input_router.registry.joined_seats(),
		outcome_rows,
		score_result,
		reason,
		race_round_controller.hard_cap_seconds,
		race_round_controller.post_first_finish_seconds
	)
	_conclude_round(
		active_round, model, "Karera round %d complete. Match continues." % active_round
	)


## Ends a scored round through the match lifecycle: the round's Results then the next Pugad, the
## final match screen, or sudden death. Scores are already committed and `items.end_round()` has
## run; `continue_model` is the round's own result model (race, Lagsanay or Kangaroo).
func _conclude_round(
	active_round: int, continue_model: MatchResultsViewModel, continue_message: String
) -> void:
	if not _simulation_can_commit():
		return
	var decision := lifecycle.finish_round(
		active_round,
		cumulative_score_units,
		tuning.match_target_score_units,
		tuning.match_round_limit
	)
	if int(decision.kind) == MatchLifecycleCoordinator.Decision.INVALID:
		push_error("P09 rejected round termination decision for round %d." % active_round)
		return
	_commit_round_record(active_round, decision)
	results_ready.clear()
	for seat in input_router.registry.joined_seats():
		input_router.registry.set_ready(int(seat.seat), false)
	if int(decision.kind) == MatchLifecycleCoordinator.Decision.CONTINUE:
		last_results_model = continue_model
		_bind_score_presentation(last_results_model, active_round)
		phase_controller.enter(
			MatchPhaseController.Phase.RESULTS, tuning.match_results_advance_seconds
		)
		_set_input_phase()
		current_context = BoundedStageCamera.Context.PLAY
		last_message = continue_message
		_refresh_match_ui()
		return
	if int(decision.kind) == MatchLifecycleCoordinator.Decision.WINNER:
		_show_final_results(int(decision.winner_seat), false, _terminal_text(str(decision.reason)))
		return
	_start_sudden_death(decision)


## NLB-P09: keeps the calculator result until the lifecycle decision for the round is known.
func _stage_round_record(family: int, score_result: Dictionary, outcome_rows: Array) -> void:
	_pending_round_record = {
		"family": family,
		"score_result": score_result.duplicate(true),
		"outcome_rows": outcome_rows.duplicate(true),
	}


func _commit_round_record(active_round: int, decision: Dictionary) -> void:
	if _pending_round_record.is_empty():
		return
	var staged := _pending_round_record
	_pending_round_record = {}
	if result_ledger.commit_round(
		active_round,
		_ledger_attempt(),
		int(staged.family),
		staged.score_result,
		staged.outcome_rows,
		decision
	).is_empty():
		push_error("P09 could not commit the round %d result ledger entry." % active_round)


## The wire attempt id: the same match-run discriminator the network metadata already carries.
func _ledger_attempt() -> int:
	return match_run_id & 0xffff


func _on_result_ledger_committed(entry: Dictionary) -> void:
	result_committed.emit(entry)


func _start_sudden_death(decision: Dictionary) -> void:
	if not _simulation_can_commit():
		return
	_sudden_death_match_id = int(decision.match_id)
	_sudden_death_round = int(decision.completed_round)
	_sudden_death_attempt = int(decision.attempt)
	_sudden_death_active = true
	_last_taya_seat = -1
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
	# Entry only: sudden death commits no score delta (the totals are frozen at the tie).
	result_ledger.commit_sudden_death_entry(
		_sudden_death_round,
		_ledger_attempt(),
		_sudden_death_attempt,
		participants,
		cumulative_score_units,
		ResultLedger.terminal_code(lifecycle.terminal_reason)
	)
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
	if not _simulation_can_commit():
		return
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
	elif lagsanay_controller.taya_seat != _last_taya_seat:
		# The clock re-renders on whole seconds; only a pass needs an immediate refresh.
		_last_taya_seat = lagsanay_controller.taya_seat
		_notify_presentation(&"taya")


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
	if not _simulation_can_commit():
		return
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
	result_ledger.commit_sudden_death_result(
		_sudden_death_round, _ledger_attempt(), _sudden_death_attempt, winner, last_cluck
	)
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
	result_ledger.commit_final(
		lifecycle.completed_round,
		_ledger_attempt(),
		winner_seat,
		last_cluck,
		lifecycle.sudden_death_attempt > 0,
		ResultLedger.terminal_code(lifecycle.terminal_reason),
		final_scores_units
	)
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
	var reveal_round := items.round_number if lifecycle.sudden_death_attempt <= 0 else -1
	_bind_score_presentation(
		last_results_model,
		reveal_round,
		"final:%d:%d:%d" % [match_run_id, winner_seat, lifecycle.sudden_death_attempt]
	)
	_result_screen.bind_final_match(last_results_model, presentation_settings.result_reveal_motion)
	_result_screen.visible = true
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


## Back from the Lobby clears the whole session, so ask first once any seat has readied up.
func confirm_lobby_exit(seat_index: int) -> bool:
	if phase_controller.phase != MatchPhaseController.Phase.LOBBY or not _modal_kind.is_empty():
		return false
	for seat in input_router.registry.joined_seats():
		if bool(seat.get("ready", false)):
			_open_confirmation("title", seat_index)
			return true
	return false


func is_confirmation_open() -> bool:
	return not _modal_kind.is_empty()


func _on_result_menu_selection_changed(index: int) -> void:
	if result_action == index:
		return
	_clear_result_readiness("selected action changed", true)
	result_action = index


func _on_result_replay_requested() -> void:
	if network_host_commands:
		_commit_result_action_now(0)
		return
	_select_result_action(0)


func _on_result_lobby_requested() -> void:
	if network_host_commands:
		_commit_result_action_now(1)
		return
	_select_result_action(1)


func _on_result_quit_requested() -> void:
	if network_host_commands:
		_commit_result_action_now(2)
		return
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
		if network_exempt_unconnected_seats and not bool(seat.get("connected", true)):
			continue
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


## A match that ran on a non-default stage (the guided tutorial match) never carries that stage
## into the next match: the owner builds a fresh room instead of resetting this one.
func _hands_back_for_fresh_stage(kind: StringName) -> bool:
	if flow_requested.get_connections().is_empty():
		return false
	# NLB-P09: Return to Lobby on a network match tears the session down, so the owner always
	# decides it (spec 3.3); the offline default-stage lobby return stays in the room.
	if network_mode and kind == &"leave_match":
		flow_requested.emit(kind)
		return true
	if arena == null or arena.layout_id == ArenaDefinition.DEFAULT_LAYOUT_ID:
		return false
	flow_requested.emit(kind)
	return true


## NLB-P09: the network replay roster. Lost remote seats (reserved for 60 s or expired) are released
## so they cannot block or join the next match; a lost local device keeps blocking the replay.
## Returns the number of connected original seats that remain, or 0 when a local device is lost.
func network_prepare_replay_roster() -> int:
	var kept: Array[int] = []
	var dropped: Array[int] = []
	for seat_index in original_seat_indices:
		var seat := input_router.registry.get_seat(seat_index)
		if seat.is_empty() or not bool(seat.get("joined", false)):
			continue
		if bool(seat.get("connected", false)):
			kept.append(seat_index)
		elif str(seat.get("device_kind", "")) == "remote":
			dropped.append(seat_index)
		else:
			return 0
	if kept.size() < 2:
		return kept.size()
	for seat_index in dropped:
		input_router.registry.release_unconnected_remote_seat(seat_index, simulation_authority)
	original_seat_indices = kept
	return kept.size()


## NLB-P09: the result vote as the phones see it. `action` is a NetworkResultsCodec.ResultAction
## value, or -1 when no action is selected (or Quit is selected, which no phone can vote on).
func network_vote_state() -> Dictionary:
	var required := 0
	var ready := 0
	for seat_index in original_seat_indices:
		var seat := input_router.registry.get_seat(seat_index)
		if network_exempt_unconnected_seats and not bool(seat.get("connected", true)):
			continue
		required |= 1 << seat_index
		var voted := (
			bool(result_ready.get(seat_index, false))
			if final_results_visible
			else bool(results_ready.get(seat_index, false))
		)
		if voted:
			ready |= 1 << seat_index
	var action := -1
	if final_results_visible:
		if result_action == 0:
			action = NetworkResultsCodec.ResultAction.VOTE_REPLAY
		elif result_action == 1:
			action = NetworkResultsCodec.ResultAction.VOTE_LOBBY
	elif phase_controller.phase == MatchPhaseController.Phase.RESULTS:
		action = NetworkResultsCodec.ResultAction.CONTINUE
	var latest := result_ledger.latest()
	return {
		"action": action,
		"ready_mask": ready,
		"required_mask": required,
		"event_id": int(latest.get("event_id", 0)),
		"round_id": int(latest.get("round_id", 0)),
	}


## NLB-P09: a phone's result action. The session has already tied it to the peer's authenticated
## seat; this applies the same rules the offline menu uses (changing the selected action clears
## everyone's readiness; every connected original seat must agree before the host commits).
func network_result_vote(seat_index: int, action: int) -> bool:
	if not _simulation_can_commit() or not original_seat_indices.has(seat_index):
		return false
	if _confirm_dialog != null and _confirm_dialog.is_open():
		return false
	if action == NetworkResultsCodec.ResultAction.CONTINUE:
		if final_results_visible or phase_controller.phase != MatchPhaseController.Phase.RESULTS:
			return false
		results_ready[seat_index] = true
		last_message = "P%d is ready for the next round." % (seat_index + 1)
		_refresh_match_ui()
		if _all_results_ready():
			_start_next_round()
		return true
	if not final_results_visible:
		return false
	var index := 0 if action == NetworkResultsCodec.ResultAction.VOTE_REPLAY else 1
	if result_action != index:
		_clear_result_readiness("selected action changed", true)
		result_action = index
	_set_result_ready(seat_index)
	return true


## NLB-P09: a host-local click on the result planks commits at once by host authority, because a
## spectator host has no seat to ready up with. Quit still asks first.
func _commit_result_action_now(index: int) -> void:
	if not final_results_visible:
		return
	result_action = index
	match index:
		0:
			_replay_match()
		1:
			_return_group_to_lobby()
		2:
			_open_confirmation("quit", -1)


## NLB-P09: a seat the final results were waiting on may have just been reserved.
func network_recheck_results() -> void:
	super.network_recheck_results()
	if network_exempt_unconnected_seats and _simulation_can_commit() and final_results_visible:
		_try_commit_result_action()


func _replay_match() -> void:
	if network_mode and network_replay_handler.is_valid():
		if not bool(network_replay_handler.call()):
			_clear_result_readiness("replay unavailable")
			last_message = "Replay needs two connected players. Return to the lobby instead."
			_refresh_match_ui()
			return
		reset_room()
		for seat_index in original_seat_indices:
			input_router.registry.set_ready(seat_index, true)
		if not start_match():
			push_error("P09 network Replay could not start from the connected roster.")
		return
	var joined := input_router.registry.joined_seats()
	if joined.size() != original_seat_indices.size():
		_clear_result_readiness("seat roster changed")
		return
	if _hands_back_for_fresh_stage(&"replay_match"):
		return
	reset_room()
	for seat_index in original_seat_indices:
		input_router.registry.set_ready(seat_index, true)
	if not start_match():
		push_error("P09 Replay could not start from the ready original seat roster.")


func _return_group_to_lobby() -> void:
	if _hands_back_for_fresh_stage(&"leave_match"):
		return
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
	_confirm_dialog.open(_confirmation_text(kind))
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
		_request_quit()
	elif kind == "leave":
		_return_group_to_lobby()
	elif kind == "title":
		if flow_requested.get_connections().is_empty():
			request_return()
		else:
			flow_requested.emit(&"lobby_back")


func _confirmation_text(kind: String) -> String:
	match kind:
		"quit":
			return "Quit Tilaok!?"
		"title":
			return "Return to the title? Everyone will need to join again."
	return "Leave this match and return the whole group to the lobby?"


## The owner (GameFlow) decides what Quit means: leave the app, or return to the harness that
## hosts the flow. A room with no owner listening exits the app itself.
func _request_quit() -> void:
	if flow_requested.get_connections().is_empty():
		get_tree().quit()
	else:
		flow_requested.emit(&"quit")


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


func build_id() -> String:
	return P09_BUILD_ID


func shows_final_results() -> bool:
	return final_results_visible


func play_clock_seconds() -> float:
	if _sudden_death_active and lagsanay_controller.active:
		if lagsanay_controller.head_start_remaining > 0.0:
			return lagsanay_controller.head_start_remaining
		return lagsanay_controller.countdown_remaining
	return super.play_clock_seconds()


func play_challenge_text() -> String:
	return "Sudden death • Lagsanay" if _sudden_death_active else super.play_challenge_text()


func play_goal_text() -> String:
	return "Touch to pass the taya!" if _sudden_death_active else super.play_goal_text()


func play_tag_text() -> String:
	if _sudden_death_active and lagsanay_controller.active:
		var prefix := "HEAD START • " if lagsanay_controller.head_start_remaining > 0.0 else ""
		return "%sTAYA %s" % [prefix, _seat_identity_text(lagsanay_controller.taya_seat)]
	return super.play_tag_text()


func play_status_text() -> String:
	if _sudden_death_active:
		return "Sudden death: the tied leaders play Lagsanay; the last chicken standing wins."
	return super.play_status_text()


func seat_state_text(seat_index: int) -> String:
	if not _sudden_death_active:
		return super.seat_state_text(seat_index)
	if _spectator_state.has(seat_index):
		return "WATCHING"
	if lagsanay_controller.active and seat_index == lagsanay_controller.taya_seat:
		return "TAYA"
	return ""


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
	if _taya_marker != null:
		_taya_marker.visible = _sudden_death_active and lagsanay_controller.active


func reset_room() -> void:
	if not _simulation_can_commit():
		return
	var saved_spectators := _spectator_state.duplicate(true)
	_sudden_death_active = false
	_last_taya_seat = -1
	lagsanay_controller.reset()
	final_results_visible = false
	final_winner_seat = -1
	final_scores_units.clear()
	result_menu_owner = -1
	result_action = -1
	result_ready.clear()
	result_ledger.reset(0)
	_pending_round_record.clear()
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

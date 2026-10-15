class_name P12ScheduledMatchRoom
extends P09MatchLifecycleRoom

## P12-T01: the full match with the event schedule. Each round's Main Challenge (and any Twist)
## comes from EventSchedule, is locked during the preceding Pugad and is announced there. Karera
## rounds run the P09 race; Lagsanay and Kangaroo Main rounds reuse the verified P08/P11 round
## controllers and their placement scoring, then end through the same match lifecycle (score
## target, round limit, sudden death). Twist pairs: Karera + Bomb-Taya (T05), Karera + Kangaroo
## (T07) and Kangaroo + Bomb-Taya (T09). Same-step ordering follows the owner-approved table in
## docs/evidence/p12/p12_terminal_order_decision_table.md.

const P12_BUILD_ID := "P12-scheduled-match-dev"

## Modes this room can run; a test may remove one to check the required-mode refusal.
var available_modes: Array[int] = [
	EventSchedule.Challenge.KARERA,
	EventSchedule.Challenge.LAGSANAY,
	EventSchedule.Challenge.KANGAROO
]
var schedule := EventSchedule.new()
var kangaroo_round: KangarooMainRound
## Lagsanay as a Twist on a Karera Main (P12-T05).
var bomb_taya := BombTayaTwist.new()
## The Main Challenge of the round in Play (NONE outside Play and during sudden death).
var event_main: int = EventSchedule.Challenge.NONE

var _schedule_match_id := -1
var _step_delta := 1.0 / 60.0
## Karera + Bomb-Taya: hazard records of this step, decided against the taya timeout (table C4).
var _twist_hazards: Array[AttributionRecord] = []


func _ready() -> void:
	super._ready()
	if not is_instance_valid(input_router) or presenter == null:
		return
	kangaroo_round = KangarooMainRound.new()
	add_child(kangaroo_round)
	kangaroo_round.setup(self)
	input_router.intentional_input_edge.connect(_on_intentional_input_edge)
	pause_coordinator.pause_state_changed.connect(_on_schedule_pause_state_changed)
	print("P12_SCHEDULED_MATCH_READY build=%s seed=%d" % [P12_BUILD_ID, base_match_seed])


func _exit_tree() -> void:
	if (
		input_router != null
		and input_router.intentional_input_edge.is_connected(_on_intentional_input_edge)
	):
		input_router.intentional_input_edge.disconnect(_on_intentional_input_edge)
	if (
		pause_coordinator != null
		and pause_coordinator.pause_state_changed.is_connected(_on_schedule_pause_state_changed)
	):
		pause_coordinator.pause_state_changed.disconnect(_on_schedule_pause_state_changed)
	if kangaroo_round != null:
		kangaroo_round.reset()
	super._exit_tree()


func build_id() -> String:
	return P12_BUILD_ID


func start_match() -> bool:
	if not super.start_match():
		return false
	if schedule.error.is_empty():
		return true
	# The first Pugad refused to lock round 1; the match never starts on an invalid pool.
	return false


## The entry for the round that is in (or about to enter) Play.
func current_entry() -> Dictionary:
	if _sudden_death_active:
		return EventSchedule.sudden_death_entry()
	return schedule.entry_for(items.round_number + 1) if items != null else {}


func _begin_pugad() -> void:
	_end_event_view()
	bomb_taya.reset()
	_twist_hazards.clear()
	event_main = EventSchedule.Challenge.NONE
	_set_goal_visible(true)
	if items != null and items.director != null:
		items.director.elimination_sink_exclusive = false
	if _schedule_match_id != match_run_id:
		_schedule_match_id = match_run_id
		var refusal := schedule.begin(
			match_streams.event, available_modes, tuning.match_round_limit
		)
		if not refusal.is_empty():
			_refuse_schedule(refusal)
			return
	super._begin_pugad()
	if phase_controller.phase != MatchPhaseController.Phase.PUGAD:
		return
	var active_round := items.round_number + 1
	schedule.lock_round(active_round)
	if active_round < tuning.match_round_limit:
		schedule.lock_round(active_round + 1)
	print(
		(
			"P12_SCHEDULE round=%d now=%s next=%s"
			% [
				active_round,
				EventSchedule.describe(schedule.entry_for(active_round)),
				EventSchedule.describe(schedule.entry_for(active_round + 1)),
			]
		)
	)
	_notify_presentation(&"eggs")


func _refuse_schedule(refusal: String) -> void:
	push_error(refusal)
	egg_pool.clear()
	phase_controller.enter(MatchPhaseController.Phase.LOBBY)
	_set_input_phase()
	last_message = refusal
	_notify_presentation(&"eggs")
	_refresh_match_ui()


## Pugad banner: the locked next round (Main first, Twist below), or this round on the last one.
func round_announcement() -> Dictionary:
	if phase_controller.phase != MatchPhaseController.Phase.PUGAD or items == null:
		return {}
	var active_round := items.round_number + 1
	var now := schedule.entry_for(active_round)
	var upcoming := schedule.entry_for(active_round + 1)
	if now.is_empty():
		return {}
	if upcoming.is_empty():
		return {
			"title": "FINAL ROUND %d: %s" % [active_round, EventSchedule.main_name(int(now.main))],
			"detail": _twist_line(now, "No Twist"),
		}
	return {
		"title":
		"NEXT • ROUND %d: %s" % [active_round + 1, EventSchedule.main_name(int(upcoming.main))],
		"detail":
		"%s  ·  This round: %s" % [_twist_line(upcoming, "No Twist"), EventSchedule.describe(now)],
	}


func _twist_line(entry: Dictionary, none_text: String) -> String:
	var twist := int(entry.get("twist", EventSchedule.Challenge.NONE))
	return (
		"TWIST: " + EventSchedule.twist_name(twist)
		if twist != EventSchedule.Challenge.NONE
		else none_text
	)


func _enter_play() -> void:
	var entry := current_entry()
	event_main = int(entry.get("main", EventSchedule.Challenge.KARERA))
	if event_main == EventSchedule.Challenge.KARERA:
		_set_goal_visible(true)
		bomb_taya.reset()
		super._enter_play()
		var twist := int(entry.get("twist", EventSchedule.Challenge.NONE))
		if twist == EventSchedule.Challenge.LAGSANAY:
			_begin_bomb_taya()
		elif twist == EventSchedule.Challenge.KANGAROO:
			_begin_kangaroo_twist()
		return
	_free_match_ghosts()
	input_router.set_rotation_supported(false)
	_reset_actors_for_round()
	race_round_controller = null
	race_candidate_queue.reset()
	_set_goal_visible(false)
	phase_controller.enter(MatchPhaseController.Phase.PLAY)
	_set_input_phase()
	current_context = BoundedStageCamera.Context.PLAY
	camera_rig.set_context(current_context)
	start_play()
	round_start_score_units = cumulative_score_units.duplicate(true)
	var seats: Array[int] = []
	for seat in input_router.registry.joined_seats():
		seats.append(int(seat.seat))
	var round_id := "%d:%d:p12:%s" % [match_run_id, items.round_number + 1, play_challenge_text()]
	var began := (
		_begin_lagsanay_main(round_id, seats)
		if event_main == EventSchedule.Challenge.LAGSANAY
		else kangaroo_round.begin(round_id, seats, round_start_score_units)
	)
	if not began:
		push_error("P12 could not begin %s round %s" % [play_challenge_text(), round_id])
		return
	items.director.active_round_id = round_id
	items.director.elimination_sink_exclusive = true
	if (
		event_main == EventSchedule.Challenge.KANGAROO
		and (
			int(entry.get("twist", EventSchedule.Challenge.NONE))
			== EventSchedule.Challenge.LAGSANAY
		)
	):
		_begin_bomb_taya_for(round_id, seats)
	last_message = (
		"Lagsanay: pass the taya before the countdown expires."
		if event_main == EventSchedule.Challenge.LAGSANAY
		else "Kangaroo: match the slipper pose. Three failed commands eliminate."
	)
	_refresh_match_ui()


func _begin_lagsanay_main(round_id: String, seats: Array[int]) -> bool:
	_last_taya_seat = -1
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
		return false
	for seat_index in seats:
		var actor := actors.get(seat_index) as ChickenController
		if actor != null:
			actor.set_opening_freeze(seat_index == lagsanay_controller.opening_taya_seat)
	_update_taya_marker()
	return true


func _begin_bomb_taya() -> void:
	if race_round_controller == null:
		return
	var seats: Array[int] = []
	for seat in input_router.registry.joined_seats():
		seats.append(int(seat.seat))
	_begin_bomb_taya_for(race_round_controller.ledger.round_id, seats)
	last_message = "Karera with a Bomb-Taya Twist: reach the flag and pass the taya before it blows."
	_refresh_match_ui()


## Karera + Kangaroo (P12-T07): Kangaroo runs beside the race as a Twist. Karera keeps the end
## and the one race score; a third failure is an elimination with no Patibong.
func _begin_kangaroo_twist() -> void:
	if race_round_controller == null:
		return
	var seats: Array[int] = []
	for seat in input_router.registry.joined_seats():
		seats.append(int(seat.seat))
	var round_id := "%s:kangaroo" % race_round_controller.ledger.round_id
	if not kangaroo_round.begin(round_id, seats, round_start_score_units):
		push_error("P12 could not begin the Kangaroo Twist.")
		return
	kangaroo_round.controller.twist_role = true
	items.director.active_round_id = round_id
	items.director.elimination_sink_exclusive = true
	last_message = "Karera with a Kangaroo Twist: reach the flag; three failed commands eliminate."
	_refresh_match_ui()


func _begin_bomb_taya_for(round_id: String, seats: Array[int]) -> void:
	if not bomb_taya.begin(
		"%s:bomb-taya" % round_id,
		seats,
		match_streams.taya,
		tuning.lagsanay_opening_head_start_seconds,
		tuning.taya_pass_back_seconds,
		tuning.lagsanay_taya_seconds_2p,
		tuning.lagsanay_taya_seconds_3p,
		tuning.lagsanay_taya_seconds_4p
	):
		push_error("P12 could not begin the Bomb-Taya Twist.")
		return
	_last_taya_seat = bomb_taya.taya_seat
	var opening := actors.get(bomb_taya.opening_taya_seat) as ChickenController
	if opening != null:
		opening.set_opening_freeze(true)
	_update_taya_marker()


## Bomb-Taya beside a Karera Main (its timeouts become race ledger eliminations).
func _bomb_taya_on_karera() -> bool:
	return (
		bomb_taya.active
		and not _sudden_death_active
		and event_main == EventSchedule.Challenge.KARERA
		and race_round_controller != null
		and not race_round_controller.ended
		and phase_controller.phase == MatchPhaseController.Phase.PLAY
	)


## Bomb-Taya beside a Kangaroo Main (its timeouts are fed to Kangaroo's batch).
func _bomb_taya_on_kangaroo() -> bool:
	return (
		bomb_taya.active
		and not _sudden_death_active
		and event_main == EventSchedule.Challenge.KANGAROO
		and kangaroo_round.controller.active
		and phase_controller.phase == MatchPhaseController.Phase.PLAY
	)


func _bomb_taya_running() -> bool:
	return _bomb_taya_on_karera() or _bomb_taya_on_kangaroo()


func _kangaroo_twist_running() -> bool:
	return (
		kangaroo_round != null
		and kangaroo_round.controller.active
		and kangaroo_round.controller.twist_role
		and not _sudden_death_active
		and event_main == EventSchedule.Challenge.KARERA
		and race_round_controller != null
		and not race_round_controller.ended
		and phase_controller.phase == MatchPhaseController.Phase.PLAY
	)


func _advance_bomb_taya(delta: float) -> void:
	var live: Array[int] = []
	var finished: Array[int] = []
	for seat_index in bomb_taya.seat_indices:
		var actor := actors.get(seat_index) as ChickenController
		if actor == null or not is_instance_valid(actor):
			continue
		if actor.lifecycle.status == PlayerLifecycleState.Status.SECURED:
			finished.append(seat_index)
		elif not actor.lifecycle.is_terminal():
			live.append(seat_index)
	var tick := Engine.get_physics_frames()
	var finishing := _goal_touching_seats(live)
	var contacts := _bomb_taya_contacts(live)
	var result := bomb_taya.advance_step(delta, tick, live, finished, contacts, finishing)
	if bool(result.head_start_ended):
		var opening := actors.get(bomb_taya.opening_taya_seat) as ChickenController
		if opening != null:
			opening.set_opening_freeze(false)
	var expired := int(result.timeout_seat)
	if _forward_twist_hazards(expired, float(result.timeout_time)):
		expired = -1
	if expired >= 0:
		# An event elimination like leaving the stage: no source item, so never a Patibong.
		race_candidate_queue.queue_elimination(
			expired,
			tick,
			"",
			-1,
			"%s:taya_timeout:%d:%d" % [race_round_controller.ledger.round_id, tick, expired]
		)
	if bomb_taya.taya_seat != _last_taya_seat:
		_last_taya_seat = bomb_taya.taya_seat
		_notify_presentation(&"taya")
	_update_taya_marker()


## Live runners overlapping the flag now. They commit as finishers before the tag pass (table
## U2/U3); a runner with a trap or bounds elimination this step is eliminated instead.
func _goal_touching_seats(live: Array[int]) -> Array[int]:
	var touching: Array[int] = []
	if goal_area == null or not goal_area.monitoring:
		return touching
	var tick := Engine.get_physics_frames()
	var excluded: Dictionary = {}
	for record in _twist_hazards:
		excluded[record.player_seat] = true
	for candidate in race_candidate_queue.candidates:
		if int(candidate.physics_tick) == tick and str(candidate.kind) != "goal":
			excluded[int(candidate.seat_index)] = true
	for body in goal_area.get_overlapping_bodies():
		var actor := body as ChickenController
		if (
			actor != null
			and actor.lifecycle.status == PlayerLifecycleState.Status.ACTIVE
			and live.has(actor.seat_index)
			and not excluded.has(actor.seat_index)
			and not touching.has(actor.seat_index)
		):
			touching.append(actor.seat_index)
	touching.sort()
	return touching


## Decides this step's trap kills against the taya timeout (table C4: a strictly earlier
## comparable trap beats the timeout and keeps its Patibong; a tie or an incomparable time is
## the timeout, no credit) and hands the survivors to the race ledger. Returns true when a trap
## replaced the timeout candidate.
func _forward_twist_hazards(timeout_seat: int, timeout_time: float) -> bool:
	var trap_won := false
	for record in _twist_hazards:
		if record.player_seat == timeout_seat:
			if not (record.time_comparable and record.physics_time < timeout_time - 0.000001):
				continue
			trap_won = true
		ItemEliminationBridge.submit(race_candidate_queue, race_round_controller, true, record)
	_twist_hazards.clear()
	return trap_won


## The taya's contacts with live, unfrozen runners (finishers are secured and never targets).
func _bomb_taya_contacts(live: Array[int]) -> Array[Dictionary]:
	var contacts: Array[Dictionary] = []
	if bomb_taya.head_start_remaining > 0.0 or not live.has(bomb_taya.taya_seat):
		return contacts
	var taya := actors.get(bomb_taya.taya_seat) as ChickenController
	if (
		taya == null
		or not is_instance_valid(taya)
		or taya.lifecycle.status != PlayerLifecycleState.Status.ACTIVE
	):
		return contacts
	for node in taya.contact_overlaps():
		var other := node as ChickenController
		if (
			other == null
			or other.lifecycle.status != PlayerLifecycleState.Status.ACTIVE
			or not live.has(other.seat_index)
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


func _event_round_active() -> bool:
	return (
		not _sudden_death_active
		and phase_controller.phase == MatchPhaseController.Phase.PLAY
		and event_main in [EventSchedule.Challenge.LAGSANAY, EventSchedule.Challenge.KANGAROO]
	)


func _physics_process(delta: float) -> void:
	# The Twist reports a timeout before the race drains this step's candidates (P05 room).
	_step_delta = delta
	if not get_tree().paused and _bomb_taya_on_karera():
		_advance_bomb_taya(delta)
	super._physics_process(delta)
	if get_tree().paused or not _event_round_active():
		return
	if event_main == EventSchedule.Challenge.LAGSANAY:
		_advance_lagsanay_main(delta)
	else:
		_advance_kangaroo_main()


func _process(delta: float) -> void:
	super._process(delta)
	if get_tree().paused:
		return
	if (
		(_event_round_active() and event_main == EventSchedule.Challenge.KANGAROO)
		or _kangaroo_twist_running()
	):
		kangaroo_round.update_view(delta)


## Runs inside the race step after support finalisation and before the ledger drains: the
## Kangaroo Twist proposes its eliminations against the same frozen live set (P12-T07).
func _collect_goal_overlaps() -> void:
	super._collect_goal_overlaps()
	if _kangaroo_twist_running():
		_advance_kangaroo_twist()


func _advance_kangaroo_twist() -> void:
	var controller := kangaroo_round.controller
	var tick := Engine.get_physics_frames()
	for candidate in race_candidate_queue.candidates:
		if int(candidate.physics_tick) == tick and str(candidate.kind) != "goal":
			controller.mark_externally_eliminated(int(candidate.seat_index))
	var result := kangaroo_round.advance(tick)
	for outcome in result.new_outcomes:
		race_candidate_queue.queue_elimination(
			int(outcome.get("seat_index", -1)),
			tick,
			str(outcome.get("source_item_id", "")),
			int(outcome.get("direct_owner_seat", -1)),
			str(outcome.get("event_id", "")),
			str(outcome.get("cause", "elimination"))
		)


func _apply_race_outcomes(outcomes: Array) -> void:
	super._apply_race_outcomes(outcomes)
	if kangaroo_round == null or not kangaroo_round.controller.twist_role:
		return
	for outcome in outcomes:
		var seat := int(outcome.get("seat_index", -1))
		if str(outcome.get("outcome", "")) == "finished":
			kangaroo_round.controller.secure_seat(seat)
		else:
			kangaroo_round.controller.mark_externally_eliminated(seat)


func _finish_race(reason: String) -> void:
	if kangaroo_round != null and kangaroo_round.controller.twist_role:
		kangaroo_round.clear_view()
	super._finish_race(reason)


func _advance_lagsanay_main(delta: float) -> void:
	if not lagsanay_controller.active:
		return
	var result := lagsanay_controller.advance_step(
		delta, Engine.get_physics_frames(), _lagsanay_contacts(), actors
	)
	if bool(result.head_start_ended):
		var opening_actor := actors.get(lagsanay_controller.opening_taya_seat) as ChickenController
		if opening_actor != null:
			opening_actor.set_opening_freeze(false)
	_apply_event_outcomes(
		result.new_outcomes,
		lagsanay_controller.score_result() if lagsanay_controller.ended else {},
		lagsanay_controller.ended,
		lagsanay_controller.winner_seat
	)
	_update_taya_marker()
	_update_camera_targets()
	if bool(result.ended):
		_finish_event_round()
	elif lagsanay_controller.taya_seat != _last_taya_seat:
		_last_taya_seat = lagsanay_controller.taya_seat
		_notify_presentation(&"taya")


func _advance_kangaroo_main() -> void:
	var controller := kangaroo_round.controller
	if not controller.active:
		return
	var tick := Engine.get_physics_frames()
	var bomb := _bomb_taya_on_kangaroo()
	if bomb:
		# The taya timeout joins Kangaroo's batch with its comparable time, so command failure,
		# timeout and trap order by recorded time (table U9: failure, then timeout, then trap).
		var expiry := bomb_taya.expiry_time_this_step(_step_delta)
		if expiry >= 0.0 and bomb_taya.taya_seat >= 0:
			controller.submit_external_elimination(
				bomb_taya.taya_seat,
				expiry,
				"%s:taya_timeout:%d:%d" % [controller.round_id, tick, bomb_taya.taya_seat],
				"timeout"
			)
	var result := kangaroo_round.advance(tick)
	if bomb:
		_advance_bomb_taya_for_kangaroo(tick)
	var score_result := controller.score_result() if controller.ended else {}
	_apply_event_outcomes(
		result.new_outcomes,
		score_result,
		controller.ended,
		int(score_result.get("winner_seat", -1))
	)
	_update_camera_targets()
	if bool(result.get("ended", false)):
		_finish_event_round()


## Bomb-Taya under a Kangaroo Main: runs after Kangaroo's batch so a failure that eliminates the
## taya or the pass target is committed before the tag pass (table U10).
func _advance_bomb_taya_for_kangaroo(tick: int) -> void:
	var live: Array[int] = []
	for seat_index in kangaroo_round.controller.live_seats:
		var actor := actors.get(seat_index) as ChickenController
		if actor != null and is_instance_valid(actor) and not actor.lifecycle.is_terminal():
			live.append(seat_index)
	var no_finished: Array[int] = []
	var result := bomb_taya.advance_step(
		_step_delta, tick, live, no_finished, _bomb_taya_contacts(live)
	)
	if bool(result.head_start_ended):
		var opening := actors.get(bomb_taya.opening_taya_seat) as ChickenController
		if opening != null:
			opening.set_opening_freeze(false)
	if bomb_taya.taya_seat != _last_taya_seat:
		_last_taya_seat = bomb_taya.taya_seat
		_notify_presentation(&"taya")
	_update_taya_marker()


## Same contact rule as P08: the live taya's overlaps with live, unfrozen round participants.
func _lagsanay_contacts() -> Array[Dictionary]:
	var contacts: Array[Dictionary] = []
	if not lagsanay_controller.active or lagsanay_controller.head_start_remaining > 0.0:
		return contacts
	var taya := actors.get(lagsanay_controller.taya_seat) as ChickenController
	if (
		taya == null
		or not is_instance_valid(taya)
		or taya.lifecycle.is_terminal()
		or taya.lifecycle.status == PlayerLifecycleState.Status.OPENING_FREEZE
	):
		return contacts
	for node in taya.contact_overlaps():
		var other := node as ChickenController
		if (
			other == null
			or other.lifecycle.is_terminal()
			or other.lifecycle.status == PlayerLifecycleState.Status.OPENING_FREEZE
			or not lagsanay_controller.seat_indices.has(other.seat_index)
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


## Eliminations from the event controller; at the end the survivor (or Last Cluck) is secured.
func _apply_event_outcomes(
	outcomes: Array, score_result: Dictionary, ended: bool, winner_seat: int
) -> void:
	var last_cluck := bool(score_result.get("last_cluck", false))
	var cluck_seat := int(score_result.get("last_cluck_seat", -1))
	for outcome in outcomes:
		var seat_index := int(outcome.get("seat_index", -1))
		var actor := actors.get(seat_index) as ChickenController
		if actor == null or not is_instance_valid(actor):
			continue
		if last_cluck and seat_index == cluck_seat:
			actor.secure("last_cluck_winner")
		else:
			actor.eliminate(str(outcome.get("cause", "eliminated")))
	if ended and not last_cluck:
		var winner := actors.get(winner_seat) as ChickenController
		if winner != null and is_instance_valid(winner) and not winner.lifecycle.is_terminal():
			winner.secure("event_winner")


## Commits the event's placement scores once, then ends the round through the lifecycle.
func _finish_event_round() -> void:
	if not _event_round_active():
		return
	var active_round := items.round_number + 1
	var is_lagsanay := event_main == EventSchedule.Challenge.LAGSANAY
	var score_result: Dictionary
	var outcome_rows: Array[Dictionary]
	if is_lagsanay:
		score_result = lagsanay_controller.score_result()
		outcome_rows = lagsanay_controller.outcomes()
		if not lagsanay_controller.commit_score_once(score_result):
			return
	else:
		score_result = kangaroo_round.controller.score_result()
		outcome_rows = kangaroo_round.controller.outcomes()
		if not kangaroo_round.controller.commit_score_once(score_result):
			return
	_record_score_presentation(active_round, score_result)
	last_resolution = score_result.duplicate(true)
	for seat_index in score_result.totals_units:
		cumulative_score_units[int(seat_index)] = int(score_result.totals_units[seat_index])
	items.end_round()
	items.director.elimination_sink_exclusive = false
	_end_event_view()
	var seats := input_router.registry.joined_seats()
	var model: MatchResultsViewModel
	if is_lagsanay:
		model = MatchResultsViewModel.lag_sanay(
			items.round_number,
			seats,
			outcome_rows,
			score_result,
			tuning.lagsanay_opening_head_start_seconds,
			tuning.lagsanay_taya_seconds_2p,
			tuning.lagsanay_taya_seconds_3p,
			tuning.lagsanay_taya_seconds_4p,
			tuning.taya_pass_back_seconds
		)
	else:
		model = MatchResultsViewModel.kangaroo(
			items.round_number, seats, outcome_rows, score_result
		)
	event_main = EventSchedule.Challenge.NONE
	_conclude_round(
		active_round,
		model,
		"%s round %d complete. Match continues." % [_event_label(is_lagsanay), active_round]
	)


func _event_label(is_lagsanay: bool) -> String:
	return "Lagsanay" if is_lagsanay else "Kangaroo"


func _start_sudden_death(decision: Dictionary) -> void:
	event_main = EventSchedule.Challenge.NONE
	_end_event_view()
	bomb_taya.reset()
	super._start_sudden_death(decision)
	# P09 begins the sudden-death controller mid-step, after the director clock was reset and
	# before this step's director advance: its clock would run one step ahead of the hazard
	# record times and drop every trap elimination. Start it one step behind so both agree.
	if lagsanay_controller.active:
		lagsanay_controller.simulation_clock = -_step_delta


func _end_event_view() -> void:
	if kangaroo_round != null:
		kangaroo_round.clear_view()
	if _taya_marker != null and is_instance_valid(_taya_marker) and not _sudden_death_active:
		_taya_marker.visible = false


func _on_item_elimination(record: AttributionRecord) -> bool:
	if _event_round_active():
		if event_main == EventSchedule.Challenge.LAGSANAY:
			return lagsanay_controller.submit_hazard(record)
		return kangaroo_round.controller.submit_hazard(record)
	if _kangaroo_twist_running():
		# Kangaroo arbitrates trap vs command failure; its outcomes reach the ledger as candidates.
		return kangaroo_round.controller.submit_hazard(record)
	if _bomb_taya_on_karera() and race_round_controller != null:
		_twist_hazards.append(record)
		return true
	return super._on_item_elimination(record)


func _on_intentional_input_edge(
	seat_index: int, action_name: String, source_id: String, is_pressed: bool, event_usec: int
) -> void:
	if (
		(_event_round_active() and event_main == EventSchedule.Challenge.KANGAROO)
		or _kangaroo_twist_running()
	):
		kangaroo_round.record_input_edge(seat_index, action_name, source_id, is_pressed, event_usec)


func _on_schedule_pause_state_changed(paused_state: bool, _reason: String) -> void:
	if kangaroo_round == null:
		return
	kangaroo_round.set_overlay_visible(
		not paused_state and (_event_round_active() or _kangaroo_twist_running())
	)
	if not paused_state:
		kangaroo_round.resync_after_pause()


func _set_goal_visible(value: bool) -> void:
	if goal_area != null:
		goal_area.monitoring = value
		goal_area.collision_mask = 2 if value else 0
		goal_area.visible = value
	for child in world_layer.get_children():
		if child is Label and (child as Label).text == "KARERA GOAL":
			(child as Label).visible = value
		elif child is Line2D and (child as Line2D).name == "FlagTriggerOutline":
			(child as Line2D).visible = value


func _update_taya_marker() -> void:
	var twist := _bomb_taya_running()
	if (
		not twist
		and (
			_sudden_death_active
			or not _event_round_active()
			or event_main != EventSchedule.Challenge.LAGSANAY
		)
	):
		super._update_taya_marker()
		return
	if _taya_marker == null or not is_instance_valid(_taya_marker):
		return
	var seat := bomb_taya.taya_seat if twist else lagsanay_controller.taya_seat
	var actor := actors.get(seat) as ChickenController
	if (
		(not twist and not lagsanay_controller.active)
		or actor == null
		or not is_instance_valid(actor)
	):
		_taya_marker.visible = false
		return
	_taya_marker.text = "★ TAYA • %s" % _seat_identity_text(seat)
	_taya_marker.position = (
		actor.global_position + Vector2(-110.0, -actor.tuning.body_height_wu * 0.65)
	)
	_taya_marker.visible = true


func _update_diagnostics() -> void:
	super._update_diagnostics()
	_update_taya_marker()


func reset_room() -> void:
	event_main = EventSchedule.Challenge.NONE
	_schedule_match_id = -1
	schedule = EventSchedule.new()
	if kangaroo_round != null:
		kangaroo_round.reset()
	super.reset_room()


# --- Presentation hooks -----------------------------------------------------------------------


func play_challenge_text() -> String:
	if _sudden_death_active:
		return super.play_challenge_text()
	var entry := current_entry()
	if entry.is_empty():
		return super.play_challenge_text()
	return EventSchedule.main_name(int(entry.main)).capitalize()


func play_twist_text() -> String:
	var entry := current_entry()
	var twist := int(entry.get("twist", EventSchedule.Challenge.NONE))
	return (
		"TWIST: " + EventSchedule.twist_name(twist) if twist != EventSchedule.Challenge.NONE else ""
	)


func play_clock_seconds() -> float:
	if not _event_round_active():
		return super.play_clock_seconds()
	if event_main == EventSchedule.Challenge.LAGSANAY:
		if not lagsanay_controller.active:
			return 0.0
		if lagsanay_controller.head_start_remaining > 0.0:
			return lagsanay_controller.head_start_remaining
		return lagsanay_controller.countdown_remaining
	var commands := kangaroo_round.controller.active_commands()
	if commands.is_empty():
		return 0.0
	var command: Dictionary = commands[0]
	var deadline := float(command.response_start_at)
	if str(command.status) == "RESPONSE":
		deadline = float(command.response_end_at)
	return maxf(0.0, deadline - items.director.simulation_time)


func play_goal_text() -> String:
	if not _event_round_active():
		return super.play_goal_text()
	if event_main == EventSchedule.Challenge.LAGSANAY:
		return "Touch to pass the taya!"
	return "Match the slipper pose."


## Taya tag beside the Main's clock: Karera adds the countdown (and the finish window); under
## Kangaroo the countdown rides on the world marker so the HUD row fits four seats.
func _bomb_tag_text() -> String:
	var prefix := "HEAD START • " if bomb_taya.head_start_remaining > 0.0 else ""
	var text := "%sTAYA %s" % [prefix, _short_seat_text(bomb_taya.taya_seat)]
	if not _bomb_taya_on_karera():
		return text
	text += " %.0fs" % ceilf(bomb_taya.countdown_remaining)
	var window := super.play_tag_text()
	return text + (" • " + window if not window.is_empty() else "")


## "P3 ■": number and shape only, so the HUD clock row fits four seats at 1080p.
func _short_seat_text(seat_index: int) -> String:
	var seat := input_router.registry.get_seat(seat_index)
	return (
		"P%d %s"
		% [int(seat.get("identity", seat_index + 1)), MARKS.get(str(seat.get("shape", "")), "◆")]
	)


func play_tag_text() -> String:
	if _bomb_taya_running():
		return _bomb_tag_text()
	if not _event_round_active():
		return super.play_tag_text()
	if event_main == EventSchedule.Challenge.LAGSANAY:
		if not lagsanay_controller.active:
			return ""
		var prefix := "HEAD START • " if lagsanay_controller.head_start_remaining > 0.0 else ""
		return "%sTAYA %s" % [prefix, _short_seat_text(lagsanay_controller.taya_seat)]
	var commands := kangaroo_round.controller.active_commands()
	if commands.is_empty():
		return ""
	return KangarooRoundController.command_name(int(commands[0].command))


## Like the P08 lab: only live pass-back immunity is persistent; otherwise the timed Play-start
## notice shows.
func play_status_text() -> String:
	var twist := _bomb_taya_running()
	if not twist and not _event_round_active():
		return super.play_status_text()
	if (
		not twist
		and (event_main != EventSchedule.Challenge.LAGSANAY or not lagsanay_controller.active)
	):
		return ""
	var immune := PackedStringArray()
	var seats := bomb_taya.seat_indices if twist else lagsanay_controller.seat_indices
	for seat_index in seats:
		var remaining := (
			bomb_taya.pass_back_remaining_seconds(int(seat_index))
			if twist
			else lagsanay_controller.pass_back_remaining_seconds(int(seat_index))
		)
		if remaining > 0.0:
			immune.append("%s %.1f s" % [_seat_identity_text(int(seat_index)), remaining])
	return "Pass-back immunity: " + ", ".join(immune) if not immune.is_empty() else ""


func seat_state_text(seat_index: int) -> String:
	if _bomb_taya_running() and seat_index == bomb_taya.taya_seat:
		return "TAYA"
	if not _event_round_active():
		return super.seat_state_text(seat_index)
	if (
		event_main == EventSchedule.Challenge.LAGSANAY
		and lagsanay_controller.active
		and seat_index == lagsanay_controller.taya_seat
	):
		return "TAYA"
	return ""


func debug_status_text() -> String:
	if (
		(_event_round_active() and event_main == EventSchedule.Challenge.KANGAROO)
		or _kangaroo_twist_running()
	):
		return KangarooCommandStyle.marker_status(kangaroo_round.controller, input_router.registry)
	return super.debug_status_text()

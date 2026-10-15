extends SceneTree

## P12-T05 / P12-T06: the Karera + Lagsanay pair ("KARERA / TWIST: BOMB-TAYA").
## Controller rules (BombTayaTwist) and real 2/3/4-seat matches in the P12 room. Checks: the
## current taya finishes (secured, taya moves with the countdown kept and no new freeze),
## secured finishers are never targets, timeout eliminations are race eliminations without a
## Patibong, a timeout and a goal in the same step resolve as the elimination, a direct trap
## kill keeps its Patibong, the last live runner finishing or dying ends the race, and the round
## scores with the race calculator only (no Lagsanay placement points).
## Run: godot --headless --fixed-fps 60 --path tilaok! --script res://tests/run_p12_stack_tests.gd

const ROOM_SCENE := preload("res://scenes/match/p12_scheduled_match_room.tscn")
const LAGSANAY := EventSchedule.Challenge.LAGSANAY
const SPIKES := "block.spikes.main"

var failures := 0
var checks := 0
var room: P12ScheduledMatchRoom


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_controller_rules()
	for players in [2, 3, 4]:
		await _test_taya_finishes_then_last_runner(players)
	await _test_timeout_goal_conflict()
	await _test_direct_trap_award(3)
	await _test_direct_trap_award(4)
	print("P12_STACK_TESTS checks=%d failures=%d" % [checks, failures])
	await process_frame
	quit(1 if failures > 0 else 0)


func _check(condition: bool, label: String) -> void:
	checks += 1
	if condition:
		print("PASS ", label)
	else:
		failures += 1
		push_error("FAIL " + label)


# ---------------------------------------------------------------- controller


func _twist(seats: Array[int], seed_value: int = 7) -> BombTayaTwist:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var twist := BombTayaTwist.new()
	twist.begin("t", seats, rng, 0.5, 1.0, 7.0, 10.0, 15.0)
	return twist


func _contact(seat: int, distance: float) -> Dictionary:
	return {"seat_index": seat, "distance_squared": distance}


func _test_controller_rules() -> void:
	var none: Array[Dictionary] = []
	var no_seats: Array[int] = []
	var seats: Array[int] = [0, 1, 2, 3]
	var twist := _twist(seats)
	_check(
		(
			twist.active
			and seats.has(twist.taya_seat)
			and is_equal_approx(twist.countdown_seconds, 15.0)
		),
		"four runners: one random opening taya with the 4-player timer"
	)
	var taya := twist.taya_seat
	var others := seats.filter(func(seat: int) -> bool: return seat != taya)
	var early: Array[Dictionary] = [_contact(int(others[0]), 1.0)]
	twist.advance_step(0.25, 1, seats, no_seats, early)
	_check(twist.taya_seat == taya, "no pass during the opening head start")
	twist.advance_step(0.5, 2, seats, no_seats, none)
	var before := twist.countdown_remaining
	var finished: Array[int] = [int(others[0])]
	var live: Array[int] = seats.filter(func(seat: int) -> bool: return seat != others[0])
	var near_finisher: Array[Dictionary] = [_contact(int(others[0]), 1.0)]
	twist.advance_step(0.1, 3, live, finished, near_finisher)
	_check(twist.taya_seat == taya, "a finished (secured) runner is never a pass target")
	var tag: Array[Dictionary] = [_contact(int(others[1]), 9.0), _contact(int(others[2]), 4.0)]
	var tagged := twist.advance_step(0.1, 4, live, finished, tag)
	_check(
		bool(tagged.tagged) and twist.taya_seat == int(others[2]),
		"touch passes to the nearest live runner"
	)
	_check(
		is_equal_approx(twist.countdown_remaining, before - 0.2),
		"passing never resets the countdown"
	)
	var back: Array[Dictionary] = [_contact(taya, 1.0)]
	twist.advance_step(0.1, 5, live, finished, back)
	_check(twist.taya_seat == int(others[2]), "the previous taya has pass-back immunity")
	# The current taya finishes: the taya moves on with the same countdown.
	var keep := twist.countdown_remaining
	var finisher := twist.taya_seat
	finished.append(finisher)
	live.erase(finisher)
	var moved := twist.advance_step(0.1, 6, live, finished, none)
	_check(
		(
			bool(moved.taya_changed)
			and live.has(twist.taya_seat)
			and str(twist.transfers.back().reason) == "taya_finished"
			and is_equal_approx(float(twist.transfers.back().countdown_remaining), keep)
			and twist.head_start_remaining == 0.0
		),
		"a finishing taya hands the taya to a live runner with the remaining countdown"
	)
	# A trap kills the taya: the next taya gets the timer for the new live count (2 left).
	var victim := twist.taya_seat
	live.erase(victim)
	twist.advance_step(0.1, 7, live, finished, none)
	_check(
		(
			live.has(twist.taya_seat)
			and str(twist.transfers.back().reason) == "taya_out"
			and is_equal_approx(twist.countdown_seconds, 7.0)
		),
		"an eliminated taya is replaced with the timer for the new live count"
	)
	# One runner is left: the taya carries the shortest (2-player) timer; provisional.
	_check(
		live.size() == 1 and twist.taya_seat == live[0],
		"the last live runner carries the taya with the shortest timer"
	)
	# Timeout of the last runner: reported once at its recorded time, then the Twist idles.
	twist.countdown_remaining = 0.05
	var expired := twist.taya_seat
	var timeout := twist.advance_step(0.1, 8, live, finished, none)
	_check(
		(
			int(timeout.timeout_seat) == expired
			and twist.timeouts.size() == 1
			and is_equal_approx(float(timeout.timeout_time), twist.simulation_clock - 0.05)
			and bool(timeout.idle)
			and not twist.active
		),
		"the countdown expiry reports one timeout at its recorded time; no runner is left"
	)
	# A timeout with runners left hands a fresh timer to the next taya.
	var three: Array[int] = [0, 1, 2]
	var other := _twist(three, 11)
	other.advance_step(0.6, 1, three, no_seats, none)
	other.countdown_remaining = 0.05
	var gone := other.taya_seat
	var handed := other.advance_step(0.1, 2, three, no_seats, none)
	_check(
		(
			int(handed.timeout_seat) == gone
			and other.taya_seat != gone
			and is_equal_approx(other.countdown_seconds, 7.0)
		),
		"after a timeout the next taya gets the timer for the new live count (2 left: 7 s)"
	)
	# The last live runner finishes: the Twist idles and the race decides the end.
	var two: Array[int] = [0, 1]
	var pair := _twist(two, 3)
	pair.advance_step(0.6, 1, two, no_seats, none)
	var done: Array[int] = [0, 1]
	var idle := pair.advance_step(0.1, 2, no_seats, done, none)
	_check(
		bool(idle.idle) and not pair.active and pair.taya_seat == -1,
		"when the last runner finishes the Twist goes idle and the race decides the end"
	)
	var replay := _twist(seats)
	_check(replay.taya_seat == _twist(seats).taya_seat, "the opening taya is seeded")


# ---------------------------------------------------------------- room


func _open(players: int) -> Array[int]:
	room = ROOM_SCENE.instantiate() as P12ScheduledMatchRoom
	root.add_child(room)
	await process_frame
	await physics_frame
	var seats: Array[int] = [room.join_keyboard("K1"), room.join_keyboard("K2")]
	for device_id in [7101, 7102].slice(0, players - 2):
		var seat_index := room.input_router.registry.join_gamepad(device_id)
		seats.append(seat_index)
		room.input_router.seat_joined.emit(seat_index)
	for seat_index in seats:
		room.input_router.registry.set_ready(seat_index, true)
	room.start_match()
	room.tuning.match_target_score_units = 100000
	room.tuning.match_results_advance_seconds = 600.0
	room.tuning.lagsanay_opening_head_start_seconds = 0.1
	return seats


## Plays round 1 with a Bomb-Taya Twist injected into its locked entry (test-only: the real
## schedule never gives round 1 a Twist), runners spread apart so nobody touches by accident.
func _enter_twist_play(edits: Array[Dictionary]) -> void:
	room.schedule.locked[1]["twist"] = LAGSANAY
	room._finish_pugad_timeout()
	room._resolve_place_edits(edits)
	var index := 0
	for seat_index in room.bomb_taya.seat_indices:
		var actor := room.actors[seat_index] as ChickenController
		var feet := room.arena.spawn_feet + Vector2(220.0 * index, 0.0)
		actor.global_position = room.arena.controller_origin_from_feet(feet)
		index += 1
	for _frame in range(12):
		await physics_frame


func _queue_goal_now(seat_index: int) -> void:
	await physics_frame
	room.race_candidate_queue.queue_goal(
		room.actors[seat_index] as ChickenController, Engine.get_physics_frames()
	)
	await physics_frame
	await physics_frame


func _outcome(seat_index: int) -> Dictionary:
	return room.race_round_controller.ledger.outcomes_by_seat.get(seat_index, {})


func _race_only(seats: Array[int], start: Dictionary) -> Dictionary:
	return RaceScoreCalculator.calculate(seats, room.race_round_controller.ledger.outcomes(), start)


func _test_taya_finishes_then_last_runner(players: int) -> void:
	var seats := await _open(players)
	var none: Array[Dictionary] = []
	await _enter_twist_play(none)
	_check(
		room.bomb_taya.active and room.play_twist_text() == "TWIST: BOMB-TAYA",
		"%dp: the Karera round runs a Bomb-Taya Twist with the flag live" % players
	)
	_check(room.goal_area.monitoring, "%dp: the flag stays active" % players)
	var start := room.round_start_score_units.duplicate()
	var first := room.bomb_taya.taya_seat
	var countdown := room.bomb_taya.countdown_remaining
	await _queue_goal_now(first)
	var secured := (room.actors[first] as ChickenController).lifecycle.status
	var new_taya := room.bomb_taya.taya_seat
	var new_actor := room.actors.get(new_taya) as ChickenController
	_check(
		(
			str(_outcome(first).get("outcome", "")) == "finished"
			and secured == PlayerLifecycleState.Status.SECURED
			and new_taya != first
			and new_actor != null
			and new_actor.lifecycle.status == PlayerLifecycleState.Status.ACTIVE
		),
		"%dp: the taya reaches the flag, is secured, and the taya moves to a runner" % players
	)
	var handed: Dictionary = room.bomb_taya.transfers.back()
	_check(
		(
			str(handed.reason) == "taya_finished"
			and float(handed.countdown_remaining) < countdown
			and float(handed.countdown_remaining) > countdown - 0.2
			and room.bomb_taya.head_start_remaining == 0.0
		),
		(
			"%dp: the remaining countdown is kept (%.2f -> %.2f) with no new opening freeze"
			% [players, countdown, float(handed.countdown_remaining)]
		)
	)
	# Secured exclusion: the finisher stands on the new taya and is never tagged back.
	(room.actors[first] as ChickenController).global_position = new_actor.global_position
	var ever_back := false
	for _frame in range(30):
		await physics_frame
		ever_back = ever_back or room.bomb_taya.taya_seat == first
	_check(not ever_back, "%dp: a secured finisher is never a taya target" % players)
	# Timeouts until one runner is left, then that runner finishes (3/4p) or times out (2p).
	var timed_out: Array[int] = []
	while _live_runners(seats).size() > (1 if players > 2 else 0):
		var expiring := room.bomb_taya.taya_seat
		room.bomb_taya.countdown_remaining = 0.05
		for _frame in range(6):
			await physics_frame
		timed_out.append(expiring)
		if room.phase_controller.phase != MatchPhaseController.Phase.PLAY:
			break
	var timeout_rows_ok := true
	for seat_index in timed_out:
		var row := _outcome(seat_index)
		timeout_rows_ok = (
			timeout_rows_ok
			and str(row.get("outcome", "")) == "eliminated"
			and str(row.get("event_id", "")).contains("taya_timeout")
			and int(row.get("direct_owner_seat", 0)) == -1
		)
	_check(
		timeout_rows_ok and not timed_out.is_empty(),
		"%dp: taya timeouts are race eliminations with no Patibong (%s)" % [players, timed_out]
	)
	if players > 2:
		var last := _live_runners(seats)[0]
		_check(
			room.bomb_taya.taya_seat == last, "%dp: the last live runner carries the taya" % players
		)
		await _queue_goal_now(last)
		_check(
			str(_outcome(last).get("outcome", "")) == "finished",
			"%dp: the last live runner can still finish" % players
		)
	_check(
		room.phase_controller.phase == MatchPhaseController.Phase.RESULTS,
		"%dp: the race ends when every runner has finished or been eliminated" % players
	)
	var expected := _race_only(seats, start)
	var totals_match := bool(expected.valid)
	for seat_index in seats:
		totals_match = (
			totals_match
			and (
				int(room.cumulative_score_units[seat_index])
				== int(expected.totals_units[seat_index])
			)
		)
	_check(
		totals_match,
		"%dp: scores equal the race calculator alone (no Lagsanay placement points)" % players
	)
	await _close()


func _live_runners(seats: Array[int]) -> Array[int]:
	var result: Array[int] = []
	for seat_index in seats:
		var actor := room.actors[seat_index] as ChickenController
		if not actor.lifecycle.is_terminal():
			result.append(seat_index)
	return result


func _test_timeout_goal_conflict() -> void:
	await _open(2)
	var none: Array[Dictionary] = []
	await _enter_twist_play(none)
	var taya := room.bomb_taya.taya_seat
	await physics_frame
	# Expires inside this very step, and the taya touches the flag in the same step.
	room.bomb_taya.countdown_remaining = 0.5 / 60.0
	room.race_candidate_queue.queue_goal(
		room.actors[taya] as ChickenController, Engine.get_physics_frames()
	)
	await physics_frame
	await physics_frame
	var row := _outcome(taya)
	_check(
		(
			str(row.get("outcome", "")) == "eliminated"
			and str(row.get("event_id", "")).contains("taya_timeout")
		),
		"timeout and goal in the same step: the elimination wins (race ledger rule)"
	)
	await _close()


func _test_direct_trap_award(players: int) -> void:
	var seats := await _open(players)
	var edits: Array[Dictionary] = [
		{
			"seat_index": 0,
			"variant_key": SPIKES,
			"origin_cell": Vector2i(16, 14),
			"quarter_turns": 0,
			"cleanup_targets": [],
		}
	]
	await _enter_twist_play(edits)
	var start := room.round_start_score_units.duplicate()
	var taya := room.bomb_taya.taya_seat
	var victim := taya if taya != 0 else 1
	var victim_actor := room.actors[victim] as ChickenController
	victim_actor.global_position = Vector2(16.0 * 64.0 + 32.0, 700.0)
	victim_actor.velocity = Vector2.ZERO
	for _frame in range(120):
		await physics_frame
		if victim_actor.lifecycle.is_terminal():
			break
	var row := _outcome(victim)
	_check(
		str(row.get("outcome", "")) == "eliminated" and int(row.get("direct_owner_seat", -1)) == 0,
		"%dp: a spike kill during the Twist is a direct trap kill credited to P1" % players
	)
	await physics_frame
	if victim == taya:
		_check(
			room.bomb_taya.taya_seat != victim and room.bomb_taya.taya_seat >= 0,
			"%dp: the trapped taya is replaced by a live runner" % players
		)
	await _queue_goal_now(0)
	room.race_round_controller.hard_cap_seconds = 0.0
	for _frame in range(4):
		await physics_frame
	var expected := _race_only(seats, start)
	var patibong := false
	for award in expected.get("award_rows", []):
		patibong = patibong or (str(award.key) == "patibong" and int(award.seat_index) == 0)
	var totals_match := bool(expected.valid)
	for seat_index in seats:
		totals_match = (
			totals_match
			and (
				int(room.cumulative_score_units[seat_index])
				== int(expected.totals_units[seat_index])
			)
		)
	_check(
		patibong and totals_match,
		"%dp: the trap owner keeps the race Patibong; totals are race-only" % players
	)
	await _close()


func _close() -> void:
	room.queue_free()
	await process_frame
	room = null

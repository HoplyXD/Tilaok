extends SceneTree

## Current P12 schedule contract: standalone modes only; historical pair runs are separate.
## Seeded schedule tables (all 12 rounds, guaranteed-round precedence, zero/one
## compatible options, required missing-mode refusal) and full scheduled matches in the real P12
## room with 2, 3 and 4 synthetic seats: every round plays the Main Challenge announced in the
## Pugad before it, scores through its own family and ends through the match lifecycle.
## Run: godot --headless --fixed-fps 60 --path tilaok! --script res://tests/run_p12_tests.gd

const ROOM_SCENE := preload("res://scenes/match/p12_scheduled_match_room.tscn")
const NONE := EventSchedule.Challenge.NONE
const KARERA := EventSchedule.Challenge.KARERA
const LAGSANAY := EventSchedule.Challenge.LAGSANAY
const KANGAROO := EventSchedule.Challenge.KANGAROO
const MAX_EVENT_FRAMES := 30000

var failures := 0
var checks := 0
var room: P12ScheduledMatchRoom


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_guaranteed_rounds_and_table()
	_test_determinism_and_lock_order()
	_test_main_distribution()
	_test_no_mixed_modes()
	_test_required_mode_refusal()
	_test_kangaroo_sequential_lifecycle()
	_test_kangaroo_reset_keeps_room_actors()
	for players in [2, 3, 4]:
		await _test_full_scheduled_match(players)
	await _test_room_refuses_missing_mode()
	print("P12_TESTS checks=%d failures=%d" % [checks, failures])
	await process_frame
	quit(1 if failures > 0 else 0)


func _check(condition: bool, label: String) -> void:
	checks += 1
	if condition:
		print("PASS ", label)
	else:
		failures += 1
		push_error("FAIL " + label)


func _all_modes() -> Array[int]:
	var modes: Array[int] = [KARERA, LAGSANAY, KANGAROO]
	return modes


func _all_pairs_enabled() -> Array[Dictionary]:
	var pairs: Array[Dictionary] = []
	for row in EventSchedule.COMPATIBILITY:
		var copy: Dictionary = row.duplicate()
		copy.enabled = true
		pairs.append(copy)
	return pairs


func _schedule(
	seed_value: int, modes: Array[int], pairs: Array[Dictionary], limit: int = 12
) -> EventSchedule:
	var streams := SeededDiagnosticStreams.new()
	streams.seed_all(seed_value)
	var schedule := EventSchedule.new()
	schedule.begin(streams.event, modes, limit, pairs)
	return schedule


func _table(schedule: EventSchedule) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for round_number in range(1, schedule.round_limit + 1):
		rows.append(schedule.lock_round(round_number))
	return rows


func _test_guaranteed_rounds_and_table() -> void:
	var violations := PackedStringArray()
	var mains_seen := {}
	for seed_value in range(1, 501):
		var rows := _table(_schedule(seed_value, _all_modes(), EventSchedule.enabled_pairs()))
		for row in rows:
			var round_number := int(row.round)
			var main := int(row.main)
			mains_seen[main] = true
			if round_number == 1 and main != KARERA:
				violations.append("seed %d round 1 is %d" % [seed_value, main])
			if round_number in [4, 8, 12] and main != LAGSANAY:
				violations.append("seed %d round %d is %d" % [seed_value, round_number, main])
			if bool(row.guaranteed) != (round_number in [1, 4, 8, 12]):
				violations.append("seed %d round %d guaranteed flag" % [seed_value, round_number])
			if int(row.twist) != NONE:
				violations.append(
					(
						"seed %d round %d unexpectedly stacks %d"
						% [seed_value, round_number, int(row.twist)]
					)
				)
			if main not in [KARERA, LAGSANAY, KANGAROO]:
				violations.append("seed %d round %d main %d" % [seed_value, round_number, main])
	_check(
		violations.is_empty(),
		(
			"500 seeded 12-round tables preserve guaranteed standalone rounds and contain no Twists: %s"
			% [violations.slice(0, 5)]
		)
	)
	_check(mains_seen.size() == 3, "every Main Challenge appears across the seeded tables")
	var sample := _table(_schedule(12345, _all_modes(), EventSchedule.enabled_pairs()))
	var described := PackedStringArray()
	for row in sample:
		described.append("R%d %s" % [int(row.round), EventSchedule.describe(row)])
	print("P12_SCHEDULE_SAMPLE seed=12345 ", ", ".join(described))
	_check(sample.size() == 12, "the seeded table covers all 12 rounds")
	var enabled_rows := EventSchedule.enabled_pairs()
	_check(
		EventSchedule.COMPATIBILITY.is_empty() and enabled_rows.is_empty(),
		"normal schedule exposes no mixed-mode compatibility rows"
	)
	var sudden := EventSchedule.sudden_death_entry()
	_check(
		int(sudden.main) == LAGSANAY and int(sudden.twist) == NONE,
		"sudden death is standalone Lagsanay with no Twist"
	)
	_check(EventSchedule.twist_chance(12) == 0.0, "Twist chance remains disabled for all rounds")


func _test_determinism_and_lock_order() -> void:
	var first := _table(_schedule(777, _all_modes(), _all_pairs_enabled()))
	var again := _table(_schedule(777, _all_modes(), _all_pairs_enabled()))
	_check(first == again, "the same seed gives the same 12-round table")
	var jump := _schedule(777, _all_modes(), _all_pairs_enabled())
	var last := jump.lock_round(12)
	_check(
		last == first[11] and _table(jump) == first,
		"locking round 12 first gives the same table (earlier rounds lock in order)"
	)
	var relock := jump.lock_round(6)
	_check(relock == first[5], "a locked round never changes when it is asked for again")
	var differs := false
	for seed_value in range(1, 30):
		if _table(_schedule(seed_value, _all_modes(), _all_pairs_enabled())) != first:
			differs = true
			break
	_check(differs, "different seeds give different tables")
	_check(jump.lock_round(13).is_empty() and jump.lock_round(0).is_empty(), "no round 0 or 13")


func _test_main_distribution() -> void:
	var counts := {KARERA: 0, LAGSANAY: 0, KANGAROO: 0}
	var total := 0
	for seed_value in range(1, 2001):
		for row in _table(_schedule(seed_value, _all_modes(), EventSchedule.enabled_pairs())):
			if bool(row.guaranteed):
				continue
			counts[int(row.main)] += 1
			total += 1
	var karera := float(counts[KARERA]) / total
	var lagsanay := float(counts[LAGSANAY]) / total
	var kangaroo := float(counts[KANGAROO]) / total
	_check(
		(
			absf(karera - 0.70) < 0.02
			and absf(lagsanay - 0.20) < 0.02
			and absf(kangaroo - 0.10) < 0.015
		),
		(
			"non-guaranteed rounds draw Karera/Lagsanay/Kangaroo near 70/20/10 (%.3f/%.3f/%.3f, n=%d)"
			% [karera, lagsanay, kangaroo, total]
		)
	)
	var without: Array[int] = [KARERA, LAGSANAY]
	var no_kangaroo := 0
	var karera_only := 0
	var samples := 0
	for seed_value in range(1, 1001):
		for row in _table(_schedule(seed_value, without, EventSchedule.enabled_pairs())):
			if bool(row.guaranteed):
				continue
			samples += 1
			no_kangaroo += 1 if int(row.main) == KANGAROO else 0
			karera_only += 1 if int(row.main) == KARERA else 0
	var renormalized := float(karera_only) / samples
	_check(
		no_kangaroo == 0 and absf(renormalized - 70.0 / 90.0) < 0.025,
		(
			"an unavailable mode's weight is zeroed, the rest renormalized (Karera %.3f of 0.778)"
			% renormalized
		)
	)


func _test_twist_rules() -> void:
	var early_twists := 0
	var guaranteed_twists := 0
	var self_stacks := 0
	var illegal := 0
	var lagsanay_main_twists := 0
	var bands := {5: [0, 0], 8: [0, 0], 11: [0, 0]}
	var karera_twists := {LAGSANAY: 0, KANGAROO: 0}
	var kangaroo_twists := {LAGSANAY: 0, KARERA: 0}
	for seed_value in range(1, 4001):
		for row in _table(_schedule(seed_value, _all_modes(), _all_pairs_enabled())):
			var round_number := int(row.round)
			var main := int(row.main)
			var twist := int(row.twist)
			if twist != NONE and round_number <= 4:
				early_twists += 1
			if twist != NONE and bool(row.guaranteed):
				guaranteed_twists += 1
			if twist != NONE and twist == main:
				self_stacks += 1
			if main == LAGSANAY and twist != NONE:
				lagsanay_main_twists += 1
			if main == KARERA and twist != NONE:
				karera_twists[twist] = int(karera_twists.get(twist, 0)) + 1
			if main == KANGAROO and twist != NONE:
				kangaroo_twists[twist] = int(kangaroo_twists.get(twist, 0)) + 1
			if (
				twist != NONE
				and not (
					(main == KARERA and twist in [LAGSANAY, KANGAROO])
					or (main == KANGAROO and twist == LAGSANAY)
				)
			):
				illegal += 1
			if bool(row.guaranteed) or main == LAGSANAY:
				continue
			var band := 5 if round_number <= 7 else (8 if round_number <= 10 else 11)
			if round_number < 5:
				continue
			bands[band][0] += 1
			bands[band][1] += 1 if twist != NONE else 0
	_check(early_twists == 0, "rounds 1–4 never roll a Twist")
	_check(guaranteed_twists == 0, "guaranteed rounds 4/8/12 stay standalone")
	_check(self_stacks == 0 and illegal == 0, "a Twist is always a different, listed partner")
	_check(
		lagsanay_main_twists == 0,
		"a Lagsanay Main has zero compatible options in the GDD table, so it never has a Twist"
	)
	var rates := PackedStringArray()
	var rates_ok := true
	for band in [5, 8, 11]:
		var expected := EventSchedule.twist_chance(band)
		var rate := float(bands[band][1]) / maxf(1.0, float(bands[band][0]))
		rates.append("%d+: %.3f (expect %.2f)" % [band, rate, expected])
		rates_ok = rates_ok and absf(rate - expected) < 0.02
	_check(rates_ok, "Twist rates follow the round bands when options exist: %s" % ", ".join(rates))
	var karera_total := int(karera_twists[LAGSANAY]) + int(karera_twists[KANGAROO])
	_check(
		karera_total > 0 and absf(float(karera_twists[LAGSANAY]) / karera_total - 0.5) < 0.06,
		"Karera's two compatible Twists are equally likely (%s)" % [karera_twists]
	)
	_check(
		int(kangaroo_twists[LAGSANAY]) > 0 and int(kangaroo_twists[KARERA]) == 0,
		"one compatible option: a Kangaroo Main's Twist is always Bomb-Taya"
	)
	var none_pairs: Array[Dictionary] = []
	var any_twist := false
	for seed_value in range(1, 301):
		for row in _table(_schedule(seed_value, _all_modes(), none_pairs)):
			any_twist = any_twist or int(row.twist) != NONE
	_check(not any_twist, "zero compatible options: a successful roll is a normal round")
	var self_pair: Array[Dictionary] = [
		{"main": KARERA, "twist": KARERA, "task": "test", "enabled": true}
	]
	var self_schedule := _schedule(1, _all_modes(), self_pair)
	_check(self_schedule.twist_options(KARERA).is_empty(), "a challenge never stacks with itself")
	var missing_twist_mode: Array[int] = [KARERA, LAGSANAY]
	var missing := _schedule(1, missing_twist_mode, _all_pairs_enabled())
	_check(
		missing.twist_options(KARERA) == [LAGSANAY],
		"an unavailable mode never enters the Twist pool"
	)
	var announce := {"main": KARERA, "twist": LAGSANAY}
	_check(
		EventSchedule.describe(announce) == "KARERA / TWIST: BOMB-TAYA",
		"announcement text shows the Main first and the Twist below it (KARERA / TWIST: BOMB-TAYA)"
	)


func _test_no_mixed_modes() -> void:
	var stale_pairs: Array[Dictionary] = [
		{"main": KARERA, "twist": LAGSANAY, "enabled": true},
		{"main": KANGAROO, "twist": LAGSANAY, "enabled": true},
	]
	var no_mixed := true
	for seed_value in range(1, 101):
		for row in _table(_schedule(seed_value, _all_modes(), stale_pairs)):
			no_mixed = no_mixed and int(row.twist) == NONE
	_check(no_mixed, "100 seeds ignore stale compatibility rows and never schedule a Twist")
	var forced := {"main": KARERA, "twist": LAGSANAY}
	_check(
		EventSchedule.mode_ids(forced) == PackedStringArray(["karera"]),
		"stale mixed entry item eligibility normalizes to its standalone Main"
	)
	_check(EventSchedule.describe(forced) == "KARERA", "stale mixed entry labels only its Main")
	_check(
		EventSchedule.enabled_pairs().is_empty(), "the normal runtime has no enabled mixed pairs"
	)


func _test_required_mode_refusal() -> void:
	var no_lagsanay: Array[int] = [KARERA, KANGAROO]
	var refused := _schedule(1, no_lagsanay, EventSchedule.enabled_pairs())
	_check(
		refused.error.contains("LAGSANAY") and refused.lock_round(2).is_empty(),
		(
			"a missing Lagsanay refuses the schedule instead of rescheduling as Karera: %s"
			% refused.error
		)
	)
	var no_karera: Array[int] = [LAGSANAY, KANGAROO]
	var refused_karera := _schedule(1, no_karera, EventSchedule.enabled_pairs())
	_check(refused_karera.error.contains("KARERA"), "a missing Karera refuses round 1")
	var short_match := _schedule(1, no_lagsanay, EventSchedule.enabled_pairs(), 3)
	_check(
		short_match.error.contains("sudden death"),
		"even a 3-round match needs Lagsanay for sudden death: %s" % short_match.error
	)
	var no_kangaroo: Array[int] = [KARERA, LAGSANAY]
	var optional := _schedule(1, no_kangaroo, EventSchedule.enabled_pairs())
	_check(optional.error.is_empty(), "Kangaroo is optional for the schedule")
	var no_stream := EventSchedule.new()
	_check(
		not no_stream.begin(null, _all_modes(), 12).is_empty(), "a schedule needs a seeded stream"
	)


## P23: standalone race Kangaroo never creates overlapping commands or Storm volleys.
func _test_kangaroo_sequential_lifecycle() -> void:
	var tuning := GameplayTuning.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 41
	var controller := KangarooRoundController.new()
	var seats: Array[int] = [0, 1, 2, 3]
	var no_contacts: Array[Dictionary] = []
	_check(
		controller.begin("p23:sequential", seats, {}, rng, tuning, 0.0), "sequential fixture begins"
	)
	var now := 0.0
	var tick := 1
	var max_active := 0
	while now < 45.0:
		now += 1.0 / 60.0
		tick += 1
		controller.advance_to(now, tick, {}, null, no_contacts)
		max_active = maxi(max_active, controller.active_commands().size())
	_check(
		controller.slippers_completed >= 3,
		"successive slipper commands complete on the active simulation clock"
	)
	_check(max_active <= 1, "the command controller exposes at most one active challenge")
	_check(
		controller.command_history.all(
			func(row: Dictionary) -> bool: return not bool(row.is_storm)
		),
		"Storm is absent from the standalone command sequence"
	)


## Regression (2026-10-15): resetting the controller cleared the room's own actor map (it kept a
## reference from the last step), so a second Kangaroo round in one match had no chickens.
func _test_kangaroo_reset_keeps_room_actors() -> void:
	var controller := KangarooRoundController.new()
	var rng := RandomNumberGenerator.new()
	var seats: Array[int] = [0, 1]
	var room_actors := {0: Node.new(), 1: Node.new()}
	var no_contacts: Array[Dictionary] = []
	controller.begin("p12:actors:1", seats, {}, rng, GameplayTuning.new(), 0.0)
	controller.advance_to(0.5, 1, room_actors, null, no_contacts)
	controller.begin("p12:actors:2", seats, {}, rng, GameplayTuning.new(), 0.0)
	controller.reset()
	_check(
		room_actors.size() == 2, "beginning or resetting a Kangaroo round keeps the room's actors"
	)
	for actor in room_actors.values():
		(actor as Node).free()


func _pending_storms(controller: KangarooRoundController) -> int:
	var count := 0
	for command in controller.command_history:
		if bool(command.is_storm) and not bool(command.evaluated):
			count += 1
	return count


## A base seed whose match includes Kangaroo, a non-guaranteed Lagsanay and a Bomb-Taya round.
func _seed_with_events(probe: P12ScheduledMatchRoom) -> int:
	for base_seed in range(1, 500):
		var streams := SeededDiagnosticStreams.new()
		streams.seed_all(probe._derive_match_seed(base_seed, probe.match_run_id + 1))
		var schedule := EventSchedule.new()
		schedule.begin(streams.event, _all_modes(), 12)
		var kangaroo := false
		var extra_lagsanay := false
		var twist := false
		for row in _table(schedule):
			kangaroo = kangaroo or int(row.main) == KANGAROO
			extra_lagsanay = (
				extra_lagsanay or (int(row.main) == LAGSANAY and not bool(row.guaranteed))
			)
			twist = twist or int(row.twist) == LAGSANAY
		if kangaroo and extra_lagsanay and twist:
			return base_seed
	return 12345


func _open_room(players: int) -> Array[int]:
	room = ROOM_SCENE.instantiate() as P12ScheduledMatchRoom
	root.add_child(room)
	await process_frame
	await physics_frame
	room.set_match_seed(_seed_with_events(room))
	var seats: Array[int] = [room.join_keyboard("K1"), room.join_keyboard("K2")]
	for device_id in [7101, 7102].slice(0, players - 2):
		var seat_index := room.input_router.registry.join_gamepad(device_id)
		seats.append(seat_index)
		room.input_router.seat_joined.emit(seat_index)
	for seat_index in seats:
		room.input_router.registry.set_ready(seat_index, true)
	return seats


func _speed_up_tuning() -> void:
	var tuning := room.tuning
	tuning.match_target_score_units = 100000
	tuning.match_results_advance_seconds = 600.0
	tuning.lagsanay_opening_head_start_seconds = 0.2
	tuning.lagsanay_taya_seconds_2p = 0.5
	tuning.lagsanay_taya_seconds_3p = 0.5
	tuning.lagsanay_taya_seconds_4p = 0.5
	tuning.kangaroo_telegraph_seconds = 0.1
	tuning.kangaroo_response_seconds = 1.0
	tuning.kangaroo_reset_seconds = 0.05
	tuning.kangaroo_storm_after_commands = 2


func _test_full_scheduled_match(players: int) -> void:
	var seats := await _open_room(players)
	_check(room.start_match(), "%dp: the scheduled match starts" % players)
	if players == 2:
		var runtime_tuning := room.tuning as GameplayTuning
		_check(
			(
				runtime_tuning.match_pugad_seconds == 15.0
				and runtime_tuning.match_race_hard_cap_seconds == 120.0
				and runtime_tuning.match_race_after_first_finish_seconds == 30.0
				and runtime_tuning.lagsanay_taya_seconds_2p == 20.0
				and runtime_tuning.lagsanay_taya_seconds_3p == 25.0
				and runtime_tuning.lagsanay_taya_seconds_4p == 30.0
				and runtime_tuning.kangaroo_telegraph_seconds == 2.0
				and runtime_tuning.kangaroo_response_seconds == 6.0
				and runtime_tuning.kangaroo_reset_seconds == 1.5
				and runtime_tuning.kangaroo_storm_after_commands == 16
				and runtime_tuning.kangaroo_response_min_seconds == 3.0
				and runtime_tuning.kangaroo_reset_min_seconds == 0.75
				and runtime_tuning.kangaroo_storm_min_after_commands == 16
				and runtime_tuning.kangaroo_storm_min_active_seconds == 3.0
				and runtime_tuning.kangaroo_storm_min_landing_seconds == 1.5
				and runtime_tuning.kangaroo_storm_active_seconds >= 3.0
				and runtime_tuning.kangaroo_storm_landing_seconds == 1.5
			),
			(
				"2p: normal scheduled runtime snapshot uses the provisional timer defaults "
				+ "before test acceleration"
			)
		)
		_check(
			not room.bomb_taya.active and not room.kangaroo_round.controller.twist_role,
			"2p: a started match has no secondary mixed-mode controller"
		)
	_speed_up_tuning()
	var announced := {}
	var played := PackedStringArray()
	var mismatches := PackedStringArray()
	var mode_counts := {KARERA: 0, LAGSANAY: 0, KANGAROO: 0}
	var twist_rounds := 0
	var scoring_ok := true
	var lifecycle_ok := true
	var pause_taya_checked := false
	var pause_kangaroo_checked := false
	for active_round in range(1, 13):
		if room.phase_controller.phase != MatchPhaseController.Phase.PUGAD:
			mismatches.append("round %d did not reach Pugad" % active_round)
			break
		var now := room.current_entry()
		if room.actors.size() != players:
			mismatches.append("round %d has %d actors" % [active_round, room.actors.size()])
		if announced.has(active_round) and announced[active_round] != now:
			mismatches.append(
				"round %d announced %s, plays %s" % [active_round, announced[active_round], now]
			)
		var banner := room.round_announcement()
		var upcoming := room.schedule.entry_for(active_round + 1)
		if active_round < 12:
			announced[active_round + 1] = upcoming.duplicate()
			var expected_title := (
				"NEXT • ROUND %d: %s"
				% [active_round + 1, EventSchedule.main_name(int(upcoming.main))]
			)
			if str(banner.get("title", "")) != expected_title:
				mismatches.append("round %d banner %s" % [active_round, banner])
		elif not str(banner.get("title", "")).begins_with("FINAL ROUND 12"):
			mismatches.append("round 12 banner %s" % [banner])
		if active_round == 1:
			# process_frame fires before nodes process; the presenter applies on the next one.
			await process_frame
			await process_frame
			var overlay := room.presenter.pugad_overlay
			_check(
				overlay._announce.visible and overlay._announce.title_text() == str(banner.title),
				(
					"%dp: the Pugad banner shows the locked next round (%s / %s)"
					% [players, banner.get("title", ""), banner.get("detail", "")]
				)
			)
		room._finish_pugad_timeout()
		var empty_edits: Array[Dictionary] = []
		room._resolve_place_edits(empty_edits)
		var main := int(now.main)
		mode_counts[main] += 1
		if int(now.get("twist", NONE)) != NONE:
			twist_rounds += 1
			if room.play_twist_text() != "TWIST: BOMB-TAYA" or not room.bomb_taya.active:
				mismatches.append("round %d Twist not running" % active_round)
		if (
			room.event_main != main
			or room.phase_controller.phase != MatchPhaseController.Phase.PLAY
		):
			mismatches.append(
				"round %d Play runs %d, expected %d" % [active_round, room.event_main, main]
			)
		if room.play_challenge_text() != EventSchedule.main_name(main).capitalize():
			mismatches.append(
				"round %d HUD challenge %s" % [active_round, room.play_challenge_text()]
			)
		var before := room.cumulative_score_units.duplicate()
		if main in [KARERA, KANGAROO]:
			_check_goal_live(active_round, true, mismatches)
			await _finish_race_round([seats[0]])
		else:
			_check_goal_live(active_round, false, mismatches)
			if players == 2 and main == LAGSANAY and not pause_taya_checked:
				await physics_frame
				var taya_clock := room.lagsanay_controller.simulation_clock
				var taya_head_start := room.lagsanay_controller.head_start_remaining
				var taya_countdown := room.lagsanay_controller.countdown_remaining
				room.pause_coordinator.set_paused("P21 timer pause check", -1)
				await process_frame
				var taya_paused := room.get_tree().paused
				await room.get_tree().create_timer(0.12, true).timeout
				_check(
					(
						taya_paused
						and room.lagsanay_controller.simulation_clock == taya_clock
						and room.lagsanay_controller.head_start_remaining == taya_head_start
						and room.lagsanay_controller.countdown_remaining == taya_countdown
					),
					"2p: pause freezes the Lagsanay active clock, head start and taya countdown"
				)
				room.pause_coordinator.external_menu = true
				room.pause_coordinator.resume_countdown_seconds = 0.0
				_check(room.pause_coordinator.request_resume(), "P21: Lagsanay pause can resume")
				room.pause_coordinator._process(0.0)
				pause_taya_checked = true
			if main == KANGAROO:
				if players == 2 and not pause_kangaroo_checked:
					await physics_frame
					var command_clock := room.kangaroo_round.controller.active_time()
					room.pause_coordinator.set_paused("P21 timer pause check", -1)
					await process_frame
					var kangaroo_paused := room.get_tree().paused
					await room.get_tree().create_timer(0.12, true).timeout
					_check(
						(
							kangaroo_paused
							and room.kangaroo_round.controller.active_time() == command_clock
						),
						"2p: pause freezes the Kangaroo challenge clock"
					)
					room.pause_coordinator.external_menu = true
					room.pause_coordinator.resume_countdown_seconds = 0.0
					_check(
						room.pause_coordinator.request_resume(), "P21: Kangaroo pause can resume"
					)
					room.pause_coordinator._process(0.0)
					pause_kangaroo_checked = true
			var frames := 0
			while (
				room.phase_controller.phase == MatchPhaseController.Phase.PLAY
				and frames < MAX_EVENT_FRAMES
			):
				await physics_frame
				frames += 1
			if frames >= MAX_EVENT_FRAMES:
				mismatches.append("round %d %d never ended" % [active_round, main])
				break
			var result := room.last_resolution
			for seat_index in seats:
				var expected := (
					int(before.get(seat_index, 0))
					+ int(result.get("awards_units", {}).get(seat_index, 0))
				)
				if result.has("totals_units"):
					expected = int(result.totals_units[seat_index])
				scoring_ok = scoring_ok and room.cumulative_score_units[seat_index] == expected
			var model := room.last_results_model
			# Round 12 ends the match, so the final screen replaces the per-round model.
			if active_round < 12 and (model == null or model.round_number != active_round):
				mismatches.append("round %d results model missing" % active_round)
		played.append("R%d %s" % [active_round, EventSchedule.main_name(main)])
		lifecycle_ok = lifecycle_ok and room.lifecycle.completed_round == active_round
		if active_round < 12:
			if room.phase_controller.phase != MatchPhaseController.Phase.RESULTS:
				mismatches.append("round %d did not show Results" % active_round)
				break
			room._start_next_round()
	print("P12_MATCH players=%d seed=%d %s" % [players, room.base_match_seed, ", ".join(played)])
	_check(
		mismatches.is_empty(),
		(
			"%dp: all 12 rounds play the announced Main Challenge: %s"
			% [players, mismatches.slice(0, 4)]
		)
	)
	_check(
		int(mode_counts[LAGSANAY]) >= 3 and int(mode_counts[KANGAROO]) >= 1,
		(
			"%dp: the match ran Karera %d, Lagsanay %d, Kangaroo %d rounds"
			% [players, mode_counts[KARERA], mode_counts[LAGSANAY], mode_counts[KANGAROO]]
		)
	)
	_check(scoring_ok, "%dp: event rounds commit their placement scores to the match" % players)
	_check(lifecycle_ok, "%dp: every round ends through the match lifecycle" % players)
	_check(
		room.shows_final_results() or room._sudden_death_active,
		"%dp: round 12 ends the match (final results or sudden death)" % players
	)
	_check(
		twist_rounds == 0,
		"%dp: no Karera round starts the retired Bomb-Taya Twist controller" % [players]
	)
	room.queue_free()
	await process_frame


## Idle chickens can pass every Freeze and Hug forever; seats that keep holding a run input
## fail each Freeze, so the round reaches its last survivor through the real controller.
func _hold_run_input(holding: Array) -> void:
	for seat_index in holding:
		room.kangaroo_round.record_input_edge(
			int(seat_index), "right", "synthetic:right", true, Time.get_ticks_usec()
		)


func _check_goal_live(active_round: int, live: bool, mismatches: PackedStringArray) -> void:
	if room.goal_area.monitoring != live or room.goal_area.visible != live:
		mismatches.append("round %d goal live=%s" % [active_round, room.goal_area.monitoring])


func _finish_race_round(winning_seats: Array[int]) -> void:
	var controller := room.race_round_controller
	var candidates: Array[Dictionary] = []
	var tick := Engine.get_physics_frames()
	for seat_index in winning_seats:
		(
			candidates
			. append(
				{
					"round_id": controller.ledger.round_id,
					"seat_index": seat_index,
					"kind": "goal",
					"event_id": "%s:synthetic-goal:%d" % [controller.ledger.round_id, seat_index],
					"physics_tick": tick,
				}
			)
		)
	room.tuning.match_race_hard_cap_seconds = 0.002
	controller.hard_cap_seconds = 0.002
	controller.post_first_finish_seconds = 0.002
	var step := controller.advance_step(0.01, tick, candidates)
	room._apply_race_outcomes(step.new_outcomes)
	room._finish_race(str(step.end_reason))
	await process_frame
	await physics_frame


func _test_room_refuses_missing_mode() -> void:
	await _open_room(2)
	var without: Array[int] = [KARERA, KANGAROO]
	room.available_modes = without
	_check(not room.start_match(), "the room refuses to start without Lagsanay")
	_check(
		(
			room.phase_controller.phase == MatchPhaseController.Phase.LOBBY
			and room.last_message.contains("LAGSANAY")
		),
		"the refusal returns to the lobby with the reason: %s" % room.last_message
	)
	room.queue_free()
	await process_frame

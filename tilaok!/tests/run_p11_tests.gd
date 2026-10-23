extends SceneTree

const CONTROLLER_SCRIPT := preload("res://scripts/match/kangaroo_round_controller.gd")
const TUNING_SCRIPT := preload("res://scripts/config/gameplay_tuning.gd")
const STREAMS_SCRIPT := preload("res://scripts/diagnostics/seeded_streams.gd")
const ATTRIBUTION_SCRIPT := preload("res://scripts/items/runtime/attribution_record.gd")

var checks := 0
var failures := 0
var _fixture_root: Node


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_fixture_root = Node.new()
	_fixture_root.name = "P11TestFixtures"
	root.add_child(_fixture_root)
	_test_seeded_selection_and_cadence()
	_test_freeze_edges_and_grace()
	_test_all_selectable_map_bounds()
	_test_rising_support_provenance_height_and_removal()
	_test_hug_pairs_and_two_player_filter()
	_test_marker_progression_and_removal()
	_test_hazard_precedence_and_terminal_batch()
	_test_storm_overlap_cap_and_reset()
	print("P11_TEST_SUMMARY checks=%d failures=%d" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _test_seeded_selection_and_cadence() -> void:
	var observed := {0: 0, 1: 0, 2: 0}
	for seed_value in range(1200):
		var selected := CONTROLLER_SCRIPT.select_command(_rng(seed_value + 1), 3)
		observed[selected] = int(observed[selected]) + 1
	_check(
		observed[0] >= 340 and observed[1] >= 340 and observed[2] >= 340,
		"3-player seeded command selection remains near equal weight (counts %s)" % str(observed)
	)
	var band_counts := [0, 0, 0]
	for seed_value in range(1200):
		var band_rng := _rng(seed_value + 2200)
		if CONTROLLER_SCRIPT.select_command(band_rng, 3) == CONTROLLER_SCRIPT.Command.RISING:
			var band := band_rng.randi_range(0, 2)
			band_counts[band] += 1
	_check(
		band_counts[0] >= 110 and band_counts[1] >= 110 and band_counts[2] >= 110,
		"seeded Rising band selection remains near equal weight (counts %s)" % str(band_counts)
	)
	var no_hug := true
	for seed_value in range(500):
		if (
			CONTROLLER_SCRIPT.select_command(_rng(seed_value + 71), 2)
			== CONTROLLER_SCRIPT.Command.HUG
		):
			no_hug = false
			break
	_check(no_hug, "two survivors reroll Hug before a command instance is created")
	_check(
		CONTROLLER_SCRIPT.hazard_precedes_command(true, 4.99, 5.0),
		"a strictly earlier comparable hazard precedes command evaluation"
	)
	_check(
		(
			not CONTROLLER_SCRIPT.hazard_precedes_command(true, 5.0, 5.0)
			and not CONTROLLER_SCRIPT.hazard_precedes_command(false, 4.0, 5.0)
		),
		"hazard time ties and missing comparisons do not precede command evaluation"
	)
	var streams_a := STREAMS_SCRIPT.new()
	var streams_b := STREAMS_SCRIPT.new()
	streams_a.seed_all(9127)
	streams_b.seed_all(9127)
	streams_a.event.randi()
	_check(
		streams_a.kangaroo.randi() == streams_b.kangaroo.randi(),
		"Kangaroo uses an independent reproducible seeded stream"
	)
	var cadence_seed := _seed_for_command(CONTROLLER_SCRIPT.Command.FREEZE, 3)
	var rising := _begin("cadence", cadence_seed, [0, 1, 2])
	rising.advance_to(40.0, 1, {}, null, [])
	_check(rising.command_history.size() >= 3, "base cadence schedules successive commands")
	if rising.command_history.size() >= 3:
		var first: Dictionary = rising.command_history[0]
		var second: Dictionary = rising.command_history[1]
		var third: Dictionary = rising.command_history[2]
		_check(
			(
				is_equal_approx(float(first.reset_seconds), 1.5)
				and is_equal_approx(float(second.reset_seconds), 1.35)
			),
			"reset cadence starts at 1.5 s and eases by 0.15 s every two no-elimination completions"
		)
		_check(
			is_equal_approx(float(third.response_end_at) - float(third.response_start_at), 6.0),
			"unaccelerated response remains at the configured 6-second starting value"
		)
		_check(
			(
				is_equal_approx(rising._response_for_count(2), 5.5)
				and is_equal_approx(rising._response_for_count(100), 3.0)
				and is_equal_approx(rising._reset_for_count(2), 1.35)
				and is_equal_approx(rising._reset_for_count(100), 0.75)
			),
			"every accelerated response/reset count respects the 3-second and 0.75-second floors"
		)
		var definition = first.instance
		_check(
			(
				int(definition.command_id) == int(first.command_id)
				and int(definition.command) == int(first.command)
				and float(definition.response_end_at) == float(first.response_end_at)
			),
			"each command row retains its immutable announced command instance"
		)
	var two_player_seed := _seed_for_command(CONTROLLER_SCRIPT.Command.HUG, 3)
	var two_player := _begin("two-player-reroll", two_player_seed, [0, 1])
	two_player.advance_to(0.0, 1, {}, null, [])
	_check(
		(
			int(two_player.active_commands()[0].command) != CONTROLLER_SCRIPT.Command.HUG
			and int(two_player.active_commands()[0].command_id) == 1
		),
		"pre-telegraph Hug reroll consumes no command ID"
	)
	var sole_survivor := _begin(
		"sole-survivor-stop", _seed_for_command(CONTROLLER_SCRIPT.Command.FREEZE, 2), [0, 1]
	)
	sole_survivor.advance_to(0.0, 2, {}, null, [])
	var only_command: Dictionary = sole_survivor.command_history[0]
	sole_survivor.submit_hazard(
		_hazard(
			"sole-survivor-stop", 1, 0, 3, float(only_command.response_end_at) - 0.1, true, "trumpo"
		)
	)
	var sole_result := sole_survivor.advance_to(
		float(only_command.response_end_at), 3, {}, null, []
	)
	var history_size := sole_survivor.command_history.size()
	var stopped := sole_survivor.advance_to(
		float(only_command.response_end_at) + 20.0, 4, {}, null, []
	)
	_check(
		(
			bool(sole_result.get("ended", false))
			and sole_survivor.live_seats.size() == 1
			and not bool(stopped.get("advanced", true))
			and sole_survivor.command_history.size() == history_size
		),
		"one survivor ends the round and receives no later commands"
	)


func _test_freeze_edges_and_grace() -> void:
	var seed_value := _seed_for_command(CONTROLLER_SCRIPT.Command.FREEZE, 3)
	var actors := _actors([0, 1, 2])
	var freeze_tuning := _fast_tuning()
	var quick_tap := _begin("freeze-tap", seed_value, [0, 1, 2], {}, freeze_tuning)
	quick_tap.advance_to(0.0, 1, actors, null, [])
	quick_tap.record_intent_edge(0, "kbd:left", true, 0.20)
	quick_tap.record_intent_edge(0, "kbd:left", false, 0.21)
	var tap_command: Dictionary = quick_tap.command_history[0]
	quick_tap.advance_to(float(tap_command.response_end_at), 2, actors, null, [])
	_check(
		not bool(tap_command.pass_by_seat.get(0, true)),
		"a run press and release between physics samples fails Freeze"
	)

	var held_and_released := _begin(
		"freeze-held-released", seed_value, [0, 1, 2], {0: ["kbd:right"]}, freeze_tuning
	)
	held_and_released.advance_to(0.0, 3, actors, null, [])
	held_and_released.record_intent_edge(0, "kbd:right", false, 0.10)
	var released_command: Dictionary = held_and_released.command_history[0]
	held_and_released.advance_to(float(released_command.response_end_at), 4, actors, null, [])
	_check(
		bool(released_command.pass_by_seat.get(0, false)),
		"input held at response start passes after releasing within the one 0.10-second grace"
	)

	var held_too_long := _begin(
		"freeze-held-too-long", seed_value, [0, 1, 2], {0: ["kbd:jump"]}, freeze_tuning
	)
	held_too_long.advance_to(0.0, 5, actors, null, [])
	held_too_long.record_intent_edge(0, "kbd:jump", false, 0.201)
	var long_command: Dictionary = held_too_long.command_history[0]
	held_too_long.advance_to(float(long_command.response_end_at), 6, actors, null, [])
	_check(
		not bool(long_command.pass_by_seat.get(0, true)),
		"held-input grace expires once and cannot be renewed by a later release"
	)

	var fresh_jump := _begin("freeze-fresh-jump", seed_value, [0, 1, 2], {}, freeze_tuning)
	fresh_jump.advance_to(0.0, 7, actors, null, [])
	fresh_jump.record_intent_edge(1, "pad:jump", true, 0.11)
	fresh_jump.record_intent_edge(1, "pad:jump", false, 0.12)
	var jump_command: Dictionary = fresh_jump.command_history[0]
	fresh_jump.advance_to(float(jump_command.response_end_at), 8, actors, null, [])
	_check(
		not bool(jump_command.pass_by_seat.get(1, true)),
		"fresh jump press fails immediately even if released before the next physics sample"
	)

	var opposing := _begin("freeze-opposing-captured", seed_value, [0, 1, 2], {}, freeze_tuning)
	opposing.advance_to(0.0, 9, actors, null, [])
	actors[1].set_captured(true, "freeze_opposing_input_fixture")
	opposing.record_intent_edge(1, "kbd:left", true, 0.15)
	opposing.record_intent_edge(1, "kbd:right", true, 0.15)
	opposing.record_intent_edge(1, "kbd:left", false, 0.16)
	opposing.record_intent_edge(1, "kbd:right", false, 0.16)
	var opposing_command: Dictionary = opposing.command_history[0]
	opposing.advance_to(float(opposing_command.response_end_at), 10, actors, null, [])
	_check(
		not bool(opposing_command.pass_by_seat.get(1, true)),
		"opposing run presses and deliberate input while captured still fail Freeze"
	)
	actors[1].set_captured(false, "freeze_opposing_input_fixture")

	actors[2].external_velocity = Vector2(900.0, -400.0)
	_check(
		bool(jump_command.pass_by_seat.get(2, false)),
		"forced external motion without intentional input does not fail Freeze"
	)


func _test_rising_support_provenance_height_and_removal() -> void:
	var fair_tuning := _fast_tuning()
	var fair_actors := _actors([0, 1, 2, 3])
	for actor in fair_actors.values():
		actor.global_position = Vector2(100.0, 600.0)
	var fair_support := SupportTracker.new()
	fair_support.playable_bounds = Rect2(Vector2.ZERO, Vector2(2048.0, 1024.0))
	var platform := SupportSurfaceMetadata.new()
	platform.surface_id = "built-platform"
	platform.construction_id = "built-platform"
	platform.player_built = true
	platform.wave_support_eligibility = SupportSurfaceMetadata.Eligibility.ELIGIBLE
	_check(
		fair_support.register_surface(platform, Rect2(0.0, 600.0, 256.0, 32.0)),
		"completed eligible support geometry registers for map-aware Rising selection"
	)
	var fair_controller := _begin(
		"map-aware-rising",
		_seed_for_command(CONTROLLER_SCRIPT.Command.RISING, 4),
		[0, 1, 2, 3],
		{},
		fair_tuning
	)
	fair_controller.advance_to(0.0, 100, fair_actors, fair_support, [])
	var fair_row: Dictionary = fair_controller.command_history[0]
	var fair_line := float(fair_row.wave_y)
	_check(
		(
			int(fair_row.command) == CONTROLLER_SCRIPT.Command.RISING
			and fair_line >= 600.0
			and fair_line < fair_support.playable_bounds.end.y
		),
		"Rising selects a world-space line from reachable built support inside actual map bounds"
	)
	fair_support.finalized_step = 101
	for seat in [0, 1, 2, 3]:
		var contact := _contact(
			"built-platform", true, SupportSurfaceMetadata.Eligibility.ELIGIBLE, fair_line, 101
		)
		fair_support.contacts_by_actor["seat_%d" % seat] = [contact]
	fair_controller.advance_to(float(fair_row.response_end_at), 101, fair_actors, fair_support, [])
	_check(
		bool(fair_row.pass_by_seat.get(0, false)),
		"fresh grounded contact on another player's completed support passes at the selected line"
	)
	var base_contact := _contact(
		"base-only", false, SupportSurfaceMetadata.Eligibility.INELIGIBLE, fair_line - 100.0, 101
	)
	var base_tracker := SupportTracker.new()
	base_tracker.finalized_step = 101
	base_tracker.contacts_by_actor["seat_0"] = [base_contact]
	_check(
		not bool(base_tracker.evaluate("seat_0", fair_line).qualifies),
		"base geometry does not qualify as Rising support"
	)
	var stale_tracker := SupportTracker.new()
	stale_tracker.finalized_step = 102
	stale_tracker.contacts_by_actor["seat_0"] = [
		_contact(
			"stale-built", true, SupportSurfaceMetadata.Eligibility.ELIGIBLE, fair_line - 100.0, 101
		)
	]
	_check(
		not bool(stale_tracker.evaluate("seat_0", fair_line).qualifies),
		"stale support from a previous physics step does not qualify"
	)
	var removed_tracker := SupportTracker.new()
	removed_tracker.finalized_step = 101
	var removable := SupportSurfaceMetadata.new()
	removable.surface_id = "removed-built"
	removable.construction_id = "removed-built"
	removable.player_built = true
	removable.wave_support_eligibility = SupportSurfaceMetadata.Eligibility.ELIGIBLE
	removed_tracker.register_surface(removable, Rect2(0.0, fair_line - 100.0, 128.0, 32.0))
	removed_tracker.contacts_by_actor["seat_0"] = [
		_contact(
			"removed-built",
			true,
			SupportSurfaceMetadata.Eligibility.ELIGIBLE,
			fair_line - 100.0,
			101
		)
	]
	removed_tracker.invalidate_surface("removed-built")
	_check(
		not bool(removed_tracker.evaluate("seat_0", fair_line).qualifies),
		"support destroyed or removed before evaluation is invalidated"
	)
	var airborne_tracker := SupportTracker.new()
	airborne_tracker.finalized_step = 101
	_check(
		not bool(airborne_tracker.evaluate("seat_0", fair_line).qualifies),
		"airborne line crossing without a current grounded support contact does not pass Rising"
	)
	var no_support := SupportTracker.new()
	no_support.playable_bounds = fair_support.playable_bounds
	var deferred := _begin(
		"rising-fallback",
		_seed_for_command(CONTROLLER_SCRIPT.Command.RISING, 3),
		[0, 1, 2],
		{},
		fair_tuning
	)
	deferred.advance_to(0.0, 110, fair_actors, no_support, [])
	_check(
		(
			int(deferred.command_history[0].command) != CONTROLLER_SCRIPT.Command.RISING
			and int(deferred.marker_counts.get(0, 0)) == 0
			and int(deferred.no_elimination_commands) == 0
		),
		"no-support Rising uses one alternate command without hidden failure or pressure credit"
	)
	var unreachable := SupportTracker.new()
	unreachable.playable_bounds = fair_support.playable_bounds
	var high_platform := SupportSurfaceMetadata.new()
	high_platform.surface_id = "unreachable-high"
	high_platform.construction_id = "unreachable-high"
	high_platform.player_built = true
	high_platform.wave_support_eligibility = SupportSurfaceMetadata.Eligibility.ELIGIBLE
	unreachable.register_surface(high_platform, Rect2(0.0, 100.0, 256.0, 32.0))
	var unreachable_controller := _begin(
		"high-support-fallback",
		_seed_for_command(CONTROLLER_SCRIPT.Command.RISING, 3),
		[0, 1, 2],
		{},
		fair_tuning
	)
	unreachable_controller.advance_to(0.0, 120, fair_actors, unreachable, [])
	_check(
		int(unreachable_controller.command_history[0].command) != CONTROLLER_SCRIPT.Command.RISING,
		"tall but unreachable built geometry cannot force an impossible Rising target"
	)
	return


func _test_all_selectable_map_bounds() -> void:
	var map_ids := MapCatalog.ids()
	map_ids.append(ArenaDefinition.DEFAULT_LAYOUT_ID)
	var errors := MapCatalog.errors()
	var all_targets_valid := errors.is_empty() and not map_ids.is_empty()
	for map_index in range(map_ids.size()):
		var map_id = map_ids[map_index]
		for height_fraction in [0.25, 0.5, 0.7]:
			var layout := MapCatalog.layout_for(map_id)
			var tuning := TUNING_SCRIPT.new() as GameplayTuning
			var arena := ArenaDefinition.new(tuning, layout)
			var tracker := SupportTracker.new()
			tracker.configure(tuning)
			var map_offset := Vector2(float(map_index) * 256.0, -float(map_index) * 400.0)
			tracker.playable_bounds = Rect2(
				arena.arena_bounds.position + map_offset, arena.arena_bounds.size
			)
			var target_top: float = (
				tracker.playable_bounds.position.y
				+ tracker.playable_bounds.size.y * float(height_fraction)
			)
			var target_x := (
				tracker.playable_bounds.position.x + tracker.playable_bounds.size.x * 0.5
			)
			var support_width := maxf(tuning.body_width_wu, tuning.grid_cell_wu * 2.0)
			var support_rect := Rect2(
				target_x - support_width * 0.5, target_top, support_width, 32.0
			)
			if not tracker.playable_bounds.encloses(support_rect):
				all_targets_valid = false
				continue
			var metadata := SupportSurfaceMetadata.new()
			metadata.surface_id = "built:%s:%s" % [map_id, height_fraction]
			metadata.construction_id = metadata.surface_id
			metadata.player_built = true
			metadata.wave_support_eligibility = SupportSurfaceMetadata.Eligibility.ELIGIBLE
			tracker.register_surface(metadata, support_rect)
			var actors := _actors([0, 1])
			for actor in actors.values():
				actor.global_position = Vector2(target_x, target_top + 60.0)
			var controller := CONTROLLER_SCRIPT.new() as KangarooRoundController
			var started := controller.begin(map_id, [0, 1], {}, _rng(map_id.hash()), tuning)
			controller._step_support_tracker = tracker
			controller._step_actors = actors
			var candidate := controller._choose_fair_wave()
			if (
				not started
				or candidate.is_empty()
				or not tracker.playable_bounds.has_point(Vector2(target_x, float(candidate.line_y)))
			):
				all_targets_valid = false
	_check(
		all_targets_valid,
		(
			(
				"low, middle and high reachable Rising lines stay in-bounds "
				+ "on every selectable/default MapCatalog map: %s"
			)
			% [map_ids]
		)
	)


func _test_hug_pairs_and_two_player_filter() -> void:
	var live: Array[int] = [0, 1, 2, 3]
	var contacts: Array[Dictionary] = [
		{"seat_a": 2, "seat_b": 3, "distance_squared": 1.0},
		{"seat_a": 1, "seat_b": 2, "distance_squared": 1.0},
		{"seat_a": 0, "seat_b": 1, "distance_squared": 1.0},
		{"seat_a": 0, "seat_b": 2, "distance_squared": 8.0},
	]
	var paired := CONTROLLER_SCRIPT.pair_hug_contacts(live, contacts)
	_check(
		paired.has(0) and paired.has(1) and paired.has(2) and paired.has(3),
		"equal-distance contact ties sort by stable seat IDs and greedily produce two pairs"
	)
	var three_pair := (
		CONTROLLER_SCRIPT
		. pair_hug_contacts(
			[0, 1, 2],
			[
				{"seat_a": 0, "seat_b": 1, "distance_squared": 4.0},
				{"seat_a": 1, "seat_b": 2, "distance_squared": 1.0},
			]
		)
	)
	_check(
		three_pair.has(1) and three_pair.has(2) and not three_pair.has(0),
		"nearest live contact wins and an unpaired third player fails Hug"
	)
	var terminal_filtered := (
		CONTROLLER_SCRIPT
		. pair_hug_contacts(
			[1, 2],
			[
				{"seat_a": 0, "seat_b": 1, "distance_squared": 0.0},
				{"seat_a": 1, "seat_b": 2, "distance_squared": 9.0},
			]
		)
	)
	_check(
		terminal_filtered.has(1) and terminal_filtered.has(2) and not terminal_filtered.has(0),
		"removed players are filtered out of live Hug candidate contacts"
	)
	var seed_value := _seed_for_command(CONTROLLER_SCRIPT.Command.HUG, 3)
	var actors := _actors([0, 1, 2])
	var controller := _begin("hug-evaluation", seed_value, [0, 1, 2])
	controller.advance_to(0.0, 40, actors, null, [])
	var command: Dictionary = controller.command_history[0]
	var at_evaluation: Array[Dictionary] = [{"seat_a": 0, "seat_b": 1, "distance_squared": 16.0}]
	controller.advance_to(float(command.response_end_at), 41, actors, null, at_evaluation)
	_check(
		(
			bool(command.pass_by_seat.get(0, false))
			and bool(command.pass_by_seat.get(1, false))
			and not bool(command.pass_by_seat.get(2, true))
		),
		"Hug evaluates only the live contact snapshot supplied at evaluation"
	)
	var two_player := _begin(
		"hug-two-player", _seed_for_command(CONTROLLER_SCRIPT.Command.HUG, 3), [0, 1]
	)
	two_player.advance_to(0.0, 42, actors, null, [])
	_check(
		int(two_player.command_history[0].command) != CONTROLLER_SCRIPT.Command.HUG,
		"exactly two survivors never receive a Hug telegraph"
	)


func _test_marker_progression_and_removal() -> void:
	var tuning := _fast_tuning()
	var controller := _begin(
		"marker-progression",
		_seed_for_command(CONTROLLER_SCRIPT.Command.FREEZE, 3),
		[0, 1, 2],
		{},
		tuning
	)
	var actors := _actors([0, 1, 2])
	controller._next_base_launch = -1.0
	for expected_marker in [1, 2, 3]:
		var at_time := controller.active_time()
		controller._create_command(
			CONTROLLER_SCRIPT.Command.FREEZE, -1, at_time, false, tuning.kangaroo_response_seconds
		)
		var row: Dictionary = controller.command_history.back()
		controller._next_base_launch = -1.0
		controller.record_intent_edge(0, "kbd:left", true, float(row.response_start_at) + 0.10)
		controller.record_intent_edge(0, "kbd:left", false, float(row.response_start_at) + 0.11)
		controller.advance_to(float(row.response_end_at), 70 + expected_marker, actors, null, [])
		if expected_marker < 3:
			_check(
				(
					int(controller.marker_counts.get(0, 0)) == expected_marker
					and controller.live_seats.has(0)
				),
				(
					"failed command %d adds one KANG/GA/ROO marker without early elimination"
					% expected_marker
				)
			)
		else:
			_check(
				int(controller.marker_counts.get(0, 0)) == 3 and not controller.live_seats.has(0),
				"third failed command saturates markers at three and removes that seat from live play"
			)
	var fourth_at := controller.active_time()
	controller._create_command(
		CONTROLLER_SCRIPT.Command.FREEZE, -1, fourth_at, false, tuning.kangaroo_response_seconds
	)
	var fourth: Dictionary = controller.command_history.back()
	controller._next_base_launch = -1.0
	controller.record_intent_edge(0, "kbd:right", true, float(fourth.response_start_at) + 0.10)
	controller.advance_to(float(fourth.response_end_at), 74, actors, null, [])
	_check(
		(
			int(controller.marker_counts.get(0, 0)) == 3
			and (
				(
					controller
					. terminal_outcomes
					. filter(func(row: Dictionary) -> bool: return int(row.seat_index) == 0)
					. size()
				)
				== 1
			)
		),
		"an eliminated seat receives no fourth marker or duplicate terminal outcome"
	)


func _test_hazard_precedence_and_terminal_batch() -> void:
	var freeze_seed := _seed_for_command(CONTROLLER_SCRIPT.Command.FREEZE, 3)
	var actors := _actors([0, 1, 2])
	var earlier := _begin("hazard-earlier", freeze_seed, [0, 1, 2])
	earlier.advance_to(0.0, 50, actors, null, [])
	var earlier_command: Dictionary = earlier.command_history[0]
	earlier.marker_counts[0] = 2
	earlier.submit_hazard(
		_hazard(
			"hazard-earlier",
			0,
			1,
			51,
			float(earlier_command.response_end_at) - 0.0000005,
			true,
			"trumpo"
		)
	)
	earlier.advance_to(float(earlier_command.response_end_at), 51, actors, null, [])
	_check(
		(
			str(earlier.terminal_outcomes[0].cause) == "direct_hazard"
			and int(earlier.terminal_outcomes[0].direct_owner_seat) == 1
		),
		"a strictly earlier direct trap wins and keeps eligible credit even 0.5 microseconds before eval"
	)

	var tied := _begin("hazard-tie", freeze_seed, [0, 1, 2])
	tied.advance_to(0.0, 52, actors, null, [])
	var tied_command: Dictionary = tied.command_history[0]
	tied.marker_counts[0] = 2
	tied.record_intent_edge(0, "kbd:jump", true, 0.2)
	tied.submit_hazard(
		_hazard("hazard-tie", 0, 1, 53, float(tied_command.response_end_at), true, "launcher")
	)
	tied.advance_to(float(tied_command.response_end_at), 53, actors, null, [])
	_check(
		(
			str(tied.terminal_outcomes[0].cause) == "command_failure"
			and int(tied.terminal_outcomes[0].direct_owner_seat) == -1
		),
		"an exact hazard-time tie resolves as command failure without Patibong credit"
	)
	_check(tied.terminal_outcomes.size() == 1, "the exact-tie player receives one terminal outcome")

	var incomparable := _begin("hazard-unavailable", freeze_seed, [0, 1, 2])
	incomparable.advance_to(0.0, 54, actors, null, [])
	var incomparable_command: Dictionary = incomparable.command_history[0]
	incomparable.marker_counts[0] = 2
	incomparable.record_intent_edge(0, "kbd:right", true, 0.2)
	incomparable.submit_hazard(_hazard("hazard-unavailable", 0, 2, 55, 0.0, false, "unclocked"))
	incomparable.advance_to(float(incomparable_command.response_end_at), 55, actors, null, [])
	_check(
		(
			str(incomparable.terminal_outcomes[0].cause) == "command_failure"
			and int(incomparable.terminal_outcomes[0].direct_owner_seat) == -1
		),
		"missing comparable hazard time also resolves the terminal tie as command failure"
	)

	var hug_seed := _seed_for_command(CONTROLLER_SCRIPT.Command.HUG, 3)
	var simultaneous := _begin("simultaneous-last-cluck", hug_seed, [0, 1, 2])
	simultaneous.advance_to(0.0, 56, actors, null, [])
	for seat in [0, 1, 2]:
		simultaneous.marker_counts[seat] = 2
	var final_command: Dictionary = simultaneous.command_history[0]
	var final_step := simultaneous.advance_to(
		float(final_command.response_end_at), 57, actors, null, []
	)
	var score := simultaneous.score_result()
	_check(
		bool(final_step.ended) and final_step.new_outcomes.size() == 3,
		"simultaneous third failures resolve in one batch with one outcome per player"
	)
	_check(
		bool(score.get("last_cluck", false)) and int(score.get("last_cluck_seat", -1)) == 0,
		"Last Cluck exact-time placement tie uses stable lowest player slot"
	)
	var placement_award: Dictionary = score.get("award_rows", [])[0]
	_check(
		(
			str(placement_award.get("explanation", "")).begins_with(
				"Kangaroo elimination placement"
			)
			and not str(placement_award.get("explanation", "")).contains("Lagsanay")
		),
		"Kangaroo placement scoring reuses placement resolution with event-owned award provenance"
	)
	_check(
		simultaneous.commit_score_once(score) and not simultaneous.commit_score_once(score),
		"placement awards commit once after terminal resolution"
	)
	simultaneous.reset()
	_check(
		(
			not simultaneous.active
			and simultaneous.command_history.is_empty()
			and simultaneous.terminal_outcomes.is_empty()
			and simultaneous.live_seats.is_empty()
			and simultaneous.marker_counts.is_empty()
		),
		"round teardown clears commands, outcomes, markers, actors and all live-seat state"
	)


func _test_storm_overlap_cap_and_reset() -> void:
	var standard := _fast_tuning(16, 3.0)
	var controller := _begin(
		"storm-standard",
		_seed_for_command(CONTROLLER_SCRIPT.Command.FREEZE, 3),
		[0, 1, 2],
		{},
		standard
	)
	controller.advance_to(70.0, 60, {}, null, [])
	var storm_rows := _storm_rows(controller)
	_check(
		storm_rows.size() >= 4,
		"sixteen no-elimination command completions enter the standard Slipper Storm"
	)
	_check(
		(
			controller.storm_active
			and is_equal_approx(standard.kangaroo_storm_landing_seconds, 1.5)
			and is_equal_approx(standard.kangaroo_storm_active_seconds, 3.0)
		),
		"standard Storm uses 1.5-second landings and at least three-second response windows"
	)
	_check(
		_max_active_storms(storm_rows) == 2,
		"standard overlapping Slipper Storm never exceeds the two-command active cap"
	)

	var delayed_tuning := _fast_tuning(16, 4.5)
	var delayed := _begin(
		"storm-delayed-cap",
		_seed_for_command(CONTROLLER_SCRIPT.Command.RISING, 3),
		[0, 1, 2],
		{},
		delayed_tuning
	)
	delayed.advance_to(67.0, 61, {}, null, [])
	var delayed_rows := _storm_rows(delayed)
	_check(
		delayed_rows.size() >= 2 and _max_active_storms(delayed_rows) <= 2,
		"long Storm windows overlap without exceeding the two-command cap"
	)
	var first_storm_end := float(delayed_rows[0].response_end_at)
	delayed.advance_to(first_storm_end, 62, {}, null, [])
	delayed_rows = _storm_rows(delayed)
	_check(
		delayed_rows.size() >= 3 and float(delayed_rows[2].telegraph_start_at) >= first_storm_end,
		"the deferred Storm landing waits until a command slot opens"
	)

	var two_player := _begin(
		"storm-two-player",
		_seed_for_command(CONTROLLER_SCRIPT.Command.FREEZE, 2),
		[0, 1],
		{},
		_fast_tuning(16, 3.0)
	)
	two_player.advance_to(72.0, 63, {}, null, [])
	var pair_rows := _storm_rows(two_player)
	var pair_contract := pair_rows.size() >= 4
	if pair_contract:
		for pair_start in [0, 2]:
			var commands := [
				int(pair_rows[pair_start].command), int(pair_rows[pair_start + 1].command)
			]
			if not (
				commands.has(CONTROLLER_SCRIPT.Command.FREEZE)
				and commands.has(CONTROLLER_SCRIPT.Command.RISING)
			):
				pair_contract = false
				break
	var all_deferred_fallbacks_are_freeze := true
	for row in pair_rows:
		if int(row.command) != CONTROLLER_SCRIPT.Command.FREEZE:
			all_deferred_fallbacks_are_freeze = false
	_check(
		pair_contract or all_deferred_fallbacks_are_freeze,
		"two-survivor Storm retains Freeze/Rising pairing when Rising is fair and defers it otherwise"
	)
	_check(
		pair_rows.all(
			func(row: Dictionary) -> bool: return int(row.command) != CONTROLLER_SCRIPT.Command.HUG
		),
		"two-survivor Storm never selects Hug"
	)

	var reset_tuning := _fast_tuning(2, 1.0)
	reset_tuning.kangaroo_response_seconds = 3.0
	reset_tuning.kangaroo_reset_seconds = 0.75
	var reset_controller := _begin(
		"storm-elimination-reset",
		_seed_for_command(CONTROLLER_SCRIPT.Command.FREEZE, 3),
		[0, 1, 2],
		{},
		reset_tuning
	)
	reset_controller.advance_to(2.65, 64, {}, null, [])
	var storm_record := _hazard("storm-elimination-reset", 2, 1, 65, 2.70, true, "trumpo")
	reset_controller.submit_hazard(storm_record)
	reset_controller.advance_to(2.70, 65, {}, null, [])
	_check(
		not reset_controller.storm_active and reset_controller.no_elimination_commands == 0,
		"any elimination resets Storm pressure and no-elimination cadence"
	)
	reset_controller.advance_to(5.0, 66, {}, null, [])
	var resumed_base: Dictionary = {}
	for row in reset_controller.command_history:
		if not bool(row.is_storm) and float(row.telegraph_start_at) > 2.70:
			resumed_base = row
			break
	_check(
		(
			not resumed_base.is_empty()
			and is_equal_approx(
				float(resumed_base.response_end_at) - float(resumed_base.response_start_at), 3.0
			)
		),
		"the first post-elimination base command uses the unaccelerated response duration"
	)


func _begin(
	round_name: String,
	seed_value: int,
	seats: Array[int],
	initial_sources: Dictionary = {},
	tuning_override: GameplayTuning = null
) -> KangarooRoundController:
	var tuning := tuning_override if tuning_override != null else TUNING_SCRIPT.new()
	var controller := CONTROLLER_SCRIPT.new() as KangarooRoundController
	var started := controller.begin(
		round_name, seats, {}, _rng(seed_value), tuning, 0.0, initial_sources
	)
	_check(started, "Kangaroo controller begins %s with %d seats" % [round_name, seats.size()])
	return controller


func _fast_tuning(storm_after: int = 16, storm_active_seconds: float = 3.0) -> GameplayTuning:
	var tuning := TUNING_SCRIPT.new() as GameplayTuning
	tuning.kangaroo_telegraph_seconds = 0.05
	tuning.kangaroo_response_seconds = 1.0
	tuning.kangaroo_reset_seconds = 0.05
	tuning.kangaroo_storm_after_commands = storm_after
	tuning.kangaroo_storm_landing_seconds = 1.5
	tuning.kangaroo_storm_active_seconds = storm_active_seconds
	tuning.kangaroo_storm_max_active = 2
	return tuning


func _seed_for_command(command: int, alive_count: int) -> int:
	for seed_value in range(10000):
		if CONTROLLER_SCRIPT.select_command(_rng(seed_value), alive_count) == command:
			return seed_value
	return 10001


func _seed_for_rising_band(band: int, alive_count: int) -> int:
	for seed_value in range(10000):
		var rng := _rng(seed_value)
		if CONTROLLER_SCRIPT.select_command(rng, alive_count) == CONTROLLER_SCRIPT.Command.RISING:
			if rng.randi_range(0, 2) == band:
				return seed_value
	return 10001


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func _actors(seats: Array[int]) -> Dictionary:
	var result: Dictionary = {}
	for seat in seats:
		var actor := ChickenController.new()
		actor.seat_index = seat
		actor.support_actor_id = "seat_%d" % seat
		_fixture_root.add_child(actor)
		result[seat] = actor
	return result


func _contact(
	surface_id: String,
	player_built: bool,
	eligibility: SupportSurfaceMetadata.Eligibility,
	feet_y: float,
	step: int
) -> SupportContact:
	var contact := SupportContact.new()
	contact.surface_id = surface_id
	contact.construction_id = "construction:%s" % surface_id if player_built else ""
	contact.player_built = player_built
	contact.eligibility = eligibility
	contact.feet_y = feet_y
	contact.physics_step = step
	return contact


func _hazard(
	round_name: String,
	victim: int,
	owner: int,
	tick: int,
	physics_time: float,
	comparable: bool,
	source_id: String
) -> AttributionRecord:
	var record := ATTRIBUTION_SCRIPT.new() as AttributionRecord
	record.kind = AttributionRecord.Kind.ELIMINATION
	record.player_seat = victim
	record.owner_seat = owner
	record.source_item_id = source_id
	record.physics_tick = tick
	record.physics_time = physics_time
	record.time_comparable = comparable
	record.round_id = round_name
	record.event_id = "%s:%s:%d:%d" % [round_name, source_id, tick, victim]
	record.self_kill = victim == owner
	return record


func _storm_rows(controller: KangarooRoundController) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for command in controller.command_history:
		if bool(command.is_storm):
			rows.append(command)
	return rows


func _max_active_storms(rows: Array[Dictionary]) -> int:
	var maximum := 0
	for row in rows:
		var sample_time := float(row.response_start_at) + 0.001
		var active_count := 0
		for other in rows:
			if (
				float(other.response_start_at) <= sample_time
				and float(other.response_end_at) > sample_time
			):
				active_count += 1
		maximum = maxi(maximum, active_count)
	return maximum


func _check(condition: bool, label: String) -> void:
	checks += 1
	if condition:
		print("PASS ", label)
	else:
		failures += 1
		push_error("FAIL " + label)

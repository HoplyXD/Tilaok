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
	var rising_seed := _seed_for_command(CONTROLLER_SCRIPT.Command.RISING, 3)
	var rising := _begin("cadence", rising_seed, [0, 1, 2])
	rising.advance_to(9.35, 1, {}, null, [])
	_check(rising.command_history.size() >= 3, "base cadence schedules successive commands")
	if rising.command_history.size() >= 3:
		var first: Dictionary = rising.command_history[0]
		var second: Dictionary = rising.command_history[1]
		var third: Dictionary = rising.command_history[2]
		_check(
			(
				is_equal_approx(float(first.reset_seconds), 0.75)
				and is_equal_approx(float(second.reset_seconds), 0.60)
			),
			"reset cadence eases by 0.15 seconds every two no-elimination completions"
		)
		_check(
			is_equal_approx(float(third.response_end_at) - float(third.response_start_at), 2.5),
			"response cadence eases by 0.5 seconds after two completed commands"
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
	var tuning := _fast_tuning()
	_check(
		(
			is_equal_approx(TUNING_SCRIPT.new().kangaroo_wave_middle_low_y_wu, 768.0)
			and is_equal_approx(TUNING_SCRIPT.new().kangaroo_wave_middle_y_wu, 576.0)
			and is_equal_approx(TUNING_SCRIPT.new().kangaroo_wave_middle_high_y_wu, 384.0)
		),
		"Rising middle-low, middle and middle-high use the scaled 768/576/384 wu lines"
	)
	var seed_value := _seed_for_command(CONTROLLER_SCRIPT.Command.RISING, 4)
	var actors := _actors([0, 1, 2, 3])
	var support := SupportTracker.new()
	support.finalized_step = 21
	var first_command := _begin("rising-support", seed_value, [0, 1, 2, 3], {}, tuning)
	first_command.advance_to(0.0, 20, actors, support, [])
	var row: Dictionary = first_command.command_history[0]
	var line := float(row.wave_y)
	var built_on_line := _contact(
		"built", true, SupportSurfaceMetadata.Eligibility.ELIGIBLE, line + 1.0, 21
	)
	var base_above_line := _contact(
		"base", false, SupportSurfaceMetadata.Eligibility.ELIGIBLE, line - 100.0, 21
	)
	var built_below_line := _contact(
		"too_low", true, SupportSurfaceMetadata.Eligibility.ELIGIBLE, line + 1.1, 21
	)
	var stale_built := _contact(
		"stale", true, SupportSurfaceMetadata.Eligibility.ELIGIBLE, line - 100.0, 20
	)
	var ineligible_built := _contact(
		"ineligible", true, SupportSurfaceMetadata.Eligibility.INELIGIBLE, line - 100.0, 21
	)
	support.contacts_by_actor["seat_0"] = [built_on_line]
	support.contacts_by_actor["seat_1"] = [base_above_line]
	support.contacts_by_actor["seat_2"] = [built_below_line]
	support.contacts_by_actor["seat_3"] = [stale_built]
	first_command.advance_to(float(row.response_end_at), 21, actors, support, [])
	_check(
		bool(row.pass_by_seat.get(0, false)),
		"current player-built support qualifies at the line plus the one-wu numerical tolerance"
	)
	_check(
		(
			not bool(row.pass_by_seat.get(1, true))
			and not bool(row.pass_by_seat.get(2, true))
			and not bool(row.pass_by_seat.get(3, true))
		),
		"base geometry, support below the line and stale prior-step support all fail Rising"
	)
	var ineligible_support := SupportTracker.new()
	ineligible_support.finalized_step = 21
	ineligible_support.contacts_by_actor["ineligible_actor"] = [ineligible_built]
	_check(
		not bool(ineligible_support.evaluate("ineligible_actor", line).get("qualifies", false)),
		"player-built support with ineligible wave metadata fails Rising"
	)
	_check(
		(
			int(row.band) >= 0
			and float(row.wave_y) == CONTROLLER_SCRIPT.wave_y_for_band(tuning, int(row.band))
		),
		"the selected world-space line remains fixed instead of rerolling an impossible layout"
	)
	var every_band_passes := true
	for band in range(3):
		var band_controller := _begin(
			"rising-band-%d" % band, _seed_for_rising_band(band, 3), [0, 1, 2], {}, tuning
		)
		band_controller.advance_to(0.0, 50 + band * 2, actors, null, [])
		var band_row: Dictionary = band_controller.command_history[0]
		var band_support := SupportTracker.new()
		band_support.finalized_step = 51 + band * 2
		var other_player_build := _contact(
			"other-player-build-%d" % band,
			true,
			SupportSurfaceMetadata.Eligibility.ELIGIBLE,
			float(band_row.wave_y) + 20.0,
			50 + band * 2
		)
		band_support.contacts_by_actor["seat_0"] = [other_player_build]
		other_player_build.feet_y = float(band_row.wave_y) - 0.1
		other_player_build.physics_step = 51 + band * 2
		other_player_build.construction_id = "other-player-build:%d" % band
		band_controller.advance_to(
			float(band_row.response_end_at), 51 + band * 2, actors, band_support, []
		)
		if int(band_row.band) != band or not bool(band_row.pass_by_seat.get(0, false)):
			every_band_passes = false
	_check(
		every_band_passes,
		"all three selected bands accept current support after it moves above the line on evaluation"
	)

	var removal_support := SupportTracker.new()
	removal_support.finalized_step = 31
	var removed := _begin("rising-removal", seed_value, [0, 1, 2], {}, tuning)
	removed.advance_to(0.0, 30, actors, removal_support, [])
	var removed_row: Dictionary = removed.command_history[0]
	var removable_contact := _contact(
		"removed",
		true,
		SupportSurfaceMetadata.Eligibility.ELIGIBLE,
		float(removed_row.wave_y) - 50.0,
		31
	)
	removal_support.contacts_by_actor["seat_0"] = [removable_contact]
	removal_support.invalidate_surface("removed")
	removed.advance_to(float(removed_row.response_end_at), 31, actors, removal_support, [])
	_check(
		not bool(removed_row.pass_by_seat.get(0, true)),
		"a support removed before evaluation is absent from the current support record"
	)

	var drain_controller := _begin("rising-drain", seed_value, [0, 1, 2], {}, tuning)
	drain_controller.advance_to(0.0, 60, actors, null, [])
	var drain_row: Dictionary = drain_controller.command_history[0]
	var drain_end := float(drain_row.response_end_at)
	drain_controller.advance_to(drain_end, 61, actors, null, [])
	var draining_rows := drain_controller.presentation_commands(drain_end)
	var clear_rows := drain_controller.presentation_commands(
		drain_end + float(drain_row.reset_seconds)
	)
	var drain_shown := false
	for presentation_row in draining_rows:
		if int(presentation_row.command) == CONTROLLER_SCRIPT.Command.RISING:
			drain_shown = str(presentation_row.status) == "DRAIN"
	var drain_cleared := true
	for presentation_row in clear_rows:
		if int(presentation_row.command) == CONTROLLER_SCRIPT.Command.RISING:
			drain_cleared = false
	_check(
		drain_shown and drain_cleared,
		"Rising exposes a drain presentation after evaluation and clears it when reset ends"
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
	var standard := _fast_tuning(8, 1.0)
	var controller := _begin(
		"storm-standard",
		_seed_for_command(CONTROLLER_SCRIPT.Command.FREEZE, 3),
		[0, 1, 2],
		{},
		standard
	)
	controller.advance_to(10.5, 60, {}, null, [])
	var storm_rows := _storm_rows(controller)
	_check(
		storm_rows.size() >= 4,
		"eight no-elimination command completions enter the standard Slipper Storm"
	)
	_check(
		(
			controller.storm_active
			and is_equal_approx(standard.kangaroo_storm_landing_seconds, 0.5)
			and is_equal_approx(standard.kangaroo_storm_active_seconds, 1.0)
		),
		"standard Storm uses 0.5-second landing cadence and one-second active windows"
	)
	_check(
		_max_active_storms(storm_rows) == 2,
		"standard overlapping Slipper Storm never exceeds the two-command active cap"
	)

	var delayed_tuning := _fast_tuning(2, 1.25)
	var delayed := _begin(
		"storm-delayed-cap",
		_seed_for_command(CONTROLLER_SCRIPT.Command.RISING, 3),
		[0, 1, 2],
		{},
		delayed_tuning
	)
	delayed.advance_to(3.7, 61, {}, null, [])
	var delayed_rows := _storm_rows(delayed)
	_check(
		bool(delayed.storm_landing_pending) and _max_active_storms(delayed_rows) == 2,
		"synthetic longer-window stress reaches the cap and defers the next landing"
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
		_fast_tuning(2, 1.25)
	)
	two_player.advance_to(5.2, 63, {}, null, [])
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
	_check(pair_contract, "each two-survivor Storm pair contains seeded-order Freeze and Rising")
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


func _fast_tuning(storm_after: int = 8, storm_active_seconds: float = 1.0) -> GameplayTuning:
	var tuning := TUNING_SCRIPT.new() as GameplayTuning
	tuning.kangaroo_telegraph_seconds = 0.05
	tuning.kangaroo_response_seconds = 1.0
	tuning.kangaroo_reset_seconds = 0.05
	tuning.kangaroo_storm_after_commands = storm_after
	tuning.kangaroo_storm_landing_seconds = 0.5
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

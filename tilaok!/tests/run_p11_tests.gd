extends SceneTree

## P11 runner retained as the controller contract suite. P11 captures remain historical; these
## checks exercise the redesigned sequential command scheduler used by standalone race Kangaroo.

const CONTROLLER := preload("res://scripts/match/kangaroo_round_controller.gd")
const TUNING := preload("res://scripts/config/gameplay_tuning.gd")

var checks := 0
var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_equal_selection_and_hug_groups()
	_test_cadence_and_no_overlap()
	_test_hitch_does_not_catch_up()
	_test_wave_boundary_and_tuning()
	print("P11_TEST_SUMMARY checks=%d failures=%d" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _test_equal_selection_and_hug_groups() -> void:
	var counts := [0, 0, 0]
	for seed_value in range(1200):
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value + 1
		counts[CONTROLLER.select_command(rng, 2)] += 1
	_check(
		counts.min() > 300,
		"2-player command selection draws all three equally, including Hug (%s)" % str(counts)
	)
	var solo_never_hugs := true
	for seed_value in range(120):
		var solo_rng := RandomNumberGenerator.new()
		solo_rng.seed = seed_value + 1
		if CONTROLLER.select_command(solo_rng, 1) == CONTROLLER.Command.HUG:
			solo_never_hugs = false
	_check(solo_never_hugs, "sole runner command selection excludes Hug")
	var group := (
		CONTROLLER
		. pair_hug_contacts(
			[0, 1, 2, 3],
			[
				{"seat_a": 0, "seat_b": 1},
				{"seat_a": 1, "seat_b": 2},
				{"seat_a": 3, "seat_b": 4},
			]
		)
	)
	_check(
		group.keys().size() == 3 and not group.has(4),
		"Hug accepts chains and pairs independently and filters nonliving seats"
	)
	_check(
		CONTROLLER.pair_hug_contacts([0, 1], [{"seat_a": 0, "seat_b": 1}]).size() == 2,
		"two touching players both pass Hug"
	)
	_check(CONTROLLER.pair_hug_contacts([0, 1], []).is_empty(), "an isolated player fails Hug")


func _test_cadence_and_no_overlap() -> void:
	var tuning := TUNING.new()
	var controller := CONTROLLER.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	_check(
		controller.begin("seq", [0, 1, 2], {}, rng, tuning),
		"sequential controller initializes with a valid tuning snapshot"
	)
	var maximum_active := 0
	for frame in range(1, 2401):
		controller.advance_to(float(frame) / 60.0, frame, {}, null, [])
		maximum_active = maxi(maximum_active, controller.active_commands().size())
	_check(maximum_active <= 1, "no two telegraph or response commands overlap")
	_check(controller.slippers_completed >= 3, "successive challenges continue after recovery")
	_check(
		(
			is_equal_approx(controller._response_for_count(0), 6.0)
			and is_equal_approx(controller._response_for_count(1), 5.5)
			and is_equal_approx(controller._response_for_count(100), 3.0)
			and is_equal_approx(controller._reset_for_count(1), 1.35)
			and is_equal_approx(controller._reset_for_count(100), 0.75)
		),
		"response and recovery shorten every slipper and honor configured floors"
	)
	var ordered := true
	for index in range(1, controller.command_history.size()):
		var previous: Dictionary = controller.command_history[index - 1]
		var current: Dictionary = controller.command_history[index]
		if (
			float(current.telegraph_start_at) + 0.0001
			< float(previous.response_end_at) + float(previous.reset_seconds)
		):
			print("CADENCE_GAP previous=%s current=%s" % [str(previous), str(current)])
			ordered = false
	_check(ordered, "next slipper waits for the previous effect cleanup and recovery")
	_check(
		controller.command_history.all(
			func(row: Dictionary) -> bool: return not bool(row.is_storm)
		),
		"normal Kangaroo command history contains no Storm volleys"
	)
	var solo := CONTROLLER.new()
	var solo_rng := RandomNumberGenerator.new()
	solo_rng.seed = 77
	_check(
		solo.begin("solo-racer", [0], {}, solo_rng, tuning, 0.0, {}, true),
		"race controller accepts a sole unfinished runner"
	)
	solo.advance_to(2.2, 1, {}, null, [])
	var solo_commands := solo.active_commands()
	_check(
		(
			solo.active
			and solo.live_seats == [0]
			and solo_commands.size() == 1
			and int(solo_commands[0].command) != CONTROLLER.Command.HUG
		),
		"sole unfinished runner continues with Freeze/Rising and no Hug"
	)
	solo.reset()
	var ten_resets_clean := true
	for cycle in range(10):
		var cycle_rng := RandomNumberGenerator.new()
		cycle_rng.seed = cycle + 1
		if not solo.begin("reset-%d" % cycle, [0, 1], {}, cycle_rng, tuning):
			ten_resets_clean = false
			break
		solo.advance_to(0.1, cycle + 1, {}, null, [])
		solo.reset()
		ten_resets_clean = ten_resets_clean and not solo.active and solo.command_history.is_empty()
	_check(ten_resets_clean, "ten controller reset cycles leave no active command history")


func _test_hitch_does_not_catch_up() -> void:
	var controller := CONTROLLER.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	controller.begin("hitch", [0, 1], {}, rng, TUNING.new())
	controller.advance_to(5.0, 1, {}, null, [])
	var commands := controller.active_commands()
	_check(commands.size() == 1, "a delayed step starts at most one fresh slipper")
	if commands.size() == 1:
		_check(
			float(commands[0].response_start_at) >= 7.0,
			"a delayed step preserves the full 2-second telegraph instead of catching up"
		)
	controller.reset()


func _test_wave_boundary_and_tuning() -> void:
	var tuning := TUNING.new()
	_check(
		(
			is_equal_approx(tuning.kangaroo_freeze_duration_seconds, 2.0)
			and is_equal_approx(tuning.kangaroo_telegraph_seconds, 2.0)
			and is_equal_approx(tuning.kangaroo_response_seconds, 6.0)
		),
		"approved provisional Freeze, telegraph and response defaults are present"
	)
	_check(
		(
			CONTROLLER.wave_y_for_band(tuning, 0) > CONTROLLER.wave_y_for_band(tuning, 1)
			and CONTROLLER.wave_y_for_band(tuning, 1) > CONTROLLER.wave_y_for_band(tuning, 2)
		),
		"map-aware Rising target bands remain bounded and ordered"
	)
	_check(
		(
			CONTROLLER.rising_hitbox_clears(Rect2(0.0, 500.0, 10.0, 11.0), 510.0)
			and CONTROLLER.rising_hitbox_clears(Rect2(0.0, 501.0, 10.0, 10.0), 510.0)
			and not CONTROLLER.rising_hitbox_clears(Rect2(0.0, 501.01, 10.0, 10.0), 510.0)
		),
		"Rising checks the current full hitbox at the line with exactly 1-unit tolerance"
	)


func _check(condition: bool, label: String) -> void:
	checks += 1
	if condition:
		print("PASS ", label)
	else:
		failures += 1
		push_error("FAIL " + label)

extends SceneTree

## P13-T07 just-in-time Kangaroo prompts on the scheduled route: poses in the Pugad and built
## supports in the Place of the round before (or of) the first Kangaroo round, the three misses once
## its commands run, once per session, replayable, skippable, never saved to disk, and sharing the
## coach box with the Bomb-Taya prompt on a stacked round. Synthetic seats and input only.

const FLOW_SCENE := preload("res://scenes/flow/game_flow.tscn")
const KARERA := EventSchedule.Challenge.KARERA
const LAGSANAY := EventSchedule.Challenge.LAGSANAY
const KANGAROO := EventSchedule.Challenge.KANGAROO
const NONE := EventSchedule.Challenge.NONE
const SOURCE_FILES := [
	"res://scripts/tutorial/tutorial_coordinator.gd",
	"res://scripts/tutorial/tutorial_session.gd",
	"res://scripts/tutorial/tutorial_script.gd",
]
const FORBIDDEN_IO := ["FileAccess", "ConfigFile", "DirAccess", "user://", "ResourceSaver"]

var checks := 0
var failures := 0
var flow: GameFlow
var room: P12ScheduledMatchRoom


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_script_data()
	await _test_main_kangaroo_sequence()
	await _test_twist_and_stack()
	await _test_skip_and_replay()
	await _test_guided_match_keeps_its_steps()
	_test_no_disk_io()
	print("P13_TUTORIAL_TESTS checks=%d failures=%d" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _test_script_data() -> void:
	var script := load("res://data/ui/tutorial_script.tres") as TutorialScript
	_check(script != null and script.has_all_steps(), "the script has every step incl. Kangaroo")
	for step_id in TutorialScript.KANGAROO_STEPS:
		var step := script.step(step_id)
		_check(
			step != null and not step.body.is_empty() and not step.title.is_empty(),
			"%s has a title and body" % step_id
		)
	var lagsanay := script.step(TutorialScript.STEP_LAGSANAY)
	_check(
		lagsanay.variants.has("twist") and str(lagsanay.variants["twist"]).contains("Bomb-Taya"),
		"the taya step has a Bomb-Taya Twist wording"
	)
	var joined := ""
	for step_id in TutorialScript.KANGAROO_STEPS:
		joined += script.step(step_id).body
	_check(
		joined.contains("KANG") and joined.contains("GA") and joined.contains("ROO"),
		"the prompts name KANG, GA and ROO"
	)
	_check(
		joined.contains("FREEZE") and joined.contains("RISING WAVE") and joined.contains("HUG"),
		"the prompts name the three poses"
	)
	_check(joined.contains("built"), "the prompts explain built supports")


# --- a Kangaroo Main round ----------------------------------------------------------------------


func _test_main_kangaroo_sequence() -> void:
	await _open(true)
	_force(2, KANGAROO, NONE)
	var coach := flow.tutorial
	_check(coach != null, "the scheduled route attaches the coach")
	_check(_step(coach) == "kangaroo_poses", "the Pugad before the first Kangaroo shows the poses")
	_check(str(coach.view.body).contains("FREEZE"), "the poses prompt explains the commands")
	_goto_place()
	_check(_step(coach) == "kangaroo_supports", "its Place shows the built-support prompt")
	_check(str(coach.view.body).contains("Build UP"), "the supports prompt says to build up")
	_goto_play()
	_check(_step(coach) == "", "the Karera round before it shows no Kangaroo prompt")
	await _finish_round()
	await _next_round_to_play()
	_check(
		room.event_main == KANGAROO and room.kangaroo_round.controller.active,
		"round 2 runs the Kangaroo Main round"
	)
	_check(
		_step(coach) == "kangaroo_misses",
		"its Play shows the three-misses prompt (poses and supports were already seen)"
	)
	_check(str(coach.view.body).contains("KANG"), "the misses prompt names the marks")
	# Seen once: after the round the session holds all three and a later Kangaroo shows nothing.
	room._end_event_view()
	await _finish_kangaroo_round()
	for step_id in TutorialScript.KANGAROO_STEPS:
		_check(
			not flow.tutorial_session.kangaroo_step_due(step_id),
			"%s is marked seen after it was shown" % step_id
		)
	await _free()


# --- Twist and stacked rounds ------------------------------------------------------------------


func _test_twist_and_stack() -> void:
	await _open(true)
	_force(1, KANGAROO, LAGSANAY)
	var coach := flow.tutorial
	_goto_place()
	_goto_play()
	_check(room.bomb_taya.active and room.kangaroo_round.controller.active, "K + Bomb-Taya runs")
	_check(
		_step(coach) == "lagsanay" and str(coach.view.body).contains("Bomb-Taya"),
		"the taya prompt (Twist wording) shows first on a stacked round"
	)
	coach._on_twist_prompt_timeout()
	_check(
		_step(coach) == "kangaroo_misses",
		"after the hand-over the Kangaroo prompt takes its turn (%s)" % _step(coach)
	)
	await _free()
	# Karera + Kangaroo Twist: the Twist triggers the same prompts.
	await _open(true)
	_force(1, KARERA, KANGAROO)
	_goto_place()
	_goto_play()
	_check(room.kangaroo_round.controller.twist_role, "Kangaroo runs as a Twist on Karera")
	_check(
		_step(flow.tutorial) == "kangaroo_misses",
		"a Kangaroo Twist shows the misses prompt (supports shown in its Place)"
	)
	await _free()
	# Karera + Bomb-Taya: the taya prompt appears for a Twist (it could not before).
	await _open(true)
	_force(1, KARERA, LAGSANAY)
	_goto_place()
	_goto_play()
	_check(
		_step(flow.tutorial) == "lagsanay" and str(flow.tutorial.view.body).contains("flag"),
		"a Bomb-Taya Twist teaches the taya rules with the flag still winning"
	)
	await _free()


# --- skip, replay -------------------------------------------------------------------------------


func _test_skip_and_replay() -> void:
	await _open(true)
	_force(2, KANGAROO, NONE)
	flow.tutorial.skip()
	_check(_step(flow.tutorial) == "", "skipping the tutorial hides the Kangaroo prompts")
	_check(
		not flow.tutorial_session.kangaroo_step_due(TutorialScript.STEP_KANGAROO_POSES),
		"a skipped session never reports a prompt as due"
	)
	flow.tutorial_session.replay()
	_check(
		flow.tutorial_session.kangaroo_step_due(TutorialScript.STEP_KANGAROO_POSES),
		"replaying the tutorial makes the Kangaroo prompts due again"
	)
	_check(_step(flow.tutorial) == "kangaroo_poses", "and the poses prompt returns")
	await _free()


func _test_guided_match_keeps_its_steps() -> void:
	await _open(false)
	_force(2, KANGAROO, NONE)
	_check(
		_step(flow.tutorial) == "pugad",
		"during the guided first match the Pugad keeps the guided step (%s)" % _step(flow.tutorial)
	)
	await _free()


func _test_no_disk_io() -> void:
	for path in SOURCE_FILES:
		var text := FileAccess.get_file_as_string(path)
		for token in FORBIDDEN_IO:
			var hit := false
			for line in text.split("\n"):
				var stripped := line.strip_edges()
				if not stripped.begins_with("#") and stripped.contains(token):
					hit = true
			_check(not hit, "%s never uses %s" % [path.get_file(), token])


# --- harness ------------------------------------------------------------------------


## completed = the guided first match is already done (no tutorial stage, JIT prompts only).
func _open(completed: bool) -> void:
	flow = FLOW_SCENE.instantiate() as GameFlow
	flow.harness_mode = true
	flow.match_scene = GameFlow.LIFECYCLE_SCENE
	root.add_child(flow)
	await _frames(3)
	flow.match_scene = GameFlow.LIFECYCLE_SCENE
	if completed:
		flow.tutorial_session.completed = true
	flow.router.registry.join_keyboard("K1")
	flow.router.registry.join_keyboard("K2")
	flow._enter_match()
	await _frames(2)
	room = flow.room as P12ScheduledMatchRoom
	for seat in room.input_router.registry.joined_seats():
		room.input_router.registry.set_ready(int(seat.seat), true)
	room.start_match()
	await _frames(3)
	room.tuning.match_target_score_units = 100000
	room.tuning.match_results_advance_seconds = 600.0
	room.tuning.match_race_hard_cap_seconds = 600.0
	room.tuning.match_race_after_first_finish_seconds = 600.0
	_check(
		room.phase_controller.phase == MatchPhaseController.Phase.PUGAD, "the match is in the Pugad"
	)


func _force(round_number: int, main: int, twist: int) -> void:
	room.schedule.locked[round_number] = {
		"round": round_number,
		"main": main,
		"twist": twist,
		"guaranteed": false,
		"sudden_death": false,
		"twist_options": 0,
	}
	flow.tutorial.rebuild()


func _goto_place() -> void:
	room._finish_pugad_timeout()
	flow.tutorial.rebuild()


func _goto_play() -> void:
	var edits: Array[Dictionary] = []
	room._resolve_place_edits(edits)
	for seat in room.input_router.registry.joined_seats():
		var actor := room.actors[int(seat.seat)] as ChickenController
		actor.global_position = room.arena.controller_origin_from_feet(
			room.arena.spawn_feet + Vector2(220.0 * int(seat.seat), 0.0)
		)
	flow.tutorial.rebuild()


func _finish_round() -> void:
	var controller := room.race_round_controller
	var candidates: Array[Dictionary] = []
	var tick := Engine.get_physics_frames()
	for seat in room.input_router.registry.joined_seats():
		(
			candidates
			. append(
				{
					"round_id": controller.ledger.round_id,
					"seat_index": int(seat.seat),
					"kind": "goal",
					"event_id": "%s:goal:%d" % [controller.ledger.round_id, int(seat.seat)],
					"physics_tick": tick,
				}
			)
		)
	controller.hard_cap_seconds = 0.002
	controller.post_first_finish_seconds = 0.002
	var step := controller.advance_step(0.01, tick, candidates)
	room._apply_race_outcomes(step.new_outcomes)
	room._finish_race(str(step.end_reason))
	await _frames(2)


func _next_round_to_play() -> void:
	room._start_next_round()
	await _frames(2)
	room._finish_pugad_timeout()
	var edits: Array[Dictionary] = []
	room._resolve_place_edits(edits)
	await _frames(3)
	flow.tutorial.rebuild()


func _finish_kangaroo_round() -> void:
	# Ending the event round (the Kangaroo controller stops) closes the Play phase.
	room.phase_controller.enter(MatchPhaseController.Phase.RESULTS)
	await _frames(2)
	flow.tutorial.rebuild()


func _step(coach: TutorialCoordinator) -> String:
	return str(coach.view.get("step_id", "")) if bool(coach.view.get("visible", false)) else ""


func _free() -> void:
	if flow != null and is_instance_valid(flow):
		flow.queue_free()
	flow = null
	room = null
	paused = false
	await _frames(3)


func _frames(count: int) -> void:
	for _frame in count:
		await process_frame


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("P13_TUTORIAL FAIL: " + message)
	print("%s %s" % ["PASS" if condition else "FAIL", message])

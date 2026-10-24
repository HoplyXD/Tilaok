extends SceneTree

## P13-T07 just-in-time Kangaroo prompts on the scheduled route: poses in the Pugad and built
## supports in the Place of the round before (or of) the first Kangaroo round, the three misses once
## its commands run, once per session, replayable, skippable, never saved to disk, and sharing the
## coach box for standalone modes and ignores stale forced mixed entries.
## Synthetic seats and input only.

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
	await _test_barya_pugad_prompt()
	await _test_main_kangaroo_sequence()
	await _test_standalone_and_mixed_rejection()
	await _test_skip_and_replay()
	await _test_guided_match_keeps_its_steps()
	_test_per_seat_learning_memory()
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
		lagsanay.variants.is_empty(), "the standalone taya step has no retired mixed-mode variant"
	)
	var pugad := script.step(TutorialScript.STEP_PUGAD)
	_check(
		(
			pugad.variants.has("barya")
			and str(pugad.variants["barya"]).to_lower().contains("barya")
			and str(pugad.variants["barya"]).to_lower().contains("reach the flag")
		),
		"the Pugad coach has a Barya pickup and scoring explanation"
	)
	var live_build := script.step(TutorialScript.STEP_LIVE_BUILD)
	var preparation_copy := str(live_build.variants.get("preparation", ""))
	_check(
		(
			preparation_copy.contains("Place your item now or save it for play")
			and preparation_copy.contains("quiet until GO")
		),
		"preparation tutorial explains early build, saving the item and inert prepared hazards"
	)
	_check(
		str(script.step(TutorialScript.STEP_PLACE).body).contains("not the normal match loop"),
		"the developer placement route is explicitly separated from normal onboarding"
	)
	var joined := ""
	for step_id in TutorialScript.KANGAROO_STEPS:
		joined += script.step(step_id).body
	_check(
		joined.to_lower().contains("directly") and joined.to_lower().contains("eliminates"),
		"the prompts explain direct race elimination"
	)
	_check(
		(
			joined.to_lower().contains("freeze")
			and joined.to_lower().contains("rising")
			and joined.to_lower().contains("hug")
		),
		"the prompts name the three poses"
	)
	_check(
		joined.contains("bottom of its hitbox") and joined.contains("No platform is needed"),
		"the prompts explain the final Rising hitbox check without a support requirement"
	)


# --- a Kangaroo Main round ----------------------------------------------------------------------


func _test_barya_pugad_prompt() -> void:
	await _open(false)
	room.tuning.barya_enabled = true
	room.tuning.barya_offer_probability = 1.0
	room.schedule.locked[1] = {
		"round": 1,
		"main": KARERA,
		"twist": NONE,
		"guaranteed": true,
		"sudden_death": false,
		"twist_options": 0,
	}
	room._augment_pugad_egg_pool(2)
	flow.tutorial.rebuild()
	_check(
		(
			_step(flow.tutorial) == "pugad"
			and str(flow.tutorial.view.body).contains("The coin egg is Barya")
			and str(flow.tutorial.view.body).contains("+0.5")
		),
		"an enabled Pugad Barya offer changes the live coach copy"
	)
	_check(
		str(flow.tutorial.view.glyph).is_empty(),
		(
			"mixed keyboard seats use their own score-row controls instead of merged glyphs (%s)"
			% flow.tutorial.view.glyph
		)
	)
	await _free()


func _test_main_kangaroo_sequence() -> void:
	await _open(true)
	_force(2, KANGAROO, NONE)
	var coach := flow.tutorial
	_check(coach != null, "the scheduled route attaches the coach")
	_check(_step(coach) == "kangaroo_poses", "the Pugad before the first Kangaroo shows the poses")
	_check(
		str(coach.view.body).to_lower().contains("freeze"), "the poses prompt explains the commands"
	)
	_goto_place()
	_check(_step(coach) == "kangaroo_supports", "its Place shows the built-support prompt")
	_check(
		str(coach.view.body).contains("No platform is needed"),
		"the Rising prompt explains its final evaluation"
	)
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
		"its Play shows the race-outcomes prompt (poses and Rising were already seen)"
	)
	_check(
		(
			str(coach.view.body).to_lower().contains("pairs, groups and chains")
			and str(coach.view.body).to_lower().contains("hug is skipped")
		),
		"the Hug prompt explains group contact and sole-runner behavior"
	)
	# Seen once: after the round the session holds all three and a later Kangaroo shows nothing.
	room._end_event_view()
	await _finish_kangaroo_round()
	for step_id in TutorialScript.KANGAROO_STEPS:
		_check(
			not flow.tutorial_session.kangaroo_step_due(step_id),
			"%s is marked seen after it was shown" % step_id
		)
	await _free()


# --- standalone modes and stale mixed entries -------------------------------------------------


func _test_standalone_and_mixed_rejection() -> void:
	await _open(true)
	_force(1, KANGAROO, LAGSANAY)
	var coach := flow.tutorial
	_goto_place()
	_goto_play()
	_check(
		(
			room.event_main == KANGAROO
			and room.kangaroo_round.controller.active
			and not room.bomb_taya.active
		),
		"a stale Kangaroo + Lagsanay entry starts only its standalone Main"
	)
	_check(
		_step(coach) == "kangaroo_misses", "stale mixed input does not show a second taya prompt"
	)
	await _free()
	# A Lagsanay Main round: the taya prompt stays until the mode ends.
	await _open(true)
	_force(1, LAGSANAY, NONE)
	_goto_place()
	_goto_play()
	_check(_step(flow.tutorial) == "lagsanay", "a Lagsanay Main round shows the taya prompt")
	_check(
		_step(flow.tutorial) == "lagsanay" and not flow.tutorial_session.seen_lagsanay,
		"the taya prompt remains active without an elapsed-time dismissal"
	)
	await _free()
	# Karera + Kangaroo is normalized to the Karera Main.
	await _open(true)
	_force(1, KARERA, KANGAROO)
	_goto_place()
	_goto_play()
	_check(
		(
			room.event_main == KARERA
			and not room.kangaroo_round.controller.active
			and not room.kangaroo_round.controller.twist_role
		),
		"a stale Karera + Kangaroo entry cannot start a secondary controller"
	)
	await _free()
	# Karera + Bomb-Taya cannot start the tag controller or its tutorial.
	await _open(true)
	_force(1, KARERA, LAGSANAY)
	_goto_place()
	_goto_play()
	_check(
		(
			room.event_main == KARERA
			and not room.lagsanay_controller.active
			and not room.bomb_taya.active
			and room.play_twist_text().is_empty()
			and _step(flow.tutorial) != "lagsanay"
		),
		"a stale Karera + Bomb-Taya entry cannot start a second controller or prompt"
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


func _test_per_seat_learning_memory() -> void:
	var session := TutorialSession.new()
	for player_count in [2, 3, 4]:
		var seats: Array[int] = []
		for seat_index in player_count:
			seats.append(seat_index)
		session.replay()
		for seat_index in seats:
			session.mark_action_learned(&"preparation", seat_index)
			_check(
				not session.all_seats_learned(&"live_build", seats),
				(
					"preparation for seat %d does not imply live build for %d seats"
					% [seat_index, player_count]
				)
			)
		for seat_index in seats:
			session.mark_action_learned(&"live_build", seat_index)
		_check(
			(
				session.all_seats_learned(&"preparation", seats)
				and session.all_seats_learned(&"live_build", seats)
			),
			"all %d seats must learn both item paths" % player_count
		)
	session.replay()
	_check(session.learned_actions.is_empty(), "Replay clears per-seat lesson records")


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

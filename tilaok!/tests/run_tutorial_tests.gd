# gdlint: disable=max-file-lines
extends SceneTree

## Guided first-round tests: session memory, coordinator steps, stage selection, skip / replay,
## copy numbers, per-device glyphs, hide rules, display-only box, no disk writes. Synthetic input
## only; this is engineering evidence, not a novice session (P13-T08).

const FLOW_SCENE := preload("res://scenes/flow/game_flow.tscn")
const P09_SCENE := preload("res://scenes/match/p09_match_lifecycle_room.tscn")
const SCRIPT_PATH := "res://data/ui/tutorial_script.tres"
const FORBIDDEN_TOKENS := [
	"Control.new(",
	"add_theme_",
	"FileAccess",
	"ConfigFile",
	"DirAccess",
	"user://",
	"ResourceSaver",
]
const TUTORIAL_SOURCES := [
	"res://scripts/tutorial/tutorial_session.gd",
	"res://scripts/tutorial/tutorial_script.gd",
	"res://scripts/tutorial/tutorial_step_def.gd",
	"res://scripts/tutorial/tutorial_coordinator.gd",
	"res://scripts/tutorial/build_here_marker.gd",
	"res://scripts/ui/ui_tutorial_prompt.gd",
]
const GOAL_PHYSICS_FRAMES := 8

var checks := 0
var failures := 0
var flow: GameFlow
var _default_signature := ""
var _tutorial_signature := ""


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var user_before := _user_listing()
	var tuning := GameplayTuning.new()
	_default_signature = ArenaDefinition.new(tuning).arena_geometry_signature()
	_tutorial_signature = (
		ArenaDefinition
		. new(tuning, load("res://data/stage/tutorial_arena_layout.tres"))
		. arena_geometry_signature()
	)
	_test_script_resource()
	_test_session_memory()
	await _test_steps_through_a_round(2)
	await _test_everyone_finished_text(4)
	await _test_everyone_finished_text(3)
	await _test_pugad_and_place_timeouts()
	await _test_overlays_and_final_result_hide()
	await _test_nobody_finished_retry()
	await _test_copy_follows_tuning_and_devices()
	await _test_hide_rules_and_display_only()
	await _test_skip_and_replay_cycles()
	await _test_layout_is_per_match()
	await _test_lagsanay_prompt_once()
	await _test_lifecycle_replay_gets_default_stage()
	await _test_lifecycle_cycles()
	_test_source_rules()
	_check(_user_listing() == user_before, "nothing was created or changed under user://")
	print("TUTORIAL_TESTS checks=%d failures=%d" % [checks, failures])
	quit(1 if failures > 0 else 0)


# --- pure data --------------------------------------------------------------------------------


func _test_script_resource() -> void:
	var script := load(SCRIPT_PATH) as TutorialScript
	_check(script != null and script.has_all_steps(), "TutorialScript has every step")
	for step_id in [
		TutorialScript.STEP_WELCOME,
		TutorialScript.STEP_PUGAD,
		TutorialScript.STEP_PLACE,
		TutorialScript.STEP_KARERA,
		TutorialScript.STEP_RESULTS,
		TutorialScript.STEP_LAGSANAY,
	]:
		var step := script.step(step_id)
		_check(
			step != null and not step.title.is_empty() and not step.body.is_empty(),
			"%s has a title and body" % step_id
		)
	_check(
		script.step(TutorialScript.STEP_PLACE).retry_body.length() > 20,
		"Place has a stronger retry hint"
	)
	_check(script.placeholder_tag.begins_with("PLACEHOLDER"), "live copy is tagged PLACEHOLDER")


func _test_session_memory() -> void:
	var session := TutorialSession.new()
	_check(session.is_active() and session.wants_tutorial_layout(), "a new session is active")
	_check(session.lagsanay_prompt_due(), "the Lagsanay prompt is due in a new session")
	session.mark_lagsanay_seen()
	_check(not session.lagsanay_prompt_due(), "the Lagsanay prompt is not due twice")
	session.skip()
	_check(session.skipped and not session.wants_tutorial_layout(), "skip ends the tutorial")
	session.replay()
	_check(
		session.is_active() and session.lagsanay_prompt_due() and not session.skipped,
		"replay clears the whole session set"
	)
	session.mark_completed()
	_check(not session.is_active(), "completion ends the tutorial")
	session.replay()
	_check(session.is_active() and not session.completed, "replay after completion restarts")


# --- coordinator through the real flow --------------------------------------------------------


func _test_steps_through_a_round(seat_count: int) -> void:
	var room := await _room_in_lobby(seat_count)
	var coach := flow.tutorial
	var prompt := room.presenter.tutorial_prompt
	_check(
		(
			room.arena.layout_id == "tutorial"
			and room.arena.arena_geometry_signature() == _tutorial_signature
		),
		"the first match uses the tutorial layout"
	)
	_check(
		coach.view.step_id == TutorialScript.STEP_WELCOME and prompt.visible,
		"Lobby shows the welcome step"
	)
	var body := str(coach.view.body)
	var names_all := true
	for seat in room.input_router.registry.joined_seats():
		names_all = names_all and body.contains("%d %s" % [int(seat.identity), str(seat.shape)])
	_check(
		names_all and body.contains("1 CIRCLE"),
		"welcome names each seat's number and shape (%s)" % body
	)
	_start_match(room)
	await _wait_frames(3)
	_check(coach.view.step_id == TutorialScript.STEP_PUGAD, "Pugad shows the Pugad step")
	_check(str(coach.view.body).contains("8"), "Pugad copy carries the tuned 8 s")
	# One seat claims; any seat advancing is enough.
	_claim(room, 0)
	await _wait_physics_frames(3)
	_check(
		(
			coach.view.step_id == TutorialScript.STEP_PUGAD
			and str(coach.view.body).begins_with("Egg claimed")
		),
		"a claim switches the Pugad copy to 'claimed'"
	)
	_claim(room, 1, 1)
	await _wait_physics_frames(3)
	await _wait_frames(2)
	_check(room.phase_controller.phase == MatchPhaseController.Phase.PLACE, "both seats claimed")
	_check(coach.view.step_id == TutorialScript.STEP_PLACE, "Place shows the build step")
	var place_body := str(coach.view.body)
	_check(
		place_body.contains("7.5") and place_body.contains("3") and place_body.contains("15"),
		"Place copy carries ledge height, jump height and Place seconds (%s)" % place_body
	)
	_check(bool(coach.view.build_here), "Place requests the BUILD HERE marker")
	var marker := _marker(room)
	_check(
		marker != null and marker.visible and marker.zone == room.arena.build_here_zone,
		"the BUILD HERE marker sits on the layout's zone"
	)
	_check(int(coach.view.hint_level) == 1, "the first Place round uses the normal hint")
	# Confirm both ghosts; Play starts.
	room._confirm_placement(0)
	room._confirm_placement(1)
	await _wait_physics_frames(3)
	await _wait_frames(2)
	_check(room.phase_controller.phase == MatchPhaseController.Phase.PLAY, "confirms start Play")
	_check(coach.view.step_id == TutorialScript.STEP_KARERA, "Play shows the Karera step")
	var play_body := str(coach.view.body)
	_check(
		play_body.contains("60") and play_body.contains("15"),
		"Karera copy carries the 60 s cap and 15 s finish window (%s)" % play_body
	)
	_check(not marker.visible, "the BUILD HERE marker hides after Place")
	# Two seats reach the flag: with two players the waiver applies.
	await _teleport_all_to_goal(room)
	_check(room.phase_controller.phase == MatchPhaseController.Phase.RESULTS, "round ends")
	_check(coach.view.step_id == TutorialScript.STEP_RESULTS, "Results shows the results step")
	var model := room.last_results_model
	_check(
		(
			str(coach.view.body).contains(model.suppression_reason)
			and model.suppression_reason.contains("two-player waiver")
		),
		"the 2-player waiver text equals the real result (%s)" % coach.view.body
	)
	_check(str(coach.view.body).contains("8"), "Results copy carries the 8 s advance time")
	room._start_next_round()
	await _wait_frames(3)
	_check(flow.tutorial_session.completed, "a round with finishers completes the tutorial")
	_check(not prompt.visible, "the coach box hides once the tutorial is complete")
	_check(
		room.arena.layout_id == "tutorial",
		"completing does not change the stage mid-match (one map per match)"
	)
	await _free_flow()


func _test_everyone_finished_text(seat_count: int) -> void:
	var room := await _room_in_lobby(seat_count)
	var coach := flow.tutorial
	_start_match(room)
	await _wait_frames(2)
	await _to_play(room)
	await _teleport_all_to_goal(room)
	_check(room.phase_controller.phase == MatchPhaseController.Phase.RESULTS, "round ends")
	var model := room.last_results_model
	_check(
		(
			str(coach.view.body).begins_with("Everyone reached the flag")
			and str(coach.view.body).contains(model.suppression_reason)
		),
		"everyone finished: text matches the real no-score reason (%s)" % coach.view.body
	)
	await _free_flow()


func _test_pugad_and_place_timeouts() -> void:
	var room := await _room_in_lobby(2)
	var coach := flow.tutorial
	_start_match(room)
	await _wait_frames(2)
	# Only seat 0 claims; seat 1 is idle, so the timer must assign it an egg.
	_claim(room, 0)
	await _wait_physics_frames(3)
	_check(room.assignments.size() == 1, "one seat claimed, one idle")
	room._finish_pugad_timeout()
	await _wait_frames(3)
	_check(
		(
			room.phase_controller.phase == MatchPhaseController.Phase.PLACE
			and room.assignments.size() == 2
		),
		"the timer assigned the idle seat an egg"
	)
	_check(
		(
			coach.view.step_id == TutorialScript.STEP_PLACE
			and str(coach.view.body).begins_with("Time ran out")
		),
		"the Place step says an egg was assigned (%s)" % coach.view.body
	)
	# Only seat 0 confirms; Place ends on its timer and Play starts.
	room._confirm_placement(0)
	await _wait_frames(2)
	_check(
		room.phase_controller.phase == MatchPhaseController.Phase.PLACE,
		"one confirmation does not end Place"
	)
	room._finish_place_timeout()
	await _wait_physics_frames(3)
	await _wait_frames(2)
	_check(
		(
			room.phase_controller.phase == MatchPhaseController.Phase.PLAY
			and coach.view.step_id == TutorialScript.STEP_KARERA
		),
		"Place timeout starts Play on the Karera step"
	)
	await _free_flow()


func _test_overlays_and_final_result_hide() -> void:
	flow = FLOW_SCENE.instantiate() as GameFlow
	flow.match_scene = P09_SCENE
	root.add_child(flow)
	await _wait_frames(3)
	await _join_title()
	var room := flow.room
	_join_k2(room)
	_start_match(room)
	await _wait_frames(3)
	var coach := flow.tutorial
	var prompt := room.presenter.tutorial_prompt
	_check(prompt.visible, "the box is visible before any overlay")
	room._toggle_pause()
	await _wait_frames(3)
	room.presenter._open_overlay(load("res://scenes/ui/screens/settings_screen.tscn"))
	await _wait_frames(3)
	_check(not prompt.visible, "the box hides under the Settings overlay")
	room.presenter._close_overlay()
	room.presenter._open_overlay(load("res://scenes/ui/screens/library_screen.tscn"))
	await _wait_frames(3)
	_check(not prompt.visible, "the box hides under the Library overlay")
	room.presenter._close_overlay()
	room._toggle_pause()
	await _wait_frames(3)
	_check(prompt.visible, "the box returns after the overlays close")
	var life := room as P09MatchLifecycleRoom
	life.final_results_visible = true
	coach.rebuild()
	room.presenter._dirty = true
	await _wait_frames(3)
	_check(not prompt.visible, "the box hides on the final match result")
	life.final_results_visible = false
	await _free_flow()


func _test_nobody_finished_retry() -> void:
	var room := await _room_in_lobby(2)
	var coach := flow.tutorial
	_start_match(room)
	await _wait_frames(2)
	await _to_play(room)
	room.race_round_controller.elapsed_seconds = room.tuning.match_race_hard_cap_seconds - 0.001
	await _wait_physics_frames(4)
	await _wait_frames(3)
	_check(room.phase_controller.phase == MatchPhaseController.Phase.RESULTS, "cap ends the round")
	_check(coach.finisher_count() == 0, "nobody finished")
	var model := room.last_results_model
	_check(
		(
			str(coach.view.body).begins_with("Nobody reached the flag")
			and str(coach.view.body).contains(model.suppression_reason)
		),
		"nobody finished: text matches the real result (%s)" % coach.view.body
	)
	_check(not flow.tutorial_session.completed, "an unsolved round does not complete it")
	room._start_next_round()
	await _wait_frames(2)
	room.assignments = {0: str(room.egg_pool[0].egg_id), 1: str(room.egg_pool[1].egg_id)}
	room._enter_place()
	await _wait_frames(2)
	_check(
		coach.view.step_id == TutorialScript.STEP_PLACE and int(coach.view.hint_level) == 2,
		"step 3 repeats with the stronger hint"
	)
	_check(
		str(coach.view.body).begins_with("Nobody reached the flag."),
		"the retry copy is shown (%s)" % coach.view.body
	)
	var marker := _marker(room)
	_check(marker != null and marker.emphasised, "the marker adds the TRY A PIECE HERE hint")
	await _free_flow()


func _test_copy_follows_tuning_and_devices() -> void:
	var room := await _room_in_lobby(2)
	var coach := flow.tutorial
	room.tuning.match_pugad_seconds = 11.0
	_start_match(room)
	await _wait_frames(3)
	_check(
		str(coach.view.body).contains("11"),
		"changing match_pugad_seconds changes the copy (%s)" % coach.view.body
	)
	await _free_flow()
	room = await _room_in_lobby(1)
	coach = flow.tutorial
	_check(
		str(coach.view.glyph).contains("A / D") and not str(coach.view.glyph).contains("Left"),
		"one K1 seat shows K1 glyphs only (%s)" % coach.view.glyph
	)
	_join_k2(room)
	coach.rebuild()
	_check(
		str(coach.view.glyph).contains("A / D") and str(coach.view.glyph).contains("Left / Right"),
		"K1 + K2 shows both devices' glyphs (%s)" % coach.view.glyph
	)
	var pad := room.input_router.registry.join_gamepad(900)
	if pad >= 0:
		room.input_router.seat_joined.emit(pad)
	coach.rebuild()
	_check(
		str(coach.view.glyph).contains("D-pad"),
		"a gamepad seat adds its glyph (%s)" % coach.view.glyph
	)
	await _free_flow()


func _test_hide_rules_and_display_only() -> void:
	var room := await _room_in_lobby(2)
	var coach := flow.tutorial
	var prompt := room.presenter.tutorial_prompt
	_start_match(room)
	await _wait_frames(3)
	_check(prompt.visible, "the box is visible in Pugad")
	_check(prompt.is_live(), "the box is bound live")
	_check(
		room.presenter.bridge.screen != prompt,
		"the box is never attached to the input bridge (display only)"
	)
	_check(prompt.mouse_filter == Control.MOUSE_FILTER_IGNORE, "the box ignores the mouse")
	var consumed := prompt.back(0)
	_check(not consumed, "Back does nothing on a live box (no skip, no double activation)")
	_check(not flow.tutorial_session.skipped, "Back did not skip the tutorial")
	room._toggle_pause()
	await _wait_frames(3)
	_check(not prompt.visible and coach.suppressed, "the box hides while paused")
	_check(not _marker_visible(room), "the marker hides while paused")
	room._toggle_pause()
	await _wait_frames(3)
	room.presenter.confirm_overlay.visible = true
	room.presenter._dirty = true
	await _wait_frames(2)
	_check(not prompt.visible, "the box hides under a confirmation")
	room.presenter.confirm_overlay.visible = false
	room.presenter._dirty = true
	await _wait_frames(2)
	_check(prompt.visible, "the box returns after the confirmation")
	await _free_flow()


func _test_skip_and_replay_cycles() -> void:
	var room := await _room_in_lobby(2)
	var prompt := room.presenter.tutorial_prompt
	_start_match(room)
	await _wait_frames(3)
	var pause := room.presenter.pause_screen
	pause.skip_tutorial_requested.emit()
	await _wait_frames(3)
	_check(flow.tutorial_session.skipped and not prompt.visible, "Skip hides the box")
	_check(room.arena.layout_id == "tutorial", "skipping mid-match keeps the stage")
	# Next match is a normal one.
	flow._on_flow_requested(&"leave_match")
	await _wait_frames(3)
	var next_room := flow.room
	_check(
		next_room.arena.arena_geometry_signature() == _default_signature,
		"after a skip the next match uses the default stage signature"
	)
	_check(flow.tutorial.view.get("visible", true) == false, "no coach box in the skipped session")
	# Replay clears the set: the match after that is guided again.
	flow.tutorial_session.replay()
	flow._on_flow_requested(&"leave_match")
	await _wait_frames(3)
	_check(flow.room.arena.layout_id == "tutorial", "replay makes the next match a tutorial match")
	flow.tutorial_session.skip()
	flow.tutorial_session.replay()
	flow._on_flow_requested(&"leave_match")
	await _wait_frames(3)
	_check(
		flow.room.arena.layout_id == "tutorial" and flow.tutorial_session.is_active(),
		"replay -> skip -> replay ends guided again"
	)
	await _free_flow()


func _test_layout_is_per_match() -> void:
	var room := await _room_in_lobby(2)
	_check(room.arena.layout_id == "tutorial", "match 1 is the tutorial match")
	flow.tutorial_session.mark_completed()
	flow._on_flow_requested(&"leave_match")
	await _wait_frames(3)
	_check(
		flow.room.arena.arena_geometry_signature() == _default_signature,
		"match 2 starts fresh on the default layout"
	)
	await _free_flow()


func _test_lagsanay_prompt_once() -> void:
	flow = FLOW_SCENE.instantiate() as GameFlow
	flow.match_scene = P09_SCENE
	root.add_child(flow)
	await _wait_frames(3)
	await _join_title()
	var room := flow.room
	_check(room != null and room.arena.layout_id == "tutorial", "lifecycle route uses the layout")
	var coach := flow.tutorial
	_join_k2(room)
	flow.tutorial_session.mark_completed()
	_ready_all(room)
	_start_match(room)
	await _wait_frames(2)
	var life := room as P09MatchLifecycleRoom
	var assignments := {}
	for seat in room.input_router.registry.joined_seats():
		assignments[int(seat.seat)] = str(room.egg_pool[int(seat.seat)].egg_id)
	room.assignments = assignments
	room._enter_place()
	await _wait_frames(2)
	var placed := room.items.place("build.hollow_blocks.cell_1x1", Vector2i(27, 9), 0, 0)
	_check(bool(placed.allowed), "a piece is built in the BUILD HERE zone before Lagsanay")
	var built_signature := room.items.construction_signature()
	room._enter_play()
	await _wait_frames(2)
	_check(coach.view.get("visible", false) == false, "no prompt in a completed Karera round")
	life.cumulative_score_units = {0: 40, 1: 40}
	life.lifecycle.completed_round = 11
	var decision := life.lifecycle.finish_round(12, {0: 40, 1: 40}, 200, 12)
	life._start_sudden_death(decision)
	await _wait_frames(3)
	_check(
		coach.view.get("step_id", &"") == TutorialScript.STEP_LAGSANAY,
		"the first Lagsanay round shows the Lagsanay prompt"
	)
	_check(
		room.arena.arena_geometry_signature() == _tutorial_signature,
		"Lagsanay / sudden death play on the same stage"
	)
	_check(str(coach.view.body).contains("3"), "the prompt carries the tuned head start")
	_check(
		room.items.construction_signature() == built_signature and built_signature != "",
		"the built pieces are unchanged in the Lagsanay round (same map, same construction)"
	)
	_check(
		not flow.tutorial_session.seen_lagsanay, "the prompt is not marked seen while it is showing"
	)
	life.lagsanay_controller.reset()
	coach.rebuild()
	_check(flow.tutorial_session.seen_lagsanay, "the prompt is marked seen when Lagsanay ends")
	_check(not flow.tutorial_session.lagsanay_prompt_due(), "it will not show again this session")
	await _free_flow()


func _test_lifecycle_replay_gets_default_stage() -> void:
	flow = FLOW_SCENE.instantiate() as GameFlow
	flow.match_scene = P09_SCENE
	root.add_child(flow)
	await _wait_frames(3)
	await _join_title()
	var room := flow.room
	_join_k2(room)
	_start_match(room)
	await _wait_frames(2)
	_check(room.arena.layout_id == "tutorial", "the lifecycle match starts on the tutorial stage")
	var life := room as P09MatchLifecycleRoom
	life._replay_match()
	await _wait_frames(3)
	var next_room := flow.room
	_check(next_room != room, "Replay from the tutorial stage builds a fresh room")
	_check(
		(
			next_room.arena.arena_geometry_signature() == _tutorial_signature
			or flow.tutorial_session.wants_tutorial_layout() == false
		),
		"the replay room follows the session (tutorial still active here)"
	)
	flow.tutorial_session.mark_completed()
	var again := flow.room as P09MatchLifecycleRoom
	again._hands_back_for_fresh_stage(&"replay_match")
	await _wait_frames(3)
	_check(
		(
			flow.room != again
			and flow.room.arena.arena_geometry_signature() == _default_signature
			and flow.room.phase_controller.phase == MatchPhaseController.Phase.PUGAD
		),
		"after completion, Replay starts a fresh match at once on the default stage"
	)
	await _free_flow()


func _test_lifecycle_cycles() -> void:
	var baseline := Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	for cycle in 10:
		var room := await _room_in_lobby(2)
		_start_match(room)
		await _wait_frames(2)
		if cycle % 3 == 0:
			flow.tutorial_session.skip()
		elif cycle % 3 == 1:
			flow.tutorial_session.replay()
		await _free_flow()
	await _wait_frames(3)
	var after := Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	_check(
		after <= baseline + 40.0,
		"10 match + skip/replay cycles do not leak nodes (%d -> %d)" % [baseline, after]
	)


func _test_source_rules() -> void:
	for path in TUTORIAL_SOURCES:
		var code := ""
		for line in FileAccess.get_file_as_string(path).split("\n"):
			if not line.strip_edges().begins_with("#"):
				code += line + "\n"
		for token in FORBIDDEN_TOKENS:
			_check(not code.contains(token), "%s has no %s" % [path.get_file(), token])


# --- helpers ----------------------------------------------------------------------------------


func _room_in_lobby(seat_count: int) -> P05MatchRoom:
	flow = FLOW_SCENE.instantiate() as GameFlow
	root.add_child(flow)
	await _wait_frames(3)
	await _join_title()
	var room := flow.room
	if seat_count >= 2:
		_join_k2(room)
	for device_id in range(900, 900 + maxi(0, seat_count - 2)):
		var seat := room.input_router.registry.join_gamepad(device_id)
		if seat >= 0:
			room.input_router.seat_joined.emit(seat)
	await _wait_frames(2)
	return room


## Title: one press joins K1, the next (on the menu) starts the match.
func _join_title() -> void:
	_key(KEY_F, true)
	_key(KEY_F, false)
	await _wait_frames(2)
	_key(KEY_F, true)
	await process_frame
	_key(KEY_F, false)
	await _wait_frames(2)


func _join_k2(room: P05MatchRoom) -> void:
	var seat := room.input_router.registry.join_keyboard("K2")
	if seat >= 0:
		room.input_router.seat_joined.emit(seat)


func _ready_all(room: P05MatchRoom) -> void:
	for seat in room.input_router.registry.joined_seats():
		room.input_router.registry.set_ready(int(seat.seat), true)


func _start_match(room: P05MatchRoom) -> void:
	_ready_all(room)
	room.start_match()


func _claim(room: P05MatchRoom, seat_index: int, egg_index: int = 0) -> void:
	room.selected_egg_by_seat[seat_index] = egg_index
	room._on_match_action_pressed(seat_index, "claim")


func _to_play(room: P05MatchRoom) -> void:
	var seats: Array = room.input_router.registry.joined_seats()
	var assignments := {}
	for seat in seats:
		assignments[int(seat.seat)] = str(room.egg_pool[int(seat.seat)].egg_id)
	room.assignments = assignments
	room._enter_place()
	await _wait_frames(2)
	room._enter_play()
	await _wait_frames(2)


func _teleport_all_to_goal(room: P05MatchRoom) -> void:
	var goal := room.goal_area.global_position
	for actor_variant in room.actors.values():
		(actor_variant as ChickenController).global_position = goal
	await _wait_physics_frames(GOAL_PHYSICS_FRAMES)
	await _wait_frames(2)


func _marker(room: P05MatchRoom) -> BuildHereMarker:
	for child in room.world_layer.get_children():
		if child is BuildHereMarker:
			return child as BuildHereMarker
	return null


func _marker_visible(room: P05MatchRoom) -> bool:
	var marker := _marker(room)
	return marker != null and marker.visible


func _user_listing() -> Array:
	var listing: Array = []
	var user_dir := OS.get_user_data_dir()
	if DirAccess.dir_exists_absolute(user_dir):
		_walk(user_dir, listing)
	listing.sort()
	return listing


func _walk(path: String, listing: Array) -> void:
	# The engine's own log files live under user://logs; everything else is game data.
	if path.replace("\\", "/").ends_with("/logs"):
		return
	for file_name in DirAccess.get_files_at(path):
		var full := path.path_join(file_name)
		listing.append("%s:%d" % [full, FileAccess.get_modified_time(full)])
	for dir_name in DirAccess.get_directories_at(path):
		_walk(path.path_join(dir_name), listing)


func _key_event(key: Key, pressed: bool) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.pressed = pressed
	return event


func _key(key: Key, pressed: bool) -> void:
	flow.router._handle_key(_key_event(key, pressed))


func _free_flow() -> void:
	if flow != null and is_instance_valid(flow):
		flow.queue_free()
	flow = null
	paused = false
	await _wait_frames(3)


func _wait_frames(count: int) -> void:
	for _frame in range(count):
		await process_frame


func _wait_physics_frames(count: int) -> void:
	for _frame in range(count):
		await physics_frame


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("TUTORIAL FAIL: " + message)
	else:
		print("PASS ", message)

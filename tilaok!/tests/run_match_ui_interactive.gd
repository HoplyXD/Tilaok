extends SceneTree

## Rendered 1920x1080 run of the live player flow (K1 + K2 plus synthetic gamepads for seats 3/4):
## Title -> Lobby -> Pugad -> Place -> Play -> Round result (twice) -> pause/resume -> Leave ->
## Lobby -> Title, with a capture of every live screen. Synthetic input is not device evidence.

const FLOW_SCENE := preload("res://scenes/flow/game_flow.tscn")
const P08_SCENE := preload("res://scenes/match/p08_lagsanay_room.tscn")
const OUTPUT_RELATIVE := "../docs/evidence/match-ui"
const PAD_IDS := [710, 711]
const NEW_PAD_ID := 712
const WINDOW_SIZE := Vector2i(1920, 1080)
const WIDE_SIZE := Vector2i(1920, 800)
## The viewport keeps 16:9 inside the wider window (aspect keep); the bars are outside it.
const LETTERBOXED_VIEWPORT := Vector2i(1422, 800)
const GOAL_PHYSICS_FRAMES := 8
const RESUME_WAIT_SECONDS := 3.6
const MIN_SETTLE_FRAMES := 90
const MAX_SETTLE_FRAMES := 900
const STABLE_FRAMES_NEEDED := 30

var checks := 0
var failures := 0
var flow: GameFlow
var output_dir := ""
var measurements := PackedStringArray()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	output_dir = ProjectSettings.globalize_path("res://").path_join(OUTPUT_RELATIVE).simplify_path()
	DirAccess.make_dir_recursive_absolute(output_dir)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(WINDOW_SIZE)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	await _four_player_session()
	await _two_player_session()
	await _lifecycle_route_session()
	await _lagsanay_lab_session()
	_write_measurements()
	print("MATCH_UI_INTERACTIVE checks=%d failures=%d captures=%s" % [checks, failures, output_dir])
	quit(1 if failures > 0 else 0)


func _four_player_session() -> void:
	flow = FLOW_SCENE.instantiate() as GameFlow
	flow.match_scene = GameFlow.MATCH_SCENE
	root.add_child(flow)
	await _wait_frames(30)
	_check(flow.state == GameFlow.State.TITLE, "boot lands on the Title")
	await _capture("01_title_nobody_joined")
	_key(KEY_E, true)
	_key(KEY_E, false)
	await _wait_frames(3)
	await _capture("02_title_menu_one_seat")
	_key(KEY_E, true)
	await _wait_frames(3)
	_key(KEY_E, false)
	var room := flow.room
	_check(room != null, "Start from the Title opens the match room")
	await _wait_frames(3)
	await _capture("03_lobby_one_seat")
	_key(KEY_ENTER, true)
	_key(KEY_ENTER, false)
	for pad in PAD_IDS:
		_pad(pad, JOY_BUTTON_A, true)
		_pad(pad, JOY_BUTTON_A, false)
	await _wait_frames(3)
	_check(room.actors.size() == 4, "K1, K2 and two synthetic gamepads fill four seats")
	_key(KEY_E, true)
	_key(KEY_E, false)
	_pad(PAD_IDS[0], JOY_BUTTON_A, true)
	_pad(PAD_IDS[0], JOY_BUTTON_A, false)
	await _wait_frames(3)
	await _capture("04_lobby_four_seats_two_ready")
	_key(KEY_ENTER, true)
	_key(KEY_ENTER, false)
	_pad(PAD_IDS[1], JOY_BUTTON_A, true)
	_pad(PAD_IDS[1], JOY_BUTTON_A, false)
	await _wait_frames(4)
	_check(
		room.phase_controller.phase == MatchPhaseController.Phase.PUGAD,
		"all four ready starts Pugad with no Start click"
	)
	await _capture("05_pugad_four_players_pointing_at_egg_1")
	# One same-tick contest: the losers get a text lost-claim cue.
	_key(KEY_E, true)
	_key(KEY_ENTER, true)
	_pad(PAD_IDS[0], JOY_BUTTON_A, true)
	_pad(PAD_IDS[1], JOY_BUTTON_A, true)
	_key(KEY_E, false)
	_key(KEY_ENTER, false)
	_pad(PAD_IDS[0], JOY_BUTTON_A, false)
	_pad(PAD_IDS[1], JOY_BUTTON_A, false)
	await _wait_physics_frames(2)
	await _wait_frames(3)
	_check(room.assignments.size() == 1, "the four-seat contest grants one owner")
	await _capture("06_pugad_claim_lost")
	for seat_index in range(4):
		if room.assignments.has(seat_index):
			continue
		for egg_index in range(room.egg_pool.size()):
			var egg_id := str(room.egg_pool[egg_index].egg_id)
			if room._owner_for_egg(egg_id) < 0 and not room._has_pending_claim(egg_id):
				room.selected_egg_by_seat[seat_index] = egg_index
				room._queue_claim(seat_index, egg_id)
				break
	await _wait_physics_frames(3)
	await _wait_frames(3)
	_check(
		room.phase_controller.phase == MatchPhaseController.Phase.PLACE,
		"four distinct claims start Place"
	)
	await _capture("07_place_four_players_valid")
	# Put seat 4 into the protected goal zone: a blocked cursor with a text reason.
	var blocked_cell := Vector2i(room.arena.protected_goal.position / room.tuning.grid_cell_wu)
	var blocked: Dictionary = room.placement_controller.cursors[3]
	var original_cell: Vector2i = blocked.cell
	blocked.cell = blocked_cell
	room.placement_controller.cursors[3] = blocked
	room._refresh_all_match_ghosts()
	await _wait_frames(3)
	_check(
		(
			not bool(room.placement_verdicts[3].allowed)
			and room.presenter.place_overlay.get_node("%ReasonToast").visible
		),
		"a blocked cursor shows a live reason in the Place overlay"
	)
	await _capture("08_place_blocked_with_reason")
	blocked.cell = original_cell
	room.placement_controller.cursors[3] = blocked
	room._refresh_all_match_ghosts()
	await _wait_frames(2)
	_confirm_everyone()
	await _wait_physics_frames(2)
	await _wait_frames(40)
	_check(
		room.phase_controller.phase == MatchPhaseController.Phase.PLAY, "everyone confirmed: Play"
	)
	await _capture("09_play_hud_four_players")
	_all_to_goal(room)
	await _wait_physics_frames(GOAL_PHYSICS_FRAMES)
	await _wait_frames(4)
	_check(
		room.phase_controller.phase == MatchPhaseController.Phase.RESULTS,
		"four finishers open the Round result"
	)
	await _capture("10_results_four_finished_no_points")
	_check(
		room.last_results_model.suppression_reason.contains("Everyone reached the goal"),
		"four-player all-finish says why no points were awarded"
	)
	await _debug_overlay_pair(room)
	await _next_round_with_three_finishers(room)
	await _pause_resume_and_leave(room)
	flow.queue_free()
	flow = null
	paused = false
	await _wait_frames(3)


func _debug_overlay_pair(room: P05MatchRoom) -> void:
	room.set_debug_overlay_visible(true)
	await _wait_frames(3)
	await _capture("11_debug_overlay_on_results")
	room.set_debug_overlay_visible(false)
	await _wait_frames(3)
	await _capture("12_debug_overlay_off_results")


func _next_round_with_three_finishers(room: P05MatchRoom) -> void:
	# All four confirm; the held key rule is covered by run_match_ui_tests.
	_key(KEY_E, true)
	_key(KEY_E, false)
	_key(KEY_ENTER, true)
	_key(KEY_ENTER, false)
	for pad in PAD_IDS:
		_pad(pad, JOY_BUTTON_A, true)
		_pad(pad, JOY_BUTTON_A, false)
	await _wait_physics_frames(2)
	await _wait_frames(3)
	_check(
		room.phase_controller.phase == MatchPhaseController.Phase.PUGAD,
		"all four ready starts round 2 (no 8 s wait)"
	)
	room.assignments.clear()
	for seat_index in range(4):
		room.assignments[seat_index] = str(room.egg_pool[seat_index].egg_id)
	room._enter_place()
	await _wait_frames(2)
	var piece := room.items.place("build.hollow_blocks.cell_1x1", Vector2i(10, 5), 0, 0)
	_check(bool(piece.allowed), "round 2 keeps round 1's stage and adds a piece")
	room._enter_play()
	await _wait_frames(30)
	# Seat 4 stays behind: three finish, the fourth fails at the post-finish deadline.
	var goal := room.goal_area.global_position
	for seat_index in range(3):
		(room.actors[seat_index] as ChickenController).global_position = goal
	await _wait_physics_frames(GOAL_PHYSICS_FRAMES)
	await _wait_frames(4)
	await _capture("13_play_finish_window")
	room.race_round_controller.elapsed_seconds = room.race_round_controller.first_finish_deadline
	await _wait_frames(2)
	await _wait_physics_frames(GOAL_PHYSICS_FRAMES)
	await _wait_frames(4)
	_check(
		room.phase_controller.phase == MatchPhaseController.Phase.RESULTS,
		"the finish window ends the round with one runner out"
	)
	await _capture("14_results_three_finished_one_out")
	await _worst_case_results_fixture(room)


## Rendering evidence for the largest award list (a staged model, not a played round).
func _worst_case_results_fixture(room: P05MatchRoom) -> void:
	var seats: Array[Dictionary] = []
	for index in PlayerSeatRegistry.MAX_SEATS:
		seats.append(room.input_router.registry.get_seat(index))
	var seat_indices: Array[int] = [0, 1, 2, 3]
	var outcomes: Array[Dictionary] = [
		P06Fixtures.terminal(0, "finished", 5),
		P06Fixtures.terminal(1, "finished", 5),
		P06Fixtures.terminal(2, "finished", 5),
		P06Fixtures.terminal(3, "eliminated", 9, 0),
	]
	var score := RaceScoreCalculator.calculate(seat_indices, outcomes, {0: 0, 1: 0, 2: 0, 3: 40})
	var model := MatchResultsViewModel.race(
		7, seats, outcomes, score, "post_finish_deadline", 60.0, 15.0
	)
	var screen := room.presenter.result_screen
	screen.bind_live(model, seats, {}, 5.0, 8.0, "k1", room.presenter.prompt_map)
	_check(model.award_rows.size() == 10, "the staged model has the worst-case ten award rows")
	await _wait_frames(3)
	await _capture("15_results_worst_case_ten_awards_FIXTURE")
	# Restore the real result before continuing.
	room.presenter._dirty = true
	await _wait_frames(2)


func _pause_resume_and_leave(room: P05MatchRoom) -> void:
	_key(KEY_E, true)
	_key(KEY_E, false)
	_key(KEY_ENTER, true)
	_key(KEY_ENTER, false)
	for pad in PAD_IDS:
		_pad(pad, JOY_BUTTON_A, true)
		_pad(pad, JOY_BUTTON_A, false)
	await _wait_physics_frames(2)
	await _wait_frames(3)
	room.assignments.clear()
	for seat_index in range(4):
		room.assignments[seat_index] = str(room.egg_pool[seat_index].egg_id)
	room._enter_place()
	await _wait_frames(2)
	room._enter_play()
	await _wait_frames(20)
	room.input_router.pause_requested.emit(1)
	await _wait_frames(4)
	_check(room.get_tree().paused, "a pause request pauses the tree")
	await _capture("16_pause_owner_seat_2")
	_key(KEY_E, true)
	_key(KEY_E, false)
	for pad in PAD_IDS:
		_pad(pad, JOY_BUTTON_A, true)
		_pad(pad, JOY_BUTTON_A, false)
	await _wait_frames(2)
	await _capture("17_pause_three_ready_waiting_on_owner")
	_key(KEY_ENTER, true)
	_key(KEY_ENTER, false)
	await _wait_frames(8)
	_check(
		room.pause_coordinator.state == PauseRecoveryCoordinator.State.COUNTDOWN,
		"the pause owner starts the 3 s countdown with one Resume action"
	)
	await _capture("18_pause_resume_countdown")
	await create_timer(RESUME_WAIT_SECONDS, true, false, true).timeout
	_check(
		(
			not room.get_tree().paused
			and room.pause_coordinator.state == PauseRecoveryCoordinator.State.RUNNING
		),
		"the resume countdown ends and the game continues"
	)
	# A lost controller: reclaim panel with the owner-less (shared) pause.
	flow.router._on_joy_connection_changed(PAD_IDS[1], false)
	await _wait_frames(4)
	_check(
		room.presenter.pause_screen.get_node("%ReclaimPanel").visible,
		"a lost controller opens the reclaim panel"
	)
	await _capture("19_pause_device_lost_reclaim")
	_pad(NEW_PAD_ID, JOY_BUTTON_A, true)
	_pad(NEW_PAD_ID, JOY_BUTTON_A, false)
	await _wait_frames(4)
	_check(
		bool(room.input_router.registry.get_seat(3).connected),
		"one South press on a new pad reclaims seat 4"
	)
	# Take the pause menu, then Leave -> confirm -> Lobby -> Back -> Title.
	_key(KEY_E, true)
	_key(KEY_E, false)
	await _wait_frames(3)
	for _step in 3:
		_key(KEY_S, true)
		_key(KEY_S, false)
		await _wait_frames(1)
	_key(KEY_E, true)
	_key(KEY_E, false)
	await _wait_frames(3)
	await _capture("20_pause_leave_confirmation")
	_key(KEY_A, true)
	_key(KEY_A, false)
	await _wait_frames(1)
	_key(KEY_E, true)
	_key(KEY_E, false)
	await _wait_frames(6)
	_check(
		(
			flow.room != null
			and flow.room.phase_controller.phase == MatchPhaseController.Phase.LOBBY
			and not flow.room.get_tree().paused
		),
		"confirmed Leave returns the group to a fresh Lobby"
	)
	await _capture("21_lobby_after_leave")
	_key(KEY_G, true)
	_key(KEY_G, false)
	await _wait_frames(6)
	_check(
		flow.state == GameFlow.State.TITLE and flow.room == null,
		"Lobby Back returns to the Title with the match released"
	)
	await _capture("22_title_after_return")


func _two_player_session() -> void:
	flow = FLOW_SCENE.instantiate() as GameFlow
	flow.match_scene = GameFlow.MATCH_SCENE
	root.add_child(flow)
	await _wait_frames(10)
	_key(KEY_E, true)
	_key(KEY_E, false)
	await _wait_frames(3)
	_key(KEY_E, true)
	await _wait_frames(2)
	_key(KEY_E, false)
	var room := flow.room
	_key(KEY_ENTER, true)
	_key(KEY_ENTER, false)
	await _wait_frames(2)
	_key(KEY_E, true)
	_key(KEY_E, false)
	_key(KEY_ENTER, true)
	_key(KEY_ENTER, false)
	await _wait_frames(4)
	room.assignments = {0: str(room.egg_pool[0].egg_id), 1: str(room.egg_pool[1].egg_id)}
	room._enter_place()
	await _wait_frames(2)
	room._enter_play()
	await _wait_frames(10)
	await _measure_zoom(room)
	_all_to_goal(room)
	await _wait_physics_frames(GOAL_PHYSICS_FRAMES)
	await _wait_frames(4)
	_check(
		room.last_results_model.suppression_reason.contains("Everyone reached the goal"),
		"two finishers: all-finish zero is explained"
	)
	await _capture("23_results_two_players_all_finish_zero")
	DisplayServer.window_set_size(WIDE_SIZE)
	await _wait_frames(6)
	await _capture("24_results_wide_window_letterbox", LETTERBOXED_VIEWPORT)
	DisplayServer.window_set_size(WINDOW_SIZE)
	await _wait_frames(6)
	flow.queue_free()
	flow = null
	paused = false
	await _wait_frames(3)


## The opt-in lifecycle route inside the player flow: sudden-death HUD, the final match result and
## its confirmation dialog (P09 data on the same scene screens).
func _lifecycle_route_session() -> void:
	flow = FLOW_SCENE.instantiate() as GameFlow
	flow.match_scene = GameFlow.LIFECYCLE_SCENE
	root.add_child(flow)
	await _wait_frames(10)
	flow.router.registry.join_keyboard("K1")
	flow.router.registry.join_keyboard("K2")
	flow.router.registry.join_gamepad(PAD_IDS[0])
	flow._enter_match()
	await _wait_frames(6)
	var life := flow.room as P09MatchLifecycleRoom
	_check(life != null, "the lifecycle route opens the P09 room from the Title flow")
	for seat in flow.router.registry.joined_seats():
		flow.router.registry.set_ready(int(seat.seat), true)
	life._on_match_action_pressed(0, "ready")
	await _wait_frames(3)
	life.assignments = {
		0: str(life.egg_pool[0].egg_id),
		1: str(life.egg_pool[1].egg_id),
		2: str(life.egg_pool[2].egg_id),
	}
	life._enter_place()
	await _wait_frames(2)
	life._enter_play()
	await _wait_frames(3)
	life.cumulative_score_units = {0: 40, 1: 40, 2: 8}
	life.lifecycle.completed_round = 11
	var decision := life.lifecycle.finish_round(12, {0: 40, 1: 40, 2: 8}, 200, 12)
	life._start_sudden_death(decision)
	await _wait_frames(6)
	_check(
		(life.presenter.play_hud.get_node("%ChallengeLabel") as Label).text.begins_with("Sudden"),
		"sudden death retitles the HUD"
	)
	await _capture("26_lifecycle_sudden_death_hud")
	life._show_final_results(0, false, "Tied leaders played Lagsanay sudden death. P1 wins.")
	await _wait_frames(6)
	_check(life.presenter.match_result_screen.visible, "the final match result is on screen")
	await _capture("27_lifecycle_final_match_result")
	life._on_match_action_pressed(0, "back")
	await _wait_frames(4)
	_check(life.presenter.confirm_dialog.is_open(), "Back opens the confirmation dialog")
	await _capture("28_lifecycle_leave_confirmation")
	life.presenter.confirm_dialog.cancel()
	await _wait_frames(3)
	flow.queue_free()
	flow = null
	paused = false
	await _wait_frames(3)


## The P08 Lagsanay lab (harness route) on the presenter, DEBUG overlay on.
func _lagsanay_lab_session() -> void:
	var lab := P08_SCENE.instantiate() as P08LagsanayMatchRoom
	lab.debug_overlay_default = true
	root.add_child(lab)
	await _wait_frames(6)
	lab.join_keyboard("K1")
	lab.join_keyboard("K2")
	for seat in lab.input_router.registry.joined_seats():
		lab.input_router.registry.set_ready(int(seat.seat), true)
	lab.tuning.lagsanay_opening_head_start_seconds = 6.0
	_check(lab.start_match(), "the Lagsanay lab starts")
	lab._enter_place()
	await _wait_frames(2)
	lab._enter_play()
	await _wait_frames(30)
	await _capture("29_lagsanay_lab_head_start_hud")
	lab.lagsanay_controller.head_start_remaining = 0.0
	await _wait_physics_frames(6)
	lab.lagsanay_controller.countdown_remaining = 0.03
	for _frame in range(12):
		await physics_frame
		if lab.phase_controller.phase == MatchPhaseController.Phase.RESULTS:
			break
	await _wait_frames(8)
	_check(
		lab.presenter.result_screen.visible,
		"the Lagsanay result uses the scene Round result screen"
	)
	await _capture("30_lagsanay_lab_results")
	lab.queue_free()
	paused = false
	await _wait_frames(3)


## Real pixel sizes of the 64 wu cell and the chicken body at the camera's two extremes.
func _measure_zoom(room: P05MatchRoom) -> void:
	var scale_to_1080 := float(WINDOW_SIZE.x) / room.tuning.camera_virtual_width_px
	var samples := [
		{"label": "widest", "rect": Rect2(Vector2.ZERO, room.arena.arena_bounds.size)},
		{"label": "tightest", "rect": Rect2(Vector2(768.0, 384.0), Vector2(256.0, 128.0))},
	]
	for sample in samples:
		room.set_camera_fixture_targets([sample.rect], BoundedStageCamera.Context.PLAY)
		var canvas_scale := await _settled_canvas_scale(room)
		var cell_px: float = canvas_scale * room.tuning.grid_cell_wu * scale_to_1080
		var body_w_px: float = canvas_scale * room.tuning.body_width_wu * scale_to_1080
		var body_h_px: float = canvas_scale * room.tuning.body_height_wu * scale_to_1080
		var line := (
			"%s framing: camera zoom %.3f; 1 cell = %.1f px; chicken body = %.1f x %.1f px at 1920x1080"
			% [sample.label, canvas_scale, cell_px, body_w_px, body_h_px]
		)
		measurements.append(line)
		print(line)
		await _capture("25_play_camera_%s" % sample.label)
	room.clear_camera_fixture_targets()
	# The camera eases toward its fitted zoom, so the tightest sample stops just short of the cap;
	# the cap itself is the tuned limit.
	for limit in [
		{"label": "tuned zoom minimum", "zoom": room.tuning.camera_zoom_min},
		{"label": "tuned zoom maximum", "zoom": room.tuning.camera_zoom_max},
	]:
		var limit_zoom: float = limit.zoom
		var limit_line := (
			"%s: camera zoom %.3f; 1 cell = %.1f px; chicken body = %.1f x %.1f px at 1920x1080"
			% [
				limit.label,
				limit_zoom,
				limit_zoom * room.tuning.grid_cell_wu * scale_to_1080,
				limit_zoom * room.tuning.body_width_wu * scale_to_1080,
				limit_zoom * room.tuning.body_height_wu * scale_to_1080,
			]
		)
		measurements.append(limit_line)
		print(limit_line)


## The camera eases toward its framing; measure only once the zoom has stopped moving.
func _settled_canvas_scale(room: P05MatchRoom) -> float:
	var previous := -1.0
	var stable_frames := 0
	for frame in range(MAX_SETTLE_FRAMES):
		await process_frame
		var current: float = room.get_viewport().get_canvas_transform().get_scale().x
		stable_frames = stable_frames + 1 if absf(current - previous) < 0.0002 else 0
		previous = current
		if frame >= MIN_SETTLE_FRAMES and stable_frames >= STABLE_FRAMES_NEEDED:
			break
	return previous


# --- helpers ---------------------------------------------------------------------------------


func _confirm_everyone() -> void:
	_key(KEY_E, true)
	_key(KEY_ENTER, true)
	for pad in PAD_IDS:
		_pad(pad, JOY_BUTTON_A, true)
	_key(KEY_E, false)
	_key(KEY_ENTER, false)
	for pad in PAD_IDS:
		_pad(pad, JOY_BUTTON_A, false)


func _all_to_goal(room: P05MatchRoom) -> void:
	var goal := room.goal_area.global_position
	for actor_variant in room.actors.values():
		(actor_variant as ChickenController).global_position = goal


func _key(key: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.pressed = pressed
	flow.router._handle_key(event)


func _pad(device_id: int, button: JoyButton, pressed: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.device = device_id
	event.button_index = button
	event.pressed = pressed
	flow.router._handle_joy_button(event)


func _capture(file_name: String, expected := WINDOW_SIZE) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var path := output_dir.path_join("%s_%dx%d.png" % [file_name, expected.x, expected.y])
	var result := image.save_png(path)
	_check(
		result == OK and image.get_size() == expected,
		"captured %s at %s" % [file_name, image.get_size()]
	)


func _write_measurements() -> void:
	var file := FileAccess.open(output_dir.path_join("frame_measurements.txt"), FileAccess.WRITE)
	if file == null:
		_check(false, "frame measurements can be written")
		return
	file.store_string(
		(
			"Measured by run_match_ui_interactive.gd (Godot %s, 1920x1080 window).\n%s\n"
			% [Engine.get_version_info().string, "\n".join(measurements)]
		)
	)
	file.close()


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
		push_error("MATCH_UI_INTERACTIVE FAIL: " + message)

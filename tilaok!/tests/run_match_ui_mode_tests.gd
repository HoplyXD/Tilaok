extends SceneTree

## The P08 Lagsanay lab and the P09 match lifecycle on the scene-based match UI: their HUD, results,
## final match result, confirmation dialog and DEBUG controls come from the presenter's screens
## (no code-built panels), and GameFlow can host the lifecycle route. Synthetic input only.

const P08_SCENE := preload("res://scenes/match/p08_lagsanay_room.tscn")
const P09_SCENE := preload("res://scenes/match/p09_match_lifecycle_room.tscn")
const FLOW_SCENE := preload("res://scenes/flow/game_flow.tscn")
const FORBIDDEN_TOKENS := [
	"Label.new(",
	"Button.new(",
	"PanelContainer.new(",
	"VBoxContainer.new(",
	"HBoxContainer.new(",
	"MarginContainer.new(",
	"ColorRect.new(",
	"TextureRect.new(",
	"Control.new(",
	"add_theme_",
]
const ROOM_SOURCES := [
	"res://scripts/match/p07_first_playable_match_room.gd",
	"res://scripts/match/p08_lagsanay_match_room.gd",
	"res://scripts/match/p09_match_lifecycle_room.gd",
]

var checks := 0
var failures := 0
var room: P05MatchRoom
var flow: GameFlow


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_lagsanay_lab_hud_and_results()
	await _test_lagsanay_lab_defect_action()
	await _test_sudden_death_hud()
	await _test_final_match_result_and_confirmation()
	await _test_pause_over_final_results()
	await _test_return_to_lobby()
	await _test_flow_hosts_the_lifecycle_route()
	_test_source_rules()
	print("MATCH_UI_MODE_TESTS checks=%d failures=%d" % [checks, failures])
	quit(1 if failures > 0 else 0)


# --- P08 ------------------------------------------------------------------------------------


func _test_lagsanay_lab_hud_and_results() -> void:
	await _new_room(P08_SCENE, 2)
	var lab := room as P08LagsanayMatchRoom
	lab.tuning.lagsanay_opening_head_start_seconds = 3.0
	_check(lab.start_match(), "P08 lab starts on the presenter")
	lab._enter_place()
	lab._enter_play()
	await _wait_frames(3)
	var presenter := lab.presenter
	var hud := presenter.play_hud
	_check(hud.visible and not presenter.place_overlay.visible, "Play shows only the HUD")
	_check(
		(hud.get_node("%ChallengeLabel") as Label).text == "Lagsanay",
		"the HUD names Lagsanay, not Karera"
	)
	var clock := ceili(lab.play_clock_seconds())
	_check(
		(hud.get_node("%TimerLabel") as Label).text == "%d:%02d" % [clock / 60, clock % 60],
		"the HUD clock is the head-start clock in whole seconds"
	)
	var tag := (hud.get_node("%NextEventLabel") as Label).text
	_check(
		(
			tag.contains("HEAD START")
			and tag.contains("TAYA P%d" % (lab.lagsanay_controller.taya_seat + 1))
		),
		"the HUD tag names the opening taya and the head start (%s)" % tag
	)
	var taya := lab.lagsanay_controller.taya_seat
	_check(hud.score_rows[taya].state_text() == "TAYA", "the taya's score row reads TAYA")
	_check(hud.score_rows[1 - taya].state_text() == "RUN", "other seats keep the default RUN state")
	_check(
		presenter.debug_overlay.identity_text().contains("P08-independent-lagsanay-dev"),
		"the DEBUG overlay carries the P08 build id"
	)
	_check(lab.race_round_controller == null, "Lagsanay creates no Karera round controller")
	var world_marker := lab.world_layer.get_node_or_null("P08TayaMarker") as Label
	_check(
		world_marker != null and world_marker.visible and world_marker.text.contains("TAYA"),
		"the world taya marker is an authored scene and follows the taya"
	)
	await _dispose_room()
	# Results: a short head start so the countdown runs and expires.
	await _new_room(P08_SCENE, 2)
	lab = room as P08LagsanayMatchRoom
	presenter = lab.presenter
	lab.tuning.lagsanay_opening_head_start_seconds = 0.1
	_check(lab.start_match(), "P08 results room starts")
	lab._enter_place()
	lab._enter_play()
	await _wait_physics_frames(10)
	lab.lagsanay_controller.countdown_remaining = 0.03
	for _frame in range(12):
		await physics_frame
		if lab.phase_controller.phase == MatchPhaseController.Phase.RESULTS:
			break
	await _wait_frames(3)
	_check(
		lab.phase_controller.phase == MatchPhaseController.Phase.RESULTS,
		"taya expiry opens the results"
	)
	var model := lab.last_results_model
	var result := presenter.result_screen
	_check(
		result.visible and not presenter.play_hud.visible,
		"the Round result screen replaces the HUD (no code-built results panel)"
	)
	_check(
		(
			(result.get_node("%EndReasonLabel") as Label).text == model.diagnostic_label
			and model.diagnostic_label.contains("last chicken standing")
		),
		"the result names the last survivor"
	)
	_check(
		(result.get_node("%DeadlineLabel") as Label).text == model.deadline_explanation,
		"the Lagsanay timing explanation is shown"
	)
	result.chart().settle()
	for index in model.per_seat_outcomes.size():
		_check(
			(
				result.chart().chart_columns()[index].score_text()
				== str(model.per_seat_outcomes[index].total_text)
			),
			"seat %d result total equals the Lagsanay view model" % (index + 1)
		)
	_check(model.award_rows.size() >= 2, "the placement awards are listed")
	for index in model.award_rows.size():
		var text: String = result.award_lines[index].text_value()
		_check(
			text.contains("Placement") and text.contains(str(model.award_rows[index].score_text)),
			"award row %d shows the placement award and its points" % (index + 1)
		)
	await _dispose_room()


func _test_lagsanay_lab_defect_action() -> void:
	await _new_room(P08_SCENE, 2)
	var lab := room as P08LagsanayMatchRoom
	_check(lab.start_match(), "defect room starts")
	lab._enter_place()
	lab._enter_play()
	await _wait_frames(3)
	var debug_overlay := lab.presenter.debug_overlay
	_check(not debug_overlay.extra_button.visible, "no extra DEBUG action before a defect")
	lab._on_actor_escaped(0)
	await _wait_frames(3)
	_check(
		debug_overlay.extra_button.visible and debug_overlay.extra_button.text == "Restart attempt",
		"a containment defect offers Restart attempt in the DEBUG overlay"
	)
	_check(lab.presenter.pause_screen.visible, "the defect pause shows the Pause screen")
	debug_overlay.extra_button.pressed.emit()
	await _wait_frames(3)
	_check(not lab._defect_paused, "Restart attempt clears the defect pause")
	_check(not debug_overlay.extra_button.visible, "the extra action hides again")
	await _dispose_room()


# --- P09 ------------------------------------------------------------------------------------


func _test_sudden_death_hud() -> void:
	await _new_room(P09_SCENE, 3)
	var life := room as P09MatchLifecycleRoom
	_check(life.start_match(), "P09 starts on the presenter")
	life.assignments = {
		0: str(life.egg_pool[0].egg_id),
		1: str(life.egg_pool[1].egg_id),
		2: str(life.egg_pool[2].egg_id),
	}
	life._enter_place()
	life._enter_play()
	await _wait_frames(2)
	_check(
		(life.presenter.play_hud.get_node("%ChallengeLabel") as Label).text == "Karera",
		"a normal P09 round is labelled Karera"
	)
	life.cumulative_score_units = {0: 40, 1: 40, 2: 8}
	# Fixture: the match is at its twelfth round with seats 1 and 2 tied on top.
	life.lifecycle.completed_round = 11
	var decision := life.lifecycle.finish_round(12, {0: 40, 1: 40, 2: 8}, 200, 12)
	_check(
		(
			int(decision.kind) == MatchLifecycleCoordinator.Decision.SUDDEN_DEATH
			and decision.tied_seats == [0, 1]
		),
		"seats 1 and 2 tie at the round limit"
	)
	life._start_sudden_death(decision)
	await _wait_frames(3)
	var hud := life.presenter.play_hud
	_check(
		(hud.get_node("%ChallengeLabel") as Label).text == "Sudden death • Lagsanay",
		"sudden death retitles the HUD"
	)
	_check(
		hud.score_rows[2].state_text() == "WATCHING",
		"the non-tied seat is shown as watching, not secured"
	)
	_check(
		(hud.get_node("%NoticeToast") as UiToastLine).text_value().contains("Sudden death"),
		"the HUD notice explains sudden death"
	)
	_check(life.race_round_controller == null, "sudden death has no Karera round controller")
	_check(
		life.presenter.debug_overlay.identity_text().contains("P09-match-lifecycle-dev"),
		"the DEBUG overlay carries the P09 build id"
	)
	await _dispose_room()


func _test_final_match_result_and_confirmation() -> void:
	await _new_room(P09_SCENE, 3)
	var life := room as P09MatchLifecycleRoom
	_check(life.start_match(), "final-result room starts")
	life.assignments = {
		0: str(life.egg_pool[0].egg_id),
		1: str(life.egg_pool[1].egg_id),
		2: str(life.egg_pool[2].egg_id),
	}
	life._enter_place()
	life._enter_play()
	life.cumulative_score_units = {0: 88, 1: 24, 2: 8}
	life._show_final_results(0, false, "First to 10 points. The score target ended the match.")
	await _wait_frames(3)
	var presenter := life.presenter
	_check(
		life._result_screen == presenter.match_result_screen,
		"the room binds the presenter's authored match-result screen"
	)
	_check(presenter.match_result_screen.visible, "the final match result is visible")
	_check(
		(
			not presenter.play_hud.visible
			and not presenter.result_screen.visible
			and not presenter.place_overlay.visible
			and not presenter.pugad_overlay.visible
			and not presenter.lobby_screen.visible
		),
		"every other match screen is hidden behind the final result"
	)
	var winner_label := presenter.match_result_screen.get_node("%WinnerLabel") as Label
	_check(winner_label.text.begins_with("WINNER"), "the winner is named (%s)" % winner_label.text)
	var final_columns := presenter.match_result_screen.chart().chart_columns()
	_check(final_columns.size() == 3, "one final chart column per original participant")
	_check(
		final_columns[0].score_text() == ScoreFormat.format_units(88),
		"the winner's exact final score is shown"
	)
	life._on_match_action_pressed(0, "back")
	await _wait_frames(2)
	_check(
		presenter.confirm_overlay.visible and presenter.confirm_dialog.is_open(),
		"Back opens the authored confirmation dialog"
	)
	_check(life.get_tree().paused, "the match is paused while the dialog is open")
	presenter.confirm_dialog.cancel()
	await _wait_frames(2)
	_check(
		not presenter.confirm_overlay.visible and not life.get_tree().paused,
		"cancelling closes the dialog and resumes"
	)
	_check(presenter.match_result_screen.visible, "the final result survives a cancelled dialog")
	await _dispose_room()


func _test_pause_over_final_results() -> void:
	await _new_room(P09_SCENE, 2)
	var life := room as P09MatchLifecycleRoom
	_check(life.start_match(), "pause-over-result room starts")
	_show_fixture_final(life)
	await _wait_frames(3)
	var presenter := life.presenter
	life.pause_coordinator.set_paused("test pause", 0)
	await _wait_frames(3)
	_check(
		presenter.pause_screen.visible and presenter.match_result_screen.visible,
		"Pause opens over the final result"
	)
	_check(
		presenter.bridge.screen == presenter.pause_screen,
		"only the pause screen takes menu input over the final result"
	)
	await _dispose_room()


func _test_return_to_lobby() -> void:
	await _new_room(P09_SCENE, 2)
	var life := room as P09MatchLifecycleRoom
	_check(life.start_match(), "return-to-lobby room starts")
	_show_fixture_final(life)
	await _wait_frames(3)
	var presenter := life.presenter
	# Return to Lobby chosen by seat 1; both original seats ready it.
	life.result_menu_owner = 0
	life._result_screen.owner_seat = 0
	life.result_action = 1
	life._set_result_ready(0)
	life._set_result_ready(1)
	await _wait_frames(3)
	_check(
		(
			life.phase_controller.phase == MatchPhaseController.Phase.LOBBY
			and not life.final_results_visible
		),
		"all original seats ready on Return to Lobby opens the Lobby"
	)
	_check(
		presenter.lobby_screen.visible and not presenter.match_result_screen.visible,
		"the Lobby screen replaces the final result"
	)
	_check(
		life.input_router.registry.joined_seats().size() == 2,
		"every original seat remains joined in the Lobby"
	)
	await _dispose_room()


func _show_fixture_final(life: P09MatchLifecycleRoom) -> void:
	life.assignments = {}
	for seat in life.input_router.registry.joined_seats():
		var seat_index := int(seat.seat)
		life.assignments[seat_index] = str(life.egg_pool[seat_index].egg_id)
	life._enter_place()
	life._enter_play()
	life.cumulative_score_units = {0: 88, 1: 8}
	life._show_final_results(0, false, "First to 10 points. The score target ended the match.")


func _test_flow_hosts_the_lifecycle_route() -> void:
	flow = FLOW_SCENE.instantiate() as GameFlow
	flow.match_scene = GameFlow.LIFECYCLE_SCENE
	root.add_child(flow)
	await _wait_frames(3)
	flow.router.registry.join_keyboard("K1")
	flow.router.registry.join_keyboard("K2")
	flow._enter_match()
	await _wait_frames(4)
	var life := flow.room as P09MatchLifecycleRoom
	_check(life != null, "GameFlow instantiates the P09 lifecycle room for the lifecycle route")
	_check(not life.presenter.debug_overlay.visible, "the DEBUG overlay is off in the player flow")
	_check(life.presenter.lobby_screen.visible, "the Lobby screen opens first")
	for seat in flow.router.registry.joined_seats():
		flow.router.registry.set_ready(int(seat.seat), true)
	life._on_match_action_pressed(0, "ready")
	await _wait_frames(3)
	_check(
		life.phase_controller.phase == MatchPhaseController.Phase.PUGAD,
		"all seats ready auto-starts the lifecycle match"
	)
	life.assignments = {0: str(life.egg_pool[0].egg_id), 1: str(life.egg_pool[1].egg_id)}
	life._enter_place()
	life._enter_play()
	life.cumulative_score_units = {0: 88, 1: 8}
	life._show_final_results(0, false, "First to 10 points. The score target ended the match.")
	await _wait_frames(3)
	_check(life.presenter.match_result_screen.visible, "the final result shows inside the flow")
	var old_room := life
	life.presenter._request_flow(&"leave_match")
	await _wait_frames(4)
	_check(
		flow.room != null and flow.room != old_room and flow.room is P09MatchLifecycleRoom,
		"Leave returns the group to a fresh lifecycle Lobby"
	)
	_check(
		(
			flow.room.phase_controller.phase == MatchPhaseController.Phase.LOBBY
			and flow.room.presenter.lobby_screen.visible
		),
		"the fresh room opens in the Lobby"
	)
	flow.queue_free()
	flow = null
	paused = false
	await _wait_frames(3)


# --- rules ----------------------------------------------------------------------------------


func _test_source_rules() -> void:
	for path in ROOM_SOURCES:
		var text := FileAccess.get_file_as_string(path)
		var clean := not text.is_empty()
		for token in FORBIDDEN_TOKENS:
			if text.contains(token):
				clean = false
				push_error("%s contains %s" % [path, token])
		_check(clean, "%s creates no Controls and adds no theme overrides" % path.get_file())


# --- helpers --------------------------------------------------------------------------------


func _new_room(scene: PackedScene, seat_count: int) -> void:
	await _dispose_room()
	room = scene.instantiate() as P05MatchRoom
	room.debug_overlay_default = true
	root.add_child(room)
	await _wait_frames(4)
	room.join_keyboard("K1")
	room.join_keyboard("K2")
	for device_id in range(900, 900 + maxi(0, seat_count - 2)):
		var seat := room.input_router.registry.join_gamepad(device_id)
		if seat >= 0:
			room.input_router.seat_joined.emit(seat)
	for seat in room.input_router.registry.joined_seats():
		room.input_router.registry.set_ready(int(seat.seat), true)


func _dispose_room() -> void:
	if room != null and is_instance_valid(room):
		room.queue_free()
	room = null
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
		push_error("MATCH_UI_MODE FAIL: " + message)

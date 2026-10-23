extends SceneTree

## Live match UI: every bind equals the P05/P06 view model, the whole Title -> Lobby -> Pugad ->
## Place -> Play -> Round result -> next-round flow, held-press consumption, menu ownership,
## pause / resume / reclaim, double activation and lifecycle. Synthetic input only.

const FLOW_SCENE := preload("res://scenes/flow/game_flow.tscn")
const HARNESS_SCENE := preload("res://scenes/harness/foundation_harness.tscn")
const PAD_IDS := [710, 711]
const NEW_PAD_ID := 712
const GOAL_PHYSICS_FRAMES := 8
const RESUME_SECONDS := 0.2
const ROUNDS_FOR_LIFECYCLE := 10
const CYCLES_FOR_LIFECYCLE := 10
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
const SOURCE_FILES := [
	"res://scripts/match/match_room.gd",
	"res://scripts/match/match_screen_presenter.gd",
	"res://scripts/flow/game_flow.gd",
	"res://scripts/ui/ui_debug_overlay.gd",
]

var checks := 0
var failures := 0
var flow: GameFlow


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_two_rounds_through_the_whole_flow()
	await _test_pause_menu_ownership_and_resume()
	await _test_lobby_resume_is_immediate()
	await _test_shared_pause_first_confirm()
	await _test_pause_menu_input_is_not_game_input()
	await _test_disconnect_and_reclaim("pugad")
	await _test_disconnect_and_reclaim("place")
	await _test_double_activation_and_echo()
	await _test_title_without_a_match()
	await _test_debug_overlay_and_harness_hosting()
	await _test_round_lifecycle()
	await _test_title_lobby_cycles()
	_test_source_rules()
	print("MATCH_UI_TESTS checks=%d failures=%d" % [checks, failures])
	quit(1 if failures > 0 else 0)


# --- 2. the whole flow, twice -------------------------------------------------------------------


func _test_two_rounds_through_the_whole_flow() -> void:
	await _new_flow()
	var title := flow._screen as UiTitleScreen
	_check(title != null and flow.state == GameFlow.State.TITLE, "boots to the Title")
	_check(
		not title.get_node("%PressToJoinPrompt").visible and title.get_node("%MenuList").visible,
		"Title with nobody joined shows the menu, not a join prompt"
	)
	_check(
		not (title.get_node("%BuildLabel") as Label).visible,
		"title hides development build identity from the recording view"
	)
	_key("K1", KEY_E, true)
	await process_frame
	_check(
		(
			flow.router.registry.joined_seats().size() == 1
			and not bool(flow.router.registry.get_seat(0).ready)
		),
		"the first press joins seat 1 and does not ready it"
	)
	_key("K1", KEY_E, false)
	await process_frame
	_check(
		title.get_node("%MenuList").visible and flow.router.phase == LocalInputRouter.Phase.MENU,
		"a joined seat reveals the Title menu (MENU phase)"
	)
	# Start while F stays held: the held press must not leak into the Lobby.
	_key("K1", KEY_E, true)
	await process_frame
	var room := flow.room
	_check(room != null and flow.state == GameFlow.State.IN_MATCH, "Start opens the match room")
	_check(
		not room.presenter.debug_overlay.visible,
		"the player flow starts with the DEBUG overlay off"
	)
	_check(
		(
			room.phase_controller.phase == MatchPhaseController.Phase.LOBBY
			and room.presenter.lobby_screen.visible
		),
		"the room starts in the Lobby with the lobby screen"
	)
	_check(
		not bool(flow.router.registry.get_seat(0).ready),
		"the Start press is consumed (Title -> Lobby): seat 1 is not ready"
	)
	_key("K1", KEY_E, false)
	await process_frame
	_key("K1", KEY_E, true)
	_key("K1", KEY_E, false)
	await process_frame
	_check(bool(flow.router.registry.get_seat(0).ready), "a fresh press readies seat 1")
	_check(
		room.presenter.lobby_screen.get_node("%NeedPlayersLabel").visible,
		"Lobby says 'need two players' with one seat"
	)
	_key("K2", KEY_ENTER, true)
	_key("K2", KEY_ENTER, false)
	await process_frame
	var seat2 := flow.router.registry.get_seat(1)
	_check(
		bool(seat2.joined) and not bool(seat2.ready),
		"a newly joining device joins and cannot ready on the same press"
	)
	_check(
		room.phase_controller.phase == MatchPhaseController.Phase.LOBBY,
		"two seats with one ready do not start the match"
	)
	await _play_round_through_keys(room, 1)
	await _play_round_through_keys(room, 2)
	await _free_flow()


## Lobby/Results ready -> Pugad contest -> re-pick -> Place confirm -> goal -> Round result.
func _play_round_through_keys(room: P05MatchRoom, round_number: int) -> void:
	var presenter := room.presenter
	if round_number == 1:
		# Both seats ready (seat 1 already is); K2 readies and the match auto-starts.
		_key("K2", KEY_ENTER, true)
		_key("K2", KEY_ENTER, false)
		await process_frame
	await _wait_frames(2)
	_check(
		room.phase_controller.phase == MatchPhaseController.Phase.PUGAD,
		"round %d: all seats ready starts Pugad" % round_number
	)
	_check(
		presenter.pugad_overlay.visible and not presenter.lobby_screen.visible,
		"round %d: Pugad overlay replaces the lobby" % round_number
	)
	_check(
		presenter.pugad_overlay.visible_egg_count() == room.egg_pool.size(),
		"round %d: one egg slot per pool egg (%d)" % [round_number, room.egg_pool.size()]
	)
	# Figma "Obstacle Pick": Pugad carries its own HUD rail and chip column.
	_check(
		(
			not presenter.play_hud.visible
			and (
				(presenter.pugad_overlay.get_node("%HudRound") as Label).text
				== "Round %d" % round_number
			)
		),
		"round %d: the Pugad HUD names the round" % round_number
	)
	_check(
		presenter.pugad_overlay.get_node("%Egg1").selector_numbers() == PackedInt32Array([1, 2]),
		"round %d: both seats' number badges show on the egg they point at" % round_number
	)
	_check(
		presenter.pugad_overlay.get_node("%Countdown").seconds_text() == "8s",
		"round %d: Pugad countdown starts at the tuned 8 s" % round_number
	)
	_check(
		(
			presenter.pugad_overlay.hud_chips[0].state_text() == "Choosing"
			and presenter.pugad_overlay.count_text() == "0 / 2 picked"
		),
		"round %d: chips read Choosing and the count reads 0 / 2 picked" % round_number
	)
	# Both seats point at egg 0 and claim on the same tick: one wins, one sees a lost-claim cue.
	_key("K1", KEY_E, true)
	_key("K2", KEY_ENTER, true)
	_key("K1", KEY_E, false)
	_key("K2", KEY_ENTER, false)
	await _wait_physics_frames(2)
	await process_frame
	_check(room.assignments.size() == 1, "round %d: same-tick claim has one owner" % round_number)
	var loser := 1 if room.assignments.has(0) else 0
	var winner := 1 - loser
	_check(
		(
			presenter.pugad_overlay.get_node("%LostClaimToast").visible
			and presenter.pugad_overlay.get_node("%LostClaimToast").text_value().contains(
				"claim lost"
			)
		),
		"round %d: the loser gets a text lost-claim cue" % round_number
	)
	_check(
		presenter.pugad_overlay.get_node("%Egg1").claim_owner_number() == winner + 1,
		"round %d: egg 1 shows the winner's number badge" % round_number
	)
	# The loser re-picks with the right key (K1 D / K2 Right) and claims again.
	if loser == 0:
		_key("K1", KEY_D, true)
		_key("K1", KEY_D, false)
		await process_frame
		_key("K1", KEY_E, true)
		_key("K1", KEY_E, false)
	else:
		_key("K2", KEY_RIGHT, true)
		_key("K2", KEY_RIGHT, false)
		await process_frame
		_key("K2", KEY_ENTER, true)
		_key("K2", KEY_ENTER, false)
	await _wait_physics_frames(2)
	await process_frame
	_check(
		room.phase_controller.phase == MatchPhaseController.Phase.PLACE,
		"round %d: both claimed, Place starts" % round_number
	)
	_check(
		presenter.place_overlay.visible and not presenter.pugad_overlay.visible,
		"round %d: Place overlay replaces Pugad" % round_number
	)
	if round_number > 1:
		# Round 1's pieces are in the stage now: move to free cells (as the P05 run does).
		for seat_index in room.placement_controller.cursors:
			var moved: Dictionary = room.placement_controller.cursors[seat_index]
			moved.cell.y = 5
			room.placement_controller.cursors[seat_index] = moved
		room._refresh_all_match_ghosts()
		await process_frame
	for index in 2:
		# Figma "Obstacle Place": the HUD chip carries Placing / Placed; the old status row stays
		# bound (exact variant) but is not shown.
		var seat_row: UiScoreRow = presenter.place_overlay.seat_rows[index]
		var variant := room.variant_label(str(room.placement_controller.cursors[index].variant_key))
		_check(
			seat_row.state_text().begins_with(variant) and not seat_row.is_visible_in_tree(),
			(
				"round %d: seat %d row stays bound to its exact variant (%s), hidden by design"
				% [round_number, index + 1, variant]
			)
		)
		_check(
			(
				presenter.play_hud.visible
				and presenter.play_hud.score_rows[index].state_text() == "Placing"
			),
			"round %d: seat %d HUD chip reads Placing" % [round_number, index + 1]
		)
	_check(
		presenter.place_overlay.get_node("%Countdown").seconds_text() == "15 secs",
		"round %d: Place countdown starts at the tuned 15 s" % round_number
	)
	# Confirm both with the keyboard; the edits resolve together and Play starts.
	_key("K1", KEY_E, true)
	_key("K2", KEY_ENTER, true)
	_key("K1", KEY_E, false)
	_key("K2", KEY_ENTER, false)
	await _wait_physics_frames(2)
	await process_frame
	_check(
		room.phase_controller.phase == MatchPhaseController.Phase.PLAY,
		"round %d: confirmed edits start Play" % round_number
	)
	_check(
		presenter.play_hud.visible and not presenter.place_overlay.visible,
		"round %d: only the HUD remains in Play" % round_number
	)
	var timer_text: String = (presenter.play_hud.get_node("%TimerLabel") as Label).text
	_check(
		timer_text in ["1:00", "0:59"],
		"round %d: HUD timer is the 60 s race (%s)" % [round_number, timer_text]
	)
	_check(
		presenter.play_hud.get_node("%NoticeToast").visible,
		"round %d: Play opens with a how-to-play hint" % round_number
	)
	var goal := room.goal_area.global_position
	for actor_variant in room.actors.values():
		(actor_variant as ChickenController).global_position = goal
	await _wait_physics_frames(GOAL_PHYSICS_FRAMES)
	await _wait_frames(2)
	_check(
		room.phase_controller.phase == MatchPhaseController.Phase.RESULTS,
		"round %d: reaching the goal opens the Round result" % round_number
	)
	var model := room.last_results_model
	var result := presenter.result_screen
	_check(result.visible and model != null, "round %d: result screen is visible" % round_number)
	_check(
		(
			result.get_node("%NoScoreReason").text_value() == model.suppression_reason
			and model.suppression_reason.contains("Everyone reached the goal")
		),
		"round %d: the 2-player all-finish zero reason is shown" % round_number
	)
	result.chart().settle()
	for index in model.per_seat_outcomes.size():
		var outcome: Dictionary = model.per_seat_outcomes[index]
		_check(
			result.chart().chart_columns()[index].score_text() == str(outcome.total_text),
			"round %d: seat %d result total equals the view model" % [round_number, index + 1]
		)
	for index in model.award_rows.size():
		var award: Dictionary = model.award_rows[index]
		_check(
			result.award_lines[index].text_value().contains(str(award.score_text)),
			"round %d: award row %d equals the view model" % [round_number, index + 1]
		)
	# K1 stays held through the advance; K2 confirms. The held press must not claim in the next Pugad.
	_key("K1", KEY_E, true)
	_key("K2", KEY_ENTER, true)
	_key("K2", KEY_ENTER, false)
	await _wait_physics_frames(2)
	await process_frame
	_check(
		room.phase_controller.phase == MatchPhaseController.Phase.PUGAD,
		"round %d: all ready advances to the next Pugad" % round_number
	)
	_check(
		room.assignments.is_empty() and room.pending_claims.is_empty(),
		"round %d: the held confirm is consumed (Results -> Pugad)" % round_number
	)
	_key("K1", KEY_E, false)
	await _wait_frames(2)
	for seat_index in 2:
		var units := int(room.cumulative_score_units[seat_index])
		_check(
			(
				presenter.pugad_overlay.hud_chips[seat_index].score_text()
				== ScoreFormat.format_units(units)
			),
			(
				"round %d: next-round HUD total for seat %d is ScoreFormat(%d)"
				% [round_number, seat_index + 1, units]
			)
		)
	if round_number == 1:
		_check(
			(presenter.pugad_overlay.get_node("%HudRound") as Label).text == "Round 2",
			"the next round is labelled Round 2 (Pugad HUD)"
		)
		_check(
			presenter.result_screen.visible == false and presenter.pugad_overlay.visible,
			"the result screen yields to the next Pugad"
		)


# --- 3. pause menu ownership ----------------------------------------------------------------


func _test_pause_menu_ownership_and_resume() -> void:
	var room := await _room_in_play()
	room.pause_coordinator.resume_countdown_seconds = RESUME_SECONDS
	var elapsed_before := room.race_round_controller.elapsed_seconds
	room.input_router.pause_requested.emit(1)
	await _wait_frames(2)
	var pause := room.presenter.pause_screen
	_check(room.get_tree().paused, "a pause request pauses the tree")
	_check(
		pause.visible and pause.owner_seat == 1,
		"the pause screen opens owned by the seat that paused"
	)
	_check(
		(
			pause.get_node("%OwnerBadge").number_text() == "2"
			and (pause.get_node("%OwnerLabel") as Label).text == "paused by"
		),
		"the owner badge shows seat 2"
	)
	var menu: UiMenuList = pause.get_node("%MenuList")
	_check(menu.selected == 0, "the pause menu starts on Resume")
	# A non-owner cannot drive the menu.
	_key("K1", KEY_S, true)
	_key("K1", KEY_S, false)
	await process_frame
	_check(menu.selected == 0, "a non-owner cannot move the pause menu")
	_key("K1", KEY_E, true)
	_key("K1", KEY_E, false)
	await process_frame
	_check(
		not bool(room.input_router.registry.get_seat(0).ready), "a non-owner cannot ready or resume"
	)
	await process_frame
	_check(
		pause.rosters[0].state_text() == "IN GAME",
		"pause roster stays informational until the owner resumes"
	)
	_check(room.pause_coordinator.state == PauseRecoveryCoordinator.State.PAUSED, "still paused")
	# Game input is not acted on while the pause menu owns the keys.
	_check(
		room.phase_controller.phase == MatchPhaseController.Phase.PLAY,
		"pausing in Play keeps the phase"
	)
	# The owner moves the menu and opens Settings, which keeps the simulation paused.
	_key("K2", KEY_DOWN, true)
	_key("K2", KEY_DOWN, false)
	await process_frame
	_check(menu.selected == 1, "the owner moves the pause menu")
	_key("K2", KEY_ENTER, true)
	_key("K2", KEY_ENTER, false)
	await _wait_frames(2)
	_check(
		room.presenter._overlay is UiSettingsScreen and room.get_tree().paused,
		"Settings opens over the pause menu with the simulation still paused"
	)
	_key("K2", KEY_BACKSPACE, true)
	_key("K2", KEY_BACKSPACE, false)
	await _wait_frames(2)
	_check(
		room.presenter._overlay == null and pause.visible,
		"Back returns from Settings to the pause menu"
	)
	_key("K2", KEY_UP, true)
	_key("K2", KEY_UP, false)
	await process_frame
	_key("K2", KEY_ENTER, true)
	_key("K2", KEY_ENTER, false)
	await process_frame
	_check(
		room.pause_coordinator.state == PauseRecoveryCoordinator.State.COUNTDOWN,
		"one Resume action starts the shared countdown"
	)
	_check(
		(
			room.presenter.fullscreen_countdown.visible
			and (
				(room.presenter.fullscreen_countdown.get_node("Center/Stack/Number") as Label).text
				== "1"
			)
			and not pause.visible
		),
		"Resume replaces the pause menu with the full-screen shared countdown"
	)
	_check(room.get_tree().paused, "the simulation stays frozen during the countdown")
	await _wait_frames(3)
	_check(
		is_equal_approx(room.race_round_controller.elapsed_seconds, elapsed_before),
		"the race clock did not advance while paused or counting down"
	)
	await create_timer(RESUME_SECONDS + 0.4, true, false, true).timeout
	_check(
		(
			not room.get_tree().paused
			and room.pause_coordinator.state == PauseRecoveryCoordinator.State.RUNNING
		),
		"the countdown resumes the game"
	)
	_check(not pause.visible, "the pause screen closes on resume")
	_check(
		not room.presenter.fullscreen_countdown.visible,
		"the full-screen countdown clears on resume"
	)
	_check(
		room.input_router.phase == LocalInputRouter.Phase.PLAY,
		"input returns to the phase before the pause"
	)
	# Pause again and leave: confirmation, then the group returns to the Lobby.
	room.input_router.pause_requested.emit(0)
	await _wait_frames(2)
	for _step in 3:
		_key("K1", KEY_S, true)
		_key("K1", KEY_S, false)
		await process_frame
	_key("K1", KEY_E, true)
	_key("K1", KEY_E, false)
	await process_frame
	_check(pause.get_node("%LeaveConfirm").is_open(), "Leave asks for confirmation before leaving")
	_key("K1", KEY_A, true)
	_key("K1", KEY_A, false)
	await process_frame
	_key("K1", KEY_E, true)
	_key("K1", KEY_E, false)
	await _wait_frames(3)
	_check(
		flow.room != null and flow.room != room and not get_root_paused(),
		"confirmed Leave opens a fresh room and unpauses"
	)
	_check(
		(
			flow.room.phase_controller.phase == MatchPhaseController.Phase.LOBBY
			and flow.router.registry.joined_seats().size() == 2
		),
		"Leave returns the group to the Lobby with its seats"
	)
	_check(flow.room.cumulative_score_units.is_empty(), "the new Lobby has no match scores")
	await _free_flow()


## Pausing in Place: menu presses must not move the cursor or confirm a placement.
func _test_pause_menu_input_is_not_game_input() -> void:
	var room := await _room_in_place()
	room.pause_coordinator.resume_countdown_seconds = RESUME_SECONDS
	var cell_before: Vector2i = room.placement_controller.cursors[1].cell
	room.input_router.pause_requested.emit(1)
	await _wait_frames(2)
	_key("K2", KEY_RIGHT, true)
	_key("K2", KEY_RIGHT, false)
	_key("K2", KEY_DOWN, true)
	_key("K2", KEY_DOWN, false)
	await process_frame
	_check(
		room.placement_controller.cursors[1].cell == cell_before,
		"menu arrows while paused do not move the Place cursor"
	)
	_key("K1", KEY_E, true)
	_key("K1", KEY_E, false)
	_key("K2", KEY_UP, true)
	_key("K2", KEY_UP, false)
	await process_frame
	_key("K2", KEY_ENTER, true)
	_key("K2", KEY_ENTER, false)
	await process_frame
	_check(
		(
			not room.placement_controller.is_confirmed(0)
			and not room.placement_controller.is_confirmed(1)
		),
		"menu confirms while paused do not lock a placement"
	)
	await create_timer(RESUME_SECONDS + 0.4, true, false, true).timeout
	_check(not room.get_tree().paused, "the countdown resumed the game")
	_key("K2", KEY_RIGHT, true)
	_key("K2", KEY_RIGHT, false)
	await process_frame
	_check(
		room.placement_controller.cursors[1].cell != cell_before,
		"game input works again after the resume"
	)
	await _free_flow()


func _test_shared_pause_first_confirm() -> void:
	var room := await _room_in_play()
	flow.router._pause_system()
	await _wait_frames(2)
	var pause := room.presenter.pause_screen
	_check(
		pause.visible and pause.owner_seat == -1,
		"a shared (Esc) pause has no owner yet and accepts no menu input"
	)
	_check(
		room.pause_coordinator.pause_reason == "shared system pause", "reason is the shared pause"
	)
	_key("K1", KEY_E, true)
	_key("K1", KEY_E, false)
	await _wait_frames(2)
	_check(room.pause_coordinator.menu_owner == 0, "the first fresh confirm takes the menu")
	_check(
		not bool(room.input_router.registry.get_seat(0).ready),
		"that confirm only takes ownership: it does not also Resume"
	)
	_check(pause.owner_seat == 0, "the pause screen follows the new owner")
	await _free_flow()


func _test_lobby_resume_is_immediate() -> void:
	await _new_flow()
	_join_title_k1()
	await process_frame
	_key("K1", KEY_E, true)
	await process_frame
	_key("K1", KEY_E, false)
	await process_frame
	_key("K1", KEY_E, true)
	_key("K1", KEY_E, false)
	await _wait_frames(3)
	var room := flow.room
	_check(
		room.phase_controller.phase == MatchPhaseController.Phase.LOBBY,
		"the immediate-resume regression starts in the Lobby"
	)
	room.input_router.pause_requested.emit(0)
	await _wait_frames(2)
	room.presenter.pause_screen.resume_requested.emit()
	await process_frame
	_check(
		(
			room.pause_coordinator.state == PauseRecoveryCoordinator.State.RUNNING
			and not room.get_tree().paused
			and not room.presenter.fullscreen_countdown.visible
		),
		"Resume in the Lobby unpauses immediately without the round countdown"
	)
	await _free_flow()


# --- 4. disconnect and reclaim ----------------------------------------------------------------


func _test_disconnect_and_reclaim(phase_name: String) -> void:
	await _new_flow()
	_join_title_k1()
	await _wait_frames(2)
	_key("K1", KEY_E, true)
	await process_frame
	_key("K1", KEY_E, false)
	await process_frame
	var room := flow.room
	# Gamepad seat 2 joins the Lobby with A, then both ready.
	_pad(PAD_IDS[0], JOY_BUTTON_A, true)
	_pad(PAD_IDS[0], JOY_BUTTON_A, false)
	await process_frame
	_key("K1", KEY_E, true)
	_key("K1", KEY_E, false)
	_pad(PAD_IDS[0], JOY_BUTTON_A, true)
	_pad(PAD_IDS[0], JOY_BUTTON_A, false)
	await _wait_frames(2)
	_check(
		room.phase_controller.phase == MatchPhaseController.Phase.PUGAD,
		"%s: keyboard + gamepad start the match" % phase_name
	)
	if phase_name == "place":
		room.assignments = {
			0: str(room.egg_pool[0].egg_id),
			1: str(room.egg_pool[1].egg_id),
		}
		room._enter_place()
		await process_frame
	var pad_seat := room.input_router.registry.get_seat(1)
	_check(
		str(pad_seat.device_kind) == "gamepad" and int(pad_seat.identity) == 2,
		"%s: seat 2 is the gamepad with number 2" % phase_name
	)
	var assignments_before := room.assignments.duplicate()
	var claims_before := room.pending_claims.size()
	flow.router._on_joy_connection_changed(PAD_IDS[0], false)
	await _wait_frames(2)
	var pause := room.presenter.pause_screen
	_check(
		pause.visible and room.get_tree().paused,
		"%s: a lost controller pauses and opens the pause screen" % phase_name
	)
	_check(
		pause.rosters[1].state_text() == "DEVICE LOST",
		"%s: the roster names the lost device" % phase_name
	)
	_check(pause.get_node("%ReclaimPanel").visible, "%s: the reclaim panel opens" % phase_name)
	_check(
		room.pause_coordinator.selected_reclaim_seat == 1,
		"%s: the single missing seat is preselected" % phase_name
	)
	_check(
		room.assignments == assignments_before and room.pending_claims.size() == claims_before,
		"%s: claims and construction survive the disconnect" % phase_name
	)
	_pad(NEW_PAD_ID, JOY_BUTTON_A, true)
	_pad(NEW_PAD_ID, JOY_BUTTON_A, false)
	await _wait_frames(2)
	var reclaimed := room.input_router.registry.get_seat(1)
	_check(
		bool(reclaimed.connected) and int(reclaimed.device_id) == NEW_PAD_ID,
		"%s: one South press on the new pad reclaims the seat" % phase_name
	)
	_check(
		int(reclaimed.identity) == 2 and str(reclaimed.shape) == "TRIANGLE",
		"%s: number and shape are preserved on reclaim" % phase_name
	)
	await _free_flow()


# --- 5. double activation / echo ---------------------------------------------------------------


func _test_double_activation_and_echo() -> void:
	await _new_flow()
	# K2 joins the Title with Enter; then Enter must activate Start exactly once.
	_key("K2", KEY_ENTER, true)
	_key("K2", KEY_ENTER, false)
	await process_frame
	var title := flow._screen as UiTitleScreen
	var counter := {"starts": 0}
	title.start_requested.connect(func() -> void: counter.starts += 1)
	for button_name in ["StartButton", "LibraryButton", "SettingsButton", "QuitButton"]:
		_check(
			(title.get_node("%" + button_name) as Button).focus_mode == Control.FOCUS_NONE,
			"%s takes no Godot focus (no Enter double activation)" % button_name
		)
	_key("K2", KEY_ENTER, true)
	_key("K2", KEY_ENTER, true, true)
	_key("K2", KEY_ENTER, true, true)
	_key("K2", KEY_ENTER, false)
	await _wait_frames(2)
	_check(counter.starts == 1, "Enter plus OS key-repeat echo activates Start exactly once")
	_check(
		flow.room != null and flow.state == GameFlow.State.IN_MATCH, "exactly one room was created"
	)
	await _free_flow()


func _test_title_without_a_match() -> void:
	await _new_flow()
	flow.router._handle_key(_key_event(KEY_ESCAPE, true))
	await _wait_frames(2)
	_check(
		not get_root_paused(), "Esc at the Title does not freeze the game (no pause coordinator)"
	)
	flow.router._handle_key(_key_event(KEY_ESCAPE, false))
	# Library and Settings are reachable and return to the Title.
	_join_title_k1()
	await _wait_frames(2)
	var title := flow._screen as UiTitleScreen
	title.library_requested.emit()
	await process_frame
	_check(
		flow.state == GameFlow.State.LIBRARY and flow._screen is UiLibraryScreen,
		"Library opens from the Title"
	)
	flow._screen.back_requested.emit()
	await process_frame
	_check(flow.state == GameFlow.State.TITLE, "Library returns to the Title")
	flow._screen.settings_requested.emit()
	await process_frame
	_check(
		flow.state == GameFlow.State.SETTINGS and flow._screen is UiSettingsScreen,
		"Settings opens from the Title"
	)
	flow._screen.back_requested.emit()
	await process_frame
	_check(flow.state == GameFlow.State.TITLE, "Settings returns to the Title")
	await _free_flow()


# --- 5b. DEBUG overlay and the harness ----------------------------------------------------------


func _test_debug_overlay_and_harness_hosting() -> void:
	var harness := HARNESS_SCENE.instantiate() as FoundationHarness
	root.add_child(harness)
	await _wait_frames(3)
	harness._open_room("ui_player_flow")
	await _wait_frames(3)
	var hosted := harness.active_room as GameFlow
	_check(hosted != null and hosted.harness_mode, "the harness hosts the live player flow")
	hosted._quit()
	await _wait_frames(2)
	_check(harness.active_room == null, "Quit inside the harness returns to the harness")
	harness._open_room("p05_match")
	await _wait_frames(4)
	var room := harness.active_room as P05MatchRoom
	_check(
		room != null and room.presenter.debug_overlay.visible,
		"a match room opened by the harness shows the DEBUG overlay"
	)
	for node in get_nodes_in_group(P03StageRoom.DEBUG_WORLD_GROUP):
		_check((node as CanvasItem).visible, "diagnostic world lines show with the overlay on")
	room.presenter._unhandled_key_input(_key_event(KEY_F3, true))
	await process_frame
	_check(not room.presenter.debug_overlay.visible, "F3 hides the DEBUG overlay")
	_check(
		get_nodes_in_group(P03StageRoom.DEBUG_WORLD_GROUP).size() > 0,
		"the support test line is tagged as diagnostics"
	)
	for node in get_nodes_in_group(P03StageRoom.DEBUG_WORLD_GROUP):
		_check(not (node as CanvasItem).visible, "diagnostic world lines hide with the overlay off")
	room.presenter._unhandled_key_input(_key_event(KEY_F3, false))
	harness.queue_free()
	await _wait_frames(3)


# --- 6. lifecycle -------------------------------------------------------------------------------


func _test_round_lifecycle() -> void:
	var room := await _room_in_play()
	var presenter := room.presenter
	var ui_nodes_after_first := _count_nodes(presenter)
	for round_index in range(ROUNDS_FOR_LIFECYCLE):
		await _finish_race_and_advance(room, round_index)
	var ui_nodes_after_ten := _count_nodes(presenter)
	_check(
		ui_nodes_after_ten == ui_nodes_after_first,
		(
			"UI node count is stable over %d rounds (%d -> %d)"
			% [ROUNDS_FOR_LIFECYCLE, ui_nodes_after_first, ui_nodes_after_ten]
		)
	)
	_check(
		room.items.persistent_count() >= ROUNDS_FOR_LIFECYCLE,
		"construction persisted across rounds"
	)
	await _free_flow()
	await _wait_frames(3)
	_check(
		int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)) == 0,
		"no orphan nodes after freeing the match"
	)


func _test_title_lobby_cycles() -> void:
	await _new_flow()
	var samples: Array[int] = []
	for cycle in range(CYCLES_FOR_LIFECYCLE):
		_join_title_k1()
		await _wait_frames(2)
		_key("K1", KEY_E, true)
		await process_frame
		_key("K1", KEY_E, false)
		await _wait_frames(2)
		_check(flow.room != null, "cycle %d: Title -> Lobby opens a room" % (cycle + 1))
		# K1 G = back: Lobby -> Title (clears the session).
		_key("K1", KEY_G, true)
		_key("K1", KEY_G, false)
		await _wait_frames(3)
		_check(
			flow.room == null and flow.state == GameFlow.State.TITLE,
			"cycle %d: Lobby Back returns to the Title" % (cycle + 1)
		)
		_check(
			flow.router.registry.joined_seats().is_empty(),
			"cycle %d: the session is cleared" % (cycle + 1)
		)
		samples.append(int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
	_check(
		samples[samples.size() - 1] == samples[1],
		(
			"node count is stable over %d Title <-> Lobby cycles (%d -> %d)"
			% [CYCLES_FOR_LIFECYCLE, samples[1], samples[samples.size() - 1]]
		)
	)
	await _free_flow()


# --- 7. source rules ------------------------------------------------------------------------------


func _test_source_rules() -> void:
	for path in SOURCE_FILES:
		var text := FileAccess.get_file_as_string(path)
		var clean := not text.is_empty()
		for token in FORBIDDEN_TOKENS:
			if text.contains(token):
				clean = false
				push_error("%s contains %s" % [path, token])
		_check(clean, "%s creates no Controls and adds no theme overrides" % path.get_file())
	_check(
		not FileAccess.file_exists("res://scripts/match/match_results_panel.gd"),
		"the code-built results panel is deleted"
	)


# --- helpers ------------------------------------------------------------------------------------


func _new_flow() -> void:
	flow = FLOW_SCENE.instantiate() as GameFlow
	# This suite covers the first-playable (P07 gate) route; the scheduled match is the default
	# since 2026-10-15 and is covered by the mode, P12 and P13 suites.
	flow.match_scene = GameFlow.MATCH_SCENE
	root.add_child(flow)
	await _wait_frames(3)


func _free_flow() -> void:
	if flow != null and is_instance_valid(flow):
		flow.queue_free()
	flow = null
	paused = false
	await _wait_frames(3)


func get_root_paused() -> bool:
	return paused


## Title -> two seats -> Lobby -> match -> Play (both seated with K1 and K2).
func _room_in_play() -> P05MatchRoom:
	await _new_flow()
	_join_title_k1()
	await _wait_frames(2)
	_key("K1", KEY_E, true)
	await process_frame
	_key("K1", KEY_E, false)
	await process_frame
	var room := flow.room
	_key("K2", KEY_ENTER, true)
	_key("K2", KEY_ENTER, false)
	await process_frame
	_key("K1", KEY_E, true)
	_key("K1", KEY_E, false)
	_key("K2", KEY_ENTER, true)
	_key("K2", KEY_ENTER, false)
	await _wait_frames(2)
	await _claim_and_confirm(room)
	return room


## Title -> two seats -> Lobby -> match -> Place (both claimed).
func _room_in_place() -> P05MatchRoom:
	await _new_flow()
	_join_title_k1()
	await _wait_frames(2)
	_key("K1", KEY_E, true)
	await process_frame
	_key("K1", KEY_E, false)
	await process_frame
	var room := flow.room
	_key("K2", KEY_ENTER, true)
	_key("K2", KEY_ENTER, false)
	await process_frame
	_key("K1", KEY_E, true)
	_key("K1", KEY_E, false)
	_key("K2", KEY_ENTER, true)
	_key("K2", KEY_ENTER, false)
	await _wait_frames(2)
	room.assignments = {0: str(room.egg_pool[0].egg_id), 1: str(room.egg_pool[1].egg_id)}
	room._enter_place()
	await _wait_frames(2)
	return room


func _claim_and_confirm(room: P05MatchRoom, round_index: int = 0) -> void:
	room.assignments = {0: str(room.egg_pool[0].egg_id), 1: str(room.egg_pool[1].egg_id)}
	room._enter_place()
	await process_frame
	var piece := room.items.place(
		"build.hollow_blocks.cell_1x1", Vector2i(6 + round_index * 2, 8), 0, 0
	)
	_check(bool(piece.allowed), "round %d: a persistent piece is placed" % (round_index + 1))
	room._enter_play()
	await _wait_frames(2)


func _finish_race_and_advance(room: P05MatchRoom, round_index: int) -> void:
	var goal := room.goal_area.global_position
	for actor_variant in room.actors.values():
		(actor_variant as ChickenController).global_position = goal
	await _wait_physics_frames(GOAL_PHYSICS_FRAMES)
	await _wait_frames(2)
	room._on_match_action_pressed(0, "confirm")
	room._on_match_action_pressed(1, "confirm")
	await process_frame
	await _claim_and_confirm(room, round_index + 1)


## The Title menu shows with nobody joined; a first menu press joins and acts. Down then up joins
## K1 and leaves Play selected without activating anything.
func _join_title_k1() -> void:
	_key("K1", KEY_S, true)
	_key("K1", KEY_S, false)
	_key("K1", KEY_W, true)
	_key("K1", KEY_W, false)


## Each egg preview counts as one node: its contents are the rolled block's own Visual, which
## differs per item (Bomb vs Kaing), so the total would change with the eggs, not with leaks.
func _count_nodes(node: Node) -> int:
	var total := 1
	if node is ItemEggPreview:
		return total
	for child in node.get_children():
		total += _count_nodes(child)
	return total


func _key_event(key: Key, pressed: bool, echo: bool = false) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.pressed = pressed
	event.echo = echo
	return event


func _key(_layout: String, key: Key, pressed: bool, echo: bool = false) -> void:
	flow.router._handle_key(_key_event(key, pressed, echo))


func _pad(device_id: int, button: JoyButton, pressed: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.device = device_id
	event.button_index = button
	event.pressed = pressed
	flow.router._handle_joy_button(event)


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
		push_error("MATCH_UI FAIL: " + message)

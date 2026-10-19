class_name MatchScreenPresenter
extends CanvasLayer

## Drives the scene-authored UI screens (lobby, Pugad, Place, Play HUD, round result, pause and the
## DEBUG overlay) from the live P05/P06 match state. It only formats text and toggles visibility:
## scores, awards, deadlines and verdicts all come from the room's controllers and view models.
##
## Game input stays with P05MatchRoom. In Pugad, Place, Play and Results the screens are
## display-only; the UiInputBridge is attached only to menu-type screens (Lobby back, Pause and the
## Settings / Library shown from Pause). The P09 match-result screen and its confirmation dialog are
## shown from here but driven by the room's own lifecycle rules. Bindings run on change, never per
## frame.

const SETTINGS_SCENE := preload("res://scenes/ui/screens/settings_screen.tscn")
const LIBRARY_SCENE := preload("res://scenes/ui/screens/library_screen.tscn")
const NOTICE_SECONDS := 5.0
const DEBUG_REFRESH_SECONDS := 0.25
const DEBUG_OVERLAY_FLAG := "--debug-overlay"
const LIST_SEPARATOR := "   •   "
const PHASE_NAMES := ["LOBBY", "PUGAD", "PLACE", "PLAY", "RESULTS"]
const CHEER_STATE_TEXT := "CHEER!"
## HUD chip words during Place (Figma "Obstacle Place").
const PLACE_STATE_PLACING := "Placing"
const PLACE_STATE_PLACED := "Placed"

var room: P05MatchRoom
var bridge: UiInputBridge
var prompt_map: UiPromptMap
var debug_visible := false
var debug_toggle_allowed := false

var _dirty := true
var _eggs_dirty := true
var _whole_seconds := -1
var _notice_text := ""
var _notice_left := 0.0
var _overlay: UiScreen
var _bridge_target: UiScreen
var _debug_accum := 0.0
var _game_input_suspended := false
var _tutorial: TutorialCoordinator
var _lobby_leave_seat := -1
## Spectator cheer: cooldowns, the HUD marks being shown and the soft crowd cue (presentation only).
var _cheer := SpectatorCheer.new()
var _cheer_marks: Dictionary = {}
var _cheer_player: AudioStreamPlayer

@onready var lobby_screen: UiLobbyScreen = %LobbyScreen
@onready var play_hud: UiPlayHud = %PlayHud
@onready var pugad_overlay: UiPugadOverlay = %PugadOverlay
@onready var place_overlay: UiPlaceOverlay = %PlaceOverlay
@onready var result_screen: UiRoundResultScreen = %RoundResultScreen
@onready var match_result_screen: UiMatchResultScreen = %MatchResultScreen
@onready var pause_screen: UiPauseScreen = %PauseScreen
@onready var confirm_overlay: Control = %ConfirmOverlay
@onready var confirm_dialog: UiConfirmDialog = %ConfirmDialog
@onready var debug_overlay: UiDebugOverlay = %DebugOverlay
@onready var tutorial_prompt: UiTutorialPrompt = %TutorialPrompt


func _ready() -> void:
	debug_toggle_allowed = (
		OS.is_debug_build() or OS.get_cmdline_user_args().has(DEBUG_OVERLAY_FLAG)
	)
	for screen in [lobby_screen, play_hud, pugad_overlay, place_overlay, result_screen]:
		(screen as Control).visible = false
	pause_screen.visible = false
	match_result_screen.visible = false
	confirm_overlay.visible = false
	debug_overlay.visible = false
	tutorial_prompt.visible = false


func _exit_tree() -> void:
	unbind_tutorial()
	_disconnect_room()
	_cheer.reset()


## Called once by the room at the end of its _ready (items and definitions exist by then).
func attach(p_room: P05MatchRoom) -> void:
	room = p_room
	prompt_map = load(UiContext.PROMPT_MAP_PATH) as UiPromptMap
	bridge = UiInputBridge.new()
	bridge.name = "MatchUiBridge"
	add_child(bridge)
	bridge.attach(room.input_router)
	room.presentation_changed.connect(_on_room_changed)
	room.phase_controller.phase_changed.connect(_on_phase_changed)
	room.actor_created.connect(_on_actor_created)
	for actor_variant in room.actors.values():
		_on_actor_created(actor_variant as ChickenController)
	var router := room.input_router
	router.seat_joined.connect(_on_seat_signal)
	router.seat_disconnected.connect(_on_seat_signal)
	router.device_status_changed.connect(_on_device_status)
	router.action_pressed.connect(_on_router_action)
	var coordinator := room.pause_coordinator
	coordinator.pause_state_changed.connect(_on_pause_state_changed)
	coordinator.menu_selection_changed.connect(_on_pause_selection)
	coordinator.recovery_complete.connect(_on_recovery_complete)
	coordinator.reclaim_prompted.connect(_on_reclaim_prompted)
	pause_screen.bind_coordinator(coordinator, router.registry, prompt_map)
	pause_screen.resume_requested.connect(_on_resume_requested)
	pause_screen.settings_requested.connect(_open_overlay.bind(SETTINGS_SCENE))
	pause_screen.library_requested.connect(_open_overlay.bind(LIBRARY_SCENE))
	pause_screen.leave_confirmed.connect(_on_leave_confirmed)
	lobby_screen.leave_requested.connect(_on_lobby_leave)
	lobby_screen.map_step_requested.connect(func(step: int) -> void: room.request_map_step(step))
	lobby_screen.back_requested.connect(_on_lobby_back)
	debug_overlay.join_requested.connect(func(layout: String) -> void: room.join_keyboard(layout))
	debug_overlay.start_requested.connect(func() -> void: room.start_match())
	debug_overlay.pause_requested.connect(func() -> void: room._toggle_pause())
	debug_overlay.return_requested.connect(func() -> void: room.request_return())
	debug_overlay.harness_requested.connect(func() -> void: room.flow_requested.emit(&"harness"))
	debug_overlay.extra_requested.connect(func() -> void: room.run_debug_action())
	set_debug_visible(room.debug_overlay_default)
	_eggs_dirty = true
	_dirty = true


## Optional guided-round coach. The presenter only shows what the coordinator publishes, hides it
## while pause / overlays / confirmations / final results own the screen, and forwards Skip.
func bind_tutorial(coordinator: TutorialCoordinator) -> void:
	unbind_tutorial()
	_tutorial = coordinator
	if _tutorial == null:
		return
	_tutorial.step_changed.connect(_on_tutorial_step)
	pause_screen.skip_tutorial_requested.connect(_on_skip_tutorial_requested)
	tutorial_prompt.bind_live(_tutorial.view)
	_dirty = true


func unbind_tutorial() -> void:
	if _tutorial != null and is_instance_valid(_tutorial):
		if _tutorial.step_changed.is_connected(_on_tutorial_step):
			_tutorial.step_changed.disconnect(_on_tutorial_step)
	if (
		pause_screen != null
		and pause_screen.skip_tutorial_requested.is_connected(_on_skip_tutorial_requested)
	):
		pause_screen.skip_tutorial_requested.disconnect(_on_skip_tutorial_requested)
	_tutorial = null
	if tutorial_prompt != null:
		tutorial_prompt.visible = false


func set_debug_visible(value: bool) -> void:
	debug_visible = value
	if debug_overlay != null:
		debug_overlay.visible = value
	if is_inside_tree():
		get_tree().call_group(P03StageRoom.DEBUG_WORLD_GROUP, "set_visible", value)
	_dirty = true


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or key.keycode != KEY_F3:
		return
	if debug_toggle_allowed:
		set_debug_visible(not debug_visible)


func _process(delta: float) -> void:
	if room == null:
		return
	if _notice_left > 0.0 and not get_tree().paused:
		_notice_left -= delta
		if _notice_left <= 0.0:
			_notice_text = ""
			_dirty = true
	if not get_tree().paused:
		_cheer.advance(delta)
		_expire_cheer_marks(delta)
	var whole := _current_whole_seconds()
	if whole != _whole_seconds:
		_whole_seconds = whole
		_dirty = true
	if debug_visible:
		_debug_accum += delta
		if _debug_accum >= DEBUG_REFRESH_SECONDS:
			_debug_accum = 0.0
			_dirty = true
	if _dirty:
		_apply()


# --- change notifications -------------------------------------------------------------------


func _on_room_changed(_reason: StringName) -> void:
	_dirty = true


func _on_phase_changed(
	previous_phase: MatchPhaseController.Phase, next_phase: MatchPhaseController.Phase
) -> void:
	_dirty = true
	if next_phase == MatchPhaseController.Phase.PUGAD:
		_eggs_dirty = true
	if (
		previous_phase == MatchPhaseController.Phase.PLACE
		and next_phase == MatchPhaseController.Phase.PLAY
	):
		_notice_text = room.place_notice if not room.place_notice.is_empty() else _play_hint()
		_notice_left = NOTICE_SECONDS


func _on_tutorial_step(view: Dictionary) -> void:
	tutorial_prompt.bind_live(view)


func _on_skip_tutorial_requested() -> void:
	if _tutorial != null:
		_tutorial.skip()
	_dirty = true


func _on_replay_tutorial_requested() -> void:
	if _tutorial != null and _tutorial.session != null:
		_tutorial.session.replay()


func _on_actor_created(actor: ChickenController) -> void:
	if actor == null or not is_instance_valid(actor):
		return
	if not actor.terminal_state_changed.is_connected(_on_actor_terminal):
		actor.terminal_state_changed.connect(_on_actor_terminal)


func _on_actor_terminal(_status: PlayerLifecycleState.Status, _reason: String) -> void:
	_dirty = true


func _on_seat_signal(_seat_index: int) -> void:
	_dirty = true


func _on_device_status(_device_id: int, _connected: bool) -> void:
	_dirty = true


## Ready edges change the registry without a coordinator signal; re-read the roster.
func _on_router_action(seat_index: int, action_name: String) -> void:
	_dirty = true
	if action_name == LocalInputRouter.ROTATE_ALIAS_PLAY:
		_try_cheer(seat_index)
	if action_name == LocalInputRouter.ROTATE_ALIAS_LOBBY and seat_index >= 0:
		_open_overlay(LIBRARY_SCENE, seat_index)


## A seat that is out or has finished may cheer during Play: a short HUD mark in its own score
## row plus a soft crowd cue on the Crowd bus. A live chicken, another phase, a pause or the final
## result ignore it. Nothing here reaches the simulation.
func _try_cheer(seat_index: int) -> void:
	if not _cheer.request(seat_index, _can_cheer(seat_index)):
		return
	_cheer_marks[seat_index] = SpectatorCheer.SHOW_SECONDS
	_play_cheer_cue()
	_dirty = true


func _can_cheer(seat_index: int) -> bool:
	if room == null or seat_index < 0 or get_tree().paused:
		return false
	if room.phase_controller.phase != MatchPhaseController.Phase.PLAY:
		return false
	if (
		room.shows_final_results()
		or room.pause_coordinator.state != PauseRecoveryCoordinator.State.RUNNING
	):
		return false
	var seat := room.input_router.registry.get_seat(seat_index)
	if seat.is_empty() or not bool(seat.get("joined", false)):
		return false
	var actor := room.actors.get(seat_index) as ChickenController
	if actor == null or not is_instance_valid(actor):
		return false
	return (
		actor.lifecycle.status
		in [PlayerLifecycleState.Status.SECURED, PlayerLifecycleState.Status.ELIMINATED]
	)


func _expire_cheer_marks(delta: float) -> void:
	for seat in _cheer_marks.keys():
		var left := float(_cheer_marks[seat]) - delta
		if left <= 0.0:
			_cheer_marks.erase(seat)
			_dirty = true
		else:
			_cheer_marks[seat] = left


func _play_cheer_cue() -> void:
	if _cheer_player == null:
		_cheer_player = AudioStreamPlayer.new()
		_cheer_player.name = "CheerCue"
		_cheer_player.bus = PresentationApplier.BUS_CROWD
		_cheer_player.volume_db = -10.0
		_cheer_player.stream = SpectatorCheer.make_stream()
		add_child(_cheer_player)
	_cheer_player.play()


## Seats currently showing the cheer mark (for tests and captures).
func cheering_seats() -> Array[int]:
	var seats: Array[int] = []
	for seat in _cheer_marks:
		seats.append(int(seat))
	return seats


func cheer_cooldown_remaining(seat_index: int) -> float:
	return _cheer.remaining(seat_index)


func _on_pause_state_changed(paused: bool, _reason: String) -> void:
	_set_game_input_suspended(paused)
	if not paused:
		_close_overlay()
	_dirty = true


func _on_pause_selection(_index: int, _owner_seat: int) -> void:
	_dirty = true


func _on_recovery_complete() -> void:
	# Seats were readied only to resume; a Lobby must not read them as "start the match".
	if room.phase_controller.phase == MatchPhaseController.Phase.LOBBY:
		for seat in room.input_router.registry.joined_seats():
			room.input_router.registry.set_ready(int(seat.seat), false)
	_dirty = true


func _on_reclaim_prompted(_device_id: int, missing_seats: Array[int]) -> void:
	var coordinator := room.pause_coordinator
	if missing_seats.size() == 1 and coordinator.choose_reclaim_seat(missing_seats[0]):
		coordinator.confirm_reclaim()
	_dirty = true


func _on_resume_requested() -> void:
	var coordinator := room.pause_coordinator
	if coordinator.menu_owner >= 0:
		coordinator.mark_ready(coordinator.menu_owner)
	_dirty = true


func _on_leave_confirmed() -> void:
	_request_flow(&"leave_match")


func _on_lobby_leave(seat_index: int) -> void:
	_lobby_leave_seat = seat_index


## Back in the Lobby clears the session: once a seat is ready the room asks first. While the
## confirmation is up the bridge is detached so the same Back press cannot reopen it.
func _on_lobby_back() -> void:
	if room.is_confirmation_open():
		return
	if room.confirm_lobby_exit(_lobby_leave_seat):
		bridge.screen = null
		_bridge_target = null
		_dirty = true
		return
	_request_flow(&"lobby_back")


## Without an owner listening (the harness) leaving simply returns to the harness.
func _request_flow(kind: StringName) -> void:
	if room.flow_requested.get_connections().is_empty():
		room.request_return()
	else:
		room.flow_requested.emit(kind)


# --- pause owns the keys ----------------------------------------------------------------------


## While the pause screen is up the room must not read the menu presses as game input (a confirm
## on Resume would lock a placement, arrows would move the Place cursor). The room's rules are
## untouched: its handlers are simply detached from the router until the game resumes.
func _set_game_input_suspended(value: bool) -> void:
	if value == _game_input_suspended or room == null or not is_instance_valid(room):
		return
	_game_input_suspended = value
	var router := room.input_router
	var action_handler := Callable(room, "_on_match_action_pressed")
	var navigation_handler := Callable(room, "_on_match_navigation_step")
	if value:
		if router.action_pressed.is_connected(action_handler):
			router.action_pressed.disconnect(action_handler)
		if router.navigation_step.is_connected(navigation_handler):
			router.navigation_step.disconnect(navigation_handler)
	else:
		if not router.action_pressed.is_connected(action_handler):
			router.action_pressed.connect(action_handler)
		if not router.navigation_step.is_connected(navigation_handler):
			router.navigation_step.connect(navigation_handler)


# --- pause overlays (Settings / Library from Pause) -------------------------------------------


## Settings / Library from Pause (the simulation stays frozen under it) or Library from the Lobby
## (no simulation yet; the seat that asked for help drives it). `seat_override` < 0 means "the
## pause menu owner".
func _open_overlay(scene: PackedScene, seat_override: int = -1) -> void:
	if _overlay != null:
		return
	var from_pause := room.pause_coordinator.state == PauseRecoveryCoordinator.State.PAUSED
	var from_lobby := _lobby_overlay_allowed() and seat_override >= 0
	if not from_pause and not from_lobby:
		return
	var screen := scene.instantiate() as UiScreen
	if screen == null:
		return
	add_child(screen)
	move_child(screen, debug_overlay.get_index())
	if from_lobby and not from_pause:
		# The Lobby listens for join / ready presses; a menu needs the MENU navigation phase.
		room.input_router.set_phase(LocalInputRouter.Phase.MENU)
		screen.owner_seat = seat_override
	else:
		room.input_router.consume_held_presses()
		screen.owner_seat = room.pause_coordinator.menu_owner
	if screen is UiLibraryScreen:
		var library_text := load(UiContext.LIBRARY_TEXT_PATH) as UiLibraryText
		var library := screen as UiLibraryScreen
		var reference: ItemDefinitions = null
		if UiLibraryScreen.dev_mode_requested():
			reference = UiLibraryScreen.reference_definitions_for(room.tuning)
		var context := UiLibraryText.build_context(
			room.tuning, prompt_map, room.presentation_settings.screen_shake
		)
		library.bind_live(room.definitions, room.tuning, library_text, context, reference)
		if _tutorial != null:
			library.replay_tutorial_enabled = true
			library.replay_tutorial_requested.connect(_on_replay_tutorial_requested)
			library.choose_category(library.category)
	elif screen is UiSettingsScreen:
		(screen as UiSettingsScreen).bind_live(room.presentation_settings)
	screen.back_requested.connect(_close_overlay)
	_overlay = screen
	_dirty = true


func _close_overlay() -> void:
	if _overlay == null:
		return
	if is_instance_valid(_overlay):
		remove_child(_overlay)
		_overlay.queue_free()
	_overlay = null
	if _lobby_overlay_allowed() and room.input_router.phase == LocalInputRouter.Phase.MENU:
		room.input_router.set_phase(LocalInputRouter.Phase.LOBBY)
	else:
		room.input_router.consume_held_presses()
	_dirty = true


func _lobby_overlay_allowed() -> bool:
	return (
		room.phase_controller.phase == MatchPhaseController.Phase.LOBBY
		and not room.shows_final_results()
		and room.pause_coordinator.state == PauseRecoveryCoordinator.State.RUNNING
	)


# --- applying the state -----------------------------------------------------------------------


func _apply() -> void:
	_dirty = false
	var phase := room.phase_controller.phase
	var paused := room.pause_coordinator.state != PauseRecoveryCoordinator.State.RUNNING
	var seats := _all_seats()
	var final_results := room.shows_final_results()
	var in_lobby := phase == MatchPhaseController.Phase.LOBBY and not final_results
	lobby_screen.visible = in_lobby
	pugad_overlay.visible = phase == MatchPhaseController.Phase.PUGAD and not final_results
	place_overlay.visible = phase == MatchPhaseController.Phase.PLACE and not final_results
	result_screen.visible = phase == MatchPhaseController.Phase.RESULTS and not final_results
	# The room binds the final model and drives replay / lobby / quit itself (P09).
	match_result_screen.visible = final_results
	# Pugad draws its own HUD rail and chip column (Figma "Obstacle Pick").
	play_hud.visible = (
		not final_results
		and (
			phase
			in [
				MatchPhaseController.Phase.PLACE,
				MatchPhaseController.Phase.PLAY,
				MatchPhaseController.Phase.GO
			]
		)
	)
	match phase:
		MatchPhaseController.Phase.LOBBY:
			lobby_screen.bind_live(room.input_router.registry, prompt_map)
			lobby_screen.bind_map(room.map_choice_label, room.map_selection_enabled)
		MatchPhaseController.Phase.PUGAD:
			_apply_pugad(seats)
		MatchPhaseController.Phase.PLACE:
			_apply_place(seats)
		MatchPhaseController.Phase.RESULTS:
			if not final_results:
				_apply_results(seats)
	if play_hud.visible:
		_apply_hud(seats, phase)
	pause_screen.visible = paused and _overlay == null
	_set_game_input_suspended(paused)
	if paused:
		pause_screen.refresh_live()
	_apply_bridge(phase, paused)
	_apply_debug(phase, paused)
	_apply_tutorial(paused, final_results)


func _apply_tutorial(paused: bool, final_results: bool) -> void:
	if _tutorial == null or not is_instance_valid(_tutorial):
		return
	var hidden := paused or final_results or _overlay != null or confirm_overlay.visible
	_tutorial.set_suppressed(hidden)
	var session := _tutorial.session
	pause_screen.set_skip_tutorial_available(session != null and session.is_active())
	var results_box := (
		tutorial_prompt.visible and str(_tutorial.view.get("step_id", "")) == "results"
	)
	result_screen.reserve_side_strip(tutorial_prompt.results_strip_width if results_box else 0.0)


func _apply_pugad(seats: Array[Dictionary]) -> void:
	if _eggs_dirty:
		pugad_overlay.bind_live_eggs(room.definitions, room.egg_pool, room.tuning)
		_eggs_dirty = false
		var announcement := room.round_announcement()
		pugad_overlay.bind_announcement(
			str(announcement.get("title", "")), str(announcement.get("detail", ""))
		)
	pugad_overlay.bind_live_hud(
		room.items.round_number + 1,
		room.play_challenge_text(),
		room.play_twist_text(),
		seats,
		room.cumulative_score_units,
		room.assignments
	)
	# The frame's hint row reads "← → Choose" and "<pick keys>  Pick"; pass the pick keys.
	var hint := _glyphs("claim")
	pugad_overlay.bind_live_state(
		seats,
		room.assignments,
		room.selected_egg_by_seat,
		_lost_claim_text(seats),
		hint,
		room.phase_controller.remaining_seconds,
		room.tuning.match_pugad_seconds
	)


func _apply_place(seats: Array[Dictionary]) -> void:
	var rows: Array[Dictionary] = []
	var reasons := PackedStringArray()
	var seat_indices: Array = room.placement_controller.cursors.keys()
	seat_indices.sort()
	for seat_variant in seat_indices:
		var seat_index := int(seat_variant)
		var cursor: Dictionary = room.placement_controller.cursors[seat_index]
		var verdict: Dictionary = room.placement_verdicts.get(seat_index, {})
		var allowed := bool(verdict.get("allowed", true))
		var confirmed := bool(cursor.confirmed)
		(
			rows
			. append(
				{
					"seat_index": seat_index,
					"variant": room.variant_label(str(cursor.variant_key)),
					"confirmed": confirmed,
					"allowed": allowed,
				}
			)
		)
		var text := str(room.place_notices.get(seat_index, ""))
		if text.is_empty() and not allowed and not confirmed:
			text = str(verdict.get("reason", ""))
		if not text.is_empty():
			reasons.append("%s: %s" % [_seat_tag(seats, seat_index), text])
	# The Guide card writes the keys as the frame does ("W A S D/Arrow keys"), one action per line.
	var hint := "\n".join([_hint("navigate"), _hint("rotate"), _hint("confirm")]).replace(
		" / ", "/"
	)
	place_overlay.bind_live(
		seats,
		rows,
		LIST_SEPARATOR.join(reasons),
		hint,
		room.phase_controller.remaining_seconds,
		room.tuning.match_place_seconds
	)


func _apply_hud(seats: Array[Dictionary], phase: MatchPhaseController.Phase) -> void:
	var timer_text := ""
	var window_text := ""
	var notice := ""
	if phase == MatchPhaseController.Phase.PLAY:
		timer_text = _clock_text(room.play_clock_seconds())
		window_text = room.play_tag_text()
		notice = room.play_status_text()
		if notice.is_empty():
			notice = _notice_text
	elif phase == MatchPhaseController.Phase.GO:
		timer_text = _clock_text(_phase_seconds(phase))
		notice = room.play_status_text()
	var states := {}
	for seat in seats:
		if bool(seat.joined):
			states[int(seat.seat)] = _state_text(int(seat.seat), phase)
	play_hud.bind_live(
		room.items.round_number + 1,
		timer_text,
		window_text,
		seats,
		room.cumulative_score_units,
		states,
		notice,
		room.play_challenge_text(),
		room.play_twist_text(),
		room.hud_up_next_text() if phase == MatchPhaseController.Phase.PLAY else ""
	)


func _apply_results(seats: Array[Dictionary]) -> void:
	var model := room.last_results_model
	if model == null or model.round_number != room.items.round_number:
		return
	result_screen.bind_live(
		model,
		seats,
		room.results_ready,
		room.phase_controller.remaining_seconds,
		room.tuning.match_results_advance_seconds,
		_first_device_kind(seats),
		prompt_map,
		room.presentation_settings.result_reveal_motion,
		room.results_twist_text(),
		room.hud_up_next_text()
	)


func _apply_bridge(phase: MatchPhaseController.Phase, paused: bool) -> void:
	var target: UiScreen = null
	if room.is_confirmation_open():
		target = null
	elif _overlay != null:
		target = _overlay
	elif paused:
		target = pause_screen
	elif phase == MatchPhaseController.Phase.LOBBY and not room.shows_final_results():
		target = lobby_screen
	if target != _bridge_target:
		_bridge_target = target
		bridge.screen = target


func _apply_debug(phase: MatchPhaseController.Phase, paused: bool) -> void:
	debug_overlay.visible = debug_visible
	if not debug_visible:
		return
	var registry := room.input_router.registry
	var identity := (
		"%s • %s • profile %s • seed %d • run %d • %s %s"
		% [
			room.build_id(),
			PHASE_NAMES[phase],
			room.profile_id,
			room.match_seed,
			room.match_run_id,
			_clock_text(_phase_seconds(phase)),
			"PAUSED" if paused else "",
		]
	)
	var seat_rows := PackedStringArray()
	for row in LobbyViewModel.seat_rows(registry):
		var state := "READY" if row.ready else "NOT READY"
		if not row.connected:
			state = "DISCONNECTED"
		seat_rows.append("P%d %s %s — %s" % [row.identity, row.mark, row.shape, state])
	var feedback := PackedStringArray()
	var mode_status := room.debug_status_text()
	if not mode_status.is_empty():
		feedback.append(mode_status)
	if not room.last_message.is_empty():
		feedback.append(room.last_message)
	for seat_index in room.claim_feedback:
		feedback.append("P%d — %s" % [int(seat_index) + 1, room.claim_feedback[seat_index]])
	debug_overlay.show_info(
		identity,
		"   ".join(seat_rows),
		"\n".join(feedback),
		(
			"F3 hides this overlay · assignments %d · pieces %d"
			% [room.assignments.size(), room.items.persistent_count()]
		)
	)
	debug_overlay.set_controls(
		phase == MatchPhaseController.Phase.LOBBY,
		LobbyViewModel.can_start(registry),
		paused,
		room.allow_harness_button and debug_toggle_allowed,
		room.debug_action_label()
	)


# --- formatting helpers (text only) -----------------------------------------------------------


func _all_seats() -> Array[Dictionary]:
	var seats: Array[Dictionary] = []
	for index in PlayerSeatRegistry.MAX_SEATS:
		seats.append(room.input_router.registry.get_seat(index))
	return seats


func _seat_tag(seats: Array[Dictionary], seat_index: int) -> String:
	if seat_index < 0 or seat_index >= seats.size():
		return "P?"
	var seat := seats[seat_index]
	return "P%d %s" % [int(seat.identity), LobbyViewModel.SHAPE_MARKS.get(str(seat.shape), "◆")]


func _lost_claim_text(seats: Array[Dictionary]) -> String:
	var lines := PackedStringArray()
	for seat_index in room.claim_feedback:
		lines.append("%s — claim lost, pick another egg" % _seat_tag(seats, int(seat_index)))
	return LIST_SEPARATOR.join(lines)


func _state_text(seat_index: int, phase: MatchPhaseController.Phase) -> String:
	if phase == MatchPhaseController.Phase.PLACE:
		return _place_state_text(seat_index)
	if phase != MatchPhaseController.Phase.PLAY:
		return ""
	if _cheer_marks.has(seat_index):
		return CHEER_STATE_TEXT
	var mode_state := room.seat_state_text(seat_index)
	if not mode_state.is_empty():
		return mode_state
	return _lifecycle_state_text(seat_index)


## The HUD chip during Place: Placed once the seat confirmed its piece, Placing before.
func _place_state_text(seat_index: int) -> String:
	var cursors: Dictionary = room.placement_controller.cursors
	if not cursors.has(seat_index):
		return ""
	return PLACE_STATE_PLACED if bool(cursors[seat_index].confirmed) else PLACE_STATE_PLACING


func _lifecycle_state_text(seat_index: int) -> String:
	var actor := room.actors.get(seat_index) as ChickenController
	if actor == null or not is_instance_valid(actor):
		return ""
	match actor.lifecycle.status:
		PlayerLifecycleState.Status.SECURED:
			return "SECURED"
		PlayerLifecycleState.Status.ELIMINATED:
			return "OUT"
	return "RUN"


func _first_device_kind(seats: Array[Dictionary]) -> String:
	for seat in seats:
		if bool(seat.joined):
			return UiContext.device_for_seat(seat)
	return "k1"


## "Claim egg: E / Enter / South" for the device kinds actually seated (all three if nobody is).
func _hint(action: String) -> String:
	return "%s: %s" % [prompt_map.action_name(action), _glyphs(action)]


## The joined seats' glyphs for one action ("South / Enter"), one per device kind.
func _glyphs(action: String) -> String:
	var kinds: Array[String] = []
	for seat in room.input_router.registry.joined_seats():
		var kind := UiContext.device_for_seat(seat)
		if not kinds.has(kind):
			kinds.append(kind)
	if kinds.is_empty():
		kinds = ["k1", "k2", "gamepad"]
	var glyphs := PackedStringArray()
	for kind in kinds:
		glyphs.append(prompt_map.glyph(action, kind))
	return " / ".join(glyphs)


func _play_hint() -> String:
	return "%s  %s  ·  %s" % [room.play_goal_text(), _hint("run"), _hint("jump")]


func _clock_text(seconds: float) -> String:
	var whole := ceili(maxf(seconds, 0.0))
	return "%d:%02d" % [floori(whole / 60.0), whole % 60]


func _phase_seconds(phase: MatchPhaseController.Phase) -> float:
	if phase == MatchPhaseController.Phase.PLAY:
		return room.play_clock_seconds()
	return room.phase_controller.remaining_seconds


func _current_whole_seconds() -> int:
	return ceili(_phase_seconds(room.phase_controller.phase))


func _disconnect_room() -> void:
	if room == null or not is_instance_valid(room):
		return
	if room.presentation_changed.is_connected(_on_room_changed):
		room.presentation_changed.disconnect(_on_room_changed)
	if room.phase_controller.phase_changed.is_connected(_on_phase_changed):
		room.phase_controller.phase_changed.disconnect(_on_phase_changed)
	if room.actor_created.is_connected(_on_actor_created):
		room.actor_created.disconnect(_on_actor_created)
	var router := room.input_router
	if router != null and is_instance_valid(router):
		if router.seat_joined.is_connected(_on_seat_signal):
			router.seat_joined.disconnect(_on_seat_signal)
		if router.seat_disconnected.is_connected(_on_seat_signal):
			router.seat_disconnected.disconnect(_on_seat_signal)
		if router.device_status_changed.is_connected(_on_device_status):
			router.device_status_changed.disconnect(_on_device_status)
		if router.action_pressed.is_connected(_on_router_action):
			router.action_pressed.disconnect(_on_router_action)
	var coordinator := room.pause_coordinator
	if coordinator != null and is_instance_valid(coordinator):
		if coordinator.pause_state_changed.is_connected(_on_pause_state_changed):
			coordinator.pause_state_changed.disconnect(_on_pause_state_changed)
		if coordinator.menu_selection_changed.is_connected(_on_pause_selection):
			coordinator.menu_selection_changed.disconnect(_on_pause_selection)
		if coordinator.recovery_complete.is_connected(_on_recovery_complete):
			coordinator.recovery_complete.disconnect(_on_recovery_complete)
		if coordinator.reclaim_prompted.is_connected(_on_reclaim_prompted):
			coordinator.reclaim_prompted.disconnect(_on_reclaim_prompted)

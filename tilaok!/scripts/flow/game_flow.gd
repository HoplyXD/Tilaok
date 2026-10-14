class_name GameFlow
extends Control

## The player-facing entry point: Title -> Lobby -> Pugad -> Place -> Play -> Round result ->
## next round, with Library / Settings from the Title and Pause over the match.
##
## One LocalInputRouter lives here and is injected into the match room, so seats and held-press
## consumption carry across Title <-> Lobby <-> match with no hand-off. P05MatchRoom stays the
## simulation and input owner; this node only owns the menus and the room's lifetime.

signal return_requested

enum State { TITLE, LIBRARY, SETTINGS, IN_MATCH }

const BUILD_LABEL := "Tilaok! development build"
## The first-playable route: karera_slice limited to the verified Kaing / Tulay variants.
const MATCH_SCENE := preload("res://scenes/match/p07_first_playable_room.tscn")
## Opt-in route with the P09 match lifecycle (score target / round limit, sudden death, final
## result screen, Replay / Return to Lobby): `-- --match-route=lifecycle`.
const LIFECYCLE_SCENE := preload("res://scenes/match/p09_match_lifecycle_room.tscn")
const ROUTE_PREFIX := "--match-route="
const ROUTE_LIFECYCLE := "lifecycle"
const TITLE_SCENE := preload("res://scenes/ui/screens/title_screen.tscn")
const LIBRARY_SCENE := preload("res://scenes/ui/screens/library_screen.tscn")
const SETTINGS_SCENE := preload("res://scenes/ui/screens/settings_screen.tscn")
const HARNESS_SCENE_PATH := "res://scenes/harness/foundation_harness.tscn"
const HARNESS_FLAG := "--harness"
const OPEN_ROOM_PREFIX := "--open-room="
const PLAYTEST_PROFILE := "karera_slice"
## Guided first match: a stage whose flag ledge needs a built piece, used for one match only.
const TUTORIAL_LAYOUT := preload("res://data/stage/tutorial_arena_layout.tres")
const TUTORIAL_SCRIPT_PATH := "res://data/ui/tutorial_script.tres"

var state := State.TITLE
## Set by the harness when it hosts this flow: Quit returns to the harness instead of exiting.
var harness_mode := false
var router: LocalInputRouter
var bridge: UiInputBridge
var room: P05MatchRoom
var settings := PresentationSettings.new()
## The room each match instantiates (the first-playable route unless the lifecycle route is asked).
var match_scene: PackedScene = MATCH_SCENE
var prompt_map: UiPromptMap
var library_text: UiLibraryText
## Session-only tutorial memory (never written to disk) and the coach for the current match.
var tutorial_session := TutorialSession.new()
var tutorial_script: TutorialScript
var tutorial: TutorialCoordinator

var _screen: UiScreen


func _ready() -> void:
	if not harness_mode and _harness_requested():
		_open_harness.call_deferred()
		return
	prompt_map = load(UiContext.PROMPT_MAP_PATH) as UiPromptMap
	library_text = load(UiContext.LIBRARY_TEXT_PATH) as UiLibraryText
	tutorial_script = load(TUTORIAL_SCRIPT_PATH) as TutorialScript
	if OS.get_cmdline_user_args().has(ROUTE_PREFIX + ROUTE_LIFECYCLE):
		match_scene = LIFECYCLE_SCENE
	router = LocalInputRouter.new()
	router.name = "FlowRouter"
	add_child(router)
	router.set_shared_keyboard_enabled(true)
	bridge = UiInputBridge.new()
	bridge.name = "FlowBridge"
	add_child(bridge)
	bridge.attach(router)
	router.seat_joined.connect(_on_seat_joined)
	router.seat_disconnected.connect(_on_seat_disconnected)
	router.action_pressed.connect(_on_action_pressed)
	show_title()
	print("TILAOK_FLOW_READY state=title profile=%s route=%s" % [PLAYTEST_PROFILE, _route_name()])


func _exit_tree() -> void:
	if router != null and is_instance_valid(router):
		if router.seat_joined.is_connected(_on_seat_joined):
			router.seat_joined.disconnect(_on_seat_joined)
		if router.seat_disconnected.is_connected(_on_seat_disconnected):
			router.seat_disconnected.disconnect(_on_seat_disconnected)
		if router.action_pressed.is_connected(_on_action_pressed):
			router.action_pressed.disconnect(_on_action_pressed)
		router.clear_input_state()
	if get_tree() != null:
		get_tree().paused = false


## Title menu. clear_seats returns every seat to the open join state (a fresh session).
func show_title(clear_seats: bool = false) -> void:
	_free_room()
	_free_screen()
	if clear_seats:
		router.registry.clear_to_lobby()
	state = State.TITLE
	var title := TITLE_SCENE.instantiate() as UiTitleScreen
	add_child(title)
	title.start_requested.connect(_enter_match)
	title.library_requested.connect(show_library)
	title.settings_requested.connect(show_settings)
	title.quit_requested.connect(_quit)
	_screen = title
	_refresh_title()
	_use_menu_screen(title)


func show_library() -> void:
	_free_screen()
	state = State.LIBRARY
	var library := LIBRARY_SCENE.instantiate() as UiLibraryScreen
	add_child(library)
	var tuning := GameplayTuning.new()
	tuning.item_enabled_variants = P07FirstPlayableMatchRoom.P07_ALLOWED_VARIANTS.duplicate()
	ItemEnabledProfiles.apply(tuning, PLAYTEST_PROFILE)
	var definitions := ItemDefinitions.load_for_profile(tuning, PLAYTEST_PROFILE)
	library.replay_tutorial_enabled = true
	library.replay_tutorial_requested.connect(tutorial_session.replay)
	library.bind_live(definitions, tuning, library_text)
	library.back_requested.connect(show_title)
	_screen = library
	_use_menu_screen(library)


func show_settings() -> void:
	_free_screen()
	state = State.SETTINGS
	var screen := SETTINGS_SCENE.instantiate() as UiSettingsScreen
	add_child(screen)
	screen.bind_live(settings)
	screen.back_requested.connect(show_title)
	_screen = screen
	_use_menu_screen(screen)


## Creates a fresh match room on the shared router; the room's own Lobby phase comes first.
func _enter_match() -> void:
	_free_room()
	_free_screen()
	state = State.IN_MATCH
	bridge.screen = null
	for seat in router.registry.joined_seats():
		router.registry.set_ready(int(seat.seat), false)
	room = match_scene.instantiate() as P05MatchRoom
	room.input_router = router
	room.auto_start_on_ready = true
	room.presentation_settings = settings
	room.allow_harness_button = not harness_mode
	# One map per match: the layout is chosen here, once, before the room builds its arena.
	if tutorial_session.wants_tutorial_layout():
		room.arena_layout = TUTORIAL_LAYOUT
	room.flow_requested.connect(_on_flow_requested)
	room.return_requested.connect(_on_room_return)
	add_child(room)
	_attach_tutorial()


func _start_replay() -> void:
	if room == null:
		return
	for seat in router.registry.joined_seats():
		router.registry.set_ready(int(seat.seat), true)
	room.start_match()


## The coach is a child of the room, so it is freed with it. It only reads room state.
func _attach_tutorial() -> void:
	if room == null or tutorial_script == null or room.presenter == null:
		return
	tutorial = TutorialCoordinator.new()
	tutorial.name = "TutorialCoordinator"
	room.add_child(tutorial)
	tutorial.attach(room, tutorial_session, tutorial_script, prompt_map)
	room.presenter.bind_tutorial(tutorial)


func _on_flow_requested(kind: StringName) -> void:
	match kind:
		&"lobby_back":
			show_title(true)
		&"leave_match":
			# PROTOTYPE_DEFAULTS §3: leaving a match returns the whole group to the Lobby.
			_enter_match()
		&"replay_match":
			# Replay from a room that held the tutorial stage: a fresh room, started at once.
			_enter_match()
			_start_replay()
		&"harness":
			_open_harness()


func _on_room_return() -> void:
	show_title(true)


func _on_seat_joined(_seat_index: int) -> void:
	if state == State.TITLE:
		_refresh_title()
		_use_menu_screen(_screen)


## No match means no pause coordinator: Esc must not freeze the Title with nobody to resume it.
func _on_action_pressed(seat_index: int, action_name: String) -> void:
	if seat_index < 0 and action_name == "system_pause" and room == null:
		router.resume_system()
		get_tree().paused = false


## A lost controller before any match has no seat to reclaim: start a fresh Title session.
func _on_seat_disconnected(_seat_index: int) -> void:
	if room == null and state != State.IN_MATCH:
		show_title(true)


func _refresh_title() -> void:
	var title := _screen as UiTitleScreen
	if title == null:
		return
	var seats := router.registry.joined_seats()
	var device := UiContext.device_for_seat(seats[0]) if not seats.is_empty() else "k1"
	var label := "%s • %s" % [BUILD_LABEL, PLAYTEST_PROFILE]
	if match_scene == LIFECYCLE_SCENE:
		label += " • match lifecycle"
	title.bind_live(label, seats.size(), prompt_map, device)


## Title with nobody seated listens for a join press (router LOBBY phase); with a seat it is a
## normal MENU. Both go through set_phase so a held press is consumed on the change.
func _use_menu_screen(screen: UiScreen) -> void:
	bridge.screen = screen
	var seated := not router.registry.joined_seats().is_empty()
	router.set_phase(LocalInputRouter.Phase.MENU if seated else LocalInputRouter.Phase.LOBBY)


func _free_screen() -> void:
	if _screen != null and is_instance_valid(_screen):
		remove_child(_screen)
		_screen.queue_free()
	_screen = null
	if bridge != null:
		bridge.screen = null


func _free_room() -> void:
	if room == null:
		return
	if is_instance_valid(room):
		if room.flow_requested.is_connected(_on_flow_requested):
			room.flow_requested.disconnect(_on_flow_requested)
		if room.return_requested.is_connected(_on_room_return):
			room.return_requested.disconnect(_on_room_return)
		remove_child(room)
		room.queue_free()
	room = null
	tutorial = null
	get_tree().paused = false
	router.resume_system()


func _quit() -> void:
	if harness_mode:
		return_requested.emit()
	else:
		get_tree().quit()


func _route_name() -> String:
	return ROUTE_LIFECYCLE if match_scene == LIFECYCLE_SCENE else "first_playable"


func _harness_requested() -> bool:
	for argument in OS.get_cmdline_user_args():
		if argument == HARNESS_FLAG or argument.begins_with(OPEN_ROOM_PREFIX):
			return true
	return false


func _open_harness() -> void:
	get_tree().change_scene_to_file(HARNESS_SCENE_PATH)

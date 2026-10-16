extends SceneTree

## P13-T01/T02 navigation matrix with synthetic K1, K2 and gamepad input: every Title / Library /
## Settings / Lobby / Pause / confirmation route is reachable and escapable, Library and Settings
## from Pause keep the simulation frozen and return to the same Pause state, held presses never
## leak across a screen swap, Quit and leave always confirm, and the left stick steps menus like the
## D-pad outside Play. Synthetic input only: this is never physical-device evidence.

const FLOW_SCENE := preload("res://scenes/flow/game_flow.tscn")
const LIBRARY_SCENE := preload("res://scenes/ui/screens/library_screen.tscn")
const SETTINGS_SCENE := preload("res://scenes/ui/screens/settings_screen.tscn")
const PAD := 720
const PAD_B := 721
const RESUME_SECONDS := 0.2
const CYCLES := 10
const KINDS := ["K1", "K2", "PAD"]
const SOURCE_FILES := [
	"res://scripts/flow/game_flow.gd",
	"res://scripts/match/match_screen_presenter.gd",
	"res://scripts/input/local_input_router.gd",
]
const FORBIDDEN_TOKENS := ["Control.new(", "Label.new(", "Button.new(", "add_theme_"]

var checks := 0
var failures := 0
var flow: GameFlow
var quit_count := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_route_flag_parsing()
	for kind in KINDS:
		await _test_route_walk(kind, GameFlow.MATCH_SCENE)
	await _test_route_walk("K1", GameFlow.LIFECYCLE_SCENE)
	await _test_route_walk("PAD", GameFlow.LIFECYCLE_SCENE)
	await _test_pause_library_and_settings()
	await _test_library_blocked_during_countdown()
	await _test_title_quit_from_results_goes_through_flow()
	_test_router_aliases_and_consume()
	await _test_stick_navigation()
	await _test_screen_cycles_are_stable()
	await _test_overlay_cycles_are_stable()
	_test_source_rules()
	print("P13_NAVIGATION_TESTS checks=%d failures=%d" % [checks, failures])
	quit(1 if failures > 0 else 0)


# --- route flag -----------------------------------------------------------------------------


func _test_route_flag_parsing() -> void:
	var parse := GameFlow.route_from_args
	_check(parse.call(PackedStringArray()) == "", "no route flag keeps the build default")
	_check(
		parse.call(PackedStringArray(["--match-route=lifecycle"])) == "lifecycle",
		"--match-route=lifecycle selects the scheduled match"
	)
	_check(
		parse.call(PackedStringArray(["--match-route=first_playable"])) == "first_playable",
		"--match-route=first_playable selects the first playable room"
	)
	var seed_of := GameFlow.seed_from_args
	_check(seed_of.call(PackedStringArray()) == -1, "no seed flag keeps the default seed")
	_check(
		seed_of.call(PackedStringArray(["--match-seed=3"])) == 3, "--match-seed=3 asks for seed 3"
	)
	_check(
		seed_of.call(PackedStringArray(["--match-seed=abc", "--match-seed=-4"])) == -1,
		"a malformed or negative seed is ignored"
	)
	_check(
		parse.call(PackedStringArray(["--match-route=nonsense"])) == "",
		"an unknown route value is ignored, never silently remapped"
	)
	_check(
		(
			parse.call(
				PackedStringArray(["--match-route=lifecycle", "--match-route=first_playable"])
			)
			== "first_playable"
		),
		"the last recognised route flag wins"
	)


# --- the matrix: one device kind walks every menu route ------------------------------------------


func _test_route_walk(kind: String, route: PackedScene) -> void:
	var label := "%s/%s" % [kind, "scheduled" if route == GameFlow.LIFECYCLE_SCENE else "first"]
	await _new_flow(route)
	quit_count = 0
	flow.return_requested.connect(func() -> void: quit_count += 1)
	_check(flow.state == GameFlow.State.TITLE, "%s: boots to the Title" % label)
	# Nobody seated: the join press seats exactly one seat and never readies it.
	await _tap(kind, "accept")
	_check(
		(
			flow.router.registry.joined_seats().size() == 1
			and not bool(flow.router.registry.get_seat(0).ready)
		),
		"%s: the join press seats one seat and does not ready it" % label
	)
	var title := flow._screen as UiTitleScreen
	var menu: UiMenuList = title.get_node("%MenuList")
	_check(menu.visible and menu.selected == 0, "%s: the Title menu shows on Start" % label)
	# Library, then back.
	await _tap(kind, "down")
	await _tap(kind, "accept")
	_check(flow.state == GameFlow.State.LIBRARY, "%s: Title -> Library" % label)
	_check(flow.router.phase == LocalInputRouter.Phase.MENU, "%s: Library keeps MENU" % label)
	await _tap(kind, "back")
	_check(flow.state == GameFlow.State.TITLE, "%s: Library Back -> Title" % label)
	# Settings, then back.
	title = flow._screen as UiTitleScreen
	await _tap(kind, "down")
	await _tap(kind, "down")
	await _tap(kind, "accept")
	_check(flow.state == GameFlow.State.SETTINGS, "%s: Title -> Settings" % label)
	await _tap(kind, "back")
	_check(flow.state == GameFlow.State.TITLE, "%s: Settings Back -> Title" % label)
	# Quit confirms; the default answer is No; Yes quits (the harness stands in for the process).
	title = flow._screen as UiTitleScreen
	await _tap(kind, "back")
	var quit_dialog: UiConfirmDialog = title.get_node("%QuitConfirm")
	_check(quit_dialog.is_open(), "%s: Back on the Title asks before quitting" % label)
	_check(quit_count == 0, "%s: the press that opened the confirm did not quit" % label)
	await _tap(kind, "accept")
	_check(
		not quit_dialog.is_open() and quit_count == 0,
		"%s: accepting the default answer (No) cancels" % label
	)
	await _tap(kind, "back")
	await _tap(kind, "left")
	await _tap(kind, "accept")
	_check(quit_count == 1, "%s: choosing Yes quits exactly once" % label)
	# Start -> Lobby (the Start press must not ready the seat).
	await _tap(kind, "accept")
	var room := flow.room
	_check(
		room != null and flow.state == GameFlow.State.IN_MATCH, "%s: Start opens the Lobby" % label
	)
	_check(
		not bool(flow.router.registry.get_seat(0).ready),
		"%s: the Start press does not ready the seat" % label
	)
	await _tap(kind, "accept")
	_check(bool(flow.router.registry.get_seat(0).ready), "%s: a fresh press readies" % label)
	# Help opens the Library from the Lobby and Back returns to it.
	await _tap(kind, "help")
	var presenter := room.presenter
	_check(
		presenter._overlay is UiLibraryScreen, "%s: help opens the Library from the Lobby" % label
	)
	_check(
		flow.router.phase == LocalInputRouter.Phase.MENU,
		"%s: the Lobby Library is driven in the MENU phase" % label
	)
	_check(
		bool(flow.router.registry.get_seat(0).ready),
		"%s: opening help keeps the seat's ready flag" % label
	)
	await _tap(kind, "back")
	_check(presenter._overlay == null, "%s: Library Back closes the overlay" % label)
	_check(
		flow.router.phase == LocalInputRouter.Phase.LOBBY and presenter.lobby_screen.visible,
		"%s: Back returns to the Lobby with the Lobby phase" % label
	)
	# Back in the Lobby: the scheduled match asks first once a seat is ready; the first-playable
	# room (P07 gate) keeps its immediate leave.
	await _tap(kind, "back")
	if route == GameFlow.LIFECYCLE_SCENE:
		_check(room.is_confirmation_open(), "%s: Lobby Back with a ready seat asks" % label)
		_check(
			flow.state == GameFlow.State.IN_MATCH, "%s: the press that asked did not leave" % label
		)
		await _tap(kind, "back")
		_check(
			not room.is_confirmation_open() and flow.state == GameFlow.State.IN_MATCH,
			"%s: Back cancels the confirmation (no re-open)" % label
		)
		await _tap(kind, "back")
		_check(room.is_confirmation_open(), "%s: Back asks again" % label)
		await _tap(kind, "left")
		await _tap(kind, "accept")
		await _wait_frames(2)
	_check(
		flow.state == GameFlow.State.TITLE and flow.router.registry.joined_seats().is_empty(),
		"%s: Lobby Back returns to the Title with the session cleared" % label
	)
	_check(not paused, "%s: the tree is not left paused" % label)
	# Lobby Back with nobody ready leaves at once, on either route.
	await _tap(kind, "accept")
	await _tap(kind, "accept")
	_check(
		flow.state == GameFlow.State.IN_MATCH and flow.room != null,
		"%s: a fresh session opens a Lobby again" % label
	)
	await _tap(kind, "back")
	_check(flow.state == GameFlow.State.TITLE, "%s: unready Lobby Back leaves at once" % label)
	await _free_flow()


# --- Library / Settings from Pause keep the simulation frozen ------------------------------------


func _test_pause_library_and_settings() -> void:
	var room := await _room_in_play()
	room.pause_coordinator.resume_countdown_seconds = RESUME_SECONDS
	var clock_before := room.items.director.simulation_time
	var race_before := room.race_round_controller.elapsed_seconds
	room.input_router.pause_requested.emit(1)
	await _wait_frames(2)
	var pause := room.presenter.pause_screen
	var menu: UiMenuList = pause.get_node("%MenuList")
	_check(paused and pause.visible and pause.owner_seat == 1, "pause opens owned by seat 2")
	# Wrong seat: seat 1's Library press is not honoured.
	await _tap("K1", "down")
	await _tap("K1", "accept")
	_check(room.presenter._overlay == null, "a non-owner cannot open anything from Pause")
	# The owner selects Library (index 2) and opens it.
	await _tap("K2", "down")
	await _tap("K2", "down")
	_check(menu.selected == 2, "the owner moves to Library")
	await _tap("K2", "accept")
	_check(
		room.presenter._overlay is UiLibraryScreen and paused,
		"Library opens over Pause with the tree still paused"
	)
	_check(not pause.visible, "the Pause screen is hidden under the overlay")
	await _wait_physics_frames(20)
	_check(
		is_equal_approx(room.items.director.simulation_time, clock_before),
		"the item director clock is frozen while the Library is open"
	)
	_check(
		is_equal_approx(room.race_round_controller.elapsed_seconds, race_before),
		"the race clock is frozen while the Library is open"
	)
	# A game key during the overlay is not game input.
	var cell_count := room.items.persistent_count()
	await _tap("K2", "jump")
	_check(room.items.persistent_count() == cell_count, "game keys do nothing under the overlay")
	# Non-owner cannot drive the overlay either.
	var library := room.presenter._overlay as UiLibraryScreen
	var category_before := library.category
	await _tap("K1", "down")
	await _tap("K1", "accept")
	_check(library.category == category_before, "a non-owner cannot drive the Library")
	# Back (owner) returns to the same Pause row.
	await _tap("K2", "back")
	_check(
		room.presenter._overlay == null and pause.visible and menu.selected == 2,
		"Back returns to Pause with Library still selected"
	)
	_check(
		room.pause_coordinator.state == PauseRecoveryCoordinator.State.PAUSED,
		"the Pause state is unchanged by the overlay round trip"
	)
	# Settings the same way.
	await _tap("K2", "up")
	_check(menu.selected == 1, "the owner moves to Settings")
	await _tap("K2", "accept")
	_check(room.presenter._overlay is UiSettingsScreen and paused, "Settings opens, still paused")
	await _tap("K2", "back")
	_check(room.presenter._overlay == null and pause.visible, "Settings Back returns to Pause")
	_check(
		is_equal_approx(room.items.director.simulation_time, clock_before),
		"the simulation clock never advanced across both overlays"
	)
	await _free_flow()


func _test_library_blocked_during_countdown() -> void:
	var room := await _room_in_play()
	room.pause_coordinator.resume_countdown_seconds = 5.0
	room.input_router.pause_requested.emit(0)
	await _wait_frames(2)
	room.pause_coordinator.mark_ready(1)
	room.pause_coordinator.mark_ready(0)
	await _wait_frames(2)
	_check(
		room.pause_coordinator.state == PauseRecoveryCoordinator.State.COUNTDOWN,
		"both seats ready starts the resume countdown"
	)
	room.presenter._open_overlay(LIBRARY_SCENE)
	_check(room.presenter._overlay == null, "Library cannot open during the resume countdown")
	await _free_flow()


# --- Quit from the match result goes through the flow ---------------------------------------------


func _test_title_quit_from_results_goes_through_flow() -> void:
	await _new_flow(GameFlow.LIFECYCLE_SCENE)
	quit_count = 0
	flow.return_requested.connect(func() -> void: quit_count += 1)
	await _tap("K1", "accept")
	await _tap("K1", "accept")
	var room := flow.room
	_check(room is P09MatchLifecycleRoom, "the scheduled route hosts a lifecycle room")
	room.flow_requested.emit(&"quit")
	await process_frame
	_check(quit_count == 1, "a room Quit request goes through GameFlow (harness aware)")
	await _free_flow()


# --- router aliases, consume, stick ---------------------------------------------------------


func _test_router_aliases_and_consume() -> void:
	var router := LocalInputRouter.new()
	root.add_child(router)
	router.set_shared_keyboard_enabled(true)
	var seat := router.registry.join_keyboard("K1")
	var seen: Array[String] = []
	router.action_pressed.connect(func(_s: int, name: String) -> void: seen.append(name))
	router.set_rotation_supported(true)
	for entry in [
		[LocalInputRouter.Phase.LOBBY, "help"],
		[LocalInputRouter.Phase.PLAY, "cheer"],
		[LocalInputRouter.Phase.PLACE, "rotate"],
	]:
		router.set_phase(entry[0] as LocalInputRouter.Phase)
		seen.clear()
		router._handle_key(_key_event(KEY_R, true))
		router._handle_key(_key_event(KEY_R, false))
		_check(seen == [entry[1]], "R in phase %s is '%s' (saw %s)" % [entry[0], entry[1], seen])
	router.set_phase(LocalInputRouter.Phase.MENU)
	router._handle_key(_key_event(KEY_E, true))
	router.consume_held_presses()
	_check(
		not router.consume_pressed(seat, "confirm"),
		"consume_held_presses drops a press waiting in the same phase"
	)
	router._handle_key(_key_event(KEY_E, false))
	seen.clear()
	router._handle_key(_key_event(KEY_E, true))
	router._handle_key(_key_event(KEY_E, false))
	_check(seen == ["confirm"], "a fresh press after release still acts")
	router.queue_free()
	await process_frame


func _test_stick_navigation() -> void:
	var router := LocalInputRouter.new()
	root.add_child(router)
	router.registry.join_gamepad(PAD)
	var steps: Array[String] = []
	router.navigation_step.connect(func(_s: int, d: String) -> void: steps.append(d))
	router.set_phase(LocalInputRouter.Phase.MENU)
	_stick(router, JOY_AXIS_LEFT_Y, 0.9)
	_check(steps == ["down"], "the stick steps a menu down like the D-pad (saw %s)" % [steps])
	_stick(router, JOY_AXIS_LEFT_Y, 0.0)
	steps.clear()
	_stick(router, JOY_AXIS_LEFT_X, -0.9)
	_check(steps == ["left"], "the stick steps left outside Play (saw %s)" % [steps])
	_stick(router, JOY_AXIS_LEFT_X, 0.0)
	steps.clear()
	_stick(router, JOY_AXIS_LEFT_Y, 0.22)
	_check(steps.is_empty(), "a deflection between neutral and activation does nothing")
	_stick(router, JOY_AXIS_LEFT_Y, 0.0)
	# Play: the stick runs, it never navigates.
	router.set_phase(LocalInputRouter.Phase.PLAY)
	steps.clear()
	_stick(router, JOY_AXIS_LEFT_X, 0.9)
	_check(steps.is_empty(), "the stick does not navigate in Play")
	_check(is_equal_approx(router.movement_axis(0), 0.9), "the stick still runs in Play")
	_stick(router, JOY_AXIS_LEFT_X, 0.0)
	# A phase change releases a held stick direction.
	router.set_phase(LocalInputRouter.Phase.MENU)
	_stick(router, JOY_AXIS_LEFT_Y, 0.9)
	_check(router.is_action_held(0, "down"), "the stick holds a digital direction in a menu")
	router.set_phase(LocalInputRouter.Phase.PLAY)
	_check(not router.is_action_held(0, "down"), "a phase change releases the stick direction")
	router.queue_free()
	await process_frame


# --- screen cycles leave nothing behind -----------------------------------------------------------


func _test_screen_cycles_are_stable() -> void:
	await _new_flow(GameFlow.MATCH_SCENE)
	await _tap("K1", "accept")
	var nodes: Array[int] = []
	for cycle in CYCLES:
		await _tap("K1", "down")
		await _tap("K1", "accept")
		await _tap("K1", "back")
		await _tap("K1", "accept")
		await _tap("K1", "accept")
		await _tap("K1", "help")
		await _tap("K1", "back")
		await _tap("K1", "back")
		await _wait_frames(2)
		_check(flow.state == GameFlow.State.TITLE, "cycle %d ends on the Title" % cycle)
		nodes.append(_count_nodes(flow))
	_check(
		nodes[0] == nodes[nodes.size() - 1],
		"screen cycles keep the flow's node count stable (%s)" % [nodes]
	)
	_check(not paused, "the tree is never left paused")
	await _free_flow()


## Ten pause -> Library -> Settings -> resume cycles in a scheduled match leave no node, object,
## signal connection or bus change behind.
func _test_overlay_cycles_are_stable() -> void:
	await _new_flow(GameFlow.LIFECYCLE_SCENE)
	flow.router.registry.join_keyboard("K1")
	flow.router.registry.join_keyboard("K2")
	flow._enter_match()
	await _wait_frames(2)
	var room := flow.room
	for seat in flow.router.registry.joined_seats():
		flow.router.registry.set_ready(int(seat.seat), true)
	room.start_match()
	await _wait_frames(3)
	room.pause_coordinator.resume_countdown_seconds = 0.05
	var before_nodes := _count_nodes(flow)
	var before_actions := flow.router.action_pressed.get_connections().size()
	var before_orphans := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	var master_db := PresentationApplier.bus_volume_db(&"Master")
	for cycle in CYCLES:
		room.input_router.pause_requested.emit(0)
		await _wait_frames(2)
		room.presenter._open_overlay(LIBRARY_SCENE)
		await _wait_frames(2)
		room.presenter._close_overlay()
		room.presenter._open_overlay(SETTINGS_SCENE)
		await _wait_frames(2)
		room.presenter._close_overlay()
		room.pause_coordinator.set_paused("", -1)
		room.get_tree().paused = false
		room.pause_coordinator.state = PauseRecoveryCoordinator.State.RUNNING
		await _wait_frames(2)
		_check(room.presenter._overlay == null, "cycle %d leaves no overlay open" % cycle)
	_check(
		_count_nodes(flow) == before_nodes,
		"ten overlay cycles keep the node count (%d -> %d)" % [before_nodes, _count_nodes(flow)]
	)
	_check(
		flow.router.action_pressed.get_connections().size() == before_actions,
		"ten overlay cycles keep the router's signal connections"
	)
	_check(
		int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)) <= before_orphans,
		"ten overlay cycles leave no new orphan nodes"
	)
	_check(
		is_equal_approx(PresentationApplier.bus_volume_db(&"Master"), master_db),
		"the audio buses are untouched by opening Library and Settings"
	)
	await _free_flow()


func _test_source_rules() -> void:
	for path in SOURCE_FILES:
		var text := FileAccess.get_file_as_string(path)
		for token in FORBIDDEN_TOKENS:
			var hit := false
			for line in text.split("\n"):
				var stripped := line.strip_edges()
				if not stripped.begins_with("#") and stripped.contains(token):
					hit = true
			_check(not hit, "%s has no %s" % [path.get_file(), token])


# --- helpers --------------------------------------------------------------------------------------


func _new_flow(route: PackedScene) -> void:
	flow = FLOW_SCENE.instantiate() as GameFlow
	flow.harness_mode = true
	flow.match_scene = route
	root.add_child(flow)
	await _wait_frames(3)
	flow.match_scene = route


func _free_flow() -> void:
	if flow != null and is_instance_valid(flow):
		flow.queue_free()
	flow = null
	paused = false
	await _wait_frames(3)


## Title -> two seated keyboards -> Lobby -> match -> Play.
func _room_in_play() -> P05MatchRoom:
	await _new_flow(GameFlow.MATCH_SCENE)
	await _tap("K1", "accept")
	await _tap("K1", "accept")
	var room := flow.room
	await _tap("K2", "accept")
	await _tap("K1", "accept")
	await _tap("K2", "accept")
	await _wait_frames(2)
	room.assignments = {0: str(room.egg_pool[0].egg_id), 1: str(room.egg_pool[1].egg_id)}
	room._enter_place()
	await process_frame
	room.items.place("build.hollow_blocks.cell_1x1", Vector2i(6, 8), 0, 0)
	room._enter_play()
	await _wait_frames(2)
	return room


func _tap(kind: String, action: String) -> void:
	_press(kind, action, true)
	await process_frame
	_press(kind, action, false)
	await process_frame


func _press(kind: String, action: String, pressed: bool) -> void:
	if kind == "PAD":
		var buttons := {
			"accept": JOY_BUTTON_A,
			"back": JOY_BUTTON_B,
			"up": JOY_BUTTON_DPAD_UP,
			"down": JOY_BUTTON_DPAD_DOWN,
			"left": JOY_BUTTON_DPAD_LEFT,
			"right": JOY_BUTTON_DPAD_RIGHT,
			"help": JOY_BUTTON_X,
			"jump": JOY_BUTTON_A,
		}
		var event := InputEventJoypadButton.new()
		event.device = PAD
		event.button_index = buttons[action]
		event.pressed = pressed
		flow.router._handle_joy_button(event)
		return
	var keys := {
		"K1":
		{
			"accept": KEY_E,
			"back": KEY_G,
			"up": KEY_W,
			"down": KEY_S,
			"left": KEY_A,
			"right": KEY_D,
			"help": KEY_R,
			"jump": KEY_SPACE,
		},
		"K2":
		{
			"accept": KEY_ENTER,
			"back": KEY_BACKSPACE,
			"up": KEY_UP,
			"down": KEY_DOWN,
			"left": KEY_LEFT,
			"right": KEY_RIGHT,
			"help": KEY_SHIFT,
			"jump": KEY_CTRL,
		},
	}
	var key: Key = keys[kind][action]
	var event := _key_event(key, pressed)
	if key in [KEY_SHIFT, KEY_CTRL]:
		event.location = KEY_LOCATION_RIGHT
	flow.router._handle_key(event)


func _key_event(key: Key, pressed: bool) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.pressed = pressed
	return event


func _stick(router: LocalInputRouter, axis: JoyAxis, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = PAD
	event.axis = axis
	event.axis_value = value
	router._handle_joy_axis(event)


func _count_nodes(node: Node) -> int:
	var total := 1
	if node is ItemEggPreview:
		return total
	for child in node.get_children():
		total += _count_nodes(child)
	return total


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
		push_error("P13_NAV FAIL: " + message)
	print("%s %s" % ["PASS" if condition else "FAIL", message])

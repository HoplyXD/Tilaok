class_name P02MovementRoom
extends Control

signal return_requested

const BUILD_ID := "P02-input-movement-dev"
const SEAT_POSITIONS := [Vector2(220, 548), Vector2(270, 548), Vector2(320, 548), Vector2(370, 548)]
## Top-left of the on-demand wall-movement fixtures (debug geometry, floating above the course).
const WALL_FIXTURE_ORIGIN := Vector2(160.0, 112.0)

var tuning := GameplayTuning.new()
var snapshot: ConfigurationSnapshot
var input_router := LocalInputRouter.new()
var pause_coordinator := PauseRecoveryCoordinator.new()
var recovery_contract := ContainmentRecoveryContract.new()
var actors: Dictionary = {}
var wall_fixtures: Dictionary = {}
var selected_phase := LocalInputRouter.Phase.PLAY
var _metric_clock := 0.0
var _simulation_ticks := 0
var _probe_timer := 0.0
var _probe_elapsed := 0.0
var _probe_callbacks := 0
var _status_label: Label
var _phase_picker: OptionButton
var _mode_picker: OptionButton
var _seat_label: Label
var _timer_probe_label: Label
var _pause_label: Label
var _reclaim_picker: OptionButton
var _join_gamepad_button: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	snapshot = ConfigurationSnapshot.create(
		tuning, PresentationSettings.new(), "movement_room", 12345, 1
	)
	input_router.tuning = snapshot.gameplay
	add_child(input_router)
	pause_coordinator.input_router = input_router
	add_child(pause_coordinator)
	recovery_contract.begin_round([0, 0, 0, 0], 0, ContainmentRecoveryContract.Mode.RACE)
	_build_world()
	_build_interface()
	input_router.seat_joined.connect(_on_seat_joined)
	input_router.seat_disconnected.connect(_on_seat_disconnected)
	input_router.action_pressed.connect(_on_router_action)
	input_router.disabled_action_cue.connect(_on_disabled_action_cue)
	pause_coordinator.pause_state_changed.connect(_on_pause_state_changed)
	pause_coordinator.countdown_changed.connect(_on_countdown_changed)
	pause_coordinator.reclaim_prompted.connect(_on_reclaim_prompted)
	pause_coordinator.menu_selection_changed.connect(_on_pause_menu_selection_changed)
	pause_coordinator.reclaim_menu_requested.connect(_on_reclaim_menu_requested)
	var probe := Timer.new()
	probe.name = "SimulationTimerProbe"
	probe.wait_time = 0.1
	probe.autostart = true
	probe.process_callback = Timer.TIMER_PROCESS_PHYSICS
	probe.timeout.connect(_on_probe_timeout)
	add_child(probe)
	_sync_actors()
	input_router.set_phase(selected_phase)
	_update_labels()


func _exit_tree() -> void:
	_disconnect_signals_to_self(self)
	input_router.clear_input_state()
	actors.clear()


func _disconnect_signals_to_self(source: Node) -> void:
	for signal_info in source.get_signal_list():
		var signal_name: StringName = signal_info.name
		for connection in source.get_signal_connection_list(signal_name):
			var callback: Callable = connection.callable
			if callback.get_object() == self:
				source.disconnect(signal_name, callback)
	for child in source.get_children():
		_disconnect_signals_to_self(child)


func _on_probe_timeout() -> void:
	_probe_callbacks += 1


func _on_return_requested() -> void:
	return_requested.emit()


func _process(delta: float) -> void:
	if get_tree().paused:
		return
	_metric_clock += delta
	_probe_elapsed += delta
	_probe_timer += delta
	if _metric_clock >= 0.25:
		_metric_clock = 0.0
		_update_labels()


func _physics_process(_delta: float) -> void:
	if get_tree().paused:
		return
	_simulation_ticks += 1


func set_diagnostic_phase(phase_index: int) -> void:
	selected_phase = phase_index as LocalInputRouter.Phase
	if _phase_picker != null:
		_phase_picker.select(selected_phase)
	input_router.set_phase(selected_phase)
	for actor in actors.values():
		actor.jump_buffer_remaining = 0.0
	_update_labels()


func inject_containment_breach(seat_index: int) -> void:
	var actor: ChickenController = actors.get(seat_index)
	if actor == null:
		return
	actor.global_position = Vector2(1180.0, 620.0)


func set_player_state(seat_index: int, state_name: String) -> void:
	var actor: ChickenController = actors.get(seat_index)
	if actor == null:
		return
	match state_name:
		"active":
			actor.lifecycle.status = PlayerLifecycleState.Status.ACTIVE
		"captured":
			actor.set_captured(true, "fixture.capture")
		"opening_freeze":
			actor.set_opening_freeze(true)
		"secured":
			actor.secure("fixture.terminal")
		"eliminated":
			actor.eliminate("fixture.terminal")


func probe_simulation_timer() -> void:
	_probe_timer = 0.0
	_probe_elapsed = 0.0


func _build_world() -> void:
	var floor_top := 580.0
	var world := Node2D.new()
	world.name = "DiagnosticWorld"
	add_child(world)
	_add_static(world, Rect2(Vector2(640, floor_top + 16), Vector2(1056, 32)), Color("#6d5137"))
	_add_static(world, Rect2(Vector2(128, 356), Vector2(32, 520)), Color("#6d5137"))
	_add_static(world, Rect2(Vector2(1152, 356), Vector2(32, 520)), Color("#6d5137"))
	_add_static(world, Rect2(Vector2(640, 84), Vector2(1056, 32)), Color("#6d5137"))
	_add_static(world, Rect2(Vector2(344, 480), Vector2(128, 32)), Color("#9a7650"))
	_add_static(world, Rect2(Vector2(568, 416), Vector2(128, 32)), Color("#9a7650"))
	_add_static(world, Rect2(Vector2(792, 480), Vector2(128, 32)), Color("#9a7650"))
	_add_static(world, Rect2(Vector2(1016, 416), Vector2(128, 32)), Color("#9a7650"))
	_add_static(world, Rect2(Vector2(720, 370), Vector2(96, 16)), Color("#c28a54"))
	_add_static(world, Rect2(Vector2(880, 306), Vector2(96, 16)), Color("#c28a54"))
	_add_static(world, Rect2(Vector2(568, 340), Vector2(96, 16)), Color("#c28a54"))
	_add_static(world, Rect2(Vector2(640, 540), Vector2(128, 8)), Color("#c59a59"), true)
	for side_x in [128.0, 1152.0]:
		var line := ColorRect.new()
		line.position = Vector2(side_x - 2.0, 100.0)
		line.size = Vector2(4.0, 512.0)
		line.color = Color("#f4d58d")
		world.add_child(line)
	var ceiling := ColorRect.new()
	ceiling.position = Vector2(128.0, 100.0)
	ceiling.size = Vector2(1024.0, 4.0)
	ceiling.color = Color("#f4d58d")
	world.add_child(ceiling)
	var floor_line := ColorRect.new()
	floor_line.position = Vector2(128.0, floor_top)
	floor_line.size = Vector2(1024.0, 4.0)
	floor_line.color = Color("#f4d58d")
	world.add_child(floor_line)
	for marker_x in [448.0, 576.0, 704.0, 768.0, 832.0, 928.0]:
		var marker := ColorRect.new()
		marker.position = Vector2(marker_x, 476.0)
		marker.size = Vector2(2.0, 104.0)
		marker.color = Color("#61c9a8")
		world.add_child(marker)


func _add_static(parent: Node2D, rect: Rect2, color: Color, one_way: bool = false) -> void:
	var body := StaticBody2D.new()
	body.position = rect.position
	body.collision_layer = 1
	body.collision_mask = 1
	parent.add_child(body)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	collision.one_way_collision = one_way
	body.add_child(collision)
	var visual := Polygon2D.new()
	visual.polygon = PackedVector2Array(
		[
			Vector2(-rect.size.x * 0.5, -rect.size.y * 0.5),
			Vector2(rect.size.x * 0.5, -rect.size.y * 0.5),
			Vector2(rect.size.x * 0.5, rect.size.y * 0.5),
			Vector2(-rect.size.x * 0.5, rect.size.y * 0.5),
		]
	)
	visual.position = Vector2.ZERO
	visual.color = color
	body.add_child(visual)


func _build_interface() -> void:
	var panel := VBoxContainer.new()
	panel.position = Vector2(24.0, 16.0)
	panel.size = Vector2(1104.0, 220.0)
	panel.add_theme_constant_override("separation", 4)
	add_child(panel)
	var title := Label.new()
	title.text = "P02 MOVEMENT ROOM — DIAGNOSTIC FIXTURE — NOT A FULL GAME"
	title.add_theme_font_size_override("font_size", 18)
	panel.add_child(title)
	_status_label = Label.new()
	panel.add_child(_status_label)
	var controls := HBoxContainer.new()
	panel.add_child(controls)
	_phase_picker = OptionButton.new()
	for label in ["Lobby", "Menu", "Pugad", "Place", "Play", "Pause", "Results"]:
		_phase_picker.add_item(label)
	_phase_picker.select(LocalInputRouter.Phase.PLAY)
	_phase_picker.item_selected.connect(set_diagnostic_phase)
	controls.add_child(_phase_picker)
	_mode_picker = OptionButton.new()
	for label in ["Race safety", "Lagsanay defect", "Kangaroo defect"]:
		_mode_picker.add_item(label)
	_mode_picker.item_selected.connect(_on_diagnostic_mode_selected)
	controls.add_child(_mode_picker)
	var ready_button := Button.new()
	ready_button.text = "Ready / Start  K1:F  K2:Enter"
	ready_button.pressed.connect(_ready_all_for_test)
	controls.add_child(ready_button)
	var toggle_keyboard := CheckButton.new()
	toggle_keyboard.text = "Shared keyboard (opt-in)"
	toggle_keyboard.button_pressed = false
	toggle_keyboard.toggled.connect(input_router.set_shared_keyboard_enabled)
	controls.add_child(toggle_keyboard)
	_join_gamepad_button = Button.new()
	_join_gamepad_button.text = "Enable lobby joins for gamepads"
	_join_gamepad_button.pressed.connect(
		func() -> void: set_diagnostic_phase(LocalInputRouter.Phase.LOBBY)
	)
	controls.add_child(_join_gamepad_button)
	var diagnostic_controls := HBoxContainer.new()
	panel.add_child(diagnostic_controls)
	var jump_test := Button.new()
	jump_test.text = "Reset jump trial"
	jump_test.pressed.connect(_reset_trial)
	diagnostic_controls.add_child(jump_test)
	var launch_test := Button.new()
	launch_test.text = "Diagnostic launch"
	launch_test.pressed.connect(_launch_trial)
	diagnostic_controls.add_child(launch_test)
	var recovery_button := Button.new()
	recovery_button.text = "Recover prototype defect"
	recovery_button.pressed.connect(_recover_from_defect)
	diagnostic_controls.add_child(recovery_button)
	var breach_button := Button.new()
	breach_button.text = "Inject escape"
	breach_button.pressed.connect(inject_containment_breach.bind(0))
	diagnostic_controls.add_child(breach_button)
	var wall_button := Button.new()
	wall_button.text = "Wall fixtures (debug) on/off"
	wall_button.pressed.connect(_toggle_wall_fixtures)
	diagnostic_controls.add_child(wall_button)
	var return_button := Button.new()
	return_button.text = "Return to harness"
	return_button.pressed.connect(_on_return_requested)
	diagnostic_controls.add_child(return_button)
	var reclaim_row := HBoxContainer.new()
	panel.add_child(reclaim_row)
	_reclaim_picker = OptionButton.new()
	_reclaim_picker.add_item("Select missing seat to reclaim")
	for index in range(PlayerSeatRegistry.MAX_SEATS):
		_reclaim_picker.add_item("Seat %d — %s" % [index + 1, PlayerSeatRegistry.SHAPES[index]])
		_reclaim_picker.set_item_metadata(index + 1, index)
	_reclaim_picker.item_selected.connect(_on_reclaim_slot_selected)
	reclaim_row.add_child(_reclaim_picker)
	_pause_label = Label.new()
	_pause_label.custom_minimum_size = Vector2(760.0, 28.0)
	_pause_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pause_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reclaim_row.add_child(_pause_label)
	var status_row := HBoxContainer.new()
	panel.add_child(status_row)
	_seat_label = Label.new()
	_seat_label.custom_minimum_size = Vector2(760.0, 36.0)
	_seat_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_seat_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_row.add_child(_seat_label)
	_timer_probe_label = Label.new()
	_timer_probe_label.custom_minimum_size = Vector2(320.0, 32.0)
	status_row.add_child(_timer_probe_label)


func _sync_actors() -> void:
	for seat in input_router.registry.joined_seats():
		var seat_index := int(seat.seat)
		if actors.has(seat_index):
			continue
		var actor := ChickenController.new()
		actor.name = "ChickenSeat%d" % (seat_index + 1)
		actor.seat_index = seat_index
		actor.identity_number = int(seat.identity)
		actor.identity_shape = str(seat.shape)
		actor.marker_color = seat.color
		actor.tuning = snapshot.gameplay
		actor.input_router = input_router
		actor.bounds = Rect2(Vector2(128.0, 100.0), Vector2(1024.0, 512.0))
		actor.position = SEAT_POSITIONS[seat_index]
		actor.collision_layer = 2
		actor.collision_mask = 1
		actor.escaped_bounds.connect(_on_actor_escaped.bind(seat_index))
		var body_shape := CollisionShape2D.new()
		var rectangle := RectangleShape2D.new()
		rectangle.size = Vector2(tuning.body_width_wu, tuning.body_height_wu)
		body_shape.shape = rectangle
		actor.add_child(body_shape)
		world_layer().add_child(actor)
		actors[seat_index] = actor


## Builds the labeled wall-movement debug fixtures (REQ-MOVE-004). Safe to call repeatedly.
func build_wall_fixtures() -> void:
	clear_wall_fixtures()
	wall_fixtures = WallFixtureBuilder.build_set(world_layer(), WALL_FIXTURE_ORIGIN)


func clear_wall_fixtures() -> void:
	for fixture in wall_fixtures.values():
		if is_instance_valid(fixture):
			(fixture as Node).queue_free()
	wall_fixtures.clear()


## Enables or disables wall movement for every seat in this room (snapshot tuning is shared).
func set_wall_movement_enabled(enabled: bool) -> void:
	snapshot.gameplay.wall_movement_enabled = enabled
	set_wall_debug_visible(enabled)


## Debug overlay only; wall movement itself is core and stays on.
func set_wall_debug_visible(visible_overlay: bool) -> void:
	for actor in actors.values():
		var chicken := actor as ChickenController
		chicken.show_wall_debug = visible_overlay
		chicken.reset_wall_state()
		chicken.queue_redraw()


## Drops a seat from the top of a named fixture so a human can watch slide/kick behavior.
func drop_actor_at_fixture(seat_index: int, fixture_name: String) -> void:
	var actor: ChickenController = actors.get(seat_index)
	if actor == null:
		return
	var x := WALL_FIXTURE_ORIGIN.x
	match fixture_name:
		"slab":
			x = WallFixtureBuilder.slab_right_stand_x(WALL_FIXTURE_ORIGIN, tuning.body_width_wu)
		"shaft":
			x = WallFixtureBuilder.shaft_center_x(WALL_FIXTURE_ORIGIN)
		_:
			x = WALL_FIXTURE_ORIGIN.x + float(WallFixtureBuilder.EXCLUDED_X) - 20.0
	actor.reset_wall_state()
	actor.global_position = Vector2(x, WALL_FIXTURE_ORIGIN.y + 24.0)
	actor.velocity = Vector2.ZERO
	actor.locomotion_velocity = Vector2.ZERO
	actor.external_velocity = Vector2.ZERO


func world_layer() -> Node2D:
	return get_node("DiagnosticWorld") as Node2D


func _update_labels() -> void:
	if _status_label == null:
		return
	var phase_name: String = LocalInputRouter.Phase.keys()[selected_phase]
	_status_label.text = (
		"Build %s • Godot 4.7.2 • movement_room • seed 12345 • phase %s • physics %d Hz"
		% [BUILD_ID, phase_name, Engine.physics_ticks_per_second]
	)
	if _seat_label != null:
		var lines := PackedStringArray()
		for seat in input_router.registry.joined_seats():
			lines.append(
				(
					"%d %s • %s %s"
					% [
						seat.identity,
						seat.shape,
						seat.device_kind,
						"connected" if seat.connected else "DISCONNECTED"
					]
				)
			)
		_seat_label.text = "Seats: " + ("  |  ".join(lines) if not lines.is_empty() else "none")
	if _pause_label != null:
		_pause_label.text = (
			"Pause: %s (%s)"
			% [
				PauseRecoveryCoordinator.State.keys()[pause_coordinator.state],
				pause_coordinator.pause_reason
			]
		)
	if _timer_probe_label != null:
		_timer_probe_label.text = (
			"Timer %.3fs • callbacks %d • ticks %d"
			% [_probe_timer, _probe_callbacks, _simulation_ticks]
		)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2(128, 100), Vector2(1024, 512)), Color("#294553"), false, 3.0)
	draw_string(
		ThemeDB.fallback_font,
		Vector2(672, 348),
		"64 GAP + 64 RISE TEST",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		12,
		Color("#e7f0ec")
	)
	draw_string(
		ThemeDB.fallback_font,
		Vector2(520, 324),
		"CEILING TEST",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		12,
		Color("#f4d58d")
	)
	draw_string(
		ThemeDB.fallback_font,
		Vector2(800, 566),
		"ONE-WAY TEST • BRAKE / REVERSE • LEDGES",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		12,
		Color("#f4d58d")
	)
	for seat_index in actors:
		var actor: ChickenController = actors[seat_index]
		if is_instance_valid(actor):
			actor.queue_redraw()


func _on_seat_joined(_seat_index: int) -> void:
	_sync_actors()
	_update_labels()


func _on_seat_disconnected(_seat_index: int) -> void:
	_update_labels()


func _on_router_action(_seat_index: int, action_name: String) -> void:
	if (
		action_name == "system_pause"
		and pause_coordinator.state == PauseRecoveryCoordinator.State.RUNNING
	):
		pause_coordinator.set_paused("shared system pause", -1)


func _on_disabled_action_cue(seat_index: int, action_name: String) -> void:
	_pause_label.text = (
		"Seat %d: %s unavailable in this diagnostic fixture." % [seat_index + 1, action_name]
	)


func _on_pause_state_changed(paused: bool, _reason: String) -> void:
	if paused:
		probe_simulation_timer()
	_update_labels()


func _on_countdown_changed(seconds_remaining: float) -> void:
	_pause_label.text = "Resume in %.1f" % seconds_remaining


func _on_reclaim_prompted(device_id: int, missing_seats: Array[int]) -> void:
	_pause_label.text = (
		"Unassigned gamepad %d — select missing slot %s" % [device_id, str(missing_seats)]
	)


func _on_reclaim_slot_selected(item_index: int) -> void:
	if item_index <= 0:
		return
	var seat_index := int(_reclaim_picker.get_item_metadata(item_index))
	if pause_coordinator.choose_reclaim_seat(seat_index) and pause_coordinator.confirm_reclaim():
		_pause_label.text = (
			"Seat %d reclaimed; identity preserved. Fresh ready is required." % (seat_index + 1)
		)
	else:
		_pause_label.text = "Select a missing seat, then press South on the unassigned gamepad."


func _ready_all_for_test() -> void:
	for seat in input_router.registry.joined_seats():
		input_router.registry.set_ready(int(seat.seat), true)
	_update_labels()


func _reset_trial() -> void:
	for seat_index in actors:
		var actor: ChickenController = actors[seat_index]
		actor.global_position = SEAT_POSITIONS[seat_index]
		actor.velocity = Vector2.ZERO
		actor.locomotion_velocity = Vector2.ZERO
		actor.external_velocity = Vector2.ZERO
		actor.coyote_remaining = 0.0
		actor.jump_buffer_remaining = 0.0
		actor.jump_was_held = false
		actor.reset_wall_state()
		actor.lifecycle.status = PlayerLifecycleState.Status.ACTIVE
		actor.lifecycle.capture_source_id = ""
		actor.lifecycle.terminal_reason = ""
		actor.containment_outcome_reported = false


func _toggle_wall_fixtures() -> void:
	if wall_fixtures.is_empty():
		build_wall_fixtures()
		set_wall_debug_visible(true)
		drop_actor_at_fixture(0, "slab")
	else:
		clear_wall_fixtures()
		set_wall_debug_visible(false)


func _launch_trial() -> void:
	if actors.has(0):
		actors[0].launch(Vector2(350.0, -775.0))


func _on_actor_escaped(seat_index: int) -> void:
	var actor: ChickenController = actors.get(seat_index)
	if actor == null:
		return
	if selected_phase in [LocalInputRouter.Phase.PUGAD, LocalInputRouter.Phase.PLACE]:
		return
	var outcome := recovery_contract.report_escape()
	match outcome:
		ContainmentRecoveryContract.Outcome.FAILED_RACE:
			actor.eliminate("prototype containment escape")
			_pause_label.text = "Prototype safeguard: race escape fails once; no respawn or score engine."
		ContainmentRecoveryContract.Outcome.PROTOTYPE_DEFECT:
			pause_coordinator.set_paused("containment defect", -1)
			_pause_label.text = (
				"Containment breach: %s paused for prototype defect recovery."
				% _mode_picker.get_item_text(_mode_picker.selected)
			)


func _recover_from_defect() -> void:
	var recovery := recovery_contract.recover()
	if recovery.is_empty():
		_pause_label.text = (
			"Race failures do not respawn; reset the diagnostic room " + "to start a new trial."
		)
		return
	if (
		recovery.scores != recovery_contract.pre_round_scores
		or recovery.construction_revision != recovery_contract.construction_revision
		or recovery.award_count != 0
	):
		_pause_label.text = "Prototype defect recovery contract rejected inconsistent snapshot."
		return
	# Diagnostic contract only: preserve the pre-round snapshot; no round system exists.
	_reset_trial()
	recovery_contract.begin_round(
		recovery.scores, recovery.construction_revision, recovery_contract.mode
	)
	for actor in actors.values():
		actor.containment_outcome_reported = false
	if pause_coordinator.state != PauseRecoveryCoordinator.State.RUNNING:
		pause_coordinator.state = PauseRecoveryCoordinator.State.RUNNING
		pause_coordinator.pause_reason = ""
		input_router.resume_system()
		input_router.set_phase(LocalInputRouter.Phase.PLAY)
		get_tree().paused = false
	_pause_label.text = "Prototype recovery: pre-round score and construction snapshot unchanged."
	_update_labels()


func _on_diagnostic_mode_selected(index: int) -> void:
	var selected_mode := index as ContainmentRecoveryContract.Mode
	recovery_contract.begin_round([0, 0, 0, 0], 0, selected_mode)


func _on_pause_menu_selection_changed(index: int, owner_seat: int) -> void:
	_pause_label.text = (
		"Pause owner seat %d • %s"
		% [owner_seat + 1, "Resume / ready" if index == 0 else "Reclaim a missing seat"]
	)


func _on_reclaim_menu_requested() -> void:
	_pause_label.text = (
		"Choose a missing slot above, then confirm with a fresh South press "
		+ "on an unassigned gamepad."
	)

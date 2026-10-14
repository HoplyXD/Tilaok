class_name P11KangarooMatchRoom
extends P05MatchRoom

const P11_BUILD_ID := "P11-independent-kangaroo-dev"
const P11_VARIANTS: PackedStringArray = ItemEnabledProfiles.KANGAROO_VARIANTS
const PROMPT_SCENE := preload("res://scenes/ui/components/kangaroo_prompt.tscn")
const RING_SCENE := preload("res://scenes/ui/components/countdown_ring.tscn")
const PRESENTER_SCRIPT := preload("res://scripts/match/kangaroo_slipper_presenter.gd")

var kangaroo_controller := KangarooRoundController.new()
var _presenter: KangarooSlipperPresenter
var _kangaroo_overlay: CanvasLayer
var _command_stack: VBoxContainer
var _toolbar: HBoxContainer
var _marker_label: Label
var _defect_panel: PanelContainer
var _defect_notice: Label
var _shake_button: Button
var _restart_attempt_button: Button
var _command_panels: Dictionary = {}
var _seen_command_ids: Dictionary = {}
var _round_attempt := 0
var _defect_paused := false
var _defect_reason := ""
var _screen_shake_mode := PresentationSettings.new().screen_shake
var _shake_remaining := 0.0
var _last_simulation_time := 0.0
var _last_simulation_wall_usec := 0
var _debug_tones: Dictionary = {}


func _init() -> void:
	profile_id = "kangaroo_contract_lab"
	tuning.item_enabled_variants = P11_VARIANTS.duplicate()


func _ready() -> void:
	super._ready()
	process_physics_priority = 300
	if goal_area != null:
		goal_area.monitoring = false
		goal_area.collision_mask = 0
		goal_area.visible = false
	if input_router != null:
		input_router.intentional_input_edge.connect(_on_intentional_input_edge)
	if pause_coordinator != null:
		pause_coordinator.pause_state_changed.connect(_on_kangaroo_pause_state_changed)
	for child in world_layer.get_children():
		if child is Label and (child as Label).text == "KARERA GOAL":
			(child as Label).visible = false
		elif child is Line2D and (child as Line2D).name == "FlagTriggerOutline":
			(child as Line2D).visible = false
	_build_kangaroo_ui()
	_shake_button = _add_kangaroo_button("Shake: Off", _cycle_shake, "kangaroo_shake")
	_presenter = PRESENTER_SCRIPT.new() as KangarooSlipperPresenter
	_presenter.name = "KangarooDebugPresenter"
	_presenter.z_index = 30
	_presenter.visible = false
	world_layer.add_child(_presenter)
	_set_input_phase()
	_update_diagnostics()
	print("P11_KANGAROO_READY build=%s profile=%s seed=%d" % [P11_BUILD_ID, profile_id, match_seed])


func _exit_tree() -> void:
	if (
		input_router != null
		and input_router.intentional_input_edge.is_connected(_on_intentional_input_edge)
	):
		input_router.intentional_input_edge.disconnect(_on_intentional_input_edge)
	if (
		pause_coordinator != null
		and pause_coordinator.pause_state_changed.is_connected(_on_kangaroo_pause_state_changed)
	):
		pause_coordinator.pause_state_changed.disconnect(_on_kangaroo_pause_state_changed)
	kangaroo_controller.reset()
	if camera_rig != null:
		camera_rig.offset = Vector2.ZERO
	if get_tree().paused:
		get_tree().paused = false
	super._exit_tree()


func start_match() -> bool:
	var started := super.start_match()
	if started and match_snapshot != null:
		var presentation := match_snapshot.presentation.duplicate(true) as PresentationSettings
		presentation.screen_shake = _screen_shake_mode
		match_snapshot.presentation = presentation
	return started


func _begin_pugad() -> void:
	kangaroo_controller.reset()
	_round_attempt = 0
	_defect_paused = false
	_defect_reason = ""
	_seen_command_ids.clear()
	_clear_command_panels()
	if _restart_attempt_button != null:
		_restart_attempt_button.visible = false
	super._begin_pugad()


func _enter_play() -> void:
	_free_match_ghosts()
	input_router.set_rotation_supported(false)
	_reset_actors_for_round()
	phase_controller.enter(MatchPhaseController.Phase.PLAY)
	_set_input_phase()
	current_context = BoundedStageCamera.Context.PLAY
	camera_rig.set_context(current_context)
	start_play()
	round_start_score_units = cumulative_score_units.duplicate(true)
	_round_attempt = 0
	_begin_kangaroo_attempt(false)
	last_message = "Kangaroo: match the slipper pose. Three failed commands eliminate."
	_refresh_match_ui()


func _begin_kangaroo_attempt(is_retry: bool) -> void:
	var seats: Array[int] = []
	var initial_sources: Dictionary = {}
	for seat in input_router.registry.joined_seats():
		var seat_index := int(seat.seat)
		seats.append(seat_index)
		initial_sources[seat_index] = input_router.intentional_input_sources(seat_index)
	if is_retry:
		_reset_actors_for_round()
		start_play()
		_round_attempt += 1
	var active_time := items.director.simulation_time
	var round_id := "%d:%d:p11:%d" % [match_run_id, items.round_number + 1, _round_attempt]
	if not kangaroo_controller.begin(
		round_id,
		seats,
		round_start_score_units,
		match_streams.kangaroo,
		tuning,
		active_time,
		initial_sources
	):
		push_error("Could not initialize independent Kangaroo round %s" % round_id)
		return
	items.director.active_round_id = round_id
	items.director.elimination_sink_exclusive = true
	_last_simulation_time = active_time
	_last_simulation_wall_usec = Time.get_ticks_usec()
	_update_kangaroo_ui(active_time)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if get_tree().paused or phase_controller.phase != MatchPhaseController.Phase.PLAY:
		return
	if not kangaroo_controller.active or items == null or items.director == null:
		return
	var active_time := items.director.simulation_time
	var step_result := kangaroo_controller.advance_to(
		active_time, Engine.get_physics_frames(), actors, support_tracker, _hug_contacts_snapshot()
	)
	_apply_kangaroo_outcomes(step_result.new_outcomes)
	_last_simulation_time = active_time
	_last_simulation_wall_usec = Time.get_ticks_usec()
	_update_camera_targets()
	if bool(step_result.get("ended", false)):
		_finish_kangaroo()
	else:
		_update_diagnostics()


func _process(delta: float) -> void:
	super._process(delta)
	if get_tree().paused:
		return
	if phase_controller.phase == MatchPhaseController.Phase.PLAY:
		_update_kangaroo_ui(items.director.simulation_time if items != null else 0.0)
	_update_shake(delta)
	_update_defect_presentation()


func _update_diagnostics() -> void:
	super._update_diagnostics()
	if _restart_attempt_button != null:
		_restart_attempt_button.visible = _defect_paused


func build_id() -> String:
	return P11_BUILD_ID


func play_challenge_text() -> String:
	return "Kangaroo"


func play_goal_text() -> String:
	return "Match the slipper pose."


func play_clock_seconds() -> float:
	var commands := kangaroo_controller.active_commands()
	if phase_controller.phase != MatchPhaseController.Phase.PLAY or commands.is_empty():
		return 0.0
	var command: Dictionary = commands[0]
	var deadline := float(command.response_start_at)
	if str(command.status) == "RESPONSE":
		deadline = float(command.response_end_at)
	return maxf(0.0, deadline - _active_simulation_time())


func play_tag_text() -> String:
	var commands := kangaroo_controller.active_commands()
	if commands.is_empty():
		return ""
	var command: Dictionary = commands[0]
	return "DEBUG %s" % KangarooRoundController.command_name(int(command.command))


func play_status_text() -> String:
	if _defect_paused:
		return _defect_reason
	return ""


func debug_status_text() -> String:
	return _kangaroo_marker_status()


func _toggle_pause() -> void:
	if pause_coordinator.state == PauseRecoveryCoordinator.State.RUNNING:
		pause_coordinator.set_paused("participant requested pause", -1)
		return
	if pause_coordinator.state == PauseRecoveryCoordinator.State.PAUSED:
		for seat in input_router.registry.joined_seats():
			input_router.registry.set_ready(int(seat.seat), true)
		pause_coordinator.request_resume()


func _on_kangaroo_pause_state_changed(paused_state: bool, _reason: String) -> void:
	if paused_state:
		if _kangaroo_overlay != null:
			_kangaroo_overlay.visible = false
		get_tree().paused = true
		if camera_rig != null:
			camera_rig.offset = Vector2.ZERO
		return
	if input_router != null and kangaroo_controller.active:
		for seat in kangaroo_controller.seat_indices:
			kangaroo_controller.sync_intent_sources(
				seat, input_router.intentional_input_sources(seat)
			)
	_last_simulation_time = _active_simulation_time()
	_last_simulation_wall_usec = Time.get_ticks_usec()
	_update_defect_presentation()


func _on_intentional_input_edge(
	seat_index: int, action_name: String, source_id: String, is_pressed: bool, event_ticks_usec: int
) -> void:
	if (
		action_name not in ["left", "right", "jump", "run_axis"]
		or phase_controller.phase != MatchPhaseController.Phase.PLAY
		or not kangaroo_controller.active
	):
		return
	if get_tree().paused and is_pressed:
		return
	var event_time := kangaroo_controller.active_time()
	if not get_tree().paused and input_router.phase == LocalInputRouter.Phase.PLAY:
		event_time = _simulation_time_at_input(event_ticks_usec)
	kangaroo_controller.record_intent_edge(seat_index, source_id, is_pressed, event_time)


func _simulation_time_at_input(event_ticks_usec: int) -> float:
	if _last_simulation_wall_usec <= 0:
		return _active_simulation_time()
	var elapsed := maxf(0.0, float(event_ticks_usec - _last_simulation_wall_usec) / 1000000.0)
	return maxf(_last_simulation_time, _last_simulation_time + elapsed)


func _active_simulation_time() -> float:
	if items == null or items.director == null:
		return kangaroo_controller.active_time()
	return items.director.simulation_time


func _on_item_elimination(record: AttributionRecord) -> bool:
	return (
		phase_controller.phase == MatchPhaseController.Phase.PLAY
		and kangaroo_controller.submit_hazard(record)
	)


func _on_actor_escaped(seat_index: int) -> void:
	if phase_controller.phase != MatchPhaseController.Phase.PLAY or _defect_paused:
		return
	_defect_paused = true
	_defect_reason = (
		"Containment breach by %s; standalone Kangaroo treats this as a recoverable prototype defect."
		% _seat_identity_text(seat_index)
	)
	kangaroo_controller.reset()
	var current_round_number := items.round_number
	items.end_round()
	items.round_number = current_round_number
	pause_coordinator.state = PauseRecoveryCoordinator.State.PAUSED
	pause_coordinator.pause_reason = "Kangaroo containment defect"
	input_router.pause_system()
	input_router.set_phase(LocalInputRouter.Phase.PAUSE)
	get_tree().paused = true
	last_message = _defect_reason
	_update_diagnostics()
	_update_defect_presentation()


func _seat_identity_text(seat_index: int) -> String:
	if input_router == null:
		return "P%d" % (seat_index + 1)
	var seat := input_router.registry.get_seat(seat_index)
	if seat.is_empty():
		return "P%d" % (seat_index + 1)
	var marks := {"CIRCLE": "●", "TRIANGLE": "▲", "SQUARE": "■", "DIAMOND": "◆"}
	return "P%d %s %s" % [int(seat.identity), marks.get(str(seat.shape), "◆"), str(seat.shape)]


func _restart_kangaroo_attempt() -> void:
	if not _defect_paused:
		return
	_defect_paused = false
	_defect_reason = ""
	get_tree().paused = false
	pause_coordinator.state = PauseRecoveryCoordinator.State.RUNNING
	pause_coordinator.pause_reason = ""
	input_router.resume_system()
	input_router.set_phase(LocalInputRouter.Phase.PLAY)
	_begin_kangaroo_attempt(true)
	last_message = (
		"Containment defect attempt restarted from the pre-Play score snapshot; "
		+ "construction is unchanged."
	)
	_refresh_match_ui()
	_update_defect_presentation()


func _hug_contacts_snapshot() -> Array[Dictionary]:
	var contacts: Array[Dictionary] = []
	var seen: Dictionary = {}
	for seat in kangaroo_controller.live_seats:
		var actor := actors.get(seat) as ChickenController
		if actor == null or not is_instance_valid(actor) or actor.lifecycle.is_terminal():
			continue
		for node in actor.contact_overlaps():
			if not node is ChickenController:
				continue
			var other := node as ChickenController
			if (
				other.lifecycle.is_terminal()
				or not kangaroo_controller.live_seats.has(other.seat_index)
				or actor.seat_index == other.seat_index
			):
				continue
			var low := mini(actor.seat_index, other.seat_index)
			var high := maxi(actor.seat_index, other.seat_index)
			var pair_key := "%d:%d" % [low, high]
			if seen.has(pair_key):
				continue
			seen[pair_key] = true
			(
				contacts
				. append(
					{
						"seat_a": low,
						"seat_b": high,
						"distance_squared":
						actor.global_position.distance_squared_to(other.global_position),
					}
				)
			)
	return contacts


func _apply_kangaroo_outcomes(outcomes: Array) -> void:
	var score_result: Dictionary = (
		kangaroo_controller.score_result() if kangaroo_controller.ended else {}
	)
	var last_cluck_winner := int(score_result.get("last_cluck_seat", -1))
	for outcome in outcomes:
		var seat := int(outcome.get("seat_index", -1))
		var actor := actors.get(seat) as ChickenController
		if actor == null or not is_instance_valid(actor):
			continue
		if bool(score_result.get("last_cluck", false)) and seat == last_cluck_winner:
			actor.secure("last_cluck_winner")
		else:
			actor.eliminate(str(outcome.get("cause", "eliminated")))
	if kangaroo_controller.ended and not bool(score_result.get("last_cluck", false)):
		var winner_seat := int(score_result.get("winner_seat", -1))
		var winner := actors.get(winner_seat) as ChickenController
		if winner != null and is_instance_valid(winner):
			winner.secure("kangaroo_winner")


func _finish_kangaroo() -> void:
	if phase_controller.phase != MatchPhaseController.Phase.PLAY:
		return
	var score_result := kangaroo_controller.score_result()
	if not kangaroo_controller.commit_score_once(score_result):
		return
	_record_score_presentation(items.round_number + 1, score_result)
	last_resolution = score_result.duplicate(true)
	for seat in kangaroo_controller.seat_indices:
		cumulative_score_units[seat] = int(score_result.totals_units[seat])
	items.end_round()
	items.director.elimination_sink_exclusive = false
	results_ready.clear()
	for seat in input_router.registry.joined_seats():
		var seat_index := int(seat.seat)
		input_router.registry.set_ready(seat_index, false)
		results_ready[seat_index] = false
	last_results_model = MatchResultsViewModel.kangaroo(
		items.round_number,
		input_router.registry.joined_seats(),
		kangaroo_controller.outcomes(),
		score_result
	)
	_bind_score_presentation(last_results_model, items.round_number)
	phase_controller.enter(MatchPhaseController.Phase.RESULTS, tuning.match_results_advance_seconds)
	_set_input_phase()
	current_context = BoundedStageCamera.Context.PLAY
	last_message = "Kangaroo ended. Construction persists; placement awards are committed."
	_clear_command_panels()
	_refresh_match_ui()


func _build_kangaroo_ui() -> void:
	_kangaroo_overlay = CanvasLayer.new()
	_kangaroo_overlay.name = "P11KangarooDebugOverlay"
	_kangaroo_overlay.layer = 21
	_kangaroo_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_kangaroo_overlay)
	_toolbar = HBoxContainer.new()
	_toolbar.name = "P11KangarooToolbar"
	_toolbar.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_toolbar.position = Vector2(18.0, 70.0)
	_toolbar.size = Vector2(440.0, 42.0)
	_toolbar.add_theme_constant_override("separation", 8)
	_kangaroo_overlay.add_child(_toolbar)
	_command_stack = VBoxContainer.new()
	_command_stack.name = "P11KangarooCommands"
	_command_stack.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_command_stack.position = Vector2(-625.0, 230.0)
	_command_stack.size = Vector2(610.0, 250.0)
	_command_stack.add_theme_constant_override("separation", 8)
	_command_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_kangaroo_overlay.add_child(_command_stack)
	_marker_label = Label.new()
	_marker_label.name = "P11KangarooMarkers"
	_marker_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_marker_label.position = Vector2(18.0, -64.0)
	_marker_label.size = Vector2(520.0, 42.0)
	_marker_label.add_theme_font_size_override("font_size", 18)
	_marker_label.add_theme_color_override("font_color", Color.WHITE)
	_marker_label.add_theme_color_override("font_outline_color", Color("#15242b"))
	_marker_label.add_theme_constant_override("outline_size", 4)
	_marker_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_kangaroo_overlay.add_child(_marker_label)
	_defect_panel = PanelContainer.new()
	_defect_panel.name = "P11ContainmentDefectPanel"
	_defect_panel.set_anchors_preset(Control.PRESET_CENTER)
	_defect_panel.position = Vector2(-360.0, -105.0)
	_defect_panel.size = Vector2(720.0, 210.0)
	_defect_panel.visible = false
	_defect_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var defect_style := StyleBoxFlat.new()
	defect_style.bg_color = Color("#14232a")
	defect_style.border_color = Color("#ffc857")
	defect_style.set_border_width_all(4)
	defect_style.set_corner_radius_all(10)
	defect_style.content_margin_left = 22
	defect_style.content_margin_right = 22
	defect_style.content_margin_top = 16
	defect_style.content_margin_bottom = 16
	_defect_panel.add_theme_stylebox_override("panel", defect_style)
	_kangaroo_overlay.add_child(_defect_panel)
	var defect_content := VBoxContainer.new()
	defect_content.add_theme_constant_override("separation", 12)
	_defect_panel.add_child(defect_content)
	_defect_notice = Label.new()
	_defect_notice.name = "P11ContainmentDefectNotice"
	_defect_notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	defect_content.add_child(_defect_notice)
	_restart_attempt_button = Button.new()
	_restart_attempt_button.name = "restart_kangaroo_attempt"
	_restart_attempt_button.text = "Restart defect attempt"
	_restart_attempt_button.custom_minimum_size = Vector2(0.0, 48.0)
	_restart_attempt_button.focus_mode = Control.FOCUS_NONE
	_restart_attempt_button.pressed.connect(_restart_kangaroo_attempt)
	defect_content.add_child(_restart_attempt_button)


func _add_kangaroo_button(label: String, callback: Callable, node_name: String) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = label
	button.custom_minimum_size = Vector2(190.0, 38.0)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(callback)
	_toolbar.add_child(button)
	return button


func _update_kangaroo_ui(active_time: float) -> void:
	if _command_stack == null:
		return
	var commands := kangaroo_controller.active_commands()
	var current_ids: Dictionary = {}
	for command in commands:
		var command_id := int(command.command_id)
		current_ids[command_id] = true
		if not _command_panels.has(command_id):
			_command_panels[command_id] = _create_command_panel(command)
			if not _seen_command_ids.has(command_id):
				_seen_command_ids[command_id] = true
				_play_command_cue(int(command.command))
		var panel: Dictionary = _command_panels[command_id]
		var type := int(command.command)
		var is_telegraph := str(command.status) == "TELEGRAPH"
		var countdown_start := (
			float(command.response_start_at) if is_telegraph else float(command.response_end_at)
		)
		var countdown_total := (
			float(command.response_start_at) - float(command.telegraph_start_at)
			if is_telegraph
			else float(command.response_end_at) - float(command.response_start_at)
		)
		panel.pose.text = (
			"DEBUG POSE • %s  %s"
			% [_command_icon(type), KangarooRoundController.command_name(type)]
		)
		panel.steps.text = "DEBUG AUDIO %d Hz • KANG  →  GA  →  ROO" % _command_frequency(type)
		panel.note.text = "DEBUG • " + _command_instruction(command)
		if bool(command.is_storm):
			panel.pose.text += " • STORM %d" % command_id
		panel.ring.set_time(maxf(0.0, countdown_start - active_time), countdown_total)
	for command_id in _command_panels.keys().duplicate():
		if current_ids.has(command_id):
			continue
		var panel: Dictionary = _command_panels[command_id]
		if is_instance_valid(panel.root):
			panel.root.queue_free()
		_command_panels.erase(command_id)
	if _marker_label != null:
		_marker_label.text = _kangaroo_marker_status()
	if _presenter != null and arena != null:
		var floor_line := arena.spawn_feet.y
		_presenter.set_state(
			kangaroo_controller.presentation_commands(active_time),
			arena.arena_bounds,
			floor_line,
			active_time,
			camera_rig.global_position
		)
	_update_diagnostics()


func _create_command_panel(command: Dictionary) -> Dictionary:
	var root := PROMPT_SCENE.instantiate() as PanelContainer
	root.name = "Command_%d" % int(command.command_id)
	root.custom_minimum_size = Vector2(590.0, 112.0)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var type := int(command.command)
	var tint := _command_color(type)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#101f27")
	style.bg_color.a = 0.9
	style.border_color = tint
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	style.content_margin_left = 12
	style.content_margin_right = 10
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	root.add_theme_stylebox_override("panel", style)
	var template_row := root.get_node("Row") as HBoxContainer
	root.remove_child(template_row)
	template_row.queue_free()
	var content := VBoxContainer.new()
	content.name = "DebugCommandContent"
	content.add_theme_constant_override("separation", 4)
	var row := HBoxContainer.new()
	row.name = "DebugCommandHeader"
	row.add_theme_constant_override("separation", 10)
	var details := HBoxContainer.new()
	details.name = "DebugCommandDetails"
	details.add_theme_constant_override("separation", 10)
	root.add_child(content)
	content.add_child(row)
	content.add_child(details)
	var icon := Label.new()
	icon.name = "DebugPoseIcon"
	icon.text = _command_icon(type)
	icon.add_theme_font_size_override("font_size", 32)
	icon.custom_minimum_size = Vector2(44.0, 0.0)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(icon)
	var pose := Label.new()
	pose.name = "DebugPoseText"
	pose.add_theme_font_size_override("font_size", 18)
	pose.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(pose)
	var steps := Label.new()
	steps.name = "DebugPoseSteps"
	steps.add_theme_font_size_override("font_size", 12)
	steps.custom_minimum_size = Vector2(190.0, 0.0)
	details.add_child(steps)
	var note := Label.new()
	note.name = "DebugCommandNote"
	note.add_theme_font_size_override("font_size", 11)
	note.custom_minimum_size = Vector2(330.0, 0.0)
	note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_child(note)
	var ring := RING_SCENE.instantiate() as UiCountdownRing
	ring.name = "CommandCountdown"
	ring.custom_minimum_size = Vector2(195.0, 0.0)
	row.add_child(ring)
	_command_stack.add_child(root)
	return {"root": root, "pose": pose, "steps": steps, "note": note, "ring": ring, "icon": icon}


func _clear_command_panels() -> void:
	for panel in _command_panels.values():
		var root: Control = panel.root
		if is_instance_valid(root):
			root.queue_free()
	_command_panels.clear()
	if _marker_label != null:
		_marker_label.text = ""


func _command_instruction(command: Dictionary) -> String:
	match int(command.command):
		KangarooRoundController.Command.FREEZE:
			return "Freeze: no intentional run or jump input. Forced motion does not count."
		KangarooRoundController.Command.RISING:
			return "Rising: stand on built support above %.0f wu." % float(command.wave_y)
		KangarooRoundController.Command.HUG:
			return "Hug: pair with one live chicken at evaluation."
	return ""


func _command_icon(command: int) -> String:
	match command:
		KangarooRoundController.Command.FREEZE:
			return "●"
		KangarooRoundController.Command.RISING:
			return "↑"
		KangarooRoundController.Command.HUG:
			return "↔"
	return "?"


func _command_color(command: int) -> Color:
	match command:
		KangarooRoundController.Command.FREEZE:
			return Color("#f2c14e")
		KangarooRoundController.Command.RISING:
			return Color("#39b9c9")
		KangarooRoundController.Command.HUG:
			return Color("#e47ab2")
	return Color.WHITE


func _command_frequency(command: int) -> int:
	match command:
		KangarooRoundController.Command.FREEZE:
			return 330
		KangarooRoundController.Command.RISING:
			return 440
		KangarooRoundController.Command.HUG:
			return 554
	return 0


func _kangaroo_marker_status() -> String:
	var parts: Array[String] = []
	for seat in kangaroo_controller.seat_indices:
		var count := int(kangaroo_controller.marker_counts.get(seat, 0))
		var steps := "KANG  GA  ROO"
		if count == 1:
			steps = "[KANG]  GA  ROO"
		elif count == 2:
			steps = "[KANG]  [GA]  ROO"
		elif count >= 3:
			steps = "[KANG]  [GA]  [ROO]"
		parts.append(
			"P%d %s" % [int(input_router.registry.get_seat(seat).get("identity", seat + 1)), steps]
		)
	return "     ".join(parts)


func _play_command_cue(command: int) -> void:
	if _debug_tones.is_empty():
		_debug_tones[0] = _make_debug_tone(330.0)
		_debug_tones[1] = _make_debug_tone(440.0)
		_debug_tones[2] = _make_debug_tone(554.0)
	var player := AudioStreamPlayer.new()
	player.name = "P11DebugCue"
	player.stream = _debug_tones.get(command)
	player.volume_db = -8.0
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()
	_trigger_shake()


func _make_debug_tone(frequency: float) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.stereo = false
	var sample_count := 2205
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for index in range(sample_count):
		var envelope := 1.0 - float(index) / float(sample_count)
		var sample := int(
			sin(TAU * frequency * float(index) / float(stream.mix_rate)) * 5200.0 * envelope
		)
		var unsigned_sample := sample & 0xffff
		data[index * 2] = unsigned_sample & 0xff
		data[index * 2 + 1] = (unsigned_sample >> 8) & 0xff
	stream.data = data
	return stream


func _trigger_shake() -> void:
	if _screen_shake_mode == 2:
		_shake_remaining = 0.0
		if camera_rig != null:
			camera_rig.offset = Vector2.ZERO
		return
	_shake_remaining = 0.22


func _update_shake(delta: float) -> void:
	if camera_rig == null:
		return
	_shake_remaining = maxf(0.0, _shake_remaining - delta)
	if _shake_remaining <= 0.0 or _screen_shake_mode == 2:
		if _screen_shake_mode == 2:
			_shake_remaining = 0.0
		camera_rig.offset = Vector2.ZERO
		return
	var intensity := 6.0 if _screen_shake_mode == 0 else 2.0
	var fade := clampf(_shake_remaining / 0.22, 0.0, 1.0)
	var phase := float(Time.get_ticks_msec()) * 0.09
	camera_rig.offset = Vector2(sin(phase), cos(phase * 1.37)) * intensity * fade


func _cycle_shake() -> void:
	if phase_controller.phase != MatchPhaseController.Phase.LOBBY and not get_tree().paused:
		last_message = "Pause before changing screen shake."
		_refresh_match_ui()
		return
	_screen_shake_mode = (_screen_shake_mode + 1) % 3
	if match_snapshot != null:
		var presentation := match_snapshot.presentation.duplicate(true) as PresentationSettings
		presentation.screen_shake = _screen_shake_mode
		match_snapshot.presentation = presentation
	_update_shake_button()


func _update_shake_button() -> void:
	if _shake_button == null:
		return
	var shake_label: String = ["Full", "Reduced", "Off"][_screen_shake_mode]
	_shake_button.text = "Shake: %s" % shake_label


func _update_defect_presentation() -> void:
	if _kangaroo_overlay == null:
		return
	if _defect_paused:
		_kangaroo_overlay.layer = 23
		_kangaroo_overlay.visible = true
		_command_stack.visible = false
		_toolbar.visible = false
		_marker_label.visible = false
		_defect_notice.text = (
			"DEBUG DEFECT • %s\nConstruction and the pre-Play score snapshot are preserved."
			% _defect_reason
		)
		_defect_panel.visible = true
		return
	_kangaroo_overlay.layer = 21
	_kangaroo_overlay.visible = (
		phase_controller.phase
		in [MatchPhaseController.Phase.LOBBY, MatchPhaseController.Phase.PLAY]
	)
	_toolbar.visible = phase_controller.phase == MatchPhaseController.Phase.LOBBY
	_command_stack.visible = phase_controller.phase == MatchPhaseController.Phase.PLAY
	_marker_label.visible = phase_controller.phase == MatchPhaseController.Phase.PLAY
	_defect_panel.visible = false

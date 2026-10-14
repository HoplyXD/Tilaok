class_name P05MatchRoom
extends ItemLabRoom

const MATCH_BUILD_ID := "P06-karera-scoring-dev"
const MARKS := {"CIRCLE": "●", "TRIANGLE": "▲", "SQUARE": "■", "DIAMOND": "◆"}
const RACE_CANDIDATE_QUEUE_SCRIPT := preload("res://scripts/match/race_candidate_queue.gd")
const VARIANT_LABELS := {
	"build.hollow_blocks.cell_1x1": "Kaing 1×1",
	"build.hollow_blocks.stack_2x3": "Kaing 2×3",
	"build.bamboo_bridge.span_4x1": "Tulay 4×1",
	"build.hollow_blocks.column_1x3": "Kaing 1×3",
	"build.bamboo_bridge.span_3x1": "Tulay 3×1",
	"build.bamboo_bridge.span_5x1": "Tulay 5×1",
	"move.tire_spring.tire_2x2": "Gulong 2×2",
	"build.solid_block.slab_3x1": "Solid 3×1",
	"build.wood_box.box_2x2": "Box 2×2",
	"build.collapsing_block.cell_1x1": "Crumble 1×1",
}
const PHASE_TO_INPUT := {
	MatchPhaseController.Phase.LOBBY: LocalInputRouter.Phase.LOBBY,
	MatchPhaseController.Phase.PUGAD: LocalInputRouter.Phase.PUGAD,
	MatchPhaseController.Phase.PLACE: LocalInputRouter.Phase.PLACE,
	MatchPhaseController.Phase.PLAY: LocalInputRouter.Phase.PLAY,
	MatchPhaseController.Phase.RESULTS: LocalInputRouter.Phase.RESULTS,
}

var phase_controller := MatchPhaseController.new()
var placement_controller := MatchPlacementController.new()
var match_streams := SeededDiagnosticStreams.new()
var race_round_controller := RaceRoundController.new()
var race_candidate_queue := RACE_CANDIDATE_QUEUE_SCRIPT.new()
var egg_pool: Array[Dictionary] = []
var assignments: Dictionary = {}
var selected_egg_by_seat: Dictionary = {}
var results_ready: Dictionary = {}
var claim_feedback: Dictionary = {}
var pending_claims: Array[Dictionary] = []
var match_seed := 12345
var match_run_id := 1
var match_snapshot: ConfigurationSnapshot
var last_resolution: Dictionary = {}
var last_results_model: MatchResultsViewModel
var cumulative_score_units: Dictionary = {}
var round_start_score_units: Dictionary = {}
var _match_canvas: CanvasLayer
var _top_bar: PanelContainer
var _info_panel: PanelContainer
var _phase_label: Label
var _timer_label: Label
var _seat_label: Label
var _feedback_label: Label
var _hints_label: Label
var _egg_row: HBoxContainer
var _results_panel: MatchResultsPanel
var _match_buttons: Dictionary = {}
var _ghosts: Dictionary = {}
var _claim_was_flushed_tick := -1


func _init() -> void:
	profile_id = "karera_slice"


func set_match_seed(value: int) -> void:
	match_seed = value


func _ready() -> void:
	super._ready()
	if arena == null or input_router == null or items == null or not definitions.is_valid():
		return
	if input_router.action_pressed.is_connected(_on_lab_action_pressed):
		input_router.action_pressed.disconnect(_on_lab_action_pressed)
	if input_router.navigation_step.is_connected(_on_lab_navigation_step):
		input_router.navigation_step.disconnect(_on_lab_navigation_step)
	if input_router.disabled_action_cue.is_connected(_on_lab_disabled_action):
		input_router.disabled_action_cue.disconnect(_on_lab_disabled_action)
	input_router.action_pressed.connect(_on_match_action_pressed)
	input_router.navigation_step.connect(_on_match_navigation_step)
	input_router.disabled_action_cue.connect(_on_match_disabled_action)
	if _overlay_layer != null and is_instance_valid(_overlay_layer):
		_overlay_layer.queue_free()
		_overlay_layer = null
	phase_controller.enter(MatchPhaseController.Phase.LOBBY)
	if goal_area != null:
		goal_area.body_entered.connect(_on_goal_body_entered)
	actor_created.connect(_on_actor_created)
	for actor_variant in actors.values():
		_on_actor_created(actor_variant as ChickenController)
	_set_input_phase()
	last_message = "Join two to four seats, then mark every joined seat ready to start."
	_move_build_region_label_below_controls()
	_update_diagnostics()
	print("P05_MATCH_READY build=%s seed=%d" % [MATCH_BUILD_ID, match_seed])


func _exit_tree() -> void:
	_free_match_ghosts()
	if input_router != null:
		if input_router.action_pressed.is_connected(_on_match_action_pressed):
			input_router.action_pressed.disconnect(_on_match_action_pressed)
		if input_router.navigation_step.is_connected(_on_match_navigation_step):
			input_router.navigation_step.disconnect(_on_match_navigation_step)
		if input_router.disabled_action_cue.is_connected(_on_match_disabled_action):
			input_router.disabled_action_cue.disconnect(_on_match_disabled_action)
	super._exit_tree()


func _process(delta: float) -> void:
	if get_tree().paused:
		return
	_update_identity_badges()
	_update_camera_targets()
	if phase_controller.phase == MatchPhaseController.Phase.PUGAD:
		if phase_controller.advance(delta):
			_finish_pugad_timeout()
	elif phase_controller.phase == MatchPhaseController.Phase.PLACE:
		if phase_controller.advance(delta):
			_finish_place_timeout()
	elif phase_controller.phase == MatchPhaseController.Phase.RESULTS:
		if phase_controller.advance(delta):
			_start_next_round()
	_update_diagnostics()


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if get_tree().paused:
		return
	if phase_controller.phase == MatchPhaseController.Phase.PUGAD:
		_flush_claims()
	elif phase_controller.phase == MatchPhaseController.Phase.PLAY:
		_collect_goal_overlaps()
		var step_result := race_round_controller.advance_step(
			delta, Engine.get_physics_frames(), race_candidate_queue.drain()
		)
		_apply_race_outcomes(step_result.new_outcomes)
		if bool(step_result.ended):
			_finish_race(str(step_result.end_reason))


func _build_hud() -> void:
	_match_canvas = CanvasLayer.new()
	_match_canvas.name = "P05MatchHudLayer"
	_match_canvas.layer = 22
	add_child(_match_canvas)
	_top_bar = PanelContainer.new()
	_top_bar.name = "P05MatchHud"
	_top_bar.process_mode = Node.PROCESS_MODE_ALWAYS
	_top_bar.size = Vector2(tuning.camera_virtual_width_px, tuning.camera_hud_reservation_px)
	_top_bar.add_theme_stylebox_override("panel", _hud_style())
	_match_canvas.add_child(_top_bar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	_top_bar.add_child(row)
	var title := Label.new()
	title.text = "TILAOK! • KARERA"
	title.add_theme_font_size_override("font_size", 13)
	row.add_child(title)
	_phase_label = Label.new()
	_phase_label.custom_minimum_size = Vector2(150.0, 0.0)
	row.add_child(_phase_label)
	_timer_label = Label.new()
	_timer_label.custom_minimum_size = Vector2(80.0, 0.0)
	row.add_child(_timer_label)
	_add_match_button(row, "Join K1", func() -> void: join_keyboard("K1"), "join_k1")
	_add_match_button(row, "Join K2", func() -> void: join_keyboard("K2"), "join_k2")
	_add_match_button(row, "Start match", start_match, "start")
	_pause_button = _add_match_button(row, "Pause", _toggle_pause, "pause")
	_add_match_button(row, "Return", request_return, "return")
	for child in row.get_children():
		if child is Button:
			(child as Button).focus_mode = Control.FOCUS_NONE
	_info_panel = PanelContainer.new()
	_info_panel.name = "P05MatchInfoPanel"
	_info_panel.position = Vector2(0.0, tuning.camera_hud_reservation_px)
	_info_panel.size = Vector2(tuning.camera_virtual_width_px, 116.0)
	_info_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_info_panel.add_theme_stylebox_override("panel", _hud_style())
	_match_canvas.add_child(_info_panel)
	var lower := VBoxContainer.new()
	lower.add_theme_constant_override("separation", 3)
	lower.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_info_panel.add_child(lower)
	_seat_label = Label.new()
	_seat_label.add_theme_color_override("font_color", Color.WHITE)
	_seat_label.add_theme_color_override("font_outline_color", Color("#14232a"))
	_seat_label.add_theme_constant_override("outline_size", 3)
	lower.add_child(_seat_label)
	_feedback_label = Label.new()
	_feedback_label.add_theme_color_override("font_color", Color("#fff2b7"))
	_feedback_label.add_theme_color_override("font_outline_color", Color("#14232a"))
	_feedback_label.add_theme_font_size_override("font_size", 13)
	_feedback_label.add_theme_constant_override("outline_size", 3)
	_feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lower.add_child(_feedback_label)
	_hints_label = Label.new()
	_hints_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hints_label.add_theme_font_size_override("font_size", 13)
	_hints_label.add_theme_color_override("font_color", Color.WHITE)
	_hints_label.add_theme_color_override("font_outline_color", Color("#14232a"))
	_hints_label.add_theme_constant_override("outline_size", 3)
	lower.add_child(_hints_label)
	_egg_row = HBoxContainer.new()
	_egg_row.name = "PugadEggRow"
	_egg_row.position = Vector2(32.0, 200.0)
	_egg_row.add_theme_constant_override("separation", 16)
	_match_canvas.add_child(_egg_row)
	_results_panel = MatchResultsPanel.new()
	_results_panel.name = "P05ResultsPanel"
	_results_panel.visible = false
	_match_canvas.add_child(_results_panel)
	_status_label = _feedback_label
	_support_label = _hints_label


func _add_match_button(
	parent: Control, text_value: String, callback: Callable, key: String
) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(92.0, 36.0)
	button.pressed.connect(callback)
	parent.add_child(button)
	_match_buttons[key] = button
	return button


func _update_diagnostics() -> void:
	if _phase_label == null:
		return
	var phase_text: String = str(MatchPhaseController.Phase.keys()[phase_controller.phase])
	_phase_label.text = phase_text
	if phase_controller.phase == MatchPhaseController.Phase.PLAY:
		_timer_label.text = "%.1f s" % race_round_controller.remaining_seconds()
	elif phase_controller.remaining_seconds > 0.0:
		_timer_label.text = "%.1f s" % phase_controller.remaining_seconds
	else:
		_timer_label.text = ""
	var rows := PackedStringArray()
	for row in LobbyViewModel.seat_rows(input_router.registry):
		var state := "READY" if row.ready else "NOT READY"
		if not row.connected:
			state = "DISCONNECTED"
		rows.append("P%d %s %s — %s" % [row.identity, row.mark, row.shape, state])
	_seat_label.text = "   ".join(rows)
	var status_lines := PackedStringArray()
	if phase_controller.phase == MatchPhaseController.Phase.PLACE:
		var placement_rows := PackedStringArray()
		for seat_index_variant in placement_controller.cursors:
			var seat_index := int(seat_index_variant)
			var cursor: Dictionary = placement_controller.cursors[seat_index]
			var verdict := items.validate_placement(
				str(cursor.variant_key), cursor.cell, int(cursor.quarter_turns), _actor_rects()
			)
			var seat := input_router.registry.get_seat(seat_index)
			var cue := "VALID" if bool(verdict.allowed) else "BLOCKED: " + str(verdict.reason)
			placement_rows.append(
				(
					"P%d %s — %s · %s"
					% [
						int(seat.identity),
						MARKS.get(str(seat.shape), "◆"),
						_short_variant_label(str(cursor.variant_key)),
						cue
					]
				)
			)
		status_lines.append("   •   ".join(placement_rows))
	elif (
		(phase_controller.phase != MatchPhaseController.Phase.PUGAD or claim_feedback.is_empty())
		and not last_message.is_empty()
	):
		status_lines.append(last_message)
	for seat_index in claim_feedback:
		var seat := input_router.registry.get_seat(int(seat_index))
		status_lines.append(
			(
				"P%d %s — %s"
				% [int(seat.identity), MARKS.get(str(seat.shape), "◆"), claim_feedback[seat_index]]
			)
		)
	_feedback_label.text = "\n".join(status_lines)
	_hints_label.text = _phase_hint()
	if _pause_button != null:
		_pause_button.text = "Resume" if get_tree().paused else "Pause"
	if _match_buttons.has("start"):
		var can_start := phase_controller.phase == MatchPhaseController.Phase.LOBBY
		_match_buttons.start.disabled = not (
			can_start and LobbyViewModel.can_start(input_router.registry)
		)
		_match_buttons.start.visible = phase_controller.phase == MatchPhaseController.Phase.LOBBY
	for key in ["join_k1", "join_k2"]:
		_match_buttons[key].visible = phase_controller.phase == MatchPhaseController.Phase.LOBBY
	_egg_row.visible = phase_controller.phase == MatchPhaseController.Phase.PUGAD
	_info_panel.visible = phase_controller.phase != MatchPhaseController.Phase.RESULTS
	if _results_panel != null:
		_results_panel.visible = phase_controller.phase == MatchPhaseController.Phase.RESULTS


func _refresh_match_ui() -> void:
	_update_diagnostics()
	_refresh_all_match_ghosts()


func start_match() -> bool:
	if phase_controller.phase != MatchPhaseController.Phase.LOBBY:
		return false
	if not LobbyViewModel.can_start(input_router.registry):
		last_message = "At least two connected seats must be joined and ready."
		_refresh_match_ui()
		return false
	match_run_id += 1
	match_snapshot = ConfigurationSnapshot.create(
		tuning, PresentationSettings.new(), profile_id, match_seed, match_run_id
	)
	tuning = match_snapshot.gameplay
	_seed = match_seed
	input_router.tuning = tuning
	definitions = _load_definitions()
	items.configure(tuning, arena, support_tracker, definitions, world_layer)
	items.director.elimination_sink = _on_item_elimination
	cumulative_score_units.clear()
	for seat in input_router.registry.joined_seats():
		cumulative_score_units[int(seat.seat)] = 0
	match_streams.seed_all(match_seed)
	_begin_pugad()
	return true


func _begin_pugad() -> void:
	_reset_actors_for_round()
	race_candidate_queue.reset()
	_free_match_ghosts()
	placement_controller.cursors.clear()
	assignments.clear()
	selected_egg_by_seat.clear()
	results_ready.clear()
	claim_feedback.clear()
	pending_claims.clear()
	var joined := input_router.registry.joined_seats()
	var seat_indices: Array[int] = []
	for seat in joined:
		seat_indices.append(int(seat.seat))
	egg_pool = PugadEggPoolGenerator.generate(
		definitions, tuning, match_streams, seat_indices.size() + tuning.match_pugad_extra_eggs
	)
	for seat_index in seat_indices:
		selected_egg_by_seat[seat_index] = 0 if not egg_pool.is_empty() else -1
	phase_controller.enter(MatchPhaseController.Phase.PUGAD, tuning.match_pugad_seconds)
	_set_input_phase()
	last_message = "Pugad: choose one egg. Number and shape markers identify each seat."
	_refresh_egg_cards()
	_refresh_match_ui()


func _refresh_egg_cards() -> void:
	if _egg_row == null:
		return
	for child in _egg_row.get_children():
		child.queue_free()
	for egg_index in range(egg_pool.size()):
		var egg: Dictionary = egg_pool[egg_index]
		var wrapper := VBoxContainer.new()
		wrapper.add_theme_constant_override("separation", 2)
		_egg_row.add_child(wrapper)
		var card := PugadEggCard.new()
		card.egg_id = str(egg.egg_id)
		if not card.configure(definitions, str(egg.variant_key), 0, tuning):
			continue
		card.name = "Pugad_%s" % egg.egg_id
		card.selected = _is_egg_selected(egg_index)
		card.egg_claimed.connect(_on_egg_card_claimed)
		wrapper.add_child(card)
		var owner := _owner_for_egg(str(egg.egg_id))
		var ownership_text := "Egg %d • AVAILABLE" % (egg_index + 1)
		if owner >= 0:
			var seat := input_router.registry.get_seat(owner)
			ownership_text = (
				"Egg %d • P%d %s" % [egg_index + 1, int(seat.identity), str(seat.shape)]
			)
		elif _has_pending_claim(str(egg.egg_id)):
			ownership_text = "Egg %d • CLAIM PENDING" % (egg_index + 1)
		var label := Label.new()
		label.text = ownership_text
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 11)
		wrapper.add_child(label)
		var lost_pickers := _claim_feedback_for_selection(egg_index)
		if not lost_pickers.is_empty():
			var retry_label := Label.new()
			retry_label.text = "CLAIM LOST — RE-PICK: " + ", ".join(lost_pickers)
			retry_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			retry_label.add_theme_font_size_override("font_size", 9)
			wrapper.add_child(retry_label)
		if owner < 0 and not _has_pending_claim(str(egg.egg_id)):
			var picker := _selecting_seats_for_egg(egg_index)
			if not picker.is_empty():
				var select_label := Label.new()
				select_label.text = "Selected by " + ", ".join(picker)
				select_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				select_label.add_theme_font_size_override("font_size", 10)
				wrapper.add_child(select_label)


func _is_egg_selected(egg_index: int) -> bool:
	for selected in selected_egg_by_seat.values():
		if int(selected) == egg_index:
			return true
	return false


func _selecting_seats_for_egg(egg_index: int) -> PackedStringArray:
	var selected: PackedStringArray = []
	for seat_index in selected_egg_by_seat:
		if int(selected_egg_by_seat[seat_index]) != egg_index:
			continue
		var seat := input_router.registry.get_seat(int(seat_index))
		selected.append("P%d %s" % [int(seat.identity), MARKS.get(str(seat.shape), "◆")])
	return selected


func _claim_feedback_for_selection(egg_index: int) -> PackedStringArray:
	var retry: PackedStringArray = []
	for seat_index in claim_feedback:
		if int(selected_egg_by_seat.get(seat_index, -1)) != egg_index:
			continue
		var seat := input_router.registry.get_seat(int(seat_index))
		retry.append("P%d %s" % [int(seat.identity), MARKS.get(str(seat.shape), "◆")])
	return retry


func _owner_for_egg(egg_id: String) -> int:
	for seat_index in assignments:
		if str(assignments[seat_index]) == egg_id:
			return int(seat_index)
	return -1


func _has_pending_claim(egg_id: String) -> bool:
	for claim in pending_claims:
		if str(claim.egg_id) == egg_id:
			return true
	return false


func _on_egg_card_claimed(egg_id: String, _variant_key: String) -> void:
	var seat_index := -1
	for seat in input_router.registry.joined_seats():
		if not assignments.has(int(seat.seat)):
			seat_index = int(seat.seat)
			break
	if seat_index < 0:
		return
	for index in range(egg_pool.size()):
		if str(egg_pool[index].egg_id) == egg_id:
			selected_egg_by_seat[seat_index] = index
			break
	_queue_claim(seat_index, egg_id)


func _queue_claim(seat_index: int, egg_id: String) -> void:
	if phase_controller.phase != MatchPhaseController.Phase.PUGAD or assignments.has(seat_index):
		return
	if _owner_for_egg(egg_id) >= 0:
		last_message = "That egg is claimed. Move to an available egg and try again."
		_refresh_match_ui()
		return
	var exists := false
	for egg in egg_pool:
		if str(egg.egg_id) == egg_id:
			exists = true
			break
	if not exists:
		return
	var tick := Engine.get_physics_frames()
	for claim in pending_claims:
		if int(claim.seat_index) == seat_index and int(claim.tick) == tick:
			return
	pending_claims.append({"seat_index": seat_index, "egg_id": egg_id, "tick": tick})
	claim_feedback.erase(seat_index)
	last_message = (
		"P%d %s claim queued; contested same-tick picks use the seeded lottery."
		% [seat_index + 1, MARKS.get(str(input_router.registry.get_seat(seat_index).shape), "◆")]
	)
	_refresh_egg_cards()


func _flush_claims() -> void:
	if pending_claims.is_empty():
		return
	var seats: Array[int] = []
	for seat in input_router.registry.joined_seats():
		seats.append(int(seat.seat))
	var result := PugadClaimArbiter.resolve(
		egg_pool, pending_claims, seats, match_streams.tie, assignments
	)
	assignments = result.assignments
	for seat_index in assignments:
		claim_feedback.erase(seat_index)
	for losing_seat in result.losers:
		claim_feedback[int(losing_seat)] = "CLAIM LOST — RE-PICK"
		last_message = (
			"CLAIM LOST — P%d %s, choose another egg."
			% [
				int(losing_seat) + 1,
				MARKS.get(str(input_router.registry.get_seat(int(losing_seat)).shape), "◆")
			]
		)
	pending_claims.clear()
	_claim_was_flushed_tick = Engine.get_physics_frames()
	_refresh_egg_cards()
	if assignments.size() >= seats.size():
		_enter_place()


func _finish_pugad_timeout() -> void:
	# Flush the last input batch first: claims received on the timeout tick take precedence.
	_flush_claims()
	if phase_controller.phase != MatchPhaseController.Phase.PUGAD:
		return
	var seats: Array[int] = []
	for seat in input_router.registry.joined_seats():
		seats.append(int(seat.seat))
	var available: Array[Dictionary] = []
	for egg in egg_pool:
		if _owner_for_egg(str(egg.egg_id)) < 0:
			available.append(egg)
	var result := PugadClaimArbiter.assign_remaining(
		available, seats, assignments, match_streams.egg
	)
	assignments = result.assignments
	last_message = "Pugad timer ended; remaining seats received distinct remaining eggs."
	_enter_place()


func _enter_place() -> void:
	if phase_controller.phase != MatchPhaseController.Phase.PUGAD:
		return
	items.enter_place()
	placement_controller.setup(_claimed_variants_by_seat(), definitions, tuning)
	input_router.set_rotation_supported(true)
	phase_controller.enter(MatchPhaseController.Phase.PLACE, tuning.match_place_seconds)
	_set_input_phase()
	current_context = BoundedStageCamera.Context.PLACE
	camera_rig.set_context(current_context)
	pointers.clear()
	_free_match_ghosts()
	for seat_index_variant in placement_controller.cursors.keys():
		_add_match_ghost(int(seat_index_variant))
	last_message = "Place: move the exact hatched variant, rotate if supported, and confirm."
	_refresh_all_match_ghosts()
	_update_camera_targets()
	_refresh_match_ui()


func _claimed_variants_by_seat() -> Dictionary:
	var variants: Dictionary = {}
	for seat_index in assignments:
		for egg in egg_pool:
			if str(egg.egg_id) == str(assignments[seat_index]):
				variants[int(seat_index)] = str(egg.variant_key)
				break
	return variants


func _add_match_ghost(seat_index: int) -> void:
	_cursor_counter += 1
	var ghost := ItemGhost.new()
	ghost.name = "P05ItemGhostSeat%d" % (seat_index + 1)
	world_layer.add_child(ghost)
	_ghosts[seat_index] = ghost
	var cursor: Dictionary = placement_controller.cursors[seat_index]
	(
		pointers
		. append(
			{
				"id": "p05_cursor_%d" % seat_index,
				"rect":
				Rect2(
					Vector2(cursor.cell) * tuning.grid_cell_wu, Vector2.ONE * tuning.grid_cell_wu
				),
				"confirmed": false,
				"node": ghost,
				"label": null,
			}
		)
	)


func _free_match_ghosts() -> void:
	for ghost_variant in _ghosts.values():
		var ghost := ghost_variant as Node
		if ghost != null and is_instance_valid(ghost):
			ghost.queue_free()
	_ghosts.clear()
	if phase_controller.phase != MatchPhaseController.Phase.PLACE:
		pointers.clear()


func _refresh_all_match_ghosts() -> void:
	if (
		phase_controller.phase != MatchPhaseController.Phase.PLACE
		or placement_controller.cursors.is_empty()
	):
		return
	for seat_index in placement_controller.cursors:
		_refresh_match_ghost(int(seat_index))


func _refresh_match_ghost(seat_index: int) -> void:
	if not placement_controller.cursors.has(seat_index) or not _ghosts.has(seat_index):
		return
	var cursor: Dictionary = placement_controller.cursors[seat_index]
	var found := definitions.find_variant(str(cursor.variant_key))
	if found.is_empty():
		return
	var variant := found.variant as ItemVariantDefinition
	var verdict := items.validate_placement(
		str(cursor.variant_key), cursor.cell, int(cursor.quarter_turns), _actor_rects()
	)
	var footprint := ItemPlacementValidator.footprint_rect_for(
		variant, cursor.cell, int(cursor.quarter_turns), tuning
	)
	var strips: Array[Rect2] = []
	var normals: Array[Vector2] = []
	for region in ItemGeometry.resolve_regions(variant, int(cursor.quarter_turns), tuning):
		if region.kind == ItemRegionSpec.Kind.ONE_WAY_TOP:
			var rect: Rect2 = region.rect
			rect.position += footprint.position
			strips.append(rect)
			normals.append(region.normal)
	var seat := input_router.registry.get_seat(seat_index)
	var mark: String = str(MARKS.get(str(seat.shape), "◆"))
	(_ghosts[seat_index] as ItemGhost).show_state(
		footprint,
		strips,
		normals,
		bool(verdict.allowed),
		str(verdict.reason),
		"P%d %s%s" % [int(seat.identity), mark, " • LOCKED" if cursor.confirmed else ""],
		_short_variant_label(str(cursor.variant_key))
	)
	(_ghosts[seat_index] as ItemGhost).compact_label = true
	(_ghosts[seat_index] as ItemGhost).set_overlay(
		overlay_for_cursor(str(cursor.variant_key), cursor.cell, int(cursor.quarter_turns))
	)
	for pointer in pointers:
		if str(pointer.id) == "p05_cursor_%d" % seat_index:
			pointer.rect = footprint
			pointer.confirmed = bool(cursor.confirmed)
	_update_camera_targets()


func _on_match_navigation_step(seat_index: int, direction: String) -> void:
	if phase_controller.phase == MatchPhaseController.Phase.PUGAD:
		if direction in ["left", "right"]:
			_cycle_egg_selection(seat_index, -1 if direction == "left" else 1)
	elif phase_controller.phase == MatchPhaseController.Phase.PLACE:
		var step := Vector2i.ZERO
		match direction:
			"left":
				step = Vector2i(-1, 0)
			"right":
				step = Vector2i(1, 0)
			"up":
				step = Vector2i(0, -1)
			"down":
				step = Vector2i(0, 1)
		if placement_controller.move(seat_index, step):
			_refresh_match_ghost(seat_index)
		elif step != Vector2i.ZERO and placement_controller.is_confirmed(seat_index):
			_show_placement_locked(seat_index)


func _cycle_egg_selection(seat_index: int, delta: int) -> void:
	if not selected_egg_by_seat.has(seat_index) or egg_pool.is_empty():
		return
	var current := int(selected_egg_by_seat[seat_index])
	for offset in range(1, egg_pool.size() + 1):
		var next := posmod(current + delta * offset, egg_pool.size())
		if _owner_for_egg(str(egg_pool[next].egg_id)) < 0:
			selected_egg_by_seat[seat_index] = next
			break
	_refresh_egg_cards()


func _on_match_action_pressed(seat_index: int, action_name: String) -> void:
	if seat_index < 0:
		return
	match phase_controller.phase:
		MatchPhaseController.Phase.LOBBY:
			if action_name == "ready":
				_refresh_match_ui()
		MatchPhaseController.Phase.PUGAD:
			if action_name == "claim" and selected_egg_by_seat.has(seat_index):
				var index := int(selected_egg_by_seat[seat_index])
				if index >= 0 and index < egg_pool.size():
					_queue_claim(seat_index, str(egg_pool[index].egg_id))
		MatchPhaseController.Phase.PLACE:
			if action_name == "confirm":
				_confirm_placement(seat_index)
			elif action_name == "rotate":
				if placement_controller.is_confirmed(seat_index):
					_show_placement_locked(seat_index)
				elif not placement_controller.rotate(seat_index):
					last_message = (
						"P%d rotation is unavailable for this variant." % (seat_index + 1)
					)
				_refresh_match_ghost(seat_index)
				_refresh_match_ui()
		MatchPhaseController.Phase.RESULTS:
			if action_name == "confirm":
				results_ready[seat_index] = true
				last_message = "P%d is ready for the next round." % (seat_index + 1)
				_refresh_match_ui()
				if _all_results_ready():
					_start_next_round()


func _on_match_disabled_action(seat_index: int, action_name: String) -> void:
	if action_name == "rotate":
		last_message = "P%d rotation is unavailable for this variant." % (seat_index + 1)
		_refresh_match_ui()


func _confirm_placement(seat_index: int) -> void:
	if not placement_controller.cursors.has(seat_index):
		return
	var cursor: Dictionary = placement_controller.cursors[seat_index]
	if bool(cursor.confirmed):
		return
	var verdict := items.validate_placement(
		str(cursor.variant_key), cursor.cell, int(cursor.quarter_turns), _actor_rects()
	)
	if not bool(verdict.allowed):
		last_message = "P%d cannot confirm: %s" % [seat_index + 1, verdict.reason]
		_refresh_match_ghost(seat_index)
		_refresh_match_ui()
		return
	placement_controller.set_confirmed(seat_index, true)
	last_message = (
		"P%d edit is pending. Nothing changes until everyone confirms or the timer ends."
		% (seat_index + 1)
	)
	_refresh_all_match_ghosts()
	_refresh_match_ui()
	if placement_controller.all_confirmed():
		_resolve_place_edits(placement_controller.confirmed_edits())


func _show_placement_locked(seat_index: int) -> void:
	var locked_message := (
		"P%d placement is locked. There is no undo this round." % (seat_index + 1)
	)
	if last_message == locked_message:
		return
	last_message = locked_message
	_refresh_match_ui()


func _finish_place_timeout() -> void:
	if phase_controller.phase != MatchPhaseController.Phase.PLACE:
		return
	var validity: Dictionary = {}
	for seat_index in placement_controller.cursors:
		var cursor: Dictionary = placement_controller.cursors[seat_index]
		var verdict := items.validate_placement(
			str(cursor.variant_key), cursor.cell, int(cursor.quarter_turns), _actor_rects()
		)
		validity[int(seat_index)] = bool(verdict.allowed)
	_resolve_place_edits(placement_controller.timeout_edits(validity))


func _resolve_place_edits(edits: Array[Dictionary]) -> void:
	if phase_controller.phase != MatchPhaseController.Phase.PLACE:
		return
	var resolver_result := AtomicEditResolver.resolve(
		definitions, arena, tuning, items.pieces.values(), edits, items.round_number, _actor_rects()
	)
	last_resolution = resolver_result
	var committed := items.commit_batch(resolver_result, _actor_rects())
	var messages := PackedStringArray()
	for seat_index in resolver_result.rejections:
		messages.append(
			"P%d rejected: %s" % [int(seat_index) + 1, resolver_result.rejections[seat_index]]
		)
	if not bool(committed.allowed):
		messages.append("Batch rejected: %s" % committed.get("reason", "unknown reason"))
	else:
		messages.append(
			(
				"Committed %d edit(s); removed %d prior construction item(s)."
				% [committed.commits.size(), committed.removals.size()]
			)
		)
	last_message = "\n".join(messages)
	_enter_play()


func _enter_play() -> void:
	_free_match_ghosts()
	input_router.set_rotation_supported(false)
	phase_controller.enter(MatchPhaseController.Phase.PLAY)
	_set_input_phase()
	current_context = BoundedStageCamera.Context.PLAY
	camera_rig.set_context(current_context)
	start_play()
	round_start_score_units = cumulative_score_units.duplicate(true)
	var seats: Array[int] = []
	for seat in input_router.registry.joined_seats():
		seats.append(int(seat.seat))
	var round_id := "%d:%d" % [match_run_id, items.round_number + 1]
	race_round_controller.configure(
		tuning.match_race_hard_cap_seconds, tuning.match_race_after_first_finish_seconds
	)
	if not race_round_controller.begin(round_id, seats, round_start_score_units):
		push_error("Could not initialize Karera round %s" % round_id)
		return
	race_candidate_queue.begin(round_id)
	last_message = (
		"Karera: reach the flag. Finished chickens are secured; "
		+ "remaining runners fail at the deadline."
	)
	_refresh_match_ui()


func _finish_race(reason: String) -> void:
	if phase_controller.phase != MatchPhaseController.Phase.PLAY or not race_round_controller.ended:
		return
	var outcome_rows := race_round_controller.ledger.outcomes()
	var seat_indices: Array[int] = []
	for seat in input_router.registry.joined_seats():
		seat_indices.append(int(seat.seat))
	var score_result := RaceScoreCalculator.calculate(
		seat_indices, outcome_rows, round_start_score_units
	)
	if not race_round_controller.ledger.commit_score_once(
		race_round_controller.ledger.round_id, score_result
	):
		return
	for seat_index in seat_indices:
		cumulative_score_units[seat_index] = int(score_result.totals_units[seat_index])
	items.end_round()
	results_ready.clear()
	for seat in input_router.registry.joined_seats():
		var seat_index := int(seat.seat)
		input_router.registry.set_ready(seat_index, false)
		results_ready[seat_index] = false
	last_results_model = MatchResultsViewModel.race(
		items.round_number,
		input_router.registry.joined_seats(),
		outcome_rows,
		score_result,
		reason,
		race_round_controller.hard_cap_seconds,
		race_round_controller.post_first_finish_seconds
	)
	_results_panel.show_results(last_results_model)
	phase_controller.enter(MatchPhaseController.Phase.RESULTS, tuning.match_results_advance_seconds)
	_set_input_phase()
	current_context = BoundedStageCamera.Context.PLAY
	last_message = (
		"Karera ended (%s). Construction persists; scores carry into the next round." % reason
	)
	_refresh_match_ui()


func _on_actor_created(actor: ChickenController) -> void:
	if actor == null or not is_instance_valid(actor):
		return
	var callback := _on_actor_escaped.bind(actor.seat_index)
	if not actor.escaped_bounds.is_connected(callback):
		actor.escaped_bounds.connect(callback)


func _on_actor_escaped(seat_index: int) -> void:
	if phase_controller.phase != MatchPhaseController.Phase.PLAY:
		return
	var actor := actors.get(seat_index) as ChickenController
	if actor == null or actor.lifecycle.status != PlayerLifecycleState.Status.ACTIVE:
		return
	race_candidate_queue.queue_elimination(
		seat_index,
		Engine.get_physics_frames(),
		"",
		-1,
		(
			"bounds:%s:%d:%d"
			% [race_round_controller.ledger.round_id, Engine.get_physics_frames(), seat_index]
		)
	)


## First-batch hazard eliminations go to the P06 ledger as candidates (see the bridge).
func _on_item_elimination(record: AttributionRecord) -> bool:
	var playing := phase_controller.phase == MatchPhaseController.Phase.PLAY
	return ItemEliminationBridge.submit(
		race_candidate_queue, race_round_controller, playing, record
	)


func _on_goal_body_entered(body: Node2D) -> void:
	if phase_controller.phase == MatchPhaseController.Phase.PLAY and body is ChickenController:
		race_candidate_queue.queue_goal(body as ChickenController, Engine.get_physics_frames())


func _collect_goal_overlaps() -> void:
	if phase_controller.phase == MatchPhaseController.Phase.PLAY:
		race_candidate_queue.collect_goal_overlaps(goal_area, Engine.get_physics_frames())


func _apply_race_outcomes(outcomes: Array) -> void:
	for outcome in outcomes:
		var actor := actors.get(int(outcome.seat_index)) as ChickenController
		if actor == null or not is_instance_valid(actor):
			continue
		if str(outcome.outcome) == "finished":
			actor.secure("reached_goal")
		else:
			actor.eliminate(str(outcome.get("cause", "eliminated")))
	_update_camera_targets()


func _reset_actors_for_round() -> void:
	if arena == null:
		return
	var spawn := arena.controller_origin_from_feet(arena.spawn_feet)
	for actor_variant in actors.values():
		var actor := actor_variant as ChickenController
		if actor != null and is_instance_valid(actor):
			support_tracker.invalidate_actor(actor.support_actor_id)
			actor.reset_for_round(spawn)
	_update_camera_targets()


func _all_results_ready() -> bool:
	var seats := input_router.registry.joined_seats()
	if seats.size() < 2:
		return false
	for seat in seats:
		if not bool(results_ready.get(int(seat.seat), false)):
			return false
	return true


func _start_next_round() -> void:
	if phase_controller.phase != MatchPhaseController.Phase.RESULTS:
		return
	_begin_pugad()


func reset_room() -> void:
	super.reset_room()
	if items != null:
		items.reset_match()
	phase_controller.enter(MatchPhaseController.Phase.LOBBY)
	race_round_controller = RaceRoundController.new()
	cumulative_score_units.clear()
	round_start_score_units.clear()
	race_candidate_queue.reset()
	assignments.clear()
	egg_pool.clear()
	results_ready.clear()
	claim_feedback.clear()
	pending_claims.clear()
	_free_match_ghosts()
	get_tree().paused = false
	if input_router != null:
		input_router.resume_system()
		input_router.set_rotation_supported(false)
		input_router.set_phase(LocalInputRouter.Phase.LOBBY)
	last_message = "Match reset: Pugad, Place and Play are ready for a new match."
	_refresh_match_ui()


func _set_input_phase() -> void:
	if input_router != null:
		input_router.set_phase(PHASE_TO_INPUT[phase_controller.phase])


func _phase_hint() -> String:
	match phase_controller.phase:
		MatchPhaseController.Phase.LOBBY:
			return (
				"Move: WASD / arrows / stick · Jump: Space / Ctrl / A · "
				+ "Ready: F / Enter / A · Pad A joins"
			)
		MatchPhaseController.Phase.PUGAD:
			return "← / → select egg · F / Enter / Pad A claim"
		MatchPhaseController.Phase.PLACE:
			return "Move: WASD / arrows / stick · Rotate: R / Right Shift · Confirm: F / Enter / Pad A"
		MatchPhaseController.Phase.PLAY:
			return "K1 AD/W jump-glide/S sneak · K2 arrows · Pad A jump · reach the flag"
		MatchPhaseController.Phase.RESULTS:
			return "F / Enter / Pad A ready · next round starts after 8 seconds"
	return ""


func _short_variant_label(variant_key: String) -> String:
	if VARIANT_LABELS.has(variant_key):
		return str(VARIANT_LABELS[variant_key])
	return definitions.short_label(variant_key)


func _move_build_region_label_below_controls() -> void:
	if world_layer == null or arena == null:
		return
	for child in world_layer.get_children():
		if child is Label and (child as Label).text == "BUILD REGION • DEBUG":
			(child as Label).position = Vector2(
				arena.build_region.end.x - 196.0, arena.build_region.end.y - 18.0
			)

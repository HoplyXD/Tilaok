extends SceneTree

const HARNESS_SCENE := preload("res://scenes/harness/foundation_harness.tscn")
const VARIANT_1X1 := "build.hollow_blocks.cell_1x1"
const VARIANT_2X3 := "build.hollow_blocks.stack_2x3"
const VARIANT_TULAY := "build.bamboo_bridge.span_4x1"
const PAD_DEVICE_IDS := [710, 711]
const CAPTURE_DIR := "../docs/evidence/p05"

var checks := 0
var failures := 0
var harness: FoundationHarness
var room: P05MatchRoom
var output_dir := ""
var _round_one_signature := ""
var _match_seed := 12345
var _handoff_rows := PackedStringArray(
	[
		"| Run | Seat | Egg | Expected variant | Hatch/ghost | Placed piece | Evidence |",
		"|---|---:|---|---|---|---|---|"
	]
)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	output_dir = ProjectSettings.globalize_path("res://").path_join(CAPTURE_DIR).simplify_path()
	DirAccess.make_dir_recursive_absolute(output_dir)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	harness = HARNESS_SCENE.instantiate() as FoundationHarness
	root.add_child(harness)
	await _wait_frames(30)
	_press_harness_room_button()
	await _wait_frames(3)
	room = harness.active_room as P05MatchRoom
	_check(room != null, "P05 match room opens from the foundation harness at 1920x1080")
	if room == null:
		quit(1)
		return
	_check(not harness.get_node("Layout").visible, "match room fills the viewport when opened")
	for run_index in range(2):
		if run_index == 0:
			await _prepare_four_seats()
			await _run_lobby()
		await _run_round(run_index)
		if run_index == 0:
			await _advance_all_ready_with_held_key()
			_check(
				room.phase_controller.phase == MatchPhaseController.Phase.PUGAD,
				"results ready advances to the next Pugad"
			)
			_check(
				room.items.construction_signature() == _round_one_signature,
				"construction persists into the next round"
			)
	await _click_text_button(room, "Return")
	await _wait_frames(3)
	_check(
		harness.active_room == null and harness.get_node("Layout").visible,
		"Return releases the P05 room back to the harness"
	)
	var matrix_file := FileAccess.open(
		output_dir.path_join("variant_handoff_matrix.md"), FileAccess.WRITE
	)
	var matrix_lines := PackedStringArray(
		[
			"# P05 exact variant handoff",
			"",
			"Seed: `%d`; enabled variants were Kaing 1x1, Kaing 2x3, and Tulay 4x1." % _match_seed,
			"",
		]
	)
	matrix_lines.append_array(_handoff_rows)
	(
		matrix_lines
		. append_array(
			[
				"",
				"The rotated 2x3 ghost changes from 2x3 to 3x2 cells while keeping the same item key.",
			]
		)
	)
	matrix_file.store_string("\n".join(matrix_lines) + "\n")
	matrix_file.close()
	print("P05_INTERACTIVE checks=%d failures=%d captures=%s" % [checks, failures, output_dir])
	harness.queue_free()
	await _wait_frames(3)
	quit(1 if failures > 0 else 0)


func _prepare_four_seats() -> void:
	await _click_text_button(room, "Join K1")
	await _click_text_button(room, "Join K2")
	for device_id in PAD_DEVICE_IDS:
		var seat_index := room.input_router.registry.join_gamepad(device_id)
		if seat_index >= 0:
			room.input_router.seat_joined.emit(seat_index)
	_check(
		room.actors.size() == 4,
		"K1/K2 plus two synthetic gamepads occupy four fixed identity seats"
	)
	_check(
		int(room.input_router.registry.get_seat(2).identity) == 3,
		"synthetic gamepad 1 has seat 3 number/shape identity"
	)
	_check(
		int(room.input_router.registry.get_seat(3).identity) == 4,
		"synthetic gamepad 2 has seat 4 number/shape identity"
	)


func _run_lobby() -> void:
	await _capture("01_lobby_1920x1080.png")
	_check(
		room._match_buttons.start.disabled,
		"Start match remains disabled until two or more joined seats are ready"
	)
	await _key_tap(KEY_F)
	await _key_tap(KEY_ENTER, KEY_LOCATION_UNSPECIFIED, "K2")
	for device_id in PAD_DEVICE_IDS:
		_joy_tap(device_id, JOY_BUTTON_A)
	await _wait_frames(2)
	_check(
		LobbyViewModel.can_start(room.input_router.registry),
		"K1/K2 and both synthetic gamepads can mark ready"
	)
	_check(not room._match_buttons.start.disabled, "all-ready input enables Start match")
	_match_seed = _seed_with_every_enabled_variant(12345)
	room.set_match_seed(_match_seed)
	print("P05_INTERACTIVE seed=%d" % _match_seed)
	await _click_text_button(room, "Start match")
	_check(
		room.phase_controller.phase == MatchPhaseController.Phase.PUGAD,
		"ready gate starts seeded Pugad"
	)
	await _capture("02_pugad_eggs_1920x1080.png")


func _run_round(round_index: int) -> void:
	if round_index > 0:
		await _capture("08_pugad_round2_1920x1080.png")
	# Every seat chooses the same egg on this input step so the seeded tie/loss cue is visible.
	for seat_index in range(4):
		room.selected_egg_by_seat[seat_index] = 0
	_send_claim_press(0)
	_send_claim_press(1)
	_send_claim_press(2)
	_send_claim_press(3)
	_send_claim_release(0)
	_send_claim_release(1)
	_send_claim_release(2)
	_send_claim_release(3)
	await _wait_physics_frames(2)
	var first_claim_count := room.assignments.size()
	_check(
		first_claim_count == 1, "same-tick four-seat egg contest grants one owner and no duplicate"
	)
	_check(not room.claim_feedback.is_empty(), "claim losers receive text/shape retry cues")
	if round_index == 0:
		await _capture("03_claim_loss_retry_1920x1080.png")
	# Re-pick distinct available eggs, preferring a missing enabled variant for ghost/egg evidence.
	for seat_index in range(4):
		if room.assignments.has(seat_index):
			continue
		var chosen_index := _choose_unclaimed_egg_with_missing_variant()
		if chosen_index < 0:
			continue
		room.selected_egg_by_seat[seat_index] = chosen_index
		room._queue_claim(seat_index, str(room.egg_pool[chosen_index].egg_id))
	await _wait_physics_frames(2)
	_check(room.assignments.size() == 4, "all four seats hatch one exact variant after repicking")
	_check(
		room.phase_controller.phase == MatchPhaseController.Phase.PLACE,
		"all assigned seats enter Place"
	)
	for seat_index_variant in room.assignments:
		var seat_index := int(seat_index_variant)
		var egg_id := str(room.assignments[seat_index])
		var egg_variant := _variant_for_egg(egg_id)
		var ghost_variant := str(room.placement_controller.cursors[seat_index].variant_key)
		var identity_matches := egg_variant == ghost_variant and not egg_variant.is_empty()
		_check(
			identity_matches,
			(
				"egg %s hands off exact variant to seat %d ghost (%s)"
				% [egg_id, seat_index + 1, ghost_variant]
			)
		)
		var egg_row := (
			"| %d | P%d | `%s` | `%s` | `%s` | pending | `02_pugad_eggs` → "
			+ "`04_place_exact_variant_pairs` |"
		)
		_handoff_rows.append(
			egg_row % [round_index + 1, seat_index + 1, egg_id, egg_variant, ghost_variant]
		)
	for seat_index in room.placement_controller.cursors:
		var cursor: Dictionary = room.placement_controller.cursors[seat_index]
		if round_index > 0:
			cursor.cell.y = 5
			room.placement_controller.cursors[seat_index] = cursor
	room._refresh_all_match_ghosts()
	await _capture("04_place_exact_variant_pairs_1920x1080.png")
	var rotated_seat := _find_seat_with_variant(VARIANT_2X3)
	if rotated_seat >= 0:
		room.placement_controller.cursors[rotated_seat].quarter_turns = 1
		room._refresh_match_ghost(rotated_seat)
		var rotated_ghost := room._ghosts[rotated_seat] as ItemGhost
		var source_variant := (
			room.definitions.find_variant(VARIANT_2X3).variant as ItemVariantDefinition
		)
		var expected_rotated_size := (
			ItemGeometry.rotated_size(Vector2(source_variant.footprint_cells), 1)
			* room.tuning.grid_cell_wu
		)
		_check(
			(
				rotated_ghost.footprint_rect.size == expected_rotated_size
				and expected_rotated_size == Vector2(3.0, 2.0) * room.tuning.grid_cell_wu
			),
			"rotated Kaing 2x3 ghost changes expected footprint to 3x2 cells"
		)
		var rotation_row := (
			(
				"| %d | P%d | same egg | Kaing 2x3 | `%s` | "
				% [round_index + 1, rotated_seat + 1, VARIANT_2X3]
			)
			+ (
				"3x2 cells (%.0fx%.0f wu) | `05_place_rotated_2x3_ghost` |"
				% [expected_rotated_size.x, expected_rotated_size.y]
			)
		)
		_handoff_rows.append(rotation_row)
		await _capture("05_place_rotated_2x3_ghost_1920x1080.png")
		room.placement_controller.cursors[rotated_seat].quarter_turns = 0
		room._refresh_match_ghost(rotated_seat)
		_check(
			str(room.placement_controller.cursors[rotated_seat].variant_key) == VARIANT_2X3,
			"2x3 hatch retains its exact identity through the rotated ghost"
		)
	# Route both keyboard confirm buttons and the two synthetic gamepad south buttons.
	_send_confirm_press(0)
	_send_confirm_press(1)
	_send_confirm_press(2)
	_send_confirm_press(3)
	_send_confirm_release(0)
	_send_confirm_release(1)
	_send_confirm_release(2)
	_send_confirm_release(3)
	await physics_frame
	_check(
		room.phase_controller.phase == MatchPhaseController.Phase.PLAY,
		"confirmed edits resolve together before live Karera Play"
	)
	_check(
		room.last_resolution.commits.size() == room.assignments.size(),
		"valid Place submissions materialize one piece per assigned seat"
	)
	for seat_index_variant in room.assignments:
		var seat_index := int(seat_index_variant)
		var expected_variant := _variant_for_egg(str(room.assignments[seat_index]))
		var placed_variant := ""
		for item_variant in room.items.pieces.values():
			var item := item_variant as PlacedItem
			if item.owner_seat == seat_index and item.placed_round == room.items.round_number:
				placed_variant = item.variant_key
				break
		var placed_exactly := placed_variant == expected_variant
		_check(
			placed_exactly,
			"seat %d placed exact hatched variant (%s)" % [seat_index + 1, placed_variant]
		)
		var piece_row := (
			"| %d | P%d | `%s` | `%s` | `%s` | `%s` | `04_place_exact_variant_pairs` "
			+ "→ `06_live_karera` |"
		)
		(
			_handoff_rows
			. append(
				(
					piece_row
					% [
						round_index + 1,
						seat_index + 1,
						str(room.assignments[seat_index]),
						expected_variant,
						expected_variant,
						placed_variant,
					]
				)
			)
		)
	if round_index == 0:
		var before_x := (room.actors[0] as ChickenController).global_position.x
		_send_key("K1", KEY_D, true)
		await _wait_physics_frames(10)
		_send_key("K1", KEY_D, false)
		_check(
			(room.actors[0] as ChickenController).global_position.x > before_x,
			"K1 keyboard input moves its chicken during diagnostic Play"
		)
	await _capture("06_live_karera_1920x1080.png")
	var signature_before_end := room.items.construction_signature()
	if round_index == 0:
		_round_one_signature = signature_before_end
	var goal_position := room.goal_area.global_position
	for actor_variant in room.actors.values():
		(actor_variant as ChickenController).global_position = goal_position
	await _wait_physics_frames(4)
	_check(
		room.phase_controller.phase == MatchPhaseController.Phase.RESULTS,
		"actual goal contact opens scored results"
	)
	_check(
		room.last_results_model.suppression_reason.contains("Everyone reached the goal"),
		"four-player all-finish results explain the no-points rule"
	)
	await _capture("07_explained_results_1920x1080.png")
	if round_index > 0:
		_check(
			room.items.construction_signature() == signature_before_end,
			"second round keeps first-round construction intact"
		)


func _advance_all_ready_with_held_key() -> void:
	# K1 remains down across RESULTS → PUGAD. The one-shot press must be consumed.
	# It must not become a claim in the next phase.
	_send_key("K1", KEY_F, true)
	_send_key("K2", KEY_ENTER, true)
	_send_key("K2", KEY_ENTER, false)
	_joy_button(PAD_DEVICE_IDS[0], JOY_BUTTON_A, true)
	_joy_button(PAD_DEVICE_IDS[0], JOY_BUTTON_A, false)
	_joy_button(PAD_DEVICE_IDS[1], JOY_BUTTON_A, true)
	_joy_button(PAD_DEVICE_IDS[1], JOY_BUTTON_A, false)
	await physics_frame
	_check(
		room.phase_controller.phase == MatchPhaseController.Phase.PUGAD,
		"all-ready result advance starts the next round"
	)
	_check(
		room.assignments.is_empty() and room.pending_claims.is_empty(),
		"held K1 confirm does not auto-claim in next Pugad"
	)
	_send_key("K1", KEY_F, false)
	await _wait_frames(2)


func _choose_unclaimed_egg_with_missing_variant() -> int:
	var owned_variants: Dictionary = {}
	for seat_index in room.assignments:
		var egg_id := str(room.assignments[seat_index])
		for egg in room.egg_pool:
			if str(egg.egg_id) == egg_id:
				owned_variants[str(egg.variant_key)] = true
				break
	var reserved_eggs: Dictionary = {}
	for claim in room.pending_claims:
		reserved_eggs[str(claim.egg_id)] = true
		for egg in room.egg_pool:
			if str(egg.egg_id) == str(claim.egg_id):
				owned_variants[str(egg.variant_key)] = true
				break
	for egg_index in range(room.egg_pool.size()):
		var egg: Dictionary = room.egg_pool[egg_index]
		if (
			room._owner_for_egg(str(egg.egg_id)) < 0
			and not reserved_eggs.has(str(egg.egg_id))
			and not owned_variants.has(str(egg.variant_key))
		):
			return egg_index
	for egg_index in range(room.egg_pool.size()):
		if (
			room._owner_for_egg(str(room.egg_pool[egg_index].egg_id)) < 0
			and not reserved_eggs.has(str(room.egg_pool[egg_index].egg_id))
		):
			return egg_index
	return -1


func _find_seat_with_variant(variant_key: String) -> int:
	for seat_index in room.placement_controller.cursors:
		if str(room.placement_controller.cursors[seat_index].variant_key) == variant_key:
			return int(seat_index)
	return -1


func _variant_for_egg(egg_id: String) -> String:
	for egg in room.egg_pool:
		if str(egg.egg_id) == egg_id:
			return str(egg.variant_key)
	return ""


func _seed_with_every_enabled_variant(start_seed: int) -> int:
	for seed_value in range(start_seed, start_seed + 500):
		var streams := SeededDiagnosticStreams.new()
		streams.seed_all(seed_value)
		var pool := PugadEggPoolGenerator.generate(
			room.definitions,
			room.tuning,
			streams,
			room.input_router.registry.joined_seats().size() + room.tuning.match_pugad_extra_eggs
		)
		var seen: Dictionary = {}
		for egg in pool:
			seen[str(egg.variant_key)] = true
		if seen.size() == room.tuning.item_enabled_variants.size():
			return seed_value
	return start_seed


func _send_claim_press(seat_index: int) -> void:
	if seat_index == 0:
		_send_key("K1", KEY_F, true)
	elif seat_index == 1:
		_send_key("K2", KEY_ENTER, true)
	else:
		_joy_button(PAD_DEVICE_IDS[seat_index - 2], JOY_BUTTON_A, true)


func _send_claim_release(seat_index: int) -> void:
	if seat_index == 0:
		_send_key("K1", KEY_F, false)
	elif seat_index == 1:
		_send_key("K2", KEY_ENTER, false)
	else:
		_joy_button(PAD_DEVICE_IDS[seat_index - 2], JOY_BUTTON_A, false)


func _send_confirm_press(seat_index: int) -> void:
	_send_claim_press(seat_index)


func _send_confirm_release(seat_index: int) -> void:
	_send_claim_release(seat_index)


func _key_tap(key: Key, location: KeyLocation = KEY_LOCATION_UNSPECIFIED, layout := "K1") -> void:
	_send_key(layout, key, true, location)
	_send_key(layout, key, false, location)
	await process_frame


func _send_key(
	_layout: String, key: Key, pressed: bool, location: KeyLocation = KEY_LOCATION_UNSPECIFIED
) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.location = location
	event.pressed = pressed
	room.input_router._handle_key(event)


func _joy_button(device_id: int, button_index: JoyButton, pressed: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.device = device_id
	event.button_index = button_index
	event.pressed = pressed
	room.input_router._handle_joy_button(event)


func _joy_tap(device_id: int, button_index: JoyButton) -> void:
	_joy_button(device_id, button_index, true)
	_joy_button(device_id, button_index, false)


func _click_text_button(parent: Node, text_value: String) -> void:
	var pending: Array[Node] = [parent]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		if node is Button and (node as Button).text == text_value:
			(node as Button).pressed.emit()
			await _wait_frames(2)
			return
		for child in node.get_children():
			pending.append(child)
	push_error("Could not find button '%s'" % text_value)
	failures += 1


func _press_harness_room_button() -> void:
	for child in harness.get_node("Layout/HarnessPanel/RoomRow").get_children():
		if child is Button and (child as Button).text == "P05 Match Loop":
			(child as Button).pressed.emit()
			return
	push_error("Could not find the P05 harness entry button")
	failures += 1


func _capture(file_name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var path := output_dir.path_join(file_name)
	var result := image.save_png(path)
	_check(
		result == OK and image.get_size() == Vector2i(1920, 1080),
		"captured %s at %s" % [file_name, image.get_size()]
	)


func _wait_frames(count: int) -> void:
	for _frame in range(count):
		await process_frame


func _wait_physics_frames(count: int) -> void:
	for _frame in range(count):
		await physics_frame


func _check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("P05_INTERACTIVE PASSED: ", message)
	else:
		failures += 1
		push_error("P05_INTERACTIVE FAILED: " + message)

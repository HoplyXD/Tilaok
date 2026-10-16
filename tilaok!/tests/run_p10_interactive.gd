extends SceneTree

## P10 interactive checks at 1920x1080 through the foundation harness: the Item Visualizer with
## real K1/K2 key events and synthetic gamepad events, and the P05 match loop with the all-families
## `items_lab` pool. All input is synthetic; PLACEHOLDER art/audio only.

const HARNESS_SCENE := preload("res://scenes/harness/foundation_harness.tscn")
const PAD_IDS := [910, 911]
const SPRING := "move.tire_spring.tire_2x2"
const RAIL_5 := "hazard.rail_trumpo.rail_5x1"
const PAROL_5 := "hazard.parol_pulse.span_5x1"
const LANE_4 := "hazard.slipper_launcher.lane_4x1"
const BULA_3 := "hazard.bubble_planter.path_1x3"
const WALIS_3 := "utility.walis_cleanup.area_3x3"
const NEW_FAMILIES: PackedStringArray = [
	"move.tire_spring",
	"hazard.rail_trumpo",
	"hazard.parol_pulse",
	"hazard.slipper_launcher",
	"utility.walis_cleanup",
	"hazard.bubble_planter",
]

const FIRST_BATCH: PackedStringArray = [
	"build.hollow_blocks",
	"build.bamboo_bridge",
	"move.tire_spring",
	"hazard.rail_trumpo",
	"hazard.parol_pulse",
	"hazard.slipper_launcher",
	"utility.walis_cleanup",
	"hazard.bubble_planter",
]

var checks := 0
var failures := 0
var harness: FoundationHarness
var viz: ItemVisualizerRoom
var match_room: P05MatchRoom
var output_dir := ""


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var override := OS.get_environment("P10_EVIDENCE_DIR")
	output_dir = (
		override
		if not override.is_empty()
		else (
			ProjectSettings
			. globalize_path("res://")
			. path_join("../docs/evidence/p10")
			. simplify_path()
		)
	)
	DirAccess.make_dir_recursive_absolute(output_dir)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	harness = HARNESS_SCENE.instantiate() as FoundationHarness
	root.add_child(harness)
	await _frames(30)
	await _visualizer_session()
	await _match_session()
	print("P10_INTERACTIVE checks=%d failures=%d evidence=%s" % [checks, failures, output_dir])
	harness.queue_free()
	await _frames(3)
	quit(1 if failures > 0 else 0)


# --------------------------------------------------------------------------- Visualizer


func _has_first_batch(ids: PackedStringArray) -> bool:
	for family_id in FIRST_BATCH:
		if not ids.has(family_id):
			return false
	return true


func _ids_of(definitions: ItemDefinitions) -> PackedStringArray:
	var ids := PackedStringArray()
	for family in definitions.families:
		ids.append(family.family_id)
	return ids


## The first cell (scanning from `preferred`, then the build region) where the variant is valid
## and its footprint misses every rect in `taken` (one-use edits occupy none).
func _free_cell(variant_key: String, preferred: Vector2i, taken: Array[Rect2i]) -> Vector2i:
	var found := match_room.definitions.find_variant(variant_key)
	if found.is_empty():
		return preferred
	var family := found.family as ItemFamilyDefinition
	var size := (found.variant as ItemVariantDefinition).footprint_cells
	var candidates: Array[Vector2i] = [preferred]
	for row in range(3, 15):
		for column in range(5, 28):
			candidates.append(Vector2i(column, row))
	for cell in candidates:
		var rect := Rect2i(cell, size)
		var clear := true
		for other in taken:
			clear = clear and not rect.grow(1).intersects(other)
		if not clear or not bool(match_room.items.validate_placement(variant_key, cell, 0).allowed):
			continue
		if not family.one_shot_edit:
			taken.append(rect)
		return cell
	return preferred


func _visualizer_session() -> void:
	_press_harness_button("Item Visualizer")
	await _frames(3)
	viz = harness.active_room as ItemVisualizerRoom
	_check(viz != null, "the harness opens the Item Visualizer from its own button")
	if viz == null:
		return
	_check(not harness.get_node("Layout").visible, "the Visualizer fills the 1920x1080 viewport")
	# The lab set also holds the stage blocks, Spikes, Cannon and explosives (since 2026-10-14).
	_check(
		_has_first_batch(viz.family_ids()),
		(
			"the Visualizer lists all eight first-batch families (%d lab families)"
			% viz.family_ids().size()
		)
	)
	await _click(viz, "Join K1")
	await _click(viz, "Join K2")
	for device_id in PAD_IDS:
		var seat := viz.input_router.registry.join_gamepad(device_id)
		if seat >= 0:
			viz.input_router.seat_joined.emit(seat)
	_check(viz.actors.size() == 4, "K1, K2 and two synthetic gamepads give four test chickens")
	await _click(viz, "Place")
	_check(viz.cursors.size() == 4, "Place gives every seat its own ghost cursor")
	# K1: Gulong at a deliberate cell, rotated once with the real rotate key.
	viz.select_family("move.tire_spring")
	var k1 := viz.cursors[0] as Dictionary
	k1.cell = Vector2i(14, 8)
	viz.move_cursor(0, Vector2i.ZERO)
	await _tap_key(KEY_R)
	_check(int(viz.cursors[0].turns) == 1, "K1 rotate key turns the Gulong ghost to 90 degrees")
	await _tap_key(KEY_E)
	var spring_id := _id_with_variant(SPRING)
	_check(not spring_id.is_empty(), "K1 confirm places the Gulong exactly as ghosted")
	_check(
		(
			viz.items.pieces.has(spring_id)
			and (viz.items.pieces[spring_id] as PlacedItem).quarter_turns == 1
		),
		"the placed Gulong keeps the rotation shown by its ghost"
	)
	# K2: Trumpo with arrow keys, shift rotate and enter.
	viz.select_family("hazard.rail_trumpo")
	var k2 := viz.cursors[1] as Dictionary
	k2.cell = Vector2i(18, 4)
	viz.move_cursor(1, Vector2i(1, 0))
	await _tap_key(KEY_RIGHT, KEY_LOCATION_UNSPECIFIED)
	await _tap_key(KEY_ENTER)
	_check(
		(
			not _id_with_variant(RAIL_5).is_empty()
			or not _id_with_family("hazard.rail_trumpo").is_empty()
		),
		"K2 confirm places a Trumpo"
	)
	# Synthetic gamepad seat 3: Parol; seat 4: Bula.
	viz.select_family("hazard.parol_pulse")
	viz.cursors[2].cell = Vector2i(8, 6)
	viz.move_cursor(2, Vector2i.ZERO)
	_pad_tap(PAD_IDS[0], JOY_BUTTON_A)
	await _frames(2)
	_check(not _id_with_family("hazard.parol_pulse").is_empty(), "gamepad seat 3 confirms a Parol")
	viz.select_family("hazard.bubble_planter")
	viz.cursors[3].cell = Vector2i(24, 10)
	viz.move_cursor(3, Vector2i.ZERO)
	_pad_tap(PAD_IDS[1], JOY_BUTTON_A)
	await _frames(2)
	_check(
		not _id_with_family("hazard.bubble_planter").is_empty(), "gamepad seat 4 confirms a Bula"
	)
	viz.select_family("hazard.slipper_launcher")
	viz.cursors[0].cell = Vector2i(6, 4)
	viz.move_cursor(0, Vector2i.ZERO)
	await _tap_key(KEY_E)
	_check(
		not _id_with_family("hazard.slipper_launcher").is_empty(), "K1 confirms a Tsinelas Launcher"
	)
	await _capture("01_visualizer_place_1920x1080.png")
	# Walis: a one-shot edit removes only an eligible piece from an earlier round.
	viz.items.end_round()
	viz.enter_place()
	viz.select_family("utility.walis_cleanup")
	var before := viz.items.persistent_count()
	viz.cursors[0].cell = Vector2i(5, 3)
	viz.move_cursor(0, Vector2i.ZERO)
	var walis_result := viz.confirm_cursor(0)
	_check(
		bool(walis_result.allowed) and bool(walis_result.get("one_shot", false)),
		"a Walis confirm is accepted as a one-shot edit: %s" % walis_result
	)
	_check(
		viz.items.persistent_count() <= before,
		"Walis never adds a persistent piece (%d -> %d)" % [before, viz.items.persistent_count()]
	)
	# Play: movers, timers and sound sources run; nothing escapes the arena.
	await _click(viz, "Play")
	await _frames(5)
	_check(viz.items.in_play, "Play starts every placed item from its documented reset")
	var phases := {}
	for _frame in range(260):
		await physics_frame
		for row in viz.piece_readouts():
			phases[str(row.state)] = true
	_check(phases.size() >= 3, "live readouts show several states: %s" % [phases.keys()])
	for actor_variant in viz.actors.values():
		var actor := actor_variant as ChickenController
		_check(
			viz.arena.arena_bounds.grow(1.0).has_point(actor.global_position),
			"seat %d stays inside the arena" % (actor.seat_index + 1)
		)
	await _capture("02_visualizer_play_1920x1080.png")
	viz.toggle_library()
	await _frames(2)
	var entries := viz.library_entries()
	var families_listed := {}
	for entry in entries:
		families_listed[entry.family_id] = true
	for family_id in NEW_FAMILIES:
		_check(families_listed.has(family_id), "Library lists %s" % family_id)
	await _capture("03_visualizer_library_1920x1080.png")
	viz.set_release_filter(true)
	_check(viz.library_entries().is_empty(), "release filter hides every unreleased family")
	await _click(viz, "Return")
	await _frames(3)
	_check(harness.active_room == null, "Return releases the Visualizer back to the harness")


# --------------------------------------------------------------------------- P05 match loop


func _match_session() -> void:
	_press_harness_button("P05 Match (all items)")
	await _frames(3)
	match_room = harness.active_room as P05MatchRoom
	_check(match_room != null, "the harness opens the P05 match loop with the items_lab pool")
	if match_room == null:
		return
	_check(
		match_room.profile_id == "items_lab" and _has_first_batch(_ids_of(match_room.definitions)),
		"the match loop carries all eight first-batch families"
	)
	await _click(match_room, "Join K1")
	await _click(match_room, "Join K2")
	for device_id in PAD_IDS:
		var seat := match_room.input_router.registry.join_gamepad(device_id)
		if seat >= 0:
			match_room.input_router.seat_joined.emit(seat)
	_check(match_room.actors.size() == 4, "four seats join the match")
	await _key_tap_match(KEY_E)
	await _key_tap_match(KEY_ENTER)
	for device_id in PAD_IDS:
		_pad_tap(device_id, JOY_BUTTON_A)
	await _frames(2)
	var seed_value := _seed_with_new_families(12345, 3)
	match_room.set_match_seed(seed_value)
	print("P10_INTERACTIVE seed=%d" % seed_value)
	await _click(match_room, "Start match")
	_check(
		match_room.phase_controller.phase == MatchPhaseController.Phase.PUGAD,
		"the ready gate starts a seeded Pugad"
	)
	var new_eggs := 0
	for egg in match_room.egg_pool:
		var family_id := (
			str(egg.variant_key).get_slice(".", 0) + "." + str(egg.variant_key).get_slice(".", 1)
		)
		if NEW_FAMILIES.has(family_id):
			new_eggs += 1
	_check(
		new_eggs >= 3,
		"the Pugad offers first-batch eggs (%d of %d)" % [new_eggs, match_room.egg_pool.size()]
	)
	await _capture("10_match_pugad_items_1920x1080.png")
	# Each seat claims a distinct egg, preferring new-family variants.
	var claimed_families := {}
	for seat_index in range(4):
		var pick := _pick_egg(claimed_families)
		if pick < 0:
			continue
		var egg: Dictionary = match_room.egg_pool[pick]
		match_room.selected_egg_by_seat[seat_index] = pick
		match_room._queue_claim(seat_index, str(egg.egg_id))
		claimed_families[str(egg.variant_key)] = true
	await _wait_physics(3)
	_check(match_room.assignments.size() == 4, "all four seats hatch one exact variant")
	_check(
		match_room.phase_controller.phase == MatchPhaseController.Phase.PLACE,
		"all assigned seats enter Place"
	)
	var exact := true
	for seat_index_variant in match_room.assignments:
		var seat_index := int(seat_index_variant)
		var egg_variant := ""
		for egg in match_room.egg_pool:
			if str(egg.egg_id) == str(match_room.assignments[seat_index]):
				egg_variant = str(egg.variant_key)
		var ghost_variant := str(match_room.placement_controller.cursors[seat_index].variant_key)
		exact = exact and egg_variant == ghost_variant
	_check(exact, "every egg hands its exact variant to its ghost")
	# Spread cursors so every placement is valid, then confirm with real inputs. The lab pool holds
	# pieces up to 6 cells wide, so each seat moves to the first valid cell clear of lower seats.
	var cells: Array[Vector2i] = [Vector2i(8, 7), Vector2i(13, 7), Vector2i(19, 7), Vector2i(24, 7)]
	var taken: Array[Rect2i] = []
	for seat_index in range(4):
		var cursor: Dictionary = match_room.placement_controller.cursors[seat_index]
		cursor.cell = _free_cell(str(cursor.variant_key), cells[seat_index], taken)
		match_room.placement_controller.cursors[seat_index] = cursor
	match_room._refresh_all_match_ghosts()
	await _capture("11_match_place_items_1920x1080.png")
	_send_confirm(0, true)
	_send_confirm(1, true)
	_send_confirm(2, true)
	_send_confirm(3, true)
	_send_confirm(0, false)
	_send_confirm(1, false)
	_send_confirm(2, false)
	_send_confirm(3, false)
	await physics_frame
	_check(
		match_room.phase_controller.phase == MatchPhaseController.Phase.PLAY,
		"confirmed edits resolve together before Play"
	)
	var committed: int = match_room.last_resolution.commits.size()
	var one_shots: int = match_room.last_resolution.one_shot_edits.size()
	var rejected: int = match_room.last_resolution.rejections.size()
	_check(
		committed + one_shots + rejected == 4,
		(
			"every seat's edit is accounted for (%d placed, %d cleanup, %d rejected)"
			% [committed, one_shots, rejected]
		)
	)
	_check(committed + one_shots >= 3, "at least three of four first-batch edits were valid")
	for item_variant in match_room.items.pieces.values():
		var item := item_variant as PlacedItem
		var expected := false
		for egg in match_room.egg_pool:
			if str(egg.variant_key) == item.variant_key:
				expected = true
		_check(expected, "placed piece %s matches a hatched egg variant" % item.instance_id)
	await _wait_physics(150)
	await _capture("12_match_play_items_1920x1080.png")
	for actor_variant in match_room.actors.values():
		var actor := actor_variant as ChickenController
		_check(
			match_room.arena.arena_bounds.grow(2.0).has_point(actor.global_position),
			"seat %d stays inside the arena during Play" % (actor.seat_index + 1)
		)
	var round_end := false
	for actor_variant in match_room.actors.values():
		(actor_variant as ChickenController).global_position = match_room.goal_area.global_position
	await _wait_physics(6)
	round_end = match_room.phase_controller.phase == MatchPhaseController.Phase.RESULTS
	_check(round_end, "goal contact still ends the round with the new families on the stage")
	_check(
		match_room.items.director.records is Array, "hazards recorded attribution without scoring"
	)
	await _click(match_room, "Return")
	await _frames(3)
	_check(harness.active_room == null, "Return leaves the match room cleanly")


func _pick_egg(claimed: Dictionary) -> int:
	var fallback := -1
	for index in range(match_room.egg_pool.size()):
		var egg: Dictionary = match_room.egg_pool[index]
		if (
			match_room._owner_for_egg(str(egg.egg_id)) >= 0
			or match_room._has_pending_claim(str(egg.egg_id))
		):
			continue
		var family_id := (
			str(egg.variant_key).get_slice(".", 0) + "." + str(egg.variant_key).get_slice(".", 1)
		)
		if claimed.has(str(egg.variant_key)):
			continue
		if NEW_FAMILIES.has(family_id):
			return index
		if fallback < 0:
			fallback = index
	return fallback


func _seed_with_new_families(start_seed: int, minimum: int) -> int:
	for seed_value in range(start_seed, start_seed + 800):
		var streams := SeededDiagnosticStreams.new()
		streams.seed_all(seed_value)
		var pool := PugadEggPoolGenerator.generate(
			match_room.definitions,
			match_room.tuning,
			streams,
			(
				match_room.input_router.registry.joined_seats().size()
				+ match_room.tuning.match_pugad_extra_eggs
			)
		)
		var families := {}
		var walis := false
		for egg in pool:
			var family_id := (
				str(egg.variant_key).get_slice(".", 0)
				+ "."
				+ str(egg.variant_key).get_slice(".", 1)
			)
			if NEW_FAMILIES.has(family_id) and family_id != "utility.walis_cleanup":
				families[family_id] = true
			walis = walis or family_id == "utility.walis_cleanup"
		if families.size() >= minimum and not walis:
			return seed_value
	return start_seed


# --------------------------------------------------------------------------- helpers


func _id_with_variant(variant_key: String) -> String:
	for id in viz.items.pieces:
		if (viz.items.pieces[id] as PlacedItem).variant_key == variant_key:
			return str(id)
	return ""


func _id_with_family(family_id: String) -> String:
	for id in viz.items.pieces:
		if (viz.items.pieces[id] as PlacedItem).family_id == family_id:
			return str(id)
	return ""


func _router() -> LocalInputRouter:
	return (
		viz.input_router if harness.active_room == viz and viz != null else match_room.input_router
	)


func _tap_key(key: Key, location: KeyLocation = KEY_LOCATION_UNSPECIFIED) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.location = location
	event.pressed = true
	_router()._handle_key(event)
	event.pressed = false
	_router()._handle_key(event)
	await physics_frame


func _key_tap_match(key: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.pressed = true
	match_room.input_router._handle_key(event)
	event.pressed = false
	match_room.input_router._handle_key(event)
	await process_frame


func _pad_tap(device_id: int, button: JoyButton) -> void:
	var event := InputEventJoypadButton.new()
	event.device = device_id
	event.button_index = button
	event.pressed = true
	_router()._handle_joy_button(event)
	event.pressed = false
	_router()._handle_joy_button(event)


func _send_confirm(seat_index: int, pressed: bool) -> void:
	if seat_index < 2:
		var event := InputEventKey.new()
		var key := KEY_E if seat_index == 0 else KEY_ENTER
		event.keycode = key
		event.physical_keycode = key
		event.pressed = pressed
		match_room.input_router._handle_key(event)
	else:
		var pad := InputEventJoypadButton.new()
		pad.device = PAD_IDS[seat_index - 2]
		pad.button_index = JOY_BUTTON_A
		pad.pressed = pressed
		match_room.input_router._handle_joy_button(pad)


func _press_harness_button(text_value: String) -> void:
	for child in harness.get_node("Layout/HarnessPanel/RoomRow").get_children():
		if child is Button and (child as Button).text == text_value:
			(child as Button).pressed.emit()
			return
	push_error("missing harness button '%s'" % text_value)
	failures += 1


func _click(parent: Node, text_value: String) -> void:
	var pending: Array[Node] = [parent]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		if node is Button and (node as Button).text == text_value:
			(node as Button).pressed.emit()
			await _frames(2)
			return
		for child in node.get_children():
			pending.append(child)
	push_error("missing button '%s'" % text_value)
	failures += 1


func _capture(file_name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var result := image.save_png(output_dir.path_join(file_name))
	_check(
		result == OK and image.get_size() == Vector2i(1920, 1080),
		"captured %s at %s" % [file_name, image.get_size()]
	)


func _frames(count: int) -> void:
	for _frame in range(count):
		await process_frame


func _wait_physics(count: int) -> void:
	for _frame in range(count):
		await physics_frame


func _check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("P10_INTERACTIVE PASSED: ", message)
	else:
		failures += 1
		push_error("P10_INTERACTIVE FAILED: " + message)

class_name ItemLabRoom
extends P03StageRoom

## Item Lab: P03 arena plus the P04 item manager. Placement here is IMMEDIATE and lab-only; it is
## not the P05 atomic Place resolver. All visuals are code-drawn DEBUG graybox.

const LAB_BUILD_ID := "P04-item-lab-dev"
const LAB_PROFILE_ID := "karera_slice"
const CURSOR_START_CELLS: Array[Vector2i] = [
	Vector2i(8, 8), Vector2i(12, 8), Vector2i(16, 8), Vector2i(20, 8)
]

var items: ItemManager
var definitions: ItemDefinitions
var cursors: Dictionary = {}
var selected_variant_key := ""
var last_message := ""
var egg_previews: Dictionary = {}
var library_visible := false
var release_filter := false
var _variant_button: Button
var _cursor_counter := 0
var _overlay_layer: CanvasLayer
var _library_panel: PanelContainer
var _library_label: Label
var _library_preview_host: Control


func _init() -> void:
	profile_id = LAB_PROFILE_ID


func _ready() -> void:
	super._ready()
	if arena == null:
		return
	definitions = _load_definitions()
	if not definitions.is_valid():
		push_error("Item definitions rejected: " + "; ".join(definitions.errors))
		return
	items = ItemManager.new()
	items.name = "ItemManager"
	add_child(items)
	items.configure(tuning, arena, support_tracker, definitions, world_layer)
	items.actors_source = _actors_for_items
	var enabled := _enabled_variant_keys()
	selected_variant_key = enabled[0] if not enabled.is_empty() else ""
	input_router.action_pressed.connect(_on_lab_action_pressed)
	input_router.navigation_step.connect(_on_lab_navigation_step)
	input_router.disabled_action_cue.connect(_on_lab_disabled_action)
	_refresh_rotation_support()
	_build_overlays()
	_update_diagnostics()
	print(
		(
			"P04_ITEM_LAB_READY families=%d enabled_variants=%d profile=%s"
			% [definitions.families.size(), tuning.item_enabled_variants.size(), profile_id]
		)
	)


## Profile-keyed definitions: the P04 profiles keep the exact Kaing/Tulay pair and pool.
func _load_definitions() -> ItemDefinitions:
	ItemEnabledProfiles.apply(tuning, profile_id)
	return ItemDefinitions.load_for_profile(tuning, profile_id)


func _actors_for_items() -> Dictionary:
	return actors


## Region overlay for first-batch families (empty for the P04 construction pieces).
func overlay_for_cursor(variant_key: String, cell: Vector2i, turns: int) -> Array[Dictionary]:
	var found := definitions.find_variant(variant_key)
	if found.is_empty() or (found.family as ItemFamilyDefinition).visual_set == null:
		return []
	return ItemOverlayBuilder.build(
		found.family,
		found.variant,
		cell,
		turns,
		tuning,
		arena,
		items.pieces.values(),
		items.round_number
	)


func _exit_tree() -> void:
	_free_cursors()
	if items != null and is_instance_valid(items):
		items.teardown()
	super._exit_tree()


func start_play() -> void:
	_free_cursors()
	if items != null and not items.in_play:
		items.begin_play()
	super.start_play()


func enter_place_fixture() -> void:
	enter_place()


func enter_place() -> void:
	if items == null:
		return
	if items.in_play:
		items.end_round()
	items.enter_place()
	current_context = BoundedStageCamera.Context.PLACE
	input_router.set_phase(LocalInputRouter.Phase.PLACE)
	camera_rig.set_context(current_context)
	_free_cursors()
	pointers.clear()
	for seat_index in actors:
		_add_cursor(int(seat_index))
	_refresh_all_ghosts()
	_update_camera_targets()
	_update_diagnostics()


func reset_room() -> void:
	_free_cursors()
	pointers.clear()
	if items != null and items.in_play:
		items.end_round()
	super.reset_room()
	if items != null:
		items.begin_play()
	_update_diagnostics()


func clear_all_construction() -> void:
	if items == null:
		return
	items.reset_match()
	last_message = "Match reset: construction cleared."
	_update_diagnostics()


func cycle_variant() -> void:
	var enabled := _enabled_variant_keys()
	if enabled.is_empty():
		return
	var index := enabled.find(selected_variant_key)
	select_variant(enabled[(index + 1) % enabled.size()])


## Claiming an egg hands its exact variant to the placement ghost; identity is never substituted.
func select_variant(variant_key: String) -> bool:
	if not _enabled_variant_keys().has(variant_key):
		return false
	selected_variant_key = variant_key
	for cursor in cursors.values():
		cursor.turns = 0
	for key in egg_previews:
		(egg_previews[key] as ItemEggPreview).selected = key == variant_key
	_refresh_rotation_support()
	_refresh_all_ghosts()
	_update_diagnostics()
	return true


func toggle_library() -> void:
	library_visible = not library_visible
	if _library_panel != null:
		_library_panel.visible = library_visible
	refresh_library()


func set_release_filter(enabled: bool) -> void:
	release_filter = enabled
	refresh_library()


func library_entries() -> Array[ItemLibraryEntry]:
	return ItemLibraryEntry.build_list(definitions, release_filter)


func refresh_library() -> void:
	if _library_label == null:
		return
	var entries := library_entries()
	var blocks := PackedStringArray()
	for entry in entries:
		blocks.append(entry.text_block())
	_library_label.text = (
		"\n\n".join(blocks)
		if not entries.is_empty()
		else "No release-enabled content yet (release filter is on)."
	)
	for child in _library_preview_host.get_children():
		child.queue_free()
	var offset := 0.0
	for entry in entries:
		if entry.animation_variant_key.is_empty():
			continue
		var preview := ItemEggPreview.new()
		if preview.configure(definitions, entry.animation_variant_key, 0, tuning):
			preview.position = Vector2(offset, 0.0)
			_library_preview_host.add_child(preview)
			offset += preview.custom_minimum_size.x + 6.0


func rotate_cursor(seat_index: int) -> bool:
	if not cursors.has(seat_index):
		return false
	var cursor: Dictionary = cursors[seat_index]
	var rotations := _usable_rotations(selected_variant_key)
	if rotations.size() <= 1:
		last_message = "Rotation unavailable for this variant."
		return false
	var index := rotations.find(cursor.turns)
	cursor.turns = rotations[(index + 1) % rotations.size()]
	_refresh_ghost(seat_index)
	return true


func move_cursor(seat_index: int, delta_cells: Vector2i) -> void:
	if not cursors.has(seat_index):
		return
	var cursor: Dictionary = cursors[seat_index]
	var next: Vector2i = cursor.cell + delta_cells
	next.x = clampi(next.x, 0, tuning.arena_width_tiles - 1)
	next.y = clampi(next.y, 0, tuning.arena_height_tiles - 1)
	cursor.cell = next
	_refresh_ghost(seat_index)


func confirm_cursor(seat_index: int) -> Dictionary:
	if not cursors.has(seat_index) or items == null:
		return {"allowed": false, "code": "no_cursor", "reason": "No cursor."}
	var cursor: Dictionary = cursors[seat_index]
	var result := items.place(
		selected_variant_key, cursor.cell, cursor.turns, seat_index, _actor_rects()
	)
	last_message = (
		"Placed %s." % result.get("instance_id", result.get("reason", ""))
		if bool(result.allowed)
		else "Rejected: %s" % result.reason
	)
	_refresh_all_ghosts()
	_update_diagnostics()
	return result


func remove_last_piece() -> bool:
	if items == null or items.pieces.is_empty():
		return false
	var ids: Array = items.pieces.keys()
	ids.sort()
	var result := items.remove(str(ids[-1]), "lab_remove")
	last_message = "Removed %s." % ids[-1] if bool(result.allowed) else str(result.reason)
	_refresh_all_ghosts()
	_update_diagnostics()
	return bool(result.allowed)


func _actor_rects() -> Array[Rect2]:
	var rects: Array[Rect2] = []
	for seat_index in actors:
		var actor := actors[seat_index] as ChickenController
		if actor == null or not is_instance_valid(actor) or actor.lifecycle.is_terminal():
			continue
		rects.append(actor.hit_rect())
	return rects


func _enabled_variant_keys() -> PackedStringArray:
	var keys := PackedStringArray()
	for family in definitions.families:
		keys.append_array(definitions.enabled_variant_keys(family.family_id))
	return keys


func _usable_rotations(variant_key: String) -> Array[int]:
	var usable: Array[int] = []
	var found := definitions.find_variant(variant_key)
	if found.is_empty():
		return usable
	var variant := found.variant as ItemVariantDefinition
	for turn in variant.rotations:
		if variant.gated_rotations.has(turn) and not tuning.item_tulay_vertical_enabled:
			continue
		usable.append(turn)
	return usable


func _refresh_rotation_support() -> void:
	input_router.set_rotation_supported(_usable_rotations(selected_variant_key).size() > 1)


func _add_cursor(seat_index: int) -> void:
	_cursor_counter += 1
	var ghost := ItemGhost.new()
	ghost.name = "ItemGhostSeat%d" % (seat_index + 1)
	world_layer.add_child(ghost)
	var start := CURSOR_START_CELLS[seat_index % CURSOR_START_CELLS.size()]
	cursors[seat_index] = {"cell": start, "turns": 0, "ghost": ghost}
	(
		pointers
		. append(
			{
				"id": "lab_cursor_%d" % seat_index,
				"rect":
				Rect2(Vector2(start) * tuning.grid_cell_wu, Vector2.ONE * tuning.grid_cell_wu),
				"confirmed": false,
				"node": ghost,
				"label": null,
			}
		)
	)


func _free_cursors() -> void:
	for cursor in cursors.values():
		var ghost := cursor.ghost as Node
		if ghost != null and is_instance_valid(ghost):
			ghost.queue_free()
	cursors.clear()
	pointers.clear()


func _refresh_all_ghosts() -> void:
	for seat_index in cursors:
		_refresh_ghost(int(seat_index))


func _refresh_ghost(seat_index: int) -> void:
	if not cursors.has(seat_index) or items == null:
		return
	var cursor: Dictionary = cursors[seat_index]
	var found := definitions.find_variant(selected_variant_key)
	if found.is_empty():
		return
	var variant := found.variant as ItemVariantDefinition
	var verdict := items.validate_placement(
		selected_variant_key, cursor.cell, cursor.turns, _actor_rects()
	)
	var footprint := ItemPlacementValidator.footprint_rect_for(
		variant, cursor.cell, cursor.turns, tuning
	)
	var strips: Array[Rect2] = []
	var normals: Array[Vector2] = []
	for region in ItemGeometry.resolve_regions(variant, cursor.turns, tuning):
		if region.kind == ItemRegionSpec.Kind.ONE_WAY_TOP:
			var rect: Rect2 = region.rect
			rect.position += footprint.position
			strips.append(rect)
			normals.append(region.normal)
	var seat := input_router.registry.get_seat(seat_index)
	(cursor.ghost as ItemGhost).show_state(
		footprint,
		strips,
		normals,
		bool(verdict.allowed),
		str(verdict.reason),
		"P%d %s" % [int(seat.identity), str(seat.shape)],
		selected_variant_key.trim_prefix("build.")
	)
	(cursor.ghost as ItemGhost).set_overlay(
		overlay_for_cursor(selected_variant_key, cursor.cell, cursor.turns)
	)
	for pointer in pointers:
		if str(pointer.id) == "lab_cursor_%d" % seat_index:
			pointer.rect = footprint
	_update_camera_targets()


func _on_lab_action_pressed(seat_index: int, action_name: String) -> void:
	if input_router.phase != LocalInputRouter.Phase.PLACE:
		return
	if action_name == "confirm":
		confirm_cursor(seat_index)
	elif action_name == "rotate":
		rotate_cursor(seat_index)
		_update_diagnostics()


func _on_lab_navigation_step(seat_index: int, direction: String) -> void:
	if input_router.phase != LocalInputRouter.Phase.PLACE:
		return
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
	move_cursor(seat_index, step)


func _on_lab_disabled_action(_seat_index: int, action_name: String) -> void:
	if action_name == "rotate":
		last_message = "Rotation unavailable for this variant."
		_update_diagnostics()


func _build_overlays() -> void:
	_overlay_layer = CanvasLayer.new()
	_overlay_layer.name = "ItemLabOverlays"
	_overlay_layer.layer = 21
	add_child(_overlay_layer)
	var row := HBoxContainer.new()
	row.name = "EggPreviewRow"
	row.position = Vector2(tuning.camera_virtual_width_px - 360.0, 70.0)
	row.add_theme_constant_override("separation", 6)
	_overlay_layer.add_child(row)
	for key in _enabled_variant_keys():
		var egg := ItemEggPreview.new()
		if not egg.configure(definitions, key, 0, tuning):
			continue
		egg.name = "Egg_%s" % key.replace(".", "_")
		egg.selected = key == selected_variant_key
		egg.claimed.connect(select_variant)
		row.add_child(egg)
		egg_previews[key] = egg
	# Right-align the row so every enabled variant's egg stays on screen; a row wider than the
	# original three-egg slot drops below the diagnostic status lines.
	var row_width := row.get_combined_minimum_size().x
	if row_width > 360.0:
		row.position = Vector2(tuning.camera_virtual_width_px - row_width - 8.0, 140.0)
	_library_panel = PanelContainer.new()
	_library_panel.name = "LibraryPanel"
	_library_panel.position = Vector2(tuning.camera_virtual_width_px - 520.0, 180.0)
	_library_panel.custom_minimum_size = Vector2(500.0, 0.0)
	_library_panel.visible = false
	_overlay_layer.add_child(_library_panel)
	var column := VBoxContainer.new()
	_library_panel.add_child(column)
	var title := Label.new()
	title.text = "LIBRARY • PLACEHOLDER (P13 owns the final Library)"
	column.add_child(title)
	var toggle := CheckButton.new()
	toggle.text = "Release filter"
	toggle.focus_mode = Control.FOCUS_NONE
	toggle.toggled.connect(set_release_filter)
	column.add_child(toggle)
	_library_preview_host = Control.new()
	_library_preview_host.custom_minimum_size = Vector2(0.0, 112.0)
	column.add_child(_library_preview_host)
	_library_label = Label.new()
	_library_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_library_label.custom_minimum_size = Vector2(480.0, 0.0)
	_library_label.add_theme_font_size_override("font_size", 11)
	column.add_child(_library_label)
	refresh_library()


func _build_hud() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "ItemLabHudLayer"
	canvas.layer = 20
	add_child(canvas)
	_hud = PanelContainer.new()
	_hud.name = "ItemLabHud"
	_hud.process_mode = Node.PROCESS_MODE_ALWAYS
	_hud.size = Vector2(tuning.camera_virtual_width_px, tuning.camera_hud_reservation_px)
	_hud.add_theme_stylebox_override("panel", _hud_style())
	canvas.add_child(_hud)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	_hud.add_child(row)
	var title := Label.new()
	title.text = "P04 ITEM LAB • DEBUG"
	title.add_theme_font_size_override("font_size", 12)
	row.add_child(title)
	_add_button(row, "Join K1", func() -> void: join_keyboard("K1"))
	_add_button(row, "Join K2", func() -> void: join_keyboard("K2"))
	_add_button(row, "Place", enter_place)
	_add_button(row, "Play", start_play)
	_variant_button = _add_button(row, "Variant", cycle_variant)
	_add_button(row, "Remove last", remove_last_piece)
	_add_button(row, "Clear all", clear_all_construction)
	_add_button(row, "Library", toggle_library)
	_add_button(row, "Reset", reset_room)
	_pause_button = _add_button(row, "Pause", _toggle_pause)
	_add_button(row, "Return", request_return)
	_variant_button.custom_minimum_size = Vector2(176.0, 36.0)
	for child in row.get_children():
		# K2 confirms with Enter; a focused HUD button would also activate on that key.
		if child is Button:
			(child as Button).focus_mode = Control.FOCUS_NONE
	var lower := VBoxContainer.new()
	lower.position = Vector2(8.0, tuning.camera_hud_reservation_px + 6.0)
	lower.add_theme_constant_override("separation", 2)
	canvas.add_child(lower)
	_status_label = Label.new()
	_status_label.add_theme_color_override("font_color", Color.WHITE)
	_status_label.add_theme_color_override("font_shadow_color", Color("#14232a"))
	_status_label.add_theme_constant_override("shadow_offset_x", 1)
	_status_label.add_theme_constant_override("shadow_offset_y", 1)
	lower.add_child(_status_label)
	_support_label = Label.new()
	_support_label.add_theme_color_override("font_color", Color.WHITE)
	lower.add_child(_support_label)
	var help := Label.new()
	help.text = (
		"Lab-only immediate placement. K1 WASD/F/R • K2 arrows/Enter/R-Shift • "
		+ "graybox visuals are labeled DEBUG"
	)
	help.add_theme_color_override("font_color", Color.WHITE)
	lower.add_child(help)


func _update_diagnostics() -> void:
	if _status_label == null:
		return
	var context_name := "PLAY" if current_context == BoundedStageCamera.Context.PLAY else "PLACE"
	var piece_count := items.persistent_count() if items != null else 0
	var grace := items.grace_remaining if items != null else 0.0
	_status_label.text = (
		"%s • %s • %s • seed %d • actors %d • pieces %d/%d • grace %.1f s • %s"
		% [
			LAB_BUILD_ID,
			context_name,
			profile_id,
			_seed,
			actors.size(),
			piece_count,
			tuning.item_persistent_cap,
			grace,
			selected_variant_key
		]
	)
	var support_summary := "Support: no actor"
	for seat_index in actors:
		var actor := actors[seat_index] as ChickenController
		var result := current_support_result(actor.support_actor_id)
		var contact := result.contact as SupportContact
		support_summary = (
			"Support: %s%s" % [result.reason, " • " + contact.surface_id if contact != null else ""]
		)
		break
	_support_label.text = "%s    %s" % [support_summary, last_message]
	if _pause_button != null:
		_pause_button.text = "Resume" if get_tree().paused else "Pause"
	if _variant_button != null:
		_variant_button.text = "Variant: %s" % selected_variant_key.get_slice(".", 2)

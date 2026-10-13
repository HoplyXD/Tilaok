class_name ItemVisualizerRoom
extends ItemLabRoom

## Item Visualizer (P10). Reuses the Item Lab arena, cursors, ghosts and immediate lab placement
## so anyone can see, place and run every first-batch family, variant and rotation with its
## regions and live state. All presentation is PLACEHOLDER and swappable through ItemVisualSet.
## Lab placement here is immediate and is NOT the P05 atomic Place resolver.

const VISUALIZER_BUILD_ID := "P10-item-visualizer-dev"
const VISUALIZER_PROFILE_ID := "items_lab"
const SPEEDS: Array[float] = [1.0, 0.25, 0.1]
const READOUT_EVERY_N_FRAMES := 6
const SYNTHETIC_PAD_IDS: Array[int] = [900, 901]

var overlays_enabled := true
var owner_tags_enabled := true
var speed_index := 0
var family_index := 0
var placed_overlay: ItemGhost
var readout_text := ""
var _readout_label: Label
var _swap_label: Label
var _panel_layer: CanvasLayer
var _single_step_pending := false
var _overlay_dirty := true
var _readout_ticks := 0


func _init() -> void:
	profile_id = VISUALIZER_PROFILE_ID


func _ready() -> void:
	super._ready()
	if items == null or definitions == null or not definitions.is_valid():
		return
	items.item_placed.connect(_mark_overlay_dirty)
	items.item_removed.connect(_mark_overlay_dirty)
	placed_overlay = ItemGhost.new()
	placed_overlay.name = "PlacedRegionOverlay"
	placed_overlay.z_index = 30
	world_layer.add_child(placed_overlay)
	_build_visualizer_panel()
	_update_readout()
	print(
		(
			"P10_ITEM_VISUALIZER_READY build=%s families=%d variants=%d profile=%s"
			% [
				VISUALIZER_BUILD_ID,
				definitions.families.size(),
				_enabled_variant_keys().size(),
				profile_id
			]
		)
	)


func _process(delta: float) -> void:
	super._process(delta)
	if placed_overlay != null and is_instance_valid(placed_overlay):
		_refresh_placed_overlay()
	_update_readout()


# ------------------------------------------------------------------ pickers


func family_ids() -> PackedStringArray:
	var ids := PackedStringArray()
	for family in definitions.families:
		ids.append(family.family_id)
	return ids


func selected_family_id() -> String:
	var found := definitions.find_variant(selected_variant_key)
	return str((found.family as ItemFamilyDefinition).family_id) if not found.is_empty() else ""


func select_family(family_id: String) -> bool:
	var keys := definitions.enabled_variant_keys(family_id)
	if keys.is_empty():
		return false
	family_index = family_ids().find(family_id)
	return select_variant(keys[0])


func cycle_family() -> void:
	var ids := family_ids()
	if ids.is_empty():
		return
	family_index = (family_ids().find(selected_family_id()) + 1) % ids.size()
	select_family(ids[family_index])


func cycle_variant_in_family() -> void:
	var keys := definitions.enabled_variant_keys(selected_family_id())
	if keys.is_empty():
		return
	var index := keys.find(selected_variant_key)
	select_variant(keys[(index + 1) % keys.size()])


func rotate_selected() -> bool:
	var rotated := false
	for seat_index in cursors:
		rotated = rotate_cursor(int(seat_index)) or rotated
	return rotated


## Places the selected variant at the first cursor (immediate, lab-only).
func place_at_cursor() -> Dictionary:
	if cursors.is_empty():
		return {"allowed": false, "code": "no_cursor", "reason": "Enter Place first."}
	var seats: Array = cursors.keys()
	seats.sort()
	return confirm_cursor(int(seats[0]))


## Places a variant at an explicit cell without moving a cursor (used by scenario scripts).
func place_variant(
	variant_key: String, cell: Vector2i, turns: int = 0, seat_index: int = 0
) -> Dictionary:
	if items == null or not _enabled_variant_keys().has(variant_key):
		return {"allowed": false, "code": "variant_disabled", "reason": "Variant is not enabled."}
	if cursors.is_empty():
		enter_place()
	var result := items.place(variant_key, cell, turns, seat_index, _actor_rects())
	last_message = (
		"Placed %s." % result.get("instance_id", result.get("code", ""))
		if bool(result.allowed)
		else "Rejected: %s" % result.reason
	)
	_refresh_all_ghosts()
	_update_diagnostics()
	return result


# ------------------------------------------------------------------ run controls


func _mark_overlay_dirty(_instance_id: String, _reason: String = "") -> void:
	_overlay_dirty = true


func toggle_overlays() -> void:
	overlays_enabled = not overlays_enabled
	_overlay_dirty = true
	if placed_overlay != null:
		placed_overlay.set_overlay([] as Array[Dictionary])


func toggle_owner_tags() -> void:
	owner_tags_enabled = not owner_tags_enabled
	for piece_variant in _hazard_pieces():
		(piece_variant as HazardPiece).show_owner_tag = owner_tags_enabled


func cycle_speed() -> void:
	speed_index = (speed_index + 1) % SPEEDS.size()
	Engine.time_scale = SPEEDS[speed_index]


func reset_speed() -> void:
	speed_index = 0
	Engine.time_scale = 1.0


## Runs exactly one physics step while paused, then pauses again.
func single_step() -> void:
	if _single_step_pending:
		return
	_single_step_pending = true
	var was_paused := get_tree().paused
	get_tree().paused = false
	await get_tree().physics_frame
	get_tree().paused = true if was_paused else get_tree().paused
	_single_step_pending = false


## Spawns the next test chicken: K1, K2, then two synthetic gamepad seats.
func spawn_test_chicken() -> int:
	if actors.size() >= 4:
		return -1
	var seat := -1
	if input_router.registry.seat_for_keyboard("K1") < 0:
		seat = join_keyboard("K1")
	elif input_router.registry.seat_for_keyboard("K2") < 0:
		seat = join_keyboard("K2")
	else:
		for device_id in SYNTHETIC_PAD_IDS:
			if input_router.registry.seat_for_gamepad(device_id) < 0:
				seat = input_router.registry.join_gamepad(device_id)
				if seat >= 0:
					input_router.seat_joined.emit(seat)
				break
	return seat


## Hides the HUD, egg row and Visualizer panel so the stage can be captured or previewed clean.
func set_chrome_visible(value: bool) -> void:
	if _hud != null and _hud.get_parent() is CanvasLayer:
		(_hud.get_parent() as CanvasLayer).visible = value
	if _overlay_layer != null:
		_overlay_layer.visible = value
	if _panel_layer != null:
		_panel_layer.visible = value


func toggle_slot_list() -> void:
	if _swap_label != null:
		_swap_label.visible = not _swap_label.visible


func reset_visualizer() -> void:
	reset_speed()
	reset_room()


# ------------------------------------------------------------------ art swap


## Re-reads every placeholder slot from disk so an artist sees a replaced file immediately.
func reload_visual_sets() -> int:
	var reloaded := 0
	for family in definitions.families:
		if family.visual_set == null:
			continue
		for slot in family.visual_set.slots:
			var fresh: Array[Texture2D] = []
			for frame in slot.frames:
				if frame != null and not frame.resource_path.is_empty():
					var again := (
						ResourceLoader.load(
							frame.resource_path, "", ResourceLoader.CACHE_MODE_REPLACE
						)
						as Texture2D
					)
					fresh.append(again if again != null else frame)
					reloaded += 1
			slot.frames = fresh
			if slot.sound != null and not slot.sound.resource_path.is_empty():
				var stream := (
					ResourceLoader.load(
						slot.sound.resource_path, "", ResourceLoader.CACHE_MODE_REPLACE
					)
					as AudioStream
				)
				if stream != null:
					slot.sound = stream
					reloaded += 1
	for piece in _hazard_pieces():
		piece.queue_redraw()
	return reloaded


func slot_report() -> PackedStringArray:
	var rows := PackedStringArray()
	for family in definitions.families:
		if family.visual_set == null:
			continue
		for slot in family.visual_set.slots:
			var path := ""
			if not slot.frames.is_empty() and slot.frames[0] != null:
				path = slot.frames[0].resource_path
			elif slot.sound != null:
				path = slot.sound.resource_path
			rows.append(
				(
					"%s • %s • %s • %s • owner %s"
					% [
						family.family_id,
						slot.slot_id,
						"PLACEHOLDER" if slot.placeholder else "FINAL",
						path.get_file(),
						slot.final_owner
					]
				)
			)
	return rows


# ------------------------------------------------------------------ readouts


func piece_readouts() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var ids: Array = items.pieces.keys()
	ids.sort()
	for instance_id in ids:
		var record := items.pieces[instance_id] as PlacedItem
		var piece := record.node as HazardPiece
		var state := "static"
		var detail := {}
		if piece != null and piece.behavior != null:
			detail = piece.behavior.readout()
			state = str(detail.get("state", "?"))
		(
			rows
			. append(
				{
					"id": str(instance_id),
					"owner": record.owner_seat,
					"state": state,
					"turns": record.quarter_turns,
					"detail": detail,
				}
			)
		)
	return rows


func _hazard_pieces() -> Array[HazardPiece]:
	var result: Array[HazardPiece] = []
	if items == null:
		return result
	for record_variant in items.pieces.values():
		var piece := (record_variant as PlacedItem).node as HazardPiece
		if piece != null:
			result.append(piece)
	return result


func _refresh_placed_overlay() -> void:
	if not overlays_enabled:
		if _overlay_dirty:
			placed_overlay.set_overlay([] as Array[Dictionary])
			_overlay_dirty = false
		return
	if not _overlay_dirty:
		return
	_overlay_dirty = false
	var combined: Array[Dictionary] = []
	var records := items.pieces.values()
	for record_variant in records:
		var record := record_variant as PlacedItem
		var found := definitions.find_variant(record.variant_key)
		if found.is_empty() or (found.family as ItemFamilyDefinition).visual_set == null:
			continue
		combined.append_array(
			ItemOverlayBuilder.build(
				found.family,
				found.variant,
				record.origin_cell,
				record.quarter_turns,
				tuning,
				arena,
				records,
				items.round_number + 1
			)
		)
	placed_overlay.set_overlay(combined)


func _update_readout() -> void:
	if items == null:
		return
	_readout_ticks += 1
	if _readout_ticks % READOUT_EVERY_N_FRAMES != 0:
		return
	var rows := PackedStringArray()
	rows.append(
		(
			"%s • %s • speed %.2fx • items %d • records %d"
			% [
				VISUALIZER_BUILD_ID,
				"PLAY" if items.in_play else "PLACE",
				Engine.time_scale,
				items.persistent_count(),
				items.director.records.size() if items.director != null else 0
			]
		)
	)
	for row in piece_readouts():
		rows.append("%s  P%d  %s" % [row.id, int(row.owner) + 1, row.state])
	readout_text = "\n".join(rows)
	if _readout_label != null:
		_readout_label.text = readout_text


func _build_visualizer_panel() -> void:
	_panel_layer = CanvasLayer.new()
	_panel_layer.name = "VisualizerPanel"
	_panel_layer.layer = 22
	add_child(_panel_layer)
	var column := VBoxContainer.new()
	column.position = Vector2(8.0, tuning.camera_hud_reservation_px + 124.0)
	column.add_theme_constant_override("separation", 3)
	_panel_layer.add_child(column)
	var title := Label.new()
	title.text = "ITEM VISUALIZER • PLACEHOLDER ART/AUDIO"
	title.add_theme_color_override("font_color", Color.WHITE)
	column.add_child(title)
	var row_one := HBoxContainer.new()
	var row_two := HBoxContainer.new()
	column.add_child(row_one)
	column.add_child(row_two)
	_viz_button(row_one, "Family", cycle_family)
	_viz_button(row_one, "Size", cycle_variant_in_family)
	_viz_button(row_one, "Rotate", rotate_selected)
	_viz_button(row_one, "Put here", place_at_cursor)
	_viz_button(row_one, "Overlays", toggle_overlays)
	_viz_button(row_one, "Owner tags", toggle_owner_tags)
	_viz_button(row_two, "Speed", cycle_speed)
	_viz_button(row_two, "Step", single_step)
	_viz_button(row_two, "+Chicken", spawn_test_chicken)
	_viz_button(row_two, "Reload art", reload_visual_sets)
	_viz_button(row_two, "Reset all", reset_visualizer)
	_viz_button(row_two, "Art slots", toggle_slot_list)
	_readout_label = Label.new()
	_readout_label.add_theme_color_override("font_color", Color.WHITE)
	_readout_label.add_theme_font_size_override("font_size", 11)
	column.add_child(_readout_label)
	_swap_label = Label.new()
	_swap_label.add_theme_font_size_override("font_size", 9)
	_swap_label.add_theme_color_override("font_color", Color("#cfe8a0"))
	_swap_label.text = (
		"Replace assets/items/<family>/PLACEHOLDER_* then Reload art.\n" + "\n".join(slot_report())
	)
	_swap_label.visible = false
	column.add_child(_swap_label)


func _viz_button(parent: Control, text_value: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text_value
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(84.0, 28.0)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _exit_tree() -> void:
	Engine.time_scale = 1.0
	super._exit_tree()

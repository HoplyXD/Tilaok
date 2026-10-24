extends SceneTree

## Windowed in-game P24 showcase. Uses real item pieces and a real captured ChickenController.

const ROOM_SCENE := preload("res://scenes/fixtures/item_visualizer.tscn")
const OUTPUT := "../docs/evidence/p24_item_art"
const VIEW_SIZE := Vector2i(1920, 1080)
const CELL := 64.0

var room: ItemVisualizerRoom
var actor: ChickenController
var parol: HazardPiece
var state_label: Label
var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var output_dir := ProjectSettings.globalize_path("res://").path_join(OUTPUT).simplify_path()
	DirAccess.make_dir_recursive_absolute(output_dir)
	root.size = VIEW_SIZE
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(VIEW_SIZE)
	room = ROOM_SCENE.instantiate() as ItemVisualizerRoom
	root.add_child(room)
	await _frames(4)
	var seat := room.join_keyboard("K1")
	if seat < 0:
		_fail("could not join the showcase chicken")
		quit(1)
		return
	actor = room.actors[seat] as ChickenController
	room.set_chrome_visible(false)
	room.toggle_owner_tags()
	room.tuning.item_bubble_cadence_s = 0.2
	var trumpo_result := room.items.place(
		"hazard.rail_trumpo.rail_5x1", Vector2i(7, 8), 0, seat, [] as Array[Rect2]
	)
	var parol_result := room.items.place(
		"hazard.parol_pulse.span_5x1", Vector2i(19, 9), 0, seat, [] as Array[Rect2]
	)
	var bula_result := room.items.place(
		"hazard.bubble_planter.path_1x5", Vector2i(16, 13), 0, seat, [] as Array[Rect2]
	)
	if (
		not bool(trumpo_result.allowed)
		or not bool(parol_result.allowed)
		or not bool(bula_result.allowed)
	):
		_fail(
			(
				"one or more item placements failed: %s %s %s"
				% [trumpo_result, parol_result, bula_result]
			)
		)
		quit(1)
		return
	parol = room.items.piece_for(str(parol_result.instance_id)) as HazardPiece
	room.toggle_overlays()
	for node in room.get_tree().get_nodes_in_group("debug_world"):
		if node is CanvasItem:
			(node as CanvasItem).visible = false
	room.start_play()
	await _physics_frames(62)
	var capture_point := Vector2(16.0 * CELL + CELL * 0.5, 13.0 * CELL - 14.0 * 2.0)
	var captured := false
	for _frame in range(420):
		actor.global_position = capture_point
		actor.clear_external_motion()
		await physics_frame
		if actor.lifecycle.status == PlayerLifecycleState.Status.CAPTURED:
			captured = true
			break
	if not captured:
		_fail("live bubble did not capture the chicken within 420 physics frames")
		quit(1)
		return
	Engine.time_scale = 0.0
	room.camera_rig.position = actor.global_position
	room.camera_rig.set_process(false)
	room.camera_rig.set_physics_process(false)
	_add_caption()
	var parol_behavior := parol.behavior as ParolBehavior
	parol_behavior.preview_at(1.8)
	room.camera_rig.zoom = Vector2.ONE * 1.15
	await _capture_placeholder_baseline(output_dir)
	room.camera_rig.zoom = Vector2.ONE * 1.7
	_set_state_label("CAPTURE CLOSE-UP")
	await _frames(3)
	await RenderingServer.frame_post_draw
	var closeup_result := root.get_texture().get_image().save_png(
		output_dir.path_join("p24_in_game_bula_capture_closeup.png")
	)
	if closeup_result != OK:
		_fail("Bula close-up capture save failed (error %d)" % closeup_result)
	room.camera_rig.zoom = Vector2.ONE * 1.15
	var views := [
		{"name": "p24_in_game_inactive.png", "time": 0.2, "state": "PAROL: INACTIVE"},
		{"name": "p24_in_game_charge.png", "time": 1.2, "state": "PAROL: CHARGE"},
		{"name": "p24_in_game_active.png", "time": 1.8, "state": "PAROL: ACTIVE"},
	]
	for view in views:
		parol_behavior.preview_at(float(view.time))
		parol.queue_redraw()
		_set_state_label(str(view.state))
		await _frames(3)
		await RenderingServer.frame_post_draw
		var result := root.get_texture().get_image().save_png(output_dir.path_join(str(view.name)))
		if result != OK:
			_fail("capture save failed for %s (error %d)" % [view.name, result])
	await _save_manifest(output_dir)
	print(
		(
			"P24_IN_GAME_CAPTURE failures=%d captured_chicken=%s output=%s"
			% [failures, captured, output_dir]
		)
	)
	quit(1 if failures > 0 else 0)


func _add_caption() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 80
	root.add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(28, 24)
	panel.custom_minimum_size = Vector2(740, 64)
	layer.add_child(panel)
	var text := VBoxContainer.new()
	panel.add_child(text)
	var title := Label.new()
	title.text = "TILAOK!  •  ITEM ART IN GAME"
	title.add_theme_font_size_override("font_size", 24)
	text.add_child(title)
	state_label = Label.new()
	state_label.text = "BULA-BULAKLAK: LIVE CHICKEN CAPTURE  •  TRUMPO SA RILES: LIVE"
	state_label.add_theme_font_size_override("font_size", 16)
	text.add_child(state_label)


func _set_state_label(value: String) -> void:
	if state_label != null:
		state_label.text = "BULA: CHICKEN CAPTURED  •  TRUMPO: LIVE  •  %s" % value


func _capture_placeholder_baseline(output_dir: String) -> void:
	var slot_ids := {
		"hazard.bubble_planter": ["pot", "bubble", "captive_icon"],
		"hazard.rail_trumpo": ["rail_end", "rail_mid", "top"],
		"hazard.parol_pulse":
		["post_inactive", "post_charge", "post_active", "beam_charge", "beam_active"],
	}
	var saved: Array[Dictionary] = []
	for piece in room.items.pieces.values():
		var hazard := (piece as PlacedItem).node as HazardPiece
		var family_id := hazard.family.family_id
		if not slot_ids.has(family_id):
			continue
		for slot_id in slot_ids[family_id]:
			var slot := hazard.family.visual_set.get_slot(str(slot_id))
			if slot == null:
				continue
			saved.append({"slot": slot, "frames": slot.frames.duplicate()})
			slot.frames.clear()
			hazard.queue_redraw()
	_set_state_label("BEFORE: PLACEHOLDER FALLBACKS  •  PAROL ACTIVE")
	await _frames(3)
	await RenderingServer.frame_post_draw
	var save_result := root.get_texture().get_image().save_png(
		output_dir.path_join("p24_in_game_before_placeholders.png")
	)
	if save_result != OK:
		_fail("placeholder baseline capture save failed (error %d)" % save_result)
	for record in saved:
		var slot := record.slot as ItemVisualSlot
		slot.frames = record.frames
	for piece in room.items.pieces.values():
		((piece as PlacedItem).node as HazardPiece).queue_redraw()
	_set_state_label("PAROL: ACTIVE")


func _save_manifest(output_dir: String) -> void:
	var file := FileAccess.open(
		output_dir.path_join("in_game_capture_manifest.md"), FileAccess.WRITE
	)
	if file == null:
		_fail("could not write capture manifest")
		return
	var body: String = (
		"# P24 in-game capture\n\nGodot "
		+ Engine.get_version_info().string
		+ "; 1920×1080; Item Visualizer stage; real Bula bubble captured the live ChickenController. "
		+ "Trumpo is live. A matched baseline uses the painter's code-drawn placeholder fallbacks "
		+ "in the same frozen scene; after images use the imported art. Parol is sampled at inactive, "
		+ "charge, and active preview times while physics is frozen for the stills.\n"
	)
	file.store_string(body)
	file.close()


func _physics_frames(count: int) -> void:
	for _frame in range(count):
		await physics_frame


func _frames(count: int) -> void:
	for _frame in range(count):
		await process_frame


func _fail(message: String) -> void:
	failures += 1
	push_error("P24 capture: " + message)

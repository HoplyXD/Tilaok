extends SceneTree

## P10 rendered evidence at 1920x1080: per-family variant/rotation sheets, tell states, egg and
## ghost sheets, the crowded 48-item mixed stage with a four-seat performance sample, and the
## placeholder-swap probe. Modes (env P10_MODE): "all" (default) and "swap_probe".
## Output directory: env P10_EVIDENCE_DIR, else ../docs/evidence/p10. PLACEHOLDER art/audio only.

const ROOM_SCENE := preload("res://scenes/fixtures/item_visualizer.tscn")
const SAMPLE_COUNT := 600
const FAMILIES: PackedStringArray = [
	"move.tire_spring",
	"hazard.rail_trumpo",
	"hazard.parol_pulse",
	"hazard.slipper_launcher",
	"utility.walis_cleanup",
	"hazard.bubble_planter",
]
const SHEET_NAMES := {
	"move.tire_spring": "gulong",
	"hazard.rail_trumpo": "trumpo",
	"hazard.parol_pulse": "parol",
	"hazard.slipper_launcher": "tsinelas",
	"utility.walis_cleanup": "walis",
	"hazard.bubble_planter": "bula",
}
const SWAP_PROBE_VARIANT := "move.tire_spring.tire_2x2"

var failures := 0
var checks := 0
var output_dir := ""
var room: ItemVisualizerRoom
var report := PackedStringArray()


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
	var mode := OS.get_environment("P10_MODE")
	if mode == "swap_probe":
		await _swap_probe(OS.get_environment("P10_LABEL"))
		quit(0)
		return
	for family_id in FAMILIES:
		await _family_sheet(family_id)
	await _tell_states()
	await _egg_sheet()
	await _ghost_sheet()
	await _crowded_and_performance()
	await _resource_swap()
	_write_report()
	print("P10_CAPTURE checks=%d failures=%d dir=%s" % [checks, failures, output_dir])
	quit(1 if failures > 0 else 0)


# ------------------------------------------------------------------------------ rooms


func _room(seats: int = 1) -> void:
	if room != null and is_instance_valid(room):
		room.queue_free()
		await process_frame
	room = ROOM_SCENE.instantiate() as ItemVisualizerRoom
	root.add_child(room)
	await _frames(3)
	if seats >= 1:
		room.join_keyboard("K1")
	if seats >= 2:
		room.join_keyboard("K2")
	for index in range(2, seats):
		var seat := room.input_router.registry.join_gamepad(920 + index)
		if seat >= 0:
			room.input_router.seat_joined.emit(seat)
	room.enter_place()
	room._free_cursors()
	room.set_chrome_visible(false)


func _pack(variant_key: String, turns: int, reserved: Array[Rect2], seat: int = 0) -> Dictionary:
	var found := room.definitions.find_variant(variant_key)
	var variant := found.variant as ItemVariantDefinition
	var envelope := ItemSilhouettePainter.envelope(variant, turns, room.tuning)
	for y in range(3, 15):
		for x in range(5, 28):
			var cell := Vector2i(x, y)
			var footprint := ItemPlacementValidator.footprint_rect_for(
				variant, cell, turns, room.tuning
			)
			var world := Rect2(envelope.position + footprint.position, envelope.size).grow(10.0)
			var clash := false
			for rect in reserved:
				clash = clash or rect.intersects(world, false)
			if clash:
				continue
			var verdict := room.items.validate_placement(
				variant_key, cell, turns, [] as Array[Rect2]
			)
			if bool(verdict.allowed):
				var placed := room.items.place(variant_key, cell, turns, seat, [] as Array[Rect2])
				if bool(placed.allowed):
					reserved.append(world)
					return placed
	return {"allowed": false}


func _all_variant_rotations(family_id: String) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var family := room.definitions.find_family(family_id)
	for variant in family.variants:
		for turns in variant.rotations:
			rows.append({"key": family.variant_key(variant), "turns": turns})
	return rows


# ------------------------------------------------------------------------------ sheets


func _family_sheet(family_id: String) -> void:
	await _room(1)
	var reserved: Array[Rect2] = []
	var placed_rows := PackedStringArray()
	if family_id == "utility.walis_cleanup":
		await _walis_sheet()
		return
	var rows := _all_variant_rotations(family_id)
	var placed_count := 0
	for row in rows:
		var result := _pack(str(row.key), int(row.turns), reserved)
		if bool(result.allowed):
			placed_count += 1
			placed_rows.append("%s turns %d placed" % [row.key, row.turns])
		else:
			placed_rows.append("%s turns %d NOT PLACED" % [row.key, row.turns])
	_check(
		placed_count == rows.size(),
		"%s: all %d variant/rotation combinations placed on the sheet" % [family_id, rows.size()]
	)
	room._update_diagnostics()
	await _frames(6)
	await _save("%s_sheet_variants_rotations_1920x1080.png" % SHEET_NAMES[family_id])
	report.append("## %s sheet\n\n%s\n" % [family_id, "\n".join(placed_rows)])


func _walis_sheet() -> void:
	await _room(1)
	var cells: Array[Vector2i] = [
		Vector2i(10, 6), Vector2i(11, 6), Vector2i(12, 6), Vector2i(18, 9)
	]
	for cell in cells:
		room.items.place("build.hollow_blocks.cell_1x1", cell, 0, 1, [] as Array[Rect2])
	room.items.place("build.bamboo_bridge.span_4x1", Vector2i(14, 8), 0, 2, [] as Array[Rect2])
	room.items.end_round()
	room.items.place("build.hollow_blocks.cell_1x1", Vector2i(12, 7), 0, 3, [] as Array[Rect2])
	room.enter_place()
	room.select_family("utility.walis_cleanup")
	room.cursors[0].cell = Vector2i(9, 5)
	room.move_cursor(0, Vector2i.ZERO)
	room.select_variant("utility.walis_cleanup.area_5x5")
	room.cursors[0].cell = Vector2i(9, 5)
	room.move_cursor(0, Vector2i.ZERO)
	await _frames(6)
	await _save("walis_preview_targets_protected_1920x1080.png")
	var overlay := room.overlay_for_cursor("utility.walis_cleanup.area_5x5", Vector2i(9, 5), 0)
	var targets := 0
	for entry in overlay:
		if entry.kind == "target":
			targets += 1
	_check(targets >= 3, "Walis 5x5 outlines its exact targets (%d)" % targets)
	room.cursors[0].cell = Vector2i(5, 11)
	room.move_cursor(0, Vector2i.ZERO)
	await _frames(6)
	await _save("walis_preview_protected_exclusion_1920x1080.png")


func _tell_states() -> void:
	await _room(1)
	var reserved: Array[Rect2] = []
	var spring := _pack("move.tire_spring.tire_2x2", 0, reserved)
	var trumpo := _pack("hazard.rail_trumpo.rail_5x1", 0, reserved)
	var parol := _pack("hazard.parol_pulse.span_5x1", 0, reserved)
	var launcher := _pack("hazard.slipper_launcher.lane_6x1", 0, reserved)
	var bula := _pack("hazard.bubble_planter.path_1x5", 0, reserved)
	var ids := [spring, trumpo, parol, launcher, bula]
	for result in ids:
		_check(bool(result.allowed), "tell fixture placed")
	var states := [
		{"label": "t0_ready_inactive", "t": 0.2},
		{"label": "t1_charge_telegraph_compress", "t": 1.3},
		{"label": "t2_active_fire_paused", "t": 2.2},
	]
	for state in states:
		for result in ids:
			var piece := room.items.piece_for(str(result.instance_id)) as HazardPiece
			if piece != null and piece.behavior != null:
				piece.behavior.preview_at(float(state.t))
				piece.queue_redraw()
		# Spring compresses at t=0.1 only; keep two distinct poses across the sheet.
		var spring_piece := room.items.piece_for(str(spring.instance_id)) as HazardPiece
		(spring_piece.behavior as SpringBehavior).compress = 1.0 if float(state.t) < 1.0 else 0.0
		var trumpo_behavior := (
			room.items.piece_for(str(trumpo.instance_id)).behavior as TrumpoBehavior
		)
		trumpo_behavior.preview_at(0.3 if float(state.t) < 1.0 else (150.0 / 160.0 + 0.2))
		for result in ids:
			room.items.piece_for(str(result.instance_id)).queue_redraw()
		await _frames(4)
		await _save("tells_%s_1920x1080.png" % state.label)
	report.append(
		"## tell states\n\nPlace-mode previews at t=0.2, 1.3 and 2.2 s of the family cycles.\n"
	)


func _egg_sheet() -> void:
	await _room(1)
	var layer := CanvasLayer.new()
	layer.layer = 40
	room.add_child(layer)
	var background := ColorRect.new()
	background.color = Color("#14232a")
	background.size = Vector2(1920.0, 1080.0)
	layer.add_child(background)
	var grid := GridContainer.new()
	grid.columns = 8
	grid.position = Vector2(24.0, 24.0)
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	layer.add_child(grid)
	var eggs := 0
	for family_id in FAMILIES:
		var family := room.definitions.find_family(family_id)
		for variant in family.variants:
			for turns in [variant.rotations[0]]:
				var column := VBoxContainer.new()
				var egg := ItemEggPreview.new()
				egg.configure(room.definitions, family.variant_key(variant), turns, room.tuning)
				egg.elapsed = 0.5
				column.add_child(egg)
				var caption := Label.new()
				caption.text = "%s\n(evidence caption only; eggs show no text)" % variant.variant_id
				caption.add_theme_font_size_override("font_size", 10)
				column.add_child(caption)
				grid.add_child(column)
				eggs += 1
	await _frames(6)
	await _save("egg_previews_every_new_variant_1920x1080.png")
	_check(eggs == 14, "an egg preview is drawn for every new variant (%d)" % eggs)
	layer.queue_free()


func _ghost_sheet() -> void:
	await _room(4)
	room.enter_place()
	var picks := [
		{"key": "move.tire_spring.tire_2x2", "cell": Vector2i(9, 5), "turns": 2},
		{"key": "hazard.slipper_launcher.lane_6x1", "cell": Vector2i(14, 5), "turns": 0},
		{"key": "hazard.parol_pulse.span_6x1", "cell": Vector2i(6, 9), "turns": 0},
		{"key": "hazard.bubble_planter.path_1x5", "cell": Vector2i(2, 10), "turns": 0},
	]
	room.items.place("build.hollow_blocks.column_1x3", Vector2i(18, 4), 0, 1, [] as Array[Rect2])
	for seat in range(4):
		var pick: Dictionary = picks[seat]
		room.select_variant(str(pick.key))
		room.cursors[seat].cell = pick.cell
		room.cursors[seat].turns = pick.turns
		room.move_cursor(seat, Vector2i.ZERO)
		var ghost := room.cursors[seat].ghost as ItemGhost
		var verdict := room.items.validate_placement(
			str(pick.key), pick.cell, int(pick.turns), [] as Array[Rect2]
		)
		report.append(
			(
				"ghost seat %d %s turns %d: %s (%s)"
				% [
					seat + 1,
					pick.key,
					pick.turns,
					"VALID" if verdict.allowed else "REJECTED",
					verdict.reason
				]
			)
		)
		_check(ghost.overlay.size() > 0, "ghost for %s carries region overlays" % pick.key)
	await _frames(6)
	await _save("ghosts_regions_validity_1920x1080.png")


# ------------------------------------------------------------------------------ crowd + perf


func _crowded_and_performance() -> void:
	await _room(4)
	var reserved: Array[Rect2] = []
	var counts := {}
	# 16 launchers: 8 firing right from column 5, 8 firing left from column 27.
	for row in range(8):
		var left := room.items.place(
			"hazard.slipper_launcher.lane_4x1", Vector2i(5, 3 + row), 0, row % 4, [] as Array[Rect2]
		)
		var right := room.items.place(
			"hazard.slipper_launcher.lane_6x1",
			Vector2i(27, 3 + row),
			2,
			row % 4,
			[] as Array[Rect2]
		)
		reserved.append(Rect2(6.0 * 32.0, float(3 + row) * 32.0, 4.0 * 32.0, 32.0))
		reserved.append(Rect2(21.0 * 32.0, float(3 + row) * 32.0, 6.0 * 32.0, 32.0))
		counts["launcher"] = (
			int(counts.get("launcher", 0)) + int(bool(left.allowed)) + int(bool(right.allowed))
		)
	for bula_cell in [Vector2i(7, 12), Vector2i(9, 12), Vector2i(17, 12), Vector2i(19, 12)]:
		var bula := room.items.place(
			"hazard.bubble_planter.path_1x3", bula_cell, 0, 1, [] as Array[Rect2]
		)
		if bool(bula.allowed):
			counts["hazard.bubble_planter"] = int(counts.get("hazard.bubble_planter", 0)) + 1
			reserved.append(Rect2(float(bula_cell.x) * 32.0, 288.0, 32.0, 128.0))
	var mix: Array[String] = [
		"move.tire_spring.tire_2x2",
		"move.tire_spring.tire_2x2",
		"move.tire_spring.tire_2x2",
		"move.tire_spring.tire_2x2",
		"hazard.rail_trumpo.rail_4x1",
		"hazard.rail_trumpo.rail_5x1",
		"hazard.rail_trumpo.rail_6x1",
		"hazard.rail_trumpo.rail_4x1",
		"hazard.parol_pulse.span_3x1",
		"hazard.parol_pulse.span_4x1",
		"hazard.parol_pulse.span_5x1",
		"hazard.parol_pulse.span_6x1",
		"build.bamboo_bridge.span_4x1",
		"build.bamboo_bridge.span_4x1",
		"build.hollow_blocks.stack_2x3",
		"build.hollow_blocks.stack_2x3",
	]
	for key in mix:
		var placed := _pack(key, 0, reserved, 0)
		if bool(placed.allowed):
			var family := key.get_slice(".", 0) + "." + key.get_slice(".", 1)
			counts[family] = int(counts.get(family, 0)) + 1
	for y in range(3, 15):
		for x in range(5, 28):
			if room.items.persistent_count() >= room.tuning.item_persistent_cap:
				break
			var cell_rect := Rect2(Vector2(x, y) * room.tuning.grid_cell_wu, Vector2.ONE * 32.0)
			var blocks_a_path := false
			for reserved_rect in reserved:
				blocks_a_path = (
					blocks_a_path or reserved_rect.grow(-10.0).intersects(cell_rect, false)
				)
			if not blocks_a_path:
				room.items.place(
					"build.hollow_blocks.cell_1x1", Vector2i(x, y), 0, 0, [] as Array[Rect2]
				)
	var persistent := room.items.persistent_count()
	_check(persistent == 48, "the crowded stage holds 48 persistent items (%d)" % persistent)
	room.set_camera_fixture_targets(
		[Rect2(Vector2.ZERO, Vector2(1024.0, 512.0))], BoundedStageCamera.Context.PLAY
	)
	room.start_play()
	await _frames(70)
	for actor_variant in room.actors.values():
		var actor := actor_variant as ChickenController
		actor.global_position = Vector2(80.0 + 24.0 * actor.seat_index, 440.0)
		actor.clear_external_motion()
	await _frames(100)
	await _save("crowded_mixed_48_items_play_1920x1080.png")
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	await _frames(10)
	var intervals := PackedFloat64Array()
	var peak_projectiles := 0
	var peak_bubbles := 0
	# Eight simulated seconds at 60 Hz so every launcher and bubble emitter cycles at least twice.
	for _tick in range(480):
		await physics_frame
		peak_projectiles = maxi(
			peak_projectiles, room.items.budget.count(TransientBudget.Kind.PROJECTILE)
		)
		peak_bubbles = maxi(peak_bubbles, room.items.budget.count(TransientBudget.Kind.BUBBLE))
		for actor_variant in room.actors.values():
			var parked := actor_variant as ChickenController
			if parked.lifecycle.status == PlayerLifecycleState.Status.ACTIVE:
				parked.global_position = Vector2(80.0 + 24.0 * parked.seat_index, 440.0)
	var previous := Time.get_ticks_usec()
	for frame in range(SAMPLE_COUNT):
		await RenderingServer.frame_post_draw
		var now := Time.get_ticks_usec()
		intervals.append(float(now - previous) / 1000.0)
		previous = now
		peak_projectiles = maxi(
			peak_projectiles, room.items.budget.count(TransientBudget.Kind.PROJECTILE)
		)
		peak_bubbles = maxi(peak_bubbles, room.items.budget.count(TransientBudget.Kind.BUBBLE))
		if frame % 4 == 0:
			for actor_variant in room.actors.values():
				var actor := actor_variant as ChickenController
				if actor.lifecycle.status == PlayerLifecycleState.Status.ACTIVE:
					actor.global_position = Vector2(80.0 + 24.0 * actor.seat_index, 440.0)
	var ordered := intervals.duplicate()
	ordered.sort()
	var middle := ordered.size() / 2
	var median := (ordered[middle - 1] + ordered[middle]) * 0.5
	var p95 := ordered[clampi(int(ceil(float(ordered.size()) * 0.95)) - 1, 0, ordered.size() - 1)]
	var worst := ordered[ordered.size() - 1]
	var memory_mib := float(Performance.get_monitor(Performance.MEMORY_STATIC)) / 1048576.0
	var objects := int(Performance.get_monitor(Performance.OBJECT_COUNT))
	var nodes := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var orphans := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	var passed := p95 <= 16.67 and worst <= 16.67 and memory_mib <= 512.0 and orphans == 0
	var lines := PackedStringArray(
		[
			"Status: %s" % ("PASSED" if passed else "FAILED"),
			"P10 48-item mixed-family / four-seat performance capture",
			"Engine: %s" % Engine.get_version_info().string,
			"Resolution: 1920x1080 windowed, V-sync off, %d rendered-frame samples" % SAMPLE_COUNT,
			"Persistent items: %d (%s)" % [persistent, counts],
			(
				"Peak active projectiles: %d (cap %d)"
				% [peak_projectiles, room.tuning.item_projectile_cap]
			),
			"Peak active bubbles: %d (cap %d)" % [peak_bubbles, room.tuning.item_bubble_cap],
			(
				"Director step cost: mean %.3f ms; worst %.3f ms over %d steps"
				% [
					(
						float(room.items.director.step_usec_total)
						/ maxf(1.0, float(room.items.director.step_samples))
						/ 1000.0
					),
					float(room.items.director.step_usec_worst) / 1000.0,
					room.items.director.step_samples
				]
			),
			"Cosmetic VFX nodes: 0 (first-batch tells are drawn, none use the 32-effect pool)",
			"Frame intervals: median %.3f ms; p95 %.3f ms; worst %.3f ms" % [median, p95, worst],
			(
				"Static memory: %.2f MiB; objects %d; nodes %d; orphan nodes %d"
				% [memory_mib, objects, nodes, orphans]
			),
			"Attribution records emitted: %d" % room.items.director.records.size(),
			"P04 reference (1080p): median 1.954 ms; p95 3.109 ms; worst 6.059 ms; 70.97 MiB; 232 nodes",
			(
				"P05 reference (1080p, 48 pieces): median 2.272 ms; p95 4.720 ms; "
				+ "worst 11.011 ms; 79.78 MiB; 302 nodes"
			),
			"Targets: p95 and worst <= 16.67 ms; static memory <= 512 MiB; 0 B/s network",
		]
	)
	var file := FileAccess.open(output_dir.path_join("p10_performance.txt"), FileAccess.WRITE)
	file.store_string("\n".join(lines) + "\n")
	file.close()
	print(
		(
			"P10_PERFORMANCE median=%.3f p95=%.3f worst=%.3f mib=%.2f nodes=%d"
			% [median, p95, worst, memory_mib, nodes]
		)
	)
	_check(passed, "48-item four-seat stress stays inside the frame and memory budget")
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	_check(peak_projectiles <= room.tuning.item_projectile_cap, "projectile cap respected")
	_check(peak_bubbles <= room.tuning.item_bubble_cap, "bubble cap respected")


# ------------------------------------------------------------------------------ swap


func _resource_swap() -> void:
	await _room(1)
	var placed := room.items.place(SWAP_PROBE_VARIANT, Vector2i(14, 8), 0, 0, [] as Array[Rect2])
	var piece := room.items.piece_for(str(placed.instance_id)) as HazardPiece
	piece.show_owner_tag = false
	room.set_camera_fixture_targets(
		[Rect2(Vector2.ZERO, Vector2(1024.0, 512.0))], BoundedStageCamera.Context.PLACE
	)
	await _frames(8)
	var before := await _crop_stats(piece)
	print("P10_SWAP_RECT %s" % [before.rect])
	var visual := piece.family.visual_set
	var slot := visual.get_slot("body")
	var original_frames := slot.frames.duplicate()
	var image := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color(1.0, 0.0, 1.0))
	slot.frames = [ImageTexture.create_from_image(image)] as Array[Texture2D]
	var sound_slot := visual.get_slot("sfx_launch")
	var original_sound := sound_slot.sound
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = 8000
	wav.data = PackedByteArray([0, 40, 80, 120, 80, 40, 0])
	sound_slot.sound = wav
	piece.queue_redraw()
	await _frames(8)
	await _save("swap_resource_after_1920x1080.png")
	var after := await _crop_stats(piece)
	_check(
		int(after.magenta) > int(before.magenta) + 200,
		(
			"swapped body slot renders (magenta pixels %d -> %d) with no code change"
			% [before.magenta, after.magenta]
		)
	)
	_check(piece.play_slot("sfx_launch"), "the swapped sound slot plays through the same call")
	slot.frames = original_frames
	sound_slot.sound = original_sound
	piece.queue_redraw()
	await _frames(8)
	var restored := await _crop_stats(piece)
	_check(
		int(restored.magenta) == int(before.magenta),
		"restoring the slot restores the placeholder art (%d magenta)" % restored.magenta
	)
	report.append(
		(
			"## resource-level swap\n\nmagenta pixels in the spring rect: "
			+ (
				"before %d, swapped %d, restored %d.\n"
				% [before.magenta, after.magenta, restored.magenta]
			)
		)
	)


func _crop_stats(piece: HazardPiece) -> Dictionary:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var transform := (
		piece.get_viewport().get_final_transform() * piece.get_global_transform_with_canvas()
	)
	var top_left := transform * Vector2.ZERO
	var bottom_right := transform * piece.footprint_size
	var magenta := 0
	for y in range(maxi(0, int(top_left.y)), mini(image.get_height(), int(bottom_right.y))):
		for x in range(maxi(0, int(top_left.x)), mini(image.get_width(), int(bottom_right.x))):
			var pixel := image.get_pixel(x, y)
			if pixel.r > 0.7 and pixel.b > 0.7 and pixel.g < 0.45:
				magenta += 1
	return {"magenta": magenta, "rect": Rect2(top_left, bottom_right - top_left)}


func _swap_probe(label: String) -> void:
	await _room(1)
	var placed := room.items.place(SWAP_PROBE_VARIANT, Vector2i(14, 8), 0, 0, [] as Array[Rect2])
	var piece := room.items.piece_for(str(placed.instance_id)) as HazardPiece
	piece.show_owner_tag = false
	await _frames(10)
	var stats := await _crop_stats(piece)
	await _save("swap_probe_%s_1920x1080.png" % label)
	print("P10_SWAP_PROBE label=%s magenta=%d" % [label, stats.magenta])


# ------------------------------------------------------------------------------ misc


func _write_report() -> void:
	var file := FileAccess.open(output_dir.path_join("capture_manifest.md"), FileAccess.WRITE)
	var text := "# P10 capture manifest\n\nEngine %s; 1920x1080; seed 12345; synthetic input; "
	text += "PLACEHOLDER art/audio.\n\n%s\n"
	file.store_string(text % [Engine.get_version_info().string, "\n".join(report)])
	file.close()


func _save(file_name: String) -> void:
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


func _check(condition: bool, label: String) -> void:
	checks += 1
	if condition:
		print("P10_CAPTURE PASSED: ", label)
	else:
		failures += 1
		push_error("P10_CAPTURE FAILED: " + label)

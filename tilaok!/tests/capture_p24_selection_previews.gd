extends SceneTree

## Windowed Pugad and Library preview captures for the three P24 art families.

const FLOW_SCENE := preload("res://scenes/flow/game_flow.tscn")
const VIEW_SIZE := Vector2i(1920, 1080)
const OUTPUT := "../docs/evidence/p24_item_art"
const P24_VARIANTS := [
	"hazard.bubble_planter.path_1x3",
	"hazard.rail_trumpo.rail_5x1",
	"hazard.parol_pulse.span_5x1",
]

var failures := 0
var flow: GameFlow


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var output_dir := ProjectSettings.globalize_path("res://").path_join(OUTPUT).simplify_path()
	DirAccess.make_dir_recursive_absolute(output_dir)
	root.size = VIEW_SIZE
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(VIEW_SIZE)
	flow = FLOW_SCENE.instantiate() as GameFlow
	flow.harness_mode = true
	root.add_child(flow)
	await _frames(4)
	flow.tutorial_session.completed = true
	flow.router.registry.join_keyboard("K1")
	flow.router.registry.join_keyboard("K2")
	flow.show_title()
	await _frames(3)
	flow._enter_match()
	await _frames(4)
	var room := flow.room as OfflineLiveBuildMatchRoom
	if room == null:
		_fail("the normal offline match room did not open")
		quit(1)
		return
	for seat in room.input_router.registry.joined_seats():
		room.input_router.registry.set_ready(int(seat.seat), true)
	if not room.start_match():
		_fail("the match did not enter Pugad")
		quit(1)
		return
	room.egg_pool.clear()
	for index in P24_VARIANTS.size():
		room.egg_pool.append(
			{"egg_id": "p24_egg_%02d" % (index + 1), "variant_key": P24_VARIANTS[index]}
		)
	room._refresh_match_ui()
	await _frames(4)
	await _save(output_dir, "p24_pugad_egg_previews.png")
	flow.show_title()
	await _frames(3)
	flow.show_library()
	await _frames(3)
	var library := flow._screen as UiLibraryScreen
	var tuning := GameplayTuning.new()
	ItemEnabledProfiles.apply(tuning, "items_lab")
	var definitions := ItemDefinitions.load_for_profile(tuning, "items_lab")
	var context := UiLibraryText.build_context(
		tuning, flow.prompt_map, int(flow.settings.screen_shake)
	)
	library.bind_live(definitions, tuning, flow.library_text, context)
	library.choose_category("Items")
	library._set_zone(UiLibraryScreen.ZONE_ENTRIES)
	var bula_index := -1
	for index in library.rows.size():
		var entry := library.rows[index].get("entry") as ItemLibraryEntry
		if entry != null and entry.family_id == "hazard.bubble_planter":
			bula_index = index
			break
	if bula_index < 0:
		_fail("Bula did not appear in the item-library showcase profile")
	else:
		library._move_entries_to(bula_index)
		library._show_entry(bula_index - library.window_offset)
		await _frames(3)
		await _save(output_dir, "p24_library_bula_preview.png")
	await _save_manifest(output_dir)
	print("P24_SELECTION_CAPTURE failures=%d output=%s" % [failures, output_dir])
	quit(1 if failures > 0 else 0)


func _save(output_dir: String, file_name: String) -> void:
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image().save_png(output_dir.path_join(file_name))
	if result != OK:
		_fail("could not save %s (error %d)" % [file_name, result])


func _save_manifest(output_dir: String) -> void:
	var file := FileAccess.open(
		output_dir.path_join("selection_capture_manifest.md"), FileAccess.WRITE
	)
	if file == null:
		_fail("could not save selection capture manifest")
		return
	var manifest: String = (
		"# P24 selection-preview captures\n\nGodot "
		+ Engine.get_version_info().string
		+ "; 1920×1080; windowed. Pugad uses the normal offline match UI with three P24 variant "
		+ "previews injected for this visual showcase. The Library capture uses its real screen and "
		+ "shared ItemEggPreview with the `items_lab` catalog so the not-yet-release-enabled Bula art "
		+ "can be inspected. These are synthetic presentation captures, not proof of item release "
		+ "eligibility.\n"
	)
	file.store_string(manifest)
	file.close()


func _frames(count: int) -> void:
	for _frame in range(count):
		await process_frame


func _fail(message: String) -> void:
	failures += 1
	push_error("P24 selection capture: " + message)

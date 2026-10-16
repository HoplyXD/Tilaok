extends SceneTree

## Map scenes (user request, 2026-10-16): StageMap scenes in scenes/maps/ with a DevMarkers
## layer (Spawn / Build Area / Flag) and a Blocks layer. Checks the folder catalog, the
## blocks-to-surfaces conversion (the sample map reproduces the default stage's surfaces), marker
## mapping, validation, drop-in discovery, a real match room on a map, and the Lobby map
## selection through GameFlow. Run:
## godot --headless --fixed-fps 60 --path tilaok! --script res://tests/run_maps_tests.gd

const FLOW_SCENE := preload("res://scenes/flow/game_flow.tscn")
const MATCH_SCENE := preload("res://scenes/match/match_room.tscn")
const TUTORIAL := "tutorial"
const DROP_IN := "res://scenes/maps/zz_test_drop_in_map.tscn"
const BROKEN := "res://scenes/maps/zz_test_broken_map.tscn"

var failures := 0
var checks := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	MapCatalog.reload()
	_test_catalog()
	_test_default_replica()
	_test_tutorial_map()
	_test_decomposition_and_validation()
	_test_frame_is_decoration()
	_test_drop_in_and_broken_maps()
	await _test_room_on_map()
	await _test_lobby_map_selection()
	print("MAPS_TESTS checks=%d failures=%d" % [checks, failures])
	await process_frame
	quit(1 if failures > 0 else 0)


func _check(condition: bool, label: String) -> void:
	checks += 1
	if condition:
		print("PASS ", label)
	else:
		failures += 1
		push_error("FAIL " + label)


func _test_catalog() -> void:
	var ids := MapCatalog.ids()
	_check(
		ids.size() >= 2 and ids[0] == MapCatalog.DEFAULT_ID and ids[1] == TUTORIAL,
		"the selection lists the built-in default, then the maps folder by order: %s" % [ids]
	)
	_check(
		MapCatalog.errors().is_empty(),
		"every map in the folder validates: %s" % [MapCatalog.errors()]
	)
	_check(
		str(MapCatalog.entry_for(TUTORIAL).name) == "Tutorial", "a map is listed under its Map Name"
	)
	_check(
		MapCatalog.layout_for(MapCatalog.DEFAULT_ID) == null, "the default stage needs no layout"
	)
	_check(
		(
			MapCatalog.cycle(TUTORIAL, 1) == ids[(ids.find(TUTORIAL) + 1) % ids.size()]
			and MapCatalog.cycle(MapCatalog.DEFAULT_ID, -1) == ids[ids.size() - 1]
		),
		"left/right cycling wraps around the selection"
	)


func _rects(arena: ArenaDefinition) -> Array:
	var result := []
	for spec in arena.surface_specs:
		result.append(str(spec.rect))
	result.sort()
	return result


func _new_map(map_name: String) -> StageMap:
	var map := StageMap.new()
	map.map_name = map_name
	var markers := TileMapLayer.new()
	markers.name = StageMap.MARKERS_LAYER
	markers.tile_set = load("res://assets/tiles/map_markers_tileset.tres")
	map.add_child(markers)
	var blocks := TileMapLayer.new()
	blocks.name = StageMap.BLOCKS_LAYER
	blocks.tile_set = load("res://assets/tiles/blocks_tileset.tres")
	map.add_child(blocks)
	return map


func _fill(layer: TileMapLayer, rect: Rect2i, source: int, atlas: Vector2i) -> void:
	for x in range(rect.position.x, rect.end.x):
		for y in range(rect.position.y, rect.end.y):
			layer.set_cell(Vector2i(x, y), source, atlas)


## The built-in default stage painted as a map (what sample_map.tscn started as).
func _default_replica() -> StageMap:
	var map := _new_map("Default replica")
	for rect in [
		Rect2i(0, 15, 32, 1),
		Rect2i(6, 13, 4, 2),
		Rect2i(12, 11, 4, 1),
		Rect2i(18, 13, 4, 2),
		Rect2i(24, 11, 4, 1),
		Rect2i(28, 12, 4, 3),
	]:
		_fill(map.blocks_layer(), rect, 1, Vector2i(0, 0))
	_fill(map.markers_layer(), Rect2i(0, 11, 5, 4), 0, StageMap.MARKER_SPAWN)
	_fill(map.markers_layer(), Rect2i(5, 3, 23, 12), 0, StageMap.MARKER_BUILD)
	_fill(map.markers_layer(), Rect2i(30, 10, 1, 2), 0, StageMap.MARKER_FLAG)
	return map


func _test_default_replica() -> void:
	var tuning := GameplayTuning.new()
	var map := _default_replica()
	var from_map := ArenaDefinition.new(tuning, map.to_layout("replica"))
	map.free()
	var builtin := ArenaDefinition.new(tuning)
	_check(
		_rects(from_map) == _rects(builtin),
		"painted blocks merge into exactly the default stage's collision rectangles"
	)
	_check(
		(
			from_map.build_region == builtin.build_region
			and from_map.protected_spawn == builtin.protected_spawn
			and from_map.goal_trigger == builtin.goal_trigger
		),
		"Build Area, Spawn and Flag markers give the default build region, spawn zone and flag"
	)
	_check(
		(
			is_equal_approx(from_map.spawn_feet.y, builtin.spawn_feet.y)
			and from_map.protected_spawn.has_point(from_map.spawn_feet - Vector2(0.0, 1.0))
			and from_map.protected_goal.encloses(from_map.goal_trigger)
		),
		"chickens spawn standing on the Spawn area's bottom edge; the flag is protected"
	)
	var floor_count := 0
	var goal_rect := Rect2()
	for spec in from_map.surface_specs:
		floor_count += 1 if str(spec.id) == "arena.floor" else 0
		if str(spec.id) == "arena.goal":
			goal_rect = spec.rect
	_check(
		(
			floor_count == 1
			and is_equal_approx(from_map.flag_height_tiles(), builtin.flag_height_tiles())
			and goal_rect == builtin.tile_rect(28, 12, 32, 15)
		),
		"the widest lowest rectangle is the floor; the block under the flag is arena.goal"
	)


## The Tutorial map must stay the verified tutorial stage: values from the retired
## data/stage/tutorial_arena_layout.tres.
func _test_tutorial_map() -> void:
	var tuning := GameplayTuning.new()
	var arena := ArenaDefinition.new(tuning, MapCatalog.layout_for(TUTORIAL))
	var rows := PackedStringArray()
	for spec in arena.surface_specs:
		if str(spec.id).ends_with("_wall") or str(spec.id) == "arena.ceiling":
			continue
		var wall := (
			(spec.metadata as SupportSurfaceMetadata).wall_movement_eligibility
			== SupportSurfaceMetadata.Eligibility.ELIGIBLE
		)
		rows.append("%s %s %s" % [spec.rect, wall, spec.get("custom_visual", false)])
	rows.sort()
	var expected := PackedStringArray()
	for row in [
		[Rect2(0, 15, 32, 1), false, false],
		[Rect2(6, 13, 4, 2), true, false],
		[Rect2(12, 11, 4, 1), true, false],
		[Rect2(18, 13, 4, 2), true, false],
		[Rect2(24, 11, 4, 1), true, false],
		[Rect2(28, 8, 4, 7), false, false],
		[Rect2(28, 7.5, 4, 0.5), false, true],
	]:
		var rect: Rect2 = row[0]
		expected.append(
			"%s %s %s" % [Rect2(rect.position * 64.0, rect.size * 64.0), row[1], row[2]]
		)
	expected.sort()
	_check(
		rows == expected,
		"the Tutorial map's surfaces, wall flags and half-tile cap match the verified stage"
	)
	_check(
		(
			arena.layout_id == TUTORIAL
			and arena.spawn_feet == Vector2(3, 15) * 64.0
			and arena.protected_spawn == arena.tile_rect(0, 11, 5, 15)
			and arena.build_region == arena.tile_rect(5, 3, 28, 15)
			and arena.protected_goal == Rect2(Vector2(28, 4.5) * 64.0, Vector2(4, 10.5) * 64.0)
			and arena.goal_trigger == Rect2(Vector2(30, 5.5) * 64.0, Vector2(1, 2) * 64.0)
			and arena.build_here_zone == arena.tile_rect(24, 8, 28, 11)
			and is_equal_approx(arena.flag_height_tiles(), 7.5)
		),
		"Tutorial spawn, build region, protected goal, half-tile flag and BUILD HERE zone match"
	)


## A map built in code: an L of blocks, markers, then a copy without a flag.
func _make_map(with_flag: bool) -> StageMap:
	var map := _new_map("Test Map")
	var markers := map.markers_layer()
	var blocks := map.blocks_layer()
	for x in 32:
		blocks.set_cell(Vector2i(x, 15), 1, Vector2i(0, 0))
	for y in range(10, 15):
		blocks.set_cell(Vector2i(20, y), 0, Vector2i(3, 2))
	for x in range(21, 24):
		blocks.set_cell(Vector2i(x, 10), 0, Vector2i(3, 2))
	for x in range(1, 4):
		for y in range(12, 15):
			markers.set_cell(Vector2i(x, y), 0, StageMap.MARKER_SPAWN)
	for x in range(6, 18):
		for y in range(4, 15):
			markers.set_cell(Vector2i(x, y), 0, StageMap.MARKER_BUILD)
	if with_flag:
		markers.set_cell(Vector2i(28, 13), 0, StageMap.MARKER_FLAG)
		markers.set_cell(Vector2i(28, 14), 0, StageMap.MARKER_FLAG)
	return map


func _test_decomposition_and_validation() -> void:
	var map := _make_map(true)
	_check(map.validate().is_empty(), "a complete map validates: %s" % [map.validate()])
	var layout := map.to_layout("test")
	var rects := []
	for surface in layout.surfaces:
		rects.append([surface.surface_id, surface.rect_tiles])
	_check(
		(
			layout.surfaces.size() == 3
			and str(layout.surfaces[0].rect_tiles) == str(Rect2(20, 10, 4, 1))
			and str(layout.surfaces[1].rect_tiles) == str(Rect2(20, 11, 1, 4))
			and layout.surfaces[2].surface_id == "arena.floor"
		),
		"touching cells merge into rectangles; the bottom row is the floor: %s" % [rects]
	)
	_check(
		(
			layout.spawn_feet_tiles == Vector2(2.5, 15.0)
			and layout.build_region_tiles == Rect2(6, 4, 12, 11)
			and layout.goal_trigger_tiles == Rect2(28, 13, 1, 2)
			and layout.protected_goal_tiles == Rect2(27, 12, 3, 4)
		),
		"markers map to spawn feet, build region, flag and the flag's 1-tile protection"
	)
	map.free()
	var no_flag := _make_map(false)
	var problems := no_flag.validate()
	_check(
		not problems.is_empty() and " ".join(problems).contains("Flag"),
		"a map without a Flag marker is rejected with a reason: %s" % [problems]
	)
	no_flag.free()


## Cells outside the 32x16 stage (a painted frame, like the Basic Map) are picture only: the game
## already closes the stage with invisible walls and a ceiling there. Outside markers are ignored.
func _test_frame_is_decoration() -> void:
	var map := _default_replica()
	var blocks := map.blocks_layer()
	_fill(blocks, Rect2i(-1, -2, 34, 1), 1, Vector2i(1, 0))
	_fill(blocks, Rect2i(-1, -1, 1, 17), 1, Vector2i(1, 0))
	_fill(blocks, Rect2i(32, -1, 1, 17), 1, Vector2i(1, 0))
	_fill(map.markers_layer(), Rect2i(5, -1, 23, 1), 0, StageMap.MARKER_BUILD)
	_check(map.validate().is_empty(), "a map with a frame outside the stage validates")
	var layout := map.to_layout("framed")
	var outside := 0
	for surface in layout.surfaces:
		if not Rect2(0, 0, 32, 16).encloses(surface.rect_tiles):
			outside += 1
	_check(
		(
			outside == 0
			and layout.surfaces.size() == 6
			and layout.build_region_tiles == Rect2(5, 3, 23, 12)
		),
		"frame cells add no collision and outside markers are ignored"
	)
	map.free()


func _save_map(map: StageMap, path: String) -> void:
	for child in map.get_children():
		child.owner = map
	var packed := PackedScene.new()
	packed.pack(map)
	ResourceSaver.save(packed, path)
	map.free()


func _test_drop_in_and_broken_maps() -> void:
	var map := _make_map(true)
	map.map_name = "Drop-in Map"
	_save_map(map, DROP_IN)
	_save_map(_make_map(false), BROKEN)
	MapCatalog.reload()
	var ids := MapCatalog.ids()
	_check(
		(
			ids.has("zz_test_drop_in_map")
			and str(MapCatalog.entry_for("zz_test_drop_in_map").name) == "Drop-in Map"
		),
		"a map scene saved into scenes/maps/ appears in the selection with no other edit"
	)
	_check(
		(
			not ids.has("zz_test_broken_map")
			and " ".join(MapCatalog.errors()).contains("zz_test_broken")
		),
		"a broken map stays out of the selection and is reported"
	)
	for path in [DROP_IN, BROKEN]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	MapCatalog.reload()
	_check(not MapCatalog.ids().has("zz_test_drop_in_map"), "removing the scene removes the map")


func _test_room_on_map() -> void:
	var room := MATCH_SCENE.instantiate() as P05MatchRoom
	room.arena_layout = MapCatalog.layout_for(TUTORIAL)
	root.add_child(room)
	await process_frame
	await process_frame
	var map := room.world_layer.get_node_or_null("StageMap") as StageMap
	_check(
		(
			map != null
			and map.markers_layer() == null
			and map.blocks_layer() != null
			and room.stage_tiles.get_used_cells().is_empty()
		),
		"in a match the map's Blocks layer is the stage picture; dev markers and debug tiles are gone"
	)
	room.join_keyboard("K1")
	var actor := room.actors[0] as ChickenController
	room.start_play()
	room.input_router.set_phase(LocalInputRouter.Phase.PLAY)
	for _frame in range(60):
		await physics_frame
	var feet_y := actor.global_position.y + room.tuning.body_height_wu * 0.5
	_check(
		actor.is_on_floor() and absf(feet_y - room.arena.spawn_feet.y) < 1.0,
		(
			"a chicken spawns on the map's floor and stands on its generated collision (feet %.1f)"
			% feet_y
		)
	)
	room.queue_free()
	await process_frame


func _press(flow: GameFlow, key: Key) -> void:
	flow.router._handle_key(_key(key, true))
	flow.router._handle_key(_key(key, false))
	for _frame in range(4):
		await process_frame


func _test_lobby_map_selection() -> void:
	var flow := FLOW_SCENE.instantiate() as GameFlow
	root.add_child(flow)
	for _frame in range(3):
		await process_frame
	flow.router.registry.join_keyboard("K1")
	flow._enter_match()
	await process_frame
	await process_frame
	var first_room := flow.room
	_check(
		(
			flow.tutorial_session.is_active()
			and flow.selected_map_id == TUTORIAL
			and first_room.arena.layout_id == TUTORIAL
			and first_room.map_selection_enabled
		),
		"a new session's first match is on the Tutorial map, and the map row is still choosable"
	)
	await _press(flow, KEY_D)
	var next_id := MapCatalog.cycle(TUTORIAL, 1)
	_check(
		(
			flow.selected_map_id == next_id
			and flow.room != first_room
			and flow.room.arena.layout_id == next_id
			and flow.router.registry.joined_seats().size() == 1
			and flow.tutorial_session.skipped
		),
		"picking another map rebuilds the stage, keeps the seat and skips the tutorial"
	)
	var label := flow.room.presenter.lobby_screen.get_node("%MapLabel") as Label
	_check(
		label.visible and label.text.contains(str(MapCatalog.entry_for(next_id).name)),
		"the Lobby shows the chosen map: %s" % label.text
	)
	await _press(flow, KEY_A)
	_check(
		(
			flow.selected_map_id == TUTORIAL
			and flow.tutorial_session.is_active()
			and flow.room.arena.layout_id == TUTORIAL
		),
		"picking the Tutorial map again brings the guided tutorial back"
	)
	flow.tutorial_session.skip()
	flow._enter_match()
	await process_frame
	_check(
		flow.selected_map_id == MapCatalog.DEFAULT_ID and flow.room.arena_layout == null,
		"after the tutorial is done or skipped, the next match falls back to the default stage"
	)
	flow.queue_free()
	await process_frame


func _key(key: Key, pressed: bool) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.pressed = pressed
	return event

# gdlint: disable=max-file-lines
extends SceneTree

## Tutorial gate proof (real Godot physics, real ChickenController, real placement validation).
## It proves the layout hook keeps the default stage identical, that the tutorial flag ledge
## cannot be reached by any scripted no-build attempt, that each allowed piece has a placement
## that reaches it, and that wrong placements do not. A scripted search is strong evidence,
## not a mathematical proof.
## Run with `--fixed-fps 60` (one 1/60 s physics tick per frame, no real-time wait) so the search
## finishes in seconds; the result is identical to real time.

const ROOM_SCENE := preload("res://scenes/fixtures/item_lab.tscn")
const KAING_1X1 := "build.hollow_blocks.cell_1x1"
const KAING_2X3 := "build.hollow_blocks.stack_2x3"
const TULAY_4X1 := "build.bamboo_bridge.span_4x1"
const P07_VARIANTS := [KAING_1X1, KAING_2X3, TULAY_4X1]
## The default stage signature recorded at the P09/P11 baseline (origin/main 7486219).
const DEFAULT_SIGNATURE_SHA := ""
const ATTEMPT_FRAMES := 130
const SETTLE_FRAMES := 6
## Search density knobs (kept explicit so the evidence states exactly what was searched).
const X_STEP_WU := 48.0
const FLOOR_X_STEP_WU := 192.0
const JUMP_DELAYS: Array[int] = [0, 4, 8, 14, 24]
const HOLD_FRAMES: Array[int] = [4, 60]
const PULSE_PERIODS: Array[int] = [0, 12]
const RUN_DIRS: Array[int] = [-1, 0, 1]
## Solution search: start on Base D, run right, press jump, then re-press (release + press) to
## hop again. A pattern is [frames the key is held, frames between presses]; [40, 0] holds once.
const SOLUTION_X_OFFSETS: Array[float] = [34.0, 98.0, 162.0, 222.0]
const SOLUTION_DELAYS: Array[int] = [0, 4, 8, 12, 16, 22]
const SOLUTION_PATTERNS: Array = [[40, 0], [12, 24], [14, 30], [16, 36], [20, 44], [24, 60]]

## Intended single-piece answers (cell is the top-left origin; turns = quarter turns).
const INTENDED: Array[Dictionary] = [
	{"v": KAING_1X1, "cell": Vector2i(27, 9), "turns": 0, "why": "1x1 floating beside the wall"},
	{"v": KAING_2X3, "cell": Vector2i(25, 9), "turns": 1, "why": "2x3 turned flat on Base D"},
	{"v": TULAY_4X1, "cell": Vector2i(24, 9), "turns": 0, "why": "Tulay one tile above Base D"},
]

## The Tutorial map scene (scenes/maps/tutorial.tscn) since 2026-10-16; it reproduces the
## verified tutorial layout exactly (docs/evidence/maps/2026-10-16_tutorial_map_parity.txt).
var tutorial_layout := MapCatalog.layout_for("tutorial")
var failures := 0
var checks := 0
var room: ItemLabRoom
var actor: ChickenController
var seat := 0
var last_solution: Dictionary = {}
var _held := {}
var _attempts_run := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_default_parity()
	_test_tutorial_layout_contract()
	room = _make_room(tutorial_layout)
	root.add_child(room)
	_test_stage_art_order()
	for _frame in range(3):
		await physics_frame
	seat = room.join_keyboard("K1")
	actor = room.actors[seat] as ChickenController
	room.items.reset_match()
	room.items.begin_play()
	room.start_play()
	for _frame in range(3):
		await physics_frame
	await _test_base_route_reaches_platform_d()
	if OS.get_cmdline_user_args().has("--quick"):
		print("GATE_SEARCHES skipped (--quick): no-build and placement solution searches")
		await _cleanup_room()
		print("TUTORIAL_GATE_TESTS quick checks=%d failures=%d" % [checks, failures])
		quit(1 if failures > 0 else 0)
		return
	await _test_no_build_gate()
	await _test_piece_solutions()
	await _test_wrong_placements()
	await _test_layout_persists_across_rounds()
	await _cleanup_room()
	print(
		"TUTORIAL_GATE_TESTS checks=%d failures=%d attempts=%d" % [checks, failures, _attempts_run]
	)
	quit(1 if failures > 0 else 0)


func _cleanup_room() -> void:
	if room != null and is_instance_valid(room):
		room.queue_free()
		await process_frame
	room = null
	actor = null
	if tutorial_layout != null:
		tutorial_layout.map_scene = null
	tutorial_layout = null
	MapCatalog.reload()
	await process_frame


func _check(condition: bool, label: String) -> void:
	checks += 1
	if condition:
		print("PASS ", label)
	else:
		failures += 1
		push_error("FAIL " + label)


func _make_room(layout: ArenaLayout) -> ItemLabRoom:
	var created := ROOM_SCENE.instantiate() as ItemLabRoom
	created.arena_layout = layout
	return created


func _test_stage_art_order() -> void:
	var stage_map := room.world_layer.get_node_or_null("StageMap") as StageMap
	var blocks := stage_map.blocks_layer() if stage_map != null else null
	_check(
		(
			blocks != null
			and blocks.visible
			and blocks.get_used_cells().size() > 0
			and blocks.z_index == 1
		),
		"runtime map artwork is populated and raised above the scene sky"
	)


# --- parity and layout contract -------------------------------------------------------------


func _test_default_parity() -> void:
	var tuning := GameplayTuning.new()
	var literal := ArenaDefinition.new(tuning)
	var from_data := ArenaDefinition.new(tuning, ArenaLayout.make_default())
	print("DEFAULT_SIGNATURE_BEGIN")
	print(literal.arena_geometry_signature())
	print("DEFAULT_SIGNATURE_END")
	_check(
		literal.arena_geometry_signature() == from_data.arena_geometry_signature(),
		"default ArenaLayout reproduces the literal geometry signature"
	)
	_check(literal.build_region == from_data.build_region, "default build region matches")
	_check(literal.protected_goal == from_data.protected_goal, "default protected goal matches")
	_check(literal.protected_spawn == from_data.protected_spawn, "default protected spawn matches")
	_check(literal.goal_trigger == from_data.goal_trigger, "default goal trigger matches")
	_check(literal.spawn_feet == from_data.spawn_feet, "default spawn feet match")
	_check(literal.layout_id == "default" and from_data.layout_id == "default", "default id")
	var parity := true
	for index in literal.surface_specs.size():
		var left: Dictionary = literal.surface_specs[index]
		var found := false
		for right in from_data.surface_specs:
			if right.id == left.id:
				found = true
				var lm := left.metadata as SupportSurfaceMetadata
				var rm := right.metadata as SupportSurfaceMetadata
				parity = parity and lm.wall_movement_eligibility == rm.wall_movement_eligibility
				parity = parity and bool(left.immutable) == bool(right.immutable)
		parity = parity and found
	_check(parity, "default surfaces keep id, immutability and wall eligibility")
	_check(
		literal.surface_specs.size() == from_data.surface_specs.size(),
		"default surface count is unchanged (%d)" % literal.surface_specs.size()
	)


func _test_tutorial_layout_contract() -> void:
	var tuning := GameplayTuning.new()
	var default_arena := ArenaDefinition.new(tuning)
	var arena := ArenaDefinition.new(tuning, tutorial_layout)
	var map_description := str(MapCatalog.entry_for("tutorial").get("description", ""))
	_check(
		(
			map_description.to_lower().contains("practice stage")
			and not map_description.to_lower().contains("without building")
		),
		"tutorial map description no longer promises that building is mandatory"
	)
	_check(arena.layout_id == "tutorial", "tutorial layout id")
	var shared := ["arena.floor", "arena.base_a", "arena.base_b", "arena.base_c", "arena.base_d"]
	for surface_id in shared:
		if surface_id == "arena.floor":
			continue
		_check(
			_rect_of(arena, _tid(surface_id)) == _rect_of(default_arena, surface_id),
			"tutorial keeps %s identical to the default stage" % surface_id
		)
	_check(_rect_of(arena, "arena.floor").has_area(), "tutorial-specific floor geometry is present")
	_check(
		(
			arena.spawn_feet == default_arena.spawn_feet
			and arena.protected_spawn == default_arena.protected_spawn
			and arena.build_region == default_arena.build_region
		),
		"spawn, protected spawn and build region are unchanged"
	)
	for surface_id in ["arena.goal", "arena.goal_cap"]:
		var metadata := _metadata_of(arena, surface_id)
		_check(
			(
				metadata != null
				and (
					metadata.wall_movement_eligibility
					== SupportSurfaceMetadata.Eligibility.INELIGIBLE
				)
			),
			"%s is wall-INELIGIBLE (no kicks off the flag ledge)" % surface_id
		)
	var ledge_top := _rect_of(arena, "arena.goal_cap").position.y
	_check(is_equal_approx(ledge_top, 480.0), "ledge top is y=480 wu (got %.1f)" % ledge_top)
	_check(
		is_equal_approx(arena.goal_trigger.end.y, ledge_top),
		"flag trigger rests exactly on the ledge top"
	)
	var zone := arena.build_here_zone
	_check(zone.size.x > 0.0 and zone.size.y > 0.0, "BUILD HERE zone is defined")
	_check(arena.build_region.encloses(zone), "BUILD HERE zone is inside the build region")
	_check(
		(
			not zone.intersects(arena.protected_spawn, false)
			and not zone.intersects(arena.protected_goal, false)
		),
		"BUILD HERE zone avoids the protected spawn and goal clearance"
	)
	var clear_of_base := true
	for spec in arena.surface_specs:
		if bool(spec.immutable) and zone.intersects(spec.rect, false):
			clear_of_base = false
	_check(clear_of_base, "BUILD HERE zone overlaps no immutable base geometry")
	_check(
		is_equal_approx(tutorial_layout.flag_height_tiles(), 7.5),
		"flag sits 7.5 tiles above the floor (got %s)" % tutorial_layout.flag_height_tiles()
	)
	var tile_painted := true
	for spec in arena.surface_specs:
		if str(spec.id) == "arena.goal_cap":
			tile_painted = not bool(spec.custom_visual)
	_check(not tile_painted, "the half-tile ledge cap uses a custom (non-tile) visual")


## The tutorial map names its merged blocks generically ("arena.block_NN"); the built-in stage's
## base ids map to the tutorial surface with the same rectangle (empty if none matches).
func _tid(default_id: String) -> String:
	var tuning := GameplayTuning.new()
	var wanted := _rect_of(ArenaDefinition.new(tuning), default_id)
	for spec in ArenaDefinition.new(tuning, tutorial_layout).surface_specs:
		if spec.rect == wanted:
			return str(spec.id)
	return ""


func _rect_of(arena: ArenaDefinition, surface_id: String) -> Rect2:
	for spec in arena.surface_specs:
		if str(spec.id) == surface_id:
			return spec.rect
	return Rect2()


func _metadata_of(arena: ArenaDefinition, surface_id: String) -> SupportSurfaceMetadata:
	for spec in arena.surface_specs:
		if str(spec.id) == surface_id:
			return spec.metadata as SupportSurfaceMetadata
	return null


# --- real-physics route and search ----------------------------------------------------------


func _test_base_route_reaches_platform_d() -> void:
	## The P03 route (floor -> A -> B -> C -> D, no building, no wall movement) is unchanged in the
	## tutorial layout. The actor then stays on D, so only the flag ledge is gated.
	_teleport(room.arena.spawn_feet)
	await _frames(SETTLE_FRAMES)
	_key(KEY_D, true)
	await _frames(10)
	_key(KEY_SPACE, true)
	await _frames(24)
	_key(KEY_SPACE, false)
	var on_a := await _wait_for_surface(_tid("arena.base_a"), 18)
	_check(on_a, "tutorial layout: floor -> Base A with the real controller")
	_key(KEY_SPACE, true)
	await _frames(24)
	_key(KEY_SPACE, false)
	var on_b := await _wait_for_surface(_tid("arena.base_b"), 20)
	_check(on_b, "tutorial layout: Base A -> Base B")
	_key(KEY_SPACE, true)
	await _frames(24)
	_key(KEY_SPACE, false)
	var on_c := await _wait_for_surface(_tid("arena.base_c"), 44)
	_check(on_c, "tutorial layout: Base B -> Base C")
	await _frames(8)
	_key(KEY_SPACE, true)
	await _frames(24)
	_key(KEY_SPACE, false)
	var on_d := await _wait_for_surface(_tid("arena.base_d"), 20)
	_check(on_d, "tutorial layout: Base C -> Base D (end of the base route)")
	_key(KEY_D, false)
	await _frames(40)
	var stopped_short := actor.global_position.x < room.arena.goal_trigger.position.x
	_check(stopped_short and not _reached_goal(), "base route alone does not reach the flag")


func _test_no_build_gate() -> void:
	room.items.reset_match()
	room.items.begin_play()
	room.input_router.set_phase(LocalInputRouter.Phase.PLAY)
	var ledge_top := _rect_of(room.arena, "arena.goal_cap").position.y
	var best := {"feet": 100000.0, "label": ""}
	var reached := 0
	var count := 0
	var surfaces := ["arena.floor", "arena.base_a", "arena.base_b", "arena.base_c", "arena.base_d"]
	for surface_id in surfaces:
		var rect := _rect_of(room.arena, _tid(surface_id))
		var x := rect.position.x + 30.0
		while x <= rect.end.x - 30.0 + 0.1:
			for run_dir in RUN_DIRS:
				for delay in JUMP_DELAYS:
					for hold in HOLD_FRAMES:
						for pulse in PULSE_PERIODS:
							var spec := {
								"feet": Vector2(x, rect.position.y),
								"run_dir": run_dir,
								"delay": delay,
								"hold": hold,
								"pulse": pulse,
							}
							var outcome := await _attempt(spec)
							count += 1
							if bool(outcome.reached):
								reached += 1
								push_error("NO-BUILD REACH %s %s" % [surface_id, spec])
							if float(outcome.min_feet) < float(best.feet):
								best.feet = outcome.min_feet
								best.label = (
									"%s x=%.0f dir=%d delay=%d hold=%d pulse=%d"
									% [surface_id, x, run_dir, delay, hold, pulse]
								)
			x += FLOOR_X_STEP_WU if surface_id == "arena.floor" else X_STEP_WU
		print("NO_BUILD_PROGRESS %s attempts=%d best_feet=%.2f" % [surface_id, count, best.feet])
	var summary := (
		"NO_BUILD_SEARCH attempts=%d reached=%d highest_feet_y=%.2f ledge_top_y=%.2f"
		% [count, reached, best.feet, ledge_top]
	)
	summary += " short_by_wu=%.2f best=%s" % [float(best.feet) - ledge_top, best.label]
	print(summary)
	_check(reached == 0, "no-build search: flag never reached in %d scripted attempts" % count)
	_check(
		float(best.feet) > ledge_top + 1.0,
		"no-build highest feet y=%.2f stays below the ledge top y=%.2f" % [best.feet, ledge_top]
	)


func _test_piece_solutions() -> void:
	for variant_key in P07_VARIANTS:
		var table: Array[Dictionary] = await _zone_table(variant_key)
		var solved := 0
		for row in table:
			print(
				(
					"ZONE_TABLE %s origin=%s turns=%d reaches=%s"
					% [variant_key, row.origin, row.turns, row.reaches]
				)
			)
			if bool(row.reaches):
				solved += 1
		print("ZONE_SUMMARY %s valid=%d reaching=%d" % [variant_key, table.size(), solved])
		_check(solved > 0, "%s: at least one BUILD HERE placement reaches the flag" % variant_key)
	for entry in INTENDED:
		var reaches := await _try_placement(str(entry.v), entry.cell, int(entry.turns))
		_check(reaches, "intended answer reaches the flag: %s" % entry.why)


func _test_wrong_placements() -> void:
	var cases := [
		{"v": KAING_1X1, "cell": Vector2i(10, 6), "turns": 0, "why": "far left, floating"},
		{"v": KAING_1X1, "cell": Vector2i(7, 12), "turns": 0, "why": "on Base A"},
		{"v": TULAY_4X1, "cell": Vector2i(12, 8), "turns": 0, "why": "above Base B"},
		{"v": KAING_2X3, "cell": Vector2i(20, 12), "turns": 1, "why": "beside Base C"},
		{"v": KAING_1X1, "cell": Vector2i(26, 12), "turns": 0, "why": "on the floor under D"},
	]
	for case in cases:
		var solved := await _try_placement(case.v, case.cell, int(case.turns))
		_check(not solved, "wrong placement (%s) does not reach the flag" % case.why)


func _test_layout_persists_across_rounds() -> void:
	var signature_before := room.arena.arena_geometry_signature()
	room.items.reset_match()
	room.enter_place()
	var placed := room.items.place(KAING_1X1, Vector2i(26, 9), 0, 0, [])
	_check(bool(placed.allowed), "a piece is accepted in the BUILD HERE zone")
	var built_signature := room.items.construction_signature()
	for _round in range(3):
		room.items.begin_play()
		room.items.end_round()
		room.items.enter_place()
	_check(
		room.arena.arena_geometry_signature() == signature_before,
		"tutorial arena geometry is identical across consecutive rounds"
	)
	_check(
		room.items.construction_signature() == built_signature,
		"construction persists unchanged across consecutive rounds"
	)
	_check(room.arena.layout_id == "tutorial", "layout id stays tutorial for the whole match")


# --- search helpers -------------------------------------------------------------------------


## Every legal placement whose footprint lies inside the BUILD HERE zone, with whether a real
## controller (scripted policy family) reaches the flag with only that piece built.
func _zone_table(variant_key: String) -> Array[Dictionary]:
	var zone := room.arena.build_here_zone
	var cell := room.tuning.grid_cell_wu
	var table: Array[Dictionary] = []
	for turns in [0, 1]:
		for row in range(int(floor(zone.position.y / cell)), int(ceil(zone.end.y / cell))):
			for col in range(int(floor(zone.position.x / cell)), int(ceil(zone.end.x / cell))):
				var origin := Vector2i(col, row)
				room.items.reset_match()
				room.items.enter_place()
				var verdict := room.items.validate_placement(variant_key, origin, turns, [])
				if not bool(verdict.allowed) or not zone.encloses(verdict.footprint):
					continue
				var reaches := await _try_placement(variant_key, origin, turns)
				table.append({"origin": origin, "turns": turns, "reaches": reaches})
	return table


func _try_placement(variant_key: String, origin: Vector2i, turns: int) -> bool:
	room.items.reset_match()
	room.items.enter_place()
	var result := room.items.place(variant_key, origin, turns, 0, [])
	if not bool(result.allowed):
		return false
	room.items.begin_play()
	room.input_router.set_phase(LocalInputRouter.Phase.PLAY)
	var rect := _rect_of(room.arena, _tid("arena.base_d"))
	for x_offset in SOLUTION_X_OFFSETS:
		for delay in SOLUTION_DELAYS:
			for pattern in SOLUTION_PATTERNS:
				var spec := {
					"feet": Vector2(rect.position.x + x_offset, rect.position.y),
					"run_dir": 1,
					"delay": delay,
					"hold": pattern[0],
					"pulse": pattern[1],
				}
				var outcome := await _attempt(spec)
				if bool(outcome.reached):
					last_solution = spec
					return true
	return false


func _attempt(spec: Dictionary) -> Dictionary:
	_attempts_run += 1
	_release_all()
	_teleport(spec.feet)
	await _frames(SETTLE_FRAMES)
	var run_dir := int(spec.run_dir)
	_key(KEY_D, run_dir > 0)
	_key(KEY_A, run_dir < 0)
	var min_feet := float(spec.feet.y)
	var reached := false
	var delay := int(spec.delay)
	var hold := int(spec.hold)
	var pulse := int(spec.pulse)
	for frame in range(ATTEMPT_FRAMES):
		var jump_down := false
		if frame >= delay:
			var elapsed := frame - delay
			if pulse > 0:
				jump_down = (elapsed % pulse) < hold
			else:
				jump_down = elapsed < hold
		_key(KEY_SPACE, jump_down)
		await physics_frame
		min_feet = minf(min_feet, _feet_y())
		if _reached_goal():
			reached = true
			break
		if actor.lifecycle.is_terminal():
			break
	_release_all()
	return {"reached": reached, "min_feet": min_feet}


func _teleport(feet: Vector2) -> void:
	actor.global_position = feet - Vector2(0.0, room.tuning.body_height_wu * 0.5)
	actor.velocity = Vector2.ZERO
	actor.locomotion_velocity = Vector2.ZERO
	actor.external_velocity = Vector2.ZERO
	actor.coyote_remaining = 0.0
	actor.jump_buffer_remaining = 0.0
	actor.lifecycle.status = PlayerLifecycleState.Status.ACTIVE
	actor.reset_wall_state()
	room.support_tracker.invalidate_actor(actor.support_actor_id)


func _feet_y() -> float:
	return actor.global_position.y + room.tuning.body_height_wu * 0.5


func _reached_goal() -> bool:
	var half := Vector2(room.tuning.body_width_wu, room.tuning.body_height_wu) * 0.5
	var body := Rect2(actor.global_position - half, half * 2.0)
	return body.intersects(room.arena.goal_trigger, false)


func _wait_for_surface(surface_id: String, max_frames: int) -> bool:
	for _frame in range(max_frames):
		await physics_frame
		var result := room.current_support_result(actor.support_actor_id, 10000.0)
		var contact := result.contact as SupportContact
		if contact != null and contact.surface_id == surface_id:
			return true
	return false


func _frames(count: int) -> void:
	for _frame in range(count):
		await physics_frame


func _key(keycode: int, down: bool) -> void:
	if bool(_held.get(keycode, false)) == down:
		return
	_held[keycode] = down
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	event.keycode = keycode
	event.pressed = down
	room.input_router._handle_key(event)


func _release_all() -> void:
	for keycode in [KEY_D, KEY_A, KEY_SPACE, KEY_S]:
		_key(keycode, false)

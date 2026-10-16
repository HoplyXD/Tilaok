extends SceneTree

## P19 promotions requested by the user on 2026-10-16 ("pick 3 low-risk ones"): Hagdan ng Bahay
## stairs, Tinik-Tinik Strip and Yelo ng Sorbetero ice, each a scene in scenes/blocks/ with DEBUG
## placeholder art. Real Godot physics in the Item Lab (64 wu grid), synthetic K1 keys.
## Run: godot --headless --fixed-fps 60 --path tilaok!
##   --script res://tests/run_p19_promoted_tests.gd

const ROOM_SCENE := preload("res://scenes/fixtures/item_lab.tscn")
const STAIRS_2 := "build.house_stairs.steps_2x2"
const STAIRS_3 := "build.house_stairs.steps_3x3"
const TINIK_3 := "hazard.toy_burr_strip.strip_3x1"
const TINIK_4 := "hazard.toy_burr_strip.strip_4x1"
const ICE_3 := "modifier.sorbetes_ice.surface_3x1"
const ICE_4 := "modifier.sorbetes_ice.surface_4x1"
const FLOOR_Y := 960.0
const CELL := 64.0

var failures := 0
var checks := 0
var room: ItemLabRoom
var actor: ChickenController


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_catalog()
	room = ROOM_SCENE.instantiate() as ItemLabRoom
	root.add_child(room)
	await _frames(3)
	var seat := room.join_keyboard("K1")
	actor = room.actors[seat] as ChickenController
	room.start_play()
	await _frames(3)
	await _test_stairs()
	await _test_tinik()
	await _test_ice()
	print("P19_PROMOTED_TESTS checks=%d failures=%d" % [checks, failures])
	room.queue_free()
	await process_frame
	quit(1 if failures > 0 else 0)


func _check(condition: bool, label: String) -> void:
	checks += 1
	if condition:
		print("PASS ", label)
	else:
		failures += 1
		push_error("FAIL " + label)


func _frames(count: int) -> void:
	for _frame in range(count):
		await physics_frame


func _key(key: int, down: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.keycode = key
	event.pressed = down
	room.input_router._handle_key(event)


func _feet_y() -> float:
	return actor.global_position.y + room.tuning.body_height_wu * 0.5


func _put_feet(feet: Vector2) -> void:
	actor.global_position = feet - Vector2(0.0, room.tuning.body_height_wu * 0.5)
	actor.velocity = Vector2.ZERO
	actor.locomotion_velocity = Vector2.ZERO
	actor.clear_external_motion()


func _revive() -> void:
	for key in [KEY_A, KEY_D, KEY_W]:
		_key(key, false)
	room.items.reset_match()
	actor.lifecycle.status = PlayerLifecycleState.Status.ACTIVE
	actor.lifecycle.terminal_reason = ""
	actor.reset_wall_state()


func _arm(entries: Array, owner_seat: int = 1) -> Array[String]:
	_revive()
	var ids: Array[String] = []
	var no_rects: Array[Rect2] = []
	for entry in entries:
		var turns := int(entry[2]) if entry.size() > 2 else 0
		var result := room.items.place(
			str(entry[0]), entry[1] as Vector2i, turns, owner_seat, no_rects
		)
		_check(bool(result.allowed), "place %s at %s: %s" % [entry[0], entry[1], result.reason])
		ids.append(str(result.get("instance_id", "")))
	room.items.begin_play()
	room.input_router.set_phase(LocalInputRouter.Phase.PLAY)
	return ids


# --- catalog -------------------------------------------------------------------------------


func _test_catalog() -> void:
	BlockCatalog.reload()
	var definitions := ItemDefinitions.load_all(GameplayTuning.new())
	_check(definitions.is_valid(), "the catalog stays valid: %s" % [definitions.errors])
	var pool := BlockCatalog.default_enabled_keys()
	for key in [STAIRS_2, STAIRS_3, TINIK_3, TINIK_4, ICE_3, ICE_4]:
		_check(
			not definitions.find_variant(key).is_empty() and pool.has(key),
			"%s is in the catalog and the match egg pool from its scene alone" % key
		)
	var stairs := definitions.find_family("build.house_stairs")
	var tinik := definitions.find_family("hazard.toy_burr_strip")
	var ice := definitions.find_family("modifier.sorbetes_ice")
	if stairs == null or tinik == null or ice == null:
		return
	_check(
		(
			stairs.modes_allowed == PackedStringArray(["karera", "lagsanay"])
			and tinik.modes_allowed == PackedStringArray(["karera"])
			and ice.modes_allowed == PackedStringArray(["karera", "lagsanay"])
			and stairs.modes_pending_review.has("kangaroo")
			and tinik.modes_pending_review.has("lagsanay")
			and ice.modes_pending_review.has("kangaroo")
		),
		"mode flags follow the catalog: stairs and ice in both modes, Tinik Karera-only for now"
	)
	var solids := 0
	for region in stairs.find_variant("steps_3x3").regions:
		solids += 1 if region.kind == ItemRegionSpec.Kind.SOLID else 0
	_check(solids == 3, "the 3x3 stairs are three solid step columns (%d)" % solids)
	var trigger_only := true
	for region in tinik.find_variant("strip_3x1").regions:
		trigger_only = trigger_only and region.kind != ItemRegionSpec.Kind.SOLID
	_check(trigger_only, "the Tinik strip has no solid body, only its thin kill strip")
	var tuning := GameplayTuning.new()
	_check(
		(
			is_equal_approx(stairs.selection_weight(tuning), 20.0)
			and is_equal_approx(tinik.selection_weight(tuning), 20.0)
			and is_equal_approx(ice.selection_weight(tuning), 20.0)
		),
		"each promoted family has a low provisional egg weight of 20"
	)


# --- Hagdan ng Bahay -----------------------------------------------------------------------


func _test_stairs() -> void:
	# 3x3 in open air at columns 14-16, rows 6-8: steps rise to the right (tops 512, 448, 384).
	_arm([[STAIRS_3, Vector2i(14, 6)]])
	var tops := [9.0 * CELL - CELL, 9.0 * CELL - 2.0 * CELL, 9.0 * CELL - 3.0 * CELL]
	var all_ok := true
	var landed := []
	for step in range(3):
		var x := (14.0 + step) * CELL + CELL * 0.5
		_put_feet(Vector2(x, float(tops[step]) - 40.0))
		await _frames(40)
		landed.append(snappedf(_feet_y(), 0.1))
		all_ok = all_ok and actor.is_on_floor() and absf(_feet_y() - float(tops[step])) <= 1.0
	_check(all_ok, "a chicken stands on each of the three steps (feet %s)" % [landed])
	# Rotated a quarter turn the solid volume is the same six cells.
	_arm([[STAIRS_2, Vector2i(10, 13), 1]])
	var piece := room.items.piece_for(room.items.pieces.keys()[0]) as StageBlock
	var area := 0.0
	for shape_owner in piece.get_shape_owners():
		var shape := piece.shape_owner_get_shape(shape_owner, 0) as RectangleShape2D
		if shape != null:
			area += shape.size.x * shape.size.y
	_check(
		is_equal_approx(area, 3.0 * CELL * CELL),
		"a rotated 2x2 stairs keeps its three solid cells (%.0f wu2)" % area
	)
	_revive()


# --- Tinik-Tinik ---------------------------------------------------------------------------


func _test_tinik() -> void:
	# A 3x1 strip on the floor at columns 10-12; the chicken walks into it from the open floor on
	# its right (under Base B).
	_arm([[TINIK_3, Vector2i(10, 14)]], 1)
	_put_feet(Vector2(14.5 * CELL, FLOOR_Y))
	await _frames(70)
	_key(KEY_A, true)
	var died := false
	for _frame in range(120):
		await physics_frame
		if actor.lifecycle.status == PlayerLifecycleState.Status.ELIMINATED:
			died = true
			break
	_key(KEY_A, false)
	var kills: Array[AttributionRecord] = []
	for record in room.items.director.records:
		if record.kind == AttributionRecord.Kind.ELIMINATION:
			kills.append(record)
	_check(died, "walking into a Tinik strip knocks the chicken out")
	_check(
		(
			not kills.is_empty()
			and kills[0].owner_seat == 1
			and kills[0].credit_eligible()
			and kills[0].source_family_id == "hazard.toy_burr_strip"
		),
		"the knockout is a direct kill credited to the strip's placer (Patibong)"
	)
	# Hopping over: a chicken kept just above the strip's thin hitbox is never touched.
	_arm([[TINIK_4, Vector2i(10, 14)]], 1)
	for _frame in range(160):
		_put_feet(Vector2(11.5 * CELL, FLOOR_Y - 40.0))
		await physics_frame
	_check(
		actor.lifecycle.status == PlayerLifecycleState.Status.ACTIVE,
		"a chicken 40 wu above the strip (mid-jump) is safe: the hitbox is only the low strip"
	)
	_revive()


# --- Yelo ng Sorbetero ---------------------------------------------------------------------


## Run right at full speed from `start`, let go at `release_x`, return the sliding distance.
func _slide(start: Vector2, release_x: float) -> Dictionary:
	_put_feet(start)
	await _frames(20)
	_key(KEY_D, true)
	var top_speed := 0.0
	var on_ice := false
	for _frame in range(240):
		await physics_frame
		top_speed = maxf(top_speed, actor.velocity.x)
		on_ice = on_ice or actor.on_ice
		if actor.global_position.x >= release_x:
			break
	_key(KEY_D, false)
	var released_at := actor.global_position.x
	for _frame in range(240):
		await physics_frame
		if absf(actor.velocity.x) < 1.0:
			break
	return {
		"distance": actor.global_position.x - released_at,
		"top_speed": top_speed,
		"on_ice": on_ice,
	}


func _test_ice() -> void:
	# Normal floor: columns 10-11 of the open floor (between Base A and the Base B column).
	_revive()
	room.items.begin_play()
	room.input_router.set_phase(LocalInputRouter.Phase.PLAY)
	var normal := await _slide(Vector2(16.0 * CELL, FLOOR_Y), 16.0 * CELL + 120.0)
	# Ice: a 4x1 slab on the floor at columns 10-13 (top 896 wu); start on its left end.
	_arm([[ICE_4, Vector2i(10, 14)], [ICE_3, Vector2i(14, 14)]])
	var icy := await _slide(Vector2(10.0 * CELL + 30.0, FLOOR_Y - CELL), 10.0 * CELL + 150.0)
	_check(
		(
			bool(icy.on_ice)
			and not bool(normal.on_ice)
			and float(icy.distance) > 3.0 * float(normal.distance)
		),
		(
			"letting go on ice slides much further than on the floor (%.0f vs %.0f wu)"
			% [icy.distance, normal.distance]
		)
	)
	_check(
		(
			float(icy.top_speed) > room.tuning.run_speed_wu_s * 1.05
			and float(normal.top_speed) <= room.tuning.run_speed_wu_s + 1.0
		),
		(
			"run speed on ice exceeds the normal cap (%.0f vs %.0f wu/s)"
			% [icy.top_speed, normal.top_speed]
		)
	)
	_check(
		room.items.director.records.is_empty(),
		"ice never eliminates or records credit (no trap credit)"
	)
	_revive()

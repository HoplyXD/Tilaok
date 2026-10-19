extends SceneTree

## Ledge climb (user request, 2026-10-16). Real Godot physics in the Item Lab (64 wu grid),
## synthetic K1 keys. A 4-tile Kaing wall (top 704 wu) is out of reach of a plain jump (apex feet
## 768 wu); jumping at it while holding toward it, the chicken grabs the ledge and climbs on top.
## Run: godot --headless --fixed-fps 60 --path tilaok! --script res://tests/run_ledge_climb_tests.gd

const ROOM_SCENE := preload("res://scenes/fixtures/item_lab.tscn")
const KAING_1X1 := "build.hollow_blocks.cell_1x1"
const FLOOR_Y := 960.0
const WALL_TOP := 704.0
const WALL_COL := 5
const WALL_LEFT := WALL_COL * 64.0
const WallFixtureBuilder = preload("res://scripts/harness/wall_fixture_builder.gd")

var failures := 0
var checks := 0
var room: ItemLabRoom
var actor: ChickenController
var seat := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	room = ROOM_SCENE.instantiate() as ItemLabRoom
	root.add_child(room)
	await _frames(3)
	seat = room.join_keyboard("K1")
	actor = room.actors[seat] as ChickenController
	room.start_play()
	await _frames(3)
	await _test_climbs_a_tall_wall()
	await _test_disabled()
	await _test_no_room_on_top()
	await _test_not_holding_toward_wall()
	await _test_unrelated_top_is_not_a_ledge()
	await _test_unrelated_top_is_not_a_ledge_on_left_wall()
	await _test_climb_stops_at_new_blocker()
	print("LEDGE_CLIMB_TESTS checks=%d failures=%d" % [checks, failures])
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


## The wall: four Kaing 1x1 cells stacked at column 5 (rows 11-14), clear of the lab bases.
func _build(extra: Array = []) -> void:
	for key in [KEY_A, KEY_D, KEY_W]:
		_key(key, false)
	room.items.reset_match()
	var no_rects: Array[Rect2] = []
	var entries := []
	for row in range(11, 15):
		entries.append([KAING_1X1, Vector2i(WALL_COL, row)])
	entries.append_array(extra)
	for entry in entries:
		var result := room.items.place(str(entry[0]), entry[1] as Vector2i, 0, 1, no_rects)
		_check(bool(result.allowed), "place %s at %s: %s" % [entry[0], entry[1], result.reason])
	room.items.begin_play()
	room.input_router.set_phase(LocalInputRouter.Phase.PLAY)
	var half := room.tuning.body_height_wu * 0.5
	actor.global_position = Vector2(WALL_LEFT - 120.0, FLOOR_Y - half)
	actor.velocity = Vector2.ZERO
	actor.locomotion_velocity = Vector2.ZERO
	actor.reset_wall_state()
	actor.cancel_ledge_climb()
	actor.lifecycle.status = PlayerLifecycleState.Status.ACTIVE
	await _frames(20)


## Run at the wall holding right, jump when close, keep holding right until a climb finishes
## (or 1.5 s pass), then let go and sample where the chicken stands.
func _attempt(
	hold_toward_wall: bool = true, wall_side: int = 1, wall_x: float = WALL_LEFT
) -> Dictionary:
	var climbs_before := actor.ledge_climb_count
	var toward_key := KEY_D if wall_side > 0 else KEY_A
	_key(toward_key, true)
	for _frame in range(40):
		await physics_frame
		if (
			(wall_side > 0 and actor.global_position.x > wall_x - 60.0)
			or (wall_side < 0 and actor.global_position.x < wall_x + 60.0)
		):
			break
	_key(KEY_W, true)
	await _frames(4)
	if not hold_toward_wall:
		_key(toward_key, false)
	var best_feet := INF
	for frame in range(90):
		await physics_frame
		best_feet = minf(best_feet, _feet_y())
		if frame == 36:
			_key(KEY_W, false)
		if actor.ledge_climb_count > climbs_before and not actor.climbing:
			break
	_key(KEY_W, false)
	_key(toward_key, false)
	await _frames(3)
	return {
		"climbs": actor.ledge_climb_count - climbs_before,
		"feet": _feet_y(),
		"x": actor.global_position.x,
		"best_feet": best_feet,
		"floor": actor.is_on_floor(),
	}


func _test_climbs_a_tall_wall() -> void:
	await _build()
	var result := await _attempt()
	_check(
		(
			int(result.climbs) == 1
			and absf(float(result.feet) - WALL_TOP) <= 1.0
			and float(result.x) > WALL_LEFT
			and bool(result.floor)
		),
		(
			"jumping at a 4-tile wall while holding toward it climbs the ledge and stands on top: %s"
			% [result]
		)
	)


func _test_disabled() -> void:
	room.tuning.ledge_climb_enabled = false
	await _build()
	var result := await _attempt()
	room.tuning.ledge_climb_enabled = true
	_check(
		int(result.climbs) == 0 and float(result.feet) > WALL_TOP + 32.0,
		(
			"without the ledge climb the same jump cannot get on top (the wall really is too tall): %s"
			% [result]
		)
	)


func _test_no_room_on_top() -> void:
	# A block one tile above the ledge leaves 64 wu: too low for a standing chicken.
	await _build([[KAING_1X1, Vector2i(WALL_COL, 9)]])
	var result := await _attempt()
	_check(
		int(result.climbs) == 0,
		"no climb when there is no room to stand on the ledge: %s" % [result]
	)


func _test_not_holding_toward_wall() -> void:
	await _build()
	var result := await _attempt(false)
	_check(
		int(result.climbs) == 0,
		"no climb when the player is not holding toward the wall: %s" % [result]
	)


func _test_unrelated_top_is_not_a_ledge() -> void:
	await _build()
	room.items.reset_match()
	var tall_wall := WallFixtureBuilder.add_solid(
		room.world_layer,
		"ledge_test.tall_wall",
		Rect2(Vector2(320.0, 300.0), Vector2(4.0, 600.0)),
		true
	)
	var nearby_shelf := WallFixtureBuilder.add_solid(
		room.world_layer,
		"ledge_test.unrelated_shelf",
		Rect2(Vector2(322.0, 704.0), Vector2(64.0, 16.0)),
		true
	)
	actor.global_position = Vector2(200.0, FLOOR_Y - room.tuning.body_height_wu * 0.5)
	actor.velocity = Vector2.ZERO
	actor.locomotion_velocity = Vector2.ZERO
	actor.reset_wall_state()
	await _frames(3)
	var result := await _attempt()
	_check(
		int(result.climbs) == 0,
		(
			"a top on unrelated geometry cannot trigger a climb while touching a tall wall: %s"
			% [result]
		)
	)
	var natural_jump_rise := FLOOR_Y - float(result.best_feet)
	print(
		(
			"LEDGE_METRIC unrelated_top_y=704.00 natural_jump_rise=%.2f false_climbs=%d"
			% [natural_jump_rise, int(result.climbs)]
		)
	)
	tall_wall.queue_free()
	nearby_shelf.queue_free()
	await _frames(2)


func _test_unrelated_top_is_not_a_ledge_on_left_wall() -> void:
	await _build()
	room.items.reset_match()
	WallFixtureBuilder.add_solid(
		room.world_layer,
		"ledge_test.tall_wall_left",
		Rect2(Vector2(500.0, 300.0), Vector2(4.0, 600.0)),
		true
	)
	WallFixtureBuilder.add_solid(
		room.world_layer,
		"ledge_test.unrelated_shelf_left",
		Rect2(Vector2(438.0, 704.0), Vector2(64.0, 16.0)),
		true
	)
	actor.global_position = Vector2(650.0, FLOOR_Y - room.tuning.body_height_wu * 0.5)
	actor.velocity = Vector2.ZERO
	actor.locomotion_velocity = Vector2.ZERO
	actor.reset_wall_state()
	await _frames(3)
	var result := await _attempt(true, -1, 504.0)
	_check(
		int(result.climbs) == 0,
		(
			"a top on unrelated geometry cannot trigger a climb while touching a tall left wall: %s"
			% [result]
		)
	)


func _test_climb_stops_at_new_blocker() -> void:
	await _build()
	_key(KEY_D, true)
	for _frame in range(40):
		await physics_frame
		if actor.global_position.x > WALL_LEFT - 60.0:
			break
	_key(KEY_W, true)
	await _frames(4)
	for _frame in range(50):
		await physics_frame
		if actor.climbing:
			break
	_check(actor.climbing, "valid ledge climb starts before a new path blocker is added")
	if not actor.climbing:
		return
	await _frames(8)
	WallFixtureBuilder.add_solid(
		room.world_layer,
		"ledge_test.mid_climb_blocker",
		Rect2(Vector2(321.0, 600.0), Vector2(2.0, 100.0)),
		true
	)
	await _frames(8)
	_check(
		actor.ledge_climb_count >= 1 and not actor.climbing and actor.global_position.x < 321.0,
		(
			"a blocker that appears in the over-edge path prevents movement through it: %s"
			% [
				{
					"climbs": actor.ledge_climb_count,
					"climbing": actor.climbing,
					"position": actor.global_position,
				}
			]
		)
	)
	_key(KEY_W, false)
	_key(KEY_D, false)

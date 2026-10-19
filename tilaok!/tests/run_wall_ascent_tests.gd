extends SceneTree

## Wall contact must never add upward motion. A normal jump beside a tall wall and unrelated shelf
## peaks at its ordinary apex on both sides of the body.
## Run: godot --headless --fixed-fps 60 --path tilaok! --script res://tests/run_wall_ascent_tests.gd

const ROOM_SCENE := preload("res://scenes/fixtures/item_lab.tscn")
const FLOOR_Y := 960.0
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
	await _test_wall_contact_does_not_add_upward_motion(1)
	await _test_wall_contact_does_not_add_upward_motion(-1)
	print("WALL_ASCENT_TESTS checks=%d failures=%d" % [checks, failures])
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


func _test_wall_contact_does_not_add_upward_motion(side: int) -> void:
	for key in [KEY_A, KEY_D, KEY_W]:
		_key(key, false)
	room.items.reset_match()
	room.items.begin_play()
	room.input_router.set_phase(LocalInputRouter.Phase.PLAY)
	var wall_x := 320.0 if side > 0 else 500.0
	var actor_x := 200.0 if side > 0 else 650.0
	WallFixtureBuilder.add_solid(
		room.world_layer,
		"wall_ascent_test.wall_%d" % side,
		Rect2(Vector2(wall_x, 300.0), Vector2(4.0, 600.0)),
		true
	)
	var shelf_x := 322.0 if side > 0 else 438.0
	WallFixtureBuilder.add_solid(
		room.world_layer,
		"wall_ascent_test.shelf_%d" % side,
		Rect2(Vector2(shelf_x, 704.0), Vector2(64.0, 16.0)),
		true
	)
	actor.global_position = Vector2(actor_x, FLOOR_Y - room.tuning.body_height_wu * 0.5)
	actor.velocity = Vector2.ZERO
	actor.locomotion_velocity = Vector2.ZERO
	actor.reset_wall_state()
	actor.lifecycle.status = PlayerLifecycleState.Status.ACTIVE
	await _frames(3)
	var toward_key := KEY_D if side > 0 else KEY_A
	_key(toward_key, true)
	for _frame in range(40):
		await physics_frame
		if (
			(side > 0 and actor.global_position.x > wall_x - 60.0)
			or (side < 0 and actor.global_position.x < wall_x + 60.0)
		):
			break
	_key(KEY_W, true)
	await _frames(4)
	var peak_feet := INF
	for frame in range(90):
		await physics_frame
		peak_feet = minf(peak_feet, _feet_y())
		if frame == 36:
			_key(KEY_W, false)
	_key(toward_key, false)
	var jump_rise := FLOOR_Y - peak_feet
	_check(
		jump_rise <= 194.0,
		"wall side %d stays within normal jump height: %.3f wu" % [side, jump_rise]
	)
	print(
		"WALL_ASCENT_METRIC side=%d peak_feet=%.3f jump_rise=%.3f wu" % [side, peak_feet, jump_rise]
	)
	await _frames(2)

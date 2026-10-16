extends SceneTree

## Sneak hitbox (user request, 2026-10-16): while sneaking, the chicken's hitbox for item
## hazards, block kill/stun hitboxes and placement clearance is its one-tile sneak body at the
## feet, not the standing body. Real Godot physics in the Item Lab, synthetic K1 keys.
## Run: godot --headless --fixed-fps 60 --path tilaok!
##   --script res://tests/run_sneak_hitbox_tests.gd

const ROOM_SCENE := preload("res://scenes/fixtures/item_lab.tscn")
const LANE := "hazard.slipper_launcher.lane_4x1"
const KAING := "build.hollow_blocks.cell_1x1"
const FLOOR_Y := 960.0
const CELL := 64.0

var failures := 0
var checks := 0
var room: ItemLabRoom
var actor: ChickenController


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	room = ROOM_SCENE.instantiate() as ItemLabRoom
	root.add_child(room)
	await _frames(3)
	var seat := room.join_keyboard("K1")
	actor = room.actors[seat] as ChickenController
	room.start_play()
	await _frames(3)
	await _test_rect()
	await _test_head_height_lane(false)
	await _test_head_height_lane(true)
	await _test_placement_clearance()
	print("SNEAK_HITBOX_TESTS checks=%d failures=%d" % [checks, failures])
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


func _stand_at(x: float) -> void:
	actor.global_position = Vector2(x, FLOOR_Y - room.tuning.body_height_wu * 0.5)
	actor.velocity = Vector2.ZERO
	actor.locomotion_velocity = Vector2.ZERO
	actor.clear_external_motion()


func _reset(sneak: bool) -> void:
	_key(KEY_S, false)
	room.items.reset_match()
	actor.lifecycle.status = PlayerLifecycleState.Status.ACTIVE
	actor.lifecycle.terminal_reason = ""
	_stand_at(13.5 * CELL)
	await _frames(10)
	if sneak:
		_key(KEY_S, true)
		await _frames(4)


func _test_rect() -> void:
	await _reset(false)
	var standing := actor.hit_rect()
	await _reset(true)
	var small := actor.hit_rect()
	_check(
		(
			actor.sneaking
			and standing.size == Vector2(room.tuning.body_width_wu, room.tuning.body_height_wu)
			and small.size == Vector2(room.tuning.body_width_wu, room.tuning.sneak_height_wu)
			and small.size.y <= CELL
			and is_equal_approx(small.end.y, standing.end.y)
		),
		(
			"sneaking shrinks the hitbox to the one-tile body at the feet (%s -> %s)"
			% [standing, small]
		)
	)
	_check(
		SweptContact.body_rect(actor, room.tuning) == small,
		"hazards and block hitboxes read the sneak hitbox (SweptContact.body_rect)"
	)
	_key(KEY_S, false)
	await _frames(4)


## A Tsinelas lane at row 13 (y 832-896): the slipper passes at head height over the floor.
func _test_head_height_lane(sneak: bool) -> void:
	await _reset(sneak)
	var no_rects: Array[Rect2] = []
	var placed := room.items.place(LANE, Vector2i(10, 13), 0, 1, no_rects)
	room.items.begin_play()
	room.input_router.set_phase(LocalInputRouter.Phase.PLAY)
	var piece := room.items.piece_for(str(placed.get("instance_id", ""))) as StageBlock
	var behavior := piece.behavior as LauncherBehavior if piece != null else null
	var shots := 0
	for _frame in range(420):
		_stand_at(13.5 * CELL)
		if sneak:
			actor.global_position.x = 13.5 * CELL
		await physics_frame
		shots = behavior.shots_fired if behavior != null else 0
		if actor.lifecycle.is_terminal() or shots >= 3:
			break
	var label := "sneaking" if sneak else "standing"
	if sneak:
		_check(
			actor.sneaking and shots >= 2 and not actor.lifecycle.is_terminal(),
			(
				"a %s chicken ducks under a head-height slipper lane (%d shots, %s)"
				% [label, shots, actor.lifecycle.status]
			)
		)
	else:
		_check(
			actor.lifecycle.status == PlayerLifecycleState.Status.ELIMINATED,
			"a %s chicken in the same spot is hit by the slipper (%d shots)" % [label, shots]
		)
	_key(KEY_S, false)
	await _frames(4)


## Placement clearance follows the hitbox: the tile just above a sneaking chicken is free.
func _test_placement_clearance() -> void:
	await _reset(false)
	var cell := Vector2i(13, 13)
	var standing := room.items.validate_placement(KAING, cell, 0, room._actor_rects())
	await _reset(true)
	var sneaking := room.items.validate_placement(KAING, cell, 0, room._actor_rects())
	_check(
		not bool(standing.allowed) and bool(sneaking.allowed),
		(
			"a piece over a standing chicken's head is refused but allowed above a sneaking one"
			+ " (%s / %s)" % [standing.reason, sneaking.reason]
		)
	)
	_key(KEY_S, false)
	await _frames(4)

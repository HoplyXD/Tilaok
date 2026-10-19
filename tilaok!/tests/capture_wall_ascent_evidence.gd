extends SceneTree

## Rendered frames for the October 19 wall-ascent regression. Run with a windowed Godot renderer;
## the label is only an output name, and the checked-out controller determines behavior.

const ROOM_SCENE := preload("res://scenes/fixtures/item_lab.tscn")
const WallFixtureBuilder = preload("res://scripts/harness/wall_fixture_builder.gd")
const FLOOR_Y := 960.0

var room: ItemLabRoom
var actor: ChickenController
var output_dir := ""
var label := "after"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--label="):
			label = argument.trim_prefix("--label=")
	output_dir = ProjectSettings.globalize_path(
		"res://../docs/evidence/fixes/2026-10-19-wall-ascent"
	)
	DirAccess.make_dir_recursive_absolute(output_dir)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	room = ROOM_SCENE.instantiate() as ItemLabRoom
	root.add_child(room)
	await _frames(3)
	var seat := room.join_keyboard("K1")
	actor = room.actors[seat] as ChickenController
	room.start_play()
	room.items.reset_match()
	WallFixtureBuilder.add_solid(
		room.world_layer,
		"capture.tall_wall",
		Rect2(Vector2(320.0, 300.0), Vector2(4.0, 600.0)),
		true
	)
	WallFixtureBuilder.add_solid(
		room.world_layer,
		"capture.unrelated_shelf",
		Rect2(Vector2(322.0, 704.0), Vector2(64.0, 16.0)),
		true
	)
	actor.global_position = Vector2(200.0, FLOOR_Y - room.tuning.body_height_wu * 0.5)
	await _frames(3)
	_key(KEY_D, true)
	for _frame in range(40):
		await physics_frame
		if actor.global_position.x > 260.0:
			break
	_key(KEY_W, true)
	await _frames(4)
	await _capture("01_jump_near_wall.png", "jump near the tall wall")
	var best_feet := INF
	for frame in range(90):
		await physics_frame
		best_feet = minf(best_feet, actor.global_position.y + room.tuning.body_height_wu * 0.5)
		if frame == 24:
			await _capture("02_apex_or_false_climb.png", "apex / ledge selection")
		if frame == 36:
			_key(KEY_W, false)
		if actor.ledge_climb_count > 0 and not actor.climbing:
			break
	_key(KEY_W, false)
	_key(KEY_D, false)
	await _frames(3)
	await _capture("03_result.png", "result after holding toward the wall")
	print(
		(
			"WALL_ASCENT_CAPTURE label=%s climbs=%d peak_feet=%.2f final_feet=%.2f wall_side=%d sliding=%s"
			% [
				label,
				actor.ledge_climb_count,
				best_feet,
				actor.global_position.y + room.tuning.body_height_wu * 0.5,
				actor.wall_side,
				actor.wall_sliding
			]
		)
	)
	quit(0)


func _capture(file_name: String, frame_label: String) -> void:
	await RenderingServer.frame_post_draw
	var path := output_dir.path_join("%s_%s" % [label, file_name])
	var error := root.get_texture().get_image().save_png(path)
	if error != OK:
		push_error("Could not save %s: %s" % [path, error_string(error)])
	else:
		print(
			(
				"WALL_ASCENT_FRAME label=%s frame=%s path=%s position=%s climbs=%d"
				% [label, frame_label, path, actor.global_position, actor.ledge_climb_count]
			)
		)


func _key(keycode: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	event.keycode = keycode
	event.pressed = pressed
	room.input_router._handle_key(event)


func _frames(count: int) -> void:
	for _frame in range(count):
		await physics_frame

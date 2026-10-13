extends SceneTree

## Rendered (windowed) captures for the 2026-10-14 movement & blocks extension: the 64 wu
## TileMapLayer stage, the three block scenes, a sneaking and a gliding chicken, and a
## collapsing block before/after. Synthetic input; DEBUG placeholder visuals only.
## Run: godot --path tilaok! --script res://tests/capture_blocks_evidence.gd

const ROOM_SCENE := preload("res://scenes/fixtures/item_lab.tscn")
const OUTPUT_DIR := "../docs/evidence/blocks"

var room: ItemLabRoom
var output_dir := ""
var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	output_dir = ProjectSettings.globalize_path("res://").path_join(OUTPUT_DIR).simplify_path()
	DirAccess.make_dir_recursive_absolute(output_dir)
	root.size = Vector2i(1920, 1080)
	room = ROOM_SCENE.instantiate() as ItemLabRoom
	root.add_child(room)
	await _frames(3)
	var first := room.join_keyboard("K1")
	var second := room.join_keyboard("K2")
	room.start_play()
	var items := room.items
	items.reset_match()
	var no_rects: Array[Rect2] = []
	for entry in [
		["build.solid_block.slab_3x1", Vector2i(14, 8), 0],
		["build.solid_block.slab_3x1", Vector2i(20, 6), 1],
		["build.wood_box.box_2x2", Vector2i(13, 12), 0],
		["build.collapsing_block.cell_1x1", Vector2i(22, 11), 0],
		["build.collapsing_block.cell_1x1", Vector2i(9, 7), 0],
	]:
		var result := items.place(str(entry[0]), entry[1], int(entry[2]), 0, no_rects)
		if not bool(result.allowed):
			failures += 1
			push_error("placement failed: %s %s" % [entry, result.reason])
	items.begin_play()
	room.input_router.set_phase(LocalInputRouter.Phase.PLAY)
	var sneaker := room.actors[first] as ChickenController
	var glider := room.actors[second] as ChickenController
	sneaker.global_position = Vector2(736.0, 960.0 - room.tuning.body_height_wu * 0.5)
	glider.global_position = Vector2(1250.0, 200.0)
	await _frames(20)
	_key(KEY_S, true)
	_key(KEY_UP, true)
	await _frames(30)
	print(
		(
			"BLOCKS_CAPTURE sneaking=%s gliding=%s glide_vy=%.1f"
			% [sneaker.sneaking, glider.gliding, glider.locomotion_velocity.y]
		)
	)
	if not sneaker.sneaking or not glider.gliding:
		failures += 1
	await _capture("2026-10-14_blocks_stage_sneak_glide_1080p.png")
	_key(KEY_UP, false)
	_key(KEY_S, false)
	# Collapse: drop K1 onto the 1x1 at (22,11) and capture shaking, then gone.
	sneaker.global_position = Vector2(1440.0, 704.0 - room.tuning.body_height_wu * 0.5 - 10.0)
	await _frames(60)
	await _capture("2026-10-14_blocks_collapse_crumbling_1080p.png")
	await _frames(90)
	await _capture("2026-10-14_blocks_collapse_gone_1080p.png")
	room.queue_free()
	await process_frame
	print("BLOCKS_CAPTURE_DONE failures=%d dir=%s" % [failures, output_dir])
	quit(1 if failures > 0 else 0)


func _frames(count: int) -> void:
	for _frame in range(count):
		await physics_frame


func _key(key: int, down: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.keycode = key
	event.pressed = down
	room.input_router._handle_key(event)


func _capture(file_name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var path := output_dir.path_join(file_name)
	var error := image.save_png(path)
	print("BLOCKS_CAPTURE saved=%s error=%d size=%s" % [path, error, image.get_size()])
	if error != OK:
		failures += 1

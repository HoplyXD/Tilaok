extends SceneTree

## Rendered (windowed) capture for the block-scene extension: upright and ceiling Spikes, a Cannon
## with a ball in flight, a stunned chicken and a chicken showing the death sprite. Synthetic
## input; DEBUG placeholder visuals only.
## Run: godot --path tilaok! --script res://tests/capture_block_scenes_evidence.gd

const ROOM_SCENE := preload("res://scenes/fixtures/item_lab.tscn")
const OUTPUT_DIR := "../docs/evidence/blocks"

var room: ItemLabRoom
var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var output_dir := ProjectSettings.globalize_path("res://").path_join(OUTPUT_DIR).simplify_path()
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
		["block.spikes.main", Vector2i(16, 14), 0],
		["block.spikes.main", Vector2i(22, 10), 2],
		["block.cannon.main", Vector2i(12, 14), 0],
		["build.hollow_blocks.cell_1x1", Vector2i(10, 13), 0],
	]:
		var result := items.place(str(entry[0]), entry[1], int(entry[2]), 1, no_rects)
		if not bool(result.allowed):
			failures += 1
			push_error("placement failed: %s %s" % [entry, result.reason])
	items.begin_play()
	room.input_router.set_phase(LocalInputRouter.Phase.PLAY)
	var stunned := room.actors[first] as ChickenController
	var fallen := room.actors[second] as ChickenController
	stunned.global_position = Vector2(1600.0, 960.0 - room.tuning.body_height_wu * 0.5)
	fallen.global_position = Vector2(736.0, 960.0 - room.tuning.body_height_wu * 0.5)
	await _frames(20)
	fallen.eliminate("capture: death sprite")
	# Wait until the cannon has a ball in flight.
	var cannon: StageBlock = null
	for record in items.pieces.values():
		if (record as PlacedItem).family_id == "block.cannon":
			cannon = (record as PlacedItem).node as StageBlock
	for _frame in range(240):
		await physics_frame
		if cannon != null and not (cannon.behavior as LauncherBehavior).projectiles.is_empty():
			break
	stunned.apply_stun(1.0, Vector2.ZERO)
	await _frames(4)
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var path := output_dir.path_join("2026-10-14_spikes_cannon_1080p.png")
	var error := image.save_png(path)
	print(
		(
			"BLOCK_SCENES_CAPTURE saved=%s error=%d ball=%s stunned=%s dead=%s"
			% [
				path,
				error,
				not (cannon.behavior as LauncherBehavior).projectiles.is_empty(),
				stunned.is_stunned(),
				fallen.lifecycle.is_terminal()
			]
		)
	)
	if error != OK:
		failures += 1
	room.queue_free()
	await process_frame
	quit(1 if failures > 0 else 0)


func _frames(count: int) -> void:
	for _frame in range(count):
		await physics_frame

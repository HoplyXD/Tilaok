extends SceneTree

## Rendered (windowed) capture for map scenes: the Lobby with the map row on the Sample Map, and
## Play on that map (its Blocks layer is the stage). Synthetic seats; placeholder art.
## Run: godot --path tilaok! --script res://tests/capture_maps_evidence.gd

const FLOW_SCENE := preload("res://scenes/flow/game_flow.tscn")
const OUTPUT_DIR := "../docs/evidence/maps"
## The Basic Map (framed stage with a tall pillar), 2026-10-16.
const MAP_ID := "Basic Map"

var failures := 0
var _output_dir := ""


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_output_dir = ProjectSettings.globalize_path("res://").path_join(OUTPUT_DIR).simplify_path()
	DirAccess.make_dir_recursive_absolute(_output_dir)
	root.size = Vector2i(1920, 1080)
	var flow := FLOW_SCENE.instantiate() as GameFlow
	root.add_child(flow)
	await _frames(3)
	flow.router.registry.join_keyboard("K1")
	flow.router.registry.join_keyboard("K2")
	flow.tutorial_session.skip()
	flow.selected_map_id = MAP_ID
	flow._enter_match()
	await _frames(6)
	await _save("2026-10-16_lobby_basic_map_1080p.png")
	var room := flow.room
	for seat in room.input_router.registry.joined_seats():
		room.input_router.registry.set_ready(int(seat.seat), true)
	room.start_match()
	room._finish_pugad_timeout()
	var none: Array[Dictionary] = []
	room._resolve_place_edits(none)
	for _frame in range(90):
		await physics_frame
	await _save("2026-10-16_basic_map_play_1080p.png")
	print("MAPS_CAPTURE failures=%d layout=%s" % [failures, room.arena.layout_id])
	flow.queue_free()
	await _frames(2)
	quit(1 if failures > 0 else 0)


func _save(file_name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var path := _output_dir.path_join(file_name)
	var error := root.get_texture().get_image().save_png(path)
	print("MAPS_CAPTURE saved=%s error=%d" % [path, error])
	if error != OK:
		failures += 1


func _frames(count: int) -> void:
	for _frame in range(count):
		await process_frame

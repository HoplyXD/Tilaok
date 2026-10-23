extends SceneTree

## Rendered (windowed) capture for 2026-10-16: the Lobby with four keyboard seats (WASD, IJKL,
## arrows, numpad) and the clickable map row, then Place with block previews at different
## rotations. Synthetic seats; DEBUG placeholder art.
## Run: godot --path tilaok! --script res://tests/capture_controls_evidence.gd

const FLOW_SCENE := preload("res://scenes/flow/game_flow.tscn")
const OUTPUT_DIR := "../docs/evidence/controls"

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
	for layout in ["K1", "K3", "K2", "K4"]:
		flow.router.registry.join_keyboard(layout)
	flow.tutorial_session.skip()
	flow._enter_match()
	await _frames(6)
	await _save("2026-10-16_lobby_four_keyboards_map_row_1080p.png")
	var room := flow.room
	for seat in room.input_router.registry.joined_seats():
		room.input_router.registry.set_ready(int(seat.seat), true)
	room.start_match()
	room._finish_pugad_timeout()
	var picks := [
		["block.spikes.main", Vector2i(9, 9), 1],
		["block.cannon.main", Vector2i(14, 8), 2],
		["build.bamboo_bridge.span_4x1", Vector2i(18, 6), 0],
	]
	for seat_index in range(picks.size()):
		if not room.placement_controller.cursors.has(seat_index):
			continue
		var cursor: Dictionary = room.placement_controller.cursors[seat_index]
		cursor.variant_key = picks[seat_index][0]
		cursor.cell = picks[seat_index][1]
		cursor.quarter_turns = picks[seat_index][2]
		room.placement_controller.cursors[seat_index] = cursor
	room._refresh_all_match_ghosts()
	await _frames(6)
	await _save("2026-10-16_place_block_previews_1080p.png")
	print("CONTROLS_CAPTURE failures=%d" % failures)
	flow.queue_free()
	await _frames(2)
	quit(1 if failures > 0 else 0)


func _save(file_name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var path := _output_dir.path_join(file_name)
	var error := root.get_texture().get_image().save_png(path)
	print("CONTROLS_CAPTURE saved=%s error=%d" % [path, error])
	if error != OK:
		failures += 1


func _frames(count: int) -> void:
	for _frame in range(count):
		await process_frame

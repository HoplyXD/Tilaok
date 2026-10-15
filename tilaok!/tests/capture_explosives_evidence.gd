extends SceneTree

## Rendered (windowed) capture for the explosives: Bomb / Dynamite / Nuke eggs in the Pugad, then
## a Nuke going off over earlier Kaing pieces. Synthetic seats; DEBUG placeholder visuals.
## Run: godot --path tilaok! --script res://tests/capture_explosives_evidence.gd

const MATCH_SCENE := preload("res://scenes/match/match_room.tscn")
const OUTPUT_DIR := "../docs/evidence/blocks"
const KAING := "build.hollow_blocks.cell_1x1"
const EXPLOSIVES := ["explosive.bomb.main", "explosive.dynamite.main", "explosive.nuke.main"]

var failures := 0
var _output_dir := ""


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_output_dir = ProjectSettings.globalize_path("res://").path_join(OUTPUT_DIR).simplify_path()
	root.size = Vector2i(1920, 1080)
	var room := MATCH_SCENE.instantiate() as P05MatchRoom
	root.add_child(room)
	await _frames(3)
	room.join_keyboard("K1")
	room.join_keyboard("K2")
	room.input_router.registry.set_ready(0, true)
	room.input_router.registry.set_ready(1, true)
	room.start_match()
	var edits: Array[Dictionary] = []
	for cell in [Vector2i(13, 8), Vector2i(14, 8), Vector2i(15, 9), Vector2i(16, 8)]:
		edits.append(_edit(edits.size() % 2, KAING, cell))
	room._finish_pugad_timeout()
	room._resolve_place_edits(edits)
	var controller := room.race_round_controller
	controller.hard_cap_seconds = 0.002
	var none: Array[Dictionary] = []
	var step := controller.advance_step(0.01, Engine.get_physics_frames(), none)
	room._apply_race_outcomes(step.new_outcomes)
	room._finish_race(str(step.end_reason))
	room._start_next_round()
	for index in range(mini(EXPLOSIVES.size(), room.egg_pool.size())):
		room.egg_pool[index].variant_key = EXPLOSIVES[index]
	room.presenter._eggs_dirty = true
	room._notify_presentation(&"eggs")
	await _frames(6)
	await _save("2026-10-15_explosive_eggs_1080p.png")
	room._finish_pugad_timeout()
	var blast: Array[Dictionary] = [_edit(0, "explosive.nuke.main", Vector2i(13, 7))]
	room._resolve_place_edits(blast)
	await _frames(8)
	await _save("2026-10-15_nuke_blast_1080p.png")
	print("EXPLOSIVES_CAPTURE failures=%d pieces_left=%d" % [failures, room.items.pieces.size()])
	room.queue_free()
	await _frames(2)
	quit(1 if failures > 0 else 0)


func _edit(seat: int, variant_key: String, cell: Vector2i) -> Dictionary:
	return {
		"seat_index": seat,
		"variant_key": variant_key,
		"origin_cell": cell,
		"quarter_turns": 0,
		"cleanup_targets": [],
	}


func _save(file_name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var path := _output_dir.path_join(file_name)
	var error := root.get_texture().get_image().save_png(path)
	print("EXPLOSIVES_CAPTURE saved=%s error=%d" % [path, error])
	if error != OK:
		failures += 1


func _frames(count: int) -> void:
	for _frame in range(count):
		await process_frame

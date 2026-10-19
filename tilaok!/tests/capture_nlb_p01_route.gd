extends SceneTree

## Synthetic rendered offline route capture for NLB-P01 verification.
## Run windowed with: godot --path tilaok! --script res://tests/capture_nlb_p01_route.gd

const FLOW_SCENE := preload("res://scenes/flow/game_flow.tscn")
const OUTPUT_DIR := "../docs/evidence/nlb/p01/captures"

var failures := 0
var output_dir := ""


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	output_dir = ProjectSettings.globalize_path("res://").path_join(OUTPUT_DIR).simplify_path()
	DirAccess.make_dir_recursive_absolute(output_dir)
	root.size = Vector2i(1280, 720)
	var flow := FLOW_SCENE.instantiate() as GameFlow
	root.add_child(flow)
	await _frames(4)
	flow.router.registry.join_keyboard("K1")
	flow.router.registry.join_keyboard("K2")
	flow._enter_match()
	await _frames(8)
	await _save("01-lobby.png")
	var room := flow.room as P12ScheduledMatchRoom
	for seat in room.input_router.registry.joined_seats():
		room.input_router.registry.set_ready(int(seat.seat), true)
	if not room.start_match():
		failures += 1
		push_error("Could not start the two-seat offline route.")
		quit(1)
		return
	await _frames(8)
	await _save("02-pugad.png")
	room._finish_pugad_timeout()
	await _frames(8)
	await _save("03-place.png")
	room._enter_play()
	await _frames(8)
	await _save("04-play.png")
	var result := room.race_round_controller.advance_step(
		room.race_round_controller.hard_cap_seconds + 1.0, Engine.get_physics_frames(), []
	)
	room._apply_race_outcomes(result.new_outcomes)
	if bool(result.ended):
		room._finish_race(str(result.end_reason))
	await _frames(8)
	await _save("05-results.png")
	room._start_next_round()
	await _frames(8)
	await _save("06-next-round-pugad.png")
	print("NLB_P01_ROUTE_CAPTURE failures=%d output=%s" % [failures, output_dir])
	flow.queue_free()
	await _frames(2)
	quit(1 if failures > 0 else 0)


func _save(file_name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var path := output_dir.path_join(file_name)
	var error := root.get_texture().get_image().save_png(path)
	print("NLB_P01_CAPTURE file=%s error=%d" % [path, error])
	if error != OK:
		failures += 1


func _frames(count: int) -> void:
	for _frame in range(count):
		await process_frame

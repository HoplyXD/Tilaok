extends SceneTree

## Rendered (windowed) capture for P12-T05: a Karera round with the Bomb-Taya Twist (4 seats,
## taya marker, TWIST tag and taya clock in the HUD). The Twist is injected into round 1's locked
## entry for the capture only. Synthetic seats; DEBUG placeholder presentation.
## Run: godot --path tilaok! --script res://tests/capture_p12_twist_evidence.gd

const ROOM_SCENE := preload("res://scenes/match/p12_scheduled_match_room.tscn")
const OUTPUT_DIR := "../docs/evidence/p12"

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var output_dir := ProjectSettings.globalize_path("res://").path_join(OUTPUT_DIR).simplify_path()
	root.size = Vector2i(1920, 1080)
	var room := ROOM_SCENE.instantiate() as P12ScheduledMatchRoom
	root.add_child(room)
	await _frames(3)
	var seats: Array[int] = [room.join_keyboard("K1"), room.join_keyboard("K2")]
	for device_id in [7101, 7102]:
		var seat_index := room.input_router.registry.join_gamepad(device_id)
		seats.append(seat_index)
		room.input_router.seat_joined.emit(seat_index)
	for seat_index in seats:
		room.input_router.registry.set_ready(seat_index, true)
	room.start_match()
	room.schedule.locked[1]["twist"] = EventSchedule.Challenge.LAGSANAY
	room._finish_pugad_timeout()
	var none: Array[Dictionary] = []
	room._resolve_place_edits(none)
	var index := 0
	for seat_index in seats:
		var actor := room.actors[seat_index] as ChickenController
		var feet := room.arena.spawn_feet + Vector2(220.0 * index, 0.0)
		actor.global_position = room.arena.controller_origin_from_feet(feet)
		index += 1
	for _frame in range(240):
		await physics_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var path := output_dir.path_join("2026-10-15_p12_bomb_taya_twist_1080p.png")
	var error := root.get_texture().get_image().save_png(path)
	if error != OK or not room.bomb_taya.active:
		failures += 1
	print(
		(
			"P12_TWIST_CAPTURE saved=%s error=%d active=%s taya=%d tag=%s"
			% [path, error, room.bomb_taya.active, room.bomb_taya.taya_seat, room.play_tag_text()]
		)
	)
	room.queue_free()
	await _frames(2)
	quit(1 if failures > 0 else 0)


func _frames(count: int) -> void:
	for _frame in range(count):
		await process_frame

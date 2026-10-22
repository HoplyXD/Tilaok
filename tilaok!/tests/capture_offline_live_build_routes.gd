extends SceneTree

## Synthetic live-build route captures. No physical-input or human-play evidence is implied.

const FALLBACK_SCENE := preload("res://scenes/match/p12_scheduled_match_room.tscn")
const LIVE_SCENE := preload("res://scenes/match/offline_live_build_room.tscn")
const OUTPUT_RELATIVE := "../docs/evidence/p20_offline_live_build/captures"
const CELL_1X1 := "build.hollow_blocks.cell_1x1"

var output_dir := ""
var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	output_dir = ProjectSettings.globalize_path("res://").path_join(OUTPUT_RELATIVE).simplify_path()
	DirAccess.make_dir_recursive_absolute(output_dir)
	root.size = Vector2i(1920, 1080)
	await _capture_fallback()
	await _capture_live_route()
	print(
		"OFFLINE_LIVE_ROUTE_CAPTURE failures=%d output=%s input=synthetic" % [failures, output_dir]
	)
	await process_frame
	quit(1 if failures > 0 else 0)


func _capture_fallback() -> void:
	var room := FALLBACK_SCENE.instantiate() as P12ScheduledMatchRoom
	root.add_child(room)
	await _frames(5)
	_join_ready(room)
	room.start_match()
	await _frames(8)
	await _save("01-fallback-pugad.png")
	room._finish_pugad_timeout()
	await _frames(5)
	await _save("02-fallback-place.png")
	var no_place_edits: Array[Dictionary] = []
	room._resolve_place_edits(no_place_edits)
	if room.race_round_controller != null:
		room.race_round_controller.hard_cap_seconds = 3600.0
	await _frames(5)
	await _save("03-fallback-play.png")
	room.queue_free()
	await _frames(4)


func _capture_live_route() -> void:
	var room = LIVE_SCENE.instantiate()
	root.add_child(room)
	await _frames(5)
	_join_ready(room)
	room.set_match_seed(73)
	room.tuning.match_target_score_units = 100000
	room.go_countdown_seconds = 3.0
	room.start_match()
	for seat_index in range(2):
		var egg: Dictionary = room.egg_pool[seat_index]
		egg.variant_key = CELL_1X1
		room.egg_pool[seat_index] = egg
		room._queue_claim(seat_index, str(egg.egg_id))
	await _frames(2)
	room._flush_claims()
	await _frames(5)
	await _save("04-live-pugad.png")
	await _save("05-live-go.png")
	room.go_countdown_seconds = 0.1
	room._go_remaining = 0.1
	room.phase_controller.remaining_seconds = 0.1
	room._process(0.2)
	if room.race_round_controller != null:
		room.race_round_controller.hard_cap_seconds = 3600.0
	await _frames(5)
	for seat_index in room.placement_controller.cursors.keys():
		room._add_match_ghost(int(seat_index))
		(room._ghosts[int(seat_index)] as ItemGhost).visible = false
	room.build_mode[0] = true
	room._set_live_ghost_visible(0, true)
	var cursor: Dictionary = room.placement_controller.cursors[0]
	var target_cell := _find_safe_cell(room, CELL_1X1)
	cursor.variant_key = CELL_1X1
	cursor.cell = target_cell
	cursor.quarter_turns = 0
	room.placement_controller.cursors[0] = cursor
	room._refresh_match_ghost(0)
	await _frames(3)
	await _save("06-live-build-preview.png")
	room._submit_live_placement(0)
	for _frame in range(4):
		await physics_frame
	await _frames(3)
	await _save("07-live-construction-progress.png")
	var rejected_intent := {
		"request_id": "capture-reject",
		"match_id": room.request_pipeline.match_id,
		"round_id": room.request_pipeline.round_id,
		"attempt_id": room.request_pipeline.attempt_id,
		"observed_stage_version": room.items.stage_version,
		"variant_key": CELL_1X1,
		"cell": Vector2i(-1, -1),
		"quarter_turns": 0,
	}
	room.placement_controller.cursors[1].variant_key = CELL_1X1
	room.inventory_used[1] = false
	var rejection: Dictionary = room._commit_live_intent(
		1, rejected_intent, Engine.get_physics_frames()
	)
	room.live_notices[1] = str(rejection.reason)
	room._notify_presentation(&"live_build")
	await _frames(3)
	await _save("08-live-placement-rejected.png")
	room.request_pipeline.close_attempt()
	room.phase_controller.enter(MatchPhaseController.Phase.RESULTS)
	room._refresh_match_ui()
	await _frames(3)
	await _save("09-live-round-close-cleanup.png")
	room.queue_free()
	await _frames(4)
	await _capture_lagsanay_event()


func _capture_lagsanay_event() -> void:
	var room = LIVE_SCENE.instantiate()
	root.add_child(room)
	await _frames(4)
	_join_ready(room)
	room.set_match_seed(73)
	room.tuning.match_target_score_units = 100000
	room.start_match()
	room.items.round_number = 3
	room.schedule.lock_round(4)
	room._begin_pugad()
	for seat_index in range(2):
		var egg: Dictionary = room.egg_pool[seat_index]
		room._queue_claim(seat_index, str(egg.egg_id))
	room._flush_claims()
	room.go_countdown_seconds = 0.1
	room._process(0.2)
	await _frames(8)
	await _save("10-live-lagsanay-event.png")
	room.queue_free()
	await _frames(4)


func _join_ready(room) -> void:
	room.join_keyboard("K1")
	room.join_keyboard("K2")
	room.input_router.registry.set_ready(0, true)
	room.input_router.registry.set_ready(1, true)


func _find_safe_cell(room, variant_key: String) -> Vector2i:
	room.items.live_actor_clearance_wu = room.live_actor_clearance_wu
	for y in range(room.tuning.arena_height_tiles):
		for x in range(room.tuning.arena_width_tiles):
			var actor_rects: Array[Rect2] = room._live_actor_swept_rects()
			var result: Dictionary = room.items.validate_placement(
				variant_key, Vector2i(x, y), 0, room.items.owner_seat_clearance(actor_rects)
			)
			if bool(result.get("allowed", false)):
				return Vector2i(x, y)
	return Vector2i(8, 6)


func _save(file_name: String) -> void:
	await process_frame
	var path := output_dir.path_join(file_name)
	var texture := root.get_texture()
	if texture == null:
		failures += 1
		push_error("OFFLINE_LIVE_CAPTURE no rendered viewport texture: %s" % file_name)
		return
	var image := texture.get_image()
	if image == null:
		failures += 1
		push_error("OFFLINE_LIVE_CAPTURE viewport image unavailable: %s" % file_name)
		return
	var error := image.save_png(path)
	print("OFFLINE_LIVE_CAPTURE file=%s error=%d" % [path, error])
	if error != OK:
		failures += 1


func _frames(count: int) -> void:
	for _frame in range(count):
		await process_frame

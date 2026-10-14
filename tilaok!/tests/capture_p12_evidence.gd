extends SceneTree

## Rendered (windowed) capture for P12-T01: the Pugad round announcement, a scheduled Lagsanay
## Main round and a scheduled Kangaroo Main round in the full match. Synthetic seats and input;
## DEBUG placeholder presentation only.
## Run: godot --path tilaok! --script res://tests/capture_p12_evidence.gd

const ROOM_SCENE := preload("res://scenes/match/p12_scheduled_match_room.tscn")
const OUTPUT_DIR := "../docs/evidence/p12"
const SEED := 3

var room: P12ScheduledMatchRoom
var failures := 0
var _output_dir := ""


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_output_dir = ProjectSettings.globalize_path("res://").path_join(OUTPUT_DIR).simplify_path()
	DirAccess.make_dir_recursive_absolute(_output_dir)
	root.size = Vector2i(1920, 1080)
	room = ROOM_SCENE.instantiate() as P12ScheduledMatchRoom
	root.add_child(room)
	await _frames(3)
	room.set_match_seed(SEED)
	var seats: Array[int] = [room.join_keyboard("K1"), room.join_keyboard("K2")]
	for device_id in [7101, 7102]:
		var seat_index := room.input_router.registry.join_gamepad(device_id)
		seats.append(seat_index)
		room.input_router.seat_joined.emit(seat_index)
	for seat_index in seats:
		room.input_router.registry.set_ready(seat_index, true)
	if not room.start_match():
		_fail("the scheduled match did not start")
	room.tuning.match_target_score_units = 100000
	room.tuning.match_results_advance_seconds = 600.0
	var captured_lagsanay := false
	var captured_kangaroo := false
	for active_round in range(1, 12):
		var main := int(room.current_entry().main)
		if active_round == 5:
			await _frames(4)
			await _save("2026-10-15_p12_pugad_announcement_1080p.png")
		room._finish_pugad_timeout()
		var empty_edits: Array[Dictionary] = []
		room._resolve_place_edits(empty_edits)
		if main == EventSchedule.Challenge.KARERA:
			_finish_race(seats[0])
		elif main == EventSchedule.Challenge.LAGSANAY:
			await _frames(260)
			if not captured_lagsanay:
				await _save("2026-10-15_p12_lagsanay_main_1080p.png")
				captured_lagsanay = true
			await _until_round_ends()
		else:
			await _frames(150)
			if not captured_kangaroo:
				await _save("2026-10-15_p12_kangaroo_main_1080p.png")
				captured_kangaroo = true
			for seat_index in seats.slice(0, seats.size() - 1):
				room.kangaroo_round.record_input_edge(
					seat_index, "right", "capture:right", true, Time.get_ticks_usec()
				)
			await _until_round_ends()
		if captured_lagsanay and captured_kangaroo:
			break
		await _frames(2)
		room._start_next_round()
		await _frames(2)
	if not (captured_lagsanay and captured_kangaroo):
		_fail("seed %d did not reach both event rounds" % SEED)
	print("P12_CAPTURE failures=%d" % failures)
	room.queue_free()
	await _frames(2)
	quit(1 if failures > 0 else 0)


func _finish_race(winner: int) -> void:
	var controller := room.race_round_controller
	var candidates: Array[Dictionary] = [
		{
			"round_id": controller.ledger.round_id,
			"seat_index": winner,
			"kind": "goal",
			"event_id": "%s:capture-goal" % controller.ledger.round_id,
			"physics_tick": Engine.get_physics_frames(),
		}
	]
	controller.hard_cap_seconds = 0.002
	var step := controller.advance_step(0.01, Engine.get_physics_frames(), candidates)
	room._apply_race_outcomes(step.new_outcomes)
	room._finish_race(str(step.end_reason))


func _until_round_ends() -> void:
	var frames := 0
	while room.phase_controller.phase == MatchPhaseController.Phase.PLAY and frames < 40000:
		await physics_frame
		frames += 1
	if frames >= 40000:
		_fail("an event round did not end")


func _save(file_name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var path := _output_dir.path_join(file_name)
	var error := root.get_texture().get_image().save_png(path)
	print(
		(
			"P12_CAPTURE saved=%s error=%d round=%d entry=%s"
			% [
				path,
				error,
				room.items.round_number + 1,
				EventSchedule.describe(room.current_entry())
			]
		)
	)
	if error != OK:
		_fail("could not save %s" % file_name)


func _frames(count: int) -> void:
	for _frame in range(count):
		await process_frame


func _fail(message: String) -> void:
	failures += 1
	push_error(message)

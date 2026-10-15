extends SceneTree

## P13 rendered evidence (windowed): every menu route, Library category, Settings, the HUD for each
## mode and stack, the round result with Last Cluck, the cheer cue, the muted + shake-off
## minimum-zoom crowded 4-seat Storm stage and a Parol strobe measurement. Synthetic seats and
## input;
## these are engineering captures, not a human spectator, novice or QA review.
## Run: godot --path tilaok! --script res://tests/capture_p13_evidence.gd
## Env: P13_EVIDENCE_DIR (default ../docs/evidence/p13), P13_RESOLUTIONS
## ("1920x1080,1280x720,1920x800").

const FLOW_SCENE := preload("res://scenes/flow/game_flow.tscn")
const ITEMS_LAB_SCENE := preload("res://scenes/match/match_room_items_lab.tscn")
const LIBRARY_SCREEN := preload("res://scenes/ui/screens/library_screen.tscn")
const SETTINGS_SCREEN := preload("res://scenes/ui/screens/settings_screen.tscn")
const PADS := [7101, 7102]
const KARERA := EventSchedule.Challenge.KARERA
const LAGSANAY := EventSchedule.Challenge.LAGSANAY
const KANGAROO := EventSchedule.Challenge.KANGAROO
const NONE := EventSchedule.Challenge.NONE
const FULL_RESOLUTION := Vector2i(1920, 1080)
const LIBRARY_CATEGORIES := [
	"How to Play", "Karera", "Lagsanay", "Kangaroo", "Items", "Accessibility"
]
const PAROL_5 := "hazard.parol_pulse.span_5x1"
const FLASH_STEP := 0.10
const PAROL_SAMPLE_MSEC := 4500

var failures := 0
var shots := 0
var output_dir := ""
var flow: GameFlow
var room: P12ScheduledMatchRoom
var tag := ""
var report := PackedStringArray()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var override := OS.get_environment("P13_EVIDENCE_DIR")
	output_dir = (
		override
		if not override.is_empty()
		else (
			ProjectSettings
			. globalize_path("res://")
			. path_join("../docs/evidence/p13")
			. simplify_path()
		)
	)
	DirAccess.make_dir_recursive_absolute(output_dir.path_join("captures"))
	var only := OS.get_environment("P13_ONLY")
	var resolutions := _resolutions() if only.is_empty() else ([] as Array[Vector2i])
	for resolution in resolutions:
		var full := resolution == FULL_RESOLUTION
		for seat_count in [2, 4]:
			tag = "%dx%d_%dp" % [resolution.x, resolution.y, seat_count]
			DisplayServer.window_set_size(resolution)
			root.size = resolution
			await _frames(3)
			await _routes(seat_count, full)
			await _modes(seat_count, full)
			if full:
				await _final_results()
	DisplayServer.window_set_size(FULL_RESOLUTION)
	root.size = FULL_RESOLUTION
	await _frames(3)
	tag = "1920x1080_4p"
	await _crowded_muted_shake_off()
	await _parol_strobe()
	_write_report()
	print("P13_CAPTURE shots=%d failures=%d dir=%s" % [shots, failures, output_dir])
	quit(1 if failures > 0 else 0)


func _resolutions() -> Array[Vector2i]:
	var text := OS.get_environment("P13_RESOLUTIONS")
	if text.is_empty():
		text = "1920x1080,1280x720,1920x800"
	var result: Array[Vector2i] = []
	for item in text.split(","):
		var parts := item.split("x")
		result.append(Vector2i(int(parts[0]), int(parts[1])))
	return result


# --- menu routes -----------------------------------------------------------


func _new_flow(seat_count: int, seated: bool) -> void:
	flow = FLOW_SCENE.instantiate() as GameFlow
	flow.harness_mode = true
	root.add_child(flow)
	await _frames(3)
	flow.tutorial_session.completed = true
	if seated:
		flow.router.registry.join_keyboard("K1")
		flow.router.registry.join_keyboard("K2")
		for device_id in PADS.slice(0, seat_count - 2):
			flow.router.registry.join_gamepad(device_id)
		flow.show_title()
		await _frames(2)


func _free_flow() -> void:
	if flow != null and is_instance_valid(flow):
		flow.queue_free()
	flow = null
	paused = false
	await _frames(3)


func _routes(seat_count: int, full: bool) -> void:
	await _new_flow(seat_count, false)
	if full and seat_count == 2:
		await _shot("title_join")
	flow.router.registry.join_keyboard("K1")
	flow.router.registry.join_keyboard("K2")
	for device_id in PADS.slice(0, seat_count - 2):
		flow.router.registry.join_gamepad(device_id)
	flow.show_title()
	await _frames(2)
	await _shot("title")
	flow.show_settings()
	await _frames(2)
	await _shot("settings")
	flow.settings.muted = true
	flow.settings.screen_shake = 2
	flow.settings.master_volume = 0.6
	flow.show_settings()
	await _frames(2)
	await _shot("settings_muted_shake_off")
	flow.settings.muted = false
	var categories: Array = LIBRARY_CATEGORIES if full else ["Items"]
	for category in categories:
		flow.show_library()
		await _frames(2)
		var library := flow._screen as UiLibraryScreen
		library.choose_category(category)
		library._set_zone(UiLibraryScreen.ZONE_ENTRIES)
		if category == "Items" and library.rows.size() > 4:
			library._move_entries_to(4)
		await _frames(2)
		await _shot("library_%s" % category.to_lower().replace(" ", "_"))
	flow._enter_match()
	await _frames(3)
	for seat in flow.router.registry.joined_seats():
		flow.router.registry.set_ready(int(seat.seat), false)
	await _frames(2)
	await _shot("lobby")
	if full:
		flow.room.presenter._open_overlay(LIBRARY_SCREEN, 0)
		await _frames(2)
		await _shot("lobby_help_library")
		flow.room.presenter._close_overlay()
		await _frames(2)
	await _free_flow()


# --- modes -----------------------------------------------------------------


func _modes(seat_count: int, full: bool) -> void:
	await _open_room(seat_count)
	await _shot("pugad_announcement")
	# Karera Main.
	_force(1, KARERA, NONE)
	_force(2, LAGSANAY, NONE)
	await _to_play()
	await _frames(20)
	await _shot("hud_karera")
	# Cheer cue: seat 1 out, seat 2 finished, cheering.
	if full and seat_count == 4:
		await physics_frame
		_trap(0)
		await _frames(3)
		await physics_frame
		room.race_candidate_queue.queue_goal(
			room.actors[1] as ChickenController, Engine.get_physics_frames()
		)
		await _frames(4)
		_press_cheer(0)
		_press_cheer(1)
		await _frames(3)
		await _shot("cheer_cue")
		await _frames(70)
	await _finish_race()
	await _frames(4)
	await _shot("round_result")
	if full:
		_next_round()
		await _frames(2)
		await _shot("pugad_next_is_lagsanay")
		_force(2, LAGSANAY, NONE)
		await _to_play()
		await _frames(30)
		await _shot("hud_lagsanay")
		await _pause_shots()
		await _end_round_by_traps()
		await _shot("round_result_last_cluck_lagsanay")
		_next_round()
		_force(3, KANGAROO, NONE)
		await _to_play()
		await _wait_command()
		await _shot("hud_kangaroo")
		await _end_round_by_traps()
		_next_round()
		_force(4, KARERA, LAGSANAY)
		await _to_play()
		room.bomb_taya.head_start_remaining = 0.0
		await _frames(30)
		await _shot("hud_karera_bomb_taya")
		await _finish_race()
		_next_round()
		_force(5, KARERA, KANGAROO)
		await _to_play()
		await _wait_command()
		await _shot("hud_karera_kangaroo")
		await _finish_race()
		_next_round()
		_force(6, KANGAROO, LAGSANAY)
		await _to_play()
		room.bomb_taya.head_start_remaining = 0.0
		await _wait_command()
		await _shot("hud_kangaroo_bomb_taya")
		await _end_round_by_traps()
		await _shot("round_result_last_cluck_twist")
	else:
		_next_round()
		_force(3, KANGAROO, LAGSANAY)
		await _to_play()
		room.bomb_taya.head_start_remaining = 0.0
		await _wait_command()
		await _shot("hud_kangaroo_bomb_taya")
		await _end_round_by_traps()
		await _shot("round_result_last_cluck_twist")
	await _free_flow()


## One finisher reaches the (tiny) target score: the match ends on the final result screen.
func _final_results() -> void:
	await _open_room(int(tag.split("_")[1].trim_suffix("p")))
	room.tuning.match_target_score_units = 8
	_force(1, KARERA, NONE)
	await _to_play()
	await _frames(10)
	await _finish_race(0)
	await _frames(240)
	await _shot("final_results")
	await _free_flow()


func _open_room(seat_count: int) -> void:
	await _new_flow(seat_count, true)
	flow._enter_match()
	await _frames(3)
	room = flow.room as P12ScheduledMatchRoom
	for seat in room.input_router.registry.joined_seats():
		room.input_router.registry.set_ready(int(seat.seat), true)
	room.start_match()
	await _frames(4)
	room.tuning.match_target_score_units = 100000
	room.tuning.match_results_advance_seconds = 600.0
	room.tuning.match_race_hard_cap_seconds = 600.0
	room.tuning.match_race_after_first_finish_seconds = 600.0
	room.tuning.kangaroo_telegraph_seconds = 0.8
	room.tuning.kangaroo_response_seconds = 3.0


func _force(round_number: int, main: int, twist: int) -> void:
	room.schedule.locked[round_number] = {
		"round": round_number,
		"main": main,
		"twist": twist,
		"guaranteed": false,
		"sudden_death": false,
		"twist_options": 0,
	}


func _to_play() -> void:
	room._finish_pugad_timeout()
	var edits: Array[Dictionary] = []
	room._resolve_place_edits(edits)
	var index := 0
	for seat in room.input_router.registry.joined_seats():
		var actor := room.actors[int(seat.seat)] as ChickenController
		actor.global_position = room.arena.controller_origin_from_feet(
			room.arena.spawn_feet + Vector2(150.0 * index, 0.0)
		)
		actor.velocity = Vector2.ZERO
		index += 1
	await _frames(4)


func _next_round() -> void:
	room._start_next_round()


func _wait_command() -> void:
	for _frame in 300:
		await physics_frame
		if not room.kangaroo_round.controller.active_commands().is_empty():
			break
	await _frames(6)


func _finish_race(only_seat: int = -1) -> void:
	var controller := room.race_round_controller
	if controller == null:
		return
	var candidates: Array[Dictionary] = []
	var tick := Engine.get_physics_frames()
	var index := 0
	for seat in room.input_router.registry.joined_seats():
		var finishes := index % 2 == 0 if only_seat < 0 else int(seat.seat) == only_seat
		if finishes:
			(
				candidates
				. append(
					{
						"round_id": controller.ledger.round_id,
						"seat_index": int(seat.seat),
						"kind": "goal",
						"event_id": "%s:p13:%d" % [controller.ledger.round_id, int(seat.seat)],
						"physics_tick": tick,
					}
				)
			)
		index += 1
	controller.hard_cap_seconds = 0.002
	controller.post_first_finish_seconds = 0.002
	var step := controller.advance_step(0.01, tick, candidates)
	room._apply_race_outcomes(step.new_outcomes)
	room._finish_race(str(step.end_reason))
	await _frames(3)


func _end_round_by_traps() -> void:
	await physics_frame
	for seat in room.input_router.registry.joined_seats():
		_trap(int(seat.seat))
	await _frames(6)


func _pause_shots() -> void:
	room.input_router.pause_requested.emit(0)
	await _frames(3)
	await _shot("pause")
	room.presenter._open_overlay(LIBRARY_SCREEN)
	await _frames(2)
	await _shot("pause_library")
	room.presenter._close_overlay()
	room.presenter._open_overlay(SETTINGS_SCREEN)
	await _frames(2)
	await _shot("pause_settings")
	room.presenter._close_overlay()
	room.pause_coordinator.set_paused("", -1)
	paused = false
	room.get_tree().paused = false
	room.pause_coordinator.state = PauseRecoveryCoordinator.State.RUNNING
	await _frames(3)


func _trap(seat: int) -> void:
	var record := AttributionRecord.new()
	record.kind = AttributionRecord.Kind.ELIMINATION
	record.player_seat = seat
	record.source_item_id = "trap.p13capture.%d" % seat
	record.owner_seat = -1
	record.physics_time = room.items.director.simulation_time + 0.004
	record.physics_tick = Engine.get_physics_frames()
	record.time_comparable = true
	record.round_id = room.items.director.active_round_id
	record.event_id = (
		"%s:item:%s:%d:%d" % [record.round_id, record.source_item_id, record.physics_tick, seat]
	)
	room._on_item_elimination(record)


func _press_cheer(seat: int) -> void:
	var router := room.input_router
	var event := InputEventKey.new()
	event.pressed = true
	if seat == 0:
		event.keycode = KEY_R
		event.physical_keycode = KEY_R
	else:
		event.keycode = KEY_SHIFT
		event.physical_keycode = KEY_SHIFT
		event.location = KEY_LOCATION_RIGHT
	router._handle_key(event)
	event.pressed = false
	router._handle_key(event)


# --- muted + shake off, minimum zoom, crowded stage ------------------------


func _crowded_muted_shake_off() -> void:
	await _open_room(4)
	# The coach box is a facilitator aid; the readability audit looks at the stage and the HUD.
	flow.tutorial_session.skip()
	flow.settings.muted = true
	flow.settings.screen_shake = 2
	PresentationApplier.apply(flow.settings)
	room.items.round_number = 11
	_force(12, KANGAROO, LAGSANAY)
	room.tuning.kangaroo_storm_after_commands = 1
	room.tuning.kangaroo_telegraph_seconds = 0.4
	room.tuning.kangaroo_response_seconds = 2.0
	var placed := 0
	var index := 0
	for column in range(2, 30, 2):
		for row in [6, 10, 13]:
			var result := room.items.place(
				"build.hollow_blocks.cell_1x1", Vector2i(column, row), 0, index % 4
			)
			index += 1
			if bool(result.get("allowed", false)):
				placed += 1
	await _to_play()
	room.bomb_taya.head_start_remaining = 0.0
	# Spread the four chickens across the whole arena so the camera frames the widest view.
	var seats := room.input_router.registry.joined_seats()
	for position in seats.size():
		var actor := room.actors[int(seats[position].seat)] as ChickenController
		var feet := room.arena.spawn_feet + Vector2(560.0 * position - 100.0, -64.0 * position)
		actor.global_position = room.arena.controller_origin_from_feet(feet)
		actor.velocity = Vector2.ZERO
	var two_commands := false
	Engine.time_scale = 4.0
	for _frame in 1500:
		await physics_frame
		if room.kangaroo_round.controller.active_commands().size() >= 2:
			two_commands = true
			break
	Engine.time_scale = 1.0
	await _frames(40)
	await _shot("crowded_min_zoom_muted_shake_off")
	(
		report
		. append(
			(
				(
					"Crowded stage: %d persistent pieces, Kangaroo + Bomb-Taya, Storm cards at once: %s, "
					+ "zoom %.3f (minimum %.3f), master muted=%s, shake mode=%d."
				)
				% [
					placed,
					str(two_commands),
					room.camera_rig.zoom.x,
					room.tuning.camera_zoom_min,
					str(PresentationApplier.bus_muted(&"Master")),
					PresentationApplier.shake_mode,
				]
			)
		)
	)
	await _free_flow()


# --- Parol strobe ----------------------------------------------------------


func _parol_strobe() -> void:
	tag = "1920x1080_2p"
	var lab := ITEMS_LAB_SCENE.instantiate() as P05MatchRoom
	root.add_child(lab)
	await _frames(3)
	var seats: Array[int] = [lab.input_router.registry.join_keyboard("K1")]
	seats.append(lab.input_router.registry.join_keyboard("K2"))
	for seat in seats:
		lab.input_router.registry.set_ready(seat, true)
		lab.input_router.seat_joined.emit(seat)
	lab.start_match()
	await _frames(3)
	var placed := lab.items.place(PAROL_5, Vector2i(10, 8), 0, 0)
	var crossing := lab.items.place(PAROL_5, Vector2i(14, 5), 1, 1)
	report.append(
		(
			"Parol overlap fixture: horizontal allowed=%s, vertical allowed=%s."
			% [str(placed.get("allowed")), str(crossing.get("allowed"))]
		)
	)
	lab._finish_pugad_timeout()
	var edits: Array[Dictionary] = []
	lab._resolve_place_edits(edits)
	await _frames(10)
	var rect := Rect2()
	for placement in [placed, crossing]:
		var piece := lab.items.piece_for(str(placement.get("instance_id", ""))) as HazardPiece
		if piece != null and piece.behavior != null and rect.size == Vector2.ZERO:
			rect = (piece.behavior as ParolBehavior).beam
	var transform := lab.get_viewport().get_canvas_transform()
	var scale := float(root.size.x) / 1280.0
	var screen_rect := Rect2(
		transform * rect.position * scale, rect.size * transform.get_scale() * scale
	)
	var series: Array[float] = []
	var phases: Dictionary = {}
	var behavior := (
		(lab.items.piece_for(str(placed.get("instance_id", ""))) as HazardPiece).behavior
		as ParolBehavior
	)
	var started := Time.get_ticks_msec()
	while Time.get_ticks_msec() - started < PAROL_SAMPLE_MSEC:
		await RenderingServer.frame_post_draw
		series.append(_mean_luminance(root.get_texture().get_image(), screen_rect))
		phases[str(behavior.phase)] = true
	report.append(
		(
			"Parol phases seen while sampling (%d frames over %.1f s): %s"
			% [series.size(), float(PAROL_SAMPLE_MSEC) / 1000.0, str(phases.keys())]
		)
	)
	var analysis := _flash_analysis(series)
	await _shot_named("parol_overlap_min_zoom")
	(
		report
		. append(
			(
				(
					"Parol strobe (rendered, %d frames, beam rect %s): max frame step %.3f, "
					+ "largest luminance swing %.3f, flashes in the worst 1 s window (>=10%%): %d (limit 3)."
				)
				% [
					series.size(),
					str(screen_rect),
					analysis.max_step,
					analysis.swing,
					analysis.worst_window,
				]
			)
		)
	)
	if int(analysis.worst_window) > 3:
		failures += 1
	lab.queue_free()
	await _frames(3)


func _mean_luminance(image: Image, rect: Rect2) -> float:
	var left := clampi(int(rect.position.x), 0, image.get_width() - 1)
	var top := clampi(int(rect.position.y), 0, image.get_height() - 1)
	var right := clampi(int(rect.end.x), left + 1, image.get_width())
	var bottom := clampi(int(rect.end.y), top + 1, image.get_height())
	var total := 0.0
	var count := 0
	for y in range(top, bottom, 3):
		for x in range(left, right, 3):
			var pixel := image.get_pixel(x, y)
			total += 0.2126 * pixel.r + 0.7152 * pixel.g + 0.0722 * pixel.b
			count += 1
	return total / float(maxi(count, 1))


## WCAG-style general flash count: opposing luminance changes of at least FLASH_STEP.
func _flash_analysis(series: Array[float]) -> Dictionary:
	var max_step := 0.0
	var swing := 0.0
	var reversals: Array[int] = []
	var extreme := series[0] if not series.is_empty() else 0.0
	var direction := 0
	for index in range(1, series.size()):
		max_step = maxf(max_step, absf(series[index] - series[index - 1]))
		var delta := series[index] - extreme
		swing = maxf(swing, absf(delta))
		if direction >= 0 and delta <= -FLASH_STEP:
			if direction == 1:
				reversals.append(index)
			direction = -1
			extreme = series[index]
		elif direction <= 0 and delta >= FLASH_STEP:
			if direction == -1:
				reversals.append(index)
			direction = 1
			extreme = series[index]
		elif (
			(direction == 1 and series[index] > extreme)
			or (direction == -1 and series[index] < extreme)
		):
			extreme = series[index]
	var worst := 0
	var window := 60
	for start in reversals:
		var in_window := 0
		for other in reversals:
			if other >= start and other < start + window:
				in_window += 1
		worst = maxi(worst, int(ceil(float(in_window) / 2.0)))
	return {"max_step": max_step, "swing": swing, "worst_window": worst}


# --- output ----------------------------------------------------------------


func _shot(name: String) -> void:
	await _shot_named(name)


func _shot_named(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var file_name := "%s_%s.png" % [tag, name]
	var path := output_dir.path_join("captures").path_join(file_name)
	var image := root.get_texture().get_image()
	var error := image.save_png(path)
	shots += 1
	report.append(
		(
			"%s  %dx%d  %s"
			% [
				file_name,
				image.get_width(),
				image.get_height(),
				"ok" if error == OK else "SAVE FAILED"
			]
		)
	)
	if error != OK:
		failures += 1


func _write_report() -> void:
	var file := FileAccess.open(output_dir.path_join("capture_report.txt"), FileAccess.WRITE)
	if file != null:
		file.store_string("\n".join(report) + "\n")
		file.close()
	for line in report:
		print(line)


func _frames(count: int) -> void:
	for _frame in count:
		await process_frame

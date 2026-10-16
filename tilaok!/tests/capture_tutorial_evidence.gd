extends SceneTree

## Rendered 1920x1080 (and 1280x720) captures of the guided first round at 2 and 4 seats, the
## tutorial stage with its BUILD HERE zone, a no-build attempt, a built route, the retry hint and a
## Lagsanay prompt on the same built stage. It also measures the coach box against the HUD bar and
## the Place strip, and the live text sizes. Synthetic input only; this is not a novice session.
## Writes to docs/evidence/tutorial/ (a new folder, so no tracked evidence is overwritten).

const FLOW_SCENE := preload("res://scenes/flow/game_flow.tscn")
const LIFECYCLE_SCENE := preload("res://scenes/match/p09_match_lifecycle_room.tscn")
const OUTPUT_RELATIVE := "../docs/evidence/tutorial"
const WINDOW_SIZE := Vector2i(1920, 1080)
const SMALL_SIZE := Vector2i(1280, 720)
const GOAL_PHYSICS_FRAMES := 8
const SETTLE_FRAMES := 20
const VIRTUAL_WIDTH := 1280.0
const MIN_BODY_FONT_AT_1080 := 16.0
const PIECE_CELL := Vector2i(27, 9)
const PIECE := "build.hollow_blocks.cell_1x1"

var checks := 0
var failures := 0
var flow: GameFlow
var output_dir := ""
var report := PackedStringArray()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	output_dir = ProjectSettings.globalize_path("res://").path_join(OUTPUT_RELATIVE).simplify_path()
	DirAccess.make_dir_recursive_absolute(output_dir)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(WINDOW_SIZE)
	await _session(2)
	await _session(4)
	await _retry_and_built_session()
	await _results_session(4, 4, "4p_12_results_everyone_finished")
	await _results_session(4, 1, "4p_13_results_one_finished")
	await _lagsanay_session()
	await _small_window_check()
	_write_report()
	print("TUTORIAL_CAPTURE checks=%d failures=%d dir=%s" % [checks, failures, output_dir])
	quit(1 if failures > 0 else 0)


# --- sessions ---------------------------------------------------------------------------------


func _session(seats: int) -> void:
	var room := await _new_room(seats)
	var tag := "%dp" % seats
	await _snap("%s_1_welcome_lobby" % tag)
	_measure("%s lobby" % tag, room)
	_start(room)
	await _settle()
	await _snap("%s_2_pugad_pick" % tag)
	_measure("%s pugad" % tag, room)
	room.selected_egg_by_seat[0] = 0
	room._on_match_action_pressed(0, "claim")
	await _wait_physics(3)
	await _settle()
	await _snap("%s_3_pugad_claimed" % tag)
	await _to_place(room)
	await _settle()
	await _snap("%s_4_place_build_here" % tag)
	_measure("%s place" % tag, room)
	_check_zone_visible(room, tag)
	# A no-build Play round: everyone stands on Base D and cannot reach the flag.
	room._enter_play()
	await _settle()
	_stand_on_base_d(room)
	await _wait_physics(40)
	await _settle()
	await _snap("%s_5_play_no_build_gate" % tag)
	_measure("%s play" % tag, room)
	await _free_flow()


func _retry_and_built_session() -> void:
	var room := await _new_room(2)
	_start(room)
	await _settle()
	await _to_place(room)
	room._enter_play()
	await _settle()
	room.race_round_controller.elapsed_seconds = room.tuning.match_race_hard_cap_seconds - 0.001
	await _wait_physics(4)
	await _settle()
	await _snap("2p_6_results_nobody_finished")
	room._start_next_round()
	await _settle()
	await _to_place(room)
	await _settle()
	await _snap("2p_7_place_retry_hint")
	_measure("2p retry place", room)
	# Place a piece in the zone, play, and put a chicken on top of it beside the ledge.
	room.items.reset_match()
	room.items.enter_place()
	var placed := room.items.place(PIECE, PIECE_CELL, 0, 0)
	_check(bool(placed.allowed), "capture piece placed in the zone")
	room._enter_play()
	await _settle()
	var piece_top := float(PIECE_CELL.y) * room.tuning.grid_cell_wu
	for seat_index in room.actors.keys():
		var actor := room.actors[seat_index] as ChickenController
		actor.global_position = Vector2(
			(float(PIECE_CELL.x) + 0.5) * room.tuning.grid_cell_wu,
			piece_top - room.tuning.body_height_wu * 0.5
		)
		break
	await _wait_physics(10)
	await _snap("2p_8_play_built_route")
	await _free_flow()


## A finished round with `finishers` seats at the flag, to check the Results box against the
## outcome rows and award lines.
func _results_session(seats: int, finishers: int, file_name: String) -> void:
	var room := await _new_room(seats)
	_start(room)
	await _settle()
	await _to_place(room)
	room._enter_play()
	await _settle()
	var goal := room.goal_area.global_position
	var moved := 0
	for seat_index in room.actors.keys():
		if moved >= finishers:
			break
		(room.actors[seat_index] as ChickenController).global_position = goal
		moved += 1
	await _wait_physics(GOAL_PHYSICS_FRAMES)
	if finishers < seats:
		room.race_round_controller.elapsed_seconds = (
			room.tuning.match_race_hard_cap_seconds - 0.001
		)
		await _wait_physics(6)
	await _settle()
	await _snap(file_name)
	_measure(file_name, room)
	var results := room.presenter.result_screen
	var prompt := room.presenter.tutorial_prompt
	if prompt.visible:
		var box := (prompt.get_node("Anchor/Box") as Control).get_global_rect()
		for index in range(1, 5):
			var row := results.get_node("%%Outcome%d" % index) as Control
			if row.is_visible_in_tree():
				var hit := box.intersects(row.get_global_rect(), false)
				report.append("    vs Outcome%d: %s" % [index, "OVERLAP" if hit else "clear"])
				_check(not hit, "%s: box clear of Outcome%d" % [file_name, index])
		for index in range(1, 11):
			var award := results.get_node("%%Award%d" % index) as Control
			if award.is_visible_in_tree():
				var hit_award := box.intersects(award.get_global_rect(), false)
				report.append("    vs Award%d: %s" % [index, "OVERLAP" if hit_award else "clear"])
				_check(not hit_award, "%s: box clear of Award%d" % [file_name, index])
	await _free_flow()


func _lagsanay_session() -> void:
	flow = FLOW_SCENE.instantiate() as GameFlow
	flow.match_scene = LIFECYCLE_SCENE
	root.add_child(flow)
	await _wait_frames(10)
	_press(KEY_E)
	await _wait_frames(3)
	_press(KEY_E)
	await _wait_frames(5)
	var room := flow.room
	_join_k2(room)
	flow.tutorial_session.mark_completed()
	_start(room)
	await _settle()
	await _to_place(room)
	room.items.reset_match()
	room.items.enter_place()
	room.items.place(PIECE, PIECE_CELL, 0, 0)
	room._enter_play()
	await _settle()
	var life := room as P09MatchLifecycleRoom
	life.cumulative_score_units = {0: 40, 1: 40}
	life.lifecycle.completed_round = 11
	var decision := life.lifecycle.finish_round(12, {0: 40, 1: 40}, 200, 12)
	life._start_sudden_death(decision)
	await _settle()
	await _snap("2p_9_lagsanay_prompt_on_built_stage")
	_measure("2p lagsanay", room)
	await _free_flow()


func _small_window_check() -> void:
	DisplayServer.window_set_size(SMALL_SIZE)
	await _wait_frames(10)
	var room := await _new_room(4)
	await _settle()
	await _snap("4p_10_welcome_1280x720", SMALL_SIZE)
	_start(room)
	await _settle()
	await _to_place(room)
	await _settle()
	await _snap("4p_11_place_1280x720", SMALL_SIZE)
	_measure("4p place 1280x720", room)
	await _free_flow()
	DisplayServer.window_set_size(WINDOW_SIZE)


# --- helpers ----------------------------------------------------------------------------------


func _new_room(seats: int) -> P05MatchRoom:
	flow = FLOW_SCENE.instantiate() as GameFlow
	flow.match_scene = GameFlow.MATCH_SCENE
	root.add_child(flow)
	await _wait_frames(10)
	_press(KEY_E)
	await _wait_frames(3)
	_press(KEY_E)
	await _wait_frames(5)
	var room := flow.room
	_join_k2(room)
	for device_id in range(900, 900 + maxi(0, seats - 2)):
		var seat := room.input_router.registry.join_gamepad(device_id)
		if seat >= 0:
			room.input_router.seat_joined.emit(seat)
	await _wait_frames(5)
	return room


func _press(key: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = key
		event.physical_keycode = key
		event.pressed = pressed
		flow.router._handle_key(event)


func _join_k2(room: P05MatchRoom) -> void:
	var seat := room.input_router.registry.join_keyboard("K2")
	if seat >= 0:
		room.input_router.seat_joined.emit(seat)


func _start(room: P05MatchRoom) -> void:
	for seat in room.input_router.registry.joined_seats():
		room.input_router.registry.set_ready(int(seat.seat), true)
	room.start_match()


func _to_place(room: P05MatchRoom) -> void:
	var assignments := {}
	for seat in room.input_router.registry.joined_seats():
		assignments[int(seat.seat)] = str(room.egg_pool[int(seat.seat)].egg_id)
	room.assignments = assignments
	room._enter_place()
	await _wait_frames(2)


func _stand_on_base_d(room: P05MatchRoom) -> void:
	var rect := Rect2()
	for spec in room.arena.surface_specs:
		if str(spec.id) == "arena.base_d":
			rect = spec.rect
	var index := 0
	for seat_index in room.actors.keys():
		var actor := room.actors[seat_index] as ChickenController
		actor.global_position = Vector2(
			rect.position.x + 40.0 + float(index) * 52.0,
			rect.position.y - room.tuning.body_height_wu * 0.5
		)
		index += 1


func _check_zone_visible(room: P05MatchRoom, tag: String) -> void:
	var marker: BuildHereMarker
	for child in room.world_layer.get_children():
		if child is BuildHereMarker:
			marker = child
	_check(marker != null and marker.visible, "%s: BUILD HERE marker is visible in Place" % tag)


## Measures the coach box against the HUD bar and the Place strip, and its text sizes at 1080p.
func _measure(label: String, room: P05MatchRoom) -> void:
	var presenter := room.presenter
	var prompt := presenter.tutorial_prompt
	var scale := float(root.get_window().size.x) / VIRTUAL_WIDTH
	if not prompt.visible:
		report.append("%s: box hidden" % label)
		return
	var box := prompt.get_node("Anchor/Box") as Control
	var rect := box.get_global_rect()
	report.append(
		(
			"%s: box rect (virtual) pos=%s size=%s | at window %.2fx pos=%s size=%s"
			% [label, rect.position, rect.size, scale, rect.position * scale, rect.size * scale]
		)
	)
	var others := {
		"HudBar": presenter.play_hud.get_node("HudBar") as Control,
	}
	if presenter.place_overlay.visible:
		for index in range(1, 5):
			others["SeatStatus%d" % index] = presenter.place_overlay.get_node(
				"%%SeatStatus%d" % index
			)
		others["GhostStatus"] = presenter.place_overlay.get_node("%GhostStatus")
		others["ReasonToast"] = presenter.place_overlay.get_node("%ReasonToast")
		others["PhaseBanner"] = presenter.place_overlay.get_node("%PhaseBanner")
		others["Countdown"] = presenter.place_overlay.get_node("%Countdown")
	elif presenter.pugad_overlay.visible:
		others["PhaseBanner"] = presenter.pugad_overlay.get_node("%PhaseBanner")
		others["Countdown"] = presenter.pugad_overlay.get_node("%Countdown")
		others["LostClaimToast"] = presenter.pugad_overlay.get_node("%LostClaimToast")
		for index in range(1, 7):
			others["Egg%d" % index] = presenter.pugad_overlay.get_node("%%Egg%d" % index)
	for other_name in others:
		var other := others[other_name] as Control
		if other == null or not other.is_visible_in_tree():
			continue
		var overlaps := rect.intersects(other.get_global_rect(), false)
		report.append("    vs %s: %s" % [other_name, "OVERLAP" if overlaps else "clear"])
		_check(not overlaps, "%s: box does not overlap %s" % [label, other_name])
	for label_name in ["StepLabel", "BodyLabel", "SkipText", "Tag"]:
		var text_label := prompt.get_node("%%%s" % label_name) as Label
		var size_px := float(text_label.get_theme_font_size("font_size")) * scale
		report.append(
			(
				"    %s font = %.1f px at this window (text=%d chars)"
				% [label_name, size_px, text_label.text.length()]
			)
		)
		if label_name == "BodyLabel" and root.get_window().size.x >= 1920:
			_check(size_px >= MIN_BODY_FONT_AT_1080, "%s: body text >= 16 px at 1080p" % label)


func _snap(file_name: String, expected := WINDOW_SIZE) -> void:
	await _wait_frames(3)
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var path := output_dir.path_join(
		"%s_%dx%d.png" % [file_name, image.get_width(), image.get_height()]
	)
	_check(image.save_png(path) == OK, "captured %s at %s" % [file_name, image.get_size()])
	if expected.x > 0 and image.get_width() < expected.x - 8:
		report.append(
			(
				"note: %s captured at %s (window smaller than requested)"
				% [file_name, image.get_size()]
			)
		)


func _settle() -> void:
	await _wait_frames(SETTLE_FRAMES)


func _free_flow() -> void:
	if flow != null and is_instance_valid(flow):
		flow.queue_free()
	flow = null
	paused = false
	await _wait_frames(3)


func _write_report() -> void:
	var file := FileAccess.open(output_dir.path_join("layout_measurements.txt"), FileAccess.WRITE)
	if file == null:
		_check(false, "measurements can be written")
		return
	file.store_string(
		(
			"Measured by capture_tutorial_evidence.gd (Godot %s). Synthetic input.\n%s\n"
			% [Engine.get_version_info().string, "\n".join(report)]
		)
	)
	file.close()


func _wait_frames(count: int) -> void:
	for _frame in range(count):
		await process_frame


func _wait_physics(count: int) -> void:
	for _frame in range(count):
		await physics_frame


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("TUTORIAL_CAPTURE FAIL: " + message)
	else:
		print("PASS ", message)

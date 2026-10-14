extends SceneTree

const ROUND_SCENE := preload("res://scenes/ui/screens/round_result_screen.tscn")
const MATCH_SCENE := preload("res://scenes/ui/screens/match_result_screen.tscn")
const MOTION_NORMAL := PresentationSettings.RESULT_REVEAL_NORMAL
const MOTION_REDUCED := PresentationSettings.RESULT_REVEAL_REDUCED
const MOTION_OFF := PresentationSettings.RESULT_REVEAL_OFF
const SEAT_COLORS := [Color("#f2c14e"), Color("#63a7ff"), Color("#f07c6c"), Color("#89c77b")]

var output_dir := ""
var _capture_failures := 0
var _capture_report := PackedStringArray()
var _capture_viewport: SubViewport


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Scoreboard screenshots require a rendered Godot window.")
		quit(2)
		return
	output_dir = ProjectSettings.globalize_path("res://../docs/evidence/scoreboard").simplify_path()
	DirAccess.make_dir_recursive_absolute(output_dir)
	_capture_report.append("Godot %s · %s" % [Engine.get_version_info().string, OS.get_name()])
	_capture_report.append(
		"Synthetic result-screen fixture captures; no physical-device or human review."
	)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	_capture_viewport = SubViewport.new()
	_capture_viewport.size = Vector2i(1280, 720)
	_capture_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_capture_viewport)
	var prompt_map := UiPromptMap.new()
	prompt_map.glyphs = {"results_ready|k1": "F", "results_ready|gamepad": "South"}
	prompt_map.action_names = {"results_ready": "Ready"}

	await _capture_round(
		"02_player_mixed_awards_1280x720.png",
		Vector2i(1280, 720),
		_make_seats([0, 1]),
		_make_round_model("mixed-2p", _mixed_rows(), _award_rows()),
		MOTION_NORMAL,
		0.42,
		false,
		prompt_map
	)
	await _capture_round(
		"03_player_placement_1920x800.png",
		Vector2i(1920, 800),
		_make_seats([0, 2, 3]),
		_make_round_model("placement-3p", _placement_rows(), _placement_awards()),
		MOTION_OFF,
		0.0,
		false,
		prompt_map
	)
	await _capture_round(
		"04_player_no_score_1280x720.png",
		Vector2i(1280, 720),
		_make_seats([0, 1, 2, 3]),
		_make_round_model("no-score-4p", _zero_rows(4), [], true),
		MOTION_OFF,
		0.0,
		false,
		prompt_map
	)
	await _capture_round(
		"fractional_eighths_1920x800.png",
		Vector2i(1920, 800),
		_make_seats([0, 1, 2]),
		_make_round_model("fractional-3p", _fractional_rows(), _fractional_awards()),
		MOTION_OFF,
		0.0,
		false,
		prompt_map
	)
	await _capture_round(
		"mid_reveal_1920x800.png",
		Vector2i(1920, 800),
		_make_seats([0, 1]),
		_make_round_model("mid-reveal", _mixed_rows(), _award_rows()),
		MOTION_NORMAL,
		0.38,
		false,
		prompt_map
	)
	await _capture_round(
		"settled_1920x800.png",
		Vector2i(1920, 800),
		_make_seats([0, 1]),
		_make_round_model("settled", _mixed_rows(), _award_rows()),
		MOTION_NORMAL,
		0.0,
		true,
		prompt_map
	)
	await _capture_round(
		"reduced_motion_1280x720.png",
		Vector2i(1280, 720),
		_make_seats([0, 1]),
		_make_round_model("reduced", _mixed_rows(), _award_rows()),
		MOTION_REDUCED,
		0.0,
		false,
		prompt_map
	)
	await _capture_round(
		"four_player_above_target_1920x1080.png",
		Vector2i(1920, 1080),
		_make_seats([0, 1, 2, 3]),
		_make_round_model("above-target-4p", _varied_four_rows(), _award_rows()),
		MOTION_OFF,
		0.0,
		false,
		prompt_map
	)
	await _capture_match(
		"round_12_winner_below_target_1920x1080.png",
		Vector2i(1920, 1080),
		_make_final_model("round12", _round12_rows(), 2, "P3 wins after round 12.", ""),
		MOTION_OFF
	)
	await _capture_match(
		"tied_sudden_death_winner_callout_1280x720.png",
		Vector2i(1280, 720),
		_make_final_model(
			"sudden-death-tie",
			_tied_rows(),
			3,
			"Last Cluck resolves the tied leaders.",
			"Last Cluck! P4 wins the tied sudden death by the latest recorded elimination time."
		),
		MOTION_OFF
	)
	var summary := (
		"SCOREBOARD_CAPTURE_SUMMARY failures=%d output=%s" % [_capture_failures, output_dir]
	)
	_capture_report.append(summary)
	var report_file := FileAccess.open(
		output_dir.path_join("scoreboard_capture_run.txt"), FileAccess.WRITE
	)
	if report_file != null:
		report_file.store_string("\n".join(_capture_report) + "\n")
		report_file.close()
	print(summary)
	quit(1 if _capture_failures > 0 else 0)


func _capture_round(
	file_name: String,
	viewport_size: Vector2i,
	seats: Array[Dictionary],
	model: MatchResultsViewModel,
	motion_mode: int,
	wait_seconds: float,
	settle_now: bool,
	prompt_map: UiPromptMap
) -> void:
	await _set_viewport(viewport_size)
	var screen := ROUND_SCENE.instantiate() as UiRoundResultScreen
	_capture_viewport.add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await process_frame
	screen.bind_live(model, seats, {}, 8.0, 8.0, "k1", prompt_map, motion_mode)
	if settle_now:
		screen.chart().settle()
	elif wait_seconds > 0.0:
		await create_timer(wait_seconds).timeout
	await _save_capture(file_name, viewport_size)
	screen.queue_free()
	await process_frame


func _capture_match(
	file_name: String, viewport_size: Vector2i, model: MatchResultsViewModel, motion_mode: int
) -> void:
	await _set_viewport(viewport_size)
	var screen := MATCH_SCENE.instantiate() as UiMatchResultScreen
	_capture_viewport.add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await process_frame
	screen.bind_final_match(model, motion_mode)
	await _save_capture(file_name, viewport_size)
	screen.queue_free()
	await process_frame


func _set_viewport(viewport_size: Vector2i) -> void:
	_capture_viewport.size = viewport_size
	await process_frame
	await process_frame


func _save_capture(file_name: String, expected_size: Vector2i) -> void:
	await RenderingServer.frame_post_draw
	var image := _capture_viewport.get_texture().get_image()
	var path := output_dir.path_join(file_name)
	var save_result := image.save_png(path)
	if save_result != OK or image.get_size() != expected_size:
		_capture_failures += 1
		var message := (
			"CAPTURE_FAILED %s actual=%s expected=%s error=%s"
			% [file_name, image.get_size(), expected_size, save_result]
		)
		_capture_report.append(message)
		push_error(message)
	else:
		var message := "SCOREBOARD_CAPTURE %s %s" % [file_name, image.get_size()]
		_capture_report.append(message)
		print(message)


func _make_seats(indices: Array[int]) -> Array[Dictionary]:
	var seats: Array[Dictionary] = []
	for seat_index in indices:
		(
			seats
			. append(
				{
					"seat": seat_index,
					"identity": seat_index + 1,
					"shape": PlayerSeatRegistry.SHAPES[seat_index],
					"color": SEAT_COLORS[seat_index],
					"joined": true,
					"connected": true,
					"device_kind": "keyboard",
					"device_id": -1,
					"keyboard_layout": "K1" if seat_index == 0 else "K2",
					"ready": false,
				}
			)
		)
	return seats


func _make_round_model(
	identity: String, rows: Array[Dictionary], awards: Array[Dictionary], no_score := false
) -> MatchResultsViewModel:
	var model := MatchResultsViewModel.new()
	model.round_number = 12 if identity == "round12" else 7
	model.diagnostic_label = "Round ended after all runners resolved."
	model.deadline_explanation = "Round clock ended; all outcomes are final."
	model.suppression_reason = (
		"No points this round: nobody reached the goal." if no_score else ""
	)
	model.score_presentation_id = identity
	model.target_score_units = 80
	model.score_presentation = {"seats": rows}
	model.award_rows = awards
	for row in rows:
		(
			model
			. per_seat_outcomes
			. append(
				{
					"seat_index": int(row.seat_index),
					"identity": int(row.identity),
					"shape": str(row.shape),
					"outcome": "Reached goal." if not no_score else "No finish this round.",
					"total_units": int(row.units),
					"score_delta_units": int(row.delta_units),
					"score_delta_text": ScoreFormat.format_units(int(row.delta_units)),
				}
			)
		)
	return model


func _make_final_model(
	identity: String,
	rows: Array[Dictionary],
	winner_seat: int,
	outcome: String,
	last_cluck_text: String
) -> MatchResultsViewModel:
	var model := MatchResultsViewModel.new()
	model.final_seats = _make_seats([0, 1, 2, 3])
	model.winner_seat = winner_seat
	model.final_outcome_text = outcome
	model.last_cluck_explanation = last_cluck_text
	model.score_presentation_id = identity
	model.target_score_units = 80
	model.score_presentation = {"seats": rows}
	return model


func _row(
	seat_index: int, units: int, segments: Array[Dictionary], delta_units: int, status: String
) -> Dictionary:
	return {
		"seat_index": seat_index,
		"identity": seat_index + 1,
		"shape": PlayerSeatRegistry.SHAPES[seat_index],
		"units": units,
		"delta_units": delta_units,
		"delta_text": ("+" if delta_units > 0 else "") + ScoreFormat.format_units(delta_units),
		"status": status,
		"segments": segments,
	}


func _segment(key: String, units: int, reveal := false) -> Dictionary:
	return {"key": key, "title": key.capitalize(), "units": units, "reveal": reveal}


func _mixed_rows() -> Array[Dictionary]:
	return [
		_row(
			0,
			39,
			[
				_segment("previous_total", 23),
				_segment("tapos", 8, true),
				_segment("una", 2, true),
				_segment("bayani", 4, true),
				_segment("patibong", 2, true),
			],
			16,
			"Reached goal."
		),
		_row(
			1,
			35,
			[
				_segment("previous_total", 17),
				_segment("tapos", 8, true),
				_segment("bawi", 6, true),
				_segment("barya", 4, true),
			],
			18,
			"Reached goal."
		),
	]


func _placement_rows() -> Array[Dictionary]:
	return [
		_row(0, 56, [_segment("previous_total", 48), _segment("placement", 8)], 8, "1st place"),
		_row(2, 36, [_segment("previous_total", 32), _segment("placement", 4)], 4, "2nd place"),
		_row(3, 26, [_segment("previous_total", 24), _segment("placement", 2)], 2, "3rd place"),
	]


func _zero_rows(count: int) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for seat_index in count:
		rows.append(_row(seat_index, 0, [], 0, "No score"))
	return rows


func _fractional_rows() -> Array[Dictionary]:
	return [
		_row(
			0,
			37,
			[_segment("previous_total", 36), _segment("placement", 1)],
			1,
			"Tie-averaged placement · 0.125"
		),
		_row(
			1,
			43,
			[_segment("previous_total", 40), _segment("placement", 3)],
			3,
			"Tie-averaged placement · 0.375"
		),
		_row(
			2,
			55,
			[_segment("previous_total", 48), _segment("placement", 7)],
			7,
			"Tie-averaged placement · 0.875"
		),
	]


func _varied_four_rows() -> Array[Dictionary]:
	return [
		_row(
			0,
			96,
			[
				_segment("previous_total", 56),
				_segment("tapos", 8),
				_segment("una", 2),
				_segment("bayani", 6),
				_segment("patibong", 8),
				_segment("bawi", 12),
				_segment("barya", 4),
			],
			40,
			"Above target"
		),
		_row(1, 80, [_segment("previous_total", 80)], 0, "At target"),
		_row(2, 63, [_segment("previous_total", 63)], 0, "In contention"),
		_row(3, 8, [_segment("previous_total", 8)], 0, "One point"),
	]


func _round12_rows() -> Array[Dictionary]:
	return [
		_row(0, 72, [_segment("previous_total", 72)], 0, "Final score"),
		_row(1, 64, [_segment("previous_total", 64)], 0, "Final score"),
		_row(2, 77, [_segment("previous_total", 77)], 0, "WINNER"),
		_row(3, 56, [_segment("previous_total", 56)], 0, "Final score"),
	]


func _tied_rows() -> Array[Dictionary]:
	return [
		_row(0, 56, [_segment("previous_total", 56)], 0, "Final score"),
		_row(1, 80, [_segment("previous_total", 80)], 0, "Tied leader"),
		_row(2, 64, [_segment("previous_total", 64)], 0, "Final score"),
		_row(3, 80, [_segment("previous_total", 80)], 0, "WINNER"),
	]


func _award_rows() -> Array[Dictionary]:
	return [
		_award(0, "tapos", "Tapos", 8, "Reached the goal."),
		_award(1, "tapos", "Tapos", 8, "Reached the goal."),
		_award(0, "una", "Una", 2, "Finished first."),
		_award(1, "bawi", "Bawi", 6, "Closed the score gap."),
		_award(0, "bayani", "Bayani", 4, "Helped another player finish."),
		_award(1, "barya", "Barya", 4, "Collected a Barya coin."),
	]


func _placement_awards() -> Array[Dictionary]:
	return [
		_award(0, "placement", "1st place", 8, "First survivor."),
		_award(2, "placement", "2nd place", 4, "Second survivor."),
		_award(3, "placement", "3rd place", 2, "Third survivor."),
	]


func _fractional_awards() -> Array[Dictionary]:
	return [
		_award(0, "placement", "Tie-averaged placement", 1, "One eighth-point placement."),
		_award(1, "placement", "Tie-averaged placement", 3, "Three eighth-point placement."),
		_award(2, "placement", "Tie-averaged placement", 7, "Seven eighth-point placement."),
	]


func _award(seat: int, key: String, title: String, units: int, explanation: String) -> Dictionary:
	return {
		"seat_index": seat,
		"key": key,
		"title": title,
		"units": units,
		"score_text": "+" + ScoreFormat.format_units(units),
		"explanation": explanation,
	}

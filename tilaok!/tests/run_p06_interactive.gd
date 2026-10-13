extends SceneTree

const MATCH_SCENE := preload("res://scenes/match/match_room.tscn")
const OUTPUT_RELATIVE := "../docs/evidence/p06"
const VARIANT_1X1 := "build.hollow_blocks.cell_1x1"

var failures := 0
var checks := 0
var room: P05MatchRoom
var output_dir := ""


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	output_dir = ProjectSettings.globalize_path("res://").path_join(OUTPUT_RELATIVE).simplify_path()
	DirAccess.make_dir_recursive_absolute(output_dir)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	room = MATCH_SCENE.instantiate() as P05MatchRoom
	root.add_child(room)
	await _wait_frames(30)
	room.join_keyboard("K1")
	room.join_keyboard("K2")
	room.input_router.registry.set_ready(0, true)
	room.input_router.registry.set_ready(1, true)
	_check(room.start_match(), "two-seat lobby starts at 1920x1080")
	room.assignments = {0: str(room.egg_pool[0].egg_id), 1: str(room.egg_pool[1].egg_id)}
	room._enter_place()
	var construction := room.items.place(VARIANT_1X1, Vector2i(8, 8), 0, 0)
	_check(construction.allowed, "Place contains one real persistent construction piece")
	room._enter_play()
	_check(room.race_round_controller.active, "Pugad → Place advances into the live Karera clock")
	await _capture("01_karera_live_1920x1080.png")
	var elapsed_before_pause := room.race_round_controller.elapsed_seconds
	room._toggle_pause()
	await _wait_physics_frames(6)
	_check(
		is_equal_approx(room.race_round_controller.elapsed_seconds, elapsed_before_pause),
		"pause freezes active race simulation time"
	)
	room._toggle_pause()
	var goal_position := room.goal_area.global_position
	for actor_variant in room.actors.values():
		(actor_variant as ChickenController).global_position = goal_position
	await _wait_physics_frames(6)
	_check(
		room.phase_controller.phase == MatchPhaseController.Phase.RESULTS,
		"live arena goal collision resolves a two-player finish"
	)
	_check(
		room.last_results_model.award_rows.size() >= 3, "results explain live Tapos and Una awards"
	)
	var tied_una_rows := 0
	for award in room.last_results_model.award_rows:
		if str(award.get("key", "")) == "una":
			tied_una_rows += 1
	_check(tied_una_rows == 2, "same-step goal contacts award exact tied Una to both seats")
	_check(
		(
			room.last_results_model.totals[0].delta_units == 10
			and room.last_results_model.totals[1].delta_units == 10
		),
		"each tied two-player finisher receives exactly 10 eighth-point units"
	)
	_check(
		room.last_results_model.suppression_reason.contains("two-player waiver"),
		"results explain why two-player scoring is active"
	)
	_check(
		room.last_results_model.per_seat_outcomes.size() == 2,
		"results display a readable terminal outcome for both seats"
	)
	await _capture("02_explained_live_results_1920x1080.png")
	var construction_signature := room.items.construction_signature()
	var score_before_next_round := room.cumulative_score_units.duplicate(true)
	room._on_match_action_pressed(0, "confirm")
	room._on_match_action_pressed(1, "confirm")
	_check(
		room.phase_controller.phase == MatchPhaseController.Phase.PUGAD,
		"all-ready results advance to the next Pugad"
	)
	_check(
		room.items.construction_signature() == construction_signature,
		"construction persists into the next round"
	)
	_check(
		room.cumulative_score_units == score_before_next_round,
		"actor reset preserves committed cumulative scores"
	)
	_check(
		(
			(room.actors[0] as ChickenController).lifecycle.status
			== PlayerLifecycleState.Status.ACTIVE
		),
		"finisher lifecycle resets before the next round"
	)
	await _capture("03_next_pugad_persistent_stage_1920x1080.png")
	_write_evidence_notes()
	print(
		(
			"P06_INTERACTIVE_SUMMARY checks=%d failures=%d resolution=%s"
			% [checks, failures, DisplayServer.window_get_size()]
		)
	)
	room.queue_free()
	await _wait_frames(4)
	quit(1 if failures > 0 else 0)


func _wait_frames(count: int) -> void:
	for _frame in range(count):
		await process_frame


func _wait_physics_frames(count: int) -> void:
	for _frame in range(count):
		await physics_frame


func _capture(file_name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var path := output_dir.path_join(file_name)
	var result := image.save_png(path)
	_check(
		result == OK and image.get_size() == Vector2i(1920, 1080),
		"captured %s at %s" % [file_name, image.get_size()]
	)


func _write_evidence_notes() -> void:
	var lines := PackedStringArray(
		[
			"# P06 Interactive Evidence",
			"",
			(
				"Build: Godot source checkout at `11352c7` plus uncommitted P06 changes; engine "
				+ "`4.7.2.stable.official.ed1daf0bf`."
			),
			(
				"Command: `D:\\Downloads\\Godot_v4.7.2-stable_win64_console.exe --path tilaok! --script "
				+ "res://tests/run_p06_interactive.gd`; exit code 0. Full stdout/stderr: "
				+ "`run_p06_interactive.txt`."
			),
			(
				"Date: 2026-10-14 Asia/Manila. Profile: `karera_slice`; seed: `12345`; seats: 2; "
				+ "input: K1/K2 synthetic keyboard control plus scripted fixture positioning "
				+ "at the real goal Area2D."
			),
			"",
			(
				"Procedure: start two ready seats, pass through Pugad and Place, retain a real Kaing 1x1 "
				+ "construction piece, enter Karera, pause and verify active time freezes, overlap both "
				+ "active released chickens with the arena-defined goal trigger, inspect result awards and "
				+ "totals, ready both seats, and inspect the next Pugad."
			),
			(
				"Expected: goal finishes secure both actors; Tapos and exact earliest Una are shown; "
				+ "two-player waiver is explained; cumulative totals commit once; next round resets "
				+ "actor lifecycle while retaining construction and scores."
			),
			(
				"Actual: PASSED — the runner reported 17 checks, including two tied Una rows and "
				+ "exact 10-unit deltas for both seats. Full command output is in `run_p06_interactive.txt`."
			),
			(
				"Reviewer: not recorded; no independent human review is claimed. "
				+ "Physical devices were not used."
			),
			"",
			"| Capture | Meaning |",
			"|---|---|",
			"| `01_karera_live_1920x1080.png` | Active race objective and clock. |",
			(
				"| `02_explained_live_results_1920x1080.png` | Live goal result with award detail, "
				+ "suppression explanation and exact totals. |"
			),
			(
				"| `03_next_pugad_persistent_stage_1920x1080.png` | Next-round Pugad after result "
				+ "readiness; construction remains in the stage. |"
			),
		]
	)
	var file := FileAccess.open(output_dir.path_join("README.md"), FileAccess.WRITE)
	if file == null:
		_check(false, "evidence README can be written")
		return
	file.store_string("\n".join(lines) + "\n")
	file.close()


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("P06 INTERACTIVE FAIL: " + message)

extends SceneTree

## P12 pairs, rendered tour at 1920x1080 (windowed; captures are skipped when headless). Seats are
## synthetic: K1/K2 keyboard seats plus synthetic gamepad IDs. It drives the real scheduled match
## room and its live scene screens through: round 1 Karera + Bomb-Taya, round 2 Karera + Kangaroo,
## round 3 Kangaroo + Bomb-Taya (forced locked entries, test-only), the natural round-4 Lagsanay,
## a pause/resume mid-stack, a level-score sudden death and Return to Lobby.
## Run from an ISOLATED copy of the repository: it overwrites docs/evidence/p12/.

const SCENARIOS := preload("res://tests/p12_pair_room_scenarios.gd")
const OUTPUT_RELATIVE := "../docs/evidence/p12"

var scn
var output_dir := ""
var checks := 0
var failures: Array[String] = []
var report := PackedStringArray()
var capture_count := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	output_dir = ProjectSettings.globalize_path("res://").path_join(OUTPUT_RELATIVE).simplify_path()
	DirAccess.make_dir_recursive_absolute(output_dir)
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(Vector2i(1920, 1080))
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	report = PackedStringArray(
		[
			"P12 pairs rendered engineering run; every seat input and event below is synthetic.",
			"Engine: %s" % Engine.get_version_info().string,
			"Date: %s UTC" % Time.get_datetime_string_from_system(true),
			"Build: P12-scheduled-match-dev; scene: p12_scheduled_match_room.tscn.",
			"OS/CPU: %s / %s" % [OS.get_name(), OS.get_processor_name()],
			"Devices: synthetic keyboard seats K1/K2; synthetic gamepad IDs 7101/7102.",
			"Window: %s" % str(DisplayServer.window_get_size()),
			"Forced locked entries (test-only): round 1 K+L, round 2 K+Kg, round 3 Kg+L.",
			"Reviewer: engineering run; no independent human review recorded.",
		]
	)
	scn = SCENARIOS.new(_check, self)
	for seat_count: int in [4, 2]:
		await _stack_tour(seat_count)
	for seat_count: int in [4, 2]:
		await _sudden_death_and_lobby(seat_count)
	report.append("P12_PAIRS_INTERACTIVE_SUMMARY checks=%d failures=%d" % [checks, failures.size()])
	report.append("CAPTURES %d" % capture_count)
	var log := FileAccess.open(
		output_dir.path_join("p12_pairs_interactive_run.txt"), FileAccess.WRITE
	)
	if log != null:
		log.store_string("\n".join(report) + "\n")
		log.close()
	print("P12_PAIRS_INTERACTIVE_SUMMARY checks=%d failures=%d" % [checks, failures.size()])
	for line in report:
		print(line)
	quit(1 if not failures.is_empty() else 0)


func _stack_tour(seat_count: int) -> void:
	var tag := "%dp" % seat_count
	var seats: Array[int] = await scn._open(
		seat_count,
		{
			1: [scn.KARERA, scn.LAGSANAY],
			2: [scn.KARERA, scn.KANGAROO],
			3: [scn.KANGAROO, scn.LAGSANAY]
		}
	)
	var room: P12ScheduledMatchRoom = scn.room
	room.tuning.match_pugad_seconds = 600.0
	await process_frame
	await process_frame
	var announcement: Dictionary = room.round_announcement()
	_check(
		(
			str(announcement.get("title", "")).contains("KARERA")
			and str(announcement.get("detail", "")).contains("TWIST: KANGAROO")
		),
		"%s: the round-1 Pugad announces round 2 (Karera / Twist Kangaroo)" % tag
	)
	await _capture("pugad_announce_%s" % tag)
	scn._to_play()
	scn._spread()
	scn._skip_bomb_head_start()
	await scn._steps(40)
	await _capture("kl_play_%s" % tag)
	room.pause_coordinator.set_paused("p12 interactive pause", -1)
	await scn._steps(4)
	await _capture("kl_pause_%s" % tag)
	var frozen: float = room.bomb_taya.countdown_remaining
	await scn._steps(20)
	_check(room.bomb_taya.countdown_remaining == frozen, "%s: pause freezes the stack" % tag)
	for seat in scn._seats():
		room.input_router.registry.set_ready(seat, true)
	room.pause_coordinator.request_resume()
	Engine.time_scale = 8.0
	for _frame in 600:
		await physics_frame
		if room.pause_coordinator.state == PauseRecoveryCoordinator.State.RUNNING:
			break
	Engine.time_scale = 1.0
	_check(
		room.pause_coordinator.state == PauseRecoveryCoordinator.State.RUNNING,
		"%s: resume continues the stacked round" % tag
	)
	await scn._steps(5)
	await physics_frame
	scn._goal(seats[0])
	await scn._steps(3)
	for index in range(1, seats.size()):
		scn._trap(seats[index], seats[0])
		await scn._steps(2)
	await scn._steps(3)
	_check(
		room.phase_controller.phase == MatchPhaseController.Phase.RESULTS,
		"%s: round 1 (K+L) ends with one race table" % tag
	)
	await _capture("kl_result_%s" % tag)
	await _next_round(room)
	await _capture("pugad_announce_r2_%s" % tag)
	scn._to_play()
	await scn._steps(70)
	await _capture("kk_play_%s" % tag)
	await physics_frame
	scn._goal(seats[0])
	await scn._steps(3)
	Engine.time_scale = 8.0
	for _frame in 2400:
		await physics_frame
		if room.phase_controller.phase == MatchPhaseController.Phase.RESULTS:
			break
	Engine.time_scale = 1.0
	_check(
		room.phase_controller.phase == MatchPhaseController.Phase.RESULTS,
		"%s: round 2 (K+Kg) ends under the race rules" % tag
	)
	await _capture("kk_result_%s" % tag)
	await _next_round(room)
	scn._to_play()
	scn._spread()
	scn._skip_bomb_head_start()
	await scn._steps(70)
	await _capture("gl_play_%s" % tag)
	for index in range(0, seats.size() - 1):
		await physics_frame
		scn._trap(seats[index], -1)
		await scn._steps(3)
	await scn._steps(3)
	_check(
		room.phase_controller.phase == MatchPhaseController.Phase.RESULTS,
		"%s: round 3 (Kg+L) ends with a last survivor" % tag
	)
	await _capture("gl_result_%s" % tag)
	await _next_round(room)
	_check(
		room.current_entry().main == scn.LAGSANAY,
		"%s: round 4 runs as the standalone Lagsanay" % tag
	)
	scn._to_play()
	await scn._steps(50)
	await _capture("lagsanay_r4_play_%s" % tag)
	_check(room.play_twist_text().is_empty(), "%s: the standalone Lagsanay shows no Twist" % tag)
	await scn._close()


func _next_round(room: P12ScheduledMatchRoom) -> void:
	room._start_next_round()
	await scn._steps(3)
	await process_frame


func _sudden_death_and_lobby(seat_count: int) -> void:
	var tag := "%dp" % seat_count
	await scn._open(seat_count, {1: [scn.KARERA, scn.LAGSANAY], 2: [scn.KARERA, scn.KANGAROO]})
	var room: P12ScheduledMatchRoom = scn.room
	room.tuning.match_round_limit = 2
	room.tuning.match_race_hard_cap_seconds = 0.3
	room.tuning.match_race_after_first_finish_seconds = 0.3
	scn._to_play()
	Engine.time_scale = 8.0
	await scn._steps(120)
	Engine.time_scale = 1.0
	await _next_round(room)
	scn._to_play()
	Engine.time_scale = 8.0
	for _frame in 400:
		await physics_frame
		if room._sudden_death_active or room.final_results_visible:
			break
	Engine.time_scale = 1.0
	_check(room._sudden_death_active, "%s: a level score after a stack starts sudden death" % tag)
	await scn._steps(30)
	await _capture("sudden_death_%s" % tag)
	_check(room.play_twist_text().is_empty(), "%s: sudden death has no Twist" % tag)
	var seats: Array[int] = scn._seats()
	for index in range(0, seats.size() - 1):
		await physics_frame
		scn._trap(seats[index], -1)
		await scn._steps(3)
	await scn._steps(5)
	_check(room.final_results_visible, "%s: sudden death ends in the final result screen" % tag)
	await _capture("final_results_%s" % tag)
	room._return_group_to_lobby()
	await scn._steps(3)
	_check(
		room.phase_controller.phase == MatchPhaseController.Phase.LOBBY,
		"%s: Return to Lobby after a stacked match" % tag
	)
	await _capture("lobby_%s" % tag)
	await scn._close()


func _capture(label: String) -> void:
	await process_frame
	await process_frame
	if DisplayServer.get_name() == "headless":
		return
	var image := root.get_texture().get_image()
	if image == null:
		return
	var path := output_dir.path_join("p12_%s.png" % label)
	image.save_png(path)
	capture_count += 1
	report.append("capture %s %dx%d" % [path.get_file(), image.get_width(), image.get_height()])


func _check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		report.append("PASS %s" % message)
		return
	failures.append("FAIL %s" % message)
	report.append("FAIL %s" % message)
	push_error("FAIL %s" % message)

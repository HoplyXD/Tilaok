# gdlint: disable=max-line-length,max-file-lines
extends SceneTree

## NLB-P11-T01 multi-client scale runner (authored, NEVER run while the laptop is shared).
## Every client here is a separate SYNTHETIC headless process driving the production client API;
## none of them is a phone or a participant, and every output line says evidence=SYNTHETIC.
##
## Roles (user args after `--`):
##   matrix [seconds] [mode]     spawns one host process for 2, 3 and 4 seats (1..3 clients plus the
##                               host's synthetic K1 seat) one after another, reads each host's and
##                               clients' telemetry, prints NLB_P11_SCALE_CELL lines and a summary.
##   host <clients> <mode> <seconds> <run_dir> <fault|none>
##                               the production GameFlow as PC host (live route, crowded fixture),
##                               spawns <clients> client processes, runs the mode, writes telemetry.
##   client <address> <port> <code> <run_dir> <index> <seed> <seconds> <fault|none>
##                               the production GameFlow as a client with scripted seeded input.
## Modes: profile (default; fixture on, `seconds` of play, 10-minute profile = 720 s with the
## 2-minute warm-up included), cycles (ten match/replay cycles, one telemetry `cycle` event each),
## thermal (profile for 1800 s; the external adb sampler records battery/thermal/RSS alongside).
## Outputs land in user://nlb_p11/<run_dir>/: host.telem, client<i>.telem, host.log, client<i>.log.
## The invitation code travels only as a process argument on this machine and is never written to
## any file or log. A headless run is NOT a render measurement: the budget profiles for the report
## use the exported windowed Windows build.
## Run: Godot --headless --fixed-fps 60 --path tilaok! --script res://tests/run_nlb_p11_scale_runner.gd -- matrix 30 profile

const TEST_GAME_PORT := 29795
const TEST_DISCOVERY_PORT := 29796
const NETWORK_FLOW := preload("res://scenes/flow/game_flow.tscn")
const SCRIPT_PATH := "res://tests/run_nlb_p11_scale_runner.gd"
const RUN_ROOT := "user://nlb_p11"
const SEED := 11011
const CYCLE_COUNT := 10
const SETUP_TIMEOUT_MS := 90000

var mode := "matrix"
var args := PackedStringArray()
var flow: GameFlow
var run_dir := ""
var client_count := 1
var run_mode := "profile"
var duration_s := 30
var fault_spec := "none"
var client_index := 0
var client_seed := SEED
var host_address := ""
var client_pids: Array[int] = []
var start_ms := 0
var fixture_placed := 0
var failed := false


func _initialize() -> void:
	args = OS.get_cmdline_user_args()
	if not args.is_empty():
		match str(args[0]):
			"host":
				mode = "host"
				client_count = clampi(int(args[1]) if args.size() > 1 else 1, 1, 3)
				run_mode = str(args[2]) if args.size() > 2 else "profile"
				duration_s = int(args[3]) if args.size() > 3 else 30
				run_dir = str(args[4]) if args.size() > 4 else "%s/adhoc" % RUN_ROOT
				fault_spec = str(args[5]) if args.size() > 5 else "none"
			"client":
				mode = "client"
				run_dir = str(args[4]) if args.size() > 4 else ""
				client_index = int(args[5]) if args.size() > 5 else 1
				client_seed = int(args[6]) if args.size() > 6 else SEED
				duration_s = int(args[7]) if args.size() > 7 else 30
				fault_spec = str(args[8]) if args.size() > 8 else "none"
			"matrix":
				mode = "matrix"
				duration_s = int(args[1]) if args.size() > 1 else 30
				run_mode = str(args[2]) if args.size() > 2 else "profile"
	call_deferred("_start")


func _process(_delta: float) -> bool:
	if mode == "client" and flow != null:
		_drive_client()
	if mode != "matrix" and flow != null and start_ms > 0:
		var limit_ms := SETUP_TIMEOUT_MS + duration_s * 1000 + CYCLE_COUNT * 60000
		if Time.get_ticks_msec() - start_ms > limit_ms:
			_fail("scale runner timed out in %s mode" % mode)
	return false


func _start() -> void:
	if mode == "matrix":
		await _run_matrix()
		return
	flow = NETWORK_FLOW.instantiate() as GameFlow
	if flow == null:
		_fail("could not instantiate the production GameFlow scene")
		return
	root.add_child(flow)
	await process_frame
	await process_frame
	start_ms = Time.get_ticks_msec()
	if mode == "host":
		await _run_host()
	else:
		_start_client()


# --- matrix ----------------------------------------------------------------------------------


func _run_matrix() -> void:
	var mismatches := 0
	var run_id := str(Time.get_unix_time_from_system()).replace(".", "")
	for clients in [1, 2, 3]:
		var cell_dir := "%s/%s-%dseat" % [RUN_ROOT, run_id, clients + 1]
		DirAccess.make_dir_recursive_absolute(cell_dir)
		var command_line := _base_command() + PackedStringArray(
			[
				"host", str(clients), run_mode, str(duration_s), cell_dir, "none",
			]
		) + _telemetry_flags("%s/host.telem" % cell_dir, "%s-%dseat" % [run_mode, clients + 1])
		var output: Array = []
		var exit_code := OS.execute(OS.get_executable_path(), command_line, output, true)
		var host_text := _read("%s/host.telem" % cell_dir)
		var problems: Array[String] = []
		if exit_code != 0:
			problems.append("host exit code %d" % exit_code)
		if not host_text.contains("NLB_TELEM v1 header") or not host_text.contains("NLB_TELEM v1 end"):
			problems.append("host telemetry missing header or end")
		for index in range(1, clients + 1):
			var client_text := _read("%s/client%d.telem" % [cell_dir, index])
			if not client_text.contains("synthetic=SYNTHETIC"):
				problems.append("client %d telemetry missing or not labeled SYNTHETIC" % index)
		if not problems.is_empty():
			mismatches += 1
		print(
			"NLB_P11_SCALE_CELL seats=%d clients=%d mode=%s seconds=%d result=%s evidence=SYNTHETIC problems=%s"
			% [clients + 1, clients, run_mode, duration_s, "OK" if problems.is_empty() else "PROBLEM", str(problems)]
		)
	print("NLB_P11_SCALE_MATRIX cells=3 problems=%d evidence=SYNTHETIC not_phones=true" % mismatches)
	quit(1 if mismatches > 0 else 0)


# --- host ------------------------------------------------------------------------------------


func _run_host() -> void:
	DirAccess.make_dir_recursive_absolute(run_dir)
	host_address = _first_lan_ipv4()
	if host_address.is_empty():
		_fail("no usable LAN IPv4 address")
		return
	var manager := flow.network_session
	manager.approval_requested.connect(
		func(peer_id: int, _compatibility: Dictionary) -> void: manager.approve_peer(peer_id)
	)
	var local_seat := flow.router.registry.join_keyboard("K1")
	if local_seat < 0 or not flow.router.registry.set_ready(local_seat, true):
		_fail("could not reserve a ready synthetic K1 host seat")
		return
	if not manager.start_host(host_address, TEST_GAME_PORT, TEST_DISCOVERY_PORT):
		_fail("the production host could not bind the test LAN ports")
		return
	_log("NLB_P11_HOST seats=%d mode=%s seconds=%d evidence=SYNTHETIC" % [client_count + 1, run_mode, duration_s])
	for index in range(1, client_count + 1):
		var pid := _spawn_client(manager.invitation_code, index)
		if pid <= 0:
			_fail("could not start synthetic client %d" % index)
			return
		client_pids.append(pid)
	var wait_begin := Time.get_ticks_msec()
	while not (
		flow.router.registry.all_joined_ready_and_connected()
		and flow.router.registry.joined_seats().size() >= client_count + 1
	):
		if Time.get_ticks_msec() - wait_begin > SETUP_TIMEOUT_MS:
			_fail("not every synthetic client joined and readied in time")
			return
		await process_frame
	if not manager.start_network_match():
		_fail("the host rejected the ready network match")
		return
	var room: P12ScheduledMatchRoom = manager.match_room
	wait_begin = Time.get_ticks_msec()
	while room == null or not _all_synced(manager, client_count):
		room = manager.match_room
		if Time.get_ticks_msec() - wait_begin > SETUP_TIMEOUT_MS:
			_fail("not every client reached the synchronized match")
			return
		await process_frame
	room.tuning.match_results_advance_seconds = 600.0
	room.tuning.match_round_limit = 1 if run_mode == "cycles" else 12
	room.tuning.match_target_score_units = 100000
	room._finish_pugad_timeout()
	if NlbP11CrowdedStage.enabled() and run_mode != "cycles":
		fixture_placed = int(NlbP11CrowdedStage.populate(room).placed)
		_log(NlbP11CrowdedStage.census_line(room, fixture_placed))
	room._resolve_place_edits([])
	await process_frame
	if run_mode == "cycles":
		await _run_cycles(manager, room, local_seat)
	else:
		await _run_profile(manager, room)
	_finish_host(manager)


func _run_profile(manager: NetworkSessionManager, room: P12ScheduledMatchRoom) -> void:
	var begin := Time.get_ticks_msec()
	var next_census := begin + 30000
	while Time.get_ticks_msec() - begin < duration_s * 1000:
		if Time.get_ticks_msec() >= next_census:
			next_census += 30000
			if NlbP11CrowdedStage.enabled():
				_log(NlbP11CrowdedStage.census_line(room, fixture_placed))
		await process_frame
	manager.telemetry_cycle_record(0)


## Ten complete match/replay cycles: end the one-round match, replay, and write one telemetry
## `cycle` event of teardown counts after each. A failure to reach final results aborts the run.
func _run_cycles(manager: NetworkSessionManager, room: P12ScheduledMatchRoom, local_seat: int) -> void:
	for cycle in range(1, CYCLE_COUNT + 1):
		var match_before := manager.active_match_id
		await _finish_race(room, [local_seat])
		var guard := 0
		while not room.final_results_visible and guard < 600:
			guard += 1
			await process_frame
		if not room.final_results_visible:
			_fail("cycle %d never reached the final results" % cycle)
			return
		manager.telemetry_cycle_record(cycle)
		_log("NLB_P11_CYCLE cycle=%d match=%d evidence=SYNTHETIC" % [cycle, match_before])
		room._on_result_replay_requested()
		guard = 0
		while manager.active_match_id == match_before and guard < 600:
			guard += 1
			await process_frame
		if manager.active_match_id == match_before:
			_fail("cycle %d: replay did not mint a new match" % cycle)
			return
		room = manager.match_room
		room.tuning.match_results_advance_seconds = 600.0
		room.tuning.match_round_limit = 1
		room.tuning.match_target_score_units = 100000
		room._finish_pugad_timeout()
		room._resolve_place_edits([])
		await process_frame


func _finish_race(room: P12ScheduledMatchRoom, finishing_seats: Array[int]) -> void:
	var controller := room.race_round_controller
	var candidates: Array[Dictionary] = []
	var tick := Engine.get_physics_frames()
	for seat_index in finishing_seats:
		candidates.append(
			{
				"round_id": controller.ledger.round_id,
				"seat_index": seat_index,
				"kind": "goal",
				"event_id": "%s:p11-goal:%d" % [controller.ledger.round_id, seat_index],
				"physics_tick": tick,
			}
		)
	var result := controller.advance_step(0.01, tick, candidates)
	room._apply_race_outcomes(result.new_outcomes)
	room._finish_race(str(result.end_reason))
	await process_frame
	await physics_frame


func _finish_host(manager: NetworkSessionManager) -> void:
	_log("NLB_P11_HOST_RESULT PASSED evidence=SYNTHETIC")
	manager.stop_session(NetworkLifecycleCodec.SessionEnd.HOST_QUIT)
	await _wait_ms(1500)
	for pid in client_pids:
		if OS.is_process_running(pid):
			OS.kill(pid)
	# Closing the manager writes the telemetry summaries (NetworkSessionManager._exit_tree).
	flow.queue_free()
	await process_frame
	quit(0)


func _spawn_client(code: String, index: int) -> int:
	var command_line := _base_command() + PackedStringArray(
		[
			"client", host_address, str(TEST_GAME_PORT), code, run_dir, str(index),
			str(SEED + index), str(duration_s), fault_spec,
		]
	) + _telemetry_flags(
		"%s/client%d.telem" % [run_dir, index], "%s-client%d" % [run_mode, index], false
	)
	if fault_spec != "none":
		command_line.append("--nlb-fault=%s" % fault_spec)
	return OS.create_process(OS.get_executable_path(), command_line, false)


func _all_synced(manager: NetworkSessionManager, expected: int) -> bool:
	var ready := 0
	for candidate in manager.candidates.values():
		if bool(candidate.get("match_sync_ready", false)):
			ready += 1
	return ready >= expected


# --- client ----------------------------------------------------------------------------------


func _start_client() -> void:
	if args.size() < 9:
		_fail("client arguments were incomplete")
		return
	var manager := flow.network_session
	manager.client_assigned.connect(func(_seat: int) -> void: manager.set_client_ready(true))
	manager.session_ended.connect(
		func(reason: int) -> void:
			_log("NLB_P11_CLIENT_SESSION_ENDED reason=%d evidence=SYNTHETIC" % reason)
			if flow != null:
				flow.queue_free()
			quit(0)
	)
	if not manager.connect_client(str(args[1]), int(args[2]), str(args[3])):
		_fail("the production client transport could not start")
		return
	_log("NLB_P11_CLIENT index=%d seed=%d evidence=SYNTHETIC" % [client_index, client_seed])


## Seeded scripted input through the production client API: a slow left/right sweep with a jump
## pulse every couple of seconds. It exercises the 30 Hz input cadence and state replication.
func _drive_client() -> void:
	var manager := flow.network_session
	if not manager.sync_ready:
		return
	var tick := Engine.get_physics_frames()
	var phase := (tick + client_seed) % 240
	var axis := 1000 if phase < 120 else -1000
	manager.client_set_continuous_input([axis, 0], [0, 0], false)
	if tick % 120 == client_seed % 120:
		manager.client_set_action(0, true)
	elif tick % 120 == (client_seed + 6) % 120:
		manager.client_set_action(0, false)


# --- shared ----------------------------------------------------------------------------------


func _base_command() -> PackedStringArray:
	return PackedStringArray(
		[
			"--headless", "--fixed-fps", "60", "--path", ProjectSettings.globalize_path("res://"),
			"--script", SCRIPT_PATH, "--",
		]
	)


func _telemetry_flags(path: String, profile: String, host_role: bool = true) -> PackedStringArray:
	var flags := PackedStringArray(
		[
			"--nlb-telemetry=%s" % path,
			"--nlb-telemetry-synthetic=1",
			"--nlb-telemetry-profile=%s" % profile.replace(" ", "_"),
			"--nlb-telemetry-seed=%d" % SEED,
		]
	)
	if host_role:
		# Only the host opts into the live route and the crowded fixture; a client follows the host.
		flags.append(NlbBuildFlags.FIXTURE_FLAG)
		flags.append("--match-route=network_live_build")
	return flags


func _read(path: String) -> String:
	return FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else ""


func _wait_ms(duration_ms: int) -> void:
	var begin := Time.get_ticks_msec()
	while Time.get_ticks_msec() - begin < duration_ms:
		await process_frame


func _first_lan_ipv4() -> String:
	var fallback := ""
	for info in IP.get_local_interfaces():
		var interface_name := str(info.get("friendly", info.get("name", ""))).to_lower()
		if interface_name.contains("virtual") or interface_name.contains("wsl") or interface_name.contains("loopback"):
			continue
		for address in info.get("addresses", []):
			var text_address := str(address)
			if text_address.contains(".") and not text_address.begins_with("127.") and not text_address.begins_with("169.254."):
				if interface_name.contains("wi-fi") or interface_name.contains("wifi"):
					return text_address
				if fallback.is_empty():
					fallback = text_address
	return fallback


func _fail(reason: String) -> void:
	if failed:
		return
	failed = true
	push_error("NLB_P11_SCALE FAILED: " + reason)
	_log("NLB_P11_FAILED %s evidence=SYNTHETIC" % reason)
	if flow != null and is_instance_valid(flow) and flow.network_session != null:
		flow.network_session.stop_session()
	for pid in client_pids:
		if OS.is_process_running(pid):
			OS.kill(pid)
	quit(1)


func _log(line: String) -> void:
	print(line)
	if run_dir.is_empty():
		return
	var path := "%s/%s.log" % [run_dir, "host" if mode == "host" else "client%d" % client_index]
	var file := FileAccess.open(path, FileAccess.READ_WRITE)
	if file == null:
		file = FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.seek_end()
		file.store_line(line)
		file.flush()

# gdlint: disable=max-line-length,max-file-lines
extends SceneTree

## NLB-P09-T03 ending-matrix runner (authored, never run). Three roles share this script:
##   matrix (default)  spawns one host+client pair per scenario below, waits for both, reads their
##                     log files and prints one NLB_P09_CELL line per scenario plus a summary;
##   host <ending> <exit> <host log> <client log>   the production GameFlow as PC host with a
##                     synthetic local K1 seat; it spawns one separate headless client, plays the
##                     named ending on the real room and takes the named exit route;
##   client <address> <port> <code> <client log> <exit>   the production GameFlow as a client.
## Endings: target (score target), round_limit (limit reached, one leader), tie_sd (limit reached,
## tied leaders, Sudden Death). Exits: replay, lobby, host_quit, abrupt_kill, client_leave.
## `-- phone <ending> <exit>` runs the host only and waits for a real Android client; the physical
## mixed-device session sheet in docs/evidence/nlb/p09/README.md records what the person saw.
## Synthetic K1 and headless clients are engineering evidence only, never phone evidence.
## Run: Godot --headless --fixed-fps 60 --path tilaok! --script res://tests/run_nlb_p09_multi_process.gd

const TEST_GAME_PORT := 29793
const TEST_DISCOVERY_PORT := 29794
const RUN_TIMEOUT_MS := 240000
const NETWORK_FLOW := preload("res://scenes/flow/game_flow.tscn")
const SCENARIOS := [
	["target", "replay"],
	["target", "lobby"],
	["round_limit", "replay"],
	["tie_sd", "replay"],
	["tie_sd", "lobby"],
	["target", "host_quit"],
	["tie_sd", "abrupt_kill"],
	["target", "client_leave"],
]
## What each exit must leave in the CLIENT log (the host log must also say HOST_RESULT PASSED,
## except after an abrupt kill, where the host cannot report).
const CLIENT_EXPECTED := {
	"replay": ["CLIENT_REKEYED from=1 to=2", "CLIENT_SYNCED match=2"],
	"lobby": ["CLIENT_SESSION_ENDED reason=3", "CLIENT_RETURNED state=3"],
	"host_quit": ["CLIENT_SESSION_ENDED reason=4", "CLIENT_RETURNED state=3"],
	"abrupt_kill": ["CLIENT_SESSION_ENDED reason=1", "CLIENT_RETURNED state=3"],
	"client_leave": ["CLIENT_LEFT"],
}

var mode := "matrix"
var args := PackedStringArray()
var flow: GameFlow
var start_ms := 0
var host_address := ""
var client_pid := -1
var phone_test := false
var ending := "target"
var exit_route := "replay"
var debug_log_path := ""
var client_log_path := ""
var client_exit := "replay"
var last_ledger_revision := 0
var last_match_id := 0
var ended_logged := false


func _initialize() -> void:
	args = OS.get_cmdline_user_args()
	if not args.is_empty():
		match str(args[0]):
			"host":
				mode = "host"
				ending = str(args[1]) if args.size() > 1 else "target"
				exit_route = str(args[2]) if args.size() > 2 else "replay"
				debug_log_path = str(args[3]) if args.size() > 3 else ""
				client_log_path = str(args[4]) if args.size() > 4 else ""
			"client":
				mode = "client"
				debug_log_path = str(args[4]) if args.size() > 4 else ""
				client_exit = str(args[5]) if args.size() > 5 else "replay"
			"phone":
				mode = "host"
				phone_test = true
				ending = str(args[1]) if args.size() > 1 else "target"
				exit_route = str(args[2]) if args.size() > 2 else "replay"
	call_deferred("_start")


func _process(_delta: float) -> bool:
	if mode != "matrix" and flow != null and Time.get_ticks_msec() - start_ms > RUN_TIMEOUT_MS:
		_fail("P09 ending run timed out in %s mode (%s / %s)." % [mode, ending, exit_route])
	if mode == "client" and flow != null:
		_watch_client()
	return false


func _start() -> void:
	if mode == "matrix":
		_run_matrix()
		return
	flow = NETWORK_FLOW.instantiate() as GameFlow
	if flow == null:
		_fail("Could not instantiate the production GameFlow scene.")
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
	var user_dir := OS.get_user_data_dir()
	var failed := 0
	for scenario in SCENARIOS:
		var host_log := user_dir.path_join("p09-host-%s-%s.log" % [scenario[0], scenario[1]])
		var client_log := user_dir.path_join("p09-client-%s-%s.log" % [scenario[0], scenario[1]])
		for path in [host_log, client_log]:
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(path)
		var command_line := PackedStringArray([
			"--headless", "--fixed-fps", "60", "--path", ProjectSettings.globalize_path("res://"),
			"--script", "res://tests/run_nlb_p09_multi_process.gd", "--", "host",
			str(scenario[0]), str(scenario[1]), host_log, client_log,
		])
		var output: Array = []
		var exit_code := OS.execute(OS.get_executable_path(), command_line, output, true)
		var host_text := FileAccess.get_file_as_string(host_log)
		var client_text := FileAccess.get_file_as_string(client_log)
		var problems: Array[String] = []
		if str(scenario[1]) != "abrupt_kill" and not host_text.contains("HOST_RESULT PASSED"):
			problems.append("host did not report PASSED")
		for token in CLIENT_EXPECTED[str(scenario[1])]:
			if not client_text.contains(str(token)):
				problems.append("client log lacks '%s'" % str(token))
		if host_text.contains("HOST_LEDGER_MISMATCH") or client_text.contains("FAILED"):
			problems.append("a ledger mismatch or failure was logged")
		var result := "MATCH" if problems.is_empty() else "MISMATCH"
		if not problems.is_empty():
			failed += 1
		print("NLB_P09_CELL ending=%s exit=%s result=%s exit_code=%d evidence=SYNTHETIC problems=%s" % [scenario[0], scenario[1], result, exit_code, str(problems)])
	print("NLB_P09_MATRIX scenarios=%d mismatches=%d evidence=SYNTHETIC" % [SCENARIOS.size(), failed])
	quit(1 if failed > 0 else 0)


# --- host ------------------------------------------------------------------------------------


func _run_host() -> void:
	host_address = _first_lan_ipv4()
	if host_address.is_empty():
		_fail("No usable LAN IPv4 address was available.")
		return
	var manager := flow.network_session
	manager.approval_requested.connect(
		func(peer_id: int, _compatibility: Dictionary) -> void:
			_log("APPROVAL_RESULT peer=%d approved=%s" % [peer_id, str(manager.approve_peer(peer_id))])
	)
	var local_seat := flow.router.registry.join_keyboard("K1")
	if local_seat < 0 or not flow.router.registry.set_ready(local_seat, true):
		_fail("Could not reserve a ready synthetic K1 host seat.")
		return
	if not manager.start_host(host_address, TEST_GAME_PORT, TEST_DISCOVERY_PORT):
		_fail("The production host could not bind the test LAN ports.")
		return
	_log("P09_RUN_HOST address=%s port=%d ending=%s exit=%s" % [host_address, TEST_GAME_PORT, ending, exit_route])
	if phone_test:
		var invite := FileAccess.open(OS.get_user_data_dir().path_join("p09-phone-invite.txt"), FileAccess.WRITE)
		if invite != null:
			invite.store_line(host_address)
			invite.store_line(str(TEST_GAME_PORT))
			invite.store_line(manager.invitation_code)
			invite.flush()
	else:
		client_pid = _spawn_client(manager.invitation_code)
		if client_pid <= 0:
			_fail("Could not start the separate production client process.")
			return
	while not (flow.router.registry.all_joined_ready_and_connected() and flow.router.registry.joined_seats().size() >= 2):
		await process_frame
	if not manager.start_network_match():
		_fail("Host rejected the ready network match.")
		return
	var room := manager.match_room
	while room == null or not _synced(manager):
		room = manager.match_room
		await process_frame
	var remote_seat := _remote_seat(manager)
	_log("HOST_MATCH seat0=%d remote=%d match=%d" % [local_seat, remote_seat, manager.active_match_id])
	# Round 1 is Karera. The ending is chosen by the tuning and by who finishes.
	room.tuning.match_results_advance_seconds = 600.0
	room.tuning.lagsanay_opening_head_start_seconds = 0.001
	room.tuning.lagsanay_taya_seconds_2p = 0.05
	room.tuning.match_round_limit = 1 if ending != "target" else 12
	room.tuning.match_target_score_units = 8 if ending == "target" else 100000
	room._finish_pugad_timeout()
	room._resolve_place_edits([])
	await process_frame
	var finishers: Array[int] = []
	if ending != "tie_sd":
		finishers.append(local_seat)
	await _finish_race(room, finishers)
	if ending == "tie_sd":
		var guard := 0
		while room._sudden_death_active and guard < 200:
			room.lagsanay_controller.countdown_remaining = 0.001
			room._advance_sudden_death_physics(0.02)
			guard += 1
			await physics_frame
	if not room.final_results_visible:
		_fail("The ending never reached the final results (%s)." % ending)
		return
	var host_ledger := _ledger_json(room)
	_log("HOST_LEDGER %s" % host_ledger)
	_check(room.result_ledger.revision() >= 2, "the host ledger holds the round and the final result")
	var final_entry: Dictionary = room.result_ledger.latest()
	_check(int(final_entry.kind) == NetworkResultsCodec.Kind.FINAL, "the last ledger entry is the final result")
	var max_round := 0
	for entry in room.result_ledger.entries():
		if int(entry.kind) == NetworkResultsCodec.Kind.ROUND:
			max_round = maxi(max_round, int(entry.round_id))
	_check(max_round <= room.tuning.match_round_limit, "no round beyond the limit was committed")
	if not phone_test:
		await _wait_client_line("CLIENT_FINAL", 25000)
		if _client_log_text().contains("CLIENT_LEDGER %s" % host_ledger):
			_log("HOST_LEDGER_MATCH")
		else:
			_log("HOST_LEDGER_MISMATCH client=%s" % _last_client_ledger())
			_fail("The client ledger differs from the host ledger.")
			return
	var scores_at_ending := room.cumulative_score_units.duplicate(true)
	await _take_exit(manager, room, scores_at_ending)


func _take_exit(manager: NetworkSessionManager, room: P12ScheduledMatchRoom, scores_at_ending: Dictionary) -> void:
	var match_before := manager.active_match_id
	match exit_route:
		"replay":
			room._on_result_replay_requested()
			var waited := 0
			while manager.active_match_id == match_before and waited < 300:
				waited += 1
				await process_frame
			_check(manager.active_match_id == match_before + 1, "Replay minted a new match ID")
			_check(room.cumulative_score_units.values().all(func(units: int) -> bool: return units == 0), "Replay reset every score")
			_check(room.result_ledger.revision() == 0 and not room.final_results_visible, "Replay reset the ledger and the result screen")
			if not phone_test:
				await _wait_client_line("CLIENT_SYNCED match=%d" % (match_before + 1), 25000)
			_pass("replay")
		"lobby":
			room._on_result_lobby_requested()
			await process_frame
			await process_frame
			_check(flow.state == GameFlow.State.LAN_LOBBY, "the host returned to the LAN lobby")
			_check(not manager.match_active and manager.candidates.is_empty(), "the host session retained no match or peer")
			if not phone_test:
				await _wait_client_line("CLIENT_RETURNED", 25000)
			_pass("lobby")
		"host_quit":
			manager.stop_session(NetworkLifecycleCodec.SessionEnd.HOST_QUIT)
			await _wait_ms(1500)
			if not phone_test:
				await _wait_client_line("CLIENT_RETURNED", 25000)
			_pass("host_quit")
		"abrupt_kill":
			_log("HOST_KILL abrupt process death now")
			OS.kill(OS.get_process_id())
		"client_leave":
			var seat := _remote_seat(manager)
			if not phone_test:
				await _wait_client_line("CLIENT_LEFT", 25000)
			await _wait_ms(1500)
			_check(seat < 0 or manager.reservations.is_reserved(seat) or not manager.match_active, "the leaving player's seat was forfeited, not held")
			_check(scores_at_ending == room.cumulative_score_units, "a Leave after the ending changed no score")
			_pass("client_leave")
		_:
			_fail("Unknown exit route %s." % exit_route)


func _finish_race(room: P12ScheduledMatchRoom, finishing_seats: Array[int]) -> void:
	var controller := room.race_round_controller
	var candidates: Array[Dictionary] = []
	var tick := Engine.get_physics_frames()
	for seat_index in finishing_seats:
		candidates.append({
			"round_id": controller.ledger.round_id,
			"seat_index": seat_index,
			"kind": "goal",
			"event_id": "%s:p09-goal:%d" % [controller.ledger.round_id, seat_index],
			"physics_tick": tick,
		})
	var result := controller.advance_step(0.01, tick, candidates)
	room._apply_race_outcomes(result.new_outcomes)
	room._finish_race(str(result.end_reason))
	await process_frame
	await physics_frame


func _ledger_json(room: P12ScheduledMatchRoom) -> String:
	var final_entry: Dictionary = room.result_ledger.latest()
	return JSON.stringify({
		"revision": room.result_ledger.revision(),
		"totals": _sorted_totals(room.cumulative_score_units),
		"winner": int(final_entry.get("winner_seat", -1)),
		"sudden_death": int(final_entry.get("sudden_death", 0)),
	})


## Seat -> units with string keys in seat order, so host and client print identical text.
func _sorted_totals(source: Dictionary) -> Dictionary:
	var seats: Array[int] = []
	for seat in source:
		seats.append(int(seat))
	seats.sort()
	var sorted_totals := {}
	for seat in seats:
		sorted_totals[str(seat)] = int(source.get(seat, 0))
	return sorted_totals


func _spawn_client(code: String) -> int:
	var command_line := PackedStringArray([
		"--headless", "--fixed-fps", "60", "--path", ProjectSettings.globalize_path("res://"),
		"--script", "res://tests/run_nlb_p09_multi_process.gd", "--", "client", host_address,
		str(TEST_GAME_PORT), code, client_log_path, exit_route,
	])
	return OS.create_process(OS.get_executable_path(), command_line, false)


func _synced(manager: NetworkSessionManager) -> bool:
	for candidate in manager.candidates.values():
		if bool(candidate.get("match_sync_ready", false)):
			return true
	return false


func _remote_seat(manager: NetworkSessionManager) -> int:
	for seat in manager.router.registry.joined_seats():
		if str(seat.device_kind) == "remote":
			return int(seat.seat)
	return -1


func _client_log_text() -> String:
	return FileAccess.get_file_as_string(client_log_path) if FileAccess.file_exists(client_log_path) else ""


func _last_client_ledger() -> String:
	var found := ""
	for line in _client_log_text().split("\n"):
		if line.begins_with("CLIENT_LEDGER "):
			found = line
	return found


func _wait_client_line(token: String, limit_ms: int) -> void:
	var begin := Time.get_ticks_msec()
	while not _client_log_text().contains(token):
		if Time.get_ticks_msec() - begin > limit_ms:
			_fail("The client never logged %s." % token)
			return
		await process_frame


func _wait_ms(duration_ms: int) -> void:
	var begin := Time.get_ticks_msec()
	while Time.get_ticks_msec() - begin < duration_ms:
		await process_frame


func _pass(route: String) -> void:
	_log("HOST_RESULT PASSED ending=%s exit=%s" % [ending, route])
	print("NLB_P09_%s PASSED ending=%s exit=%s" % ["PHONE" if phone_test else "RUN", ending, route])
	if flow != null and flow.network_session != null:
		flow.network_session.stop_session()
	if client_pid > 0 and OS.is_process_running(client_pid):
		await _wait_ms(1500)
		OS.kill(client_pid)
	quit(0)


# --- client ----------------------------------------------------------------------------------


func _start_client() -> void:
	if args.size() < 4:
		_fail("Client process arguments were incomplete.")
		return
	var manager := flow.network_session
	manager.client_message.connect(func(message: String) -> void: _log("CLIENT_MESSAGE " + message))
	manager.client_assigned.connect(func(_seat: int) -> void: manager.set_client_ready(true))
	manager.session_ended.connect(func(reason: int) -> void: _log("CLIENT_SESSION_ENDED reason=%d t=%d" % [reason, Time.get_ticks_msec()]))
	if not manager.connect_client(str(args[1]), int(args[2]), str(args[3])):
		_fail("Production client transport could not start.")
		return
	_log("P09_RUN_CLIENT connecting=true exit=%s" % client_exit)


## Every frame: log what the client's model shows, so the host (and a reviewer) can compare it.
func _watch_client() -> void:
	var manager := flow.network_session
	if manager.active_match_id != last_match_id:
		if last_match_id != 0 and manager.active_match_id > last_match_id:
			_log("CLIENT_REKEYED from=%d to=%d" % [last_match_id, manager.active_match_id])
		last_match_id = manager.active_match_id
	if last_match_id != 0 and manager.sync_ready and not _synced_logged_for(last_match_id):
		_log("CLIENT_SYNCED match=%d" % last_match_id)
	var results := manager.client_results
	if results.revision() != last_ledger_revision:
		last_ledger_revision = results.revision()
		if last_ledger_revision > 0 and results.is_final():
			var final_entry := results.final_entry()
			_log("CLIENT_LEDGER %s" % JSON.stringify({
				"revision": results.revision(),
				"totals": _sorted_totals(results.totals()),
				"winner": int(final_entry.get("winner_seat", -1)),
				"sudden_death": int(final_entry.get("sudden_death", 0)),
			}))
			_log("CLIENT_FINAL revision=%d" % results.revision())
			if client_exit == "client_leave":
				_client_leave.call_deferred()
	if not ended_logged and manager.state == NetworkSessionManager.SessionState.OFFLINE and flow.state == GameFlow.State.LAN_LOBBY and last_match_id != 0 and client_exit in ["lobby", "host_quit", "abrupt_kill"]:
		ended_logged = true
		_log("CLIENT_RETURNED state=%d" % int(flow.state))
		_finish_client.call_deferred()


var _synced_matches: Dictionary = {}


func _synced_logged_for(match_id: int) -> bool:
	if _synced_matches.has(match_id):
		return true
	_synced_matches[match_id] = true
	return false


func _client_leave() -> void:
	await _wait_ms(1000)
	_log("CLIENT_LEFT now")
	flow.network_session.stop_session(NetworkLifecycleCodec.SessionEnd.CLIENT_LEFT)
	await _wait_ms(3000)
	quit(0)


func _finish_client() -> void:
	await _wait_ms(1000)
	quit(0)


# --- shared ----------------------------------------------------------------------------------


func _check(condition: bool, label: String) -> void:
	if condition:
		_log("CHECK PASS " + label)
	else:
		_fail("CHECK FAIL " + label)


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
	push_error("NLB_P09_RUN FAILED: " + reason)
	_log("FAILED " + reason)
	paused = false
	if flow != null and is_instance_valid(flow) and flow.network_session != null:
		flow.network_session.stop_session()
	if client_pid > 0 and OS.is_process_running(client_pid):
		OS.kill(client_pid)
	quit(1)


func _log(line: String) -> void:
	print(line)
	if debug_log_path.is_empty():
		return
	var file := FileAccess.open(debug_log_path, FileAccess.READ_WRITE)
	if file == null:
		file = FileAccess.open(debug_log_path, FileAccess.WRITE)
	if file != null:
		file.seek_end()
		file.store_line(line)
		file.flush()

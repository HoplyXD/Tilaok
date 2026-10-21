# gdlint: disable=max-line-length,max-file-lines
extends SceneTree

## NLB-P08 disconnect / reconnect runner (authored, never run). Host mode (default) starts the
## production GameFlow on the scheduled network route with a synthetic local K1 seat, spawns one
## separate headless client process and walks the lifecycle:
##   1. reserve: the client drops its transport; the host keeps seat, identity and score;
##   2. reclaim: the client proves the reclaim token and gets the SAME seat and Player ID back;
##   3. host pause: the host freezes its clocks and the client mirrors the pause epoch;
##   4. expiry: the client stays away past 60 s; the host commits at most one disconnect elimination
##      for the round and keeps the identity reserved;
##   5. late reclaim: the client returns and is rebound once the snapshot is acknowledged;
##   6. kill limitation: a freshly started client process (no memory-only token) cannot take a seat.
## `-- phone` writes user://p08-phone-invite.txt and waits for a real Android client instead; the
## physical background / screen-lock / Wi-Fi sessions are on the P08 session sheet, not here.
## Synthetic K1 and headless clients are never phone or physical-controller evidence.
## Run: Godot --headless --fixed-fps 60 --path tilaok! --script res://tests/run_nlb_p08_multi_process.gd [-- phone]

const TEST_GAME_PORT := 29791
const TEST_DISCOVERY_PORT := 29792
const RUN_TIMEOUT_MS := 900000
const EXPIRY_WAIT_MS := 66000
const NETWORK_FLOW := preload("res://scenes/flow/game_flow.tscn")

var mode := "host"
var args := PackedStringArray()
var flow: GameFlow
var host_address := ""
var client_pid := -1
var late_pid := -1
var start_ms := 0
var phone_test := false
var debug_log_path := ""
var match_started := false
var step := 0
var step_ms := 0
var seat0 := -1
var player_id0 := PackedByteArray()
var score0 := {}
var pause_clock := -1.0
var client_stage := 0
var client_stage_ms := 0


func _initialize() -> void:
	args = OS.get_cmdline_user_args()
	if not args.is_empty() and args[0] == "client":
		mode = "client"
		if args.size() > 4:
			debug_log_path = str(args[4])
	elif not args.is_empty() and args[0] == "late":
		mode = "late"
		if args.size() > 4:
			debug_log_path = str(args[4])
	elif not args.is_empty() and args[0] == "phone":
		phone_test = true
	call_deferred("_start")


func _process(_delta: float) -> bool:
	if flow == null:
		return false
	if Time.get_ticks_msec() - start_ms > RUN_TIMEOUT_MS:
		_fail("P08 reconnect run timed out in %s mode." % mode)
		return false
	match mode:
		"client":
			_step_client()
		"late":
			_step_late()
		_:
			_step_host()
	return false


func _start() -> void:
	flow = NETWORK_FLOW.instantiate() as GameFlow
	if flow == null:
		_fail("Could not instantiate the production GameFlow scene.")
		return
	root.add_child(flow)
	await process_frame
	await process_frame
	start_ms = Time.get_ticks_msec()
	match mode:
		"client", "late":
			_start_client()
		_:
			_start_host()


# --- host ------------------------------------------------------------------------------------


func _start_host() -> void:
	host_address = _first_lan_ipv4()
	if host_address.is_empty():
		_fail("No usable LAN IPv4 address was available.")
		return
	var manager := flow.network_session
	manager.approval_requested.connect(
		func(peer_id: int, _compatibility: Dictionary) -> void:
			_log("APPROVAL_RESULT peer=%d approved=%s" % [peer_id, str(manager.approve_peer(peer_id))])
	)
	manager.seat_reservation_changed.connect(func(seat: int, event_name: String) -> void: _log("HOST_RESERVATION seat=%d event=%s t=%d" % [seat, event_name, Time.get_ticks_msec()]))
	var local_seat := flow.router.registry.join_keyboard("K1")
	if local_seat < 0 or not flow.router.registry.set_ready(local_seat, true):
		_fail("Could not reserve a ready synthetic K1 host seat.")
		return
	if not manager.start_host(host_address, TEST_GAME_PORT, TEST_DISCOVERY_PORT):
		_fail("The production host could not bind the test LAN ports.")
		return
	_log("P08_RUN_HOST address=%s port=%d route=scheduled" % [host_address, TEST_GAME_PORT])
	if phone_test:
		var invite := FileAccess.open(OS.get_user_data_dir().path_join("p08-phone-invite.txt"), FileAccess.WRITE)
		if invite != null:
			invite.store_line(host_address)
			invite.store_line(str(TEST_GAME_PORT))
			invite.store_line(manager.invitation_code)
			invite.flush()
		return
	client_pid = _spawn("client", manager.invitation_code, "p08-client-debug.log")
	if client_pid <= 0:
		_fail("Could not start the separate production client process.")


func _spawn(role: String, code: String, log_name: String) -> int:
	var command_line := PackedStringArray([
		"--headless", "--fixed-fps", "60", "--path", ProjectSettings.globalize_path("res://"),
		"--script", "res://tests/run_nlb_p08_multi_process.gd", "--", role, host_address,
		str(TEST_GAME_PORT), code, OS.get_user_data_dir().path_join(log_name),
	])
	return OS.create_process(OS.get_executable_path(), command_line, false)


func _advance(next_step: int, label: String) -> void:
	step = next_step
	step_ms = Time.get_ticks_msec()
	_log("HOST_STEP %d %s t=%d" % [next_step, label, step_ms])


func _waited(limit_ms: int) -> bool:
	return Time.get_ticks_msec() - step_ms > limit_ms


func _step_host() -> void:
	var manager := flow.network_session
	var registry := manager.router.registry
	if not match_started and registry.all_joined_ready_and_connected() and registry.joined_seats().size() >= 2:
		match_started = manager.start_network_match()
		if not match_started:
			_fail("Host rejected the ready network match.")
			return
		_advance(1, "match started; waiting for the client to synchronise")
	var room := manager.match_room
	if not match_started or room == null:
		return
	match step:
		1:
			seat0 = _remote_seat(manager)
			if seat0 >= 0 and _synced(manager):
				player_id0 = manager.reservations.player_id_of(seat0)
				score0 = room.cumulative_score_units.duplicate(true)
				_log("HOST_BASELINE seat=%d scores=%s" % [seat0, str(score0)])
				_advance(2, "waiting for the first drop (reserve)")
			elif _waited(60000):
				_fail("The client never synchronised.")
		2:
			if manager.reservations.is_reserved(seat0):
				var seat := registry.get_seat(seat0)
				_check(bool(seat.joined) and not bool(seat.connected), "reserved seat stays joined but disconnected")
				_check(room.cumulative_score_units == score0, "score is unchanged while reserved")
				_check(manager.reservations.player_id_of(seat0) == player_id0, "identity is unchanged while reserved")
				_advance(3, "waiting for the reclaim")
			elif _waited(40000):
				_fail("The client never dropped.")
		3:
			if not manager.reservations.is_reserved(seat0) and bool(registry.get_seat(seat0).connected):
				_check(_remote_seat(manager) == seat0 and manager.reservations.player_id_of(seat0) == player_id0, "the SAME seat and Player ID came back")
				_advance(4, "host pause")
				pause_clock = room.play_clock_seconds()
				paused = true
			elif _waited(30000):
				_fail("The client never reclaimed its seat.")
		4:
			if _waited(1500):
				_check(manager.pause_controller.paused and manager.pause_controller.epoch >= 1, "the host pause advanced the epoch")
				_check(is_equal_approx(room.play_clock_seconds(), pause_clock) or room.play_clock_seconds() == pause_clock, "the authoritative play clock froze with the pause")
				paused = false
				_advance(5, "waiting for the second drop (expiry)")
		5:
			if manager.reservations.is_reserved(seat0):
				_advance(6, "client absent; waiting for the 60 s grace to end")
			elif _waited(60000):
				_fail("The second drop never happened.")
		6:
			if manager.reservations.is_expired(seat0):
				_log("HOST_EXPIRED seat=%d committed_round=%d phase=%d scores=%s" % [seat0, manager.reservations.committed_round(seat0), int(room.phase_controller.phase), str(room.cumulative_score_units)])
				_check(manager.reservations.is_reserved(seat0), "the identity stays reserved after expiry")
				_advance(7, "waiting for the late reclaim")
			elif _waited(EXPIRY_WAIT_MS + 20000):
				_fail("The reservation never expired.")
		7:
			if not manager.reservations.is_reserved(seat0) and bool(registry.get_seat(seat0).connected):
				_check(_remote_seat(manager) == seat0, "the late reclaim returned the same seat")
				_log("HOST_LATE_RECLAIM phase=%d scores=%s" % [int(room.phase_controller.phase), str(room.cumulative_score_units)])
				var joined_before := registry.joined_seats().size()
				late_pid = _spawn("late", manager.invitation_code, "p08-late-debug.log")
				_advance(8, "a fresh process (no token) tries to join mid-match; joined=%d" % joined_before)
			elif _waited(120000):
				_fail("The late reclaim never completed.")
		8:
			if _waited(12000):
				_check(registry.joined_seats().size() == 2, "a new process cannot take a seat mid-match")
				print("NLB_P08_%s PASSED seat=%d" % ["PHONE" if phone_test else "MULTI_PROCESS", seat0])
				manager.stop_session()
				if late_pid > 0 and OS.is_process_running(late_pid):
					OS.kill(late_pid)
				quit(0)


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


# --- client ----------------------------------------------------------------------------------


func _start_client() -> void:
	if args.size() < 4:
		_fail("Client process arguments were incomplete.")
		return
	var manager := flow.network_session
	manager.client_message.connect(func(message: String) -> void: _log("CLIENT_MESSAGE " + message))
	manager.client_assigned.connect(func(_seat: int) -> void: manager.set_client_ready(true))
	manager.pause_state_changed.connect(func(is_paused: bool, epoch: int) -> void: _log("CLIENT_PAUSE paused=%s epoch=%d" % [str(is_paused), epoch]))
	if not manager.connect_client(str(args[1]), int(args[2]), str(args[3])):
		_fail("Production client transport could not start.")
		return
	_log("P08_RUN_CLIENT role=%s connecting=true" % mode)


func _drop(manager: NetworkSessionManager, label: String) -> void:
	_log("CLIENT_DROP %s t=%d" % [label, Time.get_ticks_msec()])
	manager.transport.request_disconnect_all()


func _client_next(stage: int) -> void:
	client_stage = stage
	client_stage_ms = Time.get_ticks_msec()


func _client_waited(limit_ms: int) -> bool:
	return Time.get_ticks_msec() - client_stage_ms > limit_ms


func _step_client() -> void:
	var manager := flow.network_session
	var ready := manager.match_active and manager.sync_ready
	match client_stage:
		0:
			if ready:
				_client_next(1)
		1:
			if _client_waited(3000):
				_drop(manager, "first (reserve then reclaim)")
				_client_next(2)
		2:
			if manager.client_reclaim_available():
				_log("CLIENT_CREDENTIAL held=true")
				_client_next(3)
		3:
			if _client_waited(2000):
				_log("CLIENT_RECLAIM connect=%s" % str(manager.connect_reclaim()))
				_client_next(4)
		4:
			if ready:
				_log("CLIENT_RECLAIMED seat=%d generation=%d" % [manager.client_assigned_seat, manager.assigned_peer_generation])
				_client_next(5)
		5:
			if _client_waited(8000):
				_drop(manager, "second (stay away past 60 s)")
				_client_next(6)
		6:
			if manager.client_reclaim_available():
				_client_next(7)
		7:
			if _client_waited(EXPIRY_WAIT_MS):
				_log("CLIENT_LATE_RECLAIM connect=%s" % str(manager.connect_reclaim()))
				_client_next(8)
		8:
			if ready:
				_log("CLIENT_LATE_RECLAIMED seat=%d" % manager.client_assigned_seat)
				_client_next(9)
		9:
			if _client_waited(15000):
				quit(0)


## A fresh process: no memory-only token, so the host (admission closed, reclaim needs a proof) must
## refuse it. The process stays up for a few seconds and reports what it saw.
func _step_late() -> void:
	var manager := flow.network_session
	if manager.client_assigned_seat >= 0:
		_fail("A process without a token was given a seat mid-match.")
		return
	if Time.get_ticks_msec() - start_ms > 10000:
		_log("LATE_CLIENT no seat assigned (expected)")
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
	push_error("NLB_P08_RUN FAILED: " + reason)
	_log("FAILED " + reason)
	paused = false
	if flow != null and is_instance_valid(flow) and flow.network_session != null:
		flow.network_session.stop_session()
	for pid in [client_pid, late_pid]:
		if int(pid) > 0 and OS.is_process_running(int(pid)):
			OS.kill(int(pid))
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

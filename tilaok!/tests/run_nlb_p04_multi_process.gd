# gdlint: disable=max-line-length
extends SceneTree

const TEST_GAME_PORT := 29779
const TEST_DISCOVERY_PORT := 29780
const READY_TIMEOUT_MS := 180000
const PHONE_READY_TIMEOUT_MS := 300000
const NETWORK_FLOW := preload("res://scenes/flow/game_flow.tscn")

var mode := "host"
var args := PackedStringArray()
var flow: GameFlow
var host_address := ""
var client_pid := -1
var start_ms := 0
var match_started := false
var saw_remote_axis := false
var client_result_received := false
var client_input_sent := false
var debug_log_path := ""
var phone_test := false
var phone_invite_path := ""
var ready_timeout_ms := READY_TIMEOUT_MS
var _last_status_ms := 0


func _initialize() -> void:
	args = OS.get_cmdline_user_args()
	if not args.is_empty() and args[0] == "client":
		mode = "client"
		if args.size() > 4:
			debug_log_path = str(args[4])
	elif not args.is_empty() and args[0] == "phone":
		phone_test = true
		ready_timeout_ms = PHONE_READY_TIMEOUT_MS
		phone_invite_path = OS.get_user_data_dir().path_join("p04-phone-invite.txt")
	call_deferred("_start")


func _process(_delta: float) -> bool:
	if flow == null:
		return false
	if Time.get_ticks_msec() - start_ms > ready_timeout_ms:
		_fail("P04 multi-process flow timed out in %s mode." % mode)
		return false
	if mode != "client":
		_step_host()
	else:
		_step_client()
	return false


func _start() -> void:
	var packed := NETWORK_FLOW.instantiate()
	flow = packed as GameFlow
	if flow == null:
		_fail("Could not instantiate the production GameFlow scene.")
		return
	root.add_child(flow)
	await process_frame
	await process_frame
	start_ms = Time.get_ticks_msec()
	if mode == "host":
		_start_host()
	else:
		_start_client()


func _start_host() -> void:
	host_address = _first_lan_ipv4()
	if host_address.is_empty():
		_fail("No usable LAN IPv4 address was available.")
		return
	var manager := flow.network_session
	manager.approval_requested.connect(
		func(peer_id: int, compatibility: Dictionary) -> void:
			_log("APPROVAL_REQUEST peer=%d protocol=%s" % [peer_id, str(compatibility.get("protocol", "unknown"))])
			_log("APPROVAL_RESULT peer=%d approved=%s" % [peer_id, str(manager.approve_peer(peer_id))])
	)
	var local_seat := flow.router.registry.join_keyboard("K1")
	if local_seat < 0 or not flow.router.registry.set_ready(local_seat, true):
		_fail("Could not reserve a ready local host seat.")
		return
	if not manager.start_host(host_address, TEST_GAME_PORT, TEST_DISCOVERY_PORT):
		_fail("The production host could not bind the test LAN ports.")
		return
	_log("P04_MULTIPROCESS_HOST address=%s port=%d lobby_id=%s" % [host_address, TEST_GAME_PORT, str(manager.lobby_id)])
	if phone_test:
		var credentials := FileAccess.open(phone_invite_path, FileAccess.WRITE)
		if credentials != null:
			credentials.store_line(host_address)
			credentials.store_line(str(TEST_GAME_PORT))
			credentials.store_line(manager.invitation_code)
			credentials.flush()
		return
	var command_line := PackedStringArray(
		[
			"--headless",
			"--path",
			ProjectSettings.globalize_path("res://"),
			"--script",
			"res://tests/run_nlb_p04_multi_process.gd",
			"--",
			"client",
			host_address,
			str(TEST_GAME_PORT),
			manager.invitation_code,
			OS.get_user_data_dir().path_join("p04-client-debug.log"),
		]
	)
	client_pid = OS.create_process(OS.get_executable_path(), command_line, false)
	if client_pid <= 0:
		_fail("Could not start the separate production client process.")


func _start_client() -> void:
	if args.size() < 4:
		_fail("Client process arguments were incomplete.")
		return
	if debug_log_path.is_empty():
		debug_log_path = OS.get_user_data_dir().path_join("p04-client-debug.log")
	_log("CLIENT_ARGS mode=client address=%s port=%s" % [str(args[1]), str(args[2])])
	host_address = str(args[1])
	var manager := flow.network_session
	manager.client_message.connect(func(message: String) -> void: _log("CLIENT_MESSAGE " + message))
	manager.client_assigned.connect(func(_seat: int) -> void: manager.set_client_ready(true))
	if not manager.connect_client(host_address, int(args[2]), str(args[3])):
		_fail("Production client transport could not start.")
		return
	_log("P04_MULTIPROCESS_CLIENT connecting=true")


func _step_host() -> void:
	var manager := flow.network_session
	if Time.get_ticks_msec() - _last_status_ms > 1000:
		_last_status_ms = Time.get_ticks_msec()
		var sync_count := 0
		for candidate in manager.candidates.values():
			if bool(candidate.get("match_sync_ready", false)):
				sync_count += 1
		var axis := 0.0
		var actor_positions: Array[String] = []
		for seat in manager.router.registry.joined_seats():
			if str(seat.device_kind) == "remote":
				axis = manager.router.movement_axis(int(seat.seat))
			if manager.match_room != null:
				var actor := manager.match_room.actors.get(int(seat.seat)) as ChickenController
				if actor != null and is_instance_valid(actor):
					actor_positions.append("%d:%.1f,%.1f" % [int(seat.seat), actor.global_position.x, actor.global_position.y])
		var remote_seat := manager.router.registry.seat_for_remote_source("peer_1")
		var camera_position := Vector2.ZERO
		if manager.match_room != null and manager.match_room.camera_rig != null:
			camera_position = manager.match_room.camera_rig.global_position
		var input_state: Dictionary = manager._host_input_state.get(1, {})
		_log("HOST_STATUS phase=%d sync=%d seat=%d router_phase=%d axis=%.2f actors=%s camera=%.1f,%.1f peers=%d last_sequence=%d timed_out=%s" % [int(manager.match_room.phase_controller.phase) if manager.match_room != null else -1, sync_count, remote_seat, int(manager.router.phase), axis, str(actor_positions), camera_position.x, camera_position.y, manager.candidates.size(), int(input_state.get("last_sequence", -1)), str(input_state.get("timed_out", false))])
	if not match_started and manager.router.registry.all_joined_ready_and_connected():
		match_started = manager.start_network_match()
		if not match_started:
			_fail("Host rejected the ready two-seat network match.")
			return
	if match_started and manager.match_room != null:
		for seat in manager.router.registry.joined_seats():
			if str(seat.device_kind) == "remote" and manager.router.movement_axis(int(seat.seat)) > 0.5:
				saw_remote_axis = true
				break
		for peer_id in manager.candidates.keys():
			if bool(manager.candidates[peer_id].get("match_sync_ready", false)):
				client_result_received = true
	if saw_remote_axis and client_result_received and client_pid > 0 and not OS.is_process_running(client_pid):
		print("NLB_P04_MULTI_PROCESS PASSED host_owned_match=true client_snapshot=true remote_input=true")
		manager.stop_session()
		quit(0)
	if phone_test and saw_remote_axis and client_result_received:
		print("NLB_P04_PHONE PASSED host_owned_match=true client_snapshot=true remote_input=true")
		manager.stop_session()
		quit(0)


func _step_client() -> void:
	var manager := flow.network_session
	if manager.sync_ready and not client_input_sent:
		var seats: Dictionary = manager.client_replica_state.get("seats", {})
		if seats.size() < 2:
			_fail("The installed snapshot did not contain both assigned seats.")
			return
		client_input_sent = true
		manager.client_set_continuous_input([0, 0])
		print("P04_MULTIPROCESS_CLIENT sync_ready=true seats=%d neutral_sent=true" % seats.size())
		await create_timer(0.2).timeout
		_log("CLIENT_AXIS start=true result=%s" % str(manager.client_set_continuous_input([800, 0])))
		await create_timer(5.0).timeout
		_log("CLIENT_AXIS stop=true")
		manager.client_set_continuous_input([0, 0])
		manager.stop_session()
		quit(0)


func _first_lan_ipv4() -> String:
	var fallback := ""
	var ethernet_fallback := ""
	for info in IP.get_local_interfaces():
		var interface_name := str(info.get("friendly", info.get("name", ""))).to_lower()
		if interface_name.contains("virtual") or interface_name.contains("wsl") or interface_name.contains("loopback"):
			continue
		for address in info.get("addresses", []):
			var text_address := str(address)
			if (
				text_address.contains(".")
				and not text_address.begins_with("127.")
				and not text_address.begins_with("169.254.")
				and text_address != "0.0.0.0"
			):
				if interface_name.contains("wi-fi") or interface_name.contains("wifi"):
					return text_address
				if interface_name.contains("ethernet") and ethernet_fallback.is_empty():
					ethernet_fallback = text_address
				if fallback.is_empty():
					fallback = text_address
	return ethernet_fallback if not ethernet_fallback.is_empty() else fallback


func _fail(reason: String) -> void:
	push_error("NLB_P04_MULTI_PROCESS FAILED: " + reason)
	_log("FAILED " + reason)
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

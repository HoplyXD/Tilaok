# gdlint: disable=max-line-length
extends SceneTree

const ENGINE_PATH := "D:/Downloads/Godot_v4.7.2-stable_win64_console.exe"
const GAME_PORT := 29777
const DISCOVERY_PORT := 29778
const CYCLE_TARGET := 10

var mode := ""
var args := PackedStringArray()
var router: LocalInputRouter
var manager: NetworkSessionManager
var host_address := ""
var client_pid := -1
var cycles_completed := 0
var saw_ready := false
var phase := ""
var timer := 0.0
var ready_wait := 0.0
var start_lobby_id := 0
var last_lobby_id := 0
var starting_memory := 0


func _initialize() -> void:
	args = OS.get_cmdline_user_args()
	if args.is_empty():
		call_deferred("_start_host_runner")
	elif args[0] == "client":
		mode = "client"
		call_deferred("_start_client_runner")
	else:
		push_error("Unknown multi-process runner mode.")
		quit(2)


func _process(delta: float) -> bool:
	if manager == null:
		return false
	if mode == "host":
		_run_host_step(delta)
	else:
		_run_client_step(delta)
	return false


func _start_host_runner() -> void:
	mode = "host"
	host_address = _first_lan_ipv4()
	if host_address.is_empty():
		_fail("No usable IPv4 interface was available.")
		return
	_create_session_objects()
	manager.approval_requested.connect(
		func(peer_id: int, _compatibility: Dictionary) -> void: manager.approve_peer(peer_id)
	)
	manager.lobby_changed.connect(_on_host_lobby_changed)
	starting_memory = Performance.get_monitor(Performance.MEMORY_STATIC)
	_start_cycle()


func _start_client_runner() -> void:
	if args.size() != 5:
		_fail("Client runner arguments were incomplete.")
		return
	_create_session_objects()
	manager.client_assigned.connect(func(_seat: int) -> void: manager.set_client_ready(true))
	if not manager.connect_client(str(args[1]), int(args[2]), str(args[4])):
		_fail("Production client transport did not start.")


func _create_session_objects() -> void:
	router = LocalInputRouter.new()
	root.add_child(router)
	manager = NetworkSessionManager.new()
	manager.configure(router)
	root.add_child(manager)


func _start_cycle() -> void:
	if not manager.start_host(host_address, GAME_PORT, DISCOVERY_PORT):
		_fail("Production host could not immediately bind both ports.")
		return
	if manager.game_port != GAME_PORT or manager.discovery_port != DISCOVERY_PORT:
		_fail("An actual bound port did not match the selected port.")
		return
	if manager.lobby_id == last_lobby_id:
		_fail("Rehost reused the previous Lobby ID.")
		return
	if cycles_completed == 0:
		start_lobby_id = manager.lobby_id
	last_lobby_id = manager.lobby_id
	saw_ready = false
	timer = 0.0
	var command_line := PackedStringArray(
		[
			"--headless",
			"--path",
			ProjectSettings.globalize_path("res://"),
			"--script",
			"res://tests/run_nlb_p02_multi_process.gd",
			"--",
			"client",
			host_address,
			str(GAME_PORT),
			str(DISCOVERY_PORT),
			manager.invitation_code,
		]
	)
	client_pid = OS.create_process(ENGINE_PATH, command_line, false)
	if client_pid <= 0:
		_fail("Could not start the separate client process.")
		return
	phase = "waiting_for_client"


func _run_host_step(delta: float) -> void:
	timer += delta
	if phase == "waiting_for_client":
		if (
			saw_ready
			and manager.router.registry.joined_seats().is_empty()
			and not OS.is_process_running(client_pid)
		):
			manager.stop_session()
			phase = "waiting_for_teardown"
			return
		if timer > 15.0:
			_fail("Separate client did not complete a ready and leave cycle.")
			return
	if (
		phase == "waiting_for_teardown"
		and manager.state == NetworkSessionManager.SessionState.OFFLINE
	):
		cycles_completed += 1
		if cycles_completed >= CYCLE_TARGET:
			var memory_delta := Performance.get_monitor(Performance.MEMORY_STATIC) - starting_memory
			print(
				(
					"NLB_P02_MULTI_PROCESS PASSED cycles=%d game_port=%d discovery_port=%d seats=%d peers=%d cache=%d static_memory_delta=%d"
					% [
						cycles_completed,
						GAME_PORT,
						DISCOVERY_PORT,
						manager.router.registry.joined_seats().size(),
						manager.transport.peer_count(),
						manager.candidates.size(),
						memory_delta,
					]
				)
			)
			quit(0)
			return
		_start_cycle()


func _run_client_step(delta: float) -> void:
	if manager.client_ready and phase.is_empty():
		phase = "ready"
		ready_wait = 0.0
	if phase == "ready":
		ready_wait += delta
		if ready_wait >= 0.25:
			manager.stop_session()
			phase = "leaving"
	elif phase == "leaving" and manager.state == NetworkSessionManager.SessionState.OFFLINE:
		print("NLB_P02_CLIENT_PROCESS PASSED assigned_ready_left=true")
		quit(0)
	elif manager.state == NetworkSessionManager.SessionState.LOBBY_OPEN and timer > 12.0:
		_fail("Client process timed out before ready.")
	timer += delta


func _on_host_lobby_changed() -> void:
	for seat in manager.router.registry.joined_seats():
		if str(seat.device_kind) == "remote" and bool(seat.ready):
			saw_ready = true
			return


func _first_lan_ipv4() -> String:
	for info in IP.get_local_interfaces():
		for address in info.get("addresses", []):
			var text_address := str(address)
			if (
				text_address.contains(".")
				and not text_address.begins_with("127.")
				and not text_address.begins_with("169.254.")
				and text_address != "0.0.0.0"
			):
				return text_address
	return ""


func _fail(reason: String) -> void:
	push_error("NLB_P02_MULTI_PROCESS FAILED: " + reason)
	if manager != null:
		manager.stop_session()
	quit(1)

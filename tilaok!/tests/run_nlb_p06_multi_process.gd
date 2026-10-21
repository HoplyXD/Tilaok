# gdlint: disable=max-line-length
extends SceneTree

## NLB-P06 live slice runner. Host mode (default) starts the production GameFlow on the opt-in
## network live-build route, reserves a synthetic local K1 seat, spawns a separate headless client
## process and runs Pugad -> GO -> live placement -> race -> results -> next Pugad twice.
## `-- phone` writes user://p06-phone-invite.txt and waits for a real Android client instead.
## Synthetic K1 and headless clients are never phone or physical-controller evidence.
## Run: Godot --headless --fixed-fps 60 --path tilaok! --script res://tests/run_nlb_p06_multi_process.gd [-- phone]

const TEST_GAME_PORT := 29781
const TEST_DISCOVERY_PORT := 29782
const SLICE_TIMEOUT_MS := 600000
const REQUIRED_ROUNDS := 2
const NETWORK_FLOW := preload("res://scenes/flow/game_flow.tscn")

var mode := "host"
var args := PackedStringArray()
var flow: GameFlow
var host_address := ""
var client_pid := -1
var start_ms := 0
var match_started := false
var phone_test := false
var debug_log_path := ""
var remote_seat_at_start := -1
var completed_rounds := 0
var network_results := 0
var local_results := 0
var _last_phase := -1
var _local_submitted_round := -1
var _last_status_ms := 0
var _client_ghost: NetworkLivePlacementClient
var _client_build_round := -1
var _client_confirm_at_ms := 0
var _client_terminal_results := 0
var _client_rounds_seen: Dictionary = {}
var _client_was_active := false


func _initialize() -> void:
	args = OS.get_cmdline_user_args()
	if not args.is_empty() and args[0] == "client":
		mode = "client"
		if args.size() > 4:
			debug_log_path = str(args[4])
	elif not args.is_empty() and args[0] == "phone":
		phone_test = true
	call_deferred("_start")


func _process(_delta: float) -> bool:
	if flow == null:
		return false
	if Time.get_ticks_msec() - start_ms > SLICE_TIMEOUT_MS:
		_fail("P06 live slice timed out in %s mode." % mode)
		return false
	if mode == "client":
		_step_client()
	else:
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
	if mode == "client":
		_start_client()
	else:
		_start_host()


func _start_host() -> void:
	host_address = _first_lan_ipv4()
	if host_address.is_empty():
		_fail("No usable LAN IPv4 address was available.")
		return
	var manager := flow.network_session
	# Same effect as `-- --match-route=network_live_build`; this runner's user args select its mode.
	flow.network_live_build_requested = true
	manager.network_route = NetworkSessionManager.ROUTE_LIVE_BUILD
	# NLB-P07: no live cell is VERIFIED yet, so this engineering slice runs under the logged
	# development override (same effect as `-- --nlb-unverified-content`). Not release evidence.
	manager.live_unverified_content = true
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
	_log("P06_SLICE_HOST address=%s port=%d route=network_live_build" % [host_address, TEST_GAME_PORT])
	if phone_test:
		var invite := FileAccess.open(OS.get_user_data_dir().path_join("p06-phone-invite.txt"), FileAccess.WRITE)
		if invite != null:
			invite.store_line(host_address)
			invite.store_line(str(TEST_GAME_PORT))
			invite.store_line(manager.invitation_code)
			invite.flush()
		return
	var command_line := PackedStringArray([
		"--headless", "--fixed-fps", "60", "--path", ProjectSettings.globalize_path("res://"),
		"--script", "res://tests/run_nlb_p06_multi_process.gd", "--", "client", host_address,
		str(TEST_GAME_PORT), manager.invitation_code,
		OS.get_user_data_dir().path_join("p06-client-debug.log"),
	])
	client_pid = OS.create_process(OS.get_executable_path(), command_line, false)
	if client_pid <= 0:
		_fail("Could not start the separate production client process.")


func _step_host() -> void:
	var manager := flow.network_session
	if not match_started and manager.router.registry.all_joined_ready_and_connected() and manager.router.registry.joined_seats().size() >= 2:
		match_started = manager.start_network_match()
		if not match_started:
			_fail("Host rejected the ready live-build network match.")
			return
	var room := manager.match_room as NLBP06NetworkLiveBuildMatchRoom
	if not match_started or room == null:
		return
	if not room.live_placement_boundary_resolved.is_connected(_on_host_boundary):
		room.live_placement_boundary_resolved.connect(_on_host_boundary)
		remote_seat_at_start = _remote_seat(manager)
	if _remote_seat(manager) != remote_seat_at_start:
		_fail("The remote seat identity changed during the slice.")
		return
	var phase := int(room.phase_controller.phase)
	if phase != _last_phase:
		_log("HOST_PHASE phase=%d round=%d stage=%d pieces=%d scores=%s" % [phase, room.items.round_number, room.items.stage_version, room.items.pieces.size(), str(room.cumulative_score_units)])
		if _last_phase == MatchPhaseController.Phase.RESULTS and phase == MatchPhaseController.Phase.PUGAD:
			completed_rounds += 1
		_last_phase = phase
	if phase == MatchPhaseController.Phase.PLAY and _local_submitted_round != room.items.round_number:
		_submit_synthetic_local(room)
	if Time.get_ticks_msec() - _last_status_ms > 2000:
		_last_status_ms = Time.get_ticks_msec()
		_log("HOST_STATUS rounds=%d network_results=%d local_results=%d" % [completed_rounds, network_results, local_results])
	if completed_rounds >= REQUIRED_ROUNDS and network_results >= REQUIRED_ROUNDS:
		print(
			"NLB_P06_%s PASSED rounds=%d network_results=%d local_results=%d remote_seat=%d stage=%d pieces=%d"
			% ["PHONE" if phone_test else "MULTI_PROCESS", completed_rounds, network_results, local_results, remote_seat_at_start, room.items.stage_version, room.items.pieces.size()]
		)
		manager.stop_session()
		quit(0)


## Synthetic K1: the same room confirm path a keyboard seat uses (build mode, cursor, submit).
func _submit_synthetic_local(room: NLBP06NetworkLiveBuildMatchRoom) -> void:
	if not room.placement_controller.cursors.has(0) or bool(room.inventory_used.get(0, false)):
		return
	_local_submitted_round = room.items.round_number
	var cursor: Dictionary = room.placement_controller.cursors[0]
	var actor_rects := room._live_actor_swept_rects()
	for y in range(room.tuning.arena_height_tiles):
		for x in range(room.tuning.arena_width_tiles):
			var verdict := room.items.validate_placement(str(cursor.variant_key), Vector2i(x, y), int(cursor.quarter_turns), room.items.owner_seat_clearance(actor_rects))
			if bool(verdict.get("allowed", false)):
				cursor.cell = Vector2i(x, y)
				room.placement_controller.cursors[0] = cursor
				room.build_mode[0] = true
				room._submit_live_placement(0)
				_log("HOST_LOCAL_SUBMIT round=%d cell=%s" % [room.items.round_number, str(cursor.cell)])
				return


func _on_host_boundary(results: Array) -> void:
	for result_variant in results:
		var result: Dictionary = result_variant
		var is_network := str(result.get("request_id", "")).begins_with("net:")
		if is_network:
			network_results += 1
		else:
			local_results += 1
		_log("HOST_RESULT network=%s seat=%d code=%s stage=%d" % [str(is_network), int(result.get("seat_index", -1)), str(result.get("code", "")), int(result.get("stage_version", -1))])


func _start_client() -> void:
	if args.size() < 4:
		_fail("Client process arguments were incomplete.")
		return
	var manager := flow.network_session
	manager.client_message.connect(func(message: String) -> void: _log("CLIENT_MESSAGE " + message))
	manager.client_assigned.connect(func(_seat: int) -> void: manager.set_client_ready(true))
	manager.placement_result_received.connect(
		func(result: Dictionary) -> void:
			if int(result.status) != NetworkPlacementCodec.Status.QUEUED:
				_client_terminal_results += 1
			_log("CLIENT_RESULT id=%d status=%d reason=%d detail=%d entity=%d stage=%d" % [int(result.request_id), int(result.status), int(result.reason), int(result.detail), int(result.entity_id), int(result.stage_version)])
	)
	manager.terrain_resync_changed.connect(func(gap: bool) -> void: _log("CLIENT_TERRAIN_GAP %s" % str(gap)))
	if not manager.connect_client(str(args[1]), int(args[2]), str(args[3])):
		_fail("Production client transport could not start.")
		return
	_log("P06_SLICE_CLIENT connecting=true")


func _step_client() -> void:
	var manager := flow.network_session
	if _client_was_active and manager.state == NetworkSessionManager.SessionState.OFFLINE:
		print(
			"P06_SLICE_CLIENT finished rounds_seen=%d terminal_results=%d stage=%d"
			% [_client_rounds_seen.size(), _client_terminal_results, int(manager.client_replica_state.get("stage_version", -1))]
		)
		quit(0)
		return
	if not manager.match_active or not manager.sync_ready:
		return
	_client_was_active = true
	if _client_ghost == null:
		var presentation := flow.network_presentation
		_client_ghost = presentation.live_client if presentation != null else null
		if _client_ghost == null:
			return
	var metadata: Dictionary = manager.client_replica_state.get("metadata", {})
	var phase := int(metadata.get("phase", -1))
	var round_id := int(manager.client_replica_state.get("round_id", 0))
	_client_rounds_seen[round_id] = true
	if phase == MatchPhaseController.Phase.PLAY and _client_build_round != round_id and _client_ghost.item_available():
		_client_build_round = round_id
		_client_ghost.toggle_build()
		_client_confirm_at_ms = Time.get_ticks_msec() + 600
		_log("CLIENT_BUILD round=%d cell=%s stage=%d" % [round_id, str(_client_ghost.cell), int(manager.client_replica_state.stage_version)])
	if _client_confirm_at_ms > 0 and Time.get_ticks_msec() >= _client_confirm_at_ms:
		_client_confirm_at_ms = 0
		_log("CLIENT_CONFIRM sent=%s" % str(_client_ghost.confirm()))


func _remote_seat(manager: NetworkSessionManager) -> int:
	for seat in manager.router.registry.joined_seats():
		if str(seat.device_kind) == "remote":
			return int(seat.seat)
	return -1


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
	push_error("NLB_P06_SLICE FAILED: " + reason)
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

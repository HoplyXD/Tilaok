# gdlint: disable=max-line-length
extends SceneTree

const QR_CODE_SCRIPT := preload("res://addons/qr_code/qr_code.gd")
const INVITATION_URI_SCRIPT := preload("res://scripts/network/invitation_uri.gd")

var failures: Array[String] = []
var checks := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_wire_and_credentials()
	_test_manifest_stability()
	_test_qr_invite_code()
	_test_invitation_uri_parser()
	await _test_raw_enet_admission()
	if failures.is_empty():
		print("NLB_P02_TESTS PASSED checks=%d" % checks)
		quit(0)
	else:
		for failure in failures:
			push_error("NLB_P02_TEST_FAILED " + failure)
		print("NLB_P02_TESTS FAILED checks=%d failures=%d" % [checks, failures.size()])
		quit(1)


func _test_wire_and_credentials() -> void:
	var payload := PackedByteArray([1, 2, 3, 4])
	var frame := NetworkFrame.encode(NetworkFrame.Family.READY_REQUEST, 77, 9, payload)
	var decoded := NetworkFrame.decode(frame, 77)
	_check(
		(
			bool(decoded.ok)
			and int(decoded.family) == NetworkFrame.Family.READY_REQUEST
			and decoded.payload == payload
		),
		"wire round trip"
	)
	_check(not NetworkFrame.decode(frame, 78).ok, "stale epoch rejected")
	_check(not NetworkFrame.decode(frame.slice(0, frame.size() - 1)).ok, "truncated frame rejected")
	_check(
		(
			NetworkFrame.encode(NetworkFrame.Family.READY_REQUEST, 1, 1, PackedByteArray()).size()
			== NetworkFrame.HEADER_BYTES
		),
		"empty payload envelope size"
	)
	_check(
		(
			NetworkFrame.encode(NetworkFrame.Family.READY_REQUEST, 1, 1, PackedByteArray()).size()
			<= NetworkFrame.MAX_FRAME_BYTES
		),
		"frame bound"
	)
	var token := InvitationCode.generate()
	var code := InvitationCode.encode(token)
	_check(token.size() == 16 and code.length() == 26, "invitation credential length")
	_check(InvitationCode.decode(code) == token, "invitation base32 round trip")
	_check(InvitationCode.decode("A".repeat(26)).size() == 16, "zero token code parses")
	_check(InvitationCode.decode("!".repeat(26)).is_empty(), "invalid invitation code rejected")
	var client_nonce := InvitationCode.generate()
	var server_nonce := InvitationCode.generate()
	var proof := InvitationCode.proof(token, 77, client_nonce, server_nonce)
	_check(proof.size() == 32, "HMAC-SHA-256 proof length")
	_check(
		Crypto.new().constant_time_compare(
			proof, InvitationCode.proof(token, 77, client_nonce, server_nonce)
		),
		"HMAC transcript stable"
	)


func _test_manifest_stability() -> void:
	var first := CompatibilityManifest.build()
	var second := CompatibilityManifest.build()
	_check(first.digest.size() == 32, "SHA-256 manifest digest length")
	_check(
		first.bytes == second.bytes and first.digest == second.digest,
		"manifest stable across recompute"
	)
	_check(
		not first.bytes.get_string_from_utf8().contains("res://"),
		"manifest excludes resource paths"
	)


func _test_qr_invite_code() -> void:
	var test_invite := (
		"tilaok://join?lobby=AAAAAAAAAAAAA&host=192.0.2.1&port=27777&protocol=1.1&digest=%s&code=AAAAAAAAAAAAAAAAAAAAAAAAAA"
		% "0".repeat(64)
	)
	var qr = QR_CODE_SCRIPT.new()
	qr.put_byte(test_invite.to_utf8_buffer())
	qr.encode()
	var image: Image = qr.generate_image(6)
	_check(image != null and not image.is_empty(), "invitation QR generator returns an image")
	if image == null or image.is_empty():
		return
	var directory := ProjectSettings.globalize_path("res://docs/evidence/nlb/p02/captures")
	DirAccess.make_dir_recursive_absolute(directory)
	var save_error := image.save_png(directory.path_join("invitation-test-invalid.png"))
	_check(save_error == OK, "synthetic invalid invitation QR saved for independent decoding")


func _test_invitation_uri_parser() -> void:
	var valid := (
		"tilaok://join?lobby=AAAAAAAAAAAAA&host=192.168.1.22&port=27777&protocol=1.1&digest=%s&code=AAAAAAAAAAAAAAAAAAAAAAAAAA&epoch=7"
		% "a".repeat(64)
	)
	var parsed: Dictionary = INVITATION_URI_SCRIPT.parse(valid)
	_check(bool(parsed.ok), "approved invitation URI parses")
	_check(parsed.get("address", "") == "192.168.1.22", "invitation URI returns validated host")
	_check(
		parsed.get("port", 0) == 27777 and parsed.get("epoch", 0) == 7,
		"invitation URI returns bounded endpoint and epoch"
	)
	_check(
		parsed.get("digest", PackedByteArray()).size() == 32,
		"invitation URI decodes canonical digest"
	)
	_check(
		not INVITATION_URI_SCRIPT.parse(valid + "&host=10.0.0.1").ok,
		"duplicate invitation field rejected"
	)
	_check(
		not INVITATION_URI_SCRIPT.parse(valid.replace("protocol=1.1", "protocol=9.0")).ok,
		"unsupported invitation protocol rejected"
	)
	_check(
		not INVITATION_URI_SCRIPT.parse(valid.replace("host=192.168.1.22", "host=0.0.0.0")).ok,
		"unspecified invitation address rejected"
	)
	_check(
		not INVITATION_URI_SCRIPT.parse(valid.replace("port=27777", "port=99999")).ok,
		"out-of-range invitation port rejected"
	)
	_check(
		not INVITATION_URI_SCRIPT.parse(valid.replace("digest=" + "a".repeat(64), "digest=abc")).ok,
		"short invitation digest rejected"
	)
	_check(
		not INVITATION_URI_SCRIPT.parse(valid.replace("epoch=7", "epoch=0")).ok,
		"zero invitation epoch rejected"
	)
	_check(not INVITATION_URI_SCRIPT.parse(valid + "%20").ok, "encoded invitation fields rejected")
	_check(
		not INVITATION_URI_SCRIPT.parse("https://example.invalid/?host=192.168.1.22").ok,
		"arbitrary URL scheme rejected"
	)


func _test_raw_enet_admission() -> void:
	var host_address := ""
	for item in _interface_options():
		if item.eligible and not item.addresses.is_empty():
			host_address = str(item.addresses[0])
			break
	if host_address.is_empty():
		_check(false, "LAN host interface available (COULD-NOT-RUN)")
		return
	var host_router := LocalInputRouter.new()
	var client_router := LocalInputRouter.new()
	root.add_child(host_router)
	root.add_child(client_router)
	var host := NetworkSessionManager.new()
	var client := NetworkSessionManager.new()
	host.configure(host_router)
	client.configure(client_router)
	root.add_child(host)
	root.add_child(client)
	var auto_approve := [true]
	var pending_peer := [-1]
	host.approval_requested.connect(
		func(peer_id: int, _compat: Dictionary) -> void:
			pending_peer[0] = peer_id
			if auto_approve[0]:
				host.approve_peer(peer_id)
	)
	client.client_message.connect(
		func(message: String) -> void: print("P02_CLIENT_STATUS " + message)
	)
	var assignment_seen := [false]
	client.client_assigned.connect(
		func(_seat: int) -> void:
			assignment_seen[0] = true
			client.set_client_ready(true)
	)
	var port := 28777
	var discovery_port := 28778
	var host_started := host.start_host(host_address, port, discovery_port)
	_check(host_started, "production session host binds ENet and discovery")
	if not host_started:
		client.stop_session()
		host.stop_session()
		return
	var scanner := LanDiscovery.new()
	var scan_started := scanner.start_client(discovery_port) == OK
	_check(scan_started, "LAN discovery client binds an ephemeral UDP port")
	if scan_started:
		scanner.query(host.lobby_id, host_address)
		var discovery_deadline := Time.get_ticks_msec() + 2500
		while (
			Time.get_ticks_msec() < discovery_deadline
			and scanner.get_lobby(host.lobby_id).is_empty()
		):
			scanner.process(0.05)
			host.discovery.process(0.05)
			await process_frame
		_check(
			not scanner.get_lobby(host.lobby_id).is_empty(),
			"Lobby ID query discovers the matching host"
		)
		_check(
			scanner.last_received_frame_bytes <= NetworkFrame.MAX_DISCOVERY_BYTES,
			"received discovery frame stays within bound"
		)
		_check(
			host.discovery.last_sent_frame_bytes <= NetworkFrame.MAX_DISCOVERY_BYTES,
			"host beacon stays within bound"
		)
		scanner.stop()
	var closed_client := NetworkSessionManager.new()
	var closed_router := LocalInputRouter.new()
	root.add_child(closed_router)
	closed_client.configure(closed_router)
	root.add_child(closed_client)
	host.close_admission()
	var closed_connect := closed_client.connect_client(host_address, port, host.invitation_code)
	_check(closed_connect, "closed-admission transport candidate can be exercised")
	for _frame in 12:
		await process_frame
	_check(
		host.router.registry.joined_seats().is_empty() and host._pending_count() == 0,
		"closed admission cannot assign or approve a seat"
	)
	await _clean_client(closed_client, closed_router)
	host.open_admission()
	var mismatched_client := NetworkSessionManager.new()
	var mismatched_router := LocalInputRouter.new()
	root.add_child(mismatched_router)
	mismatched_client.configure(mismatched_router)
	root.add_child(mismatched_client)
	var mismatch_seen := [false]
	mismatched_client.client_message.connect(
		func(message: String) -> void:
			if message.contains("match the host"):
				mismatch_seen[0] = true
	)
	var wrong_digest := PackedByteArray()
	wrong_digest.resize(32)
	wrong_digest.fill(1)
	var mismatch_started := mismatched_client.connect_client(
		host_address, port, host.invitation_code, wrong_digest
	)
	_check(mismatch_started, "incompatible candidate reaches compatibility validator")
	for _frame in 120:
		if mismatch_seen[0]:
			break
		await process_frame
	_check(mismatch_seen[0], "incompatible client build receives a readable rejection")
	_check(
		host.router.registry.joined_seats().is_empty() and host._pending_count() == 0,
		"incompatible client receives no seat or approval"
	)
	await _clean_client(mismatched_client, mismatched_router)
	var invalid_client := NetworkSessionManager.new()
	var invalid_router := LocalInputRouter.new()
	root.add_child(invalid_router)
	invalid_client.configure(invalid_router)
	root.add_child(invalid_client)
	var invalid_seen := [false]
	invalid_client.client_message.connect(
		func(message: String) -> void:
			if message.contains("invalid") or message.contains("expired"):
				invalid_seen[0] = true
	)
	var invalid_started := invalid_client.connect_client(host_address, port, "A".repeat(26))
	_check(invalid_started, "well-formed but invalid invitation candidate reaches proof validator")
	for _frame in 120:
		if invalid_seen[0]:
			break
		await process_frame
	_check(invalid_seen[0], "invalid invitation proof receives bounded rejection feedback")
	_check(
		host.router.registry.joined_seats().is_empty() and host._pending_count() == 0,
		"invalid invitation receives no seat or approval"
	)
	await _clean_client(invalid_client, invalid_router)
	var rejected_client := NetworkSessionManager.new()
	var rejected_router := LocalInputRouter.new()
	root.add_child(rejected_router)
	rejected_client.configure(rejected_router)
	root.add_child(rejected_client)
	var rejected_seen := [false]
	rejected_client.client_message.connect(
		func(message: String) -> void:
			if message.contains("declined"):
				rejected_seen[0] = true
	)
	auto_approve[0] = false
	pending_peer[0] = -1
	var reject_started := rejected_client.connect_client(host_address, port, host.invitation_code)
	_check(reject_started, "compatible client reaches the host approval decision")
	for _frame in 120:
		if pending_peer[0] >= 0:
			break
		await process_frame
	_check(
		pending_peer[0] >= 0 and host._pending_count() == 1,
		"proof enters bounded pending approval without a seat"
	)
	_check(host.reject_peer(pending_peer[0]), "host can reject a pending candidate")
	for _frame in 60:
		if rejected_seen[0]:
			break
		await process_frame
	_check(rejected_seen[0], "rejected join receives readable feedback")
	_check(host.router.registry.joined_seats().is_empty(), "rejected candidate receives no seat")
	await _clean_client(rejected_client, rejected_router)
	auto_approve[0] = true
	var room_code := host.invitation_code
	_check(room_code.length() == 26, "room invitation remains available after a rejected request")
	var connected := client.connect_client(host_address, port, room_code)
	_check(connected, "production raw ENet client connects")
	if not connected:
		client.stop_session()
		host.stop_session()
		return
	var deadline := Time.get_ticks_msec() + 8000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if (
			assignment_seen[0]
			and host.router.registry.joined_seats().size() == 1
			and host.router.registry.get_seat(0).ready
		):
			break
	print(
		(
			"P02_TRACE host_state=%s client_epoch_match=%s assigned_seat=%d"
			% [
				str(host.candidates.values().map(func(c: Dictionary) -> int: return int(c.state))),
				str(client.session_epoch == host.session_epoch),
				client.client_assigned_seat
			]
		)
	)
	_check(assignment_seen[0], "proof, approval and seat assignment complete")
	_check(
		host.router.registry.joined_seats().size() == 1, "host registry assigns exactly one seat"
	)
	_check(bool(host.router.registry.get_seat(0).ready), "ready updates assigned host seat")
	_check(
		host.invitation_code == room_code, "successful join keeps the same room access code active"
	)
	client.stop_session()
	var cleanup_deadline := Time.get_ticks_msec() + 2000
	while (
		Time.get_ticks_msec() < cleanup_deadline
		and not host.router.registry.joined_seats().is_empty()
	):
		await process_frame
	_check(host.router.registry.joined_seats().is_empty(), "disconnect releases remote seat")
	var repeat_client := NetworkSessionManager.new()
	var repeat_router := LocalInputRouter.new()
	root.add_child(repeat_router)
	repeat_client.configure(repeat_router)
	root.add_child(repeat_client)
	var repeat_assigned := [false]
	repeat_client.client_assigned.connect(func(_seat: int) -> void: repeat_assigned[0] = true)
	_check(
		repeat_client.connect_client(host_address, port, room_code),
		"same room access code can start another join"
	)
	for _frame in 150:
		if repeat_assigned[0]:
			break
		await process_frame
	_check(repeat_assigned[0], "same room access code completes another approved assignment")
	_check(host.invitation_code == room_code, "later join leaves the room code unchanged")
	await _clean_client(repeat_client, repeat_router)
	for layout in PlayerSeatRegistry.KEYBOARD_LAYOUTS:
		_check(
			host.router.registry.join_keyboard(layout) >= 0,
			"host local input can occupy the shared seat registry"
		)
	_check(
		host.router.registry.joined_seats().size() == PlayerSeatRegistry.MAX_SEATS,
		"local and remote seats share a four-player cap"
	)
	var full_code := host.invitation_code
	var full_client := NetworkSessionManager.new()
	var full_router := LocalInputRouter.new()
	root.add_child(full_router)
	full_client.configure(full_router)
	root.add_child(full_client)
	var full_seen := [false]
	full_client.client_message.connect(
		func(message: String) -> void:
			if message.contains("full"):
				full_seen[0] = true
	)
	var full_started := full_client.connect_client(host_address, port, full_code)
	_check(full_started, "full-lobby candidate reaches host capacity recheck")
	for _frame in 180:
		if full_seen[0]:
			break
		await process_frame
	_check(full_seen[0], "full lobby returns capacity feedback")
	_check(
		host.router.registry.joined_seats().size() == PlayerSeatRegistry.MAX_SEATS,
		"full-lobby candidate cannot exceed the shared seat cap"
	)
	await _clean_client(full_client, full_router)
	await _test_owned_malformed_flood(host, host_address, port)
	host.stop_session()
	for _frame in 60:
		if host.state == NetworkSessionManager.SessionState.OFFLINE:
			break
		await process_frame
	_check(
		(
			host.state == NetworkSessionManager.SessionState.OFFLINE
			and not host.transport.is_open
			and not host.discovery.listening
		),
		"idempotent session teardown closes transport"
	)
	_check(host.invitation_code.is_empty(), "stopping the room revokes its invitation")
	host.stop_session()
	_check(
		host.state == NetworkSessionManager.SessionState.OFFLINE, "repeated stop remains harmless"
	)
	host.free()
	client.free()
	host_router.free()
	client_router.free()


func _test_owned_malformed_flood(
	host: NetworkSessionManager, host_address: String, port: int
) -> void:
	var flood := RawEnetTransport.new()
	var local_peer := [0]
	flood.connected.connect(func(peer_id: int) -> void: local_peer[0] = peer_id)
	var opened := flood.open_client(host_address, port) == OK
	_check(opened, "owned malformed-flood client opens raw ENet session")
	if not opened:
		return
	var sent := 0
	var host_peer := -1
	var deadline := Time.get_ticks_msec() + 5000
	while Time.get_ticks_msec() < deadline:
		flood.poll()
		for candidate_peer in host.candidates.keys():
			if host._peer_abuse.has(candidate_peer) or host_peer < 0:
				host_peer = int(candidate_peer)
		var current_abuse: Dictionary = host._peer_abuse.get(host_peer, {})
		if int(current_abuse.get("format_failures", 0)) >= 120:
			break
		if local_peer[0] > 0:
			for _packet in 8:
				if flood.send(local_peer[0], PackedByteArray([0])) != OK:
					break
				sent += 1
		await process_frame
	_check(sent >= 120, "owned process sends at least 120 bounded malformed frames")
	for _frame in 90:
		if host_peer > 0 and not host.transport._peers.has(host_peer):
			break
		flood.poll()
		await process_frame
	var abuse: Dictionary = host._peer_abuse.get(host_peer, {})
	_check(
		int(abuse.get("format_failures", 0)) >= 120,
		"host counts 120 malformed frames against the test peer"
	)
	_check(
		int(abuse.get("logged", 0)) == 10 and int(abuse.get("suppressed", 0)) >= 110,
		"host suppresses detailed rejection logs after ten entries"
	)
	_check(
		not host.transport._peers.has(host_peer) and not host.candidates.has(host_peer),
		"host closes malformed flood peer and clears its pending candidate"
	)
	flood.close()


func _interface_options() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for info in IP.get_local_interfaces():
		var addresses: Array = []
		for address in info.get("addresses", []):
			var text_address := str(address)
			if (
				text_address.contains(".")
				and not text_address.begins_with("127.")
				and not text_address.begins_with("169.254.")
				and text_address != "0.0.0.0"
			):
				addresses.append(text_address)
		result.append({"addresses": addresses, "eligible": not addresses.is_empty()})
	return result


func _clean_client(manager: NetworkSessionManager, input_router: LocalInputRouter) -> void:
	manager.stop_session()
	for _frame in 60:
		if manager.state == NetworkSessionManager.SessionState.OFFLINE:
			break
		await process_frame
	manager.free()
	input_router.free()


func _check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)

# gdlint: disable=class-definitions-order,max-returns,max-file-lines
class_name NetworkSessionManager
extends Node

signal state_changed(state_name: String)
signal lobby_changed
signal approval_requested(peer_id: int, compatibility: Dictionary)
signal client_message(message: String)
signal client_assigned(seat_index: int)
signal session_error(message: String)

enum SessionState { OFFLINE, STARTING, LOBBY_OPEN, STOPPING }
enum CandidateState {
	COMPATIBILITY, CHALLENGE, PROOF, PENDING_APPROVAL, ASSIGNED, ACKNOWLEDGED, READY
}

const DEFAULT_GAME_PORT := 27777
const DEFAULT_DISCOVERY_PORT := 27778
const MAX_PENDING_APPROVALS := 4
const MAX_FRAME_EVENTS := 32
const CHALLENGE_TIMEOUT_SECONDS := 30
const INVITATION_LIFETIME_SECONDS := 300

var state := SessionState.OFFLINE
var admission_open := false
var selected_address := ""
var game_port := DEFAULT_GAME_PORT
var discovery_port := DEFAULT_DISCOVERY_PORT
var lobby_id := 0
var session_epoch := 0
var invitation_code := ""
var invitation_expires_unix := 0
var host_authority := SimulationAuthority.offline()
var local_authority := SimulationAuthority.offline()
var router: LocalInputRouter
var transport := RawEnetTransport.new()
var discovery := LanDiscovery.new()
var remote_adapter := RemoteSeatInputAdapter.new()
var candidates: Dictionary = {}
var client_mode := false
var client_assigned_seat := -1
var client_ready := false
var client_lobby_seats: Array[Dictionary] = []
var client_admission_open := false
var client_invite_token := PackedByteArray()
var client_manifest_digest := PackedByteArray()
var _client_expected_host_digest := PackedByteArray()
var _client_expected_host_epoch := 0
var manifest_digest := PackedByteArray()
var _manifest_revision := 0
var _cached_compatibility: Dictionary = {}
var _local_nonce := PackedByteArray()
var _sequences: Dictionary = {}
var _incoming_sequences: Dictionary = {}
var _idempotent_requests: Dictionary = {}
var _peer_abuse: Dictionary = {}
var _peer_family_times: Dictionary = {}
var _candidate_timer := 0.0
var _client_sequence := 0
var _client_connect_deadline := 0
var _client_transport_connected := false
var _client_disconnect_notice_set := false
var _pending_stop := false
var _stop_deadline := 0
var _manifest_source_stamp := ""
var _manifest_poll_clock := 0.0
var _interface_poll_clock := 0.0
var selected_interface_usable := true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	transport.connected.connect(_on_peer_connected)
	transport.disconnected.connect(_on_peer_disconnected)
	transport.packet_received.connect(_on_packet_received)
	transport.transport_error.connect(_on_transport_error)


func _process(delta: float) -> void:
	if transport.is_open:
		transport.poll()
	if not client_mode and _invitation_expired():
		_revoke_invitation()
		lobby_changed.emit()
	if (
		client_mode
		and _client_connect_deadline > 0
		and Time.get_ticks_msec() >= _client_connect_deadline
	):
		_client_connect_deadline = 0
		(
			client_message
			. emit(
				"Could not reach the host. Check that both devices share a reachable Wi-Fi network, then retry."
			)
		)
		stop_session()
	if discovery.listening:
		if state == SessionState.LOBBY_OPEN and not client_mode:
			discovery.occupancy = router.registry.joined_seats().size() if router != null else 0
			discovery.lobby_open = admission_open
		discovery.process(delta)
	if state == SessionState.LOBBY_OPEN:
		if not client_mode:
			_interface_poll_clock += delta
			if _interface_poll_clock >= 1.0:
				_interface_poll_clock = 0.0
				var usable := _interface_has_address(selected_address)
				if usable != selected_interface_usable:
					selected_interface_usable = usable
					if not usable:
						close_admission()
						discovery.stop()
					lobby_changed.emit()
		_manifest_poll_clock += delta
		if _manifest_poll_clock >= 2.0:
			_manifest_poll_clock = 0.0
			_poll_manifest_sources()
		_expire_candidates(delta)
	elif state == SessionState.STOPPING and _pending_stop:
		if transport.peer_count() == 0 or Time.get_ticks_msec() >= _stop_deadline:
			_finish_stop()


func configure(input_router: LocalInputRouter) -> bool:
	if input_router == null:
		return false
	router = input_router
	local_authority = input_router.authority
	return true


func start_host(
	address: String,
	requested_game_port: int = DEFAULT_GAME_PORT,
	requested_discovery_port: int = DEFAULT_DISCOVERY_PORT
) -> bool:
	if (
		state != SessionState.OFFLINE
		or not _valid_ports(requested_game_port, requested_discovery_port)
	):
		return false
	state = SessionState.STARTING
	state_changed.emit("STARTING")
	if router == null or address.is_empty() or not _interface_has_address(address):
		return _rollback_start("Choose a usable IPv4 interface.")
	CompatibilityManifest.reload_sources()
	_manifest_source_stamp = CompatibilityManifest.source_fingerprint()
	var manifest := CompatibilityManifest.build()
	_cached_compatibility = manifest
	manifest_digest = manifest.digest
	var host_error := transport.open_host(address, requested_game_port)
	if host_error != OK:
		return _rollback_start("Could not bind the game port (%d)." % host_error)
	var random := InvitationCode.generate()
	if random.size() != 16:
		return _rollback_start("Could not create a secure invitation.")
	var id_bytes := Crypto.new().generate_random_bytes(8)
	var epoch_bytes := Crypto.new().generate_random_bytes(8)
	id_bytes[7] = int(id_bytes[7]) & 0x7f
	epoch_bytes[7] = int(epoch_bytes[7]) & 0x7f
	lobby_id = _bytes_to_u64(id_bytes)
	session_epoch = _bytes_to_u64(epoch_bytes)
	if lobby_id == 0:
		lobby_id = 1
	if session_epoch == 0:
		session_epoch = 1
	_set_invitation(random)
	selected_address = address
	selected_interface_usable = true
	_interface_poll_clock = 0.0
	game_port = requested_game_port
	discovery_port = requested_discovery_port
	host_authority = SimulationAuthority.host()
	router.set_authority(host_authority)
	remote_adapter.configure(router, host_authority)
	var discovery_error := discovery.start_host(
		address, discovery_port, lobby_id, session_epoch, manifest_digest
	)
	if discovery_error != OK:
		return _rollback_start("Could not bind the discovery port (%d)." % discovery_error)
	discovery.game_port = game_port
	game_port = transport.connection.get_local_port()
	discovery_port = discovery.socket.get_local_port()
	admission_open = true
	client_mode = false
	state = SessionState.LOBBY_OPEN
	state_changed.emit("LOBBY_OPEN")
	lobby_changed.emit()
	return true


func create_invitation() -> bool:
	if (
		client_mode
		or state != SessionState.LOBBY_OPEN
		or not admission_open
		or not transport.is_host
	):
		return false
	var random := InvitationCode.generate()
	if random.size() != 16:
		return false
	_set_invitation(random)
	lobby_changed.emit()
	return true


func connect_client(
	address: String,
	port: int,
	code: String,
	digest: PackedByteArray = PackedByteArray(),
	expected_epoch: int = 0
) -> bool:
	if (
		state != SessionState.OFFLINE
		or port < 1024
		or port > 65535
		or not address.is_valid_ip_address()
		or address == "0.0.0.0"
		or address == "255.255.255.255"
	):
		client_message.emit("Enter a valid host IP address and port.")
		return false
	var token := InvitationCode.decode(code)
	if token.size() != 16:
		client_message.emit("Enter the 26-character access code.")
		return false
	state = SessionState.STARTING
	state_changed.emit("STARTING")
	_client_disconnect_notice_set = false
	client_invite_token = token
	CompatibilityManifest.reload_sources()
	var manifest := CompatibilityManifest.build()
	client_manifest_digest = manifest.digest
	_client_expected_host_digest = digest.duplicate()
	_client_expected_host_epoch = expected_epoch
	var error := transport.open_client(address, port)
	if error != OK:
		return _rollback_start("Could not connect to the host (%d)." % error)
	client_mode = true
	_client_connect_deadline = Time.get_ticks_msec() + 8000
	_client_transport_connected = false
	selected_address = address
	game_port = port
	manifest_digest = client_manifest_digest
	state = SessionState.LOBBY_OPEN
	state_changed.emit("LOBBY_OPEN")
	return true


func stop_session() -> void:
	if state == SessionState.OFFLINE:
		discovery.stop()
		return
	if state == SessionState.STOPPING:
		return
	state = SessionState.STOPPING
	state_changed.emit("STOPPING")
	admission_open = false
	if transport.is_open:
		if transport.is_host:
			for peer_id in candidates.keys():
				_send(
					int(peer_id),
					NetworkFrame.Family.SESSION_CLOSE,
					_u16(NetworkFrame.Reason.SESSION_CLOSED)
				)
		else:
			for peer_id in _connected_peer_ids():
				_send(int(peer_id), NetworkFrame.Family.SESSION_CLOSE, _u16(NetworkFrame.Reason.OK))
		transport.request_disconnect_all()
	discovery.stop()
	for seat in router.registry.joined_seats() if router != null else []:
		if str(seat.device_kind) == "remote":
			remote_adapter.release_source(str(seat.remote_source_id))
	_revoke_invitation()
	_pending_stop = true
	_stop_deadline = Time.get_ticks_msec() + 500
	if not transport.is_open or transport.peer_count() == 0:
		_finish_stop()
	lobby_changed.emit()


func _finish_stop() -> void:
	_pending_stop = false
	transport.close()
	candidates.clear()
	_sequences.clear()
	_incoming_sequences.clear()
	_idempotent_requests.clear()
	_peer_abuse.clear()
	_peer_family_times.clear()
	_revoke_invitation()
	lobby_id = 0
	session_epoch = 0
	selected_address = ""
	client_assigned_seat = -1
	client_ready = false
	client_lobby_seats.clear()
	client_admission_open = false
	client_invite_token.clear()
	_client_expected_host_digest.clear()
	_client_expected_host_epoch = 0
	client_mode = false
	_client_connect_deadline = 0
	_client_transport_connected = false
	_client_disconnect_notice_set = false
	manifest_digest.clear()
	_cached_compatibility.clear()
	if router != null:
		router.set_authority(local_authority)
	host_authority = SimulationAuthority.offline()
	remote_adapter.configure(router, host_authority)
	if router != null:
		router.set_authority(local_authority)
	state = SessionState.OFFLINE
	state_changed.emit("OFFLINE")
	lobby_changed.emit()


func approve_peer(peer_id: int) -> bool:
	if _poll_manifest_sources():
		return false
	if not admission_open or not candidates.has(peer_id):
		return false
	var candidate: Dictionary = candidates[peer_id]
	if (
		candidate.state != CandidateState.PENDING_APPROVAL
		or _pending_count() > MAX_PENDING_APPROVALS
	):
		return false
	if (
		not _manifest_is_current()
		or router.registry.joined_seats().size() >= PlayerSeatRegistry.MAX_SEATS
	):
		_send(peer_id, NetworkFrame.Family.ADMISSION_DECISION, _u16(NetworkFrame.Reason.LOBBY_FULL))
		transport.close_peer(peer_id, true)
		return false
	var source_id := "peer_%d" % peer_id
	var seat_index := remote_adapter.assign_source(source_id)
	if seat_index < 0:
		_send(peer_id, NetworkFrame.Family.ADMISSION_DECISION, _u16(NetworkFrame.Reason.LOBBY_FULL))
		transport.close_peer(peer_id, true)
		return false
	candidate.state = CandidateState.ASSIGNED
	candidate.seat = seat_index
	candidate.deadline = Time.get_ticks_msec() + CHALLENGE_TIMEOUT_SECONDS * 1000
	candidates[peer_id] = candidate
	var payload := PackedByteArray([seat_index, seat_index])
	_send(peer_id, NetworkFrame.Family.ADMISSION_DECISION, _u16(NetworkFrame.Reason.OK))
	_send(peer_id, NetworkFrame.Family.SEAT_ASSIGNMENT, payload)
	_broadcast_lobby_state()
	lobby_changed.emit()
	return true


func reject_peer(peer_id: int) -> bool:
	if not candidates.has(peer_id) or candidates[peer_id].state != CandidateState.PENDING_APPROVAL:
		return false
	var decision := _u16(NetworkFrame.Reason.APPROVAL_REQUIRED)
	decision.append(2)
	_send(peer_id, NetworkFrame.Family.ADMISSION_DECISION, decision)
	transport.close_peer(peer_id, true)
	candidates.erase(peer_id)
	lobby_changed.emit()
	return true


func set_client_ready(ready: bool) -> bool:
	if not client_mode or client_assigned_seat < 0 or not transport.is_open:
		return false
	_client_sequence += 1
	return _send_to_host(NetworkFrame.Family.READY_REQUEST, PackedByteArray([1 if ready else 0]))


func close_admission() -> void:
	admission_open = false
	if discovery.listening:
		discovery.lobby_open = false
	_broadcast_lobby_state()
	lobby_changed.emit()


func open_admission() -> void:
	if state == SessionState.LOBBY_OPEN and not client_mode:
		admission_open = true
		discovery.lobby_open = true
		_broadcast_lobby_state()
		lobby_changed.emit()


func start_gate_status() -> String:
	if state != SessionState.LOBBY_OPEN:
		return "Start a host session first."
	if _poll_manifest_sources():
		return "Content changed; refresh the invitation and rejoin before continuing."
	if not _manifest_is_current():
		return "Content changed; invitations and readiness need refreshing."
	if not selected_interface_usable:
		return "Selected interface is unavailable. Stop the session and choose a current interface."
	if not admission_open:
		return "Admission is closed."
	if router.registry.joined_seats().size() < 2:
		return "At least two players are required."
	if not router.registry.all_joined_ready_and_connected():
		return "Every assigned player must be connected and ready."
	return "Network gameplay unavailable until a later phase."


func interface_options() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for info in IP.get_local_interfaces():
		var addresses: Array = []
		for address in info.get("addresses", []):
			var candidate := str(address)
			if _is_usable_ipv4(candidate):
				addresses.append(candidate)
		(
			result
			. append(
				{
					"name": str(info.get("friendly", info.get("name", "Network interface"))),
					"addresses": addresses,
					"eligible": not addresses.is_empty(),
					"status": "Ready" if not addresses.is_empty() else "Manual address only",
				}
			)
		)
	return result


func _on_peer_connected(peer_id: int) -> void:
	if client_mode:
		_client_transport_connected = true
		_client_connect_deadline = 0
		_local_nonce = InvitationCode.generate()
		return
	if not admission_open or transport.peer_count() > RawEnetTransport.MAX_PEERS:
		transport.close_peer(peer_id)
		return
	candidates[peer_id] = {
		"state": CandidateState.COMPATIBILITY,
		"deadline": Time.get_ticks_msec() + CHALLENGE_TIMEOUT_SECONDS * 1000,
		"nonce": PackedByteArray(),
		"server_nonce": PackedByteArray(),
		"seat": -1,
	}
	var welcome := _u16(NetworkFrame.Reason.OK)
	welcome.append_array(manifest_digest)
	_send(peer_id, NetworkFrame.Family.COMPATIBILITY_RESULT, welcome)


func _on_peer_disconnected(peer_id: int) -> void:
	if client_mode:
		client_assigned_seat = -1
		client_ready = false
		if state != SessionState.STOPPING:
			if not _client_disconnect_notice_set:
				client_message.emit("Host connection closed.")
			stop_session()
		return
	if candidates.has(peer_id):
		var candidate: Dictionary = candidates[peer_id]
		if int(candidate.seat) >= 0:
			remote_adapter.release_source("peer_%d" % peer_id)
		candidates.erase(peer_id)
		_broadcast_lobby_state()
		lobby_changed.emit()


func _on_packet_received(peer_id: int, channel: int, packet: PackedByteArray) -> void:
	if channel != RawEnetTransport.CONTROL_CHANNEL:
		_reject(peer_id, NetworkFrame.Reason.MALFORMED)
		return
	var decoded := NetworkFrame.decode(packet, -1 if client_mode else session_epoch, false)
	if not bool(decoded.ok):
		_reject(peer_id, int(decoded.reason))
		return
	if not _accept_incoming_sequence(peer_id, int(decoded.family), int(decoded.sequence)):
		_reject(peer_id, NetworkFrame.Reason.STALE_STATE)
		return
	if not _accept_rate(peer_id, int(decoded.family)):
		_reject(peer_id, NetworkFrame.Reason.RATE_LIMIT)
		return
	if client_mode:
		if _client_expected_host_epoch > 0 and int(decoded.epoch) != _client_expected_host_epoch:
			client_message.emit("This invitation belongs to an older host session.")
			stop_session()
			return
		if session_epoch == 0:
			session_epoch = int(decoded.epoch)
		elif int(decoded.epoch) != session_epoch:
			client_message.emit("The host session changed during connection.")
			return
		_handle_client_packet(peer_id, int(decoded.family), decoded.payload)
	else:
		_handle_host_packet(peer_id, int(decoded.family), decoded.payload)


func _handle_host_packet(peer_id: int, family: int, payload: PackedByteArray) -> void:
	if not candidates.has(peer_id):
		_reject(peer_id, NetworkFrame.Reason.OWNERSHIP)
		return
	var candidate: Dictionary = candidates[peer_id]
	match family:
		NetworkFrame.Family.COMPATIBILITY_HELLO:
			if _poll_manifest_sources():
				return
			if not candidates.has(peer_id):
				return
			candidate = candidates[peer_id]
			if candidate.state != CandidateState.COMPATIBILITY or payload.size() != 38:
				_reject(peer_id, NetworkFrame.Reason.MALFORMED)
				return
			if (
				payload.slice(0, 32) != manifest_digest
				or int(payload[32]) != NetworkFrame.MAJOR
				or int(payload[33]) > NetworkFrame.MINOR
				or int(payload[34]) != 1
				or int(payload[35]) != 0
				or int(payload[36]) != 15
				or int(payload[37]) != 0
			):
				_send(
					peer_id,
					NetworkFrame.Family.COMPATIBILITY_RESULT,
					_u16(NetworkFrame.Reason.INCOMPATIBLE)
				)
				transport.close_peer(peer_id)
				return
			candidate.state = CandidateState.CHALLENGE
			_send(peer_id, NetworkFrame.Family.COMPATIBILITY_RESULT, _u16(NetworkFrame.Reason.OK))
			candidates[peer_id] = candidate
		NetworkFrame.Family.JOIN_BEGIN:
			if candidate.state != CandidateState.CHALLENGE or payload.size() != 16:
				_reject(peer_id, NetworkFrame.Reason.MALFORMED)
				return
			candidate.nonce = payload.duplicate()
			candidate.server_nonce = InvitationCode.generate()
			candidate.state = CandidateState.PROOF
			candidate.deadline = Time.get_ticks_msec() + CHALLENGE_TIMEOUT_SECONDS * 1000
			var challenge: PackedByteArray = candidate.nonce.duplicate()
			challenge.append_array(candidate.server_nonce)
			_send(peer_id, NetworkFrame.Family.CHALLENGE, challenge)
			candidates[peer_id] = candidate
		NetworkFrame.Family.PROOF:
			if candidate.state != CandidateState.PROOF or payload.size() != 64:
				_reject(peer_id, NetworkFrame.Reason.MALFORMED)
				return
			var client_nonce := payload.slice(0, 16)
			var proof_value := payload.slice(32, 64)
			if client_nonce != candidate.nonce or payload.slice(16, 32) != candidate.server_nonce:
				_reject(peer_id, NetworkFrame.Reason.MALFORMED)
				return
			if _invitation_expired():
				_revoke_invitation()
				lobby_changed.emit()
				_reject(peer_id, NetworkFrame.Reason.TOKEN_EXPIRED)
				return
			if not _invitation_valid():
				_reject(peer_id, NetworkFrame.Reason.TOKEN_EXPIRED)
				return
			var expected := InvitationCode.proof(
				_invitation_token, session_epoch, candidate.nonce, candidate.server_nonce
			)
			if not Crypto.new().constant_time_compare(expected, proof_value):
				_reject(peer_id, NetworkFrame.Reason.TOKEN_INVALID)
				return
			# One credential admits one proof, regardless of the later host decision.
			_revoke_invitation()
			lobby_changed.emit()
			if _pending_count() >= MAX_PENDING_APPROVALS:
				_send(
					peer_id,
					NetworkFrame.Family.ADMISSION_DECISION,
					_u16(NetworkFrame.Reason.REQUEST_CAPACITY)
				)
				transport.close_peer(peer_id)
				return
			candidate.state = CandidateState.PENDING_APPROVAL
			candidate.deadline = Time.get_ticks_msec() + CHALLENGE_TIMEOUT_SECONDS * 1000
			candidate.compatibility = {
				"digest": manifest_digest.hex_encode(),
				"protocol": "%d.%d" % [NetworkFrame.MAJOR, NetworkFrame.MINOR]
			}
			candidates[peer_id] = candidate
			var decision := _u16(NetworkFrame.Reason.APPROVAL_REQUIRED)
			decision.append(0)
			_send(peer_id, NetworkFrame.Family.ADMISSION_DECISION, decision)
			approval_requested.emit(peer_id, candidate.compatibility)
			lobby_changed.emit()
		NetworkFrame.Family.ASSIGNMENT_ACK:
			if (
				candidate.state != CandidateState.ASSIGNED
				or payload.size() != 1
				or int(payload[0]) != int(candidate.seat)
			):
				_reject(peer_id, NetworkFrame.Reason.OWNERSHIP)
				return
			candidate.state = CandidateState.ACKNOWLEDGED
			candidate.deadline = 0
			candidates[peer_id] = candidate
			_send_lobby_state(peer_id)
			lobby_changed.emit()
		NetworkFrame.Family.READY_REQUEST:
			if _poll_manifest_sources():
				_send(
					peer_id,
					NetworkFrame.Family.READY_RESULT,
					_u16(NetworkFrame.Reason.INCOMPATIBLE)
				)
				return
			if not candidates.has(peer_id):
				return
			candidate = candidates[peer_id]
			if (
				candidate.state not in [CandidateState.ACKNOWLEDGED, CandidateState.READY]
				or payload.size() != 1
				or int(payload[0]) > 1
			):
				_reject(peer_id, NetworkFrame.Reason.OWNERSHIP)
				return
			var ready := int(payload[0]) == 1
			var seat_index := int(candidate.seat)
			if not _manifest_is_current() or not router.registry.set_ready(seat_index, ready):
				_send(
					peer_id,
					NetworkFrame.Family.READY_RESULT,
					_u16(NetworkFrame.Reason.INCOMPATIBLE)
				)
				return
			candidate.state = CandidateState.READY if ready else CandidateState.ACKNOWLEDGED
			candidates[peer_id] = candidate
			var result := _u16(NetworkFrame.Reason.OK)
			result.append(1 if ready else 0)
			_send(peer_id, NetworkFrame.Family.READY_RESULT, result)
			_broadcast_lobby_state()
			lobby_changed.emit()
		NetworkFrame.Family.SESSION_CLOSE:
			if payload.size() != 2 or int(candidate.seat) < 0:
				_reject(peer_id, NetworkFrame.Reason.OWNERSHIP)
				return
			remote_adapter.release_source("peer_%d" % peer_id)
			candidates.erase(peer_id)
			transport.close_peer(peer_id)
			_broadcast_lobby_state()
			lobby_changed.emit()
		_:
			_reject(peer_id, NetworkFrame.Reason.OWNERSHIP)


func _handle_client_packet(peer_id: int, family: int, payload: PackedByteArray) -> void:
	match family:
		NetworkFrame.Family.COMPATIBILITY_RESULT:
			if payload.size() == 34:
				var host_digest := payload.slice(2, 34)
				if (
					host_digest != client_manifest_digest
					or (
						not _client_expected_host_digest.is_empty()
						and host_digest != _client_expected_host_digest
					)
				):
					client_message.emit("This client does not match the host build.")
					_client_disconnect_notice_set = true
					return
				var hello := PackedByteArray()
				hello.append_array(client_manifest_digest)
				hello.append(NetworkFrame.MAJOR)
				hello.append(NetworkFrame.MINOR)
				hello.append_array(_u16(1))
				hello.append_array(_u16(15))
				_send(peer_id, NetworkFrame.Family.COMPATIBILITY_HELLO, hello)
				return
			if payload.size() != 2 or _read_u16(payload) != NetworkFrame.Reason.OK:
				client_message.emit("This client is not compatible with the host.")
				_client_disconnect_notice_set = true
				return
			var join := _local_nonce.duplicate()
			_send(peer_id, NetworkFrame.Family.JOIN_BEGIN, join)
		NetworkFrame.Family.CHALLENGE:
			if payload.size() != 32:
				client_message.emit("The host sent an invalid pairing challenge.")
				return
			var client_nonce := payload.slice(0, 16)
			var server_nonce := payload.slice(16, 32)
			if client_nonce != _local_nonce:
				client_message.emit("The pairing challenge expired.")
				return
			var proof_value := InvitationCode.proof(
				client_invite_token, session_epoch, client_nonce, server_nonce
			)
			var proof_payload := client_nonce.duplicate()
			proof_payload.append_array(server_nonce)
			proof_payload.append_array(proof_value)
			_send(peer_id, NetworkFrame.Family.PROOF, proof_payload)
		NetworkFrame.Family.ADMISSION_DECISION:
			if payload.size() not in [2, 3]:
				return
			var reason := _read_u16(payload)
			if reason == NetworkFrame.Reason.APPROVAL_REQUIRED:
				var decision_status := int(payload[2]) if payload.size() == 3 else 0
				client_message.emit(
					(
						"Waiting for host approval."
						if decision_status == 0
						else (
							"The host declined this join request."
							if decision_status == 2
							else "The host closed this join request."
						)
					)
				)
			elif reason != NetworkFrame.Reason.OK:
				client_message.emit(_reason_message(reason))
				_client_disconnect_notice_set = true
		NetworkFrame.Family.SEAT_ASSIGNMENT:
			if payload.size() != 2 or int(payload[0]) >= 4:
				client_message.emit("The host sent an invalid seat assignment.")
				return
			client_assigned_seat = int(payload[0])
			var ack := PackedByteArray([client_assigned_seat])
			_send(peer_id, NetworkFrame.Family.ASSIGNMENT_ACK, ack)
			client_assigned.emit(client_assigned_seat)
			client_message.emit(
				"Assigned player %d. Choose Ready when set." % (client_assigned_seat + 1)
			)
		NetworkFrame.Family.READY_RESULT:
			if payload.size() == 3:
				client_ready = int(payload[2]) == 1
				client_message.emit("Ready." if client_ready else "Not ready.")
		NetworkFrame.Family.LOBBY_STATE:
			if payload.size() < 2:
				client_message.emit("The host sent an incomplete lobby update.")
				return
			var count := int(payload[0])
			if count > PlayerSeatRegistry.MAX_SEATS or payload.size() != 2 + count * 3:
				client_message.emit("The host sent an invalid lobby update.")
				return
			var received_seats: Array[Dictionary] = []
			var seen := {}
			for index in count:
				var offset := 2 + index * 3
				var seat_index := int(payload[offset])
				var ready_value := int(payload[offset + 1])
				var connected_value := int(payload[offset + 2])
				if (
					seat_index >= PlayerSeatRegistry.MAX_SEATS
					or ready_value > 1
					or connected_value > 1
					or seen.has(seat_index)
				):
					client_message.emit("The host sent an invalid lobby update.")
					return
				seen[seat_index] = true
				(
					received_seats
					. append(
						{
							"seat": seat_index,
							"identity": seat_index + 1,
							"shape": PlayerSeatRegistry.SHAPES[seat_index],
							"color": PlayerSeatRegistry.COLORS[seat_index],
							"ready": ready_value == 1,
							"connected": connected_value == 1,
						}
					)
				)
			client_lobby_seats = received_seats
			client_admission_open = int(payload[1]) == 1
			if int(payload[1]) > 1:
				client_message.emit("The host sent an invalid lobby update.")
				return
			var assigned := -1
			for seat_state in client_lobby_seats:
				if int(seat_state.seat) == client_assigned_seat:
					assigned = int(seat_state.seat)
					client_ready = bool(seat_state.ready)
					break
			if client_assigned_seat >= 0 and assigned < 0:
				client_assigned_seat = -1
				client_ready = false
			lobby_changed.emit()
		NetworkFrame.Family.SESSION_CLOSE:
			client_message.emit("The host closed the session.")
			_client_disconnect_notice_set = true
			stop_session()
		_:
			client_message.emit("The host sent an unsupported lobby message.")


func _on_transport_error(message: String) -> void:
	session_error.emit(message)


func _send(peer_id: int, family: int, payload: PackedByteArray) -> bool:
	var sequence_key := "%d:%d" % [peer_id, family]
	var sequence := int(_sequences.get(sequence_key, 0)) + 1
	_sequences[sequence_key] = sequence
	var frame := NetworkFrame.encode(family, session_epoch, sequence, payload)
	if frame.is_empty():
		return false
	return transport.send(peer_id, frame) == OK


func _send_to_host(family: int, payload: PackedByteArray) -> bool:
	var peers := _connected_peer_ids()
	return false if peers.is_empty() else _send(int(peers[0]), family, payload)


func _send_lobby_state(peer_id: int) -> void:
	var seats := router.registry.joined_seats()
	var payload := PackedByteArray([seats.size(), 1 if admission_open else 0])
	for seat in seats:
		payload.append(int(seat.seat))
		payload.append(1 if seat.ready else 0)
		payload.append(1 if seat.connected else 0)
	_send(peer_id, NetworkFrame.Family.LOBBY_STATE, payload)


func _broadcast_lobby_state() -> void:
	if client_mode or not transport.is_open:
		return
	for peer_id in candidates.keys():
		if int(candidates[peer_id].state) >= CandidateState.ASSIGNED:
			_send_lobby_state(int(peer_id))


func _reject(peer_id: int, reason: int) -> void:
	var now := Time.get_ticks_msec()
	var abuse: Dictionary = (
		_peer_abuse
		. get(
			peer_id,
			{
				"window": now,
				"auth_window": now,
				"auth_failures": 0,
				"format_window": now,
				"format_failures": 0,
				"logged": 0,
				"suppressed": 0,
			}
		)
	)
	if now - int(abuse.window) >= 60000:
		if int(abuse.suppressed) > 0:
			print("NLB_P02_REJECT_AGGREGATE peer=%d count=%d" % [peer_id, abuse.suppressed])
		abuse.window = now
		abuse.logged = 0
		abuse.suppressed = 0
	if (
		reason
		in [
			NetworkFrame.Reason.TOKEN_INVALID,
			NetworkFrame.Reason.TOKEN_EXPIRED,
			NetworkFrame.Reason.OWNERSHIP
		]
	):
		if now - int(abuse.auth_window) >= 10000:
			abuse.auth_window = now
			abuse.auth_failures = 0
		abuse.auth_failures += 1
	if (
		reason
		in [
			NetworkFrame.Reason.MALFORMED,
			NetworkFrame.Reason.RATE_LIMIT,
			NetworkFrame.Reason.FIELD_RANGE
		]
	):
		if now - int(abuse.format_window) >= 10000:
			abuse.format_window = now
			abuse.format_failures = 0
		abuse.format_failures += 1
	if int(abuse.logged) < 10:
		print("NLB_P02_REJECT peer=%d reason=%d" % [peer_id, reason])
		abuse.logged += 1
	else:
		abuse.suppressed += 1
	_peer_abuse[peer_id] = abuse
	if candidates.has(peer_id) and int(candidates[peer_id].state) >= CandidateState.ASSIGNED:
		remote_adapter.release_source("peer_%d" % peer_id)
	_send(peer_id, NetworkFrame.Family.ADMISSION_DECISION, _u16(reason))
	if int(abuse.auth_failures) >= 3 or int(abuse.format_failures) >= 120:
		transport.close_peer(peer_id)
		candidates.erase(peer_id)
		_sequences.erase(peer_id)
		_incoming_sequences.erase(peer_id)
		for key in _peer_family_times.keys():
			if str(key).begins_with("%d:" % peer_id):
				_peer_family_times.erase(key)
		lobby_changed.emit()


func _accept_rate(peer_id: int, family: int) -> bool:
	var interval := 100 if family == NetworkFrame.Family.READY_REQUEST else 0
	var key := "%d:%d" % [peer_id, family]
	var now := Time.get_ticks_msec()
	var previous := int(_peer_family_times.get(key, 0))
	if interval > 0 and previous > 0 and now - previous < interval:
		return false
	_peer_family_times[key] = now
	return true


func _expire_candidates(delta: float) -> void:
	_candidate_timer += delta
	if _candidate_timer < 0.1:
		return
	_candidate_timer = 0.0
	var now := Time.get_ticks_msec()
	for peer_id in candidates.keys():
		var candidate: Dictionary = candidates[peer_id]
		if int(candidate.deadline) > 0 and now >= int(candidate.deadline):
			if int(candidate.seat) >= 0:
				remote_adapter.release_source("peer_%d" % peer_id)
			_send(
				int(peer_id),
				NetworkFrame.Family.ADMISSION_DECISION,
				_u16(NetworkFrame.Reason.APPROVAL_REQUIRED)
			)
			transport.close_peer(int(peer_id))
			candidates.erase(peer_id)
			lobby_changed.emit()


func _pending_count() -> int:
	var count := 0
	for candidate in candidates.values():
		if candidate.state == CandidateState.PENDING_APPROVAL:
			count += 1
	return count


func _manifest_is_current() -> bool:
	var current := _cached_compatibility
	if current.is_empty():
		CompatibilityManifest.reload_sources()
		_manifest_source_stamp = CompatibilityManifest.source_fingerprint()
		current = CompatibilityManifest.build()
	if current.digest == manifest_digest:
		return true
	manifest_digest = current.digest
	_cached_compatibility = current
	_manifest_revision += 1
	for peer_id in candidates.keys():
		if int(candidates[peer_id].state) == CandidateState.PENDING_APPROVAL:
			_send(
				int(peer_id),
				NetworkFrame.Family.ADMISSION_DECISION,
				_u16(NetworkFrame.Reason.INCOMPATIBLE)
			)
			transport.close_peer(int(peer_id))
			candidates.erase(peer_id)
	for seat in router.registry.joined_seats():
		if str(seat.device_kind) == "remote":
			router.registry.set_ready(int(seat.seat), false)
	return false


func _poll_manifest_sources() -> bool:
	var stamp := CompatibilityManifest.source_fingerprint()
	if stamp == _manifest_source_stamp:
		return false
	_manifest_source_stamp = stamp
	CompatibilityManifest.reload_sources()
	var current := CompatibilityManifest.build()
	if current.digest == manifest_digest:
		_cached_compatibility = current
		return false
	manifest_digest = current.digest
	_cached_compatibility = current
	_manifest_revision += 1
	for peer_id in candidates.keys():
		var candidate: Dictionary = candidates[peer_id]
		_send(
			int(peer_id),
			NetworkFrame.Family.ADMISSION_DECISION,
			_u16(NetworkFrame.Reason.INCOMPATIBLE)
		)
		if int(candidate.seat) >= 0:
			remote_adapter.release_source("peer_%d" % int(peer_id))
		transport.close_peer(int(peer_id))
		candidates.erase(peer_id)
	for seat in router.registry.joined_seats():
		if str(seat.device_kind) == "remote":
			remote_adapter.release_source(str(seat.remote_source_id))
	lobby_changed.emit()
	return true


func _invitation_valid() -> bool:
	return not _invitation_token.is_empty() and not _invitation_expired()


func _invitation_expired() -> bool:
	return (
		not _invitation_token.is_empty()
		and invitation_expires_unix > 0
		and Time.get_unix_time_from_system() >= invitation_expires_unix
	)


func _set_invitation(token: PackedByteArray) -> void:
	_revoke_invitation()
	_invitation_token = token.duplicate()
	_invitation_code = InvitationCode.encode(token)
	invitation_code = _invitation_code
	invitation_expires_unix = int(Time.get_unix_time_from_system()) + INVITATION_LIFETIME_SECONDS


func _revoke_invitation() -> void:
	_invitation_token.fill(0)
	_invitation_token.clear()
	_invitation_code = ""
	invitation_code = ""
	invitation_expires_unix = 0


func _rollback_start(message: String) -> bool:
	discovery.stop()
	transport.close()
	_revoke_invitation()
	lobby_id = 0
	session_epoch = 0
	selected_address = ""
	admission_open = false
	if router != null:
		router.set_authority(local_authority)
	host_authority = SimulationAuthority.offline()
	remote_adapter.configure(router, host_authority)
	if router != null:
		router.set_authority(local_authority)
	state = SessionState.OFFLINE
	state_changed.emit("OFFLINE")
	session_error.emit(message)
	return false


func _valid_ports(first: int, second: int) -> bool:
	return (
		first >= 1024 and first <= 65535 and second >= 1024 and second <= 65535 and first != second
	)


func _interface_has_address(address: String) -> bool:
	for entry in interface_options():
		if entry.eligible and entry.addresses.has(address):
			return true
	return false


func _is_usable_ipv4(address: String) -> bool:
	var parts := address.split(".")
	if parts.size() != 4:
		return false
	for part in parts:
		if not part.is_valid_int() or int(part) < 0 or int(part) > 255:
			return false
	return (
		not address.begins_with("127.")
		and address != "0.0.0.0"
		and address != "255.255.255.255"
		and not address.begins_with("169.254.")
	)


func _connected_peer_ids() -> Array:
	return transport._peers.keys()


func _bytes_to_u64(bytes: PackedByteArray) -> int:
	var stream := StreamPeerBuffer.new()
	stream.big_endian = false
	stream.data_array = bytes
	return stream.get_u64()


func _u16(value: int) -> PackedByteArray:
	var stream := StreamPeerBuffer.new()
	stream.big_endian = false
	stream.put_u16(value)
	return stream.data_array


func _accept_incoming_sequence(peer_id: int, family: int, sequence: int) -> bool:
	var key := "%d:%d" % [peer_id, family]
	if not _incoming_sequences.has(key):
		_incoming_sequences[key] = sequence
		return true
	var previous := int(_incoming_sequences[key])
	var difference := (sequence - previous) & 0xffffffff
	if difference == 0 or difference >= 0x80000000:
		return false
	_incoming_sequences[key] = sequence
	return true


func _read_u16(bytes: PackedByteArray) -> int:
	var stream := StreamPeerBuffer.new()
	stream.big_endian = false
	stream.data_array = bytes
	return stream.get_u16()


func _reason_message(reason: int) -> String:
	match reason:
		NetworkFrame.Reason.TOKEN_INVALID:
			return "Access code is invalid, expired or used. Ask the host for a fresh code."
		NetworkFrame.Reason.TOKEN_EXPIRED:
			return "Access code expired or was used. Ask the host for a fresh code."
		NetworkFrame.Reason.INCOMPATIBLE:
			return "This client does not match the host build."
		NetworkFrame.Reason.LOBBY_FULL:
			return "The lobby is full."
		NetworkFrame.Reason.LOBBY_CLOSED:
			return "The host closed admission."
		NetworkFrame.Reason.REQUEST_CAPACITY:
			return "The host is reviewing the maximum number of players."
		_:
			return "The host declined or closed this join request."


var _invitation_token := PackedByteArray()
var _invitation_code := ""

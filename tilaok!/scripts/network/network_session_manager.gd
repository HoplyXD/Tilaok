# gdlint: disable=class-definitions-order,max-returns,max-file-lines
class_name NetworkSessionManager
extends Node

signal state_changed(state_name: String)
signal lobby_changed
signal approval_requested(peer_id: int, compatibility: Dictionary)
signal client_message(message: String)
signal client_assigned(seat_index: int)
signal session_error(message: String)
signal network_match_start_requested
signal network_match_started(match_id: int)
signal network_match_start_received(match_id: int)
signal match_state_received(state: Dictionary)
## Client only (contract v1.3): one decoded PLACEMENT_RESULT, the host's per-seat live inventory /
## build-mode echo, and the terrain-gap flag that disables edit-dependent actions until resync.
signal placement_result_received(result: Dictionary)
signal live_seat_state_received(state: Dictionary)
signal terrain_resync_changed(gap: bool)

enum SessionState { OFFLINE, STARTING, LOBBY_OPEN, STOPPING }
enum CandidateState {
	COMPATIBILITY, CHALLENGE, PROOF, PENDING_APPROVAL, ASSIGNED, ACKNOWLEDGED, READY
}

const DEFAULT_GAME_PORT := 27777
const DEFAULT_DISCOVERY_PORT := 27778
const MAX_PENDING_APPROVALS := 4
const MAX_FRAME_EVENTS := 32
const CHALLENGE_TIMEOUT_SECONDS := 30
const INPUT_TIMEOUT_MS := 150
const INPUT_MAX_PER_SECOND := 60
const ACTION_MAX_PER_SECOND := 10
const ACTION_PER_KIND_PER_SECOND := 2
const ACTION_QUEUE_CAP := 32
const STATE_SEND_INTERVAL_TICKS := 3
## MATCH_LIFECYCLE route byte. Scheduled stays the default; live build is an explicit host opt-in.
const ROUTE_SCHEDULED := 0
const ROUTE_LIVE_BUILD := 1
const PLACEMENT_INTENT_MAX_PER_SECOND := 10
const PLACEMENT_NEW_IDS_PER_SECOND := 2
const PLACEMENT_CACHE_CAP := 32
const PLACEMENT_CACHE_MS := 120000
const LIVE_SEAT_STATE_INTERVAL_MS := 100
const TOMBSTONE_REPEATS := 3
const TERRAIN_BEHIND_RESYNC_MS := 2000
const LIVE_ACTION_FIRST := 12
const ACTION_NAMES := [
	"jump", "confirm", "back", "rotate", "claim", "ready", "cheer", "left", "right", "up", "down",
	"down", "build_toggle", "live_rotate", "live_cancel"
]

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
var match_active := false
var sync_ready := false
var assigned_peer_generation := 0
var active_match_id := 0
var match_room: P12ScheduledMatchRoom
var _generation_counter := 0
var _pending_continuous: Dictionary = {}
var _pending_actions: Dictionary = {}
var _host_input_state: Dictionary = {}
var _action_edge_watermarks: Dictionary = {}
var _reliable_edge_watermarks: Dictionary = {}
var _action_request_cache: Dictionary = {}
var _client_input_sequence := 0
var _client_action_sequence := 0
var _client_request_id := 0
var _last_state_send_tick := -1
var _snapshot_counter := 0
var _initial_snapshots_started := false
var _snapshot_receivers: Dictionary = {}
var _snapshot_sender: Dictionary = {}
var _pending_snapshot_peers: Dictionary = {}
var _snapshot_retry_counts: Dictionary = {}
var _snapshot_request_count := 0
var _snapshot_request_last_ms := 0
var _last_event_signature := ""
var _known_stage_entity_ids: Dictionary = {}
var client_replica_state: Dictionary = {}
var _client_axes := [0, 0]
var _client_aim := [0, 0]
var _client_held_mask := 0
var _client_build_mode := false
var _client_edge_watermark := 0
var _client_input_elapsed := 0.0
## Host route chosen by the flow before the match starts; clients learn it from MATCH_LIFECYCLE.
var network_route := ROUTE_SCHEDULED
var client_route := ROUTE_SCHEDULED
## NLB-P07 host policy for the live route: the selected map and the development override
## (`--nlb-unverified-content`). Clients never decide content availability.
var live_map_id := MapCatalog.DEFAULT_ID
var live_unverified_content := false
var client_live_seat_state: Dictionary = {}
var terrain_gap := false
## Host receipt time of the packet being handled; placement order uses only this clock.
var _receipt_usec := 0
var _placement_cache: Dictionary = {}
var _placement_inflight: Dictionary = {}
var _placement_new_id_times: Dictionary = {}
var _live_seat_state_sent: Dictionary = {}
var _terrain_shadow: Dictionary = {}
var _terrain_shadow_version := -1
var _tombstone_repeats: Dictionary = {}
var _terrain_parts: Dictionary = {}
var _terrain_behind_since_ms := 0
var _client_placement_request_id := 0


func _init() -> void:
	process_physics_priority = -100


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	transport.connected.connect(_on_peer_connected)
	transport.disconnected.connect(_on_peer_disconnected)
	transport.packet_received.connect(_on_packet_received)
	transport.transport_error.connect(_on_transport_error)


func _process(delta: float) -> void:
	if transport.is_open:
		transport.poll()
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
	if match_active and not client_mode:
		if match_room != null and not _initial_snapshots_started and match_room.phase_controller.phase != MatchPhaseController.Phase.LOBBY:
			_initial_snapshots_started = true
			_send_initial_snapshots()
	if client_mode and match_active and sync_ready:
		_client_input_elapsed += delta
		if _client_input_elapsed >= (1.0 / 30.0):
			_client_input_elapsed = fmod(_client_input_elapsed, 1.0 / 30.0)
			_send_client_continuous_input()
	_maintain_snapshot_transfers()


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
	match_active = false
	sync_ready = false
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


func _physics_process(_delta: float) -> void:
	if not match_active or client_mode or not host_authority.can_commit():
		return
	_expire_input_sources()
	_apply_queued_gameplay_input()
	_send_queued_snapshots()
	_send_periodic_state()
	_send_live_seat_states(false)


func _finish_stop() -> void:
	_pending_stop = false
	transport.close()
	candidates.clear()
	_sequences.clear()
	_incoming_sequences.clear()
	_idempotent_requests.clear()
	_peer_abuse.clear()
	_peer_family_times.clear()
	_pending_continuous.clear()
	_pending_actions.clear()
	_host_input_state.clear()
	_action_edge_watermarks.clear()
	_reliable_edge_watermarks.clear()
	_action_request_cache.clear()
	_snapshot_receivers.clear()
	_snapshot_sender.clear()
	_pending_snapshot_peers.clear()
	_snapshot_retry_counts.clear()
	_placement_cache.clear()
	_placement_inflight.clear()
	_placement_new_id_times.clear()
	_live_seat_state_sent.clear()
	_terrain_shadow.clear()
	_terrain_shadow_version = -1
	_tombstone_repeats.clear()
	_terrain_parts.clear()
	_terrain_behind_since_ms = 0
	_client_placement_request_id = 0
	client_live_seat_state.clear()
	client_route = ROUTE_SCHEDULED
	terrain_gap = false
	match_room = null
	match_active = false
	sync_ready = false
	active_match_id = 0
	assigned_peer_generation = 0
	client_replica_state.clear()
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
	_generation_counter = (_generation_counter + 1) & 0xffffffff
	if _generation_counter == 0:
		_generation_counter = 1
	candidate.peer_generation = _generation_counter
	candidate.deadline = Time.get_ticks_msec() + CHALLENGE_TIMEOUT_SECONDS * 1000
	candidates[peer_id] = candidate
	var payload := PackedByteArray([seat_index, seat_index + 1])
	var generation_writer := StreamPeerBuffer.new()
	generation_writer.big_endian = false
	generation_writer.put_u32(_generation_counter)
	payload.append_array(generation_writer.data_array)
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
	if match_active:
		return "A network match is already running."
	if router.registry.joined_seats().size() < 2:
		return "At least two players are required."
	if not router.registry.all_joined_ready_and_connected():
		return "Every assigned player must be connected and ready."
	if network_route == ROUTE_LIVE_BUILD:
		var live_refusal := NLBLiveCompatibilityMatrix.start_gate(
			live_map_id, live_unverified_content
		)
		if not live_refusal.is_empty():
			return live_refusal
	return "Ready to start the scheduled network match."


## Host lobby lines for the live route's content matrix (empty on the scheduled route).
func live_content_summary() -> PackedStringArray:
	if client_mode or network_route != ROUTE_LIVE_BUILD:
		return PackedStringArray()
	return NLBLiveCompatibilityMatrix.lobby_summary(live_unverified_content)


func start_network_match() -> bool:
	if client_mode or match_active or start_gate_status() != "Ready to start the scheduled network match.":
		return false
	active_match_id = 1
	if active_match_id <= 0:
		return false
	match_active = true
	sync_ready = true
	close_admission()
	# Contract v1.3: u8 1, u64 match ID, u8 route (0 scheduled, 1 live build).
	var payload := _u8_u64(1, active_match_id)
	payload.append(ROUTE_LIVE_BUILD if network_route == ROUTE_LIVE_BUILD else ROUTE_SCHEDULED)
	for peer_id in candidates.keys():
		var candidate: Dictionary = candidates[peer_id]
		if int(candidate.get("seat", -1)) >= 0 and candidate.state >= CandidateState.ACKNOWLEDGED:
			_send(int(peer_id), NetworkFrame.Family.MATCH_LIFECYCLE, payload)
			candidate.match_sync_ready = false
			candidates[peer_id] = candidate
	network_match_start_requested.emit()
	network_match_started.emit(active_match_id)
	return true


func bind_match_room(room: P12ScheduledMatchRoom) -> void:
	if client_mode or not match_active:
		return
	match_room = room
	if not match_room.presentation_changed.is_connected(_on_match_presentation_changed):
		match_room.presentation_changed.connect(_on_match_presentation_changed)
	if (
		match_room is NLBP05LiveBuildMatchRoom
		and not (match_room as NLBP05LiveBuildMatchRoom).live_placement_boundary_resolved.is_connected(
			_on_live_placement_boundary_resolved
		)
	):
		(match_room as NLBP05LiveBuildMatchRoom).live_placement_boundary_resolved.connect(
			_on_live_placement_boundary_resolved
		)
	_last_state_send_tick = -1
	_known_stage_entity_ids.clear()
	_tombstone_repeats.clear()
	_terrain_shadow.clear()
	_terrain_shadow_version = -1
	_placement_inflight.clear()
	_live_seat_state_sent.clear()
	_initial_snapshots_started = false


func _send_initial_snapshots() -> void:
	for peer_id in candidates.keys():
		var candidate: Dictionary = candidates[peer_id]
		if int(candidate.get("seat", -1)) >= 0 and candidate.state >= CandidateState.ACKNOWLEDGED:
			_pending_snapshot_peers[int(peer_id)] = true


func _send_queued_snapshots() -> void:
	for peer_id in _pending_snapshot_peers.keys():
		_pending_snapshot_peers.erase(peer_id)
		_send_initial_snapshot(int(peer_id))


func _send_initial_snapshot(peer_id: int) -> void:
	if match_room == null or not candidates.has(peer_id):
		return
	_snapshot_counter = (_snapshot_counter + 1) & 0xffffffff
	if _snapshot_counter == 0:
		_snapshot_counter = 1
	var snapshot := match_room.network_replication_snapshot(
		active_match_id, _snapshot_counter, Engine.get_physics_frames()
	)
	var metadata := NetworkMatchCodec.encode_metadata(snapshot.metadata)
	var body := NetworkMatchCodec.pack_snapshot(snapshot.records)
	if metadata.is_empty() or body.is_empty() or metadata.size() > 255:
		_send(peer_id, NetworkFrame.Family.ADMISSION_DECISION, _u16(NetworkFrame.Reason.SNAPSHOT_LIMIT))
		transport.close_peer(peer_id)
		return
	var content := PackedByteArray([metadata.size()])
	content.append_array(metadata)
	content.append_array(body)
	if content.size() > NetworkMatchCodec.SNAPSHOT_CAP:
		_send(peer_id, NetworkFrame.Family.ADMISSION_DECISION, _u16(NetworkFrame.Reason.SNAPSHOT_LIMIT))
		transport.close_peer(peer_id)
		return
	var checksum := NetworkMatchCodec.crc32(content)
	var chunk_count := ceili(float(content.size()) / NetworkMatchCodec.SNAPSHOT_CHUNK_BYTES)
	if chunk_count < 1 or chunk_count > NetworkMatchCodec.MAX_SNAPSHOT_CHUNKS:
		_send(peer_id, NetworkFrame.Family.ADMISSION_DECISION, _u16(NetworkFrame.Reason.SNAPSHOT_LIMIT))
		return
	_snapshot_sender[peer_id] = {
		"snapshot_id": _snapshot_counter,
		"checksum": checksum,
		"total": content.size(),
		"sent_ms": Time.get_ticks_msec(),
		"retries": int(_snapshot_retry_counts.get(peer_id, 0)),
	}
	for index in chunk_count:
		var offset := index * NetworkMatchCodec.SNAPSHOT_CHUNK_BYTES
		var chunk := content.slice(offset, mini(offset + NetworkMatchCodec.SNAPSHOT_CHUNK_BYTES, content.size()))
		var payload := StreamPeerBuffer.new()
		payload.big_endian = false
		payload.put_u32(_snapshot_counter)
		payload.put_u16(index)
		payload.put_u16(chunk_count)
		payload.put_u32(checksum)
		payload.put_u32(content.size())
		payload.put_u16(chunk.size())
		payload.put_u16(0)
		payload.put_data(chunk)
		_send(peer_id, NetworkFrame.Family.SNAPSHOT_CHUNK, payload.data_array)
	var end := StreamPeerBuffer.new()
	end.big_endian = false
	end.put_u32(_snapshot_counter)
	end.put_u16(chunk_count)
	end.put_u32(checksum)
	end.put_u32(content.size())
	_send(peer_id, NetworkFrame.Family.SNAPSHOT_END, end.data_array)


func _receive_snapshot_chunk(payload: PackedByteArray) -> void:
	if payload.size() < NetworkMatchCodec.SNAPSHOT_CHUNK_HEADER_BYTES or payload.size() > NetworkFrame.MAX_FRAME_BYTES - NetworkFrame.HEADER_BYTES:
		return
	var stream := StreamPeerBuffer.new()
	stream.big_endian = false
	stream.data_array = payload
	var snapshot_id := stream.get_u32()
	var index := int(stream.get_u16())
	var count := int(stream.get_u16())
	var checksum := stream.get_u32()
	var total := int(stream.get_u32())
	var chunk_length := int(stream.get_u16())
	var reserved := stream.get_u16()
	if (
		snapshot_id == 0 or count < 1 or count > NetworkMatchCodec.MAX_SNAPSHOT_CHUNKS
		or index >= count or total < 1 or total > NetworkMatchCodec.SNAPSHOT_CAP
		or count != ceili(float(total) / NetworkMatchCodec.SNAPSHOT_CHUNK_BYTES)
		or chunk_length < 1 or chunk_length > NetworkMatchCodec.SNAPSHOT_CHUNK_BYTES
		or payload.size() != NetworkMatchCodec.SNAPSHOT_CHUNK_HEADER_BYTES + chunk_length
		or reserved != 0
		or (index < count - 1 and chunk_length != NetworkMatchCodec.SNAPSHOT_CHUNK_BYTES)
		or (index == count - 1 and chunk_length != total - index * NetworkMatchCodec.SNAPSHOT_CHUNK_BYTES)
	):
		client_message.emit("The host sent an invalid snapshot chunk.")
		return
	var receiver: Dictionary = _snapshot_receivers.get(snapshot_id, {
		"checksum": checksum, "total": total, "count": count, "chunks": {}, "ended": false,
		"started_ms": Time.get_ticks_msec(),
	})
	if int(receiver.checksum) != checksum or int(receiver.total) != total or int(receiver.count) != count:
		_snapshot_receivers.erase(snapshot_id)
		client_message.emit("The host sent conflicting snapshot chunks.")
		return
	var chunk_data := stream.get_data(chunk_length)
	if int(chunk_data[0]) != OK:
		return
	var chunks: Dictionary = receiver.chunks
	if chunks.has(index) and chunks[index] != chunk_data[1]:
		_snapshot_receivers.erase(snapshot_id)
		client_message.emit("The host repeated a conflicting snapshot chunk.")
		return
	chunks[index] = chunk_data[1]
	receiver.chunks = chunks
	_snapshot_receivers[snapshot_id] = receiver


func _receive_snapshot_end(payload: PackedByteArray, peer_id: int) -> void:
	if payload.size() != 14:
		return
	var snapshot_id := _read_u32(payload, 0)
	var count := _read_u16(payload, 4)
	var checksum := _read_u32(payload, 6)
	var total := _read_u32(payload, 10)
	if not _snapshot_receivers.has(snapshot_id):
		_request_snapshot_recovery()
		return
	var receiver: Dictionary = _snapshot_receivers[snapshot_id]
	if int(receiver.count) != count or int(receiver.checksum) != checksum or int(receiver.total) != total or receiver.chunks.size() != count:
		_request_snapshot_recovery()
		return
	var content := PackedByteArray()
	for index in count:
		if not receiver.chunks.has(index):
			_request_snapshot_recovery()
			return
		content.append_array(receiver.chunks[index])
	if content.size() != total or NetworkMatchCodec.crc32(content) != checksum or content.is_empty():
		_request_snapshot_recovery()
		return
	var metadata_length := int(content[0])
	if metadata_length < 59 or content.size() <= 1 + metadata_length:
		_request_snapshot_recovery()
		return
	var metadata := NetworkMatchCodec.decode_metadata(content.slice(1, 1 + metadata_length))
	var unpacked := NetworkMatchCodec.unpack_snapshot(content.slice(1 + metadata_length))
	if not bool(metadata.get("ok", false)) or not bool(unpacked.get("ok", false)):
		_request_snapshot_recovery()
		return
	if int(metadata.match_id) != active_match_id or int(metadata.snapshot_id) != snapshot_id:
		_request_snapshot_recovery()
		return
	var installed := _replica_from_records(metadata, unpacked.records, snapshot_id)
	client_replica_state = installed
	_snapshot_receivers.clear()
	# A complete snapshot is the full entity manifest, so it repairs any terrain gap.
	_terrain_parts.clear()
	_terrain_behind_since_ms = 0
	_set_terrain_gap(false)
	match_state_received.emit(client_replica_state.duplicate(true))
	var ack := _u32(snapshot_id)
	ack.append_array(_u32(checksum))
	ack.append_array(_u32(total))
	_send(peer_id, NetworkFrame.Family.SNAPSHOT_ACK, ack)


func _accept_snapshot_ack(peer_id: int, payload: PackedByteArray, candidate: Dictionary) -> void:
	if payload.size() != 12 or not _snapshot_sender.has(peer_id):
		_reject(peer_id, NetworkFrame.Reason.SNAPSHOT_INVALID)
		return
	var sent: Dictionary = _snapshot_sender[peer_id]
	if (
		_read_u32(payload, 0) != int(sent.snapshot_id)
		or _read_u32(payload, 4) != int(sent.checksum)
		or _read_u32(payload, 8) != int(sent.total)
	):
		_reject(peer_id, NetworkFrame.Reason.SNAPSHOT_INVALID)
		return
	candidate.match_sync_ready = true
	candidates[peer_id] = candidate
	# Resend the live inventory/build echo after every (re)sync.
	_live_seat_state_sent.erase(peer_id)
	var ready_payload := _u32(int(sent.snapshot_id))
	_send(peer_id, NetworkFrame.Family.SYNC_READY, ready_payload)
	_snapshot_sender.erase(peer_id)
	_snapshot_retry_counts.erase(peer_id)


func _request_snapshot_recovery() -> void:
	sync_ready = false
	var now := Time.get_ticks_msec()
	if not client_mode or not transport.is_open or _snapshot_request_count >= 3:
		return
	if now - _snapshot_request_last_ms < 1000:
		return
	_snapshot_request_count += 1
	_snapshot_request_last_ms = now
	_send_to_host(NetworkFrame.Family.SNAPSHOT_REQUEST, PackedByteArray([1]))


func _replica_from_records(metadata: Dictionary, records: Array[Dictionary], snapshot_id: int) -> Dictionary:
	var seats := {}
	var entities := {}
	var objective := {}
	var event_context := {}
	for record in records:
		if record.has("seat"):
			seats[int(record.seat)] = record.duplicate(true)
		elif record.has("entity_id") and not bool(record.get("removed", false)):
			entities[int(record.entity_id)] = record.duplicate(true)
		elif record.has("kind"):
			objective = record.duplicate(true)
		elif record.has("event_main"):
			event_context = record.duplicate(true)
	return {
		"metadata": metadata.duplicate(true),
		"match_id": int(metadata.match_id),
		"round_id": int(metadata.round_id),
		"attempt_id": int(metadata.attempt_id),
		"snapshot_id": snapshot_id,
		"tick": int(metadata.tick),
		"stage_version": int(metadata.stage_version),
		"seats": seats,
		"entities": entities,
		"objective": objective,
		"event_context": event_context,
		"event_revision": int(metadata.event_revision),
	}


func _send_periodic_state() -> void:
	if match_room == null:
		return
	var tick := Engine.get_physics_frames()
	if tick == _last_state_send_tick or tick % STATE_SEND_INTERVAL_TICKS != 0:
		return
	_last_state_send_tick = tick
	# Versioned terrain edits go first on the reliable channel so state records never lead them.
	_send_terrain_commit_if_changed()
	var frame := match_room.network_replication_snapshot(active_match_id, _snapshot_counter, tick)
	var stage_version := int(frame.metadata.stage_version)
	var seen: Dictionary = {}
	for record in frame.records:
		var raw: PackedByteArray = record
		if raw.is_empty():
			continue
		if int(raw[0]) == NetworkMatchCodec.RECORD_STAGE_ENTITY:
			var entity := NetworkMatchCodec.decode_stage_record(raw)
			if bool(entity.get("ok", false)):
				seen[int(entity.entity_id)] = true
		var state_payload := NetworkMatchCodec.encode_state_update(
			frame.metadata, tick, stage_version, raw
		)
		if state_payload.is_empty():
			continue
		for peer_id in candidates.keys():
			if bool(candidates[peer_id].get("match_sync_ready", false)):
				_send(int(peer_id), NetworkFrame.Family.STATE_UPDATE, state_payload)
	# Versioned removals are reliable TERRAIN_COMMIT ops. These unreliable tombstones only cover
	# unversioned disappearances and repeat a bounded number of times instead of once.
	for entity_id in _known_stage_entity_ids.keys():
		if not seen.has(entity_id):
			_tombstone_repeats[entity_id] = TOMBSTONE_REPEATS
	for entity_id in _tombstone_repeats.keys():
		if seen.has(entity_id):
			_tombstone_repeats.erase(entity_id)
			continue
		var tombstone := NetworkMatchCodec.encode_state_update(
			frame.metadata, tick, stage_version, NetworkMatchCodec.encode_tombstone(int(entity_id))
		)
		for peer_id in candidates.keys():
			if bool(candidates[peer_id].get("match_sync_ready", false)):
				_send(int(peer_id), NetworkFrame.Family.STATE_UPDATE, tombstone)
		var remaining := int(_tombstone_repeats[entity_id]) - 1
		if remaining <= 0:
			_tombstone_repeats.erase(entity_id)
		else:
			_tombstone_repeats[entity_id] = remaining
	_known_stage_entity_ids = seen


## Sends only what changed since the last committed stage version: add, update and remove ops
## against a host shadow, with base/new versions that are always contiguous. The first call only
## seeds the shadow (snapshots carry the initial manifest). A version jump, a reset, or more edits
## than the contract allows forces a full snapshot instead of a truncated or non-contiguous commit.
func _send_terrain_commit_if_changed() -> void:
	if client_mode or match_room == null or match_room.items == null:
		return
	var version := int(match_room.items.stage_version)
	if version == _terrain_shadow_version:
		return
	var tick := Engine.get_physics_frames()
	var frame := match_room.network_replication_snapshot(active_match_id, _snapshot_counter, tick)
	var current := {}
	for record in frame.records:
		var raw: PackedByteArray = record
		if raw.is_empty() or int(raw[0]) != NetworkMatchCodec.RECORD_STAGE_ENTITY:
			continue
		var entity := NetworkMatchCodec.decode_stage_record(raw)
		if bool(entity.get("ok", false)):
			current[int(entity.entity_id)] = {"raw": raw, "signature": _terrain_signature(entity)}
	var previous_version := _terrain_shadow_version
	var previous_shadow := _terrain_shadow
	_terrain_shadow = {}
	for entity_id in current.keys():
		_terrain_shadow[entity_id] = str(current[entity_id].signature)
	_terrain_shadow_version = version
	if previous_version < 0:
		return
	if version != previous_version + 1:
		_force_terrain_snapshots("stage version jumped %d -> %d" % [previous_version, version])
		return
	var edits: Array = []
	for entity_id in current.keys():
		var op := 0
		if not previous_shadow.has(entity_id):
			op = NetworkPlacementCodec.EditOp.ADD
		elif str(previous_shadow[entity_id]) != str(current[entity_id].signature):
			op = NetworkPlacementCodec.EditOp.UPDATE
		if op != 0:
			edits.append({"op": op, "entity_id": entity_id, "record": current[entity_id].raw})
	for entity_id in previous_shadow.keys():
		if not current.has(entity_id):
			edits.append({"op": NetworkPlacementCodec.EditOp.REMOVE, "entity_id": entity_id})
	if edits.size() > NetworkPlacementCodec.MAX_TERRAIN_EDITS:
		_force_terrain_snapshots("CONTENT_LIMIT_EXCEEDED edits=%d" % edits.size())
		return
	var parts := NetworkPlacementCodec.encode_terrain_parts(
		{
			"match_id": active_match_id,
			"round_id": match_room.network_current_round_id(),
			"base_version": previous_version,
			"new_version": version,
			"commit_tick": tick,
		},
		edits
	)
	if parts.is_empty():
		_force_terrain_snapshots("CONTENT_LIMIT_EXCEEDED encode")
		return
	print(
		"NLB_P06_TERRAIN_COMMIT base=%d new=%d edits=%d parts=%d"
		% [previous_version, version, edits.size(), parts.size()]
	)
	for peer_id in candidates.keys():
		if bool(candidates[peer_id].get("match_sync_ready", false)):
			for part in parts:
				_send(int(peer_id), NetworkFrame.Family.TERRAIN_COMMIT, part)


func _terrain_signature(entity: Dictionary) -> String:
	var position: Vector2 = entity.get("position", Vector2.ZERO)
	return "%s|%d|%d|%d" % [
		str(entity.get("variant_key", "")),
		roundi(position.x),
		roundi(position.y),
		int(entity.get("rotation", 0)),
	]


func _force_terrain_snapshots(reason: String) -> void:
	print("NLB_P06_TERRAIN_RESYNC reason=%s" % reason)
	for peer_id in candidates.keys():
		if bool(candidates[peer_id].get("match_sync_ready", false)):
			_pending_snapshot_peers[int(peer_id)] = true


func _on_match_presentation_changed(_reason: StringName) -> void:
	if client_mode or not match_active or match_room == null:
		return
	var tick := Engine.get_physics_frames()
	var frame := match_room.network_replication_snapshot(active_match_id, _snapshot_counter, tick)
	var signature := "%d:%d:%d:%d" % [
		int(frame.metadata.phase),
		int(frame.metadata.round_id),
		int(frame.metadata.stage_version),
		int(frame.metadata.remaining_ms) / 1000,
	]
	if signature == _last_event_signature:
		return
	_last_event_signature = signature
	match_room._network_event_revision += 1
	frame.metadata.event_revision = match_room._network_event_revision
	var metadata := NetworkMatchCodec.encode_metadata(frame.metadata)
	if metadata.is_empty():
		return
	var payload := _u32(match_room._network_event_revision)
	payload.append(metadata.size())
	payload.append_array(metadata)
	var seat_records: Array[PackedByteArray] = []
	for record in frame.records:
		var raw: PackedByteArray = record
		if not raw.is_empty() and int(raw[0]) == NetworkMatchCodec.RECORD_SEAT:
			seat_records.append(raw)
	payload.append(seat_records.size())
	for record in seat_records:
		payload.append_array(_u16(record.size()))
		payload.append_array(record)
	for peer_id in candidates.keys():
		if bool(candidates[peer_id].get("match_sync_ready", false)):
			_send(int(peer_id), NetworkFrame.Family.AUTHORITATIVE_EVENT, payload)


func _receive_state_update(payload: PackedByteArray) -> void:
	var update := NetworkMatchCodec.decode_state_update(payload)
	if not bool(update.get("ok", false)):
		return
	var metadata: Dictionary = update.metadata
	if int(metadata.match_id) != active_match_id or int(metadata.attempt_id) < int(client_replica_state.get("attempt_id", 0)):
		return
	var current_tick := int(client_replica_state.get("tick", -1))
	if int(update.tick) < current_tick:
		return
	if client_replica_state.is_empty():
		return
	# Stage versions advance only through reliable TERRAIN_COMMITs (or a snapshot). A state record
	# that stays ahead for too long means a commit was lost, so recover with a full snapshot.
	var current_stage := int(client_replica_state.get("stage_version", -1))
	var update_stage := int(update.stage_version)
	if update_stage < current_stage:
		return
	if update_stage > current_stage:
		var now := Time.get_ticks_msec()
		if _terrain_behind_since_ms == 0:
			_terrain_behind_since_ms = now
		elif now - _terrain_behind_since_ms >= TERRAIN_BEHIND_RESYNC_MS:
			_terrain_behind_since_ms = 0
			_set_terrain_gap(true)
			_request_snapshot_recovery()
			return
	else:
		_terrain_behind_since_ms = 0
	var record: Dictionary = update.record
	if record.has("seat"):
		var seats: Dictionary = client_replica_state.seats
		seats[int(record.seat)] = record.duplicate(true)
		client_replica_state.seats = seats
	elif record.has("entity_id"):
		var entities: Dictionary = client_replica_state.entities
		var entity_id := int(record.entity_id)
		if bool(record.get("removed", false)):
			entities.erase(entity_id)
		elif entities.has(entity_id) or update_stage == current_stage:
			# Unknown entities wait for their versioned add unless the host is at our version.
			entities[entity_id] = record.duplicate(true)
		client_replica_state.entities = entities
	elif record.has("kind"):
		client_replica_state.objective = record.duplicate(true)
	elif record.has("event_main"):
		client_replica_state.event_context = record.duplicate(true)
	client_replica_state.metadata = metadata.duplicate(true)
	client_replica_state.round_id = int(metadata.round_id)
	client_replica_state.attempt_id = int(metadata.attempt_id)
	client_replica_state.tick = int(update.tick)
	match_state_received.emit(client_replica_state.duplicate(true))


func _receive_authoritative_event(payload: PackedByteArray) -> void:
	if payload.size() < 48 or client_replica_state.is_empty():
		return
	var revision := _read_u32(payload, 0)
	if revision <= int(client_replica_state.get("event_revision", 0)):
		return
	var metadata_length := int(payload[4])
	if metadata_length < 59 or payload.size() < 6 + metadata_length:
		return
	var metadata := NetworkMatchCodec.decode_metadata(payload.slice(5, 5 + metadata_length))
	if not bool(metadata.get("ok", false)) or int(metadata.match_id) != active_match_id:
		return
	var offset := 5 + metadata_length
	var count := int(payload[offset])
	offset += 1
	if count > NetworkMatchCodec.MAX_SEATS:
		return
	var seats: Dictionary = client_replica_state.seats.duplicate(true)
	for _index in count:
		if offset + 2 > payload.size():
			return
		var length := _read_u16(payload, offset)
		offset += 2
		if length != 26 or offset + length > payload.size():
			return
		var record := NetworkMatchCodec.decode_seat_record(payload.slice(offset, offset + length))
		if not bool(record.get("ok", false)):
			return
		seats[int(record.seat)] = record
		offset += length
	if offset != payload.size():
		return
	client_replica_state.seats = seats
	client_replica_state.metadata = metadata
	client_replica_state.event_revision = revision
	client_replica_state.round_id = int(metadata.round_id)
	client_replica_state.tick = int(metadata.tick)
	match_state_received.emit(client_replica_state.duplicate(true))


## Applies one contiguous stage-version commit (contract v1.3). A duplicate or older version is
## idempotent; a base mismatch is a gap that disables building and requests a full snapshot. A
## multi-part commit applies only once every part has arrived.
func _receive_terrain_commit(payload: PackedByteArray) -> void:
	if client_replica_state.is_empty():
		return
	var commit := NetworkPlacementCodec.decode_terrain_commit(payload)
	if not bool(commit.get("ok", false)) or int(commit.match_id) != active_match_id:
		client_message.emit("The host sent an invalid terrain update.")
		return
	var local_version := int(client_replica_state.get("stage_version", 0))
	var new_version := int(commit.new_version)
	if new_version <= local_version:
		return
	if int(commit.base_version) != local_version:
		print(
			"NLB_P06_TERRAIN_GAP local=%d base=%d new=%d"
			% [local_version, int(commit.base_version), new_version]
		)
		_terrain_parts.clear()
		_set_terrain_gap(true)
		_request_snapshot_recovery()
		return
	var pending: Dictionary = _terrain_parts.get(
		new_version, {"count": int(commit.part_count), "parts": {}}
	)
	if int(pending.count) != int(commit.part_count):
		_terrain_parts.clear()
		_set_terrain_gap(true)
		_request_snapshot_recovery()
		return
	var parts: Dictionary = pending.parts
	parts[int(commit.part_index)] = commit.edits
	pending.parts = parts
	# Only the next version can be pending, which bounds this buffer to one commit.
	_terrain_parts = {new_version: pending}
	if parts.size() < int(pending.count):
		return
	var entities: Dictionary = client_replica_state.entities.duplicate(true)
	for index in int(pending.count):
		for edit in parts[index]:
			if int(edit.op) == NetworkPlacementCodec.EditOp.REMOVE:
				entities.erase(int(edit.entity_id))
			else:
				entities[int(edit.entity_id)] = (edit.entity as Dictionary).duplicate(true)
	_terrain_parts.clear()
	_terrain_behind_since_ms = 0
	client_replica_state.entities = entities
	client_replica_state.stage_version = new_version
	match_state_received.emit(client_replica_state.duplicate(true))


func _set_terrain_gap(gap: bool) -> void:
	if terrain_gap == gap:
		return
	terrain_gap = gap
	terrain_resync_changed.emit(gap)


func _maintain_snapshot_transfers() -> void:
	var now := Time.get_ticks_msec()
	for peer_id in _snapshot_sender.keys():
		var sent: Dictionary = _snapshot_sender[peer_id]
		if now - int(sent.sent_ms) < 2000:
			continue
		var retries := int(sent.retries) + 1
		if retries > 3:
			transport.close_peer(int(peer_id))
			_snapshot_sender.erase(peer_id)
			continue
		_snapshot_retry_counts[int(peer_id)] = retries
		sent.retries = retries
		sent.sent_ms = now
		_snapshot_sender[peer_id] = sent
		_pending_snapshot_peers[int(peer_id)] = true
	for snapshot_id in _snapshot_receivers.keys():
		var receiver: Dictionary = _snapshot_receivers[snapshot_id]
		if now - int(receiver.started_ms) > 10000:
			_snapshot_receivers.erase(snapshot_id)
			_request_snapshot_recovery()


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
		_clear_live_placement_peer(peer_id)
		if int(candidate.seat) >= 0:
			remote_adapter.release_source("peer_%d" % peer_id)
		_pending_continuous.erase(peer_id)
		_pending_actions.erase(peer_id)
		_host_input_state.erase(peer_id)
		_action_edge_watermarks.erase(peer_id)
		_reliable_edge_watermarks.erase(peer_id)
		_action_request_cache.erase(peer_id)
		_snapshot_sender.erase(peer_id)
		candidates.erase(peer_id)
		_broadcast_lobby_state()
		lobby_changed.emit()


func _on_packet_received(peer_id: int, channel: int, packet: PackedByteArray) -> void:
	# Stamped before any validation: live placements are ordered by this host receipt time only.
	_receipt_usec = Time.get_ticks_usec()
	var decoded := NetworkFrame.decode(packet, -1 if client_mode else session_epoch, false)
	if not bool(decoded.ok):
		_reject(peer_id, int(decoded.reason))
		return
	if not NetworkFrame.family_allowed_on_channel(int(decoded.family), channel):
		_reject(peer_id, NetworkFrame.Reason.MALFORMED)
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
				or int(payload[34]) != NetworkFrame.SCHEMA
				or int(payload[35]) != 0
				or int(payload[36]) != (NetworkFrame.FEATURE_P06_MASK & 0xff)
				or int(payload[37]) != ((NetworkFrame.FEATURE_P06_MASK >> 8) & 0xff)
			):
				# Schema-2 / mask-0x007F (P04-only) binaries are refused here, never half-admitted.
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
			if not _invitation_valid():
				_reject(peer_id, NetworkFrame.Reason.TOKEN_EXPIRED)
				return
			var expected := InvitationCode.proof(
				_invitation_token, session_epoch, candidate.nonce, candidate.server_nonce
			)
			if not Crypto.new().constant_time_compare(expected, proof_value):
				_reject(peer_id, NetworkFrame.Reason.TOKEN_INVALID)
				return
			# The room credential is reusable; this peer's challenge remains single-use.
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
				or payload.size() != 5
				or int(payload[0]) != int(candidate.seat)
				or _read_u32(payload, 1) != int(candidate.peer_generation)
			):
				_reject(peer_id, NetworkFrame.Reason.OWNERSHIP)
				return
			candidate.state = CandidateState.ACKNOWLEDGED
			candidate.deadline = 0
			candidates[peer_id] = candidate
			_host_input_state[peer_id] = {
				"generation": int(candidate.peer_generation),
				"last_valid_ms": Time.get_ticks_msec(),
				"last_sequence": -1,
				"timed_out": true,
				"await_neutral": true,
			}
			_action_edge_watermarks[peer_id] = 0
			_reliable_edge_watermarks[peer_id] = 0
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
			_clear_live_placement_peer(peer_id)
			remote_adapter.release_source("peer_%d" % peer_id)
			candidates.erase(peer_id)
			transport.close_peer(peer_id)
			_broadcast_lobby_state()
			lobby_changed.emit()
		NetworkFrame.Family.CONTINUOUS_INPUT:
			_accept_continuous_input(peer_id, payload, candidate)
		NetworkFrame.Family.ACTION_REQUEST:
			_accept_action_request(peer_id, payload, candidate)
		NetworkFrame.Family.PLACEMENT_INTENT:
			_accept_placement_intent(peer_id, payload, candidate)
		NetworkFrame.Family.SNAPSHOT_ACK:
			_accept_snapshot_ack(peer_id, payload, candidate)
		NetworkFrame.Family.SNAPSHOT_REQUEST:
			if payload.size() == 1 and int(payload[0]) == 1:
				candidate.match_sync_ready = false
				candidates[peer_id] = candidate
				router.clear_remote_source("peer_%d" % peer_id)
				_pending_continuous.erase(peer_id)
				_pending_actions[peer_id] = []
				if _host_input_state.has(peer_id):
					_host_input_state[peer_id].timed_out = true
					_host_input_state[peer_id].await_neutral = true
				_pending_snapshot_peers[peer_id] = true
			else:
				_reject(peer_id, NetworkFrame.Reason.MALFORMED)
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
				hello.append_array(_u16(NetworkFrame.SCHEMA))
				hello.append_array(_u16(NetworkFrame.FEATURE_P06_MASK))
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
			if payload.size() != 6 or int(payload[0]) >= 4 or int(payload[1]) != int(payload[0]) + 1:
				client_message.emit("The host sent an invalid seat assignment.")
				return
			client_assigned_seat = int(payload[0])
			assigned_peer_generation = _read_u32(payload, 2)
			if assigned_peer_generation == 0:
				client_message.emit("The host sent an invalid seat generation.")
				return
			var ack := PackedByteArray([client_assigned_seat])
			ack.append_array(_u32(assigned_peer_generation))
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
		NetworkFrame.Family.MATCH_LIFECYCLE:
			if (
				payload.size() != 10 or int(payload[0]) != 1 or _read_u64(payload, 1) <= 0
				or int(payload[9]) > ROUTE_LIVE_BUILD
			):
				client_message.emit("The host sent an invalid match start.")
				return
			active_match_id = _read_u64(payload, 1)
			client_route = int(payload[9])
			client_live_seat_state.clear()
			_terrain_parts.clear()
			_terrain_behind_since_ms = 0
			_set_terrain_gap(false)
			match_active = true
			sync_ready = false
			network_match_start_received.emit(active_match_id)
		NetworkFrame.Family.SNAPSHOT_CHUNK:
			_receive_snapshot_chunk(payload)
		NetworkFrame.Family.SNAPSHOT_END:
			_receive_snapshot_end(payload, peer_id)
		NetworkFrame.Family.SYNC_READY:
			if payload.size() != 4 or _read_u32(payload, 0) != int(client_replica_state.get("snapshot_id", -1)):
				client_message.emit("The host sent an invalid synchronization notice.")
				return
			sync_ready = true
			_snapshot_request_count = 0
			_client_axes = [0, 0]
			_client_aim = [0, 0]
			_client_held_mask = 0
			_client_build_mode = false
			_client_edge_watermark = _client_action_sequence
			client_message.emit("Connected to the shared match.")
		NetworkFrame.Family.STATE_UPDATE:
			_receive_state_update(payload)
		NetworkFrame.Family.AUTHORITATIVE_EVENT, NetworkFrame.Family.TERRAIN_COMMIT:
			if family == NetworkFrame.Family.AUTHORITATIVE_EVENT:
				_receive_authoritative_event(payload)
			else:
				_receive_terrain_commit(payload)
		NetworkFrame.Family.ACTION_RESULT:
			if payload.size() == 10:
				var reason := _read_u16(payload, 8)
				if reason != NetworkFrame.Reason.OK:
					client_message.emit("An action was not accepted by the host (%d)." % reason)
		NetworkFrame.Family.PLACEMENT_RESULT:
			var result := NetworkPlacementCodec.decode_result(payload)
			if not bool(result.get("ok", false)):
				client_message.emit("The host sent an invalid placement result.")
				return
			placement_result_received.emit(result)
		NetworkFrame.Family.LIVE_SEAT_STATE:
			var seat_state := NetworkPlacementCodec.decode_seat_state(payload)
			if not bool(seat_state.get("ok", false)) or int(seat_state.match_id) != active_match_id:
				client_message.emit("The host sent an invalid build state.")
				return
			client_live_seat_state = seat_state
			live_seat_state_received.emit(seat_state.duplicate(true))
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
	return transport.send(peer_id, frame, NetworkFrame.channel_for_family(family)) == OK


func _send_to_host(family: int, payload: PackedByteArray) -> bool:
	var peers := _connected_peer_ids()
	return false if peers.is_empty() else _send(int(peers[0]), family, payload)


func client_set_continuous_input(axes: Array, aim: Array = [0, 0], build_mode: bool = false) -> bool:
	if not client_mode or axes.size() != 2 or aim.size() != 2:
		return false
	for value in axes + aim:
		if int(value) < -1000 or int(value) > 1000:
			return false
	_client_axes = [int(axes[0]), int(axes[1])]
	_client_aim = [int(aim[0]), int(aim[1])]
	_client_build_mode = build_mode
	return true


func client_set_action(action_id: int, pressed: bool) -> bool:
	if not client_mode or not sync_ready or client_assigned_seat < 0:
		return false
	var held_bit := _held_bit_for_action(action_id)
	if held_bit != 0:
		var was_held := (_client_held_mask & held_bit) != 0
		if was_held == pressed:
			return true
		_client_held_mask = (_client_held_mask | held_bit) if pressed else (_client_held_mask & ~held_bit)
	_client_action_sequence = (_client_action_sequence + 1) & 0xffffffff
	if _client_action_sequence == 0:
		_client_action_sequence = 1
	_client_edge_watermark = _client_action_sequence
	var request_id := (int(Time.get_ticks_msec()) << 20) | (_client_action_sequence & 0xfffff)
	var request := {
		"request_id": request_id,
		"match_id": active_match_id,
		"round_id": int(client_replica_state.get("round_id", 0)),
		"attempt_id": int(client_replica_state.get("attempt_id", 0)),
		"peer_generation": assigned_peer_generation,
		"edge_sequence": _client_action_sequence,
		"action": action_id,
		"target_id": 0,
		"cell": Vector2i.ZERO,
		"rotation": 0,
		"pressed": pressed,
		"client_tick": Engine.get_physics_frames() & 0xffffffff,
	}
	var payload := NetworkMatchCodec.encode_action_request(request)
	return not payload.is_empty() and _send_to_host(NetworkFrame.Family.ACTION_REQUEST, payload)


func _send_client_continuous_input() -> void:
	if not sync_ready or client_assigned_seat < 0 or assigned_peer_generation == 0:
		return
	_client_input_sequence = (_client_input_sequence + 1) & 0xffffffff
	var sample := {
		"match_id": active_match_id,
		"round_id": int(client_replica_state.get("round_id", 0)),
		"attempt_id": int(client_replica_state.get("attempt_id", 0)),
		"peer_generation": assigned_peer_generation,
		"sequence": _client_input_sequence,
		"client_tick": Engine.get_physics_frames() & 0xffffffff,
		"axes": _client_axes,
		"aim": _client_aim,
		"held": _client_held_mask,
		"build_mode": _client_build_mode,
		"edge_watermark": _client_edge_watermark,
	}
	var payload := NetworkMatchCodec.encode_input(sample)
	if not payload.is_empty():
		_send_to_host(NetworkFrame.Family.CONTINUOUS_INPUT, payload)


func _accept_continuous_input(peer_id: int, payload: PackedByteArray, candidate: Dictionary) -> void:
	if (
		not match_active or match_room == null or not bool(candidate.get("match_sync_ready", false))
		or not _input_phase_eligible()
	):
		_reject(peer_id, NetworkFrame.Reason.WRONG_PHASE)
		return
	var sample := NetworkMatchCodec.decode_input(payload)
	if not bool(sample.get("ok", false)):
		_reject(peer_id, NetworkFrame.Reason.MALFORMED)
		return
	if not _input_identity_matches(peer_id, sample, candidate):
		_reject(peer_id, NetworkFrame.Reason.STALE_STATE)
		return
	var prior: Dictionary = _host_input_state.get(peer_id, {})
	if bool(prior.get("await_neutral", true)) and not _sample_is_neutral(sample):
		_reject(peer_id, NetworkFrame.Reason.STALE_STATE)
		return
	var sequence := int(sample.sequence)
	if int(prior.get("last_sequence", -1)) >= 0 and not _sequence_is_newer(sequence, int(prior.last_sequence)):
		_reject(peer_id, NetworkFrame.Reason.STALE_STATE)
		return
	if int(sample.edge_watermark) != 0 and not _watermark_not_older(peer_id, int(sample.edge_watermark)):
		_reject(peer_id, NetworkFrame.Reason.STALE_STATE)
		return
	prior.last_sequence = sequence
	prior.last_valid_ms = Time.get_ticks_msec()
	prior.timed_out = false
	prior.await_neutral = false
	prior.generation = int(candidate.peer_generation)
	_host_input_state[peer_id] = prior
	if match_room.phase_controller.phase == MatchPhaseController.Phase.GO:
		# The shared countdown keeps the peer bound and fresh but applies only neutral input.
		sample.axes = [0, 0]
		sample.aim = [0, 0]
		sample.held = 0
		sample.build_mode = false
	_pending_continuous[peer_id] = sample


func _accept_action_request(peer_id: int, payload: PackedByteArray, candidate: Dictionary) -> void:
	if not match_active or match_room == null or not bool(candidate.get("match_sync_ready", false)):
		_reject(peer_id, NetworkFrame.Reason.WRONG_PHASE)
		return
	var request := NetworkMatchCodec.decode_action_request(payload)
	if not bool(request.get("ok", false)):
		_reject(peer_id, NetworkFrame.Reason.MALFORMED)
		return
	if not _input_identity_matches(peer_id, request, candidate):
		_reject(peer_id, NetworkFrame.Reason.STALE_STATE)
		return
	var cache: Dictionary = _action_request_cache.get(peer_id, {})
	_prune_action_cache(cache)
	var request_key := str(request.request_id)
	var payload_hasher := HashingContext.new()
	payload_hasher.start(HashingContext.HASH_SHA256)
	payload_hasher.update(payload)
	var payload_hash := payload_hasher.finish().hex_encode()
	if cache.has(request_key):
		var cached: Dictionary = cache[request_key]
		if str(cached.hash) != payload_hash:
			_send_action_result(peer_id, int(request.request_id), NetworkFrame.Reason.REQUEST_ID_REUSE)
			return
		_send(peer_id, NetworkFrame.Family.ACTION_RESULT, cached.response)
		return
	if cache.size() >= 32:
		_send_action_result(peer_id, int(request.request_id), NetworkFrame.Reason.REQUEST_CAPACITY)
		return
	if not _action_phase_allowed(int(request.action)):
		_cache_action_result(cache, peer_id, request, payload_hash, NetworkFrame.Reason.WRONG_PHASE)
		return
	var per_action_key := "%d:action:%d" % [peer_id, int(request.action)]
	var now := Time.get_ticks_msec()
	var rate: Dictionary = _peer_family_times.get(per_action_key, {"window": now, "count": 0})
	if now - int(rate.window) >= 1000:
		rate = {"window": now, "count": 0}
	if int(rate.count) >= ACTION_PER_KIND_PER_SECOND:
		_cache_action_result(cache, peer_id, request, payload_hash, NetworkFrame.Reason.RATE_LIMIT)
		return
	rate.count = int(rate.count) + 1
	_peer_family_times[per_action_key] = rate
	var edge_sequence := int(request.edge_sequence)
	var previous_edge := int(_reliable_edge_watermarks.get(peer_id, 0))
	if previous_edge != 0 and not _sequence_is_newer(edge_sequence, previous_edge):
		_cache_action_result(cache, peer_id, request, payload_hash, NetworkFrame.Reason.STALE_STATE)
		return
	if _pending_actions.get(peer_id, []).size() >= ACTION_QUEUE_CAP:
		_send_action_result(peer_id, int(request.request_id), NetworkFrame.Reason.REQUEST_CAPACITY)
		return
	request.source_id = "peer_%d" % peer_id
	var queue: Array = _pending_actions.get(peer_id, [])
	queue.append(request)
	_pending_actions[peer_id] = queue
	_reliable_edge_watermarks[peer_id] = edge_sequence
	_cache_action_result(cache, peer_id, request, payload_hash, NetworkFrame.Reason.OK)


func _input_identity_matches(peer_id: int, record: Dictionary, candidate: Dictionary) -> bool:
	return (
		int(record.get("match_id", -1)) == active_match_id
		and int(record.get("round_id", -1)) == match_room.network_current_round_id()
		and int(record.get("attempt_id", -1)) == (int(match_room.match_run_id) & 0xffff)
		and int(record.get("peer_generation", -1)) == int(candidate.get("peer_generation", 0))
		and router.registry.seat_for_remote_source("peer_%d" % peer_id) == int(candidate.seat)
	)


func _input_phase_eligible() -> bool:
	if match_room == null:
		return false
	var phase := match_room.phase_controller.phase
	# The live route's GO countdown is eligible so streaming peers are not rejected (and released);
	# _accept_continuous_input forces those samples neutral and every action stays disallowed.
	if phase == MatchPhaseController.Phase.GO:
		return _live_route_active()
	return phase in [
		MatchPhaseController.Phase.PUGAD,
		MatchPhaseController.Phase.PLACE,
		MatchPhaseController.Phase.PLAY,
		MatchPhaseController.Phase.RESULTS,
	]


func _live_route_active() -> bool:
	return network_route == ROUTE_LIVE_BUILD and match_room is NLBP06NetworkLiveBuildMatchRoom


func _action_phase_allowed(action_id: int) -> bool:
	if not _input_phase_eligible():
		return false
	var phase := match_room.phase_controller.phase
	if phase == MatchPhaseController.Phase.GO:
		return false
	match action_id:
		0, 11:
			return phase == MatchPhaseController.Phase.PLAY
		12, 13, 14:
			# Build toggle / live rotate / live cancel exist only on the opt-in live route.
			return phase == MatchPhaseController.Phase.PLAY and _live_route_active()
		1, 2:
			return phase in [MatchPhaseController.Phase.PUGAD, MatchPhaseController.Phase.PLACE, MatchPhaseController.Phase.RESULTS]
		3:
			return phase == MatchPhaseController.Phase.PLACE
		4:
			return phase == MatchPhaseController.Phase.PUGAD
		5:
			return false
		6:
			return phase in [MatchPhaseController.Phase.PLAY, MatchPhaseController.Phase.RESULTS]
		7, 8, 9, 10:
			return phase in [MatchPhaseController.Phase.PUGAD, MatchPhaseController.Phase.PLACE, MatchPhaseController.Phase.RESULTS]
	return false


func _apply_queued_gameplay_input() -> void:
	for peer_id in candidates.keys():
		var candidate: Dictionary = candidates[peer_id]
		if not bool(candidate.get("match_sync_ready", false)):
			continue
		var source_id := "peer_%d" % int(peer_id)
		if _pending_continuous.has(peer_id):
			var sample: Dictionary = _pending_continuous[peer_id]
			var mask := int(sample.held)
			if not remote_adapter.submit_sample(source_id, sample.axes, sample.aim, mask, bool(sample.build_mode)):
				continue
			_action_edge_watermarks[peer_id] = int(sample.edge_watermark)
			_pending_continuous.erase(peer_id)
		var queue: Array = _pending_actions.get(peer_id, [])
		for request in queue:
			var edge := int(request.edge_sequence)
			var watermark := int(_action_edge_watermarks.get(peer_id, 0))
			var held_action := int(request.action) in [0, 7, 8, 9, 10, 11]
			if held_action and watermark != 0 and not _sequence_is_newer(edge, watermark):
				continue
			if not _apply_action_request(source_id, request):
				continue
			_action_edge_watermarks[peer_id] = edge
		_pending_actions[peer_id] = []


func _apply_action_request(source_id: String, request: Dictionary) -> bool:
	var action_id := int(request.action)
	if action_id < 0 or action_id >= ACTION_NAMES.size():
		return false
	var action_name := str(ACTION_NAMES[action_id])
	if action_id >= LIVE_ACTION_FIRST:
		# Live build actions are press-only on the wire: the host applies the full edge so one
		# frame within the per-kind budget is one toggle/rotate/cancel, never a held state.
		if not bool(request.pressed):
			return true
		return (
			remote_adapter.submit_action(source_id, action_name, true)
			and remote_adapter.submit_action(source_id, action_name, false)
		)
	return remote_adapter.submit_action(source_id, action_name, bool(request.pressed))


func _expire_input_sources() -> void:
	var now := Time.get_ticks_msec()
	for peer_id in _host_input_state.keys():
		var input: Dictionary = _host_input_state[peer_id]
		if not bool(input.get("timed_out", true)) and now - int(input.last_valid_ms) >= INPUT_TIMEOUT_MS:
			router.clear_remote_source("peer_%d" % int(peer_id))
			_pending_continuous.erase(peer_id)
			_pending_actions[peer_id] = []
			input.timed_out = true
			# The first valid post-timeout sequence is fresh input from the still-bound peer.
			# Only initial assignment and snapshot resync require an explicit neutral sample;
			# requiring one after a transient packet gap can otherwise lock controls forever.
			input.await_neutral = false
			_host_input_state[peer_id] = input


func _watermark_not_older(peer_id: int, watermark: int) -> bool:
	var previous := int(_action_edge_watermarks.get(peer_id, 0))
	return previous == 0 or watermark == previous or _sequence_is_newer(watermark, previous)


func _sample_is_neutral(sample: Dictionary) -> bool:
	return (
		int(sample.axes[0]) == 0 and int(sample.axes[1]) == 0
		and int(sample.aim[0]) == 0 and int(sample.aim[1]) == 0
		and int(sample.held) == 0 and not bool(sample.build_mode)
	)


func _sequence_is_newer(current: int, previous: int) -> bool:
	var difference := (current - previous) & 0xffffffff
	return difference > 0 and difference < 0x80000000


func _held_bit_for_action(action_id: int) -> int:
	match action_id:
		0: return NetworkMatchCodec.HELD_JUMP
		7: return NetworkMatchCodec.HELD_LEFT
		8: return NetworkMatchCodec.HELD_RIGHT
		9: return NetworkMatchCodec.HELD_UP
		10: return NetworkMatchCodec.HELD_DOWN
		11: return NetworkMatchCodec.HELD_SNEAK
	return 0


func _action_result_payload(request_id: int, reason: int) -> PackedByteArray:
	var stream := StreamPeerBuffer.new()
	stream.big_endian = false
	stream.put_u64(request_id)
	stream.put_u16(reason)
	return stream.data_array


func _send_action_result(peer_id: int, request_id: int, reason: int) -> void:
	_send(peer_id, NetworkFrame.Family.ACTION_RESULT, _action_result_payload(request_id, reason))


func _cache_action_result(cache: Dictionary, peer_id: int, request: Dictionary, payload_hash: String, reason: int) -> void:
	var response := _action_result_payload(int(request.request_id), reason)
	cache[str(request.request_id)] = {
		"hash": payload_hash,
		"response": response,
		"time": Time.get_ticks_msec(),
	}
	_action_request_cache[peer_id] = cache
	_send(peer_id, NetworkFrame.Family.ACTION_RESULT, response)


func _prune_action_cache(cache: Dictionary) -> void:
	var now := Time.get_ticks_msec()
	for request_id in cache.keys():
		if now - int(cache[request_id].time) > 120000:
			cache.erase(request_id)


## Host handling for one PLACEMENT_INTENT (contract v1.3). Frame-level faults reject the frame;
## every gameplay-level outcome is a typed PLACEMENT_RESULT. The seat always comes from the peer
## binding. Cache: (session epoch implicit, peer generation, family, request ID) -> response.
func _accept_placement_intent(peer_id: int, payload: PackedByteArray, candidate: Dictionary) -> void:
	var intent := NetworkPlacementCodec.decode_intent(payload)
	if not bool(intent.get("ok", false)):
		if int(intent.get("reason", 0)) == NetworkFrame.Reason.FIELD_RANGE:
			_send_placement_rejection(peer_id, int(intent.request_id), "cell_range")
			return
		_reject(peer_id, NetworkFrame.Reason.MALFORMED)
		return
	var request_id := int(intent.request_id)
	if not match_active or match_room == null or not bool(candidate.get("match_sync_ready", false)):
		_send_placement_rejection(peer_id, request_id, "wrong_phase")
		return
	var seat_index := int(candidate.get("seat", -1))
	if (
		seat_index < 0
		or int(intent.peer_generation) != int(candidate.get("peer_generation", 0))
		or router.registry.seat_for_remote_source("peer_%d" % peer_id) != seat_index
	):
		_reject(peer_id, NetworkFrame.Reason.OWNERSHIP)
		return
	var cache: Dictionary = _placement_cache.get(peer_id, {})
	_prune_placement_cache(cache)
	var cache_key := "%d:%d" % [int(intent.peer_generation), request_id]
	var payload_hash := _sha256_hex(payload)
	if cache.has(cache_key):
		var cached: Dictionary = cache[cache_key]
		if str(cached.hash) != payload_hash:
			_send_placement_rejection(peer_id, request_id, "request_id_reused")
			return
		# Exact retry: replay the stored response; never submit or consume twice.
		_send(peer_id, NetworkFrame.Family.PLACEMENT_RESULT, cached.response)
		return
	if cache.size() >= PLACEMENT_CACHE_CAP and not _evict_oldest_terminal(cache):
		_send_placement_rejection(peer_id, request_id, "request_capacity")
		return
	_placement_cache[peer_id] = cache
	if (
		int(intent.match_id) != active_match_id
		or int(intent.round_id) != match_room.network_current_round_id()
		or int(intent.attempt_id) != (int(match_room.match_run_id) & 0xffff)
	):
		_cache_placement_terminal(
			peer_id, cache_key, payload_hash, _placement_rejection_payload(request_id, "stale_round")
		)
		return
	if not _live_route_active():
		_cache_placement_terminal(
			peer_id, cache_key, payload_hash, _placement_rejection_payload(request_id, "wrong_route")
		)
		return
	var phase := match_room.phase_controller.phase
	if phase != MatchPhaseController.Phase.PLAY:
		var closed_code := (
			"round_ended" if phase == MatchPhaseController.Phase.RESULTS else "wrong_phase"
		)
		_cache_placement_terminal(
			peer_id, cache_key, payload_hash, _placement_rejection_payload(request_id, closed_code)
		)
		return
	if not _accept_new_placement_id(peer_id):
		# Uncached so the same request ID can be retried once the new-request budget refills.
		_send_placement_rejection(peer_id, request_id, "rate_limit")
		return
	var live_room := match_room as NLBP06NetworkLiveBuildMatchRoom
	var receipt := live_room.network_submit_placement(
		seat_index,
		{
			"request_id": request_id,
			"peer_generation": int(intent.peer_generation),
			"inventory_id": int(intent.inventory_id),
			"expected_stage_version": int(intent.expected_stage_version),
			"cell": intent.cell,
			"rotation": int(intent.rotation),
		},
		_receipt_usec
	)
	if str(receipt.get("status", "rejected")) == "pending":
		var pipeline_key := NLBP06NetworkLiveBuildMatchRoom.network_request_key(
			int(intent.peer_generation), seat_index, request_id
		)
		_placement_inflight[pipeline_key] = {
			"peer_id": peer_id, "cache_key": cache_key, "request_id": request_id,
		}
		var queued := NetworkPlacementCodec.encode_result(
			{
				"request_id": request_id,
				"status": NetworkPlacementCodec.Status.QUEUED,
				"reason": NetworkFrame.Reason.OK,
				"detail": NetworkPlacementCodec.Detail.QUEUED,
				"stage_version": int(match_room.items.stage_version),
			}
		)
		cache[cache_key] = {
			"hash": payload_hash, "response": queued, "time": Time.get_ticks_msec(), "terminal": false,
		}
		_placement_cache[peer_id] = cache
		_send(peer_id, NetworkFrame.Family.PLACEMENT_RESULT, queued)
		return
	_cache_placement_terminal(
		peer_id, cache_key, payload_hash, _placement_response(request_id, receipt)
	)


## Answers each network-owned request resolved at an authority boundary. The terrain commit for
## the new stage version is sent first (same reliable channel), so the committed entity reaches
## the client no later than its acceptance.
func _on_live_placement_boundary_resolved(results: Array) -> void:
	if client_mode or match_room == null:
		return
	_send_terrain_commit_if_changed()
	var now := Time.get_ticks_msec()
	for result_variant in results:
		var result: Dictionary = result_variant
		var key := str(result.get("request_id", ""))
		if not _placement_inflight.has(key):
			continue
		var inflight: Dictionary = _placement_inflight[key]
		_placement_inflight.erase(key)
		var peer_id := int(inflight.peer_id)
		var response := _placement_response(int(inflight.request_id), result)
		print(
			"NLB_P06_PLACEMENT_RESULT peer=%d request=%d code=%s stage=%d"
			% [
				peer_id,
				int(inflight.request_id),
				str(result.get("code", "")),
				int(result.get("stage_version", -1)),
			]
		)
		if not candidates.has(peer_id):
			continue
		var cache: Dictionary = _placement_cache.get(peer_id, {})
		if cache.has(str(inflight.cache_key)):
			var entry: Dictionary = cache[str(inflight.cache_key)]
			entry.response = response
			entry.terminal = true
			entry.time = now
			cache[str(inflight.cache_key)] = entry
			_placement_cache[peer_id] = cache
		_send(peer_id, NetworkFrame.Family.PLACEMENT_RESULT, response)
	_send_live_seat_states(true)


func _placement_response(request_id: int, result: Dictionary) -> PackedByteArray:
	var code := str(result.get("code", ""))
	var stage_version := int(result.get("stage_version", match_room.items.stage_version))
	var accepted := bool(result.get("allowed", false)) or str(result.get("status", "")) == "accepted"
	if accepted:
		var entity_id := 0
		if code != "objective":
			entity_id = match_room.network_entity_id_for(str(result.get("entity_id", "")))
		if entity_id <= 0 and code != "objective":
			push_warning("NLB-P06 accepted placement without an entity: %s" % code)
		var grace_ticks := ceili(
			float(result.get("activation_after_seconds", 0.0)) * Engine.physics_ticks_per_second
		)
		var detail := (
			NetworkPlacementCodec.Detail.OBJECTIVE
			if code == "objective"
			else NetworkPlacementCodec.Detail.COMMITTED
		)
		return NetworkPlacementCodec.encode_result(
			{
				"request_id": request_id,
				"status": NetworkPlacementCodec.Status.ACCEPTED,
				"reason": NetworkFrame.Reason.OK,
				"entity_id": entity_id,
				"cell": result.get("cell", Vector2i.ZERO),
				"rotation": int(result.get("quarter_turns", 0)) & 3,
				"stage_version": stage_version,
				"activation_tick": (Engine.get_physics_frames() + grace_ticks) & 0xffffffff,
				"detail": detail,
			}
		)
	if code == "wrong_phase" and (
		match_room.phase_controller.phase != MatchPhaseController.Phase.PLAY
		or not match_room.items.in_play
	):
		code = "round_ended"
	return _placement_rejection_payload(request_id, code, stage_version)


func _placement_rejection_payload(
	request_id: int, code: String, stage_version: int = -1
) -> PackedByteArray:
	var reason := NetworkPlacementCodec.reason_for_code(code)
	if reason == NetworkFrame.Reason.OK:
		reason = NetworkFrame.Reason.INTERNAL_RETRY
	if stage_version < 0:
		stage_version = 0
		if match_room != null and match_room.items != null:
			stage_version = int(match_room.items.stage_version)
	return NetworkPlacementCodec.encode_result(
		{
			"request_id": request_id,
			"status": NetworkPlacementCodec.Status.REJECTED,
			"reason": reason,
			"detail": NetworkPlacementCodec.detail_for_code(code),
			"stage_version": stage_version,
		}
	)


func _send_placement_rejection(peer_id: int, request_id: int, code: String) -> void:
	var payload := _placement_rejection_payload(request_id, code)
	if not payload.is_empty():
		_send(peer_id, NetworkFrame.Family.PLACEMENT_RESULT, payload)


func _cache_placement_terminal(
	peer_id: int, cache_key: String, payload_hash: String, response: PackedByteArray
) -> void:
	if response.is_empty():
		return
	var cache: Dictionary = _placement_cache.get(peer_id, {})
	cache[cache_key] = {
		"hash": payload_hash, "response": response, "time": Time.get_ticks_msec(), "terminal": true,
	}
	_placement_cache[peer_id] = cache
	_send(peer_id, NetworkFrame.Family.PLACEMENT_RESULT, response)


## Terminal results expire after 120 s; in-flight entries are never pruned or evicted.
func _prune_placement_cache(cache: Dictionary) -> void:
	var now := Time.get_ticks_msec()
	for key in cache.keys():
		if bool(cache[key].terminal) and now - int(cache[key].time) > PLACEMENT_CACHE_MS:
			cache.erase(key)


func _evict_oldest_terminal(cache: Dictionary) -> bool:
	var oldest_key := ""
	var oldest_time := 0
	for key in cache.keys():
		var entry: Dictionary = cache[key]
		if bool(entry.terminal) and (oldest_key.is_empty() or int(entry.time) < oldest_time):
			oldest_key = str(key)
			oldest_time = int(entry.time)
	if oldest_key.is_empty():
		return false
	cache.erase(oldest_key)
	return true


func _accept_new_placement_id(peer_id: int) -> bool:
	var now := Time.get_ticks_msec()
	var recent: Array = []
	for stamp in _placement_new_id_times.get(peer_id, []):
		if now - int(stamp) < 1000:
			recent.append(int(stamp))
	if recent.size() >= PLACEMENT_NEW_IDS_PER_SECOND:
		_placement_new_id_times[peer_id] = recent
		return false
	recent.append(now)
	_placement_new_id_times[peer_id] = recent
	return true


func _sha256_hex(payload: PackedByteArray) -> String:
	var hasher := HashingContext.new()
	hasher.start(HashingContext.HASH_SHA256)
	hasher.update(payload)
	return hasher.finish().hex_encode()


## Sends each remote seat its host-owned inventory/build-mode/cursor echo when it changes (at most
## every 100 ms unless forced right after a boundary).
func _send_live_seat_states(force: bool) -> void:
	if not _live_route_active():
		return
	var live_room := match_room as NLBP06NetworkLiveBuildMatchRoom
	var now := Time.get_ticks_msec()
	for peer_id in candidates.keys():
		var candidate: Dictionary = candidates[peer_id]
		var seat_index := int(candidate.get("seat", -1))
		if seat_index < 0 or not bool(candidate.get("match_sync_ready", false)):
			continue
		var seat_state := live_room.live_seat_state_for(seat_index)
		seat_state.match_id = active_match_id
		seat_state.round_id = live_room.network_current_round_id()
		seat_state.attempt_id = int(live_room.match_run_id) & 0xffff
		var payload := NetworkPlacementCodec.encode_seat_state(seat_state)
		if payload.is_empty():
			continue
		var sent: Dictionary = _live_seat_state_sent.get(peer_id, {})
		if sent.get("payload", PackedByteArray()) == payload:
			continue
		var last_sent_ms := int(sent.get("time", -LIVE_SEAT_STATE_INTERVAL_MS))
		if not force and now - last_sent_ms < LIVE_SEAT_STATE_INTERVAL_MS:
			continue
		_live_seat_state_sent[peer_id] = {"payload": payload, "time": now}
		_send(int(peer_id), NetworkFrame.Family.LIVE_SEAT_STATE, payload)


## Clears one peer's live-placement state. In-flight entries are dropped first, then the room
## cancels that seat's queued request (item retained) so nothing is answered to a closed peer.
func _clear_live_placement_peer(peer_id: int) -> void:
	for key in _placement_inflight.keys():
		if int(_placement_inflight[key].peer_id) == peer_id:
			_placement_inflight.erase(key)
	_placement_cache.erase(peer_id)
	_placement_new_id_times.erase(peer_id)
	_live_seat_state_sent.erase(peer_id)
	var seat_index := int(candidates.get(peer_id, {}).get("seat", -1))
	if (
		seat_index >= 0
		and match_room != null
		and is_instance_valid(match_room)
		and match_room is NLBP06NetworkLiveBuildMatchRoom
	):
		(match_room as NLBP06NetworkLiveBuildMatchRoom).network_cancel_seat(seat_index)


func client_live_build_available() -> bool:
	return (
		client_mode
		and match_active
		and sync_ready
		and client_route == ROUTE_LIVE_BUILD
		and not terrain_gap
		and client_assigned_seat >= 0
		and assigned_peer_generation != 0
	)


func client_next_placement_request_id() -> int:
	_client_placement_request_id += 1
	return _client_placement_request_id


## Exact bytes for one placement intent. Callers keep and resend these unchanged so a retry is
## recognised by the host cache instead of being treated as a new or reused request.
func client_encode_placement_intent(
	request_id: int, cell: Vector2i, rotation: int
) -> PackedByteArray:
	if not client_live_build_available():
		return PackedByteArray()
	return NetworkPlacementCodec.encode_intent(
		{
			"request_id": request_id,
			"match_id": active_match_id,
			"round_id": int(client_replica_state.get("round_id", 0)),
			"attempt_id": int(client_replica_state.get("attempt_id", 0)),
			"peer_generation": assigned_peer_generation,
			"expected_stage_version": int(client_replica_state.get("stage_version", 0)),
			"inventory_id": int(client_live_seat_state.get("inventory_id", 0)),
			"cell": cell,
			"rotation": rotation,
		}
	)


func client_send_placement_payload(payload: PackedByteArray) -> bool:
	if (
		not client_mode
		or not sync_ready
		or payload.size() != NetworkPlacementCodec.INTENT_BYTES
	):
		return false
	return _send_to_host(NetworkFrame.Family.PLACEMENT_INTENT, payload)


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
	if client_mode:
		client_message.emit("The host sent an invalid or out-of-order message (%d)." % reason)
		return
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
		_clear_live_placement_peer(peer_id)
		transport.close_peer(peer_id)
		candidates.erase(peer_id)
		# Sequence tables are keyed "peer:family"; erase by prefix (an int-key erase was a no-op).
		_erase_peer_keys(_sequences, peer_id)
		_erase_peer_keys(_incoming_sequences, peer_id)
		_pending_continuous.erase(peer_id)
		_pending_actions.erase(peer_id)
		_host_input_state.erase(peer_id)
		_action_edge_watermarks.erase(peer_id)
		_reliable_edge_watermarks.erase(peer_id)
		_action_request_cache.erase(peer_id)
		_snapshot_sender.erase(peer_id)
		_erase_peer_keys(_peer_family_times, peer_id)
		lobby_changed.emit()


func _erase_peer_keys(table: Dictionary, peer_id: int) -> void:
	var prefix := "%d:" % peer_id
	for key in table.keys():
		if str(key).begins_with(prefix):
			table.erase(key)


func _accept_rate(peer_id: int, family: int) -> bool:
	var key := "%d:%d" % [peer_id, family]
	var now := Time.get_ticks_msec()
	var state: Dictionary = _peer_family_times.get(key, {"window": now, "count": 0, "last": -1000})
	if now - int(state.window) >= 1000:
		state = {"window": now, "count": 0, "last": -1000}
	var limit := 0
	match family:
		NetworkFrame.Family.CONTINUOUS_INPUT:
			limit = INPUT_MAX_PER_SECOND
		NetworkFrame.Family.ACTION_REQUEST:
			limit = ACTION_MAX_PER_SECOND
		NetworkFrame.Family.PLACEMENT_INTENT:
			limit = PLACEMENT_INTENT_MAX_PER_SECOND
		NetworkFrame.Family.READY_REQUEST:
			if now - int(state.last) < 100:
				return false
	if limit > 0 and int(state.count) >= limit:
		return false
	state.count = int(state.count) + 1
	state.last = now
	_peer_family_times[key] = state
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
			_clear_live_placement_peer(int(peer_id))
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
	return not _invitation_token.is_empty()


func _set_invitation(token: PackedByteArray) -> void:
	_revoke_invitation()
	_invitation_token = token.duplicate()
	_invitation_code = InvitationCode.encode(token)
	invitation_code = _invitation_code
	invitation_expires_unix = 0


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


func _read_u16(bytes: PackedByteArray, offset: int = 0) -> int:
	if offset == 0:
		var stream := StreamPeerBuffer.new()
		stream.big_endian = false
		stream.data_array = bytes
		return stream.get_u16()
	if offset < 0 or bytes.size() < offset + 2:
		return -1
	var stream := StreamPeerBuffer.new()
	stream.big_endian = false
	stream.data_array = bytes.slice(offset, offset + 2)
	return stream.get_u16()


func _read_u32(bytes: PackedByteArray, offset: int = 0) -> int:
	if offset < 0 or bytes.size() < offset + 4:
		return -1
	var stream := StreamPeerBuffer.new()
	stream.big_endian = false
	stream.data_array = bytes.slice(offset, offset + 4)
	return stream.get_u32()


func _read_u64(bytes: PackedByteArray, offset: int = 0) -> int:
	if offset < 0 or bytes.size() < offset + 8:
		return -1
	var stream := StreamPeerBuffer.new()
	stream.big_endian = false
	stream.data_array = bytes.slice(offset, offset + 8)
	return stream.get_u64()


func _u32(value: int) -> PackedByteArray:
	var stream := StreamPeerBuffer.new()
	stream.big_endian = false
	stream.put_u32(value)
	return stream.data_array


func _u8_u64(first: int, second: int) -> PackedByteArray:
	var stream := StreamPeerBuffer.new()
	stream.big_endian = false
	stream.put_u8(first)
	stream.put_u64(second)
	return stream.data_array


func _reason_message(reason: int) -> String:
	match reason:
		NetworkFrame.Reason.TOKEN_INVALID:
			return "Access code does not match this room. Check the code shown by the host."
		NetworkFrame.Reason.TOKEN_EXPIRED:
			return "This room invitation is no longer active. Ask the host to reopen the room."
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

# gdlint: disable=max-line-length,max-file-lines
extends SceneTree

## Focused NLB-P08 checks (contract v1.5): the wire constants and codecs, the HMAC reclaim context,
## the host-only pause epoch and clock freeze, client lifecycle neutralisation, seat reservation,
## reclaim (proof, rotation, races, stale generations), the one-per-round disconnect elimination
## through the ledger and the Lagsanay controller, and the unchanged offline pause/reclaim rules.
## Transport-free: frames are fed to the manager handlers. Authored only; nothing here has run.
## Run: Godot --headless --fixed-fps 60 --path tilaok! --script res://tests/run_nlb_p08_tests.gd

const REMOTE_PEER := 51
const REMOTE_SOURCE := "peer_51"
const SECOND_PEER := 52
const GENERATION := 9

var checks := 0
var failures := 0


class CaptureManager:
	extends NetworkSessionManager

	var sent: Array[Dictionary] = []

	func _send(peer_id: int, family: int, payload: PackedByteArray) -> bool:
		sent.append({"peer": peer_id, "family": family, "payload": payload.duplicate()})
		return true

	func _send_to_host(family: int, payload: PackedByteArray) -> bool:
		return _send(1, family, payload)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_wire_constants()
	_test_codecs()
	_test_hmac_context()
	_test_pause_controller()
	_test_reservation_book()
	_test_registry_reservation_and_reclaim()
	await _test_host_pause_flow()
	await _test_client_lifecycle()
	await _test_host_hint_and_reservation()
	await _test_reclaim_flow()
	_test_disconnect_elimination_paths()
	_test_offline_rules_unchanged()
	print("NLB_P08_TESTS checks=%d failures=%d" % [checks, failures])
	await process_frame
	quit(1 if failures > 0 else 0)


# --- wire ------------------------------------------------------------------------------------


func _test_wire_constants() -> void:
	_check(NetworkFrame.MAJOR == 1 and NetworkFrame.MINOR == 2, "envelope stays 1.2 so older binaries read the welcome")
	# Schema 5 added the lifecycle bit; NLB-P09 (v1.6) raised the schema to 6 and the mask to 0x07FF.
	_check(NetworkFrame.SCHEMA == 6 and NetworkFrame.FEATURE_LIFECYCLE == 0x0200, "the lifecycle feature bit 9 (schema 5) is still required")
	_check(NetworkFrame.FEATURE_P08_MASK == 0x03ff and (NetworkFrame.FEATURE_REQUIRED_MASK & NetworkFrame.FEATURE_P08_MASK) == NetworkFrame.FEATURE_P08_MASK, "the P08 mask is a subset of the required mask")
	_check(NetworkFrame.FEATURE_P07_MASK != NetworkFrame.FEATURE_REQUIRED_MASK, "a P07 peer (0x01FF) is refused at hello")
	for family in [NetworkFrame.Family.PAUSE_STATE, NetworkFrame.Family.LIFECYCLE_HINT, NetworkFrame.Family.RECLAIM_BEGIN, NetworkFrame.Family.RECLAIM_RESULT]:
		_check(family in NetworkFrame.FAMILIES, "family 0x%02X is allowlisted" % family)
		_check(NetworkFrame.family_allowed_on_channel(family, RawEnetTransport.CONTROL_CHANNEL), "family 0x%02X uses reliable channel 0" % family)
		_check(not NetworkFrame.family_allowed_on_channel(family, RawEnetTransport.INPUT_CHANNEL), "family 0x%02X rejected on the input channel" % family)
		_check(not NetworkFrame.family_allowed_on_channel(family, RawEnetTransport.STATE_CHANNEL), "family 0x%02X rejected on the state channel" % family)
	_check(NetworkFrame.FAMILIES.size() == 38 and NetworkFrame.FAMILIES.max() == 0x26, "the allowlist ends at 0x26 after NLB-P09")
	_check(str(CompatibilityManifest.build().manifest.build) == "tilaok-nlb-p09-2026-10-21", "the manifest build ID is the P09 build")


func _test_codecs() -> void:
	var pause := NetworkLifecycleCodec.encode_pause_state({"match_id": 3, "round_id": 2, "attempt_id": 1, "epoch": 5, "host_tick": 900, "state": 1, "reason": 0})
	var pause_decoded := NetworkLifecycleCodec.decode_pause_state(pause)
	_check(pause.size() == NetworkLifecycleCodec.PAUSE_STATE_BYTES and bool(pause_decoded.get("ok", false)) and int(pause_decoded.epoch) == 5 and int(pause_decoded.state) == 1, "pause state is exactly 26 bytes and round-trips")
	_check(NetworkLifecycleCodec.encode_pause_state({"epoch": 0, "state": 1, "reason": 0}).is_empty(), "epoch 0 cannot be encoded")
	_check(NetworkLifecycleCodec.encode_pause_state({"epoch": 1, "state": 2, "reason": 0}).is_empty(), "an unknown pause state cannot be encoded")
	var bad_state := pause.duplicate()
	bad_state[24] = 2
	_check(not bool(NetworkLifecycleCodec.decode_pause_state(bad_state).get("ok", true)), "an out-of-range pause state is rejected")
	_check(not bool(NetworkLifecycleCodec.decode_pause_state(pause.slice(0, 25)).get("ok", true)), "a short pause frame is rejected")
	var long_pause := pause.duplicate()
	long_pause.append(0)
	_check(not bool(NetworkLifecycleCodec.decode_pause_state(long_pause).get("ok", true)), "a long pause frame is rejected")
	var hint := NetworkLifecycleCodec.encode_lifecycle_hint(GENERATION, 4, NetworkLifecycleCodec.Hint.BACKGROUND)
	var hint_decoded := NetworkLifecycleCodec.decode_lifecycle_hint(hint)
	_check(hint.size() == 9 and bool(hint_decoded.get("ok", false)) and int(hint_decoded.peer_generation) == GENERATION, "lifecycle hint is exactly 9 bytes with generation, sequence and state only")
	_check(NetworkLifecycleCodec.encode_lifecycle_hint(0, 1, 0).is_empty() and NetworkLifecycleCodec.encode_lifecycle_hint(1, 1, 4).is_empty(), "a hint without a generation or with an unknown state cannot be encoded")
	var player_id := Crypto.new().generate_random_bytes(16)
	var nonce := Crypto.new().generate_random_bytes(16)
	var begin := NetworkLifecycleCodec.encode_reclaim_begin(player_id, nonce, 12)
	var begin_decoded := NetworkLifecycleCodec.decode_reclaim_begin(begin)
	_check(begin.size() == 36 and bool(begin_decoded.get("ok", false)) and begin_decoded.player_id == player_id and begin_decoded.client_nonce == nonce, "reclaim begin is exactly 36 bytes: Player ID, nonce, last snapshot; no token, no seat")
	_check(not bool(NetworkLifecycleCodec.decode_reclaim_begin(begin.slice(0, 35)).get("ok", true)), "a short reclaim begin is rejected")
	var token := Crypto.new().generate_random_bytes(16)
	var result := NetworkLifecycleCodec.encode_reclaim_result(NetworkFrame.Reason.OK, 2, GENERATION, token, 41000)
	var result_decoded := NetworkLifecycleCodec.decode_reclaim_result(result)
	_check(result.size() == 27 and int(result_decoded.seat) == 2 and result_decoded.token == token and int(result_decoded.remaining_ms) == 41000, "reclaim result is exactly 27 bytes and carries the rotated token")
	_check(NetworkLifecycleCodec.encode_reclaim_result(0, 4, 1, token, 0).is_empty(), "seat 4 cannot be encoded")
	var assignment := NetworkLifecycleCodec.encode_seat_assignment(1, GENERATION, player_id, token)
	var assignment_decoded := NetworkLifecycleCodec.decode_seat_assignment(assignment)
	_check(assignment.size() == 38 and bool(assignment_decoded.get("ok", false)) and assignment_decoded.player_id == player_id and assignment_decoded.token == token, "the extended seat assignment is exactly 38 bytes")
	var wrong_identity := assignment.duplicate()
	wrong_identity[1] = 9
	_check(not bool(NetworkLifecycleCodec.decode_seat_assignment(wrong_identity).get("ok", true)), "an assignment whose identity does not match its seat is rejected")
	_check(not bool(NetworkLifecycleCodec.decode_seat_assignment(assignment.slice(0, 6)).get("ok", true)), "the old 6-byte assignment is rejected")


func _test_hmac_context() -> void:
	var token := Crypto.new().generate_random_bytes(16)
	var client_nonce := Crypto.new().generate_random_bytes(16)
	var server_nonce := Crypto.new().generate_random_bytes(16)
	var join := InvitationCode.proof(token, 77, client_nonce, server_nonce)
	var reclaim := InvitationCode.proof(token, 77, client_nonce, server_nonce, InvitationCode.CONTEXT_RECLAIM)
	_check(join.size() == 32 and reclaim.size() == 32 and join != reclaim, "the join and reclaim contexts produce different proofs for the same token")
	_check(InvitationCode.proof(token, 77, client_nonce, server_nonce, 2).is_empty(), "an unknown auth context yields no proof")
	var other_token := Crypto.new().generate_random_bytes(16)
	_check(InvitationCode.proof(other_token, 77, client_nonce, server_nonce, InvitationCode.CONTEXT_RECLAIM) != reclaim, "a different token yields a different reclaim proof")
	_check(InvitationCode.proof(token, 78, client_nonce, server_nonce, InvitationCode.CONTEXT_RECLAIM) != reclaim, "a different session epoch yields a different proof")
	_check(InvitationCode.proof(token, 77, client_nonce, Crypto.new().generate_random_bytes(16), InvitationCode.CONTEXT_RECLAIM) != reclaim, "a fresh server nonce yields a different proof (no replay)")


# --- pause -----------------------------------------------------------------------------------


func _test_pause_controller() -> void:
	var host := NetworkPauseController.new()
	host.authority = SimulationAuthority.host()
	_check(host.host_set(true, 0, 1000) and host.epoch == 1 and host.paused, "the host pause advances the epoch")
	_check(not host.host_set(true, 0, 1100) and host.epoch == 1, "pausing again is idempotent and issues no epoch")
	_check(host.host_set(false, 0, 1200) and host.epoch == 2 and not host.paused, "resume advances the epoch")
	_check(not host.host_set(true, 0, 1300) and host.epoch == 2, "more than 2 requests per second are refused")
	_check(host.host_set(true, 0, 2500) and host.epoch == 3, "requests are allowed again after the window")
	var client_side := NetworkPauseController.new()
	client_side.authority = SimulationAuthority.new()
	_check(not client_side.host_set(true, 0, 1000) and client_side.epoch == 0 and not client_side.paused, "a controller without host authority cannot pause")
	var replica := NetworkPauseController.new()
	var record := host.record(1, 1, 1, 100)
	_check(replica.apply_host_state(record) == "applied" and replica.paused and replica.epoch == 3, "a client applies a newer host epoch")
	_check(replica.apply_host_state(record) == "duplicate", "a duplicate epoch is idempotent")
	var stale := record.duplicate()
	stale.epoch = 2
	stale.state = NetworkLifecycleCodec.PauseState.RUNNING
	_check(replica.apply_host_state(stale) == "stale" and replica.paused, "a stale epoch is ignored")
	var wrapped := NetworkPauseController.new()
	wrapped.epoch = 0xfffffffe
	var next := record.duplicate()
	next.epoch = 1
	_check(wrapped.apply_host_state(next) == "applied", "epoch comparison is wrap-aware")


func _test_host_pause_flow() -> void:
	var fixture: Dictionary = await _host_fixture()
	var manager: CaptureManager = fixture.manager
	var router: LocalInputRouter = fixture.router
	manager.candidates[REMOTE_PEER].match_sync_ready = true
	# A client PAUSE_STATE frame is HOST_ONLY: refused and never applied.
	var forged := NetworkLifecycleCodec.encode_pause_state({"match_id": 1, "epoch": 1, "state": 1, "reason": 0, "round_id": 1, "attempt_id": 1, "host_tick": 1})
	manager._handle_host_packet(REMOTE_PEER, NetworkFrame.Family.PAUSE_STATE, forged)
	var refusals := _sent_family(manager, NetworkFrame.Family.ADMISSION_DECISION).filter(func(payload: PackedByteArray) -> bool: return manager._read_u16(payload) == NetworkFrame.Reason.HOST_ONLY)
	_check(not refusals.is_empty() and not manager.pause_controller.paused and manager.pause_controller.epoch == 0, "a client pause frame is refused HOST_ONLY and changes nothing")
	_check(not get_root_paused(), "a client pause does not freeze the simulation")
	manager.sent.clear()
	# The host's own pause (tree pause, set only by host-local input) becomes epoch 1 for every peer.
	manager.candidates[REMOTE_PEER].state = NetworkSessionManager.CandidateState.ACKNOWLEDGED
	manager.match_active = true
	paused = true
	manager._sync_pause_state()
	var pause_frames := _sent_family(manager, NetworkFrame.Family.PAUSE_STATE)
	var decoded := NetworkLifecycleCodec.decode_pause_state(pause_frames[0]) if not pause_frames.is_empty() else {}
	_check(pause_frames.size() == 1 and int(decoded.get("epoch", 0)) == 1 and int(decoded.get("state", 0)) == 1, "the host pause is broadcast once with epoch 1")
	manager._sync_pause_state()
	_check(_sent_family(manager, NetworkFrame.Family.PAUSE_STATE).size() == 1, "an unchanged pause is not re-broadcast inside the heartbeat window")
	# The input clock freezes with the pause: no peer times out because of it.
	manager._host_input_state[REMOTE_PEER] = {"generation": GENERATION, "last_valid_ms": Time.get_ticks_msec() - 5000, "last_sequence": 3, "timed_out": false, "await_neutral": false}
	manager._expire_input_sources()
	_check(not bool(manager._host_input_state[REMOTE_PEER].timed_out), "a paused host does not time a peer out")
	paused = false
	manager._sync_pause_state()
	var resumed := _sent_family(manager, NetworkFrame.Family.PAUSE_STATE)
	_check(resumed.size() == 2 and int(NetworkLifecycleCodec.decode_pause_state(resumed.back()).state) == 0 and manager.pause_controller.epoch == 2, "resume is epoch 2")
	manager._host_input_state[REMOTE_PEER].last_valid_ms = Time.get_ticks_msec() - 5000
	manager._expire_input_sources()
	_check(bool(manager._host_input_state[REMOTE_PEER].timed_out), "the 150 ms neutral timeout applies again after resume")
	# Client side: an applied host pause holds the shared clock; a local overlay is not a pause.
	var client := CaptureManager.new()
	root.add_child(client)
	client.client_mode = true
	client.match_active = true
	client.active_match_id = 1
	var seen: Array = []
	client.pause_state_changed.connect(func(is_paused: bool, epoch: int) -> void: seen.append([is_paused, epoch]))
	client._receive_pause_state(NetworkLifecycleCodec.encode_pause_state({"match_id": 1, "epoch": 7, "state": 1, "reason": 0, "round_id": 1, "attempt_id": 1, "host_tick": 4}))
	_check(client.client_paused and client.client_pause_epoch == 7 and seen == [[true, 7]], "a client shows the host pause")
	client._receive_pause_state(NetworkLifecycleCodec.encode_pause_state({"match_id": 1, "epoch": 7, "state": 1, "reason": 0, "round_id": 1, "attempt_id": 1, "host_tick": 4}))
	client._receive_pause_state(NetworkLifecycleCodec.encode_pause_state({"match_id": 1, "epoch": 6, "state": 0, "reason": 0, "round_id": 1, "attempt_id": 1, "host_tick": 4}))
	_check(client.client_paused and seen.size() == 1, "a duplicate and a stale epoch change nothing")
	client._receive_pause_state(NetworkLifecycleCodec.encode_pause_state({"match_id": 2, "epoch": 9, "state": 0, "reason": 0, "round_id": 1, "attempt_id": 1, "host_tick": 4}))
	_check(client.client_paused, "a pause for another match is ignored")
	client.free()
	await _free_host_fixture(fixture)


func get_root_paused() -> bool:
	return paused


# --- client lifecycle -------------------------------------------------------------------------


func _test_client_lifecycle() -> void:
	var client := CaptureManager.new()
	root.add_child(client)
	client.client_mode = true
	client.match_active = true
	client.sync_ready = true
	client.client_assigned_seat = 1
	client.assigned_peer_generation = GENERATION
	client.active_match_id = 1
	client.client_set_continuous_input([1000, 0], [0, 0], false)
	client.client_set_action(0, true)
	_check(client._client_held_mask != 0 and client._client_axes[0] == 1000, "the client holds jump and right before it loses focus")
	client.sent.clear()
	client._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	var inputs := _sent_family(client, NetworkFrame.Family.CONTINUOUS_INPUT)
	var neutral := NetworkMatchCodec.decode_input(inputs.back()) if not inputs.is_empty() else {}
	_check(inputs.size() == 1 and int(neutral.get("held", -1)) == 0 and int(neutral.axes[0]) == 0 and not bool(neutral.build_mode), "focus loss sends one neutral sample immediately")
	_check(client._client_held_mask == 0 and client._client_axes == [0, 0], "no movement or jump stays held locally")
	var hints := _sent_family(client, NetworkFrame.Family.LIFECYCLE_HINT)
	var hint := NetworkLifecycleCodec.decode_lifecycle_hint(hints[0]) if not hints.is_empty() else {}
	_check(hints.size() == 1 and int(hint.get("state", -1)) == NetworkLifecycleCodec.Hint.FOCUS_OUT and int(hint.get("peer_generation", 0)) == GENERATION, "one bounded lifecycle hint accompanies it")
	client._send_client_continuous_input()
	_check(_sent_family(client, NetworkFrame.Family.CONTINUOUS_INPUT).size() == 1, "streaming stops while backgrounded")
	_check(not client.client_set_continuous_input([1000, 0]) and not client.client_set_action(0, true), "held state cannot be re-armed while backgrounded")
	client._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	_check(_sent_family(client, NetworkFrame.Family.LIFECYCLE_HINT).size() == 1, "repeated focus-out sends no second hint")
	client._client_last_state_ms = Time.get_ticks_msec()
	client._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	var after := _sent_family(client, NetworkFrame.Family.LIFECYCLE_HINT)
	_check(after.size() == 2 and int(NetworkLifecycleCodec.decode_lifecycle_hint(after.back()).state) == NetworkLifecycleCodec.Hint.FOCUS_IN, "return sends the foreground hint")
	var neutral_again := NetworkMatchCodec.decode_input(_sent_family(client, NetworkFrame.Family.CONTINUOUS_INPUT).back())
	_check(int(neutral_again.held) == 0 and int(neutral_again.axes[0]) == 0, "return starts from a fresh neutral sample")
	_check(_sent_family(client, NetworkFrame.Family.SNAPSHOT_REQUEST).is_empty(), "a quick return needs no resync")
	# A hint over the budget is retried, never dropped: at most two per second leave the client.
	client._client_hint_times = [Time.get_ticks_msec(), Time.get_ticks_msec()]
	client._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	_check(_sent_family(client, NetworkFrame.Family.LIFECYCLE_HINT).size() == 2 and client._client_pending_hint == NetworkLifecycleCodec.Hint.BACKGROUND, "a third hint inside a second waits instead of being sent")
	client._client_hint_times.clear()
	client._client_send_hint(client._client_pending_hint)
	_check(_sent_family(client, NetworkFrame.Family.LIFECYCLE_HINT).size() == 3 and client._client_pending_hint == -1, "the waiting hint goes out next frame")
	# A long absence resyncs from the host's snapshot on return.
	client._client_last_state_ms = Time.get_ticks_msec() - 10000
	client._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	_check(not _sent_family(client, NetworkFrame.Family.SNAPSHOT_REQUEST).is_empty() and not client.sync_ready, "a stale return requests a full snapshot")
	client.free()
	# A client that is not in a match ignores lifecycle callbacks.
	var idle := CaptureManager.new()
	root.add_child(idle)
	idle.client_mode = true
	idle._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	_check(idle.sent.is_empty() and not idle._client_backgrounded, "a lobby client sends nothing on focus loss")
	idle.free()


func _test_host_hint_and_reservation() -> void:
	var fixture: Dictionary = await _host_fixture()
	var manager: CaptureManager = fixture.manager
	var router: LocalInputRouter = fixture.router
	var seat := int(fixture.remote_seat)
	manager.match_active = true
	manager.candidates[REMOTE_PEER].match_sync_ready = true
	var stale := NetworkLifecycleCodec.encode_lifecycle_hint(GENERATION + 1, 1, NetworkLifecycleCodec.Hint.BACKGROUND)
	manager._accept_lifecycle_hint(REMOTE_PEER, stale, manager.candidates[REMOTE_PEER])
	_check(not bool(manager.candidates[REMOTE_PEER].get("backgrounded", false)), "a hint with a stale peer generation is refused")
	manager._host_input_state[REMOTE_PEER] = {"generation": GENERATION, "last_valid_ms": Time.get_ticks_msec(), "last_sequence": 1, "timed_out": false, "await_neutral": false}
	router.apply_remote_sample(REMOTE_SOURCE, [1000, 0], [0, 0], NetworkMatchCodec.HELD_JUMP, false)
	var hint := NetworkLifecycleCodec.encode_lifecycle_hint(GENERATION, 1, NetworkLifecycleCodec.Hint.BACKGROUND)
	manager._accept_lifecycle_hint(REMOTE_PEER, hint, manager.candidates[REMOTE_PEER])
	_check(bool(manager.candidates[REMOTE_PEER].backgrounded) and bool(manager._host_input_state[REMOTE_PEER].timed_out), "a valid background hint neutralises the peer at once")
	manager._accept_lifecycle_hint(REMOTE_PEER, hint, manager.candidates[REMOTE_PEER])
	_check(bool(manager.candidates[REMOTE_PEER].backgrounded), "a replayed hint sequence is ignored")
	_check(manager._peer_backgrounded(manager.candidates[REMOTE_PEER]), "a backgrounded peer's held input is dropped by the host gate")
	manager.candidates[REMOTE_PEER].background_at_ms = Time.get_ticks_msec() - 6000
	_check(not manager._peer_backgrounded(manager.candidates[REMOTE_PEER]), "the gate expires after 5 s so a lost foreground hint cannot lock input forever")
	manager.candidates[REMOTE_PEER].background_at_ms = Time.get_ticks_msec()
	manager._accept_lifecycle_hint(REMOTE_PEER, NetworkLifecycleCodec.encode_lifecycle_hint(GENERATION, 2, NetworkLifecycleCodec.Hint.FOCUS_IN), manager.candidates[REMOTE_PEER])
	_check(not bool(manager.candidates[REMOTE_PEER].backgrounded), "the foreground hint clears the flag")
	# Disconnect during a match reserves the seat, score and identity; the lobby would release it.
	var identity_before := manager.reservations.player_id_of(seat)
	manager.match_active = true
	manager._unbind_peer_seat(REMOTE_PEER, manager.candidates[REMOTE_PEER])
	var seat_state := router.registry.get_seat(seat)
	_check(bool(seat_state.joined) and not bool(seat_state.connected) and str(seat_state.remote_source_id) == "", "a match disconnect keeps the seat joined but disconnected")
	_check(manager.reservations.is_reserved(seat) and manager.reservations.player_id_of(seat) == identity_before and manager.reservations.remaining_ms(seat, Time.get_ticks_msec()) > 59000, "the identity is reserved for 60 s")
	_check(router.registry.seat_for_remote_source(REMOTE_SOURCE) < 0, "the old source no longer controls any seat")
	_check(router.registry.assign_remote_source("peer_77", -1, SimulationAuthority.host()) != seat, "a new source never lands on the reserved seat")
	manager.admission_open = false
	var join_peer := CaptureManager.new()
	root.add_child(join_peer)
	join_peer.host_authority = SimulationAuthority.host()
	join_peer.candidates[88] = {"state": NetworkSessionManager.CandidateState.CHALLENGE, "seat": -1, "deadline": 0, "reclaim_only": true, "claim_seat": -1}
	join_peer._handle_host_packet(88, NetworkFrame.Family.JOIN_BEGIN, Crypto.new().generate_random_bytes(16))
	var closed := _sent_family(join_peer, NetworkFrame.Family.ADMISSION_DECISION).filter(func(payload: PackedByteArray) -> bool: return join_peer._read_u16(payload) == NetworkFrame.Reason.LOBBY_CLOSED)
	_check(not closed.is_empty() and join_peer.candidates[88].state == NetworkSessionManager.CandidateState.CHALLENGE, "a join request in the reclaim window is refused and gets no challenge")
	join_peer.free()
	# The lobby path is unchanged: a lobby disconnect releases the seat completely.
	manager.reservations.clear()
	manager.match_active = false
	var lobby_seat := router.registry.assign_remote_source("peer_88", -1, SimulationAuthority.host())
	manager.reservations.issue(lobby_seat)
	manager.candidates[88] = {"state": NetworkSessionManager.CandidateState.ACKNOWLEDGED, "seat": lobby_seat, "claim_seat": -1}
	manager._unbind_peer_seat(88, manager.candidates[88])
	_check(not bool(router.registry.get_seat(lobby_seat).joined) and not manager.reservations.has_entry(lobby_seat), "a lobby disconnect still releases the seat and forgets the identity")
	await _free_host_fixture(fixture)


# --- reservation book and registry ----------------------------------------------------------


func _test_reservation_book() -> void:
	var book := SeatReservationBook.new()
	var identity := book.issue(2)
	_check(identity.player_id.size() == 16 and identity.token.size() == 16 and identity.player_id != identity.token, "a Player ID and a token are 128 random bits each")
	_check(book.issue(9).is_empty(), "no seat above the four-seat cap gets an identity")
	_check(book.seat_for_player(identity.player_id) == 2 and book.seat_for_player(Crypto.new().generate_random_bytes(16)) < 0, "a Player ID resolves only its own seat")
	_check(book.token_for_proof(2).is_empty(), "an unreserved seat has no proof key")
	_check(book.reserve(2, 1000) and book.is_reserved(2) and book.remaining_ms(2, 1000) == 60000, "reserve starts a 60 s grace")
	_check(book.reserve(2, 5000) and book.remaining_ms(2, 5000) == 56000, "reserving twice does not restart the clock")
	_check(book.take_expired(60999).is_empty() and book.take_expired(61000) == [2], "the reservation expires exactly once at 60 s")
	_check(book.take_expired(70000).is_empty() and book.is_expired(2) and book.remaining_ms(2, 70000) == 0, "an expired reservation is reported once and stays reserved")
	_check(book.claim_round_commit(2, 4) and not book.claim_round_commit(2, 4) and book.claim_round_commit(2, 5), "one disconnect elimination per round per seat")
	_check(book.committed_round(2) == 5, "the committed round is remembered")
	_check(book.begin_claim(2, 61) and book.begin_claim(2, 61) and not book.begin_claim(2, 62), "only one reclaim is in flight; a racing peer is refused")
	book.release_claim(2, 62)
	_check(not book.begin_claim(2, 62), "a loser cannot release the winner's claim")
	_check(book.rotate_token(2, 62).is_empty(), "only the claiming peer can rotate the token")
	var old_token := book.token_for_proof(2)
	var new_token := book.rotate_token(2, 61)
	_check(new_token.size() == 16 and new_token != old_token and book.token_for_proof(2) == new_token, "a verified reclaim rotates the token and revokes the old one")
	_check(book.is_reserved(2) and book.finish_reclaim(2, 61) and not book.is_reserved(2), "the reservation clears when the seat is rebound")
	_check(book.committed_round(2) == 5, "the committed round survives reclaim so a round is never double-counted")
	for seat in 4:
		book.issue(seat)
		book.reserve(seat, 0)
	_check(book.reserved_seats().size() == 4, "at most four seats can be reserved")
	book.clear()
	_check(book.reserved_seats().is_empty() and not book.has_entry(0), "the book clears with the session")


func _test_registry_reservation_and_reclaim() -> void:
	var registry := PlayerSeatRegistry.new()
	var host := SimulationAuthority.host()
	var seat := registry.assign_remote_source("peer_5", -1, host)
	_check(seat == 0, "a remote source takes the first seat")
	_check(not registry.reclaim_remote_source("peer_6", seat, host), "a connected seat cannot be reclaimed")
	_check(registry.revoke_remote_source("peer_5", host) and bool(registry.get_seat(seat).joined) and not bool(registry.get_seat(seat).connected), "revoke keeps the seat joined (a reservation)")
	_check(not registry.reclaim_remote_source("peer_6", seat, SimulationAuthority.new()), "a client authority cannot reclaim")
	_check(not registry.reclaim_remote_source("peer_6", 3, host), "an unjoined seat cannot be taken by the reclaim path")
	_check(registry.reclaim_remote_source("peer_6", seat, host) and registry.seat_for_remote_source("peer_6") == seat and registry.seat_for_remote_source("peer_5") < 0, "reclaim rebinds the same seat to the new source only")
	_check(not bool(registry.get_seat(seat).ready), "a reclaimed seat starts not ready")
	var other := registry.assign_remote_source("peer_7", -1, host)
	_check(other == 1, "a new join after the reclaim takes a different seat")


# --- reclaim ----------------------------------------------------------------------------------


func _test_reclaim_flow() -> void:
	var fixture: Dictionary = await _host_fixture()
	var manager: CaptureManager = fixture.manager
	var router: LocalInputRouter = fixture.router
	var seat := int(fixture.remote_seat)
	manager.match_active = true
	manager.session_epoch = 4242
	var player_id := manager.reservations.player_id_of(seat)
	var first_token := manager.reservations.token_for_proof(seat)
	_check(first_token.is_empty(), "before a disconnect the seat is not reserved, so it cannot be reclaimed")
	manager._unbind_peer_seat(REMOTE_PEER, manager.candidates[REMOTE_PEER])
	manager.candidates.erase(REMOTE_PEER)
	var token := manager.reservations.token_for_proof(seat)
	_check(token.size() == 16, "a disconnected seat is keyed by its reclaim token")
	# A forged Player ID gets the same answer as an unreserved seat.
	manager.candidates[SECOND_PEER] = _challenge_candidate()
	manager.sent.clear()
	var forged := NetworkLifecycleCodec.encode_reclaim_begin(Crypto.new().generate_random_bytes(16), Crypto.new().generate_random_bytes(16), 0)
	manager._accept_reclaim_begin(SECOND_PEER, forged, manager.candidates[SECOND_PEER])
	var denied := _sent_family(manager, NetworkFrame.Family.ADMISSION_DECISION).filter(func(payload: PackedByteArray) -> bool: return manager._read_u16(payload) == NetworkFrame.Reason.TOKEN_INVALID)
	_check(not denied.is_empty() and int(manager.candidates[SECOND_PEER].claim_seat) < 0 and _sent_family(manager, NetworkFrame.Family.CHALLENGE).is_empty(), "a forged Player ID is refused with no challenge")
	# The real claim: a challenge, then an HMAC under the reclaim context.
	manager.candidates[SECOND_PEER] = _challenge_candidate()
	var client_nonce := Crypto.new().generate_random_bytes(16)
	manager._accept_reclaim_begin(SECOND_PEER, NetworkLifecycleCodec.encode_reclaim_begin(player_id, client_nonce, 0), manager.candidates[SECOND_PEER])
	var challenges := _sent_family(manager, NetworkFrame.Family.CHALLENGE)
	_check(challenges.size() == 1 and challenges[0].size() == 32 and challenges[0].slice(0, 16) == client_nonce, "a reclaim begin is answered with the single-use challenge")
	var server_nonce: PackedByteArray = challenges[0].slice(16, 32)
	# A second peer racing for the same seat is refused while the first claim is in flight.
	manager.candidates[53] = _challenge_candidate()
	manager._accept_reclaim_begin(53, NetworkLifecycleCodec.encode_reclaim_begin(player_id, Crypto.new().generate_random_bytes(16), 0), manager.candidates[53])
	_check(int(manager.candidates[53].claim_seat) < 0, "a second peer cannot claim a seat that is already being claimed")
	# A join-context proof, a stale token and a wrong session epoch all fail; the claim stays open for the owner.
	var join_proof := InvitationCode.proof(token, 4242, client_nonce, server_nonce)
	manager.sent.clear()
	manager._verify_reclaim_proof(SECOND_PEER, manager.candidates[SECOND_PEER], join_proof)
	_check(router.registry.seat_for_remote_source("peer_52") < 0 and int(manager.candidates[SECOND_PEER].claim_seat) < 0, "a proof in the join context never reclaims a seat and frees the claim")
	# Fresh claim for the genuine proof.
	manager.candidates[SECOND_PEER] = _challenge_candidate()
	var nonce_two := Crypto.new().generate_random_bytes(16)
	manager._accept_reclaim_begin(SECOND_PEER, NetworkLifecycleCodec.encode_reclaim_begin(player_id, nonce_two, 0), manager.candidates[SECOND_PEER])
	var server_two: PackedByteArray = _sent_family(manager, NetworkFrame.Family.CHALLENGE).back().slice(16, 32)
	var good := InvitationCode.proof(token, 4242, nonce_two, server_two, InvitationCode.CONTEXT_RECLAIM)
	manager.sent.clear()
	manager._verify_reclaim_proof(SECOND_PEER, manager.candidates[SECOND_PEER], good)
	var results := _sent_family(manager, NetworkFrame.Family.RECLAIM_RESULT)
	var result := NetworkLifecycleCodec.decode_reclaim_result(results[0]) if not results.is_empty() else {}
	_check(results.size() == 1 and int(result.get("reason", -1)) == NetworkFrame.Reason.OK and int(result.get("seat", -1)) == seat, "a valid proof returns the SAME seat")
	_check(result.get("token", PackedByteArray()) != token and manager.reservations.token_for_proof(seat) == result.get("token", PackedByteArray()), "the reclaim token rotated and the old one is revoked")
	_check(int(result.get("peer_generation", 0)) != GENERATION and int(result.peer_generation) == int(manager.candidates[SECOND_PEER].peer_generation), "the new peer generation differs from the old one")
	_check(not bool(router.registry.get_seat(seat).connected) and manager.reservations.is_reserved(seat), "the seat is not rebound before the snapshot acknowledgement")
	# The replayed proof (old transcript) cannot be used again: the old token no longer verifies.
	manager.candidates[53] = _challenge_candidate()
	manager._accept_reclaim_begin(53, NetworkLifecycleCodec.encode_reclaim_begin(player_id, Crypto.new().generate_random_bytes(16), 0), manager.candidates[53])
	_check(int(manager.candidates[53].claim_seat) < 0, "while one reclaim is in flight another is refused")
	# Safe boundary: bind after the snapshot is acknowledged; input then needs a fresh neutral sample.
	var bound := manager._finalize_reclaim_bind(SECOND_PEER, manager.candidates[SECOND_PEER])
	var state := router.registry.get_seat(seat)
	_check(bound and bool(state.connected) and str(state.remote_source_id) == "peer_52" and not manager.reservations.is_reserved(seat), "the seat is rebound after the snapshot, and the reservation clears")
	_check(bool(manager._host_input_state[SECOND_PEER].await_neutral) and bool(manager._host_input_state[SECOND_PEER].timed_out), "the reclaimed seat needs a fresh neutral sample; no input is replayed")
	_check(manager._pending_continuous.get(SECOND_PEER, null) == null, "no earlier input is queued for the reclaimed seat")
	_check(router.registry.seat_for_remote_source(REMOTE_SOURCE) < 0, "the old peer generation lost authority")
	# The old peer's late disconnect cannot reserve or revoke the new owner's seat.
	var stale_candidate := {"state": NetworkSessionManager.CandidateState.ACKNOWLEDGED, "seat": seat, "claim_seat": -1}
	manager._unbind_peer_seat(REMOTE_PEER, stale_candidate)
	_check(bool(router.registry.get_seat(seat).connected) and not manager.reservations.is_reserved(seat), "a stale disconnect cannot take the seat back from the new owner")
	# Reclaim expiry rule: an expired reservation cannot be reclaimed in the middle of PLAY.
	manager.reservations.reserve(seat, 0)
	manager.reservations.take_expired(61000)
	_check(manager.reservations.is_expired(seat), "the expired reservation stays reserved for a later boundary")
	await _free_host_fixture(fixture)


func _challenge_candidate() -> Dictionary:
	return {
		"state": NetworkSessionManager.CandidateState.CHALLENGE,
		"seat": -1,
		"deadline": 0,
		"nonce": PackedByteArray(),
		"server_nonce": PackedByteArray(),
		"reclaim_only": true,
		"claim_seat": -1,
	}


# --- disconnect elimination -----------------------------------------------------------------


func _test_disconnect_elimination_paths() -> void:
	# Karera: a no-source elimination with the disconnect cause, never a Patibong owner.
	var ledger := RaceOutcomeLedger.new()
	var seats: Array[int] = [0, 1]
	ledger.begin("p8", seats, {})
	var batch: Array[Dictionary] = [
		{"event_id": "p8:disconnect:1", "round_id": "p8", "seat_index": 1, "kind": "elimination", "physics_tick": 9, "source_item_id": "", "direct_owner_seat": -1, "cause": RaceOutcomeLedger.CAUSE_DISCONNECT},
	]
	var resolved := ledger.resolve_step(9, batch)
	_check(resolved.size() == 1 and str(resolved[0].cause) == "disconnect" and int(resolved[0].direct_owner_seat) == -1 and str(resolved[0].source_item_id).is_empty(), "a disconnect elimination is a no-source outcome with cause disconnect")
	var again := ledger.resolve_step(10, [{"event_id": "p8:disconnect:1b", "round_id": "p8", "seat_index": 1, "kind": "elimination", "physics_tick": 10, "cause": "disconnect"}])
	_check(again.is_empty() and ledger.outcomes().size() == 1, "a seat is eliminated at most once per round")
	var mixed := RaceOutcomeLedger.new()
	mixed.begin("p8b", seats, {})
	var same_step: Array[Dictionary] = [
		{"event_id": "a:trap", "round_id": "p8b", "seat_index": 1, "kind": "elimination", "physics_tick": 3, "source_item_id": "trap.1", "direct_owner_seat": 0},
		{"event_id": "b:disconnect", "round_id": "p8b", "seat_index": 1, "kind": "elimination", "physics_tick": 3, "source_item_id": "", "direct_owner_seat": -1, "cause": "disconnect"},
	]
	var merged := mixed.resolve_step(3, same_step)
	_check(merged.size() == 1 and int(merged[0].direct_owner_seat) == -1, "a disconnect on the same step as a trap earns no Patibong for anyone")
	var goal_batch: Array[Dictionary] = [{"event_id": "g", "round_id": "p8c", "seat_index": 1, "kind": "goal", "physics_tick": 4}, {"event_id": "d", "round_id": "p8c", "seat_index": 1, "kind": "elimination", "physics_tick": 4, "cause": "disconnect"}]
	var goal_ledger := RaceOutcomeLedger.new()
	goal_ledger.begin("p8c", seats, {})
	var goal_resolved := goal_ledger.resolve_step(4, goal_batch)
	_check(goal_resolved.size() == 1 and str(goal_resolved[0].outcome) == "eliminated", "elimination keeps its priority over a goal on the same step (P12 order unchanged)")
	# Lagsanay (and Sudden Death, which is the same controller): one disconnect outcome, lowest rank.
	var host := SimulationAuthority.host()
	var event := LagsanayRoundController.new()
	event.authority = host
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var event_seats: Array[int] = [0, 1, 2]
	_check(event.begin("lag", event_seats, {}, rng, 0.5, 1.0, 7.0, 6.0, 5.0), "a Lagsanay round starts for the disconnect fixture")
	_check(event.submit_disconnect(2, 1) and event.submit_disconnect(2, 1) and event.pending_disconnects.size() == 1, "a seat is queued once")
	_check(not event.submit_disconnect(7, 1), "a seat outside the round cannot be queued")
	var empty_contacts: Array[Dictionary] = []
	var step := event.advance_step(0.1, 2, empty_contacts, {})
	var disconnected: Array = step.new_outcomes.filter(func(outcome: Dictionary) -> bool: return str(outcome.cause) == "disconnect")
	_check(disconnected.size() == 1 and int(disconnected[0].seat_index) == 2 and str(disconnected[0].source_item_id).is_empty() and int(disconnected[0].direct_owner_seat) == -1, "Lagsanay commits one disconnect elimination with no Patibong owner")
	_check(not event.submit_disconnect(2, 3), "a finished seat cannot be queued again")
	var live := event._live_seats()
	_check(not live.has(2) and live.size() == 2 and not event.ended, "the round continues with the remaining runners")
	var taya_case := LagsanayRoundController.new()
	taya_case.authority = host
	taya_case.begin("lag2", [0, 1, 2] as Array[int], {}, rng, 0.5, 1.0, 7.0, 6.0, 5.0)
	var taya := taya_case.taya_seat
	taya_case.submit_disconnect(taya, 1)
	taya_case.advance_step(0.1, 2, empty_contacts, {})
	_check(taya_case.taya_seat != taya and taya_case.outcomes_by_seat.has(taya), "a disconnected taya is eliminated and the bomb is redrawn")
	_check(LagsanayRoundController.new().submit_disconnect(0, 1) == false, "an inactive controller refuses a disconnect")
	# The round id bookkeeping lives in the book: one elimination per round, never two.
	var book := SeatReservationBook.new()
	book.issue(1)
	book.reserve(1, 0)
	book.take_expired(60000)
	_check(book.claim_round_commit(1, 3) and not book.claim_round_commit(1, 3), "expiry exactly at the round end commits at most once")


func _test_offline_rules_unchanged() -> void:
	var registry := PlayerSeatRegistry.new()
	var seat := registry.join_gamepad(4)
	_check(registry.disconnect_gamepad(4) == seat and not bool(registry.get_seat(seat).connected), "a gamepad disconnect still keeps the seat")
	_check(registry.reclaim_gamepad(seat, 9) and bool(registry.get_seat(seat).connected), "offline gamepad reclaim is unchanged")
	_check(not registry.all_joined_ready_and_connected(), "the offline resume rule still needs every joined seat ready")
	registry.join_keyboard("K1")
	registry.set_ready(0, true)
	registry.set_ready(1, true)
	_check(registry.all_joined_ready_and_connected(), "the offline all-seats readiness rule is unchanged")
	var router := LocalInputRouter.new()
	root.add_child(router)
	router.registry.join_keyboard("K1")
	var coordinator := PauseRecoveryCoordinator.new()
	coordinator.input_router = router
	root.add_child(coordinator)
	_check(not coordinator.remote_ready_exempt, "offline coordinators keep the all-seats resume rule")
	coordinator.free()
	router.free()


# --- fixtures -------------------------------------------------------------------------------


func _host_fixture() -> Dictionary:
	var host := SimulationAuthority.host()
	var router := LocalInputRouter.new()
	root.add_child(router)
	router.set_authority(host)
	var manager := CaptureManager.new()
	manager.configure(router)
	root.add_child(manager)
	manager.host_authority = host
	manager.remote_adapter.configure(router, host)
	router.registry.join_keyboard("K1")
	var remote_seat := manager.remote_adapter.assign_source(REMOTE_SOURCE)
	manager.reservations.issue(remote_seat)
	manager.candidates[REMOTE_PEER] = {
		"state": NetworkSessionManager.CandidateState.ACKNOWLEDGED,
		"seat": remote_seat,
		"peer_generation": GENERATION,
		"deadline": 0,
		"claim_seat": -1,
		"match_sync_ready": false,
	}
	await process_frame
	return {"manager": manager, "router": router, "remote_seat": remote_seat}


func _free_host_fixture(fixture: Dictionary) -> void:
	paused = false
	(fixture.manager as Node).queue_free()
	(fixture.router as Node).queue_free()
	await process_frame


func _sent_family(manager: CaptureManager, family: int) -> Array:
	var payloads: Array = []
	for entry in manager.sent:
		if int(entry.family) == family:
			payloads.append(entry.payload)
	return payloads


func _check(condition: bool, label: String) -> void:
	checks += 1
	if condition:
		print("PASS ", label)
	else:
		failures += 1
		push_error("FAIL " + label)

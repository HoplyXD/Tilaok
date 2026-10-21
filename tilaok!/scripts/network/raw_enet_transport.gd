class_name RawEnetTransport
extends RefCounted

signal connected(peer_id: int)
signal disconnected(peer_id: int)
signal packet_received(peer_id: int, channel: int, packet: PackedByteArray)
signal transport_error(message: String)

const MAX_PEERS := 8
const MAX_EVENTS_PER_FRAME := 16
const CONTROL_CHANNEL := 0
const INPUT_CHANNEL := 1
const STATE_CHANNEL := 2
const CHANNEL_COUNT := 3

var connection := ENetConnection.new()
var is_host := false
var is_open := false
var _peers: Dictionary = {}
var _peer_ids_by_endpoint: Dictionary = {}
var _peer_ids_by_instance: Dictionary = {}
var _next_peer_id := 1
## NLB-P11: null unless a development build asked for fault injection (NlbFaultInjector.from_cmdline).
var fault: NlbFaultInjector = null
## NLB-P11 counters: complete application frames (22-byte envelope + payload) handed to / received
## from ENet. Cumulative; telemetry reads deltas. They hold no peer data.
var app_tx_bytes := 0
var app_rx_bytes := 0
var app_tx_packets := 0
var app_rx_packets := 0


func open_host(address: String, port: int) -> Error:
	if is_open:
		close()
	var error := connection.create_host_bound(address, port, MAX_PEERS, CHANNEL_COUNT)
	if error != OK:
		return error
	is_host = true
	is_open = true
	return OK


func open_client(address: String, port: int) -> Error:
	if is_open:
		close()
	var error := connection.create_host(1, CHANNEL_COUNT)
	if error != OK:
		return error
	var peer := connection.connect_to_host(address, port, CHANNEL_COUNT)
	if peer == null:
		close()
		return ERR_CANT_CREATE
	is_host = false
	is_open = true
	return OK


func poll() -> void:
	if not is_open:
		return
	if fault != null:
		_deliver_held_faults()
	var processed := 0
	while processed < MAX_EVENTS_PER_FRAME:
		var event := connection.service(0)
		if event.is_empty():
			break
		processed += 1
		var kind := int(event[0])
		var peer := event[1] as ENetPacketPeer
		if peer == null:
			if int(event[0]) == ENetConnection.EVENT_ERROR:
				transport_error.emit("ENet service reported an error")
				continue
			continue
		var peer_instance_id := peer.get_instance_id()
		var peer_id: int = int(_peer_ids_by_instance.get(peer_instance_id, 0))
		var endpoint := ""
		if kind != ENetConnection.EVENT_DISCONNECT:
			endpoint = _endpoint_key(peer)
			if peer_id == 0:
				peer_id = int(_peer_ids_by_endpoint.get(endpoint, 0))
		match kind:
			ENetConnection.EVENT_CONNECT:
				if peer_id == 0:
					peer_id = _next_peer_id
					_next_peer_id += 1
					_peer_ids_by_endpoint[endpoint] = peer_id
				_peer_ids_by_instance[peer_instance_id] = peer_id
				_peers[peer_id] = peer
				connected.emit(peer_id)
			ENetConnection.EVENT_DISCONNECT:
				_peers.erase(peer_id)
				_peer_ids_by_instance.erase(peer_instance_id)
				if not endpoint.is_empty():
					_peer_ids_by_endpoint.erase(endpoint)
				disconnected.emit(peer_id)
			ENetConnection.EVENT_RECEIVE:
				var received := peer.get_packet()
				app_rx_bytes += received.size()
				app_rx_packets += 1
				if fault != null and fault.is_active():
					_inject_incoming(peer_id, int(event[3]), received)
				else:
					packet_received.emit(peer_id, int(event[3]), received)
			ENetConnection.EVENT_ERROR:
				transport_error.emit("ENet service reported an error")


func _endpoint_key(peer: ENetPacketPeer) -> String:
	return "%s:%d" % [peer.get_remote_address(), peer.get_remote_port()]


func send(peer_id: int, packet: PackedByteArray, channel: int = CONTROL_CHANNEL) -> Error:
	if not is_open or packet.is_empty() or packet.size() > NetworkFrame.MAX_FRAME_BYTES:
		return ERR_INVALID_PARAMETER
	if channel < CONTROL_CHANNEL or channel >= CHANNEL_COUNT:
		return ERR_INVALID_PARAMETER
	var peer: ENetPacketPeer = _peers.get(peer_id)
	if peer == null or peer.get_state() != ENetPacketPeer.STATE_CONNECTED:
		return ERR_DOES_NOT_EXIST
	# ENet's default packet mode is unreliable-sequenced. In particular, do not set
	# FLAG_UNSEQUENCED for superseding input or state records.
	if fault != null and fault.is_active():
		_inject_outgoing(peer_id, channel, packet)
		return OK
	return _send_now(peer, channel, packet)


func _send_now(peer: ENetPacketPeer, channel: int, packet: PackedByteArray) -> Error:
	var flags := ENetPacketPeer.FLAG_RELIABLE if channel == CONTROL_CHANNEL else 0
	var error := peer.send(channel, packet, flags)
	if error == OK:
		app_tx_bytes += packet.size()
		app_tx_packets += 1
	return error


func send_to_all(packet: PackedByteArray, channel: int = CONTROL_CHANNEL) -> Error:
	if not is_host or not is_open or packet.is_empty() or packet.size() > NetworkFrame.MAX_FRAME_BYTES:
		return ERR_INVALID_PARAMETER
	if channel < CONTROL_CHANNEL or channel >= CHANNEL_COUNT:
		return ERR_INVALID_PARAMETER
	if fault != null and fault.is_active():
		# Faults are per packet and per peer, so a broadcast becomes one send per connected peer.
		for peer_id in _peers.keys():
			send(int(peer_id), packet, channel)
		return OK
	var flags := ENetPacketPeer.FLAG_RELIABLE if channel == CONTROL_CHANNEL else 0
	connection.broadcast(channel, packet, flags)
	app_tx_bytes += packet.size() * _peers.size()
	app_tx_packets += _peers.size()
	return OK


func close_peer(peer_id: int, after_queued_packets: bool = false) -> void:
	var peer: ENetPacketPeer = _peers.get(peer_id)
	if peer != null:
		if after_queued_packets:
			peer.peer_disconnect_later()
			connection.flush()
		else:
			# disconnect_now raises no DISCONNECT event, so the endpoint tables are cleared here.
			_peer_ids_by_instance.erase(peer.get_instance_id())
			_peer_ids_by_endpoint.erase(_endpoint_key(peer))
			peer.peer_disconnect_now()
			_peers.erase(peer_id)


func request_disconnect_all() -> void:
	if not is_open:
		return
	for peer in _peers.values():
		var packet_peer := peer as ENetPacketPeer
		if packet_peer != null and packet_peer.is_active():
			packet_peer.peer_disconnect_later()
	connection.flush()


func _inject_outgoing(peer_id: int, channel: int, packet: PackedByteArray) -> void:
	var now := Time.get_ticks_msec()
	for entry in fault.filter(NlbFaultInjector.OUTGOING, peer_id, channel, packet, now):
		if int(entry.due_ms) <= now:
			_deliver_fault_entry(entry)
		else:
			fault.hold(entry)


func _inject_incoming(peer_id: int, channel: int, packet: PackedByteArray) -> void:
	var now := Time.get_ticks_msec()
	for entry in fault.filter(NlbFaultInjector.INCOMING, peer_id, channel, packet, now):
		if int(entry.due_ms) <= now:
			_deliver_fault_entry(entry)
		else:
			fault.hold(entry)


func _deliver_held_faults() -> void:
	var now := Time.get_ticks_msec()
	fault.announce(now)
	for entry in fault.pop_due(now):
		_deliver_fault_entry(entry)


func _deliver_fault_entry(entry: Dictionary) -> void:
	if int(entry.direction) == NlbFaultInjector.OUTGOING:
		var peer: ENetPacketPeer = _peers.get(int(entry.peer_id))
		if peer != null and peer.get_state() == ENetPacketPeer.STATE_CONNECTED:
			_send_now(peer, int(entry.channel), entry.packet)
	elif _peers.has(int(entry.peer_id)):
		packet_received.emit(int(entry.peer_id), int(entry.channel), entry.packet)


## Per-peer ENet statistics for telemetry: {peer_id: {rtt_ms, rtt_var_ms, loss_ratio}} (no
## addresses). RTT is ENet's own single-endpoint estimate, never a one-way latency.
func peer_statistics() -> Dictionary:
	var result := {}
	for peer_id in _peers:
		var peer := _peers[peer_id] as ENetPacketPeer
		if peer == null or peer.get_state() != ENetPacketPeer.STATE_CONNECTED:
			continue
		result[int(peer_id)] = {
			"rtt_ms": peer.get_statistic(ENetPacketPeer.PEER_ROUND_TRIP_TIME),
			"rtt_var_ms": peer.get_statistic(ENetPacketPeer.PEER_ROUND_TRIP_TIME_VARIANCE),
			"loss_ratio":
			peer.get_statistic(ENetPacketPeer.PEER_PACKET_LOSS) / float(ENetPacketPeer.PACKET_LOSS_SCALE),
		}
	return result


## ENet host totals since the previous call (pop_statistic resets them): network bytes/packets as
## ENet counts them, i.e. including ENet headers but not UDP/IP/link overhead.
func pop_host_statistics() -> Dictionary:
	if not is_open:
		return {}
	return {
		"net_tx_bytes": connection.pop_statistic(ENetConnection.HOST_TOTAL_SENT_DATA),
		"net_tx_packets": connection.pop_statistic(ENetConnection.HOST_TOTAL_SENT_PACKETS),
		"net_rx_bytes": connection.pop_statistic(ENetConnection.HOST_TOTAL_RECEIVED_DATA),
		"net_rx_packets": connection.pop_statistic(ENetConnection.HOST_TOTAL_RECEIVED_PACKETS),
	}


func peer_count() -> int:
	return _peers.size()


func close() -> void:
	if fault != null:
		fault.clear()
	if is_open:
		connection.destroy()
	_peers.clear()
	_peer_ids_by_endpoint.clear()
	_peer_ids_by_instance.clear()
	is_open = false
	is_host = false

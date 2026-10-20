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
				packet_received.emit(peer_id, int(event[3]), peer.get_packet())
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
	var flags := ENetPacketPeer.FLAG_RELIABLE if channel == CONTROL_CHANNEL else 0
	return peer.send(channel, packet, flags)


func send_to_all(packet: PackedByteArray, channel: int = CONTROL_CHANNEL) -> Error:
	if not is_host or not is_open or packet.is_empty() or packet.size() > NetworkFrame.MAX_FRAME_BYTES:
		return ERR_INVALID_PARAMETER
	if channel < CONTROL_CHANNEL or channel >= CHANNEL_COUNT:
		return ERR_INVALID_PARAMETER
	var flags := ENetPacketPeer.FLAG_RELIABLE if channel == CONTROL_CHANNEL else 0
	connection.broadcast(channel, packet, flags)
	return OK


func close_peer(peer_id: int, after_queued_packets: bool = false) -> void:
	var peer: ENetPacketPeer = _peers.get(peer_id)
	if peer != null:
		if after_queued_packets:
			peer.peer_disconnect_later()
			connection.flush()
		else:
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


func peer_count() -> int:
	return _peers.size()


func close() -> void:
	if is_open:
		connection.destroy()
	_peers.clear()
	_peer_ids_by_endpoint.clear()
	_peer_ids_by_instance.clear()
	is_open = false
	is_host = false

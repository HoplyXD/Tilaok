class_name LanDiscovery
extends RefCounted

const DISCOVERY_PORT_DEFAULT := 27778
const MAX_ENTRIES := 64
## Contract v1 §3.7 / P11: per-source query throttle state is bounded in count and age.
const MAX_QUERY_SOURCES := 128
const QUERY_SOURCE_TTL_MS := 10000
const MAX_EVENTS_PER_FRAME := 16
const ENTRY_TTL_SECONDS := 3.0
const QUERY_INTERVAL_SECONDS := 1.0

var socket := PacketPeerUDP.new()
var listening := false
var broadcasting := false
var selected_address := ""
var discovery_port := DISCOVERY_PORT_DEFAULT
var lobby_id := 0
var session_epoch := 0
var game_port := 27777
var digest := PackedByteArray()
var occupancy := 0
var lobby_open := true
var beacon_counter := 0
var last_sent_frame_bytes := 0
var last_received_frame_bytes := 0
var _beacon_clock := 0.0
var _query_clock := 0.0
var _last_beacon_msec := -500
var _last_query_by_source: Dictionary = {}
var _entries: Dictionary = {}


func start_host(
	interface_address: String, port: int, id_value: int, epoch: int, build_digest: PackedByteArray
) -> Error:
	stop()
	if not _is_ipv4(interface_address) or not _valid_port(port):
		return ERR_INVALID_PARAMETER
	selected_address = interface_address
	discovery_port = port
	lobby_id = id_value
	session_epoch = epoch
	digest = build_digest.duplicate()
	var error := socket.bind(discovery_port, selected_address)
	if error != OK:
		return error
	listening = true
	broadcasting = true
	_beacon_clock = 0.0
	return OK


func start_client(port: int) -> Error:
	stop()
	if not _valid_port(port):
		return ERR_INVALID_PARAMETER
	discovery_port = port
	var error := socket.bind(0, "0.0.0.0")
	if error != OK:
		return error
	socket.set_broadcast_enabled(true)
	listening = true
	broadcasting = false
	return OK


func process(delta: float) -> void:
	if not listening:
		return
	_beacon_clock += delta
	_query_clock += delta
	if broadcasting and _beacon_clock >= 1.0:
		_beacon_clock = 0.0
		_send_beacon()
	if not broadcasting and _query_clock >= QUERY_INTERVAL_SECONDS:
		_query_clock = 0.0
		query(0)
	_expire_entries()
	var processed := 0
	while socket.get_available_packet_count() > 0 and processed < MAX_EVENTS_PER_FRAME:
		processed += 1
		var packet := socket.get_packet()
		last_received_frame_bytes = packet.size()
		var address := socket.get_packet_ip()
		var source_port := socket.get_packet_port()
		if broadcasting:
			_receive_query(packet, address, source_port)
		else:
			_receive_beacon(packet, address, source_port)


func query(target_lobby_id: int = 0, destination: String = "255.255.255.255") -> Error:
	if not listening or broadcasting:
		return ERR_UNCONFIGURED
	if not destination.is_valid_ip_address():
		return ERR_INVALID_PARAMETER
	var stream := StreamPeerBuffer.new()
	stream.big_endian = false
	stream.put_u64(target_lobby_id)
	stream.put_u16(discovery_port)
	var frame := NetworkFrame.encode(NetworkFrame.Family.DISCOVERY_QUERY, 0, 0, stream.data_array)
	if frame.is_empty() or frame.size() > NetworkFrame.MAX_DISCOVERY_BYTES:
		return ERR_INVALID_DATA
	var error := socket.set_dest_address(destination, discovery_port)
	return error if error != OK else socket.put_packet(frame)


func discovered() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry in _entries.values():
		result.append(entry.duplicate(true))
	result.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool: return int(a.lobby_id) < int(b.lobby_id)
	)
	return result


func get_lobby(target_lobby_id: int) -> Dictionary:
	for entry in _entries.values():
		if int(entry.lobby_id) == target_lobby_id:
			return entry.duplicate(true)
	return {}


func stop() -> void:
	if listening:
		socket.close()
	listening = false
	broadcasting = false
	selected_address = ""
	_entries.clear()
	_last_query_by_source.clear()
	_beacon_clock = 0.0
	_query_clock = 0.0
	_last_beacon_msec = -500


func _send_beacon(destination: String = "255.255.255.255", destination_port: int = -1) -> void:
	var now := Time.get_ticks_msec()
	if now - _last_beacon_msec < 500:
		return
	beacon_counter += 1
	var stream := StreamPeerBuffer.new()
	stream.big_endian = false
	stream.put_u64(lobby_id)
	stream.put_u64(session_epoch)
	var ip_parts := selected_address.split(".")
	for part in ip_parts:
		stream.put_u8(int(part))
	stream.put_u16(game_port)
	stream.put_u16(discovery_port)
	stream.put_data(digest)
	stream.put_u8(occupancy)
	stream.put_u8(1 if lobby_open else 0)
	stream.put_u32(beacon_counter)
	stream.put_u16(3)
	var frame := NetworkFrame.encode(
		NetworkFrame.Family.BEACON, 0, beacon_counter, stream.data_array
	)
	if frame.size() <= NetworkFrame.MAX_DISCOVERY_BYTES:
		socket.set_dest_address(
			destination, discovery_port if destination_port < 0 else destination_port
		)
		if socket.put_packet(frame) == OK:
			last_sent_frame_bytes = frame.size()
			_last_beacon_msec = now


func _bound_query_sources(now: int) -> void:
	for source in _last_query_by_source.keys():
		if now - int(_last_query_by_source[source]) >= QUERY_SOURCE_TTL_MS:
			_last_query_by_source.erase(source)
	while _last_query_by_source.size() > MAX_QUERY_SOURCES:
		var oldest_source = null
		var oldest_time := 0
		for source in _last_query_by_source:
			var seen := int(_last_query_by_source[source])
			if oldest_source == null or seen < oldest_time:
				oldest_source = source
				oldest_time = seen
		_last_query_by_source.erase(oldest_source)


func _receive_query(frame: PackedByteArray, source: String, source_port: int) -> void:
	var decoded := NetworkFrame.decode(frame, -1, true)
	if not bool(decoded.ok) or int(decoded.family) != NetworkFrame.Family.DISCOVERY_QUERY:
		return
	var now := Time.get_ticks_msec()
	if now - int(_last_query_by_source.get(source, 0)) < 1000:
		return
	_last_query_by_source[source] = now
	_bound_query_sources(now)
	var payload: PackedByteArray = decoded.payload
	if payload.size() != 10:
		return
	var stream := StreamPeerBuffer.new()
	stream.big_endian = false
	stream.data_array = payload
	var requested_id := stream.get_u64()
	stream.get_u16()
	if requested_id == 0 or requested_id == lobby_id:
		_send_beacon(source, source_port)


func _receive_beacon(frame: PackedByteArray, source: String, source_port: int) -> void:
	var decoded := NetworkFrame.decode(frame, -1, true)
	if not bool(decoded.ok) or int(decoded.family) != NetworkFrame.Family.BEACON:
		return
	var payload: PackedByteArray = decoded.payload
	if payload.size() != 64:
		return
	var stream := StreamPeerBuffer.new()
	stream.big_endian = false
	stream.data_array = payload
	var id_value := stream.get_u64()
	var epoch := stream.get_u64()
	var advertised := (
		"%d.%d.%d.%d" % [stream.get_u8(), stream.get_u8(), stream.get_u8(), stream.get_u8()]
	)
	var game_port_value := stream.get_u16()
	var discovery_port_value := stream.get_u16()
	var advertised_digest: PackedByteArray = stream.get_data(32)[1]
	var seats := stream.get_u8()
	var open := stream.get_u8() == 1
	var counter := stream.get_u32()
	var expiry := stream.get_u16()
	if id_value == 0 or epoch == 0 or not _is_ipv4(advertised) or not _valid_port(game_port_value):
		return
	if not _valid_port(discovery_port_value) or seats > 4 or expiry == 0 or expiry > 3:
		return
	var key := "%d:%d" % [id_value, epoch]
	var previous: Dictionary = _entries.get(key, {})
	if not previous.is_empty() and counter <= int(previous.counter):
		return
	_entries[key] = {
		"lobby_id": id_value,
		"session_epoch": epoch,
		"address": advertised,
		"source_address": source,
		"source_port": source_port,
		"game_port": game_port_value,
		"discovery_port": discovery_port_value,
		"digest": advertised_digest,
		"occupancy": seats,
		"lobby_open": open,
		"counter": counter,
		"expires_at": Time.get_ticks_msec() + expiry * 1000,
	}
	while _entries.size() > MAX_ENTRIES:
		var oldest_key = _entries.keys()[0]
		var oldest_time := int(_entries[oldest_key].expires_at)
		for candidate in _entries:
			if int(_entries[candidate].expires_at) < oldest_time:
				oldest_key = candidate
				oldest_time = int(_entries[candidate].expires_at)
		_entries.erase(oldest_key)


func _expire_entries() -> void:
	var now := Time.get_ticks_msec()
	for key in _entries.keys():
		if now >= int(_entries[key].expires_at):
			_entries.erase(key)


func _valid_port(port: int) -> bool:
	return port >= 1024 and port <= 65535


func _is_ipv4(address: String) -> bool:
	var parts := address.split(".")
	if parts.size() != 4:
		return false
	for part in parts:
		if not part.is_valid_int() or int(part) < 0 or int(part) > 255:
			return false
	return not address.begins_with("127.") and address != "0.0.0.0" and address != "255.255.255.255"

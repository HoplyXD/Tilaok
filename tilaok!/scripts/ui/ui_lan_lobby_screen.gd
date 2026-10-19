class_name UiLanLobbyScreen
extends UiScreen

const QR_CODE_SCRIPT := preload("res://addons/qr_code/qr_code.gd")

var manager: NetworkSessionManager
var _root: VBoxContainer
var _status: Label
var _interfaces: OptionButton
var _game_port: SpinBox
var _discovery_port: SpinBox
var _code: LineEdit
var _address: LineEdit
var _port: SpinBox
var _lobby_id: LineEdit
var _pending: VBoxContainer
var _seats: VBoxContainer
var _discovered: VBoxContainer
var _invite_label: Label
var _qr: TextureRect
var _start_gate: Label
var _refresh_time := 0.0
var _last_qr_value := ""
var _client_notice := ""
var _host_only_controls: Array[Control] = []
var _client_only_controls: Array[Control] = []


func bind_session(session: NetworkSessionManager) -> void:
	manager = session
	if is_node_ready():
		_bind_signals()
		_refresh()


func _ready() -> void:
	super._ready()
	_build_ui()
	_bind_signals()
	_refresh()


func _process(delta: float) -> void:
	_refresh_time += delta
	if _refresh_time >= 0.5:
		_refresh_time = 0.0
		_refresh()


func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color("#10282b")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 28
	scroll.offset_top = 20
	scroll.offset_right = -28
	scroll.offset_bottom = -20
	add_child(scroll)
	_root = VBoxContainer.new()
	_root.custom_minimum_size.x = 900
	_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_root)
	var title := Label.new()
	title.text = "LAN Lobby"
	title.theme_type_variation = &"HeadingLabel"
	_root.add_child(title)
	_status = _label("Offline play remains available. No network session is open.")
	_root.add_child(_status)
	_root.add_child(HSeparator.new())
	var host_label := _label("Host on one usable IPv4 interface")
	_root.add_child(host_label)
	_host_only_controls.append(host_label)
	_interfaces = OptionButton.new()
	_root.add_child(_interfaces)
	_host_only_controls.append(_interfaces)
	var port_row := GridContainer.new()
	port_row.columns = 2
	_game_port = _port_spin(27777)
	_discovery_port = _port_spin(27778)
	var game_port_label := _label("Game port")
	game_port_label.custom_minimum_size.x = 140
	port_row.add_child(game_port_label)
	port_row.add_child(_game_port)
	var discovery_port_label := _label("Discovery port")
	discovery_port_label.custom_minimum_size.x = 140
	port_row.add_child(discovery_port_label)
	port_row.add_child(_discovery_port)
	_root.add_child(port_row)
	_host_only_controls.append(port_row)
	var host_row := HBoxContainer.new()
	var host_button := _button("Start spectator host")
	host_button.pressed.connect(_start_host)
	host_row.add_child(host_button)
	var stop_button := _button("Stop session")
	stop_button.pressed.connect(func() -> void: manager.stop_session())
	host_row.add_child(stop_button)
	_root.add_child(host_row)
	_host_only_controls.append(host_row)
	_invite_label = _label("Invitation: session is offline")
	_root.add_child(_invite_label)
	_host_only_controls.append(_invite_label)
	_qr = TextureRect.new()
	_qr.custom_minimum_size = Vector2(208, 208)
	_qr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_qr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_root.add_child(_qr)
	_host_only_controls.append(_qr)
	var invite_row := HBoxContainer.new()
	var refresh_button := _button("Refresh access code")
	refresh_button.pressed.connect(func() -> void: manager.refresh_invitation())
	invite_row.add_child(refresh_button)
	var copy_button := _button("Copy access code")
	copy_button.pressed.connect(
		func() -> void:
			if manager != null and not manager.invitation_code.is_empty():
				DisplayServer.clipboard_set(manager.invitation_code)
	)
	invite_row.add_child(copy_button)
	_root.add_child(invite_row)
	_host_only_controls.append(invite_row)
	var join_label := _label(
		"Join by manual address or Lobby ID. The access code is entered separately."
	)
	_root.add_child(join_label)
	_client_only_controls.append(join_label)
	var join_row := HBoxContainer.new()
	_address = LineEdit.new()
	_address.placeholder_text = "Host IPv4 or IPv6 address"
	_address.custom_minimum_size.x = 280
	join_row.add_child(_address)
	_port = _port_spin(27777)
	join_row.add_child(_port)
	_code = LineEdit.new()
	_code.placeholder_text = "26-character access code"
	_code.custom_minimum_size.x = 245
	join_row.add_child(_code)
	var join_button := _button("Connect")
	join_button.pressed.connect(_connect_manual)
	join_row.add_child(join_button)
	_root.add_child(join_row)
	_client_only_controls.append(join_row)
	var lookup_row := HBoxContainer.new()
	_lobby_id = LineEdit.new()
	_lobby_id.placeholder_text = "Lobby ID (13 characters)"
	lookup_row.add_child(_lobby_id)
	var lookup_button := _button("Search LAN")
	lookup_button.pressed.connect(_query_lobby)
	lookup_row.add_child(lookup_button)
	_root.add_child(lookup_row)
	_client_only_controls.append(lookup_row)
	_discovered = VBoxContainer.new()
	_root.add_child(_discovered)
	_root.add_child(HSeparator.new())
	var approval_label := _label("Pending host approvals")
	_root.add_child(approval_label)
	_host_only_controls.append(approval_label)
	_pending = VBoxContainer.new()
	_root.add_child(_pending)
	_host_only_controls.append(_pending)
	_root.add_child(_label("Seats · number / shape / color · readiness"))
	_seats = VBoxContainer.new()
	_root.add_child(_seats)
	var ready_row := HBoxContainer.new()
	var ready_button := _button("Toggle Ready")
	ready_button.pressed.connect(func() -> void: manager.set_client_ready(not manager.client_ready))
	ready_row.add_child(ready_button)
	_root.add_child(ready_row)
	_client_only_controls.append(ready_row)
	var admission_row := HBoxContainer.new()
	var close_admission_button := _button("Close admission")
	close_admission_button.pressed.connect(func() -> void: manager.close_admission())
	admission_row.add_child(close_admission_button)
	var open_admission_button := _button("Reopen admission")
	open_admission_button.pressed.connect(func() -> void: manager.open_admission())
	admission_row.add_child(open_admission_button)
	_root.add_child(admission_row)
	_host_only_controls.append(admission_row)
	_start_gate = _label("Network gameplay unavailable until a later phase.")
	_root.add_child(_start_gate)
	_host_only_controls.append(_start_gate)
	var back := _button("Back to title")
	back.pressed.connect(
		func() -> void:
			if manager != null and manager.state != NetworkSessionManager.SessionState.OFFLINE:
				manager.stop_session()
			back_requested.emit()
	)
	_root.add_child(back)
	_populate_interfaces()


func _bind_signals() -> void:
	if manager == null:
		return
	if not manager.lobby_changed.is_connected(_refresh):
		manager.lobby_changed.connect(_refresh)
	if not manager.state_changed.is_connected(_on_state_changed):
		manager.state_changed.connect(_on_state_changed)
	if not manager.client_message.is_connected(_on_client_message):
		manager.client_message.connect(_on_client_message)
	if not manager.session_error.is_connected(_on_client_message):
		manager.session_error.connect(_on_client_message)
	if not manager.approval_requested.is_connected(_on_approval):
		manager.approval_requested.connect(_on_approval)


func _populate_interfaces() -> void:
	if _interfaces == null or manager == null:
		return
	_interfaces.clear()
	var count := 0
	for info in manager.interface_options():
		for address in info.addresses:
			_interfaces.add_item("%s · %s" % [info.name, address])
			_interfaces.set_item_metadata(count, address)
			count += 1
		if info.addresses.is_empty():
			_interfaces.add_item("%s · %s (manual address only)" % [info.name, info.status])
			_interfaces.set_item_disabled(count, true)
			count += 1
	if count == 0:
		_interfaces.add_item("No usable IPv4 interface detected")
		_interfaces.set_item_disabled(0, true)


func _start_host() -> void:
	if manager == null or _interfaces.get_item_count() == 0:
		return
	var address := str(_interfaces.get_item_metadata(_interfaces.selected))
	manager.start_host(address, int(_game_port.value), int(_discovery_port.value))


func _connect_manual() -> void:
	if manager == null:
		return
	var accepted := manager.connect_client(
		_address.text.strip_edges(), int(_port.value), _code.text.strip_edges()
	)
	if accepted:
		_code.clear()
		_client_notice = "Connecting to the host."
		_refresh()


func _query_lobby() -> void:
	if manager == null:
		return
	if not manager.discovery.listening:
		manager.discovery.start_client(int(_discovery_port.value))
	var lobby := _decode_lobby_id(_lobby_id.text.strip_edges())
	manager.discovery.query(lobby)
	_refresh_discovered()


func _refresh() -> void:
	if manager == null or not is_node_ready():
		return
	var state_name: String = NetworkSessionManager.SessionState.keys()[manager.state]
	var show_client_join := not manager.client_mode or manager.client_assigned_seat < 0
	for control in _host_only_controls:
		control.visible = not manager.client_mode
	for control in _client_only_controls:
		control.visible = show_client_join
	var address_status := (
		manager.selected_address
		if not manager.selected_address.is_empty()
		else "no interface bound"
	)
	if not manager.selected_interface_usable:
		address_status += " · interface unavailable; discovery stopped"
	_status.text = (
		"Session: %s · %s · game %d · discovery %d · Lobby ID %s"
		% [
			state_name,
			address_status,
			manager.game_port,
			manager.discovery_port,
			_encode_lobby_id(manager.lobby_id) if manager.lobby_id > 0 else "—"
		]
	)
	if not _client_notice.is_empty():
		_status.text += "\n" + _client_notice
	_invite_label.text = (
		"Invitation: %s · expires in %s s"
		% [
			(
				manager.invitation_code
				if not manager.invitation_code.is_empty()
				else "revoked or unavailable"
			),
			(
				str(maxi(0, int((manager.invitation_expires_at - Time.get_ticks_msec()) / 1000)))
				if manager.invitation_expires_at > 0
				else "—"
			)
		]
	)
	_update_qr()
	_start_gate.text = manager.start_gate_status()
	_refresh_seats()
	_refresh_pending()
	_refresh_discovered()


func _refresh_seats() -> void:
	for child in _seats.get_children():
		child.queue_free()
	if manager.client_mode:
		_seats.add_child(
			_label(
				(
					(
						"Assigned player %d · %s"
						% [
							manager.client_assigned_seat + 1,
							"ready" if manager.client_ready else "not ready"
						]
					)
					if manager.client_assigned_seat >= 0
					else "No seat assigned"
				)
			)
		)
		return
	for index in PlayerSeatRegistry.MAX_SEATS:
		var seat := manager.router.registry.get_seat(index) if manager.router != null else {}
		var line := (
			"Seat %d · %s" % [index + 1, "open" if seat.is_empty() or not seat.joined else "taken"]
		)
		if not seat.is_empty() and seat.joined:
			line = (
				"Seat %d · %s · %s · %s"
				% [index + 1, seat.shape, seat.device_kind, "ready" if seat.ready else "not ready"]
			)
		_seats.add_child(_label(line))


func _update_qr() -> void:
	if _qr == null or manager == null:
		return
	if (
		manager.invitation_code.is_empty()
		or manager.lobby_id <= 0
		or manager.selected_address.is_empty()
	):
		if not _last_qr_value.is_empty():
			_qr.texture = null
			_last_qr_value = ""
		return
	var invite := (
		"tilaok://join?lobby=%s&host=%s&port=%d&protocol=%d.%d&digest=%s&code=%s"
		% [
			_encode_lobby_id(manager.lobby_id),
			manager.selected_address,
			manager.game_port,
			NetworkFrame.MAJOR,
			NetworkFrame.MINOR,
			manager.manifest_digest.hex_encode(),
			manager.invitation_code,
		]
	)
	if invite == _last_qr_value:
		return
	var qr = QR_CODE_SCRIPT.new()
	qr.put_byte(invite.to_utf8_buffer())
	qr.encode()
	var image: Image = qr.generate_image(4)
	_qr.texture = ImageTexture.create_from_image(image) if image != null else null
	_last_qr_value = invite


func _refresh_pending() -> void:
	for child in _pending.get_children():
		child.queue_free()
	if manager.client_mode:
		_pending.add_child(_label("Host approval happens on the host screen."))
		return
	var found := false
	for peer_id in manager.candidates:
		var candidate: Dictionary = manager.candidates[peer_id]
		if candidate.state != NetworkSessionManager.CandidateState.PENDING_APPROVAL:
			continue
		found = true
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(
			_label(
				(
					"Peer %d · compatible build %s"
					% [peer_id, str(candidate.compatibility.digest).substr(0, 12)]
				)
			)
		)
		var approve := _button("Approve")
		approve.pressed.connect(func() -> void: manager.approve_peer(int(peer_id)))
		row.add_child(approve)
		var reject := _button("Reject")
		reject.pressed.connect(func() -> void: manager.reject_peer(int(peer_id)))
		row.add_child(reject)
		_pending.add_child(row)
	if not found:
		_pending.add_child(_label("No pending approvals."))


func _refresh_discovered() -> void:
	if _discovered == null or manager == null:
		return
	for child in _discovered.get_children():
		child.queue_free()
	for entry in manager.discovery.discovered():
		var row := HBoxContainer.new()
		row.add_child(
			_label(
				(
					"Lobby %s · %s:%d · %d/4 seats"
					% [
						_encode_lobby_id(int(entry.lobby_id)),
						entry.address,
						entry.game_port,
						entry.occupancy
					]
				)
			)
		)
		var use := _button("Use address")
		use.pressed.connect(
			func() -> void:
				_address.text = str(entry.address)
				_port.value = int(entry.game_port)
				_lobby_id.text = _encode_lobby_id(int(entry.lobby_id))
		)
		row.add_child(use)
		_discovered.add_child(row)


func _on_approval(_peer_id: int, _compatibility: Dictionary) -> void:
	_refresh()


func _on_state_changed(_state: String) -> void:
	_refresh()


func _on_client_message(message: String) -> void:
	_client_notice = message
	_refresh()


func _button(caption: String) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size.y = 42
	return button


func _label(caption: String) -> Label:
	var label := Label.new()
	label.text = caption
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label


func _port_spin(value: int) -> SpinBox:
	var spin := SpinBox.new()
	spin.min_value = 1024
	spin.max_value = 65535
	spin.step = 1
	spin.value = value
	spin.custom_minimum_size.x = 150
	return spin


func _encode_lobby_id(value: int) -> String:
	if value <= 0:
		return ""
	const ALPHABET := "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
	var remaining := value
	var result := ""
	for _index in 13:
		result = ALPHABET[remaining & 31] + result
		remaining = remaining >> 5
	return result


func _decode_lobby_id(value: String) -> int:
	if value.length() != 13:
		return 0
	const ALPHABET := "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
	var result := 0
	for character in value.to_upper():
		var digit := ALPHABET.find(character)
		if digit < 0:
			return 0
		result = (result << 5) | digit
	return result

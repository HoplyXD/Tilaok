class_name UiLanLobbyScreen
extends UiScreen

const QR_CODE_SCRIPT := preload("res://addons/qr_code/qr_code.gd")

var manager: NetworkSessionManager
var client_only_mode := false
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
var _mobile_status: Label
var _ready_button: Button
var _ready_row: HBoxContainer
var _lookup_deadline := 0
var _selected_discovery_digest := PackedByteArray()


func bind_session(session: NetworkSessionManager) -> void:
	manager = session
	if is_node_ready():
		_bind_signals()
		_refresh()


func _ready() -> void:
	super._ready()
	_build_ui()
	_bind_signals()
	_bind_scanner()
	_refresh()
	set_process_unhandled_input(true)


func _exit_tree() -> void:
	_cancel_scanner()
	if manager != null and manager.state != NetworkSessionManager.SessionState.OFFLINE:
		manager.stop_session()


func _process(delta: float) -> void:
	_refresh_time += delta
	if _refresh_time >= 0.5:
		_refresh_time = 0.0
		if _lookup_deadline > 0:
			var target := _decode_lobby_id(_lobby_id.text.strip_edges().to_upper())
			if manager != null and not manager.discovery.get_lobby(target).is_empty():
				_lookup_deadline = 0
				_client_notice = "Lobby found. Enter its separate access code to continue."
			elif Time.get_ticks_msec() >= _lookup_deadline:
				_lookup_deadline = 0
				_client_notice = "No open lobby answered. Check the ID or use manual IP:port."
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
	_root.custom_minimum_size.x = 0 if client_only_mode else 900
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
	var join_label := _label("Join a nearby host. Your host will approve the request.")
	_root.add_child(join_label)
	_client_only_controls.append(join_label)
	var scan_button := _button("Scan host QR")
	scan_button.custom_minimum_size.y = 52
	scan_button.pressed.connect(_scan_qr)
	_root.add_child(scan_button)
	_client_only_controls.append(scan_button)
	var id_section := VBoxContainer.new()
	id_section.add_child(_label("Enter Lobby ID"))
	var lookup_row := HBoxContainer.new()
	lookup_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lobby_id = LineEdit.new()
	_lobby_id.placeholder_text = "13-character Lobby ID"
	_lobby_id.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lobby_id.text_changed.connect(func(_text: String) -> void: _selected_discovery_digest.clear())
	lookup_row.add_child(_lobby_id)
	var lookup_button := _button("Find")
	lookup_button.custom_minimum_size = Vector2(76, 44)
	lookup_button.pressed.connect(_query_lobby)
	lookup_row.add_child(lookup_button)
	id_section.add_child(lookup_row)
	_discovered = VBoxContainer.new()
	id_section.add_child(_discovered)
	_root.add_child(id_section)
	_client_only_controls.append(id_section)
	var manual_section := VBoxContainer.new()
	manual_section.add_child(_label("Manual IP:port"))
	var join_row := VBoxContainer.new()
	_address = LineEdit.new()
	_address.placeholder_text = "Host IPv4 or IPv6 address"
	_address.custom_minimum_size.y = 48
	join_row.add_child(_address)
	_port = _port_spin(27777)
	_port.custom_minimum_size.y = 44
	_code = LineEdit.new()
	_code.placeholder_text = "Separate 26-character access code"
	_code.custom_minimum_size.y = 48
	_code.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var access_row := HBoxContainer.new()
	access_row.add_child(_port)
	access_row.add_child(_code)
	join_row.add_child(access_row)
	var join_button := _button("Connect")
	join_button.custom_minimum_size.y = 52
	join_button.pressed.connect(_connect_manual)
	join_row.add_child(join_button)
	manual_section.add_child(join_row)
	_root.add_child(manual_section)
	_client_only_controls.append(manual_section)
	_mobile_status = _label("")
	_mobile_status.custom_minimum_size.y = 48
	_root.add_child(_mobile_status)
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
	_ready_row = HBoxContainer.new()
	_ready_button = _button("Set Ready")
	_ready_button.pressed.connect(
		func() -> void: manager.set_client_ready(not manager.client_ready)
	)
	_ready_row.add_child(_ready_button)
	_root.add_child(_ready_row)
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
	if client_only_mode:
		back.text = "Leave lobby"
	back.pressed.connect(_leave_lobby)
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
		_address.text.strip_edges(),
		int(_port.value),
		_code.text.strip_edges(),
		_selected_discovery_digest
	)
	_selected_discovery_digest.clear()
	if accepted:
		_code.clear()
		_client_notice = "Connecting to the host."
	else:
		_client_notice = "Check the host address, port and access code, then try again."
	_refresh()


func _scan_qr() -> void:
	if not Engine.has_singleton("TilaokQrScanner"):
		_client_notice = "QR scanner is not available. Enter the Lobby ID or host address below."
		_refresh()
		return
	var scanner: Object = Engine.get_singleton("TilaokQrScanner")
	if scanner.has_method("startScan"):
		scanner.startScan()
		_client_notice = "Point the camera at the host's Tilaok! QR code."
	else:
		_client_notice = "QR scanner could not start. Use Lobby ID or manual address."
	_refresh()
	if scanner.has_signal("qr_scanned") and not scanner.is_connected("qr_scanned", _on_qr_scanned):
		scanner.connect("qr_scanned", _on_qr_scanned)
	if (
		scanner.has_signal("scan_cancelled")
		and not scanner.is_connected("scan_cancelled", _on_scan_cancelled)
	):
		scanner.connect("scan_cancelled", _on_scan_cancelled)
	if (
		scanner.has_signal("scan_failed")
		and not scanner.is_connected("scan_failed", _on_scan_failed)
	):
		scanner.connect("scan_failed", _on_scan_failed)


func _leave_lobby() -> void:
	if manager != null and manager.state != NetworkSessionManager.SessionState.OFFLINE:
		manager.stop_session()
	if client_only_mode:
		if manager != null:
			manager.discovery.stop()
		_client_notice = "Left the lobby. Join again with a fresh host invitation."
		_refresh()
		return
	back_requested.emit()


func _bind_scanner() -> void:
	if not Engine.has_singleton("TilaokQrScanner"):
		return
	var scanner: Object = Engine.get_singleton("TilaokQrScanner")
	if scanner.has_signal("qr_scanned") and not scanner.is_connected("qr_scanned", _on_qr_scanned):
		scanner.connect("qr_scanned", _on_qr_scanned)
	if (
		scanner.has_signal("scan_cancelled")
		and not scanner.is_connected("scan_cancelled", _on_scan_cancelled)
	):
		scanner.connect("scan_cancelled", _on_scan_cancelled)
	if (
		scanner.has_signal("scan_failed")
		and not scanner.is_connected("scan_failed", _on_scan_failed)
	):
		scanner.connect("scan_failed", _on_scan_failed)


func _cancel_scanner() -> void:
	if Engine.has_singleton("TilaokQrScanner"):
		var scanner: Object = Engine.get_singleton("TilaokQrScanner")
		if scanner.has_method("cancelScan"):
			scanner.cancelScan()


func _on_qr_scanned(value: String) -> void:
	_cancel_scanner()
	if manager == null:
		return
	var parsed := InvitationUri.parse(value)
	if not bool(parsed.get("ok", false)):
		_client_notice = str(
			parsed.get("error", "The scanned code is not a valid Tilaok! invitation.")
		)
		_refresh()
		return
	var connected := manager.connect_client(
		str(parsed.address), int(parsed.port), str(parsed.code), parsed.digest, int(parsed.epoch)
	)
	_client_notice = (
		"Connecting to the host. The host still needs to approve you."
		if connected
		else "Could not start the connection. Check the invitation and try again."
	)
	_refresh()


func _on_scan_cancelled() -> void:
	_client_notice = "QR scan cancelled. You can enter the Lobby ID or host address instead."
	_refresh()


func _on_scan_failed(message: String) -> void:
	_client_notice = (
		message if not message.is_empty() else "Camera unavailable. Use Lobby ID or manual IP:port."
	)
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_cancel_scanner()
		_leave_lobby()
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		_cancel_scanner()


func _query_lobby() -> void:
	if manager == null:
		return
	var target_text := _lobby_id.text.strip_edges().to_upper()
	if target_text.length() != 13 or _decode_lobby_id(target_text) <= 0:
		_client_notice = "Enter a valid 13-character Lobby ID."
		_refresh()
		return
	if not manager.discovery.listening:
		manager.discovery.start_client(int(_discovery_port.value))
	var lobby := _decode_lobby_id(target_text)
	_selected_discovery_digest.clear()
	manager.discovery.query(lobby)
	_client_notice = "Searching this Wi-Fi network for lobby %s…" % target_text
	_lookup_deadline = Time.get_ticks_msec() + 3500
	_refresh_discovered()


func _refresh() -> void:
	if manager == null or not is_node_ready():
		return
	var state_name: String = NetworkSessionManager.SessionState.keys()[manager.state]
	var show_client_join := (
		client_only_mode or not manager.client_mode or manager.client_assigned_seat < 0
	)
	for control in _host_only_controls:
		control.visible = not client_only_mode and not manager.client_mode
	for control in _client_only_controls:
		control.visible = show_client_join
	if _mobile_status != null:
		_mobile_status.visible = client_only_mode or manager.client_mode
	if _ready_row != null:
		_ready_row.visible = manager.client_mode and manager.client_assigned_seat >= 0
		_ready_button.text = "Set Not Ready" if manager.client_ready else "Set Ready"
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
	if _mobile_status != null:
		_mobile_status.text = _client_status_text()
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
		if manager.client_assigned_seat >= 0:
			var assigned := manager.client_assigned_seat
			var badge := _label(
				(
					"Player %d · %s · %s"
					% [
						assigned + 1,
						PlayerSeatRegistry.SHAPES[assigned],
						"ready" if manager.client_ready else "not ready"
					]
				)
			)
			badge.add_theme_color_override("font_color", PlayerSeatRegistry.COLORS[assigned])
			_seats.add_child(badge)
		else:
			_seats.add_child(_label("Waiting for the host to assign a seat."))
		for seat_state in manager.client_lobby_seats:
			_seats.add_child(
				_label(
					(
						"Seat %d · %s · %s"
						% [
							int(seat_state.seat) + 1,
							str(seat_state.shape),
							"ready" if bool(seat_state.ready) else "not ready"
						]
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
		"tilaok://join?lobby=%s&host=%s&port=%d&protocol=%d.%d&digest=%s&code=%s&epoch=%d"
		% [
			_encode_lobby_id(manager.lobby_id),
			manager.selected_address,
			manager.game_port,
			NetworkFrame.MAJOR,
			NetworkFrame.MINOR,
			manager.manifest_digest.hex_encode(),
			manager.invitation_code,
			manager.session_epoch,
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
				_selected_discovery_digest = entry.digest.duplicate()
				_client_notice = "Lobby found. Enter its separate access code to continue."
				_refresh()
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
	if value.length() != 13 or value[0] > "B":
		return 0
	const ALPHABET := "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
	var result := 0
	for character in value.to_upper():
		var digit := ALPHABET.find(character)
		if digit < 0:
			return 0
		result = (result << 5) | digit
	return result


func _client_status_text() -> String:
	if manager == null:
		return ""
	if manager.client_mode and manager.client_assigned_seat >= 0:
		return (
			"Connected · ready %s · network gameplay is not available yet."
			% ("yes" if manager.client_ready else "no")
		)
	return "Phone lobby · same Wi-Fi · gameplay is unavailable in this phase."

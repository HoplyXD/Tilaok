class_name UiLanLobbyScreen
extends UiScreen

const QR_CODE_SCRIPT := preload("res://addons/qr_code/qr_code.gd")

var manager: NetworkSessionManager
var client_only_mode := false
var _root: VBoxContainer
var _status: Label
var _role_picker: HBoxContainer
var _role_back: Button
var _role_mode := "choose"
var _host_notice := ""
var _interfaces: OptionButton
var _game_port: SpinBox
var _discovery_port: SpinBox
var _code: LineEdit
var _address: LineEdit
var _port: SpinBox
var _lobby_id: LineEdit
var _lookup_target := 0
var _pending: VBoxContainer
var _seats: VBoxContainer
var _discovered: VBoxContainer
var _invite_label: Label
var _invite_actions: HBoxContainer
var _copy_code_button: Button
var _copy_lobby_id_button: Button
var _new_invitation_button: Button
var _scan_button: Button
var _manual_join_toggle: Button
var _manual_join_section: VBoxContainer
var _manual_join_expanded := false
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
	_role_mode = "join" if client_only_mode else "choose"
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
			var lobby := manager.discovery.get_lobby(_lookup_target) if manager != null else {}
			if not lobby.is_empty():
				_lookup_deadline = 0
				_lookup_target = 0
				if not bool(lobby.get("lobby_open", false)):
					manager.discovery.stop()
					_client_notice = "That room is closed. Ask the host to open a new room."
				else:
					var host_address := str(lobby.address)
					var host_port := int(lobby.game_port)
					var host_digest: PackedByteArray = lobby.digest.duplicate()
					var host_epoch := int(lobby.session_epoch)
					manager.discovery.stop()
					_client_notice = ""
					var accepted := manager.connect_client(
						host_address, host_port, _code.text.strip_edges(), host_digest, host_epoch
					)
					if accepted:
						_code.clear()
						_client_notice = "Room found. Connecting; the host must approve you."
					elif _client_notice.is_empty():
						_client_notice = "Couldn't connect. Check the access code and try again."
			elif Time.get_ticks_msec() >= _lookup_deadline:
				_lookup_deadline = 0
				_lookup_target = 0
				if manager != null:
					manager.discovery.stop()
				_client_notice = (
					"Couldn't find that room on this Wi-Fi. "
					+ "Check the Lobby ID or use the address option below."
				)
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
	_status = _label("Offline play is unchanged. Choose whether this computer will host or join.")
	_root.add_child(_status)
	_root.add_child(HSeparator.new())
	_role_picker = HBoxContainer.new()
	var host_choice := _button("Host a room")
	host_choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host_choice.pressed.connect(func() -> void: _select_role("host"))
	_role_picker.add_child(host_choice)
	var join_choice := _button("Join a room")
	join_choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	join_choice.pressed.connect(func() -> void: _select_role("join"))
	_role_picker.add_child(join_choice)
	_root.add_child(_role_picker)
	var quick_start := _label(
		(
			"Two-window laptop test\n"
			+ "1. Start a room using the same Wi-Fi as the other game window. Ignore WSL and Loopback.\n"
			+ "2. Share the Lobby ID and access code shown here. No IP address is needed.\n"
			+ "3. In the second game window, choose Join, enter the Lobby ID and access code, "
			+ "then select Find & request to join.\n"
			+ "4. Back here, approve the request. In the second window, choose Set Ready.\n"
			+ "The first window hosts as a spectator; the second gets the player seat. "
			+ "This tests the lobby only. Stop the room when finished."
		)
	)
	_root.add_child(quick_start)
	_host_only_controls.append(quick_start)
	var host_label := _label("Host · choose the Wi-Fi or Ethernet your other game window uses")
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
	var host_button := _button("Start room")
	host_button.pressed.connect(_start_host)
	host_row.add_child(host_button)
	var stop_button := _button("Stop room")
	stop_button.pressed.connect(func() -> void: manager.stop_session())
	host_row.add_child(stop_button)
	_root.add_child(host_row)
	_host_only_controls.append(host_row)
	_invite_label = _label("Room invitation: start a room to create an access code")
	_root.add_child(_invite_label)
	_host_only_controls.append(_invite_label)
	_qr = TextureRect.new()
	_qr.custom_minimum_size = Vector2(208, 208)
	_qr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_qr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_root.add_child(_qr)
	_host_only_controls.append(_qr)
	_invite_actions = HBoxContainer.new()
	_copy_lobby_id_button = _button("Copy Lobby ID")
	_copy_lobby_id_button.pressed.connect(
		func() -> void:
			if manager != null and manager.lobby_id > 0:
				DisplayServer.clipboard_set(_encode_lobby_id(manager.lobby_id))
	)
	_invite_actions.add_child(_copy_lobby_id_button)
	_copy_code_button = _button("Copy access code")
	_copy_code_button.pressed.connect(
		func() -> void:
			if manager != null and not manager.invitation_code.is_empty():
				DisplayServer.clipboard_set(manager.invitation_code)
	)
	_invite_actions.add_child(_copy_code_button)
	_new_invitation_button = _button("Create fresh access code")
	_new_invitation_button.pressed.connect(_create_fresh_invitation)
	_invite_actions.add_child(_new_invitation_button)
	_root.add_child(_invite_actions)
	_host_only_controls.append(_invite_actions)
	var join_label := _label(
		(
			"Join with the Lobby ID and separate access code. The game finds the host on your Wi-Fi; "
			+ "the host must approve your request."
		)
	)
	_root.add_child(join_label)
	_client_only_controls.append(join_label)
	_scan_button = _button("Scan host QR")
	_scan_button.custom_minimum_size.y = 52
	_scan_button.pressed.connect(_scan_qr)
	_root.add_child(_scan_button)
	_client_only_controls.append(_scan_button)
	var id_section := VBoxContainer.new()
	id_section.add_child(_label("Enter Lobby ID"))
	_lobby_id = LineEdit.new()
	_lobby_id.placeholder_text = "13-character Lobby ID"
	_lobby_id.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lobby_id.text_changed.connect(
		func(_text: String) -> void:
			_selected_discovery_digest.clear()
			_lookup_target = 0
	)
	id_section.add_child(_lobby_id)
	_code = LineEdit.new()
	_code.placeholder_text = "Access code from the host"
	_code.custom_minimum_size.y = 48
	_code.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	id_section.add_child(_code)
	var lookup_button := _button("Find & request to join")
	lookup_button.custom_minimum_size.y = 52
	lookup_button.pressed.connect(_query_lobby)
	id_section.add_child(lookup_button)
	_discovered = VBoxContainer.new()
	id_section.add_child(_discovered)
	_root.add_child(id_section)
	_client_only_controls.append(id_section)
	_manual_join_section = VBoxContainer.new()
	_manual_join_section.add_child(_label("Connect using host address"))
	var join_row := VBoxContainer.new()
	_address = LineEdit.new()
	_address.placeholder_text = "Host IP address"
	_address.custom_minimum_size.y = 48
	join_row.add_child(_address)
	_port = _port_spin(27777)
	_port.custom_minimum_size.y = 44
	join_row.add_child(_port)
	var join_button := _button("Request to join by address")
	join_button.custom_minimum_size.y = 52
	join_button.pressed.connect(_connect_manual)
	join_row.add_child(join_button)
	_manual_join_section.add_child(join_row)
	_manual_join_toggle = _button("Can't find room? Use host address")
	_manual_join_toggle.pressed.connect(
		func() -> void:
			_manual_join_expanded = not _manual_join_expanded
			_manual_join_section.visible = _manual_join_expanded
			_manual_join_toggle.text = (
				"Hide address options"
				if _manual_join_expanded
				else "Can't find room? Use host address"
			)
	)
	_root.add_child(_manual_join_toggle)
	_client_only_controls.append(_manual_join_toggle)
	_root.add_child(_manual_join_section)
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
	var seats_label := _label("Players in this room · seat, shape, color and ready status")
	_root.add_child(seats_label)
	_host_only_controls.append(seats_label)
	_seats = VBoxContainer.new()
	_root.add_child(_seats)
	_host_only_controls.append(_seats)
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
	_role_back = _button("Back to Host / Join")
	_role_back.pressed.connect(_show_role_choices)
	_root.add_child(_role_back)
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
	if not manager.session_error.is_connected(_on_session_error):
		manager.session_error.connect(_on_session_error)
	if not manager.approval_requested.is_connected(_on_approval):
		manager.approval_requested.connect(_on_approval)


func _populate_interfaces() -> void:
	if _interfaces == null or manager == null:
		return
	_interfaces.clear()
	var count := 0
	var preferred_wifi := -1
	var preferred_ethernet := -1
	for info in manager.interface_options():
		for address in info.addresses:
			_interfaces.add_item("%s · %s" % [info.name, address])
			_interfaces.set_item_metadata(count, address)
			var interface_name := str(info.name).to_lower()
			if not interface_name.contains("wsl") and not interface_name.contains("virtual"):
				if interface_name.contains("wi-fi") or interface_name.contains("wifi"):
					if preferred_wifi < 0:
						preferred_wifi = count
				elif interface_name.contains("ethernet") and preferred_ethernet < 0:
					preferred_ethernet = count
			count += 1
		if info.addresses.is_empty():
			_interfaces.add_item("%s · %s (manual address only)" % [info.name, info.status])
			_interfaces.set_item_disabled(count, true)
			count += 1
	if count == 0:
		_interfaces.add_item("No usable IPv4 interface detected")
		_interfaces.set_item_disabled(0, true)
	elif preferred_wifi >= 0:
		_interfaces.select(preferred_wifi)
	elif preferred_ethernet >= 0:
		_interfaces.select(preferred_ethernet)


func _select_role(role: String) -> void:
	if role not in ["host", "join"]:
		return
	_role_mode = role
	_host_notice = ""
	_client_notice = ""
	_refresh()


func _show_role_choices() -> void:
	if manager != null and manager.state != NetworkSessionManager.SessionState.OFFLINE:
		return
	_role_mode = "choose"
	_host_notice = ""
	_client_notice = ""
	_refresh()


func _start_host() -> void:
	if manager == null or _interfaces.get_item_count() == 0:
		return
	var address := str(_interfaces.get_item_metadata(_interfaces.selected))
	manager.start_host(address, int(_game_port.value), int(_discovery_port.value))


func _connect_manual() -> void:
	if manager == null:
		return
	_client_notice = ""
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
	elif _client_notice.is_empty():
		_client_notice = "Check the host address, port and access code, then try again."
	_refresh()


func _scan_qr() -> void:
	if not Engine.has_singleton("TilaokQrScanner"):
		_client_notice = "QR scanning isn't available here. Enter the Lobby ID and access code below."
		_refresh()
		return
	var scanner: Object = Engine.get_singleton("TilaokQrScanner")
	_bind_scanner()
	# Android plugin functions are exposed by JNISingleton, not Object.has_method().
	# Query the Java bridge API before calling the exact annotated Kotlin method name.
	if not bool(scanner.call("has_java_method", "startScan")):
		_client_notice = (
			"QR scanning isn't available in this Android build. "
			+ "Use Lobby ID or manual address."
		)
		_refresh()
		return
	_client_notice = "Opening the camera. Allow camera access when Android asks."
	_refresh()
	scanner.call("startScan")


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
	_client_notice = "QR scan cancelled. Enter the Lobby ID and access code instead."
	_refresh()


func _on_scan_failed(message: String) -> void:
	match message:
		"camera_permission_denied":
			_client_notice = (
				"Camera permission was denied.\nAllow it when asked, "
				+ "or use Lobby ID/manual address."
			)
		"camera_permission_permanently_denied":
			_client_notice = (
				"Camera permission is off in Android Settings. Allow Camera for Tilaok!, "
				+ "or use Lobby ID/manual address."
			)
		"camera_unavailable", "camera_ui_unavailable":
			_client_notice = "Camera is unavailable right now. Use Lobby ID or manual IP:port."
		_:
			_client_notice = "Camera unavailable. Use Lobby ID or manual IP:port."
	_refresh()


func _create_fresh_invitation() -> void:
	if manager == null or not manager.create_invitation():
		_host_notice = "Could not create an access code. Check that the room is open."
	else:
		_host_notice = "Fresh one-use code created. Share it only with the next player."
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
	_client_notice = ""
	var target_text := _lobby_id.text.strip_edges().to_upper()
	if target_text.length() != 13 or _decode_lobby_id(target_text) <= 0:
		_client_notice = "Enter a valid 13-character Lobby ID."
		_refresh()
		return
	if _code.text.strip_edges().is_empty():
		_client_notice = "Enter the access code shared by the host."
		_refresh()
		return
	manager.discovery.stop()
	var start_error := manager.discovery.start_client(NetworkSessionManager.DEFAULT_DISCOVERY_PORT)
	if start_error != OK:
		_client_notice = "Room search couldn't start. Use the host address option below."
		_refresh()
		return
	_lookup_target = _decode_lobby_id(target_text)
	_selected_discovery_digest.clear()
	var query_error := manager.discovery.query(_lookup_target)
	if query_error != OK:
		_lookup_target = 0
		_client_notice = "Room search couldn't start. Use the host address option below."
		_refresh()
		return
	_client_notice = "Searching this Wi-Fi for your room…"
	_lookup_deadline = Time.get_ticks_msec() + 3500
	_refresh()
	_refresh_discovered()


func _refresh() -> void:
	if manager == null or not is_node_ready():
		return
	var host_view := not client_only_mode and _role_mode == "host" and not manager.client_mode
	var join_view := client_only_mode or _role_mode == "join" or manager.client_mode
	var show_client_join := join_view and not manager.client_mode
	_role_picker.visible = not client_only_mode and _role_mode == "choose"
	_role_back.visible = (
		not client_only_mode
		and _role_mode != "choose"
		and manager.state == NetworkSessionManager.SessionState.OFFLINE
	)
	for control in _host_only_controls:
		control.visible = host_view
	for control in _client_only_controls:
		control.visible = show_client_join
	_scan_button.visible = client_only_mode and show_client_join
	_manual_join_section.visible = show_client_join and _manual_join_expanded
	if _mobile_status != null:
		_mobile_status.visible = join_view
	if _ready_row != null:
		_ready_row.visible = join_view and manager.client_mode and manager.client_assigned_seat >= 0
		_ready_button.text = "Set Not Ready" if manager.client_ready else "Set Ready"
	if _role_mode == "choose" and not client_only_mode:
		_status.text = "Offline play is unchanged. Choose whether this computer will host or join."
	elif host_view:
		if manager.state == NetworkSessionManager.SessionState.OFFLINE:
			_status.text = "Choose the Wi-Fi or Ethernet used by both game windows, then select Start room."
		elif manager.state == NetworkSessionManager.SessionState.STARTING:
			_status.text = "Starting your room…"
		elif manager.state == NetworkSessionManager.SessionState.STOPPING:
			_status.text = "Closing your room…"
		else:
			var address_status := (
				manager.selected_address
				if not manager.selected_address.is_empty()
				else "no interface bound"
			)
			if not manager.selected_interface_usable:
				address_status += " · interface unavailable"
			_status.text = (
				"Room is open · Address: %s · Game port: %d · Lobby ID: %s"
				% [
					address_status,
					manager.game_port,
					_encode_lobby_id(manager.lobby_id) if manager.lobby_id > 0 else "—"
				]
			)
		if not _host_notice.is_empty():
			_status.text += "\n" + _host_notice
	else:
		_status.text = "Enter the room's Lobby ID and access code below."
	if _mobile_status != null:
		_mobile_status.text = _client_status_text()
		if not _client_notice.is_empty():
			_mobile_status.text += "\n" + _client_notice
	var has_invitation := not manager.invitation_code.is_empty()
	if has_invitation:
		_invite_label.text = (
			"One-use access code: %s · valid for 5 minutes or until its first valid proof"
			% manager.invitation_code
		)
	elif manager.state == NetworkSessionManager.SessionState.OFFLINE:
		_invite_label.text = "Start a room to create an access code."
	elif manager.state == NetworkSessionManager.SessionState.STARTING:
		_invite_label.text = "Creating access code…"
	else:
		_invite_label.text = (
			"Previous access code expired or was used. "
			+ "Create a fresh code for the next player."
		)
	_invite_actions.visible = (
		host_view and manager.state == NetworkSessionManager.SessionState.LOBBY_OPEN
	)
	_copy_code_button.disabled = not has_invitation
	_copy_lobby_id_button.disabled = manager.lobby_id <= 0
	_qr.visible = host_view and has_invitation and not manager.selected_address.is_empty()
	_update_qr()
	_start_gate.text = (
		"Network matches are not available yet."
		if manager.state != NetworkSessionManager.SessionState.LOBBY_OPEN
		else "Network matches are disabled. Lobby check: " + manager.start_gate_status()
	)
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
		"tilaok://join?lobby=%s&host=%s&port=%d&protocol=%d.%d&digest=%s&code=%s&epoch=%d&expires=%d"
		% [
			_encode_lobby_id(manager.lobby_id),
			manager.selected_address,
			manager.game_port,
			NetworkFrame.MAJOR,
			NetworkFrame.MINOR,
			manager.manifest_digest.hex_encode(),
			manager.invitation_code,
			manager.session_epoch,
			manager.invitation_expires_unix,
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
		row.add_child(_label("A compatible player is asking to join this room."))
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
	if _lookup_target > 0:
		_discovered.add_child(_label("Searching nearby Wi-Fi for that Lobby ID…"))


func _on_approval(_peer_id: int, _compatibility: Dictionary) -> void:
	_refresh()


func _on_state_changed(_state: String) -> void:
	_refresh()


func _on_client_message(message: String) -> void:
	_client_notice = _friendly_error(message)
	_refresh()


func _on_session_error(message: String) -> void:
	if client_only_mode or manager.client_mode or _role_mode == "join":
		_client_notice = _friendly_error(message)
	else:
		_host_notice = _friendly_error(message)
	_refresh()


func _friendly_error(message: String) -> String:
	var prefix_replacements := {
		"Could not connect to the host":
		"Couldn't reach the host. Check the host address, game port, and that their room is open.",
		"Could not bind the game port":
		"That game port is busy. Close the other room or choose a different port.",
		"Could not bind the discovery port":
		"Lobby search couldn't start. You can still join using the host address option."
	}
	for prefix in prefix_replacements:
		if message.begins_with(prefix):
			return str(prefix_replacements[prefix])
	var exact_replacements := {
		"This invitation belongs to an older host session.":
		"This invite is out of date. Ask the host to create a fresh access code.",
		"The host session changed during connection.":
		"This invite is out of date. Ask the host to create a fresh access code.",
		"This client does not match the host build.":
		"This game copy doesn't match the host. Update both copies and try again.",
		"This client is not compatible with the host.":
		"This game copy doesn't match the host. Update both copies and try again.",
		"The host is reviewing the maximum number of players.":
		"The host is handling other join requests. Try again in a moment."
	}
	return str(exact_replacements.get(message, message))


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
			"Connected as Player %d · %s. Network gameplay is not available yet."
			% [manager.client_assigned_seat + 1, "Ready" if manager.client_ready else "Not ready"]
		)
	if manager.client_mode:
		return "Connected to the room. Waiting for host approval."
	return "Enter the room details, then select Request to join."

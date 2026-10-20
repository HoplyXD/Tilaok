class_name NetworkMatchPresentation
extends Control

## Read-only client canvas. It consumes detached codec records and never creates gameplay nodes,
## collision shapes, hazards, score logic, or simulation clocks.

var network_session: NetworkSessionManager
var _state: Dictionary = {}
var _seat_buffer: Dictionary = {}
var _last_drawn_ms := 0
var _received_at_ms := 0
var _last_snapshot_id := -1
var _last_phase := -1
var _layout: ArenaLayout
var _status_label: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	_status_label = Label.new()
	_status_label.position = Vector2(24, 18)
	_status_label.add_theme_font_size_override("font_size", 22)
	add_child(_status_label)
	if OS.has_feature("android"):
		_build_phone_controls()


func bind_session(session: NetworkSessionManager) -> void:
	network_session = session
	if session != null and not session.match_state_received.is_connected(apply_state):
		session.match_state_received.connect(apply_state)
	if session != null and not session.client_replica_state.is_empty():
		apply_state(session.client_replica_state)


func _exit_tree() -> void:
	if network_session != null and is_instance_valid(network_session):
		if network_session.match_state_received.is_connected(apply_state):
			network_session.match_state_received.disconnect(apply_state)
		if OS.has_feature("android"):
			network_session.client_set_continuous_input([0, 0])
			for action_id in [0, 1, 2, 3, 4, 9, 10, 11]:
				network_session.client_set_action(action_id, false)


func apply_state(state: Dictionary) -> void:
	# Copy only the whitelisted primitive fields and codec-produced records.
	var next_metadata: Dictionary = state.get("metadata", {})
	var next_snapshot_id := int(state.get("snapshot_id", -1))
	var next_phase := int(next_metadata.get("phase", -1))
	if next_snapshot_id != _last_snapshot_id or next_phase != _last_phase:
		_seat_buffer.clear()
	_last_snapshot_id = next_snapshot_id
	_last_phase = next_phase
	_state = state.duplicate(true)
	var map_id := str(next_metadata.get("map_id", MapCatalog.DEFAULT_ID))
	if not MapCatalog.ids().has(map_id):
		map_id = MapCatalog.DEFAULT_ID
	_layout = MapCatalog.layout_for(map_id)
	var now := Time.get_ticks_msec()
	_received_at_ms = now
	for seat_id in _state.get("seats", {}).keys():
		var seat: Dictionary = _state.seats[seat_id]
		var buffer: Array = _seat_buffer.get(seat_id, [])
		if not buffer.is_empty() and (
			int(buffer.back().status) != int(seat.status)
			or buffer.back().position.distance_to(seat.position) > 300.0
		):
			buffer.clear()
		buffer.append({"time": now, "position": seat.position, "status": seat.status})
		while buffer.size() > 3:
			buffer.pop_front()
		_seat_buffer[seat_id] = buffer
	_last_drawn_ms = now
	_status_label.text = _host_status_text()
	queue_redraw()


func _host_status_text() -> String:
	var metadata: Dictionary = _state.get("metadata", {})
	var phase := int(metadata.get("phase", 0))
	var phase_name := ["Lobby", "Pugad", "Place", "Play", "Results", "Pause", "Results", "Go"]
	var remaining_ms := int(metadata.get("remaining_ms", 0))
	if not bool(metadata.get("paused", false)) and _received_at_ms > 0:
		remaining_ms -= Time.get_ticks_msec() - _received_at_ms
	var remaining := maxf(0.0, float(remaining_ms) / 1000.0)
	var round_number := int(metadata.get("round_id", 0))
	var event_names := ["Karera", "Lagsanay", "Kangaroo"]
	var event_id := int(metadata.get("event_main", 255))
	var event_text := ""
	if event_id >= 0 and event_id < event_names.size():
		event_text = "  ·  " + event_names[event_id]
	var barya_state := int(metadata.get("barya_state", 0))
	if barya_state in [BaryaRoundObjective.State.AVAILABLE, BaryaRoundObjective.State.CARRIED, BaryaRoundObjective.State.SECURED]:
		event_text += "  ·  Barya"
	var event_context: Dictionary = _state.get("event_context", {})
	var event_clock_ms := int(event_context.get("event_clock_ms", 0))
	if event_clock_ms > 0:
		event_text += "  ·  %.1fs" % (float(event_clock_ms) / 1000.0)
	return "Tilaok!  ·  %s%s  ·  Round %d  ·  %.1fs" % [phase_name[mini(phase, phase_name.size() - 1)], event_text, round_number, remaining]


func _draw() -> void:
	var size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, size), Color("#263b46"), true)
	draw_rect(Rect2(Vector2(0, size.y * 0.67), Vector2(size.x, size.y * 0.33)), Color("#517052"), true)
	var seats: Dictionary = _state.get("seats", {})
	var metadata: Dictionary = _state.get("metadata", {})
	var center: Vector2 = metadata.get("camera_position", Vector2(1024, 540))
	var scale_factor := minf(size.x / 1152.0, size.y / 648.0) * float(metadata.get("camera_zoom", 1.0))
	var origin := size * 0.5 - center * scale_factor
	# Static map geometry comes from the compatible local map catalog; it is draw-only on clients.
	if _layout != null:
		for surface in _layout.surfaces:
			var rect: Rect2 = surface.rect_tiles
			var world_rect := Rect2(Vector2(rect.position.x * 64.0, rect.position.y * 64.0), Vector2(rect.size.x * 64.0, rect.size.y * 64.0))
			var surface_color := Color("#aa8554") if str(surface.surface_id) == "arena.floor" else Color("#836947")
			draw_rect(Rect2(origin + world_rect.position * scale_factor, world_rect.size * scale_factor), surface_color, true)
	var entities: Dictionary = _state.get("entities", {})
	for entity in entities.values():
		if not entity.has("variant_key"):
			continue
		var point: Vector2 = origin + entity.position * scale_factor
		var tint := Color("#d8bb82")
		if str(entity.variant_key).contains("bamboo"):
			tint = Color("#78a96b")
		elif str(entity.variant_key).contains("tire"):
			tint = Color("#52616b")
		elif str(entity.variant_key).contains("collapsing"):
			tint = Color("#c89955")
		if (int(entity.get("state_flags", 0)) & 6) == (StageBlock.CollapseState.GONE << 1):
			tint = Color("#777c78")
		draw_rect(Rect2(point - Vector2(48, 12) * scale_factor, Vector2(96, 24) * scale_factor), tint, true)
	for seat_id in seats.keys():
		var seat: Dictionary = seats[seat_id]
		var point := origin + _interpolated_position(int(seat_id), seat.position) * scale_factor
		var colors := [Color("#f2c14e"), Color("#63a7ff"), Color("#f07c6c"), Color("#89c77b")]
		var color: Color = colors[mini(int(seat_id), colors.size() - 1)]
		if int(seat.status) >= PlayerLifecycleState.Status.ELIMINATED:
			color = Color("#70777a")
		draw_circle(point, 20.0 * scale_factor, color)
		draw_arc(point, 22.0 * scale_factor, 0.0, TAU, 24, Color.WHITE, 3.0 * scale_factor)
		draw_string(ThemeDB.fallback_font, point + Vector2(-7, 6) * scale_factor, str(int(seat.identity)), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#16232a"))
		var event_context: Dictionary = _state.get("event_context", {})
		if int(event_context.get("taya_seat", -1)) == int(seat_id):
			draw_string(ThemeDB.fallback_font, point + Vector2(-22, -30) * scale_factor, "TAYA", HORIZONTAL_ALIGNMENT_LEFT, 60, 12, Color("#fff1a6"))
	var objective: Dictionary = _state.get("objective", {})
	if not objective.is_empty() and int(objective.get("state", BaryaRoundObjective.State.REMOVED)) in [BaryaRoundObjective.State.AVAILABLE, BaryaRoundObjective.State.CARRIED]:
		var coin_point: Vector2 = origin + objective.position * scale_factor
		draw_circle(coin_point, 11.0 * scale_factor, Color("#f4d05c"))
		draw_arc(coin_point, 14.0 * scale_factor, 0.0, TAU, 20, Color("#fff4b8"), 3.0 * scale_factor)
	_draw_score_rows(size, seats)


func _interpolated_position(seat_id: int, fallback: Vector2) -> Vector2:
	var buffer: Array = _seat_buffer.get(seat_id, [])
	if buffer.size() < 2:
		return fallback
	var older: Dictionary = buffer[buffer.size() - 2]
	var newer: Dictionary = buffer[buffer.size() - 1]
	if int(older.status) != int(newer.status):
		return newer.position
	var elapsed := clampf(float(Time.get_ticks_msec() - int(older.time)) / maxf(1.0, float(int(newer.time) - int(older.time))), 0.0, 1.0)
	return older.position.lerp(newer.position, elapsed)


func _draw_score_rows(size: Vector2, seats: Dictionary) -> void:
	var index := 0
	for seat_id in seats.keys():
		var seat: Dictionary = seats[seat_id]
		var points := float(int(seat.get("score_units", 0))) / 100.0
		draw_string(ThemeDB.fallback_font, Vector2(size.x - 190, 42 + index * 26), "P%d  %.2f" % [int(seat.identity), points], HORIZONTAL_ALIGNMENT_LEFT, 170, 18, Color.WHITE)
		index += 1


func _build_phone_controls() -> void:
	var panel := HBoxContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_top = -88
	panel.offset_bottom = -8
	panel.add_theme_constant_override("separation", 5)
	add_child(panel)
	var left := _touch_button("◀", 56)
	left.button_down.connect(func() -> void: _set_horizontal(-1000); _send_action(7, true))
	left.button_up.connect(func() -> void: _set_horizontal(0); _send_action(7, false))
	panel.add_child(left)
	var right := _touch_button("▶", 56)
	right.button_down.connect(func() -> void: _set_horizontal(1000); _send_action(8, true))
	right.button_up.connect(func() -> void: _set_horizontal(0); _send_action(8, false))
	panel.add_child(right)
	var up := _touch_button("▲", 52)
	up.button_down.connect(func() -> void: _send_action(9, true))
	up.button_up.connect(func() -> void: _send_action(9, false))
	panel.add_child(up)
	var down := _touch_button("▼", 52)
	down.button_down.connect(func() -> void: _send_action(10, true))
	down.button_up.connect(func() -> void: _send_action(10, false))
	panel.add_child(down)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(spacer)
	var choose := _touch_button("Claim / OK", 88)
	choose.pressed.connect(_choose_action)
	panel.add_child(choose)
	var rotate := _touch_button("Turn", 56)
	rotate.pressed.connect(func() -> void: _send_action(3, true); _send_action(3, false))
	panel.add_child(rotate)
	var jump := _touch_button("Jump", 64)
	jump.button_down.connect(func() -> void: _send_action(0, true))
	jump.button_up.connect(func() -> void: _send_action(0, false))
	panel.add_child(jump)
	var sneak := _touch_button("Sneak", 70)
	sneak.button_down.connect(func() -> void: _send_action(11, true))
	sneak.button_up.connect(func() -> void: _send_action(11, false))
	panel.add_child(sneak)
	var back := _touch_button("Cancel / Back", 84)
	back.pressed.connect(func() -> void: _send_action(2, true); _send_action(2, false))
	panel.add_child(back)


func _touch_button(label: String, width: float) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(width, 72)
	button.add_theme_font_size_override("font_size", 17)
	button.focus_mode = Control.FOCUS_NONE
	return button


func _set_horizontal(value: int) -> void:
	if network_session == null:
		return
	network_session.client_set_continuous_input([value, 0])


func _send_action(action_id: int, pressed: bool) -> void:
	if network_session != null:
		network_session.client_set_action(action_id, pressed)


func _choose_action() -> void:
	var metadata: Dictionary = _state.get("metadata", {})
	var phase := int(metadata.get("phase", 0))
	var action_id := 4 if phase == MatchPhaseController.Phase.PUGAD else 1
	_send_action(action_id, true)
	_send_action(action_id, false)

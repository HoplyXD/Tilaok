class_name NetworkMatchPresentation
extends Control

## Read-only client canvas. It consumes detached codec records and never creates gameplay nodes,
## collision shapes, hazards, score logic, or simulation clocks. On the opt-in live-build route it
## also draws a tentative ghost (NetworkLivePlacementClient) that is never shown as committed.

## NLB-P09: the session is over and the player asked to leave the dead match view.
signal session_end_dismissed

const GRID_CELL_WU := 64.0
## Indexed by MatchPhaseController.Phase (LOBBY, PUGAD, PLACE, PLAY, RESULTS, GO).
const PHASE_NAMES := ["Lobby", "Pugad", "Place", "Play", "Results", "Go"]
const LIVE_BUTTON_SIZE := 72.0

## Lets a desktop test or capture show the touch controls; Android always builds them.
var touch_controls_forced := false
var network_session: NetworkSessionManager
var live_client := NetworkLivePlacementClient.new()
var _state: Dictionary = {}
var _seat_buffer: Dictionary = {}
var _last_drawn_ms := 0
var _received_at_ms := 0
var _last_snapshot_id := -1
var _last_phase := -1
var _layout: ArenaLayout
var _status_label: Label
var _results_overlay: NetworkResultsOverlay
var _phone_panel: HBoxContainer
var _phone_controls_built := false
var _live_controls: GridContainer
var _live_buttons: Dictionary = {}
var _axis_x := 0
## NLB-P08: a local menu opened by the client's pause button. It never pauses the match.
var _local_overlay := false
var _catalog: ItemDefinitions
var _footprints: Dictionary = {}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	_status_label = Label.new()
	_status_label.position = Vector2(24, 18)
	_status_label.add_theme_font_size_override("font_size", 22)
	add_child(_status_label)
	if _touch_enabled():
		_build_phone_controls()
	# Added last so it draws above the match view and the touch row.
	_results_overlay = NetworkResultsOverlay.new()
	_results_overlay.name = "NetworkResultsOverlay"
	_results_overlay.dismissed.connect(func() -> void: session_end_dismissed.emit())
	add_child(_results_overlay)
	if network_session != null:
		_results_overlay.bind(network_session)


func bind_session(session: NetworkSessionManager) -> void:
	network_session = session
	if _results_overlay != null:
		_results_overlay.bind(session)
	if session != null and not session.results_changed.is_connected(_on_results_changed):
		session.results_changed.connect(_on_results_changed)
	if session != null and not session.match_state_received.is_connected(apply_state):
		session.match_state_received.connect(apply_state)
	if session != null and not session.terrain_resync_changed.is_connected(_on_terrain_resync):
		session.terrain_resync_changed.connect(_on_terrain_resync)
	if session != null and not session.pause_state_changed.is_connected(_on_host_pause_changed):
		session.pause_state_changed.connect(_on_host_pause_changed)
	if (
		session != null
		and session.router != null
		and not session.router.action_pressed.is_connected(_on_router_action)
	):
		session.router.action_pressed.connect(_on_router_action)
	live_client.bind(session)
	if session != null and session.client_route == NetworkSessionManager.ROUTE_LIVE_BUILD and _touch_enabled():
		_build_live_controls()
	if session != null and not session.client_replica_state.is_empty():
		apply_state(session.client_replica_state)


func _exit_tree() -> void:
	live_client.unbind()
	if network_session != null and is_instance_valid(network_session):
		if network_session.results_changed.is_connected(_on_results_changed):
			network_session.results_changed.disconnect(_on_results_changed)
		if network_session.match_state_received.is_connected(apply_state):
			network_session.match_state_received.disconnect(apply_state)
		if network_session.terrain_resync_changed.is_connected(_on_terrain_resync):
			network_session.terrain_resync_changed.disconnect(_on_terrain_resync)
		if network_session.pause_state_changed.is_connected(_on_host_pause_changed):
			network_session.pause_state_changed.disconnect(_on_host_pause_changed)
		if (
			network_session.router != null
			and network_session.router.action_pressed.is_connected(_on_router_action)
		):
			network_session.router.action_pressed.disconnect(_on_router_action)
		if _touch_enabled():
			network_session.client_set_continuous_input([0, 0])
			for action_id in [0, 1, 2, 3, 4, 9, 10, 11]:
				network_session.client_set_action(action_id, false)


func _process(delta: float) -> void:
	if network_session == null or network_session.client_route != NetworkSessionManager.ROUTE_LIVE_BUILD:
		return
	var was_visible := live_client.ghost_visible()
	var previous_cell := live_client.cell
	live_client.process(delta)
	_push_input()
	_refresh_live_buttons()
	if was_visible or live_client.ghost_visible() or previous_cell != live_client.cell:
		_status_label.text = _host_status_text()
		queue_redraw()


func apply_state(state: Dictionary) -> void:
	# Copy only the whitelisted primitive fields and codec-produced records.
	var next_metadata: Dictionary = state.get("metadata", {})
	var next_snapshot_id := int(state.get("snapshot_id", -1))
	var next_phase := int(next_metadata.get("phase", -1))
	if next_snapshot_id != _last_snapshot_id or next_phase != _last_phase:
		_seat_buffer.clear()
	if next_phase != _last_phase and next_phase != MatchPhaseController.Phase.PLAY:
		live_client.reset()
	_last_snapshot_id = next_snapshot_id
	_last_phase = next_phase
	if _results_overlay != null:
		_results_overlay.set_phase(next_phase)
	_refresh_controls_visibility()
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


## NLB-P09: the replicated ledger or vote changed. The status line and the overlay follow it.
func _on_results_changed() -> void:
	_refresh_controls_visibility()
	_status_label.text = _host_status_text()
	queue_redraw()


## The gameplay touch row is hidden while a results or session-ended screen covers the view.
func _refresh_controls_visibility() -> void:
	var covered := _results_overlay != null and _results_overlay.is_blocking()
	if _phone_panel != null:
		_phone_panel.visible = not covered
	if _live_controls != null:
		_live_controls.visible = not covered


## The session ended (host loss, host close, lobby return, host quit or the player leaving): show
## why and let the owner return to the title or lobby. Never leaves a stale match view on screen.
func show_session_ended(reason: int) -> void:
	if _results_overlay != null:
		_results_overlay.show_session_ended(reason)
	_refresh_controls_visibility()


func _on_host_pause_changed(_paused: bool, _epoch: int) -> void:
	# The host's global pause froze the shared clocks; the banner and the held timer follow it.
	_received_at_ms = Time.get_ticks_msec()
	_status_label.text = _host_status_text()
	queue_redraw()


func _on_router_action(seat_index: int, action_name: String) -> void:
	if seat_index == -1 and action_name == "client_pause_overlay":
		_local_overlay = not _local_overlay
		_status_label.text = _host_status_text()
		queue_redraw()


func _host_paused() -> bool:
	return network_session != null and network_session.client_paused


func _host_status_text() -> String:
	var metadata: Dictionary = _state.get("metadata", {})
	var phase := int(metadata.get("phase", 0))
	var remaining_ms := int(metadata.get("remaining_ms", 0))
	if not _host_paused() and not bool(metadata.get("paused", false)) and _received_at_ms > 0:
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
	var phase_name: String = PHASE_NAMES[clampi(phase, 0, PHASE_NAMES.size() - 1)]
	# The ledger, not the wire round number, says when the match is in sudden death or over.
	var round_text := "Round %d" % round_number
	if network_session != null and network_session.client_results.is_final():
		round_text = "Final results"
	elif network_session != null and network_session.client_results.is_sudden_death():
		round_text = "Sudden Death"
	var text := "Tilaok!  ·  %s%s  ·  %s  ·  %.1fs" % [phase_name, event_text, round_text, remaining]
	if _host_paused():
		text += "
PAUSED BY HOST — the match is frozen for everyone until the host resumes."
	if _local_overlay:
		text += "
MENU (local) — the match keeps running; only the host can pause it."
	if network_session != null and network_session.client_unverified_content:
		text += "\nUNVERIFIED CONTENT — development host; results are not evidence."
	if network_session != null and network_session.client_route == NetworkSessionManager.ROUTE_LIVE_BUILD:
		if network_session.terrain_gap:
			text += "\nResyncing the stage…"
		elif not live_client.notice.is_empty():
			text += "\n" + live_client.notice
	return text


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
		_draw_entity(entity, origin, scale_factor)
	_draw_transients(origin, scale_factor)
	if live_client.ghost_visible():
		_draw_ghost(origin, scale_factor)
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


## Committed host terrain: its real footprint and rotation from the local draw-only catalog, with
## the stage record position as the top-left corner. A live piece in its safe grace gets a dashed
## outline, an hourglass and its remaining time, so the tell never depends on colour alone.
func _draw_entity(entity: Dictionary, origin: Vector2, scale_factor: float) -> void:
	var key := str(entity.variant_key)
	var known := _footprint_cells(key) != Vector2i.ZERO
	var size := _footprint_size(key, int(entity.get("rotation", 0)))
	var rect := Rect2(origin + entity.position * scale_factor, size * scale_factor)
	var tint := Color("#d8bb82")
	if key.contains("bamboo"):
		tint = Color("#78a96b")
	elif key.contains("tire"):
		tint = Color("#52616b")
	elif key.contains("collapsing"):
		tint = Color("#c89955")
	if (int(entity.get("state_flags", 0)) & 6) == (StageBlock.CollapseState.GONE << 1):
		tint = Color("#777c78")
	var outline := Color("#2a1f14")
	if not known:
		draw_rect(rect, outline, false, 2.0)
		draw_string(ThemeDB.fallback_font, rect.get_center() + Vector2(-4, 6), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
		return
	if int(entity.get("lifecycle", 0)) == NetworkPlacementCodec.Lifecycle.GRACE:
		draw_rect(rect, Color(tint, 0.55), true)
		_draw_dashed_rect(rect, Color("#fff4b8"), 3.0)
		var seconds := float(int(entity.get("timer_ms", 0))) / 1000.0
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(4, 18), "⌛ %.1fs" % seconds, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
		return
	draw_rect(rect, tint, true)
	draw_rect(rect, outline, false, 2.0)


## Contract v1.4 host transients, draw-only. Each kind has its own shape and glyph so it never
## depends on colour alone; a captured chicken's seat number is drawn inside its bubble.
func _draw_transients(origin: Vector2, scale_factor: float) -> void:
	var transients: Dictionary = _state.get("transients", {})
	for transient in transients.values():
		var point: Vector2 = origin + (transient.position as Vector2) * scale_factor
		var extent: Vector2 = (transient.get("extent", Vector2.ONE * 16.0) as Vector2) * scale_factor
		match int(transient.get("transient_kind", 0)):
			NetworkMatchCodec.TRANSIENT_PROJECTILE:
				draw_rect(Rect2(point - extent * 0.5, extent), Color("#e9e2d0"), true)
				draw_string(ThemeDB.fallback_font, point + Vector2(-4, 5), "»", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#16232a"))
			NetworkMatchCodec.TRANSIENT_BUBBLE:
				var radius := maxf(extent.x, extent.y) * 0.5
				draw_arc(point, radius, 0.0, TAU, 28, Color("#bfe8ff"), 3.0 * scale_factor)
				var captive := int(transient.get("captive_seat", -1))
				if captive >= 0:
					draw_string(ThemeDB.fallback_font, point + Vector2(-5, 6), "P%d" % (captive + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
			NetworkMatchCodec.TRANSIENT_BLAST:
				var area := Rect2(point - extent * 0.5, extent)
				draw_rect(area, Color(1.0, 0.85, 0.45, 0.35), true)
				_draw_dashed_rect(area, Color("#fff4b8"), 3.0)
				draw_string(ThemeDB.fallback_font, area.get_center() + Vector2(-14, 6), "POP", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
			NetworkMatchCodec.TRANSIENT_MOVER:
				draw_rect(Rect2(point - extent * 0.5, extent), Color("#c4553f"), true)
				draw_string(ThemeDB.fallback_font, point + Vector2(-5, 6), "◆", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)


## The local tentative ghost: dashed outline, no fill, and a text state. It is never drawn as
## solid terrain; a rejection shows a cross and its reason.
func _draw_ghost(origin: Vector2, scale_factor: float) -> void:
	var world := Vector2(live_client.cell) * GRID_CELL_WU
	var size := live_client.footprint_size_wu(GRID_CELL_WU)
	var rect := Rect2(origin + world * scale_factor, size * scale_factor)
	var color := Color.WHITE
	if live_client.state == NetworkLivePlacementClient.GhostState.PENDING:
		color = Color("#ffe08a")
	elif live_client.state == NetworkLivePlacementClient.GhostState.REJECTED:
		color = Color("#ff9a8a")
		draw_line(rect.position, rect.end, color, 3.0)
		draw_line(Vector2(rect.position.x, rect.end.y), Vector2(rect.end.x, rect.position.y), color, 3.0)
	_draw_dashed_rect(rect, color, 3.0)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(0, -8), live_client.ghost_label(), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, color)


func _draw_dashed_rect(rect: Rect2, color: Color, width: float) -> void:
	var corners := [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]
	for index in corners.size():
		draw_dashed_line(corners[index], corners[(index + 1) % corners.size()], color, width, 8.0)


func _footprint_cells(variant_key: String) -> Vector2i:
	if _footprints.has(variant_key):
		return _footprints[variant_key]
	if _catalog == null:
		_catalog = ItemDefinitions.load_all(GameplayTuning.new())
	var found := _catalog.find_variant(variant_key)
	var cells := Vector2i.ZERO
	if not found.is_empty():
		cells = (found.variant as ItemVariantDefinition).footprint_cells
	_footprints[variant_key] = cells
	return cells


func _footprint_size(variant_key: String, rotation: int) -> Vector2:
	var cells := _footprint_cells(variant_key)
	if cells == Vector2i.ZERO:
		cells = Vector2i.ONE
	return ItemGeometry.rotated_size(Vector2(cells) * GRID_CELL_WU, rotation)


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
		# Scores are integer eighth-point units end to end; the text derives from the units.
		var points_text := ScoreFormat.format_units(int(seat.get("score_units", 0)))
		draw_string(ThemeDB.fallback_font, Vector2(size.x - 190, 42 + index * 26), "P%d  %s" % [int(seat.identity), points_text], HORIZONTAL_ALIGNMENT_LEFT, 170, 18, Color.WHITE)
		index += 1


func _touch_enabled() -> bool:
	return OS.has_feature("android") or touch_controls_forced


func _build_phone_controls() -> void:
	if _phone_controls_built:
		return
	_phone_controls_built = true
	var panel := HBoxContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_top = -88
	panel.offset_bottom = -8
	panel.add_theme_constant_override("separation", 5)
	_phone_panel = panel
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


## Minimum live-build cluster (NLB-P06), right side above the existing row: Build, a four-way aim
## pad that moves only the ghost, Rotate, Place and Cancel. Movement buttons keep working while
## building. Full touch UX, dp scaling and the accessibility audit remain P10 work.
func _build_live_controls() -> void:
	if _live_controls != null:
		return
	_live_controls = GridContainer.new()
	_live_controls.columns = 3
	_live_controls.add_theme_constant_override("h_separation", 6)
	_live_controls.add_theme_constant_override("v_separation", 6)
	_live_controls.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	var span := LIVE_BUTTON_SIZE * 3.0 + 12.0
	_live_controls.offset_right = -8
	_live_controls.offset_left = -8 - span
	_live_controls.offset_bottom = -96
	_live_controls.offset_top = -96 - span
	add_child(_live_controls)
	var layout := [
		["build", "Build"], ["aim_up", "▲ Aim"], ["rotate", "Rotate"],
		["aim_left", "◀ Aim"], ["place", "Place"], ["aim_right", "Aim ▶"],
		["cancel", "Cancel"], ["aim_down", "▼ Aim"], ["", ""],
	]
	for entry in layout:
		if str(entry[0]).is_empty():
			var filler := Control.new()
			filler.custom_minimum_size = Vector2(LIVE_BUTTON_SIZE, LIVE_BUTTON_SIZE)
			filler.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_live_controls.add_child(filler)
			continue
		var button := _touch_button(str(entry[1]), LIVE_BUTTON_SIZE)
		button.custom_minimum_size = Vector2(LIVE_BUTTON_SIZE, LIVE_BUTTON_SIZE)
		_live_buttons[str(entry[0])] = button
		_live_controls.add_child(button)
	(_live_buttons.build as Button).pressed.connect(func() -> void: live_client.toggle_build(); queue_redraw())
	(_live_buttons.rotate as Button).pressed.connect(func() -> void: live_client.rotate(); queue_redraw())
	(_live_buttons.place as Button).pressed.connect(func() -> void: live_client.confirm(); queue_redraw())
	(_live_buttons.cancel as Button).pressed.connect(func() -> void: live_client.cancel(); queue_redraw())
	var aims := {
		"aim_up": Vector2.UP, "aim_down": Vector2.DOWN, "aim_left": Vector2.LEFT, "aim_right": Vector2.RIGHT,
	}
	for aim_name in aims:
		var aim_button := _live_buttons[aim_name] as Button
		var direction: Vector2 = aims[aim_name]
		aim_button.button_down.connect(func() -> void: live_client.set_aim(direction))
		aim_button.button_up.connect(func() -> void: live_client.set_aim(Vector2.ZERO))
	_refresh_live_buttons()


func _refresh_live_buttons() -> void:
	if _live_controls == null:
		return
	var building := live_client.state == NetworkLivePlacementClient.GhostState.TENTATIVE
	var pending := live_client.state == NetworkLivePlacementClient.GhostState.PENDING
	var available := network_session != null and network_session.client_live_build_available()
	(_live_buttons.build as Button).disabled = not available and not building
	(_live_buttons.build as Button).text = "Close" if building else "Build"
	(_live_buttons.place as Button).disabled = not (live_client.can_confirm() or pending)
	(_live_buttons.rotate as Button).disabled = not building
	(_live_buttons.cancel as Button).disabled = live_client.state == NetworkLivePlacementClient.GhostState.NONE
	for aim_name in ["aim_up", "aim_down", "aim_left", "aim_right"]:
		(_live_buttons[aim_name] as Button).disabled = not building


func _on_terrain_resync(_gap: bool) -> void:
	_status_label.text = _host_status_text()
	_refresh_live_buttons()
	queue_redraw()


func _touch_button(label: String, width: float) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(width, 72)
	button.add_theme_font_size_override("font_size", 17)
	button.focus_mode = Control.FOCUS_NONE
	return button


func _set_horizontal(value: int) -> void:
	_axis_x = value
	_push_input()


## One continuous-input sample: movement axis plus (live route) the aim pad and the build echo.
## The aim never moves the chicken; the host routes it to the live cursor only.
func _push_input() -> void:
	if network_session == null:
		return
	var building := live_client.state == NetworkLivePlacementClient.GhostState.TENTATIVE
	network_session.client_set_continuous_input(
		[_axis_x, 0], live_client.aim_axes() if building else [0, 0], building
	)


func _send_action(action_id: int, pressed: bool) -> void:
	if network_session != null:
		network_session.client_set_action(action_id, pressed)


func _choose_action() -> void:
	var metadata: Dictionary = _state.get("metadata", {})
	var phase := int(metadata.get("phase", 0))
	var action_id := 4 if phase == MatchPhaseController.Phase.PUGAD else 1
	_send_action(action_id, true)
	_send_action(action_id, false)

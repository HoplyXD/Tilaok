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
var _touch_layer: NetworkTouchLayer
var _phone_hud: NetworkPhoneHud
var _move_direction := Vector2i.ZERO
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
		_build_touch()
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
		if _touch_layer != null:
			_touch_layer.configure(true)
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
			for action_id in [0, 1, 2, 3, 4, 6, 7, 8, 9, 10, 11]:
				network_session.client_set_action(action_id, false)


func _process(delta: float) -> void:
	if network_session == null or network_session.client_route != NetworkSessionManager.ROUTE_LIVE_BUILD:
		return
	var was_visible := live_client.ghost_visible()
	var previous_cell := live_client.cell
	live_client.process(delta)
	_push_input()
	_refresh_touch_state()
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
	_refresh_touch_state()
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
	if _touch_layer != null:
		_touch_layer.visible = not covered
	if _phone_hud != null:
		_phone_hud.visible = not covered


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
		if network_session != null and network_session.client_assigned_seat == int(seat_id):
			# The local chicken is marked with an outer ring and a text tag, never colour alone.
			draw_arc(point, 30.0 * scale_factor, 0.0, TAU, 28, Color.WHITE, 3.0 * scale_factor)
			draw_string(ThemeDB.fallback_font, point + Vector2(-14, 44) * scale_factor, "YOU", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
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


## NLB-P10: one index-owning touch layer replaces the old Button rows (see NetworkTouchLayer).
func _build_touch() -> void:
	if _touch_layer != null:
		return
	_touch_layer = NetworkTouchLayer.new()
	_touch_layer.name = "NetworkTouchLayer"
	_touch_layer.accept_mouse = touch_controls_forced and not OS.has_feature("android")
	_touch_layer.live_route = _is_live_route()
	_touch_layer.control_pressed.connect(_on_touch_pressed)
	_touch_layer.control_released.connect(_on_touch_released)
	_touch_layer.move_changed.connect(_on_touch_move)
	_touch_layer.aim_changed.connect(_on_touch_aim)
	add_child(_touch_layer)
	_phone_hud = NetworkPhoneHud.new()
	_phone_hud.name = "NetworkPhoneHud"
	add_child(_phone_hud)
	_status_label.position = Vector2(24, 18 + NetworkPhoneHud.BADGE_SIZE.y + NetworkPhoneHud.CHIP_SIZE.y + 14.0)
	_refresh_touch_state()


func _is_live_route() -> bool:
	return network_session != null and network_session.client_route == NetworkSessionManager.ROUTE_LIVE_BUILD


func _on_touch_pressed(control_id: String) -> void:
	var live := _is_live_route()
	match control_id:
		"jump":
			_send_action(0, true)
		"sneak":
			_send_action(11, true)
		"cheer":
			_send_action(6, true)
		"claim":
			_choose_action()
		"back":
			_tap_action(2)
		"pause":
			_on_router_action(-1, "client_pause_overlay")
		"rotate":
			if live:
				live_client.rotate()
			else:
				_tap_action(3)
		"build":
			live_client.toggle_build()
		"place":
			live_client.confirm()
		"cancel":
			live_client.cancel()
	queue_redraw()


func _on_touch_released(control_id: String) -> void:
	match control_id:
		"jump":
			_send_action(0, false)
		"sneak":
			_send_action(11, false)
		"cheer":
			_send_action(6, false)


## Move zone: the horizontal axis plus the four held direction actions the old arrows sent.
func _on_touch_move(direction: Vector2i) -> void:
	_axis_x = direction.x * 1000
	# Only edges are sent, so the per-action rate limit is never spent on repeats.
	var previous := _move_direction
	_move_direction = direction
	if (direction.x < 0) != (previous.x < 0):
		_send_action(7, direction.x < 0)
	if (direction.x > 0) != (previous.x > 0):
		_send_action(8, direction.x > 0)
	if (direction.y < 0) != (previous.y < 0):
		_send_action(9, direction.y < 0)
	if (direction.y > 0) != (previous.y > 0):
		_send_action(10, direction.y > 0)
	_push_input()


## Aim zone: moves only the ghost (live route); it never feeds the movement axis.
func _on_touch_aim(direction: Vector2) -> void:
	live_client.set_aim(direction)


func _refresh_touch_state() -> void:
	if _touch_layer == null:
		return
	var live := network_session != null and network_session.client_route == NetworkSessionManager.ROUTE_LIVE_BUILD
	var building := live_client.state == NetworkLivePlacementClient.GhostState.TENTATIVE
	var pending := live_client.state == NetworkLivePlacementClient.GhostState.PENDING
	var available := network_session != null and network_session.client_live_build_available()
	_touch_layer.set_button_enabled("build", live and (available or building))
	_touch_layer.set_button_label("build", "Close" if building else "Build")
	_touch_layer.set_button_enabled("place", live_client.can_confirm() or pending)
	# One control per action in each context (InputContextTable): Claim / OK only answers in the Pugad
	# and Place screens, so it never doubles as the live Place button.
	var claim_phase := _last_phase == MatchPhaseController.Phase.PUGAD or _last_phase == MatchPhaseController.Phase.PLACE
	_touch_layer.set_button_enabled("claim", claim_phase)
	_touch_layer.set_button_enabled("rotate", building or (not live and _last_phase == MatchPhaseController.Phase.PLACE))
	_touch_layer.set_button_enabled("cancel", live_client.state != NetworkLivePlacementClient.GhostState.NONE)
	_touch_layer.set_button_enabled(NetworkTouchLayer.ZONE_AIM, building)
	if _phone_hud != null:
		_phone_hud.set_seat(network_session.client_assigned_seat if network_session != null else -1)
		_phone_hud.set_placement(int(live_client.state), live_client.ghost_label())


func _on_terrain_resync(_gap: bool) -> void:
	_status_label.text = _host_status_text()
	_refresh_touch_state()
	queue_redraw()


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


func _tap_action(action_id: int) -> void:
	_send_action(action_id, true)
	_send_action(action_id, false)


func _choose_action() -> void:
	var metadata: Dictionary = _state.get("metadata", {})
	var phase := int(metadata.get("phase", 0))
	var action_id := 4 if phase == MatchPhaseController.Phase.PUGAD else 1
	_send_action(action_id, true)
	_send_action(action_id, false)

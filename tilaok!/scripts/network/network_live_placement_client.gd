class_name NetworkLivePlacementClient
extends RefCounted

## Client-side, presentation-only live placement (NLB-P06). It never commits terrain, consumes an
## item or decides success: the ghost stays tentative until the host answers, and a committed
## piece appears only through the host's terrain commit or a snapshot. Build mode, inventory and
## the item variant are echoed from the host's LIVE_SEAT_STATE.

enum GhostState { NONE, TENTATIVE, PENDING, ACCEPTED_AWAIT_TERRAIN, REJECTED }

const RESEND_INTERVAL_MS := 1500
const MAX_RESENDS := 3
const REJECTED_DISPLAY_MS := 2000
const AWAIT_TERRAIN_MS := 3000
const HOST_ECHO_GRACE_MS := 600
const CURSOR_CELLS_PER_SECOND := 8.0
const CURSOR_INITIAL_DELAY := 0.25
const ACTION_BUILD_TOGGLE := 12
const ACTION_LIVE_ROTATE := 13
const ACTION_LIVE_CANCEL := 14

var session: NetworkSessionManager
var state := GhostState.NONE
var cell := Vector2i.ZERO
var rotation := 0
var variant_key := ""
var request_id := 0
var accepted_entity_id := 0
var notice := ""
## True after Cancel/Build while a request is pending: the preview hides, the request resolves.
var preview_hidden := false
var _request_payload := PackedByteArray()
var _sent_ms := 0
var _resends := 0
var _state_since_ms := 0
var _aim := Vector2.ZERO
var _aim_elapsed := 0.0
var _aim_first := true
var _catalog: ItemDefinitions


func bind(next_session: NetworkSessionManager) -> void:
	session = next_session
	if session == null:
		return
	if not session.placement_result_received.is_connected(apply_result):
		session.placement_result_received.connect(apply_result)
	if not session.live_seat_state_received.is_connected(apply_seat_state):
		session.live_seat_state_received.connect(apply_seat_state)
	if not session.match_state_received.is_connected(apply_replica):
		session.match_state_received.connect(apply_replica)


func unbind() -> void:
	if session == null or not is_instance_valid(session):
		return
	if session.placement_result_received.is_connected(apply_result):
		session.placement_result_received.disconnect(apply_result)
	if session.live_seat_state_received.is_connected(apply_seat_state):
		session.live_seat_state_received.disconnect(apply_seat_state)
	if session.match_state_received.is_connected(apply_replica):
		session.match_state_received.disconnect(apply_replica)


func item_available() -> bool:
	if session == null:
		return false
	var seat_state: Dictionary = session.client_live_seat_state
	return (
		int(seat_state.get("inventory_id", 0)) > 0
		and int(seat_state.get("item_status", 0)) == NetworkPlacementCodec.ItemStatus.AVAILABLE
	)


func can_confirm() -> bool:
	return (
		state == GhostState.TENTATIVE
		and session != null
		and session.client_live_build_available()
		and item_available()
	)


## Build button. Opening starts a local tentative preview at the host cursor and tells the host;
## closing never confirms. While a request is pending it only hides the preview.
func toggle_build() -> bool:
	match state:
		GhostState.NONE, GhostState.REJECTED:
			if session == null or not session.client_live_build_available():
				notice = "Building is unavailable right now."
				return false
			if not item_available():
				notice = "You have no item to place."
				return false
			var seat_state: Dictionary = session.client_live_seat_state
			variant_key = str(seat_state.get("variant_key", ""))
			cell = seat_state.get("cursor", Vector2i.ZERO)
			rotation = int(seat_state.get("rotation", 0)) & 3
			preview_hidden = false
			_set_state(GhostState.TENTATIVE)
			notice = "Build mode on • aim, then Place."
			# The host toggle flips state, so send it only when the host echo says "off".
			if not bool(seat_state.get("build_mode", false)):
				session.client_set_action(ACTION_BUILD_TOGGLE, true)
			return true
		GhostState.TENTATIVE:
			_set_state(GhostState.NONE)
			notice = "Build mode off."
			# Closing uses the idempotent cancel so a lost or late echo cannot reopen build mode.
			session.client_set_action(ACTION_LIVE_CANCEL, true)
			return true
		_:
			preview_hidden = true
			notice = "Preview hidden. Your request still resolves."
			return true


## Cancel keeps the item: it closes the local preview and asks the host to leave build mode.
func cancel() -> void:
	if state == GhostState.TENTATIVE:
		_set_state(GhostState.NONE)
		notice = "Preview closed. Your item is kept."
		if session != null:
			session.client_set_action(ACTION_LIVE_CANCEL, true)
	elif state in [GhostState.PENDING, GhostState.ACCEPTED_AWAIT_TERRAIN]:
		preview_hidden = true
		notice = "Preview hidden. Your request still resolves."


func rotate() -> void:
	if state != GhostState.TENTATIVE:
		return
	var allowed := _allowed_rotations()
	if allowed.size() <= 1:
		notice = "This item does not rotate."
		return
	var index := allowed.find(rotation)
	rotation = int(allowed[(index + 1) % allowed.size()])
	if session != null:
		session.client_set_action(ACTION_LIVE_ROTATE, true)


## Place button. One tap sends one request with a stable ID; repeat taps while it is pending
## resend the identical bytes so the host cache deduplicates them.
func confirm() -> bool:
	if state == GhostState.PENDING:
		_resend()
		return true
	if not can_confirm():
		if session != null and session.terrain_gap:
			notice = "Resyncing the stage… try again in a moment."
		return false
	var next_id := session.client_next_placement_request_id()
	var payload := session.client_encode_placement_intent(next_id, cell, rotation)
	if payload.is_empty():
		notice = "That placement could not be sent."
		return false
	request_id = next_id
	_request_payload = payload
	_resends = 0
	_sent_ms = Time.get_ticks_msec()
	preview_hidden = false
	_set_state(GhostState.PENDING)
	notice = NetworkPlacementCodec.detail_text(NetworkPlacementCodec.Detail.QUEUED)
	session.client_send_placement_payload(_request_payload)
	return true


## Aim pad direction in cells (-1..1 per axis). The local ghost moves with the host's repeat
## timing; the same direction also streams to the host as aim axes for its own cursor.
func set_aim(direction: Vector2) -> void:
	if direction == _aim:
		return
	_aim = direction
	_aim_elapsed = 0.0
	_aim_first = true
	if direction != Vector2.ZERO:
		_step_cursor()


func aim_axes() -> Array:
	return [roundi(clampf(_aim.x, -1.0, 1.0) * 1000.0), roundi(clampf(_aim.y, -1.0, 1.0) * 1000.0)]


func process(delta: float) -> void:
	var now := Time.get_ticks_msec()
	if state == GhostState.TENTATIVE and _aim != Vector2.ZERO:
		_aim_elapsed += delta
		var delay := CURSOR_INITIAL_DELAY if _aim_first else 1.0 / CURSOR_CELLS_PER_SECOND
		if _aim_elapsed >= delay:
			_aim_elapsed -= delay
			_aim_first = false
			_step_cursor()
	match state:
		GhostState.PENDING:
			if now - _sent_ms >= RESEND_INTERVAL_MS:
				if _resends >= MAX_RESENDS:
					# The item stays with the host either way; a new confirm uses a new ID.
					request_id = 0
					_request_payload = PackedByteArray()
					_set_state(GhostState.TENTATIVE)
					notice = "No reply from the host — try again."
				else:
					_resend()
		GhostState.REJECTED:
			if now - _state_since_ms >= REJECTED_DISPLAY_MS:
				_set_state(GhostState.NONE)
		GhostState.ACCEPTED_AWAIT_TERRAIN:
			if now - _state_since_ms >= AWAIT_TERRAIN_MS:
				# The snapshot path repairs a missing commit; the ghost never turns into terrain.
				_set_state(GhostState.NONE)
		GhostState.TENTATIVE:
			var seat_state: Dictionary = session.client_live_seat_state if session != null else {}
			if (
				now - _state_since_ms >= HOST_ECHO_GRACE_MS
				and not bool(seat_state.get("build_mode", false))
			):
				_set_state(GhostState.NONE)
				notice = "Build mode closed by the host."


func apply_result(result: Dictionary) -> void:
	if request_id == 0 or int(result.get("request_id", 0)) != request_id:
		# A duplicate or stale result for an older request can never commit anything here.
		return
	var status := int(result.get("status", 0))
	var detail := int(result.get("detail", 0))
	if status == NetworkPlacementCodec.Status.QUEUED:
		_sent_ms = Time.get_ticks_msec()
		notice = NetworkPlacementCodec.detail_text(detail)
		return
	request_id = 0
	_request_payload = PackedByteArray()
	notice = NetworkPlacementCodec.detail_text(detail)
	if status == NetworkPlacementCodec.Status.ACCEPTED:
		accepted_entity_id = int(result.get("entity_id", 0))
		cell = result.get("cell", cell)
		rotation = int(result.get("rotation", rotation))
		if accepted_entity_id <= 0 or _replica_has_entity(accepted_entity_id):
			_set_state(GhostState.NONE)
		else:
			_set_state(GhostState.ACCEPTED_AWAIT_TERRAIN)
	else:
		accepted_entity_id = 0
		_set_state(GhostState.REJECTED)


func apply_seat_state(seat_state: Dictionary) -> void:
	if (
		int(seat_state.get("item_status", 0)) == NetworkPlacementCodec.ItemStatus.USED
		and state == GhostState.TENTATIVE
	):
		_set_state(GhostState.NONE)


func apply_replica(_replica: Dictionary) -> void:
	if state == GhostState.ACCEPTED_AWAIT_TERRAIN and _replica_has_entity(accepted_entity_id):
		# The host's committed entity now replaces the tentative ghost.
		_set_state(GhostState.NONE)


func ghost_visible() -> bool:
	return state != GhostState.NONE and not preview_hidden


## Status text drawn on the ghost. Never "placed": only host terrain is committed.
func ghost_label() -> String:
	match state:
		GhostState.TENTATIVE:
			return "PREVIEW" if can_confirm() else "PREVIEW • WAIT"
		GhostState.PENDING:
			return "SENDING…"
		GhostState.ACCEPTED_AWAIT_TERRAIN:
			return "CONFIRMING…"
		GhostState.REJECTED:
			return "✕ " + notice
	return ""


func footprint_size_wu(grid_cell_wu: float = 64.0) -> Vector2:
	var variant := _variant()
	var cells := Vector2(variant.footprint_cells) if variant != null else Vector2.ONE
	return ItemGeometry.rotated_size(cells * grid_cell_wu, rotation)


func reset() -> void:
	state = GhostState.NONE
	request_id = 0
	accepted_entity_id = 0
	_request_payload = PackedByteArray()
	preview_hidden = false
	notice = ""
	_aim = Vector2.ZERO


func _resend() -> void:
	if _request_payload.is_empty() or session == null:
		return
	_resends += 1
	_sent_ms = Time.get_ticks_msec()
	session.client_send_placement_payload(_request_payload)


func _step_cursor() -> void:
	var step := Vector2i.ZERO
	if absf(_aim.x) >= absf(_aim.y):
		step.x = 1 if _aim.x > 0.0 else -1
	else:
		step.y = 1 if _aim.y > 0.0 else -1
	var next := cell + step
	if absi(next.x) <= NetworkPlacementCodec.MAX_CELL and absi(next.y) <= NetworkPlacementCodec.MAX_CELL:
		cell = next


func _set_state(next_state: GhostState) -> void:
	state = next_state
	_state_since_ms = Time.get_ticks_msec()
	if next_state == GhostState.NONE:
		preview_hidden = false


func _replica_has_entity(entity_id: int) -> bool:
	if session == null or entity_id <= 0:
		return false
	var entities: Dictionary = session.client_replica_state.get("entities", {})
	return entities.has(entity_id)


## Rotations the local draw-only catalog allows without host-only gates; the host still validates.
func _allowed_rotations() -> Array:
	var variant := _variant()
	var allowed: Array = []
	if variant == null:
		return [0]
	for turn in variant.rotations:
		if int(turn) not in variant.gated_rotations:
			allowed.append(int(turn) & 3)
	if allowed.is_empty():
		allowed.append(0)
	return allowed


func _variant() -> ItemVariantDefinition:
	if variant_key.is_empty():
		return null
	if _catalog == null:
		_catalog = ItemDefinitions.load_all(GameplayTuning.new())
	var found := _catalog.find_variant(variant_key)
	return found.get("variant") as ItemVariantDefinition if not found.is_empty() else null

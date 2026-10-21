# gdlint: disable=max-returns
class_name NLBP06NetworkLiveBuildMatchRoom
extends NLBP05LiveBuildMatchRoom

## Opt-in networked live-build route (`-- --match-route=network_live_build` on the PC host). The
## host room stays the only rules implementation. Remote peers send bounded placement intents that
## NetworkSessionManager hands to network_submit_placement(); they enter the same pipeline, receipt
## order and authority boundary as local keyboard/gamepad seats. Only the host commits terrain.

const NETWORK_PROFILE_ID := "nlb_p06_network_live_build"
## Matches the offline ExplosionFlash lifetime.
const LIVE_BLAST_SECONDS := 0.7

## NLB-P07 development override (`--nlb-unverified-content`), set by GameFlow before _ready.
## Off by default: only VERIFIED matrix cells are selectable, so a strict host deals nothing yet.
var unverified_content := false
## Host-issued inventory IDs for this round's assigned items (seat -> int, 0 = none). They are
## unique for the match so a stale or foreign ID can never match another seat's item.
var _inventory_ids: Dictionary = {}
var _inventory_serial := 0
## Contract v1.4 transient bookkeeping: wire IDs per live key and host blast flashes.
var _transient_ids: Dictionary = {}
var _transient_serial := 0
var _live_blasts: Dictionary = {}
var _blast_serial := 0


func _init() -> void:
	profile_id = NETWORK_PROFILE_ID
	# Dealt per round from the NLB-P07 matrix (_prepare_pugad_pool); nothing before that.
	tuning.item_enabled_variants = PackedStringArray()


func _ready() -> void:
	available_modes = NLBLiveCompatibilityMatrix.available_modes(unverified_content)
	super._ready()


## The host refuses a networked live match whose map, required rounds or items are not
## selectable in the NLB-P07 matrix; the reason is readable in the lobby and the log.
func start_match() -> bool:
	var refusal := NLBLiveCompatibilityMatrix.start_gate(network_map_id, unverified_content)
	if not refusal.is_empty():
		push_warning(refusal)
		last_message = refusal
		_refresh_match_ui()
		return false
	print(
		(
			"NLB_P07_LIVE_MATRIX version=%d override=%s map=%s modes=%s"
			% [
				NLBLiveCompatibilityMatrix.MATRIX_VERSION,
				str(unverified_content),
				network_map_id,
				str(available_modes),
			]
		)
	)
	return super.start_match()


func schedule_pairs() -> Array[Dictionary]:
	return NLBLiveCompatibilityMatrix.schedule_pairs(unverified_content)


func _prepare_pugad_pool(mode_ids: PackedStringArray) -> void:
	var round_cell := NLBLiveCompatibilityMatrix.round_cell_id(current_entry())
	if not NLBLiveCompatibilityMatrix.selectable(round_cell, unverified_content):
		# The schedule only draws selectable rows; this is a defensive fail-closed path.
		tuning.item_enabled_variants = PackedStringArray()
		push_warning("NLB-P07: round cell %s is not selectable; no eggs dealt." % round_cell)
		return
	tuning.item_enabled_variants = NLBLiveCompatibilityMatrix.live_variants(
		mode_ids, unverified_content
	)


func _augment_pugad_egg_pool(seat_count: int) -> void:
	if NLBLiveCompatibilityMatrix.selectable(
		NLBLiveCompatibilityMatrix.BARYA_CELL, unverified_content
	):
		super._augment_pugad_egg_pool(seat_count)


## True when the assigned variant's matrix cell is selectable for every mode of this round.
func live_variant_allowed(variant_key: String) -> bool:
	if BaryaObjectiveDefinition.is_variant(variant_key):
		return NLBLiveCompatibilityMatrix.selectable(
			NLBLiveCompatibilityMatrix.BARYA_CELL, unverified_content
		)
	var mode_ids := pugad_mode_ids()
	if mode_ids.is_empty():
		return false
	for mode_id in mode_ids:
		var cell_id := NLBLiveCompatibilityMatrix.item_cell_id(variant_key, mode_id)
		if not NLBLiveCompatibilityMatrix.selectable(cell_id, unverified_content):
			return false
	return true


## Commit-time recheck for local and remote seats alike: a cell turned off since dealing (or a
## spoofed inventory) never reaches the shared validator.
func _commit_live_intent(seat_index: int, intent: Dictionary, boundary: int) -> Dictionary:
	var variant_key := str(intent.get("variant_key", ""))
	if not variant_key.is_empty() and not live_variant_allowed(variant_key):
		return _live_result(
			{
				"request_id": str(intent.get("request_id", "")),
				"seat_index": seat_index,
				"commit_boundary": boundary,
				"stage_version": items.stage_version,
			},
			false,
			"variant_disabled",
			"This item is turned off for networked live play."
		)
	return super._commit_live_intent(seat_index, intent, boundary)


func _enter_place() -> void:
	super._enter_place()
	if phase_controller.phase != MatchPhaseController.Phase.GO:
		return
	_inventory_ids.clear()
	for seat_variant in placement_controller.cursors.keys():
		_inventory_serial += 1
		_inventory_ids[int(seat_variant)] = _inventory_serial
	_notify_presentation(&"live_build")


func is_remote_seat(seat_index: int) -> bool:
	return str(input_router.registry.get_seat(seat_index).get("device_kind", "")) == "remote"


## Remote seats confirm only through PLACEMENT_INTENT, so a forwarded confirm edge can never
## submit a second, cursor-based request for the same item.
func _on_match_action_pressed(seat_index: int, action_name: String) -> void:
	if (
		action_name == "confirm"
		and phase_controller.phase == MatchPhaseController.Phase.PLAY
		and seat_index >= 0
		and is_remote_seat(seat_index)
	):
		return
	super._on_match_action_pressed(seat_index, action_name)


## Queues one validated network intent. The seat comes from the session's authenticated peer
## binding; the variant comes from the host inventory, never from the client. `request` carries
## request_id (wire u64), peer_generation, inventory_id, expected_stage_version, cell, rotation.
func network_submit_placement(
	seat_index: int, request: Dictionary, receipt_usec: int
) -> Dictionary:
	if (
		phase_controller.phase != MatchPhaseController.Phase.PLAY
		or request_pipeline.attempt_id.is_empty()
		or items == null
		or not items.in_play
	):
		return _network_rejection("wrong_phase")
	if _sudden_death_active:
		return _network_rejection("wrong_phase")
	if not placement_controller.cursors.has(seat_index):
		return _network_rejection("inventory_missing")
	var inventory_id := int(request.get("inventory_id", 0))
	if inventory_id != int(_inventory_ids.get(seat_index, 0)):
		if inventory_id > 0 and inventory_id in _inventory_ids.values():
			return _network_rejection("other_seat_item")
		return _network_rejection("inventory_mismatch")
	if bool(inventory_used.get(seat_index, false)):
		return _network_rejection("inventory_used")
	var cursor: Dictionary = placement_controller.cursors[seat_index]
	var variant_key := str(cursor.variant_key)
	if not live_variant_allowed(variant_key):
		return _network_rejection("variant_disabled")
	var request_key := network_request_key(
		int(request.get("peer_generation", 0)), seat_index, int(request.get("request_id", 0))
	)
	var intent := {
		"request_id": request_key,
		"match_id": match_run_id,
		"round_id": items.round_number + 1,
		"attempt_id": request_pipeline.attempt_id,
		"observed_stage_version": int(request.get("expected_stage_version", -1)),
		"variant_key": variant_key,
		"objective": variant_key if _is_round_objective_variant(variant_key) else "",
		"cell": request.get("cell", Vector2i.ZERO),
		"quarter_turns": int(request.get("rotation", 0)),
	}
	var occupied: Array[int] = []
	for seat in input_router.registry.joined_seats():
		occupied.append(int(seat.seat))
	var receipt := request_pipeline.submit(
		intent, seat_index, receipt_usec, Engine.get_physics_frames() + 1, occupied
	)
	_notify_presentation(&"live_build")
	return receipt


static func network_request_key(
	peer_generation: int, seat_index: int, wire_request_id: int
) -> String:
	return "net:%d:%d:%d" % [peer_generation, seat_index, wire_request_id]


## Bounded per-seat view for LIVE_SEAT_STATE. Build mode, inventory and cursor are host-owned;
## the client only echoes them.
func live_seat_state_for(seat_index: int) -> Dictionary:
	var state := {
		"inventory_id": 0,
		"variant_key": "",
		"item_status": NetworkPlacementCodec.ItemStatus.NONE,
		"build_mode": false,
		"rotation": 0,
		"cursor": Vector2i.ZERO,
	}
	var live_phase := phase_controller.phase in [
		MatchPhaseController.Phase.GO, MatchPhaseController.Phase.PLAY
	]
	if not live_phase or not placement_controller.cursors.has(seat_index):
		return state
	var inventory_id := int(_inventory_ids.get(seat_index, 0))
	if inventory_id <= 0:
		return state
	var cursor: Dictionary = placement_controller.cursors[seat_index]
	var item_status := NetworkPlacementCodec.ItemStatus.AVAILABLE
	if bool(inventory_used.get(seat_index, false)):
		item_status = NetworkPlacementCodec.ItemStatus.USED
	elif request_pipeline.pending_by_seat.has(seat_index):
		item_status = NetworkPlacementCodec.ItemStatus.PENDING
	state.inventory_id = inventory_id
	state.variant_key = str(cursor.variant_key)
	state.item_status = item_status
	state.build_mode = bool(build_mode.get(seat_index, false))
	state.rotation = int(cursor.get("quarter_turns", 0)) & 3
	state.cursor = cursor.get("cell", Vector2i.ZERO)
	return state


## Drops a disconnected seat's queued request before validation. Its item is retained (nothing was
## committed) and the result is announced once with "seat_disconnected".
func network_cancel_seat(seat_index: int) -> Array:
	var results: Array = []
	for receipt in request_pipeline.cancel_seat(seat_index):
		var base := {
			"request_id": str(receipt.request_id),
			"seat_index": seat_index,
			"commit_boundary": Engine.get_physics_frames(),
			"stage_version": items.stage_version if items != null else 0,
		}
		results.append(_live_result(base, false, "seat_disconnected", "The seat disconnected."))
	build_mode[seat_index] = false
	_set_live_ghost_visible(seat_index, false)
	if not results.is_empty():
		live_placement_boundary_resolved.emit(results)
	return results


## Contract v1.4: every host-owned transient the clients must draw this tick. Projectiles,
## bubbles (with the captive seat) and mover positions are read from the shared item runtime;
## blast flashes come from live one-shot commits. Nothing here changes simulation state.
func network_transient_states() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var live_keys := {}
	if items != null:
		var ids: Array = items.pieces.keys()
		ids.sort()
		for instance_variant in ids:
			var instance_id := str(instance_variant)
			var piece := items.piece_for(instance_id) as HazardPiece
			if piece == null or piece.behavior == null:
				continue
			var owner_entity := network_entity_id_for(instance_id)
			var behavior := piece.behavior
			if behavior is LauncherBehavior:
				var launcher := behavior as LauncherBehavior
				var size := Vector2.ONE * tuning.item_launcher_projectile_size_wu
				for projectile in launcher.projectiles:
					var key := "p:%s:%d" % [instance_id, int(projectile.get("handle", -1))]
					live_keys[key] = true
					result.append(
						{
							"transient_kind": NetworkMatchCodec.TRANSIENT_PROJECTILE,
							"transient_id": _transient_id_for(key),
							"owner_entity": owner_entity,
							"position": projectile.center,
							"velocity": launcher.lane_dir * tuning.item_launcher_projectile_speed_wu_s,
							"extent": size,
							"owner_seat": launcher.owner_seat,
						}
					)
			elif behavior is BubbleBehavior and (behavior as BubbleBehavior).has_bubble():
				var bubble := behavior as BubbleBehavior
				var key := "b:%s" % instance_id
				live_keys[key] = true
				var captive_seat := -1
				if bubble.captive != null and is_instance_valid(bubble.captive):
					captive_seat = bubble.captive.seat_index
				result.append(
					{
						"transient_kind": NetworkMatchCodec.TRANSIENT_BUBBLE,
						"transient_id": _transient_id_for(key),
						"owner_entity": owner_entity,
						"position": bubble.bubble_center,
						"extent": Vector2.ONE * tuning.item_bubble_radius_wu * 2.0,
						"phase": int(bubble.state),
						"timer_ms": roundi(maxf(0.0, bubble.capture_left) * 1000.0),
						"owner_seat": bubble.owner_seat,
						"captive_seat": captive_seat,
					}
				)
			elif behavior is TrumpoBehavior:
				var trumpo := behavior as TrumpoBehavior
				var key := "m:%s" % instance_id
				live_keys[key] = true
				result.append(
					{
						"transient_kind": NetworkMatchCodec.TRANSIENT_MOVER,
						"transient_id": _transient_id_for(key),
						"owner_entity": owner_entity,
						"position": trumpo.top_center(),
						"extent": trumpo.current_rect.size,
						"phase": 1 if trumpo.paused_at_end else 0,
						"owner_seat": trumpo.owner_seat,
					}
				)
	var blast_ids: Array = _live_blasts.keys()
	blast_ids.sort()
	for blast_key in blast_ids:
		var blast: Dictionary = _live_blasts[blast_key]
		live_keys[blast_key] = true
		var area: Rect2 = blast.area
		result.append(
			{
				"transient_kind": NetworkMatchCodec.TRANSIENT_BLAST,
				"transient_id": _transient_id_for(str(blast_key)),
				"owner_entity": 0,
				"position": area.get_center(),
				"extent": area.size,
				"timer_ms": roundi(maxf(0.0, float(blast.remaining)) * 1000.0),
				"owner_seat": int(blast.owner_seat),
			}
		)
	for key in _transient_ids.keys():
		if not live_keys.has(key):
			_transient_ids.erase(key)
	return result


## Stable u16 wire ID per live transient key, released when the transient ends.
func _transient_id_for(key: String) -> int:
	if not _transient_ids.has(key):
		var in_use: Array = _transient_ids.values()
		_transient_serial = (_transient_serial % 0xffff) + 1
		while in_use.has(_transient_serial):
			_transient_serial = (_transient_serial % 0xffff) + 1
		_transient_ids[key] = _transient_serial
	return int(_transient_ids[key])


## Records a host blast flash for clients (live explosives and Walis), bounded by the VFX cap.
func _register_live_blast(area: Rect2, owner_seat: int) -> void:
	_blast_serial += 1
	_live_blasts["x:%d" % _blast_serial] = {
		"area": area, "remaining": LIVE_BLAST_SECONDS, "owner_seat": owner_seat
	}


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if get_tree().paused or _live_blasts.is_empty():
		return
	for blast_key in _live_blasts.keys():
		var blast: Dictionary = _live_blasts[blast_key]
		blast.remaining = float(blast.remaining) - delta
		if float(blast.remaining) <= 0.0:
			_live_blasts.erase(blast_key)


func _network_rejection(code: String) -> Dictionary:
	return {"status": "rejected", "code": code, "reason": code}


func reset_room() -> void:
	_inventory_ids.clear()
	_inventory_serial = 0
	_transient_ids.clear()
	_live_blasts.clear()
	super.reset_room()

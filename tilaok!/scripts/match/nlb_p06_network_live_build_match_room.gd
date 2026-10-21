# gdlint: disable=max-returns
class_name NLBP06NetworkLiveBuildMatchRoom
extends NLBP05LiveBuildMatchRoom

## Opt-in networked live-build route (`-- --match-route=network_live_build` on the PC host). The
## host room stays the only rules implementation. Remote peers send bounded placement intents that
## NetworkSessionManager hands to network_submit_placement(); they enter the same pipeline, receipt
## order and authority boundary as local keyboard/gamepad seats. Only the host commits terrain.

const NETWORK_PROFILE_ID := "nlb_p06_network_live_build"

## Host-issued inventory IDs for this round's assigned items (seat -> int, 0 = none). They are
## unique for the match so a stale or foreign ID can never match another seat's item.
var _inventory_ids: Dictionary = {}
var _inventory_serial := 0


func _init() -> void:
	profile_id = NETWORK_PROFILE_ID
	tuning.item_enabled_variants = LIVE_VARIANT_ALLOWLIST


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


func _network_rejection(code: String) -> Dictionary:
	return {"status": "rejected", "code": code, "reason": code}


func reset_room() -> void:
	_inventory_ids.clear()
	_inventory_serial = 0
	super.reset_room()

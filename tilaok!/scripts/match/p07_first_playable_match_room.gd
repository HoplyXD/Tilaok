class_name P07FirstPlayableMatchRoom
extends P05MatchRoom

const P07_BUILD_ID := "P07-first-playable-dev"
const P07_ALLOWED_VARIANTS: PackedStringArray = [
	"build.hollow_blocks.cell_1x1",
	"build.hollow_blocks.stack_2x3",
	"build.bamboo_bridge.span_4x1",
]

var reset_audit_rows: Array[Dictionary] = []


func _init() -> void:
	profile_id = "karera_slice"
	tuning.item_enabled_variants = P07_ALLOWED_VARIANTS.duplicate()


func _ready() -> void:
	super._ready()
	if _top_bar != null and _top_bar.get_child_count() > 0:
		var row := _top_bar.get_child(0) as HBoxContainer
		if row != null and row.get_child_count() > 0:
			(row.get_child(0) as Label).text = "TILAOK! • P07 FIRST PLAYABLE"
	print(
		(
			"P07_FIRST_PLAYABLE_READY build=%s profile=%s seed=%d variants=%s"
			% [P07_BUILD_ID, profile_id, match_seed, ",".join(tuning.item_enabled_variants)]
		)
	)


func _begin_pugad() -> void:
	super._begin_pugad()
	var pool_error := _validate_p07_egg_pool(egg_pool)
	if pool_error.is_empty():
		return
	push_error(pool_error)
	egg_pool.clear()
	phase_controller.enter(MatchPhaseController.Phase.LOBBY)
	_set_input_phase()
	last_message = pool_error
	_refresh_egg_cards()
	_refresh_match_ui()


func _validate_p07_egg_pool(pool: Array[Dictionary]) -> String:
	if pool.is_empty():
		return "P07 pool validation failed: no eligible Kaing/Tulay eggs were generated."
	for egg in pool:
		var variant_key := str(egg.get("variant_key", ""))
		if not P07_ALLOWED_VARIANTS.has(variant_key):
			return "P07 pool validation failed: unsupported variant '%s'." % variant_key
	return ""


func _update_diagnostics() -> void:
	super._update_diagnostics()
	for key in ["join_k1", "join_k2", "start"]:
		if _match_buttons.has(key):
			(_match_buttons[key] as Button).visible = false


func _on_match_action_pressed(seat_index: int, action_name: String) -> void:
	var was_lobby := phase_controller.phase == MatchPhaseController.Phase.LOBBY
	super._on_match_action_pressed(seat_index, action_name)
	if was_lobby and action_name == "ready" and LobbyViewModel.can_start(input_router.registry):
		start_match()


func _phase_hint() -> String:
	if phase_controller.phase == MatchPhaseController.Phase.LOBBY:
		return "Keyboard: F / Enter joins, then readies · Controller: A joins, press A again to ready"
	return super._phase_hint()


func _start_next_round() -> void:
	if phase_controller.phase != MatchPhaseController.Phase.RESULTS:
		super._start_next_round()
		return
	var before := _reset_snapshot()
	super._start_next_round()
	var after := _reset_snapshot()
	var row := {
		"transition": reset_audit_rows.size() + 1,
		"before": before,
		"after": after,
		"construction_preserved": before.item_ids == after.item_ids,
		"signature_preserved": before.signature == after.signature,
		"scores_preserved": before.scores == after.scores,
		"actors_reset": _all_actors_active(),
		"transients_cleared": int(after.transients) == 0,
	}
	reset_audit_rows.append(row)
	print("P07_RESET_AUDIT %s" % JSON.stringify(row))


func reset_room() -> void:
	super.reset_room()
	reset_audit_rows.clear()


func _reset_snapshot() -> Dictionary:
	var item_ids: Array[String] = []
	if items != null:
		for item_id in items.pieces.keys():
			item_ids.append(str(item_id))
	item_ids.sort()
	return {
		"round": items.round_number if items != null else -1,
		"item_count": items.persistent_count() if items != null else 0,
		"item_ids": item_ids,
		"signature": items.construction_signature() if items != null else "",
		"scores": cumulative_score_units.duplicate(true),
		"actor_statuses": _actor_statuses(),
		"transients": items.budget.total_count() if items != null else -1,
		"pending_claims": pending_claims.size(),
		"race_candidates": race_candidate_queue.candidates.size(),
	}


func _actor_statuses() -> Dictionary:
	var statuses := {}
	for seat_index in actors:
		var actor := actors[seat_index] as ChickenController
		statuses[str(seat_index)] = (
			str(PlayerLifecycleState.Status.keys()[actor.lifecycle.status])
			if actor != null and is_instance_valid(actor)
			else "MISSING"
		)
	return statuses


func _all_actors_active() -> bool:
	for actor_variant in actors.values():
		var actor := actor_variant as ChickenController
		if (
			actor == null
			or not is_instance_valid(actor)
			or actor.lifecycle.status != PlayerLifecycleState.Status.ACTIVE
		):
			return false
	return true

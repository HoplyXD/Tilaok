class_name P07FirstPlayableMatchRoom
extends P05MatchRoom

const P07_BUILD_ID := "P07-first-playable-dev"

var reset_audit_rows: Array[Dictionary] = []


func _init() -> void:
	profile_id = "karera_slice"
	tuning.item_enabled_variants = allowed_variants()
	# The route starts from player-ready input; there is no Start click (see the base room).
	auto_start_on_ready = true


## The match's egg pool: every main-game block scene marked "enabled by default" (BlockCatalog),
## so new blocks dropped into scenes/blocks/ reach the selector without a code change.
static func allowed_variants() -> PackedStringArray:
	return BlockCatalog.default_enabled_keys()


func _ready() -> void:
	super._ready()
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
	_notify_presentation(&"eggs")
	_refresh_match_ui()


func _validate_p07_egg_pool(pool: Array[Dictionary]) -> String:
	if pool.is_empty():
		return "P07 pool validation failed: no eligible block eggs were generated."
	var allowed := allowed_variants()
	for egg in pool:
		var variant_key := str(egg.get("variant_key", ""))
		if not allowed.has(variant_key) and not _is_round_objective_variant(variant_key):
			return "P07 pool validation failed: unsupported variant '%s'." % variant_key
	return ""


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

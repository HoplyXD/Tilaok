# gdlint: disable=max-returns,max-public-methods
class_name ItemManager
extends Node

## Owns persistent construction pieces: placement, removal (the Walis Cleanup hook), the
## inert-in-Place / reset-at-Play lifecycle, caps and teardown. P05 replaces the immediate
## placement call with the atomic Place resolver; the lifecycle contract stays the same.

signal item_placed(instance_id: String)
signal item_removed(instance_id: String, reason: String)

var tuning: GameplayTuning
var authority := SimulationAuthority.offline():
	set(value):
		authority = value
		if budget != null:
			budget.authority = value
var arena: ArenaDefinition
var support_tracker: SupportTracker
var definitions: ItemDefinitions
var budget := TransientBudget.new()
## Returns {seat_index: ChickenController}; rooms set it so hazards see the live actors.
var actors_source := Callable()
var director: ItemHazardDirector
var world_parent: Node
var pieces: Dictionary = {}
var in_play := false
var grace_remaining := 0.0
## Advances only when persistent terrain changes; objectives and rejected previews do not count.
var stage_version := 0
## instance_id -> {remaining, held}; newly placed live items activate independently.
var live_activation: Dictionary = {}
var live_activation_grace_seconds := 1.0
var live_actor_clearance_wu := 32.0
## Live route entity age (NLB-P07, NETWORKED_LIVE_BUILD.md §6.2): the authority boundary being
## resolved, and the boundary each live piece was committed at. A one-shot edit only affects
## pieces committed at an earlier boundary; pieces with no entry are older (Place or earlier round).
var live_boundary := -1
var live_commit_boundary: Dictionary = {}
var round_number := 0
var _serial := 1
var _defer_stage_version := false


func configure(
	source_tuning: GameplayTuning,
	source_arena: ArenaDefinition,
	source_tracker: SupportTracker,
	source_definitions: ItemDefinitions,
	parent_for_pieces: Node,
	source_authority: SimulationAuthority = null
) -> void:
	if source_authority != null:
		authority = source_authority
	if not _can_mutate():
		return
	tuning = source_tuning
	arena = source_arena
	support_tracker = source_tracker
	definitions = source_definitions
	world_parent = parent_for_pieces
	budget.authority = authority
	budget.configure(tuning)
	if director != null and is_instance_valid(director):
		director.queue_free()
	director = ItemHazardDirector.new()
	add_child(director)
	director.configure(self)


func _exit_tree() -> void:
	teardown()


func _physics_process(delta: float) -> void:
	if not in_play or authority == null or not authority.can_commit():
		return
	if grace_remaining > 0.0:
		grace_remaining = maxf(0.0, grace_remaining - delta)
	_advance_live_activation(delta)
	budget.advance(delta)


func is_active() -> bool:
	return in_play and grace_remaining <= 0.0


func persistent_count() -> int:
	return pieces.size()


func validate_placement(
	variant_key: String, origin_cell: Vector2i, quarter_turns: int, actor_rects: Array[Rect2] = []
) -> Dictionary:
	return ItemPlacementValidator.validate(
		definitions,
		arena,
		tuning,
		variant_key,
		origin_cell,
		quarter_turns,
		pieces.values(),
		actor_rects
	)


func place(
	variant_key: String,
	origin_cell: Vector2i,
	quarter_turns: int,
	owner_seat: int,
	actor_rects: Array[Rect2] = []
) -> Dictionary:
	if not _can_mutate():
		return {"allowed": false, "code": "authority_denied", "reason": "Not authoritative."}
	if in_play:
		return {
			"allowed": false,
			"code": "wrong_phase",
			"reason": "Construction is only placed during Place.",
		}
	var result := validate_placement(variant_key, origin_cell, quarter_turns, actor_rects)
	if not bool(result.allowed):
		return result
	if bool(result.get("one_shot", false)):
		return _apply_one_shot(result, owner_seat)
	var placed := _materialize_placement(
		variant_key, origin_cell, quarter_turns, owner_seat, result
	)
	if bool(placed.get("allowed", false)) and not _defer_stage_version:
		stage_version += 1
	return placed


## Live route entry: reuses catalog validation, but materializes without resetting any existing
## items. The caller has already verified attempt, ownership and current phase.
func place_live(
	variant_key: String,
	origin_cell: Vector2i,
	quarter_turns: int,
	owner_seat: int,
	actor_rects: Array[Rect2] = [],
	advance_version: bool = true
) -> Dictionary:
	if not _can_mutate():
		return {"allowed": false, "code": "authority_denied", "reason": "Not authoritative."}
	if not in_play:
		return {"allowed": false, "code": "wrong_phase", "reason": "Live placement is closed."}
	var result := validate_placement(
		variant_key, origin_cell, quarter_turns, owner_seat_clearance(actor_rects)
	)
	if not bool(result.allowed):
		return result
	if bool(result.get("one_shot", false)):
		return {
			"allowed": false,
			"code": "one_shot_unsupported",
			"reason": "This item uses a round objective path."
		}
	var committed := _materialize_placement(
		variant_key, origin_cell, quarter_turns, owner_seat, result
	)
	if not bool(committed.get("allowed", false)):
		return committed
	var instance_id := str(committed.instance_id)
	var piece := piece_for(instance_id)
	if piece != null and piece.has_method("set_block_active"):
		piece.call("set_block_active", false)
	live_activation[instance_id] = {"remaining": live_activation_grace_seconds, "held": false}
	live_commit_boundary[instance_id] = live_boundary
	if advance_version:
		stage_version += 1
	committed["stage_version"] = stage_version
	committed["activation_after_seconds"] = live_activation_grace_seconds
	return committed


## Live one-shot commit (Walis Cleanup and, since NLB-P07, Bomb/Dynamite/Nuke) derives its target
## set again from the current world. Every surface is preflighted before support invalidation or
## removal, so a stale preview cannot remove new pieces. There is no shared Place batch on the live
## route, so the offline same-Place blast rule does not apply: a piece committed at an earlier
## authority boundary (this round or before) is eligible if removable; edits of this same boundary
## and requests still pending are never touched. Protected base/spawn/goal geometry is never a
## target; as offline, it is excluded from the edit rather than refusing it.
func apply_live_one_shot(
	verdict: Dictionary, owner_seat: int, advance_version: bool = false
) -> Dictionary:
	if not _can_mutate() or not in_play:
		return {"allowed": false, "code": "wrong_phase", "reason": "Live cleanup is closed."}
	if not bool(verdict.get("allowed", false)) or not bool(verdict.get("one_shot", false)):
		return {
			"allowed": false, "code": "invalid_cleanup", "reason": "Cleanup preview is invalid."
		}
	var target_info := CleanupTargetResolver.resolve(
		verdict.footprint, pieces.values(), arena, round_number
	)
	var candidates: Array = []
	candidates.append_array(target_info.get("ids", []))
	for same_variant in target_info.get("same_phase", []):
		var same_id := str(same_variant)
		if (
			int(live_commit_boundary.get(same_id, live_boundary)) < live_boundary
			and bool(arena.can_remove_surface(same_id).get("allowed", false))
		):
			candidates.append(same_id)
	var protected_rects: Array = target_info.get("protected", [])
	var target_ids: Array[String] = []
	for target_variant in candidates:
		var target_id := str(target_variant)
		if not pieces.has(target_id):
			return {
				"allowed": false,
				"code": "stale_target",
				"reason": "A cleanup target changed before commit."
			}
		var removal := arena.can_remove_surface(target_id)
		if not bool(removal.get("allowed", false)):
			return {
				"allowed": false,
				"code": "unsafe_support",
				"reason": str(removal.get("reason", "Removing that support is unsafe."))
			}
		target_ids.append(target_id)
	target_ids.sort()
	var removed: Array[String] = []
	_defer_stage_version = true
	for target_id in target_ids:
		if bool(remove(target_id, "live_walis_cleanup", true).get("allowed", false)):
			removed.append(target_id)
	_defer_stage_version = false
	if not removed.is_empty() and advance_version:
		stage_version += 1
	return {
		"allowed": true,
		"code": "one_shot",
		"reason": "Cleanup removed %d piece(s)." % removed.size(),
		"one_shot": true,
		"owner_seat": owner_seat,
		"removed": removed,
		"protected_excluded": protected_rects.size(),
		"edit_id":
		"walis:%d:%d" % [round_number, stage_version + (1 if not removed.is_empty() else 0)],
	}


func owner_seat_clearance(actor_rects: Array[Rect2]) -> Array[Rect2]:
	var safe_rects: Array[Rect2] = []
	for rect in actor_rects:
		safe_rects.append(rect.grow(live_actor_clearance_wu))
	return safe_rects


## Applies one already-resolved P05 batch. All removals and additions are preflighted before
## mutating the live stage; IDs and materialization follow the resolver's stable seat order.
func commit_batch(resolution: Dictionary, actor_rects: Array[Rect2] = []) -> Dictionary:
	if not _can_mutate():
		return {"allowed": false, "reason": "Not authoritative."}
	if in_play:
		return {"allowed": false, "reason": "Construction is only committed during Place."}
	if not bool(resolution.get("allowed", false)):
		return {"allowed": false, "reason": "Resolver did not provide an allowed batch."}
	var removal_ids: Array[String] = []
	for target_variant in resolution.get("removals", []):
		var target_id := str(target_variant)
		if target_id not in removal_ids:
			removal_ids.append(target_id)
	removal_ids.sort()
	var removed_records: Array[PlacedItem] = []
	var existing_after_removal: Array[PlacedItem] = []
	for target_id in removal_ids:
		if not pieces.has(target_id):
			return {"allowed": false, "reason": "Cleanup target disappeared: %s" % target_id}
		var removal_verdict := arena.can_remove_surface(target_id)
		if not bool(removal_verdict.allowed):
			return {"allowed": false, "reason": "Cleanup rejected: %s" % removal_verdict.reason}
		removed_records.append(pieces[target_id] as PlacedItem)
	for instance_id in _sorted_ids():
		if instance_id not in removal_ids:
			existing_after_removal.append(pieces[instance_id] as PlacedItem)
	var commits: Array = resolution.get("commits", [])
	var preflight_existing := existing_after_removal.duplicate()
	var checked_commits: Array[Dictionary] = []
	for edit_variant in commits:
		var edit := (edit_variant as Dictionary).duplicate(true)
		var verdict := ItemPlacementValidator.validate(
			definitions,
			arena,
			tuning,
			str(edit.get("variant_key", "")),
			edit.get("origin_cell", Vector2i.ZERO),
			int(edit.get("quarter_turns", 0)),
			preflight_existing,
			actor_rects
		)
		if not bool(verdict.allowed):
			return {"allowed": false, "reason": "Batch preflight rejected: %s" % verdict.reason}
		var found := definitions.find_variant(str(edit.variant_key))
		var family := found.family as ItemFamilyDefinition
		var placeholder := PlacedItem.new()
		placeholder.instance_id = "preflight:%d" % checked_commits.size()
		placeholder.family_id = family.family_id
		placeholder.variant_key = str(edit.variant_key)
		placeholder.origin_cell = edit.origin_cell
		placeholder.quarter_turns = ItemGeometry.normalized_turns(int(edit.quarter_turns))
		placeholder.owner_seat = int(edit.seat_index)
		placeholder.placed_round = round_number
		placeholder.footprint_rect = verdict.footprint
		placeholder.occupied_rects = verdict.occupied
		preflight_existing.append(placeholder)
		checked_commits.append(edit)
	_defer_stage_version = true
	for target_id in removal_ids:
		var removed := remove(target_id, "p05_atomic_cleanup")
		if not bool(removed.allowed):
			_defer_stage_version = false
			return {
				"allowed": false, "reason": "Cleanup failed after preflight: %s" % removed.reason
			}
	var materialized: Array[Dictionary] = []
	for edit in checked_commits:
		var verdict := ItemPlacementValidator.validate(
			definitions,
			arena,
			tuning,
			str(edit.variant_key),
			edit.origin_cell,
			int(edit.quarter_turns),
			pieces.values(),
			actor_rects
		)
		var result := _materialize_placement(
			str(edit.variant_key),
			edit.origin_cell,
			int(edit.quarter_turns),
			int(edit.seat_index),
			verdict
		)
		if not bool(result.get("allowed", false)):
			_defer_stage_version = false
			push_error(
				"P05 batch materialization failed after preflight: %s" % result.get("reason", "")
			)
			return {"allowed": false, "reason": "Batch materialization failed; see engine output."}
		materialized.append(result)
	_defer_stage_version = false
	if not removal_ids.is_empty() or not materialized.is_empty():
		stage_version += 1
	return {
		"allowed": true,
		"removals": removal_ids,
		"commits": materialized,
		"one_shot_edits": resolution.get("one_shot_edits", []),
	}


## Immediate Walis path (Item Lab / Visualizer): one removal set from the current snapshot.
func _apply_one_shot(verdict: Dictionary, owner_seat: int) -> Dictionary:
	var target_info := CleanupTargetResolver.resolve(
		verdict.footprint, pieces.values(), arena, round_number
	)
	var removed: Array[String] = []
	_defer_stage_version = true
	for target_id in target_info.ids:
		if bool(remove(str(target_id), "walis_cleanup").allowed):
			removed.append(str(target_id))
	_defer_stage_version = false
	if not removed.is_empty():
		stage_version += 1
	return {
		"allowed": true,
		"code": "one_shot",
		"reason": "Cleanup removed %d piece(s)." % removed.size(),
		"one_shot": true,
		"owner_seat": owner_seat,
		"removed": removed,
		"same_phase": target_info.same_phase,
		"protected": target_info.protected,
	}


func _materialize_placement(
	variant_key: String,
	origin_cell: Vector2i,
	quarter_turns: int,
	owner_seat: int,
	result: Dictionary
) -> Dictionary:
	var found := definitions.find_variant(variant_key)
	var family := found.family as ItemFamilyDefinition
	var variant := found.variant as ItemVariantDefinition
	var turns := ItemGeometry.normalized_turns(quarter_turns)
	var record := PlacedItem.new()
	record.instance_id = "%s#%03d" % [variant_key, _serial]
	record.family_id = family.family_id
	record.variant_key = variant_key
	record.origin_cell = origin_cell
	record.quarter_turns = turns
	record.owner_seat = owner_seat
	record.placed_round = round_number
	record.footprint_rect = result.footprint
	record.occupied_rects = result.get("occupied", [])
	var metadata := SupportSurfaceMetadata.new()
	metadata.surface_id = record.instance_id
	metadata.construction_id = record.instance_id
	metadata.player_built = true
	metadata.wave_support_eligibility = (
		SupportSurfaceMetadata.Eligibility.INELIGIBLE
		if family.support_role == ItemFamilyDefinition.SUPPORT_ROLE_NONE
		else SupportSurfaceMetadata.Eligibility.ELIGIBLE
	)
	# Wall slide/jump eligibility is explicit and independent of wave support (fail closed).
	metadata.wall_movement_eligibility = (
		SupportSurfaceMetadata.Eligibility.ELIGIBLE
		if family.wall_contact == ItemFamilyDefinition.WALL_ELIGIBLE
		else SupportSurfaceMetadata.Eligibility.INELIGIBLE
	)
	if not arena.register_player_construction(record.instance_id):
		return {"allowed": false, "code": "duplicate", "reason": "Duplicate construction ID."}
	if not support_tracker.register_surface(metadata):
		arena.unregister_player_construction(record.instance_id)
		return {"allowed": false, "code": "metadata", "reason": "Support metadata rejected."}
	_serial += 1
	var piece := _instantiate_piece(family, variant)
	if piece == null:
		arena.unregister_player_construction(record.instance_id)
		support_tracker.invalidate_surface(record.instance_id)
		return {"allowed": false, "code": "scene", "reason": "Block scene could not be loaded."}
	if piece is ConstructionPiece:
		(piece as ConstructionPiece).simulation_authority = authority
	# A block that overrides tuning (e.g. a faster cannon) gets its own copy for its behavior.
	var piece_tuning := tuning
	if not variant.tuning_overrides.is_empty():
		piece_tuning = tuning.duplicate() as GameplayTuning
		for field in variant.tuning_overrides:
			piece_tuning.set(field, variant.tuning_overrides[field])
	var regions := ItemGeometry.clip_to_stage(
		ItemGeometry.resolve_regions(variant, turns, tuning), record.footprint_rect, arena
	)
	piece.call("configure", record, regions, metadata, family.wall_contact, piece_tuning)
	var behavior := ItemBehaviorFactory.create_for(family)
	if behavior != null and piece is HazardPiece:
		behavior.stun_seconds = float(variant.effect_params.get("stun_seconds", 1.0))
		behavior.stun_knockback_wu_s = float(
			variant.effect_params.get("stun_knockback_wu_s", 480.0)
		)
		behavior.configure(record, regions, piece_tuning)
		(piece as HazardPiece).attach_behavior(family, variant, behavior, piece_tuning)
	if piece.has_method("set_block_active"):
		piece.call("set_block_active", in_play)
	record.node = piece
	pieces[record.instance_id] = record
	world_parent.add_child(piece)
	item_placed.emit(record.instance_id)
	result["instance_id"] = record.instance_id
	return result


## Every variant is a block scene in scenes/blocks/ (BlockCatalog records its path).
func _instantiate_piece(_family: ItemFamilyDefinition, variant: ItemVariantDefinition) -> Node2D:
	if variant.scene_path.is_empty():
		return null
	var packed := load(variant.scene_path) as PackedScene
	return packed.instantiate() as Node2D if packed != null else null


## The removal API Walis Cleanup (P10) will call. force is for reset/teardown only.
func remove(instance_id: String, reason: String, force: bool = false) -> Dictionary:
	if not _can_mutate():
		return {"allowed": false, "code": "authority_denied", "reason": "Not authoritative."}
	if not pieces.has(instance_id):
		return {"allowed": false, "code": "unknown_item", "reason": "No such construction."}
	if in_play and not force:
		return {
			"allowed": false,
			"code": "wrong_phase",
			"reason": "Construction is only removed during Place.",
		}
	var verdict := arena.can_remove_surface(instance_id)
	if not bool(verdict.allowed):
		return {"allowed": false, "code": "not_removable", "reason": str(verdict.reason)}
	var record := pieces[instance_id] as PlacedItem
	if director != null:
		director.on_item_removed(instance_id)
	# Invalidate support before the node leaves the tree so no step evaluates a stale contact.
	support_tracker.invalidate_surface(instance_id)
	arena.unregister_player_construction(instance_id)
	pieces.erase(instance_id)
	live_activation.erase(instance_id)
	live_commit_boundary.erase(instance_id)
	budget.release_emitter(instance_id)
	var node := record.node
	record.node = null
	if node != null and is_instance_valid(node):
		var parent := node.get_parent()
		if parent != null:
			parent.remove_child(node)
		node.queue_free()
	item_removed.emit(instance_id, reason)
	if not _defer_stage_version:
		stage_version += 1
	return {"allowed": true, "code": "removed", "reason": "Removed."}


func enter_place() -> void:
	if not _can_mutate():
		return
	in_play = false
	grace_remaining = 0.0
	live_activation.clear()
	_set_blocks_active(false)


## Deterministic Play start: static construction has nothing to restore; movers reset here.
func begin_play() -> PackedStringArray:
	if not _can_mutate():
		return PackedStringArray()
	in_play = true
	grace_remaining = tuning.item_activation_grace_s
	live_activation.clear()
	director.release_all_captives()
	var released := budget.clear_all()
	director.reset_for_play()
	for instance_id in _sorted_ids():
		var piece := (pieces[instance_id] as PlacedItem).node
		if piece != null and piece.has_method("reset_to_start"):
			piece.call("reset_to_start")
		if piece is HazardPiece:
			(piece as HazardPiece).set_animating(true)
	_set_blocks_active(true)
	return released


## Round end: transients and captives clear; placed construction persists.
func end_round() -> PackedStringArray:
	if not _can_mutate():
		return PackedStringArray()
	var released := end_play_attempt()
	round_number += 1
	return released


## Ends an extra mode attempt without advancing ItemManager's completed match-round counter.
func end_play_attempt() -> PackedStringArray:
	if not _can_mutate():
		return PackedStringArray()
	in_play = false
	grace_remaining = 0.0
	live_activation.clear()
	director.release_all_captives()
	for instance_id in _sorted_ids():
		var piece := (pieces[instance_id] as PlacedItem).node as HazardPiece
		if piece != null:
			piece.set_animating(false)
	_set_blocks_active(false)
	return budget.clear_all()


## Match reset: construction is removed, counters restart, transients clear.
func reset_match() -> PackedStringArray:
	if not _can_mutate():
		return PackedStringArray()
	if director != null:
		director.release_all_captives()
	var released := budget.clear_all()
	for instance_id in _sorted_ids():
		remove(instance_id, "match_reset", true)
	in_play = false
	grace_remaining = 0.0
	round_number = 0
	stage_version = 0
	live_activation.clear()
	live_commit_boundary.clear()
	live_boundary = -1
	_serial = 1
	return released


func teardown() -> void:
	if tuning == null or arena == null or support_tracker == null:
		return
	reset_match()


func construction_signature() -> String:
	var rows := PackedStringArray()
	for instance_id in _sorted_ids():
		rows.append((pieces[instance_id] as PlacedItem).signature())
	return "\n".join(rows)


func piece_for(instance_id: String) -> ConstructionPiece:
	if not pieces.has(instance_id):
		return null
	return (pieces[instance_id] as PlacedItem).node as ConstructionPiece


## Any placed node (every placed block is a StageBlock, which is a ConstructionPiece).
func node_for(instance_id: String) -> Node2D:
	if not pieces.has(instance_id):
		return null
	return (pieces[instance_id] as PlacedItem).node as Node2D


## Stage blocks (wood box, collapsing block) only simulate during Play; Place restores them.
func _set_blocks_active(enabled: bool) -> void:
	for instance_id in _sorted_ids():
		var piece := (pieces[instance_id] as PlacedItem).node
		if piece == null or not piece.has_method("set_block_active"):
			continue
		if not enabled and piece.has_method("reset_to_start"):
			piece.call("reset_to_start")
		piece.call("set_block_active", enabled)


func item_activation_ready(instance_id: String) -> bool:
	return not live_activation.has(instance_id)


func live_activation_warning_text() -> String:
	for state_variant in live_activation.values():
		if bool((state_variant as Dictionary).get("held", false)):
			return "Placement warning • area occupied; item remains inactive."
	return ""


func _advance_live_activation(delta: float) -> void:
	if live_activation.is_empty():
		return
	var actors: Dictionary = actors_source.call() if actors_source.is_valid() else {}
	for instance_id_variant in live_activation.keys():
		var instance_id := str(instance_id_variant)
		if not pieces.has(instance_id):
			live_activation.erase(instance_id)
			continue
		var record := pieces[instance_id] as PlacedItem
		var danger := record.footprint_rect.grow(live_actor_clearance_wu)
		var found := definitions.find_variant(record.variant_key)
		if not found.is_empty():
			var variant := found.variant as ItemVariantDefinition
			var regions := ItemGeometry.clip_to_stage(
				ItemGeometry.resolve_regions(variant, record.quarter_turns, tuning),
				record.footprint_rect,
				arena
			)
			for region in regions:
				var effect_rect: Rect2 = region.rect
				effect_rect.position += record.footprint_rect.position
				danger = danger.merge(effect_rect.grow(live_actor_clearance_wu))
		var occupied := false
		for actor_variant in actors.values():
			var actor := actor_variant as ChickenController
			if actor == null or not is_instance_valid(actor) or actor.lifecycle.is_terminal():
				continue
			if danger.intersects(actor.hit_rect(), false):
				occupied = true
				break
		if not occupied:
			occupied = _live_mover_occupies_danger(instance_id, danger)
		var state: Dictionary = live_activation[instance_id]
		if occupied:
			state.remaining = live_activation_grace_seconds
			state.held = true
		else:
			if bool(state.held):
				state.held = false
				state.remaining = live_activation_grace_seconds
			state.remaining = maxf(0.0, float(state.remaining) - delta)
			if float(state.remaining) <= 0.0:
				var piece := record.node
				if piece != null and piece.has_method("set_block_active"):
					piece.call("set_block_active", true)
				live_activation.erase(instance_id)
				continue
		live_activation[instance_id] = state


func _live_mover_occupies_danger(activating_id: String, danger: Rect2) -> bool:
	for other_id_variant in pieces.keys():
		var other_id := str(other_id_variant)
		if other_id == activating_id:
			continue
		var other_record := pieces[other_id] as PlacedItem
		var mover := other_record.node as StageBlock if other_record.node is StageBlock else null
		if mover == null or (not mover.is_dynamic() and not mover.is_pushable()):
			continue
		var colliders := mover.find_children("*", "CollisionShape2D", true, false)
		if colliders.is_empty():
			# Fail closed while a mover's live collision geometry cannot be inspected.
			return true
		for collider_variant in colliders:
			var collider := collider_variant as CollisionShape2D
			if collider.disabled or collider.shape == null:
				continue
			var live_rect: Rect2 = collider.global_transform * collider.shape.get_rect()
			var swept_rect := live_rect
			swept_rect.position += mover.velocity * 0.5
			if danger.intersects(live_rect.merge(swept_rect), false):
				return true
	return false


func _sorted_ids() -> Array:
	var ids: Array = pieces.keys()
	ids.sort()
	return ids


func _can_mutate() -> bool:
	return authority != null and authority.can_commit()

# gdlint: disable=max-returns
class_name ItemManager
extends Node

## Owns persistent construction pieces: placement, removal (the Walis Cleanup hook), the
## inert-in-Place / reset-at-Play lifecycle, caps and teardown. P05 replaces the immediate
## placement call with the atomic Place resolver; the lifecycle contract stays the same.

signal item_placed(instance_id: String)
signal item_removed(instance_id: String, reason: String)

const PIECE_SCENES := {
	"build.hollow_blocks": preload("res://scenes/items/kaing_piece.tscn"),
	"build.bamboo_bridge": preload("res://scenes/items/tulay_piece.tscn"),
}

var tuning: GameplayTuning
var arena: ArenaDefinition
var support_tracker: SupportTracker
var definitions: ItemDefinitions
var budget := TransientBudget.new()
var world_parent: Node
var pieces: Dictionary = {}
var in_play := false
var grace_remaining := 0.0
var round_number := 0
var _serial := 1


func configure(
	source_tuning: GameplayTuning,
	source_arena: ArenaDefinition,
	source_tracker: SupportTracker,
	source_definitions: ItemDefinitions,
	parent_for_pieces: Node
) -> void:
	tuning = source_tuning
	arena = source_arena
	support_tracker = source_tracker
	definitions = source_definitions
	world_parent = parent_for_pieces
	budget.configure(tuning)


func _exit_tree() -> void:
	teardown()


func _physics_process(delta: float) -> void:
	if not in_play:
		return
	if grace_remaining > 0.0:
		grace_remaining = maxf(0.0, grace_remaining - delta)
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
	if in_play:
		return {
			"allowed": false,
			"code": "wrong_phase",
			"reason": "Construction is only placed during Place.",
		}
	var result := validate_placement(variant_key, origin_cell, quarter_turns, actor_rects)
	if not bool(result.allowed):
		return result
	return _materialize_placement(variant_key, origin_cell, quarter_turns, owner_seat, result)


## Applies one already-resolved P05 batch. All removals and additions are preflighted before
## mutating the live stage; IDs and materialization follow the resolver's stable seat order.
func commit_batch(resolution: Dictionary, actor_rects: Array[Rect2] = []) -> Dictionary:
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
		preflight_existing.append(placeholder)
		checked_commits.append(edit)
	for target_id in removal_ids:
		var removed := remove(target_id, "p05_atomic_cleanup")
		if not bool(removed.allowed):
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
			push_error(
				"P05 batch materialization failed after preflight: %s" % result.get("reason", "")
			)
			return {"allowed": false, "reason": "Batch materialization failed; see engine output."}
		materialized.append(result)
	return {"allowed": true, "removals": removal_ids, "commits": materialized}


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
	var metadata := SupportSurfaceMetadata.new()
	metadata.surface_id = record.instance_id
	metadata.construction_id = record.instance_id
	metadata.player_built = true
	metadata.wave_support_eligibility = SupportSurfaceMetadata.Eligibility.ELIGIBLE
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
	var piece := (PIECE_SCENES[family.family_id] as PackedScene).instantiate() as ConstructionPiece
	piece.configure(
		record,
		ItemGeometry.resolve_regions(variant, turns, tuning),
		metadata,
		family.wall_contact,
		tuning
	)
	record.node = piece
	pieces[record.instance_id] = record
	world_parent.add_child(piece)
	item_placed.emit(record.instance_id)
	result["instance_id"] = record.instance_id
	return result


## The removal API Walis Cleanup (P10) will call. force is for reset/teardown only.
func remove(instance_id: String, reason: String, force: bool = false) -> Dictionary:
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
	# Invalidate support before the node leaves the tree so no step evaluates a stale contact.
	support_tracker.invalidate_surface(instance_id)
	arena.unregister_player_construction(instance_id)
	pieces.erase(instance_id)
	budget.release_emitter(instance_id)
	var node := record.node
	record.node = null
	if node != null and is_instance_valid(node):
		var parent := node.get_parent()
		if parent != null:
			parent.remove_child(node)
		node.queue_free()
	item_removed.emit(instance_id, reason)
	return {"allowed": true, "code": "removed", "reason": "Removed."}


func enter_place() -> void:
	in_play = false
	grace_remaining = 0.0


## Deterministic Play start: static construction has nothing to restore; movers reset here.
func begin_play() -> PackedStringArray:
	in_play = true
	grace_remaining = tuning.item_activation_grace_s
	var released := budget.clear_all()
	for instance_id in _sorted_ids():
		var piece := (pieces[instance_id] as PlacedItem).node as ConstructionPiece
		if piece != null:
			piece.reset_to_start()
	return released


## Round end: transients and captives clear; placed construction persists.
func end_round() -> PackedStringArray:
	in_play = false
	grace_remaining = 0.0
	round_number += 1
	return budget.clear_all()


## Match reset: construction is removed, counters restart, transients clear.
func reset_match() -> PackedStringArray:
	var released := budget.clear_all()
	for instance_id in _sorted_ids():
		remove(instance_id, "match_reset", true)
	in_play = false
	grace_remaining = 0.0
	round_number = 0
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


func _sorted_ids() -> Array:
	var ids: Array = pieces.keys()
	ids.sort()
	return ids

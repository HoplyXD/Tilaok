class_name ItemPlacementValidator
extends RefCounted

## Placement validity for one construction piece against a stage snapshot.
## Only the variant footprint occupies cells; sweep, lane and effect regions never do.

const REASON_TEXT := {
	"unknown_variant": "Unknown item variant. Pick one from the approved list.",
	"variant_disabled": "This variant is not enabled in the current pool.",
	"rotation_unsupported": "This variant cannot face that way. Rotate to a supported direction.",
	"persistent_cap": "Construction limit reached. Remove a piece first.",
	"out_of_bounds": "Outside the arena. Move it inside the stage.",
	"protected_spawn": "Spawn area is protected. Move it right of the spawn zone.",
	"protected_goal": "Goal area is protected. Move it away from the flag platform.",
	"outside_build_region": "Outside the build region. Move it inside the green area.",
	"immutable_base": "Overlaps stage ground. Move it into open space.",
	"player_clearance": "A chicken is too close. Wait for them to move or pick another cell.",
	"item_overlap": "Overlaps another piece. Move it into a free cell.",
	"invalid_region": "The region has no size. This is a definition defect.",
}

const ARENA_REASON_CODES := {
	"outside arena bounds": "out_of_bounds",
	"protected spawn zone": "protected_spawn",
	"protected goal zone": "protected_goal",
	"outside build region": "outside_build_region",
	"player clearance": "player_clearance",
	"region must have positive dimensions": "invalid_region",
}


## existing: Array of PlacedItem. actor_rects: living player body rects.
static func validate(
	definitions: ItemDefinitions,
	arena: ArenaDefinition,
	tuning: GameplayTuning,
	variant_key: String,
	origin_cell: Vector2i,
	quarter_turns: int,
	existing: Array,
	actor_rects: Array[Rect2] = []
) -> Dictionary:
	var found := definitions.find_variant(variant_key)
	if found.is_empty():
		return _reject("unknown_variant")
	if not definitions.is_variant_enabled(variant_key):
		return _reject("variant_disabled")
	var variant := found.variant as ItemVariantDefinition
	var turns := ItemGeometry.normalized_turns(quarter_turns)
	if not variant.rotations.has(turns):
		return _reject("rotation_unsupported")
	if variant.gated_rotations.has(turns) and not tuning.item_tulay_vertical_enabled:
		return _reject("rotation_unsupported")
	var family := found.family as ItemFamilyDefinition
	if existing.size() >= tuning.item_persistent_cap and not family.one_shot_edit:
		return _reject("persistent_cap")
	var footprint := footprint_rect_for(variant, origin_cell, turns, tuning)
	var occupied := occupied_rects_for(family, variant, origin_cell, turns, tuning)
	if family.one_shot_edit:
		if not arena.arena_bounds.encloses(footprint):
			return _reject("out_of_bounds", "outside arena bounds")
	else:
		for occupied_rect in occupied:
			var arena_result := arena.validate_region(
				occupied_rect, ArenaDefinition.REGION_FOOTPRINT, actor_rects
			)
			if not bool(arena_result.allowed):
				return _reject(
					_code_for_arena_reason(str(arena_result.reason)), str(arena_result.reason)
				)
	var regions := ItemGeometry.clip_to_stage(
		ItemGeometry.resolve_regions(variant, turns, tuning), footprint, arena
	)
	for region in regions:
		var region_kind: ItemRegionSpec.Kind = region.kind
		if not ItemRegionSpec.is_bounded_extent_kind(region_kind) or family.one_shot_edit:
			continue
		var world_rect: Rect2 = region.rect
		world_rect.position += footprint.position
		var extent_kind := ArenaDefinition.REGION_EFFECT
		if bool(region.get("blockable", false)):
			extent_kind = ArenaDefinition.REGION_BLOCKABLE
		elif region_kind in [ItemRegionSpec.Kind.SWEEP, ItemRegionSpec.Kind.LANE]:
			extent_kind = ArenaDefinition.REGION_SWEEP
		var extent_result := arena.validate_region(world_rect, extent_kind, actor_rects)
		if not bool(extent_result.allowed):
			return _reject(
				_code_for_arena_reason(str(extent_result.reason)), str(extent_result.reason)
			)
	for other_variant in existing:
		var other := other_variant as PlacedItem
		for occupied_rect in occupied:
			for other_rect in other.occupancy():
				if occupied_rect.intersects(other_rect, false):
					return _reject("item_overlap", "overlaps %s" % other.instance_id)
	return {
		"allowed": true,
		"code": "valid",
		"reason": "Valid placement.",
		"footprint": footprint,
		"occupied": occupied,
		"one_shot": family.one_shot_edit,
	}


## Cells this placement actually reserves. One-shot edits reserve nothing; a variant that lists
## `occupied_cells` (Parol posts) reserves only those; everything else reserves its footprint.
static func occupied_rects_for(
	family: ItemFamilyDefinition,
	variant: ItemVariantDefinition,
	origin_cell: Vector2i,
	quarter_turns: int,
	tuning: GameplayTuning
) -> Array[Rect2]:
	var result: Array[Rect2] = []
	if family.one_shot_edit:
		return result
	var footprint := footprint_rect_for(variant, origin_cell, quarter_turns, tuning)
	if variant.occupied_cells.is_empty():
		result.append(footprint)
		return result
	var cell := tuning.grid_cell_wu
	var box := Vector2(variant.footprint_cells) * cell
	for cells in variant.occupied_cells:
		var local := Rect2(Vector2(cells.position) * cell, Vector2(cells.size) * cell)
		var rotated := ItemGeometry.rotate_rect(local, box, quarter_turns)
		rotated.position += footprint.position
		result.append(rotated)
	return result


static func footprint_rect_for(
	variant: ItemVariantDefinition,
	origin_cell: Vector2i,
	quarter_turns: int,
	tuning: GameplayTuning
) -> Rect2:
	var size := ItemGeometry.rotated_size(Vector2(variant.footprint_cells), quarter_turns)
	return Rect2(Vector2(origin_cell) * tuning.grid_cell_wu, size * tuning.grid_cell_wu)


static func _code_for_arena_reason(reason: String) -> String:
	if ARENA_REASON_CODES.has(reason):
		return ARENA_REASON_CODES[reason]
	if reason.begins_with("immutable base geometry"):
		return "immutable_base"
	return "invalid_region"


static func _reject(code: String, detail: String = "") -> Dictionary:
	var text: String = REASON_TEXT.get(code, code)
	if not detail.is_empty():
		text = "%s (%s)" % [text, detail]
	return {"allowed": false, "code": code, "reason": text}

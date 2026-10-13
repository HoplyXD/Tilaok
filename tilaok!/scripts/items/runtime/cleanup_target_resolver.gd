class_name CleanupTargetResolver
extends RefCounted

## Walis Cleanup target set. One pure function feeds the ghost preview, the atomic resolver and the
## tests, so the outline a player sees is exactly the set that is removed.


## pieces: Array of PlacedItem from the phase snapshot. Returns
## {ids: Array[String], protected: Array[Dictionary{rect,label}], same_phase: Array[String]}.
static func resolve(
	area: Rect2, pieces: Array, arena: ArenaDefinition, current_round: int
) -> Dictionary:
	var ids: Array[String] = []
	var same_phase: Array[String] = []
	for piece_variant in pieces:
		var piece := piece_variant as PlacedItem
		if piece == null:
			continue
		var hit := false
		for rect in piece.occupancy():
			if rect.intersects(area, false):
				hit = true
				break
		if not hit:
			continue
		if piece.placed_round >= current_round:
			same_phase.append(piece.instance_id)
			continue
		if bool(arena.can_remove_surface(piece.instance_id).allowed):
			ids.append(piece.instance_id)
	ids.sort()
	same_phase.sort()
	return {"ids": ids, "protected": protected_exclusions(area, arena), "same_phase": same_phase}


static func protected_exclusions(area: Rect2, arena: ArenaDefinition) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for spec in arena.surface_specs:
		var rect: Rect2 = spec.rect
		if bool(spec.immutable) and rect.intersects(area, false):
			result.append({"rect": rect.intersection(area), "label": str(spec.id)})
	if arena.protected_spawn.intersects(area, false):
		result.append({"rect": arena.protected_spawn.intersection(area), "label": "spawn"})
	if arena.protected_goal.intersects(area, false):
		result.append({"rect": arena.protected_goal.intersection(area), "label": "goal"})
	return result

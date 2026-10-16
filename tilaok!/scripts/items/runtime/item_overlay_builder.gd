class_name ItemOverlayBuilder
extends RefCounted

## World-space region overlays for ghosts and the Item Visualizer. The same helpers the runtime
## uses (LaneQuery, CleanupTargetResolver) build them, so the outline is the real region.
## Entry: {kind: String, rect: Rect2, normal?: Vector2, from?: Vector2, to?: Vector2, label?}.
## Kinds: occupied, solid, trigger, sweep, lane, effect, beam, path, blocker, target, protected.


static func world_occluders(arena: ArenaDefinition, pieces: Array) -> Array[Rect2]:
	var result: Array[Rect2] = []
	for spec in arena.surface_specs:
		result.append(spec.rect)
	for piece_variant in pieces:
		var record := piece_variant as PlacedItem
		if record == null or record.node == null or not is_instance_valid(record.node):
			continue
		var piece := record.node as ConstructionPiece
		if piece != null:
			result.append_array(piece.occlusion_rects())
	return result


static func build(
	family: ItemFamilyDefinition,
	variant: ItemVariantDefinition,
	origin_cell: Vector2i,
	turns: int,
	tuning: GameplayTuning,
	arena: ArenaDefinition,
	pieces: Array,
	current_round: int
) -> Array[Dictionary]:
	var overlay: Array[Dictionary] = []
	var footprint := ItemPlacementValidator.footprint_rect_for(variant, origin_cell, turns, tuning)
	var occluders := world_occluders(arena, pieces)
	for occupied in ItemPlacementValidator.occupied_rects_for(
		family, variant, origin_cell, turns, tuning
	):
		overlay.append({"kind": "occupied", "rect": occupied})
	var regions := ItemGeometry.clip_to_stage(
		ItemGeometry.resolve_regions(variant, turns, tuning), footprint, arena
	)
	for region in regions:
		var rect: Rect2 = region.rect
		rect.position += footprint.position
		var kind: ItemRegionSpec.Kind = region.kind
		match kind:
			ItemRegionSpec.Kind.SOLID:
				overlay.append({"kind": "solid", "rect": rect})
			ItemRegionSpec.Kind.TRIGGER:
				var normal := ItemGeometry.rotate_vector(Vector2.UP, turns)
				overlay.append({"kind": "trigger", "rect": rect, "normal": normal})
			ItemRegionSpec.Kind.SWEEP:
				overlay.append({"kind": "sweep", "rect": rect})
			ItemRegionSpec.Kind.LANE:
				_append_lane(overlay, rect, footprint, tuning, occluders)
			ItemRegionSpec.Kind.EFFECT:
				_append_effect(
					overlay, family, rect, tuning, arena, pieces, current_round, occluders
				)
	return overlay


static func _append_lane(
	overlay: Array[Dictionary],
	rect: Rect2,
	footprint: Rect2,
	tuning: GameplayTuning,
	occluders: Array[Rect2]
) -> void:
	var direction := Vector2.RIGHT
	var origin := Vector2(rect.position.x, rect.get_center().y)
	var length := rect.size.x
	if rect.end.x <= footprint.position.x + 0.01:
		direction = Vector2.LEFT
		origin = Vector2(rect.end.x, rect.get_center().y)
	elif rect.position.y >= footprint.end.y - 0.01:
		direction = Vector2.DOWN
		origin = Vector2(rect.get_center().x, rect.position.y)
		length = rect.size.y
	elif rect.end.y <= footprint.position.y + 0.01:
		direction = Vector2.UP
		origin = Vector2(rect.get_center().x, rect.end.y)
		length = rect.size.y
	var clip := LaneQuery.clip(
		origin, direction, length, tuning.item_launcher_projectile_size_wu, occluders
	)
	(
		overlay
		. append(
			{
				"kind": "lane",
				"rect": rect,
				"from": origin,
				"to": origin + direction * float(clip.length),
				"blocked": bool(clip.blocked),
			}
		)
	)
	if bool(clip.blocked):
		overlay.append({"kind": "blocker", "rect": clip.blocker})


static func _append_effect(
	overlay: Array[Dictionary],
	family: ItemFamilyDefinition,
	rect: Rect2,
	tuning: GameplayTuning,
	arena: ArenaDefinition,
	pieces: Array,
	current_round: int,
	occluders: Array[Rect2]
) -> void:
	if family.one_shot_edit:
		overlay.append({"kind": "effect", "rect": rect})
		var info := CleanupTargetResolver.resolve(rect, pieces, arena, current_round)
		for record_variant in pieces:
			var record := record_variant as PlacedItem
			if record != null and info.ids.has(record.instance_id):
				for occupied in record.occupancy():
					overlay.append({"kind": "target", "rect": occupied})
		for exclusion in info.protected:
			overlay.append({"kind": "protected", "rect": exclusion.rect, "label": exclusion.label})
		return
	if family.preview_silhouette == "parol":
		var horizontal := rect.size.x >= rect.size.y
		var width := tuning.item_parol_beam_width_wu
		var from_a := rect.position
		var from_b := rect.end
		var center := rect.get_center()
		if horizontal:
			from_a = Vector2(rect.position.x, center.y)
			from_b = Vector2(rect.end.x, center.y)
		else:
			from_a = Vector2(center.x, rect.position.y)
			from_b = Vector2(center.x, rect.end.y)
		var dir_a := Vector2.RIGHT if horizontal else Vector2.DOWN
		var length := rect.size.x if horizontal else rect.size.y
		var clip_a := LaneQuery.clip(from_a, dir_a, length, width, occluders)
		var clip_b := LaneQuery.clip(from_b, -dir_a, length, width, occluders)
		overlay.append(
			{
				"kind": "beam",
				"rect": rect,
				"from": from_a,
				"to": from_a + dir_a * float(clip_a.length)
			}
		)
		overlay.append(
			{
				"kind": "beam",
				"rect": rect,
				"from": from_b,
				"to": from_b - dir_a * float(clip_b.length)
			}
		)
		for clip in [clip_a, clip_b]:
			if bool(clip.blocked):
				overlay.append({"kind": "blocker", "rect": clip.blocker})
		return
	if family.preview_silhouette == "flower":
		var start := Vector2(rect.get_center().x, rect.end.y)
		var clip := LaneQuery.clip(
			start, Vector2.UP, rect.size.y, tuning.item_bubble_radius_wu * 2.0, occluders
		)
		overlay.append(
			{
				"kind": "path",
				"rect": rect,
				"from": start,
				"to": start + Vector2.UP * float(clip.length)
			}
		)
		if bool(clip.blocked):
			overlay.append({"kind": "blocker", "rect": clip.blocker})
		return
	overlay.append({"kind": "effect", "rect": rect})

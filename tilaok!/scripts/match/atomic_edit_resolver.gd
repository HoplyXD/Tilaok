class_name AtomicEditResolver
extends RefCounted


## Resolve every player's pending construction edit against one immutable stage snapshot.
## Cleanup targets are unioned first; remaining edits are considered in ascending seat order.
static func resolve(
	definitions: ItemDefinitions,
	arena: ArenaDefinition,
	tuning: GameplayTuning,
	snapshot_pieces: Array,
	edit_submissions: Array[Dictionary],
	current_round: int,
	actor_rects: Array[Rect2] = []
) -> Dictionary:
	var snapshot_by_id: Dictionary = {}
	for item_variant in snapshot_pieces:
		var item := item_variant as PlacedItem
		if item != null:
			snapshot_by_id[item.instance_id] = item
	# One-shot construction edits (Walis Cleanup) become cleanup targets from the same snapshot.
	var rejected: Dictionary = {}
	var one_shot_edits: Array[Dictionary] = []
	var placing_edits: Array[Dictionary] = []
	var all_edits: Array[Dictionary] = []
	var ordered_edits := edit_submissions.duplicate()
	ordered_edits.sort_custom(
		func(left: Dictionary, right: Dictionary) -> bool:
			return int(left.get("seat_index", -1)) < int(right.get("seat_index", -1))
	)
	for edit_variant in ordered_edits:
		var edit := (edit_variant as Dictionary).duplicate(true)
		var found := definitions.find_variant(str(edit.get("variant_key", "")))
		var is_one_shot := (
			not found.is_empty() and (found.family as ItemFamilyDefinition).one_shot_edit
		)
		if not is_one_shot:
			placing_edits.append(edit)
			all_edits.append(edit)
			continue
		var verdict := ItemPlacementValidator.validate(
			definitions,
			arena,
			tuning,
			str(edit.variant_key),
			edit.get("origin_cell", Vector2i.ZERO),
			int(edit.get("quarter_turns", 0)),
			snapshot_pieces,
			actor_rects
		)
		if not bool(verdict.allowed):
			rejected[int(edit.get("seat_index", -1))] = str(verdict.reason)
			continue
		var info := CleanupTargetResolver.resolve(
			verdict.footprint, snapshot_pieces, arena, current_round
		)
		edit["cleanup_targets"] = info.ids
		all_edits.append(edit)
		(
			one_shot_edits
			. append(
				{
					"seat_index": int(edit.get("seat_index", -1)),
					"variant_key": str(edit.variant_key),
					"area": verdict.footprint,
					"targets": info.ids,
					"same_phase": info.same_phase,
					"protected": info.protected,
				}
			)
		)
	var cleanup_ids: Dictionary = {}
	for edit in all_edits:
		for target_variant in edit.get("cleanup_targets", []):
			var target_id := str(target_variant)
			if not snapshot_by_id.has(target_id):
				continue
			var target := snapshot_by_id[target_id] as PlacedItem
			var removable := arena.can_remove_surface(target_id)
			if target.placed_round < current_round and bool(removable.allowed):
				cleanup_ids[target_id] = true
	var removals: Array[String] = []
	for target_id in cleanup_ids:
		removals.append(str(target_id))
	removals.sort()
	var remaining_snapshot: Array[PlacedItem] = []
	for target_id in snapshot_by_id:
		if not cleanup_ids.has(target_id):
			remaining_snapshot.append(snapshot_by_id[target_id] as PlacedItem)
	remaining_snapshot.sort_custom(
		func(left: PlacedItem, right: PlacedItem) -> bool:
			return left.instance_id < right.instance_id
	)
	var edits_by_seat: Dictionary = {}
	for edit in placing_edits:
		var seat_index := int(edit.get("seat_index", -1))
		if not edits_by_seat.has(seat_index):
			edits_by_seat[seat_index] = []
		edits_by_seat[seat_index].append(edit.duplicate(true))
	var seats: Array = edits_by_seat.keys()
	seats.sort()
	var accepted: Array[Dictionary] = []
	var committed_snapshot: Array[PlacedItem] = remaining_snapshot.duplicate()
	for seat_variant in seats:
		var seat_index := int(seat_variant)
		var seat_edits: Array = edits_by_seat[seat_index]
		seat_edits.sort_custom(
			func(left: Dictionary, right: Dictionary) -> bool:
				var left_key := str(left.get("variant_key", ""))
				var right_key := str(right.get("variant_key", ""))
				if left_key != right_key:
					return left_key < right_key
				var left_cell: Vector2i = left.get("origin_cell", Vector2i.ZERO)
				var right_cell: Vector2i = right.get("origin_cell", Vector2i.ZERO)
				if left_cell != right_cell:
					return (
						left_cell.x < right_cell.x
						if left_cell.x != right_cell.x
						else left_cell.y < right_cell.y
					)
				return int(left.get("quarter_turns", 0)) < int(right.get("quarter_turns", 0))
		)
		var seat_additions: Array[PlacedItem] = []
		var seat_reason := ""
		for edit in seat_edits:
			var validation_existing := committed_snapshot.duplicate()
			validation_existing.append_array(seat_additions)
			var verdict := ItemPlacementValidator.validate(
				definitions,
				arena,
				tuning,
				str(edit.get("variant_key", "")),
				edit.get("origin_cell", Vector2i.ZERO),
				int(edit.get("quarter_turns", 0)),
				validation_existing,
				actor_rects
			)
			if not bool(verdict.allowed):
				seat_reason = str(verdict.reason)
				break
			var found := definitions.find_variant(str(edit.variant_key))
			var family := found.family as ItemFamilyDefinition
			var variant := found.variant as ItemVariantDefinition
			var record := PlacedItem.new()
			record.instance_id = (
				"pending:%d:%s:%s:%s"
				% [seat_index, edit.variant_key, edit.origin_cell, str(edit.quarter_turns)]
			)
			record.family_id = family.family_id
			record.variant_key = str(edit.variant_key)
			record.origin_cell = edit.origin_cell
			record.quarter_turns = ItemGeometry.normalized_turns(int(edit.quarter_turns))
			record.owner_seat = seat_index
			record.placed_round = current_round
			record.footprint_rect = verdict.footprint
			seat_additions.append(record)
		if seat_reason.is_empty():
			for edit in seat_edits:
				accepted.append(edit)
			var accepted_ids: Dictionary = {}
			for addition in seat_additions:
				accepted_ids[addition.instance_id] = true
			committed_snapshot.append_array(seat_additions)
		else:
			rejected[seat_index] = seat_reason
	var signature_rows := PackedStringArray()
	for item in remaining_snapshot:
		signature_rows.append(item.signature())
	for edit in accepted:
		signature_rows.append(
			(
				"%s|%s|%s|%d|%d"
				% [
					edit.variant_key,
					edit.origin_cell,
					str(edit.quarter_turns),
					edit.seat_index,
					current_round
				]
			)
		)
	signature_rows.sort()
	return {
		"allowed": true,
		"removals": removals,
		"commits": accepted,
		"one_shot_edits": one_shot_edits,
		"rejections": rejected,
		"signature": "\n".join(signature_rows),
	}

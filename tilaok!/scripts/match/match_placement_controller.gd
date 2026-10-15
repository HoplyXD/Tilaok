class_name MatchPlacementController
extends RefCounted

const START_CELLS: Array[Vector2i] = [
	Vector2i(8, 8), Vector2i(12, 8), Vector2i(17, 8), Vector2i(22, 8)
]

var cursors: Dictionary = {}
var definitions: ItemDefinitions
var tuning: GameplayTuning
## First come, first served: seats in the order they confirmed. A confirmed placement claims its
## cells at once; later players cannot confirm over them, and edits resolve in this order.
var confirm_order: Array[int] = []


func setup(
	items_by_seat: Dictionary, source_definitions: ItemDefinitions, source_tuning: GameplayTuning
) -> void:
	cursors.clear()
	confirm_order.clear()
	definitions = source_definitions
	tuning = source_tuning
	var seats: Array = items_by_seat.keys()
	seats.sort()
	for seat_index_variant in seats:
		var seat_index := int(seat_index_variant)
		cursors[seat_index] = {
			"variant_key": str(items_by_seat[seat_index]),
			"cell": START_CELLS[seat_index % START_CELLS.size()],
			"quarter_turns": 0,
			"confirmed": false,
			"reason": "",
		}


func move(seat_index: int, delta_cells: Vector2i) -> bool:
	if not cursors.has(seat_index):
		return false
	var cursor: Dictionary = cursors[seat_index]
	if bool(cursor.confirmed):
		return false
	var next: Vector2i = cursor.cell + delta_cells
	next.x = clampi(next.x, 0, tuning.arena_width_tiles - 1)
	next.y = clampi(next.y, 0, tuning.arena_height_tiles - 1)
	if next == cursor.cell:
		return false
	cursor.cell = next
	cursors[seat_index] = cursor
	return true


func rotate(seat_index: int) -> bool:
	if not cursors.has(seat_index):
		return false
	var cursor: Dictionary = cursors[seat_index]
	if bool(cursor.confirmed):
		return false
	var rotations := _usable_rotations(str(cursor.variant_key))
	if rotations.size() <= 1:
		return false
	var index := rotations.find(int(cursor.quarter_turns))
	cursor.quarter_turns = rotations[(index + 1) % rotations.size()]
	cursors[seat_index] = cursor
	return true


func set_confirmed(seat_index: int, value: bool) -> void:
	if not cursors.has(seat_index):
		return
	var cursor: Dictionary = cursors[seat_index]
	# Confirmation is a one-way lock for the rest of this Place phase.
	if bool(cursor.confirmed) and not value:
		return
	cursor.confirmed = value
	cursors[seat_index] = cursor
	if value and not confirm_order.has(seat_index):
		confirm_order.append(seat_index)


func is_confirmed(seat_index: int) -> bool:
	return cursors.has(seat_index) and bool(cursors[seat_index].confirmed)


func all_confirmed() -> bool:
	if cursors.is_empty():
		return false
	for cursor in cursors.values():
		if not bool(cursor.confirmed):
			return false
	return true


## Seat of the earliest confirmed placement (other than `seat_index`) whose claimed cells overlap
## this candidate, or -1 when the cells are still free.
func claimed_by(seat_index: int, variant_key: String, cell: Vector2i, quarter_turns: int) -> int:
	var candidate := _occupancy(variant_key, cell, quarter_turns)
	for owner in confirm_order:
		if owner == seat_index or not cursors.has(owner):
			continue
		var claim: Dictionary = cursors[owner]
		for claimed in _occupancy(str(claim.variant_key), claim.cell, int(claim.quarter_turns)):
			for rect in candidate:
				if rect.intersects(claimed, false):
					return owner
	return -1


func _occupancy(variant_key: String, cell: Vector2i, quarter_turns: int) -> Array[Rect2]:
	if BaryaObjectiveDefinition.is_variant(variant_key):
		return [Rect2(Vector2(cell) * tuning.grid_cell_wu, Vector2.ONE * tuning.grid_cell_wu)]
	var found := definitions.find_variant(variant_key)
	if found.is_empty():
		var none: Array[Rect2] = []
		return none
	return ItemPlacementValidator.occupied_rects_for(
		found.family as ItemFamilyDefinition,
		found.variant as ItemVariantDefinition,
		cell,
		quarter_turns,
		tuning
	)


func confirmed_edits() -> Array[Dictionary]:
	return _edits(false, {})


func timeout_edits(validity_by_seat: Dictionary) -> Array[Dictionary]:
	return _edits(true, validity_by_seat)


## Confirmed edits first, in confirmation order; then (at timeout) valid unconfirmed edits in seat
## order. Each edit carries `confirm_order` so the resolver keeps first come, first served.
func _edits(include_valid_unconfirmed: bool, validity_by_seat: Dictionary) -> Array[Dictionary]:
	var edits: Array[Dictionary] = []
	var seats: Array = confirm_order.duplicate()
	var rest: Array = cursors.keys()
	rest.sort()
	for seat_index_variant in rest:
		if not seats.has(int(seat_index_variant)):
			seats.append(int(seat_index_variant))
	for seat_index_variant in seats:
		var seat_index := int(seat_index_variant)
		var cursor: Dictionary = cursors[seat_index]
		var allowed := bool(cursor.confirmed)
		if include_valid_unconfirmed:
			allowed = allowed or bool(validity_by_seat.get(seat_index, false))
		if not allowed:
			continue
		(
			edits
			. append(
				{
					"seat_index": seat_index,
					"variant_key": str(cursor.variant_key),
					"origin_cell": cursor.cell,
					"quarter_turns": int(cursor.quarter_turns),
					"cleanup_targets": [],
					"confirm_order": _order_of(seat_index),
				}
			)
		)
	return edits


## Position in the confirmation order; unconfirmed seats come after every confirmed one.
func _order_of(seat_index: int) -> int:
	var index := confirm_order.find(seat_index)
	return index if index >= 0 else confirm_order.size() + 100 + seat_index


func _usable_rotations(variant_key: String) -> Array[int]:
	var usable: Array[int] = []
	var found := definitions.find_variant(variant_key)
	if found.is_empty():
		return usable
	var variant := found.variant as ItemVariantDefinition
	for turn in variant.rotations:
		if variant.gated_rotations.has(turn) and not tuning.item_tulay_vertical_enabled:
			continue
		usable.append(turn)
	return usable

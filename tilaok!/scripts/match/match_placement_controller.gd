class_name MatchPlacementController
extends RefCounted

const START_CELLS: Array[Vector2i] = [
	Vector2i(8, 8), Vector2i(12, 8), Vector2i(17, 8), Vector2i(22, 8)
]

var cursors: Dictionary = {}
var definitions: ItemDefinitions
var tuning: GameplayTuning


func setup(
	items_by_seat: Dictionary, source_definitions: ItemDefinitions, source_tuning: GameplayTuning
) -> void:
	cursors.clear()
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
	var next: Vector2i = cursor.cell + delta_cells
	next.x = clampi(next.x, 0, tuning.arena_width_tiles - 1)
	next.y = clampi(next.y, 0, tuning.arena_height_tiles - 1)
	if next == cursor.cell:
		return false
	cursor.cell = next
	cursor.confirmed = false
	cursors[seat_index] = cursor
	return true


func rotate(seat_index: int) -> bool:
	if not cursors.has(seat_index):
		return false
	var cursor: Dictionary = cursors[seat_index]
	var rotations := _usable_rotations(str(cursor.variant_key))
	if rotations.size() <= 1:
		return false
	var index := rotations.find(int(cursor.quarter_turns))
	cursor.quarter_turns = rotations[(index + 1) % rotations.size()]
	cursor.confirmed = false
	cursors[seat_index] = cursor
	return true


func set_confirmed(seat_index: int, value: bool) -> void:
	if not cursors.has(seat_index):
		return
	var cursor: Dictionary = cursors[seat_index]
	cursor.confirmed = value
	cursors[seat_index] = cursor


func all_confirmed() -> bool:
	if cursors.is_empty():
		return false
	for cursor in cursors.values():
		if not bool(cursor.confirmed):
			return false
	return true


func confirmed_edits() -> Array[Dictionary]:
	return _edits(false, {})


func timeout_edits(validity_by_seat: Dictionary) -> Array[Dictionary]:
	return _edits(true, validity_by_seat)


func _edits(include_valid_unconfirmed: bool, validity_by_seat: Dictionary) -> Array[Dictionary]:
	var edits: Array[Dictionary] = []
	var seats: Array = cursors.keys()
	seats.sort()
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
				}
			)
		)
	return edits


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

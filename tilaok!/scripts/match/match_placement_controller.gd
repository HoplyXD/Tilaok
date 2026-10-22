class_name MatchPlacementController
extends RefCounted

## Fallback cursor columns, used only when no build region is supplied.
const START_CELLS: Array[Vector2i] = [
	Vector2i(8, 8), Vector2i(12, 8), Vector2i(17, 8), Vector2i(22, 8)
]

var cursors: Dictionary = {}
var definitions: ItemDefinitions
var tuning: GameplayTuning
## The map's build area in tiles, from its Build markers (ArenaDefinition.build_region). The cursor
## is clamped to this instead of the fixed tuning arena size, which on a map larger than 32x16
## trapped the cursor in the top-left corner and let it roam outside the painted build area.
## Empty falls back to the tuning arena size.
var build_region_tiles := Rect2i()
## Where the build cursor starts: the spawn column, so a round opens next to the chickens rather
## than at a hardcoded middle-of-the-stage cell. Negative means "use START_CELLS".
var start_anchor_tile := Vector2i(-1, -1)


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
			"cell": _start_cell(seat_index),
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
	var next := _clamp_to_build_area(cursor.cell + delta_cells)
	if next == cursor.cell:
		return false
	cursor.cell = next
	cursors[seat_index] = cursor
	return true


## Keeps the cursor inside the map's painted build area, falling back to the tuning arena size for
## a stage that supplies none.
func _clamp_to_build_area(cell: Vector2i) -> Vector2i:
	if build_region_tiles.size.x > 0 and build_region_tiles.size.y > 0:
		return Vector2i(
			clampi(cell.x, build_region_tiles.position.x, build_region_tiles.end.x - 1),
			clampi(cell.y, build_region_tiles.position.y, build_region_tiles.end.y - 1)
		)
	return Vector2i(
		clampi(cell.x, 0, tuning.arena_width_tiles - 1),
		clampi(cell.y, 0, tuning.arena_height_tiles - 1)
	)


## Seat `seat_index` opens near the spawn anchor when one is known, spread a little so four seats
## do not stack on one cell, and always inside the build area.
func _start_cell(seat_index: int) -> Vector2i:
	if start_anchor_tile.x < 0 or start_anchor_tile.y < 0:
		return _clamp_to_build_area(START_CELLS[seat_index % START_CELLS.size()])
	var spread := Vector2i(seat_index % 2, seat_index / 2)
	return _clamp_to_build_area(start_anchor_tile + spread)


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


func is_confirmed(seat_index: int) -> bool:
	return cursors.has(seat_index) and bool(cursors[seat_index].confirmed)


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


## Confirmed edits (and, at timeout, valid unconfirmed ones) in seat order. Confirming earlier
## gives no advantage: overlapping placements are refused together by the resolver.
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

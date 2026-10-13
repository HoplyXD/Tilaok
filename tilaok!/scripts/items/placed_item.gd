class_name PlacedItem
extends RefCounted

## Ownership and placement record for one persistent construction piece.
## Construction is never a hazard: this record carries no trap-credit fields.
var instance_id := ""
var family_id := ""
var variant_key := ""
var origin_cell := Vector2i.ZERO
var quarter_turns := 0
var owner_seat := -1
var placed_round := 0
var footprint_rect := Rect2()
var node: Node = null


func signature() -> String:
	return (
		"%s|%s|%d,%d|%d|owner%d|r%d"
		% [
			instance_id,
			variant_key,
			origin_cell.x,
			origin_cell.y,
			ItemGeometry.normalized_turns(quarter_turns),
			owner_seat,
			placed_round
		]
	)

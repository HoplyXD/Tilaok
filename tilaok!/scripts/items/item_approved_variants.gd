class_name ItemApprovedVariants
extends RefCounted

## Documented variant authority: docs/ITEMS.md "Approved size variants" (2026-10-12).
## A definition may only declare variants listed here, with exactly this footprint.
const TABLE := {
	"build.hollow_blocks":
	{
		"cell_1x1": Vector2i(1, 1),
		"column_1x3": Vector2i(1, 3),
		"stack_2x3": Vector2i(2, 3),
	},
	"build.bamboo_bridge":
	{
		"span_3x1": Vector2i(3, 1),
		"span_4x1": Vector2i(4, 1),
		"span_5x1": Vector2i(5, 1),
	},
	# Stage blocks (owner request 2026-10-14; docs/ITEMS.md "Stage blocks").
	"build.solid_block": {"slab_3x1": Vector2i(3, 1)},
	"build.wood_box": {"box_2x2": Vector2i(2, 2)},
	"build.collapsing_block": {"cell_1x1": Vector2i(1, 1)},
}


static func is_approved(family_id: String, variant_id: String) -> bool:
	return TABLE.has(family_id) and (TABLE[family_id] as Dictionary).has(variant_id)


static func approved_footprint(family_id: String, variant_id: String) -> Vector2i:
	if not is_approved(family_id, variant_id):
		return Vector2i.ZERO
	return (TABLE[family_id] as Dictionary)[variant_id]

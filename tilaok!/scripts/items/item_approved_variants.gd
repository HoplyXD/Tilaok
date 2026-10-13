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
	"move.tire_spring": {"tire_2x2": Vector2i(2, 2)},
	"hazard.rail_trumpo":
	{
		"rail_4x1": Vector2i(4, 1),
		"rail_5x1": Vector2i(5, 1),
		"rail_6x1": Vector2i(6, 1),
	},
	"hazard.parol_pulse":
	{
		"span_3x1": Vector2i(3, 1),
		"span_4x1": Vector2i(4, 1),
		"span_5x1": Vector2i(5, 1),
		"span_6x1": Vector2i(6, 1),
	},
	"hazard.slipper_launcher":
	{
		"lane_4x1": Vector2i(1, 1),
		"lane_6x1": Vector2i(1, 1),
	},
	"utility.walis_cleanup":
	{
		"area_3x3": Vector2i(3, 3),
		"area_5x5": Vector2i(5, 5),
	},
	"hazard.bubble_planter":
	{
		"path_1x3": Vector2i(1, 1),
		"path_1x5": Vector2i(1, 1),
	},
}


static func is_approved(family_id: String, variant_id: String) -> bool:
	return TABLE.has(family_id) and (TABLE[family_id] as Dictionary).has(variant_id)


static func approved_footprint(family_id: String, variant_id: String) -> Vector2i:
	if not is_approved(family_id, variant_id):
		return Vector2i.ZERO
	return (TABLE[family_id] as Dictionary)[variant_id]

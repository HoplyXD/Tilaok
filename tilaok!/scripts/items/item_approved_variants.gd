class_name ItemApprovedVariants
extends RefCounted

## The documented variant table is now the block scene folder itself (scenes/blocks/): every
## scanned scene documents its family, variant and footprint. A definition may only declare
## variants that exist there, with exactly that footprint (docs/ITEMS.md "Block scenes").


## {family_id: {variant_id: footprint}} for every block scene.
static func table() -> Dictionary:
	return BlockCatalog.approved_table()


static func is_approved(family_id: String, variant_id: String) -> bool:
	var rows := table()
	return rows.has(family_id) and (rows[family_id] as Dictionary).has(variant_id)


static func approved_footprint(family_id: String, variant_id: String) -> Vector2i:
	if not is_approved(family_id, variant_id):
		return Vector2i.ZERO
	return (table()[family_id] as Dictionary)[variant_id]

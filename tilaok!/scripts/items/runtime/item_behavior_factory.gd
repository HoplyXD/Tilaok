class_name ItemBehaviorFactory
extends RefCounted

## Family ID -> runtime behavior. Static construction and the one-shot Walis edit have none.


static func create(family_id: String) -> ItemBehavior:
	match family_id:
		"move.tire_spring":
			return SpringBehavior.new()
		"hazard.rail_trumpo":
			return TrumpoBehavior.new()
		"hazard.parol_pulse":
			return ParolBehavior.new()
		"hazard.slipper_launcher":
			return LauncherBehavior.new()
		"hazard.bubble_planter":
			return BubbleBehavior.new()
	return null


static func has_behavior(family_id: String) -> bool:
	return create(family_id) != null


## Detached behavior at the origin for previews (egg, ghost, Library). Never touches a stage.
static func create_preview(
	family: ItemFamilyDefinition, variant: ItemVariantDefinition, turns: int, tuning: GameplayTuning
) -> ItemBehavior:
	var behavior := create(family.family_id)
	if behavior == null:
		return null
	var record := PlacedItem.new()
	record.instance_id = "preview"
	record.family_id = family.family_id
	record.quarter_turns = ItemGeometry.normalized_turns(turns)
	record.footprint_rect = Rect2(
		Vector2.ZERO,
		ItemGeometry.rotated_size(Vector2(variant.footprint_cells), turns) * tuning.grid_cell_wu
	)
	behavior.configure(record, ItemGeometry.resolve_regions(variant, turns, tuning), tuning)
	return behavior

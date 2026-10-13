class_name SolidBlock
extends StaticBody2D

## Solid block: 3x1 cells (192x64 wu), rotates to 1x3. No gravity; wall-slide eligible.
## Collision and the DEBUG placeholder visual are authored in scenes/blocks/solid_block.tscn.

var placed: PlacedItem
var metadata: SupportSurfaceMetadata


func configure(
	source: PlacedItem,
	_regions: Array[Dictionary],
	surface_metadata: SupportSurfaceMetadata,
	_wall_contact_declaration: String,
	_tuning: GameplayTuning
) -> void:
	placed = source
	metadata = surface_metadata
	collision_mask = 1
	StageBlockSupport.configure_root(self, source, surface_metadata)


## Static block: nothing to restore.
func reset_to_start() -> void:
	pass


func footprint_world_rect() -> Rect2:
	return placed.footprint_rect if placed != null else Rect2()


func occlusion_rects() -> Array[Rect2]:
	var result: Array[Rect2] = [footprint_world_rect()]
	return result


func strip_world_rects() -> Array[Rect2]:
	return []


func strip_normals() -> Array[Vector2]:
	return []

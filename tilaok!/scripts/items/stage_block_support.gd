class_name StageBlockSupport
extends RefCounted

## Shared setup for scene-authored stage blocks (scenes/blocks/*.tscn). Each block scene is a
## physics body root authored at quarter turn 0 and centered on its footprint, with a
## `CollisionShape2D` child and a `Visual` node. ItemManager places it through the same
## interface as ConstructionPiece: configure(), reset_to_start(), footprint_world_rect(),
## occlusion_rects(), strip_world_rects() and strip_normals().
## The item definition footprint is authoritative: when the authored shape differs (for example
## the legacy 32 wu test grid) the shape is resized and the visual scaled to match.

const SHAPE_NODE := "CollisionShape2D"
const VISUAL_NODE := "Visual"


static func configure_root(
	body: CollisionObject2D, source: PlacedItem, surface_metadata: SupportSurfaceMetadata
) -> void:
	var turns := ItemGeometry.normalized_turns(source.quarter_turns)
	body.name = source.instance_id.replace("#", "_")
	body.position = source.footprint_rect.get_center()
	body.rotation = float(turns) * PI * 0.5
	body.collision_layer = 1
	body.add_to_group("support_surfaces")
	body.add_to_group("stage_blocks")
	body.set_meta(SupportSurfaceMetadata.META_KEY, surface_metadata)
	fit_authored_shape(body, unrotated_size(source))


## Footprint size in the scene's own (turn 0) frame.
static func unrotated_size(source: PlacedItem) -> Vector2:
	return ItemGeometry.rotated_size(source.footprint_rect.size, source.quarter_turns)


static func fit_authored_shape(body: Node, size: Vector2) -> void:
	var collision := body.get_node_or_null(SHAPE_NODE) as CollisionShape2D
	if collision == null or not collision.shape is RectangleShape2D:
		push_error("%s: block scene needs a RectangleShape2D '%s'" % [body.name, SHAPE_NODE])
		return
	var rectangle := collision.shape.duplicate() as RectangleShape2D
	var authored := rectangle.size
	collision.shape = rectangle
	if authored.is_equal_approx(size):
		return
	rectangle.size = size
	var visual := body.get_node_or_null(VISUAL_NODE) as Node2D
	if visual != null and authored.x > 0.0 and authored.y > 0.0:
		visual.scale = size / authored


static func shape_of(body: Node) -> CollisionShape2D:
	return body.get_node_or_null(SHAPE_NODE) as CollisionShape2D

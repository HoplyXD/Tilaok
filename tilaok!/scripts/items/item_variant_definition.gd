class_name ItemVariantDefinition
extends Resource

@export var variant_id := ""
## Unrotated width x height in grid cells.
@export var footprint_cells := Vector2i.ZERO
@export var regions: Array[ItemRegionSpec] = []
## Documented clockwise quarter turns this variant may be placed at.
@export var rotations: PackedInt32Array = PackedInt32Array()
## Subset of rotations that stays disabled until its controller/movement gate is lifted.
@export var gated_rotations: PackedInt32Array = PackedInt32Array()
## Disabled-rotation cue text shown when no rotation changes this variant.
@export var rotation_cue := ""

class_name ItemRegionSpec
extends Resource

## One authored region of an item. Footprint, solid, trigger, sweep, lane and effect data stay
## separate: only the variant footprint ever occupies construction-grid cells.
enum Kind { UNSET = -1, SOLID, ONE_WAY_TOP, TRIGGER, SWEEP, LANE, EFFECT }

@export var kind := Kind.UNSET
## Bounds in grid cells relative to the unrotated footprint's top-left corner.
@export var rect_cells := Rect2()
## ONE_WAY_TOP only: GameplayTuning field that gives the strip thickness in world units.
@export var thickness_tuning_key: StringName = &""
## Sweep, lane and effect regions must declare themselves explicitly bounded.
@export var declared_bounded := false
## Lane, beam or path that solids may cut short: base-geometry overlap is allowed and clips it.
@export var blockable := false
## A projectile path drawn past the stage edge (2026-10-16): when placed, the lane is cut where it
## would leave the build region or enter a protected zone (ItemGeometry.clip_to_stage).
@export var reach_stage_edge := false
## Scene-authored blocks: what touching this region does ("kill", "stun", "launch", "capture",
## or empty). Behaviors filter TRIGGER regions by it.
@export var effect: StringName = &""
## ONE_WAY_TOP without a tuning key: the authored strip thickness in world units.
@export var thickness_wu := 0.0


static func kind_name(region_kind: Kind) -> String:
	match region_kind:
		Kind.SOLID:
			return "solid"
		Kind.ONE_WAY_TOP:
			return "one_way_top"
		Kind.TRIGGER:
			return "trigger"
		Kind.SWEEP:
			return "sweep"
		Kind.LANE:
			return "lane"
		Kind.EFFECT:
			return "effect"
	return "unset"


static func is_collision_kind(region_kind: Kind) -> bool:
	return region_kind in [Kind.SOLID, Kind.ONE_WAY_TOP]


static func is_bounded_extent_kind(region_kind: Kind) -> bool:
	return region_kind in [Kind.SWEEP, Kind.LANE, Kind.EFFECT]

class_name ItemBehavior
extends RefCounted

## Per-placed-item runtime state machine. Behaviors never decide outcomes by callback order: they
## advance in `step`, report intents through the step context, and are cleaned in `teardown`.
## Time is accumulated only while the item is active (after Play start and the activation grace),
## so the Play reset and a pause mid-cycle are both exact.

var item_id := ""
var family_id := ""
var owner_seat := -1
var turns := 0
var tuning: GameplayTuning
## World position of the footprint's top-left corner.
var origin := Vector2.ZERO
var footprint_size := Vector2.ZERO
## Regions resolved by ItemGeometry (relative to `origin`).
var regions: Array[Dictionary] = []
var elapsed := 0.0
## Slot IDs of sounds to play; the piece drains this each frame.
var pending_sounds: Array[String] = []


func configure(
	record: PlacedItem, resolved_regions: Array[Dictionary], source_tuning: GameplayTuning
) -> void:
	item_id = record.instance_id
	family_id = record.family_id
	owner_seat = record.owner_seat
	turns = record.quarter_turns
	tuning = source_tuning
	origin = record.footprint_rect.position
	footprint_size = record.footprint_rect.size
	regions = resolved_regions
	reset_to_start()


func reset_to_start() -> void:
	elapsed = 0.0
	pending_sounds.clear()


func step(_ctx: ItemStepContext) -> void:
	pass


## Pose this behavior would have `seconds` after an uninterrupted Play start. Used by egg previews,
## the Library and ghosts; it never touches the stage.
func preview_at(seconds: float) -> void:
	elapsed = seconds


## Runs after lethal contacts resolved (captures, carried players).
func post_resolve(_ctx: ItemStepContext) -> void:
	pass


## Frees every transient and releases any captive; safe to call more than once.
func teardown(_director: ItemHazardDirector) -> void:
	pass


## State for the painter and the Visualizer readout. Positions are local to `origin`.
func readout() -> Dictionary:
	return {"elapsed": elapsed}


func world_rects(kind: ItemRegionSpec.Kind) -> Array[Rect2]:
	var result: Array[Rect2] = []
	for region in regions:
		if region.kind == kind:
			var rect: Rect2 = region.rect
			result.append(Rect2(rect.position + origin, rect.size))
	return result


func advance(dt: float) -> void:
	elapsed += dt


func make_record(
	kind: AttributionRecord.Kind, seat: int, time: float, detail: String
) -> AttributionRecord:
	var record := AttributionRecord.new()
	record.kind = kind
	record.player_seat = seat
	record.source_item_id = item_id
	record.source_family_id = family_id
	record.owner_seat = owner_seat
	record.physics_time = time
	record.self_kill = kind == AttributionRecord.Kind.ELIMINATION and seat == owner_seat
	record.setup_only = kind == AttributionRecord.Kind.SETUP
	record.detail = detail
	return record

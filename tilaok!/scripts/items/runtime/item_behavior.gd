class_name ItemBehavior
extends RefCounted

## Per-placed-item runtime state machine. Behaviors never decide outcomes by callback order: they
## advance in `step`, report intents through the step context, and are cleaned in `teardown`.
## Time is accumulated only while the item is active (after Play start and the activation grace),
## so the Play reset and a pause mid-cycle are both exact.

## Touching counts: a chicken pressed against a block's solid sits a physics safe margin away,
## so touch regions are tested with this tolerance.
const TOUCH_TOLERANCE_WU := 2.0

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
## Scene-authored touch effects (TRIGGER regions tagged "kill"/"stun"; see BlockHitbox).
var stun_seconds := 1.0
var stun_knockback_wu_s := 480.0


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


## Kill/stun touch regions, checked by the director after `step` for every behavior. A static
## block with only hitboxes uses this base class as its whole behavior.
func apply_touch_effects(ctx: ItemStepContext) -> void:
	var kill_rects := effect_rects(&"kill")
	var stun_rects := effect_rects(&"stun")
	if kill_rects.is_empty() and stun_rects.is_empty():
		return
	for actor in ctx.actors:
		if not ctx.is_hazard_target(actor):
			continue
		var body := ctx.body_of(actor)
		var killed := false
		for rect in kill_rects:
			if body.intersects(rect.grow(TOUCH_TOLERANCE_WU), false):
				ctx.report_lethal(actor.seat_index, ctx.time_start, item_id, "kill hitbox")
				killed = true
				break
		if killed:
			continue
		for rect in stun_rects:
			if body.intersects(rect.grow(TOUCH_TOLERANCE_WU), false):
				var away := body.get_center() - rect.get_center()
				var direction := Vector2(signf(away.x) if absf(away.x) > 0.01 else 0.0, -0.5)
				ctx.request_stun(
					actor.seat_index,
					item_id,
					direction.normalized() * stun_knockback_wu_s,
					stun_seconds
				)
				break


## Launch faces: TRIGGER regions tagged "launch" (or untagged legacy spring faces).
func launch_faces() -> Array[Rect2]:
	var result := effect_rects(&"launch")
	result.append_array(effect_rects(&""))
	return result


## World rects of TRIGGER regions carrying `effect`.
func effect_rects(effect: StringName) -> Array[Rect2]:
	var result: Array[Rect2] = []
	for region in regions:
		if region.kind == ItemRegionSpec.Kind.TRIGGER and region.get("effect", &"") == effect:
			var rect: Rect2 = region.rect
			result.append(Rect2(rect.position + origin, rect.size))
	return result


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

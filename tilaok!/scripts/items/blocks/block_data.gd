@tool
class_name BlockData
extends Node2D

## Designer-authored data for ONE placeable block, added as a child node of its scene in
## scenes/blocks/ (like aLima's ArtifactScannerData). BlockCatalog reads it during the folder scan,
## so any new block scene dropped into scenes/blocks/ becomes a placeable item (Pugad eggs, Item
## Lab, Library) with NO code, data table or .tres edit.
##
## Scene layout (all authored at rotation 0, centred on the block root):
## - BlockData (this node): settings below. In the editor it draws the placement box and grid.
## - CollisionShape2D children of the root: the SOLID hitbox (one-way shapes become one-way
##   platforms). Independent of the placement box: a 2x2 block may have a 1x1 solid.
## - BlockHitbox (Area2D) children: KILL / STUN / LAUNCH ... regions (see block_hitbox.gd).
## - Visual (Node2D): everything the player sees. Replace with final art freely.
## - Optional projectile template (Special: Spawn Projectiles): a Node2D with a Path2D child the
##   projectile follows and a BlockHitbox (KILL or STUN) for what it does on touch.
## All values are PROTOTYPE — UNMEASURED unless the block says otherwise.

enum Anchor { ANCHORED, HEAVY, LIGHT }
enum Special { NONE, SPAWN_PROJECTILES, FOLLOW_RAIL, TIMED_HITBOX, LAUNCH, COLLAPSE, CLEANUP }

## One grid tile in the authored scene (world units). Blocks are authored on the 64 wu grid.
const AUTHOR_CELL_WU := 64.0
## Special parameter -> GameplayTuning field it overrides for this block only (-1 = keep global).
const OVERRIDE_FIELDS := {
	"projectile_speed_wu_s": "item_launcher_projectile_speed_wu_s",
	"projectile_size_wu": "item_launcher_projectile_size_wu",
	"fire_interval_s": "item_launcher_cooldown_s",
	"initial_delay_s": "item_launcher_initial_delay_s",
	"telegraph_s": "item_launcher_telegraph_s",
	"rail_speed_wu_s": "item_trumpo_speed_wu_s",
	"rail_pause_s": "item_trumpo_pause_s",
	"rail_hit_wu": "item_trumpo_hit_wu",
	"cycle_s": "item_parol_cycle_s",
	"active_s": "item_parol_active_s",
	"charge_s": "item_parol_charge_s",
	"beam_width_wu": "item_parol_beam_width_wu",
	"launch_wu_s": "item_spring_launch_wu_s",
	"boost_wu_s": "item_spring_boost_wu_s",
	"launch_cooldown_s": "item_spring_cooldown_s",
	"bubble_cadence_s": "item_bubble_cadence_s",
	"bubble_rise_wu_s": "item_bubble_rise_wu_s",
	"capture_s": "item_bubble_capture_s",
	"collapse_delay_s": "block_collapse_delay_s",
	"collapse_respawn_s": "block_collapse_respawn_s",
	"push_speed_wu_s": "block_box_push_speed_wu_s",
}

@export_group("Block")
## Name shown in the Library and Item Lab.
@export var block_name := "":
	set(value):
		block_name = value
		update_configuration_warnings()
## Catalog family ID. Blank = "block.<scene file name>". Variants that share an ID are grouped
## (e.g. all Kaing sizes are "build.hollow_blocks").
@export var family_id := ""
## Variant ID inside the family. Blank = "main".
@export var variant_id := ""
@export var category := "build"
## Family sort order in catalogs (lower first). Keeps seeded Pugad pools stable; new blocks can
## keep the default and sort after the built-in ones by family ID.
@export var catalog_order := 100
@export_multiline var library_tell := ""
@export_multiline var library_counterplay := ""
@export var modes_allowed := PackedStringArray(["karera", "lagsanay", "kangaroo"])
@export var modes_pending_review := PackedStringArray()

@export_group("Placement Box")
## Placement box in tiles: columns x rows (width x height). The box is what the placement grid
## reserves; the solid and hitboxes inside it are edited separately.
@export var placement_size := Vector2i.ONE:
	set(value):
		placement_size = Vector2i(maxi(1, value.x), maxi(1, value.y))
		queue_redraw()
		update_configuration_warnings()
## Quarter turns (0..3) R may rotate it to. [0] = no rotation.
@export var rotations := PackedInt32Array([0])
## Rotations that stay disabled until a gate lifts (Tulay vertical).
@export var gated_rotations := PackedInt32Array()
## Reserve only the cells under solid shapes (Parol posts) instead of the whole box.
@export var reserve_only_solid_cells := false
## Chickens may wall-slide on its solid sides.
@export var wall_slide_eligible := true
## Its solid tops count as raised support (Kangaroo Rising wave). Off for hazards/launchers.
@export var counts_as_support := true
## One-way platforms: GameplayTuning field for the strip thickness (blank = shape height).
@export var one_way_thickness_key: StringName = &""

@export_group("Selection Pool")
@export var in_main_game := true
@export var in_dev_labs := true
## In the default Pugad / Item Lab pool without editing tuning.
@export var enabled_by_default := true
@export var pool_weight := 50.0
## Optional GameplayTuning weight field (wins over pool_weight when set).
@export var weight_tuning_key: StringName = &""

@export_group("Anchor / Gravity")
## Anchored = stays in its tile; Heavy = falls but players can't push it; Light = falls and a
## grounded chicken walking into it pushes it.
@export var anchor := Anchor.ANCHORED

@export_group("Effects")
## KILL hitboxes eliminate the touching chicken (credited to the placer).
@export var kill := false
## STUN hitboxes freeze the chicken's controls and knock it away.
@export var stun := false
@export var stun_seconds := 1.0
@export var stun_knockback_wu_s := 480.0
## SLIPPERY: a chicken standing on this block brakes and turns slowly and runs a little faster
## (Yelo ng Sorbetero ice; rates are GameplayTuning.ice_*). No credit: it never eliminates.
@export var slippery := false

@export_group("Special")
@export var special := Special.NONE:
	set(value):
		special = value
		update_configuration_warnings()
## Spawn Projectiles: the projectile template child (with a Path2D child it follows and a
## BlockHitbox for its touch effect). Straight paths fire like the Tsinelas lane.
@export_node_path("Node2D") var projectile_node: NodePath
## -1 = use the global GameplayTuning value for every number below.
@export var projectile_speed_wu_s := -1.0
@export var projectile_size_wu := -1.0
@export var fire_interval_s := -1.0
@export var initial_delay_s := -1.0
@export var telegraph_s := -1.0
@export var rail_speed_wu_s := -1.0
@export var rail_pause_s := -1.0
@export var rail_hit_wu := -1.0
@export var cycle_s := -1.0
@export var active_s := -1.0
@export var charge_s := -1.0
@export var beam_width_wu := -1.0
@export var launch_wu_s := -1.0
@export var boost_wu_s := -1.0
@export var launch_cooldown_s := -1.0
@export var bubble_cadence_s := -1.0
@export var bubble_rise_wu_s := -1.0
@export var capture_s := -1.0
@export var collapse_delay_s := -1.0
@export var collapse_respawn_s := -1.0
@export var push_speed_wu_s := -1.0

@export_group("Presentation")
## Optional legacy painter silhouette ("tire", "rail_top", "parol", "slipper", "broom", "flower",
## "crate", "bamboo_bridge", ...). Blank = eggs and pieces show this scene's Visual node.
@export var preview_silhouette := ""
@export var preview_cue := "ghost_outline"
@export var visual_set: ItemVisualSet


func _ready() -> void:
	if not Engine.is_editor_hint():
		visible = false


## Block-only GameplayTuning overrides: {field: value} for every parameter set >= 0.
func tuning_overrides() -> Dictionary:
	var result := {}
	for property in OVERRIDE_FIELDS:
		var value := float(get(property))
		if value >= 0.0:
			result[OVERRIDE_FIELDS[property]] = value
	return result


## Runtime behavior kind for the catalog ("" = static block with no timed or touch logic).
func behavior_kind(projectile_captures: bool) -> StringName:
	match special:
		Special.SPAWN_PROJECTILES:
			return &"bubble" if projectile_captures else &"launcher"
		Special.FOLLOW_RAIL:
			return &"trumpo"
		Special.TIMED_HITBOX:
			return &"parol"
		Special.LAUNCH:
			return &"spring"
	return &"hitbox" if kill or stun else &""


## Safe-start contract implied by the anchor and special.
func safe_start() -> String:
	match special:
		Special.SPAWN_PROJECTILES:
			return ItemFamilyDefinition.SAFE_START_IDLE
		Special.FOLLOW_RAIL:
			return ItemFamilyDefinition.SAFE_START_ENDPOINT
		Special.TIMED_HITBOX:
			return ItemFamilyDefinition.SAFE_START_INACTIVE_CHARGE
		Special.LAUNCH:
			return ItemFamilyDefinition.SAFE_START_READY
	if anchor != Anchor.ANCHORED:
		return ItemFamilyDefinition.SAFE_START_RESET_TO_PLACED
	return ItemFamilyDefinition.SAFE_START_STATIC


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if block_name.strip_edges().is_empty():
		warnings.append("Give the block a Block Name (shown in the Library).")
	var root := get_parent()
	if root != null and not root is StageBlock:
		warnings.append("The scene root should use res://scripts/items/blocks/stage_block.gd.")
	if special == Special.SPAWN_PROJECTILES and projectile_node.is_empty():
		warnings.append("Spawn Projectiles needs a Projectile Node (with a Path2D child).")
	return warnings


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var size := Vector2(placement_size) * AUTHOR_CELL_WU
	var box := Rect2(-size * 0.5, size)
	for column in range(1, placement_size.x):
		var x := box.position.x + column * AUTHOR_CELL_WU
		draw_line(Vector2(x, box.position.y), Vector2(x, box.end.y), Color(1, 1, 1, 0.25), 1.0)
	for row in range(1, placement_size.y):
		var y := box.position.y + row * AUTHOR_CELL_WU
		draw_line(Vector2(box.position.x, y), Vector2(box.end.x, y), Color(1, 1, 1, 0.25), 1.0)
	draw_rect(box, Color(0.3, 0.8, 1.0, 0.9), false, 2.0)

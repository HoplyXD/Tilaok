class_name ItemFamilyDefinition
extends Resource

const OWNERSHIP_PLACER := "placer"
const SAFE_START_STATIC := "static_no_motion"
const SAFE_START_ENDPOINT := "reset_to_endpoint"
const SAFE_START_INACTIVE_CHARGE := "reset_inactive_charge"
const SAFE_START_IDLE := "reset_idle"
const SAFE_START_READY := "reset_ready"
## Moves during Play (e.g. a pushed Wood Box) and returns to its placed spot at Place/Play start.
const SAFE_START_RESET_TO_PLACED := "reset_to_placed"
const SAFE_START_STATES: PackedStringArray = [
	SAFE_START_STATIC,
	SAFE_START_ENDPOINT,
	SAFE_START_INACTIVE_CHARGE,
	SAFE_START_IDLE,
	SAFE_START_READY,
	SAFE_START_RESET_TO_PLACED,
]
const SUPPORT_ROLE_SUPPORT := "support"
const SUPPORT_ROLE_NONE := "none"
const REMOVAL_WALIS := "walis_cleanup"
const PERSISTENCE_UNTIL_REMOVED := "until_removed"
const WALL_ELIGIBLE := "eligible"
const WALL_INELIGIBLE := "ineligible"

@export var family_id := ""
@export var working_name := ""
@export var category := ""
@export var variants: Array[ItemVariantDefinition] = []
@export var ownership := ""
@export var safe_start := ""
@export var removal_policy := ""
@export var persistence := ""
@export var modes_allowed: PackedStringArray = PackedStringArray()
@export var modes_pending_review: PackedStringArray = PackedStringArray()
@export var wall_contact := ""
## On: this family may be placed on a tile a player occupies (BlockData.can_place_on_player).
@export var can_place_on_player := false
## GameplayTuning field that supplies this family's Pugad selection weight.
@export var weight_tuning_key: StringName = &""
@export var preview_silhouette := ""
@export var preview_cue := ""
@export var library_tell := ""
@export var library_counterplay := ""
@export var implementation_complete := false
@export var independently_verified := false
@export var runtime_enabled := false
@export var release_target := false
## "support": solid faces may carry feet for wave support; "none": launch/hazard bodies never do.
@export var support_role := "support"
## Walis-style construction edit: its footprint is a cleanup area, nothing is placed or persisted.
@export var one_shot_edit := false
@export var visual_set: ItemVisualSet
## Scene-authored block families (scenes/blocks/, built by BlockCatalog from each BlockData).
@export var scene_authored := false
## Runtime behavior chosen from the block's special: "", "hitbox", "spring", "trumpo", "parol",
## "launcher", "bubble". Empty families use the legacy family-ID mapping.
@export var behavior_kind: StringName = &""
## Selection weight used when `uses_pool_weight` is set (scene blocks without a tuning key).
@export var pool_weight := 50.0
@export var uses_pool_weight := false
## Catalog membership: the main game (load_all) and the development item labs.
@export var in_main_game := true
@export var in_dev_labs := true


## Pugad family weight: the tuning field when one is named, else the authored pool weight.
func selection_weight(tuning: GameplayTuning) -> float:
	if weight_tuning_key != &"" and tuning != null and tuning.get(weight_tuning_key) != null:
		return float(tuning.get(weight_tuning_key))
	return pool_weight if uses_pool_weight else 0.0


func find_variant(variant_id_value: String) -> ItemVariantDefinition:
	for variant in variants:
		if variant != null and variant.variant_id == variant_id_value:
			return variant
	return null


func variant_key(variant: ItemVariantDefinition) -> String:
	return "%s.%s" % [family_id, variant.variant_id]

class_name ItemFamilyDefinition
extends Resource

const OWNERSHIP_PLACER := "placer"
const SAFE_START_STATIC := "static_no_motion"
const SAFE_START_ENDPOINT := "reset_to_endpoint"
const SAFE_START_INACTIVE_CHARGE := "reset_inactive_charge"
const SAFE_START_IDLE := "reset_idle"
const SAFE_START_READY := "reset_ready"
const SAFE_START_STATES: PackedStringArray = [
	SAFE_START_STATIC,
	SAFE_START_ENDPOINT,
	SAFE_START_INACTIVE_CHARGE,
	SAFE_START_IDLE,
	SAFE_START_READY,
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


func find_variant(variant_id_value: String) -> ItemVariantDefinition:
	for variant in variants:
		if variant != null and variant.variant_id == variant_id_value:
			return variant
	return null


func variant_key(variant: ItemVariantDefinition) -> String:
	return "%s.%s" % [family_id, variant.variant_id]

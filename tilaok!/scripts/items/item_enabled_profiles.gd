class_name ItemEnabledProfiles
extends RefCounted

## Profile-keyed enabled-variant sets for development rooms. The default `GameplayTuning` pool and
## `ItemDefinitions.load_all()` stay the P04 pair so seeded P04/P05 baselines are unchanged.
## Nothing here is release-enabled (docs/ITEMS.md, P10).

const ITEMS_LAB := "items_lab"
const KARERA_SPRING := "karera_spring"
const LAGSANAY_LAB := "lagsanay_lab"
const KANGAROO_CONTRACT_LAB := "kangaroo_contract_lab"
const DEV_WEIGHT := 50.0
const SPRING_PROFILE_VARIANTS: PackedStringArray = [
	"build.hollow_blocks.cell_1x1",
	"build.hollow_blocks.stack_2x3",
	"build.bamboo_bridge.span_4x1",
	"move.tire_spring.tire_2x2",
]
const LAGSANAY_VARIANTS: PackedStringArray = [
	"build.hollow_blocks.cell_1x1",
	"build.hollow_blocks.stack_2x3",
	"build.bamboo_bridge.span_4x1",
	"hazard.rail_trumpo.rail_4x1",
	"hazard.slipper_launcher.lane_4x1",
]
const KANGAROO_VARIANTS: PackedStringArray = [
	"build.hollow_blocks.cell_1x1",
	"build.hollow_blocks.stack_2x3",
	"build.bamboo_bridge.span_4x1",
	"hazard.rail_trumpo.rail_4x1",
	"hazard.slipper_launcher.lane_4x1",
]


static func uses_first_batch(profile_id: String) -> bool:
	return profile_id in [ITEMS_LAB, KARERA_SPRING, LAGSANAY_LAB, KANGAROO_CONTRACT_LAB]


static func enabled_variants(profile_id: String) -> PackedStringArray:
	if profile_id == KARERA_SPRING:
		return SPRING_PROFILE_VARIANTS
	if profile_id == LAGSANAY_LAB:
		return LAGSANAY_VARIANTS
	if profile_id == KANGAROO_CONTRACT_LAB:
		return KANGAROO_VARIANTS
	var keys := PackedStringArray()
	if profile_id != ITEMS_LAB:
		return keys
	for family_id in ItemApprovedVariants.TABLE:
		for variant_id in ItemApprovedVariants.TABLE[family_id] as Dictionary:
			keys.append("%s.%s" % [family_id, variant_id])
	return keys


## Applies the profile's pool and PROVISIONAL weights to a (snapshot) tuning copy.
static func apply(tuning: GameplayTuning, profile_id: String) -> void:
	if tuning == null or not uses_first_batch(profile_id):
		return
	tuning.item_enabled_variants = enabled_variants(profile_id)
	if profile_id == KARERA_SPRING:
		tuning.item_kaing_weight = 45.0
		tuning.item_tulay_weight = 40.0
		tuning.item_spring_weight = 15.0
		return
	if profile_id == LAGSANAY_LAB:
		tuning.item_kaing_weight = 45.0
		tuning.item_tulay_weight = 25.0
		tuning.item_spring_weight = 0.0
		tuning.item_trumpo_weight = 15.0
		tuning.item_parol_weight = 0.0
		tuning.item_launcher_weight = 15.0
		tuning.item_walis_weight = 0.0
		tuning.item_bubble_weight = 0.0
		return
	if profile_id == KANGAROO_CONTRACT_LAB:
		tuning.item_kaing_weight = 45.0
		tuning.item_tulay_weight = 25.0
		tuning.item_spring_weight = 0.0
		tuning.item_trumpo_weight = 15.0
		tuning.item_parol_weight = 0.0
		tuning.item_launcher_weight = 15.0
		tuning.item_walis_weight = 0.0
		tuning.item_bubble_weight = 0.0
		return
	tuning.item_kaing_weight = DEV_WEIGHT
	tuning.item_tulay_weight = DEV_WEIGHT
	tuning.item_spring_weight = DEV_WEIGHT
	tuning.item_trumpo_weight = DEV_WEIGHT
	tuning.item_parol_weight = DEV_WEIGHT
	tuning.item_launcher_weight = DEV_WEIGHT
	tuning.item_walis_weight = DEV_WEIGHT
	tuning.item_bubble_weight = DEV_WEIGHT

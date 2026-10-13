class_name ItemDefinitions
extends RefCounted

const DEFINITION_PATHS: PackedStringArray = [
	"res://data/items/build.hollow_blocks.tres",
	"res://data/items/build.bamboo_bridge.tres",
]

var families: Array[ItemFamilyDefinition] = []
var errors := PackedStringArray()
var tuning: GameplayTuning


static func load_all(source_tuning: GameplayTuning) -> ItemDefinitions:
	var result := ItemDefinitions.new()
	result.tuning = source_tuning
	for path in DEFINITION_PATHS:
		var loaded := ResourceLoader.load(path) as ItemFamilyDefinition
		if loaded == null:
			result.errors.append("could not load item definition '%s'" % path)
		else:
			result.families.append(loaded)
	result.errors.append_array(
		ItemDefinitionValidator.validate_families(result.families, source_tuning)
	)
	return result


static func from_families(
	source_families: Array[ItemFamilyDefinition], source_tuning: GameplayTuning
) -> ItemDefinitions:
	var result := ItemDefinitions.new()
	result.tuning = source_tuning
	result.families = source_families
	result.errors = ItemDefinitionValidator.validate_families(source_families, source_tuning)
	return result


func is_valid() -> bool:
	return errors.is_empty()


func find_family(family_id: String) -> ItemFamilyDefinition:
	for family in families:
		if family.family_id == family_id:
			return family
	return null


## Returns {family, variant} or an empty dictionary.
func find_variant(variant_key: String) -> Dictionary:
	for family in families:
		for variant in family.variants:
			if family.variant_key(variant) == variant_key:
				return {"family": family, "variant": variant}
	return {}


func is_variant_enabled(variant_key: String) -> bool:
	return tuning.item_enabled_variants.has(variant_key)


func enabled_variant_keys(family_id: String) -> PackedStringArray:
	var keys := PackedStringArray()
	var family := find_family(family_id)
	if family == null:
		return keys
	for variant in family.variants:
		var key := family.variant_key(variant)
		if is_variant_enabled(key):
			keys.append(key)
	return keys


## Selection-pool rows. A family with no enabled variant has weight zero (never selectable).
func catalog_entries() -> Array[DiagnosticContentEntry]:
	var entries: Array[DiagnosticContentEntry] = []
	for family in families:
		var weight := 0.0
		if not enabled_variant_keys(family.family_id).is_empty():
			weight = float(tuning.get(family.weight_tuning_key))
		entries.append(
			DiagnosticContentEntry.new(
				family.family_id,
				"item",
				family.implementation_complete,
				family.independently_verified,
				family.runtime_enabled,
				family.release_target,
				weight
			)
		)
	return entries

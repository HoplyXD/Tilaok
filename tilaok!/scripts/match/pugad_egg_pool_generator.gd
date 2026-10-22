class_name PugadEggPoolGenerator
extends RefCounted


## `mode_ids` are the round's active modes (Main and any Twist, e.g. ["karera", "lagsanay"]).
## When given, only families whose `modes_allowed` lists every one of them are dealt (catalog mode
## restrictions, P04-T11/T20 and P10 integration tasks). Empty means no mode filter.
static func generate(
	definitions: ItemDefinitions,
	tuning: GameplayTuning,
	streams: SeededDiagnosticStreams,
	egg_count: int,
	mode_ids: PackedStringArray = PackedStringArray(),
	excluded_variant_keys: PackedStringArray = PackedStringArray()
) -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	if definitions == null or tuning == null or streams == null or egg_count <= 0:
		return pool
	var eligible_families: Array[Dictionary] = []
	var total_weight := 0.0
	for family in definitions.families:
		if not allows_modes(family, mode_ids):
			continue
		var variants := definitions.enabled_variant_keys(family.family_id)
		for excluded_key in excluded_variant_keys:
			var excluded_index := variants.find(excluded_key)
			if excluded_index >= 0:
				variants.remove_at(excluded_index)
		if variants.is_empty():
			continue
		var weight := family.selection_weight(tuning)
		if weight <= 0.0:
			continue
		eligible_families.append({"family": family, "variants": variants, "weight": weight})
		total_weight += weight
	if eligible_families.is_empty() or total_weight <= 0.0:
		return pool
	for index in range(egg_count):
		var draw := streams.egg.randf() * total_weight
		var selected: Dictionary = eligible_families.back()
		for candidate in eligible_families:
			draw -= float(candidate.weight)
			if draw < 0.0:
				selected = candidate
				break
		var variants: PackedStringArray = selected.variants
		var variant_key := variants[streams.egg.randi_range(0, variants.size() - 1)]
		pool.append({"egg_id": "egg_%02d" % (index + 1), "variant_key": variant_key})
	return pool


## True when the family is approved for every active mode. A mode still pending review is not.
static func allows_modes(family: ItemFamilyDefinition, mode_ids: PackedStringArray) -> bool:
	if family == null:
		return false
	for mode_id in mode_ids:
		if not family.modes_allowed.has(mode_id):
			return false
	return true

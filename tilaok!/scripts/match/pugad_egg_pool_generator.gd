class_name PugadEggPoolGenerator
extends RefCounted


static func generate(
	definitions: ItemDefinitions,
	tuning: GameplayTuning,
	streams: SeededDiagnosticStreams,
	egg_count: int
) -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	if definitions == null or tuning == null or streams == null or egg_count <= 0:
		return pool
	var eligible_families: Array[Dictionary] = []
	var total_weight := 0.0
	for family in definitions.families:
		var variants := definitions.enabled_variant_keys(family.family_id)
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

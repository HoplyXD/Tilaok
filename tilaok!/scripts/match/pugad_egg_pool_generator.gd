class_name PugadEggPoolGenerator
extends RefCounted


## `mode_ids` are the round's active modes (Main and any Twist, e.g. ["karera", "lagsanay"]).
## When given, only families whose `modes_allowed` lists every one of them are dealt (catalog mode
## restrictions, P04-T11/T20 and P10 integration tasks). Empty means no mode filter.
## `without_replacement` randomizes distinct variants for one nest before a small pool refills.
static func generate(
	definitions: ItemDefinitions,
	tuning: GameplayTuning,
	streams: SeededDiagnosticStreams,
	egg_count: int,
	mode_ids: PackedStringArray = PackedStringArray(),
	excluded_variant_keys: PackedStringArray = PackedStringArray(),
	without_replacement: bool = false
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
	var draw_families := eligible_families.duplicate(true)
	var draw_weight := total_weight
	for index in range(egg_count):
		if draw_families.is_empty():
			# A mode can have fewer unique items than seats plus bonus eggs. Refill only after
			# showing every eligible variant once, so a small catalog still fills every nest slot.
			draw_families = eligible_families.duplicate(true)
			draw_weight = total_weight
		var draw := streams.egg.randf() * draw_weight
		var selected_index := draw_families.size() - 1
		for candidate_index in draw_families.size():
			var candidate: Dictionary = draw_families[candidate_index]
			draw -= float(candidate.weight)
			if draw < 0.0:
				selected_index = candidate_index
				break
		var selected: Dictionary = draw_families[selected_index]
		var variants: PackedStringArray = selected.variants
		var variant_index := streams.egg.randi_range(0, variants.size() - 1)
		var variant_key := variants[variant_index]
		pool.append({"egg_id": "egg_%02d" % (index + 1), "variant_key": variant_key})
		if without_replacement:
			variants.remove_at(variant_index)
		selected["variants"] = variants
		draw_families[selected_index] = selected
		if without_replacement:
			if variants.is_empty():
				draw_weight -= float(selected.weight)
				draw_families.remove_at(selected_index)
	return pool


## True when the family is approved for every active mode. A mode still pending review is not.
static func allows_modes(family: ItemFamilyDefinition, mode_ids: PackedStringArray) -> bool:
	if family == null:
		return false
	for mode_id in mode_ids:
		if not family.modes_allowed.has(mode_id):
			return false
	return true

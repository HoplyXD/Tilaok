class_name DiagnosticContentCatalog
extends RefCounted

const MODES: PackedStringArray = [
	"karera",
	"lagsanay",
	"kangaroo",
	"sudden_death_lagsanay",
	"stack_karera_lagsanay",
	"stack_karera_kangaroo",
	"stack_kangaroo_lagsanay"
]
const CONTENT_ID_PATTERN := "^[a-z][a-z0-9_]*(\\.[a-z][a-z0-9_]*)+$"

var entries: Array[DiagnosticContentEntry] = []
var verified_modes: PackedStringArray = PackedStringArray()


func validate_profile(profile: RunProfile) -> PackedStringArray:
	var errors := PackedStringArray()
	if profile == null:
		errors.append("Unknown profile ID.")
		return errors
	var validation := validate_catalog()
	errors.append_array(validation)
	for mode_id in profile.required_modes:
		if not MODES.has(mode_id):
			errors.append(
				"Profile '%s' references unknown mode '%s'." % [profile.profile_id, mode_id]
			)
		elif not verified_modes.has(mode_id):
			errors.append(
				(
					"Profile '%s' requires mode '%s', which is not implemented and verified."
					% [profile.profile_id, mode_id]
				)
			)
	for kind in profile.required_kinds:
		if kind not in ["item", "mode", "pair"]:
			errors.append(
				"Profile '%s' requires unknown pool kind '%s'." % [profile.profile_id, kind]
			)
		elif not has_selectable_kind(kind):
			errors.append(
				"Profile '%s' has an empty eligible '%s' pool." % [profile.profile_id, kind]
			)
	for content_id in profile.required_content_ids:
		var entry := find_entry(content_id)
		if entry == null:
			errors.append(
				"Profile '%s' references unknown content '%s'." % [profile.profile_id, content_id]
			)
		elif not is_selectable(entry):
			errors.append(
				(
					"Profile '%s' requires '%s', which is not implemented, verified, and enabled."
					% [profile.profile_id, content_id]
				)
			)
	if profile.profile_id == "release_candidate":
		for required_mode in ["karera", "lagsanay", "kangaroo", "sudden_death_lagsanay"]:
			if not verified_modes.has(required_mode):
				errors.append(
					(
						"Release profile is missing required scheduled/sudden-death mode '%s'."
						% required_mode
					)
				)
	return errors


func validate_catalog() -> PackedStringArray:
	var errors := PackedStringArray()
	var ids_seen := {}
	var id_regex := RegEx.new()
	id_regex.compile(CONTENT_ID_PATTERN)
	for entry in entries:
		if entry == null:
			errors.append("Content catalog contains a null entry.")
			continue
		if id_regex.search(entry.content_id) == null:
			errors.append("Invalid content ID '%s'." % entry.content_id)
		if ids_seen.has(entry.content_id):
			errors.append("Duplicate content ID '%s'." % entry.content_id)
		ids_seen[entry.content_id] = true
		if entry.kind not in ["item", "mode", "pair"]:
			errors.append("Content '%s' has unknown kind '%s'." % [entry.content_id, entry.kind])
		if not is_finite(entry.weight) or entry.weight < 0.0:
			errors.append("Content '%s' has an invalid selection weight." % entry.content_id)
		if (
			entry.runtime_enabled
			and not (entry.implementation_complete and entry.independently_verified)
		):
			errors.append(
				(
					"Content '%s' is runtime-enabled without implementation and verification."
					% entry.content_id
				)
			)
	for entry in entries:
		if entry == null:
			continue
		for reference_id in entry.references:
			if not ids_seen.has(reference_id):
				errors.append(
					"Content '%s' references unknown ID '%s'." % [entry.content_id, reference_id]
				)
	return errors


func eligible_entries(kind: String) -> Array[DiagnosticContentEntry]:
	var eligible: Array[DiagnosticContentEntry] = []
	for entry in entries:
		if entry != null and entry.kind == kind and is_selectable(entry) and entry.weight > 0.0:
			eligible.append(entry)
	return eligible


func normalized_weights(kind: String) -> Dictionary:
	var pool := eligible_entries(kind)
	var result := {}
	var total := 0.0
	for entry in pool:
		total += entry.weight
	if total <= 0.0:
		return result
	for entry in pool:
		result[entry.content_id] = entry.weight / total
	return result


func total_eligible_weight(kind: String) -> float:
	var total := 0.0
	for entry in eligible_entries(kind):
		total += entry.weight
	return total


func has_selectable_kind(kind: String) -> bool:
	return not eligible_entries(kind).is_empty()


func find_entry(content_id: String) -> DiagnosticContentEntry:
	for entry in entries:
		if entry != null and entry.content_id == content_id:
			return entry
	return null


static func is_selectable(entry: DiagnosticContentEntry) -> bool:
	return entry.implementation_complete and entry.independently_verified and entry.runtime_enabled

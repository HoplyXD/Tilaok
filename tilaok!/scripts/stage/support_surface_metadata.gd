class_name SupportSurfaceMetadata
extends Resource

enum Eligibility { UNSET = -1, INELIGIBLE = 0, ELIGIBLE = 1 }

const META_KEY := &"support_surface_metadata"

@export var surface_id := ""
@export var construction_id := ""
@export var player_built := false
@export var wave_support_eligibility := Eligibility.UNSET
@export var inherits_provenance_from := ""


func validate(known_surfaces: Dictionary = {}) -> PackedStringArray:
	var errors := PackedStringArray()
	if surface_id.is_empty():
		errors.append("support surface ID is required")
	if wave_support_eligibility == Eligibility.UNSET:
		errors.append("wave support eligibility must be explicit")
	elif wave_support_eligibility not in [Eligibility.INELIGIBLE, Eligibility.ELIGIBLE]:
		errors.append("wave support eligibility is invalid")
	if not inherits_provenance_from.is_empty():
		if not known_surfaces.has(inherits_provenance_from):
			errors.append("provenance parent '%s' is missing" % inherits_provenance_from)
		elif not bool(known_surfaces[inherits_provenance_from].player_built):
			errors.append("provenance parent must be player-built")
	elif player_built and construction_id.is_empty():
		errors.append("player-built surface requires a construction ID")
	elif not player_built and not construction_id.is_empty():
		errors.append("base surface cannot claim a player construction ID")
	return errors


func resolved_provenance(known_surfaces: Dictionary = {}) -> Dictionary:
	if not inherits_provenance_from.is_empty() and known_surfaces.has(inherits_provenance_from):
		var parent: SupportSurfaceMetadata = known_surfaces[inherits_provenance_from]
		return {"player_built": parent.player_built, "construction_id": parent.construction_id}
	return {"player_built": player_built, "construction_id": construction_id}


static func for_collider(collider: Object) -> SupportSurfaceMetadata:
	if collider is Node and (collider as Node).has_meta(META_KEY):
		return (collider as Node).get_meta(META_KEY) as SupportSurfaceMetadata
	return null

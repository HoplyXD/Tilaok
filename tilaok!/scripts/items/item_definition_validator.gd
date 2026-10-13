class_name ItemDefinitionValidator
extends RefCounted

const ALLOWED_MODES := ["karera", "lagsanay", "kangaroo"]
const ALLOWED_WALL_CONTACT := [
	ItemFamilyDefinition.WALL_ELIGIBLE,
	ItemFamilyDefinition.WALL_INELIGIBLE,
]
const REQUIRED_TEXT_FIELDS := [
	"working_name",
	"category",
	"preview_silhouette",
	"preview_cue",
	"library_tell",
	"library_counterplay",
]


static func validate_families(
	families: Array[ItemFamilyDefinition], tuning: GameplayTuning
) -> PackedStringArray:
	var errors := PackedStringArray()
	var seen_ids := {}
	var seen_keys := {}
	for family in families:
		if family == null:
			errors.append("definition list contains a null family")
			continue
		if not family.family_id.is_empty():
			if seen_ids.has(family.family_id):
				errors.append("duplicate family ID '%s'" % family.family_id)
			seen_ids[family.family_id] = true
		errors.append_array(validate_family(family, tuning))
		for variant in family.variants:
			if variant == null:
				continue
			var key := family.variant_key(variant)
			if seen_keys.has(key):
				errors.append("duplicate variant key '%s'" % key)
			seen_keys[key] = true
	for enabled_key in tuning.item_enabled_variants:
		if not seen_keys.has(enabled_key):
			errors.append("enabled variant '%s' is not defined" % enabled_key)
	return errors


static func validate_family(
	family: ItemFamilyDefinition, tuning: GameplayTuning
) -> PackedStringArray:
	var errors := PackedStringArray()
	if family == null:
		errors.append("family definition is missing")
		return errors
	var label := family.family_id if not family.family_id.is_empty() else "<unnamed family>"
	var id_regex := RegEx.new()
	id_regex.compile(DiagnosticContentCatalog.CONTENT_ID_PATTERN)
	if family.family_id.is_empty():
		errors.append("%s: family_id is required" % label)
	elif id_regex.search(family.family_id) == null:
		errors.append("%s: family_id is not a stable catalog ID" % label)
	for required in REQUIRED_TEXT_FIELDS:
		if str(family.get(required)).is_empty():
			errors.append("%s: %s is required" % [label, required])
	if family.ownership != ItemFamilyDefinition.OWNERSHIP_PLACER:
		errors.append("%s: ownership must be '%s'" % [label, ItemFamilyDefinition.OWNERSHIP_PLACER])
	if (
		family.safe_start
		not in [
			ItemFamilyDefinition.SAFE_START_STATIC,
			ItemFamilyDefinition.SAFE_START_RESET_TO_PLACED,
		]
	):
		errors.append("%s: safe_start is required and must be a documented state" % label)
	if family.removal_policy != ItemFamilyDefinition.REMOVAL_WALIS:
		errors.append("%s: removal_policy is required and must be a documented policy" % label)
	if family.persistence != ItemFamilyDefinition.PERSISTENCE_UNTIL_REMOVED:
		errors.append("%s: persistence is required and must be a documented policy" % label)
	if family.modes_allowed.is_empty():
		errors.append("%s: event eligibility (modes_allowed) is required" % label)
	for mode_id in family.modes_allowed:
		if mode_id not in ALLOWED_MODES:
			errors.append("%s: unknown mode '%s'" % [label, mode_id])
		if family.modes_pending_review.has(mode_id):
			errors.append("%s: mode '%s' cannot be allowed and pending review" % [label, mode_id])
	for mode_id in family.modes_pending_review:
		if mode_id not in ALLOWED_MODES:
			errors.append("%s: unknown mode '%s'" % [label, mode_id])
	if family.wall_contact not in ALLOWED_WALL_CONTACT:
		errors.append("%s: wall_contact declaration is required" % label)
	if family.weight_tuning_key == &"" or tuning.get(family.weight_tuning_key) == null:
		errors.append("%s: weight_tuning_key must name a tuning field" % label)
	if (
		family.runtime_enabled
		and not (family.implementation_complete and family.independently_verified)
	):
		errors.append("%s: runtime_enabled requires implementation and verification" % label)
	if family.variants.is_empty():
		errors.append("%s: at least one variant is required" % label)
	var variant_ids := {}
	for variant in family.variants:
		if variant == null:
			errors.append("%s: null variant entry" % label)
			continue
		if variant_ids.has(variant.variant_id):
			errors.append("%s: duplicate variant '%s'" % [label, variant.variant_id])
		variant_ids[variant.variant_id] = true
		errors.append_array(_validate_variant(family, variant, tuning))
	return errors


static func _validate_variant(
	family: ItemFamilyDefinition, variant: ItemVariantDefinition, tuning: GameplayTuning
) -> PackedStringArray:
	var errors := PackedStringArray()
	var label := "%s.%s" % [family.family_id, variant.variant_id]
	if variant.variant_id.is_empty():
		errors.append("%s: variant_id is required" % label)
		return errors
	if not ItemApprovedVariants.is_approved(family.family_id, variant.variant_id):
		errors.append("%s: undocumented variant (not in the approved variant table)" % label)
	else:
		var documented := ItemApprovedVariants.approved_footprint(
			family.family_id, variant.variant_id
		)
		if variant.footprint_cells != documented:
			errors.append(
				(
					"%s: footprint %s does not match documented %s"
					% [label, variant.footprint_cells, documented]
				)
			)
	if variant.footprint_cells.x <= 0 or variant.footprint_cells.y <= 0:
		errors.append("%s: footprint is required and must be positive" % label)
		return errors
	if variant.rotations.is_empty():
		errors.append("%s: at least one documented rotation is required" % label)
	for turn in variant.rotations:
		if turn < 0 or turn > 3:
			errors.append("%s: rotation %d is outside 0..3 quarter turns" % [label, turn])
	for turn in variant.gated_rotations:
		if not variant.rotations.has(turn):
			errors.append("%s: gated rotation %d is not a documented rotation" % [label, turn])
	if variant.regions.is_empty():
		errors.append("%s: at least one region is required" % label)
	var footprint_rect := Rect2(Vector2.ZERO, Vector2(variant.footprint_cells))
	var arena_extent := Vector2(tuning.arena_width_tiles, tuning.arena_height_tiles)
	var solid_rects: Array[Rect2] = []
	var one_way_rects: Array[Rect2] = []
	var has_collision := false
	for region in variant.regions:
		if region == null or region.kind == ItemRegionSpec.Kind.UNSET:
			errors.append("%s: region kind is required" % label)
			continue
		var kind_label := "%s %s" % [label, ItemRegionSpec.kind_name(region.kind)]
		var rect := region.rect_cells
		var finite := (
			is_finite(rect.position.x)
			and is_finite(rect.position.y)
			and is_finite(rect.size.x)
			and is_finite(rect.size.y)
		)
		if not finite or rect.size.x <= 0.0 or rect.size.y <= 0.0:
			errors.append("%s: region has missing, unbounded or non-positive extent" % kind_label)
			continue
		if rect.size.x > arena_extent.x or rect.size.y > arena_extent.y:
			errors.append("%s: region exceeds the arena extent (unbounded)" % kind_label)
			continue
		if ItemRegionSpec.is_bounded_extent_kind(region.kind):
			if not region.declared_bounded:
				errors.append("%s: region must declare explicit bounds" % kind_label)
		elif not footprint_rect.encloses(rect):
			errors.append("%s: region must lie inside the footprint" % kind_label)
		if region.kind == ItemRegionSpec.Kind.ONE_WAY_TOP:
			var thickness: Variant = tuning.get(region.thickness_tuning_key)
			if region.thickness_tuning_key == &"" or thickness == null:
				errors.append("%s: one-way strip needs a thickness tuning key" % kind_label)
			elif float(thickness) <= 0.0 or float(thickness) > rect.size.y * tuning.grid_cell_wu:
				errors.append("%s: strip thickness is outside its region" % kind_label)
			one_way_rects.append(rect)
		if region.kind == ItemRegionSpec.Kind.SOLID:
			solid_rects.append(rect)
		if ItemRegionSpec.is_collision_kind(region.kind):
			has_collision = true
	for one_way in one_way_rects:
		for solid in solid_rects:
			if one_way.intersects(solid, false):
				errors.append("%s: a one-way strip may not overlap a solid region" % label)
	if not has_collision and not variant.regions.is_empty():
		errors.append("%s: no collision-bearing (solid or one-way) region is defined" % label)
	return errors

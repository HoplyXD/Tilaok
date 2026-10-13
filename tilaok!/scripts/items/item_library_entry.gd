class_name ItemLibraryEntry
extends RefCounted

## PLACEHOLDER Library entry model built only from item definitions. The shared Library schema
## and shell belong to P13; this keeps the fields the entry must expose testable now.

const CONTROLS_TEXT := "K1 WASD/R/F  •  K2 arrows/Right Shift/Enter (move, rotate, confirm)"

var family_id := ""
var display_name := ""
var sizes: PackedStringArray = PackedStringArray()
var enabled_variant_keys: PackedStringArray = PackedStringArray()
var placement := ""
var tell := ""
var counterplay := ""
var controls := CONTROLS_TEXT
var modes_allowed: PackedStringArray = PackedStringArray()
var modes_pending_review: PackedStringArray = PackedStringArray()
var release_enabled := false
var animation_variant_key := ""


static func from_family(
	family: ItemFamilyDefinition, definitions: ItemDefinitions
) -> ItemLibraryEntry:
	var entry := ItemLibraryEntry.new()
	entry.family_id = family.family_id
	entry.display_name = "%s (working name)" % family.working_name
	for variant in family.variants:
		var key := family.variant_key(variant)
		var size_text := "%d×%d" % [variant.footprint_cells.x, variant.footprint_cells.y]
		if definitions.is_variant_enabled(key):
			entry.enabled_variant_keys.append(key)
			entry.sizes.append(size_text)
		else:
			entry.sizes.append("%s (not enabled yet)" % size_text)
	entry.placement = (
		"Snaps to the grid inside the build region; cannot overlap stage ground, other "
		+ "pieces, the spawn or goal areas, or a chicken. Rotate where the shape allows."
	)
	entry.tell = family.library_tell
	entry.counterplay = family.library_counterplay
	entry.modes_allowed = family.modes_allowed
	entry.modes_pending_review = family.modes_pending_review
	entry.release_enabled = family.release_target and family.runtime_enabled
	if not entry.enabled_variant_keys.is_empty():
		entry.animation_variant_key = entry.enabled_variant_keys[0]
	return entry


## Release filter: only content that is both enabled and a release target is listed.
static func build_list(
	definitions: ItemDefinitions, release_filter: bool
) -> Array[ItemLibraryEntry]:
	var entries: Array[ItemLibraryEntry] = []
	for family in definitions.families:
		var entry := from_family(family, definitions)
		if entry.enabled_variant_keys.is_empty():
			continue
		if release_filter and not entry.release_enabled:
			continue
		entries.append(entry)
	return entries


func text_block() -> String:
	return (
		"%s\nSizes: %s\nPlacement: %s\nTell: %s\nCounter: %s\nControls: %s\nModes: %s%s"
		% [
			display_name,
			", ".join(sizes),
			placement,
			tell,
			counterplay,
			controls,
			", ".join(modes_allowed),
			(
				"  (pending review: %s)" % ", ".join(modes_pending_review)
				if not modes_pending_review.is_empty()
				else ""
			)
		]
	)

class_name PlaceholderAudit
extends RefCounted

## Release gate for presentation: PLACEHOLDER art/audio may ship in a development profile, but a
## family that is both a release target and runtime-enabled must not still use any of it.

const ASSET_ROOT := "res://assets/items"
const FILE_PREFIX := "PLACEHOLDER_"


## One row per placeholder slot: "family • slot • file".
static func slot_rows(definitions: ItemDefinitions) -> PackedStringArray:
	var rows := PackedStringArray()
	for family in definitions.families:
		if family.visual_set == null:
			continue
		for slot in family.visual_set.slots:
			if slot.placeholder:
				rows.append("%s • %s • %s" % [family.family_id, slot.slot_id, _slot_file(slot)])
	return rows


## Release-enabled families that still use a placeholder (must be empty before release).
static func release_violations(definitions: ItemDefinitions) -> PackedStringArray:
	var violations := PackedStringArray()
	for family in definitions.families:
		if not (family.release_target and family.runtime_enabled):
			continue
		if family.visual_set == null:
			violations.append("%s has no visual set" % family.family_id)
			continue
		for slot_id in family.visual_set.placeholder_slot_ids():
			violations.append("%s still uses PLACEHOLDER slot '%s'" % [family.family_id, slot_id])
	return violations


## Every file under the item asset root whose name marks it as a placeholder.
static func placeholder_files() -> PackedStringArray:
	var found := PackedStringArray()
	_scan(ASSET_ROOT, found)
	found.sort()
	return found


static func _scan(path: String, found: PackedStringArray) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		return
	for sub_directory in directory.get_directories():
		_scan("%s/%s" % [path, sub_directory], found)
	for file_name in directory.get_files():
		if file_name.begins_with(FILE_PREFIX) and not file_name.ends_with(".import"):
			found.append("%s/%s" % [path, file_name])


static func _slot_file(slot: ItemVisualSlot) -> String:
	if not slot.frames.is_empty() and slot.frames[0] != null:
		return slot.frames[0].resource_path.get_file()
	if slot.sound != null:
		return slot.sound.resource_path.get_file()
	return "(code-drawn fallback)"

class_name CompatibilityManifest
extends RefCounted

## NLB-P06 changed the gameplay wire (schema 3, live placement) and NLB-P07 changed it again
## (schema 4, live transients, live content matrix), so the build identity changed too: an older
## binary's digest differs and it shows the readable build-mismatch notice.
const BUILD_ID := "tilaok-nlb-p07-2026-10-21"
const PROFILE_ID := "karera_slice"
## Network routes this binary can host or join; the host picks one per match (MATCH_LIFECYCLE).
const NETWORK_ROUTES := ["network_live_build", "scheduled"]


static func build(profile_id: String = PROFILE_ID) -> Dictionary:
	var tuning := GameplayTuning.new()
	tuning.item_enabled_variants = BlockCatalog.default_enabled_keys()
	ItemEnabledProfiles.apply(tuning, profile_id)
	var definitions := ItemDefinitions.load_for_profile(tuning, profile_id)
	var manifest := {
		"wire_major": NetworkFrame.MAJOR,
		"wire_minor": NetworkFrame.MINOR,
		"schema": 1,
		"build": BUILD_ID,
		"engine": Engine.get_version_info().string,
		"profile": profile_id,
		"routes": NETWORK_ROUTES.duplicate(),
		"maps": _map_records(),
		"items": _item_records(definitions),
		# NLB-P07: the live-route compatibility matrix is part of the content identity.
		"live_matrix": NLBLiveCompatibilityMatrix.manifest_record(),
	}
	return {"manifest": manifest, "bytes": canonical_bytes(manifest), "digest": sha256(manifest)}


static func reload_sources() -> void:
	MapCatalog.reload()
	BlockCatalog.reload()
	NLBLiveCompatibilityMatrix.reload()


## A local invalidation hint only; paths/times never enter the compatibility manifest.
static func source_fingerprint() -> String:
	var paths: Array[String] = []
	for directory in [
		"res://scenes/maps",
		"res://scenes/blocks",
		"res://assets/tiles",
		"res://scripts/items",
		"res://scripts/stage"
	]:
		_collect_files(directory, paths)
	paths.sort()
	var values := PackedStringArray()
	for path in paths:
		var absolute := ProjectSettings.globalize_path(path)
		var source := FileAccess.open(absolute, FileAccess.READ)
		if source != null:
			values.append(
				"%s:%d:%d" % [path, FileAccess.get_modified_time(absolute), source.get_length()]
			)
			source.close()
	return "\n".join(values)


static func _collect_files(directory: String, output: Array[String]) -> void:
	var access := DirAccess.open(directory)
	if access == null:
		return
	for name in access.get_files():
		if name.ends_with(".uid") or name.ends_with(".import"):
			continue
		output.append(directory.path_join(name))
	for name in access.get_directories():
		_collect_files(directory.path_join(name), output)


static func canonical_bytes(value: Variant) -> PackedByteArray:
	return JSON.stringify(_canonical(value), "", true).to_utf8_buffer()


static func sha256(value: Variant) -> PackedByteArray:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(canonical_bytes(value))
	return context.finish()


static func digest_hex(value: Variant) -> String:
	return sha256(value).hex_encode()


static func _canonical(value: Variant) -> Variant:
	if value is Dictionary:
		var result := {}
		var keys: Array = value.keys()
		keys.sort()
		for key in keys:
			result[str(key)] = _canonical(value[key])
		return result
	if value is Array or value is PackedStringArray:
		var result: Array = []
		for item in value:
			result.append(_canonical(item))
		return result
	if value is Vector2i:
		return [value.x, value.y]
	if value is Vector2:
		return [value.x, value.y]
	if value is Rect2:
		return [value.position.x, value.position.y, value.size.x, value.size.y]
	if value is Rect2i:
		return [value.position.x, value.position.y, value.size.x, value.size.y]
	return value


static func _map_records() -> Array[Dictionary]:
	var ids := Array(MapCatalog.ids())
	ids.sort()
	var records: Array[Dictionary] = []
	for map_id in ids:
		var record := {"id": map_id, "cells": [], "no_wall_slide": []}
		var layout := MapCatalog.layout_for(map_id)
		if layout != null:
			record["layout"] = _layout_record(layout)
		else:
			record["layout"] = {"default_stage": true}
		var entry := MapCatalog.entry_for(map_id)
		if not str(entry.get("path", "")).is_empty():
			var packed := load(str(entry.path)) as PackedScene
			var map := packed.instantiate() as StageMap if packed != null else null
			if map != null:
				for cell in map.block_cells():
					record.cells.append([cell.x, cell.y])
					if map.is_no_wall_slide(cell):
						record.no_wall_slide.append([cell.x, cell.y])
				map.free()
		records.append(record)
	return records


static func _layout_record(layout: ArenaLayout) -> Dictionary:
	var surfaces: Array = []
	for surface in layout.surfaces:
		(
			surfaces
			. append(
				{
					"id": surface.surface_id,
					"rect": _canonical(surface.rect_tiles),
					"wall_eligible": surface.wall_eligible,
					"custom_visual": surface.custom_visual,
				}
			)
		)
	surfaces.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool: return JSON.stringify(a) < JSON.stringify(b)
	)
	return {
		"spawn": _canonical(layout.spawn_feet_tiles),
		"flag": _canonical(layout.goal_trigger_tiles),
		"protected_goal": _canonical(layout.protected_goal_tiles),
		"build_zone": _canonical(layout.build_region_tiles),
		"surfaces": surfaces,
	}


static func _item_records(definitions: ItemDefinitions) -> Array[Dictionary]:
	var records: Array[Dictionary] = []
	for family in definitions.families:
		var variants: Array = []
		for variant in family.variants:
			var regions: Array = []
			for region in variant.regions:
				regions.append(
					{
						"kind": ItemRegionSpec.kind_name(region.kind),
						"rect": _canonical(region.rect_cells),
						"effect": str(region.effect),
						"thickness": region.thickness_wu,
						"blockable": region.blockable,
						"bounded": region.declared_bounded
					}
				)
			regions.sort_custom(
				func(a: Dictionary, b: Dictionary) -> bool:
					return JSON.stringify(a) < JSON.stringify(b)
			)
			(
				variants
				. append(
					{
						"id": variant.variant_id,
						"footprint": _canonical(variant.footprint_cells),
						"rotations": Array(variant.rotations),
						"gated_rotations": Array(variant.gated_rotations),
						"regions": regions,
						"occupied_cells": _canonical(variant.occupied_cells),
						"requires_collision": variant.requires_collision,
						"enabled": definitions.is_variant_enabled(family.variant_key(variant)),
						"enabled_by_default": variant.enabled_by_default,
						"tuning": _canonical(variant.tuning_overrides),
						"params": _canonical(variant.effect_params),
					}
				)
			)
		variants.sort_custom(
			func(a: Dictionary, b: Dictionary) -> bool: return str(a.id) < str(b.id)
		)
		records.append(
			{
				"family": family.family_id,
				"behavior": str(family.behavior_kind),
				"variants": variants
			}
		)
		records[-1]["category"] = family.category
		records[-1]["ownership"] = family.ownership
		records[-1]["safe_start"] = family.safe_start
		records[-1]["removal_policy"] = family.removal_policy
		records[-1]["persistence"] = family.persistence
		records[-1]["modes_allowed"] = _sorted_strings(family.modes_allowed)
		records[-1]["modes_pending_review"] = _sorted_strings(family.modes_pending_review)
		records[-1]["support_role"] = family.support_role
		records[-1]["one_shot_edit"] = family.one_shot_edit
		records[-1]["complete"] = family.implementation_complete
	records.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool: return str(a.family) < str(b.family)
	)
	return records


static func _sorted_strings(values: PackedStringArray) -> Array[String]:
	var result: Array[String] = []
	for value in values:
		result.append(value)
	result.sort()
	return result

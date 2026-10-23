class_name BlockCatalog
extends RefCounted

## Folder-scanned catalog of scene-authored blocks. Every .tscn under BLOCKS_DIR (recursively)
## whose root has a BlockData child becomes one item variant; variants sharing a family ID form
## one ItemFamilyDefinition. Regions come from the scene's nodes:
## - root CollisionShape2D (RectangleShape2D) -> SOLID, or ONE_WAY_TOP when one_way_collision;
## - BlockHitbox areas -> TRIGGER (kill/stun/launch), SWEEP, EFFECT (beam/capture/cleanup), LANE;
## - the Spawn Projectiles template's Path2D -> LANE (or EFFECT "capture" for bubbles).
## So a new block needs only its scene: no .tres, table, factory or pool edit.

const BLOCKS_DIR := "res://scenes/blocks"
const SET_MAIN := "main"
const SET_LAB := "lab"
const SCENE_PREVIEW := "scene"

static var _cache: Dictionary = {}


## Clears the cached scan (tests, or after adding scenes at runtime).
static func reload() -> void:
	_cache.clear()


## Scan result for `directory`: {"families": Array[ItemFamilyDefinition], "scenes": {key: path},
## "errors": PackedStringArray}. Cached per directory.
static func scan(directory: String = BLOCKS_DIR) -> Dictionary:
	if _cache.has(directory):
		return _cache[directory]
	var entries: Array[Dictionary] = []
	var errors := PackedStringArray()
	for path in _scene_paths(directory):
		var entry := _read_scene(path, errors)
		if not entry.is_empty():
			entries.append(entry)
	var result := _build_families(entries, errors)
	_cache[directory] = result
	_drop_invalid(result)
	return result


## Families for a set: SET_MAIN (the main game, load_all) or SET_LAB (development item labs).
static func families(set_name: String = SET_MAIN, directory: String = BLOCKS_DIR) -> Array:
	var result: Array[ItemFamilyDefinition] = []
	for family in scan(directory).families:
		var item := family as ItemFamilyDefinition
		if (
			(set_name == SET_MAIN and item.in_main_game)
			or (set_name == SET_LAB and item.in_dev_labs)
		):
			result.append(item)
	return result


static func scene_path_for(variant_key: String, directory: String = BLOCKS_DIR) -> String:
	return str(scan(directory).scenes.get(variant_key, ""))


## A fresh copy of the variant scene's Visual node for previews (eggs, Library), without text
## labels. The caller owns and frees it. Null when the scene has no Visual.
static func preview_visual(variant: ItemVariantDefinition) -> Node2D:
	if variant == null or variant.scene_path.is_empty():
		return null
	var packed := load(variant.scene_path) as PackedScene
	if packed == null:
		return null
	var root := packed.instantiate()
	var visual := root.get_node_or_null(StageBlock.VISUAL_NODE) as Node2D
	if visual == null:
		root.free()
		return null
	root.remove_child(visual)
	root.free()
	_strip_labels(visual)
	return visual


static func _strip_labels(node: Node) -> void:
	for child in node.get_children():
		if child is Label:
			node.remove_child(child)
			child.free()
		else:
			_strip_labels(child)


static func errors(directory: String = BLOCKS_DIR) -> PackedStringArray:
	return scan(directory).errors


## Blocks left out of the catalog because they fail validation (see _build_families).
static func skipped(directory: String = BLOCKS_DIR) -> PackedStringArray:
	return scan(directory).get("skipped", PackedStringArray())


## {family_id: {variant_id: footprint}} for every scanned block: the documented variant table.
static func approved_table(directory: String = BLOCKS_DIR) -> Dictionary:
	var table := {}
	for family in scan(directory).families:
		var rows := {}
		for variant in (family as ItemFamilyDefinition).variants:
			rows[variant.variant_id] = variant.footprint_cells
		table[(family as ItemFamilyDefinition).family_id] = rows
	return table


## Default enabled pool: main-game variants marked enabled_by_default, in catalog order.
static func default_enabled_keys(directory: String = BLOCKS_DIR) -> PackedStringArray:
	var keys := PackedStringArray()
	for family in families(SET_MAIN, directory):
		for variant in (family as ItemFamilyDefinition).variants:
			if variant.enabled_by_default:
				keys.append((family as ItemFamilyDefinition).variant_key(variant))
	return keys


## Every development-lab variant, in catalog order.
static func lab_keys(directory: String = BLOCKS_DIR) -> PackedStringArray:
	var keys := PackedStringArray()
	for family in families(SET_LAB, directory):
		for variant in (family as ItemFamilyDefinition).variants:
			keys.append((family as ItemFamilyDefinition).variant_key(variant))
	return keys


static func _scene_paths(directory: String) -> PackedStringArray:
	var found := PackedStringArray()
	if not DirAccess.dir_exists_absolute(directory):
		return found
	for name in ResourceLoader.list_directory(directory):
		var child := directory.path_join(name)
		if name.ends_with("/"):
			found.append_array(_scene_paths(child.trim_suffix("/")))
		elif name.get_extension() == "tscn":
			found.append(child)
	found.sort()
	return found


## Reads one block scene into {data fields, variant, family_id, order}; empty when not a block.
static func _read_scene(path: String, errors: PackedStringArray) -> Dictionary:
	var packed := load(path) as PackedScene
	if packed == null:
		errors.append("%s: could not load" % path)
		return {}
	var root := packed.instantiate() as Node2D
	if root == null:
		return {}
	var data: BlockData = null
	for child in root.get_children():
		if child is BlockData:
			data = child
			break
	if data == null:
		root.free()
		return {}
	var file_id := path.get_file().get_basename()
	var family_id := data.family_id if not data.family_id.is_empty() else "block.%s" % file_id
	var variant_id := data.variant_id if not data.variant_id.is_empty() else "main"
	var collected := _collect_regions(root, data)
	var variant := ItemVariantDefinition.new()
	variant.variant_id = variant_id
	variant.footprint_cells = data.placement_size
	variant.regions = collected.regions
	variant.rotations = data.rotations.duplicate()
	variant.gated_rotations = data.gated_rotations.duplicate()
	variant.requires_collision = bool(collected.has_collision)
	variant.scene_path = path
	variant.enabled_by_default = data.enabled_by_default
	variant.tuning_overrides = data.tuning_overrides()
	variant.effect_params = {
		"stun_seconds": data.stun_seconds,
		"stun_knockback_wu_s": data.stun_knockback_wu_s,
	}
	if data.reserve_only_solid_cells:
		var occupied: Array[Rect2i] = []
		for rect in collected.solid_cells:
			occupied.append(rect)
		variant.occupied_cells = occupied
	var entry := {
		"path": path,
		"family_id": family_id,
		"order": data.catalog_order,
		"variant": variant,
		"family": _family_from(data, family_id, bool(collected.captures)),
	}
	root.free()
	return entry


static func _family_from(
	data: BlockData, family_id: String, captures: bool
) -> ItemFamilyDefinition:
	var family := ItemFamilyDefinition.new()
	family.family_id = family_id
	family.working_name = data.block_name if not data.block_name.is_empty() else family_id
	family.category = data.category
	family.ownership = ItemFamilyDefinition.OWNERSHIP_PLACER
	family.safe_start = data.safe_start()
	family.removal_policy = ItemFamilyDefinition.REMOVAL_WALIS
	family.persistence = ItemFamilyDefinition.PERSISTENCE_UNTIL_REMOVED
	family.modes_allowed = data.modes_allowed.duplicate()
	family.modes_pending_review = data.modes_pending_review.duplicate()
	family.wall_contact = (
		ItemFamilyDefinition.WALL_ELIGIBLE
		if data.wall_slide_eligible
		else ItemFamilyDefinition.WALL_INELIGIBLE
	)
	family.can_place_on_player = data.can_place_on_player
	family.weight_tuning_key = data.weight_tuning_key
	family.uses_pool_weight = data.weight_tuning_key == &""
	family.pool_weight = data.pool_weight
	# "scene" = eggs, ghosts and the Library show this block scene's own Visual node.
	family.preview_silhouette = (
		data.preview_silhouette if not data.preview_silhouette.is_empty() else SCENE_PREVIEW
	)
	family.preview_cue = data.preview_cue
	family.library_tell = (
		data.library_tell
		if not data.library_tell.is_empty()
		else "%s: see its shape in the egg and ghost." % family.working_name
	)
	family.library_counterplay = (
		data.library_counterplay
		if not data.library_counterplay.is_empty()
		else "Route around it or use Walis Cleanup."
	)
	family.implementation_complete = true
	family.independently_verified = true
	family.runtime_enabled = true
	family.release_target = false
	family.support_role = (
		ItemFamilyDefinition.SUPPORT_ROLE_SUPPORT
		if data.counts_as_support
		else ItemFamilyDefinition.SUPPORT_ROLE_NONE
	)
	family.one_shot_edit = data.special == BlockData.Special.CLEANUP
	family.visual_set = data.visual_set
	family.scene_authored = true
	family.behavior_kind = data.behavior_kind(captures)
	family.in_main_game = data.in_main_game
	family.in_dev_labs = data.in_dev_labs
	return family


## Regions in grid cells relative to the unrotated placement box's top-left corner.
static func _collect_regions(root: Node2D, data: BlockData) -> Dictionary:
	var cell := BlockData.AUTHOR_CELL_WU
	var half := Vector2(data.placement_size) * cell * 0.5
	var regions: Array[ItemRegionSpec] = []
	var solid_cells: Array[Rect2i] = []
	var has_collision := false
	var captures := false
	var projectile := root.get_node_or_null(data.projectile_node) as Node2D
	if data.projectile_node.is_empty():
		projectile = null
	for child in root.get_children():
		var collision := child as CollisionShape2D
		if collision == null or not collision.shape is RectangleShape2D:
			continue
		var rect := _cells(_shape_rect(collision, root), half, cell)
		var region := ItemRegionSpec.new()
		if collision.one_way_collision:
			region.kind = ItemRegionSpec.Kind.ONE_WAY_TOP
			if data.one_way_thickness_key != &"":
				region.thickness_tuning_key = data.one_way_thickness_key
				rect.size.y = maxf(rect.size.y, 1.0)
			else:
				region.thickness_wu = (collision.shape as RectangleShape2D).size.y
		else:
			region.kind = ItemRegionSpec.Kind.SOLID
			solid_cells.append(Rect2i(Vector2i(rect.position.floor()), Vector2i(rect.size.ceil())))
		region.rect_cells = rect
		regions.append(region)
		has_collision = true
	for hitbox in _hitboxes(root):
		if projectile != null and projectile.is_ancestor_of(hitbox):
			continue
		for local_rect in _hitbox_rects(hitbox, root):
			regions.append(_hitbox_region(hitbox, _cells(local_rect, half, cell), data))
	if projectile != null:
		var effect := &"kill"
		for hitbox in _hitboxes(projectile):
			if hitbox.effect == BlockHitbox.Effect.STUN:
				effect = &"stun"
			elif hitbox.effect == BlockHitbox.Effect.CAPTURE_PATH:
				effect = &"capture"
		if effect != &"capture":
			effect = _gated_effect(effect, data)
		var path_rect := _path_rect(projectile, root)
		if path_rect.size != Vector2.ZERO:
			var region := ItemRegionSpec.new()
			captures = effect == &"capture"
			region.kind = ItemRegionSpec.Kind.EFFECT if captures else ItemRegionSpec.Kind.LANE
			region.rect_cells = _cells(path_rect, half, cell)
			region.declared_bounded = true
			region.blockable = true
			region.effect = effect
			# Clamped to the stage (drawn past it): "as far as it can go" once placed.
			var stage := Vector2(StageMap.ARENA_SIZE) * BlockData.AUTHOR_CELL_WU
			region.reach_stage_edge = (
				is_equal_approx(path_rect.size.x, stage.x)
				or is_equal_approx(path_rect.size.y, stage.y)
			)
			regions.append(region)
	return {
		"regions": regions,
		"solid_cells": solid_cells,
		"has_collision": has_collision,
		"captures": captures,
	}


static func _hitbox_region(hitbox: BlockHitbox, rect: Rect2, data: BlockData) -> ItemRegionSpec:
	var region := ItemRegionSpec.new()
	region.rect_cells = rect
	region.effect = _gated_effect(hitbox.effect_name(), data)
	match hitbox.effect:
		BlockHitbox.Effect.KILL, BlockHitbox.Effect.STUN, BlockHitbox.Effect.LAUNCH:
			region.kind = ItemRegionSpec.Kind.TRIGGER
		BlockHitbox.Effect.SWEEP:
			region.kind = ItemRegionSpec.Kind.SWEEP
			region.declared_bounded = true
		BlockHitbox.Effect.LANE:
			region.kind = ItemRegionSpec.Kind.LANE
			region.declared_bounded = true
			region.blockable = true
		BlockHitbox.Effect.BEAM, BlockHitbox.Effect.CAPTURE_PATH:
			region.kind = ItemRegionSpec.Kind.EFFECT
			region.declared_bounded = true
			region.blockable = true
		BlockHitbox.Effect.CLEANUP_AREA:
			region.kind = ItemRegionSpec.Kind.EFFECT
			region.declared_bounded = true
	return region


## Kill/stun hitboxes act only when the block's Kill/Stun effect is switched on.
static func _gated_effect(effect: StringName, data: BlockData) -> StringName:
	if effect == &"kill" and not data.kill:
		return &""
	if effect == &"stun" and not data.stun:
		return &""
	return effect


static func _hitboxes(root: Node) -> Array[BlockHitbox]:
	var result: Array[BlockHitbox] = []
	for child in root.get_children():
		if child is BlockHitbox:
			result.append(child)
		result.append_array(_hitboxes(child))
	return result


## Transform from `node` to `root` using local transforms only (works outside the scene tree).
static func _to_root(node: Node, root: Node) -> Transform2D:
	var result := Transform2D.IDENTITY
	var current := node
	while current != null and current != root:
		if current is Node2D:
			result = (current as Node2D).transform * result
		current = current.get_parent()
	return result


static func _shape_rect(collision: CollisionShape2D, root: Node) -> Rect2:
	var size := (collision.shape as RectangleShape2D).size
	var transform := _to_root(collision, root)
	var rect := Rect2(transform * (-size * 0.5), Vector2.ZERO)
	rect = rect.expand(transform * Vector2(size.x * 0.5, -size.y * 0.5))
	rect = rect.expand(transform * (size * 0.5))
	return rect.expand(transform * Vector2(-size.x * 0.5, size.y * 0.5))


static func _hitbox_rects(hitbox: BlockHitbox, root: Node) -> Array[Rect2]:
	var result: Array[Rect2] = []
	for child in hitbox.get_children():
		var collision := child as CollisionShape2D
		if collision != null and collision.shape is RectangleShape2D:
			result.append(_shape_rect(collision, root))
	return result


## Path2D of the projectile template, as a 1-cell-thick lane rect in root space.
static func _path_rect(projectile: Node2D, root: Node) -> Rect2:
	for child in projectile.get_children():
		var path := child as Path2D
		if path == null or path.curve == null or path.curve.point_count < 2:
			continue
		var transform := _to_root(path, root)
		var start := transform * path.curve.get_point_position(0)
		var finish := transform * path.curve.get_point_position(path.curve.point_count - 1)
		var rect := Rect2(start, Vector2.ZERO).expand(finish)
		for index in range(1, path.curve.point_count - 1):
			rect = rect.expand(transform * path.curve.get_point_position(index))
		var thickness := BlockData.AUTHOR_CELL_WU
		# A path longer than the stage is clamped to the stage size, keeping its start: a Cannon
		# drawn "to the far side" still shoots across the whole stage (2026-10-16).
		var stage := Vector2(StageMap.ARENA_SIZE) * BlockData.AUTHOR_CELL_WU
		if rect.size.y < rect.size.x:
			var length := minf(rect.size.x, stage.x)
			var left := start.x if finish.x >= start.x else start.x - length
			return Rect2(left, rect.get_center().y - thickness * 0.5, length, thickness)
		var height := minf(rect.size.y, stage.y)
		var top := start.y if finish.y >= start.y else start.y - height
		return Rect2(rect.get_center().x - thickness * 0.5, top, thickness, height)
	return Rect2()


## Root-space rect -> cells relative to the placement box's top-left (rounded to 1/64 cell).
static func _cells(rect: Rect2, half: Vector2, cell: float) -> Rect2:
	var local := Rect2(rect.position + half, rect.size)
	var snap := 1.0 / cell
	return Rect2(
		snappedf(local.position.x / cell, snap),
		snappedf(local.position.y / cell, snap),
		snappedf(local.size.x / cell, snap),
		snappedf(local.size.y / cell, snap)
	)


static func _build_families(entries: Array[Dictionary], errors: PackedStringArray) -> Dictionary:
	var by_family := {}
	var order := {}
	var scenes := {}
	for entry in entries:
		var family_id := str(entry.family_id)
		if not by_family.has(family_id):
			by_family[family_id] = entry.family
			order[family_id] = int(entry.order)
		else:
			order[family_id] = mini(int(order[family_id]), int(entry.order))
		var family := by_family[family_id] as ItemFamilyDefinition
		var variant := entry.variant as ItemVariantDefinition
		if family.find_variant(variant.variant_id) != null:
			errors.append(
				"%s: duplicate variant %s.%s" % [entry.path, family_id, variant.variant_id]
			)
			continue
		family.variants.append(variant)
		scenes["%s.%s" % [family_id, variant.variant_id]] = str(entry.path)
	var ids: Array = by_family.keys()
	ids.sort_custom(
		func(left: String, right: String) -> bool:
			if int(order[left]) != int(order[right]):
				return int(order[left]) < int(order[right])
			return left < right
	)
	var families: Array[ItemFamilyDefinition] = []
	for family_id in ids:
		var family := by_family[family_id] as ItemFamilyDefinition
		family.variants.sort_custom(
			func(a: ItemVariantDefinition, b: ItemVariantDefinition) -> bool:
				return a.variant_id < b.variant_id
		)
		families.append(family)
	return {
		"families": families, "scenes": scenes, "errors": errors, "skipped": PackedStringArray()
	}


## One broken block scene must not take every block (and the match) down with it: it is left
## out of the catalog and reported. Runs after the scan is cached, because GameplayTuning's
## defaults read the catalog.
static func _drop_invalid(result: Dictionary) -> void:
	var check_tuning := GameplayTuning.new()
	var kept: Array[ItemFamilyDefinition] = []
	for family in result.families:
		var problems := ItemDefinitionValidator.validate_family(family, check_tuning)
		if problems.is_empty():
			kept.append(family)
			continue
		var message := "%s left out: %s" % [family.family_id, "; ".join(problems)]
		result.skipped.append(message)
		push_warning("BlockCatalog: " + message)
	result.families = kept

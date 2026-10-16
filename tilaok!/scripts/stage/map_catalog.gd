class_name MapCatalog
extends RefCounted

## Folder-scanned map list (user request, 2026-10-16). Every .tscn under MAPS_DIR
## (recursively) whose root is a StageMap with `in_selection` on and no validation errors becomes
## a Lobby map choice; the map id is the scene's file name. The built-in default stage is always
## the first choice. Broken maps are left out and reported by errors().

const MAPS_DIR := "res://scenes/maps"
const DEFAULT_ID := ArenaDefinition.DEFAULT_LAYOUT_ID

static var _cache: Dictionary = {}


static func reload() -> void:
	_cache.clear()


## [{map_id, name, path, order, description}] with the built-in default first, then maps by
## map_order and name.
static func entries(directory: String = MAPS_DIR) -> Array[Dictionary]:
	var result: Array[Dictionary] = [
		{
			"map_id": DEFAULT_ID,
			"name": "Default stage",
			"path": "",
			"order": -1,
			"description": "The built-in base stage."
		}
	]
	result.append_array(_scan(directory).entries)
	return result


static func errors(directory: String = MAPS_DIR) -> PackedStringArray:
	return _scan(directory).errors


static func ids(directory: String = MAPS_DIR) -> PackedStringArray:
	var result := PackedStringArray()
	for entry in entries(directory):
		result.append(str(entry.map_id))
	return result


static func entry_for(map_id: String, directory: String = MAPS_DIR) -> Dictionary:
	for entry in entries(directory):
		if str(entry.map_id) == map_id:
			return entry
	return {}


## The ArenaLayout for a map, or null for the built-in default (and for an unknown id).
static func layout_for(map_id: String, directory: String = MAPS_DIR) -> ArenaLayout:
	var entry := entry_for(map_id, directory)
	if entry.is_empty() or str(entry.path).is_empty():
		return null
	var packed := load(str(entry.path)) as PackedScene
	var map := packed.instantiate() as StageMap if packed != null else null
	if map == null:
		return null
	var layout := map.to_layout(map_id)
	layout.map_scene = packed
	map.free()
	return layout


## The id `steps` places after `map_id` in the selection, wrapping around.
static func cycle(map_id: String, steps: int, directory: String = MAPS_DIR) -> String:
	var all := ids(directory)
	var index := maxi(0, all.find(map_id))
	return all[posmod(index + steps, all.size())]


static func _scan(directory: String) -> Dictionary:
	if _cache.has(directory):
		return _cache[directory]
	var found: Array[Dictionary] = []
	var problems := PackedStringArray()
	for path in _scene_paths(directory):
		var packed := load(path) as PackedScene
		if packed == null:
			problems.append("%s: could not load" % path)
			continue
		var root := packed.instantiate()
		var map := root as StageMap
		if map == null:
			root.free()
			continue
		var map_errors := map.validate()
		if not map_errors.is_empty():
			problems.append("%s: %s" % [path, "; ".join(map_errors)])
		elif map.in_selection:
			(
				found
				. append(
					{
						"map_id": path.get_file().get_basename(),
						"name": map.map_name,
						"path": path,
						"order": map.map_order,
						"description": map.description,
					}
				)
			)
		map.free()
	found.sort_custom(
		func(left: Dictionary, right: Dictionary) -> bool:
			if int(left.order) != int(right.order):
				return int(left.order) < int(right.order)
			return str(left.name) < str(right.name)
	)
	for problem in problems:
		push_warning("MapCatalog: " + problem)
	var result := {"entries": found, "errors": problems}
	_cache[directory] = result
	return result


static func _scene_paths(directory: String) -> PackedStringArray:
	var result := PackedStringArray()
	if not DirAccess.dir_exists_absolute(directory):
		return result
	for name in ResourceLoader.list_directory(directory):
		var child := directory.path_join(name)
		if name.ends_with("/"):
			result.append_array(_scene_paths(child.trim_suffix("/")))
		elif name.get_extension() == "tscn":
			result.append(child)
	result.sort()
	return result

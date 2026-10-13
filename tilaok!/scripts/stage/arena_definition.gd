class_name ArenaDefinition
extends RefCounted

const REGION_FOOTPRINT := "footprint"
const REGION_SWEEP := "sweep"
const REGION_EFFECT := "effect"

var tuning: GameplayTuning
var arena_bounds: Rect2
var build_region: Rect2
var protected_spawn: Rect2
var protected_goal: Rect2
var spawn_feet := Vector2.ZERO
var goal_trigger: Rect2
var surface_specs: Array[Dictionary] = []
var _immutable_ids: Dictionary = {}
var _construction_ids: Dictionary = {}


func _init(source_tuning: GameplayTuning = null) -> void:
	tuning = source_tuning if source_tuning != null else GameplayTuning.new()
	var cell := tuning.grid_cell_wu
	arena_bounds = Rect2(
		Vector2.ZERO, Vector2(tuning.arena_width_tiles, tuning.arena_height_tiles) * cell
	)
	build_region = tile_rect(5, 3, 28, 15)
	protected_spawn = tile_rect(0, 11, 5, 15)
	protected_goal = tile_rect(28, 9, 32, 15)
	spawn_feet = Vector2(3.0, 15.0) * cell
	goal_trigger = tile_rect(30, 10, 31, 12)
	_add_surface("arena.floor", tile_rect(0, 15, 32, 16), true)
	_add_surface("arena.base_a", tile_rect(6, 13, 10, 15), true)
	_add_surface("arena.base_b", tile_rect(12, 11, 16, 12), true)
	_add_surface("arena.base_c", tile_rect(18, 13, 22, 15), true)
	_add_surface("arena.base_d", tile_rect(24, 11, 28, 12), true)
	_add_surface("arena.goal", tile_rect(28, 12, 32, 15), true)
	_add_surface(
		"arena.left_wall", Rect2(Vector2(-cell, 0.0), Vector2(cell, arena_bounds.size.y)), true
	)
	_add_surface(
		"arena.right_wall",
		Rect2(Vector2(arena_bounds.end.x, 0.0), Vector2(cell, arena_bounds.size.y)),
		true
	)
	_add_surface(
		"arena.ceiling", Rect2(Vector2(0.0, -cell), Vector2(arena_bounds.size.x, cell)), true
	)


func tile_rect(left: float, top: float, right: float, bottom: float) -> Rect2:
	var cell := tuning.grid_cell_wu
	return Rect2(Vector2(left, top) * cell, Vector2(right - left, bottom - top) * cell)


func controller_origin_from_feet(feet_position: Vector2) -> Vector2:
	return feet_position - Vector2(0.0, tuning.body_height_wu * 0.5)


func arena_geometry_signature() -> String:
	var rows := PackedStringArray()
	for spec in surface_specs:
		var rect: Rect2 = spec.rect
		rows.append(
			(
				"%s:%.3f,%.3f,%.3f,%.3f"
				% [spec.id, rect.position.x, rect.position.y, rect.size.x, rect.size.y]
			)
		)
	rows.sort()
	return "\n".join(rows)


func validate_region(
	region: Rect2, region_kind: String, actor_rects: Array[Rect2] = []
) -> Dictionary:
	var reason := ""
	if region.size.x <= 0.0 or region.size.y <= 0.0:
		reason = "region must have positive dimensions"
	elif not arena_bounds.encloses(region):
		reason = "outside arena bounds"
	elif _overlaps(region, protected_spawn):
		reason = "protected spawn zone"
	elif _overlaps(region, protected_goal):
		reason = "protected goal zone"
	elif not build_region.encloses(region):
		reason = "outside build region"
	if reason.is_empty():
		for spec in surface_specs:
			if bool(spec.immutable) and _overlaps(region, spec.rect):
				reason = "immutable base geometry: %s" % spec.id
				break
	if reason.is_empty() and region_kind == REGION_FOOTPRINT:
		for actor_rect in actor_rects:
			if _overlaps(region, actor_rect.grow(4.0)):
				reason = "player clearance"
				break
	elif reason.is_empty() and region_kind not in [REGION_SWEEP, REGION_EFFECT]:
		reason = "unknown edit region kind"
	return (
		_reject(reason)
		if not reason.is_empty()
		else {"allowed": true, "reason": "valid build region"}
	)


func register_player_construction(construction_id: String) -> bool:
	if construction_id.is_empty() or _construction_ids.has(construction_id):
		return false
	_construction_ids[construction_id] = true
	return true


func can_remove_surface(surface_id: String) -> Dictionary:
	if _immutable_ids.has(surface_id):
		return _reject("immutable arena geometry")
	if not _construction_ids.has(surface_id):
		return _reject("unknown construction")
	return {"allowed": true, "reason": "player construction"}


func _add_surface(surface_id: String, rect: Rect2, immutable: bool) -> void:
	var metadata := SupportSurfaceMetadata.new()
	metadata.surface_id = surface_id
	metadata.construction_id = surface_id if not immutable else ""
	metadata.player_built = not immutable
	metadata.wave_support_eligibility = SupportSurfaceMetadata.Eligibility.INELIGIBLE
	surface_specs.append(
		{"id": surface_id, "rect": rect, "immutable": immutable, "metadata": metadata}
	)
	if immutable:
		_immutable_ids[surface_id] = true


func _overlaps(left: Rect2, right: Rect2) -> bool:
	return left.intersects(right, false)


func _reject(reason: String) -> Dictionary:
	return {"allowed": false, "reason": reason}

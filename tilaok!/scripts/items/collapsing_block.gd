class_name CollapsingBlock
extends StaticBody2D

## Collapsing block: 1x1 cell (64x64 wu). No gravity. A chicken standing on it or wall-sliding
## on it starts a block_collapse_delay_s (2 s) shake; it then loses collision and fades, and
## returns after block_collapse_respawn_s (3 s) once no chicken overlaps it. Every Place/Play
## start restores it. Collision and the DEBUG placeholder visual are authored in
## scenes/blocks/collapsing_block.tscn.

signal collapse_started
signal collapsed
signal restored

enum State { SOLID, CRUMBLING, GONE }

const SHAKE_WU := 3.0
const SHAKE_HZ := 18.0
const GONE_ALPHA := 0.25

var placed: PlacedItem
var metadata: SupportSurfaceMetadata
var state := State.SOLID
var active := false
var collapse_delay := 2.0
var respawn_delay := 3.0
var _timer := 0.0
var _shake_clock := 0.0
var _visual: Node2D


func configure(
	source: PlacedItem,
	_regions: Array[Dictionary],
	surface_metadata: SupportSurfaceMetadata,
	_wall_contact_declaration: String,
	tuning: GameplayTuning
) -> void:
	placed = source
	metadata = surface_metadata
	collision_mask = 1
	StageBlockSupport.configure_root(self, source, surface_metadata)
	collapse_delay = tuning.block_collapse_delay_s
	respawn_delay = tuning.block_collapse_respawn_s
	_visual = get_node_or_null(StageBlockSupport.VISUAL_NODE) as Node2D


func _physics_process(delta: float) -> void:
	if not active or get_tree().paused:
		return
	match state:
		State.CRUMBLING:
			_timer -= delta
			_shake_clock += delta
			if _visual != null:
				_visual.position.x = sin(_shake_clock * TAU * SHAKE_HZ) * SHAKE_WU
			if _timer <= 0.0:
				_collapse()
		State.GONE:
			_timer -= delta
			if _timer <= 0.0 and not _chicken_overlapping():
				_restore()


## Called by ChickenController for floor contact and wall-slide contact.
func notify_chicken_contact(_chicken: Node) -> void:
	if not active or state != State.SOLID:
		return
	state = State.CRUMBLING
	_timer = collapse_delay
	_shake_clock = 0.0
	collapse_started.emit()


## ItemManager: true during Play, false during Place.
func set_block_active(enabled: bool) -> void:
	active = enabled


func reset_to_start() -> void:
	_restore()


func is_solid() -> bool:
	return state != State.GONE


func footprint_world_rect() -> Rect2:
	return placed.footprint_rect if placed != null else Rect2()


func occlusion_rects() -> Array[Rect2]:
	var result: Array[Rect2] = []
	if is_solid():
		result.append(footprint_world_rect())
	return result


func strip_world_rects() -> Array[Rect2]:
	return []


func strip_normals() -> Array[Vector2]:
	return []


func _collapse() -> void:
	state = State.GONE
	_timer = respawn_delay
	_set_collision_enabled(false)
	if _visual != null:
		_visual.position = Vector2.ZERO
		_visual.modulate.a = GONE_ALPHA
	collapsed.emit()


func _restore() -> void:
	var was_gone := state == State.GONE
	state = State.SOLID
	_timer = 0.0
	_shake_clock = 0.0
	_set_collision_enabled(true)
	if _visual != null:
		_visual.position = Vector2.ZERO
		_visual.modulate.a = 1.0
	if was_gone:
		restored.emit()


func _set_collision_enabled(enabled: bool) -> void:
	var collision := StageBlockSupport.shape_of(self)
	if collision != null:
		collision.disabled = not enabled


## Respawning inside a chicken would trap it; wait until the footprint is clear.
func _chicken_overlapping() -> bool:
	var collision := StageBlockSupport.shape_of(self)
	if collision == null or not is_inside_tree():
		return false
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = collision.shape
	query.transform = collision.global_transform
	query.collision_mask = 2
	query.collide_with_bodies = true
	query.collide_with_areas = false
	return not get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()

class_name WoodBox
extends CharacterBody2D

## Wood box: 2x2 cells (128x128 wu). Falls under gravity and slides when a grounded chicken
## walks into its side. It rests on the stage, other blocks and chickens' heads (mask 1 | 2),
## and returns to its placed spot at every Place/Play start. Inert outside Play.
## Collision and the DEBUG placeholder visual are authored in scenes/blocks/wood_box.tscn.

## A push lasts this many physics steps after the last chicken contact.
const PUSH_HOLD_STEPS := 2

var placed: PlacedItem
var metadata: SupportSurfaceMetadata
var active := false
var push_speed := 160.0
var friction := 2400.0
var gravity := 2531.25
var fall_cap := 900.0
var _start_position := Vector2.ZERO
var _push_dir := 0
var _push_steps := 0
var _size := Vector2.ZERO


func configure(
	source: PlacedItem,
	_regions: Array[Dictionary],
	surface_metadata: SupportSurfaceMetadata,
	_wall_contact_declaration: String,
	tuning: GameplayTuning
) -> void:
	placed = source
	metadata = surface_metadata
	StageBlockSupport.configure_root(self, source, surface_metadata)
	collision_mask = 1 | 2
	motion_mode = CharacterBody2D.MOTION_MODE_GROUNDED
	floor_snap_length = 4.0
	add_to_group("pushable_blocks")
	_size = StageBlockSupport.unrotated_size(source)
	_start_position = position
	push_speed = tuning.block_box_push_speed_wu_s
	friction = tuning.block_box_friction_wu_s2
	fall_cap = tuning.fall_speed_cap_wu_s
	# Same falling gravity as a chicken so drops read consistently.
	if tuning.jump_apex_seconds > 0.0:
		gravity = (
			2.0
			* tuning.jump_height_wu
			/ pow(tuning.jump_apex_seconds, 2.0)
			* tuning.fall_gravity_multiplier
		)


func _physics_process(delta: float) -> void:
	if not active or get_tree().paused:
		return
	velocity.y = minf(velocity.y + gravity * delta, fall_cap)
	if _push_steps > 0 and is_on_floor():
		velocity.x = float(_push_dir) * push_speed
		_push_steps -= 1
	else:
		_push_steps = 0
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
	move_and_slide()


## Called by ChickenController when a grounded chicken walks into a side of the box.
func push_from_chicken(_chicken: Node, direction: int) -> void:
	if not active or direction == 0:
		return
	_push_dir = direction
	_push_steps = PUSH_HOLD_STEPS


## ItemManager: true during Play, false during Place (the box then sits at its placed spot).
func set_block_active(enabled: bool) -> void:
	active = enabled


func reset_to_start() -> void:
	position = _start_position
	velocity = Vector2.ZERO
	_push_dir = 0
	_push_steps = 0


func footprint_world_rect() -> Rect2:
	return Rect2(position - _size * 0.5, _size)


func occlusion_rects() -> Array[Rect2]:
	var result: Array[Rect2] = [footprint_world_rect()]
	return result


func strip_world_rects() -> Array[Rect2]:
	return []


func strip_normals() -> Array[Vector2]:
	return []

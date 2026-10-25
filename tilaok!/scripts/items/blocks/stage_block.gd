class_name StageBlock
extends HazardPiece

## Root script of every scene-authored block (scenes/blocks/*.tscn). The scene's CollisionShape2D
## and BlockHitbox nodes are authoring data: BlockCatalog turns them into regions, and at placement
## this piece rebuilds its collision from those regions exactly like Kaing/Tulay (so rotation,
## occlusion, support and wall metadata follow the proven construction path). The scene's Visual
## node is what players see; it is centred on the placement box and turned with the block.
##
## Anchor: ANCHORED never moves; HEAVY falls; LIGHT falls and is pushed by a grounded chicken.
## Specials run through the deterministic ItemHazardDirector behaviors (see BlockData).

signal collapse_started
signal collapsed
signal restored

enum CollapseState { SOLID, CRUMBLING, GONE }

const VISUAL_NODE := "Visual"
const CONNECTED_PAINTER_FAMILIES := [
	"hazard.rail_trumpo", "hazard.parol_pulse", "hazard.slipper_launcher"
]
## Animations an authored AnimatedSprite2D under VISUAL_NODE may carry: the firing wind-up and the
## pose between shots. A block whose sprite lacks either simply keeps playing its own autoplay.
const VISUAL_FIRE_ANIMATION := &"shoot"
const VISUAL_REST_ANIMATION := &"reloading"
## A push lasts this many physics steps after the last chicken contact.
const PUSH_HOLD_STEPS := 2
const SHAKE_WU := 3.0
const SHAKE_HZ := 18.0
const GONE_ALPHA := 0.25

var data: BlockData
var active := false
var velocity := Vector2.ZERO
var collapse_state := CollapseState.SOLID
var gravity := 2531.25
var fall_cap := 1800.0
var push_speed := 160.0
var friction := 2400.0
var collapse_delay := 2.0
var respawn_delay := 3.0
var _turns := 0
var _start_position := Vector2.ZERO
var _push_dir := 0
var _push_steps := 0
var _collapse_timer := 0.0
var _shake_clock := 0.0
var _visual: Node2D
## Optional AnimatedSprite2D under VISUAL_NODE, and whether its fire animation is already running.
var _visual_sprite: AnimatedSprite2D
var _visual_winding := false
var _projectile_template: Node2D
var _projectile_visuals: Array[Node2D] = []


func configure(
	source: PlacedItem,
	regions: Array[Dictionary],
	surface_metadata: SupportSurfaceMetadata,
	wall_contact_declaration: String,
	tuning: GameplayTuning
) -> void:
	for child in get_children():
		if child is BlockData:
			data = child
	# Authoring shapes and hitboxes are replaced by the region-built collision below.
	for child in get_children():
		if child is CollisionShape2D or child is BlockHitbox:
			remove_child(child)
			child.free()
	super.configure(source, regions, surface_metadata, wall_contact_declaration, tuning)
	_turns = ItemGeometry.normalized_turns(source.quarter_turns)
	_start_position = position
	_visual = get_node_or_null(VISUAL_NODE) as Node2D
	if _visual != null:
		_visual.position = footprint_size * 0.5
		_visual.rotation = float(_turns) * PI * 0.5
		# These families use their replaceable ItemVisualSet art for fixed and moving parts.
		# Keep authored lighting and occluders, but hide the older placeholder sprites.
		if data != null and data.family_id in CONNECTED_PAINTER_FAMILIES:
			for child in _visual.get_children():
				if child is Sprite2D or child is AnimatedSprite2D:
					(child as CanvasItem).visible = false
			painter_static_parts = true
		else:
			# Authored Visual art replaces the painter's fixed parts; the painter keeps what moves.
			painter_static_parts = _visual.get_child_count() == 0
		_visual_sprite = _authored_visual_sprite()
	if _visual_sprite != null:
		if not _visual_sprite.animation_finished.is_connected(_on_visual_animation_finished):
			_visual_sprite.animation_finished.connect(_on_visual_animation_finished)
		_visual_winding = false
	if data != null and not data.projectile_node.is_empty():
		_projectile_template = get_node_or_null(data.projectile_node) as Node2D
		if _projectile_template != null:
			_projectile_template.visible = false
			_projectile_template.process_mode = Node.PROCESS_MODE_DISABLED
	_read_tuning(tuning)
	if is_dynamic() or is_pushable():
		collision_mask = 1 | 2
	queue_redraw()


func _read_tuning(tuning: GameplayTuning) -> void:
	fall_cap = tuning.fall_speed_cap_wu_s
	push_speed = tuning.block_box_push_speed_wu_s
	friction = tuning.block_box_friction_wu_s2
	collapse_delay = tuning.block_collapse_delay_s
	respawn_delay = tuning.block_collapse_respawn_s
	if tuning.jump_apex_seconds > 0.0:
		gravity = (
			2.0
			* tuning.jump_height_wu
			/ pow(tuning.jump_apex_seconds, 2.0)
			* tuning.fall_gravity_multiplier
		)
	if data != null:
		if data.push_speed_wu_s >= 0.0:
			push_speed = data.push_speed_wu_s
		if data.collapse_delay_s >= 0.0:
			collapse_delay = data.collapse_delay_s
		if data.collapse_respawn_s >= 0.0:
			respawn_delay = data.collapse_respawn_s


func is_dynamic() -> bool:
	return data != null and data.anchor != BlockData.Anchor.ANCHORED


func is_pushable() -> bool:
	return data != null and data.anchor == BlockData.Anchor.LIGHT


func collapses() -> bool:
	return data != null and data.special == BlockData.Special.COLLAPSE


## ItemManager: true during Play, false during Place (the block then rests at its placed spot).
func set_block_active(enabled: bool) -> void:
	if simulation_authority == null or not simulation_authority.can_commit():
		return
	active = enabled


func reset_to_start() -> void:
	if simulation_authority == null or not simulation_authority.can_commit():
		return
	super.reset_to_start()
	position = _start_position
	velocity = Vector2.ZERO
	_push_dir = 0
	_push_steps = 0
	# A reset mid-shot leaves the barrel mid-recoil otherwise.
	_visual_winding = false
	if _visual_sprite != null and _visual_sprite.sprite_frames != null:
		if _visual_sprite.sprite_frames.has_animation(VISUAL_REST_ANIMATION):
			_visual_sprite.play(VISUAL_REST_ANIMATION)
	_restore_collapse()
	_sync_behavior_origin()


## Footprint follows the block when gravity or pushing moves it.
func footprint_world_rect() -> Rect2:
	return Rect2(position, footprint_size)


func occlusion_rects() -> Array[Rect2]:
	if collapse_state == CollapseState.GONE:
		var none: Array[Rect2] = []
		return none
	return super.occlusion_rects()


## Called by ChickenController when a grounded chicken walks into a side of the block.
func push_from_chicken(_chicken: Node, direction: int) -> void:
	if simulation_authority == null or not simulation_authority.can_commit():
		return
	if not active or direction == 0 or not is_pushable():
		return
	_push_dir = direction
	_push_steps = PUSH_HOLD_STEPS


## Called by ChickenController for floor contact and wall-slide contact.
func notify_chicken_contact(_chicken: Node) -> void:
	if simulation_authority == null or not simulation_authority.can_commit():
		return
	if not active or not collapses() or collapse_state != CollapseState.SOLID:
		return
	collapse_state = CollapseState.CRUMBLING
	_collapse_timer = collapse_delay
	_shake_clock = 0.0
	collapse_started.emit()


func is_solid() -> bool:
	return collapse_state != CollapseState.GONE


## Read by ChickenController for the floor it stands on (Yelo ice).
func is_slippery() -> bool:
	return data != null and data.slippery and is_solid()


func is_on_ground() -> bool:
	return test_move(global_transform, Vector2(0.0, 1.0))


func _physics_process(delta: float) -> void:
	if not active or get_tree().paused or not simulation_authority.can_commit():
		return
	if is_dynamic():
		_step_gravity(delta)
	if collapses():
		_step_collapse(delta)
	_sync_behavior_origin()


func _step_gravity(delta: float) -> void:
	var grounded := is_on_ground()
	if grounded and velocity.y > 0.0:
		velocity.y = 0.0
	elif not grounded:
		velocity.y = minf(velocity.y + gravity * delta, fall_cap)
	if _push_steps > 0 and grounded:
		velocity.x = float(_push_dir) * push_speed
		_push_steps -= 1
	else:
		_push_steps = 0
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
	if velocity.y != 0.0 and move_and_collide(Vector2(0.0, velocity.y * delta)) != null:
		velocity.y = 0.0
	if velocity.x != 0.0 and move_and_collide(Vector2(velocity.x * delta, 0.0)) != null:
		velocity.x = 0.0


func _step_collapse(delta: float) -> void:
	match collapse_state:
		CollapseState.CRUMBLING:
			_collapse_timer -= delta
			_shake_clock += delta
			if _visual != null:
				_visual.position = (
					footprint_size * 0.5
					+ Vector2(
						(
							sin(_shake_clock * TAU * SHAKE_HZ)
							* SHAKE_WU
							* PresentationApplier.shake_scale()
						),
						0.0
					)
				)
			if _collapse_timer <= 0.0:
				_collapse()
		CollapseState.GONE:
			_collapse_timer -= delta
			if _collapse_timer <= 0.0 and not _chicken_overlapping():
				_restore_collapse()


func _collapse() -> void:
	collapse_state = CollapseState.GONE
	_collapse_timer = respawn_delay
	_set_shapes_disabled(true)
	if _visual != null:
		_visual.position = footprint_size * 0.5
		_visual.modulate.a = GONE_ALPHA
	collapsed.emit()


func _restore_collapse() -> void:
	var was_gone := collapse_state == CollapseState.GONE
	collapse_state = CollapseState.SOLID
	_collapse_timer = 0.0
	_shake_clock = 0.0
	_set_shapes_disabled(false)
	if _visual != null:
		_visual.position = footprint_size * 0.5
		_visual.modulate.a = 1.0
	if was_gone:
		restored.emit()


func _set_shapes_disabled(disabled: bool) -> void:
	for child in get_children():
		if child is CollisionShape2D:
			(child as CollisionShape2D).disabled = disabled


## Respawning inside a chicken would trap it; wait until the footprint is clear.
func _chicken_overlapping() -> bool:
	if not is_inside_tree():
		return false
	var shape := RectangleShape2D.new()
	shape.size = footprint_size
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, global_position + footprint_size * 0.5)
	query.collision_mask = 2
	query.collide_with_bodies = true
	query.collide_with_areas = false
	return not get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()


func _sync_behavior_origin() -> void:
	if behavior != null and is_dynamic():
		behavior.origin = position


func _process(delta: float) -> void:
	super._process(delta)
	_sync_projectile_visuals()
	_sync_visual_animation()


## Drives an AnimatedSprite2D authored under the scene's Visual node, if the block has one. The
## Cannon's `shoot` runs its wind-up through the launcher telegraph so the blast frame lands on
## the shot itself, then hands back to `reloading`. Starting it is the only cue: once playing it
## is left alone, or firing would cut off its own muzzle flash and smoke.
func _sync_visual_animation() -> void:
	if _visual_sprite == null or _visual_sprite.sprite_frames == null:
		return
	var launcher := behavior as LauncherBehavior
	var winding := (
		active and launcher != null and launcher.state == LauncherBehavior.State.TELEGRAPH
	)
	if winding == _visual_winding:
		return
	_visual_winding = winding
	if winding and _visual_sprite.sprite_frames.has_animation(VISUAL_FIRE_ANIMATION):
		_visual_sprite.play(VISUAL_FIRE_ANIMATION)


## `shoot` is authored non-looping so it reaches this and returns the barrel to rest. A looping
## or missing rest pose is simply left alone rather than restarted every frame.
func _on_visual_animation_finished() -> void:
	if _visual_sprite == null or _visual_sprite.animation != VISUAL_FIRE_ANIMATION:
		return
	if _visual_sprite.sprite_frames.has_animation(VISUAL_REST_ANIMATION):
		_visual_sprite.play(VISUAL_REST_ANIMATION)


## The scene's own animated sprite, if it authored one. Projectile copies live under the
## projectile template, not Visual, so they are never picked up here.
func _authored_visual_sprite() -> AnimatedSprite2D:
	for child in _visual.get_children():
		if child is AnimatedSprite2D:
			return child as AnimatedSprite2D
	return null


## Shows one copy of the projectile template's Visual per live projectile (non-painter blocks).
func _sync_projectile_visuals() -> void:
	if _projectile_template == null or behavior == null or uses_painter():
		return
	var centers: Array = []
	if behavior is LauncherBehavior:
		for projectile in (behavior as LauncherBehavior).projectiles:
			centers.append(projectile.center)
	while _projectile_visuals.size() < centers.size():
		var copy := _projectile_copy()
		if copy == null:
			return
		add_child(copy)
		_projectile_visuals.append(copy)
	for index in range(_projectile_visuals.size()):
		var copy := _projectile_visuals[index]
		copy.visible = index < centers.size()
		if copy.visible:
			copy.position = (centers[index] as Vector2) - global_position
			copy.rotation = float(_turns) * PI * 0.5


func _projectile_copy() -> Node2D:
	var source := _projectile_template.get_node_or_null(VISUAL_NODE) as Node2D
	if source == null:
		return null
	var copy := source.duplicate() as Node2D
	copy.name = "ProjectileVisual%d" % _projectile_visuals.size()
	copy.visible = true
	return copy


## Legacy painter presentation (P10 families keep their swappable ItemVisualSet).
func uses_painter() -> bool:
	return (
		family != null
		and family.preview_silhouette != BlockCatalog.SCENE_PREVIEW
		and family.visual_set != null
	)


func _draw() -> void:
	if uses_painter():
		super._draw()

class_name P03StageRoom
extends Control

signal return_requested
signal actor_created(actor: ChickenController)

const BUILD_ID := "P03-graybox-dev"
## Top-left of the on-demand wall-movement debug fixtures (above the base route), authored on
## the historical 32 wu grid; multiply by world_scale (see wall_fixture_origin()).
const WALL_FIXTURE_ORIGIN := Vector2(352.0, 112.0)
const STAGE_TILES_SCENE := preload("res://scenes/stage/stage_tiles.tscn")
## Editable chicken scene: ChickenController + body shape + animated PLACEHOLDER sprite.
const CHICKEN_SCENE := preload("res://scenes/characters/chicken.tscn")
## Pure diagnostics (the support test line); the player flow hides this group.
const DEBUG_WORLD_GROUP := &"debug_world"
const PREVIEW_COLORS := [Color("#f5c95b"), Color("#74c8d6"), Color("#ef8b74"), Color("#a8d782")]

var tuning := GameplayTuning.new()
var snapshot: ConfigurationSnapshot
var arena: ArenaDefinition
## Optional stage layout, set before the room enters the tree. Null keeps the default stage; the
## tutorial match sets it once, so every round and mode of that match shares one map.
var arena_layout: ArenaLayout
var support_tracker := SupportTracker.new()
var input_router: LocalInputRouter
var simulation_authority := SimulationAuthority.offline()
var pause_coordinator: PauseRecoveryCoordinator
var camera_rig: BoundedStageCamera
var world_layer: Node2D
## 64x64 visual tiles painted from ArenaDefinition; collision stays on per-surface bodies.
var stage_tiles: StageTileLayer
var actors: Dictionary = {}
var goal_area: Area2D
var wall_fixtures: Dictionary = {}
var pointers: Array[Dictionary] = []
var current_context := BoundedStageCamera.Context.PLAY
var profile_id := "movement_room"
var support_line_y := 384.0
## grid_cell_wu / 32: scales this room's debug literals authored on the historical 32 wu grid.
var world_scale := 1.0
var _camera_targets: Array[StageCameraTarget] = []
var _camera_target_cache: Dictionary = {}
var _seed := 12345
var _run_id := 1
var _phase_before_pause := LocalInputRouter.Phase.PLAY
var _use_camera_fixture_targets := false
var _hud: Control
var _status_label: Label
var _support_label: Label
var _pause_button: Button
var _pointer_counter := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	process_physics_priority = 100
	var errors := tuning.validate()
	if not errors.is_empty():
		push_error("P03 tuning rejected: " + "; ".join(errors))
		return
	# GameFlow injects one shared router so seats and held-press state survive Title <-> match.
	if input_router == null:
		input_router = LocalInputRouter.new()
	if simulation_authority == null or not simulation_authority.configured:
		return
	input_router.set_authority(simulation_authority)
	pause_coordinator = PauseRecoveryCoordinator.new()
	snapshot = ConfigurationSnapshot.create(
		tuning, PresentationSettings.new(), profile_id, _seed, _run_id
	)
	tuning = snapshot.gameplay
	world_scale = tuning.grid_cell_wu / 32.0
	support_line_y = 384.0 * world_scale
	arena = ArenaDefinition.new(tuning, arena_layout)
	arena.authority = simulation_authority
	support_tracker.configure(tuning)
	support_tracker.playable_bounds = arena.arena_bounds
	support_tracker.authority = simulation_authority
	input_router.tuning = tuning
	input_router.set_shared_keyboard_enabled(true)
	input_router.set_phase(LocalInputRouter.Phase.LOBBY)
	if input_router.get_parent() == null:
		add_child(input_router)
	pause_coordinator.input_router = input_router
	pause_coordinator.authority = simulation_authority
	add_child(pause_coordinator)
	input_router.seat_joined.connect(_on_seat_joined)
	input_router.pause_requested.connect(_on_pause_requested)
	_build_world()
	_build_hud()
	_update_camera_targets()
	_update_diagnostics()


func _exit_tree() -> void:
	input_router.clear_input_state()
	support_tracker.clear()
	actors.clear()
	pointers.clear()
	_camera_targets.clear()
	_camera_target_cache.clear()


func _process(_delta: float) -> void:
	if get_tree().paused:
		return
	_update_identity_badges()
	_update_camera_targets()
	_update_diagnostics()


func _physics_process(_delta: float) -> void:
	if simulation_authority == null or not simulation_authority.can_commit():
		return
	support_tracker.finalize_physics_step(Engine.get_physics_frames())


func join_keyboard(layout: String) -> int:
	if layout not in PlayerSeatRegistry.KEYBOARD_LAYOUTS:
		return -1
	var seat_index := input_router.registry.join_keyboard(layout)
	if seat_index >= 0:
		input_router.seat_joined.emit(seat_index)
	return seat_index


func start_play() -> void:
	current_context = BoundedStageCamera.Context.PLAY
	input_router.set_phase(LocalInputRouter.Phase.PLAY)
	camera_rig.set_context(current_context)
	_update_camera_targets()


func enter_place_fixture() -> void:
	current_context = BoundedStageCamera.Context.PLACE
	input_router.set_phase(LocalInputRouter.Phase.PLACE)
	camera_rig.set_context(current_context)
	if pointers.is_empty():
		_add_pointer(_scaled_rect(Rect2(Vector2(176.0, 112.0), Vector2(128.0, 64.0))), false)
		_add_pointer(_scaled_rect(Rect2(Vector2(720.0, 360.0), Vector2(192.0, 96.0))), false)
	_update_camera_targets()


func confirm_next_pointer() -> bool:
	for pointer in pointers:
		if not bool(pointer.confirmed):
			pointer.confirmed = true
			(pointer.node as Polygon2D).color = Color("#65727a")
			(pointer.label as Label).text = "CONFIRMED PREVIEW"
			_update_camera_targets()
			return true
	return false


func rotate_next_pointer() -> bool:
	for pointer in pointers:
		if not bool(pointer.confirmed):
			var old_rect: Rect2 = pointer.rect
			var next_rect := Rect2(old_rect.position, Vector2(old_rect.size.y, old_rect.size.x))
			pointer.rect = next_rect
			(pointer.node as Polygon2D).position = next_rect.get_center()
			(pointer.node as Polygon2D).polygon = _rect_polygon_centered(next_rect.size)
			(pointer.label as Label).position = next_rect.position + Vector2(4.0, 4.0) * world_scale
			(pointer.label as Label).text = "UNCONFIRMED • ROTATED"
			_update_camera_targets()
			return true
	return false


func set_camera_fixture_targets(rects: Array[Rect2], context: BoundedStageCamera.Context) -> void:
	current_context = context
	_use_camera_fixture_targets = true
	camera_rig.set_context(context)
	var fixture_targets: Array[StageCameraTarget] = []
	for index in range(rects.size()):
		fixture_targets.append(StageCameraTarget.new("fixture_%d" % index, rects[index]))
	camera_rig.set_targets(fixture_targets)


func clear_camera_fixture_targets() -> void:
	_use_camera_fixture_targets = false
	_update_camera_targets()


func reset_room() -> void:
	get_tree().paused = false
	pause_coordinator.state = PauseRecoveryCoordinator.State.RUNNING
	pause_coordinator.pause_reason = ""
	input_router.resume_system()
	for actor_variant in actors.values():
		var actor := actor_variant as ChickenController
		actor.support_tracker.invalidate_actor(actor.support_actor_id)
		actor.reset_for_round(arena.controller_origin_from_feet(arena.spawn_feet))
	clear_wall_fixtures()
	for pointer in pointers:
		(pointer.node as Polygon2D).queue_free()
		(pointer.label as Label).queue_free()
	pointers.clear()
	current_context = BoundedStageCamera.Context.PLAY
	_use_camera_fixture_targets = false
	input_router.set_phase(LocalInputRouter.Phase.PLAY)
	camera_rig.set_context(current_context)
	camera_rig._initialized = false
	camera_rig.position = _camera_home()
	camera_rig.zoom = Vector2.ONE * tuning.camera_zoom_min
	_update_camera_targets()
	_update_diagnostics()


## Builds labeled wall-movement debug fixtures above the route; never touches base geometry.
func build_wall_fixtures() -> void:
	clear_wall_fixtures()
	wall_fixtures = WallFixtureBuilder.build_set(world_layer, wall_fixture_origin(), world_scale)


func wall_fixture_origin() -> Vector2:
	return WALL_FIXTURE_ORIGIN * world_scale


func _camera_home() -> Vector2:
	return Vector2(512.0, 224.0) * world_scale


func _scaled_rect(rect: Rect2) -> Rect2:
	return Rect2(rect.position * world_scale, rect.size * world_scale)


func clear_wall_fixtures() -> void:
	for fixture in wall_fixtures.values():
		if is_instance_valid(fixture):
			(fixture as Node).queue_free()
	wall_fixtures.clear()


func set_wall_movement_enabled(enabled: bool) -> void:
	tuning.wall_movement_enabled = enabled
	set_wall_debug_visible(enabled)


## Debug overlay only; wall movement itself is core and stays on.
func set_wall_debug_visible(visible_overlay: bool) -> void:
	for actor_variant in actors.values():
		var actor := actor_variant as ChickenController
		actor.show_wall_debug = visible_overlay
		actor.reset_wall_state()
		actor.queue_redraw()


func _toggle_wall_fixtures() -> void:
	if wall_fixtures.is_empty():
		build_wall_fixtures()
		set_wall_debug_visible(true)
	else:
		clear_wall_fixtures()
		set_wall_debug_visible(false)


func request_return() -> void:
	input_router.clear_input_state()
	support_tracker.clear()
	return_requested.emit()


func remove_support_surface(surface_id: String, body: Node) -> void:
	# Invalidate before queue_free so this step cannot evaluate a stale contact.
	support_tracker.invalidate_surface(surface_id)
	if body != null and is_instance_valid(body):
		body.queue_free()


func current_support_result(actor_id: String, line_y: float = -1.0) -> Dictionary:
	var resolved_line := support_line_y if line_y < 0.0 else line_y
	return support_tracker.evaluate(actor_id, resolved_line, tuning.support_height_epsilon_wu)


func _build_world() -> void:
	world_layer = Node2D.new()
	world_layer.name = "P03World"
	add_child(world_layer)
	var backdrop := _add_polygon(
		world_layer, tuning.camera_view_bounds, Color("#263843"), "NeutralBackdrop"
	)
	backdrop.z_index = -20
	_add_region_overlay(arena.build_region, Color("#5ba989"), "BUILD REGION • DEBUG")
	_add_region_overlay(arena.protected_spawn, Color("#edc85c"), "SPAWN • PROTECTED")
	_add_region_overlay(arena.protected_goal, Color("#df8d72"), "GOAL • PROTECTED")
	stage_tiles = STAGE_TILES_SCENE.instantiate() as StageTileLayer
	world_layer.add_child(stage_tiles)
	stage_tiles.paint_arena(arena)
	_add_map_visual()
	for spec in arena.surface_specs:
		_add_static_surface(spec, bool(spec.get("custom_visual", false)))
	_add_flag_trigger()
	_add_support_line()
	camera_rig = BoundedStageCamera.new()
	camera_rig.name = "BoundedStageCamera"
	camera_rig.configure(tuning)
	# Follow this stage's camera border instead of the fixed tuning rect, which is sized for the
	# old 32x16 arena and pins the view to the top-left corner of any larger map.
	camera_rig.view_bounds = arena.camera_bounds
	camera_rig.position = _camera_home()
	world_layer.add_child(camera_rig)
	camera_rig.make_current()


## A map from scenes/maps/ draws its own Blocks layer instead of the debug stage tiles.
func _add_map_visual() -> void:
	if arena_layout == null or arena_layout.map_scene == null:
		return
	var map := arena_layout.map_scene.instantiate() as StageMap
	if map == null:
		return
	map.name = "StageMap"
	map.z_index = stage_tiles.z_index
	map.scale = Vector2.ONE * tuning.grid_cell_wu / 64.0
	world_layer.add_child(map)
	stage_tiles.clear()


func _build_hud() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "P03HudLayer"
	canvas.layer = 20
	add_child(canvas)
	_hud = PanelContainer.new()
	_hud.name = "P03Hud"
	_hud.process_mode = Node.PROCESS_MODE_ALWAYS
	_hud.position = Vector2.ZERO
	_hud.size = Vector2(tuning.camera_virtual_width_px, tuning.camera_hud_reservation_px)
	_hud.add_theme_stylebox_override("panel", _hud_style())
	canvas.add_child(_hud)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	_hud.add_child(row)
	var title := Label.new()
	title.text = "P03 GRAYBOX • DEVELOPMENT FIXTURE"
	title.add_theme_font_size_override("font_size", 13)
	row.add_child(title)
	_add_button(row, "Join K1", func() -> void: join_keyboard("K1"))
	_add_button(row, "Join K2", func() -> void: join_keyboard("K2"))
	_add_button(row, "Play", start_play)
	_add_button(row, "Place previews", enter_place_fixture)
	_add_button(row, "Confirm next", confirm_next_pointer)
	_add_button(row, "Rotate next", rotate_next_pointer)
	_add_button(row, "Reset", reset_room)
	_add_button(row, "Wall fixtures", _toggle_wall_fixtures)
	_pause_button = _add_button(row, "Pause", _toggle_pause)
	_add_button(row, "Return", request_return)
	var lower := VBoxContainer.new()
	lower.position = Vector2(8.0, tuning.camera_hud_reservation_px + 6.0)
	lower.add_theme_constant_override("separation", 2)
	canvas.add_child(lower)
	_status_label = Label.new()
	_status_label.add_theme_color_override("font_color", Color("#ffffff"))
	_status_label.add_theme_color_override("font_shadow_color", Color("#14232a"))
	_status_label.add_theme_constant_override("shadow_offset_x", 1)
	_status_label.add_theme_constant_override("shadow_offset_y", 1)
	lower.add_child(_status_label)
	_support_label = Label.new()
	_support_label.add_theme_color_override("font_color", Color("#ffffff"))
	lower.add_child(_support_label)
	var help := Label.new()
	help.text = (
		"K1 A/D move, W jump (hold to glide), S sneak • K2 arrows (Up jump/glide, Down sneak)"
		+ " • zones are labeled debug geometry"
	)
	help.add_theme_color_override("font_color", Color("#ffffff"))
	lower.add_child(help)


func _add_button(parent: Control, text_value: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(82.0, 36.0)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _build_actor(seat_index: int) -> ChickenController:
	var seat := input_router.registry.get_seat(seat_index)
	if seat.is_empty() or not bool(seat.joined):
		return null
	if actors.has(seat_index):
		return actors[seat_index] as ChickenController
	var actor := CHICKEN_SCENE.instantiate() as ChickenController
	actor.name = "ChickenSeat%d" % (seat_index + 1)
	actor.seat_index = seat_index
	actor.identity_number = int(seat.identity)
	actor.identity_shape = str(seat.shape)
	actor.marker_color = seat.color
	actor.tuning = tuning
	actor.input_router = input_router
	actor.simulation_authority = simulation_authority
	actor.support_tracker = support_tracker
	actor.support_actor_id = "seat_%d" % seat_index
	actor.water_regions = arena.water_regions
	actor.border_regions = arena.border_regions
	# Containment was removed on 2026-10-22, so `bounds` is no longer the stage edge: it is only the
	# far backstop that reports a chicken lost to the void. The kill line is the Border marker.
	actor.bounds = Rect2(-arena.arena_bounds.size, arena.arena_bounds.size * 3.0)
	actor.position = arena.controller_origin_from_feet(arena.spawn_feet)
	actor.collision_layer = 2
	actor.collision_mask = 1
	actor.set_meta("support_half_height", tuning.body_height_wu * 0.5)
	# `actor.tuning` is already set, so the controller resizes its own authored hitboxes to the
	# tuning body on _ready (ChickenController._apply_body_tuning).
	world_layer.add_child(actor)
	var badge := Label.new()
	badge.name = "IdentityBadge"
	badge.text = "%d • %s" % [seat.identity, seat.shape]
	badge.add_theme_font_size_override("font_size", roundi(12 * world_scale))
	badge.add_theme_color_override("font_color", Color.WHITE)
	badge.add_theme_color_override("font_outline_color", Color("#15242b"))
	badge.add_theme_constant_override("outline_size", roundi(3 * world_scale))
	badge.size = Vector2(104.0, 22.0) * world_scale
	world_layer.add_child(badge)
	var leader := Line2D.new()
	leader.name = "IdentityLeader"
	leader.width = 1.5 * world_scale
	leader.default_color = Color.WHITE
	world_layer.add_child(leader)
	actor.set_meta("identity_badge", badge)
	actor.set_meta("identity_leader", leader)
	actors[seat_index] = actor
	actor_created.emit(actor)
	_update_identity_badges()
	return actor


## `with_visual` false leaves the drawing to the stage TileMapLayer (collision only).
func _add_static_surface(spec: Dictionary, with_visual: bool = true) -> StaticBody2D:
	var metadata := spec.metadata as SupportSurfaceMetadata
	if not support_tracker.register_surface(metadata, spec.rect):
		push_error("Rejected arena support metadata for %s" % spec.id)
	var rect: Rect2 = spec.rect
	var body := StaticBody2D.new()
	body.name = str(spec.id)
	body.position = rect.get_center()
	body.collision_layer = 1
	body.collision_mask = 1
	body.add_to_group("support_surfaces")
	body.set_meta(SupportSurfaceMetadata.META_KEY, metadata)
	world_layer.add_child(body)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	body.add_child(collision)
	if not with_visual:
		return body
	var color := Color("#70583f") if bool(spec.immutable) else Color("#80a86c")
	var visual := Polygon2D.new()
	visual.polygon = _rect_polygon_centered(rect.size)
	visual.color = color
	body.add_child(visual)
	var edge := Line2D.new()
	edge.points = PackedVector2Array(
		[
			Vector2(-rect.size.x * 0.5, -rect.size.y * 0.5),
			Vector2(rect.size.x * 0.5, -rect.size.y * 0.5),
			Vector2(rect.size.x * 0.5, rect.size.y * 0.5),
			Vector2(-rect.size.x * 0.5, rect.size.y * 0.5),
			Vector2(-rect.size.x * 0.5, -rect.size.y * 0.5),
		]
	)
	edge.width = 2.0
	edge.default_color = Color("#f0ead8")
	body.add_child(edge)
	return body


func _add_flag_trigger() -> void:
	goal_area = Area2D.new()
	goal_area.name = "KareraGoalTrigger"
	goal_area.position = arena.goal_trigger.get_center()
	goal_area.collision_layer = 0
	goal_area.collision_mask = 2
	goal_area.monitoring = true
	goal_area.monitorable = false
	world_layer.add_child(goal_area)
	var goal_collision := CollisionShape2D.new()
	var goal_shape := RectangleShape2D.new()
	goal_shape.size = arena.goal_trigger.size
	goal_collision.shape = goal_shape
	goal_area.add_child(goal_collision)
	var outline := Line2D.new()
	outline.name = "FlagTriggerOutline"
	outline.points = PackedVector2Array(
		[
			arena.goal_trigger.position,
			Vector2(arena.goal_trigger.end.x, arena.goal_trigger.position.y),
			arena.goal_trigger.end,
			Vector2(arena.goal_trigger.position.x, arena.goal_trigger.end.y),
			arena.goal_trigger.position,
		]
	)
	outline.width = 2.0
	outline.default_color = Color("#f0d25d")
	world_layer.add_child(outline)
	_add_world_label(
		"KARERA GOAL", arena.goal_trigger.position + Vector2(-48.0, 16.0) * world_scale
	)


func _add_support_line() -> void:
	var line := Line2D.new()
	line.name = "SupportDiagnosticLine"
	line.points = PackedVector2Array(
		[Vector2(160.0 * world_scale, support_line_y), Vector2(896.0 * world_scale, support_line_y)]
	)
	line.width = 2.0
	line.default_color = Color("#66d5d0")
	line.add_to_group(DEBUG_WORLD_GROUP)
	world_layer.add_child(line)
	var label := _add_world_label(
		"SUPPORT TEST LINE • NOT AN EVENT",
		Vector2(164.0, support_line_y / world_scale - 14.0) * world_scale
	)
	label.add_to_group(DEBUG_WORLD_GROUP)


func _add_region_overlay(rect: Rect2, color: Color, label: String) -> void:
	var fill := _add_polygon(
		world_layer, rect, Color(color, 0.14), "%sFill" % label.replace(" ", "_")
	)
	fill.z_index = -2
	var outline := Line2D.new()
	outline.points = PackedVector2Array(
		[
			rect.position,
			Vector2(rect.end.x, rect.position.y),
			rect.end,
			Vector2(rect.position.x, rect.end.y),
			rect.position
		]
	)
	outline.width = 2.0
	outline.default_color = color
	world_layer.add_child(outline)
	var stripe_x := rect.position.x
	while stripe_x < rect.end.x:
		var stripe := Line2D.new()
		var start_y := rect.position.y
		var end_x := minf(stripe_x + 40.0 * world_scale, rect.end.x)
		stripe.points = PackedVector2Array(
			[
				Vector2(stripe_x, start_y),
				Vector2(end_x, minf(start_y + 40.0 * world_scale, rect.end.y))
			]
		)
		stripe.width = 1.0 * world_scale
		stripe.default_color = Color(color, 0.7)
		world_layer.add_child(stripe)
		stripe_x += 48.0 * world_scale
	_add_world_label(label, rect.position + Vector2(4.0, 4.0) * world_scale)


func _add_polygon(parent: Node2D, rect: Rect2, color: Color, node_name: String) -> Polygon2D:
	var polygon := Polygon2D.new()
	polygon.name = node_name
	polygon.position = rect.get_center()
	polygon.polygon = _rect_polygon_centered(rect.size)
	polygon.color = color
	parent.add_child(polygon)
	return polygon


func _rect_polygon_centered(size: Vector2) -> PackedVector2Array:
	return PackedVector2Array(
		[
			Vector2(-size.x * 0.5, -size.y * 0.5),
			Vector2(size.x * 0.5, -size.y * 0.5),
			Vector2(size.x * 0.5, size.y * 0.5),
			Vector2(-size.x * 0.5, size.y * 0.5),
		]
	)


func _add_world_label(text_value: String, world_position: Vector2) -> Label:
	var label := Label.new()
	label.text = text_value
	label.position = world_position
	label.add_theme_font_size_override("font_size", roundi(12 * world_scale))
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color("#14232a"))
	label.add_theme_constant_override("outline_size", roundi(3 * world_scale))
	world_layer.add_child(label)
	return label


func _add_pointer(rect: Rect2, confirmed: bool) -> void:
	_pointer_counter += 1
	var pointer := Polygon2D.new()
	pointer.name = "PreviewPointer%d" % _pointer_counter
	pointer.position = rect.get_center()
	pointer.polygon = _rect_polygon_centered(rect.size)
	pointer.color = Color("#f0d25d", 0.3) if not confirmed else Color("#65727a", 0.3)
	pointer.z_index = 8
	world_layer.add_child(pointer)
	var outline := Line2D.new()
	outline.points = PackedVector2Array(
		[
			Vector2(-rect.size.x * 0.5, -rect.size.y * 0.5),
			Vector2(rect.size.x * 0.5, -rect.size.y * 0.5),
			Vector2(rect.size.x * 0.5, rect.size.y * 0.5),
			Vector2(-rect.size.x * 0.5, rect.size.y * 0.5),
			Vector2(-rect.size.x * 0.5, -rect.size.y * 0.5),
		]
	)
	outline.width = 3.0
	outline.default_color = Color("#fff2b7")
	pointer.add_child(outline)
	var label := _add_world_label(
		"UNCONFIRMED PREVIEW", rect.position + Vector2(4.0, 4.0) * world_scale
	)
	pointers.append(
		{
			"id": "pointer_%d" % _pointer_counter,
			"rect": rect,
			"confirmed": confirmed,
			"node": pointer,
			"label": label
		}
	)


func _update_camera_targets() -> void:
	if camera_rig == null or _use_camera_fixture_targets:
		return
	_camera_targets.clear()
	if current_context == BoundedStageCamera.Context.PLAY:
		for seat_index in actors:
			var actor := actors[seat_index] as ChickenController
			if actor == null or not is_instance_valid(actor) or actor.lifecycle.is_terminal():
				continue
			var body_rect := Rect2(
				(
					actor.global_position
					- Vector2(tuning.body_width_wu * 0.5, tuning.body_height_wu * 0.5)
				),
				Vector2(tuning.body_width_wu, tuning.body_height_wu)
			)
			var badge := actor.get_meta("identity_badge") as Label
			var badge_rect := (
				Rect2(badge.global_position, badge.size) if badge != null else body_rect
			)
			var target_id := "seat_%d" % seat_index
			var target := _cached_camera_target(target_id)
			target.world_rect = body_rect.merge(badge_rect)
			_camera_targets.append(target)
	else:
		for pointer in pointers:
			if not bool(pointer.confirmed):
				var target_id := str(pointer.id)
				var target := _cached_camera_target(target_id)
				target.world_rect = pointer.rect
				_camera_targets.append(target)
	camera_rig.set_targets(_camera_targets)


func _cached_camera_target(target_id: String) -> StageCameraTarget:
	if not _camera_target_cache.has(target_id):
		_camera_target_cache[target_id] = StageCameraTarget.new(target_id)
	return _camera_target_cache[target_id] as StageCameraTarget


func _update_identity_badges() -> void:
	var joined_count := actors.size()
	for seat_index in actors:
		var actor := actors[seat_index] as ChickenController
		if actor == null or not is_instance_valid(actor):
			continue
		var badge := actor.get_meta("identity_badge") as Label
		var leader := actor.get_meta("identity_leader") as Line2D
		var seat_number: int = int(seat_index)
		var column: int = seat_number % 2
		var row: int = floori(float(seat_number) / 2.0)
		var badge_offset := Vector2(0.0, -42.0 - float(row) * 26.0) * world_scale
		badge_offset.y -= tuning.body_height_wu * 0.5 - 24.0 * world_scale
		if joined_count > 1:
			badge_offset.x = (-112.0 if column == 0 else 8.0) * world_scale
		var badge_position := actor.global_position + badge_offset
		badge.global_position = badge_position
		var leader_end := badge_position + Vector2(0.0, 18.0) * world_scale
		if badge_offset.x < 0.0:
			leader_end.x += badge.size.x
		leader.points = PackedVector2Array(
			[actor.global_position + Vector2(0.0, -tuning.body_height_wu * 0.4), leader_end]
		)


func _update_diagnostics() -> void:
	if _status_label == null:
		return
	var context_name := "PLAY" if current_context == BoundedStageCamera.Context.PLAY else "PLACE"
	var camera_note := " • CAMERA FIXTURE TARGETS" if _use_camera_fixture_targets else ""
	_status_label.text = (
		"%s • %s%s • movement_room • seed %d • actors %d • 60 Hz"
		% [BUILD_ID, context_name, camera_note, _seed, actors.size()]
	)
	var support_summary := "Support: no actor"
	if not actors.is_empty():
		for seat_index in actors:
			var actor := actors[seat_index] as ChickenController
			var result := current_support_result(actor.support_actor_id)
			var contact := result.contact as SupportContact
			support_summary = (
				"Support: %s%s"
				% [result.reason, " • " + contact.surface_id if contact != null else ""]
			)
			break
	_support_label.text = support_summary
	if _pause_button != null:
		_pause_button.text = "Resume" if get_tree().paused else "Pause"


func _on_seat_joined(seat_index: int) -> void:
	_build_actor(seat_index)
	_update_camera_targets()
	_update_diagnostics()


func _toggle_pause() -> void:
	if pause_coordinator.state == PauseRecoveryCoordinator.State.RUNNING:
		_phase_before_pause = input_router.phase
		pause_coordinator.set_paused("P03 diagnostic pause", -1)
	else:
		pause_coordinator.state = PauseRecoveryCoordinator.State.RUNNING
		pause_coordinator.pause_reason = ""
		get_tree().paused = false
		input_router.resume_system()
		input_router.set_phase(_phase_before_pause)
	_update_diagnostics()


func _on_pause_requested(_seat_index: int) -> void:
	if pause_coordinator.state == PauseRecoveryCoordinator.State.RUNNING:
		_phase_before_pause = input_router.phase
		pause_coordinator.set_paused("participant requested pause", -1)


func _hud_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#17262d")
	style.border_color = Color("#cfdbd7")
	style.border_width_bottom = 2
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	return style

class_name KangarooSlipperPresenter
extends Node2D

## Non-colliding Kangaroo presentation. The P11 lab can retain the original diagnostic drawings;
## the scheduled P23 route supplies the illustrated textures below.

const FREEZE_SLIPPER := preload("res://assets/events/kangaroo/kangaroo_slipper_freeze_top.png")
const RISING_SLIPPER := preload("res://assets/events/kangaroo/kangaroo_slipper_rising_outsole.png")
const HUG_SLIPPER := preload("res://assets/events/kangaroo/kangaroo_slipper_hug_side.png")
const RISING_SURFACE := preload("res://assets/events/kangaroo/kangaroo_rising_surface_blend.png")
const HUG_LINK := preload("res://assets/events/kangaroo/kangaroo_hug_link.png")
const WATER_BODY_SHADER := preload("res://assets/shaders/kangaroo_water_body.gdshader")

const RISING_SURFACE_ALPHA := 0.88
const RISING_SURFACE_HEIGHT := 48.0
const RISING_SURFACE_MEAN_OFFSET := 17.0

var shown_commands: Array[Dictionary] = []
var world_bounds := Rect2()
var floor_y := 0.0
var simulation_time := 0.0
var camera_position := Vector2.ZERO
var use_illustrated_art := false
var hug_links: Array[Dictionary] = []
var _water_fill: ColorRect
var _water_material: ShaderMaterial


func _ready() -> void:
	_water_fill = ColorRect.new()
	_water_fill.name = "RisingWaterBody"
	_water_fill.color = Color.WHITE
	_water_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_water_fill.z_as_relative = false
	_water_fill.z_index = -4
	_water_fill.visible = false
	_water_material = ShaderMaterial.new()
	_water_material.shader = WATER_BODY_SHADER
	_water_fill.material = _water_material
	add_child(_water_fill)
	_sync_water_fill()


func set_state(
	commands: Array[Dictionary],
	bounds: Rect2,
	floor_height: float,
	active_time: float,
	camera_position: Vector2,
	contact_links: Array[Dictionary] = []
) -> void:
	shown_commands = commands.duplicate(true)
	world_bounds = bounds
	floor_y = floor_height
	simulation_time = active_time
	self.camera_position = camera_position
	hug_links = contact_links.duplicate(true)
	position = camera_position
	visible = not shown_commands.is_empty()
	_sync_water_fill()
	queue_redraw()


func _draw() -> void:
	if shown_commands.is_empty():
		return
	_draw_wave_targets()
	_draw_hug_links()
	var count := shown_commands.size()
	for index in range(count):
		var command := shown_commands[index]
		var command_type := int(command.get("command", -1))
		var center := Vector2((float(index) - float(count - 1) * 0.5) * 150.0, 0.0)
		var start := float(command.get("telegraph_start_at", simulation_time))
		var response_start := float(command.get("response_start_at", start))
		var landing_progress := clampf(
			(simulation_time - start) / maxf(response_start - start, 0.001), 0.0, 1.0
		)
		var strike_elapsed := simulation_time - response_start
		var recovering := maxf(0.0, strike_elapsed)
		center.y = lerpf(-154.0, -8.0, _ease_out(landing_progress))
		var alpha := 1.0
		if strike_elapsed >= 0.0:
			var strike_progress := clampf(strike_elapsed / 0.16, 0.0, 1.0)
			center.y = lerpf(-8.0, 8.0, _ease_out(strike_progress))
			var recovery_progress := clampf((recovering - 0.16) / 0.42, 0.0, 1.0)
			center.y = lerpf(center.y, -126.0, _ease_out(recovery_progress))
			alpha = 1.0 - recovery_progress
		if use_illustrated_art:
			_draw_illustrated_slipper(center, command_type, alpha)
		else:
			var angle := 0.0
			if command_type == KangarooRoundController.Command.RISING:
				angle = PI
			elif command_type == KangarooRoundController.Command.HUG:
				angle = PI * 0.5
			_draw_slipper(center, angle, _pose_color(command_type), command_type)
	if count > 0 and not use_illustrated_art:
		var font := ThemeDB.fallback_font
		if font != null:
			draw_string(
				font,
				Vector2(-88.0, -172.0),
				"KANGAROO COMMAND",
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				14,
				Color.WHITE
			)


func _draw_wave_targets() -> void:
	for command in shown_commands:
		if int(command.get("command", -1)) != KangarooRoundController.Command.RISING:
			continue
		var target_y := float(command.get("wave_y", -1.0))
		var start := float(command.get("response_start_at", simulation_time))
		var end := float(command.get("response_end_at", start + 1.0))
		var progress := clampf((simulation_time - start) / maxf(end - start, 0.001), 0.0, 1.0)
		if str(command.get("status", "")) == "DRAIN":
			var reset_end := (
				float(command.get("evaluated_at", simulation_time))
				+ float(command.get("reset_seconds", 0.0))
			)
			progress = (
				1.0
				- clampf(
					(
						(simulation_time - float(command.get("evaluated_at", simulation_time)))
						/ maxf(
							reset_end - float(command.get("evaluated_at", simulation_time)), 0.001
						)
					),
					0.0,
					1.0
				)
			)
		var current_y := lerpf(floor_y, target_y, progress) - camera_position.y
		var local_floor_y := floor_y - camera_position.y
		var local_target_y := target_y - camera_position.y
		if use_illustrated_art:
			draw_texture_rect(
				RISING_SURFACE,
				Rect2(
					Vector2(
						world_bounds.position.x - camera_position.x,
						current_y - RISING_SURFACE_MEAN_OFFSET
					),
					Vector2(world_bounds.size.x, RISING_SURFACE_HEIGHT)
				),
				false,
				Color(1.0, 1.0, 1.0, RISING_SURFACE_ALPHA)
			)
		var x := world_bounds.position.x - camera_position.x
		var local_end_x := world_bounds.end.x - camera_position.x
		draw_line(
			Vector2(x, local_target_y),
			Vector2(local_end_x, local_target_y),
			Color("#174b53", 0.94),
			8.0
		)
		while x < local_end_x:
			draw_line(
				Vector2(x, local_target_y),
				Vector2(minf(x + 56.0, local_end_x), local_target_y),
				Color("#fff2b5", 1.0),
				3.0
			)
			x += 96.0
		if ThemeDB.fallback_font != null:
			var target_label := (
				"FINAL LINE" if use_illustrated_art else "WAVE TARGET • %.0f wu" % target_y
			)
			var label_position := Vector2(
				world_bounds.position.x - camera_position.x + 12.0, local_target_y - 30.0
			)
			draw_rect(
				Rect2(label_position - Vector2(7.0, 17.0), Vector2(112.0, 24.0)),
				Color("#174b53", 0.96),
				true
			)
			draw_rect(
				Rect2(label_position - Vector2(7.0, 17.0), Vector2(112.0, 24.0)),
				Color("#f5d681", 1.0),
				false,
				1.5
			)
			draw_string(
				ThemeDB.fallback_font,
				label_position,
				target_label,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				12,
				Color("#fff6d5")
			)


func _sync_water_fill() -> void:
	if _water_fill == null:
		return
	_water_fill.visible = false
	for command in shown_commands:
		if int(command.get("command", -1)) != KangarooRoundController.Command.RISING:
			continue
		var target_y := float(command.get("wave_y", -1.0))
		var start := float(command.get("response_start_at", simulation_time))
		var end := float(command.get("response_end_at", start + 1.0))
		var progress := clampf((simulation_time - start) / maxf(end - start, 0.001), 0.0, 1.0)
		if str(command.get("status", "")) == "DRAIN":
			var evaluated_at := float(command.get("evaluated_at", simulation_time))
			var reset_end := evaluated_at + float(command.get("reset_seconds", 0.0))
			progress = 1.0 - clampf(
				(simulation_time - evaluated_at) / maxf(reset_end - evaluated_at, 0.001), 0.0, 1.0
			)
		var current_y := lerpf(floor_y, target_y, progress)
		# The body begins at the simulated mean surface. The artwork's lower edge is alpha-feathered
		# into this patterned fill, so its decorative water does not create a second, lower surface.
		var fill_height := floor_y - current_y
		if fill_height <= 0.0 or world_bounds.size.x <= 0.0:
			return
		_water_fill.position = Vector2(
			world_bounds.position.x - camera_position.x, current_y - camera_position.y
		)
		_water_fill.size = Vector2(world_bounds.size.x, fill_height)
		_water_material.set_shader_parameter("region_size", _water_fill.size)
		_water_material.set_shader_parameter("simulation_time", simulation_time)
		_water_fill.visible = true
		return


func _draw_illustrated_slipper(center: Vector2, command_type: int, alpha: float) -> void:
	var texture: Texture2D
	var size := Vector2(104.0, 258.0)
	var angle := 0.0
	match command_type:
		KangarooRoundController.Command.FREEZE:
			texture = FREEZE_SLIPPER
		KangarooRoundController.Command.RISING:
			texture = RISING_SLIPPER
			angle = PI
		KangarooRoundController.Command.HUG:
			texture = HUG_SLIPPER
			size = Vector2(252.0, 80.0)
	if texture == null:
		return
	var modulation := Color(1.0, 1.0, 1.0, clampf(alpha, 0.0, 1.0))
	draw_set_transform(center, angle, Vector2.ONE)
	draw_texture_rect(texture, Rect2(-size * 0.5, size), false, modulation)
	draw_set_transform(Vector2.ZERO)


func _draw_hug_links() -> void:
	if not use_illustrated_art:
		return
	var hug_response_active := false
	for command in shown_commands:
		if (
			int(command.get("command", -1)) == KangarooRoundController.Command.HUG
			and str(command.get("status", "")) == "RESPONSE"
		):
			hug_response_active = true
			break
	if not hug_response_active:
		return
	for link in hug_links:
		var midpoint: Vector2 = (link.position_a + link.position_b) * 0.5
		midpoint -= camera_position
		draw_texture_rect(
			HUG_LINK, Rect2(midpoint - Vector2(18.0, 9.0), Vector2(36.0, 18.0)), false
		)


func _draw_slipper(center: Vector2, angle: float, color: Color, command_type: int) -> void:
	var local_shape := PackedVector2Array(
		[
			Vector2(-42.0, -96.0),
			Vector2(-28.0, -120.0),
			Vector2(24.0, -116.0),
			Vector2(44.0, -92.0),
			Vector2(48.0, 74.0),
			Vector2(34.0, 112.0),
			Vector2(-30.0, 114.0),
			Vector2(-48.0, 78.0),
		]
	)
	var transform := Transform2D(angle, center)
	var silhouette := PackedVector2Array()
	for point in local_shape:
		silhouette.append(transform * point)
	var soft := color
	soft.a = 0.62
	draw_colored_polygon(silhouette, soft)
	var outline := silhouette.duplicate()
	outline.append(silhouette[0])
	draw_polyline(outline, Color("#17242a"), 6.0, true)
	var stripe_count := 3
	for stripe in range(stripe_count):
		var y := -34.0 + float(stripe) * 24.0
		var a := transform * Vector2(-25.0, y)
		var b := transform * Vector2(25.0, y)
		draw_line(a, b, Color("#17242a", 0.82), 5.0)
	if command_type == KangarooRoundController.Command.FREEZE:
		draw_circle(center, 9.0, Color.WHITE)
	elif command_type == KangarooRoundController.Command.RISING:
		draw_line(center + Vector2(0.0, 24.0), center + Vector2(0.0, -36.0), Color.WHITE, 7.0)
		draw_line(center + Vector2(0.0, -36.0), center + Vector2(-18.0, -16.0), Color.WHITE, 7.0)
		draw_line(center + Vector2(0.0, -36.0), center + Vector2(18.0, -16.0), Color.WHITE, 7.0)
	else:
		draw_line(center + Vector2(-24.0, 0.0), center + Vector2(24.0, 0.0), Color.WHITE, 7.0)


func _pose_color(command_type: int) -> Color:
	match command_type:
		KangarooRoundController.Command.FREEZE:
			return Color("#f2c14e")
		KangarooRoundController.Command.RISING:
			return Color("#39b9c9")
		KangarooRoundController.Command.HUG:
			return Color("#e47ab2")
	return Color.WHITE


func _ease_out(value: float) -> float:
	return 1.0 - pow(1.0 - clampf(value, 0.0, 1.0), 3.0)

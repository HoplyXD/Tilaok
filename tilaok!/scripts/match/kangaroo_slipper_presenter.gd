class_name KangarooSlipperPresenter
extends Node2D

## Debug-only, non-colliding code-drawn presenter and rising-wave cue. Final art/audio stays with
## the human art/audio team; this node is presentation only and has no physics shapes.

var shown_commands: Array[Dictionary] = []
var world_bounds := Rect2()
var floor_y := 0.0
var simulation_time := 0.0
var camera_position := Vector2.ZERO


func set_state(
	commands: Array[Dictionary],
	bounds: Rect2,
	floor_height: float,
	active_time: float,
	camera_position: Vector2
) -> void:
	shown_commands = commands.duplicate(true)
	world_bounds = bounds
	floor_y = floor_height
	simulation_time = active_time
	self.camera_position = camera_position
	position = camera_position
	visible = not shown_commands.is_empty()
	queue_redraw()


func _draw() -> void:
	if shown_commands.is_empty():
		return
	_draw_wave_targets()
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
		if bool(command.get("is_storm", false)):
			landing_progress = clampf((simulation_time - start) / 0.16, 0.0, 1.0)
		center.y = lerpf(-148.0, -12.0, _ease_out(landing_progress))
		var angle := 0.0
		if command_type == KangarooRoundController.Command.RISING:
			angle = PI
		elif command_type == KangarooRoundController.Command.HUG:
			angle = PI * 0.5
		var color := _pose_color(command_type)
		_draw_slipper(center, angle, color, command_type)
	if count > 0:
		var font := ThemeDB.fallback_font
		if font != null:
			draw_string(
				font,
				Vector2(-88.0, -172.0),
				"DEBUG SLIPPER POSE",
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
		if target_y < 0.0:
			continue
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
		var fill := Color("#48c8d8")
		fill.a = 0.13
		draw_rect(
			Rect2(
				Vector2(world_bounds.position.x - camera_position.x, current_y),
				Vector2(world_bounds.size.x, local_floor_y - current_y)
			),
			fill,
			true
		)
		var line_color := Color("#9ceaf2")
		line_color.a = 0.82
		var x := world_bounds.position.x - camera_position.x
		var local_end_x := world_bounds.end.x - camera_position.x
		while x < local_end_x:
			draw_line(
				Vector2(x, local_target_y),
				Vector2(minf(x + 72.0, local_end_x), local_target_y),
				line_color,
				4.0
			)
			x += 120.0
		if ThemeDB.fallback_font != null:
			draw_string(
				ThemeDB.fallback_font,
				Vector2(world_bounds.position.x - camera_position.x + 12.0, local_target_y - 8.0),
				"DEBUG RISING WAVE • %.0f wu" % target_y,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				13,
				Color("#d8fbff")
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

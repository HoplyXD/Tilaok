class_name BoundedStageCamera
extends Camera2D

enum Context { PLAY, PLACE }

var tuning: GameplayTuning
var context := Context.PLAY
var targets: Array[StageCameraTarget] = []
var last_safe_position := Vector2.ZERO
var _initialized := false


func _ready() -> void:
	process_physics_priority = 100
	position_smoothing_enabled = false
	set_process(true)


func configure(source_tuning: GameplayTuning) -> void:
	tuning = source_tuning if source_tuning != null else GameplayTuning.new()
	zoom = Vector2.ONE * tuning.camera_zoom_min


func set_context(next_context: Context) -> void:
	context = next_context


func set_targets(next_targets: Array[StageCameraTarget]) -> void:
	targets = next_targets


func _process(delta: float) -> void:
	if tuning == null or targets.is_empty():
		return
	var target_bounds := _combined_bounds()
	if target_bounds.size.x <= 0.0 or target_bounds.size.y <= 0.0:
		return
	var padded := target_bounds.grow(tuning.camera_target_padding_wu)
	var usable := _usable_rect()
	var fitted_zoom := minf(usable.size.x / padded.size.x, usable.size.y / padded.size.y)
	fitted_zoom = clampf(fitted_zoom, tuning.camera_zoom_min, tuning.camera_zoom_max)
	var next_zoom := fitted_zoom
	var weight := (
		1.0 if tuning.camera_ease_seconds <= 0.0 else 1.0 - exp(-delta / tuning.camera_ease_seconds)
	)
	if zoom.x > fitted_zoom:
		zoom = Vector2.ONE * fitted_zoom
	elif tuning.camera_ease_seconds > 0.0:
		next_zoom = lerpf(zoom.x, fitted_zoom, weight)
		zoom = Vector2.ONE * next_zoom
	var desired := _clamped_camera_position(target_bounds.get_center(), zoom.x)
	if not _bounds_visible(target_bounds, desired, zoom.x):
		position = desired
		last_safe_position = desired
		_initialized = true
		return
	if not _initialized:
		position = desired
		last_safe_position = desired
		_initialized = true
		return
	var eased := _clamp_camera_center(position.lerp(desired, weight), zoom.x)
	if _bounds_visible(target_bounds, eased, zoom.x):
		position = eased
		last_safe_position = eased
	else:
		position = desired
		last_safe_position = desired


func screen_bounds_visible(world_rect: Rect2) -> bool:
	return _bounds_visible(world_rect, position, zoom.x)


func _combined_bounds() -> Rect2:
	var result := targets[0].world_rect
	for index in range(1, targets.size()):
		result = result.merge(targets[index].world_rect)
	return result


func _usable_rect() -> Rect2:
	var viewport_size := Vector2(tuning.camera_virtual_width_px, tuning.camera_virtual_height_px)
	return Rect2(
		Vector2(0.0, tuning.camera_hud_reservation_px),
		Vector2(viewport_size.x, viewport_size.y - tuning.camera_hud_reservation_px)
	)


func _clamped_camera_position(target_center: Vector2, zoom_value: float) -> Vector2:
	var camera_center := (
		target_center - Vector2(0.0, tuning.camera_hud_reservation_px * 0.5 / zoom_value)
	)
	return _clamp_camera_center(camera_center, zoom_value)


func _clamp_camera_center(camera_center: Vector2, zoom_value: float) -> Vector2:
	var viewport_size := Vector2(tuning.camera_virtual_width_px, tuning.camera_virtual_height_px)
	var bounds := tuning.camera_view_bounds
	var half_x := viewport_size.x * 0.5 / zoom_value
	var low_x := bounds.position.x + half_x
	var high_x := bounds.end.x - half_x
	if low_x > high_x:
		camera_center.x = bounds.get_center().x
	else:
		camera_center.x = clampf(camera_center.x, low_x, high_x)
	var half_y := viewport_size.y * 0.5 / zoom_value
	var low_y := bounds.position.y + half_y
	var high_y := bounds.end.y - half_y
	if low_y > high_y:
		camera_center.y = bounds.get_center().y
	else:
		camera_center.y = clampf(camera_center.y, low_y, high_y)
	return camera_center


func _bounds_visible(world_rect: Rect2, camera_center: Vector2, zoom_value: float) -> bool:
	var viewport_size := Vector2(tuning.camera_virtual_width_px, tuning.camera_virtual_height_px)
	var screen_center := viewport_size * 0.5
	var safe_rect := _usable_rect()
	var top_left := (world_rect.position - camera_center) * zoom_value + screen_center
	var bottom_right := (world_rect.end - camera_center) * zoom_value + screen_center
	return safe_rect.has_point(top_left) and safe_rect.has_point(bottom_right)

class_name GameplayTuning
extends Resource

## PROTOTYPE — UNTESTED values from docs/PROTOTYPE_DEFAULTS.md.
@export var grid_cell_wu: float = 32.0
@export var arena_width_tiles: int = 32
@export var arena_height_tiles: int = 16
@export var body_width_wu: float = 24.0
@export var body_height_wu: float = 48.0
@export var jump_height_wu: float = 96.0
@export var jump_apex_seconds: float = 0.32
@export var run_speed_wu_s: float = 280.0
@export var ground_accel_wu_s2: float = 2400.0
@export var brake_wu_s2: float = 2800.0
@export var reverse_wu_s2: float = 3200.0
@export var air_accel_wu_s2: float = 1600.0
@export var air_neutral_drag_wu_s2: float = 0.0
@export var coyote_seconds: float = 0.10
@export var jump_buffer_seconds: float = 0.10
@export var fall_gravity_multiplier: float = 1.35
@export var fall_speed_cap_wu_s: float = 900.0
@export var jump_release_gravity_multiplier: float = 2.5
@export var stick_activation_threshold: float = 0.25
@export var stick_neutral_threshold: float = 0.20
@export var placement_initial_repeat_delay: float = 0.25
@export var placement_repeat_rate: float = 8.0
@export var menu_initial_repeat_delay: float = 0.25
@export var menu_repeat_rate: float = 6.0
@export var contact_sensor_width_wu: float = 28.0
@export var contact_sensor_height_wu: float = 48.0
@export var taya_pass_back_seconds: float = 1.0
@export var camera_virtual_width_px: float = 1280.0
@export var camera_virtual_height_px: float = 720.0
@export var camera_hud_reservation_px: float = 64.0
@export var camera_target_padding_wu: float = 64.0
@export var camera_zoom_min: float = 1.0
@export var camera_zoom_max: float = 1.4
@export var camera_ease_seconds: float = 0.20
@export var camera_view_bounds := Rect2(Vector2(-64.0, -64.0), Vector2(1152.0, 640.0))
@export var support_normal_limit_degrees: float = 45.0
@export var support_contact_tolerance_wu: float = 1.0
@export var support_height_epsilon_wu: float = 1.0
## Wall slide / wall jump (approved Should extension, REQ-MOVE-004). PROTOTYPE — UNMEASURED.
## Disabled by default; the October 21 keep/defer decision sets the shipped value.
@export var wall_movement_enabled: bool = false
@export var wall_slide_fall_cap_wu_s: float = 120.0
@export var wall_jump_horizontal_wu_s: float = 240.0
@export var wall_jump_vertical_wu_s: float = -520.0
@export var wall_jump_contact_grace_s: float = 0.08
@export var wall_jump_recontact_separation_wu: float = 8.0
@export var wall_contact_probe_wu: float = 1.0
@export var wall_normal_tolerance_degrees: float = 10.0


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	for field_name in [
		"grid_cell_wu",
		"body_width_wu",
		"body_height_wu",
		"jump_height_wu",
		"jump_apex_seconds",
		"run_speed_wu_s",
		"ground_accel_wu_s2",
		"brake_wu_s2",
		"reverse_wu_s2",
		"air_accel_wu_s2",
		"air_neutral_drag_wu_s2",
		"coyote_seconds",
		"jump_buffer_seconds",
		"fall_gravity_multiplier",
		"fall_speed_cap_wu_s",
		"jump_release_gravity_multiplier",
		"stick_activation_threshold",
		"stick_neutral_threshold",
		"placement_initial_repeat_delay",
		"placement_repeat_rate",
		"menu_initial_repeat_delay",
		"menu_repeat_rate",
		"contact_sensor_width_wu",
		"contact_sensor_height_wu",
		"taya_pass_back_seconds",
		"camera_virtual_width_px",
		"camera_virtual_height_px",
		"camera_hud_reservation_px",
		"camera_target_padding_wu",
		"camera_zoom_min",
		"camera_zoom_max",
		"camera_ease_seconds",
		"support_normal_limit_degrees",
		"support_contact_tolerance_wu",
		"support_height_epsilon_wu",
		"wall_slide_fall_cap_wu_s",
		"wall_jump_horizontal_wu_s",
		"wall_jump_vertical_wu_s",
		"wall_jump_contact_grace_s",
		"wall_jump_recontact_separation_wu",
		"wall_contact_probe_wu",
		"wall_normal_tolerance_degrees",
	]:
		if not is_finite(get(field_name)):
			errors.append("%s must be finite" % field_name)
	if grid_cell_wu <= 0.0:
		errors.append("grid_cell_wu must be greater than zero")
	if arena_width_tiles <= 0 or arena_height_tiles <= 0:
		errors.append("arena tile dimensions must be greater than zero")
	if body_width_wu <= 0.0 or body_height_wu <= 0.0:
		errors.append("body dimensions must be greater than zero")
	if jump_height_wu <= 0.0 or jump_apex_seconds <= 0.0:
		errors.append("jump height and apex time must be greater than zero")
	if run_speed_wu_s <= 0.0 or ground_accel_wu_s2 <= 0.0 or brake_wu_s2 <= 0.0:
		errors.append("movement speeds and accelerations must be greater than zero")
	if reverse_wu_s2 <= 0.0 or air_accel_wu_s2 < 0.0 or air_neutral_drag_wu_s2 < 0.0:
		errors.append("air/reversal tuning is outside its valid range")
	if coyote_seconds < 0.0 or jump_buffer_seconds < 0.0 or taya_pass_back_seconds < 0.0:
		errors.append("timing values cannot be negative")
	if fall_gravity_multiplier < 1.0 or fall_speed_cap_wu_s <= 0.0:
		errors.append("fall gravity and speed cap must be positive")
	if jump_release_gravity_multiplier < 1.0:
		errors.append("jump release multiplier must be at least one")
	if stick_neutral_threshold < 0.0 or stick_activation_threshold <= stick_neutral_threshold:
		errors.append("stick thresholds must define a positive hysteresis interval")
	if placement_initial_repeat_delay < 0.0 or menu_initial_repeat_delay < 0.0:
		errors.append("repeat delays cannot be negative")
	if placement_repeat_rate <= 0.0 or menu_repeat_rate <= 0.0:
		errors.append("navigation repeat rates must be positive")
	if contact_sensor_width_wu <= 0.0 or contact_sensor_height_wu <= 0.0:
		errors.append("contact sensor dimensions must be positive")
	if camera_virtual_width_px <= 0.0 or camera_virtual_height_px <= camera_hud_reservation_px:
		errors.append("camera viewport must be positive and taller than its HUD reservation")
	if camera_hud_reservation_px < 0.0 or camera_target_padding_wu < 0.0:
		errors.append("camera HUD reservation and target padding cannot be negative")
	if camera_zoom_min <= 0.0 or camera_zoom_max < camera_zoom_min:
		errors.append("camera zoom range is invalid")
	if camera_ease_seconds < 0.0:
		errors.append("camera easing duration cannot be negative")
	if support_normal_limit_degrees < 0.0 or support_normal_limit_degrees > 90.0:
		errors.append("support normal limit must be between zero and 90 degrees")
	if support_contact_tolerance_wu < 0.0 or support_height_epsilon_wu < 0.0:
		errors.append("support tolerances cannot be negative")
	errors.append_array(_validate_wall_movement())
	if camera_view_bounds.size.x <= 0.0 or camera_view_bounds.size.y <= 0.0:
		errors.append("camera view bounds must have positive dimensions")
	for bound_value in [
		camera_view_bounds.position.x,
		camera_view_bounds.position.y,
		camera_view_bounds.size.x,
		camera_view_bounds.size.y
	]:
		if not is_finite(bound_value):
			errors.append("camera view bounds must be finite")
			break
	return errors


func _validate_wall_movement() -> PackedStringArray:
	var errors := PackedStringArray()
	if wall_slide_fall_cap_wu_s <= 0.0 or wall_slide_fall_cap_wu_s > fall_speed_cap_wu_s:
		errors.append("wall slide cap must be positive and not exceed the fall speed cap")
	if wall_jump_horizontal_wu_s < 0.0 or wall_jump_horizontal_wu_s > 480.0:
		errors.append("wall jump horizontal speed must be between 0 and the 480 wu/s external cap")
	if wall_jump_vertical_wu_s >= 0.0 or wall_jump_vertical_wu_s < -900.0:
		errors.append("wall jump vertical speed must be upward and within the 900 wu/s launch cap")
	if wall_jump_contact_grace_s < 0.0 or wall_jump_contact_grace_s > 0.25:
		errors.append("wall jump contact grace must be between 0 and 0.25 seconds")
	if wall_contact_probe_wu <= 0.0 or wall_contact_probe_wu > 4.0:
		errors.append("wall contact probe distance must be between 0 and 4 wu")
	if wall_jump_recontact_separation_wu <= wall_contact_probe_wu:
		errors.append("wall recontact separation must exceed the contact probe distance")
	if wall_normal_tolerance_degrees < 0.0 or wall_normal_tolerance_degrees > 45.0:
		errors.append("wall normal tolerance must be between 0 and 45 degrees")
	return errors

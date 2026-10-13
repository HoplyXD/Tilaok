class_name GameplayTuning
extends Resource

## PROTOTYPE — UNTESTED values from docs/PROTOTYPE_DEFAULTS.md.
@export var grid_cell_wu: float = 32.0
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
		"taya_pass_back_seconds"
	]:
		if not is_finite(get(field_name)):
			errors.append("%s must be finite" % field_name)
	if grid_cell_wu <= 0.0:
		errors.append("grid_cell_wu must be greater than zero")
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
	return errors

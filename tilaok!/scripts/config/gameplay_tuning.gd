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
	return errors

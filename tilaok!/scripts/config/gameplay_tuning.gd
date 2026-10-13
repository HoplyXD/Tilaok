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
## Core movement: enabled everywhere by default (owner decision, 2026-10-13).
@export var wall_movement_enabled: bool = true
@export var wall_slide_fall_cap_wu_s: float = 120.0
@export var wall_jump_horizontal_wu_s: float = 240.0
@export var wall_jump_vertical_wu_s: float = -520.0
@export var wall_jump_contact_grace_s: float = 0.08
@export var wall_jump_recontact_separation_wu: float = 8.0
@export var wall_contact_probe_wu: float = 1.0
@export var wall_normal_tolerance_degrees: float = 10.0
## PROTOTYPE item infrastructure values: docs/PROTOTYPE_DEFAULTS.md §4 (items.*, transients.*).
@export var item_persistent_cap: int = 48
@export var item_projectile_cap: int = 16
@export var item_projectiles_per_emitter: int = 2
@export var item_bubble_cap: int = 4
@export var item_bubbles_per_emitter: int = 1
@export var item_bubbles_per_player: int = 1
@export var item_vfx_cap: int = 32
@export var item_projectile_ttl_s: float = 3.0
@export var item_bubble_ttl_s: float = 4.0
@export var item_vfx_ttl_s: float = 2.0
@export var item_activation_grace_s: float = 1.0
@export var item_tulay_strip_thickness_wu: float = 4.0
@export var item_tulay_vertical_enabled: bool = false
@export var item_kaing_weight: float = 50.0
@export var item_tulay_weight: float = 50.0
## P10 first-batch item values. PROVISIONAL and UNMEASURED: docs/PROTOTYPE_DEFAULTS.md §4/§P10.
## Spring gate figures (775/849 wu/s, 0.10 s window, 0.20 s cooldown, 480/900 caps) are documented.
@export var item_spring_launch_wu_s: float = 775.0
@export var item_spring_boost_wu_s: float = 849.0
@export var item_spring_boost_window_s: float = 0.10
@export var item_spring_cooldown_s: float = 0.20
@export var item_spring_contact_probe_wu: float = 2.0
@export var item_spring_horizontal_cap_wu_s: float = 480.0
@export var item_spring_upward_cap_wu_s: float = 900.0
@export var item_spring_weight: float = 15.0
@export var item_trumpo_speed_wu_s: float = 160.0
@export var item_trumpo_pause_s: float = 0.75
@export var item_trumpo_hit_wu: float = 20.0
@export var item_trumpo_weight: float = 50.0
@export var item_parol_cycle_s: float = 3.0
@export var item_parol_active_s: float = 1.5
@export var item_parol_charge_s: float = 0.6
@export var item_parol_beam_width_wu: float = 12.0
@export var item_parol_weight: float = 50.0
@export var item_launcher_initial_delay_s: float = 0.5
@export var item_launcher_telegraph_s: float = 0.8
@export var item_launcher_cooldown_s: float = 1.7
@export var item_launcher_projectile_speed_wu_s: float = 360.0
@export var item_launcher_projectile_size_wu: float = 14.0
@export var item_launcher_weight: float = 50.0
@export var item_walis_weight: float = 50.0
@export var item_bubble_cadence_s: float = 2.5
@export var item_bubble_rise_wu_s: float = 60.0
@export var item_bubble_radius_wu: float = 14.0
@export var item_bubble_capture_s: float = 2.0
@export var item_bubble_release_wu_s: float = 120.0
@export var item_bubble_recapture_immunity_s: float = 1.0
@export var item_bubble_weight: float = 50.0
## P05 match-loop prototype values; copied into the match configuration snapshot.
@export var match_pugad_extra_eggs: int = 2
@export var match_pugad_seconds: float = 8.0
@export var match_place_seconds: float = 15.0
@export var match_results_advance_seconds: float = 8.0
## P06 provisional active-simulation race deadlines; frozen with the match snapshot.
@export var match_race_hard_cap_seconds: float = 60.0
@export var match_race_after_first_finish_seconds: float = 15.0
## Variant keys allowed into the prototype pool; each must be defined and approved.
@export var item_enabled_variants: PackedStringArray = PackedStringArray(
	[
		"build.hollow_blocks.cell_1x1",
		"build.hollow_blocks.stack_2x3",
		"build.bamboo_bridge.span_4x1",
	]
)


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
		"item_projectile_ttl_s",
		"item_bubble_ttl_s",
		"item_vfx_ttl_s",
		"item_activation_grace_s",
		"item_tulay_strip_thickness_wu",
		"item_kaing_weight",
		"item_tulay_weight",
		"item_spring_launch_wu_s",
		"item_spring_boost_wu_s",
		"item_spring_boost_window_s",
		"item_spring_cooldown_s",
		"item_spring_contact_probe_wu",
		"item_trumpo_speed_wu_s",
		"item_trumpo_pause_s",
		"item_trumpo_hit_wu",
		"item_parol_cycle_s",
		"item_parol_active_s",
		"item_parol_charge_s",
		"item_parol_beam_width_wu",
		"item_launcher_initial_delay_s",
		"item_launcher_telegraph_s",
		"item_launcher_cooldown_s",
		"item_launcher_projectile_speed_wu_s",
		"item_launcher_projectile_size_wu",
		"item_bubble_cadence_s",
		"item_bubble_rise_wu_s",
		"item_bubble_radius_wu",
		"item_bubble_capture_s",
		"item_bubble_release_wu_s",
		"item_bubble_recapture_immunity_s",
		"match_pugad_seconds",
		"match_place_seconds",
		"match_results_advance_seconds",
		"match_race_hard_cap_seconds",
		"match_race_after_first_finish_seconds",
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
	errors.append_array(_validate_item_tuning())
	if camera_view_bounds.size.x <= 0.0 or camera_view_bounds.size.y <= 0.0:
		errors.append("camera view bounds must have positive dimensions")
	if match_pugad_extra_eggs < 0:
		errors.append("match_pugad_extra_eggs cannot be negative")
	if (
		match_pugad_seconds <= 0.0
		or match_place_seconds <= 0.0
		or match_results_advance_seconds <= 0.0
		or match_race_hard_cap_seconds <= 0.0
		or match_race_after_first_finish_seconds <= 0.0
	):
		errors.append("match phase durations must be greater than zero")
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


func _validate_item_tuning() -> PackedStringArray:
	var errors := PackedStringArray()
	if item_persistent_cap <= 0:
		errors.append("item_persistent_cap must be greater than zero")
	if item_projectile_cap < 0 or item_bubble_cap < 0 or item_vfx_cap < 0:
		errors.append("transient caps cannot be negative")
	if (
		item_projectiles_per_emitter < 0
		or item_bubbles_per_emitter < 0
		or item_bubbles_per_player < 0
	):
		errors.append("per-emitter and per-player transient limits cannot be negative")
	if item_projectile_ttl_s <= 0.0 or item_bubble_ttl_s <= 0.0 or item_vfx_ttl_s <= 0.0:
		errors.append("transient lifetimes must be greater than zero")
	if item_activation_grace_s < 0.0:
		errors.append("item activation grace cannot be negative")
	if item_tulay_strip_thickness_wu <= 0.0 or item_tulay_strip_thickness_wu > grid_cell_wu:
		errors.append("Tulay strip thickness must be positive and no larger than one cell")
	if item_kaing_weight < 0.0 or item_tulay_weight < 0.0:
		errors.append("item family weights cannot be negative")
	errors.append_array(_validate_first_batch_tuning())
	return errors


func _validate_first_batch_tuning() -> PackedStringArray:
	var errors := PackedStringArray()
	for weight in [
		item_spring_weight,
		item_trumpo_weight,
		item_parol_weight,
		item_launcher_weight,
		item_walis_weight,
		item_bubble_weight
	]:
		if not is_finite(weight) or weight < 0.0:
			errors.append("first-batch item weights must be finite and not negative")
			break
	for positive in [
		item_spring_launch_wu_s,
		item_spring_boost_wu_s,
		item_spring_contact_probe_wu,
		item_spring_horizontal_cap_wu_s,
		item_spring_upward_cap_wu_s,
		item_trumpo_speed_wu_s,
		item_trumpo_hit_wu,
		item_parol_cycle_s,
		item_parol_active_s,
		item_parol_beam_width_wu,
		item_launcher_telegraph_s,
		item_launcher_projectile_speed_wu_s,
		item_launcher_projectile_size_wu,
		item_bubble_cadence_s,
		item_bubble_rise_wu_s,
		item_bubble_radius_wu,
		item_bubble_capture_s,
	]:
		if not is_finite(positive) or positive <= 0.0:
			errors.append("first-batch item magnitudes must be finite and greater than zero")
			break
	if item_spring_launch_wu_s > item_spring_upward_cap_wu_s:
		errors.append("spring launch cannot exceed the 900 wu/s upward cap")
	if item_spring_boost_wu_s > item_spring_upward_cap_wu_s:
		errors.append("spring boost cannot exceed the 900 wu/s upward cap")
	if item_spring_boost_wu_s < item_spring_launch_wu_s:
		errors.append("spring boost must not be weaker than the plain launch")
	if item_spring_horizontal_cap_wu_s > 480.0 or item_spring_upward_cap_wu_s > 900.0:
		errors.append("spring caps cannot exceed the documented 480/900 wu/s external caps")
	if item_spring_boost_window_s < 0.0 or item_spring_cooldown_s < 0.0:
		errors.append("spring windows cannot be negative")
	if item_parol_active_s >= item_parol_cycle_s:
		errors.append("Parol active window must be shorter than its cycle")
	if item_parol_charge_s < 0.0 or item_parol_charge_s > item_parol_cycle_s - item_parol_active_s:
		errors.append("Parol charge must fit inside the inactive window")
	if item_trumpo_pause_s < 0.0 or item_launcher_initial_delay_s < 0.0:
		errors.append("item pauses and delays cannot be negative")
	if item_launcher_cooldown_s < 0.0 or item_bubble_recapture_immunity_s < 0.0:
		errors.append("item cooldowns and immunity cannot be negative")
	if item_bubble_release_wu_s < 0.0 or item_bubble_release_wu_s > item_spring_upward_cap_wu_s:
		errors.append("bubble release speed must be between zero and the 900 wu/s cap")
	return errors

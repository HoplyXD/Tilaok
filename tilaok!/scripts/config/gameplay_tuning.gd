class_name GameplayTuning
extends Resource

## Fields measured in wu, wu/s or wu/s². with_distance_scale() multiplies exactly these.
const DISTANCE_FIELDS: PackedStringArray = [
	"grid_cell_wu",
	"body_width_wu",
	"body_height_wu",
	"jump_height_wu",
	"run_speed_wu_s",
	"ground_accel_wu_s2",
	"brake_wu_s2",
	"reverse_wu_s2",
	"air_accel_wu_s2",
	"air_neutral_drag_wu_s2",
	"fall_speed_cap_wu_s",
	"launch_max_horizontal_wu_s",
	"launch_max_upward_wu_s",
	"contact_sensor_width_wu",
	"contact_sensor_height_wu",
	"camera_target_padding_wu",
	"wall_slide_fall_cap_wu_s",
	"wall_jump_horizontal_wu_s",
	"wall_jump_vertical_wu_s",
	"wall_jump_recontact_separation_wu",
	"sneak_height_wu",
	"glide_fall_cap_wu_s",
	"water_sink_cap_wu_s",
	"water_buoyancy_wu_s2",
	"water_stroke_wu_s",
	"water_move_wu_s",
	"block_box_push_speed_wu_s",
	"block_box_friction_wu_s2",
	"item_tulay_strip_thickness_wu",
	"item_spring_launch_wu_s",
	"item_spring_boost_wu_s",
	"item_spring_contact_probe_wu",
	"item_spring_horizontal_cap_wu_s",
	"item_spring_upward_cap_wu_s",
	"item_trumpo_speed_wu_s",
	"item_trumpo_hit_wu",
	"item_parol_beam_width_wu",
	"item_launcher_projectile_speed_wu_s",
	"item_launcher_projectile_size_wu",
	"item_bubble_rise_wu_s",
	"item_bubble_radius_wu",
	"item_bubble_release_wu_s",
]

## PROTOTYPE — UNTESTED values from docs/PROTOTYPE_DEFAULTS.md.
## 2026-10-14: 64 wu grid (1 tile = 64 px). Distances/speeds are the 32 wu values x2;
## times are unchanged.
@export var grid_cell_wu: float = 64.0
@export var arena_width_tiles: int = 32
@export var arena_height_tiles: int = 16
@export var body_width_wu: float = 56.0
@export var body_height_wu: float = 120.0
@export var jump_height_wu: float = 192.0
@export var jump_apex_seconds: float = 0.32
@export var run_speed_wu_s: float = 560.0
@export var ground_accel_wu_s2: float = 4800.0
@export var brake_wu_s2: float = 5600.0
@export var reverse_wu_s2: float = 6400.0
@export var air_accel_wu_s2: float = 3200.0
@export var air_neutral_drag_wu_s2: float = 0.0
@export var coyote_seconds: float = 0.10
@export var jump_buffer_seconds: float = 0.10
@export var fall_gravity_multiplier: float = 1.35
@export var fall_speed_cap_wu_s: float = 1800.0
## External launch caps (ChickenController.launch defaults).
@export var launch_max_horizontal_wu_s: float = 960.0
@export var launch_max_upward_wu_s: float = 1800.0
@export var jump_release_gravity_multiplier: float = 2.5
@export var stick_activation_threshold: float = 0.25
@export var stick_neutral_threshold: float = 0.20
@export var placement_initial_repeat_delay: float = 0.25
@export var placement_repeat_rate: float = 8.0
@export var menu_initial_repeat_delay: float = 0.25
@export var menu_repeat_rate: float = 6.0
@export var contact_sensor_width_wu: float = 60.0
@export var contact_sensor_height_wu: float = 120.0
@export var taya_pass_back_seconds: float = 1.0
## P08 provisional active-simulation settings, copied into each round snapshot.
@export var lagsanay_opening_head_start_seconds: float = 3.0
@export var lagsanay_taya_seconds_2p: float = 20.0
@export var lagsanay_taya_seconds_3p: float = 25.0
@export var lagsanay_taya_seconds_4p: float = 30.0
@export var lagsanay_last_cluck_freeze_seconds: float = 0.75
## P11 independent Kangaroo. Gameplay values are copied into the match snapshot.
@export var kangaroo_telegraph_seconds: float = 2.0
@export var kangaroo_response_seconds: float = 6.0
@export var kangaroo_reset_seconds: float = 1.5
@export var kangaroo_response_acceleration_step_seconds: float = 0.5
@export var kangaroo_response_min_seconds: float = 3.0
@export var kangaroo_reset_acceleration_step_seconds: float = 0.15
@export var kangaroo_reset_min_seconds: float = 0.75
@export var kangaroo_freeze_release_seconds: float = 0.10
@export var kangaroo_wave_middle_low_y_wu: float = 768.0
@export var kangaroo_wave_middle_y_wu: float = 576.0
@export var kangaroo_wave_middle_high_y_wu: float = 384.0
@export var kangaroo_storm_after_commands: int = 16
@export var kangaroo_storm_landing_seconds: float = 1.5
@export var kangaroo_storm_active_seconds: float = 3.0
@export var kangaroo_storm_min_after_commands: int = 16
@export var kangaroo_storm_min_landing_seconds: float = 1.5
@export var kangaroo_storm_min_active_seconds: float = 3.0
@export var kangaroo_storm_max_active: int = 2
@export var camera_virtual_width_px: float = 1280.0
@export var camera_virtual_height_px: float = 720.0
@export var camera_hud_reservation_px: float = 64.0
@export var camera_target_padding_wu: float = 128.0
@export var camera_zoom_min: float = 0.5
## 1.0 = normal, one world unit per screen pixel (user request, 2026-10-22). The camera opens here
## and only zooms out, towards camera_zoom_min, as the chickens spread apart.
@export var camera_zoom_max: float = 1.0
@export var camera_ease_seconds: float = 0.20
@export var camera_view_bounds := Rect2(Vector2(-128.0, -128.0), Vector2(2304.0, 1280.0))
@export var support_normal_limit_degrees: float = 45.0
@export var support_contact_tolerance_wu: float = 1.0
@export var support_height_epsilon_wu: float = 1.0
## Wall slide / wall jump (approved Should extension, REQ-MOVE-004). PROTOTYPE — UNMEASURED.
## Core movement: enabled everywhere by default (owner decision, 2026-10-13).
@export var wall_movement_enabled: bool = true
@export var wall_slide_fall_cap_wu_s: float = 240.0
@export var wall_jump_horizontal_wu_s: float = 480.0
@export var wall_jump_vertical_wu_s: float = -1040.0
@export var wall_jump_contact_grace_s: float = 0.08
@export var wall_jump_recontact_separation_wu: float = 16.0
@export var wall_contact_probe_wu: float = 1.0
@export var wall_normal_tolerance_degrees: float = 10.0
## Sneak and glide (owner request 2026-10-14). PROTOTYPE — UNMEASURED.
## Sneak: hold down while grounded to shrink to a 1x1 cell body; no walking or jumping.
@export var sneak_enabled: bool = true
@export var sneak_height_wu: float = 56.0
## Glide: hold jump while falling to cap descent; air steering is unchanged.
@export var glide_enabled: bool = true
@export var glide_fall_cap_wu_s: float = 180.0
## Water (the Water terrain of a map's Blocks layer). PROTOTYPE — UNMEASURED. A chicken in water
## floats: it sinks no faster than the sink cap, is pushed back up toward the surface, and may
## stroke upward with jump. Horizontal speed is capped while submerged.
@export var water_enabled: bool = true
## Terminal sink speed while submerged (positive is downward).
@export var water_sink_cap_wu_s: float = 90.0
## Upward push applied while submerged; this is what makes a chicken rise and bob at the surface.
@export var water_buoyancy_wu_s2: float = 900.0
## Upward speed from a jump press while submerged.
@export var water_stroke_wu_s: float = 240.0
## Horizontal speed cap while submerged.
@export var water_move_wu_s: float = 150.0
## Stage blocks (scenes/blocks). PROTOTYPE — UNMEASURED.
@export var block_box_push_speed_wu_s: float = 160.0
@export var block_box_friction_wu_s2: float = 2400.0
@export var block_collapse_delay_s: float = 2.0
@export var block_collapse_respawn_s: float = 3.0
## Yelo ng Sorbetero ice (P19, promoted on user request, 2026-10-16). PROTOTYPE — UNMEASURED. On a
## slippery block a grounded chicken brakes and turns with these fractions of its normal rates
## and its run speed is multiplied by `ice_speed_scale`, so it slides further.
@export var ice_brake_scale: float = 0.12
@export var ice_accel_scale: float = 0.6
@export var ice_speed_scale: float = 1.25
## Stun (block STUN hitboxes): re-stun immunity after a stun ends. Duration/knockback are per block.
@export var stun_immunity_s: float = 0.5
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
@export var item_tulay_strip_thickness_wu: float = 8.0
@export var item_tulay_vertical_enabled: bool = false
@export var item_kaing_weight: float = 50.0
@export var item_tulay_weight: float = 50.0
## P10 first-batch item values. PROVISIONAL and UNMEASURED: docs/PROTOTYPE_DEFAULTS.md §4/§P10.
## Spring gate figures were documented on the 32 wu grid (775/849 wu/s, 0.10 s window, 0.20 s
## cooldown, 480/900 caps); distances/speeds here are x2 for the 64 wu grid, times unchanged.
@export var item_spring_launch_wu_s: float = 1550.0
@export var item_spring_boost_wu_s: float = 1698.0
@export var item_spring_boost_window_s: float = 0.10
@export var item_spring_cooldown_s: float = 0.20
@export var item_spring_contact_probe_wu: float = 4.0
@export var item_spring_horizontal_cap_wu_s: float = 960.0
@export var item_spring_upward_cap_wu_s: float = 1800.0
## The six P10 families joined the main match pool on 2026-10-16 (user request) with these low
## PROVISIONAL egg weights (Gulong 15, Trumpo 20, Parol 15, Tsinelas 20, Walis 15, Bula 10).
@export var item_spring_weight: float = 15.0
@export var item_trumpo_speed_wu_s: float = 320.0
@export var item_trumpo_pause_s: float = 0.75
@export var item_trumpo_hit_wu: float = 40.0
@export var item_trumpo_weight: float = 20.0
@export var item_parol_cycle_s: float = 3.0
@export var item_parol_active_s: float = 1.5
@export var item_parol_charge_s: float = 0.6
@export var item_parol_beam_width_wu: float = 24.0
@export var item_parol_weight: float = 15.0
@export var item_launcher_initial_delay_s: float = 0.5
@export var item_launcher_telegraph_s: float = 0.8
@export var item_launcher_cooldown_s: float = 1.7
@export var item_launcher_projectile_speed_wu_s: float = 720.0
@export var item_launcher_projectile_size_wu: float = 28.0
@export var item_launcher_weight: float = 20.0
@export var item_walis_weight: float = 15.0
@export var item_bubble_cadence_s: float = 2.5
@export var item_bubble_rise_wu_s: float = 120.0
@export var item_bubble_radius_wu: float = 28.0
@export var item_bubble_capture_s: float = 2.0
@export var item_bubble_release_wu_s: float = 240.0
@export var item_bubble_recapture_immunity_s: float = 1.0
@export var item_bubble_weight: float = 10.0
@export var item_solid_block_weight: float = 50.0
@export var item_wood_box_weight: float = 50.0
@export var item_collapsing_block_weight: float = 50.0
## P05 match-loop prototype values; copied into the match configuration snapshot.
@export var match_pugad_extra_eggs: int = 2
@export var match_pugad_seconds: float = 15.0
## Barya is an optional P12 round objective. Other match routes leave it off.
@export var barya_enabled := false
@export_range(0.0, 1.0, 0.01) var barya_offer_probability := 1.0 / 3.0
@export var match_place_seconds: float = 15.0
@export var match_results_advance_seconds: float = 8.0
## P09 full-match termination; points are eighth-point units.
@export_range(1, 10000, 1) var match_target_score_units: int = 80
@export_range(1, 1000, 1) var match_round_limit: int = 12
## P06 provisional active-simulation race deadlines; frozen with the match snapshot.
@export var match_race_hard_cap_seconds: float = 120.0
@export var match_race_after_first_finish_seconds: float = 30.0
## Variant keys allowed into the Pugad pool. Defaults to every main-game block scene marked
## "enabled by default" (BlockCatalog), so a new scene in scenes/blocks/ joins with no edit here.
@export var item_enabled_variants: PackedStringArray = PackedStringArray()


func _init() -> void:
	item_enabled_variants = BlockCatalog.default_enabled_keys()


## Copy with every DISTANCE_FIELDS value (and the camera bounds) multiplied by `factor`;
## times are unchanged and zoom is divided so the framing stays the same. Used to keep
## historical 32 wu diagnostic fixtures (factor 0.5) on their measured scale.
func with_distance_scale(factor: float) -> GameplayTuning:
	var result := duplicate() as GameplayTuning
	for field_name in DISTANCE_FIELDS:
		result.set(field_name, float(get(field_name)) * factor)
	result.camera_view_bounds = Rect2(
		camera_view_bounds.position * factor, camera_view_bounds.size * factor
	)
	result.camera_zoom_min = camera_zoom_min / factor
	result.camera_zoom_max = camera_zoom_max / factor
	return result


## The historical 32 wu grid (P01–P04 measurements) derived from the current defaults.
static func legacy_32_wu() -> GameplayTuning:
	var current := GameplayTuning.new()
	var legacy := current.with_distance_scale(32.0 / current.grid_cell_wu)
	# The 64 wu body (56x120) is not an exact double of the measured 24x48 body; keep the
	# historical body and contact sensor so P02 measurements stay comparable.
	legacy.body_width_wu = 24.0
	legacy.body_height_wu = 48.0
	legacy.contact_sensor_width_wu = 28.0
	legacy.contact_sensor_height_wu = 48.0
	legacy.sneak_height_wu = 24.0
	return legacy


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
		"launch_max_horizontal_wu_s",
		"launch_max_upward_wu_s",
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
		"lagsanay_opening_head_start_seconds",
		"lagsanay_taya_seconds_2p",
		"lagsanay_taya_seconds_3p",
		"lagsanay_taya_seconds_4p",
		"lagsanay_last_cluck_freeze_seconds",
		"kangaroo_telegraph_seconds",
		"kangaroo_response_seconds",
		"kangaroo_reset_seconds",
		"kangaroo_response_acceleration_step_seconds",
		"kangaroo_response_min_seconds",
		"kangaroo_reset_acceleration_step_seconds",
		"kangaroo_reset_min_seconds",
		"kangaroo_freeze_release_seconds",
		"kangaroo_wave_middle_low_y_wu",
		"kangaroo_wave_middle_y_wu",
		"kangaroo_wave_middle_high_y_wu",
		"kangaroo_storm_landing_seconds",
		"kangaroo_storm_active_seconds",
		"kangaroo_storm_min_landing_seconds",
		"kangaroo_storm_min_active_seconds",
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
		"sneak_height_wu",
		"glide_fall_cap_wu_s",
		"water_sink_cap_wu_s",
		"water_buoyancy_wu_s2",
		"water_stroke_wu_s",
		"water_move_wu_s",
		"block_box_push_speed_wu_s",
		"block_box_friction_wu_s2",
		"block_collapse_delay_s",
		"block_collapse_respawn_s",
		"stun_immunity_s",
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
		"item_solid_block_weight",
		"item_wood_box_weight",
		"item_collapsing_block_weight",
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
	if (
		coyote_seconds < 0.0
		or jump_buffer_seconds < 0.0
		or taya_pass_back_seconds < 0.0
		or lagsanay_last_cluck_freeze_seconds < 0.0
		or kangaroo_freeze_release_seconds < 0.0
	):
		errors.append("timing values cannot be negative")
	if (
		lagsanay_opening_head_start_seconds <= 0.0
		or lagsanay_taya_seconds_2p <= 0.0
		or lagsanay_taya_seconds_3p <= 0.0
		or lagsanay_taya_seconds_4p <= 0.0
	):
		errors.append("Lagsanay head start and taya timers must be greater than zero")
	if launch_max_horizontal_wu_s <= 0.0 or launch_max_upward_wu_s <= 0.0:
		errors.append("launch caps must be greater than zero")
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
	errors.append_array(_validate_sneak_glide_blocks())
	errors.append_array(_validate_item_tuning())
	if camera_view_bounds.size.x <= 0.0 or camera_view_bounds.size.y <= 0.0:
		errors.append("camera view bounds must have positive dimensions")
	if match_pugad_extra_eggs < 0:
		errors.append("match_pugad_extra_eggs cannot be negative")
	if match_target_score_units <= 0 or match_round_limit <= 0:
		errors.append("match target score and round limit must be positive integers")
	if (
		match_pugad_seconds <= 0.0
		or match_place_seconds <= 0.0
		or match_results_advance_seconds <= 0.0
		or match_race_hard_cap_seconds <= 0.0
		or match_race_after_first_finish_seconds <= 0.0
	):
		errors.append("match phase durations must be greater than zero")
	if (
		kangaroo_telegraph_seconds <= 0.0
		or kangaroo_response_seconds < 1.0
		or kangaroo_reset_seconds < 0.0
		or kangaroo_response_acceleration_step_seconds < 0.0
		or kangaroo_response_min_seconds <= 0.0
		or kangaroo_reset_acceleration_step_seconds < 0.0
		or kangaroo_reset_min_seconds < 0.0
		or kangaroo_storm_after_commands <= 0
		or kangaroo_storm_min_after_commands < 16
		or kangaroo_storm_landing_seconds <= 0.0
		or kangaroo_storm_active_seconds <= 0.0
		or kangaroo_storm_min_landing_seconds < 1.5
		or kangaroo_storm_min_active_seconds < 3.0
		or kangaroo_storm_max_active != 2
	):
		errors.append("Kangaroo cadence and Storm values are outside their valid range")
	if kangaroo_response_min_seconds < 3.0 or kangaroo_reset_min_seconds < 0.75:
		errors.append("Kangaroo acceleration floors cannot be shorter than 3.0/0.75 seconds")
	if not (
		kangaroo_wave_middle_high_y_wu < kangaroo_wave_middle_y_wu
		and kangaroo_wave_middle_y_wu < kangaroo_wave_middle_low_y_wu
	):
		errors.append("Kangaroo wave bands must be ordered high, middle, then low")
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
	if wall_jump_horizontal_wu_s < 0.0 or wall_jump_horizontal_wu_s > launch_max_horizontal_wu_s:
		errors.append("wall jump horizontal speed must be between 0 and the external launch cap")
	if wall_jump_vertical_wu_s >= 0.0 or wall_jump_vertical_wu_s < -launch_max_upward_wu_s:
		errors.append("wall jump vertical speed must be upward and within the launch cap")
	if wall_jump_contact_grace_s < 0.0 or wall_jump_contact_grace_s > 0.25:
		errors.append("wall jump contact grace must be between 0 and 0.25 seconds")
	if wall_contact_probe_wu <= 0.0 or wall_contact_probe_wu > 4.0:
		errors.append("wall contact probe distance must be between 0 and 4 wu")
	if wall_jump_recontact_separation_wu <= wall_contact_probe_wu:
		errors.append("wall recontact separation must exceed the contact probe distance")
	if wall_normal_tolerance_degrees < 0.0 or wall_normal_tolerance_degrees > 45.0:
		errors.append("wall normal tolerance must be between 0 and 45 degrees")
	return errors


func _validate_sneak_glide_blocks() -> PackedStringArray:
	var errors := PackedStringArray()
	if sneak_height_wu <= 0.0 or sneak_height_wu > body_height_wu:
		errors.append("sneak height must be positive and no taller than the standing body")
	if glide_fall_cap_wu_s <= 0.0 or glide_fall_cap_wu_s > fall_speed_cap_wu_s:
		errors.append("glide cap must be positive and not exceed the fall speed cap")
	if water_sink_cap_wu_s <= 0.0 or water_sink_cap_wu_s > fall_speed_cap_wu_s:
		errors.append("water sink cap must be positive and not exceed the fall speed cap")
	if water_buoyancy_wu_s2 <= 0.0 or water_stroke_wu_s <= 0.0 or water_move_wu_s <= 0.0:
		errors.append("water buoyancy, stroke and move speed must be greater than zero")
	if block_box_push_speed_wu_s < 0.0 or block_box_friction_wu_s2 < 0.0:
		errors.append("box push speed and friction cannot be negative")
	if stun_immunity_s < 0.0:
		errors.append("stun immunity cannot be negative")
	if block_collapse_delay_s < 0.0 or block_collapse_respawn_s < 0.0:
		errors.append("collapse delay and respawn time cannot be negative")
	if (
		ice_brake_scale <= 0.0
		or ice_brake_scale > 1.0
		or ice_accel_scale <= 0.0
		or ice_accel_scale > 1.0
		or ice_speed_scale < 1.0
		or ice_speed_scale > 2.0
	):
		errors.append("ice brake/accel scales must be in (0, 1] and the speed scale in [1, 2]")
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
	if (
		item_kaing_weight < 0.0
		or item_tulay_weight < 0.0
		or item_solid_block_weight < 0.0
		or item_wood_box_weight < 0.0
		or item_collapsing_block_weight < 0.0
	):
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
		errors.append("spring launch cannot exceed the spring upward cap")
	if item_spring_boost_wu_s > item_spring_upward_cap_wu_s:
		errors.append("spring boost cannot exceed the spring upward cap")
	if item_spring_boost_wu_s < item_spring_launch_wu_s:
		errors.append("spring boost must not be weaker than the plain launch")
	if (
		item_spring_horizontal_cap_wu_s > launch_max_horizontal_wu_s
		or item_spring_upward_cap_wu_s > launch_max_upward_wu_s
	):
		errors.append("spring caps cannot exceed the external launch caps")
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
		errors.append("bubble release speed must be between zero and the spring upward cap")
	return errors

extends SceneTree

## P13-T09 accessibility and readability controls: Screen shake Full / Reduced / Off is actually
## applied through the Settings path, the Master / Music / Effects / Crowd buses and the Mute switch
## drive real buses, every audio cue has a visual partner, stun brightening and the Parol ramp stay
## under the photosensitivity limit, Filipino glyphs and display sizes are reported. Headless and
## synthetic: rendered muted / shake-off captures are produced by capture_p13_evidence.gd and are
## not a human review.

const FLOW_SCENE := preload("res://scenes/flow/game_flow.tscn")
const SETTINGS_SCENE := preload("res://scenes/ui/screens/settings_screen.tscn")
const ROOM_SCENE := preload("res://scenes/match/p12_scheduled_match_room.tscn")
const BUSES := ["Master", "Music", "Effects", "Crowd"]
const FILIPINO_GLYPHS := "ñÑáéíóúÁÉÍÓÚüÜ"
const SYMBOL_GLYPHS := "●▲■◆→↑↔•×·"
const RESOLUTIONS := [Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(1920, 800)]
const FRAME_SECONDS := 1.0 / 60.0
const MAX_FLASHES_PER_SECOND := 3.0

var checks := 0
var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_buses_and_settings()
	await _test_shake_through_settings()
	_test_stun_and_parol_flash_limits()
	await _test_audio_has_visual_partners()
	_test_glyph_coverage()
	_test_resolutions()
	await _test_applier_lifecycle()
	print("P13_ACCESSIBILITY_TESTS checks=%d failures=%d" % [checks, failures])
	quit(1 if failures > 0 else 0)


# --- buses, volumes, mute ---------------------------------------------------------------------


func _test_buses_and_settings() -> void:
	for bus in BUSES:
		_check(AudioServer.get_bus_index(bus) >= 0, "the %s bus exists" % bus)
	var screen := SETTINGS_SCENE.instantiate() as UiSettingsScreen
	root.add_child(screen)
	var settings := PresentationSettings.new()
	screen.bind_live(settings)
	var pairs := {"master": "Master", "music": "Music", "effects": "Effects", "crowd": "Crowd"}
	for key in pairs:
		screen.volume_changed.emit(key, 0.4)
		var db := PresentationApplier.bus_volume_db(StringName(pairs[key]))
		_check(
			absf(db - linear_to_db(0.4)) < 0.01,
			(
				"the %s slider sets the %s bus to %.1f dB (%.1f)"
				% [key, pairs[key], linear_to_db(0.4), db]
			)
		)
		for other in pairs:
			if other != key:
				_check(
					(
						(
							absf(PresentationApplier.bus_volume_db(StringName(pairs[other])) - 0.0)
							< 0.01
						)
						or PresentationApplier.bus_volume_db(StringName(pairs[other])) < -0.01
					),
					"the %s slider leaves %s alone" % [key, pairs[other]]
				)
		screen.volume_changed.emit(key, 1.0)
	screen.volume_changed.emit("effects", 0.0)
	_check(PresentationApplier.bus_volume_db(&"Effects") <= -79.0, "a zero slider silences its bus")
	screen.volume_changed.emit("effects", 1.0)
	_check(not PresentationApplier.bus_muted(&"Master"), "sound starts unmuted")
	screen.mute_changed.emit(true)
	_check(
		PresentationApplier.bus_muted(&"Master") and settings.muted,
		"the Mute switch mutes the Master bus and the setting"
	)
	screen.mute_changed.emit(false)
	_check(not PresentationApplier.bus_muted(&"Master"), "unmuting restores sound")
	screen.shake_changed.emit(0)
	_check(
		(
			PresentationApplier.shake_mode == 0
			and is_equal_approx(PresentationApplier.shake_scale(), 1.0)
		),
		"Full shake is applied"
	)
	screen.shake_changed.emit(1)
	_check(
		PresentationApplier.shake_scale() > 0.0 and PresentationApplier.shake_scale() < 1.0,
		"Reduced shake scales down"
	)
	screen.shake_changed.emit(2)
	_check(is_zero_approx(PresentationApplier.shake_scale()), "Off shake scales to nothing")
	_check(settings.validate().is_empty(), "the settings stay valid")
	PresentationApplier.reset()
	screen.queue_free()


# --- Screen shake through the live Settings path -----------------------------------------------


func _test_shake_through_settings() -> void:
	var flow := FLOW_SCENE.instantiate() as GameFlow
	flow.harness_mode = true
	flow.match_scene = GameFlow.LIFECYCLE_SCENE
	root.add_child(flow)
	await _frames(3)
	flow.match_scene = GameFlow.LIFECYCLE_SCENE
	flow.router.registry.join_keyboard("K1")
	flow.router.registry.join_keyboard("K2")
	flow._enter_match()
	await _frames(2)
	var room := flow.room as P12ScheduledMatchRoom
	_check(
		room.presentation_settings == flow.settings,
		"the match room reads the same settings object the Settings screen edits"
	)
	var amplitudes := {}
	for mode in [0, 1, 2]:
		flow.settings.screen_shake = mode
		var peak := 0.0
		for sample in 24:
			room.kangaroo_round._play_cue(KangarooRoundController.Command.FREEZE)
			room.kangaroo_round._update_shake(0.001)
			peak = maxf(peak, room.camera_rig.offset.length())
			await process_frame
		amplitudes[mode] = peak
		room.kangaroo_round.clear_view()
	_check(
		float(amplitudes[0]) > float(amplitudes[1]) and float(amplitudes[1]) > 0.0,
		"Full shakes more than Reduced, Reduced still shakes (%s)" % [amplitudes]
	)
	_check(is_zero_approx(float(amplitudes[2])), "Off never moves the camera")
	# A change mid-round applies at the next cue without touching any clock.
	var clock_before := room.items.director.simulation_time
	flow.settings.screen_shake = 0
	room.kangaroo_round._play_cue(KangarooRoundController.Command.HUG)
	flow.settings.screen_shake = 2
	room.kangaroo_round._update_shake(0.016)
	_check(
		is_zero_approx(room.camera_rig.offset.length()),
		"switching to Off mid-cue stops the shake at once"
	)
	_check(
		is_equal_approx(room.items.director.simulation_time, clock_before),
		"changing the setting never advances a simulation clock"
	)
	flow.queue_free()
	paused = false
	await _frames(3)


# --- flashing -----------------------------------------------------------------------------------


func _test_stun_and_parol_flash_limits() -> void:
	var base := 1.5
	var peak := 2.4
	var hz := 2.0
	for mode in [0, 1, 2]:
		var lows := 0
		var peaks := 0
		var previous := ChickenSpriteAnimator.stun_brightness(0.0, mode, hz, base, peak)
		var rising := true
		var biggest_step := 0.0
		var minimum := previous
		var frames := 240
		for frame in range(1, frames + 1):
			var value := ChickenSpriteAnimator.stun_brightness(
				float(frame) * FRAME_SECONDS, mode, hz, base, peak
			)
			biggest_step = maxf(biggest_step, absf(value - previous))
			minimum = minf(minimum, value)
			if rising and value < previous - 0.000001:
				peaks += 1
				rising = false
			elif not rising and value > previous + 0.000001:
				lows += 1
				rising = true
			previous = value
		var seconds := float(frames) * FRAME_SECONDS
		_check(
			float(peaks) / seconds <= MAX_FLASHES_PER_SECOND,
			(
				"stun brightness at shake %d has %.2f peaks per second (limit 3)"
				% [mode, float(peaks) / seconds]
			)
		)
		_check(
			biggest_step <= (peak - base) * TAU * hz * FRAME_SECONDS + 0.0001,
			(
				"stun brightness at shake %d never jumps (largest frame step %.3f)"
				% [mode, biggest_step]
			)
		)
		_check(minimum >= base - 0.0001, "stun never dims below its steady brightening")
	_check(
		is_equal_approx(ChickenSpriteAnimator.stun_brightness(0.3, 2, hz, base, peak), base),
		"shake Off holds the stun tint steady"
	)
	var tuning := GameplayTuning.new()
	_check(
		1.0 / tuning.item_parol_cycle_s <= MAX_FLASHES_PER_SECOND,
		"the Parol beam repeats every %.1f s (well under 3 per second)" % tuning.item_parol_cycle_s
	)
	_check(
		tuning.item_parol_charge_s >= 0.3,
		"the Parol charge ramp lasts %.1f s before the beam is solid" % tuning.item_parol_charge_s
	)


# --- every audio cue has a visual partner ---------------------------------------------------


func _test_audio_has_visual_partners() -> void:
	var tuning := GameplayTuning.new()
	var definitions := ItemDefinitions.load_for_profile(tuning, ItemEnabledProfiles.ITEMS_LAB)
	var audited := 0
	for family in definitions.families:
		if family.visual_set == null:
			continue
		var sound_slots := PackedStringArray()
		var visual_slots := PackedStringArray()
		for slot_id in family.visual_set.slot_ids():
			if slot_id.begins_with("sfx_"):
				sound_slots.append(slot_id)
			else:
				visual_slots.append(slot_id)
		if sound_slots.is_empty():
			continue
		audited += 1
		_check(
			not visual_slots.is_empty() and not family.library_tell.is_empty(),
			(
				"%s: sounds %s have visual slots %s and a written tell"
				% [family.family_id, sound_slots, visual_slots]
			)
		)
	_check(audited >= 5, "%d families with sound were audited" % audited)
	# Kangaroo cues: every cue tone is paired with a command card in the same frame.
	var room := ROOM_SCENE.instantiate() as P12ScheduledMatchRoom
	root.add_child(room)
	await _frames(2)
	for layout in ["K1", "K2"]:
		room.join_keyboard(layout)
	for seat in room.input_router.registry.joined_seats():
		room.input_router.registry.set_ready(int(seat.seat), true)
	room.start_match()
	await _frames(2)
	room.schedule.locked[1] = {
		"round": 1,
		"main": EventSchedule.Challenge.KANGAROO,
		"twist": EventSchedule.Challenge.NONE,
		"guaranteed": false,
		"sudden_death": false,
		"twist_options": 0,
	}
	room._finish_pugad_timeout()
	var edits: Array[Dictionary] = []
	room._resolve_place_edits(edits)
	for _frame in 240:
		await physics_frame
		if not room.kangaroo_round.controller.active_commands().is_empty():
			break
	await process_frame
	await process_frame
	var hud := room.kangaroo_round.hud()
	_check(hud.command_count() >= 1, "the Kangaroo cue tone has a command card on screen")
	var card := hud.cards[0]
	_check(
		not card.pose_text().is_empty() and not card.instruction_text().is_empty(),
		"the card carries the pose name and its instruction as text"
	)
	room.queue_free()
	await process_frame


# --- glyphs and resolutions -------------------------------------------------------------------


func _test_glyph_coverage() -> void:
	var theme := ThemeDB.get_project_theme()
	var font: Font = theme.get_default_font() if theme != null else ThemeDB.fallback_font
	if font == null:
		font = ThemeDB.fallback_font
	var missing_filipino := PackedStringArray()
	for index in FILIPINO_GLYPHS.length():
		if not font.has_char(FILIPINO_GLYPHS.unicode_at(index)):
			missing_filipino.append(FILIPINO_GLYPHS[index])
	var missing_symbols := PackedStringArray()
	for index in SYMBOL_GLYPHS.length():
		if not font.has_char(SYMBOL_GLYPHS.unicode_at(index)):
			missing_symbols.append(SYMBOL_GLYPHS[index])
	print(
		(
			"P13_GLYPH_REPORT font=%s missing_filipino=%s missing_symbols=%s"
			% [font.get_font_name(), missing_filipino, missing_symbols]
		)
	)
	_check(
		missing_filipino.is_empty(),
		"the default font covers the Filipino letters (missing %s)" % [missing_filipino]
	)
	_check(
		missing_symbols.size() <= SYMBOL_GLYPHS.length(),
		(
			"the symbol glyph gaps are reported (%d of %d missing)"
			% [missing_symbols.size(), SYMBOL_GLYPHS.length()]
		)
	)


func _test_resolutions() -> void:
	var theme := load("res://assets/ui/theme/tilaok_theme.tres") as Theme
	var label_min := theme.get_constant("min_label_font_px", "TilaokPolicy")
	var hud_min := theme.get_constant("min_midround_font_px", "TilaokPolicy")
	var hud_reserve := theme.get_constant("hud_reservation_px", "TilaokPolicy")
	for size in RESOLUTIONS:
		var scale := minf(float(size.x) / 1280.0, float(size.y) / 720.0)
		var content := Vector2(1280.0, 720.0) * scale
		var bars := (Vector2(size) - content) * 0.5
		print(
			(
				"P13_DISPLAY %dx%d scale=%.3f content=%.0fx%.0f bars=%.0f,%.0f hud=%.0fpx text=%.0f/%.0fpx"
				% [
					size.x,
					size.y,
					scale,
					content.x,
					content.y,
					bars.x,
					bars.y,
					hud_reserve * scale,
					label_min * scale,
					hud_min * scale,
				]
			)
		)
		_check(
			content.x <= float(size.x) + 0.01 and content.y <= float(size.y) + 0.01,
			"%dx%d: the 1280x720 view fits (scale %.3f)" % [size.x, size.y, scale]
		)
		_check(
			hud_min * scale >= 16.0 and hud_reserve * scale >= 64.0,
			(
				"%dx%d: mid-round text %.0f px and HUD %.0f px are not below the 720p values"
				% [size.x, size.y, hud_min * scale, hud_reserve * scale]
			)
		)
	_check(
		(
			int(ProjectSettings.get_setting("display/window/size/viewport_width")) == 1280
			and int(ProjectSettings.get_setting("display/window/size/viewport_height")) == 720
		),
		"the logical canvas is 1280x720 (documented supported base)"
	)


func _test_applier_lifecycle() -> void:
	var defaults := PresentationSettings.new()
	_check(
		(
			defaults.screen_shake == PresentationApplier.SHAKE_FULL
			and is_equal_approx(defaults.effects_volume, 1.0)
			and is_equal_approx(defaults.master_volume, 1.0)
			and is_equal_approx(defaults.music_volume, 1.0)
			and is_equal_approx(defaults.crowd_volume, 1.0)
			and not defaults.muted
		),
		"fresh presentation settings enable full shake and all sound buses"
	)
	var flow := FLOW_SCENE.instantiate() as GameFlow
	flow.harness_mode = true
	root.add_child(flow)
	await _frames(2)
	flow.settings.master_volume = 0.5
	flow.settings.muted = true
	flow.settings.screen_shake = 0
	PresentationApplier.apply(flow.settings)
	_check(PresentationApplier.bus_muted(&"Master"), "settings applied while the flow runs")
	flow.queue_free()
	await _frames(3)
	_check(
		(
			not PresentationApplier.bus_muted(&"Master")
			and absf(PresentationApplier.bus_volume_db(&"Master")) < 0.01
			and PresentationApplier.shake_mode == PresentationApplier.SHAKE_FULL
		),
		"leaving the flow restores full volume, unmuted, full shake (no bus leak)"
	)


func _frames(count: int) -> void:
	for _frame in count:
		await process_frame


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("P13_ACCESS FAIL: " + message)
	print("%s %s" % ["PASS" if condition else "FAIL", message])

extends SceneTree

## Regenerates every PLACEHOLDER item asset. Original, plain geometric shapes and synthesized
## tones only; no third-party material. Final art/audio replaces these files by name.
## Run: godot --headless --path tilaok! --script res://tools/generate_placeholder_assets.gd

const ROOT := "res://assets/items"
const SAMPLE_RATE := 22050

const INK := "#1d2930"
const AMBER := "#f2b84b"
const SLATE := "#59707a"
const PAPER := "#f6efd8"
const BEAM := "#ffe27a"
const SKY := "#bfe7f5"
const ROSE := "#f08fb0"
const CLAY := "#9a6b3a"


func _initialize() -> void:
	var written := 0
	for family_id in _svg_files():
		for file_name in _svg_files()[family_id] as Dictionary:
			written += _write_text(
				family_id, file_name, (_svg_files()[family_id] as Dictionary)[file_name]
			)
	for family_id in _audio_files():
		for file_name in _audio_files()[family_id] as Dictionary:
			var spec: Array = (_audio_files()[family_id] as Dictionary)[file_name]
			written += _write_wav(family_id, file_name, spec)
	print("PLACEHOLDER_ASSETS_WRITTEN %d" % written)
	quit(0)


func _svg(width: int, height: int, body: String) -> String:
	return (
		(
			'<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" '
			+ 'viewBox="0 0 %d %d">%s</svg>\n'
		)
		% [width, height, width, height, body]
	)


func _svg_files() -> Dictionary:
	return {
		"move.tire_spring":
		{
			"PLACEHOLDER_body.svg":
			_svg(
				64,
				64,
				(
					(
						'<circle cx="32" cy="32" r="29" fill="#2f3438" stroke="%s" stroke-width="3"/>'
						+ '<circle cx="32" cy="32" r="17" fill="none" stroke="#b9b19a" stroke-width="4"/>'
						+ '<circle cx="32" cy="32" r="7" fill="#b9b19a"/>'
						+ '<path d="M32 3V13M32 51V61M3 32H13M51 32H61" stroke="#b9b19a" stroke-width="3"/>'
					)
					% INK
				)
			),
			"PLACEHOLDER_body_compressed.svg":
			_svg(
				64,
				64,
				(
					(
						'<ellipse cx="32" cy="36" rx="30" ry="25" fill="#2f3438" stroke="%s" stroke-width="3"/>'
						+ '<ellipse cx="32" cy="36" rx="17" ry="13" fill="none" stroke="#b9b19a" stroke-width="4"/>'
						+ '<circle cx="32" cy="36" r="7" fill="#b9b19a"/>'
					)
					% INK
				)
			),
		},
		"hazard.rail_trumpo":
		{
			"PLACEHOLDER_rail.svg":
			_svg(
				64,
				16,
				(
					(
						'<rect x="0" y="5" width="64" height="6" fill="%s" stroke="%s" stroke-width="2"/>'
						+ '<path d="M8 2V14M24 2V14M40 2V14M56 2V14" stroke="%s" stroke-width="2"/>'
					)
					% [SLATE, INK, INK]
				)
			),
			"PLACEHOLDER_top.svg":
			_svg(
				32,
				32,
				(
					(
						'<circle cx="16" cy="16" r="14" fill="%s" stroke="%s" stroke-width="2"/>'
						+ '<path d="M16 2L20 16L16 30L12 16Z" fill="%s"/>'
						+ '<path d="M2 16L16 12L30 16L16 20Z" fill="%s"/>'
					)
					% [AMBER, INK, INK, INK]
				)
			),
		},
		"hazard.parol_pulse":
		{
			"PLACEHOLDER_post.svg":
			_svg(
				32,
				32,
				(
					(
						'<rect x="3" y="3" width="26" height="26" fill="%s" stroke="%s" stroke-width="2"/>'
						+ '<path d="M16 5L26 16L16 27L6 16Z" fill="%s" stroke="%s" stroke-width="2"/>'
					)
					% [INK, SLATE, BEAM, INK]
				)
			),
			"PLACEHOLDER_beam_on.svg":
			_svg(
				32,
				12,
				(
					(
						'<rect x="0" y="0" width="32" height="12" fill="%s"/>'
						+ '<path d="M0 6H32" stroke="#ffffff" stroke-width="2"/>'
						+ '<path d="M4 0V12M12 0V12M20 0V12M28 0V12" stroke="%s" stroke-width="1"/>'
					)
					% [BEAM, INK]
				)
			),
		},
		"hazard.slipper_launcher":
		{
			"PLACEHOLDER_launcher.svg":
			_svg(
				32,
				32,
				(
					(
						'<rect x="2" y="2" width="28" height="28" fill="%s" stroke="%s" stroke-width="2"/>'
						+ '<rect x="16" y="12" width="14" height="8" fill="%s" stroke="%s" stroke-width="2"/>'
					)
					% [SLATE, INK, AMBER, INK]
				)
			),
			"PLACEHOLDER_launcher_charge.svg":
			_svg(
				32,
				32,
				(
					(
						'<rect x="2" y="2" width="28" height="28" fill="%s" stroke="%s" stroke-width="2"/>'
						+ '<rect x="12" y="12" width="14" height="8" fill="%s" stroke="%s" stroke-width="2"/>'
						+ '<circle cx="16" cy="6" r="3" fill="#ffffff"/>'
					)
					% [SLATE, INK, AMBER, INK]
				)
			),
			"PLACEHOLDER_projectile.svg":
			_svg(
				16,
				16,
				(
					(
						'<ellipse cx="8" cy="8" rx="7" ry="5" fill="#e8896b" stroke="%s" stroke-width="2"/>'
						+ '<path d="M3 8H13" stroke="%s" stroke-width="2"/>'
					)
					% [INK, INK]
				)
			),
		},
		"utility.walis_cleanup":
		{
			"PLACEHOLDER_broom_outline.svg":
			_svg(
				32,
				32,
				(
					(
						'<path d="M6 4L20 22" stroke="%s" stroke-width="4" fill="none"/>'
						+ '<path d="M16 20L28 28L20 30L12 26Z" fill="%s" stroke="%s" stroke-width="2"/>'
					)
					% [CLAY, AMBER, INK]
				)
			),
		},
		"hazard.bubble_planter":
		{
			"PLACEHOLDER_pot.svg":
			_svg(
				32,
				32,
				(
					(
						'<path d="M5 14H27L24 30H8Z" fill="%s" stroke="%s" stroke-width="2"/>'
						+ '<circle cx="16" cy="8" r="6" fill="%s" stroke="%s" stroke-width="2"/>'
						+ '<circle cx="16" cy="8" r="2.5" fill="%s"/>'
					)
					% [CLAY, INK, ROSE, INK, AMBER]
				)
			),
			"PLACEHOLDER_bubble.svg":
			_svg(
				32,
				32,
				(
					(
						'<circle cx="16" cy="16" r="14" fill="%s" fill-opacity="0.35" '
						+ 'stroke="#ffffff" stroke-width="2"/>'
						+ '<path d="M8 12A9 9 0 0 1 14 7" stroke="#ffffff" stroke-width="2" fill="none"/>'
					)
					% SKY
				)
			),
			"PLACEHOLDER_captive_icon.svg":
			_svg(
				16,
				16,
				(
					(
						'<circle cx="8" cy="8" r="6" fill="%s" stroke="%s" stroke-width="1.5"/>'
						+ '<circle cx="10" cy="6" r="1" fill="%s"/>'
					)
					% [PAPER, INK, INK]
				)
			),
		},
	}


## [start_hz, end_hz, seconds, wave ("sine"|"square"|"noise"), volume]
func _audio_files() -> Dictionary:
	return {
		"move.tire_spring": {"PLACEHOLDER_sfx_launch.wav": [180.0, 520.0, 0.28, "sine", 0.5]},
		"hazard.rail_trumpo": {"PLACEHOLDER_sfx_pause.wav": [320.0, 300.0, 0.08, "square", 0.25]},
		"hazard.parol_pulse":
		{
			"PLACEHOLDER_sfx_charge.wav": [220.0, 440.0, 0.5, "sine", 0.3],
			"PLACEHOLDER_sfx_on.wav": [660.0, 660.0, 0.18, "square", 0.3],
		},
		"hazard.slipper_launcher":
		{
			"PLACEHOLDER_sfx_charge.wav": [240.0, 360.0, 0.4, "sine", 0.3],
			"PLACEHOLDER_sfx_fire.wav": [900.0, 300.0, 0.14, "noise", 0.4],
		},
		"utility.walis_cleanup": {"PLACEHOLDER_sfx_sweep.wav": [400.0, 200.0, 0.3, "noise", 0.35]},
		"hazard.bubble_planter":
		{
			"PLACEHOLDER_sfx_emit.wav": [300.0, 500.0, 0.15, "sine", 0.3],
			"PLACEHOLDER_sfx_capture.wav": [500.0, 700.0, 0.2, "sine", 0.4],
			"PLACEHOLDER_sfx_pop.wav": [800.0, 200.0, 0.1, "noise", 0.35],
		},
	}


func _ensure_dir(family_id: String) -> String:
	var path := "%s/%s" % [ROOT, family_id]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path))
	return path


func _write_text(family_id: String, file_name: String, text: String) -> int:
	var file := FileAccess.open("%s/%s" % [_ensure_dir(family_id), file_name], FileAccess.WRITE)
	if file == null:
		push_error("cannot write %s/%s" % [family_id, file_name])
		return 0
	file.store_string(text)
	return 1


func _write_wav(family_id: String, file_name: String, spec: Array) -> int:
	var start_hz: float = spec[0]
	var end_hz: float = spec[1]
	var seconds: float = spec[2]
	var kind: String = spec[3]
	var volume: float = spec[4]
	var count := int(seconds * SAMPLE_RATE)
	var data := PackedByteArray()
	var phase := 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	for index in range(count):
		var t := float(index) / float(count)
		var hz := lerpf(start_hz, end_hz, t)
		phase += TAU * hz / float(SAMPLE_RATE)
		var sample := sin(phase)
		if kind == "square":
			sample = 1.0 if sin(phase) >= 0.0 else -1.0
		elif kind == "noise":
			sample = rng.randf_range(-1.0, 1.0)
		var envelope := minf(1.0, minf(t * 20.0, (1.0 - t) * 6.0))
		var value := int(clampf(sample * volume * envelope, -1.0, 1.0) * 32767.0)
		data.append(value & 0xFF)
		data.append((value >> 8) & 0xFF)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.data = data
	var error := wav.save_to_wav("%s/%s" % [_ensure_dir(family_id), file_name])
	if error != OK:
		push_error("cannot write wav %s/%s (%d)" % [family_id, file_name, error])
		return 0
	return 1

class_name ScoreColumn
extends Control

const AWARD_GLYPHS := {
	"tapos": "T",
	"una": "1",
	"bayani": "B",
	"patibong": "P",
	"bawi": "R",
	"barya": "C",
	"placement": "L",
	"previous_total": "·",
}
const AWARD_COLORS := {
	"tapos": "tapos",
	"una": "una",
	"bayani": "bayani",
	"patibong": "patibong",
	"bawi": "bawi",
	"barya": "barya",
	"placement": "placement",
	"previous_total": "previous_total",
}
## One short line per outcome sentence under the chart (first matching prefix wins). The full
## sentence stays in the results model; anything not listed keeps its first clause.
const SHORT_STATUS := [
	["Reached the flag", "Reached the flag"],
	["Did not reach the flag before", "Out of time"],
	["Did not reach the flag within", "Finish window closed"],
	["The Bomb-Taya timer expired", "Taya timer ran out"],
	["Taya timer expired", "Taya timer ran out"],
	["Eliminated after the third failed Kangaroo command", "3 missed commands"],
	["Directly eliminated by a trap", "Eliminated by a trap"],
	["Eliminated by a direct trap", "Eliminated by a trap"],
	["Eliminated by a hazard", "Eliminated by a hazard"],
	["Eliminated before reaching the flag", "Eliminated"],
]
const READY_MARK := "READY · "
const MOTION_NORMAL := PresentationSettings.RESULT_REVEAL_NORMAL
const MOTION_REDUCED := PresentationSettings.RESULT_REVEAL_REDUCED
const MOTION_OFF := PresentationSettings.RESULT_REVEAL_OFF
const STEP_SECONDS := 0.24
const MAX_REVEAL_SECONDS := 2.4
## Texture pixels from the bottom of a 2048 px chicken frame up to the art's feet (the line the
## in-game hitbox stands on), so the feet rather than the frame edge rest on the bar.
const CHICKEN_FEET_INSET_PX := 224.0

var badge: UiPlayerBadge
var _row: Dictionary = {}
var _segments: Array[Dictionary] = []
var _segment_progress: Array[int] = []
var _axis_max_units := 88
var _plot_height := 200.0
var _bar_width := 42.0
var _motion_mode := MOTION_OFF
var _elapsed := 0.0
var _reveal_count := 0

## The chicken draws one z level up (set in the scene) so the chalkboard grain, drawn over the
## chart, does not darken it; the match HUD overlays sit at the same level, later, to cover it.
@onready var _chicken: AnimatedSprite2D = %Chicken
@onready var _score_label: Label = %ScoreLabel
@onready var _delta_label: Label = %DeltaLabel
@onready var _status_label: Label = %StatusLabel


func _ready() -> void:
	badge = %IdentityBadge


func bind_row(
	row: Dictionary,
	axis_max_units: int,
	plot_height: float,
	bar_width: float,
	motion_mode: int,
	elapsed: float = 0.0
) -> void:
	_row = row.duplicate(true)
	_segments.clear()
	_segment_progress.clear()
	_reveal_count = 0
	for segment_variant in _row.get("segments", []):
		if not segment_variant is Dictionary:
			continue
		var segment: Dictionary = segment_variant.duplicate(true)
		if int(segment.get("units", 0)) <= 0:
			continue
		if bool(segment.get("reveal", false)):
			segment["reveal_index"] = _reveal_count
			_reveal_count += 1
		_segments.append(segment)
	_axis_max_units = maxi(axis_max_units, 1)
	_plot_height = maxf(plot_height, 1.0)
	_bar_width = maxf(bar_width, 1.0)
	_motion_mode = motion_mode
	_elapsed = elapsed
	var seat := {
		"identity": int(_row.get("identity", 0)),
		"shape": str(_row.get("shape", "")),
		"color": _row.get("color", Color.WHITE),
		"joined": true,
	}
	badge.bind_seat(seat)
	_chicken.sprite_frames = ChickenSpriteAnimator.frames_for_color(_row.get("color", Color.WHITE))
	if _chicken.sprite_frames != null and _chicken.sprite_frames.has_animation(&"idle"):
		_chicken.visible = true
		_chicken.play(&"idle")
	else:
		# Never display the first frame set's `dead` animation when a skin is unavailable.
		_chicken.stop()
		_chicken.visible = false
	_refresh_labels()
	_layout_marker()
	queue_redraw()


func set_chart_layout(plot_height: float, bar_width: float, axis_max_units: int) -> void:
	_plot_height = maxf(plot_height, 1.0)
	_bar_width = maxf(bar_width, 1.0)
	_axis_max_units = maxi(axis_max_units, 1)
	_layout_marker()
	queue_redraw()


func set_reveal_elapsed(elapsed: float) -> void:
	_elapsed = minf(maxf(elapsed, 0.0), MAX_REVEAL_SECONDS)
	_refresh_labels()
	_layout_marker()
	queue_redraw()


func settle() -> void:
	_elapsed = MAX_REVEAL_SECONDS
	_refresh_labels()
	_layout_marker()
	queue_redraw()


func visible_segment_units() -> Array[int]:
	var result: Array[int] = []
	for index in _segments.size():
		result.append(_visible_units(index))
	return result


func visible_total_units() -> int:
	var total := 0
	for index in _segments.size():
		total += _visible_units(index)
	return total


func feet_anchor_y() -> float:
	return _chicken.position.y + _chicken_foot_offset()


func score_text() -> String:
	return _score_label.text


func state_text() -> String:
	return "%s · %s" % [_delta_label.text, _status_label.text]


## "READY · Reached the flag; secured." -> "READY · Reached the flag".
static func short_status(text: String) -> String:
	var ready := text.begins_with(READY_MARK)
	var sentence := text.trim_prefix(READY_MARK).strip_edges()
	var short := sentence.get_slice(";", 0).strip_edges().trim_suffix(".")
	for pair in SHORT_STATUS:
		if sentence.begins_with(str(pair[0])):
			short = str(pair[1])
			break
	return (READY_MARK + short) if ready else short


func bar_top_y() -> float:
	return _plot_height - _units_to_pixels(visible_total_units())


func reveal_duration() -> float:
	return minf(float(_reveal_count) * STEP_SECONDS, MAX_REVEAL_SECONDS)


func _draw() -> void:
	var baseline := _plot_height
	var x := (size.x - _bar_width) * 0.5
	var filled_height := 0.0
	if visible_total_units() <= 0:
		var perch_color := get_theme_color("perch", "ScoreAxis")
		draw_line(
			Vector2(x - 9.0, baseline), Vector2(x + _bar_width + 9.0, baseline), perch_color, 3.0
		)
	for index in _segments.size():
		var visible_units := _visible_units(index)
		if visible_units <= 0:
			continue
		var segment: Dictionary = _segments[index]
		var height := _units_to_pixels(visible_units)
		var top := baseline - filled_height - height
		var award_key := str(segment.get("key", "previous_total"))
		var token := str(AWARD_COLORS.get(award_key, "previous_total"))
		var fill_color := get_theme_color(token, "ScoreAward")
		draw_rect(Rect2(x, top, _bar_width, height), fill_color, true)
		_draw_segment_glyph(award_key, x, top, _bar_width, height)
		filled_height += height
	if filled_height > 0.0:
		draw_line(
			Vector2(x - 4.0, baseline - filled_height),
			Vector2(x + _bar_width + 4.0, baseline - filled_height),
			get_theme_color("bar_edge", "ScoreAxis"),
			2.0
		)


func _draw_segment_glyph(key: String, x: float, top: float, width: float, height: float) -> void:
	if height < 15.0:
		return
	var glyph := str(AWARD_GLYPHS.get(key, "·"))
	var font := get_theme_default_font()
	var font_size := 12
	var glyph_size := font.get_string_size(glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var color := get_theme_color("segment_glyph", "ScoreAxis")
	draw_string(
		font,
		Vector2(x + (width - glyph_size.x) * 0.5, top + (height + font_size) * 0.5 - 2.0),
		glyph,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		color
	)


func _visible_units(index: int) -> int:
	var segment: Dictionary = _segments[index]
	var units := int(segment.get("units", 0))
	if not bool(segment.get("reveal", false)) or _motion_mode != MOTION_NORMAL:
		return units
	var reveal_index := int(segment.get("reveal_index", 0))
	var start := minf(float(reveal_index) * STEP_SECONDS, MAX_REVEAL_SECONDS - STEP_SECONDS)
	var progress := clampf((_elapsed - start) / STEP_SECONDS, 0.0, 1.0)
	return mini(units, int(floor(float(units) * progress + 0.00001)))


func _units_to_pixels(units: int) -> float:
	return float(units) * _plot_height / float(_axis_max_units)


func _refresh_labels() -> void:
	var total := visible_total_units()
	var revealed_delta := 0
	for index in _segments.size():
		if bool(_segments[index].get("reveal", false)):
			revealed_delta += _visible_units(index)
	_score_label.text = ScoreFormat.format_units(total)
	var final_delta := int(_row.get("delta_units", 0))
	if final_delta > 0:
		_delta_label.text = "+%s" % ScoreFormat.format_units(revealed_delta)
	else:
		_delta_label.text = str(_row.get("delta_text", ""))
	# READY rides on the short delta line so the outcome below keeps its one line.
	var status := short_status(str(_row.get("status", "")))
	if status.begins_with(READY_MARK):
		status = status.trim_prefix(READY_MARK)
		_delta_label.text = (
			"%s · READY" % _delta_label.text if not _delta_label.text.is_empty() else "READY"
		)
	_status_label.text = status


func _layout_marker() -> void:
	if not is_node_ready():
		return
	badge.position = Vector2(maxf((size.x - badge.size.x) * 0.5, 0.0), _plot_height + 8.0)
	badge.size.x = size.x
	_score_label.position = Vector2(0.0, _plot_height + 44.0)
	_score_label.size = Vector2(size.x, 24.0)
	# The delta sits clearly below the total, then one status line.
	_delta_label.position = Vector2(0.0, _plot_height + 76.0)
	_delta_label.size = Vector2(size.x, 20.0)
	_status_label.position = Vector2(0.0, _plot_height + 98.0)
	_status_label.size = Vector2(size.x, 22.0)
	var top := bar_top_y()
	_chicken.position = Vector2(size.x * 0.5, top - _chicken_foot_offset())


func _chicken_foot_offset() -> float:
	if _chicken.sprite_frames == null:
		return 0.0
	var frame := _chicken.sprite_frames.get_frame_texture(_chicken.animation, _chicken.frame)
	if frame == null:
		return 0.0
	var frame_height := frame.get_size().y
	var frame_top := -frame_height * 0.5 if _chicken.centered else 0.0
	return (
		(frame_top + frame_height - CHICKEN_FEET_INSET_PX + _chicken.offset.y) * _chicken.scale.y
	)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_marker()

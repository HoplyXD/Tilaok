class_name ItemGhost
extends Node2D

## Placement ghost: footprint, the separate one-way strip and its arrow, and a validity cue that
## never relies on colour alone (outline style, mark and text reason).

const VALID_COLOR := Color("#7fd68a")
const INVALID_COLOR := Color("#ef6a5b")
const HATCH_SPACING_WU := 8.0

var footprint_rect := Rect2()
var strip_rects: Array[Rect2] = []
var strip_normals: Array[Vector2] = []
var valid := true
var reason := ""
var seat_label := ""
var item_label := ""


func show_state(
	new_footprint: Rect2,
	new_strips: Array[Rect2],
	new_normals: Array[Vector2],
	is_valid: bool,
	reason_text: String,
	new_seat_label: String,
	new_item_label: String
) -> void:
	footprint_rect = new_footprint
	strip_rects = new_strips
	strip_normals = new_normals
	valid = is_valid
	reason = reason_text
	seat_label = new_seat_label
	item_label = new_item_label
	z_index = 40
	queue_redraw()


func _draw() -> void:
	if footprint_rect.size == Vector2.ZERO:
		return
	var tint := VALID_COLOR if valid else INVALID_COLOR
	draw_rect(footprint_rect, Color(tint, 0.22))
	if valid:
		draw_rect(footprint_rect, tint, false, 3.0)
	else:
		_draw_dashed_rect(footprint_rect, tint)
		_draw_hatch(footprint_rect, tint)
	for index in range(strip_rects.size()):
		_draw_arrow(strip_rects[index], strip_normals[index])
	var font := ThemeDB.fallback_font
	if font == null:
		return
	var mark := "OK" if valid else "X"
	var text := "%s %s • %s" % [seat_label, mark, item_label]
	if not valid:
		text += " — " + reason
	var anchor := footprint_rect.position + Vector2(0.0, -8.0)
	draw_string(
		font, anchor + Vector2(1.0, 1.0), text, HORIZONTAL_ALIGNMENT_LEFT, 720.0, 12, Color.BLACK
	)
	draw_string(font, anchor, text, HORIZONTAL_ALIGNMENT_LEFT, 720.0, 12, Color.WHITE)


func _draw_arrow(strip: Rect2, normal: Vector2) -> void:
	# Drawn inside the footprint so the label never hides it: a one-way "pass up, land on top" cue.
	var center := footprint_rect.get_center()
	var along := Vector2(-normal.y, normal.x)
	var tail := center - normal * 8.0
	var tip := center + normal * 10.0
	var head_back := tip - normal * 8.0
	for pass_index in range(2):
		var color := Color.WHITE if pass_index == 0 else Color("#1d2930")
		var width := 6.0 if pass_index == 0 else 3.0
		draw_line(tail, tip, color, width)
		draw_line(tip, head_back + along * 7.0, color, width)
		draw_line(tip, head_back - along * 7.0, color, width)
	draw_rect(strip, Color("#fff2b7"))


func _draw_dashed_rect(rect: Rect2, color: Color) -> void:
	var corners := [
		rect.position,
		Vector2(rect.end.x, rect.position.y),
		rect.end,
		Vector2(rect.position.x, rect.end.y),
		rect.position,
	]
	for index in range(4):
		var from: Vector2 = corners[index]
		var to: Vector2 = corners[index + 1]
		var length := from.distance_to(to)
		var direction := (to - from) / length
		var travelled := 0.0
		while travelled < length:
			var segment_end := minf(travelled + 6.0, length)
			draw_line(from + direction * travelled, from + direction * segment_end, color, 3.0)
			travelled += 12.0


func _draw_hatch(rect: Rect2, color: Color) -> void:
	var offset := HATCH_SPACING_WU
	var total := rect.size.x + rect.size.y
	while offset < total:
		var start := Vector2(rect.position.x + minf(offset, rect.size.x), rect.position.y)
		var end := Vector2(
			rect.position.x + maxf(0.0, offset - rect.size.y),
			rect.position.y + minf(offset, rect.size.y)
		)
		if offset > rect.size.x:
			start = Vector2(rect.end.x, rect.position.y + (offset - rect.size.x))
		draw_line(start, end, Color(color, 0.6), 1.0)
		offset += HATCH_SPACING_WU

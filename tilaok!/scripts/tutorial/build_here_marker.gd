class_name BuildHereMarker
extends Node2D

## World-space BUILD HERE zone shown during the tutorial Place step. It is a dashed outline plus an
## arrow glyph plus a text label, so it never relies on colour alone. Pure presentation: it has no
## collision and takes no part in placement validation.

const OUTLINE_WIDTH := 6.0
const DASH_WU := 24.0
const ARROW_WU := 56.0
const ARROW_GAP_WU := 12.0
const FILL_ALPHA := 0.16
const OUTLINE_COLOR := Color("#ffe27a")

var zone := Rect2()
var emphasised := false

@onready var _label: Label = %ZoneLabel
@onready var _hint: Label = %HintLabel


func configure(zone_rect: Rect2, emphasis: bool) -> void:
	zone = zone_rect
	emphasised = emphasis
	if is_node_ready():
		_layout_labels()
	queue_redraw()


func _ready() -> void:
	z_index = 5
	_layout_labels()
	queue_redraw()


func _layout_labels() -> void:
	_label.position = zone.position + Vector2(8.0, 4.0)
	_hint.visible = emphasised
	_hint.position = zone.position + Vector2(8.0, zone.size.y - 52.0)


func _draw() -> void:
	if zone.size == Vector2.ZERO:
		return
	draw_rect(zone, Color(OUTLINE_COLOR, FILL_ALPHA), true)
	var corners := [
		zone.position,
		Vector2(zone.end.x, zone.position.y),
		zone.end,
		Vector2(zone.position.x, zone.end.y),
	]
	for index in corners.size():
		var next_corner: Vector2 = corners[(index + 1) % corners.size()]
		draw_dashed_line(corners[index], next_corner, OUTLINE_COLOR, OUTLINE_WIDTH, DASH_WU)
	# Downward arrow above the zone: the shape cue that this is where to build.
	var tip := Vector2(zone.get_center().x, zone.position.y - ARROW_GAP_WU)
	draw_colored_polygon(
		PackedVector2Array(
			[
				tip,
				tip + Vector2(-ARROW_WU * 0.5, -ARROW_WU * 0.6),
				tip + Vector2(ARROW_WU * 0.5, -ARROW_WU * 0.6),
			]
		),
		OUTLINE_COLOR
	)

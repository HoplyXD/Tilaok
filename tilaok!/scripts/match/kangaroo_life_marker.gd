class_name KangarooLifeMarker
extends Node2D

## Screen-readable, actor-following KANG / GA / ROO strikes. Drawn in world space with scale
## compensated for the active camera zoom; this node is separate from the mirrored chicken art.

const SEGMENT_SIZE := Vector2(42.0, 22.0)
const GAP := 4.0
const LABELS := ["KANG", "GA", "ROO"]

var actor: ChickenController
var failure_count := 0
var body_height := 120.0
var camera: BoundedStageCamera
var overlap_lane := 0


func configure(
	source_actor: ChickenController,
	failures: int,
	height: float,
	source_camera: BoundedStageCamera,
	lane: int = 0
) -> void:
	actor = source_actor
	failure_count = clampi(failures, 0, 3)
	body_height = height
	camera = source_camera
	overlap_lane = lane
	set_process(true)
	queue_redraw()


func set_overlap_lane(lane: int) -> void:
	overlap_lane = lane


func _process(_delta: float) -> void:
	if actor == null or not is_instance_valid(actor):
		visible = false
		return
	visible = true
	global_position = (
		actor.global_position + Vector2(0.0, -body_height * 0.5 - 34.0 - overlap_lane * 28.0)
	)
	var zoom_value := camera.zoom.x if camera != null else 1.0
	global_scale = Vector2.ONE / maxf(zoom_value, 0.01)


func _draw() -> void:
	var width := SEGMENT_SIZE.x * 3.0 + GAP * 2.0
	var font := ThemeDB.fallback_font
	if font != null and actor != null:
		var identity := "P%d" % (actor.seat_index + 1)
		var identity_position := Vector2(-width * 0.5, -SEGMENT_SIZE.y * 0.5 - 3.0)
		draw_string_outline(
			font,
			identity_position,
			identity,
			HORIZONTAL_ALIGNMENT_CENTER,
			width,
			11,
			3,
			Color("#15242b")
		)
		draw_string(
			font, identity_position, identity, HORIZONTAL_ALIGNMENT_CENTER, width, 11, Color.WHITE
		)
	var origin := Vector2(-width * 0.5, -SEGMENT_SIZE.y * 0.5)
	for index in range(3):
		var rect := Rect2(origin + Vector2(index * (SEGMENT_SIZE.x + GAP), 0.0), SEGMENT_SIZE)
		var used := index < failure_count
		draw_rect(rect, Color("#852f37") if used else Color("#17242a"), true)
		draw_rect(rect, Color.WHITE, false, 2.0)
		var label_font := ThemeDB.fallback_font
		if label_font == null:
			continue
		var label_color := Color("#ffe0df") if used else Color("#f5f4e9")
		draw_string(
			label_font,
			rect.position + Vector2(4.0, 15.0),
			LABELS[index],
			HORIZONTAL_ALIGNMENT_CENTER,
			rect.size.x - 8.0,
			11,
			label_color
		)
		if used:
			draw_line(
				rect.position + Vector2(5.0, 5.0),
				rect.end - Vector2(5.0, 5.0),
				Color("#ffb5a8"),
				2.0
			)
			draw_line(
				Vector2(rect.end.x - 5.0, rect.position.y + 5.0),
				Vector2(rect.position.x + 5.0, rect.end.y - 5.0),
				Color("#ffb5a8"),
				2.0
			)

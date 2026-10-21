class_name NetworkPhoneHud
extends Control

## NLB-P10 phone identity and placement badge. "You are P#" is shown with the seat number, a seat
## shape and the seat colour, so colour is never the only identifier. The placement chip uses a
## shape prefix plus text (no flashing). Code-drawn placeholder: the final look is Shanti's design.

const SEAT_COLORS := [Color("#f2c14e"), Color("#63a7ff"), Color("#f07c6c"), Color("#89c77b")]
const SEAT_SHAPES := ["circle", "square", "triangle", "diamond"]
## PROPOSAL (UI_HANDOFF): at least 16 logical px mid-round, 12 px for non-critical labels.
const MIN_TEXT_PX := 16
const BADGE_SIZE := Vector2(236, 44)
const CHIP_SIZE := Vector2(236, 36)

var seat := -1
var placement_text := ""
var placement_shape := ""


static func shape_for_seat(seat_index: int) -> String:
	return SEAT_SHAPES[clampi(seat_index, 0, SEAT_SHAPES.size() - 1)]


static func color_for_seat(seat_index: int) -> Color:
	return SEAT_COLORS[clampi(seat_index, 0, SEAT_COLORS.size() - 1)]


static func badge_text(seat_index: int) -> String:
	return "You are P%d" % (seat_index + 1) if seat_index >= 0 else "Joining…"


## Short objective line for the current phase and event (display only).
static func objective_text(phase: int, event_id: int) -> String:
	if phase == MatchPhaseController.Phase.PUGAD:
		return "Pick an egg from the nest"
	if phase == MatchPhaseController.Phase.PLACE:
		return "Place your item"
	if phase == MatchPhaseController.Phase.PLAY or phase == MatchPhaseController.Phase.GO:
		match event_id:
			0:
				return "Reach the flag"
			1:
				return "Lagsanay: pass the tag"
			2:
				return "Kangaroo: stay on the stage"
		return "Play"
	return ""


## Shape prefix and text for the local ghost state; accepted/rejected never rely on colour.
static func placement_chip(state: int, label: String) -> Dictionary:
	match state:
		NetworkLivePlacementClient.GhostState.TENTATIVE:
			return {"shape": "square", "text": label}
		NetworkLivePlacementClient.GhostState.PENDING:
			return {"shape": "diamond", "text": label}
		NetworkLivePlacementClient.GhostState.ACCEPTED_AWAIT_TERRAIN:
			return {"shape": "circle", "text": label}
		NetworkLivePlacementClient.GhostState.REJECTED:
			return {"shape": "cross", "text": label}
	return {"shape": "", "text": ""}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(BADGE_SIZE.x, BADGE_SIZE.y + CHIP_SIZE.y + 6.0)
	size = custom_minimum_size


func set_seat(next_seat: int) -> void:
	if seat != next_seat:
		seat = next_seat
		queue_redraw()


func set_placement(state: int, label: String) -> void:
	var chip := placement_chip(state, label)
	if chip.shape != placement_shape or chip.text != placement_text:
		placement_shape = str(chip.shape)
		placement_text = str(chip.text)
		queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, BADGE_SIZE), Color(0.09, 0.14, 0.17, 0.85), true)
	draw_rect(Rect2(Vector2.ZERO, BADGE_SIZE), Color.WHITE, false, 3.0)
	if seat >= 0:
		_draw_shape(SEAT_SHAPES[clampi(seat, 0, SEAT_SHAPES.size() - 1)], Vector2(26, BADGE_SIZE.y * 0.5), 15.0, color_for_seat(seat), true)
		draw_string(font, Vector2(24 - 5, BADGE_SIZE.y * 0.5 + 6), str(seat + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#16232a"))
	draw_string(font, Vector2(52, BADGE_SIZE.y * 0.5 + 7), badge_text(seat), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
	if placement_text.is_empty():
		return
	var chip_rect := Rect2(Vector2(0, BADGE_SIZE.y + 6.0), CHIP_SIZE)
	draw_rect(chip_rect, Color(0.09, 0.14, 0.17, 0.85), true)
	draw_rect(chip_rect, Color.WHITE, false, 2.0)
	if placement_shape != "":
		_draw_shape(placement_shape, chip_rect.position + Vector2(18, CHIP_SIZE.y * 0.5), 9.0, Color.WHITE, false)
	draw_string(font, chip_rect.position + Vector2(36, CHIP_SIZE.y * 0.5 + 6), placement_text, HORIZONTAL_ALIGNMENT_LEFT, int(CHIP_SIZE.x) - 40, MIN_TEXT_PX, Color.WHITE)


func _draw_shape(shape: String, center: Vector2, radius: float, color: Color, filled: bool) -> void:
	var points := PackedVector2Array()
	match shape:
		"circle":
			if filled:
				draw_circle(center, radius, color)
			draw_arc(center, radius, 0.0, TAU, 24, Color.WHITE, 2.0)
			return
		"square":
			points = PackedVector2Array([center + Vector2(-radius, -radius), center + Vector2(radius, -radius), center + Vector2(radius, radius), center + Vector2(-radius, radius)])
		"triangle":
			points = PackedVector2Array([center + Vector2(0, -radius), center + Vector2(radius, radius), center + Vector2(-radius, radius)])
		"diamond":
			points = PackedVector2Array([center + Vector2(0, -radius), center + Vector2(radius, 0), center + Vector2(0, radius), center + Vector2(-radius, 0)])
		"cross":
			draw_line(center + Vector2(-radius, -radius), center + Vector2(radius, radius), color, 3.0)
			draw_line(center + Vector2(-radius, radius), center + Vector2(radius, -radius), color, 3.0)
			return
		_:
			return
	if filled:
		draw_colored_polygon(points, color)
	points.append(points[0])
	draw_polyline(points, Color.WHITE, 2.0)

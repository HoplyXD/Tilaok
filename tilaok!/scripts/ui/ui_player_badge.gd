class_name UiPlayerBadge
extends HBoxContainer

## Seat identity: number + shape always, colour supplementary. Designers may assign a texture to an
## Art_<Shape> slot; it replaces the placeholder polygon for that shape.

const SHAPE_NAMES := ["CIRCLE", "TRIANGLE", "SQUARE", "DIAMOND"]

var seat_number := 0
var shape_name := ""

@onready var _number_label: Label = %NumberLabel
@onready var _polygons: Dictionary = {
	"CIRCLE": %ShapeCircle,
	"TRIANGLE": %ShapeTriangle,
	"SQUARE": %ShapeSquare,
	"DIAMOND": %ShapeDiamond,
}
@onready var _art: Dictionary = {
	"CIRCLE": %Art_Circle,
	"TRIANGLE": %Art_Triangle,
	"SQUARE": %Art_Square,
	"DIAMOND": %Art_Diamond,
}


func bind_seat(seat: Dictionary) -> void:
	var joined := not seat.is_empty() and bool(seat.get("joined", false))
	seat_number = int(seat.get("identity", 0)) if joined else 0
	shape_name = str(seat.get("shape", "")) if joined else ""
	_number_label.text = str(seat_number) if joined else "-"
	var tint: Color = seat.get("color", Color.WHITE)
	for key in SHAPE_NAMES:
		var polygon := _polygons[key] as Polygon2D
		var art := _art[key] as TextureRect
		var active: bool = joined and key == shape_name
		var has_art := art.texture != null
		polygon.visible = active and not has_art
		polygon.color = tint
		art.visible = active and has_art
		art.modulate = tint


## Name of the shape currently visible (placeholder polygon or designer art), "" when empty.
func visible_shape() -> String:
	for key in SHAPE_NAMES:
		if (_polygons[key] as Polygon2D).visible or (_art[key] as TextureRect).visible:
			return key
	return ""


func number_text() -> String:
	return _number_label.text

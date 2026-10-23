class_name UiPlayerBadge
extends HBoxContainer

## Seat identity: number + shape always, colour supplementary. Designers may assign a texture to an
## Art_<Shape> slot; it replaces the placeholder polygon for that shape.

const SHAPE_NAMES := ["CIRCLE", "TRIANGLE", "SQUARE", "DIAMOND"]
const CHICKEN_HEAD_SHEET := preload("res://assets/character/Chicken Placeholder Sprite Sheet.png")
const CHICKEN_HEAD_REGION := Rect2(60.0, 16.0, 370.0, 255.0)

## Text before the number while a seat is joined ("P" reads "P1", "Player " reads "Player 1").
@export var prefix_text := ""
## Darkens the seat colour toward black so the shape stays readable on cream surfaces.
@export_range(0.0, 1.0) var tint_darken := 0.0
## False paints the shape plain_tint (for badges sitting on a seat-coloured pill).
@export var use_seat_tint := true
@export var plain_tint := Color(0.965, 0.906, 0.804, 1.0)
## Score chips can use the team's chicken head instead of a geometric seat mark.
@export var use_chicken_head := false
@export_range(0.5, 3.0, 0.1) var chicken_head_tint_strength := 2.1

var seat_number := 0
var shape_name := ""

@onready var _prefix_label: Label = %PrefixLabel
@onready var _number_label: Label = %NumberLabel
@onready var _chicken_head: TextureRect = %ChickenHeadIcon
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


func _ready() -> void:
	var head_texture := AtlasTexture.new()
	head_texture.atlas = CHICKEN_HEAD_SHEET
	head_texture.region = CHICKEN_HEAD_REGION
	_chicken_head.texture = head_texture


func bind_seat(seat: Dictionary) -> void:
	var joined := not seat.is_empty() and bool(seat.get("joined", false))
	seat_number = int(seat.get("identity", 0)) if joined else 0
	shape_name = str(seat.get("shape", "")) if joined else ""
	_number_label.text = str(seat_number) if joined else "-"
	_prefix_label.text = prefix_text
	_prefix_label.visible = joined and not prefix_text.is_empty()
	# A prefixed name reads as one word ("P1"); a bare number stays centred in its slot.
	_number_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_LEFT if _prefix_label.visible else HORIZONTAL_ALIGNMENT_CENTER
	)
	var tint: Color = seat.get("color", Color.WHITE)
	tint = tint.darkened(tint_darken) if use_seat_tint else plain_tint
	_chicken_head.visible = joined and use_chicken_head
	_chicken_head.modulate = Color(
		tint.r * chicken_head_tint_strength,
		tint.g * chicken_head_tint_strength,
		tint.b * chicken_head_tint_strength,
		tint.a
	)
	for key in SHAPE_NAMES:
		var polygon := _polygons[key] as Polygon2D
		var art := _art[key] as TextureRect
		var active: bool = joined and key == shape_name
		var has_art := art.texture != null
		polygon.visible = active and not has_art and not use_chicken_head
		polygon.color = tint
		art.visible = active and has_art and not use_chicken_head
		art.modulate = tint


## Shows the identity a seat will have once someone joins it (a lobby open slot). seat_number
## stays 0, so the seat still counts as empty.
func bind_preview(seat: Dictionary) -> void:
	if seat.is_empty():
		bind_seat(seat)
		return
	var preview := seat.duplicate()
	preview["joined"] = true
	bind_seat(preview)
	seat_number = 0


## Name of the shape currently visible (placeholder polygon or designer art), "" when empty.
func visible_shape() -> String:
	if _chicken_head.visible:
		return shape_name
	for key in SHAPE_NAMES:
		if (_polygons[key] as Polygon2D).visible or (_art[key] as TextureRect).visible:
			return key
	return ""


func number_text() -> String:
	return _number_label.text

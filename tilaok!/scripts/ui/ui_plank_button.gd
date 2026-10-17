class_name UiPlankButton
extends Button

## The wooden plank button from the Figma "Button Variants" frame (16:434).
## The Theme stylebox draws each state's fill. The scene nodes draw what one stylebox cannot:
## the gradient outline (`Stroke`, a 2 px ring clipping a gradient), the Pressed inner frame
## and group inner shadow (`PressedLook`), and the faded Disabled rivets. This script only
## picks each node's Theme type for the current state; every look stays editable in the Theme.

const RIVET := &"Rivet"
const RIVET_DISABLED := &"RivetDisabled"
const STROKE := &"PlankStroke"
const STROKE_PRESSED := &"PlankStrokePressed"
const STROKE_DISABLED := &"PlankStrokeDisabled"

@onready var _pressed_look: Control = $PressedLook
@onready var _stroke_gradient: Control = $Stroke/Gradient
@onready var _rivets: Array[Control] = [$RivetLeft, $RivetRight]


func _draw() -> void:
	# Hover, press and disable all redraw the button, so this keeps the extras in step.
	var mode := get_draw_mode()
	var pressed_now := mode == DRAW_PRESSED or mode == DRAW_HOVER_PRESSED
	var disabled_now := mode == DRAW_DISABLED
	if _pressed_look.visible != pressed_now:
		_pressed_look.visible = pressed_now
	var stroke := STROKE_PRESSED if pressed_now else (STROKE_DISABLED if disabled_now else STROKE)
	if _stroke_gradient.theme_type_variation != stroke:
		_stroke_gradient.theme_type_variation = stroke
	var rivet := RIVET_DISABLED if disabled_now else RIVET
	for node in _rivets:
		if node.theme_type_variation != rivet:
			node.theme_type_variation = rivet

class_name PugadEggCard
extends ItemEggPreview

signal egg_claimed(egg_id: String, variant_key: String)

var egg_id := ""


func _gui_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton
	if mouse != null and mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
		egg_claimed.emit(egg_id, variant_key)
		accept_event()

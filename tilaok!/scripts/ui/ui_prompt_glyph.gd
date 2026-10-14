class_name UiPromptGlyph
extends HBoxContainer

## "[glyph] Action" prompt. Text comes from UiPromptMap (data); Art_Glyph can show a picture too.

var action := ""
var device := ""

@onready var _glyph_label: Label = %GlyphLabel
@onready var _action_label: Label = %ActionLabel
@onready var _art_glyph: TextureRect = %Art_Glyph


func bind(action_id: String, device_kind: String, map: UiPromptMap) -> void:
	action = action_id
	device = device_kind
	if map == null:
		_glyph_label.text = "?"
		_action_label.text = action_id.capitalize()
	else:
		_glyph_label.text = map.glyph(action_id, device_kind)
		_action_label.text = map.action_name(action_id)
	_art_glyph.visible = _art_glyph.texture != null


## Free-text variant for a prompt that names several devices at once ("F / Enter / South").
func bind_text(glyph_value: String, action_value: String) -> void:
	action = ""
	device = ""
	_glyph_label.text = glyph_value
	_action_label.text = action_value
	_art_glyph.visible = _art_glyph.texture != null


func glyph_text() -> String:
	return _glyph_label.text


func action_text() -> String:
	return _action_label.text

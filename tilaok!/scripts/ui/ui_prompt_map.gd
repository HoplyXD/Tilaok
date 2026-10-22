class_name UiPromptMap
extends Resource

## Data-driven action -> glyph text per device kind ("k1".."k4", "gamepad"), from UI_HANDOFF §5.
## Gamepad labels are positions (South/East/West/Start), never brand symbols.
## Designers can replace a text glyph by assigning a texture in a PromptGlyph's Art_Glyph slot.

## Keys are "<action>|<device>" -> glyph text.
@export var glyphs: Dictionary = {}
## Keys are action ids -> player-facing action word.
@export var action_names: Dictionary = {}


func glyph(action: String, device: String) -> String:
	return str(glyphs.get("%s|%s" % [action, device], "?"))


func action_name(action: String) -> String:
	return str(action_names.get(action, action.capitalize()))


func actions() -> PackedStringArray:
	return PackedStringArray(action_names.keys())

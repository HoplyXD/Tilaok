class_name UiAwardLine
extends HBoxContainer

const GLYPHS := {
	"tapos": "T",
	"una": "1",
	"bayani": "B",
	"patibong": "P",
	"bawi": "R",
	"barya": "C",
	"placement": "L",
}
## Text style per award key: the Legend<Name> Theme types carry the ScoreAward colours.
const VARIATIONS := {
	"tapos": &"LegendTapos",
	"una": &"LegendUna",
	"bayani": &"LegendBayani",
	"patibong": &"LegendPatibong",
	"bawi": &"LegendBawi",
	"barya": &"LegendBarya",
	"placement": &"LegendPlacement",
}
const VARIATION_PLAIN := &"ResultText"

@onready var badge: UiPlayerBadge = %Badge
@onready var _text_label: Label = %TextLabel


func bind(seat: Dictionary, text: String, award_key: String = "") -> void:
	visible = not seat.is_empty()
	badge.bind_seat(seat)
	var glyph := str(GLYPHS.get(award_key, ""))
	_text_label.text = ("%s · %s" % [glyph, text]) if not glyph.is_empty() else text
	_text_label.theme_type_variation = VARIATIONS.get(award_key, VARIATION_PLAIN)


func text_value() -> String:
	return _text_label.text


## Height this line needs when the row is `width` wide (badge beside the wrapped text). Measured
## from the label's Theme font, so it is right before the container lays the line out.
func height_for_width(width: float) -> float:
	var badge_size := badge.get_combined_minimum_size()
	var text_width := maxf(
		width - badge_size.x - get_theme_constant("separation"), _text_label.custom_minimum_size.x
	)
	var font := _text_label.get_theme_font("font")
	var font_size := _text_label.get_theme_font_size("font_size")
	var line_height := font.get_height(font_size)
	var text_height := (
		font
		. get_multiline_string_size(
			_text_label.text, HORIZONTAL_ALIGNMENT_LEFT, text_width, font_size
		)
		. y
	)
	var lines := maxi(roundi(text_height / line_height), 1)
	text_height = lines * line_height + (lines - 1) * _text_label.get_theme_constant("line_spacing")
	return maxf(text_height, badge_size.y)

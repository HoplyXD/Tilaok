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

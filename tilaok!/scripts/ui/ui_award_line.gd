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

@onready var badge: UiPlayerBadge = %Badge
@onready var _text_label: Label = %TextLabel


func bind(seat: Dictionary, text: String, award_key: String = "") -> void:
	visible = not seat.is_empty()
	badge.bind_seat(seat)
	var glyph := str(GLYPHS.get(award_key, ""))
	_text_label.text = ("%s · %s" % [glyph, text]) if not glyph.is_empty() else text
	if GLYPHS.has(award_key):
		_text_label.add_theme_color_override("font_color", get_theme_color(award_key, "ScoreAward"))
	else:
		_text_label.remove_theme_color_override("font_color")


func text_value() -> String:
	return _text_label.text

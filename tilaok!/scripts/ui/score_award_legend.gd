class_name ScoreAwardLegend
extends GridContainer

const TOKENS := [
	{"key": "tapos", "glyph": "T", "label": "Tapos"},
	{"key": "una", "glyph": "1", "label": "Una"},
	{"key": "bayani", "glyph": "B", "label": "Bayani"},
	{"key": "patibong", "glyph": "P", "label": "Patibong"},
	{"key": "bawi", "glyph": "R", "label": "Bawi"},
	{"key": "barya", "glyph": "C", "label": "Barya"},
	{"key": "placement", "glyph": "L", "label": "Placement"},
]


func _ready() -> void:
	columns = 2
	add_theme_constant_override("h_separation", 8)
	add_theme_constant_override("v_separation", 4)
	for token in TOKENS:
		var entry := HBoxContainer.new()
		entry.add_theme_constant_override("separation", 6)
		entry.custom_minimum_size = Vector2(132.0, 22.0)
		var glyph := Label.new()
		glyph.text = str(token.glyph)
		glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		glyph.custom_minimum_size = Vector2(24.0, 0.0)
		glyph.add_theme_color_override("font_color", get_theme_color(str(token.key), "ScoreAward"))
		var label := Label.new()
		label.text = str(token.label)
		label.add_theme_font_size_override("font_size", 14)
		entry.add_child(glyph)
		entry.add_child(label)
		add_child(entry)

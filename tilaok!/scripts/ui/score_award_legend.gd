class_name ScoreAwardLegend
extends GridContainer

## Letter, dash and name for every score type. The entries are authored in score_award_legend.tscn
## (one Entry_<key> per token); each letter's colour is the Legend<Name> Theme type, kept equal to
## the ScoreAward/<key> chart colour.

const TOKENS := [
	{"key": "tapos", "glyph": "T", "label": "Tapos"},
	{"key": "bayani", "glyph": "B", "label": "Bayani"},
	{"key": "bawi", "glyph": "R", "label": "Bawi"},
	{"key": "placement", "glyph": "L", "label": "Placement"},
	{"key": "una", "glyph": "1", "label": "Una"},
	{"key": "patibong", "glyph": "P", "label": "Patibong"},
	{"key": "barya", "glyph": "C", "label": "Barya"},
]


func entry(key: String) -> Control:
	return get_node_or_null("Entry_%s" % key) as Control

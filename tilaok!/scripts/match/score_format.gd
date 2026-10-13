class_name ScoreFormat
extends RefCounted


## Tilaok scores are stored as integer eighth-point units.
static func format_units(units: int) -> String:
	var sign := "-" if units < 0 else ""
	var magnitude := absi(units)
	var whole := int(magnitude / 8)
	var fraction := (magnitude % 8) * 125
	if fraction == 0:
		return "%s%d" % [sign, whole]
	var fraction_text := "%03d" % fraction
	while fraction_text.ends_with("0"):
		fraction_text = fraction_text.substr(0, fraction_text.length() - 1)
	return "%s%d.%s" % [sign, whole, fraction_text]

class_name PresentationSettings
extends Resource

const RESULT_REVEAL_NORMAL := 0
const RESULT_REVEAL_REDUCED := 1
const RESULT_REVEAL_OFF := 2

@export_range(0.0, 1.0) var master_volume: float = 1.0
@export_range(0.0, 1.0) var music_volume: float = 1.0
@export_range(0.0, 1.0) var effects_volume: float = 1.0
@export_range(0.0, 1.0) var crowd_volume: float = 1.0
@export_enum("Full", "Reduced", "Off") var screen_shake: int = 2
@export_enum("Normal", "Reduced", "Off") var result_reveal_motion: int = RESULT_REVEAL_NORMAL


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	for field_name in ["master_volume", "music_volume", "effects_volume", "crowd_volume"]:
		var value: float = get(field_name)
		if not is_finite(value) or value < 0.0 or value > 1.0:
			errors.append("%s must be in the range 0..1" % field_name)
	if screen_shake < 0 or screen_shake > 2:
		errors.append("screen_shake must be Full, Reduced, or Off")
	if result_reveal_motion < RESULT_REVEAL_NORMAL or result_reveal_motion > RESULT_REVEAL_OFF:
		errors.append("result_reveal_motion must be Normal, Reduced, or Off")
	return errors

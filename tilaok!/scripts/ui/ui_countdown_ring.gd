class_name UiCountdownRing
extends HBoxContainer

## Countdown label + bar. Final art can drop into Art_Ring; the numeric label stays for readability.

@onready var _bar: ProgressBar = %Bar
@onready var _seconds_label: Label = %SecondsLabel


func set_time(remaining: float, total: float) -> void:
	_bar.max_value = maxf(total, 0.001)
	_bar.value = clampf(remaining, 0.0, total)
	_seconds_label.text = "%d" % int(ceilf(maxf(remaining, 0.0)))


func seconds_text() -> String:
	return _seconds_label.text

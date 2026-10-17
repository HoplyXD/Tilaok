class_name UiCountdownRing
extends BoxContainer

## Countdown label + bar. Final art can drop into Art_Ring; the numeric label stays for readability.
## countdown_ring.tscn lays it out in a row; countdown_bar.tscn stacks the bar over its labels.

## Text after the whole seconds ("s" reads "8s").
@export var seconds_suffix := ""

@onready var _bar: ProgressBar = %Bar
@onready var _seconds_label: Label = %SecondsLabel


func set_time(remaining: float, total: float) -> void:
	_bar.max_value = maxf(total, 0.001)
	_bar.value = clampf(remaining, 0.0, total)
	_seconds_label.text = "%d%s" % [int(ceilf(maxf(remaining, 0.0))), seconds_suffix]


func seconds_text() -> String:
	return _seconds_label.text

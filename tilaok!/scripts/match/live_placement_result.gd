class_name LivePlacementResult
extends RefCounted

## Stable resolved value retained through the placement attempt for idempotent retries.

var values: Dictionary = {}


func configure(source_values: Dictionary) -> void:
	values = source_values.duplicate(true)


func to_dictionary() -> Dictionary:
	return values.duplicate(true)

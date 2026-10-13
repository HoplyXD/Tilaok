class_name UiLibraryText
extends Resource

## SAMPLE Library copy for categories that have no live data yet. Final copy needs cultural review.

@export var categories: PackedStringArray = PackedStringArray()
@export var titles: PackedStringArray = PackedStringArray()
@export var bodies: PackedStringArray = PackedStringArray()


func body_for(category: String) -> String:
	var index := categories.find(category)
	return bodies[index] if index >= 0 and index < bodies.size() else ""


func title_for(category: String) -> String:
	var index := categories.find(category)
	return titles[index] if index >= 0 and index < titles.size() else category

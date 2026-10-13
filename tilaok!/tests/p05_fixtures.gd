class_name P05TestFixtures
extends RefCounted


## Test-only fixtures. These are never loaded by production scenes or item pools.
class MoverFixture:
	extends Node2D
	var start_position := Vector2.ZERO
	var reset_count := 0

	func _ready() -> void:
		start_position = position

	func reset_to_start() -> void:
		position = start_position
		reset_count += 1


class SolidAndTriggerFixture:
	extends RefCounted
	var solid_rect := Rect2(Vector2(0.0, 0.0), Vector2(32.0, 32.0))
	var danger_rect := Rect2(Vector2(24.0, 8.0), Vector2(24.0, 16.0))
	var solid_label := "TEST SOLID"
	var danger_label := "TEST DANGER REGION"

	func overlap_is_labeled() -> bool:
		return solid_rect.intersects(danger_rect, false) and not danger_label.is_empty()

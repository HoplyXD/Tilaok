class_name WallContactProbe
extends RefCounted
## Samples actual solid contact beside a CharacterBody2D for wall slide/jump.
## Eligibility comes only from explicit surface metadata (fail closed); this class never
## reads or writes support contacts and never publishes grounded support.

var side := 0
var collider_id := 0
var _collision := KinematicCollision2D.new()


func clear() -> void:
	side = 0
	collider_id = 0


## Returns -1/+1 for an eligible wall on the left/right (0 for none) and records its collider.
## `preferred_side` is tested first so a chicken wedged between two walls stays stable.
func sample(body: CharacterBody2D, tuning: GameplayTuning, preferred_side: int = 0) -> int:
	var first := -1 if preferred_side < 0 else 1
	for direction in [first, -first]:
		if has_eligible_wall(body, tuning, direction, tuning.wall_contact_probe_wu):
			side = direction
			collider_id = _collision.get_collider_id()
			return side
	clear()
	return 0


## True when an eligible, vertical, live wall face lies within `distance` wu on `direction`.
func has_eligible_wall(
	body: CharacterBody2D, tuning: GameplayTuning, direction: int, distance: float
) -> bool:
	if direction == 0 or body == null or not body.is_inside_tree():
		return false
	var motion := Vector2(float(direction) * distance, 0.0)
	if not body.test_move(body.global_transform, motion, _collision):
		return false
	return _is_eligible(_collision, direction, tuning)


static func collider_is_live(collider_object_id: int) -> bool:
	if collider_object_id == 0:
		return false
	var collider := instance_from_id(collider_object_id) as Node
	return collider != null and is_instance_valid(collider) and not collider.is_queued_for_deletion()


func _is_eligible(
	collision: KinematicCollision2D, direction: int, tuning: GameplayTuning
) -> bool:
	var collider := collision.get_collider() as Node
	if collider == null or not is_instance_valid(collider) or collider.is_queued_for_deletion():
		return false
	var metadata := SupportSurfaceMetadata.for_collider(collider)
	if (
		metadata == null
		or metadata.wall_movement_eligibility != SupportSurfaceMetadata.Eligibility.ELIGIBLE
	):
		return false
	var normal := collision.get_normal()
	# The face must oppose the probe and be near vertical (rejects floors, ceilings, corners).
	if normal.x * float(direction) >= 0.0:
		return false
	return absf(normal.x) >= cos(deg_to_rad(tuning.wall_normal_tolerance_degrees))

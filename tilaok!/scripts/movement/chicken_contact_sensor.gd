class_name ChickenContactSensor
extends Area2D

signal chicken_contacted(other: Node2D)
signal chicken_contact_left(other: Node2D)

@export var contact_size := Vector2(60.0, 120.0)
var _overlapping: Array[Node2D] = []
var _overlap_sources: Dictionary = {}


func _ready() -> void:
	monitoring = true
	monitorable = true
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_refresh_shape()


func _exit_tree() -> void:
	if area_entered.is_connected(_on_area_entered):
		area_entered.disconnect(_on_area_entered)
	if body_entered.is_connected(_on_body_entered):
		body_entered.disconnect(_on_body_entered)
	if area_exited.is_connected(_on_area_exited):
		area_exited.disconnect(_on_area_exited)
	if body_exited.is_connected(_on_body_exited):
		body_exited.disconnect(_on_body_exited)
	_overlapping.clear()
	_overlap_sources.clear()


func set_contact_size(size: Vector2) -> void:
	contact_size = size
	_refresh_shape()


func overlaps() -> Array[Node2D]:
	var result: Array[Node2D] = []
	for index in range(_overlapping.size() - 1, -1, -1):
		var other := _overlapping[index]
		if not is_instance_valid(other) or not other.is_inside_tree():
			_overlapping.remove_at(index)
			continue
		if _currently_intersects_body(other):
			result.append(other)
	for key in _overlap_sources.keys():
		var source: Dictionary = _overlap_sources[key]
		var referenced := (source.get("ref") as WeakRef).get_ref() as Node2D
		if (
			referenced == null
			or not is_instance_valid(referenced)
			or not referenced.is_inside_tree()
		):
			_overlap_sources.erase(key)
	return result


## Physics overlap signals are cached by Godot and may remain stale for a step after a
## teleport, a shape change, or a freed participant. Tag arbitration asks for current contact,
## so filter each cached participant against the current sensor and body rectangles.
func _currently_intersects_body(other: Node2D) -> bool:
	if not other is PhysicsBody2D:
		return false
	var body_shape: CollisionShape2D
	for child in other.get_children():
		# A chicken carries one hitbox per pose (standing, airborne, sneaking) and enables only
		# the one its state calls for, so the enabled shape is the body to measure against.
		if not (child is CollisionShape2D) or (child as CollisionShape2D).disabled:
			continue
		if (child as CollisionShape2D).shape is RectangleShape2D:
			body_shape = child
			break
	if body_shape == null:
		return false
	var other_size := (body_shape.shape as RectangleShape2D).size * body_shape.global_scale.abs()
	var sensor_size := contact_size * global_scale.abs()
	var combined_half_size := (sensor_size + other_size) * 0.5
	var separation := (global_position - body_shape.global_position).abs()
	return separation.x <= combined_half_size.x and separation.y <= combined_half_size.y


func _refresh_shape() -> void:
	if not is_inside_tree():
		return
	var collision := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision == null:
		collision = CollisionShape2D.new()
		collision.name = "CollisionShape2D"
		add_child(collision)
	var shape := RectangleShape2D.new()
	shape.size = contact_size
	collision.shape = shape


func _on_area_entered(area: Area2D) -> void:
	var other := area.get_parent() as Node2D
	_track_enter(other)


func _on_body_entered(body: Node2D) -> void:
	_track_enter(body)


func _track_enter(other: Node2D) -> void:
	if other == null or other == get_parent() or not other.is_in_group("chickens"):
		return
	var key := other.get_instance_id()
	var source: Dictionary = _overlap_sources.get(key, {"ref": weakref(other), "count": 0})
	var source_count := int(source.count)
	source.count = source_count + 1
	_overlap_sources[key] = source
	if source_count == 0:
		_overlapping.append(other)
		chicken_contacted.emit(other)


func _on_body_exited(body: Node2D) -> void:
	_track_exit(body)


func _on_area_exited(area: Area2D) -> void:
	_track_exit(area.get_parent() as Node2D)


func _track_exit(other: Node2D) -> void:
	if other == null or not is_instance_valid(other):
		return
	var key := other.get_instance_id()
	if not _overlap_sources.has(key):
		return
	var source: Dictionary = _overlap_sources[key]
	var source_count := int(source.count)
	if source_count > 1:
		source.count = source_count - 1
		_overlap_sources[key] = source
	else:
		_overlap_sources.erase(key)
		_overlapping.erase(other)
		chicken_contact_left.emit(other)

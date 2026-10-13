class_name ChickenContactSensor
extends Area2D

signal chicken_contacted(other: Node2D)
signal chicken_contact_left(other: Node2D)

@export var contact_size := Vector2(60.0, 120.0)
var _overlapping: Array[Node2D] = []


func _ready() -> void:
	monitoring = true
	monitorable = true
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_refresh_shape()


func _exit_tree() -> void:
	if area_entered.is_connected(_on_area_entered):
		area_entered.disconnect(_on_area_entered)
	if body_entered.is_connected(_on_body_entered):
		body_entered.disconnect(_on_body_entered)
	if body_exited.is_connected(_on_body_exited):
		body_exited.disconnect(_on_body_exited)
	_overlapping.clear()


func set_contact_size(size: Vector2) -> void:
	contact_size = size
	_refresh_shape()


func overlaps() -> Array[Node2D]:
	var result: Array[Node2D] = []
	for other in _overlapping:
		if is_instance_valid(other) and other.is_inside_tree():
			result.append(other)
	return result


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
	if not _overlapping.has(other):
		_overlapping.append(other)
		chicken_contacted.emit(other)


func _on_body_exited(body: Node2D) -> void:
	if _overlapping.has(body):
		_overlapping.erase(body)
		chicken_contact_left.emit(body)

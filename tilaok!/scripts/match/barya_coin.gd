class_name BaryaCoin
extends Area2D

## DEBUG procedural stand-in only. The human art team owns the final coin and carried attachment.
const OUTER := Color("#f4c95d")
const INNER := Color("#8b5421")
const MARK := Color("#fff6cf")

var identity := ""
var is_carried := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	monitorable = true
	queue_redraw()


func place_at(parent: Node, world_position: Vector2, objective_identity: String) -> void:
	identity = objective_identity
	if get_parent() != parent:
		reparent(parent)
	global_position = world_position
	is_carried = false
	collision_mask = 2
	set_deferred("monitoring", true)
	queue_redraw()


func attach_to(actor: ChickenController) -> void:
	if actor == null:
		return
	if get_parent() != actor:
		reparent(actor)
	position = Vector2(0.0, -82.0)
	is_carried = true
	collision_mask = 0
	set_deferred("monitoring", false)
	queue_redraw()


## Read a deterministic shape-overlap snapshot from the physics space during the room's physics
## step. No Area2D body_entered callback order participates in pickup arbitration.
func bodies_in_pickup_snapshot() -> Array[Node2D]:
	var bodies: Array[Node2D] = []
	var shape_node := get_node_or_null("PickupShape") as CollisionShape2D
	if (
		shape_node == null
		or shape_node.shape == null
		or not is_inside_tree()
		or get_world_2d() == null
	):
		return bodies
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape_node.shape
	query.transform = shape_node.global_transform
	query.collision_mask = 2
	query.collide_with_bodies = true
	query.collide_with_areas = false
	for hit in get_world_2d().direct_space_state.intersect_shape(query, 16):
		var body := hit.get("collider") as Node2D
		if body != null and not bodies.has(body):
			bodies.append(body)
	return bodies


func _draw() -> void:
	draw_circle(Vector2.ZERO, 17.0, OUTER)
	draw_circle(Vector2.ZERO, 12.0, INNER)
	draw_arc(Vector2.ZERO, 14.5, -2.65, -0.55, 20, MARK, 2.0)
	var font := ThemeDB.fallback_font
	if font != null:
		draw_string(font, Vector2(-5.0, 5.0), "B", HORIZONTAL_ALIGNMENT_CENTER, 10.0, 13, MARK)
		draw_string(font, Vector2(-14.0, 31.0), "DEBUG", HORIZONTAL_ALIGNMENT_CENTER, 28.0, 7, MARK)

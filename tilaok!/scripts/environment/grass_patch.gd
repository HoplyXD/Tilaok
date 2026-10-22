@tool
class_name GrassPatch
extends Node2D

## Decorative grass for scenes/environment/ (user request, 2026-10-22).
##
## Not a block and not an item: it carries no collision, never supports anyone, never blocks a
## build and is not in BlockCatalog, so devs may drop it anywhere in a map scene and off the grid.
## Its only job is to look alive. Chickens walking through push the blades aside and they spring
## back; an ambient breeze keeps idle grass from looking frozen.
##
## The detector is monitoring-only on the chicken layer (2), so it can never push a chicken around
## or be stood on. Because it is cosmetic it runs on _process, not the physics step, and so it
## never touches the deterministic simulation the match and the networked track depend on.

## How hard a passing chicken pushes the blades.
@export_range(0.0, 2.0) var push_strength := 1.0
## How quickly the blades return once nothing is touching them. Higher springs back faster.
@export_range(1.0, 60.0) var spring_stiffness := 26.0
## Bleeds off the spring's overshoot so the grass settles instead of wobbling forever.
@export_range(0.0, 30.0) var spring_damping := 9.0
## Breeze speed. Zero leaves the grass still until something walks through it.
@export_range(0.0, 8.0) var breeze_speed := 1.4
## Mirrors the art horizontally; handy so a row of patches is not visibly identical.
@export var flip_h := false:
	set(value):
		flip_h = value
		var sprite := _sprite()
		if sprite != null:
			sprite.flip_h = value

var _bend := 0.0
var _bend_velocity := 0.0
var _phase := 0.0
var _visitors: Array[Node2D] = []


func _ready() -> void:
	_phase = randf() * TAU
	var sprite := _sprite()
	if sprite != null:
		sprite.flip_h = flip_h
	if Engine.is_editor_hint():
		return
	var area := _area()
	if area != null:
		area.body_entered.connect(_on_body_entered)
		area.body_exited.connect(_on_body_exited)


func _process(delta: float) -> void:
	_phase += delta * breeze_speed
	_bend = _step_bend(_bend, _target_bend(), delta)
	var sprite := _sprite()
	var material := sprite.material as ShaderMaterial if sprite != null else null
	if material == null:
		return
	material.set_shader_parameter("bend", _bend)
	material.set_shader_parameter("sway", _phase)


## Where the blades want to be: pushed in each visitor's direction of travel, strongest for a
## chicken right on top of the patch. Zero when nothing is inside.
func _target_bend() -> float:
	var target := 0.0
	for visitor in _visitors:
		if not is_instance_valid(visitor):
			continue
		var direction := signf(visitor.global_position.x - global_position.x)
		if visitor is CharacterBody2D and absf((visitor as CharacterBody2D).velocity.x) > 1.0:
			direction = signf((visitor as CharacterBody2D).velocity.x)
		target += direction * push_strength
	return clampf(target, -1.0, 1.0)


## One damped-spring step towards `target`. Pure so the easing can be checked without a scene.
func _step_bend(current: float, target: float, delta: float) -> float:
	_bend_velocity += (target - current) * spring_stiffness * delta
	_bend_velocity -= _bend_velocity * minf(spring_damping * delta, 1.0)
	return clampf(current + _bend_velocity * delta, -1.5, 1.5)


func _on_body_entered(body: Node2D) -> void:
	if not _visitors.has(body):
		_visitors.append(body)


func _on_body_exited(body: Node2D) -> void:
	_visitors.erase(body)


func _sprite() -> Sprite2D:
	return get_node_or_null("Visual") as Sprite2D


func _area() -> Area2D:
	return get_node_or_null("Detector") as Area2D

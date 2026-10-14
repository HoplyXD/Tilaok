@tool
class_name BlockHitbox
extends Area2D

## A hitbox region of a scene-authored block (scenes/blocks/). Add it as a child of the block root
## and give it one or more RectangleShape2D children; resize them freely in the editor. Hitboxes
## are independent of the block's solid collision and of its placement box, so a 2x2 block can
## have a small solid and a kill strip anywhere. BlockCatalog turns each shape into a region.
##
## Effects:
## - KILL / STUN / LAUNCH: touch regions (KILL eliminates, STUN freezes + knocks back, LAUNCH is
##   the spring face). Must stay inside the placement box.
## - SWEEP: the bounded rail a moving part travels (Follow Rail special).
## - BEAM: a timed beam between solid posts that solids can cut short (Timed Hitbox special).
## - CAPTURE_PATH: the rising bubble path (projectiles with capture).
## - CLEANUP_AREA: the one-shot cleanup area (Cleanup special).
## - LANE: an explicit projectile lane (normally derived from the projectile's Path2D instead).
## The editor draws each effect in its own colour; the game never shows these nodes.

enum Effect { KILL, STUN, LAUNCH, SWEEP, BEAM, CAPTURE_PATH, CLEANUP_AREA, LANE }

const EFFECT_COLORS := {
	Effect.KILL: Color(1.0, 0.15, 0.15, 0.45),
	Effect.STUN: Color(1.0, 0.85, 0.1, 0.45),
	Effect.LAUNCH: Color(0.2, 0.9, 0.4, 0.45),
	Effect.SWEEP: Color(1.0, 0.5, 0.1, 0.3),
	Effect.BEAM: Color(1.0, 0.9, 0.4, 0.35),
	Effect.CAPTURE_PATH: Color(0.5, 0.85, 1.0, 0.3),
	Effect.CLEANUP_AREA: Color(0.7, 0.6, 1.0, 0.3),
	Effect.LANE: Color(1.0, 0.7, 0.3, 0.3),
}

## What touching or being inside this hitbox does (see the list above).
@export var effect := Effect.KILL:
	set(value):
		effect = value
		queue_redraw()


func _ready() -> void:
	# Hitboxes are authoring data; collision is driven by the catalog regions, not this Area2D.
	monitoring = false
	monitorable = false
	collision_layer = 0
	collision_mask = 0
	if not Engine.is_editor_hint():
		visible = false


## Effect tag stored on the generated region ("kill", "stun", "launch" or "").
func effect_name() -> StringName:
	match effect:
		Effect.KILL:
			return &"kill"
		Effect.STUN:
			return &"stun"
		Effect.LAUNCH:
			return &"launch"
		Effect.CAPTURE_PATH:
			return &"capture"
	return &""


## Rects of this hitbox's rectangle shapes, in the coordinates of `relative_to`.
func shape_rects(relative_to: Node2D) -> Array[Rect2]:
	var result: Array[Rect2] = []
	for child in get_children():
		var collision := child as CollisionShape2D
		if collision == null or not collision.shape is RectangleShape2D:
			continue
		var size := (collision.shape as RectangleShape2D).size
		var to_root := relative_to.global_transform.affine_inverse() * collision.global_transform
		var corners := [
			to_root * (-size * 0.5),
			to_root * Vector2(size.x * 0.5, -size.y * 0.5),
			to_root * (size * 0.5),
			to_root * Vector2(-size.x * 0.5, size.y * 0.5),
		]
		var rect := Rect2(corners[0], Vector2.ZERO)
		for corner in corners:
			rect = rect.expand(corner)
		result.append(rect)
	return result


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	var has_rect := false
	for child in get_children():
		if child is CollisionShape2D and (child as CollisionShape2D).shape is RectangleShape2D:
			has_rect = true
	if not has_rect:
		warnings.append("Add a CollisionShape2D with a RectangleShape2D to define this hitbox.")
	return warnings


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var color: Color = EFFECT_COLORS.get(effect, Color(1, 1, 1, 0.3))
	for rect in shape_rects(self):
		draw_rect(rect, color)
		draw_rect(rect, Color(color, 1.0), false, 2.0)

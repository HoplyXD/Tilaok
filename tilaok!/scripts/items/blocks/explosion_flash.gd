class_name ExplosionFlash
extends Node2D

## DEBUG placeholder blast cue for one-shot cleanup blocks (Bomb, Dynamite, Nuke): a soft puff
## that fills the blast area, grows a little and fades, then frees itself. Presentation only:
## the pieces were already removed by the atomic Place commit. Final art/VFX stays with the team.

const SECONDS := 0.7
const FILL := Color(1.0, 0.72, 0.25, 0.55)
const RING := Color(1.0, 0.95, 0.75, 0.95)

var area := Rect2()
var _age := 0.0


## `blast_area` is the cleanup footprint in world units.
func setup(blast_area: Rect2) -> void:
	area = blast_area
	name = "ExplosionFlash"
	z_index = 40
	queue_redraw()


func _process(delta: float) -> void:
	_age += delta
	if _age >= SECONDS:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var t := clampf(_age / SECONDS, 0.0, 1.0)
	var fade := 1.0 - t
	var center := area.get_center()
	var radius := maxf(area.size.x, area.size.y) * (0.35 + 0.35 * t)
	draw_rect(area, Color(FILL, FILL.a * fade))
	draw_circle(center, radius, Color(FILL, FILL.a * fade))
	draw_arc(center, radius, 0.0, TAU, 40, Color(RING, RING.a * fade), 6.0 * fade + 1.0)

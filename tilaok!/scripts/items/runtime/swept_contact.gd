class_name SweptContact
extends RefCounted

## Axis-aligned swept overlap so fast movers never tunnel through a player body.


## Fraction 0..1 of the first overlap while `from_rect` moves linearly to `to_rect`; -1 for none.
static func first_overlap(from_rect: Rect2, to_rect: Rect2, target: Rect2) -> float:
	if from_rect.intersects(target, false):
		return 0.0
	var delta := to_rect.position - from_rect.position
	var entry := 0.0
	var exit_time := 1.0
	for axis in range(2):
		var near_edge: float = from_rect.position[axis]
		var far_edge: float = from_rect.end[axis]
		var target_near: float = target.position[axis]
		var target_far: float = target.end[axis]
		var motion: float = delta[axis]
		if is_zero_approx(motion):
			if far_edge <= target_near or near_edge >= target_far:
				return -1.0
			continue
		var t_enter := (target_near - far_edge) / motion
		var t_exit := (target_far - near_edge) / motion
		if motion < 0.0:
			t_enter = (target_far - near_edge) / motion
			t_exit = (target_near - far_edge) / motion
		entry = maxf(entry, t_enter)
		exit_time = minf(exit_time, t_exit)
		if entry > exit_time:
			return -1.0
	return clampf(entry, 0.0, 1.0)


static func body_rect(actor: Node2D, tuning: GameplayTuning) -> Rect2:
	var size := Vector2(tuning.body_width_wu, tuning.body_height_wu)
	return Rect2(actor.global_position - size * 0.5, size)


## True when a body touches a launch face within `probe` wu. `normal` is the face's outward
## direction (the direction a launched chicken is pushed).
static func face_contact(body: Rect2, face: Rect2, normal: Vector2, probe: float) -> bool:
	var vertical := absf(normal.y) > 0.5
	var plane := face.position.y if normal.y < 0.0 else face.end.y
	var body_edge := body.end.y if normal.y < 0.0 else body.position.y
	if not vertical:
		plane = face.position.x if normal.x < 0.0 else face.end.x
		body_edge = body.end.x if normal.x < 0.0 else body.position.x
	if absf(body_edge - plane) > probe:
		return false
	var overlap := 0.0
	if vertical:
		overlap = minf(body.end.x, face.end.x) - maxf(body.position.x, face.position.x)
	else:
		overlap = minf(body.end.y, face.end.y) - maxf(body.position.y, face.position.y)
	return overlap > 2.0

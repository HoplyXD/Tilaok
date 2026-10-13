class_name LaneQuery
extends RefCounted

## First-blocker query for axis-aligned beams, lanes and bubble paths. Uses the real solid volume
## of pieces and immutable base geometry, so the ghost, runtime and tests agree exactly.


## origin: lane start. direction: unit axis vector. Returns
## {length: clipped length, blocked: bool, blocker: Rect2}.
static func clip(
	origin: Vector2, direction: Vector2, length: float, thickness: float, occluders: Array[Rect2]
) -> Dictionary:
	var horizontal := absf(direction.x) > 0.5
	var half := thickness * 0.5
	var best := length
	var blocker := Rect2()
	var blocked := false
	for rect in occluders:
		var distance := _distance(origin, direction, half, horizontal, rect)
		if distance < 0.0:
			continue
		if distance < best:
			best = distance
			blocker = rect
			blocked = true
	return {"length": best, "blocked": blocked, "blocker": blocker}


## Distance from origin to the rect along direction, or -1 when the rect is off the swath.
static func _distance(
	origin: Vector2, direction: Vector2, half: float, horizontal: bool, rect: Rect2
) -> float:
	if horizontal:
		if rect.end.y <= origin.y - half or rect.position.y >= origin.y + half:
			return -1.0
		if direction.x > 0.0:
			return -1.0 if rect.end.x <= origin.x else maxf(0.0, rect.position.x - origin.x)
		return -1.0 if rect.position.x >= origin.x else maxf(0.0, origin.x - rect.end.x)
	if rect.end.x <= origin.x - half or rect.position.x >= origin.x + half:
		return -1.0
	if direction.y > 0.0:
		return -1.0 if rect.end.y <= origin.y else maxf(0.0, rect.position.y - origin.y)
	return -1.0 if rect.position.y >= origin.y else maxf(0.0, origin.y - rect.end.y)

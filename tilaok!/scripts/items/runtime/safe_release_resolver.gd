class_name SafeReleaseResolver
extends RefCounted

## Nearest non-overlapping body position inside the arena for a released captive.
## Deterministic ring search; ties are broken by position order, never by call order.

const STEP_WU := 4.0
const MAX_RADIUS_WU := 96.0


static func is_free(center: Vector2, size: Vector2, bounds: Rect2, occluders: Array[Rect2]) -> bool:
	var body := Rect2(center - size * 0.5, size)
	if not bounds.encloses(body):
		return false
	for rect in occluders:
		if body.intersects(rect, false):
			return false
	return true


## {found: bool, center: Vector2}. `found=false` means the caller must use its last safe point.
static func find(
	desired: Vector2, size: Vector2, bounds: Rect2, occluders: Array[Rect2]
) -> Dictionary:
	if is_free(desired, size, bounds, occluders):
		return {"found": true, "center": desired}
	var candidates: Array[Vector2] = []
	var steps := int(MAX_RADIUS_WU / STEP_WU)
	for ix in range(-steps, steps + 1):
		for iy in range(-steps, steps + 1):
			if ix == 0 and iy == 0:
				continue
			candidates.append(desired + Vector2(ix, iy) * STEP_WU)
	candidates.sort_custom(
		func(left: Vector2, right: Vector2) -> bool:
			var left_d := left.distance_squared_to(desired)
			var right_d := right.distance_squared_to(desired)
			if not is_equal_approx(left_d, right_d):
				return left_d < right_d
			if not is_equal_approx(left.y, right.y):
				return left.y < right.y
			return left.x < right.x
	)
	for candidate in candidates:
		if is_free(candidate, size, bounds, occluders):
			return {"found": true, "center": candidate}
	return {"found": false, "center": desired}

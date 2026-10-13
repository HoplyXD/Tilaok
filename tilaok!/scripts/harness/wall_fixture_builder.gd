class_name WallFixtureBuilder
extends RefCounted
## Test/diagnostic wall fixtures for the REQ-MOVE-004 extension. These are labeled DEBUG
## geometry added on demand to the diagnostic rooms; they never replace P03 base geometry.

const FIXTURE_HEIGHT_WU := 128.0
const FIXTURE_WIDTH_WU := 16.0
const SHAFT_GAP_WU := 64.0
## Local x offsets from the fixture origin. Slab, shaft pair, excluded, one-way, moving.
const SLAB_X := 0.0
const SHAFT_LEFT_X := 96.0
const SHAFT_RIGHT_X := 176.0
const EXCLUDED_X := 240.0
const ONE_WAY_X := 288.0
const MOVING_X := 336.0


## Adds one solid with explicit wall eligibility metadata. `options` keys: `one_way`, `moving`,
## `player_built`, `label`. Returns the body (an AnimatableBody2D when `moving`).
static func add_solid(
	parent: Node2D, surface_id: String, rect: Rect2, wall_eligible: bool, options: Dictionary = {}
) -> StaticBody2D:
	var metadata := SupportSurfaceMetadata.new()
	metadata.surface_id = surface_id
	metadata.player_built = bool(options.get("player_built", false))
	metadata.construction_id = surface_id if metadata.player_built else ""
	metadata.wave_support_eligibility = SupportSurfaceMetadata.Eligibility.INELIGIBLE
	metadata.wall_movement_eligibility = (
		SupportSurfaceMetadata.Eligibility.ELIGIBLE
		if wall_eligible
		else SupportSurfaceMetadata.Eligibility.INELIGIBLE
	)
	var body: StaticBody2D
	if bool(options.get("moving", false)):
		var animatable := AnimatableBody2D.new()
		animatable.sync_to_physics = true
		body = animatable
	else:
		body = StaticBody2D.new()
	body.name = surface_id.replace(".", "_")
	body.position = rect.get_center()
	body.collision_layer = 1
	body.collision_mask = 1
	body.set_meta(SupportSurfaceMetadata.META_KEY, metadata)
	parent.add_child(body)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	collision.one_way_collision = bool(options.get("one_way", false))
	body.add_child(collision)
	var visual := Polygon2D.new()
	visual.polygon = PackedVector2Array(
		[
			Vector2(-rect.size.x * 0.5, -rect.size.y * 0.5),
			Vector2(rect.size.x * 0.5, -rect.size.y * 0.5),
			Vector2(rect.size.x * 0.5, rect.size.y * 0.5),
			Vector2(-rect.size.x * 0.5, rect.size.y * 0.5),
		]
	)
	visual.color = Color("#e9c46a") if wall_eligible else Color("#6b7a86")
	body.add_child(visual)
	var label := Label.new()
	label.text = str(options.get("label", "WALL OK" if wall_eligible else "NO WALL"))
	var label_row := int(options.get("label_row", 0))
	label.position = Vector2(
		-rect.size.x * 0.5 - 4.0, -rect.size.y * 0.5 - 18.0 - float(label_row) * 13.0
	)
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color("#14232a"))
	label.add_theme_constant_override("outline_size", 3)
	body.add_child(label)
	return body


## Builds the standard fixture set under `parent` at `origin` (top-left). Returns the bodies
## keyed by fixture name so tests can move or remove them.
static func build_set(parent: Node2D, origin: Vector2) -> Dictionary:
	var tall := Vector2(FIXTURE_WIDTH_WU, FIXTURE_HEIGHT_WU)
	var fixtures := {}
	fixtures["slab"] = add_solid(
		parent,
		"wall_fixture.slab",
		Rect2(origin + Vector2(SLAB_X, 0.0), tall),
		true,
		{"label": "WALL OK • SLAB", "label_row": 0}
	)
	fixtures["shaft_left"] = add_solid(
		parent,
		"wall_fixture.shaft_left",
		Rect2(origin + Vector2(SHAFT_LEFT_X, 0.0), tall),
		true,
		{"label": "WALL OK • SHAFT", "player_built": true, "label_row": 1}
	)
	fixtures["shaft_right"] = add_solid(
		parent,
		"wall_fixture.shaft_right",
		Rect2(origin + Vector2(SHAFT_RIGHT_X, 0.0), tall),
		true,
		{"label": "WALL OK • SHAFT", "player_built": true, "label_row": 0}
	)
	fixtures["excluded"] = add_solid(
		parent,
		"wall_fixture.excluded",
		Rect2(origin + Vector2(EXCLUDED_X, 0.0), tall),
		false,
		{"label": "NO WALL • EXCLUDED", "label_row": 1}
	)
	fixtures["one_way"] = add_solid(
		parent,
		"wall_fixture.one_way",
		Rect2(origin + Vector2(ONE_WAY_X, 0.0), tall),
		true,
		{"label": "NO WALL • ONE-WAY", "one_way": true, "label_row": 0}
	)
	fixtures["moving"] = add_solid(
		parent,
		"wall_fixture.moving",
		Rect2(origin + Vector2(MOVING_X, 0.0), tall),
		true,
		{"label": "WALL OK • MOVING", "moving": true, "label_row": 2}
	)
	return fixtures


## Local x of the free space immediately right of the slab (wall on the chicken's left).
static func slab_right_stand_x(origin: Vector2, body_width: float) -> float:
	return origin.x + SLAB_X + FIXTURE_WIDTH_WU + body_width * 0.5 + 0.1


## Centre x of the shaft interior.
static func shaft_center_x(origin: Vector2) -> float:
	return origin.x + SHAFT_LEFT_X + FIXTURE_WIDTH_WU + SHAFT_GAP_WU * 0.5

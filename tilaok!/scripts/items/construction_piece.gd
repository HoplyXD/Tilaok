class_name ConstructionPiece
extends AnimatableBody2D

## One placed construction piece: collision plus a code-drawn graybox silhouette.
## Visuals are labeled DEBUG placeholders; final art belongs to the human art team.

enum Style { CRATE, BAMBOO }

## Drawing constants are authored on the historical 32 wu grid; _k() scales them to cell_wu.
const DEBUG_LABEL_MIN_WIDTH_WU := 96.0
const BAMBOO_NODE_SPACING_WU := 16.0
const CHEVRON_SPACING_WU := 32.0

@export var style := Style.CRATE

var placed: PlacedItem
var simulation_authority := SimulationAuthority.offline()
var metadata: SupportSurfaceMetadata
var wall_contact := ""
var footprint_size := Vector2.ZERO
var resolved_regions: Array[Dictionary] = []
var cell_wu := 32.0
var _solid_rects: Array[Rect2] = []
var _strip_rects: Array[Rect2] = []
var _strip_normals: Array[Vector2] = []


## An AnimatableBody2D (still a StaticBody2D) so scene blocks with gravity can move through
## move_and_collide; unmoved pieces behave exactly like static bodies.
func _init() -> void:
	sync_to_physics = false


## regions: output of ItemGeometry.resolve_regions (rects are relative to the footprint corner).
func configure(
	source: PlacedItem,
	regions: Array[Dictionary],
	surface_metadata: SupportSurfaceMetadata,
	wall_contact_declaration: String,
	tuning: GameplayTuning
) -> void:
	placed = source
	resolved_regions = regions
	metadata = surface_metadata
	wall_contact = wall_contact_declaration
	cell_wu = tuning.grid_cell_wu
	footprint_size = source.footprint_rect.size
	name = source.instance_id.replace("#", "_")
	position = source.footprint_rect.position
	collision_layer = 1
	collision_mask = 1
	add_to_group("support_surfaces")
	set_meta(SupportSurfaceMetadata.META_KEY, surface_metadata)
	for region in regions:
		var kind: ItemRegionSpec.Kind = region.kind
		if not ItemRegionSpec.is_collision_kind(kind):
			continue
		var rect: Rect2 = region.rect
		var shape := RectangleShape2D.new()
		shape.size = rect.size
		var collision := CollisionShape2D.new()
		collision.name = "%sShape%d" % [ItemRegionSpec.kind_name(kind), get_child_count()]
		collision.shape = shape
		collision.position = rect.get_center()
		if kind == ItemRegionSpec.Kind.ONE_WAY_TOP:
			collision.one_way_collision = true
			collision.rotation = (region.normal as Vector2).angle() + PI * 0.5
			_strip_rects.append(rect)
			_strip_normals.append(region.normal)
		else:
			_solid_rects.append(rect)
		add_child(collision)
	queue_redraw()


## World-space rects of the actual solid volume (projectile occlusion uses exactly these).
func occlusion_rects() -> Array[Rect2]:
	var result: Array[Rect2] = []
	for rect in _solid_rects:
		result.append(Rect2(rect.position + position, rect.size))
	return result


func strip_world_rects() -> Array[Rect2]:
	var result: Array[Rect2] = []
	for rect in _strip_rects:
		result.append(Rect2(rect.position + position, rect.size))
	return result


func strip_normals() -> Array[Vector2]:
	return _strip_normals


func footprint_world_rect() -> Rect2:
	return Rect2(position, footprint_size)


## Static construction has no start state to restore; movers override this later.
func reset_to_start() -> void:
	pass


func _draw() -> void:
	if footprint_size == Vector2.ZERO:
		return
	if style == Style.CRATE:
		_draw_crate()
	else:
		_draw_bamboo()
	var font := ThemeDB.fallback_font
	if font != null and footprint_size.x >= DEBUG_LABEL_MIN_WIDTH_WU * _k():
		var text := "KAING • DEBUG" if style == Style.CRATE else "TULAY • DEBUG"
		draw_string(
			font,
			(
				Vector2(4.0, footprint_size.y / _k() - 5.0) * _k()
				if style == Style.CRATE
				else Vector2(4.0, 26.0) * _k()
			),
			text,
			HORIZONTAL_ALIGNMENT_LEFT,
			footprint_size.x - 8.0 * _k(),
			roundi(10 * _k()),
			Color.WHITE
		)


func _k() -> float:
	return cell_wu / 32.0


func _draw_crate() -> void:
	var outline := Color("#2a1a0c")
	for rect in _solid_rects:
		draw_rect(rect, Color("#9a6b3a"))
		var cells := Vector2i(roundi(rect.size.x / cell_wu), roundi(rect.size.y / cell_wu))
		for column in range(cells.x):
			for row in range(cells.y):
				var cell_rect := Rect2(
					rect.position + Vector2(column, row) * cell_wu, Vector2(cell_wu, cell_wu)
				)
				draw_rect(cell_rect.grow(-3.0 * _k()), Color("#7a5226"), false, 2.0 * _k())
				draw_line(cell_rect.position, cell_rect.end, Color("#5a3a18"), 2.0 * _k())
				draw_line(
					cell_rect.position + Vector2(cell_wu, 0.0),
					cell_rect.position + Vector2(0.0, cell_wu),
					Color("#5a3a18"),
					2.0 * _k()
				)
		draw_rect(rect, outline, false, 3.0 * _k())


func _draw_bamboo() -> void:
	# Footprint reservation: dashed outline, visibly distinct from the 4 wu collision strip.
	var reservation := Rect2(Vector2.ZERO, footprint_size)
	var dash := 8.0 * _k()
	var x := 0.0
	while x < reservation.size.x:
		var end_x := minf(x + dash, reservation.size.x)
		draw_line(Vector2(x, 0.0), Vector2(end_x, 0.0), Color("#cfe8a0"), 1.0)
		draw_line(
			Vector2(x, reservation.size.y),
			Vector2(end_x, reservation.size.y),
			Color("#cfe8a0"),
			1.0
		)
		x += dash * 2.0
	var y := 0.0
	while y < reservation.size.y:
		var end_y := minf(y + dash, reservation.size.y)
		draw_line(Vector2(0.0, y), Vector2(0.0, end_y), Color("#cfe8a0"), 1.0)
		draw_line(
			Vector2(reservation.size.x, y),
			Vector2(reservation.size.x, end_y),
			Color("#cfe8a0"),
			1.0
		)
		y += dash * 2.0
	for index in range(_strip_rects.size()):
		var rect := _strip_rects[index]
		draw_rect(rect, Color("#c9b43c"))
		draw_rect(rect, Color("#4b4511"), false, 2.0)
		var horizontal := absf((_strip_normals[index] as Vector2).y) > 0.5
		var step := BAMBOO_NODE_SPACING_WU * _k()
		var offset := step
		var length := rect.size.x if horizontal else rect.size.y
		while offset < length:
			if horizontal:
				draw_line(
					rect.position + Vector2(offset, 0.0),
					rect.position + Vector2(offset, rect.size.y),
					Color("#4b4511"),
					2.0
				)
			else:
				draw_line(
					rect.position + Vector2(0.0, offset),
					rect.position + Vector2(rect.size.x, offset),
					Color("#4b4511"),
					2.0
				)
			offset += step
		# Upward chevrons mark the one-way top.
		var normal: Vector2 = _strip_normals[index]
		var along := Vector2(-normal.y, normal.x)
		var cursor := CHEVRON_SPACING_WU * _k() * 0.5
		var span := rect.size.x if horizontal else rect.size.y
		while cursor < span:
			var base := (
				rect.get_center()
				- along * span * 0.5
				+ along * cursor
				+ normal * (rect.size.y + 3.0)
			)
			draw_line(base, base - along * 5.0 - normal * 5.0, Color("#fff2b7"), 2.0)
			draw_line(base, base + along * 5.0 - normal * 5.0, Color("#fff2b7"), 2.0)
			cursor += CHEVRON_SPACING_WU * _k()

class_name ItemSilhouettePainter
extends RefCounted

## Code-drawn placeholder presentation for the six first-batch families, in piece-local world units
## (footprint top-left is the origin). Every part first asks the family's `ItemVisualSet` for a
## replaceable slot and only falls back to a graybox shape when the slot is missing, so artists
## swap files without code. All shapes are PLACEHOLDER; nothing here is final art.

const INK := Color("#1d2930")
const PAPER := Color("#f6efd8")
const RUBBER := Color("#2f3438")
const HUB := Color("#b9b19a")
const AMBER := Color("#f2b84b")
const BEAM := Color("#ffe27a")
const SLATE := Color("#59707a")
const BUBBLE := Color("#bfe7f5")
const WOOD := Color("#9a6b3a")
const TAG_FONT_SIZE := 9


static func envelope(variant: ItemVariantDefinition, turns: int, tuning: GameplayTuning) -> Rect2:
	var size := (
		ItemGeometry.rotated_size(Vector2(variant.footprint_cells), turns) * tuning.grid_cell_wu
	)
	var result := Rect2(Vector2.ZERO, size)
	for region in ItemGeometry.resolve_regions(variant, turns, tuning):
		result = result.merge(region.rect)
	return result


static func draw_variant(
	canvas: CanvasItem,
	family: ItemFamilyDefinition,
	variant: ItemVariantDefinition,
	turns: int,
	tuning: GameplayTuning,
	state: Dictionary,
	tag: String = ""
) -> void:
	var regions := ItemGeometry.resolve_regions(variant, turns, tuning)
	var visual := family.visual_set
	var seconds := float(state.get("elapsed", 0.0))
	match family.preview_silhouette:
		"tire":
			_draw_tire(canvas, regions, visual, state, turns, seconds)
		"rail_top":
			_draw_rail(canvas, regions, visual, state, tuning, seconds)
		"parol":
			_draw_parol(canvas, regions, visual, state, tuning, seconds)
		"slipper":
			_draw_launcher(canvas, regions, visual, state, tuning, seconds)
		"broom":
			_draw_broom(canvas, regions, visual, state, seconds)
		"flower":
			_draw_flower(canvas, regions, visual, state, tuning, seconds)
	if tag != "":
		_draw_tag(canvas, tag, envelope(variant, turns, tuning))


static func _rects(regions: Array[Dictionary], kind: ItemRegionSpec.Kind) -> Array[Rect2]:
	var result: Array[Rect2] = []
	for region in regions:
		if region.kind == kind:
			result.append(region.rect)
	return result


static func _texture(visual: ItemVisualSet, slot: String, seconds: float) -> Texture2D:
	return visual.frame(slot, seconds) if visual != null else null


static func _draw_tag(canvas: CanvasItem, text: String, bounds: Rect2) -> void:
	var font := ThemeDB.fallback_font
	if font == null:
		return
	canvas.draw_string(
		font,
		bounds.position + Vector2(2.0, bounds.size.y + 11.0),
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		maxf(bounds.size.x, 240.0),
		TAG_FONT_SIZE,
		Color.WHITE
	)


static func _dotted(
	canvas: CanvasItem, from: Vector2, to: Vector2, color: Color, width: float, dash: float
) -> void:
	var length := from.distance_to(to)
	if length <= 0.01:
		return
	var direction := (to - from) / length
	var travelled := 0.0
	while travelled < length:
		var end := minf(travelled + dash, length)
		canvas.draw_line(from + direction * travelled, from + direction * end, color, width)
		travelled += dash * 2.0


# ---------------- Gulong Talon


static func _draw_tire(
	canvas: CanvasItem,
	regions: Array[Dictionary],
	visual: ItemVisualSet,
	state: Dictionary,
	turns: int,
	seconds: float
) -> void:
	var bodies := _rects(regions, ItemRegionSpec.Kind.SOLID)
	var compress := float(state.get("compress", 0.0))
	for body in bodies:
		var frames: Texture2D = _texture(
			visual, "body_compressed" if compress > 0.5 else "body", seconds
		)
		if frames != null:
			canvas.draw_set_transform(body.get_center(), float(turns) * PI * 0.5, Vector2.ONE)
			canvas.draw_texture_rect(frames, Rect2(-body.size * 0.5, body.size), false)
			canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		else:
			# Keep a clean silhouette if an art slot is missing; no debug footprint box or arrow.
			var center := body.get_center()
			var tire := Rect2(Vector2(-54.0, -42.0), Vector2(108.0, 38.0))
			var base := Rect2(Vector2(-31.0, 39.0), Vector2(62.0, 9.0))
			canvas.draw_set_transform(center, float(turns) * PI * 0.5, Vector2.ONE)
			canvas.draw_rect(tire, RUBBER, true)
			for coil in range(3):
				var y := 5.0 + float(coil) * 13.0
				canvas.draw_line(Vector2(-18.0, y), Vector2(18.0, y + 6.0), HUB, 5.0)
			canvas.draw_rect(base, Color("#b47b38"), true)
			canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# ---------------- Trumpo sa Riles


static func _draw_rail(
	canvas: CanvasItem,
	regions: Array[Dictionary],
	visual: ItemVisualSet,
	state: Dictionary,
	tuning: GameplayTuning,
	seconds: float
) -> void:
	var hit := tuning.item_trumpo_hit_wu
	for sweep in _rects(regions, ItemRegionSpec.Kind.SWEEP):
		var horizontal := sweep.size.x >= sweep.size.y
		var rail_tex: Texture2D = _texture(visual, "rail", seconds)
		if rail_tex != null:
			canvas.draw_texture_rect(rail_tex, sweep, false)
		else:
			var center := sweep.get_center()
			var half := hit * 0.5 + 2.0
			if horizontal:
				canvas.draw_line(
					Vector2(sweep.position.x, center.y - 3.0),
					Vector2(sweep.end.x, center.y - 3.0),
					SLATE,
					2.0
				)
				canvas.draw_line(
					Vector2(sweep.position.x, center.y + 3.0),
					Vector2(sweep.end.x, center.y + 3.0),
					SLATE,
					2.0
				)
			else:
				canvas.draw_line(
					Vector2(center.x - 3.0, sweep.position.y),
					Vector2(center.x - 3.0, sweep.end.y),
					SLATE,
					2.0
				)
				canvas.draw_line(
					Vector2(center.x + 3.0, sweep.position.y),
					Vector2(center.x + 3.0, sweep.end.y),
					SLATE,
					2.0
				)
			var cap_a := Rect2(
				sweep.position,
				Vector2(half, half) if not horizontal else Vector2(6.0, sweep.size.y)
			)
			var cap_b := Rect2(sweep.end - cap_a.size, cap_a.size)
			canvas.draw_rect(cap_a, INK)
			canvas.draw_rect(cap_b, INK)
			canvas.draw_rect(sweep, INK, false, 1.0)
	var top_pos: Vector2 = state.get("top_pos", Vector2.ZERO)
	if state.has("top_pos"):
		var paused := bool(state.get("paused", false))
		var spin := float(state.get("spin", 0.0))
		var top_tex: Texture2D = _texture(visual, "top", seconds)
		canvas.draw_set_transform(top_pos, spin, Vector2.ONE)
		if top_tex != null:
			canvas.draw_texture_rect(
				top_tex, Rect2(Vector2.ONE * hit * -0.5, Vector2.ONE * hit), false
			)
		else:
			var radius := hit * 0.5 * (0.8 if paused else 1.0)
			canvas.draw_circle(Vector2.ZERO, radius, AMBER)
			canvas.draw_circle(Vector2.ZERO, radius * 0.4, INK)
			for index in range(4):
				var spoke := Vector2.from_angle(TAU * float(index) / 4.0) * radius
				canvas.draw_line(Vector2.ZERO, spoke, INK, 2.0)
		canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if paused:
			canvas.draw_rect(
				Rect2(top_pos + Vector2(-5.0, -hit - 4.0), Vector2(3.0, 9.0)), Color.WHITE
			)
			canvas.draw_rect(
				Rect2(top_pos + Vector2(2.0, -hit - 4.0), Vector2(3.0, 9.0)), Color.WHITE
			)


# ---------------- Parol Pulse


static func _draw_parol(
	canvas: CanvasItem,
	regions: Array[Dictionary],
	visual: ItemVisualSet,
	state: Dictionary,
	tuning: GameplayTuning,
	seconds: float
) -> void:
	var phase := str(state.get("phase", "inactive"))
	var charge_t := float(state.get("charge_t", 0.0))
	var width := tuning.item_parol_beam_width_wu
	for beam in _rects(regions, ItemRegionSpec.Kind.EFFECT):
		var horizontal := beam.size.x >= beam.size.y
		var center := beam.get_center()
		var from := (
			Vector2(beam.position.x, center.y) if horizontal else Vector2(center.x, beam.position.y)
		)
		var to := Vector2(beam.end.x, center.y) if horizontal else Vector2(center.x, beam.end.y)
		match phase:
			"inactive":
				_dotted(canvas, from, to, Color(BEAM, 0.45), 2.0, 4.0)
			"charge":
				var line_width := lerpf(2.0, width * 0.7, charge_t)
				_dotted(canvas, from, to, Color(BEAM, lerpf(0.5, 0.9, charge_t)), line_width, 8.0)
			_:
				pass
	if phase == "active":
		var tex: Texture2D = _texture(visual, "beam_on", seconds)
		for segment in state.get("segments", []):
			var rect: Rect2 = segment
			if rect.size.x <= 0.0 or rect.size.y <= 0.0:
				continue
			if tex != null:
				canvas.draw_texture_rect(tex, rect, true)
			else:
				canvas.draw_rect(rect, Color(BEAM, 0.85))
				canvas.draw_rect(rect, INK, false, 2.0)
	for post in _rects(regions, ItemRegionSpec.Kind.SOLID):
		var post_tex: Texture2D = _texture(visual, "post", seconds)
		if post_tex != null:
			canvas.draw_texture_rect(post_tex, post, false)
			continue
		var c := post.get_center()
		var glow := 3.0 + 4.0 * charge_t + (6.0 if phase == "active" else 0.0)
		canvas.draw_rect(post, INK)
		canvas.draw_colored_polygon(
			PackedVector2Array(
				[
					c + Vector2(0, -12 - glow),
					c + Vector2(10 + glow, 0),
					c + Vector2(0, 12 + glow),
					c + Vector2(-10 - glow, 0)
				]
			),
			BEAM if phase != "inactive" else PAPER
		)
		canvas.draw_rect(post, SLATE, false, 2.0)


# ---------------- Tsinelas Launcher


static func _draw_launcher(
	canvas: CanvasItem,
	regions: Array[Dictionary],
	visual: ItemVisualSet,
	state: Dictionary,
	tuning: GameplayTuning,
	seconds: float
) -> void:
	var direction: Vector2 = state.get("lane_dir", Vector2.RIGHT)
	var charge_t := float(state.get("charge_t", 0.0))
	var origin: Vector2 = state.get("lane_origin", Vector2.ZERO)
	var full: float = float(state.get("lane_length", 0.0))
	var clipped: float = float(state.get("clipped_length", full))
	if full > 0.0:
		var lane_width := 2.0 + 4.0 * charge_t
		_dotted(
			canvas, origin, origin + direction * clipped, Color(Color.WHITE, 0.75), lane_width, 5.0
		)
		if clipped < full - 0.5:
			var stop := origin + direction * clipped
			var side := Vector2(-direction.y, direction.x) * 9.0
			canvas.draw_line(stop - side, stop + side, Color("#ef6a5b"), 3.0)
	for body in _rects(regions, ItemRegionSpec.Kind.SOLID):
		var tex_slot := "launcher_charge" if charge_t > 0.0 else "launcher"
		var tex: Texture2D = _texture(visual, tex_slot, seconds)
		if tex != null:
			canvas.draw_texture_rect(tex, body, false)
		else:
			canvas.draw_rect(body, SLATE)
			canvas.draw_rect(body, INK, false, 2.0)
			var recoil := charge_t * 5.0
			var barrel_start := body.get_center() + direction * (6.0 - recoil)
			canvas.draw_line(barrel_start, barrel_start + direction * 14.0, INK, 7.0)
			canvas.draw_line(barrel_start, barrel_start + direction * 14.0, AMBER, 3.0)
			if charge_t > 0.0:
				canvas.draw_circle(
					body.get_center() + Vector2(0, -body.size.y * 0.5 - 6.0),
					3.0 + 3.0 * charge_t,
					Color.WHITE
				)
	var size := tuning.item_launcher_projectile_size_wu
	var projectile_tex: Texture2D = _texture(visual, "projectile", seconds)
	for center_variant in state.get("projectiles", []):
		var center: Vector2 = center_variant
		var rect := Rect2(center - Vector2.ONE * size * 0.5, Vector2.ONE * size)
		if projectile_tex != null:
			canvas.draw_texture_rect(projectile_tex, rect, false)
		else:
			canvas.draw_rect(rect, Color("#e8896b"))
			canvas.draw_rect(rect, INK, false, 2.0)
			canvas.draw_line(rect.position + Vector2(3, 3), rect.end - Vector2(3, 3), INK, 2.0)


# ---------------- Walis Cleanup


static func _draw_broom(
	canvas: CanvasItem,
	regions: Array[Dictionary],
	visual: ItemVisualSet,
	state: Dictionary,
	seconds: float
) -> void:
	for area in _rects(regions, ItemRegionSpec.Kind.EFFECT):
		_dotted(canvas, area.position, Vector2(area.end.x, area.position.y), AMBER, 3.0, 8.0)
		_dotted(canvas, Vector2(area.end.x, area.position.y), area.end, AMBER, 3.0, 8.0)
		_dotted(canvas, area.end, Vector2(area.position.x, area.end.y), AMBER, 3.0, 8.0)
		_dotted(canvas, Vector2(area.position.x, area.end.y), area.position, AMBER, 3.0, 8.0)
		var tex: Texture2D = _texture(visual, "broom_outline", seconds)
		var sweep := 0.5 + 0.5 * sin(float(state.get("elapsed", 0.0)) * 3.0)
		var broom_center := area.position + Vector2(area.size.x * sweep, area.size.y * 0.5)
		if tex != null:
			canvas.draw_texture_rect(
				tex, Rect2(broom_center - Vector2(16, 16), Vector2(32, 32)), false
			)
		else:
			canvas.draw_line(
				broom_center + Vector2(-10, -18), broom_center + Vector2(6, 6), WOOD, 4.0
			)
			canvas.draw_rect(Rect2(broom_center + Vector2(-2, 4), Vector2(18, 12)), AMBER)
			canvas.draw_rect(Rect2(broom_center + Vector2(-2, 4), Vector2(18, 12)), INK, false, 2.0)
		canvas.draw_line(area.position, area.end, Color(INK, 0.5), 1.0)
		canvas.draw_line(
			Vector2(area.end.x, area.position.y),
			Vector2(area.position.x, area.end.y),
			Color(INK, 0.5),
			1.0
		)


# ---------------- Bula-Bulaklak


static func _draw_flower(
	canvas: CanvasItem,
	regions: Array[Dictionary],
	visual: ItemVisualSet,
	state: Dictionary,
	tuning: GameplayTuning,
	seconds: float
) -> void:
	for path in _rects(regions, ItemRegionSpec.Kind.EFFECT):
		var x := path.get_center().x
		_dotted(
			canvas,
			Vector2(x, path.end.y),
			Vector2(x, path.position.y),
			Color(BUBBLE, 0.9),
			2.0,
			5.0
		)
		var cursor := path.end.y - 12.0
		while cursor > path.position.y + 6.0:
			canvas.draw_line(
				Vector2(x, cursor), Vector2(x - 5, cursor + 6), Color(BUBBLE, 0.9), 2.0
			)
			canvas.draw_line(
				Vector2(x, cursor), Vector2(x + 5, cursor + 6), Color(BUBBLE, 0.9), 2.0
			)
			cursor -= 32.0
	for pot in _rects(regions, ItemRegionSpec.Kind.SOLID):
		var tex: Texture2D = _texture(visual, "pot", seconds)
		if tex != null:
			canvas.draw_texture_rect(tex, pot, false)
		else:
			canvas.draw_rect(Rect2(pot.position + Vector2(4, 12), pot.size - Vector2(8, 12)), WOOD)
			canvas.draw_rect(
				Rect2(pot.position + Vector2(4, 12), pot.size - Vector2(8, 12)), INK, false, 2.0
			)
			var head := pot.position + Vector2(pot.size.x * 0.5, 8.0)
			for index in range(6):
				canvas.draw_circle(
					head + Vector2.from_angle(TAU * float(index) / 6.0) * 6.0, 4.0, Color("#f08fb0")
				)
			canvas.draw_circle(head, 4.0, AMBER)
	if bool(state.get("has_bubble", false)):
		var center: Vector2 = state.get("bubble_pos", Vector2.ZERO)
		var radius := tuning.item_bubble_radius_wu
		var bubble_tex: Texture2D = _texture(visual, "bubble", seconds)
		if bubble_tex != null:
			canvas.draw_texture_rect(
				bubble_tex, Rect2(center - Vector2.ONE * radius, Vector2.ONE * radius * 2.0), false
			)
		else:
			canvas.draw_circle(center, radius, Color(BUBBLE, 0.35))
			canvas.draw_arc(center, radius, 0.0, TAU, 24, Color.WHITE, 2.0)
			canvas.draw_arc(center, radius * 0.6, -2.4, -1.2, 8, Color.WHITE, 2.0)
		if int(state.get("captive_seat", -1)) >= 0:
			var left := clampf(
				float(state.get("capture_left", 0.0)) / tuning.item_bubble_capture_s, 0.0, 1.0
			)
			canvas.draw_arc(center, radius + 5.0, -PI * 0.5, -PI * 0.5 + TAU * left, 24, AMBER, 3.0)

class_name ItemEggPreview
extends Control

## PLACEHOLDER egg preview: a code-drawn animated egg that shows the exact item variant inside,
## with no name or description text (the Library holds those). Final art is human-made.

signal claimed(variant_key: String)

const EGG_SIZE := Vector2(76.0, 96.0)
const LOOP_SECONDS := 2.0
const SILHOUETTE_BOX_WU := 44.0
const SELECT_COLOR := Color("#fff2b7")
const HAZARD_BOX_WU := Vector2(60.0, 52.0)
const HAZARD_MAX_SCALE := 0.6

var variant_key := ""
var quarter_turns := 0
var selected := false
var elapsed := 0.0
var _family: ItemFamilyDefinition
var _variant: ItemVariantDefinition
var _tuning: GameplayTuning
var _preview_behavior: ItemBehavior


func configure(
	definitions: ItemDefinitions, key: String, turns: int, source_tuning: GameplayTuning
) -> bool:
	var found := definitions.find_variant(key)
	if found.is_empty():
		return false
	variant_key = key
	quarter_turns = turns
	_family = found.family
	_variant = found.variant
	_tuning = source_tuning
	_preview_behavior = null
	if _family.preview_silhouette not in ["crate", "bamboo_bridge"]:
		_preview_behavior = ItemBehaviorFactory.create_preview(
			_family, _variant, turns, source_tuning
		)
	custom_minimum_size = EGG_SIZE + Vector2(8.0, 8.0)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE
	return true


## 0..1 position inside the looping animation; two samples a half loop apart differ.
func loop_phase() -> float:
	return fposmod(elapsed, LOOP_SECONDS) / LOOP_SECONDS


func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton
	if mouse != null and mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
		claimed.emit(variant_key)
		accept_event()


func _draw() -> void:
	if _variant == null:
		return
	var wobble := sin(loop_phase() * TAU)
	var center := custom_minimum_size * 0.5 + Vector2(0.0, wobble * 2.5)
	_draw_egg(center, selected)
	_draw_silhouette(center + Vector2(0.0, 6.0), wobble)


func _draw_egg(center: Vector2, highlight: bool) -> void:
	var points := PackedVector2Array()
	for step in range(33):
		var angle := float(step) / 32.0 * TAU
		var squash := 1.0 + 0.12 * sin(angle) if sin(angle) < 0.0 else 1.0
		points.append(
			center + Vector2(cos(angle) * EGG_SIZE.x * 0.5, sin(angle) * EGG_SIZE.y * 0.5 * squash)
		)
	draw_colored_polygon(points, Color("#f3ead2"))
	draw_polyline(
		points, SELECT_COLOR if highlight else Color("#5a4a2c"), 4.0 if highlight else 2.0
	)


func _draw_hazard_silhouette(center: Vector2) -> void:
	var envelope := ItemSilhouettePainter.envelope(_variant, quarter_turns, _tuning)
	var fit := minf(HAZARD_BOX_WU.x / envelope.size.x, HAZARD_BOX_WU.y / envelope.size.y)
	var scale_value := minf(fit, HAZARD_MAX_SCALE)
	var state := {"elapsed": elapsed}
	if _preview_behavior != null:
		_preview_behavior.preview_at(elapsed)
		state = _preview_behavior.readout()
	var offset := center - envelope.get_center() * scale_value
	draw_set_transform(offset, 0.0, Vector2(scale_value, scale_value))
	ItemSilhouettePainter.draw_variant(self, _family, _variant, quarter_turns, _tuning, state)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_silhouette(center: Vector2, wobble: float) -> void:
	if _family.preview_silhouette not in ["crate", "bamboo_bridge"]:
		_draw_hazard_silhouette(center)
		return
	var cells := ItemGeometry.rotated_size(Vector2(_variant.footprint_cells), quarter_turns)
	var scale := minf(SILHOUETTE_BOX_WU / (cells.x * 32.0), SILHOUETTE_BOX_WU / (cells.y * 32.0))
	scale = minf(scale, 0.6)
	var size_px := cells * 32.0 * scale
	var rect := Rect2(center - size_px * 0.5, size_px)
	if _family.preview_silhouette == "crate":
		draw_rect(rect, Color("#9a6b3a"))
		draw_rect(rect, Color("#2a1a0c"), false, 2.0)
		draw_line(rect.position, rect.end, Color("#5a3a18"), 2.0)
		draw_line(
			rect.position + Vector2(rect.size.x, 0.0),
			rect.position + Vector2(0.0, rect.size.y),
			Color("#5a3a18"),
			2.0
		)
		return
	# Bamboo bridge: dashed reservation, thin strip on its one-way side, pulsing arrow.
	draw_rect(rect, Color("#cfe8a0"), false, 1.0)
	var normal := ItemGeometry.rotate_vector(Vector2.UP, quarter_turns)
	var strip := rect
	if absf(normal.y) > 0.5:
		strip.size.y = maxf(3.0, 4.0 * scale)
		if normal.y > 0.0:
			strip.position.y = rect.end.y - strip.size.y
	else:
		strip.size.x = maxf(3.0, 4.0 * scale)
		if normal.x > 0.0:
			strip.position.x = rect.end.x - strip.size.x
	draw_rect(strip, Color("#c9b43c"))
	var along := Vector2(-normal.y, normal.x)
	var tip := rect.get_center() + normal * (6.0 + wobble * 3.0)
	var tail := rect.get_center() - normal * 4.0
	draw_line(tail, tip, Color("#1d2930"), 3.0)
	draw_line(tip, tip - normal * 5.0 + along * 4.0, Color("#1d2930"), 3.0)
	draw_line(tip, tip - normal * 5.0 - along * 4.0, Color("#1d2930"), 3.0)

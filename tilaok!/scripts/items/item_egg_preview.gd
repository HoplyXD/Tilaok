# gdlint: disable=max-returns
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

## Silhouettes drawn here as simple shapes; every other family uses ItemSilhouettePainter.
const BOX_SILHOUETTES := ["crate", "bamboo_bridge", "solid_block", "wood_box", "collapsing_block"]


class PreviewCanvas extends Node2D:
	var family: ItemFamilyDefinition
	var variant: ItemVariantDefinition
	var quarter_turns := 0
	var tuning: GameplayTuning
	var behavior: ItemBehavior
	var elapsed := 0.0


	func _draw() -> void:
		if family == null or variant == null or tuning == null:
			return
		var state := {"elapsed": elapsed}
		if behavior != null:
			behavior.preview_at(elapsed)
			state = behavior.readout()
		ItemSilhouettePainter.draw_variant(
			self, family, variant, quarter_turns, tuning, state
		)

## False skips the code-drawn shell, for an egg card that draws the team's egg art behind the item.
@export var draw_shell := true

var variant_key := ""
var quarter_turns := 0
var selected := false
var elapsed := 0.0
var _family: ItemFamilyDefinition
var _variant: ItemVariantDefinition
var _tuning: GameplayTuning
var _preview_behavior: ItemBehavior
var _barya_preview := false
## Scene-authored blocks ("scene" silhouette): a copy of the block scene's own Visual node.
var _scene_visual: Node2D
## Separate canvas lets Node2D scale the preview while painter-local rotations/transforms are used.
var _preview_canvas: PreviewCanvas


func configure(
	definitions: ItemDefinitions, key: String, turns: int, source_tuning: GameplayTuning
) -> bool:
	_clear_preview_canvas()
	if _scene_visual != null and is_instance_valid(_scene_visual):
		_scene_visual.visible = false
		_scene_visual.queue_free()
	_scene_visual = null
	if BaryaObjectiveDefinition.is_variant(key):
		variant_key = key
		quarter_turns = turns
		_tuning = source_tuning
		_family = null
		_variant = null
		_preview_behavior = null
		_barya_preview = true
		custom_minimum_size = EGG_SIZE + Vector2(8.0, 8.0)
		size = custom_minimum_size
		mouse_filter = Control.MOUSE_FILTER_STOP
		focus_mode = Control.FOCUS_NONE
		queue_redraw()
		return true
	var found := definitions.find_variant(key)
	if found.is_empty():
		return false
	_barya_preview = false
	variant_key = key
	quarter_turns = turns
	_family = found.family
	_variant = found.variant
	_tuning = source_tuning
	_preview_behavior = null
	if _family.preview_silhouette == BlockCatalog.SCENE_PREVIEW:
		_add_scene_visual()
	elif _family.preview_silhouette not in BOX_SILHOUETTES:
		_preview_behavior = ItemBehaviorFactory.create_preview(
			_family, _variant, turns, source_tuning
		)
		_preview_canvas = PreviewCanvas.new()
		_preview_canvas.name = "PreviewCanvas"
		_preview_canvas.family = _family
		_preview_canvas.variant = _variant
		_preview_canvas.quarter_turns = turns
		_preview_canvas.tuning = source_tuning
		_preview_canvas.behavior = _preview_behavior
		add_child(_preview_canvas)
	custom_minimum_size = EGG_SIZE + Vector2(8.0, 8.0)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE
	return true


func _add_scene_visual() -> void:
	_scene_visual = BlockCatalog.preview_visual(_variant)
	if _scene_visual == null:
		return
	var box := ItemGeometry.rotated_size(Vector2(_variant.footprint_cells), quarter_turns) * 64.0
	var fit := minf(HAZARD_BOX_WU.x / box.x, HAZARD_BOX_WU.y / box.y)
	_scene_visual.scale = Vector2.ONE * minf(fit, HAZARD_MAX_SCALE)
	_scene_visual.rotation = float(ItemGeometry.normalized_turns(quarter_turns)) * PI * 0.5
	_scene_visual.position = (EGG_SIZE + Vector2(8.0, 8.0)) * 0.5 + Vector2(0.0, 6.0)
	add_child(_scene_visual)


## 0..1 position inside the looping animation; two samples a half loop apart differ.
func loop_phase() -> float:
	return fposmod(elapsed, LOOP_SECONDS) / LOOP_SECONDS


func _process(delta: float) -> void:
	elapsed += delta
	if _preview_canvas != null:
		_preview_canvas.elapsed = elapsed
		_preview_canvas.queue_redraw()
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton
	if mouse != null and mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
		claimed.emit(variant_key)
		accept_event()


func _draw() -> void:
	if _barya_preview:
		var center := custom_minimum_size * 0.5
		if draw_shell:
			_draw_egg(center, selected)
		draw_circle(center + Vector2(0.0, 8.0), 17.0, Color("#f4c95d"))
		draw_circle(center + Vector2(0.0, 8.0), 12.0, Color("#8b5421"))
		var font := ThemeDB.fallback_font
		if font != null:
			draw_string(
				font,
				center + Vector2(-4.0, 12.0),
				"B",
				HORIZONTAL_ALIGNMENT_CENTER,
				10.0,
				13,
				Color("#fff6cf")
			)
		return
	if _variant == null:
		return
	var wobble := sin(loop_phase() * TAU)
	var center := custom_minimum_size * 0.5 + Vector2(0.0, wobble * 2.5)
	if draw_shell:
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
	if _preview_canvas == null:
		return
	var envelope := ItemSilhouettePainter.envelope(_variant, quarter_turns, _tuning)
	var fit := minf(HAZARD_BOX_WU.x / envelope.size.x, HAZARD_BOX_WU.y / envelope.size.y)
	var scale_value := minf(fit, HAZARD_MAX_SCALE)
	_preview_canvas.position = center - envelope.get_center() * scale_value
	_preview_canvas.scale = Vector2.ONE * scale_value
	_preview_canvas.visible = true


func _clear_preview_canvas() -> void:
	if _preview_canvas != null and is_instance_valid(_preview_canvas):
		_preview_canvas.visible = false
		_preview_canvas.queue_free()
	_preview_canvas = null


func _draw_silhouette(center: Vector2, wobble: float) -> void:
	if _scene_visual != null:
		_scene_visual.position = center
		return
	if _family.preview_silhouette == BlockCatalog.SCENE_PREVIEW:
		return
	if _family.preview_silhouette not in BOX_SILHOUETTES:
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
	match _family.preview_silhouette:
		"solid_block":
			draw_rect(rect, Color("#6e7580"))
			draw_line(
				rect.position + Vector2(0.0, rect.size.y * 0.5),
				rect.position + Vector2(rect.size.x, rect.size.y * 0.5),
				Color("#4c525a"),
				2.0
			)
			draw_rect(rect, Color("#212429"), false, 2.0)
			return
		"wood_box":
			draw_rect(rect, Color("#b8803f"))
			draw_line(rect.position, rect.end, Color("#7a4f24"), 3.0)
			draw_line(
				rect.position + Vector2(rect.size.x, 0.0),
				rect.position + Vector2(0.0, rect.size.y),
				Color("#7a4f24"),
				3.0
			)
			draw_rect(rect, Color("#2b1a0a"), false, 2.0)
			return
		"collapsing_block":
			var crumble := rect.grow(-wobble * 1.5)
			draw_rect(crumble, Color("#d9ba85"))
			draw_polyline(
				PackedVector2Array(
					[
						crumble.position + Vector2(crumble.size.x * 0.2, 0.0),
						crumble.get_center() + Vector2(-2.0, 0.0),
						crumble.position + Vector2(crumble.size.x * 0.6, crumble.size.y),
					]
				),
				Color("#5c3f1e"),
				2.0
			)
			draw_rect(crumble, Color("#5c3f1e"), false, 2.0)
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

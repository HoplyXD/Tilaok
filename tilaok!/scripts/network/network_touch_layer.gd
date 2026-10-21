class_name NetworkTouchLayer
extends Control

## NLB-P10 phone touch layer. Every finger (touch index) is owned by exactly one control or zone
## from press to release: a left Move zone and a right Aim zone are independent, so a player can
## move while aiming, rotating or placing. Releasing outside the zone still releases the finger, a
## finger that lands on nothing is ignored (palms, dead margin) and focus loss releases everything.
## It only emits signals; the presentation maps them to wire actions. Code-drawn placeholders: the
## final look is Shanti's design pass.

signal control_pressed(control_id: String)
signal control_released(control_id: String)
signal move_changed(direction: Vector2i)
signal aim_changed(direction: Vector2)

const ZONE_MOVE := "zone_move"
const ZONE_AIM := "zone_aim"
## PROPOSED drag dead zone, in dp. Unmeasured until NLB-P10-T03.
const DEAD_ZONE_DP := 14.0
## Desktop tests and captures drive the layer with the mouse as this pseudo touch index.
const MOUSE_INDEX := 99

## Desktop test or capture only: also treat the left mouse button as a finger.
var accept_mouse := false
var live_route := false
var layout: Dictionary = {}
var _owners: Dictionary = {}
var _enabled: Dictionary = {}
var _labels := {
	"jump": "Jump", "sneak": "Sneak", "cheer": "Cheer", "claim": "Claim / OK", "back": "Back",
	"pause": "Menu", "build": "Build", "rotate": "Rotate", "place": "Place", "cancel": "Cancel",
}
var _move_direction := Vector2i.ZERO
var _aim_direction := Vector2.ZERO
var _dpi_override := 0.0
var _safe_override := Rect2()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var viewport := get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(_on_viewport_resized):
		viewport.size_changed.connect(_on_viewport_resized)
	relayout()


func _notification(what: int) -> void:
	if (
		what == NOTIFICATION_APPLICATION_FOCUS_OUT
		or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT
		or what == NOTIFICATION_EXIT_TREE
	):
		release_all()
	elif what == NOTIFICATION_VISIBILITY_CHANGED and not visible:
		release_all()


func _input(event: InputEvent) -> void:
	if handle_event(event):
		get_viewport().set_input_as_handled()


## Tests inject a fixed dpi and safe rect so the layout is deterministic.
func set_environment(dpi: float, safe_rect: Rect2) -> void:
	_dpi_override = dpi
	_safe_override = safe_rect


func configure(live: bool) -> void:
	if live == live_route and not layout.is_empty():
		return
	release_all()
	live_route = live
	relayout()


func relayout() -> void:
	var viewport := get_viewport_rect().size if is_inside_tree() else Vector2(1280, 720)
	relayout_for(viewport, Vector2(DisplayServer.window_get_size()))


func relayout_for(viewport: Vector2, window: Vector2) -> void:
	var dpi := _dpi_override if _dpi_override > 0.0 else float(DisplayServer.screen_get_dpi())
	var safe := _safe_override if _safe_override.has_area() else _platform_safe_rect(viewport, window)
	layout = TouchLayout.compute(viewport, safe, dpi, window, live_route)
	queue_redraw()


func set_button_enabled(control_id: String, enabled: bool) -> void:
	if bool(_enabled.get(control_id, true)) == enabled:
		return
	_enabled[control_id] = enabled
	if not enabled:
		_release_owned_by(control_id)
	queue_redraw()


func set_button_label(control_id: String, text: String) -> void:
	if _labels.get(control_id, "") != text:
		_labels[control_id] = text
		queue_redraw()


## True while any finger owns the control or zone.
func is_held(control_id: String) -> bool:
	for finger in _owners.values():
		if finger.id == control_id:
			return true
	return false


func owner_of(index: int) -> String:
	return str(_owners[index].id) if _owners.has(index) else ""


func owner_count() -> int:
	return _owners.size()


func dead_zone_px() -> float:
	return DEAD_ZONE_DP * float(layout.get("dp_px", 1.0))


## Routes one event. Returns true when a finger owns the event (so it never reaches another layer).
func handle_event(event: InputEvent) -> bool:
	if not visible or layout.is_empty():
		return false
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed and not touch.canceled:
			return _press(touch.index, touch.position)
		return _release(touch.index)
	if event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		return _drag(drag.index, drag.position)
	if accept_mouse and event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		if button.button_index == MOUSE_BUTTON_LEFT:
			return _press(MOUSE_INDEX, button.position) if button.pressed else _release(MOUSE_INDEX)
	elif accept_mouse and event is InputEventMouseMotion:
		return _drag(MOUSE_INDEX, (event as InputEventMouseMotion).position)
	return false


## Releases every finger: buttons emit control_released, zones return to neutral.
func release_all() -> void:
	var owners := _owners.duplicate()
	_owners.clear()
	for finger in owners.values():
		if bool(finger.fired):
			control_released.emit(str(finger.id))
	_refresh_zone_outputs()
	queue_redraw()


func _press(index: int, position: Vector2) -> bool:
	if _owners.has(index):
		return true
	var hit := _hit(position)
	if hit.is_empty():
		return false
	var finger := {"id": hit, "origin": position, "position": position, "fired": false}
	if hit == ZONE_MOVE or hit == ZONE_AIM:
		# A second finger in an already-owned zone is swallowed and ignored.
		if is_held(hit):
			return true
		_owners[index] = finger
		_refresh_zone_outputs()
	else:
		_owners[index] = finger
		# A disabled button still owns the finger so it cannot slide onto a neighbour.
		if bool(_enabled.get(hit, true)):
			finger.fired = true
			control_pressed.emit(hit)
	queue_redraw()
	return true


func _drag(index: int, position: Vector2) -> bool:
	if not _owners.has(index):
		return false
	_owners[index].position = position
	_refresh_zone_outputs()
	queue_redraw()
	return true


func _release(index: int) -> bool:
	if not _owners.has(index):
		return false
	var finger: Dictionary = _owners[index]
	_owners.erase(index)
	if bool(finger.fired):
		control_released.emit(str(finger.id))
	_refresh_zone_outputs()
	queue_redraw()
	return true


func _release_owned_by(control_id: String) -> void:
	for index in _owners.keys():
		if _owners[index].id == control_id:
			_release(int(index))


func _hit(position: Vector2) -> String:
	var buttons: Dictionary = layout.get("buttons", {})
	for control_id in buttons:
		if (buttons[control_id] as Rect2).has_point(position):
			return str(control_id)
	if (layout.get("move_zone", Rect2()) as Rect2).has_point(position):
		return ZONE_MOVE
	if (layout.get("aim_zone", Rect2()) as Rect2).has_point(position):
		return ZONE_AIM
	return ""


func _refresh_zone_outputs() -> void:
	var move := Vector2i.ZERO
	var aim := Vector2.ZERO
	var dead := dead_zone_px()
	for finger in _owners.values():
		var delta: Vector2 = finger.position - finger.origin
		var direction := Vector2i(_axis(delta.x, dead), _axis(delta.y, dead))
		if finger.id == ZONE_MOVE:
			move = direction
		elif finger.id == ZONE_AIM and bool(_enabled.get(ZONE_AIM, true)):
			aim = Vector2(direction)
	if move != _move_direction:
		_move_direction = move
		move_changed.emit(move)
	if aim != _aim_direction:
		_aim_direction = aim
		aim_changed.emit(aim)


func _axis(value: float, dead: float) -> int:
	if absf(value) < dead:
		return 0
	return 1 if value > 0.0 else -1


## Android reports the cutout/gesture-safe area in window pixels; elsewhere the whole viewport is safe.
func _platform_safe_rect(viewport: Vector2, window: Vector2) -> Rect2:
	if not OS.has_feature("android") or window.x <= 0.0 or window.y <= 0.0:
		return Rect2()
	var area := Rect2(DisplayServer.get_display_safe_area())
	var scale := Vector2(viewport.x / window.x, viewport.y / window.y)
	return Rect2(area.position * scale, area.size * scale)


func _on_viewport_resized() -> void:
	# An orientation or window change invalidates every finger's origin.
	release_all()
	relayout()


func _draw() -> void:
	if layout.is_empty():
		return
	var font := ThemeDB.fallback_font
	var font_size := maxi(16, int(float(layout.button_px) * 0.22))
	_draw_zone(layout.move_zone, "MOVE", ZONE_MOVE, font, font_size)
	if live_route:
		_draw_zone(layout.aim_zone, "AIM", ZONE_AIM, font, font_size)
	var buttons: Dictionary = layout.buttons
	for control_id in buttons:
		var rect: Rect2 = buttons[control_id]
		var enabled := bool(_enabled.get(control_id, true))
		var held := is_held(str(control_id))
		draw_rect(rect, Color(0.09, 0.14, 0.17, 0.85 if enabled else 0.45), true)
		if held:
			draw_rect(rect.grow(-4.0), Color(1.0, 1.0, 1.0, 0.25), true)
		# Disabled controls change outline (dashed) and keep their text: never colour alone.
		if enabled:
			draw_rect(rect, Color.WHITE, false, 5.0 if held else 3.0)
		else:
			_draw_dashed_outline(rect)
		var text := str(_labels.get(control_id, control_id))
		var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var text_color := Color.WHITE if enabled else Color(1, 1, 1, 0.6)
		draw_string(font, rect.position + Vector2((rect.size.x - width) * 0.5, rect.size.y * 0.5 + font_size * 0.35), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_color)


func _draw_zone(rect: Rect2, label: String, zone_id: String, font: Font, font_size: int) -> void:
	draw_rect(rect, Color(1, 1, 1, 0.06), true)
	_draw_dashed_outline(rect)
	draw_string(font, rect.position + Vector2(10, font_size + 6), label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(1, 1, 1, 0.7))
	for finger in _owners.values():
		if finger.id == zone_id:
			draw_arc(finger.origin, dead_zone_px() * 2.0, 0.0, TAU, 28, Color.WHITE, 3.0)
			draw_circle(finger.position, dead_zone_px(), Color(1, 1, 1, 0.6))


func _draw_dashed_outline(rect: Rect2) -> void:
	var corners := [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]
	for index in corners.size():
		draw_dashed_line(corners[index], corners[(index + 1) % corners.size()], Color(1, 1, 1, 0.7), 2.0, 8.0)

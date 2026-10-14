class_name ScoreboardChart
extends Control

const COLUMN_SCENE := preload("res://scenes/ui/components/score_column.tscn")
const AXIS_LEFT := 52.0
const AXIS_RIGHT_MARGIN := 8.0
const PLOT_TOP := 58.0
const BASELINE_BOTTOM_MARGIN := 112.0
const TICK_UNITS := 16

var _columns: Array[ScoreColumn] = []
var _rows: Array[Dictionary] = []
var _active_column_count := 0
var _target_units := 80
var _axis_max_units := 88
var _plot_height := 200.0
var _result_identity := ""
var _motion_mode := PresentationSettings.RESULT_REVEAL_NORMAL
var _elapsed := 0.0
var _reveal_duration := 0.0
var _fade_elapsed := 0.0
var _is_revealing := false


func bind_model(
	model: MatchResultsViewModel,
	seats: Array[Dictionary],
	motion_mode: int = PresentationSettings.RESULT_REVEAL_NORMAL
) -> void:
	var rows: Array = model.score_presentation.get("seats", [])
	bind_rows(rows, model.target_score_units, model.score_presentation_id, seats, motion_mode)


func bind_rows(
	rows: Array,
	target_units: int,
	result_identity: String,
	seats: Array[Dictionary] = [],
	motion_mode: int = PresentationSettings.RESULT_REVEAL_NORMAL
) -> void:
	var same_result := result_identity == _result_identity and not result_identity.is_empty()
	if not same_result:
		_elapsed = 0.0
		_fade_elapsed = 0.0
	_rows.clear()
	for raw_variant in rows:
		if not raw_variant is Dictionary:
			continue
		var row: Dictionary = raw_variant.duplicate(true)
		var seat_index := int(row.get("seat_index", -1))
		var seat := _seat_for(seats, seat_index)
		if not seat.is_empty():
			row["identity"] = int(seat.get("identity", row.get("identity", 0)))
			row["shape"] = str(seat.get("shape", row.get("shape", "")))
			row["color"] = seat.get("color", row.get("color", Color.WHITE))
			if not bool(seat.get("joined", true)):
				continue
		_rows.append(row)
	_rows.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			return int(a.get("seat_index", -1)) < int(b.get("seat_index", -1))
	)
	_active_column_count = mini(_rows.size(), PlayerSeatRegistry.MAX_SEATS)
	if _rows.size() > PlayerSeatRegistry.MAX_SEATS:
		_rows.resize(PlayerSeatRegistry.MAX_SEATS)
	_target_units = maxi(target_units, 1)
	_motion_mode = clampi(
		motion_mode,
		PresentationSettings.RESULT_REVEAL_NORMAL,
		PresentationSettings.RESULT_REVEAL_OFF
	)
	_result_identity = result_identity
	_rebuild_columns(same_result)
	_compute_scale()
	_layout_columns()
	if same_result:
		for index in _active_column_count:
			_columns[index].set_reveal_elapsed(_elapsed)
	else:
		_start_reveal()
	queue_redraw()


func settle() -> void:
	_elapsed = _reveal_duration
	_fade_elapsed = 0.18
	_is_revealing = false
	modulate.a = 1.0
	for column in _columns:
		if column.visible:
			column.settle()
	set_process(false)


func result_identity() -> String:
	return _result_identity


func axis_max_units() -> int:
	return _axis_max_units


func target_units() -> int:
	return _target_units


func chart_columns() -> Array[ScoreColumn]:
	var active: Array[ScoreColumn] = []
	for column in _columns:
		if column.visible:
			active.append(column)
	return active


func is_revealing() -> bool:
	return _is_revealing


func reveal_elapsed_seconds() -> float:
	return _elapsed


func _process(delta: float) -> void:
	if _is_revealing:
		_elapsed = minf(_elapsed + delta, _reveal_duration)
		for index in _active_column_count:
			_columns[index].set_reveal_elapsed(_elapsed)
		if _elapsed >= _reveal_duration:
			_is_revealing = false
	if _motion_mode == PresentationSettings.RESULT_REVEAL_REDUCED and _fade_elapsed < 0.18:
		_fade_elapsed = minf(_fade_elapsed + delta, 0.18)
		modulate.a = lerpf(0.7, 1.0, _fade_elapsed / 0.18)
	if not _is_revealing and _fade_elapsed >= 0.18:
		set_process(false)


func _draw() -> void:
	if _rows.is_empty():
		return
	var axis_x := AXIS_LEFT
	var right := maxf(size.x - AXIS_RIGHT_MARGIN, axis_x + 1.0)
	var top := PLOT_TOP
	var baseline := size.y - BASELINE_BOTTOM_MARGIN
	var plot_height := maxf(baseline - top, 1.0)
	var axis_color := get_theme_color("guide", "ScoreAxis")
	var text_color := get_theme_color("label", "ScoreAxis")
	var baseline_color := get_theme_color("baseline", "ScoreAxis")
	var font := get_theme_default_font()
	var font_size := 13
	for units in range(0, _axis_max_units + 1, TICK_UNITS):
		var y := baseline - float(units) * plot_height / float(_axis_max_units)
		draw_line(Vector2(axis_x, y), Vector2(right, y), axis_color, 1.0)
		draw_string(
			font,
			Vector2(1.0, y + font_size * 0.35),
			ScoreFormat.format_units(units),
			HORIZONTAL_ALIGNMENT_LEFT,
			AXIS_LEFT - 7.0,
			font_size,
			text_color
		)
	var target_y := baseline - float(_target_units) * plot_height / float(_axis_max_units)
	draw_line(
		Vector2(axis_x, target_y),
		Vector2(right, target_y),
		get_theme_color("target", "ScoreAxis"),
		2.0
	)
	var target_text := "TARGET %s" % ScoreFormat.format_units(_target_units)
	draw_string(
		font,
		Vector2(axis_x + 6.0, target_y - 5.0),
		target_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		get_theme_color("target", "ScoreAxis")
	)
	draw_line(Vector2(axis_x, baseline), Vector2(right, baseline), baseline_color, 3.0)


func _rebuild_columns(preserve_elapsed: bool) -> void:
	var elapsed := _elapsed if preserve_elapsed else 0.0
	for index in _columns.size():
		var column := _columns[index]
		column.visible = index < _active_column_count
		if column.visible:
			column.bind_row(
				_rows[index], _axis_max_units, _plot_height, 48.0, _motion_mode, elapsed
			)


func _compute_scale() -> void:
	var highest := 0
	for row in _rows:
		highest = maxi(highest, int(row.get("units", 0)))
	_axis_max_units = maxi(_target_units, highest) + 8


func _layout_columns() -> void:
	if not is_node_ready():
		return
	var baseline := maxf(size.y - BASELINE_BOTTOM_MARGIN, PLOT_TOP + 80.0)
	_plot_height = maxf(baseline - PLOT_TOP, 1.0)
	var left := AXIS_LEFT
	var right := maxf(size.x - AXIS_RIGHT_MARGIN, left + 1.0)
	var slot_width := (right - left) / float(maxi(_active_column_count, 1))
	var column_width := minf(maxf(slot_width - 8.0, 48.0), 152.0)
	var bar_width := clampf(slot_width * 0.34, 28.0, 52.0)
	for index in _active_column_count:
		var column := _columns[index]
		column.position = Vector2(
			left + slot_width * (float(index) + 0.5) - column_width * 0.5, PLOT_TOP
		)
		column.size = Vector2(column_width, size.y - PLOT_TOP)
		column.set_chart_layout(_plot_height, bar_width, _axis_max_units)
	queue_redraw()


func _start_reveal() -> void:
	_reveal_duration = 0.0
	for index in _active_column_count:
		_reveal_duration = maxf(_reveal_duration, _columns[index].reveal_duration())
	_reveal_duration = minf(_reveal_duration, 2.4)
	if _motion_mode == PresentationSettings.RESULT_REVEAL_NORMAL and _reveal_duration > 0.0:
		_is_revealing = true
		for index in _active_column_count:
			_columns[index].set_reveal_elapsed(0.0)
		set_process(true)
	elif _motion_mode == PresentationSettings.RESULT_REVEAL_REDUCED:
		_is_revealing = false
		for index in _active_column_count:
			_columns[index].settle()
		modulate.a = 0.7
		_fade_elapsed = 0.0
		set_process(true)
	else:
		_is_revealing = false
		modulate.a = 1.0
		for index in _active_column_count:
			_columns[index].settle()
		set_process(false)


func _seat_for(seats: Array[Dictionary], seat_index: int) -> Dictionary:
	for seat in seats:
		if int(seat.get("seat", -1)) == seat_index:
			return seat
	return {}


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_columns()


func _ready() -> void:
	for _index in PlayerSeatRegistry.MAX_SEATS:
		var column := COLUMN_SCENE.instantiate() as ScoreColumn
		column.visible = false
		add_child(column)
		_columns.append(column)


func _exit_tree() -> void:
	_is_revealing = false
	set_process(false)

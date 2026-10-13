class_name MatchResultsPanel
extends PanelContainer

var _column: VBoxContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	size = Vector2(680.0, 460.0)
	position = (get_viewport_rect().size - size) * 0.5
	_column = VBoxContainer.new()
	_column.add_theme_constant_override("separation", 8)
	add_child(_column)


func show_results(model: MatchResultsViewModel) -> void:
	for child in _column.get_children():
		child.queue_free()
	_add_label("ROUND %d RESULTS • DEBUG" % model.round_number, 22)
	_add_label(model.diagnostic_label, 16)
	_add_label("Seat outcomes", 15)
	for outcome in model.per_seat_outcomes:
		_add_label("P%d %s — %s" % [outcome.identity, outcome.shape, outcome.outcome], 13)
	_add_label("Award rows: %d (provided by P06)" % model.award_rows.size(), 13)
	_add_label("Score explanation: %s" % model.suppression_reason, 13)
	_add_label("Totals: %s" % str(model.totals), 13)
	_add_label("Press your confirm button to ready. Next round also starts in 8 seconds.", 14)


func _add_label(text_value: String, font_size: int) -> void:
	var label := Label.new()
	label.text = text_value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	_column.add_child(label)

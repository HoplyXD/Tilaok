class_name MatchResultsPanel
extends PanelContainer

var _column: VBoxContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	size = Vector2(720.0, 560.0)
	position = (get_viewport_rect().size - size) * 0.5
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)
	_column = VBoxContainer.new()
	_column.add_theme_constant_override("separation", 8)
	_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(_column)


func show_results(model: MatchResultsViewModel) -> void:
	for child in _column.get_children():
		child.queue_free()
	_add_label("ROUND %d RESULTS" % model.round_number, 22)
	_add_label(model.diagnostic_label, 16)
	_add_label(model.deadline_explanation, 13)
	_add_label("Outcomes and round score", 15)
	for outcome in model.per_seat_outcomes:
		_add_label(
			(
				"P%d %s — %s · round %s · total %s"
				% [
					outcome.identity,
					outcome.shape,
					outcome.outcome,
					outcome.score_delta_text,
					outcome.total_text
				]
			),
			13
		)
	_add_label("Award details", 15)
	if model.award_rows.is_empty():
		_add_label("No awards this round.", 13)
	else:
		for award in model.award_rows:
			_add_label(
				(
					"P%d %s — %s %s · %s"
					% [
						award.identity,
						award.shape,
						award.title,
						award.score_text,
						award.explanation
					]
				),
				13
			)
	_add_label("Scoring: %s" % model.suppression_reason, 13)
	_add_label("Press your confirm button to ready. Next round also starts in 8 seconds.", 14)


func _add_label(text_value: String, font_size: int) -> void:
	var label := Label.new()
	label.text = text_value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	_column.add_child(label)

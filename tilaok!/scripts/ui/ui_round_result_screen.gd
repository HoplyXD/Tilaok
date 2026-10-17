class_name UiRoundResultScreen
extends UiScreen

signal continue_requested(seat_index: int)

## Above this many award rows only title + points are shown so the breakdown remains readable.
const EXPLAINED_AWARD_ROWS := 6
## Clear space between the title (and Last Cluck callout) and an end reason tucked beside it.
const TITLE_REASON_GAP := 14.0
## How much award explanation the Awards column shows; see _show_awards.
enum { EXPLAIN_ALL, EXPLAIN_ONCE, EXPLAIN_NONE }
## Deferred hops _refit_when_sorted waits for the container sorts queued ahead of it.
const FIT_HOPS := 12
## UI Gallery sample copy, worded as the live view model words it.
const SAMPLE_END_REASON := "Every player finished or was eliminated."
const SAMPLE_DEADLINE := "Race limit 60 s; after the first finish, remaining runners had 15 s."

var award_lines: Array[UiAwardLine] = []
var _next_round_raw := ""
## One entry per award line: seat, key, text (title + points), explanation, explained.
var _award_binds: Array[Dictionary] = []

@onready var _safe: MarginContainer = %Safe
@onready var _content: VBoxContainer = %Content
@onready var _title_block: VBoxContainer = %TitleBlock
@onready var _title_row: HBoxContainer = %TitleRow
@onready var _columns: HBoxContainer = %Columns
@onready var _awards: VBoxContainer = %Awards
@onready var _legend_heading: Label = %LegendHeading
@onready var _legend_margin: MarginContainer = %LegendMargin
@onready var _round_label: Label = %RoundLabel
@onready var _end_reason_label: Label = %EndReasonLabel
@onready var _deadline_label: Label = %DeadlineLabel
@onready var _last_cluck_callout: Label = %LastCluckCallout
@onready var _twist_line: Label = %TwistLine
@onready var _next_round_caption: Label = %NextRoundCaption
@onready var _next_round_label: Label = %NextRoundLabel
@onready var _legend: ScoreAwardLegend = %ScoreAwardLegend
@onready var _no_score_reason: UiToastLine = %NoScoreReason
@onready var _ready_hint: UiPromptGlyph = %ReadyHint
@onready var _advance: UiCountdownRing = %AdvanceCountdown
@onready var _tutorial_strip: Control = %TutorialStrip
@onready var _chart: ScoreboardChart = %ScoreChart


func state_names() -> PackedStringArray:
	return PackedStringArray(["Normal", "Nobody finished", "Everybody finished", "2-player waived"])


## Keeps a free strip at the right edge while the tutorial Results box is shown, so the box
## never covers chart content or an award line. Zero width removes the strip.
func reserve_side_strip(width: float) -> void:
	_tutorial_strip.visible = width > 0.0
	_tutorial_strip.custom_minimum_size = Vector2(maxf(width, 0.0), 0.0)


func router_phase() -> int:
	return LocalInputRouter.Phase.RESULTS


func bind_result(sample: UiSampleMatch, seats: Array[Dictionary], reason: String) -> void:
	_round_label.text = "Round %d Result" % sample.round_number
	_end_reason_label.text = SAMPLE_END_REASON
	_end_reason_label.visible = true
	_deadline_label.text = SAMPLE_DEADLINE
	_deadline_label.visible = true
	_show_next_round("NEXT R%d KARERA" % (sample.round_number + 1))
	var chart_rows: Array[Dictionary] = []
	for index in seats.size():
		var seat: Dictionary = seats[index]
		if not bool(seat.get("joined", false)):
			continue
		var total_units := (
			roundi(float(sample.scores[index]) * 8.0) if index < sample.scores.size() else 0
		)
		var delta_units := (
			roundi(float(sample.outcome_points[index]) * 8.0)
			if index < sample.outcome_points.size()
			else 0
		)
		var outcome_text := sample.outcomes[index] if index < sample.outcomes.size() else ""
		chart_rows.append(_sample_chart_row(seat, total_units, delta_units, outcome_text))
	_chart.bind_rows(chart_rows, 80, "sample:%d" % sample.round_number, seats)
	_award_binds.clear()
	for index in mini(sample.awards.size(), award_lines.size()):
		var seat_index := sample.award_seats[index] if index < sample.award_seats.size() else 0
		_award_binds.append(
			{
				"seat": _seat_for(seats, seat_index),
				"key": "",
				"text": sample.awards[index],
				"explanation": "",
				"explained": false,
			}
		)
	_show_awards(EXPLAIN_ALL)
	_no_score_reason.show_text(reason)
	_refit_when_sorted()
	_refit_later()


## Live: shows exactly what P05/P06 computed for the round (see MatchResultsViewModel).
## seats are the four registry seat dictionaries; ready_by_seat maps seat -> bool.
func bind_live(
	model: MatchResultsViewModel,
	seats: Array[Dictionary],
	ready_by_seat: Dictionary,
	remaining: float,
	total: float,
	device_kind: String,
	map: UiPromptMap,
	motion_mode: int = PresentationSettings.RESULT_REVEAL_NORMAL,
	twist_text: String = "",
	next_round_text: String = ""
) -> void:
	_last_cluck_callout.visible = not model.last_cluck_explanation.is_empty()
	_twist_line.text = twist_text
	_twist_line.visible = not twist_text.is_empty()
	_show_next_round(next_round_text)
	_round_label.text = "Round %d Result" % model.round_number
	_end_reason_label.text = model.diagnostic_label
	_end_reason_label.visible = not model.diagnostic_label.is_empty()
	_deadline_label.text = model.deadline_explanation
	_deadline_label.visible = not model.deadline_explanation.is_empty()
	var chart_rows: Array = model.score_presentation.get("seats", []).duplicate(true)
	if chart_rows.is_empty():
		chart_rows = _fallback_chart_rows(model)
	for chart_row in chart_rows:
		var seat_index := int(chart_row.get("seat_index", -1))
		var outcome := _outcome_for(model.per_seat_outcomes, seat_index)
		var detail := str(outcome.get("outcome", ""))
		if bool(ready_by_seat.get(seat_index, false)):
			detail = "READY · " + detail
		chart_row["status"] = detail
	_chart.bind_rows(
		chart_rows,
		model.target_score_units,
		(
			model.score_presentation_id
			if not model.score_presentation_id.is_empty()
			else "round:%d" % model.round_number
		),
		seats,
		motion_mode
	)
	var explain := model.award_rows.size() <= EXPLAINED_AWARD_ROWS
	_award_binds.clear()
	for index in mini(model.award_rows.size(), award_lines.size()):
		var award: Dictionary = model.award_rows[index]
		_award_binds.append(
			{
				"seat": _seat_for(seats, int(award.get("seat_index", -1))),
				"key": str(award.get("key", "")),
				"text": "%s %s" % [str(award.get("title", "")), str(award.get("score_text", ""))],
				"explanation": str(award.get("explanation", "")),
				"explained": explain,
			}
		)
	_show_awards(EXPLAIN_ALL)
	_no_score_reason.show_text(model.suppression_reason)
	_refit_when_sorted()
	_refit_later()
	_ready_hint.bind("results_ready", device_kind, map)
	_advance.set_time(remaining, total)


func _on_screen_ready() -> void:
	award_lines = [
		%Award1, %Award2, %Award3, %Award4, %Award5, %Award6, %Award7, %Award8, %Award9, %Award10
	]


func _show_state(index: int, ctx: UiContext) -> void:
	var reason := ctx.sample.no_score_reason
	if index == 1:
		reason = "Nobody reached the flag, so no points were awarded this round."
	elif index == 2:
		reason = "Everybody reached the flag, so no points were awarded this round."
	elif index == 3:
		reason = "Both finished: points are waived in 2-player."
	bind_result(ctx.sample, ctx.seats, reason)
	_ready_hint.bind("results_ready", ctx.device_kind, ctx.prompt_map)
	_advance.set_time(ctx.sample.advance_seconds, ctx.sample.advance_seconds)


func _accept(seat_index: int) -> bool:
	_chart.settle()
	continue_requested.emit(seat_index)
	return true


func last_cluck_visible() -> bool:
	return _last_cluck_callout.visible


func twist_line_text() -> String:
	return _twist_line.text if _twist_line.visible else ""


func next_round_text() -> String:
	return _next_round_raw if _next_round_label.visible else ""


## "NEXT R6 KANGAROO" reads "Next Round: R6 KANGAROO" in the chalkboard header; text without the
## NEXT prefix ("FINAL ROUND") is shown alone, and "" hides the line.
func _show_next_round(text: String) -> void:
	_next_round_raw = text
	var has_prefix := text.begins_with("NEXT ")
	_next_round_label.text = text.trim_prefix("NEXT ")
	_next_round_label.visible = not text.is_empty()
	_next_round_caption.visible = has_prefix


## Figma "Round Results" tucks the end reason under the title baseline, right of the title. A reason
## too wide for that space gets its own line below the title instead of running into it.
func _place_end_reason() -> void:
	var content_width := _title_block.size.x
	if content_width <= 0.0:
		content_width = size.x - _margin("margin_left") - _margin("margin_right")
	var font := _end_reason_label.get_theme_font("font")
	var reason_width := (
		font
		. get_string_size(
			_end_reason_label.text,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			_end_reason_label.get_theme_font_size("font_size")
		)
		. x
	)
	var room := content_width - _title_row.get_combined_minimum_size().x - TITLE_REASON_GAP
	var tucked := not _end_reason_label.visible or reason_width <= room
	_title_block.theme_type_variation = &"ResultTitleBlock" if tucked else &"ResultTitleBlockStacked"


## Fits again once the next layout pass has run: a screen bound as it is added, or a line that was
## hidden, only then has its real width and wrapped height. Binding fits at once when it can.
func _refit_later() -> void:
	var tree := get_tree()
	if tree != null and not tree.process_frame.is_connected(_refit):
		tree.process_frame.connect(_refit, CONNECT_ONE_SHOT)


## Fits as soon as the wrapped labels have widths. Container sorts are deferred calls, so each hop
## re-queues behind the sorts already waiting; the fit still lands in this frame's layout flush.
func _refit_when_sorted(hops_left: int = FIT_HOPS) -> void:
	if not is_inside_tree():
		return
	if _layout_settled() or hops_left <= 0 or not is_visible_in_tree():
		_refit()
		return
	_refit_when_sorted.call_deferred(hops_left - 1)


func _refit() -> void:
	_place_end_reason()
	if not _layout_settled():
		if is_visible_in_tree():
			_refit_later.call_deferred()
		return
	for level in [EXPLAIN_ALL, EXPLAIN_ONCE, EXPLAIN_NONE]:
		_show_awards(level)
		if _fit_legend():
			return


## Wrapped labels report their height for the width they had at the last layout; until they have
## one, the column heights are not known yet. (The scene keeps NoScoreReason visible so its label is
## laid out once even before the first scoring reason.)
func _layout_settled() -> bool:
	for label: Label in [_end_reason_label, _deadline_label, _no_score_reason.get_node("%TextLabel")]:
		if _shown_in_screen(label) and label.size.x < 2.0:
			return false
	return true


## Visible within this screen, whether or not the screen itself is shown right now.
func _shown_in_screen(control: Control) -> bool:
	var node: Node = control
	while node != null and node != self:
		if node is CanvasItem and not (node as CanvasItem).visible:
			return false
		node = node.get_parent()
	return true


func _notification(what: int) -> void:
	if what != NOTIFICATION_RESIZED and what != NOTIFICATION_VISIBILITY_CHANGED:
		return
	if is_node_ready() and not award_lines.is_empty() and is_visible_in_tree():
		_refit_when_sorted()
		_refit_later()


## Binds the award lines from _award_binds. EXPLAIN_ALL adds every explanation the round allows,
## EXPLAIN_ONCE only the first line of each distinct explanation (four Kangaroo placements share
## one), EXPLAIN_NONE shows title and points only.
func _show_awards(level: int) -> void:
	var shown := {}
	for index in award_lines.size():
		var line := award_lines[index]
		if index >= _award_binds.size():
			line.visible = false
			continue
		var award: Dictionary = _award_binds[index]
		var explanation := str(award.explanation)
		var explained := (
			bool(award.explained)
			and (level == EXPLAIN_ALL or (level == EXPLAIN_ONCE and not shown.has(explanation)))
		)
		shown[explanation] = true
		var text := str(award.text)
		if explained:
			text += " — %s" % explanation
		line.bind(award.seat, text, str(award.key))


## The Score Legend is one column, as designed, while the award lines fit above it. When they need
## the room it folds into two columns, then hides (each award line already shows its letter and
## name). False when the award lines do not fit even without it.
func _fit_legend() -> bool:
	var separation := float(_awards.get_theme_constant("separation"))
	var width := maxf(_awards.size.x, _awards.custom_minimum_size.x)
	var needed := 0.0
	for line in award_lines:
		if line.visible:
			needed += line.height_for_width(width) + separation
	_legend_heading.visible = true
	_legend_margin.visible = true
	_legend.columns = 1
	var room := _awards_room()
	if needed + _legend_block_height() <= room:
		return true
	_legend.columns = 2
	if needed + _legend_block_height() <= room:
		return true
	_legend_heading.visible = false
	_legend_margin.visible = false
	return needed <= room


## Height left in the Awards column for award lines and the legend once the title, footer and the
## column's own heading are placed.
func _awards_room() -> float:
	var inner := size.y - _margin("margin_top") - _margin("margin_bottom")
	var columns_height := (
		inner
		- (_content.get_combined_minimum_size().y - _columns.get_combined_minimum_size().y)
	)
	var awards_min := _awards.get_combined_minimum_size().y
	var flexible := _legend_block_height()
	for line in award_lines:
		if line.visible:
			flexible += line.get_combined_minimum_size().y + _awards.get_theme_constant("separation")
	return columns_height - (awards_min - flexible)


func _legend_block_height() -> float:
	var separation := float(_awards.get_theme_constant("separation"))
	return (
		_legend_heading.get_combined_minimum_size().y
		+ _legend_margin.get_combined_minimum_size().y
		+ separation * 2.0
	)


func _margin(side: String) -> float:
	return float(_safe.get_theme_constant(side))


func chart() -> ScoreboardChart:
	return _chart


func _fallback_chart_rows(model: MatchResultsViewModel) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for outcome in model.per_seat_outcomes:
		var seat_index := int(outcome.get("seat_index", -1))
		var total_units := int(outcome.get("total_units", 0))
		var awards: Array[Dictionary] = []
		var known_units := 0
		for award in model.award_rows:
			if int(award.get("seat_index", -1)) != seat_index or int(award.get("units", 0)) <= 0:
				continue
			known_units += int(award.units)
			(
				awards
				. append(
					{
						"key": str(award.get("key", "previous_total")),
						"row_id": str(award.get("key", "award")),
						"title": str(award.get("title", "Award")),
						"units": int(award.units),
						"reveal": true,
					}
				)
			)
		var segments: Array[Dictionary] = []
		if total_units > known_units:
			segments.append({"key": "previous_total", "units": total_units - known_units})
		segments.append_array(awards)
		(
			rows
			. append(
				{
					"seat_index": seat_index,
					"identity": int(outcome.get("identity", seat_index + 1)),
					"shape": str(outcome.get("shape", "")),
					"units": total_units,
					"delta_units": int(outcome.get("score_delta_units", 0)),
					"delta_text": str(outcome.get("score_delta_text", "")),
					"segments": segments,
				}
			)
		)
	return rows


func _outcome_for(outcomes: Array[Dictionary], seat_index: int) -> Dictionary:
	for outcome in outcomes:
		if int(outcome.get("seat_index", -1)) == seat_index:
			return outcome
	return {}


func _seat_for(seats: Array[Dictionary], seat_index: int) -> Dictionary:
	for seat in seats:
		if int(seat.get("seat", -1)) == seat_index:
			return seat
	return {}


func _sample_chart_row(
	seat: Dictionary, total_units: int, delta_units: int, outcome_text: String
) -> Dictionary:
	var segments: Array[Dictionary] = []
	if total_units > maxi(delta_units, 0):
		segments.append({"key": "previous_total", "units": total_units - maxi(delta_units, 0)})
	if delta_units > 0:
		segments.append({"key": "tapos", "title": "Tapos", "units": delta_units, "reveal": true})
	return {
		"seat_index": int(seat.get("seat", -1)),
		"identity": int(seat.get("identity", 0)),
		"shape": str(seat.get("shape", "")),
		"units": total_units,
		"delta_units": delta_units,
		"status": outcome_text,
		"segments": segments,
	}

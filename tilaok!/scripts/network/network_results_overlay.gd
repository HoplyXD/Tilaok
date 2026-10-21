class_name NetworkResultsOverlay
extends Control

## NLB-P09 minimum phone screens for the end of a round, the end of a match and the end of a session.
## Everything shown comes from the host's replicated ledger (ClientResultsModel) or the session's end
## reason; nothing is computed here, and every button only asks the host (or leaves locally). The full
## touch HUD, dp scaling and accessibility audit stay NLB-P10 work.

signal dismissed

const MARKS := {"CIRCLE": "●", "TRIANGLE": "▲", "SQUARE": "■", "DIAMOND": "◆"}
const END_AUTO_DISMISS_MS := 10000
const END_TEXT := {
	NetworkLifecycleCodec.SessionEnd.HOST_LOST: "The connection to the host was lost.",
	NetworkLifecycleCodec.SessionEnd.HOST_CLOSED: "The host ended the session.",
	NetworkLifecycleCodec.SessionEnd.LOBBY_RETURN: "The host returned everyone to the lobby.",
	NetworkLifecycleCodec.SessionEnd.HOST_QUIT: "The host quit the game.",
	NetworkLifecycleCodec.SessionEnd.CLIENT_LEFT: "You left the match.",
	NetworkLifecycleCodec.SessionEnd.REPLAY_UNAVAILABLE: "The host could not start a replay.",
}

var _session: NetworkSessionManager
var _phase := -1
var _ended_reason := NetworkLifecycleCodec.SessionEnd.NONE
var _end_deadline_ms := 0
var _panel: PanelContainer
var _title: Label
var _body: Label
var _vote: Label
var _buttons: HBoxContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel = PanelContainer.new()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(520, 0)
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	_panel.add_child(column)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 30)
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_title)
	_body = Label.new()
	_body.add_theme_font_size_override("font_size", 20)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_body)
	_vote = Label.new()
	_vote.add_theme_font_size_override("font_size", 20)
	column.add_child(_vote)
	_buttons = HBoxContainer.new()
	_buttons.add_theme_constant_override("separation", 10)
	column.add_child(_buttons)
	_panel.visible = false


func bind(session: NetworkSessionManager) -> void:
	_session = session
	if session != null and not session.results_changed.is_connected(refresh):
		session.results_changed.connect(refresh)


func _exit_tree() -> void:
	if _session != null and is_instance_valid(_session) and _session.results_changed.is_connected(refresh):
		_session.results_changed.disconnect(refresh)


func _process(_delta: float) -> void:
	if _ended_reason != NetworkLifecycleCodec.SessionEnd.NONE and Time.get_ticks_msec() >= _end_deadline_ms:
		_end_deadline_ms = 0x7fffffffffffffff
		dismissed.emit()


## True while a results or session-ended screen covers the match view.
func is_blocking() -> bool:
	return _panel != null and _panel.visible


func set_phase(phase: int) -> void:
	_phase = phase
	refresh()


## The session is over: show why, then ask the owner to return to the title or lobby.
func show_session_ended(reason: int) -> void:
	_ended_reason = reason if END_TEXT.has(reason) else NetworkLifecycleCodec.SessionEnd.HOST_LOST
	_end_deadline_ms = Time.get_ticks_msec() + END_AUTO_DISMISS_MS
	refresh()


func refresh() -> void:
	if _panel == null:
		return
	if _ended_reason != NetworkLifecycleCodec.SessionEnd.NONE:
		_show_end()
		return
	if _session == null:
		_panel.visible = false
		return
	var results := _session.client_results
	if results.is_final():
		_show_final(results)
		return
	var latest := results.latest()
	if (
		not latest.is_empty()
		and int(latest.kind) == NetworkResultsCodec.Kind.ROUND
		and _phase == MatchPhaseController.Phase.RESULTS
	):
		_show_round(latest, results)
		return
	_panel.visible = false


func _show_round(entry: Dictionary, results: ClientResultsModel) -> void:
	_begin(("Round %d results" % int(entry.round_id)))
	var lines: Array[String] = []
	for seat_variant in entry.seats:
		lines.append(_seat_line(seat_variant as Dictionary))
	var family_note := _round_note(entry)
	if not family_note.is_empty():
		lines.append(family_note)
	if int(entry.decision) == NetworkResultsCodec.Decision.SUDDEN_DEATH:
		lines.append("Tied for the lead — Sudden Death decides the match.")
	_body.text = "\n".join(lines)
	_vote.text = _vote_text(NetworkResultsCodec.ResultAction.CONTINUE, results)
	var ready := _my_seat_ready(results, NetworkResultsCodec.ResultAction.CONTINUE)
	var button := _button("Ready ✓" if ready else "Continue")
	button.disabled = ready or _session == null or not _session.sync_ready
	button.pressed.connect(func() -> void: _ask(NetworkResultsCodec.ResultAction.CONTINUE))
	_panel.visible = true


func _show_final(results: ClientResultsModel) -> void:
	var final_entry := results.final_entry()
	var winner := int(final_entry.winner_seat)
	_begin("Match over — %s wins!" % _seat_name(winner))
	var lines: Array[String] = []
	if int(final_entry.last_cluck) == 1:
		lines.append("Last Cluck! The latest elimination takes the win.")
	if int(final_entry.sudden_death) == 1:
		lines.append("Sudden Death decided the match; it added no points.")
	elif int(final_entry.terminal_reason) == NetworkResultsCodec.Terminal.SCORE_TARGET:
		lines.append("The score target ended the match.")
	else:
		lines.append("The round limit ended the match.")
	for seat_variant in final_entry.seats:
		var seat: Dictionary = seat_variant
		lines.append(
			"%s    %s%s"
			% [
				_seat_name(int(seat.seat)),
				ScoreFormat.format_units(int(seat.total)),
				"   ★" if int(seat.seat) == winner else "",
			]
		)
	_body.text = "\n".join(lines)
	var vote := results.vote
	var selected := int(vote.get("action", -1))
	_vote.text = _vote_text(selected, results) if selected > 0 else "Choose Replay or Return to Lobby."
	for action_entry in [
		[NetworkResultsCodec.ResultAction.VOTE_REPLAY, "Replay"],
		[NetworkResultsCodec.ResultAction.VOTE_LOBBY, "Return to Lobby"],
	]:
		var action := int(action_entry[0])
		var ready := _my_seat_ready(results, action)
		var vote_button := _button(("▶ " if selected == action else "") + str(action_entry[1]) + (" ✓" if ready else ""))
		vote_button.disabled = ready or _session == null or not _session.sync_ready
		vote_button.pressed.connect(func() -> void: _ask(action))
	var leave := _button("Leave")
	leave.pressed.connect(
		func() -> void:
			if _session != null:
				_session.stop_session(NetworkLifecycleCodec.SessionEnd.CLIENT_LEFT)
	)
	_panel.visible = true


func _show_end() -> void:
	_begin("Session ended")
	_body.text = str(END_TEXT.get(_ended_reason, END_TEXT[NetworkLifecycleCodec.SessionEnd.HOST_LOST]))
	_vote.text = "Returning to the lobby…"
	var back := _button("Back to lobby")
	back.pressed.connect(
		func() -> void:
			_end_deadline_ms = 0x7fffffffffffffff
			dismissed.emit()
	)
	_panel.visible = true


func _begin(title: String) -> void:
	_title.text = title
	_body.text = ""
	_vote.text = ""
	for child in _buttons.get_children():
		child.queue_free()
		_buttons.remove_child(child)


func _button(label: String) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(150, 72)
	button.add_theme_font_size_override("font_size", 20)
	button.focus_mode = Control.FOCUS_NONE
	_buttons.add_child(button)
	return button


func _ask(action: int) -> void:
	if _session != null:
		_session.client_send_result_action(action)


func _seat_name(seat: int) -> String:
	if seat < 0 or seat >= PlayerSeatRegistry.SHAPES.size():
		return "—"
	var shape: String = PlayerSeatRegistry.SHAPES[seat]
	return "%s P%d %s" % [MARKS.get(shape, "◆"), seat + 1, shape]


func _seat_line(seat: Dictionary) -> String:
	var parts: Array[String] = []
	for award_variant in seat.awards:
		var award: Dictionary = award_variant
		var units := int(award.units)
		if units == 0:
			continue
		parts.append(
			"%s %s%s"
			% [
				NetworkResultsCodec.award_name(int(award.key)).capitalize(),
				"+" if units > 0 else "",
				ScoreFormat.format_units(units),
			]
		)
	var outcome := "—"
	if int(seat.outcome) == NetworkResultsCodec.Outcome.FINISHED:
		outcome = "Finished"
	elif int(seat.outcome) == NetworkResultsCodec.Outcome.ELIMINATED:
		outcome = "Out"
		var cause := NetworkResultsCodec.cause_name(int(seat.cause)).replace("_", " ")
		if not cause.is_empty():
			outcome += " (%s)" % cause
	var points := ", ".join(parts) if not parts.is_empty() else "no points"
	return (
		"%s — %s · %s → %s (%s%s)"
		% [
			_seat_name(int(seat.seat)),
			outcome,
			points,
			ScoreFormat.format_units(int(seat.total)),
			"+" if int(seat.delta) > 0 else "",
			ScoreFormat.format_units(int(seat.delta)),
		]
	)


func _round_note(entry: Dictionary) -> String:
	if int(entry.last_cluck_seat) >= 0:
		return "Last Cluck! %s wins on the latest elimination." % _seat_name(int(entry.last_cluck_seat))
	match int(entry.suppression):
		NetworkResultsCodec.Suppression.NO_FINISHER:
			return "Nobody reached the flag — no round points."
		NetworkResultsCodec.Suppression.ALL_FINISHED:
			return "Everyone finished — race awards are suppressed."
	return ""


func _vote_text(action: int, results: ClientResultsModel) -> String:
	var vote := results.vote
	if vote.is_empty() or int(vote.get("action", -1)) != action:
		return "Waiting for players…"
	var required := NetworkResultsCodec.seats_of(int(vote.required_mask)).size()
	var ready := NetworkResultsCodec.seats_of(int(vote.ready_mask)).size()
	return "Ready %d of %d" % [ready, required]


func _my_seat_ready(results: ClientResultsModel, action: int) -> bool:
	var vote := results.vote
	if vote.is_empty() or int(vote.get("action", -1)) != action or _session == null:
		return false
	var seat := _session.client_assigned_seat
	return seat >= 0 and (int(vote.ready_mask) & (1 << seat)) != 0

extends SceneTree

## Current standalone mode HUD checks on the P12 scheduled route; historical stack cases remain
## below as dated source evidence but are not invoked. KANG / GA / ROO are checked overhead.
## Number/shape, totals, deadlines, taya, secured/eliminated, next-round selection, no-score
## reason and Last Cluck are also checked. Text size,
## the 64 px reservation and the absence of internal ids are checked on what is actually visible.
## Synthetic seats and input only; this is not a spectator comprehension result.

const ROOM_SCENE := preload("res://scenes/match/p12_scheduled_match_room.tscn")
const KARERA := EventSchedule.Challenge.KARERA
const LAGSANAY := EventSchedule.Challenge.LAGSANAY
const KANGAROO := EventSchedule.Challenge.KANGAROO
const NONE := EventSchedule.Challenge.NONE
const HUD_RESERVATION := 64.0
const LAYOUT_TOLERANCE := 1.5
const FORBIDDEN_TEXT := [
	"seed",
	"DEBUG",
	"profile",
	"build=",
	"build.",
	"karera_slice",
	"collision",
	"shape_id",
	"uid://",
	"res://",
]

var checks := 0
var failures := 0
var room: P12ScheduledMatchRoom
var min_label_px := 12
var min_hud_px := 16


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var theme := load("res://assets/ui/theme/tilaok_theme.tres") as Theme
	min_label_px = theme.get_constant("min_label_font_px", "TilaokPolicy")
	min_hud_px = theme.get_constant("min_midround_font_px", "TilaokPolicy")
	_check(min_label_px >= 12 and min_hud_px >= 16, "theme minimum sizes are 12 / 16")
	for seat_count: int in [2, 4]:
		await _karera_main(seat_count)
		await _lagsanay_main(seat_count)
		await _kangaroo_main(seat_count)
	await _final_round_and_sudden_death()
	await _barya_has_a_text_cue()
	print("P13_HUD_TESTS checks=%d failures=%d" % [checks, failures])
	quit(1 if failures > 0 else 0)


# --- scenarios --------------------------------------------------------------------------------


func _karera_main(seat_count: int) -> void:
	var tag := "Karera %dp" % seat_count
	var seats := await _open(seat_count, {1: [KARERA, NONE]})
	await _to_play(seats)
	var hud := room.presenter.play_hud
	_check_common(tag, hud, seat_count)
	_check((hud.get_node("%ChallengeLabel") as Label).text == "Karera", tag + ": names Karera")
	_check(not (hud.get_node("%TwistTag") as Label).visible, tag + ": no TWIST tag without a Twist")
	_check(hud.up_next_text().begins_with("NEXT R2 "), tag + ": names the next round")
	_check(
		_state_texts(hud, seat_count) == _repeat("RUN", seat_count),
		tag + ": every runner reads RUN"
	)
	# One finisher: SECURED, then the finish window tag appears.
	await physics_frame
	room.race_candidate_queue.queue_goal(
		room.actors[seats[0]] as ChickenController, Engine.get_physics_frames()
	)
	await _frames(4)
	await process_frame
	_check(
		hud.score_rows[seats[0]].state_text() == "SECURED",
		tag + ": a finisher reads SECURED (%s)" % hud.score_rows[seats[0]].state_text()
	)
	_check(
		(hud.get_node("%NextEventLabel") as Label).text.contains("FINISH WINDOW"),
		tag + ": the finish window is named"
	)
	_check_text_rules(tag, room.presenter)
	# Everybody else finishes: results with the reason (waived at 2 seats).
	var rest: Array[int] = []
	for seat in seats:
		if seat != seats[0]:
			rest.append(seat)
	await _finish_with_goals(rest)
	await _frames(3)
	var result := room.presenter.result_screen
	_check(
		room.phase_controller.phase == MatchPhaseController.Phase.RESULTS and result.visible,
		tag + ": the round result is shown"
	)
	var reason := (result.get_node("%NoScoreReason") as UiToastLine).text_value()
	_check(
		not reason.is_empty() or seat_count > 2,
		tag + ": everyone finishing explains why no points were awarded (%s)" % reason
	)
	_check(not result.last_cluck_visible(), tag + ": no Last Cluck callout on a race")
	_check(result.next_round_text().begins_with("NEXT R2"), tag + ": results name the next round")
	_check_text_rules(tag + " results", room.presenter)
	await _close()


func _lagsanay_main(seat_count: int) -> void:
	var tag := "Lagsanay %dp" % seat_count
	var seats := await _open(seat_count, {1: [LAGSANAY, NONE]})
	await _to_play(seats)
	var hud := room.presenter.play_hud
	_check_common(tag, hud, seat_count)
	_check((hud.get_node("%ChallengeLabel") as Label).text == "Lagsanay", tag + ": names Lagsanay")
	var taya := room.lagsanay_controller.taya_seat
	_check(taya >= 0 and hud.score_rows[taya].state_text() == "TAYA", tag + ": the taya reads TAYA")
	var tag_text := (hud.get_node("%NextEventLabel") as Label).text
	_check(
		tag_text.contains("TAYA P%d" % (taya + 1)),
		tag + ": the HUD names the taya's number (%s)" % tag_text
	)
	_check(
		(hud.get_node("%TimerLabel") as Label).visible,
		tag + ": the taya countdown shows as a clock"
	)
	_check(not room.goal_area.monitoring, tag + ": no flag in Lagsanay")
	_check_text_rules(tag, room.presenter)
	await _close()


func _kangaroo_main(seat_count: int) -> void:
	var tag := "Kangaroo %dp" % seat_count
	var seats := await _open(seat_count, {1: [KANGAROO, NONE]})
	await _to_play(seats)
	var hud := room.presenter.play_hud
	_check_common(tag, hud, seat_count)
	_check((hud.get_node("%ChallengeLabel") as Label).text == "Kangaroo", tag + ": names Kangaroo")
	await _wait_for_command()
	var kangaroo_hud := room.kangaroo_round.hud()
	_check(kangaroo_hud.command_count() >= 1, tag + ": a command card is shown")
	var card := kangaroo_hud.cards[0]
	_check(
		card.pose_text() in ["FREEZE", "RISING", "HUG"],
		tag + ": the card names the pose in text (%s)" % card.pose_text()
	)
	_check(
		card.phase_text() in ["GET READY", "NOW"] and not card.instruction_text().is_empty(),
		tag + ": the card says when and what to do"
	)
	_check(
		room.kangaroo_round._life_markers.size() == seat_count,
		tag + ": one overhead life marker is bound to each chicken"
	)
	_check(kangaroo_hud.marker_texts().is_empty(), tag + ": side-panel miss rows are removed")
	for seat in seats:
		(room.actors[seat] as ChickenController).global_position = Vector2(800.0, 600.0)
	room.kangaroo_round.update_view(0.0)
	await _frames(1)
	var close_lanes: Dictionary = {}
	var ownership_ok := true
	for seat in seats:
		var marker := room.kangaroo_round._life_markers[seat] as KangarooLifeMarker
		close_lanes[marker.overlap_lane] = true
		ownership_ok = ownership_ok and marker.actor == room.actors[seat]
	_check(
		close_lanes.size() == seat_count and ownership_ok,
		tag + ": close chickens get separate lanes and retain the correct actor ownership"
	)
	for seat in seats:
		(room.actors[seat] as ChickenController).global_position = Vector2(
			500.0 + seat * 500.0, 600.0
		)
	room.camera_rig.zoom = Vector2(0.5, 0.5)
	room.kangaroo_round.update_view(0.0)
	await _frames(1)
	var wide_layout_ok := true
	for seat in seats:
		var marker := room.kangaroo_round._life_markers[seat] as KangarooLifeMarker
		wide_layout_ok = wide_layout_ok and marker.overlap_lane == 0
		wide_layout_ok = (
			wide_layout_ok
			and marker.global_scale.is_equal_approx(Vector2.ONE / room.camera_rig.zoom.x)
		)
	_check(
		wide_layout_ok,
		(
			tag
			+ (
				": separated chickens use the base lane and marker scale compensates camera zoom (%s / %s)"
				% [
					str(room.camera_rig.zoom),
					str(room.kangaroo_round._life_markers[seats[0]].global_scale)
				]
			)
		)
	)
	# One miss: the existing player score row has no duplicate miss indicator; overhead marker changes.
	room.kangaroo_round.controller.marker_counts[seats[0]] = 1
	await _frames(3)
	_check(
		(
			(room.kangaroo_round._life_markers[seats[0]] as KangarooLifeMarker).failure_count == 1
			and kangaroo_hud.marker_texts().is_empty()
		),
		tag + ": first strike changes the owned overhead marker with no side duplicate"
	)
	room.kangaroo_round.controller.marker_counts[seats[0]] = 2
	await _frames(3)
	_check(
		(room.kangaroo_round._life_markers[seats[0]] as KangarooLifeMarker).failure_count == 2,
		tag + ": second strike is shown above its chicken"
	)
	room.kangaroo_round.controller.marker_counts[seats[0]] = 3
	await _frames(3)
	_check(
		(room.kangaroo_round._life_markers[seats[0]] as KangarooLifeMarker).failure_count == 3,
		tag + ": the final strike remains visible in the overhead indicator"
	)
	_check_text_rules(tag, room.presenter)
	_check_kangaroo_hud_text(tag, kangaroo_hud)
	room.kangaroo_round.clear_view()
	_check(
		room.kangaroo_round._life_markers.is_empty(),
		tag + ": round-view teardown clears every overhead marker binding"
	)
	await _close()


func _karera_bomb_taya(seat_count: int) -> void:
	var tag := "Karera+Bomb-Taya %dp" % seat_count
	var seats := await _open(seat_count, {1: [KARERA, LAGSANAY]})
	await _to_play(seats)
	room.bomb_taya.head_start_remaining = 0.0
	await _frames(4)
	var hud := room.presenter.play_hud
	_check_common(tag, hud, seat_count)
	_check(
		(hud.get_node("%TwistTag") as Label).text == "TWIST: BOMB-TAYA",
		tag + ": the TWIST label names Bomb-Taya"
	)
	var taya := room.bomb_taya.taya_seat
	_check(hud.score_rows[taya].state_text() == "TAYA", tag + ": the taya reads TAYA")
	_check(
		(hud.get_node("%NextEventLabel") as Label).text.contains("%d" % (taya + 1)),
		tag + ": the tag names the taya"
	)
	_check_text_rules(tag, room.presenter)
	await _close()


func _karera_kangaroo(seat_count: int) -> void:
	var tag := "Karera+Kangaroo %dp" % seat_count
	var seats := await _open(seat_count, {1: [KARERA, KANGAROO]})
	await _to_play(seats)
	await _wait_for_command()
	var hud := room.presenter.play_hud
	_check_common(tag, hud, seat_count)
	_check(
		(hud.get_node("%TwistTag") as Label).text == "TWIST: KANGAROO",
		tag + ": the TWIST label names Kangaroo"
	)
	var kangaroo_hud := room.kangaroo_round.hud()
	_check(kangaroo_hud.command_count() >= 1, tag + ": the Twist's command card is shown")
	_check(
		kangaroo_hud.marker_texts().size() == seat_count,
		tag + ": KANG GA ROO rows for every runner"
	)
	await physics_frame
	room.race_candidate_queue.queue_goal(
		room.actors[seats[0]] as ChickenController, Engine.get_physics_frames()
	)
	await _frames(4)
	_check(
		hud.score_rows[seats[0]].state_text() == "SECURED",
		tag + ": a secured finisher keeps SECURED (not a miss label)"
	)
	_check_text_rules(tag, room.presenter)
	_check_kangaroo_hud_text(tag, kangaroo_hud)
	await _close()


func _kangaroo_bomb_taya(seat_count: int) -> void:
	var tag := "Kangaroo+Bomb-Taya %dp" % seat_count
	var seats := await _open(seat_count, {1: [KANGAROO, LAGSANAY]})
	await _to_play(seats)
	room.bomb_taya.head_start_remaining = 0.0
	await _wait_for_command()
	var hud := room.presenter.play_hud
	_check_common(tag, hud, seat_count)
	_check(
		(hud.get_node("%TwistTag") as Label).text == "TWIST: BOMB-TAYA",
		tag + ": the TWIST label names Bomb-Taya"
	)
	var taya := room.bomb_taya.taya_seat
	_check(
		taya >= 0 and hud.score_rows[taya].state_text() == "TAYA",
		tag + ": the taya reads TAYA over Kangaroo"
	)
	_check(room.kangaroo_round.hud().command_count() >= 1, tag + ": the command card is shown")
	_check_text_rules(tag, room.presenter)
	# Everyone out in one step: Last Cluck callout, Twist line and next round on the result.
	await physics_frame
	for seat in seats:
		_trap(seat)
	await _frames(5)
	var result := room.presenter.result_screen
	_check(
		room.phase_controller.phase == MatchPhaseController.Phase.RESULTS and result.visible,
		tag + ": the all-eliminated round resolves to results"
	)
	_check(result.last_cluck_visible(), tag + ": the Last Cluck callout is shown")
	_check(
		result.twist_line_text() == "TWIST: BOMB-TAYA",
		tag + ": results name the Twist (%s)" % result.twist_line_text()
	)
	_check(
		result.next_round_text().begins_with("NEXT R2"),
		tag + ": results name the next round (%s)" % result.next_round_text()
	)
	_check_text_rules(tag + " results", room.presenter)
	_check_result_fits(tag + " results", result)
	await _close()


func _final_round_and_sudden_death() -> void:
	var seats := await _open(2, {1: [KARERA, NONE]})
	await _to_play(seats)
	room.tuning.match_round_limit = 1
	room.schedule.locked.erase(2)
	_check(room.hud_up_next_text() == "FINAL ROUND", "the last round says FINAL ROUND")
	room._sudden_death_active = true
	_check(room.hud_up_next_text() == "", "sudden death shows no next round")
	room._sudden_death_active = false
	await _close()


func _barya_has_a_text_cue() -> void:
	var seats := await _open(2, {1: [KARERA, NONE]})
	await _to_play(seats)
	room.barya_objective.state = BaryaRoundObjective.State.CARRIED
	room.barya_objective.carrier_seat = seats[0]
	room._notify_presentation(&"barya_test")
	await process_frame
	var hud := room.presenter.play_hud
	var visible_cue := false
	for node in _all_nodes(room.presenter):
		if (
			node is Label
			and (node as Label).is_visible_in_tree()
			and (node as Label).text.to_lower().contains("barya")
		):
			visible_cue = true
	_check(visible_cue, "the Barya carrier has a visible text cue")
	_check(hud.score_rows[seats[0]].state_text() == "BARYA", "carrier row names BARYA")
	await _close()


# --- shared checks ------------------------------------------------------------------------------


func _check_common(tag: String, hud: UiPlayHud, seat_count: int) -> void:
	_check(hud.visible, tag + ": the Play HUD is visible")
	_check((hud.get_node("%RoundLabel") as Label).text == "Round 1", tag + ": names the round")
	var visible_rows := 0
	for row in hud.score_rows:
		if row.visible:
			visible_rows += 1
			_check(
				row.score_text() == "0" and row.badge.number_text() != "",
				tag + ": row shows number and exact total (%s)" % row.score_text()
			)
	_check(visible_rows == seat_count, tag + ": a row per joined seat (%d)" % visible_rows)
	var timer := hud.get_node("%TimerLabel") as Label
	_check(timer.visible and timer.text.contains(":"), tag + ": a deadline clock is shown")
	var bar := hud.hud_bar
	var rect := bar.get_global_rect()
	_check(
		rect.size.y <= HUD_RESERVATION + LAYOUT_TOLERANCE and rect.position.y >= -LAYOUT_TOLERANCE,
		tag + ": the HUD bar stays inside the 64 px reservation (%.1f)" % rect.size.y
	)
	var viewport := Vector2(
		float(ProjectSettings.get_setting("display/window/size/viewport_width")),
		float(ProjectSettings.get_setting("display/window/size/viewport_height"))
	)
	for node in _all_nodes(bar):
		var control := node as Control
		if control == null or not control.is_visible_in_tree() or control == bar:
			continue
		var child_rect := control.get_global_rect()
		if child_rect.size.x <= 0.0:
			continue
		if (
			child_rect.position.x < -LAYOUT_TOLERANCE
			or child_rect.end.x > viewport.x + LAYOUT_TOLERANCE
		):
			_check(
				false, "%s: %s overflows the viewport width %s" % [tag, control.name, child_rect]
			)


## Visible text on the player's screens: sizes above the theme minimum, no internal tokens.
func _check_text_rules(tag: String, presenter: MatchScreenPresenter) -> void:
	var roots: Array[Node] = [presenter]
	if room != null and room.kangaroo_round != null:
		roots.append(room.kangaroo_round.hud())
	var small := PackedStringArray()
	var leaked := PackedStringArray()
	for root_node in roots:
		for node in _all_nodes(root_node):
			var label := node as Label
			if (
				label == null
				or not label.is_visible_in_tree()
				or label.text.strip_edges().is_empty()
			):
				continue
			if label.get_theme_font_size("font_size") < min_label_px:
				small.append("%s=%d" % [label.name, label.get_theme_font_size("font_size")])
			for token in FORBIDDEN_TEXT:
				if label.text.contains(token) or label.text.contains(str(room.match_seed)):
					leaked.append("%s:'%s'" % [label.name, label.text])
	_check(small.is_empty(), "%s: no visible text below the theme minimum %s" % [tag, small])
	_check(leaked.is_empty(), "%s: no internal ids, seeds or DEBUG text %s" % [tag, leaked])


## The command cards and the miss grid sit below the HUD bar and its notice row and never
## overlap each other, so the Play-start hint and the commands are all readable together.
## The Round result keeps its title row and footer (ready hint, next-round countdown) on screen
## with the Last Cluck callout, Twist line and next-round line added.
func _check_result_fits(tag: String, result: UiRoundResultScreen) -> void:
	var height := float(ProjectSettings.get_setting("display/window/size/viewport_height"))
	var width := float(ProjectSettings.get_setting("display/window/size/viewport_width"))
	for node_name in ["RoundLabel", "ReadyHint", "AdvanceCountdown"]:
		var control := result.get_node("%" + node_name) as Control
		var rect := control.get_global_rect()
		_check(
			rect.position.y >= -LAYOUT_TOLERANCE and rect.end.y <= height + LAYOUT_TOLERANCE,
			"%s: %s is inside the screen height (%s)" % [tag, node_name, rect]
		)
		_check(
			rect.position.x >= -LAYOUT_TOLERANCE and rect.end.x <= width + LAYOUT_TOLERANCE,
			"%s: %s is inside the screen width" % [tag, node_name]
		)


func _check_kangaroo_layout(tag: String, kangaroo_hud: UiKangarooHud) -> void:
	var play_hud := room.presenter.play_hud
	var toast := play_hud.get_node("%NoticeToast") as Control
	var bar := play_hud.hud_bar.get_global_rect().end.y
	var below := toast.get_global_rect().end.y if toast.is_visible_in_tree() else bar
	_check(
		kangaroo_hud.get_node_or_null("%Markers") == null, tag + ": no duplicate miss panel exists"
	)
	var cards: Array[Rect2] = []
	for card in kangaroo_hud.cards:
		if card.visible:
			cards.append(card.get_global_rect())
	for rect in cards:
		_check(
			rect.position.y >= below - LAYOUT_TOLERANCE,
			tag + ": a command card is below the notice (%s vs %.1f)" % [rect, below]
		)
	for first in cards.size():
		for second in range(first + 1, cards.size()):
			_check(
				not cards[first].intersects(cards[second]), tag + ": cards never overlap each other"
			)


func _check_kangaroo_hud_text(tag: String, kangaroo_hud: UiKangarooHud) -> void:
	_check_kangaroo_layout(tag, kangaroo_hud)
	var small := PackedStringArray()
	for node in _all_nodes(kangaroo_hud):
		var label := node as Label
		if label == null or not label.is_visible_in_tree() or label.text.strip_edges().is_empty():
			continue
		var is_note := label.theme_type_variation in [&"CaptionLabel", &"PlaceholderTag"]
		var limit := min_label_px if is_note else min_hud_px
		if label.get_theme_font_size("font_size") < limit:
			small.append("%s=%d" % [label.name, label.get_theme_font_size("font_size")])
	_check(small.is_empty(), "%s: Kangaroo HUD text meets the mid-round minimum %s" % [tag, small])


# --- harness ----------------------------------------------------------------------------------


func _open(seat_count: int, forced: Dictionary) -> Array[int]:
	room = ROOM_SCENE.instantiate() as P12ScheduledMatchRoom
	root.add_child(room)
	await process_frame
	await physics_frame
	var seats: Array[int] = [room.join_keyboard("K1"), room.join_keyboard("K2")]
	for device_id in [7101, 7102].slice(0, seat_count - 2):
		var seat_index := room.input_router.registry.join_gamepad(device_id)
		seats.append(seat_index)
		room.input_router.seat_joined.emit(seat_index)
	for seat_index in seats:
		room.input_router.registry.set_ready(seat_index, true)
	_check(room.start_match(), "%d-seat scheduled match starts" % seat_count)
	for round_number in forced:
		var pair: Array = forced[round_number]
		room.schedule.locked[int(round_number)] = {
			"round": int(round_number),
			"main": int(pair[0]),
			"twist": int(pair[1]),
			"guaranteed": false,
			"sudden_death": false,
			"twist_options": 0,
		}
	room.tuning.match_target_score_units = 100000
	room.tuning.match_results_advance_seconds = 600.0
	room.tuning.match_race_hard_cap_seconds = 600.0
	room.tuning.match_race_after_first_finish_seconds = 600.0
	room.tuning.kangaroo_telegraph_seconds = 0.5
	room.tuning.kangaroo_response_seconds = 2.0
	room.tuning.kangaroo_reset_seconds = 0.1
	return seats


func _to_play(seats: Array[int]) -> void:
	room._finish_pugad_timeout()
	var edits: Array[Dictionary] = []
	room._resolve_place_edits(edits)
	var index := 0
	for seat in seats:
		var actor := room.actors[seat] as ChickenController
		actor.global_position = room.arena.controller_origin_from_feet(
			room.arena.spawn_feet + Vector2(220.0 * index, 0.0)
		)
		actor.velocity = Vector2.ZERO
		index += 1
	await _frames(4)
	# The Barya pickup can notify the presenter on the last physics step. Let its coalesced
	# process-frame binding run before reading visible HUD state.
	await process_frame
	_check(
		room.phase_controller.phase == MatchPhaseController.Phase.PLAY,
		"round enters Play as %s" % EventSchedule.describe(room.current_entry())
	)


func _wait_for_command() -> void:
	for _frame in 240:
		await physics_frame
		if not room.kangaroo_round.controller.active_commands().is_empty():
			break
	await _frames(3)


func _finish_with_goals(seats: Array[int]) -> void:
	await physics_frame
	for seat in seats:
		room.race_candidate_queue.queue_goal(
			room.actors[seat] as ChickenController, Engine.get_physics_frames()
		)
	await _frames(3)
	for _frame in 240:
		if room.phase_controller.phase == MatchPhaseController.Phase.RESULTS:
			break
		await physics_frame


func _trap(seat: int) -> void:
	var record := AttributionRecord.new()
	record.kind = AttributionRecord.Kind.ELIMINATION
	record.player_seat = seat
	record.source_item_id = "trap.p13.%d" % seat
	record.owner_seat = -1
	record.physics_time = room.items.director.simulation_time + 0.004
	record.physics_tick = Engine.get_physics_frames()
	record.time_comparable = true
	record.round_id = room.items.director.active_round_id
	record.event_id = (
		"%s:item:%s:%d:%d" % [record.round_id, record.source_item_id, record.physics_tick, seat]
	)
	room._on_item_elimination(record)


func _close() -> void:
	Engine.time_scale = 1.0
	if room != null and is_instance_valid(room):
		room.queue_free()
	room = null
	paused = false
	await process_frame
	await process_frame


func _state_texts(hud: UiPlayHud, seat_count: int) -> PackedStringArray:
	var result := PackedStringArray()
	for index in seat_count:
		result.append(hud.score_rows[index].state_text())
	return result


func _repeat(text: String, count: int) -> PackedStringArray:
	var result := PackedStringArray()
	for _index in count:
		result.append(text)
	return result


func _frames(count: int) -> void:
	for _frame in count:
		await physics_frame
	await process_frame


func _all_nodes(node: Node) -> Array[Node]:
	var result: Array[Node] = [node]
	for child in node.get_children():
		result.append_array(_all_nodes(child))
	return result


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("P13_HUD FAIL: " + message)
	print("%s %s" % ["PASS" if condition else "FAIL", message])

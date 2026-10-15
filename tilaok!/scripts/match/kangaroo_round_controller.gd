class_name KangarooRoundController
extends RefCounted

## Independent P11 round state. The room supplies real actor/support/contact snapshots; this
## controller owns command timing, deterministic selection, failure markers and terminal batches.

enum Command { FREEZE, RISING, HUG }

const COMMAND_INSTANCE_SCRIPT := preload("res://scripts/match/kangaroo_command_instance.gd")
const COMMAND_NAMES := ["FREEZE", "RISING", "HUG"]
const COMMAND_HISTORY_LIMIT := 128

var active := false
var ended := false
var round_id := ""
var seat_indices: Array[int] = []
var live_seats: Array[int] = []
var marker_counts: Dictionary = {}
var command_history: Array[Dictionary] = []
var terminal_outcomes: Array[Dictionary] = []
var elimination_records: Array[Dictionary] = []
var starting_totals: Dictionary = {}
var no_elimination_commands := 0
var storm_active := false
var storm_landing_pending := false
var last_cluck := false
var last_cluck_seat := -1
var commit_done := false
## P12 stacks: as a Twist (Karera Main) this controller never ends the round, never names a
## winner and runs no Storm; finishers leave the live roster via `secure_seat`.
var twist_role := false
var secured_seats: Array[int] = []

var _external_causes: Dictionary = {}
var _tuning: GameplayTuning
var _rng: RandomNumberGenerator
var _now := 0.0
var _next_base_launch := -1.0
var _next_storm_landing := -1.0
var _next_command_id := 1
var _storm_pair_next := -1
var _input_sources: Dictionary = {}
var _input_events: Array[Dictionary] = []
var _processed_input_edges: Array[Dictionary] = []
var _hazards: Array[AttributionRecord] = []
var _event_sequence := 0
var _step_had_elimination := false
var _step_completed_count := 0
var _step_provisional_count := 0
var _step_storm_trigger_at := -1.0
var _step_physics_tick := -1
var _step_actors: Dictionary = {}
var _step_support_tracker: SupportTracker
var _step_hug_contacts: Array[Dictionary] = []


static func command_name(command: int) -> String:
	return COMMAND_NAMES[command] if command >= 0 and command < COMMAND_NAMES.size() else "UNKNOWN"


static func select_command(rng: RandomNumberGenerator, alive_count: int) -> int:
	if rng == null or alive_count <= 1:
		return -1
	var selected := rng.randi_range(Command.FREEZE, Command.HUG)
	while alive_count == 2 and selected == Command.HUG:
		selected = rng.randi_range(Command.FREEZE, Command.HUG)
	return selected


static func wave_y_for_band(tuning: GameplayTuning, band: int) -> float:
	if tuning == null:
		tuning = GameplayTuning.new()
	match band:
		0:
			return tuning.kangaroo_wave_middle_low_y_wu
		1:
			return tuning.kangaroo_wave_middle_y_wu
		2:
			return tuning.kangaroo_wave_middle_high_y_wu
	return -1.0


static func hazard_precedes_command(
	hazard_time_comparable: bool, hazard_time: float, command_evaluation_time: float
) -> bool:
	return hazard_time_comparable and hazard_time < command_evaluation_time


static func pair_hug_contacts(
	live_seat_list: Array[int], contacts: Array[Dictionary]
) -> Dictionary:
	var live: Dictionary = {}
	for seat in live_seat_list:
		live[seat] = true
	var best_distance: Dictionary = {}
	for contact in contacts:
		var seat_a := int(contact.get("seat_a", contact.get("seat_index", -1)))
		var seat_b := int(contact.get("seat_b", contact.get("other_seat_index", -1)))
		if seat_a == seat_b or not live.has(seat_a) or not live.has(seat_b):
			continue
		var low := mini(seat_a, seat_b)
		var high := maxi(seat_a, seat_b)
		var key := "%d:%d" % [low, high]
		var distance := float(contact.get("distance_squared", 0.0))
		if not best_distance.has(key) or distance < float(best_distance[key]):
			best_distance[key] = distance
	var pairs: Array[Dictionary] = []
	for key in best_distance:
		var parts := str(key).split(":")
		(
			pairs
			. append(
				{
					"seat_a": int(parts[0]),
					"seat_b": int(parts[1]),
					"distance_squared": float(best_distance[key]),
				}
			)
		)
	pairs.sort_custom(_hug_pair_less)
	var paired: Dictionary = {}
	for pair in pairs:
		var seat_a := int(pair.seat_a)
		var seat_b := int(pair.seat_b)
		if paired.has(seat_a) or paired.has(seat_b):
			continue
		paired[seat_a] = true
		paired[seat_b] = true
	return paired


static func _hug_pair_less(left: Dictionary, right: Dictionary) -> bool:
	if float(left.distance_squared) != float(right.distance_squared):
		return float(left.distance_squared) < float(right.distance_squared)
	if int(left.seat_a) != int(right.seat_a):
		return int(left.seat_a) < int(right.seat_a)
	return int(left.seat_b) < int(right.seat_b)


func begin(
	new_round_id: String,
	seats: Array[int],
	starting_score_units: Dictionary,
	random_stream: RandomNumberGenerator,
	gameplay_tuning: GameplayTuning,
	start_time: float = 0.0,
	initial_intent_sources: Dictionary = {}
) -> bool:
	reset()
	if (
		new_round_id.is_empty()
		or seats.size() < 2
		or seats.size() > 4
		or random_stream == null
		or gameplay_tuning == null
		or not gameplay_tuning.validate().is_empty()
		or not is_finite(start_time)
	):
		return false
	var unique: Dictionary = {}
	for seat in seats:
		if seat < 0 or unique.has(seat):
			return false
		unique[seat] = true
		marker_counts[seat] = 0
		var sources: Dictionary = {}
		for source in initial_intent_sources.get(seat, []):
			sources[str(source)] = true
		_input_sources[seat] = sources
	seat_indices = seats.duplicate()
	seat_indices.sort()
	live_seats = seat_indices.duplicate()
	starting_totals = starting_score_units.duplicate(true)
	for seat in seat_indices:
		if not starting_totals.has(seat):
			starting_totals[seat] = 0
	round_id = new_round_id
	_rng = random_stream
	_tuning = gameplay_tuning.duplicate(true) as GameplayTuning
	_now = start_time
	_next_base_launch = start_time
	active = true
	return true


func reset() -> void:
	active = false
	ended = false
	round_id = ""
	seat_indices.clear()
	live_seats.clear()
	marker_counts.clear()
	command_history.clear()
	terminal_outcomes.clear()
	elimination_records.clear()
	starting_totals.clear()
	no_elimination_commands = 0
	storm_active = false
	storm_landing_pending = false
	last_cluck = false
	last_cluck_seat = -1
	commit_done = false
	twist_role = false
	secured_seats.clear()
	_external_causes.clear()
	_rng = null
	_tuning = null
	_now = 0.0
	_next_base_launch = -1.0
	_next_storm_landing = -1.0
	_next_command_id = 1
	_storm_pair_next = -1
	_input_sources.clear()
	_input_events.clear()
	_processed_input_edges.clear()
	_hazards.clear()
	_event_sequence = 0
	_step_had_elimination = false
	_step_completed_count = 0
	_step_provisional_count = 0
	_step_storm_trigger_at = -1.0
	_step_physics_tick = -1
	# Drop the reference: `_step_actors` is the room's own actor map, so clearing it in place
	# removed every chicken from the room before the next round (fixed 2026-10-15, P12).
	_step_actors = {}
	_step_support_tracker = null
	_step_hug_contacts.clear()


func record_intent_edge(
	seat: int, source_id: String, pressed: bool, simulation_time: float
) -> void:
	if not active or ended or not seat_indices.has(seat) or source_id.is_empty():
		return
	if not is_finite(simulation_time):
		return
	_event_sequence += 1
	(
		_input_events
		. append(
			{
				"seat": seat,
				"source": source_id,
				"pressed": pressed,
				"time": maxf(_now, simulation_time),
				"sequence": _event_sequence,
			}
		)
	)


func sync_intent_sources(seat: int, sources: Array[String]) -> void:
	if not seat_indices.has(seat):
		return
	var snapshot: Dictionary = {}
	for source in sources:
		snapshot[source] = true
	_input_sources[seat] = snapshot


func active_time() -> float:
	return _now


func submit_hazard(record: AttributionRecord) -> bool:
	if (
		not active
		or ended
		or record == null
		or record.kind != AttributionRecord.Kind.ELIMINATION
		or not live_seats.has(record.player_seat)
		or (not record.round_id.is_empty() and record.round_id != round_id)
	):
		return false
	for existing in _hazards:
		if not record.event_id.is_empty() and existing.event_id == record.event_id:
			return false
	_hazards.append(record)
	return true


## Kangaroo+Lagsanay: the Bomb-Taya timeout is fed to this Main Challenge as an elimination
## with a comparable time, so command failure, timeout and trap order by recorded time (ties:
## command failure, then timeout, then trap). It earns no Patibong.
func submit_external_elimination(
	seat: int, event_time: float, event_id: String, cause: String
) -> bool:
	if not active or ended or not live_seats.has(seat) or event_id.is_empty():
		return false
	var record := AttributionRecord.new()
	record.kind = AttributionRecord.Kind.ELIMINATION
	record.player_seat = seat
	record.physics_time = event_time
	record.physics_tick = Engine.get_physics_frames()
	record.time_comparable = true
	record.round_id = round_id
	record.event_id = event_id
	_external_causes[event_id] = cause
	if not submit_hazard(record):
		_external_causes.erase(event_id)
		return false
	return true


## A finisher (Karera Main) leaves command, Hug and hazard eligibility without an elimination.
func secure_seat(seat: int) -> void:
	if not live_seats.has(seat):
		return
	live_seats.erase(seat)
	if not secured_seats.has(seat):
		secured_seats.append(seat)


## A seat the Main Challenge eliminated outside this controller (bounds escape, deadline).
func mark_externally_eliminated(seat: int) -> void:
	if not live_seats.has(seat):
		return
	live_seats.erase(seat)
	no_elimination_commands = 0
	storm_active = false
	storm_landing_pending = false
	_next_storm_landing = -1.0
	_storm_pair_next = -1


func advance_to(
	simulation_time: float,
	physics_tick: int,
	actors: Dictionary,
	support_tracker: SupportTracker,
	hug_contacts: Array[Dictionary]
) -> Dictionary:
	if not active or ended or not is_finite(simulation_time) or simulation_time < _now:
		return {"advanced": false, "new_outcomes": [], "completed_commands": 0}
	_step_physics_tick = physics_tick
	_step_actors = actors
	_step_support_tracker = support_tracker
	_step_hug_contacts = hug_contacts.duplicate(true)
	_processed_input_edges.clear()
	_step_had_elimination = false
	_step_completed_count = 0
	_step_provisional_count = no_elimination_commands
	_step_storm_trigger_at = -1.0
	var previous_outcomes := terminal_outcomes.size()
	var iterations := 0
	while iterations < 4096:
		iterations += 1
		var event_time := _next_event_time(simulation_time)
		if not is_finite(event_time) or event_time > simulation_time:
			break
		_process_inputs_at(event_time)
		_start_responses_at(event_time)
		_check_freeze_graces_at(event_time)
		var completed_here := _evaluate_commands_at(event_time)
		_apply_hazards_at(event_time, simulation_time)
		if completed_here > 0 and not _step_had_elimination:
			if (
				_step_provisional_count >= _tuning.kangaroo_storm_after_commands
				and not storm_active
				and not twist_role
			):
				storm_active = true
				_next_base_launch = -1.0
				_step_storm_trigger_at = event_time
				_next_storm_landing = event_time + _tuning.kangaroo_storm_landing_seconds
		_process_launches_at(event_time)
		_maybe_resume_base_after_drain(event_time)
	if iterations >= 4096:
		push_error("Kangaroo scheduler exceeded its deterministic event bound.")
	if _step_had_elimination:
		no_elimination_commands = 0
		storm_active = false
		storm_landing_pending = false
		_next_storm_landing = -1.0
		_next_base_launch = -1.0
		_storm_pair_next = -1
	else:
		no_elimination_commands = _step_provisional_count
		if _step_storm_trigger_at >= 0.0:
			storm_active = true
	if not twist_role and live_seats.size() <= 1:
		_end_round()
	_now = simulation_time
	return {
		"advanced": true,
		"new_outcomes": terminal_outcomes.slice(previous_outcomes),
		"completed_commands": _step_completed_count,
		"ended": ended,
		"last_cluck": last_cluck,
	}


func active_commands() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for command in command_history:
		if str(command.get("status", "")) in ["TELEGRAPH", "RESPONSE"]:
			result.append(command.duplicate(true))
	return result


func presentation_commands(at_time: float) -> Array[Dictionary]:
	var result := active_commands()
	for index in range(command_history.size() - 1, -1, -1):
		var command: Dictionary = command_history[index]
		if (
			int(command.get("command", -1)) == Command.RISING
			and not bool(command.get("is_storm", false))
			and str(command.get("status", "")) == "COMPLETE"
			and float(command.get("reset_seconds", 0.0)) > 0.0
			and at_time < float(command.get("evaluated_at", -1.0)) + float(command.reset_seconds)
		):
			var draining := command.duplicate(true)
			draining.status = "DRAIN"
			result.append(draining)
			break
	return result


func outcomes() -> Array[Dictionary]:
	return terminal_outcomes.duplicate(true)


func score_result() -> Dictionary:
	if not ended:
		return {"valid": false, "reason": "Kangaroo round has not ended."}
	return KangarooScoreCalculator.calculate(
		seat_indices, elimination_records, live_seats, terminal_outcomes, starting_totals
	)


func commit_score_once(result: Dictionary) -> bool:
	if commit_done or not ended or not bool(result.get("valid", false)):
		return false
	commit_done = true
	last_cluck = bool(result.get("last_cluck", false))
	last_cluck_seat = int(result.get("last_cluck_seat", -1))
	return true


func _next_event_time(limit: float) -> float:
	var next := INF
	if _next_base_launch >= 0.0 and live_seats.size() >= _command_min_live():
		next = minf(next, maxf(_now, _next_base_launch))
	if storm_active and _next_storm_landing >= 0.0 and live_seats.size() > 1:
		next = minf(next, maxf(_now, _next_storm_landing))
	for event in _input_events:
		next = minf(next, maxf(_now, float(event.time)))
	for record in _hazards:
		var at := float(record.physics_time) if record.time_comparable else limit
		next = minf(next, maxf(_now, at))
	for command in command_history:
		if bool(command.evaluated):
			continue
		if not bool(command.response_started):
			next = minf(next, maxf(_now, float(command.response_start_at)))
		elif (
			int(command.command) == Command.FREEZE
			and not bool(command.grace_checked)
			and float(command.grace_at) >= 0.0
		):
			next = minf(next, maxf(_now, float(command.grace_at)))
		next = minf(next, maxf(_now, float(command.response_end_at)))
	return next


func _process_inputs_at(event_time: float) -> void:
	var same_time: Array[Dictionary] = []
	for event in _input_events:
		if float(event.time) <= event_time:
			same_time.append(event)
	same_time.sort_custom(
		func(left: Dictionary, right: Dictionary) -> bool:
			if float(left.time) != float(right.time):
				return float(left.time) < float(right.time)
			return int(left.sequence) < int(right.sequence)
	)
	for event in same_time:
		var event_time_value := float(event.time)
		var seat := int(event.seat)
		var source := str(event.source)
		for command in command_history:
			if (
				int(command.command) == Command.FREEZE
				and not bool(command.evaluated)
				and event_time_value >= float(command.response_start_at)
				and event_time_value <= float(command.response_end_at)
				and live_seats.has(seat)
				and bool(event.pressed)
			):
				command.freeze_violations[seat] = true
		var sources: Dictionary = _input_sources.get(seat, {})
		if bool(event.pressed):
			sources[source] = true
		else:
			sources.erase(source)
		_input_sources[seat] = sources
		_processed_input_edges.append(event.duplicate(true))
		_input_events.erase(event)


func _start_responses_at(event_time: float) -> void:
	for command in command_history:
		if (
			bool(command.evaluated)
			or bool(command.response_started)
			or float(command.response_start_at) > event_time
		):
			continue
		command.response_started = true
		command.status = "RESPONSE"
		if int(command.command) != Command.FREEZE:
			continue
		for seat in live_seats:
			var sources: Dictionary = _input_sources.get(seat, {})
			var held: Array[String] = []
			for source in sources:
				held.append(str(source))
			held.sort()
			command.initial_held_sources[seat] = held
			if not held.is_empty():
				command.grace_at = (
					float(command.response_start_at) + _tuning.kangaroo_freeze_release_seconds
				)
			for event in _processed_input_edges:
				if (
					live_seats.has(int(event.seat))
					and bool(event.pressed)
					and float(event.time) >= float(command.response_start_at)
					and float(event.time) <= float(command.response_end_at)
				):
					command.freeze_violations[int(event.seat)] = true


func _check_freeze_graces_at(event_time: float) -> void:
	for command in command_history:
		if (
			int(command.command) != Command.FREEZE
			or bool(command.evaluated)
			or not bool(command.response_started)
			or bool(command.grace_checked)
			or float(command.grace_at) < 0.0
			or float(command.grace_at) > event_time
		):
			continue
		command.grace_checked = true
		for seat in live_seats:
			for source in command.initial_held_sources.get(seat, []):
				if _input_sources.get(seat, {}).has(str(source)):
					command.freeze_violations[seat] = true


func _evaluate_commands_at(event_time: float) -> int:
	var due: Array[Dictionary] = []
	for command in command_history:
		if (
			not bool(command.evaluated)
			and bool(command.response_started)
			and float(command.response_end_at) <= event_time
		):
			due.append(command)
	due.sort_custom(
		func(left: Dictionary, right: Dictionary) -> bool:
			return int(left.command_id) < int(right.command_id)
	)
	for command in due:
		var paired := (
			pair_hug_contacts(live_seats, _step_hug_contacts)
			if int(command.command) == Command.HUG
			else {}
		)
		for seat in live_seats.duplicate():
			var actor := _step_actors.get(seat) as ChickenController
			if actor == null or not is_instance_valid(actor) or actor.lifecycle.is_terminal():
				continue
			var passed := false
			match int(command.command):
				Command.FREEZE:
					passed = not bool(command.freeze_violations.get(seat, false))
				Command.RISING:
					if _step_support_tracker != null:
						var support := _step_support_tracker.evaluate(
							actor.support_actor_id,
							float(command.wave_y),
							_tuning.support_height_epsilon_wu
						)
						passed = bool(support.get("qualifies", false))
				Command.HUG:
					passed = bool(paired.get(seat, false))
			command.pass_by_seat[seat] = passed
			if not passed:
				command.failure_seats.append(seat)
		command.evaluated = true
		command.status = "COMPLETE"
		command.evaluated_at = float(command.response_end_at)
		_step_completed_count += 1
		if not _step_had_elimination:
			_step_provisional_count += 1
		for seat in command.failure_seats:
			if not live_seats.has(int(seat)):
				continue
			var next_marker := int(marker_counts.get(seat, 0)) + 1
			marker_counts[seat] = mini(next_marker, 3)
			if next_marker >= 3:
				_record_elimination(
					{
						"seat_index": int(seat),
						"cause": "command_failure",
						"physics_tick": _step_physics_tick,
						"physics_time": float(command.response_end_at),
						"time_comparable": true,
						"direct_owner_seat": -1,
						"source_item_id": "",
						"event_id": "%s:kangaroo:%d:%d" % [round_id, command.command_id, seat],
					}
				)
		command.reset_seconds = (
			0.0
			if bool(command.is_storm)
			else (
				_tuning.kangaroo_reset_seconds
				if _step_had_elimination
				else _reset_for_count(_step_provisional_count)
			)
		)
		_schedule_after_command(command, event_time)
	return due.size()


func _apply_hazards_at(event_time: float, limit: float) -> void:
	var due: Array[AttributionRecord] = []
	for record in _hazards:
		var record_time := float(record.physics_time) if record.time_comparable else limit
		if record_time <= event_time:
			due.append(record)
	due.sort_custom(
		func(left: AttributionRecord, right: AttributionRecord) -> bool:
			if left.source_item_id != right.source_item_id:
				return left.source_item_id < right.source_item_id
			return left.player_seat < right.player_seat
	)
	for record in due:
		_hazards.erase(record)
		if not live_seats.has(record.player_seat):
			continue
		_record_elimination(
			{
				"seat_index": record.player_seat,
				"cause": str(_external_causes.get(record.event_id, "direct_hazard")),
				"physics_tick":
				record.physics_tick if record.physics_tick >= 0 else _step_physics_tick,
				"physics_time": record.physics_time,
				"time_comparable": record.time_comparable,
				"direct_owner_seat": record.owner_seat if record.credit_eligible() else -1,
				"source_item_id": record.source_item_id,
				"event_id": record.event_id,
			}
		)


func _record_elimination(outcome: Dictionary) -> void:
	var seat := int(outcome.get("seat_index", -1))
	if not live_seats.has(seat):
		return
	live_seats.erase(seat)
	terminal_outcomes.append(outcome.duplicate(true))
	(
		elimination_records
		. append(
			{
				"seat_index": seat,
				"physics_tick": int(outcome.get("physics_tick", _step_physics_tick)),
				"physics_time": float(outcome.get("physics_time", _now)),
				"time_comparable": bool(outcome.get("time_comparable", false)),
			}
		)
	)
	_step_had_elimination = true
	no_elimination_commands = 0
	_step_provisional_count = 0
	storm_active = false
	storm_landing_pending = false
	_next_storm_landing = -1.0
	_next_base_launch = -1.0
	_storm_pair_next = -1


func _schedule_after_command(command: Dictionary, evaluated_at: float) -> void:
	if storm_active or bool(command.is_storm):
		if _step_had_elimination:
			storm_active = false
			if _active_storm_count() == 0 and live_seats.size() > 1:
				_next_base_launch = evaluated_at + _tuning.kangaroo_reset_seconds
			return
		if storm_landing_pending and _active_storm_count() < _tuning.kangaroo_storm_max_active:
			storm_landing_pending = false
			_next_storm_landing = evaluated_at
		return
	if not _step_had_elimination:
		var adjusted_reset := _reset_for_count(_step_provisional_count)
		_next_base_launch = evaluated_at + adjusted_reset
	else:
		_next_base_launch = evaluated_at + _tuning.kangaroo_reset_seconds


func _process_launches_at(event_time: float) -> void:
	if live_seats.size() < _command_min_live():
		_next_base_launch = -1.0
		_next_storm_landing = -1.0
		return
	if storm_active and _next_storm_landing >= 0.0 and _next_storm_landing <= event_time:
		_next_storm_landing = -1.0
		if _active_storm_count() >= _tuning.kangaroo_storm_max_active:
			storm_landing_pending = true
		else:
			_launch_storm(event_time)
	if not storm_active and _next_base_launch >= 0.0 and _next_base_launch <= event_time:
		_next_base_launch = -1.0
		_launch_base(event_time)
	if (
		storm_active
		and storm_landing_pending
		and _active_storm_count() < _tuning.kangaroo_storm_max_active
	):
		storm_landing_pending = false
		_launch_storm(event_time)


## Standalone and Main rounds need two live seats for a command; as a Twist the last unfinished
## runner keeps receiving Freeze and Rising commands (P12 table U7).
func _command_min_live() -> int:
	return 1 if twist_role else 2


func _select_for_live() -> int:
	var count := live_seats.size()
	if twist_role and count == 1:
		return _rng.randi_range(Command.FREEZE, Command.RISING)
	return select_command(_rng, count)


func _launch_base(at_time: float) -> void:
	var selected := _select_for_live()
	if selected < 0:
		return
	var band := _rng.randi_range(0, 2) if selected == Command.RISING else -1
	var response := _response_for_count(_step_provisional_count)
	_create_command(selected, band, at_time, false, response)


func _launch_storm(at_time: float) -> void:
	if live_seats.size() <= 1:
		return
	var selected := -1
	if live_seats.size() == 2:
		if _storm_pair_next < 0:
			var first := Command.FREEZE if _rng.randi_range(0, 1) == 0 else Command.RISING
			_storm_pair_next = Command.RISING if first == Command.FREEZE else Command.FREEZE
			selected = first
		else:
			selected = _storm_pair_next
			_storm_pair_next = -1
	else:
		_storm_pair_next = -1
		selected = _rng.randi_range(Command.FREEZE, Command.HUG)
	var band := _rng.randi_range(0, 2) if selected == Command.RISING else -1
	_create_command(selected, band, at_time, true, _tuning.kangaroo_storm_active_seconds)
	_next_storm_landing = at_time + _tuning.kangaroo_storm_landing_seconds


func _create_command(
	selected: int, band: int, at_time: float, is_storm: bool, response: float
) -> void:
	var telegraph := _tuning.kangaroo_telegraph_seconds if not is_storm else 0.0
	var response_start := at_time + telegraph
	var response_end := response_start + response
	var command_id := _next_command_id
	var definition = COMMAND_INSTANCE_SCRIPT.new(
		command_id,
		selected,
		command_name(selected),
		is_storm,
		band,
		wave_y_for_band(_tuning, band),
		at_time,
		response_start,
		response_end
	)
	var row := {
		"instance": definition,
		"command_id": command_id,
		"command": selected,
		"command_name": command_name(selected),
		"is_storm": is_storm,
		"band": band,
		"wave_y": wave_y_for_band(_tuning, band),
		"telegraph_start_at": at_time,
		"response_start_at": response_start,
		"response_end_at": response_end,
		"reset_seconds": 0.0,
		"status": "RESPONSE" if is_storm else "TELEGRAPH",
		"response_started": is_storm,
		"evaluated": false,
		"evaluated_at": -1.0,
		"grace_at": -1.0,
		"grace_checked": false,
		"initial_held_sources": {},
		"freeze_violations": {},
		"pass_by_seat": {},
		"failure_seats": [],
	}
	command_history.append(row)
	_next_command_id += 1
	if command_history.size() > COMMAND_HISTORY_LIMIT:
		var remove_index := -1
		for index in range(command_history.size()):
			if bool(command_history[index].evaluated):
				remove_index = index
				break
		if remove_index >= 0:
			command_history.remove_at(remove_index)


func _active_storm_count() -> int:
	var count := 0
	for command in command_history:
		if bool(command.is_storm) and not bool(command.evaluated):
			count += 1
	return count


## Once no command is pending and no launch is scheduled, the base cadence resumes after the
## standard reset. Fix (2026-10-15, P12): an elimination ends a Storm while a second Storm
## command can still be pending; that command used to drain in a later step without scheduling
## anything, so the round never launched another command and never ended.
func _maybe_resume_base_after_drain(event_time: float) -> void:
	if storm_active or live_seats.size() < _command_min_live() or _next_base_launch >= 0.0:
		return
	for command in command_history:
		if not bool(command.evaluated):
			return
	_next_base_launch = event_time + _tuning.kangaroo_reset_seconds


func _response_for_count(completed_count: int) -> float:
	var reductions := floori(float(completed_count) / 2.0)
	return maxf(1.0, _tuning.kangaroo_response_seconds - 0.5 * reductions)


func _reset_for_count(completed_count: int) -> float:
	var reductions := floori(float(completed_count) / 2.0)
	return maxf(0.0, _tuning.kangaroo_reset_seconds - 0.15 * reductions)


func _end_round() -> void:
	if ended:
		return
	active = false
	ended = true
	_next_base_launch = -1.0
	_next_storm_landing = -1.0
	storm_landing_pending = false
	for command in command_history:
		if not bool(command.evaluated):
			command.evaluated = true
			command.status = "CANCELLED"
	_input_events.clear()
	_hazards.clear()
	var survivors := live_seats.duplicate()
	var provisional := KangarooScoreCalculator.calculate(
		seat_indices, elimination_records, survivors, terminal_outcomes, starting_totals
	)
	last_cluck = bool(provisional.get("last_cluck", false))
	last_cluck_seat = int(provisional.get("last_cluck_seat", -1))

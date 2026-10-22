# gdlint: disable=max-line-length
extends SceneTree

## NLB-P07-T03 matrix runner (authored; deferred). For every round cell that the networked live
## route can select (under the development override: no cell is VERIFIED yet) and for 2, 3 and 4
## seats, it plays the same scripted round twice from the same seed: once on the offline scheduled
## P12 room (the oracle) and once on the networked live-build host room. Both use the one shared
## rules implementation; the run passes when the outcome ledger signature and every seat's exact
## eighth-point total match. Synthetic K1/K2 keyboard seats and synthetic gamepad IDs only: this
## is SYNTHETIC evidence, never physical-device evidence. Barya is disabled in both rooms here;
## Barya scoring stays covered by run_barya_tests.gd until a live Barya script is added.
## Prints one `P07_CELL <cell> seats=<n> result=<MATCH|MISMATCH|SKIPPED> ...` line per run.
## Run: Godot --headless --fixed-fps 60 --path tilaok! --script res://tests/run_nlb_p07_matrix_runner.gd

const ORACLE_ROOM := preload("res://scenes/match/p12_scheduled_match_room.tscn")
const LIVE_ROOM := preload("res://scenes/match/nlb_p06_network_live_build_room.tscn")
## preload, not the NLBLiveCompatibilityMatrix global class name: a global class identifier is not
## a constant expression, so `const M := NLBLiveCompatibilityMatrix` fails to parse.
const M := preload("res://scripts/network/nlb_live_compatibility_matrix.gd")
const SEED := 7307
const MAX_STEPS := 900
const KARERA := EventSchedule.Challenge.KARERA
const LAGSANAY := EventSchedule.Challenge.LAGSANAY
const KANGAROO := EventSchedule.Challenge.KANGAROO
const NONE := EventSchedule.Challenge.NONE
const ROUND_ENTRIES := {
	"round:karera": [KARERA, NONE],
	"round:lagsanay": [LAGSANAY, NONE],
	"round:kangaroo": [KANGAROO, NONE],
	"round:stack_karera_lagsanay": [KARERA, LAGSANAY],
	"round:stack_karera_kangaroo": [KARERA, KANGAROO],
	"round:stack_kangaroo_lagsanay": [KANGAROO, LAGSANAY],
}

var runs := 0
var mismatches := 0
var _serial := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var cell_ids: Array = ROUND_ENTRIES.keys()
	cell_ids.sort()
	for cell_id in cell_ids:
		if not M.selectable(str(cell_id), true):
			print("P07_CELL %s seats=all result=SKIPPED reason=%s" % [cell_id, M.resolve(str(cell_id), true).reason])
			continue
		for seat_count in [2, 3, 4]:
			var oracle := await _play(ORACLE_ROOM, false, seat_count, ROUND_ENTRIES[cell_id])
			var live := await _play(LIVE_ROOM, true, seat_count, ROUND_ENTRIES[cell_id])
			runs += 1
			var same: bool = (
				bool(oracle.ok) and bool(live.ok)
				and str(oracle.signature) == str(live.signature)
				and oracle.totals == live.totals
			)
			if not same:
				mismatches += 1
			print(
				"P07_CELL %s seats=%d result=%s oracle=%s live=%s"
				% [cell_id, seat_count, "MATCH" if same else "MISMATCH", JSON.stringify(oracle), JSON.stringify(live)]
			)
	print("NLB_P07_MATRIX runs=%d mismatches=%d evidence=SYNTHETIC" % [runs, mismatches])
	await process_frame
	quit(1 if mismatches > 0 or runs == 0 else 0)


## One scripted round: seat 0 reaches the goal (Karera) or survives (events); seat 1 is removed by
## a trap owned by seat 0 (Patibong where the mode awards it); every other seat by an ownerless
## trap. Returns {ok, signature, totals}.
func _play(scene: PackedScene, live: bool, seat_count: int, pair: Array) -> Dictionary:
	_serial = 0
	var room := scene.instantiate() as P12ScheduledMatchRoom
	if live:
		(room as NLBP06NetworkLiveBuildMatchRoom).unverified_content = true
		(room as NLBP06NetworkLiveBuildMatchRoom).go_countdown_seconds = 0.1
	root.add_child(room)
	await process_frame
	await physics_frame
	room.set_match_seed(SEED)
	var seats: Array[int] = [room.join_keyboard("K1"), room.join_keyboard("K2")]
	for device_id in [7101, 7102].slice(0, seat_count - 2):
		var seat_index := room.input_router.registry.join_gamepad(device_id)
		seats.append(seat_index)
		room.input_router.seat_joined.emit(seat_index)
	for seat_index in seats:
		room.input_router.registry.set_ready(seat_index, true)
	room.tuning.barya_enabled = false
	if not room.start_match():
		await _close(room)
		return {"ok": false, "signature": "start refused", "totals": {}}
	room.schedule.locked[1] = {
		"round": 1, "main": int(pair[0]), "twist": int(pair[1]),
		"guaranteed": false, "sudden_death": false, "twist_options": 0,
	}
	room.tuning.match_target_score_units = 100000
	room.tuning.match_results_advance_seconds = 600.0
	room.tuning.kangaroo_telegraph_seconds = 0.05
	room.tuning.kangaroo_response_seconds = 1.0
	room.tuning.kangaroo_reset_seconds = 0.05
	room._finish_pugad_timeout()
	if live:
		room._process(0.2)
	else:
		var edits: Array[Dictionary] = []
		room._resolve_place_edits(edits)
	if room.phase_controller.phase != MatchPhaseController.Phase.PLAY:
		await _close(room)
		return {"ok": false, "signature": "no Play", "totals": {}}
	await physics_frame
	await physics_frame
	if int(pair[0]) == KARERA:
		room.race_candidate_queue.queue_goal(room.actors[seats[0]] as ChickenController, Engine.get_physics_frames())
	await physics_frame
	_trap(room, seats[1], seats[0])
	for seat_index in seats.slice(2):
		await physics_frame
		_trap(room, seat_index, -1)
	var steps := 0
	while room.phase_controller.phase == MatchPhaseController.Phase.PLAY and steps < MAX_STEPS:
		await physics_frame
		steps += 1
	var totals := {}
	for seat_index in seats:
		totals[str(seat_index)] = int(room.cumulative_score_units.get(seat_index, 0))
	var signature := _ledger_signature(room)
	var ok := room.phase_controller.phase != MatchPhaseController.Phase.PLAY
	await _close(room)
	return {"ok": ok, "signature": signature, "totals": totals}


## Tick-independent outcome rows (absolute physics ticks differ between the two runs).
func _ledger_signature(room: P12ScheduledMatchRoom) -> String:
	if room.race_round_controller == null:
		return ""
	var rows := PackedStringArray()
	var outcomes: Dictionary = room.race_round_controller.ledger.outcomes_by_seat
	var seat_ids: Array = outcomes.keys()
	seat_ids.sort()
	for seat_index in seat_ids:
		var outcome: Dictionary = outcomes[seat_index]
		rows.append(
			"%d:%s:%s:%d"
			% [
				int(seat_index),
				str(outcome.get("kind", "")),
				str(outcome.get("cause", "")),
				int(outcome.get("owner_seat", -1)),
			]
		)
	return ";".join(rows)


func _trap(room: P12ScheduledMatchRoom, seat: int, owner: int) -> void:
	_serial += 1
	var record := AttributionRecord.new()
	record.kind = AttributionRecord.Kind.ELIMINATION
	record.player_seat = seat
	record.source_item_id = "trap.p07.%d" % _serial
	record.owner_seat = owner
	record.physics_time = room.items.director.simulation_time + 0.004
	record.physics_tick = Engine.get_physics_frames()
	record.time_comparable = true
	record.round_id = room.items.director.active_round_id
	record.event_id = "%s:item:%s:%d:%d" % [record.round_id, record.source_item_id, record.physics_tick, seat]
	room._on_item_elimination(record)


func _close(room: Node) -> void:
	if room != null and is_instance_valid(room):
		room.queue_free()
	await process_frame
	await process_frame

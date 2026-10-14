extends SceneTree

## Place phase, first come, first served (requested by Jorge, 2026-10-14): a confirmed placement
## claims its cells at once, later players cannot confirm over them, and edits resolve in
## confirmation order. Also checks the main match selector offers every main-game block scene.
## Synthetic input in the real P05 match room. Run:
## godot --headless --path tilaok! --script res://tests/run_place_claim_tests.gd

const MATCH_SCENE := preload("res://scenes/match/match_room.tscn")
const KAING := "build.hollow_blocks.cell_1x1"
const SPIKES := "block.spikes.main"
const CANNON := "block.cannon.main"

var failures := 0
var checks := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_selector_pool()
	_test_resolver_uses_confirm_order()
	await _test_room_first_come_first_served()
	await _test_timeout_respects_claims()
	await _test_match_spikes_kill()
	print("PLACE_CLAIM_TESTS checks=%d failures=%d" % [checks, failures])
	await process_frame
	quit(1 if failures > 0 else 0)


func _check(condition: bool, label: String) -> void:
	checks += 1
	if condition:
		print("PASS ", label)
	else:
		failures += 1
		push_error("FAIL " + label)


func _test_selector_pool() -> void:
	var allowed := P07FirstPlayableMatchRoom.allowed_variants()
	_check(
		allowed.has(SPIKES) and allowed.has(CANNON) and allowed.has(KAING),
		"the match selector offers Spikes, Cannon and the construction blocks: %s" % [allowed]
	)
	var tuning := GameplayTuning.new()
	tuning.item_enabled_variants = allowed
	var definitions := ItemDefinitions.load_all(tuning)
	var seen := {}
	for seed_value in range(1, 41):
		var streams := SeededDiagnosticStreams.new()
		streams.seed_all(seed_value)
		for egg in PugadEggPoolGenerator.generate(definitions, tuning, streams, 4):
			seen[str(egg.variant_key)] = true
	_check(
		seen.has(SPIKES) and seen.has(CANNON),
		"seeded Pugad eggs include Spikes and Cannon (%d variants seen)" % seen.size()
	)
	_check(
		definitions.short_label(SPIKES) == "Spikes", "single-size blocks are labelled by name only"
	)


func _test_resolver_uses_confirm_order() -> void:
	var tuning := GameplayTuning.new()
	var definitions := ItemDefinitions.load_all(tuning)
	var arena := ArenaDefinition.new(tuning)
	var edits: Array[Dictionary] = [
		{
			"seat_index": 0,
			"variant_key": KAING,
			"origin_cell": Vector2i(14, 8),
			"quarter_turns": 0,
			"cleanup_targets": [],
			"confirm_order": 1,
		},
		{
			"seat_index": 1,
			"variant_key": KAING,
			"origin_cell": Vector2i(14, 8),
			"quarter_turns": 0,
			"cleanup_targets": [],
			"confirm_order": 0,
		},
	]
	var result := AtomicEditResolver.resolve(definitions, arena, tuning, [], edits, 0)
	_check(
		(
			(result.commits as Array).size() == 1
			and int(result.commits[0].seat_index) == 1
			and (result.rejections as Dictionary).has(0)
		),
		"the seat that confirmed first keeps a contested spot (not the lower seat number)"
	)


func _start_two_seat_place() -> P05MatchRoom:
	var room := MATCH_SCENE.instantiate() as P05MatchRoom
	root.add_child(room)
	await process_frame
	room.join_keyboard("K1")
	room.join_keyboard("K2")
	room.input_router.registry.set_ready(0, true)
	room.input_router.registry.set_ready(1, true)
	room.start_match()
	room.assignments = {0: str(room.egg_pool[0].egg_id), 1: str(room.egg_pool[1].egg_id)}
	room._enter_place()
	for seat_index in [0, 1]:
		var cursor: Dictionary = room.placement_controller.cursors[seat_index]
		cursor.variant_key = KAING
		cursor.cell = Vector2i(14, 8)
		cursor.quarter_turns = 0
		room.placement_controller.cursors[seat_index] = cursor
	room._refresh_all_match_ghosts()
	return room


func _test_room_first_come_first_served() -> void:
	var room := await _start_two_seat_place()
	_check(
		bool(room._placement_verdict(0).allowed) and bool(room._placement_verdict(1).allowed),
		"before anyone confirms, both players may aim at the same free spot"
	)
	room._confirm_placement(1)
	_check(room.placement_controller.is_confirmed(1), "P2 confirms first and claims the spot")
	var p1_verdict := room._placement_verdict(0)
	_check(
		not bool(p1_verdict.allowed) and str(p1_verdict.reason).contains("Taken by P2"),
		"P1's ghost now shows the spot as taken by P2: %s" % p1_verdict.reason
	)
	_check(
		not bool(room.placement_verdicts[0].allowed),
		"P1's ghost turned invalid as soon as P2 confirmed"
	)
	room._confirm_placement(0)
	_check(
		not room.placement_controller.is_confirmed(0),
		"P1 cannot confirm on the claimed spot (first come, first served)"
	)
	room.placement_controller.move(0, Vector2i(2, 0))
	room._refresh_all_match_ghosts()
	_check(bool(room._placement_verdict(0).allowed), "a free spot elsewhere is still allowed")
	room._confirm_placement(0)
	var owners := {}
	for record in room.items.pieces.values():
		owners[(record as PlacedItem).origin_cell] = (record as PlacedItem).owner_seat
	_check(
		owners.get(Vector2i(14, 8), -1) == 1 and owners.get(Vector2i(16, 8), -1) == 0,
		"both placements commit: P2 owns the contested spot, P1 its free one"
	)
	room.queue_free()
	await process_frame


func _test_timeout_respects_claims() -> void:
	var room := await _start_two_seat_place()
	room._confirm_placement(1)
	room._finish_place_timeout()
	var owners: Array[int] = []
	for record in room.items.pieces.values():
		owners.append((record as PlacedItem).owner_seat)
	_check(
		owners == [1],
		"at the timer, an unconfirmed placement on a claimed spot is discarded (%s)" % [owners]
	)
	room.queue_free()
	await process_frame


## Regression (2026-10-15): in a real match the race ledger accepts only same-tick kills, so the
## hazard director must report before the room resolves the race. Spikes must eliminate.
func _test_match_spikes_kill() -> void:
	var room := await _start_two_seat_place()
	for seat_index in [0, 1]:
		var cursor: Dictionary = room.placement_controller.cursors[seat_index]
		cursor.variant_key = SPIKES
		cursor.cell = Vector2i(16, 14) if seat_index == 0 else Vector2i(13, 14)
		room.placement_controller.cursors[seat_index] = cursor
	room._confirm_placement(0)
	room._confirm_placement(1)
	_check(
		room.phase_controller.phase == MatchPhaseController.Phase.PLAY,
		"both spike placements commit and Play starts"
	)
	var actor := room.actors[0] as ChickenController
	for _frame in range(70):
		await physics_frame
	actor.global_position = Vector2(14.0 * 64.0 + 32.0, 900.0)
	room.input_router._stick_x[0] = 1.0
	var died := false
	for _frame in range(120):
		await physics_frame
		if actor.lifecycle.status == PlayerLifecycleState.Status.ELIMINATED:
			died = true
			break
	room.input_router._stick_x[0] = 0.0
	_check(died, "walking into placed spikes eliminates the chicken in a real match")
	var ledger := room.race_round_controller.ledger
	_check(
		ledger.outcomes_by_seat.has(0) and str(ledger.outcomes_by_seat[0].outcome) != "finished",
		"the race ledger records the spike elimination"
	)
	room.queue_free()
	await process_frame

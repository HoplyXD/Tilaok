extends SceneTree

## Place conflicts. First come, first served (2026-10-14) was removed on 2026-10-16 at Jorge's
## request: confirming earlier gives no advantage, a ghost only says "Tile occupied" (a piece,
## the stage or a chicken is there) or "Invalid spot", and same-phase overlaps resolve in stable
## seat order as before (the later seat sees "Tile occupied"). Also checks the main match selector
## offers every main-game block scene and that placed spikes kill in a real match.
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
	_test_resolver_seat_order()
	await _test_room_no_claims()
	await _test_timeout_seat_order()
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


func _test_resolver_seat_order() -> void:
	var tuning := GameplayTuning.new()
	var definitions := ItemDefinitions.load_all(tuning)
	var arena := ArenaDefinition.new(tuning)
	var edits: Array[Dictionary] = [
		{
			"seat_index": 1,
			"variant_key": KAING,
			"origin_cell": Vector2i(14, 8),
			"quarter_turns": 0,
			"cleanup_targets": [],
		},
		{
			"seat_index": 0,
			"variant_key": KAING,
			"origin_cell": Vector2i(14, 8),
			"quarter_turns": 0,
			"cleanup_targets": [],
		},
	]
	var result := AtomicEditResolver.resolve(definitions, arena, tuning, [], edits, 0)
	_check(
		(
			(result.commits as Array).size() == 1
			and int(result.commits[0].seat_index) == 0
			and (result.rejections as Dictionary).has(1)
		),
		"two placements on one spot: the lower seat keeps it, confirmation order does not matter"
	)
	_check(
		P05MatchRoom.short_reason("", str(result.rejections[1])) == "Tile occupied",
		"the refused player is told: Tile occupied"
	)
	_check(
		(
			P05MatchRoom.short_reason("protected_spawn") == "Invalid spot"
			and P05MatchRoom.short_reason("immutable_base") == "Tile occupied"
		),
		"other refusals read Invalid spot; the stage itself reads Tile occupied"
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


func _test_room_no_claims() -> void:
	var room := await _start_two_seat_place()
	room._confirm_placement(1)
	_check(room.placement_controller.is_confirmed(1), "P2 confirms a spot")
	var p1_verdict := room._placement_verdict(0)
	_check(
		bool(p1_verdict.allowed) and bool(room.placement_verdicts[0].allowed),
		"P1 is not blocked by P2's confirmed spot (no first come, first served)"
	)
	room._confirm_placement(0)
	var owners := {}
	for record in room.items.pieces.values():
		owners[(record as PlacedItem).origin_cell] = (record as PlacedItem).owner_seat
	_check(
		owners.get(Vector2i(14, 8), -1) == 0 and owners.size() == 1,
		"both confirmed the same spot: P1 (lower seat) gets it even though P2 confirmed first"
	)
	_check(
		str(room.place_notice).contains("P2: Tile occupied"),
		"P2 is told Tile occupied: %s" % room.place_notice
	)
	room.queue_free()
	await process_frame


func _test_timeout_seat_order() -> void:
	var room := await _start_two_seat_place()
	room._confirm_placement(1)
	room._finish_place_timeout()
	var owners: Array[int] = []
	for record in room.items.pieces.values():
		owners.append((record as PlacedItem).owner_seat)
	_check(
		owners == [0],
		(
			"at the timer, a valid unconfirmed placement still counts; seat order decides (%s)"
			% [owners]
		)
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
	# Drop onto the points (the kill hitbox sits inside the points; see run_blocks_tests).
	actor.global_position = Vector2(16.0 * 64.0 + 32.0, 700.0)
	actor.velocity = Vector2.ZERO
	var died := false
	for _frame in range(120):
		await physics_frame
		if actor.lifecycle.status == PlayerLifecycleState.Status.ELIMINATED:
			died = true
			break
	_check(died, "landing on placed spikes eliminates the chicken in a real match")
	var ledger := room.race_round_controller.ledger
	_check(
		ledger.outcomes_by_seat.has(0) and str(ledger.outcomes_by_seat[0].outcome) != "finished",
		"the race ledger records the spike elimination"
	)
	room.queue_free()
	await process_frame

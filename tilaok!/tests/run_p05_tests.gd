extends SceneTree

const MATCH_SCENE := preload("res://scenes/match/match_room.tscn")
const FIXTURE_SCRIPT := preload("res://tests/p05_fixtures.gd")
const VARIANT_1X1 := "build.hollow_blocks.cell_1x1"
const VARIANT_2X3 := "build.hollow_blocks.stack_2x3"
const VARIANT_TULAY := "build.bamboo_bridge.span_4x1"
const SEEDS := [12345, 7, 991]

var failures := 0
var checks := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_tuning_and_pool()
	_test_claim_permutations_and_timeout()
	_test_resolver_permutations_and_protection()
	_test_rejection_reason_matrix()
	_test_cleanup_once_and_batch_commit()
	_test_timeout_commit_and_discard()
	await _test_mover_and_solid_trigger_fixtures()
	_test_ten_round_persistence()
	_test_held_input_and_lobby_gate()
	await _test_pause_freezes_match_timers()
	await _test_results_timeout_advances()
	print("P05_TEST_SUMMARY checks=%d failures=%d" % [checks, failures])
	await process_frame
	await process_frame
	quit(1 if failures > 0 else 0)


func _test_tuning_and_pool() -> void:
	var tuning := GameplayTuning.new()
	_check(tuning.validate().is_empty(), "P05 phase tuning validates")
	var definitions := ItemDefinitions.load_all(tuning)
	var streams := SeededDiagnosticStreams.new()
	streams.seed_all(12345)
	var pool := PugadEggPoolGenerator.generate(definitions, tuning, streams, 6)
	_check(pool.size() == 6, "Pugad pool contains joined seats plus two eggs")
	var ids: Dictionary = {}
	for egg in pool:
		ids[str(egg.egg_id)] = true
		_check(
			tuning.item_enabled_variants.has(str(egg.variant_key)),
			"egg picks only enabled variant %s" % egg.variant_key
		)
	_check(
		ids.size() == pool.size(),
		"egg identifiers are unique while duplicate variants remain allowed"
	)
	var repeated_streams := SeededDiagnosticStreams.new()
	repeated_streams.seed_all(12345)
	var repeated := PugadEggPoolGenerator.generate(definitions, tuning, repeated_streams, 6)
	_check(pool == repeated, "egg pool is stable for the same match seed")
	var bad_tuning := tuning.duplicate(true) as GameplayTuning
	bad_tuning.match_pugad_seconds = 0.0
	_check(
		not bad_tuning.validate().is_empty(), "invalid P05 phase durations fail tuning validation"
	)


func _test_claim_permutations_and_timeout() -> void:
	for seed_value in SEEDS:
		for seat_count in range(2, 5):
			var seats := _seat_ids(seat_count)
			var eggs := _fake_eggs(seat_count + 2)
			var claims: Array[Dictionary] = []
			for seat_index in seats:
				claims.append({"seat_index": seat_index, "egg_id": "egg_00", "tick": 10})
			var first_stream := RandomNumberGenerator.new()
			first_stream.seed = seed_value
			var first := PugadClaimArbiter.resolve(eggs, claims, seats, first_stream)
			var reverse_claims := claims.duplicate(true)
			reverse_claims.reverse()
			var second_stream := RandomNumberGenerator.new()
			second_stream.seed = seed_value
			var second := PugadClaimArbiter.resolve(eggs, reverse_claims, seats, second_stream)
			_check(
				first.assignments == second.assignments,
				"seed %d %d-seat claim permutations resolve identically" % [seed_value, seat_count]
			)
			_check(
				first.assignments.size() == 1,
				"one contested egg has one owner at %d seats" % seat_count
			)
			_check(
				first.losers.size() == seat_count - 1,
				"all losing seats receive retry feedback at %d seats" % seat_count
			)
			var partial_claim: Array[Dictionary] = [
				{"seat_index": 0, "egg_id": "egg_00", "tick": 100}
			]
			var timeout_stream := RandomNumberGenerator.new()
			timeout_stream.seed = seed_value
			var partial := PugadClaimArbiter.resolve(eggs, partial_claim, seats, timeout_stream)
			var assigned_ids: Dictionary = {}
			for owner in partial.assignments.values():
				assigned_ids[str(owner)] = true
			var remaining: Array[Dictionary] = []
			for egg in eggs:
				if not assigned_ids.has(str(egg.egg_id)):
					remaining.append(egg)
			var complete := PugadClaimArbiter.assign_remaining(
				remaining, seats, partial.assignments, timeout_stream
			)
			var final_ids: Dictionary = {}
			for owner in complete.assignments.values():
				final_ids[str(owner)] = true
			_check(
				complete.assignments.size() == seat_count,
				"timeout assigns every remaining seat at %d seats" % seat_count
			)
			_check(
				final_ids.size() == seat_count,
				"timeout assignment never duplicates eggs at %d seats" % seat_count
			)
			var timeout_tick_stream := RandomNumberGenerator.new()
			timeout_tick_stream.seed = seed_value
			var final_tick_claim := PugadClaimArbiter.resolve(
				eggs,
				[{"seat_index": 0, "egg_id": "egg_01", "tick": 999}],
				seats,
				timeout_tick_stream
			)
			_check(
				str(final_tick_claim.assignments.get(0, "")) == "egg_01",
				"claim received on the final timeout tick resolves before auto-assignment"
			)


func _test_resolver_permutations_and_protection() -> void:
	var tuning := GameplayTuning.new()
	var definitions := ItemDefinitions.load_all(tuning)
	var arena := ArenaDefinition.new(tuning)
	var no_actors: Array[Rect2] = []
	var left := _edit(0, VARIANT_1X1, Vector2i(7, 5))
	var right := _edit(1, VARIANT_2X3, Vector2i(12, 5))
	var forward := AtomicEditResolver.resolve(
		definitions, arena, tuning, [], [right, left], 0, no_actors
	)
	var reverse := AtomicEditResolver.resolve(
		definitions, arena, tuning, [], [left, right], 0, no_actors
	)
	_check(
		forward.signature == reverse.signature,
		"resolver signatures ignore callback submission order"
	)
	_check(forward.commits.size() == 2, "valid non-overlapping construction edits commit together")
	var overlap := AtomicEditResolver.resolve(
		definitions,
		arena,
		tuning,
		[],
		[_edit(1, VARIANT_1X1, Vector2i(8, 5)), _edit(0, VARIANT_1X1, Vector2i(8, 5))],
		0,
		no_actors
	)
	_check(overlap.commits.size() == 1, "solid conflict resolves by stable seat order")
	_check(
		str(overlap.rejections.get(1, "")).contains("Overlaps another piece"),
		"conflicting whole edit set gets actionable rejection"
	)
	var whole_set := (
		AtomicEditResolver
		. resolve(
			definitions,
			arena,
			tuning,
			[],
			[
				_edit(0, VARIANT_1X1, Vector2i(8, 5)),
				_edit(0, VARIANT_1X1, Vector2i(8, 5)),
			],
			0,
			no_actors
		)
	)
	_check(whole_set.commits.is_empty(), "conflicting edits from one seat reject as a whole set")
	_check(whole_set.rejections.has(0), "whole-set rejection keeps a specific reason")
	var protected := AtomicEditResolver.resolve(
		definitions, arena, tuning, [], [_edit(0, VARIANT_1X1, Vector2i(4, 11))], 0, no_actors
	)
	_check(
		str(protected.rejections.get(0, "")).contains("protected spawn"),
		"spawn protection is enforced with readable reason"
	)
	var goal := AtomicEditResolver.resolve(
		definitions, arena, tuning, [], [_edit(0, VARIANT_1X1, Vector2i(28, 9))], 0, no_actors
	)
	_check(
		str(goal.rejections.get(0, "")).contains("protected goal"),
		"goal protection is enforced with readable reason"
	)
	var outside := AtomicEditResolver.resolve(
		definitions, arena, tuning, [], [_edit(0, VARIANT_1X1, Vector2i(32, 5))], 0, no_actors
	)
	_check(
		str(outside.rejections.get(0, "")).contains("Outside the arena"),
		"arena bounds rejection is actionable"
	)
	var stack := definitions.find_variant(VARIANT_2X3).variant as ItemVariantDefinition
	var rotated_rect := ItemPlacementValidator.footprint_rect_for(stack, Vector2i(12, 5), 1, tuning)
	_check(rotated_rect.size == Vector2(96.0, 64.0), "rotated 2x3 ghost swaps to a 3x2 footprint")


func _test_cleanup_once_and_batch_commit() -> void:
	var context := _new_item_context()
	var manager: ItemManager = context.manager
	var placed := manager.place(VARIANT_1X1, Vector2i(8, 5), 0, 0, [])
	_check(bool(placed.allowed), "cleanup test creates one prior-round construction item")
	var remove_events: Array[String] = []
	manager.item_removed.connect(
		func(instance_id: String, _reason: String) -> void: remove_events.append(instance_id)
	)
	manager.round_number = 1
	var target_id := str(placed.instance_id)
	var first := _edit(0, VARIANT_1X1, Vector2i(12, 5))
	first.cleanup_targets = [target_id]
	var second := _edit(1, VARIANT_1X1, Vector2i(14, 5))
	second.cleanup_targets = [target_id]
	var resolution := AtomicEditResolver.resolve(
		manager.definitions,
		manager.arena,
		manager.tuning,
		manager.pieces.values(),
		[first, second],
		manager.round_number,
		[]
	)
	_check(
		resolution.removals == [target_id], "snapshot cleanup targets are unioned and deduplicated"
	)
	var committed := manager.commit_batch(resolution)
	_check(bool(committed.allowed), "batch commit applies validated removals and additions")
	_check(remove_events.size() == 1, "overlapping cleanup executes exactly once")
	_check(manager.persistent_count() == 2, "batch creates both stable accepted edits")
	var same_phase_cleanup := _edit(0, VARIANT_1X1, Vector2i(16, 5))
	same_phase_cleanup.cleanup_targets = [str(committed.commits[0].instance_id)]
	var rejected_cleanup := AtomicEditResolver.resolve(
		manager.definitions,
		manager.arena,
		manager.tuning,
		manager.pieces.values(),
		[same_phase_cleanup],
		manager.round_number,
		[]
	)
	_check(
		rejected_cleanup.removals.is_empty(),
		"same-round construction cannot be removed in its own Place phase"
	)
	manager.reset_match()
	context.root.queue_free()
	await process_frame


func _test_rejection_reason_matrix() -> void:
	var tuning := GameplayTuning.new()
	var definitions := ItemDefinitions.load_all(tuning)
	var arena := ArenaDefinition.new(tuning)
	var empty: Array[PlacedItem] = []
	var no_actors: Array[Rect2] = []
	var test_cases: Array[Dictionary] = [
		{
			"key": "build.unknown.missing",
			"cell": Vector2i(8, 5),
			"turns": 0,
			"code": "unknown_variant"
		},
		{"key": VARIANT_1X1, "cell": Vector2i(8, 5), "turns": 0, "code": "variant_disabled"},
		{"key": VARIANT_TULAY, "cell": Vector2i(8, 5), "turns": 1, "code": "rotation_unsupported"},
		{"key": VARIANT_1X1, "cell": Vector2i(8, 5), "turns": 0, "code": "out_of_bounds"},
		{"key": VARIANT_1X1, "cell": Vector2i(4, 11), "turns": 0, "code": "protected_spawn"},
		{"key": VARIANT_1X1, "cell": Vector2i(28, 9), "turns": 0, "code": "protected_goal"},
		{"key": VARIANT_1X1, "cell": Vector2i(6, 2), "turns": 0, "code": "outside_build_region"},
		{"key": VARIANT_1X1, "cell": Vector2i(6, 14), "turns": 0, "code": "immutable_base"},
		{"key": VARIANT_1X1, "cell": Vector2i(8, 5), "turns": 0, "code": "player_clearance"},
		{"key": VARIANT_1X1, "cell": Vector2i(8, 5), "turns": 0, "code": "item_overlap"},
		{"key": VARIANT_1X1, "cell": Vector2i(8, 5), "turns": 0, "code": "persistent_cap"},
	]
	for case in test_cases:
		var case_tuning := tuning.duplicate(true) as GameplayTuning
		var case_definitions := ItemDefinitions.load_all(case_tuning)
		var existing: Array[PlacedItem] = empty.duplicate()
		var actors: Array[Rect2] = no_actors.duplicate()
		match str(case.code):
			"variant_disabled":
				case_tuning.item_enabled_variants = PackedStringArray([VARIANT_2X3, VARIANT_TULAY])
				case_definitions = ItemDefinitions.load_all(case_tuning)
			"player_clearance":
				actors.append(
					Rect2(
						Vector2(8.0, 5.0) * case_tuning.grid_cell_wu,
						Vector2.ONE * case_tuning.grid_cell_wu
					)
				)
			"item_overlap", "persistent_cap":
				var item := PlacedItem.new()
				item.instance_id = "test_existing"
				item.variant_key = VARIANT_1X1
				item.origin_cell = Vector2i(8, 5)
				item.footprint_rect = Rect2(
					Vector2(8.0, 5.0) * case_tuning.grid_cell_wu,
					Vector2.ONE * case_tuning.grid_cell_wu
				)
				existing.append(item)
				if str(case.code) == "persistent_cap":
					case_tuning.item_persistent_cap = 1
			"out_of_bounds":
				case.cell = Vector2i(32, 5)
		var verdict := ItemPlacementValidator.validate(
			case_definitions,
			ArenaDefinition.new(case_tuning),
			case_tuning,
			str(case.key),
			case.cell,
			int(case.turns),
			existing,
			actors
		)
		_check(
			str(verdict.code) == str(case.code),
			"validator returns the specific %s rejection reason" % case.code
		)
	var bad_families: Array[ItemFamilyDefinition] = []
	for family in definitions.families:
		bad_families.append(family.duplicate(true) as ItemFamilyDefinition)
	var stack_family := bad_families[0]
	var stack_variant := stack_family.find_variant("stack_2x3")
	var invalid_extent := ItemRegionSpec.new()
	invalid_extent.kind = ItemRegionSpec.Kind.EFFECT
	invalid_extent.rect_cells = Rect2(Vector2.ZERO, Vector2.ZERO)
	invalid_extent.declared_bounded = true
	stack_variant.regions.append(invalid_extent)
	var invalid_definitions := ItemDefinitions.from_families(bad_families, tuning)
	var invalid := ItemPlacementValidator.validate(
		invalid_definitions, arena, tuning, VARIANT_2X3, Vector2i(8, 5), 0, empty, no_actors
	)
	_check(
		str(invalid.code) == "invalid_region",
		"invalid authored region reports an item-rule rejection"
	)


func _test_timeout_commit_and_discard() -> void:
	var tuning := GameplayTuning.new()
	var definitions := ItemDefinitions.load_all(tuning)
	var controller := MatchPlacementController.new()
	controller.setup({0: VARIANT_1X1, 1: VARIANT_1X1}, definitions, tuning)
	var validity := {0: true, 1: false}
	var edits := controller.timeout_edits(validity)
	_check(
		edits.size() == 1 and int(edits[0].seat_index) == 0,
		"Place timeout commits valid unconfirmed cursor and discards invalid cursor"
	)
	controller.set_confirmed(0, true)
	_check(
		controller.confirmed_edits().size() == 1,
		"confirmed edits remain pending for the atomic batch"
	)
	_check(
		not controller.all_confirmed(), "one confirmed seat cannot end Place while another remains"
	)
	controller.set_confirmed(1, true)
	_check(controller.all_confirmed(), "Place ends when every seat confirms")


func _test_mover_and_solid_trigger_fixtures() -> void:
	var mover := FIXTURE_SCRIPT.MoverFixture.new() as Node2D
	mover.position = Vector2(64.0, 32.0)
	root.add_child(mover)
	await process_frame
	mover.position += Vector2(32.0, 0.0)
	mover.reset_to_start()
	_check(
		mover.position == Vector2(64.0, 32.0) and mover.reset_count == 1,
		"test-only mover resets cleanly to its authored start"
	)
	var danger := FIXTURE_SCRIPT.SolidAndTriggerFixture.new()
	_check(
		danger.overlap_is_labeled(),
		"solid/trigger intersection has an explicit danger-region label"
	)
	mover.queue_free()


func _test_ten_round_persistence() -> void:
	var context := _new_item_context()
	var manager: ItemManager = context.manager
	var placed := manager.place(VARIANT_1X1, Vector2i(8, 6), 0, 0, [])
	_check(bool(placed.allowed), "persistence test starts with construction")
	var instance_id := str(placed.instance_id)
	var start_signature := manager.construction_signature()
	for round_index in range(10):
		manager.begin_play()
		manager.end_round()
		if round_index == 4:
			manager.enter_place()
			manager.remove(instance_id, "p05_test_cleanup")
			start_signature = ""
		_check(
			manager.construction_signature() == start_signature,
			"round %d preserves current construction signature" % (round_index + 1)
		)
		_check(
			manager.persistent_count() <= 1,
			"round %d does not duplicate persistent pieces" % (round_index + 1)
		)
	_check(
		not manager.pieces.has(instance_id),
		"removed construction does not resurrect in later rounds"
	)
	manager.reset_match()
	_check(
		manager.persistent_count() == 0 and manager.round_number == 0,
		"match reset clears construction and round counter"
	)
	context.root.queue_free()


func _test_held_input_and_lobby_gate() -> void:
	var registry := PlayerSeatRegistry.new()
	var router := LocalInputRouter.new()
	root.add_child(router)
	router.registry = registry
	router.tuning = GameplayTuning.new()
	router.set_shared_keyboard_enabled(true)
	router.set_phase(LocalInputRouter.Phase.LOBBY)
	_check(not LobbyViewModel.can_start(registry), "lobby blocks a start with fewer than two seats")
	var seat0 := registry.join_keyboard("K1")
	var seat1 := registry.join_keyboard("K2")
	_check(seat0 == 0 and seat1 == 1, "keyboard identities receive stable seat numbers")
	_check(not LobbyViewModel.can_start(registry), "two unready seats cannot start")
	registry.set_ready(seat0, true)
	_check(not LobbyViewModel.can_start(registry), "lobby waits for every joined seat to be ready")
	registry.set_ready(seat1, true)
	_check(LobbyViewModel.can_start(registry), "two connected ready seats pass the lobby gate")
	router.set_phase(LocalInputRouter.Phase.PLACE)
	router._handle_action_edge(seat0, "confirm", "p05-test-confirm", true)
	router.set_phase(LocalInputRouter.Phase.RESULTS)
	_check(
		not router.consume_pressed(seat0, "confirm"),
		"phase transition consumes a held one-shot press"
	)
	router._handle_action_edge(seat0, "confirm", "p05-test-confirm", true)
	_check(
		not router.consume_pressed(seat0, "confirm"), "held confirm cannot leak into the next phase"
	)
	router._handle_action_edge(seat0, "confirm", "p05-test-confirm", false)
	router._handle_action_edge(seat0, "confirm", "p05-test-confirm", true)
	_check(
		router.consume_pressed(seat0, "confirm"),
		"released then pressed confirm is accepted in the new phase"
	)
	router.queue_free()


func _test_pause_freezes_match_timers() -> void:
	var room := MATCH_SCENE.instantiate() as P05MatchRoom
	root.add_child(room)
	await process_frame
	room.join_keyboard("K1")
	room.join_keyboard("K2")
	room.input_router.registry.set_ready(0, true)
	room.input_router.registry.set_ready(1, true)
	_check(room.start_match(), "paused-timer fixture starts an approved two-seat match")
	var pugad_remaining := room.phase_controller.remaining_seconds
	paused = true
	for _frame in range(5):
		await process_frame
	_check(
		is_equal_approx(room.phase_controller.remaining_seconds, pugad_remaining),
		"Pugad timer freezes while paused"
	)
	paused = false
	room.assignments = {0: "egg_01", 1: "egg_02"}
	room._enter_place()
	var place_remaining := room.phase_controller.remaining_seconds
	paused = true
	for _frame in range(5):
		await process_frame
	_check(
		is_equal_approx(room.phase_controller.remaining_seconds, place_remaining),
		"Place timer freezes while paused"
	)
	paused = false
	room.queue_free()
	await process_frame


func _test_results_timeout_advances() -> void:
	var room := MATCH_SCENE.instantiate() as P05MatchRoom
	root.add_child(room)
	await process_frame
	room.join_keyboard("K1")
	room.join_keyboard("K2")
	room.input_router.registry.set_ready(0, true)
	room.input_router.registry.set_ready(1, true)
	_check(room.start_match(), "results-timer fixture starts a two-seat match")
	for seat_index in range(2):
		room.assignments[seat_index] = str(room.egg_pool[seat_index].egg_id)
	room._enter_place()
	room._enter_play()
	room.end_round_diagnostic()
	_check(
		(
			room.phase_controller.phase == MatchPhaseController.Phase.RESULTS
			and is_equal_approx(room.phase_controller.remaining_seconds, 8.0)
		),
		"diagnostic results use the configured eight-second advance"
	)
	var remaining := room.phase_controller.remaining_seconds
	paused = true
	room._process(8.1)
	_check(
		(
			room.phase_controller.phase == MatchPhaseController.Phase.RESULTS
			and is_equal_approx(room.phase_controller.remaining_seconds, remaining)
		),
		"paused results timer does not advance the next round"
	)
	paused = false
	room._process(8.1)
	_check(
		room.phase_controller.phase == MatchPhaseController.Phase.PUGAD,
		"results timer starts the next Pugad after eight seconds"
	)
	room.queue_free()
	await process_frame


func _new_item_context() -> Dictionary:
	var tuning := GameplayTuning.new()
	var definitions := ItemDefinitions.load_all(tuning)
	var arena := ArenaDefinition.new(tuning)
	var tracker := SupportTracker.new()
	tracker.configure(tuning)
	var owner := Node2D.new()
	root.add_child(owner)
	var world := Node2D.new()
	world.name = "P05TestWorld"
	owner.add_child(world)
	var manager := ItemManager.new()
	manager.name = "P05TestItems"
	owner.add_child(manager)
	manager.configure(tuning, arena, tracker, definitions, world)
	return {"root": owner, "world": world, "manager": manager}


func _fake_eggs(count: int) -> Array[Dictionary]:
	var eggs: Array[Dictionary] = []
	for index in range(count):
		eggs.append({"egg_id": "egg_%02d" % index, "variant_key": VARIANT_1X1})
	return eggs


func _seat_ids(count: int) -> Array[int]:
	var seats: Array[int] = []
	for index in range(count):
		seats.append(index)
	return seats


func _edit(seat: int, variant: String, cell: Vector2i, turns: int = 0) -> Dictionary:
	return {
		"seat_index": seat,
		"variant_key": variant,
		"origin_cell": cell,
		"quarter_turns": turns,
		"cleanup_targets": [],
	}


func _check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("P05_TEST PASSED: ", message)
	else:
		failures += 1
		push_error("P05_TEST FAILED: " + message)

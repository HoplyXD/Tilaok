extends SceneTree

## Barya objective policy, 1×1 placement, state transitions and a real Area2D round loop.
## All inputs here are synthetic; physics overlaps are produced by Godot's actual physics server.

const ROOM_SCENE := preload("res://scenes/match/p12_scheduled_match_room.tscn")
const COIN_SCENE := preload("res://scenes/match/barya_coin.tscn")
const KARERA := EventSchedule.Challenge.KARERA
const LAGSANAY := EventSchedule.Challenge.LAGSANAY
const KANGAROO := EventSchedule.Challenge.KANGAROO
const EVIDENCE_DIR := "../docs/evidence/barya/captures"

var checks := 0
var failures := 0
var room: P12ScheduledMatchRoom
var capture_enabled := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	capture_enabled = OS.get_cmdline_user_args().has("--capture-barya")
	_test_offer_policy()
	_test_claims_and_placement_rules()
	_test_objective_transitions_and_terminal_order()
	_test_scoring_matrix()
	await _test_invalid_timeout_discards_objective()
	await _test_real_round_loop()
	print(
		(
			"BARYA_TESTS checks=%d failures=%d input=synthetic physics=Godot Area2D"
			% [checks, failures]
		)
	)
	await process_frame
	quit(1 if failures > 0 else 0)


func _check(condition: bool, label: String) -> void:
	checks += 1
	if condition:
		print("PASS ", label)
	else:
		failures += 1
		push_error("FAIL " + label)


func _test_offer_policy() -> void:
	_check(BaryaOfferPolicy.eligible(true, KARERA, KARERA, false), "Karera Main is eligible")
	_check(
		not BaryaOfferPolicy.eligible(true, LAGSANAY, KARERA, false), "Lagsanay Main is excluded"
	)
	_check(
		not BaryaOfferPolicy.eligible(true, KANGAROO, KARERA, false), "Kangaroo Main is excluded"
	)
	_check(not BaryaOfferPolicy.eligible(true, KARERA, KARERA, true), "sudden death is excluded")
	for player_count in [2, 3, 4]:
		for twist in [LAGSANAY, KANGAROO]:
			var pool: Array[Dictionary] = [
				{"egg_id": "stacked", "variant_key": "build.wood_box.box_2x2"}
			]
			var stack_rng := RandomNumberGenerator.new()
			stack_rng.seed = player_count * 100 + twist
			var slot := BaryaOfferPolicy.roll_offer(
				true, KARERA, KARERA, false, pool, 1.0, stack_rng
			)
			_check(
				(
					slot == 0
					and pool.size() == 1
					and BaryaObjectiveDefinition.is_variant(str(pool[0].variant_key))
				),
				(
					"Karera + %s offers Barya at %d seats"
					% [EventSchedule.main_name(twist), player_count]
				)
			)
	_check(
		not BaryaOfferPolicy.eligible(false, KARERA, KARERA, false), "disabled Barya is excluded"
	)
	var empty: Array[Dictionary] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 321
	var initial_state := rng.state
	_check(
		(
			BaryaOfferPolicy.roll_offer(false, KARERA, KARERA, false, empty, 1.0, rng) == -1
			and rng.state == initial_state
		),
		"disabled offer consumes no Barya randomness"
	)
	_check(
		(
			BaryaOfferPolicy.roll_offer(true, KANGAROO, KARERA, false, empty, 1.0, rng) == -1
			and rng.state == initial_state
		),
		"ineligible offer consumes no Barya randomness"
	)
	var pool: Array[Dictionary] = [
		{"egg_id": "egg_01", "variant_key": "build.hollow_blocks.cell_1x1"},
		{"egg_id": "egg_02", "variant_key": "build.hollow_blocks.stack_2x3"},
		{"egg_id": "egg_03", "variant_key": "build.wood_box.box_2x2"},
	]
	var zero_rng := RandomNumberGenerator.new()
	zero_rng.seed = 77
	var zero_state := zero_rng.state
	var zero_pool := pool.duplicate(true)
	_check(
		(
			BaryaOfferPolicy.replace_random_egg(zero_pool, 0.0, zero_rng) == -1
			and zero_pool == pool
			and zero_rng.state == zero_state
		),
		"zero chance preserves eggs and consumes no Barya randomness"
	)
	var certain_rng := RandomNumberGenerator.new()
	certain_rng.seed = 77
	var certain_pool := pool.duplicate(true)
	var selected := BaryaOfferPolicy.replace_random_egg(certain_pool, 1.0, certain_rng)
	_check(
		(
			selected >= 0
			and certain_pool.size() == pool.size()
			and str(certain_pool[selected].variant_key) == BaryaObjectiveDefinition.VARIANT_ID
		),
		"probability one replaces exactly one egg and preserves the pool count"
	)
	var second_slot := BaryaOfferPolicy.replace_random_egg(certain_pool, 1.0, certain_rng)
	var coin_count := 0
	for egg in certain_pool:
		if BaryaObjectiveDefinition.is_variant(str(egg.variant_key)):
			coin_count += 1
	_check(
		second_slot == selected and coin_count == 1, "repeated offer attempts keep one coin maximum"
	)
	var offered := 0
	var slots := [0, 0, 0]
	for seed_value in range(1, 9001):
		var sample_rng := RandomNumberGenerator.new()
		sample_rng.seed = seed_value
		var sample_pool := pool.duplicate(true)
		var slot := BaryaOfferPolicy.replace_random_egg(sample_pool, 1.0 / 3.0, sample_rng)
		if slot >= 0:
			offered += 1
			slots[slot] += 1
	_check(
		offered >= 2700 and offered <= 3300, "1/3 seeded offer rate is within deterministic bounds"
	)
	_check(
		(
			float(slots[0]) / offered > 0.29
			and float(slots[1]) / offered > 0.29
			and float(slots[2]) / offered > 0.29
		),
		"successful offer replaces a uniformly sampled egg slot"
	)
	var tuning := GameplayTuning.new()
	ItemEnabledProfiles.apply(tuning, "karera_slice")
	var definitions := ItemDefinitions.load_for_profile(tuning, "karera_slice")
	var baseline_streams := SeededDiagnosticStreams.new()
	var disabled_streams := SeededDiagnosticStreams.new()
	baseline_streams.seed_all(991)
	disabled_streams.seed_all(991)
	var baseline := PugadEggPoolGenerator.generate(definitions, tuning, baseline_streams, 6)
	var disabled := PugadEggPoolGenerator.generate(definitions, tuning, disabled_streams, 6)
	BaryaOfferPolicy.roll_offer(
		false, KARERA, KARERA, false, disabled, 1.0 / 3.0, disabled_streams.barya
	)
	_check(
		(
			baseline == disabled
			and baseline_streams.egg.state == disabled_streams.egg.state
			and baseline_streams.barya.state == disabled_streams.barya.state
		),
		"disabled seeded parity preserves baseline eggs and both random streams"
	)


func _test_claims_and_placement_rules() -> void:
	var eggs: Array[Dictionary] = [
		{"egg_id": "coin", "variant_key": BaryaObjectiveDefinition.VARIANT_ID},
		{"egg_id": "normal", "variant_key": "build.hollow_blocks.cell_1x1"},
	]
	var tie_rng := RandomNumberGenerator.new()
	tie_rng.seed = 12
	var claims: Array[Dictionary] = [
		{"seat_index": 0, "egg_id": "coin", "tick": 4},
		{"seat_index": 1, "egg_id": "coin", "tick": 4},
	]
	var claim_result := PugadClaimArbiter.resolve(eggs, claims, [0, 1], tie_rng)
	_check(
		claim_result.assignments.size() == 1 and claim_result.assignments.values().has("coin"),
		"the ordinary Pugad arbiter assigns a contested Barya egg once"
	)
	var tuning := GameplayTuning.new()
	var arena := ArenaDefinition.new(tuning)
	var existing: Array[PlacedItem] = []
	var no_actors: Array[Rect2] = []
	var valid := BaryaPlacementRules.validate_cell(
		arena, tuning, Vector2i(5, 3), existing, no_actors
	)
	_check(bool(valid.allowed), "Barya accepts a legal 1×1 build-region cell")
	_check(
		not (
			BaryaPlacementRules
			. validate_cell(arena, tuning, Vector2i(2, 12), existing, no_actors)
			. allowed
		),
		"Barya rejects the protected spawn zone"
	)
	_check(
		not (
			BaryaPlacementRules
			. validate_cell(arena, tuning, Vector2i(32, 3), existing, no_actors)
			. allowed
		),
		"Barya rejects out-of-bounds cells"
	)
	var blocker := PlacedItem.new()
	blocker.instance_id = "test:blocker"
	blocker.footprint_rect = BaryaPlacementRules.cell_rect(Vector2i(5, 3), tuning)
	existing.append(blocker)
	_check(
		not (
			BaryaPlacementRules
			. validate_cell(arena, tuning, Vector2i(5, 3), existing, no_actors)
			. allowed
		),
		"Barya rejects overlaps with construction pieces"
	)
	existing.clear()
	var actor_rects: Array[Rect2] = [BaryaPlacementRules.cell_rect(Vector2i(5, 3), tuning)]
	_check(
		not (
			BaryaPlacementRules
			. validate_cell(arena, tuning, Vector2i(5, 3), existing, actor_rects)
			. allowed
		),
		"Barya placement respects player clearance"
	)
	var full_stage_actor: Array[Rect2] = [arena.arena_bounds.grow(tuning.grid_cell_wu)]
	_check(
		not bool(
			(
				BaryaPlacementRules
				. nearest_valid_cell(Vector2.ZERO, arena, tuning, existing, full_stage_actor)
				. allowed
			)
		),
		"Barya is discarded when no valid recovery cell exists"
	)
	var placement := MatchPlacementController.new()
	placement.setup(
		{0: BaryaObjectiveDefinition.VARIANT_ID, 1: "build.hollow_blocks.cell_1x1"},
		ItemDefinitions.load_for_profile(tuning, "karera_slice"),
		tuning
	)
	placement.set_confirmed(0, true)
	_check(
		placement.claimed_by(1, "build.hollow_blocks.cell_1x1", placement.cursors[0].cell, 0) == 0,
		"confirmed Barya reserves a 1×1 first-confirm cell"
	)
	var timeout_edits := placement.timeout_edits({0: true, 1: false})
	_check(
		(
			timeout_edits.size() == 1
			and str(timeout_edits[0].variant_key) == BaryaObjectiveDefinition.VARIANT_ID
		),
		"Place timeout keeps a valid confirmed Barya and drops an invalid other edit"
	)


func _test_objective_transitions_and_terminal_order() -> void:
	var objective := BaryaRoundObjective.new()
	_check(
		objective.begin_offer(4, 3, "egg_02"),
		"objective begins in offered state with stable identity"
	)
	_check(objective.assign(1), "Pugad claim advances the objective to assigned")
	_check(objective.place(Vector2i(8, 8)), "valid placement advances the objective to placed")
	var coin := COIN_SCENE.instantiate() as BaryaCoin
	root.add_child(coin)
	await process_frame
	coin.place_at(root, Vector2(544, 544), objective.identity())
	_check(objective.activate(coin), "placed objective creates its one live world coin")
	var contenders: Array[Dictionary] = [
		{"seat_index": 2, "distance_squared": 9.0, "eligible": true},
		{"seat_index": 1, "distance_squared": 4.0, "eligible": true},
		{"seat_index": 0, "distance_squared": 4.0, "eligible": true},
	]
	_check(
		objective.resolve_pickup(contenders, 20) == 0,
		"nearest pickup ties resolve by stable seat index"
	)
	_check(
		objective.resolve_pickup(contenders, 20) == -1, "duplicate pickup in one step is harmless"
	)
	_check(
		objective.commit_terminal(0, "eliminated", 20) == "drop",
		"committed elimination drops the coin"
	)
	objective.finish_drop(Vector2i(9, 8))
	_check(
		(
			objective.resolve_pickup(
				[{"seat_index": 1, "distance_squared": 0.0, "eligible": true}], 20
			)
			== -1
		),
		"a death-step drop cannot be picked up again on that step"
	)
	var prior_identity := objective.identity()
	_check(objective.retry_attempt(), "aborted retry resets temporary ownership without rerolling")
	_check(
		(
			objective.attempt_id == 1
			and objective.identity() != prior_identity
			and objective.placement_cell == Vector2i(8, 8)
			and objective.current_cell == Vector2i(8, 8)
			and objective.state == BaryaRoundObjective.State.PLACED
		),
		"retry keeps the original Place cell and increments attempt identity"
	)
	var retry_coin := COIN_SCENE.instantiate() as BaryaCoin
	root.add_child(retry_coin)
	await process_frame
	var tuning := GameplayTuning.new()
	retry_coin.place_at(
		root,
		BaryaPlacementRules.cell_rect(objective.placement_cell, tuning).get_center(),
		"stale:" + objective.identity()
	)
	_check(
		not objective.activate(retry_coin),
		"a stale attempt identity cannot attach its delayed coin"
	)
	retry_coin.identity = objective.identity()
	_check(objective.activate(retry_coin), "retry respawns the same objective at its Place cell")
	_check(
		(
			objective.resolve_pickup(
				[{"seat_index": 1, "distance_squared": 0.0, "eligible": true}], 22
			)
			== 1
		),
		"a later physics step allows the next pickup"
	)
	_check(
		objective.commit_terminal(1, "finished", 22) == "secured",
		"committed finish secures the receipt"
	)
	_check(objective.scoring_seats() == [1], "only the committed finisher enters Barya scoring")
	objective.cleanup()
	_check(
		objective.state == BaryaRoundObjective.State.REMOVED, "round cleanup removes the objective"
	)
	await process_frame

	var terminal_objective := BaryaRoundObjective.new()
	terminal_objective.begin_offer(4, 4, "egg_01")
	terminal_objective.assign(0)
	terminal_objective.place(Vector2i(8, 8))
	var terminal_coin := COIN_SCENE.instantiate() as BaryaCoin
	root.add_child(terminal_coin)
	await process_frame
	terminal_coin.identity = terminal_objective.identity()
	terminal_objective.activate(terminal_coin)
	terminal_objective.resolve_pickup(
		[{"seat_index": 0, "distance_squared": 0.0, "eligible": true}], 42
	)
	var ledger := RaceOutcomeLedger.new()
	ledger.begin("barya-order", [0, 1], {})
	var terminal_candidates: Array[Dictionary] = [
		{
			"round_id": "barya-order",
			"seat_index": 0,
			"kind": "goal",
			"physics_tick": 42,
			"event_id": "goal",
			"source_item_id": ""
		},
		{
			"round_id": "barya-order",
			"seat_index": 0,
			"kind": "elimination",
			"physics_tick": 42,
			"event_id": "hazard",
			"source_item_id": "trap"
		},
	]
	var committed := ledger.resolve_step(42, terminal_candidates)
	_check(
		(
			committed.size() == 1
			and str(committed[0].outcome) == "eliminated"
			and terminal_objective.commit_terminal(0, str(committed[0].outcome), 42) == "drop"
			and terminal_objective.scoring_seats().is_empty()
		),
		"same-step hazard winner drops the coin and suppresses a losing goal payout"
	)
	terminal_objective.cleanup()
	await process_frame


func _test_scoring_matrix() -> void:
	for player_count in [2, 3, 4]:
		var seats: Array[int] = []
		var outcomes: Array[Dictionary] = []
		var starts := {}
		for seat in player_count:
			seats.append(seat)
			starts[seat] = 0
			outcomes.append({"seat_index": seat, "outcome": "finished", "physics_tick": 30})
		var result := RaceScoreCalculator.calculate(seats, outcomes, starts, [0])
		_check(
			(
				bool(result.valid)
				and int(result.delta_units[0]) == BaryaObjectiveDefinition.SCORE_UNITS
				and result.award_rows.size() == 1
				and str(result.award_rows[0].key) == "barya"
			),
			"all-finish %dp awards only Barya's four eighth-point units" % player_count
		)
	var no_finish := (
		RaceScoreCalculator
		. calculate(
			[0, 1],
			[
				{"seat_index": 0, "outcome": "eliminated", "physics_tick": 20},
				{"seat_index": 1, "outcome": "eliminated", "physics_tick": 20},
			],
			{0: 0, 1: 0},
			[0]
		)
	)
	_check(
		int(no_finish.delta_units[0]) == 0 and no_finish.award_rows.is_empty(),
		"no-finisher round suppresses Barya even when a stale carrier fact is passed"
	)


func _test_invalid_timeout_discards_objective() -> void:
	room = ROOM_SCENE.instantiate() as P12ScheduledMatchRoom
	root.add_child(room)
	await process_frame
	await physics_frame
	var seats: Array[int] = [room.join_keyboard("K1"), room.join_keyboard("K2")]
	for seat in seats:
		room.input_router.registry.set_ready(seat, true)
	room.tuning.barya_enabled = true
	room.tuning.barya_offer_probability = 1.0
	_check(room.start_match(), "invalid-timeout fixture starts a P12 match")
	await process_frame
	var slot := -1
	for index in room.egg_pool.size():
		if BaryaObjectiveDefinition.is_variant(str(room.egg_pool[index].variant_key)):
			slot = index
	_check(slot >= 0, "probability-one Pugad includes Barya for invalid-timeout fixture")
	if slot < 0:
		await _close_room()
		return
	room.selected_egg_by_seat[seats[0]] = slot
	room._queue_claim(seats[0], str(room.egg_pool[slot].egg_id))
	room._flush_claims()
	room._finish_pugad_timeout()
	var cursor: Dictionary = room.placement_controller.cursors[seats[0]]
	cursor.cell = Vector2i(2, 12)
	room.placement_controller.cursors[seats[0]] = cursor
	var other_cursor: Dictionary = room.placement_controller.cursors[seats[1]]
	other_cursor.cell = Vector2i(2, 12)
	room.placement_controller.cursors[seats[1]] = other_cursor
	room._finish_place_timeout()
	_check(
		(
			room.barya_objective.state == BaryaRoundObjective.State.DISCARDED
			and room.barya_objective.coin == null
			and room.items.persistent_count() == 0
		),
		"invalid timeout placement discards Barya without construction or a coin scene"
	)
	await _close_room()


func _test_real_round_loop() -> void:
	room = ROOM_SCENE.instantiate() as P12ScheduledMatchRoom
	root.add_child(room)
	await process_frame
	await physics_frame
	var seats: Array[int] = [room.join_keyboard("K1"), room.join_keyboard("K2")]
	for seat in seats:
		room.input_router.registry.set_ready(seat, true)
	room.tuning.barya_enabled = true
	room.tuning.barya_offer_probability = 1.0
	room.tuning.match_race_hard_cap_seconds = 600.0
	room.tuning.match_race_after_first_finish_seconds = 600.0
	room.tuning.match_target_score_units = 10000
	_check(room.start_match(), "two-seat P12 match starts with Barya enabled")
	await process_frame
	room._notify_presentation(&"eggs")
	await process_frame
	_check(
		room.egg_pool.size() == seats.size() + room.tuning.match_pugad_extra_eggs,
		"Barya replaces an egg without changing Pugad pool size"
	)
	var barya_slot := -1
	var barya_eggs := 0
	for index in room.egg_pool.size():
		if BaryaObjectiveDefinition.is_variant(str(room.egg_pool[index].variant_key)):
			barya_slot = index
			barya_eggs += 1
	_check(barya_eggs == 1, "P12 offer contains at most one Barya egg")
	var preview_found := false
	for slot in room.presenter.pugad_overlay.egg_slots:
		if slot.visible and slot.variant_key == BaryaObjectiveDefinition.VARIANT_ID:
			preview_found = true
	if not preview_found:
		print(
			(
				"BARYA_UI_DIAGNOSTIC slots=%s egg_pool=%s"
				% [room.presenter.pugad_overlay._egg_ids, room.egg_pool]
			)
		)
	_check(preview_found, "the live Pugad shows a coin silhouette for the Barya offer")
	await _capture_barya("01-pugad-offer")
	_check(room.items.persistent_count() == 0, "Pugad offer is not construction")
	if barya_slot < 0:
		await _close_room()
		return
	room.selected_egg_by_seat[seats[0]] = barya_slot
	room._queue_claim(seats[0], str(room.egg_pool[barya_slot].egg_id))
	room._flush_claims()
	_check(
		str(room.assignments.get(seats[0], "")) == str(room.egg_pool[barya_slot].egg_id),
		"a claimed Pugad Barya is assigned through the ordinary claim path"
	)
	room._finish_pugad_timeout()
	_check(
		(
			room.phase_controller.phase == MatchPhaseController.Phase.PLACE
			and room.barya_objective.state == BaryaRoundObjective.State.ASSIGNED
		),
		"Place receives the assigned objective"
	)
	var coin_cursor: Dictionary = room.placement_controller.cursors[seats[0]]
	coin_cursor.cell = Vector2i(5, 3)
	room.placement_controller.cursors[seats[0]] = coin_cursor
	var other_cursor: Dictionary = room.placement_controller.cursors[seats[1]]
	other_cursor.cell = Vector2i(5, 3)
	room.placement_controller.cursors[seats[1]] = other_cursor
	room._confirm_placement(seats[0])
	_check(
		str(room._placement_verdict(seats[1]).get("code", "")) == "claimed",
		"first Barya confirmation reserves its footprint"
	)
	await _capture_barya("02-place-locked")
	room._finish_place_timeout()
	_check(
		(
			room.phase_controller.phase == MatchPhaseController.Phase.PLAY
			and room.barya_objective.state == BaryaRoundObjective.State.AVAILABLE
			and room.items.persistent_count() == 0
		),
		"temporary coin placement enters Play and consumes zero construction capacity"
	)
	await _capture_barya("03-play-coin-available")
	var coin := room.barya_objective.coin
	var carrier := room.actors[seats[0]] as ChickenController
	var bystander := room.actors[seats[1]] as ChickenController
	carrier.set_physics_process(false)
	bystander.set_physics_process(false)
	carrier.global_position = coin.global_position
	bystander.global_position = coin.global_position + Vector2(30.0, 0.0)
	await physics_frame
	await physics_frame
	if room.barya_objective.state == BaryaRoundObjective.State.AVAILABLE:
		room._resolve_round_objective_pickups(Engine.get_physics_frames())
	var overlap_seats: Array[int] = []
	for overlap_body in coin.bodies_in_pickup_snapshot():
		var overlap_actor := overlap_body as ChickenController
		if overlap_actor != null:
			overlap_seats.append(overlap_actor.seat_index)
	print(
		(
			"BARYA_PHYSICS_PICKUP state=%s carrier=%d overlap_seats=%s"
			% [
				BaryaRoundObjective.State.keys()[room.barya_objective.state],
				room.barya_objective.carrier_seat,
				overlap_seats
			]
		)
	)
	_check(
		(
			room.barya_objective.state == BaryaRoundObjective.State.CARRIED
			and room.barya_objective.carrier_seat == seats[0]
			and coin.get_parent() == carrier
		),
		"real contested Area2D pickup uses nearest origin and lower-seat tie-break"
	)
	await _capture_barya("04-carried")
	carrier.global_position += Vector2(64.0, 0.0)
	await physics_frame
	_check(
		(
			coin.get_parent() == carrier
			and (
				coin.global_position.distance_to(carrier.global_position + Vector2(0.0, -82.0))
				< 0.1
			)
		),
		"coin attachment follows controller-root movement"
	)
	carrier.lifecycle.status = PlayerLifecycleState.Status.CAPTURED
	_check(
		(
			room.barya_objective.state == BaryaRoundObjective.State.CARRIED
			and coin.get_parent() == carrier
		),
		"capture preserves carrier ownership and attachment"
	)
	bystander.global_position = room.arena.controller_origin_from_feet(room.arena.spawn_feet)
	carrier.global_position = room.arena.protected_spawn.get_center()
	var death_tick := Engine.get_physics_frames() + 100
	room._on_race_terminal_committed(
		{"seat_index": seats[0], "outcome": "eliminated", "physics_tick": death_tick}, carrier
	)
	_check(
		(
			room.barya_objective.state == BaryaRoundObjective.State.AVAILABLE
			and room.barya_feedback == "BARYA RECOVERED"
			and coin.get_parent() == room.world_layer
		),
		"committed death drops at controller root and recovers from a protected cell"
	)
	await _capture_barya("05-death-drop-recovered")
	var same_tick_candidates: Array[Dictionary] = [
		{"seat_index": seats[1], "distance_squared": 0.0, "eligible": true}
	]
	_check(
		room.barya_objective.resolve_pickup(same_tick_candidates, death_tick) == -1,
		"death-step recovery cannot be picked up until the next physics step"
	)
	carrier.eliminate("test_committed_elimination")
	var drop_position := coin.global_position
	bystander.global_position = drop_position
	await physics_frame
	await physics_frame
	var pickup_tick := Engine.get_physics_frames() + 100
	var real_candidates: Array[Dictionary] = []
	for body in coin.bodies_in_pickup_snapshot():
		var actor := body as ChickenController
		if actor != null and actor.lifecycle.status == PlayerLifecycleState.Status.ACTIVE:
			(
				real_candidates
				. append(
					{
						"seat_index": actor.seat_index,
						"distance_squared":
						coin.global_position.distance_squared_to(actor.global_position),
						"eligible": true,
					}
				)
			)
	var reclaimer := room.barya_objective.resolve_pickup(real_candidates, pickup_tick)
	if reclaimer >= 0:
		coin.attach_to(bystander)
	_check(
		(
			reclaimer == seats[1]
			and room.barya_objective.state == BaryaRoundObjective.State.CARRIED
			and coin.get_parent() == bystander
		),
		"a second eligible player reclaims the death-dropped coin with real physics overlap"
	)
	await _capture_barya("06-reclaimed")
	var final_tick := Engine.get_physics_frames() + 200
	room.race_candidate_queue.queue_elimination(
		seats[0], final_tick, "", -1, "barya-test:seat0-eliminated", "trap"
	)
	room.race_candidate_queue.queue_goal(bystander, final_tick)
	var step := room.race_round_controller.advance_step(
		1.0 / 60.0, final_tick, room.race_candidate_queue.drain()
	)
	room._apply_race_outcomes(step.new_outcomes)
	_check(
		(
			step.ended
			and room.barya_objective.state == BaryaRoundObjective.State.SECURED
			and room.barya_objective.receipt_seat == seats[1]
		),
		"only the reclaimer's committed finish secures the Barya receipt"
	)
	await _capture_barya("07-finish-secured")
	room._finish_race(str(step.end_reason))
	var has_barya_row := false
	var barya_units := 0
	for award in room.last_results_model.award_rows:
		if str(award.get("key", "")) == "barya" and int(award.get("seat_index", -1)) == seats[1]:
			has_barya_row = true
			barya_units = int(award.get("units", 0))
	_check(has_barya_row, "round results and history show the live Barya award row")
	var history_snapshot := room.score_presentation_history.snapshot(room.last_results_model.totals)
	var history_has_barya := false
	for seat_row in history_snapshot.seats:
		for segment in seat_row.segments:
			if str(segment.get("key", "")) == "barya":
				history_has_barya = true
	_check(history_has_barya, "scoreboard history snapshot retains the Barya award segment")
	_check(
		barya_units == BaryaObjectiveDefinition.SCORE_UNITS,
		"committed Barya carrier receives exactly four eighth-point units"
	)
	await _capture_barya("08-results-award")
	_check(
		(
			room.barya_objective.state == BaryaRoundObjective.State.REMOVED
			and room.items.persistent_count() == 0
		),
		"round scoring removes the coin and leaves construction unchanged"
	)
	await _close_room()


func _capture_barya(name: String) -> void:
	if not capture_enabled:
		return
	await process_frame
	var directory := (
		ProjectSettings.globalize_path("res://").path_join(EVIDENCE_DIR).simplify_path()
	)
	DirAccess.make_dir_recursive_absolute(directory)
	var image := root.get_texture().get_image()
	var result := image.save_png(directory.path_join(name + ".png"))
	_check(result == OK, "rendered capture saved: %s" % name)


func _close_room() -> void:
	if room != null and is_instance_valid(room):
		room.queue_free()
	await process_frame
	room = null

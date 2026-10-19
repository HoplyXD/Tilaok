extends SceneTree

## Focused regressions for the opt-in offline live-build route and its host request queue.
## Run: Godot --headless --fixed-fps 60 --path tilaok! --script res://tests/run_nlb_p05_tests.gd

const LIVE_ROOM := preload("res://scenes/match/nlb_p05_live_build_room.tscn")
const PIPELINE_SCRIPT := preload("res://scripts/match/live_placement_pipeline.gd")
const CELL_1X1 := "build.hollow_blocks.cell_1x1"

var checks := 0
var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_route_selection()
	_test_request_ordering_and_deduplication()
	_test_request_limits()
	_test_live_controls_are_isolated()
	await _test_live_assignment_seat_layouts()
	await _test_pugad_timeout_and_impossible_pool()
	await _test_live_go_pause_and_commit()
	await _test_live_barya_placement()
	print("NLB_P05_TESTS checks=%d failures=%d" % [checks, failures])
	await process_frame
	quit(1 if failures > 0 else 0)


func _test_route_selection() -> void:
	_check(
		GameFlow.route_from_args(PackedStringArray()) == "", "empty route keeps scheduled default"
	)
	_check(
		(
			GameFlow.route_from_args(PackedStringArray(["--match-route=first_playable"]))
			== GameFlow.ROUTE_FIRST_PLAYABLE
		),
		"first playable route remains selectable"
	)
	_check(
		(
			GameFlow.route_from_args(PackedStringArray(["--match-route=offline_live_build"]))
			== GameFlow.ROUTE_OFFLINE_LIVE_BUILD
		),
		"offline live-build route is explicit"
	)


func _test_request_ordering_and_deduplication() -> void:
	var pipeline = PIPELINE_SCRIPT.new()
	pipeline.begin_attempt(8, 3, 12)
	var seats: Array[int] = [0, 1, 2, 3]
	var later := _intent("later", Vector2i(8, 6), pipeline)
	var earlier := _intent("earlier", Vector2i(9, 6), pipeline)
	var first := pipeline.submit(later, 0, 900, 5, seats)
	var duplicate := pipeline.submit(later, 0, 901, 5, seats)
	_check(first == duplicate, "identical retry returns the original pending result")
	var altered := later.duplicate(true)
	altered.cell = Vector2i(10, 6)
	_check(
		pipeline.submit(altered, 0, 902, 5, seats).code == "request_id_reused",
		"changed payload under a reused ID is rejected"
	)
	pipeline.submit(earlier, 1, 800, 5, seats)
	var ordered := pipeline.drain_boundary(5, 3)
	_check(
		ordered.size() == 2 and str(ordered[0].request_id) == "earlier",
		"distinct host receipt times preserve receipt ordering"
	)
	var tied_a := _intent("tie_a", Vector2i(11, 6), pipeline)
	var tied_b := _intent("tie_b", Vector2i(12, 6), pipeline)
	pipeline.submit(tied_a, 0, 1000, 6, seats)
	pipeline.submit(tied_b, 1, 1000, 6, seats)
	var tied := pipeline.drain_boundary(6, 1)
	_check(
		str(tied[0].request_id) == "tie_b",
		"only equal receipt times use round-rotated occupied-seat priority"
	)
	pipeline.resolve_result("later", {"status": "accepted", "entity_id": "tile#001"})
	_check(
		pipeline.cached_result("later").entity_id == "tile#001",
		"attempt cache retains the stable resolved result"
	)
	_check(
		pipeline.submit(later, 0, 2000, 7, seats).entity_id == "tile#001",
		"retry after resolution returns the same result"
	)


func _test_request_limits() -> void:
	var pipeline = PIPELINE_SCRIPT.new()
	pipeline.begin_attempt(2, 1, 0)
	var seats: Array[int] = [0, 1, 2, 3]
	for seat_index in seats:
		pipeline.submit(
			_intent("boundary_%d" % seat_index, Vector2i(8 + seat_index, 6), pipeline),
			seat_index,
			seat_index,
			10,
			seats
		)
	_check(pipeline.pending.size() == 4, "one boundary accepts at most four queued requests")
	var overflow := _intent("overflow", Vector2i(8, 7), pipeline)
	_check(
		pipeline.submit(overflow, 0, 99, 10, seats).code == "request_pending",
		"each seat can hold only one pending request"
	)
	var repeated = PIPELINE_SCRIPT.new()
	repeated.begin_attempt(3, 1, 0)
	for request_index in range(8):
		var request := _intent("cap_%d" % request_index, Vector2i(8, 6), repeated)
		repeated.submit(request, 0, request_index, request_index, seats)
		var drained := repeated.drain_boundary(request_index, 1)
		if not drained.is_empty():
			repeated.resolve_result(
				str(drained[0].request_id), {"status": "rejected", "code": "test"}
			)
	var over_cap := _intent("cap_9", Vector2i(9, 6), repeated)
	_check(
		repeated.submit(over_cap, 0, 99, 99, seats).code == "request_limit",
		"a seat is limited to eight unique request IDs per attempt"
	)
	_check(
		(
			pipeline.submit(_intent("wrong_owner", Vector2i(8, 6), pipeline), 4, 10, 11, seats).code
			== "seat_unregistered"
		),
		"authority derives ownership from the registered seat"
	)


func _test_live_controls_are_isolated() -> void:
	var router := LocalInputRouter.new()
	router.set_shared_keyboard_enabled(true)
	router.set_phase(LocalInputRouter.Phase.PLAY)
	_check(router._key_action("K1", KEY_Q) == "build_toggle", "K1 Q toggles live build mode")
	_check(router._key_action("K1", KEY_Z) == "aim_up", "K1 aim is separate from movement")
	_check(
		router._key_action("K1", KEY_T) == "live_rotate", "K1 live rotate is separate from cheer"
	)
	_check(
		router._key_action("K2", KEY_BRACKETLEFT) == "build_toggle",
		"K2 bracket toggles live build mode"
	)
	_check(
		router._key_action("K3", KEY_MINUS) == "build_toggle", "K3 minus toggles live build mode"
	)
	_check(router._key_action("K3", KEY_7) == "aim_up", "K3 number-row aim stays independent")
	_check(
		router._key_action("K4", KEY_KP_ADD) == "build_toggle",
		"K4 numpad plus toggles live build mode"
	)
	_check(
		router._gamepad_phase_action(JOY_BUTTON_RIGHT_SHOULDER) == "live_rotate",
		"gamepad right bumper rotates the live preview"
	)
	_check(
		router._phase_alias(router._gamepad_phase_action(JOY_BUTTON_X)) == "cheer",
		"gamepad cheer remains on X during Play"
	)
	router.free()


func _test_live_assignment_seat_layouts() -> void:
	for seat_count in [2, 3, 4]:
		var room := LIVE_ROOM.instantiate() as NLBP05LiveBuildMatchRoom
		root.add_child(room)
		await process_frame
		for seat_index in range(seat_count):
			room.join_keyboard("K%d" % (seat_index + 1))
			room.input_router.registry.set_ready(seat_index, true)
		room.tuning.match_target_score_units = 100000
		var started := room.start_match()
		var unsupported_variant := ""
		for egg in room.egg_pool:
			var variant_key := str(egg.get("variant_key", ""))
			if (
				not BaryaObjectiveDefinition.is_variant(variant_key)
				and not room.tuning.item_enabled_variants.has(variant_key)
			):
				unsupported_variant = variant_key
		_check(unsupported_variant.is_empty(), "P05 live egg pool excludes unverified variants")
		for seat_index in range(seat_count):
			var egg: Dictionary = room.egg_pool[seat_index]
			egg.variant_key = CELL_1X1
			room.egg_pool[seat_index] = egg
			room._queue_claim(seat_index, str(egg.egg_id))
		room._flush_claims()
		var assigned_ids: Array[String] = []
		for egg_id_variant in room.assignments.values():
			assigned_ids.append(str(egg_id_variant))
		_check(
			(
				started
				and room.phase_controller.phase == MatchPhaseController.Phase.GO
				and room.assignments.size() == seat_count
				and room.placement_controller.cursors.size() == seat_count
				and assigned_ids.size() == seat_count
				and assigned_ids.size() == _unique_count(assigned_ids)
			),
			"%d-seat live layout assigns one distinct item per player and enters GO" % seat_count
		)
		_check(
			(
				is_equal_approx(room.go_countdown_seconds, 3.0)
				and is_equal_approx(room.phase_controller.remaining_seconds, 3.0)
			),
			"%d-seat GO begins at the shared three-second default" % seat_count
		)
		room.queue_free()
		await process_frame


func _test_pugad_timeout_and_impossible_pool() -> void:
	var timeout_room := LIVE_ROOM.instantiate() as NLBP05LiveBuildMatchRoom
	root.add_child(timeout_room)
	await process_frame
	_join_two_ready(timeout_room)
	timeout_room.set_match_seed(73)
	timeout_room.tuning.match_target_score_units = 100000
	timeout_room.start_match()
	timeout_room._finish_pugad_timeout()
	var timeout_ids: Array[String] = []
	for egg_id_variant in timeout_room.assignments.values():
		timeout_ids.append(str(egg_id_variant))
	_check(
		(
			timeout_room.phase_controller.phase == MatchPhaseController.Phase.GO
			and timeout_room.assignments.size() == 2
			and timeout_ids.size() == _unique_count(timeout_ids)
		),
		"Pugad timeout resolves remaining seats to distinct eggs before GO"
	)
	print(
		(
			"NLB_P05_ASSIGNMENT_TIMEOUT seed=%d assignments=%s"
			% [timeout_room.match_seed, JSON.stringify(timeout_room.assignments)]
		)
	)
	timeout_room.queue_free()
	await process_frame

	var failure_room := LIVE_ROOM.instantiate() as NLBP05LiveBuildMatchRoom
	root.add_child(failure_room)
	await process_frame
	_join_two_ready(failure_room)
	failure_room.start_match()
	failure_room.egg_pool.clear()
	failure_room._finish_pugad_timeout()
	_check(
		(
			failure_room.phase_controller.phase == MatchPhaseController.Phase.LOBBY
			and failure_room.last_message.contains("assignment failed")
		),
		"Impossible egg assignment explains failure and returns to Lobby without GO"
	)
	failure_room.queue_free()
	await process_frame


func _join_two_ready(room: NLBP05LiveBuildMatchRoom) -> void:
	room.join_keyboard("K1")
	room.join_keyboard("K2")
	room.input_router.registry.set_ready(0, true)
	room.input_router.registry.set_ready(1, true)


func _unique_count(values: Array[String]) -> int:
	var unique: Dictionary = {}
	for value in values:
		unique[value] = true
	return unique.size()


func _test_live_go_pause_and_commit() -> void:
	var room := LIVE_ROOM.instantiate() as NLBP05LiveBuildMatchRoom
	root.add_child(room)
	await process_frame
	room.join_keyboard("K1")
	room.join_keyboard("K2")
	room.set_match_seed(73)
	room.input_router.registry.set_ready(0, true)
	room.input_router.registry.set_ready(1, true)
	room.tuning.match_target_score_units = 100000
	room.go_countdown_seconds = 0.1
	_check(room.start_match(), "live route starts through the existing two-seat Lobby gate")
	for seat_index in range(2):
		var egg: Dictionary = room.egg_pool[seat_index]
		egg.variant_key = CELL_1X1
		room.egg_pool[seat_index] = egg
		room._queue_claim(seat_index, str(egg.egg_id))
	room._flush_claims()
	_check(
		room.phase_controller.phase == MatchPhaseController.Phase.GO,
		"every seat assignment enters the shared GO countdown without Place"
	)
	var remaining := room.phase_controller.remaining_seconds
	paused = true
	await process_frame
	room._process(0.5)
	_check(
		(
			room.phase_controller.phase == MatchPhaseController.Phase.GO
			and is_equal_approx(room.phase_controller.remaining_seconds, remaining)
		),
		"pause freezes the GO phase and preserves its countdown"
	)
	paused = false
	room._process(0.2)
	_check(
		room.phase_controller.phase == MatchPhaseController.Phase.PLAY and room.items.in_play,
		"GO releases movement and item lifecycle together"
	)
	if room.phase_controller.phase == MatchPhaseController.Phase.PLAY:
		room.inventory_used[0] = false
		room.build_mode[0] = true
		var cursor: Dictionary = room.placement_controller.cursors[0]
		var found_cell := Vector2i(-1, -1)
		for y in range(room.tuning.arena_height_tiles):
			for x in range(room.tuning.arena_width_tiles):
				var actor_rects := room._live_actor_swept_rects()
				var verdict := room.items.validate_placement(
					CELL_1X1, Vector2i(x, y), 0, room.items.owner_seat_clearance(actor_rects)
				)
				if bool(verdict.allowed):
					found_cell = Vector2i(x, y)
					break
			if found_cell.x >= 0:
				break
		cursor.variant_key = CELL_1X1
		cursor.cell = found_cell
		cursor.quarter_turns = 0
		room.placement_controller.cursors[0] = cursor
		if found_cell.x >= 0:
			var bad_intent := _intent("atomic_reject", Vector2i(-1, -1), room.request_pipeline)
			var rejected := room._commit_live_intent(0, bad_intent, Engine.get_physics_frames())
			_check(
				(
					not bool(rejected.allowed)
					and room.items.pieces.is_empty()
					and room.items.stage_version == 0
					and not bool(room.inventory_used.get(0, false))
				),
				"rejected placement leaves inventory, terrain and stage version unchanged"
			)
			room._submit_live_placement(0)
			var ids: Array = room.request_pipeline.request_records.keys()
			var cached := (
				room.request_pipeline.cached_result(str(ids[0])) if not ids.is_empty() else {}
			)
			for _frame in range(4):
				if str(cached.get("status", "")) != "pending":
					break
				await physics_frame
			cached = room.request_pipeline.cached_result(str(ids[0])) if not ids.is_empty() else {}
			_check(
				bool(cached.get("allowed", false)) and room.items.stage_version == 1,
				"safe live placement commits once and advances stage version once"
			)
			_check(
				room.items.live_activation.size() == 1,
				"new item receives an independent activation grace entry"
			)
			var committed_id := str(cached.get("entity_id", ""))
			var committed_piece := room.items.piece_for(committed_id)
			var actor := room.actors[0] as ChickenController
			if committed_piece != null and actor != null:
				actor.global_position = committed_piece.global_position
			room.items._advance_live_activation(0.2)
			var held_state: Dictionary = room.items.live_activation.get(committed_id, {})
			_check(
				(
					bool(held_state.get("held", false))
					and is_equal_approx(
						float(held_state.get("remaining", 0.0)), room.live_item_grace_seconds
					)
				),
				"actor entering the new item's danger area holds its activation grace"
			)
			if actor != null:
				actor.global_position = Vector2(-10000.0, -10000.0)
			room.items._advance_live_activation(0.1)
			var restarted_state: Dictionary = room.items.live_activation.get(committed_id, {})
			_check(
				(
					not bool(restarted_state.get("held", true))
					and is_equal_approx(
						float(restarted_state.get("remaining", 0.0)),
						room.live_item_grace_seconds - 0.1
					)
				),
				"clearing the danger area restarts a full one-second activation grace"
			)
			var live_danger: Rect2 = (
				(room.items.pieces[committed_id] as PlacedItem)
				. footprint_rect
				. grow(room.live_actor_clearance_wu)
			)
			var mover := StageBlock.new()
			var mover_data := BlockData.new()
			mover_data.anchor = BlockData.Anchor.HEAVY
			mover.data = mover_data
			mover.add_child(mover_data)
			var mover_shape := CollisionShape2D.new()
			var mover_box := RectangleShape2D.new()
			mover_box.size = Vector2(12.0, 12.0)
			mover_shape.shape = mover_box
			mover.add_child(mover_shape)
			room.add_child(mover)
			mover.global_position = Vector2(live_danger.end.x + 20.0, live_danger.get_center().y)
			mover.velocity = Vector2(-100.0, 0.0)
			var mover_record := PlacedItem.new()
			mover_record.instance_id = "audit_mover"
			mover_record.node = mover
			mover_record.footprint_rect = Rect2(mover.global_position, Vector2(12.0, 12.0))
			room.items.pieces[mover_record.instance_id] = mover_record
			await process_frame
			room.items._advance_live_activation(0.1)
			var mover_held_state: Dictionary = room.items.live_activation.get(committed_id, {})
			_check(
				bool(mover_held_state.get("held", false)),
				"a live mover sweep holds activation while crossing the danger area"
			)
			mover.velocity = Vector2.ZERO
			mover.global_position = Vector2(-10000.0, -10000.0)
			room.items.pieces.erase(mover_record.instance_id)
			mover.queue_free()
			room.items._advance_live_activation(0.1)
			var mover_cleared_state: Dictionary = room.items.live_activation.get(committed_id, {})
			_check(
				(
					not bool(mover_cleared_state.get("held", true))
					and is_equal_approx(
						float(mover_cleared_state.get("remaining", 0.0)),
						room.live_item_grace_seconds - 0.1
					)
				),
				"clearing the mover path restarts its full activation grace"
			)
			var remaining_grace := float(room.items.live_activation.values()[0].remaining)
			paused = true
			await physics_frame
			_check(
				is_equal_approx(
					float(room.items.live_activation.values()[0].remaining), remaining_grace
				),
				"pause freezes the live item grace clock"
			)
			paused = false
			for _frame in range(70):
				await physics_frame
			_check(
				room.items.live_activation.is_empty(),
				"live item activates after a clear one-second grace"
			)
			room.request_pipeline.close_attempt()
			_check(
				(
					room.request_pipeline.pending.is_empty()
					and room.request_pipeline.request_records.is_empty()
				),
				"closing the attempt clears pending requests and dedupe results"
			)
		else:
			_check(false, "live room has a safe open cell for the 1x1 construction")
	else:
		_check(false, "live route transitions from GO to active Play")
	room.queue_free()
	await process_frame


func _test_live_barya_placement() -> void:
	var room := LIVE_ROOM.instantiate() as NLBP05LiveBuildMatchRoom
	root.add_child(room)
	await process_frame
	_join_two_ready(room)
	room.set_match_seed(73)
	room.tuning.match_target_score_units = 100000
	room.tuning.barya_offer_probability = 1.0
	_check(room.start_match(), "live route starts the P12 Barya fixture")
	var barya_egg_id := ""
	var ordinary_egg_id := ""
	for egg in room.egg_pool:
		if BaryaObjectiveDefinition.is_variant(str(egg.get("variant_key", ""))):
			barya_egg_id = str(egg.get("egg_id", ""))
		elif ordinary_egg_id.is_empty():
			ordinary_egg_id = str(egg.get("egg_id", ""))
	if not barya_egg_id.is_empty() and not ordinary_egg_id.is_empty():
		room._queue_claim(0, barya_egg_id)
		room._queue_claim(1, ordinary_egg_id)
		room._flush_claims()
		room.go_countdown_seconds = 0.1
		room._go_remaining = 0.1
		room.phase_controller.remaining_seconds = 0.1
		room._process(0.2)
		var cursor: Dictionary = room.placement_controller.cursors.get(0, {})
		var persistent_before := room.items.persistent_count()
		var safe_cell := Vector2i(-1, -1)
		for y in range(room.tuning.arena_height_tiles):
			for x in range(room.tuning.arena_width_tiles):
				var cell := Vector2i(x, y)
				var verdict := BaryaPlacementRules.validate_cell(
					room.arena,
					room.tuning,
					cell,
					room.items.pieces.values(),
					room.items.owner_seat_clearance(room._live_actor_swept_rects())
				)
				if bool(verdict.get("allowed", false)):
					safe_cell = cell
					break
			if safe_cell.x >= 0:
				break
		if not cursor.is_empty() and safe_cell.x >= 0:
			cursor.cell = safe_cell
			room.placement_controller.cursors[0] = cursor
			room.build_mode[0] = true
			room._submit_live_placement(0)
			var request_ids: Array = room.request_pipeline.request_records.keys()
			for _frame in range(4):
				if request_ids.is_empty():
					break
				if (
					room.request_pipeline.cached_result(str(request_ids[0])).get("status")
					!= "pending"
				):
					break
				await physics_frame
				room._resolve_live_placement_boundary()
			var result := (
				room.request_pipeline.cached_result(str(request_ids[0]))
				if not request_ids.is_empty()
				else {}
			)
			_check(
				(
					bool(result.get("allowed", false))
					and bool(result.get("objective", false))
					and room.items.persistent_count() == persistent_before
					and bool(room.inventory_used.get(0, false))
					and room.barya_objective.state == BaryaRoundObjective.State.AVAILABLE
				),
				"Barya uses live active-round placement without entering construction counts"
			)
		else:
			_check(false, "Barya cursor has a valid objective cell")
	else:
		_check(false, "P12 Barya offer is assigned with one ordinary construction egg")
	room.queue_free()
	await process_frame


func _intent(request_id: String, cell: Vector2i, pipeline) -> Dictionary:
	return {
		"request_id": request_id,
		"match_id": pipeline.match_id,
		"round_id": pipeline.round_id,
		"attempt_id": pipeline.attempt_id,
		"observed_stage_version": pipeline.stage_version,
		"variant_key": CELL_1X1,
		"objective": "",
		"cell": cell,
		"quarter_turns": 0,
	}


func _check(condition: bool, label: String) -> void:
	checks += 1
	if condition:
		print("PASS ", label)
	else:
		failures += 1
		push_error("FAIL " + label)

# gdlint: disable=max-file-lines
extends SceneTree

## Focused regressions for the normal offline live-build route and its construction jobs.
## Run with Godot --headless --fixed-fps 60 --path tilaok! and this script path:
## res://tests/run_offline_live_build_tests.gd

const LIVE_ROOM := preload("res://scenes/match/offline_live_build_room.tscn")
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
	await _test_live_safety_manifest()
	await _test_live_hazard_occupant_moves_not_cancels()
	await _test_live_assignment_seat_layouts()
	await _test_pugad_timeout_and_impossible_pool()
	await _test_live_go_pause_and_commit()
	await _test_live_barya_placement()
	print("OFFLINE_LIVE_BUILD_TESTS checks=%d failures=%d" % [checks, failures])
	await process_frame
	quit(1 if failures > 0 else 0)


func _test_route_selection() -> void:
	var default_flow := GameFlow.new()
	_check(
		default_flow.match_scene == LIVE_ROOM,
		"normal Play selects offline live-build without a route override"
	)
	default_flow.free()
	_check(
		GameFlow.route_from_args(PackedStringArray()) == "",
		"no developer route override is supplied by default"
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
		"offline live-build developer override remains parseable"
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
		router._key_action("K1", KEY_SPACE) == "jump",
		"K1 Space remains jump while the chicken is running"
	)
	router.set_live_build_mode(0, true)
	router.live_build_confirm_enabled = true
	_check(
		(
			router._key_action("K1", KEY_A, 0) == "aim_left"
			and router._key_action("K1", KEY_W, 0) == "aim_up"
		),
		"K1 movement keys steer the preview while build mode owns the controls"
	)
	_check(
		router._key_action("K1", KEY_E, 0) == "confirm",
		"build mode preserves the live placement confirm action"
	)
	_check(
		router._key_action("K1", KEY_SPACE, 0) == "confirm",
		"K1 Space confirms placement while build mode pauses the chicken"
	)
	_check(
		router._build_aim_action_for_joy_button(JOY_BUTTON_DPAD_RIGHT, "right") == "aim_right",
		"gamepad D-pad steers the preview while build mode is active"
	)
	_check(
		router._gamepad_build_action_for_joy_button(JOY_BUTTON_A, "jump") == "confirm",
		"gamepad South/A confirms a live placement while build mode is active"
	)
	router.set_live_build_mode(0, false)
	_check(
		router._key_action("K1", KEY_A, 0) == "left",
		"K1 movement controls resume after build mode closes"
	)
	_check(
		router._key_action("K1", KEY_SPACE, 0) == "jump",
		"K1 Space returns to jump when build mode closes"
	)
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


func _test_live_safety_manifest() -> void:
	var room := LIVE_ROOM.instantiate() as OfflineLiveBuildMatchRoom
	root.add_child(room)
	await process_frame
	var missing_definitions: Array[String] = []
	for variant_key in room.tuning.item_enabled_variants:
		var found := room.definitions.find_variant(str(variant_key))
		var family := found.get("family") as ItemFamilyDefinition
		if family == null:
			missing_definitions.append(str(variant_key))
	var restored_variants := PackedStringArray(
		[
			"block.cannon.main",
			"hazard.parol_pulse.span_3x1",
			"hazard.parol_pulse.span_4x1",
			"hazard.parol_pulse.span_5x1",
			"hazard.parol_pulse.span_6x1",
			"hazard.slipper_launcher.lane_4x1",
			"hazard.slipper_launcher.lane_6x1",
			"move.tire_spring.tire_2x2",
		]
	)
	var not_enabled: Array[String] = []
	for variant_key in restored_variants:
		if not room.tuning.item_enabled_variants.has(variant_key):
			not_enabled.append(variant_key)
	_check(
		(
			missing_definitions.is_empty()
			and room.pugad_excluded_variant_keys().is_empty()
			and not_enabled.is_empty()
		),
		"all enabled variants, including the eight restored items, are eligible for live-build offers"
	)
	_check(
		BaryaObjectiveDefinition.is_variant(BaryaObjectiveDefinition.VARIANT_ID),
		"Barya remains a separately audited Karera objective construction path"
	)
	room.queue_free()
	await process_frame


func _test_live_assignment_seat_layouts() -> void:
	for seat_count in [2, 3, 4]:
		var room := LIVE_ROOM.instantiate() as OfflineLiveBuildMatchRoom
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
			var family := (
				room.definitions.find_variant(variant_key).get("family") as ItemFamilyDefinition
			)
			if (
				not BaryaObjectiveDefinition.is_variant(variant_key)
				and (
					not room.tuning.item_enabled_variants.has(variant_key)
					or family == null
					or not PugadEggPoolGenerator.allows_modes(family, room.pugad_mode_ids())
				)
			):
				unsupported_variant = (
					"%s (%s)" % [variant_key, family.family_id if family != null else "missing"]
				)
		_check(
			unsupported_variant.is_empty(),
			"normal live egg pool contains only enabled mode-filtered variants"
		)
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
	var timeout_room := LIVE_ROOM.instantiate() as OfflineLiveBuildMatchRoom
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
			"OFFLINE_LIVE_ASSIGNMENT_TIMEOUT seed=%d assignments=%s"
			% [timeout_room.match_seed, JSON.stringify(timeout_room.assignments)]
		)
	)
	timeout_room.queue_free()
	await process_frame

	var failure_room := LIVE_ROOM.instantiate() as OfflineLiveBuildMatchRoom
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


func _join_two_ready(room: OfflineLiveBuildMatchRoom) -> void:
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
	var room := LIVE_ROOM.instantiate() as OfflineLiveBuildMatchRoom
	root.add_child(room)
	await process_frame
	_join_two_ready(room)
	room.set_match_seed(73)
	room.input_router.registry.set_ready(0, true)
	room.input_router.registry.set_ready(1, true)
	room.tuning.match_target_score_units = 100000
	room.go_countdown_seconds = 0.1
	_check(room.start_match(), "normal live-build route starts through the two-seat Lobby gate")
	for seat_index in range(2):
		var egg: Dictionary = room.egg_pool[seat_index]
		egg.variant_key = CELL_1X1
		room.egg_pool[seat_index] = egg
		room._queue_claim(seat_index, str(egg.egg_id))
	room._flush_claims()
	_check(
		room.phase_controller.phase == MatchPhaseController.Phase.GO,
		"every seat assignment enters shared GO without a Place phase"
	)
	_check(
		(
			(
				room
				. presenter
				. _control_hint_lines(
					room.input_router.registry.joined_seats(), MatchPhaseController.Phase.GO
				)
				. size()
			)
			== 2
		),
		"per-seat controls are visible during the shared GO countdown"
	)
	_check(
		(
			room.placement_controller.build_region_tiles == room._build_region_tiles()
			and room.placement_controller.start_anchor_tile == room._build_start_anchor_tile()
		),
		"offline live-build cursors initialize from the active map build area and spawn"
	)
	var remaining := room.phase_controller.remaining_seconds
	paused = true
	room._process(0.5)
	_check(
		(
			room.phase_controller.phase == MatchPhaseController.Phase.GO
			and is_equal_approx(room.phase_controller.remaining_seconds, remaining)
		),
		"pause freezes the shared GO countdown"
	)
	paused = false
	room._process(0.2)
	_check(
		room.phase_controller.phase == MatchPhaseController.Phase.PLAY and room.items.in_play,
		"GO releases movement and item lifecycle together"
	)
	if room.phase_controller.phase == MatchPhaseController.Phase.PLAY:
		room.inventory_used[0] = false
		room._set_build_mode(0, true)
		var joined_seats := room.input_router.registry.joined_seats()
		room.presenter._apply_hud(joined_seats, MatchPhaseController.Phase.PLAY)
		var p1_hint := str(room.presenter.play_hud._control_hint_labels[0].text)
		var p2_hint := str(room.presenter.play_hud._control_hint_labels[1].text)
		_check(
			(
				p1_hint.contains("AIM")
				and p1_hint.contains("P1 · K1 KEYBOARD")
				and p1_hint.contains("PLACE E, F or Space")
				and p2_hint.contains("P2 · K2 KEYBOARD")
				and p2_hint.contains("RUN: Left/Right")
				and p2_hint.contains("JUMP: Right Ctrl")
			),
			"HUD shows each seat's keyboard controls and only switches the builder to build hints"
		)
		room._set_build_mode(0, false)
		room._set_build_mode(1, true)
		room.presenter._apply_hud(joined_seats, MatchPhaseController.Phase.PLAY)
		p1_hint = str(room.presenter.play_hud._control_hint_labels[0].text)
		p2_hint = str(room.presenter.play_hud._control_hint_labels[1].text)
		_check(
			p1_hint.contains("RUN") and p2_hint.contains("AIM"),
			"HUD control hints follow the player who enters build mode"
		)
		var pad_seat := {"seat": 2, "identity": 3, "joined": true, "device_kind": "gamepad"}
		var pad_hint := str(
			room.presenter._control_hint_lines([pad_seat], MatchPhaseController.Phase.PLAY)[0]
		)
		_check(
			(
				pad_hint.contains("P3 · GAMEPAD")
				and pad_hint.contains("MOVE: D-pad or Left stick")
				and pad_hint.contains("JUMP: South (bottom) button")
				and pad_hint.contains("BUILD: North (top) button")
			),
			"HUD shows the connected gamepad's own running controls"
		)
		room.build_mode[2] = true
		pad_hint = str(
			room.presenter._control_hint_lines([pad_seat], MatchPhaseController.Phase.PLAY)[0]
		)
		_check(
			(
				pad_hint.contains("AIM D-pad / Left or Right stick")
				and pad_hint.contains("PLACE Bottom button (A / Cross) or Right trigger")
				and pad_hint.contains("ROTATE Right bumper")
				and pad_hint.contains("CANCEL Left bumper")
			),
			"HUD switches a gamepad seat to its live-build controls"
		)
		room.build_mode.erase(2)
		var four_player_hints := room.presenter._control_hint_lines(
			UiContext.sample_seats(4), MatchPhaseController.Phase.PLAY
		)
		room.presenter.play_hud._bind_control_hints(four_player_hints)
		_check(
			(
				four_player_hints.size() == 4
				and room.presenter.play_hud._control_hint_labels[0].visible
				and room.presenter.play_hud._control_hint_labels[1].visible
				and room.presenter.play_hud._control_hint_labels[2].visible
				and room.presenter.play_hud._control_hint_labels[3].visible
				and four_player_hints[2].contains("P3 · GAMEPAD")
				and four_player_hints[3].contains("P4 · GAMEPAD")
			),
			"the HUD gives all four players visible, device-specific control cards"
		)
		room._set_build_mode(0, true)
		room._set_build_mode(1, false)
		var actor := room.actors[0] as ChickenController
		if actor != null:
			actor.locomotion_velocity.x = 240.0
			actor._physics_process(1.0 / 60.0)
		_check(
			(
				actor != null
				and actor.build_input_locked
				and is_zero_approx(actor.locomotion_velocity.x)
			),
			"build mode stops direct chicken movement while leaving the match in Play"
		)
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
				"rejected preview leaves terrain, inventory and stage version unchanged"
			)
			cursor.cell = Vector2i(-1, -1)
			room.placement_controller.cursors[0] = cursor
			room._submit_live_placement(0)
			var rejected_ids: Array = room.request_pipeline.request_records.keys()
			for _frame in range(4):
				await physics_frame
			var rejected_result := (
				room.request_pipeline.cached_result(str(rejected_ids.back()))
				if not rejected_ids.is_empty()
				else {}
			)
			_check(
				(
					not bool(rejected_result.get("allowed", false))
					and bool(room.build_mode.get(0, false))
					and not bool(room.inventory_used.get(0, false))
					and actor != null
					and actor.build_input_locked
				),
				"rejected live placement keeps build mode active so the player can correct the preview"
			)
			cursor.cell = found_cell
			room.placement_controller.cursors[0] = cursor
			var occupied_preview_verdict := room.items.validate_placement(
				CELL_1X1, found_cell, 0, []
			)
			var occupied_preview_rect: Rect2 = occupied_preview_verdict.get("footprint", Rect2())
			var occupied_blocker := room.actors[1] as ChickenController
			if occupied_blocker != null:
				occupied_blocker.global_position = occupied_preview_rect.get_center()
			var occupied_preview := _intent("occupied_preview", found_cell, room.request_pipeline)
			_check(
				bool(
					(
						room
						. _commit_live_intent(
							0, occupied_preview, Engine.get_physics_frames(), false
						)
						. get("allowed", false)
					)
				),
				"a solid placement preview is accepted while a chicken occupies its footprint"
			)
			room._submit_live_placement(0)
			var ids: Array = room.request_pipeline.request_records.keys()
			for _frame in range(4):
				if not room.construction_jobs.is_empty():
					break
				await physics_frame
			var job_id := str(ids.back()) if not ids.is_empty() else ""
			_check(
				(
					room.construction_jobs.size() == 1
					and room.items.pieces.is_empty()
					and room.items.stage_version == 0
				),
				"accepted confirm starts one visible job without creating gameplay terrain"
			)
			var preview := (
				room.construction_jobs.get(job_id, {}).get("preview") as ConstructionJobPreview
			)
			_check(
				preview != null and room._reserved_footprints.has(job_id),
				"job has preview and footprint reservation"
			)
			var overlap_intent := _intent("reserved_overlap", found_cell, room.request_pipeline)
			var overlap := room._start_construction_job(
				1, overlap_intent, Engine.get_physics_frames()
			)
			_check(
				(
					not bool(overlap.get("allowed", false))
					and str(overlap.get("code", "")) == "reserved_overlap"
					and room.construction_jobs.size() == 1
					and not bool(room.inventory_used.get(1, false))
				),
				"later conflicting footprint is rejected visibly and keeps the item"
			)
			room._cancel_construction_job(job_id, true)
			_check(
				(
					room.construction_jobs.is_empty()
					and room._reserved_footprints.is_empty()
					and not bool(room.inventory_used.get(0, false))
				),
				"explicit cancel releases reservation once and restores an eligible builder's item"
			)
			room.build_mode[0] = true
			room._submit_live_placement(0)
			ids = room.request_pipeline.request_records.keys()
			for _frame in range(4):
				if not room.construction_jobs.is_empty():
					break
				await physics_frame
			job_id = str(ids[ids.size() - 1]) if not ids.is_empty() else ""
			_check(
				room.construction_jobs.size() == 1 and room._reserved_footprints.has(job_id),
				"a cancelled job can restart with a new stable job ID"
			)
			var job: Dictionary = room.construction_jobs.get(job_id, {})
			room._construction_clock = float(job.get("started_at", room._construction_clock))
			var pending_count := room.request_pipeline.request_records.size()
			room._submit_live_placement(0)
			_check(
				(
					room.request_pipeline.request_records.size() == pending_count
					and room.construction_jobs.size() == 1
				),
				"duplicate confirm cannot restart or duplicate the active job"
			)
			var clock_before_pause := room._construction_clock
			paused = true
			room._physics_process(0.5)
			_check(
				is_equal_approx(room._construction_clock, clock_before_pause),
				"pause freezes the construction simulation clock"
			)
			paused = false
			room._advance_construction_jobs(1.0)
			_check(
				room.items.pieces.is_empty(), "one second of construction has no gameplay effect"
			)
			room._advance_construction_jobs(0.99)
			_check(
				room.items.pieces.is_empty(),
				"just-under-two-second construction has no gameplay effect"
			)
			room._advance_construction_jobs(0.02)
			var completed := room.request_pipeline.cached_result(job_id)
			_check(
				(
					room.construction_jobs.is_empty()
					and room._reserved_footprints.is_empty()
					and bool(completed.get("allowed", false))
					and room.items.pieces.size() == 1
					and room.items.stage_version == 1
					and bool(room.inventory_used.get(0, false))
				),
				"job commits once at the first fixed-step boundary after two seconds and releases reservation"
			)
			_check(
				room.items.live_activation.is_empty(),
				"ordinary solid has no extra generic activation delay"
			)
			_check(
				actor != null and not actor.build_input_locked,
				"successful confirmation releases the chicken while construction runs"
			)
			var repeat_attempt := room._commit_live_intent(
				0,
				_intent("repeat_after_complete", Vector2i(20, 6), room.request_pipeline),
				Engine.get_physics_frames(),
				false
			)
			_check(
				(
					not bool(repeat_attempt.get("allowed", false))
					and str(repeat_attempt.get("code", "")) == "inventory_used"
					and room.items.pieces.size() == 1
					and bool(room.inventory_used.get(0, false))
				),
				"a player can place their assigned item only once per round"
			)
			var third_cell := Vector2i(-1, -1)
			for y in range(room.tuning.arena_height_tiles):
				for x in range(room.tuning.arena_width_tiles):
					var intent := _intent(
						"actor_probe_%d_%d" % [x, y], Vector2i(x, y), room.request_pipeline
					)
					var verdict := room._commit_live_intent(
						1, intent, Engine.get_physics_frames(), false
					)
					if bool(verdict.allowed):
						third_cell = Vector2i(x, y)
						break
				if third_cell.x >= 0:
					break
			if third_cell.x < 0:
				_check(false, "a second safe cell exists for occupied-footprint completion")
			else:
				var second_cursor: Dictionary = room.placement_controller.cursors[1]
				second_cursor.variant_key = CELL_1X1
				second_cursor.cell = third_cell
				room.placement_controller.cursors[1] = second_cursor
				room._set_build_mode(1, true)
				room._submit_live_placement(1)
				var second_ids: Array = room.request_pipeline.request_records.keys()
				for _frame in range(4):
					if room.construction_jobs.has(str(second_ids.back())):
						break
					await physics_frame
				var second_job_id := str(second_ids.back())
				var second_job: Dictionary = room.construction_jobs.get(second_job_id, {})
				var blocker := room.actors[1] as ChickenController
				var reserved: Rect2 = second_job.get("footprint", Rect2())
				if blocker != null and not second_job.is_empty():
					blocker.global_position = Vector2(
						reserved.get_center().x,
						reserved.position.y - room.tuning.body_height_wu * 0.5 + 20.0
					)
				room._advance_construction_jobs(room.construction_seconds)
				var second_result := room.request_pipeline.cached_result(second_job_id)
				_check(
					(
						room.items.pieces.size() == 2
						and room.construction_jobs.is_empty()
						and room._reserved_footprints.is_empty()
						and bool(second_result.get("allowed", false))
						and bool(room.inventory_used.get(1, false))
						and blocker != null
						and is_equal_approx(
							blocker.global_position.y,
							reserved.position.y - room.tuning.body_height_wu * 0.5
						)
					),
					"an occupied build completes and moves the chicken onto the new top surface"
				)
		else:
			_check(false, "live room finds a safe open construction cell")
	else:
		_check(false, "live route transitions from GO to active Play")
	room.queue_free()
	await process_frame


func _test_live_hazard_occupant_moves_not_cancels() -> void:
	var room := LIVE_ROOM.instantiate() as OfflineLiveBuildMatchRoom
	root.add_child(room)
	await process_frame
	_join_two_ready(room)
	room.set_match_seed(173)
	room.tuning.match_target_score_units = 100000
	room.go_countdown_seconds = 0.1
	var hazard_key := ""
	for family in room.definitions.families:
		if str(family.behavior_kind) not in ["hitbox", "trumpo", "bubble"]:
			continue
		for variant in family.variants:
			var candidate_key := family.variant_key(variant)
			if room.tuning.item_enabled_variants.has(candidate_key):
				hazard_key = candidate_key
				break
		if not hazard_key.is_empty():
			break
	if not hazard_key.is_empty() and room.start_match():
		for seat_index in range(2):
			var egg: Dictionary = room.egg_pool[seat_index]
			egg.variant_key = CELL_1X1
			room.egg_pool[seat_index] = egg
			room._queue_claim(seat_index, str(egg.egg_id))
		room._flush_claims()
		room._process(0.2)
		var cursor: Dictionary = room.placement_controller.cursors.get(0, {})
		var safe_cell := Vector2i(-1, -1)
		if not cursor.is_empty():
			cursor.variant_key = hazard_key
			room.placement_controller.cursors[0] = cursor
			for y in range(room.tuning.arena_height_tiles):
				for x in range(room.tuning.arena_width_tiles):
					var cell := Vector2i(x, y)
					var intent := _intent(
						"hazard_probe_%d_%d" % [x, y], cell, room.request_pipeline
					)
					intent.variant_key = hazard_key
					var probe := room._commit_live_intent(
						0, intent, Engine.get_physics_frames(), false
					)
					if bool(probe.get("allowed", false)):
						safe_cell = cell
						break
				if safe_cell.x >= 0:
					break
		if safe_cell.x >= 0:
			cursor.cell = safe_cell
			room.placement_controller.cursors[0] = cursor
			var hazard_preview_intent := _intent(
				"hazard_occupied_preview", safe_cell, room.request_pipeline
			)
			hazard_preview_intent.variant_key = hazard_key
			var hazard_verdict := room._commit_live_intent(
				0, hazard_preview_intent, Engine.get_physics_frames(), false
			)
			var blocker := room.actors[1] as ChickenController
			var hazard_footprint: Rect2 = hazard_verdict.get("footprint", Rect2())
			if blocker != null:
				blocker.global_position = hazard_footprint.get_center()
			var occupied_hazard_preview := _intent(
				"hazard_occupied_confirm", safe_cell, room.request_pipeline
			)
			occupied_hazard_preview.variant_key = hazard_key
			_check(
				(
					bool(hazard_verdict.get("allowed", false))
					and bool(
						(
							room
							. _commit_live_intent(
								0, occupied_hazard_preview, Engine.get_physics_frames(), false
							)
							. get("allowed", false)
						)
					)
				),
				"a lethal hazard preview is accepted while a chicken occupies its footprint"
			)
			room._set_build_mode(0, true)
			room._submit_live_placement(0)
			var ids: Array = room.request_pipeline.request_records.keys()
			for _frame in range(4):
				if not ids.is_empty() and room.construction_jobs.has(str(ids.back())):
					break
				await physics_frame
			var job_id := str(ids.back()) if not ids.is_empty() else ""
			var job: Dictionary = room.construction_jobs.get(job_id, {})
			var footprint: Rect2 = job.get("footprint", Rect2())
			var untouched := room.actors[0] as ChickenController
			if blocker != null and not job.is_empty():
				blocker.global_position = footprint.get_center()
			var before := blocker.global_position if blocker != null else Vector2.ZERO
			var untouched_before := untouched.global_position if untouched != null else Vector2.ZERO
			room._advance_construction_jobs(room.construction_seconds)
			var result := room.request_pipeline.cached_result(job_id)
			_check(
				(
					bool(result.get("allowed", false))
					and room.items.pieces.size() == 1
					and room.construction_jobs.is_empty()
					and blocker != null
					and is_equal_approx(blocker.global_position.x, before.x)
					and is_equal_approx(
						blocker.global_position.y,
						footprint.position.y - room.tuning.body_height_wu * 0.5
					)
					and untouched != null
					and untouched.global_position == untouched_before
				),
				"a touching chicken gets a small top nudge, while a non-touching chicken stays put"
			)
		else:
			_check(false, "enabled, live-safe hazard has a constructible placement cell")
	else:
		_check(
			false, "an enabled hitbox, trumpo or bubble variant is available for relocation test"
		)
	room.queue_free()
	await process_frame


func _test_live_barya_placement() -> void:
	var room := LIVE_ROOM.instantiate() as OfflineLiveBuildMatchRoom
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
			var job_id := str(request_ids[0]) if not request_ids.is_empty() else ""
			_check(
				(
					room.construction_jobs.size() == 1
					and room.items.persistent_count() == persistent_before
					and room.barya_objective.state == BaryaRoundObjective.State.ASSIGNED
				),
				"Barya is a visible non-gameplay construction job before completion"
			)
			room._advance_construction_jobs(room.construction_seconds)
			var result := room.request_pipeline.cached_result(job_id)
			_check(
				(
					bool(result.get("allowed", false))
					and bool(result.get("objective", false))
					and room.items.persistent_count() == persistent_before
					and bool(room.inventory_used.get(0, false))
					and room.barya_objective.state == BaryaRoundObjective.State.AVAILABLE
				),
				"Barya completion starts its existing objective lifecycle without terrain mutation"
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

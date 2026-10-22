extends SceneTree

const ROOM_SCENE := preload("res://scenes/fixtures/p03_stage_room.tscn")

var failures := 0
var checks := 0
var room: P03StageRoom


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	room = ROOM_SCENE.instantiate() as P03StageRoom
	root.add_child(room)
	for _frame in range(3):
		await physics_frame
	_test_arena_and_guards()
	_test_support_metadata_contract()
	await _test_camera_framing()
	_test_camera_hud_easing()
	var seat := room.join_keyboard("K1")
	room.start_play()
	var actor := room.actors[seat] as ChickenController
	await _test_maximum_launch_camera(actor)
	for _frame in range(3):
		await physics_frame
	await _test_playable_route(actor)
	await _test_support_contacts(actor)
	_test_badge_camera_stability()
	await _test_lifecycle_and_cleanup(actor)
	room.queue_free()
	await process_frame
	print("P03_TESTS checks=%d failures=%d" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _check(condition: bool, label: String) -> void:
	checks += 1
	if condition:
		print("PASS ", label)
	else:
		failures += 1
		push_error("FAIL " + label)


func _test_arena_and_guards() -> void:
	var definition := ArenaDefinition.new(GameplayTuning.new())
	_check(
		definition.arena_bounds.size == Vector2(2048.0, 1024.0), "arena is 2048 by 1024 world units"
	)
	_check(
		definition.spawn_feet == Vector2(192.0, 960.0),
		"shared spawn uses documented feet coordinate"
	)
	var origin := definition.controller_origin_from_feet(definition.spawn_feet)
	_check(
		is_equal_approx(origin.y + definition.tuning.body_height_wu * 0.5, 960.0),
		"center-origin controller feet align with floor top"
	)
	_check(definition.surface_specs[0].rect.position.y == 960.0, "floor top is y=960")
	var signature := definition.arena_geometry_signature()
	var valid := definition.validate_region(
		Rect2(Vector2(400.0, 384.0), Vector2(64.0, 64.0)), ArenaDefinition.REGION_FOOTPRINT
	)
	_check(bool(valid.allowed), "valid footprint inside the build region is accepted")
	var spawn := definition.validate_region(
		Rect2(Vector2(48.0, 752.0), Vector2(64.0, 64.0)), ArenaDefinition.REGION_FOOTPRINT
	)
	_check(
		not bool(spawn.allowed) and spawn.reason == "protected spawn zone",
		"spawn footprint is rejected"
	)
	var goal_sweep := definition.validate_region(
		Rect2(Vector2(1840.0, 640.0), Vector2(64.0, 64.0)), ArenaDefinition.REGION_SWEEP
	)
	_check(
		not bool(goal_sweep.allowed) and goal_sweep.reason == "protected goal zone",
		"goal sweep remains protected"
	)
	var hidden_goal_effect := definition.validate_region(
		Rect2(Vector2(1856.0, 608.0), Vector2(48.0, 48.0)), ArenaDefinition.REGION_EFFECT
	)
	_check(
		not bool(hidden_goal_effect.allowed),
		"goal effect region is protected regardless of flag visibility"
	)
	var base_overlap := definition.validate_region(
		Rect2(Vector2(420.0, 860.0), Vector2(48.0, 48.0)), ArenaDefinition.REGION_FOOTPRINT
	)
	_check(
		not bool(base_overlap.allowed) and str(base_overlap.reason).begins_with("immutable base"),
		"base geometry overlap is rejected"
	)
	var outside := definition.validate_region(
		Rect2(Vector2(300.0, 400.0), Vector2(48.0, 48.0)), ArenaDefinition.REGION_FOOTPRINT
	)
	_check(
		not bool(outside.allowed) and outside.reason == "outside build region",
		"out-of-build-region edit is rejected"
	)
	var actor_rects: Array[Rect2] = [Rect2(Vector2(800.0, 384.0), Vector2(56.0, 120.0))]
	var clearance := definition.validate_region(
		Rect2(Vector2(856.0, 400.0), Vector2(32.0, 32.0)),
		ArenaDefinition.REGION_FOOTPRINT,
		actor_rects
	)
	_check(
		not bool(clearance.allowed) and clearance.reason == "player clearance",
		"player clearance expands the collider by four units"
	)
	var floor_remove := definition.can_remove_surface("arena.floor")
	_check(not bool(floor_remove.allowed), "floor removal is rejected")
	_check(
		definition.register_player_construction("fixture.kaing"),
		"known player construction can be registered"
	)
	_check(
		bool(definition.can_remove_surface("fixture.kaing").allowed),
		"registered construction removal guard permits mutable geometry"
	)
	_check(
		not bool(definition.can_remove_surface("unknown.id").allowed),
		"unknown surface removal is rejected"
	)
	_check(
		signature == definition.arena_geometry_signature(),
		"rejected edits leave immutable geometry unchanged"
	)


func _test_support_metadata_contract() -> void:
	var missing := SupportSurfaceMetadata.new()
	missing.surface_id = "fixture.missing"
	_check(not missing.validate().is_empty(), "missing eligibility metadata is rejected")
	var base := SupportSurfaceMetadata.new()
	base.surface_id = "fixture.base"
	base.wave_support_eligibility = SupportSurfaceMetadata.Eligibility.INELIGIBLE
	_check(base.validate().is_empty(), "explicitly ineligible surface metadata is valid")
	var built := _eligible_metadata("fixture.built", "construction.shared")
	_check(built.validate().is_empty(), "eligible player-built surface metadata validates")
	var child := SupportSurfaceMetadata.new()
	child.surface_id = "fixture.child"
	child.wave_support_eligibility = SupportSurfaceMetadata.Eligibility.ELIGIBLE
	child.inherits_provenance_from = built.surface_id
	var registry := {built.surface_id: built}
	_check(
		child.validate(registry).is_empty(),
		"authored child accepts explicit provenance inheritance"
	)
	_check(
		child.resolved_provenance(registry).construction_id == built.construction_id,
		"child resolves to its construction identity"
	)
	var unlinked := SupportSurfaceMetadata.new()
	unlinked.surface_id = "fixture.unlinked"
	unlinked.wave_support_eligibility = SupportSurfaceMetadata.Eligibility.ELIGIBLE
	unlinked.inherits_provenance_from = "missing.parent"
	_check(not unlinked.validate(registry).is_empty(), "missing provenance parent is rejected")
	var tracker := SupportTracker.new()
	_check(not tracker.register_surface(missing), "tracker rejects missing eligibility metadata")
	_check(tracker.register_surface(base), "tracker accepts explicit ineligible metadata")
	var missing_node := StaticBody2D.new()
	missing_node.name = "MissingMetadataFixture"
	missing_node.add_to_group("support_surfaces")
	var scene_errors := tracker.validate_scene(missing_node)
	_check(
		not scene_errors.is_empty(), "scene validation rejects a support collider without metadata"
	)
	missing_node.free()


func _test_camera_framing() -> void:
	_check(
		ProjectSettings.get_setting("display/window/stretch/aspect") == "keep",
		"project preserves the 16:9 virtual aspect"
	)
	var scenarios := [
		[
			Rect2(Vector2(48.0, 816.0), Vector2(56.0, 120.0)),
			Rect2(Vector2(1952.0, 816.0), Vector2(56.0, 120.0))
		],
		[
			Rect2(Vector2(48.0, 816.0), Vector2(56.0, 120.0)),
			Rect2(Vector2(1000.0, 192.0), Vector2(256.0, 64.0)),
			Rect2(Vector2(1952.0, 816.0), Vector2(56.0, 120.0))
		],
		[
			Rect2(Vector2(48.0, 816.0), Vector2(56.0, 120.0)),
			Rect2(Vector2(720.0, 192.0), Vector2(192.0, 64.0)),
			Rect2(Vector2(1280.0, 576.0), Vector2(384.0, 128.0)),
			Rect2(Vector2(1952.0, 816.0), Vector2(56.0, 120.0))
		],
	]
	for scenario_index in range(scenarios.size()):
		var rects: Array[Rect2] = []
		for rect_variant in scenarios[scenario_index]:
			rects.append(rect_variant as Rect2)
		room.set_camera_fixture_targets(rects, BoundedStageCamera.Context.PLAY)
		await process_frame
		await process_frame
		var all_visible := true
		for rect in rects:
			all_visible = all_visible and room.camera_rig.screen_bounds_visible(rect)
		_check(all_visible, "%d-actor framing contains full target extents" % (scenario_index + 2))
		if scenario_index == 0:
			_check(
				room.camera_rig.screen_bounds_visible(
					Rect2(Vector2(1000.0, 192.0), Vector2(256.0, 64.0))
				),
				"highest legal construction preview at build-region y=192 remains visible"
			)
	var launch_and_preview: Array[Rect2] = [
		Rect2(Vector2(0.0, 0.0), Vector2(56.0, 120.0)),
		Rect2(Vector2(1992.0, 904.0), Vector2(56.0, 120.0)),
		Rect2(Vector2(1640.0, 192.0), Vector2(320.0, 128.0)),
		Rect2(Vector2(960.0, 256.0), Vector2(56.0, 120.0)),
	]
	room.set_camera_fixture_targets(launch_and_preview, BoundedStageCamera.Context.PLACE)
	await process_frame
	await process_frame
	var all_visible := true
	for rect in launch_and_preview:
		all_visible = all_visible and room.camera_rig.screen_bounds_visible(rect)
	_check(all_visible, "launch and rotated-preview extents remain inside the usable viewport")
	_check(
		(
			room.camera_rig.zoom.x >= room.tuning.camera_zoom_min
			and room.camera_rig.zoom.x <= room.tuning.camera_zoom_max
		),
		"camera honors its bounded zoom range"
	)
	var last_position := room.camera_rig.position
	room.set_camera_fixture_targets([], BoundedStageCamera.Context.PLAY)
	await process_frame
	_check(
		room.camera_rig.position.is_equal_approx(last_position),
		"empty target set holds the last safe framing"
	)
	room.clear_camera_fixture_targets()
	var previous_bounds := room.tuning.camera_view_bounds
	room.tuning.camera_view_bounds = Rect2(Vector2.ZERO, Vector2(100.0, 100.0))
	room.camera_rig.tuning.camera_view_bounds = room.tuning.camera_view_bounds
	room.set_camera_fixture_targets(
		[Rect2(Vector2(32.0, 32.0), Vector2(16.0, 16.0))], BoundedStageCamera.Context.PLAY
	)
	await process_frame
	await process_frame
	var locked_position := room.camera_rig.position
	await process_frame
	_check(
		locked_position.is_equal_approx(room.camera_rig.position),
		"viewport larger than bounds locks without inverted clamps or jitter"
	)
	room.tuning.camera_view_bounds = previous_bounds
	room.clear_camera_fixture_targets()
	var before_pause := room.camera_rig.position
	room._toggle_pause()
	room.set_camera_fixture_targets(
		[Rect2(Vector2(800.0, 200.0), Vector2(48.0, 48.0))], BoundedStageCamera.Context.PLAY
	)
	await process_frame
	await process_frame
	_check(
		room.camera_rig.position.is_equal_approx(before_pause),
		"pause holds the camera at its safe framing"
	)
	room._toggle_pause()
	room.clear_camera_fixture_targets()


func _test_camera_hud_easing() -> void:
	var camera := room.camera_rig
	var fixture := Rect2(Vector2(976.0, 552.0), Vector2(96.0, 96.0))
	var camera_was_processing := camera.is_processing()
	var previous_position := camera.position
	var previous_zoom := camera.zoom
	var previous_initialized := camera._initialized
	camera.set_process(false)
	camera.position = Vector2(1024.0, 512.0)
	camera.zoom = Vector2.ONE * room.tuning.camera_zoom_min
	camera._initialized = false
	room.set_camera_fixture_targets([fixture], BoundedStageCamera.Context.PLAY)
	for _step in range(20):
		camera._process(0.2)
	var expected_y := (
		fixture.get_center().y - room.tuning.camera_hud_reservation_px * 0.5 / camera.zoom.x
	)
	_check(
		absf(camera.position.y - expected_y) <= 1.0,
		"camera easing applies the reserved-HUD offset once without vertical drift"
	)
	_check(
		camera.screen_bounds_visible(fixture),
		"camera easing keeps the stationary target inside the usable viewport"
	)
	print(
		(
			"P03_CAMERA_EASE target_y=%.2f camera_y=%.2f expected_y=%.2f zoom=%.3f visible=%s"
			% [
				fixture.get_center().y,
				camera.position.y,
				expected_y,
				camera.zoom.x,
				camera.screen_bounds_visible(fixture)
			]
		)
	)
	room.clear_camera_fixture_targets()
	camera.position = previous_position
	camera.zoom = previous_zoom
	camera._initialized = previous_initialized
	camera.set_process(camera_was_processing)


func _test_maximum_launch_camera(actor: ChickenController) -> void:
	actor.global_position = Vector2(1472.0, 900.0)
	actor.velocity = Vector2.ZERO
	actor.locomotion_velocity = Vector2.ZERO
	actor.external_velocity = Vector2.ZERO
	actor.launch(Vector2(0.0, -1800.0))
	var all_visible := true
	var highest_target_y := INF
	for _frame in range(36):
		await physics_frame
		await process_frame
		if room.camera_rig.targets.is_empty():
			all_visible = false
			continue
		var target := room.camera_rig.targets[0]
		all_visible = all_visible and room.camera_rig.screen_bounds_visible(target.world_rect)
		highest_target_y = minf(highest_target_y, target.world_rect.position.y)
	_check(
		highest_target_y < 600.0, "maximum configured 1800 wu/s launch reaches its measured apex"
	)
	_check(all_visible, "camera contains live identity and body extents through maximum launch")
	print(
		(
			"P03_CAMERA_LAUNCH speed=1800 target_top_y=%.2f frames=36 visible=%s"
			% [highest_target_y, all_visible]
		)
	)
	actor.external_velocity = Vector2.ZERO
	actor.velocity = Vector2.ZERO
	actor.locomotion_velocity = Vector2.ZERO
	actor.global_position = room.arena.controller_origin_from_feet(room.arena.spawn_feet)
	await physics_frame
	await process_frame


func _test_playable_route(actor: ChickenController) -> void:
	var router := room.input_router
	_press(router, KEY_D, true)
	await _physics_frames(10)
	var floor_takeoff_y := actor.global_position.y
	_press(router, KEY_SPACE, true)
	var floor_head_clear := await _physics_frames_track_ceiling(actor, 24)
	_press(router, KEY_SPACE, false)
	_check(
		actor.global_position.y < floor_takeoff_y and not floor_head_clear,
		"floor takeoff rises through the clear head and body corridor"
	)
	var landed_a := await _wait_for_surface(actor, "arena.base_a", 18)
	_check(landed_a, "real controller lands on Base A from the floor")
	if not landed_a:
		print(
			(
				"P03_ROUTE floor_to_a x=%.2f y=%.2f"
				% [actor.global_position.x, actor.global_position.y]
			)
		)
		return
	_press(router, KEY_SPACE, true)
	var a_head_clear := await _physics_frames_track_ceiling(actor, 24)
	_press(router, KEY_SPACE, false)
	var landed_b := await _wait_for_surface(actor, "arena.base_b", 20)
	_check(landed_b, "real controller clears the 64-unit rise and gap to Base B")
	_check(not a_head_clear, "Base A takeoff clears the underside of Base B")
	if not landed_b:
		print("P03_ROUTE a_to_b x=%.2f y=%.2f" % [actor.global_position.x, actor.global_position.y])
		return
	_press(router, KEY_SPACE, true)
	var b_head_clear := await _physics_frames_track_ceiling(actor, 24)
	_press(router, KEY_SPACE, false)
	var landed_c := await _wait_for_surface(actor, "arena.base_c", 44)
	_check(landed_c, "real controller lands on Base C across the descending gap")
	_check(not b_head_clear, "descending gap has clear headroom through its jump arc")
	if not landed_c:
		print("P03_ROUTE b_to_c x=%.2f y=%.2f" % [actor.global_position.x, actor.global_position.y])
		return
	await _physics_frames(8)
	_press(router, KEY_SPACE, true)
	var c_head_clear := await _physics_frames_track_ceiling(actor, 24)
	_press(router, KEY_SPACE, false)
	var landed_d := await _wait_for_surface(actor, "arena.base_d", 20)
	_check(landed_d, "real controller clears the 64-unit rise and gap to Base D")
	_check(not c_head_clear, "Base C takeoff clears the underside of Base D")
	if not landed_d:
		print("P03_ROUTE c_to_d x=%.2f y=%.2f" % [actor.global_position.x, actor.global_position.y])
		return
	var speed_before_brake := absf(actor.locomotion_velocity.x)
	_press(router, KEY_D, false)
	await _physics_frames(6)
	_check(
		(
			absf(actor.locomotion_velocity.x) < speed_before_brake
			and actor.bounds.has_point(actor.global_position)
		),
		"ground braking reduces horizontal speed while the actor stays contained"
	)
	_press(router, KEY_D, true)
	# Containment was removed, so nothing parks the actor against a right wall any more. Check that
	# it genuinely stands on the goal platform inside the stage, instead of relying on a wall to
	# settle its feet on exactly y=768.
	var reached_goal := false
	for _frame in range(60):
		await physics_frame
		var feet := actor.global_position.y + room.tuning.body_height_wu * 0.5
		if (
			actor.global_position.x >= 1800.0
			and actor.global_position.x <= 2048.0
			and absf(feet - 768.0) <= 1.0
			and actor.is_on_floor()
		):
			reached_goal = true
			break
	_check(reached_goal, "real controller reaches the goal platform without teleporting")
	_press(router, KEY_D, false)
	_check(actor.bounds.has_point(actor.global_position), "route remains within arena containment")
	print(
		(
			"P03_ROUTE goal=%s x=%.2f y=%.2f"
			% [reached_goal, actor.global_position.x, actor.global_position.y]
		)
	)


func _test_support_contacts(actor: ChickenController) -> void:
	var built := _make_surface(
		"fixture.kaing",
		Rect2(Vector2(300.0, 240.0), Vector2(160.0, 8.0)),
		SupportSurfaceMetadata.Eligibility.ELIGIBLE,
		true
	)
	await _place_actor_on(actor, Vector2(350.0, 216.0))
	var built_result := room.current_support_result(actor.support_actor_id, 240.0)
	_check(
		bool(built_result.qualifies), "Kaing-like built solid qualifies with actual upward support"
	)
	var built_contact := built_result.contact as SupportContact
	_check(
		built_contact != null and built_contact.normal.dot(Vector2.UP) >= 0.707,
		"support captures the real upward normal and contact"
	)
	if built_contact != null:
		var above_line := room.current_support_result(
			actor.support_actor_id, built_contact.feet_y - 0.9
		)
		var on_line := room.current_support_result(
			actor.support_actor_id, built_contact.feet_y - 1.0
		)
		var below_line := room.current_support_result(
			actor.support_actor_id, built_contact.feet_y - 1.1
		)
		_check(bool(above_line.qualifies), "feet just above the wave boundary qualify")
		_check(
			bool(on_line.qualifies), "one-unit inclusive wave tolerance qualifies at its boundary"
		)
		_check(
			not bool(below_line.qualifies) and below_line.reason == "feet below line",
			"feet below the wave boundary fail without grace"
		)
	var launch_origin := actor.global_position
	actor.launch(Vector2(0.0, -600.0))
	_check(
		room.current_support_result(actor.support_actor_id, 240.0).reason == "no support",
		"launch immediately invalidates prior support"
	)
	_check(
		actor.global_position == launch_origin, "support invalidation does not teleport the actor"
	)
	room.remove_support_surface("fixture.kaing", built)
	await physics_frame
	await _test_fixture_support_lines(actor)

	var other_player_platform := _make_surface(
		"fixture.other_player_construction",
		Rect2(Vector2(520.0, 240.0), Vector2(160.0, 8.0)),
		SupportSurfaceMetadata.Eligibility.ELIGIBLE,
		true
	)
	await _place_actor_on(actor, Vector2(600.0, 216.0))
	_check(
		bool(room.current_support_result(actor.support_actor_id, 240.0).qualifies),
		"another player's eligible construction supports this actor"
	)
	room.remove_support_surface("fixture.other_player_construction", other_player_platform)
	await physics_frame

	var one_way := _make_surface(
		"fixture.one_way",
		Rect2(Vector2(600.0, 560.0), Vector2(320.0, 8.0)),
		SupportSurfaceMetadata.Eligibility.ELIGIBLE,
		true,
		true
	)
	room.input_router.set_phase(LocalInputRouter.Phase.LOBBY)
	actor.global_position = Vector2(700.0, 626.0)
	actor.velocity = Vector2.ZERO
	actor.locomotion_velocity = Vector2.ZERO
	actor.external_velocity = Vector2.ZERO
	actor.coyote_remaining = 0.0
	actor.launch(Vector2(0.0, -1200.0))
	room.input_router.set_phase(LocalInputRouter.Phase.PLAY)
	await _physics_frames(12)
	_check(
		room.current_support_result(actor.support_actor_id, 600.0).reason == "no support",
		"one-way bridge does not support a player rising through it"
	)
	var one_way_landed := await _wait_for_surface(actor, "fixture.one_way", 65)
	_check(one_way_landed, "one-way bridge qualifies after a real landing")
	room.remove_support_surface("fixture.one_way", one_way)
	await physics_frame

	var spring_face := _make_surface(
		"fixture.spring_support_face",
		Rect2(Vector2(300.0, 240.0), Vector2(160.0, 8.0)),
		SupportSurfaceMetadata.Eligibility.ELIGIBLE,
		true
	)
	await _place_actor_on(actor, Vector2(350.0, 216.0))
	_check(
		bool(room.current_support_result(actor.support_actor_id, 240.0).qualifies),
		"separate spring face qualifies only during actual upward support"
	)
	actor.launch(Vector2(0.0, -600.0))
	_check(
		room.current_support_result(actor.support_actor_id, 240.0).reason == "no support",
		"spring launching loses support immediately after contact"
	)
	room.remove_support_surface("fixture.spring_support_face", spring_face)
	await physics_frame

	var safe_face := _make_surface(
		"fixture.safe_hazard_face",
		Rect2(Vector2(300.0, 240.0), Vector2(160.0, 8.0)),
		SupportSurfaceMetadata.Eligibility.ELIGIBLE,
		true
	)
	await _place_actor_on(actor, Vector2(350.0, 216.0))
	_check(
		bool(room.current_support_result(actor.support_actor_id, 240.0).qualifies),
		"explicit safe hazard face qualifies only while actually supporting"
	)
	room.remove_support_surface("fixture.safe_hazard_face", safe_face)
	await physics_frame

	var child_parent := _eligible_metadata("fixture.construction_parent", "construction.temporary")
	_check(
		room.support_tracker.register_surface(child_parent),
		"temporary platform construction provenance parent registers"
	)
	var child := SupportSurfaceMetadata.new()
	child.surface_id = "fixture.temporary_child"
	child.wave_support_eligibility = SupportSurfaceMetadata.Eligibility.ELIGIBLE
	child.inherits_provenance_from = child_parent.surface_id
	var child_body := _make_surface_with_metadata(
		child, Rect2(Vector2(300.0, 240.0), Vector2(160.0, 8.0))
	)
	await _place_actor_on(actor, Vector2(350.0, 216.0))
	var child_result := room.current_support_result(actor.support_actor_id, 240.0)
	_check(
		bool(child_result.qualifies),
		"temporary authored child qualifies through explicit inherited provenance"
	)
	_check(
		child_result.contact.construction_id == child_parent.construction_id,
		"temporary child reports the parent construction identity"
	)
	room.remove_support_surface(child.surface_id, child_body)
	room.support_tracker.invalidate_surface(child_parent.surface_id)
	await physics_frame

	var crumble := _make_surface(
		"fixture.crumble",
		Rect2(Vector2(300.0, 240.0), Vector2(160.0, 8.0)),
		SupportSurfaceMetadata.Eligibility.ELIGIBLE,
		true
	)
	await _place_actor_on(actor, Vector2(350.0, 216.0))
	_check(
		bool(room.current_support_result(actor.support_actor_id, 240.0).qualifies),
		"crumbling platform qualifies before collapse"
	)
	room.remove_support_surface("fixture.crumble", crumble)
	_check(
		room.current_support_result(actor.support_actor_id, 240.0).reason == "no support",
		"same-step crumble invalidation removes support before evaluation"
	)
	await physics_frame

	await _test_base_and_ineligible_surfaces(actor)
	await _test_side_and_airborne_states(actor)
	await _test_moving_surface(actor)


func _test_fixture_support_lines(actor: ChickenController) -> void:
	# Sample-only contract lines; P03 does not select or schedule Kangaroo wave heights.
	var fixture_lines := [384.0, 320.0, 256.0]
	for line_index in range(fixture_lines.size()):
		var line_y: float = fixture_lines[line_index]
		for offset in [-0.1, 0.0, 1.1]:
			var surface_id := "fixture.band_%d_%d" % [line_index, roundi(offset * 10.0)]
			var feet_y: float = line_y + float(offset)
			var surface := _make_surface(
				surface_id,
				Rect2(Vector2(520.0, feet_y), Vector2(160.0, 8.0)),
				SupportSurfaceMetadata.Eligibility.ELIGIBLE,
				true
			)
			await _place_actor_on(actor, Vector2(600.0, feet_y - 24.0))
			var result := room.current_support_result(actor.support_actor_id, line_y)
			var expected := float(offset) <= room.tuning.support_height_epsilon_wu
			_check(
				bool(result.qualifies) == expected,
				(
					"fixture support line %.0f feet offset %.1f evaluates %s"
					% [line_y, float(offset), "eligible" if expected else "below line"]
				)
			)
			room.remove_support_surface(surface_id, surface)
			await physics_frame


func _test_base_and_ineligible_surfaces(actor: ChickenController) -> void:
	await _place_actor_on(actor, Vector2(880.0, 704.0 - room.tuning.body_height_wu * 0.5))
	var base_result := room.current_support_result(actor.support_actor_id, 800.0)
	_check(
		not bool(base_result.qualifies) and base_result.reason == "base surface",
		"elevated base platform never qualifies regardless of height"
	)
	var ineligible := _make_surface(
		"fixture.ineligible",
		Rect2(Vector2(300.0, 240.0), Vector2(160.0, 8.0)),
		SupportSurfaceMetadata.Eligibility.INELIGIBLE,
		true
	)
	await _place_actor_on(actor, Vector2(350.0, 216.0))
	var ineligible_result := room.current_support_result(actor.support_actor_id, 240.0)
	_check(
		not bool(ineligible_result.qualifies) and ineligible_result.reason == "ineligible surface",
		"explicitly ineligible built surface does not qualify"
	)
	room.remove_support_surface("fixture.ineligible", ineligible)
	await physics_frame

	var second_seat := room.join_keyboard("K2")
	var other := room.actors[second_seat] as ChickenController
	actor.global_position = Vector2(420.0, 216.0)
	other.global_position = actor.global_position
	for _frame in range(4):
		await physics_frame
	_check(
		actor.global_position.distance_to(other.global_position) < 1.0,
		"overlapping chickens do not push each other"
	)
	room._update_identity_badges()
	var actor_badge := actor.get_meta("identity_badge") as Label
	var other_badge := other.get_meta("identity_badge") as Label
	var actor_badge_rect := Rect2(actor_badge.global_position, actor_badge.size)
	var other_badge_rect := Rect2(other_badge.global_position, other_badge.size)
	_check(
		not actor_badge_rect.intersects(other_badge_rect, false),
		"overlapping chickens keep separate readable identity badges"
	)
	_check(
		room.current_support_result(actor.support_actor_id, 240.0).reason == "no support",
		"another chicken is never treated as a supporting surface"
	)
	other.set_captured(true, "fixture.bubble")
	_check(
		room.current_support_result("seat_%d" % second_seat, 240.0).reason == "no support",
		"bubble capture has no supporting contact"
	)
	other.set_captured(false)
	other.lifecycle.status = PlayerLifecycleState.Status.ACTIVE


func _test_side_and_airborne_states(actor: ChickenController) -> void:
	var wall := _make_surface(
		"fixture.side_wall",
		Rect2(Vector2(420.0, 120.0), Vector2(8.0, 100.0)),
		SupportSurfaceMetadata.Eligibility.ELIGIBLE,
		true
	)
	actor.global_position = Vector2(390.0, 180.0)
	actor.velocity = Vector2.ZERO
	actor.locomotion_velocity = Vector2.ZERO
	actor.external_velocity = Vector2.ZERO
	actor.launch(Vector2(480.0, 0.0))
	await _physics_frames(8)
	_check(
		room.current_support_result(actor.support_actor_id, 250.0).reason == "no support",
		"side-wall contact is not upward support"
	)
	room.remove_support_surface("fixture.side_wall", wall)
	await physics_frame
	actor.global_position = Vector2(500.0, 180.0)
	actor.velocity = Vector2.ZERO
	actor.external_velocity = Vector2.ZERO
	actor.coyote_remaining = tuning_coyote(room)
	room.support_tracker.invalidate_actor(actor.support_actor_id)
	await physics_frame
	_check(
		room.current_support_result(actor.support_actor_id, 250.0).reason == "no support",
		"coyote permission without contact is not support"
	)
	actor.coyote_remaining = 0.0
	_check(
		room.current_support_result(actor.support_actor_id, 250.0).reason == "no support",
		"airborne crossing above a line is not support"
	)
	room.input_router.clear_input_state()
	actor.set_opening_freeze(true)
	actor.global_position = Vector2(500.0, 180.0)
	actor.velocity = Vector2.ZERO
	actor.locomotion_velocity = Vector2.ZERO
	actor.external_velocity = Vector2.ZERO
	var projectile := StaticBody2D.new()
	projectile.name = "ProjectileWithoutSupportMetadata"
	projectile.add_to_group("projectiles")
	projectile.position = actor.global_position + Vector2(32.0, 0.0)
	projectile.collision_layer = 1
	projectile.collision_mask = 2
	room.world_layer.add_child(projectile)
	var projectile_shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 12.0
	projectile_shape.shape = circle
	projectile.add_child(projectile_shape)
	await physics_frame
	await process_frame
	var projectile_sweep := KinematicCollision2D.new()
	var would_hit_projectile := actor.test_move(
		actor.global_transform, Vector2(40.0, 0.0), projectile_sweep
	)
	_check(
		would_hit_projectile and projectile_sweep.get_collider() == projectile,
		"real controller shape sweep intersects the projectile fixture"
	)
	actor.set_opening_freeze(false)
	actor.launch(Vector2(480.0, 0.0))
	await _physics_frames(4)
	_check(
		room.current_support_result(actor.support_actor_id, 250.0).reason == "no support",
		"projectile collision never qualifies without explicit support metadata"
	)
	projectile.queue_free()
	await physics_frame


func _test_moving_surface(actor: ChickenController) -> void:
	var metadata := _eligible_metadata("fixture.moving", "construction.moving")
	_check(room.support_tracker.register_surface(metadata), "moving platform metadata registers")
	var moving := AnimatableBody2D.new()
	moving.name = "MovingEligiblePlatform"
	moving.sync_to_physics = true
	moving.process_physics_priority = -10
	moving.position = Vector2(380.0, 240.0)
	moving.collision_layer = 1
	moving.collision_mask = 1
	moving.add_to_group("support_surfaces")
	moving.set_meta(SupportSurfaceMetadata.META_KEY, metadata)
	room.world_layer.add_child(moving)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(160.0, 8.0)
	collision.shape = shape
	moving.add_child(collision)
	await _place_actor_on(actor, Vector2(350.0, 216.0))
	var before := room.current_support_result(actor.support_actor_id, 240.0)
	_check(bool(before.qualifies), "moving platform supports only while carrying actual contact")
	var before_boundary := room.current_support_result(actor.support_actor_id, 231.0)
	_check(
		not bool(before_boundary.qualifies),
		"moving surface starts below the measured wave support boundary"
	)
	moving.position.y -= 4.0
	await physics_frame
	await process_frame
	var after := room.current_support_result(actor.support_actor_id, 240.0)
	var after_boundary := room.current_support_result(actor.support_actor_id, 231.0)
	_check(
		(
			bool(after.qualifies)
			and not bool(before_boundary.qualifies)
			and bool(after_boundary.qualifies)
		),
		"moving platform carries actual contact and uses its current height on the evaluation step"
	)
	room.remove_support_surface(metadata.surface_id, moving)
	await physics_frame


func _test_lifecycle_and_cleanup(actor: ChickenController) -> void:
	room.enter_place_fixture()
	_check(room.camera_rig.targets.size() == 2, "Place camera includes unconfirmed pointers")
	_check(room.confirm_next_pointer(), "one diagnostic pointer can be confirmed")
	_check(room.camera_rig.targets.size() == 1, "confirmed pointer is excluded individually")
	room.rotate_next_pointer()
	_check(
		room.camera_rig.targets.size() == 1,
		"rotated preview remains included by its current extents"
	)
	room.start_play()
	var second_seat := room.input_router.registry.seat_for_keyboard("K2")
	var second := room.actors[second_seat] as ChickenController
	_check(room.camera_rig.targets.size() == 2, "Play camera includes both unfinished chickens")
	second.secure("fixture.finish")
	room._update_camera_targets()
	_check(room.camera_rig.targets.size() == 1, "secured chicken leaves the Play target set")
	second.lifecycle.status = PlayerLifecycleState.Status.ACTIVE
	second.eliminate("fixture.eliminate")
	room._update_camera_targets()
	_check(room.camera_rig.targets.size() == 1, "eliminated chicken leaves the Play target set")
	room.reset_room()
	_check(
		room.actors.size() == 2 and room.support_tracker.contacts_by_actor.is_empty(),
		"reset clears support and restores actors"
	)
	room.request_return()
	_check(
		room.support_tracker.surfaces.is_empty(), "return clears support registry for scene cleanup"
	)
	_check(is_instance_valid(actor), "cleanup keeps room-owned actors valid until scene release")


func _test_badge_camera_stability() -> void:
	var first_seat := room.input_router.registry.seat_for_keyboard("K1")
	var second_seat := room.input_router.registry.seat_for_keyboard("K2")
	var first := room.actors[first_seat] as ChickenController
	var second := room.actors[second_seat] as ChickenController
	var first_position := first.global_position
	var second_position := second.global_position
	first.global_position = Vector2(400.0, 300.0)
	second.global_position = Vector2(478.0, 300.0)
	room._update_identity_badges()
	room._update_camera_targets()
	var close_bounds := room.camera_rig._combined_bounds()
	second.global_position.x = 482.0
	room._update_identity_badges()
	room._update_camera_targets()
	var apart_bounds := room.camera_rig._combined_bounds()
	_check(
		is_equal_approx(close_bounds.get_center().y, apart_bounds.get_center().y),
		"camera vertical framing stays stable across the former 80-unit badge-spacing threshold"
	)
	first.global_position = first_position
	second.global_position = second_position
	room._update_identity_badges()
	room._update_camera_targets()


func _make_surface(
	surface_id: String,
	rect: Rect2,
	eligibility: SupportSurfaceMetadata.Eligibility,
	player_built: bool,
	one_way: bool = false
) -> StaticBody2D:
	var metadata := SupportSurfaceMetadata.new()
	metadata.surface_id = surface_id
	metadata.player_built = player_built
	metadata.construction_id = surface_id if player_built else ""
	metadata.wave_support_eligibility = eligibility
	return _make_surface_with_metadata(metadata, rect, one_way)


func _make_surface_with_metadata(
	metadata: SupportSurfaceMetadata, rect: Rect2, one_way: bool = false
) -> StaticBody2D:
	if (
		metadata.inherits_provenance_from.is_empty()
		or not room.support_tracker.surfaces.has(metadata.surface_id)
	):
		room.support_tracker.register_surface(metadata)
	var body := StaticBody2D.new()
	body.name = metadata.surface_id
	body.position = rect.get_center()
	body.collision_layer = 1
	body.collision_mask = 1
	body.add_to_group("support_surfaces")
	body.set_meta(SupportSurfaceMetadata.META_KEY, metadata)
	room.world_layer.add_child(body)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	collision.one_way_collision = one_way
	body.add_child(collision)
	var visual := Polygon2D.new()
	visual.polygon = PackedVector2Array(
		[
			Vector2(-rect.size.x * 0.5, -rect.size.y * 0.5),
			Vector2(rect.size.x * 0.5, -rect.size.y * 0.5),
			Vector2(rect.size.x * 0.5, rect.size.y * 0.5),
			Vector2(-rect.size.x * 0.5, rect.size.y * 0.5),
		]
	)
	visual.color = Color("#8cb07b") if metadata.player_built else Color("#8a7050")
	body.add_child(visual)
	return body


func _eligible_metadata(surface_id: String, construction_id: String) -> SupportSurfaceMetadata:
	var metadata := SupportSurfaceMetadata.new()
	metadata.surface_id = surface_id
	metadata.construction_id = construction_id
	metadata.player_built = true
	metadata.wave_support_eligibility = SupportSurfaceMetadata.Eligibility.ELIGIBLE
	return metadata


func _place_actor_on(actor: ChickenController, position: Vector2) -> void:
	actor.global_position = position
	actor.velocity = Vector2.ZERO
	actor.locomotion_velocity = Vector2.ZERO
	actor.external_velocity = Vector2.ZERO
	actor.coyote_remaining = 0.0
	actor.lifecycle.status = PlayerLifecycleState.Status.ACTIVE
	actor.lifecycle.capture_source_id = ""
	room.support_tracker.invalidate_actor(actor.support_actor_id)
	for _frame in range(10):
		await physics_frame


func _wait_for_surface(actor: ChickenController, surface_id: String, max_frames: int) -> bool:
	for frame_index in range(max_frames):
		await physics_frame
		var result := room.current_support_result(actor.support_actor_id, 10000.0)
		var contact := result.contact as SupportContact
		if contact != null and contact.surface_id == surface_id:
			return true
	return false


func _physics_frames(count: int) -> void:
	for _frame in range(count):
		await physics_frame


func _physics_frames_track_ceiling(actor: ChickenController, count: int) -> bool:
	var hit_ceiling := false
	for _frame in range(count):
		await physics_frame
		hit_ceiling = hit_ceiling or actor.is_on_ceiling()
	return hit_ceiling


func _press(router: LocalInputRouter, key: int, down: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.keycode = key
	event.pressed = down
	router._handle_key(event)


func tuning_coyote(source_room: P03StageRoom) -> float:
	return source_room.tuning.coyote_seconds

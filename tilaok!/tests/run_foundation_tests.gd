extends SceneTree

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		push_error("FAIL: " + message)
		failures += 1


func _run() -> void:
	var gameplay := GameplayTuning.new()
	_check(gameplay.validate().is_empty(), "default gameplay tuning validates")
	gameplay.run_speed_wu_s = 0.0
	_check(not gameplay.validate().is_empty(), "invalid gameplay range is rejected")
	gameplay.run_speed_wu_s = INF
	_check(not gameplay.validate().is_empty(), "non-finite gameplay values are rejected")
	gameplay.run_speed_wu_s = 280.0
	var presentation := PresentationSettings.new()
	presentation.master_volume = 1.1
	_check(not presentation.validate().is_empty(), "invalid presentation range is rejected")
	presentation.master_volume = NAN
	_check(not presentation.validate().is_empty(), "non-finite presentation values are rejected")
	presentation.master_volume = 0.5

	var snapshot := ConfigurationSnapshot.create(gameplay, presentation, "movement_room", 12345, 1)
	gameplay.run_speed_wu_s = 300.0
	presentation.master_volume = 0.9
	_check(
		snapshot.gameplay.run_speed_wu_s == 280.0, "gameplay settings are copied into run snapshot"
	)
	_check(snapshot.presentation.master_volume == 0.5, "presentation snapshot starts as a copy")
	_check(
		not snapshot.apply_presentation_while_paused(presentation, false),
		"presentation edit is rejected while unpaused"
	)
	_check(
		snapshot.apply_presentation_while_paused(presentation, true),
		"presentation edit is accepted while paused"
	)
	presentation.master_volume = 1.1
	_check(
		not snapshot.apply_presentation_while_paused(presentation, true),
		"invalid paused presentation values are rejected"
	)
	_check(
		snapshot.rule_proposals_active == {"R1": false, "R2": false, "R3": false, "R4": false},
		"R1-R4 are inactive"
	)
	_check(ProfileRegistry.get_profile("unknown") == null, "unknown profile IDs are rejected")
	_check(ProfileRegistry.ids().size() == 7, "seven contract profiles are registered")

	var catalog := DiagnosticContentCatalog.new()
	_check(
		catalog.validate_profile(ProfileRegistry.get_profile("movement_room")).is_empty(),
		"diagnostic bootstrap profile validates"
	)
	_check(
		not catalog.validate_profile(ProfileRegistry.get_profile("release_candidate")).is_empty(),
		"incomplete release profile is rejected"
	)
	var empty_pool_errors := catalog.validate_profile(ProfileRegistry.get_profile("lagsanay_lab"))
	var required_pool_rejected := false
	for error in empty_pool_errors:
		if error.contains("empty eligible 'item' pool"):
			required_pool_rejected = true
	_check(required_pool_rejected, "profile with an empty required pool is rejected")
	_check(not catalog.validate_profile(null).is_empty(), "missing profile is rejected")
	var eligible := DiagnosticContentEntry.new(
		"build.eligible", "item", true, true, true, true, 2.0
	)
	var eligible_also := DiagnosticContentEntry.new(
		"build.eligible_also", "item", true, true, true, true, 1.0
	)
	var unverified := DiagnosticContentEntry.new(
		"build.unverified", "item", true, false, false, true, 7.0
	)
	var disabled := DiagnosticContentEntry.new(
		"build.disabled", "item", true, true, false, true, 9.0
	)
	var zero_weight := DiagnosticContentEntry.new("build.zero", "item", true, true, true, true, 0.0)
	catalog.entries = [eligible, eligible_also, unverified, disabled, zero_weight]
	_check(catalog.validate_catalog().is_empty(), "valid catalog entries pass validation")
	_check(
		catalog.eligible_entries("item").size() == 2,
		"only enabled, implemented, verified positive-weight entries are eligible"
	)
	catalog.entries.append(
		DiagnosticContentEntry.new("build.bad_enabled", "item", true, false, true, true, 1.0)
	)
	_check(
		not catalog.validate_catalog().is_empty(),
		"runtime-enabled but unverified content is rejected"
	)
	catalog.entries.pop_back()
	_check(
		is_equal_approx(catalog.normalized_weights("item")["build.eligible"], 2.0 / 3.0),
		"eligible pool weights normalize after filtering"
	)
	_check(catalog.eligible_entries("mode").is_empty(), "empty required pool is observable")
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	var one_pick := SeededDiagnosticStreams.new().choose_weighted(catalog, "item", rng)
	_check(
		one_pick == eligible or one_pick == eligible_also,
		"weighted selector only returns eligible entries"
	)
	_check(
		SeededDiagnosticStreams.new().choose_weighted(catalog, "mode", rng) == null,
		"empty pool returns no fallback selection"
	)
	var selection_a := RandomNumberGenerator.new()
	var selection_b := RandomNumberGenerator.new()
	selection_a.seed = 12345
	selection_b.seed = 12345
	var same_profile_sequence := true
	for _index in range(32):
		var picked_a := SeededDiagnosticStreams.new().choose_weighted(catalog, "item", selection_a)
		var picked_b := SeededDiagnosticStreams.new().choose_weighted(catalog, "item", selection_b)
		same_profile_sequence = same_profile_sequence and picked_a.content_id == picked_b.content_id
	_check(same_profile_sequence, "same profile and seed reproduce weighted selection sequence")
	var invalid := DiagnosticContentEntry.new(
		"bad id", "item", true, true, true, false, -1.0, PackedStringArray(["missing.reference"])
	)
	catalog.entries.append(invalid)
	_check(
		not catalog.validate_catalog().is_empty(),
		"invalid IDs, weights, and references are rejected"
	)
	catalog.entries.append(DiagnosticContentEntry.new("build.eligible", "item"))
	_check(not catalog.validate_catalog().is_empty(), "duplicate IDs are rejected")

	var stream_a := SeededDiagnosticStreams.new()
	var stream_b := SeededDiagnosticStreams.new()
	stream_a.seed_all(12345)
	stream_b.seed_all(12345)
	var same_seed_matches := true
	for _index in range(8):
		same_seed_matches = same_seed_matches and stream_a.egg.randi() == stream_b.egg.randi()
	_check(same_seed_matches, "same seed reproduces egg stream")
	var baseline := SeededDiagnosticStreams.new()
	var cosmetic_advanced := SeededDiagnosticStreams.new()
	baseline.seed_all(12345)
	cosmetic_advanced.seed_all(12345)
	for _index in range(20):
		cosmetic_advanced.cosmetic.randi()
	_check(
		baseline.egg.randi() == cosmetic_advanced.egg.randi(),
		"cosmetic draws do not affect egg stream"
	)
	var separated_streams := SeededDiagnosticStreams.new()
	var untouched_streams := SeededDiagnosticStreams.new()
	separated_streams.seed_all(12345)
	untouched_streams.seed_all(12345)
	for _index in range(20):
		separated_streams.egg.randi()
	_check(
		separated_streams.event.randi() == untouched_streams.event.randi(),
		"egg draws do not affect event stream"
	)

	var fixture_parent := Node.new()
	root.add_child(fixture_parent)
	var node_baseline := root.get_child_count()
	var fixture_paths := [
		"res://scenes/fixtures/movement_room.tscn",
		"res://scenes/fixtures/item_lab.tscn",
		"res://scenes/fixtures/event_lab.tscn",
		"res://scenes/fixtures/p03_stage_room.tscn"
	]
	for fixture_path in fixture_paths:
		var fixture_scene: PackedScene = load(fixture_path)
		for _index in range(10):
			var fixture := fixture_scene.instantiate()
			fixture_parent.add_child(fixture)
			fixture.queue_free()
			await process_frame
			await process_frame
		if fixture_path == "res://scenes/fixtures/p03_stage_room.tscn":
			_check(
				fixture_parent.get_child_count() == 0,
				"repeated P03 fixture loads release room and owned nodes"
			)
		var probe: Node = fixture_scene.instantiate()
		_check(probe.has_signal("return_requested"), "%s exposes return signal" % fixture_path)
		probe.free()
	_check(
		root.get_child_count() == node_baseline, "repeated fixture cleanup returns to node baseline"
	)
	fixture_parent.free()
	print("Foundation checks complete: %d failure(s)." % failures)
	await _run_harness_lifecycle_checks()


func _run_harness_lifecycle_checks() -> void:
	var harness_scene: PackedScene = load("res://scenes/harness/foundation_harness.tscn")
	var harness := harness_scene.instantiate() as FoundationHarness
	root.add_child(harness)
	await process_frame
	var room_host: Control = harness.get_node("Layout/RoomHost")
	var root_baseline := root.get_child_count()
	for button_name in ["ValidateButton", "RunButton", "ResetButton", "ReloadButton", "ExitButton"]:
		var button_path := "Layout/HarnessPanel/ActionRow/%s" % button_name
		if button_name == "ExitButton":
			button_path = "Layout/ExitButton"
		var button: Button = harness.get_node(button_path)
		_check(
			button.pressed.get_connections().size() == 1, "%s has one action callback" % button_name
		)
	for room_id in [
		"movement_room", "p02_movement_room", "item_lab", "event_lab", "p03_stage_room"
	]:
		for _index in range(10):
			harness._open_room(room_id)
			await process_frame
			var fixture: Node = harness.active_room
			_check(
				fixture.get_signal_connection_list("return_requested").size() == 1,
				"%s connects one return callback" % room_id
			)
			harness._close_room()
			await process_frame
			if room_id == "p02_movement_room":
				await physics_frame
			var released := (
				harness.active_room == null
				and harness.get_node_or_null("P03StageRoom") == null
				and harness.get_node_or_null("ItemLabRoom") == null
				and room_host.get_child_count() == 0
			)
			_check(released, "%s reset releases its fixture" % room_id)
	_check(root.get_child_count() == root_baseline, "harness fixtures return root to baseline")
	harness._start_diagnostic_run()
	_check(harness.active_snapshot != null, "harness run creates a configuration snapshot")
	harness._reset_scenario()
	_check(harness.active_snapshot == null, "scenario reset clears the run snapshot")
	harness.queue_free()
	await process_frame
	var change_result := change_scene_to_packed(harness_scene)
	_check(change_result == OK, "harness scene loads through the scene lifecycle")
	await process_frame
	var before_reload := current_scene as FoundationHarness
	before_reload._start_diagnostic_run()
	before_reload._open_room("item_lab")
	before_reload._reload_harness()
	await process_frame
	await process_frame
	var after_reload := current_scene as FoundationHarness
	_check(after_reload != before_reload, "reload creates a fresh harness scene")
	_check(after_reload.active_snapshot == null, "reload clears the diagnostic run snapshot")
	_check(
		after_reload.get_node("Layout/RoomHost").get_child_count() == 0,
		"reload releases the active fixture"
	)
	_check(
		after_reload.get_node("Layout/HarnessPanel").visible,
		"reload restores the diagnostic controls"
	)
	print("Harness lifecycle checks complete: %d failure(s)." % failures)
	quit(1 if failures > 0 else 0)

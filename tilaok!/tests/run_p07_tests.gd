extends SceneTree

const P07_SCENE := preload("res://scenes/match/p07_first_playable_room.tscn")
## Since 2026-10-14 the selector offers every main-game block scene that is enabled by default
## (BlockCatalog), so new blocks such as Spikes and Cannon reach the match without a code edit.
## P10 hazards stay out of this pool.
var expected_variants := BlockCatalog.default_enabled_keys()

var checks := 0
var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var room := P07_SCENE.instantiate() as P07FirstPlayableMatchRoom
	root.add_child(room)
	await process_frame
	await physics_frame

	_check(room.profile_id == "karera_slice", "P07 retains the karera_slice profile identity")
	_check(
		room.tuning.item_enabled_variants == expected_variants,
		"P07 config enables exactly the main-game block scenes (catalog default pool)"
	)
	_check(room.definitions != null and room.definitions.is_valid(), "P07 item definitions load")
	var enabled_from_definitions := PackedStringArray()
	for family in room.definitions.families:
		enabled_from_definitions.append_array(
			room.definitions.enabled_variant_keys(family.family_id)
		)
	enabled_from_definitions.sort()
	var expected_sorted := expected_variants.duplicate()
	expected_sorted.sort()
	_check(
		enabled_from_definitions == expected_sorted,
		"P07 loaded definition set exposes only the catalog default variants"
	)
	_check(
		room._validate_p07_egg_pool([{"variant_key": expected_variants[0]}]).is_empty(),
		"P07 pool validator accepts allowed variants"
	)
	_check(
		not (
			room._validate_p07_egg_pool([{"variant_key": "hazard.rail_trumpo.rail_4x1"}]).is_empty()
		),
		"P07 pool validator rejects a variant outside the main-game pool (a P10 hazard)"
	)
	_check(
		(
			expected_variants.has("block.spikes.main")
			and expected_variants.has("block.cannon.main")
			and not expected_variants.has("build.hollow_blocks.column_1x3")
		),
		"P07 pool includes Spikes and Cannon and still omits disabled sizes"
	)

	for seed_value in range(64):
		var tuning_copy := room.tuning.duplicate(true) as GameplayTuning
		var definitions := ItemDefinitions.load_for_profile(tuning_copy, room.profile_id)
		var streams := SeededDiagnosticStreams.new()
		streams.seed_all(seed_value)
		var pool := PugadEggPoolGenerator.generate(definitions, tuning_copy, streams, 8)
		_check(not pool.is_empty(), "seed %d yields a nonempty P07 pool" % seed_value)
		for egg in pool:
			_check(
				expected_variants.has(str(egg.get("variant_key", ""))),
				"seed %d generated only P07-allowed variants" % seed_value
			)

	var seat_zero := room.join_keyboard("K1")
	var seat_one := room.join_keyboard("K2")
	_check(seat_zero == 0 and seat_one == 1, "P07 supports K1/K2 seat assignment")
	room.input_router.registry.set_ready(seat_zero, true)
	room._on_match_action_pressed(seat_zero, "ready")
	_check(
		room.phase_controller.phase == MatchPhaseController.Phase.LOBBY,
		"P07 waits until all joined seats are ready"
	)
	room.input_router.registry.set_ready(seat_one, true)
	room._on_match_action_pressed(seat_one, "ready")
	_check(
		room.phase_controller.phase == MatchPhaseController.Phase.PUGAD,
		"P07 starts from player-ready input without the diagnostic Start button"
	)
	_check(
		not room.presenter.debug_overlay.visible,
		"P07 shows no harness-only join/start buttons (the DEBUG overlay is off by default)"
	)
	for egg in room.egg_pool:
		_check(
			expected_variants.has(str(egg.variant_key)),
			"actual P07 runtime egg pool excludes unapproved variants"
		)

	room.queue_free()
	await process_frame
	print("P07_TESTS checks=%d failures=%d" % [checks, failures.size()])
	for failure in failures:
		push_error(failure)
	quit(1 if not failures.is_empty() else 0)


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)

extends SceneTree

const P07_SCENE := preload("res://scenes/match/p07_first_playable_room.tscn")
const EXPECTED_VARIANTS: PackedStringArray = [
	"build.hollow_blocks.cell_1x1",
	"build.hollow_blocks.stack_2x3",
	"build.bamboo_bridge.span_4x1",
]

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
		room.tuning.item_enabled_variants == EXPECTED_VARIANTS,
		"P07 config enables exactly the verified Kaing/Tulay variants"
	)
	_check(room.definitions != null and room.definitions.is_valid(), "P07 item definitions load")
	var enabled_from_definitions := PackedStringArray()
	for family in room.definitions.families:
		enabled_from_definitions.append_array(
			room.definitions.enabled_variant_keys(family.family_id)
		)
	enabled_from_definitions.sort()
	var expected_sorted := EXPECTED_VARIANTS.duplicate()
	expected_sorted.sort()
	_check(
		enabled_from_definitions == expected_sorted,
		"P07 loaded definition set exposes only the three allowed variants"
	)
	_check(
		room._validate_p07_egg_pool([{"variant_key": EXPECTED_VARIANTS[0]}]).is_empty(),
		"P07 pool validator accepts allowed variants"
	)
	_check(
		not room._validate_p07_egg_pool([{"variant_key": "build.solid_block.slab_3x1"}]).is_empty(),
		"P07 pool validator rejects an unapproved stage block"
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
				EXPECTED_VARIANTS.has(str(egg.get("variant_key", ""))),
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
		(
			room._match_buttons.start.visible == false
			and room._match_buttons.join_k1.visible == false
			and room._match_buttons.join_k2.visible == false
		),
		"P07 hides harness-only join/start buttons"
	)
	for egg in room.egg_pool:
		_check(
			EXPECTED_VARIANTS.has(str(egg.variant_key)),
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

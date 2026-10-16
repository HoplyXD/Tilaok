extends SceneTree

## Explosives and the Pugad pick lock (requested by Jorge, 2026-10-15).
## - Bomb 2x2, Dynamite 3x3 and Nuke 4x4 are scene-authored one-shot cleanup blocks: in a real
##   match they clear player-built pieces inside their area, including pieces placed in the same
##   Place phase (2026-10-16), and show a short placeholder blast.
## - After a seat claims a Pugad egg it can no longer move its selection.
## Synthetic input in the real P05 match room. Run:
## godot --headless --fixed-fps 60 --path tilaok! --script res://tests/run_explosives_tests.gd

const MATCH_SCENE := preload("res://scenes/match/match_room.tscn")
const KAING := "build.hollow_blocks.cell_1x1"
const BOMB := "explosive.bomb.main"
const DYNAMITE := "explosive.dynamite.main"
const NUKE := "explosive.nuke.main"

var failures := 0
var checks := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_catalog()
	await _test_pugad_pick_lock()
	await _test_bomb_clears_earlier_pieces()
	print("EXPLOSIVES_TESTS checks=%d failures=%d" % [checks, failures])
	await process_frame
	quit(1 if failures > 0 else 0)


func _check(condition: bool, label: String) -> void:
	checks += 1
	if condition:
		print("PASS ", label)
	else:
		failures += 1
		push_error("FAIL " + label)


func _test_catalog() -> void:
	var pool := P07FirstPlayableMatchRoom.allowed_variants()
	var definitions := ItemDefinitions.load_all(GameplayTuning.new())
	var sizes := {BOMB: Vector2i(2, 2), DYNAMITE: Vector2i(3, 3), NUKE: Vector2i(4, 4)}
	var labels := {BOMB: "Bomb", DYNAMITE: "Dynamite", NUKE: "Nuke"}
	for key in sizes:
		var found := definitions.find_variant(key)
		_check(not found.is_empty(), "%s is in the catalog from its scene alone" % key)
		if found.is_empty():
			continue
		var family := found.family as ItemFamilyDefinition
		var variant := found.variant as ItemVariantDefinition
		_check(
			family.one_shot_edit and variant.footprint_cells == sizes[key],
			"%s is a one-shot %s cleanup" % [labels[key], sizes[key]]
		)
		_check(pool.has(key), "%s is in the match selector pool" % labels[key])
		_check(definitions.short_label(key) == labels[key], "%s is labelled by name" % labels[key])


func _start_two_seats() -> P05MatchRoom:
	var room := MATCH_SCENE.instantiate() as P05MatchRoom
	root.add_child(room)
	await process_frame
	room.join_keyboard("K1")
	room.join_keyboard("K2")
	room.input_router.registry.set_ready(0, true)
	room.input_router.registry.set_ready(1, true)
	room.start_match()
	return room


func _test_pugad_pick_lock() -> void:
	var room := await _start_two_seats()
	room._queue_claim(0, str(room.egg_pool[0].egg_id))
	room._flush_claims()
	_check(room.assignments.has(0), "P1 claims the first egg")
	var before := int(room.selected_egg_by_seat[0])
	room._on_match_navigation_step(0, "right")
	room._on_match_navigation_step(0, "left")
	room._on_match_navigation_step(0, "right")
	_check(
		int(room.selected_egg_by_seat[0]) == before,
		"after claiming, P1 can no longer move to another egg"
	)
	var other_before := int(room.selected_egg_by_seat[1])
	room._on_match_navigation_step(1, "right")
	_check(
		int(room.selected_egg_by_seat[1]) != other_before,
		"P2, who has not claimed yet, can still browse"
	)
	room._queue_claim(0, str(room.egg_pool[2].egg_id))
	room._flush_claims()
	_check(
		str(room.assignments[0]) == str(room.egg_pool[0].egg_id),
		"a second claim press never swaps P1's egg"
	)
	room.queue_free()
	await process_frame


func _edit(seat: int, variant_key: String, cell: Vector2i) -> Dictionary:
	return {
		"seat_index": seat,
		"variant_key": variant_key,
		"origin_cell": cell,
		"quarter_turns": 0,
		"cleanup_targets": [],
	}


func _place_round(room: P05MatchRoom, edits: Array[Dictionary]) -> void:
	room._finish_pugad_timeout()
	room._resolve_place_edits(edits)


func _finish_race(room: P05MatchRoom) -> void:
	var controller := room.race_round_controller
	controller.hard_cap_seconds = 0.002
	var empty: Array[Dictionary] = []
	var step := controller.advance_step(0.01, Engine.get_physics_frames(), empty)
	room._apply_race_outcomes(step.new_outcomes)
	room._finish_race(str(step.end_reason))
	room._start_next_round()


func _piece_cells(room: P05MatchRoom) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for record in room.items.pieces.values():
		cells.append((record as PlacedItem).origin_cell)
	cells.sort()
	return cells


func _test_bomb_clears_earlier_pieces() -> void:
	var room := await _start_two_seats()
	var round_one: Array[Dictionary] = [
		_edit(0, KAING, Vector2i(14, 8)), _edit(1, KAING, Vector2i(18, 8))
	]
	_place_round(room, round_one)
	_check(
		_piece_cells(room) == [Vector2i(14, 8), Vector2i(18, 8)], "round 1 builds two Kaing pieces"
	)
	_finish_race(room)
	# Round 2: P1's bomb covers (14..15, 8..9); P2 builds inside that area in the same phase.
	var round_two: Array[Dictionary] = [
		_edit(0, BOMB, Vector2i(14, 8)), _edit(1, KAING, Vector2i(15, 9))
	]
	_place_round(room, round_two)
	var cells := _piece_cells(room)
	_check(not cells.has(Vector2i(14, 8)), "the bomb destroys the earlier Kaing in its 2x2 area")
	_check(cells.has(Vector2i(18, 8)), "a piece outside the blast area is untouched")
	_check(
		(
			not cells.has(Vector2i(15, 9))
			and str(room.last_resolution.rejections.get(1, "")) == "Blown up by P1's Bomb"
		),
		"a piece placed in the blast area in the same Place phase is blown up too"
	)
	var flashes := room.world_layer.get_children().filter(
		func(node: Node) -> bool: return node is ExplosionFlash
	)
	_check(flashes.size() == 1, "the bomb shows one placeholder blast")
	_check(
		room.phase_controller.phase == MatchPhaseController.Phase.PLAY,
		"Play starts after the blast"
	)
	_finish_race(room)
	# Round 3: a Nuke clears everything earlier inside 4x4, including the round-2 piece.
	var round_three: Array[Dictionary] = [_edit(1, NUKE, Vector2i(14, 6))]
	_place_round(room, round_three)
	cells = _piece_cells(room)
	_check(
		not cells.has(Vector2i(15, 9)) and cells.has(Vector2i(18, 8)),
		"the nuke clears its 4x4 area and nothing outside it: %s" % [cells]
	)
	room.queue_free()
	await process_frame

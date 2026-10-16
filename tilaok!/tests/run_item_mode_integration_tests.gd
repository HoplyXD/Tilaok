# gdlint: disable=max-file-lines
extends SceneTree

## Item integration with events and scoring (P04-T11, P04-T20, P10-T07/T16/T25/T34/T43/T52) on the
## scheduled P12 match room, the default player route.
## - Catalog mode restrictions: the Pugad deals only families whose `modes_allowed` lists every
##   active mode of the round (Main and Twist). Pieces already on the stage stay as they are
##   (owner decision, Jorge 2026-10-16).
## - Real pieces, real physics: in every independent mode and supported stack, a direct hazard
##   kill (Trumpo, Parol, Tsinelas) credits its placer; Gulong launches and Bula captures with no
##   credit; Kaing and Tulay are standable terrain that never eliminates; Walis clears earlier
##   pieces in Place and has no Play effect.
## Synthetic seats (K1/K2 plus a synthetic gamepad id). Each round's locked schedule entry is forced
## to the case under test (test-only; the real schedule rolls it).
## Run: godot --headless --fixed-fps 60 --path tilaok!
##   --script res://tests/run_item_mode_integration_tests.gd

const ROOM_SCENE := preload("res://scenes/match/p12_scheduled_match_room.tscn")
const KARERA := EventSchedule.Challenge.KARERA
const LAGSANAY := EventSchedule.Challenge.LAGSANAY
const KANGAROO := EventSchedule.Challenge.KANGAROO
const NONE := EventSchedule.Challenge.NONE
const KAING := "build.hollow_blocks.stack_2x3"
const KAING_1 := "build.hollow_blocks.cell_1x1"
const TULAY := "build.bamboo_bridge.span_4x1"
const SPRING := "move.tire_spring.tire_2x2"
const TRUMPO := "hazard.rail_trumpo.rail_4x1"
const PAROL := "hazard.parol_pulse.span_5x1"
const TSINELAS := "hazard.slipper_launcher.lane_6x1"
const WALIS := "utility.walis_cleanup.area_3x3"
const BULA := "hazard.bubble_planter.path_1x5"
const INITIAL_FAMILIES: PackedStringArray = [
	"build.hollow_blocks",
	"build.bamboo_bridge",
	"move.tire_spring",
	"hazard.rail_trumpo",
	"hazard.parol_pulse",
	"hazard.slipper_launcher",
	"utility.walis_cleanup",
	"hazard.bubble_planter",
]
const ENTRIES := [
	["Karera", KARERA, NONE],
	["Lagsanay", LAGSANAY, NONE],
	["Kangaroo", KANGAROO, NONE],
	["Karera + Bomb-Taya", KARERA, LAGSANAY],
	["Karera + Kangaroo", KARERA, KANGAROO],
	["Kangaroo + Bomb-Taya", KANGAROO, LAGSANAY],
]
const OWNER := 0
const VICTIM := 1

var checks := 0
var failures := 0
var room: P12ScheduledMatchRoom
var mode_table: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_catalog()
	_test_generator_filter()
	for entry in ENTRIES:
		await _test_room_pool(entry)
	for entry in ENTRIES:
		for variant in [TRUMPO, PAROL, TSINELAS]:
			await _test_direct_kill(entry, variant)
		await _test_spring(entry)
		await _test_bubble(entry)
		await _test_terrain(entry, KAING)
		await _test_terrain(entry, TULAY)
	await _test_walis()
	for line in mode_table:
		print("MODE_TABLE ", line)
	print("ITEM_MODE_INTEGRATION_TESTS checks=%d failures=%d" % [checks, failures])
	await process_frame
	quit(1 if failures > 0 else 0)


func _check(condition: bool, label: String) -> void:
	checks += 1
	if condition:
		print("PASS ", label)
	else:
		failures += 1
		push_error("FAIL " + label)


func _main_definitions() -> ItemDefinitions:
	var tuning := GameplayTuning.new()
	tuning.item_enabled_variants = BlockCatalog.default_enabled_keys()
	return ItemDefinitions.load_all(tuning)


func _entry_modes(entry: Array) -> PackedStringArray:
	var schedule_entry := {"main": int(entry[1]), "twist": int(entry[2])}
	return EventSchedule.mode_ids(schedule_entry)


# --- catalog, mode table and support eligibility -------------------------------------------


func _test_catalog() -> void:
	var definitions := _main_definitions()
	var keys := BlockCatalog.default_enabled_keys()
	for family_id in INITIAL_FAMILIES:
		var family := definitions.find_family(family_id)
		var in_pool := false
		for key in keys:
			in_pool = in_pool or key.begins_with(family_id + ".")
		_check(
			family != null and in_pool,
			"%s is in the main match egg pool (P10 families joined 2026-10-16)" % family_id
		)
		if family == null:
			continue
		var wave := family.support_role
		(
			mode_table
			. append(
				(
					"%s | allowed %s | pending review %s | wave support %s | weight %.0f"
					% [
						family_id,
						",".join(family.modes_allowed),
						(
							",".join(family.modes_pending_review)
							if not family.modes_pending_review.is_empty()
							else "-"
						),
						wave,
						family.selection_weight(GameplayTuning.new()),
					]
				)
			)
		)
	var tuning := GameplayTuning.new()
	_check(
		(
			is_equal_approx(tuning.item_spring_weight, 15.0)
			and is_equal_approx(tuning.item_trumpo_weight, 20.0)
			and is_equal_approx(tuning.item_parol_weight, 15.0)
			and is_equal_approx(tuning.item_launcher_weight, 20.0)
			and is_equal_approx(tuning.item_walis_weight, 15.0)
			and is_equal_approx(tuning.item_bubble_weight, 10.0)
		),
		"the six P10 families use low provisional match weights (15/20/15/20/15/10)"
	)


# --- the generator filter -----------------------------------------------------------------


func _test_generator_filter() -> void:
	var definitions := _main_definitions()
	var tuning := GameplayTuning.new()
	tuning.item_enabled_variants = BlockCatalog.default_enabled_keys()
	for entry in ENTRIES:
		var modes := _entry_modes(entry)
		var streams := SeededDiagnosticStreams.new()
		streams.seed_all(20261016)
		var pool := PugadEggPoolGenerator.generate(definitions, tuning, streams, 1500, modes)
		var dealt := {}
		var bad := PackedStringArray()
		for egg in pool:
			var family := (
				definitions.find_variant(str(egg.variant_key)).family as ItemFamilyDefinition
			)
			dealt[family.family_id] = true
			if not PugadEggPoolGenerator.allows_modes(family, modes):
				bad.append(str(egg.variant_key))
		var expected := PackedStringArray()
		for family in definitions.families:
			if (
				PugadEggPoolGenerator.allows_modes(family, modes)
				and not definitions.enabled_variant_keys(family.family_id).is_empty()
				and family.selection_weight(tuning) > 0.0
			):
				expected.append(family.family_id)
		var missing := PackedStringArray()
		for family_id in expected:
			if not dealt.has(family_id):
				missing.append(family_id)
		_check(
			bad.is_empty() and missing.is_empty() and dealt.size() == expected.size(),
			(
				"%s: 1500 eggs deal only the %d families approved for %s (bad %s, missing %s)"
				% [entry[0], expected.size(), ",".join(modes), bad, missing]
			)
		)
		var excluded := PackedStringArray()
		for family_id in INITIAL_FAMILIES:
			if not dealt.has(family_id):
				excluded.append(family_id.get_slice(".", 1))
		mode_table.append("%s eggs exclude: %s" % [entry[0], ", ".join(excluded)])
	var none_streams := SeededDiagnosticStreams.new()
	none_streams.seed_all(20261016)
	var unfiltered := PugadEggPoolGenerator.generate(definitions, tuning, none_streams, 5)
	var karera_streams := SeededDiagnosticStreams.new()
	karera_streams.seed_all(20261016)
	var karera := PugadEggPoolGenerator.generate(
		definitions, tuning, karera_streams, 5, PackedStringArray(["karera"])
	)
	_check(
		unfiltered == karera,
		"every family allows Karera, so Karera rounds deal exactly the unfiltered seeded eggs"
	)


# --- the real room ------------------------------------------------------------------------


func _open(seat_count: int, entry: Array) -> void:
	room = ROOM_SCENE.instantiate() as P12ScheduledMatchRoom
	root.add_child(room)
	await process_frame
	await physics_frame
	var seats: Array[int] = [room.join_keyboard("K1"), room.join_keyboard("K2")]
	for device_id in [7101, 7102].slice(0, seat_count - 2):
		var seat_index := room.input_router.registry.join_gamepad(device_id)
		seats.append(seat_index)
		room.input_router.seat_joined.emit(seat_index)
	for seat_index in seats:
		room.input_router.registry.set_ready(seat_index, true)
	room.start_match()
	for round_number in [1, 2]:
		room.schedule.locked[round_number] = {
			"round": round_number,
			"main": int(entry[1]),
			"twist": int(entry[2]),
			"guaranteed": false,
			"sudden_death": false,
			"twist_options": 0,
		}
	room.tuning.match_target_score_units = 100000
	room.tuning.match_results_advance_seconds = 600.0
	room.tuning.match_race_hard_cap_seconds = 600.0
	room.tuning.match_race_after_first_finish_seconds = 600.0


func _close() -> void:
	if room != null and is_instance_valid(room):
		room.queue_free()
	room = null
	await process_frame
	await process_frame


func _edit(seat: int, variant_key: String, cell: Vector2i) -> Dictionary:
	return {
		"seat_index": seat,
		"variant_key": variant_key,
		"origin_cell": cell,
		"quarter_turns": 0,
		"cleanup_targets": [],
	}


func _to_play(edits: Array[Dictionary]) -> bool:
	room._finish_pugad_timeout()
	room._resolve_place_edits(edits)
	if room.phase_controller.phase != MatchPhaseController.Phase.PLAY:
		return false
	# No opening head start or taya timeout during these checks: only the item acts. (The event
	# validates its tuning at begin, so these are cleared on the live controllers instead.)
	room.bomb_taya.head_start_remaining = 0.0
	room.bomb_taya.countdown_remaining = 600.0
	room.lagsanay_controller.head_start_remaining = 0.0
	room.lagsanay_controller.countdown_remaining = 600.0
	for actor in room.actors.values():
		(actor as ChickenController).set_opening_freeze(false)
	_park_bystanders()
	return true


## Seats other than the victim wait at the spawn, far from every test piece.
func _park_bystanders() -> void:
	var index := 0
	for seat in room.actors:
		if int(seat) == VICTIM:
			continue
		var actor := room.actors[seat] as ChickenController
		var feet := room.arena.spawn_feet + Vector2(-60.0 + 120.0 * index, 0.0)
		actor.global_position = room.arena.controller_origin_from_feet(feet)
		actor.velocity = Vector2.ZERO
		index += 1


func _victim() -> ChickenController:
	return room.actors[VICTIM] as ChickenController


func _hold(center: Vector2) -> void:
	var actor := _victim()
	actor.global_position = center
	actor.velocity = Vector2.ZERO
	actor.clear_external_motion()


func _piece() -> StageBlock:
	for instance_id in room.items.pieces:
		return room.items.piece_for(str(instance_id)) as StageBlock
	return null


## The victim's terminal outcome in whichever controller owns this round's end.
func _outcome(entry: Array) -> Dictionary:
	var main := int(entry[1])
	if main == LAGSANAY:
		return room.lagsanay_controller.outcomes_by_seat.get(VICTIM, {})
	if main == KANGAROO:
		for outcome in room.kangaroo_round.controller.terminal_outcomes:
			if int(outcome.get("seat_index", -1)) == VICTIM:
				return outcome
		return {}
	if room.race_round_controller == null:
		return {}
	return room.race_round_controller.ledger.outcomes_by_seat.get(VICTIM, {})


func _eliminations_recorded() -> int:
	var count := 0
	for record in room.items.director.records:
		if record.kind == AttributionRecord.Kind.ELIMINATION:
			count += 1
	return count


func _eliminated() -> bool:
	return _victim().lifecycle.status == PlayerLifecycleState.Status.ELIMINATED


# --- Pugad pools on the room --------------------------------------------------------------


func _test_room_pool(entry: Array) -> void:
	await _open(4, entry)
	room.tuning.match_pugad_extra_eggs = 24
	room._begin_pugad()
	var modes := _entry_modes(entry)
	var bad := PackedStringArray()
	var count := 0
	for egg in room.egg_pool:
		var key := str(egg.variant_key)
		if room._is_round_objective_variant(key):
			continue
		count += 1
		var family := room.definitions.find_variant(key).family as ItemFamilyDefinition
		if not PugadEggPoolGenerator.allows_modes(family, modes):
			bad.append(key)
	_check(
		(
			room.phase_controller.phase == MatchPhaseController.Phase.PUGAD
			and room.pugad_mode_ids() == modes
			and count >= 20
			and bad.is_empty()
		),
		(
			"%s: the room's Pugad (%d eggs) deals only %s-approved items (bad %s)"
			% [entry[0], count, ",".join(modes), bad]
		)
	)
	await _close()


# --- direct hazards: kill and Patibong credit ---------------------------------------------


func _kill_point(variant_key: String) -> Vector2:
	var piece := _piece()
	if piece == null:
		return Vector2.ZERO
	var behavior := piece.behavior
	if behavior is TrumpoBehavior:
		return (behavior as TrumpoBehavior).current_rect.get_center()
	if behavior is ParolBehavior:
		return (behavior as ParolBehavior).beam.get_center()
	if behavior is LauncherBehavior:
		var lane := (behavior as LauncherBehavior).lane
		return lane.get_center() + Vector2(lane.size.x * 0.25, 0.0)
	push_error("no kill point for %s" % variant_key)
	return Vector2.ZERO


func _test_direct_kill(entry: Array, variant_key: String) -> void:
	var cells := {TRUMPO: Vector2i(14, 8), PAROL: Vector2i(13, 8), TSINELAS: Vector2i(8, 8)}
	var name := variant_key.get_slice(".", 1)
	await _open(3, entry)
	var edits: Array[Dictionary] = [_edit(OWNER, variant_key, cells[variant_key])]
	var playing := _to_play(edits)
	var piece := _piece()
	_check(
		playing and piece != null and int(room.items.pieces.size()) == 1,
		"%s: %s placed by P1 is on the stage in Play" % [entry[0], name]
	)
	if piece == null:
		await _close()
		return
	var instance_id := str(room.items.pieces.keys()[0])
	var frames := 0
	while frames < 900 and not _eliminated():
		_hold(_kill_point(variant_key))
		await physics_frame
		frames += 1
	await physics_frame
	await physics_frame
	var outcome := _outcome(entry)
	_check(
		(
			_eliminated()
			and str(outcome.get("cause", "")) == "direct_hazard"
			and int(outcome.get("direct_owner_seat", -1)) == OWNER
			and str(outcome.get("source_item_id", "")) == instance_id
		),
		(
			"%s: %s eliminates P2 and credits its placer P1 (Patibong) after %d steps: %s"
			% [entry[0], name, frames, outcome]
		)
	)
	await _close()


# --- Gulong: a launch, never a credit -----------------------------------------------------


func _test_spring(entry: Array) -> void:
	await _open(3, entry)
	var edits: Array[Dictionary] = [_edit(OWNER, SPRING, Vector2i(16, 13))]
	_to_play(edits)
	var piece := _piece()
	if piece == null:
		_check(false, "%s: Gulong is placed" % entry[0])
		await _close()
		return
	var spring := piece.behavior as SpringBehavior
	var top := piece.footprint_world_rect()
	var drop := Vector2(
		top.get_center().x, top.position.y - room.tuning.body_height_wu * 0.5 - 24.0
	)
	for _frame in range(75):
		_hold(drop)
		await physics_frame
	var highest := INF
	for _frame in range(120):
		await physics_frame
		highest = minf(highest, _victim().global_position.y)
		if spring.launch_count > 0 and _victim().velocity.y > 0.0:
			break
	_check(
		(
			spring.launch_count >= 1
			and highest < drop.y - 64.0
			and not _victim().lifecycle.is_terminal()
			and _outcome(entry).is_empty()
		),
		(
			"%s: Gulong launches P2 (%d launch, rose %.0f wu) with no elimination or credit"
			% [entry[0], spring.launch_count, drop.y - highest]
		)
	)
	await _close()


# --- Bula: a capture, never a credit ------------------------------------------------------


func _test_bubble(entry: Array) -> void:
	await _open(3, entry)
	var edits: Array[Dictionary] = [_edit(OWNER, BULA, Vector2i(16, 13))]
	_to_play(edits)
	var piece := _piece()
	if piece == null:
		_check(false, "%s: Bula is placed" % entry[0])
		await _close()
		return
	var bubble := piece.behavior as BubbleBehavior
	var frames := 0
	while frames < 600 and bubble.capture_count == 0:
		if bubble.has_bubble():
			_hold(bubble.bubble_center)
		else:
			_hold(bubble.path.get_center() + Vector2(0.0, -16.0))
		await physics_frame
		frames += 1
	var captured := bubble.capture_count >= 1
	var released_frames := 0
	while released_frames < 400 and bubble.release_count == 0:
		await physics_frame
		released_frames += 1
	await physics_frame
	_check(
		(
			captured
			and bubble.release_count >= 1
			and not _victim().lifecycle.is_terminal()
			and _outcome(entry).is_empty()
		),
		(
			"%s: Bula captures P2 and releases it (%d / %d) with no elimination or credit"
			% [entry[0], bubble.capture_count, bubble.release_count]
		)
	)
	await _close()


# --- Kaing and Tulay: standable terrain ---------------------------------------------------


func _test_terrain(entry: Array, variant_key: String) -> void:
	var cells := {KAING: Vector2i(10, 12), TULAY: Vector2i(16, 10)}
	var name := variant_key.get_slice(".", 1)
	await _open(3, entry)
	var edits: Array[Dictionary] = [_edit(OWNER, variant_key, cells[variant_key])]
	_to_play(edits)
	var piece := _piece()
	if piece == null:
		_check(false, "%s: %s is placed" % [entry[0], name])
		await _close()
		return
	var top := piece.footprint_world_rect()
	var surface_id := str(room.items.pieces.keys()[0])
	var surface := room.items.support_tracker.surfaces.get(surface_id) as SupportSurfaceMetadata
	_hold(Vector2(top.get_center().x, top.position.y - room.tuning.body_height_wu * 0.5 - 8.0))
	for _frame in range(60):
		await physics_frame
	var feet := _victim().global_position.y + room.tuning.body_height_wu * 0.5
	_check(
		(
			_victim().is_on_floor()
			and absf(feet - top.position.y) <= 2.0
			and not _victim().lifecycle.is_terminal()
			and _outcome(entry).is_empty()
			and surface != null
			and (
				(surface as SupportSurfaceMetadata).wave_support_eligibility
				== SupportSurfaceMetadata.Eligibility.ELIGIBLE
			)
		),
		(
			"%s: %s is standable, wave-support eligible terrain that never eliminates (feet %.1f)"
			% [entry[0], name, feet]
		)
	)
	await _close()


# --- Walis: a Place-only edit -------------------------------------------------------------


func _test_walis() -> void:
	var entry: Array = ENTRIES[0]
	await _open(3, entry)
	var first: Array[Dictionary] = [_edit(VICTIM, KAING_1, Vector2i(10, 8))]
	_to_play(first)
	var controller := room.race_round_controller
	controller.hard_cap_seconds = 0.002
	var empty: Array[Dictionary] = []
	var step := controller.advance_step(0.01, Engine.get_physics_frames(), empty)
	room._apply_race_outcomes(step.new_outcomes)
	room._finish_race(str(step.end_reason))
	room._start_next_round()
	var before := room.items.pieces.size()
	var second: Array[Dictionary] = [_edit(OWNER, WALIS, Vector2i(9, 7))]
	var playing := _to_play(second)
	_check(
		before == 1 and playing and room.items.pieces.is_empty() and _eliminations_recorded() == 0,
		"Karera: Walis clears P2's earlier Kaing in Place, leaves no Play piece and no credit"
	)
	await _close()

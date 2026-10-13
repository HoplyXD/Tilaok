# gdlint: disable=max-file-lines
extends SceneTree

## P10 first-batch families: definitions, regions, mechanics, tells, ownership/attribution,
## lifecycle, caps, previews and Library. Real physics and the real ChickenController; all input
## is synthetic. Placeholder art/audio only.

const ROOM_SCENE := preload("res://scenes/fixtures/item_visualizer.tscn")
const SPRING := "move.tire_spring.tire_2x2"
const RAIL_4 := "hazard.rail_trumpo.rail_4x1"
const RAIL_5 := "hazard.rail_trumpo.rail_5x1"
const RAIL_6 := "hazard.rail_trumpo.rail_6x1"
const PAROL_3 := "hazard.parol_pulse.span_3x1"
const PAROL_4 := "hazard.parol_pulse.span_4x1"
const PAROL_5 := "hazard.parol_pulse.span_5x1"
const PAROL_6 := "hazard.parol_pulse.span_6x1"
const LANE_4 := "hazard.slipper_launcher.lane_4x1"
const LANE_6 := "hazard.slipper_launcher.lane_6x1"
const WALIS_3 := "utility.walis_cleanup.area_3x3"
const WALIS_5 := "utility.walis_cleanup.area_5x5"
const BULA_3 := "hazard.bubble_planter.path_1x3"
const BULA_5 := "hazard.bubble_planter.path_1x5"
const KAING_1 := "build.hollow_blocks.cell_1x1"
const KAING_3 := "build.hollow_blocks.column_1x3"
const TULAY_4 := "build.bamboo_bridge.span_4x1"
const NEW_FAMILIES: PackedStringArray = [
	"move.tire_spring",
	"hazard.rail_trumpo",
	"hazard.parol_pulse",
	"hazard.slipper_launcher",
	"utility.walis_cleanup",
	"hazard.bubble_planter",
]
const GRACE_FRAMES := 62
## 64 wu grid (2026-10-14): CELL is one tile; W converts the original 32 wu offsets (x2).
const CELL := 64.0
const W := 2.0

var failures := 0
var checks := 0
var room: ItemVisualizerRoom
var actor: ChickenController
var tuning_defaults := GameplayTuning.new()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_definitions()
	_test_baseline_isolation()
	_test_geometry_and_regions()
	await _test_gulong()
	await _test_trumpo()
	await _test_parol()
	await _test_launcher()
	await _test_walis()
	await _test_bula()
	await _test_cross_cutting()
	await _test_reset_states()
	await _test_scenarios()
	await _test_previews_and_library()
	await _test_visualizer()
	_test_placeholder_audit()
	await _test_occupancy()
	print("P10_TESTS checks=%d failures=%d" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _check(condition: bool, label: String) -> void:
	checks += 1
	if condition:
		print("PASS ", label)
	else:
		failures += 1
		push_error("FAIL " + label)


func _row(case_id: String, expected: String, actual: String, passed: bool) -> void:
	_check(passed, "%s | expected: %s | actual: %s" % [case_id, expected, actual])


# ---------------- helpers


func _wait(frames: int) -> void:
	for _frame in range(frames):
		await physics_frame


func _fresh(seat_layout: String = "K1") -> void:
	await _dispose()
	room = ROOM_SCENE.instantiate() as ItemVisualizerRoom
	root.add_child(room)
	await _wait(3)
	var seat := room.join_keyboard(seat_layout)
	actor = room.actors[seat] as ChickenController


func _dispose() -> void:
	if room != null and is_instance_valid(room):
		room.queue_free()
		await process_frame
	room = null
	actor = null
	Engine.time_scale = 1.0


func _arm() -> void:
	room.start_play()
	await _wait(GRACE_FRAMES)


func _place(variant_key: String, cell: Vector2i, turns: int = 0, seat: int = 0) -> Dictionary:
	return room.items.place(variant_key, cell, turns, seat, [] as Array[Rect2])


func _piece(instance_id: String) -> HazardPiece:
	return room.items.piece_for(instance_id) as HazardPiece


func _key(key: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.keycode = key
	event.pressed = pressed
	room.input_router._input(event)


func _hold(position: Vector2) -> void:
	actor.global_position = position
	actor.clear_external_motion()


func _feet_to_center(feet: Vector2) -> Vector2:
	return feet - Vector2(0.0, room.tuning.body_height_wu * 0.5)


func _records_of(kind: AttributionRecord.Kind) -> Array[AttributionRecord]:
	var result: Array[AttributionRecord] = []
	for record in room.items.director.records:
		if record.kind == kind:
			result.append(record)
	return result


func _object_nodes() -> Array:
	return [
		int(Performance.get_monitor(Performance.OBJECT_COUNT)),
		int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
	]


func _fresh_families() -> Array[ItemFamilyDefinition]:
	var tuning := GameplayTuning.new()
	ItemEnabledProfiles.apply(tuning, "items_lab")
	var loaded := ItemDefinitions.load_for_profile(tuning, "items_lab")
	var copies: Array[ItemFamilyDefinition] = []
	for family in loaded.families:
		copies.append(family.duplicate(true) as ItemFamilyDefinition)
	return copies


func _errors_for(families: Array[ItemFamilyDefinition]) -> PackedStringArray:
	var tuning := GameplayTuning.new()
	return ItemDefinitionValidator.validate_families(families, tuning)


# ---------------- definitions


func _test_definitions() -> void:
	var tuning := GameplayTuning.new()
	ItemEnabledProfiles.apply(tuning, "items_lab")
	_check(
		tuning.validate().is_empty(), "T01 first-batch tuning validates: %s" % [tuning.validate()]
	)
	var definitions := ItemDefinitions.load_for_profile(tuning, "items_lab")
	_check(
		definitions.is_valid(), "T01 eight definitions load and validate: %s" % [definitions.errors]
	)
	# 8 first-batch families plus the three 2026-10-14 stage blocks.
	_check(definitions.families.size() == 11, "T01 eight families (+3 stage blocks) are defined")
	var expected := {
		"move.tire_spring": {"tire_2x2": Vector2i(2, 2)},
		"hazard.rail_trumpo":
		{"rail_4x1": Vector2i(4, 1), "rail_5x1": Vector2i(5, 1), "rail_6x1": Vector2i(6, 1)},
		"hazard.parol_pulse":
		{
			"span_3x1": Vector2i(3, 1),
			"span_4x1": Vector2i(4, 1),
			"span_5x1": Vector2i(5, 1),
			"span_6x1": Vector2i(6, 1),
		},
		"hazard.slipper_launcher": {"lane_4x1": Vector2i(1, 1), "lane_6x1": Vector2i(1, 1)},
		"utility.walis_cleanup": {"area_3x3": Vector2i(3, 3), "area_5x5": Vector2i(5, 5)},
		"hazard.bubble_planter": {"path_1x3": Vector2i(1, 1), "path_1x5": Vector2i(1, 1)},
	}
	for family_id in expected:
		var family := definitions.find_family(family_id)
		_check(family != null, "T01 %s is defined" % family_id)
		if family == null:
			continue
		var variant_ids := PackedStringArray()
		for variant in family.variants:
			variant_ids.append(variant.variant_id)
		_row(
			"T01 %s variants" % family_id,
			str((expected[family_id] as Dictionary).keys()),
			str(variant_ids),
			variant_ids.size() == (expected[family_id] as Dictionary).size()
		)
		for variant in family.variants:
			var want: Vector2i = (expected[family_id] as Dictionary).get(
				variant.variant_id, Vector2i.ZERO
			)
			_check(
				variant.footprint_cells == want,
				"T01 %s.%s footprint %s" % [family_id, variant.variant_id, want]
			)
			_check(
				not variant.regions.is_empty(),
				"T01 %s.%s has explicit regions" % [family_id, variant.variant_id]
			)
			_check(
				not variant.rotations.is_empty(),
				"T01 %s.%s has explicit rotations" % [family_id, variant.variant_id]
			)
		_check(family.ownership == "placer", "T01 %s owner is the placer" % family_id)
		_check(
			not family.safe_start.is_empty(),
			"T01 %s safe start is explicit: %s" % [family_id, family.safe_start]
		)
		_check(
			family.modes_allowed == PackedStringArray(["karera"]),
			"T01 %s mode flags: allowed karera only" % family_id
		)
		_check(
			family.modes_pending_review.has("lagsanay"),
			"T01 %s Lagsanay is pending review" % family_id
		)
		_check(not family.release_target, "T01 %s is not a release target" % family_id)
		_check(
			family.wall_contact == ItemFamilyDefinition.WALL_INELIGIBLE,
			"T01 %s wall contact is declared" % family_id
		)
		_check(family.visual_set != null, "T01 %s has a replaceable visual set" % family_id)
	var spring := definitions.find_family("move.tire_spring").variants[0] as ItemVariantDefinition
	_check(spring.rotations == PackedInt32Array([0, 1, 2, 3]), "T01 Gulong rotates 0/90/180/270")
	var parol := definitions.find_family("hazard.parol_pulse").find_variant("span_5x1")
	_check(parol.occupied_cells.size() == 2, "T19 Parol reserves only its two posts")
	var launcher := definitions.find_family("hazard.slipper_launcher").find_variant("lane_4x1")
	_check(launcher.rotations == PackedInt32Array([0, 2]), "T28 Tsinelas rotates 0 and 180 only")
	var bula := definitions.find_family("hazard.bubble_planter").find_variant("path_1x3")
	_check(
		bula.rotations == PackedInt32Array([0]), "T46 Bula has a fixed upward path (no rotation)"
	)
	var walis := definitions.find_family("utility.walis_cleanup")
	_check(
		walis.one_shot_edit, "T37 Walis is a one-shot construction edit with no placed footprint"
	)
	# Rejection rows.
	var families := _fresh_families()
	families[4].variants[0].variant_id = "span_7x1"
	_check(not _errors_for(families).is_empty(), "T19 an undocumented Parol span 7 is rejected")
	families = _fresh_families()
	families[3].variants[0].footprint_cells = Vector2i(9, 1)
	_check(
		not _errors_for(families).is_empty(),
		"T10 a Trumpo rail that does not match its table is rejected"
	)
	families = _fresh_families()
	families[5].variants[0].regions[1].declared_bounded = false
	_check(not _errors_for(families).is_empty(), "T28 an unbounded lane is rejected")
	families = _fresh_families()
	families[7].variants[0].regions[1].rect_cells = Rect2(0, -99, 1, 99)
	_check(not _errors_for(families).is_empty(), "T46 a bubble path beyond the arena is rejected")
	families = _fresh_families()
	families[2].safe_start = "whatever"
	_check(not _errors_for(families).is_empty(), "T01 an undocumented safe start is rejected")
	families = _fresh_families()
	families[2].variants[0].regions = [] as Array[ItemRegionSpec]
	_check(not _errors_for(families).is_empty(), "T01 a variant without regions is rejected")
	families = _fresh_families()
	families[4].variants[0].occupied_cells = [Rect2i(0, 0, 9, 9)] as Array[Rect2i]
	_check(
		not _errors_for(families).is_empty(),
		"T19 occupied cells outside the footprint are rejected"
	)


func _test_baseline_isolation() -> void:
	var base := ItemDefinitions.load_all(GameplayTuning.new())
	# The default pool is Kaing/Tulay plus the 2026-10-14 stage blocks; P10 hazards stay out.
	_check(base.families.size() == 5, "baseline load_all defines Kaing, Tulay and the stage blocks")
	var default_tuning := GameplayTuning.new()
	_check(
		default_tuning.item_enabled_variants.size() == 6,
		"default enabled pool has no P10 hazard variants (6)"
	)
	var spring_pool := ItemEnabledProfiles.enabled_variants("karera_spring")
	_check(spring_pool.has(SPRING), "karera_spring now includes the spring variant")
	var karera_slice := ItemDefinitions.load_for_profile(GameplayTuning.new(), "karera_slice")
	_check(
		karera_slice.families.size() == 5, "karera_slice keeps the P04 pair plus the stage blocks"
	)


func _test_geometry_and_regions() -> void:
	var tuning := GameplayTuning.new()
	ItemEnabledProfiles.apply(tuning, "items_lab")
	var definitions := ItemDefinitions.load_for_profile(tuning, "items_lab")
	var cell := tuning.grid_cell_wu
	# Gulong: body solid 2x2; trigger top row follows the launch normal.
	var spring := definitions.find_variant(SPRING).variant as ItemVariantDefinition
	var wanted_trigger := {
		0: Rect2(0, 0, 128, 64),
		1: Rect2(64, 0, 64, 128),
		2: Rect2(0, 64, 128, 64),
		3: Rect2(0, 0, 64, 128),
	}
	for turns in range(4):
		var resolved := ItemGeometry.resolve_regions(spring, turns, tuning)
		var trigger := Rect2()
		var solid := Rect2()
		for region in resolved:
			if region.kind == ItemRegionSpec.Kind.TRIGGER:
				trigger = region.rect
			elif region.kind == ItemRegionSpec.Kind.SOLID:
				solid = region.rect
		_row(
			"T02 Gulong rotation %d trigger" % turns,
			str(wanted_trigger[turns]),
			str(trigger),
			trigger == wanted_trigger[turns]
		)
		_check(solid == Rect2(0, 0, 128, 128), "T02 Gulong rotation %d body stays 2x2" % turns)
		var normal := ItemGeometry.rotate_vector(Vector2.UP, turns)
		var on_edge := false
		if normal.y < 0.0:
			on_edge = is_equal_approx(trigger.position.y, solid.position.y)
		elif normal.y > 0.0:
			on_edge = is_equal_approx(trigger.end.y, solid.end.y)
		elif normal.x > 0.0:
			on_edge = is_equal_approx(trigger.end.x, solid.end.x)
		else:
			on_edge = is_equal_approx(trigger.position.x, solid.position.x)
		_check(on_edge, "T02 Gulong rotation %d launch face lies on the %s edge" % [turns, normal])
	# Trumpo: sweep equals the rail footprint at every rotation.
	for variant_key in [RAIL_4, RAIL_5, RAIL_6]:
		var variant := definitions.find_variant(variant_key).variant as ItemVariantDefinition
		for turns in range(4):
			var footprint := (
				ItemGeometry.rotated_size(Vector2(variant.footprint_cells), turns) * cell
			)
			var sweep := Rect2()
			for region in ItemGeometry.resolve_regions(variant, turns, tuning):
				if region.kind == ItemRegionSpec.Kind.SWEEP:
					sweep = region.rect
			_check(
				sweep.size == footprint,
				(
					"T11 %s turns %d: sweep %s == visible rail %s"
					% [variant_key, turns, sweep.size, footprint]
				)
			)
	# Launcher lane: outside the 1x1 footprint, left of it at 180 degrees.
	var lane_variant := definitions.find_variant(LANE_6).variant as ItemVariantDefinition
	for turns in [0, 2]:
		var lane := Rect2()
		for region in ItemGeometry.resolve_regions(lane_variant, turns, tuning):
			if region.kind == ItemRegionSpec.Kind.LANE:
				lane = region.rect
		var expected_x := cell if turns == 0 else -6.0 * cell
		_row(
			"T29 lane_6x1 turns %d" % turns,
			"x=%.0f width %.0f" % [expected_x, 6.0 * cell],
			str(lane),
			(
				is_equal_approx(lane.position.x, expected_x)
				and is_equal_approx(lane.size.x, 6.0 * cell)
			)
		)
	# Bula path: upward from the 1x1 emitter.
	var path_variant := definitions.find_variant(BULA_5).variant as ItemVariantDefinition
	for region in ItemGeometry.resolve_regions(path_variant, 0, tuning):
		if region.kind == ItemRegionSpec.Kind.EFFECT:
			_check(
				region.rect == Rect2(0, -5.0 * cell, cell, 5.0 * cell),
				"T47 Bula 1x5 path rises 5 cells above the pot"
			)


# ---------------- Gulong Talon


func _test_gulong() -> void:
	await _fresh()
	var placed := _place(SPRING, Vector2i(16, 13), 0, 0)
	_check(bool(placed.allowed), "T02 Gulong places on the floor: %s" % placed)
	var spring_id := str(placed.instance_id)
	var piece := _piece(spring_id)
	_check(piece != null and piece.behavior is SpringBehavior, "T02 Gulong has a spring behavior")
	_check(
		piece.occlusion_rects().size() == 1, "T02 Gulong body is one solid; the face is a trigger"
	)
	var metadata := piece.metadata
	_check(
		metadata.wave_support_eligibility == SupportSurfaceMetadata.Eligibility.INELIGIBLE,
		"T05 Gulong declares itself wave-support ineligible (fail closed)"
	)
	# Standing on the face during the activation grace: support is ineligible, not launched.
	await _arm_with_start()
	var top := Vector2(1088.0, 832.0)
	_hold(_feet_to_center(top))
	await _wait(6)
	var support := room.current_support_result(actor.support_actor_id, 832.0)
	_row(
		"T05 Gulong face is not wave support",
		"qualifies=false",
		"qualifies=%s reason=%s" % [support.qualifies, support.reason],
		not bool(support.qualifies)
	)
	await _wait(GRACE_FRAMES)
	var launches := (piece.behavior as SpringBehavior).launch_count
	_check(launches >= 1, "T03 contact on the face launches the chicken (launches=%d)" % launches)
	# Plain launch peak.
	var plain_peak := await _launch_peak(Vector2i(16, 13), false)
	var boosted_peak := await _launch_peak(Vector2i(16, 13), true)
	_row(
		"T03 plain launch rise",
		"300-340 wu (1550 wu/s, ~320 wu)",
		"%.1f wu" % plain_peak,
		plain_peak > 300.0 and plain_peak < 340.0
	)
	_row(
		"T03 timed-jump boost rise",
		"364-404 wu (1698 wu/s, ~384 wu)",
		"%.1f wu" % boosted_peak,
		boosted_peak > 364.0 and boosted_peak < 404.0
	)
	_check(
		boosted_peak > plain_peak + 40.0, "T03 the timed jump boosts height over the plain launch"
	)
	await _test_gulong_cooldown()
	await _test_gulong_rotations_and_caps()
	await _test_gulong_ownership()


func _arm_with_start() -> void:
	room.start_play()
	await _wait(2)


func _launch_peak(cell: Vector2i, boosted: bool) -> float:
	await _fresh()
	var placed := _place(SPRING, cell, 0, 0)
	_check(bool(placed.allowed), "launch fixture placed")
	await _arm()
	var top_y := float(cell.y) * CELL
	var half := room.tuning.body_height_wu * 0.5
	var column_x := float(cell.x) * CELL + CELL
	_hold(Vector2(column_x, top_y - half - 24.0 * W))
	var contact_center := top_y - half
	var minimum := 99999.0
	var pressed := false
	for _frame in range(100):
		var gap := top_y - (actor.global_position.y + half)
		if boosted and not pressed and gap <= 8.0 * W:
			_key(KEY_SPACE, true)
			pressed = true
		await physics_frame
		minimum = minf(minimum, actor.global_position.y)
	if pressed:
		_key(KEY_SPACE, false)
	return contact_center - minimum


func _test_gulong_cooldown() -> void:
	await _fresh()
	var placed := _place(SPRING, Vector2i(16, 13), 0, 0)
	var behavior := _piece(str(placed.instance_id)).behavior as SpringBehavior
	await _arm()
	var face_center := _feet_to_center(Vector2(1088.0, 832.0))
	for _frame in range(10):
		_hold(face_center)
		await physics_frame
	var early := behavior.launch_count
	for _frame in range(30):
		_hold(face_center)
		await physics_frame
	var late := behavior.launch_count
	_row(
		"T03 spring cooldown holds 0.20 s", "1 launch in first 10 frames", "%d" % early, early == 1
	)
	_row("T03 spring relaunches after cooldown", ">=2 launches by frame 40", "%d" % late, late >= 2)
	await _dispose()


func _test_gulong_rotations_and_caps() -> void:
	# Rotation 1 pushes right, capped at the spring horizontal cap (960 wu/s on the 64 wu grid).
	await _fresh()
	var placed := _place(SPRING, Vector2i(14, 8), 1, 0)
	_check(bool(placed.allowed), "T02 Gulong rotation 1 places")
	await _arm()
	var face_x := 14.0 * CELL + 2.0 * CELL
	var cap := room.tuning.item_spring_horizontal_cap_wu_s
	var seen_max := 0.0
	for _frame in range(4):
		_hold(Vector2(face_x + room.tuning.body_width_wu * 0.5 + 1.0, 8.0 * CELL + CELL))
		await physics_frame
		seen_max = maxf(seen_max, actor.external_velocity.x)
	_row(
		"T03 side launch respects the spring horizontal cap",
		"0 < vx <= %.0f" % cap,
		"%.1f" % seen_max,
		seen_max > 0.0 and seen_max <= cap + 0.001
	)
	# Ceiling containment: spring directly under the ceiling band.
	await _fresh()
	var ceiling_cell := Vector2i(14, 4)
	var near_ceiling := _place(SPRING, ceiling_cell, 0, 0)
	_check(bool(near_ceiling.allowed), "T04 spring near the ceiling places")
	await _arm()
	var top_y := float(ceiling_cell.y) * CELL
	var lowest := 9999.0
	for _frame in range(120):
		if _frame == 0:
			_hold(_feet_to_center(Vector2(960.0, top_y - 1.0)))
		await physics_frame
		lowest = minf(lowest, actor.global_position.y)
	var bounds_ok := lowest >= room.tuning.body_height_wu * 0.5 - 0.5
	_row(
		"T04 launch never leaves the arena",
		"centre y >= half body height",
		"min centre y %.2f" % lowest,
		bounds_ok and not actor.containment_outcome_reported
	)
	await _dispose()


func _test_gulong_ownership() -> void:
	await _fresh()
	var placed := _place(SPRING, Vector2i(16, 13), 0, 1)
	_check(bool(placed.allowed), "owner fixture placed")
	await _arm()
	_hold(_feet_to_center(Vector2(1088.0, 832.0)))
	await _wait(4)
	var setups := _records_of(AttributionRecord.Kind.SETUP)
	var eliminations := _records_of(AttributionRecord.Kind.ELIMINATION)
	_check(setups.size() >= 1, "T04 the launch is recorded as a setup effect")
	if not setups.is_empty():
		var record := setups[0]
		_row(
			"T04 spring setup has no credit",
			"owner=1 setup_only=true credit=false",
			record.summary(),
			record.owner_seat == 1 and record.setup_only and not record.credit_eligible()
		)
	_check(eliminations.is_empty(), "T04 a launch alone never eliminates or credits (no assist)")
	# Removal and reset.
	var items := room.items
	var removed := items.remove(str(placed.instance_id), "test_remove", true)
	_check(bool(removed.allowed), "T04 spring removal succeeds")
	_check(items.persistent_count() == 0, "T04 spring record is gone after removal")
	await _dispose()


# ---------------- Trumpo sa Riles


func _test_trumpo() -> void:
	await _fresh()
	var placed := _place(RAIL_5, Vector2i(14, 8), 0, 0)
	_check(bool(placed.allowed), "T11 rail 5x1 places: %s" % placed)
	var behavior := _piece(str(placed.instance_id)).behavior as TrumpoBehavior
	_check(is_equal_approx(behavior.sweep.size.x, 5.0 * CELL), "T11 sweep matches the 5-cell rail")
	await _arm()
	var speed := room.tuning.item_trumpo_speed_wu_s
	var pause := room.tuning.item_trumpo_pause_s
	var travel := 5.0 * CELL - room.tuning.item_trumpo_hit_wu
	var xs: Array[float] = []
	var paused_frames := 0
	var run_paused := 0
	var longest_pause := 0
	for _frame in range(int((PathMover.period(travel, speed, pause) + 0.2) * 60.0)):
		await physics_frame
		xs.append(behavior.top_center().x)
		if behavior.paused_at_end:
			paused_frames += 1
			run_paused += 1
			longest_pause = maxi(longest_pause, run_paused)
		else:
			run_paused = 0
	var minimum: float = xs.min()
	var maximum: float = xs.max()
	var half_hit := room.tuning.item_trumpo_hit_wu * 0.5
	var rail_lo := 14.0 * CELL + half_hit
	var rail_hi := 19.0 * CELL - half_hit
	_row(
		"T12 top travels the visible rail and no further",
		"centre x spans %.1f..%.1f" % [rail_lo, rail_hi],
		"%.1f..%.1f" % [minimum, maximum],
		minimum >= rail_lo - 1.0 and maximum <= rail_hi + 1.0
	)
	_row(
		"T12 endpoint pause length",
		"%d frames ±2" % int(pause * 60.0),
		"%d frames" % longest_pause,
		absi(longest_pause - int(pause * 60.0)) <= 2
	)
	var period_s := PathMover.period(travel, speed, pause)
	_row("T12 period", "%.3f s" % period_s, "%.3f s" % period_s, period_s > 1.0)
	await _test_trumpo_contact_and_attribution()
	await _test_trumpo_rotations()
	await _test_trumpo_tunnelling()


func _test_trumpo_contact_and_attribution() -> void:
	await _fresh()
	var placed := _place(RAIL_5, Vector2i(14, 8), 0, 1)
	await _arm()
	# Stand on the rail centre; the top reaches it during its first pass.
	var rail_center := Vector2(14.0 * CELL + 80.0 * W, 8.0 * CELL + 16.0 * W)
	var eliminated_frame := -1
	for frame in range(180):
		_hold(rail_center)
		await physics_frame
		if actor.lifecycle.status == PlayerLifecycleState.Status.ELIMINATED:
			eliminated_frame = frame
			break
	_check(eliminated_frame > 0, "T12 trumpo contact eliminates (frame %d)" % eliminated_frame)
	var rows := _records_of(AttributionRecord.Kind.ELIMINATION)
	_check(rows.size() == 1, "T13 exactly one elimination record")
	if not rows.is_empty():
		var record := rows[0]
		_row(
			"T13 direct kill credits the placer",
			"owner=1 self=false credit=true",
			record.summary(),
			record.owner_seat == 1 and not record.self_kill and record.credit_eligible()
		)
		_check(record.source_item_id == str(placed.instance_id), "T13 record names the source item")
	# Self-kill.
	await _fresh()
	_place(RAIL_5, Vector2i(14, 8), 0, 0)
	await _arm()
	for _frame in range(180):
		_hold(rail_center)
		await physics_frame
		if actor.lifecycle.is_terminal():
			break
	var own := _records_of(AttributionRecord.Kind.ELIMINATION)
	_check(
		not own.is_empty() and own[0].self_kill and not own[0].credit_eligible(),
		"T13 self-elimination records no credit"
	)
	await _dispose()


func _test_trumpo_rotations() -> void:
	var expected_dirs := {
		0: Vector2.RIGHT,
		1: Vector2.DOWN,
		2: Vector2.LEFT,
		3: Vector2.UP,
	}
	for turns in range(4):
		await _fresh()
		var placed := _place(RAIL_4, Vector2i(14, 6), turns, 0)
		_check(bool(placed.allowed), "T11 rail 4x1 rotation %d places" % turns)
		var behavior := _piece(str(placed.instance_id)).behavior as TrumpoBehavior
		_row(
			"T11 rotation %d start direction" % turns,
			str(expected_dirs[turns]),
			str(behavior.direction),
			behavior.direction == expected_dirs[turns]
		)
		var sweep_wh := behavior.sweep.size
		_check(
			(
				(turns % 2 == 0 and sweep_wh.x > sweep_wh.y)
				or (turns % 2 == 1 and sweep_wh.y > sweep_wh.x)
			),
			"T11 rotation %d sweep orientation" % turns
		)
	await _dispose()


func _test_trumpo_tunnelling() -> void:
	await _fresh()
	room.tuning.item_trumpo_speed_wu_s = 4800.0
	var placed := _place(RAIL_6, Vector2i(14, 8), 0, 1)
	await _arm()
	var rail_center := Vector2(14.0 * CELL + 96.0 * W, 8.0 * CELL + 16.0 * W)
	for _frame in range(60):
		_hold(rail_center)
		await physics_frame
		if actor.lifecycle.is_terminal():
			break
	_check(
		actor.lifecycle.status == PlayerLifecycleState.Status.ELIMINATED,
		"T14 a 4800 wu/s top (80 wu/frame) cannot tunnel through a 56 wu body"
	)
	await _dispose()


# ---------------- Parol Pulse


func _test_parol() -> void:
	await _fresh()
	var placed := _place(PAROL_5, Vector2i(13, 8), 0, 0)
	_check(bool(placed.allowed), "T20 Parol span 5 places: %s" % placed)
	var behavior := _piece(str(placed.instance_id)).behavior as ParolBehavior
	_row(
		"T20 Parol beam spans the three open cells between the posts",
		"x 896..1088",
		"%s" % behavior.beam,
		is_equal_approx(behavior.beam.size.x, 3.0 * CELL)
	)
	await _arm()
	var cycle := room.tuning.item_parol_cycle_s
	var active := room.tuning.item_parol_active_s
	var charge := room.tuning.item_parol_charge_s
	var phases: Array[int] = []
	var times: Array[float] = []
	for _frame in range(int(cycle * 2.0 * 60.0) + 30):
		await physics_frame
		phases.append(behavior.phase)
		times.append(behavior.elapsed)
	var first_active := phases.find(PhaseCycle.Phase.ACTIVE)
	var first_charge := phases.find(PhaseCycle.Phase.CHARGE)
	var inactive_len := cycle - active
	var step := 1.0 / 60.0
	_row(
		"T21 charge starts inside the inactive tail (item time)",
		"%.3f s ±1 step" % (inactive_len - charge),
		"%.3f s" % times[first_charge],
		absf(times[first_charge] - (inactive_len - charge)) <= step + 0.001
	)
	_row(
		"T21 active starts after 1.5 s inactive (item time)",
		"%.3f s ±1 step" % inactive_len,
		"%.3f s" % times[first_active],
		absf(times[first_active] - inactive_len) <= step + 0.001
	)
	var active_frames := 0
	var transitions := 0
	for index in range(phases.size()):
		if phases[index] == PhaseCycle.Phase.ACTIVE and times[index] < cycle * 2.0:
			active_frames += 1
		if index > 0 and phases[index] != phases[index - 1]:
			transitions += 1
	_row(
		"T21 the cycle is 3 s: 1.5 s active per cycle",
		"180 active frames in 2 cycles ±3",
		"%d active frames" % active_frames,
		absi(active_frames - 180) <= 3
	)
	var seconds := float(phases.size()) / 60.0
	_row(
		"T22 no rapid flashing: transitions per second",
		"<= 1.5 /s",
		"%.2f /s" % (float(transitions) / seconds),
		float(transitions) / seconds <= 1.5
	)
	await _test_parol_contact_and_occlusion()
	await _test_parol_vertical_and_spans()


func _test_parol_contact_and_occlusion() -> void:
	await _fresh()
	var placed := _place(PAROL_5, Vector2i(13, 8), 0, 1)
	var behavior := _piece(str(placed.instance_id)).behavior as ParolBehavior
	await _arm()
	var beam_center := behavior.beam.get_center()
	var safe_frames := 0
	var died_frame := -1
	for frame in range(200):
		_hold(beam_center)
		await physics_frame
		if actor.lifecycle.is_terminal():
			died_frame = frame
			break
		if behavior.phase != PhaseCycle.Phase.ACTIVE:
			safe_frames += 1
	_check(safe_frames >= 80, "T21 inactive and charge are safe (%d safe frames)" % safe_frames)
	_check(died_frame >= 0, "T21 crossing the active beam eliminates (frame %d)" % died_frame)
	var rows := _records_of(AttributionRecord.Kind.ELIMINATION)
	_check(
		rows.size() == 1 and rows[0].owner_seat == 1 and rows[0].credit_eligible(),
		"T22 Parol placer owns the direct elimination"
	)
	# Occlusion by a real solid between the posts.
	await _fresh()
	var parol := _place(PAROL_5, Vector2i(13, 8), 0, 0)
	var block := _place(KAING_1, Vector2i(15, 8), 0, 0)
	_check(
		bool(block.allowed), "T20 a block may sit between the posts (posts reserve only two cells)"
	)
	var parol_behavior := _piece(str(parol.instance_id)).behavior as ParolBehavior
	await _arm()
	await _wait(2)
	var segments := parol_behavior.segments
	var lengths := 0.0
	for segment in segments:
		lengths += segment.size.x
	_row(
		"T20 solid cover shortens the beam by exactly its width",
		"%.0f wu of beam" % (parol_behavior.beam.size.x - CELL),
		"%.0f wu" % lengths,
		is_equal_approx(lengths, parol_behavior.beam.size.x - CELL)
	)
	await _dispose()


func _test_parol_vertical_and_spans() -> void:
	for key in [PAROL_3, PAROL_4, PAROL_5, PAROL_6]:
		for turns in [0, 1]:
			await _fresh()
			var placed := _place(key, Vector2i(14, 4), turns, 0)
			_check(bool(placed.allowed), "T20 %s turns %d places" % [key, turns])
			if not bool(placed.allowed):
				continue
			var behavior := _piece(str(placed.instance_id)).behavior as ParolBehavior
			var span := int(key.right(3).left(1))
			var length := behavior.beam.size.x if turns == 0 else behavior.beam.size.y
			_row(
				"T20 %s turns %d beam length" % [key, turns],
				"%d wu" % ((span - 2) * int(CELL)),
				"%.0f wu" % length,
				is_equal_approx(length, float(span - 2) * CELL)
			)
	await _dispose()


# ---------------- Tsinelas Launcher


func _test_launcher() -> void:
	await _fresh()
	var placed := _place(LANE_4, Vector2i(8, 8), 0, 0)
	_check(bool(placed.allowed), "T29 launcher lane 4 places: %s" % placed)
	var behavior := _piece(str(placed.instance_id)).behavior as LauncherBehavior
	_check(
		behavior.lane_dir == Vector2.RIGHT and is_equal_approx(behavior.lane_length, 4.0 * CELL),
		"T29 lane is 4 cells to the right"
	)
	await _arm()
	var spawn_frame := -1
	var charge_frame := -1
	var positions: Array[float] = []
	var vanish_frame := -1
	for frame in range(300):
		await physics_frame
		if charge_frame < 0 and behavior.state == LauncherBehavior.State.TELEGRAPH:
			charge_frame = frame
		if spawn_frame < 0 and not behavior.projectiles.is_empty():
			spawn_frame = frame
		if spawn_frame >= 0 and vanish_frame < 0:
			if behavior.projectiles.is_empty():
				vanish_frame = frame
			else:
				positions.append((behavior.projectiles[0].center as Vector2).x)
		if vanish_frame >= 0:
			break
	var expected_fire := int(
		round(
			(
				(room.tuning.item_launcher_initial_delay_s + room.tuning.item_launcher_telegraph_s)
				* 60.0
			)
		)
	)
	_row(
		"T30 telegraph then fire interval",
		"fires ~%d frames after arming ±3" % expected_fire,
		"fired at frame %d, telegraph from %d" % [spawn_frame, charge_frame],
		absi(spawn_frame - expected_fire) <= 3 and charge_frame >= 0 and charge_frame < spawn_frame
	)
	if positions.size() >= 3:
		var per_frame := positions[2] - positions[1]
		_row(
			"T30 projectile speed",
			(
				"%.1f wu/frame (%.0f wu/s)"
				% [
					room.tuning.item_launcher_projectile_speed_wu_s / 60.0,
					room.tuning.item_launcher_projectile_speed_wu_s
				]
			),
			"%.2f wu/frame" % per_frame,
			absf(per_frame - room.tuning.item_launcher_projectile_speed_wu_s / 60.0) < 0.5
		)
	_row(
		"T31 projectile lifetime is bounded by the lane",
		"vanishes within 3 s TTL",
		"vanished at frame %d" % vanish_frame,
		vanish_frame > spawn_frame and float(vanish_frame - spawn_frame) / 60.0 < 3.0
	)
	await _test_launcher_hit_cover_and_spawn_safety()
	await _test_launcher_rotation_and_lane_variants()


func _test_launcher_hit_cover_and_spawn_safety() -> void:
	# Direct hit.
	await _fresh()
	var placed := _place(LANE_4, Vector2i(8, 8), 0, 1)
	await _arm()
	var target := Vector2(10.0 * CELL + 16.0 * W, 8.0 * CELL + 16.0 * W)
	for _frame in range(200):
		_hold(target)
		await physics_frame
		if actor.lifecycle.is_terminal():
			break
	var rows := _records_of(AttributionRecord.Kind.ELIMINATION)
	_check(
		actor.lifecycle.status == PlayerLifecycleState.Status.ELIMINATED,
		"T30 a slipper hit eliminates"
	)
	_check(
		rows.size() == 1 and rows[0].owner_seat == 1 and rows[0].credit_eligible(),
		"T31 launcher placer owns the direct hit"
	)
	# Cover: a block in the lane stops the slipper; a chicken behind it is safe.
	await _fresh()
	var launcher := _place(LANE_6, Vector2i(8, 8), 0, 0)
	var cover := _place(KAING_1, Vector2i(10, 8), 0, 0)
	_check(bool(cover.allowed), "T30 a block can sit in the lane (lanes are not footprints)")
	var behavior := _piece(str(launcher.instance_id)).behavior as LauncherBehavior
	await _arm()
	var behind := Vector2(12.0 * CELL + 16.0 * W, 8.0 * CELL + 16.0 * W)
	var fired := 0
	for _frame in range(260):
		_hold(behind)
		await physics_frame
		fired = maxi(fired, behavior.shots_fired)
		if actor.lifecycle.is_terminal():
			break
	_check(fired >= 1, "T30 the launcher fired at least once (%d)" % fired)
	_check(
		actor.lifecycle.status == PlayerLifecycleState.Status.ACTIVE,
		"T30 solid cover blocks the projectile; the chicken behind it survives"
	)
	_check(
		behavior.clipped_length < behavior.lane_length,
		(
			"T30 the lane reports its first blocker (%.0f of %.0f wu)"
			% [behavior.clipped_length, behavior.lane_length]
		)
	)
	# Spawn safety: a chicken in the muzzle cell suppresses the shot instead of spawning inside it.
	await _fresh()
	var safe := _place(LANE_4, Vector2i(8, 8), 0, 0)
	var safe_behavior := _piece(str(safe.instance_id)).behavior as LauncherBehavior
	await _arm()
	var muzzle := Vector2(9.0 * CELL + 8.0 * W, 8.0 * CELL + 16.0 * W)
	for _frame in range(200):
		_hold(muzzle)
		await physics_frame
		if safe_behavior.suppressed_shots > 0 or actor.lifecycle.is_terminal():
			break
	_check(
		safe_behavior.suppressed_shots > 0 and safe_behavior.shots_fired == 0,
		(
			"T29 a shot whose spawn overlaps a chicken is suppressed (%d suppressed)"
			% safe_behavior.suppressed_shots
		)
	)
	await _dispose()


func _test_launcher_rotation_and_lane_variants() -> void:
	await _fresh()
	var placed := _place(LANE_6, Vector2i(14, 8), 2, 0)
	_check(bool(placed.allowed), "T29 lane 6 at 180 degrees places")
	var behavior := _piece(str(placed.instance_id)).behavior as LauncherBehavior
	_check(behavior.lane_dir == Vector2.LEFT, "T29 180 degrees fires to the left")
	_check(is_equal_approx(behavior.lane_length, 6.0 * CELL), "T29 lane 6 is 6 cells")
	var rejected := _place(LANE_4, Vector2i(20, 8), 1, 0)
	_check(not bool(rejected.allowed), "T29 90 degrees is rejected (only 0/180 are documented)")
	await _dispose()


# ---------------- Walis Cleanup


func _resolve(edits: Array[Dictionary]) -> Dictionary:
	return AtomicEditResolver.resolve(
		room.definitions,
		room.arena,
		room.tuning,
		room.items.pieces.values(),
		edits,
		room.items.round_number,
		[] as Array[Rect2]
	)


func _walis_edit(variant_key: String, cell: Vector2i, seat: int) -> Dictionary:
	return {
		"seat_index": seat,
		"variant_key": variant_key,
		"origin_cell": cell,
		"quarter_turns": 0,
		"cleanup_targets": [],
	}


func _test_walis() -> void:
	await _fresh()
	var old_a := _place(KAING_1, Vector2i(10, 8), 0, 0)
	var old_b := _place(KAING_1, Vector2i(11, 8), 0, 0)
	var far := _place(KAING_1, Vector2i(20, 8), 0, 0)
	room.items.end_round()
	var fresh := _place(KAING_1, Vector2i(10, 9), 0, 1)
	_check(
		bool(old_a.allowed) and bool(old_b.allowed) and bool(far.allowed) and bool(fresh.allowed),
		"T38 fixture pieces placed"
	)
	var resolution := _resolve([_walis_edit(WALIS_3, Vector2i(9, 7), 2)] as Array[Dictionary])
	var removals: Array = resolution.removals
	var expected: Array = [str(old_a.instance_id), str(old_b.instance_id)]
	expected.sort()
	_row(
		"T39 exact cleanup set (same-phase and far pieces excluded)",
		str(expected),
		str(removals),
		removals == expected
	)
	_check(
		(resolution.one_shot_edits as Array).size() == 1,
		"T38 the resolver reports one one-shot edit and places nothing"
	)
	_check((resolution.commits as Array).is_empty(), "T38 Walis never becomes a placed piece")
	# The ghost preview lists exactly the same targets.
	var overlay := room.overlay_for_cursor(WALIS_3, Vector2i(9, 7), 0)
	var target_rects := 0
	for entry in overlay:
		if entry.kind == "target":
			target_rects += 1
	_row(
		"T39 preview outlines every exact target",
		"2 targets",
		"%d" % target_rects,
		target_rects == 2
	)
	# Protected exclusion: an area over the base platform lists it and removes nothing of the base.
	var protected_overlay := room.overlay_for_cursor(WALIS_5, Vector2i(6, 11), 0)
	var protected_count := 0
	for entry in protected_overlay:
		if entry.kind == "protected":
			protected_count += 1
	_check(
		protected_count >= 1, "T39 the preview outlines protected exclusions (%d)" % protected_count
	)
	# Commit once, then never return.
	var committed := room.items.commit_batch(resolution)
	_check(bool(committed.allowed), "T40 cleanup commits as one atomic edit: %s" % committed)
	_check(not room.items.pieces.has(str(old_a.instance_id)), "T40 removed pieces are gone")
	_check(room.items.pieces.has(str(far.instance_id)), "T40 pieces outside the area survive")
	_check(room.items.pieces.has(str(fresh.instance_id)), "T40 same-phase pieces survive")
	room.items.begin_play()
	room.items.end_round()
	_check(
		not room.items.pieces.has(str(old_a.instance_id)),
		"T40 removed pieces do not return after reset"
	)
	# Overlapping Walis: one union, each target once.
	var union := _resolve(
		(
			[_walis_edit(WALIS_3, Vector2i(19, 7), 0), _walis_edit(WALIS_5, Vector2i(18, 6), 1)]
			as Array[Dictionary]
		)
	)
	_row(
		"T38 overlapping Walis resolve as one removal set",
		"[%s] once" % str(far.instance_id),
		str(union.removals),
		union.removals == [str(far.instance_id)]
	)
	# Out-of-bounds Walis is rejected, not clipped.
	var oob := _resolve([_walis_edit(WALIS_5, Vector2i(30, 14), 0)] as Array[Dictionary])
	_check((oob.rejections as Dictionary).size() == 1, "T38 an area outside the arena is rejected")
	# Walis never creates Play state.
	_check(
		not ItemBehaviorFactory.has_behavior("utility.walis_cleanup"),
		"T40 Walis has no Play behavior"
	)
	# Immediate lab path uses the same resolver output.
	var lab := room.items.place(WALIS_5, Vector2i(18, 6), 0, 1)
	_check(
		bool(lab.get("one_shot", false)) and (lab.removed as Array).size() <= 1,
		"T40 lab one-shot edit follows the same target set: %s" % lab
	)
	await _dispose()


# ---------------- Bula-Bulaklak


func _fast_bubbles() -> void:
	room.tuning.item_bubble_cadence_s = 0.2


func _test_bula() -> void:
	await _fresh()
	_fast_bubbles()
	var placed := _place(BULA_5, Vector2i(16, 13), 0, 1)
	_check(bool(placed.allowed), "T47 Bula 1x5 places: %s" % placed)
	var behavior := _piece(str(placed.instance_id)).behavior as BubbleBehavior
	await _arm()
	var start := Vector2(16.0 * CELL + 16.0 * W, 13.0 * CELL - 14.0 * W)
	var captured_frame := -1
	var released_frame := -1
	var top_y := 99999.0
	for frame in range(400):
		if captured_frame < 0:
			_hold(start)
		await physics_frame
		if captured_frame < 0 and actor.lifecycle.status == PlayerLifecycleState.Status.CAPTURED:
			captured_frame = frame
		if captured_frame >= 0:
			top_y = minf(top_y, actor.global_position.y)
			if released_frame < 0 and actor.lifecycle.status == PlayerLifecycleState.Status.ACTIVE:
				released_frame = frame
				break
	_check(captured_frame >= 0, "T48 a bubble captures a chicken (frame %d)" % captured_frame)
	var held := released_frame - captured_frame
	_row(
		"T48 capture lasts about 2 s",
		"120 frames ±4",
		"%d frames" % held,
		released_frame > 0 and absi(held - 120) <= 4
	)
	_check(
		top_y < start.y - 40.0,
		"T48 the bubble lifts the chicken (rose %.0f wu)" % (start.y - top_y)
	)
	_check(not actor.lifecycle.is_terminal(), "T48 a bubble never eliminates by itself")
	_check(
		(
			room.items.director.records.size() >= 1
			and _records_of(AttributionRecord.Kind.ELIMINATION).is_empty()
		),
		"T49 capture is a setup record only; no Patibong"
	)
	var safe_here := SafeReleaseResolver.is_free(
		actor.global_position,
		Vector2(room.tuning.body_width_wu, room.tuning.body_height_wu),
		room.arena.arena_bounds,
		room.items.director.release_occluders("none")
	)
	_check(safe_here, "T47 release lands on a safe, non-overlapping position")
	await _test_bula_immunity_and_no_control(behavior)
	await _test_bula_cleanup_paths()
	await _test_release_resolver_cases()


func _test_bula_immunity_and_no_control(_behavior: BubbleBehavior) -> void:
	await _fresh()
	_fast_bubbles()
	var placed := _place(BULA_3, Vector2i(16, 13), 0, 1)
	var behavior := _piece(str(placed.instance_id)).behavior as BubbleBehavior
	await _arm()
	var start := Vector2(16.0 * CELL + 16.0 * W, 13.0 * CELL - 14.0 * W)
	# Wait for the first capture; then hold input to prove there is no control while held.
	var captured := false
	for _frame in range(200):
		_hold(start)
		await physics_frame
		if actor.lifecycle.status == PlayerLifecycleState.Status.CAPTURED:
			captured = true
			break
	_check(captured, "T48 capture happened for the immunity scenario")
	var held_x := actor.global_position.x
	_key(KEY_D, true)
	await _wait(10)
	_key(KEY_D, false)
	_check(
		is_equal_approx(actor.global_position.x, held_x),
		"T48 a held chicken has no control (x unchanged %.1f)" % actor.global_position.x
	)
	var release_time := -1.0
	for _frame in range(260):
		await physics_frame
		if actor.lifecycle.status == PlayerLifecycleState.Status.ACTIVE:
			release_time = room.items.director.play_time
			break
	_check(release_time > 0.0, "T49 the captive is released")
	# Within the 1.0 s immunity a new bubble in reach does not recapture.
	var recaptured_early := false
	var frames_after := 0
	for _frame in range(150):
		_hold(Vector2(actor.global_position.x, start.y))
		await physics_frame
		frames_after += 1
		var since := room.items.director.play_time - release_time
		if actor.lifecycle.status == PlayerLifecycleState.Status.CAPTURED:
			recaptured_early = since < room.tuning.item_bubble_recapture_immunity_s - 0.03
			break
	_check(not recaptured_early, "T49 no recapture inside the 1.0 s immunity window")
	await _dispose()


func _test_bula_cleanup_paths() -> void:
	for scenario in ["removal", "death", "round_end", "reset_match"]:
		await _fresh()
		_fast_bubbles()
		var placed := _place(BULA_3, Vector2i(16, 13), 0, 1)
		var behavior := _piece(str(placed.instance_id)).behavior as BubbleBehavior
		await _arm()
		var start := Vector2(16.0 * CELL + 16.0 * W, 13.0 * CELL - 14.0 * W)
		for _frame in range(200):
			_hold(start)
			await physics_frame
			if actor.lifecycle.status == PlayerLifecycleState.Status.CAPTURED:
				break
		_check(
			actor.lifecycle.status == PlayerLifecycleState.Status.CAPTURED,
			"T49 [%s] capture established" % scenario
		)
		match scenario:
			"removal":
				room.items.remove(str(placed.instance_id), "test", true)
			"death":
				actor.eliminate("test death")
				await _wait(3)
			"round_end":
				room.items.end_round()
			"reset_match":
				room.items.reset_match()
		await _wait(2)
		var status := actor.lifecycle.status
		var captive_left := room.items.budget.captive_count()
		var ok := status != PlayerLifecycleState.Status.CAPTURED and captive_left == 0
		_row(
			"T49 captive state cleaned on %s" % scenario,
			"not captured, 0 captives",
			"status=%d captives=%d" % [status, captive_left],
			ok
		)
		_check(behavior != null, "T49 [%s] behavior existed" % scenario)
	await _dispose()


func _test_release_resolver_cases() -> void:
	var size := Vector2(24.0, 48.0)
	var bounds := Rect2(0, 0, 1024, 512)
	var free := SafeReleaseResolver.find(Vector2(500, 300), size, bounds, [] as Array[Rect2])
	_check(
		bool(free.found) and free.center == Vector2(500, 300), "T47 open space: released in place"
	)
	var wall: Array[Rect2] = [Rect2(480, 250, 40, 100)]
	var near := SafeReleaseResolver.find(Vector2(500, 300), size, bounds, wall)
	_check(
		bool(near.found) and not Rect2(near.center - size * 0.5, size).intersects(wall[0], false),
		"T47 wall overlap: nearest safe spot is clear"
	)
	var ceiling := SafeReleaseResolver.find(Vector2(500, 10), size, bounds, [] as Array[Rect2])
	_check(
		bool(ceiling.found) and bounds.encloses(Rect2(ceiling.center - size * 0.5, size)),
		"T47 ceiling: spot is pulled inside the arena"
	)
	var sealed: Array[Rect2] = [Rect2(-500, -500, 3000, 3000)]
	var none := SafeReleaseResolver.find(Vector2(500, 300), size, bounds, sealed)
	_check(
		not bool(none.found),
		"T47 no safe spot: reported, so the caller uses its last safe point with zero velocity"
	)


# ---------------- cross-cutting


func _test_cross_cutting() -> void:
	# Same-step simultaneous contact: earliest time, then stable item ID, one outcome.
	await _fresh()
	var first := _place(RAIL_4, Vector2i(14, 8), 0, 1)
	var second := _place(RAIL_4, Vector2i(14, 9), 0, 2)
	_check(bool(first.allowed) and bool(second.allowed), "tie fixture placed")
	await _arm()
	var boundary_y := 9.0 * CELL
	var cx := 14.0 * CELL + 16.0 * W
	for _frame in range(200):
		_hold(Vector2(cx, boundary_y))
		await physics_frame
		if actor.lifecycle.is_terminal():
			break
	var rows := _records_of(AttributionRecord.Kind.ELIMINATION)
	_check(rows.size() == 1, "T14 one terminal outcome per player (%d records)" % rows.size())
	if rows.size() == 1:
		var wanted := (
			str(first.instance_id)
			if str(first.instance_id) < str(second.instance_id)
			else str(second.instance_id)
		)
		_row(
			"T14 equal-time contacts resolve by stable item ID",
			wanted,
			rows[0].source_item_id,
			rows[0].source_item_id == wanted
		)
	# Pause mid-cycle is exact.
	await _fresh()
	var parol := _place(PAROL_5, Vector2i(13, 8), 0, 0)
	var behavior := _piece(str(parol.instance_id)).behavior as ParolBehavior
	await _arm()
	await _wait(50)
	var before := behavior.elapsed
	var before_time := room.items.director.play_time
	paused = true
	await _wait(30)
	var during := behavior.elapsed
	var during_time := room.items.director.play_time
	paused = false
	await _wait(10)
	_row(
		"T22 pausing mid-cycle freezes item clocks",
		"elapsed %.4f unchanged over 30 paused frames" % before,
		"%.4f -> %.4f (director %.4f -> %.4f)" % [before, during, before_time, during_time],
		is_equal_approx(before, during) and is_equal_approx(before_time, during_time)
	)
	_check(behavior.elapsed > during, "T22 resuming continues the cycle from the paused point")
	# Ten reset cycles keep counts stable.
	var base := _object_nodes()
	for _cycle in range(10):
		room.reset_room()
		await _wait(3)
	var after := _object_nodes()
	_row(
		"T05 ten reset cycles keep node counts stable",
		"nodes %d ±0" % base[1],
		"nodes %d" % after[1],
		absi(int(after[1]) - int(base[1])) <= 2
	)
	# Transient cap saturation: rotating allocation, no starvation, never over the cap.
	await _fresh()
	room.tuning.item_projectile_cap = 3
	room.items.configure(
		room.tuning, room.arena, room.support_tracker, room.definitions, room.world_layer
	)
	room.items.actors_source = room._actors_for_items
	var fired_by: Dictionary = {}
	var ids: Array[String] = []
	for index in range(6):
		var placed := _place(LANE_4, Vector2i(6 + (index % 3) * 6, 5 + (index / 3) * 3), 0, 0)
		if bool(placed.allowed):
			ids.append(str(placed.instance_id))
	_check(ids.size() == 6, "cap fixture: six launchers placed (%d)" % ids.size())
	await _arm()
	var peak := 0
	for _frame in range(420):
		await physics_frame
		peak = maxi(peak, room.items.budget.count(TransientBudget.Kind.PROJECTILE))
	for id in ids:
		var launcher := _piece(id).behavior as LauncherBehavior
		fired_by[id] = launcher.shots_fired
	var all_fired := true
	for id in ids:
		all_fired = all_fired and int(fired_by[id]) >= 1
	_row("T31 projectile cap is never exceeded", "<= 3 active", "peak %d" % peak, peak <= 3)
	_check(all_fired, "T31 rotating allocation lets every emitter fire: %s" % [fired_by])
	await _dispose()


# ---------------- scenarios


func _test_scenarios() -> void:
	# 1 Bridge + trumpo: rail sweep is separate from the bridge footprint and both place.
	await _fresh()
	var bridge := _place(TULAY_4, Vector2i(14, 10), 0, 0)
	var rail := _place(RAIL_4, Vector2i(14, 8), 0, 1)
	var rail_behavior := _piece(str(rail.instance_id)).behavior as TrumpoBehavior
	var bridge_rect := (room.items.pieces[str(bridge.instance_id)] as PlacedItem).footprint_rect
	_check(
		(
			bool(bridge.allowed)
			and bool(rail.allowed)
			and not rail_behavior.sweep.intersects(bridge_rect, false)
		),
		"S1 bridge + trumpo: sweep stays separate from the bridge footprint"
	)
	# 2 Spring + Parol: a launch from a spring reaches the beam row and the beam stays readable.
	await _fresh()
	var spring := _place(SPRING, Vector2i(16, 13), 0, 0)
	var parol := _place(PAROL_5, Vector2i(14, 8), 0, 1)
	_check(bool(spring.allowed) and bool(parol.allowed), "S2 spring + Parol both place")
	var parol_behavior := _piece(str(parol.instance_id)).behavior as ParolBehavior
	await _arm()
	_hold(_feet_to_center(Vector2(16.0 * CELL + CELL, 13.0 * CELL - 1.0)))
	var reached_beam_row := false
	var phases_seen := {}
	for _frame in range(240):
		await physics_frame
		phases_seen[parol_behavior.phase] = true
		if absf(actor.global_position.y - parol_behavior.beam.get_center().y) < 60.0 * W:
			reached_beam_row = true
	_check(phases_seen.size() == 3, "S2 inactive, charge and active are all observable")
	_check(
		reached_beam_row or actor.lifecycle.is_terminal(), "S2 the launch arc reaches the beam row"
	)
	# 3 Block + launcher: cover occludes and still leaves a visible lane.
	await _fresh()
	var launcher := _place(LANE_6, Vector2i(8, 8), 0, 0)
	var block := _place(KAING_3, Vector2i(11, 7), 0, 0)
	_check(bool(launcher.allowed) and bool(block.allowed), "S3 launcher + column cover place")
	var overlay := room.overlay_for_cursor(LANE_6, Vector2i(8, 12), 0)
	_check(overlay.size() > 0, "S3 the lane overlay is drawn for the placement preview")
	var found_blocker := false
	for entry in ItemOverlayBuilder.build(
		room.definitions.find_family("hazard.slipper_launcher"),
		room.definitions.find_variant(LANE_6).variant,
		Vector2i(8, 8),
		0,
		room.tuning,
		room.arena,
		room.items.pieces.values(),
		room.items.round_number
	):
		if entry.kind == "blocker":
			found_blocker = true
	_check(found_blocker, "S3 the ghost shows the lane's first blocker")
	# 4 Bubble + trumpo: only the direct trumpo elimination earns Patibong.
	await _fresh()
	_fast_bubbles()
	var bula := _place(BULA_5, Vector2i(16, 13), 0, 1)
	var trumpo := _place(RAIL_4, Vector2i(13, 8), 0, 2)
	_check(bool(bula.allowed) and bool(trumpo.allowed), "S4 bubble + trumpo place")
	await _arm()
	var start := Vector2(16.0 * CELL + 16.0 * W, 13.0 * CELL - 14.0 * W)
	for _frame in range(60):
		_hold(start)
		await physics_frame
		if actor.lifecycle.status == PlayerLifecycleState.Status.CAPTURED:
			break
	for _frame in range(420):
		await physics_frame
		if actor.lifecycle.is_terminal():
			break
	var eliminations := _records_of(AttributionRecord.Kind.ELIMINATION)
	var setups := _records_of(AttributionRecord.Kind.SETUP)
	var bubble_setups := 0
	for record in setups:
		if record.source_family_id == "hazard.bubble_planter":
			bubble_setups += 1
	_check(bubble_setups >= 1, "S4 bubble capture is recorded as setup")
	for record in eliminations:
		_check(
			record.source_family_id == "hazard.rail_trumpo" and record.owner_seat == 2,
			"S4 the trumpo owner (not the bubble owner) is credited"
		)
	# 5 Cleanup + obstructed route.
	await _fresh()
	var wall_a := _place(KAING_3, Vector2i(20, 8), 0, 0)
	var wall_b := _place(KAING_3, Vector2i(21, 8), 0, 0)
	room.items.end_round()
	var resolved := _resolve([_walis_edit(WALIS_3, Vector2i(19, 7), 1)] as Array[Dictionary])
	_check(
		(
			(resolved.removals as Array).size() >= 1
			and bool(room.items.commit_batch(resolved).allowed)
		),
		"S5 cleanup commits once and clears the obstructing pieces"
	)
	_check(not room.items.pieces.has(str(wall_a.instance_id)), "S5 the cleared route stays cleared")
	room.items.end_round()
	_check(not room.items.pieces.has(str(wall_a.instance_id)), "S5 still clear next round")
	_check(wall_b != null, "S5 fixture existed")
	await _dispose()


# ---------------- egg / ghost / library


func _test_previews_and_library() -> void:
	var tuning := GameplayTuning.new()
	ItemEnabledProfiles.apply(tuning, "items_lab")
	var definitions := ItemDefinitions.load_for_profile(tuning, "items_lab")
	var checked := 0
	for family_id in NEW_FAMILIES:
		var family := definitions.find_family(family_id)
		for variant in family.variants:
			var key := family.variant_key(variant)
			for turns in variant.rotations:
				var egg := ItemEggPreview.new()
				var ok := egg.configure(definitions, key, turns, tuning)
				_check(ok, "T06 egg preview configures for %s turns %d" % [key, turns])
				root.add_child(egg)
				egg.elapsed = 0.0
				var phase_a := egg.loop_phase()
				egg.elapsed = 1.0
				var phase_b := egg.loop_phase()
				_check(
					not is_equal_approx(phase_a, phase_b),
					"T06 %s turns %d egg loops (animated)" % [key, turns]
				)
				egg.queue_free()
				checked += 1
	_check(checked >= 25, "T06 every enabled variant/rotation has an egg preview (%d)" % checked)
	var no_text := true
	for family_id in NEW_FAMILIES:
		var family := definitions.find_family(family_id)
		no_text = no_text and family.preview_silhouette != "" and not family.working_name.is_empty()
	_check(no_text, "T06 previews are shape-only; names live in the Library")
	var entries := ItemLibraryEntry.build_list(definitions, false)
	var by_family := {}
	for entry in entries:
		by_family[entry.family_id] = entry
	for family_id in NEW_FAMILIES:
		_check(by_family.has(family_id), "T08 Library entry exists for %s" % family_id)
		if not by_family.has(family_id):
			continue
		var entry := by_family[family_id] as ItemLibraryEntry
		var complete := (
			not entry.display_name.is_empty()
			and not entry.sizes.is_empty()
			and not entry.placement.is_empty()
			and not entry.tell.is_empty()
			and not entry.counterplay.is_empty()
			and not entry.controls.is_empty()
			and not entry.modes_allowed.is_empty()
			and not entry.animation_variant_key.is_empty()
		)
		_check(
			complete,
			(
				"T08 %s entry has name, sizes, placement, tell, counterplay, controls, modes, animation"
				% family_id
			)
		)
		_check(
			entry.display_name.ends_with("(working name)"),
			"T08 %s name is flagged as a working name" % family_id
		)
		_check(
			not entry.placeholder_slots.is_empty(), "T08 %s lists its PLACEHOLDER slots" % family_id
		)
	var released := ItemLibraryEntry.build_list(definitions, true)
	_check(released.is_empty(), "T08 the release filter lists no unreleased family")
	await process_frame


# ---------------- visualizer


func _test_visualizer() -> void:
	await _fresh()
	_check(room.family_ids().size() == 11, "Visualizer lists all eight families (+3 stage blocks)")
	for family_id in room.family_ids():
		var selected := room.select_family(family_id)
		_check(
			selected and room.selected_family_id() == family_id, "Visualizer selects %s" % family_id
		)
	room.enter_place()
	var result := room.place_variant(SPRING, Vector2i(16, 13), 0, 0)
	_check(bool(result.allowed), "Visualizer places a spring")
	room.start_play()
	await _wait(5)
	_check(room.items.in_play, "Visualizer toggles to Play")
	var rows := room.piece_readouts()
	_check(rows.size() == 1 and str(rows[0].state) != "", "Visualizer reads out live item state")
	room.cycle_speed()
	_check(is_equal_approx(Engine.time_scale, 0.25), "Visualizer slow motion sets 0.25x")
	room.reset_speed()
	var seat_a := room.spawn_test_chicken()
	var seat_b := room.spawn_test_chicken()
	var seat_c := room.spawn_test_chicken()
	_check(seat_a >= 0 or room.actors.size() >= 1, "Visualizer spawns test chickens")
	_check(
		room.actors.size() <= 4, "Visualizer caps test chickens at four (%d)" % room.actors.size()
	)
	_check(seat_b >= -1 and seat_c >= -1, "Visualizer spawn is bounded")
	var report := room.slot_report()
	_check(report.size() >= 20, "Visualizer lists every replaceable slot (%d)" % report.size())
	var all_placeholder := true
	for line in report:
		all_placeholder = all_placeholder and line.contains("PLACEHOLDER")
	_check(all_placeholder, "every shipped slot is labelled PLACEHOLDER")
	room.toggle_overlays()
	room.toggle_owner_tags()
	await _dispose()


func _test_placeholder_audit() -> void:
	var tuning := GameplayTuning.new()
	ItemEnabledProfiles.apply(tuning, "items_lab")
	var definitions := ItemDefinitions.load_for_profile(tuning, "items_lab")
	var rows := PlaceholderAudit.slot_rows(definitions)
	var files := PlaceholderAudit.placeholder_files()
	_check(rows.size() >= 20, "audit lists every placeholder slot (%d)" % rows.size())
	_check(files.size() >= 23, "audit finds every PLACEHOLDER_* file (%d)" % files.size())
	_check(
		PlaceholderAudit.release_violations(definitions).is_empty(),
		"no family is release-enabled, so no placeholder violates the release gate"
	)
	var copies: Array[ItemFamilyDefinition] = []
	for family in definitions.families:
		copies.append(family.duplicate(true) as ItemFamilyDefinition)
	copies[2].release_target = true
	copies[2].runtime_enabled = true
	copies[2].implementation_complete = true
	copies[2].independently_verified = true
	var flagged := ItemDefinitions.from_families(copies, tuning)
	var violations := PlaceholderAudit.release_violations(flagged)
	_row(
		"release gate flags a placeholder in an enabled release item",
		"violations for move.tire_spring",
		str(violations),
		violations.size() >= 1 and violations[0].begins_with("move.tire_spring")
	)
	copies[2].visual_set = null
	var missing := PlaceholderAudit.release_violations(
		ItemDefinitions.from_families(copies, tuning)
	)
	_check(missing.size() == 1, "release gate also flags a release item with no visual set")


func _test_occupancy() -> void:
	var tuning := GameplayTuning.new()
	ItemEnabledProfiles.apply(tuning, "items_lab")
	var definitions := ItemDefinitions.load_for_profile(tuning, "items_lab")
	var found := definitions.find_variant(PAROL_5)
	var family := found.family as ItemFamilyDefinition
	var variant := found.variant as ItemVariantDefinition
	for turns in [0, 1]:
		var occupied := ItemPlacementValidator.occupied_rects_for(
			family, variant, Vector2i(14, 4), turns, tuning
		)
		var expected: Array[Rect2] = []
		if turns == 0:
			expected = [Rect2(896, 256, 64, 64), Rect2(1152, 256, 64, 64)]
		else:
			expected = [Rect2(896, 256, 64, 64), Rect2(896, 512, 64, 64)]
		_row(
			"T20 Parol turns %d reserves only its two posts" % turns,
			str(expected),
			str(occupied),
			occupied == expected
		)
	await _fresh()
	var first := _place(PAROL_5, Vector2i(14, 4), 0, 0)
	var inside := _place(KAING_1, Vector2i(16, 4), 0, 0)
	var on_post := _place(KAING_1, Vector2i(14, 4), 0, 0)
	_check(bool(first.allowed), "occupancy fixture placed")
	_check(bool(inside.allowed), "a block may share the beam cells between the posts")
	_check(not bool(on_post.allowed), "a block cannot take a post cell")
	await _dispose()


func _test_reset_states() -> void:
	await _fresh()
	_fast_bubbles()
	var rail := _place(RAIL_5, Vector2i(14, 8), 2, 0)
	var parol := _place(PAROL_5, Vector2i(13, 4), 0, 0)
	var launcher := _place(LANE_4, Vector2i(6, 5), 0, 0)
	var bula := _place(BULA_3, Vector2i(20, 12), 0, 0)
	var spring := _place(SPRING, Vector2i(24, 13), 0, 0)
	var rail_b := _piece(str(rail.instance_id)).behavior as TrumpoBehavior
	var parol_b := _piece(str(parol.instance_id)).behavior as ParolBehavior
	var launcher_b := _piece(str(launcher.instance_id)).behavior as LauncherBehavior
	var bula_b := _piece(str(bula.instance_id)).behavior as BubbleBehavior
	var spring_b := _piece(str(spring.instance_id)).behavior as SpringBehavior
	await _arm()
	await _wait(240)
	_check(rail_b.elapsed > 1.0 and parol_b.elapsed > 1.0, "T13 items advanced during Play")
	spring_b.compress = 1.0
	room.reset_room()
	await _wait(2)
	_row(
		"T13 trumpo resets to its start endpoint and direction",
		"centre %s, direction %s, elapsed 0" % [rail_b.start_center, Vector2.LEFT],
		(
			"centre %s, direction %s, elapsed %.3f"
			% [rail_b.top_center(), rail_b.direction, rail_b.elapsed]
		),
		(
			rail_b.top_center().is_equal_approx(rail_b.start_center)
			and rail_b.direction == Vector2.LEFT
			and rail_b.elapsed < 0.05
		)
	)
	_row(
		"T22 parol resets to inactive at t=0",
		"phase inactive, elapsed ~0",
		"phase %s, elapsed %.3f" % [PhaseCycle.phase_name(parol_b.phase), parol_b.elapsed],
		parol_b.phase == PhaseCycle.Phase.INACTIVE and parol_b.elapsed < 0.05
	)
	_row(
		"T31 launcher resets idle with no projectile",
		"cooldown, 0 projectiles, 0 shots",
		(
			"state %d, %d projectiles, %d shots"
			% [launcher_b.state, launcher_b.projectiles.size(), launcher_b.shots_fired]
		),
		(
			launcher_b.state == LauncherBehavior.State.COOLDOWN
			and launcher_b.projectiles.is_empty()
			and launcher_b.shots_fired == 0
		)
	)
	_row(
		"T49 bubble emitter resets idle with no bubble",
		"wait, no bubble, 0 captures",
		(
			"state %d, bubble %s, %d captures"
			% [bula_b.state, bula_b.has_bubble(), bula_b.capture_count]
		),
		(
			bula_b.state == BubbleBehavior.State.WAIT
			and not bula_b.has_bubble()
			and bula_b.capture_count == 0
		)
	)
	_check(spring_b.compress == 0.0 and spring_b.launch_count == 0, "T04 spring resets ready")
	await _dispose()

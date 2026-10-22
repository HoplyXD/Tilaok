# gdlint: disable=max-file-lines
extends SceneTree

const ROOM_SCENE := preload("res://scenes/fixtures/item_lab.tscn")
const HARNESS_SCENE := preload("res://scenes/harness/foundation_harness.tscn")
const KAING_1X1 := "build.hollow_blocks.cell_1x1"
const KAING_1X3 := "build.hollow_blocks.column_1x3"
const KAING_2X3 := "build.hollow_blocks.stack_2x3"
const TULAY_3X1 := "build.bamboo_bridge.span_3x1"
const TULAY_4X1 := "build.bamboo_bridge.span_4x1"
const TULAY_5X1 := "build.bamboo_bridge.span_5x1"
const SOLID_3X1 := "build.solid_block.slab_3x1"
const WOOD_BOX_2X2 := "build.wood_box.box_2x2"
const COLLAPSE_1X1 := "build.collapsing_block.cell_1x1"
const FEET_TOLERANCE_WU := 1.0

var failures := 0
var checks := 0
var room: ItemLabRoom
var actor: ChickenController
var seat := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	room = ROOM_SCENE.instantiate() as ItemLabRoom
	root.add_child(room)
	for _frame in range(3):
		await physics_frame
	_test_tuning_and_definitions()
	_test_rejection_table()
	_test_effect_regions_are_not_cells()
	_test_transient_budget()
	seat = room.join_keyboard("K1")
	actor = room.actors[seat] as ChickenController
	room.start_play()
	for _frame in range(3):
		await physics_frame
	_test_placement_reasons()
	await _test_lifecycle_cycles()
	await _test_kaing_physics()
	await _test_tulay_physics()
	await _test_disabled_variant_geometry()
	await _test_wall_eligibility()
	_test_lab_flow()
	await _test_placeholder_previews_and_library()
	await _test_catalog_and_harness()
	room.queue_free()
	await process_frame
	print("P04_TESTS checks=%d failures=%d" % [checks, failures])
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


# ---------------------------------------------------------------- T01 / T02


func _fresh_definitions(tuning: GameplayTuning = null) -> Array[ItemFamilyDefinition]:
	var source_tuning := tuning if tuning != null else GameplayTuning.new()
	var loaded := ItemDefinitions.load_all(source_tuning)
	var copies: Array[ItemFamilyDefinition] = []
	for family in loaded.families:
		copies.append(family.duplicate(true) as ItemFamilyDefinition)
	return copies


func _errors_for(
	families: Array[ItemFamilyDefinition], tuning: GameplayTuning = null
) -> PackedStringArray:
	return ItemDefinitionValidator.validate_families(
		families, tuning if tuning != null else GameplayTuning.new()
	)


func _has_error(errors: PackedStringArray, fragment: String) -> bool:
	for message in errors:
		if message.contains(fragment):
			return true
	return false


func _test_tuning_and_definitions() -> void:
	var tuning := GameplayTuning.new()
	_check(tuning.validate().is_empty(), "default tuning including item tunables validates")
	_check(
		(
			tuning.item_persistent_cap == 48
			and tuning.item_projectile_cap == 16
			and tuning.item_projectiles_per_emitter == 2
			and tuning.item_bubble_cap == 4
			and tuning.item_bubbles_per_emitter == 1
			and tuning.item_bubbles_per_player == 1
			and tuning.item_vfx_cap == 32
		),
		"caps are 48 persistent, 16 projectiles (2/emitter), 4 bubbles (1/emitter, 1/player), 32 VFX"
	)
	_check(
		(
			is_equal_approx(tuning.item_projectile_ttl_s, 3.0)
			and is_equal_approx(tuning.item_bubble_ttl_s, 4.0)
			and is_equal_approx(tuning.item_vfx_ttl_s, 2.0)
			and is_equal_approx(tuning.item_activation_grace_s, 1.0)
		),
		"TTLs 3/4/2 s and activation grace 1.0 s match PROTOTYPE_DEFAULTS"
	)
	var broken := GameplayTuning.new()
	broken.item_tulay_strip_thickness_wu = 0.0
	_check(not broken.validate().is_empty(), "tuning rejects a zero Tulay strip thickness")
	broken = GameplayTuning.new()
	broken.item_persistent_cap = 0
	_check(not broken.validate().is_empty(), "tuning rejects a zero persistent cap")
	var definitions := ItemDefinitions.load_all(tuning)
	_check(definitions.is_valid(), "shipped definitions validate: %s" % [definitions.errors])
	# The six P10 families joined the main game on 2026-10-16 (user request).
	_check(
		(
			definitions.families.size() == BlockCatalog.families(BlockCatalog.SET_MAIN).size()
			and definitions.families.size() >= 16
		),
		(
			"every catalog block family is defined (at least Kaing, Tulay, stage blocks, Spikes, Cannon,"
			+ " six P10 families): %d" % definitions.families.size()
		)
	)
	var kaing := definitions.find_family("build.hollow_blocks")
	var tulay := definitions.find_family("build.bamboo_bridge")
	var kaing_ids := PackedStringArray()
	for variant in kaing.variants:
		kaing_ids.append(variant.variant_id)
	var tulay_ids := PackedStringArray()
	for variant in tulay.variants:
		tulay_ids.append(variant.variant_id)
	_check(
		kaing_ids == PackedStringArray(["cell_1x1", "column_1x3", "stack_2x3"]),
		"Kaing lists 1x1, 1x3 column and 2x3 stack"
	)
	_check(
		tulay_ids == PackedStringArray(["span_3x1", "span_4x1", "span_5x1"]),
		"Tulay lists 3x1, 4x1 and 5x1"
	)
	_check(
		(
			definitions.enabled_variant_keys("build.hollow_blocks")
			== PackedStringArray([KAING_1X1, KAING_2X3])
		),
		"prototype Kaing subset is exactly 1x1 and 2x3"
	)
	_check(
		definitions.enabled_variant_keys("build.bamboo_bridge") == PackedStringArray([TULAY_4X1]),
		"prototype Tulay subset is exactly horizontal 4x1"
	)
	_check(
		(
			not definitions.is_variant_enabled(KAING_1X3)
			and not definitions.is_variant_enabled(TULAY_3X1)
			and not definitions.is_variant_enabled(TULAY_5X1)
		),
		"1x3 column and 3x1/5x1 Tulay are defined but not enabled"
	)
	var kaing_solid_only := true
	for variant in kaing.variants:
		for region in variant.regions:
			if region.kind != ItemRegionSpec.Kind.SOLID:
				kaing_solid_only = false
		var solid: ItemRegionSpec = variant.regions[0]
		if solid.rect_cells != Rect2(Vector2.ZERO, Vector2(variant.footprint_cells)):
			kaing_solid_only = false
	_check(
		kaing_solid_only,
		"every Kaing variant is one SOLID region equal to its footprint, with no trigger"
	)
	var tulay_one_way_only := true
	for variant in tulay.variants:
		if (
			variant.regions.size() != 1
			or variant.regions[0].kind != ItemRegionSpec.Kind.ONE_WAY_TOP
		):
			tulay_one_way_only = false
	_check(tulay_one_way_only, "every Tulay variant is a single ONE_WAY_TOP strip region")
	_check(
		(
			kaing.ownership == "placer"
			and kaing.safe_start == "static_no_motion"
			and tulay.removal_policy == "walis_cleanup"
			and tulay.persistence == "until_removed"
		),
		"ownership, safe start, removal and persistence are explicit"
	)
	# Since the P11 Kangaroo contract lab (reviewed construction) the scenes also allow Kangaroo;
	# Tulay's Lagsanay safe-floor review is still open (P04-T20, 2026-10-16).
	_check(
		(
			kaing.modes_allowed == PackedStringArray(["karera", "lagsanay", "kangaroo"])
			and kaing.modes_pending_review.is_empty()
			and tulay.modes_allowed == PackedStringArray(["karera", "kangaroo"])
			and tulay.modes_pending_review == PackedStringArray(["lagsanay"])
		),
		(
			"mode flags: Kaing karera+lagsanay+kangaroo; Tulay karera+kangaroo, Lagsanay pending"
			+ (
				" review (%s / %s pending %s)"
				% [kaing.modes_allowed, tulay.modes_allowed, tulay.modes_pending_review]
			)
		)
	)
	_check(
		(
			kaing.wall_contact == ItemFamilyDefinition.WALL_ELIGIBLE
			and tulay.wall_contact == ItemFamilyDefinition.WALL_INELIGIBLE
		),
		"wall-contact declaration: Kaing solid sides eligible, Tulay ineligible"
	)


func _test_rejection_table() -> void:
	var cases: Array[Dictionary] = [
		{"id": "missing family_id", "expect": "family_id is required"},
		{"id": "missing ownership", "expect": "ownership must be"},
		{"id": "missing safe_start", "expect": "safe_start is required"},
		{"id": "missing removal_policy", "expect": "removal_policy is required"},
		{"id": "missing persistence", "expect": "persistence is required"},
		{"id": "missing event eligibility", "expect": "event eligibility"},
		{"id": "missing wall_contact", "expect": "wall_contact declaration"},
		{"id": "missing weight key", "expect": "weight_tuning_key"},
		{"id": "missing preview silhouette", "expect": "preview_silhouette is required"},
		{"id": "missing library tell", "expect": "library_tell is required"},
		{"id": "no variants", "expect": "at least one variant"},
		{"id": "missing variant id", "expect": "variant_id is required"},
		{"id": "undocumented variant", "expect": "undocumented variant"},
		{"id": "wrong documented footprint", "expect": "does not match documented"},
		{"id": "zero footprint", "expect": "footprint is required"},
		{"id": "no rotations", "expect": "at least one documented rotation"},
		{"id": "rotation out of range", "expect": "outside 0..3"},
		{"id": "gated rotation undocumented", "expect": "gated rotation"},
		{"id": "no regions", "expect": "at least one region"},
		{"id": "region kind unset", "expect": "region kind is required"},
		{"id": "zero-size region", "expect": "missing, unbounded or non-positive"},
		{"id": "infinite region", "expect": "missing, unbounded or non-positive"},
		{"id": "arena-sized region", "expect": "exceeds the arena extent"},
		{"id": "effect not declared bounded", "expect": "must declare explicit bounds"},
		{"id": "solid outside footprint", "expect": "inside the footprint"},
		{"id": "strip without thickness key", "expect": "thickness tuning key"},
		{"id": "strip thicker than cell", "expect": "strip thickness is outside"},
		{"id": "strip overlaps solid", "expect": "may not overlap a solid"},
		{"id": "enabled without verification", "expect": "runtime_enabled requires"},
		{"id": "duplicate variant", "expect": "duplicate variant"},
		{"id": "enabled variant undefined", "expect": "is not defined"},
	]
	var rejected := 0
	for entry in cases:
		var families := _fresh_definitions()
		var tuning := GameplayTuning.new()
		var kaing := families[0]
		var tulay := families[1]
		match str(entry.id):
			"missing family_id":
				kaing.family_id = ""
			"missing ownership":
				kaing.ownership = ""
			"missing safe_start":
				kaing.safe_start = ""
			"missing removal_policy":
				kaing.removal_policy = ""
			"missing persistence":
				kaing.persistence = ""
			"missing event eligibility":
				kaing.modes_allowed = PackedStringArray()
			"missing wall_contact":
				kaing.wall_contact = ""
			"missing weight key":
				kaing.weight_tuning_key = &""
			"missing preview silhouette":
				kaing.preview_silhouette = ""
			"missing library tell":
				kaing.library_tell = ""
			"no variants":
				kaing.variants = []
			"missing variant id":
				kaing.variants[0].variant_id = ""
			"undocumented variant":
				kaing.variants[0].variant_id = "stack_4x4"
			"wrong documented footprint":
				kaing.variants[0].footprint_cells = Vector2i(2, 2)
			"zero footprint":
				kaing.variants[0].footprint_cells = Vector2i.ZERO
			"no rotations":
				kaing.variants[0].rotations = PackedInt32Array()
			"rotation out of range":
				kaing.variants[2].rotations = PackedInt32Array([0, 5])
			"gated rotation undocumented":
				kaing.variants[0].gated_rotations = PackedInt32Array([1])
			"no regions":
				kaing.variants[0].regions = []
			"region kind unset":
				kaing.variants[0].regions[0].kind = ItemRegionSpec.Kind.UNSET
			"zero-size region":
				kaing.variants[0].regions[0].rect_cells = Rect2(0, 0, 0, 0)
			"infinite region":
				kaing.variants[0].regions[0].rect_cells = Rect2(0, 0, INF, 1)
			"arena-sized region":
				kaing.variants[0].regions[0].rect_cells = Rect2(0, 0, 64, 1)
			"effect not declared bounded":
				var effect := ItemRegionSpec.new()
				effect.kind = ItemRegionSpec.Kind.EFFECT
				effect.rect_cells = Rect2(-1, -1, 3, 3)
				kaing.variants[0].regions.append(effect)
			"solid outside footprint":
				kaing.variants[0].regions[0].rect_cells = Rect2(0, 0, 2, 2)
			"strip without thickness key":
				tulay.variants[0].regions[0].thickness_tuning_key = &""
			"strip thicker than cell":
				tuning.item_tulay_strip_thickness_wu = tuning.grid_cell_wu - 1.0
				tulay.variants[0].regions[0].rect_cells = Rect2(0, 0, 3, 0.5)
			"strip overlaps solid":
				var solid := ItemRegionSpec.new()
				solid.kind = ItemRegionSpec.Kind.SOLID
				solid.rect_cells = Rect2(0, 0, 1, 1)
				tulay.variants[0].regions.append(solid)
			"enabled without verification":
				kaing.runtime_enabled = true
				kaing.implementation_complete = true
				kaing.independently_verified = false
			"duplicate variant":
				kaing.variants.append(kaing.variants[0])
			"enabled variant undefined":
				tuning.item_enabled_variants = PackedStringArray(
					[KAING_1X1, "build.hollow_blocks.stack_9x9"]
				)
		var errors := _errors_for(families, tuning)
		var matched := _has_error(errors, str(entry.expect))
		if matched:
			rejected += 1
		_row("T02 reject: %s" % entry.id, str(entry.expect), "%d error(s)" % errors.size(), matched)
	_check(rejected == cases.size(), "all %d rejection cases are rejected" % cases.size())
	var baseline := _errors_for(_fresh_definitions())
	_check(baseline.is_empty(), "unmodified definitions still validate after the table runs")


func _test_effect_regions_are_not_cells() -> void:
	var families := _fresh_definitions()
	var effect := ItemRegionSpec.new()
	effect.kind = ItemRegionSpec.Kind.EFFECT
	effect.rect_cells = Rect2(-1, -1, 3, 3)
	effect.declared_bounded = true
	families[0].variants[0].regions.append(effect)
	var tuning := GameplayTuning.new()
	var definitions := ItemDefinitions.from_families(families, tuning)
	_check(definitions.is_valid(), "a bounded effect region around a 1x1 passes validation")
	var arena := ArenaDefinition.new(tuning)
	var first := ItemPlacementValidator.validate(
		definitions, arena, tuning, KAING_1X1, Vector2i(14, 8), 0, []
	)
	_check(bool(first.allowed), "1x1 with effect region places")
	var placed := PlacedItem.new()
	placed.instance_id = "fixture#001"
	placed.footprint_rect = first.footprint
	_check(
		first.footprint.size == Vector2(64.0, 64.0),
		"occupied footprint stays one cell although the effect spans 3x3"
	)
	var inside_effect := ItemPlacementValidator.validate(
		definitions, arena, tuning, KAING_1X1, Vector2i(15, 8), 0, [placed]
	)
	_check(
		bool(inside_effect.allowed),
		"a piece may sit inside another piece's effect region: effect cells are not occupied"
	)
	var on_footprint := ItemPlacementValidator.validate(
		definitions, arena, tuning, KAING_1X1, Vector2i(14, 8), 0, [placed]
	)
	_check(
		not bool(on_footprint.allowed) and on_footprint.code == "item_overlap",
		"the real footprint cell is still occupied"
	)
	var effect_into_spawn := ItemPlacementValidator.validate(
		definitions, arena, tuning, KAING_1X1, Vector2i(5, 12), 0, []
	)
	_check(
		not bool(effect_into_spawn.allowed) and effect_into_spawn.code == "protected_spawn",
		"an effect region reaching protected spawn rejects the placement"
	)


# ---------------------------------------------------------------- T03 / T04 budget


func _new_budget() -> TransientBudget:
	var budget := TransientBudget.new()
	budget.configure(GameplayTuning.new())
	return budget


func _requests(ids: Array, player_prefix: String = "") -> Array[Dictionary]:
	var requests: Array[Dictionary] = []
	for emitter_id in ids:
		var request := {"emitter_id": str(emitter_id)}
		if not player_prefix.is_empty():
			request["player_id"] = "%s%s" % [player_prefix, emitter_id]
		requests.append(request)
	return requests


func _test_transient_budget() -> void:
	var budget := _new_budget()
	var emitters: Array = []
	for index in range(20):
		emitters.append("emitter_%02d" % index)
	var first := budget.allocate(TransientBudget.Kind.PROJECTILE, _requests(emitters))
	_check(first.size() == 16, "projectile grants stop at the 16 cap (got %d)" % first.size())
	var second := budget.allocate(TransientBudget.Kind.PROJECTILE, _requests(emitters))
	_check(second.is_empty(), "saturated projectile budget suppresses spawns")
	_check(budget.count(TransientBudget.Kind.PROJECTILE) == 16, "no active projectile was evicted")
	var single := _new_budget()
	var grants := 0
	for _call in range(4):
		grants += single.allocate(TransientBudget.Kind.PROJECTILE, _requests(["solo"])).size()
	_check(grants == 2, "one emitter is limited to 2 projectiles (got %d)" % grants)
	var bubbles := _new_budget()
	var bubble_grants := bubbles.allocate(
		TransientBudget.Kind.BUBBLE, _requests(["a", "b", "c", "d", "e", "f"], "player_")
	)
	_check(bubble_grants.size() == 4, "bubble grants stop at the 4 cap")
	var same_player := _new_budget()
	var shared_player: Array[Dictionary] = [
		{"emitter_id": "a", "player_id": "p1"}, {"emitter_id": "b", "player_id": "p1"}
	]
	_check(
		same_player.allocate(TransientBudget.Kind.BUBBLE, shared_player).size() == 1,
		"one bubble per player"
	)
	var effects := _new_budget()
	var many: Array = []
	for index in range(40):
		many.append("fx_%02d" % index)
	_check(
		effects.allocate(TransientBudget.Kind.VFX, _requests(many)).size() == 32,
		"cosmetic effects stop at the 32 cap"
	)
	# Rotating order: permuting callback order must not change who is granted.
	var forward := _new_budget()
	var reversed := _new_budget()
	var names := ["e0", "e1", "e2", "e3", "e4", "e5"]
	var same_sequence := true
	var wins := {}
	for _round in range(6):
		var a := forward.allocate(TransientBudget.Kind.BUBBLE, _requests(names))
		var reversed_names := names.duplicate()
		reversed_names.reverse()
		var b := reversed.allocate(TransientBudget.Kind.BUBBLE, _requests(reversed_names))
		var order_a := []
		var order_b := []
		for grant in a:
			order_a.append(grant.emitter_id)
			wins[grant.emitter_id] = int(wins.get(grant.emitter_id, 0)) + 1
			forward.release(TransientBudget.Kind.BUBBLE, int(grant.handle))
		for grant in b:
			order_b.append(grant.emitter_id)
			reversed.release(TransientBudget.Kind.BUBBLE, int(grant.handle))
		same_sequence = same_sequence and order_a == order_b
	_check(same_sequence, "callback order permutation yields the same grants in the same order")
	var even := true
	for emitter_id in names:
		even = even and int(wins.get(emitter_id, 0)) == 4
	_check(even, "rotating order is fair: 6 emitters, cap 4, 6 rounds -> 4 wins each %s" % [wins])
	# Captives are never evicted by saturation, and release is explicit and safe.
	var captive_budget := _new_budget()
	var held := captive_budget.allocate(TransientBudget.Kind.BUBBLE, _requests(["a"], "player_"))
	var handle := int(held[0].handle)
	_check(captive_budget.register_captive(handle, "victim"), "a captive attaches to a bubble")
	captive_budget.allocate(TransientBudget.Kind.BUBBLE, _requests(["b", "c", "d", "e"], "q_"))
	var saturated := captive_budget.allocate(
		TransientBudget.Kind.BUBBLE, _requests(["f", "g"], "r_")
	)
	_check(
		(
			saturated.is_empty()
			and captive_budget.captive_count() == 1
			and captive_budget.is_active(TransientBudget.Kind.BUBBLE, handle)
		),
		"saturation suppresses new bubbles and leaves the captive's bubble untouched"
	)
	captive_budget.advance(10.0)
	_check(
		(
			captive_budget.is_active(TransientBudget.Kind.BUBBLE, handle)
			and captive_budget.count(TransientBudget.Kind.BUBBLE) == 1
		),
		"empty bubbles expire by TTL; the captive's bubble does not"
	)
	var released := captive_budget.release(TransientBudget.Kind.BUBBLE, handle)
	_check(
		released == "victim" and captive_budget.captive_count() == 0,
		"explicit release returns the captive and clears the reference"
	)
	var clear_budget := _new_budget()
	var clear_held := clear_budget.allocate(TransientBudget.Kind.BUBBLE, _requests(["a"], "p_"))
	clear_budget.register_captive(int(clear_held[0].handle), "victim")
	clear_budget.allocate(TransientBudget.Kind.PROJECTILE, _requests(["x", "y"]))
	var cleared := clear_budget.clear_all()
	_check(
		(
			cleared == PackedStringArray(["victim"])
			and clear_budget.total_count() == 0
			and clear_budget.captive_count() == 0
		),
		"clear_all drops every transient and releases the captive"
	)
	var ttl := _new_budget()
	ttl.allocate(TransientBudget.Kind.PROJECTILE, _requests(["p"]))
	ttl.allocate(TransientBudget.Kind.VFX, _requests(["v"]))
	ttl.allocate(TransientBudget.Kind.BUBBLE, _requests(["b"], "z_"))
	ttl.advance(2.01)
	_check(
		(
			ttl.count(TransientBudget.Kind.VFX) == 0
			and ttl.count(TransientBudget.Kind.PROJECTILE) == 1
			and ttl.count(TransientBudget.Kind.BUBBLE) == 1
		),
		"cosmetic effects expire at 2 s while projectile and bubble remain"
	)
	ttl.advance(1.0)
	ttl.advance(1.0)
	_check(
		(
			ttl.count(TransientBudget.Kind.PROJECTILE) == 0
			and ttl.count(TransientBudget.Kind.BUBBLE) == 0
		),
		"projectile expires at 3 s and an empty bubble at 4 s"
	)


# ---------------------------------------------------------------- placement reasons


func _actor_rect_at_cell(cell: Vector2i) -> Rect2:
	return Rect2(Vector2(cell) * 64.0 + Vector2(4.0, 0.0), Vector2(56.0, 120.0))


func _test_placement_reasons() -> void:
	var items := room.items
	items.reset_match()
	var clear_rects: Array[Rect2] = []
	var cases: Array[Dictionary] = [
		{
			"id": "valid 1x1",
			"variant": KAING_1X1,
			"cell": Vector2i(14, 8),
			"turns": 0,
			"code": "valid"
		},
		{
			"id": "valid rotated 3x2",
			"variant": KAING_2X3,
			"cell": Vector2i(14, 8),
			"turns": 1,
			"code": "valid"
		},
		{
			"id": "valid Tulay 4x1",
			"variant": TULAY_4X1,
			"cell": Vector2i(14, 8),
			"turns": 0,
			"code": "valid"
		},
		{
			"id": "out of bounds",
			"variant": KAING_1X1,
			"cell": Vector2i(-1, 8),
			"turns": 0,
			"code": "out_of_bounds"
		},
		{
			"id": "past right edge",
			"variant": TULAY_4X1,
			"cell": Vector2i(30, 8),
			"turns": 0,
			"code": "out_of_bounds"
		},
		{
			"id": "protected spawn",
			"variant": KAING_1X1,
			"cell": Vector2i(2, 12),
			"turns": 0,
			"code": "protected_spawn"
		},
		{
			"id": "protected goal",
			"variant": KAING_1X1,
			"cell": Vector2i(29, 10),
			"turns": 0,
			"code": "protected_goal"
		},
		{
			"id": "outside build region",
			"variant": KAING_1X1,
			"cell": Vector2i(14, 1),
			"turns": 0,
			"code": "outside_build_region"
		},
		{
			"id": "base geometry",
			"variant": KAING_1X1,
			"cell": Vector2i(7, 13),
			"turns": 0,
			"code": "immutable_base"
		},
		{
			"id": "disabled variant",
			"variant": KAING_1X3,
			"cell": Vector2i(14, 8),
			"turns": 0,
			"code": "variant_disabled"
		},
		{
			"id": "disabled Tulay 5x1",
			"variant": TULAY_5X1,
			"cell": Vector2i(14, 8),
			"turns": 0,
			"code": "variant_disabled"
		},
		{
			"id": "unknown variant",
			"variant": "build.hollow_blocks.stack_9x9",
			"cell": Vector2i(14, 8),
			"turns": 0,
			"code": "unknown_variant"
		},
		{
			"id": "1x1 rotation",
			"variant": KAING_1X1,
			"cell": Vector2i(14, 8),
			"turns": 1,
			"code": "rotation_unsupported"
		},
		{
			"id": "180 degrees",
			"variant": KAING_2X3,
			"cell": Vector2i(14, 8),
			"turns": 2,
			"code": "rotation_unsupported"
		},
		{
			"id": "vertical Tulay gated",
			"variant": TULAY_4X1,
			"cell": Vector2i(14, 8),
			"turns": 1,
			"code": "rotation_unsupported"
		},
	]
	for entry in cases:
		var verdict := items.validate_placement(
			str(entry.variant), entry.cell, int(entry.turns), clear_rects
		)
		_row(
			"T06/T15 placement: %s" % entry.id,
			str(entry.code),
			"%s (%s)" % [verdict.code, verdict.reason],
			verdict.code == entry.code
		)
	var player_clearance := items.validate_placement(
		KAING_1X1,
		Vector2i(14, 8),
		0,
		[Rect2(Vector2(14.0 * 64.0 + 64.0 + 3.0, 512.0), Vector2(56.0, 120.0))]
	)
	_row(
		"T06 placement: player clearance",
		"player_clearance",
		str(player_clearance.code),
		player_clearance.code == "player_clearance"
	)
	var beside_clearance := items.validate_placement(
		KAING_1X1,
		Vector2i(14, 8),
		0,
		[Rect2(Vector2(14.0 * 64.0 + 64.0 + 5.0, 512.0), Vector2(56.0, 120.0))]
	)
	_check(bool(beside_clearance.allowed), "five wu away is outside the four wu player clearance")
	var first := items.place(KAING_2X3, Vector2i(14, 8), 0, 0, clear_rects)
	_check(bool(first.allowed), "first placement is committed")
	var overlap := items.place(KAING_1X1, Vector2i(15, 9), 0, 1, clear_rects)
	_row(
		"T06 placement: overlap", "item_overlap", str(overlap.code), overlap.code == "item_overlap"
	)
	var flush := items.place(KAING_1X1, Vector2i(16, 8), 0, 1, clear_rects)
	_check(bool(flush.allowed), "a flush neighbour that only shares an edge is valid")
	var tulay_overlap := items.place(TULAY_4X1, Vector2i(13, 10), 0, 1, clear_rects)
	_check(not bool(tulay_overlap.allowed), "Tulay footprint reservation overlaps Kaing solid")
	items.reset_match()
	var placed_count := 0
	for row_index in range(3, 6):
		for column in range(5, 28):
			if placed_count >= items.tuning.item_persistent_cap:
				break
			var result := items.place(KAING_1X1, Vector2i(column, row_index), 0, 0, clear_rects)
			if bool(result.allowed):
				placed_count += 1
	_check(placed_count == 48, "48 persistent pieces fit (placed %d)" % placed_count)
	var over_cap := items.place(KAING_1X1, Vector2i(5, 7), 0, 0, clear_rects)
	_row(
		"T03 cap: 49th piece",
		"persistent_cap",
		str(over_cap.code),
		over_cap.code == "persistent_cap"
	)
	_check(items.persistent_count() == 48, "a rejected piece creates no node or record")
	items.reset_match()
	_check(items.persistent_count() == 0, "match reset removes every piece")


# ---------------------------------------------------------------- lifecycle


## Runtime collision of a placed piece (block scenes also hold BlockData and Visual nodes).
func _collision_shapes(piece: Node) -> Array[CollisionShape2D]:
	var result: Array[CollisionShape2D] = []
	for child in piece.get_children():
		if child is CollisionShape2D:
			result.append(child)
	return result


func _world_piece_count() -> int:
	var found := 0
	for child in room.world_layer.get_children():
		if child is ConstructionPiece:
			found += 1
	return found


func _test_lifecycle_cycles() -> void:
	var items := room.items
	items.reset_match()
	var clear_rects: Array[Rect2] = []
	_check(bool(items.place(KAING_1X1, Vector2i(14, 8), 0, 0, clear_rects).allowed), "setup 1x1")
	_check(
		bool(items.place(KAING_2X3, Vector2i(20, 6), 1, 1, clear_rects).allowed),
		"setup rotated 2x3"
	)
	_check(bool(items.place(TULAY_4X1, Vector2i(10, 5), 0, 0, clear_rects).allowed), "setup Tulay")
	var signature := items.construction_signature()
	var surface_ids := items.support_tracker.surfaces.keys()
	var in_place := items.place(KAING_1X1, Vector2i(25, 5), 0, 0, clear_rects)
	_check(bool(in_place.allowed), "Place accepts construction")
	items.remove(str(in_place.instance_id), "setup_cleanup")
	var start_positions := {}
	for instance_id in items.pieces:
		start_positions[instance_id] = items.piece_for(str(instance_id)).position
	var baseline_nodes := 0
	var baseline_objects := 0
	var baseline_orphans := 0
	for cycle in range(1, 11):
		var released := items.begin_play()
		_check(released.is_empty(), "cycle %d: Play start has no stale captive" % cycle)
		_check(
			(
				is_equal_approx(items.grace_remaining, items.tuning.item_activation_grace_s)
				and not items.is_active()
			),
			"cycle %d: activation grace restarts at Play" % cycle
		)
		var wrong_phase := items.place(KAING_1X1, Vector2i(25, 5), 0, 0, clear_rects)
		_check(
			not bool(wrong_phase.allowed) and wrong_phase.code == "wrong_phase",
			"cycle %d: construction cannot be placed during Play" % cycle
		)
		var pieces_list: Array = items.pieces.keys()
		var emitter_id := str(pieces_list[0])
		var projectile_grants := items.budget.allocate(
			TransientBudget.Kind.PROJECTILE, _requests([emitter_id, "ghost_emitter"])
		)
		var bubble_grants := items.budget.allocate(
			TransientBudget.Kind.BUBBLE, _requests([emitter_id], "player_")
		)
		items.budget.register_captive(int(bubble_grants[0].handle), "captive_%d" % cycle)
		items.budget.allocate(TransientBudget.Kind.VFX, _requests([emitter_id]))
		_check(
			projectile_grants.size() == 2 and items.budget.total_count() == 4,
			"cycle %d: test-only transients are active" % cycle
		)
		for _frame in range(70 if cycle == 1 else 3):
			await physics_frame
		if cycle == 1:
			_check(items.is_active(), "cycle 1: construction becomes active after grace")
		var released_at_end := items.end_round()
		_check(
			(
				released_at_end == PackedStringArray(["captive_%d" % cycle])
				and items.budget.total_count() == 0
				and items.budget.captive_count() == 0
			),
			"cycle %d: round end clears transients and releases the captive" % cycle
		)
		_check(
			(
				items.construction_signature() == signature
				and items.support_tracker.surfaces.keys() == surface_ids
			),
			"cycle %d: only the intended construction persists" % cycle
		)
		var same_positions := true
		for instance_id in start_positions:
			same_positions = (
				same_positions
				and items.piece_for(str(instance_id)).position == start_positions[instance_id]
			)
		_check(same_positions, "cycle %d: static pieces return to their placed positions" % cycle)
		await process_frame
		if cycle == 1:
			baseline_nodes = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
			baseline_objects = int(Performance.get_monitor(Performance.OBJECT_COUNT))
			baseline_orphans = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	var final_nodes := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var final_objects := int(Performance.get_monitor(Performance.OBJECT_COUNT))
	var final_orphans := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	_row(
		"T04 ten cycles: node count",
		"stable at %d" % baseline_nodes,
		str(final_nodes),
		final_nodes == baseline_nodes
	)
	_row(
		"T04 ten cycles: object count",
		"stable at %d" % baseline_objects,
		str(final_objects),
		final_objects == baseline_objects
	)
	_row(
		"T04 ten cycles: orphan nodes",
		"stable at %d" % baseline_orphans,
		str(final_orphans),
		final_orphans == baseline_orphans
	)
	_check(_world_piece_count() == 3, "three construction pieces remain in the world")
	# Removal releases support, arena registration, emitter transients and the node.
	var remove_id := str(items.pieces.keys()[0])
	var removed_piece := items.piece_for(remove_id)
	items.begin_play()
	var blocked := items.remove(remove_id, "walis_cleanup")
	_check(
		not bool(blocked.allowed) and blocked.code == "wrong_phase",
		"construction is not removed during Play without force"
	)
	items.enter_place()
	var emitter_grant := items.budget.allocate(
		TransientBudget.Kind.BUBBLE, _requests([remove_id], "owner_")
	)
	items.budget.register_captive(int(emitter_grant[0].handle), "passenger")
	var removal := items.remove(remove_id, "walis_cleanup")
	_check(bool(removal.allowed), "Place removal succeeds")
	_check(
		(
			not items.support_tracker.surfaces.has(remove_id)
			and not bool(items.arena.can_remove_surface(remove_id).allowed)
			and items.budget.captive_count() == 0
			and items.budget.total_count() == 0
		),
		"removal invalidates support, unregisters construction and releases the emitter's captive"
	)
	await process_frame
	_check(not is_instance_valid(removed_piece), "removed piece node is freed")
	var replay_a := items.reset_match()
	_check(
		replay_a.is_empty() and items.persistent_count() == 0, "match reset empties construction"
	)
	_check(
		items.support_tracker.surfaces.keys().all(func(k): return not str(k).begins_with("build.")),
		"no construction surfaces remain registered"
	)
	# Same seed and script reproduce the same construction.
	var script_signature := []
	for _run_index in range(2):
		items.reset_match()
		items.place(KAING_2X3, Vector2i(12, 6), 1, 0, clear_rects)
		items.place(TULAY_4X1, Vector2i(18, 9), 0, 1, clear_rects)
		items.place(KAING_1X1, Vector2i(24, 4), 0, 2, clear_rects)
		script_signature.append(items.construction_signature())
	_check(
		script_signature[0] == script_signature[1] and not str(script_signature[0]).is_empty(),
		"identical placement script reproduces identical IDs and layout (seed 12345 run)"
	)
	items.reset_match()
	await physics_frame


# ---------------------------------------------------------------- real-physics helpers


func _stick(axis: float) -> void:
	room.input_router._stick_x[seat] = axis


func _key(key: int, down: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.keycode = key
	event.pressed = down
	room.input_router._handle_key(event)


func _frames(count: int) -> void:
	for _frame in range(count):
		await physics_frame


func _arrange(entries: Array[Dictionary]) -> Array[String]:
	var items := room.items
	items.reset_match()
	var ids: Array[String] = []
	var no_rects: Array[Rect2] = []
	for entry in entries:
		var result := items.place(
			str(entry.variant), entry.cell, int(entry.get("turns", 0)), 0, no_rects
		)
		_check(
			bool(result.allowed),
			"arrange %s at %s: %s" % [entry.variant, entry.cell, result.reason]
		)
		ids.append(str(result.get("instance_id", "")))
	items.begin_play()
	room.input_router.set_phase(LocalInputRouter.Phase.PLAY)
	return ids


func _put_actor_feet(feet: Vector2) -> void:
	_stick(0.0)
	actor.global_position = feet - Vector2(0.0, _half_height())
	actor.velocity = Vector2.ZERO
	actor.locomotion_velocity = Vector2.ZERO
	actor.external_velocity = Vector2.ZERO
	actor.coyote_remaining = 0.0
	actor.jump_buffer_remaining = 0.0
	actor.lifecycle.status = PlayerLifecycleState.Status.ACTIVE
	room.support_tracker.invalidate_actor(actor.support_actor_id)


func _feet_y() -> float:
	return actor.global_position.y + _half_height()


func _half_height() -> float:
	return room.tuning.body_height_wu * 0.5


func _support(line_y: float = 10000.0) -> Dictionary:
	return room.current_support_result(actor.support_actor_id, line_y)


func _supported_by(instance_id: String) -> bool:
	var result := _support()
	var contact := result.contact as SupportContact
	return contact != null and contact.surface_id == instance_id


func _settle(frames: int = 40) -> void:
	await _frames(frames)


func _stand_trial(
	case_id: String, variant: String, cell: Vector2i, turns: int, expected_top: float
) -> void:
	var ids := _arrange([{"variant": variant, "cell": cell, "turns": turns}])
	var piece := room.items.piece_for(ids[0])
	var rect := piece.footprint_world_rect()
	_put_actor_feet(Vector2(rect.get_center().x, rect.position.y - 120.0))
	await _settle()
	var result := _support(expected_top + 4.0)
	var contact := result.contact as SupportContact
	var passed: bool = (
		actor.is_on_floor()
		and absf(_feet_y() - expected_top) <= FEET_TOLERANCE_WU
		and bool(result.qualifies)
		and contact != null
		and contact.surface_id == ids[0]
		and contact.player_built
		and contact.eligibility == SupportSurfaceMetadata.Eligibility.ELIGIBLE
	)
	_row(
		case_id,
		"stands with feet at y=%.0f on %s, eligible player-built support" % [expected_top, ids[0]],
		"floor=%s feet=%.2f reason=%s" % [actor.is_on_floor(), _feet_y(), result.reason],
		passed
	)


func _test_kaing_physics() -> void:
	room.start_play()
	await _stand_trial("T09 Kaing 1x1 top", KAING_1X1, Vector2i(14, 8), 0, 512.0)
	await _stand_trial("T09 Kaing 2x3 top", KAING_2X3, Vector2i(14, 8), 0, 512.0)
	await _stand_trial("T09 Kaing rotated 3x2 top", KAING_2X3, Vector2i(14, 8), 1, 512.0)
	# Footprints and collider boundaries.
	var ids := _arrange(
		[
			{"variant": KAING_1X1, "cell": Vector2i(8, 6)},
			{"variant": KAING_2X3, "cell": Vector2i(14, 6)},
			{"variant": KAING_2X3, "cell": Vector2i(20, 6), "turns": 1},
		]
	)
	var sizes := [Vector2(64, 64), Vector2(128, 192), Vector2(192, 128)]
	for index in range(3):
		var piece := room.items.piece_for(ids[index])
		var shapes := _collision_shapes(piece)
		var shape_rect := shapes[0].shape.get_rect() if not shapes.is_empty() else Rect2()
		var passed: bool = (
			piece.footprint_world_rect().size == sizes[index]
			and shape_rect.size == sizes[index]
			and piece.occlusion_rects().size() == 1
			and piece.occlusion_rects()[0] == piece.footprint_world_rect()
			and shapes.size() == 1
		)
		_row(
			"T06 Kaing collider #%d" % index,
			"solid == footprint %s, one shape, no trigger, occlusion == solid" % sizes[index],
			(
				"footprint %s shape %s children %d"
				% [piece.footprint_world_rect().size, shape_rect.size, shapes.size()]
			),
			passed
		)
	# Wall: a 2x3 standing on the floor blocks the side; the chicken cannot pass through.
	ids = _arrange([{"variant": KAING_2X3, "cell": Vector2i(10, 12)}])
	_put_actor_feet(Vector2(1000.0, 960.0))
	await _settle(10)
	_stick(-1.0)
	var min_x := 10000.0
	for _frame in range(120):
		await physics_frame
		min_x = minf(min_x, actor.global_position.x)
	_stick(0.0)
	var side_contact_counted := false
	for contact in room.support_tracker.contacts_by_actor.get(actor.support_actor_id, []):
		if (contact as SupportContact).surface_id == ids[0]:
			side_contact_counted = true
	_row(
		"T09 Kaing solid side",
		"stopped at x>=796 (block right edge 768 + half body 28); side contact is not support",
		"min_x=%.2f side_counted=%s" % [min_x, side_contact_counted],
		min_x >= 795.0 and not side_contact_counted
	)
	# Route: a chicken beside a 1x1 foothold jumps and lands on it.
	ids = _arrange([{"variant": KAING_1X1, "cell": Vector2i(11, 14)}])
	_put_actor_feet(Vector2(798.0, 960.0))
	await _settle(10)
	_stick(0.0)
	_key(KEY_SPACE, true)
	await _frames(2)
	_stick(-1.0)
	await _frames(4)
	_stick(0.0)
	await _frames(20)
	_key(KEY_SPACE, false)
	var routed := false
	for _frame in range(90):
		await physics_frame
		if actor.is_on_floor() and _supported_by(ids[0]):
			routed = true
			break
	_row(
		"T09 Kaing route foothold",
		"chicken jumps from the floor onto the 1x1 foothold (top y=896)",
		"on_foothold=%s feet=%.2f" % [routed, _feet_y()],
		routed and absf(_feet_y() - 896.0) <= FEET_TOLERANCE_WU
	)
	# Head clearance below a Kaing underside: stops, never clips into the solid.
	ids = _arrange([{"variant": KAING_1X1, "cell": Vector2i(14, 8)}])
	_put_actor_feet(Vector2(928.0, 596.0 + room.tuning.body_height_wu))
	await _frames(1)
	actor.launch(Vector2(0.0, -1000.0))
	var highest_head := 10000.0
	var hit_ceiling := false
	for _frame in range(30):
		await physics_frame
		highest_head = minf(highest_head, actor.global_position.y - _half_height())
		hit_ceiling = hit_ceiling or actor.is_on_ceiling()
	_row(
		"T09 Kaing underside",
		"head stops at the solid underside y=576 with a ceiling contact",
		"highest_head=%.2f ceiling=%s" % [highest_head, hit_ceiling],
		highest_head >= 575.0 and hit_ceiling
	)
	# Removal: support disappears the same step, then the chicken falls.
	room.items.reset_match()
	ids = _arrange([{"variant": KAING_1X1, "cell": Vector2i(14, 8)}])
	_put_actor_feet(Vector2(928.0, 400.0))
	await _settle()
	var stood := _supported_by(ids[0])
	room.items.enter_place()
	room.items.remove(ids[0], "walis_cleanup")
	var immediate := _support()
	room.items.begin_play()
	await _settle(60)
	_row(
		"T08 Kaing removal",
		"was supported; support is gone on the removal step; chicken falls to a different surface",
		"stood=%s immediate=%s feet_after=%.2f" % [stood, immediate.reason, _feet_y()],
		stood and immediate.reason == "no support" and _feet_y() > 600.0
	)
	room.items.reset_match()


func _test_tulay_physics() -> void:
	room.start_play()
	var cell_floating := Vector2i(14, 8)
	# Landing from above onto the 4 wu strip.
	var ids := _arrange([{"variant": TULAY_4X1, "cell": cell_floating}])
	var piece := room.items.piece_for(ids[0])
	var strip := piece.strip_world_rects()
	var strip_ok: bool = (
		strip.size() == 1
		and strip[0].size == Vector2(256.0, 8.0)
		and piece.footprint_world_rect().size == Vector2(256.0, 64.0)
		and piece.occlusion_rects().is_empty()
	)
	_row(
		"T15 Tulay regions",
		"footprint 256x64, one-way strip 256x8 at the top, footprint != strip",
		"footprint %s strip %s" % [piece.footprint_world_rect().size, strip],
		strip_ok
	)
	var tulay_shapes := _collision_shapes(piece)
	_check(
		tulay_shapes.size() == 1 and tulay_shapes[0].one_way_collision,
		"T15 Tulay has exactly one one-way collision shape and no solid underside/sides"
	)
	_put_actor_feet(Vector2(1024.0, 380.0))
	await _settle()
	var landed := _support(520.0)
	var contact := landed.contact as SupportContact
	_row(
		"T18 Tulay land from above",
		"lands with feet y=512 on the strip; eligible player-built support",
		"floor=%s feet=%.2f reason=%s" % [actor.is_on_floor(), _feet_y(), landed.reason],
		(
			actor.is_on_floor()
			and absf(_feet_y() - 512.0) <= FEET_TOLERANCE_WU
			and bool(landed.qualifies)
			and contact != null
			and contact.surface_id == ids[0]
		)
	)
	# Jump off: leaves the surface and returns.
	_key(KEY_SPACE, true)
	var apex := 10000.0
	var left_surface := false
	for frame_index in range(70):
		await physics_frame
		if frame_index == 25:
			_key(KEY_SPACE, false)
		apex = minf(apex, _feet_y())
		left_surface = left_surface or not actor.is_on_floor()
	_row(
		"T18 Tulay jump off",
		"leaves the strip, rises about 192 wu, and lands back on it",
		"left=%s apex_feet=%.2f feet_after=%.2f" % [left_surface, apex, _feet_y()],
		left_surface and apex < 350.0 and absf(_feet_y() - 512.0) <= FEET_TOLERANCE_WU
	)
	# Walk off the edge: no longer supported by the Tulay.
	_stick(1.0)
	await _frames(70)
	_stick(0.0)
	await _settle(60)
	_row(
		"T18 Tulay walk off edge",
		"walks past x=1152 and lands on a different surface",
		(
			"x=%.2f feet=%.2f supported_by_tulay=%s"
			% [actor.global_position.x, _feet_y(), _supported_by(ids[0])]
		),
		actor.global_position.x > 1152.0 and not _supported_by(ids[0]) and _feet_y() > 600.0
	)
	# Rise from below through the strip, then land on top; never support while rising.
	ids = _arrange([{"variant": TULAY_4X1, "cell": Vector2i(22, 13)}])
	_put_actor_feet(Vector2(1480.0, 960.0))
	await _settle(15)
	_key(KEY_SPACE, true)
	var counted_while_rising := false
	var min_feet := 10000.0
	var passed_through := false
	for frame_index in range(40):
		await physics_frame
		min_feet = minf(min_feet, _feet_y())
		if _feet_y() < 828.0 and _supported_by(ids[0]):
			counted_while_rising = true
		if _feet_y() < 820.0:
			passed_through = true
	_key(KEY_SPACE, false)
	await _settle(60)
	_row(
		"T18 Tulay rise from below",
		"passes up through the strip, is never support while rising, then lands on top (y=832)",
		(
			"min_feet=%.2f passed=%s counted_rising=%s final_feet=%.2f supported=%s"
			% [min_feet, passed_through, counted_while_rising, _feet_y(), _supported_by(ids[0])]
		),
		(
			passed_through
			and not counted_while_rising
			and _supported_by(ids[0])
			and absf(_feet_y() - 832.0) <= FEET_TOLERANCE_WU
		)
	)
	# Sides and underside are non-solid: walking along a platform passes through the Tulay.
	ids = _arrange(
		[
			{"variant": KAING_2X3, "cell": Vector2i(10, 9), "turns": 1},
			{"variant": KAING_2X3, "cell": Vector2i(13, 9), "turns": 1},
			{"variant": TULAY_4X1, "cell": Vector2i(14, 8)},
		]
	)
	_put_actor_feet(Vector2(680.0, 576.0))
	await _settle(15)
	var on_platform := actor.is_on_floor() and absf(_feet_y() - 576.0) <= FEET_TOLERANCE_WU
	_stick(1.0)
	var max_x := 0.0
	for _frame in range(60):
		await physics_frame
		max_x = maxf(max_x, actor.global_position.x)
	_stick(0.0)
	_row(
		"T15 Tulay sides non-solid",
		"body overlapping the strip height walks through the footprint side (x passes 940)",
		"on_platform=%s max_x=%.2f" % [on_platform, max_x],
		on_platform and max_x > 940.0
	)
	# Fast fall at the 1800 wu/s cap onto the 8 wu strip.
	ids = _arrange([{"variant": TULAY_4X1, "cell": Vector2i(17, 12)}])
	var all_landed := true
	var worst_speed := 0.0
	for drop_x in [1104.0, 1160.0, 1220.0, 1280.0, 1328.0]:
		_put_actor_feet(Vector2(drop_x, 200.0))
		var peak := 0.0
		for _frame in range(90):
			await physics_frame
			peak = maxf(peak, actor.velocity.y)
		worst_speed = maxf(worst_speed, peak)
		var held := absf(_feet_y() - 768.0) <= FEET_TOLERANCE_WU and _supported_by(ids[0])
		all_landed = all_landed and held
	_row(
		"T18 Tulay strip at fall cap",
		"five drops reach ~1800 wu/s and all land on the 8 wu strip (feet y=768), none tunnel",
		"peak_speed=%.1f all_landed=%s" % [worst_speed, all_landed],
		all_landed and worst_speed >= 1700.0
	)
	# Ceiling: rising through a Tulay directly under the arena ceiling never clips.
	ids = _arrange([{"variant": TULAY_4X1, "cell": Vector2i(14, 3)}])
	_put_actor_feet(Vector2(1024.0, 210.0 + room.tuning.body_height_wu))
	await _frames(1)
	actor.launch(Vector2(0.0, -1600.0))
	var highest_head := 10000.0
	var saw_ceiling := false
	for _frame in range(25):
		await physics_frame
		highest_head = minf(highest_head, actor.global_position.y - _half_height())
		saw_ceiling = saw_ceiling or actor.is_on_ceiling()
	await _settle(60)
	_row(
		"T18 Tulay under ceiling",
		"passes the strip, stops at the arena ceiling (head y>=0), then lands on top (feet y=192)",
		"highest_head=%.2f ceiling=%s final_feet=%.2f" % [highest_head, saw_ceiling, _feet_y()],
		(
			highest_head >= -0.5
			and saw_ceiling
			and absf(_feet_y() - 192.0) <= FEET_TOLERANCE_WU
			and _supported_by(ids[0])
		)
	)
	# Support matrix: base floor, airborne.
	room.items.reset_match()
	room.items.begin_play()
	_put_actor_feet(Vector2(1120.0, 960.0))
	await _settle(30)
	var base_row := _support()
	_row(
		"T18 matrix: base floor",
		"base surface",
		str(base_row.reason),
		base_row.reason == "base surface"
	)
	_put_actor_feet(Vector2(1120.0, 400.0))
	await _frames(2)
	_row(
		"T18 matrix: airborne",
		"no support",
		str(_support().reason),
		_support().reason == "no support"
	)
	room.items.reset_match()


# ---------------------------------------------------------------- Item Lab flow


func _test_lab_flow() -> void:
	room.items.reset_match()
	room.enter_place()
	_check(
		room.input_router.phase == LocalInputRouter.Phase.PLACE and room.cursors.size() == 1,
		"Item Lab Place shows one cursor per joined seat"
	)
	var cursor: Dictionary = room.cursors[seat]
	var ghost := cursor.ghost as ItemGhost
	room.selected_variant_key = KAING_2X3
	room._refresh_rotation_support()
	room.move_cursor(seat, Vector2i(2, 0))
	_check(ghost.valid, "ghost is valid in open build space")
	room.move_cursor(seat, Vector2i(-20, 0))
	_check(
		not ghost.valid and ghost.reason.contains("build region"),
		"ghost reports an actionable reason when it leaves the valid region: %s" % ghost.reason
	)
	room.move_cursor(seat, Vector2i(20, 0))
	var rotated := room.rotate_cursor(seat)
	_check(rotated and cursor.turns == 1, "2x3 rotates to 3x2 in the lab")
	_check(
		ghost.footprint_rect.size == Vector2(192.0, 128.0), "rotated ghost footprint is 3x2 cells"
	)
	var result := room.confirm_cursor(seat)
	_check(bool(result.allowed) and room.items.persistent_count() == 1, "confirm places the piece")
	room.cycle_variant()
	_check(room.selected_variant_key == TULAY_4X1, "Variant button advances to the Tulay 4x1")
	_check(
		ghost.strip_rects.size() == 1 and ghost.strip_normals[0] == Vector2.UP,
		"Tulay ghost carries its one-way strip and an upward arrow"
	)
	_check(not room.rotate_cursor(seat), "Tulay has no usable rotation while vertical is gated")
	room.start_play()
	_check(
		(
			room.items.in_play
			and room.cursors.is_empty()
			and room.input_router.phase == LocalInputRouter.Phase.PLAY
		),
		"Play frees ghosts and starts item lifecycle"
	)
	room.reset_room()
	_check(
		room.items.persistent_count() == 1 and room.items.in_play,
		"Reset keeps construction and restarts the Play lifecycle"
	)
	room.clear_all_construction()
	_check(room.items.persistent_count() == 0, "Clear all removes construction")


func _test_catalog_and_harness() -> void:
	var harness := HARNESS_SCENE.instantiate() as FoundationHarness
	root.add_child(harness)
	await process_frame
	harness.selected_profile_id = "karera_slice"
	var catalog := harness._current_catalog()
	_check(catalog.entries.size() == 5, "karera_slice catalog lists exactly its five families")
	var normalized := catalog.normalized_weights("item")
	var equal_weights := normalized.size() == 5
	for family_id in [
		"build.hollow_blocks",
		"build.bamboo_bridge",
		"build.solid_block",
		"build.wood_box",
		"build.collapsing_block",
	]:
		equal_weights = (
			equal_weights and is_equal_approx(float(normalized.get(family_id, 0.0)), 0.2)
		)
	_check(equal_weights, "five families at weight 50 normalize to equal selection weights")
	var slice_errors := catalog.validate_profile(ProfileRegistry.get_profile("karera_slice"))
	var only_mode_gap := not slice_errors.is_empty()
	for message in slice_errors:
		if not message.contains("mode 'karera'"):
			only_mode_gap = false
	_check(
		only_mode_gap,
		(
			"karera_slice content and item pool now validate; only the unbuilt karera mode (P06) remains: %s"
			% [slice_errors]
		)
	)
	harness.selected_profile_id = "lagsanay_lab"
	var lagsanay_entries := harness._current_catalog().entries
	var lagsanay_family_ids: Array[String] = []
	for entry in lagsanay_entries:
		lagsanay_family_ids.append(str(entry.content_id))
	lagsanay_family_ids.sort()
	_check(
		(
			lagsanay_family_ids
			== [
				"build.bamboo_bridge",
				"build.hollow_blocks",
				"hazard.rail_trumpo",
				"hazard.slipper_launcher",
			]
		),
		"Lagsanay Lab lists only its mode-compatible first-batch construction and hazards"
	)
	harness.selected_profile_id = "kangaroo_contract_lab"
	var kangaroo_family_ids: Array[String] = []
	for entry in harness._current_catalog().entries:
		kangaroo_family_ids.append(str(entry.content_id))
	kangaroo_family_ids.sort()
	_check(
		kangaroo_family_ids == lagsanay_family_ids,
		"Kangaroo Contract Lab lists its reviewed construction and two direct hazards (P11)"
	)
	harness.selected_profile_id = "stack_lab"
	_check(
		harness._current_catalog().entries.is_empty(),
		"profiles that do not list seed families keep an empty item pool"
	)
	harness.selected_profile_id = "movement_room"
	_check(harness._current_catalog().entries.is_empty(), "movement_room lists no content")
	var family_rows := ItemDefinitions.load_all(GameplayTuning.new()).catalog_entries()
	var release_flags := false
	for entry in family_rows:
		release_flags = release_flags or entry.release_target
	_check(not release_flags, "no seed family is marked release_target before P13 and P12 gates")
	harness.queue_free()
	await process_frame


func _test_disabled_variant_geometry() -> void:
	# Defined-but-disabled variants and gated orientations: geometry and standing only.
	var saved_enabled := room.tuning.item_enabled_variants
	var saved_vertical := room.tuning.item_tulay_vertical_enabled
	room.tuning.item_enabled_variants = PackedStringArray(
		[KAING_1X1, KAING_1X3, KAING_2X3, TULAY_3X1, TULAY_4X1, TULAY_5X1]
	)
	room.tuning.item_tulay_vertical_enabled = true
	room.start_play()
	var cases: Array[Dictionary] = [
		{"id": "Kaing 1x3 column", "variant": KAING_1X3, "turns": 0, "size": Vector2(64, 192)},
		{"id": "Kaing 1x3 rotated 3x1", "variant": KAING_1X3, "turns": 1, "size": Vector2(192, 64)},
		{"id": "Tulay 3x1", "variant": TULAY_3X1, "turns": 0, "size": Vector2(192, 64)},
		{"id": "Tulay 5x1", "variant": TULAY_5X1, "turns": 0, "size": Vector2(320, 64)},
	]
	for entry in cases:
		var ids := _arrange(
			[{"variant": entry.variant, "cell": Vector2i(14, 8), "turns": entry.turns}]
		)
		var piece := room.items.piece_for(ids[0])
		var rect := piece.footprint_world_rect()
		_put_actor_feet(Vector2(rect.position.x + 32.0, 380.0))
		await _settle()
		var stands: bool = actor.is_on_floor() and _supported_by(ids[0])
		_row(
			"T09/T18 disabled variant: %s" % entry.id,
			"footprint %s and a chicken stands on its top at y=512" % entry.size,
			"footprint %s feet=%.2f stands=%s" % [rect.size, _feet_y(), stands],
			rect.size == entry.size and stands and absf(_feet_y() - 512.0) <= FEET_TOLERANCE_WU
		)
	var vertical_ids := _arrange([{"variant": TULAY_4X1, "cell": Vector2i(17, 6), "turns": 1}])
	var vertical := room.items.piece_for(vertical_ids[0])
	var strips := vertical.strip_world_rects()
	_row(
		"T15 gated vertical Tulay geometry",
		"1x4 footprint, 8 wu strip on the right edge, one-way normal pointing right",
		(
			"footprint %s strip %s normal %s"
			% [vertical.footprint_world_rect().size, strips, vertical.strip_normals()]
		),
		(
			vertical.footprint_world_rect().size == Vector2(64.0, 256.0)
			and strips.size() == 1
			and strips[0] == Rect2(Vector2(1144.0, 384.0), Vector2(8.0, 256.0))
			and vertical.strip_normals()[0] == Vector2.RIGHT
		)
	)
	room.tuning.item_enabled_variants = saved_enabled
	room.tuning.item_tulay_vertical_enabled = saved_vertical
	var back_to_disabled := room.items.validate_placement(KAING_1X3, Vector2i(14, 8), 0, [])
	_check(
		back_to_disabled.code == "variant_disabled",
		"restoring tuning disables the 1x3 column again"
	)
	room.items.reset_match()


func _test_wall_eligibility() -> void:
	# Uses the P02 wall extension's own probe; the extension itself stays disabled and unverified.
	var probe := WallContactProbe.new()
	room.start_play()
	var kaing_ids := _arrange([{"variant": KAING_2X3, "cell": Vector2i(10, 12)}])
	var kaing_metadata := room.support_tracker.surfaces[kaing_ids[0]] as SupportSurfaceMetadata
	_put_actor_feet(Vector2(796.0, 960.0))
	await _settle(10)
	var kaing_wall := probe.has_eligible_wall(
		actor, room.tuning, -1, room.tuning.wall_contact_probe_wu
	)
	_row(
		"T09 Kaing wall eligibility",
		"metadata ELIGIBLE and the wall probe finds the solid side",
		"metadata=%d probe=%s" % [kaing_metadata.wall_movement_eligibility, kaing_wall],
		(
			kaing_metadata.wall_movement_eligibility == SupportSurfaceMetadata.Eligibility.ELIGIBLE
			and kaing_wall
		)
	)
	# Wall movement is core: slide down a placed Kaing side, then kick away from it.
	_check(room.tuning.wall_movement_enabled, "wall movement is enabled in the Item Lab by default")
	_arrange([{"variant": KAING_2X3, "cell": Vector2i(22, 10)}])
	_put_actor_feet(Vector2(1408.0 - room.tuning.body_width_wu * 0.5 - 0.1, 728.0))
	await _frames(1)
	# Wall slide does not need input toward the wall. Holding toward it must not pull the chicken up.
	_stick(0.0)
	var slid := false
	var slide_speed := 0.0
	for _frame in range(20):
		await physics_frame
		if actor.wall_sliding and actor.wall_side == 1:
			slid = true
			slide_speed = maxf(slide_speed, actor.velocity.y)
	_key(KEY_SPACE, true)
	await _frames(3)
	var kicked_away: bool = actor.velocity.x < -100.0
	_key(KEY_SPACE, false)
	_stick(0.0)
	_row(
		"T09 Kaing wall slide and kick",
		"slides on the Kaing side at or below the configured cap, then a fresh jump kicks away",
		(
			"slid=%s speed=%.1f kicked_away=%s vx=%.1f"
			% [slid, slide_speed, kicked_away, actor.velocity.x]
		),
		slid and slide_speed <= room.tuning.wall_slide_fall_cap_wu_s + 1.0 and kicked_away
	)
	var tulay_ids := _arrange(
		[
			{"variant": KAING_2X3, "cell": Vector2i(10, 9), "turns": 1},
			{"variant": KAING_2X3, "cell": Vector2i(13, 9), "turns": 1},
			{"variant": TULAY_4X1, "cell": Vector2i(14, 8)},
		]
	)
	var tulay_metadata := room.support_tracker.surfaces[tulay_ids[2]] as SupportSurfaceMetadata
	_put_actor_feet(Vector2(872.0, 576.0))
	await _settle(10)
	var tulay_wall := probe.has_eligible_wall(
		actor, room.tuning, 1, room.tuning.wall_contact_probe_wu
	)
	_row(
		"T18 Tulay wall eligibility",
		"metadata INELIGIBLE and no wall at the strip's side",
		"metadata=%d probe=%s" % [tulay_metadata.wall_movement_eligibility, tulay_wall],
		(
			(
				tulay_metadata.wall_movement_eligibility
				== SupportSurfaceMetadata.Eligibility.INELIGIBLE
			)
			and not tulay_wall
		)
	)
	room.items.reset_match()


func _test_placeholder_previews_and_library() -> void:
	var expected_keys := [KAING_1X1, KAING_2X3, TULAY_4X1, SOLID_3X1, WOOD_BOX_2X2, COLLAPSE_1X1]
	var enabled_count := BlockCatalog.default_enabled_keys().size()
	_check(
		room.egg_previews.size() == enabled_count,
		(
			"one placeholder egg preview per enabled variant (%d of %d)"
			% [room.egg_previews.size(), enabled_count]
		)
	)
	var text_free := true
	for key in expected_keys:
		var egg := room.egg_previews.get(key) as ItemEggPreview
		if egg == null:
			text_free = false
			continue
		text_free = text_free and egg.variant_key == key and egg.get_child_count() == 0
	_check(text_free, "each egg shows its exact variant and carries no name or description text")
	var sample := room.egg_previews[KAING_2X3] as ItemEggPreview
	var first_phase := sample.loop_phase()
	var start_elapsed := sample.elapsed
	await create_timer(0.5).timeout
	var moved := absf(sample.loop_phase() - first_phase) > 0.05 or sample.elapsed > start_elapsed
	_check(moved, "egg animation advances over time")
	sample.elapsed = 1.0
	var mid := sample.loop_phase()
	sample.elapsed = 1.0 + ItemEggPreview.LOOP_SECONDS
	_check(is_equal_approx(mid, sample.loop_phase()), "egg animation loops with a fixed period")
	room.items.reset_match()
	room.enter_place()
	var identity_ok := true
	for key in expected_keys:
		var egg := room.egg_previews[key] as ItemEggPreview
		egg.claimed.emit(key)
		var cursor: Dictionary = room.cursors[seat]
		cursor.cell = Vector2i(14, 8)
		room._refresh_all_ghosts()
		var ghost := cursor.ghost as ItemGhost
		var found := room.definitions.find_variant(key)
		var variant := found.variant as ItemVariantDefinition
		var matches_shape := (
			ghost.footprint_rect.size == Vector2(variant.footprint_cells) * room.tuning.grid_cell_wu
		)
		var placed := room.confirm_cursor(seat)
		var piece_key: String = (
			(room.items.pieces[placed.instance_id] as PlacedItem).variant_key
			if bool(placed.allowed)
			else ""
		)
		identity_ok = (
			identity_ok
			and room.selected_variant_key == key
			and egg.selected
			and matches_shape
			and piece_key == key
		)
		room.items.reset_match()
		room.enter_place()
	_row(
		"T10/T19 egg to ghost to piece identity",
		"claiming an egg yields a ghost and a placed piece of the same variant and size",
		"identity_ok=%s" % identity_ok,
		identity_ok
	)
	var entries := room.library_entries()
	var fields_ok := entries.size() == room.definitions.families.size()
	for entry in entries:
		fields_ok = (
			fields_ok
			and not entry.display_name.is_empty()
			and not entry.sizes.is_empty()
			and not entry.placement.is_empty()
			and not entry.tell.is_empty()
			and not entry.counterplay.is_empty()
			and not entry.controls.is_empty()
			and not entry.modes_allowed.is_empty()
			and not entry.animation_variant_key.is_empty()
		)
	_row(
		"T12/T21 Library entry fields",
		"all families list name, sizes, placement, tell, counterplay, controls, modes, animation",
		"entries=%d fields_ok=%s" % [entries.size(), fields_ok],
		fields_ok
	)
	var tulay_entry := entries[0]
	for entry in entries:
		if entry.family_id == "build.bamboo_bridge":
			tulay_entry = entry
	var has_disabled_note := false
	for size_text in tulay_entry.sizes:
		has_disabled_note = has_disabled_note or size_text.contains("not enabled yet")
	_check(has_disabled_note, "Library marks defined-but-disabled sizes as not enabled yet")
	room.toggle_library()
	_check(
		room.library_visible and room._library_panel.visible and room._library_label.text != "",
		"Library panel opens with entry text"
	)
	room.set_release_filter(true)
	_check(
		(
			room.library_entries().is_empty()
			and room._library_label.text.contains("No release-enabled content")
		),
		"release filter hides content that is not release-enabled"
	)
	room.set_release_filter(false)
	room.toggle_library()
	room.items.reset_match()

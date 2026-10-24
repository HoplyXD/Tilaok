extends SceneTree

## P24: resource, variant-preview and provenance-state smoke checks for the three item-art families.

const FAMILIES := {
	"hazard.bubble_planter":
	{
		"pot": Vector2i(512, 512),
		"bubble": Vector2i(512, 512),
		"captive_icon": Vector2i(256, 256),
	},
	"hazard.rail_trumpo":
	{
		"rail_end": Vector2i(512, 512),
		"rail_mid": Vector2i(512, 512),
		"top": Vector2i(512, 512),
	},
	"hazard.parol_pulse":
	{
		"post_inactive": Vector2i(512, 512),
		"post_charge": Vector2i(512, 512),
		"post_active": Vector2i(512, 512),
		"beam_charge": Vector2i(512, 192),
		"beam_active": Vector2i(512, 192),
	},
}
const AUDIO_SLOTS := {
	"hazard.bubble_planter": ["sfx_emit", "sfx_capture", "sfx_pop"],
	"hazard.rail_trumpo": ["sfx_pause"],
	"hazard.parol_pulse": ["sfx_charge", "sfx_on"],
}

var checks := 0
var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_check_parol_post_joins()
	var tuning := GameplayTuning.new()
	ItemEnabledProfiles.apply(tuning, "items_lab")
	var definitions := ItemDefinitions.load_for_profile(tuning, "items_lab")
	for family_id in FAMILIES:
		var family := definitions.find_family(family_id)
		_check(family != null and family.visual_set != null, "%s visual set loads" % family_id)
		if family == null or family.visual_set == null:
			continue
		for slot_id in FAMILIES[family_id]:
			var expected_size: Vector2i = FAMILIES[family_id][slot_id]
			var slot := family.visual_set.get_slot(slot_id)
			_check(
				slot != null and not slot.placeholder,
				"%s/%s is registered artwork" % [family_id, slot_id]
			)
			if slot == null or slot.frames.is_empty() or slot.frames[0] == null:
				_check(false, "%s/%s texture resolves" % [family_id, slot_id])
				continue
			var texture := slot.frames[0]
			_check(
				Vector2i(texture.get_size()) == expected_size,
				"%s/%s dimensions are %s" % [family_id, slot_id, expected_size]
			)
			_check(
				not texture.resource_path.get_file().begins_with("PLACEHOLDER_"),
				"%s/%s points at its generated asset" % [family_id, slot_id]
			)
		for slot_id in AUDIO_SLOTS[family_id]:
			var slot := family.visual_set.get_slot(slot_id)
			_check(
				slot != null and slot.placeholder and slot.sound != null,
				"%s/%s placeholder audio remains unchanged" % [family_id, slot_id]
			)
	_check_launcher_prototype(definitions)
	for family in definitions.families:
		for variant in family.variants:
			for turns in variant.rotations:
				var preview := ItemEggPreview.new()
				var key := family.variant_key(variant)
				var configured := preview.configure(definitions, key, turns, tuning)
				var label := "%s/%s at %d degrees" % [family.family_id, variant.variant_id, turns * 90]
				_check(configured, "%s preview configures" % label)
				if configured:
					_check(_preview_fits_egg(preview, family, variant, turns, tuning), "%s stays in egg" % label)
				preview.free()
	_check(
		PlaceholderAudit.release_violations(definitions).is_empty(),
		"art replacement does not enable a release family"
	)
	print("P24_ITEM_ART checks=%d failures=%d" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _check_launcher_prototype(definitions: ItemDefinitions) -> void:
	var family := definitions.find_family("hazard.slipper_launcher")
	_check(family != null and family.visual_set != null, "launcher visual set loads")
	if family == null or family.visual_set == null:
		return
	for slot_id in ["launcher", "launcher_charge"]:
		var slot := family.visual_set.get_slot(slot_id)
		_check(slot != null and not slot.placeholder, "launcher/%s is art" % slot_id)
		if slot == null or slot.frames.is_empty() or slot.frames[0] == null:
			_check(false, "launcher/%s texture resolves" % slot_id)
			continue
		_check(
			Vector2i(slot.frames[0].get_size()) == Vector2i(64, 64),
			"launcher/%s matches the 64×64 footprint" % slot_id
		)


func _check(condition: bool, label: String) -> void:
	checks += 1
	if condition:
		print("PASS ", label)
	else:
		failures += 1
		push_error("FAIL " + label)


func _check_parol_post_joins() -> void:
	var horizontal_beam := Rect2(0.0, 0.0, 320.0, 12.0)
	var horizontal_from_post := ItemSilhouettePainter._join_parol_post_edges(
		Rect2(0.0, 0.0, 128.0, 12.0), horizontal_beam, 12.0
	)
	_check(
		is_equal_approx(horizontal_from_post.position.x, -8.0)
		and is_equal_approx(horizontal_from_post.end.x, 128.0),
		"horizontal Parol art reaches its post without crossing a clipped beam end"
	)
	var horizontal_to_post := ItemSilhouettePainter._join_parol_post_edges(
		Rect2(192.0, 0.0, 128.0, 12.0), horizontal_beam, 12.0
	)
	_check(
		is_equal_approx(horizontal_to_post.position.x, 192.0)
		and is_equal_approx(horizontal_to_post.end.x, 328.0),
		"horizontal Parol art reaches the far post without crossing a clipped beam end"
	)
	var vertical_beam := Rect2(0.0, 0.0, 12.0, 320.0)
	var vertical_from_post := ItemSilhouettePainter._join_parol_post_edges(
		Rect2(0.0, 0.0, 12.0, 128.0), vertical_beam, 12.0
	)
	_check(
		is_equal_approx(vertical_from_post.position.y, -8.0)
		and is_equal_approx(vertical_from_post.end.y, 128.0),
		"vertical Parol art reaches its post without crossing a clipped beam end"
	)
	var vertical_to_post := ItemSilhouettePainter._join_parol_post_edges(
		Rect2(0.0, 192.0, 12.0, 128.0), vertical_beam, 12.0
	)
	_check(
		is_equal_approx(vertical_to_post.position.y, 192.0)
		and is_equal_approx(vertical_to_post.end.y, 328.0),
		"vertical Parol art reaches the far post without crossing a clipped beam end"
	)


func _preview_fits_egg(
	preview: ItemEggPreview,
	family: ItemFamilyDefinition,
	variant: ItemVariantDefinition,
	turns: int,
	tuning: GameplayTuning
) -> bool:
	var center := preview.custom_minimum_size * 0.5 + Vector2(0.0, 6.0)
	var item_rect: Rect2
	if family.preview_silhouette == BlockCatalog.SCENE_PREVIEW:
		var bounds := ItemGeometry.rotated_size(Vector2(variant.footprint_cells), turns) * 64.0
		var fit := minf(ItemEggPreview.HAZARD_BOX_WU.x / bounds.x, ItemEggPreview.HAZARD_BOX_WU.y / bounds.y)
		var scale := minf(fit, ItemEggPreview.HAZARD_MAX_SCALE)
		item_rect = Rect2(center - bounds * scale * 0.5, bounds * scale)
	elif family.preview_silhouette in ItemEggPreview.BOX_SILHOUETTES:
		var cells := ItemGeometry.rotated_size(Vector2(variant.footprint_cells), turns)
		var scale := minf(
			ItemEggPreview.SILHOUETTE_BOX_WU / (cells.x * 32.0),
			ItemEggPreview.SILHOUETTE_BOX_WU / (cells.y * 32.0)
		)
		scale = minf(scale, 0.6)
		var bounds := cells * 32.0 * scale
		item_rect = Rect2(center - bounds * 0.5, bounds)
	else:
		var envelope := ItemSilhouettePainter.envelope(variant, turns, tuning)
		var fit := minf(
			ItemEggPreview.HAZARD_BOX_WU.x / envelope.size.x,
			ItemEggPreview.HAZARD_BOX_WU.y / envelope.size.y
		)
		var scale := minf(fit, ItemEggPreview.HAZARD_MAX_SCALE)
		var child := preview.get_node_or_null("PreviewCanvas") as Node2D
		if child == null:
			return false
		# Mimic the transform set by Control._draw before the child painter replaces its
		# local canvas transform. The node transform must retain this scale and offset.
		preview._draw_hazard_silhouette(center)
		if not is_equal_approx(child.scale.x, scale):
			return false
		item_rect = Rect2(child.position + envelope.position * scale, envelope.size * scale)
	var egg_rect := Rect2(Vector2.ZERO, preview.custom_minimum_size)
	return egg_rect.grow(-2.0).encloses(item_rect)

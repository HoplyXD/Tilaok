extends SceneTree

## Every item-library variant and supported rotation must remain inside its egg card.

var checks := 0
var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var tuning := GameplayTuning.new()
	ItemEnabledProfiles.apply(tuning, "items_lab")
	var definitions := ItemDefinitions.load_for_profile(tuning, "items_lab")
	for family in definitions.families:
		for variant in family.variants:
			for turns in variant.rotations:
				var preview := ItemEggPreview.new()
				var configured := preview.configure(
					definitions, family.variant_key(variant), turns, tuning
				)
				var label := "%s/%s turn %d" % [family.family_id, variant.variant_id, turns]
				_check(configured, "%s configures" % label)
				if configured:
					_check(_fits_egg(preview, family, variant, turns, tuning), "%s fits egg" % label)
				preview.free()
	print("EGG_PREVIEW_FIT checks=%d failures=%d" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _fits_egg(
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
		preview._draw_hazard_silhouette(center)
		if not is_equal_approx(child.scale.x, scale):
			return false
		item_rect = Rect2(child.position + envelope.position * scale, envelope.size * scale)
	return Rect2(Vector2.ZERO, preview.custom_minimum_size).grow(-2.0).encloses(item_rect)


func _check(condition: bool, label: String) -> void:
	checks += 1
	if condition:
		print("PASS ", label)
	else:
		failures += 1
		push_error("FAIL " + label)

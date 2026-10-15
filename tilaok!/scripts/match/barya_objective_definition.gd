class_name BaryaObjectiveDefinition
extends RefCounted

## A round-scoped pickup definition. This ID is deliberately outside BlockCatalog and ItemManager.
const VARIANT_ID := "round_objective.barya.coin_1x1"
const DISPLAY_NAME := "Barya • 1×1"
const FOOTPRINT_CELLS := Vector2i.ONE
const SCORE_UNITS := 4


static func is_variant(key: String) -> bool:
	return key == VARIANT_ID

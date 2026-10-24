class_name BaryaOfferPolicy
extends RefCounted


static func eligible(
	enabled: bool, main_challenge: int, karera_value: int, sudden_death: bool
) -> bool:
	return (
		enabled
		and not sudden_death
		and main_challenge in [karera_value, EventSchedule.Challenge.KANGAROO]
	)


static func roll_offer(
	enabled: bool,
	main_challenge: int,
	karera_value: int,
	sudden_death: bool,
	egg_pool: Array[Dictionary],
	probability: float,
	stream: RandomNumberGenerator
) -> int:
	if not eligible(enabled, main_challenge, karera_value, sudden_death):
		return -1
	return replace_random_egg(egg_pool, probability, stream)


## Replaces one existing egg in place. A disabled, ineligible, empty or zero-chance offer leaves
## both the pool and the dedicated RNG untouched. The regular egg stream is never consulted.
static func replace_random_egg(
	egg_pool: Array[Dictionary], probability: float, stream: RandomNumberGenerator
) -> int:
	if egg_pool.is_empty() or stream == null:
		return -1
	for index in egg_pool.size():
		if BaryaObjectiveDefinition.is_variant(str(egg_pool[index].get("variant_key", ""))):
			return index
	var chance := clampf(probability, 0.0, 1.0)
	if chance <= 0.0:
		return -1
	if chance < 1.0 and stream.randf() >= chance:
		return -1
	var slot := stream.randi_range(0, egg_pool.size() - 1)
	var offer: Dictionary = egg_pool[slot].duplicate(true)
	offer["variant_key"] = BaryaObjectiveDefinition.VARIANT_ID
	offer["round_objective"] = true
	egg_pool[slot] = offer
	return slot

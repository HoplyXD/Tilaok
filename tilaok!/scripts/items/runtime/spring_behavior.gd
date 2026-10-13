class_name SpringBehavior
extends ItemBehavior

## Gulong Talon. The launch face reports contact; the director applies cooldown, boost and the
## launch in one stable order. The body is a plain solid, so a launch never creates support.

const COMPRESS_DECAY_S := 0.25

var compress := 0.0
var launch_count := 0


func reset_to_start() -> void:
	super.reset_to_start()
	compress = 0.0
	launch_count = 0


func launch_normal() -> Vector2:
	return ItemGeometry.rotate_vector(Vector2.UP, turns)


func step(ctx: ItemStepContext) -> void:
	advance(ctx.dt)
	compress = maxf(0.0, compress - ctx.dt / COMPRESS_DECAY_S)
	var normal := launch_normal()
	for face in world_rects(ItemRegionSpec.Kind.TRIGGER):
		for actor in ctx.actors:
			if not ctx.is_hazard_target(actor):
				continue
			if SweptContact.face_contact(
				ctx.body_of(actor), face, normal, tuning.item_spring_contact_probe_wu
			):
				ctx.request_launch(actor.seat_index, item_id, normal)


func preview_at(seconds: float) -> void:
	elapsed = seconds
	compress = clampf(1.0 - fposmod(seconds, 2.0) / 0.4, 0.0, 1.0)


func on_launched() -> void:
	compress = 1.0
	launch_count += 1
	pending_sounds.append("sfx_launch")


func readout() -> Dictionary:
	return {
		"elapsed": elapsed,
		"compress": compress,
		"normal": launch_normal(),
		"launches": launch_count,
		"state": "compressed" if compress > 0.05 else "ready",
	}

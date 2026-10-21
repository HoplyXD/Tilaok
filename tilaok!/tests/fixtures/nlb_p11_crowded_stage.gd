class_name NlbP11CrowdedStage
extends RefCounted
## NLB-P11-T01 networked crowded-stage fixture (authored, never run).
##
## Fills the host's authoritative stage with the maximum persistent pieces the wire allows and
## lets the item emitters raise live transients toward their per-kind wire caps, so a ten-minute
## profile exercises the worst-case state/snapshot load. It works only through the production
## authority path (`room.items.place` on the host in the build phase); clients receive the stage
## through the normal terrain commit / snapshot machinery, never through a fake. The caps are read
## from NetworkMatchCodec, never copied. The fixture REPORTS what it reached (`census`); it does
## not assume the caps were hit, because emitters ramp up during play.
##
## Enabled by `--nlb-p11-fixture` (development builds only, via NlbBuildFlags). Fixed seed, fixed
## map, deterministic placement order, so two runs build the same stage.

const SEED := 11011
const PERSISTENT_TARGET := NetworkMatchCodec.MAX_STAGE_ENTITIES
const MAP_ID := "default"
## Structural fillers first so every emitter has somewhere to stand; the emitter variants cycle in
## so launchers (projectiles), rails/springs (movers) and any bubble/blast emitters all appear.
const STRUCTURAL: PackedStringArray = [
	"build.hollow_blocks.cell_1x1",
	"build.bamboo_bridge.span_4x1",
	"build.solid_block.slab_3x1",
	"build.wood_box.box_2x2",
]
const EMITTERS: PackedStringArray = [
	"hazard.slipper_launcher.lane_4x1",
	"hazard.rail_trumpo.rail_4x1",
	"move.tire_spring.tire_2x2",
]


static func enabled() -> bool:
	return NlbBuildFlags.dev_flag_present(NlbBuildFlags.FIXTURE_FLAG)


## Places up to PERSISTENT_TARGET pieces in the build phase. Returns {placed, attempts, seed}.
static func populate(room: P12ScheduledMatchRoom) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var placed := 0
	var attempts := 0
	var index := 0
	# Walk the stage grid row by row (same walk as the offline crowd helpers) with a seeded phase.
	var phase := rng.randi_range(0, EMITTERS.size() - 1)
	for row in range(3, 17, 2):
		for column in range(1, 62, 2):
			if placed >= PERSISTENT_TARGET:
				return {"placed": placed, "attempts": attempts, "seed": SEED}
			var variant := (
				EMITTERS[(index + phase) % EMITTERS.size()]
				if index % 3 == 0
				else STRUCTURAL[index % STRUCTURAL.size()]
			)
			index += 1
			attempts += 1
			var result := room.items.place(variant, Vector2i(column, row), 0, 0)
			if bool(result.get("allowed", false)):
				placed += 1
	return {"placed": placed, "attempts": attempts, "seed": SEED}


## Live reach versus the wire caps: {persistent_cap, transient_<kind>: [live, cap], ...}.
static func census(room: P12ScheduledMatchRoom) -> Dictionary:
	var live := {}
	for transient in room.network_transient_states():
		var kind := int(transient.transient_kind)
		live[kind] = int(live.get(kind, 0)) + 1
	var report := {"persistent_cap": PERSISTENT_TARGET}
	var names := {
		NetworkMatchCodec.TRANSIENT_PROJECTILE: "projectile",
		NetworkMatchCodec.TRANSIENT_BUBBLE: "bubble",
		NetworkMatchCodec.TRANSIENT_BLAST: "blast",
		NetworkMatchCodec.TRANSIENT_MOVER: "mover",
	}
	for kind in NetworkMatchCodec.TRANSIENT_CAPS:
		report["transient_%s" % names[kind]] = [
			int(live.get(kind, 0)), int(NetworkMatchCodec.TRANSIENT_CAPS[kind])
		]
	return report


## One parseable line for logs: NLB_P11_FIXTURE placed=48 projectile=3/16 ...
static func census_line(room: P12ScheduledMatchRoom, placed: int) -> String:
	var line := "NLB_P11_FIXTURE placed=%d/%d seed=%d" % [placed, PERSISTENT_TARGET, SEED]
	var report := census(room)
	for key in report:
		if str(key).begins_with("transient_"):
			line += " %s=%d/%d" % [str(key).trim_prefix("transient_"), report[key][0], report[key][1]]
	return line

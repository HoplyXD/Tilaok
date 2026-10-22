# gdlint: disable=max-returns,max-public-methods
class_name NLBLiveCompatibilityMatrix
extends RefCounted

## NLB-P07-T01: the one authoritative content table for the networked live-build route
## (`--match-route=network_live_build`). It replaces the P05/P06 hard-coded variant allowlist.
## Pugad dealing, the event schedule, the stack pool, the map/start gate, per-intent checks, the
## compatibility manifest digest, the matrix document and the P07 tests all read it.
##
## Cells are factored on four axes instead of one cross product:
## - "map:<map id>" for every MapCatalog map;
## - "round:<mode id>" for every Main, stack and sudden death (DiagnosticContentCatalog.MODES),
##   plus the Kangaroo commands "round:kangaroo#freeze|rising|hug";
## - "item:<family.variant>@<mode>" for every catalog variant in each mode its family allows
##   (out-of-family modes are never dealt offline either), plus Barya in Karera;
## - "life:<id>" for cross-cutting live behavior that other cells require.
##
## Default deny: an id that is not in the table, catalog content without a rule, a DISABLED cell
## and any cell whose `requires` closure is not selectable are never selectable. VERIFIED cells are
## selectable. ENGINEERING cells (live rule authored, network verification pending) are selectable
## only on a PC host started with OVERRIDE_FLAG, which is never the default. No cell is VERIFIED
## until its own P07-T03 evidence passes.

const MATRIX_VERSION := 1
## Minimum wire/content identity of every cell in this table (contract v1.6).
const MIN_PROTOCOL := "1.2/schema6/0x07FF"
const MIN_CONTENT := "tilaok-nlb-p09-2026-10-21"
## Host-only development switch. Ignored on Android and on release export templates.
const OVERRIDE_FLAG := "--nlb-unverified-content"
const MATRIX_DOC := "docs/evidence/nlb/p07/compatibility-matrix.md"

const STATUS_DISABLED := "DISABLED"
const STATUS_ENGINEERING := "ENGINEERING"
const STATUS_VERIFIED := "VERIFIED"
const STATUSES: PackedStringArray = [STATUS_DISABLED, STATUS_ENGINEERING, STATUS_VERIFIED]

const AXIS_MAP := "map"
const AXIS_ROUND := "round"
const AXIS_ITEM := "item"
const AXIS_LIFE := "life"

## Player-readable text for each reason key (host lobby list and start gate).
const REASON_TEXT := {
	"OK": "Verified for networked live play.",
	"PENDING_NETWORK_VERIFICATION":
	"Not verified on the network yet; only a development host can turn it on.",
	"NOT_IN_MAIN_GAME": "Not part of the main game.",
	"DISABLED_BY_DEFAULT": "Turned off in the main game's item pool.",
	"NO_LIVE_RULE": "Has no networked live-play rule.",
	"TRANSIENT_UNREPLICATED": "Its moving effects are not sent to other devices yet.",
	"DEPENDENCY_DISABLED": "Needs another live feature that is turned off.",
	"NOT_IMPLEMENTED": "Not built yet.",
	"UNKNOWN_CONTENT": "New or unknown content stays off until it is reviewed.",
}

const BARYA_KEY := "round_objective.barya.coin_1x1"
const BARYA_CELL := "item:round_objective.barya.coin_1x1@karera"
const KANGAROO_COMMANDS: PackedStringArray = ["freeze", "rising", "hug"]

## Cross-cutting live behavior (NETWORKED_LIVE_BUILD.md §6.2 rows that are not one item).
const LIFE_RULES := {
	"persistent_terrain": {"status": STATUS_ENGINEERING, "requires": []},
	"snapshot_recovery": {"status": STATUS_ENGINEERING, "requires": []},
	"round_end_pending_edits": {"status": STATUS_ENGINEERING, "requires": []},
	"live_transients": {"status": STATUS_ENGINEERING, "requires": ["life:snapshot_recovery"]},
	"map_transition":
	{
		"status": STATUS_ENGINEERING,
		"requires": ["life:snapshot_recovery", "life:persistent_terrain"]
	},
	"barya_lifecycle":
	{
		"status": STATUS_ENGINEERING,
		"requires": ["life:round_end_pending_edits", "life:snapshot_recovery"]
	},
	# NLB-P08 (contract v1.5): host pause, phone lifecycle and seat reservation/reclaim.
	"host_pause": {"status": STATUS_ENGINEERING, "requires": ["life:snapshot_recovery"]},
	"client_lifecycle": {"status": STATUS_ENGINEERING, "requires": ["life:snapshot_recovery"]},
	"seat_reclaim":
	{
		"status": STATUS_ENGINEERING,
		"requires": ["life:client_lifecycle", "life:host_pause", "life:snapshot_recovery"]
	},
	# NLB-P09 (contract v1.6): replicated results, in-place replay re-key, host loss.
	"results_replication": {"status": STATUS_ENGINEERING, "requires": ["life:snapshot_recovery"]},
	"replay_rekey":
	{
		"status": STATUS_ENGINEERING,
		"requires": ["life:results_replication", "life:seat_reclaim"]
	},
	"host_loss": {"status": STATUS_ENGINEERING, "requires": ["life:results_replication"]},
}

## The tutorial is the guided offline onboarding; it has no networked live rule.
const MAP_RULES := {
	"default": {"status": STATUS_ENGINEERING, "requires": ["life:map_transition"]},
	"sample_map": {"status": STATUS_ENGINEERING, "requires": ["life:map_transition"]},
	"Basic Map": {"status": STATUS_ENGINEERING, "requires": ["life:map_transition"]},
	"tutorial": {"status": STATUS_DISABLED, "reason": "NO_LIVE_RULE", "requires": []},
}

## Kangaroo needs all three commands: disabling one cannot silently change the event's meaning.
const ROUND_RULES := {
	"karera": {"status": STATUS_ENGINEERING, "requires": ["life:round_end_pending_edits"]},
	"lagsanay": {"status": STATUS_ENGINEERING, "requires": ["life:round_end_pending_edits"]},
	"kangaroo#freeze": {"status": STATUS_ENGINEERING, "requires": []},
	"kangaroo#rising": {"status": STATUS_ENGINEERING, "requires": ["life:persistent_terrain"]},
	"kangaroo#hug": {"status": STATUS_ENGINEERING, "requires": []},
	"kangaroo":
	{
		"status": STATUS_ENGINEERING,
		"requires":
		[
			"life:round_end_pending_edits",
			"round:kangaroo#freeze",
			"round:kangaroo#rising",
			"round:kangaroo#hug"
		]
	},
	"stack_karera_lagsanay":
	{"status": STATUS_ENGINEERING, "requires": ["round:karera", "round:lagsanay"]},
	"stack_karera_kangaroo":
	{"status": STATUS_ENGINEERING, "requires": ["round:karera", "round:kangaroo"]},
	"stack_kangaroo_lagsanay":
	{"status": STATUS_ENGINEERING, "requires": ["round:kangaroo", "round:lagsanay"]},
	"sudden_death_lagsanay":
	{
		"status": STATUS_ENGINEERING,
		"requires": ["round:lagsanay", "life:persistent_terrain", "life:results_replication"]
	},
}

## One rule per catalog family; every allowed mode of every variant becomes a cell with it.
## `offline_live` names the variants of the opt-in OFFLINE live route (the P05 slice), so that
## route keeps its exact pool without a second list. Catalog flags still apply: a variant that is
## not enabled_by_default is DISABLED/DISABLED_BY_DEFAULT whatever its family rule says.
const FAMILY_RULES := {
	"build.hollow_blocks":
	{
		"status": STATUS_ENGINEERING,
		"requires": ["life:persistent_terrain"],
		"offline_live": ["cell_1x1", "stack_2x3"]
	},
	"build.bamboo_bridge":
	{
		"status": STATUS_ENGINEERING,
		"requires": ["life:persistent_terrain"],
		"offline_live": ["span_4x1"]
	},
	"build.solid_block": {"status": STATUS_ENGINEERING, "requires": ["life:persistent_terrain"]},
	"build.house_stairs": {"status": STATUS_ENGINEERING, "requires": ["life:persistent_terrain"]},
	"modifier.sorbetes_ice":
	{"status": STATUS_ENGINEERING, "requires": ["life:persistent_terrain"]},
	"build.wood_box": {"status": STATUS_ENGINEERING, "requires": ["life:persistent_terrain"]},
	"build.collapsing_block":
	{"status": STATUS_ENGINEERING, "requires": ["life:persistent_terrain", "life:live_transients"]},
	"move.tire_spring": {"status": STATUS_ENGINEERING, "requires": ["life:persistent_terrain"]},
	"block.spikes": {"status": STATUS_ENGINEERING, "requires": ["life:persistent_terrain"]},
	"hazard.toy_burr_strip":
	{"status": STATUS_ENGINEERING, "requires": ["life:persistent_terrain"]},
	"hazard.rail_trumpo":
	{"status": STATUS_ENGINEERING, "requires": ["life:persistent_terrain", "life:live_transients"]},
	"hazard.parol_pulse":
	{"status": STATUS_ENGINEERING, "requires": ["life:persistent_terrain", "life:live_transients"]},
	"hazard.slipper_launcher":
	{"status": STATUS_ENGINEERING, "requires": ["life:persistent_terrain", "life:live_transients"]},
	"block.cannon":
	{"status": STATUS_ENGINEERING, "requires": ["life:persistent_terrain", "life:live_transients"]},
	"hazard.bubble_planter":
	{"status": STATUS_ENGINEERING, "requires": ["life:persistent_terrain", "life:live_transients"]},
	"utility.walis_cleanup":
	{"status": STATUS_ENGINEERING, "requires": ["life:persistent_terrain"]},
}

## Round objectives are not catalog blocks (BaryaObjectiveDefinition), so they are listed here.
const OBJECTIVE_RULES := {
	BARYA_CELL: {"status": STATUS_ENGINEERING, "requires": ["life:barya_lifecycle"]},
}

## Per-cell evidence references; a VERIFIED cell must have one. Empty until P07-T03 runs.
const EVIDENCE := {}

static var _cells_cache: Dictionary = {}


## Clears the cached table (tests, or after BlockCatalog/MapCatalog reload).
static func reload() -> void:
	_cells_cache.clear()


## Host-only, never default, never on Android or a release export template.
static func override_requested(arguments: PackedStringArray) -> bool:
	if OS.has_feature("android") or not NlbBuildFlags.dev_flags_allowed():
		return false
	return arguments.has(OVERRIDE_FLAG)


## {cell id: cell} for every cell. A cell is {id, axis, status, reason, text, min_protocol,
## min_content, requires, evidence, offline_live}.
static func cells() -> Dictionary:
	if not _cells_cache.is_empty():
		return _cells_cache
	var table := {}
	for life_id in LIFE_RULES:
		_add(table, "life:%s" % life_id, AXIS_LIFE, LIFE_RULES[life_id])
	for map_id in MapCatalog.ids():
		_add(table, "map:%s" % map_id, AXIS_MAP, MAP_RULES.get(map_id, {}))
	for round_id in ROUND_RULES:
		_add(table, "round:%s" % round_id, AXIS_ROUND, ROUND_RULES[round_id])
	for mode_id in DiagnosticContentCatalog.MODES:
		if not table.has("round:%s" % mode_id):
			_add(table, "round:%s" % mode_id, AXIS_ROUND, {})
	for family_variant in BlockCatalog.scan().families:
		var family := family_variant as ItemFamilyDefinition
		if family == null:
			continue
		var rule: Dictionary = FAMILY_RULES.get(family.family_id, {})
		var offline: Array = rule.get("offline_live", [])
		for variant in family.variants:
			if variant == null:
				continue
			for mode_id in family.modes_allowed:
				var cell_rule := rule.duplicate(true)
				if not rule.is_empty() and not family.in_main_game:
					cell_rule = {"status": STATUS_DISABLED, "reason": "NOT_IN_MAIN_GAME"}
				elif not rule.is_empty() and not variant.enabled_by_default:
					cell_rule = {"status": STATUS_DISABLED, "reason": "DISABLED_BY_DEFAULT"}
				var cell_id := item_cell_id(family.variant_key(variant), mode_id)
				_add(table, cell_id, AXIS_ITEM, cell_rule)
				table[cell_id]["offline_live"] = (
					offline.has(variant.variant_id)
					and family.in_main_game
					and variant.enabled_by_default
				)
	for objective_id in OBJECTIVE_RULES:
		_add(table, objective_id, AXIS_ITEM, OBJECTIVE_RULES[objective_id])
	_cells_cache = table
	return table


static func _add(table: Dictionary, cell_id: String, axis: String, rule: Dictionary) -> void:
	var status := str(rule.get("status", STATUS_DISABLED))
	var reason := str(rule.get("reason", ""))
	if rule.is_empty():
		reason = "UNKNOWN_CONTENT"
	elif reason.is_empty():
		reason = "OK" if status == STATUS_VERIFIED else "PENDING_NETWORK_VERIFICATION"
	var requires: Array[String] = []
	for required in rule.get("requires", []):
		requires.append(str(required))
	table[cell_id] = {
		"id": cell_id,
		"axis": axis,
		"status": status,
		"reason": reason,
		"text": str(REASON_TEXT.get(reason, reason)),
		"min_protocol": MIN_PROTOCOL,
		"min_content": MIN_CONTENT,
		"requires": requires,
		"evidence": str(EVIDENCE.get(cell_id, "")),
		"offline_live": false,
	}


static func item_cell_id(variant_key: String, mode_id: String) -> String:
	return "item:%s@%s" % [variant_key, mode_id]


static func map_cell_id(map_id: String) -> String:
	return "map:%s" % map_id


## The round cell for a schedule entry (EventSchedule.lock_round / sudden_death_entry).
static func round_cell_id(entry: Dictionary) -> String:
	if entry.is_empty():
		return ""
	if bool(entry.get("sudden_death", false)):
		return "round:sudden_death_lagsanay"
	var main := EventSchedule.mode_id(int(entry.get("main", EventSchedule.Challenge.NONE)))
	var twist := int(entry.get("twist", EventSchedule.Challenge.NONE))
	if twist == EventSchedule.Challenge.NONE:
		return "round:%s" % main
	return "round:stack_%s_%s" % [main, EventSchedule.mode_id(twist)]


## {selectable, status, reason, text, blocked_by}. Unknown ids are DISABLED/UNKNOWN_CONTENT.
static func resolve(cell_id: String, unverified_override: bool = false) -> Dictionary:
	return _resolve(cells(), cell_id, unverified_override, [])


static func _resolve(
	table: Dictionary, cell_id: String, unverified_override: bool, path: Array
) -> Dictionary:
	if not table.has(cell_id):
		return _verdict(false, STATUS_DISABLED, "UNKNOWN_CONTENT", cell_id)
	var cell: Dictionary = table[cell_id]
	if path.has(cell_id):
		return _verdict(false, str(cell.status), "DEPENDENCY_DISABLED", cell_id)
	if str(cell.status) == STATUS_DISABLED or not STATUSES.has(str(cell.status)):
		return _verdict(false, STATUS_DISABLED, str(cell.reason), cell_id)
	var next_path := path.duplicate()
	next_path.append(cell_id)
	for required in cell.requires:
		var dependency := _resolve(table, str(required), unverified_override, next_path)
		if not bool(dependency.selectable):
			return _verdict(
				false, str(cell.status), "DEPENDENCY_DISABLED", str(dependency.blocked_by)
			)
	if str(cell.status) == STATUS_VERIFIED:
		return _verdict(true, STATUS_VERIFIED, "OK", "")
	return _verdict(unverified_override, STATUS_ENGINEERING, str(cell.reason), cell_id)


static func _verdict(
	is_selectable: bool, status: String, reason: String, blocked_by: String
) -> Dictionary:
	return {
		"selectable": is_selectable,
		"status": status,
		"reason": reason,
		"text": str(REASON_TEXT.get(reason, reason)),
		"blocked_by": "" if is_selectable else blocked_by,
	}


static func selectable(cell_id: String, unverified_override: bool = false) -> bool:
	return bool(resolve(cell_id, unverified_override).selectable)


## Variant keys the networked live route may deal in a round whose active modes are `mode_ids`:
## every mode's item cell must be selectable. Empty modes deal nothing (fail closed).
static func live_variants(
	mode_ids: PackedStringArray, unverified_override: bool = false
) -> PackedStringArray:
	var keys := PackedStringArray()
	if mode_ids.is_empty():
		return keys
	for family in BlockCatalog.families(BlockCatalog.SET_MAIN):
		for variant in (family as ItemFamilyDefinition).variants:
			var key := (family as ItemFamilyDefinition).variant_key(variant)
			var allowed := true
			for mode_id in mode_ids:
				if not selectable(item_cell_id(key, mode_id), unverified_override):
					allowed = false
					break
			if allowed:
				keys.append(key)
	return keys


## The opt-in OFFLINE live route's pool (the P05 slice), from the same table.
static func offline_live_variants() -> PackedStringArray:
	var keys := PackedStringArray()
	for family in BlockCatalog.families(BlockCatalog.SET_MAIN):
		for variant in (family as ItemFamilyDefinition).variants:
			var key := (family as ItemFamilyDefinition).variant_key(variant)
			for mode_id in (family as ItemFamilyDefinition).modes_allowed:
				var cell: Dictionary = cells().get(item_cell_id(key, mode_id), {})
				if bool(cell.get("offline_live", false)) and not keys.has(key):
					keys.append(key)
	return keys


## Main Challenges the networked live schedule may draw.
static func available_modes(unverified_override: bool = false) -> Array[int]:
	var modes: Array[int] = []
	for challenge in [
		EventSchedule.Challenge.KARERA,
		EventSchedule.Challenge.LAGSANAY,
		EventSchedule.Challenge.KANGAROO
	]:
		if selectable("round:%s" % EventSchedule.mode_id(challenge), unverified_override):
			modes.append(challenge)
	return modes


## The enabled EventSchedule stack rows whose stack cell is selectable.
static func schedule_pairs(unverified_override: bool = false) -> Array[Dictionary]:
	var pairs: Array[Dictionary] = []
	for row in EventSchedule.enabled_pairs():
		var entry := {"main": int(row.main), "twist": int(row.twist)}
		if selectable(round_cell_id(entry), unverified_override):
			pairs.append(row)
	return pairs


## "" when a networked live match may start on `map_id`, else the first readable refusal.
static func start_gate(map_id: String, unverified_override: bool = false) -> String:
	var errors := validate()
	if not errors.is_empty():
		return "The live content table is invalid: %s" % errors[0]
	var map_verdict := resolve(map_cell_id(map_id), unverified_override)
	if not bool(map_verdict.selectable):
		return _refusal("Map '%s'" % map_id, map_verdict)
	# Round 1 is Karera; rounds 4/8/12 and sudden death are Lagsanay (EventSchedule.GUARANTEED).
	for round_id in ["round:karera", "round:lagsanay", "round:sudden_death_lagsanay"]:
		var verdict := resolve(round_id, unverified_override)
		if not bool(verdict.selectable):
			return _refusal(round_id.trim_prefix("round:").capitalize(), verdict)
	if live_variants(PackedStringArray(["karera"]), unverified_override).is_empty():
		return "No item is available for networked live Karera rounds."
	return ""


static func _refusal(label: String, verdict: Dictionary) -> String:
	if str(verdict.reason) == "PENDING_NETWORK_VERIFICATION":
		return (
			"%s is not verified for networked live play. A development host may start with %s."
			% [label, OVERRIDE_FLAG]
		)
	return "%s is unavailable for networked live play: %s" % [label, str(verdict.text)]


## Host lobby lines: counts plus the first `limit` cells that are off, with their reasons.
static func lobby_summary(unverified_override: bool, limit: int = 6) -> PackedStringArray:
	var lines := PackedStringArray()
	var ids: Array = cells().keys()
	ids.sort()
	var on := 0
	var off: Array[String] = []
	for cell_id in ids:
		var verdict := resolve(str(cell_id), unverified_override)
		if bool(verdict.selectable):
			on += 1
		else:
			off.append("%s — %s" % [str(cell_id), str(verdict.text)])
	if unverified_override:
		lines.append("UNVERIFIED CONTENT — development override is on; results are not evidence.")
	lines.append("Live content: %d on, %d off." % [on, off.size()])
	for index in range(mini(limit, off.size())):
		lines.append(off[index])
	if off.size() > limit:
		lines.append("… and %d more (see %s)." % [off.size() - limit, MATRIX_DOC])
	return lines


## Structural errors. Any error refuses the networked live route; the scheduled route is
## unaffected.
static func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	var table := cells()
	for cell_id in table:
		var cell: Dictionary = table[cell_id]
		if not STATUSES.has(str(cell.status)):
			errors.append("%s has unknown status '%s'." % [cell_id, str(cell.status)])
		if not REASON_TEXT.has(str(cell.reason)):
			errors.append("%s has unknown reason '%s'." % [cell_id, str(cell.reason)])
		if str(cell.status) == STATUS_VERIFIED and str(cell.evidence).is_empty():
			errors.append("%s is VERIFIED without an evidence reference." % cell_id)
		for required in cell.requires:
			if not table.has(str(required)):
				errors.append("%s requires unknown cell '%s'." % [cell_id, str(required)])
		if _has_cycle(table, str(cell_id), []):
			errors.append("%s has a dependency cycle." % cell_id)
	var catalog_families := {}
	for family_variant in BlockCatalog.scan().families:
		catalog_families[(family_variant as ItemFamilyDefinition).family_id] = true
	for family_id in FAMILY_RULES:
		if not catalog_families.has(family_id):
			errors.append("Family rule '%s' has no catalog family." % family_id)
	var map_ids := MapCatalog.ids()
	for map_id in MAP_RULES:
		if not map_ids.has(map_id):
			errors.append("Map rule '%s' has no catalog map." % map_id)
	for mode_id in DiagnosticContentCatalog.MODES:
		if not ROUND_RULES.has(mode_id):
			errors.append("Mode '%s' has no round rule." % mode_id)
	for evidence_id in EVIDENCE:
		if not table.has(evidence_id):
			errors.append("Evidence names unknown cell '%s'." % evidence_id)
	return errors


## Catalog content without a rule. It is already DISABLED/UNKNOWN_CONTENT (default deny); the
## P07 test keeps this list empty so new content gets a reviewed row.
static func coverage_gaps() -> PackedStringArray:
	var gaps := PackedStringArray()
	for family_variant in BlockCatalog.scan().families:
		var family_id := (family_variant as ItemFamilyDefinition).family_id
		if not FAMILY_RULES.has(family_id):
			gaps.append("family:%s" % family_id)
	for map_id in MapCatalog.ids():
		if not MAP_RULES.has(map_id):
			gaps.append("map:%s" % map_id)
	return gaps


static func _has_cycle(table: Dictionary, cell_id: String, path: Array) -> bool:
	if path.has(cell_id):
		return true
	if not table.has(cell_id):
		return false
	var next_path := path.duplicate()
	next_path.append(cell_id)
	for required in (table[cell_id] as Dictionary).requires:
		if _has_cycle(table, str(required), next_path):
			return true
	return false


## The digest record. Every host and client binary computes it the same way, so a peer with a
## different table gets a different manifest digest and the existing INCOMPATIBLE rejection.
## The development override is host policy, not identity, and is announced separately.
static func manifest_record() -> Dictionary:
	var rows: Array = []
	var ids: Array = cells().keys()
	ids.sort()
	for cell_id in ids:
		var cell: Dictionary = cells()[cell_id]
		rows.append(
			{
				"id": str(cell_id),
				"status": str(cell.status),
				"reason": str(cell.reason),
				"min_protocol": str(cell.min_protocol),
				"min_content": str(cell.min_content),
				"requires": Array(cell.requires),
			}
		)
	return {"version": MATRIX_VERSION, "cells": rows}


## Markdown table rows for MATRIX_DOC ("| id | axis | status | reason | requires |").
static func markdown_rows() -> PackedStringArray:
	var rows := PackedStringArray()
	var ids: Array = cells().keys()
	ids.sort()
	for cell_id in ids:
		var cell: Dictionary = cells()[cell_id]
		var requires := ", ".join(PackedStringArray(cell.requires))
		rows.append(
			(
				"| `%s` | %s | %s | %s | %s |"
				% [
					str(cell_id),
					str(cell.axis),
					str(cell.status),
					str(cell.reason),
					requires if not requires.is_empty() else "—",
				]
			)
		)
	return rows

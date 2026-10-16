class_name UiLibraryText
extends Resource

## Library copy: categories with one or more pages each (UiLibraryPage). Pages are PLACEHOLDER
## English written from the GDD / ITEMS / PRD contracts and are not culturally reviewed. Numbers
## come from live tuning and the score calculators through {tokens}; a page whose `requires`
## names content that is not enabled is absent from the Library. The older one-page-per-category
## arrays remain as a fallback for categories that have no pages.

const PLACEHOLDER_NOTE := "PLACEHOLDER copy, pending Filipino / Hiligaynon review."
const ALL_MODES := ["KARERA", "LAGSANAY", "KANGAROO"]
const CONTROL_ACTIONS := [
	["navigate", "Move / menus"],
	["run", "Run"],
	["jump", "Jump"],
	["claim", "Claim egg / confirm"],
	["rotate", "Rotate piece"],
	["back", "Back"],
	["pause", "Pause"],
	["cheer", "Cheer (when out)"],
]
const DEVICE_LABELS := {
	"k1": "Keyboard WASD",
	"k2": "Keyboard arrows",
	"k3": "Keyboard IJKL",
	"k4": "Keyboard numpad",
	"gamepad": "Gamepad",
}

@export var categories: PackedStringArray = PackedStringArray()
@export var titles: PackedStringArray = PackedStringArray()
@export var bodies: PackedStringArray = PackedStringArray()
@export var pages: Array[UiLibraryPage] = []


func body_for(category: String) -> String:
	var index := categories.find(category)
	return bodies[index] if index >= 0 and index < bodies.size() else ""


func title_for(category: String) -> String:
	var index := categories.find(category)
	return titles[index] if index >= 0 and index < titles.size() else category


## Resolved pages of a category as {title, body} rows, in authored order. `context` is
## build_context(); an empty context keeps every page and leaves tokens untouched.
func pages_for(category: String, context: Dictionary = {}) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for page in pages:
		if page == null or page.category != category:
			continue
		if not context.is_empty() and not _is_available(page.requires, context):
			continue
		(
			rows
			. append(
				{
					"title": _fill(page.title, context),
					"body": _fill(page.body, context) + "\n\n" + PLACEHOLDER_NOTE,
				}
			)
		)
	return rows


## The tokens a page may use, from live tuning, the score calculators and the prompt map.
static func build_context(
	tuning: GameplayTuning,
	prompt_map: UiPromptMap = null,
	shake_mode: int = 2,
	pair_rows: Array[Dictionary] = EventSchedule.enabled_pairs(),
	available_modes: Array = ALL_MODES
) -> Dictionary:
	var stacks: Array[String] = []
	for row in pair_rows:
		var main_name := EventSchedule.main_name(int(row.main))
		var twist_name := EventSchedule.main_name(int(row.twist))
		if main_name in available_modes and twist_name in available_modes:
			stacks.append("%s+%s" % [main_name, twist_name])
	var four := PlacementScoreResolver.table_for_players(4)
	var tokens := {
		"tapos": ScoreFormat.format_units(RaceScoreCalculator.TAPOS_UNITS),
		"una": ScoreFormat.format_units(RaceScoreCalculator.UNA_UNITS),
		"bayani": ScoreFormat.format_units(RaceScoreCalculator.BAYANI_UNITS),
		"patibong": ScoreFormat.format_units(RaceScoreCalculator.PATIBONG_UNITS),
		"bawi": ScoreFormat.format_units(RaceScoreCalculator.BAWI_UNITS),
		"barya": ScoreFormat.format_units(RaceScoreCalculator.BARYA_UNITS),
		"bawi_gap": ScoreFormat.format_units(RaceScoreCalculator.BAWI_GAP_UNITS),
		"target": ScoreFormat.format_units(tuning.match_target_score_units),
		"round_limit": str(tuning.match_round_limit),
		"pugad_s": str(roundi(tuning.match_pugad_seconds)),
		"place_s": str(roundi(tuning.match_place_seconds)),
		"finish_window": str(roundi(tuning.match_race_after_first_finish_seconds)),
		"hard_cap": str(roundi(tuning.match_race_hard_cap_seconds)),
		"head_start": str(roundi(tuning.lagsanay_opening_head_start_seconds)),
		"taya_4p": str(roundi(tuning.lagsanay_taya_seconds_4p)),
		"taya_3p": str(roundi(tuning.lagsanay_taya_seconds_3p)),
		"taya_2p": str(roundi(tuning.lagsanay_taya_seconds_2p)),
		"pass_back": "%s" % snappedf(tuning.taya_pass_back_seconds, 0.1),
		"telegraph": "%s" % snappedf(tuning.kangaroo_telegraph_seconds, 0.1),
		"response": "%s" % snappedf(tuning.kangaroo_response_seconds, 0.1),
		"storm_after": str(tuning.kangaroo_storm_after_commands),
		"place_1st": ScoreFormat.format_units(four[0]),
		"place_2nd": ScoreFormat.format_units(four[1]),
		"place_3rd": ScoreFormat.format_units(four[2]),
		"place_4th": ScoreFormat.format_units(four[3]),
		"shake_mode": ["Full", "Reduced", "Off"][clampi(shake_mode, 0, 2)],
		"controls": _controls_text(prompt_map),
	}
	return {
		"tokens": tokens,
		"stacks": stacks,
		"modes": available_modes.duplicate(),
		"barya_enabled": tuning.barya_enabled,
	}


static func _controls_text(map: UiPromptMap) -> String:
	if map == null:
		return ""
	var lines := PackedStringArray()
	for device in DEVICE_LABELS:
		var parts := PackedStringArray()
		for entry in CONTROL_ACTIONS:
			parts.append("%s: %s" % [entry[1], map.glyph(str(entry[0]), str(device))])
		lines.append("%s - %s" % [DEVICE_LABELS[device], ", ".join(parts)])
	return "\n".join(lines)


func _is_available(requires: String, context: Dictionary) -> bool:
	if requires.is_empty():
		return true
	var parts := requires.split(":", false, 1)
	if parts.size() < 2:
		return true
	var needed := parts[1].split("|", false)
	var available := true
	match parts[0]:
		"main":
			available = str(needed[0]) in (context.get("modes", []) as Array)
		"stack":
			available = false
			for option in needed:
				if str(option) in (context.get("stacks", []) as Array):
					available = true
					break
		"feature":
			available = needed[0] == "barya" and bool(context.get("barya_enabled", false))
	return available


func _fill(text: String, context: Dictionary) -> String:
	if context.is_empty():
		return text
	var result := text
	var tokens: Dictionary = context.get("tokens", {})
	for key in tokens:
		result = result.replace("{%s}" % key, str(tokens[key]))
	return result

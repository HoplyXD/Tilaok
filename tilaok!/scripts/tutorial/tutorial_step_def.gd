class_name TutorialStepDef
extends Resource

## One coach-box step. Copy is PLACEHOLDER English (needs a Filipino / Hiligaynon and cultural
## review). `{name}` tokens are filled from GameplayTuning, the stage layout and the live seats by
## TutorialCoordinator; nothing numeric is typed into the copy.

@export var step_id: StringName = &""
## Short caption above the body, for example "Step 3 of 5 - Place".
@export var title := ""
@export var body := ""
## Stronger text shown when a build round failed to reach the flag (hint level 2).
@export var retry_body := ""
## Control action whose glyph the box shows (prompt_map action id); empty hides the glyph.
@export var glyph_action := ""
## Named variants selected from live state (egg claimed / lost, result kinds, ...).
@export var variants: Dictionary = {}


func body_for(variant: StringName = &"", hint_level: int = 1) -> String:
	if hint_level >= 2 and not retry_body.is_empty():
		return retry_body
	if variant != &"" and variants.has(str(variant)):
		return str(variants[str(variant)])
	return body

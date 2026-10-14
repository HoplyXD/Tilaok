class_name TutorialScript
extends Resource

## The editable guided-first-round script (data/ui/tutorial_script.tres). Steps are looked up by id;
## order and advance rules live in TutorialCoordinator, wording and glyph actions live here.

const STEP_WELCOME := &"welcome"
const STEP_PUGAD := &"pugad"
const STEP_PLACE := &"place"
const STEP_KARERA := &"karera"
const STEP_RESULTS := &"results"
const STEP_LAGSANAY := &"lagsanay"

@export var steps: Array[TutorialStepDef] = []
## Visible label on every live prompt until the copy is reviewed (honest provenance).
@export var placeholder_tag := "PLACEHOLDER copy"
## Static caption that replaces the old Back-bound skip glyph in live mode.
@export var skip_caption := "Pause > Skip tutorial"
@export var total_steps := 5


func step(step_id: StringName) -> TutorialStepDef:
	for candidate in steps:
		if candidate != null and candidate.step_id == step_id:
			return candidate
	return null


func has_all_steps() -> bool:
	for step_id in [STEP_WELCOME, STEP_PUGAD, STEP_PLACE, STEP_KARERA, STEP_RESULTS, STEP_LAGSANAY]:
		if step(step_id) == null:
			return false
	return true

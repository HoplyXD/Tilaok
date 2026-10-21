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
## Just-in-time Kangaroo prompts (P13-T07): poses in the Pugad before the first Kangaroo round,
## built supports in its Place, the three misses once its commands run.
const STEP_KANGAROO_POSES := &"kangaroo_poses"
const STEP_KANGAROO_SUPPORTS := &"kangaroo_supports"
const STEP_KANGAROO_MISSES := &"kangaroo_misses"
const KANGAROO_STEPS: Array[StringName] = [
	STEP_KANGAROO_POSES, STEP_KANGAROO_SUPPORTS, STEP_KANGAROO_MISSES
]

## NLB-P10 phone help cards (client-local, never host-driven), shown in this order. The offline
## coach never uses them; they teach phone play, build mode, placement results, LAN joining and
## the host-only pause.
const STEP_NET_PHONE_CONTROLS := &"net_phone_controls"
const STEP_NET_PUGAD := &"net_pugad"
const STEP_NET_GO := &"net_go"
const STEP_NET_BUILD_MODE := &"net_build_mode"
const STEP_NET_REJECTED := &"net_rejected"
const STEP_NET_CANCEL := &"net_cancel"
const STEP_NET_LAN_JOIN := &"net_lan_join"
const STEP_NET_HOST_PAUSE := &"net_host_pause"
const NETWORK_STEPS: Array[StringName] = [
	STEP_NET_PHONE_CONTROLS,
	STEP_NET_PUGAD,
	STEP_NET_GO,
	STEP_NET_BUILD_MODE,
	STEP_NET_REJECTED,
	STEP_NET_CANCEL,
	STEP_NET_LAN_JOIN,
	STEP_NET_HOST_PAUSE,
]

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
	for step_id in KANGAROO_STEPS:
		if step(step_id) == null:
			return false
	return true


func has_all_network_steps() -> bool:
	for step_id in NETWORK_STEPS:
		if step(step_id) == null:
			return false
	return true

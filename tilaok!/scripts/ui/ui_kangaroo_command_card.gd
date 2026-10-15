class_name UiKangarooCommandCard
extends PanelContainer

## One Kangaroo command: pose icon + name, GET READY / NOW phase, countdown ring and the plain
## instruction. Every cue is text and shape; colour is never the only signal. Display only.

const PHASE_TELEGRAPH := "GET READY"
const PHASE_RESPONSE := "NOW"
const STORM_TEXT := "STORM %d"

@onready var _icon: Label = %Icon
@onready var _pose: Label = %PoseLabel
@onready var _storm: Label = %StormLabel
@onready var _phase: Label = %PhaseLabel
@onready var _ring: UiCountdownRing = %Ring
@onready var _instruction: Label = %InstructionLabel


## `command` is one KangarooRoundController.active_commands() row.
func bind(command: Dictionary, active_time: float) -> void:
	var type := int(command.command)
	var is_telegraph := str(command.status) == "TELEGRAPH"
	var countdown_end := (
		float(command.response_start_at) if is_telegraph else float(command.response_end_at)
	)
	var countdown_total := (
		float(command.response_start_at) - float(command.telegraph_start_at)
		if is_telegraph
		else float(command.response_end_at) - float(command.response_start_at)
	)
	_icon.text = KangarooCommandStyle.icon(type)
	_pose.text = KangarooRoundController.command_name(type).to_upper()
	_storm.visible = bool(command.is_storm)
	_storm.text = STORM_TEXT % int(command.command_id)
	_phase.text = PHASE_TELEGRAPH if is_telegraph else PHASE_RESPONSE
	_instruction.text = KangarooCommandStyle.player_instruction(type)
	_ring.set_time(maxf(0.0, countdown_end - active_time), countdown_total)


func pose_text() -> String:
	return _pose.text


func phase_text() -> String:
	return _phase.text


func instruction_text() -> String:
	return _instruction.text

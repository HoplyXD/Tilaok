class_name UiDebugOverlay
extends Control

## Developer diagnostics and fixture controls (build id, seed, profile, last message, join/start/
## pause/return buttons). Off in the player flow; the harness opens it by default and F3 toggles it
## in debug builds. Layout lives in debug_overlay.tscn; this script only binds text and signals.

signal join_requested(layout: String)
signal start_requested
signal pause_requested
signal return_requested
signal harness_requested
signal extra_requested

@onready var join_k1_button: Button = %JoinK1Button
@onready var join_k2_button: Button = %JoinK2Button
@onready var start_button: Button = %StartButton
@onready var pause_button: Button = %PauseButton
@onready var return_button: Button = %ReturnButton
@onready var harness_button: Button = %HarnessButton
@onready var extra_button: Button = %ExtraButton
@onready var _identity_label: Label = %IdentityLabel
@onready var _seats_label: Label = %SeatsLabel
@onready var _feedback_label: Label = %FeedbackLabel
@onready var _hints_label: Label = %HintsLabel


func _ready() -> void:
	join_k1_button.pressed.connect(func() -> void: join_requested.emit("K1"))
	join_k2_button.pressed.connect(func() -> void: join_requested.emit("K2"))
	start_button.pressed.connect(func() -> void: start_requested.emit())
	pause_button.pressed.connect(func() -> void: pause_requested.emit())
	return_button.pressed.connect(func() -> void: return_requested.emit())
	harness_button.pressed.connect(func() -> void: harness_requested.emit())
	extra_button.pressed.connect(func() -> void: extra_requested.emit())


func show_info(identity_text: String, seats_text: String, feedback: String, hints: String) -> void:
	_identity_label.text = identity_text
	_seats_label.text = seats_text
	_feedback_label.text = feedback
	_hints_label.text = hints


## Lobby controls only matter in the Lobby; Start is enabled by the room's ready gate. A room can
## offer one extra developer action by name (the Lagsanay lab's "Restart attempt").
func set_controls(
	in_lobby: bool, can_start: bool, paused: bool, harness_available: bool, extra_label: String = ""
) -> void:
	join_k1_button.visible = in_lobby
	join_k2_button.visible = in_lobby
	start_button.visible = in_lobby
	start_button.disabled = not (in_lobby and can_start)
	pause_button.text = "Resume" if paused else "Pause"
	harness_button.visible = harness_available
	extra_button.visible = not extra_label.is_empty()
	extra_button.text = extra_label


func feedback_text() -> String:
	return _feedback_label.text


func identity_text() -> String:
	return _identity_label.text

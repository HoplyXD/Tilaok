class_name GameSfx
extends Node

## Short interface, building and chicken sounds, all on the Effects bus:
## - Click: a button is pressed (mouse or touch press), a confirm key is pressed (E/F, Enter, O,
##   Numpad 0 or gamepad A, outside Place and Play; a new player's join press counts too), or a
##   Lobby map change is accepted.
## - Switch: the selection moves to another button (a router step, or the mouse moving onto one).
## - Place: a player places a block.
## - Death: a chicken is eliminated (the moment it shows its "dead" sprite).
## It also holds the looping menu music on the Music bus. GameFlow says when it should play; it
## fades in and out over 0.6 s, and picks up where it stopped. On a score screen it keeps
## playing under the progress sound while the bars rise.
## - Progress: the score bars filling on a results screen (ScoreboardChart reports when its bars
##   are rising). It plays once from the start while any chart is revealing, and stops when the
##   last one finishes, settles, hides or leaves the tree.
## Presentation only: it never reads or writes a rule, a clock or a score.
##
## res://scenes/audio/game_sfx.tscn is an autoload, so one copy sits under the root from startup:
## a sound outlives the screen that asked for it, and it keeps playing while the game is paused.
## Each sound's stream, volume and pitch are set on its player in that scene. Scripts call the
## static functions (GameSfx.play_click()); the autoload has no global name, because test scripts
## preload game scenes before Godot registers autoload names.

const CLICK := &"click"
const SWITCH := &"switch"
const PLACE := &"place"
const DEATH := &"death"
## Router phases where a confirm press clicks. Place has its own placing sound, and the confirm
## key does nothing in Play or GO.
const CONFIRM_CLICK_PHASES := [
	LocalInputRouter.Phase.LOBBY,
	LocalInputRouter.Phase.MENU,
	LocalInputRouter.Phase.PUGAD,
	LocalInputRouter.Phase.PAUSE,
	LocalInputRouter.Phase.RESULTS,
]

const PROGRESS_STOP_FADE_SECONDS := 0.15
const MUSIC_FADE_SECONDS := 0.6
const MUSIC_FADE_OUT_SECONDS := 0.6
## Fade floor as a linear gain (about -80 dB), so the fade never reaches log(0).
const MUSIC_SILENT_GAIN := 0.0001

static var _instance: GameSfx

var _music_on := false
var _music_started := false
var _music_tween: Tween
## The Music player's volume in the scene is its full level; fades scale below it.
var _music_full_db := 0.0
## Instance ids of the charts whose bars are rising right now.
var _progress_owners: Dictionary = {}
var _progress_tween: Tween
## The Progress player's volume in the scene is its level (set a little below the music).
var _progress_full_db := 0.0

## Process frame each sound last started on. One action can reach two hooks in the same frame
## (for example a confirm that also lands a block, or several chickens out at a deadline), and it
## should still sound once.
var _played_frame: Dictionary = {}

@onready var _players := {CLICK: $Click, SWITCH: $Switch, PLACE: $Place, DEATH: $Death}
@onready var _music: AudioStreamPlayer = $Music
@onready var _progress: AudioStreamPlayer = $Progress


static func play_click() -> void:
	_play_cue(CLICK)


static func play_switch() -> void:
	_play_cue(SWITCH)


static func play_place() -> void:
	_play_cue(PLACE)


static func play_death() -> void:
	_play_cue(DEATH)


## Fades the menu music in (true) or out (false). Calling it again with the same value does nothing.
static func set_menu_music(on: bool) -> void:
	if _instance != null and is_instance_valid(_instance) and _instance.is_node_ready():
		_instance._set_music(on)


## A score chart says whether its bars are rising. The progress sound plays while any chart's are.
## Safe to call every frame: it only acts when the answer changes.
static func set_progress_sound(chart: Object, rising: bool) -> void:
	if _instance != null and is_instance_valid(_instance) and _instance.is_node_ready():
		_instance._set_progress(chart.get_instance_id(), rising)


## True while any score chart's bars are rising.
static func are_score_bars_rising() -> bool:
	return (
		_instance != null and is_instance_valid(_instance) and not _instance._progress_owners.is_empty()
	)


static func is_progress_sound_playing() -> bool:
	return _instance != null and is_instance_valid(_instance) and _instance._progress.playing


static func is_menu_music_on() -> bool:
	return _instance != null and is_instance_valid(_instance) and _instance._music_on


static func _play_cue(cue: StringName) -> void:
	if _instance != null and is_instance_valid(_instance) and _instance.is_node_ready():
		_instance.play(cue)


func play(cue: StringName) -> void:
	var frame := Engine.get_process_frames()
	if int(_played_frame.get(cue, -1)) == frame:
		return
	_played_frame[cue] = frame
	var player := _players.get(cue) as AudioStreamPlayer
	if player != null and player.stream != null:
		player.play()


func _set_music(on: bool) -> void:
	if on == _music_on or _music.stream == null:
		return
	_music_on = on
	if _music_tween != null:
		_music_tween.kill()
	_music_tween = create_tween()
	var from := db_to_linear(_music.volume_db - _music_full_db)
	if on:
		if not _music_started:
			_music_started = true
			from = MUSIC_SILENT_GAIN
			_set_music_gain(from)
			_music.play()
		_music.stream_paused = false
		_music_tween.tween_method(_set_music_gain, from, 1.0, MUSIC_FADE_SECONDS)
	else:
		_music_tween.tween_method(
			_set_music_gain, from, MUSIC_SILENT_GAIN, MUSIC_FADE_OUT_SECONDS
		)
		# Paused, not stopped, so it picks up where it left off.
		_music_tween.tween_callback(func() -> void: _music.stream_paused = true)


func _set_progress(owner_id: int, rising: bool) -> void:
	var was_active := not _progress_owners.is_empty()
	if rising:
		_progress_owners[owner_id] = true
	else:
		_progress_owners.erase(owner_id)
	var active := not _progress_owners.is_empty()
	if active == was_active or _progress.stream == null:
		return
	if _progress_tween != null:
		_progress_tween.kill()
		_progress_tween = null
	_progress.volume_db = _progress_full_db
	if active:
		_progress.play()
	else:
		# A short fade, so cutting the clip short does not click.
		_progress_tween = create_tween()
		_progress_tween.tween_property(
			_progress, "volume_db", linear_to_db(MUSIC_SILENT_GAIN), PROGRESS_STOP_FADE_SECONDS
		)
		_progress_tween.tween_callback(_progress.stop)


func _set_music_gain(gain: float) -> void:
	_music.volume_db = _music_full_db + linear_to_db(maxf(gain, MUSIC_SILENT_GAIN))


func _enter_tree() -> void:
	_instance = self


func _exit_tree() -> void:
	if _instance == self:
		_instance = null


func _ready() -> void:
	# Every button gets the click and hover sounds, every input router the confirm click and every
	# chicken the death sound, including ones added later. The button hooks use button_down and
	# mouse_entered so each button's pressed signal keeps only its own action callbacks.
	_music_full_db = _music.volume_db
	_progress_full_db = _progress.volume_db
	get_tree().node_added.connect(_on_node_added)
	for node in get_tree().root.find_children("*", "", true, false):
		_on_node_added(node)


func _on_node_added(node: Node) -> void:
	var button := node as BaseButton
	if button != null:
		_hook_button(button)
		return
	var chicken := node as ChickenController
	if chicken != null and not chicken.terminal_state_changed.is_connected(_on_chicken_terminal):
		chicken.terminal_state_changed.connect(_on_chicken_terminal)
		return
	var router := node as LocalInputRouter
	if router != null:
		var handler := _on_router_action.bind(router)
		if not router.action_pressed.is_connected(handler):
			router.action_pressed.connect(handler)
			router.seat_joined.connect(_on_seat_joined)


func _hook_button(button: BaseButton) -> void:
	if button == null or button.button_down.is_connected(_on_button_down):
		return
	button.button_down.connect(_on_button_down)
	button.mouse_entered.connect(_on_button_hovered.bind(button))


func _on_button_down() -> void:
	play(CLICK)


func _on_button_hovered(button: BaseButton) -> void:
	if is_instance_valid(button) and not button.disabled and button.is_visible_in_tree():
		play(SWITCH)


## A confirm press (Lobby ready, Pugad claim, menu/pause/results confirm). In a menu the list's
## own click lands in the same frame, so it still sounds once.
func _on_router_action(_seat_index: int, action_name: String, router: LocalInputRouter) -> void:
	if (
		action_name in UiInputBridge.ACCEPT_ACTIONS
		and is_instance_valid(router)
		and router.phase in CONFIRM_CLICK_PHASES
	):
		play(CLICK)


## The first confirm press of a new player (Title or Lobby) joins a seat instead of confirming.
func _on_seat_joined(_seat_index: int) -> void:
	play(CLICK)


## Every elimination shows the "dead" sprite: hazards, falls, the Lagsanay bomb, Kangaroo misses,
## and chickens still running when a Karera round runs out of time.
func _on_chicken_terminal(status: PlayerLifecycleState.Status, _reason: String) -> void:
	if status == PlayerLifecycleState.Status.ELIMINATED:
		play(DEATH)

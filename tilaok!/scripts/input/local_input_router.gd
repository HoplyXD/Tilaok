# gdlint: disable=max-returns,max-public-methods,max-file-lines
class_name LocalInputRouter
extends Node

signal seat_joined(seat_index: int)
signal seat_disconnected(seat_index: int)
signal device_status_changed(device_id: int, connected: bool)
signal action_pressed(seat_index: int, action_name: String)
signal intentional_input_edge(
	seat_index: int, action_name: String, source_id: String, is_pressed: bool, event_ticks_usec: int
)
signal pause_requested(seat_index: int)
signal navigation_step(seat_index: int, direction: String)
signal disabled_action_cue(seat_index: int, action_name: String)
signal phase_changed(previous_phase: Phase, next_phase: Phase)

enum Phase { LOBBY, MENU, PUGAD, PLACE, PLAY, PAUSE, RESULTS, GO }

const ONE_SHOT_ACTIONS := [
	"join",
	"ready",
	"claim",
	"confirm",
	"rotate",
	"jump",
	"back",
	"help",
	"cheer",
	"build_toggle",
	"live_rotate",
	"live_cancel"
]
## The physical Rotate control (West / R / Right Shift) is context-sensitive: it opens the Library
## from the Lobby ("help") and cheers from the stands during Play ("cheer"). Rotation itself is
## only meaningful in Place, so neither alias takes anything from the placement rules.
const ROTATE_ALIAS_LOBBY := "help"
const ROTATE_ALIAS_PLAY := "cheer"
const STICK_KEY_PREFIX := "stick_"
const STICK_DIRECTIONS := {
	JOY_AXIS_LEFT_X: ["left", "right"],
	JOY_AXIS_LEFT_Y: ["up", "down"],
}

var registry := PlayerSeatRegistry.new()
var authority := SimulationAuthority.offline()
var tuning: GameplayTuning
var phase := Phase.LOBBY
var shared_keyboard_enabled := false
var rotation_supported := false
## Set only by live-build rooms: keyboard south keys then confirm a live placement during Play.
var live_build_confirm_enabled := false
## Seats currently in build mode. Their movement keys steer the block cursor instead of the chicken.
var build_mode_seats: Dictionary = {}
var _held: Dictionary = {}
var _pressed: Dictionary = {}
var _blocked: Dictionary = {}
var _axis: Dictionary = {}
var _repeat_elapsed: Dictionary = {}
var _active_navigation: Dictionary = {}
var _stick_x: Dictionary = {}
var _stick_y: Dictionary = {}
var _aim_x: Dictionary = {}
var _aim_y: Dictionary = {}
## Digital menu direction (-1 / 0 / +1) per "seat:axis" derived from the left stick outside Play.
var _stick_sign: Dictionary = {}
var _system_paused := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if tuning == null:
		tuning = GameplayTuning.new()
	Input.joy_connection_changed.connect(_on_joy_connection_changed)


func _process(delta: float) -> void:
	if phase not in [Phase.MENU, Phase.PUGAD, Phase.PLACE, Phase.PAUSE, Phase.RESULTS]:
		return
	for seat in registry.joined_seats():
		var seat_index := int(seat.seat)
		for direction in ["up", "down", "left", "right"]:
			if repeat_navigation(seat_index, direction, delta):
				navigation_step.emit(seat_index, direction)


func _exit_tree() -> void:
	if Input.joy_connection_changed.is_connected(_on_joy_connection_changed):
		Input.joy_connection_changed.disconnect(_on_joy_connection_changed)
	clear_input_state()


func set_phase(next_phase: Phase) -> void:
	if phase == next_phase:
		return
	var previous_phase := phase
	phase = next_phase
	_release_stick_navigation()
	for key in _held:
		if ONE_SHOT_ACTIONS.has(str(_held[key])):
			_blocked[key] = true
	_pressed.clear()
	_repeat_elapsed.clear()
	for seat in registry.joined_seats():
		var seat_index := int(seat.seat)
		var active: String = _active_navigation.get(seat_index, "")
		if not active.is_empty() and _is_action_held(seat_index, active):
			_repeat_elapsed[_edge_key(seat_index, active)] = {"elapsed": 0.0, "first": true}
	phase_changed.emit(previous_phase, next_phase)


## Treats everything currently held as already used, like a phase change does, without changing
## the phase. Screen swaps inside one phase (Title <-> Library <-> Settings, Pause <-> overlays)
## call this so a press that opened a screen can never also act on the next one.
func consume_held_presses() -> void:
	for key in _held:
		if ONE_SHOT_ACTIONS.has(str(_held[key])):
			_blocked[key] = true
	_pressed.clear()
	_repeat_elapsed.clear()
	for seat in registry.joined_seats():
		var seat_index := int(seat.seat)
		var active: String = _active_navigation.get(seat_index, "")
		if not active.is_empty() and _is_action_held(seat_index, active):
			_repeat_elapsed[_edge_key(seat_index, active)] = {"elapsed": 0.0, "first": true}


func consume_held_presses_for_seat(seat_index: int) -> void:
	for key in _held.keys():
		if _physical_key_seat(str(key)) == seat_index and ONE_SHOT_ACTIONS.has(str(_held[key])):
			_blocked[key] = true
	for edge in _pressed.keys():
		if str(edge).begins_with("%d:" % seat_index):
			_pressed[edge] = false
	for edge in _repeat_elapsed.keys():
		if str(edge).begins_with("%d:" % seat_index):
			_repeat_elapsed.erase(edge)


func set_shared_keyboard_enabled(enabled: bool) -> void:
	shared_keyboard_enabled = enabled
	clear_input_state()


func set_rotation_supported(supported: bool) -> void:
	rotation_supported = supported


func set_live_build_mode(seat_index: int, enabled: bool) -> void:
	set_build_mode(seat_index, enabled)


func set_authority(value: SimulationAuthority) -> bool:
	if value == null or not value.configured:
		return false
	authority = value
	registry.authority = value
	return true


func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton:
		_handle_joy_button(event as InputEventJoypadButton)
	elif event is InputEventJoypadMotion:
		_handle_joy_axis(event as InputEventJoypadMotion)
	elif event is InputEventKey:
		_handle_key(event as InputEventKey)


func _handle_joy_button(event: InputEventJoypadButton) -> void:
	var physical_key := "joy:%d:%d" % [event.device, event.button_index]
	var seat_index := registry.seat_for_gamepad(event.device)
	if not event.pressed and _held.has(physical_key):
		if seat_index >= 0:
			_handle_action_edge(seat_index, str(_held[physical_key]), physical_key, false)
		else:
			_held.erase(physical_key)
			_blocked.erase(physical_key)
		return
	var action_name := _joy_action(event.button_index)
	if action_name.is_empty():
		return
	if seat_index < 0:
		if event.pressed and event.button_index == JOY_BUTTON_A:
			if _held.has(physical_key):
				return
			_held[physical_key] = "join"
			_blocked[physical_key] = true
			if phase == Phase.PAUSE:
				action_pressed.emit(-1, "select_reclaim_device:%d" % event.device)
			elif phase == Phase.LOBBY:
				var joined := registry.join_gamepad(event.device)
				if joined >= 0:
					seat_joined.emit(joined)
		elif not event.pressed:
			_held.erase(physical_key)
			_blocked.erase(physical_key)
		return
	action_name = _gamepad_phase_action(event.button_index)
	if phase == Phase.PLAY and is_build_mode(seat_index):
		action_name = _gamepad_build_action_for_joy_button(event.button_index, action_name)
	_handle_action_edge(seat_index, action_name, physical_key, event.pressed)


func _handle_joy_axis(event: InputEventJoypadMotion) -> void:
	if event.axis in [JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y]:
		var seat_index := registry.seat_for_gamepad(event.device)
		if seat_index < 0:
			return
		var value := event.axis_value
		if absf(value) < tuning_neutral_threshold():
			value = 0.0
		elif absf(value) < tuning_activation_threshold():
			value = (
				float(_aim_x.get(seat_index, 0.0))
				if event.axis == JOY_AXIS_RIGHT_X
				else float(_aim_y.get(seat_index, 0.0))
			)
		if event.axis == JOY_AXIS_RIGHT_X:
			_aim_x[seat_index] = value
		else:
			_aim_y[seat_index] = value
		return
	if event.axis == JOY_AXIS_TRIGGER_RIGHT:
		var trigger_seat := registry.seat_for_gamepad(event.device)
		if trigger_seat >= 0:
			_handle_action_edge(
				trigger_seat,
				"confirm",
				"joy:%d:live_confirm" % event.device,
				event.axis_value >= 0.55
			)
		return
	if event.axis != JOY_AXIS_LEFT_X and event.axis != JOY_AXIS_LEFT_Y:
		return
	var seat_index := registry.seat_for_gamepad(event.device)
	if seat_index < 0:
		return
	if phase == Phase.PLAY and is_build_mode(seat_index):
		var current := event.axis_value
		if absf(current) < tuning_neutral_threshold():
			current = 0.0
		elif absf(current) < tuning_activation_threshold():
			current = (
				float(_aim_x.get(seat_index, 0.0))
				if event.axis == JOY_AXIS_LEFT_X
				else float(_aim_y.get(seat_index, 0.0))
			)
		if event.axis == JOY_AXIS_LEFT_X:
			_aim_x[seat_index] = current
		else:
			_aim_y[seat_index] = current
		return
	if event.axis == JOY_AXIS_LEFT_Y:
		var vertical := event.axis_value
		if absf(vertical) < tuning_neutral_threshold():
			vertical = 0.0
		elif absf(vertical) < tuning_activation_threshold():
			vertical = float(_stick_y.get(seat_index, 0.0))
		_stick_y[seat_index] = vertical
		_handle_stick_navigation(seat_index, event)
		return
	if event.axis == JOY_AXIS_LEFT_X:
		var previous: float = _stick_x.get(seat_index, 0.0)
		var current := event.axis_value
		if absf(current) < tuning_neutral_threshold():
			current = 0.0
		elif absf(current) < tuning_activation_threshold():
			current = previous
		_stick_x[seat_index] = current
		if is_zero_approx(previous) != is_zero_approx(current):
			intentional_input_edge.emit(
				seat_index, "run_axis", "stick", not is_zero_approx(current), Time.get_ticks_usec()
			)
	_handle_stick_navigation(seat_index, event)


## Outside Play (and the Lobby) the left stick steps menus, Pugad and Place exactly like the D-pad:
## it is turned into the same digital left/right/up/down edges with the same hysteresis as the
## run axis, so repeat timing, pause and device rules are shared.
func _handle_stick_navigation(seat_index: int, event: InputEventJoypadMotion) -> void:
	var names: Array = STICK_DIRECTIONS[event.axis]
	var sign_key := "%d:%d" % [seat_index, event.axis]
	var previous: int = _stick_sign.get(sign_key, 0)
	var next := previous
	if phase in [Phase.LOBBY, Phase.PLAY]:
		next = 0
	elif absf(event.axis_value) < tuning_neutral_threshold():
		next = 0
	elif absf(event.axis_value) >= tuning_activation_threshold():
		next = 1 if event.axis_value > 0.0 else -1
	if next == previous:
		return
	_stick_sign[sign_key] = next
	if previous != 0:
		var released: String = names[0] if previous < 0 else names[1]
		_handle_action_edge(seat_index, released, _stick_key(event.device, released), false)
	if next != 0:
		var pressed: String = names[0] if next < 0 else names[1]
		_handle_action_edge(seat_index, pressed, _stick_key(event.device, pressed), true)


func _stick_key(device: int, direction: String) -> String:
	return "joy:%d:%s%s" % [device, STICK_KEY_PREFIX, direction]


func _release_stick_navigation() -> void:
	for key in _held.keys():
		var name := str(key)
		if not name.begins_with("joy:") or not name.contains(":" + STICK_KEY_PREFIX):
			continue
		var action_name := str(_held[key])
		var seat_index := _physical_key_seat(name)
		_held.erase(key)
		_blocked.erase(key)
		_repeat_elapsed.erase(_edge_key(seat_index, action_name))
		if _active_navigation.get(seat_index, "") == action_name:
			_active_navigation.erase(seat_index)
	_stick_sign.clear()


func _handle_key(event: InputEventKey) -> void:
	if event.echo:
		return
	var key := event.physical_keycode if event.physical_keycode != 0 else event.keycode
	var layout := _keyboard_layout_for_key(key, event.location)
	if key == KEY_ESCAPE:
		if event.pressed and not _key_is_down("sys:pause"):
			_pause_system()
		_set_key_down("sys:pause", event.pressed, "pause")
		return
	if layout.is_empty():
		return
	if not shared_keyboard_enabled:
		return
	var physical_key := "kbd:%s:%d" % [layout, key]
	var seat_index := registry.seat_for_keyboard(layout)
	if not event.pressed and _held.has(physical_key):
		if seat_index >= 0:
			_handle_action_edge(seat_index, str(_held[physical_key]), physical_key, false)
		else:
			_held.erase(physical_key)
			_blocked.erase(physical_key)
		return
	var action_name := _key_action(layout, key, seat_index)
	if action_name.is_empty():
		if not event.pressed and _held.has(physical_key):
			_held.erase(physical_key)
			_blocked.erase(physical_key)
		return
	if seat_index < 0 and phase == Phase.LOBBY and event.pressed and action_name == "ready":
		seat_index = registry.join_keyboard(layout)
		if seat_index >= 0:
			seat_joined.emit(seat_index)
			var join_key := "kbd:%s:%d" % [layout, key]
			_held[join_key] = "join"
			_blocked[join_key] = true
			return
	if seat_index < 0:
		return
	_handle_action_edge(seat_index, action_name, physical_key, event.pressed)


func _handle_action_edge(
	seat_index: int, action_name: String, physical_key: String, is_pressed: bool
) -> void:
	if not is_pressed:
		if action_name in ["left", "right", "jump"]:
			intentional_input_edge.emit(
				seat_index, action_name, physical_key, false, Time.get_ticks_usec()
			)
		_held.erase(physical_key)
		_blocked.erase(physical_key)
		_repeat_elapsed.erase(_edge_key(seat_index, action_name))
		if action_name in ["left", "right", "up", "down"]:
			var active: String = _active_navigation.get(seat_index, "")
			if active == action_name:
				_active_navigation.erase(seat_index)
				for candidate in ["up", "down", "left", "right"]:
					if _is_action_held(seat_index, candidate):
						_active_navigation[seat_index] = candidate
						_repeat_elapsed[_edge_key(seat_index, candidate)] = {
							"elapsed": 0.0,
							"first": true,
						}
						break
		return
	if _held.has(physical_key):
		return
	var requested_action := action_name
	action_name = _phase_alias(action_name)
	_held[physical_key] = action_name
	if action_name in ["left", "right", "jump"]:
		intentional_input_edge.emit(
			seat_index, action_name, physical_key, true, Time.get_ticks_usec()
		)
	if ONE_SHOT_ACTIONS.has(action_name) and _blocked.has(physical_key):
		return
	if action_name == "pause":
		pause_requested.emit(seat_index)
		return
	# Rotate keeps its disabled cue wherever it is pressed (P02-T05); the Lobby help alias is a
	# different action and shows no rotation cue.
	if (
		requested_action == "rotate"
		and not rotation_supported
		and action_name != ROTATE_ALIAS_LOBBY
	):
		disabled_action_cue.emit(seat_index, requested_action)
		if action_name == requested_action:
			return
	if action_name == "ready" and phase == Phase.LOBBY:
		var seat: Dictionary = registry.get_seat(seat_index)
		registry.set_ready(seat_index, not bool(seat.ready))
	_pressed[_edge_key(seat_index, action_name)] = true
	if action_name in ["left", "right", "up", "down"]:
		_axis[_edge_key(seat_index, action_name)] = true
		if (
			phase in [Phase.MENU, Phase.PUGAD, Phase.PLACE, Phase.PAUSE, Phase.RESULTS]
			and not _active_navigation.has(seat_index)
		):
			_active_navigation[seat_index] = action_name
			_repeat_elapsed[_edge_key(seat_index, action_name)] = {"elapsed": 0.0, "first": true}
			navigation_step.emit(seat_index, action_name)
	if (
		action_name
		in [
			"claim",
			"confirm",
			"rotate",
			"jump",
			"back",
			"ready",
			"help",
			"cheer",
			"build_toggle",
			"live_rotate",
			"live_cancel"
		]
	):
		action_pressed.emit(seat_index, action_name)


func _phase_alias(action_name: String) -> String:
	if action_name != "rotate":
		return action_name
	match phase:
		Phase.LOBBY:
			return ROTATE_ALIAS_LOBBY
		Phase.PLAY:
			return ROTATE_ALIAS_PLAY
	return action_name


func consume_pressed(seat_index: int, action_name: String) -> bool:
	var key := _edge_key(seat_index, action_name)
	if not _pressed.get(key, false):
		return false
	_pressed[key] = false
	return true


func intent_vector(seat_index: int) -> Vector2:
	var x := _digital_axis(seat_index, "left", "right")
	var y := _digital_axis(seat_index, "up", "down")
	if x == 0.0 and not _has_active_gamepad_dpad(seat_index):
		x = float(_stick_x.get(seat_index, 0.0))
	return (
		Vector2(x, y).normalized()
		if phase in [Phase.MENU, Phase.PUGAD, Phase.PLACE]
		else Vector2(x, 0.0)
	)


## True while this seat is aiming a block instead of steering its chicken.
func is_build_mode(seat_index: int) -> bool:
	return bool(build_mode_seats.get(seat_index, false))


func set_build_mode(seat_index: int, enabled: bool) -> void:
	if enabled:
		build_mode_seats[seat_index] = true
		_aim_x[seat_index] = float(_stick_x.get(seat_index, 0.0))
		_aim_y[seat_index] = float(_stick_y.get(seat_index, 0.0))
	else:
		build_mode_seats.erase(seat_index)
		_aim_x[seat_index] = 0.0
		_aim_y[seat_index] = 0.0


func movement_axis(seat_index: int) -> float:
	# In build mode the movement keys belong to the block cursor, so the chicken reads nothing.
	if is_build_mode(seat_index):
		return 0.0
	var dpad := _digital_axis(seat_index, "left", "right")
	return (
		dpad
		if dpad != 0.0 or _has_active_gamepad_dpad(seat_index)
		else float(_stick_x.get(seat_index, 0.0))
	)


func has_direction_intent(seat_index: int) -> bool:
	return (
		_is_action_held(seat_index, "left")
		or _is_action_held(seat_index, "right")
		or not is_zero_approx(float(_stick_x.get(seat_index, 0.0)))
	)


## Physical movement/jump sources are exposed so time-windowed event rules can distinguish a
## control held at cue time from a fresh press later in the same physics step.
func intentional_input_sources(seat_index: int) -> Array[String]:
	var result: Array[String] = []
	for physical_key in _held:
		if (
			_physical_key_seat(str(physical_key)) == seat_index
			and _held[physical_key] in ["left", "right", "jump"]
		):
			result.append(str(physical_key))
	if not is_zero_approx(float(_stick_x.get(seat_index, 0.0))):
		result.append("stick")
	result.sort()
	return result


func repeat_navigation(seat_index: int, direction: String, delta: float) -> bool:
	var edge := _edge_key(seat_index, direction)
	if (
		not _is_action_held(seat_index, direction)
		or _active_navigation.get(seat_index, "") != direction
	):
		_repeat_elapsed.erase(edge)
		return false
	var opposite := str(
		{"left": "right", "right": "left", "up": "down", "down": "up"}.get(direction, "")
	)
	if _is_action_held(seat_index, opposite):
		_repeat_elapsed[edge] = {"elapsed": 0.0, "first": true}
		return false
	if not _repeat_elapsed.has(edge):
		_repeat_elapsed[edge] = {"elapsed": 0.0, "first": true}
		return true
	var state: Dictionary = _repeat_elapsed[edge]
	var elapsed := float(state.elapsed) + delta
	var initial_delay := (
		tuning.placement_initial_repeat_delay
		if phase == Phase.PLACE
		else tuning.menu_initial_repeat_delay
	)
	var repeat_rate := (
		tuning.placement_repeat_rate if phase == Phase.PLACE else tuning.menu_repeat_rate
	)
	var threshold := initial_delay if bool(state.first) else 1.0 / repeat_rate
	if elapsed >= threshold:
		state.elapsed = elapsed - threshold
		state.first = false
		_repeat_elapsed[edge] = state
		return true
	state.elapsed = elapsed
	_repeat_elapsed[edge] = state
	return false


func is_action_held(seat_index: int, action_name: String) -> bool:
	return _is_action_held(seat_index, action_name)


func live_aim_vector(seat_index: int) -> Vector2:
	# In build mode the movement keys aim the block, so WASD / arrows / IJKL / numpad 8426 steer
	# the cursor. The dedicated aim keys keep working as a second way in.
	if is_build_mode(seat_index):
		# During Play the up key resolves to "jump" (W, Up, I, Numpad 8), so accept either name:
		# the chicken cannot jump in build mode anyway.
		var up_held := (
			_is_action_held(seat_index, "up", true) or _is_action_held(seat_index, "jump", true)
		)
		var moved := Vector2(
			(
				float(_is_action_held(seat_index, "right", true))
				- float(_is_action_held(seat_index, "left", true))
			),
			float(_is_action_held(seat_index, "down", true)) - float(up_held)
		)
		if not moved.is_zero_approx():
			return moved.normalized()
	var x := float(_aim_x.get(seat_index, 0.0))
	var y := float(_aim_y.get(seat_index, 0.0))
	if is_zero_approx(x):
		x = (
			float(_is_action_held(seat_index, "aim_right"))
			- float(_is_action_held(seat_index, "aim_left"))
		)
	if is_zero_approx(y):
		y = (
			float(_is_action_held(seat_index, "aim_down"))
			- float(_is_action_held(seat_index, "aim_up"))
		)
	return (
		Vector2(x, y).normalized()
		if not is_zero_approx(x) or not is_zero_approx(y)
		else Vector2.ZERO
	)


func pause_system() -> void:
	_pause_system()


func resume_system() -> void:
	_system_paused = false
	clear_input_state()


func clear_input_state() -> void:
	for physical_key in _held:
		var action_name := str(_held[physical_key])
		if action_name not in ["left", "right", "jump"]:
			continue
		var seat_index := _physical_key_seat(str(physical_key))
		if seat_index >= 0:
			intentional_input_edge.emit(
				seat_index, action_name, str(physical_key), false, Time.get_ticks_usec()
			)
	for seat_index in _stick_x:
		if not is_zero_approx(float(_stick_x[seat_index])):
			intentional_input_edge.emit(
				int(seat_index), "run_axis", "stick", false, Time.get_ticks_usec()
			)
	_held.clear()
	_pressed.clear()
	_blocked.clear()
	_axis.clear()
	_repeat_elapsed.clear()
	_active_navigation.clear()
	_stick_x.clear()
	_stick_y.clear()
	_aim_x.clear()
	_aim_y.clear()
	_stick_sign.clear()


func _pause_system() -> void:
	if _system_paused:
		return
	if authority != null and authority.is_client_presentation():
		action_pressed.emit(-1, "client_pause_overlay")
		return
	_system_paused = true
	get_tree().paused = true
	action_pressed.emit(-1, "system_pause")


func _on_joy_connection_changed(device_id: int, connected: bool) -> void:
	device_status_changed.emit(device_id, connected)
	if connected:
		return
	var device_prefix := "joy:%d:" % device_id
	for key in _held.keys():
		if str(key).begins_with(device_prefix):
			_held.erase(key)
			_blocked.erase(key)
			_repeat_elapsed.erase(key)
	var seat_index := registry.disconnect_gamepad(device_id)
	if seat_index >= 0:
		_active_navigation.erase(seat_index)
		for direction in ["up", "down", "left", "right"]:
			_repeat_elapsed.erase(_edge_key(seat_index, direction))
		seat_disconnected.emit(seat_index)
		_pause_system()


func _set_key_down(key: String, down: bool, action_name: String) -> void:
	if down:
		_held[key] = action_name
	else:
		_held.erase(key)


func _key_is_down(key: String) -> bool:
	return _held.has(key)


func _digital_axis(seat_index: int, negative: String, positive: String) -> float:
	var has_negative := _is_action_held(seat_index, negative, true)
	var has_positive := _is_action_held(seat_index, positive, true)
	if has_negative == has_positive:
		return 0.0
	return -1.0 if has_negative else 1.0


## `skip_stick` ignores the digital directions synthesised from the left stick, so movement and
## the "D-pad wins over the stick" rule see physical buttons and keys only.
func _is_action_held(seat_index: int, action_name: String, skip_stick: bool = false) -> bool:
	for physical_key in _held:
		if skip_stick and str(physical_key).contains(":" + STICK_KEY_PREFIX):
			continue
		if (
			_held[physical_key] == action_name
			and _physical_key_seat(str(physical_key)) == seat_index
		):
			return true
	return false


func _has_active_gamepad_dpad(seat_index: int) -> bool:
	for physical_key in _held:
		if str(physical_key).contains(":" + STICK_KEY_PREFIX):
			continue
		if (
			_physical_key_seat(str(physical_key)) == seat_index
			and str(physical_key).begins_with("joy:")
		):
			if _held[physical_key] in ["left", "right"]:
				return true
	return false


func _physical_key_seat(key: String) -> int:
	if key.begins_with("joy:"):
		var parts := key.split(":")
		return registry.seat_for_gamepad(int(parts[1]))
	if key.begins_with("kbd:"):
		var parts := key.split(":")
		return registry.seat_for_keyboard(parts[1])
	return -1


func _edge_key(seat_index: int, action_name: String) -> String:
	return "%d:%s" % [seat_index, action_name]


func _joy_action(button: int) -> String:
	match button:
		JOY_BUTTON_DPAD_LEFT:
			return "left"
		JOY_BUTTON_DPAD_RIGHT:
			return "right"
		JOY_BUTTON_DPAD_UP:
			return "up"
		JOY_BUTTON_DPAD_DOWN:
			return "down"
		JOY_BUTTON_A:
			return "confirm"
		JOY_BUTTON_B:
			return "back"
		JOY_BUTTON_X:
			return "rotate"
		JOY_BUTTON_Y:
			return "build_toggle"
		JOY_BUTTON_RIGHT_SHOULDER:
			return "live_rotate"
		JOY_BUTTON_LEFT_SHOULDER:
			return "live_cancel"
		JOY_BUTTON_START:
			return "pause"
	return ""


func _gamepad_phase_action(button: int) -> String:
	match button:
		JOY_BUTTON_DPAD_LEFT:
			return "left"
		JOY_BUTTON_DPAD_RIGHT:
			return "right"
		JOY_BUTTON_DPAD_UP:
			return "up"
		JOY_BUTTON_DPAD_DOWN:
			return "down"
		JOY_BUTTON_A:
			if phase == Phase.PUGAD:
				return "claim"
			if phase == Phase.PLAY:
				return "jump"
			if phase in [Phase.MENU, Phase.PLACE, Phase.PAUSE, Phase.RESULTS]:
				return "confirm"
			return "ready" if phase == Phase.LOBBY else ""
		JOY_BUTTON_B:
			return "back"
		JOY_BUTTON_X:
			return "rotate"
		JOY_BUTTON_Y:
			return "build_toggle" if phase == Phase.PLAY else ""
		JOY_BUTTON_RIGHT_SHOULDER:
			return "live_rotate" if phase == Phase.PLAY else ""
		JOY_BUTTON_LEFT_SHOULDER:
			return "live_cancel" if phase == Phase.PLAY else ""
		JOY_BUTTON_START:
			return "pause"
	return ""


func tuning_activation_threshold() -> float:
	return tuning.stick_activation_threshold


func tuning_neutral_threshold() -> float:
	return tuning.stick_neutral_threshold


## Four shared-keyboard layouts (2026-10-16, user request). The layout is only a device:
## seats are numbered in join order, so any layout can be any player.
## K1 W A S D, E or F confirm, R rotate (Space jump, G back)
## K2 Arrow keys, Enter confirm, Right Shift rotate (Right Ctrl jump, Backspace back)
## K3 I J K L, O confirm, P rotate (U back)
## K4 Numpad 8 4 2 6, Numpad 0 confirm, Numpad 5 rotate (Numpad . back)
func _keyboard_layout_for_key(key: int, location: int) -> String:
	if (
		key
		in [
			KEY_W,
			KEY_A,
			KEY_S,
			KEY_D,
			KEY_SPACE,
			KEY_E,
			KEY_F,
			KEY_G,
			KEY_R,
			KEY_Q,
			KEY_Z,
			KEY_C,
			KEY_V,
			KEY_B,
			KEY_T,
			KEY_X
		]
	):
		return "K1"
	if (
		key
		in [
			KEY_UP,
			KEY_DOWN,
			KEY_LEFT,
			KEY_RIGHT,
			KEY_ENTER,
			KEY_BACKSPACE,
			KEY_BRACKETLEFT,
			KEY_BRACKETRIGHT,
			KEY_Y,
			KEY_H,
			KEY_N,
			KEY_M,
			KEY_BACKSLASH
		]
	):
		return "K2"
	if key in [KEY_SHIFT, KEY_CTRL] and location == KEY_LOCATION_RIGHT:
		return "K2"
	if (
		key
		in [
			KEY_I,
			KEY_J,
			KEY_K,
			KEY_L,
			KEY_O,
			KEY_P,
			KEY_U,
			KEY_MINUS,
			KEY_EQUAL,
			KEY_SEMICOLON,
			KEY_APOSTROPHE,
			KEY_QUOTELEFT,
			KEY_7,
			KEY_4,
			KEY_8,
			KEY_6
		]
	):
		return "K3"
	if (
		key
		in [
			KEY_KP_8,
			KEY_KP_4,
			KEY_KP_2,
			KEY_KP_6,
			KEY_KP_7,
			KEY_KP_1,
			KEY_KP_3,
			KEY_KP_9,
			KEY_KP_0,
			KEY_KP_5,
			KEY_KP_PERIOD,
			KEY_KP_ADD,
			KEY_KP_SUBTRACT,
			KEY_KP_MULTIPLY
		]
	):
		return "K4"
	return ""


func _key_action(layout: String, key: int, seat_index: int = -1) -> String:
	if phase == Phase.PLAY and is_build_mode(seat_index):
		if live_build_confirm_enabled and key == KEY_SPACE and layout == "K1":
			return "confirm"
		var build_direction := _build_aim_action_for_key(layout, key)
		if not build_direction.is_empty():
			return build_direction
	if layout == "K1":
		match key:
			KEY_Q:
				return "build_toggle"
			KEY_Z:
				return "aim_up"
			KEY_C:
				return "aim_left"
			KEY_V:
				return "aim_down"
			KEY_B:
				return "aim_right"
			KEY_T:
				return "live_rotate"
			KEY_X:
				return "live_cancel"
			KEY_A:
				return "left"
			KEY_D:
				return "right"
			KEY_W:
				return _keyboard_up_action()
			KEY_S:
				return "down"
			KEY_SPACE:
				return "jump"
			KEY_E, KEY_F:
				return _keyboard_south_action()
			KEY_G:
				return "back"
			KEY_R:
				return "rotate"
	elif layout == "K3":
		match key:
			KEY_MINUS:
				return "build_toggle"
			KEY_7:
				return "aim_up"
			KEY_4:
				return "aim_left"
			KEY_8:
				return "aim_down"
			KEY_6:
				return "aim_right"
			KEY_EQUAL:
				return "live_rotate"
			KEY_APOSTROPHE:
				return "live_cancel"
			KEY_J:
				return "left"
			KEY_L:
				return "right"
			KEY_I:
				return _keyboard_up_action()
			KEY_K:
				return "down"
			KEY_O:
				return _keyboard_south_action()
			KEY_U:
				return "back"
			KEY_P:
				return "rotate"
	elif layout == "K4":
		match key:
			KEY_KP_ADD:
				return "build_toggle"
			KEY_KP_7:
				return "aim_up"
			KEY_KP_1:
				return "aim_left"
			KEY_KP_3:
				return "aim_down"
			KEY_KP_9:
				return "aim_right"
			KEY_KP_MULTIPLY:
				return "live_rotate"
			KEY_KP_SUBTRACT:
				return "live_cancel"
			KEY_KP_4:
				return "left"
			KEY_KP_6:
				return "right"
			KEY_KP_8:
				return _keyboard_up_action()
			KEY_KP_2:
				return "down"
			KEY_KP_0:
				return _keyboard_south_action()
			KEY_KP_PERIOD:
				return "back"
			KEY_KP_5:
				return "rotate"
	else:
		match key:
			KEY_BRACKETLEFT:
				return "build_toggle"
			KEY_Y:
				return "aim_up"
			KEY_H:
				return "aim_left"
			KEY_N:
				return "aim_down"
			KEY_M:
				return "aim_right"
			KEY_BRACKETRIGHT:
				return "live_rotate"
			KEY_BACKSLASH:
				return "live_cancel"
			KEY_LEFT:
				return "left"
			KEY_RIGHT:
				return "right"
			KEY_UP:
				return _keyboard_up_action()
			KEY_DOWN:
				return "down"
			KEY_CTRL:
				return "jump"
			KEY_ENTER:
				return _keyboard_south_action()
			KEY_BACKSPACE:
				return "back"
			KEY_SHIFT:
				return "rotate"
	return ""


func _build_aim_action_for_key(layout: String, key: int) -> String:
	if layout == "K1":
		match key:
			KEY_A:
				return "aim_left"
			KEY_D:
				return "aim_right"
			KEY_W:
				return "aim_up"
			KEY_S:
				return "aim_down"
	elif layout == "K3":
		match key:
			KEY_J:
				return "aim_left"
			KEY_L:
				return "aim_right"
			KEY_I:
				return "aim_up"
			KEY_K:
				return "aim_down"
	elif layout == "K4":
		match key:
			KEY_KP_4:
				return "aim_left"
			KEY_KP_6:
				return "aim_right"
			KEY_KP_8:
				return "aim_up"
			KEY_KP_2:
				return "aim_down"
	else:
		match key:
			KEY_LEFT:
				return "aim_left"
			KEY_RIGHT:
				return "aim_right"
			KEY_UP:
				return "aim_up"
			KEY_DOWN:
				return "aim_down"
	return ""


func _build_aim_action_for_joy_button(button: int, fallback: String) -> String:
	match button:
		JOY_BUTTON_DPAD_LEFT:
			return "aim_left"
		JOY_BUTTON_DPAD_RIGHT:
			return "aim_right"
		JOY_BUTTON_DPAD_UP:
			return "aim_up"
		JOY_BUTTON_DPAD_DOWN:
			return "aim_down"
	return fallback


func _gamepad_build_action_for_joy_button(button: int, fallback: String) -> String:
	if button == JOY_BUTTON_A:
		return "confirm"
	return _build_aim_action_for_joy_button(button, fallback)


## W (K1), Up (K2), I (K3) and Numpad 8 (K4) jump during Play (hold to glide) and stay "up" for
## menus and Place. Space/Right Ctrl remain alternate jump keys for K1/K2.
func _keyboard_up_action() -> String:
	return "jump" if phase == Phase.PLAY else "up"


func _keyboard_south_action() -> String:
	if phase == Phase.LOBBY:
		return "ready"
	if phase == Phase.PUGAD:
		return "claim"
	if phase in [Phase.MENU, Phase.PLACE, Phase.PAUSE, Phase.RESULTS]:
		return "confirm"
	if phase == Phase.PLAY and live_build_confirm_enabled:
		return "confirm"
	return ""

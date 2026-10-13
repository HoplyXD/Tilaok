# gdlint: disable=max-returns
class_name LocalInputRouter
extends Node

signal seat_joined(seat_index: int)
signal seat_disconnected(seat_index: int)
signal device_status_changed(device_id: int, connected: bool)
signal action_pressed(seat_index: int, action_name: String)
signal pause_requested(seat_index: int)
signal navigation_step(seat_index: int, direction: String)
signal disabled_action_cue(seat_index: int, action_name: String)
signal phase_changed(previous_phase: Phase, next_phase: Phase)

enum Phase { LOBBY, MENU, PUGAD, PLACE, PLAY, PAUSE, RESULTS }

const ONE_SHOT_ACTIONS := ["join", "ready", "claim", "confirm", "rotate", "jump", "back"]

var registry := PlayerSeatRegistry.new()
var tuning: GameplayTuning
var phase := Phase.LOBBY
var shared_keyboard_enabled := false
var rotation_supported := false
var _held: Dictionary = {}
var _pressed: Dictionary = {}
var _blocked: Dictionary = {}
var _axis: Dictionary = {}
var _repeat_elapsed: Dictionary = {}
var _active_navigation: Dictionary = {}
var _stick_x: Dictionary = {}
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


func set_shared_keyboard_enabled(enabled: bool) -> void:
	shared_keyboard_enabled = enabled
	clear_input_state()


func set_rotation_supported(supported: bool) -> void:
	rotation_supported = supported


func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton:
		_handle_joy_button(event as InputEventJoypadButton)
	elif event is InputEventJoypadMotion:
		_handle_joy_axis(event as InputEventJoypadMotion)
	elif event is InputEventKey:
		_handle_key(event as InputEventKey)


func _handle_joy_button(event: InputEventJoypadButton) -> void:
	var physical_key := "joy:%d:%d" % [event.device, event.button_index]
	var action_name := _joy_action(event.button_index)
	if action_name.is_empty():
		return
	var seat_index := registry.seat_for_gamepad(event.device)
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
	_handle_action_edge(seat_index, action_name, physical_key, event.pressed)


func _handle_joy_axis(event: InputEventJoypadMotion) -> void:
	if event.axis != JOY_AXIS_LEFT_X:
		return
	var seat_index := registry.seat_for_gamepad(event.device)
	if seat_index < 0:
		return
	var previous: float = _stick_x.get(seat_index, 0.0)
	var current := event.axis_value
	if absf(current) < tuning_neutral_threshold():
		current = 0.0
	elif absf(current) < tuning_activation_threshold():
		current = previous
	_stick_x[seat_index] = current


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
	var action_name := _key_action(layout, key)
	if action_name.is_empty():
		if not event.pressed and _held.has(physical_key):
			_held.erase(physical_key)
			_blocked.erase(physical_key)
		return
	var seat_index := registry.seat_for_keyboard(layout)
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
	_held[physical_key] = action_name
	if ONE_SHOT_ACTIONS.has(action_name) and _blocked.has(physical_key):
		return
	if action_name == "pause":
		pause_requested.emit(seat_index)
		return
	if action_name == "rotate" and not rotation_supported:
		disabled_action_cue.emit(seat_index, action_name)
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
	if action_name in ["claim", "confirm", "rotate", "jump", "back", "ready"]:
		action_pressed.emit(seat_index, action_name)


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
		x = _stick_x.get(seat_index, 0.0)
	return (
		Vector2(x, y).normalized()
		if phase in [Phase.MENU, Phase.PUGAD, Phase.PLACE]
		else Vector2(x, 0.0)
	)


func movement_axis(seat_index: int) -> float:
	var dpad := _digital_axis(seat_index, "left", "right")
	return (
		dpad
		if dpad != 0.0 or _has_active_gamepad_dpad(seat_index)
		else _stick_x.get(seat_index, 0.0)
	)


func has_direction_intent(seat_index: int) -> bool:
	return _is_action_held(seat_index, "left") or _is_action_held(seat_index, "right")


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


func pause_system() -> void:
	_pause_system()


func resume_system() -> void:
	_system_paused = false
	clear_input_state()


func clear_input_state() -> void:
	_held.clear()
	_pressed.clear()
	_blocked.clear()
	_axis.clear()
	_repeat_elapsed.clear()
	_active_navigation.clear()
	_stick_x.clear()


func _pause_system() -> void:
	if _system_paused:
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
	var has_negative := _is_action_held(seat_index, negative)
	var has_positive := _is_action_held(seat_index, positive)
	if has_negative == has_positive:
		return 0.0
	return -1.0 if has_negative else 1.0


func _is_action_held(seat_index: int, action_name: String) -> bool:
	for physical_key in _held:
		if (
			_held[physical_key] == action_name
			and _physical_key_seat(str(physical_key)) == seat_index
		):
			return true
	return false


func _has_active_gamepad_dpad(seat_index: int) -> bool:
	for physical_key in _held:
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
		JOY_BUTTON_START:
			return "pause"
	return ""


func tuning_activation_threshold() -> float:
	return tuning.stick_activation_threshold


func tuning_neutral_threshold() -> float:
	return tuning.stick_neutral_threshold


func _keyboard_layout_for_key(key: int, location: int) -> String:
	if key in [KEY_W, KEY_A, KEY_S, KEY_D, KEY_SPACE, KEY_F, KEY_G, KEY_R]:
		return "K1"
	if key in [KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_ENTER, KEY_KP_ENTER, KEY_BACKSPACE]:
		return "K2"
	if key in [KEY_SHIFT, KEY_CTRL] and location == KEY_LOCATION_RIGHT:
		return "K2"
	return ""


func _key_action(layout: String, key: int) -> String:
	if layout == "K1":
		match key:
			KEY_A:
				return "left"
			KEY_D:
				return "right"
			KEY_W:
				return "up"
			KEY_S:
				return "down"
			KEY_SPACE:
				return "jump"
			KEY_F:
				return _keyboard_south_action()
			KEY_G:
				return "back"
			KEY_R:
				return "rotate"
	else:
		match key:
			KEY_LEFT:
				return "left"
			KEY_RIGHT:
				return "right"
			KEY_UP:
				return "up"
			KEY_DOWN:
				return "down"
			KEY_CTRL:
				return "jump"
			KEY_ENTER, KEY_KP_ENTER:
				return _keyboard_south_action()
			KEY_BACKSPACE:
				return "back"
			KEY_SHIFT:
				return "rotate"
	return ""


func _keyboard_south_action() -> String:
	if phase == Phase.LOBBY:
		return "ready"
	if phase == Phase.PUGAD:
		return "claim"
	if phase in [Phase.MENU, Phase.PLACE, Phase.PAUSE, Phase.RESULTS]:
		return "confirm"
	return ""

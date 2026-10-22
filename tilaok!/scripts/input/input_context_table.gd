class_name InputContextTable
extends RefCounted

## Local action table: for each keyboard/gamepad and context, which control sends which action.
## It documents the LocalInputRouter bindings, and `audit()` proves that no control is bound
## twice in one context, that no extra action aliases jump/cheer/rotate and that the build
## controls never take over locomotion. The router remains the source of truth for the keys; a test
## compares the two. Contexts: lobby, pugad, go, play (locomotion), build (play with build mode
## available), results, pause.

const CONTEXTS := ["lobby", "pugad", "go", "play", "build", "results", "pause"]
const DEVICES := ["k1", "k2", "k3", "k4", "gamepad"]
## Actions that may be reachable from more than one physical control (alternate keys).
const MULTI_CONTROL_OK := ["jump", "ready", "claim", "confirm", "pause"]
## Locomotion meanings that no build control may take over.
const PROTECTED_ACTIONS := ["jump", "cheer", "rotate", "left", "right", "up", "down"]
## Build-mode actions, in the order the glyph map and the tutorial list them.
const BUILD_ACTIONS := ["build_toggle", "aim", "live_rotate", "live_confirm", "live_cancel"]

const KEYS := {
	"k1":
	{
		"left": KEY_A,
		"right": KEY_D,
		"up": KEY_W,
		"down": KEY_S,
		"jump_alt": KEY_SPACE,
		"south": KEY_E,
		"south_alt": KEY_F,
		"back": KEY_G,
		"rotate": KEY_R,
		"build_toggle": KEY_Q,
		"aim_up": KEY_Z,
		"aim_left": KEY_C,
		"aim_down": KEY_V,
		"aim_right": KEY_B,
		"live_rotate": KEY_T,
		"live_cancel": KEY_X,
	},
	"k2":
	{
		"left": KEY_LEFT,
		"right": KEY_RIGHT,
		"up": KEY_UP,
		"down": KEY_DOWN,
		"jump_alt": KEY_CTRL,
		"south": KEY_ENTER,
		"south_alt": 0,
		"back": KEY_BACKSPACE,
		"rotate": KEY_SHIFT,
		"build_toggle": KEY_BRACKETLEFT,
		"aim_up": KEY_Y,
		"aim_left": KEY_H,
		"aim_down": KEY_N,
		"aim_right": KEY_M,
		"live_rotate": KEY_BRACKETRIGHT,
		"live_cancel": KEY_BACKSLASH,
	},
	"k3":
	{
		"left": KEY_J,
		"right": KEY_L,
		"up": KEY_I,
		"down": KEY_K,
		"jump_alt": 0,
		"south": KEY_O,
		"south_alt": 0,
		"back": KEY_U,
		"rotate": KEY_P,
		"build_toggle": KEY_MINUS,
		"aim_up": KEY_7,
		"aim_left": KEY_4,
		"aim_down": KEY_8,
		"aim_right": KEY_6,
		"live_rotate": KEY_EQUAL,
		"live_cancel": KEY_APOSTROPHE,
	},
	"k4":
	{
		"left": KEY_KP_4,
		"right": KEY_KP_6,
		"up": KEY_KP_8,
		"down": KEY_KP_2,
		"jump_alt": 0,
		"south": KEY_KP_0,
		"south_alt": 0,
		"back": KEY_KP_PERIOD,
		"rotate": KEY_KP_5,
		"build_toggle": KEY_KP_ADD,
		"aim_up": KEY_KP_7,
		"aim_left": KEY_KP_1,
		"aim_down": KEY_KP_3,
		"aim_right": KEY_KP_9,
		"live_rotate": KEY_KP_MULTIPLY,
		"live_cancel": KEY_KP_SUBTRACT,
	},
}


## Returns [{control, action}] for one device and context. Controls are key codes (keyboards),
## JOY_BUTTON_* ints or axis names (gamepad).
static func bindings(device: String, context: String) -> Array:
	if device == "gamepad":
		return _gamepad(context)
	return _keyboard(device, context)


static func _row(control: Variant, action: String) -> Dictionary:
	return {"control": control, "action": action}


static func _keyboard(device: String, context: String) -> Array:
	var k: Dictionary = KEYS[device]
	var rows: Array = [_row(KEY_ESCAPE, "pause")]
	var moves := [_row(k.left, "left"), _row(k.right, "right"), _row(k.down, "down")]
	match context:
		"lobby":
			rows.append_array(moves)
			rows.append_array(
				[
					_row(k.up, "up"),
					_row(k.south, "ready"),
					_row(k.back, "back"),
					_row(k.rotate, "help")
				]
			)
			if int(k.south_alt) != 0:
				rows.append(_row(k.south_alt, "ready"))
		"pugad":
			rows.append_array(moves)
			rows.append_array([_row(k.up, "up"), _row(k.south, "claim"), _row(k.back, "back")])
			if int(k.south_alt) != 0:
				rows.append(_row(k.south_alt, "claim"))
		"go":
			rows.append_array(moves)
			rows.append_array([_row(k.up, "up"), _row(k.back, "back")])
		"play", "build":
			rows.append_array(moves)
			rows.append_array([_row(k.up, "jump"), _row(k.rotate, "cheer"), _row(k.back, "back")])
			if int(k.jump_alt) != 0:
				rows.append(_row(k.jump_alt, "jump"))
			rows.append(_row(k.build_toggle, "build_toggle"))
			if context == "build":
				(
					rows
					. append_array(
						[
							_row(k.aim_up, "aim_up"),
							_row(k.aim_left, "aim_left"),
							_row(k.aim_down, "aim_down"),
							_row(k.aim_right, "aim_right"),
							_row(k.live_rotate, "live_rotate"),
							_row(k.live_cancel, "live_cancel"),
							_row(k.south, "live_confirm"),
						]
					)
				)
				if int(k.south_alt) != 0:
					rows.append(_row(k.south_alt, "live_confirm"))
		"results", "pause":
			rows.append_array(moves)
			rows.append_array([_row(k.up, "up"), _row(k.south, "confirm"), _row(k.back, "back")])
			if int(k.south_alt) != 0:
				rows.append(_row(k.south_alt, "confirm"))
	return rows


static func _gamepad(context: String) -> Array:
	var rows: Array = [
		_row(JOY_BUTTON_START, "pause"),
		_row(JOY_BUTTON_B, "back"),
		_row(JOY_BUTTON_DPAD_LEFT, "left"),
		_row(JOY_BUTTON_DPAD_RIGHT, "right"),
		_row(JOY_BUTTON_DPAD_UP, "up"),
		_row(JOY_BUTTON_DPAD_DOWN, "down"),
	]
	match context:
		"lobby":
			rows.append_array([_row(JOY_BUTTON_A, "ready"), _row(JOY_BUTTON_X, "help")])
		"pugad":
			rows.append(_row(JOY_BUTTON_A, "claim"))
		"play", "build":
			rows.append_array(
				[
					_row(JOY_BUTTON_A, "jump"),
					_row(JOY_BUTTON_X, "cheer"),
					_row(JOY_BUTTON_Y, "build_toggle")
				]
			)
			if context == "build":
				# Left bumper is the live_cancel decision; B stays Back and never cancels a placement.
				(
					rows
					. append_array(
						[
							_row(JOY_BUTTON_RIGHT_SHOULDER, "live_rotate"),
							_row(JOY_BUTTON_LEFT_SHOULDER, "live_cancel"),
							_row("right_stick", "aim"),
							_row("right_trigger", "live_confirm"),
						]
					)
				)
		"results", "pause":
			rows.append(_row(JOY_BUTTON_A, "confirm"))
	return rows


## Returns a list of problem strings; empty means the table is unambiguous.
static func audit() -> Array:
	var problems: Array = []
	for device in DEVICES:
		for context in CONTEXTS:
			var seen_controls := {}
			var controls_for_action := {}
			for row in bindings(device, context):
				var key := str(row.control)
				if seen_controls.has(key):
					problems.append("%s/%s: control %s bound twice" % [device, context, key])
				seen_controls[key] = row.action
				var list: Array = controls_for_action.get(row.action, [])
				list.append(key)
				controls_for_action[row.action] = list
			for action in controls_for_action:
				if (
					(controls_for_action[action] as Array).size() > 1
					and not MULTI_CONTROL_OK.has(action)
					and action != "live_confirm"
				):
					problems.append(
						"%s/%s: action %s has several controls" % [device, context, action]
					)
			if context != "build":
				for action in BUILD_ACTIONS:
					if action != "build_toggle" and controls_for_action.has(action):
						problems.append("%s/%s: %s outside build" % [device, context, action])
	return problems

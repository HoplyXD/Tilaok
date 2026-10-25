class_name InputContextTable
extends RefCounted

## Local action table: for each keyboard/gamepad and context, which control sends which action.
## It documents the LocalInputRouter bindings, and `audit()` proves that no control is bound
## twice in one context, that no extra action aliases jump/cheer/rotate and that the build
## controls never take over locomotion. The router remains the source of truth for the keys; a test
## compares the two. Contexts: lobby, pugad, go, play (locomotion), build (play with build mode
## available), results, pause.

const CONTEXTS := ["lobby", "pugad", "preparation", "go", "play", "build", "results", "pause"]
const DEVICES := ["k1", "k2", "k3", "k4", "gamepad"]
## Actions that may be reachable from more than one physical control (alternate keys).
const MULTI_CONTROL_OK := [
	"jump", "ready", "claim", "confirm", "pause", "live_rotate", "live_confirm"
]
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
		"live_rotate": KEY_R,
		"live_confirm": KEY_E,
		"live_cancel": KEY_G,
	},
	"k2":
	{
		"left": KEY_J,
		"right": KEY_L,
		"up": KEY_I,
		"down": KEY_K,
		"jump_alt": 0,
		"south": KEY_O,
		"south_alt": 0,
		"back": KEY_H,
		"rotate": KEY_P,
		"build_toggle": KEY_U,
		"aim_up": KEY_I,
		"aim_left": KEY_J,
		"aim_down": KEY_K,
		"aim_right": KEY_L,
		"live_rotate": KEY_P,
		"live_cancel": KEY_H,
	},
	"k3":
	{
		"left": KEY_LEFT,
		"right": KEY_RIGHT,
		"up": KEY_UP,
		"down": KEY_DOWN,
		"jump_alt": KEY_CTRL,
		"south": KEY_ENTER,
		"south_alt": 0,
		"back": KEY_BACKSLASH,
		"rotate": KEY_BACKSPACE,
		"build_toggle": KEY_SHIFT,
		"aim_up": KEY_UP,
		"aim_left": KEY_LEFT,
		"aim_down": KEY_DOWN,
		"aim_right": KEY_RIGHT,
		"live_rotate": KEY_BACKSPACE,
		"live_cancel": KEY_BACKSLASH,
	},
	"k4":
	{
		"left": KEY_KP_4,
		"right": KEY_KP_6,
		"up": KEY_KP_8,
		"down": KEY_KP_2,
		"jump_alt": 0,
		"south": KEY_KP_ENTER,
		"south_alt": 0,
		"back": KEY_KP_PERIOD,
		"rotate": KEY_KP_0,
		"build_toggle": KEY_KP_5,
		"aim_up": KEY_KP_8,
		"aim_left": KEY_KP_4,
		"aim_down": KEY_KP_2,
		"aim_right": KEY_KP_6,
		"live_rotate": KEY_KP_0,
		"live_cancel": KEY_KP_PERIOD,
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
	if context in ["build", "preparation"]:
		var build_bindings: Array = []
		match device:
			"k1":
				build_bindings = [
					_row(k.build_toggle, "build_toggle"),
					_row(KEY_W, "aim_up"),
					_row(KEY_A, "aim_left"),
					_row(KEY_S, "aim_down"),
					_row(KEY_D, "aim_right"),
					_row(k.live_rotate, "live_rotate"),
					_row(k.live_confirm, "live_confirm"),
					_row(k.south_alt, "live_confirm"),
					_row(k.live_cancel, "live_cancel"),
					_row(KEY_SPACE, "live_confirm"),
				]
			"k3":
				build_bindings = [
					_row(k.build_toggle, "build_toggle"),
					_row(KEY_UP, "aim_up"),
					_row(KEY_LEFT, "aim_left"),
					_row(KEY_DOWN, "aim_down"),
					_row(KEY_RIGHT, "aim_right"),
					_row(k.live_rotate, "live_rotate"),
					_row(k.south, "live_confirm"),
					_row(k.live_cancel, "live_cancel"),
				]
			"k2":
				build_bindings = [
					_row(k.build_toggle, "build_toggle"),
					_row(KEY_I, "aim_up"),
					_row(KEY_J, "aim_left"),
					_row(KEY_K, "aim_down"),
					_row(KEY_L, "aim_right"),
					_row(k.live_rotate, "live_rotate"),
					_row(k.south, "live_confirm"),
					_row(k.live_cancel, "live_cancel"),
				]
			"k4":
				build_bindings = [
					_row(k.build_toggle, "build_toggle"),
					_row(KEY_KP_8, "aim_up"),
					_row(KEY_KP_4, "aim_left"),
					_row(KEY_KP_2, "aim_down"),
					_row(KEY_KP_6, "aim_right"),
					_row(k.live_rotate, "live_rotate"),
					_row(k.south, "live_confirm"),
					_row(k.live_cancel, "live_cancel"),
				]
		build_bindings.push_front(rows[0])
		return build_bindings
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
		"play", "build", "preparation":
			rows.append_array(moves)
			rows.append_array([_row(k.up, "jump"), _row(k.rotate, "cheer"), _row(k.back, "back")])
			if int(k.jump_alt) != 0:
				rows.append(_row(k.jump_alt, "jump"))
			rows.append(_row(k.build_toggle, "build_toggle"))
			if context in ["build", "preparation"]:
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
		"play", "build", "preparation":
			rows.append_array(
				[
					_row(
						LocalInputRouter.GENERIC_USB_PLACE_BUTTON,
						"live_confirm" if context in ["build", "preparation"] else "jump"
					),
					_row(
						LocalInputRouter.GENERIC_USB_ROTATE_BUTTON,
						"live_rotate" if context in ["build", "preparation"] else "cheer"
					),
					_row(JOY_BUTTON_Y, "build_toggle")
				]
			)
			if context in ["build", "preparation"]:
				# Left bumper is the live_cancel decision; B stays Back and never cancels a placement.
				(
					rows
					. append_array(
						[
							_row(JOY_BUTTON_RIGHT_SHOULDER, "live_rotate"),
							_row(JOY_BUTTON_LEFT_SHOULDER, "live_cancel"),
							_row("right_stick", "aim"),
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
			if context not in ["build", "preparation"]:
				for action in BUILD_ACTIONS:
					if action != "build_toggle" and controls_for_action.has(action):
						problems.append("%s/%s: %s outside build" % [device, context, action])
	return problems

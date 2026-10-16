class_name KeyChordRecorder
extends Control

## P02-T04 / P13-T11 physical keyboard checker. It shows each supported simultaneous chord from
## PROTOTYPE_DEFAULTS section 3 and records whether the keyboard reports every key of the chord at
## the same instant (no rollover loss). It reads raw key events only; it is not part of the game and
## never touches input routing. The result is a text report the tester pastes into PLAYTEST.md;
## nothing here claims a result by itself.
##
## Controls while testing:  hold the shown keys together  ->  PASS is recorded automatically.
##   Insert  = the keyboard could not report all of them (LOST).   Page Down = skip / next.
##   Page Up = previous chord.   F2 = write and print the report.   Home = restart the run.

signal return_requested

const STATUS_PENDING := "PENDING"
const STATUS_PASS := "PASS"
const STATUS_LOST := "LOST"
const STATUS_SKIPPED := "SKIPPED"
const AUTO_ADVANCE_SECONDS := 0.6
const LOG_LINES := 10
const REPORT_PREFIX := "p13_key_chords_"

## id, group, label, keys. Key ids: letters, Space, Left/Right/Up/Down, Enter, Backspace,
## LCtrl/RCtrl, LShift/RShift, Esc.
const CHORDS: Array[Dictionary] = [
	{"id": "C01", "group": "Run + jump", "label": "K1 left + jump", "keys": ["A", "Space"]},
	{"id": "C02", "group": "Run + jump", "label": "K1 right + jump", "keys": ["D", "Space"]},
	{"id": "C03", "group": "Run + jump", "label": "K1 right + alt jump (W)", "keys": ["D", "W"]},
	{"id": "C04", "group": "Run + jump", "label": "K2 left + jump", "keys": ["Left", "RCtrl"]},
	{"id": "C05", "group": "Run + jump", "label": "K2 right + jump", "keys": ["Right", "RCtrl"]},
	{
		"id": "C06",
		"group": "Run + jump",
		"label": "K2 right + alt jump (Up)",
		"keys": ["Right", "Up"]
	},
	{
		"id": "C07",
		"group": "Two seats",
		"label": "both seats run right + jump",
		"keys": ["D", "Space", "Right", "RCtrl"]
	},
	{
		"id": "C08",
		"group": "Two seats",
		"label": "K1 left + jump, K2 right + jump",
		"keys": ["A", "Space", "Right", "RCtrl"]
	},
	{
		"id": "C09",
		"group": "Two seats",
		"label": "both seats run + alt jump",
		"keys": ["D", "W", "Right", "Up"]
	},
	{"id": "C10", "group": "Place", "label": "K1 pointer + rotate", "keys": ["D", "R"]},
	{"id": "C11", "group": "Place", "label": "K1 pointer + confirm", "keys": ["D", "E"]},
	{"id": "C12", "group": "Place", "label": "K1 diagonal + rotate", "keys": ["W", "D", "R"]},
	{"id": "C13", "group": "Place", "label": "K2 pointer + rotate", "keys": ["Right", "RShift"]},
	{"id": "C14", "group": "Place", "label": "K2 pointer + confirm", "keys": ["Right", "Enter"]},
	{
		"id": "C15",
		"group": "Place",
		"label": "K2 diagonal + rotate",
		"keys": ["Up", "Right", "RShift"]
	},
	{
		"id": "C16",
		"group": "Two seats",
		"label": "both pointers + rotate",
		"keys": ["D", "R", "Right", "RShift"]
	},
	{
		"id": "C17",
		"group": "Two seats",
		"label": "both diagonal pointers + confirm",
		"keys": ["W", "D", "E", "Up", "Right", "Enter"]
	},
	{"id": "C18", "group": "Menus", "label": "both seats claim / confirm", "keys": ["E", "Enter"]},
	{"id": "C19", "group": "Menus", "label": "K1 back + K2 back", "keys": ["G", "Backspace"]},
	{
		"id": "C20",
		"group": "Pause",
		"label": "pause while K1 runs + jumps",
		"keys": ["Esc", "D", "Space"]
	},
	{
		"id": "C21",
		"group": "Pause",
		"label": "pause while K2 runs + jumps",
		"keys": ["Esc", "Right", "RCtrl"]
	},
	{"id": "C22", "group": "Cheer", "label": "both cheer", "keys": ["R", "RShift"]},
	{
		"id": "C23",
		"group": "Cheer",
		"label": "K1 cheers while K2 runs + jumps",
		"keys": ["R", "Right", "RCtrl"]
	},
	{
		"id": "C24",
		"group": "Cheer",
		"label": "K2 cheers while K1 runs + jumps",
		"keys": ["RShift", "D", "Space"]
	},
	# Four keyboard players (2026-10-16): K3 = I J K L / O / P, K4 = Numpad 8 4 2 6 / 0 / 5.
	{"id": "C25", "group": "Four seats", "label": "K3 run + jump", "keys": ["L", "I"]},
	{"id": "C26", "group": "Four seats", "label": "K4 run + jump", "keys": ["Num 6", "Num 8"]},
	{"id": "C27", "group": "Place", "label": "K3 pointer + confirm", "keys": ["L", "O"]},
	{"id": "C28", "group": "Place", "label": "K4 pointer + rotate", "keys": ["Num 6", "Num 5"]},
	{
		"id": "C29",
		"group": "Four seats",
		"label": "all four run right",
		"keys": ["D", "Right", "L", "Num 6"]
	},
	{
		"id": "C30",
		"group": "Four seats",
		"label": "all four run right + jump",
		"keys": ["D", "W", "Right", "Up", "L", "I", "Num 6", "Num 8"]
	},
	{
		"id": "C31",
		"group": "Four seats",
		"label": "all four confirm",
		"keys": ["E", "Enter", "O", "Num 0"]
	},
]

const KEY_NAMES := {
	KEY_SPACE: "Space",
	KEY_LEFT: "Left",
	KEY_RIGHT: "Right",
	KEY_UP: "Up",
	KEY_DOWN: "Down",
	KEY_ENTER: "Enter",
	KEY_BACKSPACE: "Backspace",
	KEY_ESCAPE: "Esc",
	KEY_KP_8: "Num 8",
	KEY_KP_4: "Num 4",
	KEY_KP_2: "Num 2",
	KEY_KP_6: "Num 6",
	KEY_KP_0: "Num 0",
	KEY_KP_5: "Num 5",
	KEY_KP_PERIOD: "Num .",
}

var index := 0
var results: Array[Dictionary] = []
var held: Dictionary = {}
var event_log: Array[String] = []
var report_path := ""

var _best_held: PackedStringArray = PackedStringArray()
var _auto_advance := -1.0
var _started_msec := 0

@onready var _chord_label: Label = %ChordLabel
@onready var _keys_label: Label = %KeysLabel
@onready var _status_label: Label = %StatusLabel
@onready var _log_label: Label = %LogLabel
@onready var _summary_label: Label = %SummaryLabel


func _ready() -> void:
	restart()


func restart() -> void:
	index = 0
	held.clear()
	event_log.clear()
	results.clear()
	for chord in CHORDS:
		(
			results
			. append(
				{
					"id": chord.id,
					"status": STATUS_PENDING,
					"best": PackedStringArray(),
					"msec": -1,
				}
			)
		)
	_best_held = PackedStringArray()
	_auto_advance = -1.0
	_started_msec = Time.get_ticks_msec()
	_refresh()


func _input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null:
		return
	var key_code := key.physical_keycode if key.physical_keycode != 0 else key.keycode
	handle_key(int(key_code), int(key.location), key.pressed, key.echo)
	get_viewport().set_input_as_handled()


## One raw key event (also the synthetic entry point for tests).
func handle_key(key_code: int, location: int, pressed: bool, echo: bool = false) -> void:
	if echo:
		return
	var name := key_id(key_code, location)
	if pressed:
		if _handle_control_key(key_code):
			return
		held[name] = true
	else:
		held.erase(name)
	_log("%s %s (location %d)" % [name, "down" if pressed else "up", location])
	if pressed:
		_track_chord()
	_refresh()


func _process(delta: float) -> void:
	if _auto_advance >= 0.0:
		_auto_advance -= delta
		if _auto_advance < 0.0:
			_auto_advance = -1.0
			_move(1)


## Stable name of a physical key: letters, named keys, and Left/Right modifiers.
static func key_id(key_code: int, location: int) -> String:
	if key_code in [KEY_CTRL, KEY_SHIFT, KEY_ALT, KEY_META]:
		var side := "R" if location == KEY_LOCATION_RIGHT else "L"
		var base := "Ctrl"
		if key_code == KEY_SHIFT:
			base = "Shift"
		elif key_code == KEY_ALT:
			base = "Alt"
		elif key_code == KEY_META:
			base = "Meta"
		return side + base
	if KEY_NAMES.has(key_code):
		return str(KEY_NAMES[key_code])
	return OS.get_keycode_string(key_code)


func current_chord() -> Dictionary:
	return CHORDS[clampi(index, 0, CHORDS.size() - 1)]


func status_of(chord_id: String) -> String:
	for row in results:
		if row.id == chord_id:
			return str(row.status)
	return ""


func pass_count() -> int:
	return _count(STATUS_PASS)


func lost_count() -> int:
	return _count(STATUS_LOST)


## The report a tester pastes into PLAYTEST.md (keyboard, layout, one row per chord).
func report_text() -> String:
	var lines := PackedStringArray()
	lines.append("Tilaok! keyboard chord report")
	lines.append("Date: %s" % Time.get_datetime_string_from_system())
	lines.append("OS: %s   Engine: %s" % [OS.get_name(), Engine.get_version_info().string])
	lines.append("Layout: %s" % _layout_name())
	lines.append("Keyboard model / notes: (fill in by hand)")
	lines.append(
		(
			"Result: %d PASS, %d LOST, %d other of %d"
			% [
				pass_count(),
				lost_count(),
				CHORDS.size() - pass_count() - lost_count(),
				CHORDS.size()
			]
		)
	)
	lines.append("")
	for position in CHORDS.size():
		var chord := CHORDS[position]
		var row := results[position]
		var held_text := ", ".join(row.best as PackedStringArray)
		(
			lines
			. append(
				(
					"%s  %-8s %-34s keys: %s  ->  %s%s"
					% [
						chord.id,
						chord.group,
						chord.label,
						" + ".join(chord.keys),
						row.status,
						(
							"  (best simultaneous: %s)" % held_text
							if row.status != STATUS_PASS
							else ""
						),
					]
				)
			)
		)
	return "\n".join(lines) + "\n"


func write_report() -> String:
	var path := "user://%s%d.txt" % [REPORT_PREFIX, Time.get_unix_time_from_system()]
	var file := FileAccess.open(path, FileAccess.WRITE)
	var text := report_text()
	if file != null:
		file.store_string(text)
		file.close()
		report_path = ProjectSettings.globalize_path(path)
	print("KEY_CHORD_REPORT_BEGIN\n%s\nKEY_CHORD_REPORT_END" % text)
	print("KEY_CHORD_REPORT_PATH %s" % report_path)
	_refresh()
	return report_path


# --- internals ----------------------------------------------------------------------------


func _handle_control_key(key_code: int) -> bool:
	var handled := key_code in [KEY_INSERT, KEY_PAGEDOWN, KEY_PAGEUP, KEY_F2, KEY_HOME, KEY_END]
	match key_code:
		KEY_INSERT:
			_mark(STATUS_LOST)
		KEY_PAGEDOWN:
			if status_of(current_chord().id) == STATUS_PENDING:
				_mark(STATUS_SKIPPED)
			_move(1)
		KEY_PAGEUP:
			_move(-1)
		KEY_F2:
			write_report()
		KEY_HOME:
			restart()
		KEY_END:
			return_requested.emit()
	return handled


func _track_chord() -> void:
	var chord := current_chord()
	var needed: Array = chord.keys
	var down := PackedStringArray()
	for name in needed:
		if held.has(str(name)):
			down.append(str(name))
	if down.size() > _best_held.size():
		_best_held = down
	if down.size() == needed.size() and status_of(chord.id) != STATUS_PASS:
		var row := results[index]
		row.status = STATUS_PASS
		row.best = down
		row.msec = Time.get_ticks_msec() - _started_msec
		_auto_advance = AUTO_ADVANCE_SECONDS


func _mark(status: String) -> void:
	var row := results[index]
	row.status = status
	row.best = _best_held
	row.msec = Time.get_ticks_msec() - _started_msec
	_auto_advance = AUTO_ADVANCE_SECONDS if status == STATUS_LOST else -1.0
	_refresh()


func _move(step: int) -> void:
	index = clampi(index + step, 0, CHORDS.size() - 1)
	_best_held = PackedStringArray()
	_auto_advance = -1.0
	_refresh()


func _count(status: String) -> int:
	var total := 0
	for row in results:
		if row.status == status:
			total += 1
	return total


func _log(text: String) -> void:
	event_log.append(text)
	while event_log.size() > LOG_LINES:
		event_log.pop_front()


func _layout_name() -> String:
	var layout := DisplayServer.keyboard_get_current_layout()
	if layout < 0:
		return "unknown"
	return DisplayServer.keyboard_get_layout_name(layout)


func _refresh() -> void:
	if not is_node_ready():
		return
	var chord := current_chord()
	_chord_label.text = (
		"%s  [%d / %d]  %s: %s" % [chord.id, index + 1, CHORDS.size(), chord.group, chord.label]
	)
	var parts := PackedStringArray()
	for name in chord.keys:
		parts.append("[%s] %s" % ["X" if held.has(str(name)) else " ", name])
	_keys_label.text = "Hold together:  " + "   ".join(parts)
	_status_label.text = (
		"Status: %s   (best at once: %d of %d)"
		% [status_of(chord.id), _best_held.size(), (chord.keys as Array).size()]
	)
	_log_label.text = "\n".join(event_log)
	_summary_label.text = (
		"%d PASS   %d LOST   %d / %d done   F2 = report"
		% [
			pass_count(),
			lost_count(),
			pass_count() + lost_count() + _count(STATUS_SKIPPED),
			CHORDS.size()
		]
	)

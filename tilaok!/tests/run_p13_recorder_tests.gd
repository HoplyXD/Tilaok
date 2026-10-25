extends SceneTree

## The keyboard chord recorder (P02-T04 tool): the matrix covers the PROTOTYPE_DEFAULTS bindings,
## a chord is PASS only when every key is down at once, a lost chord is recorded with what did
## register, and the report names every chord. Synthetic events only: this proves the TOOL works,
## never that any physical keyboard does.

const SCENE := preload("res://scenes/tools/key_chord_recorder.tscn")
const SOURCE := "res://scripts/diagnostics/key_chord_recorder.gd"

var checks := 0
var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var recorder := SCENE.instantiate() as KeyChordRecorder
	root.add_child(recorder)
	await process_frame
	_test_matrix(recorder)
	await _test_pass_and_lost(recorder)
	_test_report(recorder)
	_test_tool_is_isolated()
	recorder.queue_free()
	print("P13_RECORDER_TESTS checks=%d failures=%d" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _test_matrix(recorder: KeyChordRecorder) -> void:
	var ids: Dictionary = {}
	var keys: Dictionary = {}
	for chord in KeyChordRecorder.CHORDS:
		ids[chord.id] = true
		for name in chord.keys:
			keys[name] = true
	_check(ids.size() == KeyChordRecorder.CHORDS.size(), "every chord has a unique id")
	_check(ids.size() >= 20, "the matrix has %d chords" % ids.size())
	# Every key the router binds appears somewhere in the matrix.
	for needed in [
		"A",
		"D",
		"W",
		"Space",
		"E",
		"G",
		"R",
		"Left",
		"Right",
		"Up",
		"Enter",
		"Backspace",
		"RCtrl",
		"H",
		"Esc"
	]:
		_check(keys.has(needed), "the matrix uses %s" % needed)
	_check(
		(
			KeyChordRecorder.key_id(KEY_SHIFT, KEY_LOCATION_RIGHT) == "RShift"
			and KeyChordRecorder.key_id(KEY_CTRL, KEY_LOCATION_RIGHT) == "RCtrl"
			and KeyChordRecorder.key_id(KEY_CTRL, KEY_LOCATION_LEFT) == "LCtrl"
		),
		"left and right modifiers are told apart"
	)
	_check(
		recorder.status_of("C01") == KeyChordRecorder.STATUS_PENDING,
		"a fresh run starts every chord PENDING"
	)


func _test_pass_and_lost(recorder: KeyChordRecorder) -> void:
	# C01: A + Space together -> PASS.
	recorder.handle_key(KEY_A, KEY_LOCATION_UNSPECIFIED, true)
	_check(recorder.status_of("C01") == KeyChordRecorder.STATUS_PENDING, "one key is not a chord")
	recorder.handle_key(KEY_SPACE, KEY_LOCATION_UNSPECIFIED, true)
	_check(recorder.status_of("C01") == KeyChordRecorder.STATUS_PASS, "both keys down -> PASS")
	recorder.handle_key(KEY_A, KEY_LOCATION_UNSPECIFIED, false)
	recorder.handle_key(KEY_SPACE, KEY_LOCATION_UNSPECIFIED, false)
	# Echo events never count.
	recorder.handle_key(KEY_D, KEY_LOCATION_UNSPECIFIED, true, true)
	_check(recorder.held.is_empty(), "key-repeat echoes are ignored")
	# Move on (the auto-advance timer is a frame loop; use Page Down).
	recorder.handle_key(KEY_PAGEDOWN, KEY_LOCATION_UNSPECIFIED, true)
	_check(recorder.current_chord().id == "C02", "Page Down moves to the next chord")
	# C02: D only, then Insert -> LOST with the best set recorded.
	recorder.handle_key(KEY_D, KEY_LOCATION_UNSPECIFIED, true)
	recorder.handle_key(KEY_INSERT, KEY_LOCATION_UNSPECIFIED, true)
	_check(recorder.status_of("C02") == KeyChordRecorder.STATUS_LOST, "Insert records LOST")
	var report := recorder.report_text()
	_check(report.contains("C02") and report.contains("LOST"), "the report lists the lost chord")
	_check(report.contains("best simultaneous: D"), "the lost chord names what did register")
	_check(recorder.pass_count() == 1 and recorder.lost_count() == 1, "counts are 1 PASS, 1 LOST")
	# Two-seat chord with right-hand modifiers.
	recorder.handle_key(KEY_PAGEDOWN, KEY_LOCATION_UNSPECIFIED, true)
	recorder.handle_key(KEY_PAGEDOWN, KEY_LOCATION_UNSPECIFIED, true)
	recorder.handle_key(KEY_PAGEDOWN, KEY_LOCATION_UNSPECIFIED, true)
	recorder.handle_key(KEY_PAGEDOWN, KEY_LOCATION_UNSPECIFIED, true)
	recorder.handle_key(KEY_PAGEDOWN, KEY_LOCATION_UNSPECIFIED, true)
	recorder.handle_key(KEY_PAGEDOWN, KEY_LOCATION_UNSPECIFIED, true)
	_check(recorder.current_chord().id == "C08", "the run reaches C08")
	recorder.handle_key(KEY_PAGEUP, KEY_LOCATION_UNSPECIFIED, true)
	_check(recorder.current_chord().id == "C07", "Page Up goes back")
	for entry in [[KEY_D, 0], [KEY_SPACE, 0], [KEY_RIGHT, 0], [KEY_CTRL, KEY_LOCATION_RIGHT]]:
		recorder.handle_key(entry[0], entry[1], true)
	_check(
		recorder.status_of("C07") == KeyChordRecorder.STATUS_PASS,
		"a four-key two-seat chord with Right Ctrl passes"
	)
	recorder.restart()
	_check(recorder.pass_count() == 0, "Home restarts the run")


func _test_report(recorder: KeyChordRecorder) -> void:
	var report := recorder.report_text()
	for chord in KeyChordRecorder.CHORDS:
		_check(report.contains(chord.id), "the report names %s" % chord.id)
	_check(
		report.contains("Layout:") and report.contains("Keyboard model"), "layout and model lines"
	)
	_check(report.contains("OS:"), "the report names the OS")


func _test_tool_is_isolated() -> void:
	var text := FileAccess.get_file_as_string(SOURCE)
	for token in ["LocalInputRouter", "Input.parse_input_event", "get_tree().paused"]:
		var hit := false
		for line in text.split("\n"):
			var stripped := line.strip_edges()
			if not stripped.begins_with("#") and stripped.contains(token):
				hit = true
		_check(not hit, "the recorder never touches %s" % token)


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("P13_RECORDER FAIL: " + message)
	print("%s %s" % ["PASS" if condition else "FAIL", message])

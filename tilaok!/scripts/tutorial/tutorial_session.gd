class_name TutorialSession
extends RefCounted

## Session-only tutorial memory, owned by GameFlow. Nothing here is saved: no file, no ConfigFile,
## no user:// write, and no tutorial bonus. A new app launch always starts a fresh session.

signal changed

var skipped := false
var completed := false
var seen_lagsanay := false


## True while the guided first match should use the tutorial stage layout and coach box.
func is_active() -> bool:
	return not skipped and not completed


## The next match uses the tutorial layout only while the tutorial is still active.
func wants_tutorial_layout() -> bool:
	return is_active()


func skip() -> void:
	if skipped:
		return
	skipped = true
	changed.emit()


func mark_completed() -> void:
	if completed:
		return
	completed = true
	changed.emit()


func mark_lagsanay_seen() -> void:
	if seen_lagsanay:
		return
	seen_lagsanay = true
	changed.emit()


## "Replay tutorial" clears the whole session set (steps, skip and the Lagsanay prompt).
func replay() -> void:
	skipped = false
	completed = false
	seen_lagsanay = false
	changed.emit()


func lagsanay_prompt_due() -> bool:
	return not skipped and not seen_lagsanay

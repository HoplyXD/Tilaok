class_name NetworkHelpCards
extends PanelContainer

## NLB-P10 phone help cards. A client teaches itself locally from the same TutorialScript data the
## offline coach uses (the network_* steps), so no host authority, wire family or host UI is needed.
## Skip and Replay follow the session-only tutorial policy (TutorialSession: nothing is saved, Back
## only steps to the previous card and is not Skip). Copy is PLACEHOLDER English; the final look is
## Shanti's design pass.

const SCRIPT_PATH := "res://data/ui/tutorial_script.tres"
const PROMPT_MAP_PATH := "res://data/ui/prompt_map.tres"
const DEVICE := "touch"
## PROPOSED, in viewport px: the same floor the touch layer starts from.
const BUTTON_MIN := Vector2(96, 48)

signal closed

var session := TutorialSession.new()
var tutorial_script: TutorialScript
var prompt_map: UiPromptMap
var seat := -1
var index := 0
var _auto_opened := false
var _title: Label
var _body: Label
var _back: Button
var _next: Button
var _skip: Button
var _close: Button


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	custom_minimum_size = Vector2(480, 0)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	add_child(column)
	var tag := Label.new()
	tag.text = "PLACEHOLDER copy"
	tag.add_theme_font_size_override("font_size", 12)
	column.add_child(tag)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 20)
	column.add_child(_title)
	_body = Label.new()
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.custom_minimum_size = Vector2(448, 0)
	_body.add_theme_font_size_override("font_size", 18)
	column.add_child(_body)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	column.add_child(row)
	_back = _button(row, "Back", _on_back)
	_next = _button(row, "Next", _on_next)
	_skip = _button(row, "Skip", _on_skip)
	_close = _button(row, "Close", close)
	_ensure_data()


func _ensure_data() -> void:
	if tutorial_script == null:
		tutorial_script = load(SCRIPT_PATH) as TutorialScript
	if prompt_map == null:
		prompt_map = load(PROMPT_MAP_PATH) as UiPromptMap


## Token values come from the prompt map for the touch device, so the copy never hard-codes a key.
static func tokens(map: UiPromptMap, seat_index: int) -> Dictionary:
	var values := {
		"seat": "P%d" % (seat_index + 1) if seat_index >= 0 else "your chicken",
		"navigate": map.glyph("navigate", DEVICE) if map != null else "?",
	}
	var pairs := {
		"jump": "jump", "claim": "claim", "build": "build_toggle", "aim": "aim",
		"rotate_live": "live_rotate", "place": "live_confirm", "cancel": "live_cancel",
		"ready": "ready", "pause": "pause",
	}
	for token in pairs:
		values[token] = map.glyph(str(pairs[token]), DEVICE) if map != null else "?"
	return values


static func render_body(step: TutorialStepDef, map: UiPromptMap, seat_index: int) -> String:
	var text := step.body
	var values := tokens(map, seat_index)
	for token in values:
		text = text.replace("{%s}" % token, str(values[token]))
	return text


func card_count() -> int:
	return TutorialScript.NETWORK_STEPS.size()


## Shows the cards once per session on the first match state, unless the session skipped them.
func auto_open_once() -> void:
	if _auto_opened or not session.is_active():
		return
	_auto_opened = true
	open(0)


## The local Menu opens the cards again: a skipped session offers Replay instead.
func open_from_menu() -> void:
	open(index if session.is_active() else 0)


func open(card_index: int = 0) -> void:
	_ensure_data()
	index = clampi(card_index, 0, card_count() - 1)
	visible = true
	_refresh()


func close() -> void:
	if visible:
		visible = false
		closed.emit()


func skip() -> void:
	session.skip()
	_refresh()


func replay() -> void:
	session.replay()
	open(0)


func next_card() -> void:
	if index >= card_count() - 1:
		session.mark_completed()
		close()
		return
	open(index + 1)


func previous_card() -> void:
	open(index - 1)


func _refresh() -> void:
	if _title == null:
		return
	if not session.is_active():
		_title.text = "Tutorial skipped"
		_body.text = "Replay brings the phone help cards back for this session."
		_back.visible = false
		_next.text = "Replay"
		_skip.visible = false
		return
	var step := tutorial_script.step(TutorialScript.NETWORK_STEPS[index]) if tutorial_script != null else null
	_title.text = step.title if step != null else ""
	_body.text = render_body(step, prompt_map, seat) if step != null else ""
	_back.visible = index > 0
	_next.text = "Done" if index >= card_count() - 1 else "Next"
	_skip.visible = true


func _on_next() -> void:
	if not session.is_active():
		replay()
	else:
		next_card()


func _on_back() -> void:
	previous_card()


func _on_skip() -> void:
	skip()


func _button(row: HBoxContainer, label: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = BUTTON_MIN
	button.add_theme_font_size_override("font_size", 18)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(callback)
	row.add_child(button)
	return button

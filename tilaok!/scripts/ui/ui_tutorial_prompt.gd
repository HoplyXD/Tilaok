class_name UiTutorialPrompt
extends UiScreen

## Coach box: the "Guide:" card from Figma frame 91:2 (UI-Tilaok-), shown at 1.125x so the body
## stays 18 px. In the gallery it shows SAMPLE steps and `_back()` still emits `skip_requested`.
## In a live match `bind_live()` makes it display-only: it is never attached to the input bridge,
## never owns a router phase and never reacts to Back, so no press can activate it twice.

signal skip_requested

## Virtual-pixel top edge of the box: under the phase banner during a match. Left column,
## narrow: it never covers the Place legend, the 64 px HUD bar or the Place status strip.
@export var match_offset_top := 167.0
## The Welcome step (Lobby) sits in the top-left corner, wider and shorter, so it stays above
## the seat slots (top at y 196) and left of the map arrows (x 452), even with four players.
@export var lobby_offset_top := 24.0
@export var lobby_width := 400.0
## The live-build lesson has a short action list, so give it enough width to read during Play.
@export var live_build_width := 320.0
## Left edge for the Results step: inside the strip the Round result screen keeps free, so the
## box never covers an outcome row or an award line. The 263 px card ends at x 1210.
@export var results_offset_left := 947.0
## Width the Round result screen reserves at its right edge for this box (box width + gap).
@export var results_strip_width := 303.0

var _live := false
var _match_left := 0.0
var _match_right := 0.0

@onready var _anchor: Control = %Anchor
@onready var _step_label: Label = %StepLabel
@onready var _body_label: Label = %BodyLabel
@onready var _prompt: UiPromptGlyph = %PromptGlyph
@onready var _skip_text: Label = %SkipText
@onready var _skip_hint: UiPromptGlyph = %SkipHint
@onready var _tag: Label = %Tag


func state_names() -> PackedStringArray:
	return PackedStringArray(["Move and jump", "Claim an egg", "Build while playing"])


func _on_screen_ready() -> void:
	_match_left = _anchor.offset_left
	_match_right = _anchor.offset_right


func router_phase() -> int:
	return LocalInputRouter.Phase.MENU


func is_live() -> bool:
	return _live


func bind_step(title: String, body: String, action: String, ctx: UiContext) -> void:
	_step_label.text = title
	_body_label.text = body
	_prompt.bind(action, ctx.device_kind, ctx.prompt_map)
	_skip_hint.bind("back", ctx.device_kind, ctx.prompt_map)


## Live binding from TutorialCoordinator's view dictionary. Text only; layout stays in the scene.
func bind_live(view: Dictionary) -> void:
	_live = true
	var shown := bool(view.get("visible", false))
	visible = shown
	if not shown:
		return
	var step_id := str(view.get("step_id", ""))
	var width := _match_right - _match_left
	if step_id == "welcome":
		width = lobby_width
	elif step_id in ["live_build", "live_place"]:
		width = live_build_width
	var left := results_offset_left if step_id == "results" else _match_left
	_anchor.offset_left = left
	_anchor.offset_right = left + width
	_anchor.offset_top = lobby_offset_top if step_id == "welcome" else match_offset_top
	_anchor.offset_bottom = _anchor.offset_top
	_step_label.text = str(view.get("title", ""))
	_body_label.text = str(view.get("body", ""))
	# The glyphs are written into the body text per seat device, so the chip glyphs stay hidden:
	# the card's footer is the skip caption alone, as in the Figma frame.
	_prompt.visible = false
	_skip_text.text = str(view.get("skip_caption", ""))
	_skip_hint.visible = false
	_tag.text = str(view.get("tag", ""))


func _show_state(index: int, ctx: UiContext) -> void:
	_live = false
	# Same card as in a match: the chip glyphs stay hidden (scene default) and the footer keeps
	# the scene's "Pause > Skip tutorial" caption.
	var steps := [
		[
			"Step 1 of 5 - Welcome",
			"Find your chicken: look for your number and shape. Run and jump to the marker.",
			"jump"
		],
		["Step 2 of 5 - Pugad", ctx.sample.tutorial_body, "claim"],
		[
			"Step 3 of 5 - Build while you play",
			(
				"Enter BUILD to aim (your chicken pauses). Confirm: move again while the visible build "
				+ "finishes. Started builds complete automatically; hazards activate immediately. "
				+ "Cancel closes an unconfirmed preview."
			),
			"build_toggle"
		],
	]
	var step: Array = steps[clampi(index, 0, steps.size() - 1)]
	bind_step(step[0], step[1], step[2], ctx)


func _back(_seat_index: int) -> bool:
	if _live:
		return false
	skip_requested.emit()
	return true

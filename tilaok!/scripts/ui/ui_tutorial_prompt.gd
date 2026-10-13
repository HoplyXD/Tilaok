class_name UiTutorialPrompt
extends UiScreen

signal skip_requested

@onready var _step_label: Label = %StepLabel
@onready var _body_label: Label = %BodyLabel
@onready var _prompt: UiPromptGlyph = %PromptGlyph
@onready var _skip_hint: UiPromptGlyph = %SkipHint


func state_names() -> PackedStringArray:
	return PackedStringArray(["Move and jump", "Claim an egg", "Place and rotate"])


func router_phase() -> int:
	return LocalInputRouter.Phase.MENU


func bind_step(title: String, body: String, action: String, ctx: UiContext) -> void:
	_step_label.text = title
	_body_label.text = body
	_prompt.bind(action, ctx.device_kind, ctx.prompt_map)
	_skip_hint.bind("back", ctx.device_kind, ctx.prompt_map)


func _show_state(index: int, ctx: UiContext) -> void:
	var steps := [
		[
			"Step 1 of 6",
			"Find your chicken: look for your number and shape. Run and jump to the marker.",
			"jump"
		],
		["Step 3 of 6", ctx.sample.tutorial_body, "claim"],
		[
			"Step 4 of 6",
			"Move the piece, rotate it, then confirm. Red outline means it cannot go there.",
			"rotate"
		],
	]
	var step: Array = steps[clampi(index, 0, steps.size() - 1)]
	bind_step(step[0], step[1], step[2], ctx)


func _back(_seat_index: int) -> bool:
	skip_requested.emit()
	return true

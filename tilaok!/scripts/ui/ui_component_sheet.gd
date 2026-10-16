class_name UiComponentSheet
extends UiScreen

## Gallery-only review sheet: every restyled component in each of its looks, side by side.
## Everything is authored in component_sheet.tscn; this script only binds SAMPLE seats so the
## pills and chips show all four number + shape identities.

var pills: Array[UiScoreRow] = []
var chips: Array[UiScoreRow] = []
var prompts: Array[UiPromptGlyph] = []


func state_names() -> PackedStringArray:
	return PackedStringArray(["Buttons, panels, pills"])


func _on_screen_ready() -> void:
	pills = [%Pill1, %Pill2, %Pill3, %Pill4]
	chips = [%Chip1, %Chip2, %Chip3, %Chip4]
	prompts = [%ReadyPrompt, %HelpPrompt, %BackPrompt]


func _show_state(_index: int, ctx: UiContext) -> void:
	var seats := UiContext.sample_seats(PlayerSeatRegistry.MAX_SEATS)
	var pill_states := ["READY", "WAITING", "READY", "DEVICE LOST"]
	var chip_states := ["Placed", "Placed", "Placing", "Placing"]
	for index in seats.size():
		pills[index].bind_roster(seats[index], pill_states[index])
		chips[index].bind_texts(seats[index], "0", chip_states[index])
	var actions := ["ready", "help", "back"]
	for index in prompts.size():
		prompts[index].bind(actions[index], ctx.device_kind, ctx.prompt_map)

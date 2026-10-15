class_name KangarooCommandStyle
extends RefCounted

## DEBUG placeholder presentation for Kangaroo commands, shared by the P11 lab and the P12
## scheduled match: prompt panels, non-colour icons, colours, cue tones and marker text. Final
## art and audio stay with the human team; nothing here affects a rule or a timing.

const PROMPT_SCENE := preload("res://scenes/ui/components/kangaroo_prompt.tscn")
const RING_SCENE := preload("res://scenes/ui/components/countdown_ring.tscn")


static func instruction(command: Dictionary) -> String:
	match int(command.command):
		KangarooRoundController.Command.FREEZE:
			return "Freeze: no intentional run or jump input. Forced motion does not count."
		KangarooRoundController.Command.RISING:
			return "Rising: stand on built support above %.0f wu." % float(command.wave_y)
		KangarooRoundController.Command.HUG:
			return "Hug: pair with one live chicken at evaluation."
	return ""


## Plain-language requirement shown to players (no world units or internal ids).
static func player_instruction(command: int) -> String:
	match command:
		KangarooRoundController.Command.FREEZE:
			return "Freeze: stop running and jumping until the ring ends."
		KangarooRoundController.Command.RISING:
			return "Rising wave: stand on a piece the players built, above the line."
		KangarooRoundController.Command.HUG:
			return "Hug: be paired with exactly one other live chicken when the ring ends."
	return ""


## The three miss steps with the missed ones bracketed ("[KANG]  [GA]  ROO"): text, not colour.
static func marker_steps(count: int) -> String:
	var names: Array[String] = ["KANG", "GA", "ROO"]
	var parts: Array[String] = []
	for index in names.size():
		parts.append("[%s]" % names[index] if index < count else names[index])
	return "  ".join(parts)


## One row per seat for the HUD: "P2 ▲  [KANG]  GA  ROO".
static func marker_rows(
	controller: KangarooRoundController, registry: PlayerSeatRegistry
) -> PackedStringArray:
	var rows := PackedStringArray()
	for seat in controller.seat_indices:
		var seat_data := registry.get_seat(int(seat))
		var mark: String = LobbyViewModel.SHAPE_MARKS.get(str(seat_data.get("shape", "")), "◆")
		rows.append(
			(
				"P%d %s  %s"
				% [
					int(seat_data.get("identity", int(seat) + 1)),
					mark,
					marker_steps(int(controller.marker_counts.get(seat, 0)))
				]
			)
		)
	return rows


static func icon(command: int) -> String:
	match command:
		KangarooRoundController.Command.FREEZE:
			return "●"
		KangarooRoundController.Command.RISING:
			return "↑"
		KangarooRoundController.Command.HUG:
			return "↔"
	return "?"


static func color(command: int) -> Color:
	match command:
		KangarooRoundController.Command.FREEZE:
			return Color("#f2c14e")
		KangarooRoundController.Command.RISING:
			return Color("#39b9c9")
		KangarooRoundController.Command.HUG:
			return Color("#e47ab2")
	return Color.WHITE


static func frequency(command: int) -> int:
	match command:
		KangarooRoundController.Command.FREEZE:
			return 330
		KangarooRoundController.Command.RISING:
			return 440
		KangarooRoundController.Command.HUG:
			return 554
	return 0


## "P1 [KANG]  GA  ROO     P2 KANG  GA  ROO": each seat's failure markers.
static func marker_status(
	controller: KangarooRoundController, registry: PlayerSeatRegistry
) -> String:
	var parts: Array[String] = []
	for seat in controller.seat_indices:
		var count := int(controller.marker_counts.get(seat, 0))
		var steps := "KANG  GA  ROO"
		if count == 1:
			steps = "[KANG]  GA  ROO"
		elif count == 2:
			steps = "[KANG]  [GA]  ROO"
		elif count >= 3:
			steps = "[KANG]  [GA]  [ROO]"
		parts.append("P%d %s" % [int(registry.get_seat(seat).get("identity", seat + 1)), steps])
	return "     ".join(parts)


## A short decaying sine cue (DEBUG placeholder audio).
static func make_tone(tone_frequency: float) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.stereo = false
	var sample_count := 2205
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for index in range(sample_count):
		var envelope := 1.0 - float(index) / float(sample_count)
		var sample := int(
			sin(TAU * tone_frequency * float(index) / float(stream.mix_rate)) * 5200.0 * envelope
		)
		var unsigned_sample := sample & 0xffff
		data[index * 2] = unsigned_sample & 0xff
		data[index * 2 + 1] = (unsigned_sample >> 8) & 0xff
	stream.data = data
	return stream


## Builds one command prompt panel under `stack`; returns its parts for `update_panel`.
static func create_panel(command: Dictionary, stack: Container) -> Dictionary:
	var root := PROMPT_SCENE.instantiate() as PanelContainer
	root.name = "Command_%d" % int(command.command_id)
	root.custom_minimum_size = Vector2(590.0, 112.0)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var type := int(command.command)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#101f27")
	style.bg_color.a = 0.9
	style.border_color = color(type)
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	style.content_margin_left = 12
	style.content_margin_right = 10
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	root.add_theme_stylebox_override("panel", style)
	var template_row := root.get_node("Row") as HBoxContainer
	root.remove_child(template_row)
	template_row.queue_free()
	var content := VBoxContainer.new()
	content.name = "DebugCommandContent"
	content.add_theme_constant_override("separation", 4)
	var row := HBoxContainer.new()
	row.name = "DebugCommandHeader"
	row.add_theme_constant_override("separation", 10)
	var details := HBoxContainer.new()
	details.name = "DebugCommandDetails"
	details.add_theme_constant_override("separation", 10)
	root.add_child(content)
	content.add_child(row)
	content.add_child(details)
	var icon_label := Label.new()
	icon_label.name = "DebugPoseIcon"
	icon_label.text = icon(type)
	icon_label.add_theme_font_size_override("font_size", 32)
	icon_label.custom_minimum_size = Vector2(44.0, 0.0)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(icon_label)
	var pose := Label.new()
	pose.name = "DebugPoseText"
	pose.add_theme_font_size_override("font_size", 18)
	pose.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(pose)
	var steps := Label.new()
	steps.name = "DebugPoseSteps"
	steps.add_theme_font_size_override("font_size", 12)
	steps.custom_minimum_size = Vector2(190.0, 0.0)
	details.add_child(steps)
	var note := Label.new()
	note.name = "DebugCommandNote"
	note.add_theme_font_size_override("font_size", 11)
	note.custom_minimum_size = Vector2(330.0, 0.0)
	note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_child(note)
	var ring := RING_SCENE.instantiate() as UiCountdownRing
	ring.name = "CommandCountdown"
	ring.custom_minimum_size = Vector2(195.0, 0.0)
	row.add_child(ring)
	stack.add_child(root)
	return {
		"root": root, "pose": pose, "steps": steps, "note": note, "ring": ring, "icon": icon_label
	}


## Refreshes a panel's text and countdown for the command's current status.
static func update_panel(panel: Dictionary, command: Dictionary, active_time: float) -> void:
	var type := int(command.command)
	var is_telegraph := str(command.status) == "TELEGRAPH"
	var countdown_start := (
		float(command.response_start_at) if is_telegraph else float(command.response_end_at)
	)
	var countdown_total := (
		float(command.response_start_at) - float(command.telegraph_start_at)
		if is_telegraph
		else float(command.response_end_at) - float(command.response_start_at)
	)
	panel.pose.text = (
		"DEBUG POSE • %s  %s" % [icon(type), KangarooRoundController.command_name(type)]
	)
	panel.steps.text = "DEBUG AUDIO %d Hz • KANG  →  GA  →  ROO" % frequency(type)
	panel.note.text = "DEBUG • " + instruction(command)
	if bool(command.is_storm):
		panel.pose.text += " • STORM %d" % int(command.command_id)
	panel.ring.set_time(maxf(0.0, countdown_start - active_time), countdown_total)

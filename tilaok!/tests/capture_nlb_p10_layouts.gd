extends SceneTree

## Rendered layout captures for NLB-P10 (touch controls, HUD and help cards per window aspect).
## Needs a rendering (non-headless) run. Synthetic layout captures only: they are neither physical
## touch evidence nor human-session evidence, and the safe-area dp numbers stay proposals.
## Run: Godot --fixed-fps 60 --path tilaok! --script res://tests/capture_nlb_p10_layouts.gd

const OUTPUT_RELATIVE := "../docs/evidence/nlb/p10/captures"
const WINDOWS := {
	"16x9": Vector2i(1280, 720),
	"19_5x9": Vector2i(1560, 720),
	"20x9": Vector2i(1600, 720),
	"4x3": Vector2i(960, 720),
}

var output_dir := ""
var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	output_dir = ProjectSettings.globalize_path("res://").path_join(OUTPUT_RELATIVE).simplify_path()
	DirAccess.make_dir_recursive_absolute(output_dir)
	for label in WINDOWS:
		root.size = WINDOWS[label]
		await _capture(str(label))
	print("NLB_P10_LAYOUT_CAPTURE failures=%d output=%s input=none-synthetic-layout" % [failures, output_dir])
	await process_frame
	quit(1 if failures > 0 else 0)


func _capture(label: String) -> void:
	var presentation := NetworkMatchPresentation.new()
	presentation.touch_controls_forced = true
	root.add_child(presentation)
	await process_frame
	var layer := presentation.get_node("NetworkTouchLayer") as NetworkTouchLayer
	layer.configure(true)
	layer.relayout()
	var hud := presentation.get_node("NetworkPhoneHud") as NetworkPhoneHud
	hud.set_seat(1)
	hud.set_placement(NetworkLivePlacementClient.GhostState.REJECTED, "Rejected: blocked")
	presentation.apply_state({"metadata": {"phase": MatchPhaseController.Phase.PLAY, "remaining_ms": 45000}, "seats": {}, "entities": {}})
	await _save("%s-live-controls.png" % label)
	(presentation.get_node("NetworkHelpCards") as NetworkHelpCards).open(3)
	await _save("%s-help-build-mode.png" % label)
	presentation.queue_free()
	await process_frame


func _save(file_name: String) -> void:
	await process_frame
	await process_frame
	var texture := root.get_texture()
	var image := texture.get_image() if texture != null else null
	if image == null:
		failures += 1
		push_error("NLB_P10_CAPTURE viewport image unavailable: %s" % file_name)
		return
	var error := image.save_png(output_dir.path_join(file_name))
	print("NLB_P10_CAPTURE file=%s error=%d" % [file_name, error])
	if error != OK:
		failures += 1

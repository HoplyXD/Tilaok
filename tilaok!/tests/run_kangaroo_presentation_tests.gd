extends SceneTree

## Headless resource and lifecycle checks for the P23 illustrated presentation.

const CARD_SCENE := preload("res://scenes/ui/components/kangaroo_command_card.tscn")
const FREEZE := preload("res://assets/events/kangaroo/kangaroo_slipper_freeze_top.png")
const RISING := preload("res://assets/events/kangaroo/kangaroo_slipper_rising_outsole.png")
const HUG := preload("res://assets/events/kangaroo/kangaroo_slipper_hug_side.png")
const RISING_SURFACE := preload("res://assets/events/kangaroo/kangaroo_rising_surface_blend.png")
const PRESENTER := preload("res://scripts/match/kangaroo_slipper_presenter.gd")

var checks := 0
var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var card := CARD_SCENE.instantiate() as UiKangarooCommandCard
	root.add_child(card)
	await process_frame
	for entry in [
		[KangarooRoundController.Command.FREEZE, FREEZE, "FREEZE"],
		[KangarooRoundController.Command.RISING, RISING, "RISING"],
		[KangarooRoundController.Command.HUG, HUG, "HUG"],
	]:
		card.bind(_command(int(entry[0])), 0.5)
		var art := card.get_node("%Art_PoseIcon") as TextureRect
		_check(
			art.visible and art.texture == entry[1], "%s card binds its illustrated pose" % entry[2]
		)
		_check(card.pose_text() == entry[2], "%s card retains command text" % entry[2])
		_check(card.phase_text() == "GET READY", "%s card retains timing phase" % entry[2])
	_check(card.get_node_or_null("StormLabel") == null, "command card has no retired Storm label")
	var presenter := PRESENTER.new() as KangarooSlipperPresenter
	presenter.use_illustrated_art = true
	root.add_child(presenter)
	var rising := _command(KangarooRoundController.Command.RISING)
	rising["wave_y"] = 350.0
	rising["response_start_at"] = 0.0
	rising["response_end_at"] = 2.0
	presenter.set_state(
		[rising],
		Rect2(0, 0, 1000, 800),
		700,
		1.0,
		Vector2.ZERO
	)
	_check(presenter.visible, "P23 presenter accepts a command presentation state")
	_check(
		presenter.get_child_count() == 1
			and presenter.get_node_or_null("RisingWaterBody") is ColorRect,
		"slipper presenter reuses one non-colliding water fill visual"
	)
	var water_body := presenter.get_node("RisingWaterBody") as ColorRect
	_check(water_body.visible and water_body.size.y > 0.0, "Rising fills the body to the live surface")
	_check(
		is_equal_approx(water_body.position.y, 525.0),
		"Rising fill begins at the same live simulation height as the illustrated surface"
	)
	_check(
		(water_body.material as ShaderMaterial).shader != null,
		"Rising body uses a seamless procedural water pattern"
	)
	var surface_image := RISING_SURFACE.get_image()
	_check(
		surface_image.get_height() == 86 and surface_image.get_pixel(768, 85).a == 0.0,
		"Rising surface art feathers into the underbody instead of drawing a hard lower edge"
	)
	var chicken := ChickenController.new()
	root.add_child(chicken)
	await process_frame
	var accent := chicken.get_node("KangarooFreezeAccent") as Sprite2D
	_check(not accent.visible, "Freeze accent starts cleared")
	_check(chicken.set_kangaroo_frozen(2.0), "Freeze lifecycle accepts the presentation fixture")
	_check(accent.visible, "Freeze accent appears with the existing Freeze state")
	chicken._set_freeze_tint(false)
	_check(not accent.visible, "Freeze accent clears with the existing thaw path")
	print("KANGAROO_PRESENTATION_TESTS checks=%d failures=%d" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _command(command_type: int) -> Dictionary:
	return {
		"command": command_type,
		"command_id": 1,
		"is_storm": false,
		"status": "TELEGRAPH",
		"telegraph_start_at": 0.0,
		"response_start_at": 2.0,
		"response_end_at": 8.0,
	}


func _check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("PASS " + message)
	else:
		failures += 1
		push_error("FAIL " + message)

class_name UiPlaceOverlay
extends UiScreen

const PLACE_SECONDS := 15.0

var pointer_chips: Array[UiPlayerBadge] = []

@onready var _phase_banner: UiPhaseBanner = %PhaseBanner
@onready var _countdown: UiCountdownRing = %Countdown
@onready var _reason_toast: UiToastLine = %ReasonToast
@onready var _ghost_status: Label = %GhostStatus


func state_names() -> PackedStringArray:
	return PackedStringArray(
		["Valid", "Invalid with reason", "Protected zone", "Rotation unavailable", "Confirmed"]
	)


func router_phase() -> int:
	return LocalInputRouter.Phase.PLACE


func _on_screen_ready() -> void:
	pointer_chips = [%Pointer1, %Pointer2, %Pointer3, %Pointer4]


func _show_state(index: int, ctx: UiContext) -> void:
	_phase_banner.set_phase("PLACE", "Position, rotate, confirm")
	_countdown.set_time(11.0, PLACE_SECONDS)
	for chip_index in pointer_chips.size():
		var seat: Dictionary = ctx.seats[chip_index] if chip_index < ctx.seats.size() else {}
		pointer_chips[chip_index].bind_seat(seat)
		pointer_chips[chip_index].visible = not seat.is_empty() and bool(seat.get("joined", false))
	var marks := [
		"[OK] Valid - confirm to place",
		"[X] Blocked",
		"[LOCK] Protected zone",
		"[NO TURN] Cannot rotate",
		"[SET] Placed"
	]
	var reasons := [
		"",
		"Overlaps the ground",
		"Too close to the spawn area",
		"This piece only fits this way",
		""
	]
	_ghost_status.text = marks[clampi(index, 0, marks.size() - 1)]
	_reason_toast.show_text(reasons[clampi(index, 0, reasons.size() - 1)])

class_name UiPlaceOverlay
extends UiScreen

const PLACE_SECONDS := 15.0
const MARK_VALID := "[OK] Valid"
const MARK_BLOCKED := "[X] Blocked"
const MARK_LOCKED := "[SET] Locked"
## Guide card (Figma "Obstacle Place"): title and the gallery sample of the live three-line hint.
const GUIDE_TITLE := "Guide"
const SAMPLE_GUIDE := "Move: W A S D/I J K L\nRotate: R/P\nConfirm: E/O"

var pointer_chips: Array[UiPlayerBadge] = []
var seat_rows: Array[UiScoreRow] = []

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


## Live: one status row per seat (variant + valid / blocked / locked), the live reason text
## and the real Place countdown. rows are dictionaries {seat_index, variant, confirmed, allowed}.
func bind_live(
	seats: Array[Dictionary],
	rows: Array[Dictionary],
	reason_text: String,
	hint_text: String,
	remaining: float,
	total: float
) -> void:
	_phase_banner.set_phase(GUIDE_TITLE, hint_text)
	_countdown.set_time(remaining, total)
	# The status rows below carry each seat's number and shape; the identity chips stay hidden.
	for chip in pointer_chips:
		chip.visible = false
	var locked := 0
	for index in seat_rows.size():
		var row: Dictionary = rows[index] if index < rows.size() else {}
		seat_rows[index].visible = not row.is_empty()
		if row.is_empty():
			continue
		var seat: Dictionary = seats[int(row.seat_index)]
		var mark := MARK_BLOCKED
		if bool(row.confirmed):
			mark = MARK_LOCKED
			locked += 1
		elif bool(row.allowed):
			mark = MARK_VALID
		seat_rows[index].bind_roster(seat, "%s %s" % [row.variant, mark])
	_ghost_status.text = "%d of %d locked" % [locked, rows.size()]
	_reason_toast.show_text(reason_text)


func _on_screen_ready() -> void:
	pointer_chips = [%Pointer1, %Pointer2, %Pointer3, %Pointer4]
	seat_rows = [%SeatStatus1, %SeatStatus2, %SeatStatus3, %SeatStatus4]


func _show_state(index: int, ctx: UiContext) -> void:
	_phase_banner.set_phase(GUIDE_TITLE, SAMPLE_GUIDE)
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

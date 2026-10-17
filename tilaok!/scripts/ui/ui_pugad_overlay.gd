class_name UiPugadOverlay
extends UiScreen

signal claim_requested(seat_index: int, slot_index: int, variant_key: String)

const SELECTION_SECONDS := 8.0
## HUD chip words and the countdown caption (Figma "Obstacle Pick").
const PICKED_STATE := "Picked"
const CHOOSING_STATE := "Choosing"
const PICK_HINT_FORMAT := "%s  Pick"
const COUNT_FORMAT := "%d / %d picked"

var egg_slots: Array[UiEggSlot] = []
var selected := 0
var _egg_ids := PackedStringArray()

@onready var _phase_banner: UiPhaseBanner = %PhaseBanner
@onready var _countdown: UiCountdownRing = %Countdown
@onready var _announce: UiPhaseBanner = %AnnounceBanner
@onready var _lost_claim: UiToastLine = %LostClaimToast
@onready var _round_label: Label = %HudRound
@onready var _challenge_label: Label = %HudChallenge
@onready var _twist_tag: Label = %HudTwist
@onready var _pick_hint: Label = %PickHint
@onready var _spots: Control = %Spots
@onready var hud_chips: Array[UiScoreRow] = [%HudChip1, %HudChip2, %HudChip3, %HudChip4]


func state_names() -> PackedStringArray:
	return PackedStringArray(["Choosing", "Claimed by players", "Lost claim", "Event next round"])


func router_phase() -> int:
	return LocalInputRouter.Phase.PUGAD


func bind_eggs(
	definitions: ItemDefinitions, keys: PackedStringArray, tuning: GameplayTuning
) -> int:
	var shown := 0
	for index in egg_slots.size():
		var slot := egg_slots[index]
		slot.visible = false
		if index < keys.size() and slot.configure(definitions, keys[index], tuning):
			slot.visible = true
			shown += 1
	selected = 0
	_refresh_selection()
	_layout_eggs(shown)
	return shown


## Places each egg card on its nest spot for this many eggs. The spots are scene markers
## (Spots/Spots4…6/SpotN, each with a Pill marker) so the layout stays editable in the 2D editor.
func _layout_eggs(count: int) -> void:
	var spots := _spots.get_node_or_null("Spots%d" % clampi(count, 4, 6))
	if spots == null:
		return
	for index in mini(egg_slots.size(), spots.get_child_count()):
		var spot := spots.get_child(index) as Control
		var pill := spot.get_node("Pill") as Control
		egg_slots[index].position = spot.position
		egg_slots[index].rotation = spot.rotation
		egg_slots[index].set_pill_rect(pill.position, pill.size, pill.rotation)


## Live: the Pugad HUD rail (round, challenge, twist) and the chip column with Picked / Choosing.
func bind_live_hud(
	round_number: int,
	challenge_text: String,
	twist_text: String,
	seats: Array[Dictionary],
	score_units: Dictionary,
	assignments: Dictionary
) -> void:
	_round_label.text = "Round %d" % round_number
	_challenge_label.text = challenge_text
	_twist_tag.text = twist_text
	_twist_tag.visible = not twist_text.is_empty()
	for index in hud_chips.size():
		var seat: Dictionary = seats[index] if index < seats.size() else {}
		var state := PICKED_STATE if assignments.has(index) else CHOOSING_STATE
		hud_chips[index].bind_units(seat, int(score_units.get(index, 0)), state)


## Live: reconfigure the egg row once per round from the real pool (stable egg ids per slot).
func bind_live_eggs(
	definitions: ItemDefinitions, egg_pool: Array[Dictionary], tuning: GameplayTuning
) -> int:
	_egg_ids.clear()
	var keys := PackedStringArray()
	for egg in egg_pool:
		_egg_ids.append(str(egg.get("egg_id", "")))
		keys.append(str(egg.get("variant_key", "")))
	var shown := bind_eggs(definitions, keys, tuning)
	_announce.visible = false
	_lost_claim.clear()
	return shown


## Live: the round announcement (P12 schedule). An empty title hides the banner.
func bind_announcement(title: String, detail: String) -> void:
	_announce.visible = not title.is_empty()
	if _announce.visible:
		_announce.set_phase(title, detail)


## Live: ownership, per-seat selection, the lost-claim cue and the countdown.
## seats are the four registry seat dictionaries; assignments maps seat -> egg_id and
## selected_by_seat maps seat -> egg index.
func bind_live_state(
	seats: Array[Dictionary],
	assignments: Dictionary,
	selected_by_seat: Dictionary,
	lost_text: String,
	hint_text: String,
	remaining: float,
	total: float
) -> void:
	_phase_banner.set_phase("PUGAD", hint_text)
	_pick_hint.text = PICK_HINT_FORMAT % hint_text
	_countdown.set_time(remaining, total)
	var joined := 0
	var picked := 0
	for seat in seats:
		if bool(seat.get("joined", false)):
			joined += 1
			if assignments.has(int(seat.get("seat", -1))):
				picked += 1
	_set_count(picked, joined)
	_lost_claim.show_text(lost_text)
	for index in egg_slots.size():
		var slot := egg_slots[index]
		if not slot.visible:
			continue
		var egg_id := _egg_ids[index] if index < _egg_ids.size() else ""
		var owner_seat := {}
		var owned := false
		for seat_index in assignments:
			if str(assignments[seat_index]) == egg_id and int(seat_index) < seats.size():
				owner_seat = seats[int(seat_index)]
				owned = true
		slot.set_claim_owner(owner_seat)
		var selectors: Array[Dictionary] = []
		if not owned:
			for seat_index in selected_by_seat:
				if int(selected_by_seat[seat_index]) == index and int(seat_index) < seats.size():
					selectors.append(seats[int(seat_index)])
		slot.set_selectors(selectors)
		slot.set_selected(not selectors.is_empty())


func show_claim(slot_index: int, seat: Dictionary) -> void:
	if slot_index >= 0 and slot_index < egg_slots.size():
		egg_slots[slot_index].set_claim_owner(seat)


func visible_egg_count() -> int:
	var count := 0
	for slot in egg_slots:
		if slot.visible:
			count += 1
	return count


func _on_screen_ready() -> void:
	egg_slots = [%Egg1, %Egg2, %Egg3, %Egg4, %Egg5, %Egg6]
	for slot in egg_slots:
		slot.claimed.connect(_on_egg_claimed.bind(slot))


func count_text() -> String:
	return (_countdown.get_node("%CaptionLabel") as Label).text


func _set_count(picked: int, total: int) -> void:
	(_countdown.get_node("%CaptionLabel") as Label).text = COUNT_FORMAT % [picked, total]


func _show_state(index: int, ctx: UiContext) -> void:
	_phase_banner.set_phase("PUGAD", "Pick an egg")
	_pick_hint.text = PICK_HINT_FORMAT % "South / Enter"
	var sample_assignments := {}
	if index != 0:
		for seat_index in ctx.joined_seats().size():
			sample_assignments[seat_index] = true
	else:
		sample_assignments = {0: true, 1: true}
	bind_live_hud(1, "Karera", "", ctx.seats, {}, sample_assignments)
	_set_count(sample_assignments.size(), ctx.joined_seats().size())
	_countdown.set_time(5.0, SELECTION_SECONDS)
	_announce.visible = index == 3
	_announce.set_phase("NEXT ROUND IS AN EVENT", "Round 8: Lagsanay")
	_lost_claim.clear()
	var keys := PackedStringArray()
	for family in ctx.definitions.families:
		keys.append_array(ctx.definitions.enabled_variant_keys(family.family_id))
	var padded := PackedStringArray()
	# GDD placeholder: players + 2 eggs.
	for slot_index in mini(egg_slots.size(), ctx.joined_seats().size() + 2):
		padded.append(keys[slot_index % keys.size()] if not keys.is_empty() else "")
	bind_eggs(ctx.definitions, padded, ctx.tuning)
	for slot in egg_slots:
		slot.set_claim_owner({})
	if index == 0:
		# The frame's sample: P1 and P2 picked, P3 and P4 choosing.
		var seats := ctx.joined_seats()
		var sample := [[0, 0, true], [1, 2, true], [2, 1, false], [3, 3, false]]
		for entry in sample:
			if int(entry[0]) < seats.size() and int(entry[1]) < visible_egg_count():
				var seat: Dictionary = seats[int(entry[0])]
				if bool(entry[2]):
					show_claim(int(entry[1]), seat)
				else:
					var choosers: Array[Dictionary] = [seat]
					egg_slots[int(entry[1])].set_selectors(choosers)
	if index == 1:
		for seat_index in ctx.joined_seats().size():
			show_claim(seat_index, ctx.seats[seat_index])
	if index == 2:
		show_claim(0, ctx.seats[0])
		_lost_claim.show_text("Egg taken by player 1 - pick another")


func _navigate(_seat_index: int, direction: String) -> bool:
	var count := visible_egg_count()
	if count == 0 or direction not in ["left", "right"]:
		return false
	selected = posmod(selected + (-1 if direction == "left" else 1), count)
	_refresh_selection()
	return true


func _accept(seat_index: int) -> bool:
	if selected < 0 or selected >= egg_slots.size() or not egg_slots[selected].visible:
		return false
	claim_requested.emit(seat_index, selected, egg_slots[selected].variant_key)
	return true


func _refresh_selection() -> void:
	for index in egg_slots.size():
		egg_slots[index].set_selected(index == selected)


func _on_egg_claimed(_key: String, slot: UiEggSlot) -> void:
	var index := egg_slots.find(slot)
	if index >= 0:
		selected = index
		_refresh_selection()

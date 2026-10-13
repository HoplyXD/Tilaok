class_name UiPugadOverlay
extends UiScreen

signal claim_requested(seat_index: int, slot_index: int, variant_key: String)

const SELECTION_SECONDS := 8.0

var egg_slots: Array[UiEggSlot] = []
var selected := 0

@onready var _phase_banner: UiPhaseBanner = %PhaseBanner
@onready var _countdown: UiCountdownRing = %Countdown
@onready var _announce: UiPhaseBanner = %AnnounceBanner
@onready var _lost_claim: UiToastLine = %LostClaimToast


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
	return shown


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


func _show_state(index: int, ctx: UiContext) -> void:
	_phase_banner.set_phase("PUGAD", "Pick an egg")
	_countdown.set_time(5.0, SELECTION_SECONDS)
	_announce.visible = index == 3
	_announce.set_phase("NEXT ROUND IS AN EVENT", "Round 8: Lagsanay")
	_lost_claim.clear()
	var keys := PackedStringArray()
	for family in ctx.definitions.families:
		keys.append_array(ctx.definitions.enabled_variant_keys(family.family_id))
	var padded := PackedStringArray()
	for slot_index in 6:
		padded.append(keys[slot_index % keys.size()] if not keys.is_empty() else "")
	bind_eggs(ctx.definitions, padded, ctx.tuning)
	for slot in egg_slots:
		slot.set_claim_owner({})
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

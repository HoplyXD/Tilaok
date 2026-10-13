class_name ItemVisualSet
extends Resource

## Per-family map of presentation slots (body, top, beam_on, projectile, bubble, sfx_*, ...).
## A missing or empty slot falls back to the code-drawn DEBUG shape, so a swap never needs code.

@export var family_id := ""
@export var slots: Array[ItemVisualSlot] = []


func get_slot(slot_id: String) -> ItemVisualSlot:
	for slot in slots:
		if slot != null and slot.slot_id == slot_id:
			return slot
	return null


func frame(slot_id: String, seconds: float) -> Texture2D:
	var slot := get_slot(slot_id)
	return slot.frame_at(seconds) if slot != null else null


func sound(slot_id: String) -> AudioStream:
	var slot := get_slot(slot_id)
	return slot.sound if slot != null else null


func slot_ids() -> PackedStringArray:
	var ids := PackedStringArray()
	for slot in slots:
		if slot != null:
			ids.append(slot.slot_id)
	return ids


func placeholder_slot_ids() -> PackedStringArray:
	var ids := PackedStringArray()
	for slot in slots:
		if slot != null and slot.placeholder:
			ids.append(slot.slot_id)
	return ids


func has_placeholders() -> bool:
	return not placeholder_slot_ids().is_empty()

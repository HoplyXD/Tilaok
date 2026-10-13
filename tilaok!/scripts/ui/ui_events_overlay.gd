class_name UiEventsOverlay
extends UiScreen

## Placeholder event components (taya marker, Kangaroo pose prompt). Event logic is P08/P11.

@onready var _taya: Control = %TayaMarker
@onready var _kangaroo: Control = %KangarooPrompt


func state_names() -> PackedStringArray:
	return PackedStringArray(["Lagsanay taya marker", "Kangaroo pose prompt"])


func router_phase() -> int:
	return LocalInputRouter.Phase.PLAY


func _show_state(index: int, _ctx: UiContext) -> void:
	_taya.visible = index == 0
	_kangaroo.visible = index == 1

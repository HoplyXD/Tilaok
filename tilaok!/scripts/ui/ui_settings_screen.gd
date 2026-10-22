class_name UiSettingsScreen
extends UiScreen

signal shake_changed(mode: int)
signal result_reveal_motion_changed(mode: int)
signal volume_changed(bus: String, level: float)
signal mute_changed(muted: bool)

const SHAKE_FULL := 0
const SHAKE_REDUCED := 1
const SHAKE_OFF := 2

@onready var _menu: UiMenuList = %MenuList
@onready var _shake_row: UiOptionRow = %ShakeRow
@onready var _result_reveal_row: UiOptionRow = %ResultRevealRow
@onready var _mute_row: UiOptionRow = %MuteRow
@onready var _master_row: UiOptionRow = %MasterRow
@onready var _music_row: UiOptionRow = %MusicRow
@onready var _effects_row: UiOptionRow = %EffectsRow
@onready var _crowd_row: UiOptionRow = %CrowdRow
@onready var _back_button: Button = %BackButton
@onready var _build_about_label: Label = %BuildAboutLabel


func state_names() -> PackedStringArray:
	return PackedStringArray(["Default", "Shake off, music 40%", "Back selected"])


func bind_settings(settings: PresentationSettings) -> void:
	_shake_row.set_choice(settings.screen_shake)
	_result_reveal_row.set_choice(settings.result_reveal_motion)
	_mute_row.set_choice(1 if settings.muted else 0)
	_master_row.set_level(settings.master_volume)
	_music_row.set_level(settings.music_volume)
	_effects_row.set_level(settings.effects_volume)
	_crowd_row.set_level(settings.crowd_volume)


## Live binding: shows the settings and writes changes back (in memory only; nothing is saved).
func bind_live(settings: PresentationSettings) -> void:
	bind_settings(settings)
	shake_changed.connect(
		func(mode: int) -> void:
			settings.screen_shake = mode
			PresentationApplier.apply(settings)
	)
	result_reveal_motion_changed.connect(
		func(mode: int) -> void: settings.result_reveal_motion = mode
	)
	mute_changed.connect(
		func(muted: bool) -> void:
			settings.muted = muted
			PresentationApplier.apply(settings)
	)
	volume_changed.connect(
		func(bus: String, level: float) -> void:
			match bus:
				"master":
					settings.master_volume = level
				"music":
					settings.music_volume = level
				"effects":
					settings.effects_volume = level
				"crowd":
					settings.crowd_volume = level
			PresentationApplier.apply(settings)
	)


func _on_screen_ready() -> void:
	_shake_row.choice_changed.connect(func(index: int) -> void: shake_changed.emit(index))
	_result_reveal_row.choice_changed.connect(
		func(index: int) -> void: result_reveal_motion_changed.emit(index)
	)
	_mute_row.choice_changed.connect(func(index: int) -> void: mute_changed.emit(index == 1))
	_master_row.level_changed.connect(func(v: float) -> void: volume_changed.emit("master", v))
	_music_row.level_changed.connect(func(v: float) -> void: volume_changed.emit("music", v))
	_effects_row.level_changed.connect(func(v: float) -> void: volume_changed.emit("effects", v))
	_crowd_row.level_changed.connect(func(v: float) -> void: volume_changed.emit("crowd", v))
	_back_button.pressed.connect(func() -> void: back_requested.emit())
	# Version, channel, and local build identity for support reports.
	_build_about_label.text = BuildIdentity.about_line()
	_menu.refresh_items()


func _show_state(index: int, ctx: UiContext) -> void:
	bind_settings(ctx.settings)
	_menu.select(0)
	if index == 1:
		_shake_row.set_choice(SHAKE_OFF)
		_music_row.set_level(0.4)
	if index == 2:
		_menu.select(_menu.items.size() - 1)


func _navigate(_seat_index: int, direction: String) -> bool:
	if direction in ["left", "right"]:
		return _menu.adjust(-1 if direction == "left" else 1)
	return _menu.move(direction)


func _accept(_seat_index: int) -> bool:
	return _menu.activate()

class_name UiTitleScreen
extends UiScreen

signal start_requested
signal library_requested
signal settings_requested
signal quit_requested

@onready var _menu: UiMenuList = %MenuList
@onready var _build_label: Label = %BuildLabel
@onready var _join_prompt: UiPromptGlyph = %PressToJoinPrompt
@onready var _quit_confirm: UiConfirmDialog = %QuitConfirm
@onready var _quit_scrim: Control = %QuitScrim
@onready var _start_button: Button = %StartButton
@onready var _library_button: Button = %LibraryButton
@onready var _settings_button: Button = %SettingsButton
@onready var _quit_button: Button = %QuitButton


func state_names() -> PackedStringArray:
	return PackedStringArray(["Menu", "Nobody joined", "Quit confirm"])


func router_phase() -> int:
	return LocalInputRouter.Phase.MENU


## Live binding used by GameFlow: build label (never a seed) plus the joined-seat count.
func bind_live(
	build_text: String, joined_count: int, map: UiPromptMap, device_kind: String
) -> void:
	bind_build_label(build_text)
	bind_joined(joined_count, map, device_kind)


func bind_build_label(text: String) -> void:
	_build_label.text = text


## The menu always shows (Play, Library, Settings, Quit), even with nobody joined: the first menu
## press joins that device. The old join prompt node stays in the scene, hidden.
func bind_joined(_count: int, map: UiPromptMap, device_kind: String) -> void:
	_menu.visible = true
	_join_prompt.visible = false
	_join_prompt.bind("ready", device_kind, map)
	_menu.refresh_items()


func _on_screen_ready() -> void:
	_start_button.pressed.connect(func() -> void: start_requested.emit())
	_library_button.pressed.connect(func() -> void: library_requested.emit())
	_settings_button.pressed.connect(func() -> void: settings_requested.emit())
	_quit_button.pressed.connect(_on_quit_pressed)
	_quit_confirm.confirmed.connect(func() -> void: quit_requested.emit())
	_quit_confirm.visibility_changed.connect(
		func() -> void: _quit_scrim.visible = _quit_confirm.visible
	)
	_menu.refresh_items()


func _show_state(index: int, ctx: UiContext) -> void:
	bind_build_label("Tilaok! development build - SAMPLE")
	bind_joined(0 if index == 1 else ctx.player_count, ctx.prompt_map, ctx.device_kind)
	if index == 2:
		_on_quit_pressed()
	else:
		_quit_confirm.close()
		_menu.set_active(true)


func _navigate(_seat_index: int, direction: String) -> bool:
	if _quit_confirm.is_open():
		return _quit_confirm.navigate(direction)
	return _menu.move(direction)


func _accept(_seat_index: int) -> bool:
	if _quit_confirm.is_open():
		return _quit_confirm.accept()
	return _menu.activate()


func _back(_seat_index: int) -> bool:
	if _quit_confirm.is_open():
		_quit_confirm.cancel()
	else:
		_on_quit_pressed()
	return true


func _on_quit_pressed() -> void:
	_quit_confirm.open("Are you sure you want to leave?")
	_menu.set_active(false)
	_quit_confirm.cancelled.connect(_on_quit_cancelled, CONNECT_ONE_SHOT)


func _on_quit_cancelled() -> void:
	_menu.set_active(true)

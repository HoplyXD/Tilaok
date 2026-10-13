class_name UiGallery
extends Control

## Designer-facing review harness: every screen x state with SAMPLE data, a device-glyph switch,
## a 1-4 player switch, a theme hot-swap and a Return button. Runs as a harness room (emits
## return_requested) or standalone with F6. Controls are authored in ui_gallery.tscn.

signal return_requested

## Order must match the buttons under Chrome/ScreenList.
const SCREEN_IDS := [
	"title",
	"lobby",
	"tutorial",
	"pugad",
	"place",
	"play_hud",
	"round_result",
	"match_result",
	"pause",
	"settings",
	"library",
	"events",
]
const DEVICES := ["k1", "k2", "gamepad"]
const FIRST_GAMEPAD_ID := 900

## One PackedScene per entry of SCREEN_IDS, in the same order.
@export var screen_scenes: Array[PackedScene] = []
## Optional second Theme for the hot-swap button (the test suite assigns one).
@export var alt_theme: Theme

var context: UiContext
var router: LocalInputRouter
var bridge: UiInputBridge
var current: UiScreen
var screen_index := -1
var state_index := 0
var base_theme: Theme

@onready var _stage: Control = %Stage
@onready var _chrome: Control = %Chrome
@onready var _screen_list: Control = %ScreenList
@onready var _screen_label: Label = %ScreenLabel
@onready var _state_label: Label = %StateLabel
@onready var _owner_button: Button = %OwnerButton
@onready var _theme_button: Button = %ThemeSwapButton
@onready var _players: Array[Button] = [%Players1, %Players2, %Players3, %Players4]
@onready var _devices: Array[Button] = [%DeviceK1, %DeviceK2, %DevicePad]


func _ready() -> void:
	base_theme = theme
	context = UiContext.make(4, "k1")
	router = LocalInputRouter.new()
	router.name = "GalleryRouter"
	add_child(router)
	router.shared_keyboard_enabled = true
	bridge = UiInputBridge.new()
	bridge.name = "GalleryBridge"
	add_child(bridge)
	bridge.attach(router)
	_seat_router(context.player_count)
	var index := 0
	for child in _screen_list.get_children():
		if child is Button:
			(child as Button).pressed.connect(show_screen.bind(index))
			index += 1
	for player_index in _players.size():
		_players[player_index].pressed.connect(set_players.bind(player_index + 1))
	for device_index in _devices.size():
		_devices[device_index].pressed.connect(set_device.bind(DEVICES[device_index]))
	%StatePrev.pressed.connect(step_state.bind(-1))
	%StateNext.pressed.connect(step_state.bind(1))
	_owner_button.pressed.connect(cycle_owner)
	_theme_button.pressed.connect(swap_theme)
	%HideButton.pressed.connect(set_chrome_visible.bind(false))
	%ReturnButton.pressed.connect(func() -> void: return_requested.emit())
	_theme_button.disabled = alt_theme == null
	show_screen(0)


func _exit_tree() -> void:
	if bridge != null:
		bridge.detach()


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo and key.keycode == KEY_F9:
		set_chrome_visible(not _chrome.visible)


func show_screen(index: int) -> void:
	if index < 0 or index >= screen_scenes.size():
		return
	_free_current()
	screen_index = index
	state_index = 0
	var instance := screen_scenes[index].instantiate() as UiScreen
	if instance == null:
		push_error("UiGallery: scene %d is not a UiScreen" % index)
		return
	current = instance
	_stage.add_child(current)
	_wire_screen(current)
	_apply_to_screen()


func step_state(delta: int) -> void:
	if current == null:
		return
	var count := current.state_names().size()
	state_index = posmod(state_index + delta, maxi(count, 1))
	_apply_to_screen()


func set_state(index: int) -> void:
	if current == null:
		return
	state_index = clampi(index, 0, maxi(current.state_names().size() - 1, 0))
	_apply_to_screen()


func set_players(count: int) -> void:
	context.configure(count, context.device_kind)
	context.owner_seat = mini(context.owner_seat, context.player_count - 1)
	_seat_router(context.player_count)
	_apply_to_screen()


func set_device(kind: String) -> void:
	context.configure(context.player_count, kind)
	_apply_to_screen()


func cycle_owner() -> void:
	context.owner_seat = (context.owner_seat + 1) % context.player_count
	_apply_to_screen()


func swap_theme() -> void:
	if alt_theme == null:
		return
	theme = alt_theme if theme == base_theme else base_theme


func set_chrome_visible(value: bool) -> void:
	_chrome.visible = value


func screen_id(index: int) -> String:
	return SCREEN_IDS[index] if index >= 0 and index < SCREEN_IDS.size() else ""


func index_of(id: String) -> int:
	return SCREEN_IDS.find(id)


func _seat_router(count: int) -> void:
	router.registry.clear_to_lobby()
	router.clear_input_state()
	for seat_index in count:
		if seat_index == 0:
			router.registry.join_keyboard("K1")
		elif seat_index == 1:
			router.registry.join_keyboard("K2")
		else:
			router.registry.join_gamepad(FIRST_GAMEPAD_ID + seat_index)


func _apply_to_screen() -> void:
	if current == null:
		return
	var phase := current.router_phase()
	current.owner_seat = -1 if phase == LocalInputRouter.Phase.LOBBY else context.owner_seat
	current.show_state(state_index, context)
	bridge.set_screen(current)
	var names := current.state_names()
	_screen_label.text = "%s" % screen_id(screen_index)
	_state_label.text = (
		"%s (%d/%d)" % [names[state_index], state_index + 1, names.size()]
		if state_index < names.size()
		else ""
	)
	_owner_button.text = "Owner: seat %d" % (context.owner_seat + 1)
	for index in _players.size():
		_players[index].button_pressed = index + 1 == context.player_count
	for index in _devices.size():
		_devices[index].button_pressed = DEVICES[index] == context.device_kind


func _wire_screen(screen: UiScreen) -> void:
	screen.back_requested.connect(_on_screen_back)
	if screen is UiTitleScreen:
		var title := screen as UiTitleScreen
		title.start_requested.connect(show_screen.bind(index_of("lobby")))
		title.library_requested.connect(show_screen.bind(index_of("library")))
		title.settings_requested.connect(show_screen.bind(index_of("settings")))
	elif screen is UiLobbyScreen:
		(screen as UiLobbyScreen).ready_toggled.connect(_on_lobby_ready_toggled)
	elif screen is UiPugadOverlay:
		(screen as UiPugadOverlay).claim_requested.connect(_on_claim_requested)
	elif screen is UiPauseScreen:
		var pause := screen as UiPauseScreen
		pause.settings_requested.connect(show_screen.bind(index_of("settings")))
		pause.library_requested.connect(show_screen.bind(index_of("library")))
	elif screen is UiSettingsScreen:
		(screen as UiSettingsScreen).shake_changed.connect(_on_shake_changed)
		(screen as UiSettingsScreen).volume_changed.connect(_on_volume_changed)


func _free_current() -> void:
	if current != null and is_instance_valid(current):
		_stage.remove_child(current)
		current.queue_free()
	current = null


func _on_screen_back() -> void:
	show_screen(index_of("title"))


func _on_lobby_ready_toggled(seat_index: int) -> void:
	var lobby := current as UiLobbyScreen
	if lobby == null or seat_index >= lobby.seats.size():
		return
	var seats := lobby.seats
	if bool(seats[seat_index].get("joined", false)):
		seats[seat_index].ready = not bool(seats[seat_index].get("ready", false))
	lobby.bind_seats(seats, context.prompt_map, context.device_kind)


func _on_claim_requested(seat_index: int, slot_index: int, _key: String) -> void:
	var pugad := current as UiPugadOverlay
	if pugad != null and seat_index < context.seats.size():
		pugad.show_claim(slot_index, context.seats[seat_index])


func _on_shake_changed(mode: int) -> void:
	context.settings.screen_shake = mode


func _on_volume_changed(bus: String, level: float) -> void:
	match bus:
		"master":
			context.settings.master_volume = level
		"music":
			context.settings.music_volume = level
		"effects":
			context.settings.effects_volume = level
		"crowd":
			context.settings.crowd_volume = level

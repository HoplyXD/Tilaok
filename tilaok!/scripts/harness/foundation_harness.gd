class_name FoundationHarness
extends Control

const DEFAULT_SEED := 12345
const BUILD_ID := "P01-foundation-dev"
const ROOM_SCENES := {
	"movement_room": preload("res://scenes/fixtures/movement_room.tscn"),
	"p02_movement_room": preload("res://scenes/fixtures/p02_movement_room.tscn"),
	"p03_stage_room": preload("res://scenes/fixtures/p03_stage_room.tscn"),
	"item_lab": preload("res://scenes/fixtures/item_lab.tscn"),
	"event_lab": preload("res://scenes/fixtures/event_lab.tscn"),
}
const FULL_VIEW_ROOMS: PackedStringArray = ["p03_stage_room", "item_lab"]

var gameplay_tuning := GameplayTuning.new()
var presentation_settings := PresentationSettings.new()
var active_snapshot: ConfigurationSnapshot
var selected_seed := DEFAULT_SEED
var selected_profile_id := "movement_room"
var run_counter := 0
var diagnostics_paused := false
var active_room: Control

@onready var profile_picker: OptionButton = $Layout/HarnessPanel/ProfileRow/ProfilePicker
@onready var seed_input: LineEdit = $Layout/HarnessPanel/SeedRow/SeedInput
@onready var identity_label: Label = $Layout/Identity
@onready var status_label: RichTextLabel = $Layout/Status
@onready var room_host: Control = $Layout/RoomHost
@onready var harness_panel: VBoxContainer = $Layout/HarnessPanel
@onready var shake_picker: OptionButton = $Layout/HarnessPanel/PresentationRow/ShakePicker
@onready var volume_slider: HSlider = $Layout/HarnessPanel/PresentationRow/VolumeSlider
@onready var pause_toggle: CheckButton = $Layout/HarnessPanel/PresentationRow/PauseToggle


func _ready() -> void:
	for profile_id in ProfileRegistry.ids():
		var profile := ProfileRegistry.get_profile(profile_id)
		profile_picker.add_item(profile.label)
		profile_picker.set_item_metadata(profile_picker.item_count - 1, profile_id)
	profile_picker.item_selected.connect(_on_profile_selected)
	seed_input.text = str(DEFAULT_SEED)
	seed_input.text_submitted.connect(_on_seed_submitted)
	shake_picker.add_item("Full")
	shake_picker.add_item("Reduced")
	shake_picker.add_item("Off")
	shake_picker.select(presentation_settings.screen_shake)
	volume_slider.value = presentation_settings.master_volume
	shake_picker.item_selected.connect(_on_presentation_changed)
	volume_slider.value_changed.connect(_on_presentation_changed)
	pause_toggle.toggled.connect(_on_pause_toggled)
	$Layout/HarnessPanel/ActionRow/ValidateButton.pressed.connect(_validate_selected_profile)
	$Layout/HarnessPanel/ActionRow/RunButton.pressed.connect(_start_diagnostic_run)
	$Layout/HarnessPanel/ActionRow/ResetButton.pressed.connect(_reset_scenario)
	$Layout/HarnessPanel/ActionRow/ReloadButton.pressed.connect(_reload_harness)
	$Layout/HarnessPanel/RoomRow/MovementRoomButton.pressed.connect(
		_open_room.bind("movement_room")
	)
	$Layout/HarnessPanel/RoomRow/P02MovementRoomButton.pressed.connect(
		_open_room.bind("p02_movement_room")
	)
	$Layout/HarnessPanel/RoomRow/P03StageRoomButton.pressed.connect(
		_open_room.bind("p03_stage_room")
	)
	$Layout/HarnessPanel/RoomRow/ItemRoomButton.pressed.connect(_open_room.bind("item_lab"))
	$Layout/HarnessPanel/RoomRow/EventRoomButton.pressed.connect(_open_room.bind("event_lab"))
	$Layout/ExitButton.pressed.connect(_exit_harness)
	profile_picker.select(0)
	_update_identity()
	_validate_selected_profile()
	# Exported-build smoke hook: "-- --open-room=item_lab" opens a fixture at startup.
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--open-room="):
			_open_room.call_deferred(argument.trim_prefix("--open-room="))
	_append_status(
		(
			"Harness ready. P01 foundation checks and P02 movement/input diagnostics are available; "
			+ "no full game loop is implemented."
		)
	)


func _on_profile_selected(index: int) -> void:
	selected_profile_id = str(profile_picker.get_item_metadata(index))
	_update_identity()
	_validate_selected_profile()


func _on_seed_submitted(value: String) -> void:
	_set_seed_from_text(value)
	_update_identity()
	_validate_selected_profile()


func _set_seed_from_text(value: String) -> bool:
	if not value.is_valid_int():
		_append_status("Seed must be a signed integer.")
		return false
	selected_seed = value.to_int()
	return true


func _update_identity() -> void:
	identity_label.text = (
		"Build: %s    Profile: %s    Seed: %d    Run: %d"
		% [BUILD_ID, selected_profile_id, selected_seed, run_counter]
	)


func _current_catalog() -> DiagnosticContentCatalog:
	var catalog := DiagnosticContentCatalog.new()
	var profile := ProfileRegistry.get_profile(selected_profile_id)
	if profile == null:
		return catalog
	var definitions := ItemDefinitions.load_all(gameplay_tuning)
	if not definitions.is_valid():
		for message in definitions.errors:
			_append_status("Item definitions rejected: %s" % message)
		return catalog
	# Item rows are visible only to profiles that list them; other profiles keep empty pools.
	for entry in definitions.catalog_entries():
		if profile.required_content_ids.has(entry.content_id):
			catalog.entries.append(entry)
	return catalog


func _validate_selected_profile() -> void:
	var profile := ProfileRegistry.get_profile(selected_profile_id)
	var errors := _current_catalog().validate_profile(profile)
	errors.append_array(gameplay_tuning.validate())
	errors.append_array(presentation_settings.validate())
	if errors.is_empty():
		_append_status(
			(
				"Profile validation PASSED. This confirms configuration only; "
				+ "no gameplay mechanics are included."
			)
		)
	else:
		_append_status(
			(
				"Profile validation REJECTED (%d issue(s)):\n• %s"
				% [errors.size(), "\n• ".join(errors)]
			)
		)


func _start_diagnostic_run() -> void:
	if not _set_seed_from_text(seed_input.text):
		return
	var profile := ProfileRegistry.get_profile(selected_profile_id)
	var errors := _current_catalog().validate_profile(profile)
	if not errors.is_empty():
		_append_status(
			(
				"Run not started: selected profile is incomplete. "
				+ "Select movement_room for the diagnostic startup path."
			)
		)
		return
	run_counter += 1
	active_snapshot = ConfigurationSnapshot.create(
		gameplay_tuning, presentation_settings, selected_profile_id, selected_seed, run_counter
	)
	var streams := SeededDiagnosticStreams.new()
	streams.seed_all(selected_seed)
	_update_identity()
	_append_status(
		"Diagnostic run %d started. No gameplay content was selected or simulated." % run_counter
	)


func _reset_scenario() -> void:
	_release_active_room()
	if active_snapshot != null:
		active_snapshot = null
		_append_status(
			"Scenario reset completed. Transient fixture released and run snapshot cleared."
		)
	else:
		_append_status("Scenario reset completed. No active run snapshot or fixture remained.")
	_update_identity()


func _reload_harness() -> void:
	get_tree().reload_current_scene()


func _open_room(room_id: String) -> void:
	if not ROOM_SCENES.has(room_id):
		_append_status("Unknown diagnostic room '%s'." % room_id)
		return
	_release_active_room()
	active_room = ROOM_SCENES[room_id].instantiate() as Control
	if FULL_VIEW_ROOMS.has(room_id):
		active_room.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(active_room)
		$Layout.hide()
	else:
		room_host.add_child(active_room)
		harness_panel.hide()
	active_room.return_requested.connect(_close_room)
	if room_id == "p03_stage_room":
		_append_status(
			"Opened the P03 graybox arena; placement and wave visuals are diagnostic fixtures only."
		)
	elif room_id == "item_lab":
		_append_status(
			"Opened the P04 Item Lab; lab placement is immediate and is not the P05 resolver."
		)
	elif room_id == "p02_movement_room":
		_append_status(
			(
				"Opened the P02 input/movement diagnostic fixture. These narrow contracts do not "
				+ "implement the full match, Lagsanay, or Kangaroo systems."
			)
		)
	else:
		_append_status(
			"Opened %s placeholder fixture. Mechanics are not implemented or verified." % room_id
		)


func _close_room() -> void:
	_release_active_room()
	_append_status("Returned to foundation diagnostics; fixture released.")


func _release_active_room() -> void:
	if active_room == null or not is_instance_valid(active_room):
		active_room = null
		return
	if active_room.has_signal("return_requested"):
		var return_callback := Callable(self, "_close_room")
		if active_room.is_connected("return_requested", return_callback):
			active_room.disconnect("return_requested", return_callback)
	var parent := active_room.get_parent()
	if parent == self:
		remove_child(active_room)
	else:
		parent.remove_child(active_room)
	active_room.queue_free()
	active_room = null
	$Layout.show()
	harness_panel.show()


func _on_pause_toggled(is_paused: bool) -> void:
	diagnostics_paused = is_paused
	_append_status(
		(
			"Diagnostic presentation settings may now be changed."
			if is_paused
			else "Presentation values are locked while diagnostics are unpaused."
		)
	)


func _on_presentation_changed(_value: Variant = null) -> void:
	if not diagnostics_paused or active_snapshot == null:
		_append_status("Presentation edit ignored: pause diagnostics and start a run first.")
		return
	var edited := presentation_settings.duplicate(true) as PresentationSettings
	edited.master_volume = volume_slider.value
	edited.screen_shake = shake_picker.selected
	if active_snapshot.apply_presentation_while_paused(edited, diagnostics_paused):
		presentation_settings = edited
		_append_status(
			(
				"Paused presentation snapshot updated (volume %.2f, shake %s)."
				% [
					presentation_settings.master_volume,
					shake_picker.get_item_text(shake_picker.selected)
				]
			)
		)


func _append_status(message: String) -> void:
	status_label.append_text("%s\n" % message)
	status_label.scroll_to_line(status_label.get_line_count())


func _exit_harness() -> void:
	get_tree().quit()

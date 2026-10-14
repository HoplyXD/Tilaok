class_name KangarooMainRound
extends Node

## Runs a Kangaroo Main Challenge inside a full match room (P12 scheduled match). It drives the
## same KangarooRoundController the P11 lab verified, from the room's simulation clock and its
## intentional-input edges, and shows the shared DEBUG command prompts, failure markers, slipper
## presenter, cue tone and screen shake. Scoring and the round end stay with the room.

const SHAKE_SECONDS := 0.22

var controller := KangarooRoundController.new()
var screen_shake_mode := 0

var _room: P05MatchRoom
var _overlay: CanvasLayer
var _command_stack: VBoxContainer
var _marker_label: Label
var _presenter: KangarooSlipperPresenter
var _command_panels: Dictionary = {}
var _seen_command_ids: Dictionary = {}
var _tones: Dictionary = {}
var _shake_remaining := 0.0
var _last_simulation_time := 0.0
var _last_simulation_wall_usec := 0


func setup(room: P05MatchRoom) -> void:
	_room = room
	name = "KangarooMainRound"
	_overlay = CanvasLayer.new()
	_overlay.name = "KangarooMainOverlay"
	_overlay.layer = 21
	_overlay.visible = false
	add_child(_overlay)
	_command_stack = VBoxContainer.new()
	_command_stack.name = "KangarooCommands"
	_command_stack.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_command_stack.position = Vector2(-625.0, 230.0)
	_command_stack.size = Vector2(610.0, 250.0)
	_command_stack.add_theme_constant_override("separation", 8)
	_command_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(_command_stack)
	_marker_label = Label.new()
	_marker_label.name = "KangarooMarkers"
	_marker_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_marker_label.position = Vector2(18.0, -64.0)
	_marker_label.size = Vector2(520.0, 42.0)
	_marker_label.add_theme_font_size_override("font_size", 18)
	_marker_label.add_theme_color_override("font_color", Color.WHITE)
	_marker_label.add_theme_color_override("font_outline_color", Color("#15242b"))
	_marker_label.add_theme_constant_override("outline_size", 4)
	_marker_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(_marker_label)
	_presenter = KangarooSlipperPresenter.new()
	_presenter.name = "KangarooMainPresenter"
	_presenter.z_index = 30
	_presenter.visible = false
	room.world_layer.add_child(_presenter)


func begin(round_id: String, seats: Array[int], score_units: Dictionary) -> bool:
	clear_view()
	var initial_sources: Dictionary = {}
	for seat_index in seats:
		initial_sources[seat_index] = _room.input_router.intentional_input_sources(seat_index)
	var active_time := _room.items.director.simulation_time
	if not controller.begin(
		round_id,
		seats,
		score_units,
		_room.match_streams.kangaroo,
		_room.tuning,
		active_time,
		initial_sources
	):
		return false
	if _room.match_snapshot != null:
		screen_shake_mode = _room.match_snapshot.presentation.screen_shake
	_last_simulation_time = active_time
	_last_simulation_wall_usec = Time.get_ticks_usec()
	_overlay.visible = true
	update_view(0.0)
	return true


## One physics step at the room's simulation time; returns the controller's step result.
func advance(tick: int) -> Dictionary:
	var active_time := _room.items.director.simulation_time
	var result := controller.advance_to(
		active_time, tick, _room.actors, _room.support_tracker, _hug_contacts_snapshot()
	)
	_last_simulation_time = active_time
	_last_simulation_wall_usec = Time.get_ticks_usec()
	return result


## Intentional run/jump edges timestamped onto the simulation clock (P11 contract).
func record_input_edge(
	seat_index: int, action_name: String, source_id: String, is_pressed: bool, event_usec: int
) -> void:
	if action_name not in ["left", "right", "jump", "run_axis"] or not controller.active:
		return
	var paused := _room.get_tree().paused
	if paused and is_pressed:
		return
	var event_time := controller.active_time()
	if not paused and _room.input_router.phase == LocalInputRouter.Phase.PLAY:
		var elapsed := maxf(0.0, float(event_usec - _last_simulation_wall_usec) / 1000000.0)
		event_time = maxf(_last_simulation_time, _last_simulation_time + elapsed)
	controller.record_intent_edge(seat_index, source_id, is_pressed, event_time)


## After a pause, held inputs are re-read so a release during the pause is not missed.
func resync_after_pause() -> void:
	if not controller.active:
		return
	for seat in controller.seat_indices:
		controller.sync_intent_sources(seat, _room.input_router.intentional_input_sources(seat))
	_last_simulation_time = _room.items.director.simulation_time
	_last_simulation_wall_usec = Time.get_ticks_usec()


## Prompts, markers, slipper presenter and shake; call once per frame during Play.
func update_view(delta: float) -> void:
	var active_time := _room.items.director.simulation_time
	var current_ids: Dictionary = {}
	for command in controller.active_commands():
		var command_id := int(command.command_id)
		current_ids[command_id] = true
		if not _command_panels.has(command_id):
			_command_panels[command_id] = KangarooCommandStyle.create_panel(command, _command_stack)
			if not _seen_command_ids.has(command_id):
				_seen_command_ids[command_id] = true
				_play_cue(int(command.command))
		KangarooCommandStyle.update_panel(_command_panels[command_id], command, active_time)
	for command_id in _command_panels.keys().duplicate():
		if not current_ids.has(command_id):
			_free_panel(command_id)
	_marker_label.text = KangarooCommandStyle.marker_status(controller, _room.input_router.registry)
	if _room.arena != null:
		_presenter.set_state(
			controller.presentation_commands(active_time),
			_room.arena.arena_bounds,
			_room.arena.spawn_feet.y,
			active_time,
			_room.camera_rig.global_position
		)
	_update_shake(delta)


## Hides every prompt; the controller keeps its outcomes for the room's results.
func clear_view() -> void:
	for command_id in _command_panels.keys().duplicate():
		_free_panel(command_id)
	_seen_command_ids.clear()
	_marker_label.text = ""
	_overlay.visible = false
	var none: Array[Dictionary] = []
	_presenter.set_state(none, Rect2(), 0.0, 0.0, Vector2.ZERO)
	_shake_remaining = 0.0
	if _room != null and _room.camera_rig != null:
		_room.camera_rig.offset = Vector2.ZERO


func set_overlay_visible(value: bool) -> void:
	_overlay.visible = value and controller.active


func reset() -> void:
	controller.reset()
	clear_view()


func _free_panel(command_id: int) -> void:
	var panel: Dictionary = _command_panels[command_id]
	if is_instance_valid(panel.root):
		panel.root.queue_free()
	_command_panels.erase(command_id)


func _hug_contacts_snapshot() -> Array[Dictionary]:
	var contacts: Array[Dictionary] = []
	var seen: Dictionary = {}
	for seat in controller.live_seats:
		var actor := _room.actors.get(seat) as ChickenController
		if actor == null or not is_instance_valid(actor) or actor.lifecycle.is_terminal():
			continue
		for node in actor.contact_overlaps():
			var other := node as ChickenController
			if (
				other == null
				or other.lifecycle.is_terminal()
				or not controller.live_seats.has(other.seat_index)
				or actor.seat_index == other.seat_index
			):
				continue
			var low := mini(actor.seat_index, other.seat_index)
			var high := maxi(actor.seat_index, other.seat_index)
			var pair_key := "%d:%d" % [low, high]
			if seen.has(pair_key):
				continue
			seen[pair_key] = true
			(
				contacts
				. append(
					{
						"seat_a": low,
						"seat_b": high,
						"distance_squared":
						actor.global_position.distance_squared_to(other.global_position),
					}
				)
			)
	return contacts


func _play_cue(command: int) -> void:
	if not _tones.has(command):
		_tones[command] = KangarooCommandStyle.make_tone(
			float(KangarooCommandStyle.frequency(command))
		)
	var player := AudioStreamPlayer.new()
	player.name = "KangarooCue"
	player.stream = _tones[command]
	player.volume_db = -8.0
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()
	# PresentationSettings.screen_shake: 0 full, 1 reduced, 2 off.
	_shake_remaining = SHAKE_SECONDS if screen_shake_mode != 2 else 0.0


func _update_shake(delta: float) -> void:
	var camera := _room.camera_rig
	if camera == null:
		return
	_shake_remaining = maxf(0.0, _shake_remaining - delta)
	if _shake_remaining <= 0.0 or screen_shake_mode == 2:
		camera.offset = Vector2.ZERO
		return
	var intensity := 6.0 if screen_shake_mode == 0 else 2.0
	var fade := clampf(_shake_remaining / SHAKE_SECONDS, 0.0, 1.0)
	var phase := float(Time.get_ticks_msec()) * 0.09
	camera.offset = Vector2(sin(phase), cos(phase * 1.37)) * intensity * fade

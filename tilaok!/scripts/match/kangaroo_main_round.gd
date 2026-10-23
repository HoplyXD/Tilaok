class_name KangarooMainRound
extends Node

## Runs a Kangaroo Main Challenge inside a full match room (P12 scheduled match). It drives the
## same KangarooRoundController the P11 lab verified, from the room's simulation clock and its
## intentional-input edges, and shows the scene-authored command cards, failure markers, slipper
## presenter, cue tone and screen shake. Scoring and the round end stay with the room.

const SHAKE_SECONDS := 0.22
## PresentationSettings.screen_shake: 0 full, 1 reduced, 2 off.
const SHAKE_FULL := 0
const SHAKE_OFF := 2
const FULL_SHAKE_PIXELS := 6.0
const REDUCED_SHAKE_PIXELS := 2.0
const HUD_SCENE := preload("res://scenes/ui/components/kangaroo_hud.tscn")

var controller := KangarooRoundController.new()
var authority := SimulationAuthority.offline()

var _room: P05MatchRoom
var _overlay: CanvasLayer
var _hud: UiKangarooHud
var _presenter: KangarooSlipperPresenter
var _seen_command_ids: Dictionary = {}
var _tones: Dictionary = {}
var _shake_remaining := 0.0
var _last_simulation_time := 0.0
var _last_simulation_wall_usec := 0
var _life_markers: Dictionary = {}
var _life_marker_signature := ""


func setup(room: P05MatchRoom) -> void:
	_room = room
	controller.authority = authority
	name = "KangarooMainRound"
	_overlay = CanvasLayer.new()
	_overlay.name = "KangarooMainOverlay"
	_overlay.layer = 21
	_overlay.visible = false
	add_child(_overlay)
	_hud = HUD_SCENE.instantiate() as UiKangarooHud
	_hud.name = "KangarooHud"
	_overlay.add_child(_hud)
	_presenter = KangarooSlipperPresenter.new()
	_presenter.name = "KangarooMainPresenter"
	_presenter.z_index = 30
	_presenter.visible = false
	room.world_layer.add_child(_presenter)


func begin(round_id: String, seats: Array[int], score_units: Dictionary) -> bool:
	if not _can_mutate():
		return false
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
	_last_simulation_time = active_time
	_last_simulation_wall_usec = Time.get_ticks_usec()
	_overlay.visible = true
	update_view(0.0)
	return true


## One physics step at the room's simulation time; returns the controller's step result.
func advance(tick: int) -> Dictionary:
	if not _can_mutate():
		return {"new_outcomes": [], "ended": false}
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
	if not _can_mutate():
		return
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
	var commands := controller.active_commands()
	var current_ids: Dictionary = {}
	for command in commands:
		var command_id := int(command.command_id)
		current_ids[command_id] = true
		if not _seen_command_ids.has(command_id):
			_seen_command_ids[command_id] = true
			_play_cue(int(command.command))
	_hud.bind_commands(commands, active_time)
	_update_life_markers()
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
	_seen_command_ids.clear()
	for marker in _life_markers.values():
		if is_instance_valid(marker):
			marker.queue_free()
	_life_markers.clear()
	_life_marker_signature = ""
	_hud.clear()
	_overlay.visible = false
	var none: Array[Dictionary] = []
	_presenter.set_state(none, Rect2(), 0.0, 0.0, Vector2.ZERO)
	_shake_remaining = 0.0
	if _room != null and _room.camera_rig != null:
		_room.camera_rig.offset = Vector2.ZERO


func set_overlay_visible(value: bool) -> void:
	_overlay.visible = value and controller.active


func reset() -> void:
	if not _can_mutate():
		return
	controller.reset()
	clear_view()


## The prompt cards currently shown (for tests and captures).
func hud() -> UiKangarooHud:
	return _hud


func _can_mutate() -> bool:
	return authority != null and authority.can_commit()


func _update_life_markers() -> void:
	var signature_rows := PackedStringArray(
		[str(controller.marker_counts), str(controller.live_seats)]
	)
	for seat in controller.seat_indices:
		var tracked_actor := _room.actors.get(seat) as ChickenController
		signature_rows.append(
			(
				"%d:%d" % [seat, tracked_actor.get_instance_id()]
				if tracked_actor != null and is_instance_valid(tracked_actor)
				else "%d:missing" % seat
			)
		)
	var signature := ":".join(signature_rows)
	var marker_state_changed := signature != _life_marker_signature
	if marker_state_changed:
		_life_marker_signature = signature
	var active_seats: Dictionary = {}
	for seat in controller.seat_indices:
		var actor := _room.actors.get(seat) as ChickenController
		if actor == null or not is_instance_valid(actor):
			continue
		active_seats[seat] = true
		var marker := _life_markers.get(seat) as KangarooLifeMarker
		if marker == null or not is_instance_valid(marker):
			marker = KangarooLifeMarker.new()
			marker.name = "KangarooLifeMarkerP%d" % (seat + 1)
			_room.world_layer.add_child(marker)
			_life_markers[seat] = marker
		var failure_count := int(controller.marker_counts.get(seat, 0))
		if marker_state_changed or marker.actor != actor or marker.failure_count != failure_count:
			marker.configure(actor, failure_count, _room.tuning.body_height_wu, _room.camera_rig)
		marker.set_overlap_lane(_life_marker_overlap_lane(seat, actor))
	for seat in _life_markers.keys():
		if marker_state_changed and not active_seats.has(seat):
			var marker := _life_markers[seat] as KangarooLifeMarker
			if is_instance_valid(marker):
				marker.queue_free()
			_life_markers.erase(seat)


func _life_marker_overlap_lane(seat: int, actor: ChickenController) -> int:
	var lane := 0
	var zoom_value := _room.camera_rig.zoom.x if _room.camera_rig != null else 1.0
	var overlap_distance := 136.0 / maxf(zoom_value, 0.01)
	for other_seat in controller.seat_indices:
		if int(other_seat) >= seat:
			continue
		var other := _room.actors.get(other_seat) as ChickenController
		if other != null and is_instance_valid(other):
			if absf(other.global_position.x - actor.global_position.x) < overlap_distance:
				lane += 1
	return lane


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
	player.bus = PresentationApplier.BUS_EFFECTS
	player.volume_db = -8.0
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()
	_shake_remaining = SHAKE_SECONDS if _shake_mode() != SHAKE_OFF else 0.0


func _update_shake(delta: float) -> void:
	var camera := _room.camera_rig
	if camera == null:
		return
	_shake_remaining = maxf(0.0, _shake_remaining - delta)
	var mode := _shake_mode()
	if _shake_remaining <= 0.0 or mode == SHAKE_OFF:
		camera.offset = Vector2.ZERO
		return
	var intensity := FULL_SHAKE_PIXELS if mode == SHAKE_FULL else REDUCED_SHAKE_PIXELS
	var fade := clampf(_shake_remaining / SHAKE_SECONDS, 0.0, 1.0)
	var phase := float(Time.get_ticks_msec()) * 0.09
	camera.offset = Vector2(sin(phase), cos(phase * 1.37)) * intensity * fade


## The player's current Screen shake choice, read at each cue so Settings changes apply at once.
func _shake_mode() -> int:
	if _room != null and _room.presentation_settings != null:
		return _room.presentation_settings.screen_shake
	return SHAKE_OFF

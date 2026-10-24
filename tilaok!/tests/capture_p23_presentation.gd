extends SceneTree

## Windowed P23 presentation evidence with synthetic seats and command previews.
## This captures integrated presentation only; the command previews do not evaluate outcomes.

const FLOW_SCENE := preload("res://scenes/flow/game_flow.tscn")
const OUTPUT_RELATIVE := "../docs/evidence/p23_presentation"
const KANGAROO := EventSchedule.Challenge.KANGAROO
const NONE := EventSchedule.Challenge.NONE
const FULL_RESOLUTION := Vector2i(1920, 1080)

var flow: GameFlow
var room: P12ScheduledMatchRoom
var output_dir := ""
var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	output_dir = ProjectSettings.globalize_path("res://").path_join(OUTPUT_RELATIVE).simplify_path()
	DirAccess.make_dir_recursive_absolute(output_dir)
	root.size = FULL_RESOLUTION
	DisplayServer.window_set_size(FULL_RESOLUTION)
	flow = FLOW_SCENE.instantiate() as GameFlow
	flow.harness_mode = true
	root.add_child(flow)
	await _frames(3)
	flow.tutorial_session.completed = true
	flow.settings.muted = true
	flow.settings.screen_shake = 2
	PresentationApplier.apply(flow.settings)
	flow.router.registry.join_keyboard("K1")
	flow.router.registry.join_keyboard("K2")
	flow.router.registry.join_gamepad(7101)
	flow.router.registry.join_gamepad(7102)
	flow.show_title()
	await _frames(2)
	flow._enter_match()
	await _frames(3)
	room = flow.room as P12ScheduledMatchRoom
	if room == null:
		_fail("the scheduled match room did not open")
		quit(1)
		return
	for seat in room.input_router.registry.joined_seats():
		room.input_router.registry.set_ready(int(seat.seat), true)
	if not room.start_match():
		_fail("the scheduled match did not start")
		quit(1)
		return
	room.tuning.match_target_score_units = 100000
	room.tuning.match_results_advance_seconds = 600.0
	room.tuning.kangaroo_telegraph_seconds = 4.0
	room.tuning.kangaroo_response_seconds = 6.0
	room.items.round_number = 1
	room._finish_pugad_timeout()
	var edits: Array[Dictionary] = []
	room._resolve_place_edits(edits)
	_force_kangaroo(room.items.round_number + 1)
	room._start_live_play()
	flow.tutorial_session.skip()
	await _frames(240)
	var seats := room.input_router.registry.joined_seats()
	for index in seats.size():
		var actor := room.actors[int(seats[index].seat)] as ChickenController
		var feet := room.arena.spawn_feet + Vector2(180.0 * index, 0.0)
		actor.global_position = room.arena.controller_origin_from_feet(feet)
		actor.velocity = Vector2.ZERO
	await _frames(8)
	# Freeze the scripted room after P23 has entered PLAY. The snapshots below alter presentation
	# data only; no controller step can evaluate these preview rows or change a race outcome.
	room.set_physics_process(false)
	room.set_process(false)
	room.presenter._go_flash_remaining = 0.0
	room.presenter._update_fullscreen_countdown()
	await _capture_command(KangarooRoundController.Command.FREEZE, "freeze")
	await _capture_command(KangarooRoundController.Command.RISING, "rising")
	await _capture_command(KangarooRoundController.Command.HUG, "hug")
	print("P23_PRESENTATION_CAPTURE failures=%d dir=%s" % [failures, output_dir])
	flow.queue_free()
	await _frames(3)
	quit(1 if failures > 0 else 0)


func _force_kangaroo(round_number: int) -> void:
	room.schedule.locked[round_number] = {
		"round": round_number,
		"main": KANGAROO,
		"twist": NONE,
		"guaranteed": false,
		"sudden_death": false,
		"twist_options": 0,
	}


func _capture_command(command: int, label: String) -> void:
	var active_time: float = room.items.director.simulation_time
	var start := active_time - 0.5
	var response_end := active_time + 4.5
	var preview := {
		"command_id": 100 + command,
		"command": command,
		"status": "RESPONSE",
		"telegraph_start_at": start,
		"response_start_at": active_time - 0.2,
		"response_end_at": response_end,
		"evaluated": false,
		"wave_y": room.arena.spawn_feet.y - 260.0,
		"is_storm": false,
	}
	var commands: Array[Dictionary] = [preview]
	room.kangaroo_round.hud().bind_commands(commands, active_time)
	var links: Array[Dictionary] = []
	if command == KangarooRoundController.Command.FREEZE:
		var actors := room.actors.values()
		if not actors.is_empty():
			(actors[0] as ChickenController).set_kangaroo_frozen(2.0)
	elif command == KangarooRoundController.Command.HUG:
		var seats := room.input_router.registry.joined_seats()
		for index in range(mini(seats.size() - 1, 3)):
			var actor_a := room.actors[int(seats[index].seat)] as ChickenController
			var actor_b := room.actors[int(seats[index + 1].seat)] as ChickenController
			links.append(
				{"position_a": actor_a.global_position, "position_b": actor_b.global_position}
			)
	room.kangaroo_round._presenter.set_state(
		commands,
		room.arena.arena_bounds,
		room.arena.spawn_feet.y,
		active_time,
		room.camera_rig.global_position,
		links
	)
	await _frames(3)
	await RenderingServer.frame_post_draw
	var path := output_dir.path_join("after_1920x1080_4p_%s.png" % label)
	var error := root.get_texture().get_image().save_png(path)
	if error != OK:
		_fail("could not save %s (error %d)" % [path, error])
	else:
		print("P23_PRESENTATION_CAPTURE saved=%s command=%s" % [path, label])


func _frames(count: int) -> void:
	for _frame in range(count):
		await process_frame


func _fail(message: String) -> void:
	failures += 1
	push_error(message)

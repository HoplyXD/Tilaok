extends SceneTree

const ROOM := preload("res://scenes/fixtures/p02_movement_room.tscn")
const EVIDENCE_PATH := "res://../docs/evidence/p02-diagnostic-room.png"
const PAUSE_EVIDENCE_PATH := "res://../docs/evidence/p02-reconnect-pause.png"
const METRICS_PATH := "res://../docs/evidence/p02-rendered-metrics.txt"

var room: P02MovementRoom


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	room = ROOM.instantiate() as P02MovementRoom
	root.add_child(room)
	for _frame in range(6):
		await process_frame
	room.input_router.set_shared_keyboard_enabled(true)
	for toggle in room.find_children("*", "CheckButton", true, false):
		(toggle as CheckButton).set_pressed_no_signal(true)
	room.input_router.set_phase(LocalInputRouter.Phase.LOBBY)
	room.input_router._handle_key(_join_event(KEY_E, true))
	room.input_router._handle_key(_join_event(KEY_E, false))
	room.input_router._handle_key(_join_event(KEY_ENTER, true))
	room.input_router._handle_key(_join_event(KEY_ENTER, false))
	room.input_router.set_phase(LocalInputRouter.Phase.PLAY)
	for device_id in [101, 102]:
		var seat_index := room.input_router.registry.join_gamepad(device_id)
		if seat_index >= 0:
			room.input_router.seat_joined.emit(seat_index)
	for _frame in range(6):
		await process_frame
	var durations_usec := PackedInt64Array()
	var previous_usec := Time.get_ticks_usec()
	for _frame in range(180):
		await process_frame
		var current_usec := Time.get_ticks_usec()
		durations_usec.append(current_usec - previous_usec)
		previous_usec = current_usec
	durations_usec.sort()
	var median_ms := float(durations_usec[durations_usec.size() / 2]) / 1000.0
	var p95_ms := float(durations_usec[roundi((durations_usec.size() - 1) * 0.95)]) / 1000.0
	var worst_ms := float(durations_usec[-1]) / 1000.0
	var viewport_image := root.get_texture().get_image()
	var absolute_image_path := ProjectSettings.globalize_path(EVIDENCE_PATH)
	var absolute_pause_image_path := ProjectSettings.globalize_path(PAUSE_EVIDENCE_PATH)
	var absolute_metrics_path := ProjectSettings.globalize_path(METRICS_PATH)
	DirAccess.make_dir_recursive_absolute(absolute_image_path.get_base_dir())
	viewport_image.save_png(absolute_image_path)
	room.input_router._on_joy_connection_changed(101, false)
	for _frame in range(6):
		await process_frame
	root.get_texture().get_image().save_png(absolute_pause_image_path)
	var metrics := FileAccess.open(absolute_metrics_path, FileAccess.WRITE)
	metrics.store_line(
		(
			"Build: P02-input-movement-dev; base revision: "
			+ "e2b4a555e8d45bec774ffebde7c46e595cd3abdb; local worktree"
		)
	)
	metrics.store_line("Engine: Godot 4.7.2.stable.official.ed1daf0bf; date: 2026-10-13")
	metrics.store_line("Profile: movement_room; seed: 12345; rendered window; 180 frames")
	metrics.store_line(
		"Viewport: %dx%d" % [viewport_image.get_width(), viewport_image.get_height()]
	)
	(
		metrics
		. store_line(
			"Seats: 4 active diagnostic actors; synthetic K1/K2 joins plus synthetic gamepad IDs 101/102"
		)
	)
	metrics.store_line(
		"Frame interval ms median=%.3f p95=%.3f worst=%.3f" % [median_ms, p95_ms, worst_ms]
	)
	metrics.store_line(
		(
			"Godot static memory bytes=%d; object count=%d; node count=%d"
			% [
				Performance.get_monitor(Performance.Monitor.MEMORY_STATIC),
				Performance.get_monitor(Performance.Monitor.OBJECT_COUNT),
				Performance.get_monitor(Performance.Monitor.OBJECT_NODE_COUNT)
			]
		)
	)
	metrics.store_line(
		"Limit: rendered diagnostic fixture only; not late-game stress or physical-device evidence."
	)
	metrics.close()
	var metric_template := (
		"P02_RENDERED_METRIC median_ms=%.3f p95_ms=%.3f worst_ms=%.3f "
		+ "static_memory_bytes=%d object_count=%d node_count=%d"
	)
	print(
		(
			metric_template
			% [
				median_ms,
				p95_ms,
				worst_ms,
				Performance.get_monitor(Performance.Monitor.MEMORY_STATIC),
				Performance.get_monitor(Performance.Monitor.OBJECT_COUNT),
				Performance.get_monitor(Performance.Monitor.OBJECT_NODE_COUNT)
			]
		)
	)
	print(
		(
			"P02_CAPTURE image=%s pause_image=%s metrics=%s"
			% [absolute_image_path, absolute_pause_image_path, absolute_metrics_path]
		)
	)
	print("P02_CAPTURE_PID %d" % OS.get_process_id())
	await create_timer(20.0).timeout
	quit()


func _join_event(key: Key, pressed: bool) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.keycode = key
	event.pressed = pressed
	return event

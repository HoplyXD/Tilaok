extends SceneTree

## Regressions for the 2026-10-16 bug report (user):
## - a Cannon whose path was drawn past the stage edge made every block invalid, so a started
##   match showed only the map (no Lobby, pause or leave);
## - pause showed "Seat 3 lost its controller" for empty seats in a 2-player match;
## plus the fixed flows: Title -> Lobby, pause -> all ready -> resume, Leave -> Yes -> Lobby.
## Run: godot --headless --fixed-fps 60 --path tilaok!
##   --script res://tests/run_fix_regression_tests.gd

const FLOW_SCENE := preload("res://scenes/flow/game_flow.tscn")
const BROKEN_BLOCK := "res://scenes/blocks/zz_test_broken_block.tscn"
const SPIKES_SCENE := "res://scenes/blocks/traps/spikes.tscn"

var failures := 0
var checks := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	_test_long_projectile_path()
	_test_broken_block_is_skipped()
	await _test_title_lobby_pause_leave()
	print("FIX_REGRESSION_TESTS checks=%d failures=%d" % [checks, failures])
	await process_frame
	quit(1 if failures > 0 else 0)


func _check(condition: bool, label: String) -> void:
	checks += 1
	if condition:
		print("PASS ", label)
	else:
		failures += 1
		push_error("FAIL " + label)


func _test_long_projectile_path() -> void:
	var root_node := Node2D.new()
	var projectile := Node2D.new()
	root_node.add_child(projectile)
	var path := Path2D.new()
	path.curve = Curve2D.new()
	path.curve.add_point(Vector2(32, 0))
	path.curve.add_point(Vector2(2749, -5))
	projectile.add_child(path)
	var rect := BlockCatalog._path_rect(projectile, root_node)
	root_node.free()
	_check(
		is_equal_approx(rect.position.x, 32.0) and is_equal_approx(rect.size.x, 32.0 * 64.0),
		(
			"a projectile path drawn past the stage is clamped to the stage width from its start (%s)"
			% rect
		)
	)
	BlockCatalog.reload()
	var definitions := ItemDefinitions.load_all(GameplayTuning.new())
	_check(
		definitions.is_valid() and not definitions.find_variant("block.cannon.main").is_empty(),
		"the item catalog is valid and the Cannon loads: %s" % [definitions.errors]
	)


func _test_broken_block_is_skipped() -> void:
	# A copy of Spikes with its kill hitbox far outside its 1x1 placement box: invalid on purpose.
	var copy := (load(SPIKES_SCENE) as PackedScene).instantiate()
	var data := copy.get_node("BlockData") as BlockData
	data.family_id = "block.zz_test_broken"
	data.block_name = "Broken test block"
	(copy.get_node("KillHitbox/Shape") as CollisionShape2D).position = Vector2(900, 0)
	var packed := PackedScene.new()
	packed.pack(copy)
	copy.free()
	ResourceSaver.save(packed, BROKEN_BLOCK)
	BlockCatalog.reload()
	var definitions := ItemDefinitions.load_all(GameplayTuning.new())
	var skipped := " ".join(BlockCatalog.skipped())
	_check(
		(
			definitions.is_valid()
			and definitions.find_variant("block.zz_test_broken.main").is_empty()
			and skipped.contains("block.zz_test_broken")
			and not definitions.find_variant("block.spikes.main").is_empty()
		),
		"a broken block scene is left out and reported; every other block still loads"
	)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(BROKEN_BLOCK))
	BlockCatalog.reload()


func _key(key: Key, pressed: bool) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.pressed = pressed
	return event


func _press(flow: GameFlow, key: Key) -> void:
	flow.router._handle_key(_key(key, true))
	for _frame in range(3):
		await process_frame
	flow.router._handle_key(_key(key, false))
	for _frame in range(3):
		await process_frame


func _test_title_lobby_pause_leave() -> void:
	var flow := FLOW_SCENE.instantiate() as GameFlow
	root.add_child(flow)
	for _frame in range(5):
		await process_frame
	await _press(flow, KEY_E)
	(flow._screen as UiTitleScreen).start_requested.emit()
	for _frame in range(6):
		await process_frame
	var room := flow.room
	_check(
		room != null and room.presenter.lobby_screen.is_visible_in_tree(),
		"Start local match opens the Lobby screen (not just the map)"
	)
	flow.tutorial_session.skip()
	await _press(flow, KEY_O)
	await _press(flow, KEY_E)
	await _press(flow, KEY_O)
	for _frame in range(10):
		await process_frame
	room = flow.room
	_check(
		room.phase_controller.phase == MatchPhaseController.Phase.PUGAD,
		"two ready players start the match"
	)
	room._finish_pugad_timeout()
	var none: Array[Dictionary] = []
	room._resolve_place_edits(none)
	for _frame in range(10):
		await physics_frame
	await _press(flow, KEY_ESCAPE)
	var pause := room.presenter.pause_screen
	_check(
		paused and pause.visible and not pause._reclaim_panel.visible,
		"pausing a 2-player match shows no 'seat lost its controller' panel for empty seats"
	)
	await _press(flow, KEY_E)
	await _press(flow, KEY_E)
	await _press(flow, KEY_O)
	await create_timer(room.pause_coordinator.resume_countdown_seconds + 0.5, true).timeout
	_check(
		not paused and room.pause_coordinator.state == PauseRecoveryCoordinator.State.RUNNING,
		"after every player is ready the resume countdown finishes and play continues"
	)
	await _press(flow, KEY_ESCAPE)
	await _press(flow, KEY_E)
	for key in [KEY_S, KEY_S, KEY_S]:
		await _press(flow, key)
	await _press(flow, KEY_E)
	_check(pause._leave_confirm.is_open(), "Leave match asks for confirmation (No is preselected)")
	await _press(flow, KEY_A)
	await _press(flow, KEY_E)
	for _frame in range(10):
		await process_frame
	_check(
		(
			flow.room != room
			and flow.room.phase_controller.phase == MatchPhaseController.Phase.LOBBY
			and not paused
			and flow.router.registry.joined_seats().size() == 2
		),
		"Leave match -> Yes returns everyone to the Lobby with their seats"
	)
	flow.queue_free()
	await process_frame

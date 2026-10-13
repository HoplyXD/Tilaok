extends SceneTree

## Renders every UI shell screen (state 0) with 1 and 4 players at three window sizes and logs a
## gallery frame-time sample. Run windowed (not headless) so real frames are drawn.

const GALLERY_SCENE := "res://scenes/ui/ui_gallery.tscn"
const EVIDENCE_DIR := "../docs/evidence/ui-shells"
const SIZES := [Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(1920, 800)]
const PERF_FRAMES := 300

var saved := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	var gallery := (load(GALLERY_SCENE) as PackedScene).instantiate() as UiGallery
	root.add_child(gallery)
	await process_frame
	gallery.set_chrome_visible(false)
	var dir := ProjectSettings.globalize_path("res://").path_join(EVIDENCE_DIR).simplify_path()
	DirAccess.make_dir_recursive_absolute(dir)
	for size in SIZES:
		DisplayServer.window_set_size(size)
		for _i in 10:
			await process_frame
		for players in [1, 4]:
			gallery.set_players(players)
			for index in UiGallery.SCREEN_IDS.size():
				gallery.show_screen(index)
				for _i in 4:
					await process_frame
				await RenderingServer.frame_post_draw
				var file_name := (
					"%dx%d_%dp_%s.png" % [size.x, size.y, players, UiGallery.SCREEN_IDS[index]]
				)
				var image := root.get_texture().get_image()
				if image.save_png(dir.path_join(file_name)) == OK:
					saved += 1
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	for _i in 10:
		await process_frame
	gallery.set_players(4)
	gallery.show_screen(gallery.index_of("play_hud"))
	var samples: Array[float] = []
	for _i in PERF_FRAMES:
		var start := Time.get_ticks_usec()
		await process_frame
		await RenderingServer.frame_post_draw
		samples.append(float(Time.get_ticks_usec() - start) / 1000.0)
	samples.sort()
	print(
		(
			"UI_CAPTURE saved=%d frames=%d median_ms=%.3f p95_ms=%.3f worst_ms=%.3f "
			+ (
				"nodes=%d objects=%d mem_mib=%.1f"
				% [
					saved,
					samples.size(),
					samples[samples.size() / 2],
					samples[int(samples.size() * 0.95)],
					samples[samples.size() - 1],
					int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
					int(Performance.get_monitor(Performance.OBJECT_COUNT)),
					float(OS.get_static_memory_usage()) / 1048576.0
				]
			)
		)
	)
	quit(0)

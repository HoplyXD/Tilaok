extends SceneTree

## Renders the screens restyled from the Figma reference (Lobby, Play HUD, Place, Round result,
## Pause, Leave-match and Quit confirmations, the component sheet) at 1920x1080 with 2, 3 and 4
## players, and writes a side-by-side JPG next to each reference PNG when the reference folder is
## available. Run windowed (not headless) so real frames are drawn:
##   Godot --path tilaok! --script res://tests/capture_ui_reference_evidence.gd
## Optional: -- --reference-dir=<folder with the exported PNGs> --out-dir=<folder>

const GALLERY_SCENE := "res://scenes/ui/ui_gallery.tscn"
const EVIDENCE_DIR := "../docs/evidence/ui-reference"
const DEFAULT_REFERENCE_DIR := "C:/Users/omsha/Downloads/Figma UI Screens"
const SIZE := Vector2i(1920, 1080)
const PERF_FRAMES := 300

## [screen id, state index, player counts, reference file or ""]
const SHOTS := [
	["lobby", 0, [4], "Lobby.png"],
	["lobby", 2, [2], "Lobby.png"],
	["lobby", 3, [3, 4], "Lobby.png"],
	["lobby", 4, [4], "Lobby.png"],
	["play_hud", 0, [2, 3, 4], "Obstacle Place.png"],
	["play_hud", 1, [4], ""],
	["play_hud", 2, [4], ""],
	["place", 0, [2, 4], "Obstacle Place.png"],
	["place", 1, [4], "Obstacle Place.png"],
	["place", 2, [4], ""],
	["place", 3, [4], ""],
	["round_result", 0, [2, 3, 4], "Round Results.png"],
	["round_result", 1, [4], ""],
	["round_result", 2, [4], ""],
	["pause", 0, [2, 3, 4], "Pause Menu.png"],
	["pause", 3, [4], "Pause Menu (With Warning).png"],
	["pause", 4, [4], "Leave Match Confirmation.png"],
	["title", 2, [2], "Confirm Exit UI.png"],
	["components", 0, [4], "Button Variants.png"],
]

var saved := 0
var compared := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(SIZE)
	var gallery := (load(GALLERY_SCENE) as PackedScene).instantiate() as UiGallery
	root.add_child(gallery)
	for _i in 10:
		await process_frame
	gallery.set_chrome_visible(false)
	var dir := _out_dir()
	DirAccess.make_dir_recursive_absolute(dir)
	var reference_dir := _reference_dir()
	for shot in SHOTS:
		for players in shot[2]:
			gallery.set_players(players)
			gallery.show_screen(gallery.index_of(shot[0]))
			gallery.set_state(shot[1])
			for _i in 6:
				await process_frame
			await RenderingServer.frame_post_draw
			var image := root.get_texture().get_image()
			var stem := "%s_s%d_%dp" % [shot[0], shot[1], players]
			if image.save_png(dir.path_join(stem + ".png")) == OK:
				saved += 1
			var reference_name := str(shot[3])
			if not reference_name.is_empty() and not reference_dir.is_empty():
				var reference := Image.load_from_file(reference_dir.path_join(reference_name))
				if reference != null and not reference.is_empty():
					var pair := _side_by_side(reference, image)
					if pair.save_jpg(dir.path_join(stem + "_vs_reference.jpg"), 0.82) == OK:
						compared += 1
	var samples := await _frame_samples(gallery)
	print(
		(
			"UI_REFERENCE_CAPTURE saved=%d compared=%d vsync=off frames=%d "
			+ "median_ms=%.3f p95_ms=%.3f worst_ms=%.3f nodes=%d draw_calls=%d "
			+ "mem_static_mib=%.1f video_mib=%.1f"
		)
		% [
			saved,
			compared,
			samples.size(),
			samples[samples.size() / 2],
			samples[int(samples.size() * 0.95)],
			samples[samples.size() - 1],
			int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
			int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
			float(OS.get_static_memory_usage()) / 1048576.0,
			Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0,
		]
	)
	quit(0)


## Heaviest screen: 4-player Round result (chart, chalkboard, awards, legend). VSync is turned off
## for the sample so the numbers are the frame cost, not the display's pacing.
func _frame_samples(gallery: UiGallery) -> Array[float]:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	gallery.set_players(4)
	gallery.show_screen(gallery.index_of("round_result"))
	gallery.set_state(0)
	for _i in 30:
		await process_frame
	var samples: Array[float] = []
	for _i in PERF_FRAMES:
		var start := Time.get_ticks_usec()
		await process_frame
		await RenderingServer.frame_post_draw
		samples.append(float(Time.get_ticks_usec() - start) / 1000.0)
	samples.sort()
	return samples


func _out_dir() -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):
			return arg.trim_prefix("--out-dir=")
	return ProjectSettings.globalize_path("res://").path_join(EVIDENCE_DIR).simplify_path()


func _reference_dir() -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--reference-dir="):
			return arg.trim_prefix("--reference-dir=")
	return DEFAULT_REFERENCE_DIR if DirAccess.dir_exists_absolute(DEFAULT_REFERENCE_DIR) else ""


## Reference on the left, render on the right, both fitted into 960x540 cells.
func _side_by_side(reference: Image, render: Image) -> Image:
	var cell := Vector2i(960, 540)
	var out := Image.create(cell.x * 2, cell.y, false, Image.FORMAT_RGB8)
	out.fill(Color(0.1, 0.1, 0.1))
	var left := _fit(reference, cell)
	var right := _fit(render, cell)
	out.blit_rect(left, Rect2i(Vector2i.ZERO, left.get_size()), (cell - left.get_size()) / 2)
	out.blit_rect(
		right,
		Rect2i(Vector2i.ZERO, right.get_size()),
		Vector2i(cell.x, 0) + (cell - right.get_size()) / 2
	)
	return out


func _fit(source: Image, cell: Vector2i) -> Image:
	var image := source.duplicate() as Image
	image.convert(Image.FORMAT_RGB8)
	var scale := minf(float(cell.x) / image.get_width(), float(cell.y) / image.get_height())
	image.resize(
		maxi(1, int(image.get_width() * scale)),
		maxi(1, int(image.get_height() * scale)),
		Image.INTERPOLATE_BILINEAR
	)
	return image

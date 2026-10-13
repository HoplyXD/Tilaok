extends SceneTree
## Writes the DEBUG placeholder stage tile atlas (assets/tiles/debug_tiles_64.png).
## Three flat 64x64 tiles: 0 ground, 1 containment boundary, 2 base platform.
## Code-generated graybox only; the art team replaces this atlas with final tiles.
## Run: godot --headless --path tilaok! --script res://tools/make_debug_tiles.gd

const TILE := 64
const FILLS := [Color("#70583f"), Color("#3d4b55"), Color("#8a6a48")]
const TOPS := [Color("#8fb36b"), Color("#56656f"), Color("#c2965f")]
const EDGE := Color("#2a1d12")


func _init() -> void:
	var image := Image.create(TILE * FILLS.size(), TILE, false, Image.FORMAT_RGBA8)
	for index in range(FILLS.size()):
		var origin := Vector2i(index * TILE, 0)
		image.fill_rect(Rect2i(origin, Vector2i(TILE, TILE)), FILLS[index])
		image.fill_rect(Rect2i(origin, Vector2i(TILE, 8)), TOPS[index])
		for edge in [
			Rect2i(origin, Vector2i(TILE, 2)),
			Rect2i(origin + Vector2i(0, TILE - 2), Vector2i(TILE, 2)),
			Rect2i(origin, Vector2i(2, TILE)),
			Rect2i(origin + Vector2i(TILE - 2, 0), Vector2i(2, TILE)),
		]:
			image.fill_rect(edge, EDGE)
	var path := ProjectSettings.globalize_path("res://assets/tiles/debug_tiles_64.png")
	var error := image.save_png(path)
	print("DEBUG_TILES saved=%s error=%d" % [path, error])
	quit(error)

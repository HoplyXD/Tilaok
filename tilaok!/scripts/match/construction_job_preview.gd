class_name ConstructionJobPreview
extends Node2D

var owner_number := 1
var shape_mark := "◆"
var item_label := "Build"
var footprint := Rect2()
var elapsed := 0.0
var duration := 2.0


func configure(job: Dictionary, job_duration: float) -> void:
	owner_number = int(job.get("owner_number", 1))
	shape_mark = str(job.get("shape_mark", "◆"))
	item_label = str(job.get("item_label", "Build"))
	footprint = job.get("footprint", Rect2())
	duration = maxf(0.1, job_duration)
	queue_redraw()


func set_progress(value: float, total: float) -> void:
	elapsed = clampf(value, 0.0, maxf(0.1, total))
	duration = maxf(0.1, total)
	queue_redraw()


func _draw() -> void:
	if footprint.size.x <= 0.0 or footprint.size.y <= 0.0:
		return
	var progress := clampf(elapsed / duration, 0.0, 1.0)
	var owner_color := Color.from_hsv(float(posmod(owner_number - 1, 4)) / 4.0, 0.78, 1.0)
	var outline := owner_color
	outline.a = 0.96
	var fill := owner_color
	fill.a = 0.17
	draw_rect(footprint, fill, true)
	draw_rect(footprint, outline, false, 3.0, true)
	var font := ThemeDB.fallback_font
	if font == null:
		return
	var label := (
		"P%d %s  %s  %.1f s" % [owner_number, shape_mark, item_label, maxf(0.0, duration - elapsed)]
	)
	var label_position := footprint.position + Vector2(4.0, -8.0)
	draw_string(font, label_position, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
	var bar := Rect2(
		footprint.position + Vector2(0.0, footprint.size.y + 4.0), Vector2(footprint.size.x, 7.0)
	)
	draw_rect(bar, Color(0.06, 0.08, 0.12, 0.88), true)
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * progress, bar.size.y)), outline, true)

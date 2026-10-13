class_name StageCameraTarget
extends RefCounted

var target_id := ""
var world_rect := Rect2()


func _init(id: String = "", target_bounds: Rect2 = Rect2()) -> void:
	target_id = id
	world_rect = target_bounds

class_name SupportContact
extends RefCounted

var actor_id := ""
var surface_id := ""
var construction_id := ""
var player_built := false
var eligibility := SupportSurfaceMetadata.Eligibility.UNSET
var normal := Vector2.ZERO
var contact_position := Vector2.ZERO
var feet_y := 0.0
var relative_velocity := Vector2.ZERO
var physics_step := -1


func qualifies(line_y: float, height_epsilon: float) -> bool:
	return (
		player_built
		and eligibility == SupportSurfaceMetadata.Eligibility.ELIGIBLE
		and feet_y <= line_y + height_epsilon
	)

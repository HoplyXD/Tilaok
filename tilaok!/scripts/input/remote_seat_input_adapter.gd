class_name RemoteSeatInputAdapter
extends RefCounted

## Transport-free adapter. A trusted host binds a source to a seat; input never carries a seat.
const MAX_SOURCE_ID_LENGTH := 64
const ACTIONS := [
	"left",
	"right",
	"up",
	"down",
	"jump",
	"confirm",
	"back",
	"rotate",
	"pause",
	"ready",
	"claim",
	"cheer",
	"help"
]

var router: LocalInputRouter
var authority: SimulationAuthority


func configure(input_router: LocalInputRouter, source_authority: SimulationAuthority) -> bool:
	if input_router == null or source_authority == null:
		return false
	router = input_router
	authority = source_authority
	return router.set_authority(authority)


func assign_source(source_id: String, seat_index: int = -1) -> int:
	if not _can_assign() or not _valid_source_id(source_id):
		return -1
	return router.registry.assign_remote_source(source_id, seat_index, authority)


func revoke_source(source_id: String) -> bool:
	if not _can_assign() or router.registry.seat_for_remote_source(source_id) < 0:
		return false
	router.clear_remote_source(source_id)
	return router.registry.revoke_remote_source(source_id, authority)


func release_source(source_id: String) -> bool:
	if not _can_assign() or router.registry.seat_for_remote_source(source_id) < 0:
		return false
	router.clear_remote_source(source_id)
	return router.registry.release_remote_source(source_id, authority)


func submit_action(source_id: String, action_name: String, pressed: bool) -> bool:
	if not _valid_submission(source_id) or action_name not in ACTIONS:
		return false
	return router.apply_remote_action(source_id, action_name, pressed)


func submit_movement_axis(source_id: String, value: float) -> bool:
	if not _valid_submission(source_id) or not is_finite(value) or value < -1.0 or value > 1.0:
		return false
	return router.apply_remote_axis(source_id, value)


func submit_sample(
	source_id: String, axes: Array, aim: Array, held_mask: int, build_mode: bool
) -> bool:
	if not _valid_submission(source_id):
		return false
	return router.apply_remote_sample(source_id, axes, aim, held_mask, build_mode)


func _can_assign() -> bool:
	return (
		router != null
		and authority != null
		and authority.can_commit()
		and authority.role == SimulationAuthority.Role.HOST_AUTHORITY
	)


func _valid_submission(source_id: String) -> bool:
	return (
		router != null
		and authority != null
		and authority.can_commit()
		and authority.role == SimulationAuthority.Role.HOST_AUTHORITY
		and _valid_source_id(source_id)
		and router.registry.seat_for_remote_source(source_id) >= 0
	)


func _valid_source_id(source_id: String) -> bool:
	if source_id.is_empty() or source_id.length() > MAX_SOURCE_ID_LENGTH:
		return false
	for index in source_id.length():
		var code := source_id.unicode_at(index)
		var allowed := (
			code == 45
			or (code >= 48 and code <= 57)
			or (code >= 65 and code <= 90)
			or (code >= 95 and code <= 122)
		)
		if not allowed:
			return false
	return true

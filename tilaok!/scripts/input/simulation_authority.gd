class_name SimulationAuthority
extends RefCounted

## Runtime role for the one shared simulation. Offline remains the safe default.
enum Role { OFFLINE_AUTHORITY, HOST_AUTHORITY, CLIENT_PRESENTATION }

var role := Role.OFFLINE_AUTHORITY
var configured := true


static func offline() -> SimulationAuthority:
	return SimulationAuthority.new()


static func host() -> SimulationAuthority:
	var authority := SimulationAuthority.new()
	authority.role = Role.HOST_AUTHORITY
	return authority


static func client_presentation() -> SimulationAuthority:
	var authority := SimulationAuthority.new()
	authority.role = Role.CLIENT_PRESENTATION
	return authority


func configure(requested_role: int) -> bool:
	if requested_role < Role.OFFLINE_AUTHORITY or requested_role > Role.CLIENT_PRESENTATION:
		configured = false
		return false
	role = requested_role as Role
	configured = true
	return true


func can_commit() -> bool:
	return configured and role in [Role.OFFLINE_AUTHORITY, Role.HOST_AUTHORITY]


func is_client_presentation() -> bool:
	return configured and role == Role.CLIENT_PRESENTATION


func detached_snapshot(value: Variant) -> Variant:
	if value is Dictionary or value is Array:
		return value.duplicate(true)
	if value is Resource:
		return value.duplicate(true)
	return value

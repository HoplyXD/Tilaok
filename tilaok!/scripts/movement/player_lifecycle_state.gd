class_name PlayerLifecycleState
extends RefCounted

enum Status { ACTIVE, CAPTURED, OPENING_FREEZE, SECURED, ELIMINATED }

var status := Status.ACTIVE
var capture_source_id := ""
var terminal_reason := ""


func is_terminal() -> bool:
	return status in [Status.SECURED, Status.ELIMINATED]


func set_status(next_status: Status, reason: String = "") -> bool:
	if is_terminal():
		return false
	status = next_status
	if next_status in [Status.SECURED, Status.ELIMINATED]:
		terminal_reason = reason
	return true

class_name NetworkPauseController
extends RefCounted

## Global pause state for the network routes (contract v1.5, NLB-P08).
## The host is the only writer: `host_set` advances a monotonic epoch. A client only ever applies
## a state received from the host (`apply_host_state`), and a client pause is a local overlay that
## never touches this object. A duplicate epoch is idempotent; a stale epoch is ignored.
const REQUESTS_PER_SECOND := 2
const MAX_EPOCH := 0xffffffff

var epoch := 0
var paused := false
var reason := NetworkLifecycleCodec.PauseReason.HOST_REQUEST
var authority := SimulationAuthority.offline()
var _request_times: Array[int] = []


func reset() -> void:
	epoch = 0
	paused = false
	reason = NetworkLifecycleCodec.PauseReason.HOST_REQUEST
	_request_times.clear()


## Host only. Returns true when the state actually changed (a new epoch was issued).
func host_set(
	new_paused: bool, new_reason: int, now_ms: int, host_authority: SimulationAuthority = null
) -> bool:
	if host_authority == null:
		host_authority = authority
	if host_authority == null or not host_authority.can_commit():
		return false
	if host_authority.role != SimulationAuthority.Role.HOST_AUTHORITY:
		return false
	if new_paused == paused:
		return false
	while not _request_times.is_empty() and now_ms - _request_times[0] >= 1000:
		_request_times.pop_front()
	if _request_times.size() >= REQUESTS_PER_SECOND or epoch >= MAX_EPOCH:
		return false
	_request_times.append(now_ms)
	epoch += 1
	paused = new_paused
	reason = new_reason
	return true


## Client side. Returns "applied", "duplicate" or "stale".
func apply_host_state(record: Dictionary) -> String:
	var incoming := int(record.get("epoch", 0))
	if incoming <= 0:
		return "stale"
	if incoming == epoch:
		return "duplicate"
	if not _epoch_is_newer(incoming, epoch):
		return "stale"
	epoch = incoming
	paused = int(record.get("state", 0)) == NetworkLifecycleCodec.PauseState.PAUSED
	reason = int(record.get("reason", 0))
	return "applied"


func record(match_id: int, round_id: int, attempt_id: int, host_tick: int) -> Dictionary:
	return {
		"match_id": match_id,
		"round_id": round_id,
		"attempt_id": attempt_id,
		"host_tick": host_tick,
		"epoch": maxi(epoch, 1),
		"state": (
			NetworkLifecycleCodec.PauseState.PAUSED
			if paused
			else NetworkLifecycleCodec.PauseState.RUNNING
		),
		"reason": reason,
	}


func _epoch_is_newer(current: int, previous: int) -> bool:
	var difference := (current - previous) & 0xffffffff
	return difference > 0 and difference < 0x80000000

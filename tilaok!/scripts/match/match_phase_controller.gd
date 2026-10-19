class_name MatchPhaseController
extends RefCounted

signal phase_changed(previous_phase: Phase, next_phase: Phase)

enum Phase { LOBBY, PUGAD, PLACE, PLAY, RESULTS, GO }

var phase := Phase.LOBBY
var authority := SimulationAuthority.offline()
var remaining_seconds := 0.0
var elapsed_seconds := 0.0


func enter(next_phase: Phase, duration_seconds: float = 0.0) -> void:
	if authority == null or not authority.can_commit():
		return
	if phase == next_phase:
		remaining_seconds = maxf(0.0, duration_seconds)
		elapsed_seconds = 0.0
		return
	var previous := phase
	phase = next_phase
	remaining_seconds = maxf(0.0, duration_seconds)
	elapsed_seconds = 0.0
	phase_changed.emit(previous, next_phase)


func advance(delta: float) -> bool:
	if authority == null or not authority.can_commit():
		return false
	if delta <= 0.0 or remaining_seconds <= 0.0:
		return remaining_seconds <= 0.0
	elapsed_seconds += delta
	remaining_seconds = maxf(0.0, remaining_seconds - delta)
	return remaining_seconds <= 0.0


func fraction_remaining(duration_seconds: float) -> float:
	if duration_seconds <= 0.0:
		return 0.0
	return clampf(remaining_seconds / duration_seconds, 0.0, 1.0)

class_name PhaseCycle
extends RefCounted

## Timed windows as a pure function of elapsed time: inactive first, charge inside its tail, then
## active. Reset and pause are therefore exact and the charge never extends the cycle.

enum Phase { INACTIVE, CHARGE, ACTIVE }


static func phase_at(elapsed: float, cycle_s: float, active_s: float, charge_s: float) -> Phase:
	var position := fposmod(elapsed, cycle_s)
	var inactive_s := cycle_s - active_s
	if position >= inactive_s:
		return Phase.ACTIVE
	if position >= inactive_s - charge_s:
		return Phase.CHARGE
	return Phase.INACTIVE


## 0..1 progress through the charge window (0 outside it).
static func charge_progress(
	elapsed: float, cycle_s: float, active_s: float, charge_s: float
) -> float:
	var position := fposmod(elapsed, cycle_s)
	var inactive_s := cycle_s - active_s
	var charge_start := inactive_s - charge_s
	if charge_s <= 0.0 or position < charge_start or position >= inactive_s:
		return 0.0
	return (position - charge_start) / charge_s


static func phase_name(phase: Phase) -> String:
	match phase:
		Phase.CHARGE:
			return "charge"
		Phase.ACTIVE:
			return "active"
	return "inactive"

class_name AttributionRecord
extends RefCounted

## Typed source record for P06's future ledger. Items only RECORD; no points are computed here.
## Direct elimination by a hazard credits the placer only when it is not a self-kill. Movement and
## capture setup (spring launch, bubble capture) is recorded as setup_only and never credited.

enum Kind { ELIMINATION, SETUP }

var kind := Kind.ELIMINATION
var player_seat := -1
var source_item_id := ""
var source_family_id := ""
var owner_seat := -1
var physics_time := 0.0
var self_kill := false
var setup_only := false
var detail := ""


func credit_eligible() -> bool:
	return kind == Kind.ELIMINATION and not self_kill and not setup_only and owner_seat >= 0


func summary() -> String:
	return (
		"%s|player%d|%s|owner%d|t=%.4f|self=%s|setup=%s|%s"
		% [
			"ELIM" if kind == Kind.ELIMINATION else "SETUP",
			player_seat,
			source_item_id,
			owner_seat,
			physics_time,
			self_kill,
			setup_only,
			detail
		]
	)

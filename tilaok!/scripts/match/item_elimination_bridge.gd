class_name ItemEliminationBridge
extends RefCounted

## Hands a first-batch hazard's direct elimination to the P06 race ledger as a candidate. The
## ledger owns the terminal commit, ordering and the rule that a self-kill earns no credit.


static func submit(
	queue: RaceCandidateQueue,
	controller: RaceRoundController,
	playing: bool,
	record: AttributionRecord
) -> bool:
	if not playing or controller.ended or queue == null:
		return false
	var tick := Engine.get_physics_frames()
	var event_id := (
		"%s:item:%s:%d:%d"
		% [controller.ledger.round_id, record.source_item_id, tick, record.player_seat]
	)
	return queue.queue_elimination(
		record.player_seat, tick, record.source_item_id, record.owner_seat, event_id
	)

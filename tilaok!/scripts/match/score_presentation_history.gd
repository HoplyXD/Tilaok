class_name ScorePresentationHistory
extends RefCounted

## Presentation-only provenance for the result chart. The score calculators and match totals stay
## authoritative; this class records only results whose owner has already accepted the commit.
const MAX_RETAINED_ROUNDS := 12
const MAX_COMMIT_TOMBSTONES := 64

var _rounds: Array[Dictionary] = []
var _committed_keys: Dictionary = {}
var _commit_order: Array[String] = []


func reset() -> void:
	_rounds.clear()
	_committed_keys.clear()
	_commit_order.clear()


## Call only after the scoring owner has committed this result. A round is a single atomic commit.
func record_committed(match_id: int, round_number: int, result: Dictionary) -> bool:
	if match_id < 0 or round_number < 1 or not bool(result.get("valid", true)):
		return false
	var commit_key := "%d:%d" % [match_id, round_number]
	if _committed_keys.has(commit_key):
		return false
	var rows: Array[Dictionary] = []
	var row_ordinals: Dictionary = {}
	for raw_variant in result.get("award_rows", []):
		if not raw_variant is Dictionary:
			continue
		var raw: Dictionary = raw_variant
		var units := int(raw.get("units", 0))
		var seat := int(raw.get("seat_index", -1))
		var key := str(raw.get("key", ""))
		if units <= 0 or seat < 0 or key.is_empty():
			continue
		var ordinal_key := "%d:%s" % [seat, key]
		var ordinal := int(row_ordinals.get(ordinal_key, 0))
		row_ordinals[ordinal_key] = ordinal + 1
		(
			rows
			. append(
				{
					"seat_index": seat,
					"key": key,
					"row_id": "%d:%s:%d" % [seat, key, ordinal],
					"title": str(raw.get("title", key.capitalize())),
					"units": units,
					"explanation": str(raw.get("explanation", "")),
				}
			)
		)
	_rounds.append({"match_id": match_id, "round_number": round_number, "rows": rows})
	_committed_keys[commit_key] = true
	_commit_order.append(commit_key)
	while _commit_order.size() > MAX_COMMIT_TOMBSTONES:
		var oldest_key: String = _commit_order.pop_front()
		_committed_keys.erase(oldest_key)
	while _rounds.size() > MAX_RETAINED_ROUNDS:
		_rounds.pop_front()
	return true


## Builds a detached chart snapshot. Any total without retained award provenance is represented by
## one neutral previous-total segment, so eviction and preloaded totals never alter displayed sums.
func snapshot(totals: Dictionary, reveal_round: int = -1) -> Dictionary:
	var awards_by_seat: Dictionary = {}
	var retained_rounds: Array[int] = []
	for round_record in _rounds:
		var number := int(round_record.round_number)
		retained_rounds.append(number)
		for award in round_record.rows:
			var seat := int(award.seat_index)
			if not awards_by_seat.has(seat):
				awards_by_seat[seat] = []
			var copied: Dictionary = award.duplicate(true)
			copied["round_number"] = number
			copied["reveal"] = number == reveal_round
			awards_by_seat[seat].append(copied)
	var seats: Array[Dictionary] = []
	var seat_keys: Array[int] = []
	for seat_variant in totals:
		seat_keys.append(int(seat_variant))
	seat_keys.sort()
	for seat_index in seat_keys:
		var total_data: Variant = totals.get(seat_index, totals.get(str(seat_index), {}))
		if not total_data is Dictionary:
			continue
		var total: Dictionary = total_data
		var total_units := int(total.get("units", 0))
		var segments: Array[Dictionary] = []
		var known_units := 0
		for award in awards_by_seat.get(seat_index, []):
			var copied: Dictionary = award.duplicate(true)
			known_units += int(copied.units)
			segments.append(copied)
		var neutral_units := maxi(total_units - known_units, 0)
		if neutral_units > 0:
			(
				segments
				. push_front(
					{
						"key": "previous_total",
						"row_id": "previous:%d" % seat_index,
						"title": "Previous total",
						"units": neutral_units,
						"reveal": false,
					}
				)
			)
		(
			seats
			. append(
				{
					"seat_index": seat_index,
					"identity": int(total.get("identity", seat_index + 1)),
					"shape": str(total.get("shape", "")),
					"units": total_units,
					"delta_units": int(total.get("delta_units", 0)),
					"text": str(total.get("text", ScoreFormat.format_units(total_units))),
					"delta_text": str(total.get("delta_text", "")),
					"status": str(total.get("status", "")),
					"color": total.get("color", Color.WHITE),
					"segments": segments,
				}
			)
		)
	return {"seats": seats, "retained_rounds": retained_rounds}


func retained_round_count() -> int:
	return _rounds.size()


func retained_award_count() -> int:
	var count := 0
	for round_record in _rounds:
		count += round_record.rows.size()
	return count


func total_units_in_segments(seat_row: Dictionary) -> int:
	var total := 0
	for segment in seat_row.get("segments", []):
		total += int(segment.get("units", 0))
	return total

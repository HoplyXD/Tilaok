# gdlint: disable=max-returns
class_name LivePlacementPipeline
extends RefCounted

## Bounded, host-ordered request queue for the offline live-build route. The router supplies the
## seat from its registered physical source; request payloads never choose their own owner.

const MAX_PENDING_PER_SEAT := 1
const MAX_PER_BOUNDARY := 4
const MAX_PER_SEAT_PER_ATTEMPT := 8
const REQUEST_RECORD := preload("res://scripts/match/live_placement_request.gd")
const RECEIPT_RECORD := preload("res://scripts/match/live_placement_receipt.gd")
const RESULT_RECORD := preload("res://scripts/match/live_placement_result.gd")

var attempt_id := ""
var match_id := 0
var round_id := 0
var stage_version := 0
var sequence := 0
var pending: Array[Dictionary] = []
var pending_by_seat: Dictionary = {}
var request_records: Dictionary = {}
var unique_counts: Dictionary = {}


func begin_attempt(match_value: int, round_value: int, version: int) -> void:
	attempt_id = "%d:%d:live" % [match_value, round_value]
	match_id = match_value
	round_id = round_value
	stage_version = version
	sequence = 0
	pending.clear()
	pending_by_seat.clear()
	request_records.clear()
	unique_counts.clear()


func submit(
	intent: Dictionary,
	registered_seat: int,
	receipt_usec: int,
	boundary: int,
	occupied_seats: Array[int]
) -> Dictionary:
	var request_id := str(intent.get("request_id", ""))
	if request_id.is_empty():
		return _rejection("invalid_request_id", "A request ID is required.")
	var signature := _signature(intent)
	if request_records.has(request_id):
		var prior: Dictionary = request_records[request_id]
		if str(prior.signature) != signature:
			return _rejection(
				"request_id_reused", "That request ID already has a different payload."
			)
		return (prior.result as Dictionary).duplicate(true)
	if registered_seat < 0 or not occupied_seats.has(registered_seat):
		return _rejection("seat_unregistered", "The input seat is no longer registered.")
	if str(intent.get("attempt_id", "")) != attempt_id:
		return _rejection("stale_attempt", "This request belongs to a closed round attempt.")
	if int(intent.get("match_id", -1)) != match_id or int(intent.get("round_id", -1)) != round_id:
		return _rejection("stale_round", "This request belongs to a different round.")
	var count := int(unique_counts.get(registered_seat, 0))
	if count >= MAX_PER_SEAT_PER_ATTEMPT:
		return _rejection("request_limit", "This seat has used all eight placement requests.")
	if pending_by_seat.has(registered_seat):
		return _rejection("request_pending", "Wait for the current placement request to resolve.")
	var boundary_count := 0
	for entry in pending:
		if int(entry.boundary) == boundary:
			boundary_count += 1
	if boundary_count >= MAX_PER_BOUNDARY:
		return _rejection("boundary_full", "The placement queue is full for this simulation step.")
	sequence += 1
	var request_record = REQUEST_RECORD.from_intent(intent)
	var host_receipt = RECEIPT_RECORD.new()
	host_receipt.configure(
		request_record, registered_seat, receipt_usec, boundary, sequence, occupied_seats
	)
	var receipt := {
		"request_id": request_id,
		"seat_index": registered_seat,
		"intent": request_record.to_dictionary(),
		"request_record": request_record,
		"host_receipt": host_receipt,
		"receipt_usec": receipt_usec,
		"boundary": boundary,
		"sequence": sequence,
		"occupied_seats": occupied_seats.duplicate(),
		"signature": signature,
	}
	var pending_result := {
		"status": "pending",
		"code": "queued",
		"reason": "Placement queued for the next authority boundary.",
		"request_id": request_id,
		"seat_index": registered_seat,
		"receipt_usec": receipt_usec,
		"boundary": boundary,
		"sequence": sequence,
		"stage_version": stage_version,
	}
	var pending_record = RESULT_RECORD.new()
	pending_record.configure(pending_result)
	request_records[request_id] = {
		"signature": signature,
		"request": request_record,
		"receipt": host_receipt,
		"result_record": pending_record,
		"result": pending_result,
	}
	pending.append(receipt)
	pending_by_seat[registered_seat] = request_id
	unique_counts[registered_seat] = count + 1
	return pending_result.duplicate(true)


func drain_boundary(boundary: int, active_round: int) -> Array[Dictionary]:
	var ready: Array[Dictionary] = []
	for entry in pending:
		if int(entry.boundary) <= boundary:
			ready.append(entry)
	ready.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			if int(a.receipt_usec) != int(b.receipt_usec):
				return int(a.receipt_usec) < int(b.receipt_usec)
			if int(a.seat_index) != int(b.seat_index):
				var seats: Array = a.occupied_seats
				seats.sort()
				var pivot := posmod(active_round, maxi(1, seats.size()))
				var a_rank := posmod(seats.find(int(a.seat_index)) - pivot, maxi(1, seats.size()))
				var b_rank := posmod(seats.find(int(b.seat_index)) - pivot, maxi(1, seats.size()))
				return a_rank < b_rank
			return int(a.sequence) < int(b.sequence)
	)
	for entry in ready:
		pending.erase(entry)
		pending_by_seat.erase(int(entry.seat_index))
	return ready


func resolve_result(request_id: String, result: Dictionary) -> void:
	if not request_records.has(request_id):
		return
	var record: Dictionary = request_records[request_id]
	var result_record = RESULT_RECORD.new()
	result_record.configure(result)
	record.result_record = result_record
	record.result = result_record.to_dictionary()
	request_records[request_id] = record


func cached_result(request_id: String) -> Dictionary:
	if not request_records.has(request_id):
		return {}
	var record: Dictionary = request_records[request_id]
	var result_record = record.get("result_record")
	return (
		result_record.to_dictionary()
		if result_record != null
		else (record.result as Dictionary).duplicate(true)
	)


func pending_requests() -> Array[Dictionary]:
	return pending.duplicate()


## Removes one seat's queued request and returns the removed receipts. The request record stays so
## an exact retry still finds its result.
func close_attempt() -> void:
	pending.clear()
	pending_by_seat.clear()
	request_records.clear()
	unique_counts.clear()
	attempt_id = ""


func _signature(intent: Dictionary) -> String:
	var cell: Vector2i = intent.get("cell", Vector2i.ZERO)
	return (
		"%s|%d|%d|%s|%s|%d,%d|%d|%d"
		% [
			str(intent.get("attempt_id", "")),
			int(intent.get("match_id", -1)),
			int(intent.get("round_id", -1)),
			str(intent.get("variant_key", "")),
			str(intent.get("objective", "")),
			cell.x,
			cell.y,
			int(intent.get("quarter_turns", 0)),
			int(intent.get("observed_stage_version", -1)),
		]
	)


func _rejection(code: String, reason: String) -> Dictionary:
	return {"status": "rejected", "code": code, "reason": reason}

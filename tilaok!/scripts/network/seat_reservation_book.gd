class_name SeatReservationBook
extends RefCounted

## Host-side identities, reclaim tokens and 60 s seat reservations (contract v1.5, NLB-P08).
## Memory only: nothing here is written to disk, logged or echoed, and the whole book is cleared
## when the session stops. The Player ID and token are host-assigned random 128-bit values; the
## token is bound to its Player ID and seat and rotates after every successful reclaim.
const GRACE_MS := 60000
const MAX_ENTRIES := 4

## seat -> {player_id, token, reserved, deadline_ms, expired, committed_round, pending_peer}
var _entries: Dictionary = {}


func clear() -> void:
	_entries.clear()


## Called when a seat is assigned in the lobby. Returns {player_id, token} for the assignment.
func issue(seat: int) -> Dictionary:
	if seat < 0 or seat >= MAX_ENTRIES:
		return {}
	var crypto := Crypto.new()
	var entry := {
		"player_id": crypto.generate_random_bytes(16),
		"token": crypto.generate_random_bytes(16),
		"reserved": false,
		"deadline_ms": 0,
		"expired": false,
		"committed_round": -1,
		"pending_peer": -1,
	}
	_entries[seat] = entry
	return {"player_id": entry.player_id.duplicate(), "token": entry.token.duplicate()}


func forget(seat: int) -> void:
	_entries.erase(seat)


## NLB-P09 replay re-key: the seat keeps its Player ID, its token is revoked and replaced, and every
## reservation, claim and per-round commit mark is cleared for the new match identity.
func rekey(seat: int) -> Dictionary:
	if not _entries.has(seat):
		return {}
	var entry: Dictionary = _entries[seat]
	entry.token = Crypto.new().generate_random_bytes(16)
	entry.reserved = false
	entry.deadline_ms = 0
	entry.expired = false
	entry.committed_round = -1
	entry.pending_peer = -1
	_entries[seat] = entry
	return {"player_id": entry.player_id.duplicate(), "token": entry.token.duplicate()}


## NLB-P09: seats that are not part of the next match lose their identity entry.
func retain_only(seats: Array) -> void:
	for seat in _entries.keys():
		if not seats.has(int(seat)):
			_entries.erase(seat)


## NLB-P09 explicit leave: a deliberate Leave is not a lost connection. The seat is reserved with its
## grace already over (so the one disconnect elimination commits at the next safe boundary) and its
## token is replaced by one nobody holds, so the identity can never be reclaimed.
func forfeit(seat: int, now_ms: int) -> bool:
	if not _entries.has(seat):
		return false
	var entry: Dictionary = _entries[seat]
	entry.token = Crypto.new().generate_random_bytes(16)
	entry.reserved = true
	entry.deadline_ms = now_ms
	entry.expired = false
	entry.pending_peer = -1
	_entries[seat] = entry
	return true


func has_entry(seat: int) -> bool:
	return _entries.has(seat)


func entry_count() -> int:
	return _entries.size()


func player_id_of(seat: int) -> PackedByteArray:
	return (_entries[seat].player_id as PackedByteArray).duplicate() if _entries.has(seat) else PackedByteArray()


## Seat holding this Player ID, or -1. A Player ID is a lookup key only, never authority.
func seat_for_player(player_id: PackedByteArray) -> int:
	if player_id.size() != 16:
		return -1
	for seat in _entries.keys():
		if (_entries[seat].player_id as PackedByteArray) == player_id:
			return int(seat)
	return -1


## Reserves the seat for GRACE_MS from `now_ms`. Idempotent for an already reserved seat.
func reserve(seat: int, now_ms: int) -> bool:
	if not _entries.has(seat):
		return false
	var entry: Dictionary = _entries[seat]
	if bool(entry.reserved):
		return true
	entry.reserved = true
	entry.deadline_ms = now_ms + GRACE_MS
	entry.expired = false
	entry.pending_peer = -1
	_entries[seat] = entry
	return true


func is_reserved(seat: int) -> bool:
	return _entries.has(seat) and bool(_entries[seat].reserved)


func is_expired(seat: int) -> bool:
	return is_reserved(seat) and bool(_entries[seat].expired)


func reserved_seats() -> Array[int]:
	var result: Array[int] = []
	for seat in _entries.keys():
		if bool(_entries[seat].reserved):
			result.append(int(seat))
	result.sort()
	return result


func remaining_ms(seat: int, now_ms: int) -> int:
	if not is_reserved(seat) or bool(_entries[seat].expired):
		return 0
	return maxi(0, int(_entries[seat].deadline_ms) - now_ms)


## Seats whose grace ended since the last call. Each seat is reported once.
func take_expired(now_ms: int) -> Array[int]:
	var result: Array[int] = []
	for seat in _entries.keys():
		var entry: Dictionary = _entries[seat]
		if bool(entry.reserved) and not bool(entry.expired) and now_ms >= int(entry.deadline_ms):
			entry.expired = true
			_entries[seat] = entry
			result.append(int(seat))
	result.sort()
	return result


## True once per (seat, round): the host's single disconnect elimination for that round.
func claim_round_commit(seat: int, round_id: int) -> bool:
	if not _entries.has(seat) or int(_entries[seat].committed_round) == round_id:
		return false
	_entries[seat].committed_round = round_id
	return true


func committed_round(seat: int) -> int:
	return int(_entries[seat].committed_round) if _entries.has(seat) else -1


## The reclaim token keying the host's expected HMAC; empty unless the seat is reserved, so a
## stale or forged claim never reveals which part failed. The caller compares in constant time.
func token_for_proof(seat: int) -> PackedByteArray:
	if not is_reserved(seat):
		return PackedByteArray()
	return (_entries[seat].token as PackedByteArray).duplicate()


## At most one claim per seat is in flight; the first valid proof wins and the loser is refused.
func begin_claim(seat: int, peer_id: int) -> bool:
	if not is_reserved(seat):
		return false
	var entry: Dictionary = _entries[seat]
	var pending := int(entry.pending_peer)
	if pending >= 0 and pending != peer_id:
		return false
	entry.pending_peer = peer_id
	_entries[seat] = entry
	return true


func release_claim(seat: int, peer_id: int) -> void:
	if _entries.has(seat) and int(_entries[seat].pending_peer) == peer_id:
		_entries[seat].pending_peer = -1


## A verified reclaim rotates the token at once (the old one is revoked) so the peer can be told
## the new one. The seat stays reserved until the peer's snapshot is acknowledged and the seat is
## rebound (`finish_reclaim`); a peer lost in between simply leaves the reservation running.
func rotate_token(seat: int, peer_id: int) -> PackedByteArray:
	if not is_reserved(seat) or int(_entries[seat].pending_peer) != peer_id:
		return PackedByteArray()
	var entry: Dictionary = _entries[seat]
	entry.token = Crypto.new().generate_random_bytes(16)
	_entries[seat] = entry
	return (entry.token as PackedByteArray).duplicate()


func finish_reclaim(seat: int, peer_id: int) -> bool:
	if not is_reserved(seat) or int(_entries[seat].pending_peer) != peer_id:
		return false
	var entry: Dictionary = _entries[seat]
	entry.reserved = false
	entry.expired = false
	entry.deadline_ms = 0
	entry.pending_peer = -1
	_entries[seat] = entry
	return true

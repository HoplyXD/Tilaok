class_name BombTayaTwist
extends RefCounted

## P12-T05: Lagsanay as a Twist on a Karera Main ("KARERA / TWIST: BOMB-TAYA", GDD §3 stack
## table). The race keeps the flag, the deadlines, the round end and the scoring; this only adds
## the taya pressure, using the P08 timing rules:
## - One random opening taya, frozen for the opening head start; then the countdown runs.
## - Touch passes the taya to the nearest live runner (lowest seat on an exact tie); the old taya
##   gets pass-back immunity. Passing never resets the countdown.
## - When the countdown expires the taya is eliminated by timeout (an event elimination: no
##   Patibong). The room reports it to the race ledger in the same physics step.
## - Runners who finished are secured: never taya, never a pass target.
## - If the taya finishes, the taya moves at once to a random live runner, keeping the remaining
##   countdown and with no new opening freeze. If the taya is eliminated (timeout or trap), a
##   random live runner becomes taya with the timer for the new live count.
## - With no live runner left the Twist idles; the race decides when the round ends.
## Only the room decides who is live (not finished, not eliminated) at the start of each step.

const EVENT_TIME_EPSILON := 0.000001

var round_id := ""
var seat_indices: Array[int] = []
var rng: RandomNumberGenerator
var active := false
var taya_seat := -1
var opening_taya_seat := -1
var head_start_remaining := 0.0
var countdown_seconds := 0.0
var countdown_remaining := 0.0
var pass_back_seconds := 1.0
var simulation_clock := 0.0
var timeout_seconds_by_alive: Dictionary = {}
var pass_back_immunity_until: Dictionary = {}
## Seats this Twist eliminated by timeout, in order: [{seat_index, physics_tick, physics_time}].
var timeouts: Array[Dictionary] = []
## Every taya change after the opening: [{from, to, reason, countdown_remaining}].
var transfers: Array[Dictionary] = []


func begin(
	new_round_id: String,
	seats: Array[int],
	gameplay_rng: RandomNumberGenerator,
	head_start_seconds: float,
	pass_back_immunity_seconds: float,
	timeout_2p: float,
	timeout_3p: float,
	timeout_4p: float
) -> bool:
	reset()
	if (
		new_round_id.is_empty()
		or seats.size() < 2
		or seats.size() > 4
		or gameplay_rng == null
		or head_start_seconds <= 0.0
		or pass_back_immunity_seconds < 0.0
		or timeout_2p <= 0.0
		or timeout_3p <= 0.0
		or timeout_4p <= 0.0
	):
		return false
	seat_indices = seats.duplicate()
	seat_indices.sort()
	round_id = new_round_id
	rng = gameplay_rng
	head_start_remaining = head_start_seconds
	pass_back_seconds = pass_back_immunity_seconds
	# One live runner left keeps the shortest (2-player) timer: provisional, see P12-T03 draft.
	timeout_seconds_by_alive = {1: timeout_2p, 2: timeout_2p, 3: timeout_3p, 4: timeout_4p}
	taya_seat = seat_indices[rng.randi_range(0, seat_indices.size() - 1)]
	opening_taya_seat = taya_seat
	countdown_seconds = _timer_for_alive(seat_indices.size())
	countdown_remaining = countdown_seconds
	active = true
	return true


func reset() -> void:
	round_id = ""
	seat_indices.clear()
	active = false
	taya_seat = -1
	opening_taya_seat = -1
	head_start_remaining = 0.0
	countdown_seconds = 0.0
	countdown_remaining = 0.0
	simulation_clock = 0.0
	pass_back_immunity_until.clear()
	timeouts.clear()
	transfers.clear()


func pass_back_remaining_seconds(seat: int) -> float:
	return maxf(0.0, float(pass_back_immunity_until.get(seat, simulation_clock)) - simulation_clock)


## One physics step. `live` = runners still in the race at the start of this step; `finished` =
## runners who reached the flag. `tag_contacts` = the taya's frozen contacts this step
## [{seat_index, distance_squared}]. Returns {head_start_ended, timeout_seat, timeout_time,
## taya_changed, tagged, idle}.
func advance_step(
	delta: float,
	physics_tick: int,
	live: Array[int],
	finished: Array[int],
	tag_contacts: Array[Dictionary]
) -> Dictionary:
	var result := {
		"head_start_ended": false,
		"timeout_seat": -1,
		"timeout_time": -1.0,
		"taya_changed": false,
		"tagged": false,
		"idle": not active,
	}
	if not active or delta <= 0.0:
		return result
	var runners := _sorted(live)
	if not runners.has(taya_seat):
		if runners.is_empty():
			_go_idle()
			result.idle = true
			return result
		var reason := "taya_finished" if finished.has(taya_seat) else "taya_out"
		var keep_countdown := reason == "taya_finished"
		_assign_new_taya(runners, reason, keep_countdown)
		result.taya_changed = true
	var tick_start := simulation_clock
	var tick_end := tick_start + delta
	simulation_clock = tick_end
	var was_opening := head_start_remaining > 0.0
	var opening_step := minf(delta, head_start_remaining)
	head_start_remaining = maxf(0.0, head_start_remaining - delta)
	result.head_start_ended = was_opening and head_start_remaining <= 0.0
	var timer_step := maxf(0.0, delta - opening_step)
	if timer_step > 0.0 and countdown_remaining <= timer_step + EVENT_TIME_EPSILON:
		var expiry_time := tick_start + opening_step + countdown_remaining
		countdown_remaining = 0.0
		var expired := taya_seat
		timeouts.append(
			{"seat_index": expired, "physics_tick": physics_tick, "physics_time": expiry_time}
		)
		result.timeout_seat = expired
		result.timeout_time = expiry_time
		# The timed-out runner leaves this step; the next taya gets the new live count's timer.
		var remaining := runners.duplicate()
		remaining.erase(expired)
		if remaining.is_empty():
			_go_idle()
			result.idle = true
		else:
			_assign_new_taya(remaining, "timeout", false)
			result.taya_changed = true
		return result
	countdown_remaining = maxf(0.0, countdown_remaining - timer_step)
	# An expiry step has priority over contact (contact has no sub-step time), as in P08.
	if was_opening or tag_contacts.is_empty():
		return result
	var receiver := _nearest_eligible(tag_contacts, runners, tick_end)
	if receiver >= 0:
		pass_back_immunity_until[taya_seat] = tick_end + pass_back_seconds
		(
			transfers
			. append(
				{
					"from": taya_seat,
					"to": receiver,
					"reason": "tag",
					"countdown_remaining": countdown_remaining,
				}
			)
		)
		taya_seat = receiver
		result.tagged = true
		result.taya_changed = true
	return result


func _assign_new_taya(runners: Array[int], reason: String, keep_countdown: bool) -> void:
	var previous := taya_seat
	taya_seat = runners[rng.randi_range(0, runners.size() - 1)]
	if not keep_countdown:
		countdown_seconds = _timer_for_alive(runners.size())
		countdown_remaining = countdown_seconds
	(
		transfers
		. append(
			{
				"from": previous,
				"to": taya_seat,
				"reason": reason,
				"countdown_remaining": countdown_remaining,
			}
		)
	)


func _go_idle() -> void:
	active = false
	taya_seat = -1


func _nearest_eligible(tag_contacts: Array[Dictionary], runners: Array[int], at_time: float) -> int:
	var best_seat := -1
	var best_distance := INF
	for contact in tag_contacts:
		var seat := int(contact.get("seat_index", -1))
		if (
			seat == taya_seat
			or not runners.has(seat)
			or float(pass_back_immunity_until.get(seat, -1.0)) > at_time
		):
			continue
		var distance := float(contact.get("distance_squared", INF))
		if distance < best_distance or (distance == best_distance and seat < best_seat):
			best_distance = distance
			best_seat = seat
	return best_seat


func _timer_for_alive(alive_count: int) -> float:
	return float(timeout_seconds_by_alive.get(clampi(alive_count, 1, 4), 0.0))


func _sorted(seats: Array[int]) -> Array[int]:
	var result: Array[int] = []
	for seat in seats:
		if seat_indices.has(seat) and not result.has(seat):
			result.append(seat)
	result.sort()
	return result

class_name NlbFaultInjector
extends RefCounted
## NLB-P11: development-only fault injection inside the production transport path.
##
## RawEnetTransport owns one of these (when enabled) and runs every outgoing packet and every
## incoming packet through `filter()`, so the real session code, the real ENet sockets and the
## real validation see the faults. It is deterministic by seed. It is never created in a release or
## Android client build (`from_args` returns null there) and announces itself in the log.
##
## Flag: `--nlb-fault=loss=5,jitter=30,delay=20,reorder=5,duplicate=2,seed=7` (user args).
## - loss: percent of packets dropped, ONLY on the unreliable input/state channels (1 and 2).
##   ENet's reliable channel 0 would retransmit a real loss; dropping before ENet would fake a
##   transport guarantee, so channel 0 is never dropped.
## - delay: fixed milliseconds added to every packet. jitter: extra 0..N ms, uniformly random.
## - reorder: percent of packets held an extra 20..80 ms so later packets overtake them.
## - duplicate: percent of packets delivered twice.

const FLAG_PREFIX := "--nlb-fault="
const OUTGOING := 0
const INCOMING := 1
const MAX_QUEUED := 512
const MAX_PERCENT := 100
const MAX_DELAY_MS := 2000
const REORDER_EXTRA_MIN_MS := 20
const REORDER_EXTRA_MAX_MS := 80
const LOG_INTERVAL_MS := 60000
const UNRELIABLE_CHANNELS := [1, 2]

var loss_percent := 0
var jitter_ms := 0
var delay_ms := 0
var reorder_percent := 0
var duplicate_percent := 0
var seed_value := 1

var dropped := 0
var delayed := 0
var duplicated := 0
var reordered := 0
var overflow_dropped := 0

var _rng := RandomNumberGenerator.new()
var _queue: Array[Dictionary] = []
var _last_log_ms := -LOG_INTERVAL_MS


## The injector requested on the command line, or null when absent or not allowed (release and
## Android client builds ignore the flag). `arguments` is injectable for tests.
static func from_args(arguments: PackedStringArray, allowed: bool = true) -> NlbFaultInjector:
	if not allowed:
		return null
	var spec := NlbBuildFlags.value_from_args(arguments, FLAG_PREFIX)
	if spec.is_empty():
		return null
	var injector := NlbFaultInjector.new()
	if not injector.configure(spec):
		push_warning("NLB_FAULT_REJECTED: unreadable --nlb-fault specification; injection stays off")
		return null
	return injector


static func from_cmdline() -> NlbFaultInjector:
	return from_args(OS.get_cmdline_user_args(), NlbBuildFlags.dev_flags_allowed())


## Parses "key=int,key=int". Unknown keys or out-of-range values reject the whole spec.
func configure(spec: String) -> bool:
	for part in spec.split(",", false):
		var pair := part.split("=")
		if pair.size() != 2 or not pair[1].is_valid_int():
			return false
		var value := int(pair[1])
		match pair[0]:
			"loss":
				if value < 0 or value > MAX_PERCENT:
					return false
				loss_percent = value
			"reorder":
				if value < 0 or value > MAX_PERCENT:
					return false
				reorder_percent = value
			"duplicate":
				if value < 0 or value > MAX_PERCENT:
					return false
				duplicate_percent = value
			"jitter":
				if value < 0 or value > MAX_DELAY_MS:
					return false
				jitter_ms = value
			"delay":
				if value < 0 or value > MAX_DELAY_MS:
					return false
				delay_ms = value
			"seed":
				if value < 0:
					return false
				seed_value = value
			_:
				return false
	_rng.seed = seed_value
	return true


func is_active() -> bool:
	return (
		loss_percent > 0
		or jitter_ms > 0
		or delay_ms > 0
		or reorder_percent > 0
		or duplicate_percent > 0
	)


func describe() -> String:
	return (
		"loss=%d jitter=%d delay=%d reorder=%d duplicate=%d seed=%d"
		% [loss_percent, jitter_ms, delay_ms, reorder_percent, duplicate_percent, seed_value]
	)


## One log line at start and then at most once per minute; never carries packet contents.
func announce(now_ms: int, force: bool = false) -> void:
	if not force and now_ms - _last_log_ms < LOG_INTERVAL_MS:
		return
	_last_log_ms = now_ms
	print(
		"NLB_FAULT_ACTIVE %s dropped=%d delayed=%d duplicated=%d reordered=%d queue=%d"
		% [describe(), dropped, delayed, duplicated, reordered, _queue.size()]
	)


## Runs one packet through the faults. Returns the deliveries to make: zero (dropped), one, or
## two (duplicated) entries of {direction, peer_id, channel, packet, due_ms}. Entries whose
## due_ms is not in the future are delivered by the caller immediately; the others are handed
## back later by `pop_due()`.
func filter(
	direction: int, peer_id: int, channel: int, packet: PackedByteArray, now_ms: int
) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if UNRELIABLE_CHANNELS.has(channel) and _roll(loss_percent):
		dropped += 1
		return result
	var copies := 2 if _roll(duplicate_percent) else 1
	if copies == 2:
		duplicated += 1
	for copy_index in copies:
		var wait := delay_ms
		if jitter_ms > 0:
			wait += _rng.randi_range(0, jitter_ms)
		if _roll(reorder_percent):
			wait += _rng.randi_range(REORDER_EXTRA_MIN_MS, REORDER_EXTRA_MAX_MS)
			reordered += 1
		if wait > 0:
			delayed += 1
		result.append(
			{
				"direction": direction,
				"peer_id": peer_id,
				"channel": channel,
				"packet": packet,
				"due_ms": now_ms + wait,
			}
		)
	return result


## Queues a future delivery. A full queue drops the newest entry (bounded, counted).
func hold(entry: Dictionary) -> void:
	if _queue.size() >= MAX_QUEUED:
		overflow_dropped += 1
		return
	_queue.append(entry)


## Removes and returns every held entry due at `now_ms`, oldest due time first.
func pop_due(now_ms: int) -> Array[Dictionary]:
	var due: Array[Dictionary] = []
	var keep: Array[Dictionary] = []
	for entry in _queue:
		if int(entry.due_ms) <= now_ms:
			due.append(entry)
		else:
			keep.append(entry)
	_queue = keep
	due.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.due_ms) < int(b.due_ms))
	return due


func queued_count() -> int:
	return _queue.size()


func clear() -> void:
	_queue.clear()


func _roll(percent: int) -> bool:
	return percent > 0 and _rng.randi_range(1, 100) <= percent

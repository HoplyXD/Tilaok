class_name EventSchedule
extends RefCounted

## P12-T01 event schedule (GDD §3 "Event cadence and stacking", PRD REQ-EVENT-001).
## Round 1 is Karera and rounds 4/8/12 are standalone Lagsanay. Every other round draws its Main
## Challenge from the available pool (Karera 70, Lagsanay 20, Kangaroo 10, with unavailable modes
## zeroed before normalizing) and, from round 5, may roll one compatible Twist. Each round is
## locked once, in order, from the match's seeded event stream: the room locks round N+1 during
## round N's Pugad, so the announcement and the round that plays always agree.

enum Challenge { NONE = -1, KARERA, LAGSANAY, KANGAROO }

const MAIN_WEIGHTS := {Challenge.KARERA: 70, Challenge.LAGSANAY: 20, Challenge.KANGAROO: 10}
const GUARANTEED := {
	1: Challenge.KARERA,
	4: Challenge.LAGSANAY,
	8: Challenge.LAGSANAY,
	12: Challenge.LAGSANAY,
}
## The GDD's compatible stacks. A row enters the Twist pool only after its pair is integrated and
## verified (the listed P12 task); until then `enabled` stays false and no Twist is rolled for it.
## Karera + Lagsanay (Bomb-Taya) passed P12-T05/T06 on 2026-10-15.
const COMPATIBILITY: Array[Dictionary] = [
	{"main": Challenge.KARERA, "twist": Challenge.LAGSANAY, "task": "P12-T05", "enabled": true},
	{"main": Challenge.KARERA, "twist": Challenge.KANGAROO, "task": "P12-T07", "enabled": false},
	{"main": Challenge.KANGAROO, "twist": Challenge.LAGSANAY, "task": "P12-T09", "enabled": false},
]

var available: Array[int] = []
var pairs: Array[Dictionary] = []
var round_limit := 12
var locked: Dictionary = {}
var error := ""

var _stream: RandomNumberGenerator


## The compatibility rows currently allowed into the Twist pool.
static func enabled_pairs() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for row in COMPATIBILITY:
		if bool(row.enabled):
			result.append(row.duplicate())
	return result


static func twist_chance(round_number: int) -> float:
	if round_number <= 4:
		return 0.0
	if round_number <= 7:
		return 0.10
	if round_number <= 10:
		return 0.20
	return 0.30


static func main_name(challenge: int) -> String:
	match challenge:
		Challenge.KARERA:
			return "KARERA"
		Challenge.LAGSANAY:
			return "LAGSANAY"
		Challenge.KANGAROO:
			return "KANGAROO"
	return ""


## Lagsanay runs as "Bomb-Taya" when it is the Twist (GDD: "KARERA / TWIST: BOMB-TAYA").
static func twist_name(challenge: int) -> String:
	if challenge == Challenge.LAGSANAY:
		return "BOMB-TAYA"
	return main_name(challenge)


## Sudden death is always standalone Lagsanay and never takes a Twist.
static func sudden_death_entry() -> Dictionary:
	return {
		"round": -1,
		"main": Challenge.LAGSANAY,
		"twist": Challenge.NONE,
		"guaranteed": true,
		"sudden_death": true,
	}


## Validates the pool and prepares an empty schedule. Returns "" or a configuration error: a
## missing required mode refuses the match instead of silently rescheduling it as Karera.
func begin(
	stream: RandomNumberGenerator,
	available_modes: Array[int],
	limit: int,
	compatible_pairs: Array[Dictionary] = enabled_pairs()
) -> String:
	_stream = stream
	available = available_modes.duplicate()
	pairs = compatible_pairs.duplicate(true)
	round_limit = limit
	locked.clear()
	error = _validate()
	return error


func _validate() -> String:
	if _stream == null:
		return "Event schedule has no seeded event stream."
	if round_limit <= 0:
		return "Event schedule needs a positive round limit."
	for round_number in GUARANTEED:
		var required := int(GUARANTEED[round_number])
		if int(round_number) <= round_limit and not available.has(required):
			return (
				"Event schedule refused: round %d requires %s, which is not available."
				% [int(round_number), main_name(required)]
			)
	if not available.has(Challenge.LAGSANAY):
		return "Event schedule refused: sudden death requires LAGSANAY, which is not available."
	if _main_pool_weight() <= 0:
		return "Event schedule refused: the Main Challenge pool is empty."
	return ""


## Locks (once) and returns a round's entry. Earlier rounds are locked first, so the result
## depends only on the seed and the pool, never on which round the caller asks about first.
func lock_round(round_number: int) -> Dictionary:
	if not error.is_empty() or _stream == null or round_number < 1 or round_number > round_limit:
		return {}
	if locked.has(round_number):
		return locked[round_number]
	if round_number > 1 and not locked.has(round_number - 1):
		lock_round(round_number - 1)
	var entry := {
		"round": round_number,
		"main": Challenge.NONE,
		"twist": Challenge.NONE,
		"guaranteed": GUARANTEED.has(round_number),
		"sudden_death": false,
		"twist_options": 0,
	}
	if bool(entry.guaranteed):
		entry.main = int(GUARANTEED[round_number])
	else:
		entry.main = _draw_main()
		var options := twist_options(int(entry.main))
		entry.twist_options = options.size()
		if _stream.randf() < twist_chance(round_number) and not options.is_empty():
			entry.twist = options[_stream.randi_range(0, options.size() - 1)]
	locked[round_number] = entry
	return entry


## Entry for an already-locked round, or {} if it has not been locked yet.
func entry_for(round_number: int) -> Dictionary:
	return locked.get(round_number, {})


## Twists that may stack on `main`: enabled compatibility rows whose modes are available.
## A challenge never stacks with itself.
func twist_options(main: int) -> Array[int]:
	var options: Array[int] = []
	for row in pairs:
		var twist := int(row.twist)
		if (
			int(row.main) == main
			and twist != main
			and available.has(twist)
			and not options.has(twist)
		):
			options.append(twist)
	options.sort()
	return options


## "KARERA" or "KARERA / TWIST: BOMB-TAYA" for logs and tests.
static func describe(entry: Dictionary) -> String:
	if entry.is_empty():
		return ""
	var text := main_name(int(entry.main))
	if int(entry.get("twist", Challenge.NONE)) != Challenge.NONE:
		text += " / TWIST: " + twist_name(int(entry.twist))
	return text


func _main_pool_weight() -> int:
	var total := 0
	for challenge in MAIN_WEIGHTS:
		if available.has(int(challenge)):
			total += int(MAIN_WEIGHTS[challenge])
	return total


func _draw_main() -> int:
	var total := _main_pool_weight()
	var pick := _stream.randi_range(0, total - 1)
	for challenge in [Challenge.KARERA, Challenge.LAGSANAY, Challenge.KANGAROO]:
		if not available.has(challenge):
			continue
		pick -= int(MAIN_WEIGHTS[challenge])
		if pick < 0:
			return challenge
	return Challenge.KARERA

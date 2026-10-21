# gdlint: disable=max-line-length,max-file-lines
extends SceneTree

## Focused NLB-P09 checks (contract v1.6): the wire constants and result codecs, exact eighth-point
## unit agreement from the offline calculators through the host ledger and the wire to the client
## model (race, suppression, Barya, Bawi, Patibong, Lagsanay placement, Last Cluck, disconnect), the
## once-only ledger and the client's dedupe/stale/gap/invalid rules, sudden death adding no score
## and no round 13, host-only refusals, the result vote and action, the in-place replay re-key
## (new epoch and match ID, retired-epoch quiet drop, ack gating, token rotation), session-end
## reasons, the deliberate-Leave forfeit and the teardown accounting.
## Transport-free: frames are fed to the manager handlers. Authored only; nothing here has run.
## Run: Godot --headless --fixed-fps 60 --path tilaok! --script res://tests/run_nlb_p09_tests.gd

const REMOTE_PEER := 51
const REMOTE_SOURCE := "peer_51"
const SECOND_PEER := 52
const GENERATION := 9
const TARGET := 80
const LIMIT := 12
const MUTATION_LABELS: PackedStringArray = [
	"unknown kind", "zero match", "event id over 128", "unknown scoring family",
	"unknown suppression", "unknown decision", "winner on a continue",
	"terminal reason on a continue", "one seat only", "duplicate seat", "seat out of range",
	"unknown cause", "unknown award key", "delta is not the award sum", "negative total",
	"owner out of range", "first mask outside the seats",
]

var checks := 0
var failures := 0


class CaptureManager:
	extends NetworkSessionManager

	var sent: Array[Dictionary] = []

	func _send(peer_id: int, family: int, payload: PackedByteArray) -> bool:
		sent.append({"peer": peer_id, "family": family, "payload": payload.duplicate(), "epoch": session_epoch})
		return true

	func _send_to_host(family: int, payload: PackedByteArray) -> bool:
		return _send(1, family, payload)


## A room with no scene: only the ledger, the phase controller and the vote/replay answers the
## session reads. Everything else the session never touches in these checks.
class StubRoom:
	extends P12ScheduledMatchRoom

	var roster := 2
	var votes: Array[Array] = []
	var vote_result := true

	func network_prepare_replay_roster() -> int:
		return roster

	func network_vote_state() -> Dictionary:
		return {
			"action": NetworkResultsCodec.ResultAction.CONTINUE,
			"ready_mask": 0,
			"required_mask": 3,
			"event_id": result_ledger.latest_event_id(),
			"round_id": result_ledger.latest_round_id(),
		}

	func network_result_vote(seat_index: int, action: int) -> bool:
		votes.append([seat_index, action])
		return vote_result

	func network_current_round_id() -> int:
		return 1


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_wire_constants()
	_test_results_codec()
	_test_lifecycle_codecs()
	_test_exact_unit_matches()
	_test_ledger_and_model_rules()
	_test_sudden_death_and_ending_rules()
	_test_reservation_and_registry_additions()
	await _test_host_results_flow()
	await _test_client_results_flow()
	await _test_replay_rekey()
	await _test_session_end_and_leave()
	await _test_teardown_counts()
	_test_offline_defaults_and_source_audit()
	print("NLB_P09_TESTS checks=%d failures=%d" % [checks, failures])
	await process_frame
	quit(1 if failures > 0 else 0)


# --- wire ------------------------------------------------------------------------------------


func _test_wire_constants() -> void:
	_check(NetworkFrame.MAJOR == 1 and NetworkFrame.MINOR == 2 and NetworkFrame.SCHEMA == 6, "envelope stays 1.2 and the schema is 6")
	_check(NetworkFrame.FEATURE_RESULTS == 0x0400 and NetworkFrame.FEATURE_P09_MASK == 0x07ff and NetworkFrame.FEATURE_REQUIRED_MASK == 0x07ff, "bit 10 is required: mask 0x07FF")
	_check((NetworkFrame.FEATURE_P08_MASK & NetworkFrame.FEATURE_RESULTS) == 0, "a P08 peer lacks the results bit and is refused at hello")
	for family in [NetworkFrame.Family.RESULT_EVENT, NetworkFrame.Family.RESULT_ACTION, NetworkFrame.Family.RESULT_VOTE, NetworkFrame.Family.REKEY, NetworkFrame.Family.REKEY_ACK]:
		_check(family in NetworkFrame.FAMILIES, "family 0x%02X is allowlisted" % family)
		_check(NetworkFrame.family_allowed_on_channel(family, RawEnetTransport.CONTROL_CHANNEL), "family 0x%02X uses reliable channel 0" % family)
		_check(not NetworkFrame.family_allowed_on_channel(family, RawEnetTransport.INPUT_CHANNEL), "family 0x%02X is refused on the input channel" % family)
		_check(not NetworkFrame.family_allowed_on_channel(family, RawEnetTransport.STATE_CHANNEL), "family 0x%02X is refused on the state channel" % family)
	_check(NetworkFrame.FAMILIES.size() == 38 and NetworkFrame.FAMILIES.max() == 0x26, "the allowlist ends at 0x26")
	_check(str(CompatibilityManifest.build().manifest.build) == BuildIdentity.BUILD_ID, "the manifest build ID is the current BuildIdentity build (P11 bump)")
	var frame := NetworkFrame.encode(NetworkFrame.Family.REKEY, 0x1122334455667788 & 0x7fffffffffffffff, 5, PackedByteArray([1]))
	_check(NetworkFrame.peek_epoch(frame) == (0x1122334455667788 & 0x7fffffffffffffff), "peek_epoch reads the envelope epoch")
	_check(NetworkFrame.peek_epoch(PackedByteArray([1, 2, 3])) == -1, "peek_epoch refuses a short frame")


func _test_results_codec() -> void:
	var round_entry := _sample_round_entry(1, 1, 3, 0)
	var payload := NetworkResultsCodec.encode_event(round_entry)
	var decoded := NetworkResultsCodec.decode_event(payload)
	_check(not payload.is_empty() and bool(decoded.get("ok", false)) and int(decoded.kind) == NetworkResultsCodec.Kind.ROUND, "a round entry round-trips")
	_check(payload.size() + NetworkFrame.HEADER_BYTES <= NetworkFrame.MAX_FRAME_BYTES, "a round entry fits one frame")
	_check(int(decoded.seats[0].delta) == 10 and int(decoded.seats[0].total) == 10 and decoded.seats[0].awards.size() == 2, "per-seat units and award segments survive the wire")
	# Largest legal entry: four seats, eight awards each.
	var largest := _sample_round_entry(1, 1, 3, 0)
	for seat in largest.seats:
		seat.awards = []
		var sum := 0
		for index in 8:
			seat.awards.append({"key": NetworkResultsCodec.AwardKey.PATIBONG, "units": 2})
			sum += 2
		seat.delta = sum
		seat.total = sum
	largest.seats.append({"seat": 2, "outcome": 2, "cause": 2, "owner": 0, "placement": 3, "delta": 16, "total": 16, "awards": _patibongs(8)})
	largest.seats.append({"seat": 3, "outcome": 2, "cause": 2, "owner": 0, "placement": 4, "delta": 16, "total": 16, "awards": _patibongs(8)})
	var largest_payload := NetworkResultsCodec.encode_event(largest)
	_check(not largest_payload.is_empty() and largest_payload.size() <= NetworkResultsCodec.MAX_EVENT_BYTES and largest_payload.size() + NetworkFrame.HEADER_BYTES <= NetworkFrame.MAX_FRAME_BYTES, "four seats of eight awards stay inside one 900-byte frame (%d bytes)" % largest_payload.size())
	var too_many := largest.duplicate(true)
	too_many.seats[0].awards.append({"key": NetworkResultsCodec.AwardKey.UNA, "units": 0})
	_check(NetworkResultsCodec.encode_event(too_many).is_empty(), "nine awards cannot be encoded")
	# Every invalid field is refused on encode and on decode.
	for label in MUTATION_LABELS:
		var mutated := _sample_round_entry(1, 1, 3, 0)
		_mutate_entry(mutated, label)
		_check(NetworkResultsCodec.encode_event(mutated).is_empty(), "an entry with %s is refused on encode" % label)
	_check(not bool(NetworkResultsCodec.decode_event(payload.slice(0, payload.size() - 1)).get("ok", true)), "a truncated entry is refused")
	var trailing := payload.duplicate()
	trailing.append(0)
	_check(not bool(NetworkResultsCodec.decode_event(trailing).get("ok", true)), "trailing bytes are refused")
	var bad_kind := payload.duplicate()
	bad_kind[0] = 9
	_check(not bool(NetworkResultsCodec.decode_event(bad_kind).get("ok", true)), "an unknown kind byte is refused on decode")
	var bad_enum := payload.duplicate()
	bad_enum[NetworkResultsCodec.COMMON_BYTES] = 9 # scoring family
	_check(not bool(NetworkResultsCodec.decode_event(bad_enum).get("ok", true)), "an unknown family byte is refused on decode")
	# Sudden-death entry/result and final.
	var sd := {"kind": 2, "match_id": 1, "round_id": 12, "attempt_id": 1, "event_id": 2, "revision": 2, "tied_mask": 3, "sd_attempt": 1, "terminal_reason": 2, "seats": [{"seat": 0, "total": 40}, {"seat": 1, "total": 40}]}
	_check(bool(NetworkResultsCodec.decode_event(NetworkResultsCodec.encode_event(sd)).get("ok", false)), "a sudden-death entry round-trips")
	var sd_result := {"kind": 3, "match_id": 1, "round_id": 12, "attempt_id": 1, "event_id": 3, "revision": 3, "winner_seat": 1, "last_cluck": 1, "sd_attempt": 1}
	var sd_decoded := NetworkResultsCodec.decode_event(NetworkResultsCodec.encode_event(sd_result))
	_check(bool(sd_decoded.get("ok", false)) and int(sd_decoded.winner_seat) == 1 and int(sd_decoded.last_cluck) == 1, "a sudden-death result round-trips")
	var final_entry := {"kind": 4, "match_id": 1, "round_id": 12, "attempt_id": 1, "event_id": 4, "revision": 4, "winner_seat": 1, "last_cluck": 0, "sudden_death": 1, "terminal_reason": 2, "seats": [{"seat": 0, "total": 40}, {"seat": 1, "total": 40}]}
	_check(bool(NetworkResultsCodec.decode_event(NetworkResultsCodec.encode_event(final_entry)).get("ok", false)), "a final entry round-trips")
	# Action and vote.
	var action := NetworkResultsCodec.encode_action({"request_id": 5, "match_id": 2, "round_id": 3, "attempt_id": 2, "event_id": 4, "action": NetworkResultsCodec.ResultAction.VOTE_REPLAY})
	_check(action.size() == NetworkResultsCodec.ACTION_BYTES and bool(NetworkResultsCodec.decode_action(action).get("ok", false)), "a result action is exactly 27 bytes and round-trips")
	_check(NetworkResultsCodec.encode_action({"request_id": 0, "match_id": 2, "round_id": 3, "attempt_id": 2, "event_id": 4, "action": 1}).is_empty(), "request id 0 cannot be encoded")
	_check(NetworkResultsCodec.encode_action({"request_id": 1, "match_id": 2, "round_id": 3, "attempt_id": 2, "event_id": 4, "action": 4}).is_empty(), "an unknown result action cannot be encoded")
	var bad_action := action.duplicate()
	bad_action[26] = 9
	_check(not bool(NetworkResultsCodec.decode_action(bad_action).get("ok", true)), "an unknown action byte is refused")
	var vote := NetworkResultsCodec.encode_vote({"match_id": 2, "round_id": 3, "event_id": 4, "vote_seq": 1, "action": 2, "ready_mask": 1, "required_mask": 3})
	_check(vote.size() == NetworkResultsCodec.VOTE_BYTES and bool(NetworkResultsCodec.decode_vote(vote).get("ok", false)), "a vote is exactly 23 bytes and round-trips")
	_check(NetworkResultsCodec.encode_vote({"match_id": 2, "round_id": 3, "event_id": 4, "vote_seq": 1, "action": 2, "ready_mask": 4, "required_mask": 3}).is_empty(), "a ready seat outside the required set is refused")
	_check(NetworkResultsCodec.encode_vote({"match_id": 2, "round_id": 3, "event_id": 4, "vote_seq": 1, "action": 0, "ready_mask": 0, "required_mask": 3}).is_empty(), "action 0 is not a vote")
	_check(bool(NetworkResultsCodec.decode_vote(NetworkResultsCodec.encode_vote({"match_id": 2, "round_id": 3, "event_id": 4, "vote_seq": 1, "action": -1, "ready_mask": 0, "required_mask": 3})).get("ok", false)), "no selected action (-1) is a valid vote state")


func _test_lifecycle_codecs() -> void:
	var token := PackedByteArray()
	token.resize(16)
	token.fill(7)
	var rekey := NetworkLifecycleCodec.encode_rekey(0x1234, 5, NetworkSessionManager.ROUTE_LIVE_BUILD, NetworkLifecycleCodec.REKEY_FLAG_UNVERIFIED, token)
	var decoded := NetworkLifecycleCodec.decode_rekey(rekey)
	_check(rekey.size() == NetworkLifecycleCodec.REKEY_BYTES and bool(decoded.get("ok", false)) and int(decoded.new_match_id) == 5 and decoded.token == token, "a re-key is exactly 34 bytes and round-trips with its token")
	_check(NetworkLifecycleCodec.encode_rekey(0, 5, 0, 0, token).is_empty() and NetworkLifecycleCodec.encode_rekey(1, 0, 0, 0, token).is_empty(), "a re-key needs a non-zero epoch and match ID")
	_check(NetworkLifecycleCodec.encode_rekey(1, 5, 0, 2, token).is_empty(), "an unknown re-key flag cannot be encoded")
	_check(not bool(NetworkLifecycleCodec.decode_rekey(rekey.slice(0, 33)).get("ok", true)), "a short re-key is refused")
	var ack := NetworkLifecycleCodec.encode_rekey_ack(0x1234, 9)
	_check(ack.size() == NetworkLifecycleCodec.REKEY_ACK_BYTES and int(NetworkLifecycleCodec.decode_rekey_ack(ack).new_epoch) == 0x1234, "a re-key ack is exactly 12 bytes and round-trips")
	var close := NetworkLifecycleCodec.encode_session_close_host(NetworkFrame.Reason.SESSION_CLOSED, NetworkLifecycleCodec.SessionEnd.LOBBY_RETURN, 7, 900)
	var close_decoded := NetworkLifecycleCodec.decode_session_close_host(close)
	_check(close.size() == NetworkLifecycleCodec.SESSION_CLOSE_HOST_BYTES and bool(close_decoded.ok) and int(close_decoded.end) == NetworkLifecycleCodec.SessionEnd.LOBBY_RETURN and int(close_decoded.ledger_revision) == 7, "the host SESSION_CLOSE is 11 bytes and carries the end reason")
	for malformed in [PackedByteArray(), PackedByteArray([1, 2]), PackedByteArray([1, 2, 3]), close.slice(0, 10), close + PackedByteArray([0])]:
		var fallback := NetworkLifecycleCodec.decode_session_close_host(malformed)
		_check(not bool(fallback.ok) and int(fallback.end) == NetworkLifecycleCodec.SessionEnd.HOST_LOST, "a malformed close notice ends the session as HOST_LOST")
	var bad_end := close.duplicate()
	bad_end[2] = 77
	_check(int(NetworkLifecycleCodec.decode_session_close_host(bad_end).end) == NetworkLifecycleCodec.SessionEnd.HOST_LOST, "an unknown end reason ends the session as HOST_LOST")


# --- exact units: offline calculators -> ledger -> wire -> client model -----------------------


func _test_exact_unit_matches() -> void:
	# Two seats: sole finisher (Tapos+Una+Bayani = 14), all-finish suppression with and without
	# Barya, and a no-finisher round (a trap kill earns no Patibong).
	var two := _run_match(2, [
		{"kind": "race", "outcomes": [_finished(0, 10), _eliminated(1, 11, "direct_hazard", 0)], "coins": []},
		{"kind": "race", "outcomes": [_finished(0, 10), _finished(1, 11)], "coins": []},
		{"kind": "race", "outcomes": [_finished(0, 10), _finished(1, 11)], "coins": [1]},
		{"kind": "race", "outcomes": [_eliminated(0, 10), _eliminated(1, 11, "direct_hazard", 0)], "coins": []},
	])
	_check(two.agreed, "two-seat race rounds agree on every unit: %s" % str(two.notes))
	_check(two.deltas[0] == {0: 16, 1: 0}, "a sole finisher earns Tapos 8 + Una 2 + Bayani 4, plus Patibong 2 for the trap kill: %s" % str(two.deltas[0]))
	_check(two.deltas[1] == {0: 0, 1: 0} and two.entries[1].suppression == NetworkResultsCodec.Suppression.ALL_FINISHED, "all-finish suppression pays nobody without Barya")
	_check(two.deltas[2] == {0: 0, 1: 4} and two.entries[2].barya_seat == 1, "Barya still pays +0.5 (4 units) in an all-finish round")
	_check(two.deltas[3] == {0: 0, 1: 0} and two.entries[3].suppression == NetworkResultsCodec.Suppression.NO_FINISHER, "no finisher: no points, no Patibong")
	# Three seats: race Patibong, Lagsanay placement + Patibong, disconnect with no Patibong.
	var three := _run_match(3, [
		{"kind": "race", "outcomes": [_finished(0, 10), _finished(1, 12), _eliminated(2, 11, "direct_hazard", 0)], "coins": []},
		{"kind": "lag", "records": [_record(2, 10, 1.0), _record(1, 20, 2.0)], "survivors": [0], "outcomes": [_eliminated(2, 10, "direct_hazard", 1), _eliminated(1, 20, "timeout", -1)]},
		{"kind": "race", "outcomes": [_finished(0, 10), _eliminated(1, 12, "disconnect", -1), _finished(2, 14)], "coins": []},
	])
	_check(three.agreed, "three-seat rounds agree on every unit: %s" % str(three.notes))
	_check(three.deltas[0] == {0: 12, 1: 8, 2: 0}, "race: Tapos+Una+Patibong (12) for the trapper, Tapos (8) for the other finisher: %s" % str(three.deltas[0]))
	_check(three.deltas[1] == {0: 8, 1: 6, 2: 0}, "Lagsanay 3 seats: placement 8/4/0 plus one Patibong (+2): %s" % str(three.deltas[1]))
	var disconnect_seat: Dictionary = three.entries[2].seats[1]
	_check(int(disconnect_seat.cause) == NetworkResultsCodec.Cause.DISCONNECT and int(disconnect_seat.owner) == -1 and int(disconnect_seat.outcome) == NetworkResultsCodec.Outcome.ELIMINATED, "a disconnect elimination is recorded with cause disconnect and no owner")
	_check(three.deltas[2] == {0: 10, 1: 0, 2: 8}, "a disconnect earns no Patibong for anyone: %s" % str(three.deltas[2]))
	# Four seats: Lagsanay Last Cluck (latest elimination time wins), then a Bawi comeback.
	var four := _run_match(4, [
		{"kind": "lag", "records": [_record(3, 100, 1.0), _record(2, 100, 1.1), _record(1, 100, 1.2), _record(0, 100, 1.3)], "survivors": [], "outcomes": [_eliminated(3, 100, "timeout", -1), _eliminated(2, 100, "timeout", -1), _eliminated(1, 100, "timeout", -1), _eliminated(0, 100, "timeout", -1)]},
		{"kind": "race", "outcomes": [_finished(0, 10), _eliminated(1, 5, "elimination", -1), _eliminated(2, 5, "elimination", -1), _eliminated(3, 5, "elimination", -1)], "coins": []},
	])
	_check(four.agreed, "four-seat rounds agree on every unit: %s" % str(four.notes))
	_check(four.deltas[0] == {0: 8, 1: 4, 2: 2, 3: 0} and int(four.entries[0].last_cluck_seat) == 0, "Last Cluck: the latest elimination takes first (8/4/2/0)")
	_check(int(four.entries[0].seats[0].outcome) == NetworkResultsCodec.Outcome.FINISHED and int(four.entries[0].seats[0].placement) == 1, "the Last Cluck winner is recorded as finished in first place")
	var bawi := _run_match(3, [
		{"kind": "race", "outcomes": [_finished(0, 10), _eliminated(1, 12, "elimination", -1), _eliminated(2, 12, "elimination", -1)], "coins": []},
		{"kind": "race", "outcomes": [_finished(0, 10), _eliminated(1, 12, "elimination", -1), _eliminated(2, 12, "elimination", -1)], "coins": []},
		{"kind": "race", "outcomes": [_eliminated(0, 10, "elimination", -1), _eliminated(1, 12, "elimination", -1), _finished(2, 14)], "coins": []},
	])
	_check(bawi.agreed and bawi.deltas[2] == {0: 0, 1: 0, 2: 20}, "Bawi: an underdog 3+ points back who finishes alone earns 8+2+4+6 = 20 units: %s" % str(bawi.deltas[2]))
	var bawi_keys: Array = []
	for award in bawi.entries[2].seats[2].awards:
		bawi_keys.append(NetworkResultsCodec.award_name(int(award.key)))
	_check(bawi_keys == ["tapos", "una", "bayani", "bawi"], "the Bawi round names every award segment: %s" % str(bawi_keys))


## Plays rounds through the offline calculators, the lifecycle coordinator, the host ledger, the
## wire and the client model. `agreed` is true only when every unit matches at every step.
func _run_match(seat_count: int, rounds: Array) -> Dictionary:
	var seats: Array[int] = []
	for index in seat_count:
		seats.append(index)
	var lifecycle := MatchLifecycleCoordinator.new()
	lifecycle.begin(1)
	var ledger := ResultLedger.new()
	ledger.reset(1)
	var model := ClientResultsModel.new()
	var totals: Dictionary = {}
	for seat in seats:
		totals[seat] = 0
	var result := {"agreed": true, "notes": [], "deltas": [], "entries": []}
	for round_index in rounds.size():
		var spec: Dictionary = rounds[round_index]
		var score: Dictionary
		var family: int
		var outcomes: Array[Dictionary] = []
		outcomes.assign(spec.outcomes)
		if str(spec.kind) == "race":
			family = NetworkResultsCodec.ScoringFamily.RACE
			var coins: Array[int] = []
			coins.assign(spec.get("coins", []))
			score = RaceScoreCalculator.calculate(seats, outcomes, totals, coins)
		else:
			family = NetworkResultsCodec.ScoringFamily.LAGSANAY
			var records: Array[Dictionary] = []
			records.assign(spec.records)
			var survivors: Array[int] = []
			survivors.assign(spec.survivors)
			score = LagsanayScoreCalculator.calculate(seats, records, survivors, outcomes, totals)
		if not bool(score.get("valid", false)):
			result.agreed = false
			result.notes.append("round %d calculator refused: %s" % [round_index + 1, str(score.get("reason", ""))])
			break
		var decision := lifecycle.finish_round(round_index + 1, score.totals_units, TARGET, LIMIT)
		var committed := ledger.commit_round(round_index + 1, 1, family, score, outcomes, decision)
		if committed.is_empty():
			result.agreed = false
			result.notes.append("round %d was not committed" % (round_index + 1))
			break
		var payload := NetworkResultsCodec.encode_event(committed)
		var wire := NetworkResultsCodec.decode_event(payload)
		if payload.is_empty() or not bool(wire.get("ok", false)):
			result.agreed = false
			result.notes.append("round %d did not survive the wire" % (round_index + 1))
			break
		if model.apply(wire, 1) != ClientResultsModel.Apply.APPLIED:
			result.agreed = false
			result.notes.append("round %d was not applied by the client model" % (round_index + 1))
			break
		var deltas: Dictionary = {}
		for seat_variant in wire.seats:
			var seat: Dictionary = seat_variant
			var index := int(seat.seat)
			deltas[index] = int(seat.delta)
			if int(seat.delta) != int(score.delta_units[index]) or int(seat.total) != int(score.totals_units[index]):
				result.agreed = false
				result.notes.append("round %d seat %d differs from the calculator" % [round_index + 1, index])
			var sum := 0
			for award in seat.awards:
				sum += int(award.units)
			if sum != int(seat.delta):
				result.agreed = false
				result.notes.append("round %d seat %d awards do not sum to the delta" % [round_index + 1, index])
		result.deltas.append(deltas)
		result.entries.append(wire)
		totals = score.totals_units.duplicate()
	if model.totals() != totals:
		result.agreed = false
		result.notes.append("client totals %s differ from host totals %s" % [str(model.totals()), str(totals)])
	if model.revision() != ledger.revision():
		result.agreed = false
		result.notes.append("client and host ledger revisions differ")
	return result


# --- ledger and client model rules -----------------------------------------------------------


func _test_ledger_and_model_rules() -> void:
	var ledger := ResultLedger.new()
	_check(ledger.commit_sudden_death_result(1, 1, 1, 0, false).is_empty(), "a ledger without a match ID refuses every commit")
	ledger.reset(4)
	var committed_events: Array = []
	ledger.committed.connect(func(entry: Dictionary) -> void: committed_events.append(entry))
	var first := ledger.commit_sudden_death_result(12, 1, 1, 0, false)
	_check(int(first.event_id) == 1 and int(first.revision) == 1 and int(first.match_id) == 4 and committed_events.size() == 1, "the first commit is event 1, revision 1, under the ledger's match")
	var second := ledger.commit_sudden_death_result(12, 1, 1, 1, true)
	_check(int(second.event_id) == 2 and ledger.revision() == 2 and ledger.latest_event_id() == 2, "each commit advances the revision by exactly one")
	_check(ledger.commit_sudden_death_result(12, 1, 1, 9, false).is_empty() and ledger.revision() == 2, "an invalid entry is refused and changes nothing")
	for index in range(ledger.revision(), NetworkResultsCodec.MAX_ENTRIES):
		ledger.commit_sudden_death_result(12, 1, 1, 0, false)
	_check(ledger.revision() == NetworkResultsCodec.MAX_ENTRIES and ledger.commit_sudden_death_result(12, 1, 1, 0, false).is_empty(), "the ledger holds at most 128 entries and never overwrites")
	var copy := ledger.entries()
	copy[0]["winner_seat"] = 3
	_check(int(ledger.entries()[0].winner_seat) == 0, "entries() returns copies; the committed record cannot be edited from outside")
	ledger.reset(5)
	_check(ledger.revision() == 0 and ledger.match_id == 5, "a reset starts a new empty ledger")

	# Client model: duplicate, stale, gap, invalid.
	var played := _run_match(2, [
		{"kind": "race", "outcomes": [_finished(0, 10), _eliminated(1, 11, "elimination", -1)], "coins": []},
		{"kind": "race", "outcomes": [_finished(0, 10), _eliminated(1, 11, "elimination", -1)], "coins": []},
		{"kind": "race", "outcomes": [_finished(0, 10), _eliminated(1, 11, "elimination", -1)], "coins": []},
	])
	var model := ClientResultsModel.new()
	var one: Dictionary = played.entries[0]
	var two_entry: Dictionary = played.entries[1]
	var three_entry: Dictionary = played.entries[2]
	_check(model.apply(three_entry, 1) == ClientResultsModel.Apply.GAP, "an entry two ahead of the ledger is a gap")
	_check(model.apply(one, 1) == ClientResultsModel.Apply.APPLIED and model.revision() == 1, "revision 1 applies")
	_check(model.apply(one, 1) == ClientResultsModel.Apply.DUPLICATE and model.revision() == 1, "the same revision again is idempotent")
	var forged := one.duplicate(true)
	forged.seats[0].total = 99
	forged.seats[0].delta = 99
	forged.seats[0].awards = [{"key": 1, "units": 99}]
	_check(model.apply(forged, 1) == ClientResultsModel.Apply.STALE, "a different body for an old revision is ignored")
	_check(model.apply(one, 2) == ClientResultsModel.Apply.STALE, "an entry of another match is stale")
	var bad_total := two_entry.duplicate(true)
	bad_total.seats[0].total += 8
	bad_total.seats[0].delta += 8
	bad_total.seats[0].awards.append({"key": 2, "units": 8})
	_check(model.apply(bad_total, 1) == ClientResultsModel.Apply.INVALID, "a total that does not continue the ledger is invalid")
	var skipped_total := two_entry.duplicate(true)
	skipped_total.seats[0].total -= 2
	skipped_total.seats[0].delta -= 2
	skipped_total.seats[0].awards.pop_back()
	_check(model.apply(skipped_total, 1) == ClientResultsModel.Apply.INVALID, "a total below the previous one plus its own delta is invalid")
	_check(model.apply(two_entry, 1) == ClientResultsModel.Apply.APPLIED and model.apply(three_entry, 1) == ClientResultsModel.Apply.APPLIED and int(model.totals()[0]) == 42 and int(model.totals()[1]) == 0, "the genuine entries apply in order (three sole-finisher rounds = 42 units)")
	var wrong_id := _sample_round_entry(4, 1, 3, 0)
	wrong_id.event_id = 9
	_check(model.apply(wrong_id, 4) != ClientResultsModel.Apply.APPLIED, "an entry whose event ID is not its revision never applies")
	# Snapshot install: out of order is sorted; an invalid ledger leaves the model empty.
	var snapshot_model := ClientResultsModel.new()
	_check(snapshot_model.install_snapshot([three_entry.duplicate(true), one.duplicate(true), two_entry.duplicate(true)], 1) and snapshot_model.revision() == 3, "a snapshot installs the complete ledger in revision order")
	var broken := two_entry.duplicate(true)
	broken.seats[1].total = 5
	broken.seats[1].delta = 5
	broken.seats[1].awards = [{"key": 1, "units": 5}]
	_check(not snapshot_model.install_snapshot([one.duplicate(true), broken], 1) and snapshot_model.revision() == 0, "a snapshot whose ledger breaks the rules installs nothing")
	# Vote: only the latest event, only a newer sequence.
	var vote_model := ClientResultsModel.new()
	vote_model.apply(one, 1)
	_check(not vote_model.apply_vote({"match_id": 1, "event_id": 9, "vote_seq": 1, "action": 1, "ready_mask": 0, "required_mask": 3}, 1), "a vote for another event is ignored")
	_check(vote_model.apply_vote({"match_id": 1, "event_id": 1, "vote_seq": 4, "action": 1, "ready_mask": 1, "required_mask": 3}, 1), "a vote for the latest event is kept")
	_check(not vote_model.apply_vote({"match_id": 1, "event_id": 1, "vote_seq": 3, "action": 1, "ready_mask": 0, "required_mask": 3}, 1) and int(vote_model.vote.ready_mask) == 1, "an older vote sequence is ignored")
	var wrap_model := ClientResultsModel.new()
	wrap_model.apply(one, 1)
	wrap_model.apply_vote({"match_id": 1, "event_id": 1, "vote_seq": 0xfffffff0, "action": 1, "ready_mask": 0, "required_mask": 3}, 1)
	_check(wrap_model.apply_vote({"match_id": 1, "event_id": 1, "vote_seq": 5, "action": 1, "ready_mask": 1, "required_mask": 3}, 1) and int(wrap_model.vote.ready_mask) == 1, "vote sequence comparison is wrap-aware")


func _test_sudden_death_and_ending_rules() -> void:
	# Target score: six sole-finisher rounds (14 units each) pass 80 and make a winner.
	var rounds: Array = []
	for index in 6:
		rounds.append({"kind": "race", "outcomes": [_finished(0, 10), _eliminated(1, 11, "elimination", -1)], "coins": []})
	var ended := _run_match(2, rounds)
	_check(ended.agreed, "a target-score match agrees: %s" % str(ended.notes))
	_check(int(ended.entries[5].decision) == NetworkResultsCodec.Decision.WINNER and int(ended.entries[5].winner_seat) == 0 and int(ended.entries[5].terminal_reason) == NetworkResultsCodec.Terminal.SCORE_TARGET, "round 6 (84 units) decides the winner by score target")
	var decisions_before_last: Array = []
	for index in 5:
		decisions_before_last.append(int(ended.entries[index].decision))
	_check(decisions_before_last == [1, 1, 1, 1, 1], "rounds 1-5 continue")
	var model := ClientResultsModel.new()
	for entry in ended.entries:
		model.apply(entry, 1)
	var after_winner := _sample_round_entry(1, 1, 7, 0)
	after_winner.event_id = 7
	after_winner.revision = 7
	_check(model.apply(after_winner, 1) == ClientResultsModel.Apply.INVALID, "no round entry can follow a winner (no extra round)")
	var final_ok := {"kind": 4, "match_id": 1, "round_id": 6, "attempt_id": 1, "event_id": 7, "revision": 7, "winner_seat": 0, "last_cluck": 0, "sudden_death": 0, "terminal_reason": 1, "seats": [{"seat": 0, "total": 84}, {"seat": 1, "total": 0}]}
	var final_bad := final_ok.duplicate(true)
	final_bad.seats[0].total = 92
	_check(model.apply(final_bad, 1) == ClientResultsModel.Apply.INVALID, "the final entry cannot change a total")
	_check(model.apply(final_ok, 1) == ClientResultsModel.Apply.APPLIED and model.is_final() and int(model.final_entry().winner_seat) == 0, "the final entry applies and names the winner")
	# Round limit with tied leaders: twelve no-finisher rounds, then Sudden Death that scores nothing.
	var tie_rounds: Array = []
	for index in 12:
		tie_rounds.append({"kind": "race", "outcomes": [_eliminated(0, 10, "elimination", -1), _eliminated(1, 11, "elimination", -1)], "coins": []})
	var tied := _run_match(2, tie_rounds)
	_check(tied.agreed and tied.entries.size() == 12, "twelve rounds agree: %s" % str(tied.notes))
	var last_round: Dictionary = tied.entries[11]
	_check(int(last_round.round_id) == 12 and int(last_round.decision) == NetworkResultsCodec.Decision.SUDDEN_DEATH and int(last_round.tied_mask) == 3 and int(last_round.terminal_reason) == NetworkResultsCodec.Terminal.ROUND_LIMIT, "round 12 with tied leaders enters Sudden Death")
	var max_round := 0
	for entry in tied.entries:
		max_round = maxi(max_round, int(entry.round_id))
	_check(max_round == 12, "no round entry exceeds round 12")
	var sd_model := ClientResultsModel.new()
	for entry in tied.entries:
		sd_model.apply(entry, 1)
	var sd_entry := {"kind": 2, "match_id": 1, "round_id": 12, "attempt_id": 1, "event_id": 13, "revision": 13, "tied_mask": 3, "sd_attempt": 1, "terminal_reason": 2, "seats": [{"seat": 0, "total": 0}, {"seat": 1, "total": 0}]}
	var sd_scored := sd_entry.duplicate(true)
	sd_scored.seats[1].total = 2
	_check(sd_model.apply(sd_scored, 1) == ClientResultsModel.Apply.INVALID, "Sudden Death cannot carry a score change")
	_check(sd_model.apply(sd_entry, 1) == ClientResultsModel.Apply.APPLIED and sd_model.is_sudden_death(), "the Sudden Death entry applies and the phone shows Sudden Death")
	var round_13 := _sample_round_entry(1, 1, 13, 0)
	round_13.event_id = 14
	round_13.revision = 14
	_check(sd_model.apply(round_13, 1) != ClientResultsModel.Apply.APPLIED, "a thirteenth round entry never applies")
	var sd_result := {"kind": 3, "match_id": 1, "round_id": 12, "attempt_id": 1, "event_id": 14, "revision": 14, "winner_seat": 1, "last_cluck": 0, "sd_attempt": 1}
	var wrong_winner := sd_result.duplicate()
	wrong_winner.winner_seat = 2
	_check(sd_model.apply(wrong_winner, 1) == ClientResultsModel.Apply.INVALID, "the Sudden Death winner must be one of the tied seats")
	_check(sd_model.apply(sd_result, 1) == ClientResultsModel.Apply.APPLIED and not sd_model.is_sudden_death(), "the Sudden Death result closes it")
	var sd_final := {"kind": 4, "match_id": 1, "round_id": 12, "attempt_id": 1, "event_id": 15, "revision": 15, "winner_seat": 1, "last_cluck": 0, "sudden_death": 1, "terminal_reason": 2, "seats": [{"seat": 0, "total": 0}, {"seat": 1, "total": 0}]}
	_check(sd_model.apply(sd_final, 1) == ClientResultsModel.Apply.APPLIED and sd_model.is_final() and sd_model.totals() == {0: 0, 1: 0}, "the final result after Sudden Death keeps every total exactly as it was at the tie")
	# The host ledger path for the same tie: the coordinator drives entry, result and final.
	var host_ledger := ResultLedger.new()
	host_ledger.reset(1)
	var totals := {0: 0, 1: 0}
	_check(not host_ledger.commit_sudden_death_entry(12, 1, 1, [0, 1], totals, NetworkResultsCodec.Terminal.ROUND_LIMIT).is_empty(), "the host commits the Sudden Death entry with no deltas")
	_check(not host_ledger.commit_sudden_death_result(12, 1, 1, 1, false).is_empty() and not host_ledger.commit_final(12, 1, 1, false, true, NetworkResultsCodec.Terminal.ROUND_LIMIT, totals).is_empty(), "the host commits the Sudden Death result and the final result")


func _test_reservation_and_registry_additions() -> void:
	var book := SeatReservationBook.new()
	var original := book.issue(1)
	book.reserve(1, 0)
	book.claim_round_commit(1, 1)
	var rekeyed := book.rekey(1)
	_check(rekeyed.player_id == original.player_id and rekeyed.token != original.token, "a re-key keeps the Player ID and replaces the token")
	_check(not book.is_reserved(1) and book.committed_round(1) == -1, "a re-key clears the reservation and the per-round commit mark")
	book.issue(2)
	book.retain_only([1])
	_check(book.has_entry(1) and not book.has_entry(2) and book.entry_count() == 1, "retain_only drops seats outside the next match")
	var forfeit_book := SeatReservationBook.new()
	var identity := forfeit_book.issue(0)
	_check(forfeit_book.forfeit(0, 1000) and forfeit_book.is_reserved(0), "a forfeit reserves the seat")
	_check(forfeit_book.take_expired(1000) == [0], "a forfeited seat's grace is already over")
	_check(forfeit_book.token_for_proof(0) != identity.token, "a forfeited seat's token is replaced by one nobody holds")
	var host := SimulationAuthority.host()
	var registry := PlayerSeatRegistry.new()
	registry.authority = host
	var seat := registry.assign_remote_source("peer_77", -1, host)
	registry.revoke_remote_source("peer_77", host)
	_check(registry.release_unconnected_remote_seat(seat, host) and not bool(registry.get_seat(seat).joined), "a lost remote seat can be released for the next match")
	var connected := registry.assign_remote_source("peer_78", -1, host)
	_check(not registry.release_unconnected_remote_seat(connected, host) and bool(registry.get_seat(connected).joined), "a connected seat is never released")
	var local := registry.join_keyboard("K1")
	registry.disconnect_gamepad(99)
	_check(not registry.release_unconnected_remote_seat(local, host), "a local seat is never released by this path")


# --- host session: results, vote, action ------------------------------------------------------


func _test_host_results_flow() -> void:
	var fixture: Dictionary = await _host_fixture()
	var manager: CaptureManager = fixture.manager
	var room: StubRoom = fixture.room
	manager.candidates[REMOTE_PEER].match_sync_ready = true
	manager.state = NetworkSessionManager.SessionState.LOBBY_OPEN
	# A committed entry reaches every synchronized peer once, under the session's match ID.
	room.result_ledger.reset(3)
	var committed := room.result_ledger.commit_sudden_death_result(12, 1, 1, 0, false)
	var frames := _sent_family(manager, NetworkFrame.Family.RESULT_EVENT)
	var decoded := NetworkResultsCodec.decode_event(frames[0]) if not frames.is_empty() else {}
	_check(frames.size() == 1 and bool(decoded.get("ok", false)) and int(decoded.match_id) == manager.active_match_id and int(decoded.event_id) == int(committed.event_id), "a commit is sent once, keyed by the session match ID (%d), not the room's run id" % manager.active_match_id)
	manager.sent.clear()
	manager.candidates[REMOTE_PEER].match_sync_ready = false
	room.result_ledger.commit_sudden_death_result(12, 1, 1, 1, false)
	_check(_sent_family(manager, NetworkFrame.Family.RESULT_EVENT).is_empty(), "a peer that is still synchronizing gets the entry after SYNC_READY, not before")
	manager._send_ledger_repeat(REMOTE_PEER)
	_check(_sent_family(manager, NetworkFrame.Family.RESULT_EVENT).size() == 2, "the repeat after sync carries the whole ledger in order")
	manager.candidates[REMOTE_PEER].match_sync_ready = true
	manager.sent.clear()
	manager.sent.clear()
	# A result action is applied for the bound seat only, once per request ID.
	var latest := room.result_ledger.latest_event_id()
	var request := {"request_id": 11, "match_id": manager.active_match_id, "round_id": 12, "attempt_id": room.match_run_id & 0xffff, "event_id": latest, "action": NetworkResultsCodec.ResultAction.VOTE_REPLAY}
	var action := NetworkResultsCodec.encode_action(request)
	manager._handle_host_packet(REMOTE_PEER, NetworkFrame.Family.RESULT_ACTION, action)
	_check(room.votes.size() == 1 and int(room.votes[0][0]) == int(fixture.remote_seat) and int(room.votes[0][1]) == NetworkResultsCodec.ResultAction.VOTE_REPLAY, "a phone's vote reaches the room for its own seat")
	manager._handle_host_packet(REMOTE_PEER, NetworkFrame.Family.RESULT_ACTION, action)
	_check(room.votes.size() == 1 and not _sent_family(manager, NetworkFrame.Family.RESULT_VOTE).is_empty(), "an exact retry is not applied twice and is answered with the current vote")
	request.request_id = 12
	request.event_id = latest + 5
	manager.sent.clear()
	manager._handle_host_packet(REMOTE_PEER, NetworkFrame.Family.RESULT_ACTION, NetworkResultsCodec.encode_action(request))
	_check(room.votes.size() == 1 and not _sent_family(manager, NetworkFrame.Family.RESULT_VOTE).is_empty() and _count_reason(manager, NetworkFrame.Reason.STALE_STATE) == 0, "an action for a stale result is repaired with the vote, never rejected (a reject would free the seat)")
	request.event_id = latest
	request.request_id = 13
	request.event_id = latest
	request.match_id = manager.active_match_id + 9
	manager._handle_host_packet(REMOTE_PEER, NetworkFrame.Family.RESULT_ACTION, NetworkResultsCodec.encode_action(request))
	_check(room.votes.size() == 1, "an action for another match is not applied")
	var refusals_before := _count_reason(manager, NetworkFrame.Reason.MALFORMED)
	manager._handle_host_packet(REMOTE_PEER, NetworkFrame.Family.RESULT_ACTION, PackedByteArray([1, 2, 3]))
	_check(_count_reason(manager, NetworkFrame.Reason.MALFORMED) == refusals_before + 1, "a malformed result action is refused MALFORMED")
	manager.candidates[REMOTE_PEER].match_sync_ready = false
	request.request_id = 14
	request.match_id = manager.active_match_id
	manager._handle_host_packet(REMOTE_PEER, NetworkFrame.Family.RESULT_ACTION, NetworkResultsCodec.encode_action(request))
	_check(room.votes.size() == 1, "a peer that is not synchronized cannot vote")
	manager.candidates[REMOTE_PEER].match_sync_ready = true
	for index in NetworkSessionManager.RESULT_ACTION_CACHE_CAP + 8:
		request.request_id = 100 + index
		manager._handle_host_packet(REMOTE_PEER, NetworkFrame.Family.RESULT_ACTION, NetworkResultsCodec.encode_action(request))
	_check(manager._result_action_cache[REMOTE_PEER].size() <= NetworkSessionManager.RESULT_ACTION_CACHE_CAP, "the per-peer request cache is bounded at 32")
	# The rate limit applies to RESULT_ACTION.
	var rate_manager := CaptureManager.new()
	root.add_child(rate_manager)
	var accepted := 0
	for index in 8:
		if rate_manager._accept_rate(REMOTE_PEER, NetworkFrame.Family.RESULT_ACTION):
			accepted += 1
	_check(accepted == NetworkSessionManager.RESULT_ACTION_MAX_PER_SECOND, "a phone may send at most 4 result actions per second")
	rate_manager.free()
	# Remote confirm/back/navigation can no longer reach the host's result menu or its leave dialog.
	room.phase_controller.enter(MatchPhaseController.Phase.RESULTS)
	for action_id in [1, 2, 7, 8, 9, 10]:
		_check(not manager._action_phase_allowed(action_id), "remote action %d is not accepted in Results (results use RESULT_ACTION)" % action_id)
	room.phase_controller.enter(MatchPhaseController.Phase.PUGAD)
	_check(manager._action_phase_allowed(1) and manager._action_phase_allowed(7), "the same actions still work in Pugad")
	# The vote broadcast follows the room's state and only repeats when it changes.
	manager.sent.clear()
	manager._last_vote_signature = ""
	manager._send_result_vote_if_changed()
	manager._send_result_vote_if_changed()
	_check(_sent_family(manager, NetworkFrame.Family.RESULT_VOTE).size() == 1, "an unchanged vote is not re-broadcast")
	# A client frame of a host-only family is refused HOST_ONLY and applies nothing. Last, because
	# three refusals in 10 s close the peer.
	var votes_before := room.votes.size()
	var refused_before := _count_reason(manager, NetworkFrame.Reason.HOST_ONLY)
	manager._handle_host_packet(REMOTE_PEER, NetworkFrame.Family.RESULT_EVENT, NetworkResultsCodec.encode_event(committed))
	manager._handle_host_packet(REMOTE_PEER, NetworkFrame.Family.RESULT_VOTE, NetworkResultsCodec.encode_vote({"match_id": 7, "round_id": 1, "event_id": 1, "vote_seq": 1, "action": 1, "ready_mask": 3, "required_mask": 3}))
	manager._handle_host_packet(REMOTE_PEER, NetworkFrame.Family.REKEY, PackedByteArray())
	_check(_count_reason(manager, NetworkFrame.Reason.HOST_ONLY) == refused_before + 3 and room.votes.size() == votes_before, "client RESULT_EVENT, RESULT_VOTE and REKEY frames are refused HOST_ONLY")
	await _free_host_fixture(fixture)


# --- client session: apply, dedupe, snapshot ---------------------------------------------------


func _test_client_results_flow() -> void:
	var played := _run_match(2, [
		{"kind": "race", "outcomes": [_finished(0, 10), _eliminated(1, 11, "elimination", -1)], "coins": []},
		{"kind": "race", "outcomes": [_finished(0, 10), _eliminated(1, 11, "elimination", -1)], "coins": []},
	])
	var client := CaptureManager.new()
	root.add_child(client)
	client.client_mode = true
	client.match_active = true
	client.sync_ready = true
	client.active_match_id = 6
	client.client_results.reset(6)
	var changes := [0]
	client.results_changed.connect(func() -> void: changes[0] += 1)
	var first: Dictionary = (played.entries[0] as Dictionary).duplicate(true)
	first.match_id = 6
	var second: Dictionary = (played.entries[1] as Dictionary).duplicate(true)
	second.match_id = 6
	client._receive_result_event(NetworkResultsCodec.encode_event(first))
	_check(client.client_results.revision() == 1 and changes[0] == 1, "a result event updates the model and notifies the screen once")
	client._receive_result_event(NetworkResultsCodec.encode_event(first))
	_check(client.client_results.revision() == 1 and changes[0] == 1, "a duplicate event changes nothing and does not re-notify")
	client._receive_result_event(NetworkResultsCodec.encode_event(second))
	_check(client.client_results.revision() == 2 and changes[0] == 2, "the next revision applies")
	var messages: Array = []
	client.client_message.connect(func(text: String) -> void: messages.append(text))
	client._receive_result_event(PackedByteArray([1, 2, 3]))
	_check(client.client_results.revision() == 2 and messages.size() == 1, "an undecodable event is ignored with one notice")
	var gap := second.duplicate(true)
	gap.event_id = 4
	gap.revision = 4
	client._receive_result_event(NetworkResultsCodec.encode_event(gap))
	_check(not client.sync_ready and client.client_results.revision() == 2, "a gap asks for a snapshot and applies nothing")
	# The vote follows the ledger.
	client.sync_ready = true
	client._receive_result_vote(NetworkResultsCodec.encode_vote({"match_id": 6, "round_id": 2, "event_id": 2, "vote_seq": 1, "action": 1, "ready_mask": 1, "required_mask": 3}))
	_check(int(client.client_results.vote.get("ready_mask", 0)) == 1 and changes[0] == 3, "a vote for the latest entry is shown")
	# The complete ledger rides the snapshot and rebuilds the client model after a resync.
	var records: Array[PackedByteArray] = []
	for entry in [first, second]:
		records.append(NetworkMatchCodec.encode_ledger_record(entry))
	var packed := NetworkMatchCodec.pack_snapshot(records)
	var unpacked := NetworkMatchCodec.unpack_snapshot(packed)
	_check(bool(unpacked.get("ok", false)) and unpacked.records.size() == 2 and bool(unpacked.records[0].get("ledger", false)), "ledger records ride a snapshot and decode as ledger records")
	var replica := client._replica_from_records({"match_id": 6, "round_id": 2, "attempt_id": 1, "tick": 1, "stage_version": 0, "event_revision": 0}, unpacked.records, 1)
	_check(replica.ledger.size() == 2, "the replica carries the snapshot ledger")
	var fresh := CaptureManager.new()
	root.add_child(fresh)
	fresh.active_match_id = 6
	_check(fresh.client_results.install_snapshot(replica.ledger, 6) and fresh.client_results.revision() == 2 and fresh.client_results.totals() == {0: 28, 1: 0}, "a resync restores the full ledger and the exact cumulative scores (28 and 0 units)")
	fresh.free()
	# A snapshot of the maximum ledger stays far under the 64 KiB cap and the 128-entry limit holds.
	var all_records: Array[PackedByteArray] = []
	for index in NetworkResultsCodec.MAX_ENTRIES:
		var sd_record := {"kind": 3, "match_id": 6, "round_id": 12, "attempt_id": 1, "event_id": index + 1, "revision": index + 1, "winner_seat": 0, "last_cluck": 0, "sd_attempt": 1}
		all_records.append(NetworkMatchCodec.encode_ledger_record(sd_record))
	var big := NetworkMatchCodec.pack_snapshot(all_records)
	_check(not big.is_empty() and big.size() <= NetworkMatchCodec.SNAPSHOT_CAP, "128 ledger records fit one snapshot (%d bytes)" % big.size())
	client.free()


# --- replay re-key ---------------------------------------------------------------------------


func _test_replay_rekey() -> void:
	var fixture: Dictionary = await _host_fixture()
	var manager: CaptureManager = fixture.manager
	var room: StubRoom = fixture.room
	var seat: int = fixture.remote_seat
	manager.candidates[REMOTE_PEER] = _acknowledged_candidate(fixture)
	manager.candidates[REMOTE_PEER].match_sync_ready = true
	manager.state = NetworkSessionManager.SessionState.LOBBY_OPEN
	manager.session_epoch = 0x1111
	var old_epoch := manager.session_epoch
	var old_match := manager.active_match_id
	manager.reservations.reserve(seat, 0)
	var old_token := manager.reservations.token_for_proof(seat)
	manager.reservations.finish_reclaim(seat, -1)
	manager._pending_actions[REMOTE_PEER] = [{"request_id": 1}]
	manager._placement_cache[REMOTE_PEER] = {"1:1": {}}
	manager._terrain_shadow = {5: "x"}
	manager._known_stage_entity_ids = {5: true}
	manager._result_action_cache[REMOTE_PEER] = {"1": true}
	manager.pause_controller.epoch = 4
	room.roster = 1
	_check(not manager._network_replay() and manager.session_epoch == old_epoch, "a replay with fewer than two connected players is refused and changes nothing")
	room.roster = 2
	room.original_seat_indices = [0, seat]
	manager._match_lineage = old_match
	_check(manager._network_replay(), "a replay with two connected players re-keys the session")
	_check(manager.session_epoch != old_epoch and manager.session_epoch > 0, "the replay mints a new epoch")
	_check(manager.active_match_id == old_match + 1 and manager._match_lineage == old_match + 1, "the replay mints a new match ID that is never reused")
	var rekey_frames := manager.sent.filter(func(entry: Dictionary) -> bool: return int(entry.family) == NetworkFrame.Family.REKEY)
	var rekey := NetworkLifecycleCodec.decode_rekey(rekey_frames[0].payload) if not rekey_frames.is_empty() else {}
	_check(rekey_frames.size() == 1 and int(rekey_frames[0].epoch) == old_epoch and int(rekey.new_epoch) == manager.session_epoch and int(rekey.new_match_id) == manager.active_match_id, "the re-key frame is sent under the OLD epoch and names the new epoch and match ID")
	_check(old_token.size() == 16 and rekey.token != old_token and manager.reservations.committed_round(seat) == -1, "the reclaim token is replaced and the per-round mark cleared")
	_check(manager._retired_epochs.has(old_epoch) and manager._rekey_pending.has(REMOTE_PEER), "the old epoch is retired and the peer must acknowledge")
	var counts := manager.teardown_counts()
	for key in ["pending_actions", "placement_cache", "terrain_shadow", "known_stage_entities", "result_action_cache", "host_input_state", "pause_epoch"]:
		_check(int(counts[key]) == 0, "the re-key cleared %s" % key)
	_check(not bool(manager.candidates[REMOTE_PEER].match_sync_ready), "no peer is synchronized until it acknowledges the new identity")
	# Packets still in flight under the old epoch are dropped quietly.
	manager.sent.clear()
	var stale_frame := NetworkFrame.encode(NetworkFrame.Family.CONTINUOUS_INPUT, old_epoch, 99, PackedByteArray([0]))
	manager._on_packet_received(REMOTE_PEER, RawEnetTransport.INPUT_CHANNEL, stale_frame)
	_check(_sent_family(manager, NetworkFrame.Family.ADMISSION_DECISION).is_empty(), "an old-epoch packet right after the re-key is dropped without a rejection")
	var unknown_frame := NetworkFrame.encode(NetworkFrame.Family.CONTINUOUS_INPUT, 0x7777, 100, PackedByteArray([0]))
	manager._on_packet_received(REMOTE_PEER, RawEnetTransport.INPUT_CHANNEL, unknown_frame)
	_check(_count_reason(manager, NetworkFrame.Reason.STALE_STATE) == 1, "an epoch that was never ours is still rejected STALE_STATE")
	manager.candidates[REMOTE_PEER] = _acknowledged_candidate(fixture)
	manager.candidates[REMOTE_PEER].match_sync_ready = false
	manager._rekey_pending[REMOTE_PEER] = Time.get_ticks_msec() + 3000
	manager._retired_epochs[old_epoch] = Time.get_ticks_msec() - NetworkSessionManager.RETIRED_EPOCH_MS - 1
	_check(not manager._epoch_is_retired(manager._retired_epochs, old_epoch) and manager._retired_epochs.is_empty(), "a retired epoch is forgotten after its window")
	# The acknowledgement: wrong epoch is refused, the right one releases the lifecycle and a snapshot.
	manager.sent.clear()
	manager._handle_host_packet(REMOTE_PEER, NetworkFrame.Family.REKEY_ACK, NetworkLifecycleCodec.encode_rekey_ack(old_epoch, GENERATION))
	_check(_count_reason(manager, NetworkFrame.Reason.OWNERSHIP) == 1 and manager._rekey_pending.has(REMOTE_PEER), "an acknowledgement for the wrong epoch is refused")
	manager.candidates[REMOTE_PEER] = _acknowledged_candidate(fixture)
	manager.sent.clear()
	manager._handle_host_packet(REMOTE_PEER, NetworkFrame.Family.REKEY_ACK, NetworkLifecycleCodec.encode_rekey_ack(manager.session_epoch, GENERATION))
	var lifecycle := _sent_family(manager, NetworkFrame.Family.MATCH_LIFECYCLE)
	_check(not manager._rekey_pending.has(REMOTE_PEER) and lifecycle.size() == 1 and manager._read_u64(lifecycle[0], 1) == manager.active_match_id, "a valid acknowledgement sends the new match start")
	_check(manager._pending_snapshot_peers.has(REMOTE_PEER) and bool(manager._host_input_state[REMOTE_PEER].await_neutral), "it queues a fresh snapshot and re-arms the neutral-input gate")
	manager.sent.clear()
	manager._handle_host_packet(REMOTE_PEER, NetworkFrame.Family.REKEY_ACK, NetworkLifecycleCodec.encode_rekey_ack(manager.session_epoch, GENERATION))
	_check(manager.sent.is_empty(), "a repeated acknowledgement is ignored")
	# A peer that never acknowledges forfeits through the disconnect-elimination path.
	manager._rekey_pending[REMOTE_PEER] = Time.get_ticks_msec() - 1
	manager._expire_rekey_pending()
	_check(not manager.candidates.has(REMOTE_PEER) and manager.reservations.is_reserved(seat) and not manager._rekey_pending.has(REMOTE_PEER), "a peer that does not acknowledge in time is dropped and its seat forfeits")
	_check(manager.reservations.take_expired(Time.get_ticks_msec() + 1).has(seat), "the forfeited seat is due for its single disconnect elimination")
	await _free_host_fixture(fixture)
	# Client side.
	var client := CaptureManager.new()
	root.add_child(client)
	client.client_mode = true
	client.match_active = true
	client.sync_ready = true
	client.client_assigned_seat = 1
	client.assigned_peer_generation = GENERATION
	client.session_epoch = 0x2222
	client._client_expected_host_epoch = 0x2222
	client.active_match_id = 2
	client.client_replica_state = {"snapshot_id": 3, "seats": {1: {}}}
	client.client_results.reset(2)
	client._client_input_sequence = 40
	client._result_request_id = 5
	var token := PackedByteArray()
	token.resize(16)
	token.fill(3)
	var messages: Array = []
	client.client_message.connect(func(text: String) -> void: messages.append(text))
	client._receive_rekey(1, NetworkLifecycleCodec.encode_rekey(0x3333, 2, 0, 0, token))
	_check(client.session_epoch == 0x2222 and client.active_match_id == 2, "a re-key that does not advance the match ID is ignored")
	client._receive_rekey(1, NetworkLifecycleCodec.encode_rekey(0x3333, 3, 0, 0, token))
	_check(client.session_epoch == 0x3333 and client.active_match_id == 3 and client._client_expected_host_epoch == 0x3333, "a client adopts the new epoch and match ID")
	_check(client.client_replica_state.is_empty() and client.client_results.revision() == 0 and not client.sync_ready and client._client_input_sequence == 0 and client._result_request_id == 0, "the client clears the old match: replica, ledger, sync and counters")
	_check(client.client_reclaim_token == token and client._client_retired_epochs.has(0x2222), "the client keeps the new token and retires the old epoch")
	var acks := client.sent.filter(func(entry: Dictionary) -> bool: return int(entry.family) == NetworkFrame.Family.REKEY_ACK)
	_check(acks.size() == 1 and int(acks[0].epoch) == 0x3333 and int(NetworkLifecycleCodec.decode_rekey_ack(acks[0].payload).new_epoch) == 0x3333, "the acknowledgement is sent under the NEW epoch")
	messages.clear()
	var late := NetworkFrame.encode(NetworkFrame.Family.STATE_UPDATE, 0x2222, 7, PackedByteArray([0]))
	client._on_packet_received(1, RawEnetTransport.STATE_CHANNEL, late)
	_check(messages.is_empty(), "an old-epoch host packet after the re-key is dropped silently (no notice, no stop)")
	client.free()


# --- session end, leave and teardown ---------------------------------------------------------


func _test_session_end_and_leave() -> void:
	for case in [
		[NetworkLifecycleCodec.SessionEnd.LOBBY_RETURN, NetworkLifecycleCodec.SessionEnd.LOBBY_RETURN],
		[NetworkLifecycleCodec.SessionEnd.HOST_QUIT, NetworkLifecycleCodec.SessionEnd.HOST_QUIT],
		[NetworkLifecycleCodec.SessionEnd.HOST_CLOSED, NetworkLifecycleCodec.SessionEnd.HOST_CLOSED],
	]:
		var client := _client_for_end()
		var ended: Array = []
		client.session_ended.connect(func(reason: int) -> void: ended.append(reason))
		client._handle_client_packet(1, NetworkFrame.Family.SESSION_CLOSE, NetworkLifecycleCodec.encode_session_close_host(NetworkFrame.Reason.SESSION_CLOSED, int(case[0]), 3, 100))
		_check(ended == [int(case[1])] and client.state == NetworkSessionManager.SessionState.OFFLINE, "a host notice ends the client session with its reason (%d)" % int(case[0]))
		client.free()
	var malformed := _client_for_end()
	var malformed_ended: Array = []
	malformed.session_ended.connect(func(reason: int) -> void: malformed_ended.append(reason))
	malformed._handle_client_packet(1, NetworkFrame.Family.SESSION_CLOSE, PackedByteArray([1, 2]))
	_check(malformed_ended == [NetworkLifecycleCodec.SessionEnd.HOST_LOST], "a malformed host notice still ends the session as HOST_LOST")
	malformed.free()
	var lost := _client_for_end()
	var lost_ended: Array = []
	lost.session_ended.connect(func(reason: int) -> void: lost_ended.append(reason))
	lost._on_peer_disconnected(1)
	_check(lost_ended == [NetworkLifecycleCodec.SessionEnd.HOST_LOST], "a transport loss with no notice reads as the host being lost")
	lost.free()
	var leaver := _client_for_end()
	var leaver_ended: Array = []
	leaver.session_ended.connect(func(reason: int) -> void: leaver_ended.append(reason))
	leaver.stop_session()
	_check(leaver_ended == [NetworkLifecycleCodec.SessionEnd.CLIENT_LEFT], "a client that leaves reports CLIENT_LEFT")
	leaver.free()
	# Host: the notice carries the reason and the last ledger revision.
	var fixture: Dictionary = await _host_fixture()
	var manager: CaptureManager = fixture.manager
	manager._pending_end_reason = NetworkLifecycleCodec.SessionEnd.LOBBY_RETURN
	(fixture.room as StubRoom).result_ledger.reset(2)
	(fixture.room as StubRoom).result_ledger.commit_sudden_death_result(12, 1, 1, 0, false)
	var notice := NetworkLifecycleCodec.decode_session_close_host(manager._host_close_payload())
	_check(bool(notice.ok) and int(notice.end) == NetworkLifecycleCodec.SessionEnd.LOBBY_RETURN and int(notice.ledger_revision) == 1, "the host's close notice names the end reason and the last ledger revision")
	manager._pending_end_reason = NetworkLifecycleCodec.SessionEnd.NONE
	_check(int(NetworkLifecycleCodec.decode_session_close_host(manager._host_close_payload()).end) == NetworkLifecycleCodec.SessionEnd.HOST_CLOSED, "a host that says nothing closes with HOST_CLOSED")
	await _free_host_fixture(fixture)
	# Deliberate Leave: the seat forfeits at once; a lost connection keeps the 60 s reservation.
	var leave_fixture: Dictionary = await _host_fixture()
	var host: CaptureManager = leave_fixture.manager
	var seat: int = leave_fixture.remote_seat
	host.match_active = true
	host.candidates[REMOTE_PEER] = _acknowledged_candidate(leave_fixture)
	host._handle_host_packet(REMOTE_PEER, NetworkFrame.Family.SESSION_CLOSE, PackedByteArray([0, 0]))
	_check(host.reservations.is_reserved(seat) and host.reservations.take_expired(Time.get_ticks_msec() + 1).has(seat), "a deliberate Leave forfeits the seat for the next safe boundary")
	_check(not host.candidates.has(REMOTE_PEER), "the leaving peer is removed")
	await _free_host_fixture(leave_fixture)
	var drop_fixture: Dictionary = await _host_fixture()
	var dropped: CaptureManager = drop_fixture.manager
	dropped.match_active = true
	dropped.candidates[REMOTE_PEER] = _acknowledged_candidate(drop_fixture)
	dropped._on_peer_disconnected(REMOTE_PEER)
	_check(dropped.reservations.is_reserved(drop_fixture.remote_seat) and dropped.reservations.remaining_ms(drop_fixture.remote_seat, Time.get_ticks_msec()) > 50000, "a lost connection still holds the seat for about 60 seconds")
	await _free_host_fixture(drop_fixture)


func _test_teardown_counts() -> void:
	var fixture: Dictionary = await _host_fixture()
	var manager: CaptureManager = fixture.manager
	var room: StubRoom = fixture.room
	manager.state = NetworkSessionManager.SessionState.LOBBY_OPEN
	manager.match_active = true
	manager.session_epoch = 77
	manager._match_lineage = 4
	manager.active_match_id = 4
	manager._pending_continuous[REMOTE_PEER] = {}
	manager._pending_actions[REMOTE_PEER] = []
	manager._action_request_cache[REMOTE_PEER] = {"1": {}}
	manager._result_action_cache[REMOTE_PEER] = {"1": true}
	manager._peer_abuse[REMOTE_PEER] = {}
	manager._sequences["51:19"] = 3
	manager._incoming_sequences["51:19"] = 3
	manager._pending_snapshot_peers[REMOTE_PEER] = true
	manager._snapshot_retry_counts[REMOTE_PEER] = 1
	manager._known_stage_entity_ids = {1: true}
	manager._last_event_signature = "x"
	manager._client_input_sequence = 12
	manager._client_pending_hint = 2
	manager._snapshot_request_count = 2
	manager._retired_epochs[5] = 1
	manager._rekey_pending[REMOTE_PEER] = 1
	room.result_ledger.reset(4)
	room.result_ledger.commit_sudden_death_result(12, 1, 1, 0, false)
	manager.stop_session()
	var counts := manager.teardown_counts()
	var leftovers: Array = []
	for key in counts:
		if int(counts[key]) != 0:
			leftovers.append("%s=%s" % [key, str(counts[key])])
	_check(manager.state == NetworkSessionManager.SessionState.OFFLINE and leftovers.is_empty(), "a stopped session retains nothing: %s" % str(leftovers))
	_check(manager._last_event_signature.is_empty() and manager._client_input_sequence == 0 and manager._client_pending_hint == -1 and manager._snapshot_request_count == 0, "the counters earlier phases left behind are reset")
	_check(not room.network_mode and not room.network_host_commands and not room.network_replay_handler.is_valid(), "a room that outlives the session returns to its offline behavior")
	# A lost peer leaves no per-peer table entry behind.
	var peer_fixture: Dictionary = await _host_fixture()
	var host: CaptureManager = peer_fixture.manager
	host.candidates[REMOTE_PEER] = _acknowledged_candidate(peer_fixture)
	host._peer_abuse[REMOTE_PEER] = {}
	host._pending_snapshot_peers[REMOTE_PEER] = true
	host._snapshot_retry_counts[REMOTE_PEER] = 2
	host._result_action_cache[REMOTE_PEER] = {"1": true}
	host._sequences["51:19"] = 4
	host._on_peer_disconnected(REMOTE_PEER)
	_check(not host._peer_abuse.has(REMOTE_PEER) and not host._pending_snapshot_peers.has(REMOTE_PEER) and not host._snapshot_retry_counts.has(REMOTE_PEER) and not host._result_action_cache.has(REMOTE_PEER) and host._sequences.is_empty(), "a disconnect erases the peer's abuse, snapshot, result and sequence entries")
	await _free_host_fixture(peer_fixture)
	await _free_host_fixture(fixture)


func _test_offline_defaults_and_source_audit() -> void:
	var room := P09MatchLifecycleRoom.new()
	_check(not room.network_mode and not room.network_host_commands and not room.network_replay_handler.is_valid(), "an offline room has every network hook off")
	_check(int(room.network_vote_state().event_id) == 0 and room.result_ledger.revision() == 0, "an offline room has an empty ledger and no vote")
	room.free()
	var source := FileAccess.get_file_as_string("res://scripts/network/network_session_manager.gd")
	_check(not source.contains("active_match_id = 1\n"), "no hard-coded match ID 1 remains in the session manager")
	_check(source.contains("_match_lineage += 1"), "the match ID is a host-lineage counter")
	var frame_source := FileAccess.get_file_as_string("res://scripts/network/network_frame.gd")
	for name in ["RESULT_EVENT", "RESULT_ACTION", "RESULT_VOTE", "REKEY", "REKEY_ACK"]:
		_check(source.contains("NetworkFrame.Family.%s" % name) and frame_source.contains(name), "family %s is declared and handled" % name)
	_check(source.contains("Family.RESULT_EVENT, NetworkFrame.Family.RESULT_VOTE, NetworkFrame.Family.REKEY:"), "the host refuses the host-only families from a client")


# --- fixtures and helpers --------------------------------------------------------------------


func _host_fixture() -> Dictionary:
	var host := SimulationAuthority.host()
	var router := LocalInputRouter.new()
	root.add_child(router)
	router.set_authority(host)
	var manager := CaptureManager.new()
	manager.configure(router)
	root.add_child(manager)
	manager.host_authority = host
	manager.remote_adapter.configure(router, host)
	router.registry.join_keyboard("K1")
	var remote_seat := manager.remote_adapter.assign_source(REMOTE_SOURCE)
	manager.reservations.issue(remote_seat)
	manager.active_match_id = 7
	manager.match_active = true
	var room := StubRoom.new()
	room.input_router = router
	manager.match_room = room
	manager.bind_match_room(room)
	manager.candidates[REMOTE_PEER] = {
		"state": NetworkSessionManager.CandidateState.ACKNOWLEDGED,
		"seat": remote_seat,
		"peer_generation": GENERATION,
		"deadline": 0,
		"claim_seat": -1,
		"match_sync_ready": false,
	}
	room.match_run_id = 3
	await process_frame
	return {"manager": manager, "router": router, "remote_seat": remote_seat, "room": room}


func _acknowledged_candidate(fixture: Dictionary) -> Dictionary:
	return {
		"state": NetworkSessionManager.CandidateState.ACKNOWLEDGED,
		"seat": int(fixture.remote_seat),
		"peer_generation": GENERATION,
		"deadline": 0,
		"claim_seat": -1,
		"match_sync_ready": true,
	}


func _free_host_fixture(fixture: Dictionary) -> void:
	paused = false
	var room := fixture.room as Node
	if is_instance_valid(room):
		room.free()
	(fixture.manager as Node).queue_free()
	(fixture.router as Node).queue_free()
	await process_frame


func _client_for_end() -> CaptureManager:
	var router := LocalInputRouter.new()
	root.add_child(router)
	var client := CaptureManager.new()
	client.configure(router)
	root.add_child(client)
	client.client_mode = true
	client.state = NetworkSessionManager.SessionState.LOBBY_OPEN
	client.match_active = true
	client.active_match_id = 2
	return client


func _sent_family(manager: CaptureManager, family: int) -> Array:
	var payloads: Array = []
	for entry in manager.sent:
		if int(entry.family) == family:
			payloads.append(entry.payload)
	return payloads


func _count_reason(manager: CaptureManager, reason: int) -> int:
	var count := 0
	for payload in _sent_family(manager, NetworkFrame.Family.ADMISSION_DECISION):
		if manager._read_u16(payload) == reason:
			count += 1
	return count


func _finished(seat: int, tick: int) -> Dictionary:
	return {"seat_index": seat, "outcome": "finished", "physics_tick": tick, "event_id": "g%d" % seat, "source_item_id": "", "direct_owner_seat": -1, "cause": "goal"}


func _eliminated(seat: int, tick: int, cause: String, owner: int) -> Dictionary:
	return {"seat_index": seat, "outcome": "eliminated", "physics_tick": tick, "event_id": "x%d" % seat, "source_item_id": "" if owner < 0 else "trap.%d" % owner, "direct_owner_seat": owner, "cause": cause}


func _record(seat: int, tick: int, time: float) -> Dictionary:
	return {"seat_index": seat, "physics_tick": tick, "physics_time": time, "time_comparable": true}


func _patibongs(count: int) -> Array:
	var awards: Array = []
	for index in count:
		awards.append({"key": NetworkResultsCodec.AwardKey.PATIBONG, "units": 2})
	return awards


## A valid two-seat race round entry: seat 0 earns Tapos + Una (10 units), seat 1 is eliminated.
func _sample_round_entry(match_id: int, attempt: int, round_id: int, _unused: int) -> Dictionary:
	return {
		"kind": NetworkResultsCodec.Kind.ROUND,
		"match_id": match_id,
		"round_id": round_id,
		"attempt_id": attempt,
		"event_id": 1,
		"revision": 1,
		"family": NetworkResultsCodec.ScoringFamily.RACE,
		"suppression": NetworkResultsCodec.Suppression.NONE,
		"finisher_count": 1,
		"first_mask": 1,
		"last_cluck_seat": -1,
		"barya_seat": -1,
		"decision": NetworkResultsCodec.Decision.CONTINUE,
		"winner_seat": -1,
		"tied_mask": 0,
		"terminal_reason": NetworkResultsCodec.Terminal.NONE,
		"seats": [
			{"seat": 0, "outcome": 1, "cause": 1, "owner": -1, "placement": 0, "delta": 10, "total": 10, "awards": [{"key": 1, "units": 8}, {"key": 2, "units": 2}]},
			{"seat": 1, "outcome": 2, "cause": 4, "owner": -1, "placement": 0, "delta": 0, "total": 0, "awards": []},
		],
	}


## Breaks exactly one field of a valid entry, named by `label` (see MUTATION_LABELS).
func _mutate_entry(entry: Dictionary, label: String) -> void:
	match label:
		"unknown kind":
			entry.kind = 9
		"zero match":
			entry.match_id = 0
		"event id over 128":
			entry.event_id = 129
		"unknown scoring family":
			entry.family = 7
		"unknown suppression":
			entry.suppression = 3
		"unknown decision":
			entry.decision = 4
		"winner on a continue":
			entry.winner_seat = 0
		"terminal reason on a continue":
			entry.terminal_reason = 1
		"one seat only":
			entry.seats.resize(1)
		"duplicate seat":
			entry.seats[1].seat = 0
		"seat out of range":
			entry.seats[1].seat = 4
		"unknown cause":
			entry.seats[0].cause = 11
		"unknown award key":
			entry.seats[0].awards[0].key = 8
		"delta is not the award sum":
			entry.seats[0].delta = 9
		"negative total":
			entry.seats[0].total = -1
		"owner out of range":
			entry.seats[0].owner = 4
		"first mask outside the seats":
			entry.first_mask = 8


func _check(condition: bool, label: String) -> void:
	checks += 1
	if condition:
		print("PASS ", label)
	else:
		failures += 1
		push_error("FAIL " + label)

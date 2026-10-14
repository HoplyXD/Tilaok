extends SceneTree

const P07_SCENE := preload("res://scenes/match/p07_first_playable_room.tscn")
const VARIANT := "build.hollow_blocks.cell_1x1"
const RESET_COUNT := 10

var checks := 0
var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var room := P07_SCENE.instantiate() as P07FirstPlayableMatchRoom
	root.add_child(room)
	await _wait_physics_frames(3)
	room.join_keyboard("K1")
	room.join_keyboard("K2")
	room.input_router.registry.set_ready(0, true)
	room.input_router.registry.set_ready(1, true)
	_check(room.start_match(), "synthetic reset audit starts a two-seat P07 match")

	var retained_id := ""
	var removed_id := ""
	var added_id := ""
	var expected_ids: Array[String] = []
	var last_scores: Dictionary = room.cumulative_score_units.duplicate(true)

	for round_index in range(RESET_COUNT):
		if room.phase_controller.phase != MatchPhaseController.Phase.PUGAD:
			_fail("round %d did not begin in Pugad" % (round_index + 1))
			break
		room._finish_pugad_timeout()
		_check(
			room.phase_controller.phase == MatchPhaseController.Phase.PLACE,
			"round %d enters Place through the existing timeout path" % (round_index + 1)
		)

		if round_index == 0:
			var retained := room.items.place(VARIANT, Vector2i(8, 8), 0, 0)
			var removed := room.items.place(VARIANT, Vector2i(10, 8), 0, 1)
			_check(
				bool(retained.get("allowed", false)), "first persistent construction is accepted"
			)
			_check(bool(removed.get("allowed", false)), "removal probe construction is accepted")
			retained_id = str(retained.get("instance_id", ""))
			removed_id = str(removed.get("instance_id", ""))
			var removal := room.items.remove(removed_id, "p07_reset_probe")
			_check(bool(removal.get("allowed", false)), "removed-piece probe is removed in Place")
			expected_ids = [retained_id]
		elif round_index == 2:
			var addition := room.items.place(VARIANT, Vector2i(12, 8), 0, 1)
			_check(
				bool(addition.get("allowed", false)), "legitimate later construction is accepted"
			)
			added_id = str(addition.get("instance_id", ""))
			expected_ids.append(added_id)

		room._enter_play()
		_check(
			room.phase_controller.phase == MatchPhaseController.Phase.PLAY,
			"round %d enters Play" % (round_index + 1)
		)
		var goal_position := room.goal_area.global_position
		for actor_variant in room.actors.values():
			(actor_variant as ChickenController).global_position = goal_position
		await _wait_physics_frames(4)
		_check(
			room.phase_controller.phase == MatchPhaseController.Phase.RESULTS,
			"round %d reaches scored results from the actual goal trigger" % (round_index + 1)
		)
		if room.phase_controller.phase != MatchPhaseController.Phase.RESULTS:
			break

		var totals_after_commit := room.cumulative_score_units.duplicate(true)
		var ledger := room.race_round_controller.ledger
		_check(ledger.score_committed, "round %d commits its score once" % (round_index + 1))
		_check(
			not ledger.commit_score_once(ledger.round_id, ledger.score_commit),
			"round %d rejects duplicate ledger score commit" % (round_index + 1)
		)
		room._finish_race("duplicate results callback probe")
		_check(
			room.cumulative_score_units == totals_after_commit,
			"round %d duplicate results callback leaves totals unchanged" % (round_index + 1)
		)
		_check(
			totals_after_commit != last_scores,
			"round %d produced a new cumulative score result" % (round_index + 1)
		)
		last_scores = totals_after_commit.duplicate(true)

		var audit_before := room.reset_audit_rows.size()
		room._start_next_round()
		_check(
			room.reset_audit_rows.size() == audit_before + 1,
			"round %d recorded one next-round reset" % (round_index + 1)
		)
		var row: Dictionary = {}
		if room.reset_audit_rows.size() == audit_before + 1:
			row = room.reset_audit_rows.back()
		if not row.is_empty():
			_check(
				bool(row.construction_preserved),
				"reset %d preserves construction IDs" % (round_index + 1)
			)
			_check(
				bool(row.signature_preserved),
				"reset %d preserves construction signature" % (round_index + 1)
			)
			_check(
				bool(row.scores_preserved),
				"reset %d preserves cumulative scores" % (round_index + 1)
			)
			_check(bool(row.actors_reset), "reset %d reactivates all actors" % (round_index + 1))
			_check(
				bool(row.transients_cleared), "reset %d clears transient state" % (round_index + 1)
			)
			_check(
				row.after.item_ids == expected_ids,
				"reset %d retains only legitimately placed item IDs" % (round_index + 1)
			)
			_check(
				not row.after.item_ids.has(removed_id),
				"reset %d does not resurrect removed construction" % (round_index + 1)
			)
			_check(
				row.after.race_candidates == 0 and row.after.pending_claims == 0,
				"reset %d clears queued race and egg-claim callbacks" % (round_index + 1)
			)

	_check(
		room.reset_audit_rows.size() == RESET_COUNT, "exactly ten next-round resets are recorded"
	)
	_check(
		room.items.persistent_count() == expected_ids.size(),
		"final construction count matches legitimate placements"
	)
	_check(room.items.pieces.has(retained_id), "original persistent construction remains")
	_check(not room.items.pieces.has(removed_id), "removed piece stays absent after all resets")
	if not added_id.is_empty():
		_check(room.items.pieces.has(added_id), "later legitimate construction remains")
	var recorded_reset_count := room.reset_audit_rows.size()
	room.reset_room()
	_check(room.items.persistent_count() == 0, "full match reset clears retained construction")
	_check(
		room.cumulative_score_units.is_empty(), "full match reset clears cumulative score totals"
	)
	print(
		(
			"P07_RESET_AUTOMATION resets=%d checks=%d failures=%d participants=synthetic"
			% [recorded_reset_count, checks, failures.size()]
		)
	)
	for failure in failures:
		push_error(failure)
	room.queue_free()
	await process_frame
	quit(1 if not failures.is_empty() else 0)


func _wait_physics_frames(count: int) -> void:
	for _frame in range(count):
		await physics_frame


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		_fail(message)


func _fail(message: String) -> void:
	failures.append(message)

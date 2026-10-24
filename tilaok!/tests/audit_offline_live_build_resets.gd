# gdlint: disable=max-file-lines,max-public-methods,max-returns
extends SceneTree

## Ten synthetic live-route start/play/reset cycles with state and Godot runtime monitors.

const LIVE_SCENE := preload("res://scenes/match/offline_live_build_room.tscn")
const CELL_1X1 := "build.hollow_blocks.cell_1x1"

var room: OfflineLiveBuildMatchRoom
var failures := 0
var rows: Array[Dictionary] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	room = LIVE_SCENE.instantiate() as OfflineLiveBuildMatchRoom
	root.add_child(room)
	await process_frame
	room.join_keyboard("K1")
	room.join_keyboard("K2")
	room.build_phase_seconds = 0.001
	room.tuning.match_target_score_units = 100000
	for cycle in range(1, 11):
		room.input_router.registry.set_ready(0, true)
		room.input_router.registry.set_ready(1, true)
		_check(room.start_match(), "cycle %d starts from Lobby" % cycle)
		_claim_distinct_eggs()
		_check(
			room.phase_controller.phase == MatchPhaseController.Phase.BUILD,
			"cycle %d resolves Pugad into shared BUILD" % cycle
		)
		room._physics_process(0.01)
		_check(
			room.phase_controller.phase == MatchPhaseController.Phase.PLAY and room.items.in_play,
			"cycle %d starts active Play directly after BUILD" % cycle
		)
		var item_result := _place_one_item()
		_check(
			bool(item_result.get("allowed", false)), "cycle %d commits live construction" % cycle
		)
		room.build_mode[0] = true
		room.inventory_used[0] = true
		var intent := _make_pending_request(cycle)
		var queued := room.request_pipeline.submit(
			intent, 0, Time.get_ticks_usec(), Engine.get_physics_frames() + 10, [0, 1]
		)
		_check(str(queued.status) == "pending", "cycle %d queues a request before close" % cycle)
		var before_reset := _snapshot()
		room.phase_controller.enter(MatchPhaseController.Phase.RESULTS)
		room.reset_room()
		await process_frame
		await physics_frame
		var after_reset := _snapshot()
		_check(
			(
				room.phase_controller.phase == MatchPhaseController.Phase.LOBBY
				and room.items.pieces.is_empty()
				and room.items.live_activation.is_empty()
				and room.construction_jobs.is_empty()
				and room._reserved_footprints.is_empty()
				and room.request_pipeline.pending.is_empty()
				and room.request_pipeline.request_records.is_empty()
				and room.inventory_used.is_empty()
				and room.build_mode.is_empty()
			),
			"cycle %d clears pending/live state and returns to Lobby" % cycle
		)
		_check(_actors_are_active(), "cycle %d retains both seats as active" % cycle)
		(
			rows
			. append(
				{
					"cycle": cycle,
					"before_reset": before_reset,
					"after_reset": after_reset,
					"pending_requests": room.request_pipeline.pending.size(),
					"dedupe_records": room.request_pipeline.request_records.size(),
					"inventory": room.inventory_used.duplicate(true),
					"live_activation": room.items.live_activation.size(),
					"round": room.items.round_number,
				}
			)
		)
	print("OFFLINE_LIVE_RESET_LEDGER %s" % JSON.stringify(rows))
	print(
		(
			"OFFLINE_LIVE_RESET_AUDIT cycles=%d failures=%d input=synthetic seats=2"
			% [rows.size(), failures]
		)
	)
	room.queue_free()
	await process_frame
	quit(1 if failures > 0 else 0)


func _claim_distinct_eggs() -> void:
	for seat_index in [0, 1]:
		var egg: Dictionary = room.egg_pool[seat_index]
		egg.variant_key = CELL_1X1
		room.egg_pool[seat_index] = egg
		room._queue_claim(seat_index, str(egg.egg_id))
	room._flush_claims()


func _place_one_item() -> Dictionary:
	var actors_now := room._live_actor_swept_rects()
	var clearance := room.items.owner_seat_clearance(actors_now)
	var cursor: Dictionary = room.placement_controller.cursors[0]
	cursor.variant_key = CELL_1X1
	for y in range(room.tuning.arena_height_tiles):
		for x in range(room.tuning.arena_width_tiles):
			var cell := Vector2i(x, y)
			var verdict := room.items.validate_placement(CELL_1X1, cell, 0, clearance)
			if not bool(verdict.get("allowed", false)):
				continue
			cursor.cell = cell
			room.placement_controller.cursors[0] = cursor
			var intent := _make_pending_request(0)
			var started := room._start_construction_job(0, intent, Engine.get_physics_frames())
			if bool(started.get("allowed", false)):
				room.inventory_used[0] = true
				room._advance_construction_jobs(room.construction_seconds)
				return {
					"allowed":
					(
						room.items.persistent_count() == 1
						and room.items.stage_version == 1
						and room.construction_jobs.is_empty()
						and room._reserved_footprints.is_empty()
					)
				}
	return {"allowed": false, "reason": "No safe live cell found."}


func _make_pending_request(cycle: int) -> Dictionary:
	var record := room.request_pipeline
	return {
		"request_id": "cycle_%d_pending" % cycle,
		"match_id": record.match_id,
		"round_id": record.round_id,
		"attempt_id": record.attempt_id,
		"observed_stage_version": room.items.stage_version,
		"variant_key": CELL_1X1,
		"cell": Vector2i(10, 6),
		"quarter_turns": 0,
	}


func _snapshot() -> Dictionary:
	return {
		"phase": MatchPhaseController.Phase.keys()[room.phase_controller.phase],
		"items": room.items.persistent_count(),
		"item_ids": room.items.pieces.keys(),
		"stage_version": room.items.stage_version,
		"pending": room.request_pipeline.pending.size(),
		"dedupe": room.request_pipeline.request_records.size(),
		"inventory_used": room.inventory_used.duplicate(true),
		"build_mode": room.build_mode.duplicate(true),
		"activation": room.items.live_activation.size(),
		"construction_jobs": room.construction_jobs.size(),
		"reservations": room._reserved_footprints.size(),
		"round": room.items.round_number,
		"clock": room.phase_controller.remaining_seconds,
		"objects": Performance.get_monitor(Performance.OBJECT_COUNT),
		"nodes": Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
		"static_memory_bytes": Performance.get_monitor(Performance.MEMORY_STATIC),
		"static_memory_peak_bytes": Performance.get_monitor(Performance.MEMORY_STATIC_MAX),
	}


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS %s" % label)
	else:
		failures += 1
		printerr("FAIL %s" % label)


func _actors_are_active() -> bool:
	for actor_variant in room.actors.values():
		var actor := actor_variant as ChickenController
		if actor == null or actor.lifecycle.status != PlayerLifecycleState.Status.ACTIVE:
			return false
	return true

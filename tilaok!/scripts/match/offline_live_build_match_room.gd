# gdlint: disable=max-returns,max-public-methods,max-file-lines
class_name OfflineLiveBuildMatchRoom
extends P12ScheduledMatchRoom

## Normal local route. It reuses P12's schedule, objective and terminal rules while allowing one
## assigned item to be constructed during Play.

## Emitted once per physics boundary after the stage version settles, and once when a round closes
## with queued requests (each then carries code "round_ended").
signal live_placement_boundary_resolved(results: Array)

const REQUEST_PIPELINE := preload("res://scripts/match/live_placement_pipeline.gd")
const JOB_PREVIEW := preload("res://scripts/match/construction_job_preview.gd")
@export_range(1.0, 10.0, 0.25) var go_countdown_seconds := 3.0
@export_range(1.0, 30.0, 0.25) var build_phase_seconds := 10.0
@export_range(0.1, 10.0, 0.1) var construction_seconds := 2.0
@export_range(1.0, 32.0, 1.0) var live_cursor_cells_per_second := 8.0
@export_range(0.0, 1.0, 0.05) var live_cursor_initial_delay := 0.25
@export_range(0.0, 64.0, 1.0) var live_actor_clearance_wu := 32.0
## Rows of cells below a movable block that must be free of chickens (fall path; never crush).
@export_range(0, 8, 1) var live_fall_check_cells := 2

var request_pipeline := REQUEST_PIPELINE.new()
var build_mode: Dictionary = {}
var inventory_used: Dictionary = {}
var live_notices: Dictionary = {}
var construction_jobs: Dictionary = {}
var _aim_repeat: Dictionary = {}
var _request_serial := 0
var _go_remaining := 0.0
var _go_start_pending := false
var _live_admission_open := false
var _edge_layer: CanvasLayer
var _edge_root: Control
var _edge_markers: Dictionary = {}
var _reserved_footprints: Dictionary = {}
var _construction_clock := 0.0


func _init() -> void:
	profile_id = "karera_slice"


func pugad_excluded_variant_keys() -> PackedStringArray:
	return PackedStringArray()


func _ready() -> void:
	super._ready()
	_edge_layer = CanvasLayer.new()
	_edge_layer.name = "LiveBuildEdgeMarkers"
	_edge_layer.layer = 24
	add_child(_edge_layer)
	_edge_root = Control.new()
	_edge_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_edge_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_edge_layer.add_child(_edge_root)


func _exit_tree() -> void:
	_cancel_all_construction_jobs(false)
	_close_live_attempt()
	if input_router != null:
		input_router.live_build_confirm_enabled = false
	super._exit_tree()


func _process(delta: float) -> void:
	super._process(delta)
	if get_tree().paused or not _simulation_can_commit():
		return
	if (
		phase_controller.phase
		in [MatchPhaseController.Phase.BUILD, MatchPhaseController.Phase.PLAY]
	):
		_advance_live_aim(delta)
		_update_edge_markers()


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if get_tree().paused or not _simulation_can_commit():
		return
	# Same-tick order: super resolves this tick's terminal outcomes first, including Kangaroo Rising
	# against the support tracker and Freeze/Hug against local input edges and contacts. Jobs resolve
	# after that, so every
	# evaluation sees exactly the edits accepted before its tick; a removal invalidates support at
	# once (P12 table C8). Build aim/rotate/confirm are not movement edges, so they never become
	# Freeze intent, and building never changes a chicken's eligibility or Hug contacts.
	if (
		phase_controller.phase
		in [MatchPhaseController.Phase.BUILD, MatchPhaseController.Phase.PLAY]
	):
		_resolve_live_placement_boundary()
		_advance_construction_jobs(delta)
		if phase_controller.phase == MatchPhaseController.Phase.BUILD:
			_advance_preparation_phase(delta)
		elif phase_controller.phase == MatchPhaseController.Phase.PLAY:
			return
	elif phase_controller.phase == MatchPhaseController.Phase.GO:
		_advance_construction_jobs(delta)
		var go_finished := phase_controller.advance(delta)
		_go_remaining = phase_controller.remaining_seconds
		last_message = "GO • %d" % ceili(_go_remaining)
		_notify_presentation(&"live_build")
		if go_finished and not _go_start_pending:
			_go_start_pending = true
			_start_live_play.call_deferred()
	else:
		# The terminal round result (resolved in super) closes admission before any queued edit.
		_close_live_attempt()
		_cancel_all_construction_jobs(false)


func _advance_preparation_phase(delta: float) -> void:
	if phase_controller.advance(delta):
		_close_live_admission()
		phase_controller.enter(MatchPhaseController.Phase.GO, go_countdown_seconds)
		_go_remaining = go_countdown_seconds
		input_router.set_phase(LocalInputRouter.Phase.GO)
		for seat_variant in build_mode.keys():
			_set_live_ghost_visible(int(seat_variant), false)
		last_message = "GO • movement and live building begin after the countdown."
		_notify_presentation(&"live_build")
		_refresh_match_ui()


func _close_live_admission() -> void:
	_live_admission_open = false


func _enter_place() -> void:
	if not _simulation_can_commit() or phase_controller.phase != MatchPhaseController.Phase.PUGAD:
		return
	var seats: Array[int] = []
	for seat in input_router.registry.joined_seats():
		seats.append(int(seat.seat))
	if seats.size() < 2 or assignments.size() != seats.size():
		last_message = "Pugad could not assign a distinct egg to every seat. Returning to Lobby."
		reset_room()
		last_message = "Pugad assignment failed: there were not enough distinct eggs."
		_refresh_match_ui()
		return
	items.enter_place()
	var claimed_variants := _claimed_variants_by_seat()
	_on_place_assignments_ready(claimed_variants)
	# Initialize map-derived cursor bounds and the spawn anchor, as the scheduled Place route does.
	# The fixed fallback can be outside a custom map's build region and make every confirm fail.
	placement_controller.build_region_tiles = _build_region_tiles()
	placement_controller.start_anchor_tile = _build_start_anchor_tile()
	placement_controller.setup(claimed_variants, definitions, tuning)
	for seat_index in seats:
		_set_build_mode(seat_index, true)
		inventory_used[seat_index] = false
		live_notices.erase(seat_index)
		_aim_repeat[seat_index] = {"elapsed": 0.0, "first": true, "direction": Vector2.ZERO}
	input_router.set_rotation_supported(false)
	# Keyboard south keys (R, Enter, O, Num 0) confirm in the preparation and live-build phases.
	input_router.live_build_confirm_enabled = true
	phase_controller.enter(MatchPhaseController.Phase.BUILD, build_phase_seconds)
	input_router.set_phase(LocalInputRouter.Phase.BUILD)
	current_context = BoundedStageCamera.Context.PLAY
	camera_rig.set_context(current_context)
	_free_match_ghosts()
	for seat_index in seats:
		_add_match_ghost(seat_index)
		_create_edge_marker(seat_index)
		_set_live_ghost_visible(seat_index, true)
	request_pipeline.begin_attempt(match_run_id, items.round_number + 1, items.stage_version)
	_live_admission_open = true
	print("OFFLINE_LIVE_PUGAD seed=%d assignments=%s" % [match_seed, JSON.stringify(assignments)])
	last_message = "BUILD • place now, or save your item for play."
	_notify_presentation(&"live_build")
	_refresh_match_ui()


func _start_live_play() -> void:
	if phase_controller.phase != MatchPhaseController.Phase.GO:
		return
	# P12 starts the locked Main/Twist here. Its existing taya freeze and immunity stay authoritative.
	super._enter_play()
	if phase_controller.phase != MatchPhaseController.Phase.PLAY:
		return
	for seat_index in placement_controller.cursors.keys():
		_set_build_mode(int(seat_index), false)
		if bool(inventory_used.get(int(seat_index), false)):
			continue
		if not _ghosts.has(int(seat_index)):
			_add_match_ghost(int(seat_index))
		(_ghosts[int(seat_index)] as ItemGhost).visible = false
		_create_edge_marker(int(seat_index))
	_live_admission_open = true
	_go_start_pending = false
	_refresh_match_ui()


func _start_sudden_death(decision: Dictionary) -> void:
	_live_admission_open = false
	for seat_variant in build_mode.keys():
		var seat_index := int(seat_variant)
		_set_build_mode(seat_index, false)
		_set_live_ghost_visible(seat_index, false)
	super._start_sudden_death(decision)


func _on_match_navigation_step(seat_index: int, direction: String) -> void:
	if phase_controller.phase == MatchPhaseController.Phase.PUGAD:
		super._on_match_navigation_step(seat_index, direction)
		return
	if phase_controller.phase == MatchPhaseController.Phase.BUILD:
		if bool(build_mode.get(seat_index, false)):
			var step := Vector2i.ZERO
			match direction:
				"left":
					step = Vector2i.LEFT
				"right":
					step = Vector2i.RIGHT
				"up":
					step = Vector2i.UP
				"down":
					step = Vector2i.DOWN
			if step != Vector2i.ZERO:
				_move_live_cursor(seat_index, step)


func _advance_live_aim(delta: float) -> void:
	for seat_variant in placement_controller.cursors.keys():
		var seat_index := int(seat_variant)
		if (
			not bool(build_mode.get(seat_index, false))
			or bool(inventory_used.get(seat_index, false))
		):
			continue
		var actor := actors.get(seat_index) as ChickenController
		if actor == null or actor.lifecycle.is_terminal():
			_set_build_mode(seat_index, false)
			_set_live_ghost_visible(seat_index, false)
			live_notices[seat_index] = "Build mode closed • this chicken is out."
			continue
		var direction := input_router.live_aim_vector(seat_index)
		if direction == Vector2.ZERO:
			_aim_repeat[seat_index] = {"elapsed": 0.0, "first": true, "direction": Vector2.ZERO}
			continue
		var state: Dictionary = _aim_repeat.get(seat_index, {})
		if direction != state.get("direction", Vector2.ZERO):
			state = {"elapsed": 0.0, "first": true, "direction": direction}
			_aim_repeat[seat_index] = state
			_move_live_cursor(seat_index, _dominant_step(direction))
			continue
		state.elapsed = float(state.elapsed) + delta
		var delay := (
			live_cursor_initial_delay if bool(state.first) else 1.0 / live_cursor_cells_per_second
		)
		if float(state.elapsed) >= delay:
			state.elapsed = float(state.elapsed) - delay
			state.first = false
			_move_live_cursor(seat_index, _dominant_step(direction))
		_aim_repeat[seat_index] = state


func _dominant_step(direction: Vector2) -> Vector2i:
	if absf(direction.x) >= absf(direction.y):
		return Vector2i.RIGHT if direction.x > 0.0 else Vector2i.LEFT
	return Vector2i.DOWN if direction.y > 0.0 else Vector2i.UP


## Entering build mode puts the block on the tile beside this player, so it appears where the
## chicken is standing rather than wherever the cursor was left last time.
func _snap_cursor_to_seat(seat_index: int) -> void:
	var actor := actors.get(seat_index) as ChickenController
	if actor == null or not is_instance_valid(actor):
		return
	var cell := tuning.grid_cell_wu
	if cell <= 0.0:
		return
	var feet := actor.global_position.y + tuning.body_height_wu * 0.5
	var tile := Vector2i(floori(actor.global_position.x / cell), maxi(0, floori(feet / cell) - 1))
	if placement_controller.set_cell(seat_index, tile):
		_refresh_match_ghost(seat_index)
		_notify_presentation(&"live_build")


func _move_live_cursor(seat_index: int, step: Vector2i) -> void:
	if not placement_controller.move(seat_index, step):
		return
	_refresh_match_ghost(seat_index)
	_notify_presentation(&"live_build")


func _on_match_action_pressed(seat_index: int, action_name: String) -> void:
	if seat_index < 0:
		return
	if phase_controller.phase == MatchPhaseController.Phase.GO:
		return
	if (
		phase_controller.phase
		in [MatchPhaseController.Phase.BUILD, MatchPhaseController.Phase.PLAY]
	):
		if (
			phase_controller.phase == MatchPhaseController.Phase.PLAY
			and _sudden_death_active
			and action_name in ["build_toggle", "live_rotate", "live_cancel", "confirm"]
		):
			if bool(build_mode.get(seat_index, false)) or action_name != "confirm":
				return
		match action_name:
			"build_toggle":
				if not bool(inventory_used.get(seat_index, false)):
					_set_build_mode(seat_index, not bool(build_mode.get(seat_index, false)))
					input_router.consume_held_presses_for_seat(seat_index)
					if bool(build_mode[seat_index]):
						_snap_cursor_to_seat(seat_index)
					_set_live_ghost_visible(seat_index, bool(build_mode[seat_index]))
					live_notices[seat_index] = (
						"Build mode on • chicken paused."
						if bool(build_mode[seat_index])
						else "Build mode off."
					)
					_notify_presentation(&"live_build")
			"live_rotate":
				if (
					bool(build_mode.get(seat_index, false))
					and placement_controller.rotate(seat_index)
				):
					_refresh_match_ghost(seat_index)
			"live_cancel", "back":
				if action_name == "live_cancel":
					var active_job_id := _job_id_for_seat(seat_index)
					if not active_job_id.is_empty():
						live_notices[seat_index] = "Build is underway • it will finish automatically."
						_notify_presentation(&"live_build")
						return
				if bool(build_mode.get(seat_index, false)):
					_set_build_mode(seat_index, false)
					_set_live_ghost_visible(seat_index, false)
					live_notices[seat_index] = "Build preview closed."
					_notify_presentation(&"live_build")
				elif action_name == "back":
					super._on_match_action_pressed(seat_index, action_name)
			"confirm":
				if bool(build_mode.get(seat_index, false)):
					_submit_live_placement(seat_index)
		return
	super._on_match_action_pressed(seat_index, action_name)


func _set_live_ghost_visible(seat_index: int, shown: bool) -> void:
	if _ghosts.has(seat_index):
		(_ghosts[seat_index] as ItemGhost).visible = shown
		if shown:
			_refresh_match_ghost(seat_index)
	_update_edge_markers()


func _set_build_mode(seat_index: int, enabled: bool) -> void:
	build_mode[seat_index] = enabled
	if input_router != null:
		input_router.set_build_mode(seat_index, enabled)
	_sync_actor_build_lock(seat_index)


func _sync_actor_build_lock(seat_index: int) -> void:
	var actor := actors.get(seat_index) as ChickenController
	if actor != null and is_instance_valid(actor):
		actor.build_input_locked = (
			(
				phase_controller.phase
				in [MatchPhaseController.Phase.BUILD, MatchPhaseController.Phase.GO]
			)
			or bool(build_mode.get(seat_index, false))
		)


func _create_edge_marker(seat_index: int) -> void:
	if _edge_root == null or _edge_markers.has(seat_index):
		return
	var marker := Label.new()
	marker.name = "Seat%dEdgeAim" % (seat_index + 1)
	marker.add_theme_color_override("font_color", Color(1.0, 0.92, 0.60))
	marker.add_theme_color_override("font_shadow_color", Color(0.08, 0.10, 0.13, 0.95))
	marker.add_theme_constant_override("shadow_offset_x", 2)
	marker.add_theme_constant_override("shadow_offset_y", 2)
	marker.add_theme_font_size_override("font_size", 18)
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker.visible = false
	_edge_root.add_child(marker)
	_edge_markers[seat_index] = marker


func _update_edge_markers() -> void:
	if _edge_root == null or not is_instance_valid(_edge_root):
		return
	var view_size := get_viewport_rect().size
	var view_bounds := Rect2(Vector2.ZERO, view_size).grow(-30.0)
	var canvas := get_viewport().get_canvas_transform()
	for seat_variant in _edge_markers.keys():
		var seat_index := int(seat_variant)
		var marker := _edge_markers[seat_index] as Label
		var shown := (
			(
				phase_controller.phase
				in [MatchPhaseController.Phase.BUILD, MatchPhaseController.Phase.PLAY]
			)
			and bool(build_mode.get(seat_index, false))
			and not bool(inventory_used.get(seat_index, false))
			and placement_controller.cursors.has(seat_index)
		)
		if not shown:
			marker.visible = false
			continue
		var cursor: Dictionary = placement_controller.cursors[seat_index]
		var world_position := (Vector2(cursor.cell) + Vector2(0.5, 0.5)) * tuning.grid_cell_wu
		var screen_position := canvas * world_position
		if view_bounds.has_point(screen_position):
			marker.visible = false
			continue
		var seat := input_router.registry.get_seat(seat_index)
		marker.text = (
			"P%d %s"
			% [
				int(seat.get("identity", seat_index + 1)),
				str(MARKS.get(str(seat.get("shape", "DIAMOND")), "◆")),
			]
		)
		marker.position = Vector2(
			clampf(screen_position.x, 18.0, maxf(18.0, view_size.x - marker.size.x - 18.0)),
			clampf(screen_position.y, 18.0, maxf(18.0, view_size.y - marker.size.y - 18.0))
		)
		marker.visible = true


func _submit_live_placement(seat_index: int) -> void:
	if (
		not _live_admission_open
		or (
			phase_controller.phase
			not in [MatchPhaseController.Phase.BUILD, MatchPhaseController.Phase.PLAY]
		)
		or not bool(build_mode.get(seat_index, false))
		or bool(inventory_used.get(seat_index, false))
		or not placement_controller.cursors.has(seat_index)
	):
		live_notices[seat_index] = "Your assigned item has already been used."
		return
	var cursor: Dictionary = placement_controller.cursors[seat_index]
	var attempt := request_pipeline.attempt_id
	_request_serial += 1
	var request_id := "%s:%d:%d" % [attempt, seat_index, _request_serial]
	var intent := {
		"request_id": request_id,
		"match_id": match_run_id,
		"round_id": items.round_number + 1,
		"attempt_id": attempt,
		"observed_stage_version": items.stage_version,
		"variant_key": str(cursor.variant_key),
		"objective":
		str(cursor.variant_key) if _is_round_objective_variant(str(cursor.variant_key)) else "",
		"cell": cursor.cell,
		"quarter_turns": int(cursor.quarter_turns),
	}
	var occupied: Array[int] = []
	for seat in input_router.registry.joined_seats():
		occupied.append(int(seat.seat))
	var receipt := request_pipeline.submit(
		intent, seat_index, Time.get_ticks_usec(), Engine.get_physics_frames() + 1, occupied
	)
	live_notices[seat_index] = str(receipt.get("reason", "Placement queued."))
	_notify_presentation(&"live_build")


func _resolve_live_placement_boundary() -> void:
	if request_pipeline.attempt_id.is_empty():
		return
	var boundary := Engine.get_physics_frames()
	var requests := request_pipeline.drain_boundary(boundary, items.round_number + 1)
	if requests.is_empty():
		return
	var resolved: Array[Dictionary] = []
	for receipt in requests:
		var request_id := str(receipt.request_id)
		var seat_index := int(receipt.seat_index)
		var intent: Dictionary = receipt.intent
		var result := _start_construction_job(seat_index, intent, boundary)
		resolved.append({"request_id": request_id, "result": result})
		inventory_used[seat_index] = bool(result.get("allowed", false))
		live_notices[seat_index] = str(result.get("reason", "Placement resolved."))
		if bool(result.get("allowed", false)):
			_set_build_mode(seat_index, false)
			_set_live_ghost_visible(seat_index, false)
			live_notices[seat_index] = "Building • %.1f s remaining." % construction_seconds
		else:
			# Keep build mode active after a rejected placement so players can reposition and retry.
			var actor := actors.get(seat_index) as ChickenController
			var still_eligible := (
				actor != null
				and not actor.lifecycle.is_terminal()
				and actor.lifecycle.status != PlayerLifecycleState.Status.CAPTURED
			)
			_set_build_mode(seat_index, still_eligible)
			_set_live_ghost_visible(seat_index, still_eligible)
	var boundary_results: Array = []
	for resolved_row in resolved:
		var result: Dictionary = resolved_row.result
		result.stage_version = items.stage_version
		request_pipeline.resolve_result(str(resolved_row.request_id), result)
		boundary_results.append(result.duplicate(true))
	for seat_variant in placement_controller.cursors.keys():
		_refresh_match_ghost(int(seat_variant))
	live_placement_boundary_resolved.emit(boundary_results)
	_notify_presentation(&"live_build")
	_refresh_match_ui()


## Closes the live attempt. Requests still queued were never validated, so each is answered once
## with "round_ended" and its seat keeps the item; the pipeline is then empty, so repeated calls
## emit nothing.
func _close_live_attempt() -> void:
	var queued := request_pipeline.pending_requests()
	request_pipeline.close_attempt()
	if queued.is_empty():
		return
	var results: Array = []
	for receipt in queued:
		var base := {
			"request_id": str(receipt.request_id),
			"seat_index": int(receipt.seat_index),
			"commit_boundary": Engine.get_physics_frames(),
			"stage_version": items.stage_version if items != null else 0,
		}
		results.append(_live_result(base, false, "round_ended", "The round ended first."))
	live_placement_boundary_resolved.emit(results)


func _start_construction_job(seat_index: int, intent: Dictionary, boundary: int) -> Dictionary:
	if construction_jobs.size() >= 4:
		return _live_result(
			{
				"request_id": str(intent.get("request_id", "")),
				"seat_index": seat_index,
				"commit_boundary": boundary
			},
			false,
			"job_limit",
			"All four construction slots are occupied."
		)
	for job in construction_jobs.values():
		if int(job.get("seat_index", -1)) == seat_index:
			return _live_result(
				{
					"request_id": str(intent.get("request_id", "")),
					"seat_index": seat_index,
					"commit_boundary": boundary
				},
				false,
				"job_active",
				"You already have a construction job."
			)
	var variant_key := str(intent.get("variant_key", ""))
	if not BaryaObjectiveDefinition.is_variant(variant_key):
		var definition := definitions.find_variant(variant_key)
		var family := definition.get("family") as ItemFamilyDefinition
		if family == null:
			return _live_result(
				{
					"request_id": str(intent.get("request_id", "")),
					"seat_index": seat_index,
					"commit_boundary": boundary
				},
				false,
				"content_unverified",
				"This item is not verified for live construction."
			)
	var validation := _commit_live_intent(seat_index, intent, boundary, false)
	if not bool(validation.get("allowed", false)):
		return validation
	var footprint: Rect2 = validation.get("footprint", Rect2())
	for other_id in _reserved_footprints:
		if footprint.intersects(_reserved_footprints[other_id], false):
			return _live_result(
				validation,
				false,
				"reserved_overlap",
				"That footprint is reserved by an earlier build."
			)
	var request_id := str(intent.get("request_id", ""))
	var seat := input_router.registry.get_seat(seat_index)
	var job := {
		"job_id": request_id,
		"seat_index": seat_index,
		"owner_number": int(seat.get("identity", seat_index + 1)),
		"shape": str(seat.get("shape", "DIAMOND")),
		"shape_mark": str(MARKS.get(str(seat.get("shape", "DIAMOND")), "◆")),
		"item_label": str(VARIANT_LABELS.get(str(intent.get("variant_key", "")), "Build")),
		"intent": intent.duplicate(true),
		"started_at": _construction_clock,
		"footprint": footprint,
		"preview": null,
	}
	var preview := JOB_PREVIEW.new()
	preview.configure(job, construction_seconds)
	world_layer.add_child(preview)
	job.preview = preview
	construction_jobs[request_id] = job
	_reserved_footprints[request_id] = footprint
	validation["job_id"] = request_id
	validation["footprint"] = footprint
	validation["code"] = "construction_started"
	validation["reason"] = "Construction started • %.1f s." % construction_seconds
	return validation


func _advance_construction_jobs(delta: float) -> void:
	_construction_clock += delta
	for job_id_variant in construction_jobs.keys():
		var job_id := str(job_id_variant)
		if not construction_jobs.has(job_id):
			continue
		var job: Dictionary = construction_jobs[job_id]
		var elapsed := maxf(0.0, _construction_clock - float(job.started_at))
		var remaining := maxf(0.0, construction_seconds - elapsed)
		var preview := job.get("preview") as Node2D
		if preview != null and is_instance_valid(preview):
			preview.set_progress(elapsed, construction_seconds)
		var seat_index := int(job.seat_index)
		if not _seat_can_keep_job(seat_index):
			_cancel_construction_job(job_id, false)
			continue
		if remaining > 0.0:
			live_notices[seat_index] = "Building • %.1f s remaining." % remaining
			continue
		items.live_boundary = Engine.get_physics_frames()
		var result := _commit_live_intent(
			seat_index,
			job.intent,
			Engine.get_physics_frames(),
			true,
			phase_controller.phase == MatchPhaseController.Phase.PLAY
		)
		if bool(result.get("allowed", false)):
			inventory_used[seat_index] = true
			for relocation in result.get("actor_relocations", []):
				var relocated_actor := actors.get(int(relocation.seat_index)) as ChickenController
				if relocated_actor != null and is_instance_valid(relocated_actor):
					relocated_actor.global_position = relocation.position
					relocated_actor.locomotion_velocity.y = minf(
						relocated_actor.locomotion_velocity.y, 0.0
					)
					relocated_actor.velocity.y = minf(relocated_actor.velocity.y, 0.0)
			if (
				not str(result.get("entity_id", "")).is_empty()
				and result.get("actor_relocations", []).is_empty()
			):
				_displace_actors_to_completed_footprint_top(job.footprint)
			live_notices[seat_index] = (
				"Build complete • this round's item is used."
				if not _is_round_objective_variant(str(job.intent.get("variant_key", "")))
				else "Objective complete."
			)
		else:
			inventory_used[seat_index] = false
			live_notices[seat_index] = (
				"Build could not complete • %s" % str(result.get("reason", "placement changed"))
			)
		_finish_construction_job(job_id)
		if bool(result.get("terrain_mutated", false)):
			items.stage_version += 1
			request_pipeline.stage_version = items.stage_version
		result.stage_version = items.stage_version
		request_pipeline.resolve_result(job_id, result)
		_notify_presentation(&"live_build")
		_refresh_match_ui()


func _displace_actors_to_completed_footprint_top(footprint: Rect2) -> void:
	for actor_variant in actors.values():
		var actor := actor_variant as ChickenController
		if actor == null or not is_instance_valid(actor) or actor.lifecycle.is_terminal():
			continue
		var current := actor.hit_rect()
		if current.intersects(footprint, true):
			# Only touchers move; preserve their lane and nudge them onto the new top surface.
			actor.global_position.y = footprint.position.y - tuning.body_height_wu * 0.5
			actor.locomotion_velocity.y = minf(actor.locomotion_velocity.y, 0.0)
			actor.velocity.y = minf(actor.velocity.y, 0.0)


func _seat_can_keep_job(seat_index: int) -> bool:
	var actor := actors.get(seat_index) as ChickenController
	return (
		(
			phase_controller.phase
			in [
				MatchPhaseController.Phase.BUILD,
				MatchPhaseController.Phase.GO,
				MatchPhaseController.Phase.PLAY
			]
		)
		and (items.in_play == (phase_controller.phase == MatchPhaseController.Phase.PLAY))
		and bool(input_router.registry.get_seat(seat_index).get("joined", false))
		and actor != null
		and not actor.lifecycle.is_terminal()
		and actor.lifecycle.status != PlayerLifecycleState.Status.CAPTURED
		and actor.lifecycle.status != PlayerLifecycleState.Status.SECURED
	)


func _finish_construction_job(job_id: String) -> void:
	if not construction_jobs.has(job_id):
		return
	var job: Dictionary = construction_jobs[job_id]
	var preview := job.get("preview") as Node2D
	if preview != null and is_instance_valid(preview):
		preview.queue_free()
	construction_jobs.erase(job_id)
	_reserved_footprints.erase(job_id)


func _job_id_for_seat(seat_index: int) -> String:
	for job_id_variant in construction_jobs:
		if int(construction_jobs[job_id_variant].get("seat_index", -1)) == seat_index:
			return str(job_id_variant)
	return ""


func _cancel_construction_job(job_id: String, restore_item: bool) -> void:
	if not construction_jobs.has(job_id):
		return
	var job: Dictionary = construction_jobs[job_id]
	var seat_index := int(job.seat_index)
	var restored := restore_item and _seat_can_keep_job(seat_index)
	if restored:
		inventory_used[seat_index] = false
	else:
		inventory_used[seat_index] = true
	var reason := (
		"Build ended • item returned."
		if restored
		else "Build ended • builder is no longer eligible."
	)
	request_pipeline.resolve_result(
		job_id,
		_live_result(
			{
				"request_id": job_id,
				"seat_index": seat_index,
				"commit_boundary": Engine.get_physics_frames(),
				"stage_version": items.stage_version
			},
			false,
			"cancelled",
			reason
		)
	)
	_finish_construction_job(job_id)


func _cancel_all_construction_jobs(restore_items: bool) -> void:
	for job_id_variant in construction_jobs.keys():
		_cancel_construction_job(str(job_id_variant), restore_items)


func _commit_live_intent(
	seat_index: int,
	intent: Dictionary,
	boundary: int,
	materialize: bool = true,
	allow_actor_displacement: bool = false
) -> Dictionary:
	var base := {
		"request_id": str(intent.get("request_id", "")),
		"seat_index": seat_index,
		"commit_boundary": boundary,
		"stage_version": items.stage_version,
	}
	var preparation_phase := (
		phase_controller.phase in [MatchPhaseController.Phase.BUILD, MatchPhaseController.Phase.GO]
	)
	if (
		(
			phase_controller.phase
			not in [
				MatchPhaseController.Phase.BUILD,
				MatchPhaseController.Phase.PLAY,
				MatchPhaseController.Phase.GO
			]
		)
		or items.in_play == preparation_phase
	):
		return _live_result(base, false, "wrong_phase", "Live placement is closed.")
	if not bool(input_router.registry.get_seat(seat_index).get("joined", false)):
		return _live_result(base, false, "seat_unregistered", "The input seat is no longer joined.")
	var actor := actors.get(seat_index) as ChickenController
	if (
		actor == null
		or actor.lifecycle.is_terminal()
		or actor.lifecycle.status == PlayerLifecycleState.Status.CAPTURED
	):
		return _live_result(
			base, false, "actor_ineligible", "Only an active, unsecured chicken can build."
		)
	if not placement_controller.cursors.has(seat_index):
		return _live_result(base, false, "inventory_missing", "This seat has no assigned item.")
	if (
		bool(inventory_used.get(seat_index, false))
		and _job_id_for_seat(seat_index) != str(intent.get("request_id", ""))
	):
		return _live_result(base, false, "inventory_used", "The assigned item was already used.")
	var cursor: Dictionary = placement_controller.cursors[seat_index]
	if str(cursor.variant_key) != str(intent.get("variant_key", "")):
		return _live_result(
			base, false, "inventory_mismatch", "The item does not belong to this seat."
		)
	if int(intent.get("observed_stage_version", -1)) > items.stage_version:
		return _live_result(base, false, "future_stage", "The stage version is not current.")
	var cell: Vector2i = intent.get("cell", Vector2i.ZERO)
	var turns := int(intent.get("quarter_turns", 0))
	if BaryaObjectiveDefinition.is_variant(str(cursor.variant_key)):
		var objective_actors := _live_actor_swept_rects()
		items.live_actor_clearance_wu = live_actor_clearance_wu
		var objective_verdict := BaryaPlacementRules.validate_cell(
			arena, tuning, cell, items.pieces.values(), items.owner_seat_clearance(objective_actors)
		)
		if not bool(objective_verdict.get("allowed", false)):
			return _live_result(
				base,
				false,
				str(objective_verdict.get("code", "objective_rejected")),
				str(objective_verdict.get("reason", "Barya cannot be placed there."))
			)
		if not materialize:
			var preview_result := base.duplicate(true)
			preview_result["footprint"] = objective_verdict.get("footprint", Rect2())
			return _live_result(preview_result, true, "preview", "Barya footprint is clear.")
		var objective := _commit_round_objective_placement(
			{
				"seat_index": seat_index,
				"variant_key": str(cursor.variant_key),
				"origin_cell": cell,
				"quarter_turns": turns,
			}
		)
		# A refused commit (stale assignment, coin scene) is a rejection on the wire, not an
		# accepted objective with an INTERNAL_RETRY reason (the previous retry fix).
		var objective_allowed := bool(objective.get("allowed", false))
		var objective_result := _live_result(
			base,
			objective_allowed,
			"objective" if objective_allowed else "objective_rejected",
			str(objective.get("reason", "Barya placed."))
		)
		objective_result["objective"] = true
		objective_result["cell"] = cell
		return objective_result
	var actor_rects := _live_actor_swept_rects()
	items.live_actor_clearance_wu = live_actor_clearance_wu
	var verdict: Dictionary
	var placement_actor_rects := actor_rects
	var actor_relocations: Array[Dictionary] = []
	var hazard_actor_clearance := false
	if materialize and allow_actor_displacement:
		# Resolve without chicken clearance. Only chickens physically touching a completed item are
		# nudged onto its top; nearby players stay where they are.
		verdict = items.validate_placement(str(cursor.variant_key), cell, turns, [])
		if bool(verdict.get("allowed", false)):
			placement_actor_rects = []
			if not bool(verdict.get("one_shot", false)):
				var found := definitions.find_variant(str(cursor.variant_key))
				var family := found.get("family") as ItemFamilyDefinition
				if family != null and str(family.behavior_kind) in ["hitbox", "trumpo", "bubble"]:
					hazard_actor_clearance = true
					actor_relocations = _plan_hazard_actor_relocations(verdict.footprint)
			verdict = items.validate_placement(
				str(cursor.variant_key),
				cell,
				turns,
				items.owner_seat_clearance(placement_actor_rects)
			)
	else:
		var validation_actor_rects: Array[Rect2] = []
		if materialize:
			validation_actor_rects = items.owner_seat_clearance(actor_rects)
		verdict = items.validate_placement(
			str(cursor.variant_key), cell, turns, validation_actor_rects
		)
	if not bool(verdict.get("allowed", false)):
		return _live_result(
			base,
			false,
			str(verdict.get("code", "invalid_placement")),
			str(verdict.get("reason", "The item cannot be placed there."))
		)
	if materialize and allow_actor_displacement and not bool(verdict.get("one_shot", false)):
		if actor_relocations.is_empty() and not hazard_actor_clearance:
			actor_rects = _live_actor_swept_rects_to_top(verdict.footprint)
		else:
			actor_rects = _live_actor_swept_rects_excluding_relocations(actor_relocations)
	if bool(verdict.get("one_shot", false)):
		if not materialize:
			var preview_result := base.duplicate(true)
			preview_result["footprint"] = verdict.footprint
			return _live_result(preview_result, true, "preview", "Walis removal area reserved.")
		var cleanup := items.apply_live_one_shot(verdict, seat_index, false, preparation_phase)
		var cleanup_result := _live_result(
			base,
			bool(cleanup.get("allowed", false)),
			str(cleanup.get("code", "cleanup_rejected")),
			str(cleanup.get("reason", "Cleanup was rejected."))
		)
		# A one-shot edit creates no entity: the wire result names none (contract v1.4); the
		# removals travel as versioned terrain REMOVE ops.
		cleanup_result["edit_id"] = str(cleanup.get("edit_id", ""))
		cleanup_result["removed"] = cleanup.get("removed", [])
		var removed: Array = cleanup.get("removed", [])
		cleanup_result["terrain_mutated"] = not removed.is_empty()
		if bool(cleanup.get("allowed", false)):
			_on_live_one_shot_committed(verdict.footprint, seat_index)
		return cleanup_result
	if _live_mover_sweep_intersects(verdict.footprint):
		return _live_result(
			base, false, "mover_sweep", "A moving piece can cross that placement area."
		)
	var effect_actor_rects: Array[Rect2] = []
	if materialize:
		effect_actor_rects = actor_rects
	var effect_check := _live_effect_check(str(cursor.variant_key), verdict, effect_actor_rects)
	if not effect_check.is_empty():
		return _live_result(base, false, str(effect_check.code), str(effect_check.reason))
	if not materialize:
		var preview_result := base.duplicate(true)
		preview_result["footprint"] = verdict.footprint
		return _live_result(preview_result, true, "preview", "Placement area is clear.")
	var committed := (
		items.place_prepared_live(
			str(cursor.variant_key), cell, turns, seat_index, placement_actor_rects, false
		)
		if preparation_phase
		else items.place_live(
			str(cursor.variant_key), cell, turns, seat_index, placement_actor_rects, false
		)
	)
	if not bool(committed.get("allowed", false)):
		return _live_result(
			base,
			false,
			str(committed.get("code", "commit_failed")),
			str(committed.get("reason", "Placement failed."))
		)
	var result := _live_result(base, true, "committed", "Placement accepted.")
	result["entity_id"] = str(committed.get("instance_id", ""))
	result["actor_relocations"] = actor_relocations
	result["cell"] = cell
	result["quarter_turns"] = turns
	result["activation_after_seconds"] = 0.0
	result["terrain_mutated"] = true
	return result


func _live_actor_swept_rects() -> Array[Rect2]:
	var result: Array[Rect2] = []
	for actor_variant in actors.values():
		var actor := actor_variant as ChickenController
		if actor == null or not is_instance_valid(actor) or actor.lifecycle.is_terminal():
			continue
		var current := actor.hit_rect()
		var future := current
		future.position += actor.velocity * 0.25
		result.append(current.merge(future))
	return result


func _live_actor_swept_rects_to_top(footprint: Rect2) -> Array[Rect2]:
	var result: Array[Rect2] = []
	for actor_variant in actors.values():
		var actor := actor_variant as ChickenController
		if actor == null or not is_instance_valid(actor) or actor.lifecycle.is_terminal():
			continue
		var current := actor.hit_rect()
		if current.intersects(footprint, true):
			result.append(
				Rect2(
					Vector2(
						actor.global_position.x - tuning.body_width_wu * 0.5,
						footprint.position.y - tuning.body_height_wu
					),
					Vector2(tuning.body_width_wu, tuning.body_height_wu)
				)
			)
		else:
			var previous := current
			previous.position -= actor.velocity * 0.25
			result.append(current.merge(previous))
	return result


func _plan_hazard_actor_relocations(footprint: Rect2) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var seats: Array[int] = []
	for seat_variant in actors:
		seats.append(int(seat_variant))
	seats.sort()
	for seat_index in seats:
		var actor := actors.get(seat_index) as ChickenController
		if actor == null or not is_instance_valid(actor) or actor.lifecycle.is_terminal():
			continue
		var actor_rect := actor.hit_rect()
		if not actor_rect.intersects(footprint, true):
			continue
		result.append(
			{
				"seat_index": seat_index,
				"position":
				Vector2(actor.global_position.x, footprint.position.y - tuning.body_height_wu * 0.5)
			}
		)
	return result


func _live_actor_swept_rects_excluding_relocations(relocations: Array[Dictionary]) -> Array[Rect2]:
	var relocated: Dictionary = {}
	for relocation in relocations:
		relocated[int(relocation.seat_index)] = relocation.position
	var result: Array[Rect2] = []
	for seat_variant in actors:
		var seat_index := int(seat_variant)
		var actor := actors.get(seat_index) as ChickenController
		if actor == null or not is_instance_valid(actor) or actor.lifecycle.is_terminal():
			continue
		var current := actor.hit_rect()
		if relocated.has(seat_index):
			current.position += relocated[seat_index] - actor.global_position
			result.append(current)
		else:
			var previous := current
			previous.position -= actor.velocity * 0.25
			result.append(current.merge(previous))
	return result


func _live_mover_sweep_intersects(footprint: Rect2) -> bool:
	var protected_rect := footprint.grow(live_actor_clearance_wu)
	for record_variant in items.pieces.values():
		var record := record_variant as PlacedItem
		var mover := record.node as StageBlock if record.node is StageBlock else null
		if mover == null or (not mover.is_dynamic() and not mover.is_pushable()):
			continue
		var colliders := mover.find_children("*", "CollisionShape2D", true, false)
		if colliders.is_empty():
			return true
		for collider_variant in colliders:
			var collider := collider_variant as CollisionShape2D
			if collider.disabled or collider.shape == null:
				continue
			var live_rect: Rect2 = collider.global_transform * collider.shape.get_rect()
			var sweep_end := live_rect
			sweep_end.position += mover.velocity * 0.5
			if protected_rect.intersects(live_rect.merge(sweep_end), false):
				return true
	return false


## A host blast flash over a committed live one-shot edit (Walis, Bomb, Dynamite, Nuke), as the
## offline Place resolution shows.
func _on_live_one_shot_committed(area: Rect2, _seat_index: int) -> void:
	_show_blasts([{"area": area}])


## Live safety checks after the shared validator accepts a persistent placement. Returns
## {} or {code, reason}. All inputs are host state; nothing here mutates the stage.
## Transient shots and bubbles do not reject a build, and hazards are active immediately at commit.
## Movable blocks still cannot be placed over a chicken in their fall path.
func _live_effect_check(
	variant_key: String, verdict: Dictionary, actor_rects: Array[Rect2]
) -> Dictionary:
	var found := definitions.find_variant(variant_key)
	if found.is_empty():
		return {}
	var family := found.family as ItemFamilyDefinition
	var footprint: Rect2 = verdict.footprint
	if family.safe_start == ItemFamilyDefinition.SAFE_START_RESET_TO_PLACED:
		var fall := footprint
		fall.size.y += float(live_fall_check_cells) * tuning.grid_cell_wu
		for actor_rect in actor_rects:
			var standing_on_new_top := (
				absf(actor_rect.end.y - footprint.position.y) <= 1.0
				and actor_rect.position.x < footprint.end.x
				and actor_rect.end.x > footprint.position.x
			)
			if standing_on_new_top:
				continue
			if actor_rect.grow(live_actor_clearance_wu).intersects(fall, false):
				return {"code": "crush_risk", "reason": "A chicken is below that spot."}
	return {}


func _live_result(base: Dictionary, allowed: bool, code: String, reason: String) -> Dictionary:
	var result := base.duplicate(true)
	result["status"] = "accepted" if allowed else "rejected"
	result["allowed"] = allowed
	result["code"] = code
	result["reason"] = reason
	return result


func play_status_text() -> String:
	var notices: Array[String] = []
	if phase_controller.phase == MatchPhaseController.Phase.BUILD:
		notices.append(
			(
				"BUILD • Build now, or save your item for play. %d s"
				% ceili(phase_controller.remaining_seconds)
			)
		)
	elif phase_controller.phase == MatchPhaseController.Phase.GO:
		notices.append("GO • %d" % ceili(_go_remaining))
	for job in construction_jobs.values():
		var remaining := maxf(
			0.0, construction_seconds - (_construction_clock - float(job.started_at))
		)
		notices.append("P%d BUILDING • %.1f s" % [int(job.owner_number), remaining])
	for seat_variant in input_router.registry.joined_seats():
		var seat_index := int(seat_variant.seat)
		if bool(build_mode.get(seat_index, false)):
			notices.append("P%d BUILD • aim • confirm • chicken paused" % (seat_index + 1))
		elif live_notices.has(seat_index) and not str(live_notices[seat_index]).is_empty():
			notices.append("P%d %s" % [seat_index + 1, str(live_notices[seat_index])])
	return "  ·  ".join(notices)


func is_seat_in_build_mode(seat_index: int) -> bool:
	return (
		(
			phase_controller.phase
			in [MatchPhaseController.Phase.BUILD, MatchPhaseController.Phase.PLAY]
		)
		and bool(build_mode.get(seat_index, false))
	)


func reset_room() -> void:
	_cancel_all_construction_jobs(false)
	_close_live_attempt()
	if input_router != null:
		input_router.live_build_confirm_enabled = false
		for seat_variant in build_mode.keys():
			input_router.set_live_build_mode(int(seat_variant), false)
	for actor_variant in actors.values():
		var actor := actor_variant as ChickenController
		if actor != null and is_instance_valid(actor):
			actor.build_input_locked = false
	build_mode.clear()
	inventory_used.clear()
	live_notices.clear()
	_aim_repeat.clear()
	_request_serial = 0
	_construction_clock = 0.0
	_live_admission_open = false
	_go_start_pending = false
	super.reset_room()

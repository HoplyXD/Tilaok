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
const LIVE_SAFE_BEHAVIORS := ["", "hitbox", "trumpo", "bubble"]
const LIVE_BLOCKED_BEHAVIOR_REASONS := {
	"spring": "P10 T03 failed: 1 launch after 40 held-contact frames.",
	"parol": "P10 T20 failed: solid cover did not shorten the beam (384 wu vs 128 wu).",
	"launcher": "P10 T30 failed: the projectile crossed a solid cover.",
	"cannon": "No P20 interaction audit covers cannon projectile and live-build overlaps.",
}

@export_range(1.0, 10.0, 0.25) var go_countdown_seconds := 3.0
@export_range(0.1, 10.0, 0.1) var construction_seconds := 2.0
@export_range(0.1, 5.0, 0.1) var live_item_grace_seconds := 1.0
@export_range(1.0, 32.0, 1.0) var live_cursor_cells_per_second := 8.0
@export_range(0.0, 1.0, 0.05) var live_cursor_initial_delay := 0.25
@export_range(0.0, 64.0, 1.0) var live_actor_clearance_wu := 32.0
## Extra reach kept clear around live chickens for lethal hazards, projectile lanes and capture
## paths, so construction never creates an unavoidable immediate hit.
@export_range(0.0, 256.0, 1.0) var live_lethal_clearance_wu := 64.0
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
var _edge_layer: CanvasLayer
var _edge_root: Control
var _edge_markers: Dictionary = {}
var _activation_warning_cache := ""
var _reserved_footprints: Dictionary = {}
var _construction_clock := 0.0


func _init() -> void:
	profile_id = "karera_slice"


func pugad_excluded_variant_keys() -> PackedStringArray:
	var excluded := PackedStringArray()
	for variant_key in tuning.item_enabled_variants:
		var found := definitions.find_variant(str(variant_key))
		var family := found.get("family") as ItemFamilyDefinition
		if family == null or str(family.behavior_kind) not in LIVE_SAFE_BEHAVIORS:
			excluded.append(str(variant_key))
	return excluded


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
	if phase_controller.phase == MatchPhaseController.Phase.GO:
		var go_finished := phase_controller.advance(delta)
		_go_remaining = phase_controller.remaining_seconds
		last_message = "GO • %d" % ceili(_go_remaining)
		_notify_presentation(&"live_build")
		if go_finished:
			_start_live_play()
	elif phase_controller.phase == MatchPhaseController.Phase.PLAY:
		_advance_live_aim(delta)
		_update_edge_markers()
		var warning := items.live_activation_warning_text()
		if warning != _activation_warning_cache:
			_activation_warning_cache = warning
			_notify_presentation(&"live_build")


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
	if phase_controller.phase == MatchPhaseController.Phase.PLAY:
		_resolve_live_placement_boundary()
		_advance_construction_jobs(delta)
	elif phase_controller.phase != MatchPhaseController.Phase.GO:
		# The terminal round result (resolved in super) closes admission before any queued edit.
		_close_live_attempt()
		_cancel_all_construction_jobs(false)


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
	placement_controller.setup(claimed_variants, definitions, tuning)
	for seat_index in seats:
		build_mode[seat_index] = false
		inventory_used[seat_index] = false
		live_notices.erase(seat_index)
		_aim_repeat[seat_index] = {"elapsed": 0.0, "first": true, "direction": Vector2.ZERO}
	input_router.set_rotation_supported(false)
	# Keyboard south keys (E/F, Enter, O, Num 0) confirm live placement only in live-build rooms.
	input_router.live_build_confirm_enabled = true
	_go_remaining = go_countdown_seconds
	phase_controller.enter(MatchPhaseController.Phase.GO, go_countdown_seconds)
	input_router.set_phase(LocalInputRouter.Phase.GO)
	current_context = BoundedStageCamera.Context.PLAY
	camera_rig.set_context(current_context)
	_free_match_ghosts()
	request_pipeline.begin_attempt(match_run_id, items.round_number + 1, items.stage_version)
	print("OFFLINE_LIVE_PUGAD seed=%d assignments=%s" % [match_seed, JSON.stringify(assignments)])
	last_message = "Get ready • movement and building begin at GO."
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
		_add_match_ghost(int(seat_index))
		(_ghosts[int(seat_index)] as ItemGhost).visible = false
		_create_edge_marker(int(seat_index))
	_refresh_match_ui()


func _on_match_navigation_step(seat_index: int, direction: String) -> void:
	if phase_controller.phase == MatchPhaseController.Phase.PUGAD:
		super._on_match_navigation_step(seat_index, direction)
		return


func _advance_live_aim(delta: float) -> void:
	for seat_variant in placement_controller.cursors.keys():
		var seat_index := int(seat_variant)
		if (
			not bool(build_mode.get(seat_index, false))
			or bool(inventory_used.get(seat_index, false))
		):
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
	if phase_controller.phase == MatchPhaseController.Phase.PLAY:
		if (
			_sudden_death_active
			and action_name in ["build_toggle", "live_rotate", "live_cancel", "confirm"]
		):
			if bool(build_mode.get(seat_index, false)) or action_name != "confirm":
				return
		match action_name:
			"build_toggle":
				if not bool(inventory_used.get(seat_index, false)):
					build_mode[seat_index] = not bool(build_mode.get(seat_index, false))
					input_router.consume_held_presses_for_seat(seat_index)
					_set_live_ghost_visible(seat_index, bool(build_mode[seat_index]))
					live_notices[seat_index] = (
						"Build mode on." if bool(build_mode[seat_index]) else "Build mode off."
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
						_cancel_construction_job(active_job_id, true)
						live_notices[seat_index] = "Construction cancelled • item returned."
						_notify_presentation(&"live_build")
						return
				if bool(build_mode.get(seat_index, false)):
					build_mode[seat_index] = false
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
			phase_controller.phase == MatchPhaseController.Phase.PLAY
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
		bool(inventory_used.get(seat_index, false))
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
		build_mode[seat_index] = false
		_set_live_ghost_visible(seat_index, false)
		live_notices[seat_index] = str(result.get("reason", "Placement resolved."))
		if bool(result.get("allowed", false)):
			live_notices[seat_index] = "Building • %.1f s remaining." % construction_seconds
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
		var behavior := str(family.behavior_kind)
		if not behavior in LIVE_SAFE_BEHAVIORS:
			var reason := str(
				LIVE_BLOCKED_BEHAVIOR_REASONS.get(
					behavior, "No live-construction safety audit is recorded for this behavior."
				)
			)
			return _live_result(
				{
					"request_id": str(intent.get("request_id", "")),
					"seat_index": seat_index,
					"commit_boundary": boundary
				},
				false,
				"content_unverified",
				(
					"Live construction is disabled for %s (%s): %s"
					% [family.family_id, behavior, reason]
				)
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
		var result := _commit_live_intent(seat_index, job.intent, Engine.get_physics_frames(), true)
		if bool(result.get("allowed", false)):
			live_notices[seat_index] = "Construction complete."
		else:
			inventory_used[seat_index] = false
			live_notices[seat_index] = (
				"Build cancelled • %s" % str(result.get("reason", "placement changed"))
			)
		_finish_construction_job(job_id)
		if bool(result.get("terrain_mutated", false)):
			items.stage_version += 1
			request_pipeline.stage_version = items.stage_version
		result.stage_version = items.stage_version
		request_pipeline.resolve_result(job_id, result)
		_notify_presentation(&"live_build")
		_refresh_match_ui()


func _seat_can_keep_job(seat_index: int) -> bool:
	var actor := actors.get(seat_index) as ChickenController
	return (
		phase_controller.phase == MatchPhaseController.Phase.PLAY
		and items.in_play
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
		"Construction cancelled • item returned."
		if restored
		else "Construction cancelled because the builder is no longer eligible."
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
	seat_index: int, intent: Dictionary, boundary: int, materialize: bool = true
) -> Dictionary:
	var base := {
		"request_id": str(intent.get("request_id", "")),
		"seat_index": seat_index,
		"commit_boundary": boundary,
		"stage_version": items.stage_version,
	}
	if phase_controller.phase != MatchPhaseController.Phase.PLAY or not items.in_play:
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
	var verdict := items.validate_placement(
		str(cursor.variant_key), cell, turns, items.owner_seat_clearance(actor_rects)
	)
	if not bool(verdict.get("allowed", false)):
		return _live_result(
			base,
			false,
			str(verdict.get("code", "invalid_placement")),
			str(verdict.get("reason", "The item cannot be placed there."))
		)
	if bool(verdict.get("one_shot", false)):
		for actor_rect_variant in items.owner_seat_clearance(actor_rects):
			var actor_rect: Rect2 = actor_rect_variant
			if actor_rect.intersects(verdict.footprint, false):
				return _live_result(
					base, false, "player_clearance", "A chicken is too close to that cleanup area."
				)
		if not materialize:
			var preview_result := base.duplicate(true)
			preview_result["footprint"] = verdict.footprint
			return _live_result(preview_result, true, "preview", "Walis removal area reserved.")
		var cleanup := items.apply_live_one_shot(verdict, seat_index, false)
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
	var effect_check := _live_effect_check(str(cursor.variant_key), turns, verdict, actor_rects)
	if not effect_check.is_empty():
		return _live_result(base, false, str(effect_check.code), str(effect_check.reason))
	if not materialize:
		var preview_result := base.duplicate(true)
		preview_result["footprint"] = verdict.footprint
		return _live_result(preview_result, true, "preview", "Placement area is clear.")
	items.live_activation_grace_seconds = live_item_grace_seconds
	var committed := items.place_live(
		str(cursor.variant_key), cell, turns, seat_index, actor_rects, false
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
	result["cell"] = cell
	result["quarter_turns"] = turns
	result["activation_after_seconds"] = live_item_grace_seconds
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
## - lethal hazards, projectile lanes and capture paths: no live chicken within the extra lethal
##   clearance of the footprint or any effect region (no unavoidable immediate hit);
## - every persistent item: no in-flight projectile or bubble inside its footprint or regions;
## - movable blocks: no chicken in the fall path below (a live solid never crushes or pins).
func _live_effect_check(
	variant_key: String, turns: int, verdict: Dictionary, actor_rects: Array[Rect2]
) -> Dictionary:
	var found := definitions.find_variant(variant_key)
	if found.is_empty():
		return {}
	var family := found.family as ItemFamilyDefinition
	var footprint: Rect2 = verdict.footprint
	var effect_rects: Array[Rect2] = [footprint]
	var variant := found.variant as ItemVariantDefinition
	var regions := ItemGeometry.clip_to_stage(
		ItemGeometry.resolve_regions(variant, ItemGeometry.normalized_turns(turns), tuning),
		footprint,
		arena
	)
	for region in regions:
		var world_rect: Rect2 = region.rect
		world_rect.position += footprint.position
		effect_rects.append(world_rect)
	var kind := str(family.behavior_kind)
	if kind in ["hitbox", "trumpo", "parol", "launcher", "bubble"]:
		for actor_rect in actor_rects:
			var reach := actor_rect.grow(live_actor_clearance_wu + live_lethal_clearance_wu)
			for effect_rect in effect_rects:
				if reach.intersects(effect_rect, false):
					return {
						"code": "lethal_clearance",
						"reason": "A chicken is too close to that hazard's reach."
					}
	for transient_rect in _live_effect_rects_in_flight():
		for effect_rect in effect_rects:
			if transient_rect.intersects(effect_rect, false):
				return {
					"code":
					"projectile_lane" if kind in ["launcher", "bubble"] else "live_effect_path",
					"reason": "A shot or bubble is crossing that spot."
				}
	if family.safe_start == ItemFamilyDefinition.SAFE_START_RESET_TO_PLACED:
		var fall := footprint
		fall.size.y += float(live_fall_check_cells) * tuning.grid_cell_wu
		for actor_rect in actor_rects:
			if actor_rect.grow(live_actor_clearance_wu).intersects(fall, false):
				return {"code": "crush_risk", "reason": "A chicken is below that spot."}
	return {}


## Host rects of every in-flight projectile and live bubble (shared item runtime).
func _live_effect_rects_in_flight() -> Array[Rect2]:
	var result: Array[Rect2] = []
	for instance_id in items.pieces.keys():
		var piece := items.piece_for(str(instance_id)) as HazardPiece
		if piece == null or piece.behavior == null:
			continue
		if piece.behavior is LauncherBehavior:
			var size := Vector2.ONE * tuning.item_launcher_projectile_size_wu
			for projectile in (piece.behavior as LauncherBehavior).projectiles:
				var center: Vector2 = projectile.center
				result.append(Rect2(center - size * 0.5, size).grow(live_actor_clearance_wu))
		elif piece.behavior is BubbleBehavior and (piece.behavior as BubbleBehavior).has_bubble():
			var radius := tuning.item_bubble_radius_wu
			var bubble_center := (piece.behavior as BubbleBehavior).bubble_center
			result.append(Rect2(bubble_center - Vector2.ONE * radius, Vector2.ONE * radius * 2.0))
	return result


func _live_result(base: Dictionary, allowed: bool, code: String, reason: String) -> Dictionary:
	var result := base.duplicate(true)
	result["status"] = "accepted" if allowed else "rejected"
	result["allowed"] = allowed
	result["code"] = code
	result["reason"] = reason
	return result


func play_status_text() -> String:
	if phase_controller.phase == MatchPhaseController.Phase.GO:
		return "GO • %d" % ceili(_go_remaining)
	var notices: Array[String] = []
	for job in construction_jobs.values():
		var remaining := maxf(
			0.0, construction_seconds - (_construction_clock - float(job.started_at))
		)
		notices.append("P%d BUILDING • %.1f s" % [int(job.owner_number), remaining])
	for seat_variant in input_router.registry.joined_seats():
		var seat_index := int(seat_variant.seat)
		if bool(build_mode.get(seat_index, false)):
			notices.append("P%d BUILD • aim • confirm" % (seat_index + 1))
		elif live_notices.has(seat_index) and not str(live_notices[seat_index]).is_empty():
			notices.append("P%d %s" % [seat_index + 1, str(live_notices[seat_index])])
	var activation_warning := items.live_activation_warning_text()
	if not activation_warning.is_empty():
		notices.append(activation_warning)
	return "  ·  ".join(notices)


func reset_room() -> void:
	_cancel_all_construction_jobs(false)
	_close_live_attempt()
	if input_router != null:
		input_router.live_build_confirm_enabled = false
	build_mode.clear()
	inventory_used.clear()
	live_notices.clear()
	_aim_repeat.clear()
	_request_serial = 0
	_construction_clock = 0.0
	super.reset_room()

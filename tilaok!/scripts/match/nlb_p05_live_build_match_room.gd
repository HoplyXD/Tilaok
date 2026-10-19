# gdlint: disable=max-returns,max-public-methods,max-file-lines
class_name NLBP05LiveBuildMatchRoom
extends P12ScheduledMatchRoom

## Opt-in offline route. It reuses P12's schedule, objective and terminal rules while changing the
## round opening and allowing one assigned item to be placed during Play.

const REQUEST_PIPELINE := preload("res://scripts/match/live_placement_pipeline.gd")

@export_range(1.0, 10.0, 0.25) var go_countdown_seconds := 3.0
@export_range(0.1, 5.0, 0.1) var live_item_grace_seconds := 1.0
@export_range(1.0, 32.0, 1.0) var live_cursor_cells_per_second := 8.0
@export_range(0.0, 1.0, 0.05) var live_cursor_initial_delay := 0.25
@export_range(0.0, 64.0, 1.0) var live_actor_clearance_wu := 32.0

var request_pipeline := REQUEST_PIPELINE.new()
var build_mode: Dictionary = {}
var inventory_used: Dictionary = {}
var live_notices: Dictionary = {}
var _aim_repeat: Dictionary = {}
var _request_serial := 0
var _go_remaining := 0.0
var _edge_layer: CanvasLayer
var _edge_root: Control
var _edge_markers: Dictionary = {}
var _activation_warning_cache := ""


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
	if phase_controller.phase == MatchPhaseController.Phase.PLAY:
		_resolve_live_placement_boundary()
	elif phase_controller.phase != MatchPhaseController.Phase.GO:
		request_pipeline.close_attempt()


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
	_go_remaining = go_countdown_seconds
	phase_controller.enter(MatchPhaseController.Phase.GO, go_countdown_seconds)
	input_router.set_phase(LocalInputRouter.Phase.GO)
	current_context = BoundedStageCamera.Context.PLAY
	camera_rig.set_context(current_context)
	_free_match_ghosts()
	request_pipeline.begin_attempt(match_run_id, items.round_number + 1, items.stage_version)
	print("NLB_P05_PUGAD seed=%d assignments=%s" % [match_seed, JSON.stringify(assignments)])
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
				if bool(build_mode.get(seat_index, false)):
					build_mode[seat_index] = false
					_set_live_ghost_visible(seat_index, false)
					live_notices[seat_index] = "Preview closed. A submitted request still resolves."
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
	var terrain_changed := false
	var resolved: Array[Dictionary] = []
	for receipt in requests:
		var request_id := str(receipt.request_id)
		var seat_index := int(receipt.seat_index)
		var intent: Dictionary = receipt.intent
		var result := _commit_live_intent(seat_index, intent, boundary)
		resolved.append({"request_id": request_id, "result": result})
		if bool(result.get("allowed", false)) and bool(result.get("terrain_mutated", false)):
			terrain_changed = true
		inventory_used[seat_index] = bool(result.get("allowed", false))
		build_mode[seat_index] = false
		_set_live_ghost_visible(seat_index, false)
		live_notices[seat_index] = str(result.get("reason", "Placement resolved."))
		if bool(result.get("allowed", false)):
			live_notices[seat_index] = "Placed • activates after its safe grace period."
	if terrain_changed:
		items.stage_version += 1
		request_pipeline.stage_version = items.stage_version
	for resolved_row in resolved:
		var result: Dictionary = resolved_row.result
		result.stage_version = items.stage_version
		request_pipeline.resolve_result(str(resolved_row.request_id), result)
	for seat_variant in placement_controller.cursors.keys():
		_refresh_match_ghost(int(seat_variant))
	_notify_presentation(&"live_build")
	_refresh_match_ui()


func _commit_live_intent(seat_index: int, intent: Dictionary, boundary: int) -> Dictionary:
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
	if bool(inventory_used.get(seat_index, false)):
		return _live_result(base, false, "inventory_used", "The assigned item was already used.")
	if (
		items.budget.count(TransientBudget.Kind.PROJECTILE) > 0
		or items.budget.count(TransientBudget.Kind.BUBBLE) > 0
	):
		return _live_result(
			base,
			false,
			"live_effect_path",
			"Wait for active projectiles and bubble effects to clear before placing."
		)
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
				str(objective_verdict.get("code", "objective_invalid")),
				str(objective_verdict.get("reason", "Barya cannot be placed there."))
			)
		var objective := _commit_round_objective_placement(
			{
				"seat_index": seat_index,
				"variant_key": str(cursor.variant_key),
				"origin_cell": cell,
				"quarter_turns": turns,
			}
		)
		var objective_result := _live_result(
			base,
			bool(objective.get("allowed", false)),
			"objective",
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
		var cleanup := items.apply_live_one_shot(verdict, seat_index, false)
		var cleanup_result := _live_result(
			base,
			bool(cleanup.get("allowed", false)),
			str(cleanup.get("code", "cleanup_rejected")),
			str(cleanup.get("reason", "Cleanup was rejected."))
		)
		cleanup_result["entity_id"] = str(cleanup.get("edit_id", ""))
		cleanup_result["removed"] = cleanup.get("removed", [])
		var removed: Array = cleanup.get("removed", [])
		cleanup_result["terrain_mutated"] = not removed.is_empty()
		return cleanup_result
	if _live_mover_sweep_intersects(verdict.footprint):
		return _live_result(
			base, false, "mover_sweep", "A moving piece can cross that placement area."
		)
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
	request_pipeline.close_attempt()
	build_mode.clear()
	inventory_used.clear()
	live_notices.clear()
	_aim_repeat.clear()
	super.reset_room()

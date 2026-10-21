# gdlint: disable=max-line-length,max-file-lines
extends SceneTree

## Focused NLB-P07 checks: the live compatibility matrix (schema, enumeration, default deny,
## dependencies, override, start gate, manifest digest, document parity), contract v1.4 transient
## and lifecycle codecs, the new reason mapping, and host-room enforcement on the networked live
## route (dealing, commit-time recheck, sudden death, one-shot entity age, lethal clearance, fall
## path). Transport-free; synthetic seats only, never physical evidence.
## Run: Godot --headless --fixed-fps 60 --path tilaok! --script res://tests/run_nlb_p07_tests.gd

const LIVE_NETWORK_ROOM := preload("res://scenes/match/nlb_p06_network_live_build_room.tscn")
const M := NLBLiveCompatibilityMatrix
const CELL_1X1 := "build.hollow_blocks.cell_1x1"
const COLUMN_1X3 := "build.hollow_blocks.column_1x3"
const SPAN_4X1 := "build.bamboo_bridge.span_4x1"
const WALIS_3X3 := "utility.walis_cleanup.area_3x3"
const BOMB := "explosive.bomb.main"
const SPIKES := "block.spikes.main"
const WOOD_BOX := "build.wood_box.box_2x2"
const DOC_PATH := "../docs/evidence/nlb/p07/compatibility-matrix.md"

var checks := 0
var failures := 0


class CaptureManager:
	extends NetworkSessionManager

	var sent: Array[Dictionary] = []

	func _send(peer_id: int, family: int, payload: PackedByteArray) -> bool:
		sent.append({"peer": peer_id, "family": family, "payload": payload.duplicate()})
		return true

	func _send_to_host(family: int, payload: PackedByteArray) -> bool:
		return _send(1, family, payload)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_matrix_schema_and_enumeration()
	_test_default_deny_and_override()
	_test_dependencies_and_cycles()
	_test_route_pools_and_schedule()
	_test_start_gate_and_lobby()
	_test_manifest_digest()
	_test_matrix_document_parity()
	_test_transient_codec_and_caps()
	_test_lifecycle_flag_and_client_transients()
	_test_reason_mapping()
	_test_build_controls_are_not_freeze_intent()
	await _test_strict_host_refuses_start()
	await _test_live_room_enforcement()
	await _test_one_shot_entity_age()
	await _test_lethal_and_fall_checks()
	print("NLB_P07_TESTS checks=%d failures=%d" % [checks, failures])
	await process_frame
	quit(1 if failures > 0 else 0)


func _check(condition: bool, label: String) -> void:
	checks += 1
	if condition:
		print("PASS ", label)
	else:
		failures += 1
		push_error("FAIL " + label)


# --- matrix ------------------------------------------------------------------------------------


func _test_matrix_schema_and_enumeration() -> void:
	M.reload()
	var cells := M.cells()
	_check(M.validate().is_empty(), "matrix validates: %s" % str(M.validate()))
	_check(M.coverage_gaps().is_empty(), "every catalog family and map has a reviewed rule: %s" % str(M.coverage_gaps()))
	var item_cells := 0
	var expected_items := 0
	for family_variant in BlockCatalog.scan().families:
		var family := family_variant as ItemFamilyDefinition
		for variant in family.variants:
			for mode_id in family.modes_allowed:
				expected_items += 1
				_check(cells.has(M.item_cell_id(family.variant_key(variant), mode_id)), "item cell %s@%s enumerated" % [family.variant_key(variant), mode_id])
	for cell_id in cells:
		if str(cells[cell_id].axis) == M.AXIS_ITEM:
			item_cells += 1
	_check(item_cells == expected_items + 1, "item cells = catalog variant x allowed mode (%d) + Barya" % expected_items)
	_check(expected_items == 70, "the current catalog yields 70 variant x mode cells (34 variants)")
	_check(cells.size() == 94, "the matrix has 94 cells (9 life, 4 map, 10 round, 70 item, Barya)")
	for map_id in MapCatalog.ids():
		_check(cells.has(M.map_cell_id(map_id)), "map cell %s enumerated" % map_id)
	for mode_id in DiagnosticContentCatalog.MODES:
		_check(cells.has("round:%s" % mode_id), "round cell %s enumerated" % mode_id)
	for command in M.KANGAROO_COMMANDS:
		_check(cells.has("round:kangaroo#%s" % command), "Kangaroo command cell %s enumerated" % command)
	var verified := 0
	for cell_id in cells:
		var cell: Dictionary = cells[cell_id]
		_check(M.REASON_TEXT.has(str(cell.reason)) and str(cell.min_protocol) == M.MIN_PROTOCOL and str(cell.min_content) == M.MIN_CONTENT, "%s carries a known reason and minimum versions" % cell_id)
		if str(cell.status) == M.STATUS_VERIFIED:
			verified += 1
	_check(verified == 0, "no cell is VERIFIED in the preparatory source")
	_check(str(cells[M.item_cell_id(COLUMN_1X3, "karera")].reason) == "DISABLED_BY_DEFAULT", "enabled_by_default=false variants are DISABLED_BY_DEFAULT")
	_check(str(cells["map:tutorial"].status) == M.STATUS_DISABLED, "the tutorial map is disabled for networked live play")
	_check(not cells.has(M.item_cell_id(SPAN_4X1, "lagsanay")), "no cell exists for a mode the family does not allow")


func _test_default_deny_and_override() -> void:
	var unknown := M.resolve("item:made.up.thing@karera", true)
	_check(not bool(unknown.selectable) and str(unknown.reason) == "UNKNOWN_CONTENT", "unknown content is denied even with the override")
	var engineering := M.item_cell_id(CELL_1X1, "karera")
	_check(not M.selectable(engineering, false), "an ENGINEERING cell is not selectable by default")
	_check(M.selectable(engineering, true), "an ENGINEERING cell is selectable with the development override")
	_check(str(M.resolve(engineering, false).reason) == "PENDING_NETWORK_VERIFICATION", "its refusal says it awaits network verification")
	_check(not M.selectable(M.item_cell_id(COLUMN_1X3, "karera"), true), "the override never unlocks a DISABLED cell")
	_check(not M.selectable("map:tutorial", true), "the override never unlocks the tutorial map")
	_check(M.override_requested(PackedStringArray([M.OVERRIDE_FLAG])) != OS.has_feature("android"), "the flag is honoured off Android (desktop test run)")
	_check(not M.override_requested(PackedStringArray()), "no flag, no override")


func _test_dependencies_and_cycles() -> void:
	var table := {
		"a": {"id": "a", "axis": "life", "status": M.STATUS_VERIFIED, "reason": "OK", "requires": ["b"], "evidence": "x"},
		"b": {"id": "b", "axis": "life", "status": M.STATUS_DISABLED, "reason": "NOT_IMPLEMENTED", "requires": [], "evidence": ""},
		"c": {"id": "c", "axis": "life", "status": M.STATUS_VERIFIED, "reason": "OK", "requires": ["d"], "evidence": "x"},
		"d": {"id": "d", "axis": "life", "status": M.STATUS_VERIFIED, "reason": "OK", "requires": ["c"], "evidence": "x"},
		"e": {"id": "e", "axis": "life", "status": M.STATUS_VERIFIED, "reason": "OK", "requires": [], "evidence": "x"},
	}
	var blocked := M._resolve(table, "a", true, [])
	_check(not bool(blocked.selectable) and str(blocked.reason) == "DEPENDENCY_DISABLED" and str(blocked.blocked_by) == "b", "a VERIFIED cell that needs a DISABLED cell is DEPENDENCY_DISABLED")
	_check(not bool(M._resolve(table, "c", true, []).selectable), "a dependency cycle is never selectable")
	_check(M._has_cycle(table, "c", []) and not M._has_cycle(table, "a", []), "cycle detection")
	_check(bool(M._resolve(table, "e", false, []).selectable), "a VERIFIED cell is selectable without the override")
	_check(not M.selectable("round:stack_karera_kangaroo", false), "stacks follow their Main/Twist cells")


func _test_route_pools_and_schedule() -> void:
	var offline := Array(M.offline_live_variants())
	offline.sort()
	var sorted_expected := [CELL_1X1, "build.hollow_blocks.stack_2x3", SPAN_4X1]
	sorted_expected.sort()
	_check(offline == sorted_expected, "offline live pool equals the three P05 slice variants")
	_check(M.live_variants(PackedStringArray(["karera"]), false).is_empty(), "a strict host deals nothing (no VERIFIED item cell)")
	var karera := M.live_variants(PackedStringArray(["karera"]), true)
	_check(karera.has(CELL_1X1) and karera.has(WALIS_3X3) and karera.has(BOMB) and not karera.has(COLUMN_1X3), "override Karera pool holds engineering cells and no disabled variant")
	var lagsanay := M.live_variants(PackedStringArray(["lagsanay"]), true)
	_check(not lagsanay.has(SPAN_4X1) and not lagsanay.has(WALIS_3X3) and lagsanay.has(CELL_1X1), "a Lagsanay round deals only Lagsanay-allowed families")
	var stacked := M.live_variants(PackedStringArray(["karera", "kangaroo"]), true)
	for key in stacked:
		_check(M.selectable(M.item_cell_id(key, "karera"), true) and M.selectable(M.item_cell_id(key, "kangaroo"), true), "stack pool %s is selectable in both modes" % key)
	_check(M.live_variants(PackedStringArray(), true).is_empty(), "no modes, no eggs (fail closed)")
	_check(M.available_modes(false).is_empty() and M.available_modes(true).size() == 3, "available modes follow the round cells")
	_check(M.schedule_pairs(false).is_empty() and M.schedule_pairs(true).size() == EventSchedule.enabled_pairs().size(), "stack rows follow the stack cells")
	var karera_entry := {"main": EventSchedule.Challenge.KARERA, "twist": EventSchedule.Challenge.NONE}
	var stack_entry := {"main": EventSchedule.Challenge.KANGAROO, "twist": EventSchedule.Challenge.LAGSANAY}
	_check(M.round_cell_id(karera_entry) == "round:karera", "Karera entry maps to its cell")
	_check(M.round_cell_id(stack_entry) == "round:stack_kangaroo_lagsanay", "a stack entry maps to its stack cell")
	_check(M.round_cell_id(EventSchedule.sudden_death_entry()) == "round:sudden_death_lagsanay", "sudden death maps to its cell")


func _test_start_gate_and_lobby() -> void:
	var strict := M.start_gate(MapCatalog.DEFAULT_ID, false)
	_check(not strict.is_empty() and strict.contains(M.OVERRIDE_FLAG), "a strict host gets a readable refusal naming the override")
	_check(M.start_gate(MapCatalog.DEFAULT_ID, true).is_empty(), "the development host may start on the default map")
	_check(not M.start_gate("tutorial", true).is_empty(), "the tutorial map is refused with a reason")
	_check(not M.start_gate("no_such_map", true).is_empty(), "an unknown map is refused")
	var lines := M.lobby_summary(true)
	_check(not lines.is_empty() and str(lines[0]).begins_with("UNVERIFIED CONTENT"), "lobby summary leads with the UNVERIFIED CONTENT banner")
	_check(not M.lobby_summary(false)[0].begins_with("UNVERIFIED"), "no banner without the override")
	var manager := CaptureManager.new()
	manager.network_route = NetworkSessionManager.ROUTE_SCHEDULED
	_check(manager.live_content_summary().is_empty(), "the scheduled route shows no live content list")
	manager.network_route = NetworkSessionManager.ROUTE_LIVE_BUILD
	_check(not manager.live_content_summary().is_empty(), "the live route shows the host content list")
	manager.free()


func _test_manifest_digest() -> void:
	var built := CompatibilityManifest.build()
	var manifest: Dictionary = built.manifest
	_check(manifest.has("live_matrix") and int(manifest.live_matrix.version) == M.MATRIX_VERSION, "manifest carries the live matrix")
	_check((manifest.live_matrix.cells as Array).size() == M.cells().size(), "manifest lists every matrix cell")
	_check(str(manifest.build) == "tilaok-nlb-p08-2026-10-21", "build identity is the P08 build")
	var changed := manifest.duplicate(true)
	(changed.live_matrix.cells[0] as Dictionary).status = M.STATUS_VERIFIED
	_check(CompatibilityManifest.sha256(changed) != built.digest, "a different matrix gives a different digest (INCOMPATIBLE before admission)")
	_check(CompatibilityManifest.sha256(manifest) == built.digest, "digest is stable for the same matrix")


func _test_matrix_document_parity() -> void:
	var path := ProjectSettings.globalize_path("res://").path_join(DOC_PATH)
	var file := FileAccess.open(path, FileAccess.READ)
	_check(file != null, "matrix document exists at %s" % DOC_PATH)
	if file == null:
		return
	var text := file.get_as_text()
	file.close()
	for row in M.markdown_rows():
		_check(text.contains(row), "matrix document lists %s" % row.get_slice("|", 1).strip_edges())


# --- contract v1.4 codecs ----------------------------------------------------------------------


func _transient(kind: int, transient_id: int) -> Dictionary:
	return {
		"transient_kind": kind, "transient_id": transient_id, "owner_entity": 9,
		"position": Vector2(128.5, -64.25), "velocity": Vector2(640, 0), "extent": Vector2(32, 32),
		"phase": 2, "timer_ms": 700, "owner_seat": 1, "captive_seat": -1,
	}


func _test_transient_codec_and_caps() -> void:
	var raw := NetworkMatchCodec.encode_transient_record(_transient(NetworkMatchCodec.TRANSIENT_PROJECTILE, 5))
	_check(raw.size() == NetworkMatchCodec.TRANSIENT_BYTES, "transient record is exactly 37 bytes")
	var decoded := NetworkMatchCodec.decode_transient_record(raw)
	_check(bool(decoded.ok) and int(decoded.transient_id) == 5 and decoded.position == Vector2(128.5, -64.25) and int(decoded.owner_seat) == 1, "transient record round-trips")
	_check(not decoded.has("kind") and not decoded.has("seat") and not decoded.has("entity_id"), "transient keys never collide with objective/seat/entity records")
	var bubble := _transient(NetworkMatchCodec.TRANSIENT_BUBBLE, 1)
	bubble.captive_seat = 3
	_check(int(NetworkMatchCodec.decode_transient_record(NetworkMatchCodec.encode_transient_record(bubble)).captive_seat) == 3, "bubble keeps its captive seat")
	for bad in [{"transient_kind": 9}, {"transient_id": 0}, {"captive_seat": 4}, {"phase": 8}, {"owner_seat": -2}]:
		var record := _transient(NetworkMatchCodec.TRANSIENT_BLAST, 2)
		record.merge(bad, true)
		_check(NetworkMatchCodec.encode_transient_record(record).is_empty(), "out-of-range transient %s is refused" % str(bad))
	var truncated := raw.slice(0, 36)
	_check(not bool(NetworkMatchCodec.decode_transient_record(truncated).ok), "a short transient record is refused")
	var ended := NetworkMatchCodec.encode_transient_end(NetworkMatchCodec.TRANSIENT_MOVER, 7)
	_check(ended.size() == 4 and bool(NetworkMatchCodec.decode_record(ended).ended), "transient end notice is 4 bytes")
	var projectiles: Array = []
	for index in 16:
		projectiles.append(_transient(NetworkMatchCodec.TRANSIENT_PROJECTILE, index + 1))
	_check(NetworkMatchCodec.transient_cap_status(projectiles) == NetworkFrame.Reason.OK, "16 projectiles fit the cap")
	projectiles.append(_transient(NetworkMatchCodec.TRANSIENT_PROJECTILE, 17))
	_check(NetworkMatchCodec.transient_cap_status(projectiles) == NetworkFrame.Reason.CONTENT_LIMIT_EXCEEDED, "a 17th projectile is CONTENT_LIMIT_EXCEEDED, never truncated")
	var bubbles: Array = []
	for index in 5:
		bubbles.append(_transient(NetworkMatchCodec.TRANSIENT_BUBBLE, index + 1))
	_check(NetworkMatchCodec.transient_cap_status(bubbles) == NetworkFrame.Reason.CONTENT_LIMIT_EXCEEDED, "a 5th bubble exceeds the cap")
	var records: Array[PackedByteArray] = []
	for transient in projectiles:
		records.append(NetworkMatchCodec.encode_transient_record(transient))
	var over := NetworkMatchCodec.unpack_snapshot(NetworkMatchCodec.pack_snapshot(records))
	_check(not bool(over.ok) and int(over.get("reason", -1)) == NetworkFrame.Reason.SNAPSHOT_LIMIT, "an over-cap snapshot is refused as SNAPSHOT_LIMIT")
	records.pop_back()
	_check(bool(NetworkMatchCodec.unpack_snapshot(NetworkMatchCodec.pack_snapshot(records)).ok), "a capped snapshot with transients unpacks")
	var metadata := {"match_id": 1, "round_id": 1, "attempt_id": 1, "phase": 3, "map_id": "default"}
	var update := NetworkMatchCodec.decode_state_update(NetworkMatchCodec.encode_state_update(metadata, 10, 0, raw))
	_check(bool(update.ok) and bool(update.record.transient), "STATE_UPDATE carries a transient record")


func _test_lifecycle_flag_and_client_transients() -> void:
	var client := CaptureManager.new()
	client.client_mode = true
	client._handle_client_packet(1, NetworkFrame.Family.MATCH_LIFECYCLE, PackedByteArray([1, 1, 0, 0, 0, 0, 0, 0, 0, NetworkSessionManager.ROUTE_LIVE_BUILD, 1]))
	_check(client.match_active and client.client_unverified_content, "lifecycle flag bit 0 shows the UNVERIFIED CONTENT banner")
	client.match_active = false
	client._handle_client_packet(1, NetworkFrame.Family.MATCH_LIFECYCLE, PackedByteArray([1, 2, 0, 0, 0, 0, 0, 0, 0, NetworkSessionManager.ROUTE_LIVE_BUILD, 2]))
	_check(not client.match_active, "unknown lifecycle flag bits are rejected")
	client.client_replica_state = {"transients": {}}
	var record := NetworkMatchCodec.decode_transient_record(NetworkMatchCodec.encode_transient_record(_transient(NetworkMatchCodec.TRANSIENT_PROJECTILE, 3)))
	client._apply_client_transient(record)
	_check((client.client_replica_state.transients as Dictionary).size() == 1, "client installs a host transient")
	client._apply_client_transient(NetworkMatchCodec.decode_transient_end(NetworkMatchCodec.encode_transient_end(NetworkMatchCodec.TRANSIENT_PROJECTILE, 3)))
	_check((client.client_replica_state.transients as Dictionary).is_empty(), "an end notice removes it")
	client._apply_client_transient(record)
	(client.client_replica_state.transients["1:3"] as Dictionary).received_ms = Time.get_ticks_msec() - NetworkSessionManager.TRANSIENT_STALE_MS - 1
	client._apply_client_transient(NetworkMatchCodec.decode_transient_record(NetworkMatchCodec.encode_transient_record(_transient(NetworkMatchCodec.TRANSIENT_BLAST, 4))))
	_check(not (client.client_replica_state.transients as Dictionary).has("1:3"), "a transient the host stopped refreshing is dropped as stale")
	var snapshot_records: Array[Dictionary] = [record]
	var replica := client._replica_from_records({"match_id": 1, "round_id": 1, "attempt_id": 1, "tick": 1, "stage_version": 0, "event_revision": 0}, snapshot_records, 1)
	_check((replica.transients as Dictionary).has("1:3"), "a snapshot installs live transients (resync during a blast/sweep/capture)")
	client.free()


func _test_reason_mapping() -> void:
	var expected := {
		"one_shot": [NetworkFrame.Reason.OK, NetworkPlacementCodec.Detail.CLEANUP_DONE],
		"lethal_clearance": [NetworkFrame.Reason.PLACEMENT_BLOCKED, NetworkPlacementCodec.Detail.LETHAL_CLEARANCE],
		"crush_risk": [NetworkFrame.Reason.PLACEMENT_BLOCKED, NetworkPlacementCodec.Detail.CRUSH_RISK],
		"projectile_lane": [NetworkFrame.Reason.PLACEMENT_BLOCKED, NetworkPlacementCodec.Detail.PROJECTILE_LANE],
		"stale_target": [NetworkFrame.Reason.STALE_STATE, NetworkPlacementCodec.Detail.CLEANUP_STALE],
		"unsafe_support": [NetworkFrame.Reason.PLACEMENT_BLOCKED, NetworkPlacementCodec.Detail.UNSAFE_SUPPORT],
		"objective_rejected": [NetworkFrame.Reason.PLACEMENT_BLOCKED, NetworkPlacementCodec.Detail.OBJECTIVE_REJECTED],
		"variant_disabled": [NetworkFrame.Reason.INVENTORY, NetworkPlacementCodec.Detail.VARIANT_DISABLED],
	}
	for code in expected:
		_check(NetworkPlacementCodec.reason_for_code(code) == int(expected[code][0]) and NetworkPlacementCodec.detail_for_code(code) == int(expected[code][1]), "%s maps to its v1.4 reason/detail" % code)
	for detail in range(41, 50):
		_check(NetworkPlacementCodec.DETAIL_TEXT.has(detail), "detail %d has client-local text" % detail)


func _test_build_controls_are_not_freeze_intent() -> void:
	var router := LocalInputRouter.new()
	root.add_child(router)
	router.registry.join_keyboard("K1")
	router.phase = LocalInputRouter.Phase.PLAY
	router.live_build_confirm_enabled = true
	var edges: Array = []
	router.intentional_input_edge.connect(
		func(seat: int, action: String, _source: String, pressed: bool, _usec: int) -> void: edges.append([seat, action, pressed])
	)
	for action in ["build_toggle", "live_rotate", "live_cancel", "confirm", "aim_left", "aim_up"]:
		router._handle_action_edge(0, action, "p07:%s" % action, true)
		router._handle_action_edge(0, action, "p07:%s" % action, false)
	_check(edges.is_empty(), "build aim/rotate/confirm/cancel never emit Freeze movement edges")
	router._handle_action_edge(0, "left", "p07:left", true)
	_check(edges.size() == 1 and str(edges[0][1]) == "left", "real movement while building still counts for Freeze")
	router.queue_free()


# --- host room on the networked live route ----------------------------------------------------


func _open_live(unverified: bool) -> NLBP06NetworkLiveBuildMatchRoom:
	var room := LIVE_NETWORK_ROOM.instantiate() as NLBP06NetworkLiveBuildMatchRoom
	room.unverified_content = unverified
	room.go_countdown_seconds = 0.1
	root.add_child(room)
	await process_frame
	await physics_frame
	for seat_index in [room.join_keyboard("K1"), room.join_keyboard("K2")]:
		room.input_router.registry.set_ready(seat_index, true)
	room.tuning.match_target_score_units = 100000
	return room


func _to_live_play(room: NLBP06NetworkLiveBuildMatchRoom) -> bool:
	room._finish_pugad_timeout()
	room._process(0.2)
	return room.phase_controller.phase == MatchPhaseController.Phase.PLAY


func _close(room: Node) -> void:
	if room != null and is_instance_valid(room):
		room.queue_free()
	await process_frame


func _test_strict_host_refuses_start() -> void:
	var room := await _open_live(false)
	_check(not room.start_match(), "a strict host refuses the networked live match")
	_check(room.last_message.contains(M.OVERRIDE_FLAG), "the refusal is readable and names the development override")
	_check(room.available_modes.is_empty(), "a strict host offers no Main Challenge")
	await _close(room)


func _test_live_room_enforcement() -> void:
	var room := await _open_live(true)
	_check(room.start_match(), "the development host starts the networked live match")
	var allowed := M.live_variants(room.pugad_mode_ids(), true)
	var subset := true
	for egg in room.egg_pool:
		var key := str(egg.variant_key)
		subset = subset and (allowed.has(key) or BaryaObjectiveDefinition.is_variant(key))
	_check(subset and not room.egg_pool.is_empty(), "every dealt egg is a selectable matrix cell for this round")
	_check(room.tuning.item_enabled_variants == allowed, "the round pool is the matrix pool, not a hard-coded list")
	if not _to_live_play(room):
		_check(false, "live room reaches Play")
		await _close(room)
		return
	var seat := int(room.placement_controller.cursors.keys()[0])
	var request := {"request_id": 1, "peer_generation": 1, "inventory_id": int(room._inventory_ids[seat]), "expected_stage_version": 0, "cell": Vector2i(4, 4), "rotation": 0}
	room.unverified_content = false
	var refused := room.network_submit_placement(seat, request, Time.get_ticks_usec())
	_check(str(refused.code) == "variant_disabled", "an intent for a cell that is no longer selectable is variant_disabled")
	var commit := room._commit_live_intent(seat, {"request_id": "t", "variant_key": str(room.placement_controller.cursors[seat].variant_key)}, 1)
	_check(str(commit.code) == "variant_disabled" and not bool(commit.allowed), "the commit-time recheck refuses it for local seats too")
	room.unverified_content = true
	room._sudden_death_active = true
	_check(str(room.network_submit_placement(seat, request, Time.get_ticks_usec()).code) == "wrong_phase", "sudden death accepts no placement request")
	room._sudden_death_active = false
	var states := room.network_transient_states()
	_check(NetworkMatchCodec.transient_cap_status(states) == NetworkFrame.Reason.OK, "host transient list stays within wire caps")
	room._on_live_one_shot_committed(Rect2(256, 256, 192, 192), seat)
	var blasts := 0
	for state in room.network_transient_states():
		blasts += 1 if int(state.transient_kind) == NetworkMatchCodec.TRANSIENT_BLAST else 0
	_check(blasts == 1, "a committed one-shot edit replicates one host blast flash")
	var snapshot := room.network_replication_snapshot(1, 1, 1)
	_check(not bool(snapshot.transient_overflow), "the replication snapshot includes transients without overflow")
	await _close(room)


func _clear_cells(room: NLBP06NetworkLiveBuildMatchRoom, key: String, count: int) -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	var clearance := room.items.owner_seat_clearance(room._live_actor_swept_rects())
	for y in range(room.tuning.arena_height_tiles):
		for x in range(room.tuning.arena_width_tiles):
			var cell := Vector2i(x, y)
			if bool(room.items.validate_placement(key, cell, 0, clearance).allowed):
				var spaced := true
				for other in found:
					spaced = spaced and (absi(other.x - cell.x) > 3 or absi(other.y - cell.y) > 3)
				if spaced:
					found.append(cell)
					if found.size() >= count:
						return found
	return found


func _test_one_shot_entity_age() -> void:
	var room := await _open_live(true)
	if not room.start_match() or not _to_live_play(room):
		_check(false, "live room reaches Play for the one-shot checks")
		await _close(room)
		return
	room.tuning.item_enabled_variants = PackedStringArray([CELL_1X1, WALIS_3X3, BOMB])
	var cells := _clear_cells(room, CELL_1X1, 2)
	if cells.size() < 2:
		_check(false, "two clear cells exist for the one-shot checks")
		await _close(room)
		return
	var no_actors: Array[Rect2] = []
	room.items.live_boundary = 100
	var first := room.items.place_live(CELL_1X1, cells[0], 0, 0, no_actors, false)
	_check(bool(first.allowed), "a live piece commits at boundary 100")
	var walis_cell := cells[0] - Vector2i(1, 1)
	var walis := room.items.validate_placement(WALIS_3X3, walis_cell, 0)
	_check(bool(walis.get("one_shot", false)), "Walis validates as a one-shot edit")
	var same := room.items.apply_live_one_shot(walis, 1, false)
	_check(bool(same.allowed) and (same.removed as Array).is_empty(), "a same-boundary Walis never removes an edit of that boundary (no crash on protected areas)")
	room.items.live_boundary = 101
	var later := room.items.apply_live_one_shot(walis, 1, false)
	_check((later.removed as Array).has(str(first.instance_id)), "an edit committed at an earlier boundary is a live target (entity age)")
	_check(str(later.code) == "one_shot" and NetworkPlacementCodec.reason_for_code(str(later.code)) == NetworkFrame.Reason.OK, "an accepted one-shot is OK on the wire")
	room.items.live_boundary = 102
	var second := room.items.place_live(CELL_1X1, cells[1], 0, 0, no_actors, false)
	room.items.live_boundary = 103
	var bomb := room.items.validate_placement(BOMB, cells[1], 0)
	var blast := room.items.apply_live_one_shot(bomb, 1, false)
	_check(bool(bomb.get("one_shot", false)) and (blast.removed as Array).has(str(second.instance_id)), "an explosive removes an older live piece in its area at detonation")
	_check(not room.items.pieces.has(str(second.instance_id)) and not room.items.live_commit_boundary.has(str(second.instance_id)), "removal also clears the entity age record")
	await _close(room)


func _test_lethal_and_fall_checks() -> void:
	var room := await _open_live(true)
	if not room.start_match() or not _to_live_play(room):
		_check(false, "live room reaches Play for the hazard checks")
		await _close(room)
		return
	room.tuning.item_enabled_variants = PackedStringArray([CELL_1X1, SPIKES, WOOD_BOX])
	var actor := room.actors[0] as ChickenController
	var actor_rects: Array[Rect2] = [actor.hit_rect()]
	var near := Vector2i(floori(actor.hit_rect().get_center().x / room.tuning.grid_cell_wu) + 1, floori(actor.hit_rect().end.y / room.tuning.grid_cell_wu))
	var spikes_verdict := {"allowed": true, "footprint": Rect2(Vector2(near) * room.tuning.grid_cell_wu, Vector2.ONE * room.tuning.grid_cell_wu)}
	var lethal := room._live_effect_check(SPIKES, 0, spikes_verdict, actor_rects)
	_check(str(lethal.get("code", "")) == "lethal_clearance", "a lethal hazard inside the extra clearance of a live chicken is refused")
	var solid := room._live_effect_check(CELL_1X1, 0, spikes_verdict, actor_rects)
	_check(solid.is_empty() or str(solid.get("code", "")) != "lethal_clearance", "plain construction is not held to the lethal clearance")
	var above := actor.hit_rect()
	above.position.y -= room.tuning.grid_cell_wu * 2.5
	var box_verdict := {"allowed": true, "footprint": Rect2(above.position, Vector2.ONE * room.tuning.grid_cell_wu * 2.0)}
	_check(str(room._live_effect_check(WOOD_BOX, 0, box_verdict, actor_rects).get("code", "")) == "crush_risk", "a movable block over a chicken's head is crush_risk")
	_check(room._live_effect_rects_in_flight().is_empty(), "no in-flight effects at the start of Play")
	await _close(room)

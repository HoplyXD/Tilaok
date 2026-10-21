class_name NlbP11ReportCore
extends RefCounted
## NLB-P11-T01 metrics report core (authored, never run). Parses NLB_TELEM v1 files and maps each
## PROPOSED budget to PASS / FAIL / COULD-NOT-RUN together with the hardware record it needs.
##
## Rules this core enforces so a report can never overstate evidence:
## - A budget outcome other than COULD-NOT-RUN requires a complete hardware record (REQUIRED_HARDWARE)
##   and a run long enough for that budget. SYNTHETIC runs never produce PASS for a phone budget.
## - Budgets the team has not set (traffic, RTT, battery/thermal, cadence) stay "EVIDENCE ONLY": the
##   measured numbers are listed, never judged.
## - End-to-end <=100 ms and process RSS are not measurable inside the engine: they are
##   COULD-NOT-RUN unless the hardware record carries the externally measured value.
## - Warm-up frames are NOT excluded (the telemetry is one cumulative histogram), so a p95 here is
##   equal to or stricter than the contract's post-warm-up figure; the report says so.
## The thresholds below are the PROPOSED targets from the measurement contract v1 section 7 and
## remain unmeasured until the team records real hardware.

const PASS := "PASS"
const FAIL := "FAIL"
const COULD_NOT_RUN := "COULD-NOT-RUN"
const EVIDENCE_ONLY := "EVIDENCE ONLY"

const HOST_FRAME_P95_MS := 16.67
const PHONE_FRAME_P95_MS := 33.3
const PHONE_MIN_FPS := 30.0
const END_TO_END_P95_MS := 100.0
const MEMORY_CAP_MIB := 512.0
const JOIN_MAX_S := 10.0
const RECLAIM_MAX_S := 5.0
const PROFILE_SECONDS := 720.0
const REQUIRED_HARDWARE := [
	"build",
	"engine",
	"date",
	"platform_os",
	"device_model",
	"battery_thermal_state",
	"profile_seed",
	"seat_count_input_type",
	"map_stage_load",
	"network_topology",
	"duration_s",
	"procedure",
	"raw_artifact_path",
	"reviewer",
]


## Parses one telemetry file's text into {header, summaries, gauges, events, last_t, seconds}.
static func parse_telemetry(text: String) -> Dictionary:
	var result := {
		"header": {}, "summaries": {}, "gauges": {}, "events": [], "last_t": 0.0, "truncated": false
	}
	for line in text.split("\n", false):
		if not line.begins_with(NlbTelemetry.PREFIX + " "):
			continue
		var fields := _fields(line.trim_prefix(NlbTelemetry.PREFIX + " "))
		match str(fields.get("_kind", "")):
			"header":
				result.header = fields
			"summary":
				result.summaries[str(fields.get("metric", ""))] = fields
			"gauge":
				result.gauges[str(fields.get("metric", ""))] = fields
			"event":
				result.events.append(fields)
			"second":
				result.last_t = maxf(float(result.last_t), float(str(fields.get("t", "0"))))
			"truncated":
				result.truncated = true
	return result


## Parses "key=value" lines of a hardware record file; unknown keys are kept, blanks ignored.
static func parse_hardware(text: String) -> Dictionary:
	var record := {}
	for line in text.split("\n", false):
		var stripped := line.strip_edges()
		if stripped.is_empty() or stripped.begins_with("#") or not stripped.contains("="):
			continue
		var split := stripped.split("=", true, 1)
		record[split[0].strip_edges()] = split[1].strip_edges()
	return record


static func missing_hardware(record: Dictionary) -> PackedStringArray:
	var missing := PackedStringArray()
	for key in REQUIRED_HARDWARE:
		var value := str(record.get(key, "")).strip_edges()
		if value.is_empty() or value.to_lower() in ["unknown", "tbd", "n/a"]:
			missing.append(key)
	return missing


## Evaluates every budget. `host` and `phone` are parse_telemetry() results (or {} when absent);
## the hardware records are parse_hardware() results. Returns an Array of
## {budget, target, outcome, measured, reason}.
static func evaluate(
	host: Dictionary, host_hardware: Dictionary, phone: Dictionary, phone_hardware: Dictionary
) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	rows.append(_host_frame(host, host_hardware))
	rows.append(_phone_frame(phone, phone_hardware))
	rows.append(_end_to_end(phone_hardware))
	rows.append(_memory("host", host_hardware))
	rows.append(_memory("phone", phone_hardware))
	rows.append(_timing_budget("Join to lobby", "join_to_seat_ms", JOIN_MAX_S, phone, phone_hardware))
	rows.append(_timing_budget("Reclaim to ready", "reclaim_to_ack_ms", RECLAIM_MAX_S, phone, phone_hardware))
	rows.append(_cleanup(host, host_hardware))
	for entry in [
		["RTT (ENet single-endpoint estimate)", "rtt_ms"],
		["Traffic: application bytes/s", "app_tx_bytes_per_s"],
		["Traffic: network bytes/s (ENet)", "net_tx_bytes_per_s"],
		["State cadence (receive interval)", "state_rx_interval_ms"],
		["Input receipt to state send", "input_receipt_to_state_ms"],
		["Placement receipt to response", "placement_receipt_to_response_ms"],
		["Snapshot size", "snapshot_bytes"],
	]:
		rows.append(_evidence_only(str(entry[0]), str(entry[1]), host, phone))
	rows.append(
		{
			"budget": "Battery / thermal",
			"target": "no threshold set (evidence only)",
			"outcome": COULD_NOT_RUN,
			"measured": "external adb sampler output required",
			"reason": "needs the physical-phone 30-minute sampler; see docs/evidence/nlb/p11/README.md",
		}
	)
	return rows


static func render_markdown(rows: Array[Dictionary], synthetic: bool) -> String:
	var text := "# NLB-P11 metrics report\n\n"
	if synthetic:
		text += "**SYNTHETIC input detected. Synthetic runs are engineering evidence only and are never counted as phones or participants.**\n\n"
	text += "Thresholds are PROPOSED and unmeasured until the team records hardware. Warm-up frames are included in every percentile (equal or stricter than the post-warm-up contract figure).\n\n"
	text += "| Budget | Target | Outcome | Measured | Reason |\n|---|---|---|---|---|\n"
	for row in rows:
		text += (
			"| %s | %s | %s | %s | %s |\n"
			% [row.budget, row.target, row.outcome, row.measured, row.reason]
		)
	return text


# --- budgets ---------------------------------------------------------------------------------


static func _host_frame(host: Dictionary, hardware: Dictionary) -> Dictionary:
	var row := _row("Host frame (60 Hz, 1080p)", "p95 frame interval <= 16.67 ms; 60 Hz held")
	var gate := _gate(host, hardware, PROFILE_SECONDS)
	if not gate.is_empty():
		return _cnr(row, gate)
	var summary := _summary(host, "frame_interval_ms")
	if summary.is_empty() or int(str(summary.get("count", "0"))) == 0:
		return _cnr(row, "no frame_interval_ms samples")
	var p95 := float(str(summary.p95))
	row.measured = "p50=%s p95=%s max=%s ms (n=%s)" % [summary.p50, summary.p95, summary.max, summary.count]
	row.outcome = PASS if p95 <= HOST_FRAME_P95_MS else FAIL
	row.reason = "resolution %s ms; resolution-limited p95 is an upper edge" % summary.resolution
	return row


static func _phone_frame(phone: Dictionary, hardware: Dictionary) -> Dictionary:
	var row := _row("Phone frame (>=30 FPS, 720p)", "FPS >= 30 and p95 <= 33.3 ms")
	if _is_synthetic(phone):
		return _cnr(row, "SYNTHETIC client: not phone evidence")
	var gate := _gate(phone, hardware, PROFILE_SECONDS)
	if not gate.is_empty():
		return _cnr(row, gate)
	if str(phone.header.get("platform", "")).to_lower() != "android":
		return _cnr(row, "telemetry platform is not Android")
	var summary := _summary(phone, "frame_interval_ms")
	if summary.is_empty() or int(str(summary.get("count", "0"))) == 0:
		return _cnr(row, "no frame_interval_ms samples")
	var p95 := float(str(summary.p95))
	var mean_fps := 1000.0 / maxf(float(str(summary.p50)), 0.001)
	row.measured = "p50=%s p95=%s max=%s ms (median FPS ~%.1f)" % [summary.p50, summary.p95, summary.max, mean_fps]
	row.outcome = PASS if (p95 <= PHONE_FRAME_P95_MS and mean_fps >= PHONE_MIN_FPS) else FAIL
	row.reason = "median-based FPS; p95 resolution %s ms" % summary.resolution
	return row


static func _end_to_end(hardware: Dictionary) -> Dictionary:
	var row := _row("End-to-end visible response", "p95 <= 100 ms (high-speed capture)")
	var value := str(hardware.get("end_to_end_p95_ms", "")).strip_edges()
	var missing := missing_hardware(hardware)
	if value.is_empty() or not value.is_valid_float() or not missing.is_empty():
		return _cnr(row, "needs an external capture value (end_to_end_p95_ms) and a complete phone hardware record")
	row.measured = "p95=%s ms (external capture: %s)" % [value, str(hardware.get("end_to_end_method", "unrecorded"))]
	row.outcome = PASS if float(value) <= END_TO_END_P95_MS else FAIL
	row.reason = "external measurement; never inferred from RTT"
	return row


static func _memory(label: String, hardware: Dictionary) -> Dictionary:
	var row := _row("Memory (%s)" % label, "RSS <= 512 MiB; no unexplained growth")
	var value := str(hardware.get("rss_peak_mib", "")).strip_edges()
	if value.is_empty() or not value.is_valid_float() or not missing_hardware(hardware).is_empty():
		return _cnr(row, "process RSS is not available in-engine; needs external sampler rss_peak_mib and a complete hardware record")
	row.measured = "peak RSS %s MiB (external sampler)" % value
	row.outcome = PASS if float(value) <= MEMORY_CAP_MIB else FAIL
	row.reason = "godot_static_bytes in telemetry is not RSS"
	return row


static func _timing_budget(
	label: String, metric: String, max_seconds: float, source: Dictionary, hardware: Dictionary
) -> Dictionary:
	var row := _row(label, "max <= %.0f s (20 trials per device)" % max_seconds)
	if _is_synthetic(source):
		return _cnr(row, "SYNTHETIC client: not device evidence")
	var summary := _summary(source, metric)
	if summary.is_empty() or int(str(summary.get("count", "0"))) < 20:
		return _cnr(row, "fewer than 20 trials recorded")
	if not missing_hardware(hardware).is_empty():
		return _cnr(row, "hardware record incomplete: %s" % ", ".join(missing_hardware(hardware)))
	var maximum := float(str(summary.max)) / 1000.0
	row.measured = "p95=%s ms max=%s ms (n=%s)" % [summary.p95, summary.max, summary.count]
	row.outcome = PASS if maximum <= max_seconds else FAIL
	row.reason = "reserved-seat grace excluded by construction (timer starts at reconnect)"
	return row


static func _cleanup(host: Dictionary, hardware: Dictionary) -> Dictionary:
	var row := _row("Ten-cycle cleanup", "no monotonic unexplained growth over 10 cycles")
	var cycles: Array = []
	for event in host.get("events", []):
		if str(event.get("name", "")) == "cycle":
			cycles.append(event)
	if cycles.size() < 10:
		return _cnr(row, "fewer than 10 cycle events recorded")
	if not missing_hardware(hardware).is_empty():
		return _cnr(row, "hardware record incomplete: %s" % ", ".join(missing_hardware(hardware)))
	var grown: PackedStringArray = PackedStringArray()
	for key in cycles[0]:
		var name := str(key)
		if name in ["_kind", "name", "t", "cycle", "match_id", "session_epoch", "match_lineage"]:
			continue
		var values: Array = []
		for cycle in cycles:
			values.append(float(str(cycle.get(name, "0"))))
		var strictly_up := true
		for index in range(1, values.size()):
			if values[index] <= values[index - 1]:
				strictly_up = false
		if strictly_up:
			grown.append(name)
	row.measured = "%d cycles; strictly growing counters: %s" % [cycles.size(), ", ".join(grown) if not grown.is_empty() else "none"]
	row.outcome = FAIL if not grown.is_empty() else PASS
	row.reason = "per-cycle teardown_counts(); final-minus-initial must also be reviewed by a human"
	return row


static func _evidence_only(label: String, metric: String, host: Dictionary, phone: Dictionary) -> Dictionary:
	var row := _row(label, "no threshold set (evidence only)")
	var parts: PackedStringArray = PackedStringArray()
	for pair in [["host", host], ["client", phone]]:
		var summary := _summary(pair[1], metric)
		if not summary.is_empty() and int(str(summary.get("count", "0"))) > 0:
			parts.append(
				"%s p50=%s p95=%s max=%s %s" % [pair[0], summary.p50, summary.p95, summary.max, summary.unit]
			)
	row.outcome = EVIDENCE_ONLY if not parts.is_empty() else COULD_NOT_RUN
	row.measured = "; ".join(parts) if not parts.is_empty() else "no samples"
	row.reason = "team has not set a threshold" if not parts.is_empty() else "not measured"
	return row


# --- helpers ---------------------------------------------------------------------------------


static func _row(budget: String, target: String) -> Dictionary:
	return {"budget": budget, "target": target, "outcome": COULD_NOT_RUN, "measured": "-", "reason": "-"}


static func _cnr(row: Dictionary, reason: String) -> Dictionary:
	row.outcome = COULD_NOT_RUN
	row.reason = reason
	return row


## "" when the run may be judged, else the reason it may not.
static func _gate(telemetry: Dictionary, hardware: Dictionary, min_seconds: float) -> String:
	if telemetry.is_empty() or telemetry.get("header", {}).is_empty():
		return "no telemetry file"
	var missing := missing_hardware(hardware)
	if not missing.is_empty():
		return "hardware record incomplete: %s" % ", ".join(missing)
	if float(telemetry.last_t) < min_seconds:
		return "run lasted %.0f s; the profile needs %.0f s (2 min warm-up + 10 min)" % [float(telemetry.last_t), min_seconds]
	if bool(telemetry.get("truncated", false)):
		return "telemetry output was truncated"
	return ""


static func _is_synthetic(telemetry: Dictionary) -> bool:
	return str(telemetry.get("header", {}).get("synthetic", "")) == "SYNTHETIC"


static func _summary(telemetry: Dictionary, metric: String) -> Dictionary:
	return telemetry.get("summaries", {}).get(metric, {})


static func _fields(text: String) -> Dictionary:
	var fields := {}
	var parts := text.split(" ", false)
	if parts.is_empty():
		return fields
	fields["_kind"] = parts[0]
	for index in range(1, parts.size()):
		var split := parts[index].split("=", true, 1)
		if split.size() == 2:
			fields[split[0]] = split[1]
	return fields

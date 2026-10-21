class_name NlbTelemetry
extends RefCounted
## NLB-P11: bounded, opt-in telemetry for the networked build (contract v1 §7 measurement rows).
##
## OFF unless `--nlb-telemetry=<path>` is given in a development build (NlbBuildFlags): release and
## Android client builds never create one. `<path>` must be under user:// or the project's ignored
## build/ folder. All timing uses the monotonic microsecond clock; RTT comes from ENet's single
## endpoint estimate; nothing here ever derives one-way or end-to-end latency, and a room code,
## token, proof, invitation or address is never recorded (event fields are a strict allowlist of
## numbers and short identifiers).
##
## Bounds: a fixed histogram per distribution metric (HISTOGRAM_BUCKETS buckets, one overflow
## bucket, running count/sum/min/max), constant-size gauges, one line per second, an event cap, and a
## hard output cap of MAX_FILE_BYTES after which a single TRUNCATED line is written and recording
## stops. Memory use is constant regardless of run length.
##
## Line grammar (one record per line, space-separated key=value after a fixed prefix):
##   NLB_TELEM v1 header   build= engine= platform= role= profile= seed= synthetic= started_usec=
##   NLB_TELEM v1 second   t= frames= role= <counter>= ... <gauge>=
##   NLB_TELEM v1 event    name= t= <field>=
##   NLB_TELEM v1 summary  metric= unit= count= min= p50= p95= max= overflow= resolution=
##   NLB_TELEM v1 gauge    metric= first= last= peak= count=
##   NLB_TELEM v1 truncated / end

const FORMAT_VERSION := 1
const PREFIX := "NLB_TELEM v1"
const FLAG_PREFIX := "--nlb-telemetry="
const HISTOGRAM_BUCKETS := 256
const MAX_FILE_BYTES := 8 * 1024 * 1024
const MAX_EVENTS := 4096
## Space kept free so the closing summaries always fit after the live lines stop.
const SUMMARY_RESERVE_BYTES := 32768
const MAX_NAME_LENGTH := 32
const SECOND_USEC := 1000000

## Distribution metrics: name -> [unit, bucket width in that unit]. Values at or beyond
## width * (HISTOGRAM_BUCKETS - 1) land in the overflow bucket (counted; max stays exact).
const DISTRIBUTIONS := {
	"frame_interval_ms": ["ms", 0.25],
	"sim_step_ms": ["ms", 0.1],
	"rtt_ms": ["ms", 1.0],
	"input_receipt_to_state_ms": ["ms", 0.5],
	"placement_receipt_to_response_ms": ["ms", 0.5],
	"recv_to_next_frame_ms": ["ms", 0.25],
	"state_rx_interval_ms": ["ms", 1.0],
	"app_tx_bytes_per_s": ["B/s", 256.0],
	"app_rx_bytes_per_s": ["B/s", 256.0],
	"net_tx_bytes_per_s": ["B/s", 256.0],
	"net_rx_bytes_per_s": ["B/s", 256.0],
	"app_tx_packets_per_s": ["pkt/s", 1.0],
	"app_rx_packets_per_s": ["pkt/s", 1.0],
	"snapshot_bytes": ["B", 256.0],
	"join_to_seat_ms": ["ms", 50.0],
	"reclaim_to_ack_ms": ["ms", 50.0],
}
## Gauge metrics: first / last / peak over the run.
const GAUGES := [
	"godot_static_bytes",
	"object_count",
	"node_count",
	"orphan_node_count",
	"peer_count",
	"fps_monitor",
	"loss_ratio",
]

var enabled := true
var role := "unknown"
var synthetic := false
var profile := "default"
var seed_value := 0
var events_written := 0
var truncated := false

var _file: FileAccess = null
var _bytes := 0
var _started_usec := 0
var _last_frame_usec := 0
var _second_start_usec := 0
var _frames_this_second := 0
var _counters_this_second: Dictionary = {}
var _hist: Dictionary = {}
var _gauges: Dictionary = {}
var _closed := false


## The telemetry sink requested on the command line, or null (absent flag, release/Android client
## build, or a path outside user:// and build/). Arguments and the gate are injectable for tests.
static func from_args(
	arguments: PackedStringArray, allowed: bool, project_root: String
) -> NlbTelemetry:
	if not allowed:
		return null
	var requested := NlbBuildFlags.value_from_args(arguments, FLAG_PREFIX)
	if requested.is_empty():
		return null
	var path := resolve_path(requested, project_root)
	if path.is_empty():
		push_warning("NLB_TELEMETRY_REJECTED: the output path must be under user:// or build/")
		return null
	var telemetry := NlbTelemetry.new()
	if not telemetry.open(path):
		push_warning("NLB_TELEMETRY_REJECTED: the output file could not be opened")
		return null
	var synthetic_flag := NlbBuildFlags.value_from_args(arguments, "--nlb-telemetry-synthetic=")
	telemetry.synthetic = synthetic_flag == "1"
	telemetry.profile = _safe_token(NlbBuildFlags.value_from_args(arguments, "--nlb-telemetry-profile="))
	var seed_text := NlbBuildFlags.value_from_args(arguments, "--nlb-telemetry-seed=")
	telemetry.seed_value = int(seed_text) if seed_text.is_valid_int() else 0
	return telemetry


static func from_cmdline() -> NlbTelemetry:
	return from_args(
		OS.get_cmdline_user_args(),
		NlbBuildFlags.dev_flags_allowed(),
		ProjectSettings.globalize_path("res://")
	)


## Returns the path to write, or "" when it is not allowed. Allowed: `user://...` (no `..`) or an
## absolute path inside `<project_root>/../build/`. Pure so tests can pin it.
static func resolve_path(requested: String, project_root: String) -> String:
	if requested.contains("..") or requested.contains("\0"):
		return ""
	if requested.begins_with("user://") and requested.length() > "user://".length():
		return requested
	var build_dir := project_root.path_join("../build").simplify_path()
	var candidate := requested.replace("\\", "/").simplify_path()
	if candidate.begins_with(build_dir.replace("\\", "/") + "/") and candidate.length() > build_dir.length() + 1:
		return candidate
	return ""


static func _safe_token(text: String) -> String:
	var clean := ""
	for index in mini(text.length(), MAX_NAME_LENGTH):
		var character := text[index]
		if (
			(character >= "a" and character <= "z")
			or (character >= "A" and character <= "Z")
			or (character >= "0" and character <= "9")
			or character == "_"
			or character == "-"
			or character == "."
		):
			clean += character
	return clean if not clean.is_empty() else "default"


func open(path: String) -> bool:
	_file = FileAccess.open(path, FileAccess.WRITE)
	if _file == null:
		enabled = false
		return false
	_started_usec = Time.get_ticks_usec()
	_second_start_usec = _started_usec
	_last_frame_usec = 0
	for metric in DISTRIBUTIONS:
		_hist[metric] = _new_distribution()
	for metric in GAUGES:
		_gauges[metric] = {"first": 0.0, "last": 0.0, "peak": 0.0, "count": 0}
	return true


## Writes the header once the role/profile are known. Never includes addresses or secrets.
func write_header() -> void:
	_write(
		"%s header build=%s engine=%s platform=%s role=%s profile=%s seed=%d synthetic=%s started_usec=%d"
		% [
			PREFIX,
			BuildIdentity.BUILD_ID,
			Engine.get_version_info().string.replace(" ", "_"),
			OS.get_name(),
			role,
			profile,
			seed_value,
			"SYNTHETIC" if synthetic else "no",
			_started_usec,
		]
	)


## Record one sample of a distribution metric. Unknown metrics are ignored (bounded by design).
func record(metric: String, value: float) -> void:
	if not enabled or _closed or not _hist.has(metric):
		return
	var entry: Dictionary = _hist[metric]
	var width: float = DISTRIBUTIONS[metric][1]
	var index := clampi(int(maxf(value, 0.0) / width), 0, HISTOGRAM_BUCKETS - 1)
	var buckets: PackedInt32Array = entry.buckets
	buckets[index] += 1
	entry.buckets = buckets
	entry.count = int(entry.count) + 1
	entry.sum = float(entry.sum) + value
	entry.min = minf(float(entry.min), value)
	entry.max = maxf(float(entry.max), value)
	if value >= width * float(HISTOGRAM_BUCKETS - 1):
		entry.overflow = int(entry.overflow) + 1


func gauge(metric: String, value: float) -> void:
	if not enabled or _closed or not _gauges.has(metric):
		return
	var entry: Dictionary = _gauges[metric]
	if int(entry.count) == 0:
		entry.first = value
		entry.peak = value
	entry.last = value
	entry.peak = maxf(float(entry.peak), value)
	entry.count = int(entry.count) + 1


## Adds to a per-second counter that is written on the next second line (unknown names allowed
## only if they pass the identifier rule, and the table stays small: at most 24 names).
func count(counter: String, amount: int = 1) -> void:
	if not enabled or _closed:
		return
	if not _counters_this_second.has(counter) and (
		_counters_this_second.size() >= 24 or not _is_identifier(counter)
	):
		return
	_counters_this_second[counter] = int(_counters_this_second.get(counter, 0)) + amount


## One discrete event (join, reclaim, cycle boundary, cleanup counts). Values must be numbers,
## bools or short identifiers; anything else is dropped so a code/token/address cannot leak in.
func event(name: String, fields: Dictionary) -> void:
	if not enabled or _closed or events_written >= MAX_EVENTS or not _is_identifier(name):
		return
	var line := "%s event name=%s t=%.3f" % [PREFIX, name, _elapsed_seconds()]
	for key in fields:
		var field_name := str(key)
		if not _is_identifier(field_name):
			continue
		var value: Variant = fields[key]
		if value is int or value is float or value is bool:
			line += " %s=%s" % [field_name, str(value)]
		elif value is String and _is_identifier(str(value)):
			line += " %s=%s" % [field_name, str(value)]
	events_written += 1
	_write(line)


## Call once per rendered frame with the monotonic clock. Records the frame interval and, once a
## second has elapsed, writes the aggregate line (and lets the caller add gauges first).
## Returns true when a second boundary was crossed (the caller then adds per-second inputs).
func frame(now_usec: int) -> bool:
	if not enabled or _closed:
		return false
	if _last_frame_usec > 0:
		record("frame_interval_ms", float(now_usec - _last_frame_usec) / 1000.0)
	_last_frame_usec = now_usec
	_frames_this_second += 1
	return now_usec - _second_start_usec >= SECOND_USEC


## Writes the per-second line and resets the per-second accumulators.
func flush_second(now_usec: int) -> void:
	if not enabled or _closed:
		return
	var line := (
		"%s second t=%.3f frames=%d role=%s"
		% [PREFIX, _elapsed_seconds(), _frames_this_second, role]
	)
	for counter in _counters_this_second:
		line += " %s=%d" % [counter, int(_counters_this_second[counter])]
	for metric in GAUGES:
		var entry: Dictionary = _gauges[metric]
		if int(entry.count) > 0:
			line += " %s=%s" % [metric, str(entry.last)]
	_write(line)
	_frames_this_second = 0
	_counters_this_second.clear()
	_second_start_usec = now_usec


## Percentile (0..1) of a distribution from its histogram: the upper edge of the bucket holding
## the rank, so it never understates. Returns -1.0 when there are no samples.
func percentile(metric: String, fraction: float) -> float:
	if not _hist.has(metric):
		return -1.0
	var entry: Dictionary = _hist[metric]
	var total := int(entry.count)
	if total == 0:
		return -1.0
	var rank := maxi(1, ceili(fraction * float(total)))
	var width: float = DISTRIBUTIONS[metric][1]
	var seen := 0
	var buckets: PackedInt32Array = entry.buckets
	for index in HISTOGRAM_BUCKETS:
		seen += buckets[index]
		if seen >= rank:
			if index == HISTOGRAM_BUCKETS - 1:
				return float(entry.max)
			return width * float(index + 1)
	return float(entry.max)


func sample_count(metric: String) -> int:
	return int(_hist[metric].count) if _hist.has(metric) else 0


func bytes_written() -> int:
	return _bytes


## Writes the summaries and closes the file. Safe to call twice.
func finish() -> void:
	if _closed:
		return
	if enabled:
		for metric in DISTRIBUTIONS:
			var entry: Dictionary = _hist[metric]
			if int(entry.count) == 0:
				_write("%s summary metric=%s unit=%s count=0" % [PREFIX, metric, DISTRIBUTIONS[metric][0]], true)
				continue
			_write(
				(
					"%s summary metric=%s unit=%s count=%d min=%.3f p50=%.3f p95=%.3f max=%.3f overflow=%d resolution=%s"
					% [
						PREFIX,
						metric,
						DISTRIBUTIONS[metric][0],
						int(entry.count),
						float(entry.min),
						percentile(metric, 0.5),
						percentile(metric, 0.95),
						float(entry.max),
						int(entry.overflow),
						str(DISTRIBUTIONS[metric][1]),
					]
				),
				true
			)
		for metric in GAUGES:
			var gauge_entry: Dictionary = _gauges[metric]
			_write(
				(
					"%s gauge metric=%s first=%s last=%s peak=%s count=%d"
					% [
						PREFIX,
						metric,
						str(gauge_entry.first),
						str(gauge_entry.last),
						str(gauge_entry.peak),
						int(gauge_entry.count),
					]
				),
				true
			)
		_write("%s end" % PREFIX, true)
	_closed = true
	if _file != null:
		_file.close()
		_file = null


func _new_distribution() -> Dictionary:
	var buckets := PackedInt32Array()
	buckets.resize(HISTOGRAM_BUCKETS)
	return {"buckets": buckets, "count": 0, "sum": 0.0, "min": INF, "max": -INF, "overflow": 0}


func _elapsed_seconds() -> float:
	return float(Time.get_ticks_usec() - _started_usec) / float(SECOND_USEC)


func _write(line: String, closing: bool = false) -> void:
	if _file == null or (truncated and not closing):
		return
	var size := line.length() + 1
	var limit := MAX_FILE_BYTES if closing else MAX_FILE_BYTES - SUMMARY_RESERVE_BYTES
	if _bytes + size > limit:
		if not closing:
			truncated = true
			_file.store_line("%s truncated" % PREFIX)
			_file.flush()
		return
	_file.store_line(line)
	_bytes += size
	if _bytes % 4096 < size:
		_file.flush()


func _is_identifier(text: String) -> bool:
	if text.is_empty() or text.length() > MAX_NAME_LENGTH:
		return false
	for index in text.length():
		var character := text[index]
		if not (
			(character >= "a" and character <= "z")
			or (character >= "A" and character <= "Z")
			or (character >= "0" and character <= "9")
			or character == "_"
			or character == "-"
			or character == "."
		):
			return false
	return true

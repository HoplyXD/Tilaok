# gdlint: disable=max-line-length,max-file-lines
extends SceneTree

## NLB-P11 preparatory suite (authored, NEVER run while the laptop is shared): telemetry bounds and
## output hygiene, fault-injector determinism and channel rules, release-tag gating of every
## development flag, per-family rate limits, saturating counters, the kick-path erase, the discovery
## bound, close-request shutdown wiring, build-identity consistency, export-preset hygiene and the
## metrics report core's PASS / FAIL / COULD-NOT-RUN discipline.
## Run: Godot --headless --fixed-fps 60 --path tilaok! --script res://tests/run_nlb_p11_tests.gd

const CORE := preload("res://tests/tools/nlb_p11_report_core.gd")
const COMMAND_LINE_ALLOWLIST := [
	"nlb_build_flags.gd", "game_flow.gd", "nlb_fault_injector.gd", "nlb_telemetry.gd"
]

var checks := 0
var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_build_flags()
	_test_command_line_audit()
	_test_fault_injector()
	_test_telemetry()
	_test_rate_limits_and_counters()
	_test_discovery_bound()
	_test_build_identity_and_presets()
	_test_close_request_wiring()
	_test_report_core()
	print("NLB_P11_TESTS checks=%d failures=%d" % [checks, failures])
	await process_frame
	quit(1 if failures > 0 else 0)


# --- release gating -------------------------------------------------------------------------


func _test_build_flags() -> void:
	_check(NlbBuildFlags.dev_flags_allowed_for(PackedStringArray()), "a development build allows dev flags")
	_check(not NlbBuildFlags.dev_flags_allowed_for(PackedStringArray(["release"])), "the release tag blocks dev flags")
	_check(not NlbBuildFlags.dev_flags_allowed_for(PackedStringArray(["android_client"])), "the android_client tag blocks dev flags")
	_check(not NlbBuildFlags.dev_flags_allowed_for(PackedStringArray(["release", "android_client"])), "both tags block dev flags")
	var arguments := PackedStringArray(["--a=1", "--nlb-fault=loss=5", "--nlb-fault=loss=7"])
	_check(NlbBuildFlags.value_from_args(arguments, "--nlb-fault=") == "loss=7", "the last value of a prefixed flag wins")
	_check(NlbBuildFlags.value_from_args(arguments, "--zzz=").is_empty(), "an absent prefixed flag is empty")
	var release_args := PackedStringArray(["--nlb-fault=loss=50,seed=1"])
	_check(NlbFaultInjector.from_args(release_args, false) == null, "release builds create no fault injector")
	_check(
		NlbTelemetry.from_args(PackedStringArray(["--nlb-telemetry=user://x.telem"]), false, "C:/p/") == null,
		"release builds create no telemetry sink"
	)
	_check(
		not NLBLiveCompatibilityMatrix.override_requested(PackedStringArray(["--nlb-unverified-content"]))
		or NlbBuildFlags.dev_flags_allowed(),
		"the unverified-content override cannot be on where dev flags are blocked"
	)


## Every runtime script that reads the command line must be on the allowlist; each allowed file
## routes its flags through NlbBuildFlags (checked by reading the file).
func _test_command_line_audit() -> void:
	var offenders: Array[String] = []
	for path in _gd_files("res://scripts"):
		var text := FileAccess.get_file_as_string(path)
		if not (text.contains("get_cmdline_user_args") or text.contains("get_cmdline_args")):
			continue
		if not COMMAND_LINE_ALLOWLIST.has(path.get_file()):
			offenders.append(path)
	_check(offenders.is_empty(), "no runtime script outside the allowlist reads the command line: %s" % str(offenders))
	var flow_text := FileAccess.get_file_as_string("res://scripts/flow/game_flow.gd")
	_check(flow_text.contains("NlbBuildFlags.dev_user_args()"), "game_flow reads map, seed and harness flags through NlbBuildFlags")
	_check(flow_text.contains("requested_route != ROUTE_NETWORK_LIVE_BUILD"), "game_flow keeps only the network opt-in route in release")
	for pair in [
		["res://scripts/ui/ui_library_screen.gd", "NlbBuildFlags.dev_flag_present(DEV_FLAG)"],
		["res://scripts/match/p12_scheduled_match_room.gd", "NlbBuildFlags.dev_flag_present(\"--barya-disabled\")"],
		["res://scripts/match/match_screen_presenter.gd", "NlbBuildFlags.dev_flag_present(DEBUG_OVERLAY_FLAG)"],
		["res://scripts/harness/foundation_harness.gd", "NlbBuildFlags.dev_user_args()"],
	]:
		_check(FileAccess.get_file_as_string(str(pair[0])).contains(str(pair[1])), "%s gates its flag" % str(pair[0]).get_file())
	_check(
		flow_text.contains("var match_scene: PackedScene = LIFECYCLE_SCENE"),
		"the offline scheduled route is still the default route"
	)


# --- fault injector -------------------------------------------------------------------------


func _test_fault_injector() -> void:
	var injector := NlbFaultInjector.new()
	_check(injector.configure("loss=5,jitter=30,delay=20,reorder=5,duplicate=2,seed=7"), "a full spec parses")
	_check(injector.is_active(), "a configured injector is active")
	_check(not NlbFaultInjector.new().is_active(), "an empty injector is inactive")
	for bad in ["loss=101", "loss=-1", "bogus=1", "loss=x", "loss", "seed=-3", "jitter=99999"]:
		_check(not NlbFaultInjector.new().configure(bad), "spec '%s' is rejected" % bad)
	var packet := PackedByteArray([1, 2, 3])
	var always_loss := NlbFaultInjector.new()
	always_loss.configure("loss=100,seed=1")
	_check(always_loss.filter(NlbFaultInjector.OUTGOING, 1, 1, packet, 1000).is_empty(), "loss drops unreliable channel 1")
	_check(always_loss.filter(NlbFaultInjector.OUTGOING, 1, 2, packet, 1000).is_empty(), "loss drops unreliable channel 2")
	_check(always_loss.filter(NlbFaultInjector.OUTGOING, 1, 0, packet, 1000).size() == 1, "loss never drops reliable channel 0")
	var always_dup := NlbFaultInjector.new()
	always_dup.configure("duplicate=100,seed=1")
	_check(always_dup.filter(NlbFaultInjector.INCOMING, 1, 0, packet, 1000).size() == 2, "duplicate=100 delivers twice")
	var delayed := NlbFaultInjector.new()
	delayed.configure("delay=40,seed=1")
	var entries := delayed.filter(NlbFaultInjector.OUTGOING, 1, 0, packet, 1000)
	_check(entries.size() == 1 and int(entries[0].due_ms) == 1040, "delay sets the due time")
	delayed.hold(entries[0])
	_check(delayed.pop_due(1039).is_empty() and delayed.pop_due(1040).size() == 1, "a held packet is released exactly when due")
	var first := NlbFaultInjector.new()
	first.configure("loss=30,jitter=50,reorder=20,duplicate=10,seed=99")
	var second := NlbFaultInjector.new()
	second.configure("loss=30,jitter=50,reorder=20,duplicate=10,seed=99")
	var same := true
	for index in 200:
		var a := first.filter(NlbFaultInjector.OUTGOING, 1, 1 + index % 2, packet, index)
		var b := second.filter(NlbFaultInjector.OUTGOING, 1, 1 + index % 2, packet, index)
		if a.size() != b.size():
			same = false
			break
		for pair_index in a.size():
			if int(a[pair_index].due_ms) != int(b[pair_index].due_ms):
				same = false
	_check(same, "the same seed produces the same fault sequence")
	var bounded := NlbFaultInjector.new()
	for index in NlbFaultInjector.MAX_QUEUED + 25:
		bounded.hold({"due_ms": 10 + index})
	_check(bounded.queued_count() == NlbFaultInjector.MAX_QUEUED and bounded.overflow_dropped == 25, "the held-packet queue is bounded and counts overflow")
	var transport_text := FileAccess.get_file_as_string("res://scripts/network/raw_enet_transport.gd")
	_check(transport_text.contains("var fault: NlbFaultInjector"), "the injector lives inside the production RawEnetTransport")
	var manager_text := FileAccess.get_file_as_string("res://scripts/network/network_session_manager.gd")
	_check(manager_text.contains("NlbFaultInjector.from_cmdline()"), "the session manager creates the injector only through the gated factory")


# --- telemetry ------------------------------------------------------------------------------


func _test_telemetry() -> void:
	var root_dir := "C:/proj/tilaok!/"
	_check(NlbTelemetry.resolve_path("user://run/host.telem", root_dir) == "user://run/host.telem", "user:// output is accepted")
	_check(NlbTelemetry.resolve_path("user://../escape", root_dir).is_empty(), "a path with .. is rejected")
	_check(NlbTelemetry.resolve_path("C:/Windows/evil.telem", root_dir).is_empty(), "a path outside user:// and build/ is rejected")
	_check(NlbTelemetry.resolve_path("C:/proj/build/x.telem", root_dir) == "C:/proj/build/x.telem", "the ignored build/ folder is accepted")
	_check(NlbTelemetry.resolve_path("user://", root_dir).is_empty(), "an empty user:// target is rejected")
	var path := "user://nlb_p11_test_%d.telem" % Time.get_ticks_usec()
	var telemetry := NlbTelemetry.new()
	_check(telemetry.open(path), "the sink opens a user:// file")
	telemetry.role = "host"
	telemetry.profile = "unit"
	telemetry.write_header()
	for index in 100000:
		telemetry.record("frame_interval_ms", 16.0 + float(index % 7))
	_check(telemetry.sample_count("frame_interval_ms") == 100000, "100k samples are counted in constant space")
	_check(telemetry._hist["frame_interval_ms"].buckets.size() == NlbTelemetry.HISTOGRAM_BUCKETS, "the histogram never grows past its fixed buckets")
	var p95 := telemetry.percentile("frame_interval_ms", 0.95)
	_check(p95 >= 20.0 and p95 <= 23.0, "p95 comes from the histogram upper edge (got %.2f)" % p95)
	telemetry.record("frame_interval_ms", 1000.0)
	_check(int(telemetry._hist["frame_interval_ms"].overflow) == 1, "an off-scale sample lands in the overflow bucket")
	telemetry.record("not_a_metric", 1.0)
	_check(telemetry.sample_count("not_a_metric") == 0, "unknown metrics are ignored")
	telemetry.event("leak_test", {"code": "ABCDEFGHIJKLMNOPQRSTUVWXYZ", "address": "192.168.1.5:27777", "ok": "label", "n": 5})
	for index in NlbTelemetry.MAX_EVENTS + 100:
		telemetry.event("cycle", {"cycle": index})
	_check(telemetry.events_written == NlbTelemetry.MAX_EVENTS, "events are capped")
	telemetry.finish()
	telemetry.finish()
	var text := FileAccess.get_file_as_string(path)
	_check(text.contains("NLB_TELEM v1 header") and text.contains("NLB_TELEM v1 end"), "the file has a header and an end line")
	_check(text.contains("name=leak_test") and text.contains(" ok=label") and text.contains(" n=5"), "short labels and numbers survive in event fields")
	_check(not text.contains("ABCDEFGHIJKLMNOPQRSTUVWXYZ") and not text.contains("192.168.1.5"), "codes and addresses in event fields are dropped")
	_check(text.contains("summary metric=frame_interval_ms") and text.contains("overflow=1"), "summaries are written with an overflow count")
	var parsed := CORE.parse_telemetry(text)
	_check(str(parsed.header.get("role", "")) == "host" and parsed.summaries.has("frame_interval_ms"), "the report core parses the sink's own output")
	DirAccess.remove_absolute(path)
	var tele_source := FileAccess.get_file_as_string("res://scripts/network/nlb_telemetry.gd")
	var manager_text := FileAccess.get_file_as_string("res://scripts/network/network_session_manager.gd")
	_check(not tele_source.contains("invitation_code") and not tele_source.contains("token") and not tele_source.contains("get_remote_address"), "the telemetry module never touches codes, tokens or addresses")
	var glue_start := manager_text.find("NLB-P11 telemetry glue")
	_check(glue_start > 0 and not manager_text.substr(glue_start, 6000).contains("invitation_code"), "the manager's telemetry glue never reads the invitation code")


# --- hardening ------------------------------------------------------------------------------


func _test_rate_limits_and_counters() -> void:
	var manager := NetworkSessionManager.new()
	for family in NetworkSessionManager.FAMILY_RATE_LIMITS:
		var limit := int(NetworkSessionManager.FAMILY_RATE_LIMITS[family])
		var accepted := 0
		for burst in limit + 5:
			if manager._accept_rate(7, int(family)):
				accepted += 1
		_check(accepted == limit, "family %d is limited to %d per second on the host" % [int(family), limit])
	var client := NetworkSessionManager.new()
	client.client_mode = true
	var client_accepted := 0
	for burst in 20:
		if client._accept_rate(1, NetworkFrame.Family.SNAPSHOT_REQUEST):
			client_accepted += 1
	_check(client_accepted == 20, "the client never rate-limits packets from the host")
	for _count in 70000:
		manager._count_abuse(3, NetworkFrame.Family.PROOF, NetworkFrame.Reason.MALFORMED)
	_check(
		manager.abuse_count(3, NetworkFrame.Family.PROOF, NetworkFrame.Reason.MALFORMED) == NetworkSessionManager.ABUSE_COUNTER_SATURATION,
		"abuse counters saturate instead of overflowing"
	)
	_check(manager.abuse_count(3, NetworkFrame.Family.PROOF, NetworkFrame.Reason.RATE_LIMIT) == 0, "counters are separate per reason")
	manager._reject(9, NetworkFrame.Reason.STALE_STATE, NetworkFrame.Family.CONTINUOUS_INPUT)
	_check(int(manager._peer_abuse[9].format_failures) == 1, "STALE_STATE counts toward the format-violation threshold")
	# 119 more makes 120 within the window: the threshold kicks the peer and erases all its state.
	for _rejection in 119:
		manager._reject(9, NetworkFrame.Reason.STALE_STATE, NetworkFrame.Family.CONTINUOUS_INPUT)
	_check(not manager._peer_abuse.has(9), "a peer kicked for stale-state spam leaves no abuse record")
	_check(manager.abuse_count(9, NetworkFrame.Family.CONTINUOUS_INPUT, NetworkFrame.Reason.STALE_STATE) == 0, "a kicked peer leaves no saturating counters")
	var leaked := false
	for key in manager._peer_family_times:
		if str(key).begins_with("9:"):
			leaked = true
	_check(not leaked, "a kicked peer leaves no per-family rate state")
	var counts := manager.teardown_counts()
	_check(counts.has("abuse_counters"), "teardown_counts reports the saturating counter table")
	var source := FileAccess.get_file_as_string("res://scripts/network/network_session_manager.gd")
	_check(source.contains("_accept_new_placement_id(peer_id)") and source.contains("PLACEMENT_NEW_IDS_PER_SECOND"), "the placement new-id budget is enforced")
	manager.free()
	client.free()


func _test_discovery_bound() -> void:
	var discovery := LanDiscovery.new()
	var now := 100000
	for index in 400:
		discovery._last_query_by_source["10.0.%d.%d" % [index / 250, index % 250]] = now - index
	discovery._bound_query_sources(now)
	_check(discovery._last_query_by_source.size() <= LanDiscovery.MAX_QUERY_SOURCES, "query-source throttle state is capped")
	discovery._last_query_by_source["stale"] = now - LanDiscovery.QUERY_SOURCE_TTL_MS - 1
	discovery._bound_query_sources(now)
	_check(not discovery._last_query_by_source.has("stale"), "stale query sources are pruned by age")


# --- build identity and presets -------------------------------------------------------------


func _test_build_identity_and_presets() -> void:
	_check(BuildIdentity.VERSION == str(ProjectSettings.get_setting("application/config/version", "")), "BuildIdentity.VERSION matches project.godot")
	_check(CompatibilityManifest.BUILD_ID == BuildIdentity.BUILD_ID, "the manifest build id is the BuildIdentity build id")
	_check(str(CompatibilityManifest.build().manifest.build) == BuildIdentity.BUILD_ID, "the built manifest carries the BuildIdentity build id")
	_check(BuildIdentity.label().contains(BuildIdentity.VERSION), "the visible label shows the version")
	_check(BuildIdentity.about_line().contains(BuildIdentity.BUILD_ID), "the about line shows the build id")
	_check(BuildIdentity.mismatch_text("Tilaok! v0.3.0 (dev)").contains("v0.3.0"), "a mismatch notice may show both labels")
	_check(not BuildIdentity.mismatch_text("evil\n\u0007label").contains("\u0007"), "control characters in a peer label are stripped")
	var presets := FileAccess.get_file_as_string("res://export_presets.cfg")
	_check(presets.contains("name=\"Windows Desktop\"") and presets.contains("tilaok-p02.exe"), "the Windows debug preset is unchanged")
	_check(presets.contains("org.hoplyxd.tilaok.debug") and presets.contains("0.3.2-debug"), "the Android debug preset is unchanged")
	_check(presets.contains("name=\"Windows Host (Release)\"") and presets.contains("tilaok-host.exe"), "the Windows host release preset exists")
	_check(presets.contains("name=\"Android LAN Client (Release)\""), "the Android client release preset exists")
	_check(presets.contains("package/unique_name=\"org.hoplyxd.tilaok\"") and presets.contains("version/name=\"%s\"" % BuildIdentity.VERSION), "the release preset has a distinct package id and the BuildIdentity version")
	_check(presets.contains("version/code=4"), "the release preset has its own version code")
	var secret_line := false
	for raw_line in presets.split("\n"):
		var line := raw_line.strip_edges()
		if line.begins_with("keystore/") and not line.ends_with("=\"\""):
			secret_line = true
		if line.to_lower().contains("password=") and not line.ends_with("=\"\""):
			secret_line = true
	_check(not secret_line, "export_presets.cfg holds no keystore path, user or password")
	_check(presets.count("exclude_filter=\"addons/tilaok_qr_scanner/android/**\"") == 4, "every preset keeps the scanner plugin source excluded")
	_check(not presets.contains("custom_features=\"release\""), "release tagging relies on the engine's built-in release feature")
	var readme := FileAccess.get_file_as_string("res://addons/tilaok_qr_scanner/README.md")
	_check(readme.contains("CameraX 1.5.1") and readme.contains("3.5.3"), "the scanner plugin provenance is intact")


func _test_close_request_wiring() -> void:
	var flow_text := FileAccess.get_file_as_string("res://scripts/flow/game_flow.gd")
	_check(flow_text.contains("NOTIFICATION_WM_CLOSE_REQUEST"), "game_flow handles the window close request")
	_check(flow_text.contains("set_auto_accept_quit(false)"), "game_flow turns off the engine's immediate close")
	_check(flow_text.contains("set_auto_accept_quit(true)"), "game_flow restores auto-accept when it leaves the tree")
	var quit_start := flow_text.find("func _quit() -> void:")
	_check(quit_start > 0 and flow_text.substr(quit_start, 900).contains("SessionEnd.HOST_QUIT"), "quit attempts SESSION_CLOSE (HOST_QUIT) before exiting")


# --- report core ----------------------------------------------------------------------------


func _test_report_core() -> void:
	var hardware := {}
	for key in CORE.REQUIRED_HARDWARE:
		hardware[key] = "recorded"
	_check(CORE.missing_hardware(hardware).is_empty(), "a complete hardware record has no missing field")
	_check(CORE.missing_hardware({"build": "x"}).size() == CORE.REQUIRED_HARDWARE.size() - 1, "an incomplete record lists every missing field")
	var good := _telemetry_text(14.0, "no", "windows", 800.0)
	var host_good := CORE.parse_telemetry(good)
	var rows := CORE.evaluate(host_good, hardware, {}, {})
	_check(_outcome(rows, "Host frame (60 Hz, 1080p)") == CORE.PASS, "a long complete host run under budget is PASS")
	var slow := CORE.parse_telemetry(_telemetry_text(25.0, "no", "windows", 800.0))
	_check(_outcome(CORE.evaluate(slow, hardware, {}, {}), "Host frame (60 Hz, 1080p)") == CORE.FAIL, "a host run over budget is FAIL")
	_check(_outcome(CORE.evaluate(host_good, {}, {}, {}), "Host frame (60 Hz, 1080p)") == CORE.COULD_NOT_RUN, "no hardware record means COULD-NOT-RUN, never PASS")
	var short := CORE.parse_telemetry(_telemetry_text(14.0, "no", "windows", 60.0))
	_check(_outcome(CORE.evaluate(short, hardware, {}, {}), "Host frame (60 Hz, 1080p)") == CORE.COULD_NOT_RUN, "a run shorter than the profile is COULD-NOT-RUN")
	var synthetic_phone := CORE.parse_telemetry(_telemetry_text(14.0, "SYNTHETIC", "android", 800.0))
	_check(_outcome(CORE.evaluate(host_good, hardware, synthetic_phone, hardware), "Phone frame (>=30 FPS, 720p)") == CORE.COULD_NOT_RUN, "a SYNTHETIC client is never phone evidence")
	_check(_outcome(rows, "End-to-end visible response") == CORE.COULD_NOT_RUN, "end-to-end is COULD-NOT-RUN without an external capture")
	_check(_outcome(rows, "Memory (host)") == CORE.COULD_NOT_RUN, "memory is COULD-NOT-RUN without an external RSS value")
	_check(_outcome(rows, "Battery / thermal") == CORE.COULD_NOT_RUN, "battery/thermal is COULD-NOT-RUN without the sampler")
	_check(_outcome(rows, "RTT (ENet single-endpoint estimate)") != CORE.PASS, "RTT never receives a pass verdict (no threshold set)")
	_check(CORE.render_markdown(rows, true).contains("SYNTHETIC"), "a synthetic report is labeled SYNTHETIC")


func _telemetry_text(p95_ms: float, synthetic: String, platform: String, seconds: float) -> String:
	return (
		"NLB_TELEM v1 header build=b engine=e platform=%s role=host profile=p seed=1 synthetic=%s started_usec=0\n" % [platform, synthetic]
		+ "NLB_TELEM v1 second t=%.3f frames=60 role=host\n" % seconds
		+ "NLB_TELEM v1 summary metric=frame_interval_ms unit=ms count=1000 min=10.0 p50=%.3f p95=%.3f max=40.0 overflow=0 resolution=0.25\n" % [p95_ms - 1.0, p95_ms]
		+ "NLB_TELEM v1 end\n"
	)


func _outcome(rows: Array[Dictionary], budget: String) -> String:
	for row in rows:
		if str(row.budget) == budget:
			return str(row.outcome)
	return "MISSING"


# --- helpers --------------------------------------------------------------------------------


func _gd_files(directory: String) -> Array[String]:
	var found: Array[String] = []
	var dir := DirAccess.open(directory)
	if dir == null:
		return found
	for entry in dir.get_files():
		if entry.ends_with(".gd"):
			found.append(directory.path_join(entry))
	for sub in dir.get_directories():
		found.append_array(_gd_files(directory.path_join(sub)))
	return found


func _check(condition: bool, label: String) -> void:
	checks += 1
	if condition:
		print("PASS ", label)
	else:
		failures += 1
		push_warning("FAIL " + label)
		print("FAIL ", label)

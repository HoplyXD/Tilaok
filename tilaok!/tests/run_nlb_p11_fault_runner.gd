# gdlint: disable=max-line-length
extends SceneTree

## NLB-P11-T01 fault-injection runner (authored, NEVER run while the laptop is shared).
## For each fault profile it launches the scale runner's host (one SYNTHETIC client) with the
## development-only `--nlb-fault=` flag on BOTH endpoints, so the faults sit inside the production
## RawEnetTransport of the real session code. It checks that the run announced the injection
## (NLB_FAULT_ACTIVE), that the host finished, and that telemetry summaries were written; it
## never judges quality of play. Results are engineering evidence only (SYNTHETIC).
## Run: Godot --headless --fixed-fps 60 --path tilaok! --script res://tests/run_nlb_p11_fault_runner.gd -- [seconds]

const RUN_ROOT := "user://nlb_p11"
const SCALE_SCRIPT := "res://tests/run_nlb_p11_scale_runner.gd"
## Deterministic by seed. Loss applies only to the unreliable input/state channels (see
## NlbFaultInjector); delay, jitter, reorder and duplicate apply to every channel.
const PROFILES := [
	["baseline", "none"],
	["loss5", "loss=5,seed=7"],
	["delay_jitter", "delay=20,jitter=30,seed=7"],
	["reorder_dup", "reorder=10,duplicate=5,seed=7"],
	["combined", "loss=10,jitter=50,reorder=10,duplicate=5,seed=7"],
]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var arguments := OS.get_cmdline_user_args()
	var seconds := int(arguments[0]) if not arguments.is_empty() and str(arguments[0]).is_valid_int() else 30
	var run_id := str(Time.get_unix_time_from_system()).replace(".", "")
	var problems_total := 0
	for profile in PROFILES:
		var label := str(profile[0])
		var spec := str(profile[1])
		var run_dir := "%s/%s-fault-%s" % [RUN_ROOT, run_id, label]
		DirAccess.make_dir_recursive_absolute(run_dir)
		var command_line := PackedStringArray(
			[
				"--headless", "--fixed-fps", "60", "--path", ProjectSettings.globalize_path("res://"),
				"--script", SCALE_SCRIPT, "--", "host", "1", "profile", str(seconds), run_dir, spec,
				"--nlb-telemetry=%s/host.telem" % run_dir,
				"--nlb-telemetry-synthetic=1",
				"--nlb-telemetry-profile=fault-%s" % label,
				"--nlb-telemetry-seed=11011",
				"--nlb-p11-fixture",
				"--match-route=network_live_build",
			]
		)
		if spec != "none":
			command_line.append("--nlb-fault=%s" % spec)
		var output: Array = []
		var exit_code := OS.execute(OS.get_executable_path(), command_line, output, true)
		var host_log := _read("%s/host.log" % run_dir)
		var telemetry := _read("%s/host.telem" % run_dir)
		var combined := "\n".join(PackedStringArray(output.map(func(entry: Variant) -> String: return str(entry))))
		var problems: Array[String] = []
		if exit_code != 0:
			problems.append("host exit code %d" % exit_code)
		if not host_log.contains("NLB_P11_HOST_RESULT PASSED"):
			problems.append("host did not report PASSED")
		if spec != "none" and not combined.contains("NLB_FAULT_ACTIVE"):
			problems.append("fault injection was never announced in the host output")
		if spec == "none" and combined.contains("NLB_FAULT_ACTIVE"):
			problems.append("baseline run announced fault injection")
		if not telemetry.contains("NLB_TELEM v1 summary metric=frame_interval_ms"):
			problems.append("host telemetry has no frame_interval_ms summary")
		if not problems.is_empty():
			problems_total += 1
		print(
			"NLB_P11_FAULT_CELL profile=%s spec=%s seconds=%d result=%s evidence=SYNTHETIC problems=%s"
			% [label, spec, seconds, "OK" if problems.is_empty() else "PROBLEM", str(problems)]
		)
	print("NLB_P11_FAULT_MATRIX profiles=%d problems=%d evidence=SYNTHETIC" % [PROFILES.size(), problems_total])
	quit(1 if problems_total > 0 else 0)


func _read(path: String) -> String:
	return FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else ""

# gdlint: disable=max-line-length
extends SceneTree

## NLB-P11-T01 metrics report generator (authored, never run).
## Run: Godot --headless --path tilaok! --script res://tests/tools/nlb_p11_report.gd -- \
##        --host=<host.telem> --host-hardware=<file> [--phone=<client.telem> --phone-hardware=<file>] \
##        --out=<report.md>
## Paths may be user:// or absolute. Each hardware file is `key=value` lines holding the fields in
## NlbP11ReportCore.REQUIRED_HARDWARE (plus optional rss_peak_mib, end_to_end_p95_ms,
## end_to_end_method). Anything missing leaves the dependent budget COULD-NOT-RUN.


func _initialize() -> void:
	var arguments := OS.get_cmdline_user_args()
	var host_text := _read(NlbBuildFlags.value_from_args(arguments, "--host="))
	var phone_text := _read(NlbBuildFlags.value_from_args(arguments, "--phone="))
	var host := NlbP11ReportCore.parse_telemetry(host_text) if not host_text.is_empty() else {}
	var phone := NlbP11ReportCore.parse_telemetry(phone_text) if not phone_text.is_empty() else {}
	var host_hardware := NlbP11ReportCore.parse_hardware(
		_read(NlbBuildFlags.value_from_args(arguments, "--host-hardware="))
	)
	var phone_hardware := NlbP11ReportCore.parse_hardware(
		_read(NlbBuildFlags.value_from_args(arguments, "--phone-hardware="))
	)
	var rows := NlbP11ReportCore.evaluate(host, host_hardware, phone, phone_hardware)
	var synthetic := (
		str(host.get("header", {}).get("synthetic", "")) == "SYNTHETIC"
		or str(phone.get("header", {}).get("synthetic", "")) == "SYNTHETIC"
	)
	var markdown := NlbP11ReportCore.render_markdown(rows, synthetic)
	var out_path := NlbBuildFlags.value_from_args(arguments, "--out=")
	if out_path.is_empty():
		print(markdown)
	else:
		var file := FileAccess.open(out_path, FileAccess.WRITE)
		if file == null:
			push_error("NLB_P11_REPORT could not write %s" % out_path)
			quit(1)
			return
		file.store_string(markdown)
		file.close()
		print("NLB_P11_REPORT written rows=%d synthetic=%s" % [rows.size(), str(synthetic)])
	quit(0)


func _read(path: String) -> String:
	if path.is_empty() or not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)

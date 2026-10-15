extends SceneTree

## P12-T03..T10 on the scheduled match room: the owner-approved terminal-order table (controller
## scenarios with callback-order permutations) and the Karera + Bomb-Taya, Karera + Kangaroo and
## Kangaroo + Bomb-Taya pairs at 2/3/4 seats.
## Run: godot --headless --fixed-fps 60 --path tilaok! --script res://tests/run_p12_pairs_tests.gd
##   [-- --part=table|rooms]

const TABLE_SCENARIOS := preload("res://tests/p12_table_scenarios.gd")
const ROOM_SCENARIOS := preload("res://tests/p12_pair_room_scenarios.gd")

var checks := 0
var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var part := "all"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--part="):
			part = argument.trim_prefix("--part=")
	if part in ["all", "table"]:
		var fixtures := Node.new()
		fixtures.name = "P12TableFixtures"
		root.add_child(fixtures)
		var table = TABLE_SCENARIOS.new(_check, fixtures)
		table.run_all()
	if part in ["all", "rooms"]:
		var rooms = ROOM_SCENARIOS.new(_check, self)
		await rooms.run_all()
	print("P12_PAIRS_TESTS checks=%d failures=%d" % [checks, failures.size()])
	for failure in failures:
		push_error(failure)
	await process_frame
	quit(1 if not failures.is_empty() else 0)


func _check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("PASS %s" % message)
		return
	failures.append("FAIL %s" % message)

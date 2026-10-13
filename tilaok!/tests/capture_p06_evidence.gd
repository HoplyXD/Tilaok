extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var output: Array = []
	var project_path := ProjectSettings.globalize_path("res://")
	var result := OS.execute(
		OS.get_executable_path(),
		["--path", project_path, "--script", "res://tests/run_p06_interactive.gd"],
		output,
		true
	)
	for line in output:
		print(line)
	quit(result)

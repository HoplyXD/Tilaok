extends SceneTree


func _initialize() -> void:
	call_deferred("_print_digest")


func _print_digest() -> void:
	CompatibilityManifest.reload_sources()
	var result: Dictionary = CompatibilityManifest.build()
	print(
		(
			"NLB_COMPATIBILITY_DIGEST profile=%s engine=%s digest=%s"
			% [
				CompatibilityManifest.PROFILE_ID,
				Engine.get_version_info().string,
				(result.digest as PackedByteArray).hex_encode(),
			]
		)
	)
	quit(0)

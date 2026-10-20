@tool
extends EditorPlugin

var export_plugin: AndroidExportPlugin


func _enter_tree() -> void:
	export_plugin = AndroidExportPlugin.new()
	add_export_plugin(export_plugin)


func _exit_tree() -> void:
	remove_export_plugin(export_plugin)
	export_plugin = null


class AndroidExportPlugin:
	extends EditorExportPlugin
	const PLUGIN_NAME := "TilaokQrScanner"

	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformAndroid

	func _get_name() -> String:
		return PLUGIN_NAME

	func _get_android_libraries(_platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
		var build_type := "debug" if debug else "release"
		return PackedStringArray(
			["tilaok_qr_scanner/bin/%s/%s-%s.aar" % [build_type, PLUGIN_NAME, build_type]]
		)

	func _get_android_dependencies(
		_platform: EditorExportPlatform, _debug: bool
	) -> PackedStringArray:
		return PackedStringArray(
			[
				"androidx.camera:camera-camera2:1.5.1",
				"androidx.camera:camera-lifecycle:1.5.1",
				"androidx.camera:camera-view:1.5.1",
				"androidx.activity:activity:1.10.1",
				"androidx.fragment:fragment:1.8.6",
				"com.google.zxing:core:3.5.3",
			]
		)

	func _get_android_dependencies_maven_repos(
		_platform: EditorExportPlatform, _debug: bool
	) -> PackedStringArray:
		return PackedStringArray(
			["https://dl.google.com/dl/android/maven2", "https://repo.maven.apache.org/maven2"]
		)

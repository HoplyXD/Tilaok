# gdlint: disable=max-line-length
extends SceneTree

const INVITATION_URI_SCRIPT := preload("res://scripts/network/invitation_uri.gd")
const LOBBY_SCREEN := preload("res://scenes/ui/screens/lan_lobby_screen.tscn")

var failures: Array[String] = []
var checks := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_invitation_parser()
	await _test_desktop_lobby_roles()
	await _test_phone_client_ui_and_authority()
	_test_android_scanner_export_contract()
	if failures.is_empty():
		print("NLB_P03_TESTS PASSED checks=%d" % checks)
		quit(0)
	else:
		for failure in failures:
			push_error("NLB_P03_TEST_FAILED " + failure)
		print("NLB_P03_TESTS FAILED checks=%d failures=%d" % [checks, failures.size()])
		quit(1)


func _test_invitation_parser() -> void:
	var uri := (
		"tilaok://join?lobby=AAAAAAAAAAAAA&host=192.168.1.22&port=27777&protocol=1.2&digest=%s&code=AAAAAAAAAAAAAAAAAAAAAAAAAA&epoch=7&expires=2000000000"
		% "a".repeat(64)
	)
	var invite: Dictionary = INVITATION_URI_SCRIPT.parse(uri)
	_check(bool(invite.ok), "approved URI schema parses")
	var shown_host_id := "EWWOOJYIFD46L"
	_check(
		bool(
			(
				INVITATION_URI_SCRIPT
				. parse(uri.replace("lobby=AAAAAAAAAAAAA", "lobby=" + shown_host_id))
				. ok
			)
		),
		"13-character Lobby IDs beginning E are valid 63-bit values"
	)
	_check(
		bool(
			(
				INVITATION_URI_SCRIPT
				. parse(uri.replace("lobby=AAAAAAAAAAAAA", "lobby=H777777777777"))
				. ok
			)
		),
		"maximum positive 63-bit Lobby ID beginning H is accepted"
	)
	_check(
		not (
			INVITATION_URI_SCRIPT
			. parse(uri.replace("lobby=AAAAAAAAAAAAA", "lobby=I000000000000"))
			. ok
		),
		"Lobby ID beyond the 63-bit range is rejected"
	)
	_check(
		not (
			INVITATION_URI_SCRIPT
			. parse(uri.replace("lobby=AAAAAAAAAAAAA", "lobby=7000000000000"))
			. ok
		),
		"out-of-range Base32 digit prefix is rejected"
	)
	_check(invite.get("address", "") == "192.168.1.22", "parsed host address is retained")
	_check(
		invite.get("port", 0) == 27777 and invite.get("epoch", 0) == 7,
		"parsed endpoint and session epoch are retained"
	)
	_check(
		invite.get("expires_unix", 0) == 2000000000,
		"parsed invitation includes a bounded canonical expiry"
	)
	_check(
		invite.get("digest", PackedByteArray()).size() == 32,
		"parsed compatibility digest has exact size"
	)
	_check(
		not INVITATION_URI_SCRIPT.parse(uri + "&code=BBBBBBBBBBBBBBBBBBBBBBBBBB").ok,
		"duplicate fields are rejected"
	)
	_check(
		not (
			INVITATION_URI_SCRIPT
			. parse(uri.replace("lobby=AAAAAAAAAAAAA", "lobby=ZZZZZZZZZZZZZ"))
			. ok
		),
		"overflowing Lobby ID is rejected"
	)
	var bad_lobby: Dictionary = INVITATION_URI_SCRIPT.parse(
		uri.replace("lobby=AAAAAAAAAAAAA", "lobby=ZZZZZZZZZZZZZ")
	)
	_check(
		str(bad_lobby.get("error", "")).contains("ZZZZZZZZZZZZZ"),
		"invalid scanned Lobby ID is shown for host comparison without exposing access code"
	)
	_check(
		not (
			INVITATION_URI_SCRIPT
			. parse(
				uri.replace("code=AAAAAAAAAAAAAAAAAAAAAAAAAA", "code=AAAAAAAAAAAAAAAAAAAAAAAAA-")
			)
			. ok
		),
		"noncanonical credential is rejected"
	)
	_check(
		not INVITATION_URI_SCRIPT.parse(uri.replace("protocol=1.2", "protocol=9.0")).ok,
		"unsupported protocol is rejected"
	)
	_check(
		not INVITATION_URI_SCRIPT.parse(uri.replace("host=192.168.1.22", "host=192.168.001.22")).ok,
		"ambiguous leading-zero IPv4 address is rejected"
	)
	_check(
		not INVITATION_URI_SCRIPT.parse(uri.replace("host=192.168.1.22", "host=239.1.1.1")).ok,
		"multicast host address is rejected"
	)
	_check(
		not INVITATION_URI_SCRIPT.parse(uri.replace("port=27777", "port=65536")).ok,
		"out-of-range host port is rejected"
	)
	_check(
		not INVITATION_URI_SCRIPT.parse(uri.replace("digest=" + "a".repeat(64), "digest=xyz")).ok,
		"non-hex compatibility digest is rejected"
	)
	_check(
		not INVITATION_URI_SCRIPT.parse(uri.replace("epoch=7", "epoch=07")).ok,
		"noncanonical session epoch is rejected"
	)
	_check(
		not INVITATION_URI_SCRIPT.parse(uri.replace("expires=2000000000", "expires=01")).ok,
		"noncanonical invitation expiry is rejected"
	)
	var permanent_invite: Dictionary = INVITATION_URI_SCRIPT.parse(
		uri.replace("expires=2000000000", "expires=0")
	)
	_check(
		(
			bool(permanent_invite.get("ok", false))
			and int(permanent_invite.get("expires_unix", -1)) == 0
		),
		"room-lifetime invitation marker is accepted"
	)
	_check(not INVITATION_URI_SCRIPT.parse(uri + "%20").ok, "encoded fields are rejected")
	_check(
		not INVITATION_URI_SCRIPT.parse("https://example.invalid/anything").ok,
		"arbitrary URL is rejected"
	)
	_check(
		not INVITATION_URI_SCRIPT.parse("tilaok://join?" + "x".repeat(513)).ok,
		"oversized QR payload is rejected"
	)


func _test_desktop_lobby_roles() -> void:
	var router := LocalInputRouter.new()
	root.add_child(router)
	var manager := NetworkSessionManager.new()
	manager.configure(router)
	root.add_child(manager)
	var screen := LOBBY_SCREEN.instantiate() as UiLanLobbyScreen
	screen.bind_session(manager)
	root.add_child(screen)
	await process_frame
	_check(screen._role_picker.visible, "desktop lobby starts with host or join choice")
	var host_controls_hidden := true
	for control in screen._host_only_controls:
		host_controls_hidden = host_controls_hidden and not control.visible
	_check(host_controls_hidden, "role chooser hides host setup controls")
	var join_controls_hidden := true
	for control in screen._client_only_controls:
		join_controls_hidden = join_controls_hidden and not control.visible
	_check(join_controls_hidden, "role chooser hides join controls")
	screen._select_role("host")
	_check(screen._interfaces.is_visible_in_tree(), "host choice shows interface selection")
	_check(screen._game_port.is_visible_in_tree(), "host choice shows host port settings")
	var join_controls_hidden_in_host := true
	for control in screen._client_only_controls:
		join_controls_hidden_in_host = join_controls_hidden_in_host and not control.visible
	_check(join_controls_hidden_in_host, "host choice hides join controls")
	screen._select_role("join")
	var host_controls_hidden_in_join := true
	for control in screen._host_only_controls:
		host_controls_hidden_in_join = host_controls_hidden_in_join and not control.visible
	_check(host_controls_hidden_in_join, "join choice hides host controls")
	_check(screen._lobby_id.is_visible_in_tree(), "Lobby ID is the primary join field")
	_check(screen._code.is_visible_in_tree(), "join still asks for the separate access code")
	_check(not screen._address.is_visible_in_tree(), "manual host address stays hidden by default")
	_check(not screen._scan_button.visible, "desktop join does not show the unavailable QR scanner")
	manager.lobby_id = 1
	manager.session_epoch = 7
	manager.selected_address = "192.168.1.22"
	manager.game_port = 27777
	manager.manifest_digest.resize(32)
	manager.invitation_expires_unix = 0
	var invitation_token := PackedByteArray()
	invitation_token.resize(16)
	manager.invitation_code = InvitationCode.encode(invitation_token)
	manager.invitation_expires_unix = 2000000000
	screen._update_qr()
	var host_qr_invitation: Dictionary = INVITATION_URI_SCRIPT.parse(screen._last_qr_value)
	_check(
		bool(host_qr_invitation.get("ok", false)),
		"the host-generated QR payload round-trips through the client invitation parser"
	)
	_check(
		int(host_qr_invitation.get("expires_unix", -1)) == 0,
		"host QR represents a room-lifetime invitation"
	)
	screen.queue_free()
	manager.free()
	router.free()
	await process_frame


func _test_phone_client_ui_and_authority() -> void:
	var router := LocalInputRouter.new()
	_check(
		router.set_authority(SimulationAuthority.client_presentation()),
		"client authority configures before lobby UI"
	)
	root.add_child(router)
	var manager := NetworkSessionManager.new()
	manager.configure(router)
	root.add_child(manager)
	var screen := LOBBY_SCREEN.instantiate() as UiLanLobbyScreen
	screen.client_only_mode = true
	screen.bind_session(manager)
	root.add_child(screen)
	await process_frame
	_check(screen._root.custom_minimum_size.x == 0, "phone layout has no desktop-width minimum")
	var host_controls_hidden := true
	for control in screen._host_only_controls:
		host_controls_hidden = host_controls_hidden and not control.visible
	_check(host_controls_hidden, "phone lobby has no host-only controls")
	_check(
		screen._client_only_controls.size() >= 4,
		"phone lobby exposes QR, lookup and manual join controls"
	)
	screen._lobby_id.text = "AAAAAAAAAAAA"
	screen._query_lobby()
	_check(
		(
			screen._client_notice.contains("You entered 12")
			and screen._client_notice.contains("copy all 13")
		),
		"manual Lobby ID error explains the required full 13 characters"
	)
	screen._lobby_id.text = "EWWOOJYIFD46L"
	screen._query_lobby()
	_check(
		(
			screen._client_notice.contains("access code")
			and screen._decode_lobby_id("EWWOOJYIFD46L") > 0
		),
		"manual lookup accepts the host's shown E-prefixed Lobby ID"
	)
	_check(
		screen._decode_lobby_id("7000000000000") == 0,
		"manual lookup rejects out-of-range Base32 digit prefix"
	)
	manager.state = NetworkSessionManager.SessionState.STARTING
	var duplicate_join_started := manager.connect_client(
		"192.168.1.22", 27777, "AAAAAAAAAAAAAAAAAAAAAAAAAA"
	)
	_check(
		not duplicate_join_started and not manager.transport.is_open,
		"repeated QR callbacks cannot open a second simultaneous connection"
	)
	manager.state = NetworkSessionManager.SessionState.OFFLINE
	manager.client_mode = true
	manager.client_assigned_seat = 0
	screen._refresh()
	_check(
		screen._ready_row.visible, "assigned phone seat exposes host-confirmed readiness control"
	)
	_check(screen._mobile_status.visible, "assigned phone retains connection status after joining")
	manager.client_assigned_seat = -1
	manager.client_mode = false
	manager.state = NetworkSessionManager.SessionState.LOBBY_OPEN
	manager.client_mode = true
	manager.stop_session()
	_check(
		router.authority.is_client_presentation() and router.registry.joined_seats().is_empty(),
		"leaving a phone session preserves client-only authority and creates no local seat"
	)
	screen.queue_free()
	manager.free()
	router.free()
	await process_frame


func _test_android_scanner_export_contract() -> void:
	var lobby_ui := FileAccess.get_file_as_string("res://scripts/ui/ui_lan_lobby_screen.gd")
	var editor_plugin := FileAccess.get_file_as_string(
		"res://addons/tilaok_qr_scanner/export_plugin.gd"
	)
	var android_plugin := (
		FileAccess
		. get_file_as_string(
			"res://addons/tilaok_qr_scanner/android/plugin/src/main/java/org/hoplyxd/tilaok/scanner/TilaokQrScannerPlugin.kt"
		)
	)
	var export_settings := FileAccess.get_file_as_string("res://export_presets.cfg")
	var enabled_plugins: PackedStringArray = ProjectSettings.get_setting(
		"editor_plugins/enabled", PackedStringArray()
	)
	_check(
		"res://addons/tilaok_qr_scanner/plugin.cfg" in enabled_plugins,
		"Android scanner export plugin is enabled in the project"
	)
	_check(
		export_settings.contains("gradle_build/use_gradle_build=true"),
		"Android scanner export selects the supported Gradle build"
	)
	_check(
		(
			editor_plugin.contains("com.google.zxing:core:3.5.3")
			and editor_plugin.contains("androidx.camera:camera-camera2:1.5.1")
		),
		"camera and offline ZXing dependencies are included in Android export"
	)
	_check(
		not editor_plugin.contains("mlkit") and not editor_plugin.contains("play-services"),
		"scanner export has no remote barcode model or metrics SDK"
	)
	_check(
		(
			android_plugin.contains("Manifest.permission.CAMERA")
			and android_plugin.contains("requestPermissions")
		),
		"camera permission is requested at scan time"
	)
	_check(
		(
			lobby_ui.contains('scanner.call("has_java_method", "startScan")')
			and not lobby_ui.contains('scanner.has_method("startScan")')
			and lobby_ui.contains("Opening the camera. Allow camera access when Android asks.")
		),
		"scanner checks the Android Java bridge and prompts for access before opening its preview"
	)
	_check(
		(
			android_plugin.contains("onMainRequestPermissionsResult")
			and android_plugin.contains("camera_permission_permanently_denied")
		),
		"permission grant, denial and permanent-denial results are surfaced"
	)
	_check(
		(
			android_plugin.contains("onMainPause")
			and android_plugin.contains("onBackPressedDispatcher")
			and android_plugin.contains("finishScan(cancelled = true)")
		),
		"pause and Android Back cancel scanning and release the camera"
	)
	_check(
		(
			android_plugin.contains("compareAndSet(false, true)")
			and android_plugin.contains("provider.unbindAll()")
			and android_plugin.contains("shutdownNow()")
		),
		"a visible QR produces one result and camera/listener resources are stopped"
	)
	var session_source := FileAccess.get_file_as_string(
		"res://scripts/network/network_session_manager.gd"
	)
	_check(
		(
			lobby_ui.contains("expires=0")
			and lobby_ui.contains("reusable until this room stops")
			and not lobby_ui.contains("Create fresh access code")
		),
		"host QR publishes the reusable room invitation"
	)
	_check(
		(
			session_source.contains("# The room credential is reusable")
			and not session_source.contains("INVITATION_LIFETIME_SECONDS")
		),
		"host keeps one invitation credential active for the room lifetime"
	)
	_check(
		(
			session_source.contains("_client_disconnect_notice_set")
			and session_source.contains("if not _client_disconnect_notice_set")
		),
		"specific rejection feedback survives the host closing its peer"
	)
	var gradle_module := FileAccess.get_file_as_string(
		"res://addons/tilaok_qr_scanner/android/plugin/build.gradle.kts"
	)
	_check(
		(
			gradle_module.contains("copyDebugAarToGodot")
			and gradle_module.contains("TilaokQrScanner-debug.aar")
		),
		"Gradle reproducibly builds the scanner library required for packaging"
	)


func _check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)

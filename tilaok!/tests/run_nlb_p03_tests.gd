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
		"tilaok://join?lobby=AAAAAAAAAAAAA&host=192.168.1.22&port=27777&protocol=1.1&digest=%s&code=AAAAAAAAAAAAAAAAAAAAAAAAAA&epoch=7"
		% "a".repeat(64)
	)
	var invite: Dictionary = INVITATION_URI_SCRIPT.parse(uri)
	_check(bool(invite.ok), "approved URI schema parses")
	_check(invite.get("address", "") == "192.168.1.22", "parsed host address is retained")
	_check(
		invite.get("port", 0) == 27777 and invite.get("epoch", 0) == 7,
		"parsed endpoint and session epoch are retained"
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
		not INVITATION_URI_SCRIPT.parse(uri.replace("protocol=1.1", "protocol=1.2")).ok,
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


func _check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)

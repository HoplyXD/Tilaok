class_name BuildIdentity
extends RefCounted
## NLB-P11: the single source of truth for this binary's inspectable build identity.
##
## `BUILD_ID` feeds the compatibility manifest digest (host and client must match), `VERSION` mirrors
## `application/config/version` in project.godot and the version fields of the release export
## presets, and the labels below are what the title, both lobbies and the settings screen show.
## Nothing here is secret: a label never carries a room code, token or address.

## Bumped from the P09 string in P11 so an older binary's digest differs and shows the readable
## build-mismatch notice. MIN_CONTENT in NLBLiveCompatibilityMatrix intentionally stays at the P09
## content identity: P11 changed no gameplay content, and that field is a minimum.
const BUILD_ID := "tilaok-nlb-p11-2026-10-21"
const VERSION := "0.4.0"
const PRODUCT := "Tilaok!"
const CHANNEL_DEV := "dev"
const CHANNEL_RELEASE := "release"


static func channel() -> String:
	return CHANNEL_RELEASE if OS.has_feature("release") else CHANNEL_DEV


## "Tilaok! v0.4.0 (dev)" - the short label shown on the title and in both lobbies.
static func label() -> String:
	return "%s v%s (%s)" % [PRODUCT, VERSION, channel()]


## "Tilaok! v0.4.0 (dev) - build tilaok-nlb-p11-2026-10-21" - the about line in settings.
static func about_line() -> String:
	return "%s - build %s" % [label(), BUILD_ID]


## Both labels for a host/client mismatch notice. `other_label` is whatever build text the peer
## advertised, or "" when it did not send one (older builds never do); it is length-capped and
## stripped of control characters here so nothing hostile reaches the UI.
static func mismatch_text(other_label: String = "") -> String:
	var mine := "This copy is %s." % label()
	var theirs := _sanitize(other_label)
	if theirs.is_empty():
		return mine
	return "%s The other copy is %s." % [mine, theirs]


static func _sanitize(text: String) -> String:
	var clean := ""
	for index in mini(text.length(), 48):
		var code := text.unicode_at(index)
		if code >= 32 and code != 127:
			clean += text[index]
	return clean.strip_edges()

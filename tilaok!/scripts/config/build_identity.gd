class_name BuildIdentity
extends RefCounted
## Single source of truth for this binary's inspectable build identity.
##
const BUILD_ID := "tilaok-offline-live-build-2026-10-22"
const VERSION := "0.4.0"
const PRODUCT := "Tilaok!"
const CHANNEL_DEV := "dev"
const CHANNEL_RELEASE := "release"


static func channel() -> String:
	return CHANNEL_RELEASE if OS.has_feature("release") else CHANNEL_DEV


## "Tilaok! v0.4.0 (dev)" - the short label shown on the title.
static func label() -> String:
	return "%s v%s (%s)" % [PRODUCT, VERSION, channel()]


## "Tilaok! v0.4.0 (dev) - build tilaok-offline-live-build-2026-10-22" - the about line in settings.
static func about_line() -> String:
	return "%s - build %s" % [label(), BUILD_ID]

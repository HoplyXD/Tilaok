class_name NlbBuildFlags
extends RefCounted
## NLB-P11: one release gate for every development-only command-line flag.
##
## A build carrying the built-in `release` feature tag (a release export template) or the
## `android_client` custom tag (both Android client presets) ignores development flags: harness,
## map and seed overrides, library/dev rows, the Barya rollback switch, the debug overlay, the
## unverified-content override, telemetry, fault injection and the P11 crowded-stage fixture.
## The one flag a release build still honours is `--match-route=network_live_build`, the explicit
## opt-in for the networked build (the offline default route is unchanged in every profile).

const RELEASE_TAG := "release"
const ANDROID_CLIENT_TAG := "android_client"
const TELEMETRY_PREFIX := "--nlb-telemetry="
const FAULT_PREFIX := "--nlb-fault="
const FIXTURE_FLAG := "--nlb-p11-fixture"


## Pure form for tests: development flags are allowed only when neither gating tag is present.
static func dev_flags_allowed_for(tags: PackedStringArray) -> bool:
	return not tags.has(RELEASE_TAG) and not tags.has(ANDROID_CLIENT_TAG)


static func dev_flags_allowed() -> bool:
	var tags := PackedStringArray()
	for tag in [RELEASE_TAG, ANDROID_CLIENT_TAG]:
		if OS.has_feature(tag):
			tags.append(tag)
	return dev_flags_allowed_for(tags)


## The user arguments a development flag may read: all of them in a development build, none in a
## release or Android client build.
static func dev_user_args() -> PackedStringArray:
	if dev_flags_allowed():
		return OS.get_cmdline_user_args()
	return PackedStringArray()


## True when `flag` is present as an exact argument and development flags are allowed.
static func dev_flag_present(flag: String) -> bool:
	return dev_user_args().has(flag)


## The value of `--name=value` from `arguments`, or "" when absent. Pure helper for the P11 tools.
static func value_from_args(arguments: PackedStringArray, prefix: String) -> String:
	var result := ""
	for argument in arguments:
		if argument.begins_with(prefix):
			result = argument.trim_prefix(prefix)
	return result

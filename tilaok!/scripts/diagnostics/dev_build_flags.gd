class_name DevBuildFlags
extends RefCounted
## Shared release gate for development-only command-line flags.
##
## Release builds ignore development-only command-line overrides.

const RELEASE_TAG := "release"


## Pure form for tests: development flags are allowed only when neither gating tag is present.
static func dev_flags_allowed_for(tags: PackedStringArray) -> bool:
	return not tags.has(RELEASE_TAG)


static func dev_flags_allowed() -> bool:
	var tags := PackedStringArray()
	if OS.has_feature(RELEASE_TAG):
		tags.append(RELEASE_TAG)
	return dev_flags_allowed_for(tags)


## The user arguments a development flag may read: all in development builds, none in release.
static func dev_user_args() -> PackedStringArray:
	if dev_flags_allowed():
		return OS.get_cmdline_user_args()
	return PackedStringArray()


## True when `flag` is present as an exact argument and development flags are allowed.
static func dev_flag_present(flag: String) -> bool:
	return dev_user_args().has(flag)


## The value of `--name=value` from `arguments`, or "" when absent.
static func value_from_args(arguments: PackedStringArray, prefix: String) -> String:
	var result := ""
	for argument in arguments:
		if argument.begins_with(prefix):
			result = argument.trim_prefix(prefix)
	return result

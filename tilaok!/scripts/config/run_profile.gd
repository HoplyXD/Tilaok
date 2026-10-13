class_name RunProfile
extends RefCounted

var profile_id: String
var label: String
var description: String
var development_only: bool
var required_content_ids: PackedStringArray
var required_modes: PackedStringArray
var required_kinds: PackedStringArray


func _init(
	id: String = "",
	display_label: String = "",
	details: String = "",
	is_development_only: bool = true,
	content_ids: PackedStringArray = PackedStringArray(),
	mode_ids: PackedStringArray = PackedStringArray(),
	pool_kinds: PackedStringArray = PackedStringArray()
) -> void:
	profile_id = id
	label = display_label
	description = details
	development_only = is_development_only
	required_content_ids = content_ids
	required_modes = mode_ids
	required_kinds = pool_kinds

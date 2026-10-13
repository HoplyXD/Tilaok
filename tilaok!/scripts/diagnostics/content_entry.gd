class_name DiagnosticContentEntry
extends RefCounted

var content_id: String
var kind: String
var implementation_complete: bool
var independently_verified: bool
var runtime_enabled: bool
var release_target: bool
var weight: float
var references: PackedStringArray


func _init(
	id: String = "",
	entry_kind: String = "item",
	implemented: bool = false,
	verified: bool = false,
	enabled: bool = false,
	is_release_target: bool = false,
	selection_weight: float = 0.0,
	referenced_ids: PackedStringArray = PackedStringArray()
) -> void:
	content_id = id
	kind = entry_kind
	implementation_complete = implemented
	independently_verified = verified
	runtime_enabled = enabled
	release_target = is_release_target
	weight = selection_weight
	references = referenced_ids

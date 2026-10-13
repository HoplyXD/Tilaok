class_name ProfileRegistry
extends RefCounted

const _PROFILES: Dictionary = {
	"movement_room":
	{
		"label": "Movement Room (diagnostic only)",
		"description": "Foundation startup; no movement mechanics are implemented.",
		"development_only": true,
		"content": [],
		"modes": [],
		"pools": [],
	},
	"karera_slice":
	{
		"label": "Karera Slice (incomplete development profile)",
		"description": "Requires verified Kaing Stack and Tulay na Kawayan.",
		"development_only": true,
		"content": ["build.hollow_blocks", "build.bamboo_bridge"],
		"modes": ["karera"],
		"pools": ["item"],
	},
	"karera_spring":
	{
		"label": "Karera + Spring (incomplete development profile)",
		"description": "Adds verified Gulong Talon to the Karera slice.",
		"development_only": true,
		"content": ["build.hollow_blocks", "build.bamboo_bridge", "move.tire_spring"],
		"modes": ["karera"],
		"pools": ["item"],
	},
	"lagsanay_lab":
	{
		"label": "Lagsanay Lab (incomplete development profile)",
		"description": "Requires verified Lagsanay and a selectable diagnostic item pool.",
		"development_only": true,
		"content": [],
		"modes": ["lagsanay"],
		"pools": ["item"],
	},
	"kangaroo_contract_lab":
	{
		"label": "Kangaroo Contract Lab (incomplete development profile)",
		"description": "Requires verified Kangaroo and a selectable diagnostic item pool.",
		"development_only": true,
		"content": [],
		"modes": ["kangaroo"],
		"pools": ["item"],
	},
	"stack_lab":
	{
		"label": "Event Stack Lab (incomplete development profile)",
		"description": "Requires verified modes, compatibility pairs, and their content.",
		"development_only": true,
		"content": [],
		"modes":
		[
			"karera",
			"lagsanay",
			"kangaroo",
			"stack_karera_lagsanay",
			"stack_karera_kangaroo",
			"stack_kangaroo_lagsanay"
		],
		"pools": ["item", "pair"],
	},
	"release_candidate":
	{
		"label": "Release Candidate (currently invalid)",
		"description": "Requires all scheduled Main Challenges and sudden-death Lagsanay.",
		"development_only": false,
		"content": [],
		"modes": ["karera", "lagsanay", "kangaroo", "sudden_death_lagsanay"],
		"pools": ["item"],
	},
}


static func ids() -> PackedStringArray:
	var result := PackedStringArray()
	for key in _PROFILES:
		result.append(key)
	return result


static func get_profile(profile_id: String) -> RunProfile:
	if not _PROFILES.has(profile_id):
		return null
	var data: Dictionary = _PROFILES[profile_id]
	return RunProfile.new(
		profile_id,
		data.label,
		data.description,
		data.development_only,
		PackedStringArray(data.content),
		PackedStringArray(data.modes),
		PackedStringArray(data.pools)
	)

class_name ConfigurationSnapshot
extends RefCounted

var gameplay: GameplayTuning
var presentation: PresentationSettings
var profile_id: String
var seed_value: int
var run_id: int
var rule_proposals_active: Dictionary = {"R1": false, "R2": false, "R3": false, "R4": false}


static func create(
	source_gameplay: GameplayTuning,
	source_presentation: PresentationSettings,
	selected_profile_id: String,
	selected_seed: int,
	selected_run_id: int
) -> ConfigurationSnapshot:
	var snapshot := ConfigurationSnapshot.new()
	snapshot.gameplay = source_gameplay.duplicate(true) as GameplayTuning
	snapshot.presentation = source_presentation.duplicate(true) as PresentationSettings
	snapshot.profile_id = selected_profile_id
	snapshot.seed_value = selected_seed
	snapshot.run_id = selected_run_id
	snapshot.rule_proposals_active = {"R1": false, "R2": false, "R3": false, "R4": false}
	return snapshot


func apply_presentation_while_paused(settings: PresentationSettings, is_paused: bool) -> bool:
	if not is_paused or settings == null or not settings.validate().is_empty():
		return false
	presentation = settings.duplicate(true) as PresentationSettings
	return true

class_name SupportTracker
extends RefCounted

var surfaces: Dictionary = {}
var contacts_by_actor: Dictionary = {}
var finalized_step := -1
var validation_errors := PackedStringArray()
var tuning: GameplayTuning


func configure(source_tuning: GameplayTuning) -> void:
	tuning = source_tuning if source_tuning != null else GameplayTuning.new()


func register_surface(metadata: SupportSurfaceMetadata) -> bool:
	if metadata == null:
		validation_errors.append("solid support surface is missing metadata")
		return false
	var errors := metadata.validate(surfaces)
	if not errors.is_empty():
		validation_errors.append_array(errors)
		return false
	if surfaces.has(metadata.surface_id):
		validation_errors.append("duplicate support surface ID '%s'" % metadata.surface_id)
		return false
	surfaces[metadata.surface_id] = metadata
	return true


func validate_metadata() -> PackedStringArray:
	var errors := PackedStringArray()
	for metadata_variant in surfaces.values():
		var metadata := metadata_variant as SupportSurfaceMetadata
		errors.append_array(metadata.validate(surfaces))
	return errors


func validate_scene(root: Node) -> PackedStringArray:
	var errors := PackedStringArray()
	if root == null:
		return PackedStringArray(["support scene root is missing"])
	var pending: Array[Node] = [root]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		if node.is_in_group("support_surfaces"):
			var metadata := SupportSurfaceMetadata.for_collider(node)
			if metadata == null:
				errors.append("support surface '%s' is missing metadata" % node.name)
			else:
				errors.append_array(metadata.validate(surfaces))
		for child in node.get_children():
			pending.append(child)
	return errors


func record_actor_step(actor_id: String, actor: CharacterBody2D, physics_step: int) -> void:
	var contacts: Array[SupportContact] = []
	if actor != null and is_instance_valid(actor):
		var feet_y: float = actor.global_position.y + actor.get_meta("support_half_height", 24.0)
		for collision_index in range(actor.get_slide_collision_count()):
			var collision := actor.get_slide_collision(collision_index)
			var collider := collision.get_collider()
			var metadata := SupportSurfaceMetadata.for_collider(collider)
			if metadata == null:
				if collider is Node and (collider as Node).is_in_group("support_surfaces"):
					validation_errors.append("support surface collision is missing metadata")
				continue
			if not surfaces.has(metadata.surface_id):
				continue
			var normal := collision.get_normal().normalized()
			var minimum_dot := cos(deg_to_rad(tuning.support_normal_limit_degrees))
			if normal.dot(Vector2.UP) < minimum_dot:
				continue
			var contact_position := collision.get_position()
			if absf(contact_position.y - feet_y) > tuning.support_contact_tolerance_wu:
				continue
			var provenance := metadata.resolved_provenance(surfaces)
			var contact := SupportContact.new()
			contact.actor_id = actor_id
			contact.surface_id = metadata.surface_id
			contact.construction_id = str(provenance.construction_id)
			contact.player_built = bool(provenance.player_built)
			contact.eligibility = metadata.wave_support_eligibility
			contact.normal = normal
			contact.contact_position = contact_position
			contact.feet_y = feet_y
			contact.relative_velocity = actor.velocity - collision.get_collider_velocity()
			contact.physics_step = physics_step
			contacts.append(contact)
	contacts_by_actor[actor_id] = contacts


func finalize_physics_step(physics_step: int) -> void:
	finalized_step = physics_step


func invalidate_actor(actor_id: String) -> void:
	contacts_by_actor.erase(actor_id)


func invalidate_surface(surface_id: String) -> void:
	surfaces.erase(surface_id)
	for actor_id in contacts_by_actor.keys():
		var kept: Array[SupportContact] = []
		for contact in contacts_by_actor[actor_id]:
			if contact.surface_id != surface_id:
				kept.append(contact)
		contacts_by_actor[actor_id] = kept


func clear() -> void:
	surfaces.clear()
	contacts_by_actor.clear()
	validation_errors.clear()
	finalized_step = -1


func evaluate(actor_id: String, line_y: float, height_epsilon: float = 1.0) -> Dictionary:
	var contacts: Array = contacts_by_actor.get(actor_id, [])
	if contacts.is_empty():
		return {"qualifies": false, "reason": "no support", "contact": null}
	var chosen: SupportContact
	for contact_variant in contacts:
		var contact := contact_variant as SupportContact
		if contact.physics_step != finalized_step:
			continue
		if contact.qualifies(line_y, height_epsilon):
			return {"qualifies": true, "reason": "eligible built support", "contact": contact}
		if chosen == null or contact.surface_id < chosen.surface_id:
			chosen = contact
	if chosen == null:
		return {"qualifies": false, "reason": "no support", "contact": null}
	var reason := "feet below line"
	if not chosen.player_built:
		reason = "base surface"
	elif chosen.eligibility == SupportSurfaceMetadata.Eligibility.UNSET:
		reason = "invalid metadata"
	elif chosen.eligibility != SupportSurfaceMetadata.Eligibility.ELIGIBLE:
		reason = "ineligible surface"
	return {"qualifies": false, "reason": reason, "contact": chosen}

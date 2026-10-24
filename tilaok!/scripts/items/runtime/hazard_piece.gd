class_name HazardPiece
extends ConstructionPiece

## Placed moving/timed item: static collision from ConstructionPiece plus one runtime behavior and
## a painter-driven presentation. Everything visible resolves through the family ItemVisualSet.

var behavior: ItemBehavior
var family: ItemFamilyDefinition
var variant: ItemVariantDefinition
var tuning_ref: GameplayTuning
var visual_time := 0.0
## Owner tags can be enabled inside the Item Visualizer harness; hidden in normal play.
var show_owner_tag := false
## False when a scene Visual node already draws the fixed art, so the painter adds only the parts
## that move or change with state (see ItemSilhouettePainter.draw_variant).
var painter_static_parts := true
## Only a running piece redraws every frame; Place-mode pieces redraw on change.
var animating := false
var _players: Dictionary = {}


func attach_behavior(
	source_family: ItemFamilyDefinition,
	source_variant: ItemVariantDefinition,
	source_behavior: ItemBehavior,
	source_tuning: GameplayTuning
) -> void:
	family = source_family
	variant = source_variant
	behavior = source_behavior
	tuning_ref = source_tuning
	queue_redraw()


func reset_to_start() -> void:
	if simulation_authority == null or not simulation_authority.can_commit():
		return
	if behavior != null:
		behavior.reset_to_start()
	queue_redraw()


func _process(delta: float) -> void:
	visual_time += delta
	if behavior != null and simulation_authority != null and simulation_authority.can_commit():
		for slot_id in behavior.pending_sounds:
			play_slot(slot_id)
		behavior.pending_sounds.clear()
	if animating:
		queue_redraw()


func set_animating(value: bool) -> void:
	if simulation_authority == null or not simulation_authority.can_commit():
		return
	animating = value
	queue_redraw()


## Plays the slot's sound if one is assigned; a missing slot is silent, never an error.
func play_slot(slot_id: String) -> bool:
	if family == null or family.visual_set == null:
		return false
	var stream := family.visual_set.sound(slot_id)
	if stream == null:
		return false
	var player: AudioStreamPlayer = _players.get(slot_id)
	if player == null:
		player = AudioStreamPlayer.new()
		player.name = "Sfx_%s" % slot_id
		player.bus = PresentationApplier.BUS_EFFECTS
		add_child(player)
		_players[slot_id] = player
	player.stream = stream
	player.play()
	return true


func _draw() -> void:
	if family == null or variant == null or placed == null:
		return
	var state: Dictionary = behavior.readout() if behavior != null else {}
	state["elapsed"] = float(state.get("elapsed", visual_time)) + 0.0
	var tag := ""
	if show_owner_tag:
		tag = "%s • P%d • PLACEHOLDER" % [family.working_name, placed.owner_seat + 1]
	ItemSilhouettePainter.draw_variant(
		self, family, variant, placed.quarter_turns, tuning_ref, state, tag, painter_static_parts
	)

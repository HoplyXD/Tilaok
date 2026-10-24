extends SceneTree

## 2026-10-14 movement & blocks extension: 64 wu stage tiles, W/Up jump in Play, sneak, glide,
## and the scene-authored Solid Block, Wood Box and Collapsing Block. Synthetic input plus real
## Godot physics in the Item Lab (64 wu grid). Not physical-device or human feel evidence.
## Run: godot --headless --path tilaok! --script res://tests/run_blocks_tests.gd

const ROOM_SCENE := preload("res://scenes/fixtures/item_lab.tscn")
const SOLID := "build.solid_block.slab_3x1"
const BOX := "build.wood_box.box_2x2"
const COLLAPSE := "build.collapsing_block.cell_1x1"
const SPIKES := "block.spikes.main"
const CANNON := "block.cannon.main"
const KAING_1X1 := "build.hollow_blocks.cell_1x1"
const KAING_1X3 := "build.hollow_blocks.column_1x3"
const BLOCK_SCENES := {
	SOLID: "res://scenes/blocks/construction/solid_block.tscn",
	BOX: "res://scenes/blocks/construction/wood_box.tscn",
	COLLAPSE: "res://scenes/blocks/construction/collapsing_block.tscn",
}
const FLOOR_Y := 960.0
const TOLERANCE := 1.0
const ANIMATIONS_NODE := "Animations"

var failures := 0
var checks := 0
var room: ItemLabRoom
var actor: ChickenController
var seat := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	room = ROOM_SCENE.instantiate() as ItemLabRoom
	root.add_child(room)
	await _frames(3)
	_test_grid_and_tiles()
	_test_block_scene_authoring()
	seat = room.join_keyboard("K1")
	actor = room.actors[seat] as ChickenController
	room.start_play()
	await _frames(3)
	await _test_controls()
	await _test_sneak()
	await _test_sneak_headroom()
	await _test_glide()
	await _test_solid_block()
	await _test_wood_box()
	await _test_collapsing_block()
	await _test_chicken_animations()
	await _test_spikes()
	await _test_cannon()
	await _test_stun_controls_and_death()
	room.queue_free()
	await process_frame
	await _test_drop_in_block()
	print("BLOCKS_TESTS checks=%d failures=%d" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _check(condition: bool, label: String) -> void:
	checks += 1
	if condition:
		print("PASS ", label)
	else:
		failures += 1
		push_error("FAIL " + label)


func _frames(count: int) -> void:
	for _frame in range(count):
		await physics_frame


func _key(key: int, down: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.keycode = key
	event.pressed = down
	room.input_router._handle_key(event)


func _release_all() -> void:
	for key in [KEY_A, KEY_D, KEY_W, KEY_S, KEY_SPACE]:
		_key(key, false)
	room.input_router._stick_x[seat] = 0.0


func _half_height() -> float:
	return room.tuning.body_height_wu * 0.5


func _feet_y() -> float:
	return actor.global_position.y + _half_height()


func _put_actor_feet(feet: Vector2) -> void:
	actor.global_position = feet - Vector2(0.0, _half_height())
	actor.velocity = Vector2.ZERO
	actor.locomotion_velocity = Vector2.ZERO
	actor.external_velocity = Vector2.ZERO
	actor.coyote_remaining = 0.0
	actor.jump_buffer_remaining = 0.0
	actor.reset_wall_state()
	actor.lifecycle.status = PlayerLifecycleState.Status.ACTIVE
	room.support_tracker.invalidate_actor(actor.support_actor_id)


## Runtime collision shapes of a placed block (rebuilt from its catalog regions).
func _block_shapes(block: Node) -> Array[CollisionShape2D]:
	var result: Array[CollisionShape2D] = []
	for child in block.get_children():
		if child is CollisionShape2D:
			result.append(child)
	return result


## The hitbox the chicken currently presents to physics. It carries one shape per pose
## (standing, airborne, sneaking) and enables exactly the one its state calls for.
func _body_shape() -> CollisionShape2D:
	for child in actor.get_children():
		if child is CollisionShape2D and not (child as CollisionShape2D).disabled:
			return child
	return null


## Places entries (variant, cell, turns) as one fresh construction set and starts Play.
func _arrange(entries: Array) -> Array[String]:
	_release_all()
	var items := room.items
	items.reset_match()
	var ids: Array[String] = []
	var no_rects: Array[Rect2] = []
	for entry in entries:
		var result := items.place(
			str(entry[0]),
			entry[1] as Vector2i,
			int(entry[2]) if entry.size() > 2 else 0,
			0,
			no_rects
		)
		_check(bool(result.allowed), "arrange %s at %s: %s" % [entry[0], entry[1], result.reason])
		ids.append(str(result.get("instance_id", "")))
	items.begin_play()
	room.input_router.set_phase(LocalInputRouter.Phase.PLAY)
	return ids


# ---------------------------------------------------------------- spikes, cannon, stun, drop-in


func _records(kind: AttributionRecord.Kind) -> Array[AttributionRecord]:
	var result: Array[AttributionRecord] = []
	for record in room.items.director.records:
		if record.kind == kind:
			result.append(record)
	return result


func _revive() -> void:
	actor.lifecycle.status = PlayerLifecycleState.Status.ACTIVE
	actor.lifecycle.terminal_reason = ""
	actor.clear_stun()


## Places entries as one fresh set (owner seat per entry) and waits out the activation grace.
func _arm(entries: Array, owner: int = 1) -> Array[String]:
	_release_all()
	room.items.reset_match()
	room.items.director.records.clear()
	var ids: Array[String] = []
	var no_rects: Array[Rect2] = []
	for entry in entries:
		var turns := int(entry[2]) if entry.size() > 2 else 0
		var result := room.items.place(str(entry[0]), entry[1] as Vector2i, turns, owner, no_rects)
		_check(bool(result.allowed), "place %s at %s: %s" % [entry[0], entry[1], result.reason])
		ids.append(str(result.get("instance_id", "")))
	room.items.begin_play()
	room.input_router.set_phase(LocalInputRouter.Phase.PLAY)
	return ids


func _test_spikes() -> void:
	var definitions := room.definitions
	var spikes := definitions.find_variant(SPIKES)
	_check(not spikes.is_empty(), "Spikes is in the catalog with no code or data edit")
	if spikes.is_empty():
		return
	var regions := (spikes.variant as ItemVariantDefinition).regions
	var kinds := {}
	for region in regions:
		kinds[region.kind] = region.rect_cells
	_check(
		(
			kinds.get(ItemRegionSpec.Kind.SOLID) == Rect2(0, 0.5, 1, 0.5)
			and kinds.has(ItemRegionSpec.Kind.TRIGGER)
		),
		"Spikes: solid bottom half and a kill hitbox, independent of its 1x1 placement box"
	)
	# Upright spikes on the floor: landing on the points eliminates, credited to the placer.
	# (2026-10-15: the kill hitbox was narrowed to 60x24 inside the points, so it is reached
	# from above, not by brushing the stone base from the side.)
	_revive()
	var ids := _arm([[SPIKES, Vector2i(16, 14)]], 1)
	_put_actor_feet(Vector2(14.0 * 64.0 + 32.0, FLOOR_Y))
	await _frames(70)
	_check(actor.lifecycle.is_terminal() == false, "a chicken beside the spikes is safe")
	_put_actor_feet(Vector2(16.0 * 64.0 + 32.0, FLOOR_Y - 192.0))
	var died := false
	for _frame in range(90):
		await physics_frame
		if actor.lifecycle.status == PlayerLifecycleState.Status.ELIMINATED:
			died = true
			break
	var kills := _records(AttributionRecord.Kind.ELIMINATION)
	_check(died, "landing on the spike points eliminates the chicken")
	_check(
		(
			kills.size() == 1
			and kills[0].source_item_id == ids[0]
			and kills[0].owner_seat == 1
			and kills[0].credit_eligible()
		),
		"the spikes kill is credited to the placer (Patibong)"
	)
	# Ceiling spikes (turned 180): the solid half is on top and can be stood on.
	_revive()
	ids = _arm([[SPIKES, Vector2i(22, 10), 2]], 1)
	var top := 10.0 * 64.0
	_put_actor_feet(Vector2(22.0 * 64.0 + 32.0, top - 40.0))
	await _frames(80)
	_check(
		(
			not actor.lifecycle.is_terminal()
			and actor.is_on_floor()
			and absf(_feet_y() - top) <= TOLERANCE
		),
		"turned spikes: a chicken stands safely on the solid half"
	)
	_revive()
	room.items.reset_match()


func _test_cannon() -> void:
	_revive()
	var ids := _arm([[CANNON, Vector2i(12, 14)]], 1)
	var cannon := room.items.piece_for(ids[0]) as StageBlock
	var behavior := cannon.behavior as LauncherBehavior
	# The Cannon's Path2D is drawn past the stage edge (since 2026-10-16), so the lane is cut at
	# the build region's right edge: from the barrel's right side (x 832) to x 1792.
	var expected_lane := room.arena.build_region.end.x - 13.0 * 64.0
	_check(
		(
			behavior != null
			and behavior.lane_dir == Vector2.RIGHT
			and is_equal_approx(behavior.lane_length, expected_lane)
		),
		(
			"Cannon fires right along its Path2D, cut at the build region edge (%s wu, expected %s)"
			% [behavior.lane_length if behavior != null else -1.0, expected_lane]
		)
	)
	_check(
		is_equal_approx(cannon.behavior.tuning.item_launcher_cooldown_s, 2.0),
		"Cannon's own fire interval (2 s) overrides the global launcher cooldown"
	)
	var barrel := cannon.get_node_or_null("Visual/AnimatedSprite2D") as AnimatedSprite2D
	_check(
		(
			barrel != null and not barrel.sprite_frames.get_animation_loop(&"shoot")
		),
		"the barrel's shoot animation is a one-shot"
	)
	_put_actor_feet(Vector2(15.0 * 64.0 + 32.0, FLOOR_Y))
	var died := false
	var saw_ball := false
	# The wind-up runs through the telegraph, so the muzzle-blast frame should be on screen at the
	# moment the ball spawns rather than the barrel sitting at rest.
	var shots_seen := 0
	var pose_at_shot := ""
	var frame_at_shot := -1
	for _frame in range(240):
		_put_actor_feet(Vector2(15.0 * 64.0 + 32.0, FLOOR_Y))
		await physics_frame
		await process_frame
		saw_ball = saw_ball or cannon.get_node_or_null("ProjectileVisual0") != null
		if barrel != null and behavior.shots_fired > shots_seen:
			shots_seen = behavior.shots_fired
			pose_at_shot = str(barrel.animation)
			frame_at_shot = barrel.frame
		if actor.lifecycle.status == PlayerLifecycleState.Status.ELIMINATED:
			died = true
			break
	var kills := _records(AttributionRecord.Kind.ELIMINATION)
	_check(died, "a cannon ball eliminates a chicken in its path")
	_check(saw_ball, "the projectile template's Visual is shown for each live ball")
	_check(
		not kills.is_empty() and kills[0].source_family_id == "block.cannon",
		"the cannon kill names the cannon family"
	)
	# Frame 4 of 0-8 is the muzzle blast; the four before it are the 0.8 s wind-up.
	_check(
		pose_at_shot == "shoot" and frame_at_shot >= 3 and frame_at_shot <= 5,
		(
			"the barrel is on its blast frame when the ball spawns (%s frame %d)"
			% [pose_at_shot, frame_at_shot]
		)
	)
	# Cover: a Kaing block in the path stops the ball.
	_revive()
	# A 1x1 Kaing is pushable and falls away before the Cannon fires. Use the
	# anchored column variant to test projectile occlusion by stable cover.
	ids = _arm([[CANNON, Vector2i(12, 14)], [KAING_1X3, Vector2i(14, 12)]], 1)
	cannon = room.items.piece_for(ids[0]) as StageBlock
	behavior = cannon.behavior as LauncherBehavior
	for _frame in range(240):
		_put_actor_feet(Vector2(16.0 * 64.0 + 32.0, FLOOR_Y))
		await physics_frame
	_check(
		behavior.shots_fired >= 1 and actor.lifecycle.status == PlayerLifecycleState.Status.ACTIVE,
		"a solid block in the path stops the ball; the chicken behind it survives"
	)
	_revive()
	room.items.reset_match()


func _test_stun_controls_and_death() -> void:
	_revive()
	room.items.reset_match()
	room.items.begin_play()
	_put_actor_feet(Vector2(736.0, FLOOR_Y))
	await _frames(10)
	var x_before := actor.global_position.x
	_check(actor.apply_stun(1.0, Vector2(480.0, -240.0)), "apply_stun accepts an active chicken")
	_key(KEY_A, true)
	_key(KEY_W, true)
	await _frames(20)
	_check(
		actor.is_stunned() and actor.global_position.x > x_before + 20.0,
		"a stunned chicken is knocked back and ignores walking left"
	)
	_check(await _anim_after(1) == &"stun", "a stunned chicken plays the stun animation")
	_check(not actor.apply_stun(1.0), "no re-stun while the stun and its immunity last")
	_key(KEY_A, false)
	_key(KEY_W, false)
	await _frames(70)
	_check(not actor.is_stunned(), "the stun wears off after its duration")
	actor.eliminate("test")
	_check(await _anim_after(2) == &"dead", "an eliminated chicken shows the death sprite")
	# 2026-10-15 (user request): a chicken eliminated in mid-air keeps falling and lands; it does not
	# hang where it died, and it no longer moves sideways or reacts to input.
	_revive()
	_put_actor_feet(Vector2(736.0, FLOOR_Y - 256.0))
	actor.eliminate("test: mid-air")
	_key(KEY_D, true)
	await _frames(90)
	_key(KEY_D, false)
	_check(
		(
			absf(actor.global_position.y + _half_height() - FLOOR_Y) <= TOLERANCE
			and absf(actor.global_position.x - 736.0) <= TOLERANCE
			and actor.lifecycle.status == PlayerLifecycleState.Status.ELIMINATED
		),
		(
			"a chicken eliminated in mid-air falls straight down and lands (feet y %.1f)"
			% (actor.global_position.y + _half_height())
		)
	)
	_revive()
	actor.reset_for_round(actor.global_position)


## A block scene saved into scenes/blocks/ joins the catalog, the default pool, the Item Lab eggs
## and play with no other edit. Built from the Spikes scene: Heavy anchor + a STUN hitbox.
func _test_drop_in_block() -> void:
	var path := "res://scenes/blocks/zz_test_drop_in.tscn"
	var source := (load("res://scenes/blocks/traps/spikes.tscn") as PackedScene).instantiate()
	var data := source.get_node("BlockData") as BlockData
	data.block_name = "Test Stun Weight"
	data.catalog_order = 999
	data.kill = false
	data.stun = true
	data.stun_seconds = 0.5
	data.anchor = BlockData.Anchor.HEAVY
	data.rotations = PackedInt32Array([0])
	(source.get_node("KillHitbox") as BlockHitbox).effect = BlockHitbox.Effect.STUN
	var packed := PackedScene.new()
	packed.pack(source)
	source.free()
	_check(ResourceSaver.save(packed, path) == OK, "drop-in scene saved into scenes/blocks/")
	BlockCatalog.reload()
	var key := "block.zz_test_drop_in.main"
	_check(
		ItemDefinitions.load_all(GameplayTuning.new()).find_variant(key).size() == 2,
		"the dropped-in scene is a defined block"
	)
	_check(
		GameplayTuning.new().item_enabled_variants.has(key),
		"the dropped-in block is in the default selection pool"
	)
	room = ROOM_SCENE.instantiate() as ItemLabRoom
	root.add_child(room)
	await _frames(3)
	_check(room.egg_previews.has(key), "the Item Lab shows an egg for the dropped-in block")
	seat = room.join_keyboard("K1")
	actor = room.actors[seat] as ChickenController
	room.start_play()
	await _frames(3)
	var ids := _arm([[key, Vector2i(11, 8)]], 1)
	var block := room.items.piece_for(ids[0]) as StageBlock
	var start_y := block.position.y
	await _frames(80)
	_check(block.position.y > start_y + 100.0, "a Heavy block falls under gravity")
	var resting_x := block.position.x
	_put_actor_feet(Vector2(block.position.x + 64.0 + 29.0, FLOOR_Y))
	_key(KEY_A, true)
	await _frames(30)
	_key(KEY_A, false)
	_check(
		absf(block.position.x - resting_x) < 0.5,
		"a Heavy block cannot be pushed by a walking chicken"
	)
	_revive()
	_put_actor_feet(Vector2(block.position.x + 32.0, block.position.y - 30.0))
	var stunned := false
	for _frame in range(20):
		await physics_frame
		stunned = stunned or actor.is_stunned()
	_check(stunned, "touching a STUN hitbox stuns the chicken")
	_check(not actor.lifecycle.is_terminal(), "a stun never eliminates")
	var setups := _records(AttributionRecord.Kind.SETUP)
	_check(
		not setups.is_empty() and setups[0].detail == "stun" and not setups[0].credit_eligible(),
		"a stun is recorded as an uncredited setup effect"
	)
	room.items.reset_match()
	room.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	BlockCatalog.reload()
	_check(
		not GameplayTuning.new().item_enabled_variants.has(key),
		"removing the scene removes the block again"
	)


# ---------------------------------------------------------------- chicken scene and animations


## The colour sprite the actor is drawn with: the Animations child whose skin_color is nearest its
## marker_color, as ChickenSpriteAnimator picks it.
func _worn_sprite() -> ChickenSpriteAnimator:
	var worn: ChickenSpriteAnimator = null
	for node in actor.get_node(ANIMATIONS_NODE).get_children():
		var sprite := node as ChickenSpriteAnimator
		if sprite == null:
			continue
		if (
			worn == null
			or (
				ChickenSpriteAnimator.skin_distance(sprite.skin_color, actor.marker_color)
				< ChickenSpriteAnimator.skin_distance(worn.skin_color, actor.marker_color)
			)
		):
			worn = sprite
	return worn


func _anim_after(frames: int) -> StringName:
	await _frames(frames)
	await process_frame
	return _worn_sprite().animation


## Waits up to `max_frames` for the animation to become `pose` and returns what it actually is,
## so a failure reports the pose that was stuck. The one-shot transitions run 0.6-1.0 s (4 frames
## at 5 fps), far longer than a fixed wait should hard-code.
func _await_anim(pose: StringName, max_frames: int = 75) -> StringName:
	var sprite := _worn_sprite()
	for _frame in range(max_frames):
		await _frames(1)
		await process_frame
		if sprite.animation == pose:
			return sprite.animation
	return sprite.animation


func _test_chicken_animations() -> void:
	room.items.reset_match()
	room.items.begin_play()
	_release_all()
	var sprites := actor.find_children("*", "AnimatedSprite2D", true, false).filter(
		func(node: Node) -> bool: return node is ChickenSpriteAnimator
	)
	var sprite := _worn_sprite() if actor.has_node(ANIMATIONS_NODE) else null
	_check(sprite != null and not actor.draw_debug_body, "chickens use the animated chicken scene")
	if sprite == null:
		return
	_check(sprites.size() == 4, "the chicken scene has one sprite per seat colour")
	var skins_ok := true
	var own_color := actor.marker_color
	for color in PlayerSeatRegistry.COLORS:
		actor.marker_color = color
		await process_frame
		await process_frame
		var shown := sprites.filter(func(node: Node) -> bool: return (node as Node2D).visible)
		skins_ok = (
			skins_ok
			and shown.size() == 1
			and (shown[0] as ChickenSpriteAnimator).skin_color.is_equal_approx(color)
			and (shown[0] as CanvasItem).modulate == Color.WHITE
		)
	_check(skins_ok, "each seat colour shows only its own untinted chicken sprite")
	actor.marker_color = own_color
	await process_frame
	await process_frame
	sprite = _worn_sprite()
	# Every pose ChickenSpriteAnimator.pose_for_state() can ask for.
	var names := [
		&"idle",
		&"run_right",
		&"run_left",
		&"wall_slide_right",
		&"wall_slide_left",
		&"sneak",
		&"sneak_hold",
		&"sneak_stand",
		&"jump",
		&"jump_right",
		&"jump_left",
		&"jump_falling",
		&"jump_right_falling",
		&"jump_left_falling",
		&"jump_gliding",
		&"jump_right_gliding",
		&"jump_left_gliding",
		&"jump_landing",
		&"jump_right_landing",
		&"jump_left_landing",
		&"stun",
		&"dead",
	]
	var frames_ok := true
	var sides_ok := true
	var timing_ok := true
	for node in sprites:
		var frames := (node as AnimatedSprite2D).sprite_frames
		var folder := frames.get_frame_texture(&"idle", 0).resource_path.get_base_dir()
		# Left and right poses must not share art (a copied animation left on the wrong side).
		for pose in [&"jump%s", &"jump%s_falling", &"jump%s_landing", &"wall_slide%s"]:
			var left := frames.get_frame_texture(StringName(pose % "_left"), 0)
			var right := frames.get_frame_texture(StringName(pose % "_right"), 0)
			sides_ok = sides_ok and left != right
		for anim_name in names:
			frames_ok = frames_ok and frames.has_animation(anim_name)
			if not frames.has_animation(anim_name):
				continue
			# The colours are the same chicken, so each pose must time out alike in all of them.
			var reference := (sprites[0] as AnimatedSprite2D).sprite_frames
			timing_ok = (
				timing_ok
				and frames.get_frame_count(anim_name) == reference.get_frame_count(anim_name)
				and frames.get_animation_loop(anim_name) == reference.get_animation_loop(anim_name)
				and (
					is_equal_approx(
						frames.get_animation_speed(anim_name),
						reference.get_animation_speed(anim_name)
					)
				)
			)
			for index in frames.get_frame_count(anim_name):
				var texture := frames.get_frame_texture(anim_name, index)
				frames_ok = (
					frames_ok
					and texture != null
					and not texture is AtlasTexture
					and texture.get_size() == Vector2(2048, 2048)
					and texture.resource_path.get_base_dir() == folder
				)
	_check(frames_ok, "every colour has every state animation, in its own 2048x2048 frames")
	_check(sides_ok, "every colour's left and right poses use different frames")
	_check(timing_ok, "every colour's poses share frame count, loop flag and speed")
	# Settling onto the floor is itself a landing, so idle only resumes once it has played out.
	_put_actor_feet(Vector2(736.0, FLOOR_Y))
	_check(await _await_anim(&"idle") == &"idle", "standing still plays idle")
	_key(KEY_D, true)
	_check(await _anim_after(10) == &"run_right", "moving right plays run_right")
	_key(KEY_D, false)
	_key(KEY_A, true)
	_check(await _anim_after(12) == &"run_left", "moving left plays run_left")
	_key(KEY_A, false)
	await _frames(10)

	# Sneak: the one-shot intro, then the hold, then the stand-up on release.
	_key(KEY_S, true)
	_check(await _anim_after(3) == &"sneak", "pressing down plays sneak")
	_check(await _await_anim(&"sneak_hold") == &"sneak_hold", "holding down plays sneak_hold after")
	_key(KEY_S, false)
	_check(await _anim_after(3) == &"sneak_stand", "releasing down plays sneak_stand")
	_check(await _await_anim(&"idle") == &"idle", "idle resumes once sneak_stand has played")

	# Jump: rise, fall, land. The landing pose always follows touching the ground.
	_key(KEY_W, true)
	_check(await _anim_after(3) == &"jump", "jumping plays jump")
	_key(KEY_W, false)
	_check(await _await_anim(&"jump_falling") == &"jump_falling", "falling plays jump_falling after")
	_check(
		await _await_anim(&"jump_landing") == &"jump_landing", "hitting the ground plays jump_landing"
	)
	_check(
		await _await_anim(&"idle") == &"idle", "idle resumes once jump_landing has played"
	)

	# The same arc moving right picks the directional variants. Rising follows the key; falling
	# and landing follow the motion, so they stay right after the key is let go (no air drag).
	_key(KEY_D, true)
	_key(KEY_W, true)
	_check(await _anim_after(3) == &"jump_right", "jumping with right held plays jump_right")
	_key(KEY_W, false)
	_key(KEY_D, false)
	_check(
		await _await_anim(&"jump_right_falling") == &"jump_right_falling",
		"falling while moving right, key released, plays jump_right_falling"
	)
	_check(
		await _await_anim(&"jump_right_landing") == &"jump_right_landing",
		"landing while moving right, key released, plays jump_right_landing"
	)
	_check(await _await_anim(&"idle") == &"idle", "idle resumes after the directional landing")

	# Glide: holding jump while falling, with and without a direction.
	_put_actor_feet(Vector2(736.0, 300.0))
	_key(KEY_A, true)
	await _frames(12)
	_key(KEY_W, true)
	_check(await _anim_after(4) == &"jump_left_gliding", "gliding left plays jump_left_gliding")
	_key(KEY_A, false)
	_check(
		await _anim_after(3) == &"jump_left_gliding",
		"letting go of left while still drifting left keeps jump_left_gliding"
	)
	_key(KEY_W, false)
	_check(
		await _await_anim(&"jump_left_landing", 150) == &"jump_left_landing",
		"the drifting chicken lands with jump_left_landing"
	)
	_check(await _await_anim(&"idle") == &"idle", "idle resumes after the glide lands")
	_put_actor_feet(Vector2(736.0, 300.0))
	await _frames(12)
	_key(KEY_W, true)
	_check(
		await _anim_after(4) == &"jump_gliding", "gliding straight down plays jump_gliding"
	)
	_key(KEY_W, false)
	_check(
		await _await_anim(&"idle", 120) == &"idle", "idle resumes after the straight glide lands"
	)
	var ids := _arrange([[SOLID, Vector2i(23, 9), 1]])
	_put_actor_feet(Vector2(1472.0 - room.tuning.body_width_wu * 0.5 - 0.1, 640.0))
	_check(await _anim_after(4) == &"wall_slide_right", "wall on the right plays wall_slide_right")
	_put_actor_feet(Vector2(1536.0 + room.tuning.body_width_wu * 0.5 + 0.1, 640.0))
	_check(await _anim_after(4) == &"wall_slide_left", "wall on the left plays wall_slide_left")
	_check(
		sprite.offset == sprite.animation_offsets.get(&"wall_slide_left", Vector2.ZERO),
		"each animation applies its feet offset"
	)
	_check(ids.size() == 1, "wall fixture placed")
	room.items.reset_match()


# ---------------------------------------------------------------- grid and tiles


func _test_grid_and_tiles() -> void:
	var tuning := room.tuning
	_check(tuning.grid_cell_wu == 64.0, "stage grid is 64 wu per tile")
	_check(
		(
			tuning.body_width_wu <= tuning.grid_cell_wu
			and tuning.body_height_wu <= 2.0 * tuning.grid_cell_wu
		),
		(
			"chicken body (%sx%s) fits a 1x2-tile clearance"
			% [tuning.body_width_wu, tuning.body_height_wu]
		)
	)
	_check(
		(
			GameplayTuning.legacy_32_wu().grid_cell_wu == 32.0
			and GameplayTuning.legacy_32_wu().validate().is_empty()
		),
		"legacy 32 wu fixture profile is derived from the current defaults and validates"
	)
	var tiles := room.stage_tiles
	_check(
		tiles != null and tiles.tile_set != null and tiles.tile_set.tile_size == Vector2i(64, 64),
		"stage uses a TileMapLayer with 64x64 tiles"
	)
	if tiles == null:
		return
	var expected := 0
	for spec in room.arena.surface_specs:
		var rect: Rect2 = spec.rect
		expected += roundi(rect.size.x / 64.0) * roundi(rect.size.y / 64.0)
	_check(
		tiles.get_used_cells().size() == expected,
		"every arena surface cell is painted (%d tiles)" % tiles.get_used_cells().size()
	)
	# Containment was removed on 2026-10-22, so cell (-1, 0) is empty: there is no boundary tile to
	# paint any more. The floor and base platform must still read as different surfaces.
	_check(
		(
			tiles.get_cell_atlas_coords(Vector2i(0, 15)) == StageTileLayer.TILE_GROUND
			and tiles.get_cell_atlas_coords(Vector2i(6, 13)) == StageTileLayer.TILE_PLATFORM
			and tiles.get_cell_atlas_coords(Vector2i(-1, 0)) == Vector2i(-1, -1)
		),
		"floor and base platform use distinct tiles, and no containment is painted"
	)
	_check(
		tiles.map_to_local(Vector2i(6, 13)) == Vector2(6.5, 13.5) * 64.0,
		"tile cells line up with ArenaDefinition world coordinates"
	)


func _test_block_scene_authoring() -> void:
	for key in BLOCK_SCENES:
		var found := room.definitions.find_variant(key)
		var variant := found.variant as ItemVariantDefinition
		var scene := load(BLOCK_SCENES[key]) as PackedScene
		var node := scene.instantiate()
		var collision := node.get_node_or_null("Solid") as CollisionShape2D
		var visual := node.get_node_or_null("Visual")
		var authored := (
			(collision.shape as RectangleShape2D).size if collision != null else Vector2.ZERO
		)
		_check(
			(
				authored == Vector2(variant.footprint_cells) * room.tuning.grid_cell_wu
				and visual != null
			),
			(
				"%s scene authors a %s collision matching its %s footprint"
				% [key, authored, variant.footprint_cells]
			)
		)
		node.free()


# ---------------------------------------------------------------- controls


func _test_controls() -> void:
	var router := room.input_router
	_release_all()
	router.set_phase(LocalInputRouter.Phase.PLACE)
	_key(KEY_W, true)
	_check(
		router.is_action_held(seat, "up") and not router.is_action_held(seat, "jump"),
		"W is 'up' during Place"
	)
	_key(KEY_W, false)
	router.set_phase(LocalInputRouter.Phase.PLAY)
	_key(KEY_W, true)
	_check(router.is_action_held(seat, "jump"), "W is jump during Play")
	_key(KEY_W, false)
	_key(KEY_S, true)
	_check(router.is_action_held(seat, "down"), "S is sneak (down) during Play")
	_key(KEY_S, false)
	# Drop the unconsumed mapping-check presses so they cannot trigger a later jump.
	router.clear_input_state()
	room.items.reset_match()
	room.items.begin_play()
	# Column 11 (x 704..768) is open to the arena ceiling.
	_put_actor_feet(Vector2(736.0, FLOOR_Y))
	await _frames(10)
	_key(KEY_W, true)
	var highest := _feet_y()
	for _frame in range(30):
		await physics_frame
		highest = minf(highest, _feet_y())
	_key(KEY_W, false)
	_check(
		FLOOR_Y - highest > room.tuning.jump_height_wu * 0.8,
		"a W press jumps (rise %.1f wu of %.0f)" % [FLOOR_Y - highest, room.tuning.jump_height_wu]
	)
	await _frames(60)


# ---------------------------------------------------------------- sneak


func _test_sneak() -> void:
	room.items.reset_match()
	room.items.begin_play()
	_put_actor_feet(Vector2(1000.0, FLOOR_Y))
	await _frames(10)
	_key(KEY_S, true)
	await _frames(3)
	var shape := _body_shape()
	var rect := shape.shape as RectangleShape2D
	var shape_bottom := actor.global_position.y + shape.position.y + rect.size.y * 0.5
	_check(
		(
			actor.sneaking
			and rect.size == Vector2(room.tuning.body_width_wu, room.tuning.sneak_height_wu)
		),
		"holding S on the floor shrinks the body to %s" % rect.size
	)
	_check(absf(shape_bottom - FLOOR_Y) <= TOLERANCE, "sneaking keeps the feet on the floor")
	var x_before := actor.global_position.x
	_key(KEY_D, true)
	await _frames(20)
	_check(
		absf(actor.global_position.x - x_before) <= 0.5 and actor.locomotion_velocity.x == 0.0,
		"a sneaking chicken cannot walk"
	)
	_key(KEY_D, false)
	_key(KEY_W, true)
	await _frames(12)
	_key(KEY_W, false)
	_check(
		actor.is_on_floor() and absf(_feet_y() - FLOOR_Y) <= TOLERANCE,
		"a sneaking chicken cannot jump"
	)
	_key(KEY_S, false)
	await _frames(2)
	# Re-read: standing up swaps which hitbox is enabled, it does not resize the sneak one.
	var standing_rect := _body_shape().shape as RectangleShape2D
	_check(
		not actor.sneaking and standing_rect.size.y == room.tuning.body_height_wu,
		"releasing S in open space stands back up"
	)
	_put_actor_feet(Vector2(736.0, 400.0))
	await _frames(2)
	_key(KEY_S, true)
	await _frames(3)
	_check(not actor.sneaking, "sneak only starts while grounded")
	_key(KEY_S, false)
	await _frames(40)


func _test_sneak_headroom() -> void:
	# Solid slab at row 13 leaves a one-tile gap (y 896..960) above the floor.
	var ids := _arrange([[SOLID, Vector2i(15, 13)]])
	_put_actor_feet(Vector2(700.0, FLOOR_Y))
	await _frames(10)
	_key(KEY_S, true)
	await _frames(3)
	_put_actor_feet(Vector2(1056.0, FLOOR_Y))
	await _frames(5)
	_key(KEY_S, false)
	await _frames(5)
	_check(
		actor.sneaking and absf(_feet_y() - FLOOR_Y) <= TOLERANCE,
		"a sneaking chicken under a one-tile ceiling stays small instead of clipping"
	)
	room.items.remove(ids[0], "test", true)
	await _frames(3)
	_check(not actor.sneaking, "it stands up as soon as the headroom is clear")
	room.items.reset_match()
	room.items.begin_play()


# ---------------------------------------------------------------- glide


func _test_glide() -> void:
	room.items.reset_match()
	room.items.begin_play()
	var cap := room.tuning.glide_fall_cap_wu_s
	_put_actor_feet(Vector2(1480.0, 200.0))
	await _frames(30)
	var free_fall := actor.locomotion_velocity.y
	_check(
		free_fall > cap * 2.0 and not actor.gliding,
		"without W a chicken falls fast (%.0f)" % free_fall
	)
	_put_actor_feet(Vector2(1480.0, 200.0))
	_key(KEY_W, true)
	var max_speed := 0.0
	var glided := false
	for _frame in range(40):
		await physics_frame
		max_speed = maxf(max_speed, actor.locomotion_velocity.y)
		glided = glided or actor.gliding
	_check(
		glided and max_speed <= cap + 0.5,
		"holding W while falling glides at <= %.0f wu/s (max %.1f)" % [cap, max_speed]
	)
	var x_before := actor.global_position.x
	_key(KEY_A, true)
	await _frames(10)
	_key(KEY_A, false)
	_check(actor.global_position.x < x_before - 20.0, "air steering still works while gliding")
	_key(KEY_W, false)
	await _frames(2)
	_check(not actor.gliding, "releasing W ends the glide")
	await _frames(60)
	# Wall slide wins over glide on an eligible wall (held W, no fresh press at the wall).
	_arrange([[SOLID, Vector2i(23, 9), 1]])
	_put_actor_feet(Vector2(1300.0, 300.0))
	_key(KEY_W, true)
	await _frames(12)
	_put_actor_feet(Vector2(1536.0 + room.tuning.body_width_wu * 0.5 + 0.1, 640.0))
	await _frames(6)
	_check(
		(
			actor.wall_sliding
			and not actor.gliding
			and absf(actor.locomotion_velocity.y - room.tuning.wall_slide_fall_cap_wu_s) <= 0.5
		),
		"wall slide (not glide) applies on a wall while W is held"
	)
	_key(KEY_W, false)
	await _frames(60)


# ---------------------------------------------------------------- blocks


func _test_solid_block() -> void:
	var ids := _arrange([[SOLID, Vector2i(14, 8)], [SOLID, Vector2i(20, 6), 1]])
	var flat := room.items.node_for(ids[0])
	var upright := room.items.node_for(ids[1])
	var flat_rect: Rect2 = flat.call("footprint_world_rect")
	var upright_rect: Rect2 = upright.call("footprint_world_rect")
	_check(
		flat is StageBlock and flat_rect.size == Vector2(192.0, 64.0), "solid block is 3x1 (192x64)"
	)
	_check(upright_rect.size == Vector2(64.0, 192.0), "R rotates the solid block to 1x3 (64x192)")
	_check(
		(
			is_equal_approx((upright.get_node("Visual") as Node2D).rotation, PI * 0.5)
			and upright.position == upright_rect.position
		),
		"rotated block sits on its footprint and its Visual is turned 90 degrees"
	)
	var metadata := room.support_tracker.surfaces[ids[0]] as SupportSurfaceMetadata
	_check(
		metadata.wall_movement_eligibility == SupportSurfaceMetadata.Eligibility.ELIGIBLE,
		"solid block sides are wall-slide eligible"
	)
	_put_actor_feet(Vector2(flat_rect.get_center().x, flat_rect.position.y - 100.0))
	await _frames(40)
	var position_before := flat.position
	_check(
		actor.is_on_floor() and absf(_feet_y() - flat_rect.position.y) <= TOLERANCE,
		"a chicken stands on the solid block"
	)
	_check(flat.position == position_before, "solid block has no gravity")
	room.items.reset_match()


func _test_wood_box() -> void:
	# Placed one cell above the floor under Base B; it falls once Play starts.
	var ids := _arrange([[BOX, Vector2i(14, 12)]])
	var box := room.items.node_for(ids[0]) as StageBlock
	var start := box.position
	_check(
		box != null and box.footprint_world_rect().size == Vector2(128.0, 128.0), "wood box is 2x2"
	)
	await _frames(60)
	_check(
		box.is_on_ground() and absf(box.position.y + 128.0 - FLOOR_Y) <= TOLERANCE,
		(
			"wood box falls under gravity and lands on the floor (bottom y=%.1f)"
			% (box.position.y + 128.0)
		)
	)
	var box_right := box.position.x + 128.0
	_put_actor_feet(Vector2(box_right + room.tuning.body_width_wu * 0.5 + 1.0, FLOOR_Y))
	await _frames(5)
	var box_x := box.position.x
	_key(KEY_A, true)
	await _frames(45)
	_key(KEY_A, false)
	var moved := box_x - box.position.x
	_check(moved > 40.0, "a grounded chicken walking into the box pushes it (%.1f wu)" % moved)
	_check(
		actor.global_position.x > box.position.x + 128.0 - 0.5,
		"the chicken never passes through the box"
	)
	await _frames(30)
	var rest_x := box.position.x
	await _frames(10)
	_check(absf(box.position.x - rest_x) <= 0.5, "friction stops the box when the push ends")
	# Step clear of the placed spot so the reset box does not land on this chicken.
	_put_actor_feet(Vector2(736.0, FLOOR_Y))
	room.items.enter_place()
	_check(
		box.position == start and not box.active,
		"entering Place returns the box to its placed spot and freezes it"
	)
	await _frames(10)
	_check(box.position == start, "the box stays put during Place")
	room.items.begin_play()
	await _frames(60)
	_check(box.is_on_ground(), "the next Play start drops the box again from its placed spot")
	# Open sky between Base C and Base D: stand on top of a landed box.
	ids = _arrange([[BOX, Vector2i(22, 12)]])
	box = room.items.node_for(ids[0]) as StageBlock
	await _frames(30)
	_put_actor_feet(Vector2(box.position.x + 64.0, box.position.y - 60.0))
	await _frames(30)
	_check(
		actor.is_on_floor() and absf(_feet_y() - box.position.y) <= TOLERANCE,
		"a chicken can stand on the box"
	)
	room.items.reset_match()


func _test_collapsing_block() -> void:
	var ids := _arrange([[COLLAPSE, Vector2i(22, 11)]])
	var block := room.items.node_for(ids[0]) as StageBlock
	var top := block.footprint_world_rect().position.y
	_check(
		block != null and block.footprint_world_rect().size == Vector2(64.0, 64.0),
		"collapsing block is 1x1"
	)
	_put_actor_feet(Vector2(1440.0, top - 80.0))
	var landed := false
	for _frame in range(30):
		await physics_frame
		if block.collapse_state == StageBlock.CollapseState.CRUMBLING:
			landed = actor.is_on_floor() and absf(_feet_y() - top) <= TOLERANCE
			break
	_check(landed, "standing on the collapsing block starts its timer")
	var crumble_frames := 0
	while block.collapse_state == StageBlock.CollapseState.CRUMBLING and crumble_frames < 400:
		await physics_frame
		crumble_frames += 1
	var expected_crumble := roundi(room.tuning.block_collapse_delay_s * 60.0)
	_check(
		(
			absi(crumble_frames - expected_crumble) <= 2
			and block.collapse_state == StageBlock.CollapseState.GONE
			and _block_shapes(block)[0].disabled
		),
		(
			"it loses collision %d frames (%.2f s) after contact"
			% [crumble_frames, crumble_frames / 60.0]
		)
	)
	var gone_frames := 0
	var fell := false
	while block.collapse_state == StageBlock.CollapseState.GONE and gone_frames < 600:
		await physics_frame
		gone_frames += 1
		fell = fell or _feet_y() > top + 100.0
	_check(fell, "the chicken falls through once it collapses")
	var expected_gone := roundi(room.tuning.block_collapse_respawn_s * 60.0)
	_check(
		(
			absi(gone_frames - expected_gone) <= 2
			and block.collapse_state == StageBlock.CollapseState.SOLID
		),
		"it respawns %d frames (%.2f s) after collapsing" % [gone_frames, gone_frames / 60.0]
	)
	# Wall-slide contact also starts the timer.
	ids = _arrange([[COLLAPSE, Vector2i(22, 9)]])
	block = room.items.node_for(ids[0]) as StageBlock
	var face := block.footprint_world_rect()
	# An airborne chicken is one tile tall at the feet (JumpHitbox), so a wall slide only catches
	# a wall beside that tile, not one up at the standing body's head. Start level with the
	# block's underside; feet at 700 would leave the compact body 4 wu clear of it.
	_put_actor_feet(Vector2(face.end.x + room.tuning.body_width_wu * 0.5 + 0.1, face.end.y))
	var slid := false
	for _frame in range(8):
		await physics_frame
		slid = slid or actor.wall_sliding
	_check(
		slid and block.collapse_state == StageBlock.CollapseState.CRUMBLING,
		"wall-sliding on the collapsing block starts its timer"
	)
	# Respawn waits while a chicken overlaps the footprint.
	await _frames(int(room.tuning.block_collapse_delay_s * 60.0) + 5)
	_check(
		block.collapse_state == StageBlock.CollapseState.GONE,
		"wall-slide contact collapses it after 2 s"
	)
	_put_actor_feet(
		Vector2(
			block.footprint_world_rect().get_center().x, block.footprint_world_rect().end.y + 20.0
		)
	)
	actor.set_opening_freeze(true)
	await _frames(int(room.tuning.block_collapse_respawn_s * 60.0) + 20)
	_check(
		block.collapse_state == StageBlock.CollapseState.GONE,
		"it does not respawn inside a chicken"
	)
	actor.set_opening_freeze(false)
	_put_actor_feet(Vector2(1000.0, FLOOR_Y))
	await _frames(5)
	_check(
		block.collapse_state == StageBlock.CollapseState.SOLID,
		"it respawns once the footprint is clear"
	)
	block.notify_chicken_contact(actor)
	room.items.enter_place()
	_check(
		block.collapse_state == StageBlock.CollapseState.SOLID and not block.active,
		"entering Place restores a crumbling block and freezes it"
	)
	room.items.reset_match()

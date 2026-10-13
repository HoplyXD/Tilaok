extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -600.0
const WALL_SLIDING_SPEED = 1200

var GRAVITY = ProjectSettings.get_setting("physics/2d/default_gravity")
var JUMPS_MADE = 0
var DO_WALL_JUMP = false

func _physics_process(delta: float) -> void:
	var direction := Input.get_axis("player1left", "player1right")
	
	if is_on_wall_only(): velocity.y = WALL_SLIDING_SPEED * delta
	elif not is_on_floor(): velocity += get_gravity() * delta 
	else: JUMPS_MADE = 0
	
	if Input.is_action_just_pressed("player1jump"):
		if is_on_wall_only():
			velocity.x = -direction * SPEED
			velocity.y = JUMP_VELOCITY
			DO_WALL_JUMP= true
			$Timer.start()
		if is_on_floor() || JUMPS_MADE < 2:
			velocity.y = JUMP_VELOCITY
			JUMPS_MADE += 1
	if direction && not DO_WALL_JUMP: velocity.x = direction * SPEED
	elif not DO_WALL_JUMP: velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()


func _on_timer_timeout() -> void:
	DO_WALL_JUMP = false

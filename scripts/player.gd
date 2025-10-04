extends CharacterBody2D


const SPEED = 200.0
const JUMP_VELOCITY = -300.0
const DASH_SPEED=1000.0

@onready var player_sprite: Sprite2D = $Sprite2D
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var dash_timer: Timer = $DashTimer

var can_dash:bool = true

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction := Input.get_axis("move_left", "move_right")
	#反转人物
	if direction>0:
		player_sprite.flip_h = false
	elif direction < 0:
		player_sprite.flip_h = true

	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	dash_system()
	move_and_slide()
	
#冲刺系统
func dash_system():
	var dash_direction
	if player_sprite.flip_h:
		dash_direction=-1
	else:
		dash_direction=1

	if Input.is_action_just_pressed("dash") and can_dash:
		if not is_zero_approx(velocity.x):
			velocity.x = 0
		dash_timer.start()
		velocity.x = DASH_SPEED * dash_direction
		can_dash=false

func _on_dash_timer_timeout() -> void:
	can_dash = true

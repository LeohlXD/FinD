extends CharacterBody2D


const SPEED = 200.0
const JUMP_VELOCITY = -300.0
const DASH_SPEED:Vector2=Vector2(1000,250)

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
	var dash_direction:=Vector2(0,-1)
	var jump_force=0
	if player_sprite.flip_h:
		dash_direction.x = -1
	else:
		dash_direction.x = 1

	if Input.is_action_just_pressed("dash") and can_dash:
		velocity = Vector2.ZERO
		dash_timer.start()
		if Input.is_action_pressed("jump"):
			jump_force = DASH_SPEED.y*dash_direction.y
		velocity = Vector2(DASH_SPEED.x * dash_direction.x,jump_force)
		can_dash=false
		for i in range(10):
			await get_tree().create_timer(0.05).timeout
			trail_system()

func trail_system():
	var trail = preload("res://scenes/trail.tscn").instantiate()
	get_parent().add_child(trail)
	get_parent().move_child(trail,get_index())
	var properties = [
		"hframes",
		"vframes",
		"frame",
		"texture",
		"global_position",
		"flip_h"
	]
	for trail_properties in properties:
		trail.set(trail_properties,player_sprite.get(trail_properties))
	

func _on_dash_timer_timeout() -> void:
	can_dash = true

	

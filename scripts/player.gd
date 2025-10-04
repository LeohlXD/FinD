
extends CharacterBody2D

const SPEED = 150.0
const JUMP_VELOCITY = -300.0
const DASH_SPEED: Vector2 = Vector2(500, 250)

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var dash_timer: Timer = $DashTimer

var can_dash: bool = true
var dash_direction: int = 1  # 1表示右，-1表示左

# 状态机
enum PlayerState { 
	IDLE,
	RUN,
	JUMP,
	FALL,
	DASH 
}
var current_state: PlayerState = PlayerState.IDLE
var previous_state: PlayerState = PlayerState.IDLE

func _ready() -> void:
	change_state(PlayerState.IDLE)

func _physics_process(delta: float) -> void:
	match current_state:
		PlayerState.IDLE:
			handle_idle_state(delta)
		PlayerState.RUN:
			handle_run_state(delta)
		PlayerState.JUMP:
			handle_jump_state(delta)
		PlayerState.FALL:
			handle_fall_state(delta)
		PlayerState.DASH:
			handle_dash_state(delta)
	
	move_and_slide()
	update_animation()

func change_state(new_state: PlayerState) -> void:
	previous_state = current_state
	current_state = new_state
	
	# 进入新状态时的处理
	match new_state:
		PlayerState.DASH:
			start_dash()

func handle_idle_state(delta: float) -> void:
	apply_gravity(delta)
	handle_jump_input()
	handle_movement_input()
	
	if not is_on_floor():
		if velocity.y < 0:
			change_state(PlayerState.JUMP)
		else:
			change_state(PlayerState.FALL)
	elif Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right"):
		change_state(PlayerState.RUN)
	
	handle_dash_input()

func handle_run_state(delta: float) -> void:
	apply_gravity(delta)
	handle_jump_input()
	handle_movement_input()
	
	if not is_on_floor():
		if velocity.y < 0:
			change_state(PlayerState.JUMP)
		else:
			change_state(PlayerState.FALL)
	elif velocity.x == 0:
		change_state(PlayerState.IDLE)
	
	handle_dash_input()

func handle_jump_state(delta: float) -> void:
	apply_gravity(delta)
	handle_movement_input()
	
	if velocity.y >= 0:
		change_state(PlayerState.FALL)
	elif is_on_floor():
		if velocity.x == 0:
			change_state(PlayerState.IDLE)
		else:
			change_state(PlayerState.RUN)
	
	handle_dash_input()

func handle_fall_state(delta: float) -> void:
	apply_gravity(delta)
	handle_movement_input()
	
	if is_on_floor():
		if velocity.x == 0:
			change_state(PlayerState.IDLE)
		else:
			change_state(PlayerState.RUN)
	elif velocity.y < 0:
		change_state(PlayerState.JUMP)
	
	handle_dash_input()

func handle_dash_state(delta: float) -> void:
	# 冲刺状态下也应用重力
	apply_gravity(delta)
	
	# 保持冲刺方向
	velocity.x = DASH_SPEED.x * dash_direction
	
	if dash_timer.is_stopped():
		if is_on_floor():
			if velocity.x == 0:
				change_state(PlayerState.IDLE)
			else:
				change_state(PlayerState.RUN)
		else:
			if velocity.y < 0:
				change_state(PlayerState.JUMP)
			else:
				change_state(PlayerState.FALL)

func apply_gravity(delta: float) -> void:
	if not is_on_floor() or current_state == PlayerState.DASH:
		velocity += get_gravity() * delta

func handle_jump_input() -> void:
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		change_state(PlayerState.JUMP)

func handle_movement_input() -> void:
	var direction := Input.get_axis("move_left", "move_right")
	
	# 更新角色朝向
	if direction != 0:
		update_character_direction(direction)

	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

func update_character_direction(direction: float) -> void:
	# 更新动画的方向
	if direction > 0:
		anim.flip_h = false
		dash_direction = 1
	elif direction < 0:
		anim.flip_h = true
		dash_direction = -1

func handle_dash_input() -> void:
	if Input.is_action_just_pressed("dash") and can_dash:
		change_state(PlayerState.DASH)

func start_dash() -> void:
	var jump_force = 0
	
	# 使用当前的方向进行冲刺
	if anim.flip_h:
		dash_direction = -1
	else:
		dash_direction = 1

	velocity = Vector2.ZERO
	dash_timer.start()
	
	# 如果在冲刺时按下跳跃，给予向上的冲力
	if Input.is_action_pressed("jump"):
		jump_force = DASH_SPEED.y * -1  # 向上冲刺
	
	velocity = Vector2(DASH_SPEED.x * dash_direction, jump_force)
	can_dash = false
	
	# 创建残影效果
	create_dash_trails()

func create_dash_trails() -> void:
	for i in range(10):
		await get_tree().create_timer(0.05).timeout
		if current_state == PlayerState.DASH:  # 确保仍在冲刺状态
			trail_system()

func trail_system():
	var trail = preload("res://scenes/trail.tscn").instantiate()
	get_parent().add_child(trail)
	get_parent().move_child(trail, get_index())
	
	# 设置残影的位置和基本属性
	trail.global_position = anim.global_position
	trail.flip_h = anim.flip_h
	
	# 如果是AnimatedSprite2D残影
	if trail is AnimatedSprite2D:
		trail.sprite_frames = anim.sprite_frames
		trail.animation = anim.animation
		trail.frame = anim.frame
		# trail.modulate = Color(1, 1, 1, 0.5)  # 半透明效果
	# 如果是Sprite2D残影
	elif trail is Sprite2D:
		# 获取当前动画的纹理
		var current_sprite = anim.sprite_frames.get_frame_texture(anim.animation, anim.frame)
		trail.texture = current_sprite
		# trail.modulate = Color(1, 1, 1, 0.5)  # 半透明效果

func update_animation() -> void:
	match current_state:
		PlayerState.IDLE:
			anim.play("idle")
		PlayerState.RUN:
			anim.play("run")
		PlayerState.JUMP:
			anim.play("jump")
		PlayerState.FALL:
			anim.play("fall")
		PlayerState.DASH:
			anim.play("dash")

func _on_dash_timer_timeout() -> void:
	can_dash = true

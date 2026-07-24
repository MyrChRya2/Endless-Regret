class_name PlayerStateRun extends PlayerState


@export var base_friction: float = 1200.0


func  init() -> void:
	pass
	
	
# 进入 state 时会发生什么？
func enter() -> void:
	print("enter ", name)
	pass
	
	
# 退出 state 时会发生什么？
func exit() -> void:
	print("exit ", name)
	pass
	
	
# 按下 input 时会发生什么？
func handle_input(_event:InputEvent) -> PlayerState:
	return null
	
	
# 在 state 中 每个 process tick 会发生什么？
func process(_delta: float) -> PlayerState:
	return null
	
# 在 state 中 每个 phusics process tick 会发生什么？
func physics_process(_delta: float) -> PlayerState:
	var move_direction = Input.get_axis("move_left", "move_right")
	var current_speed = player._get_effective_move_speed()
	
	if move_direction !=0:
		player.velocity.x = move_direction * current_speed
	else:
		if player.is_on_floor():
			var effective_friction = base_friction * player.DEFAULT_FRICTION_MULTIPLIER
			player.velocity.x = move_toward(player.velocity.x, 0.0, effective_friction * _delta)
	
	# 按跳跃 → 切到 Jump
	if Input.is_action_just_pressed("jump"):
		return get_node("../Jump")
	
	# 松手 → 切回 Idle
	if move_direction == 0 and player.is_on_floor() and abs(player.velocity.x) < 1.0:
		return get_node("../Idle")
	
	
	return null

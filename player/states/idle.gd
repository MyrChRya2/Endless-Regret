class_name PlayerStateIdle extends PlayerState


func  init() -> void:
	pass
	
	
# 进入 state 时会发生什么？
func enter() -> void:
	player.velocity.x = 0
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
	if Input.is_action_just_pressed("jump"):
		return get_node("../Jump")
	if Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("move_right"):
		return get_node("../Run")
	return null

class_name PlayerStateRun extends PlayerState


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
	
	return next_state
	
	
# 在 state 中 每个 process tick 会发生什么？
func process(_delta: float) -> PlayerState:
	return next_state
	
# 在 state 中 每个 phusics process tick 会发生什么？
func physics_process(_delta: float) -> PlayerState:
	var move_input := Input.get_axis("move_left", "move_right")
	player.velocity.x = move_input * player._get_effective_move_speed()
	
	if move_input == 0:
		return get_node("../Idle")
		
	if Input.is_action_just_pressed("jump"):
		return get_node("../Jump")
	
	return null

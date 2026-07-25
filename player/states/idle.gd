class_name PlayerStateIdle extends PlayerState

func enter() -> void:
	player.is_falling_off_ledge = false
	player.can_coyote_jump = true
	
	
# 在 state 中 每个 phusics process tick 会发生什么？
func physics_process(_delta: float) -> PlayerState:
	if Input.is_action_just_pressed("jump"):
		return get_node("../Jump")
		
	if Input.get_axis("move_left", "move_right") != 0:
		return get_node("../Run")
		
	if not player.is_on_floor() and player.velocity.y >=0:
		player.is_falling_off_ledge = true
		return get_node("../Fall")
		
	return null

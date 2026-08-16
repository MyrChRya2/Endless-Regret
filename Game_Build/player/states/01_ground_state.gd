class_name GroundState extends PlayerState


# 地面通用逻辑
func physics_process(_delta: float) -> PlayerState:
	# 通用跳跃检测
	if Input.is_action_just_pressed("jump"):
		player.current_jump_type = "Ground Jump"
		player.can_coyote_jump = false
		player._handle_jump()
		player.current_jump_type = player.JumpType.GROUND
		return player.get_state("Airborne")
		
	# 通用边缘掉落检测
	if not player.is_on_floor() and  player.velocity.y >= 0:
		player.is_falling_off_ledge = true
		return player.get_state("Airborne")
		
	return null

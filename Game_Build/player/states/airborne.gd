class_name PlayerStateAirborne extends PlayerState


func enter() -> void:
	if player.is_on_floor() and player.velocity.y >= 0:
		player.can_coyote_jump = false
		
	player.is_falling_off_ledge = false
	player.jump_buffer_timer = 0.0
	

func physics_process(_delta: float) -> PlayerState:
	# 空中水平移动
	player._handle_air_move(_delta, Input.get_axis("move_left", "move_right"))
	
	player.update_air_animation()
	
	# 跳跃截断
	if Input.is_action_just_released("jump") and player.velocity.y < 0:
		player.velocity.y *= player.jump_cut_multiplier
		
	# 多段跳
	if Input.is_action_just_pressed("jump"):
		# 优先计算墙跳
		if player.is_on_wall() and not player.is_on_floor():
			return player.get_state("Wall/WallJump")
		
		# 土狼跳
		if player.can_coyote_jump:
			player.can_coyote_jump = false
			player.current_jump_type = player.JumpType.COYOTE
			player._handle_jump()
			return null
			
		# 常规多段跳
		if player.remaining_air_jumps > 0:
			player.remaining_air_jumps -=1
			player.current_jump_type = player.JumpType.AIR
			player._handle_jump()
			return null
			
		# 重置预输入倒计时
		player.jump_buffer_timer = player.jump_buffer_time
		
	# 贴墙检测（优先于其他切换）
	if player.is_on_wall() and not player.is_on_floor() and player.velocity.y >= 0:
		var move_dir = Input.get_axis("move_left", "move_right")
		var wall_normal = player.get_wall_normal()
		if wall_normal != Vector2.ZERO:
			var wall_dir = -sign(wall_normal.x)
			if sign(move_dir) == wall_dir:
				return player.get_state("Wall/WallGrab")
				
	# 落地检测
	if player.is_on_floor() and player.velocity.y >= 0:
		# 落地前预输入，暂时先设为跳跃，即重回Airborn
		if player.jump_buffer_timer > 0:
			player.jump_buffer_timer = 0
			player.current_jump_type = player.JumpType.GROUND
			player._handle_jump()
			player.can_coyote_jump = false
			return null
			
		# 落地后进入哪个状态
		if Input.get_axis("move_left", "move_right") and abs(player.velocity.x) > 10.0:
			return player.get_state("Run")
		return player.get_state("Idle")
		
	# 预输入倒计时启动
	if player.jump_buffer_timer > 0:
		player.jump_buffer_timer = max(0, player.jump_buffer_timer - _delta)
		
	DebugManager.set_value("jump_buffer_timer", player.jump_buffer_timer)
	return null

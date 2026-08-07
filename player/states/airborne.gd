class_name PlayerStateAirborne extends PlayerState


func enter() -> void:
	if player.is_on_floor() and player.velocity.y >= 0:
		player._handle_jump()
		player.can_coyote_jump = false
		
	player.is_falling_off_ledge = false


func physics_process(_delta: float) -> PlayerState:
	# 空中水平移动
	player._handle_air_move(_delta, Input.get_axis("move_left", "move_right"))
	
	player.update_air_animation()
	
	# 跳跃截断
	if Input.is_action_just_released("jump") and player.velocity.y < 0:
		player.velocity.y *= player.jump_cut_multiplier
		
	# 多段跳
	if Input.is_action_just_pressed("jump"):
		# 优先计算土狼跳
		if player.can_coyote_jump:
			player.can_coyote_jump = false
			player._handle_jump()
			return null
			
		# 常规多段跳
		if player.remaining_air_jumps > 0:
			player.remaining_air_jumps -=1
			player._handle_jump()
			return null
			
		# 重置预输入倒计时
		player.jump_buffer_timer = player.jump_buffer_time
		
	# 贴墙检测（优先于其他切换）
	if player.is_on_wall() and not player.is_on_floor():
		return player.get_state("Wall")
	# 落地检测
	if player.is_on_floor() and player.velocity.y >= 0:
		# 落地前预输入，暂时先设为跳跃，即重回Airborn
		if player.jump_buffer_timer > 0:
			player.jump_buffer_timer = 0
			player._handle_jump()
			player.can_coyote_jump = false
			return null
			
		# 落地后进入哪个状态
		if Input.get_axis("move_left", "move_right") and abs(player.velocity.x) > 10.0:
			return get_node("../Run")
		return get_node("../Idle")
		
	# 预输入倒计时启动
	if player.jump_buffer_timer > 0:
		player.jump_buffer_timer = max(0, player.jump_buffer_timer - _delta)
		
	return null

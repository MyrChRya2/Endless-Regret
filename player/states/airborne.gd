class_name PlayerStateAirborne extends PlayerState


var _jumped_from_ground: bool


func enter() -> void:
	if player.is_on_floor():
		var jump_vel := sqrt(2 * player.gravity * player._get_effective_jump_height())
		player.velocity.y = -jump_vel
		player.can_coyote_jump = false
		_jumped_from_ground = true
		
	else:
		_jumped_from_ground = false
		
	player.is_falling_off_ledge = false


func process(_delta: float) -> PlayerState:
	player.update_air_animation()
	return null
	
	
func physics_process(_delta: float) -> PlayerState:
	# 空中水平移动
	player.air_move(_delta)
	
	# 跳跃截断
	if Input.is_action_just_released("jump") and player.velocity.y < 0:
		player.velocity.y *= player.jump_cut_multiplier
		
	# 多段跳
	if Input.is_action_just_pressed("jump"):
		# 优先计算土狼跳
		if player.can_coyote_jump:
			player.can_coyote_jump = false
			var jump_vel := sqrt(2 * player.gravity * player._get_effective_jump_height())
			player.velocity.y = -jump_vel
			return null
		# 常规多段跳
		if player.remaining_air_jumps > 0:
			player.remaining_air_jumps -=1
			var jump_vel := sqrt(2 * player.gravity * player._get_effective_jump_height())
			player.velocity.y = -jump_vel
			return null
			
	# 跳跃预输入
	if Input.is_action_just_pressed("jump"):
		player.jump_buffer_timer = player.jump_buffer_time
	if player.jump_buffer_timer > 0:
		player.jump_buffer_timer = max(0, player.jump_buffer_timer - _delta)
		
	# 落地检测
	if player.is_on_floor() and player.velocity.y >= 0:
		# 落地前预输入，暂时先设为跳跃，即重回Airborn
		if player.jump_buffer_timer > 0:
			player.jump_buffer_timer = 0
			var jump_vel := sqrt(2 * player.gravity * player._get_effective_jump_height())
			player.velocity.y = -jump_vel
			player.can_coyote_jump = false
			return null
			
		player.velocity.y = 0
		
		# 落地后进入哪个状态
		if abs(player.velocity.x) > 10.0:
			if not Input.get_axis("move_left", "move_right"):
				return get_node("../Slide")
			else:
				return get_node("../Run")
		else:
			return get_node("../Idle")
			
	return null

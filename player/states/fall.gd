class_name PlayerStateFall extends PlayerState

func enter() -> void:
	if player.is_falling_off_ledge:
		player.can_coyote_jump = true
		player.is_falling_off_ledge = false
	else:
		player.can_coyote_jump = false
		
		
func process(_delta: float) -> PlayerState:
	player.play_anim("fall")
	
	return null
	
	
func  physics_process(_delta: float) -> PlayerState:
	# 空中水平物理
	var move_direction = Input.get_axis("move_left", "move_right")
	var target_speed = move_direction * player._get_effective_move_speed() * player.air_move_speed
	if move_direction != 0:
		player.velocity.x = move_toward(player.velocity.x, target_speed, player.air_acceleration * _delta)
	else:
		player.velocity.x = move_toward(player.velocity.x, 0.0, player.air_deceleration * _delta)
	
	if Input.is_action_just_pressed("jump"):
		if player.can_coyote_jump:
			player.jump_buffer_timer = 0
			return get_node("../Jump")
		if player.remaining_air_jumps > 0:
			player.jump_buffer_timer = 0
			return get_node("../AirJump")
		else:
			player.jump_buffer_timer = player.jump_buffer_time
			
	if player.jump_buffer_timer > 0:
		player.jump_buffer_timer = max(0, player.jump_buffer_timer - _delta)
		
	# 落地检测
	if player.velocity.y >= 0 and player.is_on_floor():
		if player.jump_buffer_timer > 0:
			player.jump_buffer_timer = 0
			return get_node("../Jump")
			
		if Input.is_action_pressed("jump"):
			return get_node("../FatigueJump")
		
		if abs(player.velocity.x) > 10.0:
			return get_node("../Slide")
		else:
			return get_node("../Idle")
	
	return null

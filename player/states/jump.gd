class_name PlayerStateJump extends PlayerState

var is_grounded_jump: bool = false
	
# 进入 state 时会发生什么？
func enter() -> void:
	player.is_falling_off_ledge = false
	is_grounded_jump = player.is_on_floor()
	player.can_coyote_jump = false
	var jump_velocity := sqrt(2 * player.gravity * player._get_effective_jump_height())
	player.velocity.y = -jump_velocity
	
	
func process(_delta: float) -> PlayerState:
	player.play_anim("jump")
	
	return null
	
	
# 在 state 中 每个 phusics process tick 会发生什么？
func physics_process(_delta: float) -> PlayerState:
	# 跳跃截断
	if Input.is_action_just_released("jump") and player.velocity.y < 0:
		player.velocity.y *= player.jump_cut_multiplier
		
	# 空中水平物理
	var move_direction = Input.get_axis("move_left", "move_right")
	var target_speed = move_direction * player._get_effective_move_speed() * player.air_move_speed
	if move_direction != 0:
		player.velocity.x = move_toward(player.velocity.x, target_speed, player.air_acceleration * _delta)
	else:
		player.velocity.x = move_toward(player.velocity.x, 0.0, player.air_deceleration * _delta)
	
	# 多段跳
	if Input.is_action_just_pressed("jump") and  player.remaining_air_jumps > 0:
		return get_node("../AirJump")
		
	if player.velocity.y > 0:
		return get_node("../Fall")
	
	return null

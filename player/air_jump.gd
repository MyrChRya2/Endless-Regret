class_name PlayerStateAirJump extends PlayerState


@export var horizontial_reset_speed: float = 0.0


func enter() -> void:
	player.is_falling_off_ledge = false
	player.remaining_air_jumps -= 1
	var base_jump_velocity = sqrt(2 * player.gravity * player._get_effective_jump_height())
	player.velocity.y = -base_jump_velocity
	
	
func physics_process(_delta: float) -> PlayerState:
	if Input.is_action_just_released("jump") and player.velocity.y < 0:
		player.velocity.y *= player.jump_cut_multiplier
		
	var move_direction = Input.get_axis("move_left", "move_right")
	var target_speed = move_direction * player._get_effective_move_speed() * player.air_move_speed
	if move_direction != 0:
		player.velocity.x = move_toward(player.velocity.x, target_speed, player.air_acceleration * _delta)
	else:
		player.velocity.x = move_toward(player.velocity.x, 0.0, player.air_deceleration * _delta)
		
	if player.velocity.y > 0:
		return get_node("../Fall")
		
	return null

class_name PlayerStateFatigueJump extends PlayerState


@export var height_multiplier: float = 0.5
@export var horizontal_damp: float = 0.5

func enter() -> void:
	var full_jump_velocity = sqrt(2 * player.gravity * player._get_effective_jump_height())
	player.velocity.y = -full_jump_velocity * height_multiplier
	
	player.velocity.x *= horizontal_damp
	if abs(player.velocity.x) < 1.0:
		player.velocity.x = 0

func physics_process(_delta: float) -> PlayerState:
	# 空中水平物理
	var move_direction = Input.get_axis("move_left", "move_right")
	var target_speed = move_direction * player._get_effective_move_speed() * player.air_move_speed
	if move_direction != 0:
		player.velocity.x = move_toward(player.velocity.x, target_speed, player.air_acceleration * _delta)
	else:
		player.velocity.x = move_toward(player.velocity.x, 0.0, player.air_deceleration * _delta)
	
	if player.velocity.y > 0:
		return get_node("../Fall")
		
	return null

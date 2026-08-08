class_name WallJump extends WallState


func enter() -> void:
	player.reset_remaining_air_jump()
	player.current_jump_type = "Wall Jump"
	player._handle_jump()
	
	var wall_dir = get_wall_direction()
	if wall_dir != 0:
		player.velocity.x = -wall_dir * 300.0
		
	player.play_anim("wall_jump")
	
func physics_process(_delta: float) -> PlayerState:
	return player.get_state("Airborne")

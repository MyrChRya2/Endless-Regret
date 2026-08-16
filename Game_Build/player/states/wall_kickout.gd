class_name WallKickout extends WallState


func enter() -> void:
	player.remaining_air_jumps = 0
	
	var wall_dir = get_wall_direction()
	if wall_dir != 0:
		player.velocity.x = -wall_dir * 200.0
		
	
func physics_process(_delta: float) -> PlayerState:
	return player.get_state("Airborne")

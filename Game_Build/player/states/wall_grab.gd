class_name WallGrab extends WallState


var slide_speed: float = 20.0


func enter() -> void:
	player.velocity.x = 0
	player.play_anim("wall_grab")
	away_timer = 0.0
	hold_timer = 0.0
		
func physics_process(_delta: float) -> PlayerState:
	if player.is_on_floor():
		if abs(player.velocity.x) > 10.0:
			return player.get_state("Run")
		else:
			return player.get_state("Idle")
		
	player.velocity.x = 0
	
	player.velocity.y = min(player.velocity.y, slide_speed)
	if player.is_on_wall():
		if Input.is_action_just_pressed("jump"):
			return player.get_state("Wall/WallJump")
			
		if handle_hold_timer(_delta):
			return player.get_state("Wall/WallKickout")
				
		if handle_away_timer(_delta):
			return player.get_state("Airborne")
				
	else:
		return player.get_state("Airborne")
		
	return null

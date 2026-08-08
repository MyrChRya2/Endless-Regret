class_name WallClimb extends WallState


var climb_speed: float = 150.0
var climb_decel: float = 400.0
var climb_accel: float = 200.0 

enum ClimbPhase { ACCELERATING, DECELERATING }
var phase: ClimbPhase
var target_velocity_y: float


func enter() -> void:
	player.velocity.x = 0
	reset_timers()
	player.play_anim("wall_climb")
	player.gravity_enabled = false
	
	phase = ClimbPhase.ACCELERATING
	target_velocity_y = -climb_speed
	
	
func exit() -> void:
	player.gravity_enabled = true
	
	
func physics_process(_delta: float) -> PlayerState:
	player.velocity.x = 0
	
	if Input.is_action_pressed("move_up") and is_pressing_towards_wall():
		match phase:
			ClimbPhase.ACCELERATING:
				player.velocity.y = move_toward(player.velocity.y, target_velocity_y, climb_accel * _delta)
				if abs(player.velocity.y - target_velocity_y) < 1.0:
					phase = ClimbPhase.DECELERATING
					target_velocity_y = 0.0
			ClimbPhase.DECELERATING:
				player.velocity.y = move_toward(player.velocity.y, target_velocity_y, climb_decel * _delta)
				if abs(player.velocity.y) < 0.1:
					return player.get_state("Wall/WallKickout")
					
		if Input.is_action_just_pressed("jump"):
			return player.get_state("Wall/WallJump")
			
		if handle_hold_timer(_delta):
			return player.get_state("Wall/WallKickout")
			
		if handle_away_timer(_delta):
			return player.get_state("Wall/WallKickout")
			
	else:
		if player.is_on_wall():
			return player.get_state("Wall/WallGrab")
		else:
			return player.get_state("Airborne")
		
	if not player.is_on_wall():
		return player.get_state("Airborne")
	return null

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
	player.gravity_enabled = false
	
	if abs(player.velocity.y) > climb_speed:
		phase = ClimbPhase.DECELERATING
		target_velocity_y = 0.0
	else:
		phase = ClimbPhase.ACCELERATING
		target_velocity_y = -climb_speed
		
	var anim_name = "wall_climb" + ("_right" if player.facing == Player.FacingDir.RIGHT else "_left")
	if player.player_anim.sprite_frames.has_animation(anim_name):
		player.player_anim.play(anim_name)
		player.player_anim.frame = 0
		
		
func exit() -> void:
	player.gravity_enabled = true
	player.can_wall_climb = false
	
	
func physics_process(_delta: float) -> PlayerState:
	player.velocity.x = 0
	DebugManager.set_value("ClimbPhase", phase)
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
		
	return null
	
	
func _set_animation_frame(progress: float) -> void:
	var anim_name = "wall_climb" + ("_right" if player.facing == Player.FacingDir.RIGHT else "_left")
	var frames = player.player_anim.sprite_frames
	if not frames.has_animation(anim_name):
		return
	var frame_count = frames.get_frame_count(anim_name)
	if frame_count <= 0:
		return
		
	if player.player_anim.animation != anim_name:
		player.player_anim.play(anim_name)
		
	var frame_index = int(round(progress * (frame_count - 1)))
	player.player_anim.frame = frame_index

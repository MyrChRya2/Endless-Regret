class_name WallClimb extends WallState


var climb_speed: float = 150.0
var climb_decel: float = 400.0
var climb_accel: float = 200.0 

enum ClimbPhase { ACCELERATING, DECELERATING }
var phase: ClimbPhase
var target_velocity_y: float

var decel_start_vel: float
var total_integral: float
var current_integral: float = 0.0


func enter() -> void:
	player.velocity.x = 0
	reset_timers()
	player.gravity_enabled = false
	
	if abs(player.velocity.y) > climb_speed:
		phase = ClimbPhase.DECELERATING
		target_velocity_y = 0.0
		_init_deceleration()
	else:
		phase = ClimbPhase.ACCELERATING
		target_velocity_y = -climb_speed
		current_integral = 0.0
		
	var anim_name = "wall_climb" + ("_right" if player.last_facing == Player.FacingDir.RIGHT else "_left")
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
					_init_deceleration()
			ClimbPhase.DECELERATING:
				player.velocity.y = move_toward(player.velocity.y, target_velocity_y, climb_decel * _delta)
				current_integral += abs(player.velocity.y) * _delta
				var progress = clamp(current_integral / total_integral, 0.0, 1.0)
				_set_animation_frame(progress)
				
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


func _init_deceleration() -> void:
	decel_start_vel = player.velocity.y  # 负值
	var abs_vel = abs(decel_start_vel)
	total_integral = 0.5 * abs_vel * (abs_vel / climb_decel)
	current_integral = 0.0
	
	
func _set_animation_frame(progress: float) -> void:
	var anim_name = "wall_climb" + ("_right" if player.last_facing == Player.FacingDir.RIGHT else "_left")
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

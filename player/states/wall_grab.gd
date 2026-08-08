class_name WallGrab extends WallState


var slide_speed: float = 20.0
var climb_speed: float = 60.0
var exit_buffer: float = 0.0
const EXIT_BUFFER_TIME: float = 0.1

func enter() -> void:
	player.velocity.x = 0
	player.play_anim("wall_grab")
	exit_buffer = EXIT_BUFFER_TIME
	
	
func physics_process(_delta: float) -> PlayerState:
	if player.is_on_floor():
		if abs(player.velocity.x) > 10.0:
			return player.get_state("Run")
		else:
			return player.get_state("Idle")
	
	if not player.is_on_wall():
		exit_buffer -= _delta
		if exit_buffer <= 0:
			return player.get_state("Airborne")
	else:
		exit_buffer = EXIT_BUFFER_TIME
		
	player.velocity.x = 0
	
	player.velocity.y = move_toward(player.velocity.y, slide_speed, 10.0 * _delta)
	
	if Input.is_action_just_pressed("jump"):
		player.current_jump_type = "Wall Jump"
		player._handle_jump()
		
		var wall_dir = get_wall_direction()
		if wall_dir != 0:
			player.velocity.x = -wall_dir * 300.0
		return player.get_state("Airborne")
		
	if Input.is_action_pressed("move_up"):
		if is_pressing_towards_wall():
			player.velocity.y = move_toward(player.velocity.y, -climb_speed, 20.0 * _delta)
			
	if is_pressing_away_from_wall():
		return player.get_state("Airborne")
		
	return null

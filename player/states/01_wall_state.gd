class_name WallState extends PlayerState


@export var grab_buffer_time: float = 0.8
var grab_timer: float = 0.0

# 爬墙参数
@export var climb_speed: float = 60.0      # 爬墙垂直速度（像素/秒）
@export var climb_accel: float = 200.0     # 爬墙加速度

var is_climbing: bool = false              # 是否正在爬行

func enter() -> void:
	player.velocity.x = 0
	grab_timer = grab_buffer_time
	is_climbing = false
	player.play_anim("wall_grab")
	
func physics_process(_delta: float) -> PlayerState:
	if not player.is_on_wall():
		return player.get_state("Airborne")
	
	grab_timer = max(0, grab_timer - _delta)
	
	var wall_normal = player.get_wall_normal()
	if wall_normal == Vector2.ZERO:
		return player.get_state("Airborne")
		
	var wall_dir = sign(wall_normal.x)
	var move_dir = Input.get_axis("move_left", "move_right")
	var is_pressing_towards_wall = (sign(move_dir) == wall_dir) and move_dir != 0
	var is_pressing_up = Input.is_action_pressed("move_up")
	var is_pressing_down = Input.is_action_pressed("move_down")
	
	if not is_climbing:
		if is_pressing_towards_wall and is_pressing_up and grab_timer > 0:
			is_climbing = true
	else:
		if (sign(move_dir) == -wall_dir) and move_dir != 0:
			return player.get_state("Airborne")
		if is_pressing_down:
			is_climbing = false
		if not is_pressing_up and not is_pressing_down:
			is_climbing = false
			
	if is_climbing:
		player.velocity.x = 0
		var target_y = 0.0
		if is_pressing_up:
			target_y = -climb_speed
		elif is_pressing_down:
			target_y = climb_speed
		player.velocity.y = move_toward(player.velocity.y, target_y, climb_accel * _delta)
		player.play_anim("wall_climb")
	else:
		player.velocity.x = 0
		player.velocity.y += player.gravity * 0.2 * _delta
		if player.velocity.y > 20.0:
			player.velocity.y = 20.0
		player.play_anim("wall_grab")
		
	return null

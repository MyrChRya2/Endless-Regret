class_name WallState extends PlayerState
	

# 获取墙面方向（-1左墙，0无效，1右墙）
func get_wall_direction() -> int:
	var normal = player.get_wall_normal()
	if normal == Vector2.ZERO:
		return 0
	return -sign(normal.x)
	
	
# 检测是否仍在墙面
func is_still_on_wall() -> bool:
	return player.is_on_wall()
	

# 检查玩家是否按向墙面
func is_pressing_towards_wall() -> bool:
	var wall_dir = get_wall_direction()
	var move_dir = Input.get_axis("move_left", "move_right")
	if wall_dir == 0 or move_dir == 0:
		return false
	return sign(move_dir) == wall_dir
	
	
# 检查玩家是否按远离墙面
func is_pressing_away_from_wall() -> bool:
	var wall_dir = get_wall_direction()
	var move_dir = Input.get_axis("move_left", "move_right")
	if wall_dir == 0 or move_dir == 0:
		return false
	return sign(move_dir) == -wall_dir
	
	
func enter() -> void:
	player.velocity.x = 0
	

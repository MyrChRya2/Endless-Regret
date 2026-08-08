class_name WallState extends PlayerState
	

var away_timer: float = 0.0
@export var AWAY_THRESHOLD: float = 0.2

var hold_timer: float = 0.0
@export var HOLD_THRESHOLD: float = 0.2


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
	

# 处理远离键长按，返回 true 表示应该离开
func handle_away_timer(_delta: float) -> bool:
	if is_pressing_away_from_wall():
		away_timer += _delta
		if away_timer >= AWAY_THRESHOLD:
			return true
	else:
		away_timer = 0.0
	return false
	

# 处理未按住朝向墙方向键的超时，返回 true 表示应该离开
func handle_hold_timer(_delta: float) -> bool:
	if is_pressing_towards_wall():
		hold_timer = 0.0
	else:
		hold_timer += _delta
		if hold_timer >= HOLD_THRESHOLD:
			return true
	return false
			

# 重置所有计时器（进入状态时调用）
func reset_timers() -> void:
	away_timer = 0.0
	hold_timer = 0.0

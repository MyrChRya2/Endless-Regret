class_name PlayerStateRun extends PlayerState

@export var acceleration: float = 2400.0

	
# 在 state 中 每个 phusics process tick 会发生什么？
func physics_process(_delta: float) -> PlayerState:
	var move_direction = Input.get_axis("move_left", "move_right")
	var target_speed = player._get_effective_move_speed() * move_direction
	
	if move_direction !=0:
		player.velocity.x = move_toward(player.velocity.x, target_speed, acceleration * _delta)
	else:
		if player.is_on_floor():
			if abs(player.velocity.x) < 1.0:
				return get_node("../Idle")
			else:
				return get_node("../Slide")
	
	# 按跳跃 → 切到 Jump
	if Input.is_action_just_pressed("jump"):
		return get_node("../Jump")
	
	if not player.is_on_floor() and player.velocity.y >= 0:
		player.is_falling_off_ledge = true
		return get_node("../Fall")
	
	return null

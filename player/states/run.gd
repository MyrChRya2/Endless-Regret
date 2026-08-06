class_name PlayerStateRun extends GroundState

@export var accel: float = 2400.0

	
# 在 state 中 每个 phusics process tick 会发生什么？
func physics_process(_delta: float) -> PlayerState:
	var parent_result = super.physics_process(_delta)
	if parent_result != null:
		return parent_result

	player.play_anim("run")
	
	var move_dir = Input.get_axis("move_left", "move_right")
	var target_speed = player._get_effective_move_speed() * move_dir
	
	if move_dir != 0:
		player.velocity.x = move_toward(player.velocity.x, target_speed, accel * _delta)
	else:
		if player.is_on_floor():
			return player.get_state("Idle")
	return null

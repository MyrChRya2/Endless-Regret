class_name LedgeGrab extends WallState


func enter() -> void:
	player.velocity = Vector2.ZERO
	player.gravity_enabled = false
	player.play_anim("ledge_grab")
	reset_timers()
	_snap_to_ledge()


func exit() -> void:
	player.gravity_enabled = true


func physics_process(_delta: float) -> PlayerState:
	# 上爬：按 up 或 jump 进入 LedgeClimb 状态
	# （空间不足时由 LedgeClimb 退回本状态保持挂边；jump 不再进入 WallJump 蹬墙跳）
	if Input.is_action_just_pressed("move_up") or Input.is_action_just_pressed("jump"):
		return player.get_state("Wall/LedgeClimb")
		
	# 主动踢墙（与 WallGrab 一致）
	if handle_away_timer(_delta):
		return player.get_state("Wall/WallKickout")
		
	# 保持挂边（无需任何按键），每帧吸附抵消残余位移
	if player.is_on_wall():
		player.velocity = Vector2.ZERO
		_snap_to_ledge()
		return null
		
	# 被撞离墙 → 掉落
	return player.get_state("Airborne")


# 吸附：把碰撞盒顶（global_position.y - 27）贴到平台顶表面
func _snap_to_ledge() -> void:
	var hit := player.get_ledge_top_hit()
	if not hit.is_empty():
		player.global_position.y = float(hit.position.y) + 27.0

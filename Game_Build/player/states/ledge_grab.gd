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
	# 上扒：按 up 爬上平台（头顶空间不足时不爬，保持挂边）
	if Input.is_action_just_pressed("move_up"):
		var climbed := _climb_up()
		if climbed != null:
			return climbed
			
	# 蹬墙跳
	if Input.is_action_just_pressed("jump"):
		return player.get_state("Wall/WallJump")
		
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


# 上扒：把玩家移到平台顶上方并进入 Idle；空间不足/无平台顶则返回 null（保持挂边）
func _climb_up() -> PlayerState:
	var hit := player.get_ledge_top_hit()
	if hit.is_empty():
		return null
		
	# 头顶空间检测：平台顶上方 27px 内不能有遮挡，否则上扒会穿模
	var space_origin := player.global_position + Vector2(0.0, -52.0)
	var sp := PhysicsRayQueryParameters2D.create(
		space_origin, space_origin + Vector2.DOWN * 27.0
	)
	sp.collision_mask = player.collision_mask
	sp.exclude = [player.get_rid()]
	if not player.get_world_2d().direct_space_state.intersect_ray(sp).is_empty():
		return null
		
	# 脚底移到平台顶上方 0.5px，由当帧 move_and_slide + 重力自然落定贴合
	player.global_position.y = float(hit.position.y) - 0.5
	player.velocity = Vector2.ZERO
	return player.get_state("Idle")

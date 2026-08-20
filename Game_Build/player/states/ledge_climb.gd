class_name LedgeClimb extends WallState

# 上爬状态：从 LedgeGrab 按 jump / move_up 进入。
# 职责：检测头顶空间 → 爬上平台顶面 → 进入 Idle；空间不足/失去墙面 → 退回 LedgeGrab 保持挂边。
# 从 LedgeGrab 解耦（原 _climb_up 逻辑），独立成状态便于后续扩展爬升动画。


func enter() -> void:
	player.play_anim("ledge_climb")


func physics_process(_delta: float) -> PlayerState:
	var wall_normal := player.get_wall_normal()
	if wall_normal == Vector2.ZERO:
		return player.get_state("Wall/LedgeGrab")
	# 爬上后的站位：向平台内侧平移 16px（碰撞盒宽），站上平台顶面
	# （原 _climb_up 只改 y 不改 x，玩家挂在平台侧面时爬上去会悬空掉落）
	var target_x: float = player.global_position.x - sign(wall_normal.x) * 16.0
	var hit := player.get_ledge_top_hit()
	if hit.is_empty():
		return player.get_state("Wall/LedgeGrab")
	var top_y: float = float(hit.position.y)
	# 头顶空间检测：平台顶上方（爬上后身体将占用的 27px）不能被遮挡，否则爬升穿模
	if not _has_headroom(target_x, top_y):
		return player.get_state("Wall/LedgeGrab")
	# 爬上：脚底放到平台顶上方 10px（防穿透余量）、水平移到平台上，由当帧 move_and_slide + 重力自然落定贴合
	player.global_position = Vector2(target_x, top_y - 10.0)
	player.velocity = Vector2.ZERO
	return player.get_state("Idle")


# 空间检测：平台顶上方 6/14/22px × 碰撞盒宽度 3 列采样，任一点埋入碰撞体 → 无净空
func _has_headroom(target_x: float, top_y: float) -> bool:
	for dy in [6.0, 14.0, 22.0]:
		for sx in [-6.0, 0.0, 6.0]:
			if player._point_inside_world(Vector2(target_x + sx, top_y - dy)):
				return false
	return true

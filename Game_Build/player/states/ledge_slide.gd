class_name LedgeSlide extends WallState

# 滑落速度上限：重力无限加速会让一帧下滑超过挂边检测窗口（头顶±容差），导致挂边漏判
const MAX_SLIDE_SPEED: float = 120.0

# 挂边要求"玩家从上方滑向墙顶"：滑落中头顶曾高于墙顶足够远（dy > LEDGE_APPROACH_MIN）才允许挂边。
# 防止：触墙/头撞墙时头顶已在墙顶附近（dy 小）却被判定挂边
var _was_above: bool = false


func enter() -> void:
	player.play_anim("ledge_slide")
	reset_timers()
	_was_above = false


func physics_process(_delta: float) -> PlayerState:
	# 贴墙滑落：锁定水平速度；垂直速度限速，保证挂边窗口内有多帧可供检测
	player.velocity.x = 0
	player.velocity.y = min(player.velocity.y, MAX_SLIDE_SPEED)
	
	# 头顶在墙顶上方足够远处 → 标记"正在从上方滑向墙顶"
	if player.get_ledge_dy() > player.LEDGE_APPROACH_MIN:
		_was_above = true
	
	# 上爬：按 jump 进入 LedgeClimb（与 LedgeGrab 一致；空间不足/平台顶不在附近时由 LedgeClimb 退回本状态）
	if Input.is_action_just_pressed("jump"):
		return player.get_state("Wall/LedgeClimb")
		
	var contact = player.classify_wall_contact()
	# 挂边：头顶顶着墙顶，且玩家是从上方滑落下来的（_was_above）
	if contact == player.WallContact.LEDGE_TOP and _was_above:
		return player.get_state("Wall/LedgeGrab")
	# 完整贴墙（头顶+脚底都贴墙）→ 切回 WallGrab 慢滑（如从平台边缘滑落到旁边完整墙上）
	if contact == player.WallContact.FULL:
		return player.get_state("Wall/WallGrab")
	if contact == player.WallContact.NONE:
		return player.get_state("Airborne")
	# SLIDING：继续滑落
		
	# 按离墙方向键 0.2s → 脱墙自由落体
	if handle_away_timer(_delta):
		return player.get_state("Airborne")
		
	return null

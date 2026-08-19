class_name WallGrab extends WallState


var slide_speed: float = 20.0
# 挂边要求"从上方滑向墙顶"：头顶曾高于墙顶足够远才允许挂边（防止撞在墙顶附近被瞬间抓住）
var _was_above: bool = false


func enter() -> void:
	player.velocity.x = 0
	player.play_anim("wall_grab")
	away_timer = 0.0
	hold_timer = 0.0
	_was_above = false
		
func physics_process(_delta: float) -> PlayerState:
	if player.is_on_floor():
		if abs(player.velocity.x) > 10.0:
			return player.get_state("Run")
		else:
			return player.get_state("Idle")
		
	player.velocity.x = 0
	
	player.velocity.y = min(player.velocity.y, slide_speed)
	if player.is_on_wall():
		# 头顶在墙顶上方足够远处 → 标记"正在从上方滑向墙顶"
		if player.get_ledge_dy() > player.LEDGE_APPROACH_MIN:
			_was_above = true
			
		if Input.is_action_just_pressed("jump"):
			return player.get_state("Wall/WallJump")
			
		var contact = player.classify_wall_contact()
		# 滑到墙顶（头顶顶着墙顶）→ 从上方滑下来的玩家转挂边
		if contact == player.WallContact.LEDGE_TOP and _was_above:
			return player.get_state("Wall/LedgeGrab")
		# 脚底已离开墙面（只贴了上半身）→ 脱离墙面自由落体
		# 置脱离锁：防止进 Airborne 后头顶还贴墙被贴墙检测拉回；锁会在离开墙面/超时后自动复位
		if contact == player.WallContact.SLIDING:
			player.wall_escape = true
			player.wall_escape_time = player.WALL_ESCAPE_DURATION
			return player.get_state("Airborne")
			
		if handle_hold_timer(_delta):
			return player.get_state("Wall/WallKickout")
				
		if handle_away_timer(_delta):
			return player.get_state("Airborne")
				
	else:
		return player.get_state("Airborne")
		
	return null

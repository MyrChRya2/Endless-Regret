class_name PlayerStateClimbWall extends PlayerState

## 进入 ClimbWall 时开始计时的时间窗口（秒）
@export var grab_time_window: float = 0.4
## 超时未抓墙时，沿墙面法线向外推开的初速度
@export var push_off_velocity: float = 100.0
## 推开后速度每帧衰减系数（0~1，越小衰减越快）
@export var push_damping: float = 0.92
## 下落（velocity.y < 0）时的重力倍率（0~1）
@export var wall_slide_gravity_rate: float = 0.25
## 跳跃脱离时沿墙面法线向外的水平初速度
@export var wall_jump_velocity: float = 300.0

var _wall_timer: float = 0.0
var _wall_normal: Vector2 = Vector2.ZERO
var _pushing_off: bool = false
var _push_velocity: float = 0.0


func enter() -> void:
	# 进入时保留 velocity.y
	player.can_wall_jump = false
	player.can_coyote_jump = false
	player.is_falling_off_ledge = false
	_wall_timer = grab_time_window
	_pushing_off = false
	_push_velocity = 0.0
	_wall_normal = _get_wall_normal()
	
	# TODO(动画): 进入 ClimbWall 时 velocity.y 正负变化可在此调用动画函数
	# 例如：if player.velocity.y < 0: play_anim("climb_up") else: play_anim("climb_slide")


func exit() -> void:
	# TODO(动画): 退出 ClimbWall 时 velocity.y 正负变化可在此调用动画函数
	pass


func handle_input(_event: InputEvent) -> PlayerState:
	# 跳跃脱离
	if Input.is_action_just_pressed("jump"):
		# 沿墙面法线方向（指向墙外）施加水平初速度
		player.velocity.x = _wall_normal.x * wall_jump_velocity
		# 空中减速逻辑（player.air_move）会在下一帧接管并衰减该速度
		player._handle_jump()
		return player.get_state("Airborne")
		
	# 主动脱离：按下 Down 键
	if Input.is_action_just_pressed("ui_down"):
		# 设置冷却锁，禁止再次进入 ClimbWall，直到完全离开墙面
		player.block_climb = true
		return player.get_state("Airborne")
	return null


func physics_process(_delta: float) -> PlayerState:
	# 1. 被动脱离：失墙
	if not player.is_on_wall():
		# 完全离开墙面，解除 block_climb 冷却锁
		player.block_climb = false
		return player.get_state("Airborne")
		
	# 2. 重力处理：下落减速（velocity.y < 0 时用倍率，否则 ×1.0）
	var gravity_rate: float = wall_slide_gravity_rate if player.velocity.y < 0 else 1.0
	player.velocity.y += player.GRAVITATIONAL_ACCELERATION * player.NORMAL_GRAVITY_RATE * gravity_rate * _delta
	
	# 3. 超时推开机制
	var input_dir: float = Input.get_axis("move_left", "move_right")
	var input_vec: Vector2 = Vector2(input_dir, 0.0)
	# 输入方向 与 -墙面法线 的点积 > 0 表示按住了朝向墙壁的方向键
	var pressing_toward_wall: bool = input_vec.dot(-_wall_normal) > 0.0
	
	if pressing_toward_wall:
		# 主动抓墙：保持状态，计时器重置（下次再进重新计时）
		_wall_timer = grab_time_window
		_pushing_off = false
	else:
		_wall_timer -= _delta
		if _wall_timer <= 0.0 and not _pushing_off:
			# 超时：沿墙面法线向外推开
			_pushing_off = true
			_push_velocity = push_off_velocity
			player.velocity.x = _wall_normal.x * _push_velocity
	
	if _pushing_off:
		# 推开速度按阻尼系数衰减
		_push_velocity *= push_damping
		player.velocity.x = _wall_normal.x * _push_velocity
		# 一旦脱离 ClimbWall，进入 Airborne
		if _push_velocity < 1.0:
			return player.get_state("Airborne")
	
	# TODO(功能): 爬墙垂直向上移动预留（按住向上方向键时 velocity.y < 0 加速上移）
	# TODO(动画): 爬墙垂直向上移动动画预留
	
	return null


func _get_wall_normal() -> Vector2:
	# 从最近一次滑动碰撞中获取墙面法线
	var collision := player.get_last_slide_collision()
	if collision:
		return collision.get_normal()
	return Vector2.ZERO

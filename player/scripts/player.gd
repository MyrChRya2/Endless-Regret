class_name Player extends CharacterBody2D


#region /// State Machine Variables
var current_state: PlayerState = null

@onready var states_machine_container: Node = $States

#endregion


#region /// 物理参数

#region /// run
# 默认奔跑速度
const default_run_speed: float = 200.0
# 默认奔跑倍率
@export var DEFAULT_MOVE_SPEED_MULTIPLIER: float = 1.0
# 移速倍率表
var move_speed_modifiers: Array[float] = [DEFAULT_MOVE_SPEED_MULTIPLIER]
#endregion

#region /// jump
# 默认跳跃高度
const default_jump_height: float = 100.0
# 默认跳高倍率
@export var DEFAULT_JUMP_HEIGHT_MULTIPLIER: float = 0.7
# 跳高倍率表
var jump_height_modifiers: Array[float] = [DEFAULT_JUMP_HEIGHT_MULTIPLIER]
# 跳跃截取系数 
@export var jump_cut_multiplier: float = 0.6
#endregion

#region /// air movement
# 空中移动移速倍率
const air_move_speed: float = 0.6
# 空中加速灵敏度
@export var air_acceleration: float = 800.0
# 空中速度衰减灵敏度
@export var air_deceleration: float = 400.0

# 多端跳次数
var extra_air_jumps: int = 1
# 剩余多端跳次数多段跳
var remaining_air_jumps = extra_air_jumps

# 跳跃预输入窗口
@export var jump_buffer_time: float = 0.15
# 跳跃与输入窗口剩余时间
var jump_buffer_timer: float = 0.0

# 土狼跳
var can_coyote_jump: bool = true
# 平面边缘掉落检测
var is_falling_off_ledge: bool = false

# 蹬墙跳
var can_wall_jump: bool = true

#endregion

#region /// gravity
@export var GRAVITATIONAL_ACCELERATION: float = 980.0
@export var NORMAL_GRAVITY_RATE: float = 1.0
var gravity: float = GRAVITATIONAL_ACCELERATION * NORMAL_GRAVITY_RATE
#endregion

#region /// friction
# 默认摩擦系数
const default_cof: float = 1.0
# 摩擦倍率
@export var DEFAULT_FRICTION_MULTIPLIER: float = 1.0
# 摩擦倍率表
var cof_modifiers: Array[float] = [DEFAULT_FRICTION_MULTIPLIER]

# 地面材质倍率
var ground_friction_multiplier: float = 1.0
#endregion

#endregion


#region /// Animation

enum FacingDir { LEFT, RIGHT }
var facing: FacingDir
var last_facing: FacingDir

@onready var player_anim: AnimatedSprite2D = %PlayerAnim

#endregion

var MAX_JUMP_VEL: float


func  _ready() -> void:
	# 初始化 states
	initialize_states()
	initialize_facing()
	pass


func _unhandled_input(event: InputEvent) -> void:
	if current_state:
		var next_state = current_state.handle_input(event)
		if next_state != null:
			change_state(next_state)
		
	
func _process(_delta: float) -> void:
	if current_state:
		var next_state = current_state.process(_delta)
		if next_state != null:
			change_state(next_state)
		
	_push_debug_data()
	pass


func _physics_process(_delta: float) -> void:
	# 重力
	velocity.y += gravity * _delta
	
	# 朝向更新
	var input_dir = Input.get_axis("move_left", "move_right")
	if input_dir != 0.0:
		set_facing(FacingDir.RIGHT if input_dir > 0 else FacingDir.LEFT)
		
	# 执行状态机逻辑
	if current_state:
		var next_state = current_state.physics_process(_delta)
		if next_state != null:
			change_state(next_state)
			
	# 移动并处理碰撞
	move_and_slide()
	update_ground_friction_from_tile()
	
	# 落地重置资源
	if is_on_floor():
		velocity.y = 0
		reset_remaining_air_jump()
		can_coyote_jump = true
	elif is_on_wall():
		reset_remaining_air_jump()
		can_wall_jump = true
	
func initialize_states() -> void:
	#收集所有子状态并注入 player 引用
	for child in states_machine_container.get_children():
		if child is PlayerState:
			child.player = self
			child.init()
	#默认进入第一个状态
	if states_machine_container.get_child_count() > 0:
		current_state = states_machine_container.get_child(0)
		current_state.enter()
	
	
func change_state(new_state:PlayerState) -> void:
	if new_state == null:
		print("⚠️ change_state 收到 null，忽略")
		return
	if new_state == current_state:
		print("ℹ️ 尝试切换到当前状态 [", current_state.name, "]，已忽略")
		return
		
	var from_name = "NULL"
	if current_state:
		from_name = current_state.name
	var to_name = new_state.name
	DebugManager.log_state_change(from_name, to_name)
	
	if current_state:
		current_state.exit()
		
	current_state = new_state
	current_state.enter()
	
	
func get_state(_name: String) -> PlayerState:
	return states_machine_container.get_node(_name)
	
	
# 当前移动倍率
func _get_total_move_speed_multiplier() -> float:
	var total_move_speed := 1.0
	for move_speed_midiier in move_speed_modifiers:
		total_move_speed *= move_speed_midiier
	return total_move_speed
# 最终移速
func _get_effective_move_speed() -> float:
	return default_run_speed * _get_total_move_speed_multiplier()


# 当前跳跃倍率
func _get_total_jump_height_multiplier() -> float:
	var total_jump_height := 1.0
	for jump_height_modifier in jump_height_modifiers:
		total_jump_height *= jump_height_modifier
	return total_jump_height
# 最终跳跃高度
func _get_effective_jump_height() -> float:
	return default_jump_height * _get_total_jump_height_multiplier()
	

# 当前摩擦倍率
func _get_total_cof_multiplier() -> float:
	var total_cof := 1.0
	for cof_modifier in cof_modifiers:
		total_cof *= cof_modifier
	return total_cof
# 最终摩擦系数
func _get_effective_cof() -> float:
	return default_cof * _get_total_cof_multiplier() * ground_friction_multiplier
	
func update_ground_friction_from_tile() -> void:
	var last_collision = get_last_slide_collision()
	var multiplier = 1.0
	
	if last_collision != null:
		var collider = last_collision.get_collider()
		
		if collider is TileMapLayer:
			var tilemap: TileMapLayer = collider
			var local_pos = tilemap.to_local(last_collision.get_position())
			var coords = tilemap.local_to_map(local_pos)
			var tile_data = tilemap.get_cell_tile_data(coords)
			
			if tile_data and  tile_data.has_custom_data("friction"):
				multiplier = tile_data.get_custom_data("friction")
				
	ground_friction_multiplier = multiplier
	
func reset_remaining_air_jump() -> int:
	remaining_air_jumps = extra_air_jumps	
	return remaining_air_jumps
	

func initialize_facing() -> void:
	facing = FacingDir.RIGHT
	last_facing = facing


# 时间驱动地面动画
func play_anim(anim_base: String) -> void:
	var suffix = "_right" if last_facing == FacingDir.RIGHT else "_left"
	var anim_name = anim_base + suffix
	if player_anim.animation != anim_name:
		player_anim.play(anim_name)

# 物理驱动空中动画
func update_air_animation() -> void:
	var suffix = "_right" if last_facing == FacingDir.RIGHT else "_left"
	var anim_name: String = ("airborne" if not is_on_wall_only() else "climb") + suffix
	
	var frame_count = player_anim.sprite_frames.get_frame_count(anim_name)
	if frame_count <= 0:
		return
		
	if player_anim.animation != anim_name:
		player_anim.play(anim_name)
	
	# 理论最大上升速度
	var max_vel = sqrt(2.0 * gravity * _get_effective_jump_height())
	# 防止除以0
	if max_vel <= 0.0:
		player_anim.frame = 0
		return
		
	# 将垂直速度映射到 [0, 1] 区间 -> [-max_vel, +max_vel]
	var t = clamp((velocity.y + max_vel) / (2.0 * max_vel), 0.0, 1.0)
	
	# 四舍五入到帧索引
	var index = int(round(t * (frame_count - 1)))
	player_anim.frame = index
	
	DebugManager.set_value("now_air_anim_dir", suffix)
	
	
	
# 空中水平移动
func air_move(_delta: float) -> void:
	var move_direction = Input.get_axis("move_left", "move_right")
	var target_speed = move_direction * _get_effective_move_speed() * air_move_speed
	if move_direction != 0:
		velocity.x = move_toward(velocity.x, target_speed, air_acceleration * _delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, air_deceleration * _delta)
		
		
	# 调试HUD数据抓取
func _push_debug_data() -> void:
	if not DebugManager:
		return
		
	DebugManager.set_value("player_vel", velocity.length())
	DebugManager.set_value("player_vel_x", velocity.x)
	DebugManager.set_value("player_vel_y", velocity.y)
	DebugManager.set_value("is_on_floor", is_on_floor())
	DebugManager.set_value("facing", facing)
	DebugManager.set_value("last_facing", last_facing)
	DebugManager.set_value("now_pressed", _get_key_input())
	
	# 临时按键抓取
func _get_key_input() -> String:
	if Input.is_key_pressed(KEY_A):
		return "A"
	elif Input.is_key_pressed(KEY_D):
		return "D"
	else:
		return ""


func set_facing(dir: FacingDir) -> void:
	if facing != dir:
		facing = dir
		last_facing = dir

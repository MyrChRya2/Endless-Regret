class_name Player extends CharacterBody2D


#region /// State Machine Variables
var current_state: PlayerState = null

@onready var states_machine_container: Node = $States

#endregion


#region /// 物理参数

#region /// run
# 默认奔跑速度
const default_run_speed: float = 200.0
# 默认奔跑加速度
@export var accel: float = 2400.0
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
# 跳跃状态
enum JumpType { GROUND, COYOTE, AIR, BUFFER, WALL }
var current_jump_type

#endregion

#region /// air movement
# 空中移动移速倍率
const air_move_speed: float = 0.6
# 空中加速灵敏度
@export var air_accel: float = 800.0
# 空中速度衰减灵敏度
@export var air_decel: float = 400.0

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


#endregion

#region /// gravity
@export var GRAVITATIONAL_ACCELERATION: float = 980.0
@export var NORMAL_GRAVITY_RATE: float = 1.0
var gravity: float = GRAVITATIONAL_ACCELERATION * NORMAL_GRAVITY_RATE
var gravity_enabled: bool = true
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

var _missing_anim_warned: Dictionary = {}

@onready var player_anim: AnimatedSprite2D = %PlayerAnim

#endregion

var can_wall_climb: bool = true

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
	# 执行状态机逻辑
	if current_state:
		var next_state = current_state.physics_process(_delta)
		if next_state != null:
			change_state(next_state)
	
	# 重力
	if gravity_enabled:
		velocity.y += gravity * _delta
	
	# 移动并处理碰撞
	move_and_slide()
	update_ground_friction_from_tile()
	
	# 朝向更新
	var input_dir = Input.get_axis("move_left", "move_right")
	if input_dir != 0.0:
		set_facing(FacingDir.RIGHT if input_dir > 0 else FacingDir.LEFT)
		
	# 落地重置资源（仅在 velocity.y >= 0 时归零，避免清除跳跃速度）
	if is_on_floor() and velocity.y >= 0:
		velocity.y = 0
		reset_remaining_air_jump()
		can_coyote_jump = true
	
func initialize_states() -> void:
	_recursive_init(states_machine_container)
	var default_state = get_state("Idle")
	if default_state:
		current_state = default_state
		current_state.enter()
		print("✅ 状态机初始化完成，当前状态：", current_state.name)
	else:
		print("❌ 错误：找不到 ", default_state, " 状态！")
	
	
func _recursive_init(node: Node) -> void:
	for child in node.get_children():
		if child is PlayerState:
			child.player = self
			child.init()
	# 持续递归
		if child.get_child_count() > 0:
			_recursive_init(child)
	
	
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
	
	
func get_state(path: String) -> PlayerState:
	return states_machine_container.get_node(path)
	
	
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
	
	
#region /// 动画方法

func _handle_anim(anim_name: String) -> bool:
	if player_anim.sprite_frames.has_animation(anim_name):
		# 动画存在，正常播放（避免重复播放同一个动画）
		if player_anim.animation != anim_name:
			player_anim.play(anim_name)
		return true
	else:
		# 动画缺失：输出错误，并尝试播放 error 占位动画
		if not _missing_anim_warned.has(anim_name):
			_missing_anim_warned[anim_name] = true
			push_error("动画 '", anim_name, "' 不存在，使用 error 占位动画")
			
		if player_anim.sprite_frames.has_animation("error"):
			if player_anim.animation != "error":
				player_anim.play("error")
		else:
			# 连 error 动画都没有，则停止动画并显示第一帧（或保持当前帧）
			player_anim.stop()
			
	DebugManager.set_value("current_anim", anim_name)
	
	return false
	
	
	
# 时间驱动地面动画
func play_anim(anim_base: String) -> void:
	var suffix = "_right" if facing == FacingDir.RIGHT else "_left"
	var anim_name = anim_base + suffix
	_handle_anim(anim_name)

# 物理驱动空中动画
func update_air_animation() -> void:
	var suffix: String
	if velocity.x > 0.0:
		suffix = "_right"
	elif velocity.x < 0.0:
		suffix = "_left"
	else:
		suffix = "_right" if player_anim.animation.ends_with("_right") else "_left"
		
	var anim_name: String = ("airborne") + suffix
	
	if not _handle_anim(anim_name):
		return
		
	var max_vel = sqrt(2.0 * gravity * _get_effective_jump_height())
	if max_vel <= 0.0:
		player_anim.frame = 0
		return
		
	var t = clamp((velocity.y + max_vel) / (2.0 * max_vel), 0.0, 1.0)
	var index = int(round(t * (player_anim.sprite_frames.get_frame_count(anim_name) - 1)))
	player_anim.frame = index
		
#endregion


	# 调试HUD数据抓取
func _push_debug_data() -> void:
	if not DebugManager:
		return
		
	DebugManager.set_value("player_vel", velocity.length())
	DebugManager.set_value("player_vel_x", velocity.x)
	DebugManager.set_value("player_vel_y", velocity.y)
	DebugManager.set_value("is_on_floor", is_on_floor())
	DebugManager.set_value("facing", facing)
	DebugManager.set_value("facing", facing)
	DebugManager.set_value("now_pressed", _get_key_input())
	DebugManager.set_value("can_coyote_jump", can_coyote_jump)
	DebugManager.set_value("remaining_air_jump", remaining_air_jumps)
	DebugManager.set_value("jump_type", current_jump_type)
	
	
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


# 垂直移动
func _handle_jump() -> void:
	var jump_vel := sqrt(2 * gravity * _get_effective_jump_height())
	velocity.y = -jump_vel
	
	
# 水平移动
func _handle_h_move(_delta: float, move_dir) -> void:
	var target_speed = move_dir * _get_effective_move_speed()
	if move_dir != 0:
		velocity.x = move_toward(velocity.x, target_speed, accel * _delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, accel * _delta)
		
		
# 空中水平移动
func _handle_air_move(_delta: float, move_dir) -> void:
	var target_speed = move_dir * _get_effective_move_speed()
	if move_dir != 0:
		velocity.x = move_toward(velocity.x, target_speed, air_accel * _delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, air_decel * _delta)

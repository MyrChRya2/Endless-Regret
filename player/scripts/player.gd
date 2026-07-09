class_name Player extends CharacterBody2D

#region /// State Machine Variables
var states: Array[PlayerState] = []
var current_state: PlayerState:
	get:
		return states.front()
var previous_state: PlayerState:
	get:
		return states[1] if states.size() > 1 else null

#endregion

#region /// standard variables
# 默认移速
const defult_move_speed: float = 200.0
# 默认移速倍率
@export var DEFAULT_MOVE_SPEED_MULTIPLIER: float = 1.0
# 移速倍率表
var move_speed_modifiers: Array[float] = [DEFAULT_MOVE_SPEED_MULTIPLIER]

# 可跳跃
var CAN_JUMP:bool = false
# 默认跳跃高度
const defult_jump_height: float = 100.0
# 默认跳高倍率
@export var DEFAULT_JUMP_HEIGHT_MULTIPLIER: float = 1.0
# 跳高倍率表
var jump_height_modifiers: Array[float] = [DEFAULT_JUMP_HEIGHT_MULTIPLIER]
# 跳跃截取系数 
@export var jump_cut_multiplier: float = 0.6
# 地面检测
var is_jumping: bool = false
# 土狗时间
var coyote_timer: float = 0.0
@export var coyote_time: float = 0.27

# 多段跳
@export var max_extra_jumps: int = 1
var remaining_jumps: int = 0


@export var GRAVITATIONAL_ACCELERATION: float = 980.0
@export var NORMAL_GRAVITY_RATE: float = 1.0
var gravity: float = GRAVITATIONAL_ACCELERATION * NORMAL_GRAVITY_RATE

# 运动向量
var direction: Vector2 = Vector2.ZERO
# 认不出这个可以重开了
var current_delta: float = 0.0

#endregion


func  _ready() -> void:
	# 初始化 states
	initialize_states()
	coyote_timer = coyote_time
	print(coyote_timer)
	CAN_JUMP = true
	pass


func _unhandled_input(event: InputEvent) -> void:
	#region /// 一次性输入
	# 跳跃
	if event.is_action("jump"):
		if _can_jump():
			change_state(get_node("States/Jump"))
			return
	## 其他一次性动作
	# if event.is_action("示例状态机")
		# if 状态机可用条件
		# pass
	change_state(current_state.handle_input(event)) # 如果所有输入都在这里统一处理，状态中的 handle_input 可以简化或移除。
	pass
	#endregion
	
	
func _process(_delta: float) -> void:
	#update_direction()
	change_state(current_state.process(_delta))
	pass


func _physics_process(_delta: float) -> void:
	# 全局计时维护
	if not is_on_floor() and not is_jumping:
		coyote_timer = max(0.0, coyote_timer - _delta)
		#if coyote_timer > 0:
			#print("coyote timer is now tick tock")
		#else:
			#print("coyote timer is done")
	else:
		coyote_timer = coyote_time
		#print("coyote timer reset: ", coyote_time)
		
	# 重力
	velocity.y += gravity * _delta
	
	move_and_slide()

	change_state(current_state.physics_process(_delta))
	
	pass
	
	
func initialize_states() -> void:
	states = []
	#收集 state
	for c in $States.get_children():
		if c is PlayerState:
			states.append(c)
			c.player = self
		pass
		
		
	if states.size() == 0:
		return
		
		
	#初始化 state
	for state in states:
		state.init()
		
		
	#设置第一 state
	change_state(current_state)
	
	current_state.enter()
	pass
	
	
	
func change_state(new_state:PlayerState) -> void:
	if new_state == null:
		return
	elif new_state == current_state:
		return
		
		
	if current_state:
		current_state.exit()
		
		
	states.push_front(new_state)
	current_state.enter()
	states.resize(3)
	pass


#func update_direction() -> void:
	##var prev_direction: Vector2 = direction
	#direction = Input.get_vector("move_left", "move_right", "look_up", "look_down")
	#
	#
	#pass
	

# 当前移动倍率
func get_total_move_speed_multiplier() -> float:
	var total_move_speed := 1.0
	for move_speed_modifier in move_speed_modifiers:
		total_move_speed *= move_speed_modifier
	return total_move_speed
	
# 最终移速
func _get_effective_move_speed() -> float:
	return defult_move_speed * get_total_move_speed_multiplier()
	
	
# 当前跳跃倍率
func _get_total_jump_height_multiplier() -> float:
	var total_jump_height := 1.0
	for jump_height_modifier in jump_height_modifiers:
		total_jump_height *= jump_height_modifier
	return total_jump_height
# 最终跳跃高度
func _get_effective_jump_height() -> float:
	return defult_jump_height * _get_total_jump_height_multiplier()
	
# 可跳跃判断
func _can_jump() -> bool:
	if is_on_floor() or coyote_timer > 0:
		return true
	else:
		return false
			
			

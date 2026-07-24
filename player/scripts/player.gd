class_name Player extends CharacterBody2D


#region /// State Machine Variables
var current_state: PlayerState = null

@onready var states_machine_container: Node = $States

#endregion


#region /// 物理参数

#region /// run
# 默认奔跑速度
const default_run_speed: float = 300.0
# 默认奔跑倍率
@export var DEFAULT_MOVE_SPEED_MULTIPLIER: float = 1.0
# 移速倍率表
var move_speed_modifiers: Array[float] = [DEFAULT_MOVE_SPEED_MULTIPLIER]
#endregion

#region /// jump
# 默认跳跃高度
const default_jump_height: float = 100.0
# 默认跳高倍率
@export var DEFAULT_JUMP_HEIGHT_MULTIPLIER: float = 1.0
# 跳高倍率表
var jump_height_modifiers: Array[float] = [DEFAULT_JUMP_HEIGHT_MULTIPLIER]
# 跳跃截取系数 
@export var jump_cut_multiplier: float = 0.6

# 空中移动移速倍率
const air_move_speed: float = 0.8
#endregion

#region /// gravity
@export var GRAVITATIONAL_ACCELERATION: float = 980.0
@export var NORMAL_GRAVITY_RATE: float = 1.0
var gravity: float = GRAVITATIONAL_ACCELERATION * NORMAL_GRAVITY_RATE
#endregion

#region /// friction
@export var DEFAULT_FRICTION_MULTIPLIER: float = 1.0
#endregion

#endregion


func  _ready() -> void:
	# 初始化 states
	initialize_states()
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
	pass


func _physics_process(_delta: float) -> void:
	# 重力
	velocity.y += gravity * _delta
	# 更新土狗时间
	#update_coyote_timer(_delta)
	if current_state:
		var next_state = current_state.physics_process(_delta)
		move_and_slide()
		if next_state != null:
			change_state(next_state)
			

	
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
	if new_state == null or new_state == current_state:
		return
	if current_state:
		current_state.exit()
		
	current_state = new_state
	current_state.enter()
	
	
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
	

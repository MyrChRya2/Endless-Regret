@icon("res://player/states/state.svg")
class_name PlayerStateJump extends PlayerState

var is_grounded_jump: bool = false

#region /// reference
## Called when the node enters the scene tree for the first time.
#func _ready() -> void:
	#pass # Replace with function body.
#
#
## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass
#endregion


# state 被初始化时会发生什么？
func  init() -> void:
	pass
	
	
# 进入 state 时会发生什么？
func enter() -> void:
	print("enter ", name)
	if player.is_on_floor():
		is_grounded_jump = true
		print("grounded jump: ", is_grounded_jump)
	else:
		is_grounded_jump = false
	var jump_velocity := sqrt(2 * player.gravity * player._get_effective_jump_height())
	player.velocity.y = -jump_velocity
	
	
	
# 退出 state 时会发生什么？
func exit() -> void:
	print("exit ", name)
	pass
	
	
# 按下 input 时会发生什么？
func handle_input(_event:InputEvent) -> PlayerState:
	return null
	
	
# 在 state 中 每个 process tick 会发生什么？
func process(_delta: float) -> PlayerState:
	return null
	
# 在 state 中 每个 phusics process tick 会发生什么？
func physics_process(_delta: float) -> PlayerState:
	# 空中水平移动
	var move_direction = Input.get_axis("move_left", "move_right")
	player.velocity.x = move_direction * player._get_effective_move_speed() * player.air_move_speed
	# 落地检测
	if player.velocity.y >= 0 and player.is_on_floor():
		return get_node("../Idle")
	
	return null

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
	player.is_jumping = true
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
	return next_state
	
	
# 在 state 中 每个 process tick 会发生什么？
func process(_delta: float) -> PlayerState:
	return next_state
	
# 在 state 中 每个 phusics process tick 会发生什么？
func physics_process(_delta: float) -> PlayerState:
	# 落地检测
	if player.is_on_floor():
		player.is_jumping = false
		return get_node("../Idle")

		
	var move_input := Input.get_axis("move_left", "move_right")
	player.velocity.x = move_input * player._get_effective_move_speed()
	
	return null

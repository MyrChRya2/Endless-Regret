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
	if player.is_on_floor() or player.coyote_timer > 0.0:
		is_grounded_jump = true
		player.coyote_timer = 0.0
	else:
		is_grounded_jump = false
		player.remaining_jumps = max(0, player.remaining_jumps - 1)
	var jump_velocity := sqrt(2 * player.gravity * player._get_effective_jump_height())
	player.velocity.y = -jump_velocity
	player.is_jumping = true
	
	
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
	# 跳跃截断
	if player.is_jumping and not Input.is_action_pressed("jump") and player.velocity.y < 0.0:
		player.velocity.y *= player.jump_cut_multiplier
		player.is_jumping = false
		
		if player.remaining_jumps >0:
			print("remaining jumps is", player.remaining_jumps, "left")
		else:
			print("remaining jumps done")
	# 落地检测
	if player.is_on_floor():
		player.coyote_timer = player.coyote_time
		player.is_jumping = false
		return get_node("../Idle")
		
	var move_input := Input.get_axis("move_left", "move_right")
	player.velocity.x = move_input * player._get_effective_move_speed()
	
	return null

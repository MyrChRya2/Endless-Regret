@icon("res://player/states/state.svg")
class_name PlayerState extends Node


var player: Player
var next_state: PlayerState = null


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
	pass
	
	
# 退出 state 时会发生什么？
func exit() -> void:
	pass
	
	
# 按下 input 时会发生什么？
func handle_input(_event:InputEvent) -> PlayerState:
	return next_state
	
	
# 在 state 中 每个 process tick 会发生什么？
func process(_delta: float) -> PlayerState:
	return next_state
	
# 在 state 中 每个 phusics process tick 会发生什么？
func physics_process(_delta: float) -> PlayerState:
	return next_state

class_name PlayerStateIdle extends GroundState

func enter() -> void:
	player.is_falling_off_ledge = false
	player.can_coyote_jump = true

	
func process(_delta: float) -> PlayerState:
	player.play_anim("idle")
	
	return null
	
	
# 在 state 中 每个 phusics process tick 会发生什么？
func physics_process(_delta: float) -> PlayerState:
	var parent_result = super.physics_process(_delta)
	if parent_result != null:
		return parent_result
		
	if Input.get_axis("move_left", "move_right"):
		return player.get_state("Run")
		
	return null

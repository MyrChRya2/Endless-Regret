class_name PlayerStateSlide extends GroundState


var base_friction: float = 1200.0

func enter() -> void:
	player.is_falling_off_ledge = false
	player.can_coyote_jump = true
	
	
func process(_delta: float) -> PlayerState:
	player.play_anim("slide")
	
	return null
	
	
func physics_process(_delta: float) -> PlayerState:
	if Input.get_axis("move_left", "move_right"):
		return player.get_state("Run")
		
		
	if player.is_on_floor():
		var effective_friction = player._get_effective_cof() * base_friction
		player.velocity.x = move_toward(player.velocity.x, 0.0, effective_friction * _delta)
	else:
		return player.get_state("Fall")
		
	if abs(player.velocity.x) < 1.0:
		player.velocity.x =0
		return player.get_state("Idle")
		
	return null

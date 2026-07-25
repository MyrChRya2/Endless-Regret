class_name PlayerStateSlide extends PlayerState


var base_friction: float = 2400.0

func enter() -> void:
	player.is_falling_off_ledge = false
	player.can_coyote_jump = true
	
	
func physics_process(_delta: float) -> PlayerState:
	if Input.get_axis("move_left", "move_right"):
		return get_node("../Run")
		
	if Input.is_action_just_pressed("jump"):
		return get_node("../Jump")
		
	if player.is_on_floor():
		var effective_friction = player._get_effective_cof() * base_friction
		player.velocity.x = move_toward(player.velocity.x, 0.0, effective_friction * _delta)
	else:
		return get_node("../Fall")
		
	if abs(player.velocity.x) < 1.0:
		player.velocity.x =0
		return get_node("../Idle")
		
	return null

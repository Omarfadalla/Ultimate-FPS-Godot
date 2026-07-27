class_name IdlePlayerState
extends PlayerMovementState

@export var SPEED : float = 2.2
@export var ACCELERATION : float = 0.1
@export var DECELERATION : float = 0.25
@export var TOP_ANIM_SPEED : float = 2.2

func enter(previous_state) -> void:
	ANIMATION.pause()
	
func update(delta):
	PLAYER.update_gravity(delta)
	PLAYER.update_input(SPEED, ACCELERATION, DECELERATION)
	PLAYER.update_velocity()

	if Input.is_action_just_pressed("crouch"):
		transition.emit("CrouchingPlayerState")
		return

	if PLAYER.velocity.length() > 0 and PLAYER.is_on_floor():
		transition.emit("WalkingPlayerState")
	
	if Input.is_action_just_pressed("jump") and PLAYER.is_on_floor():
			transition.emit("JumpingPlayerState")

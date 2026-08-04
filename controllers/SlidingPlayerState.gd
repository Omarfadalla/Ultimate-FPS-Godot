class_name SlidingPlayerState
extends PlayerMovementState

@export var SPEED : float = 6.0
@export var ACCELERATION : float = 0.1
@export var DECELERATION : float = 0.25
@export var TILT_AMOUNT : float = 0.09
@export_range(1,6,0.1) var SLIDE_ANIM_SPEED: float = 4.0
@onready var CROUCH_SHAPECAST : ShapeCast3D = %ShapeCast3D

func enter(previous_state) -> void:
	set_tilt(PLAYER._current_rotation)
	ANIMATION.get_animation("Sliding").track_set_key_value(5,0,PLAYER.velocity.length())
	ANIMATION.speed_scale = 1.0
	ANIMATION.play("Sliding",-1.0,SLIDE_ANIM_SPEED)

	# BUG FIX: previously nothing ever called finish(), so the slide state
	# had no way to end itself once the animation finished — the player
	# would stay stuck in SlidingPlayerState indefinitely unless something
	# else forced a transition. Wait for the animation to finish, then
	# hand off to the next state.
	await ANIMATION.animation_finished
	finish()

func update(delta: float) -> void:
	PLAYER.update_gravity(delta)
	PLAYER.update_velocity()

	# BUG FIX: this was previously in _ready(), which only ever runs once
	# when the node first enters the tree — not every frame — so firing
	# while sliding almost never actually worked. Polling it in update()
	# means it's checked every physics frame the state is active.
	if Input.is_action_just_pressed("attack"):
		WEAPON._attack()

func set_tilt(player_rotation):
	var tilt = Vector3.ZERO
	tilt.z = clamp(TILT_AMOUNT * player_rotation,-0.1,0.1)
	if tilt.z == 0.0:
		tilt.z = 0.05
	ANIMATION.get_animation("Sliding").track_set_key_value(3,1,tilt)
	ANIMATION.get_animation("Sliding").track_set_key_value(3,2,tilt)

func finish() -> void:
	transition.emit("IdlePlayerState")

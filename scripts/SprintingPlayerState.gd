extends State

@export var ANIMATION : AnimationPlayer
@export var TOP_ANIM_SPEED : float = 1.6

func enter() -> void:
	ANIMATION.play("Sprinting",0.5,1.0)
	global.player._speed = global.player.SPEED_SPRINTING

func update(delta: float) -> void:
	set_animation_speed(global.player.velocity.length())

func set_animation_speed(spd):
	var alpha = remap(spd,0.0,global.player.SPEED_SPRINTING,0.0,1.0)
	ANIMATION.speed_scale = lerp(0.0,TOP_ANIM_SPEED,alpha)

func _input(event: InputEvent) -> void:
	if event.is_action_released("sprint"):
		transition.emit("WalkingPlayerState")

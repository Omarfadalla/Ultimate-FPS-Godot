class_name IdlePlayerState
extends State

@export var ANIMATION : AnimationPlayer


func enter() -> void:
	ANIMATION.pause()

func update(delta):
	if global.player.velocity.length() > 0 and global.player.is_on_floor():
		transition.emit("WalkingPlayerState") 

class_name WalkingPlayerState
extends State

func update(delta: float) -> void:
	if global.player and global.player.velocity.length() == 0:
		transition.emit("IdlePlayerState")

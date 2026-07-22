class_name IdlePlayerState

extends State



func update(delta):
	if global.player.velocity.length() > 0:
		transition.emit("WalkingPlayerState") 

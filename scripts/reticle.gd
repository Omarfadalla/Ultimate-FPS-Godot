extends CenterContainer

@export var RETICLE_LINES: Array[Line2D]
@export var PLAYER_CONTROLLER: CharacterBody3D
@export var RETICLE_SPEED: float = 3
@export var RETICLE_DISTANCE: float = 9.0
@export var DOT_RADIUS: float = 1.0
@export var DOT_COLOR: Color = Color.WHITE


func _ready() -> void:
	queue_redraw()


func _process(delta: float) -> void:
	adjust_reticle_lines()


func _draw():
	draw_circle(Vector2(0,0),DOT_RADIUS,DOT_COLOR)

func adjust_reticle_lines():
	var vel  = PLAYER_CONTROLLER.get_real_velocity()
	var origin = Vector3(0,0,0)
	var pos = Vector2(0,0)
	var speed = origin.distance_to(vel)

	#adjusting reticle line position 
	#top line
	RETICLE_LINES[0].position = lerp(RETICLE_LINES[0].position, pos + Vector2(0,-speed * RETICLE_DISTANCE),RETICLE_SPEED)
	#right line
	RETICLE_LINES[1].position = lerp(RETICLE_LINES[1].position, pos + Vector2(speed * RETICLE_DISTANCE , 0),RETICLE_SPEED)
	#bottom line
	RETICLE_LINES[2].position = lerp(RETICLE_LINES[2].position, pos + Vector2(0, speed * RETICLE_DISTANCE),RETICLE_SPEED)
	# left line
	RETICLE_LINES[3].position = lerp(RETICLE_LINES[3].position, pos + Vector2(-speed * RETICLE_DISTANCE, 0),RETICLE_SPEED)
	

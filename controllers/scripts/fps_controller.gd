class_name Player

extends CharacterBody3D


@export var SPEED_DEFAULT : float = 5.0
@export var SPEED_SPRINTING : float = 7.0
@export var SPEED_CROUCH : float = 2.0
@export var ACCELERATION : float = 0.1
@export var DECELERATION : float = 0.25
@export var MOUSE_SENSITIVITY : float = 0.5
@export var TILT_LOWER_LIMIT := deg_to_rad(-90.0)
@export var TILT_UPPER_LIMIT := deg_to_rad(90.0)
@export var CAMERA_CONTROLLER : Camera3D
@export var ANIMATIONPLAYER : AnimationPlayer
@export var CROUCH_SHAPECAST : Node3D
@export var WEAPON_CONTROLLER : WeaponController
@export var interact_distance : float = 2.0

## --- Health / Damage ---
@export var max_health: int = 100
@export var invulnerability_time: float = 0.5  # brief i-frames after a hit
@export var death_disables_movement: bool = true

signal health_changed(current_health: int, max_health: int)
signal damaged(amount: int)
signal died

var health: int
var is_dead: bool = false
var _invulnerable: bool = false


var _mouse_input : bool = false
var _rotation_input : float
var _tilt_input : float
var _mouse_rotation : Vector3
var _player_rotation : Vector3
var _camera_rotation : Vector3
var interact_cast_result

var _current_rotation: float
# Get the gravity from the project settings to be synced with RigidBody nodes.

var gravity = 12.0  

func _unhandled_input(event: InputEvent) -> void:
	_mouse_input = event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	if _mouse_input:
		_rotation_input = -event.relative.x * MOUSE_SENSITIVITY
		_tilt_input = -event.relative.y * MOUSE_SENSITIVITY

func _input(event):
	if event.is_action_pressed("exit"):
		get_tree().quit()
	if event.is_action_pressed("interact"):
		interact()

func update_camera(delta) -> void:
	_current_rotation = _rotation_input
	_mouse_rotation.x += _tilt_input * delta
	_mouse_rotation.x = clamp(_mouse_rotation.x, TILT_LOWER_LIMIT, TILT_UPPER_LIMIT)
	_mouse_rotation.y += _rotation_input * delta
	
	_player_rotation = Vector3(0.0,_mouse_rotation.y,0.0)
	_camera_rotation = Vector3(_mouse_rotation.x,0.0,0.0)

	CAMERA_CONTROLLER.transform.basis = Basis.from_euler(_camera_rotation)
	global_transform.basis = Basis.from_euler(_player_rotation)
	
	CAMERA_CONTROLLER.rotation.z = 0.0

	_rotation_input = 0.0
	_tilt_input = 0.0
	
func _ready():
	
	global.player = self
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var _speed = ACCELERATION
	_speed = SPEED_DEFAULT
	
	CROUCH_SHAPECAST.add_exception($".")

	# Health init
	health = max_health
	health_changed.emit(health, max_health)

	add_to_group("player")
	
func _physics_process(delta):
	
	global.debug.add_property("Velocity","%.2f" % velocity.length(), 2)
	
	update_camera(delta)
	interact_cast()
	
func update_gravity(delta) -> void:
	velocity.y -= gravity * delta
	
func update_input(speed: float, acceleration: float, deceleration: float) -> void:
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = lerp(velocity.x,direction.x * speed, acceleration)
		velocity.z = lerp(velocity.z,direction.z * speed, acceleration)
	else:
		velocity.x = move_toward(velocity.x, 0, deceleration)
		velocity.z = move_toward(velocity.z, 0, deceleration)
	
func update_velocity() -> void:
	move_and_slide()

func interact_cast() -> void:
	var camera = global.player.CAMERA_CONTROLLER
	var space_state = camera.get_world_3d().direct_space_state
	var screen_center = get_viewport().size / 2
	var orgin = camera.project_ray_origin(screen_center)
	var end = orgin + camera.project_ray_normal(screen_center) * interact_distance
	var query = PhysicsRayQueryParameters3D.create(orgin,end)
	query.collide_with_bodies = true
	var result = space_state.intersect_ray(query)
	var current_cast_result = result.get("collider")
	interact_cast_result = current_cast_result
func interact() -> void:
	if interact_cast_result: 
		print(interact_cast_result)


## --- Health / Damage ---

func take_damage(amount: int) -> void:
	if is_dead or _invulnerable:
		return

	health -= amount
	health = clamp(health, 0, max_health)

	damaged.emit(amount)
	health_changed.emit(health, max_health)

	if health <= 0:
		_die()
	else:
		_start_invulnerability()


func heal(amount: int) -> void:
	if is_dead:
		return

	health += amount
	health = clamp(health, 0, max_health)
	health_changed.emit(health, max_health)


func _start_invulnerability() -> void:
	_invulnerable = true
	await get_tree().create_timer(invulnerability_time).timeout
	_invulnerable = false


func _die() -> void:
	is_dead = true
	died.emit()

	if death_disables_movement:
		set_physics_process(false)
		set_process_unhandled_input(false)
		set_process_input(false)


func respawn(spawn_position: Vector3) -> void:
	is_dead = false
	health = max_health
	global_position = spawn_position
	health_changed.emit(health, max_health)
	set_physics_process(true)
	set_process_unhandled_input(true)
	set_process_input(true)

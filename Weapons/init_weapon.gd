@tool
class_name WeaponController
extends Node3D


@export var WEAPON_TYPE: Weapons:
	set(value):
		WEAPON_TYPE = value
		if Engine.is_editor_hint():
			load_weapon()

@export var sway_noise :NoiseTexture3D
@export var sway_speed :float = 1.2
@export var reset :bool = false:
	set(value):
		reset = value
		if Engine.is_editor_hint():
			load_weapon()


@onready var Weapon_mesh : MeshInstance3D = %WeaponMesh
@onready var Weapon_shadow : MeshInstance3D = %WeaponShadow

var mouse_movement : Vector2
var random_sway_x
var random_sway_y
var random_sway_amount : float
var time : float = 0.0
var idle_sway_adjustment
var idle_sway_rotation_strength
var weapon_bob_amount : Vector2 = Vector2(0,0)


func _ready() -> void:
	await  owner.ready
	load_weapon()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("weapon1"):
		WEAPON_TYPE = load("res://meshes/weapons/cowbar/crowbar.tres")
		load_weapon()
	if event.is_action_pressed("weapon2"):
		WEAPON_TYPE = load("res://meshes/weapons/cowbar/CrowbarL.tres")
		load_weapon()
	if event is InputEventMouseMotion:
		mouse_movement = event.relative

func load_weapon():
	Weapon_mesh.mesh = WEAPON_TYPE.mesh
	position = WEAPON_TYPE.position
	rotation_degrees = WEAPON_TYPE.rotation
	rotation_degrees = WEAPON_TYPE.rotation
	Weapon_shadow.visible = WEAPON_TYPE.shadow
	scale = WEAPON_TYPE.scale
	idle_sway_adjustment = WEAPON_TYPE.idle_sway_adjustment
	idle_sway_rotation_strength = WEAPON_TYPE.idle_sway_rotation_strength
	random_sway_amount = WEAPON_TYPE.randomw_sway_amount

func sway_weapon(delta,isIdle:bool):
	
	mouse_movement = mouse_movement.clamp( WEAPON_TYPE.sway_min, WEAPON_TYPE.sway_max)
	
	if isIdle:
		var sway_random :float = get_sway_noise()
		var sway_random_adjusted: float = sway_random * idle_sway_adjustment
	
		time += delta *( sway_speed + sway_random)
		random_sway_x = sin(time *1.5 + sway_random_adjusted) / random_sway_amount
		random_sway_y = sin(time - sway_random_adjusted) / random_sway_amount

		position.x = lerp(position.x,WEAPON_TYPE.position.x - (mouse_movement.x*
		WEAPON_TYPE.sway_amount_position + random_sway_x)*delta,WEAPON_TYPE.sway_speed_position)

		position.y = lerp(position.y,WEAPON_TYPE.position.y - (mouse_movement.y*
		WEAPON_TYPE.sway_amount_position + random_sway_y)*delta,WEAPON_TYPE.sway_speed_position)

		rotation_degrees.y = lerp(rotation_degrees.y,WEAPON_TYPE.rotation.y -
		(mouse_movement.y* WEAPON_TYPE.sway_amount_rotation +(random_sway_y * idle_sway_rotation_strength))*delta,WEAPON_TYPE.sway_speed_rotation)

		rotation_degrees.x = lerp(rotation_degrees.x,WEAPON_TYPE.rotation.x -
		(mouse_movement.x* WEAPON_TYPE.sway_amount_rotation + (random_sway_x * idle_sway_rotation_strength))*delta,WEAPON_TYPE.sway_speed_rotation)
	
	else:

		position.x = lerp(position.x,WEAPON_TYPE.position.x - (mouse_movement.x*
		WEAPON_TYPE.sway_amount_position + weapon_bob_amount.x)*delta,WEAPON_TYPE.sway_speed_position)

		position.y = lerp(position.y,WEAPON_TYPE.position.y - (mouse_movement.y*
		WEAPON_TYPE.sway_amount_position + weapon_bob_amount.y)*delta,WEAPON_TYPE.sway_speed_position)

		rotation_degrees.y = lerp(rotation_degrees.y,WEAPON_TYPE.rotation.y -
		(mouse_movement.y* WEAPON_TYPE.sway_amount_rotation)*delta,WEAPON_TYPE.sway_speed_rotation)

		rotation_degrees.x = lerp(rotation_degrees.x,WEAPON_TYPE.rotation.x -
		(mouse_movement.x* WEAPON_TYPE.sway_amount_rotation)*delta,WEAPON_TYPE.sway_speed_rotation)

func _weapon_bob(delta,bob_speed: float,hbob_amount: float,vbob_amount: float) -> void:
	time += delta
	weapon_bob_amount.x = sin(time * bob_speed) * hbob_amount 
	weapon_bob_amount.y = abs(cos(time * bob_speed) * vbob_amount)

func get_sway_noise() -> float:

	var player_position:Vector3 = Vector3(0,0,0)

	if not Engine.is_editor_hint():
		player_position = global.player.global_position
	
	var noise_location :float = sway_noise.noise.get_noise_2d(player_position.x,player_position.y)
	return noise_location

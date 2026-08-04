@tool
class_name WeaponController
extends Node3D

signal weapon_fired
signal ammo_changed(current_ammo: int, magazine_size: int)
signal reload_started
signal reload_finished

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

@export_group("Combat")
@export var attack_damage: int = 20
@export var magazine_size: int = 12
@export var reload_time: float = 1.2

@export_group("Visuals")
@export var bullet_hole_texture: Texture2D  # drag your decal texture in here
@export var damage_number_font: FontFile    # drag your font in here


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

var current_ammo: int
var is_reloading: bool = false

var raycast_test = preload("res://raycast_test.tscn")

func _ready() -> void:
	await  owner.ready
	load_weapon()

	current_ammo = magazine_size
	ammo_changed.emit(current_ammo, magazine_size)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("weapon1"):
		WEAPON_TYPE = load("res://meshes/weapons/weapon.tres")
		load_weapon()
	if event.is_action_pressed("weapon2"):
		WEAPON_TYPE = load("res://meshes/weapons/cowbar/CrowbarL.tres")
		load_weapon()
	if event is InputEventMouseMotion:
		mouse_movement = event.relative
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			_attack()
	# Requires a "reload" input action bound to a key (e.g. R) in
	# Project Settings > Input Map.
	if event.is_action_pressed("reload"):
		_reload()

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

func _attack():
	if is_reloading:
		return
	if current_ammo <= 0:
		_reload()  # optional: auto-reload on empty, remove if you don't want this
		return

	weapon_fired.emit()
	current_ammo -= 1
	ammo_changed.emit(current_ammo, magazine_size)

	var camera = global.player.CAMERA_CONTROLLER
	var space_state = camera.get_world_3d().direct_space_state
	var screen_center = get_viewport().size / 2
	var orgin = camera.project_ray_origin(screen_center)
	var end = orgin + camera.project_ray_normal(screen_center) *1000
	var query = PhysicsRayQueryParameters3D.create(orgin,end)
	query.collide_with_bodies = true
	var result = space_state.intersect_ray(query)
	if result:
		_bullet_hole(result.get("position"),result.get("normal"))
		var hit_collider = result.get("collider")
		if hit_collider and hit_collider.has_method("take_damage"):
			hit_collider.take_damage(attack_damage)
			_spawn_damage_number(attack_damage, result.get("position"))

## Reload "animation": the weapon tilts upward (rotates on its local X
## axis) and wobbles gently left-right (small Z rotation) while reloading,
## then settles back to its original rotation. Swap this out for
## anim.play("reload") later if you add a proper reload animation.
func _reload() -> void:
	if is_reloading or current_ammo == magazine_size:
		return

	is_reloading = true
	reload_started.emit()

	var start_rotation := rotation
	var lift_time := reload_time * 0.35
	var settle_time := reload_time - lift_time

	# Upward tilt, then back down.
	var lift_tween := create_tween()
	lift_tween.tween_property(self, "rotation:x", start_rotation.x - deg_to_rad(25), lift_time)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	lift_tween.tween_property(self, "rotation:x", start_rotation.x, settle_time)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	# Small left-right wobble (in degrees, very subtle) while reloading.
	var wobble_tween := create_tween()
	wobble_tween.tween_property(self, "rotation:z", start_rotation.z + deg_to_rad(3), reload_time * 0.2)
	wobble_tween.tween_property(self, "rotation:z", start_rotation.z - deg_to_rad(3), reload_time * 0.2)
	wobble_tween.tween_property(self, "rotation:z", start_rotation.z + deg_to_rad(1.5), reload_time * 0.2)
	wobble_tween.tween_property(self, "rotation:z", start_rotation.z, reload_time * 0.4)

	await get_tree().create_timer(reload_time).timeout

	rotation = start_rotation  # snap back cleanly in case of float drift
	current_ammo = magazine_size
	ammo_changed.emit(current_ammo, magazine_size)
	is_reloading = false
	reload_finished.emit()

## Bullet hole built directly in code as a small quad mesh instead of a
## Decal node, so it renders reliably on any surface (including the
## zombie) regardless of your project's rendering method.
func _bullet_hole(position: Vector3, normal: Vector3) -> void:
	var mesh_instance := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(0.25, 0.25)
	mesh_instance.mesh = quad

	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if bullet_hole_texture:
		mat.albedo_texture = bullet_hole_texture
		mat.albedo_color = Color(1, 1, 1, 1)
	else:
		mat.albedo_color = Color(0.05, 0.05, 0.05, 0.9)
	mesh_instance.material_override = mat

	get_tree().root.add_child(mesh_instance)
	mesh_instance.global_position = position + normal * 0.02  # avoid z-fighting

	var up_reference := Vector3.UP
	if abs(normal.dot(up_reference)) > 0.99:
		up_reference = Vector3.RIGHT
	mesh_instance.look_at(mesh_instance.global_position + normal, up_reference)

	await get_tree().create_timer(1).timeout
	var fade = get_tree().create_tween()
	fade.tween_property(mat, "albedo_color:a", 0.0, 0.2)
	await get_tree().create_timer(0.2).timeout
	mesh_instance.queue_free()

## Floating damage number that pops up where the shot landed and drifts
## upward while fading out. Uses damage_number_font if you assign one.
func _spawn_damage_number(amount: int, at_position: Vector3) -> void:
	var label := Label3D.new()
	label.text = str(amount)
	label.modulate = Color(1.0, 0.15, 0.15)
	label.font_size = 56
	label.outline_size = 10
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.pixel_size = 0.01
	if damage_number_font:
		label.font = damage_number_font

	get_tree().root.add_child(label)
	label.global_position = at_position + Vector3(0, 0.25, 0)

	var tween := get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "global_position:y", label.global_position.y + 1.0, 0.7)
	tween.tween_property(label, "modulate:a", 0.0, 0.7)
	tween.finished.connect(label.queue_free)

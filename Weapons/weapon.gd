extends Node3D

@export var WEAPON_TYPE: Weapons

@onready var Weapon_mesh : MeshInstance3D = %WeaponMesh
@onready var Weapon_shadow : MeshInstance3D = %WeaponShadow

func _ready() -> void:
	load_weapon()
	
func load_weapon():
	Weapon_mesh.mesh = WEAPON_TYPE.mesh
	position = WEAPON_TYPE.position
	rotation_degrees = WEAPON_TYPE.rotation
	rotation_degress = WEAPON_TYPE.rotation
	Weapon_shadow.visible = WEAPON_TYPE.shadow

extends CharacterBody3D

## ZOMBIE AI
## Attach this to your zombie's root CharacterBody3D node.
##
## Required child nodes (create these in the editor, matching these names
## or update the @onready paths below):
##   - AnimationPlayer      (with animations: "idle", "walk", "attack", "death")
##   - NavigationAgent3D    (for pathfinding around obstacles)
##   - AttackArea (Area3D)  (a small Area3D in front of the zombie with a
##                           CollisionShape3D, used to detect when the
##                           player is close enough to actually hit)
##
## Your player scene must be in the "player" group, and must have a
## method called take_damage(amount: int) on it (see player_health.gd).

enum State { IDLE, CHASE, ATTACK, DEAD }

@export_group("Stats")
@export var max_health: int = 100
@export var move_speed: float = 3.0
@export var attack_damage: int = 15
@export var attack_cooldown: float = 1.2   # seconds between attacks
@export var detection_radius: float = 10.0 # how far the zombie can "see"
@export var attack_range: float = 1.8      # distance at which it stops and attacks
@export var lose_interest_radius: float = 14.0 # gives up chase beyond this

@export_group("Nodes")
@export var animation_player_path: NodePath = "AnimationPlayer"
@export var nav_agent_path: NodePath = "NavigationAgent3D"
@export var attack_area_path: NodePath = "AttackArea"

var health: int
var state: State = State.IDLE
var player: Node3D = null
var can_attack: bool = true
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var anim: AnimationPlayer = get_node(animation_player_path)
@onready var nav_agent: NavigationAgent3D = get_node(nav_agent_path)
@onready var attack_area: Area3D = get_node(attack_area_path)


func _ready() -> void:
	health = max_health
	nav_agent.path_desired_distance = 0.5
	nav_agent.target_desired_distance = attack_range * 0.8

	# Find the player once at startup (assumes a single player in the "player" group).
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

	_play_anim("idle")


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return

	if not is_on_floor():
		velocity.y -= gravity * delta

	match state:
		State.IDLE:
			_process_idle()
		State.CHASE:
			_process_chase(delta)
		State.ATTACK:
			_process_attack()

	move_and_slide()


func _process_idle() -> void:
	velocity.x = 0
	velocity.z = 0

	if player == null:
		return

	if global_position.distance_to(player.global_position) <= detection_radius:
		_change_state(State.CHASE)


func _process_chase(delta: float) -> void:
	if player == null:
		_change_state(State.IDLE)
		return

	var dist := global_position.distance_to(player.global_position)

	# Player wandered too far away, give up and go back to idle.
	if dist > lose_interest_radius:
		_change_state(State.IDLE)
		return

	# Close enough to attack.
	if dist <= attack_range:
		_change_state(State.ATTACK)
		return

	nav_agent.target_position = player.global_position

	if not nav_agent.is_navigation_finished():
		var next_point: Vector3 = nav_agent.get_next_path_position()
		var direction := (next_point - global_position)
		direction.y = 0
		direction = direction.normalized()

		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed

		_face_direction(direction)


func _process_attack() -> void:
	velocity.x = 0
	velocity.z = 0

	if player == null:
		_change_state(State.IDLE)
		return

	var dist := global_position.distance_to(player.global_position)
	_face_direction((player.global_position - global_position).normalized())

	# Player stepped out of range mid-attack-state; go back to chasing.
	if dist > attack_range * 1.3:
		_change_state(State.CHASE)
		return

	if can_attack:
		_perform_attack()


func _perform_attack() -> void:
	can_attack = false
	_play_anim("attack")

	# Wait roughly until the "hit" moment in your animation before dealing damage.
	# Adjust this delay to match the frame where the zombie's swing connects.
	await get_tree().create_timer(0.4).timeout

	if state == State.DEAD:
		return

	# Only actually damage the player if they're still within the AttackArea.
	if attack_area.overlaps_body(player):
		if player.has_method("take_damage"):
			player.take_damage(attack_damage)

	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true


func take_damage(amount: int) -> void:
	if state == State.DEAD:
		return

	health -= amount
	health = max(health, 0)

	if health <= 0:
		_die()
	else:
		# Optional: interrupt current action, aggro the player if not already.
		if player != null and state == State.IDLE:
			_change_state(State.CHASE)


func _die() -> void:
	_change_state(State.DEAD)
	velocity = Vector3.ZERO
	_play_anim("death")
	set_physics_process(false)

	# Disable collisions so the corpse doesn't keep blocking navigation/attacks.
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)

	# Optional: remove the body after the death animation finishes.
	await get_tree().create_timer(4.0).timeout
	queue_free()


func _change_state(new_state: State) -> void:
	if state == new_state:
		return
	state = new_state

	match state:
		State.IDLE:
			_play_anim("idle")
		State.CHASE:
			_play_anim("walk")
		State.ATTACK:
			pass # handled by _perform_attack()
		State.DEAD:
			pass # handled by _die()


func _face_direction(direction: Vector3) -> void:
	if direction.length() < 0.01:
		return
	var target_angle := atan2(direction.x, direction.z)
	rotation.y = lerp_angle(rotation.y, target_angle, 0.15)


func _play_anim(anim_name: String) -> void:
	if anim.has_animation(anim_name) and anim.current_animation != anim_name:
		anim.play(anim_name)

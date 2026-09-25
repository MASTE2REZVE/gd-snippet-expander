@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"snippets": {
			"flying_enemy_3d": {
				"phrases": ["flying enemy 3d", "3d flying enemy", "flying ai 3d", "drone enemy"],
				"code": """extends CharacterBody3D

signal died

@export var speed: float = 6.0
@export var hover_amplitude: float = 0.3
@export var hover_speed: float = 2.0
@export var attack_range: float = 8.0
@export var attack_damage: int = 10
@export var attack_cooldown: float = 1.5
@export var target_path: NodePath

var _time: float = 0.0
var _hover_origin: float = 0.0
var _attack_timer: float = 0.0
@onready var _target: Node3D = get_node_or_null(target_path)

func _ready() -> void:
	_hover_origin = global_position.y
	if _target == null:
		_find_player()

func _find_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		_target = players[0]

func _physics_process(delta: float) -> void:
	_time += delta * hover_speed
	_attack_timer = maxf(_attack_timer - delta, 0.0)
	if _target == null or not is_instance_valid(_target):
		_move_and_hover(delta, Vector3.ZERO)
		return
	var to_target := _target.global_position - global_position
	var flat := Vector3(to_target.x, 0, to_target.z)
	var dist := flat.length()
	if dist < attack_range and _attack_timer <= 0.0:
		_attack()
		_attack_timer = attack_cooldown
	var move_dir := flat.normalized() if dist > attack_range * 0.8 else Vector3.ZERO
	_move_and_hover(delta, move_dir)

func _move_and_hover(delta: float, move_dir: Vector3) -> void:
	velocity.x = move_dir.x * speed
	velocity.z = move_dir.z * speed
	var target_y: float = _hover_origin + sin(_time) * hover_amplitude
	velocity.y = (target_y - global_position.y) * 5.0
	move_and_slide()

func _attack() -> void:
	if _target == null or not _target.has_method("take_damage"):
		return
	_target.call("take_damage", attack_damage)

func take_damage(_amount: int) -> void:
	died.emit()
	queue_free()
""",
				"params": ["speed", "hover_amplitude", "attack_range", "attack_damage", "attack_cooldown"],
				"category": "enemy",
				"subcategory": "3d",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "intermediate",
				"param_info": {
					"speed": {
						"default": 6.0,
						"range": [1.0, 20.0],
						"what": "Movement speed in meters per second.",
						"typical": "3 slow drone / 6 standard / 12+ fast",
						"increase": "Faster.",
						"decrease": "Slower."
					},
					"attack_range": {
						"default": 8.0,
						"range": [2.0, 30.0],
						"what": "Distance at which the enemy attacks.",
						"typical": "4 melee range / 8 standard / 20+ ranged",
						"increase": "Attacks from further.",
						"decrease": "Must be closer."
					}
				},
				"details": {
					"what": "3D flying enemy that hovers and chases the player, ignoring gravity. Drones, bats, floating orbs.",
					"where": "CharacterBody3D with CollisionShape3D and MeshInstance3D. Player in group 'player' or assigned via target_path.",
					"before": "CollisionShape3D sized to the enemy. Target with take_damage method.",
					"after": "Add a projectile attack instead of melee — see enemy turret for ranged options.",
					"why_optimized": "Sine-based hover, direct velocity. No gravity, no physics raycasts.",
					"mistakes": "Using is_on_floor() in a flying enemy causes errors — flying enemies never touch the floor.",
					"related": ["health_system", "loot_table", "enemy_chaser_3d"]
				}
			},
			"turret_enemy_3d": {
				"phrases": ["turret 3d", "3d turret", "gun turret 3d", "stationary shooter 3d"],
				"code": """extends StaticBody3D

signal fired(direction: Vector3)

@export var projectile_scene: PackedScene
@export var fire_rate: float = 1.5
@export var range: float = 30.0
@export var rotate_horizontal_only: bool = true
@export var rotate_speed: float = 4.0
@export var burst_count: int = 1

@onready var _yaw_pivot: Node3D = get_node_or_null("YawPivot")
@onready var _muzzle: Node3D = get_node_or_null("YawPivot/Muzzle")

var _fire_timer: float = 0.0
var _target: Node3D = null
var _target_direction: Vector3 = Vector3.FORWARD

func _ready() -> void:
	_find_player()

func _find_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		_target = players[0]

func _physics_process(delta: float) -> void:
	_fire_timer = maxf(_fire_timer - delta, 0.0)
	if _target == null or not is_instance_valid(_target):
		return
	var to_target := _target.global_position - global_position
	if to_target.length() > range:
		return
	_target_direction = to_target.normalized()
	_rotate_toward(delta, to_target)
	if _fire_timer <= 0.0:
		_fire_burst()
		_fire_timer = fire_rate

func _rotate_toward(delta: float, to_target: Vector3) -> void:
	if _yaw_pivot == null:
		return
	var target_yaw: float = atan2(to_target.x, to_target.z)
	_yaw_pivot.rotation.y = lerp_angle(_yaw_pivot.rotation.y, target_yaw, rotate_speed * delta)
	if not rotate_horizontal_only:
		var horizontal := Vector3(to_target.x, 0, to_target.z)
		var target_pitch: float = -atan2(to_target.y, horizontal.length())
		_yaw_pivot.rotation.x = lerp_angle(_yaw_pivot.rotation.x, target_pitch, rotate_speed * delta)

func _fire_burst() -> void:
	for i in range(burst_count):
		if i > 0:
			await get_tree().create_timer(0.1).timeout
		_spawn_projectile()

func _spawn_projectile() -> void:
	if projectile_scene == null:
		return
	var bullet := projectile_scene.instantiate() as Node3D
	get_tree().current_scene.add_child(bullet)
	var spawn_pos := global_position if _muzzle == null else _muzzle.global_position
	bullet.global_position = spawn_pos
	if bullet.has_method("setup"):
		bullet.call("setup", _target_direction)
	fired.emit(_target_direction)

func take_damage(_amount: int) -> void:
	queue_free()
""",
				"params": ["fire_rate", "range", "rotate_speed", "burst_count"],
				"category": "enemy",
				"subcategory": "3d",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "intermediate",
				"param_info": {
					"fire_rate": {
						"default": 1.5,
						"range": [0.2, 5.0],
						"what": "Seconds between bursts.",
						"typical": "0.5 aggressive / 1.5 standard / 3.0 slow",
						"increase": "Slower fire.",
						"decrease": "Faster."
					},
					"range": {
						"default": 30.0,
						"range": [5.0, 100.0],
						"what": "Detection range in meters.",
						"typical": "10 short / 30 standard / 60+ long",
						"increase": "Fires from further.",
						"decrease": "Closer."
					},
					"rotate_horizontal_only": {
						"default": true,
						"range": [],
						"what": "Whether to only rotate on the Y axis (tanks, wall turrets) or full pitch.",
						"typical": "true for most turrets / false for AA guns",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "3D turret that rotates to aim and fires projectiles. Works for wall-mounted, ceiling, or floor turrets.",
					"where": "StaticBody3D with a 'YawPivot' Node3D child and optionally a 'Muzzle' Marker3D. Attach the script to the root.",
					"before": "Projectile scene with a setup(direction) method. See projectile_3d snippet.",
					"after": "Add muzzle flash particles and a firing sound. Add a target-lost timeout so the turret returns to idle rotation.",
					"why_optimized": "Rotation uses lerp_angle — no gimbal lock. Only processes when player is in range.",
					"mistakes": "Rotating the turret root instead of a pivot node means the base rotates too. Use a YawPivot child.",
					"related": ["projectile_3d", "ranged_attack", "enemy_chaser_3d"]
				}
			},
			"jumper_enemy_3d": {
				"phrases": ["jumper enemy 3d", "3d jumping enemy", "3d hopper", "jumping ai 3d"],
				"code": """extends CharacterBody3D

signal died

@export var jump_velocity: float = 8.0
@export var forward_speed: float = 5.0
@export var gravity: float = 24.0
@export var jump_cooldown: float = 1.2
@export var chase_player: bool = true

var _jump_timer: float = 0.0
var _jump_direction: Vector3 = Vector3.FORWARD
var _target: Node3D = null

func _ready() -> void:
	if chase_player:
		_find_player()

func _find_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		_target = players[0]

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	_jump_timer = maxf(_jump_timer - delta, 0.0)
	if is_on_floor() and _jump_timer <= 0.0:
		_prepare_jump()
	if is_on_floor():
		var horizontal := Vector3(_jump_direction.x, 0, _jump_direction.z).normalized()
		velocity.x = horizontal.x * forward_speed
		velocity.z = horizontal.z * forward_speed
	move_and_slide()

func _prepare_jump() -> void:
	if _target != null and is_instance_valid(_target):
		var to_target := _target.global_position - global_position
		to_target.y = 0.0
		if to_target.length() > 0.1:
			_jump_direction = to_target.normalized()
	else:
		var angle := randf() * TAU
		_jump_direction = Vector3(cos(angle), 0, sin(angle))
	velocity.y = jump_velocity
	_jump_timer = jump_cooldown
	_squash_and_jump()

func _squash_and_jump() -> void:
	var mesh := get_node_or_null("MeshInstance3D")
	if mesh == null:
		return
	var base := mesh.scale
	var tween := create_tween()
	tween.tween_property(mesh, "scale", base * Vector3(1.2, 0.8, 1.2), 0.05)
	tween.tween_property(mesh, "scale", base, 0.15)

func take_damage(_amount: int) -> void:
	died.emit()
	queue_free()
""",
				"params": ["jump_velocity", "forward_speed", "jump_cooldown", "chase_player"],
				"category": "enemy",
				"subcategory": "3d",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "intermediate",
				"param_info": {
					"jump_velocity": {
						"default": 8.0,
						"range": [3.0, 20.0],
						"what": "Upward jump speed in meters per second.",
						"typical": "5 small hop / 8 standard / 15+ huge",
						"increase": "Higher jumps.",
						"decrease": "Lower."
					},
					"forward_speed": {
						"default": 5.0,
						"range": [1.0, 15.0],
						"what": "Horizontal speed during the jump.",
						"typical": "2 slow / 5 standard / 10+ aggressive",
						"increase": "Faster.",
						"decrease": "Slower."
					}
				},
				"details": {
					"what": "3D jumping enemy that hops toward the player. Uses CharacterBody3D and manual gravity for predictable arcs.",
					"where": "CharacterBody3D with CollisionShape3D and MeshInstance3D child. Player in group 'player'.",
					"before": "Floor collision so the enemy can detect landing.",
					"after": "Add landing dust particles and a thud sound. See particle_dust.",
					"why_optimized": "Manual gravity application only when airborne. Landing check uses the engine's is_on_floor().",
					"mistakes": "Setting forward_speed too high makes the enemy overshoot and miss the player each jump.",
					"related": ["health_system", "particle_dust", "enemy_types_2d"]
				}
			},
			"exploder_enemy_3d": {
				"phrases": ["exploder enemy 3d", "3d exploder", "kamikaze 3d", "suicide bomber 3d"],
				"code": """extends CharacterBody3D

signal exploded(position: Vector3, damage: int)
signal died

@export var speed: float = 8.0
@export var trigger_range: float = 3.0
@export var fuse_time: float = 1.0
@export var blast_radius: float = 5.0
@export var blast_damage: int = 40
@export var gravity: float = 24.0

var _state: String = "idle"
var _fuse_timer: float = 0.0
var _target: Node3D = null
@onready var _mesh: MeshInstance3D = get_node_or_null("MeshInstance3D")

func _ready() -> void:
	_find_player()

func _find_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		_target = players[0]

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	if _state == "idle":
		_chase()
	elif _state == "fusing":
		_fuse_timer -= delta
		_flash()
		if _fuse_timer <= 0.0:
			_explode()
	move_and_slide()

func _chase() -> void:
	if _target == null or not is_instance_valid(_target):
		velocity.x = 0.0
		velocity.z = 0.0
		return
	var to_target := _target.global_position - global_position
	to_target.y = 0.0
	var dist := to_target.length()
	if dist < trigger_range:
		_start_fuse()
		return
	var dir := to_target.normalized()
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed

func _start_fuse() -> void:
	_state = "fusing"
	_fuse_timer = fuse_time
	velocity.x = 0.0
	velocity.z = 0.0

func _flash() -> void:
	if _mesh == null:
		return
	var t: float = fmod(_fuse_timer * 10.0, 2.0)
	_mesh.modulate = Color(1, 0.3, 0.3) if t < 1.0 else Color.WHITE

func _explode() -> void:
	var space := get_world_3d().direct_space_state
	var shape := SphereShape3D.new()
	shape.radius = blast_radius
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis(), global_position)
	var results := space.intersect_shape(query, 32)
	for result in results:
		var collider = result.get("collider")
		if collider != null and collider.has_method("take_damage"):
			var dist := global_position.distance_to((collider as Node3D).global_position)
			var falloff: float = clampf(1.0 - dist / blast_radius, 0.3, 1.0)
			collider.take_damage(int(float(blast_damage) * falloff))
	exploded.emit(global_position, blast_damage)
	died.emit()
	queue_free()

func take_damage(_amount: int) -> void:
	died.emit()
	queue_free()
""",
				"params": ["speed", "trigger_range", "fuse_time", "blast_radius", "blast_damage"],
				"category": "enemy",
				"subcategory": "3d",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "intermediate",
				"param_info": {
					"trigger_range": {
						"default": 3.0,
						"range": [1.0, 10.0],
						"what": "Distance at which the fuse starts, in meters.",
						"typical": "2 close / 3 standard / 6+ ranged",
						"increase": "Starts fuse from further.",
						"decrease": "Closer."
					},
					"fuse_time": {
						"default": 1.0,
						"range": [0.3, 3.0],
						"what": "Seconds before detonation.",
						"typical": "0.5 fast / 1.0 standard / 2.0 slow",
						"increase": "Longer warning.",
						"decrease": "Shorter."
					},
					"blast_radius": {
						"default": 5.0,
						"range": [2.0, 15.0],
						"what": "Explosion radius in meters.",
						"typical": "3 small / 5 standard / 10+ huge",
						"increase": "Bigger blast.",
						"decrease": "Smaller."
					}
				},
				"details": {
					"what": "3D kamikaze enemy that chases the player, starts a fuse, and explodes. Has visual flash warning.",
					"where": "CharacterBody3D with CollisionShape3D and MeshInstance3D. Player in group 'player'.",
					"before": "Sphere query on explosion — works with any colliders that have take_damage.",
					"after": "Add explosion particles, screen shake, and hitstop for the full impact.",
					"why_optimized": "Single sphere query on explosion. Chase uses flat direction (ignores Y).",
					"mistakes": "No fuse warning makes the enemy feel unfair. The flashing mesh is the telegraph.",
					"related": ["rocket_3d", "hit_feedback_3d", "particle_explosion"]
				}
			},
			"splitter_enemy_3d": {
				"phrases": ["splitter enemy 3d", "3d splitter", "3d splitting enemy", "slime split 3d"],
				"code": """extends CharacterBody3D

signal split_into_children(positions: Array)
signal died

@export var size_tier: int = 2
@export var speed: float = 4.0
@export var split_count: int = 2
@export var min_size_tier: int = 1
@export var child_scene: PackedScene
@export var max_health: int = 15
@export var gravity: float = 24.0

var health: int = max_health
var _target: Node3D = null

func _ready() -> void:
	health = max_health
	_apply_size()
	_find_player()

func _find_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		_target = players[0]

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	if _target == null or not is_instance_valid(_target):
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return
	var to_target := _target.global_position - global_position
	to_target.y = 0.0
	var dir := to_target.normalized()
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	move_and_slide()

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		_die()

func _die() -> void:
	if size_tier > min_size_tier and child_scene != null:
		_spawn_children()
	died.emit()
	queue_free()

func _spawn_children() -> void:
	var positions: Array = []
	for i in range(split_count):
		var angle: float = TAU * float(i) / float(split_count) + randf_range(-0.3, 0.3)
		var offset := Vector3(cos(angle), 0, sin(angle)) * 1.0
		var child := child_scene.instantiate()
		child.set("size_tier", size_tier - 1)
		child.set("child_scene", child_scene)
		child.set("min_size_tier", min_size_tier)
		get_tree().current_scene.add_child(child)
		child.global_position = global_position + offset
		positions.append(child.global_position)
	split_into_children.emit(positions)

func _apply_size() -> void:
	var size_scale: float = 0.5 + 0.2 * float(size_tier)
	scale = Vector3(size_scale, size_scale, size_scale)
	max_health = max_health * size_tier / 2
	speed = speed * (1.5 - 0.15 * float(size_tier))
""",
				"params": ["size_tier", "speed", "split_count", "min_size_tier", "max_health"],
				"category": "enemy",
				"subcategory": "3d",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "advanced",
				"param_info": {
					"size_tier": {
						"default": 2,
						"range": [1, 5],
						"what": "Current size tier. Children spawn one tier smaller.",
						"typical": "1 smallest / 2 standard / 3 big",
						"increase": "Bigger starting enemy.",
						"decrease": "Smaller."
					},
					"split_count": {
						"default": 2,
						"range": [2, 6],
						"what": "Number of children spawned on death.",
						"typical": "2 simple / 3 standard / 4+ swarm",
						"increase": "More children.",
						"decrease": "Fewer."
					}
				},
				"details": {
					"what": "3D enemy that splits into smaller copies when killed. Recurses until min_size_tier.",
					"where": "CharacterBody3D saved as its own .tscn (self-reference for child_scene). Set child_scene to that same scene.",
					"before": "The enemy scene must be saved as a standalone .tscn so it can instantiate itself.",
					"after": "Add a spawn pop effect (scale tween) so children visually appear instead of teleporting in.",
					"why_optimized": "Health and size derive from size_tier. No per-instance tuning.",
					"mistakes": "Setting child_scene without saving the scene first causes an infinite load loop.",
					"related": ["health_system", "squash_stretch", "particle_explosion"]
				}
			},
			"shielded_enemy_3d": {
				"phrases": ["shielded enemy 3d", "3d shielded", "3d shield enemy", "armored 3d"],
				"code": """extends CharacterBody3D

signal shield_broken
signal shield_recharged
signal died

@export var speed: float = 4.0
@export var max_health: int = 30
@export var shield_health: int = 40
@export var shield_recharge_delay: float = 3.0
@export var shield_recharge_rate: float = 8.0
@export var gravity: float = 24.0

var health: int = max_health
var shield: int = shield_health
var _recharge_timer: float = 0.0
var _target: Node3D = null

@onready var _shield_mesh: MeshInstance3D = get_node_or_null("ShieldMesh")

func _ready() -> void:
	health = max_health
	shield = shield_health
	_find_player()

func _find_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		_target = players[0]

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	if _target != null and is_instance_valid(_target):
		var to_target := _target.global_position - global_position
		to_target.y = 0.0
		var dir := to_target.normalized()
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
	move_and_slide()
	_update_shield(delta)

func _update_shield(delta: float) -> void:
	var was_empty := shield <= 0
	if shield <= 0:
		if _recharge_timer > 0.0:
			_recharge_timer -= delta
		elif shield_health > 0:
			shield = mini(shield + int(shield_recharge_rate * delta * 10.0), shield_health)
			if was_empty and shield > 0:
				shield_recharged.emit()
	if _shield_mesh != null:
		_shield_mesh.visible = shield > 0
		var ratio: float = float(shield) / float(shield_health)
		_shield_mesh.modulate = Color(0.3, 0.7, 1.0, 0.3 + 0.4 * ratio)

func take_damage(amount: int) -> void:
	if shield > 0:
		shield -= amount
		_recharge_timer = shield_recharge_delay
		if shield <= 0:
			shield = 0
			shield_broken.emit()
		return
	health -= amount
	if health <= 0:
		died.emit()
		queue_free()

func is_shielded() -> bool:
	return shield > 0

func get_shield_ratio() -> float:
	return float(shield) / float(shield_health)
""",
				"params": ["speed", "max_health", "shield_health", "shield_recharge_delay", "shield_recharge_rate"],
				"category": "enemy",
				"subcategory": "3d",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "intermediate",
				"param_info": {
					"shield_health": {
						"default": 40,
						"range": [5, 300],
						"what": "How much damage the shield absorbs.",
						"typical": "15 weak / 40 standard / 150+ tanky",
						"increase": "Stronger shield.",
						"decrease": "Weaker."
					},
					"shield_recharge_delay": {
						"default": 3.0,
						"range": [0.0, 15.0],
						"what": "Seconds before the shield regenerates.",
						"typical": "1.0 aggressive / 3.0 standard / 10.0+ patient",
						"increase": "Slower recharge.",
						"decrease": "Faster."
					}
				},
				"details": {
					"what": "3D enemy with a recharging shield. Shield absorbs damage first, then breaks. Optional shield visual child.",
					"where": "CharacterBody3D with CollisionShape3D, MeshInstance3D, and optional ShieldMesh child.",
					"before": "ShieldMesh can be a transparent sphere or a shader-driven effect.",
					"after": "Add shield shatter particles when shield_broken fires.",
					"why_optimized": "Recharge only runs when the shield is depleted. One visual property per frame.",
					"mistakes": "Shield regeneration without a delay means the shield never breaks in single-target fights.",
					"related": ["health_system", "shader_dissolve", "shielded_enemy_2d"]
				}
			}
		}
	}

@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"snippets": {
			"spread_shot": {
				"phrases": ["spread shot", "shotgun", "fan shot", "multiple bullets"],
				"code": """@export var projectile_scene: PackedScene
@export var projectile_count: int = 5
@export var spread_angle: float = 45.0
@export var spawn_offset: float = 20.0

func fire_spread(direction: Vector2) -> void:
	if projectile_scene == null:
		return
	var half_spread := deg_to_rad(spread_angle) * 0.5
	var base_angle := direction.angle()
	for i in range(projectile_count):
		var t: float = 0.0
		if projectile_count > 1:
			t = float(i) / float(projectile_count - 1)
		var angle := base_angle - half_spread + (t * half_spread * 2.0)
		var dir := Vector2.RIGHT.rotated(angle)
		_spawn_projectile(dir)

func _spawn_projectile(dir: Vector2) -> void:
	var bullet := projectile_scene.instantiate() as Node2D
	if bullet == null:
		return
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = global_position + dir * spawn_offset
	bullet.rotation = dir.angle()
	if bullet.get("direction") != null:
		bullet.set("direction", dir)
""",
				"params": ["projectile_scene", "projectile_count", "spread_angle", "spawn_offset"],
				"category": "projectile",
				"subcategory": "patterns",
				"dimension": "2d",
				"difficulty": "beginner",
				"param_info": {
					"projectile_count": {
						"default": 5,
						"range": [2, 20],
						"what": "Number of projectiles in the fan.",
						"typical": "3 pistol spread / 5 shotgun / 12 wide fan",
						"increase": "Wider coverage.",
						"decrease": "Tighter grouping."
					},
					"spread_angle": {
						"default": 45.0,
						"range": [5.0, 180.0],
						"what": "Total arc in degrees the projectiles cover.",
						"typical": "15 tight / 45 standard / 90 wide",
						"increase": "Wider spread.",
						"decrease": "Tighter."
					},
					"spawn_offset": {
						"default": 20.0,
						"range": [0.0, 100.0],
						"what": "Distance from origin where bullets spawn.",
						"typical": "10 pistol / 20 standard / 40 long-barrel",
						"increase": "Bullets spawn further out.",
						"decrease": "Closer to origin."
					}
				},
				"details": {
					"what": "Fires multiple projectiles in a fan pattern. Classic shotgun or spread attack.",
					"where": "Attach to the shooter. Call fire_spread(direction) when the player attacks.",
					"before": "A projectile scene. The projectile should accept a 'direction' property or read rotation.",
					"after": "Randomize the spread slightly per shot for a more organic feel.",
					"why_optimized": "Pre-computes angles once. No per-projectile trigonometry beyond one rotated() call.",
					"mistakes": "Using the same offset for all projectiles makes them spawn in a line. Rotation of the direction handles it.",
					"related": ["ranged_attack", "projectile", "burst_shot"]
				}
			},
			"homing_projectile": {
				"phrases": ["homing missile", "homing projectile", "tracking bullet", "guided missile"],
				"code": """extends Area2D

@export var speed: float = 300.0
@export var turn_speed: float = 4.0
@export var damage: int = 10
@export var lifetime: float = 4.0
@export var target_group: String = "enemy"

var _target: Node2D = null
var _direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(lifetime).timeout.connect(queue_free)
	_acquire_target()

func _acquire_target() -> void:
	var best: Node2D = null
	var best_dist: float = INF
	for node in get_tree().get_nodes_in_group(target_group):
		if not (node is Node2D):
			continue
		var d := global_position.distance_to((node as Node2D).global_position)
		if d < best_dist:
			best_dist = d
			best = node as Node2D
	_target = best

func _physics_process(delta: float) -> void:
	if _target != null and is_instance_valid(_target):
		var desired := (_target.global_position - global_position).normalized()
		_direction = _direction.lerp(desired, turn_speed * delta).normalized()
	position += _direction * speed * delta
	rotation = _direction.angle()

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()
""",
				"params": ["speed", "turn_speed", "damage", "lifetime", "target_group"],
				"category": "projectile",
				"subcategory": "patterns",
				"dimension": "2d",
				"difficulty": "intermediate",
				"param_info": {
					"turn_speed": {
						"default": 4.0,
						"range": [0.5, 20.0],
						"what": "How fast the projectile turns toward the target.",
						"typical": "1 lazy / 4 standard / 12 aggressive",
						"increase": "Tighter tracking.",
						"decrease": "Looser, miss-able."
					},
					"target_group": {
						"default": "enemy",
						"range": [],
						"what": "Which group to home toward.",
						"typical": "enemy for player bullets / player for enemy bullets",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "Projectile that curves toward the nearest target in a group. Uses lerp on the direction vector for smooth turning.",
					"where": "Attach to an Area2D. Assign the projectile scene from ranged_attack.",
					"before": "Targets in a group (e.g. 'enemy'). Projectile scene set up like a regular bullet.",
					"after": "Re-acquire targets if the current one is freed. Add a small particle exhaust for visual interest.",
					"why_optimized": "Only re-acquires targets once on _ready. If the target dies, it flies straight instead of scanning each frame.",
					"mistakes": "Scanning for targets every frame is expensive with many enemies. Acquire once and reuse.",
					"related": ["projectile", "spread_shot", "enemy_patrol"]
				}
			},
			"boomerang_projectile": {
				"phrases": ["boomerang", "return projectile", "back and forth bullet", "returning projectile"],
				"code": """extends Area2D

@export var speed: float = 400.0
@export var out_distance: float = 300.0
@export var damage: int = 15
@export var return_speed_multiplier: float = 1.2
@export var catch_radius: float = 24.0

enum Phase { OUT, RETURN }
var _phase: int = Phase.OUT
var _origin: Vector2 = Vector2.ZERO
var _direction: Vector2 = Vector2.RIGHT
var _traveled: float = 0.0
var _thrower: Node2D = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_origin = global_position
	if _thrower == null:
		_thrower = _find_thrower()

func setup(dir: Vector2, thrower: Node2D) -> void:
	_direction = dir.normalized()
	_thrower = thrower
	rotation = _direction.angle()

func _physics_process(delta: float) -> void:
	if _phase == Phase.OUT:
		var step := speed * delta
		position += _direction * step
		_traveled += step
		if _traveled >= out_distance:
			_phase = Phase.RETURN
	else:
		if _thrower == null or not is_instance_valid(_thrower):
			queue_free()
			return
		var back := (_thrower.global_position - global_position)
		if back.length() < catch_radius:
			queue_free()
			return
		var return_dir := back.normalized()
		position += return_dir * speed * return_speed_multiplier * delta
		rotation = return_dir.angle()

func _on_body_entered(body: Node2D) -> void:
	if body == _thrower:
		return
	if body.has_method("take_damage"):
		body.take_damage(damage)

func _find_thrower() -> Node2D:
	var p := get_parent()
	while p != null:
		if p is Node2D:
			return p as Node2D
		p = p.get_parent()
	return null
""",
				"params": ["speed", "out_distance", "damage", "return_speed_multiplier", "catch_radius"],
				"category": "projectile",
				"subcategory": "patterns",
				"dimension": "2d",
				"difficulty": "intermediate",
				"param_info": {
					"out_distance": {
						"default": 300.0,
						"range": [50.0, 1000.0],
						"what": "Distance the projectile travels before returning.",
						"typical": "150 short / 300 standard / 600 long",
						"increase": "Goes further.",
						"decrease": "Comes back sooner."
					},
					"return_speed_multiplier": {
						"default": 1.2,
						"range": [0.5, 3.0],
						"what": "How much faster the return trip is.",
						"typical": "1.0 same / 1.2 slightly faster / 2.0 very fast",
						"increase": "Faster return.",
						"decrease": "Slower."
					},
					"catch_radius": {
						"default": 24.0,
						"range": [8.0, 100.0],
						"what": "How close to the thrower before the projectile despawns.",
						"typical": "24 standard / 60 forgiving",
						"increase": "Despawns further away.",
						"decrease": "Must get closer."
					}
				},
				"details": {
					"what": "Projectile that flies out, then curves back to its thrower. Can hit enemies on both trips.",
					"where": "Attach to an Area2D. Call setup(direction, thrower) after instantiating.",
					"before": "Player or thrower is a Node2D.",
					"after": "Add a rotation animation while flying for a proper boomerang spin.",
					"why_optimized": "State enum avoids boolean flags. Distance tracking is one addition per frame.",
					"mistakes": "Not skipping the thrower in _on_body_entered means the player damages themselves on the return trip.",
					"related": ["projectile", "ranged_attack", "homing_projectile"]
				}
			},
			"spiral_shot": {
				"phrases": ["spiral shot", "rotating emitter", "spiral bullet pattern", "spinning attack"],
				"code": """extends Node2D

@export var projectile_scene: PackedScene
@export var projectiles_per_burst: int = 1
@export var rotation_per_burst: float = 15.0
@export var burst_interval: float = 0.15
@export var total_bursts: int = 24
@export var projectile_speed: float = 200.0

var _current_rotation: float = 0.0
var _burst_count: int = 0

func start_spiral() -> void:
	_current_rotation = 0.0
	_burst_count = 0
	_run_spiral()

func _run_spiral() -> void:
	while _burst_count < total_bursts:
		_fire_burst()
		_current_rotation += rotation_per_burst
		_burst_count += 1
		await get_tree().create_timer(burst_interval).timeout

func _fire_burst() -> void:
	if projectile_scene == null:
		return
	for i in range(projectiles_per_burst):
		var angle := _current_rotation + (360.0 / float(projectiles_per_burst)) * float(i)
		var dir := Vector2.RIGHT.rotated(deg_to_rad(angle))
		var bullet := projectile_scene.instantiate() as Node2D
		get_tree().current_scene.add_child(bullet)
		bullet.global_position = global_position
		bullet.rotation = dir.angle()
		if bullet.get("direction") != null:
			bullet.set("direction", dir)
""",
				"params": ["projectiles_per_burst", "rotation_per_burst", "burst_interval", "total_bursts"],
				"category": "projectile",
				"subcategory": "patterns",
				"dimension": "2d",
				"difficulty": "intermediate",
				"param_info": {
					"projectiles_per_burst": {
						"default": 1,
						"range": [1, 8],
						"what": "How many bullets fire per burst.",
						"typical": "1 single spiral / 2 double / 4+ dense",
						"increase": "Denser spiral.",
						"decrease": "Sparser."
					},
					"rotation_per_burst": {
						"default": 15.0,
						"range": [5.0, 90.0],
						"what": "Degrees rotated between bursts.",
						"typical": "10 tight / 15 standard / 30 loose",
						"increase": "Bigger gaps in the spiral.",
						"decrease": "Tighter spiral."
					},
					"total_bursts": {
						"default": 24,
						"range": [4, 100],
						"what": "How many bursts before the pattern stops.",
						"typical": "12 short / 24 standard / 48+ full rotation+",
						"increase": "Longer attack.",
						"decrease": "Shorter."
					}
				},
				"details": {
					"what": "Fires projectiles in a rotating spiral. Classic bullet-hell boss attack.",
					"where": "Attach to the boss or emitter. Call start_spiral() to begin.",
					"before": "Projectile scene with a 'direction' property.",
					"after": "Emit start and end signals so the boss script can coordinate attacks.",
					"why_optimized": "Single while loop with await timer. No Timer node needed.",
					"mistakes": "Calling start_spiral() multiple times without awaiting leads to overlapping spirals that fill the screen.",
					"related": ["spread_shot", "boss_health_bar", "projectile"]
				}
			},
			"pierce_projectile": {
				"phrases": ["pierce bullet", "piercing projectile", "through enemy", "penetrating shot"],
				"code": """extends Area2D

@export var speed: float = 500.0
@export var damage: int = 15
@export var lifetime: float = 2.0
@export var pierce_count: int = 3
@export var damage_falloff: float = 0.7

var _remaining_pierce: int = 0
var _direction: Vector2 = Vector2.RIGHT
var _hit_bodies: Array = []

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_remaining_pierce = pierce_count
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

func setup(dir: Vector2) -> void:
	_direction = dir.normalized()
	rotation = _direction.angle()

func _physics_process(delta: float) -> void:
	position += _direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body in _hit_bodies:
		return
	_hit_bodies.append(body)
	if body.has_method("take_damage"):
		body.take_damage(damage)
	damage = int(float(damage) * damage_falloff)
	if damage < 1:
		queue_free()
		return
	_remaining_pierce -= 1
	if _remaining_pierce <= 0:
		queue_free()
""",
				"params": ["speed", "damage", "lifetime", "pierce_count", "damage_falloff"],
				"category": "projectile",
				"subcategory": "patterns",
				"dimension": "2d",
				"difficulty": "beginner",
				"param_info": {
					"pierce_count": {
						"default": 3,
						"range": [1, 20],
						"what": "How many enemies the bullet can pass through.",
						"typical": "1 no pierce / 3 standard / 10+ sniper",
						"increase": "Hits more enemies.",
						"decrease": "Hits fewer."
					},
					"damage_falloff": {
						"default": 0.7,
						"range": [0.1, 1.0],
						"what": "Damage multiplier after each hit. 1.0 means no falloff.",
						"typical": "0.5 heavy falloff / 0.7 standard / 1.0 no falloff",
						"increase": "Less damage loss.",
						"decrease": "More."
					}
				},
				"details": {
					"what": "Projectile that passes through multiple enemies. Each hit reduces pierce count and damage.",
					"where": "Attach to an Area2D. Call setup(direction) after instantiating.",
					"before": "Enemies with take_damage method.",
					"after": "Add a hit spark effect at each collision point.",
					"why_optimized": "Tracks hit bodies to avoid double-hits on the same enemy. Single damage value decrements.",
					"mistakes": "Forgetting to track hit bodies means the bullet hits the same enemy multiple times while overlapping.",
					"related": ["projectile", "ranged_attack", "damage_over_time"]
				}
			},
			"burst_shot": {
				"phrases": ["burst shot", "burst fire", "3 round burst", "burst rifle"],
				"code": """@export var projectile_scene: PackedScene
@export var burst_count: int = 3
@export var burst_interval: float = 0.08
@export var burst_cooldown: float = 0.8

var _firing: bool = false
var _can_fire: bool = true

func fire_burst(direction: Vector2) -> void:
	if not _can_fire or _firing:
		return
	_firing = true
	_can_fire = false
	for i in range(burst_count):
		_spawn_bullet(direction)
		if i < burst_count - 1:
			await get_tree().create_timer(burst_interval).timeout
	_firing = false
	await get_tree().create_timer(burst_cooldown).timeout
	_can_fire = true

func _spawn_bullet(dir: Vector2) -> void:
	if projectile_scene == null:
		return
	var bullet := projectile_scene.instantiate() as Node2D
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = global_position
	bullet.rotation = dir.angle()
	if bullet.get("direction") != null:
		bullet.set("direction", dir.normalized())

func is_firing() -> bool:
	return _firing
""",
				"params": ["burst_count", "burst_interval", "burst_cooldown"],
				"category": "projectile",
				"subcategory": "patterns",
				"dimension": "2d",
				"difficulty": "beginner",
				"param_info": {
					"burst_count": {
						"default": 3,
						"range": [2, 10],
						"what": "How many bullets per burst.",
						"typical": "2 double tap / 3 rifle burst / 5+ machine burst",
						"increase": "More per burst.",
						"decrease": "Fewer."
					},
					"burst_interval": {
						"default": 0.08,
						"range": [0.02, 0.5],
						"what": "Seconds between bullets within a burst.",
						"typical": "0.05 rapid / 0.08 standard / 0.2 distinct",
						"increase": "Slower burst.",
						"decrease": "Faster."
					},
					"burst_cooldown": {
						"default": 0.8,
						"range": [0.1, 3.0],
						"what": "Seconds between bursts.",
						"typical": "0.4 fast / 0.8 standard / 1.5 slow",
						"increase": "Longer pause between bursts.",
						"decrease": "Shorter."
					}
				},
				"details": {
					"what": "Fires N bullets in quick succession, then waits for a cooldown. Classic burst rifle behavior.",
					"where": "Attach to the shooter. Call fire_burst(direction) from input handling.",
					"before": "Projectile scene. Input action for shooting.",
					"after": "Connect to the sprite animation so the character plays an attack animation during the burst.",
					"why_optimized": "Two state flags prevent double-firing. await handles timing cleanly.",
					"mistakes": "Not tracking _firing means calling fire_burst while already bursting starts a second overlapping burst.",
					"related": ["spread_shot", "ranged_attack", "combo_attack"]
				}
			}
		}
	}

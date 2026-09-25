@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"snippets": {
			"flying_enemy_2d": {
				"phrases": ["flying enemy", "flying enemy 2d", "bird enemy", "floating enemy"],
				"code": """extends CharacterBody2D

signal died

@export var speed: float = 120.0
@export var hover_amplitude: float = 8.0
@export var hover_speed: float = 3.0
@export var player_path: NodePath
@export var attack_range: float = 200.0
@export var attack_damage: int = 5
@export var attack_cooldown: float = 1.5

var _time: float = 0.0
var _hover_origin: float = 0.0
var _attack_timer: float = 0.0
@onready var _player: Node2D = get_node_or_null(player_path)

func _ready() -> void:
	_hover_origin = global_position.y
	var anim := get_node_or_null("AnimatedSprite2D")
	if anim != null:
		anim.play("fly")

func _physics_process(delta: float) -> void:
	_time += delta * hover_speed
	_attack_timer = max(_attack_timer - delta, 0.0)
	if _player == null or not is_instance_valid(_player):
		_apply_hover(delta)
		move_and_slide()
		return
	var to_player := _player.global_position - global_position
	var dist := to_player.length()
	if dist < attack_range:
		velocity.x = 0.0
		if _attack_timer <= 0.0:
			_dive_attack()
			_attack_timer = attack_cooldown
	else:
		velocity.x = signf(to_player.x) * speed
	_apply_hover(delta)
	move_and_slide()

func _apply_hover(delta: float) -> void:
	var hover_y: float = _hover_origin + sin(_time) * hover_amplitude
	velocity.y = (hover_y - global_position.y) / maxf(delta, 0.001)
	velocity.y = clampf(velocity.y, -200.0, 200.0)

func _dive_attack() -> void:
	if _player == null:
		return
	var dir := (_player.global_position - global_position).normalized()
	velocity = dir * speed * 3.0
	if _player.has_method("take_damage"):
		_player.call("take_damage", attack_damage)

func take_damage(_amount: int) -> void:
	died.emit()
	queue_free()
""",
				"params": ["speed", "hover_amplitude", "hover_speed", "attack_range", "attack_damage", "attack_cooldown"],
				"category": "enemy",
				"subcategory": "flying",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "2d",
				"difficulty": "intermediate",
				"param_info": {
					"speed": {
						"default": 120.0,
						"range": [40.0, 400.0],
						"what": "Horizontal speed when chasing.",
						"typical": "60 slow / 120 standard / 250 fast",
						"increase": "Faster.",
						"decrease": "Slower."
					},
					"hover_amplitude": {
						"default": 8.0,
						"range": [2.0, 40.0],
						"what": "Vertical wobble in pixels.",
						"typical": "4 subtle / 8 standard / 20 obvious",
						"increase": "Bigger float.",
						"decrease": "Smaller."
					},
					"attack_range": {
						"default": 200.0,
						"range": [50.0, 500.0],
						"what": "Distance at which the enemy dives.",
						"typical": "100 close / 200 standard / 400+ ranged",
						"increase": "Attacks from further.",
						"decrease": "Must be closer."
					}
				},
				"details": {
					"what": "Flying enemy that hovers with a sine wave and dives at the player. Ignores gravity — no floor required.",
					"where": "Attach to a CharacterBody2D with a CollisionShape2D and AnimatedSprite2D child.",
					"before": "Player in group 'player' or assigned to player_path. Enemy has take_damage method.",
					"after": "Add attack telegraphs (color flash before dive) so players can react.",
					"why_optimized": "Sine-based hover is cheaper than physics. Only chases when player exists.",
					"mistakes": "Using gravity on a flying enemy defeats the point. This script never touches gravity.",
					"related": ["enemy_patrol", "chase_player", "health_system"]
				}
			},
			"turret_enemy_2d": {
				"phrases": ["turret enemy", "turret 2d", "stationary shooter", "gun turret"],
				"code": """extends Node2D

signal fired(direction: Vector2)

@export var projectile_scene: PackedScene
@export var fire_rate: float = 1.5
@export var range: float = 300.0
@export var rotate_to_target: bool = true
@export var rotate_speed: float = 5.0
@export var burst_count: int = 1
@export var burst_interval: float = 0.15

var _fire_timer: float = 0.0
var _player: Node2D = null
var _target_direction: Vector2 = Vector2.RIGHT
@onready var _sprite: Node2D = get_node_or_null("Sprite")
@onready var _muzzle: Node2D = get_node_or_null("Muzzle")

func _ready() -> void:
	_find_player()

func _find_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		_player = players[0]

func _physics_process(delta: float) -> void:
	_fire_timer = max(_fire_timer - delta, 0.0)
	if _player == null or not is_instance_valid(_player):
		return
	var to_player := _player.global_position - global_position
	if to_player.length() > range:
		return
	_target_direction = to_player.normalized()
	if rotate_to_target and _sprite != null:
		var target_angle := _target_direction.angle()
		_sprite.rotation = lerp_angle(_sprite.rotation, target_angle, rotate_speed * delta)
	if _fire_timer <= 0.0:
		_fire_burst()
		_fire_timer = fire_rate

func _fire_burst() -> void:
	if projectile_scene == null:
		return
	for i in range(burst_count):
		if i > 0:
			await get_tree().create_timer(burst_interval).timeout
		_spawn_projectile()

func _spawn_projectile() -> void:
	var bullet := projectile_scene.instantiate() as Node2D
	get_tree().current_scene.add_child(bullet)
	var spawn_pos := global_position if _muzzle == null else _muzzle.global_position
	bullet.global_position = spawn_pos
	bullet.rotation = _target_direction.angle()
	if bullet.get("direction") != null:
		bullet.set("direction", _target_direction)
	fired.emit(_target_direction)
""",
				"params": ["fire_rate", "range", "burst_count", "rotate_to_target"],
				"category": "enemy",
				"subcategory": "turret",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "2d",
				"difficulty": "beginner",
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
						"default": 300.0,
						"range": [100.0, 1000.0],
						"what": "Detection range in pixels.",
						"typical": "200 short / 300 standard / 600 long",
						"increase": "Fires from further.",
						"decrease": "Closer."
					},
					"burst_count": {
						"default": 1,
						"range": [1, 10],
						"what": "Projectiles per burst.",
						"typical": "1 single / 3 burst fire",
						"increase": "More per burst.",
						"decrease": "Fewer."
					}
				},
				"details": {
					"what": "Stationary turret that rotates to face the player and fires projectiles on a cooldown. Can fire in bursts.",
					"where": "Attach to a Node2D with a Sprite child. Add a Muzzle Marker2D at the barrel tip.",
					"before": "Projectile scene (see library/snippets/projectile_patterns.gd for options).",
					"after": "Add a laser sight that appears when the player is in range for telegraphing.",
					"why_optimized": "Finds player once and caches. Only rotates when player is in range.",
					"mistakes": "Firing without a Muzzle node spawns bullets from the turret center, which looks wrong with a long barrel.",
					"related": ["projectile", "ranged_attack", "boss_health_bar"]
				}
			},
			"jumper_enemy_2d": {
				"phrases": ["jumper enemy", "jumping enemy", "hopping enemy", "jumping slime"],
				"code": """extends CharacterBody2D

signal died

@export var jump_velocity: float = -450.0
@export var horizontal_speed: float = 120.0
@export var gravity: float = 1200.0
@export var jump_cooldown: float = 1.2
@export var chase_player: bool = true

var _jump_timer: float = 0.0
var _jump_direction: float = 1.0
var _player: Node2D = null

func _ready() -> void:
	if chase_player:
		var players := get_tree().get_nodes_in_group("player")
		if not players.is_empty():
			_player = players[0]

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	_jump_timer = max(_jump_timer - delta, 0.0)
	if is_on_floor() and _jump_timer <= 0.0:
		_prepare_jump()
	if is_on_floor():
		velocity.x = _jump_direction * horizontal_speed
	move_and_slide()

func _prepare_jump() -> void:
	if _player != null and is_instance_valid(_player):
		_jump_direction = signf(_player.global_position.x - global_position.x)
	else:
		_jump_direction = 1.0 if randf() < 0.5 else -1.0
	velocity.y = jump_velocity
	_jump_timer = jump_cooldown
	_squash_before_jump()

func _squash_before_jump() -> void:
	var sprite := get_node_or_null("AnimatedSprite2D")
	if sprite == null:
		return
	var base_scale: Vector2 = sprite.scale
	var tween := create_tween()
	tween.tween_property(sprite, "scale", base_scale * Vector2(1.2, 0.8), 0.05)
	tween.tween_property(sprite, "scale", base_scale, 0.1)

func take_damage(_amount: int) -> void:
	died.emit()
	queue_free()
""",
				"params": ["jump_velocity", "horizontal_speed", "jump_cooldown", "chase_player"],
				"category": "enemy",
				"subcategory": "jumper",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "2d",
				"difficulty": "beginner",
				"param_info": {
					"jump_velocity": {
						"default": -450.0,
						"range": [-900.0, -200.0],
						"what": "Upward velocity applied on jump.",
						"typical": "-350 small hop / -450 standard / -700 big jump",
						"increase": "Higher jumps.",
						"decrease": "Lower."
					},
					"horizontal_speed": {
						"default": 120.0,
						"range": [30.0, 400.0],
						"what": "Horizontal speed while jumping.",
						"typical": "60 gentle / 120 standard / 250 aggressive",
						"increase": "Faster.",
						"decrease": "Slower."
					},
					"jump_cooldown": {
						"default": 1.2,
						"range": [0.3, 3.0],
						"what": "Seconds between jumps.",
						"typical": "0.6 fast / 1.2 standard / 2.0 slow",
						"increase": "Longer pause between jumps.",
						"decrease": "Shorter."
					}
				},
				"details": {
					"what": "Jumping enemy that hops toward the player. Has a squash-and-stretch telegraph before each jump.",
					"where": "Attach to a CharacterBody2D with a CollisionShape2D and AnimatedSprite2D child.",
					"before": "Player in group 'player' for chasing. Set chase_player false for a purely random hop pattern.",
					"after": "Add a small dust puff on landing. See particle_dust.",
					"why_optimized": "Only applies gravity when airborne. Landing check is a single built-in query.",
					"mistakes": "Setting horizontal speed when airborne instead of only on ground makes the hop feel floaty and uncontrollable.",
					"related": ["platformer_movement_2d", "squash_stretch", "particle_dust"]
				}
			},
			"exploder_enemy_2d": {
				"phrases": ["exploder enemy", "kamikaze", "suicide bomber", "exploding enemy"],
				"code": """extends CharacterBody2D

signal exploded(position: Vector2, damage: int)
signal died

@export var speed: float = 150.0
@export var trigger_range: float = 60.0
@export var fuse_time: float = 1.0
@export var blast_radius: float = 80.0
@export var blast_damage: int = 30
@export var projectile_scene: PackedScene

var _state: String = "idle"
var _fuse_timer: float = 0.0
var _player: Node2D = null
@onready var _sprite: Node2D = get_node_or_null("AnimatedSprite2D")

func _ready() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		_player = players[0]

func _physics_process(delta: float) -> void:
	if _state == "idle":
		_chase(delta)
	elif _state == "fusing":
		_fuse_timer -= delta
		_flash()
		if _fuse_timer <= 0.0:
			_explode()
	move_and_slide()

func _chase(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		velocity = Vector2.ZERO
		return
	var dir := (_player.global_position - global_position).normalized()
	velocity = dir * speed
	if global_position.distance_to(_player.global_position) < trigger_range:
		_start_fuse()
	move_and_slide()

func _start_fuse() -> void:
	_state = "fusing"
	_fuse_timer = fuse_time
	velocity = Vector2.ZERO

func _flash() -> void:
	if _sprite == null:
		return
	var t: float = fmod(_fuse_timer * 10.0, 2.0)
	_sprite.modulate = Color(1, 0.3, 0.3) if t < 1.0 else Color.WHITE

func _explode() -> void:
	var players := get_tree().get_nodes_in_group("player")
	for p in players:
		if not (p is Node2D):
			continue
		if global_position.distance_to((p as Node2D).global_position) < blast_radius:
			if p.has_method("take_damage"):
				p.call("take_damage", blast_damage)
	exploded.emit(global_position, blast_damage)
	_spawn_blast_particles()
	died.emit()
	queue_free()

func _spawn_blast_particles() -> void:
	var particles := CPUParticles2D.new()
	particles.global_position = global_position
	particles.emitting = false
	particles.one_shot = true
	particles.amount = 30
	particles.lifetime = 0.6
	particles.explosiveness = 1.0
	particles.direction = Vector2.ZERO
	particles.spread = 180.0
	particles.initial_velocity_min = 200.0
	particles.initial_velocity_max = 400.0
	particles.gravity = Vector2(0, 300)
	particles.scale_amount_min = 3.0
	particles.scale_amount_max = 6.0
	particles.color = Color(1.0, 0.6, 0.2)
	get_tree().current_scene.add_child(particles)
	particles.emitting = true

func take_damage(_amount: int) -> void:
	died.emit()
	queue_free()
""",
				"params": ["speed", "trigger_range", "fuse_time", "blast_radius", "blast_damage"],
				"category": "enemy",
				"subcategory": "exploder",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "2d",
				"difficulty": "intermediate",
				"param_info": {
					"trigger_range": {
						"default": 60.0,
						"range": [20.0, 200.0],
						"what": "Distance at which the fuse starts.",
						"typical": "40 close / 60 standard / 120+ ranged",
						"increase": "Starts fuse from further.",
						"decrease": "Closer."
					},
					"fuse_time": {
						"default": 1.0,
						"range": [0.3, 3.0],
						"what": "Seconds between fuse start and explosion.",
						"typical": "0.5 fast / 1.0 standard / 2.0 slow",
						"increase": "Longer warning.",
						"decrease": "Shorter."
					},
					"blast_radius": {
						"default": 80.0,
						"range": [30.0, 300.0],
						"what": "Explosion damage radius.",
						"typical": "50 small / 80 standard / 200 huge",
						"increase": "Bigger blast.",
						"decrease": "Smaller."
					},
					"blast_damage": {
						"default": 30,
						"range": [5, 200],
						"what": "Damage dealt to anything in the blast.",
						"typical": "15 chip / 30 standard / 100+ devastating",
						"increase": "More damage.",
						"decrease": "Less."
					}
				},
				"details": {
					"what": "Enemy that chases the player, starts a fuse when close, and explodes. Has visual flash telegraph before detonation.",
					"where": "Attach to a CharacterBody2D with a CollisionShape2D and AnimatedSprite2D child.",
					"before": "Player in group 'player' with take_damage method.",
					"after": "Add screen shake, hitstop, and a bang sound on explosion for full effect.",
					"why_optimized": "Only checks player distance in the chase state. Blast damage uses a simple distance check.",
					"mistakes": "No fuse telegraph means the player can't avoid the explosion. The flashing is essential feedback.",
					"related": ["hitstop", "camera_shake", "particle_explosion", "health_system"]
				}
			},
			"splitter_enemy_2d": {
				"phrases": ["splitter enemy", "splitting enemy", "slime split", "dividing enemy"],
				"code": """extends CharacterBody2D

signal split_into_children(positions: Array)
signal died

@export var size_tier: int = 2
@export var speed: float = 100.0
@export var split_count: int = 2
@export var min_size_tier: int = 1
@export var child_scene: PackedScene
@export var max_health: int = 10

var health: int = max_health
var _player: Node2D = null

func _ready() -> void:
	health = max_health
	_apply_size()
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		_player = players[0]

func _physics_process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		velocity = Vector2.ZERO
		move_and_slide()
		return
	var dir := (_player.global_position - global_position).normalized()
	velocity = dir * speed
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
		var offset := Vector2(cos(angle), sin(angle)) * 24.0
		var child := child_scene.instantiate()
		child.set("size_tier", size_tier - 1)
		child.set("child_scene", child_scene)
		child.set("min_size_tier", min_size_tier)
		get_tree().current_scene.add_child(child)
		child.global_position = global_position + offset
		positions.append(child.global_position)
	split_into_children.emit(positions)

func _apply_size() -> void:
	var size_scale: float = 0.6 + 0.2 * float(size_tier)
	scale = Vector2(size_scale, size_scale)
	max_health = max_health * size_tier / 2
	speed = speed * (1.5 - 0.15 * float(size_tier))
""",
				"params": ["size_tier", "speed", "split_count", "min_size_tier", "max_health"],
				"category": "enemy",
				"subcategory": "splitter",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "2d",
				"difficulty": "intermediate",
				"param_info": {
					"size_tier": {
						"default": 2,
						"range": [1, 5],
						"what": "Current size level. Children spawn one tier smaller.",
						"typical": "1 smallest / 2 standard / 3 big",
						"increase": "Bigger starting enemy.",
						"decrease": "Smaller."
					},
					"split_count": {
						"default": 2,
						"range": [2, 6],
						"what": "Number of children spawned on death.",
						"typical": "2 simple / 3 standard / 4+ swarm",
						"increase": "More children per split.",
						"decrease": "Fewer."
					},
					"min_size_tier": {
						"default": 1,
						"range": [1, 5],
						"what": "Smallest tier. Below this, no more splitting.",
						"typical": "1 stops at smallest / 2 stops after one split",
						"increase": "Fewer split levels.",
						"decrease": "More."
					}
				},
				"details": {
					"what": "Enemy that splits into smaller versions when killed. Recurses until reaching min_size_tier.",
					"where": "Attach to a CharacterBody2D. Save the scene as its own .tscn and set child_scene to that same scene (self-reference).",
					"before": "The enemy scene must be saved separately so it can spawn copies of itself.",
					"after": "Add scaling squash-and-stretch on spawn so children visually pop into existence.",
					"why_optimized": "Size and health auto-scale from size_tier — no per-instance tuning needed.",
					"mistakes": "Setting child_scene to itself without saving as .tscn causes an infinite scene load loop. Save the scene first.",
					"related": ["health_system", "squash_stretch", "particle_explosion"]
				}
			},
			"shielded_enemy_2d": {
				"phrases": ["shielded enemy", "shield enemy", "blocking enemy", "armored enemy"],
				"code": """extends CharacterBody2D

signal shield_broken
signal died

@export var speed: float = 80.0
@export var max_health: int = 20
@export var shield_health: int = 30
@export var shield_recharge_delay: float = 3.0
@export var shield_recharge_rate: float = 5.0

var health: int = max_health
var shield: int = shield_health
var _recharge_timer: float = 0.0
var _player: Node2D = null
@onready var _shield_visual: Node2D = get_node_or_null("ShieldVisual")

func _ready() -> void:
	health = max_health
	shield = shield_health
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		_player = players[0]

func _physics_process(delta: float) -> void:
	if _player != null and is_instance_valid(_player):
		var dir := (_player.global_position - global_position).normalized()
		velocity = dir * speed
		move_and_slide()
	_update_shield(delta)

func _update_shield(delta: float) -> void:
	if shield <= 0:
		if _recharge_timer > 0.0:
			_recharge_timer -= delta
		elif shield_health > 0:
			shield = min(shield + int(shield_recharge_rate * delta * 10.0), shield_health)
	if _shield_visual != null:
		_shield_visual.visible = shield > 0

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
""",
				"params": ["speed", "max_health", "shield_health", "shield_recharge_delay", "shield_recharge_rate"],
				"category": "enemy",
				"subcategory": "shielded",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "2d",
				"difficulty": "intermediate",
				"param_info": {
					"shield_health": {
						"default": 30,
						"range": [5, 200],
						"what": "How much damage the shield absorbs before breaking.",
						"typical": "10 weak / 30 standard / 100 tanky",
						"increase": "Stronger shield.",
						"decrease": "Weaker."
					},
					"shield_recharge_delay": {
						"default": 3.0,
						"range": [0.0, 15.0],
						"what": "Seconds after taking damage before the shield regenerates.",
						"typical": "1.0 aggressive / 3.0 standard / 10.0+ patient",
						"increase": "Slower recharge.",
						"decrease": "Faster."
					},
					"shield_recharge_rate": {
						"default": 5.0,
						"range": [0.5, 30.0],
						"what": "Shield points restored per second.",
						"typical": "2 slow / 5 standard / 15 fast",
						"increase": "Faster recharge.",
						"decrease": "Slower."
					}
				},
				"details": {
					"what": "Enemy with a shield that absorbs damage first, then breaks. Shield recharges after a delay if the enemy isn't hit.",
					"where": "Attach to a CharacterBody2D. Optional ShieldVisual child toggles visibility based on shield state.",
					"before": "Player in group 'player' with take_damage method.",
					"after": "Add a shatter effect when shield_broken fires. See shader_dissolve for a shield-shatter shader.",
					"why_optimized": "Shield recharge only runs when shield is depleted. Toggles one visual property per frame.",
					"mistakes": "Not calling shield_broken means the player gets no feedback when the shield drops — critical for strategy.",
					"related": ["health_system", "shader_dissolve", "invincibility_frames"]
				}
			}
		}
	}

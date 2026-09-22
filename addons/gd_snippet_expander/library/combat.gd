@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"snippets": {
			"melee_attack": {
				"phrases": ["melee attack", "melee", "sword attack", "punch"],
				"code": """@export var damage: int = 10
@export var cooldown: float = 0.4

@onready var _hitbox: Area2D = $Hitbox

var _can_attack: bool = true

func attack() -> void:
	if not _can_attack:
		return
	_can_attack = false
	for body in _hitbox.get_overlapping_bodies():
		if body.has_method("take_damage"):
			body.take_damage(damage)
	await get_tree().create_timer(cooldown).timeout
	_can_attack = true
""",
				"params": ["damage", "cooldown"],
				"category": "combat",
				"dimension": "2d",
				"difficulty": "beginner",
				"required_actions": ["attack"],
				"param_info": {
					"damage": {
						"default": 10,
						"range": [1, 100],
						"what": "Damage dealt per hit.",
						"typical": "5 light / 10 standard / 25 heavy / 50+ boss",
						"increase": "Kills enemies faster, less back-and-forth.",
						"decrease": "Longer fights, more chance to react."
					},
					"cooldown": {
						"default": 0.4,
						"range": [0.1, 2.0],
						"what": "Seconds between attacks.",
						"typical": "0.2 spammy / 0.4 standard / 0.8 deliberate / 1.5+ heavy",
						"increase": "Attack feels more committed.",
						"decrease": "Faster, more arcadey."
					}
				},
				"details": {
					"what": "Melee attack that damages everything overlapping the Hitbox child.",
					"where": "Attach to the player or enemy. Add an Area2D child named 'Hitbox'.",
					"before": "Create input action 'attack' in Input Map. Enemies must have take_damage().",
					"after": "Add a short animation or hit effect — code alone feels lifeless.",
					"why_optimized": "get_overlapping_bodies avoids allocating new arrays per frame.",
					"mistakes": "Not checking has_method crashes if the hitbox overlaps a static wall.",
					"related": ["hitbox", "knockback", "attack_cooldown", "combo_attack"]
				}
			},
			"ranged_attack": {
				"phrases": ["ranged attack", "shoot", "fire bullet"],
				"code": """@export var projectile_scene: PackedScene
@export var fire_rate: float = 0.2

var _cooldown: float = 0.0

func _process(delta: float) -> void:
	_cooldown = max(_cooldown - delta, 0.0)

func shoot() -> void:
	if _cooldown > 0.0 or projectile_scene == null:
		return
	var bullet := projectile_scene.instantiate() as Node2D
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = global_position
	bullet.rotation = rotation
	_cooldown = fire_rate
""",
				"params": ["projectile_scene", "fire_rate"],
				"category": "combat",
				"dimension": "2d",
				"difficulty": "beginner",
				"required_actions": ["shoot"],
				"param_info": {
					"fire_rate": {
						"default": 0.2,
						"range": [0.05, 2.0],
						"what": "Seconds between shots.",
						"typical": "0.1 machine gun / 0.2 pistol / 0.5 rifle / 1.0+ sniper",
						"increase": "Slower, more deliberate shots.",
						"decrease": "Faster fire, more bullets on screen."
					}
				},
				"details": {
					"what": "Spawns a projectile in front of the shooter, rate-limited.",
					"where": "Attach to the shooter. Assign a projectile scene (.tscn) in the Inspector.",
					"before": "You need a projectile scene — use 'projectile' snippet to make one.",
					"after": "Add a muzzle flash sprite and recoil animation.",
					"why_optimized": "Adds bullet to current_scene so it doesn't move with the shooter.",
					"mistakes": "Adding the bullet as a child of the shooter makes it rotate with the player.",
					"related": ["projectile", "attack_cooldown", "damage_number_popup"]
				}
			},
			"projectile": {
				"phrases": ["projectile", "bullet", "moving projectile"],
				"code": """extends Area2D

@export var speed: float = 600.0
@export var damage: int = 10
@export var lifetime: float = 2.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	position += Vector2.RIGHT.rotated(rotation) * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()
""",
				"params": ["speed", "damage", "lifetime"],
				"category": "combat",
				"dimension": "2d",
				"difficulty": "beginner",
				"param_info": {
					"speed": {
						"default": 600.0,
						"range": [100.0, 2000.0],
						"what": "How fast the projectile travels, in pixels per second.",
						"typical": "300 thrown / 600 bullet / 1200 laser",
						"increase": "Harder for player to dodge.",
						"decrease": "Slower, easier to see and dodge."
					},
					"damage": {
						"default": 10,
						"range": [1, 100],
						"what": "Damage applied on hit.",
						"typical": "5 weak / 10 standard / 25 heavy",
						"increase": "Deadlier bullets.",
						"decrease": "Weaker hits, requires more shots."
					},
					"lifetime": {
						"default": 2.0,
						"range": [0.2, 10.0],
						"what": "How long before the bullet despawns.",
						"typical": "0.5 melee range / 2.0 standard / 5+ long-range sniper",
						"increase": "Bullets travel further before vanishing.",
						"decrease": "Shorter range, less clutter on screen."
					}
				},
				"details": {
					"what": "A bullet that moves forward, damages what it hits, and despawns.",
					"where": "Attach to an Area2D. Add a CollisionShape2D and sprite.",
					"before": "None.",
					"after": "Add particle effects on hit for polish.",
					"why_optimized": "Timer created in _ready means no Timer node. Damage on body_entered.",
					"mistakes": "Forgetting queue_free means bullets pile up. Forgetting the timer means they never die.",
					"related": ["ranged_attack", "hitbox", "damage_number_popup"]
				}
			},
			"hitbox": {
				"phrases": ["hitbox", "damage area", "attack area"],
				"code": """extends Area2D

@export var damage: int = 10

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	if area.has_method("take_damage"):
		area.take_damage(damage)
""",
				"params": ["damage"],
				"category": "combat",
				"dimension": "2d",
				"difficulty": "beginner",
				"param_info": {
					"damage": {
						"default": 10,
						"range": [1, 100],
						"what": "Damage dealt to entering areas.",
						"typical": "5 light / 10 standard / 25 heavy",
						"increase": "Bigger hits.",
						"decrease": "Smaller hits."
					}
				},
				"details": {
					"what": "An Area2D that damages other Areas that enter it (Area-to-Area combat).",
					"where": "Attach to an Area2D. Used for ability hitboxes that detect hurtboxes.",
					"before": "Target must have a matching hurtbox (Area2D with take_damage).",
					"after": "For body-to-area (player hits enemy body), use melee_attack instead.",
					"why_optimized": "Uses area_entered for hit detection — the physics engine handles overlap.",
					"mistakes": "Confusing body_entered and area_entered. body_entered is for CharacterBody/StaticBody, area_entered is for other Areas.",
					"related": ["hurtbox", "melee_attack", "projectile"]
				}
			},
			"hurtbox": {
				"phrases": ["hurtbox", "hurt box", "receive damage area"],
				"code": """extends Area2D

@export var owner_health: NodePath

@onready var _health: Node = get_node(owner_health)

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	if area.has_method("get_damage"):
		_health.take_damage(area.get_damage())
""",
				"params": ["owner_health"],
				"category": "combat",
				"dimension": "2d",
				"difficulty": "intermediate",
				"param_info": {
					"owner_health": {
						"default": "",
						"range": [],
						"what": "Path to the node that has the health system. Usually the parent.",
						"typical": ".. (parent) or the player node path",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "An Area2D that forwards damage to a health node. The receiving end of combat.",
					"where": "Attach to an Area2D child of the character. Set owner_health to the parent.",
					"before": "Parent must have health_system and take_damage. Attacker must have get_damage().",
					"after": "Combine with hitbox on the attacker. Hitbox sends, hurtbox receives.",
					"why_optimized": "Forwards to the health system so damage logic lives in one place.",
					"mistakes": "Forgetting owner_health leaves the hurtbox unable to find where to send damage.",
					"related": ["hitbox", "health_system", "take_damage"]
				}
			},
			"knockback": {
				"phrases": ["knockback", "knock back", "push back"],
				"code": """@export var knockback_force: float = 300.0

func apply_knockback(from_position: Vector2) -> void:
	var dir := (global_position - from_position).normalized()
	velocity = dir * knockback_force
	move_and_slide()
""",
				"params": ["knockback_force"],
				"category": "combat",
				"dimension": "2d",
				"difficulty": "beginner",
				"param_info": {
					"knockback_force": {
						"default": 300.0,
						"range": [50.0, 1500.0],
						"what": "How hard the target is pushed away, in pixels per second.",
						"typical": "150 light nudge / 300 standard / 600 heavy hit / 1000+ launch",
						"increase": "Dramatic launch, more distance.",
						"decrease": "Subtle pushback."
					}
				},
				"details": {
					"what": "Pushes a character away from a source point.",
					"where": "Attach to the CharacterBody2D being hit. Call apply_knockback(attacker.position) on hit.",
					"before": "Target must extend CharacterBody2D.",
					"after": "Add a brief stun — disable input for the knockback duration.",
					"why_optimized": "normalized() gives consistent push distance regardless of distance to attacker.",
					"mistakes": "Using the raw difference without normalized() means knockback is stronger when the attacker is further away.",
					"related": ["melee_attack", "hurtbox", "hitbox"]
				}
			},
			"attack_cooldown": {
				"phrases": ["attack cooldown", "cooldown timer", "attack delay"],
				"code": """@export var cooldown: float = 0.5

var _ready_to_attack: bool = true

func try_attack() -> void:
	if not _ready_to_attack:
		return
	_ready_to_attack = false
	_do_attack()
	await get_tree().create_timer(cooldown).timeout
	_ready_to_attack = true

func _do_attack() -> void:
	pass
""",
				"params": ["cooldown"],
				"category": "combat",
				"dimension": "any",
				"difficulty": "beginner",
				"param_info": {
					"cooldown": {
						"default": 0.5,
						"range": [0.1, 3.0],
						"what": "Seconds between attacks.",
						"typical": "0.2 dagger / 0.5 sword / 1.5 hammer / 3+ ultimate",
						"increase": "Attacks feel more weighted.",
						"decrease": "Faster combat, more spam-friendly."
					}
				},
				"details": {
					"what": "Generic cooldown wrapper for any attack function.",
					"where": "Attach to the attacker. Replace _do_attack() with your real attack logic.",
					"before": "None.",
					"after": "Show a cooldown bar UI to give feedback.",
					"why_optimized": "await is one coroutine, no Timer node needed.",
					"mistakes": "Forgetting to call try_attack() instead of _do_attack() bypasses the cooldown.",
					"related": ["melee_attack", "ranged_attack", "combo_attack"]
				}
			},
			"weapon_swap": {
				"phrases": ["weapon swap", "switch weapon", "change weapon"],
				"code": """@export var weapons: Array[PackedScene] = []

var _current_index: int = 0
var _current: Node = null

func swap_weapon(index: int) -> void:
	if index < 0 or index >= weapons.size():
		return
	if _current:
		_current.queue_free()
	_current = weapons[index].instantiate()
	add_child(_current)
	_current_index = index
""",
				"params": ["weapons"],
				"category": "combat",
				"dimension": "2d",
				"difficulty": "intermediate",
				"param_info": {
					"weapons": {
						"default": [],
						"range": [],
						"what": "Array of weapon scenes (.tscn) to swap between.",
						"typical": "2-4 weapons typical for action games",
						"increase": "More options but more memorization for the player.",
						"decrease": "Simpler loadout."
					}
				},
				"details": {
					"what": "Removes the current weapon and adds a new one from an array.",
					"where": "Attach to the player. Add a Node2D child to hold the weapons visually.",
					"before": "You need weapon scenes as .tscn files.",
					"after": "Add input actions for weapon 1, 2, 3 or scroll wheel.",
					"why_optimized": "queue_free instead of free — safe even mid-frame.",
					"mistakes": "Calling free() instead of queue_free() crashes if called during physics.",
					"related": ["melee_attack", "ranged_attack", "weapon_pickup"]
				}
			},
			"combo_attack": {
				"phrases": ["combo attack", "combo", "attack combo"],
				"code": """@export var combo_window: float = 0.6
@export var max_combo: int = 3

var _combo_step: int = 0
var _combo_timer: float = 0.0

func _process(delta: float) -> void:
	_combo_timer = max(_combo_timer - delta, 0.0)
	if _combo_timer == 0.0:
		_combo_step = 0

func attack() -> void:
	_combo_step = (_combo_step + 1) % max_combo
	_combo_timer = combo_window
	_play_attack(_combo_step)

func _play_attack(step: int) -> void:
	pass
""",
				"params": ["combo_window", "max_combo"],
				"category": "combat",
				"dimension": "2d",
				"difficulty": "intermediate",
				"required_actions": ["attack"],
				"param_info": {
					"combo_window": {
						"default": 0.6,
						"range": [0.2, 2.0],
						"what": "How long after an attack the next one counts as a combo.",
						"typical": "0.3 tight / 0.6 standard / 1.0 forgiving",
						"increase": "Easier to chain attacks.",
						"decrease": "Requires precise timing."
					},
					"max_combo": {
						"default": 3,
						"range": [2, 8],
						"what": "Number of hits in the combo before looping back.",
						"typical": "3 standard / 4 combo-heavy / 5+ elaborate",
						"increase": "Longer combo chains.",
						"decrease": "Shorter combos."
					}
				},
				"details": {
					"what": "Tracks combo step. Each attack advances the step until the window expires.",
					"where": "Attach to the attacker. Replace _play_attack(step) with your animation code.",
					"before": "Create input action 'attack'.",
					"after": "Play a different animation for each combo step.",
					"why_optimized": "Modulo wraps the combo back to step 0 automatically.",
					"mistakes": "Forgetting to reset _combo_step when the timer expires means the combo never restarts.",
					"related": ["melee_attack", "attack_cooldown", "weapon_swap"]
				}
			},
			"damage_number_popup": {
				"phrases": ["damage number", "floating damage", "damage popup"],
				"code": """@export var popup_scene: PackedScene

func spawn_damage_number(amount: int, world_position: Vector2) -> void:
	var popup := popup_scene.instantiate() as Node2D
	get_tree().current_scene.add_child(popup)
	popup.global_position = world_position
	popup.set_text(str(amount))
""",
				"params": ["popup_scene"],
				"category": "combat",
				"dimension": "2d",
				"difficulty": "intermediate",
				"param_info": {
					"popup_scene": {
						"default": "",
						"range": [],
						"what": "Scene with a Label and a tween to move up and fade.",
						"typical": "one popup scene reused everywhere",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "Spawns a floating damage number at a world position.",
					"where": "Attach to a global node (an autoload or the game manager).",
					"before": "You need a popup scene with a Label node and a set_text() function.",
					"after": "Color the number differently for crits, healing, etc.",
					"why_optimized": "Adds to current_scene so numbers don't move with the attacker.",
					"mistakes": "Attaching the popup to the enemy means it vanishes when the enemy dies.",
					"related": ["health_system", "melee_attack", "damage_over_time"]
				}
			}
		}
	}

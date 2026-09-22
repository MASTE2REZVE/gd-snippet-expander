@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"snippets": {
			"health_system": {
				"phrases": ["health", "health system", "hp system", "hit points"],
				"code": """signal health_changed(new_health: int)
signal died

@export var max_health: int = 100
var health: int = max_health

func take_damage(amount: int) -> void:
	health = max(health - amount, 0)
	health_changed.emit(health)
	if health == 0:
		died.emit()

func heal(amount: int) -> void:
	health = min(health + amount, max_health)
	health_changed.emit(health)
""",
				"params": ["max_health"],
				"category": "health",
				"dimension": "any",
				"difficulty": "beginner",
				"param_info": {
					"max_health": {
						"default": 100,
						"range": [1, 10000],
						"what": "Starting and maximum hit points.",
						"typical": "3 hearts / 10 small numbers / 100 standard / 1000+ MMO",
						"increase": "Everything takes more hits.",
						"decrease": "Combat resolves faster, more lethal."
					}
				},
				"details": {
					"what": "Signal-based health with take_damage, heal, and a died signal.",
					"where": "Attach to the player, enemy, or anything that can be hurt. Combine with hitbox or hurtbox.",
					"before": "None.",
					"after": "Connect 'died' to a respawn or game-over handler.",
					"why_optimized": "max() and min() clamp health without an if branch. Signal emit only when health actually changes.",
					"mistakes": "Forgetting to emit health_changed means UI bars never update.",
					"related": ["take_damage", "heal", "die", "health_bar_ui", "health_pickup"]
				}
			},
			"take_damage": {
				"phrases": ["take damage", "damage", "receive damage"],
				"code": """func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		die()
""",
				"params": [],
				"category": "health",
				"dimension": "any",
				"difficulty": "beginner",
				"details": {
					"what": "Simplest possible damage function. Reduces health, calls die() at zero or below.",
					"where": "Attach to anything that can be hurt. Pair with a health variable.",
					"before": "You must have a 'health' variable and a 'die()' function already.",
					"after": "For a proper system with signals and clamping, use 'health system' instead.",
					"why_optimized": "Two lines — no signals, no overhead. Good for prototypes.",
					"mistakes": "Forgetting die() means the enemy stays alive with negative health.",
					"related": ["health_system", "heal", "die"]
				}
			},
			"heal": {
				"phrases": ["heal", "restore health", "recover health"],
				"code": """func heal(amount: int) -> void:
	health = min(health + amount, max_health)
""",
				"params": [],
				"category": "health",
				"dimension": "any",
				"difficulty": "beginner",
				"details": {
					"what": "Restores health but never above max_health.",
					"where": "Add to anything that has health and max_health.",
					"before": "Needs 'health' and 'max_health' variables.",
					"after": "Call heal(25) from a health_pickup.",
					"why_optimized": "min() clamps in one line — no if needed.",
					"mistakes": "Using 'health += amount' without min() lets health go past max.",
					"related": ["health_system", "take_damage", "health_pickup"]
				}
			},
			"die": {
				"phrases": ["die", "death", "kill player", "on death"],
				"code": """signal died

func die() -> void:
	died.emit()
	queue_free()
""",
				"params": [],
				"category": "health",
				"dimension": "any",
				"difficulty": "beginner",
				"details": {
					"what": "Emits a died signal and removes the node.",
					"where": "Attach anywhere that needs to die. Call from take_damage.",
					"before": "None.",
					"after": "Connect 'died' to game over, respawn, or score handlers.",
					"why_optimized": "Emits before queue_free so listeners can react.",
					"mistakes": "Calling queue_free() before died.emit() means listeners see a freed node.",
					"related": ["health_system", "take_damage", "respawn", "game_over_screen"]
				}
			},
			"health_bar": {
				"phrases": ["health bar", "healthbar", "hp bar"],
				"code": """@onready var _bar: ProgressBar = $ProgressBar

func _ready() -> void:
	health_changed.connect(_on_health_changed)
	_on_health_changed(health)

func _on_health_changed(new_health: int) -> void:
	_bar.value = float(new_health) / float(max_health) * 100.0
""",
				"params": [],
				"category": "health",
				"dimension": "any",
				"difficulty": "beginner",
				"details": {
					"what": "Updates a ProgressBar whenever health changes.",
					"where": "Attach to the same node that has health_system. Add a ProgressBar child.",
					"before": "Needs health_changed signal and 'health'/'max_health' variables (from health_system).",
					"after": "For a UI-only version that reads the player remotely, use health_bar_ui.",
					"why_optimized": "Calls _on_health_changed once in _ready to sync the bar immediately.",
					"mistakes": "Forgetting the initial call leaves the bar at its scene default instead of real health.",
					"related": ["health_system", "health_bar_ui", "score_display"]
				}
			},
			"invincibility_frames": {
				"phrases": ["invincibility", "i-frames", "invincibility frames"],
				"code": """@export var invincibility_time: float = 1.0

var _invincible: bool = false

func take_damage_safe(amount: int) -> void:
	if _invincible:
		return
	_invincible = true
	health -= amount
	await get_tree().create_timer(invincibility_time).timeout
	_invincible = false
""",
				"params": ["invincibility_time"],
				"category": "health",
				"dimension": "any",
				"difficulty": "intermediate",
				"param_info": {
					"invincibility_time": {
						"default": 1.0,
						"range": [0.1, 3.0],
						"what": "How long the character is immune after being hit.",
						"typical": "0.5 fast action / 1.0 standard / 1.5+ forgiving",
						"increase": "Safer, less punishing.",
						"decrease": "More danger, tighter timing."
					}
				},
				"details": {
					"what": "Prevents damage for a short time after being hit.",
					"where": "Attach to the player or any character that needs invulnerability.",
					"before": "Needs a 'health' variable.",
					"after": "Add a flash animation — set modulate to white and back during _invincible.",
					"why_optimized": "await is cheaper than a Timer node.",
					"mistakes": "Calling regular take_damage bypasses this. Use take_damage_safe everywhere.",
					"related": ["health_system", "take_damage", "damage_over_time"]
				}
			},
			"damage_over_time": {
				"phrases": ["damage over time", "dot damage", "burn damage", "poison"],
				"code": """@export var dot_damage: int = 2
@export var dot_interval: float = 0.5
@export var dot_duration: float = 5.0

func apply_damage_over_time() -> void:
	var elapsed := 0.0
	while elapsed < dot_duration:
		await get_tree().create_timer(dot_interval).timeout
		health -= dot_damage
		elapsed += dot_interval
""",
				"params": ["dot_damage", "dot_interval", "dot_duration"],
				"category": "health",
				"dimension": "any",
				"difficulty": "intermediate",
				"param_info": {
					"dot_damage": {
						"default": 2,
						"range": [1, 50],
						"what": "Damage per tick.",
						"typical": "1 slow burn / 2 poison / 5 fire",
						"increase": "Faster death.",
						"decrease": "Slower, more annoying than dangerous."
					},
					"dot_interval": {
						"default": 0.5,
						"range": [0.1, 2.0],
						"what": "Seconds between ticks.",
						"typical": "0.25 fast / 0.5 standard / 1.0 slow",
						"increase": "Fewer, bigger-looking ticks.",
						"decrease": "More, smaller ticks — feels continuous."
					},
					"dot_duration": {
						"default": 5.0,
						"range": [1.0, 30.0],
						"what": "How long the effect lasts, in seconds.",
						"typical": "3 brief / 5 standard / 15 lingering",
						"increase": "Longer effect.",
						"decrease": "Shorter effect."
					}
				},
				"details": {
					"what": "Applies damage repeatedly over a fixed duration.",
					"where": "Call apply_damage_over_time() when the player enters fire, poison, or acid.",
					"before": "Needs a 'health' variable.",
					"after": "For stacking effects, track how many DOT instances are active.",
					"why_optimized": "while loop with await — no Timer nodes needed.",
					"mistakes": "Calling apply_damage_over_time() multiple times stacks damage massively. Gate with a flag.",
					"related": ["health_system", "take_damage", "invincibility_frames"]
				}
			},
			"respawn": {
				"phrases": ["respawn", "respawn player", "respawn at point"],
				"code": """@export var respawn_delay: float = 2.0
@export var spawn_point: NodePath

func _on_died() -> void:
	await get_tree().create_timer(respawn_delay).timeout
	var point := get_node(spawn_point) as Node2D
	global_position = point.global_position
	health = max_health
""",
				"params": ["respawn_delay", "spawn_point"],
				"category": "health",
				"dimension": "2d",
				"difficulty": "beginner",
				"param_info": {
					"respawn_delay": {
						"default": 2.0,
						"range": [0.0, 10.0],
						"what": "How long to wait before respawning.",
						"typical": "0 instant / 1 fast / 2 standard / 5 cinematic",
						"increase": "More dramatic pause.",
						"decrease": "Faster return to action."
					}
				},
				"details": {
					"what": "Moves the player back to a spawn point after a delay and restores health.",
					"where": "Connect to the 'died' signal. Set spawn_point in the Inspector.",
					"before": "Need a Marker2D or any Node2D to serve as the spawn point.",
					"after": "For animation on respawn, add a fade-in tween.",
					"why_optimized": "await is a single coroutine, no Timer node.",
					"mistakes": "Calling respawn on a freed node crashes. Use died signal with a persistent node instead.",
					"related": ["health_system", "die", "game_over_screen"]
				}
			},
			"health_signal": {
				"phrases": ["health signal", "health changed signal"],
				"code": """signal health_changed(current: int, maximum: int)

func _ready() -> void:
	health_changed.emit(health, max_health)
""",
				"params": [],
				"category": "health",
				"dimension": "any",
				"difficulty": "beginner",
				"details": {
					"what": "A signal that carries both current and max health.",
					"where": "Any node that has health. UI can connect to display '75/100' style text.",
					"before": "Needs 'health' and 'max_health' variables.",
					"after": "Emit it whenever health changes.",
					"why_optimized": "Carries both values in one signal — UI doesn't need to look anything up.",
					"mistakes": "Emitting only 'current' means UI has to find max_health separately.",
					"related": ["health_system", "health_bar", "health_bar_ui"]
				}
			},
			"kill_zone": {
				"phrases": ["kill zone", "killzone", "instant death area"],
				"code": """extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("die"):
		body.die()
""",
				"params": [],
				"category": "health",
				"dimension": "2d",
				"difficulty": "beginner",
				"details": {
					"what": "Kills anything that enters the area — spikes, lava, pits.",
					"where": "Attach to an Area2D. Give it a CollisionShape2D child sized to the danger zone.",
					"before": "The target must have a die() method.",
					"after": "For damage instead of instant death, call take_damage(1) instead of die().",
					"why_optimized": "has_method check means anything with die() works — player or enemy.",
					"mistakes": "Forgetting body_entered.connect means nothing happens.",
					"related": ["die", "health_system", "take_damage"]
				}
			}
		}
	}

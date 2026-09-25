@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"snippets": {
			"enemy_patrol": {
				"phrases": ["enemy patrol", "patrol", "patrol between points"],
				"code": """extends CharacterBody2D

@export var speed: float = 80.0
@export var points: Array[Vector2] = []

var _index: int = 0

func _physics_process(_delta: float) -> void:
	if points.is_empty():
		return
	var target := points[_index]
	var dir := (target - global_position).normalized()
	velocity = dir * speed
	move_and_slide()
	if global_position.distance_to(target) < 4.0:
		_index = (_index + 1) % points.size()
""",
				"params": ["speed", "points"],
				"category": "ai",
				"dimension": "2d",
				"difficulty": "beginner",
				"param_info": {
					"speed": {
						"default": 80.0,
						"range": [20.0, 300.0],
						"what": "Movement speed between waypoints.",
						"typical": "40 slow guard / 80 standard / 150 fast patrol / 250+ chasing",
						"increase": "Faster patrol, harder to avoid.",
						"decrease": "Slow, easy to sneak past."
					},
					"points": {
						"default": [],
						"range": [],
						"what": "Array of world positions the enemy walks between.",
						"typical": "2-4 points for a simple patrol",
						"increase": "Longer route, more ground covered.",
						"decrease": "Simpler back-and-forth."
					}
				},
				"details": {
					"what": "An enemy that walks between a list of waypoints in a loop.",
					"where": "Attach to a CharacterBody2D with a CollisionShape2D child. Set the points array in the Inspector.",
					"before": "Fill in the points array with world positions.",
					"after": "Add look_for_player to switch from patrol to chase.",
					"why_optimized": "Modulo wraps the index — no bounds check needed. distance_to is squared-free.",
					"mistakes": "Forgetting to set points leaves the enemy standing still.",
					"related": ["chase_player", "look_for_player", "wander_ai", "flee_ai"]
				}
			},
			"chase_player": {
				"phrases": ["chase player", "follow player enemy", "enemy chase"],
				"code": """extends CharacterBody2D

@export var speed: float = 120.0
@export var player_path: NodePath

@onready var _player: Node2D = get_node(player_path) as Node2D

func _physics_process(_delta: float) -> void:
	var dir := (_player.global_position - global_position).normalized()
	velocity = dir * speed
	move_and_slide()
""",
				"params": ["speed", "player_path"],
				"category": "ai",
				"dimension": "2d",
				"difficulty": "beginner",
				"param_info": {
					"speed": {
						"default": 120.0,
						"range": [40.0, 400.0],
						"what": "Chase speed.",
						"typical": "60 slow zombie / 120 standard / 200 fast / 300+ racing",
						"increase": "Harder to escape.",
						"decrease": "Player can outrun the enemy."
					},
					"player_path": {
						"default": "",
						"range": [],
						"what": "Path to the player node.",
						"typical": "usually a NodePath set in the Inspector",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "Enemy that always moves toward the player, no matter where they are.",
					"where": "Attach to a CharacterBody2D. Set player_path in the Inspector.",
					"before": "Player must exist in the scene.",
					"after": "Add detection_area so the enemy only chases when the player is visible.",
					"why_optimized": "normalized() means speed is consistent regardless of distance.",
					"mistakes": "Without detection, this chases the player across the entire map — usually not what you want.",
					"related": ["enemy_patrol", "look_for_player", "navigation_agent_2d", "flee_ai"]
				}
			},
			"state_machine": {
				"phrases": ["state machine", "finite state machine", "fsm"],
				"code": """enum State { IDLE, WALK, ATTACK }

var state: State = State.IDLE

func _set_state(new_state: State) -> void:
	if state == new_state:
		return
	_exit_state(state)
	state = new_state
	_enter_state(state)

func _enter_state(s: State) -> void:
	match s:
		State.IDLE:
			pass
		State.WALK:
			pass
		State.ATTACK:
			pass

func _exit_state(_s: State) -> void:
	pass
""",
				"params": [],
				"category": "ai",
				"dimension": "any",
				"difficulty": "intermediate",
				"details": {
					"what": "A simple state machine with enter/exit hooks. The foundation for enemy behavior.",
					"where": "Attach to any node that needs to switch between behaviors.",
					"before": "Add your own states to the enum and their handlers in _enter_state.",
					"after": "Call _set_state(State.ATTACK) when the enemy spots the player.",
					"why_optimized": "Early-return when setting the same state avoids redundant work.",
					"mistakes": "Forgetting _exit_state means cleanup code never runs when leaving a state.",
					"related": ["enemy_patrol", "chase_player", "look_for_player"]
				}
			},
			"navigation_agent_2d": {
				"phrases": ["navigation agent 2d", "nav agent 2d", "pathfind 2d"],
				"code": """extends CharacterBody2D

@export var speed: float = 150.0
@export var target_path: NodePath

@onready var _agent: NavigationAgent2D = $NavigationAgent2D
@onready var _target: Node2D = get_node(target_path) as Node2D

func _physics_process(_delta: float) -> void:
	_agent.target_position = _target.global_position
	if _agent.is_navigation_finished():
		velocity = Vector2.ZERO
		move_and_slide()
		return
	var next := _agent.get_next_path_position()
	velocity = (next - global_position).normalized() * speed
	move_and_slide()
""",
				"params": ["speed", "target_path"],
				"category": "ai",
				"dimension": "2d",
				"difficulty": "intermediate",
				"param_info": {
					"speed": {
						"default": 150.0,
						"range": [40.0, 400.0],
						"what": "Movement speed along the path.",
						"typical": "80 slow / 150 standard / 300 fast",
						"increase": "Faster navigation.",
						"decrease": "Slower movement."
					},
					"target_path": {
						"default": "",
						"range": [],
						"what": "The node to chase. Usually the player.",
						"typical": "NodePath set in the Inspector",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "Uses Godot's navigation system to path around obstacles toward a target.",
					"where": "Attach to a CharacterBody2D. Add a NavigationAgent2D child. The scene needs a NavigationRegion2D with a baked nav mesh.",
					"before": "You must set up a NavigationRegion2D covering your walkable area.",
					"after": "Add a NavigationObstacle2D for dynamic blockers like boxes.",
					"why_optimized": "Only recomputes the target position each frame — path is cached by the agent.",
					"mistakes": "Forgetting to bake the navigation region means the agent just walks straight at walls.",
					"related": ["chase_player", "navigation_agent_3d", "enemy_patrol"]
				}
			},
			"navigation_agent_3d": {
				"phrases": ["navigation agent 3d", "nav agent 3d", "pathfind 3d"],
				"code": """extends CharacterBody3D

@export var speed: float = 3.0
@export var target_path: NodePath

@onready var _agent: NavigationAgent3D = $NavigationAgent3D
@onready var _target: Node3D = get_node(target_path) as Node3D

func _physics_process(_delta: float) -> void:
	_agent.target_position = _target.global_position
	if _agent.is_navigation_finished():
		velocity = Vector3.ZERO
		move_and_slide()
		return
	var next := _agent.get_next_path_position()
	velocity = (next - global_position).normalized() * speed
	move_and_slide()
""",
				"params": ["speed", "target_path"],
				"category": "ai",
				"dimension": "3d",
				"difficulty": "intermediate",
				"param_info": {
					"speed": {
						"default": 3.0,
						"range": [0.5, 15.0],
						"what": "Movement speed in meters per second.",
						"typical": "1.5 slow zombie / 3.0 standard / 6.0 fast / 8.0+ sprinting",
						"increase": "Faster chase.",
						"decrease": "Slow, menacing."
					},
					"target_path": {
						"default": "",
						"range": [],
						"what": "The target to path toward.",
						"typical": "NodePath to the player",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "3D navigation agent that walks around obstacles toward a target.",
					"where": "Attach to a CharacterBody3D. Add a NavigationAgent3D child. Scene needs a NavigationRegion3D.",
					"before": "Bake the navigation mesh in NavigationRegion3D.",
					"after": "Add a NavigationObstacle3D for dynamic blockers.",
					"why_optimized": "Agent caches the path; only the target updates each frame.",
					"mistakes": "Forgetting to bake nav mesh means the agent walks straight at walls.",
					"related": ["navigation_agent_2d", "chase_player", "state_machine"]
				}
			},
			"look_for_player": {
				"phrases": ["look for player", "enemy detect player", "vision cone"],
				"code": """extends Area2D

signal player_spotted(player: Node2D)

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_spotted.emit(body)
""",
				"params": [],
				"category": "ai",
				"dimension": "2d",
				"difficulty": "beginner",
				"details": {
					"what": "Emits a signal when the player enters the area. The trigger for switching from patrol to chase.",
					"where": "Attach to an Area2D child of the enemy. Give it a CollisionShape2D sized to the vision range.",
					"before": "Add the player to a group called 'player'.",
					"after": "Connect player_spotted to the enemy's chase logic.",
					"why_optimized": "Signal-based — no per-frame polling. The area is checked by the physics engine.",
					"mistakes": "Forgetting to add the player to the 'player' group means this never fires.",
					"related": ["detection_area", "chase_player", "state_machine"]
				}
			},
			"attack_player": {
				"phrases": ["enemy attack", "attack player", "enemy attacks"],
				"code": """@export var damage: int = 10
@export var attack_cooldown: float = 1.0

var _cooldown: float = 0.0

func _process(delta: float) -> void:
	_cooldown = max(_cooldown - delta, 0.0)

func try_attack(target: Node) -> void:
	if _cooldown > 0.0:
		return
	if target.has_method("take_damage"):
		target.take_damage(damage)
	_cooldown = attack_cooldown
""",
				"params": ["damage", "attack_cooldown"],
				"category": "ai",
				"dimension": "any",
				"difficulty": "beginner",
				"param_info": {
					"damage": {
						"default": 10,
						"range": [1, 100],
						"what": "Damage per hit.",
						"typical": "5 weak / 10 standard / 25 heavy / 50+ boss",
						"increase": "Deadlier enemy.",
						"decrease": "Less punishing."
					},
					"attack_cooldown": {
						"default": 1.0,
						"range": [0.2, 5.0],
						"what": "Seconds between attacks.",
						"typical": "0.5 aggressive / 1.0 standard / 2.0 slow brute",
						"increase": "Player has more recovery time.",
						"decrease": "Faster attacks, harder to dodge."
					}
				},
				"details": {
					"what": "Damages a target on a cooldown. Call try_attack(player) when the enemy is close enough.",
					"where": "Attach to the enemy. Call from detection logic or animation event.",
					"before": "Target must have take_damage().",
					"after": "Play an attack animation before applying damage.",
					"why_optimized": "max() clamps the cooldown in one line.",
					"mistakes": "Calling take_damage directly bypasses the cooldown — always use try_attack.",
					"related": ["chase_player", "look_for_player", "health_system"]
				}
			},
			"wander_ai": {
				"phrases": ["wander ai", "random movement ai", "roam ai"],
				"code": """@export var speed: float = 60.0
@export var wander_radius: float = 200.0

var _target: Vector2 = Vector2.ZERO
var _origin: Vector2 = Vector2.ZERO

func _ready() -> void:
	_origin = global_position
	_pick_target()

func _pick_target() -> void:
	_target = _origin + Vector2(randf_range(-1, 1), randf_range(-1, 1)) * wander_radius

func _physics_process(_delta: float) -> void:
	var dir := (_target - global_position).normalized()
	velocity = dir * speed
	move_and_slide()
	if global_position.distance_to(_target) < 8.0:
		_pick_target()
""",
				"params": ["speed", "wander_radius"],
				"category": "ai",
				"dimension": "2d",
				"difficulty": "beginner",
				"param_info": {
					"speed": {
						"default": 60.0,
						"range": [20.0, 200.0],
						"what": "Wander speed.",
						"typical": "40 idle NPC / 60 standard / 100+ skittish",
						"increase": "Faster wandering.",
						"decrease": "Slower, lazier."
					},
					"wander_radius": {
						"default": 200.0,
						"range": [20.0, 2000.0],
						"what": "How far from the origin the character wanders.",
						"typical": "80 small yard / 200 standard / 500+ open world",
						"increase": "Larger wander area.",
						"decrease": "Stays closer to origin."
					}
				},
				"details": {
					"what": "Picks random points near an origin and walks between them.",
					"where": "Attach to a CharacterBody2D. Good for neutral NPCs, animals, ambient enemies.",
					"before": "None.",
					"after": "Add a wait timer between wander steps so it feels less robotic.",
					"why_optimized": "Re-picks a target only when arrived — no per-frame randomness.",
					"mistakes": "Re-picking every frame makes the character jitter in place.",
					"related": ["enemy_patrol", "chase_player", "flee_ai"]
				}
			},
			"flee_ai": {
				"phrases": ["flee ai", "run away ai", "flee from player"],
				"code": """@export var speed: float = 150.0
@export var player_path: NodePath

@onready var _player: Node2D = get_node(player_path) as Node2D

func _physics_process(_delta: float) -> void:
	var dir := (global_position - _player.global_position).normalized()
	velocity = dir * speed
	move_and_slide()
""",
				"params": ["speed", "player_path"],
				"category": "ai",
				"dimension": "2d",
				"difficulty": "beginner",
				"param_info": {
					"speed": {
						"default": 150.0,
						"range": [40.0, 400.0],
						"what": "Flee speed.",
						"typical": "80 panicked slow / 150 standard / 250 fast prey",
						"increase": "Harder to catch.",
						"decrease": "Easier to catch."
					},
					"player_path": {
						"default": "",
						"range": [],
						"what": "The player node to flee from.",
						"typical": "NodePath set in the Inspector",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "Enemy that runs away from the player.",
					"where": "Attach to a CharacterBody2D. Set player_path in the Inspector.",
					"before": "Player must exist in the scene.",
					"after": "Combine with detection_area to only flee when spotted.",
					"why_optimized": "Subtracting positions instead of adding flips the direction — same math as chase.",
					"mistakes": "Fleeing forever without a stop condition means the enemy runs into a corner and jitters.",
					"related": ["chase_player", "wander_ai", "detection_area"]
				}
			},
			"detection_area": {
				"phrases": ["detection area", "enemy detection", "vision area"],
				"code": """extends Area2D

signal detected(body: Node2D)
signal lost(body: Node2D)

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		detected.emit(body)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		lost.emit(body)
""",
				"params": [],
				"category": "ai",
				"dimension": "2d",
				"difficulty": "beginner",
				"details": {
					"what": "Emits detected and lost signals when the player enters or leaves.",
					"where": "Attach to an Area2D child of the enemy.",
					"before": "Player must be in the 'player' group.",
					"after": "Connect detected to start chasing, lost to return to patrol.",
					"why_optimized": "Two signals cover both transitions — no polling.",
					"mistakes": "Forgetting to handle 'lost' means the enemy never stops chasing.",
					"related": ["look_for_player", "chase_player", "state_machine"]
				}
			}
		}
	}

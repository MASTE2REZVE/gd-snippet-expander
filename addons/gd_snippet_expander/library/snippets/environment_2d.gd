@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"snippets": {
			"spring_2d": {
				"phrases": ["spring", "bounce pad", "jump pad", "trampoline"],
				"code": """extends Area2D

@export var bounce_velocity: float = -700.0
@export var horizontal_boost: float = 0.0
@export var cooldown: float = 0.2

var _cooldown_timer: float = 0.0
var _sprite: Node2D = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_sprite = get_node_or_null("Sprite")

func _process(delta: float) -> void:
	if _cooldown_timer > 0.0:
		_cooldown_timer -= delta

func _on_body_entered(body: Node2D) -> void:
	if _cooldown_timer > 0.0:
		return
	if not (body is CharacterBody2D):
		return
	if body.has_method("take_damage") and not body.is_in_group("player"):
		pass
	var cb := body as CharacterBody2D
	var vel := cb.velocity
	vel.y = bounce_velocity
	if absf(horizontal_boost) > 0.0:
		vel.x = sign(vel.x) * horizontal_boost if absf(vel.x) > 1.0 else horizontal_boost
	cb.velocity = vel
	_cooldown_timer = cooldown
	_animate_bounce()

func _animate_bounce() -> void:
	if _sprite == null:
		return
	var original := _sprite.position
	var tween := create_tween()
	tween.tween_property(_sprite, "position:y", original.y - 4.0, 0.05)
	tween.tween_property(_sprite, "position:y", original.y, 0.15)
""",
				"params": ["bounce_velocity", "horizontal_boost", "cooldown"],
				"category": "environment",
				"subcategory": "spring",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "2d",
				"difficulty": "beginner",
				"param_info": {
					"bounce_velocity": {
						"default": -700.0,
						"range": [-1500.0, -200.0],
						"what": "Upward velocity applied when something lands on the spring.",
						"typical": "-400 small bounce / -700 standard / -1200 super jump",
						"increase": "Higher bounce.",
						"decrease": "Lower."
					},
					"horizontal_boost": {
						"default": 0.0,
						"range": [-500.0, 500.0],
						"what": "Optional horizontal speed added on launch.",
						"typical": "0 straight up / 200 angled launch / 500 long jump",
						"increase": "More horizontal push.",
						"decrease": "Less."
					},
					"cooldown": {
						"default": 0.2,
						"range": [0.05, 1.0],
						"what": "Seconds before the spring can fire again.",
						"typical": "0.2 standard / 0.5 prevents double-bounce",
						"increase": "Longer cooldown.",
						"decrease": "Shorter."
					}
				},
				"details": {
					"what": "Bounce pad that launches any CharacterBody2D upward when touched. Has a cooldown to prevent multi-bounce.",
					"where": "Attach to an Area2D with a CollisionShape2D child. Optional Sprite2D for the visual.",
					"before": "None.",
					"after": "Add a bounce sound and a small particle burst for feedback. See particle_explosion for the effect.",
					"why_optimized": "Direct velocity assignment — the physics engine takes it from there. Cooldown prevents physics jitter.",
					"mistakes": "No cooldown means the spring fires every physics frame the player overlaps it, sending them to space.",
					"related": ["platformer_movement_2d", "particle_explosion", "play_sound"]
				}
			},
			"wind_zone_2d": {
				"phrases": ["wind zone", "wind area", "push zone", "wind 2d"],
				"code": """extends Area2D

@export var wind_direction: Vector2 = Vector2(1, 0)
@export var wind_strength: float = 200.0
@export var affect_gravity: bool = false
@export var gravity_reduction: float = 0.5

var _bodies_in_zone: Array = []

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _physics_process(delta: float) -> void:
	var force := wind_direction.normalized() * wind_strength
	for body in _bodies_in_zone:
		if not is_instance_valid(body):
			continue
		if body is CharacterBody2D:
			var cb := body as CharacterBody2D
			cb.velocity += force * delta
			if affect_gravity:
				cb.velocity.y -= cb.get_gravity().y * gravity_reduction * delta

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		_bodies_in_zone.append(body)

func _on_body_exited(body: Node2D) -> void:
	_bodies_in_zone.erase(body)
""",
				"params": ["wind_direction", "wind_strength", "affect_gravity", "gravity_reduction"],
				"category": "environment",
				"subcategory": "wind",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "2d",
				"difficulty": "intermediate",
				"param_info": {
					"wind_direction": {
						"default": [1, 0],
						"range": [],
						"what": "Direction the wind pushes. Normalized on use.",
						"typical": "[1, 0] rightward / [-1, 0] leftward / [0, -1] updraft",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"wind_strength": {
						"default": 200.0,
						"range": [20.0, 2000.0],
						"what": "Force applied per second.",
						"typical": "100 gentle / 200 standard / 600+ strong wind",
						"increase": "Stronger push.",
						"decrease": "Weaker."
					},
					"affect_gravity": {
						"default": false,
						"range": [],
						"what": "True means the wind also reduces gravity — useful for updrafts.",
						"typical": "false normal wind / true updraft columns",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"gravity_reduction": {
						"default": 0.5,
						"range": [0.0, 1.0],
						"what": "Fraction of gravity reduced when affect_gravity is on.",
						"typical": "0.5 half-gravity / 1.0 zero-g / 1.5 anti-gravity",
						"increase": "More weightless.",
						"decrease": "Less."
					}
				},
				"details": {
					"what": "Area2D that applies a continuous force to CharacterBody2D nodes inside it. Classic updraft column or wind tunnel.",
					"where": "Attach to an Area2D with a CollisionShape2D. Position and size the collision to match the wind area.",
					"before": "Character bodies must have a velocity property (CharacterBody2D).",
					"after": "Add particle streaks moving in the wind direction for visual clarity.",
					"why_optimized": "Only processes bodies currently inside the zone. Force multiplication is one vector op per body.",
					"mistakes": "Applying wind in _process instead of _physics_process makes the force frame-rate dependent and inconsistent.",
					"related": ["water_zone_2d", "particle_trail", "platformer_movement_2d"]
				}
			},
			"water_zone_2d": {
				"phrases": ["water zone", "swim area", "water 2d", "underwater 2d"],
				"code": """extends Area2D

signal player_entered_water
signal player_exited_water

@export var buoyancy: float = 100.0
@export var drag: float = 3.0
@export var swim_speed: float = 80.0
@export var gravity_multiplier: float = 0.3

var _in_water_bodies: Array = []

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _physics_process(delta: float) -> void:
	for body in _in_water_bodies:
		if not is_instance_valid(body) or not (body is CharacterBody2D):
			continue
		var cb := body as CharacterBody2D
		# Buoyancy counteracts gravity
		cb.velocity.y -= buoyancy * delta
		# Drag slows movement
		cb.velocity = cb.velocity.lerp(Vector2.ZERO, drag * delta)
		# Optional: allow swimming up with jump input
		if body.is_in_group("player") and Input.is_action_pressed("jump"):
			cb.velocity.y = min(cb.velocity.y, -swim_speed)

func _on_body_entered(body: Node2D) -> void:
	if not (body is CharacterBody2D):
		return
	if _in_water_bodies.has(body):
		return
	_in_water_bodies.append(body)
	if body.is_in_group("player"):
		player_entered_water.emit()

func _on_body_exited(body: Node2D) -> void:
	_in_water_bodies.erase(body)
	if body.is_in_group("player"):
		player_exited_water.emit()

func is_in_water(body: Node) -> bool:
	return _in_water_bodies.has(body)
""",
				"params": ["buoyancy", "drag", "swim_speed", "gravity_multiplier"],
				"category": "environment",
				"subcategory": "water",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "2d",
				"difficulty": "intermediate",
				"required_actions": ["jump"],
				"param_info": {
					"buoyancy": {
						"default": 100.0,
						"range": [0.0, 800.0],
						"what": "Upward force counteracting gravity.",
						"typical": "50 slow sink / 100 neutral / 300+ float up",
						"increase": "More floaty.",
						"decrease": "Sinks faster."
					},
					"drag": {
						"default": 3.0,
						"range": [0.5, 15.0],
						"what": "How much the water slows movement.",
						"typical": "1.0 slight / 3.0 standard / 8.0+ heavy",
						"increase": "More sluggish.",
						"decrease": "More responsive."
					},
					"swim_speed": {
						"default": 80.0,
						"range": [20.0, 300.0],
						"what": "Upward speed when jump is held underwater.",
						"typical": "40 slow paddle / 80 standard / 200 fast swim",
						"increase": "Swim up faster.",
						"decrease": "Slower."
					}
				},
				"details": {
					"what": "Water zone that applies buoyancy and drag to bodies inside it. Player can swim up by holding jump.",
					"where": "Attach to an Area2D with a CollisionShape2D sized to cover the water. Overlap the player's swim region.",
					"before": "Input action 'jump' exists.",
					"after": "Change the player's sprite animation when they enter water. Slow all movement and disable normal jumping.",
					"why_optimized": "Only processes bodies in the list. All operations are vector additions and lerps.",
					"mistakes": "Not disabling normal gravity while underwater means the two systems fight. Apply buoyancy in place of gravity or scale gravity down.",
					"related": ["wind_zone_2d", "platformer_movement_2d", "particle_sparkle"]
				}
			},
			"ice_surface_2d": {
				"phrases": ["ice surface", "slippery ice", "ice physics", "slippery floor"],
				"code": """extends Area2D

# Add this to the player's script or use it as a standalone
# surface detector. When the player is on an ice surface, apply low
# friction.

@export var ice_friction: float = 200.0
@export var normal_friction: float = 1500.0

var _on_ice: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_on_ice = true
		if body.has_method("set_surface_friction"):
			body.call("set_surface_friction", ice_friction)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_on_ice = false
		if body.has_method("set_surface_friction"):
			body.call("set_surface_friction", normal_friction)

func is_player_on_ice() -> bool:
	return _on_ice

# Add this to your player script:
#
# @export var friction: float = 1500.0
#
# func set_surface_friction(value: float) -> void:
#     friction = value
#
# In _physics_process, use friction for deceleration:
#     if input_dir.length() < 0.1:
#         velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
""",
				"params": ["ice_friction", "normal_friction"],
				"category": "environment",
				"subcategory": "surface",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "2d",
				"difficulty": "intermediate",
				"param_info": {
					"ice_friction": {
						"default": 200.0,
						"range": [50.0, 800.0],
						"what": "Deceleration rate while on ice.",
						"typical": "100 very slippery / 200 standard / 400 mildly slick",
						"increase": "Less slippery.",
						"decrease": "More."
					},
					"normal_friction": {
						"default": 1500.0,
						"range": [500.0, 5000.0],
						"what": "Deceleration rate on normal ground.",
						"typical": "1200 standard / 2500 hard stop",
						"increase": "Snappier stop.",
						"decrease": "Smoother."
					}
				},
				"details": {
					"what": "Area2D that tells the player they're on ice. Player script swaps its friction value to something much lower.",
					"where": "Attach to an Area2D covering the ice surface. Player script must have a set_surface_friction method and use friction in deceleration.",
					"before": "Player script with a friction-based deceleration in _physics_process.",
					"after": "Add a small ice particle when the player skids or changes direction.",
					"why_optimized": "Signal-driven, no per-frame checks. Friction change is one assignment.",
					"mistakes": "Applying ice friction directly in the Area instead of via the player means it's not reset when the player leaves.",
					"related": ["platformer_movement_2d", "mud_zone_2d", "particle_dust"]
				}
			},
			"conveyor_2d": {
				"phrases": ["conveyor belt", "conveyor 2d", "moving floor", "belt"],
				"code": """extends Area2D

@export var belt_speed: float = 150.0
@export var direction: Vector2 = Vector2.RIGHT

var _bodies_on_belt: Array = []
var _sprite: Node2D = null
var _texture_offset: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_sprite = get_node_or_null("Sprite")

func _physics_process(delta: float) -> void:
	for body in _bodies_on_belt:
		if not is_instance_valid(body) or not (body is CharacterBody2D):
			continue
		var cb := body as CharacterBody2D
		cb.velocity += direction.normalized() * belt_speed * delta
	_animate_belt(delta)

func _animate_belt(delta: float) -> void:
	if _sprite == null or not (_sprite is Sprite2D):
		return
	var sprite := _sprite as Sprite2D
	if sprite.texture == null:
		return
	_texture_offset += belt_speed * delta
	var tex_size := sprite.texture.get_size()
	if tex_size.x > 0:
		sprite.region_enabled = true
		sprite.region_rect.position.x = fmod(_texture_offset, tex_size.x)

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		_bodies_on_belt.append(body)

func _on_body_exited(body: Node2D) -> void:
	_bodies_on_belt.erase(body)
""",
				"params": ["belt_speed", "direction"],
				"category": "environment",
				"subcategory": "surface",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "2d",
				"difficulty": "intermediate",
				"param_info": {
					"belt_speed": {
						"default": 150.0,
						"range": [20.0, 500.0],
						"what": "Pixels per second the belt pushes bodies.",
						"typical": "60 slow / 150 standard / 350 fast",
						"increase": "Faster belt.",
						"decrease": "Slower."
					},
					"direction": {
						"default": [1, 0],
						"range": [],
						"what": "Direction the belt moves.",
						"typical": "[1, 0] right / [-1, 0] left / [0, -1] up",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "Conveyor belt that pushes CharacterBody2D nodes along a direction. Animates the sprite's texture region for a scrolling look.",
					"where": "Attach to an Area2D with a Sprite2D child. Set the sprite's region_enabled to true in the Inspector.",
					"before": "Sprite texture should be tileable (repeats seamlessly).",
					"after": "Reverse the belt by setting direction to [-1, 0]. Reset the sprite's texture_offset when reversing.",
					"why_optimized": "Only affects bodies in the list. Sprite animation uses region offset — no per-frame texture swap.",
					"mistakes": "Forgetting to enable region_enabled means the texture offset does nothing.",
					"related": ["ice_surface_2d", "mud_zone_2d", "wind_zone_2d"]
				}
			},
			"mud_zone_2d": {
				"phrases": ["mud zone", "mud 2d", "slowing area", "sticky surface"],
				"code": """extends Area2D

signal entered_mud
signal exited_mud

@export var speed_multiplier: float = 0.4
@export var jump_multiplier: float = 0.6

var _affected_bodies: Dictionary = {}

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if not body.has_method("set_speed_modifier"):
		return
	var previous_speed = body.get("speed")
	var previous_jump = body.get("jump_velocity")
	if previous_speed != null:
		_affected_bodies[body] = {
			"speed": previous_speed,
			"jump_velocity": previous_jump
		}
		body.call("set_speed_modifier", float(previous_speed) * speed_multiplier)
		if previous_jump != null:
			body.set("jump_velocity", float(previous_jump) * jump_multiplier)
	entered_mud.emit()

func _on_body_exited(body: Node2D) -> void:
	if not _affected_bodies.has(body):
		return
	var saved: Dictionary = _affected_bodies[body]
	if body.has_method("set_speed_modifier"):
		body.call("set_speed_modifier", saved.speed)
	if saved.jump_velocity != null:
		body.set("jump_velocity", saved.jump_velocity)
	_affected_bodies.erase(body)
	exited_mud.emit()

# Add to player script:
#
# func set_speed_modifier(value: float) -> void:
#     speed = value
""",
				"params": ["speed_multiplier", "jump_multiplier"],
				"category": "environment",
				"subcategory": "surface",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "2d",
				"difficulty": "intermediate",
				"param_info": {
					"speed_multiplier": {
						"default": 0.4,
						"range": [0.1, 0.9],
						"what": "Multiplier applied to the player's speed in mud.",
						"typical": "0.3 very sticky / 0.4 standard / 0.7 mild",
						"increase": "Less slowdown.",
						"decrease": "More."
					},
					"jump_multiplier": {
						"default": 0.6,
						"range": [0.1, 1.0],
						"what": "Multiplier applied to jump velocity in mud.",
						"typical": "0.5 stunted jumps / 0.6 standard / 1.0 normal jump",
						"increase": "Less jump penalty.",
						"decrease": "More."
					}
				},
				"details": {
					"what": "Slow mud zone that reduces player speed and jump height. Restores original values when the player leaves.",
					"where": "Attach to an Area2D covering the mud. Player must be in group 'player' and have a set_speed_modifier method.",
					"before": "Player script must expose 'speed' and 'jump_velocity' as properties and have set_speed_modifier.",
					"after": "Add a sloshing sound and small splash particles on entry.",
					"why_optimized": "Stores original values per body — safe even if two mud zones overlap. Dictionary lookup is O(1).",
					"mistakes": "If the player dies or respawns while in mud, the original values aren't restored. Clear the affected_bodies dictionary on death.",
					"related": ["ice_surface_2d", "water_zone_2d", "particle_dust"]
				}
			}
		}
	}

@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"snippets": {
			"topdown_8dir": {
				"phrases": ["8 direction movement", "8dir movement", "topdown 8 direction", "diagonal movement"],
				"code": """extends CharacterBody2D

@export var speed: float = 200.0
@export var acceleration: float = 1200.0
@export var friction: float = 1500.0

func _physics_process(delta: float) -> void:
	var input_dir := Input.get_vector("left", "right", "up", "down")
	var target_velocity := input_dir * speed
	if input_dir.length() > 0.1:
		velocity = velocity.move_toward(target_velocity, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	move_and_slide()
""",
				"params": ["speed", "acceleration", "friction"],
				"category": "topdown",
				"subcategory": "movement",
				"dimension": "2d",
				"difficulty": "beginner",
				"required_actions": ["left", "right", "up", "down"],
				"param_info": {
					"speed": {
						"default": 200.0,
						"range": [50.0, 500.0],
						"what": "Maximum movement speed.",
						"typical": "120 slow / 200 standard / 350 fast",
						"increase": "Faster.",
						"decrease": "Slower."
					},
					"acceleration": {
						"default": 1200.0,
						"range": [200.0, 5000.0],
						"what": "How fast the character reaches max speed.",
						"typical": "600 floaty / 1200 standard / 3000 snappy",
						"increase": "Snappier start.",
						"decrease": "More slippery."
					},
					"friction": {
						"default": 1500.0,
						"range": [200.0, 5000.0],
						"what": "How fast the character stops when no input.",
						"typical": "800 slidey ice / 1500 standard / 3000 hard stop",
						"increase": "Faster stop.",
						"decrease": "More momentum."
					}
				},
				"details": {
					"what": "Smooth 8-direction top-down movement with acceleration and friction. Feels better than instant velocity changes.",
					"where": "Attach to a CharacterBody2D with a CollisionShape2D child.",
					"before": "Input actions left, right, up, down in Input Map.",
					"after": "For grid-locked movement, use grid_movement_2d instead.",
					"why_optimized": "move_toward is one vector operation. No delta multiplication errors.",
					"mistakes": "Multiplying velocity directly by delta causes faster-than-intended movement. move_toward already accounts for frame time.",
					"related": ["topdown_movement_2d", "grid_movement_2d", "sprite_flip_direction"]
				}
			},
			"grid_movement_2d": {
				"phrases": ["grid movement", "tile movement", "step movement", "pokemon movement"],
				"code": """extends CharacterBody2D

@export var tile_size: float = 16.0
@export var move_duration: float = 0.2

var _moving: bool = false
var _target_position: Vector2 = Vector2.ZERO

func _unhandled_input(event: InputEvent) -> void:
	if _moving:
		return
	var dir := Vector2.ZERO
	if event.is_action_pressed("left"):
		dir = Vector2.LEFT
	elif event.is_action_pressed("right"):
		dir = Vector2.RIGHT
	elif event.is_action_pressed("up"):
		dir = Vector2.UP
	elif event.is_action_pressed("down"):
		dir = Vector2.DOWN
	if dir == Vector2.ZERO:
		return
	# Snap to grid before moving
	var snapped := global_position.snapped(Vector2(tile_size, tile_size))
	global_position = snapped
	_start_move(snapped + dir * tile_size)

func _start_move(new_position: Vector2) -> void:
	_moving = true
	_target_position = new_position
	var tween := create_tween()
	tween.tween_property(self, "global_position", _target_position, move_duration)
	tween.finished.connect(_on_move_done)

func _on_move_done() -> void:
	_moving = false

func is_moving() -> bool:
	return _moving
""",
				"params": ["tile_size", "move_duration"],
				"category": "topdown",
				"subcategory": "grid",
				"dimension": "2d",
				"difficulty": "intermediate",
				"required_actions": ["left", "right", "up", "down"],
				"param_info": {
					"tile_size": {
						"default": 16.0,
						"range": [8.0, 64.0],
						"what": "Grid cell size in pixels. Should match your TileMap's cell size.",
						"typical": "16 classic / 32 modern / 48+ chunky",
						"increase": "Bigger steps.",
						"decrease": "Smaller."
					},
					"move_duration": {
						"default": 0.2,
						"range": [0.05, 1.0],
						"what": "Seconds per grid step.",
						"typical": "0.1 fast / 0.2 standard / 0.4 slow RPG",
						"increase": "Slower stepping.",
						"decrease": "Faster."
					}
				},
				"details": {
					"what": "Classic grid-locked movement — one tile per keypress. Like Pokemon or old Final Fantasy.",
					"where": "Attach to a CharacterBody2D. Set tile_size to match the TileMap cell size.",
					"before": "Input actions left, right, up, down. Player starting position should be grid-aligned.",
					"after": "For collision, do a raycast before starting the move to check if the target tile is walkable.",
					"why_optimized": "Tween handles interpolation. snapped() ensures perfect grid alignment even after knockback.",
					"mistakes": "Not snapping before moving causes the player to drift off-grid over time. Always snap first.",
					"related": ["topdown_8dir", "tilemap_query", "topdown_movement_2d"]
				}
			},
			"topdown_look_direction": {
				"phrases": ["topdown look direction", "face movement direction", "rotate to movement", "aim direction topdown"],
				"code": """extends CharacterBody2D

@export var speed: float = 200.0
@export var rotate_to_movement: bool = true
@export var rotate_speed: float = 12.0

var _last_direction: Vector2 = Vector2.RIGHT

func _physics_process(delta: float) -> void:
	var input_dir := Input.get_vector("left", "right", "up", "down")
	velocity = input_dir * speed
	move_and_slide()
	if input_dir.length() > 0.1:
		_last_direction = input_dir.normalized()
	if rotate_to_movement:
		var target_angle := _last_direction.angle()
		rotation = lerp_angle(rotation, target_angle, rotate_speed * delta)

func get_aim_direction() -> Vector2:
	return _last_direction

func aim_at(world_position: Vector2) -> void:
	_last_direction = (world_position - global_position).normalized()
	if rotate_to_movement:
		rotation = _last_direction.angle()
""",
				"params": ["speed", "rotate_to_movement", "rotate_speed"],
				"category": "topdown",
				"subcategory": "direction",
				"dimension": "2d",
				"difficulty": "beginner",
				"param_info": {
					"rotate_to_movement": {
						"default": true,
						"range": [],
						"what": "True to auto-rotate the sprite to face movement direction.",
						"typical": "true for shooters / false for RPGs with directional sprites",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"rotate_speed": {
						"default": 12.0,
						"range": [1.0, 50.0],
						"what": "How fast the rotation catches up. Higher = snappier.",
						"typical": "5 floaty / 12 standard / 30 instant-feel",
						"increase": "Faster turning.",
						"decrease": "Slower."
					}
				},
				"details": {
					"what": "Rotates the sprite to face its movement direction. Uses lerp_angle for smooth turning without spinning the long way around.",
					"where": "Attach to a top-down CharacterBody2D with a rotated sprite or with rotation applied directly to the body.",
					"before": "Input actions left, right, up, down.",
					"after": "Use get_aim_direction() to know where bullets or attacks should fire.",
					"why_optimized": "lerp_angle handles wraparound correctly. Caching _last_direction avoids recalculating from velocity when stopped.",
					"mistakes": "Using rotation directly without lerp_angle makes the sprite spin a full circle when turning past 180 degrees.",
					"related": ["topdown_8dir", "ranged_attack", "topdown_movement_2d"]
				}
			},
			"topdown_dash_8dir": {
				"phrases": ["topdown dash", "8 direction dash", "dash topdown", "roll dodge"],
				"code": """extends CharacterBody2D

@export var dash_speed: float = 500.0
@export var dash_duration: float = 0.15
@export var dash_cooldown: float = 0.5
@export var invincible_during_dash: bool = true

var _dashing: bool = false
var _can_dash: bool = true
var _dash_direction: Vector2 = Vector2.RIGHT

signal dash_started(direction: Vector2)
signal dash_ended

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("dash") and _can_dash:
		var input_dir := Input.get_vector("left", "right", "up", "down")
		if input_dir.length() < 0.1:
			input_dir = Vector2.RIGHT.rotated(rotation)
		_start_dash(input_dir.normalized())

func _start_dash(dir: Vector2) -> void:
	_dashing = true
	_can_dash = false
	_dash_direction = dir
	dash_started.emit(dir)
	if invincible_during_dash:
		_set_invincible(true)
	await get_tree().create_timer(dash_duration).timeout
	if invincible_during_dash:
		_set_invincible(false)
	_dashing = false
	dash_ended.emit()
	await get_tree().create_timer(dash_cooldown).timeout
	_can_dash = true

func _physics_process(_delta: float) -> void:
	if _dashing:
		velocity = _dash_direction * dash_speed
		move_and_slide()

func _set_invincible(value: bool) -> void:
	if has_method("set_invincible"):
		call("set_invincible", value)

func is_dashing() -> bool:
	return _dashing
""",
				"params": ["dash_speed", "dash_duration", "dash_cooldown", "invincible_during_dash"],
				"category": "topdown",
				"subcategory": "movement",
				"dimension": "2d",
				"difficulty": "intermediate",
				"required_actions": ["dash"],
				"param_info": {
					"dash_speed": {
						"default": 500.0,
						"range": [200.0, 1500.0],
						"what": "Velocity during the dash.",
						"typical": "300 short / 500 standard / 1000+ teleport-feel",
						"increase": "Longer dash distance.",
						"decrease": "Shorter."
					},
					"dash_duration": {
						"default": 0.15,
						"range": [0.05, 0.5],
						"what": "How long the dash lasts.",
						"typical": "0.1 snappy / 0.15 standard / 0.3 heavy",
						"increase": "Longer dash.",
						"decrease": "Shorter."
					},
					"invincible_during_dash": {
						"default": true,
						"range": [],
						"what": "Whether the player dodges damage while dashing.",
						"typical": "true for action games / false for platformers",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "8-direction dash with optional invincibility. Classic dodge-roll mechanic for action games.",
					"where": "Attach to a top-down CharacterBody2D. Create input action 'dash' in Input Map.",
					"before": "Input actions: dash, left, right, up, down. Player can have set_invincible for the i-frame integration.",
					"after": "Add a dash trail particle effect and change the sprite to a 'roll' animation during the dash.",
					"why_optimized": "Cache direction once at dash start, then apply every frame. No input checks during the dash.",
					"mistakes": "Not caching direction means the player can steer mid-dash. That makes dashes feel inconsistent.",
					"related": ["dash_2d", "invincibility_frames", "particle_trail"]
				}
			},
			"topdown_interaction_prompt": {
				"phrases": ["interaction prompt", "press e prompt", "nearby npc prompt", "interact hint"],
				"code": """extends Area2D

signal player_nearby(body: Node2D)
signal player_left(body: Node2D)

@export var prompt_scene: PackedScene
@export var prompt_offset: Vector2 = Vector2(0, -40)

var _prompt: Node = null
var _current_body: Node2D = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_current_body = body
	_show_prompt()
	player_nearby.emit(body)

func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_current_body = null
	_hide_prompt()
	player_left.emit(body)

func _show_prompt() -> void:
	if prompt_scene == null:
		return
	_prompt = prompt_scene.instantiate()
	if _prompt is Node2D:
		(_prompt as Node2D).global_position = global_position + prompt_offset
	get_tree().current_scene.add_child(_prompt)

func _hide_prompt() -> void:
	if _prompt != null and is_instance_valid(_prompt):
		_prompt.queue_free()
	_prompt = null
""",
				"params": ["prompt_scene", "prompt_offset"],
				"category": "topdown",
				"subcategory": "interaction",
				"dimension": "2d",
				"difficulty": "beginner",
				"param_info": {
					"prompt_scene": {
						"default": "",
						"range": [],
						"what": "PackedScene for the prompt (a sprite or label showing 'press E').",
						"typical": "a Label or Sprite2D with [E] text",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"prompt_offset": {
						"default": [0, -40],
						"range": [],
						"what": "Offset from the Area2D's center where the prompt appears.",
						"typical": "[0, -40] above the object / [0, -60] high above",
						"increase": "Higher offscreen direction.",
						"decrease": "Lower."
					}
				},
				"details": {
					"what": "Shows a floating prompt above an interactable object when the player enters its range.",
					"where": "Attach to an Area2D child of the NPC or interactable object. Set prompt_scene in the Inspector.",
					"before": "Player in group 'player'. A prompt scene (Label or Sprite2D).",
					"after": "Combine with npc_interactable to actually fire the dialogue when the player presses Interact.",
					"why_optimized": "Prompt is spawned on demand and freed on exit — no idle prompt nodes sitting in the scene.",
					"mistakes": "Adding the prompt as a child of the Area2D means it rotates with the NPC. Add to the current_scene and set global_position.",
					"related": ["npc_interactable", "pickup_range", "tooltip"]
				}
			}
		}
	}

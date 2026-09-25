@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"snippets": {
			"one_way_platform": {
				"phrases": ["one way platform", "jump through platform", "drop through platform", "one-way collision"],
				"code": """extends StaticBody2D

@export var platform_thickness: float = 8.0
@export var platform_width: float = 96.0

func _ready() -> void:
	# One-way collision is set on the CollisionShape2D, not here.
	# In the Inspector:
	#   - Select the CollisionShape2D child.
	#   - Set 'One Way Collision' to ON.
	#   - The rectangle should be a thin horizontal strip.
	pass

func set_one_way_rectangle() -> void:
	var shape_node := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node == null:
		return
	if shape_node.shape is RectangleShape2D:
		var rect := shape_node.shape as RectangleShape2D
		rect.size = Vector2(platform_width, platform_thickness)
""",
				"params": ["platform_thickness", "platform_width"],
				"category": "platformer",
				"subcategory": "platforms",
				"dimension": "2d",
				"difficulty": "beginner",
				"param_info": {
					"platform_thickness": {
						"default": 8.0,
						"range": [2.0, 32.0],
						"what": "Height of the platform's collision rectangle, in pixels.",
						"typical": "4 very thin / 8 standard / 16 chunky",
						"increase": "Thicker collision.",
						"decrease": "Thinner."
					},
					"platform_width": {
						"default": 96.0,
						"range": [16.0, 1000.0],
						"what": "Width of the platform, in pixels.",
						"typical": "32 small / 96 standard / 200 wide",
						"increase": "Wider platform.",
						"decrease": "Narrower."
					}
				},
				"details": {
					"what": "A thin StaticBody2D platform the player can jump through from below but stand on from above. The one-way behavior comes from the CollisionShape2D's One Way Collision property.",
					"where": "Attach to a StaticBody2D with a CollisionShape2D child. Set One Way Collision to ON in the Inspector.",
					"before": "None.",
					"after": "To let the player drop through, add a drop-through snippet that temporarily disables the collision shape.",
					"why_optimized": "One-way collision is handled by the physics engine — no code needed for the basic behavior.",
					"mistakes": "Forgetting to enable One Way Collision means the platform blocks from both sides. The property is on the shape, not the body.",
					"related": ["platform_drop_through", "moving_platform", "platformer_movement_2d"]
				}
			},
			"platform_drop_through": {
				"phrases": ["drop through platform", "fall through platform", "down through platform", "one way drop"],
				"code": """extends CharacterBody2D

@export var drop_time: float = 0.25

var _dropping: bool = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("down") and is_on_floor():
		_try_drop_through()

func _try_drop_through() -> void:
	if _dropping:
		return
	# Find one-way platforms directly under the player
	var space := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(
		global_position,
		global_position + Vector2(0, 8)
	)
	query.collide_with_areas = false
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return
	var body = hit.get("collider")
	if body == null or not (body is StaticBody2D):
		return
	_drop_start(body)

func _drop_start(platform: StaticBody2D) -> void:
	_dropping = true
	var shape := platform.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape == null:
		_dropping = false
		return
	var original_layer := shape.get_collision_layer()
	var original_mask := shape.get_collision_mask()
	shape.set_collision_layer_value(1, false)
	shape.set_collision_mask_value(1, false)
	await get_tree().create_timer(drop_time).timeout
	if is_instance_valid(shape):
		shape.collision_layer = original_layer
		shape.collision_mask = original_mask
	_dropping = false
""",
				"params": ["drop_time"],
				"category": "platformer",
				"subcategory": "platforms",
				"dimension": "2d",
				"difficulty": "intermediate",
				"required_actions": ["down"],
				"param_info": {
					"drop_time": {
						"default": 0.25,
						"range": [0.1, 1.0],
						"what": "Seconds the platform stays passable.",
						"typical": "0.2 quick / 0.25 standard / 0.5 slow fall",
						"increase": "Longer fall through time.",
						"decrease": "Shorter."
					}
				},
				"details": {
					"what": "When the player presses Down while standing on a one-way platform, temporarily disables its collision so the player falls through.",
					"where": "Attach to the player CharacterBody2D. Requires an input action named 'down'.",
					"before": "One-way platforms with collision layer 1. Input action 'down' bound to S or Down arrow.",
					"after": "Trigger a small squash animation and a whoosh sound for feedback.",
					"why_optimized": "Uses a short raycast to find the platform instead of scanning all bodies. Collision is restored via await rather than a Timer node.",
					"mistakes": "Not restoring the collision layer after the drop leaves the platform permanently passable.",
					"related": ["one_way_platform", "platformer_movement_2d", "squash_stretch"]
				}
			},
			"moving_platform": {
				"phrases": ["moving platform", "platform path", "platform movement", "patrol platform"],
				"code": """extends AnimatableBody2D

@export var point_a: Vector2 = Vector2.ZERO
@export var point_b: Vector2 = Vector2(200, 0)
@export var travel_time: float = 2.0
@export var wait_time: float = 0.5
@export var loop_mode: bool = true

var _t: float = 0.0
var _waiting: float = 0.0
var _direction: int = 1
var _origin: Vector2 = Vector2.ZERO

func _ready() -> void:
	_origin = global_position
	point_a += _origin
	point_b += _origin

func _physics_process(delta: float) -> void:
	if _waiting > 0.0:
		_waiting -= delta
		return
	_t += (delta / travel_time) * float(_direction)
	if _t >= 1.0:
		_t = 1.0
		_direction = -1
		_waiting = wait_time
		if not loop_mode:
			_physics_process(0.0)
			return
	elif _t <= 0.0:
		_t = 0.0
		_direction = 1
		_waiting = wait_time
	global_position = point_a.lerp(point_b, _t)
""",
				"params": ["point_a", "point_b", "travel_time", "wait_time", "loop_mode"],
				"category": "platformer",
				"subcategory": "platforms",
				"dimension": "2d",
				"difficulty": "intermediate",
				"param_info": {
					"point_a": {
						"default": [0, 0],
						"range": [],
						"what": "First waypoint, relative to the platform's starting position.",
						"typical": "[0, 0] to start at origin",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"point_b": {
						"default": [200, 0],
						"range": [],
						"what": "Second waypoint, relative to the platform's starting position.",
						"typical": "[200, 0] horizontal / [0, -100] vertical / [100, -100] diagonal",
						"increase": "Longer path.",
						"decrease": "Shorter."
					},
					"travel_time": {
						"default": 2.0,
						"range": [0.5, 20.0],
						"what": "Seconds to travel from A to B.",
						"typical": "1.0 fast / 2.0 standard / 5.0 slow",
						"increase": "Slower platform.",
						"decrease": "Faster."
					}
				},
				"details": {
					"what": "Platform that moves between two points and carries the player. AnimatableBody2D is used instead of StaticBody2D so the player rides it.",
					"where": "Attach to an AnimatableBody2D with a CollisionShape2D child. Set point_a and point_b in the Inspector.",
					"before": "None.",
					"after": "For a multi-waypoint path, replace the lerp with a tween over an Array of positions.",
					"why_optimized": "AnimatableBody2D uses kinematic motion — the physics engine handles carrying riders for free.",
					"mistakes": "Using StaticBody2D means the player doesn't ride the platform and falls through. Always use AnimatableBody2D.",
					"related": ["one_way_platform", "moving_platform_path", "platformer_movement_2d"]
				}
			},
			"moving_platform_path": {
				"phrases": ["platform path", "multi point platform", "platform waypoint", "elevator platform"],
				"code": """extends AnimatableBody2D

@export var waypoints: Array[Vector2] = [Vector2.ZERO, Vector2(200, 0), Vector2(200, -100)]
@export var speed: float = 80.0
@export var wait_time: float = 0.5
@export var loop_forward_only: bool = true

var _index: int = 0
var _waiting: float = 0.0
var _origin: Vector2 = Vector2.ZERO

func _ready() -> void:
	_origin = global_position
	for i in range(waypoints.size()):
		waypoints[i] += _origin

func _physics_process(delta: float) -> void:
	if _waiting > 0.0:
		_waiting -= delta
		return
	if waypoints.size() < 2:
		return
	var target: Vector2 = waypoints[_index]
	global_position = global_position.move_toward(target, speed * delta)
	if global_position.distance_to(target) < 1.0:
		_advance_index()
		_waiting = wait_time

func _advance_index() -> void:
	if loop_forward_only:
		_index = (_index + 1) % waypoints.size()
	else:
		if _index >= waypoints.size() - 1:
			_index = 0
		else:
			_index += 1
""",
				"params": ["waypoints", "speed", "wait_time", "loop_forward_only"],
				"category": "platformer",
				"subcategory": "platforms",
				"dimension": "2d",
				"difficulty": "intermediate",
				"param_info": {
					"waypoints": {
						"default": [[0, 0], [200, 0], [200, -100]],
						"range": [],
						"what": "Array of relative waypoints. The platform visits them in order.",
						"typical": "2-6 points for a path",
						"increase": "Longer path.",
						"decrease": "Simpler."
					},
					"speed": {
						"default": 80.0,
						"range": [20.0, 500.0],
						"what": "Pixels per second of platform movement.",
						"typical": "40 slow elevator / 80 standard / 200 fast",
						"increase": "Faster.",
						"decrease": "Slower."
					},
					"wait_time": {
						"default": 0.5,
						"range": [0.0, 5.0],
						"what": "Pause at each waypoint.",
						"typical": "0.0 continuous / 0.5 standard / 1.5 deliberate",
						"increase": "Longer pause.",
						"decrease": "Shorter."
					}
				},
				"details": {
					"what": "Platform that follows a multi-point path. Perfect for elevators, spirals, and patrol routes.",
					"where": "Attach to an AnimatableBody2D. Fill the waypoints array in the Inspector.",
					"before": "None.",
					"after": "Set loop_forward_only to false if the platform should go back the way it came.",
					"why_optimized": "move_toward is a single vector operation. Distance check is O(1).",
					"mistakes": "Waypoints are relative to the starting position — placing them in absolute world coordinates makes the platform teleport far away on _ready.",
					"related": ["moving_platform", "enemy_patrol", "platformer_movement_2d"]
				}
			},
			"ladder": {
				"phrases": ["ladder", "climb ladder", "climbing area", "ladder zone"],
				"code": """extends Area2D

signal player_entered
signal player_exited

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.has_method("set_in_ladder"):
			body.set_in_ladder(true)
		player_entered.emit()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.has_method("set_in_ladder"):
			body.set_in_ladder(false)
		player_exited.emit()

# Add these methods to your player script:
#
# var _in_ladder: bool = false
# @export var climb_speed: float = 100.0
#
# func set_in_ladder(value: bool) -> void:
#     _in_ladder = value
#
# In _physics_process, before applying gravity:
#     if _in_ladder:
#         var input_y := Input.get_axis("up", "down")
#         velocity.y = input_y * climb_speed
#         if absf(input_y) > 0.1:
#             velocity.x = 0.0
#     else:
#         velocity.y += gravity * delta
""",
				"params": [],
				"category": "platformer",
				"subcategory": "traversal",
				"dimension": "2d",
				"difficulty": "intermediate",
				"details": {
					"what": "Area2D ladder zone. Tells the player when they're inside it so they can climb instead of fall.",
					"where": "Attach to an Area2D positioned over the ladder sprite. Add the player to group 'player'.",
					"before": "Player script must have a set_in_ladder method and handle the ladder state in _physics_process.",
					"after": "Add a snap-to-ladder-center behavior — lerp player.x toward the ladder's x when entering.",
					"why_optimized": "Signal-driven. No polling of positions.",
					"mistakes": "Forgetting to zero out horizontal velocity while climbing makes the player walk sideways off the ladder.",
					"related": ["platformer_movement_2d", "climb_zone", "rope_climb"]
				}
			},
			"wall_slide_2d": {
				"phrases": ["wall slide", "wall slide 2d", "slide on wall", "wall cling"],
				"code": """extends CharacterBody2D

@export var wall_slide_speed: float = 40.0
@export var wall_slide_gravity: float = 100.0
@export var regular_gravity: float = 980.0
@export var wall_stick_time: float = 0.15
@export var wall_stick_force: float = 200.0

var _wall_stick_timer: float = 0.0

func _physics_process(delta: float) -> void:
	var on_wall := is_on_wall_only() and not is_on_floor()
	var pressing_toward_wall := false
	if on_wall:
		var wall_normal := get_wall_normal()
		var input_x := Input.get_axis("left", "right")
		pressing_toward_wall = (wall_normal.x > 0.0 and input_x > 0.0) or (wall_normal.x < 0.0 and input_x < 0.0)
	if on_wall and pressing_toward_wall:
		if velocity.y > 0.0:
			velocity.y = min(velocity.y, wall_slide_speed)
		else:
			velocity.y += wall_slide_gravity * delta
		_wall_stick_timer = wall_stick_time
	elif _wall_stick_timer > 0.0:
		_wall_stick_timer -= delta
		var wall_normal := get_wall_normal()
		velocity.x -= wall_normal.x * wall_stick_force * delta
		velocity.y += regular_gravity * delta
	else:
		velocity.y += regular_gravity * delta
	move_and_slide()
""",
				"params": ["wall_slide_speed", "wall_slide_gravity", "regular_gravity", "wall_stick_time", "wall_stick_force"],
				"category": "platformer",
				"subcategory": "traversal",
				"dimension": "2d",
				"difficulty": "intermediate",
				"required_actions": ["left", "right"],
				"param_info": {
					"wall_slide_speed": {
						"default": 40.0,
						"range": [10.0, 150.0],
						"what": "Maximum fall speed while sliding down a wall.",
						"typical": "20 slow slide / 40 standard / 80 fast",
						"increase": "Faster slide.",
						"decrease": "Slower."
					},
					"wall_stick_time": {
						"default": 0.15,
						"range": [0.0, 0.5],
						"what": "Brief window after leaving the wall where the player still gets pushed back.",
						"typical": "0.1 tight / 0.15 standard / 0.25 forgiving",
						"increase": "Easier to re-attach.",
						"decrease": "Harder."
					}
				},
				"details": {
					"what": "Slows falling while pressing into a wall and pressing away from it, with a brief stick window after release.",
					"where": "Attach to a CharacterBody2D. Combine with wall_jump_2d for a full wall-climb experience.",
					"before": "Input actions left and right. Player's collision shape can detect walls.",
					"after": "Add a wall-slide particle effect and change the sprite animation when on a wall.",
					"why_optimized": "Clamps velocity.y instead of applying friction. No per-frame allocations.",
					"mistakes": "Not checking pressing_toward_wall makes the player slide even when not holding into the wall, which feels wrong.",
					"related": ["wall_jump_2d", "platformer_movement_2d", "sprite_flip_direction"]
				}
			}
		}
	}

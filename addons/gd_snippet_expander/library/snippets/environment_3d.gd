@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"snippets": {
			"gravity_zone_3d": {
				"phrases": ["gravity zone 3d", "3d gravity zone", "low gravity 3d", "anti gravity 3d"],
				"code": """extends Area3D

@export var gravity_scale: float = 0.5
@export var extra_force: Vector3 = Vector3.ZERO

var _affected_bodies: Array = []

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _physics_process(delta: float) -> void:
	for body in _affected_bodies:
		if not is_instance_valid(body):
			continue
		if body is CharacterBody3D:
			var cb := body as CharacterBody3D
			var normal_gravity := cb.get_gravity() * gravity_scale
			cb.velocity.y += normal_gravity.y * delta
			cb.velocity += extra_force * delta
		elif body is RigidBody3D:
			var rb := body as RigidBody3D
			rb.gravity_scale = gravity_scale
			if extra_force.length() > 0.01:
				rb.apply_central_force(extra_force * rb.mass)

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D or body is RigidBody3D:
		_affected_bodies.append(body)

func _on_body_exited(body: Node3D) -> void:
	_affected_bodies.erase(body)
	if body is RigidBody3D:
		(body as RigidBody3D).gravity_scale = 1.0

func set_gravity_scale(value: float) -> void:
	gravity_scale = value

# SETUP
# 1. Area3D with CollisionShape3D (a BoxShape3D usually).
# 2. Collision layer/mask should detect the player and physics objects.
# 3. gravity_scale = 0.3 for low gravity, -0.5 for anti-gravity.
# 4. extra_force adds a constant push (e.g. updraft).
""",
				"params": ["gravity_scale", "extra_force"],
				"category": "environment",
				"subcategory": "3d",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "intermediate",
				"param_info": {
					"gravity_scale": {
						"default": 0.5,
						"range": [-2.0, 2.0],
						"what": "Multiplier on gravity inside the zone.",
						"typical": "0.3 moon / 0.5 half / 1.0 normal / -0.5 anti-gravity / -1.0 reverse",
						"increase": "Stronger gravity.",
						"decrease": "Weaker or reversed."
					},
					"extra_force": {
						"default": [0, 0, 0],
						"range": [],
						"what": "Constant force in addition to gravity.",
						"typical": "[0, 15, 0] updraft / [10, 0, 0] wind push",
						"increase": "Stronger push.",
						"decrease": "Weaker."
					}
				},
				"details": {
					"what": "Area3D that modifies gravity for characters and physics bodies inside it. Low-gravity rooms, underwater, or anti-gravity chambers.",
					"where": "Add as a child of the level. Box shape matching the region. Set collision layers to detect the player.",
					"before": "Player character must be CharacterBody3D with get_gravity() usage, or RigidBody3D.",
					"after": "Combine with visual effects — floating particles, ambient sound — so the player knows gravity changed.",
					"why_optimized": "Only affects bodies in the list. Physics forces applied per frame, not accumulated.",
					"mistakes": "Not restoring gravity_scale to 1.0 on exit means rigid bodies keep the modified value forever. The exit handler handles it.",
					"related": ["water_zone_3d", "wind_zone_3d", "character_movement_3d"]
				}
			},
			"water_zone_3d": {
				"phrases": ["water zone 3d", "3d water", "swim 3d", "underwater 3d"],
				"code": """extends Area3D

signal player_entered_water
signal player_exited_water

@export var water_level_y: float = 0.0
@export var buoyancy: float = 15.0
@export var drag: float = 3.0
@export var swim_force: float = 15.0
@export var sink_speed: float = 2.0

var _bodies: Array = []

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _physics_process(delta: float) -> void:
	for body in _bodies:
		if not is_instance_valid(body):
			continue
		if not (body is CharacterBody3D):
			continue
		var cb := body as CharacterBody3D
		var depth := global_position.y - body.global_position.y
		var submerged: float = clampf(depth / 2.0, 0.0, 1.0)
		if submerged < 0.1:
			continue
		# Buoyancy — push up proportional to submersion
		cb.velocity.y += buoyancy * submerged * delta
		# Drag — slow all movement
		cb.velocity = cb.velocity.lerp(Vector3.ZERO, drag * submerged * delta)
		# Swim controls
		if body.is_in_group("player"):
			_handle_swim_input(cb, delta, submerged)

func _handle_swim_input(cb: CharacterBody3D, delta: float, submerged: float) -> void:
	var input_dir := Input.get_vector("left", "right", "forward", "back")
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var forward := -camera.global_transform.basis.z
	var right := camera.global_transform.basis.x
	var direction := (right * input_dir.x + forward * input_dir.y).normalized()
	cb.velocity += direction * swim_force * submerged * delta
	if Input.is_action_pressed("jump"):
		cb.velocity.y += swim_force * submerged * delta
	elif Input.is_action_pressed("crouch"):
		cb.velocity.y -= swim_force * submerged * delta

func _on_body_entered(body: Node3D) -> void:
	if not (body is CharacterBody3D):
		return
	if _bodies.has(body):
		return
	_bodies.append(body)
	if body.is_in_group("player"):
		player_entered_water.emit()

func _on_body_exited(body: Node3D) -> void:
	_bodies.erase(body)
	if body.is_in_group("player"):
		player_exited_water.emit()

func is_underwater(body: Node3D) -> bool:
	if not _bodies.has(body):
		return false
	return body.global_position.y < water_level_y
""",
				"params": ["water_level_y", "buoyancy", "drag", "swim_force", "sink_speed"],
				"category": "environment",
				"subcategory": "3d",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "advanced",
				"required_actions": ["left", "right", "forward", "back", "jump", "crouch"],
				"param_info": {
					"buoyancy": {
						"default": 15.0,
						"range": [0.0, 40.0],
						"what": "Upward force applied when submerged.",
						"typical": "5 slow sink / 15 neutral float / 30+ rises fast",
						"increase": "More floaty.",
						"decrease": "Sinks faster."
					},
					"swim_force": {
						"default": 15.0,
						"range": [2.0, 50.0],
						"what": "How fast the player swims in input directions.",
						"typical": "8 slow / 15 standard / 30 fast",
						"increase": "Faster swim.",
						"decrease": "Slower."
					},
					"drag": {
						"default": 3.0,
						"range": [0.5, 10.0],
						"what": "How much water slows movement.",
						"typical": "1.5 light / 3.0 standard / 6.0+ heavy",
						"increase": "More resistance.",
						"decrease": "Less."
					}
				},
				"details": {
					"what": "Full 3D swimming zone with buoyancy, drag, and directional swim controls tied to the camera.",
					"where": "Box Area3D covering the water volume. Player must be in group 'player'.",
					"before": "Input actions left, right, forward, back, jump, crouch. A WaterSurface mesh for visuals.",
					"after": "Add underwater post-processing (blue tint, fog) via a WorldEnvironment when submerged. Handle breath/oxygen separately.",
					"why_optimized": "Submersion fraction only computes when in the zone. Camera-relative swim direction is a few vector ops.",
					"mistakes": "Not accounting for submersion depth means the player feels the same at the surface and deep underwater.",
					"related": ["gravity_zone_3d", "wind_zone_3d", "first_person_movement"]
				}
			},
			"ladder_3d": {
				"phrases": ["ladder 3d", "3d ladder", "climb 3d", "climbable 3d"],
				"code": """extends Area3D

signal player_entered
signal player_exited

@export var climb_speed: float = 3.0
@export var snap_to_ladder: bool = true
@export var snap_speed: float = 5.0

var _players_in_zone: Array = []

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _physics_process(delta: float) -> void:
	for body in _players_in_zone:
		if not is_instance_valid(body):
			continue
		if not (body is CharacterBody3D):
			continue
		var cb := body as CharacterBody3D
		if cb.has_method("set_on_ladder"):
			var climbing: bool = cb.call("is_climbing") if cb.has_method("is_climbing") else false
			if not climbing:
				continue
			var input_y := Input.get_axis("back", "forward")
			if Input.is_action_pressed("jump"):
				cb.velocity.y = climb_speed
			elif Input.is_action_pressed("crouch"):
				cb.velocity.y = -climb_speed
			else:
				cb.velocity.y = -input_y * climb_speed
			if snap_to_ladder:
				var ladder_center := global_position
				cb.global_position.x = lerpf(cb.global_position.x, ladder_center.x, snap_speed * delta)
				cb.global_position.z = lerpf(cb.global_position.z, ladder_center.z, snap_speed * delta)

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	if _players_in_zone.has(body):
		return
	_players_in_zone.append(body)
	if body.has_method("set_on_ladder"):
		body.call("set_on_ladder", true)
	player_entered.emit()

func _on_body_exited(body: Node3D) -> void:
	_players_in_zone.erase(body)
	if body.has_method("set_on_ladder"):
		body.call("set_on_ladder", false)
	player_exited.emit()

# PLAYER SCRIPT ADDITIONS
# var _on_ladder: bool = false
# func set_on_ladder(value): _on_ladder = value
# func is_climbing(): return _on_ladder and Input.get_vector(...).length() > 0.1
#
# In _physics_process, before applying gravity:
#   if _on_ladder:
#       move_and_slide()
#       return
""",
				"params": ["climb_speed", "snap_to_ladder", "snap_speed"],
				"category": "environment",
				"subcategory": "3d",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "intermediate",
				"required_actions": ["forward", "back", "jump", "crouch"],
				"param_info": {
					"climb_speed": {
						"default": 3.0,
						"range": [0.5, 10.0],
						"what": "Meters per second climbing speed.",
						"typical": "1.5 slow / 3.0 standard / 6.0 fast",
						"increase": "Faster climb.",
						"decrease": "Slower."
					},
					"snap_to_ladder": {
						"default": true,
						"range": [],
						"what": "Whether to keep the player centered on the ladder.",
						"typical": "true for simple ladders / false for free-form climbing",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "3D ladder zone. Player can climb up or down and is optionally snapped to the ladder's center.",
					"where": "Box Area3D covering the ladder visual. Player must be in group 'player' with set_on_ladder method.",
					"before": "Input actions forward, back, jump, crouch. Player script modified to skip gravity while on ladder.",
					"after": "Add a climb animation (usually just the idle pose). Disable jump while on the ladder.",
					"why_optimized": "Only processes players in the zone. Snap uses lerp for smooth centering.",
					"mistakes": "Not skipping gravity in the player script means the ladder's velocity gets overwritten each frame.",
					"related": ["ladder", "gravity_zone_3d", "character_movement_3d"]
				}
			},
			"wind_zone_3d": {
				"phrases": ["wind zone 3d", "3d wind", "wind tunnel 3d", "updraft 3d"],
				"code": """extends Area3D

@export var wind_direction: Vector3 = Vector3(1, 0, 0)
@export var wind_strength: float = 8.0
@export var turbulence: float = 0.3
@export var affects_gravity: bool = false

var _bodies: Array = []

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _physics_process(delta: float) -> void:
	var base_force := wind_direction.normalized() * wind_strength
	for body in _bodies:
		if not is_instance_valid(body):
			continue
		var force := base_force
		if turbulence > 0.0:
			force += Vector3(
				randf_range(-turbulence, turbulence),
				randf_range(-turbulence, turbulence),
				randf_range(-turbulence, turbulence)
			) * wind_strength
		if body is CharacterBody3D:
			var cb := body as CharacterBody3D
			cb.velocity += force * delta
			if affects_gravity:
				cb.velocity.y -= cb.get_gravity().y * 0.5 * delta
		elif body is RigidBody3D:
			(body as RigidBody3D).apply_central_force(force * (body as RigidBody3D).mass)

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D or body is RigidBody3D:
		_bodies.append(body)

func _on_body_exited(body: Node3D) -> void:
	_bodies.erase(body)

func set_wind(direction: Vector3, strength: float) -> void:
	wind_direction = direction
	wind_strength = strength
""",
				"params": ["wind_direction", "wind_strength", "turbulence", "affects_gravity"],
				"category": "environment",
				"subcategory": "3d",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "intermediate",
				"param_info": {
					"wind_direction": {
						"default": [1, 0, 0],
						"range": [],
						"what": "Direction the wind pushes.",
						"typical": "[0, 1, 0] updraft / [1, 0, 0] horizontal / [-1, 0, 0] opposite",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"wind_strength": {
						"default": 8.0,
						"range": [1.0, 30.0],
						"what": "Force applied per second.",
						"typical": "3 gentle breeze / 8 standard / 20+ storm",
						"increase": "Stronger push.",
						"decrease": "Weaker."
					},
					"turbulence": {
						"default": 0.3,
						"range": [0.0, 2.0],
						"what": "Random variation added to the wind direction per frame.",
						"typical": "0.0 smooth / 0.3 standard / 1.0+ chaotic",
						"increase": "More chaotic.",
						"decrease": "Smoother."
					}
				},
				"details": {
					"what": "Area3D that pushes characters and physics objects. Wind tunnels, updraft columns, fans.",
					"where": "Box Area3D covering the wind region. Configure wind direction and strength.",
					"before": "None. Works with CharacterBody3D and RigidBody3D.",
					"after": "Add particle streaks or leaf sprites moving with the wind direction for visual feedback.",
					"why_optimized": "Only iterates bodies in the zone. Random turbulence uses three randf_range calls.",
					"mistakes": "Very high turbulence values (over 1.0) make the wind direction feel random and confusing.",
					"related": ["gravity_zone_3d", "water_zone_3d", "particle_trail"]
				}
			},
			"moving_platform_3d": {
				"phrases": ["moving platform 3d", "3d platform", "elevator 3d", "moving 3d platform"],
				"code": """extends AnimatableBody3D

@export var point_a: Vector3 = Vector3.ZERO
@export var point_b: Vector3 = Vector3(5, 0, 0)
@export var travel_time: float = 2.0
@export var wait_time: float = 0.5
@export var loop_mode: String = "pingpong"

var _t: float = 0.0
var _direction: int = 1
var _waiting: float = 0.0
var _origin: Vector3 = Vector3.ZERO

func _ready() -> void:
	_origin = global_position
	point_a += _origin
	point_b += _origin
	global_position = point_a

func _physics_process(delta: float) -> void:
	if _waiting > 0.0:
		_waiting -= delta
		return
	_t += (delta / travel_time) * float(_direction)
	match loop_mode:
		"pingpong":
			if _t >= 1.0:
				_t = 1.0
				_direction = -1
				_waiting = wait_time
			elif _t <= 0.0:
				_t = 0.0
				_direction = 1
				_waiting = wait_time
		"cycle":
			if _t >= 1.0:
				_t = 0.0
	global_position = point_a.lerp(point_b, _t)

func set_points(a: Vector3, b: Vector3) -> void:
	point_a = a
	point_b = b

# SETUP
# 1. AnimatableBody3D with a CollisionShape3D child.
# 2. Add a MeshInstance3D child for the visual.
# 3. Position the platform where you want point_a.
# 4. Set point_b (relative to point_a) in the Inspector.
# 5. AnimatableBody3D carries CharacterBody3D riders.
""",
				"params": ["point_a", "point_b", "travel_time", "wait_time", "loop_mode"],
				"category": "environment",
				"subcategory": "3d",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "beginner",
				"param_info": {
					"travel_time": {
						"default": 2.0,
						"range": [0.5, 20.0],
						"what": "Seconds to travel from A to B.",
						"typical": "1.0 fast / 2.0 standard / 5.0 slow",
						"increase": "Slower.",
						"decrease": "Faster."
					},
					"loop_mode": {
						"default": "pingpong",
						"range": [],
						"what": "Whether the platform bounces back or cycles.",
						"typical": "pingpong back-forth / cycle teleport to start",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "3D moving platform between two points. AnimatableBody3D carries the player.",
					"where": "AnimatableBody3D with collision and mesh children. Set point_a and point_b in Inspector.",
					"before": "None.",
					"after": "For multi-waypoint paths, extend the code to lerp between an array of points.",
					"why_optimized": "AnimatableBody3D uses kinematic motion. The engine carries riders with no manual velocity calculation.",
					"mistakes": "Using StaticBody3D means riders fall off. Always AnimatableBody3D for moving platforms.",
					"related": ["moving_platform_path", "moving_platform", "gridmap_setup"]
				}
			}
		}
	}

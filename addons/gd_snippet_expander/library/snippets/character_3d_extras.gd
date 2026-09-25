@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"snippets": {
			"stairs_slopes_3d": {
				"phrases": ["stairs 3d", "slopes 3d", "walk stairs", "climb stairs"],
				"code": """extends CharacterBody3D

@export var speed: float = 5.0
@export var max_slope_angle: float = 45.0
@export var floor_snap_length: float = 0.3
@export var stair_step_height: float = 0.3

func _ready() -> void:
	# floor_max_angle controls which surfaces count as walkable.
	# 45 degrees is standard — steeper counts as wall.
	floor_max_angle = deg_to_rad(max_slope_angle)
	# Snap to floor keeps the character grounded on slopes and stairs
	floor_snap_length = 0.3

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	var input_dir := Input.get_vector("left", "right", "forward", "back")
	var dir := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	move_and_slide()

func is_on_slope() -> bool:
	if not is_on_floor():
		return false
	var normal := get_floor_normal()
	var angle := acos(normal.dot(Vector3.UP))
	return angle > 0.05 and angle < floor_max_angle
""",
				"params": ["speed", "max_slope_angle", "floor_snap_length", "stair_step_height"],
				"category": "movement",
				"subcategory": "3d",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "beginner",
				"required_actions": ["left", "right", "forward", "back"],
				"param_info": {
					"max_slope_angle": {
						"default": 45.0,
						"range": [10.0, 89.0],
						"what": "Steepest angle the character can walk up.",
						"typical": "30 tight / 45 standard / 60 loose",
						"increase": "Steeper slopes walkable.",
						"decrease": "Sharper cutoff."
					},
					"floor_snap_length": {
						"default": 0.3,
						"range": [0.05, 1.0],
						"what": "How far down to snap to find a floor when airborne.",
						"typical": "0.1 tight / 0.3 standard / 0.5 loose",
						"increase": "Stays grounded over bigger bumps.",
						"decrease": "Falls off smaller ledges."
					}
				},
				"details": {
					"what": "Configures CharacterBody3D for walking up slopes and stairs. Uses built-in floor_max_angle and floor_snap_length.",
					"where": "Attach to a CharacterBody3D. This snippet is mostly a _ready configuration.",
					"before": "Input actions left, right, forward, back.",
					"after": "For very tall stairs (steps > 0.5m), add an invisible ramp or use separate StaticBody3D steps.",
					"why_optimized": "Uses built-in CharacterBody3D properties. No custom raycasting needed.",
					"mistakes": "Not setting floor_max_angle means the default 45 degrees may reject your slopes.",
					"related": ["character_movement_3d", "first_person_movement", "character_3d_crouch"]
				}
			},
			"character_3d_crouch": {
				"phrases": ["crouch 3d", "crouch 3d character", "duck 3d", "sneak 3d"],
				"code": """extends CharacterBody3D

@export var normal_speed: float = 5.0
@export var crouch_speed: float = 2.5
@export var normal_height: float = 1.8
@export var crouch_height: float = 1.0

@onready var _collision: CollisionShape3D = $CollisionShape3D

var _crouching: bool = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("crouch"):
		_try_crouch()
	elif event.is_action_released("crouch"):
		_try_stand()

func _try_crouch() -> void:
	if _crouching:
		return
	_crouching = true
	_update_height(crouch_height)

func _try_stand() -> void:
	if not _crouching:
		return
	if not _has_headroom():
		return
	_crouching = false
	_update_height(normal_height)

func _has_headroom() -> bool:
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(
		global_position + Vector3(0, crouch_height, 0),
		global_position + Vector3(0, normal_height, 0)
	)
	query.exclude = [get_rid()]
	var hit := space.intersect_ray(query)
	return hit.is_empty()

func _update_height(height: float) -> void:
	if _collision.shape is CapsuleShape3D:
		var capsule := _collision.shape as CapsuleShape3D
		capsule.height = height
		_collision.position.y = height * 0.5

func get_current_speed() -> float:
	return crouch_speed if _crouching else normal_speed

func is_crouching() -> bool:
	return _crouching
""",
				"params": ["normal_speed", "crouch_speed", "normal_height", "crouch_height"],
				"category": "movement",
				"subcategory": "3d",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "intermediate",
				"required_actions": ["crouch"],
				"param_info": {
					"crouch_height": {
						"default": 1.0,
						"range": [0.5, 1.5],
						"what": "Height of the collision capsule while crouching.",
						"typical": "0.6 crawl / 1.0 standard crouch",
						"increase": "Taller crouch.",
						"decrease": "Lower."
					},
					"crouch_speed": {
						"default": 2.5,
						"range": [0.5, 5.0],
						"what": "Movement speed while crouching.",
						"typical": "1.5 stealth / 2.5 standard / 4.0 fast crouch",
						"increase": "Faster crouch movement.",
						"decrease": "Slower."
					}
				},
				"details": {
					"what": "3D crouch that changes the collision capsule height and prevents standing when there's a ceiling.",
					"where": "Attach to a CharacterBody3D with a CollisionShape3D using CapsuleShape3D.",
					"before": "Input action 'crouch'. CapsuleShape3D on the collision shape (not BoxShape3D).",
					"after": "Update the camera position when crouching for a first-person game.",
					"why_optimized": "Headroom check is a single raycast. No physics queries per frame.",
					"mistakes": "Not checking headroom means the player can stand inside a wall. The raycast prevents this.",
					"related": ["first_person_movement", "character_movement_3d", "crouch_2d"]
				}
			},
			"character_3d_slide": {
				"phrases": ["slide 3d", "dash slide 3d", "crouch slide", "slide ability 3d"],
				"code": """extends CharacterBody3D

@export var slide_speed: float = 10.0
@export var slide_duration: float = 0.6
@export var slide_cooldown: float = 0.3
@export var slide_friction: float = 3.0

var _sliding: bool = false
var _can_slide: bool = true
var _slide_direction: Vector3 = Vector3.ZERO
var _slide_timer: float = 0.0

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("crouch") and _can_slide and is_on_floor() and not _sliding:
		_start_slide()

func _start_slide() -> void:
	_sliding = true
	_can_slide = false
	_slide_timer = slide_duration
	var input_dir := Input.get_vector("left", "right", "forward", "back")
	var local := Vector3(input_dir.x, 0, input_dir.y)
	_slide_direction = (transform.basis * local).normalized()
	if _slide_direction.length() < 0.1:
		_slide_direction = -transform.basis.z

func _physics_process(delta: float) -> void:
	if _sliding:
		_slide_timer -= delta
		velocity = _slide_direction * slide_speed
		_slide_speed_decay(delta)
		if _slide_timer <= 0.0 or not is_on_floor():
			_end_slide()
	else:
		if not is_on_floor():
			velocity += get_gravity() * delta
	move_and_slide()

func _slide_speed_decay(delta: float) -> void:
	slide_speed = maxf(slide_speed - slide_friction * delta * 10.0, 2.0)

func _end_slide() -> void:
	_sliding = false
	await get_tree().create_timer(slide_cooldown).timeout
	_can_slide = true

func is_sliding() -> bool:
	return _sliding
""",
				"params": ["slide_speed", "slide_duration", "slide_cooldown", "slide_friction"],
				"category": "movement",
				"subcategory": "3d",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "intermediate",
				"required_actions": ["crouch", "left", "right", "forward", "back"],
				"param_info": {
					"slide_speed": {
						"default": 10.0,
						"range": [4.0, 25.0],
						"what": "Starting speed of the slide.",
						"typical": "6 slow / 10 standard / 18+ fast",
						"increase": "Faster slide.",
						"decrease": "Slower."
					},
					"slide_duration": {
						"default": 0.6,
						"range": [0.2, 2.0],
						"what": "How long the slide lasts.",
						"typical": "0.4 short / 0.6 standard / 1.0 long",
						"increase": "Longer slide.",
						"decrease": "Shorter."
					},
					"slide_friction": {
						"default": 3.0,
						"range": [0.5, 10.0],
						"what": "How fast the slide decelerates.",
						"typical": "1.0 slow decay / 3.0 standard / 8.0+ rapid stop",
						"increase": "Faster deceleration.",
						"decrease": "Slower."
					}
				},
				"details": {
					"what": "Crouch-triggered slide. Locks movement direction at slide start and decays over time.",
					"where": "Attach to a CharacterBody3D. Combine with crouch to make the crouch key both slide and crouch.",
					"before": "Input actions crouch, left, right, forward, back.",
					"after": "Lower the camera height during slide for the classic FPS feel.",
					"why_optimized": "Direction is cached at slide start. Only friction math per frame.",
					"mistakes": "Not decelerating means the slide never ends naturally. The friction handles that.",
					"related": ["topdown_dash_8dir", "camera_shake", "screen_flash"]
				}
			},
			"character_3d_wall_run": {
				"phrases": ["wall run 3d", "wallrun", "titanfall wall run", "wall running"],
				"code": """extends CharacterBody3D

@export var speed: float = 8.0
@export var wall_run_speed: float = 10.0
@export var wall_run_duration: float = 1.5
@export var wall_stick_force: float = 15.0
@export var wall_jump_force: float = 6.0
@export var wall_jump_up: float = 5.0

var _wall_running: bool = false
var _wall_run_timer: float = 0.0
var _wall_normal: Vector3 = Vector3.ZERO

func _physics_process(delta: float) -> void:
	if _wall_running:
		_update_wall_run(delta)
	elif not is_on_floor():
		velocity += get_gravity() * delta
	_check_wall_run_start()
	_handle_movement(delta)
	move_and_slide()

func _check_wall_run_start() -> void:
	if _wall_running or is_on_floor():
		return
	if not is_on_wall():
		return
	var input_dir := Input.get_vector("left", "right", "forward", "back")
	if input_dir.length() < 0.1:
		return
	_wall_running = true
	_wall_run_timer = wall_run_duration
	_wall_normal = get_wall_normal()

func _update_wall_run(delta: float) -> void:
	_wall_run_timer -= delta
	if _wall_run_timer <= 0.0 or is_on_floor() or not is_on_wall():
		_end_wall_run()
		return
	# Stick to the wall
	velocity -= _wall_normal * wall_stick_force * delta
	# Cancel gravity
	velocity.y = maxf(velocity.y, -2.0)
	# Move forward along the wall
	var forward := transform.basis.z * -1.0
	var along := forward.slide(_wall_normal)
	velocity.x = along.x * wall_run_speed
	velocity.z = along.z * wall_run_speed

func _handle_movement(delta: float) -> void:
	if _wall_running:
		return
	if is_on_floor():
		var input_dir := Input.get_vector("left", "right", "forward", "back")
		var dir := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
	if Input.is_action_just_pressed("jump") and _wall_running:
		_wall_jump()

func _wall_jump() -> void:
	velocity = _wall_normal * wall_jump_force
	velocity.y = wall_jump_up
	_end_wall_run()

func _end_wall_run() -> void:
	_wall_running = false

func is_wall_running() -> bool:
	return _wall_running
""",
				"params": ["wall_run_speed", "wall_run_duration", "wall_stick_force", "wall_jump_force"],
				"category": "movement",
				"subcategory": "3d",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "advanced",
				"required_actions": ["jump", "left", "right", "forward", "back"],
				"param_info": {
					"wall_run_speed": {
						"default": 10.0,
						"range": [5.0, 20.0],
						"what": "Horizontal speed along the wall.",
						"typical": "8 slow / 10 standard / 15 fast",
						"increase": "Faster wall run.",
						"decrease": "Slower."
					},
					"wall_run_duration": {
						"default": 1.5,
						"range": [0.5, 5.0],
						"what": "Maximum time on the wall before falling off.",
						"typical": "1.0 short / 1.5 standard / 3.0+ generous",
						"increase": "Longer wall run.",
						"decrease": "Shorter."
					}
				},
				"details": {
					"what": "Titanfall-style wall running. Character sticks to walls and runs along them while airborne.",
					"where": "Attach to a CharacterBody3D. Walls need proper collision layers.",
					"before": "Input actions jump, left, right, forward, back.",
					"after": "Tilt the camera on wall run for the classic effect. See camera_shake for tilt-like feedback.",
					"why_optimized": "Vector slide projection keeps the character moving along the wall regardless of angle.",
					"mistakes": "Very narrow walls or short wall segments make wall running feel glitchy. Design walls at least 3m long.",
					"related": ["first_person_movement", "camera_shake", "dash_2d"]
				}
			},
			"character_3d_slope_slide": {
				"phrases": ["slope slide 3d", "steep slope 3d", "mountain slide", "slippery slope 3d"],
				"code": """extends CharacterBody3D

@export var slide_speed_threshold: float = 30.0
@export var slope_acceleration: float = 9.8
@export var slope_friction: float = 0.8

var _on_steep_slope: bool = false

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
		_on_steep_slope = false
		move_and_slide()
		return
	var floor_angle := _get_floor_angle()
	if floor_angle >= slide_speed_threshold:
		_on_steep_slope = true
		_apply_slope_slide(delta, floor_angle)
	else:
		_on_steep_slope = false
	move_and_slide()

func _get_floor_angle() -> float:
	var normal := get_floor_normal()
	var angle := acos(clampf(normal.dot(Vector3.UP), -1.0, 1.0))
	return rad_to_deg(angle)

func _apply_slope_slide(delta: float, floor_angle: float) -> void:
	var normal := get_floor_normal()
	# Project gravity onto the slope plane to get downhill direction
	var gravity_dir := Vector3.DOWN
	var downhill := gravity_dir.slide(normal).normalized()
	# Steeper angle means faster acceleration
	var angle_factor: float = floor_angle / 90.0
	velocity += downhill * slope_acceleration * angle_factor * delta
	# Apply slope friction
	velocity *= (1.0 - slope_friction * delta)

func is_on_steep_slope() -> bool:
	return _on_steep_slope
""",
				"params": ["slide_speed_threshold", "slope_acceleration", "slope_friction"],
				"category": "movement",
				"subcategory": "3d",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "intermediate",
				"param_info": {
					"slide_speed_threshold": {
						"default": 30.0,
						"range": [15.0, 60.0],
						"what": "Angle above which the player slides down slopes.",
						"typical": "25 permissive / 30 standard / 45 strict",
						"increase": "Only steeper slopes slide.",
						"decrease": "More slopes slide."
					},
					"slope_acceleration": {
						"default": 9.8,
						"range": [2.0, 30.0],
						"what": "How fast the player accelerates downhill.",
						"typical": "5 gentle / 9.8 gravity / 20 fast",
						"increase": "Faster acceleration.",
						"decrease": "Slower."
					},
					"slope_friction": {
						"default": 0.8,
						"range": [0.0, 5.0],
						"what": "Resistance while sliding.",
						"typical": "0.3 icy / 0.8 standard / 2.0+ sticky",
						"increase": "More resistance.",
						"decrease": "Less."
					}
				},
				"details": {
					"what": "Player slides down steep slopes automatically. Classic for snowboarding or ice levels.",
					"where": "Attach to a CharacterBody3D. Combine with normal movement for the flat-ground case.",
					"before": "Floor collision on the level. Slopes at varying angles.",
					"after": "Add a slide animation and a motion blur or particle effect for speed feedback.",
					"why_optimized": "Projection math uses Vector3.slide which handles any slope orientation. No per-frame raycasts.",
					"mistakes": "Setting slide_speed_threshold too low makes the player slide on gentle hills they should walk up.",
					"related": ["ice_surface_2d", "character_movement_3d", "camera_shake"]
				}
			}
		}
	}

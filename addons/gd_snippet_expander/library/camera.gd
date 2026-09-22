@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"snippets": {
			"camera_follow_2d": {
				"phrases": ["camera follow 2d", "follow player 2d", "camera follow player"],
				"code": """extends Camera2D

@export var target_path: NodePath
@export var smooth_speed: float = 5.0

@onready var _target: Node2D = get_node(target_path) as Node2D

func _process(delta: float) -> void:
	global_position = global_position.lerp(_target.global_position, smooth_speed * delta)
""",
				"params": ["target_path", "smooth_speed"],
				"category": "camera",
				"dimension": "2d",
				"difficulty": "beginner",
				"param_info": {
					"smooth_speed": {
						"default": 5.0,
						"range": [0.5, 20.0],
						"what": "How fast the camera catches up to the target.",
						"typical": "2 slow cinematic / 5 standard / 10 tight / 20 snappy",
						"increase": "Camera snaps faster, can feel jerky.",
						"decrease": "Camera lags behind, feels floaty."
					}
				},
				"details": {
					"what": "A Camera2D that follows another node smoothly.",
					"where": "Attach to a Camera2D. Set target_path in the Inspector to point at the player.",
					"before": "The player must exist as a Node2D somewhere in the scene.",
					"after": "Add camera_limits_2d if you want the camera to stop at level edges.",
					"why_optimized": "lerp with a scaled weight gives frame-rate independent smoothing.",
					"mistakes": "Forgetting to set target_path leaves the camera at the origin.",
					"related": ["camera_smooth_follow_2d", "camera_limits_2d", "camera_deadzone"]
				}
			},
			"camera_follow_3d": {
				"phrases": ["camera follow 3d", "follow player 3d", "third person camera"],
				"code": """extends Camera3D

@export var target_path: NodePath
@export var offset: Vector3 = Vector3(0, 3, 6)
@export var smooth_speed: float = 5.0

@onready var _target: Node3D = get_node(target_path) as Node3D

func _process(delta: float) -> void:
	var desired := _target.global_position + offset
	global_position = global_position.lerp(desired, smooth_speed * delta)
	look_at(_target.global_position, Vector3.UP)
""",
				"params": ["target_path", "offset", "smooth_speed"],
				"category": "camera",
				"dimension": "3d",
				"difficulty": "beginner",
				"param_info": {
					"offset": {
						"default": [0, 3, 6],
						"range": [[-10, 1, 1], [10, 15, 30]],
						"what": "Where the camera sits relative to the target. X is side, Y is up, Z is back.",
						"typical": "[0, 3, 6] third person / [0, 1.6, 0] first person / [0, 6, 10] wide shot",
						"increase": "Larger Z pulls the camera further back.",
						"decrease": "Smaller Z brings it closer, tighter framing."
					},
					"smooth_speed": {
						"default": 5.0,
						"range": [0.5, 20.0],
						"what": "How fast the camera catches up.",
						"typical": "2 cinematic / 5 standard / 10 tight",
						"increase": "Faster catch-up, less lag.",
						"decrease": "More lag, more cinematic."
					}
				},
				"details": {
					"what": "A Camera3D that follows a target at a fixed offset.",
					"where": "Attach to a Camera3D at the scene root, not as a child of the player.",
					"before": "The player must be a Node3D in the scene.",
					"after": "Add orbit_camera_3d instead if you want the player to control the angle.",
					"why_optimized": "look_at uses Godot's built-in math, no manual rotation needed.",
					"mistakes": "Making the camera a child of the player causes the camera to rotate with the player. Keep it separate.",
					"related": ["orbit_camera_3d", "first_person_camera_3d", "camera_shake"]
				}
			},
			"camera_shake": {
				"phrases": ["camera shake", "screen shake", "shake camera"],
				"code": """@export var shake_decay: float = 8.0

var _shake_amount: float = 0.0
var _origin: Vector2 = Vector2.ZERO

func _ready() -> void:
	_origin = position

func shake(amount: float) -> void:
	_shake_amount = max(_shake_amount, amount)

func _process(delta: float) -> void:
	if _shake_amount > 0.0:
		position = _origin + Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake_amount
		_shake_amount = max(_shake_amount - shake_decay * delta, 0.0)
	else:
		position = _origin
""",
				"params": ["shake_decay"],
				"category": "camera",
				"dimension": "2d",
				"difficulty": "beginner",
				"param_info": {
					"shake_decay": {
						"default": 8.0,
						"range": [1.0, 30.0],
						"what": "How quickly the shake fades out.",
						"typical": "4 long rumble / 8 standard / 20 short punch",
						"increase": "Shake stops quickly — good for bullets and small hits.",
						"decrease": "Shake lingers — good for explosions and heavy hits."
					}
				},
				"details": {
					"what": "Shakes the camera for a short burst. Call shake(amount) whenever something impactful happens.",
					"where": "Attach to a Camera2D. Call shake() from your game code.",
					"before": "None.",
					"after": "Call shake(8.0) on hit, shake(20.0) on explosion.",
					"why_optimized": "Uses randf_range each frame instead of pre-generating noise — cheap and looks fine.",
					"mistakes": "Forgetting to store _origin means the camera drifts away from where it started.",
					"related": ["camera_follow_2d", "camera_follow_3d", "hitbox"]
				}
			},
			"camera_zoom": {
				"phrases": ["camera zoom", "zoom in out", "mouse wheel zoom"],
				"code": """extends Camera2D

@export var zoom_step: float = 0.1
@export var min_zoom: float = 0.5
@export var max_zoom: float = 3.0

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom = (zoom + Vector2.ONE * zoom_step).clamp(Vector2.ONE * min_zoom, Vector2.ONE * max_zoom)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom = (zoom - Vector2.ONE * zoom_step).clamp(Vector2.ONE * min_zoom, Vector2.ONE * max_zoom)
""",
				"params": ["zoom_step", "min_zoom", "max_zoom"],
				"category": "camera",
				"dimension": "2d",
				"difficulty": "beginner",
				"param_info": {
					"zoom_step": {
						"default": 0.1,
						"range": [0.02, 0.5],
						"what": "How much zoom changes per scroll notch.",
						"typical": "0.05 fine / 0.1 standard / 0.25 chunky",
						"increase": "Zoom jumps fast.",
						"decrease": "Smoother, slower zoom."
					},
					"min_zoom": {
						"default": 0.5,
						"range": [0.1, 1.0],
						"what": "Furthest the camera can zoom out. Lower = see more.",
						"typical": "0.3 strategy / 0.5 standard / 1.0 no zoom out",
						"increase": "Less zoom-out range.",
						"decrease": "Can see further out."
					},
					"max_zoom": {
						"default": 3.0,
						"range": [1.0, 10.0],
						"what": "Closest the camera can zoom in. Higher = see less.",
						"typical": "2 character focus / 3 standard / 5+ detail",
						"increase": "Can zoom in more.",
						"decrease": "Less zoom-in range."
					}
				},
				"details": {
					"what": "Mouse wheel zooms the Camera2D in and out.",
					"where": "Attach to a Camera2D. Works with the standard mouse wheel.",
					"before": "None.",
					"after": "For touch screens, use pinch instead — mouse wheel events don't fire on Android.",
					"why_optimized": "clamp prevents zoom from going past the min/max, no separate checks needed.",
					"mistakes": "Forgetting clamp lets the player zoom to infinity.",
					"related": ["camera_follow_2d", "camera_deadzone", "camera_limits_2d"]
				}
			},
			"camera_smooth_follow_2d": {
				"phrases": ["smooth camera 2d", "smooth follow camera"],
				"code": """extends Camera2D

@export var target_path: NodePath
@export var speed: float = 4.0

@onready var _target: Node2D = get_node(target_path) as Node2D

func _process(delta: float) -> void:
	var weight := 1.0 - exp(-speed * delta)
	global_position = global_position.lerp(_target.global_position, weight)
""",
				"params": ["target_path", "speed"],
				"category": "camera",
				"dimension": "2d",
				"difficulty": "intermediate",
				"param_info": {
					"speed": {
						"default": 4.0,
						"range": [0.5, 20.0],
						"what": "How quickly the camera catches up.",
						"typical": "2 slow / 4 standard / 8 fast",
						"increase": "Camera moves faster, less lag.",
						"decrease": "More lag, more cinematic."
					}
				},
				"details": {
					"what": "Like camera_follow_2d but with a smoother curve. Better for slow-paced games.",
					"where": "Attach to a Camera2D. Set target_path to the player.",
					"before": "Player must exist as a Node2D.",
					"after": "Add camera_deadzone if the camera is too twitchy.",
					"why_optimized": "The 1.0 - exp(-speed * delta) formula is the mathematically correct way to do smooth follow that's frame-rate independent.",
					"mistakes": "Using the wrong formula (just speed * delta) makes the camera move at different speeds on different frame rates.",
					"related": ["camera_follow_2d", "camera_deadzone", "camera_limits_2d"]
				}
			},
			"camera_limits_2d": {
				"phrases": ["camera limits", "camera limits 2d", "clamp camera"],
				"code": """extends Camera2D

@export var top_left: Vector2 = Vector2(0, 0)
@export var bottom_right: Vector2 = Vector2(2000, 2000)

func _ready() -> void:
	limit_left = int(top_left.x)
	limit_top = int(top_left.y)
	limit_right = int(bottom_right.x)
	limit_bottom = int(bottom_right.y)
""",
				"params": ["top_left", "bottom_right"],
				"category": "camera",
				"dimension": "2d",
				"difficulty": "beginner",
				"param_info": {
					"top_left": {
						"default": [0, 0],
						"range": [[-10000, -10000], [10000, 10000]],
						"what": "The top-left corner of the level, in world coordinates.",
						"typical": "whatever your TileMap's top-left is",
						"increase": "Move the boundary right and down.",
						"decrease": "Move the boundary left and up."
					},
					"bottom_right": {
						"default": [2000, 2000],
						"range": [[-10000, -10000], [10000, 10000]],
						"what": "The bottom-right corner of the level.",
						"typical": "whatever your TileMap's bottom-right is",
						"increase": "Extend the visible area further.",
						"decrease": "Shrink the visible area."
					}
				},
				"details": {
					"what": "Clamps the Camera2D so it can't scroll past the level edges.",
					"where": "Attach to a Camera2D. Set the bounds to match your level.",
					"before": "You need to know where your level starts and ends.",
					"after": "Combine with camera_follow_2d so the camera tracks the player within the bounds.",
					"why_optimized": "Uses Godot's built-in limit_* properties — no per-frame checks needed.",
					"mistakes": "Setting bottom_right smaller than top_left causes flicker and jitter.",
					"related": ["camera_follow_2d", "camera_deadzone", "camera_zoom"]
				}
			},
			"orbit_camera_3d": {
				"phrases": ["orbit camera", "orbit camera 3d", "rotate around target"],
				"code": """extends Node3D

@export var target_path: NodePath
@export var distance: float = 6.0
@export var sensitivity: float = 0.005

var _yaw: float = 0.0
var _pitch: float = 0.0
@onready var _target: Node3D = get_node(target_path) as Node3D

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_yaw -= event.relative.x * sensitivity
		_pitch = clamp(_pitch - event.relative.y * sensitivity, -1.2, 1.2)

func _process(_delta: float) -> void:
	global_position = _target.global_position + Vector3(0, 0, distance).rotated(Vector3.UP, _yaw).rotated(Vector3.RIGHT, _pitch)
	look_at(_target.global_position, Vector3.UP)
""",
				"params": ["target_path", "distance", "sensitivity"],
				"category": "camera",
				"dimension": "3d",
				"difficulty": "intermediate",
				"param_info": {
					"distance": {
						"default": 6.0,
						"range": [2.0, 30.0],
						"what": "How far the camera orbits from the target.",
						"typical": "3 close third-person / 6 standard / 15 wide / 25 strategy",
						"increase": "Camera pulls back, shows more.",
						"decrease": "Camera moves closer, more intimate."
					},
					"sensitivity": {
						"default": 0.005,
						"range": [0.001, 0.02],
						"what": "Mouse look speed multiplier.",
						"typical": "0.002 slow / 0.005 standard / 0.01 fast",
						"increase": "Camera turns faster.",
						"decrease": "Slower, more precise."
					}
				},
				"details": {
					"what": "A camera rig that orbits around a target when you move the mouse.",
					"where": "Attach to a Node3D that has a Camera3D child. Set target_path to the player.",
					"before": "Set Input.mouse_mode = CAPTURED so mouse events register.",
					"after": "Add camera collision — right now the camera passes through walls.",
					"why_optimized": "Vector rotation math avoids gimbal lock, works at any angle.",
					"mistakes": "Not clamping pitch lets the camera flip upside down.",
					"related": ["camera_follow_3d", "first_person_camera_3d", "mouse_look_3d"]
				}
			},
			"first_person_camera_3d": {
				"phrases": ["first person camera", "fps camera"],
				"code": """@onready var _camera: Camera3D = $Camera3D

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * 0.003)
		_camera.rotation.x = clamp(_camera.rotation.x - event.relative.y * 0.003, -1.5, 1.5)
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
""",
				"params": [],
				"category": "camera",
				"dimension": "3d",
				"difficulty": "beginner",
				"details": {
					"what": "Basic first-person mouse look. Locks the cursor and rotates the camera.",
					"where": "Attach to a CharacterBody3D with a Camera3D child named 'Camera3D'.",
					"before": "The node must have a Camera3D child.",
					"after": "Add first_person_movement for WASD movement.",
					"why_optimized": "Small — reads input events only when the mouse moves, no polling.",
					"mistakes": "Hardcoded sensitivity 0.003 — for tunability use mouse_look_3d instead.",
					"related": ["mouse_look_3d", "first_person_movement", "orbit_camera_3d"]
				}
			},
			"camera_deadzone": {
				"phrases": ["camera deadzone", "dead zone camera"],
				"code": """extends Camera2D

@export var target_path: NodePath
@export var deadzone: Vector2 = Vector2(48, 48)

@onready var _target: Node2D = get_node(target_path) as Node2D

func _process(_delta: float) -> void:
	var diff := _target.global_position - global_position
	if abs(diff.x) > deadzone.x:
		global_position.x = _target.global_position.x - sign(diff.x) * deadzone.x
	if abs(diff.y) > deadzone.y:
		global_position.y = _target.global_position.y - sign(diff.y) * deadzone.y
""",
				"params": ["target_path", "deadzone"],
				"category": "camera",
				"dimension": "2d",
				"difficulty": "intermediate",
				"param_info": {
					"deadzone": {
						"default": [48, 48],
						"range": [[8, 8], [200, 200]],
						"what": "How far the player can move before the camera follows. Vector2(X, Y).",
						"typical": "[32, 32] tight / [48, 48] standard / [96, 96] loose / [200, 200] very still",
						"increase": "Camera moves less — player walks within a larger box before it scrolls.",
						"decrease": "Camera follows tightly. Zero means no deadzone."
					}
				},
				"details": {
					"what": "The camera stays put until the player leaves a box around the center, then follows.",
					"where": "Attach to a Camera2D. Set target_path to the player.",
					"before": "Player must exist as a Node2D.",
					"after": "Combine with camera_follow_2d for smoother motion.",
					"why_optimized": "Two abs() checks per axis — cheaper than any smoothing method.",
					"mistakes": "Making the deadzone too large means the player runs off screen before the camera reacts.",
					"related": ["camera_follow_2d", "camera_smooth_follow_2d", "camera_limits_2d"]
				}
			}
		}
	}

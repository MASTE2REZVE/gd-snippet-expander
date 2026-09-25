@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"snippets": {
			"spring_arm_camera_3d": {
				"phrases": ["spring arm camera", "springarm 3d", "camera collision 3d", "third person camera collision"],
				"code": """extends SpringArm3D

@export var target_path: NodePath
@export var distance: float = 4.0
@export var min_distance: float = 1.0
@export var mouse_sensitivity: float = 0.003
@export var pitch_min: float = -1.2
@export var pitch_max: float = 0.8

var _yaw: float = 0.0
var _pitch: float = 0.0
@onready var _target: Node3D = get_node_or_null(target_path)
@onready var _camera: Camera3D = get_node_or_null("Camera3D")

func _ready() -> void:
	spring_length = distance
	if _camera != null:
		_camera.current = true

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_yaw -= event.relative.x * mouse_sensitivity
		_pitch = clampf(_pitch - event.relative.y * mouse_sensitivity, pitch_min, pitch_max)
	elif event is InputEventScreenDrag:
		_yaw -= event.relative.x * mouse_sensitivity
		_pitch = clampf(_pitch - event.relative.y * mouse_sensitivity, pitch_min, pitch_max)

func _process(_delta: float) -> void:
	if _target == null:
		return
	global_position = _target.global_position + Vector3(0, 1.0, 0)
	rotation.y = _yaw
	rotation.x = _pitch
	var desired: float = distance
	spring_length = desired

func set_camera_mode(first_person: bool) -> void:
	distance = 0.2 if first_person else 4.0
""",
				"params": ["target_path", "distance", "min_distance", "mouse_sensitivity", "pitch_min", "pitch_max"],
				"category": "camera",
				"subcategory": "3d",
				"platforms": ["desktop", "mobile"],
				"dimension": "3d",
				"difficulty": "intermediate",
				"param_info": {
					"distance": {
						"default": 4.0,
						"range": [0.5, 15.0],
						"what": "Ideal distance behind the target.",
						"typical": "2 close / 4 standard / 8 far / 0.2 first person",
						"increase": "Further back.",
						"decrease": "Closer."
					},
					"mouse_sensitivity": {
						"default": 0.003,
						"range": [0.0005, 0.02],
						"what": "Mouse or touch drag sensitivity.",
						"typical": "0.0015 slow / 0.003 standard / 0.006 fast",
						"increase": "Faster rotation.",
						"decrease": "Slower."
					}
				},
				"details": {
					"what": "Third-person camera that automatically pulls in when hitting walls. SpringArm3D handles collision — you don't need to raycast manually.",
					"where": "Structure: Player (CharacterBody3D) → SpringArm3D → Camera3D. Attach the script to the SpringArm3D.",
					"before": "A CharacterBody3D player. Add a SpringArm3D as a child, then a Camera3D as a child of the SpringArm3D.",
					"after": "Adjust spring_length to define the ideal distance. The spring automatically shortens it when a wall is in the way.",
					"why_optimized": "SpringArm3D does its own collision check internally. No manual raycast per frame.",
					"mistakes": "Putting the Camera3D at the SpringArm3D's origin means the collision happens after the camera — put the camera at the arm's tip.",
					"related": ["orbit_camera_3d", "first_person_camera_3d", "camera_follow_3d"]
				}
			},
			"shoulder_swap_3d": {
				"phrases": ["shoulder swap", "shoulder camera", "over the shoulder", "swap camera side"],
				"code": """extends Node3D

@export var left_offset: Vector3 = Vector3(-0.5, 0, 0)
@export var right_offset: Vector3 = Vector3(0.5, 0, 0)
@export var swap_speed: float = 8.0
@export var center_offset: Vector3 = Vector3.ZERO

enum Shoulder { LEFT, CENTER, RIGHT }
var _target: int = Shoulder.RIGHT
var _current_offset: Vector3 = Vector3.ZERO

@onready var _camera: Camera3D = get_node_or_null("Camera3D")

func _ready() -> void:
	_current_offset = right_offset

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("swap_shoulder"):
		_cycle_shoulder()

func _cycle_shoulder() -> void:
	_target = (_target + 1) % 3

func _process(delta: float) -> void:
	var target_offset: Vector3 = _offset_for(_target)
	_current_offset = _current_offset.lerp(target_offset, swap_speed * delta)
	if _camera != null:
		_camera.position = _current_offset

func _offset_for(shoulder: int) -> Vector3:
	match shoulder:
		Shoulder.LEFT: return left_offset
		Shoulder.CENTER: return center_offset
		Shoulder.RIGHT: return right_offset
	return right_offset

func set_shoulder(shoulder: int) -> void:
	_target = shoulder
""",
				"params": ["left_offset", "right_offset", "swap_speed", "center_offset"],
				"category": "camera",
				"subcategory": "3d",
				"platforms": ["desktop", "mobile"],
				"dimension": "3d",
				"difficulty": "beginner",
				"required_actions": ["swap_shoulder"],
				"param_info": {
					"left_offset": {
						"default": [-0.5, 0, 0],
						"range": [],
						"what": "Camera position offset when on the left shoulder.",
						"typical": "[-0.5, 0, 0] standard",
						"increase": "Further left.",
						"decrease": "Closer to center."
					},
					"right_offset": {
						"default": [0.5, 0, 0],
						"range": [],
						"what": "Camera position offset when on the right shoulder.",
						"typical": "[0.5, 0, 0] standard",
						"increase": "Further right.",
						"decrease": "Closer to center."
					},
					"swap_speed": {
						"default": 8.0,
						"range": [2.0, 20.0],
						"what": "How fast the camera slides to the new position.",
						"typical": "4 slow / 8 standard / 15 snappy",
						"increase": "Faster swap.",
						"decrease": "Slower."
					}
				},
				"details": {
					"what": "Over-the-shoulder camera that cycles left, center, right when the swap key is pressed. Classic for shooters.",
					"where": "Attach to a Node3D that's a child of the player, with a Camera3D child. The Node3D handles the rotation, this script just offsets the camera position.",
					"before": "Input action 'swap_shoulder' bound to a key (often Q or middle mouse).",
					"after": "Add a small animation to the crosshair moving with the camera.",
					"why_optimized": "lerp between offsets is one vector operation per frame.",
					"mistakes": "Moving the Node3D itself instead of just the Camera3D means the whole camera rig shifts and the aim direction changes.",
					"related": ["spring_arm_camera_3d", "orbit_camera_3d", "first_person_camera_3d"]
				}
			},
			"camera_shake_3d": {
				"phrases": ["camera shake 3d", "shake camera 3d", "screen shake 3d", "impact shake 3d"],
				"code": """extends Camera3D

@export var shake_decay: float = 5.0
@export var max_offset: float = 0.5
@export var max_roll: float = 0.05

var _shake_amount: float = 0.0
var _origin_position: Vector3 = Vector3.ZERO
var _origin_rotation: Vector3 = Vector3.ZERO
var _noise_time: float = 0.0
var _noise := FastNoiseLite.new()

func _ready() -> void:
	_origin_position = position
	_origin_rotation = rotation
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_noise.frequency = 5.0

func shake(amount: float) -> void:
	_shake_amount = maxf(_shake_amount, amount)

func shake_heavy() -> void:
	shake(0.8)

func shake_light() -> void:
	shake(0.2)

func _process(delta: float) -> void:
	if _shake_amount <= 0.001:
		position = _origin_position
		rotation = _origin_rotation
		return
	_noise_time += delta * 25.0
	var offset := Vector3(
		_noise.get_noise_2d(_noise_time, 0.0),
		_noise.get_noise_2d(0.0, _noise_time),
		0.0
	) * max_offset * _shake_amount
	var roll := _noise.get_noise_2d(_noise_time, 100.0) * max_roll * _shake_amount
	position = _origin_position + offset
	rotation = Vector3(
		_origin_rotation.x,
		_origin_rotation.y,
		_origin_rotation.z + roll
	)
	_shake_amount = maxf(_shake_amount - shake_decay * delta, 0.0)
""",
				"params": ["shake_decay", "max_offset", "max_roll"],
				"category": "camera",
				"subcategory": "3d",
				"platforms": ["desktop", "mobile"],
				"dimension": "3d",
				"difficulty": "beginner",
				"param_info": {
					"shake_decay": {
						"default": 5.0,
						"range": [1.0, 20.0],
						"what": "How fast the shake fades.",
						"typical": "2 long rumble / 5 standard / 12 short punch",
						"increase": "Shorter shake.",
						"decrease": "Longer."
					},
					"max_offset": {
						"default": 0.5,
						"range": [0.05, 2.0],
						"what": "Maximum position offset in meters.",
						"typical": "0.1 subtle / 0.5 standard / 1.5+ dramatic",
						"increase": "Bigger shake.",
						"decrease": "Smaller."
					}
				},
				"details": {
					"what": "3D camera shake using noise. Additive to the camera's position and roll. Call shake() from hit handlers.",
					"where": "Attach directly to a Camera3D. The script stores origin position and rotation, then adds offset on top.",
					"before": "None.",
					"after": "Combine with hitstop and screen flash for full impact feel. See hit_feedback_3d snippet.",
					"why_optimized": "FastNoiseLite gives smooth shake without storing per-frame random values. Only 3 noise lookups per frame.",
					"mistakes": "Adding the shake to a camera that's a child of a SpringArm or rotation rig means the origin drifts. Store and restore the local origin each frame.",
					"related": ["hit_feedback_3d", "spring_arm_camera_3d", "camera_shake"]
				}
			},
			"camera_look_at_target_3d": {
				"phrases": ["camera look at target", "lock on camera", "look at enemy", "camera target lock"],
				"code": """extends Camera3D

@export var target: Node3D
@export var follow_speed: float = 4.0
@export var offset: Vector3 = Vector3(0, 1.5, 3.0)
@export var smooth_rotation: bool = true

var _velocity: Vector3 = Vector3.ZERO

func _process(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		return
	var desired := target.global_position + offset
	if follow_speed > 0.0:
		global_position = global_position.lerp(desired, follow_speed * delta)
	else:
		global_position = desired
	if smooth_rotation:
		var t := Transform3D().looking_at(target.global_position, Vector3.UP)
		var current_basis := global_transform.basis
		var new_basis := current_basis.slerp(t.basis, follow_speed * delta)
		global_transform.basis = new_basis
	else:
		look_at(target.global_position, Vector3.UP)

func set_target(new_target: Node3D) -> void:
	target = new_target

func clear_target() -> void:
	target = null
""",
				"params": ["target", "follow_speed", "offset", "smooth_rotation"],
				"category": "camera",
				"subcategory": "3d",
				"platforms": ["desktop", "mobile"],
				"dimension": "3d",
				"difficulty": "beginner",
				"param_info": {
					"follow_speed": {
						"default": 4.0,
						"range": [0.0, 20.0],
						"what": "How fast the camera catches up. 0 means instant.",
						"typical": "0 instant / 4 smooth / 10 tight / 20 snappy",
						"increase": "Faster catch-up.",
						"decrease": "Slower, more cinematic."
					},
					"offset": {
						"default": [0, 1.5, 3.0],
						"range": [],
						"what": "Position offset from the target.",
						"typical": "[0, 1.5, 3] over-the-shoulder / [0, 5, 8] wide / [0, 0, 0] first person",
						"increase": "Further away.",
						"decrease": "Closer."
					}
				},
				"details": {
					"what": "Camera that follows and looks at a target. Smooth rotation via basis slerp — no snapping when the target moves suddenly.",
					"where": "Attach to a standalone Camera3D. Set target to the player or a focal point.",
					"before": "A target Node3D in the scene.",
					"after": "Switch targets during a cutscene by calling set_target(). Clear with clear_target() to give manual control.",
					"why_optimized": "Basis slerp gives smooth interpolation without gimbal lock or angle wraparound issues.",
					"mistakes": "Using look_at() every frame causes snapping. Set smooth_rotation to true for silky rotation.",
					"related": ["camera_follow_3d", "spring_arm_camera_3d", "orbit_camera_3d"]
				}
			},
			"camera_zoom_3d": {
				"phrases": ["camera zoom 3d", "zoom 3d", "fov zoom", "fov change"],
				"code": """extends Camera3D

@export var default_fov: float = 75.0
@export var zoomed_fov: float = 35.0
@export var zoom_speed: float = 8.0
@export var mouse_wheel_step: float = 3.0

var _target_fov: float = 75.0

func _ready() -> void:
	fov = default_fov
	_target_fov = default_fov

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_target_fov = clampf(_target_fov - mouse_wheel_step, 10.0, 120.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_target_fov = clampf(_target_fov + mouse_wheel_step, 10.0, 120.0)
	elif event.is_action_pressed("zoom"):
		_target_fov = zoomed_fov
	elif event.is_action_released("zoom"):
		_target_fov = default_fov

func _process(delta: float) -> void:
	fov = lerpf(fov, _target_fov, zoom_speed * delta)

func set_fov(value: float) -> void:
	_target_fov = clampf(value, 10.0, 120.0)
""",
				"params": ["default_fov", "zoomed_fov", "zoom_speed", "mouse_wheel_step"],
				"category": "camera",
				"subcategory": "3d",
				"platforms": ["desktop", "mobile"],
				"dimension": "3d",
				"difficulty": "beginner",
				"param_info": {
					"default_fov": {
						"default": 75.0,
						"range": [50.0, 110.0],
						"what": "Default field of view in degrees.",
						"typical": "60 cinematic / 75 standard / 90 wide / 110 fisheye",
						"increase": "Wider view, more distorted.",
						"decrease": "Narrower, more zoomed."
					},
					"zoomed_fov": {
						"default": 35.0,
						"range": [10.0, 60.0],
						"what": "Field of view when zoomed in.",
						"typical": "20 sniper scope / 35 standard zoom / 50 subtle",
						"increase": "Less zoom.",
						"decrease": "More zoom."
					}
				},
				"details": {
					"what": "Smooth FOV zoom for 3D cameras. Mouse wheel for gradual zoom, or a 'zoom' action for a sniper scope.",
					"where": "Attach to a Camera3D. Tweening FOV is smoother than moving the camera position.",
					"before": "None.",
					"after": "Add a zoom vignette or scope overlay UI when zoomed for a sniper feel.",
					"why_optimized": "FOV is a single float change. No camera repositioning required — everything interpolates from the current view.",
					"mistakes": "Very low FOV (under 10) causes perspective distortion that looks wrong. Keep above 15.",
					"related": ["spring_arm_camera_3d", "first_person_camera_3d", "camera_zoom"]
				}
			}
		}
	}

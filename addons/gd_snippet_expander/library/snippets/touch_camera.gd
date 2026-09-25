@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"snippets": {
			"touch_drag_look": {
				"phrases": ["touch drag look", "mobile mouse look", "drag look", "touch 3d look"],
				"code": """extends CharacterBody3D

@export var touch_sensitivity: float = 0.005
@export var pitch_min: float = -1.5
@export var pitch_max: float = 1.5

@onready var _camera: Camera3D = $Camera3D

var _active_touch: int = -1
var _last_position: Vector2 = Vector2.ZERO

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _active_touch < 0:
			_active_touch = event.index
			_last_position = event.position
		elif not event.pressed and event.index == _active_touch:
			_active_touch = -1
	elif event is InputEventScreenDrag:
		if event.index != _active_touch:
			return
		var delta := event.position - _last_position
		_last_position = event.position
		rotate_y(-delta.x * touch_sensitivity)
		_camera.rotation.x = clamp(_camera.rotation.x - delta.y * touch_sensitivity, pitch_min, pitch_max)

func _input(event: InputEvent) -> void:
	# Optional: fall back to mouse on desktop
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * touch_sensitivity * 0.6)
		_camera.rotation.x = clamp(_camera.rotation.x - event.relative.y * touch_sensitivity * 0.6, pitch_min, pitch_max)
""",
				"params": ["touch_sensitivity", "pitch_min", "pitch_max"],
				"category": "touch",
				"subcategory": "camera",
				"platforms": ["mobile", "desktop", "web"],
				"dimension": "3d",
				"difficulty": "intermediate",
				"param_info": {
					"touch_sensitivity": {
						"default": 0.005,
						"range": [0.001, 0.02],
						"what": "Multiplier for touch drag distance.",
						"typical": "0.002 slow / 0.005 standard / 0.01 fast",
						"increase": "Faster look.",
						"decrease": "Slower, more precise."
					},
					"pitch_min": {
						"default": -1.5,
						"range": [-3.14, 0.0],
						"what": "Lowest camera pitch in radians (looking down limit).",
						"typical": "-1.5 for standard FPS",
						"increase": "Camera looks further down.",
						"decrease": "N/A"
					},
					"pitch_max": {
						"default": 1.5,
						"range": [0.0, 3.14],
						"what": "Highest camera pitch in radians (looking up limit).",
						"typical": "1.5 for standard FPS",
						"increase": "Camera looks further up.",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "Touch drag look for mobile. Replaces mouse_look_3d. Tracks a single finger and rotates the body (yaw) and camera (pitch). Falls back to mouse on desktop.",
					"where": "Attach to a CharacterBody3D with a Camera3D child named 'Camera3D'. Same structure as mouse_look_3d.",
					"before": "Camera3D as a child of the player. Touch input works without any input action mapping.",
					"after": "Combine with touch_button for jump and virtual_joystick for movement.",
					"why_optimized": "Only reads drag events, not every touch. Tracks a single finger by index so multi-touch gestures don't interfere.",
					"mistakes": "Dragging over UI elements moves the camera behind the menu. Use CanvasLayer with mouse_filter = STOP on UI to block.",
					"related": ["mouse_look_3d", "first_person_movement", "virtual_joystick", "touch_button"]
				}
			},
			"pinch_zoom": {
				"phrases": ["pinch zoom", "two finger zoom", "mobile zoom", "touch zoom"],
				"code": """extends Camera2D

@export var min_zoom: float = 0.5
@export var max_zoom: float = 3.0
@export var zoom_speed: float = 1.5

var _first_touch: int = -1
var _second_touch: int = -1
var _positions: Dictionary = {}
var _last_distance: float = 0.0

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_positions[event.index] = event.position
			if _first_touch < 0:
				_first_touch = event.index
			elif _second_touch < 0:
				_second_touch = event.index
				_last_distance = _positions[_first_touch].distance_to(_positions[_second_touch])
		else:
			_positions.erase(event.index)
			if event.index == _first_touch:
				_first_touch = _second_touch
				_second_touch = -1
			elif event.index == _second_touch:
				_second_touch = -1
	elif event is InputEventScreenDrag:
		if not _positions.has(event.index):
			return
		_positions[event.index] = event.position
		if _first_touch < 0 or _second_touch < 0:
			return
		var current_distance: float = _positions[_first_touch].distance_to(_positions[_second_touch])
		var ratio: float = current_distance / max(_last_distance, 1.0)
		var new_zoom: float = clamp(zoom.x * (1.0 + (ratio - 1.0) * zoom_speed * 0.1), min_zoom, max_zoom)
		zoom = Vector2(new_zoom, new_zoom)
		_last_distance = current_distance
""",
				"params": ["min_zoom", "max_zoom", "zoom_speed"],
				"category": "touch",
				"subcategory": "camera",
				"platforms": ["mobile"],
				"dimension": "2d",
				"difficulty": "intermediate",
				"param_info": {
					"min_zoom": {
						"default": 0.5,
						"range": [0.1, 1.0],
						"what": "Furthest zoom out allowed.",
						"typical": "0.3 strategy / 0.5 standard",
						"increase": "Less zoom out.",
						"decrease": "More zoom out."
					},
					"max_zoom": {
						"default": 3.0,
						"range": [1.0, 10.0],
						"what": "Closest zoom in allowed.",
						"typical": "2 character / 3 detail / 5 very close",
						"increase": "More zoom in.",
						"decrease": "Less."
					},
					"zoom_speed": {
						"default": 1.5,
						"range": [0.5, 4.0],
						"what": "Multiplier for pinch responsiveness.",
						"typical": "1.0 subtle / 1.5 standard / 3.0 sensitive",
						"increase": "Faster zoom.",
						"decrease": "Slower."
					}
				},
				"details": {
					"what": "Two-finger pinch to zoom a Camera2D. Replaces camera_zoom (mouse wheel) on mobile.",
					"where": "Attach to a Camera2D. Works alongside camera_follow_2d or camera_smooth_follow_2d.",
					"before": "Camera2D active in the scene. No input action needed.",
					"after": "Add double-tap to reset zoom for a quick return to default.",
					"why_optimized": "Only computes distance when two touches are active. Dictionary storage is O(1) per touch.",
					"mistakes": "The ratio calculation uses current_distance / last_distance so a stationary pinch doesn't drift. Guarding max() avoids division by zero.",
					"related": ["camera_zoom", "touch_drag_pan", "camera_follow_2d"]
				}
			},
			"tap_to_aim": {
				"phrases": ["tap to aim", "touch aim", "mobile aim", "tap target"],
				"code": """extends Node2D

signal aim_changed(world_position: Vector2, direction: Vector2)

@export var touch_radius: float = 60.0

var _aim_position: Vector2 = Vector2.ZERO
var _has_aim: bool = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_set_aim(event.position)
	elif event is InputEventScreenDrag:
		_set_aim(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_set_aim(event.position)

func _set_aim(screen_position: Vector2) -> void:
	var world_pos := get_global_mouse_position()
	# Convert screen to world using the active Camera2D
	var camera := get_viewport().get_camera_2d()
	if camera != null:
		world_pos = camera.get_screen_center_position() + (screen_position - get_viewport_rect().size * 0.5) / camera.zoom
	_aim_position = world_pos
	_has_aim = true
	var direction := (world_pos - global_position).normalized()
	aim_changed.emit(world_pos, direction)

func get_aim_position() -> Vector2:
	return _aim_position

func get_aim_direction() -> Vector2:
	if not _has_aim:
		return Vector2.RIGHT
	return (_aim_position - global_position).normalized()

func has_aim() -> bool:
	return _has_aim
""",
				"params": ["touch_radius"],
				"category": "touch",
				"subcategory": "aim",
				"platforms": ["mobile", "desktop", "web"],
				"dimension": "2d",
				"difficulty": "intermediate",
				"param_info": {
					"touch_radius": {
						"default": 60.0,
						"range": [20.0, 200.0],
						"what": "Reserved for future use — snapping radius for tap targets.",
						"typical": "60 standard",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "Tap or drag on screen to set an aim direction. Replaces camera_look_at_mouse for mobile games.",
					"where": "Attach to the player CharacterBody2D. Read get_aim_direction() when firing or attacking.",
					"before": "Camera2D in the scene. Tap input works without any input action mapping.",
					"after": "Draw an aim indicator (a line or arrow) at get_aim_position() for player feedback.",
					"why_optimized": "Screen-to-world conversion uses the camera directly. No physics raycast needed for top-down games.",
					"mistakes": "Using get_global_mouse_position() alone doesn't work on touch. The manual conversion via camera.transform handles both.",
					"related": ["camera_look_at_mouse", "ranged_attack", "topdown_look_direction"]
				}
			},
			"touch_orbit_camera": {
				"phrases": ["touch orbit camera", "mobile orbit", "drag orbit", "touch 3d orbit"],
				"code": """extends Node3D

@export var target_path: NodePath
@export var distance: float = 6.0
@export var sensitivity: float = 0.01
@export var min_distance: float = 2.0
@export var max_distance: float = 15.0

var _yaw: float = 0.0
var _pitch: float = 0.0
var _active_touch: int = -1
var _last_position: Vector2 = Vector2.ZERO
var _pinch_first: int = -1
var _pinch_second: int = -1
var _positions: Dictionary = {}
var _last_pinch_distance: float = 0.0

@onready var _target: Node3D = get_node(target_path)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_yaw -= event.relative.x * sensitivity
		_pitch = clamp(_pitch - event.relative.y * sensitivity, -1.2, 1.2)

func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		_positions[event.index] = event.position
		if _pinch_first < 0:
			_pinch_first = event.index
			_active_touch = event.index
			_last_position = event.position
		elif _pinch_second < 0:
			_pinch_second = event.index
			_last_pinch_distance = _positions[_pinch_first].distance_to(_positions[_pinch_second])
	else:
		_positions.erase(event.index)
		if event.index == _pinch_first:
			_pinch_first = _pinch_second
			_pinch_second = -1
			_active_touch = _pinch_first
		elif event.index == _pinch_second:
			_pinch_second = -1
		if event.index == _active_touch:
			_active_touch = -1

func _handle_drag(event: InputEventScreenDrag) -> void:
	if not _positions.has(event.index):
		return
	_positions[event.index] = event.position
	if _pinch_second >= 0:
		var current_distance: float = _positions[_pinch_first].distance_to(_positions[_pinch_second])
		var ratio := current_distance / max(_last_pinch_distance, 1.0)
		distance = clamp(distance * (1.0 / max(ratio, 0.5)), min_distance, max_distance)
		_last_pinch_distance = current_distance
	elif event.index == _active_touch:
		var delta := event.position - _last_position
		_last_position = event.position
		_yaw -= delta.x * sensitivity
		_pitch = clamp(_pitch - delta.y * sensitivity, -1.2, 1.2)

func _process(_delta: float) -> void:
	global_position = _target.global_position + Vector3(0, 0, distance).rotated(Vector3.UP, _yaw).rotated(Vector3.RIGHT, _pitch)
	look_at(_target.global_position, Vector3.UP)
""",
				"params": ["distance", "sensitivity", "min_distance", "max_distance"],
				"category": "touch",
				"subcategory": "camera",
				"platforms": ["mobile", "desktop"],
				"dimension": "3d",
				"difficulty": "advanced",
				"param_info": {
					"distance": {
						"default": 6.0,
						"range": [2.0, 30.0],
						"what": "Starting orbit distance from the target.",
						"typical": "3 close / 6 standard / 15 wide",
						"increase": "Camera further.",
						"decrease": "Closer."
					},
					"sensitivity": {
						"default": 0.01,
						"range": [0.002, 0.03],
						"what": "Drag sensitivity.",
						"typical": "0.005 slow / 0.01 standard / 0.02 fast",
						"increase": "Faster drag.",
						"decrease": "Slower."
					},
					"min_distance": {
						"default": 2.0,
						"range": [0.5, 10.0],
						"what": "Closest the pinch can zoom in.",
						"typical": "1.5 close / 2.0 standard",
						"increase": "Stops zooming in sooner.",
						"decrease": "Allows closer."
					},
					"max_distance": {
						"default": 15.0,
						"range": [5.0, 50.0],
						"what": "Furthest the pinch can zoom out.",
						"typical": "15 standard / 30+ wide shot",
						"increase": "Allows zoom out further.",
						"decrease": "Stops zoom out sooner."
					}
				},
				"details": {
					"what": "3D orbit camera driven by touch drag (rotate) and pinch (zoom). Replaces orbit_camera_3d on mobile.",
					"where": "Attach to a Node3D with a Camera3D child. Set target_path to the player.",
					"before": "Player is a Node3D in the scene. Camera3D as a child of this rig.",
					"after": "Add a camera collision SpringArm3D for walls.",
					"why_optimized": "Handles single-touch drag and two-touch pinch separately. Only computes when the correct touches are active.",
					"mistakes": "Trying to drag with one finger while the joystick is held with another. The joystick should only claim the left half of the screen.",
					"related": ["orbit_camera_3d", "virtual_joystick", "touch_drag_pan"]
				}
			},
			"touch_drag_pan": {
				"phrases": ["touch drag pan", "drag pan camera", "mobile camera pan", "touch scroll map"],
				"code": """extends Camera2D

@export var pan_speed: float = 1.0
@export var edge_pan_margin: float = 40.0
@export var edge_pan_speed: float = 400.0
@export var use_edge_pan: bool = false

var _dragging: bool = false
var _last_position: Vector2 = Vector2.ZERO
var _active_touch: int = -1

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _active_touch < 0:
			_active_touch = event.index
			_dragging = true
			_last_position = event.position
		elif not event.pressed and event.index == _active_touch:
			_dragging = false
			_active_touch = -1
	elif event is InputEventScreenDrag:
		if event.index != _active_touch:
			return
		var delta := event.position - _last_position
		_last_position = event.position
		global_position -= delta * pan_speed / zoom
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed
		_last_position = event.position
	elif event is InputEventMouseMotion and _dragging:
		global_position -= event.relative * pan_speed / zoom

func _process(delta: float) -> void:
	if not use_edge_pan or _dragging:
		return
	var mouse_pos := get_viewport().get_mouse_position()
	var viewport_size := get_viewport_rect().size
	var direction := Vector2.ZERO
	if mouse_pos.x < edge_pan_margin:
		direction.x = -1.0
	elif mouse_pos.x > viewport_size.x - edge_pan_margin:
		direction.x = 1.0
	if mouse_pos.y < edge_pan_margin:
		direction.y = -1.0
	elif mouse_pos.y > viewport_size.y - edge_pan_margin:
		direction.y = 1.0
	if direction.length() > 0.0:
		global_position += direction.normalized() * edge_pan_speed * delta / zoom
""",
				"params": ["pan_speed", "edge_pan_margin", "edge_pan_speed", "use_edge_pan"],
				"category": "touch",
				"subcategory": "camera",
				"platforms": ["mobile", "desktop"],
				"dimension": "2d",
				"difficulty": "intermediate",
				"param_info": {
					"pan_speed": {
						"default": 1.0,
						"range": [0.3, 3.0],
						"what": "Multiplier for drag pan speed.",
						"typical": "0.5 slow / 1.0 standard / 2.0 fast",
						"increase": "Faster pan.",
						"decrease": "Slower."
					},
					"use_edge_pan": {
						"default": false,
						"range": [],
						"what": "True to scroll when the mouse is near screen edges (RTS style).",
						"typical": "true for strategy games / false for direct drag",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"edge_pan_speed": {
						"default": 400.0,
						"range": [100.0, 2000.0],
						"what": "Pixels per second when edge panning.",
						"typical": "200 slow / 400 standard / 1000 fast",
						"increase": "Faster edge scroll.",
						"decrease": "Slower."
					}
				},
				"details": {
					"what": "Drag-to-pan camera for strategy games, puzzle games, and map views. Works with touch drag and mouse drag.",
					"where": "Attach to a Camera2D that isn't following a player. Common in RTS and town-building games.",
					"before": "Camera2D active in the scene. Set limit_left/top/right/bottom to keep it within the map bounds.",
					"after": "Combine with pinch_zoom for full mobile RTS camera control.",
					"why_optimized": "Dividing delta by zoom keeps pan speed consistent across zoom levels. Edge pan check is two comparisons per edge.",
					"mistakes": "Not dividing by zoom makes the camera move too fast when zoomed in and too slow when zoomed out.",
					"related": ["camera_limits_2d", "pinch_zoom", "touch_drag_look"]
				}
			}
		}
	}

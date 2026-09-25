@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"snippets": {
			"fov_platform_3d": {
				"phrases": ["fov platform", "mobile fov", "3d fov platform", "adaptive fov"],
				"code": """extends Camera3D

@export var desktop_fov: float = 75.0
@export var mobile_fov: float = 85.0
@export var web_fov: float = 75.0
@export var aspect_compensation: bool = true

func _ready() -> void:
	fov = _pick_base_fov()
	if aspect_compensation:
		get_viewport().size_changed.connect(_apply_aspect_compensation)
		_apply_aspect_compensation()

func _pick_base_fov() -> float:
	if OS.has_feature("web"):
		return web_fov
	if DisplayServer.is_touchscreen_available():
		return mobile_fov
	return desktop_fov

func _apply_aspect_compensation() -> void:
	if not aspect_compensation:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	if viewport_size.y <= 0.0:
		return
	var aspect: float = viewport_size.x / viewport_size.y
	# Reference aspect is 16:9 (~1.78). Wider screens get slightly more FOV,
	# taller (portrait) screens get slightly less.
	var ratio: float = aspect / 1.7778
	var base: float = _pick_base_fov()
	fov = clampf(base * (1.0 + (ratio - 1.0) * 0.4), 50.0, 110.0)

func set_platform_fov(override_fov: float) -> void:
	desktop_fov = override_fov
	mobile_fov = override_fov
	web_fov = override_fov
	fov = override_fov
""",
				"params": ["desktop_fov", "mobile_fov", "web_fov", "aspect_compensation"],
				"category": "platform",
				"subcategory": "3d",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "intermediate",
				"param_info": {
					"mobile_fov": {
						"default": 85.0,
						"range": [60.0, 110.0],
						"what": "FOV used on touch devices. Wider because phone screens are small.",
						"typical": "75 tight / 85 standard / 100+ very wide",
						"increase": "Wider view on mobile.",
						"decrease": "Narrower, more cinematic."
					},
					"aspect_compensation": {
						"default": true,
						"range": [],
						"what": "Adjust FOV based on screen aspect ratio.",
						"typical": "true for cross-platform / false for fixed-target",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "Picks the right FOV for the platform and compensates for unusual aspect ratios. Keeps the game readable on phones, tablets, and desktops.",
					"where": "Attach to the active Camera3D. Called once on _ready and on viewport resize.",
					"before": "None.",
					"after": "For a cinematic FOV per scene, override with set_platform_fov().",
					"why_optimized": "Single computation on ready and resize, not per frame.",
					"mistakes": "Very narrow FOV on portrait phones cuts off too much. Mobile FOV should stay above 80.",
					"related": ["camera_zoom_3d", "platform_detect", "safe_area_ui"]
				}
			},
			"touch_look_3d": {
				"phrases": ["touch look 3d", "mobile look 3d", "3d touch camera", "touch mouse look 3d"],
				"code": """extends CharacterBody3D

signal touch_look_input(relative: Vector2)

@export var sensitivity: float = 0.005
@export var touch_look_zone: Rect2 = Rect2(0.5, 0.0, 0.5, 1.0)
@export var invert_y: bool = false

var _active_touch: int = -1
var _last_position: Vector2 = Vector2.ZERO
@onready var _camera: Camera3D = get_node_or_null("Camera3D")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_apply_look(event.relative)

func _handle_touch(event: InputEventScreenTouch) -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var normalized: Vector2 = event.position / viewport_size
	if event.pressed:
		if _active_touch < 0 and touch_look_zone.has_point(normalized):
			_active_touch = event.index
			_last_position = event.position
	elif event.index == _active_touch:
		_active_touch = -1

func _handle_drag(event: InputEventScreenDrag) -> void:
	if event.index != _active_touch:
		return
	var delta := event.position - _last_position
	_last_position = event.position
	_apply_look(delta)

func _apply_look(relative: Vector2) -> void:
	var y_sign: float = 1.0 if not invert_y else -1.0
	rotate_y(-relative.x * sensitivity)
	if _camera != null:
		_camera.rotation.x = clampf(
			_camera.rotation.x - relative.y * sensitivity * y_sign,
			-1.5,
			1.5
		)
	touch_look_input.emit(relative)
""",
				"params": ["sensitivity", "touch_look_zone", "invert_y"],
				"category": "platform",
				"subcategory": "3d",
				"platforms": ["mobile", "desktop"],
				"dimension": "3d",
				"difficulty": "intermediate",
				"param_info": {
					"sensitivity": {
						"default": 0.005,
						"range": [0.001, 0.02],
						"what": "Touch or mouse look multiplier.",
						"typical": "0.002 slow / 0.005 standard / 0.01 fast",
						"increase": "Faster look.",
						"decrease": "Slower."
					},
					"touch_look_zone": {
						"default": [0.5, 0, 0.5, 1],
						"range": [],
						"what": "Screen rect where touch drag rotates the camera. Default is right half.",
						"typical": "[0.5, 0, 0.5, 1] right half / [0, 0, 1, 1] full screen",
						"increase": "Bigger zone.",
						"decrease": "Smaller."
					}
				},
				"details": {
					"what": "Touch look for 3D games with a virtual joystick. Left half drives movement, right half looks around.",
					"where": "Attach to a CharacterBody3D with a Camera3D child. Works alongside virtual_joystick_ui.",
					"before": "Player in group 'player'. A virtual joystick on the left half of the screen.",
					"after": "Combine with touch_button for jump and attack.",
					"why_optimized": "Single finger tracked by index. Only applies look when a drag arrives.",
					"mistakes": "Using the whole screen for look means the joystick's left-half taps rotate the camera. Restrict the touch_look_zone to the right half.",
					"related": ["touch_drag_look", "virtual_joystick_ui", "first_person_movement", "fov_platform_3d"]
				}
			},
			"mobile_quality_scaler_3d": {
				"phrases": ["mobile quality 3d", "quality scaler", "adaptive quality", "performance scaling"],
				"code": """extends Node

@export var target_fps: int = 60
@export var min_scale: float = 0.5
@export var max_scale: float = 1.0
@export var adjust_interval: float = 2.0

var _current_scale: float = 1.0
var _check_timer: float = 0.0
var _fps_samples: Array = []

func _ready() -> void:
	_current_scale = _get_initial_scale()
	_apply_scale()
	Engine.max_fps = target_fps

func _process(delta: float) -> void:
	_check_timer += delta
	_fps_samples.append(Engine.get_frames_per_second())
	if _check_timer >= adjust_interval:
		_adjust()
		_check_timer = 0.0
		_fps_samples.clear()

func _get_initial_scale() -> float:
	if OS.has_feature("web"):
		return 0.85
	if DisplayServer.is_touchscreen_available():
		return 0.75
	return 1.0

func _apply_scale() -> void:
	var viewport := get_viewport()
	viewport.scaling_3d_scale = _current_scale

func _adjust() -> void:
	if _fps_samples.is_empty():
		return
	var avg_fps: float = 0.0
	for f in _fps_samples:
		avg_fps += float(f)
	avg_fps /= float(_fps_samples.size())
	if avg_fps < target_fps * 0.85 and _current_scale > min_scale:
		_current_scale = maxf(_current_scale - 0.1, min_scale)
		_apply_scale()
	elif avg_fps > target_fps * 0.95 and _current_scale < max_scale:
		_current_scale = minf(_current_scale + 0.05, max_scale)
		_apply_scale()

func set_quality(scale: float) -> void:
	_current_scale = clampf(scale, min_scale, max_scale)
	_apply_scale()

func get_current_scale() -> float:
	return _current_scale
""",
				"params": ["target_fps", "min_scale", "max_scale", "adjust_interval"],
				"category": "platform",
				"subcategory": "3d",
				"platforms": ["mobile", "web", "desktop"],
				"dimension": "3d",
				"difficulty": "advanced",
				"param_info": {
					"target_fps": {
						"default": 60,
						"range": [30, 144],
						"what": "FPS target the scaler tries to maintain.",
						"typical": "30 battery saver / 60 standard / 120 high refresh",
						"increase": "Higher target.",
						"decrease": "Lower."
					},
					"min_scale": {
						"default": 0.5,
						"range": [0.3, 1.0],
						"what": "Lowest 3D resolution scale the scaler will use.",
						"typical": "0.5 blurry but fast / 0.7 good balance / 0.85 quality",
						"increase": "Higher minimum quality.",
						"decrease": "Allows lower resolution."
					},
					"adjust_interval": {
						"default": 2.0,
						"range": [0.5, 10.0],
						"what": "Seconds between quality adjustments.",
						"typical": "1.0 reactive / 2.0 standard / 5.0+ stable",
						"increase": "Less frequent changes.",
						"decrease": "More responsive."
					}
				},
				"details": {
					"what": "Dynamically scales 3D render resolution to maintain target FPS. Reduces quality on slow hardware, increases it when headroom exists.",
					"where": "Add as an autoload or to the scene root. Works with any 3D scene.",
					"before": "None.",
					"after": "Expose set_quality() to a settings menu so players can override.",
					"why_optimized": "Only checks every adjust_interval seconds. scaling_3d_scale is a single viewport property.",
					"mistakes": "Adjusting too aggressively makes quality visibly flicker. 0.1 steps and 2-second intervals are conservative.",
					"related": ["debug_overlay_3d", "platform_detect", "fov_platform_3d"]
				}
			},
			"mobile_ui_scale_3d": {
				"phrases": ["mobile ui 3d", "3d ui scale", "hud scale mobile", "touch ui scale"],
				"code": """extends CanvasLayer

@export var desktop_scale: float = 1.0
@export var mobile_scale: float = 1.4
@export var web_scale: float = 1.0

func _ready() -> void:
	_apply_scale()
	get_tree().root.size_changed.connect(_apply_scale)

func _apply_scale() -> void:
	var target: float = _pick_scale()
	for child in get_children():
		if child is Control:
			(child as Control).scale = Vector2(target, target)

func _pick_scale() -> float:
	if OS.has_feature("web"):
		return web_scale
	if DisplayServer.is_touchscreen_available():
		return mobile_scale
	return desktop_scale

func set_scale_override(value: float) -> void:
	desktop_scale = value
	mobile_scale = value
	web_scale = value
	_apply_scale()
""",
				"params": ["desktop_scale", "mobile_scale", "web_scale"],
				"category": "platform",
				"subcategory": "3d",
				"platforms": ["mobile", "desktop", "web"],
				"dimension": "ui",
				"difficulty": "beginner",
				"param_info": {
					"mobile_scale": {
						"default": 1.4,
						"range": [1.0, 2.0],
						"what": "Scale factor applied to HUD Controls on mobile.",
						"typical": "1.2 subtle / 1.4 standard / 1.8+ large for accessibility",
						"increase": "Bigger UI.",
						"decrease": "Smaller."
					}
				},
				"details": {
					"what": "Scales the entire HUD on mobile so touch targets are big enough. Desktop and web stay at 1.0.",
					"where": "Attach to the main HUD CanvasLayer. All Control children scale together.",
					"before": "HUD Layout is anchored properly.",
					"after": "Combine with safe_area_ui for a HUD that fits within the safe zone.",
					"why_optimized": "Scale applied once per resize, not per frame.",
					"mistakes": "Scaling Controls that are already anchored with offsets double-scales them. Apply scale to a container, not to each Control.",
					"related": ["safe_area_ui", "responsive_ui_scale", "touch_buttons_ui"]
				}
			},
			"mobile_orientation_3d": {
				"phrases": ["mobile orientation", "screen orientation", "lock landscape", "force orientation"],
				"code": """extends Node

@export var lock_landscape: bool = true
@export var lock_on_mobile: bool = true
@export var lock_on_desktop: bool = false

func _ready() -> void:
	_apply_orientation()

func _apply_orientation() -> void:
	if OS.has_feature("web"):
		return
	var is_mobile := DisplayServer.is_touchscreen_available()
	if lock_on_mobile and is_mobile:
		var orientation := (
			DisplayServer.SCREEN_LANDSCAPE if lock_landscape
			else DisplayServer.SCREEN_PORTRAIT
		)
		DisplayServer.screen_set_orientation(orientation)
	elif lock_on_desktop:
		# On desktop, only window width/height is controllable
		pass

func set_landscape() -> void:
	lock_landscape = true
	_apply_orientation()

func set_portrait() -> void:
	lock_landscape = false
	_apply_orientation()

func set_auto_rotate() -> void:
	if OS.has_feature("web"):
		return
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR)
""",
				"params": ["lock_landscape", "lock_on_mobile", "lock_on_desktop"],
				"category": "platform",
				"subcategory": "3d",
				"platforms": ["mobile"],
				"dimension": "any",
				"difficulty": "beginner",
				"param_info": {
					"lock_landscape": {
						"default": true,
						"range": [],
						"what": "True for landscape, false for portrait.",
						"typical": "true for most games / false for puzzle or card games",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "Locks the device orientation on mobile. Does nothing on desktop or web (browsers don't allow it).",
					"where": "Add as an autoload or a node in the main scene. Called on _ready.",
					"before": "None.",
					"after": "For user-facing options, add a settings toggle for auto-rotate.",
					"why_optimized": "One API call. No per-frame work.",
					"mistakes": "Calling screen_set_orientation on desktop may log warnings. The platform check prevents this.",
					"related": ["platform_detect", "fullscreen_toggle", "mobile_ui_scale_3d"]
				}
			},
			"mobile_safe_ui_3d": {
				"phrases": ["mobile safe ui 3d", "3d safe area", "safe hud 3d", "notch 3d hud"],
				"code": """extends CanvasLayer

@export var margin: float = 20.0

func _ready() -> void:
	_apply_safe_area()
	get_tree().root.size_changed.connect(_apply_safe_area)

func _apply_safe_area() -> void:
	var safe := DisplayServer.get_display_safe_area()
	var window_size := DisplayServer.window_get_size()
	if window_size.x <= 0 or window_size.y <= 0:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var scale_factor := viewport_size / Vector2(window_size)
	var safe_position: Vector2 = Vector2(safe.position) * scale_factor
	var safe_size: Vector2 = Vector2(safe.size) * scale_factor
	for child in get_children():
		if child is Control:
			var control := child as Control
			control.position = safe_position + Vector2(margin, margin)
			control.size = safe_size - Vector2(margin * 2.0, margin * 2.0)

# USAGE
# Attach to the main HUD CanvasLayer. All Control children are inset
# to fit inside the display's safe area with a uniform margin.
#
# Safe area handling differs per platform:
#   iOS — Dynamic Island and home indicator affect the top and bottom
#   Android — punch-hole cameras and gesture bar affect the top and bottom
#   Web — usually no safe area unless the browser adds one
#
# For iOS specifically, use ios_safe_area_helper instead for
# Dynamic-Island-aware padding.
""",
				"params": ["margin"],
				"category": "platform",
				"subcategory": "3d",
				"platforms": ["mobile"],
				"dimension": "ui",
				"difficulty": "beginner",
				"param_info": {
					"margin": {
						"default": 20.0,
						"range": [0.0, 100.0],
						"what": "Extra padding inside the safe area.",
						"typical": "0 tight / 20 standard / 40+ cautious",
						"increase": "More padding.",
						"decrease": "Less."
					}
				},
				"details": {
					"what": "Insets HUD Controls inside the display's safe area for 3D games with lots of screen-real-estate HUD elements.",
					"where": "Attach to the HUD CanvasLayer. Children must be Controls.",
					"before": "None.",
					"after": "For fine control per side, apply safe area to containers instead of individual Controls.",
					"why_optimized": "Recomputed on resize only. No per-frame math.",
					"mistakes": "Applying safe area to a full-screen ColorRect causes visible black bars. Only apply to actual UI elements.",
					"related": ["safe_area_ui", "ios_safe_area_helper", "mobile_ui_scale_3d"]
				}
			}
		}
	}

@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"snippets": {
			"platform_detect": {
				"phrases": ["platform detect", "which platform", "desktop mobile web", "check platform"],
				"code": """func get_platform() -> String:
	if OS.has_feature("web"):
		return "web"
	if OS.has_feature("mobile") or OS.get_name() == "Android" or OS.get_name() == "iOS":
		return "mobile"
	return "desktop"

func is_mobile() -> bool:
	return get_platform() == "mobile"

func is_web() -> bool:
	return get_platform() == "web"

func is_desktop() -> bool:
	return get_platform() == "desktop"

func has_touch() -> bool:
	return DisplayServer.is_touchscreen_available()

func has_gamepad() -> bool:
	return not Input.get_connected_joypads().is_empty()

func apply_platform_defaults() -> void:
	match get_platform():
		"mobile":
			DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		"web":
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_:
			pass
""",
				"params": [],
				"category": "platform",
				"subcategory": "detect",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "any",
				"difficulty": "beginner",
				"details": {
					"what": "Detects which platform the game is running on: desktop, mobile, or web. Also reports touch and gamepad availability.",
					"where": "Add to a game manager or an autoload. Call once in _ready to configure platform defaults.",
					"before": "None.",
					"after": "Use is_mobile() to show on-screen buttons, is_desktop() to enable mouse features.",
					"why_optimized": "OS.has_feature is a cached boolean. No string comparisons on hot paths.",
					"mistakes": "Checking OS.get_name() alone misses the web platform on desktop browsers. Always check has_feature('web') first.",
					"related": ["input_abstraction", "safe_area_ui", "touch_camera"]
				}
			},
			"input_abstraction": {
				"phrases": ["input abstraction", "unified input", "read all inputs", "input cross platform"],
				"code": """extends Node

# Reads movement from keyboard, gamepad, and touch joystick.
# Registers the joystick by finding a node in group 'virtual_joystick'.

var _joystick: Node = null
var _is_mobile: bool = false

func _ready() -> void:
	_is_mobile = DisplayServer.is_touchscreen_available()
	if _is_mobile:
		call_deferred("_find_joystick")

func _find_joystick() -> void:
	var nodes := get_tree().get_nodes_in_group("virtual_joystick")
	if not nodes.is_empty():
		_joystick = nodes[0]

func get_movement() -> Vector2:
	if _joystick != null and _joystick.has_method("get_direction"):
		var touch_dir: Vector2 = _joystick.call("get_direction")
		if touch_dir.length() > 0.15:
			return touch_dir
	var kb := Input.get_vector("left", "right", "up", "down")
	if kb.length() > 0.15:
		return kb
	return Vector2.ZERO

func get_movement_8dir() -> Vector2:
	var raw := get_movement()
	if raw.length() < 0.15:
		return Vector2.ZERO
	var x: float = 0.0
	var y: float = 0.0
	if absf(raw.x) > 0.4:
		x = sign(raw.x)
	if absf(raw.y) > 0.4:
		y = sign(raw.y)
	return Vector2(x, y).normalized()

func is_action_pressed_any(action: String) -> bool:
	# Reads keyboard, gamepad, AND touch button for the same action.
	if Input.is_action_pressed(action):
		return true
	return false

func is_action_just_pressed_any(action: String) -> bool:
	return Input.is_action_just_pressed(action)
""",
				"params": [],
				"category": "platform",
				"subcategory": "input",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "any",
				"difficulty": "intermediate",
				"details": {
					"what": "One call for movement input that works across keyboard, gamepad, and touch joystick. Add the joystick node to group 'virtual_joystick' and it's picked up automatically.",
					"where": "Add to a game manager or autoload named 'InputManager'. Use get_movement() everywhere instead of Input.get_vector.",
					"before": "Input actions left, right, up, down in Input Map. Bind keyboard, gamepad, and touch.",
					"after": "If you already use Input.get_vector in your player scripts, replace those calls with InputManager.get_movement().",
					"why_optimized": "Finds the joystick once, caches the reference. Only falls back to Input.get_vector if the touch joystick is idle.",
					"mistakes": "Adding multiple virtual joysticks means only the first one found in the group is used. Use only one per scene.",
					"related": ["platform_detect", "virtual_joystick", "touch_button"]
				}
			},
			"safe_area_ui": {
				"phrases": ["safe area", "notch safe area", "screen inset", "mobile safe area"],
				"code": """extends Control

# Adjusts this Control's position and size to fit inside the display's
# safe area — avoiding notches, rounded corners, and status bars.

@export var margin: float = 0.0
@export var apply_on_ready: bool = true

func _ready() -> void:
	if apply_on_ready:
		apply_safe_area()
	get_tree().root.size_changed.connect(_on_viewport_resized)

func _on_viewport_resized() -> void:
	apply_safe_area()

func apply_safe_area() -> void:
	var safe := DisplayServer.get_display_safe_area()
	var window_size := DisplayServer.window_get_size()
	if window_size.x <= 0 or window_size.y <= 0:
		return
	var scale_factor: Vector2 = Vector2(get_viewport_rect().size) / Vector2(window_size)
	var safe_position: Vector2 = Vector2(safe.position) * scale_factor
	var safe_size: Vector2 = Vector2(safe.size) * scale_factor
	position = safe_position + Vector2(margin, margin)
	size = safe_size - Vector2(margin * 2.0, margin * 2.0)

func get_safe_rect() -> Rect2:
	var safe := DisplayServer.get_display_safe_area()
	return Rect2(Vector2(safe.position), Vector2(safe.size))
""",
				"params": ["margin", "apply_on_ready"],
				"category": "platform",
				"subcategory": "ui",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "ui",
				"difficulty": "intermediate",
				"param_info": {
					"margin": {
						"default": 0.0,
						"range": [0.0, 100.0],
						"what": "Extra padding inside the safe area, in pixels.",
						"typical": "0 tight / 16 comfortable / 40+ very cautious",
						"increase": "More padding.",
						"decrease": "Less."
					}
				},
				"details": {
					"what": "Resizes a Control to fit inside the display's safe area. On phones with notches or rounded corners, this prevents UI from being cut off.",
					"where": "Attach to the root Control of your HUD or any full-screen UI. Common parent for menus.",
					"before": "None.",
					"after": "Put all HUD children inside this Control. They'll inherit the safe area automatically.",
					"why_optimized": "Only recalculates on viewport resize, not every frame. Safe area is cached by DisplayServer.",
					"mistakes": "Applying safe area to a full-screen ColorRect that should extend under the notch makes ugly bars. Only apply to UI you want visible.",
					"related": ["platform_detect", "mobile_ui_layout", "health_bar_ui"]
				}
			},
			"fullscreen_toggle": {
				"phrases": ["fullscreen toggle", "fullscreen button", "window mode", "borderless"],
				"code": """extends Node

signal fullscreen_changed(is_fullscreen: bool)

func toggle_fullscreen() -> void:
	var current := DisplayServer.window_get_mode()
	var is_fs := current == DisplayServer.WINDOW_MODE_FULLSCREEN or current == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	if is_fs:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		fullscreen_changed.emit(false)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		fullscreen_changed.emit(true)

func is_fullscreen() -> bool:
	var current := DisplayServer.window_get_mode()
	return current == DisplayServer.WINDOW_MODE_FULLSCREEN or current == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN

func apply_saved_fullscreen(saved: bool) -> void:
	if saved:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func lock_mobile_orientation(landscape: bool = true) -> void:
	if not DisplayServer.is_touchscreen_available():
		return
	var mode := DisplayServer.SCREEN_LANDSCAPE if landscape else DisplayServer.SCREEN_PORTRAIT
	DisplayServer.screen_set_orientation(mode)
""",
				"params": [],
				"category": "platform",
				"subcategory": "display",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "any",
				"difficulty": "beginner",
				"details": {
					"what": "Toggles fullscreen and locks mobile orientation. Save the state in your settings file for next launch.",
					"where": "Add to a settings menu script or an autoload named 'Display'.",
					"before": "None.",
					"after": "On web, fullscreen must be triggered by a user gesture (a button click), not on page load.",
					"why_optimized": "Single DisplayServer call. No polling.",
					"mistakes": "Calling toggle_fullscreen() on web without a user gesture is blocked by browsers. Only trigger from a button.",
					"related": ["platform_detect", "settings_save", "options_menu"]
				}
			},
			"web_audio_unlock": {
				"phrases": ["web audio", "audio unlock", "html5 audio", "browser audio"],
				"code": """extends CanvasLayer

# Web browsers block audio until the user interacts with the page.
# This shows a splash screen with a "Click to start" button that
# starts the game only after the user has clicked.

@onready var _button: Button = $Panel/StartButton

@export var next_scene: PackedScene

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not OS.has_feature("web"):
		# Not on web — skip this screen entirely
		call_deferred("_skip")
		return
	_button.pressed.connect(_on_start_pressed)
	get_tree().paused = true

func _skip() -> void:
	get_tree().paused = false
	queue_free()

func _on_start_pressed() -> void:
	# Resume AudioServer — this is the unlock point
	AudioServer.set_bus_mute(0, false)
	get_tree().paused = false
	if next_scene != null:
		get_tree().change_scene_to_packed(next_scene)
	else:
		queue_free()
""",
				"params": ["next_scene"],
				"category": "platform",
				"subcategory": "web",
				"platforms": ["web"],
				"dimension": "ui",
				"difficulty": "intermediate",
				"param_info": {
					"next_scene": {
						"default": "",
						"range": [],
						"what": "Optional scene to load after the user clicks. Leave empty to just resume the current scene.",
						"typical": "main menu scene or empty",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "Splash screen that unlocks browser audio. Web games can't play audio until the user clicks or taps. This automates that gate.",
					"where": "Set as the main scene in Project Settings. Automatically skips itself on desktop and mobile.",
					"before": "A CanvasLayer with a Panel and StartButton child.",
					"after": "Once unlocked, audio plays normally through the rest of the session.",
					"why_optimized": "Only on web. Desktop and mobile skip the entire flow with one feature check.",
					"mistakes": "Trying to play music before the click silently fails. The gate prevents that confusion.",
					"related": ["platform_detect", "main_menu", "play_music"]
				}
			},
			"responsive_ui_scale": {
				"phrases": ["responsive ui", "ui scale", "screen size ui", "adapt ui"],
				"code": """extends Control

@export var design_width: float = 1280.0
@export var design_height: float = 720.0
@export var min_scale: float = 0.5
@export var max_scale: float = 3.0

func _ready() -> void:
	var project_setting := ProjectSettings.get_setting("display/window/stretch/mode", "canvas_items")
	if project_setting != "canvas_items" and project_setting != "viewport":
		push_warning("Responsive UI works best with Stretch Mode set to canvas_items.")
	get_tree().root.size_changed.connect(_on_resize)
	_on_resize()

func _on_resize() -> void:
	var viewport_size := get_viewport_rect().size
	var scale_x := viewport_size.x / design_width
	var scale_y := viewport_size.y / design_height
	var factor: float = clamp(min(scale_x, scale_y), min_scale, max_scale)
	scale = Vector2(factor, factor)

func get_scale_factor() -> float:
	return scale.x
""",
				"params": ["design_width", "design_height", "min_scale", "max_scale"],
				"category": "platform",
				"subcategory": "ui",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "ui",
				"difficulty": "intermediate",
				"param_info": {
					"design_width": {
						"default": 1280.0,
						"range": [640.0, 3840.0],
						"what": "Reference width the UI was designed at.",
						"typical": "1280 for 720p / 1920 for 1080p",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"min_scale": {
						"default": 0.5,
						"range": [0.25, 1.0],
						"what": "Never scale below this on small screens.",
						"typical": "0.5 phone / 0.75 tablet",
						"increase": "UI stays larger on small screens.",
						"decrease": "Allows smaller UI."
					},
					"max_scale": {
						"default": 3.0,
						"range": [1.0, 6.0],
						"what": "Never scale above this on large screens.",
						"typical": "2.0 monitor / 4.0 4K TV",
						"increase": "Larger UI on big screens.",
						"decrease": "Caps the scale."
					}
				},
				"details": {
					"what": "Scales a UI Control to fit any screen size while keeping proportions. Handles the desktop-to-mobile-to-web width range.",
					"where": "Attach to the root Control of your HUD or menu. Children scale automatically.",
					"before": "Project Settings → Display → Window → Stretch Mode set to canvas_items (default).",
					"after": "Set design_width/height to whatever resolution you designed at. The rest is automatic.",
					"why_optimized": "Recomputes only on viewport resize. Single min() call per resize.",
					"mistakes": "Scaling a Control that already uses anchors and containers can produce double-scaling. Use one or the other.",
					"related": ["safe_area_ui", "platform_detect", "health_bar_ui"]
				}
			}
		}
	}

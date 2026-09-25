@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"snippets": {
			"virtual_joystick": {
				"phrases": ["virtual joystick", "touch joystick", "mobile joystick", "on screen joystick"],
				"code": """extends Control

signal joystick_input(direction: Vector2)
signal joystick_released

@export var dead_zone: float = 0.15
@export var max_distance: float = 80.0

@onready var _base: Control = $Base
@onready var _knob: Control = $Base/Knob

var _touch_index: int = -1
var _center: Vector2 = Vector2.ZERO
var _output: Vector2 = Vector2.ZERO

func _ready() -> void:
	_center = _base.global_position + _base.size * 0.5
	visible = false

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index < 0 and _is_touch_in_area(event.position):
			_touch_index = event.index
			_center = event.position
			_base.global_position = event.position - _base.size * 0.5
			visible = true
		elif not event.pressed and event.index == _touch_index:
			_release()
	elif event is InputEventScreenDrag:
		if event.index == _touch_index:
			_update_knob(event.position)

func _is_touch_in_area(position: Vector2) -> bool:
	return position.x < get_viewport().get_visible_rect().size.x * 0.5

func _update_knob(position: Vector2) -> void:
	var offset := position - _center
	if offset.length() > max_distance:
		offset = offset.normalized() * max_distance
	_knob.position = _base.size * 0.5 + offset - _knob.size * 0.5
	var normalized := offset / max_distance
	if normalized.length() < dead_zone:
		_output = Vector2.ZERO
	else:
		_output = normalized
	joystick_input.emit(_output)

func _release() -> void:
	_touch_index = -1
	_output = Vector2.ZERO
	_knob.position = _base.size * 0.5 - _knob.size * 0.5
	visible = false
	joystick_released.emit()

func get_direction() -> Vector2:
	return _output

func get_direction_8() -> Vector2:
	if _output.length() < dead_zone:
		return Vector2.ZERO
	return Vector2(
		sign(_output.x) if absf(_output.x) > 0.4 else 0.0,
		sign(_output.y) if absf(_output.y) > 0.4 else 0.0
	).normalized()
""",
				"params": ["dead_zone", "max_distance"],
				"category": "touch",
				"subcategory": "joystick",
				"dimension": "ui",
				"difficulty": "intermediate",
				"param_info": {
					"dead_zone": {
						"default": 0.15,
						"range": [0.0, 0.5],
						"what": "Normalized distance before the joystick registers input.",
						"typical": "0.1 sensitive / 0.15 standard / 0.3 deliberate",
						"increase": "Requires more movement to start.",
						"decrease": "More sensitive."
					},
					"max_distance": {
						"default": 80.0,
						"range": [30.0, 200.0],
						"what": "Maximum knob travel distance in pixels.",
						"typical": "60 small / 80 standard / 120 large",
						"increase": "Bigger range.",
						"decrease": "Smaller."
					}
				},
				"details": {
					"what": "On-screen joystick that appears wherever the player touches the left half of the screen. Returns a normalized Vector2 direction.",
					"where": "Attach to a Control node in a CanvasLayer. Add a Base Control (circle background) and a Knob Control (inner circle) as children.",
					"before": "Base and Knob are Control nodes with textures or rounded panels. The Control node should cover the screen (or the left half for a split layout).",
					"after": "Connect joystick_input to your player and pass the direction into the movement code.",
					"why_optimized": "Tracks a single touch by index. Emits only on drag events, not per frame.",
					"mistakes": "Using position instead of global_position means the joystick offsets wrong on nested UIs. Always work in global coordinates.",
					"related": ["touch_button", "virtual_joystick_2", "mobile_ui_layout"]
				}
			},
			"touch_button": {
				"phrases": ["touch button", "on screen button", "mobile button", "tap button"],
				"code": """extends Control

signal pressed
signal released

@export var action_name: String = "jump"
@export var button_label: String = "A"

@onready var _label: Label = $Label
@onready var _background: Panel = $Background

var _touch_index: int = -1
var _is_pressed: bool = false
var _original_color: Color = Color.WHITE

func _ready() -> void:
	if _label != null:
		_label.text = button_label
	if _background != null:
		_original_color = _background.modulate

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index < 0 and _is_inside(event.position):
			_touch_index = event.index
			_set_pressed(true)
		elif not event.pressed and event.index == _touch_index:
			_set_pressed(false)
			_touch_index = -1
	elif event is InputEventScreenDrag:
		if event.index == _touch_index:
			var inside := _is_inside(event.position)
			if inside != _is_pressed:
				_set_pressed(inside)

func _is_inside(position: Vector2) -> bool:
	var rect := Rect2(global_position, size)
	return rect.has_point(position)

func _set_pressed(value: bool) -> void:
	_is_pressed = value
	if _background != null:
		_background.modulate = Color(0.7, 0.7, 0.7) if value else _original_color
	if value:
		pressed.emit()
		if not action_name.is_empty():
			Input.action_press(action_name)
	else:
		released.emit()
		if not action_name.is_empty():
			Input.action_release(action_name)

func is_pressed() -> bool:
	return _is_pressed
""",
				"params": ["action_name", "button_label"],
				"category": "touch",
				"subcategory": "button",
				"dimension": "ui",
				"difficulty": "beginner",
				"param_info": {
					"action_name": {
						"default": "jump",
						"range": [],
						"what": "Input action to trigger when pressed. Leave empty to use signals only.",
						"typical": "jump / attack / interact / dash",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"button_label": {
						"default": "A",
						"range": [],
						"what": "Text label shown on the button.",
						"typical": "A / B / Jump / Attack / Action icon",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "Touch button that calls Input.action_press/release so existing keyboard input code works unchanged.",
					"where": "Attach to a Control with a Background Panel and a Label child. Position it in a CanvasLayer.",
					"before": "Create the input action in Input Map (jump, attack, etc.). Set the action_name in the Inspector.",
					"after": "Connect the pressed signal for extra effects (button flash, sound).",
					"why_optimized": "Uses Input.action_press — no custom input polling. Existing player code doesn't change.",
					"mistakes": "Forgetting to release the action on touch end leaves the input 'stuck' held forever.",
					"related": ["virtual_joystick", "touch_swipe", "mobile_ui_layout"]
				}
			},
			"touch_swipe": {
				"phrases": ["swipe detection", "touch swipe", "swipe gesture", "flick input"],
				"code": """extends Node

signal swipe(direction: Vector2, distance: float, duration: float)

@export var min_swipe_distance: float = 60.0
@export var max_swipe_time: float = 0.5

var _start_position: Vector2 = Vector2.ZERO
var _start_time: float = 0.0
var _tracking: bool = false
var _touch_index: int = -1

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and not _tracking:
			_start_position = event.position
			_start_time = Time.get_ticks_msec() / 1000.0
			_tracking = true
			_touch_index = event.index
		elif not event.pressed and event.index == _touch_index:
			_tracking = false
			_touch_index = -1
	elif event is InputEventScreenDrag:
		if not _tracking or event.index != _touch_index:
			return
		var current_time := Time.get_ticks_msec() / 1000.0
		var elapsed := current_time - _start_time
		if elapsed > max_swipe_time:
			_tracking = false
			return
		var offset := event.position - _start_position
		if offset.length() < min_swipe_distance:
			return
		var direction := offset.normalized()
		swipe.emit(direction, offset.length(), elapsed)
		_tracking = false

func swipe_to_direction(direction: Vector2) -> String:
	var angle := direction.angle()
	var degrees := rad_to_deg(angle)
	if degrees >= -45.0 and degrees < 45.0:
		return "right"
	elif degrees >= 45.0 and degrees < 135.0:
		return "down"
	elif degrees >= -135.0 and degrees < -45.0:
		return "up"
	return "left"
""",
				"params": ["min_swipe_distance", "max_swipe_time"],
				"category": "touch",
				"subcategory": "gesture",
				"dimension": "ui",
				"difficulty": "intermediate",
				"param_info": {
					"min_swipe_distance": {
						"default": 60.0,
						"range": [20.0, 300.0],
						"what": "Minimum finger travel distance to count as a swipe.",
						"typical": "40 short / 60 standard / 120+ deliberate",
						"increase": "Requires longer swipe.",
						"decrease": "Shorter swipes work."
					},
					"max_swipe_time": {
						"default": 0.5,
						"range": [0.1, 2.0],
						"what": "Maximum time for a swipe. Longer becomes a drag.",
						"typical": "0.3 fast flick / 0.5 standard / 1.0 slow swipe",
						"increase": "Slower swipes count.",
						"decrease": "Faster flicks only."
					}
				},
				"details": {
					"what": "Detects swipe gestures and emits direction, distance, and time. Includes a helper to classify the swipe into up/down/left/right.",
					"where": "Attach to a Node in an autoload or in your scene root.",
					"before": "None.",
					"after": "Connect the swipe signal to trigger attacks, dash directions, or menu navigation.",
					"why_optimized": "Only tracks one touch at a time. Emits once per swipe and stops tracking.",
					"mistakes": "Not capping the swipe time means a long drag counts as a swipe. The max_swipe_time check prevents this.",
					"related": ["virtual_joystick", "touch_tap", "touch_button"]
				}
			},
			"touch_tap": {
				"phrases": ["tap detection", "touch tap", "single tap", "double tap"],
				"code": """extends Node

signal tap(position: Vector2)
signal double_tap(position: Vector2)
signal long_press(position: Vector2)

@export var double_tap_window: float = 0.3
@export var long_press_duration: float = 0.6
@export var max_move_distance: float = 20.0

var _first_tap_time: float = 0.0
var _first_tap_position: Vector2 = Vector2.ZERO
var _waiting_second_tap: bool = false
var _press_start_time: float = 0.0
var _press_position: Vector2 = Vector2.ZERO
var _pressing: bool = false
var _long_press_fired: bool = false
var _touch_index: int = -1

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_on_press(event.position, event.index)
		else:
			_on_release(event.position, event.index)
	elif event is InputEventScreenDrag:
		if event.index != _touch_index:
			return
		if _press_position.distance_to(event.position) > max_move_distance:
			_pressing = false

func _on_press(position: Vector2, index: int) -> void:
	_pressing = true
	_long_press_fired = false
	_press_start_time = Time.get_ticks_msec() / 1000.0
	_press_position = position
	_touch_index = index

func _on_release(position: Vector2, index: int) -> void:
	if not _pressing or index != _touch_index:
		return
	_pressing = false
	_touch_index = -1
	if _long_press_fired:
		return
	if position.distance_to(_press_position) > max_move_distance:
		return
	var now := Time.get_ticks_msec() / 1000.0
	if _waiting_second_tap and now - _first_tap_time < double_tap_window:
		_waiting_second_tap = false
		double_tap.emit(position)
		return
	_first_tap_time = now
	_first_tap_position = position
	_waiting_second_tap = true
	await get_tree().create_timer(double_tap_window).timeout
	if _waiting_second_tap:
		_waiting_second_tap = false
		tap.emit(_first_tap_position)

func _process(_delta: float) -> void:
	if not _pressing or _long_press_fired:
		return
	var elapsed := Time.get_ticks_msec() / 1000.0 - _press_start_time
	if elapsed >= long_press_duration:
		_long_press_fired = true
		long_press.emit(_press_position)
""",
				"params": ["double_tap_window", "long_press_duration", "max_move_distance"],
				"category": "touch",
				"subcategory": "gesture",
				"dimension": "ui",
				"difficulty": "advanced",
				"param_info": {
					"double_tap_window": {
						"default": 0.3,
						"range": [0.15, 0.5],
						"what": "Maximum time between two taps to count as a double tap.",
						"typical": "0.25 tight / 0.3 standard / 0.4 forgiving",
						"increase": "Easier to double-tap.",
						"decrease": "Harder."
					},
					"long_press_duration": {
						"default": 0.6,
						"range": [0.3, 2.0],
						"what": "Seconds held before a long_press fires.",
						"typical": "0.4 quick / 0.6 standard / 1.0+ deliberate",
						"increase": "Longer hold required.",
						"decrease": "Shorter."
					},
					"max_move_distance": {
						"default": 20.0,
						"range": [5.0, 100.0],
						"what": "Max finger movement before a press is canceled.",
						"typical": "15 strict / 20 standard / 40 forgiving",
						"increase": "Finger can wander more.",
						"decrease": "Must stay still."
					}
				},
				"details": {
					"what": "Detects tap, double tap, and long press gestures. Includes tap delay so single and double taps don't both fire.",
					"where": "Attach to a Node in an autoload or scene root.",
					"before": "None.",
					"after": "Use tap for attack, double_tap for special abilities, long_press for information popups.",
					"why_optimized": "Single state machine. Uses Time.get_ticks_msec instead of frame counting.",
					"mistakes": "Not delaying single tap until double_tap_window passes means every double tap also fires two single taps.",
					"related": ["touch_swipe", "touch_button", "virtual_joystick"]
				}
			},
			"multi_touch_tracker": {
				"phrases": ["multi touch", "multi touch tracker", "multiple touches", "touch count"],
				"code": """extends Node

signal touch_count_changed(count: int)
signal touch_added(index: int, position: Vector2)
signal touch_removed(index: int, position: Vector2)

var active_touches: Dictionary = {}

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			active_touches[event.index] = event.position
			touch_added.emit(event.index, event.position)
			touch_count_changed.emit(active_touches.size())
		else:
			active_touches.erase(event.index)
			touch_removed.emit(event.index, event.position)
			touch_count_changed.emit(active_touches.size())
	elif event is InputEventScreenDrag:
		if active_touches.has(event.index):
			active_touches[event.index] = event.position

func get_touch_count() -> int:
	return active_touches.size()

func get_touch_position(index: int) -> Vector2:
	return active_touches.get(index, Vector2.ZERO)

func get_touch_indices() -> Array:
	return active_touches.keys()

func is_touching() -> bool:
	return not active_touches.is_empty()
""",
				"params": [],
				"category": "touch",
				"subcategory": "tracking",
				"dimension": "ui",
				"difficulty": "beginner",
				"details": {
					"what": "Central tracker for all active touches on screen. Emits signals when touches start, end, or their count changes.",
					"where": "Add as an autoload named 'MultiTouch'.",
					"before": "None.",
					"after": "Query MultiTouch.get_touch_count() to detect two-finger gestures, or MultiTouch.get_touch_position(index) for a specific finger.",
					"why_optimized": "Single dictionary tracks all touches. O(1) lookup by index.",
					"mistakes": "Not clearing touches when the app loses focus leaves stale touches in the dictionary. Add a focus_lost handler that clears it.",
					"related": ["virtual_joystick", "touch_swipe", "touch_tap"]
				}
			}
		}
	}

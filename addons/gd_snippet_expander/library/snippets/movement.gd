@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"snippets": {
			"character_movement_2d": {
				"phrases": ["2d movement", "move 2d", "characterbody2d movement", "walk 2d"],
				"code": """extends CharacterBody2D

@export var speed: float = 200.0

func _physics_process(_delta: float) -> void:
	var input_dir := Input.get_vector("left", "right", "up", "down")
	velocity = input_dir * speed
	move_and_slide()
""",
				"params": ["speed"],
				"category": "movement",
				"dimension": "2d",
				"difficulty": "beginner",
				"required_actions": ["left", "right", "up", "down"],
				"param_info": {
					"speed": {
						"default": 200.0,
						"range": [50.0, 500.0],
						"what": "Movement speed in pixels per second.",
						"typical": "100 slow / 200 normal / 350 fast / 500+ speedrun",
						"increase": "Above 400 feels twitchy on small screens.",
						"decrease": "Below 100 feels sluggish."
					}
				},
				"details": {
					"what": "A CharacterBody2D with 8-directional movement (top-down).",
					"where": "Attach to a CharacterBody2D. Add a CollisionShape2D child.",
					"before": "Create input actions left, right, up, down in Input Map.",
					"after": "For top-down sprite rotation, add 'topdown movement' instead.",
					"why_optimized": "get_vector returns normalized input with dead zone; no per-frame allocations.",
					"mistakes": "Using platformer_movement_2d for a top-down game — the gravity handling is wrong for that layout.",
					"related": ["topdown_movement_2d", "platformer_movement_2d", "camera_follow_2d"]
				}
			},
			"topdown_movement_2d": {
				"phrases": ["topdown movement", "top down movement", "top-down 2d", "top down 2d"],
				"code": """extends CharacterBody2D

@export var speed: float = 200.0

func _physics_process(_delta: float) -> void:
	var input_dir := Input.get_vector("left", "right", "up", "down")
	velocity = input_dir * speed
	move_and_slide()
	if input_dir.length() > 0.0:
		rotation = input_dir.angle()
""",
				"params": ["speed"],
				"category": "movement",
				"dimension": "2d",
				"difficulty": "beginner",
				"required_actions": ["left", "right", "up", "down"],
				"param_info": {
					"speed": {
						"default": 200.0,
						"range": [50.0, 500.0],
						"what": "Movement speed in pixels per second.",
						"typical": "120 character / 200 normal / 350 vehicle",
						"increase": "Above 400 rotation looks jittery.",
						"decrease": "Below 100 feels slow for a shooter."
					}
				},
				"details": {
					"what": "CharacterBody2D that moves and rotates toward the movement direction.",
					"where": "Attach to a CharacterBody2D. Add a CollisionShape2D child.",
					"before": "Create input actions left, right, up, down in Input Map.",
					"after": "For sprite-based characters that shouldn't rotate, use character_movement_2d instead.",
					"why_optimized": "rotation only updates when input_dir is non-zero, avoiding jitter at rest.",
					"mistakes": "Forgetting the input_dir.length() check makes the sprite snap to angle 0 (right) when idle.",
					"related": ["character_movement_2d", "camera_follow_2d", "chase player"]
				}
			},
			"dash_2d": {
				"phrases": ["dash", "dash 2d", "dash ability"],
				"code": """@export var dash_speed: float = 600.0
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 0.6

var _dashing: bool = false
var _can_dash: bool = true
var _dash_dir: Vector2 = Vector2.RIGHT

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("dash") and _can_dash:
		_dash_dir = Vector2.RIGHT if velocity.x >= 0.0 else Vector2.LEFT
		_start_dash()

func _start_dash() -> void:
	_dashing = true
	_can_dash = false
	await get_tree().create_timer(dash_duration).timeout
	_dashing = false
	await get_tree().create_timer(dash_cooldown).timeout
	_can_dash = true
""",
				"params": ["dash_speed", "dash_duration", "dash_cooldown"],
				"category": "movement",
				"dimension": "2d",
				"difficulty": "intermediate",
				"required_actions": ["dash"],
				"param_info": {
					"dash_speed": {
						"default": 600.0,
						"range": [200.0, 2000.0],
						"what": "Velocity applied during the dash, in pixels per second.",
						"typical": "400 short hop / 600 punchy / 1200+ teleport-feel",
						"increase": "Goes further during the same duration.",
						"decrease": "Shorter reach, safer but less satisfying."
					},
					"dash_duration": {
						"default": 0.2,
						"range": [0.05, 0.5],
						"what": "How long the dash lasts, in seconds.",
						"typical": "0.1 blink / 0.2 standard / 0.35 heavy",
						"increase": "Longer dash, more distance, less punchy.",
						"decrease": "Snappier, less distance."
					},
					"dash_cooldown": {
						"default": 0.6,
						"range": [0.1, 3.0],
						"what": "Seconds between dash uses.",
						"typical": "0.3 spam-friendly / 0.6 balanced / 1.5 careful",
						"increase": "Makes dash a resource, not a spam.",
						"decrease": "Below 0.3 lets the player chain dashes."
					}
				},
				"details": {
					"what": "Adds a directional dash triggered by the 'dash' action.",
					"where": "Combine with character_movement_2d or platformer_movement_2d. Not standalone.",
					"before": "Create input action 'dash' in Input Map (usually Shift).",
					"after": "To make the dash apply speed to velocity, set velocity = _dash_dir * dash_speed inside _start_dash().",
					"why_optimized": "Uses await instead of polling a Timer node, so no extra scene-tree nodes.",
					"mistakes": "Forgetting _can_dash check lets the player spam dash infinitely.",
					"related": ["character_movement_2d", "sprint", "coyote_time_2d"]
				}
			},
			"sprint": {
				"phrases": ["sprint", "run", "sprint toggle"],
				"code": """@export var walk_speed: float = 200.0
@export var sprint_speed: float = 350.0

var _current_speed: float = walk_speed

func _process(_delta: float) -> void:
	_current_speed = sprint_speed if Input.is_action_pressed("sprint") else walk_speed
""",
				"params": ["walk_speed", "sprint_speed"],
				"category": "movement",
				"dimension": "2d",
				"difficulty": "beginner",
				"required_actions": ["sprint"],
				"param_info": {
					"walk_speed": {
						"default": 200.0,
						"range": [50.0, 400.0],
						"what": "Speed while not sprinting.",
						"typical": "150 calm / 200 standard / 280 fast base",
						"increase": "Faster walk, less need to sprint.",
						"decrease": "Sprint feels more impactful."
					},
					"sprint_speed": {
						"default": 350.0,
						"range": [150.0, 800.0],
						"what": "Speed while holding the sprint action.",
						"typical": "1.5x walk normal / 2x arcade / 3x+ racing",
						"increase": "Higher contrast with walk speed.",
						"decrease": "Below 1.2x walk feels pointless."
					}
				},
				"details": {
					"what": "A speed modifier that reads the 'sprint' action each frame.",
					"where": "Pair with a movement snippet — this only sets a variable, it doesn't move the character.",
					"before": "Create input action 'sprint' in Input Map (usually Shift).",
					"after": "Replace 'speed' in your movement code with '_current_speed'.",
					"why_optimized": "Reads input in _process, not _physics_process — input polling is a per-frame concept.",
					"mistakes": "Assuming sprint works alone — it needs a movement snippet to actually move anything.",
					"related": ["character_movement_2d", "character_movement_3d", "dash_2d"]
				}
			},
			"crouch_2d": {
				"phrases": ["crouch", "crouch 2d", "duck"],
				"code": """@export var crouch_speed: float = 100.0

var _crouching: bool = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("crouch"):
		_crouching = true
	elif event.is_action_released("crouch"):
		_crouching = false
""",
				"params": ["crouch_speed"],
				"category": "movement",
				"dimension": "2d",
				"difficulty": "beginner",
				"required_actions": ["crouch"],
				"param_info": {
					"crouch_speed": {
						"default": 100.0,
						"range": [30.0, 200.0],
						"what": "Movement speed while crouching.",
						"typical": "60 stealth / 100 standard / 150 quick duck",
						"increase": "Crouch becomes less of a penalty.",
						"decrease": "Stealth sections feel more deliberate."
					}
				},
				"details": {
					"what": "Tracks whether the crouch action is held.",
					"where": "Pair with a movement snippet — you swap speed when _crouching is true.",
					"before": "Create input action 'crouch' in Input Map (usually Ctrl or C).",
					"after": "For stealth mechanics, also scale the collision shape and sprite.",
					"why_optimized": "Uses event.is_action_released instead of polling, so no per-frame check.",
					"mistakes": "Forgetting to actually change anything when crouching — this only tracks state.",
					"related": ["character_movement_2d", "sprint", "platformer_movement_2d"]
				}
			},
			"double_jump": {
				"phrases": ["double jump", "doublejump", "air jump"],
				"code": """@export var jump_velocity: float = -400.0
@export var max_jumps: int = 2

var _jumps_left: int = max_jumps

func _physics_process(_delta: float) -> void:
	if is_on_floor():
		_jumps_left = max_jumps
	if Input.is_action_just_pressed("jump") and _jumps_left > 0:
		velocity.y = jump_velocity
		_jumps_left -= 1
""",
				"params": ["jump_velocity", "max_jumps"],
				"category": "movement",
				"dimension": "2d",
				"difficulty": "beginner",
				"required_actions": ["jump"],
				"param_info": {
					"jump_velocity": {
						"default": -400.0,
						"range": [-800.0, -100.0],
						"what": "Upward impulse for each jump.",
						"typical": "-400 normal / -550 snappy double-jump games",
						"increase": "Higher jump. Negatives go up in 2D.",
						"decrease": "Smaller hop."
					},
					"max_jumps": {
						"default": 2,
						"range": [1, 5],
						"what": "Total jumps available before touching the ground.",
						"typical": "2 double-jump / 3 triple / 5 very forgiving",
						"increase": "More air mobility, harder to design levels around.",
						"decrease": "1 disables double-jump entirely."
					}
				},
				"details": {
					"what": "Extends normal jumping to allow N jumps per airtime.",
					"where": "Use instead of platformer_movement_2d's jump logic, not alongside it.",
					"before": "Create input action 'jump' in Input Map.",
					"after": "For gliding, check if _jumps_left == 0 and the player is falling.",
					"why_optimized": "Uses is_action_just_pressed to prevent the same press from counting twice.",
					"mistakes": "Using is_action_pressed instead lets one held button drain all jumps at once.",
					"related": ["platformer_movement_2d", "wall_jump_2d", "coyote_time_2d"]
				}
			},
			"wall_jump_2d": {
				"phrases": ["wall jump", "walljump", "wall slide jump"],
				"code": """@export var wall_jump_velocity: Vector2 = Vector2(300.0, -400.0)

func _physics_process(_delta: float) -> void:
	if is_on_wall_only() and Input.is_action_just_pressed("jump"):
		var wall_normal := get_wall_normal()
		velocity.x = wall_normal.x * wall_jump_velocity.x
		velocity.y = wall_jump_velocity.y
""",
				"params": ["wall_jump_velocity"],
				"category": "movement",
				"dimension": "2d",
				"difficulty": "intermediate",
				"required_actions": ["jump"],
				"param_info": {
					"wall_jump_velocity": {
						"default": [300.0, -400.0],
						"range": [[100, -200], [600, -800]],
						"what": "Vector2(X horizontal push, Y vertical push). Both magnitudes.",
						"typical": "[300, -400] standard / [500, -550] bouncy / [150, -350] tight",
						"increase": "X pushes further from wall. Y goes higher (more negative).",
						"decrease": "Smaller hop, less distance."
					}
				},
				"details": {
					"what": "Lets the player push off a wall while airborne.",
					"where": "Combine with platformer_movement_2d. Needs wall collision layers set up.",
					"before": "Create input action 'jump'. Make sure the player's collision shape can detect walls.",
					"after": "Add wall slide (velocity.y clamped while on wall) to make it feel deliberate.",
					"why_optimized": "get_wall_normal() respects the surface — works on slopes too.",
					"mistakes": "Using is_on_wall() instead of is_on_wall_only() triggers on ceilings and floors in some setups.",
					"related": ["platformer_movement_2d", "double_jump", "coyote_time_2d"]
				}
			},
			"mouse_look_3d": {
				"phrases": ["mouse look 3d", "mouse look", "fps look", "look with mouse"],
				"code": """@export var mouse_sensitivity: float = 0.003

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		var cam := $Camera3D as Camera3D
		cam.rotation.x = clamp(cam.rotation.x - event.relative.y * mouse_sensitivity, -1.5, 1.5)
""",
				"params": ["mouse_sensitivity"],
				"category": "camera",
				"dimension": "3d",
				"difficulty": "beginner",
				"param_info": {
					"mouse_sensitivity": {
						"default": 0.003,
						"range": [0.0005, 0.02],
						"what": "Multiplier applied to raw mouse movement. Lower = slower look.",
						"typical": "0.0015 slow / 0.003 standard / 0.006 fast",
						"increase": "Camera turns faster. Above 0.01 is unplayable.",
						"decrease": "Slower aim, more precise for long-range."
					}
				},
				"details": {
					"what": "Yaw on the parent, pitch on the Camera3D child. Standard FPS look.",
					"where": "Attach to the player (CharacterBody3D). Add a Camera3D child.",
					"before": "Set Input.mouse_mode = MOUSE_MODE_CAPTURED in _ready().",
					"after": "Add 'first person movement' for WASD.",
					"why_optimized": "Pitch is clamped so the camera can't flip over — a bug most tutorials skip.",
					"mistakes": "Rotating the whole player on both axes makes movement weird. Yaw on parent, pitch on camera.",
					"related": ["first_person_movement", "first_person_camera_3d", "orbit_camera_3d"]
				}
			},
			"first_person_movement": {
				"phrases": ["first person movement", "fps movement", "first person controller"],
				"code": """extends CharacterBody3D

@export var speed: float = 5.0
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.003

@onready var _camera: Camera3D = $Camera3D

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		_camera.rotation.x = clamp(_camera.rotation.x - event.relative.y * mouse_sensitivity, -1.5, 1.5)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
	var input_dir := Input.get_vector("left", "right", "forward", "back")
	var dir := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	move_and_slide()
""",
				"params": ["speed", "jump_velocity", "mouse_sensitivity"],
				"category": "movement",
				"dimension": "3d",
				"difficulty": "beginner",
				"required_actions": ["left", "right", "forward", "back", "jump"],
				"param_info": {
					"speed": {
						"default": 5.0,
						"range": [1.0, 20.0],
						"what": "Walk speed in meters per second.",
						"typical": "3 slow / 5 standard FPS / 8 fast / 12+ sprint",
						"increase": "Faster movement, harder to aim.",
						"decrease": "Slower, more cinematic."
					},
					"jump_velocity": {
						"default": 4.5,
						"range": [1.0, 15.0],
						"what": "Upward impulse on jump. Positive is up in 3D.",
						"typical": "2 small hop / 4.5 normal / 7 floaty",
						"increase": "Higher jump, more air time.",
						"decrease": "Smaller hop. Below 2 barely lifts."
					},
					"mouse_sensitivity": {
						"default": 0.003,
						"range": [0.0005, 0.02],
						"what": "Mouse look multiplier.",
						"typical": "0.002 precise / 0.003 standard / 0.005 twitchy",
						"increase": "Faster aim.",
						"decrease": "Precise aim, slower turn."
					}
				},
				"details": {
					"what": "Complete first-person controller: movement, jump, gravity, mouse look.",
					"where": "Attach to a CharacterBody3D with a Camera3D child.",
					"before": "Create input actions left, right, forward, back, jump. Set mouse_mode CAPTURED in _ready.",
					"after": "Add 'pause menu' so the player can escape. Add 'raycast 3d' for interaction.",
					"why_optimized": "Uses transform.basis so movement follows the player's yaw — standard Godot 4 pattern.",
					"mistakes": "Applying input_dir directly to velocity ignores rotation. Always multiply by transform.basis.",
					"related": ["mouse_look_3d", "first_person_camera_3d", "pause_menu"]
				}
			},
			"coyote_time_2d": {
				"phrases": ["coyote time", "coyote time 2d"],
				"code": """@export var coyote_time: float = 0.1

var _coyote_timer: float = 0.0

func _physics_process(delta: float) -> void:
	if is_on_floor():
		_coyote_timer = coyote_time
	else:
		_coyote_timer = max(_coyote_timer - delta, 0.0)
	if Input.is_action_just_pressed("jump") and _coyote_timer > 0.0:
		velocity.y = -400.0
		_coyote_timer = 0.0
""",
				"params": ["coyote_time"],
				"category": "movement",
				"dimension": "2d",
				"difficulty": "intermediate",
				"required_actions": ["jump"],
				"param_info": {
					"coyote_time": {
						"default": 0.1,
						"range": [0.0, 0.3],
						"what": "How long after walking off a ledge the player can still jump.",
						"typical": "0.08 tight / 0.1 standard / 0.15 forgiving / 0.2+ very loose",
						"increase": "More forgiving — feels like the game reads your mind.",
						"decrease": "More punishing. Zero disables coyote time entirely."
					}
				},
				"details": {
					"what": "Gives a short grace period where jumping is allowed even after leaving the ground.",
					"where": "Replace the jump check in platformer_movement_2d with this logic.",
					"before": "Create input action 'jump'.",
					"after": "Combine with jump buffer for the best feel.",
					"why_optimized": "Single float timer, no Timers or awaits — cheapest possible implementation.",
					"mistakes": "Setting coyote_time too high (>0.2) makes mid-air jumps feel accidental.",
					"related": ["jump_buffer_2d", "platformer_movement_2d", "variable_jump_height"]
				}
			},
			"jump_buffer_2d": {
				"phrases": ["jump buffer", "input buffer jump"],
				"code": """@export var jump_buffer_time: float = 0.15

var _jump_buffer: float = 0.0

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		_jump_buffer = jump_buffer_time

func _physics_process(delta: float) -> void:
	_jump_buffer = max(_jump_buffer - delta, 0.0)
	if _jump_buffer > 0.0 and is_on_floor():
		velocity.y = -400.0
		_jump_buffer = 0.0
""",
				"params": ["jump_buffer_time"],
				"category": "movement",
				"dimension": "2d",
				"difficulty": "intermediate",
				"required_actions": ["jump"],
				"param_info": {
					"jump_buffer_time": {
						"default": 0.15,
						"range": [0.05, 0.3],
						"what": "How long an early jump press stays queued.",
						"typical": "0.1 tight / 0.15 standard / 0.2 forgiving",
						"increase": "Player can press jump earlier and still get the jump.",
						"decrease": "Below 0.05 feels unresponsive."
					}
				},
				"details": {
					"what": "Remembers a jump press for a short window, so the jump fires when landing.",
					"where": "Combine with platformer_movement_2d.",
					"before": "Create input action 'jump'.",
					"after": "Pair with coyote time for maximum responsiveness.",
					"why_optimized": "Input is captured in _unhandled_input (event-driven), the physics check is a single float.",
					"mistakes": "Buffering in _physics_process instead of _unhandled_input — the input event can arrive between physics frames.",
					"related": ["coyote_time_2d", "platformer_movement_2d", "variable_jump_height"]
				}
			},
			"variable_jump_height": {
				"phrases": ["variable jump height", "hold jump higher", "variable jump"],
				"code": """@export var min_jump_velocity: float = -300.0
@export var max_jump_velocity: float = -500.0
@export var max_charge_time: float = 0.3

var _charge: float = 0.0

func _physics_process(delta: float) -> void:
	if Input.is_action_pressed("jump") and is_on_floor():
		_charge = min(_charge + delta, max_charge_time)
	if Input.is_action_just_released("jump") and is_on_floor():
		var t := _charge / max_charge_time
		velocity.y = lerp(min_jump_velocity, max_jump_velocity, t)
		_charge = 0.0
""",
				"params": ["min_jump_velocity", "max_jump_velocity", "max_charge_time"],
				"category": "movement",
				"dimension": "2d",
				"difficulty": "intermediate",
				"required_actions": ["jump"],
				"param_info": {
					"min_jump_velocity": {
						"default": -300.0,
						"range": [-500.0, -100.0],
						"what": "Jump height for a quick tap.",
						"typical": "-250 short / -300 standard / -350 tap-comfortable",
						"increase": "Even short taps go high — removes the point of variable jump.",
						"decrease": "Taps barely hop."
					},
					"max_jump_velocity": {
						"default": -500.0,
						"range": [-900.0, -300.0],
						"what": "Jump height for a full hold.",
						"typical": "-450 modest / -500 standard / -650 heroic",
						"increase": "Held jumps go very high.",
						"decrease": "Reduces contrast between tap and hold."
					},
					"max_charge_time": {
						"default": 0.3,
						"range": [0.1, 0.6],
						"what": "How long you must hold jump to reach max height.",
						"typical": "0.2 quick / 0.3 standard / 0.5 deliberate",
						"increase": "Longer hold required.",
						"decrease": "Easier to get max height immediately."
					}
				},
				"details": {
					"what": "Jump height scales with how long the player holds the jump button.",
					"where": "Replace the jump check in platformer_movement_2d.",
					"before": "Create input action 'jump'.",
					"after": "Pair with coyote time for maximum feel.",
					"why_optimized": "Uses lerp for smooth interpolation between min and max.",
					"mistakes": "Applying the impulse on press instead of release — you can't know the hold duration yet on press.",
					"related": ["platformer_movement_2d", "coyote_time_2d", "double_jump"]
				}
			}
		}
	}

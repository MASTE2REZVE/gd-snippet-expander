@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"snippets": {
			"squash_stretch": {
				"phrases": ["squash stretch", "squash and stretch", "jump squash", "landing squash"],
				"code": """extends Node2D

@export var squash_amount: float = 0.15
@export var stretch_amount: float = 0.2
@export var jump_duration: float = 0.12
@export var land_duration: float = 0.15
@export var return_duration: float = 0.2

var _base_scale: Vector2 = Vector2.ONE
var _tween: Tween = null

func _ready() -> void:
	_base_scale = scale

func jump_squash() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	var wide := Vector2(1.0 + squash_amount, 1.0 - squash_amount)
	_tween = create_tween()
	_tween.tween_property(self, "scale", _base_scale * wide, jump_duration)
	_tween.tween_property(self, "scale", _base_scale * Vector2(1.0 - stretch_amount, 1.0 + stretch_amount), jump_duration)
	_tween.tween_property(self, "scale", _base_scale, return_duration).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func land_squash() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	var wide := Vector2(1.0 + squash_amount * 1.5, 1.0 - squash_amount * 1.5)
	_tween = create_tween()
	_tween.tween_property(self, "scale", _base_scale * wide, land_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "scale", _base_scale, return_duration).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
""",
				"params": ["squash_amount", "stretch_amount", "jump_duration", "land_duration", "return_duration"],
				"category": "feedback",
				"subcategory": "scale",
				"dimension": "2d",
				"difficulty": "beginner",
				"param_info": {
					"squash_amount": {
						"default": 0.15,
						"range": [0.05, 0.5],
						"what": "How much the sprite flattens on impact.",
						"typical": "0.1 subtle / 0.15 standard / 0.3 very cartoon",
						"increase": "More squash.",
						"decrease": "Less."
					},
					"stretch_amount": {
						"default": 0.2,
						"range": [0.05, 0.5],
						"what": "How much the sprite elongates on jump.",
						"typical": "0.1 subtle / 0.2 standard / 0.35 very bouncy",
						"increase": "More stretch.",
						"decrease": "Less."
					},
					"land_duration": {
						"default": 0.15,
						"range": [0.05, 0.4],
						"what": "How long the squash lasts on landing.",
						"typical": "0.1 snappy / 0.15 standard / 0.3 heavy",
						"increase": "Longer.",
						"decrease": "Shorter."
					}
				},
				"details": {
					"what": "Classic squash-and-stretch animation on jump and land. Makes movement feel weighted and cartoony.",
					"where": "Attach to a Node2D that contains the sprite and collision. Scale this parent, not the sprite alone, to include collision.",
					"before": "The sprite must be anchored to the bottom (feet), not center, or the character sinks into the floor when squashing.",
					"after": "Call jump_squash() when the jump input fires. Call land_squash() when velocity.y transitions from negative to zero.",
					"why_optimized": "Kills any existing tween before starting a new one to prevent fights. Tween reused across calls.",
					"mistakes": "Scaling a center-anchored sprite causes the character to sink. Use sprite_offset_center first.",
					"related": ["sprite_offset_center", "impact_frames", "bounce_in", "wobble"]
				}
			},
			"wobble": {
				"phrases": ["wobble", "wobble effect", "jelly", "jelly effect"],
				"code": """extends Node2D

@export var wobble_strength: float = 0.15
@export var wobble_speed: float = 6.0
@export var decay_time: float = 0.8

var _time: float = 0.0
var _active: bool = false
var _base_scale: Vector2 = Vector2.ONE

func _ready() -> void:
	_base_scale = scale

func start_wobble() -> void:
	_time = 0.0
	_active = true

func _process(delta: float) -> void:
	if not _active:
		return
	_time += delta
	var decay: float = 1.0 - (_time / decay_time)
	if decay <= 0.0:
		scale = _base_scale
		_active = false
		return
	var sx: float = 1.0 + sin(_time * wobble_speed) * wobble_strength * decay
	var sy: float = 1.0 - sin(_time * wobble_speed) * wobble_strength * decay
	scale = _base_scale * Vector2(sx, sy)

func stop_wobble() -> void:
	_active = false
	scale = _base_scale
""",
				"params": ["wobble_strength", "wobble_speed", "decay_time"],
				"category": "feedback",
				"subcategory": "scale",
				"dimension": "2d",
				"difficulty": "beginner",
				"param_info": {
					"wobble_strength": {
						"default": 0.15,
						"range": [0.05, 0.5],
						"what": "How much the sprite stretches at peak wobble.",
						"typical": "0.1 subtle / 0.15 standard / 0.3 very jelly",
						"increase": "Bigger wobble.",
						"decrease": "Smaller."
					},
					"wobble_speed": {
						"default": 6.0,
						"range": [2.0, 20.0],
						"what": "How fast the wobble oscillates.",
						"typical": "3 slow / 6 standard / 12 fast jiggle",
						"increase": "Faster.",
						"decrease": "Slower."
					},
					"decay_time": {
						"default": 0.8,
						"range": [0.2, 3.0],
						"what": "How long until the wobble fades to nothing.",
						"typical": "0.4 quick / 0.8 standard / 1.5+ long",
						"increase": "Longer wobble.",
						"decrease": "Shorter."
					}
				},
				"details": {
					"what": "Jelly-like wobble that decays over time. Triggered by impacts, landings, or any event.",
					"where": "Attach to a Node2D. Call start_wobble() when something happens.",
					"before": "Sprite anchored at bottom for correct wobble pivot.",
					"after": "Stack multiple wobbles by resetting _time without killing the effect.",
					"why_optimized": "Sine-based oscillation with linear decay. Single _process loop.",
					"mistakes": "Running wobble alongside a Tween-based scale effect fights for control of the scale property. Pick one at a time.",
					"related": ["squash_stretch", "bounce_in", "idle_bob"]
				}
			},
			"bounce_in": {
				"phrases": ["bounce in", "scale in pop", "pop in", "springy appear"],
				"code": """extends Node2D

@export var overshoot: float = 1.3
@export var duration: float = 0.4
@export var start_scale: float = 0.0

var _base_scale: Vector2 = Vector2.ONE

func _ready() -> void:
	_base_scale = scale
	scale = _base_scale * start_scale
	play()

func play() -> void:
	scale = _base_scale * start_scale
	var tween := create_tween()
	tween.tween_property(self, "scale", _base_scale * overshoot, duration * 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", _base_scale, duration * 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func play_with_delay(delay: float) -> void:
	scale = _base_scale * start_scale
	await get_tree().create_timer(delay).timeout
	play()
""",
				"params": ["overshoot", "duration", "start_scale"],
				"category": "feedback",
				"subcategory": "scale",
				"dimension": "2d",
				"difficulty": "beginner",
				"param_info": {
					"overshoot": {
						"default": 1.3,
						"range": [1.0, 2.0],
						"what": "How much the object overshoots before settling.",
						"typical": "1.1 subtle / 1.3 standard / 1.8 very bouncy",
						"increase": "Bigger bounce.",
						"decrease": "Smaller."
					},
					"duration": {
						"default": 0.4,
						"range": [0.1, 2.0],
						"what": "Total duration of the bounce-in.",
						"typical": "0.2 quick / 0.4 standard / 0.8 slow",
						"increase": "Slower.",
						"decrease": "Faster."
					},
					"start_scale": {
						"default": 0.0,
						"range": [0.0, 1.0],
						"what": "Initial scale multiplier before the bounce.",
						"typical": "0.0 pop from nothing / 0.5 half size / 1.0 no scale",
						"increase": "Starts larger.",
						"decrease": "Starts smaller."
					}
				},
				"details": {
					"what": "Object pops in from nothing with an overshoot bounce. Great for UI elements, pickups, and enemy spawns.",
					"where": "Attach to a Node2D that should appear with a bounce. Bounce runs automatically on _ready.",
					"before": "None.",
					"after": "Call play() again to replay. Or use play_with_delay(delay) for staggered entrances.",
					"why_optimized": "Two-tween bounce is cheaper than full physics. Elastic easing gives the bounce feel.",
					"mistakes": "Bouncing a node whose scale was already non-1 in the Inspector resets it to base. Set base_scale in the Inspector and it's respected.",
					"related": ["squash_stretch", "wobble", "fade_in_ui"]
				}
			},
			"idle_bob": {
				"phrases": ["idle bob", "float", "hover", "idle float"],
				"code": """extends Node2D

@export var bob_height: float = 4.0
@export var bob_speed: float = 2.0
@export var bob_offset: float = 0.0

var _time: float = 0.0
var _origin: Vector2 = Vector2.ZERO
var _active: bool = true

func _ready() -> void:
	_origin = position
	_time = bob_offset

func _process(delta: float) -> void:
	if not _active:
		return
	_time += delta * bob_speed
	position.y = _origin.y + sin(_time) * bob_height

func set_active(value: bool) -> void:
	_active = value
	if not value:
		position = _origin

func set_origin(new_origin: Vector2) -> void:
	_origin = new_origin
""",
				"params": ["bob_height", "bob_speed", "bob_offset"],
				"category": "feedback",
				"subcategory": "idle",
				"dimension": "2d",
				"difficulty": "beginner",
				"param_info": {
					"bob_height": {
						"default": 4.0,
						"range": [1.0, 20.0],
						"what": "How high the bob goes, in pixels.",
						"typical": "2 subtle / 4 standard / 10+ floating pickup",
						"increase": "Bigger bob.",
						"decrease": "Smaller."
					},
					"bob_speed": {
						"default": 2.0,
						"range": [0.5, 10.0],
						"what": "How fast the bob oscillates.",
						"typical": "1 lazy / 2 standard / 5 quick",
						"increase": "Faster.",
						"decrease": "Slower."
					},
					"bob_offset": {
						"default": 0.0,
						"range": [0.0, 6.28],
						"what": "Phase offset in radians. Set different values to desync multiple bobbing objects.",
						"typical": "0.0 / 1.0 / 2.0 / 3.0 for four distinct phases",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "Smooth vertical bob for pickups, floating enemies, and idle UI elements.",
					"where": "Attach to any Node2D. Store the base position in _ready and modify on top.",
					"before": "None.",
					"after": "Give each instance a different bob_offset so a room full of coins doesn't bob in perfect sync.",
					"why_optimized": "Single sine call per frame. Bobbing property setter is only position.y.",
					"mistakes": "Modifying position directly without storing the origin causes drift. The _ready caches the origin.",
					"related": ["particle_sparkle", "coin_pickup", "bounce_in"]
				}
			},
			"breathing": {
				"phrases": ["breathing", "idle breathing", "character breathing", "subtle idle"],
				"code": """extends Node2D

@export var breath_amount: float = 0.03
@export var breath_speed: float = 1.2
@export var vertical_only: bool = true

var _time: float = 0.0
var _base_scale: Vector2 = Vector2.ONE

func _ready() -> void:
	_base_scale = scale

func _process(delta: float) -> void:
	_time += delta * breath_speed
	var breath: float = sin(_time) * breath_amount
	if vertical_only:
		scale = _base_scale * Vector2(1.0, 1.0 + breath)
	else:
		scale = _base_scale * Vector2(1.0 + breath, 1.0 + breath)
""",
				"params": ["breath_amount", "breath_speed", "vertical_only"],
				"category": "feedback",
				"subcategory": "idle",
				"dimension": "2d",
				"difficulty": "beginner",
				"param_info": {
					"breath_amount": {
						"default": 0.03,
						"range": [0.01, 0.15],
						"what": "How much the sprite scales during a breath.",
						"typical": "0.02 very subtle / 0.03 standard / 0.08 obvious",
						"increase": "More noticeable breathing.",
						"decrease": "Subtler."
					},
					"breath_speed": {
						"default": 1.2,
						"range": [0.3, 5.0],
						"what": "How fast the breath cycles.",
						"typical": "0.8 slow calm / 1.2 standard / 2.5+ panting",
						"increase": "Faster breathing.",
						"decrease": "Slower."
					},
					"vertical_only": {
						"default": true,
						"range": [],
						"what": "True for vertical-only breathing (chest movement). False for uniform (whole body).",
						"typical": "true for humans / false for animals",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "Subtle idle breathing animation. The tiniest detail that makes characters feel alive.",
					"where": "Attach to the sprite's parent node. Sprite must be anchored at the bottom so breathing pushes upward.",
					"before": "Sprite anchored at bottom (sprite_offset_center).",
					"after": "Disable during movement — call set_process(false) when walking.",
					"why_optimized": "One sine call per frame. Scale-only, no position changes.",
					"mistakes": "Applying to a center-anchored sprite makes the character bounce up and down instead of breathing.",
					"related": ["idle_bob", "sprite_offset_center", "animated_sprite_state"]
				}
			}
		}
	}

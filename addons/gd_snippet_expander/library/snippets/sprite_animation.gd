@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"snippets": {
			"sprite_sheet_setup": {
				"phrases": ["sprite sheet", "sprite sheet setup", "sprite frames", "sprite frames resource"],
				"code": """# Setting up a sprite sheet with AnimatedSprite2D.
#
# 1. Add an AnimatedSprite2D node.
# 2. In the Inspector, click Sprite Frames -> New SpriteFrames.
# 3. Click the SpriteFrames resource to open the bottom panel.
# 4. Click 'Add Animation' and name it (idle, walk, run, jump...).
# 5. With the animation selected, click the grid icon (Add frames from sprite sheet).
# 6. Pick your spritesheet PNG, set Horizontal and Vertical to the
#    number of frames in the sheet.
# 7. Select the frames you want, click Add Frames.
#
# Recommended animations for a platformer:
#   idle     - 1-2 frames, loop
#   walk     - 4-8 frames, loop
#   run      - 4-8 frames, loop, faster
#   jump     - 2-3 frames, no loop
#   fall     - 1-2 frames, loop
#   hurt     - 2-3 frames, no loop

func ensure_animations(sprite: AnimatedSprite2D) -> void:
	if sprite.sprite_frames == null:
		sprite.sprite_frames = SpriteFrames.new()
	for anim in ["idle", "walk", "run", "jump", "fall", "hurt"]:
		if not sprite.sprite_frames.has_animation(anim):
			sprite.sprite_frames.add_animation(anim)
""",
				"params": [],
				"category": "sprite",
				"subcategory": "animation",
				"dimension": "2d",
				"difficulty": "beginner",
				"details": {
					"what": "Workflow for setting up a sprite sheet as an AnimatedSprite2D with named animations. Comment-only — no runtime behavior.",
					"where": "In the AnimatedSprite2D SpriteFrames editor.",
					"before": "A spritesheet PNG with frames laid out in a grid.",
					"after": "Play animations by name with sprite.play(\"walk\"). The animated_sprite_state snippet drives them from velocity.",
					"why_optimized": "SpriteFrames is a shared resource — one instance per character type works for many instances.",
					"mistakes": "Wrong grid dimensions split frames unevenly. Count columns and rows in an image editor first.",
					"related": ["animated_sprite_state", "sprite_flip_direction", "sprite_offset_center"]
				}
			},
			"animated_sprite_state": {
				"phrases": ["animated sprite state", "sprite state", "animation from velocity", "walk idle animation"],
				"code": """extends AnimatedSprite2D

@export var idle_anim: String = "idle"
@export var walk_anim: String = "walk"
@export var run_anim: String = "run"
@export var jump_anim: String = "jump"
@export var fall_anim: String = "fall"
@export var run_threshold: float = 200.0
@export var walk_threshold: float = 5.0

var _body: CharacterBody2D = null

func _ready() -> void:
	_body = get_parent() as CharacterBody2D
	if _body == null:
		push_warning("AnimatedSprite2D parent should be a CharacterBody2D.")
		return
	if not sprite_frames.has_animation(idle_anim):
		push_warning("Missing animation: " + idle_anim)

func _process(_delta: float) -> void:
	if _body == null:
		return
	var vx: float = absf(_body.velocity.x)
	var vy: float = _body.velocity.y
	var on_floor: bool = _body.is_on_floor()
	# Air states take priority
	if not on_floor:
		if vy < 0.0:
			_set_anim(jump_anim)
		else:
			_set_anim(fall_anim)
		return
	# Ground states
	if vx < walk_threshold:
		_set_anim(idle_anim)
	elif vx < run_threshold:
		_set_anim(walk_anim)
	else:
		_set_anim(run_anim)

func _set_anim(anim: String) -> void:
	if not sprite_frames.has_animation(anim):
		return
	if animation == anim and is_playing():
		return
	play(anim)
""",
				"params": ["idle_anim", "walk_anim", "run_anim", "jump_anim", "fall_anim", "run_threshold", "walk_threshold"],
				"category": "sprite",
				"subcategory": "animation",
				"dimension": "2d",
				"difficulty": "beginner",
				"param_info": {
					"run_threshold": {
						"default": 200.0,
						"range": [50.0, 500.0],
						"what": "Horizontal speed above which the run animation plays.",
						"typical": "150 slow / 200 standard / 300 needs sprint",
						"increase": "Requires faster movement to trigger run.",
						"decrease": "Triggers run sooner."
					},
					"walk_threshold": {
						"default": 5.0,
						"range": [1.0, 50.0],
						"what": "Speed below which idle plays.",
						"typical": "5 standard / 20 stops mid-drift",
						"increase": "Idle triggers more easily.",
						"decrease": "Idle only at near-zero speed."
					}
				},
				"details": {
					"what": "Attaches to an AnimatedSprite2D that is a child of a CharacterBody2D. Reads the body's velocity and floor state, then plays the correct animation.",
					"where": "Attach to the AnimatedSprite2D child of a CharacterBody2D with platformer_movement_2d or character_movement_2d.",
					"before": "AnimatedSprite2D with idle, walk, run, jump, fall animations. Parent must be a CharacterBody2D.",
					"after": "Add attack or hurt animations and gate them with a state variable so movement doesn't interrupt them.",
					"why_optimized": "Checks animation changes only when needed — play() is skipped if the same animation is already running.",
					"mistakes": "Calling play() every frame restarts the animation from frame 0, causing stutter. The _set_anim check prevents this.",
					"related": ["sprite_sheet_setup", "sprite_flip_direction", "platformer_movement_2d", "animated_sprite_state_8dir"]
				}
			},
			"sprite_flip_direction": {
				"phrases": ["flip sprite", "sprite direction", "face direction", "flip on direction"],
				"code": """extends AnimatedSprite2D

@export var flip_threshold: float = 5.0

var _body: CharacterBody2D = null
var _last_facing: int = 1

func _ready() -> void:
	_body = get_parent() as CharacterBody2D

func _process(_delta: float) -> void:
	if _body == null:
		return
	var vx: float = _body.velocity.x
	if absf(vx) < flip_threshold:
		return
	var facing: int = 1 if vx > 0.0 else -1
	if facing != _last_facing:
		_last_facing = facing
		flip_h = facing < 0

func face_direction(dir: int) -> void:
	if dir == 0:
		return
	_last_facing = 1 if dir > 0 else -1
	flip_h = _last_facing < 0

func get_facing() -> int:
	return _last_facing
""",
				"params": ["flip_threshold"],
				"category": "sprite",
				"subcategory": "direction",
				"dimension": "2d",
				"difficulty": "beginner",
				"param_info": {
					"flip_threshold": {
						"default": 5.0,
						"range": [1.0, 50.0],
						"what": "Minimum horizontal speed to trigger a flip.",
						"typical": "3 responsive / 5 standard / 20 lazy",
						"increase": "Requires more speed to flip.",
						"decrease": "Flips at the smallest movement."
					}
				},
				"details": {
					"what": "Flips the sprite horizontally based on the parent body's horizontal velocity.",
					"where": "Attach to the AnimatedSprite2D child of a CharacterBody2D.",
					"before": "Parent must be a CharacterBody2D with horizontal movement.",
					"after": "Call face_direction(1) or face_direction(-1) explicitly when attacking or aiming at a target.",
					"why_optimized": "Only writes flip_h when the direction actually changes. No per-frame property writes.",
					"mistakes": "Flipping every frame when velocity is near zero causes the sprite to jitter. The threshold prevents this.",
					"related": ["animated_sprite_state", "topdown_movement_2d", "weapon_visual_swap"]
				}
			},
			"animated_sprite_state_8dir": {
				"phrases": ["8 direction animation", "8dir sprite", "topdown sprite animation", "4 direction sprite"],
				"code": """extends AnimatedSprite2D

@export var idle_anim: String = "idle"
@export var walk_anim_prefix: String = "walk_"
@export var dead_zone: float = 0.1
@export var use_8dir: bool = false

var _body: CharacterBody2D = null
var _current_dir: String = "down"

func _ready() -> void:
	_body = get_parent() as CharacterBody2D

func _process(_delta: float) -> void:
	if _body == null:
		return
	var v := _body.velocity
	var dir := _direction_from_vector(v)
	if dir.is_empty():
		_play_animation(idle_anim)
		return
	if dir != _current_dir:
		_current_dir = dir
	_play_animation(walk_anim_prefix + dir)

func _direction_from_vector(v: Vector2) -> String:
	if v.length() < dead_zone:
		return ""
	if use_8dir:
		return _8dir_name(v)
	return _4dir_name(v)

func _4dir_name(v: Vector2) -> String:
	if absf(v.x) > absf(v.y):
		return "right" if v.x > 0.0 else "left"
	return "down" if v.y > 0.0 else "up"

func _8dir_name(v: Vector2) -> String:
	var angle := v.angle()
	var octant := int(round(angle / (PI / 4.0))) % 8
	match octant:
		0: return "right"
		1: return "down_right"
		2: return "down"
		3: return "down_left"
		4: return "left"
		-4: return "left"
		-3: return "up_left"
		-2: return "up"
		-1: return "up_right"
	return "down"

func _play_animation(anim: String) -> void:
	if not sprite_frames.has_animation(anim):
		return
	if animation == anim and is_playing():
		return
	play(anim)
""",
				"params": ["idle_anim", "walk_anim_prefix", "dead_zone", "use_8dir"],
				"category": "sprite",
				"subcategory": "direction",
				"dimension": "2d",
				"difficulty": "intermediate",
				"param_info": {
					"walk_anim_prefix": {
						"default": "walk_",
						"range": [],
						"what": "Prefix used to build the animation name from a direction. walk_down, walk_up, etc.",
						"typical": "walk_ / run_ / move_",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"dead_zone": {
						"default": 0.1,
						"range": [0.0, 1.0],
						"what": "Velocity length below which idle plays.",
						"typical": "0.1 standard / 0.3 forces larger movement",
						"increase": "Idle triggers easier.",
						"decrease": "Idle only at near-zero."
					},
					"use_8dir": {
						"default": false,
						"range": [],
						"what": "True for 8-direction animations (diagonals), false for 4.",
						"typical": "false simple RPGs / true detailed sprites",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "Drives directional animations from a CharacterBody2D's velocity. Supports both 4-direction and 8-direction sprite sets.",
					"where": "Attach to the AnimatedSprite2D child of a CharacterBody2D used for top-down movement.",
					"before": "Animations named walk_up, walk_down, walk_left, walk_right (and diagonals for 8dir). Plus an idle animation.",
					"after": "For 8-direction, name animations walk_down_right, walk_up_left, etc.",
					"why_optimized": "Only recomputes direction when velocity is above the deadzone. Animation name is cached until direction changes.",
					"mistakes": "Missing animation names silently fail. Use ensure_animations in the sprite_sheet_setup snippet to catch these at startup.",
					"related": ["sprite_sheet_setup", "topdown_movement_2d", "character_movement_2d"]
				}
			},
			"sprite_offset_center": {
				"phrases": ["sprite offset", "center sprite", "sprite alignment", "fix sprite offset"],
				"code": """# Sprite2D and AnimatedSprite2D default to top-left origin.
# Use centered = true (default in Godot 4) OR set an explicit offset.
#
# The most common setup for a 2D character:
#   - Sprite anchored at the character's "feet" (the bottom-center pixel).
#   - Then collision shape is a small rectangle at the feet.
#   - Then the sprite offset.y is set to half the sprite height.
#
# Why feet-anchored? Because when you rotate or scale the character
# for effects like squash-and-stretch, you want it to pivot at the
# ground, not the middle.

extends Sprite2D

@export var anchor_to_feet: bool = true

func _ready() -> void:
	if anchor_to_feet and texture != null:
		centered = false
		offset = Vector2(texture.get_width() * 0.5, texture.get_height())
	else:
		centered = true
		offset = Vector2.ZERO

func set_feet_offset() -> void:
	if texture == null:
		return
	centered = false
	offset = Vector2(texture.get_width() * 0.5, texture.get_height())

func set_center_offset() -> void:
	centered = true
	offset = Vector2.ZERO
""",
				"params": ["anchor_to_feet"],
				"category": "sprite",
				"subcategory": "alignment",
				"dimension": "2d",
				"difficulty": "beginner",
				"param_info": {
					"anchor_to_feet": {
						"default": true,
						"range": [],
						"what": "True to anchor the sprite so its bottom-center sits at the node origin.",
						"typical": "true for characters / false for props and pickups",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "Sets sprite origin to bottom-center (feet) for characters. Makes squash-and-stretch, jump arcs, and knockback behave naturally.",
					"where": "Attach to a Sprite2D. AnimatedSprite2D has the same properties.",
					"before": "A sprite with a texture assigned.",
					"after": "Adjust your CollisionShape2D to match — a small rectangle near the feet for platformers, a circle for top-down.",
					"why_optimized": "One-time setup in _ready. No runtime cost.",
					"mistakes": "Using center-anchored sprites with squash-and-stretch makes the character sink into the floor on every jump.",
					"related": ["squash_stretch", "platformer_movement_2d", "player_2d_platformer"]
				}
			}
		}
	}

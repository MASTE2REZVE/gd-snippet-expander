@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"snippets": {
			"character_animation_3d": {
				"phrases": ["character animation 3d", "3d character animation", "blendspace locomotion", "3d locomotion"],
				"code": """extends CharacterBody3D

@export var walk_speed: float = 5.0
@export var run_speed: float = 10.0

@onready var _anim_tree: AnimationTree = $AnimationTree

var _blend_position: Vector2 = Vector2.ZERO
var _playback: AnimationNodeStateMachinePlayback = null

func _ready() -> void:
	_anim_tree.active = true
	if _anim_tree.tree_root is AnimationNodeStateMachine:
		_playback = _anim_tree.get("parameters/playback")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	var input_dir := Input.get_vector("left", "right", "forward", "back")
	var dir := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var target_speed: float = run_speed if Input.is_action_pressed("sprint") else walk_speed
	velocity.x = dir.x * target_speed
	velocity.z = dir.z * target_speed
	move_and_slide()
	_update_animation(input_dir, target_speed)

func _update_animation(input_dir: Vector2, target_speed: float) -> void:
	# Blend position — feed the local movement direction
	_blend_position = _blend_position.lerp(input_dir, 0.15)
	_anim_tree.set("parameters/move/blend_position", _blend_position)
	# State machine — switch between idle/walk/run based on speed
	if _playback == null:
		return
	var speed_ratio: float = velocity.length() / target_speed
	if speed_ratio < 0.1:
		_playback.travel("idle")
	elif speed_ratio < 0.8:
		_playback.travel("walk")
	else:
		_playback.travel("run")

# SETUP
# 1. CharacterBody3D with an AnimationTree child.
# 2. AnimationPlayer inside with idle, walk, run animations.
# 3. AnimationTree -> tree_root = AnimationNodeStateMachine.
# 4. Add a BlendSpace2D node inside with 'blend_position' parameter.
# 5. Wire idle / walk / run states to the blendspace.
""",
				"params": ["walk_speed", "run_speed"],
				"category": "animation",
				"subcategory": "3d",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "intermediate",
				"required_actions": ["left", "right", "forward", "back", "sprint"],
				"param_info": {
					"walk_speed": {
						"default": 5.0,
						"range": [1.0, 15.0],
						"what": "Walk movement speed.",
						"typical": "3 slow / 5 standard / 8 fast",
						"increase": "Faster walk.",
						"decrease": "Slower."
					},
					"run_speed": {
						"default": 10.0,
						"range": [5.0, 30.0],
						"what": "Run movement speed.",
						"typical": "1.5x walk standard / 2x arcade",
						"increase": "Faster run.",
						"decrease": "Slower."
					}
				},
				"details": {
					"what": "Full 3D character animation setup: BlendSpace2D for directional locomotion plus a state machine for idle/walk/run transitions.",
					"where": "Attach to a CharacterBody3D with an AnimationTree child. Configure the tree in the AnimationTree panel.",
					"before": "AnimationPlayer with at least idle, walk, run animations. Each animation should ideally be directional (forward, back, left, right).",
					"after": "Add jump/fall animations and air states to the state machine.",
					"why_optimized": "Blend position is smoothed with lerp. State machine travel is a single call.",
					"mistakes": "Setting the blend_position directly from input without smoothing causes animation pops when the player changes direction.",
					"related": ["animation_tree_setup", "animation_tree_state", "character_movement_3d"]
				}
			},
			"root_motion_3d": {
				"phrases": ["root motion 3d", "3d root motion", "animation driven movement", "rootmotion"],
				"code": """extends CharacterBody3D

@onready var _anim_tree: AnimationTree = $AnimationTree

func _ready() -> void:
	_anim_tree.active = true

func _physics_process(delta: float) -> void:
	# Apply gravity and other physics here if not using full root motion
	if not is_on_floor():
		velocity += get_gravity() * delta
	move_and_slide()

func _on_animation_tree_animation_finished(_anim_name: StringName) -> void:
	pass

# ROOT MOTION SETUP
# 1. In the AnimationTree, set root_motion_track to the root bone's
#    transform track (usually 'Armature/Skeleton3D:Root').
# 2. Enable root motion on the character via the AnimationTree:
#    anim_tree.root_motion_track = NodePath("Armature/Skeleton3D:Root")
# 3. In _physics_process, after animation update, read the root motion:
#
#    var motion := _anim_tree.get_root_motion_position()
#    var rotation_motion := _anim_tree.get_root_motion_rotation()
#    transform.basis = transform.basis.rotated(Vector3.UP, rotation_motion)
#    velocity = transform.basis * motion / delta
#
# 4. Reset root motion at the end of each frame if you have a
#    control rig, so the animation doesn't drift:
#    _anim_tree.set("parameters/blend_position", 0)
#
# Root motion gives animations exact control over character movement
# speed and direction. Ideal for attack lunges, dodges, and
# cinematic-style actions.
""",
				"params": [],
				"category": "animation",
				"subcategory": "3d",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "advanced",
				"details": {
					"what": "Reference for using root motion — animations that control character movement directly, instead of code driving the animation.",
					"where": "CharacterBody3D with an AnimationTree. Set root_motion_track in the AnimationTree Inspector.",
					"before": "Animations with proper root bone motion baked in (from Blender or Mixamo). The root bone must be animated, not the whole armature.",
					"after": "Root motion is best for attack lunges and dodges. Regular locomotion is easier with code-driven velocity.",
					"why_optimized": "Root motion values come directly from the animation — no per-frame math on the game code side.",
					"mistakes": "Using root motion for everything means the player can't influence movement. Mix code-driven and root-motion-driven depending on the animation.",
					"related": ["character_animation_3d", "animation_tree_setup", "combo_attack"]
				}
			},
			"animation_ik_hint_3d": {
				"phrases": ["animation ik 3d", "ik setup 3d", "inverse kinematics 3d", "foot ik"],
				"code": """# Godot 4's SkeletonIK3D was removed in favor of manual IK via
# Node3D targets and AnimationTree modifier nodes.
#
# Approach 1: AnimationTree IK Modifier (Godot 4.3+)
#   1. Add an AnimationNodeStateMachine or AnimationNodeBlendTree.
#   2. Add an AnimationNodeIKModifier3D node.
#   3. Assign the Skeleton3D path and target node paths.
#   4. Set the chain length (e.g. 2 for arm, 2 for leg).
#
# Approach 2: Simple two-bone IK in script
#   Use for feet that follow terrain or hands that follow a target.

extends Skeleton3D

@export var left_foot_target: Node3D
@export var right_foot_target: Node3D
@export var raycast_range: float = 2.0
@export var foot_offset: float = 0.1

func _physics_process(_delta: float) -> void:
	if left_foot_target == null or right_foot_target == null:
		return
	# Raycast down from each target to find ground height
	_adjust_target(left_foot_target)
	_adjust_target(right_foot_target)

func _adjust_target(target: Node3D) -> void:
	var space := get_world_3d().direct_space_state
	var from := target.global_position + Vector3.UP * 0.5
	var to := target.global_position + Vector3.DOWN * raycast_range
	var query := PhysicsRayQueryParameters3D.create(from, to)
	var result := space.intersect_ray(query)
	if not result.is_empty():
		var hit_pos: Vector3 = result.get("position", target.global_position)
		target.global_position = hit_pos + Vector3.UP * foot_offset

# SETUP
# 1. CharacterBody3D with MeshInstance3D and Skeleton3D children.
# 2. Add left_foot_target and right_foot_target Marker3D nodes.
# 3. Parent them to the character so they move with it.
# 4. Attach this script to the Skeleton3D.
# 5. In AnimationTree, add IK modifiers targeting these nodes.
""",
				"params": ["left_foot_target", "right_foot_target", "raycast_range", "foot_offset"],
				"category": "animation",
				"subcategory": "3d",
				"platforms": ["desktop", "mobile"],
				"dimension": "3d",
				"difficulty": "advanced",
				"param_info": {
					"raycast_range": {
						"default": 2.0,
						"range": [0.5, 5.0],
						"what": "How far down to search for the ground.",
						"typical": "1.0 tight / 2.0 standard / 4.0+ for uneven terrain",
						"increase": "Reaches further down.",
						"decrease": "Shorter."
					},
					"foot_offset": {
						"default": 0.1,
						"range": [0.0, 0.5],
						"what": "How far above the ground to place the foot.",
						"typical": "0.05 tight / 0.1 standard / 0.2+ thick boots",
						"increase": "Foot higher off ground.",
						"decrease": "Closer to ground."
					}
				},
				"details": {
					"what": "Reference for setting up IK (inverse kinematics) in Godot 4. Foot IK for sloped terrain, hand IK for weapon holding.",
					"where": "Skeleton3D on a rigged character. AnimationTree with IK modifier nodes.",
					"before": "A rigged character with a skeleton. AnimationTree configured with a state machine or blend tree.",
					"after": "IK is expensive — only use on characters near the camera. Disable for distant NPCs.",
					"why_optimized": "Raycast per foot per frame is the main cost. Cache the raycast and only update when the character moves.",
					"mistakes": "Forgetting to set the IK modifier in the AnimationTree means the targets do nothing. The modifier is what drives the IK.",
					"related": ["character_animation_3d", "root_motion_3d", "animation_tree_setup"]
				}
			},
			"animation_layers_3d": {
				"phrases": ["animation layers 3d", "3d animation layers", "upper lower body animation", "animation mask"],
				"code": """# Animation layers in Godot 4 use AnimationNodeBlend2 or
# AnimationNodeBlend3 with bone masks.
#
# Common use case: separate upper body (aiming, shooting) from
# lower body (walking).
#
# SETUP
# 1. AnimationTree -> tree_root = AnimationNodeBlendTree.
# 2. Add a Blend2 node named 'layer'.
# 3. Connect:
#    - Base input: the full-body locomotion (state machine).
#    - Blend input: the upper body override (aim animation).
# 4. Set blend_amount to 0 for full locomotion, 1 for full upper.
# 5. To mask bones, use an AnimationNodeBlendTree with a mask node,
#    or use AnimationNodeStateMachine with per-state bone masks.

extends CharacterBody3D

@onready var _anim_tree: AnimationTree = $AnimationTree

var _aiming: bool = false

func _ready() -> void:
	_anim_tree.active = true

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("aim"):
		_aiming = true
	elif event.is_action_released("aim"):
		_aiming = false

func _process(delta: float) -> void:
	var target_blend: float = 1.0 if _aiming else 0.0
	var current = _anim_tree.get("parameters/layer/blend_amount")
	_anim_tree.set("parameters/layer/blend_amount", lerpf(current, target_blend, 8.0 * delta))

# MASK CONFIGURATION
# In the AnimationTree panel:
# 1. Select the state with the upper-body animation.
# 2. In the Inspector, set 'Filter Enabled' to true.
# 3. Set 'Filter Type' to 'Bones'.
# 4. Enable the bones you want masked (spine, arms, head).
# 5. The rest of the body continues playing the locomotion animation.
#
# Common masks:
# - Upper body: spine, chest, neck, head, both arms
# - Right arm only: right shoulder, right elbow, right hand
# - Head only: neck, head
""",
				"params": [],
				"category": "animation",
				"subcategory": "3d",
				"platforms": ["desktop", "mobile"],
				"dimension": "3d",
				"difficulty": "advanced",
				"required_actions": ["aim"],
				"details": {
					"what": "Reference for using animation layers with bone masks — aim animations on the upper body while the lower body walks.",
					"where": "CharacterBody3D with an AnimationTree. Blend2 node in a BlendTree root.",
					"before": "Separate full-body and upper-body animations. A rigged character.",
					"after": "Chain layers for complex setups: base locomotion, upper-body aim, additive effects like breathing.",
					"why_optimized": "Masks are baked into the animation. Runtime cost is one blend operation per frame.",
					"mistakes": "Forgetting to enable Filter on the masked state means the whole animation overrides the base — no layering.",
					"related": ["character_animation_3d", "animation_blend_2d", "weapon_swap"]
				}
			},
			"animation_event_3d": {
				"phrases": ["animation event 3d", "animation call method", "3d animation event", "anim notify 3d"],
				"code": """extends CharacterBody3D

@onready var _anim_player: AnimationPlayer = get_node_or_null("AnimationPlayer")
@onready var _anim_tree: AnimationTree = get_node_or_null("AnimationTree")

signal attack_window_opened
signal attack_window_closed
signal footstep_step

func _ready() -> void:
	if _anim_player != null:
		_anim_player.animation_finished.connect(_on_animation_finished)

func _on_animation_finished(anim_name: StringName) -> void:
	match String(anim_name):
		"attack":
			_on_attack_finished()
		"jump":
			_on_jump_finished()

func _on_attack_finished() -> void:
	attack_window_closed.emit()

func _on_jump_finished() -> void:
	pass

# ANIMATION EVENTS
# Godot animation events are called "method call tracks".
#
# 1. Open the AnimationPlayer.
# 2. Select the animation you want to add events to.
# 3. Add a new track of type 'Call Method Track'.
# 4. Set the target node (typically the character root).
# 5. Double-click on the timeline to add event keys.
# 6. On each key, pick the method name and arguments.
#
# Common animation events:
# - 'open_attack_window' at the start of the hit frame
# - 'close_attack_window' at the end of the hit frame
# - 'spawn_footstep' at each foot contact
# - 'play_sfx' with a sound name argument
# - 'spawn_vfx' with a name argument
#
# Define these methods on the target node:
func open_attack_window() -> void:
	attack_window_opened.emit()

func close_attack_window() -> void:
	attack_window_closed.emit()

func spawn_footstep() -> void:
	footstep_step.emit()

func play_sfx(sound_name: String) -> void:
	print("Play sound: ", sound_name)

func spawn_vfx(vfx_name: String) -> void:
	print("Spawn VFX: ", vfx_name)
""",
				"params": [],
				"category": "animation",
				"subcategory": "3d",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "intermediate",
				"details": {
					"what": "Animation events via Call Method Tracks. Trigger game logic from exact frames in animations.",
					"where": "Target node with the script attached, referenced by an AnimationPlayer's Call Method Track.",
					"before": "Animations with method call tracks set up in the AnimationPlayer.",
					"after": "Connect the signals to actual game logic. Example: attack_window_opened enables damage on the hitbox.",
					"why_optimized": "Events fire only at the exact frame. No per-frame checks for animation state.",
					"mistakes": "Calling methods with wrong argument counts breaks silently. Verify signatures match the track.",
					"related": ["melee_attack", "hitbox", "character_animation_3d"]
				}
			},
			"animation_transition_blend_3d": {
				"phrases": ["animation transition 3d", "blend transition 3d", "smooth transition animation", "animation blend time"],
				"code": """# Smooth transitions between animations use the state machine's
# transition time in the AnimationTree panel.
#
# Per-transition configuration:
# 1. Open the AnimationTree panel.
# 2. Click on an arrow between two states.
# 3. In the Inspector:
#    - Xfade Time: how long to blend (e.g. 0.2 seconds)
#    - Xfade Curve: linear, ease-in, ease-out, etc.
#    - Priority: which transitions win when multiple are valid
#    - Advance Mode: when the destination animation starts
#      (Enabled / Auto / After Xfade time)
#
# Common transition times:
#   idle -> walk: 0.2s
#   walk -> run: 0.3s
#   walk -> jump: 0.1s (snappy)
#   anything -> hurt: 0.05s (instant reaction)
#   attack -> idle: 0.3s (recovery)
#
# Some transitions should be instant (0.0 xfade):
#   - Landing from a fall
#   - Taking a hit
#   - Death

extends CharacterBody3D

@onready var _playback: AnimationNodeStateMachinePlayback = $AnimationTree.get("parameters/playback")

func _ready() -> void:
	$AnimationTree.active = true

func force_transition(state: String, immediately: bool = false) -> void:
	if immediately:
		_playback.start(state)
	else:
		_playback.travel(state)

func get_current_state() -> String:
	return String(_playback.get_current_node())

func get_current_play_position() -> float:
	return _playback.get_current_play_position()

# TIPS
# - Keep walking transitions around 0.2-0.3 seconds for natural feel.
# - Short transitions (0.05-0.1) for combat animations so hits feel snappy.
# - After taking damage, use force_transition('hurt', true) to
#   immediately cut to the hurt animation, bypassing the xfade.
# - For smooth transitions to the SAME state (walk to walk), enable
#   'Auto Advance' so the animation loops without interruption.
""",
				"params": [],
				"category": "animation",
				"subcategory": "3d",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "intermediate",
				"details": {
					"what": "Reference for tuning animation transitions. Xfade times, priorities, and instant cuts.",
					"where": "AnimationTree panel. Configure each transition arrow in the Inspector.",
					"before": "An AnimationTree with a state machine set up.",
					"after": "Test transitions in-game. Long transitions feel sluggish; short ones feel robotic. 0.2-0.3s is the sweet spot.",
					"why_optimized": "State machine transitions are computed once. No per-frame blending unless mid-transition.",
					"mistakes": "Using a single xfade time for all transitions makes combat feel slow and idle feel jerky. Configure per-transition.",
					"related": ["animation_state_machine_2d", "character_animation_3d", "animation_3d"]
				}
			}
		}
	}

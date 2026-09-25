@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"snippets": {
			"animation_tree_setup": {
				"phrases": ["animation tree setup", "animationtree setup", "animation tree"],
				"code": """@onready var _tree: AnimationTree = $AnimationTree

func _ready() -> void:
	_tree.active = true
""",
				"params": [],
				"category": "animation",
				"subcategory": "tree",
				"dimension": "any",
				"difficulty": "beginner",
				"details": {
					"what": "Activates an AnimationTree at scene load.",
					"where": "Attach to a node with an AnimationTree child. The AnimationTree needs a tree_root set in the Inspector.",
					"before": "Create an AnimationPlayer with animations, then an AnimationTree pointing at it. Set tree_root in the Inspector to an AnimationNodeStateMachine or AnimationNodeBlendTree.",
					"after": "Use animation_tree_state to switch states, or animation_tree_param to set parameters.",
					"why_optimized": "AnimationTree.active is false by default — enabling it in _ready is the standard pattern.",
					"mistakes": "Forgetting to set the Anim Player property on the AnimationTree means nothing plays.",
					"related": ["animation_tree_state", "animation_tree_param", "animation_play"]
				}
			},
			"animation_tree_state": {
				"phrases": ["animation state", "state machine animation", "switch animation state"],
				"code": """@onready var _tree: AnimationTree = $AnimationTree

func travel_to(state_name: String) -> void:
	_tree.set("parameters/playback", "travel")
	var playback: AnimationNodeStateMachinePlayback = _tree.get("parameters/playback")
	if playback != null:
		playback.travel(state_name)
""",
				"params": ["state_name"],
				"category": "animation",
				"subcategory": "tree",
				"dimension": "any",
				"difficulty": "intermediate",
				"details": {
					"what": "Moves an AnimationTree state machine to a named state.",
					"where": "Attach to a node with an AnimationTree whose tree_root is an AnimationNodeStateMachine.",
					"before": "Set up states in the state machine (idle, walk, jump, etc.) via the AnimationTree panel.",
					"after": "Call travel_to(\"walk\") when movement starts, travel_to(\"idle\") when it stops.",
					"why_optimized": "travel() handles the transition curve automatically.",
					"mistakes": "Calling get() with the wrong path. The path is always 'parameters/playback' for a state machine root.",
					"related": ["animation_tree_setup", "animation_tree_param", "animation_state_machine_2d"]
				}
			},
			"animation_tree_param": {
				"phrases": ["animation parameter", "animation blend param", "set animation param"],
				"code": """@onready var _tree: AnimationTree = $AnimationTree

func set_blend(amount: float) -> void:
	_tree.set("parameters/blend_amount", clamp(amount, 0.0, 1.0))
""",
				"params": ["amount"],
				"category": "animation",
				"subcategory": "tree",
				"dimension": "any",
				"difficulty": "intermediate",
				"details": {
					"what": "Sets a float parameter on an AnimationTree blend node.",
					"where": "Attach to a node with an AnimationTree containing a blend node with a 'blend_amount' parameter.",
					"before": "Create a Blend2 node in the AnimationTree. Name its blend parameter 'blend_amount'.",
					"after": "Use it in _physics_process: set_blend(absf(velocity.x) / max_speed).",
					"why_optimized": "One set() call per frame. No allocation.",
					"mistakes": "Wrong parameter path. Verify it in the AnimationTree panel; each node shows its full parameter path.",
					"related": ["animation_tree_setup", "animation_tree_state", "animation_blend_2d"]
				}
			},
			"animation_blend_2d": {
				"phrases": ["blend 2d", "animation blend space", "directional animation"],
				"code": """@onready var _tree: AnimationTree = $AnimationTree

func set_move_direction(input_dir: Vector2) -> void:
	_tree.set("parameters/move/blend_position", input_dir)
""",
				"params": ["input_dir"],
				"category": "animation",
				"subcategory": "tree",
				"dimension": "2d",
				"difficulty": "intermediate",
				"details": {
					"what": "Drives a BlendSpace2D in the AnimationTree from a movement direction.",
					"where": "Attach to the player. The AnimationTree must have a BlendSpace2D node.",
					"before": "Create a BlendSpace2D with points for each direction (up, down, left, right). Name the parameter path 'parameters/move/blend_position'.",
					"after": "Call set_move_direction(Input.get_vector(...)) in _physics_process.",
					"why_optimized": "BlendSpace2D interpolation is handled by the engine — one set() per frame.",
					"mistakes": "Using a raw Vector2 that isn't normalized means the blend snaps to corners.",
					"related": ["animation_tree_param", "character_movement_2d", "topdown_movement_2d"]
				}
			},
			"animation_state_machine_2d": {
				"phrases": ["animation state machine", "anim state machine", "animation tree state machine"],
				"code": """@onready var _tree: AnimationTree = $AnimationTree
@onready var _playback: AnimationNodeStateMachinePlayback = _tree.get("parameters/playback")

func _ready() -> void:
	_tree.active = true

func set_state(state: StringName) -> void:
	if _playback.get_current_node() == state:
		return
	_playback.travel(state)

func is_in_state(state: StringName) -> bool:
	return _playback.get_current_node() == state
""",
				"params": [],
				"category": "animation",
				"subcategory": "tree",
				"dimension": "any",
				"difficulty": "intermediate",
				"details": {
					"what": "Caches the playback node once and provides set_state / is_in_state helpers.",
					"where": "Attach to a node with an AnimationTree whose root is a state machine.",
					"before": "Set up the state machine with named states in the AnimationTree panel.",
					"after": "Call set_state(&\"run\") from movement code. Use is_in_state(&\"attack\") to gate actions.",
					"why_optimized": "Caches the playback node in an @onready var instead of looking it up every call.",
					"mistakes": "Calling travel() to the current state causes a restart. The early return in set_state prevents that.",
					"related": ["animation_tree_state", "animation_tree_setup", "state_machine"]
				}
			},
			"animation_oneshot": {
				"phrases": ["animation one shot", "play once animation", "one shot animation"],
				"code": """@onready var _tree: AnimationTree = $AnimationTree

func play_oneshot(anim_name: String) -> void:
	_tree.set("parameters/oneshot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	_tree.set("parameters/oneshot/clip", anim_name)
""",
				"params": ["anim_name"],
				"category": "animation",
				"subcategory": "tree",
				"dimension": "any",
				"difficulty": "intermediate",
				"details": {
					"what": "Fires a one-shot animation through an AnimationNodeOneShot.",
					"where": "Attach to a node with an AnimationTree containing a OneShot node named 'oneshot'.",
					"before": "Add an AnimationNodeOneShot to the AnimationTree. Set its animation name to the animation to play.",
					"after": "Use for attacks, hits, or reactions layered on top of a locomotion state machine.",
					"why_optimized": "One-shot nodes handle the return to base animation automatically.",
					"mistakes": "Setting the clip parameter requires the OneShot node's animation property to be a valid animation name.",
					"related": ["animation_state_machine_2d", "animation_tree_state", "combo_attack"]
				}
			}
		}
	}

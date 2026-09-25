@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"snippets": {
			"animation_play": {
				"phrases": ["play animation", "animation play", "start animation", "animationplayer play"],
				"code": """@onready var _anim: AnimationPlayer = $AnimationPlayer

func play_animation(name: String) -> void:
	if _anim.has_animation(name):
		_anim.play(name)
	else:
		push_warning("Animation not found: " + name)
""",
				"params": ["name"],
				"category": "animation",
				"subcategory": "player",
				"dimension": "any",
				"difficulty": "beginner",
				"param_info": {
					"name": {
						"default": "",
						"range": [],
						"what": "The name of the animation to play. Must match an animation in the AnimationPlayer.",
						"typical": "idle, walk, run, jump, attack, hurt",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "Plays a named animation through an AnimationPlayer child.",
					"where": "Attach to a node that has an AnimationPlayer child. AnimationPlayer must contain the animations.",
					"before": "Add an AnimationPlayer node as a child. Create at least one animation in the panel.",
					"after": "Connect animation_finished signal to know when non-looping animations end.",
					"why_optimized": "has_animation() check prevents a silent error when the name is wrong.",
					"mistakes": "Calling play() with a name that doesn't exist fails silently. Always check with has_animation.",
					"related": ["animation_loop", "animation_signal", "animation_queue"]
				}
			},
			"animation_loop": {
				"phrases": ["loop animation", "animation loop", "repeat animation"],
				"code": """@onready var _anim: AnimationPlayer = $AnimationPlayer

func loop_animation(name: String) -> void:
	var anim := _anim.get_animation(name)
	if anim == null:
		return
	anim.loop_mode = Animation.LOOP_LINEAR
	_anim.play(name)
""",
				"params": ["name"],
				"category": "animation",
				"subcategory": "player",
				"dimension": "any",
				"difficulty": "beginner",
				"details": {
					"what": "Forces an animation to loop and plays it.",
					"where": "Any node with an AnimationPlayer child.",
					"before": "The animation must exist in the AnimationPlayer.",
					"after": "For boomerang looping, use Animation.LOOP_PINGPONG instead.",
					"why_optimized": "Sets loop_mode at runtime instead of only via the editor, useful for dynamic cases.",
					"mistakes": "Setting loop_mode on a shared animation affects every user of that animation. Duplicate the animation resource if you need different loop modes.",
					"related": ["animation_play", "animation_signal", "tween_loop"]
				}
			},
			"animation_queue": {
				"phrases": ["queue animation", "animation queue", "chain animations", "play next animation"],
				"code": """@onready var _anim: AnimationPlayer = $AnimationPlayer

func play_sequence(names: Array) -> void:
	if names.is_empty():
		return
	_anim.play(str(names[0]))
	for i in range(1, names.size()):
		_anim.queue(str(names[i]))
""",
				"params": ["names"],
				"category": "animation",
				"subcategory": "player",
				"dimension": "any",
				"difficulty": "intermediate",
				"details": {
					"what": "Plays animations back to back in the order given.",
					"where": "Any node with an AnimationPlayer child.",
					"before": "Every animation in the array must exist in the AnimationPlayer.",
					"after": "Call play_sequence([\"wind_up\", \"strike\", \"recover\"]) for a combo.",
					"why_optimized": "Uses the built-in queue() method rather than awaiting each animation_finished signal.",
					"mistakes": "Queueing an animation that doesn't exist is silently ignored, breaking the sequence.",
					"related": ["animation_play", "animation_signal", "tween_sequence"]
				}
			},
			"animation_signal": {
				"phrases": ["animation finished", "on animation end", "animation signal"],
				"code": """@onready var _anim: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	_anim.animation_finished.connect(_on_animation_finished)

func _on_animation_finished(anim_name: String) -> void:
	print("Animation ended: ", anim_name)
""",
				"params": [],
				"category": "animation",
				"subcategory": "player",
				"dimension": "any",
				"difficulty": "beginner",
				"details": {
					"what": "Fires when a non-looping animation reaches its end.",
					"where": "Any node with an AnimationPlayer child.",
					"before": "The animation must be non-looping, or the signal never fires.",
					"after": "Use the anim_name parameter to branch: if anim_name == \"attack\", then do X.",
					"why_optimized": "Signal-based, no polling of is_playing().",
					"mistakes": "Looping animations never fire this signal.",
					"related": ["animation_play", "animation_loop", "animation_queue"]
				}
			},
			"animation_speed": {
				"phrases": ["animation speed", "animation speed scale", "slow motion animation"],
				"code": """@onready var _anim: AnimationPlayer = $AnimationPlayer

@export var speed_scale: float = 1.0

func _ready() -> void:
	_anim.speed_scale = speed_scale

func set_speed(scale: float) -> void:
	_anim.speed_scale = scale
""",
				"params": ["speed_scale"],
				"category": "animation",
				"subcategory": "player",
				"dimension": "any",
				"difficulty": "beginner",
				"param_info": {
					"speed_scale": {
						"default": 1.0,
						"range": [0.0, 5.0],
						"what": "Multiplier for animation playback speed. 1.0 is normal.",
						"typical": "0.5 slow motion / 1.0 normal / 1.5 fast / 2.0 double speed",
						"increase": "Plays faster. Above 3.0 looks frantic.",
						"decrease": "Plays slower. Zero pauses the animation."
					}
				},
				"details": {
					"what": "Controls how fast all animations play through this AnimationPlayer.",
					"where": "Any node with an AnimationPlayer child.",
					"before": "None.",
					"after": "Tween speed_scale for a slow-motion effect.",
					"why_optimized": "One multiplier affects every animation, no duplication needed.",
					"mistakes": "Setting speed_scale to 0 pauses but doesn't stop. Use pause() if you need that.",
					"related": ["animation_play", "tween_easing", "camera_shake"]
				}
			},
			"tween_sequence": {
				"phrases": ["tween sequence", "chain tween", "tween then", "sequential tween"],
				"code": """func tween_sequence() -> void:
	var t := create_tween()
	t.tween_property(self, "position", Vector2(100, 0), 0.5)
	t.tween_property(self, "position", Vector2(100, 200), 0.5)
	t.tween_property(self, "modulate:a", 0.0, 0.5)
""",
				"params": [],
				"category": "animation",
				"subcategory": "tween",
				"dimension": "2d",
				"difficulty": "beginner",
				"details": {
					"what": "Runs multiple tweens one after another in order.",
					"where": "Any CanvasItem (Node2D, Control, Sprite).",
					"before": "None.",
					"after": "Add .set_trans() and .set_ease() per tween for smoother motion.",
					"why_optimized": "One Tween object handles the whole sequence — no coroutines.",
					"mistakes": "Starting a second tween on the same property while the first runs causes a fight. Chain them or await the first.",
					"related": ["tween_parallel", "tween_callback", "tween_easing"]
				}
			},
			"tween_parallel": {
				"phrases": ["tween parallel", "simultaneous tween", "tween at once"],
				"code": """func tween_parallel() -> void:
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(self, "position", Vector2(200, 100), 0.5)
	t.tween_property(self, "modulate:a", 0.0, 0.5)
	t.tween_property(self, "scale", Vector2(2, 2), 0.5)
""",
				"params": [],
				"category": "animation",
				"subcategory": "tween",
				"dimension": "2d",
				"difficulty": "beginner",
				"details": {
					"what": "Runs multiple tweens at the same time.",
					"where": "Any CanvasItem.",
					"before": "None.",
					"after": "Call .chain() on one tween to make it wait for the others.",
					"why_optimized": "set_parallel(true) flips the whole tween into parallel mode with one line.",
					"mistakes": "Forgetting to call .chain() after a parallel section means the next tween also runs in parallel.",
					"related": ["tween_sequence", "tween_callback", "tween_easing"]
				}
			},
			"tween_callback": {
				"phrases": ["tween callback", "tween then call", "call after tween"],
				"code": """func tween_then_call() -> void:
	var t := create_tween()
	t.tween_property(self, "scale", Vector2(1.5, 1.5), 0.3)
	t.tween_callback(_on_pulse_done)

func _on_pulse_done() -> void:
	print("Pulse finished")
""",
				"params": [],
				"category": "animation",
				"subcategory": "tween",
				"dimension": "any",
				"difficulty": "beginner",
				"details": {
					"what": "Runs a function after a tween completes, inside the tween's own sequence.",
					"where": "Anywhere you can call create_tween().",
					"before": "None.",
					"after": "Chain multiple callbacks for a scripted sequence.",
					"why_optimized": "Keeps the timing inside the tween — no await, no state tracking.",
					"mistakes": "Calling a method on a node that might be freed by then. Guard with is_instance_valid in the callback.",
					"related": ["tween_sequence", "tween_parallel", "tween_loop"]
				}
			}
		}
	}

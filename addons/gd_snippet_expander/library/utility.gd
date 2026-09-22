@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"snippets": {
			"signal_connect": {
				"phrases": ["connect signal", "signal connect", "connect"],
				"code": """func _ready() -> void:
	some_node.some_signal.connect(_on_some_signal)

func _on_some_signal(arg: Variant) -> void:
	print(arg)
""",
				"params": [],
				"category": "utility",
				"dimension": "any",
				"difficulty": "beginner",
				"details": {
					"what": "Connects a signal to a handler function in code.",
					"where": "Any node that needs to react to another node's signal.",
					"before": "The target node must have the signal defined.",
					"after": "For one-shot connections, add CONNECT_ONE_SHOT flag.",
					"why_optimized": "Code connections are visible in the file, unlike editor connections.",
					"mistakes": "Connecting twice runs the handler twice per signal. Check with is_connected first.",
					"related": ["health_signal", "item_pickup_signal", "button_pressed"]
				}
			},
			"tween_move": {
				"phrases": ["tween move", "move tween", "animate position"],
				"code": """func move_to(target_position: Vector2, duration: float = 0.5) -> void:
	var tween := create_tween()
	tween.tween_property(self, "position", target_position, duration).set_trans(Tween.TRANS_SINE)
""",
				"params": ["target_position", "duration"],
				"category": "utility",
				"dimension": "2d",
				"difficulty": "beginner",
				"param_info": {
					"target_position": {
						"default": [0, 0],
						"range": [],
						"what": "The destination Vector2.",
						"typical": "any world or local position",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"duration": {
						"default": 0.5,
						"range": [0.05, 10.0],
						"what": "How long the move takes, in seconds.",
						"typical": "0.2 snappy / 0.5 standard / 2.0 slow",
						"increase": "Slower, more visible.",
						"decrease": "Faster, more abrupt."
					}
				},
				"details": {
					"what": "Smoothly moves a node from current position to target using a Tween.",
					"where": "Any Node2D. Call move_to() with the destination.",
					"before": "None.",
					"after": "Chain more tweens for parallel or sequential effects.",
					"why_optimized": "Tween is a lightweight, auto-freed animation.",
					"mistakes": "Starting a second tween on the same property while one is running causes flicker.",
					"related": ["tween_fade", "audio_fade", "camera_shake"]
				}
			},
			"tween_fade": {
				"phrases": ["tween fade", "fade tween", "fade out"],
				"code": """func fade_to(target_alpha: float, duration: float = 0.5) -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", target_alpha, duration)
""",
				"params": ["target_alpha", "duration"],
				"category": "utility",
				"dimension": "any",
				"difficulty": "beginner",
				"param_info": {
					"target_alpha": {
						"default": 1.0,
						"range": [0.0, 1.0],
						"what": "Final alpha. 0 is invisible, 1 is fully opaque.",
						"typical": "0 fade out / 1 fade in / 0.5 translucent",
						"increase": "More visible.",
						"decrease": "More transparent."
					},
					"duration": {
						"default": 0.5,
						"range": [0.05, 10.0],
						"what": "Length of the fade.",
						"typical": "0.2 quick / 0.5 standard / 2.0 slow",
						"increase": "Slower fade.",
						"decrease": "Faster fade."
					}
				},
				"details": {
					"what": "Fades a node's alpha from current to a target value.",
					"where": "Any CanvasItem — Node2D, Control, Sprite.",
					"before": "None.",
					"after": "Use await get_tree().create_tween().finished to run code after fading.",
					"why_optimized": "Tween property binding avoids per-frame code.",
					"mistakes": "Setting modulate.a directly instead of via tween snaps instantly — no fade.",
					"related": ["tween_move", "fade_in_ui", "audio_fade"]
				}
			},
			"random_range": {
				"phrases": ["random number", "random range", "randf randi"],
				"code": """func random_int(min_value: int, max_value: int) -> int:
	return randi_range(min_value, max_value)

func random_float(min_value: float, max_value: float) -> float:
	return randf_range(min_value, max_value)
""",
				"params": [],
				"category": "utility",
				"dimension": "any",
				"difficulty": "beginner",
				"details": {
					"what": "Two helpers for random integers and floats in a range.",
					"where": "Any script.",
					"before": "None.",
					"after": "For seeded randomness, call seed(n) before using.",
					"why_optimized": "randi_range and randf_range are native — no manual math.",
					"mistakes": "Using randf() * n + offset is less clear than randf_range.",
					"related": ["array_shuffle", "wander_ai", "camera_shake"]
				}
			},
			"singleton_pattern": {
				"phrases": ["singleton", "autoload singleton", "global singleton"],
				"code": """extends Node

static var _instance: Node = null

static func instance() -> Node:
	return _instance

func _enter_tree() -> void:
	if _instance == null:
		_instance = self
	else:
		queue_free()
""",
				"params": [],
				"category": "utility",
				"dimension": "any",
				"difficulty": "intermediate",
				"details": {
					"what": "A classic singleton. Only one instance can exist. Access via ClassName.instance().",
					"where": "Attach to any Node. Register it in Project Settings > Autoload for global access.",
					"before": "Add the script as an autoload in Project Settings for it to work globally.",
					"after": "Access from anywhere with MySingleton.instance().some_method().",
					"why_optimized": "Static var is a single global — no get_node lookup.",
					"mistakes": "Forgetting to register as autoload means the singleton is never instantiated.",
					"related": ["signal_connect", "inventory_system", "settings_save"]
				}
			},
			"debug_print": {
				"phrases": ["debug print", "print debug", "log message"],
				"code": """func debug_print(message: String) -> void:
	if OS.is_debug_build():
		print("[DEBUG] ", message)
""",
				"params": ["message"],
				"category": "utility",
				"dimension": "any",
				"difficulty": "beginner",
				"param_info": {
					"message": {
						"default": "",
						"range": [],
						"what": "The string to print.",
						"typical": "any diagnostic text",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "Prints a message only in debug builds. Silent in exported games.",
					"where": "Anywhere you need debug output.",
					"before": "None.",
					"after": "For richer output, use print_debug or push_warning.",
					"why_optimized": "is_debug_build check is evaluated once per call — negligible cost.",
					"mistakes": "Using plain print() ships debug messages to the release game's logs.",
					"related": ["get_node_safe", "array_shuffle", "dictionary_loop"]
				}
			},
			"array_shuffle": {
				"phrases": ["shuffle array", "randomize array", "shuffle"],
				"code": """func shuffle_array(array: Array) -> Array:
	var copy := array.duplicate()
	copy.shuffle()
	return copy
""",
				"params": ["array"],
				"category": "utility",
				"dimension": "any",
				"difficulty": "beginner",
				"param_info": {
					"array": {
						"default": [],
						"range": [],
						"what": "The array to shuffle.",
						"typical": "any array",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "Returns a shuffled copy of an array, leaving the original untouched.",
					"where": "Anywhere you need a randomized list.",
					"before": "None.",
					"after": "For in-place shuffle, call array.shuffle() directly.",
					"why_optimized": "duplicate() then shuffle() avoids mutating the caller's data.",
					"mistakes": "Shuffling in place can surprise other code that shares the array.",
					"related": ["random_range", "wander_ai", "damage_number_popup"]
				}
			},
			"dictionary_loop": {
				"phrases": ["loop dictionary", "iterate dictionary", "foreach dict"],
				"code": """func loop_dict(data: Dictionary) -> void:
	for key in data.keys():
		var value: Variant = data[key]
		print(key, " = ", value)
""",
				"params": ["data"],
				"category": "utility",
				"dimension": "any",
				"difficulty": "beginner",
				"param_info": {
					"data": {
						"default": {},
						"range": [],
						"what": "The Dictionary to iterate.",
						"typical": "any dictionary",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "Iterates a Dictionary and prints key-value pairs.",
					"where": "Anywhere you need to inspect a dictionary.",
					"before": "None.",
					"after": "Replace print with your actual per-entry logic.",
					"why_optimized": "Calls .keys() once instead of iterating and rechecking keys.",
					"mistakes": "Modifying the dictionary while iterating it crashes. Duplicate first.",
					"related": ["inventory_system", "load_json", "save_json"]
				}
			},
			"get_node_safe": {
				"phrases": ["safe get node", "get node safe", "safe node lookup"],
				"code": """func get_node_safe(path: NodePath) -> Node:
	if has_node(path):
		return get_node(path)
	push_warning("Node not found: ", path)
	return null
""",
				"params": ["path"],
				"category": "utility",
				"dimension": "any",
				"difficulty": "beginner",
				"param_info": {
					"path": {
						"default": "",
						"range": [],
						"what": "NodePath to look up.",
						"typical": "$Child or a NodePath from a signal",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "Like get_node but returns null instead of crashing if missing.",
					"where": "Anywhere you'd use get_node but the node might not exist.",
					"before": "None.",
					"after": "Combine with has_method or is_instance_valid checks before use.",
					"why_optimized": "has_node is a fast tree lookup, done once.",
					"mistakes": "Forgetting to check the return value for null means the crash moves one line down.",
					"related": ["debug_print", "signal_connect", "singleton_pattern"]
				}
			},
			"await_timer": {
				"phrases": ["await timer", "wait seconds", "delay await"],
				"code": """func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
""",
				"params": ["seconds"],
				"category": "utility",
				"dimension": "any",
				"difficulty": "beginner",
				"param_info": {
					"seconds": {
						"default": 1.0,
						"range": [0.01, 3600.0],
						"what": "How long to wait before the next line runs.",
						"typical": "0.1 quick pause / 1.0 standard / 5.0 cinematic",
						"increase": "Longer pause.",
						"decrease": "Shorter pause."
					}
				},
				"details": {
					"what": "Waits the given time, then continues. Makes coroutines simple.",
					"where": "Any async function that needs to pause mid-execution.",
					"before": "The calling function must be async (uses await).",
					"after": "Chain multiple await wait() calls for a sequence.",
					"why_optimized": "await is a coroutine — no Timer node, no state machine.",
					"mistakes": "Forgetting await at the call site means wait() returns instantly and doesn't pause.",
					"related": ["timer", "transition_scene", "audio_fade"]
				}
			},
			"raycast_2d": {
				"phrases": ["raycast 2d", "ray cast 2d", "line of sight 2d"],
				"code": """@export var ray_length: float = 500.0

func cast_ray_2d(from: Vector2, direction: Vector2) -> Dictionary:
	var space := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(from, from + direction * ray_length)
	return space.intersect_ray(query)
""",
				"params": ["ray_length"],
				"category": "utility",
				"dimension": "2d",
				"difficulty": "intermediate",
				"param_info": {
					"ray_length": {
						"default": 500.0,
						"range": [10.0, 5000.0],
						"what": "How far the ray reaches, in pixels.",
						"typical": "100 melee / 500 gun / 2000+ sight line",
						"increase": "Longer reach.",
						"decrease": "Shorter reach."
					}
				},
				"details": {
					"what": "Casts a ray from a point and returns what it hits.",
					"where": "Any node with access to the 2D world.",
					"before": "None.",
					"after": "Check the returned Dictionary for 'collider' — that's what was hit.",
					"why_optimized": "direct_space_state has no scene-tree overhead unlike a RayCast2D node.",
					"mistakes": "An empty Dictionary means nothing was hit. Always check has(\"collider\") first.",
					"related": ["raycast_3d", "look_for_player", "camera_deadzone"]
				}
			},
			"raycast_3d": {
				"phrases": ["raycast 3d", "ray cast 3d", "line of sight 3d"],
				"code": """@export var ray_length: float = 1000.0

func cast_ray_3d(from: Vector3, direction: Vector3) -> Dictionary:
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, from + direction * ray_length)
	return space.intersect_ray(query)
""",
				"params": ["ray_length"],
				"category": "utility",
				"dimension": "3d",
				"difficulty": "intermediate",
				"param_info": {
					"ray_length": {
						"default": 1000.0,
						"range": [10.0, 10000.0],
						"what": "How far the ray reaches, in meters.",
						"typical": "5 short / 100 gun / 1000+ sight line",
						"increase": "Longer reach.",
						"decrease": "Shorter reach."
					}
				},
				"details": {
					"what": "Casts a ray from a point in a direction and returns what it hits.",
					"where": "Any Node3D with access to the 3D world.",
					"before": "None.",
					"after": "Check the returned Dictionary for 'collider'.",
					"why_optimized": "direct_space_state avoids per-cast overhead.",
					"mistakes": "Empty Dictionary means no hit. Always check.",
					"related": ["raycast_2d", "first_person_movement", "look_for_player"]
				}
			}
		}
	}

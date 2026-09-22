@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"snippets": {
			"change_scene": {
				"phrases": ["change scene", "switch scene", "load scene"],
				"code": """func change_scene(path: String) -> void:
	get_tree().change_scene_to_file(path)
""",
				"params": ["path"],
				"category": "scene",
				"dimension": "any",
				"difficulty": "beginner",
				"param_info": {
					"path": {
						"default": "",
						"range": [],
						"what": "res:// path to the scene to load.",
						"typical": "res://levels/level_2.tscn",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "Loads a new scene from a file path, replacing the current one.",
					"where": "Attach to any node that needs to trigger a scene change.",
					"before": "None.",
					"after": "For async loading with a loading screen, use loading_screen instead.",
					"why_optimized": "Direct engine call, no allocation.",
					"mistakes": "Typo in the path crashes at runtime. Double-check with the FileSystem panel.",
					"related": ["reload_scene", "transition_scene", "preload_scene", "loading_screen"]
				}
			},
			"reload_scene": {
				"phrases": ["reload scene", "restart scene", "reset scene"],
				"code": """func reload_scene() -> void:
	get_tree().reload_current_scene()
""",
				"params": [],
				"category": "scene",
				"dimension": "any",
				"difficulty": "beginner",
				"details": {
					"what": "Restarts the current scene from scratch. Perfect for retry buttons.",
					"where": "Call from a game over or retry button.",
					"before": "None.",
					"after": "Make sure to unpause first if the scene is paused.",
					"why_optimized": "Atomic — the engine handles teardown and rebuild.",
					"mistakes": "Calling while paused leaves the new scene paused. Use get_tree().paused = false first.",
					"related": ["change_scene", "game_over_screen", "pause_game"]
				}
			},
			"pause_game": {
				"phrases": ["pause game", "pause", "resume game"],
				"code": """func toggle_pause() -> void:
	get_tree().paused = not get_tree().paused
""",
				"params": [],
				"category": "scene",
				"dimension": "any",
				"difficulty": "beginner",
				"details": {
					"what": "Flips the paused state of the entire scene tree.",
					"where": "Call from an input handler or a UI button.",
					"before": "Nodes that should keep working while paused need process_mode = ALWAYS.",
					"after": "For a full pause UI with buttons, use pause_menu instead.",
					"why_optimized": "Single property flip — no manual pausing of individual nodes.",
					"mistakes": "Pausing without a way to unpause traps the player. Always have an Escape action.",
					"related": ["pause_menu", "reload_scene", "quit_game"]
				}
			},
			"quit_game": {
				"phrases": ["quit game", "exit game", "close game"],
				"code": """func quit_game() -> void:
	get_tree().quit()
""",
				"params": [],
				"category": "scene",
				"dimension": "any",
				"difficulty": "beginner",
				"details": {
					"what": "Closes the game cleanly.",
					"where": "Call from a Quit button in a menu.",
					"before": "None.",
					"after": "Optionally save the game before quitting.",
					"why_optimized": "Direct engine call — the cleanest way to exit.",
					"mistakes": "Calling quit() from _process or a loop misses cleanup. Call from a signal or input handler.",
					"related": ["main_menu", "pause_menu", "save_game"]
				}
			},
			"instantiate_scene": {
				"phrases": ["instantiate scene", "spawn scene", "load scene instance"],
				"code": """func spawn(scene: PackedScene, parent: Node, position: Vector2) -> Node:
	var instance := scene.instantiate()
	parent.add_child(instance)
	if instance is Node2D:
		instance.global_position = position
	return instance
""",
				"params": ["scene", "parent", "position"],
				"category": "scene",
				"dimension": "2d",
				"difficulty": "beginner",
				"param_info": {
					"scene": {
						"default": "",
						"range": [],
						"what": "The PackedScene to instantiate.",
						"typical": "a bullet, enemy, or pickup .tscn",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"parent": {
						"default": "",
						"range": [],
						"what": "Where the instance is added in the scene tree.",
						"typical": "get_tree().current_scene",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"position": {
						"default": [0, 0],
						"range": [],
						"what": "World position to place the new instance.",
						"typical": "spawner.global_position",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "Generic spawn helper. Instantiates, adds, positions, and returns the node.",
					"where": "Attach to a spawner or game manager.",
					"before": "You need the PackedScene reference in the Inspector or via preload.",
					"after": "For spawning at intervals, combine with spawn_prefab.",
					"why_optimized": "Returns the instance so callers can configure it without another lookup.",
					"mistakes": "Forgetting add_child means the instance exists but isn't in the scene.",
					"related": ["spawn_prefab", "preload_scene", "change_scene"]
				}
			},
			"spawn_prefab": {
				"phrases": ["spawn prefab", "spawn enemy", "spawn object"],
				"code": """@export var prefab: PackedScene
@export var spawn_interval: float = 3.0

func _ready() -> void:
	var timer := Timer.new()
	timer.wait_time = spawn_interval
	timer.autostart = true
	timer.timeout.connect(_spawn)
	add_child(timer)

func _spawn() -> void:
	if prefab:
		var node := prefab.instantiate()
		add_child(node)
""",
				"params": ["prefab", "spawn_interval"],
				"category": "scene",
				"dimension": "any",
				"difficulty": "beginner",
				"param_info": {
					"prefab": {
						"default": "",
						"range": [],
						"what": "The PackedScene to spawn repeatedly.",
						"typical": "enemy, bullet, particle effect",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"spawn_interval": {
						"default": 3.0,
						"range": [0.1, 60.0],
						"what": "Seconds between spawns.",
						"typical": "0.5 fast / 3.0 standard / 10+ slow",
						"increase": "Fewer spawns.",
						"decrease": "More spawns — watch performance."
					}
				},
				"details": {
					"what": "Spawns a prefab on a repeating interval using an internal Timer.",
					"where": "Attach to a spawner node. Set prefab in the Inspector.",
					"before": "Assign a PackedScene to the prefab slot.",
					"after": "Randomize position and add a spawn animation for polish.",
					"why_optimized": "Timer node handles scheduling, no _process needed.",
					"mistakes": "Spawning every frame floods the scene. Always use an interval.",
					"related": ["instantiate_scene", "timer", "spawn_prefab"]
				}
			},
			"transition_scene": {
				"phrases": ["scene transition", "fade transition", "fade to black"],
				"code": """@onready var _overlay: ColorRect = $ColorRect

func transition_to(path: String) -> void:
	var tween := create_tween()
	tween.tween_property(_overlay, "modulate:a", 1.0, 0.4)
	await tween.finished
	get_tree().change_scene_to_file(path)
""",
				"params": ["path"],
				"category": "scene",
				"dimension": "any",
				"difficulty": "intermediate",
				"param_info": {
					"path": {
						"default": "",
						"range": [],
						"what": "res:// path of the scene to load after the fade.",
						"typical": "res://levels/level_2.tscn",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "Fades the screen to black, then loads a new scene.",
					"where": "Attach to a CanvasLayer with a full-screen ColorRect child. Set the ColorRect's color to black and modulate.a to 0.",
					"before": "Add a CanvasLayer with a ColorRect covering the screen. Set layer high so it's above everything.",
					"after": "Add a second tween to fade back in when the new scene loads.",
					"why_optimized": "await tween.finished keeps the transition sequential and clean.",
					"mistakes": "Forgetting to set modulate.a to 0 means the screen is already black on load.",
					"related": ["fade_in_ui", "change_scene", "loading_screen"]
				}
			},
			"preload_scene": {
				"phrases": ["preload scene", "preload resource", "preload"],
				"code": """const SCENE := preload("res://path/to/scene.tscn")

func _ready() -> void:
	var instance := SCENE.instantiate()
	add_child(instance)
""",
				"params": [],
				"category": "scene",
				"dimension": "any",
				"difficulty": "beginner",
				"details": {
					"what": "Loads a scene at parse time (before the game runs) and instantiates it.",
					"where": "Any node that needs an instance of a known scene at startup.",
					"before": "Replace the path with your actual scene path.",
					"after": "For runtime paths, use load() or instantiate_scene instead.",
					"why_optimized": "preload is faster than load() at runtime because the file is already in memory.",
					"mistakes": "preload of a missing file breaks the whole script at parse time. Verify the path.",
					"related": ["instantiate_scene", "change_scene", "spawn_prefab"]
				}
			},
			"timer": {
				"phrases": ["timer", "create timer", "delay"],
				"code": """func delayed_call(delay: float, callback: Callable) -> void:
	get_tree().create_timer(delay).timeout.connect(callback)
""",
				"params": ["delay", "callback"],
				"category": "scene",
				"dimension": "any",
				"difficulty": "beginner",
				"param_info": {
					"delay": {
						"default": 1.0,
						"range": [0.01, 3600.0],
						"what": "Seconds to wait before calling the callback.",
						"typical": "0.1 fast / 1.0 standard / 5.0+ cinematic",
						"increase": "Longer wait.",
						"decrease": "Shorter wait."
					},
					"callback": {
						"default": null,
						"range": [],
						"what": "A Callable — the function to run after the delay.",
						"typical": "my_function or func(): print(\"done\")",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "Calls a function after a delay without needing a Timer node.",
					"where": "Anywhere you need a one-shot delay.",
					"before": "None.",
					"after": "Use await create_timer(delay).timeout for sequential code.",
					"why_optimized": "Creates the Timer in the scene tree, cleaned up automatically.",
					"mistakes": "Holding a reference to the timer after it fires — it's already freed.",
					"related": ["spawn_prefab", "await_timer", "autosave"]
				}
			}
		}
	}

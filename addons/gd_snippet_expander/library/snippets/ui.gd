@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"snippets": {
			"health_bar_ui": {
				"phrases": ["health bar ui", "health ui", "hp bar ui"],
				"code": """extends ProgressBar

@export var player_path: NodePath

@onready var _player: Node = get_node(player_path)

func _ready() -> void:
	if _player.has_signal("health_changed"):
		_player.health_changed.connect(_on_health_changed)

func _on_health_changed(current: int) -> void:
	value = float(current)
""",
				"params": ["player_path"],
				"category": "ui",
				"dimension": "ui",
				"difficulty": "beginner",
				"param_info": {
					"player_path": {
						"default": "",
						"range": [],
						"what": "Path to the node that has health_changed.",
						"typical": "NodePath from UI to player",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "A ProgressBar that reads the player's health from a remote node.",
					"where": "Attach to a ProgressBar in a CanvasLayer. Set player_path in the Inspector.",
					"before": "The player must have health_system with health_changed signal.",
					"after": "Set ProgressBar's max_value to match max_health in the Inspector.",
					"why_optimized": "Signal-based — no per-frame polling of the player's health.",
					"mistakes": "Forgetting to set max_value on the ProgressBar leaves the bar looking wrong.",
					"related": ["health_system", "health_bar", "score_display"]
				}
			},
			"score_display": {
				"phrases": ["score display", "score ui", "show score"],
				"code": """extends Label

var score: int = 0

func add_score(amount: int) -> void:
	score += amount
	text = "Score: %d" % score
""",
				"params": [],
				"category": "ui",
				"dimension": "ui",
				"difficulty": "beginner",
				"details": {
					"what": "A Label that shows the current score and updates when points are added.",
					"where": "Attach to a Label inside a CanvasLayer.",
					"before": "None.",
					"after": "Call add_score(100) when a coin is collected.",
					"why_optimized": "String formatting only happens when score changes, not every frame.",
					"mistakes": "Updating text every frame in _process wastes CPU for a value that rarely changes.",
					"related": ["coin_pickup", "health_bar_ui", "countdown_timer_ui"]
				}
			},
			"pause_menu": {
				"phrases": ["pause menu", "pause screen", "pause ui"],
				"code": """extends CanvasLayer

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func toggle_pause() -> void:
	var paused := not get_tree().paused
	get_tree().paused = paused
	visible = paused
""",
				"params": [],
				"category": "ui",
				"dimension": "ui",
				"difficulty": "beginner",
				"details": {
					"what": "A CanvasLayer that pauses the game when Escape is pressed.",
					"where": "Attach to a CanvasLayer. Add a Panel or ColorRect as a child so it covers the screen.",
					"before": "None. ui_cancel is Godot's built-in Escape action.",
					"after": "Add Button nodes for Resume / Restart / Quit. Connect their pressed signals.",
					"why_optimized": "process_mode = ALWAYS keeps the menu responsive while the game is paused.",
					"mistakes": "Forgetting process_mode = ALWAYS means the pause menu itself is frozen and can't unpause.",
					"related": ["main_menu", "game_over_screen", "options_menu"]
				}
			},
			"game_over_screen": {
				"phrases": ["game over screen", "game over", "death screen"],
				"code": """extends CanvasLayer

@export var menu_scene: PackedScene

func show_game_over() -> void:
	visible = true
	get_tree().paused = true

func restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
""",
				"params": ["menu_scene"],
				"category": "ui",
				"dimension": "ui",
				"difficulty": "beginner",
				"param_info": {
					"menu_scene": {
						"default": "",
						"range": [],
						"what": "Scene to return to if the player quits the game over screen.",
						"typical": "the main menu scene",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "A CanvasLayer that shows when the player dies. Pauses the game.",
					"where": "Attach to a CanvasLayer. Hidden by default in the Inspector.",
					"before": "Connect the player's died signal to show_game_over().",
					"after": "Add a Retry button that calls restart().",
					"why_optimized": "reload_current_scene is atomic — no need to reset state manually.",
					"mistakes": "Forgetting to unpause before reloading means the new scene starts paused.",
					"related": ["health_system", "respawn", "pause_menu", "main_menu"]
				}
			},
			"main_menu": {
				"phrases": ["main menu", "start menu", "title screen"],
				"code": """@export var game_scene: PackedScene

func _on_start_pressed() -> void:
	get_tree().change_scene_to_packed(game_scene)

func _on_quit_pressed() -> void:
	get_tree().quit()
""",
				"params": ["game_scene"],
				"category": "ui",
				"dimension": "ui",
				"difficulty": "beginner",
				"param_info": {
					"game_scene": {
						"default": "",
						"range": [],
						"what": "The game scene to load when Start is pressed.",
						"typical": "your main level scene",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "Two functions for Start and Quit buttons.",
					"where": "Attach to the root of your main menu scene.",
					"before": "Add Button nodes named Start and Quit.",
					"after": "Connect each button's pressed signal to the matching function.",
					"why_optimized": "change_scene_to_packed is the modern Godot 4 API — faster than the old string path.",
					"mistakes": "Using change_scene_to_file is slower and requires a String path.",
					"related": ["pause_menu", "options_menu", "change_scene"]
				}
			},
			"button_pressed": {
				"phrases": ["button pressed", "connect button", "button signal"],
				"code": """@onready var _button: Button = $Button

func _ready() -> void:
	_button.pressed.connect(_on_button_pressed)

func _on_button_pressed() -> void:
	print("Button pressed")
""",
				"params": [],
				"category": "ui",
				"dimension": "ui",
				"difficulty": "beginner",
				"details": {
					"what": "Connects a Button's pressed signal to a function.",
					"where": "Attach to the parent of the Button. Assumes a child named 'Button'.",
					"before": "Add a Button node as a child of the script's node.",
					"after": "Replace print with real logic.",
					"why_optimized": "Signal connection via code — no editor connection needed.",
					"mistakes": "Connecting the same signal twice causes the function to run twice per click.",
					"related": ["main_menu", "pause_menu", "game_over_screen"]
				}
			},
			"fade_in_ui": {
				"phrases": ["fade in ui", "fade ui in", "ui fade"],
				"code": """extends CanvasLayer

@onready var _rect: ColorRect = $ColorRect

func _ready() -> void:
	_rect.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_property(_rect, "modulate:a", 0.0, 0.6)
""",
				"params": [],
				"category": "ui",
				"dimension": "ui",
				"difficulty": "beginner",
				"details": {
					"what": "Fades a ColorRect overlay from opaque to transparent on load. Standard scene intro.",
					"where": "Attach to a CanvasLayer. Add a ColorRect child that covers the screen.",
					"before": "Add a ColorRect child. Set its color to black in the Inspector.",
					"after": "Reverse for a fade-out when leaving the scene.",
					"why_optimized": "Tween handles the math; no _process needed.",
					"mistakes": "Forgetting to set modulate.a = 1.0 in _ready means the fade starts from whatever the Inspector has.",
					"related": ["transition_scene", "loading_screen", "pause_menu"]
				}
			},
			"countdown_timer_ui": {
				"phrases": ["countdown timer", "countdown ui", "timer display"],
				"code": """extends Label

@export var duration: float = 60.0
var _time_left: float = 0.0

func _ready() -> void:
	_time_left = duration

func _process(delta: float) -> void:
	_time_left = max(_time_left - delta, 0.0)
	text = "%02d:%02d" % [int(_time_left) / 60, int(_time_left) % 60]
""",
				"params": ["duration"],
				"category": "ui",
				"dimension": "ui",
				"difficulty": "beginner",
				"param_info": {
					"duration": {
						"default": 60.0,
						"range": [5.0, 3600.0],
						"what": "Countdown length in seconds.",
						"typical": "30 speedrun / 60 standard level / 300+ long mission",
						"increase": "Longer mission.",
						"decrease": "More pressure."
					}
				},
				"details": {
					"what": "A Label that shows MM:SS time remaining.",
					"where": "Attach to a Label inside a CanvasLayer.",
					"before": "None.",
					"after": "Emit a signal when _time_left hits 0 for game over.",
					"why_optimized": "max() clamps to 0 so the timer doesn't go negative.",
					"mistakes": "Forgetting max() lets the timer display -1, -2, etc. after expiring.",
					"related": ["score_display", "pause_menu", "game_over_screen"]
				}
			},
			"dialog_box": {
				"phrases": ["dialog box", "dialogue box", "npc dialog"],
				"code": """extends CanvasLayer

signal dialog_finished

@onready var _label: Label = $Panel/Label

var _lines: Array[String] = []
var _index: int = 0

func start_dialog(lines: Array[String]) -> void:
	_lines = lines
	_index = 0
	visible = true
	_show_current()

func _show_current() -> void:
	if _index >= _lines.size():
		visible = false
		dialog_finished.emit()
		return
	_label.text = _lines[_index]

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_accept"):
		_index += 1
		_show_current()
""",
				"params": [],
				"category": "ui",
				"dimension": "ui",
				"difficulty": "intermediate",
				"details": {
					"what": "A simple sequential dialog box. Shows one line per Space press.",
					"where": "Attach to a CanvasLayer. Add a Panel with a Label child named 'Label' inside.",
					"before": "None. ui_accept is Godot's built-in Space/Enter action.",
					"after": "Add a typewriter effect — reveal each line character by character.",
					"why_optimized": "Array of strings, no external data. Signal emits when done.",
					"mistakes": "Forgetting to hide the dialog after the last line leaves it stuck on screen.",
					"related": ["button_pressed", "main_menu", "ui_fade"]
				}
			},
			"options_menu": {
				"phrases": ["options menu", "settings menu", "config menu"],
				"code": """@onready var _master_slider: HSlider = $MasterSlider

func _ready() -> void:
	_master_slider.value_changed.connect(_on_master_changed)

func _on_master_changed(value: float) -> void:
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus, linear_to_db(value))
""",
				"params": [],
				"category": "ui",
				"dimension": "ui",
				"difficulty": "beginner",
				"details": {
					"what": "Wires a slider to the master audio bus volume.",
					"where": "Attach to the options menu root. Add an HSlider named 'MasterSlider'.",
					"before": "Add the slider in the scene with range 0.0 to 1.0, default 1.0.",
					"after": "Add more sliders for Music, SFX, and other buses.",
					"why_optimized": "linear_to_db converts slider (0-1) to dB automatically.",
					"mistakes": "Forgetting linear_to_db makes the volume curve feel wrong — audio uses dB, not linear.",
					"related": ["pause_menu", "main_menu", "audio_bus_volume"]
				}
			},
			"loading_screen": {
				"phrases": ["loading screen", "loading ui", "async load"],
				"code": """extends CanvasLayer

@export var scene_path: String = ""

func _ready() -> void:
	if scene_path.is_empty():
		return
	ResourceLoader.load_threaded_request(scene_path)

func _process(_delta: float) -> void:
	var progress: Array = []
	var status := ResourceLoader.load_threaded_get_status(scene_path, progress)
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		var scene := ResourceLoader.load_threaded_get(scene_path) as PackedScene
		get_tree().change_scene_to_packed(scene)
""",
				"params": ["scene_path"],
				"category": "ui",
				"dimension": "ui",
				"difficulty": "intermediate",
				"param_info": {
					"scene_path": {
						"default": "",
						"range": [],
						"what": "The res:// path of the scene to load in the background.",
						"typical": "res://levels/level_2.tscn",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "Loads a scene asynchronously and switches to it when ready.",
					"where": "Attach to a CanvasLayer. Show a spinner or text while loading.",
					"before": "Set scene_path in the Inspector to the target scene.",
					"after": "Use the progress array to drive a ProgressBar.",
					"why_optimized": "Threaded loading keeps the UI responsive during the load.",
					"mistakes": "Calling change_scene_to_file directly blocks the frame — this avoids that.",
					"related": ["change_scene", "transition_scene", "fade_in_ui"]
				}
			},
			"tooltip": {
				"phrases": ["tooltip", "hover tooltip", "show tooltip"],
				"code": """extends Control

@export var text: String = ""

func _ready() -> void:
	tooltip_text = text
	mouse_entered.connect(_on_enter)
	mouse_exited.connect(_on_exit)

func _on_enter() -> void:
	modulate = Color(1.2, 1.2, 1.2)

func _on_exit() -> void:
	modulate = Color.WHITE
""",
				"params": ["text"],
				"category": "ui",
				"dimension": "ui",
				"difficulty": "beginner",
				"param_info": {
					"text": {
						"default": "",
						"range": [],
						"what": "The tooltip string shown on hover.",
						"typical": "short description of the button or item",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "Sets the tooltip text and brightens the Control on hover.",
					"where": "Attach to any Control node — Button, Panel, custom widget.",
					"before": "Set the 'text' property in the Inspector.",
					"after": "For dynamic tooltips, update text at runtime.",
					"why_optimized": "tooltip_text is built-in — Godot shows the popup automatically.",
					"mistakes": "Setting tooltip_text every frame in _process is wasteful.",
					"related": ["button_pressed", "inventory_system", "main_menu"]
				}
			}
		}
	}

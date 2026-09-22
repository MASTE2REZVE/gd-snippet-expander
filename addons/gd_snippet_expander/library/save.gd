@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"snippets": {
			"save_game": {
				"phrases": ["save game", "save", "save data"],
				"code": """const SAVE_PATH := "user://save.json"

func save_game(data: Dictionary) -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()
""",
				"params": ["data"],
				"category": "save",
				"dimension": "any",
				"difficulty": "beginner",
				"param_info": {
					"data": {
						"default": {},
						"range": [],
						"what": "Dictionary containing whatever you want to persist — player position, health, score, inventory.",
						"typical": "{\"health\": 75, \"level\": 3, \"score\": 1200}",
						"increase": "More data saved. Keep it small — this is meant to be JSON-serializable.",
						"decrease": "Minimal save, fastest."
					}
				},
				"details": {
					"what": "Writes a Dictionary to a JSON file in user:// (persists across runs).",
					"where": "Attach to a game manager node or make it an autoload.",
					"before": "Build a Dictionary of what you want to save.",
					"after": "Use load_game to read it back. For multiple slots, use save_slot instead.",
					"why_optimized": "FileAccess is a direct file handle. No ResourceSaver overhead.",
					"mistakes": "Saving to res:// won't work at runtime — always use user://.",
					"related": ["load_game", "save_json", "save_slot", "autosave"]
				}
			},
			"load_game": {
				"phrases": ["load game", "load save", "load data"],
				"code": """const SAVE_PATH := "user://save.json"

func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return {}
	return json.data as Dictionary
""",
				"params": [],
				"category": "save",
				"dimension": "any",
				"difficulty": "beginner",
				"details": {
					"what": "Reads the JSON save file and returns it as a Dictionary. Returns {} if missing or corrupt.",
					"where": "Attach to the same node as save_game.",
					"before": "None. Safe to call even if no save exists — returns empty.",
					"after": "Apply the loaded values to your game state.",
					"why_optimized": "Checks file_exists first, avoiding an exception. Parse error returns empty rather than crashing.",
					"mistakes": "Not checking the parse result means a corrupted file crashes the game.",
					"related": ["save_game", "load_json", "save_slot", "config_file"]
				}
			},
			"save_json": {
				"phrases": ["save json", "write json", "json save"],
				"code": """func save_json(path: String, data: Dictionary) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data, "\\t"))
	file.close()
	return true
""",
				"params": ["path", "data"],
				"category": "save",
				"dimension": "any",
				"difficulty": "beginner",
				"param_info": {
					"path": {
						"default": "",
						"range": [],
						"what": "Where to write the file. Use user:// for saves, res:// only for dev.",
						"typical": "user://save.json or user://slot_1.json",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"data": {
						"default": {},
						"range": [],
						"what": "The Dictionary to serialize as JSON.",
						"typical": "game state dictionary",
						"increase": "Larger file.",
						"decrease": "Smaller file."
					}
				},
				"details": {
					"what": "Generic JSON writer that takes any path. Indented with tabs for readability.",
					"where": "Anywhere you need to write JSON — saves, configs, level data.",
					"before": "None.",
					"after": "Pair with load_json to read it back.",
					"why_optimized": "Returns a bool so callers can react to failure.",
					"mistakes": "Writing to res:// works in the editor but fails in exported games. Always user://.",
					"related": ["load_json", "save_game", "save_slot"]
				}
			},
			"load_json": {
				"phrases": ["load json", "read json", "json load"],
				"code": """func load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return {}
	return json.data as Dictionary
""",
				"params": ["path"],
				"category": "save",
				"dimension": "any",
				"difficulty": "beginner",
				"param_info": {
					"path": {
						"default": "",
						"range": [],
						"what": "Path to the JSON file to read.",
						"typical": "user://save.json",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "Generic JSON reader. Returns {} for missing or invalid files.",
					"where": "Anywhere you need to read JSON.",
					"before": "None.",
					"after": "Use the returned Dictionary directly.",
					"why_optimized": "Guards against missing file and parse error — never crashes.",
					"mistakes": "Using json.data without checking parse result means bad files silently return garbage.",
					"related": ["save_json", "load_game", "config_file"]
				}
			},
			"autosave": {
				"phrases": ["autosave", "auto save", "periodic save"],
				"code": """@export var interval: float = 60.0

func _ready() -> void:
	var timer := Timer.new()
	timer.wait_time = interval
	timer.autostart = true
	timer.timeout.connect(_autosave)
	add_child(timer)

func _autosave() -> void:
	print("Autosaving...")
""",
				"params": ["interval"],
				"category": "save",
				"dimension": "any",
				"difficulty": "beginner",
				"param_info": {
					"interval": {
						"default": 60.0,
						"range": [10.0, 600.0],
						"what": "Seconds between autosaves.",
						"typical": "30 frequent / 60 standard / 300 checkpoints-only",
						"increase": "Saves less often — less disk churn, more progress lost on crash.",
						"decrease": "Saves more often — more disk writes."
					}
				},
				"details": {
					"what": "Creates a Timer that fires _autosave() on an interval.",
					"where": "Attach to a game manager. Replace print with your actual save logic.",
					"before": "None. Timer is created in _ready.",
					"after": "Replace _autosave()'s body with save_game(current_state).",
					"why_optimized": "Timer node handles the timing — no _process needed.",
					"mistakes": "Autosaving every frame destroys performance. Always use a Timer.",
					"related": ["save_game", "load_game", "save_slot"]
				}
			},
			"settings_save": {
				"phrases": ["save settings", "settings save", "config save"],
				"code": """const SETTINGS_PATH := "user://settings.cfg"

func save_setting(section: String, key: String, value: Variant) -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value(section, key, value)
	cfg.save(SETTINGS_PATH)
""",
				"params": ["section", "key", "value"],
				"category": "save",
				"dimension": "any",
				"difficulty": "beginner",
				"param_info": {
					"section": {
						"default": "",
						"range": [],
						"what": "Group name — usually 'audio', 'video', 'gameplay'.",
						"typical": "audio, video, controls",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"key": {
						"default": "",
						"range": [],
						"what": "Setting name within the section.",
						"typical": "master_volume, fullscreen, mouse_sensitivity",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"value": {
						"default": null,
						"range": [],
						"what": "The value to store. Can be int, float, bool, String, Vector, etc.",
						"typical": "0.8, true, 100",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "Saves one setting to a ConfigFile. Loads the existing file first so other settings survive.",
					"where": "Call from your options menu whenever a setting changes.",
					"before": "None.",
					"after": "Read back with read_config or ConfigFile.get_value.",
					"why_optimized": "ConfigFile is Godot's native INI-style format — human-readable and typed.",
					"mistakes": "Creating a fresh ConfigFile without loading means previous settings are lost.",
					"related": ["config_file", "options_menu", "save_game"]
				}
			},
			"save_slot": {
				"phrases": ["save slot", "save slots", "multiple saves"],
				"code": """func save_to_slot(slot: int, data: Dictionary) -> void:
	var path := "user://save_%d.json" % slot
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()

func load_from_slot(slot: int) -> Dictionary:
	var path := "user://save_%d.json" % slot
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	var json := JSON.new()
	json.parse(file.get_as_text())
	return json.data as Dictionary
""",
				"params": ["slot", "data"],
				"category": "save",
				"dimension": "any",
				"difficulty": "intermediate",
				"param_info": {
					"slot": {
						"default": 0,
						"range": [0, 99],
						"what": "Which save slot. Each gets its own file.",
						"typical": "0-2 for 3 slots, 0-9 for 10",
						"increase": "More save slots available.",
						"decrease": "Fewer slots."
					},
					"data": {
						"default": {},
						"range": [],
						"what": "Game state to save in the slot.",
						"typical": "same Dictionary you'd pass to save_game",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "Multi-slot save system. Each slot is a separate JSON file.",
					"where": "Attach to a game manager. Build a UI with one button per slot.",
					"before": "None.",
					"after": "Add a preview to each slot button — load the first few fields and show level / playtime.",
					"why_optimized": "Filename is derived from the slot integer — no index file needed.",
					"mistakes": "Not validating slot range lets players save to slot 999999 and fill the disk.",
					"related": ["save_game", "load_game", "save_json", "main_menu"]
				}
			},
			"config_file": {
				"phrases": ["config file", "configfile", "config read write"],
				"code": """const CONFIG_PATH := "user://config.cfg"

func write_config(section: String, key: String, value: Variant) -> void:
	var cfg := ConfigFile.new()
	cfg.load(CONFIG_PATH)
	cfg.set_value(section, key, value)
	cfg.save(CONFIG_PATH)

func read_config(section: String, key: String, default: Variant) -> Variant:
	var cfg := ConfigFile.new()
	cfg.load(CONFIG_PATH)
	return cfg.get_value(section, key, default)
""",
				"params": [],
				"category": "save",
				"dimension": "any",
				"difficulty": "beginner",
				"details": {
					"what": "Read/write pair for a ConfigFile. Read falls back to a default if the key is missing.",
					"where": "Attach to a settings manager or an autoload.",
					"before": "None.",
					"after": "Use read_config on startup to restore user preferences.",
					"why_optimized": "get_value's third argument is a built-in default — no has_key check needed.",
					"mistakes": "Forgetting the default means a first-run user gets null instead of a sane value.",
					"related": ["settings_save", "options_menu", "audio_bus_volume"]
				}
			}
		}
	}

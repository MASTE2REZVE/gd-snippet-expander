@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"snippets": {
			"dialogue_data": {
				"phrases": ["dialogue data", "dialogue resource", "npc dialogue data", "conversation data"],
				"code": """class_name DialogueData
extends Resource

@export var npc_name: String = ""
@export var portrait: Texture2D
@export var lines: Array[String] = []
@export var auto_advance: bool = false
@export var auto_advance_delay: float = 3.0
""",
				"params": ["npc_name", "portrait", "lines", "auto_advance", "auto_advance_delay"],
				"category": "dialogue",
				"subcategory": "data",
				"dimension": "any",
				"difficulty": "intermediate",
				"param_info": {
					"npc_name": {
						"default": "",
						"range": [],
						"what": "Display name shown above the dialogue text.",
						"typical": "Blacksmith / Innkeeper / Mysterious Stranger",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"portrait": {
						"default": "",
						"range": [],
						"what": "Character portrait texture shown next to the text.",
						"typical": "one per NPC expression (happy, angry, neutral)",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"lines": {
						"default": [],
						"range": [],
						"what": "Array of dialogue lines, shown one at a time.",
						"typical": "3-8 lines per conversation",
						"increase": "Longer conversation.",
						"decrease": "Shorter."
					},
					"auto_advance": {
						"default": false,
						"range": [],
						"what": "If true, lines advance on a timer instead of waiting for input.",
						"typical": "false for player-paced / true for cutscenes",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"auto_advance_delay": {
						"default": 3.0,
						"range": [0.5, 10.0],
						"what": "Seconds per line when auto_advance is on.",
						"typical": "1.5 fast / 3.0 standard / 5.0 slow",
						"increase": "Slower auto-advance.",
						"decrease": "Faster."
					}
				},
				"details": {
					"what": "A Resource that stores all dialogue for one conversation. Save as .tres, one per NPC.",
					"where": "Save this as dialogue_data.gd. Then in Godot, create new .tres resources based on this class.",
					"before": "None. This is a base data class.",
					"after": "Load with preload or as an @export var in your NPC script. Pass to dialogue_box.start_dialogue().",
					"why_optimized": "Resources are cached by the engine — reusing them across NPCs is free.",
					"mistakes": "Naming files without the class_name means you can't create resources from this script in the editor.",
					"related": ["dialogue_box_advanced", "dialogue_choice", "npc_interactable"]
				}
			},
			"npc_interactable": {
				"phrases": ["npc interactable", "talk to npc", "npc interaction", "start dialogue"],
				"code": """extends Area2D

signal player_entered
signal player_exited

@export var dialogue_resource: Resource

var _player_in_range: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _unhandled_input(event: InputEvent) -> void:
	if _player_in_range and event.is_action_pressed("interact"):
		start_dialogue()

func start_dialogue() -> void:
	if dialogue_resource == null:
		push_warning("No dialogue resource assigned to " + name)
		return
	if dialogue_resource.has_method("get") and dialogue_resource.get("lines") != null:
		var dialogue_ui = get_tree().get_first_node_in_group("dialogue_ui")
		if dialogue_ui != null and dialogue_ui.has_method("start_dialogue"):
			dialogue_ui.start_dialogue(dialogue_resource)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = true
		player_entered.emit()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = false
		player_exited.emit()
""",
				"params": ["dialogue_resource"],
				"category": "dialogue",
				"subcategory": "interaction",
				"dimension": "2d",
				"difficulty": "intermediate",
				"required_actions": ["interact"],
				"param_info": {
					"dialogue_resource": {
						"default": "",
						"range": [],
						"what": "DialogueData resource containing this NPC's conversation.",
						"typical": "one .tres file per NPC",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "An Area2D that starts dialogue when the player is in range and presses Interact.",
					"where": "Attach to an Area2D child of the NPC. Player must be in group 'player'. The dialogue UI must be in group 'dialogue_ui'.",
					"before": "Create an input action 'interact' in Input Map (usually E or Space). Add the player to group 'player'. Add your dialogue UI to group 'dialogue_ui'.",
					"after": "Add a prompt UI that appears when player_entered fires ('[E] Talk').",
					"why_optimized": "Uses get_first_node_in_group — no scene path dependency. Works wherever the dialogue UI lives.",
					"mistakes": "Forgetting to put the dialogue UI in the 'dialogue_ui' group means nothing happens on interact.",
					"related": ["dialogue_data", "dialogue_box_advanced", "dialogue_prompt"]
				}
			},
			"dialogue_choice": {
				"phrases": ["dialogue choice", "dialogue options", "branch dialogue", "player choice"],
				"code": """class_name DialogueChoice
extends Resource

@export var prompt: String = ""
@export var options: Array[String] = []
@export var next_dialogue: Array[Resource] = []
@export var conditions: Array[String] = []
""",
				"params": ["prompt", "options", "next_dialogue", "conditions"],
				"category": "dialogue",
				"subcategory": "branching",
				"dimension": "any",
				"difficulty": "intermediate",
				"param_info": {
					"prompt": {
						"default": "",
						"range": [],
						"what": "The question or line shown before the choices appear.",
						"typical": "Will you help me? / What do you want? / Choose your path.",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"options": {
						"default": [],
						"range": [],
						"what": "Button labels the player chooses between.",
						"typical": "['Yes', 'No'] or ['Accept quest', 'Ask more', 'Leave']",
						"increase": "More choices — keep to 2-4 for readability.",
						"decrease": "Fewer choices."
					},
					"next_dialogue": {
						"default": [],
						"range": [],
						"what": "Resource paths — one per option. The choice at index N leads to next_dialogue[N].",
						"typical": "one DialogueData or DialogueChoice per option",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"conditions": {
						"default": [],
						"range": [],
						"what": "Optional condition strings checked before showing each option (e.g. 'has_item:key'). Empty means always show.",
						"typical": "['has_quest:rescue', '', 'always']",
						"increase": "More gated options.",
						"decrease": "Fewer requirements."
					}
				},
				"details": {
					"what": "A Resource describing a branching dialogue node: a prompt, a set of options, and where each option leads.",
					"where": "Save as dialogue_choice.gd. Use with a dialogue system that understands branching.",
					"before": "None. This is a base data class.",
					"after": "Chain multiple DialogueChoice resources for multi-level conversations. Next_dialogue can point to either DialogueData (linear) or another DialogueChoice (branching again).",
					"why_optimized": "Resource references mean no scene re-load — dialogue trees are loaded once.",
					"mistakes": "Mismatched array sizes — options and next_dialogue must be the same length, or the choice at index N has no destination.",
					"related": ["dialogue_data", "dialogue_box_advanced", "dialogue_condition_check"]
				}
			},
			"dialogue_condition_check": {
				"phrases": ["dialogue condition", "conditional dialogue", "check condition dialogue", "gated dialogue"],
				"code": """func check_condition(condition: String) -> bool:
	if condition.is_empty() or condition == "always":
		return true
	var parts := condition.split(":", false)
	if parts.size() < 2:
		return false
	var kind := str(parts[0])
	var value := str(parts[1])
	match kind:
		"has_item":
			var inventory = get_tree().get_first_node_in_group("inventory")
			if inventory != null and inventory.has_method("has_item"):
				return inventory.has_item(value)
		"has_quest":
			var quest_log = get_tree().get_first_node_in_group("quest_log")
			if quest_log != null and quest_log.has_method("has_quest"):
				return quest_log.has_quest(value)
		"flag":
			var settings = get_node_or_null("/root/GameState")
			if settings != null:
				return bool(settings.get(value))
	return false
""",
				"params": ["condition"],
				"category": "dialogue",
				"subcategory": "branching",
				"dimension": "any",
				"difficulty": "advanced",
				"param_info": {
					"condition": {
						"default": "",
						"range": [],
						"what": "Condition string in the format 'type:value'.",
						"typical": "has_item:key / has_quest:rescue / flag:met_king / always",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "Evaluates a condition string against the player's inventory, quest log, or game state flags.",
					"where": "Attach to your dialogue manager. Call before showing dialogue options that have conditions.",
					"before": "Inventory in group 'inventory'. Quest log in group 'quest_log'. Optional autoload named 'GameState' for flags.",
					"after": "Extend the match statement with new condition types as your game grows (has_level, has_gold, etc.).",
					"why_optimized": "String parsing happens once per check. Match is faster than if/elif chains in GDScript.",
					"mistakes": "Forgetting to add the inventory or quest_log to its group means those conditions silently fail.",
					"related": ["dialogue_choice", "dialogue_data", "inventory_system", "quest_add"]
				}
			},
			"dialogue_typewriter": {
				"phrases": ["typewriter effect", "text reveal", "letter by letter", "type text slowly"],
				"code": """@export var characters_per_second: float = 40.0

var _typing: bool = false
var _full_text: String = ""

func type_text(label: Label, text: String) -> void:
	_full_text = text
	label.text = ""
	_typing = true
	var visible_chars: int = 0
	var total: int = text.length()
	var delay: float = 1.0 / max(characters_per_second, 1.0)
	while visible_chars < total:
		visible_chars += 1
		label.text = text.substr(0, visible_chars)
		await get_tree().create_timer(delay).timeout
		if not _typing:
			label.text = text
			return
	_typing = false

func skip() -> void:
	_typing = false

func is_typing() -> bool:
	return _typing
""",
				"params": ["characters_per_second"],
				"category": "dialogue",
				"subcategory": "presentation",
				"dimension": "ui",
				"difficulty": "intermediate",
				"param_info": {
					"characters_per_second": {
						"default": 40.0,
						"range": [10.0, 120.0],
						"what": "How fast text appears on screen.",
						"typical": "20 slow / 40 standard / 80 fast / 200 instant-feel",
						"increase": "Faster reveal.",
						"decrease": "Slower, more dramatic."
					}
				},
				"details": {
					"what": "Reveals text one character at a time inside a Label.",
					"where": "Attach to your dialogue manager. Call type_text($Label, line) for each line.",
					"before": "None.",
					"after": "Call skip() when the player presses Interact during typing — sets the full text immediately.",
					"why_optimized": "Single loop, no Label duplication. create_timer is a lightweight coroutine.",
					"mistakes": "Not handling skip() means the player can't read a long line without waiting.",
					"related": ["dialogue_box_advanced", "dialog_box", "typewriter_sound"]
				}
			},
			"npc_portrait_swap": {
				"phrases": ["portrait swap", "npc portrait change", "emotion portrait", "dialogue portrait"],
				"code": """@export var texture_rect_path: NodePath
@export var default_texture: Texture2D
@export var emotion_textures: Dictionary = {}

@onready var _rect: TextureRect = get_node(texture_rect_path)

func set_emotion(emotion: String) -> void:
	if emotion_textures.has(emotion):
		_rect.texture = emotion_textures[emotion]
	else:
		_rect.texture = default_texture

func reset_portrait() -> void:
	_rect.texture = default_texture
""",
				"params": ["texture_rect_path", "default_texture", "emotion_textures"],
				"category": "dialogue",
				"subcategory": "presentation",
				"dimension": "ui",
				"difficulty": "beginner",
				"param_info": {
					"texture_rect_path": {
						"default": "",
						"range": [],
						"what": "NodePath to the TextureRect displaying the portrait.",
						"typical": "the portrait node inside your dialogue UI",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"default_texture": {
						"default": "",
						"range": [],
						"what": "Portrait shown when no emotion is set.",
						"typical": "neutral face",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"emotion_textures": {
						"default": {},
						"range": [],
						"what": "Dictionary mapping emotion names to textures.",
						"typical": "{\"happy\": tex1, \"angry\": tex2, \"sad\": tex3}",
						"increase": "More expressions.",
						"decrease": "Fewer."
					}
				},
				"details": {
					"what": "Swaps the portrait texture based on an emotion string. Enables expressive dialogue.",
					"where": "Attach to your dialogue manager. Set emotion_textures in the Inspector.",
					"before": "Prepare portrait textures for each emotion (happy, angry, sad, etc.) — usually cropped from one source image.",
					"after": "Call set_emotion(\"happy\") before each line. Or embed emotion tags in your dialogue text and parse them.",
					"why_optimized": "Dictionary lookup — O(1). Textures are shared resources, not copied.",
					"mistakes": "Loading textures at runtime instead of preloading them causes hitching on the first swap.",
					"related": ["dialogue_data", "dialogue_box_advanced", "npc_interactable"]
				}
			}
		}
	}

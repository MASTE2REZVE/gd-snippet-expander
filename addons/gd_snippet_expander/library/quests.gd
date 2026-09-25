@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"snippets": {
			"quest_data": {
				"phrases": ["quest data", "quest resource", "quest definition", "define quest"],
				"code": """class_name QuestData
extends Resource

@export var quest_id: String = ""
@export var title: String = ""
@export var description: String = ""
@export var objectives: Array[String] = []
@export var required_counts: Array[int] = []
@export var reward_gold: int = 0
@export var reward_items: Array[String] = []
@export var reward_xp: int = 0
@export var is_main_quest: bool = false
""",
				"params": ["quest_id", "title", "description", "objectives", "required_counts", "reward_gold", "reward_items", "reward_xp", "is_main_quest"],
				"category": "quest",
				"subcategory": "data",
				"dimension": "any",
				"difficulty": "intermediate",
				"param_info": {
					"quest_id": {
						"default": "",
						"range": [],
						"what": "Unique identifier for this quest. Used in code and save data.",
						"typical": "rescue_villager / find_sword / main_chapter_1",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"objectives": {
						"default": [],
						"range": [],
						"what": "Array of objective description strings.",
						"typical": "['Find the sword', 'Return to the king']",
						"increase": "More steps in the quest.",
						"decrease": "Simpler quest."
					},
					"required_counts": {
						"default": [],
						"range": [],
						"what": "How many of each objective must be completed. Matches objectives array size.",
						"typical": "[1, 1] for single tasks / [5, 1] for kill-5 then report",
						"increase": "Grindier objective.",
						"decrease": "Faster to complete."
					},
					"reward_gold": {
						"default": 0,
						"range": [0, 100000],
						"what": "Currency reward on completion.",
						"typical": "50 side quest / 500 main quest / 0 no gold",
						"increase": "More generous.",
						"decrease": "Less."
					},
					"reward_xp": {
						"default": 0,
						"range": [0, 100000],
						"what": "Experience points on completion.",
						"typical": "50 trivial / 500 standard / 5000 main",
						"increase": "Levels the player faster.",
						"decrease": "Slower."
					},
					"is_main_quest": {
						"default": false,
						"range": [],
						"what": "True if this quest is part of the main story.",
						"typical": "false for side / true for main",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "Resource describing a quest: objectives, required counts, and rewards.",
					"where": "Save as quest_data.gd. Create .tres resources in the editor for each quest.",
					"before": "None. Base data class.",
					"after": "Register quests with the quest_log autoload using add_quest(). Track progress with advance_objective().",
					"why_optimized": "Resources are shared and cached. All quest definitions load once.",
					"mistakes": "Mismatched array sizes — objectives and required_counts must match. Otherwise the last objectives can never complete.",
					"related": ["quest_log", "quest_add", "quest_advance", "quest_reward"]
				}
			},
			"quest_log": {
				"phrases": ["quest log", "quest manager", "track quests", "quest system"],
				"code": """extends Node

signal quest_added(quest_id: String)
signal quest_completed(quest_id: String)
signal objective_advanced(quest_id: String, index: int, current: int, required: int)

var active_quests: Dictionary = {}
var completed_quests: Dictionary = {}

func add_quest(quest: Resource) -> void:
	if quest == null:
		return
	var qid: String = str(quest.get("quest_id"))
	if qid.is_empty() or active_quests.has(qid) or completed_quests.has(qid):
		return
	var objectives: Array = quest.get("objectives")
	var required: Array = quest.get("required_counts")
	var progress: Array = []
	for i in range(objectives.size()):
		progress.append(0)
	active_quests[qid] = {
		"resource": quest,
		"progress": progress
	}
	quest_added.emit(qid)

func has_quest(quest_id: String) -> bool:
	return active_quests.has(quest_id)

func is_completed(quest_id: String) -> bool:
	return completed_quests.has(quest_id)

func advance_objective(quest_id: String, index: int, amount: int = 1) -> void:
	if not active_quests.has(quest_id):
		return
	var entry: Dictionary = active_quests[quest_id]
	var quest: Resource = entry.resource
	var required: Array = quest.get("required_counts")
	if index < 0 or index >= required.size():
		return
	var progress: Array = entry.progress
	progress[index] = min(progress[index] + amount, int(required[index]))
	objective_advanced.emit(quest_id, index, progress[index], int(required[index]))
	if _is_fully_completed(quest_id):
		_complete_quest(quest_id)

func get_progress(quest_id: String, index: int) -> Array:
	if not active_quests.has(quest_id):
		return [0, 0]
	var entry: Dictionary = active_quests[quest_id]
	var quest: Resource = entry.resource
	var progress: Array = entry.progress
	var required: Array = quest.get("required_counts")
	if index < 0 or index >= required.size():
		return [0, 0]
	return [int(progress[index]), int(required[index])]

func _is_fully_completed(quest_id: String) -> bool:
	if not active_quests.has(quest_id):
		return false
	var entry: Dictionary = active_quests[quest_id]
	var quest: Resource = entry.resource
	var required: Array = quest.get("required_counts")
	var progress: Array = entry.progress
	for i in range(required.size()):
		if int(progress[i]) < int(required[i]):
			return false
	return true

func _complete_quest(quest_id: String) -> void:
	if not active_quests.has(quest_id):
		return
	var entry: Dictionary = active_quests[quest_id]
	completed_quests[quest_id] = entry
	active_quests.erase(quest_id)
	quest_completed.emit(quest_id)
""",
				"params": [],
				"category": "quest",
				"subcategory": "system",
				"dimension": "any",
				"difficulty": "intermediate",
				"details": {
					"what": "Central quest tracker with signals. Manages active and completed quests.",
					"where": "Add as an autoload in Project Settings → Autoload. Name it 'QuestLog'. Add it to group 'quest_log'.",
					"before": "None.",
					"after": "Add quests with add_quest(). Advance objectives with advance_objective(). Listen to quest_completed for reward granting.",
					"why_optimized": "Dictionary-based tracking — O(1) lookups. Signals keep UI decoupled.",
					"mistakes": "Forgetting to register as autoload means the singleton doesn't exist and calls fail silently.",
					"related": ["quest_data", "quest_add", "quest_advance", "quest_reward", "quest_log_ui"]
				}
			},
			"quest_add": {
				"phrases": ["add quest", "start quest", "give quest", "accept quest"],
				"code": """@export var quest_resource: Resource

func give_quest() -> void:
	if quest_resource == null:
		push_warning("No quest resource assigned.")
		return
	var quest_log = get_tree().get_first_node_in_group("quest_log")
	if quest_log == null:
		push_warning("No quest log in scene. Add it as an autoload.")
		return
	if quest_log.has_method("add_quest"):
		quest_log.add_quest(quest_resource)
""",
				"params": ["quest_resource"],
				"category": "quest",
				"subcategory": "actions",
				"dimension": "any",
				"difficulty": "beginner",
				"param_info": {
					"quest_resource": {
						"default": "",
						"range": [],
						"what": "QuestData resource to give when this is called.",
						"typical": "one .tres file per quest",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "Adds a quest to the player's log. Call from NPC dialogue or a trigger area.",
					"where": "Attach to any node that should grant quests. Set the resource in the Inspector.",
					"before": "QuestLog autoload must exist and be in group 'quest_log'.",
					"after": "Call give_quest() when the player accepts the quest in dialogue.",
					"why_optimized": "Single check + method call. No scene dependencies.",
					"mistakes": "Calling this when the quest is already active is safe — the quest log ignores duplicates.",
					"related": ["quest_data", "quest_log", "quest_advance", "npc_interactable"]
				}
			},
			"quest_advance": {
				"phrases": ["advance quest", "progress quest", "complete objective", "update quest"],
				"code": """func advance_quest(quest_id: String, objective_index: int = 0, amount: int = 1) -> void:
	var quest_log = get_tree().get_first_node_in_group("quest_log")
	if quest_log == null or not quest_log.has_method("advance_objective"):
		return
	quest_log.advance_objective(quest_id, objective_index, amount)

func on_enemy_killed(enemy_type: String) -> void:
	match enemy_type:
		"goblin":
			advance_quest("kill_goblins", 0)
		"wolf":
			advance_quest("kill_wolves", 0)

func on_item_collected(item_id: String) -> void:
	match item_id:
		"herb":
			advance_quest("gather_herbs", 0)
		"crystal":
			advance_quest("collect_crystals", 0)
""",
				"params": ["quest_id", "objective_index", "amount"],
				"category": "quest",
				"subcategory": "actions",
				"dimension": "any",
				"difficulty": "beginner",
				"param_info": {
					"quest_id": {
						"default": "",
						"range": [],
						"what": "ID of the quest to advance.",
						"typical": "matches QuestData.quest_id",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"objective_index": {
						"default": 0,
						"range": [0, 10],
						"what": "Which objective to advance. 0 = first, 1 = second, etc.",
						"typical": "0 for single-objective quests",
						"increase": "Advance a later objective.",
						"decrease": "N/A"
					},
					"amount": {
						"default": 1,
						"range": [1, 100],
						"what": "How many to add to the counter.",
						"typical": "1 for single kills / 5 for group kills",
						"increase": "Faster quest completion.",
						"decrease": "Slower."
					}
				},
				"details": {
					"what": "Advances a quest objective by a given amount. Call from kill handlers, pickup handlers, etc.",
					"where": "Attach to your game manager or listen to events across the game.",
					"before": "QuestLog must be loaded. The quest must be active.",
					"after": "The QuestLog automatically checks completion and emits quest_completed when done.",
					"why_optimized": "Single method call, no allocations.",
					"mistakes": "Advancing a quest that isn't active does nothing. Give the quest first.",
					"related": ["quest_log", "quest_add", "quest_reward"]
				}
			},
			"quest_reward": {
				"phrases": ["quest reward", "grant reward", "complete quest reward", "turn in quest"],
				"code": """func _ready() -> void:
	var quest_log = get_tree().get_first_node_in_group("quest_log")
	if quest_log != null and quest_log.has_signal("quest_completed"):
		quest_log.quest_completed.connect(_on_quest_completed)

func _on_quest_completed(quest_id: String) -> void:
	var quest_log = get_tree().get_first_node_in_group("quest_log")
	if quest_log == null:
		return
	var entry = quest_log.completed_quests.get(quest_id)
	if entry == null:
		return
	var quest: Resource = entry.resource
	_grant_gold(int(quest.get("reward_gold")))
	_grant_xp(int(quest.get("reward_xp")))
	var items: Array = quest.get("reward_items")
	for item_id in items:
		_grant_item(str(item_id))

func _grant_gold(amount: int) -> void:
	if amount <= 0:
		return
	var inventory = get_tree().get_first_node_in_group("inventory")
	if inventory != null and inventory.has_method("add_item"):
		inventory.add_item("gold", amount)

func _grant_xp(amount: int) -> void:
	if amount <= 0:
		return
	var player = get_tree().get_first_node_in_group("player")
	if player != null and player.has_method("add_xp"):
		player.add_xp(amount)

func _grant_item(item_id: String) -> void:
	var inventory = get_tree().get_first_node_in_group("inventory")
	if inventory != null and inventory.has_method("add_item"):
		inventory.add_item(item_id, 1)
""",
				"params": [],
				"category": "quest",
				"subcategory": "rewards",
				"dimension": "any",
				"difficulty": "intermediate",
				"details": {
					"what": "Listens for quest_completed and grants gold, XP, and items.",
					"where": "Attach to your game manager or an autoload that runs for the whole game.",
					"before": "Inventory in group 'inventory'. Player in group 'player' with an add_xp method.",
					"after": "Extend _grant_item to show a reward popup UI.",
					"why_optimized": "Signal-driven, no per-frame checks. Runs only when a quest completes.",
					"mistakes": "If the player doesn't have an add_xp method, XP is silently skipped. Add a stub if your game doesn't use XP yet.",
					"related": ["quest_data", "quest_log", "inventory_system", "score_display"]
				}
			},
			"quest_log_ui": {
				"phrases": ["quest log ui", "quest journal", "quest list ui", "quest tracker"],
				"code": """extends CanvasLayer

@onready var _list: VBoxContainer = $Panel/ScrollContainer/QuestList

func _ready() -> void:
	visible = false
	var quest_log = get_tree().get_first_node_in_group("quest_log")
	if quest_log != null:
		if quest_log.has_signal("quest_added"):
			quest_log.quest_added.connect(_on_quest_changed)
		if quest_log.has_signal("quest_completed"):
			quest_log.quest_completed.connect(_on_quest_changed)
		if quest_log.has_signal("objective_advanced"):
			quest_log.objective_advanced.connect(_on_objective_advanced)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_quest_log"):
		visible = not visible
		if visible:
			_rebuild()

func _on_quest_changed(_a = null, _b = null) -> void:
	if visible:
		_rebuild()

func _on_objective_advanced(_qid, _idx, _cur, _req) -> void:
	if visible:
		_rebuild()

func _rebuild() -> void:
	if _list == null:
		return
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	var quest_log = get_tree().get_first_node_in_group("quest_log")
	if quest_log == null:
		return
	for qid in quest_log.active_quests.keys():
		_list.add_child(_build_entry(qid, quest_log.active_quests[qid]))

func _build_entry(quest_id: String, entry: Dictionary) -> Control:
	var panel := PanelContainer.new()
	var vbox := VBoxContainer.new()
	var quest: Resource = entry.resource
	var title := Label.new()
	title.text = str(quest.get("title"))
	title.add_theme_font_size_override("font_size", 16)
	vbox.add_child(title)
	var desc := Label.new()
	desc.text = str(quest.get("description"))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 12)
	vbox.add_child(desc)
	var objectives: Array = quest.get("objectives")
	var progress: Array = entry.progress
	var required: Array = quest.get("required_counts")
	for i in range(objectives.size()):
		var obj := Label.new()
		var cur := int(progress[i])
		var req := int(required[i])
		var check := " [x] " if cur >= req else " [ ] "
		obj.text = check + str(objectives[i]) + "  (" + str(cur) + "/" + str(req) + ")"
		obj.add_theme_font_size_override("font_size", 12)
		vbox.add_child(obj)
	panel.add_child(vbox)
	return panel
""",
				"params": [],
				"category": "quest",
				"subcategory": "ui",
				"dimension": "ui",
				"difficulty": "intermediate",
				"details": {
					"what": "A CanvasLayer quest journal. Opens with a keybind, shows active quests and progress.",
					"where": "Attach to a CanvasLayer. Add a Panel → ScrollContainer → VBoxContainer named 'QuestList' as children.",
					"before": "Create input action 'toggle_quest_log' in Input Map (usually J or Tab). Hide the CanvasLayer by default.",
					"after": "Style the PanelContainer with a theme for consistency.",
					"why_optimized": "Rebuilds only when visible and only when a signal fires — no per-frame UI churn.",
					"mistakes": "Node paths — the VBoxContainer must be at $Panel/ScrollContainer/QuestList exactly.",
					"related": ["quest_log", "quest_data", "pause_menu"]
				}
			}
		}
	}

@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"snippets": {
			"item_registry": {
				"phrases": ["item registry", "item database", "item loader", "load items"],
				"code": """extends Node

signal registry_loaded

@export var item_folder: String = "res://data/items/"

var items: Dictionary = {}
var _loaded: bool = false

func _ready() -> void:
	load_all()

func load_all() -> void:
	items.clear()
	var dir := DirAccess.open(item_folder)
	if dir == null:
		push_warning("Item registry: folder not found: " + item_folder)
		_loaded = true
		registry_loaded.emit()
		return
	_scan_folder(item_folder)
	_loaded = true
	registry_loaded.emit()

func _scan_folder(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if dir.current_is_dir():
			if not name.begins_with("."):
				_scan_folder(path + name + "/")
		elif name.ends_with(".tres") or name.ends_with(".res"):
			var resource := load(path + name)
			if resource != null and resource.get("item_id") != null:
				var id := str(resource.get("item_id"))
				if not id.is_empty():
					items[id] = resource
		name = dir.get_next()
	dir.list_dir_end()

func get_item(item_id: String) -> Resource:
	return items.get(item_id, null)

func has_item(item_id: String) -> bool:
	return items.has(item_id)

func list_ids() -> Array:
	return items.keys()

func get_by_type(item_type: String) -> Array:
	var out: Array = []
	for id in items.keys():
		var item: Resource = items[id]
		if str(item.get("item_type")) == item_type:
			out.append(item)
	return out

func is_loaded() -> bool:
	return _loaded
""",
				"params": ["item_folder"],
				"category": "items",
				"subcategory": "registry",
				"dimension": "any",
				"difficulty": "intermediate",
				"param_info": {
					"item_folder": {
						"default": "res://data/items/",
						"range": [],
						"what": "res:// path to the folder containing .tres item resources. Scanned recursively.",
						"typical": "res://data/items/ or res://items/",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "Autoload singleton that scans a folder for ItemData resources and indexes them by item_id.",
					"where": "Add as an autoload named 'ItemRegistry'. Set item_folder in the Inspector after adding.",
					"before": "Create your item .tres files under res://data/items/ (or whatever folder you choose).",
					"after": "Access any item anywhere with ItemRegistry.get_item(\"health_potion\").",
					"why_optimized": "Loads once at startup, kept in memory. Recursive scan means organizing items into subfolders still works.",
					"mistakes": "Scanning res:// at runtime works in the editor but not in exported builds for loose files. For export, keep items as .tres (they get packed into the .pck) or preload them explicitly.",
					"related": ["item_data", "item_spawn_pickup", "inventory_grid", "shop_buy"]
				}
			},
			"item_spawn_pickup": {
				"phrases": ["spawn item pickup", "drop item by id", "spawn item world", "create item pickup"],
				"code": """const DEFAULT_PICKUP_SCENE := "res://scenes/pickups/item_pickup.tscn"

@export var pickup_scene: PackedScene

func spawn_item(item_id: String, count: int, at_global_position: Vector2, parent: Node = null) -> Node:
	if count <= 0:
		return null
	var scene := pickup_scene
	if scene == null:
		scene = load(DEFAULT_PICKUP_SCENE)
	if scene == null:
		push_warning("No pickup scene available.")
		return null
	var target_parent: Node = parent if parent != null else get_tree().current_scene
	if target_parent == null:
		return null
	var instance := scene.instantiate()
	target_parent.add_child(instance)
	if instance is Node2D:
		(instance as Node2D).global_position = at_global_position
	if instance.has_method("setup"):
		instance.setup(item_id, count)
	elif instance.get("item_id") != null:
		instance.set("item_id", item_id)
		instance.set("count", count)
	return instance

func spawn_many(results: Array, at_global_position: Vector2, scatter: float = 40.0) -> void:
	for entry in results:
		if not (entry is Dictionary):
			continue
		var item_id := str(entry.get("item_id", ""))
		var count := int(entry.get("count", 1))
		if item_id.is_empty():
			continue
		var angle := randf() * TAU
		var distance := randf() * scatter
		var offset := Vector2(cos(angle), sin(angle)) * distance
		spawn_item(item_id, count, at_global_position + offset)
""",
				"params": ["pickup_scene"],
				"category": "items",
				"subcategory": "spawning",
				"dimension": "2d",
				"difficulty": "intermediate",
				"param_info": {
					"pickup_scene": {
						"default": "",
						"range": [],
						"what": "PackedScene used for spawned pickups. Must have setup(item_id, count) or item_id/count properties.",
						"typical": "the scene from inventory_pickup_auto",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "Spawns one or many item pickups in the world by item ID. Handles the parent and position.",
					"where": "Attach to your loot manager, drop system, or any node that needs to spawn items.",
					"before": "A pickup scene set up. ItemData registered so the pickup can identify what to add.",
					"after": "Use spawn_many() with the output of loot_roll() to scatter drops after an enemy dies.",
					"why_optimized": "Uses current_scene by default so pickups live in the world, not as children of the spawner. Avoids scene path dependencies.",
					"mistakes": "Adding pickups as children of a moving node (like the enemy) makes them move with it. Always add to the scene root or a static parent.",
					"related": ["loot_drop_pickup", "loot_roll", "item_registry", "inventory_pickup_auto"]
				}
			},
			"item_use_consumable": {
				"phrases": ["use item", "consume item", "drink potion", "use consumable"],
				"code": """signal item_used(item_id: String, succeeded: bool)

@export var effect_handlers: Dictionary = {}

func use_item(item_id: String, user: Node) -> bool:
	var registry = get_tree().get_first_node_in_group("item_registry")
	if registry == null:
		registry = get_node_or_null("/root/ItemRegistry")
	if registry == null or not registry.has_method("get_item"):
		item_used.emit(item_id, false)
		return false
	var item: Resource = registry.get_item(item_id)
	if item == null:
		item_used.emit(item_id, false)
		return false
	if not bool(item.get("consumable")):
		item_used.emit(item_id, false)
		return false
	# Look for a custom handler first
	if effect_handlers.has(item_id):
		var handler: Callable = effect_handlers[item_id]
		if handler.is_valid():
			handler.call(user, item)
			_consume_one(item_id)
			item_used.emit(item_id, true)
			return true
	# Fall back to stat-based healing if the item has a "heal_amount" concept
	if item.get("stat_bonuses") is Dictionary:
		var bonuses: Dictionary = item.get("stat_bonuses")
		if bonuses.has("heal") and user != null and user.has_method("heal"):
			user.heal(int(bonuses["heal"]))
			_consume_one(item_id)
			item_used.emit(item_id, true)
			return true
	item_used.emit(item_id, false)
	return false

func _consume_one(item_id: String) -> void:
	var inventory = get_tree().get_first_node_in_group("inventory")
	if inventory != null and inventory.has_method("remove_item"):
		inventory.remove_item(item_id, 1)
""",
				"params": ["effect_handlers"],
				"category": "items",
				"subcategory": "effects",
				"dimension": "any",
				"difficulty": "intermediate",
				"param_info": {
					"effect_handlers": {
						"default": {},
						"range": [],
						"what": "Dictionary mapping item_id to a Callable(user, item) that runs when used.",
						"typical": "{\"health_potion\": func(u, i): u.heal(50)}",
						"increase": "More items with custom effects.",
						"decrease": "Fewer custom handlers, more reliance on stat_bonuses."
					}
				},
				"details": {
					"what": "Uses a consumable item. Runs a custom handler if one exists, otherwise falls back to heal via stat_bonuses. Consumes one from the inventory on success.",
					"where": "Attach to your player, a game manager, or an autoload named 'ItemUser'.",
					"before": "ItemRegistry loaded. Inventory in group 'inventory'. Items marked consumable = true.",
					"after": "Connect item_used to show feedback (heal particles, sound, HUD flash).",
					"why_optimized": "Callable dictionary means each item can have a unique effect without a big match statement. Fallback handles the common heal case.",
					"mistakes": "Forgetting to mark the item as consumable = true means use_item returns false immediately.",
					"related": ["item_registry", "item_data", "inventory_grid", "health_system"]
				}
			},
			"item_tooltip": {
				"phrases": ["item tooltip", "item hover tooltip", "show item info", "item description popup"],
				"code": """extends Control

@onready var _name_label: Label = $VBox/NameLabel
@onready var _type_label: Label = $VBox/TypeLabel
@onready var _desc_label: Label = $VBox/DescLabel
@onready var _stats_label: Label = $VBox/StatsLabel

func _ready() -> void:
	visible = false

func show_item(item: Resource) -> void:
	if item == null:
		hide_item()
		return
	_name_label.text = str(item.get("display_name"))
	_name_label.modulate = _rarity_color(item)
	_type_label.text = str(item.get("item_type")).capitalize()
	_desc_label.text = str(item.get("description"))
	_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_stats_label.text = _format_stats(item)
	visible = true

func hide_item() -> void:
	visible = false

func _format_stats(item: Resource) -> String:
	var bonuses = item.get("stat_bonuses")
	if not (bonuses is Dictionary) or bonuses.is_empty():
		return ""
	var lines: Array = []
	for key in bonuses.keys():
		var value = bonuses[key]
		var sign_str := "+" if float(value) >= 0.0 else ""
		lines.append(str(key).capitalize() + ": " + sign_str + str(value))
	var value_prop = item.get("value")
	if value_prop != null and int(value_prop) > 0:
		lines.append("Value: " + str(value_prop) + "g")
	return "\n".join(lines)

func _rarity_color(item: Resource) -> Color:
	var bonuses = item.get("stat_bonuses")
	if not (bonuses is Dictionary):
		return Color.WHITE
	var total := 0.0
	for key in bonuses.keys():
		total += abs(float(bonuses[key]))
	if total > 40.0:
		return Color(1.0, 0.8, 0.2)
	if total > 20.0:
		return Color(0.7, 0.4, 1.0)
	if total > 10.0:
		return Color(0.4, 0.6, 1.0)
	if total > 3.0:
		return Color(0.4, 0.9, 0.4)
	return Color(0.8, 0.8, 0.8)
""",
				"params": [],
				"category": "items",
				"subcategory": "ui",
				"dimension": "ui",
				"difficulty": "beginner",
				"details": {
					"what": "A tooltip Control that shows item name, type, description, stats, and value. Name color is auto-derived from stat total.",
					"where": "Attach to a Control with child structure: VBox → NameLabel / TypeLabel / DescLabel / StatsLabel.",
					"before": "ItemData must have display_name, description, and stat_bonuses filled.",
					"after": "Call show_item(item) from your inventory slot's mouse_entered signal, hide_item() from mouse_exited.",
					"why_optimized": "Sets text only on show — no per-frame updates. Rarity color is derived from stat totals so you don't need a separate field.",
					"mistakes": "Hardcoding node paths — the tree structure must match exactly or the @onready refs are null.",
					"related": ["item_data", "inventory_grid", "tooltip", "inventory_ui_grid"]
				}
			}
		}
	}

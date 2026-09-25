@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"snippets": {
			"item_data": {
				"phrases": ["item data", "item resource", "define item", "item definition"],
				"code": """class_name ItemData
extends Resource

@export var item_id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var icon: Texture2D
@export var max_stack: int = 99
@export var value: int = 10
@export var item_type: String = "misc"
@export var consumable: bool = false
@export var equip_slot: String = ""
@export var stat_bonuses: Dictionary = {}
""",
				"params": ["item_id", "display_name", "description", "icon", "max_stack", "value", "item_type", "consumable", "equip_slot", "stat_bonuses"],
				"category": "inventory",
				"subcategory": "data",
				"dimension": "any",
				"difficulty": "intermediate",
				"param_info": {
					"item_id": {
						"default": "",
						"range": [],
						"what": "Unique identifier used in code and save files.",
						"typical": "health_potion / iron_sword / ancient_key",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"max_stack": {
						"default": 99,
						"range": [1, 9999],
						"what": "How many of this item fit in one inventory slot.",
						"typical": "1 for equipment / 99 for consumables / 999 for materials",
						"increase": "Fewer slots used by materials.",
						"decrease": "Forces more inventory management."
					},
					"value": {
						"default": 10,
						"range": [0, 1000000],
						"what": "Base gold value for shops.",
						"typical": "5 trash / 50 common / 500 rare / 5000+ legendary",
						"increase": "More valuable.",
						"decrease": "Cheaper."
					},
					"item_type": {
						"default": "misc",
						"range": [],
						"what": "Category string for filtering and sorting.",
						"typical": "weapon / armor / consumable / quest / material / misc",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"consumable": {
						"default": false,
						"range": [],
						"what": "True if using this item depletes one from the stack.",
						"typical": "true for potions/scrolls, false for equipment",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"equip_slot": {
						"default": "",
						"range": [],
						"what": "If non-empty, this item equips into that slot.",
						"typical": "weapon / helmet / chest / ring / amulet",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"stat_bonuses": {
						"default": {},
						"range": [],
						"what": "Dictionary of stat names to bonus values, applied when equipped.",
						"typical": "{\"attack\": 5, \"defense\": 2}",
						"increase": "Stronger item.",
						"decrease": "Weaker."
					}
				},
				"details": {
					"what": "Resource class defining an item. Create .tres files in the editor, one per item.",
					"where": "Save as item_data.gd. Right-click in FileSystem → New Resource → ItemData to create items.",
					"before": "None. Base data class.",
					"after": "Reference items by ID in recipes, loot tables, and shops. Load via preload or a registry.",
					"why_optimized": "Resources are cached. Reusing the same ItemData across dozens of inventory slots costs nothing extra.",
					"mistakes": "Not setting item_id means the item can't be found by code. Always fill it in.",
					"related": ["inventory_grid", "inventory_sort", "equipment_slots", "crafting_recipe", "shop_buy"]
				}
			},
			"inventory_grid": {
				"phrases": ["inventory grid", "grid inventory", "slot inventory", "inventory slots"],
				"code": """extends Node

signal inventory_changed

@export var slot_count: int = 24

var slots: Array = []
var _item_registry: Dictionary = {}

func _ready() -> void:
	for i in range(slot_count):
		slots.append({"item": null, "count": 0})

func register_item(item: Resource) -> void:
	if item == null:
		return
	var id := str(item.get("item_id"))
	if not id.is_empty():
		_item_registry[id] = item

func register_items(items: Array) -> void:
	for item in items:
		register_item(item)

func add_item(item_id: String, count: int = 1) -> bool:
	if not _item_registry.has(item_id):
		push_warning("Unknown item: " + item_id)
		return false
	var item: Resource = _item_registry[item_id]
	var max_stack: int = int(item.get("max_stack"))
	var remaining := count
	# Fill existing stacks first
	for i in range(slots.size()):
		if remaining <= 0:
			break
		var slot: Dictionary = slots[i]
		if slot.item == null:
			continue
		if str(slot.item.get("item_id")) != item_id:
			continue
		if slot.count >= max_stack:
			continue
		var space: int = max_stack - int(slot.count)
		var to_add: int = min(space, remaining)
		slot.count = int(slot.count) + to_add
		remaining -= to_add
	# Fill empty slots
	for i in range(slots.size()):
		if remaining <= 0:
			break
		var slot: Dictionary = slots[i]
		if slot.item != null:
			continue
		var to_add: int = min(max_stack, remaining)
		slot.item = item
		slot.count = to_add
		remaining -= to_add
	if remaining > 0:
		push_warning("Inventory full. Could not add " + str(remaining) + " of " + item_id)
		inventory_changed.emit()
		return false
	inventory_changed.emit()
	return true

func remove_item(item_id: String, count: int = 1) -> bool:
	var total := count_item(item_id)
	if total < count:
		return false
	var remaining := count
	for i in range(slots.size() - 1, -1, -1):
		if remaining <= 0:
			break
		var slot: Dictionary = slots[i]
		if slot.item == null:
			continue
		if str(slot.item.get("item_id")) != item_id:
			continue
		var take: int = min(int(slot.count), remaining)
		slot.count = int(slot.count) - take
		remaining -= take
		if slot.count <= 0:
			slot.item = null
	inventory_changed.emit()
	return true

func count_item(item_id: String) -> int:
	var total := 0
	for slot in slots:
		if slot.item != null and str(slot.item.get("item_id")) == item_id:
			total += int(slot.count)
	return total

func has_item(item_id: String, count: int = 1) -> bool:
	return count_item(item_id) >= count
""",
				"params": ["slot_count"],
				"category": "inventory",
				"subcategory": "core",
				"dimension": "any",
				"difficulty": "intermediate",
				"param_info": {
					"slot_count": {
						"default": 24,
						"range": [4, 200],
						"what": "Number of inventory slots.",
						"typical": "12 small / 24 standard / 40+ large / 100+ hoard",
						"increase": "More room for items.",
						"decrease": "Tighter inventory management."
					}
				},
				"details": {
					"what": "Slot-based inventory with stacking. Items are tracked by ID. Fills existing stacks before opening new slots.",
					"where": "Attach to a node and add to group 'inventory'. Register items at game start, then use add_item / remove_item.",
					"before": "Create ItemData resources for every item in your game. Register them with register_items() at startup.",
					"after": "Connect inventory_changed to your inventory UI to refresh it.",
					"why_optimized": "Dictionary-based registry — O(1) item lookup. Slots are plain dictionaries, no per-item node overhead.",
					"mistakes": "Forgetting to register items means add_item fails with 'Unknown item'. Register everything at game start.",
					"related": ["item_data", "inventory_sort", "inventory_ui_grid", "equipment_slots"]
				}
			},
			"inventory_sort": {
				"phrases": ["sort inventory", "inventory sort", "organize inventory", "sort items"],
				"code": """func sort_by_type() -> void:
	if slots.is_empty():
		return
	var filled: Array = []
	var empty: Array = []
	for slot in slots:
		if slot.item != null:
			filled.append(slot)
		else:
			empty.append({"item": null, "count": 0})
	filled.sort_custom(_compare_slots)
	var result: Array = []
	result.append_array(filled)
	result.append_array(empty)
	slots = result
	inventory_changed.emit()

func sort_by_name() -> void:
	if slots.is_empty():
		return
	var filled: Array = []
	var empty: Array = []
	for slot in slots:
		if slot.item != null:
			filled.append(slot)
		else:
			empty.append({"item": null, "count": 0})
	filled.sort_custom(func(a, b):
		return str(a.item.get("display_name")) < str(b.item.get("display_name"))
	)
	var result: Array = []
	result.append_array(filled)
	result.append_array(empty)
	slots = result
	inventory_changed.emit()

func _compare_slots(a: Dictionary, b: Dictionary) -> bool:
	var ta := str(a.item.get("item_type"))
	var tb := str(b.item.get("item_type"))
	if ta != tb:
		return ta < tb
	var na := str(a.item.get("display_name"))
	var nb := str(b.item.get("display_name"))
	return na < nb
""",
				"params": [],
				"category": "inventory",
				"subcategory": "management",
				"dimension": "any",
				"difficulty": "beginner",
				"details": {
					"what": "Sorts inventory by item type then name, or by name only. Moves all filled slots to the front.",
					"where": "Add to your inventory script. Call from a Sort button in the UI.",
					"before": "Inventory must contain slots (from inventory_grid).",
					"after": "Add sort_by_value() or sort_by_rarity() with the same pattern.",
					"why_optimized": "sort_custom is a single O(n log n) pass. Empty slots are kept at the end without extra loops.",
					"mistakes": "Calling sort on an empty inventory is safe but does nothing. Guard against it in the UI if you want to disable the button.",
					"related": ["inventory_grid", "item_data", "inventory_ui_grid"]
				}
			},
			"inventory_hotbar": {
				"phrases": ["hotbar", "quick slot", "action bar", "quick select"],
				"code": """extends Node

signal hotbar_changed

@export var slot_count: int = 8

var hotbar: Array = []
var selected_index: int = 0

func _ready() -> void:
	for i in range(slot_count):
		hotbar.append(null)

func _unhandled_input(event: InputEvent) -> void:
	for i in range(slot_count):
		var action := "hotbar_" + str(i + 1)
		if InputMap.has_action(action) and event.is_action_pressed(action):
			select_slot(i)

func select_slot(index: int) -> void:
	if index < 0 or index >= hotbar.size():
		return
	selected_index = index
	hotbar_changed.emit()

func set_slot(index: int, item: Resource) -> void:
	if index < 0 or index >= hotbar.size():
		return
	hotbar[index] = item
	hotbar_changed.emit()

func get_selected() -> Resource:
	if selected_index < 0 or selected_index >= hotbar.size():
		return null
	return hotbar[selected_index]
""",
				"params": ["slot_count"],
				"category": "inventory",
				"subcategory": "hotbar",
				"dimension": "any",
				"difficulty": "beginner",
				"param_info": {
					"slot_count": {
						"default": 8,
						"range": [4, 10],
						"what": "Number of hotbar slots. Keybinds 1-9 by default.",
						"typical": "4 minimalist / 8 standard / 10 full row",
						"increase": "More quick-select items.",
						"decrease": "Fewer, more focused."
					}
				},
				"details": {
					"what": "Quick-select bar with number keys 1-9 (configurable). Emits hotbar_changed when the selection moves.",
					"where": "Attach to a node. Create input actions 'hotbar_1' through 'hotbar_8' in Input Map, bind them to number keys.",
					"before": "Create the input actions. Even if you only use 4, create all 8 so the loop works.",
					"after": "Connect hotbar_changed to your HUD to update the visual selection.",
					"why_optimized": "Input check runs in _unhandled_input, only when an event fires. No _process polling.",
					"mistakes": "Forgetting to create the input actions means number keys do nothing. Create all of them even if you skip some.",
					"related": ["inventory_grid", "weapon_swap", "item_data"]
				}
			},
			"inventory_pickup_auto": {
				"phrases": ["auto inventory pickup", "pickup into inventory", "collect to inventory", "auto collect"],
				"code": """extends Area2D

@export var item_id: String = ""
@export var count: int = 1

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	var inventory = get_tree().get_first_node_in_group("inventory")
	if inventory == null or not inventory.has_method("add_item"):
		return
	if inventory.add_item(item_id, count):
		var quest_log = get_tree().get_first_node_in_group("quest_log")
		if quest_log != null and quest_log.has_method("advance_objective"):
			quest_log.advance_objective("collect_" + item_id, 0, count)
		queue_free()
""",
				"params": ["item_id", "count"],
				"category": "inventory",
				"subcategory": "pickup",
				"dimension": "2d",
				"difficulty": "beginner",
				"param_info": {
					"item_id": {
						"default": "",
						"range": [],
						"what": "ID of the item to add to the inventory.",
						"typical": "matches ItemData.item_id",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"count": {
						"default": 1,
						"range": [1, 999],
						"what": "How many to add on pickup.",
						"typical": "1 for unique items / 5 for materials",
						"increase": "More per pickup.",
						"decrease": "Less."
					}
				},
				"details": {
					"what": "World pickup that adds itself to the inventory when the player touches it. Only disappears on successful add.",
					"where": "Attach to an Area2D with a CollisionShape2D child. Set item_id in the Inspector.",
					"before": "Inventory in group 'inventory'. ItemData for this item_id registered with the inventory.",
					"after": "Auto-advances a quest named 'collect_<item_id>' if one exists in the quest log.",
					"why_optimized": "Only queue_free on successful add — prevents losing items when the inventory is full.",
					"mistakes": "Forgetting to register the ItemData with the inventory means pickup silently fails and the item stays in the world forever.",
					"related": ["inventory_grid", "item_data", "item_pickup_signal", "coin_pickup"]
				}
			}
		}
	}

@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"snippets": {
			"equipment_slots": {
				"phrases": ["equipment slots", "equipment system", "worn items", "gear slots"],
				"code": """extends Node

signal equipment_changed

@export var slot_names: Array[String] = ["weapon", "helmet", "chest", "boots", "ring", "amulet"]

var equipped: Dictionary = {}

func _ready() -> void:
	for slot in slot_names:
		equipped[slot] = null

func equip(item: Resource, slot: String) -> bool:
	if item == null or not equipped.has(slot):
		return false
	var required_slot: String = str(item.get("equip_slot"))
	if not required_slot.is_empty() and required_slot != slot:
		return false
	var previous = equipped[slot]
	equipped[slot] = item
	_recompute_stats()
	if previous != null:
		_return_to_inventory(previous)
	equipment_changed.emit()
	return true

func unequip(slot: String) -> void:
	if not equipped.has(slot):
		return
	var item = equipped[slot]
	if item == null:
		return
	equipped[slot] = null
	_recompute_stats()
	_return_to_inventory(item)
	equipment_changed.emit()

func get_equipped(slot: String) -> Resource:
	return equipped.get(slot, null)

func _return_to_inventory(item: Resource) -> void:
	var inventory = get_tree().get_first_node_in_group("inventory")
	if inventory != null and inventory.has_method("add_item"):
		inventory.add_item(str(item.get("item_id")), 1)

func _recompute_stats() -> void:
	# Override in a subclass or connect equipment_changed elsewhere.
	pass
""",
				"params": ["slot_names"],
				"category": "equipment",
				"subcategory": "core",
				"dimension": "any",
				"difficulty": "intermediate",
				"param_info": {
					"slot_names": {
						"default": ["weapon", "helmet", "chest", "boots", "ring", "amulet"],
						"range": [],
						"what": "Array of slot identifiers. Each item's equip_slot must match one of these.",
						"typical": "minimal: [weapon, armor] / standard: 6 slots / MMO: 12+",
						"increase": "More loadout options.",
						"decrease": "Simpler gearing."
					}
				},
				"details": {
					"what": "Manages equipped items per slot. Auto-returns swapped items to the inventory.",
					"where": "Add as a node in your player or as an autoload. Add to group 'equipment' if other systems need to find it.",
					"before": "Player must be in group 'player'. Inventory in group 'inventory'. ItemData must have equip_slot set for equippable items.",
					"after": "Connect equipment_changed to recalculate player stats, update the visual model, and refresh the equipment UI.",
					"why_optimized": "Dictionary-based slots — O(1) swap. Old items go straight to inventory without a separate pickup step.",
					"mistakes": "Forgetting to set equip_slot on the ItemData means nothing can be equipped. Check every equipment item.",
					"related": ["item_data", "equipment_stats", "equipment_visual_swap", "inventory_grid"]
				}
			},
			"equipment_stats": {
				"phrases": ["equipment stats", "stat bonuses", "stat modifiers", "gear stats"],
				"code": """extends Node

signal stats_changed(stats: Dictionary)

@export var base_stats: Dictionary = {
	"attack": 10,
	"defense": 5,
	"max_health": 100,
	"speed": 200.0
}

var current_stats: Dictionary = {}

func _ready() -> void:
	_recalculate()
	var equipment = get_tree().get_first_node_in_group("equipment")
	if equipment != null and equipment.has_signal("equipment_changed"):
		equipment.equipment_changed.connect(_recalculate)

func _recalculate() -> void:
	current_stats = base_stats.duplicate(true)
	var equipment = get_tree().get_first_node_in_group("equipment")
	if equipment != null:
		for slot in equipment.equipped.keys():
			var item = equipment.equipped[slot]
			if item == null:
				continue
			var bonuses: Dictionary = item.get("stat_bonuses")
			for stat in bonuses.keys():
				var current: float = float(current_stats.get(stat, 0))
				current_stats[stat] = current + float(bonuses[stat])
	stats_changed.emit(current_stats)

func get_stat(name: String, default_value: float = 0.0) -> float:
	return float(current_stats.get(name, default_value))
""",
				"params": ["base_stats"],
				"category": "equipment",
				"subcategory": "stats",
				"dimension": "any",
				"difficulty": "intermediate",
				"param_info": {
					"base_stats": {
						"default": {"attack": 10, "defense": 5, "max_health": 100, "speed": 200.0},
						"range": [],
						"what": "Starting stats before any equipment bonuses.",
						"typical": "attack / defense / max_health / speed / crit_chance",
						"increase": "Stronger base character.",
						"decrease": "Weaker."
					}
				},
				"details": {
					"what": "Recomputes player stats whenever equipment changes. Adds all stat_bonuses from equipped items to base values.",
					"where": "Attach to the player or a child node. Player should be in group 'player'. Equipment in group 'equipment'.",
					"before": "Equipment system set up (equipment_slots). ItemData must have stat_bonuses filled for stat-giving items.",
					"after": "Read stats via get_stat(\"attack\"). Connect stats_changed to UI that displays them.",
					"why_optimized": "Only recalculates on change (signal-driven), not every frame. duplicate(true) is a deep copy so base stays clean.",
					"mistakes": "Modifying current_stats directly instead of base_stats means bonuses stack permanently and never reset.",
					"related": ["equipment_slots", "item_data", "health_system"]
				}
			},
			"equipment_visual_swap": {
				"phrases": ["equip visual", "weapon visual swap", "show equipped", "item sprite swap"],
				"code": """@export var weapon_sprite_path: NodePath
@export var armor_sprite_path: NodePath

@onready var _weapon_sprite: Sprite2D = get_node_or_null(weapon_sprite_path)
@onready var _armor_sprite: Sprite2D = get_node_or_null(armor_sprite_path)

func _ready() -> void:
	var equipment = get_tree().get_first_node_in_group("equipment")
	if equipment != null and equipment.has_signal("equipment_changed"):
		equipment.equipment_changed.connect(_on_equipment_changed)
	_on_equipment_changed()

func _on_equipment_changed() -> void:
	var equipment = get_tree().get_first_node_in_group("equipment")
	if equipment == null:
		return
	_update_sprite(_weapon_sprite, equipment.get_equipped("weapon"))
	_update_sprite(_armor_sprite, equipment.get_equipped("chest"))

func _update_sprite(sprite: Sprite2D, item: Resource) -> void:
	if sprite == null:
		return
	if item == null:
		sprite.visible = false
		return
	var icon = item.get("icon")
	if icon is Texture2D:
		sprite.texture = icon
		sprite.visible = true
	else:
		sprite.visible = false
""",
				"params": ["weapon_sprite_path", "armor_sprite_path"],
				"category": "equipment",
				"subcategory": "visual",
				"dimension": "2d",
				"difficulty": "beginner",
				"param_info": {
					"weapon_sprite_path": {
						"default": "",
						"range": [],
						"what": "NodePath to a Sprite2D holding the visible weapon.",
						"typical": "a Sprite2D child of the player called 'WeaponSprite'",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"armor_sprite_path": {
						"default": "",
						"range": [],
						"what": "NodePath to a Sprite2D holding the visible armor.",
						"typical": "a Sprite2D child of the player called 'ArmorSprite'",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "Shows the icon of the currently equipped weapon and chest armor on the player sprite.",
					"where": "Attach to the player. Add two Sprite2D children (or use existing ones) and point the paths at them.",
					"before": "Equipment in group 'equipment'. ItemData icons assigned to weapons and armor.",
					"after": "For animated weapons, use AnimatedSprite2D instead of Sprite2D and swap animation names.",
					"why_optimized": "Only updates on equipment_changed. Uses null guards so missing nodes don't crash.",
					"mistakes": "Setting the sprite's visible = false on empty slots is important — otherwise the previous texture lingers.",
					"related": ["equipment_slots", "item_data", "sprite_hover"]
				}
			},
			"equipment_stat_apply": {
				"phrases": ["apply equipment stats", "use equipment bonus", "stat from gear", "gear effect"],
				"code": """extends CharacterBody2D

@export var base_speed: float = 200.0

@onready var _stats_node: Node = get_node_or_null("Stats")

func _ready() -> void:
	if _stats_node != null and _stats_node.has_signal("stats_changed"):
		_stats_node.stats_changed.connect(_on_stats_changed)
		_on_stats_changed(_stats_node.current_stats)

func _on_stats_changed(stats: Dictionary) -> void:
	# Update speed from equipment
	if stats.has("speed"):
		base_speed = float(stats["speed"])
	# Update health max if the health system supports it
	var health = get_node_or_null("HealthSystem")
	if health != null and stats.has("max_health"):
		health.set("max_health", int(stats["max_health"]))
""",
				"params": ["base_speed"],
				"category": "equipment",
				"subcategory": "stats",
				"dimension": "2d",
				"difficulty": "intermediate",
				"param_info": {
					"base_speed": {
						"default": 200.0,
						"range": [50.0, 500.0],
						"what": "Fallback speed when equipment stats aren't loaded yet.",
						"typical": "matches base_stats.speed from equipment_stats",
						"increase": "Faster default.",
						"decrease": "Slower default."
					}
				},
				"details": {
					"what": "Reads equipment stats into the player's movement speed and health max. Bridges the stats system to actual gameplay.",
					"where": "Attach to the player CharacterBody2D. Child nodes must be named 'Stats' (equipment_stats) and 'HealthSystem' (health_system).",
					"before": "equipment_stats attached to a child node named 'Stats'. health_system attached to a child named 'HealthSystem'.",
					"after": "For attack damage, read get_stat(\"attack\") in your attack code instead of hardcoding.",
					"why_optimized": "Signal-driven — updates only when equipment changes. No per-frame stat lookups.",
					"mistakes": "Naming the child nodes differently breaks the get_node_or_null path. Either rename the children or change the paths.",
					"related": ["equipment_stats", "health_system", "character_movement_2d"]
				}
			}
		}
	}

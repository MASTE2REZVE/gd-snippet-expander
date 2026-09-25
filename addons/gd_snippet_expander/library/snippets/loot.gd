@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"snippets": {
			"loot_table": {
				"phrases": ["loot table", "drop table", "loot data", "drop loot"],
				"code": """class_name LootTable
extends Resource

@export var table_id: String = ""
@export var item_ids: Array[String] = []
@export var drop_chances: Array[float] = []
@export var min_counts: Array[int] = []
@export var max_counts: Array[int] = []
@export var guaranteed_gold: int = 0
@export var gold_variance: int = 0
""",
				"params": ["table_id", "item_ids", "drop_chances", "min_counts", "max_counts", "guaranteed_gold", "gold_variance"],
				"category": "loot",
				"subcategory": "data",
				"dimension": "any",
				"difficulty": "intermediate",
				"param_info": {
					"table_id": {
						"default": "",
						"range": [],
						"what": "Unique identifier for this loot table.",
						"typical": "goblin_drops / boss_tier_1 / chest_common",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"item_ids": {
						"default": [],
						"range": [],
						"what": "Array of ItemData.item_id strings that can drop.",
						"typical": "5-15 entries per table",
						"increase": "More variety.",
						"decrease": "Focused loot."
					},
					"drop_chances": {
						"default": [],
						"range": [0.0, 1.0],
						"what": "Probability per item. Matches item_ids array size.",
						"typical": "0.05 rare / 0.3 common / 0.9 near-guaranteed",
						"increase": "More common drop.",
						"decrease": "Rarer."
					},
					"min_counts": {
						"default": [],
						"range": [0, 999],
						"what": "Minimum amount dropped per item. Matches item_ids array size.",
						"typical": "[1, 1, 5] for singles + stacks",
						"increase": "Bigger minimum stacks.",
						"decrease": "Smaller."
					},
					"max_counts": {
						"default": [],
						"range": [1, 9999],
						"what": "Maximum amount dropped per item.",
						"typical": "[1, 3, 15]",
						"increase": "Bigger maximum stacks.",
						"decrease": "Smaller."
					},
					"guaranteed_gold": {
						"default": 0,
						"range": [0, 100000],
						"what": "Gold always dropped, before variance.",
						"typical": "5 weak / 50 normal / 500 boss",
						"increase": "More gold.",
						"decrease": "Less."
					},
					"gold_variance": {
						"default": 0,
						"range": [0, 10000],
						"what": "Random range added to guaranteed_gold. Actual is gold + rand(-variance, +variance).",
						"typical": "0 fixed / 10 slight / 50+ wild swing",
						"increase": "More randomness.",
						"decrease": "More predictable."
					}
				},
				"details": {
					"what": "Resource describing a loot table: which items can drop, how often, in what quantities, plus gold.",
					"where": "Save as loot_table.gd. Create .tres files in the editor for each enemy or chest type.",
					"before": "ItemData resources for every drop.",
					"after": "Call roll_loot(table) from your enemy death handler.",
					"why_optimized": "Resources cache well. One table can be reused across many enemies with no memory overhead.",
					"mistakes": "Mismatched array sizes — all four arrays must match. Otherwise the last entries never roll.",
					"related": ["loot_roll", "loot_drop_pickup", "item_data", "inventory_grid"]
				}
			},
			"loot_roll": {
				"phrases": ["roll loot", "generate loot", "roll drops", "compute loot"],
				"code": """func roll_loot(table: Resource) -> Array:
	if table == null:
		return []
	var results: Array = []
	var item_ids: Array = table.get("item_ids")
	var chances: Array = table.get("drop_chances")
	var mins: Array = table.get("min_counts")
	var maxs: Array = table.get("max_counts")
	var count := min(min(item_ids.size(), chances.size()), min(mins.size(), maxs.size()))
	for i in range(count):
		var chance: float = float(chances[i])
		if randf() <= chance:
			var amount: int = randi_range(int(mins[i]), int(maxs[i]))
			results.append({"item_id": str(item_ids[i]), "count": amount})
	var gold: int = int(table.get("guaranteed_gold"))
	var variance: int = int(table.get("gold_variance"))
	if variance > 0:
		gold += randi_range(-variance, variance)
	if gold > 0:
		results.append({"item_id": "gold", "count": gold})
	return results
""",
				"params": ["table"],
				"category": "loot",
				"subcategory": "logic",
				"dimension": "any",
				"difficulty": "beginner",
				"param_info": {
					"table": {
						"default": "",
						"range": [],
						"what": "LootTable resource to roll against.",
						"typical": "the drop table for the enemy being killed",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "Rolls each item in a loot table. Returns an array of {item_id, count} dicts for successfully dropped items.",
					"where": "Attach to your enemy script or a loot manager. Call roll_loot(enemy_table) on death.",
					"before": "LootTable resource created and assigned to the enemy.",
					"after": "Pass the results to loot_drop_pickup to spawn world pickups, or directly to the inventory for auto-loot.",
					"why_optimized": "Single loop, min() clamps array sizes to the shortest. randf() and randi_range are native.",
					"mistakes": "Not seeding the RNG means every playthrough rolls identical loot. Call randomize() at game start if you want variety.",
					"related": ["loot_table", "loot_drop_pickup", "enemy_patrol", "inventory_grid"]
				}
			},
			"loot_drop_pickup": {
				"phrases": ["spawn loot pickup", "drop items in world", "loot spawn", "drop item pickup"],
				"code": """@export var pickup_scene: PackedScene
@export var scatter_radius: float = 40.0

func spawn_loot_drops(results: Array, at_position: Vector2) -> void:
	if pickup_scene == null:
		return
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for entry in results:
		var item_id := str(entry.get("item_id", ""))
		var count := int(entry.get("count", 1))
		if item_id.is_empty() or count <= 0:
			continue
		var pickup := pickup_scene.instantiate()
		var angle: float = rng.randf() * TAU
		var distance: float = rng.randf() * scatter_radius
		var offset := Vector2(cos(angle), sin(angle)) * distance
		get_tree().current_scene.add_child(pickup)
		pickup.global_position = at_position + offset
		if pickup.has_method("setup"):
			pickup.setup(item_id, count)
		elif pickup.get("item_id") != null:
			pickup.set("item_id", item_id)
			pickup.set("count", count)
""",
				"params": ["pickup_scene", "scatter_radius"],
				"category": "loot",
				"subcategory": "spawning",
				"dimension": "2d",
				"difficulty": "intermediate",
				"param_info": {
					"pickup_scene": {
						"default": "",
						"range": [],
						"what": "PackedScene for the world pickup. Should have setup(item_id, count) or item_id/count properties.",
						"typical": "reuse the inventory_pickup_auto scene from library/inventory_advanced",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"scatter_radius": {
						"default": 40.0,
						"range": [0.0, 200.0],
						"what": "Maximum distance from the death point that items scatter.",
						"typical": "0 stacked / 40 standard / 100+ wide spread",
						"increase": "Wider spread.",
						"decrease": "Tighter cluster."
					}
				},
				"details": {
					"what": "Spawns pickup instances in a circle around a death position. Each result gets a random offset so items don't perfectly overlap.",
					"where": "Attach to your enemy script or a loot manager. Call on death with the results from roll_loot().",
					"before": "A pickup scene with either a setup(item_id, count) method or item_id/count properties.",
					"after": "Add a pickup animation — items popping up briefly before settling looks better than a static spawn.",
					"why_optimized": "RandomNumberGenerator instance avoids the global RNG state. Only randoms a couple values per drop.",
					"mistakes": "Adding pickups to the enemy instead of the scene means they vanish when the enemy is freed.",
					"related": ["loot_roll", "loot_table", "inventory_pickup_auto"]
				}
			},
			"rarity_tier": {
				"phrases": ["rarity tier", "item rarity", "common rare legendary", "rarity colors"],
				"code": """enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }

const RARITY_NAMES := {
	Rarity.COMMON: "Common",
	Rarity.UNCOMMON: "Uncommon",
	Rarity.RARE: "Rare",
	Rarity.EPIC: "Epic",
	Rarity.LEGENDARY: "Legendary"
}

const RARITY_COLORS := {
	Rarity.COMMON: Color(0.8, 0.8, 0.8),
	Rarity.UNCOMMON: Color(0.4, 0.9, 0.4),
	Rarity.RARE: Color(0.4, 0.6, 1.0),
	Rarity.EPIC: Color(0.7, 0.4, 1.0),
	Rarity.LEGENDARY: Color(1.0, 0.8, 0.2)
}

func get_rarity_name(rarity: int) -> String:
	return RARITY_NAMES.get(rarity, "Unknown")

func get_rarity_color(rarity: int) -> Color:
	return RARITY_COLORS.get(rarity, Color.WHITE)

func roll_rarity() -> int:
	var roll := randf()
	if roll < 0.55:
		return Rarity.COMMON
	elif roll < 0.80:
		return Rarity.UNCOMMON
	elif roll < 0.93:
		return Rarity.RARE
	elif roll < 0.99:
		return Rarity.EPIC
	return Rarity.LEGENDARY
""",
				"params": [],
				"category": "loot",
				"subcategory": "rarity",
				"dimension": "any",
				"difficulty": "beginner",
				"details": {
					"what": "Five-tier rarity enum with names and colors. roll_rarity() returns a weighted random tier.",
					"where": "Attach to a loot manager or item database. Use get_rarity_color() to color item names in the inventory UI.",
					"before": "None.",
					"after": "Attach rarity to ItemData so each item has a fixed tier, or roll at drop time for procedural loot.",
					"why_optimized": "Dictionary constants — no allocation, O(1) lookup. Enum is an int so it saves efficiently.",
					"mistakes": "Using the rarity colors on text but forgetting to add an outline means light colors are unreadable on bright backgrounds.",
					"related": ["loot_table", "item_data", "inventory_ui_grid"]
				}
			},
			"loot_auto_collect": {
				"phrases": ["auto collect loot", "auto loot", "automatic loot pickup", "auto pickup gold"],
				"code": """extends Area2D

@export var magnet_speed: float = 500.0
@export var collection_delay: float = 0.3

var _active: bool = true
var _target: Node2D = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	await get_tree().create_timer(collection_delay).timeout
	_active = true

func _on_body_entered(body: Node2D) -> void:
	if not _active:
		return
	if body.is_in_group("player"):
		_target = body

func _process(delta: float) -> void:
	if _target == null or not is_instance_valid(_target):
		return
	global_position = global_position.move_toward(_target.global_position, magnet_speed * delta)
	if global_position.distance_to(_target.global_position) < 8.0:
		_collect()

func _collect() -> void:
	var item_id := ""
	var count := 1
	if get("item_id") != null:
		item_id = str(get("item_id"))
	if get("count") != null:
		count = int(get("count"))
	var inventory = get_tree().get_first_node_in_group("inventory")
	if inventory != null and inventory.has_method("add_item") and not item_id.is_empty():
		inventory.add_item(item_id, count)
	queue_free()
""",
				"params": ["magnet_speed", "collection_delay"],
				"category": "loot",
				"subcategory": "collection",
				"dimension": "2d",
				"difficulty": "intermediate",
				"param_info": {
					"magnet_speed": {
						"default": 500.0,
						"range": [100.0, 2000.0],
						"what": "How fast the pickup flies toward the player.",
						"typical": "300 gentle / 500 standard / 1000+ snappy",
						"increase": "Faster pickup.",
						"decrease": "Slower, more visible."
					},
					"collection_delay": {
						"default": 0.3,
						"range": [0.0, 2.0],
						"what": "Seconds before the magnet activates. Lets the pickup spawn animation play first.",
						"typical": "0.0 immediate / 0.3 short pause / 1.0 cinematic",
						"increase": "Longer delay before collection.",
						"decrease": "Shorter."
					}
				},
				"details": {
					"what": "Pickup that flies to the player and auto-collects after a brief delay. Feels better than instant pickup on death.",
					"where": "Attach to an Area2D with item_id and count properties set at spawn time (from loot_drop_pickup).",
					"before": "Inventory in group 'inventory'. ItemData registered for the item_id.",
					"after": "Add a small particle trail while the pickup flies to the player.",
					"why_optimized": "move_toward is a single built-in vector op. Only runs _process when a target is set.",
					"mistakes": "Setting collection_delay to 0 makes pickups snap to the player instantly, which looks glitchy. Keep 0.2-0.5s minimum.",
					"related": ["loot_drop_pickup", "inventory_pickup_auto", "particle_trail"]
				}
			}
		}
	}

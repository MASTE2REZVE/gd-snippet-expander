@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"snippets": {
			"coin_pickup": {
				"phrases": ["coin pickup", "pickup coin", "collect coin"],
				"code": """extends Area2D

signal collected

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		collected.emit()
		queue_free()
""",
				"params": [],
				"category": "pickup",
				"dimension": "2d",
				"difficulty": "beginner",
				"details": {
					"what": "A collectible that disappears when the player touches it and emits a collected signal.",
					"where": "Attach to an Area2D with a CollisionShape2D child and a Sprite2D for the visual.",
					"before": "Add the player to a group called 'player'.",
					"after": "Connect the collected signal to your score system.",
					"why_optimized": "queue_free is deferred-safe and won't crash mid-physics.",
					"mistakes": "Forgetting to add the player to the 'player' group means nothing happens on touch.",
					"related": ["health_pickup", "powerup", "score_display"]
				}
			},
			"health_pickup": {
				"phrases": ["health pickup", "pickup health", "heart pickup"],
				"code": """extends Area2D

@export var heal_amount: int = 25

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("heal"):
		body.heal(heal_amount)
		queue_free()
""",
				"params": ["heal_amount"],
				"category": "pickup",
				"dimension": "2d",
				"difficulty": "beginner",
				"param_info": {
					"heal_amount": {
						"default": 25,
						"range": [1, 100],
						"what": "How much health is restored.",
						"typical": "10 small snack / 25 standard / 50 large / 100 full heal",
						"increase": "Pickup becomes more valuable.",
						"decrease": "Requires picking up more to heal."
					}
				},
				"details": {
					"what": "Restores health to anything that has a heal() method.",
					"where": "Attach to an Area2D with a CollisionShape2D and Sprite2D child.",
					"before": "The target must have heal(amount). health_system snippet provides one.",
					"after": "Add a spawn animation and floating idle motion for polish.",
					"why_optimized": "has_method check means anything with heal works — player or NPC.",
					"mistakes": "Attaching to a StaticBody2D — Area2D is what detects overlap.",
					"related": ["health_system", "coin_pickup", "powerup"]
				}
			},
			"powerup": {
				"phrases": ["powerup", "power up", "power-up pickup"],
				"code": """extends Area2D

@export var duration: float = 8.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("apply_powerup"):
		body.apply_powerup(duration)
		queue_free()
""",
				"params": ["duration"],
				"category": "pickup",
				"dimension": "2d",
				"difficulty": "beginner",
				"param_info": {
					"duration": {
						"default": 8.0,
						"range": [1.0, 60.0],
						"what": "How long the powerup lasts, in seconds.",
						"typical": "3 short burst / 8 standard / 20 long / 60+ permanent-ish",
						"increase": "Player keeps the power longer.",
						"decrease": "Feels temporary and rushed."
					}
				},
				"details": {
					"what": "Generic powerup pickup — calls apply_powerup(duration) on the player.",
					"where": "Attach to an Area2D. The player must implement apply_powerup(duration).",
					"before": "Player needs an apply_powerup() function.",
					"after": "Add a HUD timer showing how much longer the powerup lasts.",
					"why_optimized": "Delegates the effect to the player, so one pickup scene works for any effect.",
					"mistakes": "Hardcoding the effect in the pickup means you need a new scene for every powerup type.",
					"related": ["coin_pickup", "health_pickup", "weapon_pickup"]
				}
			},
			"item_pickup_signal": {
				"phrases": ["item pickup signal", "pickup signal"],
				"code": """signal item_picked(item_id: String)

func pickup(item_id: String) -> void:
	item_picked.emit(item_id)
	queue_free()
""",
				"params": [],
				"category": "pickup",
				"dimension": "any",
				"difficulty": "beginner",
				"details": {
					"what": "Emits a signal with an item ID string, then deletes itself.",
					"where": "Attach to any pickup. Call pickup(\"sword\") or pickup(\"key_red\") when collected.",
					"before": "None.",
					"after": "Connect item_picked to your inventory or quest system.",
					"why_optimized": "String IDs are flexible — one pickup type handles every item.",
					"mistakes": "Freeing the node before emitting means listeners can't react.",
					"related": ["inventory_system", "inventory_add", "weapon_pickup"]
				}
			},
			"auto_pickup_area": {
				"phrases": ["auto pickup area", "magnet pickup", "attract pickup"],
				"code": """@export var magnet_speed: float = 400.0
@export var player_path: NodePath

@onready var _player: Node2D = get_node(player_path) as Node2D

func _process(delta: float) -> void:
	global_position = global_position.move_toward(_player.global_position, magnet_speed * delta)
""",
				"params": ["magnet_speed", "player_path"],
				"category": "pickup",
				"dimension": "2d",
				"difficulty": "beginner",
				"param_info": {
					"magnet_speed": {
						"default": 400.0,
						"range": [50.0, 2000.0],
						"what": "How fast the pickup flies toward the player.",
						"typical": "200 gentle / 400 standard / 800+ snappy",
						"increase": "Pickup reaches the player faster.",
						"decrease": "Slow drift, easier to see."
					},
					"player_path": {
						"default": "",
						"range": [],
						"what": "Path to the player.",
						"typical": "NodePath set in the Inspector",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "Pickup that drifts toward the player automatically once spawned.",
					"where": "Attach to any pickup. Set player_path in the Inspector.",
					"before": "Player must exist. Combine with a detection area to only magnet when close.",
					"after": "Add a tween on scale for a satisfying pull effect.",
					"why_optimized": "move_toward is a single built-in vector operation.",
					"mistakes": "Magnetizing from anywhere on the map makes the pickup fly across the screen.",
					"related": ["coin_pickup", "health_pickup", "pickup_range"]
				}
			},
			"inventory_add": {
				"phrases": ["add inventory", "inventory add item", "add to inventory"],
				"code": """var inventory: Dictionary = {}

func add_item(item_id: String, amount: int = 1) -> void:
	inventory[item_id] = inventory.get(item_id, 0) + amount
""",
				"params": [],
				"category": "pickup",
				"dimension": "any",
				"difficulty": "beginner",
				"details": {
					"what": "Adds an item to a Dictionary-based inventory. Minimal.",
					"where": "Attach to the player or an autoload.",
					"before": "None.",
					"after": "For a full system with signals and removal, use inventory_system.",
					"why_optimized": "Dictionary.get with a default avoids a has() check.",
					"mistakes": "Forgetting a default in get() crashes if the key doesn't exist yet.",
					"related": ["inventory_system", "item_pickup_signal", "coin_pickup"]
				}
			},
			"inventory_system": {
				"phrases": ["inventory", "inventory system", "item inventory"],
				"code": """signal inventory_changed(inventory: Dictionary)

var items: Dictionary = {}

func add_item(id: String, amount: int = 1) -> void:
	items[id] = items.get(id, 0) + amount
	inventory_changed.emit(items)

func remove_item(id: String, amount: int = 1) -> bool:
	if items.get(id, 0) < amount:
		return false
	items[id] -= amount
	if items[id] <= 0:
		items.erase(id)
	inventory_changed.emit(items)
	return true

func has_item(id: String, amount: int = 1) -> bool:
	return items.get(id, 0) >= amount
""",
				"params": [],
				"category": "pickup",
				"dimension": "any",
				"difficulty": "beginner",
				"details": {
					"what": "Inventory with add/remove/has and a change signal. Dictionary-backed.",
					"where": "Attach to the player, or make it an autoload for global inventory.",
					"before": "None.",
					"after": "Connect inventory_changed to UI to show the current items.",
					"why_optimized": "Dictionary-based with O(1) lookups. Removes zero-count entries to keep it clean.",
					"mistakes": "Forgetting to emit inventory_changed means the UI never updates.",
					"related": ["inventory_add", "item_pickup_signal", "weapon_pickup"]
				}
			},
			"weapon_pickup": {
				"phrases": ["weapon pickup", "pickup weapon"],
				"code": """extends Area2D

@export var weapon_scene: PackedScene

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("equip_weapon"):
		body.equip_weapon(weapon_scene)
		queue_free()
""",
				"params": ["weapon_scene"],
				"category": "pickup",
				"dimension": "2d",
				"difficulty": "beginner",
				"param_info": {
					"weapon_scene": {
						"default": "",
						"range": [],
						"what": "The weapon scene (.tscn) to give the player.",
						"typical": "one .tscn per weapon",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "Pickup that hands a weapon scene to the player.",
					"where": "Attach to an Area2D. Set weapon_scene in the Inspector.",
					"before": "Player must have an equip_weapon(scene) function. Use weapon_swap as a base.",
					"after": "Add a visual preview of the weapon on the pickup sprite.",
					"why_optimized": "Uses PackedScene reference — no instantiation until the player picks it up.",
					"mistakes": "Instantiating the weapon on pickup spawns it in the world, not in the player's hands.",
					"related": ["weapon_swap", "item_pickup_signal", "powerup"]
				}
			},
			"pickup_range": {
				"phrases": ["pickup range", "pickup detection", "collect range"],
				"code": """extends Area2D

signal item_in_range(item: Node2D)

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("pickups"):
		item_in_range.emit(area)
""",
				"params": [],
				"category": "pickup",
				"dimension": "2d",
				"difficulty": "beginner",
				"details": {
					"what": "Detects nearby pickups and emits a signal. Used with a 'press to collect' system.",
					"where": "Attach to an Area2D child of the player.",
					"before": "Add pickups to a group called 'pickups'.",
					"after": "Combine with auto_pickup_area to magnet collected items.",
					"why_optimized": "Signal-based, no polling of positions.",
					"mistakes": "Using body_entered instead of area_entered — pickups are usually Areas, not bodies.",
					"related": ["auto_pickup_area", "coin_pickup", "item_pickup_signal"]
				}
			}
		}
	}

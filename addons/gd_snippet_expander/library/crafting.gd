@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"snippets": {
			"crafting_recipe": {
				"phrases": ["crafting recipe", "recipe data", "craft recipe", "recipe definition"],
				"code": """class_name CraftingRecipe
extends Resource

@export var recipe_id: String = ""
@export var display_name: String = ""
@export var ingredients: Array[String] = []
@export var ingredient_counts: Array[int] = []
@export var result_item: String = ""
@export var result_count: int = 1
@export var craft_time: float = 0.0
@export var required_station: String = ""
""",
				"params": ["recipe_id", "display_name", "ingredients", "ingredient_counts", "result_item", "result_count", "craft_time", "required_station"],
				"category": "crafting",
				"subcategory": "data",
				"dimension": "any",
				"difficulty": "intermediate",
				"param_info": {
					"recipe_id": {
						"default": "",
						"range": [],
						"what": "Unique identifier for the recipe. Used in save data and lookups.",
						"typical": "iron_sword / health_potion / torch",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"ingredients": {
						"default": [],
						"range": [],
						"what": "Array of item IDs required to craft.",
						"typical": "['iron_ingot', 'wood']",
						"increase": "More complex recipe.",
						"decrease": "Simpler."
					},
					"ingredient_counts": {
						"default": [],
						"range": [],
						"what": "How many of each ingredient. Matches ingredients array size.",
						"typical": "[3, 1] for 3 iron + 1 wood",
						"increase": "More demanding.",
						"decrease": "Easier."
					},
					"result_item": {
						"default": "",
						"range": [],
						"what": "Item ID produced by the recipe.",
						"typical": "matches an ItemData.item_id",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"result_count": {
						"default": 1,
						"range": [1, 999],
						"what": "How many of the result item are produced.",
						"typical": "1 for equipment / 5 for arrows / 3 for potions",
						"increase": "More per craft.",
						"decrease": "Less."
					},
					"craft_time": {
						"default": 0.0,
						"range": [0.0, 30.0],
						"what": "Seconds the craft takes. Zero means instant.",
						"typical": "0 instant / 2 standard / 10 crafting stations",
						"increase": "Longer craft.",
						"decrease": "Shorter."
					},
					"required_station": {
						"default": "",
						"range": [],
						"what": "If non-empty, only craftable at a station with this ID.",
						"typical": "anvil / furnace / workbench / alchemy_table",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "Resource describing a crafting recipe: ingredients, result, time, and required station.",
					"where": "Save as crafting_recipe.gd. Create .tres files in the editor for each recipe.",
					"before": "ItemData resources for all ingredients and results.",
					"after": "Register recipes with a crafting manager. Check availability with crafting_can_craft().",
					"why_optimized": "Resources are shared and cached. Recipe definitions load once at startup.",
					"mistakes": "Mismatched array sizes — ingredients and ingredient_counts must match, or the recipe can never be crafted.",
					"related": ["crafting_can_craft", "crafting_station", "item_data", "inventory_grid"]
				}
			},
			"crafting_can_craft": {
				"phrases": ["can craft", "check ingredients", "has materials", "craft check"],
				"code": """func can_craft(recipe: Resource, inventory: Node) -> bool:
	if recipe == null or inventory == null:
		return false
	var ingredients: Array = recipe.get("ingredients")
	var counts: Array = recipe.get("ingredient_counts")
	if ingredients.size() != counts.size():
		return false
	for i in range(ingredients.size()):
		var item_id := str(ingredients[i])
		var need: int = int(counts[i])
		if not inventory.has_method("has_item"):
			return false
		if not inventory.has_item(item_id, need):
			return false
	return true

func get_missing_ingredients(recipe: Resource, inventory: Node) -> Array:
	var missing: Array = []
	if recipe == null or inventory == null:
		return missing
	var ingredients: Array = recipe.get("ingredients")
	var counts: Array = recipe.get("ingredient_counts")
	for i in range(ingredients.size()):
		var item_id := str(ingredients[i])
		var need: int = int(counts[i])
		var has: int = 0
		if inventory.has_method("count_item"):
			has = inventory.count_item(item_id)
		elif inventory.has_method("has_item"):
			has = need if inventory.has_item(item_id, need) else 0
		if has < need:
			missing.append({"item_id": item_id, "need": need, "have": has})
	return missing
""",
				"params": ["recipe", "inventory"],
				"category": "crafting",
				"subcategory": "logic",
				"dimension": "any",
				"difficulty": "beginner",
				"param_info": {
					"recipe": {
						"default": "",
						"range": [],
						"what": "CraftingRecipe resource to check.",
						"typical": "the recipe the player is trying to craft",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"inventory": {
						"default": "",
						"range": [],
						"what": "Node with has_item and/or count_item methods (from inventory_grid).",
						"typical": "the node in group 'inventory'",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "Checks whether the player has every ingredient. Also returns a list of what's missing for UI display.",
					"where": "Attach to your crafting manager or a UI script. Call before showing the Craft button as enabled.",
					"before": "Inventory with has_item and count_item methods.",
					"after": "Grey out the Craft button when can_craft returns false. Show missing ingredients from get_missing_ingredients.",
					"why_optimized": "Single loop, early exit on first missing ingredient. No allocations for the fast path.",
					"mistakes": "Assuming the inventory has has_item. Use has_method checks if you want to support different inventory implementations.",
					"related": ["crafting_recipe", "crafting_station", "inventory_grid"]
				}
			},
			"crafting_execute": {
				"phrases": ["craft item", "execute craft", "perform craft", "make item"],
				"code": """signal craft_started(recipe_id: String)
signal craft_completed(recipe_id: String)
signal craft_failed(recipe_id: String, reason: String)

func craft(recipe: Resource, inventory: Node) -> bool:
	if recipe == null or inventory == null:
		return false
	var recipe_id := str(recipe.get("recipe_id"))
	if not can_craft(recipe, inventory):
		craft_failed.emit(recipe_id, "Missing ingredients")
		return false
	var ingredients: Array = recipe.get("ingredients")
	var counts: Array = recipe.get("ingredient_counts")
	craft_started.emit(recipe_id)
	var craft_time: float = float(recipe.get("craft_time"))
	if craft_time > 0.0:
		await get_tree().create_timer(craft_time).timeout
	# Re-check in case inventory changed during the craft
	if not can_craft(recipe, inventory):
		craft_failed.emit(recipe_id, "Ingredients changed during craft")
		return false
	for i in range(ingredients.size()):
		inventory.remove_item(str(ingredients[i]), int(counts[i]))
	var result_item := str(recipe.get("result_item"))
	var result_count: int = int(recipe.get("result_count"))
	inventory.add_item(result_item, result_count)
	craft_completed.emit(recipe_id)
	return true
""",
				"params": [],
				"category": "crafting",
				"subcategory": "logic",
				"dimension": "any",
				"difficulty": "intermediate",
				"details": {
					"what": "Consumes ingredients and produces the result. Handles craft time with optional delay. Emits signals for UI.",
					"where": "Attach to your crafting manager. Call craft(recipe, inventory) when the player confirms.",
					"before": "can_craft and get_missing_ingredients in the same script (or copied in). Inventory with add_item and remove_item methods.",
					"after": "Connect craft_started to show a progress bar. Connect craft_completed to play a sound. Connect craft_failed to show an error message.",
					"why_optimized": "Re-checks availability after the delay to prevent race conditions. Signals keep UI decoupled from the craft logic.",
					"mistakes": "Not re-checking after the craft time means a player can drop ingredients mid-craft and still get the result.",
					"related": ["crafting_recipe", "crafting_can_craft", "inventory_grid"]
				}
			},
			"crafting_station": {
				"phrases": ["crafting station", "anvil", "workbench", "crafting station interaction"],
				"code": """extends Area2D

@export var station_id: String = "workbench"
@export var recipes: Array[Resource] = []

signal player_entered
signal player_exited

var _player_in_range: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _unhandled_input(event: InputEvent) -> void:
	if _player_in_range and event.is_action_pressed("interact"):
		open_crafting_ui()

func open_crafting_ui() -> void:
	var ui = get_tree().get_first_node_in_group("crafting_ui")
	if ui != null and ui.has_method("open"):
		ui.open(station_id, recipes)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = true
		player_entered.emit()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = false
		player_exited.emit()
""",
				"params": ["station_id", "recipes"],
				"category": "crafting",
				"subcategory": "station",
				"dimension": "2d",
				"difficulty": "beginner",
				"required_actions": ["interact"],
				"param_info": {
					"station_id": {
						"default": "workbench",
						"range": [],
						"what": "Identifier for this station type. Recipes with matching required_station only appear here.",
						"typical": "anvil / furnace / workbench / alchemy_table",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"recipes": {
						"default": [],
						"range": [],
						"what": "Array of CraftingRecipe resources available at this station.",
						"typical": "5-20 recipes per station",
						"increase": "More options.",
						"decrease": "Focused crafting."
					}
				},
				"details": {
					"what": "An Area2D crafting station. Opens the crafting UI when the player is in range and presses Interact.",
					"where": "Attach to an Area2D child of the station sprite. Add the crafting UI to group 'crafting_ui'.",
					"before": "Create input action 'interact'. Crafting UI in group 'crafting_ui' with an open(station_id, recipes) method.",
					"after": "Add a floating prompt that appears when player_entered fires ('[E] Use workbench').",
					"why_optimized": "get_first_node_in_group avoids scene path dependency. Input check is event-driven.",
					"mistakes": "Forgetting to add recipes in the Inspector means an empty crafting list.",
					"related": ["crafting_recipe", "crafting_execute", "crafting_ui"]
				}
			},
			"crafting_disassemble": {
				"phrases": ["disassemble", "salvage item", "break down item", "dismantle"],
				"code": """@export var salvage_ratio: float = 0.5

func disassemble(item: Resource, inventory: Node) -> bool:
	if item == null or inventory == null:
		return false
	if not inventory.has_method("remove_item") or not inventory.has_method("add_item"):
		return false
	var item_id := str(item.get("item_id"))
	if not inventory.has_item(item_id, 1):
		return false
	# Get the recipe that produces this item
	var recipes: Array = get_recipes_for(item_id)
	if recipes.is_empty():
		return false
	var recipe: Resource = recipes[0]
	inventory.remove_item(item_id, 1)
	var ingredients: Array = recipe.get("ingredients")
	var counts: Array = recipe.get("ingredient_counts")
	for i in range(ingredients.size()):
		var return_count: int = max(1, int(float(counts[i]) * salvage_ratio))
		inventory.add_item(str(ingredients[i]), return_count)
	return true

var _recipes_by_result: Dictionary = {}

func register_recipes(recipes: Array) -> void:
	for recipe in recipes:
		if recipe == null:
			continue
		var result := str(recipe.get("result_item"))
		if result.is_empty():
			continue
		if not _recipes_by_result.has(result):
			_recipes_by_result[result] = []
		_recipes_by_result[result].append(recipe)

func get_recipes_for(item_id: String) -> Array:
	return _recipes_by_result.get(item_id, [])
""",
				"params": ["salvage_ratio"],
				"category": "crafting",
				"subcategory": "logic",
				"dimension": "any",
				"difficulty": "intermediate",
				"param_info": {
					"salvage_ratio": {
						"default": 0.5,
						"range": [0.0, 1.0],
						"what": "Fraction of ingredients returned when disassembling.",
						"typical": "0.25 harsh / 0.5 standard / 0.75 generous / 1.0 no penalty",
						"increase": "Player gets more back.",
						"decrease": "Less — makes crafting feel more permanent."
					}
				},
				"details": {
					"what": "Reverses a recipe: consumes an item and returns a fraction of its ingredients.",
					"where": "Attach to your crafting manager. Register recipes with register_recipes() at startup.",
					"before": "Recipes registered. Inventory with add_item, remove_item, and has_item.",
					"after": "Add a confirmation dialog before disassembly — losing items by accident is bad UX.",
					"why_optimized": "Recipes are indexed by result item for O(1) lookup. Salvage math is one multiply per ingredient.",
					"mistakes": "Using max(1, ...) means an ingredient with count 1 always returns 1, even at 0.25 ratio. That's intentional — a crafting recipe shouldn't give zero back.",
					"related": ["crafting_recipe", "crafting_execute", "inventory_grid"]
				}
			}
		}
	}

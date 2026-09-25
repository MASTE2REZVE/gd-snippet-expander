@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"blueprints": {
			"shop_ui": {
				"title": "Shop UI",
				"phrases": ["shop ui", "shop screen", "merchant ui", "buy sell ui"],
				"category": "shop",
				"subcategory": "ui",
				"dimension": "ui",
				"difficulty": "intermediate",
				"root": {
					"type": "CanvasLayer",
					"name": "ShopUI"
				},
				"required_children": [
					{"type": "PanelContainer", "name": "Panel", "properties": {"anchors_preset": 15, "offset_left": 60, "offset_top": 60, "offset_right": -60, "offset_bottom": -60}},
					{"type": "VBoxContainer", "name": "Layout", "properties": {}},
					{"type": "HBoxContainer", "name": "Header", "properties": {}},
					{"type": "Label", "name": "Title", "properties": {"text": "Shop"}},
					{"type": "Label", "name": "GoldLabel", "properties": {"text": "Gold: 0"}},
					{"type": "Button", "name": "CloseButton", "properties": {"text": "X"}},
					{"type": "TabContainer", "name": "Tabs", "properties": {}},
					{"type": "VBoxContainer", "name": "BuyTab", "properties": {}},
					{"type": "ScrollContainer", "name": "BuyScroll", "properties": {}},
					{"type": "VBoxContainer", "name": "BuyList", "properties": {}},
					{"type": "VBoxContainer", "name": "SellTab", "properties": {}},
					{"type": "ScrollContainer", "name": "SellScroll", "properties": {}},
					{"type": "VBoxContainer", "name": "SellList", "properties": {}}
				],
				"recommended_children": [],
				"script": "",
				"required_actions": [],
				"setup_notes": [
					"Note: Re-parent after building so the structure is:",
					"  Panel",
					"    Layout (VBoxContainer)",
					"      Header (HBoxContainer) — Title, GoldLabel, CloseButton",
					"      Tabs (TabContainer)",
					"        BuyTab (VBoxContainer, renamed to 'Buy')",
					"          BuyScroll → BuyList",
					"        SellTab (VBoxContainer, renamed to 'Sell')",
					"          SellScroll → SellList",
					"Create a 'shop_row.tscn' scene: an HBoxContainer with icon, name label, price label, and a Buy/Sell Button.",
					"Assign a script to the root CanvasLayer with:",
					"  open(station_id, recipes) or open(shop_node) — reads stock and populates lists",
					"  _populate_buy() — one row per item with current buy price",
					"  _populate_sell() — one row per inventory item with sell price",
					"  Connect each row's Buy button to shop_buy.buy_item(item, inventory, 1)",
					"  Connect each row's Sell button to shop_sell.sell_item(item, inventory, 1)",
					"  Update GoldLabel on inventory_changed",
					"Add to group 'shop_ui' if you want stations to find it programmatically.",
					"Hide the CanvasLayer by default."
				],
				"next_steps": [
					{"snippet": "shop_buy", "why": "Buy logic."},
					{"snippet": "shop_sell", "why": "Sell logic."},
					{"snippet": "shop_pricing", "why": "Price calculation with reputation."},
					{"snippet": "shop_stock", "why": "Stock tracking with restock."}
				],
				"mistakes": [
					"Hardcoding prices instead of using shop_pricing means you can't add reputation discounts later.",
					"Forgetting to refresh the Sell tab after a purchase means the sold items still appear.",
					"Not disabling the Buy button when the player can't afford an item — always show them why they can't buy.",
					"Using a Panel that doesn't block clicks passes them through to the game world underneath."
				]
			},
			"crafting_bench_ui": {
				"title": "Crafting Bench UI",
				"phrases": ["crafting ui", "crafting bench", "crafting screen", "recipe ui"],
				"category": "crafting",
				"subcategory": "ui",
				"dimension": "ui",
				"difficulty": "intermediate",
				"root": {
					"type": "CanvasLayer",
					"name": "CraftingUI"
				},
				"required_children": [
					{"type": "PanelContainer", "name": "Panel", "properties": {"anchors_preset": 15, "offset_left": 60, "offset_top": 60, "offset_right": -60, "offset_bottom": -60}},
					{"type": "HBoxContainer", "name": "Split", "properties": {}},
					{"type": "VBoxContainer", "name": "RecipeList", "properties": {}},
					{"type": "Label", "name": "ListTitle", "properties": {"text": "Recipes"}},
					{"type": "ScrollContainer", "name": "RecipeScroll", "properties": {}},
					{"type": "VBoxContainer", "name": "RecipeItems", "properties": {}},
					{"type": "VBoxContainer", "name": "DetailPanel", "properties": {}},
					{"type": "Label", "name": "DetailName", "properties": {"text": "Select a recipe"}},
					{"type": "VBoxContainer", "name": "IngredientRows", "properties": {}},
					{"type": "Label", "name": "ResultLabel", "properties": {"text": ""}},
					{"type": "Button", "name": "CraftButton", "properties": {"text": "Craft"}},
					{"type": "Button", "name": "CloseButton", "properties": {"text": "Close"}}
				],
				"recommended_children": [],
				"script": "",
				"required_actions": [],
				"setup_notes": [
					"Note: Re-parent after building so the structure is:",
					"  Panel",
					"    Split (HBoxContainer)",
					"      RecipeList (VBoxContainer)",
					"        ListTitle",
					"        RecipeScroll → RecipeItems",
					"      DetailPanel (VBoxContainer)",
					"        DetailName",
					"        IngredientRows",
					"        ResultLabel",
					"        CraftButton",
					"        CloseButton",
					"Assign a script to the root CanvasLayer with:",
					"  open(station_id, recipes) — populate RecipeItems with one Button per recipe",
					"  _on_recipe_selected(recipe) — show DetailName, list ingredients with [have/need] counts",
					"  _update_craft_button() — grey out if can_craft returns false",
					"  _on_craft_pressed() — call crafting_execute.craft(recipe, inventory)",
					"Connect the crafting manager's craft_completed signal to refresh the ingredient list.",
					"Hide the CanvasLayer by default.",
					"Add to group 'crafting_ui' if stations should find it automatically."
				],
				"next_steps": [
					{"snippet": "crafting_recipe", "why": "Recipe data."},
					{"snippet": "crafting_can_craft", "why": "Availability check."},
					{"snippet": "crafting_execute", "why": "Perform the craft."},
					{"snippet": "crafting_station", "why": "The world object that opens this UI."}
				],
				"mistakes": [
					"Not showing ingredient counts (have/need) means the player can't tell what they're missing.",
					"Not disabling the Craft button when materials are missing — always give the option greyed out.",
					"Building the recipe list every frame instead of only on open — expensive when there are many recipes.",
					"Using plain Labels for ingredients loses the ability to color missing items red."
				]
			},
			"quest_log_ui_blueprint": {
				"title": "Quest Log UI",
				"phrases": ["quest log ui blueprint", "quest journal ui", "quest tracker ui", "quest panel"],
				"category": "quest",
				"subcategory": "ui",
				"dimension": "ui",
				"difficulty": "intermediate",
				"root": {
					"type": "CanvasLayer",
					"name": "QuestLogUI"
				},
				"required_children": [
					{"type": "PanelContainer", "name": "Panel", "properties": {"anchors_preset": 15, "offset_left": 60, "offset_top": 60, "offset_right": -60, "offset_bottom": -60}},
					{"type": "VBoxContainer", "name": "Layout", "properties": {}},
					{"type": "HBoxContainer", "name": "Header", "properties": {}},
					{"type": "Label", "name": "Title", "properties": {"text": "Quests"}},
					{"type": "Button", "name": "CloseButton", "properties": {"text": "X"}},
					{"type": "TabContainer", "name": "Tabs", "properties": {}},
					{"type": "ScrollContainer", "name": "ActiveScroll", "properties": {}},
					{"type": "VBoxContainer", "name": "ActiveList", "properties": {}},
					{"type": "ScrollContainer", "name": "CompletedScroll", "properties": {}},
					{"type": "VBoxContainer", "name": "CompletedList", "properties": {}}
				],
				"recommended_children": [],
				"script": "",
				"required_actions": ["toggle_quest_log"],
				"setup_notes": [
					"Note: Re-parent after building so the structure is:",
					"  Panel",
					"    Layout (VBoxContainer)",
					"      Header (HBoxContainer) — Title, CloseButton",
					"      Tabs (TabContainer)",
					"        ActiveScroll (renamed to 'Active') → ActiveList",
					"        CompletedScroll (renamed to 'Completed') → CompletedList",
					"Assign a script to the root CanvasLayer with:",
					"  - Toggle visible on 'toggle_quest_log' action",
					"  - Rebuild both lists when quest_log emits quest_added / quest_completed / objective_advanced",
					"  - Each Active entry: quest title, description, list of objectives with [x] / [ ] and progress",
					"  - Each Completed entry: greyed-out title only",
					"Note: the 'quest_log_ui' snippet already does most of this. This blueprint provides the container and layout — pair with the snippet for the logic.",
					"Hide the CanvasLayer by default.",
					"Create input action 'toggle_quest_log' in Input Map (usually J or Tab)."
				],
				"next_steps": [
					{"snippet": "quest_log_ui", "why": "The logic to display quests in this layout."},
					{"snippet": "quest_log", "why": "The quest manager autoload."},
					{"snippet": "quest_data", "why": "Quest resources."},
					{"blueprint": "hud_score_ui", "why": "Add a small 'active quest' tracker to the main HUD."}
				],
				"mistakes": [
					"Forgetting the toggle action means the UI is never openable.",
					"Rebuilding the whole list on every frame instead of on signals — expensive for large quest logs.",
					"Not showing completed quests at all — players like to see what they've accomplished.",
					"Making the panel opaque white instead of a semi-transparent dark overlay — hard on the eyes."
				]
			}
		}
	}

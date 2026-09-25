@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"blueprints": {
			"inventory_ui_grid": {
				"title": "Inventory Grid UI",
				"phrases": ["inventory ui", "inventory screen", "grid inventory ui", "inventory panel"],
				"category": "inventory",
				"subcategory": "ui",
				"dimension": "ui",
				"difficulty": "intermediate",
				"root": {
					"type": "CanvasLayer",
					"name": "InventoryUI"
				},
				"required_children": [
					{"type": "PanelContainer", "name": "Panel", "properties": {"anchors_preset": 15, "offset_left": 40, "offset_top": 40, "offset_right": -40, "offset_bottom": -40}},
					{"type": "VBoxContainer", "name": "Layout", "properties": {}},
					{"type": "HBoxContainer", "name": "Header", "properties": {}},
					{"type": "Label", "name": "Title", "properties": {"text": "Inventory"}},
					{"type": "Button", "name": "SortButton", "properties": {"text": "Sort"}},
					{"type": "Button", "name": "CloseButton", "properties": {"text": "X"}},
					{"type": "GridContainer", "name": "SlotGrid", "properties": {"columns": 6}},
					{"type": "Label", "name": "GoldLabel", "properties": {"text": "Gold: 0"}}
				],
				"recommended_children": [],
				"script": "",
				"required_actions": ["toggle_inventory"],
				"setup_notes": [
					"Note: The parent-child structure must be arranged after building. Layout should be:",
					"  Panel",
					"    Layout (VBoxContainer)",
					"      Header (HBoxContainer)",
					"        Title (Label)",
					"        SortButton",
					"        CloseButton",
					"      SlotGrid (GridContainer, 6 columns)",
					"      GoldLabel",
					"Create a 'slot.tscn' scene: a PanelContainer with a TextureRect (icon) and a Label (count). Save it as res://scenes/ui/inventory_slot.tscn.",
					"Assign a script to the root CanvasLayer that:",
					"  - Populates SlotGrid with 24 slot instances on _ready",
					"  - Connects to the inventory's inventory_changed signal to refresh slots",
					"  - Connects SortButton.pressed to inventory.sort_by_type()",
					"  - Connects CloseButton.pressed to hide()",
					"  - Toggles visible on the 'toggle_inventory' action",
					"Add 'inventory_ui' to the node's groups if you want other systems to open it programmatically.",
					"Hide the CanvasLayer by default in the Inspector."
				],
				"next_steps": [
					{"snippet": "inventory_grid", "why": "The inventory data this UI displays."},
					{"snippet": "inventory_sort", "why": "Sort logic for the Sort button."},
					{"snippet": "item_tooltip", "why": "Tooltip when hovering a slot."},
					{"blueprint": "equipment_panel_ui", "why": "Gear panel next to the inventory."}
				],
				"mistakes": [
					"Forgetting to hide the CanvasLayer means the inventory is visible at game start.",
					"Using the same slot instance 24 times instead of duplicating means every slot shows the same item.",
					"Not connecting to inventory_changed means the UI doesn't update when items are picked up.",
					"Forgetting to create the 'toggle_inventory' input action (usually I or Tab) means the UI can't open."
				]
			},
			"equipment_panel_ui": {
				"title": "Equipment Panel UI",
				"phrases": ["equipment panel", "equipment ui", "gear panel", "character equipment screen"],
				"category": "equipment",
				"subcategory": "ui",
				"dimension": "ui",
				"difficulty": "intermediate",
				"root": {
					"type": "PanelContainer",
					"name": "EquipmentPanel"
				},
				"required_children": [
					{"type": "VBoxContainer", "name": "Layout", "properties": {}},
					{"type": "Label", "name": "Title", "properties": {"text": "Equipment"}},
					{"type": "GridContainer", "name": "SlotGrid", "properties": {"columns": 2}}
				],
				"recommended_children": [],
				"script": "",
				"required_actions": [],
				"setup_notes": [
					"Create six slot scenes — or one generic slot scene — and place one per equipment type in the SlotGrid.",
					"Each slot should be a PanelContainer with:",
					"  - A Label showing the slot name (weapon, helmet, chest, boots, ring, amulet)",
					"  - A TextureRect showing the equipped item's icon (or empty)",
					"  - A Button or an Area2D click handler to unequip on click",
					"Assign a script to the root PanelContainer with:",
					"",
					"    func _ready() -> void:",
					"        var equipment = get_tree().get_first_node_in_group(\"equipment\")",
					"        if equipment != null and equipment.has_signal(\"equipment_changed\"):",
					"            equipment.equipment_changed.connect(_refresh)",
					"        _refresh()",
					"",
					"    func _refresh() -> void:",
					"        var equipment = get_tree().get_first_node_in_group(\"equipment\")",
					"        if equipment == null:",
					"            return",
					"        for slot_name in equipment.equipped.keys():",
					"            var item = equipment.get_equipped(slot_name)",
					"            # find the matching UI slot and update its icon",
					"            pass",
					"",
					"To handle dropping a new item onto a slot, connect the slot's gui_input signal and check for InputEventMouseButton.",
					"Pair with the inventory grid UI — usually they appear side by side."
				],
				"next_steps": [
					{"snippet": "equipment_slots", "why": "The data behind this UI."},
					{"snippet": "equipment_stats", "why": "Recalculates stats when gear changes."},
					{"blueprint": "inventory_ui_grid", "why": "Place next to this panel."},
					{"blueprint": "character_stats_ui", "why": "Show final stats below the gear panel."}
				],
				"mistakes": [
					"Hardcoding slot names in the UI instead of reading from equipment.equipped.keys() means renaming slots breaks the UI.",
					"Forgetting to refresh on equipment_changed means the UI shows stale gear.",
					"Not handling unequip-on-click means the player can't remove gear without opening the inventory."
				]
			},
			"character_stats_ui": {
				"title": "Character Stats Panel",
				"phrases": ["stats panel", "character stats ui", "stat display", "show stats"],
				"category": "equipment",
				"subcategory": "ui",
				"dimension": "ui",
				"difficulty": "beginner",
				"root": {
					"type": "PanelContainer",
					"name": "StatsPanel"
				},
				"required_children": [
					{"type": "VBoxContainer", "name": "Layout", "properties": {}},
					{"type": "Label", "name": "Title", "properties": {"text": "Character"}},
					{"type": "VBoxContainer", "name": "StatRows", "properties": {}}
				],
				"recommended_children": [],
				"script": "",
				"required_actions": [],
				"setup_notes": [
					"Create one row per stat as an HBoxContainer with two Labels (name and value). Example:",
					"  StatRows",
					"    HBox — AttackLabel, AttackValue",
					"    HBox — DefenseLabel, DefenseValue",
					"    HBox — HealthLabel, HealthValue",
					"    HBox — SpeedLabel, SpeedValue",
					"Assign a script to the root PanelContainer with:",
					"",
					"    @onready var _stats_node: Node = get_node_or_null(\"../Stats\")",
					"",
					"    func _ready() -> void:",
					"        if _stats_node != null and _stats_node.has_signal(\"stats_changed\"):",
					"            _stats_node.stats_changed.connect(_on_stats)",
					"        if _stats_node != null:",
					"            _on_stats(_stats_node.current_stats)",
					"",
					"    func _on_stats(stats: Dictionary) -> void:",
					"        $Layout/StatRows/AttackRow/Value.text = str(int(stats.get(\"attack\", 0)))",
					"        $Layout/StatRows/DefenseRow/Value.text = str(int(stats.get(\"defense\", 0)))",
					"        # etc.",
					"",
					"Or, for a dynamic build with no hardcoded rows, iterate stats.keys() and create Labels programmatically.",
					"Pair with equipment_stats for values that update when gear changes."
				],
				"next_steps": [
					{"snippet": "equipment_stats", "why": "The data behind this UI."},
					{"snippet": "equipment_stat_apply", "why": "Bridges stats to actual gameplay."},
					{"blueprint": "equipment_panel_ui", "why": "Show gear next to this panel."}
				],
				"mistakes": [
					"Hardcoding stat names means adding a new stat requires UI edits. Iterate the dictionary for a dynamic version.",
					"Showing raw floats looks ugly. Round ints for display unless the stat is a percentage.",
					"Forgetting to call the update once on _ready means the panel shows placeholder values until the first stat change."
				]
			}
		}
	}

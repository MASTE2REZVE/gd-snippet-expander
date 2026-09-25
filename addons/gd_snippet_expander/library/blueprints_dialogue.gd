@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"blueprints": {
			"dialogue_ui_advanced": {
				"title": "Advanced Dialogue UI",
				"phrases": ["advanced dialogue", "dialogue ui", "dialogue with portrait", "dialogue with choices"],
				"category": "dialogue",
				"subcategory": "ui",
				"dimension": "ui",
				"difficulty": "intermediate",
				"root": {
					"type": "CanvasLayer",
					"name": "DialogueUI"
				},
				"required_children": [
					{"type": "PanelContainer", "name": "Panel", "properties": {"anchors_preset": 12, "offset_left": 40, "offset_top": -220, "offset_right": -40, "offset_bottom": -20}},
					{"type": "HBoxContainer", "name": "Layout", "properties": {}},
					{"type": "TextureRect", "name": "Portrait", "properties": {"custom_minimum_size": [128, 128], "expand_mode": 1, "stretch_mode": 5}},
					{"type": "VBoxContainer", "name": "TextColumn", "properties": {}},
					{"type": "Label", "name": "SpeakerName", "properties": {"text": "Speaker"}},
					{"type": "RichTextLabel", "name": "BodyText", "properties": {"bbcode_enabled": true, "fit_content": true, "custom_minimum_size": [0, 80]}},
					{"type": "VBoxContainer", "name": "Choices", "properties": {}},
					{"type": "Label", "name": "ContinueHint", "properties": {"text": "[Space] Continue", "horizontal_alignment": 2}}
				],
				"recommended_children": [],
				"script": "",
				"required_actions": [],
				"setup_notes": [
					"Note: HBoxContainer, TextureRect, VBoxContainer, and the Labels must be re-parented manually since this blueprint doesn't preserve parent-child structure for non-required children. The 'children' nesting is not enforced — after building, arrange them as:",
					"  Panel",
					"    Layout (HBoxContainer)",
					"      Portrait (TextureRect)",
					"      TextColumn (VBoxContainer)",
					"        SpeakerName (Label)",
					"        BodyText (RichTextLabel)",
					"        Choices (VBoxContainer)",
					"        ContinueHint (Label)",
					"Add this node to the group 'dialogue_ui' so NPCs can find it.",
					"Assign a script to the root CanvasLayer with these methods:",
					"  start_dialogue(data: Resource) — sets SpeakerName, Portrait, starts typing BodyText",
					"  show_choices(choices: DialogueChoice) — creates one Button per option in Choices",
					"  advance() — moves to the next line or closes if finished",
					"Connect the root's _unhandled_input to call advance() when 'ui_accept' is pressed. Disable input while choices are shown.",
					"Pair with the 'dialogue_typewriter' snippet for character-by-character text reveal."
				],
				"next_steps": [
					{"snippet": "dialogue_data", "why": "Resource for storing conversations."},
					{"snippet": "dialogue_choice", "why": "Branching dialogue options."},
					{"snippet": "dialogue_typewriter", "why": "Character-by-character text reveal."},
					{"snippet": "npc_portrait_swap", "why": "Swap portraits per emotion."},
					{"snippet": "npc_interactable", "why": "The NPC side that triggers this UI."}
				],
				"mistakes": [
					"Forgetting to add to the 'dialogue_ui' group means NPCs can't find this UI.",
					"Not disabling ContinueHint while choices are shown lets the player skip past a choice.",
					"Using a plain Label for BodyText instead of RichTextLabel loses BBCode support (bold, italics, colored keywords).",
					"Not setting fit_content on the RichTextLabel means long lines cut off instead of wrapping."
				]
			},
			"dialogue_trigger_zone": {
				"title": "Dialogue Trigger Zone",
				"phrases": ["dialogue trigger", "auto dialogue", "cutscene trigger", "walk into dialogue"],
				"category": "dialogue",
				"subcategory": "trigger",
				"dimension": "2d",
				"difficulty": "beginner",
				"root": {
					"type": "Area2D",
					"name": "DialogueTrigger"
				},
				"required_children": [
					{"type": "CollisionShape2D", "name": "CollisionShape2D", "shape": "RectangleShape2D"}
				],
				"recommended_children": [],
				"script": "",
				"required_actions": [],
				"setup_notes": [
					"Assign a script to the root with this behaviour:",
					"",
					"    extends Area2D",
					"",
					"    @export var dialogue_resource: Resource",
					"    @export var one_shot: bool = true",
					"    var _fired: bool = false",
					"",
					"    func _ready() -> void:",
					"        body_entered.connect(_on_body_entered)",
					"",
					"    func _on_body_entered(body: Node2D) -> void:",
					"        if _fired and one_shot:",
					"            return",
					"        if not body.is_in_group(\"player\"):",
					"            return",
					"        _fired = true",
					"        var ui = get_tree().get_first_node_in_group(\"dialogue_ui\")",
					"        if ui != null and ui.has_method(\"start_dialogue\"):",
					"            ui.start_dialogue(dialogue_resource)",
					"",
					"Assign a DialogueData resource to dialogue_resource in the Inspector.",
					"Set one_shot to false for repeatable triggers (like a tutorial that repeats until the player reads it).",
					"Resize the CollisionShape2D rectangle to cover the trigger area — usually the width of a doorway or the entrance to a room.",
					"Place this Area2D at the door or zone where the dialogue should fire.",
					"To chain multiple triggers in sequence, use one_shot = true and place them along a path."
				],
				"next_steps": [
					{"snippet": "dialogue_data", "why": "The conversation this trigger fires."},
					{"blueprint": "dialogue_ui_advanced", "why": "The UI that displays the dialogue."},
					{"snippet": "quest_add", "why": "Combine with a trigger to start a quest on entering a zone."}
				],
				"mistakes": [
					"Forgetting to add the player to the 'player' group means nothing fires.",
					"Making the CollisionShape2D too small means the player walks past without triggering.",
					"Not using a one_shot flag means the trigger fires on every frame the player stays inside."
				]
			}
		}
	}

@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"blueprints": {
			"door_2d_blueprint": {
				"title": "Door (2D)",
				"phrases": ["door blueprint", "add door", "make a door", "interactable door blueprint"],
				"category": "level",
				"subcategory": "door",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "2d",
				"difficulty": "beginner",
				"root": {
					"type": "Area2D",
					"name": "Door"
				},
				"required_children": [
					{"type": "CollisionShape2D", "name": "CollisionShape2D", "shape": "RectangleShape2D"},
					{"type": "Sprite2D", "name": "Sprite"}
				],
				"recommended_children": [],
				"script": "door_2d",
				"required_actions": ["interact"],
				"setup_notes": [
					"Add the door sprite to the Sprite node.",
					"Resize the CollisionShape2D rectangle to cover the door's interaction area — usually slightly larger than the visual so the player can trigger it by standing nearby.",
					"Add the Door to group 'door' via the Node tab's Groups button. This lets key pickups find it automatically.",
					"In the Inspector:",
					"  - locked: false for a normal door, true to require a key",
					"  - required_key: leave empty unless locked is true",
					"  - auto_close: false to stay open, true to close when the player walks away",
					"Create an input action 'interact' in Project Settings → Input Map (usually bound to E).",
					"For a walking-through door, add a StaticBody2D child and toggle its collision when open. For a simple interact-only door, no collision is needed."
				],
				"next_steps": [
					{"blueprint": "key_pickup_2d", "why": "A key that unlocks this door."},
					{"snippet": "play_sound", "why": "Door creak on open."},
					{"blueprint": "checkpoint_2d", "why": "Save progress past this door."}
				],
				"mistakes": [
					"Forgetting to add the player to group 'player' means the interact input never triggers.",
					"Setting locked to true without assigning a required_key makes the door permanently impossible to open.",
					"Not creating the 'interact' input action means nothing happens when the player presses E.",
					"If the door has a StaticBody2D for blocking, forgetting to toggle its collision on open makes it look open but block movement."
				]
			},
			"key_pickup_2d": {
				"title": "Key Pickup (2D)",
				"phrases": ["key pickup blueprint", "add key", "make a key", "collectible key"],
				"category": "level",
				"subcategory": "key",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "2d",
				"difficulty": "beginner",
				"root": {
					"type": "Area2D",
					"name": "Key"
				},
				"required_children": [
					{"type": "CollisionShape2D", "name": "CollisionShape2D", "shape": "CircleShape2D"},
					{"type": "Sprite2D", "name": "Sprite"}
				],
				"recommended_children": [],
				"script": "key_pickup",
				"required_actions": [],
				"setup_notes": [
					"Assign a key sprite to the Sprite node — usually a golden key icon.",
					"The CollisionShape2D circle defaults to radius 20. That's fine for most pickups; adjust for very large or small keys.",
					"In the Inspector:",
					"  - key_id: unique string like 'iron_key' or 'red_keycard'. Doors that require this key must set their required_key to the same value.",
					"  - unlock_doors_in_group: true means the key auto-unlocks every door with a matching required_key. False requires custom unlock logic.",
					"The script bobs the key up and down automatically. No config needed.",
					"Register the key item in your inventory system's item registry before the game runs. See item_registry snippet.",
					"Add a pickup sound by connecting to the key_collected signal."
				],
				"next_steps": [
					{"blueprint": "door_2d_blueprint", "why": "The door this key opens."},
					{"snippet": "particle_sparkle", "why": "Glow effect around the key."},
					{"snippet": "item_registry", "why": "Register the key item."}
				],
				"mistakes": [
					"Typo in key_id means the matching door never unlocks. Copy-paste the key ID between the key and the door.",
					"Forgetting to add the player to group 'player' means the pickup doesn't fire.",
					"Registering the key with the inventory after the level loads means pickups before registration silently fail."
				]
			},
			"switch_2d_blueprint": {
				"title": "Lever Switch (2D)",
				"phrases": ["switch blueprint", "add lever", "toggle switch blueprint", "interactable switch"],
				"category": "level",
				"subcategory": "switch",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "2d",
				"difficulty": "beginner",
				"root": {
					"type": "Area2D",
					"name": "Switch"
				},
				"required_children": [
					{"type": "CollisionShape2D", "name": "CollisionShape2D", "shape": "RectangleShape2D"},
					{"type": "Sprite2D", "name": "Sprite"}
				],
				"recommended_children": [],
				"script": "switch_2d",
				"required_actions": ["interact"],
				"setup_notes": [
					"Add a lever sprite to the Sprite node.",
					"Resize the CollisionShape2D to cover the interaction area — a small rectangle around the lever.",
					"Create input action 'interact' in Project Settings → Input Map if you haven't already.",
					"In the Inspector:",
					"  - starts_on: false for a lever that starts in the 'off' position",
					"  - toggle_cooldown: 0.3 seconds prevents spam-toggling",
					"  - one_shot: true for a lever that can only turn on, not off",
					"Connect switched_on and switched_off signals to whatever the switch controls (doors, platforms, lights).",
					"Example: to open a door when the switch flips on, connect switched_on to door.open()."
				],
				"next_steps": [
					{"snippet": "door_2d", "why": "A door the switch controls."},
					{"snippet": "moving_platform", "why": "A platform the switch starts."},
					{"snippet": "play_sound", "why": "Lever click sound."}
				],
				"mistakes": [
					"Not connecting the switched_on signal to anything means the lever flips but nothing happens.",
					"Setting one_shot to true means the player can never turn the switch off — only use it when you need a permanent state change.",
					"Forgetting the interact input action means nothing triggers."
				]
			},
			"pressure_plate_2d": {
				"title": "Pressure Plate (2D)",
				"phrases": ["pressure plate blueprint", "add pressure plate", "step plate", "weight plate"],
				"category": "level",
				"subcategory": "switch",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "2d",
				"difficulty": "beginner",
				"root": {
					"type": "Area2D",
					"name": "PressurePlate"
				},
				"required_children": [
					{"type": "CollisionShape2D", "name": "CollisionShape2D", "shape": "RectangleShape2D"},
					{"type": "Sprite2D", "name": "Sprite"}
				],
				"recommended_children": [],
				"script": "pressure_plate",
				"required_actions": [],
				"setup_notes": [
					"Add a plate sprite to the Sprite node.",
					"Resize the CollisionShape2D to match the visible plate — usually a wide short rectangle.",
					"In the Inspector:",
					"  - requires_weight: 1 for player-only, 2+ for 'player plus crate' puzzles",
					"  - hold_time: 0 for instant release, 0.5-2.0 for a grace period so fast players don't lose progress",
					"Add the same collision layer as your player so body_entered fires.",
					"Connect plate_pressed to trigger doors, platforms, or anything else.",
					"For a crate puzzle: set requires_weight to 2 and add crates to the same collision layer."
				],
				"next_steps": [
					{"blueprint": "door_2d_blueprint", "why": "A door the plate opens."},
					{"snippet": "moving_platform", "why": "A platform the plate activates."},
					{"blueprint": "switch_2d_blueprint", "why": "An interactable alternative to the plate."}
				],
				"mistakes": [
					"hold_time of 0 means the plate releases the instant the player steps off, which can cut off doors mid-animation.",
					"Wrong collision layer means body_entered never fires — check the Area2D's collision mask in the Inspector.",
					"Setting requires_weight to 2 without providing a pushable crate in the level makes the puzzle impossible."
				]
			},
			"checkpoint_2d_blueprint": {
				"title": "Checkpoint (2D)",
				"phrases": ["checkpoint blueprint", "add checkpoint", "save point blueprint", "respawn point blueprint"],
				"category": "level",
				"subcategory": "checkpoint",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "2d",
				"difficulty": "beginner",
				"root": {
					"type": "Area2D",
					"name": "Checkpoint"
				},
				"required_children": [
					{"type": "CollisionShape2D", "name": "CollisionShape2D", "shape": "RectangleShape2D"},
					{"type": "Sprite2D", "name": "Sprite"}
				],
				"recommended_children": [],
				"script": "checkpoint_2d",
				"required_actions": [],
				"setup_notes": [
					"Add a checkpoint sprite — a flag, obelisk, or crystal works well.",
					"Resize the CollisionShape2D to be wide enough to reliably catch the player passing through.",
					"The Sprite turns green when the checkpoint activates as visual feedback.",
					"In the Inspector:",
					"  - checkpoint_id: unique string per checkpoint (level_1_start, boss_door, etc.)",
					"  - respawn_offset: [0, -16] places the player slightly above the checkpoint, avoiding floor-clipping",
					"Set up the CheckpointManager autoload (from the checkpoint_manager snippet) so checkpoints persist between sessions.",
					"On game load, call CheckpointManager.load_from_config() then force_activate() on every checkpoint that was already active."
				],
				"next_steps": [
					{"snippet": "checkpoint_manager", "why": "The autoload that stores respawn data."},
					{"snippet": "respawn", "why": "The player's respawn logic."},
					{"snippet": "save_game", "why": "Save checkpoint state in save files."}
				],
				"mistakes": [
					"Without a checkpoint manager, checkpoints work but don't survive saving and reloading.",
					"Same checkpoint_id on two different checkpoints means they overwrite each other in the save file.",
					"Making the CollisionShape2D too small means the player can run past it without triggering."
				]
			}
		}
	}

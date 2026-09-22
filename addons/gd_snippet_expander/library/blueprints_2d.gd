@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"blueprints": {
			"player_2d_platformer": {
				"title": "2D Platformer Character",
				"phrases": ["2d character", "make a 2d character", "platformer character", "2d player", "player 2d"],
				"category": "player",
				"dimension": "2d",
				"difficulty": "beginner",
				"root": {
					"type": "CharacterBody2D",
					"name": "Player"
				},
				"required_children": [
					{"type": "CollisionShape2D", "name": "CollisionShape2D", "shape": "RectangleShape2D"},
					{"type": "Sprite2D", "name": "Sprite"}
				],
				"recommended_children": [],
				"script": "platformer_movement_2d",
				"required_actions": ["left", "right", "jump"],
				"setup_notes": [
					"Drag your character sprite onto the Sprite node.",
					"Adjust the CollisionShape2D rectangle to roughly match your sprite's bounds.",
					"You'll need a floor to stand on — build one with StaticBody2D + CollisionShape2D, or use a TileMap."
				],
				"next_steps": [
					{"snippet": "coyote_time_2d", "why": "Makes jumping feel fair when you just walk off a ledge."},
					{"snippet": "jump_buffer_2d", "why": "Lets a jump pressed slightly early still register."},
					{"blueprint": "camera_2d_follow", "why": "So the camera tracks the player."},
					{"blueprint": "platformer_ground_2d", "why": "Something to stand and jump on."}
				],
				"mistakes": [
					"Forgetting move_and_slide() means nothing happens on screen.",
					"Using a square CollisionShape2D for a round character means visible gaps at edges."
				]
			},
			"player_2d_topdown": {
				"title": "2D Top-Down Character",
				"phrases": ["topdown character", "top down character", "rpg character", "2d top down player"],
				"category": "player",
				"dimension": "2d",
				"difficulty": "beginner",
				"root": {
					"type": "CharacterBody2D",
					"name": "Player"
				},
				"required_children": [
					{"type": "CollisionShape2D", "name": "CollisionShape2D", "shape": "CircleShape2D"},
					{"type": "Sprite2D", "name": "Sprite"}
				],
				"recommended_children": [],
				"script": "character_movement_2d",
				"required_actions": ["left", "right", "up", "down"],
				"setup_notes": [
					"Drag your character sprite onto the Sprite node.",
					"The CircleShape2D is a good default for top-down movement — no corner snags.",
					"If your sprite faces right by default, no rotation needed. Use topdown_movement_2d if the character should face the direction of motion."
				],
				"next_steps": [
					{"blueprint": "camera_2d_follow", "why": "So the camera tracks the player."},
					{"snippet": "inventory_system", "why": "Common in top-down RPGs."},
					{"blueprint": "enemy_patrol_2d", "why": "Give the player something to avoid."}
				],
				"mistakes": [
					"Using platformer_movement_2d for top-down — gravity makes the character fall through the screen.",
					"Forgetting the input actions means the character won't move at all."
				]
			},
			"platformer_ground_2d": {
				"title": "Platformer Ground (2D)",
				"phrases": ["ground 2d", "floor 2d", "platform 2d", "add floor 2d"],
				"category": "world",
				"dimension": "2d",
				"difficulty": "beginner",
				"root": {
					"type": "StaticBody2D",
					"name": "Ground"
				},
				"required_children": [
					{"type": "CollisionShape2D", "name": "CollisionShape2D", "shape": "RectangleShape2D"},
					{"type": "ColorRect", "name": "Visual", "properties": {"color": [0.3, 0.6, 0.3, 1.0]}}
				],
				"recommended_children": [],
				"script": "",
				"required_actions": [],
				"setup_notes": [
					"The CollisionShape2D's RectangleShape2D defaults to 20x20 pixels. Set size to (400, 40) for a wide floor.",
					"The ColorRect is just a green placeholder. Replace with a Sprite2D or TileMap later.",
					"Place the ground lower in the scene (y = 400 or so) so the player has room to fall onto it.",
					"Make sure the ColorRect's size matches the CollisionShape2D's rectangle."
				],
				"next_steps": [
					{"blueprint": "player_2d_platformer", "why": "Something needs to stand on the ground."},
					{"blueprint": "camera_2d_follow", "why": "So the camera tracks the player."}
				],
				"mistakes": [
					"CollisionShape2D size not matching the visual means players fall through parts of the floor that look solid.",
					"Adding a Sprite2D without adjusting its position means it doesn't line up with the collision."
				]
			},
			"camera_2d_follow": {
				"title": "Camera Follow (2D)",
				"phrases": ["camera 2d", "follow camera 2d", "camera rig 2d", "camera setup 2d"],
				"category": "camera",
				"dimension": "2d",
				"difficulty": "beginner",
				"root": {
					"type": "Camera2D",
					"name": "Camera"
				},
				"required_children": [],
				"recommended_children": [],
				"script": "camera_follow_2d",
				"required_actions": [],
				"setup_notes": [
					"The script has a target_path property. In the Inspector, set it to point at your player node.",
					"Place the Camera2D at the scene root, not as a child of the player.",
					"If the camera jitters, add camera_smooth_follow_2d instead — it uses a better formula."
				],
				"next_steps": [
					{"snippet": "camera_limits_2d", "why": "So the camera stops at the level edges."},
					{"snippet": "camera_deadzone", "why": "If the camera feels too twitchy."},
					{"snippet": "camera_shake", "why": "For impactful hits."}
				],
				"mistakes": [
					"Making the Camera2D a child of the player means the camera spins with the character.",
					"Forgetting to set target_path leaves the camera stuck at the origin."
				]
			},
			"enemy_patrol_2d": {
				"title": "Patrolling Enemy (2D)",
				"phrases": ["patrol enemy", "enemy blueprint", "2d enemy", "enemy patrol blueprint"],
				"category": "enemy",
				"dimension": "2d",
				"difficulty": "beginner",
				"root": {
					"type": "CharacterBody2D",
					"name": "Enemy"
				},
				"required_children": [
					{"type": "CollisionShape2D", "name": "CollisionShape2D", "shape": "RectangleShape2D"},
					{"type": "Sprite2D", "name": "Sprite"}
				],
				"recommended_children": [],
				"script": "enemy_patrol",
				"required_actions": [],
				"setup_notes": [
					"In the Inspector, fill the 'points' array with Vector2 world positions the enemy should walk between.",
					"Drag your enemy sprite onto the Sprite node.",
					"Place the enemy in the scene near its patrol points — it will walk toward the first point on start."
				],
				"next_steps": [
					{"snippet": "look_for_player", "why": "So the enemy can notice the player."},
					{"snippet": "chase_player", "why": "So the enemy can chase once it sees the player."},
					{"snippet": "attack_player", "why": "So the enemy can deal damage."},
					{"snippet": "health_system", "why": "So the enemy can be killed."}
				],
				"mistakes": [
					"Forgetting to set patrol points means the enemy stands still.",
					"Making the enemy's collision shape too large means it gets stuck on corners."
				]
			},
			"coin_pickup_2d": {
				"title": "Coin Pickup (2D)",
				"phrases": ["coin 2d", "2d coin", "collectible 2d", "pickup 2d"],
				"category": "pickup",
				"dimension": "2d",
				"difficulty": "beginner",
				"root": {
					"type": "Area2D",
					"name": "Coin"
				},
				"required_children": [
					{"type": "CollisionShape2D", "name": "CollisionShape2D", "shape": "CircleShape2D"},
					{"type": "Sprite2D", "name": "Sprite"}
				],
				"recommended_children": [],
				"script": "coin_pickup",
				"required_actions": [],
				"setup_notes": [
					"Add the player to a group called 'player' in the Inspector so the coin detects it.",
					"Drag your coin sprite onto the Sprite node.",
					"The CircleShape2D radius defaults to 20 — adjust to match your sprite size.",
					"For a bobbing coin, add a small Tween animation on the Sprite's position."
				],
				"next_steps": [
					{"snippet": "score_display", "why": "To show the collected count."},
					{"snippet": "play_sound", "why": "For the classic pickup ding."},
					{"blueprint": "player_2d_platformer", "why": "Someone needs to collect it."}
				],
				"mistakes": [
					"Not adding the player to the 'player' group means nothing happens on touch.",
					"Forgetting CollisionShape2D means the coin has no detection area."
				]
			},
			"tilemap_2d": {
				"title": "TileMap Level (2D)",
				"phrases": ["tilemap", "level 2d", "tile map", "level design 2d"],
				"category": "world",
				"dimension": "2d",
				"difficulty": "intermediate",
				"root": {
					"type": "Node2D",
					"name": "Level"
				},
				"required_children": [
					{"type": "TileMapLayer", "name": "Ground"}
				],
				"recommended_children": [],
				"script": "",
				"required_actions": [],
				"setup_notes": [
					"TileMapLayer is Godot 4.3+'s new tilemap node. In older 4.x, use TileMap instead.",
					"Create a TileSet resource in the TileMapLayer's Inspector by clicking 'New TileSet'.",
					"Drag a tilesheet image into the TileSet to slice it into tiles.",
					"Paint tiles by selecting the TileMapLayer and using the TileMap panel at the bottom."
				],
				"next_steps": [
					{"blueprint": "player_2d_platformer", "why": "Someone needs to run around your level."},
					{"blueprint": "camera_2d_follow", "why": "So the camera follows the player across the level."},
					{"snippet": "camera_limits_2d", "why": "So the camera stops at the level edges."}
				],
				"mistakes": [
					"Forgetting to add a physics layer to the TileSet means the player falls through the tiles.",
					"Using TileMap instead of TileMapLayer in Godot 4.3+ means missing new features."
				]
			}
		}
	}

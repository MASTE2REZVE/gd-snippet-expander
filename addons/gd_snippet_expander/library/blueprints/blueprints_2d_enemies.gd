@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"blueprints": {
			"flying_enemy_2d_blueprint": {
				"title": "Flying Enemy (2D)",
				"phrases": ["flying enemy blueprint", "add flying enemy", "bird enemy blueprint", "floating enemy blueprint"],
				"category": "enemy",
				"subcategory": "flying",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "2d",
				"difficulty": "intermediate",
				"root": {
					"type": "CharacterBody2D",
					"name": "FlyingEnemy"
				},
				"required_children": [
					{"type": "CollisionShape2D", "name": "CollisionShape2D", "shape": "CircleShape2D"},
					{"type": "AnimatedSprite2D", "name": "AnimatedSprite2D"}
				],
				"recommended_children": [],
				"script": "flying_enemy_2d",
				"required_actions": [],
				"setup_notes": [
					"The AnimatedSprite2D needs a SpriteFrames resource with at least one animation named 'fly'.",
					"In the Inspector:",
					"  - speed: horizontal movement speed",
					"  - hover_amplitude: how much it bobs vertically",
					"  - hover_speed: how fast the bob oscillates",
					"  - attack_range: distance at which it dives at the player",
					"  - player_path: leave empty to auto-find the player via group 'player'",
					"The player must be in group 'player' for auto-detection. Otherwise set player_path in the Inspector.",
					"Set the collision layer so the enemy hits the player's hurtbox but not the walls (flying enemies usually pass over ground).",
					"Add a 'hurt' flash effect by connecting to health_changed or overriding take_damage."
				],
				"next_steps": [
					{"snippet": "health_system", "why": "Make it killable."},
					{"snippet": "loot_table", "why": "Drops on death."},
					{"snippet": "hitstop", "why": "Feedback when hit."},
					{"snippet": "death_effect", "why": "Visual on death."}
				],
				"mistakes": [
					"Using a RectangleShape2D makes the collision feel off — CircleShape2D matches the visual better for flying enemies.",
					"Forgetting to add the player to group 'player' means player_path stays null and the enemy never attacks.",
					"Setting hover_amplitude very high (over 40) makes the enemy drift too far from its origin and miss the player entirely."
				]
			},
			"turret_enemy_2d_blueprint": {
				"title": "Turret Enemy (2D)",
				"phrases": ["turret enemy blueprint", "add turret", "stationary shooter blueprint", "gun turret blueprint"],
				"category": "enemy",
				"subcategory": "turret",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "2d",
				"difficulty": "intermediate",
				"root": {
					"type": "Node2D",
					"name": "Turret"
				},
				"required_children": [
					{"type": "Sprite2D", "name": "Sprite"},
					{"type": "Marker2D", "name": "Muzzle", "properties": {"position": [24, 0]}}
				],
				"recommended_children": [],
				"script": "turret_enemy_2d",
				"required_actions": [],
				"setup_notes": [
					"Assign a turret sprite to the Sprite node. The script rotates the Sprite to aim at the player.",
					"The Muzzle Marker2D is the barrel tip where projectiles spawn. Adjust its position to match the sprite.",
					"In the Inspector:",
					"  - projectile_scene: assign your bullet .tscn (see projectile snippet)",
					"  - fire_rate: seconds between shots",
					"  - range: detection range in pixels",
					"  - rotate_to_target: true for rotating turret, false for a fixed-direction turret",
					"  - burst_count: 1 for single shots, 3+ for burst fire",
					"The turret is a Node2D, not a CharacterBody2D — it doesn't move. For collision, add a StaticBody2D or Area2D sibling.",
					"To make the turret killable, add an Area2D child with a hurtbox and a take_damage method."
				],
				"next_steps": [
					{"snippet": "projectile", "why": "The bullet scene to spawn."},
					{"snippet": "spread_shot", "why": "For turrets that fire multiple bullets."},
					{"snippet": "health_system", "why": "Make the turret killable."},
					{"snippet": "impact_effect", "why": "Feedback on bullet impact."}
				],
				"mistakes": [
					"Forgetting the Muzzle node means bullets spawn from the turret center, looking wrong with a long barrel.",
					"Not assigning projectile_scene in the Inspector means nothing fires — the script pushes no warning.",
					"Setting rotate_to_target to false but expecting the turret to aim means bullets always fire in the initial direction."
				]
			},
			"jumper_enemy_2d_blueprint": {
				"title": "Jumper Enemy (2D)",
				"phrases": ["jumper enemy blueprint", "add jumping enemy", "hopping slime blueprint", "jumping enemy"],
				"category": "enemy",
				"subcategory": "jumper",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "2d",
				"difficulty": "beginner",
				"root": {
					"type": "CharacterBody2D",
					"name": "Jumper"
				},
				"required_children": [
					{"type": "CollisionShape2D", "name": "CollisionShape2D", "shape": "RectangleShape2D"},
					{"type": "AnimatedSprite2D", "name": "AnimatedSprite2D"}
				],
				"recommended_children": [],
				"script": "jumper_enemy_2d",
				"required_actions": [],
				"setup_notes": [
					"The AnimatedSprite2D should have at least a 'jump' animation. Optional: idle, land animations if you want more polish.",
					"In the Inspector:",
					"  - jump_velocity: -450 for standard height, -700 for tall jumps",
					"  - horizontal_speed: how fast it moves horizontally",
					"  - jump_cooldown: pause between jumps (0.6 fast, 1.2 standard, 2.0 slow)",
					"  - chase_player: true to home in on the player, false for random hopping",
					"Add the enemy to the same collision layer as the ground so it lands properly.",
					"The script already plays a squash animation on jump — no AnimatedSprite2D setup needed for that effect.",
					"The player must be in group 'player' for chasing."
				],
				"next_steps": [
					{"snippet": "health_system", "why": "Make it killable."},
					{"snippet": "melee_attack", "why": "So the jumper damages the player on contact."},
					{"snippet": "particle_dust", "why": "Dust puff on landing."},
					{"snippet": "loot_table", "why": "Drops on death."}
				],
				"mistakes": [
					"Making jump_cooldown too low (under 0.3) makes the enemy hop constantly and look jittery.",
					"Using a CircleShape2D makes the enemy roll off platforms. RectangleShape2D stays put.",
					"Setting horizontal_speed too high (over 300) means the enemy overshoots the player every jump.",
					"Not setting up the ground collision layer means the enemy falls through the floor."
				]
			}
		}
	}

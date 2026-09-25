@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"blueprints": {
			"player_3d": {
				"title": "3D Character",
				"phrases": ["3d character", "make a 3d character", "player 3d", "character 3d", "add player 3d"],
				"category": "player",
				"dimension": "3d",
				"difficulty": "beginner",
				"root": {
					"type": "CharacterBody3D",
					"name": "Player"
				},
				"required_children": [
					{"type": "CollisionShape3D", "name": "CollisionShape3D", "shape": "CapsuleShape3D"},
					{"type": "MeshInstance3D", "name": "Body", "mesh": "BoxMesh"}
				],
				"recommended_children": [
					{"type": "Camera3D", "name": "Camera3D", "transform": {"position": [0, 1.6, 0]}}
				],
				"script": "character_movement_3d",
				"required_actions": ["left", "right", "forward", "back", "jump"],
				"setup_notes": [
					"The CollisionShape3D has a CapsuleShape3D placeholder. Select it and adjust height/radius to match your character.",
					"The Body node has a BoxMesh placeholder. Replace it by dragging your .glb or .obj mesh onto the Body node.",
					"The Camera3D is a placeholder. For first-person, delete it and add 'first person camera'. For third-person, use 'camera follow 3d'."
				],
				"next_steps": [
					{"blueprint": "ground_plane_3d", "why": "So the player has something to stand on."},
					{"snippet": "mouse look 3d", "why": "To look around with the mouse."},
					{"snippet": "jump_3d", "why": "Add jumping to the movement script."},
					{"blueprint": "pause_menu_ui", "why": "So you can pause the game."}
				],
				"mistakes": [
					"Forgetting CollisionShape3D means the player falls through the floor.",
					"Attaching the script to the Camera3D instead of the CharacterBody3D means nothing moves.",
					"Making the CapsuleShape3D too small means the player clips into walls."
				]
			},
			"ground_plane_3d": {
				"title": "Ground Plane (3D)",
				"phrases": ["ground plane", "ground 3d", "floor 3d", "add ground", "make ground"],
				"category": "world",
				"dimension": "3d",
				"difficulty": "beginner",
				"root": {
					"type": "StaticBody3D",
					"name": "Ground"
				},
				"required_children": [
					{"type": "CollisionShape3D", "name": "CollisionShape3D", "shape": "BoxShape3D"},
					{"type": "MeshInstance3D", "name": "Mesh", "mesh": "PlaneMesh"}
				],
				"recommended_children": [],
				"script": "",
				"required_actions": [],
				"setup_notes": [
					"The PlaneMesh defaults to 2x2 meters. Set its size in the Inspector to something large like 50x50.",
					"The BoxShape3D needs to be thin and wide — set its size to (50, 0.2, 50) to match.",
					"To color the ground, add a StandardMaterial3D to the MeshInstance3D's material slot."
				],
				"next_steps": [
					{"blueprint": "player_3d", "why": "The player needs somewhere to stand."},
					{"blueprint": "directional_light_3d", "why": "So the ground and player are visible."},
					{"snippet": "change_scene", "why": "To move between scenes."}
				],
				"mistakes": [
					"Forgetting CollisionShape3D means the player falls through the ground.",
					"Making the mesh bigger than the collision shape means parts of the floor look solid but aren't."
				]
			},
			"camera_rig_3d": {
				"title": "Third-Person Camera Rig",
				"phrases": ["camera rig 3d", "third person camera rig", "orbit rig", "camera setup 3d"],
				"category": "camera",
				"dimension": "3d",
				"difficulty": "beginner",
				"root": {
					"type": "Node3D",
					"name": "CameraRig"
				},
				"required_children": [
					{"type": "Camera3D", "name": "Camera3D", "transform": {"position": [0, 0, 6]}}
				],
				"recommended_children": [],
				"script": "orbit_camera_3d",
				"required_actions": [],
				"setup_notes": [
					"The script has a 'target_path' property. In the Inspector, set it to point at your player node.",
					"Set Input.mouse_mode = MOUSE_MODE_CAPTURED somewhere at game start so mouse events register.",
					"The camera currently passes through walls. For camera collision, add a SpringArm3D between the rig and the Camera3D."
				],
				"next_steps": [
					{"blueprint": "player_3d", "why": "The rig needs something to orbit."},
					{"snippet": "camera_shake", "why": "For impactful hits and explosions."},
					{"snippet": "mouse_look_3d", "why": "If you'd rather do first-person instead."}
				],
				"mistakes": [
					"Attaching this to the player means the camera rotates with the player — usually not what you want for third-person.",
					"Forgetting to set target_path leaves the rig orbiting the world origin."
				]
			},
			"directional_light_3d": {
				"title": "Directional Light (Sun)",
				"phrases": ["directional light 3d", "sun light", "add light 3d", "scene lighting 3d"],
				"category": "world",
				"dimension": "3d",
				"difficulty": "beginner",
				"root": {
					"type": "DirectionalLight3D",
					"name": "Sun"
				},
				"required_children": [],
				"recommended_children": [],
				"script": "",
				"required_actions": [],
				"setup_notes": [
					"Rotate the light node in the editor to change the sun direction.",
					"Enable Shadows in the Inspector for a more grounded look.",
					"In a 3D scene without any light, everything appears black. This is usually one of the first things to add."
				],
				"next_steps": [
					{"blueprint": "ground_plane_3d", "why": "The light needs something to shine on."},
					{"blueprint": "player_3d", "why": "Give the light something to illuminate."}
				],
				"mistakes": [
					"Setting energy too low means the scene stays dark. Try energy = 1.0 first.",
					"Forgetting to rotate the light means shadows point straight down — flat and unnatural."
				]
			},
			"enemy_chaser_3d": {
				"title": "Chasing Enemy (3D)",
				"phrases": ["enemy 3d", "3d enemy", "chasing enemy 3d", "enemy chaser 3d"],
				"category": "enemy",
				"dimension": "3d",
				"difficulty": "intermediate",
				"root": {
					"type": "CharacterBody3D",
					"name": "Enemy"
				},
				"required_children": [
					{"type": "CollisionShape3D", "name": "CollisionShape3D", "shape": "CapsuleShape3D"},
					{"type": "MeshInstance3D", "name": "Body", "mesh": "BoxMesh"},
					{"type": "NavigationAgent3D", "name": "NavigationAgent3D"},
					{"type": "Area3D", "name": "DetectionArea"}
				],
				"recommended_children": [],
				"script": "navigation_agent_3d",
				"required_actions": [],
				"setup_notes": [
					"The script's target_path needs to point at the player.",
					"For navigation to work, your scene needs a NavigationRegion3D with a baked nav mesh covering the walkable area.",
					"The DetectionArea needs a CollisionShape3D child sized to the enemy's vision range.",
					"Replace the Body mesh with your own enemy model."
				],
				"next_steps": [
					{"snippet": "look_for_player", "why": "So the enemy knows when to start chasing."},
					{"snippet": "attack_player", "why": "So the enemy can deal damage."},
					{"snippet": "health_system", "why": "So the enemy can be killed."},
					{"blueprint": "player_3d", "why": "The enemy needs a target."}
				],
				"mistakes": [
					"Forgetting to bake the navigation mesh means the enemy walks straight into walls.",
					"Making the DetectionArea too large means the enemy chases the player across the entire map."
				]
			},
			"coin_pickup_3d": {
				"title": "Coin Pickup (3D)",
				"phrases": ["coin 3d", "3d coin", "pickup 3d", "collectible 3d"],
				"category": "pickup",
				"dimension": "3d",
				"difficulty": "beginner",
				"root": {
					"type": "Area3D",
					"name": "Coin"
				},
				"required_children": [
					{"type": "CollisionShape3D", "name": "CollisionShape3D", "shape": "SphereShape3D"},
					{"type": "MeshInstance3D", "name": "Mesh", "mesh": "SphereMesh"}
				],
				"recommended_children": [
					{"type": "OmniLight3D", "name": "Glow"}
				],
				"script": "coin_pickup",
				"required_actions": [],
				"setup_notes": [
					"The script uses body_entered, which requires the Area3D's collision mask to include the player.",
					"The SphereShape3D defaults to radius 0.5 — adjust to match your coin size.",
					"For a spinning coin, add a Rotation animation on the Mesh child.",
					"Add the player to a group called 'player' in the Inspector so the pickup detects it."
				],
				"next_steps": [
					{"snippet": "score_display", "why": "To show the collected count."},
					{"snippet": "play_sound", "why": "For the classic pickup ding."},
					{"blueprint": "player_3d", "why": "Someone needs to collect it."}
				],
				"mistakes": [
					"Not adding the player to the 'player' group means nothing happens on touch.",
					"Forgetting a CollisionShape3D means the coin has no physical presence."
				]
			}
		}
	}

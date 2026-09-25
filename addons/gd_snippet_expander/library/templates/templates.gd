@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"templates": {
			"starter_2d_platformer": {
				"title": "2D Platformer Starter",
				"description": "Bare minimum to get a playable 2D platformer scene. Ground, player, camera, and pause menu.",
				"dimension": "2d",
				"difficulty": "beginner",
				"steps": [
					{"kind": "blueprint", "id": "platformer_ground_2d", "note": "Wide floor to stand on."},
					{"kind": "blueprint", "id": "player_2d_platformer", "note": "The character you control."},
					{"kind": "blueprint", "id": "camera_2d_follow", "note": "Tracks the player. Set target_path in Inspector."},
					{"kind": "snippet", "id": "coyote_time_2d", "note": "Optional but makes jumping feel fair."},
					{"kind": "snippet", "id": "jump_buffer_2d", "note": "Optional — makes early jump presses register."},
					{"kind": "blueprint", "id": "pause_menu_ui", "note": "So the player can pause with Escape."}
				]
			},
			"starter_3d_fps": {
				"title": "3D FPS Starter",
				"description": "Bare minimum to get a playable first-person scene. Ground, player, sun, and pause menu.",
				"dimension": "3d",
				"difficulty": "beginner",
				"steps": [
					{"kind": "blueprint", "id": "ground_plane_3d", "note": "Wide floor. Set PlaneMesh size to 50x50."},
					{"kind": "blueprint", "id": "directional_light_3d", "note": "Sun. Without light, the scene is pitch black."},
					{"kind": "blueprint", "id": "player_3d", "note": "Includes a placeholder Camera3D."},
					{"kind": "snippet", "id": "mouse_look_3d", "note": "Mouse look. Add to the Player."},
					{"kind": "snippet", "id": "first_person_movement", "note": "Overwrites character_movement_3d with FPS-style movement."},
					{"kind": "blueprint", "id": "pause_menu_ui", "note": "So the player can pause with Escape."}
				]
			},
			"starter_topdown_rpg": {
				"title": "Top-Down RPG Starter",
				"description": "Top-down character, follow camera, enemy, coin. A starting point for a small RPG or adventure game.",
				"dimension": "2d",
				"difficulty": "beginner",
				"steps": [
					{"kind": "blueprint", "id": "player_2d_topdown", "note": "8-directional character."},
					{"kind": "blueprint", "id": "camera_2d_follow", "note": "Set target_path to the player."},
					{"kind": "snippet", "id": "camera_limits_2d", "note": "Prevents camera from scrolling past level edges."},
					{"kind": "blueprint", "id": "coin_pickup_2d", "note": "Place a few around the map."},
					{"kind": "blueprint", "id": "enemy_patrol_2d", "note": "Give the player something to avoid."},
					{"kind": "snippet", "id": "inventory_system", "note": "Ready-made item tracking. Add to the player."},
					{"kind": "blueprint", "id": "hud_score_ui", "note": "Shows the current score."},
					{"kind": "blueprint", "id": "pause_menu_ui", "note": "Standard Escape-to-pause."}
				]
			},
			"starter_3d_third_person": {
				"title": "3D Third-Person Starter",
				"description": "Ground, character, orbit camera rig, sun, and a chase enemy. Good for action-adventure.",
				"dimension": "3d",
				"difficulty": "intermediate",
				"steps": [
					{"kind": "blueprint", "id": "ground_plane_3d", "note": "50x50 floor."},
					{"kind": "blueprint", "id": "directional_light_3d", "note": "Sun."},
					{"kind": "blueprint", "id": "player_3d", "note": "Delete the placeholder Camera3D after step 4."},
					{"kind": "blueprint", "id": "camera_rig_3d", "note": "Orbit rig. Set target_path to the player."},
					{"kind": "blueprint", "id": "enemy_chaser_3d", "note": "Optional — needs a NavigationRegion3D with baked mesh."},
					{"kind": "blueprint", "id": "coin_pickup_3d", "note": "Add a few around the level."},
					{"kind": "blueprint", "id": "pause_menu_ui", "note": "Escape to pause."}
				]
			},
			"starter_2d_topdown_combat": {
				"title": "2D Top-Down Combat Starter",
				"description": "Top-down player with melee attack, an enemy that chases and attacks back, health bar, and game over screen.",
				"dimension": "2d",
				"difficulty": "intermediate",
				"steps": [
					{"kind": "blueprint", "id": "player_2d_topdown", "note": "The player."},
					{"kind": "snippet", "id": "health_system", "note": "Add to the player."},
					{"kind": "snippet", "id": "melee_attack", "note": "Add to the player. Add an Area2D child named Hitbox."},
					{"kind": "snippet", "id": "knockback", "note": "Add to the player for hit reactions."},
					{"kind": "blueprint", "id": "enemy_patrol_2d", "note": "An enemy. Add health_system to it too."},
					{"kind": "snippet", "id": "chase_player", "note": "Add to the enemy. Set player_path to the player."},
					{"kind": "snippet", "id": "attack_player", "note": "Add to the enemy."},
					{"kind": "blueprint", "id": "health_bar_ui_blueprint", "note": "Set player_path to the player."},
					{"kind": "blueprint", "id": "game_over_ui", "note": "Shown when the player dies."},
					{"kind": "blueprint", "id": "pause_menu_ui", "note": "Escape to pause."}
				]
			}
		}
	}

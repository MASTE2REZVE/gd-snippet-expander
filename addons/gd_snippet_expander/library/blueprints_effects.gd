@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"blueprints": {
			"animated_player_2d": {
				"title": "Animated 2D Player",
				"phrases": ["animated player 2d", "animated character 2d", "sprite player", "animated sprite"],
				"category": "player",
				"subcategory": "2d",
				"dimension": "2d",
				"difficulty": "intermediate",
				"root": {
					"type": "CharacterBody2D",
					"name": "Player"
				},
				"required_children": [
					{"type": "CollisionShape2D", "name": "CollisionShape2D", "shape": "RectangleShape2D"},
					{"type": "AnimatedSprite2D", "name": "AnimatedSprite"},
					{"type": "AnimationPlayer", "name": "AnimationPlayer"}
				],
				"recommended_children": [],
				"script": "platformer_movement_2d",
				"required_actions": ["left", "right", "jump"],
				"setup_notes": [
					"The AnimatedSprite2D needs a SpriteFrames resource. Click the SpriteFrames slot in the Inspector and choose 'New SpriteFrames'.",
					"Add at least two animations: 'idle' and 'run'. Right-click each and 'Add frames from sprite sheet' if you have a sheet.",
					"The AnimationPlayer is included for combining animations with movement tweens (e.g. squash-and-stretch on jump).",
					"Adjust the CollisionShape2D rectangle to roughly match your sprite bounds.",
					"To drive the animations from code, add the 'animated sprite state' snippet to the Player script."
				],
				"next_steps": [
					{"snippet": "animated_sprite_state", "why": "Switches animations based on velocity."},
					{"snippet": "coyote_time_2d", "why": "Makes jumping feel fair on ledges."},
					{"snippet": "jump_buffer_2d", "why": "Lets early jump presses register."}
				],
				"mistakes": [
					"Forgetting to add a SpriteFrames resource to the AnimatedSprite2D means nothing renders.",
					"Naming the animations anything other than 'idle' and 'run' means the state snippet can't find them.",
					"Making the collision rectangle much larger than the visible sprite causes phantom collisions."
				]
			},
			"animated_player_3d": {
				"title": "Animated 3D Player",
				"phrases": ["animated player 3d", "animated character 3d", "3d animated player", "character with animation"],
				"category": "player",
				"subcategory": "3d",
				"dimension": "3d",
				"difficulty": "intermediate",
				"root": {
					"type": "CharacterBody3D",
					"name": "Player"
				},
				"required_children": [
					{"type": "CollisionShape3D", "name": "CollisionShape3D", "shape": "CapsuleShape3D"},
					{"type": "MeshInstance3D", "name": "Mesh", "mesh": "BoxMesh"},
					{"type": "AnimationPlayer", "name": "AnimationPlayer"}
				],
				"recommended_children": [
					{"type": "Camera3D", "name": "Camera3D", "transform": {"position": [0, 1.6, 0]}}
				],
				"script": "character_movement_3d",
				"required_actions": ["left", "right", "forward", "back", "jump"],
				"setup_notes": [
					"Drag your character model (.glb or .obj) onto the Mesh node to replace the placeholder BoxMesh.",
					"Most character models come with animations baked in. Godot imports them into the AnimationPlayer automatically.",
					"Open the AnimationPlayer and check the animation list — you'll see things like 'Idle', 'Walk', 'Run'. Rename them to 'idle', 'walk', 'run' for consistency.",
					"The CapsuleShape3D should be tall enough to contain the whole character. Typical humanoid: radius 0.3, height 1.8.",
					"To switch animations based on movement, add the 'animation tree setup' snippet and set up a state machine, or use 'animation play' for simple cases."
				],
				"next_steps": [
					{"snippet": "animation_tree_setup", "why": "For proper animation state machines."},
					{"snippet": "animation_tree_state", "why": "To switch between idle / walk / run."},
					{"snippet": "first_person_camera_3d", "why": "If you want first-person instead."}
				],
				"mistakes": [
					"Using BoxMesh as the final mesh. Replace with your real model before shipping.",
					"Animations play at world scale by default. If your model is scaled, animation positions may be wrong.",
					"Not renaming animations means code can't find them by name."
				]
			},
			"screen_effect_layer": {
				"title": "Screen Effect Layer",
				"phrases": ["screen effect", "screen effects", "post processing layer", "fullscreen effect"],
				"category": "ui",
				"subcategory": "effects",
				"dimension": "ui",
				"difficulty": "intermediate",
				"root": {
					"type": "CanvasLayer",
					"name": "ScreenEffects"
				},
				"required_children": [
					{"type": "ColorRect", "name": "EffectRect", "properties": {"color": [1, 1, 1, 1], "anchors_preset": 15}}
				],
				"recommended_children": [],
				"script": "",
				"required_actions": [],
				"setup_notes": [
					"This blueprint provides the layer for full-screen shader effects. The shader itself must be added by hand.",
					"In the Inspector for ScreenEffects, set the 'layer' property to a high number (100+) so it draws over the game.",
					"Select the EffectRect node. In its material slot, click 'New ShaderMaterial'.",
					"In that ShaderMaterial's shader slot, load one of the shader snippets from this library (shader_crt, shader_dissolve, etc.).",
					"Enable 'Use Screen Texture' on the material if the shader needs access to what's behind it (CRT, distortion).",
					"The EffectRect's color should stay white with full alpha — the shader does the actual coloring."
				],
				"next_steps": [
					{"snippet": "shader_crt", "why": "Full-screen CRT effect."},
					{"snippet": "shader_wave", "why": "Distortion effect."},
					{"snippet": "fade_in_ui", "why": "Simple black fade without a shader."}
				],
				"mistakes": [
					"Forgetting to set the CanvasLayer's layer high means the effect is hidden behind the game.",
					"Forgetting 'Use Screen Texture' on the material means the effect renders to a black screen instead of the game view.",
					"Setting EffectRect color to black makes it a solid overlay instead of a shader target."
				]
			}
		}
	}

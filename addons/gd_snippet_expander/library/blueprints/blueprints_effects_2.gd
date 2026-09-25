@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"blueprints": {
			"impact_effect": {
				"title": "Impact Effect",
				"phrases": ["impact effect", "hit effect", "impact particles", "damage impact"],
				"category": "effects",
				"subcategory": "combat",
				"dimension": "2d",
				"difficulty": "intermediate",
				"root": {
					"type": "Node2D",
					"name": "ImpactEffect"
				},
				"required_children": [
					{"type": "CPUParticles2D", "name": "Particles"},
					{"type": "AudioStreamPlayer2D", "name": "Sound"}
				],
				"recommended_children": [],
				"script": "",
				"required_actions": [],
				"setup_notes": [
					"Select the Particles node and configure it in the Inspector:",
					"  - amount: 20-40",
					"  - one_shot: ON",
					"  - explosiveness: 1.0",
					"  - lifetime: 0.4-0.6",
					"  - spread: 180 (full circle)",
					"  - initial velocity: 200-400",
					"  - gravity: (0, 200)",
					"Assign an AudioStream to the Sound node for the impact chime. Set its bus to 'SFX'.",
					"To make the effect auto-delete after playing, add this snippet to a Node script:",
					"    extends Node2D",
					"    func _ready() -> void:",
					"        $Particles.emitting = true",
					"        $Sound.play()",
					"        await get_tree().create_timer(1.0).timeout",
					"        queue_free()",
					"Save this as its own scene (.tscn) and load it in code with preload. Spawn it at the impact position and don't worry about cleanup."
				],
				"next_steps": [
					{"snippet": "particle_explosion", "why": "If you prefer to spawn particles from code instead of a scene."},
					{"snippet": "damage_number_popup", "why": "For floating damage text."},
					{"snippet": "camera_shake", "why": "For extra impact feel."}
				],
				"mistakes": [
					"Leaving one_shot OFF means the particles loop forever.",
					"Forgetting to hide the effect in a scene you spawn means it plays from the world origin first.",
					"Using 3D particles (GPUParticles3D) on a 2D scene — the wrong dimension class won't render."
				]
			},
			"death_effect": {
				"title": "Death Effect",
				"phrases": ["death effect", "enemy death effect", "death particles", "dying effect"],
				"category": "effects",
				"subcategory": "combat",
				"dimension": "2d",
				"difficulty": "intermediate",
				"root": {
					"type": "Node2D",
					"name": "DeathEffect"
				},
				"required_children": [
					{"type": "CPUParticles2D", "name": "Burst"},
					{"type": "CPUParticles2D", "name": "Smoke"},
					{"type": "AudioStreamPlayer2D", "name": "Sound"}
				],
				"recommended_children": [],
				"script": "",
				"required_actions": [],
				"setup_notes": [
					"Burst node — quick, bright particles:",
					"  - amount: 30, one_shot: ON, lifetime: 0.5",
					"  - velocity: 300-500, gravity: (0, 300)",
					"  - color: matching your enemy's tint",
					"Smoke node — slow rising particles:",
					"  - amount: 15, one_shot: ON, lifetime: 1.5",
					"  - velocity: 30-60, direction: UP, spread: 30",
					"  - gravity: (0, -30), color: grey with alpha 0.5",
					"Assign a death sound to the Sound node. Set its bus to 'SFX'.",
					"Self-delete script (attach to root Node2D as a script):",
					"    extends Node2D",
					"    func _ready() -> void:",
					"        $Burst.emitting = true",
					"        $Smoke.emitting = true",
					"        $Sound.play()",
					"        await get_tree().create_timer(2.0).timeout",
					"        queue_free()",
					"To also dissolve the enemy sprite before it disappears, combine with the shader_dissolve snippet."
				],
				"next_steps": [
					{"snippet": "shader_dissolve", "why": "For the sprite itself to dissolve instead of vanish."},
					{"snippet": "particle_smoke", "why": "Alternative smoke implementation."},
					{"snippet": "camera_shake", "why": "Small shake for enemy deaths feels good."}
				],
				"mistakes": [
					"Making every enemy death a 2-second effect gets repetitive fast. Keep it snappy — 0.5-1.0 second total.",
					"Spawning death effects at the enemy's feet when the sprite is above them makes the effect feel disconnected. Use the sprite's global_position.",
					"Forgetting to free the node leaks memory over a long session."
				]
			},
			"projectile_with_trail": {
				"title": "Projectile with Trail",
				"phrases": ["projectile trail", "bullet with trail", "fancy projectile", "tracer bullet"],
				"category": "combat",
				"subcategory": "ranged",
				"dimension": "2d",
				"difficulty": "intermediate",
				"root": {
					"type": "Area2D",
					"name": "Bullet"
				},
				"required_children": [
					{"type": "CollisionShape2D", "name": "CollisionShape2D", "shape": "CircleShape2D"},
					{"type": "Sprite2D", "name": "Sprite"},
					{"type": "CPUParticles2D", "name": "Trail"}
				],
				"recommended_children": [
					{"type": "PointLight2D", "name": "Glow"}
				],
				"script": "projectile",
				"required_actions": [],
				"setup_notes": [
					"The script already handles movement, damage, and auto-despawn. No code changes needed.",
					"Drag a bullet sprite onto the Sprite node.",
					"Configure the Trail particles in the Inspector:",
					"  - amount: 30, emitting: ON",
					"  - lifetime: 0.5, local_coords: OFF",
					"  - initial velocity: 5-20 (low — trail lingers)",
					"  - gravity: (0, 0)",
					"  - color: matching the bullet (yellow for laser, orange for fire, blue for plasma)",
					"Optional: assign a radial gradient texture to the Trail's texture slot for a soft fade.",
					"The Glow node (PointLight2D) is optional. Assign any gradient texture, set color to the bullet's tint, and enable it for a glow effect in dark scenes."
				],
				"next_steps": [
					{"snippet": "ranged_attack", "why": "To spawn this projectile from a weapon."},
					{"snippet": "impact_effect", "why": "Blueprint — spawn on hit for polish."},
					{"snippet": "damage_number_popup", "why": "To show damage dealt."}
				],
				"mistakes": [
					"Leaving the Trail's local_coords ON makes the trail follow the bullet instead of staying in place.",
					"Making the collision circle match the sprite exactly causes missed hits at high speeds. Make it slightly larger.",
					"Very fast bullets can pass through thin walls. Enable Continuous CD on the Area2D's collision settings."
				]
			}
		}
	}

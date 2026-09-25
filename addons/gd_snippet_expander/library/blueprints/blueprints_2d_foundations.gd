@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"blueprints": {
			"parallax_rig_2d": {
				"title": "Parallax Background Rig",
				"phrases": ["parallax rig", "parallax background blueprint", "scrolling background rig", "add parallax"],
				"category": "parallax",
				"subcategory": "setup",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "2d",
				"difficulty": "beginner",
				"root": {
					"type": "ParallaxBackground",
					"name": "ParallaxBackground"
				},
				"required_children": [
					{"type": "ParallaxLayer", "name": "FarLayer", "properties": {"motion_scale": [0.2, 0.2], "motion_mirroring": [1920, 0]}},
					{"type": "ParallaxLayer", "name": "MidLayer", "properties": {"motion_scale": [0.5, 0.5], "motion_mirroring": [1920, 0]}},
					{"type": "ParallaxLayer", "name": "NearLayer", "properties": {"motion_scale": [0.85, 0.85], "motion_mirroring": [1920, 0]}}
				],
				"recommended_children": [],
				"script": "",
				"required_actions": [],
				"setup_notes": [
					"Add a Sprite2D child to each ParallaxLayer and assign the background texture.",
					"Set motion_mirroring on each layer to match the texture's pixel width exactly (e.g. 1920 for a 1920px-wide texture). This makes it repeat infinitely.",
					"motion_scale controls the parallax factor: 0.2 = far (slow), 0.5 = mid, 0.85 = near (fast). 1.0 has no parallax.",
					"Place this at the scene root, ABOVE the level and player. Not as a child of the player.",
					"The active Camera2D drives the scroll automatically — no code needed.",
					"If the camera has a limit set, parallax stops scrolling past those bounds. Keep limits wide enough for the parallax to still look good."
				],
				"next_steps": [
					{"snippet": "parallax_infinite", "why": "If you want auto-scroll for a menu background."},
					{"snippet": "parallax_vertical", "why": "For top-down or flight games."},
					{"snippet": "parallax_fade", "why": "Distance-based opacity per layer."},
					{"blueprint": "camera_2d_follow", "why": "The camera that drives the parallax."}
				],
				"mistakes": [
					"Wrong motion_mirroring value causes visible seams or gaps. Measure the texture width in an image editor.",
					"Putting ParallaxBackground as a child of a moving player rotates it with the player. Keep it at scene root.",
					"Missing a ParallaxLayer's texture means that depth level shows nothing — check every layer.",
					"Setting motion_scale above 1.0 makes layers move faster than the world, which usually looks wrong."
				]
			},
			"one_way_platform": {
				"title": "One-Way Platform",
				"phrases": ["one way platform", "jump through platform", "drop through platform blueprint", "add one way"],
				"category": "platformer",
				"subcategory": "platforms",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "2d",
				"difficulty": "beginner",
				"root": {
					"type": "StaticBody2D",
					"name": "OneWayPlatform"
				},
				"required_children": [
					{"type": "CollisionShape2D", "name": "CollisionShape2D", "shape": "RectangleShape2D"},
					{"type": "ColorRect", "name": "Visual", "properties": {"color": [0.4, 0.6, 0.3, 1.0]}}
				],
				"recommended_children": [],
				"script": "",
				"required_actions": [],
				"setup_notes": [
					"The CollisionShape2D is what makes it one-way. In the Inspector:",
					"  - Select the CollisionShape2D child.",
					"  - Tick 'One Way Collision' to ON.",
					"  - Set its RectangleShape2D size to roughly (96, 8) — thin and wide.",
					"The ColorRect is a placeholder visual. Replace with a Sprite2D or tile it with a TileMapLayer.",
					"The one-way direction is controlled by the shape's 'One Way Collision Margin' — positive makes it solid from above.",
					"To let the player drop through, add the platform_drop_through snippet to the player's script."
				],
				"next_steps": [
					{"snippet": "platform_drop_through", "why": "Lets the player fall through with the Down key."},
					{"snippet": "platformer_movement_2d", "why": "The player that uses this platform."},
					{"snippet": "moving_platform", "why": "For a platform that also moves."}
				],
				"mistakes": [
					"Forgetting to enable One Way Collision means the platform blocks from both sides — the player can't jump up through it.",
					"Making the RectangleShape2D too thick means the player's body clips visibly into it before landing.",
					"Putting the visual ColorRect in front of the player (higher z_index) hides the player. Keep the visual at z_index 0.",
					"Not adding the player's collision layer to the shape's mask means the player ignores it entirely."
				]
			},
			"moving_platform": {
				"title": "Moving Platform",
				"phrases": ["moving platform blueprint", "add moving platform", "patrol platform blueprint", "horizontal platform"],
				"category": "platformer",
				"subcategory": "platforms",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "2d",
				"difficulty": "intermediate",
				"root": {
					"type": "AnimatableBody2D",
					"name": "MovingPlatform"
				},
				"required_children": [
					{"type": "CollisionShape2D", "name": "CollisionShape2D", "shape": "RectangleShape2D"},
					{"type": "ColorRect", "name": "Visual", "properties": {"color": [0.6, 0.5, 0.4, 1.0]}}
				],
				"recommended_children": [],
				"script": "moving_platform",
				"required_actions": [],
				"setup_notes": [
					"The script moves between point_a and point_b, which default to (0,0) and (200,0).",
					"Both points are RELATIVE to the platform's starting position. Moving the platform in the editor shifts both.",
					"Adjust in the Inspector:",
					"  - point_a: start position (usually stays at [0, 0])",
					"  - point_b: end position relative to start",
					"  - travel_time: seconds one way",
					"  - wait_time: pause at each end",
					"AnimatableBody2D is required for the player to ride. StaticBody2D does not carry riders.",
					"Resize the CollisionShape2D rectangle to match your visual."
				],
				"next_steps": [
					{"snippet": "moving_platform_path", "why": "Multi-waypoint version with more than 2 points."},
					{"blueprint": "one_way_platform", "why": "For jump-through platforms that don't move."},
					{"snippet": "platformer_movement_2d", "why": "The player that rides this platform."}
				],
				"mistakes": [
					"Using StaticBody2D means the player doesn't ride — they fall through the platform when it moves.",
					"Setting point_a and point_b in world coordinates instead of relative coordinates makes the platform teleport on the first frame.",
					"Very high travel speeds (travel_time under 0.5) make the platform jittery with the physics engine."
				]
			},
			"ladder": {
				"title": "Ladder Zone",
				"phrases": ["ladder blueprint", "add ladder", "climbable ladder", "climbing zone"],
				"category": "platformer",
				"subcategory": "traversal",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "2d",
				"difficulty": "intermediate",
				"root": {
					"type": "Area2D",
					"name": "Ladder"
				},
				"required_children": [
					{"type": "CollisionShape2D", "name": "CollisionShape2D", "shape": "RectangleShape2D"},
					{"type": "Sprite2D", "name": "Sprite"}
				],
				"recommended_children": [],
				"script": "ladder",
				"required_actions": [],
				"setup_notes": [
					"Resize the CollisionShape2D rectangle to fit the ladder visual. Make it slightly narrow so the player doesn't enter from the sides.",
					"Add your ladder sprite to the Sprite node.",
					"The script calls set_in_ladder(true/false) on the player when entering or exiting.",
					"Your player script must implement these two things:",
					"  var _in_ladder: bool = false",
					"  func set_in_ladder(value): _in_ladder = value",
					"And in _physics_process, before gravity is applied:",
					"  if _in_ladder:",
					"      var input_y := Input.get_axis('up', 'down')",
					"      velocity.y = input_y * climb_speed",
					"      if absf(input_y) > 0.1: velocity.x = 0.0",
					"Place the ladder Area2D so its bottom overlaps the floor and its top reaches the destination platform."
				],
				"next_steps": [
					{"snippet": "platformer_movement_2d", "why": "The base movement to modify."},
					{"snippet": "wall_slide_2d", "why": "For a wall-climb alternative to ladders."},
					{"snippet": "character_movement_2d", "why": "If using a top-down layout instead."}
				],
				"mistakes": [
					"Forgetting to disable normal horizontal velocity while climbing makes the player walk sideways off the ladder.",
					"Making the Area2D collision too wide lets the player latch on from the side.",
					"Placing the ladder without overlapping the top platform means the player can't exit at the top."
				]
			},
			"spring_pad": {
				"title": "Spring Pad",
				"phrases": ["spring pad blueprint", "bounce pad", "add spring", "jump pad blueprint"],
				"category": "environment",
				"subcategory": "spring",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "2d",
				"difficulty": "beginner",
				"root": {
					"type": "Area2D",
					"name": "Spring"
				},
				"required_children": [
					{"type": "CollisionShape2D", "name": "CollisionShape2D", "shape": "RectangleShape2D"},
					{"type": "Sprite2D", "name": "Sprite"}
				],
				"recommended_children": [],
				"script": "spring_2d",
				"required_actions": [],
				"setup_notes": [
					"Resize the CollisionShape2D rectangle to cover the top of the spring sprite. It should be wide enough to catch the player but thin.",
					"Add your spring sprite to the Sprite node.",
					"Adjust bounce_velocity in the Inspector:",
					"  -400 = small hop (about 1 tile high)",
					"  -700 = standard launch (about 2-3 tiles)",
					"  -1200 = super jump (about 5 tiles)",
					"To send the player at an angle instead of straight up, set horizontal_boost to a positive or negative value.",
					"Add a bounce sound and a particle burst on launch for feedback. The spring script's cooldown prevents multi-firing."
				],
				"next_steps": [
					{"snippet": "particle_explosion", "why": "Add a burst on bounce."},
					{"snippet": "play_sound", "why": "Bounce sound."},
					{"snippet": "platformer_movement_2d", "why": "The player that uses the spring."}
				],
				"mistakes": [
					"Zero cooldown means the spring fires every physics frame the player overlaps it, launching them into space.",
					"Making the collision shape too tall means the player triggers it before visually touching the spring.",
					"Setting horizontal_boost when the player is standing still pushes them sideways for no reason — guard with a velocity check."
				]
			},
			"ice_surface": {
				"title": "Ice Surface",
				"phrases": ["ice surface blueprint", "slippery ice", "add ice", "ice ground"],
				"category": "environment",
				"subcategory": "surface",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "2d",
				"difficulty": "intermediate",
				"root": {
					"type": "Area2D",
					"name": "IceSurface"
				},
				"required_children": [
					{"type": "CollisionShape2D", "name": "CollisionShape2D", "shape": "RectangleShape2D"},
					{"type": "ColorRect", "name": "Visual", "properties": {"color": [0.7, 0.85, 1.0, 0.9]}}
				],
				"recommended_children": [],
				"script": "ice_surface_2d",
				"required_actions": [],
				"setup_notes": [
					"Place this Area2D directly on top of your ice floor tiles. The collision shape should cover the walkable area, not the whole tile.",
					"The script calls set_surface_friction(ice_friction) on the player when they enter and set_surface_friction(normal_friction) when they leave.",
					"Your player script must implement:",
					"  @export var friction: float = 1500.0",
					"  func set_surface_friction(value: float) -> void:",
					"      friction = value",
					"And use `friction` in your deceleration:",
					"  velocity = velocity.move_toward(Vector2.ZERO, friction * delta)",
					"Replace the ColorRect with a proper ice sprite for production.",
					"Layer the Area2D slightly above the tilemap so it overlaps the player."
				],
				"next_steps": [
					{"snippet": "platformer_movement_2d", "why": "The movement that must read friction."},
					{"snippet": "mud_zone_2d", "why": "The opposite — slowing surfaces."},
					{"snippet": "particle_dust", "why": "Skid particles when the player brakes."}
				],
				"mistakes": [
					"Not modifying your movement code to use a friction variable means the ice has no visible effect. The snippet alone does nothing without player changes.",
					"Placing the Area2D as a child of the player means it moves with them and constantly fires enter/exit.",
					"Setting ice_friction too low (under 100) makes the player feel like they're on rails."
				]
			}
		}
	}

@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"blueprints": {
			"environment_rig_3d": {
				"title": "3D Environment Rig",
				"phrases": ["environment rig 3d", "3d environment setup", "world environment rig", "add environment 3d"],
				"category": "world",
				"subcategory": "environment",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "beginner",
				"root": {
					"type": "Node3D",
					"name": "EnvironmentRig"
				},
				"required_children": [
					{"type": "WorldEnvironment", "name": "WorldEnvironment"},
					{"type": "DirectionalLight3D", "name": "Sun"}
				],
				"recommended_children": [],
				"script": "",
				"required_actions": [],
				"setup_notes": [
					"Select the WorldEnvironment node. In the Inspector, click the Environment slot -> New Environment.",
					"Configure the Environment resource:",
					"  - Background Mode: Sky (procedural sky) for outdoors",
					"  - Sky: click to create New ProceduralSkyMaterial",
					"  - Ambient Light Source: Sky",
					"  - Tonemap Mode: Filmic for a cinematic look",
					"  - Glow: enable for bloom on emissive materials",
					"  - Fog: enable with density around 0.02 for atmospheric depth",
					"Select the Sun (DirectionalLight3D). In the Inspector:",
					"  - Rotation: drag in the 3D viewport to set sun angle",
					"  - Shadow: enabled",
					"  - Directional Shadow Mode: PSSM 4 Splits (for outdoor scenes)",
					"  - Light Energy: 1.0 for standard daylight",
					"  - Light Color: warm orange for sunset, white for noon",
					"Run the script from world_3d.gd on the EnvironmentRig node to auto-configure the sky if you prefer code.",
					"Place this rig as a direct child of your 3D scene root."
				],
				"next_steps": [
					{"snippet": "world_environment_3d", "why": "The script that configures the environment."},
					{"snippet": "day_night_3d", "why": "Add a day/night cycle to the sun."},
					{"snippet": "fog_3d", "why": "Add distance fog for depth."},
					{"blueprint": "ground_plane_3d", "why": "The floor to stand on."}
				],
				"mistakes": [
					"Forgetting to set the Environment slot means no sky, no ambient light, and pitch-black shadows.",
					"Multiple WorldEnvironment nodes fight each other. Only one per scene.",
					"Missing the sun means everything is lit only by ambient light — flat and washed out.",
					"Sun rotation of 0,0,0 makes the light point straight down — flat and unnatural. Use 45+ degrees."
				]
			},
			"spring_arm_camera_rig": {
				"title": "Spring Arm Camera Rig",
				"phrases": ["spring arm camera rig", "third person camera rig", "camera rig 3d springarm", "collision camera 3d"],
				"category": "camera",
				"subcategory": "3d",
				"platforms": ["desktop", "mobile"],
				"dimension": "3d",
				"difficulty": "intermediate",
				"root": {
					"type": "SpringArm3D",
					"name": "CameraRig"
				},
				"required_children": [
					{"type": "Camera3D", "name": "Camera3D", "transform": {"position": [0, 0, 0]}}
				],
				"recommended_children": [],
				"script": "spring_arm_camera_3d",
				"required_actions": [],
				"setup_notes": [
					"Node tree structure:",
					"  Player (CharacterBody3D)",
					"    CameraRig (SpringArm3D)  <- this blueprint",
					"      Camera3D",
					"    Body (MeshInstance3D)",
					"    CollisionShape3D",
					"The SpringArm3D should be a child of the player. The Camera3D at its tip.",
					"Position the SpringArm3D at roughly head height — set its transform.y to about 1.5.",
					"In the Inspector for the SpringArm3D:",
					"  - Spring Length: 4.0 (ideal distance behind player)",
					"  - Margin: 0.1 (how much space to leave before a wall)",
					"  - Collision Mask: set to layer 1 (default walls)",
					"The script has a target_path property. Since this rig is a child of the player, set target_path to '..' (the parent).",
					"Set the Camera3D's 'current' property to true so it becomes the active camera.",
					"Attach the script to the SpringArm3D (not the Camera3D)."
				],
				"next_steps": [
					{"blueprint": "player_3d", "why": "The player this rig is attached to."},
					{"snippet": "spring_arm_camera_3d", "why": "The camera logic."},
					{"snippet": "camera_shake_3d", "why": "Add shake for hits."},
					{"blueprint": "animated_player_3d", "why": "Combine with a rigged character."}
				],
				"mistakes": [
					"Placing the Camera3D at the SpringArm3D's origin (0,0,0) means the arm collision doesn't protect the camera. Put the camera at the tip.",
					"Making the SpringArm3D a sibling of the player (not a child) means it doesn't follow the player.",
					"Setting spring_length too high (over 10) makes the camera lose focus on the player.",
					"Forgetting current = true on the Camera3D means another camera stays active."
				]
			},
			"item_pickup_3d": {
				"title": "Item Pickup (3D)",
				"phrases": ["pickup 3d", "item pickup 3d", "3d coin", "collectible 3d", "add pickup 3d"],
				"category": "pickup",
				"subcategory": "3d",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "beginner",
				"root": {
					"type": "Area3D",
					"name": "Pickup"
				},
				"required_children": [
					{"type": "CollisionShape3D", "name": "CollisionShape3D", "shape": "SphereShape3D"},
					{"type": "MeshInstance3D", "name": "Mesh", "mesh": "SphereMesh"},
					{"type": "OmniLight3D", "name": "Glow", "properties": {"light_color": [1.0, 0.9, 0.4, 1.0], "light_energy": 1.5, "omni_range": 3.0}}
				],
				"recommended_children": [],
				"script": "",
				"required_actions": [],
				"setup_notes": [
					"The CollisionShape3D sphere defaults to radius 0.5. Adjust to match the visual size.",
					"The Mesh uses a default SphereMesh. Replace with a coin model or your own mesh.",
					"The OmniLight3D adds a glow around the pickup. Optional but helps items stand out in dark areas.",
					"Attach this script to the Area3D root:",
					"",
					"    extends Area3D",
					"",
					"    @export var item_id: String = \"coin\"",
					"    @export var count: int = 1",
					"    @export var spin_speed: float = 2.0",
					"    @export var bob_height: float = 0.3",
					"",
					"    var _time: float = 0.0",
					"    var _origin_y: float = 0.0",
					"",
					"    func _ready() -> void:",
					"        body_entered.connect(_on_body_entered)",
					"        _origin_y = position.y",
					"",
					"    func _process(delta: float) -> void:",
					"        rotate_y(spin_speed * delta)",
					"        _time += delta",
					"        position.y = _origin_y + sin(_time * 2.0) * bob_height",
					"",
					"    func _on_body_entered(body: Node3D) -> void:",
					"        if not body.is_in_group(\"player\"):",
					"            return",
					"        var inventory = get_tree().get_first_node_in_group(\"inventory\")",
					"        if inventory != null and inventory.has_method(\"add_item\"):",
					"            inventory.add_item(item_id, count)",
					"            queue_free()",
					"",
					"Set the item_id in the Inspector to match your inventory's item registry. The pickup only despawns on successful add.",
					"Pair with particle_sparkle (as a child) for a glowing effect."
				],
				"next_steps": [
					{"snippet": "item_registry", "why": "Register the item type."},
					{"snippet": "particle_sparkle", "why": "Ambient sparkles for the pickup."},
					{"snippet": "play_sound", "why": "Pickup chime."},
					{"blueprint": "inventory_ui_grid", "why": "Where the item ends up."}
				],
				"mistakes": [
					"Not adding the player to group 'player' means the pickup never fires on touch.",
					"Forgetting queue_free() leaves collected items in the scene.",
					"Making the OmniLight3D too bright in a dark scene looks unnatural. Keep energy under 2.0.",
					"Sphere collision shape overlapping the ground triggers pickup on spawn — raise the pickup off the floor."
				]
			},
			"gravity_zone_3d_blueprint": {
				"title": "Gravity Zone (3D)",
				"phrases": ["gravity zone blueprint", "add gravity zone", "low gravity room", "anti gravity area"],
				"category": "environment",
				"subcategory": "3d",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "intermediate",
				"root": {
					"type": "Area3D",
					"name": "GravityZone"
				},
				"required_children": [
					{"type": "CollisionShape3D", "name": "CollisionShape3D", "shape": "BoxShape3D"}
				],
				"recommended_children": [],
				"script": "gravity_zone_3d",
				"required_actions": [],
				"setup_notes": [
					"Resize the CollisionShape3D BoxShape3D to cover the volume where gravity changes. In the Inspector, set size to (10, 8, 10) for a large room.",
					"Set the Area3D's collision layer and mask so it detects the player and any RigidBody3D objects:",
					"  - Monitorable: on",
					"  - Collision Mask: includes the player's layer",
					"In the Inspector for the GravityZone script:",
					"  - gravity_scale: 0.3 for moon, 0.5 for half, -0.5 for anti-gravity",
					"  - extra_force: Vector3(0, 0, 0) for pure gravity change, or a non-zero vector for wind push",
					"Optional visual feedback:",
					"  - Add a semi-transparent BoxMesh child with an unusual color (cyan for low-g, purple for anti-g)",
					"  - Add a particle effect floating upward inside the zone",
					"To make characters spawn with modified gravity, they must be inside the box when they enter the scene."
				],
				"next_steps": [
					{"snippet": "gravity_zone_3d", "why": "The zone logic."},
					{"snippet": "particle_sparkle", "why": "Ambient floating particles."},
					{"blueprint": "player_3d", "why": "The character that experiences the zone."},
					{"snippet": "water_zone_3d", "why": "For underwater sections."}
				],
				"mistakes": [
					"Not matching the collision mask to the player's layer means the zone detects nothing.",
					"Setting gravity_scale to 0.0 makes characters float forever. Use 0.1 as a minimum for low-gravity.",
					"Making the collision shape too small means the player triggers gravity changes for a fraction of a second.",
					"Anti-gravity (negative scale) sends RigidBody3D objects flying — check your level design before combining."
				]
			}
		}
	}

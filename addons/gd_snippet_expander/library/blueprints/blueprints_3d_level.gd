@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"blueprints": {
			"door_3d_blueprint": {
				"title": "Door (3D)",
				"phrases": ["door blueprint 3d", "add 3d door", "make a door 3d", "3d swinging door"],
				"category": "interaction",
				"subcategory": "3d",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "intermediate",
				"root": {
					"type": "Node3D",
					"name": "Door"
				},
				"required_children": [
					{"type": "Node3D", "name": "Hinge"},
					{"type": "MeshInstance3D", "name": "DoorMesh"},
					{"type": "StaticBody3D", "name": "DoorBody"},
					{"type": "CollisionShape3D", "name": "CollisionShape3D", "shape": "BoxShape3D"}
				],
				"recommended_children": [],
				"script": "door_3d",
				"required_actions": ["interact"],
				"setup_notes": [
					"Note: re-parent the children after building. The tree should be:",
					"  Door (Node3D) — script on this",
					"    Hinge (Node3D) — rotates when door opens",
					"      DoorMesh (MeshInstance3D) — the visual",
					"      DoorBody (StaticBody3D)",
					"        CollisionShape3D (BoxShape3D)",
					"Position the Hinge at the door's edge (the side that swings). The door rotates around the Hinge's local Y axis.",
					"Set the CollisionShape3D BoxShape3D size to match the door's dimensions — e.g. (0.05, 2.0, 1.0) for a thin tall door.",
					"Assign a door mesh (BoxMesh works as a placeholder) to DoorMesh.",
					"Add the door to the interaction collision layer so the player's raycast_interact_3d finds it.",
					"In the Inspector on the Door script:",
					"  - locked: false for a normal door, true to require a key",
					"  - required_key: leave empty unless locked is true",
					"  - open_angle: 90 for standard swing",
					"  - open_duration: 0.6 seconds"
				],
				"next_steps": [
					{"snippet": "door_3d", "why": "The door logic."},
					{"snippet": "raycast_interact_3d", "why": "The player side that triggers interaction."},
					{"blueprint": "key_pickup_2d", "why": "A key to unlock it (works for 3D too)."},
					{"snippet": "play_sound", "why": "Door creak on open."}
				],
				"mistakes": [
					"Putting the Hinge at the door's center makes it spin in place instead of swinging from the edge.",
					"Not adding the door's StaticBody3D to the interaction collision layer means the raycast never finds it.",
					"Forgetting the 'interact' input action means nothing happens when the player presses E.",
					"Setting open_angle to 180 makes the door sweep through the frame and clip through walls."
				]
			},
			"switch_3d_blueprint": {
				"title": "Switch Lever (3D)",
				"phrases": ["switch blueprint 3d", "add 3d switch", "3d lever blueprint", "interactable 3d switch"],
				"category": "interaction",
				"subcategory": "3d",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "intermediate",
				"root": {
					"type": "Node3D",
					"name": "Switch"
				},
				"required_children": [
					{"type": "MeshInstance3D", "name": "Base", "mesh": "BoxMesh"},
					{"type": "Node3D", "name": "Handle"},
					{"type": "MeshInstance3D", "name": "HandleMesh", "mesh": "CylinderMesh"},
					{"type": "StaticBody3D", "name": "SwitchBody"},
					{"type": "CollisionShape3D", "name": "CollisionShape3D", "shape": "BoxShape3D"}
				],
				"recommended_children": [],
				"script": "switch_3d",
				"required_actions": ["interact"],
				"setup_notes": [
					"Note: re-parent the children after building. The tree should be:",
					"  Switch (Node3D) — script on this",
					"    Base (MeshInstance3D) — the mounting plate",
					"    Handle (Node3D) — rotates when toggled",
					"      HandleMesh (MeshInstance3D) — the lever itself",
					"    SwitchBody (StaticBody3D)",
					"      CollisionShape3D (BoxShape3D)",
					"The Handle node should be positioned at the pivot point of the lever (usually the bottom of the lever). HandleMesh is offset from the Handle to extend upward.",
					"Set CollisionShape3D size to roughly (0.4, 0.6, 0.4) so the raycast can find the switch.",
					"Add the switch to the interaction collision layer.",
					"In the Inspector for the Switch script:",
					"  - starts_on: false for a lever that begins down",
					"  - rotate_on_axis: Vector3(1, 0, 0) for a forward-backward throw",
					"  - rotate_angle: 45 degrees",
					"  - one_shot: true if the switch should only turn on, never off",
					"Connect switched_on and switched_off signals to whatever the switch controls (doors, lights, platforms)."
				],
				"next_steps": [
					{"snippet": "switch_3d", "why": "The switch logic."},
					{"snippet": "door_3d", "why": "A door the switch can control."},
					{"snippet": "moving_platform_3d", "why": "A platform the switch activates."},
					{"snippet": "raycast_interact_3d", "why": "The player interaction side."}
				],
				"mistakes": [
					"Rotating the Switch root instead of the Handle node means the base rotates too. Always use a Handle child.",
					"Forgetting the collision layer assignment means the raycast doesn't find the switch.",
					"Making the interaction shape too small (under 0.2) makes the raycast hard to land.",
					"Not connecting switched_on to anything means the lever flips but nothing happens."
				]
			},
			"enemy_spawner_3d": {
				"title": "Enemy Spawner (3D)",
				"phrases": ["enemy spawner 3d", "3d spawner", "spawn enemies 3d", "wave spawner 3d"],
				"category": "enemy",
				"subcategory": "3d",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "beginner",
				"root": {
					"type": "Node3D",
					"name": "EnemySpawner"
				},
				"required_children": [
					{"type": "Timer", "name": "SpawnTimer", "properties": {"wait_time": 5.0, "autostart": true}},
					{"type": "Marker3D", "name": "SpawnPoint"}
				],
				"recommended_children": [],
				"script": "",
				"required_actions": [],
				"setup_notes": [
					"Position the SpawnPoint Marker3D at the location where enemies appear. Typically a few centimeters above the floor.",
					"Attach this script to the EnemySpawner root:",
					"",
					"    extends Node3D",
					"",
					"    @export var enemy_scene: PackedScene",
					"    @export var max_alive: int = 8",
					"    @export var spawn_variance: float = 2.0",
					"",
					"    var _alive_count: int = 0",
					"",
					"    func _ready() -> void:",
					"        $SpawnTimer.timeout.connect(_spawn)",
					"",
					"    func _spawn() -> void:",
					"        if enemy_scene == null or _alive_count >= max_alive:",
					"            return",
					"        var enemy := enemy_scene.instantiate()",
					"        get_tree().current_scene.add_child(enemy)",
					"        enemy.global_position = $SpawnPoint.global_position + _random_offset()",
					"        _alive_count += 1",
					"        if enemy.has_signal(\"died\"):",
					"            enemy.died.connect(_on_enemy_died)",
					"",
					"    func _random_offset() -> Vector3:",
					"        return Vector3(",
					"            randf_range(-spawn_variance, spawn_variance),",
					"            0,",
					"            randf_range(-spawn_variance, spawn_variance)",
					"        )",
					"",
					"    func _on_enemy_died() -> void:",
					"        _alive_count -= 1",
					"",
					"Set enemy_scene in the Inspector to your enemy .tscn. Adjust SpawnTimer's wait_time to control the spawn rate.",
					"For multiple spawn points, duplicate the Marker3D and pick one randomly in _spawn().",
					"The max_alive cap prevents the scene from flooding with enemies on slower devices."
				],
				"next_steps": [
					{"blueprint": "flying_enemy_2d_blueprint", "why": "An enemy to spawn."},
					{"snippet": "spawn_prefab", "why": "Alternative simpler spawner."},
					{"snippet": "loot_table", "why": "Drops from spawned enemies."}
				],
				"mistakes": [
					"No max_alive cap means the spawner floods the level on long play sessions. Always cap.",
					"Spawning enemies as children of the spawner makes them move with it if the spawner moves.",
					"Spawning at ground level clips enemies into the floor. Add a small Y offset on the Marker3D.",
					"Very fast spawn rates (Timer wait_time under 1.0) tank performance."
				]
			},
			"checkpoint_3d": {
				"title": "Checkpoint (3D)",
				"phrases": ["checkpoint 3d", "3d checkpoint", "save point 3d", "respawn 3d"],
				"category": "level",
				"subcategory": "3d",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "beginner",
				"root": {
					"type": "Area3D",
					"name": "Checkpoint"
				},
				"required_children": [
					{"type": "CollisionShape3D", "name": "CollisionShape3D", "shape": "SphereShape3D"},
					{"type": "MeshInstance3D", "name": "Marker", "mesh": "CylinderMesh"},
					{"type": "OmniLight3D", "name": "Glow"}
				],
				"recommended_children": [],
				"script": "",
				"required_actions": [],
				"setup_notes": [
					"CollisionShape3D sphere radius should be 1.0 to 1.5 meters for reliable detection. Players walking through the sphere trigger it.",
					"The Marker MeshInstance3D is a placeholder. Replace with a flag, obelisk, or glowing crystal.",
					"Attach this script to the Area3D root:",
					"",
					"    extends Area3D",
					"",
					"    signal checkpoint_activated(position: Vector3)",
					"",
					"    @export var checkpoint_id: String = \"checkpoint_1\"",
					"    @export var respawn_offset: Vector3 = Vector3(0, 0.5, 0)",
					"    @export var activated_color: Color = Color(0.3, 1.0, 0.3)",
					"",
					"    var _activated: bool = false",
					"",
					"    func _ready() -> void:",
					"        body_entered.connect(_on_body_entered)",
					"        add_to_group(\"checkpoint\")",
					"",
					"    func _on_body_entered(body: Node3D) -> void:",
					"        if _activated:",
					"            return",
					"        if not body.is_in_group(\"player\"):",
					"            return",
					"        _activated = true",
					"        var save_pos := global_position + respawn_offset",
					"        checkpoint_activated.emit(save_pos)",
					"        var manager = get_tree().get_first_node_in_group(\"checkpoint_manager\")",
					"        if manager != null and manager.has_method(\"set_respawn_point\"):",
					"            manager.set_respawn_point(checkpoint_id, save_pos)",
					"        _update_visual()",
					"",
					"    func _update_visual() -> void:",
					"        if has_node(\"Marker\"):",
					"            var mat := StandardMaterial3D.new()",
					"            mat.albedo_color = activated_color",
					"            mat.emission_enabled = true",
					"            mat.emission = activated_color",
					"            mat.emission_energy_multiplier = 3.0",
					"            $Marker.material_override = mat",
					"        if has_node(\"Glow\"):",
					"            $Glow.light_color = activated_color",
					"",
					"Add this Area3D to the 'checkpoint' group. Optional: add to a checkpoint_manager autoload (see checkpoint_manager snippet) for persistent respawn across sessions.",
					"Place the OmniLight3D at the base of the marker for a glow effect."
				],
				"next_steps": [
					{"snippet": "checkpoint_manager", "why": "Persistent respawn across sessions."},
					{"snippet": "respawn", "why": "Player respawn logic."},
					{"snippet": "omni_light_3d", "why": "Glow effect tuning."},
					{"blueprint": "player_3d", "why": "The player that activates it."}
				],
				"mistakes": [
					"Not adding the player to group 'player' means the checkpoint never fires.",
					"Same checkpoint_id on two checkpoints overwrites each other in the save file.",
					"Collision shape too small means the player can run past without triggering.",
					"Not calling checkpoint_manager.set_respawn_point() means respawns don't persist between play sessions."
				]
			}
		}
	}

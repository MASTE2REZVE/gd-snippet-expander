@tool
extends Node


func describe(node: Node) -> Dictionary:
	if node == null:
		return {"ok": false, "message": "No node selected."}
	var cls := node.get_class()
	var info := _lookup(cls)
	if info.is_empty():
		info = _fallback_info(cls)
	return {
		"ok": true,
		"class": cls,
		"name": node.name,
		"info": info
	}


func format(node: Node) -> String:
	var result := describe(node)
	if not result.get("ok", false):
		return str(result.get("message", "Unknown node."))
	var info: Dictionary = result.get("info", {})
	var lines: Array = []
	lines.append(str(result.name) + "  (" + str(result.class) + ")")
	lines.append("")
	_append_section(lines, "WHAT", str(info.get("what", "")))
	_append_section(lines, "REQUIRED CHILDREN", str(info.get("required", "")))
	_append_section(lines, "RECOMMENDED CHILDREN", str(info.get("recommended", "")))
	_append_section(lines, "USUALLY PAIRED WITH", str(info.get("paired", "")))
	_append_section(lines, "COMMON MISTAKES", str(info.get("mistakes", "")))
	_append_section(lines, "DOCS", str(info.get("docs", "")))
	return "\n".join(lines)


func _append_section(out: Array, title: String, body: String) -> void:
	if body.strip_edges().is_empty():
		return
	if not out.is_empty():
		out.append("")
	out.append(title)
	out.append("  " + body)


func _lookup(cls: String) -> Dictionary:
	match cls:
		"CharacterBody2D":
			return {
				"what": "A 2D physics body for player or enemy characters you move with code.",
				"required": "CollisionShape2D — without it, the character has no physical presence.",
				"recommended": "Sprite2D or AnimatedSprite2D for visuals.",
				"paired": "camera_follow_2d to track it, health_system for damage handling.",
				"mistakes": "Forgetting to call move_and_slide() means the character never moves.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_characterbody2d.html"
			}
		"CharacterBody3D":
			return {
				"what": "A 3D physics body for player or enemy characters you move with code.",
				"required": "CollisionShape3D — without it, the character falls through everything.",
				"recommended": "MeshInstance3D or a .glb model for visuals. Camera3D for first/third-person.",
				"paired": "character_movement_3d or first_person_movement.",
				"mistakes": "Using velocity += for horizontal movement. Set velocity.x and velocity.z directly.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_characterbody3d.html"
			}
		"Area2D":
			return {
				"what": "A 2D region that detects overlap with bodies and other areas. Doesn't block movement.",
				"required": "CollisionShape2D — defines the detection region.",
				"recommended": "Connect body_entered or area_entered to react to overlap.",
				"paired": "coin_pickup, hitbox, hurtbox, detection_area.",
				"mistakes": "Expecting Area2D to block movement. It never does — that's StaticBody2D's job.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_area2d.html"
			}
		"Area3D":
			return {
				"what": "A 3D region that detects overlap with bodies and other areas. Doesn't block movement.",
				"required": "CollisionShape3D — defines the detection region.",
				"recommended": "Connect body_entered or area_entered to react to overlap.",
				"paired": "coin_pickup_3d, interaction prompts, trigger zones.",
				"mistakes": "Expecting Area3D to block movement. It never does.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_area3d.html"
			}
		"StaticBody2D":
			return {
				"what": "A 2D physics body that doesn't move. Used for walls, floors, platforms.",
				"required": "CollisionShape2D — defines the physical shape.",
				"recommended": "Sprite2D or ColorRect for visuals matching the collision shape.",
				"paired": "platformer_movement_2d (the player stands on this).",
				"mistakes": "Making the visual bigger than the collision shape means parts of the wall look solid but aren't.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_staticbody2d.html"
			}
		"StaticBody3D":
			return {
				"what": "A 3D physics body that doesn't move. Walls, floors, platforms.",
				"required": "CollisionShape3D — defines the physical shape.",
				"recommended": "MeshInstance3D matching the collision shape.",
				"paired": "ground_plane_3d blueprint provides one preconfigured.",
				"mistakes": "Forgetting CollisionShape3D means the player walks through.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_staticbody3d.html"
			}
		"Camera2D":
			return {
				"what": "The 2D viewport camera. Only one is active at a time.",
				"required": "Nothing — but it needs to be enabled (current = true).",
				"recommended": "Set limit_left/top/right/bottom to keep the camera within level bounds.",
				"paired": "camera_follow_2d, camera_smooth_follow_2d, camera_limits_2d.",
				"mistakes": "Making it a child of the player means the camera spins with the character.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_camera2d.html"
			}
		"Camera3D":
			return {
				"what": "The 3D viewport camera. Only one is active at a time.",
				"required": "Nothing. Position it where the view should originate.",
				"recommended": "For third-person, put it inside a Node3D rig with orbit camera logic.",
				"paired": "camera_follow_3d, orbit_camera_3d, first_person_camera_3d.",
				"mistakes": "Forgetting to set current = true when there are multiple cameras.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_camera3d.html"
			}
		"CollisionShape2D":
			return {
				"what": "Defines the physical or detection shape of a 2D physics body or area.",
				"required": "A Shape2D resource (CircleShape2D, RectangleShape2D, CapsuleShape2D).",
				"recommended": "Match the shape to the sprite's visible bounds.",
				"paired": "Always a child of CharacterBody2D, StaticBody2D, or Area2D.",
				"mistakes": "Using a huge shape for small sprites — collisions happen far off the visible sprite.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_collisionshape2d.html"
			}
		"CollisionShape3D":
			return {
				"what": "Defines the physical or detection shape of a 3D physics body or area.",
				"required": "A Shape3D resource (BoxShape3D, CapsuleShape3D, SphereShape3D, etc.).",
				"recommended": "For characters, CapsuleShape3D is the standard — it slides over small bumps.",
				"paired": "CharacterBody3D, StaticBody3D, Area3D.",
				"mistakes": "Using BoxShape3D for a character causes snagging on floor edges.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_collisionshape3d.html"
			}
		"MeshInstance3D":
			return {
				"what": "Renders a 3D mesh. Attach a Mesh resource or a .glb / .obj file.",
				"required": "A Mesh resource (primitive like BoxMesh, or imported model).",
				"recommended": "StandardMaterial3D override for coloring.",
				"paired": "Typically a child of a CharacterBody3D or StaticBody3D.",
				"mistakes": "Forgetting that MeshInstance3D is visual only — it doesn't affect physics.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_meshinstance3d.html"
			}
		"Sprite2D":
			return {
				"what": "Draws a 2D texture. The standard visual for 2D sprites.",
				"required": "A Texture2D resource.",
				"recommended": "Adjust offset to center the sprite on its collision shape.",
				"paired": "Child of CharacterBody2D, Area2D, or StaticBody2D.",
				"mistakes": "Leaving offset at (0,0) means the sprite's top-left is at the node origin.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_sprite2d.html"
			}
		"CanvasLayer":
			return {
				"what": "A layer that renders above the game world. Used for HUD, menus, overlays.",
				"required": "Nothing — but add Control nodes as children for the UI.",
				"recommended": "For pause menus and game over screens, set process_mode = ALWAYS.",
				"paired": "pause_menu, health_bar_ui, main_menu, game_over_screen.",
				"mistakes": "Forgetting process_mode = ALWAYS means UI freezes when the game pauses.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_canvaslayer.html"
			}
		"Control":
			return {
				"what": "Base class for all UI elements. Buttons, labels, panels all inherit from Control.",
				"required": "None. Controls can be nested for layout.",
				"recommended": "Use anchors and containers (VBoxContainer, HBoxContainer) for resizable layouts.",
				"paired": "HUDs, menus, dialog boxes.",
				"mistakes": "Setting position manually instead of using anchors means the UI breaks on different screen sizes.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_control.html"
			}
		"Timer":
			return {
				"what": "Fires a timeout signal after a duration. Can loop.",
				"required": "Set wait_time in the Inspector.",
				"recommended": "autostart = true if it should run immediately on scene load.",
				"paired": "Spawners, cooldowns, autosave, periodic effects.",
				"mistakes": "Forgetting to start() a non-autostart Timer means it never fires.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_timer.html"
			}
		"AudioStreamPlayer":
			return {
				"what": "Plays non-positional audio (music, UI sounds).",
				"required": "An AudioStream resource.",
				"recommended": "Set the bus to Music or SFX instead of Master for volume control.",
				"paired": "play_music, play_sound, ui_click_sound.",
				"mistakes": "Reusing a single AudioStreamPlayer for overlapping sounds cuts off the previous one.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_audiostreamplayer.html"
			}
		"AudioStreamPlayer3D":
			return {
				"what": "Plays positional 3D audio. Volume attenuates with distance from the camera.",
				"required": "An AudioStream resource. Set max_distance and unit_size in the Inspector.",
				"recommended": "Attach to a source node (footstep emitter, gun, ambient sound).",
				"paired": "sound_effect_3d, footstep_sound.",
				"mistakes": "Default max_distance is small — increase for sounds meant to carry.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_audiostreamplayer3d.html"
			}
		"ProgressBar":
			return {
				"what": "A horizontal bar that fills from min_value to max_value. Used for health, XP, etc.",
				"required": "Set max_value in the Inspector.",
				"recommended": "Set show_percentage = false for cleaner health bars.",
				"paired": "health_bar_ui, xp_bar, cooldown_display.",
				"mistakes": "Leaving max_value at the default 100 when your health is 10 means the bar never fills.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_progressbar.html"
			}
		"Button":
			return {
				"what": "A clickable UI element. Emits a pressed signal.",
				"required": "None.",
				"recommended": "Set text in the Inspector. Connect the pressed signal.",
				"paired": "main_menu, pause_menu, options_menu.",
				"mistakes": "Connecting the same signal twice means the function runs twice per click.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_button.html"
			}
		"Label":
			return {
				"what": "Displays text in the UI.",
				"required": "None. Set the text property.",
				"recommended": "Enable autowrap_mode for multi-line text.",
				"paired": "score_display, countdown_timer_ui, dialog_box.",
				"mistakes": "Forgetting autowrap means long lines run off the edge of the screen.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_label.html"
			}
		"Node2D":
			return {
				"what": "A 2D transform node. Base for everything 2D that isn't a Control.",
				"required": "None.",
				"recommended": "Use as a container for related 2D children.",
				"paired": "Level containers, scene roots, spawners.",
				"mistakes": "Using Node2D when you need physics — use StaticBody2D or CharacterBody2D.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_node2d.html"
			}
		"Node3D":
			return {
				"what": "A 3D transform node. Base for everything 3D.",
				"required": "None.",
				"recommended": "Use as a container for related 3D children or a pivot point.",
				"paired": "Scene roots, camera rigs, spawners.",
				"mistakes": "Using Node3D when you need physics — use StaticBody3D or CharacterBody3D.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_node3d.html"
			}
		"NavigationRegion2D":
			return {
				"what": "Defines the walkable area for 2D navigation. Agents path within this region.",
				"required": "A NavigationPolygon resource. Bake it after drawing the walkable polygon.",
				"recommended": "Set the navigation layer to match the agent's layer.",
				"paired": "navigation_agent_2d.",
				"mistakes": "Forgetting to bake means the agent walks straight at walls.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_navigationregion2d.html"
			}
		"NavigationRegion3D":
			return {
				"what": "Defines the walkable area for 3D navigation.",
				"required": "Bake the navigation mesh in the toolbar.",
				"recommended": "Set agent radius and height to match your enemies.",
				"paired": "navigation_agent_3d, enemy_chaser_3d.",
				"mistakes": "Not baking after changing the level geometry means old paths still apply.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_navigationregion3d.html"
			}
		"TileMapLayer":
			return {
				"what": "Draws a grid of tiles. The modern tilemap node in Godot 4.3+.",
				"required": "A TileSet resource. Create it in the Inspector.",
				"recommended": "Enable physics layer on the TileSet so the player can stand on tiles.",
				"paired": "platformer levels, top-down RPG maps.",
				"mistakes": "Forgetting to add a physics layer means the player falls through the tiles.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_tilemaplayer.html"
			}
		"LineEdit":
			return {
				"what": "A single-line text input field.",
				"required": "None.",
				"recommended": "Connect text_submitted for Enter-key handling.",
				"paired": "search boxes, name entry, chat input.",
				"mistakes": "Not handling text_changed means the UI doesn't react as the user types.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_lineedit.html"
			}
		"AnimationPlayer":
			return {
				"what": "Plays Animation resources — property tweens, skeletal animation, sprite frames.",
				"required": "At least one Animation resource with keyframes.",
				"recommended": "Use autoplay for an idle animation that runs on scene load.",
				"paired": "Character animation, cutscenes, UI transitions.",
				"mistakes": "Forgetting to add the player to the scene tree means play() does nothing.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_animationplayer.html"
			}
		_:
			return {}


func _fallback_info(cls: String) -> Dictionary:
	return {
		"what": "A " + cls + " node. See the Godot docs for details.",
		"required": "",
		"recommended": "",
		"paired": "",
		"mistakes": "",
		"docs": "https://docs.godotengine.org/en/stable/classes/class_" + cls.to_lower() + ".html"
	}

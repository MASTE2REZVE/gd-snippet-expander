@tool
extends Node

var _editor_help = null


func set_editor_interface(ei: EditorInterface) -> void:
	# Godot 4 has no GDScript binding for the embedded docs. This hook
	# exists so the panel's call site doesn't break.
	_editor_help = null


func describe(node: Node) -> Dictionary:
	if node == null:
		return {"ok": false, "message": "No node selected."}
	var cls := node.get_class()
	var info := _lookup(cls)
	if info.is_empty():
		info = _auto_describe(cls)
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
		# =====================================================
		# Node (base)
		# =====================================================
		"Node":
			return {
				"what": "The base class of everything in Godot. A plain Node has no position, no drawing, no physics — it exists only as a place to hold children or hold a script.",
				"required": "None.",
				"recommended": "Use a plain Node as a scene root when the root doesn't need a 2D or 3D transform.",
				"paired": "Autoloads, managers, game state.",
				"mistakes": "Using Node when you need a position — that's Node2D or Node3D.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_node.html"
			}
		"Node2D":
			return {
				"what": "A 2D transform node. Has position, rotation, scale, z_index. Base for every visual 2D object that isn't UI.",
				"required": "None.",
				"recommended": "Use as a container for related 2D children, or as a scene root for a 2D level.",
				"paired": "Sprite2D, CharacterBody2D, CollisionShape2D.",
				"mistakes": "Using Node2D when you need physics — use StaticBody2D or CharacterBody2D instead.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_node2d.html"
			}
		"Node3D":
			return {
				"what": "A 3D transform node. Has position, rotation, scale in 3D space. Base for every 3D object.",
				"required": "None.",
				"recommended": "Use as a pivot, a container, or a scene root for a 3D level.",
				"paired": "MeshInstance3D, CharacterBody3D, Camera3D.",
				"mistakes": "Using Node3D when you need physics — use StaticBody3D or CharacterBody3D.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_node3d.html"
			}

		# =====================================================
		# Physics bodies — 2D
		# =====================================================
		"CharacterBody2D":
			return {
				"what": "A 2D physics body you move with code. Gravity, collision, and slide are handled by move_and_slide(). The standard body for players, enemies, and NPCs in 2D.",
				"required": "CollisionShape2D or CollisionPolygon2D — without it, the body has no shape and falls through everything.",
				"recommended": "Sprite2D or AnimatedSprite2D for visuals. A Camera2D child if this is the player.",
				"paired": "Move with move_and_slide(). Detect ground with is_on_floor(). Pair with camera_follow_2d, health_system.",
				"mistakes": "Setting position directly instead of velocity makes collision slide break. Always drive through velocity, then call move_and_slide().",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_characterbody2d.html"
			}
		"RigidBody2D":
			return {
				"what": "A 2D physics body fully controlled by the physics engine. Applies gravity, bounces off walls, reacts to forces. Use for crates, debris, ragdolls, projectiles that arc.",
				"required": "CollisionShape2D — defines the physical shape.",
				"recommended": "Set mass in the Inspector. For crate puzzles, enable contact_monitor.",
				"paired": "apply_central_impulse() to push it. apply_central_force() for continuous force.",
				"mistakes": "Setting position or velocity directly fights the physics engine and causes jitter. Use apply_impulse() instead.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_rigidbody2d.html"
			}
		"StaticBody2D":
			return {
				"what": "A 2D physics body that never moves. Walls, floors, platforms. Cheapest possible collider because the engine knows it will never change.",
				"required": "CollisionShape2D or CollisionPolygon2D.",
				"recommended": "Sprite2D or TileMapLayer for visuals that match the collision exactly.",
				"paired": "CharacterBody2D stands on top of this. Pair with one_way_platform for jump-through platforms.",
				"mistakes": "Making the visual bigger than the collision shape means parts of the wall look solid but the player passes through.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_staticbody2d.html"
			}
		"AnimatableBody2D":
			return {
				"what": "A 2D physics body that moves but is fully script-driven. Carries CharacterBody2D riders — the standard body for moving platforms.",
				"required": "CollisionShape2D.",
				"recommended": "Change its position in _physics_process, not _process, for smooth physics.",
				"paired": "moving_platform snippet, moving_platform_path, platformer_movement_2d.",
				"mistakes": "Using StaticBody2D for a moving platform makes riders fall off. Only AnimatableBody2D carries riders reliably.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_animatablebody2d.html"
			}
		"Area2D":
			return {
				"what": "A 2D region that detects overlaps with bodies and other areas. Never blocks movement. Triggers, pickups, hitboxes, detection zones.",
				"required": "CollisionShape2D — the detection region.",
				"recommended": "Connect body_entered and area_entered signals to react.",
				"paired": "coin_pickup, hitbox, hurtbox, detection_area, look_for_player.",
				"mistakes": "Expecting Area2D to block movement — it never does. That's StaticBody2D's job.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_area2d.html"
			}

		# =====================================================
		# Physics bodies — 3D
		# =====================================================
		"CharacterBody3D":
			return {
				"what": "A 3D physics body you move with code. Player, enemy, or NPC. Handles slopes and stairs through the built-in floor_max_angle and floor_snap_length.",
				"required": "CollisionShape3D — CapsuleShape3D is standard for characters.",
				"recommended": "MeshInstance3D or an imported .glb model for visuals. Camera3D for first or third person.",
				"paired": "character_movement_3d, first_person_movement, spring_arm_camera_3d, navigation_agent_3d.",
				"mistakes": "Using BoxShape3D for the collision shape causes the character to snag on floor edges. Use CapsuleShape3D.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_characterbody3d.html"
			}
		"RigidBody3D":
			return {
				"what": "A 3D physics body fully controlled by the physics engine. Barrels, debris, thrown objects, physics puzzles.",
				"required": "CollisionShape3D.",
				"recommended": "MeshInstance3D for visuals. Set mass in the Inspector.",
				"paired": "grenade_3d, apply_central_impulse() for pushes.",
				"mistakes": "Directly setting position on a RigidBody3D makes it teleport through walls and stutter. Use impulse or force.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_rigidbody3d.html"
			}
		"StaticBody3D":
			return {
				"what": "A 3D body that never moves. Walls, floors, platforms, terrain. Cheapest collider.",
				"required": "CollisionShape3D.",
				"recommended": "MeshInstance3D matching the collision shape. For complex terrain, use a GridMap or imported model with generated collision.",
				"paired": "ground_plane_3d blueprint, character_movement_3d stands on it.",
				"mistakes": "Mismatched visual and collision sizes. Also — a StaticBody3D with no CollisionShape3D silently does nothing.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_staticbody3d.html"
			}
		"AnimatableBody3D":
			return {
				"what": "A 3D physics body that moves but is script-driven. Carries CharacterBody3D riders. Moving platforms in 3D.",
				"required": "CollisionShape3D.",
				"recommended": "Change position in _physics_process. Turn on sync_to_physics for stable rider carrying.",
				"paired": "moving_platform_3d, elevator platforms.",
				"mistakes": "Using StaticBody3D for a moving platform means riders fall off.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_animatablebody3d.html"
			}
		"Area3D":
			return {
				"what": "A 3D region that detects overlaps with bodies and areas. Triggers, gravity zones, water volumes, interaction prompts.",
				"required": "CollisionShape3D.",
				"recommended": "Connect body_entered and area_exited for state tracking.",
				"paired": "gravity_zone_3d, water_zone_3d, ladder_3d, raycast_interact_3d.",
				"mistakes": "Expecting Area3D to block movement — it never does. Use StaticBody3D for that.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_area3d.html"
			}

		# =====================================================
		# Collision shapes
		# =====================================================
		"CollisionShape2D":
			return {
				"what": "Defines the physical or detection shape of a 2D body or area. The actual collision is this shape, not the body itself.",
				"required": "A Shape2D resource — CircleShape2D, RectangleShape2D, or CapsuleShape2D. Without a shape, the node does nothing.",
				"recommended": "Match the shape to the sprite's visible bounds. Circle for round characters, rectangle for square ones, capsule for platformer characters.",
				"paired": "Always a child of CharacterBody2D, StaticBody2D, RigidBody2D, or Area2D.",
				"mistakes": "Using a huge shape for small sprites makes collisions happen far off the visual. Also — One Way Collision is on this node, not the parent body.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_collisionshape2d.html"
			}
		"CollisionPolygon2D":
			return {
				"what": "A polygon-based collision shape for 2D. More flexible than CollisionShape2D for irregular shapes and slopes.",
				"required": "A polygon drawn in the editor. Set build_mode to Solids or Segments.",
				"recommended": "For complex shapes, use CollisionShape2D with a ConvexPolygonShape2D — it's faster to collide against.",
				"paired": "Slopes, custom terrain, character hulls.",
				"mistakes": "Concave polygons silently fail. Break them into multiple convex pieces or use ConvexPolygonShape2D.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_collisionpolygon2d.html"
			}
		"CollisionShape3D":
			return {
				"what": "Defines the physical or detection shape of a 3D body or area.",
				"required": "A Shape3D resource — BoxShape3D, CapsuleShape3D, SphereShape3D, CylinderShape3D, or ConcavePolygonShape3D.",
				"recommended": "For characters, CapsuleShape3D is the standard. For terrain, ConcavePolygonShape3D (from a mesh with create_trimesh_collision).",
				"paired": "Always a child of CharacterBody3D, StaticBody3D, RigidBody3D, or Area3D.",
				"mistakes": "Using BoxShape3D for a character causes snagging on stairs and slopes. CapsuleShape3D slides over them.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_collisionshape3d.html"
			}

		# =====================================================
		# Visuals — 2D
		# =====================================================
		"Sprite2D":
			return {
				"what": "Draws a single texture in 2D. The standard visual for non-animated 2D objects.",
				"required": "A Texture2D resource.",
				"recommended": "Set centered = true (default) or use an offset to anchor at the feet for characters. Set flip_h to flip facing.",
				"paired": "Child of CharacterBody2D, StaticBody2D, or Area2D. Combine with collision shape matching the sprite bounds.",
				"mistakes": "Leaving centered = false with a nonzero offset makes position math confusing. Use centered = true unless you have a reason.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_sprite2d.html"
			}
		"AnimatedSprite2D":
			return {
				"what": "Plays a SpriteFrames resource — a collection of animations with frames. The standard 2D character animation node.",
				"required": "A SpriteFrames resource with at least one animation. Create it in the Inspector.",
				"recommended": "Name animations idle, walk, run, jump, fall, hurt. Drive them from velocity and floor state.",
				"paired": "animated_sprite_state, sprite_flip_direction, animated_sprite_state_8dir.",
				"mistakes": "Naming animations inconsistently (Idle vs idle) breaks code that plays them by name.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_animatedsprite2d.html"
			}
		"Line2D":
			return {
				"what": "Draws a connected series of points as a line. Wires, ropes, laser sights, trails.",
				"required": "At least 2 points in the points array.",
				"recommended": "Set width and a default_color. For a textured line, assign a gradient or texture.",
				"paired": "Rope physics, laser pointer, drawing tools.",
				"mistakes": "Setting very large point arrays and updating them every frame is slow — for trail-style effects use a particle system instead.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_line2d.html"
			}
		"Polygon2D":
			return {
				"what": "Draws a filled 2D polygon. Terrain pieces, custom shapes, UI backgrounds.",
				"required": "At least 3 points in the polygon array.",
				"recommended": "Give it a material or vertex_colors for gradients. Enable antialiasing for smooth edges.",
				"paired": "Level geometry, custom UI panels.",
				"mistakes": "Concave polygons need a triangulation hint or they render wrong. Break complex shapes into multiple Polygon2D nodes.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_polygon2d.html"
			}
		"NinePatchRect":
			return {
				"what": "A UI panel that stretches a texture while keeping its corners at their original size. Dialog boxes, buttons, frames.",
				"required": "A Texture2D with distinct corners. Set patch_margin on each side.",
				"recommended": "Make the source texture a 48x48 or 64x64 nine-slice image. Set axis_stretch_horizontal / vertical to Tile for repeating patterns.",
				"paired": "Dialog boxes, HUD frames, custom buttons.",
				"mistakes": "Using a plain panel texture instead of a nine-slice causes the border to stretch ugly when resized.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_ninepatchrect.html"
			}
		"TileMapLayer":
			return {
				"what": "A single layer of tiles drawn on a grid. The modern tilemap node in Godot 4.3+. Replaces the older multi-layer TileMap.",
				"required": "A TileSet resource — contains the tilesheet, autotile rules, physics layers, and occlusion.",
				"recommended": "Use one TileMapLayer per layer: Background, Ground, Decor, Foreground. Share the same TileSet across layers.",
				"paired": "tilemap_autotile, tilemap_collision, tilemap_paint_programmatic, tilemap_terrain_connect.",
				"mistakes": "Forgetting to add a physics layer to the TileSet means the player falls through the tiles.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_tilemaplayer.html"
			}
		"TileMap":
			return {
				"what": "The older multi-layer tilemap node. Still works in Godot 4 but TileMapLayer is the recommended replacement.",
				"required": "A TileSet resource.",
				"recommended": "Migrate to TileMapLayer (one node per layer) for clearer scenes and better tooling.",
				"paired": "Older 2D projects.",
				"mistakes": "Using TileMap in new projects is discouraged — the TileMapLayer API is cleaner and gets more editor support.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_tilemap.html"
			}

		# =====================================================
		# Cameras
		# =====================================================
		"Camera2D":
			return {
				"what": "The 2D viewport camera. Only one Camera2D is active at a time (the one with current = true).",
				"required": "None — but you usually want a script that follows a target. See camera_follow_2d.",
				"recommended": "Set limit_left, limit_top, limit_right, limit_bottom to keep the view within level bounds. Set position_smoothing_enabled for smooth follow without a script.",
				"paired": "camera_follow_2d, camera_smooth_follow_2d, camera_shake, camera_deadzone, camera_limits_2d.",
				"mistakes": "Making the camera a child of the player rotates it with the character. Keep it at the scene root.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_camera2d.html"
			}
		"Camera3D":
			return {
				"what": "The 3D viewport camera. Only one is active at a time.",
				"required": "Nothing. Position it in the world where the view should originate.",
				"recommended": "For third-person, put it inside a SpringArm3D node that handles collision. Set fov to 70-90 for gameplay, 40-60 for cinematic.",
				"paired": "spring_arm_camera_3d, camera_follow_3d, orbit_camera_3d, camera_shake_3d, shoulder_swap_3d.",
				"mistakes": "Forgetting to set current = true when there are multiple cameras. Also — a Camera3D as a direct child of a CharacterBody3D inherits the player's rotation.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_camera3d.html"
			}

		# =====================================================
		# Visuals — 3D
		# =====================================================
		"MeshInstance3D":
			return {
				"what": "Renders a 3D mesh. Attach a Mesh resource (primitive like BoxMesh or an imported .glb / .obj model).",
				"required": "A Mesh resource.",
				"recommended": "Set material_override for a quick color. For per-surface materials on models with multiple materials, use set_surface_override_material(index, mat).",
				"paired": "Always a child of a CharacterBody3D or StaticBody3D. Pair with mesh_material_3d, mesh_swap_3d, mesh_fade_3d.",
				"mistakes": "Forgetting that MeshInstance3D is visual-only — it doesn't block movement or cast shadows without a matching CollisionShape3D.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_meshinstance3d.html"
			}
		"MultiMeshInstance3D":
			return {
				"what": "Renders thousands of copies of the same mesh in one draw call. Grass, trees, rocks, debris — anything repeated many times.",
				"required": "A MultiMesh resource with a mesh set and instance_count > 0.",
				"recommended": "Set the transforms in code (set_instance_transform). For per-instance color, set the MultiMesh's color_format.",
				"paired": "multimesh_instancing_3d.",
				"mistakes": "Creating hundreds of individual MeshInstance3D nodes instead of a MultiMesh tanks performance. Any repeat count over ~50 should use MultiMesh.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_multimeshinstance3d.html"
			}
		"CSGBox3D":
			return {
				"what": "A constructive solid geometry box. CSG nodes are for rapid level prototyping — they can be combined with other CSG nodes to subtract and merge shapes.",
				"required": "Nothing. Set size in the Inspector.",
				"recommended": "Combine multiple CSG nodes as children to build complex shapes (subtract a smaller box from a larger one to make a doorway).",
				"paired": "Level prototyping. Convert to a MeshInstance3D with a static body for the final version.",
				"mistakes": "Leaving CSG in the final build — it's expensive at runtime because the union/subtract is recomputed. Only use for prototyping.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_csgbox3d.html"
			}
		"CSGSphere3D":
			return {
				"what": "A CSG sphere primitive. Same rules as CSGBox3D — prototyping tool.",
				"required": "Nothing.",
				"recommended": "Use as a subtractor to carve round holes in other CSG shapes.",
				"paired": "Level prototyping.",
				"mistakes": "Same as CSGBox3D — expensive at runtime. Bake to a mesh before shipping.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_csgsphere3d.html"
			}

		# =====================================================
		# Lights — 2D
		# =====================================================
		"PointLight2D":
			return {
				"what": "A radial 2D light. Lights in all directions from its position. Torches, lamps, glows, ambient light.",
				"required": "A texture assigned. The light's size is controlled by texture_scale × the texture's pixel size.",
				"recommended": "Assign a radial gradient texture for smooth falloff. Set blend_mode to Add for a glowing effect.",
				"paired": "canvas_modulate (to darken the scene first), light_occluder_2d (for shadows), flickering_light.",
				"mistakes": "Without a CanvasModulate with a dark color, the light has almost no visible effect.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_pointlight2d.html"
			}
		"DirectionalLight2D":
			return {
				"what": "A 2D light with parallel rays (like a sun in 2D). Every shadow in the scene aligns to this light's direction.",
				"required": "A texture assigned. Set max_distance for attenuation.",
				"recommended": "Set height for a shadow-casting effect — higher values push shadows further from objects.",
				"paired": "canvas_modulate, day_night_2d.",
				"mistakes": "Using this instead of CanvasModulate to darken a scene — DirectionalLight2D adds light, it doesn't dim.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_directionallight2d.html"
			}
		"LightOccluder2D":
			return {
				"what": "Blocks 2D light and casts shadows. Walls, trees, rocks that should stop PointLight2D.",
				"required": "An OccluderPolygon2D resource — draw the polygon in the 2D viewport.",
				"recommended": "Enable Debug → Visible Light Occluders to verify the polygon. Close the polygon (Closed = true).",
				"paired": "point_light_2d, canvas_modulate.",
				"mistakes": "Forgetting to close the polygon means no shadow. Draw shapes counter-clockwise to avoid self-intersection artifacts.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_lightoccluder2d.html"
			}
		"CanvasModulate":
			return {
				"what": "Tints the entire 2D scene. The starting point for 2D lighting — darken the world so PointLight2D has something to light.",
				"required": "None. Set the color property.",
				"recommended": "One per scene. Use a dark blue-purple like Color(0.15, 0.15, 0.35) for night.",
				"paired": "point_light_2d, day_night_2d, canvas_modulate (script).",
				"mistakes": "Multiple CanvasModulate nodes fight each other. Only one is active.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_canvasmodulate.html"
			}

		# =====================================================
		# Lights — 3D
		# =====================================================
		"DirectionalLight3D":
			return {
				"what": "A 3D sun. Parallel rays from infinitely far away. Every outdoor 3D scene needs one.",
				"required": "Nothing. Rotate it to set the sun angle.",
				"recommended": "Enable shadows. Directional Shadow Mode: PSSM 4 Splits for outdoor scenes, PSSM 2 Splits for indoor.",
				"paired": "world_environment_3d, day_night_3d, shadow_tuning_3d, fog_3d.",
				"mistakes": "Sun rotation of 0,0,0 points straight down — flat and unnatural. Use a 45-degree angle for interesting shadows.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_directionallight3d.html"
			}
		"OmniLight3D":
			return {
				"what": "A 3D point light. Lamps, bulbs, torches, glowing objects.",
				"required": "Nothing.",
				"recommended": "Set omni_range to match the area you want lit. Enable shadows sparingly — shadows are expensive per light.",
				"paired": "omni_light_3d, flickering_light, light_group_3d.",
				"mistakes": "Enabling shadows on many omni lights destroys performance. Keep shadow-casting lights under 3-5.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_omnilight3d.html"
			}
		"SpotLight3D":
			return {
				"what": "A cone-shaped 3D light. Flashlights, headlights, stage spotlights.",
				"required": "Nothing.",
				"recommended": "Set spot_range and spot_angle. For a flashlight, parent it to the player and aim it forward.",
				"paired": "spot_light_3d, first_person_camera_3d.",
				"mistakes": "Very narrow cones (under 5 degrees) look artificial. Wide cones (over 60) lose the spotlight feel.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_spotlight3d.html"
			}
		"ReflectionProbe":
			return {
				"what": "Captures the surroundings and reflects them on shiny surfaces. Essential for metallic materials to look right.",
				"required": "Nothing — the probe captures automatically.",
				"recommended": "Set the size to cover the room or area. Use Update Mode Once for static scenes (free at runtime).",
				"paired": "reflection_probe_3d, mesh_material_3d.",
				"mistakes": "Multiple dynamic probes in different rooms is very expensive. Only use dynamic probes where the player currently is.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_reflectionprobe.html"
			}
		"LightmapGI":
			return {
				"what": "Bakes static lighting into textures. Realistic global illumination with zero runtime cost.",
				"required": "Static geometry in the scene. Meshes need GI Mode set and UV2 layers.",
				"recommended": "Configure quality in the Inspector, then click 'Bake Lightmaps' in the toolbar. Bake whenever geometry or lighting changes.",
				"paired": "lightmap_gi_3d.",
				"mistakes": "Forgetting to set GI Mode on meshes means they don't contribute to or receive the bake.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_lightmapgi.html"
			}
		"WorldEnvironment":
			return {
				"what": "Sets the sky, ambient light, fog, and post-processing for a 3D scene. The 3D equivalent of CanvasModulate.",
				"required": "An Environment resource assigned in the Inspector.",
				"recommended": "Configure the Environment: Background Mode = Sky, add a ProceduralSkyMaterial, set Tonemap = Filmic, enable Glow for bloom.",
				"paired": "world_environment_3d, fog_3d, volumetric_fog_3d, day_night_3d.",
				"mistakes": "Multiple WorldEnvironment nodes fight each other. Only one per scene. Also — forgetting the Environment slot leaves the scene pitch black at night.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_worldenvironment.html"
			}

		# =====================================================
		# Animation
		# =====================================================
		"AnimationPlayer":
			return {
				"what": "Plays keyframed animations. Property tweens, sprite frame changes, skeletal motion, method calls — all driven from one timeline.",
				"required": "At least one Animation resource with keyframes. Create it in the AnimationPlayer panel at the bottom.",
				"recommended": "Name animations consistently (idle, walk, run, attack). Use Call Method Tracks to trigger game logic at exact frames.",
				"paired": "animation_play, animation_event_3d, animated_sprite_state.",
				"mistakes": "Forgetting to add the AnimationPlayer to the tree means play() does nothing. Also — Call Method Tracks calling methods with the wrong argument count fail silently.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_animationplayer.html"
			}
		"AnimationTree":
			return {
				"what": "A node-driven animation state machine. Blend trees, state machines, blend spaces, and one-shots.",
				"required": "A tree_root AnimationNode — usually an AnimationNodeStateMachine or AnimationNodeBlendTree. Assign an AnimationPlayer.",
				"recommended": "Set active = true in _ready. Use travel() to switch states, set() to drive blend parameters.",
				"paired": "animation_tree_setup, animation_tree_state, animation_blend_2d, animation_state_machine_2d, character_animation_3d.",
				"mistakes": "Forgetting to assign the Anim Player property on the AnimationTree means nothing plays. Also — AnimationTree.active must be true.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_animationtree.html"
			}
		"Tween":
			return {
				"what": "A lightweight interpolator. Property tweens, chains, parallel sequences, callbacks — created in code with create_tween().",
				"required": "None — create_tween() builds one.",
				"recommended": "Chain multiple tween_property() calls for sequences. Use set_parallel(true) for simultaneous tweens. Tweens auto-free when done.",
				"paired": "tween_move, tween_fade, tween_sequence, tween_parallel, tween_callback.",
				"mistakes": "Starting a second tween on the same property while the first runs causes both to fight. Kill the old one or await its finished signal.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_tween.html"
			}

		# =====================================================
		# Audio
		# =====================================================
		"AudioStreamPlayer":
			return {
				"what": "Plays non-positional audio — music, UI sounds, narration. Volume and stereo balance are fixed regardless of position.",
				"required": "An AudioStream resource assigned.",
				"recommended": "Assign the bus to 'Music' or 'SFX' (created in the Audio panel) instead of Master, so volume control per category works.",
				"paired": "play_sound, play_music, audio_fade, options_menu.",
				"mistakes": "Reusing one player for overlapping sounds cuts off the previous. Add a second player or use a pool for varied SFX.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_audiostreamplayer.html"
			}
		"AudioStreamPlayer2D":
			return {
				"what": "Plays audio positioned in 2D space. Volume and panning change based on the camera's position.",
				"required": "An AudioStream resource. Set max_distance and attenuation in the Inspector.",
				"recommended": "Attach to the source (footstep emitter, gun, ambient zone). For global music, use AudioStreamPlayer instead.",
				"paired": "play_sound, sound_effect_3d, footstep_sound.",
				"mistakes": "Default max_distance is small — increase for sounds meant to carry across a room.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_audiostreamplayer2d.html"
			}
		"AudioStreamPlayer3D":
			return {
				"what": "Plays audio positioned in 3D space. Attenuates with distance from the camera.",
				"required": "An AudioStream resource. Set max_distance and unit_size in the Inspector.",
				"recommended": "Adjust attenuation_model for the desired falloff. Attach to the source node (footstep emitter, gun, ambient sound).",
				"paired": "sound_effect_3d, footstep_sound.",
				"mistakes": "Default max_distance is only 20 meters. Increase for gunshots or ambient sounds meant to carry further.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_audiostreamplayer3d.html"
			}

		# =====================================================
		# Particles
		# =====================================================
		"GPUParticles2D":
			return {
				"what": "GPU-accelerated 2D particles. Handles thousands of particles in a single draw call.",
				"required": "A ParticleProcessMaterial (process_material) and a draw_pass_1 mesh or texture.",
				"recommended": "Use for explosions, trails, ambient effects with many particles. Set amount, lifetime, one_shot as needed.",
				"paired": "particle_explosion, particle_trail, particle_dust.",
				"mistakes": "For very few particles, GPUParticles2D has more overhead than CPUParticles2D. Use CPU for tiny effects.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_gpuparticles2d.html"
			}
		"CPUParticles2D":
			return {
				"what": "CPU-driven 2D particles. Simpler than GPU particles, works on any hardware including older devices.",
				"required": "None — all properties (amount, lifetime, direction, color) are on the node.",
				"recommended": "Use for small effects (under ~100 particles): dust puffs, sparkles, hit bursts. Simplest API.",
				"paired": "particle_dust, particle_sparkle, particle_explosion.",
				"mistakes": "Very high particle counts (500+) tank CPU. Switch to GPUParticles2D above that.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_cpuparticles2d.html"
			}
		"GPUParticles3D":
			return {
				"what": "GPU-accelerated 3D particles. The standard for 3D explosions, trails, weather, and ambient effects.",
				"required": "A ParticleProcessMaterial and a draw_pass_1 mesh.",
				"recommended": "Use for anything with more than ~20 particles. Set one_shot = true for one-shot effects, then queue_free after lifetime.",
				"paired": "particle_explosion_3d, particle_trail_3d, particle_smoke_3d, particle_fire_3d.",
				"mistakes": "Forgetting to set draw_pass_1 means nothing renders, even though the particle system is emitting.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_gpuparticles3d.html"
			}
		"CPUParticles3D":
			return {
				"what": "CPU-driven 3D particles. Same as GPUParticles3D but simpler, and works on any hardware.",
				"required": "At least a draw_pass_1 mesh.",
				"recommended": "Use for small effects with limited particle counts. For anything above ~100 particles, switch to GPU.",
				"paired": "particle_dust_3d.",
				"mistakes": "High particle counts (500+) on CPU tank performance. GPU version is required at that scale.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_cpuparticles3d.html"
			}

		# =====================================================
		# UI — Controls
		# =====================================================
		"Control":
			return {
				"what": "Base class for all UI elements. Every Button, Label, Panel, and Container inherits from Control.",
				"required": "None.",
				"recommended": "Use anchors (Layout → Anchors Preset) so the UI scales with the screen. Use Containers for automatic layout.",
				"paired": "Parent of every UI element. Set mouse_filter to Ignore to pass clicks through.",
				"mistakes": "Setting position and size manually instead of using anchors means the UI breaks at different resolutions.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_control.html"
			}
		"CanvasLayer":
			return {
				"what": "A layer that renders above the game world. Every HUD, menu, and overlay lives inside one.",
				"required": "Add Control nodes as children for actual UI.",
				"recommended": "Set layer to 10+ for game HUD, 100+ for menus and overlays that should draw on top of everything.",
				"paired": "pause_menu, health_bar_ui, main_menu, game_over_screen, loading_screen.",
				"mistakes": "Forgetting process_mode = ALWAYS on menu CanvasLayers means the menu freezes when the game pauses.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_canvaslayer.html"
			}
		"Label":
			return {
				"what": "Displays text in the UI.",
				"required": "None. Set the text property.",
				"recommended": "Enable autowrap_mode for multi-line text. Set horizontal_alignment / vertical_alignment to position text within the box.",
				"paired": "score_display, countdown_timer_ui, dialog_box.",
				"mistakes": "Forgetting autowrap on long text means it runs off the edge of the screen instead of wrapping.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_label.html"
			}
		"RichTextLabel":
			return {
				"what": "A Label with BBCode support. Bold, italics, colors, inline images, custom fonts.",
				"required": "None. Enable bbcode_enabled for BBCode formatting.",
				"recommended": "Set fit_content = true to auto-size to the text. Use [b]bold[/b], [color=red]text[/color], [img]path[/img] tags.",
				"paired": "dialogue_ui_advanced, tooltips, rich text HUD elements.",
				"mistakes": "Forgetting bbcode_enabled means tags render as plain text instead of formatting.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_richtextlabel.html"
			}
		"Button":
			return {
				"what": "A clickable UI button. Emits a pressed signal on click or Space/Enter when focused.",
				"required": "None.",
				"recommended": "Set text in the Inspector. Connect the pressed signal to your handler function.",
				"paired": "main_menu, pause_menu, options_menu, game_over_screen.",
				"mistakes": "Connecting the same signal twice runs the handler twice per click. Check is_connected before connecting.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_button.html"
			}
		"TextureButton":
			return {
				"what": "A button that uses textures instead of the theme. For custom-styled buttons with different states.",
				"required": "At least texture_normal assigned.",
				"recommended": "Assign texture_hover, texture_pressed, texture_disabled for full state coverage.",
				"paired": "Custom UI, image-based buttons.",
				"mistakes": "Forgetting texture_pressed means the button doesn't visually change when clicked.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_texturebutton.html"
			}
		"LineEdit":
			return {
				"what": "A single-line text input field.",
				"required": "None.",
				"recommended": "Connect text_submitted for Enter-key handling. Set placeholder_text for a hint.",
				"paired": "search boxes, name entry, chat input.",
				"mistakes": "Not handling text_changed means the UI doesn't react as the user types.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_lineedit.html"
			}
		"TextEdit":
			return {
				"what": "A multi-line text input / display area.",
				"required": "None.",
				"recommended": "Set editable = false for read-only displays. Enable wrap_mode for automatic line wrapping.",
				"paired": "Log panels, code viewers, notes fields.",
				"mistakes": "Using a TextEdit for simple one-line display wastes memory — use a Label instead.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_textedit.html"
			}
		"CodeEdit":
			return {
				"what": "A TextEdit with code-editing features: line numbers, syntax highlighting, code folding, indent guides.",
				"required": "None. Assign a CodeHighlighter for syntax coloring.",
				"recommended": "Set editable = false for read-only display. Assign a syntax_highlighter for colored code.",
				"paired": "The plugin's own preview tabs, any in-game code viewer.",
				"mistakes": "Using a plain TextEdit for code loses line numbers and highlighting. Always use CodeEdit for code.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_codeedit.html"
			}
		"ProgressBar":
			return {
				"what": "A bar that fills from min_value to max_value. Health bars, XP bars, cooldowns, loading progress.",
				"required": "Set max_value in the Inspector.",
				"recommended": "Set show_percentage = false for health bars. For a two-tone bar with a damage lag effect, layer two ProgressBars or a ColorRect behind one.",
				"paired": "health_bar, health_bar_ui, boss_health_bar.",
				"mistakes": "Leaving max_value at the default 100 when your health is 10 makes the bar look stuck.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_progressbar.html"
			}
		"HSlider":
			return {
				"what": "A horizontal slider for numeric input. Volume, sensitivity, brightness.",
				"required": "Set min_value, max_value, step in the Inspector.",
				"recommended": "Connect value_changed for live updates. Set step to 0.01 for smooth sliders, 1 for integer values.",
				"paired": "options_menu, audio_bus_volume.",
				"mistakes": "Forgetting to connect value_changed means the slider moves but nothing changes.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_hslider.html"
			}
		"PanelContainer":
			return {
				"what": "A Panel that wraps its single child with a themed background and padding.",
				"required": "Exactly one child Control. More than one child causes layout errors.",
				"recommended": "Put a VBoxContainer or HBoxContainer inside to lay out multiple children.",
				"paired": "Dialog boxes, HUD frames, tooltips.",
				"mistakes": "Adding multiple children directly — PanelContainer only supports one. Wrap them in a container.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_panelcontainer.html"
			}
		"VBoxContainer":
			return {
				"what": "Stacks children vertically with automatic spacing. The most common UI layout container.",
				"required": "Any number of Control children.",
				"recommended": "Set theme_override_constants/separation in the Inspector to control spacing.",
				"paired": "Menus, dialog boxes, option lists, any vertical layout.",
				"mistakes": "Putting non-Control children (like Node3D) inside — they won't be laid out.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_vboxcontainer.html"
			}
		"HBoxContainer":
			return {
				"what": "Stacks children horizontally with automatic spacing.",
				"required": "Any number of Control children.",
				"recommended": "Set size_flags_horizontal = Expand Fill on children you want to take up extra space.",
				"paired": "Toolbars, header rows, chip rows.",
				"mistakes": "Children with fixed size_flags stay at their minimum size instead of stretching to fill.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_hboxcontainer.html"
			}
		"GridContainer":
			return {
				"what": "Lays children out in a fixed number of columns. Inventory slots, ability grids, level select menus.",
				"required": "Set columns in the Inspector.",
				"recommended": "Children wrap to the next row automatically when the column count is reached.",
				"paired": "inventory_ui_grid, ability bars, key rebinding menus.",
				"mistakes": "Forgetting to set columns leaves everything in one column. Default is 1.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_gridcontainer.html"
			}
		"ScrollContainer":
			return {
				"what": "Wraps a single child and adds scrolling. For lists that might overflow.",
				"required": "Exactly one child Control.",
				"recommended": "Put a VBoxContainer inside. Enable horizontal_scroll_mode or vertical_scroll_mode as needed.",
				"paired": "Quest logs, inventory lists, settings menus.",
				"mistakes": "Putting multiple children directly — ScrollContainer only takes one. Wrap in a VBoxContainer.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_scrollcontainer.html"
			}
		"TabContainer":
			return {
				"what": "A container that shows one child at a time, with tab headers. The active tab is set by current_tab.",
				"required": "One or more Control children. Each becomes a tab named after the child's node name.",
				"recommended": "Rename child nodes to control the tab labels — the node name is the tab title.",
				"paired": "Options menus, inventory tabs, shop tabs.",
				"mistakes": "Renaming a child node changes its tab title at runtime. If you need a different display label, override set_tab_title().",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_tabcontainer.html"
			}
		"ItemList":
			return {
				"what": "A scrollable list of selectable items. Emits item_selected when an item is clicked.",
				"required": "Add items with add_item() in code, or pre-fill in the Inspector.",
				"recommended": "Connect item_selected to react to clicks. Use select_mode for single or multiple selection.",
				"paired": "The plugin's own multi-result dropdown, any list UI.",
				"mistakes": "Clearing with clear() removes all items — you must re-add them if you rebuild.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_itemlist.html"
			}
		"Tree":
			return {
				"what": "A hierarchical list with collapsible branches. File browsers, category trees, scene trees.",
				"required": "Build items with create_item() in code, or pre-fill in the Inspector.",
				"recommended": "Set columns for multi-column layouts. Set hide_root = true to hide the top-level header.",
				"paired": "map_browser, category browsers, folder views.",
				"mistakes": "Forgetting to set selectable = false on group nodes lets users select them, which is usually unwanted.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_tree.html"
			}
		"TextureRect":
			return {
				"what": "Displays a texture with control over how it stretches. UI images, icons, portraits.",
				"required": "A Texture2D assigned.",
				"recommended": "Set stretch_mode based on your needs: Scale fits the box, Keep Aspect preserves proportions, Tile repeats.",
				"paired": "Icons, portraits, item slots, HUD backgrounds.",
				"mistakes": "Forgetting to set expand_mode means the texture stays at its native size, ignoring the container.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_texturerect.html"
			}
		"ColorRect":
			return {
				"what": "A solid colored rectangle. Fades, overlays, backgrounds, dividers.",
				"required": "None. Set color in the Inspector.",
				"recommended": "Set anchors_preset = Full Rect for a full-screen overlay.",
				"paired": "fade_in_ui, pause_menu overlays, screen tints, black bars.",
				"mistakes": "Forgetting to set anchors makes the rect have zero size and be invisible.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_colorrect.html"
			}

		# =====================================================
		# Utility — markers, timers, helpers
		# =====================================================
		"Timer":
			return {
				"what": "Fires a timeout signal after wait_time seconds. Can loop, can autostart, can be paused.",
				"required": "Set wait_time in the Inspector.",
				"recommended": "Enable autostart = true if it should run on scene load. Set one_shot = false for repeating timers.",
				"paired": "Spawners, cooldowns, autosave, periodic effects.",
				"mistakes": "Forgetting to call start() on a non-autostart Timer means it never fires.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_timer.html"
			}
		"Marker2D":
			return {
				"what": "A 2D position marker with no visual at runtime. Spawn points, patrol waypoints, aim targets.",
				"required": "None.",
				"recommended": "The gizmo is visible in the editor but not at runtime. Use global_position to read the location.",
				"paired": "checkpoint_2d, patrol_waypoints, spawn points.",
				"mistakes": "Using a Marker2D when you need to actually draw something — it's invisible at runtime.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_marker2d.html"
			}
		"Marker3D":
			return {
				"what": "A 3D position marker with no visual at runtime. Muzzles, spawn points, camera targets, patrol waypoints.",
				"required": "None.",
				"recommended": "The gizmo is visible in the editor only. Use global_position to read the location.",
				"paired": "enemy_spawner_3d, patrol_waypoints_3d, muzzle flash positions, camera targets.",
				"mistakes": "Expecting this to render something at runtime — it's invisible.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_marker3d.html"
			}
		"RayCast2D":
			return {
				"what": "A persistent 2D ray. Continuously tests for collisions from its origin along its target_position.",
				"required": "Set target_position (in local coordinates) to define the ray.",
				"recommended": "Enable enabled = true. Read is_colliding() and get_collider() in _physics_process.",
				"paired": "Wall detection, ledge detection, line-of-sight.",
				"mistakes": "Forgetting enabled = true means the ray never runs. Very long rays on many nodes get expensive — for occasional checks use raycast_2d instead.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_raycast2d.html"
			}
		"RayCast3D":
			return {
				"what": "A persistent 3D ray. Line of sight, aim direction, ground detection.",
				"required": "Set target_position (in local coordinates) to define the ray.",
				"recommended": "Enable enabled = true. Set collision_mask to only test the layers you care about.",
				"paired": "raycast_interact_3d, first_person_movement ground check.",
				"mistakes": "Very long rays on many nodes get expensive. For occasional queries, use raycast_3d instead.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_raycast3d.html"
			}
		"ShapeCast3D":
			return {
				"what": "Sweeps a 3D shape along a direction and reports overlaps. Better than RayCast3D for characters with volume.",
				"required": "A shape resource and target_position set.",
				"recommended": "Set shape and max_results. Read is_colliding() and get_collision_count().",
				"paired": "Sphere casts for attack hitboxes, character body checks.",
				"mistakes": "Forgetting to assign a shape — nothing happens with a null shape.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_shapecast3d.html"
			}
		"SpringArm3D":
			return {
				"what": "A 3D arm that casts a ray between itself and its tip. Shortens when it hits a wall. Third-person camera rigs.",
				"required": "Nothing. Add a Camera3D as a child at the tip.",
				"recommended": "Set spring_length to the ideal distance. Set collision_mask so it collides with level geometry.",
				"paired": "spring_arm_camera_3d, spring_arm_camera_rig blueprint.",
				"mistakes": "Putting the Camera3D at the SpringArm3D's origin (0,0,0) instead of at the tip — the arm shortens, but the camera doesn't move out of the wall.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_springarm3d.html"
			}
		"RemoteTransform2D":
			return {
				"what": "Pushes this node's transform to another Node2D elsewhere in the scene. The remote node follows this one.",
				"required": "Set remote_path to the target Node2D.",
				"recommended": "Enable update_position, update_rotation, update_scale per what you want to sync.",
				"paired": "Camera targets, weapon attachment points, follower objects.",
				"mistakes": "Forgetting to set remote_path means nothing follows. Also — the remote node must be in the same scene tree.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_remotetransform2d.html"
			}
		"RemoteTransform3D":
			return {
				"what": "Pushes this node's 3D transform to another Node3D. Attachment points, camera targets, follow rigs.",
				"required": "Set remote_path to the target Node3D.",
				"recommended": "Enable use_global_coordinates for world-space sync.",
				"paired": "Third-person camera targets, weapon holsters, mounting rigs.",
				"mistakes": "Syncing scale when you don't want to scale the target. Enable only the components you need.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_remotetransform3d.html"
			}

		# =====================================================
		# Navigation
		# =====================================================
		"NavigationRegion2D":
			return {
				"what": "Defines the walkable area for 2D navigation. Agents path within this region.",
				"required": "A NavigationPolygon resource — draw the walkable polygon in the editor, then bake.",
				"recommended": "The polygon should trace the outside edge of the walkable area. Bake after drawing.",
				"paired": "navigation_agent_2d, grid_movement_2d (for hybrid grid/navigation).",
				"mistakes": "Forgetting to bake means the agent walks straight into walls.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_navigationregion2d.html"
			}
		"NavigationRegion3D":
			return {
				"what": "Defines the walkable area for 3D navigation. Agents path within the baked navigation mesh.",
				"required": "A NavigationMesh resource configured in the Inspector, then baked from the toolbar.",
				"recommended": "Set agent_radius, agent_height, and agent_max_climb to match your characters. Rebake after moving any static geometry.",
				"paired": "navigation_region_3d_setup, navigation_agent_3d, patrol_waypoints_3d.",
				"mistakes": "Forgetting to rebake after editing the level means AI paths through walls that no longer exist.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_navigationregion3d.html"
			}
		"NavigationAgent2D":
			return {
				"what": "An agent that paths within a NavigationRegion2D. Set the target position, read the next path point, move toward it.",
				"required": "A NavigationRegion2D somewhere in the scene.",
				"recommended": "Set path_desired_distance and target_desired_distance. Read get_next_path_position() in _physics_process.",
				"paired": "navigation_agent_2d, chase_player, enemy_patrol.",
				"mistakes": "Calling move_and_slide() with velocity toward the target instead of toward get_next_path_position() bypasses pathfinding.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_navigationagent2d.html"
			}
		"NavigationAgent3D":
			return {
				"what": "An agent that paths within a NavigationRegion3D.",
				"required": "A NavigationRegion3D with a baked navigation mesh.",
				"recommended": "Enable avoidance_enabled and read velocity_computed for smooth agent-to-agent avoidance.",
				"paired": "navigation_agent_3d, navigation_agent_avoidance_3d, boss_3d, patrol_waypoints_3d.",
				"mistakes": "Moving toward the raw target instead of get_next_path_position() ignores the path and walks into walls.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_navigationagent3d.html"
			}
		"NavigationObstacle3D":
			return {
				"what": "A dynamic obstacle that agents path around. Barrels, vehicles, moving platforms.",
				"required": "A NavigationRegion3D and agents with avoidance_enabled.",
				"recommended": "Set radius to roughly match the obstacle's footprint.",
				"paired": "navigation_obstacle_3d, moving_platform_3d.",
				"mistakes": "Forgetting to match radius to the object makes AI walk through the visual mesh.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_navigationobstacle3d.html"
			}

		# =====================================================
		# GridMap / 3D level building
		# =====================================================
		"GridMap":
			return {
				"what": "Places 3D meshes on a grid. The 3D equivalent of TileMap. Blocky voxel-style levels, modular architecture.",
				"required": "A MeshLibrary resource — contains mesh + collision per item.",
				"recommended": "Set cell_size to match your mesh scale. Use the GridMap panel at the bottom to paint cells.",
				"paired": "gridmap_setup, mesh_library_setup, gridmap_room_builder, gridmap_navigation.",
				"mistakes": "Mismatched cell_size and mesh scale causes gaps or overlapping pieces.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_gridmap.html"
			}

		# =====================================================
		# Misc
		# =====================================================
		"Path2D":
			return {
				"what": "A 2D curve. Defines a path that PathFollow2D nodes travel along.",
				"required": "A Curve2D resource — draw the curve in the 2D editor.",
				"recommended": "Add a PathFollow2D child and place its children on it.",
				"paired": "PathFollow2D, moving_platform_path, patrolling enemies along curved routes.",
				"mistakes": "Leaving the curve empty — the path has no shape and PathFollow2D has nothing to follow.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_path2d.html"
			}
		"Path3D":
			return {
				"what": "A 3D curve. Defines a path that PathFollow3D nodes travel along.",
				"required": "A Curve3D resource — draw the curve in the 3D editor.",
				"recommended": "Set the curve's points in the 3D viewport. Add a PathFollow3D child.",
				"paired": "PathFollow3D, camera rails, moving platforms on curves.",
				"mistakes": "Very sharp curves cause PathFollow3D to snap between segments, looking jittery. Smooth the curve.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_path3d.html"
			}
		"PathFollow2D":
			return {
				"what": "A node that travels along a Path2D. Set progress or progress_ratio to move it.",
				"required": "A Path2D parent with a non-empty Curve2D.",
				"recommended": "Animate progress_ratio from 0 to 1 for one full loop. Set loop = true for continuous motion.",
				"paired": "Path2D, moving platforms, projectiles on curved paths.",
				"mistakes": "Forgetting to increment progress — the follow node sits at the start of the curve.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_pathfollow2d.html"
			}
		"PathFollow3D":
			return {
				"what": "A node that travels along a Path3D.",
				"required": "A Path3D parent with a non-empty Curve3D.",
				"recommended": "Animate progress_ratio from 0 to 1. Set rotation_mode for how the node faces along the curve.",
				"paired": "Path3D, camera rails, enemy patrols on curves.",
				"mistakes": "Very sharp curves cause snapping. Add more control points to smooth the curve.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_pathfollow3d.html"
			}
		"VisibleOnScreenNotifier2D":
			return {
				"what": "Emits signals when a 2D node enters or leaves the visible viewport area. Enables off-screen culling optimizations.",
				"required": "Set the rect property to cover the area you want to test.",
				"recommended": "Connect screen_entered and screen_exited to pause AI and animation when off-screen.",
				"paired": "Any performance optimization pass.",
				"mistakes": "Very large rects mean the notifier almost always reports visible, defeating the point.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_visibleonscreennotifier2d.html"
			}
		"VisibleOnScreenEnabler3D":
			return {
				"what": "Enables or disables a 3D node based on whether it's on screen. Automatic off-screen optimization.",
				"required": "Set the parent node's visible range. Configure enable_node_path.",
				"recommended": "Attach to expensive 3D nodes (particles, complex meshes) to disable them off-screen.",
				"paired": "Performance passes on mobile or with many 3D objects.",
				"mistakes": "Forgetting enable_node_path means nothing gets enabled or disabled.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_visibleonscreenenabler3d.html"
			}
		"SubViewport":
			return {
				"what": "A separate render target. Renders a scene into a texture that can be displayed elsewhere. Minimaps, portals, picture-in-picture.",
				"required": "A size set (e.g. 256x256 for a minimap).",
				"recommended": "Wrap in a SubViewportContainer to display it. Add a Camera3D and scene content inside.",
				"paired": "Minimap UI, split-screen, in-game monitors.",
				"mistakes": "Forgetting to enable render_target_update_mode means the SubViewport renders once and never updates.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_subviewport.html"
			}
		"SubViewportContainer":
			return {
				"what": "A Control that displays the output of a SubViewport child.",
				"required": "Exactly one SubViewport child.",
				"recommended": "Set stretch = true to scale the SubViewport contents to fill the container.",
				"paired": "Minimaps, split-screen, in-game monitors.",
				"mistakes": "Putting multiple SubViewports as children — SubViewportContainer only displays the first.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_subviewportcontainer.html"
			}
		"HTTPRequest":
			return {
				"what": "Sends HTTP requests and emits signals on completion. Leaderboards, cloud saves, telemetry.",
				"required": "None. Call request() with a URL.",
				"recommended": "Connect request_completed. Check the result code and response_code.",
				"paired": "Leaderboards, cloud saves, update checks.",
				"mistakes": "Forgetting to handle the failure case — request_completed fires for both success and failure.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_httprequest.html"
			}
		"MultiplayerSpawner":
			return {
				"what": "Replicates spawned nodes across the network. Part of Godot's high-level multiplayer API.",
				"required": "A spawn_path pointing at the node whose children should be replicated. An auto_spawn_list of scenes.",
				"recommended": "Add scenes to spawnable_scenes. Set spawn_limit based on expected counts.",
				"paired": "Multiplayer lobbies, co-op games, shared world state.",
				"mistakes": "Forgetting to add scenes to spawnable_scenes means they fail to replicate silently.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_multiplayerspawner.html"
			}
		"MultiplayerSynchronizer":
			return {
				"what": "Replicates properties across the network. Position, health, state — anything that needs to stay in sync.",
				"required": "A replication_config with a SceneReplicationConfig resource defining what to sync.",
				"recommended": "Only sync properties that actually change. Position + rotation + essential state.",
				"paired": "Player characters, enemies, shared game state.",
				"mistakes": "Syncing too many properties wastes bandwidth. Keep the replicated set minimal.",
				"docs": "https://docs.godotengine.org/en/stable/classes/class_multiplayersynchronizer.html"
			}
		_:
			return {}
			
# =========================================================================
# Auto-describe (ClassDB fallback)
# =========================================================================

func _auto_describe(cls: String) -> Dictionary:
	if not ClassDB.class_exists(cls):
		return {
			"what": "Unknown class: " + cls,
			"required": "",
			"recommended": "",
			"paired": "",
			"mistakes": "",
			"docs": ""
		}

	var chain := _build_inheritance_chain(cls)
	var own_methods := _filter_methods(cls)
	var own_properties := _filter_properties(cls)
	var signals := _filter_signals(cls)
	var api_type := ClassDB.class_get_api_type(cls)

	var what_lines: Array = []
	if ClassDB.is_parent_class(cls, "Node") or cls == "Node":
		what_lines.append("A " + cls + " node.")
	else:
		what_lines.append("A " + cls + " class.")
	if chain.size() > 0:
		what_lines.append("Inherits from " + " \u2192 ".join(chain) + ".")

	if api_type == ClassDB.API_EDITOR:
		what_lines.append("Editor-only class \u2014 not available in exported games.")
	elif api_type == ClassDB.API_EDITOR_EXTENSION:
		what_lines.append("Editor extension class.")

	if own_methods.size() > 0:
		what_lines.append("")
		what_lines.append("Notable methods:")
		for m in own_methods:
			what_lines.append("  - " + m)
	if own_properties.size() > 0:
		what_lines.append("")
		what_lines.append("Notable properties:")
		for p in own_properties:
			what_lines.append("  - " + p)
	if signals.size() > 0:
		what_lines.append("")
		what_lines.append("Signals: " + ", ".join(signals))
	else:
		what_lines.append("")
		what_lines.append("Signals: none.")

	return {
		"what": "\n".join(what_lines),
		"required": "",
		"recommended": "",
		"paired": "",
		"mistakes": "",
		"docs": "https://docs.godotengine.org/en/stable/classes/class_" + cls.to_lower() + ".html"
	}


# =========================================================================
# ClassDB walking helpers
# =========================================================================

func _build_inheritance_chain(cls: String) -> Array:
	var chain: Array = []
	var current := ClassDB.get_parent_class(cls)
	while current != "" and chain.size() < 6:
		chain.append(current)
		current = ClassDB.get_parent_class(current)
	return chain


func _filter_methods(cls: String) -> Array:
	var out: Array = []
	var seen: Dictionary = {}
	var methods := ClassDB.class_get_method_list(cls, true)
	var parent := ClassDB.get_parent_class(cls)
	for m in methods:
		var name := str(m.get("name", ""))
		if name.is_empty() or seen.has(name):
			continue
		if name.begins_with("_"):
			continue
		if name.begins_with("notification") or name.begins_with("initialize"):
			continue
		if parent != "" and _has_method(parent, name):
			continue
		seen[name] = true
		out.append(name + "()")
		if out.size() >= 10:
			break
	return out


func _filter_properties(cls: String) -> Array:
	var out: Array = []
	var seen: Dictionary = {}
	var properties := ClassDB.class_get_property_list(cls, true)
	var parent := ClassDB.get_parent_class(cls)
	for p in properties:
		var name := str(p.get("name", ""))
		if name.is_empty() or seen.has(name):
			continue
		if name.begins_with("_") or name.begins_with("metadata/"):
			continue
		var usage: int = int(p.get("usage", 0))
		if usage & PROPERTY_USAGE_GROUP != 0 or usage & PROPERTY_USAGE_CATEGORY != 0:
			continue
		if parent != "" and _has_property(parent, name):
			continue
		seen[name] = true
		var type_name := _property_type_name(p)
		var line := name
		if not type_name.is_empty():
			line += ": " + type_name
		out.append(line)
		if out.size() >= 12:
			break
	return out


func _filter_signals(cls: String) -> Array:
	var out: Array = []
	var signals := ClassDB.class_get_signal_list(cls, true)
	var parent := ClassDB.get_parent_class(cls)
	for s in signals:
		var name := str(s.get("name", ""))
		if name.is_empty():
			continue
		if parent != "" and _has_signal(parent, name):
			continue
		out.append(name)
		if out.size() >= 10:
			break
	return out


func _property_type_name(prop: Dictionary) -> String:
	var t: int = int(prop.get("type", TYPE_NIL))
	match t:
		TYPE_BOOL: return "bool"
		TYPE_INT: return "int"
		TYPE_FLOAT: return "float"
		TYPE_STRING: return "String"
		TYPE_VECTOR2: return "Vector2"
		TYPE_VECTOR2I: return "Vector2i"
		TYPE_VECTOR3: return "Vector3"
		TYPE_VECTOR3I: return "Vector3i"
		TYPE_COLOR: return "Color"
		TYPE_NODE_PATH: return "NodePath"
		TYPE_OBJECT: return str(prop.get("class_name", "Object"))
		TYPE_ARRAY: return "Array"
		TYPE_DICTIONARY: return "Dictionary"
	return ""


func _has_method(cls: String, method: String) -> bool:
	var methods := ClassDB.class_get_method_list(cls)
	for m in methods:
		if str(m.get("name", "")) == method:
			return true
	return false


func _has_property(cls: String, property_name: String) -> bool:
	var properties := ClassDB.class_get_property_list(cls)
	for p in properties:
		if str(p.get("name", "")) == property_name:
			return true
	return false


func _has_signal(cls: String, signal_name: String) -> bool:
	var signals := ClassDB.class_get_signal_list(cls)
	for s in signals:
		if str(s.get("name", "")) == signal_name:
			return true
	return false

# res://addons/gd_snippet_expander/ai_debugger/fix_library_data_c.gd
@tool
class_name FixLibraryDataC
extends RefCounted

## Fix records, volume C: physics, collision, animation, groups.
##
## Part of the GD Snippet Expander mini AI debugger (v1.6).
## Forty curated records covering physics bodies, collision setup,
## animation playback, and group-based node discovery.
##
## Usage from the plugin loader:
##   var lib := FixLibrary.new()
##   lib.load_all()
##   FixLibraryDataA.register_into(lib)
##   FixLibraryDataB.register_into(lib)
##   FixLibraryDataC.register_into(lib)   # this file

# --- public entry points -----------------------------------------------

static func register_into(lib: FixLibrary) -> int:
	return lib.register_records(records())


static func records() -> Array:
	var out: Array = []

	# ===================================================================
	# PHYSICS (24)
	# ===================================================================

	out.append({
		"id": "physics_process_vs_process",
		"title": "Physics code running in _process instead of _physics_process",
		"category": "physics",
		"phrases": [
			"physics jittery",
			"movement stutters",
			"character shakes",
			"move_and_slide in process",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "move_and_slide"},
			{"kind": "identifier", "value": "_process"},
			{"kind": "identifier", "value": "_physics_process", "negate": true},
		],
		"candidates": [{
			"code": "func _physics_process(delta: float) -> void:\n\tvelocity = ...\n\tmove_and_slide()\n",
			"description": "move_and_slide, move_and_collide, and force application must run in _physics_process. Running them in _process desyncs them from the physics tick and causes jitter.",
			"confidence": 0.82,
		}],
	})

	out.append({
		"id": "body_type_selection",
		"title": "Choosing between CharacterBody, RigidBody, Area, and StaticBody",
		"category": "physics",
		"phrases": [
			"which physics body",
			"characterbody or rigidbody",
			"body type",
			"what body should I use",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "RigidBody"},
			{"kind": "identifier", "value": "CharacterBody"},
		],
		"candidates": [{
			"code": "# StaticBody — never moves, blocks everything.\n# CharacterBody — YOU move it manually with velocity + move_and_slide.\n# RigidBody — physics engine moves it with forces and impulses.\n# Area — detects overlap, no physical blocking.\n",
			"description": "Pick by who controls movement. Player controllers usually want CharacterBody. Bouncing boxes and physics props want RigidBody. Triggers want Area.",
			"confidence": 0.75,
		}],
	})

	out.append({
		"id": "move_and_slide_vs_move_and_collide",
		"title": "move_and_slide or move_and_collide?",
		"category": "physics",
		"phrases": [
			"move_and_slide vs move_and_collide",
			"character slides on walls",
			"character stops at walls",
			"which move function",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "move_and_slide"},
			{"kind": "identifier", "value": "move_and_collide"},
		],
		"candidates": [{
			"code": "# move_and_slide: character glides along surfaces. Good for players.\n# move_and_collide: character stops on impact, returns collision info.\n#   Good for projectiles you want to despawn on hit.\n",
			"description": "move_and_slide resolves collisions by sliding. move_and_collide stops at the first collision and gives you the info to react.",
			"confidence": 0.78,
		}],
	})

	out.append({
		"id": "raycast_ignore_self",
		"title": "RayCast hits the caster's own body",
		"category": "physics",
		"phrases": [
			"raycast hits itself",
			"raycast collides with caster",
			"raycast self",
			"raycast returns own body",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "RayCast"},
		],
		"candidates": [{
			"code": "$RayCast2D.add_exception(self)\n# Or exclude the whole layer:\n$RayCast2D.collision_mask = 1   # only layer 1\n",
			"description": "A RayCast that starts inside a body detects that body. Add self as an exception, or use collision_mask to only detect the layers you care about.",
			"confidence": 0.80,
		}],
	})

	out.append({
		"id": "raycast_target_to_global",
		"title": "RayCast target_position is local, not global",
		"category": "physics",
		"phrases": [
			"raycast points wrong way",
			"raycast direction wrong",
			"raycast to global point",
			"target_position raycast",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "RayCast"}
		],
		"candidates": [{
			"code": "var global_target: Vector2 = mouse_pos\n$RayCast2D.target_position = to_local(global_target)\n",
			"description": "RayCast's target_position is relative to the RayCast node. To aim at a world point, convert it with to_local() first.",
			"confidence": 0.72,
		}],
	})

	out.append({
		"id": "area_monitoring_disabled",
		"title": "Area2D/Area3D isn't monitoring",
		"category": "physics",
		"phrases": [
			"area doesn't detect",
			"area signal never fires",
			"monitoring area",
			"area overlap not detected",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "Area2D"}
		],
		"candidates": [{
			"code": "# Check on the Area2D:\n#   monitoring = true       (detects other bodies entering)\n#   monitorable = true      (can be detected by other areas)\n#   collision_mask          (which layers this area detects)\n#   has a CollisionShape2D child\n",
			"description": "Areas need monitoring=true and a CollisionShape child. If collision_mask doesn't include the layer of the target, no overlap is reported.",
			"confidence": 0.75,
		}],
	})

	out.append({
		"id": "area_body_entered_signal",
		"title": "Which Area signal to connect",
		"category": "physics",
		"phrases": [
			"body_entered vs area_entered",
			"which area signal",
			"area signal to use",
			"area_entered not firing",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "Area2D"}
		],
		"candidates": [{
			"code": "# body_entered(body) fires for PhysicsBody2D/3D and TileMap.\n# area_entered(area) fires only for other Areas.\n# Use body_entered for players/enemies, area_entered for triggers.\n$Area2D.body_entered.connect(_on_body_entered)\n",
			"description": "body_entered is what you usually want. area_entered only fires when the entering thing is itself an Area, which is rare.",
			"confidence": 0.78,
		}],
	})

	out.append({
		"id": "continuous_collision_detection",
		"title": "Fast objects pass through walls",
		"category": "physics",
		"phrases": [
			"bullet passes through wall",
			"fast object tunnels",
			"tunneling collision",
			"ccd enable",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "RigidBody"}
		],
		"candidates": [{
			"code": "# On the fast-moving body, set:\n#   continuous_cd = true\n# On a RigidBody3D it's called:\n#   continuous_cd = true\n",
			"description": "Physics runs at fixed timesteps. A bullet moving more than its own length per step can skip past a thin wall. Continuous collision detection samples along the path.",
			"confidence": 0.78,
		}],
	})

	out.append({
		"id": "rigidbody_sleep_issue",
		"title": "RigidBody stops responding after a while",
		"category": "physics",
		"phrases": [
			"rigidbody falls asleep",
			"rigidbody stops moving",
			"body won't respond to forces",
			"can_sleep rigidbody",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "RigidBody"}
		],
		"candidates": [{
			"code": "# Option A: disable sleeping entirely\ncan_sleep = false\n# Option B: wake it before applying a force\nsleeping = false\napply_central_force(force)\n",
			"description": "RigidBodies sleep when at rest to save CPU. Applying a force to a sleeping body has no effect until it wakes. Set sleeping=false or can_sleep=false.",
			"confidence": 0.72,
		}],
	})

	out.append({
		"id": "physics_material_bounce",
		"title": "Set bounce and friction via PhysicsMaterial",
		"category": "physics",
		"phrases": [
			"bouncy ball",
			"no bounce",
			"friction missing",
			"physics material",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "PhysicsMaterial"},
		],
		"candidates": [{
			"code": "# Create a PhysicsMaterial resource, set bounce and friction,\n# then assign it to the body's physics_material_override:\nvar mat: PhysicsMaterial = PhysicsMaterial.new()\nmat.bounce = 0.8\nmat.friction = 0.2\nphysics_material_override = mat\n",
			"description": "Bounce and friction come from a PhysicsMaterial resource, not from the body directly. Both bodies in a collision contribute — the effective values are combined.",
			"confidence": 0.75,
		}],
	})

	out.append({
		"id": "one_way_collision_3d",
		"title": "One-way collision platform in 3D",
		"category": "physics",
		"phrases": [
			"one way platform",
			"jump through platform",
			"pass through from below",
			"one_way_collision",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "one_way_collision"},
		],
		"candidates": [{
			"code": "# On the platform's CollisionShape3D:\n#   one_way_collision = true\n#   one_way_collision_margin = 1.0\n",
			"description": "Set one_way_collision on the platform's CollisionShape3D. Bodies pass through from the back side and collide from the front.",
			"confidence": 0.75,
		}],
	})

	out.append({
		"id": "get_slide_collision_info",
		"title": "Read what move_and_slide collided with",
		"category": "physics",
		"phrases": [
			"what did I hit",
			"slide collision info",
			"get_slide_collision",
			"collision from move_and_slide",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "move_and_slide"},
		],
		"candidates": [{
			"code": "move_and_slide()\nfor i in get_slide_collision_count():\n\tvar col: KinematicCollision2D = get_slide_collision(i)\n\tvar other: Object = col.get_collider()\n\tif other is Enemy:\n\t\tother.take_damage(1)\n",
			"description": "After move_and_slide, iterate get_slide_collision(i) for each collision that occurred. Each returns the collider, normal, and point.",
			"confidence": 0.72,
		}],
	})

	out.append({
		"id": "is_on_wall_only_checks",
		"title": "Distinguish floor, wall, and ceiling",
		"category": "physics",
		"phrases": [
			"is_on_floor vs is_on_wall",
			"check floor vs wall",
			"which side am I touching",
			"floor normal",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "is_on_floor"},
		],
		"candidates": [{
			"code": "if is_on_floor():\n\t# floor\nelif is_on_wall_only():\n\t# wall\nelif is_on_ceiling():\n\t# ceiling\n",
			"description": "CharacterBody3D has is_on_floor, is_on_wall, is_on_wall_only, is_on_ceiling. Use is_on_wall_only when you need to rule out the floor.",
			"confidence": 0.72,
		}],
	})

	out.append({
		"id": "max_slides_exhausted",
		"title": "Character gets stuck in corners",
		"category": "physics",
		"phrases": [
			"character stuck in corner",
			"stuck on geometry",
			"max_slides",
			"corner collision stuck",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "max_slides"},
		],
		"candidates": [{
			"code": "# In _physics_process, before move_and_slide:\nmax_slides = 8\n# Also consider:\nfloor_max_angle = deg_to_rad(46.0)\nsafe_margin = 0.08\n",
			"description": "max_slides caps how many collisions move_and_slide resolves per frame. Corners and tight geometry can exhaust it, leaving the body wedged. Raise it to 8-12.",
			"confidence": 0.60,
		}],
	})

	out.append({
		"id": "collision_layer_vs_mask",
		"title": "collision_layer vs collision_mask",
		"category": "physics",
		"phrases": [
			"layer vs mask",
			"collision layers explained",
			"what layer should I use",
			"layers and masks",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "collision_layer"},
		],
		"candidates": [{
			"code": "# collision_layer = \"what I am\"\n# collision_mask = \"what I detect / collide with\"\n#\n# Two bodies interact only if one's mask has the other's layer.\n# Player:  layer=1, mask=2 (detects enemies)\n# Enemy:   layer=2, mask=1 (detects player)\n",
			"description": "Layer is identity. Mask is what you look for. A one-way interaction (player detects enemy but not vice versa) is valid and useful.",
			"confidence": 0.82,
		}],
	})

	out.append({
		"id": "collision_shape_missing",
		"title": "Body has no CollisionShape child",
		"category": "physics",
		"phrases": [
			"collision not working",
			"no collision shape",
			"body passes through",
			"collision shape missing",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "CollisionShape2D"},
			{"kind": "identifier", "value": "CollisionShape3D"},
		],
		"candidates": [{
			"code": "# A physics body needs a CollisionShape2D or CollisionShape3D child\n# with a Shape resource assigned (RectangleShape2D, BoxShape3D, ...).\n# Setting collision_layer/mask alone does nothing without a shape.\n",
			"description": "The shape defines the geometry. Without a child CollisionShape and a shape resource, the body has no volume and collisions can't happen.",
			"confidence": 0.82,
		}],
	})

	out.append({
		"id": "collision_shape_scale_issue",
		"title": "Scaled collision shapes behave unpredictably",
		"category": "physics",
		"phrases": [
			"scaled collision",
			"collision shape scale",
			"scaling collision wrong",
			"collision distorted",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "CollisionShape2D"},
		],
		"candidates": [{
			"code": "# Instead of scaling the CollisionShape node, resize the Shape resource:\nvar rect: RectangleShape2D = $CollisionShape2D.shape as RectangleShape2D\nrect.size = Vector2(64, 32)\n",
			"description": "Scaling a CollisionShape at the node level works but is discouraged — physics engines prefer uniform shapes. Change the shape resource's size/extents instead.",
			"confidence": 0.65,
		}],
	})

	out.append({
		"id": "collision_shape_2d_vs_3d",
		"title": "Wrong shape type for the body dimension",
		"category": "physics",
		"phrases": [
			"collision shape wrong type",
			"2d shape on 3d body",
			"shape mismatch",
			"can't add shape",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "CollisionShape"}
		],
		"candidates": [{
			"code": "# 2D bodies (CharacterBody2D, Area2D) need CollisionShape2D\n#   + a Shape2D resource (RectangleShape2D, CircleShape2D, ...).\n# 3D bodies (CharacterBody3D, Area3D) need CollisionShape3D\n#   + a Shape3D resource (BoxShape3D, SphereShape3D, ...).\n",
			"description": "2D and 3D shapes are separate type hierarchies. A BoxShape3D can't go on a CollisionShape2D.",
			"confidence": 0.78,
		}],
	})

	out.append({
		"id": "one_way_collision_2d",
		"title": "One-way collision platform in 2D",
		"category": "physics",
		"phrases": [
			"one way platform 2d",
			"jump through floor",
			"drop through platform",
			"one_way_collision 2d",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "one_way_collision"},
		],
		"candidates": [{
			"code": "# On the platform's CollisionShape2D:\n#   one_way_collision = true\n#   one_way_collision_margin = 1.0\n#\n# To drop through, disable the body's mask briefly:\ncollision_mask = 0\nawait get_tree().create_timer(0.2).timeout\ncollision_mask = original_mask\n",
			"description": "one_way_collision makes the shape solid only from one direction. For drop-through, temporarily clear the player's collision_mask.",
			"confidence": 0.72,
		}],
	})

	out.append({
		"id": "collision_debug_visible",
		"title": "Show collision shapes in the running game",
		"category": "physics",
		"phrases": [
			"show collision shapes",
			"debug collision",
			"see collision outlines",
			"collision visible",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "debug_collisions"}
		],
		"candidates": [{
			"code": "# Debug menu -> Visible Collision Shapes (toggle while running)\n# Or from code:\nget_tree().debug_collisions_hint = true\n",
			"description": "Toggling collision shape visibility while the game runs shows exactly where the physics geometry is. The single best debugging tool for collision issues.",
			"confidence": 0.78,
		}],
	})

	out.append({
		"id": "area_signals_setup",
		"title": "Connect Area signals from code",
		"category": "physics",
		"phrases": [
			"connect area signal code",
			"area body entered from code",
			"area signal no editor",
			"setup area signals",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "Area2D"},
		],
		"candidates": [{
			"code": "func _ready() -> void:\n\t$Area2D.body_entered.connect(_on_body_entered)\n\t$Area2D.body_exited.connect(_on_body_exited)\n\nfunc _on_body_entered(body: Node2D) -> void:\n\tpass\n",
			"description": "Area emits body_entered, body_exited, area_entered, area_exited. Connect from _ready with the Callable form — the old string form is deprecated in Godot 4.",
			"confidence": 0.75,
		}],
	})

	out.append({
		"id": "collision_shape_rotation",
		"title": "Rotating a collision shape rotates collisions",
		"category": "physics",
		"phrases": [
			"rotated collision shape",
			"collision rotates with sprite",
			"rotating collision",
			"shape rotation issue",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "CollisionShape"}
		],
		"candidates": [{
			"code": "# CollisionShape2D/3D inherit rotation from their parent.\n# If the sprite rotates and you don't want the collision to,\n# detach the shape by giving it its own Node2D/Node3D parent that\n# does not rotate, or reset the shape's rotation each frame.\n",
			"description": "Collision shapes rotate with their parent. If your sprite rotates and the collision shouldn't, separate the two hierarchies.",
			"confidence": 0.62,
		}],
	})

	out.append({
		"id": "rigidbody_disable_collision",
		"title": "Temporarily disable a body's collisions",
		"category": "physics",
		"phrases": [
			"disable collision temporarily",
			"turn off collision",
			"ghost mode",
			"phase through",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "collision_layer"}
		],
		"candidates": [{
			"code": "# Save and clear the layer/mask:\nvar old_layer: int = collision_layer\nvar old_mask: int = collision_mask\ncollision_layer = 0\ncollision_mask = 0\nawait get_tree().create_timer(0.5).timeout\ncollision_layer = old_layer\ncollision_mask = old_mask\n",
			"description": "Setting collision_layer and collision_mask to 0 makes the body invisible to physics. Restore the values when the effect ends.",
			"confidence": 0.72,
		}],
	})

	out.append({
		"id": "character_body_floor_snap",
		"title": "Character bounces down slopes",
		"category": "physics",
		"phrases": [
			"character bounces on slopes",
			"not staying on ground",
			"slope bounce",
			"floor snap length",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "floor_snap_length"},
		],
		"candidates": [{
			"code": "# In _physics_process, before move_and_slide:\nfloor_snap_length = 8.0\nfloor_max_angle = deg_to_rad(46.0)\n",
			"description": "floor_snap_length pulls the body to the ground when it's just above the floor. Without it, the body 'peels off' at slope crests and creates bouncy movement.",
			"confidence": 0.68,
		}],
	})

	# ===================================================================
	# ANIMATION (10)
	# ===================================================================

	out.append({
		"id": "animation_player_vs_tree",
		"title": "AnimationPlayer or AnimationTree?",
		"category": "animation",
		"phrases": [
			"animationplayer or animationtree",
			"which animation node",
			"animation player vs tree",
			"when to use animation tree",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "AnimationPlayer"},
			{"kind": "identifier", "value": "AnimationTree"},
		],
		"candidates": [{
			"code": "# AnimationPlayer — simple, plays one animation at a time.\n#   Good for one-shot effects, doors, cutscenes.\n# AnimationTree — blends and blends between animations.\n#   Good for character locomotion with idle/walk/run states.\n",
			"description": "Use AnimationPlayer for simple cases. Use AnimationTree when you need blended transitions based on parameters.",
			"confidence": 0.72,
		}],
	})

	out.append({
		"id": "animation_tree_parameters",
		"title": "Set AnimationTree parameters from code",
		"category": "animation",
		"phrases": [
			"animation tree parameter",
			"set blend parameter",
			"animation tree from code",
			"set animation parameter",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "AnimationTree"},
		],
		"candidates": [{
			"code": "$AnimationTree.set(\"parameters/move/blend_position\", velocity.length())\n# Or use the shorthand:\n$AnimationTree[\"parameters/conditions/is_running\"] = true\n",
			"description": "AnimationTree parameters live under the parameters/ prefix. In the editor, hover a parameter to see its full path.",
			"confidence": 0.78,
		}],
	})

	out.append({
		"id": "animation_state_transition",
		"title": "State transition never fires",
		"category": "animation",
		"phrases": [
			"animation state stuck",
			"transition not firing",
			"animation tree stuck",
			"animation state machine",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "AnimationTree"},
		],
		"candidates": [{
			"code": "# In AnimationTree, a transition needs:\n#   - a condition or advance_mode set\n#   - a target state that exists\n#   - the parameter driving the condition to actually change\n#\n# Open the AnimationTree panel and click the transition to inspect.\n",
			"description": "Most stuck transitions are because the condition parameter never changes. Print the parameter from code to confirm it's being set.",
			"confidence": 0.65,
		}],
	})

	out.append({
		"id": "animation_blend_2d",
		"title": "2D blend space for top-down movement",
		"category": "animation",
		"phrases": [
			"top down animation",
			"2d blend space",
			"blend walk directions",
			"directional animation",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "BlendSpace2D"},
		],
		"candidates": [{
			"code": "# In AnimationTree: AnimationNodeBlendSpace2D\n# Add animation points at compass positions:\n#   (0,0)    idle\n#   (0,-1)   walk_up\n#   (1,0)    walk_right\n#   (0,1)    walk_down\n#   (-1,0)   walk_left\n# From code:\n$AnimationTree[\"parameters/move/blend_position\"] = direction\n",
			"description": "BlendSpace2D places animations on a 2D plane and interpolates between the nearest three. Set blend_position to the movement direction vector.",
			"confidence": 0.68,
		}],
	})

	out.append({
		"id": "animation_method_call",
		"title": "Trigger code at a specific animation frame",
		"category": "animation",
		"phrases": [
			"method call track",
			"animation callback",
			"run code at frame",
			"animation event",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "AnimationPlayer"},
		],
		"candidates": [{
			"code": "# Add a Method Call Track in the AnimationPlayer editor.\n# Set the key's method to a method name on your script.\n# At that timestamp, AnimationPlayer calls it with any args.\n\nfunc footstep() -> void:\n\t$FootstepSound.play()\n",
			"description": "Method Call Tracks fire a method when the animation reaches a key. Use for footstep sounds, hitboxes, or state changes.",
			"confidence": 0.72,
		}],
	})

	out.append({
		"id": "sprite_frames_timing",
		"title": "SpriteFrames animation plays too fast or slow",
		"category": "animation",
		"phrases": [
			"sprite frames speed",
			"sprite animation too fast",
			"spritefps",
			"sprite frames fps",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "SpriteFrames"},
		],
		"candidates": [{
			"code": "# SpriteFrames sets fps per animation:\nframes.set_animation_speed(\"walk\", 12.0)\n# Per-frame duration overrides are also available:\nframes.set_frame_duration(\"walk\", 0, 0.2)\n",
			"description": "The default SpriteFrames fps is 5. Walk cycles usually want 8-12, run cycles 12-16. Set it per animation.",
			"confidence": 0.65,
		}],
	})

	out.append({
		"id": "animation_not_playing",
		"title": "AnimationPlayer.play() does nothing",
		"category": "animation",
		"phrases": [
			"animation not playing",
			"play() does nothing",
			"animation silent",
			"animation won't start",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "play"},
		],
		"candidates": [{
			"code": "# Check:\n#   - the animation name is exactly right (case sensitive)\n#   - the AnimationPlayer has an AnimationLibrary assigned\n#   - current_animation isn't blocking\n#   - the node isn't paused\n$AnimationPlayer.play(\"walk\")\nprint($AnimationPlayer.get_animation_list())\n",
			"description": "Printing get_animation_list() is the fastest way to see what animations exist. Most failures are typos in the animation name.",
			"confidence": 0.72,
		}],
	})

	out.append({
		"id": "animation_looping_setup",
		"title": "Animation loops when it shouldn't (or vice versa)",
		"category": "animation",
		"phrases": [
			"animation loops",
			"animation doesn't loop",
			"loop mode",
			"animation repeat",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "Animation"}
		],
		"candidates": [{
			"code": "# Per-animation loop mode:\nvar anim: Animation = $AnimationPlayer.get_animation(\"walk\")\nanim.loop_mode = Animation.LOOP_LINEAR\n# Options: LOOP_NONE, LOOP_LINEAR, LOOP_PINGPONG\n",
			"description": "Loop mode is set on the Animation resource itself, not on AnimationPlayer. Loop one-shots (like attacks) should be LOOP_NONE; walks should be LOOP_LINEAR.",
			"confidence": 0.75,
		}],
	})

	out.append({
		"id": "tween_vs_animation_player",
		"title": "Tween or AnimationPlayer for a simple motion?",
		"category": "animation",
		"phrases": [
			"tween or animation",
			"which to use tween",
			"animation player vs tween",
			"simple motion code",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "create_tween"},
			{"kind": "identifier", "value": "AnimationPlayer"},
		],
		"candidates": [{
			"code": "# Tween — one-off, code-defined, disposable.\nvar t := create_tween()\nt.scene_tree = get_tree()\nt.tween_property($Sprite2D, \"modulate:a\", 0.0, 0.3)\n# AnimationPlayer — designed in the editor, reusable, works on many props.\n",
			"description": "Tween is best for quick programmatic animations (fade, slide). AnimationPlayer is best for hand-authored, reused animations.",
			"confidence": 0.70,
		}],
	})

	out.append({
		"id": "animation_speed_scale",
		"title": "Speed up or slow down an AnimationPlayer",
		"category": "animation",
		"phrases": [
			"animation speed",
			"slow motion animation",
			"speed scale",
			"animation playback speed",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "speed_scale"},
		],
		"candidates": [{
			"code": "$AnimationPlayer.speed_scale = 2.0   # 2x speed\n$AnimationPlayer.speed_scale = 0.5   # half speed\n",
			"description": "speed_scale multiplies playback rate. Affects all animations on the player. Reset to 1.0 when the effect ends.",
			"confidence": 0.72,
		}],
	})

	# ===================================================================
	# NODES (6) — groups
	# ===================================================================

	out.append({
		"id": "add_to_group_basics",
		"title": "Add a node to a group",
		"category": "nodes",
		"phrases": [
			"add to group",
			"group node",
			"assign group code",
			"node group setup",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "add_to_group"},
		],
		"candidates": [{
			"code": "func _ready() -> void:\n\tadd_to_group(\"enemies\")\n",
			"description": "add_to_group puts the node in the named group. Groups can also be assigned in the editor via the Node dock.",
			"confidence": 0.82,
		}],
	})

	out.append({
		"id": "get_nodes_in_group",
		"title": "Get every node in a group",
		"category": "nodes",
		"phrases": [
			"get all enemies",
			"nodes in group",
			"iterate group",
			"find all in group",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "get_nodes_in_group"},
		],
		"candidates": [{
			"code": "var enemies: Array = get_tree().get_nodes_in_group(\"enemies\")\nfor e in enemies:\n\tif e is Node3D:\n\t\te.take_damage(10)\n",
			"description": "get_nodes_in_group returns an Array of all nodes currently in the group. Iterate with a type check if the group could mix node types.",
			"confidence": 0.80,
		}],
	})

	out.append({
		"id": "node_added_signal_tree",
		"title": "React when a node joins a group or the tree",
		"category": "nodes",
		"phrases": [
			"node added signal",
			"when node joins group",
			"tree node_added",
			"watch for new nodes",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "node_added"},
		],
		"candidates": [{
			"code": "func _ready() -> void:\n\tget_tree().node_added.connect(_on_node_added)\n\nfunc _on_node_added(node: Node) -> void:\n\tif node.is_in_group(\"enemies\"):\n\t\t# new enemy spawned\n\t\tpass\n",
			"description": "SceneTree emits node_added whenever any node enters the tree. Filter with is_in_group to react only to relevant spawns.",
			"confidence": 0.68,
		}],
	})

	out.append({
		"id": "group_typo_issue",
		"title": "Group name typo causes silent no-match",
		"category": "nodes",
		"phrases": [
			"group not found",
			"group is empty",
			"typo group name",
			"can't find group",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "is_in_group"},
		],
		"candidates": [{
			"code": "print(get_groups())   # on the node itself\nprint(get_tree().get_nodes_in_group(\"enemies\"))\n# Compare the two lists — group names are case sensitive.\n",
			"description": "Group names are case sensitive. Print get_groups() on the node to see its actual group strings and compare with the string you're searching for.",
			"confidence": 0.72,
		}],
	})

	out.append({
		"id": "remove_from_group",
		"title": "Remove a node from a group",
		"category": "nodes",
		"phrases": [
			"remove from group",
			"leave group",
			"take node out of group",
			"delete from group",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "remove_from_group"},
		],
		"candidates": [{
			"code": "if is_in_group(\"enemies\"):\n\tremove_from_group(\"enemies\")\n",
			"description": "remove_from_group detaches a single node. Use is_in_group first if you're not sure — remove_from_group on a non-member is a no-op but costs a call.",
			"confidence": 0.75,
		}],
	})

	out.append({
		"id": "group_cleanup_on_free",
		"title": "Freed nodes still appear in get_nodes_in_group",
		"category": "nodes",
		"phrases": [
			"group has freed nodes",
			"removed nodes still in group",
			"stale group entries",
			"group memory leak",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "get_nodes_in_group"},
		],
		"candidates": [{
			"code": "for e in get_tree().get_nodes_in_group(\"enemies\"):\n\tif not is_instance_valid(e):\n\t\tcontinue\n\te.take_damage(10)\n",
			"description": "Nodes are removed from groups when freed, but a frame can pass between queue_free and actual free. Guard with is_instance_valid if you iterate right after removals.",
			"confidence": 0.62,
		}],
	})

	return out


# --- self-test ----------------------------------------------------------

static func self_test() -> void:
	print("=== FixLibraryDataC self-test ===")
	var failures: Array[String] = []

	var arr: Array = records()

	var lib: FixLibrary = FixLibrary.new()
	lib.load_all()
	var added: int = register_into(lib)
	if added != arr.size():
		failures.append("register_into accepted %d of %d" % [added, arr.size()])
	if not lib.reject_log().is_empty():
		failures.append("%d rejects during registration" % lib.reject_log().size())

	# Category counts derived from the records themselves, then
	# compared to a hardcoded expected map. This way the only
	# hand-maintained number is the expected map, and the total
	# must equal the sum of its values.
	var actual: Dictionary = {}
	var i: int = 0
	while i < arr.size():
		var rec: Dictionary = arr[i]
		var cat: String = str(rec.get("category", ""))
		actual[cat] = int(actual.get(cat, 0)) + 1
		i += 1

	var expected: Dictionary = {
		"physics": 24,
		"animation": 10,
		"nodes": 6,
	}

	var expected_total: int = 0
	var ekeys: Array = expected.keys()
	i = 0
	while i < ekeys.size():
		expected_total += int(expected[ekeys[i]])
		i += 1

	if arr.size() != expected_total:
		failures.append("total records: expected %d, got %d" % [expected_total, arr.size()])

	i = 0
	while i < ekeys.size():
		var k: String = str(ekeys[i])
		var want: int = int(expected[k])
		var got: int = int(actual.get(k, 0))
		if want != got:
			failures.append("category '%s' expected %d, got %d" % [k, want, got])
		i += 1

	# Every ID must be unique within this file.
	var seen: Dictionary = {}
	i = 0
	while i < arr.size():
		var id: String = str(arr[i].get("id", ""))
		if seen.has(id):
			failures.append("duplicate id '%s'" % id)
		seen[id] = true
		i += 1

	# Cross-check against every ID already shipped in A, B, and
	# the starter set. If any of these collide, the loader will
	# reject the second one at runtime.
	var prior_ids: Array = [
		# Starter set
		"is_on_floor_missing", "gravity_not_applied", "delta_not_used",
		"input_map_missing", "input_get_action_strength",
		"get_node_returns_null", "node_path_wrong",
		"signal_wrong_signature", "await_signal_never_fires",
		"wrong_node_type", "queue_free_after_use",
		"rigidbody_moved_directly", "collision_layer_mismatch",
		"missing_type_hint", "godot3_to_godot4_rename",
		# Data A
		"coyote_time_2d", "jump_buffer_2d", "variable_jump_height",
		"air_control_2d", "wall_slide_2d", "wall_jump_2d",
		"dash_2d", "dash_air_2d", "sprint_toggle", "crouch_2d",
		"slope_slide_2d", "max_fall_speed", "jump_velocity_setup",
		"double_jump_2d", "jump_cut_on_release", "jump_particles_land",
		"jump_particles_takeoff", "jump_sound_pitch_variation",
		"landing_recovery_time", "dash_iframes", "dash_direction_8way",
		"dash_cancel_into_attack", "camera_follow_smooth",
		"camera_deadzone", "camera_lookahead", "camera_shake",
		"camera_limits_2d", "camera_zoom_smooth", "camera_mouse_look_3d",
		"camera_smooth_3d", "dash_camera_zoom", "input_deadzone_analog",
		"input_remap_runtime", "input_controller_detection",
		"input_touch_button_2d", "input_hold_vs_press", "input_double_tap",
		"dash_cooldown_ui", "dash_trail",
		# Data B
		"null_after_free", "null_signal_arg", "null_typed_var",
		"get_node_or_null_returns_null", "instantiate_returns_null",
		"owner_is_null", "get_first_node_in_group_empty", "dict_key_missing",
		"resource_load_failed", "get_parent_at_root", "autoload_not_registered",
		"await_result_null", "null_typed_array_access", "assert_condition_false",
		"signal_not_emitted", "signal_connect_failed",
		"signal_emitted_before_connect", "signal_arg_type_mismatch",
		"signal_one_shot", "signal_await_timeout", "signal_callable_bind",
		"signal_typed_params", "signal_duplicate_connection",
		"signal_disconnect_during_emit", "signal_emit_in_ready",
		"signal_custom_no_params", "signal_wrong_arg_count",
		"ready_not_called", "process_not_called", "node_added_to_wrong_parent",
		"node_name_collision", "node_order_in_scene", "ready_vs_enter_tree",
		"remove_child_vs_queue_free", "node_visibility", "node_processing_disabled",
		"z_index_wrong", "node_duplicate", "node_reparent",
		"_ready_called_before_parent_ready", "call_deferred_pattern",
	]
	i = 0
	while i < prior_ids.size():
		var pid: String = str(prior_ids[i])
		if seen.has(pid):
			failures.append("id '%s' collides with prior volume" % pid)
		i += 1

	if not lib.has_record("physics_process_vs_process"):
		failures.append("physics_process_vs_process missing")
	if not lib.has_record("collision_layer_vs_mask"):
		failures.append("collision_layer_vs_mask missing")
	if not lib.has_record("get_nodes_in_group"):
		failures.append("get_nodes_in_group missing")

	# Spot-check token matching.
	var m1: Array = lib.records_matching_tokens(["collision"])
	if m1.is_empty():
		failures.append("'collision' token should match records")
	var m2: Array = lib.records_matching_tokens(["animation"])
	if m2.is_empty():
		failures.append("'animation' token should match records")

	print("")
	if failures.is_empty():
		print("OK — all assertions passed (%d records, %d categories)" % [arr.size(), actual.size()])
	else:
		print("FAILED — %d issues:" % failures.size())
		i = 0
		while i < failures.size():
			print("  " + failures[i])
			i += 1

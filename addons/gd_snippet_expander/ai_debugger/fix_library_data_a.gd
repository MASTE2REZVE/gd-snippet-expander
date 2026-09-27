# res://addons/gd_snippet_expander/ai_debugger/fix_library_data_a.gd
@tool
class_name FixLibraryDataA
extends RefCounted

## Fix records, volume A: movement, camera, input, jump, dash.
##
## Part of the GD Snippet Expander mini AI debugger (v1.6).
## Thirty-nine curated records covering the most common problems
## users hit when building player controllers in 2D and 3D.
##
## Usage from the plugin loader:
##   var lib := FixLibrary.new()
##   lib.load_all()                     # starter set
##   FixLibraryDataA.register_into(lib) # this file
##   FixLibraryDataB.register_into(lib) # ... etc
##
## Every record follows the schema documented in fix_library.gd.
## This file never touches the FixLibrary internals directly — it
## only calls register_into().

# --- public entry points -----------------------------------------------

## Registers every record in this file into `lib`. Returns the count
## of accepted records (validation failures are logged in lib).
static func register_into(lib: FixLibrary) -> int:
	return lib.register_records(records())


## Returns the raw array of records. Exposed so the self-test can
## inspect them without going through a FixLibrary instance.
static func records() -> Array:
	var out: Array = []

	# ===================================================================
	# MOVEMENT (22)
	# ===================================================================

	out.append({
		"id": "coyote_time_2d",
		"title": "Coyote time for platformer jumps",
		"category": "movement",
		"phrases": [
			"player falls off ledge before jumping",
			"jump feels unresponsive at edges",
			"coyote time",
			"jump grace period",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "is_on_floor"},
			{"kind": "substring", "value": "coyote", "negate": true},
		],
		"candidates": [{
			"code": "var coyote_time: float = 0.15\nvar time_since_floor: float = 0.0\n\nfunc _physics_process(delta: float) -> void:\n\tif is_on_floor():\n\t\ttime_since_floor = 0.0\n\telse:\n\t\ttime_since_floor += delta\n\tif Input.is_action_just_pressed(\"jump\") and time_since_floor <= coyote_time:\n\t\tvelocity.y = jump_velocity\n",
			"description": "Store how long it's been since the body last touched the floor. Allow jumping within a short window after walking off an edge.",
			"confidence": 0.72,
		}],
		"related": ["is_on_floor_missing", "jump_buffer_2d"],
	})

	out.append({
		"id": "jump_buffer_2d",
		"title": "Input buffer for jump presses",
		"category": "movement",
		"phrases": [
			"jump ignored when pressed early",
			"pressing jump before landing does nothing",
			"jump buffer",
			"input buffering",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "is_action_just_pressed"},
			{"kind": "substring", "value": "buffer", "negate": true},
		],
		"candidates": [{
			"code": "var jump_buffer_time: float = 0.1\nvar jump_buffer_counter: float = 0.0\n\nfunc _physics_process(delta: float) -> void:\n\tif Input.is_action_just_pressed(\"jump\"):\n\t\tjump_buffer_counter = jump_buffer_time\n\tif jump_buffer_counter > 0.0:\n\t\tjump_buffer_counter -= delta\n\t\tif is_on_floor():\n\t\t\tvelocity.y = jump_velocity\n\t\t\tjump_buffer_counter = 0.0\n",
			"description": "Remember a jump press for a short window. If the player lands during that window, the jump fires immediately.",
			"confidence": 0.70,
		}],
		"related": ["coyote_time_2d", "is_on_floor_missing"],
	})

	out.append({
		"id": "variable_jump_height",
		"title": "Variable jump height on button release",
		"category": "movement",
		"phrases": [
			"jump is always the same height",
			"want short tap for small jump",
			"variable jump",
			"jump cut",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "jump_velocity"},
			{"kind": "substring", "value": "jump_cut", "negate": true},
		],
		"candidates": [{
			"code": "if Input.is_action_just_released(\"jump\") and velocity.y < 0.0:\n\tvelocity.y *= 0.5\n",
			"description": "When the jump button is released while the body is still rising, cut upward velocity in half. Short taps produce small jumps; holds produce full jumps.",
			"confidence": 0.65,
		}],
		"related": ["jump_velocity_setup"],
	})

	out.append({
		"id": "air_control_2d",
		"title": "Reduced air control while airborne",
		"category": "movement",
		"phrases": [
			"player turns too fast in air",
			"air control",
			"movement feels the same in air",
			"want different air handling",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "move_and_slide"},
			{"kind": "substring", "value": "is_on_floor()", "negate": false},
		],
		"candidates": [{
			"code": "var target_speed: float = direction * speed\nif not is_on_floor():\n\ttarget_speed *= 0.4\nvelocity.x = move_toward(velocity.x, target_speed, accel * delta)\n",
			"description": "Blend the horizontal target toward a smaller value while airborne. Gives weight to jumps without removing air control entirely.",
			"confidence": 0.55,
		}],
	})

	out.append({
		"id": "wall_slide_2d",
		"title": "Wall slide for 2D platformers",
		"category": "movement",
		"phrases": [
			"wall slide",
			"slide down walls slowly",
			"stick to wall when touching",
			"wall grab",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "is_on_wall"},
			{"kind": "substring", "value": "wall_slide", "negate": true},
		],
		"candidates": [{
			"code": "var wall_slide_speed: float = 50.0\n\nfunc _physics_process(delta: float) -> void:\n\tif not is_on_floor() and is_on_wall() and velocity.y > 0.0:\n\t\tvelocity.y = min(velocity.y, wall_slide_speed)\n",
			"description": "Cap downward velocity while touching a wall. The character still falls, but slower, giving the player time to wall-jump.",
			"confidence": 0.68,
		}],
		"related": ["wall_jump_2d"],
	})

	out.append({
		"id": "wall_jump_2d",
		"title": "Wall jump pushes away from wall",
		"category": "movement",
		"phrases": [
			"wall jump",
			"jump off walls",
			"bounce away from wall",
			"wall kick",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "is_on_wall"},
		],
		"candidates": [{
			"code": "var wall_jump_velocity: Vector2 = Vector2(300.0, -400.0)\n\nif is_on_wall() and Input.is_action_just_pressed(\"jump\"):\n\tvelocity = Vector2(-get_wall_normal().x * wall_jump_velocity.x, wall_jump_velocity.y)\n",
			"description": "Use get_wall_normal() to detect which side the wall is on, then fire velocity away from it and upward.",
			"confidence": 0.62,
		}],
		"related": ["wall_slide_2d"],
	})

	out.append({
		"id": "dash_2d",
		"title": "Horizontal dash with cooldown",
		"category": "movement",
		"phrases": [
			"dash",
			"quick burst forward",
			"dash mechanic",
			"dash cooldown",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "dash"}
		],
		"candidates": [{
			"code": "var dash_speed: float = 800.0\nvar dash_duration: float = 0.15\nvar dash_cooldown: float = 0.5\nvar _dash_timer: float = 0.0\nvar _cooldown_timer: float = 0.0\n\nfunc try_dash(direction: Vector2) -> void:\n\tif _cooldown_timer > 0.0:\n\t\treturn\n\tvelocity = direction.normalized() * dash_speed\n\t_dash_timer = dash_duration\n\t_cooldown_timer = dash_cooldown\n",
			"description": "Set velocity to a high fixed value for a short duration, then lock out further dashes for a cooldown period.",
			"confidence": 0.60,
		}],
		"related": ["dash_cooldown_ui", "dash_iframes"],
	})

	out.append({
		"id": "dash_air_2d",
		"title": "Air dash limited to once per jump",
		"category": "movement",
		"phrases": [
			"air dash",
			"limit air dash to one per jump",
			"cannot dash twice in air",
			"double dash prevention",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "dash"}
		],
		"candidates": [{
			"code": "var _air_dashes_left: int = 1\n\nfunc try_dash(direction: Vector2) -> void:\n\tif not is_on_floor():\n\t\tif _air_dashes_left <= 0:\n\t\t\treturn\n\t\t_air_dashes_left -= 1\n\tvelocity = direction.normalized() * dash_speed\n\nfunc _on_landed() -> void:\n\t_air_dashes_left = 1\n",
			"description": "Reset the air-dash counter on landing. Decrement it each time an air dash is used, and refuse if the counter is already zero.",
			"confidence": 0.58,
		}],
		"related": ["dash_2d"],
	})

	out.append({
		"id": "sprint_toggle",
		"title": "Toggle sprint vs hold to sprint",
		"category": "movement",
		"phrases": [
			"sprint toggle",
			"hold to run",
			"toggle run key",
			"sprint mode",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "sprint"}
		],
		"candidates": [{
			"code": "var _sprinting: bool = false\n\nfunc _input(event: InputEvent) -> void:\n\tif event.is_action_pressed(\"sprint\"):\n\t\t_sprinting = not _sprinting\n",
			"description": "Track sprint state yourself and flip it on each press. Use `event.is_action_pressed` (not `just_pressed` in `_physics_process`) so the toggle fires once per key press.",
			"confidence": 0.52,
		}],
	})

	out.append({
		"id": "crouch_2d",
		"title": "Crouch shrinks collision and slows movement",
		"category": "movement",
		"phrases": [
			"crouch",
			"shrink when crouching",
			"crouch mechanic",
			"crouching collision",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "crouch"}
		],
		"candidates": [{
			"code": "var _crouching: bool = false\nvar _stand_height: float = 60.0\nvar _crouch_height: float = 30.0\n\nfunc _set_crouch(state: bool) -> void:\n\t_crouching = state\n\tvar shape: CapsuleShape2D = $CollisionShape2D.shape as CapsuleShape2D\n\tshape.height = _crouch_height if state else _stand_height\n",
			"description": "Swap the collision shape's height when crouching. Also apply a movement speed multiplier in your input handler.",
			"confidence": 0.55,
		}],
	})

	out.append({
		"id": "slope_slide_2d",
		"title": "Slide down steep slopes",
		"category": "movement",
		"phrases": [
			"character sticks to slopes",
			"slide on steep ground",
			"slope handling",
			"gravity on slopes",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "move_and_slide"},
			{"kind": "identifier", "value": "floor_max_angle", "negate": true},
		],
		"candidates": [{
			"code": "var min_slide_angle: float = deg_to_rad(45.0)\n\nfunc _physics_process(delta: float) -> void:\n\tif is_on_floor():\n\t\tvar normal: Vector2 = get_floor_normal()\n\t\tvar slope_angle: float = normal.angle_to(Vector2.UP)\n\t\tif slope_angle > min_slide_angle:\n\t\t\tvelocity.x += normal.x * 500.0 * delta\n",
			"description": "Check the floor normal each frame. When it tilts past a threshold, add a horizontal push in the direction of the slope.",
			"confidence": 0.50,
		}],
	})

	out.append({
		"id": "max_fall_speed",
		"title": "Terminal velocity cap",
		"category": "movement",
		"phrases": [
			"player falls too fast",
			"cap fall speed",
			"terminal velocity",
			"fall speed limit",
		],
		"code_patterns": [
			{"kind": "substring", "value": "velocity.y -= gravity", "negate": false},
			{"kind": "identifier", "value": "max_fall_speed", "negate": true},
		],
		"candidates": [{
			"code": "var max_fall_speed: float = 600.0\n\nif not is_on_floor():\n\tvelocity.y = min(velocity.y + gravity * delta, max_fall_speed)\n",
			"description": "Clamp downward velocity so it never exceeds a chosen cap. Prevents the player from clipping through platforms at high speed.",
			"confidence": 0.60,
		}],
	})

	out.append({
		"id": "jump_velocity_setup",
		"title": "Jump velocity from desired height",
		"category": "movement",
		"phrases": [
			"jump height",
			"calculate jump velocity",
			"how high should jump be",
			"jump too low",
			"jump too high",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "jump_velocity"}
		],
		"candidates": [{
			"code": "var jump_height: float = 150.0   # pixels, desired peak\nvar gravity: float = 980.0\nvar jump_velocity: float = sqrt(2.0 * gravity * jump_height)\n",
			"description": "Given a target height and gravity, jump_velocity is `sqrt(2 * g * h)`. Change height to tune the jump feel instead of guessing at velocity.",
			"confidence": 0.72,
		}],
	})

	out.append({
		"id": "double_jump_2d",
		"title": "Double jump with reset on landing",
		"category": "movement",
		"phrases": [
			"double jump",
			"jump twice in air",
			"extra jump",
			"air jump",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "jump"}
		],
		"candidates": [{
			"code": "var max_jumps: int = 2\nvar _jumps_left: int = 2\n\nfunc _physics_process(delta: float) -> void:\n\tif is_on_floor():\n\t\t_jumps_left = max_jumps\n\telif Input.is_action_just_pressed(\"jump\") and _jumps_left > 0:\n\t\tvelocity.y = jump_velocity\n\t\t_jumps_left -= 1\n",
			"description": "Track a jump counter. Reset it on landing. Decrement on each jump and refuse once it hits zero.",
			"confidence": 0.68,
		}],
	})

	out.append({
		"id": "jump_cut_on_release",
		"title": "Cut jump when button released",
		"category": "movement",
		"phrases": [
			"jump feels floaty",
			"jump too long",
			"jump cut",
			"short hop",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "jump"}
		],
		"candidates": [{
			"code": "var jump_cut_factor: float = 0.5\n\nfunc _physics_process(delta: float) -> void:\n\tif Input.is_action_just_released(\"jump\") and velocity.y < 0.0:\n\t\tvelocity.y *= jump_cut_factor\n",
			"description": "When the player releases jump while still rising, multiply the upward velocity by a factor below 1. Short taps produce short jumps.",
			"confidence": 0.65,
		}],
		"related": ["variable_jump_height"],
	})

	out.append({
		"id": "jump_particles_land",
		"title": "Dust particles on landing",
		"category": "movement",
		"phrases": [
			"dust on landing",
			"landing puff",
			"particles when landing",
			"impact effect on ground",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "is_on_floor"},
			{"kind": "substring", "value": "GPUParticles2D", "negate": true},
		],
		"candidates": [{
			"code": "var _was_on_floor: bool = true\n\nfunc _physics_process(delta: float) -> void:\n\tif is_on_floor() and not _was_on_floor:\n\t\t$LandDust.emitting = true\n\t_was_on_floor = is_on_floor()\n",
			"description": "Track the previous floor state. When it flips from false to true, trigger the particle emitter once.",
			"confidence": 0.62,
		}],
	})

	out.append({
		"id": "jump_particles_takeoff",
		"title": "Puff on jump takeoff",
		"category": "movement",
		"phrases": [
			"puff on jump",
			"jump particle effect",
			"jump dust",
			"takeoff effect",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "jump"}
		],
		"candidates": [{
			"code": "if Input.is_action_just_pressed(\"jump\") and is_on_floor():\n\tvelocity.y = jump_velocity\n\t$JumpPuff.restart()\n\t$JumpPuff.emitting = true\n",
			"description": "Call restart() before setting emitting so the emitter plays from the start even if it was already playing.",
			"confidence": 0.58,
		}],
	})

	out.append({
		"id": "jump_sound_pitch_variation",
		"title": "Random pitch on repeated sound",
		"category": "movement",
		"phrases": [
			"sound is repetitive",
			"jump sound same every time",
			"vary pitch of sound",
			"sound variation",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "AudioStreamPlayer"}
		],
		"candidates": [{
			"code": "var base_pitch: float = 1.0\nvar pitch_variation: float = 0.15\n\nfunc play_jump_sound() -> void:\n\t$JumpSound.pitch_scale = base_pitch + randf_range(-pitch_variation, pitch_variation)\n\t$JumpSound.play()\n",
			"description": "Randomize pitch_scale slightly on each play. A ±15% variation is enough to sound varied without sounding wrong.",
			"confidence": 0.62,
		}],
	})

	out.append({
		"id": "landing_recovery_time",
		"title": "Brief input lock on hard landing",
		"category": "movement",
		"phrases": [
			"heavy landing",
			"input lock on landing",
			"recovery time",
			"stun on land",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "is_on_floor"}
		],
		"candidates": [{
			"code": "var hard_landing_speed: float = 500.0\nvar recovery_time: float = 0.2\nvar _recovery_timer: float = 0.0\n\nfunc _physics_process(delta: float) -> void:\n\tif is_on_floor() and not _was_on_floor:\n\t\tif _prev_fall_speed > hard_landing_speed:\n\t\t\t_recovery_timer = recovery_time\n\t\t_prev_fall_speed = 0.0\n\telse:\n\t\t_prev_fall_speed = abs(velocity.y)\n\t_recovery_timer = max(_recovery_timer - delta, 0.0)\n\tif _recovery_timer > 0.0:\n\t\treturn\n\t# normal input handling below\n",
			"description": "Record the fall speed just before landing. If it exceeded a threshold, block input for a moment. Gives hard landings weight.",
			"confidence": 0.52,
		}],
	})

	out.append({
		"id": "dash_iframes",
		"title": "Brief invulnerability during dash",
		"category": "movement",
		"phrases": [
			"invincibility during dash",
			"dash i-frames",
			"invulnerable while dashing",
			"dash through attacks",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "dash"},
			{"kind": "identifier", "value": "invulnerable", "negate": true},
		],
		"candidates": [{
			"code": "var _invulnerable: bool = false\n\nfunc try_dash(direction: Vector2) -> void:\n\tvelocity = direction.normalized() * dash_speed\n\t_invulnerable = true\n\tawait get_tree().create_timer(dash_duration).timeout\n\t_invulnerable = false\n\nfunc take_damage(amount: int) -> void:\n\tif _invulnerable:\n\t\treturn\n\thealth -= amount\n",
			"description": "Set a flag during the dash and check it in your damage handler. The await timer clears it automatically when the dash ends.",
			"confidence": 0.60,
		}],
		"related": ["dash_2d"],
	})

	out.append({
		"id": "dash_direction_8way",
		"title": "Eight-way directional dash",
		"category": "movement",
		"phrases": [
			"8-way dash",
			"dash in any direction",
			"direction dash",
			"omnidirectional dash",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "dash"}
		],
		"candidates": [{
			"code": "func try_dash() -> void:\n\tvar dir: Vector2 = Input.get_vector(\"left\", \"right\", \"up\", \"down\")\n\tif dir == Vector2.ZERO:\n\t\tdir = Vector2.RIGHT * (1.0 if not $Sprite2D.flip_h else -1.0)\n\tvelocity = dir.normalized() * dash_speed\n",
			"description": "Read the input vector. If the player isn't pressing a direction, fall back to facing direction.",
			"confidence": 0.58,
		}],
		"related": ["dash_2d"],
	})

	out.append({
		"id": "dash_cancel_into_attack",
		"title": "Cancel dash into attack",
		"category": "movement",
		"phrases": [
			"cancel dash into attack",
			"dash attack combo",
			"attack during dash",
			"chain dash to attack",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "dash"},
			{"kind": "identifier", "value": "attack"}
		],
		"candidates": [{
			"code": "func _physics_process(delta: float) -> void:\n\tif _dash_timer > 0.0:\n\t\t_dash_timer -= delta\n\t\tif Input.is_action_just_pressed(\"attack\"):\n\t\t\t_dash_timer = 0.0\n\t\t\tstart_attack()\n\t\treturn\n\t# normal input\n",
			"description": "While dashing, check for the attack input. If pressed, end the dash early and start the attack. Chain feels responsive.",
			"confidence": 0.52,
		}],
		"related": ["dash_2d"],
	})

	# ===================================================================
	# CAMERA (9)
	# ===================================================================

	out.append({
		"id": "camera_follow_smooth",
		"title": "Smooth camera follow with lerp",
		"category": "camera",
		"phrases": [
			"camera follows player",
			"smooth camera",
			"camera lag",
			"camera snaps to player",
		],
		"code_patterns": [
			{"kind": "substring", "value": "global_position = target.global_position", "negate": false},
		],
		"candidates": [{
			"code": "var target: Node2D = null\nvar follow_speed: float = 5.0\n\nfunc _process(delta: float) -> void:\n\tif target == null:\n\t\treturn\n\tglobal_position = global_position.lerp(target.global_position, follow_speed * delta)\n",
			"description": "Lerp the camera's position toward the target each frame. Higher follow_speed means the camera catches up faster.",
			"confidence": 0.72,
		}],
		"related": ["camera_deadzone", "camera_lookahead"],
	})

	out.append({
		"id": "camera_deadzone",
		"title": "Camera deadzone before following",
		"category": "camera",
		"phrases": [
			"camera jitters on small movement",
			"camera deadzone",
			"camera doesn't move for small inputs",
			"dead zone camera",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "Camera2D"},
			{"kind": "substring", "value": "deadzone", "negate": true},
		],
		"candidates": [{
			"code": "var deadzone: float = 20.0\n\nfunc _process(delta: float) -> void:\n\tif target == null:\n\t\treturn\n\tvar diff: Vector2 = target.global_position - global_position\n\tif diff.length() > deadzone:\n\t\tvar target_pos: Vector2 = target.global_position - diff.normalized() * deadzone\n\t\tglobal_position = global_position.lerp(target_pos, 5.0 * delta)\n",
			"description": "Ignore movement smaller than a chosen radius. The camera only starts following once the target crosses the deadzone boundary.",
			"confidence": 0.62,
		}],
		"related": ["camera_follow_smooth"],
	})

	out.append({
		"id": "camera_lookahead",
		"title": "Camera looks ahead based on velocity",
		"category": "camera",
		"phrases": [
			"camera looks ahead",
			"show where player is going",
			"camera look ahead",
			"leading camera",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "lookahead", "negate": true},
		],
		"candidates": [{
			"code": "var lookahead_factor: float = 0.3\n\nfunc _process(delta: float) -> void:\n\tif target == null:\n\t\treturn\n\tvar offset: Vector2 = target.velocity * lookahead_factor\n\tglobal_position = global_position.lerp(target.global_position + offset, 5.0 * delta)\n",
			"description": "Add a velocity-scaled offset to the camera target so it leans in the direction the player is moving.",
			"confidence": 0.55,
		}],
		"related": ["camera_follow_smooth"],
	})

	out.append({
		"id": "camera_shake",
		"title": "Trauma-based camera shake",
		"category": "camera",
		"phrases": [
			"camera shake",
			"screen shake on hit",
			"shake effect",
			"add screen shake",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "shake"}
		],
		"candidates": [{
			"code": "var trauma: float = 0.0\nvar max_offset: Vector2 = Vector2(20.0, 20.0)\nvar decay: float = 1.5\n\nfunc add_trauma(amount: float) -> void:\n\ttrauma = min(trauma + amount, 1.0)\n\nfunc _process(delta: float) -> void:\n\ttrauma = max(trauma - decay * delta, 0.0)\n\tvar shake: float = trauma * trauma\n\toffset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * max_offset * shake\n",
			"description": "Trauma decays over time and squares to produce a falloff that feels natural. Call add_trauma(0.5) on impact.",
			"confidence": 0.68,
		}],
	})

	out.append({
		"id": "camera_limits_2d",
		"title": "Camera clamped to level bounds",
		"category": "camera",
		"phrases": [
			"camera shows outside level",
			"camera goes past edges",
			"camera limits",
			"camera bounds",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "Camera2D"},
			{"kind": "identifier", "value": "limit_left", "negate": true},
		],
		"candidates": [{
			"code": "# In the editor, select the Camera2D and set limit_left,\n# limit_top, limit_right, limit_bottom in the inspector.\n# Or from code:\nlimit_left = 0\nlimit_top = 0\nlimit_right = 1920\nlimit_bottom = 1080\n",
			"description": "Camera2D has built-in limit_ properties. Set them to the level's pixel bounds and the camera stops at those edges automatically.",
			"confidence": 0.75,
		}],
	})

	out.append({
		"id": "camera_zoom_smooth",
		"title": "Smooth zoom transition",
		"category": "camera",
		"phrases": [
			"smooth camera zoom",
			"zoom in effect",
			"camera zooms instantly",
			"lerp camera zoom",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "zoom"}
		],
		"candidates": [{
			"code": "var target_zoom: Vector2 = Vector2.ONE\nvar zoom_speed: float = 5.0\n\nfunc _process(delta: float) -> void:\n\tzoom = zoom.lerp(target_zoom, zoom_speed * delta)\n",
			"description": "Lerp the zoom vector toward a target each frame instead of snapping. Set target_zoom to change the zoom level.",
			"confidence": 0.60,
		}],
	})

	out.append({
		"id": "camera_mouse_look_3d",
		"title": "Mouse look with pitch clamp",
		"category": "camera",
		"phrases": [
			"mouse look",
			"first person camera",
			"camera flips upside down",
			"pitch clamp",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "Camera3D"},
			{"kind": "identifier", "value": "rotation.x", "negate": false},
		],
		"candidates": [{
			"code": "var sensitivity: float = 0.002\nvar pitch_min: float = deg_to_rad(-89.0)\nvar pitch_max: float = deg_to_rad(89.0)\n\nfunc _unhandled_input(event: InputEvent) -> void:\n\tif event is InputEventMouseMotion:\n\t\trotate_y(-event.relative.x * sensitivity)\n\t\trotation.x = clamp(rotation.x - event.relative.y * sensitivity, pitch_min, pitch_max)\n",
			"description": "Yaw rotates the body (or the camera itself), pitch rotates only the camera. Clamp pitch to ±89 degrees so the camera can't flip over.",
			"confidence": 0.78,
		}],
	})

	out.append({
		"id": "camera_smooth_3d",
		"title": "Third-person camera smoothing with SpringArm3D",
		"category": "camera",
		"phrases": [
			"third person camera",
			"camera follows behind player",
			"spring arm camera",
			"camera behind character",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "Camera3D"},
			{"kind": "identifier", "value": "SpringArm3D", "negate": true},
		],
		"candidates": [{
			"code": "# Scene tree:\n#   Player (CharacterBody3D)\n#     SpringArm3D (spring_length = 4, rotation.x = -15 degrees)\n#       Camera3D\n#\n# Rotate the SpringArm3D for yaw/pitch. Camera3D just sits at the tip.\n",
			"description": "SpringArm3D pushes the camera back and automatically pulls it in when a wall is behind the player. Way easier than doing it manually.",
			"confidence": 0.72,
		}],
	})

	out.append({
		"id": "dash_camera_zoom",
		"title": "Subtle camera zoom during dash",
		"category": "camera",
		"phrases": [
			"zoom during dash",
			"camera punch on dash",
			"dash effect camera",
			"zoom out on dash",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "dash"}
		],
		"candidates": [{
			"code": "var normal_zoom: Vector2 = Vector2.ONE\nvar dash_zoom: Vector2 = Vector2(0.9, 0.9)\n\nfunc try_dash(direction: Vector2) -> void:\n\t# ... dash logic ...\n\ttarget_zoom = dash_zoom\n\tawait get_tree().create_timer(dash_duration).timeout\n\ttarget_zoom = normal_zoom\n",
			"description": "Temporarily set the camera's target_zoom (see camera_zoom_smooth) and let the existing lerp handle the transition.",
			"confidence": 0.48,
		}],
		"related": ["camera_zoom_smooth"],
	})

	# ===================================================================
	# INPUT (6)
	# ===================================================================

	out.append({
		"id": "input_deadzone_analog",
		"title": "Analog stick deadzone",
		"category": "input",
		"phrases": [
			"controller drifts",
			"stick drift",
			"analog deadzone",
			"joystick moves on its own",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "get_vector"}
		],
		"candidates": [{
			"code": "var raw_input: Vector2 = Input.get_vector(\"left\", \"right\", \"up\", \"down\")\nvar deadzone: float = 0.2\nvar direction: Vector2 = raw_input if raw_input.length() > deadzone else Vector2.ZERO\n",
			"description": "Ignore small stick values so worn controllers don't cause the character to drift.",
			"confidence": 0.65,
		}],
	})

	out.append({
		"id": "input_remap_runtime",
		"title": "Remap input actions at runtime",
		"category": "input",
		"phrases": [
			"rebind keys",
			"custom controls",
			"key remap",
			"input settings",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "action_erase_events", "negate": true},
		],
		"candidates": [{
			"code": "func rebind_action(action: StringName, new_event: InputEvent) -> void:\n\tInputMap.action_erase_events(action)\n\tInputMap.action_add_event(action, new_event)\n",
			"description": "InputMap lets you clear and re-add events for any action at runtime. Persist the changes by saving the events to a config file.",
			"confidence": 0.55,
		}],
	})

	out.append({
		"id": "input_controller_detection",
		"title": "Detect controller connect/disconnect",
		"category": "input",
		"phrases": [
			"detect controller",
			"switch to controller input",
			"gamepad connected",
			"controller support",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "Input.joy_connection_changed", "negate": true},
		],
		"candidates": [{
			"code": "func _ready() -> void:\n\tInput.joy_connection_changed.connect(_on_joy_changed)\n\nfunc _on_joy_changed(device: int, connected: bool) -> void:\n\tif connected:\n\t\tprint(\"Controller connected: \", Input.get_joy_name(device))\n",
			"description": "Input emits joy_connection_changed whenever a gamepad is plugged in or removed. Hook it to swap your UI prompts.",
			"confidence": 0.62,
		}],
	})

	out.append({
		"id": "input_touch_button_2d",
		"title": "Touch button for mobile input",
		"category": "input",
		"phrases": [
			"touch controls",
			"mobile buttons",
			"on screen buttons",
			"touch input",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "TouchScreenButton"}
		],
		"candidates": [{
			"code": "# Add a TouchScreenButton node as a child of a CanvasLayer.\n# Set its texture_normal in the inspector.\n# Set its action to the input action name (e.g. \"jump\").\n# Bind the action in Project Settings -> Input Map.\n",
			"description": "TouchScreenButton fires an input action when pressed. No code needed — connect it to an existing action name and the rest of your controller works unchanged.",
			"confidence": 0.70,
		}],
	})

	out.append({
		"id": "input_hold_vs_press",
		"title": "Distinguish hold from press",
		"category": "input",
		"phrases": [
			"hold vs tap",
			"long press",
			"hold to charge",
			"detect held button",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "is_action_pressed"}
		],
		"candidates": [{
			"code": "var hold_time: float = 0.5\nvar _held: float = 0.0\nvar _fired: bool = false\n\nfunc _process(delta: float) -> void:\n\tif Input.is_action_pressed(\"action\"):\n\t\t_held += delta\n\t\tif _held >= hold_time and not _fired:\n\t\t\t_fired = true\n\t\t\ton_long_press()\n\telse:\n\t\tif _held > 0.0 and not _fired:\n\t\t\ton_short_press()\n\t\t_held = 0.0\n\t\t_fired = false\n",
			"description": "Track how long the button has been down. Fire one event or the other when it's released, depending on the duration.",
			"confidence": 0.58,
		}],
	})

	out.append({
		"id": "input_double_tap",
		"title": "Double-tap detection",
		"category": "input",
		"phrases": [
			"double tap",
			"double tap to dash",
			"detect double press",
			"double click input",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "double_tap", "negate": true},
		],
		"candidates": [{
			"code": "var double_tap_window: float = 0.25\nvar _last_tap_time: float = -1.0\n\nfunc _input(event: InputEvent) -> void:\n\tif event.is_action_pressed(\"dash\"):\n\t\tvar now: float = Time.get_ticks_msec() / 1000.0\n\t\tif now - _last_tap_time < double_tap_window:\n\t\t\ton_double_tap()\n\t\t\t_last_tap_time = -1.0\n\t\telse:\n\t\t\t_last_tap_time = now\n",
			"description": "Compare the timestamp of the previous press to the current one. If they're close enough, treat it as a double tap.",
			"confidence": 0.55,
		}],
	})

	# ===================================================================
	# UI (1)
	# ===================================================================

	out.append({
		"id": "dash_cooldown_ui",
		"title": "Cooldown indicator for dash",
		"category": "ui",
		"phrases": [
			"dash cooldown bar",
			"show dash ready",
			"dash ui",
			"cooldown indicator",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "dash"}
		],
		"candidates": [{
			"code": "# Add a TextureProgressBar to a CanvasLayer.\n# In the player's _process:\nvar ratio: float = 1.0 - (_cooldown_timer / dash_cooldown)\n$UI/DashBar.value = ratio * 100.0\n",
			"description": "Drive a progress bar from the dash cooldown timer. When the bar fills, the dash is ready.",
			"confidence": 0.55,
		}],
		"related": ["dash_2d"],
	})

	# ===================================================================
	# ANIMATION (1)
	# ===================================================================

	out.append({
		"id": "dash_trail",
		"title": "Afterimage trail during dash",
		"category": "animation",
		"phrases": [
			"dash trail",
			"afterimage",
			"motion trail",
			"ghost trail",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "dash"},
			{"kind": "substring", "value": "trail", "negate": true},
		],
		"candidates": [{
			"code": "# Simplest trail: a Line2D that follows the player.\n# Add a Line2D node named \"Trail\" as a child of the player.\n# Configure width and gradient in the inspector.\n\nfunc _process(delta: float) -> void:\n\t$Trail.add_point(global_position)\n\tif $Trail.get_point_count() > 20:\n\t\t$Trail.remove_point(0)\n",
			"description": "Line2D keeps a running list of points. Adding the current position each frame gives a smooth trail; removing old points keeps it short.",
			"confidence": 0.55,
		}],
	})

	return out


# --- self-test ----------------------------------------------------------

## Registers this file into a fresh FixLibrary and verifies the
## records are valid, unique, and cover the expected categories.
## Pass condition: "OK" printed at the end.
static func self_test() -> void:
	print("=== FixLibraryDataA self-test ===")
	var failures: Array[String] = []

	var arr: Array = records()
	if arr.size() != 39:
		failures.append("1: expected 39 records, got %d" % arr.size())

	# Build a fresh library and register everything from this file.
	var lib: FixLibrary = FixLibrary.new()
	lib.load_all()
	var added: int = register_into(lib)
	if added != arr.size():
		failures.append("2: register_into accepted %d of %d" % [added, arr.size()])
	if not lib.reject_log().is_empty():
		failures.append("2: %d rejects during registration" % lib.reject_log().size())

	# Categories represented by this data file, with expected counts.
	var expected: Dictionary = {
		"movement": 22,
		"camera": 9,
		"input": 6,
		"ui": 1,
		"animation": 1,
	}
	var actual: Dictionary = {}
	var i: int = 0
	while i < arr.size():
		var rec: Dictionary = arr[i]
		var cat: String = str(rec.get("category", ""))
		actual[cat] = int(actual.get(cat, 0)) + 1
		i += 1

	var keys: Array = expected.keys()
	i = 0
	while i < keys.size():
		var k: String = str(keys[i])
		var want: int = int(expected[k])
		var got: int = int(actual.get(k, 0))
		if want != got:
			failures.append("3: category '%s' expected %d, got %d" % [k, want, got])
		i += 1

	# Every ID must be unique within this file.
	var seen: Dictionary = {}
	i = 0
	while i < arr.size():
		var id: String = str(arr[i].get("id", ""))
		if seen.has(id):
			failures.append("4: duplicate id '%s'" % id)
		seen[id] = true
		i += 1

	# A couple of specific lookups should work through the library.
	if not lib.has_record("coyote_time_2d"):
		failures.append("5: coyote_time_2d missing after register")
	if not lib.has_record("camera_mouse_look_3d"):
		failures.append("5: camera_mouse_look_3d missing")
	if not lib.has_record("dash_iframes"):
		failures.append("5: dash_iframes missing")

	# Phrase-based pre-filter should find relevant records.
	var m1: Array = lib.records_matching_tokens(["jump"])
	if not ("coyote_time_2d" in m1):
		failures.append("6: 'jump' token should match coyote_time_2d")
	if not ("jump_buffer_2d" in m1):
		failures.append("6: 'jump' token should match jump_buffer_2d")
	var m2: Array = lib.records_matching_tokens(["dash"])
	if not ("dash_2d" in m2):
		failures.append("6: 'dash' token should match dash_2d")

	# Every record should have at least one candidate with a
	# confidence in [0, 1].
	i = 0
	while i < arr.size():
		var rec2: Dictionary = arr[i]
		var rid: String = str(rec2.get("id", "?"))
		var cands: Array = rec2.get("candidates", [])
		if cands.is_empty():
			failures.append("7: '%s' has no candidates" % rid)
		else:
			var c: Dictionary = cands[0]
			var conf: float = float(c.get("confidence", -1.0))
			if conf < 0.0 or conf > 1.0:
				failures.append("7: '%s' candidate confidence out of range (%f)" % [rid, conf])
		i += 1

	print("")
	if failures.is_empty():
		print("OK — all assertions passed")
	else:
		print("FAILED — %d issues:" % failures.size())
		i = 0
		while i < failures.size():
			print("  " + failures[i])
			i += 1

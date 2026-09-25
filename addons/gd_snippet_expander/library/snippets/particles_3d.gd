@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"snippets": {
			"particle_explosion_3d": {
				"phrases": ["particle explosion 3d", "3d explosion", "burst particles 3d", "explode 3d"],
				"code": """extends Node3D

@export var particle_count: int = 60
@export var burst_speed: float = 8.0
@export var particle_lifetime: float = 0.8
@export var particle_color: Color = Color(1.0, 0.6, 0.2)
@export var particle_radius: float = 0.15

func _ready() -> void:
	var particles := GPUParticles3D.new()
	particles.amount = particle_count
	particles.lifetime = particle_lifetime
	particles.one_shot = true
	particles.explosiveness = 1.0
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 90.0
	mat.initial_velocity_min = burst_speed * 0.5
	mat.initial_velocity_max = burst_speed
	mat.gravity = Vector3(0, -9.8, 0)
	mat.color = particle_color
	mat.scale_min = 0.3
	mat.scale_max = 0.6
	particles.process_material = mat
	var mesh := SphereMesh.new()
	mesh.radius = particle_radius
	mesh.height = particle_radius * 2.0
	particles.draw_pass_1 = mesh
	add_child(particles)
	particles.emitting = true
	await get_tree().create_timer(particle_lifetime + 0.5).timeout
	queue_free()

# USAGE
# var explosion := preload("res://scenes/effects/explosion_3d.tscn").instantiate()
# get_tree().current_scene.add_child(explosion)
# explosion.global_position = hit_position
#
# The particle emits once and the node auto-deletes.
# For colored variants, use particle_color export.
""",
				"params": ["particle_count", "burst_speed", "particle_lifetime", "particle_color", "particle_radius"],
				"category": "particles",
				"subcategory": "3d",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "beginner",
				"param_info": {
					"particle_count": {
						"default": 60,
						"range": [10, 500],
						"what": "Number of particles in the burst.",
						"typical": "20 small / 60 standard / 200+ big explosion",
						"increase": "Denser burst.",
						"decrease": "Sparser."
					},
					"burst_speed": {
						"default": 8.0,
						"range": [2.0, 30.0],
						"what": "Maximum particle velocity in meters per second.",
						"typical": "4 small pop / 8 standard / 20+ dramatic",
						"increase": "Particles fly further.",
						"decrease": "Tighter burst."
					},
					"particle_color": {
						"default": [1, 0.6, 0.2, 1],
						"range": [],
						"what": "Color of the particles.",
						"typical": "orange fire / red damage / blue magic / white generic",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "One-shot 3D explosion with radial particles. Self-contained scene that spawns, plays, and auto-deletes.",
					"where": "Save as its own .tscn. Instantiate at hit position. No code changes needed after the scene is set up.",
					"before": "None — all particles are created in code.",
					"after": "For directional bursts (shrapnel), set mat.direction to a non-vertical vector and reduce spread.",
					"why_optimized": "GPUParticles3D handles hundreds of particles in one draw call. Self-cleaning scene.",
					"mistakes": "Using CPUParticles3D for 3D explosions is much slower than GPUParticles3D. Use GPU for any 3D particle effect.",
					"related": ["impact_particles_3d", "camera_shake_3d", "hit_feedback_3d", "rocket_3d"]
				}
			},
			"particle_trail_3d": {
				"phrases": ["particle trail 3d", "3d trail", "smoke trail 3d", "missile trail"],
				"code": """extends GPUParticles3D

@export var trail_color: Color = Color(1.0, 1.0, 1.0, 0.6)
@export var trail_lifetime: float = 0.8
@export var particle_rate: float = 30.0

func _ready() -> void:
	emitting = true
	lifetime = trail_lifetime
	amount = int(particle_rate * trail_lifetime)
	explosiveness = 0.0
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 0, 1)
	mat.spread = 15.0
	mat.initial_velocity_min = 0.5
	mat.initial_velocity_max = 1.5
	mat.gravity = Vector3.ZERO
	mat.color = trail_color
	mat.scale_min = 0.1
	mat.scale_max = 0.25
	mat.damping_min = 1.0
	mat.damping_max = 3.0
	process_material = mat
	if draw_pass_1 == null:
		var mesh := QuadMesh.new()
		mesh.size = Vector2(0.3, 0.3)
		draw_pass_1 = mesh

# USAGE
# Add as a child of a moving object (projectile, missile, dashing player).
# The particles emit continuously behind the parent.
#
# For a fading trail, animate trail_color.a over the particle lifetime
# using a Gradient or by setting mat.color_ramp.

func set_trail_color(color: Color) -> void:
	trail_color = color
	var mat := process_material as ParticleProcessMaterial
	if mat != null:
		mat.color = color
""",
				"params": ["trail_color", "trail_lifetime", "particle_rate"],
				"category": "particles",
				"subcategory": "3d",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "beginner",
				"param_info": {
					"trail_color": {
						"default": [1, 1, 1, 0.6],
						"range": [],
						"what": "Particle color and alpha.",
						"typical": "white smoke / orange fire / cyan energy / red blood",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"trail_lifetime": {
						"default": 0.8,
						"range": [0.2, 3.0],
						"what": "How long each particle lives.",
						"typical": "0.3 short / 0.8 standard / 2.0 long tail",
						"increase": "Longer tail.",
						"decrease": "Shorter."
					},
					"particle_rate": {
						"default": 30.0,
						"range": [5.0, 100.0],
						"what": "Particles emitted per second.",
						"typical": "10 sparse / 30 standard / 80+ dense",
						"increase": "Denser trail.",
						"decrease": "Sparser."
					}
				},
				"details": {
					"what": "Continuous 3D particle trail. Attach to a moving object to leave a path behind.",
					"where": "Attach as a child of a projectile, missile, or dashing character. Enable emitting in the Inspector or via script.",
					"before": "None — all setup is code.",
					"after": "For a fading tail, assign a Gradient to mat.color_ramp so particles fade to transparent as they age.",
					"why_optimized": "GPU particles handle rate independently. The damping makes particles slow down naturally.",
					"mistakes": "Using default spread causes particles to scatter in all directions. Set spread to 15 or lower for a tight trail.",
					"related": ["projectile_3d", "rocket_3d", "particle_explosion_3d"]
				}
			},
			"particle_dust_3d": {
				"phrases": ["particle dust 3d", "3d dust", "landing dust 3d", "footstep dust 3d"],
				"code": """extends Node3D

@export var dust_color: Color = Color(0.8, 0.75, 0.65, 0.7)
@export var dust_count: int = 20
@export var dust_lifetime: float = 0.6

func _ready() -> void:
	var particles := GPUParticles3D.new()
	particles.amount = dust_count
	particles.lifetime = dust_lifetime
	particles.one_shot = true
	particles.explosiveness = 1.0
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 45.0
	mat.initial_velocity_min = 0.5
	mat.initial_velocity_max = 1.5
	mat.gravity = Vector3(0, -2, 0)
	mat.color = dust_color
	mat.scale_min = 0.3
	mat.scale_max = 0.6
	mat.damping_min = 2.0
	mat.damping_max = 4.0
	particles.process_material = mat
	var mesh := QuadMesh.new()
	mesh.size = Vector2(0.4, 0.4)
	particles.draw_pass_1 = mesh
	add_child(particles)
	particles.emitting = true
	await get_tree().create_timer(dust_lifetime + 0.3).timeout
	queue_free()

# USAGE
# var dust := preload("res://scenes/effects/dust_3d.tscn").instantiate()
# get_tree().current_scene.add_child(dust)
# dust.global_position = landing_position
#
# Adjust dust_color per terrain:
#   brown for dirt
#   grey for stone
#   white for snow
#   dark green for grass
""",
				"params": ["dust_color", "dust_count", "dust_lifetime"],
				"category": "particles",
				"subcategory": "3d",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "beginner",
				"param_info": {
					"dust_color": {
						"default": [0.8, 0.75, 0.65, 0.7],
						"range": [],
						"what": "Color of the dust. Should match the ground.",
						"typical": "brown dirt / grey stone / white snow / green grass",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"dust_count": {
						"default": 20,
						"range": [5, 60],
						"what": "Particles per dust puff.",
						"typical": "10 subtle / 20 standard / 40+ thick",
						"increase": "Denser cloud.",
						"decrease": "Sparser."
					}
				},
				"details": {
					"what": "Small 3D dust puff for landings and footsteps. Self-contained scene.",
					"where": "Instantiate at landing position or under each footstep. Adjust color per terrain type.",
					"before": "None — code only.",
					"after": "Add a second puff on sprint footsteps for heavier feedback.",
					"why_optimized": "Small one-shot burst. High damping makes particles slow down and fade naturally.",
					"mistakes": "Using the default velocity ranges causes particles to fly too far. 0.5-1.5 is the sweet spot for dust.",
					"related": ["character_movement_3d", "footstep_sound", "particle_explosion_3d"]
				}
			},
			"particle_smoke_3d": {
				"phrases": ["particle smoke 3d", "3d smoke", "smoke column 3d", "chimney smoke"],
				"code": """extends GPUParticles3D

@export var smoke_color: Color = Color(0.3, 0.3, 0.3, 0.6)
@export var smoke_rise_speed: float = 1.5
@export var smoke_lifetime: float = 3.0
@export var smoke_radius: float = 0.5

func _ready() -> void:
	emitting = true
	lifetime = smoke_lifetime
	amount = 30
	explosiveness = 0.0
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 15.0
	mat.initial_velocity_min = smoke_rise_speed * 0.5
	mat.initial_velocity_max = smoke_rise_speed
	mat.gravity = Vector3(0, 0.2, 0)
	mat.color = smoke_color
	mat.scale_min = smoke_radius * 0.5
	mat.scale_max = smoke_radius
	mat.damping_min = 0.5
	mat.damping_max = 1.5
	process_material = mat
	if draw_pass_1 == null:
		var mesh := QuadMesh.new()
		mesh.size = Vector2(1.0, 1.0)
		draw_pass_1 = mesh
	# Billboard so particles always face the camera
	if draw_pass_1 is QuadMesh:
		var quad_mat := StandardMaterial3D.new()
		quad_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		quad_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		quad_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		draw_pass_1.surface_set_material(0, quad_mat)

func set_intensity(value: float) -> void:
	amount = int(30.0 * value)

# USAGE
# Attach to a chimney, damaged engine, or a burning object.
# Adjust smoke_color and smoke_radius per case.
#
# For a dying enemy that emits more smoke as health drops:
#   var health_ratio = float(health) / max_health
#   smoke.set_intensity(1.0 + (1.0 - health_ratio) * 2.0)
""",
				"params": ["smoke_color", "smoke_rise_speed", "smoke_lifetime", "smoke_radius"],
				"category": "particles",
				"subcategory": "3d",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "beginner",
				"param_info": {
					"smoke_color": {
						"default": [0.3, 0.3, 0.3, 0.6],
						"range": [],
						"what": "Smoke color and alpha.",
						"typical": "grey engine / white steam / black fire / green poison",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"smoke_lifetime": {
						"default": 3.0,
						"range": [1.0, 8.0],
						"what": "How long each particle lives.",
						"typical": "1.5 short puff / 3.0 standard / 6.0+ lingering",
						"increase": "Longer lasting.",
						"decrease": "Shorter."
					}
				},
				"details": {
					"what": "Continuous 3D smoke column. Chimneys, engine exhaust, burning objects, or dying enemies.",
					"where": "Attach as a child of the source. The particle rises and dissipates.",
					"before": "None — code only.",
					"after": "For thick smoke that fills a room, increase particle amount and lifetime together.",
					"why_optimized": "Billboard quads with unshaded material — cheapest possible particle rendering.",
					"mistakes": "Very high initial velocity makes the smoke shoot up too fast. Keep rise speed between 0.5 and 3.0.",
					"related": ["particle_fire_3d", "particle_explosion_3d", "damage_over_time"]
				}
			},
			"particle_fire_3d": {
				"phrases": ["particle fire 3d", "3d fire", "campfire 3d", "torch fire 3d"],
				"code": """extends GPUParticles3D

@export var fire_height: float = 1.5
@export var particle_count: int = 40
@export var outer_color: Color = Color(1.0, 0.3, 0.0)
@export var inner_color: Color = Color(1.0, 0.9, 0.3)

func _ready() -> void:
	emitting = true
	lifetime = 0.8
	amount = particle_count
	explosiveness = 0.0
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 10.0
	mat.initial_velocity_min = fire_height * 1.5
	mat.initial_velocity_max = fire_height * 2.5
	mat.gravity = Vector3.ZERO
	mat.scale_min = 0.1
	mat.scale_max = 0.4
	mat.damping_min = 1.0
	mat.damping_max = 2.0
	# Color gradient — orange at bottom, yellow at top, fading out
	var gradient := Gradient.new()
	gradient.set_color(0, outer_color)
	gradient.set_color(1, Color(inner_color.r, inner_color.g, inner_color.b, 0.0))
	var ramp := GradientTexture1D.new()
	ramp.gradient = gradient
	mat.color_ramp = ramp
	process_material = mat
	if draw_pass_1 == null:
		var mesh := QuadMesh.new()
		mesh.size = Vector2(0.5, 0.5)
		var quad_mat := StandardMaterial3D.new()
		quad_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		quad_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		quad_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		quad_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		mesh.surface_set_material(0, quad_mat)
		draw_pass_1 = mesh

# USAGE
# Attach to a campfire, torch, or burning object.
# Pair with an OmniLight3D for actual light casting — this particle
# only creates the visual flames.
#
# For a flickering effect:
#   var light := $OmniLight3D
#   var t := randf_range(0.8, 1.2)
#   light.light_energy = t

func set_intensity(value: float) -> void:
	amount = int(particle_count * value)
""",
				"params": ["fire_height", "particle_count", "outer_color", "inner_color"],
				"category": "particles",
				"subcategory": "3d",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "intermediate",
				"param_info": {
					"fire_height": {
						"default": 1.5,
						"range": [0.3, 5.0],
						"what": "How tall the flames reach, in meters.",
						"typical": "0.5 candle / 1.5 campfire / 3.0+ bonfire",
						"increase": "Taller flames.",
						"decrease": "Shorter."
					},
					"particle_count": {
						"default": 40,
						"range": [10, 200],
						"what": "Number of particle flames.",
						"typical": "20 small / 40 standard / 100+ blazing",
						"increase": "Denser fire.",
						"decrease": "Sparser."
					}
				},
				"details": {
					"what": "3D fire particles for campfires, torches, and burning objects. Uses additive blending for glow.",
					"where": "Attach to any scene node. Pair with an OmniLight3D at the same position for light casting.",
					"before": "None — code only.",
					"after": "Animate the OmniLight3D's energy with random values for a flicker effect.",
					"why_optimized": "Additive blend quad particles are cheap. Color ramp handles the fade — no per-particle scripts.",
					"mistakes": "Forgetting additive blend mode makes the fire look flat. Set blend_mode to ADD on the material.",
					"related": ["omni_light_3d", "particle_smoke_3d", "flickering_light"]
				}
			},
			"particle_debris_3d": {
				"phrases": ["particle debris 3d", "3d debris", "shrapnel 3d", "chunks 3d"],
				"code": """extends Node3D

@export var debris_count: int = 15
@export var debris_speed: float = 10.0
@export var debris_lifetime: float = 2.0
@export var debris_color: Color = Color(0.5, 0.4, 0.3)
@export var mesh_type: String = "box"

func _ready() -> void:
	var particles := GPUParticles3D.new()
	particles.amount = debris_count
	particles.lifetime = debris_lifetime
	particles.one_shot = true
	particles.explosiveness = 1.0
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 60.0
	mat.initial_velocity_min = debris_speed * 0.5
	mat.initial_velocity_max = debris_speed
	mat.gravity = Vector3(0, -9.8, 0)
	mat.angular_velocity_min = -360.0
	mat.angular_velocity_max = 360.0
	mat.color = debris_color
	mat.scale_min = 0.1
	mat.scale_max = 0.3
	particles.process_material = mat
	var mesh: Mesh
	match mesh_type:
		"box":
			var box := BoxMesh.new()
			box.size = Vector3(0.2, 0.2, 0.2)
			mesh = box
		"tetra":
			var tetra := PrismMesh.new()
			tetra.size = Vector3(0.2, 0.2, 0.2)
			mesh = tetra
		_:
			var sphere := SphereMesh.new()
			sphere.radius = 0.1
			sphere.height = 0.2
			mesh = sphere
	particles.draw_pass_1 = mesh
	add_child(particles)
	particles.emitting = true
	await get_tree().create_timer(debris_lifetime + 0.5).timeout
	queue_free()

# USAGE
# var debris := preload("res://scenes/effects/debris_3d.tscn").instantiate()
# get_tree().current_scene.add_child(debris)
# debris.global_position = break_position
#
# Adjust debris_color to match the broken material:
#   brown for wood
#   grey for stone
#   silver for metal
#   green for glass (with a green-tinted translucent material)
""",
				"params": ["debris_count", "debris_speed", "debris_lifetime", "debris_color", "mesh_type"],
				"category": "particles",
				"subcategory": "3d",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "beginner",
				"param_info": {
					"debris_count": {
						"default": 15,
						"range": [5, 60],
						"what": "Number of debris chunks.",
						"typical": "8 small break / 15 standard / 40+ shatter",
						"increase": "More chunks.",
						"decrease": "Fewer."
					},
					"debris_speed": {
						"default": 10.0,
						"range": [3.0, 25.0],
						"what": "Initial velocity of debris.",
						"typical": "5 small drop / 10 standard / 20+ violent",
						"increase": "Chunks fly further.",
						"decrease": "Closer together."
					},
					"mesh_type": {
						"default": "box",
						"range": [],
						"what": "Shape of the debris chunks.",
						"typical": "box / tetra / sphere",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "One-shot debris burst for breaking objects — barrels, crates, walls, wooden doors.",
					"where": "Instantiate at the break position. Color and mesh type should match the broken material.",
					"before": "None — code only.",
					"after": "Add a shatter sound and a brief camera shake for full effect.",
					"why_optimized": "Angular velocity gives tumbling chunks without per-particle scripts. Gravity makes them land naturally.",
					"mistakes": "Very high debris_speed with default gravity makes chunks fly offscreen. Balance speed against lifetime.",
					"related": ["particle_explosion_3d", "camera_shake_3d", "door_3d"]
				}
			}
		}
	}

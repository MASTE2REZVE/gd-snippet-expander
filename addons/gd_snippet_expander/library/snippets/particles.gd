@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"snippets": {
			"particle_explosion": {
				"phrases": ["particle explosion", "explosion effect", "burst particles", "explode particles"],
				"code": """@export var burst_count: int = 40
@export var burst_speed: float = 300.0
@export var burst_lifetime: float = 0.6
@export var particle_color: Color = Color(1.0, 0.7, 0.2)

func spawn_explosion(at_global_position: Vector2) -> void:
	var particles := CPUParticles2D.new()
	particles.global_position = at_global_position
	particles.emitting = false
	particles.one_shot = true
	particles.amount = burst_count
	particles.lifetime = burst_lifetime
	particles.explosiveness = 1.0
	particles.direction = Vector2.ZERO
	particles.spread = 180.0
	particles.initial_velocity_min = burst_speed * 0.5
	particles.initial_velocity_max = burst_speed
	particles.gravity = Vector2(0, 200)
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0
	particles.color = particle_color
	get_tree().current_scene.add_child(particles)
	particles.emitting = true
	await get_tree().create_timer(burst_lifetime + 0.2).timeout
	if is_instance_valid(particles):
		particles.queue_free()
""",
				"params": ["burst_count", "burst_speed", "burst_lifetime", "particle_color"],
				"category": "particles",
				"subcategory": "burst",
				"dimension": "2d",
				"difficulty": "beginner",
				"param_info": {
					"burst_count": {
						"default": 40,
						"range": [10, 200],
						"what": "Number of particles per explosion.",
						"typical": "20 small pop / 40 standard / 100+ big boom",
						"increase": "Denser, more dramatic.",
						"decrease": "Sparser."
					},
					"burst_speed": {
						"default": 300.0,
						"range": [50.0, 800.0],
						"what": "Maximum speed particles fly outward, in pixels per second.",
						"typical": "150 gentle / 300 standard / 600 explosive",
						"increase": "Particles fly further.",
						"decrease": "Tighter burst."
					},
					"burst_lifetime": {
						"default": 0.6,
						"range": [0.2, 2.0],
						"what": "How long each particle lives, in seconds.",
						"typical": "0.4 snappy / 0.6 standard / 1.2 lingering",
						"increase": "Longer effect.",
						"decrease": "Quicker."
					},
					"particle_color": {
						"default": [1, 0.7, 0.2, 1],
						"range": [],
						"what": "Color of the particles.",
						"typical": "orange fire / red damage / white generic / green poison",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "Spawns a one-shot particle burst at any world position. Self-deletes.",
					"where": "Attach to a manager node or the attacker. Call spawn_explosion(global_position) when something blows up.",
					"before": "None. Particles are created programmatically — no scene file needed.",
					"after": "For directional bursts (bullets, shrapnel), set particles.direction before emitting.",
					"why_optimized": "CPUParticles2D avoids needing a texture. One-shot + auto-free means no leaks.",
					"mistakes": "Forgetting queue_free leaves particles in the tree forever. The timer in this snippet handles it.",
					"related": ["particle_trail", "particle_dust", "damage_number_popup", "camera_shake"]
				}
			},
			"particle_trail": {
				"phrases": ["particle trail", "trail effect", "smoke trail", "bullet trail"],
				"code": """@export var trail_color: Color = Color(1.0, 1.0, 1.0, 0.6)
@export var trail_lifetime: float = 0.5

func _ready() -> void:
	var particles := CPUParticles2D.new()
	particles.emitting = true
	particles.amount = 30
	particles.lifetime = trail_lifetime
	particles.local_coords = false
	particles.direction = Vector2.ZERO
	particles.spread = 30.0
	particles.initial_velocity_min = 5.0
	particles.initial_velocity_max = 20.0
	particles.gravity = Vector2.ZERO
	particles.scale_amount_min = 3.0
	particles.scale_amount_max = 6.0
	particles.color = trail_color
	add_child(particles)
""",
				"params": ["trail_color", "trail_lifetime"],
				"category": "particles",
				"subcategory": "trail",
				"dimension": "2d",
				"difficulty": "beginner",
				"param_info": {
					"trail_color": {
						"default": [1, 1, 1, 0.6],
						"range": [],
						"what": "Particle color and alpha.",
						"typical": "white smoke / orange fire / purple magic / red blood",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"trail_lifetime": {
						"default": 0.5,
						"range": [0.1, 2.0],
						"what": "How long each puff lives.",
						"typical": "0.3 short trail / 0.5 standard / 1.0 long",
						"increase": "Longer tail behind the object.",
						"decrease": "Tighter trail."
					}
				},
				"details": {
					"what": "Attaches a trailing particle emitter to any node. Leaves a path behind as it moves.",
					"where": "Attach to a moving node (bullet, missile, dashing player). Add the snippet as a script or paste _ready into an existing script.",
					"before": "None.",
					"after": "For fading trails, animate trail_color.a down over the trail_lifetime via a Gradient or Tween.",
					"why_optimized": "local_coords = false means particles stay behind in world space as the parent moves.",
					"mistakes": "Forgetting local_coords = false makes the trail stick to the moving object.",
					"related": ["particle_explosion", "particle_dust", "projectile"]
				}
			},
			"particle_dust": {
				"phrases": ["particle dust", "dust puff", "landing dust", "footstep dust"],
				"code": """@export var dust_color: Color = Color(0.8, 0.75, 0.65, 0.7)
@export var dust_count: int = 12

func spawn_dust(at_global_position: Vector2) -> void:
	var particles := CPUParticles2D.new()
	particles.global_position = at_global_position
	particles.emitting = false
	particles.one_shot = true
	particles.amount = dust_count
	particles.lifetime = 0.4
	particles.explosiveness = 1.0
	particles.direction = Vector2.UP
	particles.spread = 45.0
	particles.initial_velocity_min = 30.0
	particles.initial_velocity_max = 80.0
	particles.gravity = Vector2(0, -50)
	particles.scale_amount_min = 4.0
	particles.scale_amount_max = 8.0
	particles.color = dust_color
	get_tree().current_scene.add_child(particles)
	particles.emitting = true
	await get_tree().create_timer(0.7).timeout
	if is_instance_valid(particles):
		particles.queue_free()
""",
				"params": ["dust_color", "dust_count"],
				"category": "particles",
				"subcategory": "burst",
				"dimension": "2d",
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
						"default": 12,
						"range": [4, 40],
						"what": "Number of dust particles per puff.",
						"typical": "6 subtle / 12 standard / 24 thick",
						"increase": "Denser cloud.",
						"decrease": "Sparser."
					}
				},
				"details": {
					"what": "Spawns a small dust puff. Use for footfalls, landings, and impacts on the ground.",
					"where": "Call spawn_dust(global_position) from a landing check or footstep timer.",
					"before": "None.",
					"after": "Vary dust_color per level — desert sand, snow, stone floor.",
					"why_optimized": "Small burst, quick despawn, no texture needed.",
					"mistakes": "Using dust_color that doesn't match the terrain looks out of place. Match the ground visually.",
					"related": ["particle_explosion", "particle_trail", "footstep_sound", "platformer_movement_2d"]
				}
			},
			"particle_sparkle": {
				"phrases": ["particle sparkle", "sparkle effect", "shiny pickup", "sparkle trail"],
				"code": """@export var sparkle_color: Color = Color(1.0, 0.9, 0.4)

func _ready() -> void:
	var particles := CPUParticles2D.new()
	particles.emitting = true
	particles.amount = 8
	particles.lifetime = 1.2
	particles.preprocess = 1.2
	particles.direction = Vector2.UP
	particles.spread = 60.0
	particles.initial_velocity_min = 10.0
	particles.initial_velocity_max = 30.0
	particles.gravity = Vector2.ZERO
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0
	particles.color = sparkle_color
	add_child(particles)
""",
				"params": ["sparkle_color"],
				"category": "particles",
				"subcategory": "ambient",
				"dimension": "2d",
				"difficulty": "beginner",
				"param_info": {
					"sparkle_color": {
						"default": [1.0, 0.9, 0.4],
						"range": [],
						"what": "Color of the sparkles.",
						"typical": "gold coins / cyan magic / pink hearts / white generic",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "Continuous sparkles rising from a node. Use for pickups, gems, quest items.",
					"where": "Attach to the item's root node. The sparkles follow automatically.",
					"before": "None.",
					"after": "Combine with a subtle bob tween on the sprite for a classic pickup look.",
					"why_optimized": "preprocess = lifetime makes the effect fully populated at scene load — no wait for the first particles to appear.",
					"mistakes": "Very high particle counts on many pickups hurt performance. Keep amount low.",
					"related": ["coin_pickup", "health_pickup", "particle_trail"]
				}
			},
			"particle_smoke": {
				"phrases": ["particle smoke", "smoke puff", "damage smoke", "engine smoke"],
				"code": """@export var smoke_color: Color = Color(0.3, 0.3, 0.3, 0.6)

func _ready() -> void:
	var particles := CPUParticles2D.new()
	particles.emitting = true
	particles.amount = 20
	particles.lifetime = 1.5
	particles.preprocess = 1.5
	particles.direction = Vector2.UP
	particles.spread = 25.0
	particles.initial_velocity_min = 20.0
	particles.initial_velocity_max = 40.0
	particles.gravity = Vector2(0, -20)
	particles.scale_amount_min = 8.0
	particles.scale_amount_max = 14.0
	particles.color = smoke_color
	particles.damping_min = 10.0
	particles.damping_max = 30.0
	add_child(particles)
""",
				"params": ["smoke_color"],
				"category": "particles",
				"subcategory": "ambient",
				"dimension": "2d",
				"difficulty": "beginner",
				"param_info": {
					"smoke_color": {
						"default": [0.3, 0.3, 0.3, 0.6],
						"range": [],
						"what": "Smoke color and alpha.",
						"typical": "grey engine / white steam / black fire / green poison",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "Continuous upward smoke from a node. Damaged engines, chimneys, dying enemies.",
					"where": "Attach to the source node. Smoke rises automatically.",
					"before": "None.",
					"after": "Scale amount up when health drops: particles.amount = int(health / max_health * 20.0)",
					"why_optimized": "damping (drag) slows particles over time so they rise and fade naturally.",
					"mistakes": "Smoke that never fades looks stuck. Tune lifetime and alpha together.",
					"related": ["particle_dust", "particle_explosion", "damage_over_time"]
				}
			}
		}
	}

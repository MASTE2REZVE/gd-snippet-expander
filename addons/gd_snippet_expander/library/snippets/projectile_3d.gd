@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"snippets": {
			"projectile_3d": {
				"phrases": ["projectile 3d", "bullet 3d", "3d projectile", "moving bullet 3d"],
				"code": """extends Area3D

@export var speed: float = 50.0
@export var damage: int = 10
@export var lifetime: float = 3.0
@export var gravity_multiplier: float = 0.0

var direction: Vector3 = Vector3.FORWARD
var _velocity: Vector3 = Vector3.ZERO

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_velocity = direction.normalized() * speed
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	if gravity_multiplier > 0.0:
		_velocity += Vector3.DOWN * 9.8 * gravity_multiplier * delta
	global_position += _velocity * delta
	if _velocity.length() > 0.01:
		look_at(global_position + _velocity.normalized(), Vector3.UP)

func _on_body_entered(body: Node3D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()

func setup(start_direction: Vector3, start_speed: float = -1.0) -> void:
	direction = start_direction.normalized()
	if start_speed > 0.0:
		speed = start_speed
	_velocity = direction * speed
""",
				"params": ["speed", "damage", "lifetime", "gravity_multiplier"],
				"category": "projectile",
				"subcategory": "3d",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "beginner",
				"param_info": {
					"speed": {
						"default": 50.0,
						"range": [5.0, 200.0],
						"what": "Meters per second the projectile travels.",
						"typical": "20 grenade / 50 bullet / 100+ railgun",
						"increase": "Faster.",
						"decrease": "Slower."
					},
					"gravity_multiplier": {
						"default": 0.0,
						"range": [0.0, 3.0],
						"what": "How much gravity affects the projectile. 0 is straight line, 1 is normal gravity.",
						"typical": "0 bullets / 0.5 arrows / 1.0 grenades",
						"increase": "More arc.",
						"decrease": "Flatter trajectory."
					},
					"lifetime": {
						"default": 3.0,
						"range": [0.5, 15.0],
						"what": "Seconds before the projectile despawns.",
						"typical": "1 short / 3 standard / 10+ long-range",
						"increase": "Travels further.",
						"decrease": "Shorter range."
					}
				},
				"details": {
					"what": "Basic 3D projectile. Moves in a direction, damages on hit, self-despawns. Supports gravity for arced trajectories.",
					"where": "Attach to an Area3D with a CollisionShape3D and MeshInstance3D child. Save as its own .tscn.",
					"before": "Enemies with take_damage method. Spawner scene that instantiates this projectile.",
					"after": "Call setup() after instantiation to set direction. Add particle trails and impact effects.",
					"why_optimized": "Manual position update instead of physics for projectiles. Area3D handles detection on the physics side.",
					"mistakes": "Using a RigidBody3D for bullets wastes physics simulation. Area3D + manual movement is cheaper and more predictable.",
					"related": ["projectile_patterns", "projectile_trail_3d", "hitscan_3d", "rocket_3d"]
				}
			},
			"hitscan_3d": {
				"phrases": ["hitscan 3d", "raycast bullet", "instant bullet", "laser shot"],
				"code": """extends Node3D

signal hit_target(target: Node3D, hit_position: Vector3, damage: int)

@export var damage: int = 25
@export var range: float = 100.0
@export var damage_falloff: float = 0.5
@export var pierce_count: int = 1
@export var tracer_scene: PackedScene
@export var tracer_duration: float = 0.05

func fire(from: Vector3, direction: Vector3) -> void:
	var space := get_world_3d().direct_space_state
	var to := from + direction.normalized() * range
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = false
	var hits: Array = []
	var current_from := from
	var remaining_pierce: int = pierce_count
	while remaining_pierce > 0:
		var result := space.intersect_ray(query)
		if result.is_empty():
			break
		var collider = result.get("collider")
		var position: Vector3 = result.get("position", Vector3.ZERO)
		hits.append({"target": collider, "position": position})
		_apply_damage(collider, position, from)
		remaining_pierce -= 1
		current_from = position + direction.normalized() * 0.1
		query = PhysicsRayQueryParameters3D.create(current_from, to)
		query.exclude = _collect_hit_rids(hits)
	_spawn_tracer(from, current_from)

func _apply_damage(collider, position: Vector3, from: Vector3) -> void:
	if collider == null or not collider.has_method("take_damage"):
		return
	var distance := from.distance_to(position)
	var multiplier: float = 1.0 - (distance / range) * damage_falloff
	var final_damage: int = max(1, int(float(damage) * multiplier))
	collider.take_damage(final_damage)
	hit_target.emit(collider, position, final_damage)

func _collect_hit_rids(hits: Array) -> Array:
	var rids: Array = []
	for h in hits:
		if h.target is CollisionObject3D:
			rids.append((h.target as CollisionObject3D).get_rid())
	return rids

func _spawn_tracer(from: Vector3, to: Vector3) -> void:
	if tracer_scene == null:
		return
	var tracer := tracer_scene.instantiate() as Node3D
	get_tree().current_scene.add_child(tracer)
	tracer.global_position = from
	tracer.look_at(to, Vector3.UP)
	if tracer.get("length") != null:
		tracer.set("length", from.distance_to(to))
	get_tree().create_timer(tracer_duration).timeout.connect(func():
		if is_instance_valid(tracer):
			tracer.queue_free()
	)
""",
				"params": ["damage", "range", "damage_falloff", "pierce_count", "tracer_duration"],
				"category": "projectile",
				"subcategory": "3d",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "intermediate",
				"param_info": {
					"damage": {
						"default": 25,
						"range": [5, 500],
						"what": "Base damage at point blank range.",
						"typical": "10 pistol / 25 rifle / 100 sniper",
						"increase": "More damage.",
						"decrease": "Less."
					},
					"damage_falloff": {
						"default": 0.5,
						"range": [0.0, 1.0],
						"what": "Fraction of damage lost at maximum range.",
						"typical": "0.0 no falloff / 0.5 standard / 0.9+ dramatic",
						"increase": "More damage loss over distance.",
						"decrease": "Less."
					},
					"pierce_count": {
						"default": 1,
						"range": [1, 10],
						"what": "How many targets the shot can pass through.",
						"typical": "1 normal / 3 piercing / 10 railgun",
						"increase": "More pierce.",
						"decrease": "Less."
					}
				},
				"details": {
					"what": "Instant hitscan weapon. Raycast from muzzle, damage first target. Optional pierce for railguns.",
					"where": "Attach to the weapon or player. Call fire(from, direction) on shoot input.",
					"before": "A tracer scene — a stretched MeshInstance3D with a bright emissive material.",
					"after": "Add muzzle flash, recoil, and impact particles on the hit_target signal.",
					"why_optimized": "Raycast is a single physics query. No moving projectile node to update.",
					"mistakes": "Forgetting to exclude already-hit targets on pierce causes infinite loops when the ray hits the same body repeatedly.",
					"related": ["projectile_3d", "impact_effect_3d", "damage_number_3d"]
				}
			},
			"rocket_3d": {
				"phrases": ["rocket 3d", "homing rocket", "missile 3d", "guided rocket"],
				"code": """extends Area3D

signal exploded(position: Vector3)

@export var speed: float = 30.0
@export var turn_speed: float = 2.0
@export var damage: int = 50
@export var splash_radius: float = 4.0
@export var lifetime: float = 8.0
@export var target_group: String = "enemy"

var direction: Vector3 = Vector3.FORWARD
var _target: Node3D = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_acquire_target()
	get_tree().create_timer(lifetime).timeout.connect(_explode)

func setup(start_direction: Vector3) -> void:
	direction = start_direction.normalized()

func _acquire_target() -> void:
	var best: Node3D = null
	var best_dist: float = 1e20
	for node in get_tree().get_nodes_in_group(target_group):
		if not (node is Node3D):
			continue
		var d := global_position.distance_to((node as Node3D).global_position)
		if d < best_dist:
			best_dist = d
			best = node as Node3D
	_target = best

func _physics_process(delta: float) -> void:
	if _target != null and is_instance_valid(_target):
		var desired := (_target.global_position - global_position).normalized()
		direction = direction.lerp(desired, turn_speed * delta).normalized()
	global_position += direction * speed * delta
	if direction.length() > 0.01:
		look_at(global_position + direction, Vector3.UP)

func _on_body_entered(_body: Node3D) -> void:
	_explode()

func _explode() -> void:
	var space := get_world_3d().direct_space_state
	var shape := SphereShape3D.new()
	shape.radius = splash_radius
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis(), global_position)
	var results := space.intersect_shape(query, 32)
	for result in results:
		var collider = result.get("collider")
		if collider != null and collider.has_method("take_damage"):
			var distance := global_position.distance_to((collider as Node3D).global_position)
			var falloff: float = clampf(1.0 - distance / splash_radius, 0.2, 1.0)
			collider.take_damage(int(float(damage) * falloff))
	exploded.emit(global_position)
	queue_free()
""",
				"params": ["speed", "turn_speed", "damage", "splash_radius", "lifetime", "target_group"],
				"category": "projectile",
				"subcategory": "3d",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "intermediate",
				"param_info": {
					"turn_speed": {
						"default": 2.0,
						"range": [0.5, 10.0],
						"what": "How fast the rocket curves toward the target.",
						"typical": "0.5 dumbfire / 2.0 standard / 5.0 aggressive",
						"increase": "Tighter tracking.",
						"decrease": "Looser, easier to dodge."
					},
					"splash_radius": {
						"default": 4.0,
						"range": [1.0, 15.0],
						"what": "Radius of the explosion damage.",
						"typical": "2 small / 4 standard / 10+ huge",
						"increase": "Bigger blast.",
						"decrease": "Smaller."
					}
				},
				"details": {
					"what": "Homing rocket with splash damage. Curves toward nearest target, explodes on impact or after lifetime.",
					"where": "Attach to an Area3D with a CollisionShape3D and MeshInstance3D child. Save as .tscn.",
					"before": "Targets in the target_group (default 'enemy'). Enemies have take_damage method.",
					"after": "Add explosion particles, screen shake, and a boom sound. See particle_explosion and camera_shake.",
					"why_optimized": "Direct position updates and single sphere query on explosion. No physics body overhead.",
					"mistakes": "Very high turn_speed makes the rocket loop and miss. Cap it or add a max-turn-rate limiter.",
					"related": ["projectile_3d", "particle_explosion", "camera_shake_3d", "hit_feedback_3d"]
				}
			},
			"grenade_3d": {
				"phrases": ["grenade 3d", "thrown grenade", "bouncing grenade", "cooked grenade"],
				"code": """extends RigidBody3D

signal exploded(position: Vector3)

@export var fuse_time: float = 3.0
@export var damage: int = 80
@export var splash_radius: float = 6.0
@export var bounce_force: float = 8.0

var _fuse_active: bool = false
var _fuse_timer: float = 0.0

func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 4
	body_entered.connect(_on_body_entered)

func start_fuse() -> void:
	if _fuse_active:
		return
	_fuse_active = true
	_fuse_timer = fuse_time

func throw_from(from: Vector3, direction: Vector3, force: float = 15.0) -> void:
	global_position = from
	apply_central_impulse(direction.normalized() * force)
	start_fuse()

func _physics_process(delta: float) -> void:
	if not _fuse_active:
		return
	_fuse_timer -= delta
	if _fuse_timer <= 0.0:
		_explode()
	elif _fuse_timer < 1.0:
		_flash_warning()

func _flash_warning() -> void:
	var mesh := get_node_or_null("MeshInstance3D")
	if mesh == null:
		return
	var t: float = fmod(_fuse_timer * 8.0, 2.0)
	(mesh as MeshInstance3D).modulate = Color(1, 0.3, 0.3) if t < 1.0 else Color.WHITE

func _on_body_entered(body: Node) -> void:
	if body is CharacterBody3D:
		return
	if linear_velocity.length() < 2.0:
		linear_velocity = Vector3.ZERO

func _explode() -> void:
	var space := get_world_3d().direct_space_state
	var shape := SphereShape3D.new()
	shape.radius = splash_radius
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis(), global_position)
	var results := space.intersect_shape(query, 32)
	for result in results:
		var collider = result.get("collider")
		if collider != null and collider.has_method("take_damage"):
			var distance := global_position.distance_to((collider as Node3D).global_position)
			var falloff: float = clampf(1.0 - distance / splash_radius, 0.3, 1.0)
			collider.take_damage(int(float(damage) * falloff))
	exploded.emit(global_position)
	queue_free()
""",
				"params": ["fuse_time", "damage", "splash_radius", "bounce_force"],
				"category": "projectile",
				"subcategory": "3d",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "intermediate",
				"param_info": {
					"fuse_time": {
						"default": 3.0,
						"range": [0.5, 10.0],
						"what": "Seconds before the grenade explodes.",
						"typical": "2 fast / 3 standard / 5+ patient",
						"increase": "Longer fuse.",
						"decrease": "Shorter."
					},
					"damage": {
						"default": 80,
						"range": [20, 500],
						"what": "Maximum damage at the center of the blast.",
						"typical": "50 frag / 80 standard / 200+ satchel",
						"increase": "Deadlier.",
						"decrease": "Weaker."
					},
					"splash_radius": {
						"default": 6.0,
						"range": [2.0, 20.0],
						"what": "Blast radius in meters.",
						"typical": "3 frag / 6 standard / 12+ artillery",
						"increase": "Bigger blast.",
						"decrease": "Smaller."
					}
				},
				"details": {
					"what": "Physics-based grenade that bounces, rolls, and explodes on a timer. Uses RigidBody3D for realistic physics.",
					"where": "Attach to a RigidBody3D with a CollisionShape3D and MeshInstance3D child. Save as .tscn.",
					"before": "Level has floor and wall collision so the grenade bounces properly.",
					"after": "Call throw_from with a direction and force. The visual flashes before exploding.",
					"why_optimized": "RigidBody3D is the right tool for bouncing projectiles. Sphere query on explosion is a single physics call.",
					"mistakes": "Using a tiny collision sphere causes the grenade to sink through floors at high speeds. Use a reasonably sized sphere and enable CCD.",
					"related": ["rocket_3d", "particle_explosion", "camera_shake_3d"]
				}
			},
			"laser_beam_3d": {
				"phrases": ["laser beam 3d", "beam weapon", "continuous laser", "rail beam"],
				"code": """extends Node3D

@export var damage_per_second: float = 40.0
@export var range: float = 50.0
@export var beam_width: float = 0.1
@export var beam_color: Color = Color(1.0, 0.3, 0.3)
@export var heat_per_second: float = 20.0
@export var overheat_threshold: float = 100.0
@export var cooling_rate: float = 30.0

var firing: bool = false
var heat: float = 0.0
var _overheated: bool = false
var _current_target: Node3D = null

@onready var _beam_mesh: MeshInstance3D = get_node_or_null("BeamMesh")
@onready var _beam_light: OmniLight3D = get_node_or_null("BeamLight")

func start_fire() -> void:
	if _overheated:
		return
	firing = true

func stop_fire() -> void:
	firing = false
	_current_target = null
	if _beam_mesh != null:
		_beam_mesh.visible = false
	if _beam_light != null:
		_beam_light.visible = false

func _process(delta: float) -> void:
	_update_heat(delta)
	if not firing or _overheated:
		return
	_fire_beam(delta)

func _fire_beam(delta: float) -> void:
	var from := global_position
	var direction := -global_transform.basis.z
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, from + direction * range)
	var result := space.intersect_ray(query)
	var hit_position := from + direction * range
	if not result.is_empty():
		hit_position = result.get("position", hit_position)
		var collider = result.get("collider")
		if collider != null and collider.has_method("take_damage"):
			var damage: int = max(1, int(damage_per_second * delta))
			collider.take_damage(damage)
	_visualize_beam(from, hit_position)
	heat += heat_per_second * delta
	if heat >= overheat_threshold:
		_overheated = true
		stop_fire()

func _update_heat(delta: float) -> void:
	if firing:
		return
	heat = maxf(heat - cooling_rate * delta, 0.0)
	if heat <= 0.0:
		_overheated = false

func _visualize_beam(from: Vector3, to: Vector3) -> void:
	if _beam_mesh == null:
		return
	_beam_mesh.visible = true
	_beam_mesh.global_position = (from + to) * 0.5
	var length := from.distance_to(to)
	_beam_mesh.scale = Vector3(beam_width, beam_width, length)
	_beam_mesh.look_at(to, Vector3.UP)
	if _beam_light != null:
		_beam_light.visible = true
		_beam_light.global_position = to
		_beam_light.light_color = beam_color

func get_heat_ratio() -> float:
	return clampf(heat / overheat_threshold, 0.0, 1.0)
""",
				"params": ["damage_per_second", "range", "beam_width", "heat_per_second", "overheat_threshold", "cooling_rate"],
				"category": "projectile",
				"subcategory": "3d",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "advanced",
				"param_info": {
					"damage_per_second": {
						"default": 40.0,
						"range": [5.0, 200.0],
						"what": "Damage dealt per second of continuous fire.",
						"typical": "20 weak / 40 standard / 100+ heavy",
						"increase": "More damage.",
						"decrease": "Less."
					},
					"overheat_threshold": {
						"default": 100.0,
						"range": [30.0, 300.0],
						"what": "Heat value that triggers overheat.",
						"typical": "50 quick overheat / 100 standard / 200 long fire",
						"increase": "Can fire longer.",
						"decrease": "Overheats sooner."
					},
					"cooling_rate": {
						"default": 30.0,
						"range": [5.0, 100.0],
						"what": "How fast heat dissipates when not firing.",
						"typical": "10 slow / 30 standard / 60 fast",
						"increase": "Cools faster.",
						"decrease": "Slower."
					}
				},
				"details": {
					"what": "Continuous laser beam weapon with heat buildup and overheat. Raycast-based damage every frame.",
					"where": "Attach to a Node3D with a BeamMesh MeshInstance3D child (using CylinderMesh or BoxMesh) and optional BeamLight.",
					"before": "Beam mesh with an emissive material. Full setup needs an OmniLight3D child for the impact glow.",
					"after": "Expose get_heat_ratio() to a UI bar so the player sees overheat coming.",
					"why_optimized": "Raycast per frame is cheap. Beam mesh is a single stretched quad — no per-pixel tracing.",
					"mistakes": "Scaling a cylinder mesh on Z scales along its own axis, not the world direction. The look_at + scale combination handles orientation.",
					"related": ["hitscan_3d", "screen_flash", "particle_trail_3d"]
				}
			},
			"throwing_arc_3d": {
				"phrases": ["throwing arc", "throw preview", "trajectory preview", "aim arc 3d"],
				"code": """extends Node3D

@export var projectile_speed: float = 15.0
@export var gravity: float = 9.8
@export var preview_points: int = 30
@export var preview_interval: float = 0.1
@export var aim_mesh: MeshInstance3D

var aim_direction: Vector3 = Vector3.FORWARD
var origin_offset: Vector3 = Vector3(0, 1.0, 0.5)

func update_aim(camera_forward: Vector3) -> void:
	aim_direction = camera_forward.normalized()
	_update_preview()

func throw() -> Node3D:
	return null

func _update_preview() -> void:
	if aim_mesh == null:
		return
	var points := _compute_trajectory()
	if points.size() < 2:
		return
	# Build a line mesh from the points
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for p in points:
		im.surface_add_vertex(p - global_position)
	im.surface_end()
	aim_mesh.mesh = im

func _compute_trajectory() -> PackedVector3Array:
	var points := PackedVector3Array()
	var origin := global_position + origin_offset
	var velocity := aim_direction * projectile_speed
	var t: float = 0.0
	for i in range(preview_points):
		var pos := origin + velocity * t + Vector3.DOWN * 0.5 * gravity * t * t
		points.append(pos)
		t += preview_interval
		# Stop if we hit something
		if i > 0:
			var space := get_world_3d().direct_space_state
			var from: Vector3 = points[i - 1]
			var query := PhysicsRayQueryParameters3D.create(from, pos)
			if not space.intersect_ray(query).is_empty():
				points.append(pos)
				break
	return points
""",
				"params": ["projectile_speed", "gravity", "preview_points", "preview_interval", "origin_offset"],
				"category": "projectile",
				"subcategory": "3d",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "advanced",
				"param_info": {
					"projectile_speed": {
						"default": 15.0,
						"range": [5.0, 40.0],
						"what": "Initial speed of the thrown object.",
						"typical": "8 grenade / 15 standard / 25+ fast throw",
						"increase": "Flatter arc.",
						"decrease": "Higher arc."
					},
					"preview_points": {
						"default": 30,
						"range": [10, 100],
						"what": "How many points to sample on the arc.",
						"typical": "20 coarse / 30 standard / 60 smooth",
						"increase": "Smoother arc.",
						"decrease": "Chunkier."
					}
				},
				"details": {
					"what": "Previews a throwing arc from the camera. Computes projectile trajectory and shows it as an ImmediateMesh line.",
					"where": "Attach to the player or a throwing controller. Requires a MeshInstance3D child for the arc line.",
					"before": "Camera3D to read the aim direction. MeshInstance3D with an empty mesh as the line target.",
					"after": "Call update_aim(camera.global_transform.basis.z * -1.0) on aim input. Call throw() to instantiate the actual projectile.",
					"why_optimized": "ImmediateMesh rebuilds only on aim update, not every frame. Raycast stops the arc at the first collision.",
					"mistakes": "Not using an ImmediateMesh for the line means creating and destroying meshes every frame. The built-in ImmediateMesh handles this efficiently.",
					"related": ["grenade_3d", "projectile_3d", "aim_line_3d"]
				}
			}
		}
	}

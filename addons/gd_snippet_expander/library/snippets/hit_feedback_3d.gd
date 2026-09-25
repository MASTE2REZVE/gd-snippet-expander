@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"snippets": {
			"hitstop_3d": {
				"phrases": ["hitstop 3d", "freeze frame 3d", "impact freeze 3d", "hit freeze 3d"],
				"code": """extends Node

@export var default_duration: float = 0.08
@export var default_scale: float = 0.05

var _active: bool = false

func freeze(duration: float = -1.0, scale: float = -1.0) -> void:
	if _active:
		return
	_active = true
	var dur: float = default_duration if duration < 0.0 else duration
	var sc: float = default_scale if scale < 0.0 else scale
	var original := Engine.time_scale
	Engine.time_scale = sc
	await get_tree().create_timer(dur * sc, true, false, true).timeout
	Engine.time_scale = original
	_active = false

func freeze_heavy() -> void:
	freeze(0.15, 0.02)

func freeze_medium() -> void:
	freeze(0.1, 0.05)

func freeze_light() -> void:
	freeze(0.05, 0.1)

func is_frozen() -> bool:
	return _active
""",
				"params": ["default_duration", "default_scale"],
				"category": "feedback",
				"subcategory": "hitstop",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "intermediate",
				"param_info": {
					"default_duration": {
						"default": 0.08,
						"range": [0.02, 0.5],
						"what": "How long the freeze lasts, in real seconds.",
						"typical": "0.05 light / 0.08 standard / 0.15+ heavy",
						"increase": "Longer freeze.",
						"decrease": "Shorter."
					},
					"default_scale": {
						"default": 0.05,
						"range": [0.0, 1.0],
						"what": "Engine time scale during the freeze.",
						"typical": "0.0 total freeze / 0.05 near-stop / 0.3 slight slow",
						"increase": "Less slowdown.",
						"decrease": "More."
					}
				},
				"details": {
					"what": "3D hitstop — freeze the entire game for a few frames on impact. The same technique as the 2D version.",
					"where": "Add as an autoload named 'Hitstop'. Call freeze_heavy() from boss hits, freeze_light() from regular hits.",
					"before": "None.",
					"after": "Combine with camera shake and impact particles for a full hit feel.",
					"why_optimized": "Engine.time_scale is a single global property. The advanced create_timer flags prevent the freeze from extending itself.",
					"mistakes": "Calling freeze() during an active freeze is blocked by the _active check to prevent overlap.",
					"related": ["camera_shake_3d", "impact_particles_3d", "hit_reaction_3d", "hitstop"]
				}
			},
			"hit_flash_3d": {
				"phrases": ["hit flash 3d", "damage flash 3d", "3d damage feedback", "mesh flash"],
				"code": """extends MeshInstance3D

@export var flash_color: Color = Color(1.0, 0.3, 0.3)
@export var flash_duration: float = 0.15
@export var flash_intensity: float = 5.0

var _original_emission: Color = Color.BLACK
var _original_emission_enabled: bool = false
var _original_emission_multiplier: float = 1.0
var _flashing: bool = false

func _ready() -> void:
	_capture_original()

func _capture_original() -> void:
	var mat := get_active_material(0)
	if mat is StandardMaterial3D:
		var std := mat as StandardMaterial3D
		_original_emission = std.emission
		_original_emission_enabled = std.emission_enabled
		_original_emission_multiplier = std.emission_energy_multiplier

func flash() -> void:
	if _flashing:
		return
	_flashing = true
	_apply_flash(flash_intensity)
	var tween := create_tween()
	tween.tween_method(_apply_flash, flash_intensity, 0.0, flash_duration)
	await tween.finished
	_restore_original()
	_flashing = false

func _apply_flash(intensity: float) -> void:
	for i in range(get_surface_override_material_count()):
		var mat = get_surface_override_material(i)
		if mat is StandardMaterial3D:
			_apply_to_standard(mat as StandardMaterial3D, intensity)
	# If no override, apply to the shared material
	if get_surface_override_material_count() == 0:
		var mat := get_active_material(0)
		if mat is StandardMaterial3D:
			var duplicate := (mat as StandardMaterial3D).duplicate() as StandardMaterial3D
			set_surface_override_material(0, duplicate)
			_apply_to_standard(duplicate, intensity)

func _apply_to_standard(std: StandardMaterial3D, intensity: float) -> void:
	if intensity > 0.0:
		std.emission_enabled = true
		std.emission = flash_color
		std.emission_energy_multiplier = intensity
	else:
		std.emission_enabled = _original_emission_enabled
		std.emission = _original_emission
		std.emission_energy_multiplier = _original_emission_multiplier

func _restore_original() -> void:
	_apply_flash(0.0)
""",
				"params": ["flash_color", "flash_duration", "flash_intensity"],
				"category": "feedback",
				"subcategory": "impact",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "beginner",
				"param_info": {
					"flash_color": {
						"default": [1.0, 0.3, 0.3, 1.0],
						"range": [],
						"what": "Color of the emission flash.",
						"typical": "red damage / white flash / yellow electric / blue frost",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"flash_duration": {
						"default": 0.15,
						"range": [0.05, 0.5],
						"what": "How long the flash lasts.",
						"typical": "0.1 snappy / 0.15 standard / 0.3 slow",
						"increase": "Longer flash.",
						"decrease": "Shorter."
					},
					"flash_intensity": {
						"default": 5.0,
						"range": [1.0, 15.0],
						"what": "Emission energy multiplier during the flash.",
						"typical": "2 subtle / 5 standard / 10 blinding",
						"increase": "Brighter flash.",
						"decrease": "Dimmer."
					}
				},
				"details": {
					"what": "Flashes a mesh bright red (or any color) when hit. The 3D equivalent of shader_flash.",
					"where": "Attach to a MeshInstance3D. Call flash() from the parent's take_damage method.",
					"before": "A mesh with a StandardMaterial3D. For best results, use a unique material (not shared).",
					"after": "Combine with hitstop and knockback for a full hit reaction. See hit_reaction_3d.",
					"why_optimized": "Uses emission (a per-material property) rather than a shader. Tween interpolates smoothly.",
					"mistakes": "Flashing a shared material makes every mesh using it flash. The script duplicates on first flash if needed.",
					"related": ["shader_flash", "hitstop_3d", "hit_reaction_3d", "damage_number_3d"]
				}
			},
			"damage_number_3d": {
				"phrases": ["damage number 3d", "floating damage 3d", "3d damage number", "label 3d damage"],
				"code": """extends Node3D

@export var text_color: Color = Color(1, 1, 1)
@export var critical_color: Color = Color(1, 0.8, 0.2)
@export var rise_height: float = 1.5
@export var duration: float = 1.0
@export var billboard: bool = true

@onready var _label: Label3D = get_node_or_null("Label3D")

func _ready() -> void:
	if _label == null:
		push_warning("DamageNumber3D needs a Label3D child named 'Label3D'.")
		return
	if billboard:
		_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.no_depth_test = true
	_animate()

func set_damage(amount: int, is_critical: bool = false) -> void:
	if _label == null:
		return
	_label.text = str(amount)
	_label.modulate = critical_color if is_critical else text_color
	if is_critical:
		_label.font_size = int(_label.font_size * 1.5)

func _animate() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y + rise_height, duration)
	if _label != null:
		tween.tween_property(_label, "modulate:a", 0.0, duration).set_delay(duration * 0.3)
	await tween.finished
	queue_free()

# SCENE SETUP
# 1. Create a new scene with a Node3D root.
# 2. Add a Label3D child named 'Label3D'.
# 3. Attach this script to the root.
# 4. Save as res://scenes/ui/damage_number_3d.tscn
# 5. Set the Label3D properties in the Inspector:
#    - font_size: 32 or larger
#    - outline_size: 6 for readability
#    - outline_modulate: Color(0, 0, 0)
#    - pixel_size: 0.01
#
# To spawn from a hit:
#   var popup := preload("res://scenes/ui/damage_number_3d.tscn").instantiate()
#   get_tree().current_scene.add_child(popup)
#   popup.global_position = hit_position + Vector3(0, 0.5, 0)
#   popup.set_damage(25, false)
""",
				"params": ["text_color", "critical_color", "rise_height", "duration", "billboard"],
				"category": "feedback",
				"subcategory": "damage",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "beginner",
				"param_info": {
					"rise_height": {
						"default": 1.5,
						"range": [0.5, 4.0],
						"what": "How high the number floats, in meters.",
						"typical": "0.8 subtle / 1.5 standard / 3.0 dramatic",
						"increase": "Floats higher.",
						"decrease": "Lower."
					},
					"duration": {
						"default": 1.0,
						"range": [0.3, 3.0],
						"what": "How long the number is visible.",
						"typical": "0.6 quick / 1.0 standard / 2.0+ slow",
						"increase": "Longer.",
						"decrease": "Shorter."
					},
					"billboard": {
						"default": true,
						"range": [],
						"what": "Whether the number always faces the camera.",
						"typical": "true for readability / false for world-anchored",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "Floating damage number in 3D using a billboarded Label3D. Rises and fades.",
					"where": "Save as its own .tscn. Instantiate and call set_damage() when a hit lands.",
					"before": "A Label3D child named 'Label3D'. Configure font size and outline in the Inspector.",
					"after": "For varied damage types, use different colors and pass them via set_damage.",
					"why_optimized": "Label3D is a single draw call. Billboard mode rotates toward the camera for free.",
					"mistakes": "Forgetting no_depth_test = true means the number clips through walls. The script enables it automatically.",
					"related": ["hit_flash_3d", "damage_number_popup", "damage_type_feedback", "hit_reaction_3d"]
				}
			},
			"impact_particles_3d": {
				"phrases": ["impact particles 3d", "hit particles 3d", "3d impact effect", "impact spark 3d"],
				"code": """extends Node3D

@export var particle_color: Color = Color(1.0, 0.8, 0.4)
@export var particle_count: int = 20
@export var lifetime: float = 0.5
@export var speed: float = 5.0

func _ready() -> void:
	var particles := GPUParticles3D.new()
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 90.0
	mat.initial_velocity_min = speed * 0.3
	mat.initial_velocity_max = speed
	mat.gravity = Vector3(0, -9.8, 0)
	mat.color = particle_color
	mat.scale_min = 0.05
	mat.scale_max = 0.1
	particles.process_material = mat
	var mesh := SphereMesh.new()
	mesh.radius = 0.05
	mesh.height = 0.1
	particles.draw_pass_1 = mesh
	particles.amount = particle_count
	particles.lifetime = lifetime
	particles.one_shot = true
	particles.explosiveness = 1.0
	add_child(particles)
	particles.emitting = true
	await get_tree().create_timer(lifetime + 0.5).timeout
	queue_free()

# USAGE:
#   var impact := preload("res://scenes/effects/impact_3d.tscn").instantiate()
#   get_tree().current_scene.add_child(impact)
#   impact.global_position = hit_position
#
# The impact spawns, bursts, and self-deletes. No cleanup needed.
""",
				"params": ["particle_color", "particle_count", "lifetime", "speed"],
				"category": "feedback",
				"subcategory": "impact",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "beginner",
				"param_info": {
					"particle_color": {
						"default": [1.0, 0.8, 0.4, 1.0],
						"range": [],
						"what": "Color of the impact particles.",
						"typical": "orange spark / red blood / green poison / blue magic",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"particle_count": {
						"default": 20,
						"range": [5, 100],
						"what": "Number of particles per burst.",
						"typical": "10 small / 20 standard / 50+ dramatic",
						"increase": "Denser burst.",
						"decrease": "Sparser."
					},
					"lifetime": {
						"default": 0.5,
						"range": [0.2, 2.0],
						"what": "How long each particle lives.",
						"typical": "0.3 snappy / 0.5 standard / 1.0 lingering",
						"increase": "Longer effect.",
						"decrease": "Quicker."
					}
				},
				"details": {
					"what": "Self-contained 3D impact effect. Spawns a particle burst at a position, plays once, auto-deletes.",
					"where": "Save as its own .tscn. Instantiate at hit position when a projectile or melee lands.",
					"before": "None.",
					"after": "Add a mesh variation per impact type — sparks for metal, blood for flesh, dust for stone.",
					"why_optimized": "GPUParticles3D handles hundreds of particles in a single draw call. Self-cleaning scene.",
					"mistakes": "Using CPUParticles3D for hundreds of particles is slower than GPUParticles3D. Use GPU for bursts.",
					"related": ["particle_explosion", "hit_flash_3d", "hit_reaction_3d", "camera_shake_3d"]
				}
			},
			"knockback_3d": {
				"phrases": ["knockback 3d", "push back 3d", "3d knockback", "hit push 3d"],
				"code": """extends CharacterBody3D

@export var knockback_force: float = 8.0
@export var knockback_up: float = 3.0
@export var knockback_duration: float = 0.3

var _knockback_timer: float = 0.0
var _knockback_velocity: Vector3 = Vector3.ZERO

func apply_knockback(from_position: Vector3) -> void:
	var direction := (global_position - from_position)
	direction.y = 0.0
	if direction.length() < 0.01:
		direction = -global_transform.basis.z
	direction = direction.normalized()
	_knockback_velocity = direction * knockback_force + Vector3.UP * knockback_up
	_knockback_timer = knockback_duration

func _physics_process(delta: float) -> void:
	if _knockback_timer > 0.0:
		_knockback_timer -= delta
		velocity = _knockback_velocity
		_knockback_velocity = _knockback_velocity.lerp(Vector3.ZERO, 5.0 * delta)
		move_and_slide()
		return
	if not is_on_floor():
		velocity += get_gravity() * delta
	move_and_slide()

func is_knocked_back() -> bool:
	return _knockback_timer > 0.0
""",
				"params": ["knockback_force", "knockback_up", "knockback_duration"],
				"category": "feedback",
				"subcategory": "impact",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "beginner",
				"param_info": {
					"knockback_force": {
						"default": 8.0,
						"range": [1.0, 30.0],
						"what": "Horizontal push speed in meters per second.",
						"typical": "3 light nudge / 8 standard / 20 heavy launch",
						"increase": "Bigger push.",
						"decrease": "Smaller."
					},
					"knockback_up": {
						"default": 3.0,
						"range": [0.0, 15.0],
						"what": "Upward velocity applied along with the push.",
						"typical": "0 no lift / 3 standard / 8+ launched into air",
						"increase": "Higher launch.",
						"decrease": "Flatter."
					},
					"knockback_duration": {
						"default": 0.3,
						"range": [0.1, 1.0],
						"what": "Seconds the character stays in the knockback state.",
						"typical": "0.2 quick / 0.3 standard / 0.6+ heavy stun",
						"increase": "Longer stun.",
						"decrease": "Shorter."
					}
				},
				"details": {
					"what": "3D knockback on hit. Pushes the character away from the damage source with an optional upward launch.",
					"where": "Attach to a CharacterBody3D. Call apply_knockback(attacker.global_position) from take_damage.",
					"before": "The character's normal movement script must check is_knocked_back() to skip input while knocked back.",
					"after": "Add a hurt animation and disable player control during the knockback window.",
					"why_optimized": "Lerps the knockback velocity to zero over the duration. No per-frame force accumulation.",
					"mistakes": "Not blending back into normal movement at the end of knockback causes a jarring stop.",
					"related": ["knockback", "hitstop_3d", "hit_flash_3d"]
				}
			},
			"hit_reaction_3d": {
				"phrases": ["hit reaction 3d", "full impact 3d", "3d hit combo", "complete hit feedback"],
				"code": """extends Node

@export var impact_scene: PackedScene
@export var damage_popup_scene: PackedScene
@export var hitstop_duration: float = 0.08
@export var flash_duration: float = 0.15
@export var shake_amount: float = 0.4

signal impact_completed(position: Vector3)

func process_hit(
	target: Node3D,
	hit_position: Vector3,
	damage: int,
	attacker_position: Vector3,
	is_critical: bool = false
) -> void:
	# 1. Hitstop
	_freeze(hitstop_duration if not is_critical else hitstop_duration * 1.5)
	# 2. Camera shake
	_shake_camera(shake_amount if not is_critical else shake_amount * 1.5)
	# 3. Impact particles
	_spawn_impact(hit_position)
	# 4. Damage number
	_spawn_damage_number(hit_position, damage, is_critical)
	# 5. Flash the target mesh
	_flash_target(target)
	# 6. Knockback
	_apply_knockback(target, attacker_position)
	impact_completed.emit(hit_position)

func _freeze(duration: float) -> void:
	var original := Engine.time_scale
	Engine.time_scale = 0.05
	await get_tree().create_timer(duration * 0.05, true, false, true).timeout
	Engine.time_scale = original

func _shake_camera(amount: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var origin := camera.position
	var tween := create_tween()
	for i in range(3):
		var offset := Vector3(
			randf_range(-amount, amount) * 0.1,
			randf_range(-amount, amount) * 0.1,
			randf_range(-amount, amount) * 0.1
		)
		tween.tween_property(camera, "position", origin + offset, 0.02)
	tween.tween_property(camera, "position", origin, 0.05)

func _spawn_impact(position: Vector3) -> void:
	if impact_scene == null:
		return
	var impact := impact_scene.instantiate() as Node3D
	get_tree().current_scene.add_child(impact)
	impact.global_position = position

func _spawn_damage_number(position: Vector3, damage: int, is_critical: bool) -> void:
	if damage_popup_scene == null:
		return
	var popup := damage_popup_scene.instantiate() as Node3D
	get_tree().current_scene.add_child(popup)
	popup.global_position = position + Vector3(0, 1.0, 0)
	if popup.has_method("set_damage"):
		popup.call("set_damage", damage, is_critical)

func _flash_target(target: Node3D) -> void:
	if target == null or not is_instance_valid(target):
		return
	var mesh := target.get_node_or_null("MeshInstance3D")
	if mesh != null and mesh.has_method("flash"):
		mesh.call("flash")

func _apply_knockback(target: Node3D, from_position: Vector3) -> void:
	if target == null or not is_instance_valid(target):
		return
	if target.has_method("apply_knockback"):
		target.call("apply_knockback", from_position)
""",
				"params": ["impact_scene", "damage_popup_scene", "hitstop_duration", "flash_duration", "shake_amount"],
				"category": "feedback",
				"subcategory": "impact",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "advanced",
				"param_info": {
					"hitstop_duration": {
						"default": 0.08,
						"range": [0.02, 0.3],
						"what": "Freeze duration on each hit.",
						"typical": "0.05 light / 0.08 standard / 0.15+ critical",
						"increase": "Longer freeze.",
						"decrease": "Shorter."
					},
					"shake_amount": {
						"default": 0.4,
						"range": [0.1, 2.0],
						"what": "Camera shake strength.",
						"typical": "0.2 subtle / 0.4 standard / 1.0 dramatic",
						"increase": "Bigger shake.",
						"decrease": "Smaller."
					}
				},
				"details": {
					"what": "Orchestrates a full 3D hit reaction — hitstop, shake, particles, damage number, mesh flash, knockback — in one call.",
					"where": "Attach to a game manager or the damage-dealing script. Call process_hit() from every hit.",
					"before": "Impact scene (impact_particles_3d), damage popup scene (damage_number_3d), target with apply_knockback and MeshInstance3D with flash method.",
					"after": "For bosses, call with is_critical=true for a bigger reaction. For chip damage, reduce the parameters directly.",
					"why_optimized": "All effects run in parallel. Camera shake uses a local tween on the camera, not the global hitstop.",
					"mistakes": "Calling process_hit for every tick of a damage-over-time effect overwhelms the player. Use it only for discrete hits.",
					"related": ["hitstop_3d", "hit_flash_3d", "impact_particles_3d", "damage_number_3d", "knockback_3d", "camera_shake_3d"]
				}
			}
		}
	}

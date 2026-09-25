@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"snippets": {
			"hitstop": {
				"phrases": ["hitstop", "hit stop", "freeze frame", "impact freeze"],
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
	var original_scale := Engine.time_scale
	Engine.time_scale = sc
	await get_tree().create_timer(dur * sc, true, false, true).timeout
	Engine.time_scale = original_scale
	_active = false

func freeze_heavy() -> void:
	freeze(0.15, 0.02)

func freeze_light() -> void:
	freeze(0.05, 0.1)

func is_frozen() -> bool:
	return _active
""",
				"params": ["default_duration", "default_scale"],
				"category": "feedback",
				"subcategory": "hitstop",
				"dimension": "any",
				"difficulty": "intermediate",
				"param_info": {
					"default_duration": {
						"default": 0.08,
						"range": [0.02, 0.5],
						"what": "How long the freeze lasts in real seconds.",
						"typical": "0.05 light hit / 0.08 standard / 0.15+ heavy",
						"increase": "Longer freeze.",
						"decrease": "Shorter."
					},
					"default_scale": {
						"default": 0.05,
						"range": [0.0, 1.0],
						"what": "Time scale during the freeze. Lower means slower.",
						"typical": "0.0 total freeze / 0.05 near-stop / 0.3 slight slow",
						"increase": "Less slowdown.",
						"decrease": "More slowdown."
					}
				},
				"details": {
					"what": "Freezes the entire game for a few frames when something impactful happens. The single most effective 'juice' technique.",
					"where": "Add as an autoload named 'Hitstop' or attach to a game manager. Call freeze() on every hit.",
					"before": "None.",
					"after": "Call freeze_heavy() for boss hits, freeze_light() for regular hits, freeze(0.3, 0.0) for finishing blows.",
					"why_optimized": "Uses Engine.time_scale — the freeze is engine-wide with one call. The ignore_time_scale parameter on create_timer means the freeze doesn't extend itself.",
					"mistakes": "Forgetting process_mode on the caller means the freeze also stops the timer that's supposed to end it. The advanced timer flags prevent this.",
					"related": ["hitstop_local", "impact_frames", "camera_shake", "screen_flash"]
				}
			},
			"hitstop_local": {
				"phrases": ["local hitstop", "pause entity freeze", "per object freeze", "partial hitstop"],
				"code": """extends Node

# Pauses specific nodes without affecting the whole game.
# Useful for cutscenes or when only one attacker should freeze.

var _frozen_nodes: Array = []

func freeze_node(node: Node, duration: float = 0.1) -> void:
	if node == null or not is_instance_valid(node):
		return
	var original_mode: int = node.process_mode
	node.process_mode = Node.PROCESS_MODE_DISABLED
	_frozen_nodes.append(node)
	await get_tree().create_timer(duration).timeout
	if is_instance_valid(node):
		node.process_mode = original_mode
	_frozen_nodes.erase(node)

func freeze_nodes(nodes: Array, duration: float = 0.1) -> void:
	for n in nodes:
		if n is Node:
			freeze_node(n, duration)

func unfreeze_all() -> void:
	for n in _frozen_nodes:
		if is_instance_valid(n):
			n.process_mode = Node.PROCESS_MODE_INHERIT
	_frozen_nodes.clear()
""",
				"params": [],
				"category": "feedback",
				"subcategory": "hitstop",
				"dimension": "any",
				"difficulty": "intermediate",
				"details": {
					"what": "Freezes only the specified nodes instead of the whole game. Good for localized hit feedback.",
					"where": "Attach to a manager node. Call freeze_node(enemy, 0.1) when the enemy is hit.",
					"before": "None.",
					"after": "Combine with a small camera shake for a full impact feel without pausing the world.",
					"why_optimized": "Uses process_mode toggling — no per-frame checks or timers on the frozen nodes.",
					"mistakes": "Freezing nodes that own the timer that unfreezes them creates a deadlock. The manager here owns the timer, not the frozen node.",
					"related": ["hitstop", "camera_shake", "impact_frames"]
				}
			},
			"screen_flash": {
				"phrases": ["screen flash", "damage flash", "hurt flash", "red flash"],
				"code": """extends CanvasLayer

@onready var _rect: ColorRect = $FlashRect

@export var default_color: Color = Color(1, 0, 0, 0.4)
@export var default_duration: float = 0.15

func _ready() -> void:
	_rect.color = Color(default_color.r, default_color.g, default_color.b, 0.0)
	layer = 99
	process_mode = Node.PROCESS_MODE_ALWAYS

func flash(color: Color = Color.TRANSPARENT, duration: float = -1.0) -> void:
	var c := color if color.a > 0.0 else default_color
	var dur: float = default_duration if duration < 0.0 else duration
	_rect.color = Color(c.r, c.g, c.b, c.a)
	var tween := create_tween()
	tween.tween_property(_rect, "color:a", 0.0, dur)

func flash_damage() -> void:
	flash(Color(1, 0.1, 0.1, 0.4), 0.2)

func flash_heal() -> void:
	flash(Color(0.3, 1, 0.3, 0.3), 0.3)

func flash_white() -> void:
	flash(Color(1, 1, 1, 0.6), 0.1)
""",
				"params": ["default_color", "default_duration"],
				"category": "feedback",
				"subcategory": "screen",
				"dimension": "ui",
				"difficulty": "beginner",
				"param_info": {
					"default_color": {
						"default": [1, 0, 0, 0.4],
						"range": [],
						"what": "Default flash color and alpha.",
						"typical": "red damage / green heal / white flash / yellow thunder",
						"increase": "Stronger tint.",
						"decrease": "Subtler."
					},
					"default_duration": {
						"default": 0.15,
						"range": [0.05, 1.0],
						"what": "How long the fade-out takes.",
						"typical": "0.1 snappy / 0.15 standard / 0.4 slow",
						"increase": "Slower fade.",
						"decrease": "Faster."
					}
				},
				"details": {
					"what": "Full-screen color flash. Red for damage, green for heal, white for screen effects.",
					"where": "Attach to a CanvasLayer at layer 99 with a full-size ColorRect child named 'FlashRect'. Set the ColorRect's color to transparent.",
					"before": "CanvasLayer with a ColorRect filling the screen. anchors_preset = 15 (full rect) on the ColorRect.",
					"after": "Call flash_damage() from your player's take_damage. Add more presets like flash_poison, flash_freeze.",
					"why_optimized": "Tween animates alpha to 0 — no per-frame script. process_mode = ALWAYS means it works even when the game is paused.",
					"mistakes": "Forgetting to set layer 99 means the flash renders behind other UI. Forgetting to hide it initially means a permanent tint.",
					"related": ["hitstop", "camera_shake", "shader_damage_flicker"]
				}
			},
			"impact_frames": {
				"phrases": ["impact frames", "scale punch", "hit scale", "punch effect"],
				"code": """extends Node2D

@export var punch_scale: float = 1.3
@export var punch_duration: float = 0.08
@export var return_duration: float = 0.15

var _base_scale: Vector2 = Vector2.ONE

func _ready() -> void:
	_base_scale = scale

func punch() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	scale = _base_scale * punch_scale
	modulate = Color(2.0, 2.0, 2.0)
	tween.tween_property(self, "scale", _base_scale, return_duration).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate", Color.WHITE, return_duration)

func punch_directional(from_direction: Vector2) -> void:
	var offset := from_direction.normalized() * 4.0
	var original := position
	var tween := create_tween()
	tween.tween_property(self, "position", original + offset, punch_duration)
	tween.tween_property(self, "position", original, return_duration)
	await tween.finished
	modulate = Color.WHITE
""",
				"params": ["punch_scale", "punch_duration", "return_duration"],
				"category": "feedback",
				"subcategory": "impact",
				"dimension": "2d",
				"difficulty": "beginner",
				"param_info": {
					"punch_scale": {
						"default": 1.3,
						"range": [1.05, 2.0],
						"what": "How big the sprite scales during the punch.",
						"typical": "1.1 subtle / 1.3 standard / 1.6 very cartoon",
						"increase": "Bigger punch.",
						"decrease": "Subtler."
					},
					"return_duration": {
						"default": 0.15,
						"range": [0.05, 0.5],
						"what": "Seconds to return to normal scale.",
						"typical": "0.1 snappy / 0.15 standard / 0.3 bouncy",
						"increase": "Slower return.",
						"decrease": "Faster."
					}
				},
				"details": {
					"what": "Brief scale punch plus brightness flash. The classic 'oomph' on every hit.",
					"where": "Attach to any Node2D that should react to impacts. Call punch() from take_damage.",
					"before": "None.",
					"after": "Combine with hitstop and a small camera shake for a full impact feel.",
					"why_optimized": "Two parallel tweens share a single Tween object. Modulate above 1.0 uses Godot's built-in color multiplier.",
					"mistakes": "Not resetting scale if the tween is interrupted (e.g. a second hit during the first) leaves the sprite permanently enlarged.",
					"related": ["squash_stretch", "hitstop", "screen_flash", "camera_shake"]
				}
			},
			"damage_type_feedback": {
				"phrases": ["damage type feedback", "elemental damage", "fire ice lightning", "damage color"],
				"code": """extends Node

enum DamageType { PHYSICAL, FIRE, ICE, LIGHTNING, POISON, HOLY }

const TYPE_COLORS := {
	DamageType.PHYSICAL: Color(1.0, 1.0, 1.0),
	DamageType.FIRE: Color(1.0, 0.4, 0.1),
	DamageType.ICE: Color(0.4, 0.8, 1.0),
	DamageType.LIGHTNING: Color(1.0, 1.0, 0.3),
	DamageType.POISON: Color(0.5, 1.0, 0.3),
	DamageType.HOLY: Color(1.0, 0.9, 0.4)
}

const TYPE_NAMES := {
	DamageType.PHYSICAL: "physical",
	DamageType.FIRE: "fire",
	DamageType.ICE: "ice",
	DamageType.LIGHTNING: "lightning",
	DamageType.POISON: "poison",
	DamageType.HOLY: "holy"
}

@export var popup_scene: PackedScene

func show_damage(amount: int, damage_type: int, world_position: Vector2) -> void:
	if popup_scene == null:
		return
	var popup := popup_scene.instantiate() as Node2D
	get_tree().current_scene.add_child(popup)
	popup.global_position = world_position
	if popup.has_method("set_text"):
		popup.call("set_text", str(amount))
	var color: Color = TYPE_COLORS.get(damage_type, Color.WHITE)
	if popup is CanvasItem:
		(popup as CanvasItem).modulate = color
	_apply_elemental_effect(damage_type, world_position)

func _apply_elemental_effect(damage_type: int, position: Vector2) -> void:
	match damage_type:
		DamageType.FIRE:
			spawn_particles(position, Color(1, 0.4, 0.1), 12)
		DamageType.ICE:
			spawn_particles(position, Color(0.6, 0.9, 1.0), 8)
		DamageType.LIGHTNING:
			spawn_particles(position, Color(1, 1, 0.4), 6)
		DamageType.POISON:
			spawn_particles(position, Color(0.5, 1.0, 0.3), 10)
		DamageType.HOLY:
			spawn_particles(position, Color(1, 0.9, 0.4), 15)

func spawn_particles(at_position: Vector2, color: Color, count: int) -> void:
	var particles := CPUParticles2D.new()
	particles.global_position = at_position
	particles.emitting = false
	particles.one_shot = true
	particles.amount = count
	particles.lifetime = 0.5
	particles.explosiveness = 1.0
	particles.direction = Vector2.ZERO
	particles.spread = 180.0
	particles.initial_velocity_min = 60.0
	particles.initial_velocity_max = 150.0
	particles.gravity = Vector2(0, 100)
	particles.scale_amount_min = 3.0
	particles.scale_amount_max = 5.0
	particles.color = color
	get_tree().current_scene.add_child(particles)
	particles.emitting = true
	await get_tree().create_timer(0.8).timeout
	if is_instance_valid(particles):
		particles.queue_free()
""",
				"params": ["popup_scene"],
				"category": "feedback",
				"subcategory": "damage",
				"dimension": "2d",
				"difficulty": "intermediate",
				"param_info": {
					"popup_scene": {
						"default": "",
						"range": [],
						"what": "PackedScene for the damage number popup. Usually the damage_popup_scene blueprint.",
						"typical": "one reusable scene for all damage types",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "Shows damage numbers with color and particle effects that change based on elemental type.",
					"where": "Attach to a game manager or a damage handler. Call show_damage(amount, type, world_pos) on every hit.",
					"before": "A popup scene with a set_text method. The damage_popup_scene blueprint provides one.",
					"after": "Extend the enum with more types. Each type gets a color and a particle burst.",
					"why_optimized": "Dictionary lookups for color and effect. Particle bursts are cheap CPUParticles2D.",
					"mistakes": "Forgetting the popup's modulate multiplies with its own color. Set the popup's base color to white.",
					"related": ["damage_number_popup", "particle_explosion", "damage_popup_scene"]
				}
			}
		}
	}

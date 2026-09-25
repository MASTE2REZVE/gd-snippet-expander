@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"snippets": {
			"transition_wipe": {
				"phrases": ["wipe transition", "horizontal wipe", "directional wipe", "screen wipe"],
				"code": """extends CanvasLayer

@onready var _rect: ColorRect = $WipeRect

@export var wipe_color: Color = Color(0, 0, 0, 1)
@export var wipe_duration: float = 0.4

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rect.color = wipe_color
	_rect.anchor_right = 0.0

func wipe_out(direction: int = 1) -> void:
	# direction: 1 = left to right, -1 = right to left
	_rect.anchor_left = 0.0 if direction > 0 else 1.0
	_rect.anchor_right = 0.0 if direction > 0 else 1.0
	_rect.offset_left = 0.0
	_rect.offset_right = 0.0
	var target := 1.0 if direction > 0 else -1.0
	var tween := create_tween()
	tween.tween_property(_rect, "anchor_right", target, wipe_duration)
	await tween.finished

func wipe_in(direction: int = 1) -> void:
	var target := 1.0 if direction > 0 else -1.0
	_rect.anchor_left = target
	_rect.anchor_right = target
	var end_target := 0.0
	var tween := create_tween()
	tween.tween_property(_rect, "anchor_right", end_target + target, wipe_duration)
	await tween.finished
	_rect.anchor_right = 0.0
""",
				"params": ["wipe_color", "wipe_duration"],
				"category": "transition",
				"subcategory": "wipe",
				"dimension": "ui",
				"difficulty": "intermediate",
				"param_info": {
					"wipe_color": {
						"default": [0, 0, 0, 1],
						"range": [],
						"what": "Color of the wipe overlay.",
						"typical": "black standard / white flash / custom theme color",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"wipe_duration": {
						"default": 0.4,
						"range": [0.1, 2.0],
						"what": "How long the wipe takes.",
						"typical": "0.2 snappy / 0.4 standard / 1.0 cinematic",
						"increase": "Slower wipe.",
						"decrease": "Faster."
					}
				},
				"details": {
					"what": "Horizontal wipe transition. Rect grows from one edge to cover the screen, then shrinks from the opposite edge on the new scene.",
					"where": "Attach to a CanvasLayer at layer 100 with a full-screen ColorRect child named 'WipeRect'.",
					"before": "ColorRect with anchors_preset = 15 and offsets all zero. Initially anchor_right = 0 to hide.",
					"after": "To load a scene between wipes: await wipe_out(); get_tree().change_scene_to_file(path); await wipe_in().",
					"why_optimized": "Only animates anchor_right — a single property. No shader, no per-pixel work.",
					"mistakes": "Forgetting process_mode = ALWAYS means the wipe pauses if the game is paused during transition.",
					"related": ["transition_iris", "transition_fade", "transition_dissolve", "transition_slide"]
				}
			},
			"transition_iris": {
				"phrases": ["iris transition", "circle transition", "shrink to point", "zoom transition"],
				"code": """extends CanvasLayer

@onready var _rect: ColorRect = $IrisRect

@export var iris_color: Color = Color(0, 0, 0, 1)
@export var iris_duration: float = 0.5
@export var max_radius: float = 1.5

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	var material := ShaderMaterial.new()
	material.shader = preload("res://addons/gd_snippet_expander/shaders/iris.gdshader")
	_rect.material = material
	_rect.color = iris_color
	set_radius(max_radius)

func set_radius(value: float) -> void:
	if _rect.material == null:
		return
	_rect.material.set_shader_parameter("iris_radius", value)

func iris_out() -> void:
	var tween := create_tween()
	tween.tween_method(set_radius, max_radius, 0.0, iris_duration)
	await tween.finished

func iris_in() -> void:
	var tween := create_tween()
	tween.tween_method(set_radius, 0.0, max_radius, iris_duration)
	await tween.finished
	set_radius(max_radius)

# Save this shader as res://addons/gd_snippet_expander/shaders/iris.gdshader:
# shader_type canvas_item;
# uniform float iris_radius : hint_range(0.0, 2.0) = 1.5;
# uniform vec4 iris_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
# void fragment() {
#     vec2 uv = SCREEN_UV - 0.5;
#     uv.x *= SCREEN_UV.y / SCREEN_UV.x;
#     float dist = length(uv);
#     float edge = smoothstep(iris_radius - 0.01, iris_radius + 0.01, dist);
#     COLOR = vec4(iris_color.rgb, iris_color.a * edge);
# }
""",
				"params": ["iris_color", "iris_duration", "max_radius"],
				"category": "transition",
				"subcategory": "iris",
				"dimension": "ui",
				"difficulty": "advanced",
				"param_info": {
					"iris_color": {
						"default": [0, 0, 0, 1],
						"range": [],
						"what": "Color of the iris overlay.",
						"typical": "black / white / themed",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"iris_duration": {
						"default": 0.5,
						"range": [0.2, 2.0],
						"what": "How long the iris closes or opens.",
						"typical": "0.3 quick / 0.5 standard / 1.0+ dramatic",
						"increase": "Slower.",
						"decrease": "Faster."
					},
					"max_radius": {
						"default": 1.5,
						"range": [0.8, 2.0],
						"what": "Radius at which the iris is fully open.",
						"typical": "1.5 covers screen corners",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "Circular iris transition. Screen closes to a point, then reopens on the new scene.",
					"where": "CanvasLayer at layer 100 with a ColorRect. Save the included shader as a .gdshader file.",
					"before": "Create the shader file at the path shown in the code comment.",
					"after": "For a square iris, change length() to max(abs(uv.x), abs(uv.y)) in the shader.",
					"why_optimized": "Shader does the per-pixel work in one line. Tween only animates one uniform.",
					"mistakes": "The shader path in the preload must match exactly, or the material is null and nothing draws.",
					"related": ["transition_wipe", "transition_fade", "shader_dissolve"]
				}
			},
			"transition_fade": {
				"phrases": ["fade transition", "fade to black", "fade out fade in", "black fade"],
				"code": """extends CanvasLayer

@onready var _rect: ColorRect = $FadeRect

@export var fade_color: Color = Color(0, 0, 0, 1)
@export var fade_out_duration: float = 0.4
@export var fade_in_duration: float = 0.4
@export var hold_time: float = 0.1

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rect.color = fade_color
	_rect.color.a = 0.0

func fade_out() -> void:
	var tween := create_tween()
	tween.tween_property(_rect, "color:a", 1.0, fade_out_duration)
	await tween.finished

func fade_in() -> void:
	var tween := create_tween()
	tween.tween_property(_rect, "color:a", 0.0, fade_in_duration)
	await tween.finished

func transition_to(scene_path: String) -> void:
	await fade_out()
	await get_tree().create_timer(hold_time).timeout
	get_tree().change_scene_to_file(scene_path)
	await get_tree().process_frame
	await fade_in()

func transition_to_packed(scene: PackedScene) -> void:
	await fade_out()
	await get_tree().create_timer(hold_time).timeout
	get_tree().change_scene_to_packed(scene)
	await get_tree().process_frame
	await fade_in()
""",
				"params": ["fade_color", "fade_out_duration", "fade_in_duration", "hold_time"],
				"category": "transition",
				"subcategory": "fade",
				"dimension": "ui",
				"difficulty": "beginner",
				"param_info": {
					"fade_color": {
						"default": [0, 0, 0, 1],
						"range": [],
						"what": "Color the screen fades to.",
						"typical": "black standard / white dream / red damage",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"fade_out_duration": {
						"default": 0.4,
						"range": [0.1, 3.0],
						"what": "How long the fade-to-color takes.",
						"typical": "0.2 quick / 0.4 standard / 1.0+ cinematic",
						"increase": "Slower fade out.",
						"decrease": "Faster."
					},
					"fade_in_duration": {
						"default": 0.4,
						"range": [0.1, 3.0],
						"what": "How long the fade-from-color takes on the new scene.",
						"typical": "0.2 quick / 0.4 standard / 1.0+ cinematic",
						"increase": "Slower fade in.",
						"decrease": "Faster."
					},
					"hold_time": {
						"default": 0.1,
						"range": [0.0, 1.0],
						"what": "Pause between fade out and fade in.",
						"typical": "0.0 instant / 0.1 standard / 0.5 dramatic",
						"increase": "Longer pause.",
						"decrease": "Shorter."
					}
				},
				"details": {
					"what": "Standard fade-to-black scene transition. The most common transition in games.",
					"where": "CanvasLayer at layer 100 with a ColorRect. Add as an autoload named 'Transition'.",
					"before": "ColorRect filling the screen. Set alpha to 0 in _ready.",
					"after": "Call Transition.transition_to(\"res://scenes/level_2.tscn\") from anywhere.",
					"why_optimized": "Tween on a single color property. process_mode = ALWAYS keeps working when the game is paused.",
					"mistakes": "Forgetting process_frame between scene change and fade_in causes the fade to start before the new scene renders.",
					"related": ["transition_wipe", "transition_iris", "fade_in_ui", "loading_screen"]
				}
			},
			"transition_slide": {
				"phrases": ["slide transition", "push transition", "slide scene", "menu slide"],
				"code": """extends CanvasLayer

@onready var _rect: ColorRect = $SlideRect

@export var slide_color: Color = Color(0.05, 0.05, 0.1, 1)
@export var slide_duration: float = 0.35
@export var easing_type: int = Tween.TRANS_CUBIC

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rect.color = slide_color
	_rect.anchor_left = -1.0
	_rect.anchor_right = 0.0

func slide_out() -> void:
	_rect.anchor_left = -1.0
	_rect.anchor_right = 0.0
	var tween := create_tween()
	tween.tween_property(_rect, "anchor_left", 0.0, slide_duration).set_trans(easing_type)
	tween.parallel().tween_property(_rect, "anchor_right", 1.0, slide_duration).set_trans(easing_type)
	await tween.finished

func slide_in() -> void:
	_rect.anchor_left = 0.0
	_rect.anchor_right = 1.0
	var tween := create_tween()
	tween.tween_property(_rect, "anchor_left", 1.0, slide_duration).set_trans(easing_type)
	tween.parallel().tween_property(_rect, "anchor_right", 2.0, slide_duration).set_trans(easing_type)
	await tween.finished
	_rect.anchor_left = -1.0
	_rect.anchor_right = 0.0

func transition_to(scene_path: String) -> void:
	await slide_out()
	get_tree().change_scene_to_file(scene_path)
	await get_tree().process_frame
	await slide_in()
""",
				"params": ["slide_color", "slide_duration", "easing_type"],
				"category": "transition",
				"subcategory": "slide",
				"dimension": "ui",
				"difficulty": "intermediate",
				"param_info": {
					"slide_color": {
						"default": [0.05, 0.05, 0.1, 1],
						"range": [],
						"what": "Color of the sliding panel.",
						"typical": "dark for standard / bright for stylized",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"slide_duration": {
						"default": 0.35,
						"range": [0.1, 1.5],
						"what": "How long the slide takes.",
						"typical": "0.2 snappy / 0.35 standard / 0.8 slow",
						"increase": "Slower.",
						"decrease": "Faster."
					}
				},
				"details": {
					"what": "Panel slides in from the left, covers the screen, then slides out to the right. Modern mobile-style transition.",
					"where": "CanvasLayer at layer 100 with a ColorRect. anchor_left and anchor_right define the panel position.",
					"before": "ColorRect child. Set its anchors in _ready.",
					"after": "For vertical slide, animate anchor_top and anchor_bottom instead.",
					"why_optimized": "Two parallel tween properties — no shader, no per-pixel work.",
					"mistakes": "Not resetting the anchors after slide_in means the next transition starts from the wrong position.",
					"related": ["transition_wipe", "transition_fade", "main_menu"]
				}
			},
			"transition_shake_combo": {
				"phrases": ["shake combo", "shake and flash", "combo feedback", "impact combo"],
				"code": """extends Node

@export var flash_layer_path: NodePath
@export var shake_target_path: NodePath

@onready var _flash_layer: CanvasLayer = get_node_or_null(flash_layer_path)
@onready var _shake_target: Camera2D = get_node_or_null(shake_target_path)

func heavy_hit(world_position: Vector2 = Vector2.ZERO) -> void:
	_run_combo(0.2, 12.0, 0.15)
	_spawn_impact_particles(world_position)

func medium_hit(world_position: Vector2 = Vector2.ZERO) -> void:
	_run_combo(0.12, 8.0, 0.1)
	_spawn_impact_particles(world_position)

func light_hit(world_position: Vector2 = Vector2.ZERO) -> void:
	_run_combo(0.06, 4.0, 0.06)
	_spawn_impact_particles(world_position)

func _run_combo(freeze_duration: float, shake_amount: float, flash_duration: float) -> void:
	_freeze(freeze_duration)
	_shake(shake_amount)
	_flash(flash_duration)

func _freeze(duration: float) -> void:
	var original := Engine.time_scale
	Engine.time_scale = 0.05
	await get_tree().create_timer(duration * 0.05, true, false, true).timeout
	Engine.time_scale = original

func _shake(amount: float) -> void:
	if _shake_target == null:
		return
	var original_offset := _shake_target.offset
	var tween := create_tween()
	for i in range(4):
		var random_offset := Vector2(
			randf_range(-amount, amount),
			randf_range(-amount, amount)
		)
		tween.tween_property(_shake_target, "offset", original_offset + random_offset, 0.02)
	tween.tween_property(_shake_target, "offset", original_offset, 0.05)

func _flash(duration: float) -> void:
	if _flash_layer == null or not _flash_layer.has_method("flash_white"):
		return
	_flash_layer.call("flash_white")

func _spawn_impact_particles(position: Vector2) -> void:
	var particles := CPUParticles2D.new()
	particles.global_position = position
	particles.emitting = false
	particles.one_shot = true
	particles.amount = 16
	particles.lifetime = 0.4
	particles.explosiveness = 1.0
	particles.direction = Vector2.ZERO
	particles.spread = 180.0
	particles.initial_velocity_min = 100.0
	particles.initial_velocity_max = 250.0
	particles.gravity = Vector2(0, 300)
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0
	particles.color = Color(1.0, 0.9, 0.6)
	get_tree().current_scene.add_child(particles)
	particles.emitting = true
	await get_tree().create_timer(0.7).timeout
	if is_instance_valid(particles):
		particles.queue_free()
""",
				"params": ["flash_layer_path", "shake_target_path"],
				"category": "transition",
				"subcategory": "feedback",
				"dimension": "2d",
				"difficulty": "intermediate",
				"param_info": {
					"flash_layer_path": {
						"default": "",
						"range": [],
						"what": "NodePath to the screen_flash CanvasLayer.",
						"typical": "the flash manager from library/snippets/hit_feedback.gd",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"shake_target_path": {
						"default": "",
						"range": [],
						"what": "NodePath to the Camera2D that should shake.",
						"typical": "the active camera in your scene",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "Combines freeze, camera shake, screen flash, and particle burst in one call. The complete impact feel.",
					"where": "Attach to a game manager or the player. Set flash_layer_path and shake_target_path in the Inspector.",
					"before": "flash_layer must have a flash_white() method (from hit_feedback.gd). shake_target must be a Camera2D.",
					"after": "Call heavy_hit(), medium_hit(), or light_hit() with the world position of the impact.",
					"why_optimized": "All effects run in parallel. The freeze uses real-time timers so it doesn't extend itself.",
					"mistakes": "Calling heavy_hit() on every hit gets overwhelming fast. Match the combo to the actual impact severity.",
					"related": ["hitstop", "screen_flash", "camera_shake", "impact_frames"]
				}
			}
		}
	}

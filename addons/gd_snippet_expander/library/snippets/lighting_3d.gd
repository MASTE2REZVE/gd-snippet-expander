@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"snippets": {
			"volumetric_fog_3d": {
				"phrases": ["volumetric fog", "god rays", "light shafts", "volumetric light"],
				"code": """extends WorldEnvironment

@export var volume_fog_enabled: bool = true
@export var volume_fog_density: float = 0.05
@export var volume_fog_albedo: Color = Color(1, 1, 1)
@export var volume_fog_emission: Color = Color(0.3, 0.3, 0.4)
@export var volume_fog_length: float = 64.0

func _ready() -> void:
	_apply_volumetric_fog()

func _apply_volumetric_fog() -> void:
	if environment == null:
		environment = Environment.new()
	environment.volumetric_fog_enabled = volume_fog_enabled
	environment.volumetric_fog_density = volume_fog_density
	environment.volumetric_fog_albedo = volume_fog_albedo
	environment.volumetric_fog_emission = volume_fog_emission
	environment.volumetric_fog_length = volume_fog_length

func set_density(value: float) -> void:
	volume_fog_density = clampf(value, 0.0, 0.5)
	_apply_volumetric_fog()

func fade_in(duration: float) -> void:
	var tween := create_tween()
	tween.tween_method(set_density, 0.0, volume_fog_density, duration)
""",
				"params": ["volume_fog_enabled", "volume_fog_density", "volume_fog_albedo", "volume_fog_emission", "volume_fog_length"],
				"category": "world",
				"subcategory": "fog",
				"platforms": ["desktop"],
				"dimension": "3d",
				"difficulty": "intermediate",
				"param_info": {
					"volume_fog_density": {
						"default": 0.05,
						"range": [0.001, 0.5],
						"what": "Thickness of the volumetric fog — how visible light shafts are.",
						"typical": "0.01 subtle / 0.05 standard / 0.15+ heavy",
						"increase": "More visible light shafts.",
						"decrease": "Clearer air."
					},
					"volume_fog_length": {
						"default": 64.0,
						"range": [8.0, 256.0],
						"what": "How far the fog extends from the camera, in meters.",
						"typical": "32 short / 64 standard / 200+ far",
						"increase": "Fog visible further out.",
						"decrease": "Only near the camera."
					}
				},
				"details": {
					"what": "Volumetric fog creates visible light shafts and hazy air. Expensive but cinematic — the classic god-rays effect.",
					"where": "Enable on the WorldEnvironment's Environment resource. Works with DirectionalLight3D and SpotLight3D.",
					"before": "A DirectionalLight3D or SpotLight3D. Without lights, volumetric fog is barely visible.",
					"after": "Enable 'Volumetric Fog' on specific lights to make them interact. Every omni light with volumetric fog on adds significant cost.",
					"why_optimized": "Volumetric fog is a ray-marched effect. Keep volume_fog_length modest for performance.",
					"mistakes": "Enabling volumetric fog on every light in the scene destroys performance. Only the main sun and a few key lights need it.",
					"related": ["fog_3d", "directional_light_3d", "world_environment_3d"]
				}
			},
			"reflection_probe_3d": {
				"phrases": ["reflection probe", "reflection probe 3d", "environment reflection", "shiny surface reflection"],
				"code": """# ReflectionProbe captures the surroundings and applies them to
# metallic or glossy surfaces within its influence.
#
# 1. Add a ReflectionProbe node to your 3D scene.
# 2. In the Inspector:
#    - Update Mode: Once (baked) or Always (dynamic)
#    - Size: the box-shaped volume the probe affects
#    - Intensity: reflection strength multiplier
#    - Max Distance: how far the probe captures
#    - Box Projection: matches reflections to the room shape
# 3. Resize the probe's box to cover the room or area it should affect.
# 4. Meshes with metallic materials inside this box will reflect the probe.

extends ReflectionProbe

@export var auto_update: bool = false

func _ready() -> void:
	update_mode = ReflectionProbe.UPDATE_ALWAYS if auto_update else ReflectionProbe.UPDATE_ONCE
	if not auto_update:
		update_mode = ReflectionProbe.UPDATE_ONCE

func refresh() -> void:
	update_mode = ReflectionProbe.UPDATE_ONCE

func set_intensity(value: float) -> void:
	intensity = clampf(value, 0.0, 2.0)
""",
				"params": ["auto_update"],
				"category": "world",
				"subcategory": "lighting",
				"platforms": ["desktop", "mobile"],
				"dimension": "3d",
				"difficulty": "intermediate",
				"param_info": {
					"auto_update": {
						"default": false,
						"range": [],
						"what": "Whether the probe re-renders each frame (dynamic) or once (static).",
						"typical": "false for most scenes / true for reflective rooms with moving characters",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "Captures the environment and reflects it on shiny surfaces. Essential for metallic or glossy materials to look right.",
					"where": "Add one per room or major area. Box size determines the influence radius.",
					"before": "Metallic or glossy MeshInstance3D nodes in the scene. Materials need low roughness for the reflection to show.",
					"after": "Use Box Projection for architectural reflection and Update Mode Once for static scenes.",
					"why_optimized": "Baked probes (Update Once) are essentially free at runtime. Dynamic probes cost a full scene render per frame.",
					"mistakes": "Dynamic probes on multiple rooms kills performance. Use them only where the player is and only if reflections need to change.",
					"related": ["world_environment_3d", "mesh_3d", "lightmap_gi_3d"]
				}
			},
			"lightmap_gi_3d": {
				"phrases": ["lightmap gi", "baked lighting", "gi bake", "baked shadows 3d"],
				"code": """# LightmapGI bakes static lighting into textures. The result is
# gorgeous global illumination with zero runtime cost.
#
# 1. Add a LightmapGI node to the scene.
# 2. In the Inspector, set:
#    - Quality: Low / Medium / High (higher = slower bake, better result)
#    - Bounces: 1-4 (indirect lighting iterations)
#    - Directional: capture directional light bounces
#    - Interior: check for indoor scenes (no sky contribution)
# 3. For every StaticBody3D or MeshInstance3D that should be baked:
#    - Open the GeometryInstance3D section in the Inspector
#    - Set 'GI Mode' to 'Static' or 'Static Lightmaps'
#    - Ensure the mesh has UV2 (Godot generates this automatically for
#      simple primitives; imported meshes need a UV2 layer)
# 4. Click 'Bake Lightmaps' in the toolbar (top-right of the 3D viewport).
# 5. Wait for the bake to finish. This can take 30 seconds to 30 minutes.
#
# To verify:
# - Hide all lights after baking to see the baked result alone.
# - Rebake whenever the scene geometry or lighting changes.

@tool
extends LightmapGI

func rebake() -> void:
	# Trigger a rebake from a script (editor only)
	if Engine.is_editor_hint():
		EditorInterface.get_editor_main_screen().emit_signal("rebake_requested")

# For dynamic objects that receive light from lightmaps but don't
# contribute to them, use LightmapProbe nodes near them.
""",
				"params": [],
				"category": "world",
				"subcategory": "lighting",
				"platforms": ["desktop"],
				"dimension": "3d",
				"difficulty": "advanced",
				"details": {
					"what": "Bakes static lighting into textures. Gives realistic global illumination with zero runtime cost — ideal for architectural scenes.",
					"where": "One LightmapGI per scene. Configure quality in the Inspector, then bake from the toolbar.",
					"before": "Static geometry (StaticBody3D or MeshInstance3D with GI Mode set). Imported meshes need UV2 layers — Godot warns if missing.",
					"after": "Use LightmapProbe nodes for moving characters so they receive the baked lighting too.",
					"why_optimized": "Zero runtime cost after baking. Perfect for low-end mobile targets.",
					"mistakes": "Forgetting to set GI Mode on meshes means they don't contribute to or receive the bake. Rebake after moving any static geometry.",
					"related": ["reflection_probe_3d", "world_environment_3d", "directional_light_3d"]
				}
			},
			"emissive_material_3d": {
				"phrases": ["emissive material", "glowing material", "emission material", "self lit material"],
				"code": """func make_emissive_material(color: Color, intensity: float = 2.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = intensity
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	return mat

func apply_emission(mesh: MeshInstance3D, color: Color, intensity: float = 2.0) -> void:
	if mesh == null:
		return
	var mat: StandardMaterial3D
	if mesh.get_surface_override_material(0) is StandardMaterial3D:
		mat = mesh.get_surface_override_material(0)
	else:
		mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = intensity
	mesh.set_surface_override_material(0, mat)

func pulse_emission(mesh: MeshInstance3D, base_intensity: float = 2.0, pulse: float = 1.0) -> void:
	if mesh == null:
		return
	var tween := create_tween().set_loops()
	tween.tween_method(
		func(v): _set_emission_intensity(mesh, v),
		base_intensity, base_intensity + pulse, 0.8
	)
	tween.tween_method(
		func(v): _set_emission_intensity(mesh, v),
		base_intensity + pulse, base_intensity, 0.8
	)

func _set_emission_intensity(mesh: MeshInstance3D, value: float) -> void:
	var mat = mesh.get_surface_override_material(0)
	if mat is StandardMaterial3D:
		(mat as StandardMaterial3D).emission_energy_multiplier = value
""",
				"params": ["color", "intensity"],
				"category": "world",
				"subcategory": "lighting",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "intermediate",
				"param_info": {
					"color": {
						"default": [1, 1, 1, 1],
						"range": [],
						"what": "Color of the emission glow.",
						"typical": "orange lava / cyan tech / red danger / white lamp",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"intensity": {
						"default": 2.0,
						"range": [0.0, 10.0],
						"what": "Brightness multiplier of the emission.",
						"typical": "1.0 subtle / 2.0 standard / 5.0+ blinding",
						"increase": "Brighter glow.",
						"decrease": "Dimmer."
					}
				},
				"details": {
					"what": "Makes a material emit light and appear self-illuminated. Combined with WorldEnvironment glow, produces bloom.",
					"where": "Apply to a MeshInstance3D's material. Enable Glow on the WorldEnvironment's environment to see the bloom.",
					"before": "WorldEnvironment with Glow enabled in the Environment resource.",
					"after": "Pair with an OmniLight3D at the same position for the illusion of casting light.",
					"why_optimized": "Emissive materials don't cast light — they just look bright. Pair with an actual light for the light-casting effect.",
					"mistakes": "Expecting emissive materials to illuminate other objects. They only change their own appearance.",
					"related": ["omni_light_3d", "world_environment_3d", "mesh_3d"]
				}
			},
			"light_group_3d": {
				"phrases": ["light group", "light group 3d", "toggle lights", "control multiple lights"],
				"code": """extends Node

@export var fade_duration: float = 1.0

var _grouped_lights: Array[Light3D] = []
var _group_base_energy: Dictionary = {}

func register(light: Light3D, group_id: String = "default") -> void:
	if not _group_base_energy.has(group_id):
		_group_base_energy[group_id] = {}
	if not _group_base_energy[group_id].has(light):
		_group_base_energy[group_id][light] = light.light_energy

func turn_on(group_id: String, duration: float = -1.0) -> void:
	var dur: float = fade_duration if duration < 0.0 else duration
	for light in _group_base_energy.get(group_id, {}).keys():
		if not is_instance_valid(light):
			continue
		var target: float = _group_base_energy[group_id][light]
		var tween := create_tween()
		tween.tween_property(light, "light_energy", target, dur)

func turn_off(group_id: String, duration: float = -1.0) -> void:
	var dur: float = fade_duration if duration < 0.0 else duration
	for light in _group_base_energy.get(group_id, {}).keys():
		if not is_instance_valid(light):
			continue
		var tween := create_tween()
		tween.tween_property(light, "light_energy", 0.0, dur)

func set_intensity(group_id: String, value: float, duration: float = -1.0) -> void:
	var dur: float = fade_duration if duration < 0.0 else duration
	for light in _group_base_energy.get(group_id, {}).keys():
		if not is_instance_valid(light):
			continue
		var tween := create_tween()
		tween.tween_property(light, "light_energy", value, dur)
""",
				"params": ["fade_duration"],
				"category": "world",
				"subcategory": "lighting",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "intermediate",
				"param_info": {
					"fade_duration": {
						"default": 1.0,
						"range": [0.0, 5.0],
						"what": "Default fade time for light on/off transitions.",
						"typical": "0.2 quick / 1.0 standard / 3.0+ dramatic",
						"increase": "Slower fade.",
						"decrease": "Faster."
					}
				},
				"details": {
					"what": "Manages groups of 3D lights. Turn all street lights off at dawn with one call.",
					"where": "Attach to a Node in the scene. Register each light with a group ID at _ready.",
					"before": "Light3D nodes (omni, spot, or directional) in the scene.",
					"after": "Connect day_night_3d's hour_changed signal to turn streetlights on at 19 and off at 06.",
					"why_optimized": "Dictionary of groups means one lookup per light. Tweens animate independently.",
					"mistakes": "Not registering a light means it never responds to group calls. Register in _ready or before use.",
					"related": ["omni_light_3d", "day_night_3d", "spot_light_3d"]
				}
			},
			"shadow_tuning_3d": {
				"phrases": ["shadow tuning", "shadow settings", "shadow bias", "fix shadow artifacts"],
				"code": """# Shadow quality in Godot 4 comes from three places:
#   - The light's shadow settings
#   - Project Settings -> Rendering -> Lights and Shadows
#   - The DirectionalLight3D's split mode (for sun)

# Common artifacts and their fixes:
#
# PETER-PANNING (shadow detaches from object):
#   - Reduce the light's shadow_bias (try 0.02 -> 0.01)
#   - Increase directional_shadow_max_distance
#   - For omni lights, lower omni_shadow_detail
#
# SHADOW ACNE (striped lines on flat surfaces):
#   - Increase shadow_bias slightly
#   - Increase shadow_normal_bias
#   - Reduce light's shadow blur
#
# JAGGED SHADOW EDGES:
#   - Increase Project Settings -> Rendering -> Lights and Shadows ->
#     Shadow Atlas Size
#   - Enable soft shadows on the light
#   - Increase directional_shadow_blend_splits
#
# SHADOWS DISAPPEAR AT DISTANCE:
#   - Increase directional_shadow_max_distance (default 100)
#   - Use PSSM 4 Splits shadow mode
#   - Reduce shadow blur which extends the far plane

func configure_directional_shadows(light: DirectionalLight3D) -> void:
	light.shadow_enabled = true
	light.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	light.directional_shadow_max_distance = 200.0
	light.directional_shadow_blend_splits = true
	light.shadow_bias = 0.03
	light.shadow_normal_bias = 1.5
	light.shadow_blur = 1.0

func configure_omni_shadows(light: OmniLight3D) -> void:
	light.shadow_enabled = true
	light.omni_shadow_mode = OmniLight3D.SHADOW_CUBE
	light.shadow_bias = 0.02
	light.shadow_normal_bias = 1.0

func disable_shadows(light: Light3D) -> void:
	light.shadow_enabled = false
""",
				"params": [],
				"category": "world",
				"subcategory": "shadow",
				"platforms": ["desktop", "mobile"],
				"dimension": "3d",
				"difficulty": "advanced",
				"details": {
					"what": "Reference for fixing common shadow artifacts plus helper functions for sane defaults.",
					"where": "Tune per-light in the Inspector. Use the helper functions for a good starting point.",
					"before": "Lights with shadows enabled. Artifacts appear in the 3D viewport.",
					"after": "For mobile, disable shadows entirely or use only one shadow-casting light.",
					"why_optimized": "Shadow rendering is one of the most expensive features. Each shadow-casting light multiplies cost.",
					"mistakes": "Increasing shadow bias to fix one artifact usually causes another. Change one value at a time and re-check.",
					"related": ["directional_light_3d", "omni_light_3d", "world_environment_3d"]
				}
			}
		}
	}
